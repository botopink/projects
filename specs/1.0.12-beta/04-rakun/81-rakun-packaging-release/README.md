# Front 81 — Packaging and release: a tarball that boots, upgrades and validates

**Priority:** high — a release that boots is the deliverable every other member exists for; the
tarball has never been booted in a test · **State:** not started (the compile step exists)
**Depends on:** 128 · 03r-ak (step 3) · whether `release_handler` and `erl` distribution run under the
test runner (step 2) · 88 depends on this front
**Owns:** `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` ·
`rakun-cli`'s `botopink.json` and `src/root.bp` (the lower number; 88 appends after this lands) ·
`repository/rakun/AGENTS.md` § Release
**Does not touch:** the rest of `rakun-cli` (88's) · `rakun-actuator` (11's; the SBOM endpoint
registers through the core's `actuator_api`) · `src/release/release.bp`'s renderers while
`03-bundled-libs/107-release` holds them — after this front (decision 188)

## Goal

A release built from `examples/rakun` carries every `.erl` sidecar compiled into its `ebin`, boots
with `bin/<name> foreground`, upgrades and downgrades on a running node with zero failed requests,
and its SBOM validates against the checked-in CycloneDX 1.5 schema.

## Mechanism

- **R81-1.** `release.bp`'s `buildTarball` already compiles every `.erl` under each application
  directory it is given (`rakun_release.erl` `compile_dir/1`: `compile:file/2`, deterministic, a
  file that does not compile raises naming it) into `lib/<app>-<vsn>/ebin/`. What is not measured
  is whether the directories `rakun build` passes include the compiler's `out/erl/` (where
  `botopink build --target erlang` ships the sidecars); step 1 measures it first and adds the
  directory if it is missing. The boot cell runs `bin/<name> foreground` as a child process with
  `RAKUN_MAIN_HEADLESS=true`, reads stdout for the banner and the exit code.
- **R81-2.** With a booting release, `release_handler:install_release/1` on the running node from
  the test (the node started with `-sname` under the test's cookie; if the runner has no `epmd`, the
  sidecar starts one with `-start_epmd` and the README says so); a request loop against the node's
  port across the upgrade; the downgrade applied afterwards on the same node.
- **R81-3 (03r-ak (a)).** `release_test.bp` reads `test/release/fixtures/bom-1.5.schema.json` with
  `json.decode` and walks the rendered SBOM: every `required` name per object, every `type`, every
  `enum`, local `$ref`s under `definitions` followed once.

The boot cell starts a real node under `BOTOPINK_TEST_TMPDIR` — no external service, no env variable.
If distribution cannot start under the runner, the upgrade cell is not written and the boxes stay
open naming the runner's limit; a boot cell without an upgrade cell is not a skip.

## Open

### Step 1 — The tarball boots (R81-1)

- [ ] `release_test.bp`: a release built from `examples/rakun` has every `out/erl/*.erl` compiled into `lib/<app>/ebin` (the `.beam` files listed in the tarball's tree) — measured first against today's `compile_dir` call; the README records whether it already held
- [ ] unpacked under the scratch directory, `bin/<name> foreground` with the headless keep-alive=false options starts, prints the banner and exits 0 within 10 s
- [ ] a sidecar that does not compile fails `rakun build` naming the file and line

### Step 2 — Upgrade and downgrade (R81-2)

- [ ] two versions built from `examples/rakun` (a one-line change in `users.bp`); the first boots with `-sname`; `install_release` of the second on the running node; a loop of 200 `GET /users` across the switch-over sees zero failures
- [ ] the generated downgrade applied to the same node afterwards; the loop again zero failures; `release_handler:which_releases/0` shows the expected states
- [ ] if the runner cannot start distribution, the README records the measured refusal and both boxes stay open naming it; no cell is written

### Step 3 — SBOM validation (R81-3, R81-4, 03r-ak)

- [ ] `bom-1.5.schema.json` checked in under `test/release/fixtures/`; `release_test.bp` walks the rendered SBOM against it (`required`, `type`, `enum`, local `$ref`) and passes; a fixture SBOM missing `bomFormat` fails the walk naming the path
- [ ] R81-4 reworded to "`src/` renders every file; there is no `templates/`" and ticked

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cli` (the `test/release/` files in the run).

Blast radius: `rakun build` (88) delegates to the release; `scaffold_test` "build: the release
artefact is front 81's tarball, and exit 0" re-runs unchanged. The boot cell adds ~10 s to the
member's suite.

## Notes

- `examples/release-manifest-example.bp` is kept for its open marker (lg2-k: no comptime project
  reflection — the application list stays a build-time walk).
- For a release, the toolchain row "a built erlang program cannot load its `.erl` sidecars" is this
  front's to close; the row's `botopink run` half is 73's re-measure.
