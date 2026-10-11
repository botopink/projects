# Front 163 — meta-ci: the meta repository's CI, the pointers, the specs' upkeep

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
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

#### Step 9 — a red the gate can meet (was `114-gate-docs-and-ci` s9)

- [ ] `repository/rakun/modules/rakun-websocket/test/limits_test.bp:48` (load-dependent cap): bound
      holds under load, or cap made deterministic; ten cold runs of rakun's cells green on a loaded machine
      — cause found and fixed in the test (chores patch): the test read the session ids before the
      connection registered its session and slept 3 s for the close; it now waits on both events.
      Measured: rakun-websocket 7 runs green under load 20–37; the ten runs of rakun's cells remain
- [ ] rakun-messaging: one erlang test red once under load 26, unnamed and not reproduced in 39 runs (status L2)

**Gate:** standard (fronts.md § Gate) + `zig build test-docs` green with `0 skipped`.

### 163 s2 — the pointers' sweep — last (07 s11)

#### Step 11 — the pointers' sweep (last) (was `07-residuals` s11)

Five library pointers bumped in one sweep after each library's branch merges into its `feat`.
jhonstart's "always name the module" rule (`repository/jhonstart/AGENTS.md`) deletable since
`04-js`'s 1.0.10 step 5 — jhonstart track's edit, noted for the sweep.

- [ ] the five pointers bumped in one meta commit

### 163 s3 — the rule that keeps the specs from drifting (141 s6, on `141-a`)

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

### 163 s6 — a language tour generated from `botopink-lang/conformance/` (after 144 B-29 step I)

**Repository:** a new `botopink/tour` (created when this step opens) · **Model:** opus

A short, ordered, teaching path through the language (as *A Tour of Go*): a curated selection of cells with
teaching text, published as a site. Nothing duplicated — each lesson names its cells and its reference section
in `botopink/conformance`, rendered from them. The conformance repository keeps its name: it states what it
guarantees, the contract every implementation passes.

- [ ] the lesson order and the cell each lesson shows, chosen from `botopink-lang/conformance/`
- [ ] a generator renders the lessons from the cells and the reference, with no copied text or code

### 163 s7 — `scripts/gate.sh` in every repository; the libraries' gate checks `conformance/` (decisions 463, 466)

**Repository:** every library repository and the meta repository (a full worktree) · **Model:** sonnet

After 144 B-29 steps H and I (`botopink cell check`, botopink-lang's `scripts/gate.sh` as hook and CI entry).

- [ ] each library gets `scripts/gate.sh`, one text identical across the libraries (CI check 4 extended to it): it
      runs the shared `runner-standalone.sh` and the repository's `repository-stages.sh`; the pre-commit hook and
      the library's `test.yml` call it
- [ ] `runner-standalone.sh` gains a stage: `botopink cell check conformance/` (464) — every
      `conformance/modules/*/` cell on the targets the manifests declare, a mismatch a `.snap.new` candidate and a
      red; absent only structurally (no `conformance/` directory)
- [ ] the libraries' pre-commit hook runs `scripts/gate.sh --no-conformance` (470); the Conformance step and the GitHub
      pipeline run it with conformance
- [ ] the meta repository's `scripts/gate.sh` runs `hook-integrity.yml`'s checks locally, and the workflow calls it
- [ ] the meta repository's `scripts/gate.sh` is the machine's scheduler (decision 469): it owns the job pool,
      runs several repositories' gates together and hands each its share of jobs; the coordinator runs every full
      gate through it; measured: two gates together finish sooner in total than one after the other, no timing red
- [ ] each library's `scripts/gate.sh` knows no pool and no lock: it takes a total of jobs (default the machine's)
      and offers `--no-conformance` (the hook's, 470); a library's `test-out` per run
- [ ] copied byte for byte to every library (CI check 4 green); each library's `AGENTS.md` names `scripts/gate.sh`
      and its `conformance/`
