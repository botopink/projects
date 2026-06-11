# TODO — rakun (Wave 3 of 3, v0.beta.11)

**Branch**: `task/rakun-finish` (from `origin/feat` @ f50de6d)
**Slug**: rakun · **Spec**: `tasks/v0.beta.11/specs/rakun.md`
**Depends on**: nothing — `@Decl`/`@emit`, F2 scan/graph/cycle, F3 placement, F4
router all landed in `feat` in-lib (`91db590`, `4eef880`, `0ff15a0`, `e10b49f`).
**Status**: pending

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test
> (no `--no-verify`).

## HARD RULE

`modules/compiler-core/src/**` keeps **zero** knowledge of rakun. Every behaviour
below is implemented in `libs/rakun/*.bp` as lib-side decorator bodies via `@emit`
over the generic primitives + a `#[@external]` host runtime.

> The old core-coupled F2/F3 line (the deleted `feb96f0`) is discarded — it
> reintroduced lib-specific code into the Zig core and was superseded. `feat`
> already has the correct in-lib F2/F4 (`libs/rakun/src/*.bp`); this task continues
> from there. Port any remaining *behaviour* into `.bp`, **never the Zig**.

## What already landed in `feat` (in-lib)

- **F2 (partial)** — component scan (`#[service]`/`#[repository]`/`#[controller]`
  → `rkScan`), DI graph (`__rkMake_<Type>()` lazy factories), runtime cycle
  detection (`rkEnter`/`rkDone`). Host runtime in `runtime.mjs` behind `#[@external]`.
- **F4 (done)** — controller decorator builds the router table from method
  `#[getMapping(path)]`/…; `dispatch` matches path params; `Response` builders
  type-check against handler return type. Green via `rkDispatch`.

What remains: **DI scopes** (F2-scopes) and the **real server** (F5).

## Steps

### F2-scopes — singleton scope + factory/property injection
- [ ] Singleton scope: one shared instance per component type (memoize the lazy
      `__rkMake_<Type>()` in the host registry so a 3-level chain shares one instance).
- [ ] `#[configuration]` + `#[bean]` factories: a `#[bean]` fn's return type becomes
      injectable by type (factory output registered as a DI-graph leaf);
      `#[configuration]` records group bean factories.
- [ ] `#[value("key")]` property injection: a `#[value]` field is filled from a
      config source and **excluded** from the DI graph (`@Decl` reflects field
      annotations, so detection is unblocked).

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [ ] Promote `libs/server` from scaffold to a real minimal HTTP surface (listen,
      route dispatch, request/response bridge) behind `#[@external]` host calls
      (node `http` first; then erlang `gen_tcp`/`inets`/`cowboy`).
- [ ] `Request` gets a concrete server-supplied impl: `param`/`query`/`header`/`body`.
- [ ] `Rakun.run(app)` reads the host router and starts `libs/server` on
      `app.port`/`basePath`. **Needs G2:** ship the runtime `.mjs` next to the
      emitted module so a *consumer* build resolves it.
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
- Keep AGENTS.md / docs.md updated in the same commit as code changes.
