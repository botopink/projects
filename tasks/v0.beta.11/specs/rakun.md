# rakun — finish the IoC scopes + the real server (F2-scopes · F5)

**Slug**: rakun
**Depends on**: nothing — the `@Decl`/`@emit` mechanism, F3 placement bodies, F2 scan/graph/cycle, and F4 router all landed in `feat` (`task/rakun-di`, `b8d9923`)
**Files**: `libs/rakun/src/*.bp` (ALL semantics — written in botopink), `libs/server/src/*` (HTTP backing — scaffold → real)
**Touches docs**: `libs/rakun/AGENTS.md`, `libs/rakun/docs.md`, `libs/server/AGENTS.md`
**Status**: **DONE** — F2-scopes + F5 landed in-lib (commit `1b222b5`, merged to
`feat` via `e1478d9`). 13 rakun lib tests green; `examples/rakun` runs over real HTTP.
See **Not done yet** below for the consciously-deferred items.

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
- [x] Singleton scope: each `__rkMake_<Type>()` is `rkSingleton("Type", { -> … })` —
      one shared instance per type (host cache), so a 3-level chain / diamond shares
      one repo/service. `rkBuildCount` proves it (`runtime.mjs#singleton`/`buildCount`).
      Key pattern: a GENERIC host external taking a thunk —
      `pub declare fn rkSingleton<T>(name, build: fn() -> T) -> T` (like onze's cells).
- [x] `#[configuration]` + `#[bean]` factories: the `#[configuration]` body walks
      `decl.methods` and `@emit`s a `__rkMake_<ReturnType>()` per `#[bean]` method →
      the bean's return type is injectable by type (a singleton, by return-type name).
- [x] `#[value("key")]` property injection: the component factory reads
      `f.annotations`, fills a `#[value]` field from `rkProp`/`rkPropInt`, and keeps
      it OFF the DI graph (no `__rkMake_<i32|string>` edge — a clean compile proves it).

### F5 — bootstrap (`Rakun.run` + real HTTP backing)
- [x] `libs/server` is real: `server.mjs` is a node-`http` server (`serve`/`stop`);
      `server.bp` binds it via `#[@external]`. Framework-agnostic — `serve(port,
      handler)` takes the dispatcher as a function, generic over the response value
      `R` (reads `R.status`/`R.body`), so the arrow is **rakun → server**, never the
      reverse. (Erlang `gen_tcp`/`inets`/`cowboy` transport: see **Not done yet**.)
- [x] `Request` is a real interface (`http.bp`) with a live host impl
      (`runtime.mjs#makeRequest`, built by `dispatchHttp`): `param`/`query`/`header`/
      `body`, all populated from the socket request.
- [x] `Rakun.run(app)` (`bootstrap.bp`, a concrete `Rakun` record) hands `libs/server`
      a dispatcher over the host router and listens on `app.port`. **G2 done:** the
      CLI ships the runtime `.mjs` next to every emitted module
      (`compiler-cli/src/cli/libs.zig#shipMjsSidecars`, wired into `test_cmd.zig` +
      `build.zig`), so a *consumer* build resolves the `#[@external]` requires.
- [x] End-to-end: `examples/rakun` is a runnable app — `botopink build` + `node
      out/main.js` serves; every route below verified over a real socket with `curl`.

## Test scenarios

```
comptime ---- a 3-level diamond (repo ← service + controller) resolves a SINGLE   [✓ scopes_test]
              shared instance per type (rkBuildCount == 1)
comptime ---- #[bean] factory output is injectable by its return type             [✓ scopes_test]
infer    ---- #[value("port")] field is filled, NOT treated as a DI edge          [✓ scopes_test]
run      ---- GET /api/users/  returns 200 with the joined user list              [✓ server_test + example]
run      ---- GET /api/hello/:name returns 200 "Hello, ana!"  (path param)        [✓ server_test + example]
run      ---- an unmapped path returns 404                                        [✓ server_test + example]
```

The `run` scenarios are covered two ways: `test/server_test.bp` drives
`rkDispatchHttp` (the EXACT seam `libs/server` calls — match → live `Request` →
handler → status/body, **synchronously**, so it runs under `botopink test`), and
`examples/rakun` exercises the full node-`http` **socket** round trip end to end
(manual `curl`). See the next section for why the socket trip can't be the
automated test.

## Not done yet (consciously deferred)

These were left out of scope — the framework is usable without them and each is a
sizeable, separable follow-up:

- **Erlang/BEAM server transport.** `libs/server` is **node-only** (`server.mjs`).
  An `escript`/`gen_tcp`/`inets`/`cowboy` backing is a recorded follow-up (the spec
  always staged it "node first, then erlang"). rakun's `#[@external]`s target `node`.
- **Comptime dependency-cycle diagnostic.** Cycle detection is at **runtime**
  (`rkEnter`/`rkDone` raise on first construction). A *compile-time* diagnostic needs
  a whole-graph view no single per-decorator process has — deferred.
- **A literal-socket *automated* test.** The "over real http" scenarios are covered
  synchronously through `rkDispatchHttp` (the exact dispatch seam) plus the manual
  `curl` run of `examples/rakun`; node's single thread can't both serve and block on
  a client inside one synchronous `botopink test`, so the TCP round trip is not an
  automated assertion.
- **`Request.param`/`query`/`header` return `string`, not `?string`.** Interface-
  method optional returns don't yet get the `@Option` lowering (a plain `fn -> ?T`
  does; an interface method's `-> ?T` doesn't, so `.unwrapOr` wouldn't lower). Chosen
  contract: a matched path var is always present and `""` is the natural default for
  a missing query/header (Spring's `@RequestParam(defaultValue = "")`). Fixing the
  interface-method `@Option` lowering is a **core** follow-up that would enable
  `?string` here.
- **`Context` IoC API.** `ctx.resolve<T>()` / `ctx.has<T>()` stay declaration-only
  in `rakun.d.bp` (documented shape, not implemented). DI is constructor-injection
  only; there is no programmatic container lookup yet.
- **Scopes beyond singleton + lifecycle.** No request/prototype scope, no graceful
  shutdown, no middleware/filters/interceptors. Singleton is the only scope.

### Generic core changes this required (all lib-agnostic; gate green)

- `codegen/commonJS.zig` `emitUse`: `require` paths now prefix `../`×depth (from the
  emitting module's path) so a **nested dependency** module resolves correctly —
  before, every `require` assumed the module sat at the output root, which broke a
  dep importing another package (`out/<dep>/x.js` requiring `./<dep2>/y.js`).
- **G2** `compiler-cli/src/cli/libs.zig#shipMjsSidecars`: copies each `#[@external]`
  `.mjs` next to the emitting module so the relative `require` resolves; the external
  paths were switched to the **sibling** `./x.mjs` so shipping stays inside the build
  tree (the old `../../src/x.mjs` resolved into a consumer's *source* dir).

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
