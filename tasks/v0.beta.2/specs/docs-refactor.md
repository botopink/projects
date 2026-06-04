# Docs & project-structure refactor — apply the 3-layer doc model to the repo

**Slug**: docs-refactor
**Depends on**: nothing
**Files**: AGENTS.md, tasks/AGENTS.md, tasks/_TEMPLATE.md, tasks/v0.beta.*/**, all distributed `*/AGENTS.md`, scripts/
**Touches docs**: AGENTS.md (root), tasks/AGENTS.md, every distributed `AGENTS.md` it trims
**Status**: done (F0–F4 — see status.md)

> Markdown-only refactor — no compiler code changes. The goal is to apply the
> agreed model (one fact → one source; authored vs derived; the 3 layers) to the
> repo's docs and the task-set layer, so any agent can navigate and decide
> mechanically.

## Target structure

```text
AGENTS.md                  → root: GLOBAL invariants + link index only
                             (no duplicated subtree trees, no volatile counters)
*/AGENTS.md                → each leaf OWNS its directory's detail
tasks/
├── AGENTS.md              → universal task-set contract (D1–D10 + workflow)
├── _TEMPLATE.md           → spec mold
└── v0.beta.N/
    ├── README.md          → set index: feature table + DAG (no live status column)
    ├── plan.md            → reasoning scratchpad
    ├── status.md          → progress rollup (generated, do not hand-author)
    └── specs/<slug>.md    → one feature spec (authored, immutable)
scripts/
├── doc-health.sh          → orphan AGENTS / broken links / duplicated trees
└── status.sh              → regenerate a set's status.md from git + .tasks/*/TODO.md
```

## Steps

### F0 — task-set layer (done)
- [x] `tasks/AGENTS.md` — universal contract (D1–D10 + workflow)
- [x] `tasks/_TEMPLATE.md` — spec template
- [x] Migrate `tasks/v0.beta.1/` to the `specs/` layout + fix README links

### F1 — root `AGENTS.md` → index (D2) ✅
- [x] Remove the duplicated "AGENTS index" tree; keep only the per-directory link index
- [x] Remove volatile counters (e.g. "162 outputs", "174 snapshots", "70 LSP") — point to the owning leaf instead
- [x] Record neutrality (D5) + "one fact, one source" in the conventions section
- [x] Add `tasks/` to the repo tree + link `tasks/AGENTS.md`; trim the duplicated worktree prose + stale "Open parallel tasks" table

### F2 — de-duplicate distributed `AGENTS.md` (D2) ✅
- [x] Root file de-duplicated (the main offender — it mirrored every subtree)
- [x] Audit the remaining ~40 leaf `AGENTS.md`; each owns its detail, drops facts copied from root
      (volatile counters removed; stale trees fixed; duplicated `alloc` convention dropped;
      vestigial top-level `snapshots/` tree — empty placeholders — deleted)
- [x] Ensure every directory with code has an `AGENTS.md` reachable from its parent
      (added 5 minimal ones for `compiler-core/src/*/tests/`)

### F3 — authored vs derived in sets (D2 / O5) ✅
- [x] Set `README.md` carries no live Status column — links to `status.md` (applied to beta.1 + beta.2)
- [x] Mark `status.md` as the single state source (header note; generated rollup is F4)
- [x] The README DAG is structure-only; live state stays in `status.md`

### F4 — health tooling ✅
- [x] `scripts/doc-health.sh`: fail on orphan source dirs, broken relative links, volatile counters
- [x] `scripts/status.sh <set>`: print the `status.md` rollup table from spec headers,
      `task/<slug>` branches and `.tasks/<slug>/TODO.md` checkboxes (prints to stdout; redirect into the set)

## Test scenarios

```
doc-health ---- no orphan AGENTS.md (every code dir has one)
doc-health ---- no broken relative links across all .md
doc-health ---- no duplicated subtree tree in root AGENTS.md
status     ---- status.sh regenerates v0.beta.N/status.md deterministically
links      ---- every README spec link resolves to specs/<slug>.md
```

## Notes

- Markdown only — the pre-commit `zig build` + `zig build test` is unaffected, but must still pass.
- Everything in English, including planning/status docs and filenames.
- F0 is already complete (this set was bootstrapped by it); kept here so the spec records the full intent.
- F4 is optional; if skipped, `status.md` stays hand-maintained but must still be marked as the single live source.
