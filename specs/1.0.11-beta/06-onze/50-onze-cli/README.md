# Front 50 — onze CLI tail (carries 68)

**Priority:** high — `onze dev` is the one of the four commands that does not exist; the
scaffold a new user runs first prints "not available yet"
**Depends on:** `02-std-and-packaging/97` (step 1) · maintainer: `50-b` (step 2's shape), `std-d`
(steps 4 and 7's shape), `50-a` as amended · `06-onze/71` step 2 (`bin/onze`, step 5) · the
`03-rakun` track's `22-rakun-file-routing` carrying 60 (`static_gen.bp` — landed; step 3 reads it)
· `04-jhonstart/27` (`applyTransition`, step 6) · `00-gate` for the `onze-cli erlang` ledger line
**Owns:** `repository/onze/modules/onze-cli/**`, `modules/onze-bundler/**`,
`examples/scaffold/**`, `modules/onze-test/src/{cli,bundler}.bp` · this directory
**Does not touch:** `modules/onze/**`, `modules/onze-server/**` (49) · `modules/onze-{assets,og}/**`
(51) · `modules/onze-release/**` (71 — step 5 calls its script; the script is 71's) ·
`examples/blog/**` (53) · `onze-cli/src/scan.bp:54` and `onze-bundler/src/chunk.bp:30-33`
(`07/102` — never at the same time) · `scripts/restricted-targets.txt` (`00-gate`)
**Carried from 1.0.10:** `50-onze-cli/README.md` § Step 6 (five boxes), § Step 7 box 1, § Step 8
boxes 1 and 4, § Definition of done boxes 1–3, § Where it stands (the tails: `--example`, the
prompts, `-H`, the docs table) · `68-onze-client-bundle/README.md` § Where it stands (route-level
splitting) · `unification.md` rows `assetPrefix`, `<Script onReady / onError>`, `-H` (copied as
`../reference-holes.md`) · `test-snap.md` § 50 (copied as [`test-snap.md`](./test-snap.md),
conditional on 53-b) · `02-packaging` step 3 (`examples/scaffold/README.md`)

---

## Problem

1. `onze dev` exits 2: `main.bp:101` "onze dev: not available yet - it serves the build `onze
   start` serves"; there is no `dev.bp`; `onze-bundler/src/rebuild.bp` (the invalidation set of a
   changed file) has no caller.
2. `onze build` writes no `prerender/`: rakun 60's `static_gen.bp` exists but `build.bp` does not
   drive it, so the "five entries" box and 53's prerender rows are open.
3. `onze start` waits on `process.run`; a `SIGTERM` to the CLI leaves the node running.
4. The defaults table exists three times (`create.bp`, `docs.md`, `--help`) and can drift; the
   DoD's `resolve_test.bp` does not exist (its cases live in `scan_test` / `create_test`).
5. The generated entry imports every client component, so every island's closure lands in the
   `shared` chunk (68's one open item); no `assetPrefix`; `<Script>` has `onLoad` only.
6. `build.bp:42`, `info.bp:11` and `onze-bundler/src/entry.bp:182` declare Json accessors std
   now provides; `entry.bp` also hand-rolls a `parseInt`.

## Current state

`onze-cli` 34 of 45 boxes; five suites on commonJS, several running the real `botopink check` /
`onze build` / `onze start`. `onze-bundler` 63 / 63, 42 tests on both rows. `examples/scaffold` is
`create`'s committed output.

## Mechanism

- **`dev` under 50-b (a)**: a file watcher over the project (std `io.fs.walk` polled, or the
  host's watcher through one cell) runs `build` on a change and restarts the node `start`
  spawned; the previous build keeps serving until the new one is ready, and a compile error
  prints the compiler's message and leaves the previous node up. `rebuild.bp` narrows the
  recompile set. "`build && start` serves what `dev` served" holds by construction.
- **`prerender/`**: `build.bp` calls rakun 60's generator for every static route the scan
  classifies, writing `<outDir>/prerender/<route>/index.html`; `start` serves them before the
  renderer (rakun 60's own serving rule).
- **The signal, under `std-d` (b)**: `start` execs 71's `bin/onze` (PID 1 is the VM) instead of
  wrapping it; the CLI process is gone by the time a signal arrives. Under (a) the CLI forwards
  it.
- **Lazy starters**: the entry registers, per route pattern, a loader that imports that route's
  chunk (`registerRouteStarters(pattern, load)`, 29-a); `chunk.bp` cuts one chunk per route
  group plus `shared`; the manifest's `R` record already maps a pattern to its chunk.

## Steps

### Step 1 — consume std (97)

**Acceptance:**
- [ ] `grep -n "fn membersOf\|fn itemsOf\|fn parseInt" modules/onze-cli/src modules/onze-bundler/src`
      is empty; every suite unchanged in count

### Step 2 — `onze dev` (50-b (a))

**Acceptance:**
- [ ] `onze dev` on `examples/scaffold` serves `/` and prints `http://localhost:3000`
      (`dev_test.bp`, over a real socket like `start_test.bp`)
- [ ] editing `app/page.bp` changes the next response after the rebuild; adding
      `app/about/page.bp` makes `/about` resolve (the manifest and `onze_routes.bp` regenerated)
- [ ] a compile error prints the compiler's own message and the previous build keeps answering
- [ ] `-p` does not write `onze.json`; `-H <addr>` binds that address (the `reference-holes.md`
      § 29 row)
- [ ] `main.bp` dispatches `dev` to `dev.bp`; the "not available yet" text is gone

### Step 3 — `prerender/`

**Acceptance:**
- [ ] `onze build` on the blog writes `prerender/blog/<slug>/index.html` for each static post and
      nothing for a dynamic route; the five output entries of 1.0.10's step 7 exist
- [ ] `start` serves a prerendered route without invoking the page (53 step 2 asserts the counter)

### Step 4 — the signal (`std-d`)

**Acceptance:**
- [ ] under (b): `start` execs `bin/onze` and is not in the process tree when the node runs;
      `start_test.bp` sends `SIGTERM` to the node and observes the drain order 71 pins
- [ ] under (a): `start` forwards `SIGTERM` through `process.forwardSignals`

### Step 5 — `start` calls `bin/onze`; `build` passes `includeErts` (50-a amended; 71's hand-offs)

**Acceptance:**
- [ ] `start.bp` runs `<outDir>/release/bin/onze` when it exists and refuses otherwise naming it
      — one start path (71 step 2's box "front 50's `start` calls this script and adds no second
      start path")
- [ ] `build.bp` passes `ReleaseSpec.includeErts` through to 71's `assembleRelease`

### Step 6 — the bundler tail (68)

**Acceptance:**
- [ ] the entry registers one loader per route pattern (`registerRouteStarters`) and imports no
      island statically; `chunk_test.bp`: an island used by one route is in that route's chunk,
      not in `shared`; the blog's `LikeButton` leaves `shared`
- [ ] `OnzeConfig.assetPrefix` (default `""`) is threaded through `ChunkRef.url` and the served
      prefixes; `manifest_test.bp` round-trips it on both rows; `config_test.bp` refuses a prefix
      that is not an absolute URL or `""`
- [ ] `<Script onReady / onError>`: `script_test.bp` asserts both callbacks scheduled per strategy
- [ ] the entry calls `jhonstart-link`'s `applyTransition` on a client navigation, supplying the
      four `DomOps`; `entry_test.bp` asserts the generated call

### Step 7 — the defaults table, `--example`, the prompts, `resolve_test.bp`

**Acceptance:**
- [ ] one `defaults()` record renders `docs.md`'s table (a `check-docs` cell compares), `--help`
      and `create`'s values; `create_test.bp` asserts the three agree
- [ ] `onze create --example scaffold` copies `examples/scaffold`; under `std-d` (b) `create`
      without `--yes` is refused listing the flags; under (a) it prompts through `readLine`
- [ ] `test/resolve_test.bp` exists with `resolve.bp`'s cases moved from `scan_test` / `create_test`
      (counts preserved in total)
- [ ] `examples/scaffold/README.md` names `create`'s table and `NEXTJS-DOCS.md` § 29

### Step 8 — conditional on `53-b` (b): record § 50 of the map

Under (a) or (c) — the recommendation — struck; `AGENTS.md` says the inline literals are the
evidence.

## Gate

- [ ] `zig build test-libs` — `onze-cli` at its count or above on commonJS (erlang per the
      ledger), `onze-bundler` 42+ on both rows, `scaffold` green
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/50-onze-cli`; no push, no merge — landing is the maintainer's step

## Blast radius

Step 6 changes the chunk plan: the blog's `assets_test` and 53's script-tag rows re-assert the
chunk names. Step 5 makes `start` depend on 71's script — sequenced after 71 step 2.

## Notes

- `dev` restarts rather than hot-loads (50-b (a)); Fast Refresh is a stated non-goal
  (`reference-holes.md` § 29).
- The bundler's `importsOf` stays a text scan (lg2-s is the compiler's row).
