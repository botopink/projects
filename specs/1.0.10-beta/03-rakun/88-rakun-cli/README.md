# Front 88 — Rakun CLI

**Track:** B rakun
**Priority:** medium — it is the first thing anyone touches, and today starting a rakun project means copying an example directory and editing it by hand
**Target:** erlang (server) — the CLI itself ships as an escript
**Wave:** 7
**Depends on:** 81 (the release builder `rakun build` delegates to, and the escript that packages this CLI), 05 (profiles and the configuration reader), 80 (the file watcher behind `rakun run --watch`), 06 (the exit-code hook the inspect commands return through), 04 (the BEAM runtime every generated project stands on), 01 (`process`, `path`)
**Owns:** `modules/rakun-cli/src/**`, `modules/rakun-cli/templates/**`, `modules/rakun-cli/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. It does not write to `repository/onze/` either; front 50 owns that CLI and this one never reaches across.
**Reference:** `12-upgrading.md § Spring Boot CLI` · `01-primeiros-passos.md § Executando o Exemplo` (Via IDE, Via Linha de Comando, Com Maven, Com Gradle) · `11-topicos-avancados.md § Plugins de Build` · https://docs.spring.io/spring-boot/cli/index.html · https://docs.spring.io/spring-boot/maven-plugin/index.html

---

## Problem

There is no way to start a rakun project. `repository/rakun/examples/rakun/` exists and a developer's
first move today is to copy it, rename things, and find out later which of the renames mattered.
There is no way to run one either, other than knowing which module holds `Rakun.run` and invoking the
compiler by hand with the right target. There is no way to package one — that is front 81 — and no
way to ask a project a question without starting it, which is exactly when the question is urgent.

Spring covers this ground with three tools that look like one: the Spring Boot CLI
(`12-upgrading.md § Spring Boot CLI`), the Maven plugin (`mvn spring-boot:run`,
`spring-boot:build-image`) and the Gradle plugin (`gradle bootRun`), all reached from a shell and all
doing project-shaped work. The milestone's audit puts the build-tool goals here rather than treating
them as JVM tooling, because the *commands* are not JVM-specific even though Maven and Gradle are.

**This is rakun's CLI, not onze's.** Front 50 delivers `onze`'s CLI — `create`, `dev`, `build`,
`start` — for a full-stack application that serves HTML from BEAM and ships a JavaScript bundle to a
browser. This front delivers `rakun`'s: scaffolding, running, building and inspecting a *server*
project, with no browser, no bundler and no client output. The two are not layered by accident and
the boundary is written down in step 7 rather than discovered when both are installed.

## Current state

- `repository/rakun/modules/` holds thirteen module stubs and no `rakun-cli`. The directory this
  front owns does not exist yet.
- `repository/rakun/examples/rakun/` is the only starting point that exists, and it is an example,
  not a template — it has no substitution points and no manifest generation.
- `repository/rakun/src/bootstrap.bp:28-37` — `Rakun.run(app)` calls `rkServe` and blocks. There is
  no mode in which the container wires itself, answers a question and exits; the inspect commands
  below need one, and it is a boot-mode flag, not a new entry point (the file is frozen, so the flag
  is read by front 04's runtime, not added to `bootstrap.bp`).
- `libs/std/src/env.bp:44` — `env.args() -> string[]` exists today, so argv needs no new primitive.
- `libs/std/src/fs.bp:33-99` — `readText`, `writeText`, `exists`, `list`, `mkdir`, `copy` all exist,
  which is the whole filesystem surface scaffolding needs.

## Mechanism

The CLI is an ordinary botopink program compiled to erlang and packaged as an escript by front 81 —
the same way `rebar3` and `mix` ship. It reads `env.args()`, dispatches on the first argument, and
returns an exit status. Nothing about it is special-cased by the compiler.

**The command table is a value.** Each command is a record holding a name, a one-line summary, a
usage string and a function from arguments to an exit code. Dispatch is a lookup, `rakun help` is a
render of the same table, and an unknown command prints the table and exits 2. A table that is data
rather than a `case` is what makes `#[cliCommand]` in step 6 possible: a plugin command appends a
row.

**Exit codes are part of the contract, because CI reads them.**

| Code | Meaning |
|---|---|
| 0 | the command did what it said |
| 1 | the command ran and the work failed (tests red, release build failed, app exited non-zero) |
| 2 | usage error — unknown command, missing argument, bad flag |
| 3 | the project did not compile |

Code 3 is separate from code 1 deliberately: "your code does not build" and "your tests fail" are
different answers and a CI pipeline routes them differently.

**Scaffolding is a runtime file copy with a substitution pass.** Templates live under
`modules/rakun-cli/templates/<variant>/` as real files, read with `fs.readText` and written with
`fs.writeText`. Placeholders are spelled `@@name@@` and not `${name}` — `${…}` is botopink's string
interpolation, so a template file containing it could not be held in a test fixture or a string
literal without fighting the lexer. The three variants are `plain` (a service), `full-stack` (a
project whose dev command is `onze dev`, generated only when onze is available) and `library` (a
module with no `Rakun.run`).

**The inspect commands boot the application and stop before it listens.** `rakun routes`,
`rakun beans` and `rakun config` need the registries that comptime `@emit` builds — the route table
comes from `#[getMapping]` emissions, the bean list from `#[service]`/`#[component]` emissions — and
those exist only after the registration pass runs. So the CLI compiles the project, starts the node
with `rakun.main.mode=inspect`, lets front 04's runtime run the registration pass, prints the
requested table, and exits through front 06's exit-code hook *before* any listener binds, any pool
connects or any broker is dialled. That ordering is the whole value: these commands answer questions
about an application that cannot start, because everything that makes it fail to start happens after
the point where they stop.

**`rakun run` is a thin wrapper and says so.** It resolves the profile, sets
`rakun.profiles.active`, and starts the same boot path a release uses. With `--watch` it additionally
starts front 80's watcher, which recompiles and hot-loads changed modules without restarting the
node. Without front 80 present, `--watch` is a usage error rather than a silent no-op.

**`rakun build` and `rakun test` delegate.** `build` calls front 81's release builder and forwards
its exit status; `test` shells out to `botopink test --target <t>` through std's `process` module and
forwards the runner's status. Neither reimplements what it calls, and both say in `--help` which tool
they are a front end for. `rakun test` defaults to the erlang target, because a rakun project is a
server.

**Target.** The CLI runs on BEAM as an escript. It holds no `@External.Node` cell: filesystem access
is std's `fs`, subprocesses are std's `process`, argv is std's `env`.

## Steps

### Step 1 — Argv, the command table, and exit codes

```bp
pub type Command(
    name: string,
    summary: string,
    usage: string,
)

pub fn flagValue(args: Array<string>, name: string, fallback: string) -> string
pub fn hasFlag(args: Array<string>, name: string) -> bool
pub fn commandOf(args: Array<string>) -> string
```

**Acceptance:**
- [ ] `commandOf([])` is `""` and the CLI prints the table and exits 2.
- [ ] `flagValue(["run", "--profile", "dev"], "--profile", "default")` is `"dev"`; with the flag absent it is `"default"`; with the flag last and no value it is a usage error, not the fallback.
- [ ] `--profile=dev` and `--profile dev` both parse to `"dev"`.
- [ ] `hasFlag` is true only for an exact match, so `--watchdog` does not enable `--watch`.
- [ ] Every command in the table has a non-empty summary and usage, asserted by a test that walks the table.

### Step 2 — `rakun new`

```
rakun new <name> [--template plain|full-stack|library]
```

**Acceptance:**
- [ ] `rakun new orders` creates `orders/botopink.json`, `orders/src/main.bp`, `orders/application.yaml`, a health endpoint and one passing test.
- [ ] `botopink test --target erlang` in the generated project is green with no edits — the scaffold is verified by running it, not by counting files.
- [ ] Every `@@name@@` in every template file is substituted; a test greps the generated tree for `@@` and fails on a hit.
- [ ] `rakun new orders` into an existing non-empty `orders/` refuses and exits 2 rather than merging.
- [ ] `--template library` generates no `Rakun.run` and no listener configuration.
- [ ] `--template full-stack` generates a project whose documented dev command is `onze dev`, and refuses with a usage error when onze is not available.

### Step 3 — `rakun run`

```
rakun run [--profile <name>] [--watch] [--port <n>]
```

**Acceptance:**
- [ ] The active profile reaches front 05 and a `#[value]` binding in the running app reflects it.
- [ ] `--port` overrides the configured port, and the precedence matches front 05's documented order (CLI above environment above file).
- [ ] `--watch` without front 80 present is a usage error naming the missing module.
- [ ] With `--watch`, editing a source file reloads the module and an in-flight connection is not dropped — the same assertion front 80 makes, made again from the CLI's side.
- [ ] SIGTERM reaches the graceful-shutdown path rather than killing the node.

### Step 4 — `rakun build` and `rakun test`

**Acceptance:**
- [ ] `rakun build` produces the artefact front 81 defines and exits 0; a failed build exits 1 with the builder's message unmodified.
- [ ] `rakun test` defaults to `--target erlang`, forwards `--filter`, and returns the runner's exit status unchanged.
- [ ] Neither command reimplements its delegate: a test asserts the subprocess is invoked, rather than asserting on its output.
- [ ] A project that does not compile exits 3 from both.

### Step 5 — `rakun routes`, `rakun beans`, `rakun config`

**Acceptance:**
- [ ] All three complete on a project whose database URL is wrong — no pool is opened before the answer is printed.
- [ ] `rakun routes` prints one line per registered route with verb, path and handler, sorted by path, and the count matches `rkRouteCount()`.
- [ ] `rakun beans` prints one line per registered component with its type and the fields it is injected from.
- [ ] `rakun config` prints the resolved configuration with the active profiles and, for each key, the source that won — and applies front 76's sanitization, so a password is masked in a terminal exactly as it is in the endpoint.
- [ ] Each command exits 0 on success and 3 when the project does not compile; none of them binds a port, asserted by running two of them at once.

### Step 6 — Plugin commands

```bp
#[cliCommand("seed")]
pub fn seed(self: Self, args: Array<string>) -> i32 { … }
```

**Acceptance:**
- [ ] `#[cliCommand]` on anything but a method fails with a located message.
- [ ] The annotated method appears in `rakun help` with its summary, and `rakun seed` runs it.
- [ ] It runs in inspect mode with the container wired, so it may inject a repository and may not assume a listener.
- [ ] Its return value is the process exit code, and a raise becomes exit 1 with the reason printed.
- [ ] Two commands claiming the same name fail at comptime, naming both declarations.

### Step 7 — The boundary with front 50

| | `rakun` (this front) | `onze` (front 50) |
|---|---|---|
| Project shape | a BEAM server: controllers, services, data | a full-stack app: routes, server components, a client bundle |
| `new` / `create` | `rakun new` — server only | `onze create` — server plus client |
| Dev loop | `rakun run --watch`, hot-loading BEAM modules | `onze dev` — the browser, the bundler, and rakun's run path underneath |
| Build | `rakun build` — an OTP release | `onze build` — the release plus the client bundle |
| Owns the browser | never | always |

The rule: when both are installed, `onze` is the entry point and drives rakun's run path; rakun
never starts a bundler, never writes client output, and never becomes a dependency of front 50's
CLI in the other direction. A `--template full-stack` project documents `onze dev` as its dev
command precisely so that two tools do not both claim the dev loop.

**Acceptance:**
- [ ] `modules/rakun-cli/` contains no bundler, no asset pipeline and no reference to `repository/onze/`.
- [ ] `rakun help` states in one line which CLI to use for a full-stack project.
- [ ] Front 50's README carries the mirror of the table above; if it does not, this front's exit is blocked until it does.

## Examples

- [`examples/scaffolded-app-example.bp`](./examples/scaffolded-app-example.bp) — what
  `rakun new orders` produces: the generated `main.bp`, and the one test it ships with.
- [`examples/cli-command-example.bp`](./examples/cli-command-example.bp) — a project adding its own
  `rakun seed` command, plus the argv parsing the CLI itself is built from.

## Language gaps

None — every construct in the examples parses today.

One design note that is *not* a gap and is easy to mistake for one: template files use `@@name@@`
rather than `${name}` because `${…}` is string interpolation in botopink
(`tests/language/test/expr_sugar.bp:14-17`), and a template fixture written into a test would be
interpolated rather than copied. The language behaves correctly; the placeholder syntax moves.

## Test plan

`modules/rakun-cli/test/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/args_test.bp` | Flag parsing in both spellings, missing values, exact-match flags, empty argv |
| `test/table_test.bp` | Every command has a summary and usage, names are unique, `help` renders them all |
| `test/scaffold_test.bp` | Generated tree for each variant, no leftover `@@`, refusal on a non-empty directory |
| `test/inspect_test.bp` | Routes and beans match the registry counts, no port bound, exit codes 0 and 3 |
| `test/command_decorator_test.bp` | Placement failure, registration, duplicate-name failure, exit code from the return value |

`scaffold_test.bp` generates into a scratch directory under `.botopinkbuild/tmp/` and runs
`botopink test --target erlang` inside it — the scaffold's guarantee is that it runs, so the test
runs it. That makes this the slowest cell in the module, and it is worth the seconds.

There is no commonJS row. The CLI ships as an escript on BEAM by the milestone's target split.

## Definition of done

- `modules/rakun-cli/` exists with `src/`, `templates/` and `test/`, and is packaged as an escript by front 81.
- The eight commands (`new`, `run`, `build`, `test`, `routes`, `beans`, `config`, `help`) exist, and each is in the table with a summary and usage.
- A freshly scaffolded project passes its own tests with no edits, asserted by CI and not by inspection.
- The three inspect commands answer on a project that cannot boot, proven by a test with a deliberately unreachable database.
- The boundary table in step 7 appears in both this README and front 50's.
- `repository/rakun/AGENTS.md`, `modules/README.md` and the repository README record the commands in the same commit.
- The front's tests are green on erlang.

