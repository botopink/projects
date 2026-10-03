# Front 71 — onze release packaging tail

**Priority:** medium — the release is the deploy artifact; four of its DoD boxes have never been
run against a real release because `onze build` was not wired to it
**Depends on:** `07-onze/50` step 5 (the two lines in `build.bp` / `start.bp` — this front
writes `bin/onze`, 50 calls it) · the `04-rakun` track: `81-rakun-packaging-release` (the
sidecar-loading toolchain row, "a built erlang program cannot load its `.erl` sidecars" — the
release boots only when it closes), `11-rakun-actuator` and `04-rakun-erlang-runtime` carrying 62
(the shutdown cells `lifecycle.bp` records against) · the `22-rakun-file-routing` front carrying
60 (static export reads its prerender) · maintainer `53-b` (step 6) · `03-bundled-libs/107-release`
runs **after** this front (it extracts `otp.bp` / `docker.bp` / `spec.bp`'s renderers)
**Owns:** `repository/onze/modules/onze-release/**`, `examples/static-site/**` (new),
`modules/onze-test/src/release.bp` · this directory
**Does not touch:** `modules/onze-cli/**` (50) · `modules/onze/**`, `modules/onze-server/**` (49)
· `examples/blog/**` (53 — the release gate boxes run over it read-only) · a container runtime's
configuration (the gate's environment)
**Carried from 1.0.10:** `71-onze-release-packaging/README.md` § Step 2 box 3 (`includeErts`),
§ Step 5 boxes 1 and 4, § Step 7 box 2, § Definition of done boxes 2–5, § Where it stands ·
`modules.md` § examples (`static-site`) · `test-snap.md` § 71 (copied as
[`test-snap.md`](./test-snap.md), conditional on 53-b) · `examples/{boot-and-shutdown,release-descriptor}-example.bp`
(copied)

---

## Problem

1. `includeErts: true` does not produce `erts-<vsn>/` in the release, and the Dockerfile's
   runner base image does not differ by it — the release is not assembled end to end until
   `onze build` drives it.
2. `bin/onze` checks `BUILD_ID` against the stamped id but does not run `verifyBuildId` across
   the release, the client manifest and the payload (the manifest/payload comparison needs the
   VM up); `onze start` does not call the script (50 step 5).
3. `static_export.bp` computes the export tree and writes nothing to disk; `examples/static-site/`
   does not exist.
4. The four gate boxes — the release boots with no source tree and no compiler; the build id is
   derived once and verified in three places; the container runs as non-root on `PORT`;
   `scanForSecrets` over the real release finds only the `ONZE_PUBLIC_` table — have never run.

## Current state

`onze-release` 9 tests on both rows (one running the real `systools:make_script`); `spec`, `otp`,
`docker`, `package`, `lifecycle`, `static_export` exist; the build id is six hex of
`contentHash`; `shutdown` runs its five steps over a recording `Lifecycle` double.

## Mechanism

`package.bp`'s `assembleRelease` takes the `ReleaseSpec` and the built tree; `includeErts` is a
copy of `$ERL_ROOT/erts-<vsn>` into the release and a `--include-erts` flag to `systools`.
`bin/onze` is a shell script the release ships: it reads `PORT`, runs the VM's `verifyBuildId`
entry (an `-eval` that loads the manifest and the stamped id and exits non-zero on a mismatch)
and then `exec`s the OTP boot script. Static export writes `<route>/index.html` per prerendered
route plus the asset tree and `public/` into `<outDir>/export/`.

## Steps

### Step 1 — `includeErts`

**Acceptance:**
- [ ] `package_test.bp`: with `includeErts: true` the release holds `erts-<vsn>/bin/erl`; with
      `false` it does not; `release_text_test.bp`: the Dockerfile's runner stage is
      `debian:bookworm-slim` with the ERTS copied, or the `erlang:<vsn>-slim` image without it —
      the two texts differ only there

### Step 2 — `bin/onze`

**Acceptance:**
- [ ] the script runs `verifyBuildId` before the boot script and exits non-zero naming the
      mismatch when the manifest's id, the stamped id or the payload's differ (`package_test.bp`
      tampers each in a scratch release)
- [ ] it `exec`s the OTP boot script (PID 1 is the VM); `PORT` defaults to 3000
- [ ] 50 step 5's box ("`start` calls this script and adds no second start path") is closable
      on this step

### Step 3 — the shutdown against real cells

**Acceptance:**
- [ ] `lifecycle.bp`'s five steps run over rakun's real cells (readiness down, the listener's
      stop/drain — rakun 11 and 62's `after()`) once they land; until then the recording double
      stays and the box is open, named "rakun 11 / 62 / 81"

### Step 4 — static export to disk and `examples/static-site/`

**Acceptance:**
- [ ] `static_export.bp` writes `<outDir>/export/<route>/index.html` for every prerendered route,
      the static asset tree under `_onze/static/<buildId>/` and `public/` copied; no boot script,
      no `releases/`
- [ ] `examples/static-site/` — three static routes, `onze.json` `output: "export"`, a
      `README.md`; `test/export_test.bp` builds it and asserts the tree; a fourth, dynamic route
      added in a test fails the export naming itself
- [ ] `zig build test-libs` lists `static-site` green on both rows

### Step 5 — the four gate boxes over the blog

Run after 50 (`build` wired) and 53 (the blog complete); asserted by `package_test.bp` over the
blog's real release in the gate's environment (a container runtime present).

**Acceptance:**
- [ ] `onze build` on the blog produces the release layout of 1.0.10's § Mechanism and `onze
      start` boots it from a directory holding no source tree and no `botopink` binary, answering
      `/` — hard failure while the sidecar-loading row is open, named as such
- [ ] the build id is derived once and `verifyBuildId` passes across the release, the client
      manifest and the payload
- [ ] the Dockerfile builds and the container runs as a non-root user on `PORT` (the gate's
      environment provides `docker` or `podman`; `00-gate` decides how a missing runtime reads)
- [ ] `scanForSecrets` over the real release finds only the `ONZE_PUBLIC_` table 68 inlined

### Step 6 — conditional on `53-b` (b) or (c): `release_text_test.bp` as snapshots

Under (c) — the recommendation — the `.rel`, `vm.args`, `sys.config`, boot script and
Dockerfile texts are recorded as `.snap` through `assertReleaseText` (the § 71 map), so
`107-release` has a byte-for-byte contract to keep.

**Acceptance:**
- [ ] under (c): five `.snap` files under `modules/onze-release/test/__snapshots__/release/`,
      identical on both rows; `107-release`'s README names them

## Gate

- [ ] `zig build test-libs` — `onze-release` 9+ on both rows; `static-site` green
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/71-onze-release-packaging`; no push, no merge — landing is the maintainer's
      step

## Blast radius

Step 1 changes the Dockerfile text (`release_text_test` re-asserts). `107-release` extracts the
renderers after this front, so the texts here are what it must reproduce.

## Notes

- Configuration at boot, not at build: no environment value enters the release (the 1.0.10
  rule; step 5's last box proves it).
- The ERTS copy is the reason the runner image can be distroless; without it the image is the
  OTP one.
