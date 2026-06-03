# tasks — spec sets (universal contract)

> Path: `tasks/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Template: [`./_TEMPLATE.md`](_TEMPLATE.md)

This folder holds the project's **specs**, grouped into versioned **sets**
(`v0.beta.1`, `v0.beta.2`, …). It is the planning/roadmap layer — distinct from
the per-directory `AGENTS.md`/`docs.md`/`examples.md` (which describe the code as
it *is*) and from `.tasks/<slug>/` git worktrees (where work is *executed*).

**This file is the universal contract: every rule here applies to every set.**
Anything specific to one set lives inside that set's folder, never here.

## Glossary

- **Spec** — the written description of *one* feature, authored **before** building
  it: what it does, the steps to build it, and how you know it's done. It is
  *intent*, not progress; *design*, not code; **immutable once written**. One
  feature = one file: `tasks/v0.beta.N/specs/<slug>.md`.
- **Set** — a versioned *batch* of specs (`v0.beta.N`). A label, **not** a
  sequential phase. A completed set freezes as immutable history.
- **Task** — the executable unit: one spec → one branch `task/<slug>` → one
  worktree `.tasks/<slug>/`. Tasks run in parallel and do not wait on each other
  unless a real dependency says so.

## Ownership — what lives where (D10)

Three levels, each the single owner of its facts:

| Level | Location | Owns | Applies to |
|---|---|---|---|
| **A — Universal** | `tasks/AGENTS.md` + `tasks/_TEMPLATE.md` | the rules, the workflow, the spec template | every version |
| **B — Set** | `tasks/v0.beta.N/` (`README.md` · `plan.md` · `status.md`) | this batch's feature list, DAG, reasoning, progress | one version |
| **C — Feature** | `tasks/v0.beta.N/specs/<slug>.md` | one feature's intent | one feature |

```text
tasks/
├── AGENTS.md          ← level A: universal rules (this file)
├── _TEMPLATE.md       ← level A: spec mold (shared by all sets)
└── v0.beta.N/
    ├── README.md      ← level B: set index — umbrella name, feature table, DAG
    ├── plan.md        ← level B: living reasoning scratchpad (mutable)
    ├── status.md      ← level B: progress rollup (derived, do not hand-author)
    └── specs/
        └── <slug>.md  ← level C: one feature spec (authored, immutable)
```

## The three layers (D1)

1. **Permanent contracts** — co-located `AGENTS.md`/`docs.md`/`examples.md`. What
   the code *is*. Updated in the same commit as the code.
2. **Specs / roadmap** — this folder. What we *will* build.
3. **Execution** — `.tasks/<slug>/` worktrees + their `TODO.md`. *Doing it now*.

## One fact, one source — authored vs derived (D2)

Each fact lives in exactly **one** file; everything else **links or derives**, it
never copies. Concretely:

- **Authored sources** (`specs/*.md`) — the only place a feature's intent, deps,
  files, steps and scenarios are written.
- **Views / derived** (`README.md`, `status.md`) — built *from* the sources:
  - the README **DAG derives from** each spec's `Depends on`;
  - the README feature table **does not carry a live Status column** — it links
    to `status.md`;
  - `status.md` is a **rollup** of `git` + each `.tasks/<slug>/TODO.md` — mark it
    *generated, do not edit by hand*.

A fact that appears in two authored places **will** drift. Don't author it twice.

## Derivable slug (D3)

One slug propagates to every path — compute it, never search:

```text
slug = "wat-features"
  ├─ spec     → tasks/v0.beta.N/specs/wat-features.md
  ├─ branch   → task/wat-features
  └─ worktree → .tasks/wat-features/
```

## State trust order (D4)

When state conflicts, trust in this order:

```text
status.md  >  .tasks/<slug>/TODO.md  >  spec header Status  >  plan.md
```

The spec's `Status` is coarse (`pending`/`done`); live state lives only in
`TODO.md` (per task) and `status.md` (rolled up).

## Neutrality (D5)

Content (specs, template, scripts) lives in neutral, version-controlled folders so
any agent — not just one vendor — can use it. `AGENTS.md` is the open portability
anchor. Tool-specific dirs (`.claude/`, `.cursor/`, …) may hold *triggers* that
point to this content, but **never a source of truth**.

## Independence & history (D9)

- The unit of independence is the **task**. Default `Depends on: nothing`; the DAG
  only draws the rare real dependency. Keep the DAG near-empty — that means
  everything parallelizes.
- A **set** is a batch label, not a phase. When all its tasks land, the set
  **freezes as immutable history**; open a new `v0.beta.(N+1)` for fresh work.
- Past sets are navigable institutional memory: each is a closed namespace, so old
  status never rots the present.

## Spec format (D6)

Every spec is written from [`_TEMPLATE.md`](_TEMPLATE.md): a front-loaded header of
closed fields, then grammar, examples, phased steps with checkboxes, and test
scenarios that serve as acceptance criteria. The header lets an agent decide
whether to pick the task — and what it will touch — in ~10 lines, without reading
the prose.

## Workflow (D7)

Five phases across the three layers; each names what is written and its exit gate.

1. **Open a set** — create `tasks/v0.beta.N/` with `README.md` (umbrella name,
   empty DAG, table skeleton) and `plan.md`. *Gate:* skeleton exists.
2. **Define a feature** — capture the idea in `plan.md`; once agreed, write
   `specs/<slug>.md` from the template and add it to the README. *Gate:* spec
   written (`Status: pending`), README updated. The spec is now immutable.
3. **Start execution** — `git worktree add .tasks/<slug> -b task/<slug> feat`
   (branch off `feat`, never `main`); seed `.tasks/<slug>/TODO.md` from the spec's
   steps. *Gate:* worktree + TODO exist.
4. **Work** — edit code **inside the worktree only**; tick `TODO.md` as steps land.
   *Gate:* all steps done, test scenarios pass.
5. **Complete & archive** — commit (pre-commit runs `zig fmt` + `zig build` +
   `zig build test`, no `--no-verify`); integrate into `feat` over SSH via a
   throwaway `.tasks/_integrate-<slug>` worktree; update `status.md`; update every
   doc listed in the spec's `Touches docs:`; remove worktrees and prune. *Gate:*
   merged into `feat`, docs synced, worktrees gone. The spec stays as history.

See [`../AGENTS.md`](../AGENTS.md) → "Parallel tasks (git worktrees)" for the exact
git commands and integration/conflict rules.
