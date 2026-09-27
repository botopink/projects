# Front 81 — Packaging and Release

**Priority:** high — a release that boots is the deliverable every other member exists for; the tarball has never booted because the sidecars it needs were not in it, and the compiler now ships them
**Carries:** —
**Depends on:** maintainer 03r-ak (CycloneDX validation) · the toolchain row re-measure (`botopink build --target erlang` writes `out/erl/*.erl`) · none in this track (88 depends on this front)
**Owns:** `modules/rakun-release/**` · `repository/rakun/AGENTS.md` § Release
**Does not touch:** `rakun-cli` (88's) · `rakun-actuator` (11's; the SBOM endpoint is registered through `rakun-actuator-api`)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/81-rakun-packaging-release/README.md`) | Box, as written |
|---|---|---|
| R81-1 | § Step 2 — The tarball | "Unpacking it and running `bin/<name> foreground` starts the node (gated by *Blocked* below) — open: blocked (see Blocked) — a built erlang program cannot load its `.erl` sidecars" |
| R81-2 | § Step 5 — Release upgrades | "An upgrade applied to a running node serves every request during the switch-over — asserted by a request loop across the upgrade with zero failures — open: the appup is generated; applying it to a running node needs a booting release (Blocked) and `release_handler`" · "A downgrade to the previous version exists, is generated at the same time, and is tested on the same node — open: … untested on a node for the same reason" |
| R81-3 | § Step 6 — SBOM | "The document validates against the CycloneDX 1.5 schema — asserted against a checked-in schema, with no network access — open: std has no JSON-schema validator" |
| R81-4 | § Definition of done | "`modules/rakun-release/` exists with its manifest, `src/` and `templates/` — open: … there is no `templates/` — every file is rendered from line arrays in `release.bp` (the front's own rule)" — closes by amendment: "`src/` renders every file; there is no `templates/`" |

## Problem

`release.bp` assembles `lib/<app>/ebin` from the emitted `.beam` files and `sys.config` / `vm.args`
/ the boot script; the `.erl` sidecars the application calls (`rakun_runtime`, `rakun_context`,
…) were not in the build output when the front closed, so the node started and died on the first
`undef`. The compiler now writes them to `out/erl/`; the release must `erlc` them into the same
`ebin`. Without a booting release the upgrade and downgrade cannot be tested on a node.

## Current state

`modules/rakun-release`: `src/{release,sbom}.bp`, `rakun_release.erl`, `test/release_test.bp` (green;
the tarball's tree, `sys.config`, `vm.args`, the Dockerfile, the systemd unit, the Kubernetes
fragments, the appup plan, the SBOM's required fields are all asserted on the rendered files);
nothing boots. `release_test.bp:22` works under `BOTOPINK_TEST_TMPDIR`.

## Mechanism

- R81-1: `rakun_release.erl` gains a `compile_sidecars(OutErlDir, EbinDir)` step — `compile:file/2`
  per `.erl` with `[{outdir, Ebin}, return_errors]`; a compile error fails the build naming the
  file. The boot test runs `bin/<name> foreground` as a child process with `RAKUN_MAIN_HEADLESS=true`,
  reads its stdout for the banner and its exit code.
- R81-2: with a booting release, `release_handler:install_release/1` on the running node from the
  test (the node is started with `-sname` under the test's own cookie — `erl` distribution on one
  host is what `release_handler` needs; if the runner's environment has no `epmd`, the sidecar starts
  one with `-start_epmd` and the README says so); a request loop against the node's port across the
  upgrade; the downgrade applied afterwards on the same node.
- R81-3 (03r-ak (a)): `release_test.bp` reads `test/fixtures/bom-1.5.schema.json` with `json.decode`
  and walks the rendered SBOM: every `required` name present per object, every `type` respected,
  every `enum` matched, local `$ref`s under `definitions` followed once.

## Gate stance

The boot cell starts a real node from the release under `BOTOPINK_TEST_TMPDIR` — no external
service, no env variable. If distribution cannot start under the runner, the upgrade cell is not
written and the box stays open naming the runner's limit; a passing boot cell without an upgrade
cell is not a skip.

## Steps

### Step 1 — The tarball boots (R81-1)

**Acceptance:**
- [ ] `release_test.bp`: a release built from `examples/rakun` compiles every `out/erl/*.erl` into `lib/<app>/ebin` (the `.beam` files listed in the tarball's tree)
- [ ] unpacked under the scratch directory, `bin/<name> foreground` with the headless keep-alive=false options starts, prints the banner and exits 0 within 10 s
- [ ] a sidecar that does not compile fails `rakun build` naming the file and line

### Step 2 — Upgrade and downgrade (R81-2)

**Acceptance:**
- [ ] two versions built from `examples/rakun` (a one-line change in `users.bp`); the first boots with `-sname`; `install_release` of the second on the running node; a request loop of 200 `GET /users` across the switch-over sees zero failures
- [ ] the generated downgrade applied to the same node afterwards; the loop again zero failures; the node's `release_handler:which_releases/0` shows the expected states
- [ ] if the runner cannot start distribution, the README records the measured refusal and both boxes stay open naming it; no cell is written

### Step 3 — SBOM validation (R81-3, 03r-ak)

**Acceptance:**
- [ ] `test/fixtures/bom-1.5.schema.json` checked in; `release_test.bp` walks the rendered SBOM against it (`required`, `type`, `enum`, local `$ref`) and passes; a fixture SBOM missing `bomFormat` fails the walk naming the path
- [ ] R81-4 reworded and ticked

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-release`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § Release updated
- [ ] commit on `fix/81-rakun-packaging-release`

## Blast radius

The release gains a compile step; `rakun-cli`'s `rakun build` (88) delegates to it and its
`scaffold_test` "build: the release artefact is front 81's tarball, and exit 0" re-runs unchanged.
The boot cell adds ~10 s to the member's suite.

## Notes

- `examples/release-manifest-example.bp` is copied here for its open marker (lg2-k: no comptime
  project reflection — the application list stays a build-time walk).
- The toolchain row "a built erlang program cannot load its `.erl` sidecars" is, for a release,
  this front's to close: the release compiles what the build ships. The row's `run` half is 73's
  re-measure.
