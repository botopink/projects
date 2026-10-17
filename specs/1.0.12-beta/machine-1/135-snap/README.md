# Front 135 — snap: the second test layer, re-evaluated case by case (coordination)

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Repository:** none of its own — each step runs in the front that owns its repository (144 B-27, 150 s24, 150 s45, 150 s55, 150 s68), with that front's worktree and Conformance step
**Model:** haiku — coordination only: the order of the snapshot steps (`AGENTS.md` § Which model a thread runs on)
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** the order of the snapshot steps; the evaluation in [`20-snap/README.md`](20-snap/context.md).
**Depends on:** 135 s0 (done, 391).

Each step writes through the `snap` library in its own repository: s1 std → 144 B-27; s2 rakun-test → 150 s24;
s3 jhonstart → 150 s45; s4 emilia-test → 150 s55 (after 150 s52–s54); s5 onze's E2E runner → 150 s68 (before 150 s67's steps 2–6). Steps 1–4 follow the owning fronts' other steps, one library at a time, last; the replaced
steps (97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7, 71 s6) have no text left of their own.
