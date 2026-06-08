# rakun-ioc-web — comptime DI container + router (rakun F2–F4)

**Slug**: rakun-ioc-web
**Depends on**: nothing (builds on the rakun foundation in `feat`: `from "rakun"` + `#[decorator]` resolution)
**Files**: `libs/rakun/src/*.bp`, `modules/compiler-core/src/comptime/*` (component scan + DI graph), `modules/compiler-core/src/codegen/*` (router table)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `modules/compiler-core/src/comptime/AGENTS.md`
**Status**: pending

## Intent

The rakun foundation (in `feat`) makes `from "rakun"` resolve, ships the real
`http.bp` types, and resolves `#[decorator]` markers to imported symbols. This
spec adds the **semantics** behind those markers: the comptime IoC container
(F2), full annotation argument validation (F3), and the web router (F4).

The wiring is **comptime** — a compilation-unit scan, not runtime reflection —
reusing the same machinery as `expr-templates`.

## Target syntax

```bp
import {repository, service, restController, route, getMapping} from "rakun";
import {Request, Response} from "rakun";

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

## Test scenarios

```
comptime ---- component scan discovers every #[service]/#[repository]/#[controller]
comptime ---- container resolves a 3-level DI chain (repo → service → controller)
comptime ---- a dependency cycle (A needs B, B needs A) raises a scoped diagnostic
comptime ---- #[bean] factory output is injectable by its return type
infer    ---- #[getMapping("/x")] handler signature (Request) -> Response type-checks
infer    ---- #[getMapping()] (wrong arity) is a clear error
codegen  ---- router table emitted for node + beam targets
```

## Notes

- Constructor injection only (immutable-first); singleton scope only in v1.
- Tests live in `libs/rakun`'s own `.bp` files (`botopink test`), not in the
  compiler's Zig suites.
- Reuses the comptime scan machinery; adds no runtime reflection.
