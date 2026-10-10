# Front 88 — rakun CLI: `run` against a live app, `build`'s failure, `beans`, `routes`, `ws generate`

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s20 · s2 → 150 s20 · s3 → 150 s20 · s4 → 150 s20 · s5 → 150 s20. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — last of the track: consumes 81's booting release, 93's generator, 92's
registry, 04's scan registry · **State:** not started
**Depends on:** 81 step 1 (R88-2 needs a failing release build's message) · 93 step 2 (generator
`ws generate` wraps) · 92 (R92-6: rsocket routes in 15's registry) · 04 step 4 (`rkScannedDeps`,
R88-3) · 73's re-measure of `botopink run` (R88-1) · onze 50 (R88-6, onze's file)
**Owns:** `modules/rakun-cli/**` (`templates/**` included) except 81's `src/release/**`,
`test/release/**`, `src/sidecars/rakun_release.erl`; `botopink.json` / `src/root.bp` are 81's until
it lands, then this front appends · `repository/rakun/AGENTS.md` § CLI
**Does not touch:** 81's files · `rakun-client/src/ws/**` (93's) · `rakun-messaging/src/rsocket/**`
(92's) · the core · `repository/onze/**` · 130's decision-216 sites in the member (track README § Order)

## Goal

`rakun run`'s profile, port, watch and SIGTERM asserted against a running app; `rakun build`'s
failure passes the builder's message through; `beans` prints injected fields; `routes` lists rsocket
routes, runs concurrently without binding; `rakun ws generate` wraps 93's generator; the boundary
table with onze's CLI has its source here.

## Mechanism

Today: `src/{args,plugins,cli}.bp`, `templates/{plain,library,full-stack}`, 4 test files driving the
compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`; manifest depends on `rakun`,
`rakun-actuator` (and, after 128, `rakun-web` with the release); `--watch` is `botopink run`'s
watcher, not devtools. `rakun run` sets `RAKUN_PROFILES_ACTIVE` / `RAKUN_SERVER_PORT`, runs `botopink run`.

- **R88-1.** Once 73's re-measure shows `botopink run` serves, each box is a child-process cell:
  `rakun run --profile test --port 0` on a scaffolded app whose handler answers the active profile
  from the `#[config("rakun")]` record's `profiles` field (299, 04 step 7; `#[value("rakun.profiles.active")]` today); bound port read from the port file (04's boot options); `--watch` edits a file
  and re-requests; SIGTERM and exit code. Re-measure fails → cells not written, boxes stay open
  naming the toolchain row.
- **R88-2.** `rakun build` on a project whose sidecar does not compile (81 step 1's refusal) exits 1,
  stderr equals the builder's message.
- **R88-3.** `beans` prints `name type [deps…]` from `rkScannedDeps(name)`.
- **R92-6.** `routes` reads 15's registry tagged `rsocket` beside the HTTP table.
- **`ws generate`.** `plugins.bp` registers the command; calls `generate(wsdlPath, outDir)` from
  `rakun-client` (`src/ws/generate.bp`, 93), prints the file list; manifest gains `rakun-client`.

Every cell a child process of the compiler or the scaffolded app under the scratch directory; no
env variable but `BOTOPINK_BIN`, no external service.
