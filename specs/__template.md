# Template — a milestone and its fronts

A milestone is a directory of **fronts**. A front is the unit of work: one worktree, one branch,
one owner, one `todo.md`. Fronts are cut so that several can run at the same time, and the cut is
by **ownership of files and of snapshot directories** — not by topic.

Copy the skeletons below; delete what does not apply. English, in every file.

```
specs/<version>/
├── overview.md                     what the milestone is, the fronts, the order
├── fronts.md                       ownership + conflict matrix (who may run together)
├── status.md                       the living checklist: done · in analysis · pending · open, with a rough %
├── decisions-pending.md            questions only the maintainer can answer, in the Measured/Options/Recommendation/Blocks shape
├── decisions-taken.md              the answers, numbered, never renumbered — what the fronts implement against
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

## `status.md`

The one file that is **always up to date**. It is a checklist, not a narrative: every front and
every carried item appears once, under exactly one of four headings, with a rough percentage at
the top. Update it in the same commit as the work it reflects — a merge, a step ticked in a
`todo.md`, a front opened, analysed or deferred. A reader who opens only this file must know where
the milestone stands.

```markdown
# Status — <version>

**Updated:** <YYYY-MM-DD> · **Progress:** ~<N> % (<done> of <total> fronts landed; fronts in
analysis count for their ticked steps)

## Done
- [x] `<NN>-<front>` — <what landed, one clause>

## In analysis
- [ ] `<NN>-<front>` — <step k of n> · worktree `.tasks/<name>` · <what is being worked, one clause>

## Pending
- [ ] `<NN>-<front>` — ready to start · waiting on <front, decision or maintainer step>

## Open
- [ ] `<NN>-<front>` — <priority> · not started, no owner · blocked on <front or nothing>

## Deferred out of this milestone
- `<NN>-<front>` → <where it went and why, one clause>
```

- **Done** landed on `feat`. **In analysis** has an owner and a worktree and is being worked or
  measured right now. **Pending** is specified and ready but waits on something named (a blocking
  front, a maintainer decision, a merge). **Open** has no owner yet.
- The percentage is a rough ratio, not a measurement — do not spend time making it exact; do
  spend the time keeping the four lists right.
- Order inside each list follows `overview.md` (most blocking first).
- A line moves between lists as the work moves; the percentage moves with it.
- `status.md` is the only spec file allowed to carry status; every other file keeps describing
  current state and remaining work (see *Conventions*).

## `decisions-pending.md` and `decisions-taken.md`

Every milestone has both, from day one, even when the pending file says *None open*. A front that
meets a question it cannot answer from the code **writes it in `decisions-pending.md` rather than
guessing**; the maintainer answers; the answer moves to `decisions-taken.md` with its evidence and
the pending file's header says so. Numbers are allocated when a question is written and are
**never reused or renumbered**, across milestones as well as within one — the next milestone
continues where the previous record stopped, so that "decision 67" means the same thing in every
directory under `specs/`.

```markdown
# Decisions the maintainer owes — <version>

<Header: how many are open, which fronts raised them, what the next free number is.>

## <N>. <question, as a sentence>

**Raised by:** `<NN>-<front>` step <k>, <date>
**Measured.** <What was observed, with the command or program that produced it and the file or
commit that can be re-read.>
**Options.** <Each one stated so that choosing between them is possible without reading the code.>
**Recommendation.** <One, argued — a question with no recommendation is a question the front did
not finish thinking about. The default is the most restrictive behaviour, and no configuration
that bypasses it.>
**Blocks.** <The step, front or landed work that waits on the answer.>
```

```markdown
# Decisions taken — <version>

<Header: where the numbering continues from; the standing principles inherited by reference.>

| # | Question | Answer |
|---|---|---|
| [<N>](#n-slug) | <question, short> | <answer, short> |

## <N>. <title>

**Decided <date> by the maintainer:** <the answer, quoted where the maintainer's words matter>.
<What prompted it; what it means for the fronts; what it amends (link the earlier number).>
```

- A decision is amended, never edited: the new number says what it changes in the old one, and the
  old one gets a one-line pointer.
- `status.md` counts an open question as a blocker of the step it names.

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
  and what it left, and the leftovers move to the next milestone. The one exception is
  `status.md`, the milestone's living checklist (done · in analysis · pending · open · rough %), which is
  updated in the same commit as the work it reflects.
- Cite `file:line` at HEAD and say when a number was measured, because both drift.
- A table beats a paragraph. A reproduction beats a description.
