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

### 163 s4 — `repository/conformance` mirrors `tests/language` (after 144 B-29 step H)

**Repository:** conformance (the generator in the meta repository's `scripts/`) · **Model:** sonnet

`botopink/conformance` holds its scaffold only. The cells are edited in botopink-lang's `tests/language/`, landing
with the compiler change they prove; this repository is their mirror for any implementation of botopink.

- [ ] a generator (`scripts/`) copies every cell (decision 457's shape: `src/`, `snapshot/output/`,
      `snapshot/targets/`, `targets`) and `test/` from the botopink-lang pointer the meta repository pins, byte for byte, with the commit it came from recorded in the mirror's commit message
- [ ] a CI check fails when the mirror differs from the pinned `tests/language` (no hand edit survives)
- [ ] `repository/conformance/AGENTS.md` and `README.md` say how a cell is read (the `.out` / `.expect` shapes, the
      `.targets` narrowing) without naming botopink-lang's runner as the only way to run them
- [ ] `repository/conformance/.github/workflows/conformance.yml`, against **the newest botopink-lang**: it checks
      out botopink-lang at the head of `feat` (never a pinned ref), builds the compiler and runs two jobs, every
      row hard (no `continue-on-error`, no row that cannot fail), as the libraries' `test.yml` does:
      `cells` — `botopink cell check modules/` (decision 464): every cell on commonJS (node), erlang and beam (OTP 28,
      the release the compiler emits for) and wasm (wasmtime), on linux and macos; `mirror` — the cells equal botopink-lang's `tests/language` at that head
- [ ] it runs on a push to `conformance` and **whenever botopink-lang's `feat` moves**: botopink-lang's
      `test.yml`, green on `feat`, sends a `repository_dispatch` to `botopink/conformance` (a token with that one
      scope, a repository secret), so a compiler change is measured against the suite without a conformance commit
- [ ] the generator never writes or deletes a cell's `docs.md` (written only in conformance, decision 462); the
      `mirror` job compares everything but the `docs.md` files


### 163 s5 — the language reference moves to `botopink/conformance`, every example a cell (decision 461)

**Repository:** conformance and botopink-lang (a full worktree: two repositories) · **Model:** opus

After 163 s4 and 144 B-29 step H (the cells in decision 457's shape, the mirror running).

- [ ] each of `docs.md`'s 141 botopink fences becomes a cell in botopink-lang's `tests/language` (or names an
      existing cell showing the same thing): the 89 compiled-only and 13 `body` with their output, the 24
      `project` as multi-module cells, the 15 `reject` with their refusal — red on the parent, green after
- [ ] the reference written in `repository/conformance/` in decision 462's layout: the root `docs.md` (the index
      and the text no single cell owns) and `modules/<cell>/docs.md` beside each cell it explains, an example being
      the cell itself (or a `<!-- example: <cell> -->` reference from the root `docs.md`); botopink-lang's
      `docs.md`, its `docs/` (the manifest schema, `botopink-json.md`) and the language part of its `README.md`
      deleted — no copy
- [ ] `test-docs` becomes a check that every reference names an existing cell (the fences' compile check moves to
      the cells); the CLI's own usage text stays in botopink-lang
- [ ] botopink-lang's `AGENTS.md` (§ Conventions: "README.md and docs.md stay in sync") rewritten to name the
      reference's new home
- [ ] `conformance.yml` gains `reference`: every `<!-- example: … -->` names an existing cell, the reference
      rendered with its examples and published on GitHub Pages — on the same triggers, so the published reference
      always shows the newest compiler's answers


### 163 s6 — a language tour generated from `botopink/conformance` (after 163 s5)

**Repository:** a new `botopink/tour` (created when this step opens) · **Model:** opus

A short, ordered, teaching path through the language (as *A Tour of Go*): a curated selection of cells with
teaching text, published as a site. Nothing duplicated — each lesson names its cells and its reference section
in `botopink/conformance`, rendered from them. The conformance repository keeps its name: it states what it
guarantees, the contract every implementation passes.

- [ ] the lesson order and the cell each lesson shows, chosen from `botopink/conformance`
- [ ] a generator renders the lessons from the cells and the reference, with no copied text or code

### 163 s7 — the shared library hook checks `conformance/` (decision 463)

**Repository:** every library repository (a full worktree: the one shared runner text) · **Model:** sonnet

After 144 B-29 step H (the cells' runner, the 457 shape).

- [ ] `scripts/git-hooks/lib/runner-standalone.sh` gains a stage: `botopink cell check conformance/` (decision 464) —
      every `conformance/modules/*/` cell of the repository run on the targets its manifest declares and compared with
      its `snapshot/` (a mismatch writes a `.snap.new`
      candidate and fails; never overwritten); absent only structurally (no `conformance/` directory)
- [ ] the runner copied byte for byte to every library (CI check 4 green); each library's `AGENTS.md` names its
      `conformance/` directory

