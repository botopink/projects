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

> **Mechanism reality (verified 2026-06-10).** Each decorator runs in an isolated
> node process — there is NO shared comptime registry across decorators, no
> top-level mutable `var`, and hand-code can't reference emitted symbols. So the
> spec's "shared comptime registry" / "topo-sorted singleton `val`s" / "comptime
> cycle diagnostic" are realized differently: a **host runtime** (`runtime.mjs`
> behind `#[@external]`) holds the scan/cycle/router state, and each decorator
> `@emit`s self-registering code + a lazy factory. Equivalent behaviour; the
> *comptime* cycle diagnostic is the one genuine casualty (runtime instead).
>
> **Generic core fixes this needed (landed):** cross-module host-`#[@external]`
> lowering + import dedup (`14cd527`); `@Decl` field-annotation reflection +
> `test/` modules excluded from the test aggregator (this commit).

## F2 — IoC container (the wiring, via `@emit`)
- [x] Component scan: each component decorator `@emit`s `rkScan("Name")` at module
      load → host scan registry (no shared comptime state needed).
- [x] DI graph: each component `@emit`s `__rkMake_<Type>()` injecting every field
      by its own factory (lazy; topo-order is implicit in the call graph, not `val`
      order). Tested via dispatch building a controller→service→repo chain.
- [x] Cycle detection (A↔B): `rkEnter`/`rkDone` guard raises at construction.
      NOTE: **runtime**, not comptime (per-decorator has no whole-graph view).
- [ ] Singleton scope (currently fresh-per-resolve) + `#[configuration]`/`#[bean]`
      factories + `#[value("key")]` property injection. (`@Decl` now reflects field
      annotations, so `#[value]` detection is unblocked — wiring deferred.)

## F4 — web layer / router (via `@emit`)
- [x] Controller decorator walks `decl.methods`, reads `#[getMapping(path)]`/… from
      `method.annotations`, `@emit`s `rkRegisterRoute(verb, prefix + path, handler)`
      (+ `#[route]` prefix). Verb from the marker name.
- [x] Path params (`:name`) — `dispatch` matches them (binding into the request);
      `req.param("name")` wiring exercised via the fake request.
- [x] `Response` builders type-check against the handler return type (handler is
      `fn(req: Request) -> Response`; `rkDispatch -> Response`).

## F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` scaffold → real minimal HTTP (listen, dispatch, req/resp
      bridge) behind `#[@external]` host calls (node `http` first; then erlang).
- [ ] `Request` gets a concrete server-supplied impl: `param`/`query`/`header`/`body`.
- [ ] `Rakun.run(app)` reads the host router and starts `libs/server` on
      `app.port`/`basePath`. (Needs G2: ship the runtime `.mjs` next to the emitted
      module so a consumer build resolves it — today only the lib's own tests do.)
- [ ] End-to-end: a request to a mapped route invokes the handler + returns its Response.

## Done gate
- [x] component scan + DI chain + cycle diagnostic (runtime) — green under
      `botopink test` (`test/di_test.bp`, `test/router_test.bp`). `#[bean]` deferred.
- [~] router: GET routes return 200, unmapped → 404 — green in-test via `rkDispatch`.
      Real `run` over node `http` + beam pending F5/G2.
- [x] Tests in `libs/rakun/*.bp`; `libs/rakun/AGENTS.md` updated. `libs/server/AGENTS.md`
      update lands with F5.
- [x] `grep -riE "rakun" modules/compiler-core/src` returns nothing (mechanism is generic).

## Notes
- Constructor injection only in v1; singleton scope, `#[value]`/`#[bean]`, and the
  real server are the remaining work. `libs/server` realness + runtime-`.mjs`
  shipping (G2) gate F5. No graceful-shutdown / middleware in v1.
- Comptime constraints on decorator bodies (no sibling calls, `if`-expr, bare-`if`
  only last, block-lambdas) force the factory builder to be inlined per marker.
