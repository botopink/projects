# Front 81 — Packaging and release: a tarball that boots, upgrades and validates

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s7 · s2 → 150 s7 · s3 → 150 s7 · s4 → 150 s7. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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

## Notes

- `examples/release-manifest-example.bp` keeps its marker (**No comptime reflection over the
  project**) until step 4: `lg2-k` answered by 216 (4), `@TypeInfo.all` (253) on feat, but it
  answers declarations, not a package's module list or manifest.
- The toolchain row "a built erlang program cannot load its `.erl` sidecars" is this front's to
  close for a release; its `botopink run` half is 73's re-measure.
