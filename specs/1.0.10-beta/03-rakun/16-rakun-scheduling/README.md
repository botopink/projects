# Front 16 — Rakun Scheduling

**Track:** B rakun
**Priority:** medium — every application eventually needs something to happen on its own, and today the only way is an external cron calling an HTTP endpoint
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 01 (`clock`), 05 (config), 06 (context), 11 (endpoint host + health registry)
**Owns:** `modules/rakun-scheduling/src/**`, `modules/rakun-scheduling/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `07-io.md § Quartz Scheduler` · https://docs.spring.io/spring-boot/reference/io/quartz.html

---

## Problem

Nothing in rakun runs on a timer. A cleanup that should happen hourly happens when someone remembers;
a cache warm-up that should happen at boot happens on the first slow request; a heartbeat that should
prove the process is alive proves nothing. `modules/rakun-scheduling/` is a `botopink.json` and a
`src/root.bp` holding a TODO comment.

A single `#[scheduled(cron: …)]` with labelled, optional arguments cannot be built: every existing
marker takes positional arguments (`repository/rakun/src/decorators.bp:210-240`) and declared
parameter defaults are never applied (`docs.md:502-505`). So: three markers, one per trigger kind,
each with the arguments it actually needs.

## Current state

- `repository/rakun/modules/rakun-scheduling/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `libs/std/src/time.bp:56,80,92` — `nowMillis()`, `monotonicMillis()` and `formatIso8601(epochMillis)` all exist today. The scheduler needs both clocks and has both; front 01 ships them as `io.clock` (`now`, `monotonic`, `formatIso8601` — decision 106).
- `repository/rakun/src/runtime.bp` — no timer seam of any kind. The only periodic thing in rakun is the HTTP server's accept loop, which front 04 owns.
- `repository/rakun/src/decorators.bp` — no `#[scheduled]`, and frozen.

## Mechanism

### Three markers, one registry

`#[scheduler]` on a type walks its methods and `@emit`s one registration per trigger marker, the same
way `#[restController]` emits one route per `#[getMapping]`
(`repository/rakun/src/decorators.bp:155-166`):

| Marker | Argument | Fires |
|---|---|---|
| `#[scheduled(cron)]` | a six-field cron expression: second minute hour day month weekday | at each matching instant |
| `#[fixedRate(millis)]` | milliseconds | every N ms measured from the previous *start* |
| `#[fixedDelay(millis)]` | milliseconds | N ms after the previous *finish* |

`fixedRate` and `fixedDelay` differ only when a run takes longer than the interval, and that is exactly
when the difference matters: `fixedRate` will start the next run immediately (and a slow task will
queue against itself), `fixedDelay` will not. The registry records which one a task uses and the
`scheduledtasks` endpoint reports it, because "why is this running twice" is the question this front
gets asked.

A scheduled method returns `i32` — a status the runtime records with the run. That is not decoration:
the emitted registration closure is `{ -> __rkMake_CleanupService().hourly() }` and the seam is declared
generic over the return type (`rkScheduleCron<R>(name, expr, task: fn() -> R) -> i32`), the same way
`rkSingleton<T>` is (`repository/rakun/src/runtime.bp:45`), so a task that has nothing to report can
return `0` and one that processed rows can return how many.

### The executor is a supervised worker set, and the pool-size keys are not ported

Spring's scheduler is a thread pool with `spring.task.scheduling.pool.size`, and Quartz adds
`org.quartz.threadPool.threadCount` on top of it. Neither is ported, and this is not an omission.

On the BEAM the natural shape is: one timer process per task, holding nothing but the next fire time,
and a `simple_one_for_one` supervisor that spawns a fresh process for each run. There is no pool to
size — a process costs a few hundred bytes and is started per execution — so a `pool-size` key would
either do nothing or introduce a queue that does not otherwise exist. Porting it would be parity
theatre. What the configuration does carry is the thing an operator actually needs to control:

| Key | Default | Effect |
|---|---|---|
| `rakun.scheduling.enabled` | `true` | Start the scheduler at boot |
| `rakun.scheduling.<task>.enabled` | `true` | Start one task |
| `rakun.scheduling.<task>.cron` | — | Override the expression compiled into the marker, without a rebuild |
| `rakun.scheduling.<task>.overlap` | `skip` | `skip` \| `allow`. What happens when a run is still going and the next is due. `skip` is the default because a task that can run twice at once and was not designed to is a data race that only appears under load. |
| `rakun.scheduling.timezone` | `UTC` | The zone cron expressions are evaluated in |

### `@Task` is not the parallelism here

`@Task<T>` lowers **eagerly** on erlang (`libs/std/src/http.bp:16-18`), so a task returning a future
gains nothing. Parallelism in this front is process count and nothing else: two tasks due at the same
instant run in two processes because the supervisor spawns two, not because anything was awaited.

### Cron

Six fields — second, minute, hour, day-of-month, month, day-of-week — matching Spring's dialect rather
than Unix's five, since that is what the reference documents. Supported syntax: `*`, a number, a list
(`1,15`), a range (`9-17`), a step (`*/5`, `0-30/10`), and `?` in either day field. Not supported:
`L`, `W`, `#`, and named months or weekdays; each is refused at comptime with the offending field
named, rather than accepted and ignored.

Compilation happens at comptime — `#[scheduler]` parses the expression while emitting and fails the
build on a bad one — and again at boot for an expression supplied by configuration, where the failure
is a startup refusal listing the key. An unparseable cron expression never becomes a task that silently
never fires.

Note the parser is a plain function over a `string`, not a template body: the comptime-body
restrictions (no `.at()`, no `?T`, no comments inside a block — `repository/jhonstart/src/html.bp:70-85`)
apply to the decorator's own body, so the decorator validates by calling into an ordinary compiled
function rather than parsing inline.

### Missed fires

A task whose process was down when it was due does not run late and does not run twice to catch up. The
scheduler records a `missed` count per task and the endpoint reports it. Catch-up semantics are a
durability question, and durability is front 84.

## Steps

### Step 1 — The registry and the three seams

```bp
pub type TaskInfo(
    name: string,
    trigger: string,
    expression: string,
    lastStartedAt: i64,
    lastFinishedAt: i64,
    lastResult: i32,
    nextFireAt: i64,
    runs: i32,
    failures: i32,
    missed: i32,
)

pub declare fn rkScheduleCron<R>(name: string, expr: string, task: fn() -> R) -> i32;
pub declare fn rkScheduleFixedRate<R>(name: string, millis: i32, task: fn() -> R) -> i32;
pub declare fn rkScheduleFixedDelay<R>(name: string, millis: i32, task: fn() -> R) -> i32;
pub declare fn rkTaskCount() -> i32;
pub declare fn rkTaskNames() -> string;
pub declare fn rkRunTaskNow(name: string) -> i32;
```

**Acceptance:**
- [x] Two tasks registered under the same name are refused at boot with both method names in the message. — held: `modules/rakun-scheduling/test/registry_test.bp` "registry: two tasks under one name are refused at boot with both method names"
- [x] `rkRunTaskNow` executes a task once, out of band, and records the run — this is the seam the tests use so that no test waits on wall-clock time. — held: `modules/rakun-scheduling/test/registry_test.bp` "registry: rkRunTaskNow runs a task once, out of band, and records the run"
- [x] Every declared fn in this module is `#[@External.Erlang]`; a grep for `External.Node` under `modules/rakun-scheduling/src` returns nothing. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: every declared fn is #[@External.Erlang] and no source names External.Node"

### Step 2 — `#[scheduler]` and the three markers

```bp
#[service]
#[scheduler]
pub type CleanupService(repo: SessionRepo) {
    #[scheduled("0 0 * * * *")]
    pub fn hourly(self: Self) -> i32 { … }

    #[fixedRate(5000)]
    pub fn heartbeat(self: Self) -> i32 { … }

    #[fixedDelay(30000)]
    pub fn drain(self: Self) -> i32 { … }
}
```

**Acceptance:**
- [x] Each marker on anything but a method fails with a located message. — held: `modules/rakun-scheduling/test/build_test.bp` "build: each trigger marker anywhere but on a method fails with a located message"
- [x] `#[scheduler]` on a type with no trigger-annotated method fails saying so. — held: `modules/rakun-scheduling/test/build_test.bp` "build: #[scheduler] on a type with no trigger-annotated method fails saying so"
- [x] A method carrying two trigger markers is refused — one trigger per task. — held: `modules/rakun-scheduling/test/build_test.bp` "build: a method carrying two trigger markers is refused - one trigger per task"
- [x] The emitted closure builds the component through `__rkMake_<Type>()`, so a task and an HTTP handler on the same `#[service]` share one instance. — held: `modules/rakun-scheduling/test/registry_test.bp` "registry: a task and an HTTP handler on one component share one instance" (emission: `markers.bp` `scheduler`)
- [x] A method whose parameter list is anything but `(self: Self)` is refused, with the extra parameter named — a scheduler has no argument to give it. — held: `modules/rakun-scheduling/test/build_test.bp` "build: a task method with a parameter besides self is refused naming it"

### Step 3 — The cron parser

**Acceptance:**
- [x] `0 0 * * * *`, `*/15 * * * * *`, `0 30 9-17 * * 1-5`, `0 0 0 1 1 ?` all parse and produce the expected next-fire instants from a fixed reference time. — held: `modules/rakun-scheduling/test/cron_test.bp` "cron: the four reference expressions parse and fire at the expected next instant"
- [x] `L`, `W`, `#`, `MON` and `JAN` are each refused at comptime with the field index and the token in the message. — held: `modules/rakun-scheduling/test/build_test.bp` "build: L, W, #, MON and JAN are each refused at comptime with the field index and the token"
- [x] A five-field expression is refused with a message saying six fields are expected and showing the seconds field. — held: `modules/rakun-scheduling/test/build_test.bp` "build: a five-field expression is refused at comptime showing the seconds field"
- [x] A step larger than the field's range is refused. — held: `modules/rakun-scheduling/test/cron_test.bp` "cron: a step larger than the field's range is refused" and `modules/rakun-scheduling/test/build_test.bp` "build: a step larger than the field's range is refused at comptime"
- [x] Next-fire computation crosses a month boundary, a year boundary and a leap day correctly, tested against a fixed clock rather than the wall clock. — held: `modules/rakun-scheduling/test/cron_test.bp` "cron: next fire crosses a month boundary", "cron: next fire crosses a year boundary", "cron: next fire lands on a leap day and skips a february without one"
- [ ] The parser is an ordinary compiled function; the decorator body calls it and does not inline a parser of its own.

### Step 4 — The executor

**Acceptance:**
- [x] Two tasks due at the same instant run in two processes; neither delays the other. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: two tasks due at the same instant run in two processes and neither delays the other"
- [x] A task that raises is recorded as a failure, its supervisor restarts the timer, and the next fire happens on schedule. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: a task that raises is recorded as a failure and the next fire keeps its schedule" and "executor: a dead timer is restarted by its supervisor and fires on schedule"
- [x] `overlap = skip` does not start a run while the previous one is in flight, and increments `missed`. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: overlap skip does not start a run while the previous is in flight and counts it missed"
- [x] `overlap = allow` starts it. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: overlap allow starts the next run while the previous is in flight"
- [x] `rakun.scheduling.enabled = false` registers every task and starts none. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: rakun.scheduling.enabled false registers every task and starts none"
- [x] `rakun.scheduling.<task>.cron` overrides the compiled expression, and an unparseable override refuses the boot with the key named. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: a cron override replaces the compiled expression without a rebuild" and "executor: an unparseable cron override refuses the boot naming the key, and starts nothing"
- [x] Nothing in the module reads or defines a pool-size key, and `AGENTS.md` records why. — held: `modules/rakun-scheduling/test/executor_test.bp` "executor: nothing in the module reads or defines a pool-size key" (the reason: `src/executor.bp` docblock and the AGENTS section)

### Step 5 — The `scheduledtasks` endpoint and health

```bp
// GET /actuator/scheduledtasks -> every task, its trigger, last and next execution
// POST /actuator/scheduledtasks/{name}/run -> run one now
pub fn scheduledTasksEndpoint(req: Request) -> Response

// Registered with front 11 under "scheduling".
pub fn schedulingHealth() -> HealthReport
```

`POST .../run` triggers execution, so it is a write surface and sits behind front 11's access control
with no separate opt-out here. Front 11 decides who may reach `/actuator`; this front does not get a
second answer.

**Acceptance:**
- [x] The listing reports, per task, the trigger kind, the expression, the last start, the last finish, the last result, the next fire, and the run/failure/missed counters. — held: `modules/rakun-scheduling/test/endpoint_test.bp` "endpoint: the listing reports trigger, expression, last start and finish, last result, next fire and the counters"
- [x] Timestamps are RFC 3339 via `clock.formatIso8601`, not raw millis. — held: `modules/rakun-scheduling/test/endpoint_test.bp` "endpoint: timestamps are RFC 3339 through clock.formatIso8601, never raw millis, and null for never"
- [x] `POST .../run` on an unknown name returns 404; on a known one it returns 202 and the run appears in the next listing. — held: `modules/rakun-scheduling/test/endpoint_test.bp` "endpoint: POST run on an unknown name answers 404" and "endpoint: POST run on a known name answers 202 and the run appears in the next listing"
- [x] Both routes are refused with front 11's standard response when the caller is not authorized, and no key in this module changes that. — held: `modules/rakun-scheduling/test/endpoint_test.bp` "endpoint: both routes answer front 11's 404 problem when the caller is not authorized" (no key: `src/endpoint.bp` reads none)
- [x] `schedulingHealth()` reports DOWN when any enabled task's timer process is not alive, naming the task. — held: `modules/rakun-scheduling/test/endpoint_test.bp` "endpoint: scheduling health is DOWN naming an enabled task whose timer is not alive"

## Examples

- [`examples/scheduled-tasks-example.bp`](./examples/scheduled-tasks-example.bp) — one service with all three trigger kinds, sharing an instance with the rest of the application, and a configuration-overridden expression.

## Language gaps

None — every construct in the examples parses today.

## Test plan

`modules/rakun-scheduling/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/cron_test.bp` | Parsing acceptance and refusal per token, next-fire arithmetic against a fixed reference time, boundary crossings |
| `test/registry_test.bp` | Registration count, duplicate refusal, parameter-list refusal, one component instance across runs |
| `test/executor_test.bp` | Independent processes, failure recording and restart, both overlap modes, the global and per-task disable, the configuration override |
| `test/endpoint_test.bp` | Listing content and timestamp format, manual run, 404, refusal when unauthorized, health UP and DOWN |

**No test waits on wall-clock time.** Every timing assertion drives `rkRunTaskNow` or computes a next
fire from a fixed reference instant. A scheduling suite that sleeps is a suite that is flaky on a loaded
CI runner, and the project already has a rule about the test budget (`zig build test` capped at sixty
seconds) that a sleeping suite would blow on its own.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **Durable and cluster-coordinated jobs** — Quartz's JDBC job store (`spring.quartz.job-store-type=jdbc`), `overwrite-existing-jobs`, `@QuartzDataSource`, and the guarantee that exactly one node in a cluster runs a task. That is **front 84 — rakun-persistent-jobs**. This front is in-VM: a task lives in one node's memory, every node in a cluster runs its own copy, and the README of an application that cannot tolerate that should say so and take front 84.
- **Catch-up after downtime** — counted as `missed` here, executed by front 84.
- **`JobDetail` / `Trigger` / `Calendar` beans** — Quartz's object model. The rakun model is a method with a marker; a second, declarative one has no consumer in this milestone.
- **Metrics on execution duration** — front 75 owns metrics export; this front keeps the counters and exposes them on its endpoint.

## Definition of done

- Three markers, one registry, and one trigger per task enforced at comptime.
- The cron parser refuses every unsupported token by name and is tested against a fixed clock.
- The executor is a supervised process per run, with no pool-size key anywhere in the module and the reason recorded in `AGENTS.md`.
- The `scheduledtasks` endpoint and the `scheduling` health indicator are registered with front 11 and refused when unauthorized.
- No test in the suite sleeps.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface and the front-84 boundary in the same commit.
- The front's tests are green on erlang.
