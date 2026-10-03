# Front 73 — Starters and example projects: the consumer surface

**Priority:** medium — one starter is missing, one names onze modules (decision 113), and the three
examples are build-only cells whose `botopink run` has never been re-measured since the compiler
started shipping sidecars · **State:** not started
**Depends on:** 128 (it rewrites every starter's manifest; `rakun-starter` brings `rakun` only once
logging is in the core) — no other rakun front: group A (decision 189) · 03r-af (step 3) · 03r-r
(confirmation) · lg2-v / PK-7 (a git dependency with a subdirectory — the out-of-tree install; stays
open, owned by the compiler)
**Owns:** `repository/rakun/starters/**` · `repository/rakun/examples/**` · `modules/README.md`
§ starters and examples · `repository/rakun/README.md` § Getting started ·
`modules/rakun/test/starter_manifest_test.bp` (carve-out from 04) · the "Checkout onze" step of
`repository/rakun/.github/workflows/test.yml` (carve-out: it exists only for the starter's onze edge)
**Does not touch:** `modules/**` otherwise · `repository/onze/**`

## Goal

Nine starters, none naming a module outside rakun; the three examples run under `botopink run` in a
cell (or the language-gaps toolchain row is re-pinned with the measured failure), each with a
`README.md`; the seven planned examples settled by 03r-af.

## Mechanism

- **The onze edge.** `starters/rakun-starter-test/botopink.json` names `onze` and `onze-test` by path
  (`../../../onze/modules/{onze,onze-test}`), the starter lint allow-lists them
  (`starter_manifest_test.bp` `allowList()`, asserted as `"onze,onze-test"`), `src/root.bp`'s doc
  names them, and the CI workflow checks out `botopink/onze` for them. Decision 113 forbids the edge
  and the mocking it pointed at is std's `testing.mocks`; all four go, and `root.bp` re-exports
  `rakun-test` only.
- **`rakun-starter-app`** is a manifest and a `root.bp` (`rakun-starter-web`, `rakun-app`,
  `rakun-cache`); `starter_manifest_test.bp` gains one row.
- **The `run` re-measure.** When 1.0.10's front 04 closed, `botopink run` died with `undef
  rakun_runtime:serve/2` (`examples/rakun`) and `undef rakun_file_router:register_layout/2`
  (`examples/rakun-ssr`); the compiler has since shipped `out/erl/*.erl` and compiles them under
  `run`. The cell builds, runs headless with `rakun.main.headless=true keep-alive=false`, asserts exit
  0 and the banner. If it still fails, the failure text goes to the milestone's `language-gaps.md`
  toolchain row and the box stays open naming it — the cell is then not written (no skip).

## Open

### Step 1 — The starters

- [ ] `starters/rakun-starter-app/{botopink.json,src/root.bp}` exist; `starter_manifest_test.bp` asserts the nine starters and their `brings` lists
- [ ] `starters/rakun-starter-test/botopink.json` names `rakun-starter` and `rakun-test` only; the lint's `allowList()` and its two asserting cells are gone (no out-of-repo dependency is allowed); the workflow's onze checkout is gone; `grep -rn onze repository/rakun/starters` answers nothing
- [ ] `starters/README.md` lists nine and states the workspace rule (03r-r)

### Step 2 — The examples run

- [ ] `examples/rakun`: `botopink build --target erlang --out out` then `botopink run` headless exits 0 and prints the banner — a cell in `modules/rakun/test/starter_manifest_test.bp` (renamed `consumer_surface_test.bp`) driving the compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`, as `rakun-cli`'s tests do
- [ ] the same for `examples/rakun-container` and `examples/rakun-ssr` (the ssr one answers `/` over a loopback socket with the text its renderer writes)
- [ ] if any of the three fails on a sidecar load, the milestone's `language-gaps.md` toolchain row is re-pinned with the measured text and the box stays open naming it
- [ ] each example has a `README.md` (what it shows, how to run it) — PK-2

### Step 3 — The seven (03r-af)

- [ ] under (a): `modules/README.md` § Examples lists the three and says the seven were retired; the closed 1.0.10 map [`03-rakun/test-snap-examples.md`](../../../1.0.10-beta/03-rakun/test-snap-examples.md) is referenced from no live document
- [ ] under (b)/(c): one front directory per example is opened by the maintainer, each after the member fronts it exercises; nothing here

**Gate:** standard (fronts.md § Gate) + `zig build test-libs -- --target erlang --lib rakun` lists the
nine starter cells and the three example cells green; `botopink format --check` clean in
`starters/**` and `examples/**`; `modules/README.md`, `starters/README.md`, `repository/rakun/README.md`
updated.

Blast radius: deleting the onze edge affects no consumer in the repository. The `run` cells add ~3 s
each to the core's suite — under its 60 s budget; if they push it over, they move to a
`consumer_surface` member of their own, named here.
