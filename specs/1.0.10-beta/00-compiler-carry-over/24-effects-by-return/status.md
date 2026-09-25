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
