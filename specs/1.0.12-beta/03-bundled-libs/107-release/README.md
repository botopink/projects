# Front 107 — release: a bundled `release`, the OTP release text both frameworks render (conditional on `07-g`)

**Priority:** low — two generators of the same five files; correct today, drifting tomorrow ·
**State:** not started
**Depends on:** `07-g` answered (a) "package" · `04-rakun/81`, `07-onze/71` landed (decision 188) ·
`04-rakun/128` (moves `rakun-release` into `rakun-cli`, decision 187) · last appender to the three
registration lines (decision 189)
**Owns:** `repository/botopink-lang/libs/release/**` (new) · registration lines (append) · consumers:
`repository/rakun/modules/rakun-cli/src/release/release.bp` (renderers `renderRel`, `renderVmArgs`,
`renderSysConfig`, `bootScript`, `renderDockerfile`, systemd, appup — today in
`rakun-release/src/release.bp`), `repository/onze/modules/onze-release/src/{otp,docker,spec}.bp`
**Does not touch:** `systools`, tar (stay with callers via `io.process`) · `rakun_release.erl`'s
consult/tar cells beyond the term writer it replaces · what `04-rakun` 81 / `07-onze` 71 own outside
those lines (`includeErts`, `verifyBuildId`, the booting tarball)

## Goal

rakun's release (erlang-only; `rakun_release.erl` term/tar/consult cells) and onze-release
(commonJS + erlang; pure text) render the same `.rel`, `vm.args`, `sys.config`, boot script,
Dockerfile, appup; no reuse since rakun is erlang-only (decision 117 item 9). After: one set of pure
renderers. `07-g` (b) → a `botopink` CLI feature under `02-std-and-packaging`; (c) → directory deleted.

## Open

### Step 1 — the package

`rel(spec)`, `vmArgs(spec)`, `sysConfig(props)` (a `.bp` Erlang-term writer — strings, atoms,
integers, lists, tuples, maps — replacing the `rkRelTerm` sidecar cell), `bootScript(spec)`,
`dockerfile(spec)`, `appup(from, to)`.

- [ ] each renderer byte-identical to rakun's release output for one fixed spec, both rows
- [ ] onze-release's two recorded snapshots reproduced byte for byte (`snap-a` (3)):
      `modules/onze-release/test/__snapshots__/release/text_rel_sys_config_vm_args_and_the_boot_script.snap`
      (`.rel`, `sys.config`, `vm.args`, boot script) and
      `dockerfile_two_stages_non_root_erts_bundled_and_not.snap` (Dockerfile with and without ERTS) —
      kept as recorded, this front's contract
- [ ] the term writer round-trips through `erl -eval 'file:consult(...)'` in an erlang test cell

### Step 2 — consumers

- [ ] rakun-cli's release imports the package; `rkRelTerm` deleted; its tests green
- [ ] onze-release imports the package; `otp.bp` / `docker.bp` / `spec.bp` keep only onze's spec
      shape; onze-release's 9 tests green on both rows

## Decisions

`07-g` — [`../README.md`](../README.md) § Decisions.

**Gate:** standard (fronts.md § Gate) + `libs/release/AGENTS.md` written
