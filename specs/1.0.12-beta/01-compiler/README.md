# Track 01 — compiler

**Repos:** in `repository/botopink-lang/`: `modules/**` (compiler-core, compiler-cli, bpmp,
language-server, lib-test-runner, test-shard, wasm3), `tests/language/**`, `scripts/**` (runners,
audits), `docs.md`, the compiler's `AGENTS.md` files; erika (`07-residuals`).

## Goal

Every program `botopink check` accepts runs the same on commonJS, erlang, wasm, beam, or is refused
located, by name; toolchain ships what `test` ships; std builds on wasm; every builtin declared and
held to it; decorators write into decision 216's four places, `@emit` leaves; the `;` after a braced
block leaves the ecosystem and the parser refuses it. Each open row = behaviour + cell in its front,
cut by file ownership so fronts run in parallel.

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`01-checker/`](./01-checker/README.md) | high | partial: steps 1–9, 11, 12, 14–17, 19, 20 on feat, 18 built with one box open; 6 (box 3), 10, 13, 21, 22, 23 and ten rows open | the checker and parser rows; the hooks in `@Decl` (277); numeric suffixes (247), type application and `comptime <expr>` (255, built), `comptime` at compile time (266), the prelude scope (270), the `@block` tail and `$stringify` refusals | 04 step 6 · 16 step 8 · 05 (step 13) · `08-bpp/116` (the prelude list) |
| [`02-erlang/`](./02-erlang/README.md) | high | partial: steps 1–3, 5, 6, 8, 9, 11–13 on feat; 4, 7, 10 open | `run/array_unique`, C-07's `run/` cells, one `math` (263), overflow aborts (264) | 05 · 01 (`@block`) · the std track (263) |
| [`03-beam/`](./03-beam/README.md) | high | partial: steps 1–8 on feat; 1 (box 3), 2 (box 1), 9 open | 01 step 13's and 02 step 7's cells on beam; 263, 264 in assembly; row 28's `{badfun, ok}` | 01 · 02 · 05 · the std track |
| [`04-js/`](./04-js/README.md) | medium | partial: steps 3, 4, 5, 7, 8 and C-37 on feat; 1, 2, 6 open | the `@block` tail IIFE, `$stringify` (239), `throw` in a `case` arm, overflow aborts (264) | 01 |
| [`05-wasm/`](./05-wasm/README.md) | high | partial: steps 1–4 on feat (two cells wait on 02); step 5 under way (heap growth, `fromCodepoint`, `pow`, astral `contentHash`, one `math` on feat; `unicode`, `json`'s two cells, family cells open) | the rest of std on wasm: heap growth (261), `String.fromCodepoint` (262), `pow` (259), `contentHash` (260), one `math` (263) | 02 · the std track · 18 |
| [`07-residuals/`](./07-residuals/README.md) | low | not started (08's items 1–2, 09's item 1, 25's steps 2–3 done elsewhere) | the 1.0.1-beta snapshot review (C-22); comments and documents (C-23, C-18, the `@BeamMemory` text); erika's migration and the pointers' sweep; the per-cell compile row | 02–05 · 01 · 16 · C-14 |
| [`12-language-tests/`](./12-language-tests/README.md) | medium | partial: steps 1 (box 1), 2 (box 2), 3, 4 on feat; 1 (box 2), 2 (box 1) open | the two missing area cells, `--cold` on the pre-existing tool set | 01/04 · 02/05 · `00-gate/114` |
| [`14-comptime-on-beam/`](./14-comptime-on-beam/README.md) | medium | partial: steps 1 (fixture half), 3, 4 and decision 237 on feat; 2, 6, 7 open | the N=200 budget, a decorator body with `\u{…}` | 18 · 01 · lg2-j/o/w |
| [`16-formatter/`](./16-formatter/README.md) | medium | not started | C-13 step 3 (the `;` refused), the siblings' reformat, the one-line trailing lambda (165), a trailing comma decides (166, 243), the lambda annotation's printer arm, annotations printed as written (286) | the library tracks' migrations · 01's parser rows · 16-a/16-b |
| [`17-beam-memory/`](./17-beam-memory/README.md) | medium | partial: step 1 on feat but box 4; step 2 open | the per-row increment (17-b), the text handed to 07 | 17-b · 07 |
| [`18-comptime-runtimes/`](./18-comptime-runtimes/README.md) | low | not started | the CI rows, the wat runtime's limits, the bench table, the transport test, `memory.grow` in the binary emitter | the maintainer · 14 · 05 |
| [`23-std-purity/`](./23-std-purity/README.md) | low | not started | the import cells and LSP snapshots, three confirmations | 23-b/c, std-c |
| [`24-effects-by-return/`](./24-effects-by-return/README.md) | medium | not started | the guide as one program, four confirmations, the per-item cost | rakun's `serverAction` · 24-a/b/c/g |
| [`26-cli-tooling/`](./26-cli-tooling/README.md) | high | partial: steps 1, 2 (boxes 1–2), 3 (box 2), 4 (box 1), 5 on feat; 2 (box 3), 3, 4, 6, 7, 8 open | only a direct dependency importable (242), warnings in `build`/`test`, the LSP's import check | compiler-core's `ModuleOutput` · lg2-v · 23 |
| [`129-import-without-from/`](./129-import-without-from/README.md) | high | done | `from` names a package (206) | — |
| [`130-decorator-outputs/`](./130-decorator-outputs/README.md) | high | partial: steps 1–4 on feat; 5 (34 of 119 sites), 6 open | the library sites, `@emit` removed | 01 step 20 (256's registry) · the library tracks |
| [`134-builtins-declared/`](./134-builtins-declared/README.md) | high | partial: steps 1, 3 on feat; 2 partial | the type functions, the `result` namespace, the `@Result`/`?T` methods, `@is` | 134-a…d |

## Ownership

Fronts share no source file or snapshot directory except by named, sequenced carve-out:

- `codegen/beam/{erl_ast,erl_emitter}.zig` (Erlang-text renderer) 02 · keyed-`Ets` functions of
  `erlang.zig` and `beam_asm.zig` 17 · `codegen/beam/asm_text.zig` 14 · `beam_file.zig`,
  `opcodes.zig`, `wat/wasm_binary_emitter.zig` 18.
- `codegen/tests/**`, `comptime/tests/**`, `parser/tests/**`, `language-server/src/tests/**` 07;
  per-backend fixtures to their backends (`erlang.zig` 02, `beam.zig` 03, `commonjs.zig` 04,
  `wat.zig` 05); 14's `comptime_module.zig` fixtures.
- `parser.zig`'s `isBracedBlockStmt` and `blockStatementSemicolon` kind: 16 for step 3, after 01's
  parser rows; 16 step 8 (annotation printer arm) before 01 step 10.
- `docs.md` prose 07 (23, 24, 26 supply section text); its marker/fence lines,
  `scripts/check-docs.sh`, `test.yml`, `gate.sh` budget lines `00-gate/114`; `release.yml` 18; root
  `build.zig` 26 except 18's `render-resident` / `compiler-web` steps.
- Runners (`scripts/{gate.sh,test-libs.sh,lib/pool.sh}`, `tests/language/run.sh` beyond 12's report
  and `all)` line, `modules/test-shard/**`, `modules/lib-test-runner/**`): no open owner (since
  `25-gate-perf`, 115, 133 closed) — an editing front names the carve-out in its commit.
- `libs/std/**`: std track (`../02-std-and-packaging/`); a std row a compiler front measures is
  handed over with its cell; carve-outs: 17's `beam.bp` primitives, 130/134's `builtins.d.bp` parts.
- 07 steps 1 and 4 (re-derive/rename in backend snapshot dirs): after 02–05.

## Decisions

Open ids waited on — statements in [`../decisions-pending.md`](../decisions-pending.md); 1.0.10
choices to confirm (16-a/b, 23-b/c, std-c, 24-a/b/c/g, 01c-a/b, 0405-b) in
[1.0.10's](../../1.0.10-beta/decisions-pending.md); front in parentheses:
**17-b, 17-c** ([`17-beam-memory`](./17-beam-memory/README.md) § Decisions) · **134-d**
(134) · **C-14** (07 step 9) · **16-a, 16-b** (16) · **23-b, 23-c, std-c** (23) · **24-a, 24-b,
24-c, 24-g** (24) · **01c-a, 01c-b** (01) · **0405-b** (04) · **imp-a** (01) · **lg2-a … lg2-w**
(`lg2-k` answered by 216): none opens a front until answered, each then a step — 01 lg2-a/e/f/q +
parser rows lg2-m/r/t, 14 lg2-j/o/w, 26 lg2-v; `lg2-l` maybe de facto (`@panic` / `@todo`
`noreturn`, a branch ending in one narrows): maintainer confirms, row closes.

Every recommendation: most restrictive behaviour, nothing configurable bypasses it (decision 67).

## Rules

- Backend builds a model, emitter renders it; a snapshot is evidence, not baseline — re-record only
  a value verified by running.
- Gate runs from a cold runtime cache; nothing skipped for speed (decision 67), no bypass of a
  refusal, no tolerated-red list.
- Compiler knows no library: a library need = a `language-gaps.md` row + a front here, workaround in
  the library meanwhile.
- An area front's cell lands in its commit, one file per cell, proved able to fail on the parent
  binary (`tests/language/AGENTS.md` § Who adds a cell).
