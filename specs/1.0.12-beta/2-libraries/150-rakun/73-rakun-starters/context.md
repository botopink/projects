# Front 73 — Starters and example projects: the consumer surface

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s9 · s2 → 150 s9 · s3 → 150 s9. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — one starter missing, one names onze modules (decision 113), the three
examples are build-only cells whose `botopink run` was never re-measured since the compiler ships
sidecars · **State:** not started
**Depends on:** 128 (rewrites every starter's manifest; `rakun-starter` brings `rakun` only once
logging is in the core) — no other rakun front: group A (decision 189) · 03r-af (step 3) · 03r-r
(confirmation) · decision 344 / PK-7 (a git dependency's `subdir` — the out-of-tree install;
`02/98` step 4 and `01-compiler/26` step 6)
**Owns:** `repository/rakun/starters/**` · `repository/rakun/examples/**` · `modules/README.md`
§ starters and examples · `repository/rakun/README.md` § Getting started ·
`modules/rakun/test/starter_manifest_test.bp` (carve-out from 04) · the "Checkout onze" step of
`repository/rakun/.github/workflows/test.yml` (carve-out: exists only for the starter's onze edge)
**Does not touch:** `modules/**` otherwise · `repository/onze/**`

## Goal

Nine starters, none naming a module outside rakun; the three examples run under `botopink run` in a
cell (or the language-gaps toolchain row re-pinned with the measured failure), each with a
`README.md`; the seven planned examples settled by 03r-af.

## Mechanism

- **Onze edge.** `starters/rakun-starter-test/botopink.json` names `onze`, `onze-test` by path
  (`../../../onze/modules/{onze,onze-test}`); the starter lint allow-lists them
  (`starter_manifest_test.bp` `allowList()`, asserted as `"onze,onze-test"`); `src/root.bp`'s doc
  names them; CI checks out `botopink/onze` for them. Decision 113 forbids the edge; the mocking it
  pointed at is std's `testing.mocks`. All four go; `root.bp` re-exports `rakun-test` only.
- **`rakun-starter-app`**: manifest + `root.bp` (`rakun-starter-web`, `rakun-app`, `rakun-cache`);
  `starter_manifest_test.bp` gains one row.
- **`run` re-measure.** At 1.0.10 front 04's close, `botopink run` died with `undef
  rakun_runtime:serve/2` (`examples/rakun`) and `undef rakun_file_router:register_layout/2`
  (`examples/rakun-ssr`); the compiler now ships `out/erl/*.erl` and compiles them under `run`. Cell:
  build, run headless with `rakun.main`'s `headless: true`, `keepAlive: false` (299: the key is the
  field's name; `keep-alive` today), assert exit 0 and banner.
  Still failing → failure text to the milestone's `language-gaps.md` toolchain row, box open naming
  it, cell not written (no skip).
