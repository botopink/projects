# Decisions the maintainer owes — 1.0.10-beta

**One open** — front 24's open point 7, below. Every other question this milestone raised is answered in
[`decisions-taken.md`](./decisions-taken.md) — 91, 92, 93 and 97 by decisions 103 and 104, 99 by 108,
94, 100 and 101 by 113; every number up to 117 is answered — 114 answers the eight seams decision 113 left open, 115 the five points 114 left open, 116 nine more pieces two libraries both run, 117 the nine points 113–116 left, and 118–127 register the maintainer's effect revision (the return type is the annotation, `@Task<T>`, only `@Result` fails, `@Iterator<T>` / `@Stream<T>`, `async { }`, `iter` / `stream` loops, no compatibility mode — front `00 · 24-effects-by-return`), and 128 merges `@Use<C, T>` and `@Component<T>` into `@Component<C, T>`. The next free number is **129**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

## Open

### `botopink migrate` beside `botopink migrate effects` (front 24, open point 7)

> **Raised by:** `00 · 24-effects-by-return` step E6, 2026-09-25
> **Measured.** At compiler `82e32e36`, `botopink migrate` (`modules/compiler-cli/src/cli/migrate.zig`)
> derives the explicit module tree — it prepends `pub mod X;` to `root.bp` / `main.bp` / `mod.bp` —,
> takes only `--dry-run` and refuses any positional: `botopink migrate src --dry-run` exits 1
> (`tests/cli_contract.sh` row C8). Front 24's README and guide name the effect codemod
> `botopink migrate effects`, which is a positional C8 refuses.
> **Options.** (a) `migrate` alone keeps its module-tree meaning; `effects` is a subcommand,
> recognised only as the first argument, so `migrate --dry-run effects` stays a usage error and C8
> holds unchanged. (b) The module tree moves to `migrate modules` and a bare `migrate` becomes a
> usage error listing the subcommands. (c) A bare `migrate` runs every migration.
> **Recommendation.** (a) — implemented on `front/24-codemod`, compiler `ba529e09` (`main.zig`, `parseMigrateEffectsOpts`;
> contract row C8b). Nothing that works today changes meaning, and a word in first position cannot be
> mistaken for the positional C8 refuses. (b) is the tidier surface but breaks a documented command
> for no gain in this milestone; (c) makes one command rewrite two unrelated things — the most
> restrictive reading of decision 67 is that each rewrite is asked for by name.
> **Blocks.** Nothing: E6 ships (a). The answer decides how E8's `docs.md` presents the command, and
> whether a later front renames the module-tree form to (b).
