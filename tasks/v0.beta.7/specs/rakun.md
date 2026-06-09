# rakun — comptime DI container + router + bootstrap (rakun F2–F5)

**Slug**: rakun
**Depends on**: [`annotation-processors`](annotation-processors.md) — the generic mechanism rakun is built on
**Files**: `libs/rakun/src/*.bp` (ALL semantics — decorators, DI, router, bootstrap, written in botopink), `libs/server/src/*` (HTTP backing — scaffold → real)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/server/AGENTS.md`
**Status**: pending

> **HARD RULE (2026-06-08).** `modules/compiler-core/src/**` must contain **zero**
> knowledge of rakun — no lib names, no DI/router/`Response` semantics, no
> `registerRakunLib`/`rakun_pkg_modules`/embeds. rakun is a **pure-botopink lib**:
> every behaviour below is implemented in `libs/rakun/*.bp` on top of the generic
> primitives from [`annotation-processors.md`](annotation-processors.md) (custom
> comptime decorator fns + a generic package loader). The steps below describe the
> *behaviour*; the *implementation* is in the lib, not the compiler.

## Intent

rakun ships HTTP types (`http.bp`) and `#[decorator]` markers. The generic
package loader resolves `from "rakun"`, and the annotation-processor mechanism
lets rakun's decorators (custom comptime fns in the lib) give those markers their
**semantics** — all in botopink. This spec describes the behaviour those
decorators implement and the loop to a booting server, as one sequential strand
on the `task/rakun` branch:

- the comptime IoC container (F2), annotation argument validation (F3), and the
  web router (F4);
- then `Rakun.run` over a real `libs/server` HTTP backing (F5) — the one leg
  that needs a real listener, which boots the F2–F4 scan/graph/router.

The wiring is **comptime** — a compilation-unit scan, not runtime reflection —
reusing the same machinery as `expr-templates`. F5 lands last because it boots
everything F2–F4 produces; the phases share `libs/rakun/src/*.bp`, so they stay
**one branch** rather than two tasks that would have to wait on each other.

## Target syntax

```bp
import {repository, service, restController, route, getMapping} from "rakun";
import {Request, Response, Rakun, App} from "rakun";

#[repository] record UserRepository { pub fn all(self: Self) -> Array<string> { return ["ana"]; } }

#[service] record UserService {
    repo: UserRepository,                 // injected by type (constructor injection)
    pub fn list(self: Self) -> Array<string> { return self.repo.all(); }
}

#[restController, route("/api/users")]
record UserController {
    service: UserService,                 // injected by type
    #[getMapping("/")]
    pub fn index(self: Self, req: Request) -> Response { return Response.json(self.service.list().join(", ")); }
}

fn main() {
    Rakun.run(App(port: 8080, basePath: "/"));   // boots the scan + graph + router
}
```

## Steps

### F2 — IoC container
- [ ] Comptime component scan: discover every `#[component]`/`#[service]`/
      `#[repository]`/`#[controller]`/`#[restController]` record in the unit.
- [ ] DI graph: a record field whose type is a known component ⇒ a dependency
      edge; topo-sort; **detect cycles → a scoped diagnostic**.
- [ ] Singleton scope: one shared instance per component type.
- [ ] `#[configuration]` + `#[bean]` factory contribution (a `#[bean]` fn's
      return type becomes injectable); `#[value("key")]` property injection.

### F3 — annotation argument validation
- [ ] Type-check `#[decorator(args)]` arguments against the imported delegate
      signature (arity + arg types — e.g. `#[getMapping("/x")]` wants one
      string; `#[getMapping()]` is an arity error).
- [ ] Clear diagnostic for a route marker on a non-handler / a component marker
      on a non-record.

### F4 — web layer / router
- [ ] `route` prefix + `getMapping|postMapping|putMapping|patchMapping|
      deleteMapping(path)` → a router table `{ method, path, handler }`.
- [ ] Path params (`:name`) wired to `req.param("name")`.
- [ ] `Response` builders type-check against the handler return type.

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` from scaffold to a real, minimal HTTP server
      surface (listen, route dispatch, request/response bridging) behind
      `#[@external]` host calls per backend (node `http`, erlang `cowboy`/
      `inets` or a minimal `gen_tcp` loop).
- [ ] `Request` (the rakun runtime-boundary interface) gets a concrete
      server-supplied implementation: `param`/`query`/`header`/`body`.
- [ ] Lower `Rakun.run(app)` to: comptime scan → instantiate the DI singletons →
      register the router table → start `libs/server` on `app.port`/`basePath`.
      The lowering is driven by the imported lib, not hard-coded in the prelude.
- [ ] End-to-end: a request to a mapped route invokes the handler with a live
      `Request` and returns its `Response` (status + body) over the wire.

## Test scenarios

```
comptime ---- component scan discovers every #[service]/#[repository]/#[controller]
comptime ---- container resolves a 3-level DI chain (repo → service → controller)
comptime ---- a dependency cycle (A needs B, B needs A) raises a scoped diagnostic
comptime ---- #[bean] factory output is injectable by its return type
infer    ---- #[getMapping("/x")] handler signature (Request) -> Response type-checks
infer    ---- #[getMapping()] (wrong arity) is a clear error
codegen  ---- router table emitted for node + beam targets
run      ---- GET /api/users/  returns 200 with the joined user list
run      ---- GET /api/hello/ana returns 200 "Hello, ana!"
run      ---- an unmapped path returns 404
```

## Notes

- Constructor injection only (immutable-first); singleton scope only in v1.
- `libs/server` realness is the gating sub-task for F5; keep it minimal (one
  backend first — node — then erlang). No graceful-shutdown / middleware in v1.
- Tests live in `libs/rakun`'s own `.bp` files (`botopink test`), not in the
  compiler's Zig suites.
- Reuses the comptime scan machinery; adds no runtime reflection.
