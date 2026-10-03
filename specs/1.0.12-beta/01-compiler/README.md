# Track 01 — compiler

**Repos:** `repository/botopink-lang/modules/**` (compiler-core, compiler-cli, bpmp, language-server,
lib-test-runner, test-shard, wasm3), `repository/botopink-lang/tests/language/**`,
`repository/botopink-lang/scripts/**` (the runners and audits), `repository/botopink-lang/docs.md`,
the compiler's `AGENTS.md` files, and erika (`07-residuals`).

## Goal

Every program `botopink check` accepts runs with the same answer on commonJS, erlang, wasm and beam,
or is refused located, by name; the toolchain ships what `test` ships; std builds on wasm; every
builtin is declared and held to its declaration; a decorator writes into the four places of
decision 216 and `@emit` leaves the language; the ecosystem stops writing the `;` after a braced
block and the parser refuses it. Every open row is stated in its front as behaviour with a cell,
cut by file ownership so the fronts can run side by side.

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`01-checker/`](./01-checker/README.md) | high | partial: steps 1–9, 11, 12, 14–17 on feat; 6 (box 3), 10, 13, 18–20 and ten rows open | the checker and parser rows; numeric suffixes (247), type application and `comptime <expr>` (255), the prelude scope (266), the `@block` tail and `$stringify` refusals | 04 step 6 · 16 step 8 · 05 (step 13) · `08-bpp/116` (the prelude list) |
| [`02-erlang/`](./02-erlang/README.md) | high | partial: steps 1–3, 5, 6, 8, 9, 11 on feat; 4, 7, 10, 12, 13 open | `run/array_unique`, C-07's `run/` cells, one `math` (263), overflow aborts (264) | 05 · 01 (`@block`) · the std track (263) |
| [`03-beam/`](./03-beam/README.md) | high | partial: steps 1–6 on feat; 1 (box 3), 2 (box 1), 7, 8, 9 open | 01 step 13's and 02 step 7's cells on beam; 263, 264 in assembly; row 28's `{badfun, ok}` | 01 · 02 · 05 · the std track |
| [`04-js/`](./04-js/README.md) | medium | partial: steps 3, 4, 5, 7 and C-37 on feat; 1, 2, 6, 8 open | the `@block` tail IIFE, `$stringify` (239), `throw` in a `case` arm, overflow aborts (264) | 01 |
| [`05-wasm/`](./05-wasm/README.md) | high | partial: steps 1–4 on feat (two cells wait on 02); step 5 under way | the rest of std on wasm: heap growth (261), `String.fromCodepoint` (262), `pow` (259), `contentHash` (260), one `math` (263) | 02 · the std track · 18 |
| [`07-residuals/`](./07-residuals/README.md) | low | not started (08's items 1–2, 09's item 1, 25's steps 2–3 done elsewhere) | the 1.0.1-beta snapshot review (C-22); comments and documents (C-23, C-18, the `@BeamMemory` text); erika's migration and the pointers' sweep; the per-cell compile row | 02–05 · 01 · 16 · C-14 |
| [`12-language-tests/`](./12-language-tests/README.md) | medium | partial: steps 1 (box 1), 2 (box 2), 3, 4 on feat; 1 (box 2), 2 (box 1) open | the two missing area cells, `--cold` on the pre-existing tool set | 01/04 · 02/05 · `00-gate/114` |
| [`14-comptime-on-beam/`](./14-comptime-on-beam/README.md) | medium | partial: steps 1 (fixture half), 3, 4 and decision 237 on feat; 2, 6, 7 open | the N=200 budget, a decorator body with `\u{…}` | 18 · 01 · lg2-j/o/w |
| [`16-formatter/`](./16-formatter/README.md) | medium | not started | C-13 step 3 (the `;` refused), the siblings' reformat, the one-line trailing lambda (165), a trailing comma decides (166, 243), the lambda annotation's printer arm | the library tracks' migrations · 01's parser rows · 16-a/16-b |
| [`17-beam-memory/`](./17-beam-memory/README.md) | medium | partial: step 1 on feat but box 4; step 2 open | the per-row increment (17-b), the text handed to 07 | 17-b · 07 |
| [`18-comptime-runtimes/`](./18-comptime-runtimes/README.md) | low | not started | the CI rows, the wat runtime's limits, the bench table, the transport test, `memory.grow` in the binary emitter | the maintainer · 14 · 05 |
| [`23-std-purity/`](./23-std-purity/README.md) | low | not started | the import cells and LSP snapshots, three confirmations | 23-b/c, std-c |
| [`24-effects-by-return/`](./24-effects-by-return/README.md) | medium | not started | the guide as one program, four confirmations, the per-item cost | rakun's `serverAction` · 24-a/b/c/g |
| [`26-cli-tooling/`](./26-cli-tooling/README.md) | high | partial: steps 1, 2 (boxes 1–2), 3 (box 2), 4 (box 1), 5 on feat; 2 (box 3), 3, 4, 6, 7, 8 open | only a direct dependency importable (242), warnings in `build`/`test`, the LSP's import check | compiler-core's `ModuleOutput` · lg2-v · 23 |
| [`129-import-without-from/`](./129-import-without-from/README.md) | high | done | `from` names a package (206) | — |
| [`130-decorator-outputs/`](./130-decorator-outputs/README.md) | high | partial: steps 1–4 on feat; 5 (34 of 119 sites), 6 open | the library sites, `@emit` removed | 01 step 20 (256's registry) · the library tracks |
| [`134-builtins-declared/`](./134-builtins-declared/README.md) | high | partial: steps 1, 3 on feat; 2 partial | the type functions, the `result` namespace, the `@Result`/`?T` methods, `@is` | 134-a…d |

## Ownership

Each front's README names what it owns; two fronts share no source file and no snapshot directory,
except by a named carve-out with a sequence:

- `codegen/beam/{erl_ast,erl_emitter}.zig` (the Erlang-text renderer) is 02's; the keyed-`Ets`
  functions of `erlang.zig` and `beam_asm.zig` are 17's; `codegen/beam/asm_text.zig` is 14's;
  `beam_file.zig`, `opcodes.zig` and `wat/wasm_binary_emitter.zig` are 18's.
- `codegen/tests/**`, `comptime/tests/**`, `parser/tests/**`, `language-server/src/tests/**` are 07's,
  with the per-backend fixture files to their backends (`erlang.zig` 02, `beam.zig` 03,
  `commonjs.zig` 04, `wat.zig` 05) and 14's `comptime_module.zig` fixtures.
- `parser.zig`'s `isBracedBlockStmt` and the `blockStatementSemicolon` kind are 16's for its step 3,
  after 01's parser rows; 16 step 8 (the annotation's printer arm) lands before 01 step 10.
- `docs.md`'s prose is 07's (23, 24 and 26 supply text for their sections); its marker and fence
  lines, `scripts/check-docs.sh`, `test.yml` and `gate.sh`'s budget lines are `00-gate/114`'s;
  `release.yml` is 18's; root `build.zig` is 26's except 18's `render-resident` / `compiler-web` steps.
- The runners (`scripts/{gate.sh,test-libs.sh,lib/pool.sh}`, `tests/language/run.sh` beyond 12's
  report and `all)` line, `modules/test-shard/**`, `modules/lib-test-runner/**`) have no open owner
  since `25-gate-perf` and 00-gate's 115 and 133 closed: a front that must edit one names it as a
  carve-out in its commit.
- `libs/std/**` is the std track's (`../02-std-and-packaging/`): a std row a compiler front measures
  is handed over with its cell; 17's `beam.bp` primitives and 130/134's `builtins.d.bp` parts are
  named carve-outs.
- 07's steps 1 and 4 re-derive and rename in the backends' snapshot directories: after 02–05 land.

## Decisions

Open ids this track waits on (the full statements in [`../decisions-pending.md`](../decisions-pending.md)
or, for the 1.0.10 confirmations, [1.0.10's](../../1.0.10-beta/decisions-pending.md)):

- **17-b, 17-c** — the per-row increment of a `keyed = true` `Dict`; what else names one
  ([`17-beam-memory`](./17-beam-memory/README.md) § Decisions)
- **134-a … 134-d** — `@print`'s arity, `with:`'s type, `@getContext`'s answer, `@is` by hand (134)
- **C-14** — whether the `->` `case` arm leaves the language (07 step 9)
- **16-a, 16-b** — C-12's argument list with its enclosing constructs; one element per line — to confirm (16)
- **23-b, 23-c, std-c** — to confirm (23) · **24-a, 24-b, 24-c, 24-g** — to confirm (24)
- **01c-a, 01c-b** — the comptime module's atom; a section leaf's shorthand — to confirm (01) ·
  **0405-b** — commonJS prints `undefined` as `null` — to confirm (04)
- **imp-a** — two aliased imports of two same-named types (decision 170 makes them legal; the
  backends do not tell types apart by module) (01)
- **lg2-a … lg2-w** (`lg2-k` answered by 216) — the rakun sweep's language questions: none opens a front until answered; each
  opens a step in its front's README — 01 for lg2-a/e/f/q and the parser rows lg2-m/r/t, 14 for
  lg2-j/o/w, 26 for lg2-v. `lg2-l` may be answered de facto (`@panic` / `@todo` are `noreturn` and a
  branch ending in one narrows); the maintainer confirms and the row closes.

Every recommendation is the most restrictive behaviour with no configuration that bypasses it
(decision 67).

## Rules

- A backend builds a model and an emitter renders it; a snapshot is evidence, not a baseline —
  re-record only a value verified by running.
- The gate runs from a cold runtime cache; no check is skipped to be fast (decision 67), no
  configuration bypasses a refusal, and no list of tolerated reds exists.
- The compiler knows no library: a library's need is a `language-gaps.md` row with a front here, and
  a workaround in the library until the front lands.
- A cell an area front adds lands in that front's commit, one file per cell, proved able to fail on
  the parent binary (`tests/language/AGENTS.md` § Who adds a cell).
