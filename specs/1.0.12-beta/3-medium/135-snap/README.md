# Front 135 — snap: the second test layer, re-evaluated case by case (coordination)

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** the order of the snapshot steps; the evaluation in [`20-snap/README.md`](20-snap/context.md).
**Depends on:** 135 s0 (done, 391).

Each step writes through the `snap` library in its own repository: s1 std → 144 B-27; s2 rakun-test → 150 s24;
s3 jhonstart → 149 s10; s4 emilia-test → 154 s4 (after 154 s1–s3); s5 onze's E2E runner → 162 s10 (before 162
s9's steps 2–6). Steps 1–4 follow the owning fronts' other steps, one library at a time, last; the replaced
steps (97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7, 71 s6) have no text left of their own.
