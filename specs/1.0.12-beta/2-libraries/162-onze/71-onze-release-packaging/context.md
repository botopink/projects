# Front 71 — onze release packaging tail: the release assembled, verified and booted end to end

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s1 → 162 s4 · s2 → 162 s4 · s3 → 162 s4 · s4 → 162 s4 · s5 → 162 s4 · gate → 162 s4. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — the release is the deploy artifact; four DoD boxes never ran against a real
release · **State:** not started (step 6's snapshots on disk)
**Depends on:** `07-onze/49` step 6 (`onze-test/src/release.bp`) · step 3: `04-rakun`
`11-rakun-actuator`, `04-rakun-erlang-runtime` carrying 62 (shutdown cells),
`81-rakun-packaging-release` (sidecar-loading row, "a built erlang program cannot load its `.erl`
sidecars" — the release boots only when it closes) · step 4: `04-rakun/22` carrying 60 (static
export reads its prerender) · step 5: `07-onze/50` (`build` wired), `07-onze/53` (blog complete)
**Feeds:** `07-onze/50` step 5 (`start` calls `bin/onze`, after step 2) ·
`03-bundled-libs/107-release` runs **after** this (extracts `otp.bp` / `docker.bp` / `spec.bp`'s
renderers; the texts here are what it must reproduce)
**Owns:** `repository/onze/modules/onze-release/**`, `examples/static-site/**` (new),
`modules/onze-test/src/release.bp` · this directory
**Does not touch:** `modules/onze-cli/**` (50 — `build.bp` / `start.bp`'s two lines are 50 step
5's) · `modules/onze/**`, `modules/onze-server/**` (49) · `examples/blog/**` (53 — step 5 reads it)
· a container runtime's configuration (the gate's environment)

## Goal

`onze build` assembles a release carrying its ERTS when asked; `bin/onze` verifies the build id
before booting; static export writes to disk, `examples/static-site/` proves it; the blog's real
release boots with no source, no compiler, non-root in a container, no secret inside.

## Mechanism

- **Today.** `spec.bp`'s `ReleaseSpec.includeErts` (default `true`) reaches `otp.bp`'s boot script
  (`erts-<vsn>/bin/erl` vs `erl`) and `docker.bp` (runner `alpine:3.20` with ERTS,
  `erlang:<otpRelease>-alpine` without — in
  `release/dockerfile_two_stages_non_root_erts_bundled_and_not.snap`); `package.bp`'s
  `assembleRelease` copies no ERTS. Boot script compares `BUILD_ID` with the stamped id (`otp.bp`
  `bootScriptText`); `verifyBuildId` (`spec.bp`) is pure, nothing runs it. `static_export.bp`
  computes the export tree, writes nothing; `examples/static-site/` absent. `lifecycle.bp`'s
  `shutdown` runs five steps over a recording `Lifecycle` double.
- **ERTS**: `assembleRelease` copies `$ERL_ROOT/erts-<vsn>` into the release, passes
  `--include-erts` to `systools`.
- **`bin/onze`**: shell script shipped in the release: reads `PORT`, runs the VM's `verifyBuildId`
  entry (an `-eval` loading manifest and stamped id, non-zero exit on mismatch), then `exec`s the
  OTP boot script.
- **Static export**: `<route>/index.html` per prerendered route + asset tree + `public/` into
  `<outDir>/export/`.
- Configuration at boot, not build: no environment value enters the release (step 5's last box).

## Notes

- Step 1 changes `package.bp` only; Dockerfile text and snapshot stay.

