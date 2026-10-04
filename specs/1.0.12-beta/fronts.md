# Fronts — 1.0.12-beta: who may touch what, when

Each track's `README.md` carries its ownership and conflict notes at file granularity; this file is
the milestone-level view: the rules for a front, who owns what, the sequences between tracks, the
execution order, and § Gate, the standard landing every front README cites. Where each front
stands is [`status.md`](./status.md).

A front is one worktree (`scripts/worktree-add.sh <NN-name>` → `.tasks/<NN-name>`), one branch
`front/<NN-name>` in the meta repo and in every submodule it edits, one `todo.md` (never
committed), one owner. Two fronts run at the same time only when they share **no source file and
no snapshot or test directory**, except by a carve-out a README names together with its sequence.

## Rules for a front

1. **A library front never touches `repository/botopink-lang/modules/**`.** It files a row in
   [`language-gaps.md`](./language-gaps.md) and works around the gap. The named exceptions:
   `01-compiler`; `00-gate/114` for its files; `02-std-and-packaging/97` for `libs/std/**` (a
   compiler front hands its std half to 97, except the named carve-outs: 17's `beam.bp` primitives,
   130's and 134's parts of `builtins.d.bp`); `08-bpp/116`, a toolchain front that names no
   library.
2. **A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front** that
   owns anything in the member; a later front appends, in number order, and never rewrites.
3. **Sidecars are `src/sidecars/<lib>_<name>.erl`** and belong to the front that owns the `.bp`
   declaring their cells.
4. **The per-library `modules.md` is the source of truth** for members and their graph; a front
   that changes an edge updates it in the same commit.
5. **A front that needs a file it does not own stops and reports** to the owning front, through the
   track README's hand-off table.
6. **Decisions are asked, not guessed**: a question goes to
   [`decisions-pending.md`](./decisions-pending.md) as Measured / Options / Recommendation / Blocks,
   the recommendation most restrictive (decision 67).
7. **The front's README stays current**: a landed step becomes one line under `## Done` in the
   landing commit; `status.md` is the only file that says where the milestone stands.
8. **Landing is § Gate.**

## Ownership, by track

Paths in `repository/rakun` are the tree `04-rakun/128` leaves (decision 187;
[`04-rakun/README.md`](./04-rakun/README.md) § Where a merged member's front works).

| Track | Owns | Never touches |
|---|---|---|
| `00-gate` (114) | `scripts/check-docs.sh`; the marker and fence lines of `docs.md` (not its prose); botopink-lang `.github/workflows/test.yml`; `gate.sh`'s budget lines; the vscode-extension workflow's Erlang install; rakun `test.yml`'s glibc comment; the meta `.github/workflows/**` and meta `AGENTS.md` § CI | the stages' content, the checker, the emitters |
| `01-compiler` | per front, [`01-compiler/README.md`](./01-compiler/README.md) § Ownership: the checker and parser (01); each backend's emitter and snapshot directories (02 · 03 · 04 · 05); `codegen/tests/**`, `comptime/tests/**`, `parser/tests/**`, `language-server/src/tests/**`, the prose of `docs.md`, erika's C-13 migration (07); `tests/language/**` bookkeeping (12); `asm_text.zig` (14); `format.zig` and the `;` parser kind (16); the keyed-`Ets` functions (17); `beam_file.zig`, `opcodes.zig`, the wasm binary emitter, `release.yml` and two `build.zig` steps (18); `compiler-cli/**`, `bpmp/**`, `language-server/**`, root `build.zig` (26); the decorator sites (130); `builtins.d.bp` and `comptime/builtins.zig` (134) | `libs/std/**` but the carve-outs; every library repository |
| `02-std-and-packaging` | `libs/std/**` and the std halves handed over (97); the examples' `README.md` and `-test` helpers no library front claimed, `scripts/check-packaging.sh`, `docs/botopink-json.md`, `modules/manifest/**` for the `subdir` field (98) | the compiler; a library's `src/` |
| `03-bundled-libs` | `libs/{routing,actions,http,i18n,log,release,validation}/**`; the three registration lines (`build.zig`'s `bundled_packages`, `libs/AGENTS.md`, `format-check.sh` `TREES` — 104 owns them, 105 then 107 append); the consumer lines each front names in rakun, jhonstart and onze, one commit per member | anything else in those members |
| `04-rakun` | while 128 is open: all of `repository/rakun`; after it, `modules/<member>/**` per front ([`04-rakun/README.md`](./04-rakun/README.md) § Parallel groups); `starters/**`, `examples/**` (73) | the compiler, onze, jhonstart, emilia; the core's `src/{decorators,http,bootstrap}.bp` (frozen; the one writer is 130's decision-216 rewrite) |
| `05-jhonstart` | `modules/jhonstart/**` and `jhonstart-dom-test/**` (26 — `fake_dom.mjs` stays 26's; a front owns the test file it adds there); `jhonstart-link/**` (27); `jhonstart-forms/**`, `jhonstart-dom-test/test/forms_dom_test.bp`, the harness's `stubWireNames()` (67) | rakun; `element.bp`, `hooks.bp` (frozen); `routes.bp`'s segment walk (102), `render.bp`'s `isLangTag` (105), `form.bp`'s `formAction` check (103) while those fronts are open |
| `06-emilia` | `modules/emilia/src/**` and its comment carve-outs from 118 (34); `examples/emilia-card/**` and the fifteen example READMEs (33) | jhonstart; `src/scoped.bp` and `jhonstart-emilia/**` (`08-bpp/119`) |
| `07-onze` | `onze/**` + `onze-server/**` + `onze-test`'s root and group files (49); `onze-cli/**` + `onze-bundler/**` (50); `onze-assets/**` + `onze-og/**` (51); `onze-release/**` + `examples/static-site/**` (71); `examples/blog/**` (53) | rakun, jhonstart; the lines 102 names in `types.bp`, `scan.bp`, `chunk.bp`, 104's in `server.bp` and `image_handler.bp`, 107's in `otp.bp` / `docker.bp` / `spec.bp`, while that front is open |
| `08-bpp` | `jhonstart-html/**` (118; after 26 step 0, `jhonstart/src/html.bp`, to which 119, 120 and 126 each append one arm), the core's `src/prelude.bp` (118, decision 270); the new member `onze-content` (121); `emilia/src/scoped.bp` + `jhonstart-emilia/**` (119); new files and named lines in the jhonstart core, `jhonstart-link`, `jhonstart-forms`, rakun, `rakun-app`, `libs/actions`, `onze`, `onze-cli`, `onze-bundler` (117 · 120 · 122 · 123 · 124 · 126 · 127, each README § Owns); in botopink-lang, **116 only**: the manifest key, the extension lists and the unfold in `compiler-cli` / `language-server` / `lib-test-runner`, and `vscode-extension` | `modules/compiler-core/**`, every `codegen/*.zig`; a file a front of track 03–07 owns, until it has landed ([`08-bpp/README.md`](./08-bpp/README.md) § Who else owns the files) |
| `20-snap` (135) | the snapshot steps of 97 s7, 19 s6, 26 s7, 33 s1/s3/s4, 50 s8, 51 s7, 53's runner, 71 s6; `modules/emilia-test/**` (s4) and the helper it names in `rakun-test`; onze's E2E runner `onze-test/src/e2e.bp` (s5) | every test and `.snap` that exists today |
| meta repo | `.github/` (114); `specs/**` — a front's README is that front's, the top-level files the coordinator's | — |

**Open item — the runners have no owner.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (beyond
114's budget lines), `tests/language/run.sh` (beyond 12's report and `all)` line),
`modules/test-shard/**`, `modules/lib-test-runner/**` and the meta `scripts/**` were owned by
`25-gate-perf`, `00-gate` 113, 115 and 133, all closed. Until the maintainer names an owner, a front
that must edit one names it as a carve-out in its commit, and no two open fronts edit the same one.

## Conflict rules

- **97 before any "consume std" step.** 97 steps 0–5 are on `feat`, so every "consume std" step is
  open (49 s1, 50 s1, 51 s1, 34 s1). 97's residue runs alone in `libs/std/src/**`; 97 step 12
  lands before `05-wasm` step 5 and the `math` steps of 02 and 03 (both sides edit std's wasm
  bodies).
- **`03` against the library tracks** (decision 188): a `03` front has a package half
  (`libs/<pkg>/**`, disjoint from every library front) and a consumer half (one commit per member),
  and a consumer commit never shares a wave with the front that owns the member. **102 step 3 and
  103 step 2 take their consumer commits before the library fronts open**, rakun's first. The
  "consume std" steps 49 s1 / s6, 50 s1, 51 s1 open now, before 102 step 3: they touch none of
  102's lines and must not share a wave with 102 step 3's onze commits — this departs from the
  letter of 188 (to confirm). 104 step 5, 105, 107 and 106's `problem_digest` commit take their
  slot **after** the fronts that own their consumer files; 106's other consumers are the owners' own
  steps (26 s4, 17, 49 s3 — decisions 194, 195). 104 before 105 (both edit `rakun-app/src/i18n.bp`);
  71 and 81 before 107; 103 step 2 before 67; 105's edit of `libs/validation/src/messages.bp`
  between two steps of 125, never during one.
- **The three registration files** take one appending front at a time (decision 189): 104 owns the
  lines; `routing`, `actions`, `validation`, `http`, `log` are registered; 105, then 107.
- **Inside `04-rakun`**: 128 first and alone in the repository (decision 187), after the rakun
  commits of 102 step 3 and 103 step 2; then groups A, B, C as its README computes. 04 step 1 (the
  tag epoch, decision 185) gates 13 and 12; 04 step 4 gates 08 step 1, 19 steps 2–5 and 88; 04
  step 5 gates 22; 19 step 1 gates 12 and 09; 15 gates 91 and 92; 74 gates 92. **65 does not wait
  on 13** (its relay streams through `httpc`, not `rakun-client`). 92 step 2 waits on `03r-an`.
  73 is in group A (decision 189).
- **130 ↔ 128 — to confirm** (no decision id): (1) 128 does not wait on 130; (2) no 130 rakun
  commit is in flight while 128 is open, and 130's rakun sites are re-pointed at the post-128 paths;
  (3) after 128, each 130 rakun commit is a decision-188 consumer commit — before the owning rakun
  front opens if ready, else after it lands; (4) the frozen-files rule excepts 130's rewrite of
  `src/decorators.bp`.
- **`08-bpp` against the library tracks**: every `08` front but 121 sequences **after** the front
  that owns its files: 26 before 119 step 2, 120 and 122; 27 before 126; 67 and 103 before 127; 50
  and 102 before 117 and 124; 49 before 117's `paginate.bp`, 122's `site` key and `onze-server`'s
  lines; 04 and 65 before 123 (decision 189); 22 before 117, 120 and 127. **118 goes first**: its
  bracket-attribute carve-outs land before the owning front opens (189 org-3), and it writes the
  core's `prelude.bp` and the node type before 26 opens (270). In emilia the carve-out is comments
  only, and 34 step 1 and 33 step 2 take it over and open now — this departs from the letter of 189
  (flagged as `ctr-r`).
- **Files several fronts append to, one at a time** (decision 189): `html.bp` 119 → 120 → 126;
  `rakun-app`'s `botopink.json` / `root.bp` 117 → 120 → 127; the jhonstart core 120 → 122;
  `fake_dom.mjs`, after 26, 120 → 126; `onze/src/config.bp` 122 (`site`) → 124.
- **116 against `01-compiler`**: it edits `compiler-cli/**` and `language-server/**` (26's),
  `lib-test-runner/**` (no owner) and `docs.md` § Modules (07's prose); it never edits
  compiler-core (decision 198). It opens after `01-compiler/26`, 26 step 0 and 118, never beside
  26-cli-tooling; its prelude list and `01-checker` step 22 land in sequence.
- **Inside `01-compiler`**: its README § Ownership; 16 step 8 before 01 step 10; 07 steps 1 and 4
  after 02–05 land; 16 step 3 after every tree is migrated.
- **The dynamic mark** (decision 186): 22 step 4 and 49 step 5 land the run-time bridge; 26 step 8
  replaces it when `01-checker` lands the hooks capability.
- **135**: step 5 (onze's E2E runner) lands before 53 steps 2–6, which run on it; step 4 after 34
  (it records what 34 moves); steps 1–4 follow the owning fronts' other steps, one library at a
  time, last.

## Execution order of tracks 03–08

The order threads are opened from for tracks 03–08, closed by `02/98` and `20-snap/135`; the
compiler fronts run beside it, taking free threads.

### Dependency graph

A front needs what its row names — fronts landed, decisions by number, open ids by id — and
unblocks the last column. Compiler fronts are in [`01-compiler/README.md`](./01-compiler/README.md).

| Front | Needs | Unblocks |
|---|---|---|
| **102** s1–2 | the unpushed branch pushed, gated, landed | 102 s3 · 117 · 122 |
| **102** s3 | s1–2 · 49-d confirmed as amended | 128 · 22 · 26 · 49 · 50 · 117 · 124 |
| **103** s1 | the unpushed branch pushed, gated, landed | 103 s2 · 127 |
| **103** s2 | s1 | 128 · 22 · 67 · 127 |
| **104** s5 | 04 · 65 · 79 · 12 · 19 · 22 · 123 · 49 · 51 | 105 |
| **105** | 104 s5 · 22 · 26 · 03r-q confirmed | — |
| **106** s2 | 17 · 26 s4 · 65 · ctr-k | — |
| **107** | 07-g (a) · 71 · 81 | — |
| **125** s3–10 | 07-j · s6: decision 183 | 127 (s6) |
| **128** | the rakun commits of 102 s3 and 103 s2 · the 130 rule · ctr-k | every rakun front |
| **04** | 128 | 13 · 12 (s1) · 22 (s5) · 08 s1 · 19 s2–5 · 88 (s4) · 123 · 104 s5 · 71 s3 |
| **74** | 128 | 92 |
| **08** | 128 · s1: 04 s4 | — |
| **15** | 128 · s5: 03r-al | 19 s2–5 · 91 · 92 |
| **79** | 128 · s3: 03r-ae | 104 s5 |
| **81** | 128 · s3: 03r-ak | 88 · 107 · 71 s3 |
| **93** | 128 | 88 |
| **73** | 128 · s3: 03r-af | 88 |
| **19** s1 | 128 | 12 · 09 |
| **19** s2–5 | 15 s1 · 04 s4 · s3–4: 03r-am | 104 s5 |
| **13** | 04 s1 | 17 · 09 |
| **17** | 128 · 13 s2 | 49 s3 · 106 s2 |
| **22** | 04 s5 · 102 s3 / 103 s2's `rakun-app` commits · s4: decision 186 | 11 · 49 s5 · 51 · 53 · 27 s1 box 2 · 71 s4 · 117 · 120 · 127 · 104 s5 · 105 |
| **12** | 19 s1 · 04 s1 | 53 · 104 s5 |
| **11** | 128 · 22 (R11-7) | 71 s3 |
| **65** | 128 · s1: decision 201 | 49 s4 · 53 · 123 · 104 s5 · 106 s2 |
| **09** | 19 s1 · 13 · s5: 03r-ab | — |
| **91** | 15 · decision 274 | — |
| **92** | 74 · 15 · s2: 03r-an | 88 |
| **88** | 81 · 93 · 92 · 04 s4 · 73 | — |
| **26** | 118 · 102 s3's `routes.bp` · s5: 29-a · s8: the checker's hooks capability, ctr-l | 67 · 49 s3 · 53 · 119 s2 · 120 · 122 · 116 · 105 |
| **27** | s1 box 2: 22 · 27-a | 50 s6 · 126 · 53 |
| **67** | 26 · 103 s2 · 67-a | 53 · 127 |
| **136** | 26 · 120 · 125 · atm-a · atm-c · s8: atm-d | 123 (locals) · 127 · 53 |
| **34** | s2: 05emilia-l · s4: 05emilia-n | 135 s4 |
| **33** s2 | — | 98 |
| **49** | 102 s3's `types.bp` (s2–s5; s1 and s6 open now) · s3: 26 s4, 17 · s4: 65 s1 · s5: 22 s4 · 49-e | 50 · 51 · 71 · 53 · 117 · 120 · 122 · 127 · 104 s5 |
| **50** | 102 s3's `scan.bp`, `chunk.bp` (s2–s7) · 49 s6 · s2: 50-b · s4, s7: std-d · s5: 71 s2 · s6: 27 s1 | 53 · 117 · 120 · 124 · 71 s5 |
| **51** | 49 s6 · s2, s5: 22 · s4: 52-a | 53 · 104 s5 |
| **71** s1–2 | 49 s6 | 50 s5 · 53 · 124 |
| **71** s3 · s4 | s3: 11, 04, 81 · s4: 22 | 53 · 107 |
| **71** s5 | 50 · 53 | — |
| **53** | 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (s2–6) · s6: 50-b | 71 s5 · 121 s7 · 124 s5 · 120's and 126's browser boxes |
| **118** | props-d/e/f (their boxes) · ctr-r | 26 · 119 · 120 · 126 · 121 s6 · 116 |
| **121** s1–2 · s3–6 · s7 | — · s3: 08-f, s6: 118, 117 · 53 | 117 · 124 |
| **119** | 08-d · s2: 118, 26 | 120 |
| **123** | 04 · 65 · s1: 08-j | 127 s4 · 104 s5 |
| **117** | 102 · 22 · 49 · 50 · 121 s1–2 | 120 · 127 · 121 s6 · 124 |
| **120** | 118 · 119 · 117 · 26 · 22 · 49 · 50 | 122 · 126 · 127 · 124 |
| **122** | 26 · 49 · 102 · 118 · 120 | 124 |
| **126** | 27 · 118 · 120 | 127 · 124 |
| **127** | 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123 | 124 |
| **116** | 118 · 26 s0 · `01-compiler/26` · with `01-checker` s22 · decisions 198–200, 212, 213, 221, 270, 285, 288, 289 · s2: `01-checker` s25 | 124 s5 |
| **124** | 08-h · 50 · 71 · every other `08` front · s5: 116, 53 | — |
| **98** | every library track's `-test` and README steps · s3: 95-f · s4: lg2-v | — |
| **135** | snap-a · s4: 34 · s1–4: the owning fronts' other steps | s5: 53 s2–6 |

### Waves

At most six worktrees run at once across every lane (three when the console is closed); the lane-1
fronts of [`status.md`](./status.md) and 16, 18, 23, 24 take a thread when one is free, so each
wave lists its fronts most blocking first. A front whose prerequisites have landed may open in a
thread freed before its wave. The fronts of one wave share no source file and no test directory but
for the carve-outs named above.

| Wave | Opens | When |
|---|---|---|
| 1 | 118 · 34 · 33 s2 · 121 s1–2 · the onze "consume std" thread (49 s1, 49 s6, 50 s1, 51 s1) · 27 (s1 box 1, s2, s3) · 125 s3 → s10; 102 s1–2 and 103 s1 pushed and landed (no thread) | now |
| 2 | 102 s3 + 103 s2, one thread: rakun's commits first, the onze commits after the consume-std thread lands | 102 s1–2 and 103 s1 landed |
| 3 | 128 · 26 · 49 s2 · 50 s2–3, s7 · 71 s1–2 · 119 | 102 s3 / 103 s2's rakun commits (128); 118 and `routes.bp` (26); `types.bp` (49); `scan.bp`, `chunk.bp` (50); 49 s6 (71); 08-d and 118 (119) |
| 4 | 04 (s1 first) · 19 s1 · 15 · 74 · 81 · 67 | 128 landed (rakun); 26 and 103 s2 (67) |
| 5 | 08 · 79 · 93 · 73 · 13 · 12; 116 at the earliest | 128; 04 s4 (08 s1); 04 s1 (13, 12); 19 s1 (12); 118, 26 s0, `01-compiler/26` (116) |
| 6 | 22 · 65 · 17 · 09 · 92 · 91 | 04 s5 (22); 13 s2 (17); 19 s1 and 13 (09); 74 and 15 (92); 15 (91) |
| 7 | 11 · 123 · 117 · 49 s3–5 · 51 s2–6 · 71 s3–4 · 27 s1 box 2 · 135 s5 | 22 (11, 117, 51, 49 s5, 71 s4, 27); 04 and 65 (123); 26 s4 and 17 (49 s3); 65 s1 (49 s4); 11, 04, 81 (71 s3); snap-a (135 s5, before 53) |
| 8 | 88 · 19 s2–5 · 120 · 53 · 104 s5 · 106 s2 · 50 s5–6 | 81, 93, 92, 04 s4, 73 (88); 15 s1, 04 s4 (19); 117, 119 (120); every front 53 names; every owner of 104's consumer files; 65, 17, 26 s4 (106); 71 s2, 27 s1 (50) |
| 9 | 122 · 126 · 121 s3–6 · 105 · 107 | 120 (122, 126); 08-f, 117 (121); 104 s5 (105); 07-g, 71, 81 (107) |
| 10 | 127 · 71 s5 · 121 s7 · 124 s1–4 | 125 s6, 126, 123 (127); 50 and 53 (71 s5, 121 s7); 08-h and every other `08` front but 116 (124) |
| 11 | 124 s5 · 98 · 135 s1–4 | 116 and 53 (124 s5); every library track (98); snap-a, 34 and the owning fronts (135, last) |

The chains that set the pace: 102 / 103 pushed → 102 s3 + 103 s2 → 128 → 04 → 22 → 49 → 53;
118 → 26 → 67 → 127; 118 → 119 (08-d) → 120 → 126 → 127 → 124.

## Gate

Every front README's `**Gate:** standard (fronts.md § Gate)` line means all of the following; the
boxes after it on that line are the front's own.

- [ ] `scripts/gate.sh --cold` green in the front's worktree — every stage, under the rules of
      [`00-gate/README.md`](./00-gate/README.md); a library front's repository hook and CI shape
      green on every row its manifests declare.
- [ ] `AGENTS.md` of every directory touched, updated in the same commit.
- [ ] The commit is on `front/<NN-name>` in each submodule touched, then the submodule bump in the
      meta repo on the meta branch of the same name.
- [ ] Landing is the maintainer's: the merge into `feat` follows a green gate, never precedes it.
- [ ] No `--no-verify`, and no hook, flag or list that lets a red pass.

## Exit gate of the milestone

Every line is a command and the output it must print; nothing is read from a spec.

1. `scripts/gate.sh --cold` in `repository/botopink-lang`: every stage green, each stage's count
   equal to its `--list` plan; no ledger file on disk (00-gate rule 2).
2. `tests/language/run.sh --target all` includes beam: `N passed, 0 failed`.
3. `zig build test-libs`: every visible library, member and manifest target `N passed, 0 failed`;
   a cell reporting `skipped` is red.
4. Each repository's own CI (`emilia`, `erika`, `jhonstart`, `onze`, `rakun`, `vscode-extension`,
   botopink-lang, the meta `hook-integrity`): green on every row, no `allow_fail`, no vacuous row.
5. `scripts/format-check.sh` over every tree and `zig fmt --check modules`: clean.
6. `scripts/language-gap-markers.sh`: every `// LANGUAGE GAP:` marker names a row of
   `language-gaps.md` (the closed milestones' spec trees excluded).
7. `gate.sh --cold` within `budget_cold` (450 s, decision 265).
8. `status.md` lists no open line; every open decision id is answered in `decisions-taken.md` or
   still listed in `decisions-pending.md` with the step it blocks.
