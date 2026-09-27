# Fronts — 1.0.11-beta: who may touch what, when

The front-number → directory map is in [`carried.md`](./carried.md); each track's `README.md`
carries its own ownership table and conflict notes at file granularity. This file is the
milestone-level view: the rules, the groups that may run together, and the exit gate.

A front is one worktree (`.tasks/<front-name>` of the meta repo, branch `front/<front-name>`, the
submodule it edits on a branch of the same name), one `todo.md` (never committed), one owner. Two
fronts may run at the same time only when they share **no source file and no snapshot directory**.

## Rules for a front

1. **A library front never touches `repository/botopink-lang/modules/**`.** It files a row in
   [`language-gaps.md`](./language-gaps.md) and works around the gap. The carve-outs are named:
   `00-gate`'s compiler fronts (110–115), `01-compiler`, and `02-std-and-packaging/97` for
   `libs/std/**` (which no compiler front edits — they hand std halves to 97).
2. **A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front** that
   owns anything in the member; a later front appends, in number order, and never rewrites.
3. **Sidecars are `src/sidecars/<lib>_<name>.erl`** and belong to the front that owns the `.bp`
   that declares their cells.
4. **The per-library `modules.md` is the source of truth** for members and their dependency graph;
   it was re-derived from the tree at the cut and a front that changes an edge updates it in the
   same commit.
5. **A front that needs a file it does not own stops and reports** — to the front that owns it,
   through the track README's "Handed to …" table.
6. **`AGENTS.md` of every directory touched, updated in the same commit.**
7. **Decisions are asked, not guessed**: a question goes to `decisions-pending.md` in the
   Measured / Options / Recommendation / Blocks shape, recommendation most restrictive.
8. **Landing is the gate's decision**: `scripts/gate.sh --cold` green in the front's worktree, then
   the maintainer merges; no `--no-verify`.

## Ownership, by track

| Track | Owns | Never touches |
|---|---|---|
| `00-gate` 99 · 100 · 101 · 108 · 109 | `repository/{rakun,onze,jhonstart,erika,emilia}/**` — the migration off `(if …)` operands and `any`, manifests' `targets`, `.gitignore` + `scripts/git-hooks/`, `.github/workflows/`, `repro/**` | the compiler |
| `00-gate` 110 · 111 · 112 | `codegen/wat.zig` + wasm snapshots + `libs/std/src/testing/asserts.bp` (110) · `compiler-cli/src/cli/{build,run,test_cmd,libs}.zig`, `codegen/beam_asm.zig`, `tests/language/run.sh`, `expected-failures.txt` (deleted), `run/*.targets`, modules manifests (111) · `scripts/format-check.sh`, `cli/format_cmd.zig`, the 11 `zig fmt` files, reformat-only commits over `libs/std`, `examples/`, `tests/language`, `compiler-cli/tests`, `gate.sh` stage 1 (112) | each other's files; 111 runs after 110 and 112 |
| `00-gate` 113 · 114 · 115 | both ledger files (deleted), `scripts/test-libs.sh`, `modules/lib-test-runner/**`, `scripts/AGENTS.md`, `test_cmd.zig`'s `BOTOPINK_BIN`, meta `scripts/language-gap-markers.sh` (113) · `scripts/check-docs.sh`, the 9 `docs.md` marker lines, the compiler `test.yml` windows row, meta `.github/workflows/` (114) · `gate.sh`, `test-libs.sh`, `run.sh` (after 111), `libs.zig`'s cache path, `lib-test-runner/**` (after 113), meta `scripts/worktree-add.sh` (115) | 113 runs after every repository front and 111/112; 115 last |
| `01-compiler` | per sub-front, as [`01-compiler/README.md`](./01-compiler/README.md) § Ownership: the checker `comptime/{infer,unify,env,types,transform}.zig` + `snapshots/comptime/**` (01); each backend its emitter + its snapshot directories (02 · 03 · 04 · 05); `codegen/tests/**` fixtures per backend file; `comptime/runtime/**` (14, 18); `format.zig` (16); `compiler-cli/**`, `bpmp/**`, `language-server/**` (26); `docs.md` (08); `tests/language/**` bookkeeping (12) | `libs/std/**` (97's); any file `00-gate` still holds until it lands |
| `02-std-and-packaging` 97 · 98 | `libs/std/**` + the std halves the compiler hands over (97); each library's `examples/*/README.md`, `-test` helpers where the library track did not claim them, `scripts/check-packaging.sh` (98) | the compiler; a library's `src/` |
| `03-rakun` | `repository/rakun/modules/<member>/**` per front, as [`03-rakun/README.md`](./03-rakun/README.md) § The fronts; `starters/**` and `examples/**` (73) | `restricted-targets.txt` (gone), the compiler, onze, jhonstart |
| `04-jhonstart` | `modules/jhonstart/**` (26), `modules/jhonstart-link/**` (27), `modules/jhonstart-forms/**` + `jhonstart-dom-test/**` (67) | rakun; `routes.bp:178-195`, `render.bp:453`, `error_boundary.bp:77`, `form.bp:117-121` while `07`'s front that names them is open |
| `05-emilia` | `modules/emilia/src/**` (34), `modules/emilia-test/**`, `modules/emilia/test/**`, `examples/**` (33) | jhonstart; `emilia.bp:95-97` until `97-std-dedupe` lands `contentHash`'s consumer step |
| `06-onze` | `modules/onze/**` + `onze-server/**` (49), `onze-cli/**` + `onze-bundler/**` (50), `onze-assets/**` + `onze-og/**` (51), `onze-release/**` (71), `examples/blog/**` + `onze-test/**` E2E (53) | rakun, jhonstart; the lines `07` names in `types.bp`, `scan.bp`, `chunk.bp`, `server.bp`, `image_handler.bp`, `otp.bp` / `docker.bp` / `spec.bp` while that front is open |
| `07-bundled-libs` | `libs/{routing,actions,http,i18n,log,release}/**`; the three registration lines (`build.zig`, `libs/AGENTS.md`, `format-check.sh` — 104 owns them, the others append); the named consumer lines in rakun, jhonstart, onze, validation | anything else in those members |

## Conflict rules

- **`00-gate` before everything.** The library tracks' rakun and onze fronts edit files `99` and
  `100` migrate; they branch from the landed gate fronts. `01-compiler`'s fronts edit files `110`,
  `111`, `112` hold (`wat.zig`, `run.sh`, `expected-failures.txt`, `parser/patterns.zig` among the
  11 `zig fmt` files); they wait. `114` shares nothing and runs any time.
- **`97-std-dedupe` before `07-bundled-libs`** and before any "consume std" step of a library
  front (each track README names those steps).
- **`07` versus the library tracks**: every `07` front names the consumer lines it edits; the
  library front that owns the member sequences after it (the table in
  [`07-bundled-libs/README.md`](./07-bundled-libs/README.md) § Who else owns the consumer files).
  `104-http` before `105-i18n` (both edit `rakun-app/src/i18n.bp`); `71-onze-release-packaging`
  before `107-release`; `103-actions-id` before `67-jhonstart-forms`.
- **Inside `03-rakun`**: group A, then B, then C, as its README computes from `Depends on`; `04`'s
  step 1 (the two core seams) gates group B.
- **`expected-failures.txt`** has one owner (111) and is deleted; **`run.sh`** is 111's, then 115's.
- **The meta repo's own files** (`.github/`, `scripts/`, `AGENTS.md`) belong to 114 and 115;
  `specs/**` to the front whose README it is.

## Parallel groups, milestone-wide

| Wave | May run together | Why |
|---|---|---|
| 0 | 99 · 100 · 101 · 108 · 109 · 110 · 112 (+ 114) | disjoint repositories / compiler files |
| 0′ | 111, then 113, then 115 | shared `run.sh`, ledger counts depend on 99–109 |
| 1 | 97 · 01-compiler A (01 · 02 · 03 · 04 · 05 · 14 · 26) · 01-compiler B (12 · 18 · 23 · 24 · 25) · 03-rakun A (04 · 74 · 08 · 15 · 79 · 81 · 93 · 19 step 1) · 26 · 27 · 34 · 33 (1–2) · 49 · 50 · 51 · 71 | per-track ownership tables; up to the maintainer's thread cap |
| 2 | 102 · 103 · 104 · 03-rakun B (13 · 17 · 22 · 12 · 11 · 65 · 09 · 91 · 92 · 73) · 67 · 33 (3–4) · 01-compiler 17 → 16 → 07 → 08 → 09 | after 97; after rakun A; after 26 and 103 |
| 3 | 105 · 106 · 107 · 03-rakun C (88 · 19 steps 3–5) · 53 · 98 | after 104; after rakun B; 53 last of onze; 98 verifies across seven repositories |

The maintainer's thread cap is five worktrees at a time (three when the console is closed); the
groups above say what *may* run together, the cap says how many do.

## Exit gate of the milestone

Every line below is a command and the output it must print; nothing is read from a spec.

1. `scripts/gate.sh --cold` in `repository/botopink-lang`: **every stage green**, the report
   printing every stage's time, the cell count equal to the `--list` count; no
   `expected-failures.txt`, no `restricted-targets.txt`, no `known-red-libs.txt` on disk.
2. `tests/language/run.sh --target all` includes beam: `N passed / 0 expected / 0 failed`.
3. `zig build test-libs`: every visible library, every member, every manifest target: `N passed / 0
   failed / 0 skipped`; a cell reporting `skipped` is red.
4. Each repository's own CI (`emilia`, `erika`, `jhonstart`, `onze`, `rakun`, `vscode-extension`,
   the meta `hook-integrity`): green on every row, no `allow_fail`, no vacuous row, every member ×
   every manifest target.
5. `scripts/format-check.sh` over every tree and `zig fmt --check modules`: clean.
6. `scripts/language-gap-markers.sh` over the seven repositories (excluding `specs/1.0.10-beta/**`):
   every `// LANGUAGE GAP:` marker names a row of `language-gaps.md`.
7. `gate.sh --cold` under the wall-clock budget `115-gate-perf` fixes from its baseline.
8. `status.md` lists no front under Open; every carried decision id is answered in
   `decisions-taken.md` or still listed in `decisions-pending.md` with the front it blocks.
