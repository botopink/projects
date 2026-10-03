# Front 71 — onze release packaging tail: the release assembled, verified and booted end to end

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

## Done

- Step 6, the recording — release texts (`.rel` / `sys.config` / `vm.args` / boot script),
  Dockerfile, build id, shutdown, static export: five `.snap` under
  `modules/onze-release/test/__snapshots__/release/`, both rows

## Open

### Step 1 — `includeErts` copies the runtime

- [ ] `package_test.bp`: `includeErts: true` → release holds `erts-<vsn>/bin/erl`; `false` → not
- [ ] `release_text_test.bp`: the two Dockerfile texts differ only in the runner `FROM` line
      (`alpine:3.20` with ERTS, `erlang:<otpRelease>-alpine` without — as `docker.bp` and its
      snapshot)

### Step 2 — `bin/onze`

- [ ] runs `verifyBuildId` before the boot script; exits non-zero naming the mismatch when the
      manifest's id, the stamped id or the payload's differ (`package_test.bp` tampers each in a
      scratch release)
- [ ] `exec`s the OTP boot script (PID 1 = the VM); `PORT` defaults to 3000
- [ ] 50 step 5's box ("`start` calls this script and adds no second start path") closable on
      this step

### Step 3 — the shutdown against real cells

- [ ] `lifecycle.bp`'s five steps run over rakun's real cells (readiness down, listener
      stop/drain — rakun 11 and 62's `after()`) once they land; until then the recording double
      stays, box open, named "rakun 11 / 62 / 81"

### Step 4 — static export to disk and `examples/static-site/`

- [ ] `static_export.bp` writes `<outDir>/export/<route>/index.html` per prerendered route, the
      static asset tree under `_onze/static/<buildId>/`, `public/` copied; no boot script, no
      `releases/`
- [ ] `examples/static-site/` — three static routes, `onze.json` `output: "export"`, a
      `README.md`; `test/export_test.bp` builds it, asserts the tree; a fourth, dynamic route
      added in a test fails the export naming itself
- [ ] `zig build test-libs` lists `static-site` green on both rows

### Step 5 — the four gate boxes over the blog

After 50 and 53; asserted by `package_test.bp` over the blog's real release in the gate's
environment (container runtime present).

- [ ] `onze build` on the blog produces `docs.md`'s release layout; `onze start` boots it from a
      directory with no source tree and no `botopink` binary, answering `/` — hard failure while
      the sidecar-loading row is open, named as such
- [ ] build id derived once; `verifyBuildId` passes across release, client manifest, payload
- [ ] the Dockerfile builds; the container runs non-root on `PORT` (gate's environment provides
      `docker` or `podman`; `00-gate` decides how a missing runtime reads)
- [ ] `scanForSecrets` over the real release finds only the `ONZE_PUBLIC_` table 68 inlined

### Step 6 — the release snapshots as `107-release`'s contract

→ 20-snap (front 135) step 5

## Notes

- Step 1 changes `package.bp` only; Dockerfile text and snapshot stay.

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-release` 9+ on both rows; `static-site` green
