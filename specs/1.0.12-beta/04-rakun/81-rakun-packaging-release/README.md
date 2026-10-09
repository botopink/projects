# Front 81 — Packaging and release: a tarball that boots, upgrades and validates

**Priority:** high — a booting release is what every member exists for; the tarball was never booted
in a test · **State:** not started (compile step exists)
**Depends on:** 128 · 03r-ak (step 3) · whether `release_handler` and `erl` distribution run under the
test runner (step 2) · 88 depends on this front
**Owns:** `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` ·
`rakun-cli`'s `botopink.json` and `src/root.bp` (lower number; 88 appends after this lands) ·
`repository/rakun/AGENTS.md` § Release
**Does not touch:** rest of `rakun-cli` (88's) · `rakun-actuator` (11's; SBOM endpoint registers
through the core's `actuator_api`) · `src/release/release.bp`'s renderers while
`03-bundled-libs/107-release` holds them — after this front (decision 188)

## Goal

A release built from `examples/rakun` has every `.erl` sidecar compiled into its `ebin`, boots with
`bin/<name> foreground`, upgrades and downgrades on a running node with zero failed requests; its
SBOM validates against the checked-in CycloneDX 1.5 schema.

## Mechanism

- **R81-1.** `release.bp`'s `buildTarball` already compiles every `.erl` under each given
  application directory (`rakun_release.erl` `compile_dir/1`: `compile:file/2`, deterministic, a
  non-compiling file raises naming it) into `lib/<app>-<vsn>/ebin/`. Unmeasured: whether
  `rakun build`'s directories include the compiler's `out/erl/` (where `botopink build --target erlang`
  ships sidecars); step 1 measures, adds it if missing. Boot cell: `bin/<name> foreground` as a
  child process with `RAKUN_MAIN_HEADLESS=true`, stdout read for banner and exit code.
- **R81-2.** On a booting release, `release_handler:install_release/1` on the running node from the
  test (node started with `-sname` under the test's cookie; no `epmd` → sidecar starts one with
  `-start_epmd`, README says so); a request loop against the node's port across the upgrade; the
  downgrade applied afterwards on the same node.
- **R81-3 (03r-ak (a)).** `release_test.bp` reads `test/release/fixtures/bom-1.5.schema.json` with
  `json.decode`, walks the rendered SBOM: every `required` name per object, every `type`, every
  `enum`, local `$ref`s under `definitions` followed once.

Boot cell starts a real node under `BOTOPINK_TEST_TMPDIR` — no external service, no env variable.
Distribution cannot start under the runner → no upgrade cell, boxes stay open naming the limit; a
boot cell without an upgrade cell is not a skip.

## Open

### Step 1 — The tarball boots (R81-1)

- [ ] `release_test.bp`: a release from `examples/rakun` has every `out/erl/*.erl` compiled into `lib/<app>/ebin` (`.beam` files listed in the tarball's tree) — measured first against today's `compile_dir` call; README records whether it already held
- [ ] unpacked under the scratch directory, `bin/<name> foreground` with `headless: true`, `keepAlive: false` (299; `keep-alive` today) starts, prints the banner, exits 0 within 10 s
- [ ] a non-compiling sidecar fails `rakun build` naming file and line

### Step 2 — Upgrade and downgrade (R81-2)

- [ ] two versions from `examples/rakun` (one-line change in `users.bp`); the first boots with `-sname`; `install_release` of the second on the running node; 200 `GET /users` across the switch-over see zero failures
- [ ] the generated downgrade applied to the same node afterwards; loop again zero failures; `release_handler:which_releases/0` shows the expected states
- [ ] if the runner cannot start distribution, README records the measured refusal, both boxes stay open naming it; no cell written

### Step 3 — SBOM validation (R81-3, R81-4, 03r-ak)

- [ ] `bom-1.5.schema.json` checked in under `test/release/fixtures/`; `release_test.bp` walks the rendered SBOM against it (`required`, `type`, `enum`, local `$ref`) and passes; a fixture SBOM missing `bomFormat` fails naming the path
- [ ] R81-4 reworded to "`src/` renders every file; there is no `templates/`" and ticked

### Step 4 — the release manifest's marker against `@TypeInfo.all` (decisions 216, 253)

- [ ] `examples/release-manifest-example.bp` re-measured: if `@TypeInfo.all` builds the application
      list, marker, its Marker-index row and the `language-gaps.md` row go together
      (`scripts/language-gap-markers.sh` exits 0); else the row narrowed to what is missing (a
      package's module list or manifest), marker stays

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cli` (`test/release/` in the run).

Blast radius: `rakun build` (88) delegates to the release; `scaffold_test` "build: the release
artefact is front 81's tarball, and exit 0" re-runs unchanged. Boot cell adds ~10 s to the suite.

## Notes

- `examples/release-manifest-example.bp` keeps its marker (**No comptime reflection over the
  project**) until step 4: `lg2-k` answered by 216 (4), `@TypeInfo.all` (253) on feat, but it
  answers declarations, not a package's module list or manifest.
- The toolchain row "a built erlang program cannot load its `.erl` sidecars" is this front's to
  close for a release; its `botopink run` half is 73's re-measure.
