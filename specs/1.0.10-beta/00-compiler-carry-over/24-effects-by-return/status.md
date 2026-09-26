# Front 24 — status

One line per landed step; the boxes are in [`README.md`](README.md).

- Step E6 (the codemod) — compiler `ba529e09` on `front/24-codemod`: `botopink migrate effects
  [--dry-run]` (`modules/compiler-cli/src/cli/migrate_effects.zig`) — pre-121 spellings normalised,
  the project type-checked once with the checker's new `ExprTypeLog` (a tooling hook in
  `comptime/infer.zig`), then every row of § *Codemod* and of guide.md § 9 rewritten or marked
  `// TODO(migrate-effects)`; open point 5 marked; open point 7 in `decisions-pending.md` (`migrate`
  keeps its meaning, `effects` is a subcommand). Two snapshots, idempotence and `--dry-run` unit
  tests, contract row C8b. Dry-run over a copy of `libs/std` (14 files, annotations and wrappers
  only) and of the jhonstart / rakun members at the main checkout's pins: no crash, modules that do
  not type-check at this compiler marked, not guessed. Not yet run for real on the libraries (E7).
- Integration (`front/24-integration`, 2026-09-26) — compiler `e993c4ee`: E1–E5 + std, cells, type
  aliases, LSP, docs (E8, `f7d2b20d`), the codemod chain (E6, `ba529e09` · `d4217805` · `b2985088`),
  `front/24-wasm-strings`, `front/24-backend-defects` and `front/24-beam-cells` merged; hazard 24-d
  resolved by a migration-only mode (`decisions-pending.md` 24-d), the codemod's output byte-identical
  to the pre-E2 binary's over the five libraries. Libraries at their front-24 sweeps (jhonstart
  `0206b91`, emilia `273b08d`, onze `b1e690d`, rakun `7ca7f2c`, erika unchanged), vscode-extension
  `cbe31cb`. `known-red-libs.txt` back to its header; `restricted-targets.txt` back to measured counts
  (jhonstart-counter erlang stays `build`, `set/2`). Measured from a copy outside the meta checkout
  (24-f): `zig build test` 2464/2464; `test-language` 773 passed / 32 expected / 0 failed
  (commonJS, erlang, wasm) and `--target beam` 198 / 8 / 0; `test-docs` 68 checked / 0 failed;
  `test-libs` 54 passed, 0 failed, 0 known red, 19 restricted as pinned, 17 without tests (per-test
  counts not compared with the pre-sweep ones); `test-cli`, `test-bpmp`, `format-check.sh` green; `scripts/gate.sh --cold` green end to end;
  vscode-extension `npm test` 49/49 and `compiler-check` passed.
- Close-out (`front/24-integration`, 2026-09-26) — compiler `f7398c40`: `front/24-yieldstep`,
  `front/24-cells`, `front/24-type-alias` and `front/24-lsp` merged; the migration mode reads the pre-122
  `YieldStep<T, E>` as `YieldStep<T>` (`816ec3b9` — RG5's arity check on the now-registered type had left
  the codemod's fixtures untyped); the E2 lossless round-trip of `async { }`, `iter` / `stream while` /
  `for`, `try await` and `yield :label` (`f7398c40`). Gate from a standalone copy: `scripts/gate.sh --cold`
  green (`zig build test` 2474/2474, runtime parity 1415 pairs, beam export 468/468, test-libs 54 / 0 / 0
  known red / 19 restricted as pinned with every row at its pre-sweep count, test-language 785 / 28 / 0,
  test-docs 68 checked / 0 failed), `--target beam` 204 / 7 / 0, vscode-extension 49/49 and
  `compiler-check` passed. README: 68 boxes ticked, 3 open with their reasons (guide fences that do not
  type as written, the E8 grep's wording, `AGENTS.md` per commit).
