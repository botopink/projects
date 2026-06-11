# rakun — finish the IoC scopes + the real server (F2-scopes · F5)

**Slug**: rakun
**Depends on**: nothing — the `@Decl`/`@emit` mechanism, F3 placement bodies, F2 scan/graph/cycle, and F4 router all landed in `feat` (`task/rakun-di`, `b8d9923`)
**Files**: `libs/rakun/src/*.bp` (ALL semantics — written in botopink), `libs/server/src/*` (HTTP backing — scaffold → real)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/server/AGENTS.md`
**Status**: pending

> **HARD RULE.** `modules/compiler-core/src/**` keeps **zero** knowledge of rakun.
> Every behaviour below is implemented in `libs/rakun/*.bp` as lib-side decorator
> bodies via `@emit` over the generic primitives. Memory:
> [[feedback_no_lib_specific_in_core]], [[project_rakun_progress]],
> [[feedback_external_annotation_form]].

## Context — what already landed (v0.beta.8)

The bulk of rakun is **done + merged** on `task/rakun-di` (`b8d9923`):

- **F2 (partial)** — component scan (`#[service]`/`#[repository]`/`#[controller]`/…
  each `@emit`s `rkScan("Name")` into a **host runtime registry**), the DI graph
  (`__rkMake_<Type>()` lazy factories injecting fields by type), and **cycle
  detection** (`rkEnter`/`rkDone` guard — at **runtime**, since a per-decorator
  process has no whole-graph view).
- **F4 (done)** — the controller decorator walks `decl.methods`, reads
  `#[getMapping(path)]`/… from `method.annotations`, `@emit`s the router table
  (`route` prefix + `:param`); `dispatch` matches path params; `Response` builders
  type-check against the handler return type. Green in-test via `rkDispatch`.

> **Mechanism reality (verified 2026-06-10).** Each decorator runs in an isolated
> node process — no shared comptime registry, no top-level mutable `var`. So the
> scan/cycle/router state lives in a **host runtime** (`runtime.mjs` behind
> `#[@external]`) and each decorator `@emit`s self-registering code + a lazy
> factory. The *comptime* cycle diagnostic is the one genuine casualty (runtime
> instead). Core fixes this needed already landed: cross-module host-`#[@external]`
> lowering + import dedup (`14cd527`); `@Decl` field-annotation reflection +
> `test/` modules excluded from the test aggregator.

What remains is the **DI scopes** and the **real server**.

## Steps

### F2-scopes — singleton scope + factory/property injection
- [ ] Singleton scope: one shared instance per component type (currently
      fresh-per-resolve — the lazy `__rkMake_<Type>()` re-runs each call). Memoize
      in the host registry so a 3-level chain shares one repo/service instance.
- [ ] `#[configuration]` + `#[bean]` factories: a `#[bean]` fn's return type
      becomes injectable by type (the factory output is registered as a leaf in the
      DI graph). `#[configuration]` records group bean factories.
- [ ] `#[value("key")]` property injection: a `#[value]`-annotated field is filled
      from a config source, **excluded** from the DI graph (property injection, not
      an edge). `@Decl` now reflects field annotations, so detection is unblocked.

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` from scaffold to a real minimal HTTP surface (listen,
      route dispatch, request/response bridge) behind `#[@external]` host calls
      (node `http` first; then erlang `gen_tcp`/`inets`/`cowboy`).
- [ ] `Request` gets a concrete server-supplied implementation:
      `param`/`query`/`header`/`body`.
- [ ] `Rakun.run(app)` reads the host router and starts `libs/server` on
      `app.port`/`basePath`. **Needs G2:** ship the runtime `.mjs` next to the
      emitted module so a *consumer* build resolves it (today only the lib's own
      tests resolve `runtime.mjs`).
- [ ] End-to-end: a request to a mapped route invokes the handler with a live
      `Request` and returns its `Response` (status + body) over the wire.

## Test scenarios

```
comptime ---- a 3-level DI chain (repo → service → controller) resolves a SINGLE
              shared instance per type (singleton scope)
comptime ---- #[bean] factory output is injectable by its return type
infer    ---- #[value("port")] field is filled, NOT treated as a DI edge
run      ---- GET /api/users/  returns 200 with the joined user list (over real http)
run      ---- GET /api/hello/ana returns 200 "Hello, ana!"  (path param, real http)
run      ---- an unmapped path returns 404
```

## Notes

- Constructor injection only; singleton is the only scope in v1 (no request/proto
  scope, no graceful-shutdown / middleware).
- `libs/server` realness + runtime-`.mjs` shipping (**G2**) gate F5 — keep the
  server minimal (node first, then erlang).
- Comptime constraints on decorator bodies (no sibling calls, `if`-expr, bare-`if`
  only last, block-lambdas) force the factory builder to be inlined per marker.
  Memory: [[reference_bp_parser_comptime_gotchas]].
- The interim core-coupled F2/F3 reference lives on the preserved `task/rakun`
  branch (`feb96f0`) — port the *behaviour* into `.bp`, never the Zig.
