# TODO — cross-module-codegen

> Live checklist for branch `task/cross-module-codegen` (worktree
> `.tasks/cross-module-codegen/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/cross-module-codegen.md`](tasks/v0.beta.6/specs/cross-module-codegen.md)

> **Goal**: bring erlang/beam/wasm to the commonJS backend's parity for concrete
> emitted types crossing the package boundary (a consumer importing
> `Response`/`App` from rakun). commonJS is the reference — match its behaviour.
> Files: `codegen/erlang.zig`, `codegen/beam_asm.zig`, `codegen/wat.zig`.

## F0 — erlang cross-package
- [x] track which imported names come from which emitted module (mirror commonJS
      `CrossModule` index)
- [x] imported-record assoc fn → remote call to the owner module atom; imported
      record construction → owner's map constructor
- [x] emit `-export` for `pub` types/assoc-fns imported elsewhere

## F1 — beam_asm cross-package
- [x] imported record construction (`put_map_assoc`) + cross-module `call_ext`
      for associated fns

## F2 — wasm cross-package
- [x] wasm stays single-module: `emitWat` flags each cross-module import with an
      explicit `;; cross-module import not linked (wasm single-module)` comment
      instead of emitting a call to a missing function

## F3 — shared
- [x] lifted the commonJS `CrossModule` builder to a backend-agnostic
      `crossModule.zig` analysis consumed by commonJS, erlang, beam_asm and wat

## Notes
- `new` is a JS detail; botopink source never has `new`.
- wasm legitimately defers — limit recorded; parity scoped to erlang+beam.
- Done in `a9e2ad2`. Test: js_features "import ---- cross-module record
  construct and assoc fn" exercises all four backends; full `zig build test`
  green.
