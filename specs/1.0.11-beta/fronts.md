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
   `00-gate`'s compiler fronts (110–115), `01-compiler`, `02-std-and-packaging/97` for
   `libs/std/**` (which no compiler front edits — they hand std halves to 97), and
   `08-bpp/116-bpp-file-format`, which is a toolchain front by construction and names no library
   in what it adds — the syntax of a `.bpp` file is a function it adds to `jhonstart`.
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
| `03-bundled-libs` | `libs/{routing,actions,http,i18n,log,release,validation}/**`; the three registration lines (`build.zig`, `libs/AGENTS.md`, `format-check.sh` — 104 owns them, the others append); the named consumer lines in rakun, jhonstart, onze | anything else in those members |
| `04-rakun` | every member, for the nine merges of decision 187 (128 — first, alone); then `repository/rakun/modules/<member>/**` per front, at the paths 128 leaves, as [`04-rakun/README.md`](./04-rakun/README.md) § The fronts and § Parallel groups; `starters/**` and `examples/**` (73) | the compiler, onze, jhonstart; the gate's files (the ledger is gone — decision 153) |
| `05-jhonstart` | `modules/jhonstart/**` + `jhonstart-dom-test/**` (26 — `fake_dom.mjs` stays 26's; a front that adds a test file to `jhonstart-dom-test` owns that file), `modules/jhonstart-link/**` (27), `modules/jhonstart-forms/**` + `jhonstart-dom-test/test/forms_dom_test.bp` (67) | rakun; `routes.bp:178-195`, `render.bp:453`, `form.bp:117-121` while `03`'s front that names them is open; `libs/log/**` (106's — 26 step 4 calls it) |
| `06-emilia` | `modules/emilia/src/**` (34), `modules/emilia-test/**`, `modules/emilia/test/**`, `examples/**` (33) | jhonstart; `src/scoped.bp` and `jhonstart-emilia/**` (`08-bpp/119`) |
| `07-onze` | `modules/onze/**` + `onze-server/**` (49), `onze-cli/**` + `onze-bundler/**` (50), `onze-assets/**` + `onze-og/**` (51), `onze-release/**` (71), `examples/blog/**` + `onze-test/**` E2E (53) | rakun, jhonstart; the lines `03` names in `types.bp`, `scan.bp`, `chunk.bp`, `server.bp`, `image_handler.bp`, `otp.bp` / `docker.bp` / `spec.bp` while that front is open |
| `08-bpp` | `jhonstart/modules/jhonstart-html/**` (118 — the member then merges into the core, `05-jhonstart/26` step 0, decision 200; 119, 120, 126 each append one lowering arm to `jhonstart/src/html.bp`) · new member `onze/modules/onze-content/**` (121) · new `emilia/modules/emilia/src/scoped.bp` + `jhonstart-emilia/**` (119) · new files in `jhonstart` core, `jhonstart-link`, `jhonstart-forms`, `rakun`, `rakun-app`, `libs/actions`, `onze`, `onze-cli`, `onze-bundler` and the named lines beside them (117 · 120 · 122 · 123 · 124 · 126 · 127 — each front's README § Owns) · in `repository/botopink-lang`, **116 only**: `modules/manifest` (the `bpp` key), the extension lists and the unfold of a `.bpp` file in `compiler-cli` / `language-server` / `lib-test-runner`, and `vscode-extension` (decision 198) | `modules/compiler-core/**` and every `codegen/*.zig` — no front of the track edits them; a file a front of track 03 / 04 / 05 / 07 owns, until that front has landed ([`08-bpp/README.md`](./08-bpp/README.md) § Who else owns the files) |

## Conflict rules

- **`00-gate` before everything.** The library tracks' rakun and onze fronts edit files `99` and
  `100` migrate; they branch from the landed gate fronts. `01-compiler`'s fronts edit files `110`,
  `111`, `112` hold (`wat.zig`, `run.sh`, `expected-failures.txt`, `parser/patterns.zig` among the
  11 `zig fmt` files); they wait. `114` shares nothing and runs any time.
- **`97-std-dedupe` before `03-bundled-libs`** and before any "consume std" step of a library
  front (each track README names those steps).
- **`03` versus the library tracks** (decision 188): a `03` front has a package half
  (`libs/<pkg>/**`, disjoint from every library front) and a consumer half (one commit per member
  on the lines it names), and a consumer commit never shares a wave with the front that owns the
  member (the table in [`03-bundled-libs/README.md`](./03-bundled-libs/README.md) § Who else owns
  the consumer files). **102 step 3 and 103 step 2 take their consumer commits before the library
  fronts open**; 104's consumer sweep, 105 and 107 take the slot **after** the library fronts
  that own their consumer files have landed. `106-log` is written against by its consumers in
  their own steps (26 step 4, 17, 49 step 3 — decisions 194, 195) and precedes them. `104-http`
  before `105-i18n` (both edit `rakun-app/src/i18n.bp`); `71-onze-release-packaging` and
  `81-rakun-packaging-release` before `107-release`; `103-actions-id` before `67-jhonstart-forms`.
- **The three registration files** (`build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`) take
  one appending front at a time (decision 189): 104 owns the lines; 106 appends when its package
  is ready; 105, then 107, in number order. 105's edit of `libs/validation/src/messages.bp` lands
  between two steps of 125, never during one.
- **Inside `04-rakun`**: `128-rakun-consolidation` first and alone in the repository (decision
  187), after the rakun consumer commits of 102 step 3 and 103 step 2; then group A, then B, then
  C, as its README computes from `Depends on`; `04`'s step 1 (the tag epoch, decision 185) gates
  13 and 12, its step 5 gates 22. 73 is in group A (decision 189).
- **`08-bpp` versus the library tracks**: every `08` front but 121 (a new member) edits files a
  front of track 04, 05, 06 or 07 owns, and sequences **after** it: 26 before 120 and 122; 27
  before 126; 67 and 103 before 127; 50 and 102 before 117 and 124; 49 before 117's
  `paginate.bp`, 122's `site` key and the two lines of `onze-server`; rakun's `04` and `65`
  before 123 (decision 189) and its 22-front before 117, 120 and 127. **118 is the exception that
  goes first**: its step 1 rewrites the bracket attributes outside `html.bp` as named
  one-line carve-outs, each landed before the owning front opens — 34, 33, 26, 119 (decision
  189). Inside the track, 118 before every front that adds a directive, and each file several
  fronts append to takes one at a time: `html.bp` (in the core after 26 step 0) 119, then 120, then 126;
  `rakun-app`'s `botopink.json` / `root.bp` 117, then 120, then 127; the jhonstart core's 120,
  then 122; `onze/src/config.bp` 122 (the `site` key), then 124 (the other four).
  `125` steps 0–2 before 121 step 4 and before 127, which also needs 125 step 6.
- **`jhonstart-dom-test`** (decision 189): a front owns the test file it adds (67, 119, 120, 126,
  127); `fake_dom.mjs` stays 26's and is edited by one front at a time after 26 — 120, then 126.
- **116 versus `01-compiler`**: it edits `compiler-cli/**` and `language-server/**` (26's),
  `lib-test-runner/**` (113's, then 115's) and `docs.md` (08's); it does not edit compiler-core
  (decision 198); 116 opens after `01-compiler/26`, `05-jhonstart/26` step 0 and 118, and never
  beside one of the others.
- **`expected-failures.txt`** has one owner (111) and is deleted; **`run.sh`** is 111's, then 115's.
- **The meta repo's own files** (`.github/`, `scripts/`, `AGENTS.md`) belong to 114 and 115;
  `specs/**` to the front whose README it is.

## Parallel groups, milestone-wide

| Wave | May run together | Why |
|---|---|---|
| 0 | 99 · 100 · 101 · 108 · 109 · 110 · 112 (+ 114) | disjoint repositories / compiler files |
| 0′ | 111, then 113, then 115 | shared `run.sh`, ledger counts depend on 99–109 |
| 1 | 97 · 01-compiler A (01 · 02 · 03 · 04 · 05 · 14 · 26) · 01-compiler B (12 · 18 · 23 · 24 · 25) | per-track ownership tables; up to the maintainer's thread cap |
| 2 | 01-compiler 17 → 16 → 07 → 08 → 09 | sequenced: each after the owners it reads |
| 1 – 10 of tracks 03–08 | every front of `03-bundled-libs`, `04-rakun`, `05-jhonstart`, `06-emilia`, `07-onze`, `08-bpp`, by step where a front is cut | § Execution order of tracks 03–08 — the waves the coordinator opens threads from; they start when wave 0′ is green and 97 steps 1–5 have landed |
| last | 98 | it verifies across seven repositories, after every library track |

The maintainer's thread cap is six worktrees at a time (three when the console is closed); the
groups above say what *may* run together, the cap says how many do, across every track.

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

## Execution order of tracks 03–08

The step-level order of `03-bundled-libs`, `04-rakun`, `05-jhonstart`, `06-emilia`, `07-onze` and
`08-bpp`: 48 fronts, cut by step where a front has halves that open at different times. It is
written from the state measured on 2026-10-02 and against decisions 144–202; where a track README
is coarser, this section is the one threads are opened from.

**Before any of it lands.** `00-gate` is green and pushed in every repository (113 landed; the
library tips of 99, 100, 101, 109 on their remotes) and `97-std-dedupe` steps 1–5 have landed.
Until then nothing of these tracks lands; the only work that may continue is a package half in
`repository/botopink-lang/libs/<pkg>/**` — it collides with no gate front and with 97 only in
`libs/std`. Three package halves exist on branches and land first, in this order, when the gate
is green: `front/102-routing-conventions` (steps 1–2), `front/103-actions-id` (step 1),
`front/125-validation-zod` (steps 0–2).

### The rules the waves follow

| Rule | Decision |
|---|---|
| A `03` front has a package half and a consumer half; a consumer commit never shares a wave with the front that owns the member. 102 step 3 and 103 step 2 go before the library fronts open; 104's sweep, 105 and 107 go after the fronts that own their consumer files | 188 |
| 106's consumers are the owning fronts' own steps (26 step 4, 17, 49 step 3); its package precedes them | 194, 195 |
| 128 is the first front of rakun and runs alone in the repository, after the rakun consumer commits of 102 step 3 and 103 step 2 | 187, 188 |
| 118 step 1's bracket-attribute rewrites outside `jhonstart-html` are one-line carve-outs landed before 34, 33, 26 and 119 open; 118 lands in `jhonstart-html`, and 26 step 0 then merges the member into the core | 189, 200 |
| One appending front at a time: `html.bp` 119 → 120 → 126; `rakun-app`'s manifest and root 117 → 120 → 127; the jhonstart core's 120 → 122; `fake_dom.mjs` 120 → 126; `onze/src/config.bp` 122 → 124; the three registration files 104, 106, 105, 107 | 189 |
| 123 after 65 in `rakun-web`; 27 does not wait on 50; 73 is in rakun's group A | 189 |
| The dynamic mark: 22 step 4 and 49 step 5 land the run-time bridge; 26 step 8 replaces it when `01-compiler/01-checker` lands the capability of the `language-gaps.md` row | 186 |

### Dependency graph

A front needs what its row names — fronts landed, decisions by number when answered, by id when
open — and unblocks the fronts in the last column. "gate" is `00-gate` green for the repository
the front edits.

| Front | Needs | Unblocks |
|---|---|---|
| **102** steps 1–2 (package) | on its branch; 97; decisions 163, 171–173 | 102 step 3 · 117 · 122 |
| **102** step 3 (consumers) | gate · 97 · steps 1–2 landed · 49-d confirmed as amended | 128 · 22 · 26 · 49 · 50 · 117 · 124 |
| **103** step 1 (package) | on its branch; decision 163 | 103 step 2 · 127 |
| **103** step 2 (consumers) | gate · step 1 landed | 128 · 22 · 67 · 127 |
| **104** steps 1–4 (package half) | gate · 97 · decisions 196, 181, 182, 163 | 104 step 5 · 105 |
| **104** step 5 (consumer sweep) | steps 1–4 · 04 · 65 · 123 · 79 · 12 · 19 · 22 · 49 · 51 landed | 105 |
| **105** | 104, both halves · 22 · 26 · decision 180 · 03r-q confirmed | — |
| **106** | gate · 97 · decisions 194, 195 | 26 step 4 · 17 · 49 step 3 |
| **107** | `07-g` (a) · 71 · 81 | — |
| **125** steps 0–2 | on its branch; 97; decisions 144, 145; `07-n` | 121 step 4 · 127 · 125 steps 3–10 |
| **125** steps 3–10 | steps 0–2 · decision 183 (step 6) · `07-j` | 127 (step 6) |
| **128** | gate (99) · the rakun commits of 102 step 3 and 103 step 2 · decision 187 | every rakun front |
| **04** | 128 · decision 185 (step 1) | 13 · 12 (step 1) · 22 (step 5) · 19 steps 2–5 · 88 (step 4) · 123 · 104 step 5 |
| **74** | 128 | 92 |
| **08** | 128 · decision 147 | — |
| **15** | 128 · `03r-al` (step 5) | 19 steps 2–5 · 91 · 92 |
| **79** | 128 · `03r-ae` (step 3) | 104 step 5 |
| **81** | 128 · `03r-ak` (step 3) | 88 · 107 |
| **93** | 128 · 13 not holding `rakun-client`'s manifest | 88 |
| **19** step 1 | 128 · decision 160 | 12 · 09 |
| **73** | 128 · `03r-af` (step 3) | 88 |
| **13** | 04 step 1 | 65 · 17 · 09 |
| **17** | 128 · 106 · 13 step 2 | — |
| **22** | 04 step 5 · the `rakun-app` commits of 102 and 103 · decision 186 (step 4) | 49 step 5 · 53 · 11 · 117 · 120 · 127 · 104 step 5 · 105 |
| **12** | 19 step 1 · 04 step 1 | 53 · 104 step 5 |
| **11** | 128 · 22 (one box) | — |
| **65** | 128 · 13 step 3 (step 2) · decision 201 (step 1) | 49 step 4 · 53 · 123 · 104 step 5 · 106's `problem_digest` commit |
| **09** | 19 step 1 · 13 · `03r-ab` | — |
| **91** | 15 · `03r-ad` | — |
| **92** | 74 · 15 | 88 |
| **88** | 81 · 93 · 92 · 04 step 4 · 73 | — |
| **19** steps 2–5 | 15 step 1 · 04 step 4 · `03r-am` (steps 3–4) · `03r-ag` (step 6) | 104 step 5 |
| **26** | gate (101) · 102's `routes.bp` commit · 118 landed (step 0 merges `jhonstart-html` into the core, decision 200) · 106 (step 4) · `30-h` (step 7) · the checker capability (step 8) | 67 · 49 step 3 · 53 · 119 · 120 · 122 · 116 · 105 |
| **27** | gate (101) · 22 (one box) | 50 step 6 · 126 |
| **67** | 26 · 103 step 2 · `67-a` | 53 · 127 |
| **34** | gate (109) · 118 step 1's carve-out · 05emilia-l confirmed (step 2) · `05emilia-n` (step 4) | 33 steps 3–4 |
| **33** steps 1–2 | gate (109) · 118 step 1's carve-out | — |
| **33** steps 3–4 | 34 · `05emilia-m` (b) or (c) | — |
| **49** | gate (100) · 102's `types.bp` commit · 97 (step 1) · 26 step 4 (step 3) · 65 step 1 (step 4, decision 201) · 22 step 4 (step 5) | 50 · 51 · 71 (its step 6) · 53 · 117 · 120 · 122 · 127 · 104 step 5 |
| **50** | gate (100) · 102's `scan.bp` and `chunk.bp` commits · 97 (step 1) · 49 step 6 · `50-b` (step 2) · `std-d` (steps 4, 7) · 71 step 2 (step 5) · 27 step 1 (step 6) | 53 · 117 · 120 · 124 |
| **51** | gate (100) · 97 (step 1) · 49 step 6 | 53 · 104 step 5 |
| **71** steps 1–4 | gate (100) · 49 step 6 | 50 step 5 · 53 · 107 · 124 |
| **71** step 5 | 50 · 53 | — |
| **53** | 49 · 50 · 51 · 71 steps 1–4 · 26 · 67 · 22 · 12 · 65 | 71 step 5 · 121 step 7 · 124 step 5 · the browser boxes of 120 and 126 |
| **118** | gate (101) · decisions 190–193 | the carve-outs 34, 33, 119 wait on · 26 (step 0 moves its member) · 119 · 120 · 126 · 121 step 6 · 116 |
| **121** steps 1–3 | gate (100) · `08-f` (step 3) | 117 · 121 steps 4–7 |
| **121** steps 4–5 · step 6 · step 7 | 125 steps 0–2 · 118 and 117 · 53 | 124 |
| **119** | `08-d` · 118 · 26 | 120 |
| **123** | 04 · 65 · decision 186 | 127 step 4 · 104 step 5 |
| **117** | 102 · 22 · 49 · 50 · 121 steps 1–2 · `08-b` (step 1) · decision 202 (step 2) | 120 · 127 · 121 step 6 · 124 |
| **120** | 118 · 119 · 26 · 22 · 49 · 50 · 117 · `08-e` (step 4) | 122 · 126 · 127 · 124 |
| **122** | 26 · 49 · 102 · 120 | 124 |
| **126** | 27 · 118 · 120 | 127 · 124 |
| **127** | 125 steps 0–2 and 6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · 123 (step 4) | 124 |
| **116** | 118 · 26 step 0 · `01-compiler/26` landed · decisions 198–200 | 124 step 5 |
| **124** | 50 · 71 · every other `08` front · `08-h` · `08-e` (step 3) · 116 and 53 (step 5) | — |

### Waves

Six threads, shared with `00-gate`, `01-compiler` and `02-std-and-packaging`: a thread another
track holds comes off the tail of a wave, so each wave lists its fronts most blocking first. The
fronts of one wave share no source file and no test directory but for the carve-outs their track
READMEs name. A front whose prerequisites have landed may open in a thread freed before its wave.

| Wave | Fronts | Why they do not collide | Opens when |
|---|---|---|---|
| 1 | 102 step 3 + 103 step 2 (one thread; the rakun commits first) · 128 · 118 · 106 · 104 steps 1–4 · 71 steps 1–4 | the consumer commits hold `rakun-app`, `rakun-hateoas`, the jhonstart core, `jhonstart-forms`, `onze`, `onze-cli`, `onze-bundler`; 128 opens when their rakun commits have landed and then holds all of rakun; 118 is alone in `jhonstart-html`; 106 and 104 are `libs/log` and `libs/http`, landing one at a time on the registration files; 71 is `onze-release` | the gate is green, 97 steps 1–5 and the three package branches have landed |
| 2 | 04 (step 1 first) · 49 (step 6 first) · 26 · 50 · 19 step 1 · 27 | rakun core · `onze` and `onze-server` · the jhonstart core and `jhonstart-dom-test` · `onze-cli` and `onze-bundler` · `rakun-test` · `jhonstart-link` | 128 has landed (04, 19); the consumer commits of 102 and 103 in jhonstart and onze have landed (26, 49, 50); 118 has landed, since 26 step 0 merges its member into the core (26) |
| 3 | 22 · 13 · 67 · 51 · 34 · 121 steps 1–3 | `rakun-app` · `rakun-client` · `jhonstart-forms` · `onze-assets` and `onze-og` · `emilia/src` · the new `onze-content` | 04 steps 1 and 5 (22, 13); 26 (67); 49 step 6 (51); 118 step 1's carve-out in emilia (34) |
| 4 | 65 · 12 · 15 · 17 · 119 · 74 | `rakun-web` · `rakun-cache` and `rakun-session` · `rakun-messaging`, `rakun-scheduling`, `rakun-data/src/tx` · the core's `logging/**` and `rakun-metrics` · `scoped.bp` and `jhonstart-emilia` · the core's four TLS files and `rakun-web/src/tls.bp` | 13 (65, 17); 19 step 1 and 04 step 1 (12); 106 (17); `08-d`, 118 and 26 (119) |
| 5 | 53 · 117 · 123 · 81 · 79 · 125 steps 3–10 | `examples/blog` · `libs/routing`, `rakun-app/src/static_gen.bp`, `onze/src/paginate.bp`, `onze-cli/src/scan.bp` · `rakun/src/locals.bp` and two files of `rakun-web` · `rakun-cli/src/release` · `rakun-security` · `libs/validation` | 49 complete, 50, 51, 67, 12, 65 (53); 22, 49, 50, `08-b` (117); 04 and 65 (123) |
| 6 | 120 · 121 steps 4–5 · 08 · 11 · 92 · 19 steps 2–5 | the jhonstart core, `rakun-app/src/server_islands.bp`, one arm of `html.bp` · `onze-content` · `rakun-data` · `rakun-actuator` and the core's `actuator_api/**` · `rakun-messaging/src/rsocket` · `rakun-test` | 117 and 119 (120); 125 steps 0–2 (121); 22 (11); 74 and 15 (92); 15 step 1 and 04 step 4 (19). 106's `problem_digest` commit in `rakun-web` fits here, after 65 and 123 |
| 7 | 122 · 126 · 121 step 6 · 104 step 5 · 93 · 73 | the jhonstart core, `libs/routing/src/navigation.bp`, `onze/src/config.bp` · `jhonstart-link` and one arm of `html.bp` · `onze-content` · the nine consumer members of 104 · `rakun-client/src/ws` · `starters` and `examples` of rakun | 120 (122, 126); 117 (121); every owner of 104's consumer files — 04, 65, 123, 79, 12, 19, 22, 49, 51 |
| 8 | 127 · 88 · 91 · 09 · 33 steps 1–2 · 71 step 5 | `rakun-app/src/typed_action.bp`, `libs/actions`, `jhonstart-forms` · `rakun-cli` · `rakun-messaging/src/pulsar` · `rakun-data/src/nosql` · `emilia-test`, emilia's examples · `onze-release`'s tests over the blog | 125 step 6, 126 and 104 step 5 (127); 81, 93, 92, 73 (88); `03r-ad` (91); `03r-ab` (09); 53 (71) |
| 9 | 124 steps 1–4 · 105 · 121 step 7 · 107 · 33 steps 3–4 · 26 step 7 | `onze-cli`, `onze-bundler`, `onze/src/config.bp`, the scaffold · `libs/i18n` and its three consumer lines · the blog's content · `libs/release` and the two release members · emilia's `test/` · every jhonstart member's snapshots, alone and last in its repository | every other `08` front but 116 (124); 104 (105); 53 (121); `07-g`, 71, 81 (107); `05emilia-m` (33); `30-h` (26) |
| 10 | 124 step 5 | the `.bpp` scaffold and the second example app | 116 and 53 |

Outside the numbered waves:

- **116** opens in the first wave after 118, 26 step 0 and `01-compiler/26` have landed — wave 3
  at the earliest — alone in the compiler files it names (decisions 198–200 leave it no open
  question; its README § Notes lists six points they do not state).
- **26 step 8** opens when `01-compiler/01-checker` lands the capability of decision 186; 49 step
  5 and 22 step 4 then delete the run-time bridge, each in its own member.
- **98** (`02-std-and-packaging`) runs after wave 9: it verifies what the library tracks wrote.

### What may start, and on what

**The moment the gate is green** (with 97 steps 1–5 landed) — no open question on the steps
named: the three package branches land; 103 step 2; 102 step 3; 128; 118; 106; 104 steps 1–4; 71
steps 1, 2 and 4; 27 (but one box); 121 steps 1–2; 125 steps 3–10. After 128: 04; 19 step 1; 74;
08; 15 steps 1–4 and 6; 79 steps 1–2; 81 steps 1–2; 93; 73 steps 1–2.

**Only after a decision** — the step named waits, the rest of the front does not:

| Decision | What waits on it |
|---|---|
| `08-b` | 117 step 1 — and with it the whole front |
| `08-d` | 119 |
| `08-e` | 120 step 4 · 124 step 3 |
| `08-f` | 121 step 3 |
| `08-h` | 124 |
| `50-b` | 50 step 2 |
| `std-d` | 50 steps 4 and 7 |
| `67-a` | 67 steps 1–3 |
| `07-g` | 107 |
| `07-n` · `07-j` | 125 step 2 (on its branch against the recommendation) · the size of 125 |
| `03r-ab` · `03r-ad` · `03r-ae` · `03r-af` · `03r-ak` · `03r-al` · `03r-am` | 09 · 91 · 79 step 3 · 73 step 3 · 81 step 3 · 15 step 5 · 19 steps 3–4 |
| `03r-ag` · `30-h` · `05emilia-m` · `53-b` (one question: realise or retire the snapshot maps) | 19 step 6 · 26 step 7 · 33 steps 3–4 · 71 step 6, 50 step 8, 51 step 7 |
| `05emilia-n` · 05emilia-l confirmed · 52-a confirmed | 34 step 4 · 34 step 2 · 51 step 4 |

**Only after a front** — the "Needs" column of the graph; the chains that set the pace are
128 → 04 → 22 → 49 → 53, 106 → 26 step 4 → 49 step 3, and 118 → 119 → 120 → 126 → 127 → 124.

### Open decisions, by what they unblock

1. `08-b` — 117, and behind it 120 and 127 (`rakun-app`, one at a time after 117), 121 step 6 and 124.
2. `67-a` and `50-b` — 67 steps 1–3 and 50 step 2: the write path and the `dev` command of 53.
3. `08-d` — 119, the first of the three fronts that append to `html.bp`.
4. `08-e` — 120 step 4, 124 step 3. `08-f` — 121 step 3. `08-h` — 124.
5. The snapshot question (`03r-ag`, `30-h`, `05emilia-m`, `53-b`, and `01std-f` in track 02) — five conditional steps, one answer.
6. One front or one step each: `03r-ab` (09), `03r-ad` (91), `03r-ae` (79 step 3), `03r-af` (73 step 3), `03r-ak` (81 step 3), `03r-al` (15 step 5), `03r-am` (19 steps 3–4), `std-d` (50 steps 4, 7), `05emilia-n` (34 step 4), `07-g` (107), `07-n` (125 step 2), `07-j` (the size of 125).
7. Nothing waits on `07-b` or `07-h`.

Points raised by applying decisions 187 and 192–200 that have no id yet, each holding one step:
the member count of decision 187 against its own list (128, before step 1); the
`rakun-websocket` edge R92-1 would add to `rakun-messaging` (92 step 2); how a named slot and a
native tag's attributes follow decisions 192 and 193 (118 steps 1 and 4); and, for 116, the
opening fence, the unfolded function's name and return type, how an app-file kind gets its
route and decorator, and `Node` against `JhonstartNode` (116 § Notes; steps 2 and 6).
