# TODO — rakun  (annotation-processor lib · Wave 1)

> Task branch `task/rakun-di` · spec
> [`tasks/v0.beta.8/specs/rakun.md`](../../tasks/v0.beta.8/specs/rakun.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing** — the `@Decl`/`@emit` mechanism + F3 placement bodies are
> in `feat`. Start now. Sibling of `onze` (same mechanism, disjoint lib).
>
> **HARD RULE.** Zero rakun knowledge in `compiler-core`. All behaviour is
> `libs/rakun/*.bp` decorator bodies via `@emit`. Port *behaviour* from the preserved
> `task/rakun` reference (`feb96f0`), never the Zig.

## F2 — IoC container (the wiring, via `@emit`)
- [ ] Component scan: the component decorators collect every annotated record (a
      shared comptime registry).
- [ ] DI graph: a field whose `typeName` is a known component ⇒ an edge; topo-sort;
      `@emit` the singleton `val`s in dependency order.
- [ ] Cycle detection (A↔B) ⇒ `@compilerError` (scoped).
- [ ] Singleton scope (one instance per type); `#[configuration]`+`#[bean]` factories
      (return type injectable); `#[value("key")]` property injection.

## F4 — web layer / router (via `@emit`)
- [ ] Controller decorator walks `decl.methods`, reads `#[getMapping(path)]`/… from
      `method.annotations`, `@emit`s a router table `{ method, path, handler }` (+ `route` prefix).
- [ ] Path params (`:name`) wired to `req.param("name")`.
- [ ] `Response` builders type-check against the handler return type.

## F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` scaffold → real minimal HTTP (listen, dispatch, req/resp
      bridge) behind `#[@external]` host calls (node `http` first; then erlang).
- [ ] `Request` gets a concrete server-supplied impl: `param`/`query`/`header`/`body`.
- [ ] `Rakun.run(app)` `@emit`s the boot: scan → instantiate singletons → register
      router → start `libs/server` on `app.port`/`basePath`.
- [ ] End-to-end: a request to a mapped route invokes the handler + returns its Response.

## Done gate
- [ ] component scan + 3-level DI chain + cycle diagnostic + `#[bean]` injection (comptime).
- [ ] router table emitted (node + beam); GET routes return 200, unmapped → 404 (run).
- [ ] Tests in `libs/rakun/*.bp`; `libs/rakun/AGENTS.md` + `libs/server/AGENTS.md` updated.
- [ ] `grep -riE "rakun" modules/compiler-core/src` returns nothing.

## Notes
- Constructor injection + singleton scope only in v1. `libs/server` realness gates F5
  (node first). No graceful-shutdown / middleware in v1.
