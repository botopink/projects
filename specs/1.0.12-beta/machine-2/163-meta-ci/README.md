# Front 163 — meta-ci: the meta repository's CI, the pointers, the specs' upkeep

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Repository:** the meta repository — a full worktree; s7 and s8 change every library repository too (one commit per repository, decision 188), s6 a new `botopink/tour`, s9 measures botopink-lang and the libraries
**Model:** by step — sonnet for the CI and gate steps whose README fixes the design, opus where a choice is left (s6), haiku for the sweep (`AGENTS.md` § Which model a thread runs on); the Conformance step opus
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** the meta `.github/workflows/**`, `scripts/{worktree-add.sh,language-gap-markers.sh}`, `AGENTS.md`
§ Layout and § CI, the submodule pointers' sweep, `specs/**`'s drift rule.
**Depends on:** nothing; s2 after every library front merges.

Also here, with no box of its own: `own-a` (the runners `scripts/{gate.sh,test-libs.sh,lib/pool.sh}`,
`tests/language/run.sh`, `modules/test-shard/**`, `modules/lib-test-runner/**` have no owner — 144 owns them as
botopink-lang files, the meta `scripts/**` are this front's); `hook-integrity.yml` and `language-gap-markers.sh`
kept in step with each new repository.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `114-gate-docs-and-ci` s9 | 163 s1 |
| `07-residuals` s11 | 163 s2 |
| `141-specs-sweep` s6 | 163 s3 |
| `141-specs-sweep` gate | 163 s3 |

## Steps

### 163 s1 — the reds the gate can meet (114 s9)

**Repository:** rakun (`--repo rakun`; the test files only) · **Model:** sonnet (a red with a measured repro)

#### Step 9 — a red the gate can meet (was `114-gate-docs-and-ci` s9)

- [ ] `repository/rakun/modules/rakun-websocket/test/limits_test.bp:48` (load-dependent cap): bound
      holds under load, or cap made deterministic; ten cold runs of rakun's cells green on a loaded machine
      — cause found and fixed in the test (chores patch): the test read the session ids before the
      connection registered its session and slept 3 s for the close; it now waits on both events.
      Measured: rakun-websocket 7 runs green under load 20–37; the ten runs of rakun's cells remain
- [ ] rakun-messaging: one erlang test red once under load 26, unnamed and not reproduced in 39 runs (status L2)

**Gate:** standard (fronts.md § Gate) + `zig build test-docs` green with `0 skipped`.

### 163 s2 — the pointers' sweep — last (07 s11)

**Repository:** the meta repository (a full worktree: the pointers) · **Model:** haiku

#### Step 11 — the pointers' sweep (last) (was `07-residuals` s11)

Five library pointers bumped in one sweep after each library's branch merges into its `feat`.
jhonstart's "always name the module" rule (`repository/rakun/modules/rakun-bpp/AGENTS.md`) deletable since
`04-js`'s 1.0.10 step 5 — jhonstart track's edit, noted for the sweep.

- [ ] the five pointers bumped in one meta commit

### 163 s3 — the rule that keeps the specs from drifting (141 s6, on `141-a`)

**Repository:** the meta repository (`specs/**`; a full worktree) · **Model:** haiku (the rule is `141-a`'s answer)

#### Step 6 — The rule that keeps it from drifting (on `141-a`) (was `141-specs-sweep` s6)

The answer to `141-a` is written into `fronts.md` § Rules for a front, or into this track's
README. With (a), the recommendation, the rule reads: "the commit that writes a decision retiring a
spelling rewrites the class S lines of `specs/<current>/**` that write it, and adds its row to
`10-specs/141-specs-sweep/inventory.md`".

- [ ] `141-a` answered, and its rule written where the answer puts it

#### Gate additions (was `141-specs-sweep` gate)

- [ ] the meta `hook-integrity` workflow green: check 2 (every § Layout path exists) and check 5
      (`scripts/language-gap-markers.sh` exit 0)
- [ ] `git diff --stat` on the meta branch touches `specs/1.0.12-beta/**` only (plus `AGENTS.md` if a
      § Layout row's text names a retired spelling)
- [ ] every step's § Measure acceptance re-run on the tip that lands
- [ ] the commits are on the front's branch; landing is the maintainer's, who reviews step 1's
      rows line by line

### 163 s8 — each library's CI fetches its dependencies — the eighth step of the conformance order (decision 474 measured it)

**Repository:** every library repository with a `botopink.json` (a full worktree) · **Model:** sonnet

After the seventh step (`scripts/gate.sh libs`, closing B-00). Measured 2026-10-11 reading the pipelines (474): jhonstart, onze and rakun are red on `feat` — `dependency 'snap' was
not found under any library root` — because each library's `test.yml` checks out only itself and botopink-lang, and
the libraries that became repositories of their own (`snap`, decision 391; `styled`, `css`, …) are never fetched;
actions, http, log, routing, validation, css and styled have a `test.yml` that has never run on `feat`; snap, json,
yaml, markdown and dbcontext have none. Locally, in the meta checkout, every one is green: the siblings are there.

- [x] each library's `test.yml` fetches the library's dependencies from its manifests' `dependencies` (the `git`
      entries) — `bpmp install`, which already clones and links them — before it runs; jhonstart, onze and rakun green
- [x] a library with a `botopink.json` and no `test.yml` gets one, the same shape as the others (dbcontext, json and
      yaml hold no `botopink.json` yet; each gets its workflow with its first manifest)
- [x] the workflow fetches the dependency closure (each linked dependency's own `git` dependencies, the workspace
      members', the sibling path libraries') under `.botopinkbuild/deps/` and the gate reads it through
      `BOTOPINK_LIB_ROOTS`, which a cell's scratch copy also reads
- [ ] the meta `scripts/gate.sh check` holds every library's `test.yml` dependency step and `BOTOPINK_LIB_ROOTS` to
      one text (the cheap test of 478: the "not found" reds appear only on a runner with no sibling library)
- [x] actions, css, http, log, routing, styled and validation: their workflow never fired (no check suite of GitHub
      Actions on any push, though enabled and active); turning Actions off and on in each made every push fire it
- [ ] every library's workflow has at least one green run on `feat`, and its latest run green — read with `gh` (474).
      Measured: actions, http, log, routing, css, snap and markdown green; rakun, query and validation have green runs
      but their latest is red on the builtins group's spelling (rakun's and query's land with 165 s10 after B-136,
      validation's B-138 migration is open); json and yaml carry the shared `test` workflow and a manifest with no source yet
- [x] no row that cannot fail, no `continue-on-error` (gate-f); 163 s7 later makes each workflow call `scripts/gate.sh`

### 163 s6 — a language tour generated from `botopink-lang/conformance/` (after 144 B-29 step I)

**Repository:** a new `botopink/tour` (created when this step opens) · **Model:** opus

A short, ordered, teaching path through the language (as *A Tour of Go*): a curated selection of cells with
teaching text, published as a site. Nothing duplicated — each lesson names its cells and its reference section
in `botopink-lang/conformance/`, rendered from them (decisions 466, 467: the suite and the reference live there; no
`botopink/conformance` repository).

- [ ] the lesson order and the cell each lesson shows, chosen from `botopink-lang/conformance/`
- [ ] a generator renders the lessons from the cells and the reference, with no copied text or code

### 163 s7 — `scripts/gate.sh` in every repository; the libraries' gate checks `conformance/` (decisions 463, 466)

**Repository:** every library repository and the meta repository (a full worktree) · **Model:** sonnet

After 144 B-29 steps H and I (`botopink cell check`, botopink-lang's `scripts/gate.sh` as hook and CI entry).

- [x] each library gets `scripts/gate.sh`, one text identical across the libraries (CI check 4 extended to it): it
      runs the shared `runner-standalone.sh` and the repository's `repository-stages.sh`; the pre-commit hook and
      the library's `test.yml` call it — the workflow on a push to `feat` (477)
- [x] `runner-standalone.sh` gains a stage: `botopink cell check conformance/` (464) — every
      `conformance/modules/*/` cell on the targets the manifests declare, a mismatch a `.snap.new` candidate and a
      red; absent only structurally (no `conformance/` directory)
- [x] the libraries' pre-commit hook runs `scripts/gate.sh --no-conformance` (470); the Conformance step and the GitHub
      pipeline run it with conformance
- [x] the meta repository's `scripts/gate.sh` runs `hook-integrity.yml`'s checks locally, and the workflow calls it
- [x] the meta repository's `scripts/gate.sh` orchestrates (decision 473): `run <repository|task> …`, `tasks`, `libs`,
      `status`; tasks found by `git worktree list` of the meta repository and the submodules, a task's own repository
      told from its linked siblings; each run's log kept as scratch
- [x] the meta repository's `scripts/gate.sh` is the machine's scheduler (decision 469): it owns the job pool,
      runs several repositories' gates together and hands each its share of jobs; the coordinator runs every full
      gate through it
- [x] each library's `scripts/gate.sh` knows no pool and no lock: it takes a total of jobs (default the machine's)
      and offers `--no-conformance` (the hook's, 470); a library's `test-out` per run
- [x] copied byte for byte to every library (CI check 4 green); each library's `AGENTS.md` names `scripts/gate.sh`
      and its `conformance/`

### 163 s9 — the measurements, at the end (after 163 s8)

**Repository:** botopink-lang and the meta repository · **Model:** sonnet

Every time measurement of the conformance order waits for its end — no step in between spends time measuring.
On a quiet machine (load below 3, nothing else running):

- [ ] the full gate (cold and warm), the step gate (a one-backend and a shared change) and the hook's
      `--no-conformance` gate, per stage, in `scripts/AGENTS.md`
- [ ] `conformance/` by kind and by target (in-process cells against the CLI-run ones), with the cells a snapshot
      already covers named
- [ ] two gates through the meta repository's scheduler against one after the other (decisions 468, 469, 473)
- [ ] each library's gate (`scripts/gate.sh libs`), per library


### 163 Conformance — the front's last step (decisions 465, 474, 477, 478, 479, 480)

**Repository:** the meta repository and every library repository s7 and s8 changed (a full worktree) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479). s7 and s8
change how every library's gate and CI run, not what a library answers: the step audits that change.

- [ ] each library's GitHub pipeline green on `feat` after s7 and s8 landed (477), every workflow calling
      `scripts/gate.sh` with conformance, and the meta `hook-integrity` green; a red reproduced locally, fixed at once
      (430), pushed again; no cell edited to match the code
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478) — a check of the
      meta `scripts/gate.sh` or CI check 4 for a gate script — or why none can
- [ ] the change analysed: each repository's gate stages and conformance cells before and after s7, none dropped
      (decision 67); a cell the libraries' gate now reaches for the first time and is red, fixed in its library's front
- [ ] the reference (480): no library's `conformance/docs.md` or `AGENTS.md` contradicts how its gate now runs the cells
- [ ] the GitHub pipeline read (474, `gh` read only): every repository s7 and s8 changed, its runs on `feat` since the
      front's base, green or each red named and fixed or filed; the pipeline's state in the step's report

### 163 s10 — each repository's generated `decisions-taken.md` (decision 482)

**Repository:** every repository under `repository/` and the meta repository (a full worktree) · **Model:** sonnet

- [x] `scripts/decisions-split.py`: reads the meta `decisions-taken.md`, maps each row's Binds (front numbers, old ids
      through the fronts' alias tables) to repositories, writes `repository/<repo>/decisions-taken.md` (the header line
      of 482, the rows as in the source, English only); a row it cannot map is reported, never guessed
- [x] every repository commits its generated file; its `AGENTS.md` names it ("generated — edit in the meta repository")
- [x] a meta CI check (and the meta `scripts/gate.sh`) fails when a repository's file differs from the script's output
- [x] the meta `AGENTS.md` § CI and § Layout name the script and the check

### 163 s11 — a library task holds its repository alone (decision 483)

**Repository:** every library repository and the meta repository (a full worktree) · **Model:** sonnet

After 144 B-37 (`bpmp link`, `.botopinkbuild/deps/` first).

- [ ] the shared `runner-standalone.sh`'s `locateBotopink` tries `<project>/.botopinkbuild/bin/botopink` first
      (byte-identical across the libraries, CI check 4)
- [ ] `scripts/worktree-add.sh --repo <lib>` makes `.tasks/<name>/<lib>` alone, runs `bpmp link` against the main
      checkout, links `.botopinkbuild/bin/botopink` to the main checkout's compiler; `AGENTS.md` § Worktrees rewritten

### 163 s12 — `scripts/land-check.py`, the coordinator's check before a landing (decision 484)

**Repository:** the meta repository (a meta-only worktree) · **Model:** sonnet

- [x] `scripts/land-check.py <repo> <branch>` prints green, or each reason it is red, one line each: the branch is
      not a fast-forward of `origin/feat`; a tracked `*.snap.new`, `*.snap.md.new` or `todo.md`; in the meta specs a
      scratch reference (`scratch-refs.py`'s patterns) or a commit hash; an English/Portuguese pair whose ids or code
      blocks differ; a `snapshot/targets/` file the branch adds (named, for the coordinator to read against 458)
- [x] exit 1 when red; a test per reason, red on a branch built to fail it
- [x] the meta `AGENTS.md` § Layout names it

### 163 s13 — a small gate is not held behind every full-pool gate queued before it

**Repository:** the meta repository (`scripts/gate.sh`) · **Model:** sonnet · **Found by:** 166 s3 (the maintainer, 2026-10-18: "file the 163 box")

Measured on 2026-10-18: a library thread's `exec --jobs 3` (166 s3, json) waited about 78 minutes. In that time
botopink-lang threads ran their `exec --jobs 10` commands one after another. The cause is first come, first served
with head-of-line blocking (`poolAcquire`):

- a gate asking for the whole pool starts only on an empty pool;
- a gate is admitted only when no live gate has waited longer.

So a small gate waits behind every full-pool waiter queued before it. While one of those runs, the free jobs stay
idle, because the older full-pool waiter cannot start and the small gate may not pass it.

- [ ] the rule chosen and written in `gate.sh`'s comment and the meta `AGENTS.md` § Gate orchestrator. Recommended: while
      the pool is not empty, a gate asking for less than the capacity may be admitted ahead of an older full-pool waiter,
      at most one such pass in flight. The full-pool gate cannot start until the pool drains anyway, and the bound
      keeps a stream of small gates from starving it. The alternative is to keep the strict order as it is and only
      write down its cost.
- [ ] a test of the scheduler: two `exec --jobs <capacity>` waiters and one `exec --jobs 1`, the small one admitted
      while the first full-pool gate runs (red on the parent) and the second full-pool gate still started after it
