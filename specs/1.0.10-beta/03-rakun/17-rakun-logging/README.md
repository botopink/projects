# Front 17 — Rakun Structured Logging

**Track:** B rakun
**Priority:** low as a feature, high as a dependency — front 31's `error.digest` and every operator question about a running node route through it
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 03 (content hash, for the error digest), 05 (config and profiles), 06 (context), 11 (endpoint host), 62 (per-request context, for the correlation id)
**Owns:** `modules/rakun-logging/src/**`, `modules/rakun-logging/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `03-recursos-principais.md § Logging` (Formato · Niveis · Grupos · Output para Arquivo · Rotacao · Log Estruturado · Extensions) · https://docs.spring.io/spring-boot/reference/features/logging.html

---

## Problem

rakun logs with `@print`. There is no level, so nothing can be turned down in production and nothing
extra can be turned on in an incident. There is no structure, so a log line is a sentence rather than a
record and the only way to find anything is to grep for a substring someone happened to write. There is
no correlation, so two log lines from the same request cannot be shown to be from the same request. And
because there is no logger at all, a library like `rakun-data` cannot report a slow query without
printing to whatever the application's stdout happens to be.

## Current state

- `repository/rakun/modules/rakun-logging/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `repository/rakun/` — every diagnostic in the tree is `@print`. The decorators, the runtime and the bootstrap all emit nothing at all.
- `libs/std/src/time.bp:92` — `formatIso8601(epochMillis) -> string` already exists, so timestamps do not need a new primitive.
- `libs/std/src/` has no content-hash module; front 03 delivers it as `hash.contentHash` (decision 106) and the error digest is one of its first consumers.
- OTP's `logger` is present in every BEAM release and is what this front configures; nothing in rakun touches it today.

## Mechanism

### One logger type, five levels, and what they map to

```bp
pub type Level { Trace, Debug, Info, Warn, Error }

pub type Logger(name: string) {
    pub fn info(self: Self, message: string) -> i32
    pub fn infoWith(self: Self, message: string, fields: Array<#(string, string)>) -> i32
    // … the same pair for trace, debug, warn, error
    pub fn isEnabled(self: Self, level: Level) -> bool
}

pub fn logger(name: string) -> Logger
```

The backing is OTP `logger`. OTP has eight levels and rakun has five, so the mapping is stated rather
than inferred:

| rakun | OTP |
|---|---|
| `Trace` | `debug` |
| `Debug` | `debug` |
| `Info` | `info` |
| `Warn` | `warning` |
| `Error` | `error` |

`Trace` and `Debug` both land on OTP `debug`, which would collapse them — so rakun's own level check
runs **before** the call: a `Trace` record is discarded by `isEnabled` when the logger's level is
`Debug` and never reaches `logger:log/3`. The record that does reach it carries the rakun level in its
metadata, so a downstream handler can still tell them apart.

`isEnabled` exists so that an expensive message is not built for a level that is off. `infoWith` takes
its fields as a list rather than interpolating them into the message, because a structured log whose
fields are embedded in a sentence is an unstructured log with extra steps.

### Structured output

One JSON object per line, written by an OTP formatter module this front ships. Three schemas, matching
the reference (`03-recursos-principais.md § Log Estruturado`):

| `rakun.logging.structured.format.console` / `.file` | Schema |
|---|---|
| `ecs` (default) | `@timestamp`, `log.level`, `message`, `service.name`, `process.thread.name`, `log.logger`, `trace.id`, `error.digest` |
| `gelf` | `version`, `host`, `short_message`, `timestamp`, `level`, `_`-prefixed extras |
| `logstash` | `@timestamp`, `@version`, `message`, `logger_name`, `level`, `level_value` |
| `plain` | Spring's console line: timestamp, level, PID, `---`, app name, process, logger, message |

`plain` is the development default and is the one shape a human reads; the other three are for a
collector and are never pretty-printed. Field order within a schema is fixed, so two lines from the
same schema diff cleanly.

### Levels, groups and the two predefined groups

```
rakun.logging.level.root = info
rakun.logging.level.rakun.data = debug
rakun.logging.group.tomcat = …        # an application's own group
rakun.logging.level.web = debug       # a group name is usable wherever a logger name is
```

A level applies to a logger name and every name beneath it, longest prefix wins. A group is a name that
stands for a list of names; setting a level on the group sets it on every member. Two groups are
predefined, matching upstream (`03-recursos-principais.md § Grupos de Log`):

| Group | Members |
|---|---|
| `web` | `rakun.web`, `rakun.core.router`, `rakun.core.middleware`, `rakun.client` |
| `sql` | `rakun.data.sql`, `rakun.data.datasource`, `rakun.data.transaction` |

An application redefines either by naming it in `rakun.logging.group.web`; the predefined value is the
default, not a floor.

### Correlation

Every request gets an id. It is taken from the incoming `traceparent` or `x-request-id` header when one
is present and generated otherwise, stored on the request process by front 62's per-request context,
and attached to every record emitted while that request is in flight — `trace.id` in ECS, `_trace_id`
in GELF. A scheduled task (front 16) and a message listener (front 15) each get an id too, so a log
line from a background worker is as traceable as one from a handler.

`correlationId()` reads it; `withCorrelationId(id)` sets it, for the case where a worker continues work
begun by a request and should keep its id.

### `error.digest`

Next shows the browser a `digest` string and nothing else when a server render fails, so that a user
cannot read a stack trace and an operator can still find the exact failure
(`NEXTJS-DOCS.md § 14`, `error.digest?: string`). Front 31 owns the client half; the server half —
the scheme, the record, and the guarantee that the two agree — is here.

```bp
pub fn errorDigest(module: string, errorClass: string, message: string, topFrames: string) -> string
pub fn logErrorWithDigest(log: Logger, module: string, errorClass: string, message: string, topFrames: string) -> string
```

The digest is the first 16 hex characters of front 03's content hash over
`module + "|" + errorClass + "|" + message + "|" + topFrames`, where `topFrames` is the first three
stack frames with line numbers stripped.

What is deliberately **not** in the input: the timestamp, the request id, the node name, any argument
value. The digest identifies a *fault*, not an *occurrence* — the same bug hit by a thousand users
produces one digest, which is the only thing that makes it useful for grouping. It is not a secret and
not a token: it is derived from the source, so it is stable across nodes and across restarts of the
same build, and it changes when the code changes.

`logErrorWithDigest` writes one ERROR record carrying the full message, the frames and the digest, and
returns the digest for the renderer to put in the payload. The rule that makes this work is one
sentence and it belongs in `AGENTS.md`: **the digest is the only part of a server error that crosses to
the client.**

### File output and rotation

| Key | Default | Effect |
|---|---|---|
| `rakun.logging.file.name` | unset | Path to the log file; unset means console only |
| `rakun.logging.file.path` | unset | Directory; the file is `<path>/rakun.log` |
| `rakun.logging.file.max-size` | `10MB` | Rotate at this size |
| `rakun.logging.file.max-history` | `7` | Rotated files to keep |
| `rakun.logging.file.total-size-cap` | `100MB` | Delete oldest beyond this total |

Backed by OTP's `logger_std_h` file handler with its own rotation, so rotation is the runtime's job and
not a timer this front owns.

### External configuration

Spring reads `logback-spring.xml` with `<springProfile>` and `<springProperty>` elements. The BEAM
equivalent is `sys.config`, and it is profile-conditional the same way:
`rakun.logging.config = config/logging.sys.config` loads the file, and a `{profile, staging, [...]}`
section applies only when `staging` is among front 05's active profiles. A key set in `sys.config`
wins over the same key in `application.yaml`, and the startup summary says which file was loaded.

### The startup summary

One line when the application is ready, matching upstream's shape
(`03-recursos-principais.md § Formato do Log`):

```
2026-09-19T12:00:03.114Z  INFO <0.412.0> --- [billing] [main] rakun.core.Bootstrap : Started billing in 1.842s (process running for 2.011s) — port 8080, profiles [prod, metrics]
```

It carries the elapsed startup time, the OS PID and the BEAM node, the listening port, and the active
profiles. It is not decoration: "which profile is this node actually running" is the first question of
most incidents, and the answer should be in the log rather than in someone's memory of the deploy.

### Target

erlang. `logger` is an OTP application; every host cell in this module is `#[@External.Erlang]`.

## Steps

### Step 1 — Logger, levels and the resolver

**Acceptance:**
- [ ] `logger("rakun.data.sql").isEnabled(Level.Debug)` follows `rakun.logging.level.rakun.data`, and `rakun.logging.level.rakun.data.sql` overrides it — longest prefix wins.
- [ ] With no key set, `root` applies.
- [ ] A `Trace` record is discarded before `logger:log/3` when the level is `Debug`, and the OTP handler never sees it.
- [ ] `isEnabled` returns false without building the message — a test asserts the message-building closure was not called.
- [ ] Every host cell in the module is `#[@External.Erlang]`.

### Step 2 — Structured formatters

**Acceptance:**
- [ ] Each of `ecs`, `gelf`, `logstash`, `plain` produces its documented field set, in a fixed order, one line per record.
- [ ] A message containing a quote, a backslash, a newline or a control character round-trips through each JSON schema.
- [ ] Console and file may carry different formats at the same time.
- [ ] An unknown format name refuses the boot with the key and the four valid values named.

### Step 3 — Groups

**Acceptance:**
- [ ] `rakun.logging.level.web = debug` raises every member of the predefined `web` group.
- [ ] `rakun.logging.group.web = a,b` replaces the predefined membership entirely.
- [ ] A group name and a logger name that collide resolve to the group, and the boot logs that it did.
- [ ] `sql` is predefined with the three members listed above.

### Step 4 — Correlation

**Acceptance:**
- [ ] A request carrying `traceparent` reuses its trace id; one carrying `x-request-id` reuses that; one carrying neither gets a generated id.
- [ ] Every record emitted during a request carries the same id, including records from a `#[service]` three calls deep.
- [ ] A scheduled task and a message listener each get an id, and two concurrent runs get different ones.
- [ ] `withCorrelationId` propagates an id into a worker started by a request.
- [ ] Two concurrent requests never share an id.

### Step 5 — `error.digest`

**Acceptance:**
- [ ] The same fault raised twice produces the same digest.
- [ ] The same fault raised on two nodes of the same build produces the same digest.
- [ ] Changing the message changes the digest; changing only the timestamp, the request id or an argument value does not.
- [ ] `logErrorWithDigest` writes exactly one record, carrying the full message and frames, and returns the digest.
- [ ] A test asserts that the record the renderer hands the client contains the digest and contains neither the message nor any frame — this is the boundary and it is checked, not trusted.
- [ ] Front 31's client half renders the digest string this front produced; the two agree in a shared fixture rather than by convention.

### Step 6 — File output and external configuration

**Acceptance:**
- [ ] With `file.name` set, records reach the file and the console according to their two formats.
- [ ] Rotation happens at `max-size`, keeps `max-history` files, and deletes beyond `total-size-cap`.
- [ ] `rakun.logging.config` loads a `sys.config` and its keys win over `application.yaml`.
- [ ] A `{profile, staging, [...]}` section applies only when `staging` is active.
- [ ] The startup summary names the loaded configuration file, or says none was loaded.

### Step 7 — The `loggers` and `logfile` endpoints

```bp
// GET  /actuator/loggers            -> every configured logger and group, with its effective level
// GET  /actuator/loggers/{name}     -> one
// POST /actuator/loggers/{name}     -> set its level at run time, via logger:set_module_level/2
// GET  /actuator/logfile            -> the configured file, with Range support
pub fn loggersEndpoint(req: Request) -> Response
pub fn logfileEndpoint(req: Request) -> Response
```

Both are defined here and hosted by front 11. `POST /actuator/loggers/{name}` changes the running
system and `GET /actuator/logfile` serves whatever the application has written — which may include
anything an application logged — so both sit behind front 11's access control with no separate opt-out
in this module. Front 11 decides who may reach `/actuator`; this front does not get a second answer.

**Acceptance:**
- [ ] `POST /actuator/loggers/rakun.data` with `{"level":"debug"}` takes effect on the next record, with no restart.
- [ ] Setting a level on a group sets it on every member.
- [ ] A level reset (`null`) returns the logger to its inherited level.
- [ ] `GET /actuator/logfile` honours `Range` and returns 206 with `Content-Range`; it returns 404 when no file is configured.
- [ ] Both routes are refused with front 11's standard response when the caller is not authorized, and no key in this module changes that.

### Step 8 — The startup summary

**Acceptance:**
- [ ] The line is emitted once, at ready, at `Info`, from the logger `rakun.core.Bootstrap`.
- [ ] It carries elapsed time, PID, node, port and active profiles, and the profile list matches front 05's.
- [ ] With no profile active it prints `profiles []` rather than omitting the field.

## Examples

- [`examples/structured-logging-example.bp`](./examples/structured-logging-example.bp) — a service logging with fields and levels, a correlation id spanning a handler and a background call, and a failure logged with a digest that is the only part crossing to the client.

## Language gaps

None — every construct in the examples parses today.

## Test plan

`modules/rakun-logging/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/level_test.bp` | Prefix resolution, root fallback, the Trace/Debug collapse, `isEnabled` short-circuiting |
| `test/format_test.bp` | All four schemas' field sets and order, escaping, split console/file formats, unknown-format refusal |
| `test/group_test.bp` | Predefined `web` and `sql`, redefinition, group-name precedence |
| `test/correlation_test.bp` | Header reuse, generation, propagation through three call levels, task and listener ids, concurrent isolation |
| `test/digest_test.bp` | Stability across occurrences and nodes, sensitivity to the message, insensitivity to time and arguments, the one-record guarantee, the boundary content check |
| `test/file_test.bp` | Rotation, history, cap, `sys.config` precedence, profile sections |
| `test/endpoint_test.bp` | Live level change, group change, reset, `Range`, 404, refusal when unauthorized |

Records are asserted by reading them back from a capturing OTP handler installed by the test, not by
inspecting stdout. There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **Metrics and traces** — counters, histograms, spans and their export. That is **front 75 — rakun-observability-metrics**. This front carries a trace id on a log record; it does not create a span.
- **The client half of `error.digest`** — front 31 renders it in an error boundary.
- **Log shipping** — writing to a file and formatting for a collector is here; running the collector is not.
- **Audit logging** — an append-only, tamper-evident record with its own retention is front 87, not a log level.

## Definition of done

- One `Logger` type with five levels over OTP `logger`, with the level mapping recorded in `AGENTS.md`.
- Four output schemas, field order fixed, tested against escapes.
- The two predefined groups exist and can be redefined.
- A correlation id is present on every record of a request, a task and a listener.
- The digest scheme is implemented, stable, and proven by the boundary test to be the only part of a server error that crosses.
- The `loggers` and `logfile` endpoints are registered with front 11 and refused when unauthorized.
- The startup summary prints elapsed time, PID, node, port and profiles.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface and the front-75 boundary in the same commit.
- The front's tests are green on erlang.
