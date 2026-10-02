# Front 88 — rakun CLI

**Priority:** medium — the last front of the track: it consumes 81's booting release, 93's generator, 92's registry and 04's scan registry, and none of its boxes can close before them
**Carries:** —
**Depends on:** `81-rakun-packaging-release` step 1 (R88-2 needs a failing release build to have a message) · `93-rakun-soap-webservices` step 2 (the generator library the `ws generate` command wraps) · `92-rakun-rsocket` (R92-6: `rakun routes` lists rsocket routes from 15's registry) · `04-rakun-erlang-runtime` step 4 (`rkScannedDeps` for R88-3) · the toolchain row re-measure (73) for R88-1 · compiler lg2-j (R88-5 stays open) · onze 50 (R88-6, onze's file)
**Owns:** `modules/rakun-cli/**` (incl. `templates/**`) except 81's `src/release/**`, `test/release/**` and `src/sidecars/rakun_release.erl` — decision 187 merges `rakun-release` into this member (front 128), and `botopink.json` / `src/root.bp` are 81's until it lands (the lower number) · `repository/rakun/AGENTS.md` § CLI
**Does not touch:** 81's release files · `rakun-client/src/ws/**` (93's — `rakun-ws` / `rakun-soap` below read as it; the `ws generate` command adds a `rakun-client` dependency, not `rakun-soap`) · `rakun-messaging/src/rsocket/**` (92's), the core · `repository/onze/**`

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/88-rakun-cli/README.md`) | Box, as written |
|---|---|---|
| R88-1 | § Step 3 — `rakun run` | "The active profile reaches front 05 and a `#[value]` binding in the running app reflects it. — open: `rakun run` sets `RAKUN_PROFILES_ACTIVE` and runs `botopink run`, and a built erlang program cannot load its sidecars (toolchain row), so no running app is asserted" · "`--port` overrides the configured port, and the precedence matches front 05's documented order (CLI above environment above file). — open: `--port` becomes `RAKUN_SERVER_PORT` …; not asserted against a running app" · "With `--watch`, editing a source file reloads the module and an in-flight connection is not dropped — … — open: needs a running app" · "SIGTERM reaches the graceful-shutdown path rather than killing the node. — open: needs a running app" |
| R88-2 | § Step 4 — `rakun build` and `rakun test` | "`rakun build` produces the artefact front 81 defines and exits 0; a failed build exits 1 with the builder's message unmodified. — open: the artefact and exit 0 hold …; a failing release build (exit 1, the message unmodified) is not asserted" |
| R88-3 | § Step 5 — `rakun routes`, `rakun beans`, `rakun config` | "`rakun beans` prints one line per registered component with its type and the fields it is injected from. — open: … the scan registry records the name only, so the injected fields are not printed" |
| R88-4 | § Step 5 | "Each command exits 0 on success and 3 when the project does not compile; none of them binds a port, asserted by running two of them at once. — open: 0 and 3 hold …; two concurrent runs are not asserted" |
| R88-5 | § `#[cliCommand("seed")]` | "Two commands claiming the same name fail at comptime, naming both declarations. — open: within one type at build …; across types the refusal comes when the second registers at load" — stays open on lg2-j; the load-time refusal is the cell |
| R88-6 | § Step 7 — The boundary with front 50 | "Front 50's README carries the mirror of the table above; if it does not, this front's exit is blocked until it does. — open: `06-onze/50-onze-cli/README.md` does not carry the table - onze track's file" |
| R92-6 | `92-rakun-rsocket/README.md` § Step 5 | "The registration is visible in front 15's registry and in `rakun routes`. — open: … `rakun routes` lists HTTP routes only" |
| R93 (command) | `93-rakun-soap-webservices` § Step 3 — The generator | `rakun ws generate <wsdl> <out>` — the CLI command over 93's generator library (the closed `modules.md`: "`rakun-cli` gets a `rakun soap:generate` command that depends on `rakun-soap`'s schema reader; a library does not depend on the CLI") |

## Problem

`rakun run` sets two environment variables and calls `botopink run`; nothing asserts that the app
it starts read them, reloaded, or drained on SIGTERM, because when the front closed no built app
ran. `rakun beans` prints names. `rakun routes` does not know rsocket routes. There is no
`ws generate`.

## Current state

`modules/rakun-cli`: `src/{args,plugins,cli}.bp`, `templates/{plain,library,full-stack}`, 4 test
files, 25 tests green; the tests drive the compiler through `BOTOPINK_BIN` under
`BOTOPINK_TEST_TMPDIR` (`inspect_test.bp:10-16`, `scaffold_test.bp:11-17`). The manifest depends on
`rakun`, `rakun-actuator`, `rakun-release` (not `rakun-devtools`: `--watch` is `botopink run`'s
watcher).

## Mechanism

- R88-1: after 73's re-measure shows `botopink run` serves, each box is a child-process cell: start
  `rakun run --profile test --port 0` on a scaffolded app whose `#[value("rakun.profiles.active")]`
  handler answers it; read the bound port from the port file (04's boot options); assert over the
  socket; `--watch` edits a file and re-requests; SIGTERM and the exit code.
- R88-2: `rakun build` on a project whose sidecar does not compile (81 step 1's refusal) exits 1
  and the stderr equals the builder's message.
- R88-3: `rkScannedDeps(name)` (04 step 4) — `beans` prints `name type [deps…]`.
- R92-6: `routes` reads 15's registry tagged `rsocket` beside the HTTP table.
- `ws generate`: `plugins.bp` registers the command; it calls `rakun-soap`'s `generate(wsdlPath,
  outDir)` (93) and prints the file list; the manifest gains `rakun-soap`.

## Gate stance

Every cell is a child process of the compiler or of the scaffolded app under the scratch
directory; no env variable but `BOTOPINK_BIN` (set by the runner) and no external service. R88-1's
four cells are written only after 73's re-measure passes; if it fails, they are not written and the
boxes stay open naming the toolchain row.

## Steps

### Step 1 — `rakun run` (R88-1)

**Acceptance:**
- [ ] `run_test.bp`: the profile reaches the app (`GET /profile` answers `test`); `--port` wins over `RAKUN_SERVER_PORT` wins over `application.yaml` (three runs, three ports)
- [ ] `--watch`: editing the scaffold's handler changes the answer within 2 s and a connection opened before the edit still answers
- [ ] SIGTERM to the child: the drain path runs (an in-flight request completes) and the exit code is 0

### Step 2 — Build and inspect (R88-2, R88-3, R88-4, R92-6)

**Acceptance:**
- [ ] `scaffold_test.bp`: a project with a broken sidecar makes `rakun build` exit 1 and print 81's message unmodified
- [ ] `inspect_test.bp`: `rakun beans` prints one line per component with its type and injected fields (`fixtures/` with a two-field component)
- [ ] two `rakun routes` runs started at once both exit 0 and neither binds a port (`ss -ltn` through the sidecar shows no new listener during the run)
- [ ] `rakun routes` lists an rsocket route from 92's fixture beside the HTTP routes, labelled

### Step 3 — `ws generate` and the boundary (93, R88-6)

**Acceptance:**
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

**Acceptance:**
- [ ] `command_decorator_test.bp`'s load-time refusal across types stays the cell; the box is open on lg2-j and says so; when lg2-j is answered "no", the box is reworded to the load-time refusal and ticked

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-cli`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § CLI updated
- [ ] commit on `fix/88-rakun-cli`

## Blast radius

The manifest gains `rakun-soap`; `rakun-cli` is depended on by nothing. `beans`' output gains a
column — `inspect_test.bp` re-records.

## Notes

The closed README's examples carry no open marker; nothing is copied.
