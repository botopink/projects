# Front 50 — onze CLI tail: `onze dev`, `prerender/`, the signal, one defaults table, the bundler tail

**Priority:** high — `onze dev` is the one of the four commands that does not exist; the scaffold
a new user runs first prints "not available yet" · **State:** not started (step 7: the defaults
record already drives `--help`)
**Depends on:** `03-bundled-libs/102` step 3's `scan.bp` and `chunk.bp` commits, landed before
this front opens (decision 188) · maintainer `50-b` (step 2), `std-d` (steps 4, 7), `50-a` as
amended · `07-onze/71` step 2 (`bin/onze`, step 5) · `05-jhonstart/27` step 1
(`applyTransition`, step 6 — 27 does not wait on this front, decision 189) · `07-onze/49` step 6
(the `onze-test` group files)
**Owns:** `repository/onze/modules/onze-cli/**`, `modules/onze-bundler/**`,
`examples/scaffold/**`, `modules/onze-test/src/{cli,bundler}.bp` · this directory
**Does not touch:** `modules/onze/**`, `modules/onze-server/**` (49) · `modules/onze-{assets,og}/**`
(51) · `modules/onze-release/**` (71 — step 5 calls its script) · `examples/blog/**` (53) ·
`onze-cli/src/scan.bp`'s segment walk and `onze-bundler/src/chunk.bp`'s segment read (`03/102`,
its commits land first) · after landing, what `08-bpp` adds: `scan.bp`'s extension and exports
(117), then the commands, build steps and scaffold of 124

## Goal

`onze dev` serves and rebuilds the scaffold; `onze build` writes `prerender/`; `onze start` runs
71's `bin/onze` and a `SIGTERM` reaches the node; `create`'s defaults exist once; the bundler
cuts a chunk per route, honours `assetPrefix` and both `<Script>` callbacks; the CLI and the
bundler read std's `Json` methods.

## Mechanism

- **Today.** `main.bp` answers `dev` with "onze dev: not available yet" (exit 2); there is no
  `dev.bp`; `onze-bundler/src/rebuild.bp` (the invalidation set of a changed file) has no caller.
  `build.bp` does not drive rakun 60's `static_gen.bp`. `start.bp` waits on `process.run`.
  `build.bp` and `info.bp` declare a local `membersOf`, `onze-bundler/src/entry.bp` an `itemsOf`
  (std's `Json.members()` / `.items()`). `create.bp`'s `createDefaults()` feeds the option
  parser and `createHelp()` (`--help`, snapshot `create/help_the_flag_table_from_the_one_defaults_record.snap`);
  `docs.md` holds no copy of the table yet. `resolve.bp`'s cases live in `scan_test` /
  `create_test` (no `resolve_test.bp`). The generated entry imports every client component, so
  every island lands in `shared`; no `assetPrefix`; `<Script>` has `onLoad` only.
- **`dev` under 50-b (a)**: a file watcher over the project (std `io.fs.walk` polled, or the
  host's watcher through one cell) runs `build` on a change and restarts the node `start`
  spawned; the previous build keeps serving until the new one is ready, and a compile error
  prints the compiler's message and leaves the previous node up. `rebuild.bp` narrows the
  recompile set. "`build && start` serves what `dev` served" holds by construction.
- **`prerender/`**: `build.bp` calls rakun 60's generator for every static route the scan
  classifies, writing `<outDir>/prerender/<route>/index.html`; `start` serves them before the
  renderer (rakun 60's serving rule).
- **The signal, under `std-d` (b)**: `start` execs 71's `bin/onze` (PID 1 is the VM); the CLI is
  gone by the time a signal arrives. Under (a) the CLI forwards it.
- **Lazy starters**: the entry registers, per route pattern, a loader that imports that route's
  chunk (`registerRouteStarters(pattern, load)`); `chunk.bp` cuts one chunk per route group plus
  `shared`; the manifest's `R` record already maps a pattern to its chunk.

## Open

### Step 1 — consume std (97)

- [ ] `grep -n "fn membersOf\|fn itemsOf" modules/onze-cli/src modules/onze-bundler/src` is
      empty; every suite unchanged in count

### Step 2 — `onze dev` (50-b (a))

- [ ] `onze dev` on `examples/scaffold` serves `/` and prints `http://localhost:3000`
      (`dev_test.bp`, over a real socket like `start_test.bp`)
- [ ] editing `app/page.bp` changes the next response after the rebuild; adding
      `app/about/page.bp` makes `/about` resolve (the manifest and `onze_routes.bp` regenerated)
- [ ] a compile error prints the compiler's own message and the previous build keeps answering
- [ ] `-p` does not write `onze.json`; `-H <addr>` binds that address (`reference-holes.md` § 29)
- [ ] `main.bp` dispatches `dev` to `dev.bp`; the "not available yet" text is gone

### Step 3 — `prerender/`

- [ ] `onze build` on the blog writes `prerender/blog/<slug>/index.html` for each static post and
      nothing for a dynamic route; the five output entries of 1.0.10's step 7 exist
- [ ] `start` serves a prerendered route without invoking the page (53 step 2 asserts the counter)

### Step 4 — the signal (`std-d`)

- [ ] under (b): `start` execs `bin/onze` and is not in the process tree when the node runs;
      `start_test.bp` sends `SIGTERM` to the node and observes the drain order 71 pins
- [ ] under (a): `start` forwards `SIGTERM` through `process.forwardSignals`

### Step 5 — `start` calls `bin/onze`; `build` passes `includeErts` (after 71 step 2)

- [ ] `start.bp` runs `<outDir>/release/bin/onze` when it exists and refuses otherwise naming it
      — one start path
- [ ] `build.bp` passes `ReleaseSpec.includeErts` through to 71's `assembleRelease`

### Step 6 — the bundler tail (68)

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

- [ ] `docs.md`'s `create` table is `createHelp()`'s output, compared by a `check-docs` cell (the
      `--help` and parser halves already read `createDefaults()`); `create_test.bp` asserts the
      three agree
- [ ] `onze create --example scaffold` copies `examples/scaffold`; under `std-d` (b) `create`
      without `--yes` is refused listing the flags; under (a) it prompts through `readLine`
- [ ] `test/resolve_test.bp` exists with `resolve.bp`'s cases moved from `scan_test` / `create_test`
      (counts preserved in total)
- [ ] `examples/scaffold/README.md` names `create`'s table and `NEXTJS-DOCS.md` § 29

### Step 8 — § 50 of the snapshot map

→ 20-snap (front 135) step 5

### Step 9 — the `@/` alias goes (decision 218, handed by `01-compiler/129`)

An application imports its own modules by path in braces (`import {lib.db.findPost};`, decision
206); staging no longer resolves `from "@/…"`, which is `module-import-with-from` like any other.
Today `onze-bundler`'s `AliasMap` resolves `@/…` (`graph.bp` `edgesOf` → `resolveAlias`,
`rebuild.bp` `BundleSetup.aliases`), `src/fixture.bp` and `graph_test` / `rebuild_test` import
through it, `examples/scaffold/botopink.json` declares `"alias"` and `docs.md` documents it.

- [ ] `AliasMap` and `resolveAlias` are gone; the bundler's tests and `fixture.bp` import by path
- [ ] `examples/scaffold/botopink.json` has no `"alias"` key; `docs.md` names the brace form, not
      the alias (the blog's half is 53 step 1)
- [ ] `grep -rn '"@/' repository/onze/modules repository/onze/examples/scaffold --include=*.bp` is empty
- [ ] `onze-test`'s `assertAlias` (`src/core.bp`, its two `test/helpers_test.bp` cases and their
      `.snap`) is deleted — 49's files, one carve-out commit

## Notes

- Step 6 changes the chunk plan: the blog's `assets_test` and 53's script-tag rows re-assert the
  chunk names.
- `dev` restarts rather than hot-loads (50-b (a)); Fast Refresh is a stated non-goal
  (`reference-holes.md` § 29). The bundler's `importsOf` stays a text scan (lg2-s is the
  compiler's row).

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-cli` 31+ and `onze-bundler` 42+ on every target its manifest
      declares; `scaffold` green
