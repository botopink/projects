# Template — a milestone and its fronts

A milestone is a directory of **fronts**. A front is the unit of work: one worktree, one branch,
one owner, one `todo.md`. Fronts are cut so that several can run at the same time, and the cut is
by **ownership of files and of snapshot directories** — not by topic.

Copy the skeletons below; delete what does not apply. English, in every file.

```
specs/<version>/
├── overview.md                     what the milestone is, the fronts, the order
├── fronts.md                       ownership + conflict matrix (who may run together)
├── <NN>-<front-name>/
│   ├── README.md                   the front: problem, steps, acceptance, ownership, gate
│   └── <topic>.md                  the deep dives (mechanism, blast radius, options, evidence)
└── …
```

Why a directory per front: the front is what becomes `.tasks/<front-name>` and `fix/<front-name>`,
so the document a worker opens is the document that owns their branch. A deep dive that would bury
the steps goes in its own file next to the README.

---

## `overview.md`

```markdown
# Specs — <version>

<2–4 lines: what this milestone is about and what it inherits from the previous one.>

| Front | Priority | What |
|---|---|---|
| [`<NN>-<name>/`](./<NN>-<name>/README.md) | critical/high/medium/low | <one line> |

## Order

```
<front> ──┐  (runs alone: <why>)
<front> ──┤
          └──► <front> · <front> · <front>   (N in parallel)
```

<One paragraph: why the first front is first — in terms of what the others cannot verify
without it, not in terms of importance.>

## Rules carried forward

<Rules earned in previous milestones that still bind — e.g. "a backend builds a model, an
emitter renders it"; "the gate runs from a cold runtime cache"; "a snapshot is evidence, not a
baseline".>
```

## `fronts.md`

The parallelism plan. Two fronts may run at the same time only when they share **no source file
and no snapshot directory** — a shared snapshot directory is the usual trap, because one change
re-records the whole directory and the two fronts then fight over every file in it.

```markdown
## Ownership

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **F1 <name>** | <paths> | <dir> (<count>) | <which steps> |

## Conflict matrix

|  | F1 | F2 | … |
|---|---|---|---|
| **F1** | — | yes | no¹ |

<Numbered notes explaining every "no": which file or directory they share, and whether the
answer is "sequence them" or "merge them into one front".>

## Order

<The diagram from overview.md, plus which fronts are the critical path because they run alone.>
```

---

## `<NN>-<front-name>/README.md`

```markdown
# Front <NN> — <name>

**Priority:** <critical | high | medium | low> — <why, in one clause>
**Depends on:** <front(s) or none>
**Owns:** <source paths> · <snapshot directories>
**Does not touch:** <the paths other fronts own — name them, so a worker knows to stop and report>

---

## Problem

<What is wrong, stated as behaviour a reader can reproduce. Command, output, exit code.>

## Current state

<Measured, not remembered: counts, which fixtures, which libraries. Say how it was measured
(`scripts/…`, a suite run from a cold cache, running the emitted code) so the next person can
repeat it.>

## Mechanism

<Why it happens: the call path, the deciding line (`file:line`), and what that line decides.
If the answer is long, this becomes `<topic>.md` and this section is its summary plus a link.>

## Steps

### Step 1 — <what>

<What to change, and the shape of the change. Where there is a choice, state the options and
recommend one with its trade-off.>

**Acceptance:**
- [ ] <objective condition — a command and its expected result, not "works">
- [ ] <the regression test that would have caught it>

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] <the front's own check: a validator run, a library that must compile, snapshots
      byte-identical for a refactor front>
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/<front-name>`; no push, no merge — landing is the maintainer's step

## Blast radius

<What else moves when this lands: how many snapshots, which libraries start or stop compiling,
which other front has to re-record. A front that reds real code needs a migration plan here,
not just a fix.>

## Notes

<Decisions taken and why; what was deliberately not done and who owns it.>
```

## `<NN>-<front-name>/<topic>.md`

One per deep dive. The README stays readable; the analysis lives here. Typical topics:

| File | Holds |
|---|---|
| `mechanism.md` | the call path traced function by function, with `file:line` at HEAD |
| `surface.md` | the full table of what works and what does not (per method, per backend, per fixture) |
| `options.md` | fix options with cost, risk and interaction, ending in a recommendation |
| `blast-radius.md` | what breaks when the permissive behaviour stops being permissive |
| `evidence.md` | quoted output, minimal reproductions, and how each was produced |

---

## Working a front

1. `git worktree add .tasks/<front-name> -b fix/<front-name>` from the submodule that owns the
   code; write `todo.md` at the worktree root from the front's README (steps as a checklist,
   owned and forbidden paths, the gate). `todo.md` is git-ignored and never committed.
2. Work only inside the worktree, only on owned files. **A front that needs a file it does not
   own stops and reports it** — that is how a mirrored bug is found instead of papered over.
3. Verify by running, not by reading: execute the emitted code, drive the server, run the CLI.
   Re-record a snapshot only for a value that was verified.
4. Land: merge into `feat`, suite green in the main checkout, push, submodule bump in the meta
   repo, then delete the worktree and the branch.

## Conventions

- Specs describe **current state and remaining work**. No status narratives, no commit hashes,
  no superseded approaches — when a front lands, its README becomes the record of what shipped
  and what it left, and the leftovers move to the next milestone.
- Cite `file:line` at HEAD and say when a number was measured, because both drift.
- A table beats a paragraph. A reproduction beats a description.
