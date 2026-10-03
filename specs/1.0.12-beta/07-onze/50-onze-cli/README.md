# Front 50 — onze CLI tail: `onze dev`, `prerender/`, the signal, one defaults table, the bundler tail

**Priority:** high — `onze dev` is the one missing command of four; a new user's first scaffold
run prints "not available yet" · **State:** not started (step 7: the defaults record already
drives `--help`)
**Depends on:** `03-bundled-libs/102` step 3's `scan.bp`, `chunk.bp` commits, before this opens
(decision 188) · maintainer `50-b` (step 2), `std-d` (steps 4, 7), `50-a` as amended ·
`07-onze/71` step 2 (`bin/onze`, step 5) · `05-jhonstart/27` step 1 (`applyTransition`, step 6 —
27 does not wait on this, decision 189) · `07-onze/49` step 6 (the `onze-test` group files)
**Owns:** `repository/onze/modules/onze-cli/**`, `modules/onze-bundler/**`,
`examples/scaffold/**`, `modules/onze-test/src/{cli,bundler}.bp` · this directory
**Does not touch:** `modules/onze/**`, `modules/onze-server/**` (49) · `modules/onze-{assets,og}/**`
(51) · `modules/onze-release/**` (71 — step 5 calls its script) · `examples/blog/**` (53) ·
`onze-cli/src/scan.bp`'s segment walk, `onze-bundler/src/chunk.bp`'s segment read (`03/102`,
lands first) · after landing, `08-bpp`'s: `scan.bp`'s extension and exports (117), then 124's
commands, build steps, scaffold

## Goal

`onze dev` serves and rebuilds the scaffold; `onze build` writes `prerender/`; `onze start` runs
71's `bin/onze`, `SIGTERM` reaches the node; `create`'s defaults exist once; the bundler cuts a
chunk per route, honours `assetPrefix` and both `<Script>` callbacks; CLI and bundler read std's
`Json` methods.

## Mechanism

- **Today.** `main.bp` answers `dev` with "onze dev: not available yet" (exit 2); no `dev.bp`;
  `onze-bundler/src/rebuild.bp` (a changed file's invalidation set) has no caller. `build.bp`
  does not drive rakun 60's `static_gen.bp`. `start.bp` waits on `process.run`. `build.bp`,
  `info.bp` declare a local `membersOf`, `onze-bundler/src/entry.bp` an `itemsOf` (std's
  `Json.members()` / `.items()`). `create.bp`'s `createDefaults()` feeds the option parser and
  `createHelp()` (`--help`, snapshot `create/help_the_flag_table_from_the_one_defaults_record.snap`);
  `docs.md` has no copy of the table. `resolve.bp`'s cases are in `scan_test` / `create_test` (no
  `resolve_test.bp`). The generated entry imports every client component → every island in
  `shared`; no `assetPrefix`; `<Script>` has `onLoad` only.
- **`dev` under 50-b (a)**: a file watcher (std `io.fs.walk` polled, or the host's watcher via one
  cell) runs `build` on a change and restarts the node `start` spawned; the previous build serves
  until the new one is ready; a compile error prints the compiler's message, previous node stays
  up. `rebuild.bp` narrows the recompile set. "`build && start` serves what `dev` served" holds by
  construction.
- **`prerender/`**: `build.bp` calls rakun 60's generator per static route the scan classifies →
  `<outDir>/prerender/<route>/index.html`; `start` serves them before the renderer (rakun 60's
  serving rule).
- **Signal, under `std-d` (b)**: `start` execs 71's `bin/onze` (PID 1 = the VM); CLI gone before
  any signal. Under (a) the CLI forwards it.
- **Lazy starters**: the entry registers per route pattern a loader importing that route's chunk
  (`registerRouteStarters(pattern, load)`); `chunk.bp` cuts one chunk per route group plus
  `shared`; the manifest's `R` record already maps pattern → chunk.

## Open

### Step 1 — consume std (97)

- [ ] `grep -n "fn membersOf\|fn itemsOf" modules/onze-cli/src modules/onze-bundler/src` empty;
      every suite's count unchanged

### Step 2 — `onze dev` (50-b (a))

- [ ] `onze dev` on `examples/scaffold` serves `/`, prints `http://localhost:3000` (`dev_test.bp`,
      real socket like `start_test.bp`)
- [ ] editing `app/page.bp` changes the next response after rebuild; adding `app/about/page.bp`
      makes `/about` resolve (manifest and `onze_routes.bp` regenerated)
- [ ] a compile error prints the compiler's own message; the previous build keeps answering
- [ ] `-p` does not write `onze.json`; `-H <addr>` binds that address (`reference-holes.md` § 29)
- [ ] `main.bp` dispatches `dev` to `dev.bp`; the "not available yet" text gone

### Step 3 — `prerender/`

- [ ] `onze build` on the blog writes `prerender/blog/<slug>/index.html` per static post, nothing
      for a dynamic route; the five output entries of 1.0.10's step 7 exist
- [ ] `start` serves a prerendered route without invoking the page (53 step 2 asserts the counter)

### Step 4 — the signal (`std-d`)

- [ ] under (b): `start` execs `bin/onze`, absent from the process tree while the node runs;
      `start_test.bp` sends `SIGTERM` to the node, observes the drain order 71 pins
- [ ] under (a): `start` forwards `SIGTERM` via `process.forwardSignals`

### Step 5 — `start` calls `bin/onze`; `build` passes `includeErts` (after 71 step 2)

- [ ] `start.bp` runs `<outDir>/release/bin/onze` when it exists, else refuses naming it — one
      start path
- [ ] `build.bp` passes `ReleaseSpec.includeErts` through to 71's `assembleRelease`

### Step 6 — the bundler tail (68)

- [ ] entry registers one loader per route pattern (`registerRouteStarters`), imports no island
      statically; `chunk_test.bp`: an island used by one route is in that route's chunk, not
      `shared`; the blog's `LikeButton` leaves `shared`
- [ ] `OnzeConfig.assetPrefix` (default `""`) threaded through `ChunkRef.url` and the served
      prefixes; `manifest_test.bp` round-trips it on both rows; `config_test.bp` refuses a prefix
      not an absolute URL or `""`
- [ ] `<Script onReady / onError>`: `script_test.bp` asserts both callbacks scheduled per strategy
- [ ] entry calls `jhonstart-link`'s `applyTransition` on client navigation, supplying the four
      `DomOps`; `entry_test.bp` asserts the generated call

### Step 7 — the defaults table, `--example`, the prompts, `resolve_test.bp`

- [ ] `docs.md`'s `create` table is `createHelp()`'s output, compared by a `check-docs` cell
      (`--help` and parser already read `createDefaults()`); `create_test.bp` asserts the three
      agree
- [ ] `onze create --example scaffold` copies `examples/scaffold`; under `std-d` (b) `create`
      without `--yes` refused listing the flags; under (a) prompts via `readLine`
- [ ] `test/resolve_test.bp` exists with `resolve.bp`'s cases moved from `scan_test` / `create_test`
      (total counts preserved)
- [ ] `examples/scaffold/README.md` names `create`'s table and `NEXTJS-DOCS.md` § 29

### Step 8 — § 50 of the snapshot map

→ 20-snap (front 135) step 5

### Step 9 — the `@/` alias goes (decision 218, handed by `01-compiler/129`)

Apps import own modules by path in braces (`import {lib.db.findPost};`, decision 206); staging
no longer resolves `from "@/…"` — `module-import-with-from` like any other. Today: `onze-bundler`'s
`AliasMap` resolves `@/…` (`graph.bp` `edgesOf` → `resolveAlias`, `rebuild.bp`
`BundleSetup.aliases`); `src/fixture.bp`, `graph_test` / `rebuild_test` import through it;
`examples/scaffold/botopink.json` declares `"alias"`; `docs.md` documents it.

- [ ] `AliasMap`, `resolveAlias` gone; bundler tests and `fixture.bp` import by path
- [ ] `examples/scaffold/botopink.json` has no `"alias"` key; `docs.md` names the brace form, not
      the alias (blog's half: 53 step 1)
- [ ] `grep -rn '"@/' repository/onze/modules repository/onze/examples/scaffold --include=*.bp` is empty
- [ ] `onze-test`'s `assertAlias` (`src/core.bp`, its two `test/helpers_test.bp` cases and `.snap`)
      deleted — 49's files, one carve-out commit

## Notes

- Step 6 changes the chunk plan: the blog's `assets_test` and 53's script-tag rows re-assert chunk
  names.
- `dev` restarts, not hot-loads (50-b (a)); Fast Refresh a stated non-goal (`reference-holes.md`
  § 29). The bundler's `importsOf` stays a text scan (lg2-s is the compiler's row).

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-cli` 31+ and `onze-bundler` 42+ on every target its manifest
      declares; `scaffold` green
