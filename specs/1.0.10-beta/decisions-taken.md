# Decisions taken — 1.0.10-beta

Answered by the maintainer, kept here as the record the fronts implement against. The numbering
continues from [1.0.5-beta's record](../1.0.5-beta/decisions-taken.md), which stopped at 67 — a
number is never reused or renumbered across milestones, so a decision cited anywhere under `specs/`
is one decision. Questions are raised in [`decisions-pending.md`](./decisions-pending.md) and move
here when answered.

**Inherited by reference, not copied.** The 1.0.5 record stays where it is; four of its decisions
govern this milestone as standing principles and are cited by number throughout:
[67](../1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it)
(the most restrictive behaviour, and no configuration that bypasses it — every option list below is
written against it),
[62](../1.0.5-beta/decisions-taken.md#62-the-order-of-what-is-left-in-the-milestone) (the order of
what was left, now `00-compiler-carry-over`'s order),
[63](../1.0.5-beta/decisions-taken.md#63-an-index-answers-t-and-an-absent-key-fails-rather-than-answering)
(an index is a method call and an absent key fails — item C-02) and
[66](../1.0.5-beta/decisions-taken.md#66-format---check-looks-at-the-whole-project--and-something-has-to-call-it)
(`format --check` over the whole project — item C-11).

| # | Question | Answer |
|---|---|---|
| [68](#68-one-milestone-the-109-numbers-kept-the-drafts-deleted) | Four spec directories or one? | One — `1.0.10-beta`; 1.0.9's front numbers are kept as directory names; `1.0.6-beta` … `1.0.9-beta` are deleted once the copy is verified |
| [69](#69-every-milestone-carries-a-living-statusmd) | Where does status live? | In `status.md`, and only there — done · in analysis · pending · open, with a rough percentage |
| [70](#70-every-milestone-carries-decisions-pendingmd-and-decisions-takenmd) | Where do questions go? | `decisions-pending.md` → `decisions-taken.md`, in every milestone, numbering continued |

## 68. One milestone, the 1.0.9 numbers kept, the drafts deleted

**Decided 2026-09-20 by the maintainer.** The open half of 1.0.5-beta and the whole of 1.0.9-beta
(which had already merged 1.0.6, 1.0.7 and 1.0.8) are one milestone, `1.0.10-beta`, ordered by what
blocks what: std/asserts/`@src()` first, the package restructure second, the four libraries after,
the compiler carry-over beside. Nothing is dropped — the proof is [`unification.md`](./unification.md)
and the per-library `unification.md` files — and a 1.0.9 front keeps its number as its directory
name under the library that owns it (`03-rakun/23-rakun-ssr-pipeline/` is still front 23), so every
cross-reference written in 1.0.9 still resolves.

The four absorbed directories are **deleted** at the end of the consolidation, after a
file-by-file check that every file has a copy here — the maintainer's words: *"pode deletar as
pastas 1.0.6 a 1.0.9 no final"*. Their mapping survives in `unification.md` and in
[`specs/1.0.5-beta/closure.md`](../1.0.5-beta/closure.md).

## 69. Every milestone carries a living `status.md`

**Decided 2026-09-20 by the maintainer:** a per-milestone `status.md`, in English, as a list —
*pending*, *in analysis*, *done*, *open* — with a percentage that need not be exact, always
updated. The convention is in [`specs/__template.md`](../__template.md) and the first instance is
[`status.md`](./status.md). It is the one spec file allowed to carry status; every other file keeps
describing current state and remaining work. It is updated in the same commit as the work it
reflects.

## 70. Every milestone carries `decisions-pending.md` and `decisions-taken.md`

**Decided 2026-09-20 by the maintainer:** the two files 1.0.5-beta kept are part of every
milestone's skeleton, from day one, and the template says so. Numbering continues across
milestones (this record starts at 68 because 1.0.5's stopped at 67). A front that cannot answer a
question from the code writes it in the pending file in the Measured / Options / Recommendation /
Blocks shape rather than guessing; the recommendation defaults to the stricter side (decision 67).
