# TODO — Front C: runtime, CLI & editor tooling test coverage (v0.beta.13)

**Branch**: `task/v13-tooling` (from `origin/feat` @ eac9313)
**Spec**: `tasks/v0.beta.13/specs/front-c-runtime.md`
**Front territory** (edit ONLY here): `modules/compiler-cli/tests/*.sh` ·
`modules/lib-test-runner/**` · the wasm/beam run harness · `modules/language-server/**` ·
`modules/vscode-extension/**`. File-disjoint from Fronts A (`task/v13-core`) and B
(`task/v13-libs`).
**Status**: C1–C4 all done (test-only + recorded reds; one real `FileCache` leak fixed)

> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test. Goal:
> close each `[gap]` (add the test / harness) or record the limitation. No production
> behaviour change expected (except the vscode F0 test harness scaffolding).

## Sections (see front-c-runtime.md for the tagged scenarios)

- [x] C1 test-tooling — DONE: `test_tooling.sh` (empty test, --filter multiple/none,
      `assert msg`, mixed pass/fail exit) + `Summary.exitCode` unit test (mixed-matrix exit).
      Recorded: uncaught-throw (no portable throw construct; assert-fail shows graceful catch),
      wasm-target lib exec (lib-test-runner is commonJS/erlang only).
- [x] C2 backend execution — DONE: `backend_exec.sh` + `zig build test-backends` (single step
      reaching beam+wasm). Green: std_erlang.sh (case…of fixed upstream), wasm numeric smoke
      (`numeric`→55), node/erlang records+enum+case+lambda, beam tail recursion (`sumTo`),
      multi-folder mod on commonJS. Pinned Front-A reds (non-fatal): beam case-dispatch/lambda,
      beam call+call arithmetic, erlang cross-module call qualification.
- [x] C3 language-server — DONE for v13: cross-module references/rename/import-missing
      (`cross_module.zig`, project-index over on-disk fixture), lifecycle didOpen→change→close
      (`lifecycle.zig`, + fixed a real `FileCache.change` leak), codeAction remove-import,
      typeDefinition generic, comptime `@external` fail diagnostic. Recorded/deferred:
      add-missing-case (exhaustiveness suppresses bindings), annotation-fail range (Front A),
      typeDef optional/fn-typed, async-unwrap Future/AsyncIterator, decorator-`@emit` +
      local-scope completion/def `→ v14`. See spec C3 status block.
- [x] C4 vscode-extension — **F0 DONE**: `node:test` harness (`npm test` / `zig build
      test-vscode`); pure logic extracted into 6 `vscode`-free leaf modules; all 15 pure-unit
      scenarios green (parseTestOutput, argsFor/label/group, quoteArg, symbol predicates,
      target fallback + round-trip, resolveBinPath). Host-integration + static-contribution
      checks deferred (need `@vscode/test-electron` + a built LSP; recorded in spec C4).

## Done means
`zig build test` + `botopink-lib-test` green with new Zig LSP tests, CLI run scripts, and the
vscode unit harness; every C-front `[gap]` closed or recorded. Integrate into `feat` via a
throwaway `.tasks/_integrate-v13-tooling`.
