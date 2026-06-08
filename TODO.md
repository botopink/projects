# TODO — stdlib-backends-and-tooling

> Live checklist for branch `task/stdlib-backends-and-tooling` (worktree
> `.tasks/stdlib-backends-and-tooling/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/stdlib-backends-and-tooling.md`](tasks/v0.beta.6/specs/stdlib-backends-and-tooling.md)

> **Goal**: finish what v0.beta.4 left open — the stdlib-interface **JS** path is
> done; this is the other backends, the dispatch stragglers, the inference
> correctness, the backend-parity F1–F6, and editor-experience F0–F5.

## Part A — stdlib-interface: dispatch + other backends
- [ ] A1 — mirror JS instance/associated-method lowering in `erlang.zig`,
      `beam_asm.zig`, `wat.zig`; `std_erlang.sh` green
- [ ] A2 — dispatch stragglers: ✅ `s.contains()`→`includes` (type-aware,
      loc-keyed `jsMethodRenames`, JS-only — `record Set.contains` unaffected);
      ⬜ `@[external]` associated fns (`Array.range`/`repeat`), record-method-body
      inference walk, companion `primitives.mjs`/`.erl`
- [ ] A3 — inference: type-check `default fn` bodies; generic-extends-generic +
      literal method receivers (parser)

## Part B — backend-parity F1–F6 (from v0.beta.3)
- [ ] F1 literal method receivers · F2 snake→camel dispatch · F3 erlang/beam std
      loading · F4 `?.` codegen (erlang/beam/wasm) · F5 wasm test runner ·
      F6 duplicate test-name warning

## Part C — editor-experience F0–F5 (from v0.beta.3) ✅ DONE
- [x] F0 semantic tokens · F1 inlay hints · F2 VS Code tasks+matcher ·
      F3 CodeLens+status bar · F4 Testing API (all landed in 25073f7) ·
      F5 docs+manifest (README/AGENTS already cover F0–F4; CHANGELOG.md added +
      extension `version` → 0.3.0)

## Notes
- Accepting `@[external]` indiscriminately collapsed the suite once (516 fails) —
  restrict to JS globals (`Math`); keep companions permissive until lowering lands.
- Tests: `zig build test` + `botopink test` in every `libs/*`; `std_erlang.sh`
  green once A1 lands.
