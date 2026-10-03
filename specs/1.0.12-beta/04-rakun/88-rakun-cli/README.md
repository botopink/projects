# Front 88 — rakun CLI: `run` against a live app, `build`'s failure, `beans`, `routes`, `ws generate`

**Priority:** medium — the last front of the track: it consumes 81's booting release, 93's generator,
92's registry and 04's scan registry · **State:** not started
**Depends on:** 81 step 1 (R88-2 needs a failing release build to have a message) · 93 step 2 (the
generator `ws generate` wraps) · 92 (R92-6: rsocket routes in 15's registry) · 04 step 4
(`rkScannedDeps`, R88-3) · 73's re-measure of `botopink run` (R88-1) · lg2-j (R88-5 stays open) ·
onze 50 (R88-6, onze's file)
**Owns:** `modules/rakun-cli/**` (`templates/**` included) except 81's `src/release/**`,
`test/release/**`, `src/sidecars/rakun_release.erl`; `botopink.json` / `src/root.bp` are 81's until it
lands, then this front appends · `repository/rakun/AGENTS.md` § CLI
**Does not touch:** 81's files · `rakun-client/src/ws/**` (93's) · `rakun-messaging/src/rsocket/**`
(92's) · the core · `repository/onze/**` · 130's decision-216 sites in the member (track README § Order)

## Goal

`rakun run`'s profile, port, watch and SIGTERM are asserted against a running app; `rakun build`'s
failure passes the builder's message through; `beans` prints injected fields; `routes` lists rsocket
routes and runs concurrently without binding; `rakun ws generate` wraps 93's generator; the
boundary table with onze's CLI has its source here.

## Mechanism

Today: `src/{args,plugins,cli}.bp`, `templates/{plain,library,full-stack}`, 4 test files driving the
compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`; the manifest depends on `rakun`,
`rakun-actuator` (and, after 128, `rakun-web` with the release); `--watch` is `botopink run`'s watcher,
not devtools. `rakun run` sets `RAKUN_PROFILES_ACTIVE` / `RAKUN_SERVER_PORT` and runs `botopink run`.

- **R88-1.** After 73's re-measure shows `botopink run` serves, each box is a child-process cell:
  `rakun run --profile test --port 0` on a scaffolded app whose `#[value("rakun.profiles.active")]`
  handler answers it; the bound port read from the port file (04's boot options); `--watch` edits a
  file and re-requests; SIGTERM and the exit code. If the re-measure fails, the cells are not written
  and the boxes stay open naming the toolchain row.
- **R88-2.** `rakun build` on a project whose sidecar does not compile (81 step 1's refusal) exits 1
  and its stderr equals the builder's message.
- **R88-3.** `beans` prints `name type [deps…]` from `rkScannedDeps(name)`.
- **R92-6.** `routes` reads 15's registry tagged `rsocket` beside the HTTP table.
- **`ws generate`.** `plugins.bp` registers the command; it calls `generate(wsdlPath, outDir)` from
  `rakun-client` (`src/ws/generate.bp`, 93) and prints the file list; the manifest gains
  `rakun-client`.

Every cell is a child process of the compiler or of the scaffolded app under the scratch directory;
no env variable but `BOTOPINK_BIN`, no external service.

## Open

### Step 1 — `rakun run` (R88-1)

- [ ] `run_test.bp`: the profile reaches the app (`GET /profile` answers `test`) and a `#[value]` binding reflects it; `--port` wins over `RAKUN_SERVER_PORT` wins over `application.yaml` (three runs, three ports)
- [ ] `--watch`: editing the scaffold's handler changes the answer within 2 s and a connection opened before the edit still answers
- [ ] SIGTERM to the child: the drain path runs (an in-flight request completes) and the exit code is 0

### Step 2 — Build and inspect (R88-2, R88-3, R88-4, R92-6)

- [ ] `scaffold_test.bp`: a project with a broken sidecar makes `rakun build` exit 1 and print 81's message unmodified
- [ ] `inspect_test.bp`: `rakun beans` prints one line per component with its type and injected fields (`fixtures/` with a two-field component)
- [ ] two `rakun routes` runs started at once both exit 0 and neither binds a port (`ss -ltn` through the sidecar shows no new listener during the run)
- [ ] `rakun routes` lists an rsocket route from 92's fixture beside the HTTP routes, labelled

### Step 3 — `ws generate` and the boundary (93, R88-6)

- [ ] `rakun ws generate fixtures/rates.wsdl out/` writes the files 93's generator produces, prints them, exits 0; a WSDL with a network `xsd:import` exits 1 with 93's refusal text
- [ ] the boundary table below is in `AGENTS.md` § CLI; R88-6 ticks when `07-onze/50-onze-cli/README.md` carries the mirror (onze's step — the source is here)

| | `rakun` (this front) | `onze` (onze 50) |
|---|---|---|
| Project shape | a BEAM server: controllers, services, data | a full-stack app: routes, server components, a client bundle |
| `new` / `create` | `rakun new` — server only | `onze create` — server plus client |
| Dev loop | `rakun run --watch`, hot-loading BEAM modules | `onze dev` — the browser, the bundler, and rakun's run path underneath |
| Build | `rakun build` — an OTP release | `onze build` — the release plus the client bundle |
| Owns the browser | never | always |

### Step 4 — R88-5

- [ ] `command_decorator_test.bp`'s load-time refusal across types stays the cell; the box ("two commands claiming the same name fail at comptime, naming both declarations") is open on lg2-j and says so; when lg2-j is answered "no", it is reworded to the load-time refusal and ticked

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cli`.

Blast radius: the manifest gains `rakun-client` (`rakun-cli` is depended on by nothing; update
[`../modules.md`](../modules.md) in the same commit); `beans`' output gains a column — `inspect_test.bp`
re-records.
