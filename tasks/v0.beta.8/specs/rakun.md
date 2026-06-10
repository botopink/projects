# rakun — IoC container + router + bootstrap (F2 · F4 · F5)

**Slug**: rakun
**Depends on**: nothing — the annotation-processor mechanism (`@Decl` reflection, decorator invocation, `@emit`/`@compilerError`) is complete in `feat`; F3 placement bodies landed (`4eef880`)
**Files**: `libs/rakun/src/*.bp` (ALL semantics — DI, router, bootstrap, written in botopink), `libs/server/src/*` (HTTP backing — scaffold → real)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/server/AGENTS.md`
**Status**: pending

> **HARD RULE.** `modules/compiler-core/src/**` keeps **zero** knowledge of rakun.
> Every behaviour below is implemented in `libs/rakun/*.bp` as lib-side decorator
> bodies on the generic primitives (custom comptime decorator fns + `@emit` +
> `@compilerError`). The steps describe the *behaviour*; the *implementation* is in
> the lib. Memory: [[feedback_no_lib_specific_in_core]],
> [[reference_worktree_merge_param_threading]].

## Context — what already landed (v0.beta.7)

The keystone and the **F3 placement bodies** are in `feat`:

- `from "rakun"` resolves via the generic disk loader; `http.bp` + `decorators.bp`
  + `rakun.d.bp` ship as the lib.
- `decorators.bp` holds every marker (`#[service]`/`#[repository]`/`#[controller]`/
  `#[restController]`/`#[configuration]`/`#[bean]`/`#[inject]`/`#[value]`/`#[route]`/
  `#[getMapping]`/…) as a comptime decorator fn taking `comptime decl: @Decl`, each
  enforcing its **placement rule** (component on a record, route on a method,
  `#[value]`/`#[inject]` on a field) via `decl.fail`. Arg arity/types are checked
  generically from the signature. `di_test.bp` proves the markers accept correct
  placements.

What remains is the **wiring** the same decorators contribute — F2 (DI), F4
(router), F5 (bootstrap) — all via `@emit`, plus a real `libs/server`.

## Available primitives (in `feat`)

- **Recognition + args** — a decorator is any fn whose first param is
  `comptime _: @Decl`; `#[d(args)]` is arg-checked generically.
- **Reflection — `@Decl`** — `decl.kind`/`decl.name`/`decl.returnType`/`decl.fields`
  (`Field{ name, typeName, annotations }`)/`decl.methods` (`Method{ name, params,
  returnType, annotations }`)/`decl.annotations`. The whole input for the scan, the
  DI graph (fields → edges), and the router (methods + their annotations).
- **Diagnostics — `@compilerError(message)`** / `decl.fail`/`failAt`.
- **Wiring — `@emit(source)`** — the body contributes generated top-level decls
  (botopink source) spliced into the module: singleton `val`s, DI construction, the
  router table, the `Rakun.run` boot. Decorator fns are comptime-only (dropped from
  codegen — `bd277bd`), so `@emit`/`@compilerError`/`decl.*` never reach output.

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

### F2 — IoC container (the wiring, via `@emit`)
- [ ] Component scan: the component decorators (`#[service]`/`#[repository]`/…)
      collect every annotated record in the unit (a comptime registry the bodies
      share).
- [ ] DI graph: a record field whose `typeName` is a known component ⇒ a dependency
      edge; topo-sort and `@emit` the singleton `val`s in dependency order.
- [ ] Cycle detection: A needs B, B needs A ⇒ `@compilerError` (scoped).
- [ ] Singleton scope: one shared instance per component type.
- [ ] `#[configuration]` + `#[bean]` factories (`#[bean]` fn's return type becomes
      injectable); `#[value("key")]` property injection.

### F4 — web layer / router (via `@emit`)
- [ ] The controller decorator walks `decl.methods`, reads each method's
      `#[getMapping(path)]`/`#[postMapping]`/… from `method.annotations`, and
      `@emit`s a router table `{ method, path, handler }` (+ `route` prefix).
- [ ] Path params (`:name`) wired to `req.param("name")`.
- [ ] `Response` builders type-check against the handler return type.

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` from scaffold to a real minimal HTTP surface (listen,
      route dispatch, request/response bridging) behind `#[@external]` host calls
      per backend (node `http` first; then erlang `gen_tcp`/`inets`/`cowboy`).
- [ ] `Request` gets a concrete server-supplied implementation:
      `param`/`query`/`header`/`body`.
- [ ] `Rakun.run(app)` `@emit`s the boot: comptime scan → instantiate the DI
      singletons → register the router table → start `libs/server` on
      `app.port`/`basePath`. Driven by the imported lib, not the prelude.
- [ ] End-to-end: a request to a mapped route invokes the handler with a live
      `Request` and returns its `Response` (status + body) over the wire.

## Test scenarios

```
comptime ---- component scan discovers every #[service]/#[repository]/#[controller]
comptime ---- container resolves a 3-level DI chain (repo → service → controller)
comptime ---- a dependency cycle (A needs B, B needs A) raises a scoped diagnostic
comptime ---- #[bean] factory output is injectable by its return type
infer    ---- #[getMapping("/x")] handler signature (Request) -> Response type-checks
codegen  ---- router table emitted for node + beam targets
run      ---- GET /api/users/  returns 200 with the joined user list
run      ---- GET /api/hello/ana returns 200 "Hello, ana!"
run      ---- an unmapped path returns 404
```

## Notes

- F3 (placement) is **done + merged**; this spec is F2/F4/F5 (the `@emit` wiring +
  the real server). Constructor injection only; singleton scope only in v1.
- `libs/server` realness gates F5 — keep it minimal (node first, then erlang); no
  graceful-shutdown / middleware in v1.
- The interim core-coupled F2/F3 reference lives on the preserved `task/rakun`
  branch (`feb96f0`) — port the *behaviour* into `.bp`, never the Zig.
- Tests live in `libs/rakun`'s own `.bp` files (`botopink test`). Reuses the
  comptime scan; adds no runtime reflection, no core code. Memory:
  [[project_rakun_progress]].
