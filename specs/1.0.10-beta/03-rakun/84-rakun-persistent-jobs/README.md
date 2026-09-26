# Front 84 — rakun Persistent Jobs

**Track:** B rakun
**Priority:** medium — front 16 schedules in memory, so a restart loses pending work and N replicas each run the same nightly job N times
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 16 (the `#[scheduled]` surface and the cron parser this reuses), 08 (the job store's datasource and its local transaction), 77 (the migrations that create the tables), 05 (configuration), 11 (the `quartz`-equivalent endpoint is served there)
**Owns:** `modules/rakun-scheduling/src/jobstore/**` · `modules/rakun-scheduling/test/jobstore/**`
**Does not touch:** front 16's `modules/rakun-scheduling/src/*.bp` at the top level — the in-VM scheduler, `#[scheduled]`, the cron parser and the `scheduledtasks` endpoint are all front 16's and stay there. Also the four frozen files in `repository/rakun/src/`
**Reference:** `07-io.md § Quartz Scheduler`, `§ Configuracao`, `§ Definindo Jobs`, `§ DataSource Dedicado` · `09-actuator.md § Endpoints (quartz, scheduledtasks)` · <https://docs.spring.io/spring-boot/reference/io/quartz.html>

---

## Problem

Front 16 delivers `#[scheduled]`: a method that runs on a fixed rate, a fixed delay or a cron
expression, driven by a timer inside the VM. That is the right mechanism for a cache sweep, a metrics
flush or a heartbeat — work that is cheap, idempotent, and meaningless to have missed.

It is the wrong mechanism for everything else, and it fails in two ways that look like bugs and are
not.

**A restart loses the schedule.** The timer lives in the process; the process dies; the next fire
time dies with it. A nightly invoice run that was due at 03:00 during a deploy window simply does not
happen, and nothing anywhere records that it did not. There is no state to inspect afterwards, which
is the part that makes it expensive: the first anyone knows is a customer asking where their invoice
is.

**Every replica runs it.** An application deployed three times is three VMs, each with its own timer,
each firing the same cron expression. A nightly report is emailed three times; a nightly charge is
made three times. The usual field fix — run the scheduler on one designated node — turns a deployment
into a configuration with a single point of failure, and the moment that node is the one being
restarted the job is skipped again.

Spring's answer is Quartz with a JDBC job store (`07 § Quartz Scheduler`): jobs, triggers and fire
states live in the database, and every node in the cluster competes for the right to fire a trigger.
That is what this front ports. The boundary with front 16 is the whole design: **front 16 owns work
that may be missed; this front owns work that may not.**

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-scheduling/` | `botopink.json` plus `src/root.bp`, whose body is the comment *"Module contents will be added by the respective fronts."* |
| `#[scheduled]`, cron parsing, the in-VM timer | front 16 delivers them; nothing exists today |
| `modules/rakun-scheduling/src/jobstore/` | does not exist — this front creates it |
| A durable job store, a cluster lease, a misfire policy | nothing, in rakun or in std |
| A clock | front 01 delivers `io.clock` (decision 106); `libs/std/src/time.bp` exists today but front 01 owns the monotonic and wall-clock split this front needs |
| Node identity | front 04's release gives the node a name; `erlang:node/0` behind a cell is the only identifier needed |

## Mechanism

### Two schedulers, one surface

An application should not have to learn a second API to make a job durable. `#[persistentJob]` takes
the same cron and fixed-delay arguments `#[scheduled]` takes, and differs only in where the next fire
time is written.

| | `#[scheduled]` — front 16 | `#[persistentJob]` — here |
|---|---|---|
| Next fire time | in the VM | a row in `rakun_job_trigger` |
| Survives a restart | no | yes |
| Runs on N replicas | N times | once |
| A missed window | is gone | is a misfire, with a policy |
| Cost per fire | a timer message | a database round trip and a lease |
| Right for | sweeps, flushes, heartbeats | invoices, reports, charges, anything a person would notice |

The cron expression is parsed by front 16's parser. There is one cron implementation in this
repository and this front does not write a second one.

### Firing exactly once across a cluster

```
every tick (jittered, per node)
  ├─ BEGIN
  ├─ SELECT … FROM rakun_job_trigger
  │     WHERE next_fire <= now AND state = 'waiting'
  │     ORDER BY next_fire
  │     FOR UPDATE SKIP LOCKED LIMIT n
  ├─ UPDATE … SET state='acquired', owner=<node>, lease_until=now+lease
  ├─ COMMIT                              ← the row is now this node's, durably
  ├─ run the handler
  └─ UPDATE … SET state='waiting', next_fire=<computed>, prev_fire=now
```

`FOR UPDATE SKIP LOCKED` is the whole of the cluster coordination: a node takes rows nobody else
holds, and a node that takes none does nothing. There is no elected leader, no designated scheduler
node, and no configuration that names one — because every such design fails on the day that node is
the one being restarted.

The lease is what makes a dead node recoverable. A trigger in `acquired` whose `lease_until` has
passed is reclaimable by any node; the reclaiming node records the takeover in the job's history, so
"this ran twice because a node was partitioned" is visible after the fact rather than inferred. A
long job renews its lease while it runs, so a slow job is not a dead one.

**The guarantee is at-least-once, and the front says so plainly.** A node that fires a trigger,
completes the work and dies before the final `UPDATE` will have another node reclaim the lease and
fire it again. Exactly-once across a database and an arbitrary side effect is not available without
the side effect being transactional — which is front 83's outbox, and a job whose handler enrols its
publishes there gets exactly the guarantee front 83 documents. This front does not claim more than it
has.

### Misfires

A trigger whose window passed while the cluster was down has a decision to make, and the right answer
depends entirely on the job. The policy is per trigger, declared, with no default that guesses:

| Policy | On a missed window | Right for |
|---|---|---|
| `FireNow` | fire once immediately, then resume the schedule | a report that is late but still wanted |
| `SkipToNext` | do nothing, fire at the next scheduled time | a sweep where a late run is pointless |
| `FireAll` | fire once per missed window, in order | an accrual that must not skip a period |

`FireAll` is bounded by a configured ceiling, and hitting the ceiling is an error entry in the job's
history rather than a silent truncation — an accrual that quietly skipped four of its twelve missed
periods is worse than one that stopped and said so.

### Job data, and why it is a string

A durable job carries data across a restart, so the data has to be serialisable. `std/json` has no
structured value (`libs/std/src/json.bp:9-16`), so job data is a querystring-encoded string — the same
choice front 24's action envelope and front 83's saga context make, for the same reason. See
[`../contracts.md`](../../contracts.md) § 3. When a JSON walker lands, this is one encoder and one
decoder to change.

### Retries and the dead-letter path

A handler that raises is retried with backoff, per job, to a declared ceiling; past it the execution
is recorded `failed` with the reason and the trigger returns to `waiting` for its next scheduled
window. A failing job therefore does not stop its own schedule and does not spin: those are two
different failure modes and both of them page somebody at 04:00.

## Steps

### Step 1 — The schema and the job store

Three tables through front 77: `rakun_job`, `rakun_job_trigger`, `rakun_job_history`. A dedicated
datasource is supported — `07 § DataSource Dedicado` — so a busy job store can be pointed at its own
pool without moving the application's data.

```bp
pub type JobDetail(
    name: string,
    group: string,
    handler: string,
    data: string,
    durable: bool,
)

pub type Trigger(
    name: string,
    job: string,
    cron: string,
    startAt: i32,
    endAt: i32,
    misfire: MisfirePolicy,
    retries: i32,
    backoffMs: i32,
)

pub type MisfirePolicy {
    FireNow,
    SkipToNext,
    FireAll,
}
```

**Acceptance:**
- [ ] A job registered twice with the same name and group is one row, and its definition is the later one only when `rakun.scheduling.overwrite-existing-jobs` is true — the `07 § Configuracao` switch
- [ ] With that switch false, a changed definition fails the boot naming the job, rather than running the old one
- [ ] A trigger whose cron does not parse fails the boot, naming the trigger and the parse error
- [ ] A trigger whose `endAt` precedes its `startAt` fails the boot
- [ ] A dedicated datasource is used when configured, and the application's otherwise
- [ ] Job data round-trips a value containing `&`, `=`, a newline and a four-byte UTF-8 character

### Step 2 — `#[persistentJob]` and registration

```bp
#[persistentJob("nightly-invoices", "0 3 * * *")]
pub fn runInvoices(self: Self, data: string) -> string
```

Arguments are positional, matching every decorator rakun already has
(`#[getMapping("/users")]`, `#[value("app.timezone")]`); a labelled decorator argument is not a form
this repository uses anywhere. The decorator `@emit`s the registration the same way `#[bean]` does,
and checks placement and argument shape at comptime.

**Acceptance:**
- [ ] `#[persistentJob]` on something that is not a method is a located compile error
- [ ] A handler whose signature is not `(self, data: string) -> string` is a located compile error
- [ ] Registration is idempotent across restarts: booting twice produces one job row and one trigger row
- [ ] A job removed from the source is marked orphaned at boot and does not fire; it is not deleted, so its history survives

### Step 3 — Firing, once, across a cluster

**Acceptance:**
- [ ] Three nodes with the same trigger due fire it once — asserted with three schedulers against one store
- [ ] The winning node is recorded as the owner in the history row
- [ ] A node that acquires and then dies has its trigger reclaimed after the lease expires, and the reclaim is recorded as a takeover
- [ ] A handler that runs longer than the lease renews it and is not reclaimed
- [ ] Ticks are jittered per node, so N nodes do not all query at the same instant
- [ ] A store that is unreachable at tick time logs once per interval rather than once per tick, and recovers without a restart

### Step 4 — Misfires

**Acceptance:**
- [ ] `FireNow` on a trigger whose window passed fires once immediately and then resumes the schedule
- [ ] `SkipToNext` fires nothing and the next fire time is the next scheduled one
- [ ] `FireAll` over three missed windows fires three times, in chronological order
- [ ] `FireAll` past the configured ceiling stops at the ceiling and records an error entry naming how many windows were skipped
- [ ] The policy is read per trigger; there is no global override that silently changes a job's semantics

### Step 5 — Retries, history and failure

**Acceptance:**
- [ ] A handler that raises is retried to the declared ceiling with the declared backoff
- [ ] Past the ceiling the execution is `failed` with the reason, and the trigger's next scheduled fire still happens
- [ ] A retry storm is impossible: a job cannot consume its own next window retrying the previous one
- [ ] Every execution — success, failure, takeover — has a history row with node, start, end and outcome
- [ ] History is pruned on a configured retention, bounded per pass

### Step 6 — The actuator endpoint

The `quartz` endpoint from `09 § Endpoints`: jobs, triggers, next fire times and recent failures.
Served by front 11, behind front 76's access control like every other endpoint.

**Acceptance:**
- [ ] `/actuator/quartz` lists every job with its group, triggers and next fire time
- [ ] A named job's recent executions are readable, newest first, bounded
- [ ] Job data is sanitised by front 76's rules before it is served — a job whose data carries a token must not leak it through an endpoint
- [ ] The endpoint is read-only: there is no trigger-now and no delete, because an endpoint that fires a job is an endpoint that fires a job twice
- [ ] It is absent, not empty, when this module is not present

## Examples

- [`examples/persistent-job-example.bp`](./examples/persistent-job-example.bp) — a nightly invoice run
  written as a durable job: the handler, its trigger with a declared misfire policy, and the
  assertions that make "three nodes fire it once" and "a dead node's work is reclaimed" tests rather
  than claims.

## Language gaps

Every gap this front meets is already filed in [`../language-gaps.md`](../../language-gaps.md): `@Decl`
carries no source location (so `#[persistentJob]` takes an explicit `name:` rather than deriving one),
and there is no structured JSON value (so job data is querystring-encoded). This front adds no new
row.

One near-miss worth naming so it is not rediscovered: `#[persistentJob]`'s body duplicates the
placement and argument checks every other rakun decorator duplicates, because a decorator body cannot
call a sibling function (`src/decorators.bp:44-46`). That is a comptime limitation, it is recorded
under front 80, and it costs this front six copied lines rather than a design change.

## Test plan

`modules/rakun-scheduling/test/jobstore/`, run with `botopink test --target erlang` from
`modules/rakun-scheduling/`, and in the gate as `zig build test-libs -- --target erlang --lib rakun`.

Time is injected, never slept. The scheduler takes its clock from front 01's `io.clock` behind a
test double, so "three missed windows" is three clock advances and the whole suite runs in
milliseconds. A scheduling test that sleeps is a scheduling test that flakes on a loaded machine and
adds minutes to every gate run.

The cluster assertions run three scheduler processes against one store inside a single test — which
is exactly what the production shape is, since coordination is entirely in the database and nothing
about it requires separate nodes. The takeover test kills a scheduler with `exit(Pid, kill)` after it
acquires and before it completes, then advances the clock past the lease.

The store is front 08's test datasource, so no external database is needed. If the embedded store
cannot express `FOR UPDATE SKIP LOCKED`, the cluster tests run against a real PostgreSQL when one is
configured and are **skipped with a named reason** otherwise — never silently passed, because the
skipped assertion is the one the whole front exists for.

This front is erlang-only. A durable schedule has no browser half.

## Definition of done

- [ ] `modules/rakun-scheduling/src/jobstore/` exists and front 16's top-level files are untouched
- [ ] `#[persistentJob]` registers a job and a trigger idempotently across restarts
- [ ] Three schedulers against one store fire a due trigger exactly once
- [ ] A dead node's acquired trigger is reclaimed after its lease and the takeover is recorded
- [ ] All three misfire policies behave as specified, and `FireAll` reports rather than truncates
- [ ] A failing handler retries to its ceiling and then fails without stopping its own schedule
- [ ] `/actuator/quartz` is read-only, sanitised, and absent when the module is not present
- [ ] The README's at-least-once statement is in `repository/rakun/AGENTS.md` too, next to front 16's
      at-most-once one — the two guarantees are the reason there are two fronts
- [ ] The front's tests are green on its assigned target

