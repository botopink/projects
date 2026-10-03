# Front 71 — onze release packaging tail: the release assembled, verified and booted end to end

**Priority:** medium — the release is the deploy artifact; four of its DoD boxes have never run
against a real release · **State:** not started (step 6's snapshots are on disk)
**Depends on:** `07-onze/49` step 6 (`onze-test/src/release.bp`) · step 3: `04-rakun`
`11-rakun-actuator` and `04-rakun-erlang-runtime` carrying 62 (the shutdown cells) and
`81-rakun-packaging-release` (the sidecar-loading row, "a built erlang program cannot load its
`.erl` sidecars" — the release boots only when it closes) · step 4: `04-rakun/22` carrying 60
(static export reads its prerender) · step 5: `07-onze/50` (`build` wired) and `07-onze/53` (the
blog complete)
**Feeds:** `07-onze/50` step 5 (`start` calls `bin/onze`, after step 2) ·
`03-bundled-libs/107-release` runs **after** this front (it extracts `otp.bp` / `docker.bp` /
`spec.bp`'s renderers; the texts here are what it must reproduce)
**Owns:** `repository/onze/modules/onze-release/**`, `examples/static-site/**` (new),
`modules/onze-test/src/release.bp` · this directory
**Does not touch:** `modules/onze-cli/**` (50 — `build.bp` / `start.bp`'s two lines are 50
step 5's) · `modules/onze/**`, `modules/onze-server/**` (49) · `examples/blog/**` (53 — step 5
runs over it read-only) · a container runtime's configuration (the gate's environment)

## Goal

`onze build` assembles a release that carries its ERTS when asked, `bin/onze` verifies the build
id before booting, static export writes to disk and `examples/static-site/` proves it, and the
blog's real release boots with no source and no compiler, as non-root in a container, with no
secret inside.

## Mechanism

- **Today.** `spec.bp`'s `ReleaseSpec.includeErts` (default `true`) reaches `otp.bp`'s boot
  script (`erts-<vsn>/bin/erl` vs `erl`) and `docker.bp` (runner `alpine:3.20` with ERTS,
  `erlang:<otpRelease>-alpine` without — recorded in
  `release/dockerfile_two_stages_non_root_erts_bundled_and_not.snap`), but `package.bp`'s
  `assembleRelease` copies no ERTS. The boot script compares `BUILD_ID` with the stamped id
  (`otp.bp` `bootScriptText`); `verifyBuildId` (`spec.bp`) is a pure function nothing runs.
  `static_export.bp` computes the export tree and writes nothing; `examples/static-site/` does
  not exist. `lifecycle.bp`'s `shutdown` runs its five steps over a recording `Lifecycle` double.
- **ERTS.** `assembleRelease` copies `$ERL_ROOT/erts-<vsn>` into the release and passes
  `--include-erts` to `systools`.
- **`bin/onze`** is a shell script the release ships: it reads `PORT`, runs the VM's
  `verifyBuildId` entry (an `-eval` that loads the manifest and the stamped id and exits non-zero
  on a mismatch) and then `exec`s the OTP boot script.
- **Static export** writes `<route>/index.html` per prerendered route plus the asset tree and
  `public/` into `<outDir>/export/`.
- Configuration at boot, not at build: no environment value enters the release (step 5's last
  box proves it).

## Done

- Step 6, the recording — the release texts (`.rel` / `sys.config` / `vm.args` / boot script), the
  Dockerfile, the build id, the shutdown and the static export are five `.snap` under
  `modules/onze-release/test/__snapshots__/release/`, on both rows

## Open

### Step 1 — `includeErts` copies the runtime

- [ ] `package_test.bp`: with `includeErts: true` the release holds `erts-<vsn>/bin/erl`; with
      `false` it does not
- [ ] `release_text_test.bp` asserts the two Dockerfile texts differ only in the runner `FROM`
      line (`alpine:3.20` with ERTS, `erlang:<otpRelease>-alpine` without — the images
      `docker.bp` and its snapshot use)

### Step 2 — `bin/onze`

- [ ] the script runs `verifyBuildId` before the boot script and exits non-zero naming the
      mismatch when the manifest's id, the stamped id or the payload's differ (`package_test.bp`
      tampers each in a scratch release)
- [ ] it `exec`s the OTP boot script (PID 1 is the VM); `PORT` defaults to 3000
- [ ] 50 step 5's box ("`start` calls this script and adds no second start path") is closable
      on this step

### Step 3 — the shutdown against real cells

- [ ] `lifecycle.bp`'s five steps run over rakun's real cells (readiness down, the listener's
      stop/drain — rakun 11 and 62's `after()`) once they land; until then the recording double
      stays and the box is open, named "rakun 11 / 62 / 81"

### Step 4 — static export to disk and `examples/static-site/`

- [ ] `static_export.bp` writes `<outDir>/export/<route>/index.html` for every prerendered route,
      the static asset tree under `_onze/static/<buildId>/` and `public/` copied; no boot script,
      no `releases/`
- [ ] `examples/static-site/` — three static routes, `onze.json` `output: "export"`, a
      `README.md`; `test/export_test.bp` builds it and asserts the tree; a fourth, dynamic route
      added in a test fails the export naming itself
- [ ] `zig build test-libs` lists `static-site` green on both rows

### Step 5 — the four gate boxes over the blog

Run after 50 and 53; asserted by `package_test.bp` over the blog's real release in the gate's
environment (a container runtime present).

- [ ] `onze build` on the blog produces the release layout of `docs.md` and `onze start` boots
      it from a directory holding no source tree and no `botopink` binary, answering `/` — hard
      failure while the sidecar-loading row is open, named as such
- [ ] the build id is derived once and `verifyBuildId` passes across the release, the client
      manifest and the payload
- [ ] the Dockerfile builds and the container runs as a non-root user on `PORT` (the gate's
      environment provides `docker` or `podman`; `00-gate` decides how a missing runtime reads)
- [ ] `scanForSecrets` over the real release finds only the `ONZE_PUBLIC_` table 68 inlined

### Step 6 — the release snapshots as `107-release`'s contract

→ 20-snap (front 135) step 5

## Notes

- Step 1 changes `package.bp` only; the Dockerfile text and its snapshot stay.

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze-release` 9+ on both rows; `static-site` green
