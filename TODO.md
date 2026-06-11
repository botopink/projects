# TODO — Front C: runtime, CLI & editor tooling test coverage (v0.beta.13)

**Branch**: `task/v13-tooling` (from `origin/feat` @ eac9313)
**Spec**: `tasks/v0.beta.13/specs/front-c-runtime.md`
**Front territory** (edit ONLY here): `modules/compiler-cli/tests/*.sh` ·
`modules/lib-test-runner/**` · the wasm/beam run harness · `modules/language-server/**` ·
`modules/vscode-extension/**`. File-disjoint from Fronts A (`task/v13-core`) and B
(`task/v13-libs`).
**Status**: pending

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test. Goal:
> close each `[gap]` (add the test / harness) or record the limitation. No production
> behaviour change expected (except the vscode F0 test harness scaffolding).

## Sections (see front-c-runtime.md for the tagged scenarios)

- [ ] C1 test-tooling — `test {}`, `botopink test`, lib-test-runner (gaps: wasm-target lib
      exec, uncaught-throw → FAIL, `assert msg`, empty test, multi-filter, mixed-matrix exit)
- [ ] C2 backend execution — the `run/*` Front A snapshots can't prove (gaps: std_erlang.sh
      green / pin the `case…of` red, beam program run, wasm wasmtime smoke, interpolation +
      Result/case parity, closures make_fun, beam tail recursion, multi-folder mod build+run)
- [ ] C3 language-server — every LSP request + CustomNode overlay (gaps: `compileMulti`
      cross-module fixtures for completion/def/refs/rename, decorator-`@emit` bindings,
      local-scope completion/def, codeAction remove-import / add-cases / import-missing,
      lifecycle didOpen→change→close, async-unwrap hover; some tagged `→ v14`)
- [x] C4 vscode-extension — **F0 DONE**: `node:test` harness (`npm test` / `zig build
      test-vscode`); pure logic extracted into 6 `vscode`-free leaf modules; all 15 pure-unit
      scenarios green (parseTestOutput, argsFor/label/group, quoteArg, symbol predicates,
      target fallback + round-trip, resolveBinPath). Host-integration + static-contribution
      checks deferred (need `@vscode/test-electron` + a built LSP; recorded in spec C4).

## Done means
`zig build test` + `botopink-lib-test` green with new Zig LSP tests, CLI run scripts, and the
vscode unit harness; every C-front `[gap]` closed or recorded. Integrate into `feat` via a
throwaway `.tasks/_integrate-v13-tooling`.
