# Fronts — 1.0.12-beta: who may touch what, when

The open work is cut by repository in three tiers (decision 433): front 144 for `repository/botopink-lang`,
one front per library repository (145–162), and the medium tier (`3-medium/`). This file is the
milestone-level view: the rules for a front, who owns which repository, the sequences, the execution order,
and § Gate, the standard landing every front README cites. Where each front stands is
[`status.md`](status.md). The old track fronts keep their numbers; their ids resolve through each new
README's alias table.

A front is one worktree (`scripts/worktree-add.sh <NN-name>` → `.tasks/<NN-name>`), one branch
`front/<NN-name>` in the meta repo and in every submodule it edits, one `todo.md` (never committed), one
owner. Front 144 runs as up to three lanes (its README § Lanes), each a worktree of its own. Two worktrees
run at the same time only when they share **no source file and no snapshot or test directory**, except by a
carve-out a README names together with its sequence. **At most six worktrees run at once** across the
milestone (three when the console is closed).

## Rules for a front

1. **Only front 144 touches `repository/botopink-lang`** (433). A library or medium front that meets a
   compiler, std or toolchain gap files a row in [`language-gaps.md`](language-gaps.md) and pauses on the
   144 step that fixes it (rule 9); it never edits `modules/**`, `libs/std/**` or the toolchain's scripts.
2. **A shared member's `botopink.json` and `src/root.bp` belong to the lowest-numbered step** that owns
   anything in the member; a later step appends, in number order, and never rewrites.
3. **Sidecars are `src/sidecars/<lib>_<name>.erl`** and belong to the front that owns the `.bp` declaring
   their cells.
4. **The per-library `modules.md` is the source of truth** for members and their graph; a front that changes
   an edge updates it in the same commit.
5. **A front that needs a file it does not own stops and reports** to the owning front, through a
   handed-over row in that front's README.
6. **Decisions are asked, not guessed**: a question goes to [`decisions-pending.md`](decisions-pending.md)
   as Measured / Options / Recommendation / Blocks, the recommendation most restrictive (decision 67).
7. **The front's README stays current**: a landed step becomes one line under `## Done` in the landing
   commit; `status.md` is the only file that says where the milestone stands.
8. **Landing is § Gate.**
9. **A structural fix comes first** (decision 430): a defect or gap of the compiler, std or a shared layer
   that a front would otherwise work around opens at once as a step of its owning front (144 for
   botopink-lang), ahead of that owner's other steps; the fronts that would build on a workaround pause on
   it, no new workaround is written, and an existing one is removed in the fix's landing — unless the
   maintainer chooses a workaround for a named case.
10. **Consumer commits** (decision 188): a step whose change reaches other repositories carries one commit
    per repository it changes, in the same landing, producer first; a package's consumer halves stay with the
    package's front. When the consumer repository's own front holds the same files, the step hands the
    change over as a row in that front instead, and the two never share a wave.
11. **Comptime on wasm first** (decision 434): front 144's B-00 group opens before any other step of any
    front; until it lands, other fronts only finish what was already in flight when 434 was taken.

## Ownership, by repository

| Front | Owns | Never touches |
|---|---|---|
| **144** botopink-lang | all of `repository/botopink-lang` — `modules/{compiler-core,compiler-cli,language-server,lib-test-runner,bpmp,manifest,test-shard,wasm3}/**`, the new `modules/std-wasm/**` and `modules/beam-to-wasm/**` (434), `libs/std/**`, `tests/language/**`, `scripts/**`, `docs.md`, `docs/**`, `build.zig`, `.github/workflows/**`; the consumer commits its steps name (rule 10) | a library repository beyond those commits; the meta repository |
| **145** erika | `repository/erika/**` | rakun-data (150's), dbcontext (153's) |
| **146** validation | `repository/validation/**` | the consumers' code beyond their import lines |
| **147** css · **148** styled | `repository/css/**` · `repository/styled/**` | jhonstart, emilia |
| **149** jhonstart | `repository/jhonstart/**` — the core, `jhonstart-link`, `jhonstart-forms`, `jhonstart-html` until 26 s0 merges it, `jhonstart-styled` (119), `jhonstart-dom-test` | rakun; `styled`'s and emilia's trees |
| **150** rakun | `repository/rakun/**` (the tree 128 left; [`04-rakun/README.md`](2-libraries/150-rakun/04-rakun/track.md) § Where a merged member's front works), `rakun-app`'s middleware and actions (123, 127) | onze, jhonstart, emilia; the core's frozen `src/{decorators,http,bootstrap}.bp` except 144 B-19's consumer commits (339) |
| **151** json · **152** yaml · **158** markdown | `repository/{json,yaml,markdown}/**`; the consumers' dependency and import lines (rule 10) | the consumers' code beyond the import; onze-content's collections (162) |
| **153** dbcontext | `repository/dbcontext/**`; rakun-data's entity, repository and native-query code moving out (consumer commit) | erika (145); rakun-data's drivers and container (150) |
| **154** emilia | `repository/emilia/**` | jhonstart, `styled` |
| **155** http · **156** log · **157** routing · **159** actions · **160** snap | `repository/{http,log,routing,actions,snap}/**`; their consumer lines (rule 10) | anything else in the consumers |
| **161** vscode-extension | `repository/vscode-extension/**` | the compiler (144) |
| **162** onze | `repository/onze/**` — `onze`, `onze-server`, `onze-cli`, `onze-bundler`, `onze-assets`, `onze-og`, `onze-release`, `onze-content`, `onze-test`, the examples | rakun, jhonstart |
| **136** cardume | `repository/cardume/**` when born; `rakun-cardume`, `jhonstart-cardume` (its bridges) | the frameworks' cores |
| **163** meta-ci | the meta `.github/workflows/**`, meta `scripts/**`, `AGENTS.md` § Layout and § CI, the submodule pointers' sweep, the specs' drift rule (141-a) | every repository under `repository/` |
| **105** i18n · **107** release | `repository/{i18n,release}/**` when born; their consumer lines | — |
| **98** packaging tail · **135** snap | nothing of their own: the closing check and the order of the snapshot steps | — |
| meta repo | `specs/**` — a front's README is that front's, the top-level files the coordinator's | — |

**Open item — the runners' owner (`own-a`).** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}`,
`tests/language/run.sh`, `modules/test-shard/**` and `modules/lib-test-runner/**` are botopink-lang files,
so 144 holds them; the meta `scripts/**` are 163's. A step that edits a runner names it in its commit, and no
two open lanes edit the same one.

## Conflict rules

Written with the old front ids (alias tables); they bind the new fronts holding those steps.

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
  71 and 81 before 107; 103 step 2 before 67; 105's edit of `repository/validation/src/messages.bp`
  between two steps of 125, never during one.
- **No registration file** (decision 326): a package is a repository; 105 and 107 create theirs
  (`botopink/i18n`, `botopink/release`), and decision 189's appending order has nothing left to order.
- **Inside `04-rakun`**: 128 first and alone in the repository (decision 187), after the rakun
  commits of 102 step 3 and 103 step 2; then groups A, B, C as its README computes. 04 step 1 (the
  tag epoch, decision 185) gates 13 and 12; 04 step 4 gates 08 step 1, 19 steps 2–5 and 88; 04
  step 5 gates 22; 19 step 1 gates 12 and 09; 15 gates 91 and 92; 74 gates 92. **65 does not wait
  on 13** (its relay streams through `httpc`, not `rakun-client`). 92 step 2 waits on `03r-an`.
  73 is in group A (decision 189).
- **130 ↔ 128 — decision 339**: (1) 128 does not wait on 130; (2) no 130 rakun
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
  (`ctr-v`, only the record; `ctr-r` closed 9 Oct — 118 lands in `jhonstart-html` before 26 step 0
  merges it, so org-3 holds literally).
- **Files several fronts append to, one at a time** (decision 189): `html.bp` 119 → 120 → 126;
  `rakun-app`'s `botopink.json` / `root.bp` 117 → 120 → 127; the jhonstart core 120 → 122;
  `fake_dom.mjs`, after 26, 120 → 126; `onze/src/config.bp` 122 (`site`) → 124.
- **116 against `01-compiler`**: it edits `compiler-cli/**` and `language-server/**` (26's),
  `lib-test-runner/**` (no owner) and `docs.md` § Modules (07's prose); it never edits
  compiler-core (decision 198). It opens after `01-compiler/26`, 26 step 0 and 118, never beside
  26-cli-tooling; its prelude list and `01-checker` step 22 land in sequence.
- **Inside `01-compiler`**: its README § Ownership; 07 steps 1 and 4
  after 02–05 land; 16 step 3 after every tree is migrated.
- **The dynamic mark** (decision 186): 22 step 4 and 49 step 5 land the run-time bridge; 26 step 8
  replaces it when `01-checker` lands the hooks capability.
- **141 against every track**: it edits a front's spec text only while that front is not in a
  worktree, one commit per track; a front that opens while 141 is on its track takes 141's commit
  first, or receives its lines as a hand-off. It shares no source, test or snapshot file with any
  front, so it runs in any wave, taking a free thread.
- **135**: step 5 (onze's E2E runner) lands before 53 steps 2–6, which run on it; step 4 after 34
  (it records what 34 moves); steps 1–4 follow the owning fronts' other steps, one library at a
  time, last.

## Execution order

1. **144 B-00a → B-00e — comptime on wasm (434), first and alone.** Nothing else opens before it; the fronts
   in flight when 434 was taken have landed (checker-s41, checker-s29, render-scope-388, bigint-139, comptime-14,
   import-129, typed-member-395's compiler half; its validation half waits in 146 s1 on B-10 G1).
2. **144's lanes**, in its README's order: the error contract (B-01–B-09), then the structural fixes the
   libraries wait on (B-10–B-19), then the rest (B-20–B-29). Lane A (checker) is serial; lanes B and C run
   beside it on disjoint files.
3. **The library fronts, in this order**, each opening when the 144 steps it names have landed: 145 erika
   (B-18) · 146 validation (B-10 G1, B-16) · 147 css · 148 styled (B-10 G2) · 149 jhonstart (B-14, B-15, B-17)
   · 150 rakun (waves A → B → C, then 123, 127; B-11, B-12, B-13, B-19) · 151 json (B-27) · 152 yaml · 153
   dbcontext (145 s1) · 154 emilia (148) · 155 http · 156 log (B-25) · 157 routing · 158 markdown · 159
   actions · 160 snap · 161 vscode-extension (B-27) · 162 onze, last (53 needs every other front).
4. **The medium tier**: 136 cardume (149, 120, 146), 105 i18n (155 s2), 107 release (`07-g`, 150 s7, 162
   s4), 163 meta-ci (s2 last), 98's closing check, 135's order; a decision-blocked step stays in its front
   and waits in `status.md`'s L5.

At most six worktrees at once; a front whose prerequisites have landed may take a thread freed early. The
chains that set the pace: B-00 → B-14 → 149 (118 s1) → 26 → 67 → 150 s23 (127); B-15 → 149 s5 (119) → s6 (120)
→ s8 (126); B-18 → 145 s1 → 153; 150 s1 (04) → s13 (22) → 162 s1 (49) → s9 (53).

### Dependency graph (old ids)

The graph inside the library tier, written with the old front ids; each resolves through the new READMEs'
alias tables (137 → 145 s1, 26 → 149 s1, 04 → 150 s1, …). Compiler steps are 144's.

| Front | Needs | Unblocks |
|---|---|---|
| **102** s1–2 | done (re-implemented in `repository/routing`) | 102 s3 · 117 · 122 |
| **102** s3 | s1–2 · 323 | 128 · 22 · 26 · 49 · 50 · 117 · 124 |
| **103** s1 | done (re-implemented in `repository/actions`) | 103 s2 · 127 |
| **103** s2 | s1 | 128 · 22 · 67 · 127 |
| **104** s5 | 04 · 65 · 79 · 12 · 19 · 22 · 123 · 49 · 51 | 105 |
| **105** | 104 s5 · 22 · 26 · 03r-q confirmed | — |
| **106** s2–3 | 17 · 26 s4 · 65 · 349 | — |
| **107** | 07-g (a) · 71 · 81 | — |
| **125** s4–10 | 325 (every step) · s6: decision 183 | 127 (s6) |
| **128** | the rakun commits of 102 s3 and 103 s2 · the 130 rule (339) | every rakun front |
| **04** | 128 | 13 · 12 (s1) · 22 (s5) · 08 s1 · 19 s2–5 · 88 (s4) · 123 · 104 s5 · 71 s3 |
| **74** | 128 | 92 |
| **08** | 128 · s1: 04 s4 · s7: 137 s1–5, 01-checker s29 | — |
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
| **09** | 19 s1 · 13 · s4: erk-b · s5: 03r-ab | — |
| **12** s5 | 01-checker s30 | — |
| **138** | the six repositories (maintainer) · between two waves | 102 s3 · 103 s2 · 104 s5 · 105 · 106 s2 · 107 · 125 s4–12 · 136 (the submodule) |
| **139** | 04-js s9 · 05-wasm s8 | 97 s15 · 125 (number fields) |
| **140** | 05-wasm s5 · 18 (emitter) · 98 (manifest key) | 97 s11, s17 · 05-wasm (the refusal list) |
| **137** | s5 and s2's template method `query` (397): 01-checker s29 | 08 s7 |
| **143** | 137 s2 · 01-checker s29 · s3: 128 | 08 s7 |
| **91** | 15 · decision 274 | — |
| **92** | 74 · 15 · s2: 03r-an | 88 |
| **88** | 81 · 93 · 92 · 04 s4 · 73 | — |
| **26** | 118 · 102 s3's `routes.bp` · s5: 29-a · s8: the checker's hooks capability, ctr-l · s13: s0, `01-checker` s28, the props-filling lowering (362) | 67 · 49 s3 · 53 · 119 s2 · 120 · 122 · 116 · 105 |
| **27** | s1 box 2: 22 | 50 s6 · 126 · 53 |
| **67** | 26 · 103 s2 · 67-a | 53 · 127 |
| **136** | 26 · 120 · 125 · atm-c · s8: atm-d | 123 (locals) · 127 · 53 |
| **34** | s5 (first, 350): 119 s1 · s2: s5 · s3: 119 s1 · s4: none (401) | 135 s4 · 119 s5 |
| **33** s2 | — | 98 |
| **49** | 102 s3's `types.bp` (s2–s5; s1 and s6 open now) · s3: 26 s4, 17 · s4: 65 s1 · s5: 22 s4 · 49-e | 50 · 51 · 71 · 53 · 117 · 120 · 122 · 127 · 104 s5 |
| **50** | 102 s3's `scan.bp`, `chunk.bp` (s2–s7) · 49 s6 · s2: 50-b · s4, s7: std-d · s5: 71 s2 · s6: 27 s1 | 53 · 117 · 120 · 124 · 71 s5 |
| **51** | 49 s6 · s2, s5: 22 · s4: 52-a | 53 · 104 s5 |
| **71** s1–2 | 49 s6 | 50 s5 · 53 · 124 |
| **71** s3 · s4 | s3: 11, 04, 81 · s4: 22 | 53 · 107 |
| **71** s5 | 50 · 53 | — |
| **53** | 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (s2–6) · s6: 50-b | 71 s5 · 121 s7 · 124 s5 · 120's and 126's browser boxes |
| **118** | s1's component spread: `01-checker` s34 (359) · s4: slots (360) | 26 · 119 · 120 · 126 · 121 s6 · 116 |
| **121** s1–2 · s3–6 · s7 | — · s3: 08-f, s6: 118, 117 · 53 | 117 · 124 |
| **119** | s1: the two repositories' first `feat` commit · s2: 118, 26 · s5: 34 s5 | 120 · 34 s5 (first, 350), s3 · 116 s6 (the style section's examples) |
| **123** | 04 · 65 | 127 s4 · 104 s5 |
| **117** | 102 · 22 · 49 · 50 · 121 s1–2 | 120 · 127 · 121 s6 · 124 |
| **120** | 118 · 119 · 117 · 26 · 22 · 49 · 50 | 122 · 126 · 127 · 124 |
| **122** | 26 · 49 · 102 · 118 · 120 | 124 |
| **126** | 27 · 118 · 120 | 127 · 124 |
| **127** | 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123 | 124 |
| **116** | 118 · 26 s0 · `01-compiler/26` · with `01-checker` s22 · decisions 198–200, 212, 213, 221, 270, 285, 288, 289, 338 · s2: `01-checker` s25 · s6: 119 s2 | 124 s5 |
| **124** | 50 · 71 · every other `08` front · s5: 116, 53 | — |
| **98** | every library track's `-test` and README steps · s3: 95-f · s4: `subdir` (344) | — |
| **135** | s0: `botopink/snap` created (391) · s4: 34 · s1–4: s0 and the owning fronts' other steps | s5: 53 s2–6 |

## Gate

Every front README's `**Gate:** standard (fronts.md § Gate)` line means all of the following; the
boxes after it on that line are the front's own.

- [ ] `scripts/gate.sh --cold` green in the front's worktree — every stage, under the rules of
      [`00-gate/README.md`](1-botopink-lang/144-botopink-lang/00-gate/track.md); a library front's repository hook and CI shape
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
