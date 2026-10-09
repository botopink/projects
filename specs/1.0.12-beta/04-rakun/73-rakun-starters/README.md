# Front 73 — Starters and example projects: the consumer surface

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

## Open

### Step 1 — The starters

- [ ] `starters/rakun-starter-app/{botopink.json,src/root.bp}` exist; `starter_manifest_test.bp` asserts the nine starters and their `brings` lists
- [ ] `starters/rakun-starter-test/botopink.json` names `rakun-starter` and `rakun-test` only; the lint's `allowList()` and its two asserting cells gone (no out-of-repo dependency allowed); the workflow's onze checkout gone; `grep -rn onze repository/rakun/starters` answers nothing
- [ ] `starters/README.md` lists nine, states the workspace rule (03r-r)

### Step 2 — The examples run

- [ ] `examples/rakun`: `botopink build --target erlang --out out` then `botopink run` headless exits 0, prints the banner — a cell in `modules/rakun/test/starter_manifest_test.bp` (renamed `consumer_surface_test.bp`) driving the compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`, as `rakun-cli`'s tests do
- [ ] the same for `examples/rakun-container` and `examples/rakun-ssr` (ssr answers `/` over a loopback socket with its renderer's text)
- [ ] if any of the three fails on a sidecar load, the milestone's `language-gaps.md` toolchain row re-pinned with the measured text, box open naming it
- [ ] each example has a `README.md` (what it shows, how to run it) — PK-2

### Step 3 — The seven (03r-af)

- [ ] under (a): `modules/README.md` § Examples lists the three, says the seven were retired; the closed 1.0.10 map [`03-rakun/test-snap-examples.md`](../../../1.0.10-beta/03-rakun/test-snap-examples.md) referenced from no live document
- [ ] under (b)/(c): one front directory per example opened by the maintainer, each after the member fronts it exercises; nothing here

**Gate:** standard (fronts.md § Gate) + `zig build test-libs -- --target erlang --lib rakun` lists
the nine starter cells and three example cells green; `botopink format --check` clean in
`starters/**`, `examples/**`; `modules/README.md`, `starters/README.md`, `repository/rakun/README.md` updated.

Blast radius: deleting the onze edge affects no consumer in the repository. `run` cells add ~3 s
each to the core's suite (under its 60 s budget); if over, they move to a `consumer_surface` member
of their own, named here.
