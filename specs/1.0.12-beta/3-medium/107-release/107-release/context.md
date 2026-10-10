# Front 107 — release: a shared `release`, the OTP release text both frameworks render (conditional on `07-g`)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [107-release](../README.md): s1 → 107 s1 · s2 → 107 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — two generators of the same five files; correct today, drifting tomorrow ·
**State:** not started
**Depends on:** `07-g` answered (a) "package" · `04-rakun/81`, `07-onze/71` landed (decision 188) ·
`04-rakun/128` (moves `rakun-release` into `rakun-cli`, decision 187)
**Owns:** `repository/release/**` (new — `botopink/release`, born as a repository: decision 326) · consumers:
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

## Decisions

`07-g` — [`../README.md`](../../163-meta-ci/03-bundled-libs/track.md) § Decisions.

**Gate:** standard (fronts.md § Gate) + `repository/release/AGENTS.md` written
