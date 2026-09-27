# Front 107 — a bundled `release`: the OTP release text both frameworks render (conditional on `07-g`)

**Priority:** low — two generators of the same five files; correct today, drifting tomorrow.
**Depends on:** `07-g` answered "package" · `00-gate` green.
**Owns:** `repository/botopink-lang/libs/release/**` (new) · registration lines (append) · consumers:
`repository/rakun/modules/rakun-release/src/release.bp` (lines 77-170: `renderRel`, `renderVmArgs`,
`renderSysConfig`, `bootScript`, `renderDockerfile`, systemd, appup),
`repository/onze/modules/onze-release/src/{otp,docker,spec}.bp`.
**Does not touch:** `systools` and tar (they stay with the callers through `io.process`) ·
`rakun_release.erl`'s consult/tar cells beyond the term writer it replaces · anything `03-rakun` 81
and `06-onze` 71 own outside the lines above (their open boxes — `includeErts`, `verifyBuildId`,
the booting tarball — are theirs, and they run **after** this front).

---

## Problem

rakun-release (erlang-only; `rakun_release.erl` term/tar/consult cells) and onze-release
(commonJS + erlang; pure text) render the same `.rel`, `vm.args`, `sys.config`, boot script,
Dockerfile and appup. onze cannot reuse rakun's because rakun is erlang-only (decision 117 item 9).

## Steps

### Step 1 — the package

`rel(spec)`, `vmArgs(spec)`, `sysConfig(props)` (with a `.bp` Erlang-term writer — strings, atoms,
integers, lists, tuples, maps — replacing the `rkRelTerm` sidecar cell), `bootScript(spec)`,
`dockerfile(spec)`, `appup(from, to)`.

**Acceptance:**
- [ ] each renderer byte-identical to rakun-release's output for one fixed spec, both rows
- [ ] the term writer round-trips through `erl -eval 'file:consult(...)'` in an erlang test cell

### Step 2 — consumers

- [ ] rakun-release imports the package; `rkRelTerm` deleted; its tests green
- [ ] onze-release imports the package; `otp.bp` / `docker.bp` / `spec.bp` keep only onze's spec
      shape; onze-release's 9 tests green on both rows

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green
- [ ] `libs/release/AGENTS.md` written; touched `AGENTS.md` files updated
- [ ] Commit on `front/107-release`

## Notes

`07-g` option (b) would make this a `botopink` CLI feature under `02-std-and-packaging` instead;
option (c) deletes this directory.
