# Front 80 — rakun DevTools

**Track:** B rakun
**Priority:** high — without it every source edit costs a full server restart, on the one runtime where that is unnecessary; the developer-experience gap here is larger than the Spring one it ports
**Target:** erlang (server)
**Wave:** 2
**Depends on:** 04 (the registry the reload has to invalidate), 05 (profiles, and the property source a global settings file merges into), 01 (`fs`, `path`, `process`, `clock`)
**Owns:** `modules/rakun-devtools/botopink.json`, `modules/rakun-devtools/src/**` · `modules/rakun-devtools/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. It reads front 04's registry through the `rk*` cells and adds none of its own to `src/runtime.bp`
**Reference:** `02-desenvolvendo-com-spring-boot.md § Developer Tools (DevTools)` (all sub-sections) · `01-primeiros-passos.md § Executando o Exemplo · Debug Remoto` · `05-data.md § H2 Web Console` · <https://docs.spring.io/spring-boot/reference/using/devtools.html>
**Replaces:** new — proposed by the Spring Boot 4 coverage audit, § 2 `NN-rakun-devtools`, plus the fold-in rows *Remote debugging / tracing attach*, *DevTools global settings file* and *H2 console equivalent*

---

## Problem

Editing a rakun source file today means stopping the server and starting it again. Everything the
running process knew — the component scan list, the singleton cache, the property map, the route
table, any open connection — is discarded and rebuilt, and the developer waits. That is the JVM
bargain, and Spring DevTools exists to make it cheaper: two classloaders, one for third-party code
that rarely changes and one for application code that changes constantly, so a "restart" reloads only
the second.

The BEAM does not need that bargain. `code:load_file/1` replaces a module in a running node while
processes keep running, connections keep their sockets, and ETS tables keep their rows. Hot code
loading is thirty years old, it is how every Erlang system has been developed and operated, and rakun
currently uses none of it. The port is not "reproduce DevTools on BEAM" — it is "DevTools is the
weaker version of something the BEAM already has, so ship the stronger one."

There are three smaller absences behind it. Spring flips six properties when the devtools dependency
is present, so a developer gets useful error bodies and disabled caches without asking; rakun has no
such profile-driven default set. Spring reads a global settings file from the home directory so a
developer's preferences follow them between projects; rakun's configuration starts and ends at the
project. And Spring ships the H2 console so a developer can look at the database without leaving the
application; rakun ships nothing, and the actuator (front 11) is deliberately not that.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-devtools/` | does not exist — this front creates it, `botopink.json` and `src/root.bp` included |
| Hot code loading | nothing in rakun calls `code:load_file/1`, `code:load_binary/3` or `nl/1` |
| A file watcher | nothing. `libs/std/src/fs.bp` has `stat(path) -> @Result<FileStat, string>` and `list(path) -> @Result<string[], string>`, which is enough to poll |
| The registry a reload must invalidate | front 04's four ETS tables: scan list, singleton cache, property map, route table. `rkRegisterRoute` **appends** — `runtime.mjs:113-121` — so reloading a controller twice registers its routes twice |
| Dev-profile defaults | front 05 delivers profiles; no front delivers a default set that a module's presence switches on |
| Global configuration | front 05's search locations are project-relative (`1.0.6-beta` F02 notes "cwd-only for now") |
| A database browser | nothing, and front 08 has no read-only query path |
| Tracing | `libs/std/src/beam.bp` exposes the process dictionary, ETS and `persistent_term`; no `dbg`, no `recon` |

The route-table detail is the one that decides the design. A reload that only calls `code:load_file/1`
leaves rakun with a doubled route table and a stale singleton, and the developer sees their old code
answer every second request. Hot loading the module is the easy half; invalidating what the module
registered is the front.

## Mechanism

### Why hot loading, and what it actually guarantees

The BEAM holds two versions of a module: *current* and *old*. A load makes the incoming version
current and the previous one old; a second load purges the old one, killing any process still
executing it. A process picks up new code at its next **fully-qualified** call (`m:f(…)`); a process
sitting in a local loop keeps running the code it started in until it makes one.

For rakun that lands well, because every request is a fresh process that starts at a
fully-qualified dispatch call. A request in flight finishes on the code it started with; the next
request uses the new code. No connection is dropped and no state is lost. The one case that needs a
word is a long-lived process of the application's own — a scheduler worker from front 16, a message
listener from front 15. Those keep old code until they make an external call, which is BEAM
semantics and not something this front will hide.

### The reload sequence

A reload is five steps, and the middle three are the front:

```
1. watcher sees mtime change under a source root      fs.stat, polled
2. compile the changed module                          botopink CLI, child process
3. drop what the old module registered                 ← the front
     routes whose owner is this module
     singletons whose defining module is this module
     scan-list entries for this module
4. code:load_file/1 the new module                     ← the front
5. re-run the module's `@emit`ted registration         ← the front
```

Step 3 is where the correctness lives. Front 04's route table is append-only and its singleton cache
is keyed by type name; without a prior drop, step 5 doubles the table and leaves a singleton built
from code that no longer exists. The front therefore adds three cells to *its own* module — front 04's
`src/runtime.bp` is not touched — that reach the same ETS tables by name:

| Cell | What it does |
|---|---|
| `rkDevDropModule(module) -> i32` | Deletes every route, singleton and scan entry tagged with that module; answers the number of rows removed |
| `rkDevLoad(module, beamPath) -> i32` | `code:load_file/1`, then `code:soft_purge/1` on the old version; answers `1` when a process was still running old code and the purge was deferred |
| `rkDevOwner(module) -> string` | Reads back the rows tagged with a module, so a test can assert step 3 without reading ETS directly |

Tagging a row with its owning module is the part the language cannot do for us — see *Language gaps*.

### Why polling, and at what cost

OTP has no built-in filesystem-event interface. `inotify` needs a port program, which means a
dependency in the release and a second implementation for macOS. A poll of the source roots with
`fs.stat` costs one `stat` per file per interval; a rakun project with 400 source files at the
default 300 ms interval is roughly 1,300 `stat` calls a second, which is nothing next to the compile
that follows a change. The interval is configuration, and the watcher never runs outside a dev
profile, so there is no production cost to weigh at all.

### Dev defaults: the six-row table, translated

`02 § Propriedades Automaticas em Desenvolvimento` lists six properties Spring flips. Four have a
rakun meaning, two do not:

| Spring property | rakun analogue | Why |
|---|---|---|
| `spring.thymeleaf.cache=false` | `rakun.cache.enabled=false` | Front 12's global disable; the template cache has no rakun twin, the render cache does |
| `spring.h2.console.enabled=true` | `rakun.devtools.db-console.enabled=true` | Step 6 |
| `spring.web.resources.cache.period=0` | `rakun.web.static.cache-seconds=0` | Front 82's per-root cache policy |
| `spring.web.error.include-message=always` | `rakun.web.error.include-message=always` | Front 07's problem-detail toggles |
| `spring.web.error.include-stacktrace=always` | `rakun.web.error.include-stacktrace=always` | Front 07 |
| `management.tracing.sampling.probability=1.0` | `rakun.observability.sampling=1.0` | Front 75 |

They are applied as a property source that sits **below** every other source, so an explicit value in
`application.yaml` or an environment variable still wins. A default that cannot be overridden is not
a default.

### Remote development, and the security posture

`nl/1` loads a module on every connected node. That is the remote-application feature, and it is one
`erl -remsh` away from being a remote code-execution endpoint, which is why Spring's own
documentation carries a warning about it. The rules here are stricter than Spring's, per the project's
standing principle that the most restrictive behaviour wins and there is no knob to get around it:

- Remote loading is refused unless a dev profile is active **and** `rakun.devtools.remote.secret` is
  set explicitly. There is no default secret and no "generate one for me".
- The secret is compared with a constant-time comparison, because a timing oracle on a shared secret
  is a real attack and the comparison costs nothing.
- Remote loading is refused when the listener it would be reached over is not TLS (front 74).
- There is no property that disables these checks. An application that wants remote loading on a
  production profile does not get it.

### Debugging: `erl -remsh` in place of a JDWP agent

`01 § Debug Remoto` describes attaching a JVM debugger over a socket. The BEAM equivalent is better
and needs no feature at all: a named node with a cookie accepts `erl -remsh`, and the attached shell
is a full REPL inside the live system with `recon_trace` and `dbg` available. This front's deliverable
is therefore documentation plus one guard rail: a `traceCalls(module, fn, limit)` helper that wraps
`recon_trace:calls/2` with a **mandatory** message limit, so a trace on a hot function cannot flood
the node — the classic way to take a production BEAM down with a debugging tool.

## Steps

### Step 1 — The module, its settings, and their precedence

`modules/rakun-devtools/` is created here. `DevtoolsSettings` is a record; three sources merge into
it, lowest first: built-in defaults, the global file at `$HOME/.config/rakun/devtools.yaml`, then
project configuration from front 05.

```bp
pub type DevtoolsSettings(
    roots: string[],
    exclude: string[],
    triggerFile: string,
    pollMs: i32,
    enabled: bool,
    remoteSecret: string,
    dbConsole: bool,
)
```

**Acceptance:**
- [ ] With no files anywhere, `settings()` answers the documented defaults: roots `["src"]`, poll 300 ms, enabled `true`, trigger file `""`, remote secret `""`, db console `false`
- [ ] A value set only in the global file is used
- [ ] A value set in both files takes the project's
- [ ] A value set in the global file, the project file and an environment variable takes the environment variable — devtools settings do not escape front 05's priority order
- [ ] A malformed global file is a named warning at boot and the defaults stand; it is not a boot failure, because a developer's home directory must not be able to break a colleague's checkout

### Step 2 — The watcher

A supervised process polling the source roots. Excludes are glob patterns matched against the
project-relative path. With a trigger file configured, changes accumulate and are applied only when
the trigger file's mtime moves.

**Acceptance:**
- [ ] Touching a file under a root produces exactly one reload, not one per `stat`
- [ ] Two files changed inside one interval produce one reload cycle covering both
- [ ] A file matching an `exclude` pattern produces none
- [ ] With a trigger file configured, changing a source file produces none until the trigger file is touched, and then produces one covering every accumulated change
- [ ] The watcher does not start when no dev profile is active, and `enabled=false` stops it in a dev profile
- [ ] Killing the watcher restarts it with no reload and no duplicated registration

### Step 3 — Compile and load

The changed module is compiled by a child process (`std/process`, front 01) running the botopink CLI
for the erlang target, and the resulting module is loaded. A compile failure reports the compiler's
own error text and leaves the running code exactly as it was.

**Acceptance:**
- [ ] A successful edit is serving new behaviour on the next request, with no process restart
- [ ] A compile error leaves the previous version answering requests, and the error text reaches the console unmodified
- [ ] A reload during an in-flight request lets that request finish on the code it started with
- [ ] An open keep-alive connection survives a reload
- [ ] A second reload within the purge window reports that a process was still running old code rather than killing it silently

### Step 4 — Invalidating what the old module registered

`rkDevDropModule` before the load, re-registration after. The route table has the same contents after
a no-op reload as before it, which is the single assertion that proves this step.

**Acceptance:**
- [ ] Reloading an unchanged controller twice leaves `rkRouteCount()` unchanged
- [ ] Reloading a controller whose route path changed leaves exactly one route, the new one
- [ ] Reloading a `#[service]` discards its cached singleton, and the next resolution runs the new constructor — `rkBuildCount` increments
- [ ] A singleton *injected into* a component that was not reloaded is rebuilt too, or the front documents precisely why it is not
- [ ] `rkDevDropModule` on a module that registered nothing answers 0 and changes nothing

### Step 5 — Dev property defaults

The six-row table above, applied as the lowest-priority property source when this module is present
and a dev profile is active.

**Acceptance:**
- [ ] With the module present and the `dev` profile active, `rkProp("rakun.web.error.include-message")` reads `always`
- [ ] With the same setup and `rakun.web.error.include-message: never` in `application.yaml`, it reads `never`
- [ ] With the module present and no dev profile, none of the six is applied
- [ ] Removing the module from the manifest removes all six, with no other change to the application

### Step 6 — The dev-profile database console

A read-only query endpoint at `/devtools/db`, the H2-console analogue, over front 08's datasource.

**Acceptance:**
- [ ] The endpoint is not registered at all outside a dev profile — it answers 404 because it does not exist, not 403
- [ ] A `SELECT` runs and renders its rows
- [ ] An `INSERT`, `UPDATE`, `DELETE` or `DROP` is refused with a message naming the statement kind; the check is a parse of the statement, not a substring search
- [ ] The connection it uses is the application's datasource, so a query sees the same schema the application sees
- [ ] A query is bounded by a row cap and a timeout, both configuration, both with finite defaults

### Step 7 — Remote loading and tracing

`nl/1`-based remote load behind the four guards above, and `traceCalls` with its mandatory limit.

**Acceptance:**
- [ ] Remote loading is refused with a named reason when no dev profile is active
- [ ] Refused when `rakun.devtools.remote.secret` is unset or empty
- [ ] Refused when the transport is not TLS
- [ ] A wrong secret is refused, and the comparison is constant-time
- [ ] There is no configuration key that bypasses any of the four checks — asserted by a test that greps the module's own property table
- [ ] `traceCalls` without a limit does not compile; with one, the trace stops itself at the limit
- [ ] `repository/rakun/AGENTS.md` documents `erl -remsh` as the debugging path and names the cookie and node-name settings it needs

## Examples

- [`examples/dev-loop-example.bp`](./examples/dev-loop-example.bp) — the dev entry point a developer
  writes, the settings record behind it, and the assertions that make "the reload did not double the
  route table" a test rather than a hope.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `@Decl` carries no module or source identity: a decorator cannot learn which module the declaration it annotates lives in. Every registration row therefore has to be tagged by hand for the reload to know what to drop. | `examples/dev-loop-example.bp`, the `#[devReloadable("orders")]` argument — it exists only to repeat a name the compiler already knows | Pass the module name as a decorator argument and accept that a rename desynchronises it | `decl.module()` (or `decl.source()`, as front 22 proposes for the same gap) so `#[devReloadable]` is bare and cannot be wrong |
| A decorator body cannot call a sibling function: `decorator_eval` emits only the decorator function into the eval script, so shared validation has to be copy-pasted, exactly as `src/decorators.bp:44-46` records for rakun's own six component decorators. | Not visible in the example — it shapes the front's internals, where `#[devReloadable]` duplicates the placement check every other rakun decorator duplicates | Inline the helper into every decorator body | Emit the module's other top-level functions alongside the decorator, or a declared `comptime` import set for the eval script |

## Test plan

`modules/rakun-devtools/test/`, run with `botopink test --target erlang` from
`modules/rakun-devtools/`, and in the gate as `zig build test-libs -- --target erlang --lib rakun`.

Two of the seven steps are awkward to test and are worth naming. The watcher is tested against a
temporary directory under `.botopinkbuild/tmp/` with mtimes moved explicitly rather than by sleeping,
so the suite has no timing flake and no wall-clock cost. The reload itself is tested by loading two
compiled versions of a fixture module that this front ships pre-built — the test does not invoke the
compiler, because a test that shells out to the toolchain is testing the toolchain.

The security guards in step 7 are tested by assertion on refusal: four tests that each disable one
guard's precondition and assert the refusal and its reason string. The "there is no bypass key" test
reads the module's own property table and asserts no key matching `*.disable*` or `*.insecure*`
exists — a test that fails if somebody later adds the escape hatch.

This front is erlang-only, and pointedly so: hot code loading has no commonJS meaning, and a JS build
of this module would be an empty shell that claims a feature it cannot have.

## Definition of done

- [ ] `modules/rakun-devtools/` exists with its manifest, its `root.bp` and its module tree
- [ ] A source edit is answered by new code on the next request, with no restart, no dropped
      connection and no doubled route
- [ ] Settings merge in the documented order, with the global home-directory file below project
      configuration
- [ ] The six dev defaults apply below every other property source and are absent without the module
- [ ] The database console exists only under a dev profile and refuses every non-`SELECT`
- [ ] Remote loading carries all four guards and no bypass
- [ ] `repository/rakun/AGENTS.md` documents the reload sequence and the `erl -remsh` debugging path
- [ ] The front's tests are green on its assigned target
