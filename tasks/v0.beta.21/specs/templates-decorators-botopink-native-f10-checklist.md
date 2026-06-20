# F10 — Cleanup checklist (delete persistent_node.zig)

> Companion to [`templates-decorators-botopink-native.md`](templates-decorators-botopink-native.md). Run this list **after** F8 + F9 ship real `evaluateWat` outputs and one release cycle has logged zero JS-fallback fires.

## Gate (must be true before F10 runs)

- [ ] `template_eval.evaluateWat(...)` returns real outputs for every audit body in [`templates-decorators-botopink-native-audit.md`](templates-decorators-botopink-native-audit.md).
- [ ] `decorator_eval.evaluateWat(...)` returns real outputs for every decorator body in the audit.
- [ ] `infer.zig` (or the caller) switches default `runtime` from `.node` to `.wat`. Add to commit message: "v0.beta.21 — default comptime runtime is wat3".
- [ ] One release cycle has passed with the new default + zero observed `evaluateWat → error.EvalFailed → evaluateNode` fallback fires in production builds (log via `std.log.warn`).

## Inventory (every callsite F10 touches)

Files that import `persistent_node`:

| File | Use | F10 action |
|---|---|---|
| `modules/compiler-core/src/comptime/template_eval.zig:24` | `evaluateNode` fast path | **DELETE** import; delete `evaluateNode` whole; rename `evaluateRuntime` → `evaluate`; drop the `Runtime` enum (only `wat` remains, so no enum needed). |
| `modules/compiler-core/src/comptime/decorator_eval.zig:26` | `evaluateNode` fast path | Same pattern as template_eval. |
| `modules/compiler-core/src/comptime.zig:383` | `warmPersistentNodeRunner` fn | **DELETE** the fn body + the `@import` inside. |
| `modules/compiler-core/src/test_warmup.zig:22` | Calls warmPersistentNodeRunner | **DELETE** the call line. Adjust the test's purpose comment. |
| `modules/compiler-core/src/codegen/runtime.zig:34,167` | `executeJavaScript` fast path | **OUT OF SCOPE — KEEP.** This runs the USER's program for RUN LOG capture, not comptime. Same rationale as `executeErlang`/`executeBeamAsm` staying. |

Files that **document** persistent_node (purely narrative):

| File | F10 action |
|---|---|
| `modules/compiler-core/src/comptime/runtime/AGENTS.md` lines 24/27/30/71 | Update prose: remove "stays because template_eval / decorator_eval execute…" — the spec these references is now done. |
| `modules/compiler-core/src/comptime/runtime/docs.md` line 38 | Same. |
| `modules/compiler-core/src/comptime/runtime/wasm3_host.zig:4` (comment about "same pattern as persistent_node's child-process singleton") | Keep the architectural comparison — wasm3_host's own singleton design rationale doesn't change. |
| Root `AGENTS.md` "Build & test" section's required-PATH matrix | **REMOVE `node`** from required binaries. Mention only as optional for running the user's generated CommonJS output (parity with `wasmtime` / `erl`). |
| `CHANGELOG.md` v0.beta.21 entry | Add the F10 closeout line. |
| `tasks/v0.beta.21/status.md` row | `templates-decorators-botopink-native` → "**DONE**". |

The file `modules/compiler-core/src/comptime/runtime/persistent_node.zig` itself is **DELETED** in the same commit as the import-site updates.

## Acceptance gate

```bash
grep -r "persistent_node\|warmPersistentNode" modules/compiler-core/src
```

must return:

- Zero matches in source code (`.zig` files), **excluding** `codegen/runtime.zig:executeJavaScript` (the RUN-LOG capture path that stays — search filter `--include='*.zig' --exclude=codegen/runtime.zig`).
- Zero matches in `comptime/runtime/AGENTS.md`, `comptime/runtime/docs.md`, root `AGENTS.md`.
- Comments-only matches OK in `CHANGELOG.md` historical entries.

## Final docker smoke

A clean Linux container with only the compiler binary (no `node` / `erl` / `wasmtime` / `escript` installed) successfully compiles a template-heavy `.bp` to byte-identical output vs the pre-F10 build. Spec exit gate.

## Why this checklist exists separately

The mechanical work (delete file, drop imports, regex `grep` the surface) is small and shouldn't block on writing fresh prose at gate-flip time. Capture it once now; execute it once gate flips.
