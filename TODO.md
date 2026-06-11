# TODO — rakun (Wave 3 of 3, v0.beta.11)

**Branch**: `task/rakun-finish` (from `origin/feat` @ f50de6d)
**Slug**: rakun · **Spec**: `tasks/v0.beta.11/specs/rakun.md`
**Depends on**: nothing — `@Decl`/`@emit`, F2 scan/graph/cycle, F3 placement, F4
router all landed in `feat` in-lib (`91db590`, `4eef880`, `0ff15a0`, `e10b49f`).
**Status**: F2-scopes + F5 DONE — 13 lib tests green; `examples/rakun` runs over real HTTP.

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
- [x] Singleton scope: each `__rkMake_<Type>()` is `rkSingleton("Type", { -> … })` —
      one shared instance per type (host cache), a 3-level diamond shares one repo.
      `rkBuildCount` proves it (`runtime.mjs#buildCount`/`singleton`).
- [x] `#[configuration]` + `#[bean]` factories: `#[configuration]` `@emit`s a
      `__rkMake_<ReturnType>()` per `#[bean]` method → the return type is injectable
      by type (a singleton, resolved by return-type name).
- [x] `#[value("key")]` property injection: the component factory reads
      `f.annotations`, fills a `#[value]` field from `rkProp`/`rkPropInt`, and keeps
      it OFF the DI graph (no `__rkMake_<i32|string>` edge — clean compile proves it).

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [x] `libs/server` is real: `server.mjs` is a node-`http` server (`serve`/`stop`);
      `server.bp` binds it via `#[@external]`. Framework-agnostic (generic over the
      response value `R`); rakun → server, never the reverse. (Erlang transport: follow-up.)
- [x] `Request` has a concrete server-supplied impl (`runtime.mjs#makeRequest`,
      built by `dispatchHttp`): `param`/`query`/`header`/`body`, all populated live.
- [x] `Rakun.run(app)` (`bootstrap.bp`) hands `libs/server` a dispatcher over the
      host router and listens on `app.port`. **G2 done:** the CLI ships the runtime
      `.mjs` next to every emitted module (`libs.zig#shipMjsSidecars`), so a consumer
      build resolves the `#[@external]` requires.
- [x] End-to-end: `examples/rakun` is a runnable app — `botopink build` + `node
      out/main.js` serves; every route below verified over a real socket with `curl`.

## Test scenarios

```
comptime ---- a 3-level diamond (repo ← service + controller) resolves a SINGLE  [✓ scopes_test]
              shared instance per type (rkBuildCount == 1)
comptime ---- #[bean] factory output is injectable by its return type            [✓ scopes_test]
infer    ---- #[value("port")] field is filled, NOT treated as a DI edge         [✓ scopes_test]
run      ---- GET /api/users/  returns 200 with the joined user list             [✓ server_test + example]
run      ---- GET /api/hello/:name returns 200 "Hello, ana!"  (path param)       [✓ server_test + example]
run      ---- an unmapped path returns 404                                       [✓ server_test + example]
```

The `run` scenarios are covered two ways: `server_test.bp` drives `rkDispatchHttp`
(the EXACT seam `libs/server` calls — match → live `Request` → handler → status/body,
synchronously, so it runs under `botopink test`), and `examples/rakun` exercises the
full node-`http` socket round trip end to end (manual `curl`; node's single thread
can't both serve and block on a client in one synchronous test).

## Notes

- Constructor injection only; singleton is the only scope (no request/proto scope,
  no graceful-shutdown / middleware).
- `Request.param`/`query`/`header` return `string` (`""` when absent), not `?string`:
  interface-method optional returns don't yet get the `@Option` lowering, and a
  required path var / empty default is the cleaner contract anyway.
- Core touched (all generic, lib-agnostic gate green): `commonJS.zig` require paths
  now prefix `../`×depth so a nested dependency module resolves correctly; CLI G2
  `.mjs` sidecar shipping in `libs.zig` (wired into `test_cmd.zig` + `build.zig`).
- Comptime constraints on decorator bodies (no sibling calls, `if`-expr, bare-`if`
  only last, block-lambdas) force the per-field injection + factory builder to be
  inlined per marker.
- Keep AGENTS.md / docs.md updated in the same commit as code changes.
