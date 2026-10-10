# Front 50 — onze CLI tail: `onze dev`, `prerender/`, the signal, one defaults table, the bundler tail

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s2 → 162 s2 · s3 → 162 s2 · s4 → 162 s2 · s5 → 162 s2 · s6 → 162 s2 · s7 → 162 s2 · s9 → 162 s2 · s10 → 162 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — `onze dev` is the one missing command of four; a new user's first scaffold
run prints "not available yet" · **State:** step 1 done (onze-wave patch; lands with the coordinator) (step 7: the defaults record already
drives `--help`)
**Depends on:** `03-bundled-libs/102` step 3's `scan.bp`, `chunk.bp` commits, before this opens
(decision 188) · maintainer `50-b` (step 2), `std-d` (steps 4, 7), `50-a` as amended ·
`07-onze/71` step 2 (`bin/onze`, step 5) · `05-jhonstart/27` step 1 (`applyTransition`, step 6 —
27 does not wait on this, decision 189) · `07-onze/49` step 6 (the `onze-test` group files)
**Owns:** `repository/onze/modules/onze-cli/**`, `modules/onze-bundler/**`,
`examples/scaffold/**`, `modules/onze-test/src/{cli,bundler}.bp` · this directory
**Does not touch:** other fronts' members (71's `onze-release`: step 5 only calls its script) and
the `03/102` (lands first) and `08-bpp` (117, 124, after) windows — [`../modules.md`](../07-onze/modules.md)
§ Front → files

## Goal

`onze dev` serves and rebuilds the scaffold; `onze build` writes `prerender/`; `onze start` runs
71's `bin/onze`, `SIGTERM` reaches the node; `create`'s defaults exist once; the bundler cuts a
chunk per route, honours `assetPrefix` and both `<Script>` callbacks; CLI and bundler read std's
`Json` methods.

## Mechanism

- **Today.** `main.bp` answers `dev` with "onze dev: not available yet" (exit 2) — its text
  describes a reload into the running node (50-b (b)) and cites "front 50 step 6", 1.0.10's
  numbering (here: step 2); no `dev.bp`;
  `onze-bundler/src/rebuild.bp` (a changed file's invalidation set) has no caller. `build.bp`
  does not drive rakun 60's `static_gen.bp`. `start.bp` waits on `process.run`. `create.bp`'s `createDefaults()` feeds the option parser and
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

## Notes

- Step 6 changes the chunk plan: the blog's `assets_test` and 53's script-tag rows re-assert chunk
  names.
- `dev` restarts, not hot-loads (50-b (a)); Fast Refresh a stated non-goal (`reference-holes.md`
  § 29). The bundler's `importsOf` stays a text scan (lg2-s is the compiler's row).
