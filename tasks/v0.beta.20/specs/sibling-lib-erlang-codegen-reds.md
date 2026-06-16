# sibling-lib-erlang-codegen-reds — defer 4 sibling-lib erlang reds to v0.beta.21

**Slug**: sibling-lib-erlang-codegen-reds
**Depends on**: `ci-tail-02-backends-parity (E half)` — the annotation-driven `-compile({no_auto_import,...}).` directive (`erlang.zig`, ci-tail commit `0568466`) clears every BIF-shadowing surface, but the 4 sibling libs (erika · jhonstart · onze · rakun) carry pre-existing erlang-codegen reds that are **not** BIF related. The directive alone is insufficient to flip their `allow_fail: true` rows on the `erlang` axis.
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/erlang.zig`
    (per-cluster fix sites; each cluster below maps to a discrete codegen surface)
  - `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`
    (`allow_fail: true` → `false` on the erlang axis once the underlying
    cluster lands)
**Touches docs**: `tasks/v0.beta.20/status.md` · `tasks/v0.beta.21/status.md` (created when v21 opens).
**Status**: **deferred to v0.beta.21** — this spec is the audit + ticket; the
fixes themselves do not land in v0.beta.20.

## Per-lib triage (captured against meta `932256a` / bot-lang `f57a8cd`)

Every red below was reproduced via `zig build test-libs -- --target erlang
--lib <name>` from `repository/botopink-lang/` with the lib placed under
`repository/botopink-lang/repository/<name>/`.

### erika

```
.botopinkbuild/test-out/erika.erl:95:5:  function forEach/2  undefined
.botopinkbuild/test-out/erika.erl:249:5: function fold/3     undefined
.botopinkbuild/test-out/erika.erl:302:5: function fold/3     undefined
.botopinkbuild/test-out/erika.erl:342:1: function count/1    already defined
.botopinkbuild/test-out/erika.erl:345:1: function toArray/1  already defined
.botopinkbuild/test-out/erika.erl:655:42 function toString/1 undefined
.botopinkbuild/test-out/erika.erl:797:42 function toString/1 undefined
```

Two distinct surfaces:

1. **`std/array` method dispatch on the erlang backend**. `forEach/2`,
   `fold/3`, `toString/1` are interface-default associated fns surfaced
   via `interface Array { default fn forEach(self, f); default fn fold(self, seed, step); }`.
   The commonJS emitter resolves these through `prim_erlang_dispatch`;
   the erlang emitter does not yet wire the same path on the receiver side
   for the chained-self form (`.where(...).forEach(...)`). Fix lives in
   `codegen/erlang.zig` `emitMethodCall` + `collectInterfaceDispatch`.
2. **`count/1` + `toArray/1` duplicate definitions**. Both arise from the
   same `extend Array` block being lowered twice: once as a generic
   `extend` and once as a typed dispatch site under `instance_lowerings`.
   The dedup pass in `commonJS.zig` `dedupExtensionEmits` has no
   equivalent in `erlang.zig`.

### jhonstart

```
.botopinkbuild/test-out/hooks.erl:100:5: function set/2       undefined
.botopinkbuild/test-out/hooks.erl:115:5: function dispatch/2  undefined
.botopinkbuild/test-out/hooks.erl:120:5: function set/2       undefined
.botopinkbuild/test-out/hooks.erl:144:103: function toString/1 undefined
.botopinkbuild/test-out/html_test.erl:34:12: function 'div'/1 undefined
.botopinkbuild/test-out/html_test.erl:34:19: function p/1     undefined
.botopinkbuild/test-out/html_test.erl:34:22: function text/1  undefined
.botopinkbuild/test-out/html_test.erl:35:12: function renderToString/1 undefined
```

Two surfaces:

1. **Hook host-cell dispatch (`set/dispatch`) on the erlang backend**.
   `hooks.bp` defines a hook handler with `set` + `dispatch` as
   `#[@external(commonJS, "...")]` host-backed fns. The erlang emitter
   silently emits the user-facing botopink names as bare calls instead
   of routing through the `MissingExternalTarget` diagnostic surface.
   Fix lives in `codegen/erlang.zig` `emitExternalCall` (extension of the
   §A2 annotation-driven pattern landed for std).
2. **HTML DSL dispatch (`div/1`, `p/1`, `text/1`, `renderToString/1`)**.
   `html.bp` lowers the `html """…"""` template through
   `q.custom`/`@ExprCustom<Element>` → final builder calls. The erlang
   emitter has not been taught the lowering yet; the commonJS emitter
   uses `comptime_vals` to materialise the builder fn name. Fix lives in
   `codegen/erlang.zig` `emitCustom` (mirroring the commonJS path).

### onze

```
error: compilation failed
  MissingExternalTarget
```

A `@[external]` decl on a synth-mock site has no erlang target. The
`onze` lib hard-codes `commonJS` as the only target for its `#[mock]`
runtime probe. Fix is one of:
- Author an erlang-target shim for the probe (`mock_runtime.bp`
  `#[@external(erlang, ...)]`); or
- Mark `onze` lib `target: ["commonJS"]` in `botopink.json` so the
  matrix skips erlang (mirrors `jhonstart`'s commonJS-only stance).

The second option is the lowest-risk close — `onze` is a mocking lib for
the commonJS runtime first; an erlang port is a separate feature
discussion.

### rakun

```
.botopinkbuild/test-out/di_test.erl:53:13: function rkScannedNames/0  undefined
.botopinkbuild/test-out/di_test.erl:56:12: function rkScannedCount/0  undefined
.botopinkbuild/test-out/di_test.erl:59:5:  function rkScan/1          undefined
.botopinkbuild/test-out/di_test.erl:62:5:  function rkSingleton/2     undefined
.botopinkbuild/test-out/di_test.erl:63:14: function rkEnter/1         undefined
.botopinkbuild/test-out/di_test.erl:65:14: function rkDone/1          undefined
.botopinkbuild/test-out/di_test.erl:70:5:  function rkScan/1          undefined
.botopinkbuild/test-out/di_test.erl:73:5:  function rkSingleton/2     undefined
.botopinkbuild/test-out/di_test.erl:74:14: function rkEnter/1         undefined
.botopinkbuild/test-out/di_test.erl:76:14: function rkDone/1          undefined
```

`rakun` ships the DI primitives `rkScan`, `rkSingleton`, `rkEnter`,
`rkDone`, `rkScannedNames`, `rkScannedCount` as builder + comptime hooks
exposed via `#[@external(commonJS, ...)]`. The erlang backend has the
same gap as `jhonstart`'s hooks: no erlang-target shim, no
`MissingExternalTarget` surface, and the call sites fall through to bare
local references. Fix is the same as `jhonstart` cluster (1) — extend
`codegen/erlang.zig` `emitExternalCall` with the §A2 annotation-driven
fan-out plus an erlang-target shim in `rakun`'s root.

## Single ticket vs four

Both shapes are feasible. Recommendation: **single follow-up spec under
`v0.beta.21`** named `sibling-lib-erlang-codegen-completion` that
groups:

1. `erlang.zig` `emitExternalCall` extension (covers jhonstart `set`/`dispatch`/
   `toString`, rakun `rk*` family).
2. `erlang.zig` `emitMethodCall` + `dedupExtensionEmits` parity (covers
   erika `forEach`/`fold`/`toString`/`count`/`toArray`).
3. `erlang.zig` `emitCustom` (covers jhonstart `html_test` HTML DSL).
4. `onze` `botopink.json` `target: ["commonJS"]` (closes onze without a
   compiler change).

After (1)+(2)+(3)+(4) land, each `repository/{erika,jhonstart,onze,rakun}/
.github/workflows/test.yml` flips its `erlang: allow_fail: true` row to
`false` and the v0.beta.21 closeout sweep can drop the row entirely.

## Why not in v0.beta.20

The ci-tail spec's exit gate calls these out as DEFERRED, with this
audit as the per-lib breakdown the spec text required. Each cluster
above is independently scoped and worth its own per-frente landing under
the v0.beta.21 wave; bundling them into ci-tail risks coupling CI
hygiene to language-feature work that has nothing to do with workflow
shape.

## Exit gate (for v0.beta.21)

- `zig build test-libs -- --target erlang --lib erika` exits `0` with
  no `function … undefined` / `function … already defined` lines.
- Same for `--lib jhonstart`, `--lib rakun`.
- `onze` either reports `erlang` as skipped (botopink.json `target` array
  shrunk) or exits `0` with the shim in place.
- Each sibling-lib `.github/workflows/test.yml` shows
  `target: erlang, allow_fail: false` and the run is green on the
  meta `feat` HEAD that bumps the four submodule pointers.
