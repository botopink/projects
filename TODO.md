# TODO — cross-module-codegen

> Live checklist for branch `task/cross-module-codegen` (worktree
> `.tasks/cross-module-codegen/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/cross-module-codegen.md`](tasks/v0.beta.6/specs/cross-module-codegen.md)

> **Goal**: bring erlang/beam/wasm to the commonJS backend's parity for concrete
> emitted types crossing the package boundary (a consumer importing
> `Response`/`App` from rakun). commonJS is the reference — match its behaviour.
> Files: `codegen/erlang.zig`, `codegen/beam_asm.zig`, `codegen/wat.zig`.

## F0 — erlang cross-package
- [ ] track which imported names come from which emitted module (mirror commonJS
      `CrossModule` index)
- [ ] imported-record assoc fn → remote call to the owner module atom; imported
      record construction → owner's map constructor
- [ ] emit `-export` for `pub` types/assoc-fns imported elsewhere

## F1 — beam_asm cross-package
- [ ] imported record construction (`put_map_assoc`) + cross-module `call_ext`
      for associated fns

## F2 — wasm cross-package
- [ ] decide the wasm module-linking story for imported types — or `log()` the
      explicit limitation if wasm stays single-module for now

## F3 — shared
- [ ] lift the commonJS `CrossModule` builder to a backend-agnostic analysis if
      it reduces duplication

## Notes
- `new` is a JS detail; botopink source never has `new`.
- wasm may legitimately defer — if so, record the limit and scope to erlang+beam.
