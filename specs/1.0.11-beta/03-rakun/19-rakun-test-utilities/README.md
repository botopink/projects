# Front 19 — rakun Test Utilities

**Priority:** high, blocking — step 1's Redis double is what three other fronts assert against (12, 09, and 18 inside 12); `bootAndExit` is the CI gate every rakun application should run
**Carries:** —
**Depends on:** step 1: none. Steps 3–5: `15-rakun-messaging` step 1 (the registries on `rkOnReset`, the listener-names term), `04-rakun-erlang-runtime` step 4 (the exit-code table for `bootAndExit`). Maintainer: 03r-aa (the double), 03r-ag (the snapshot layer), 03r-am (where the broker double lives)
**Owns:** `modules/rakun-test/**` · `repository/rakun/AGENTS.md` § Test utilities · under 03r-am (a): `modules/rakun-messaging/src/broker_double.bp`, `modules/rakun-messaging/src/sidecars/rakun_messaging_double.erl`, `modules/rakun-scheduling/src/task_double.bp` by carve-out, named here so 15 knows not to write them
**Does not touch:** every other member (the doubles' consumers import; they do not edit `rakun-test`) · `repository/botopink-lang/libs/std/**` (`testing.mocks` is std's)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/19-rakun-test-utilities/README.md`) | Box, as written |
|---|---|---|
| R19-1 | § Step 4 — Context control | "`resetContext()` empties the scan registry, the route table, the listener registry and the task registry, and a dispatch afterwards returns 404. — scan registry and route table done (`context_test.bp`); the listener and task registries hang off the core's `rkOnReset` once fronts 15 and 16 register theirs" |
| R19-2 | § Step 4 | "`contextSnapshot()` reports scanned names, route paths and listener destinations, and is stable across runs. — scanned names and routes, stable (`context_test.bp`); listener destinations read `[]` until front 15 keeps the `rakun_listener_names` term" |
| R19-3 | § Step 5 — The broker double | "`deliver` reaches a `#[listener]` handler with no broker configured." · "`published(broker)` returns every destination and payload sent through that arm's template, in order." · "`clearPublished()` empties the record and two tests do not see each other's publishes." · "Front 15's container tests run green with every integration cell skipped, entirely through this double." — the last is reworded: there is no integration cell to skip (03r-aa); "front 15's container tests run through this double" |
| R19-4 | § Step 6 — `bootAndExit` | "Exit `0` on an application that wires up; non-zero with the first failure printed otherwise." · "A missing bean, a DI cycle, a duplicate route, a duplicate listener destination, an unparseable cron expression and a configuration-constraint violation each produce a distinct non-zero exit with a message naming the offending declaration." · "No port is bound and no broker connection is attempted." · "The whole run is under two seconds for an application with fifty components — this is a CI gate, and a slow gate gets deleted." |
| R19-5 | § Step 7 — Documenting the onze pairing | "The README and `AGENTS.md` show the `#[mock]` + `#[bean]` pairing as the `@MockBean` equivalent, and `modules/rakun-test/src/` contains no mocking implementation of its own. — … open on `#[mock]` firing outside `mocks.bp` (std), so the pairing is a hand-written double" |
| RX-5 | closed `README.md` § What rakun still owes | the 57-helper snapshot layer — [`test-snap-helpers.md`](./test-snap-helpers.md) carries the contract for 03r-ag |
| STD-2 | `01-std` audit | `examples/controller-test-example.bp:24` imports the retired mocking library `from "onze"` — rewritten to `testing.mocks` + `#[bean]` |
| 03r-aa | this milestone | the Redis RESP double |

## Problem

`rakun-session`'s Redis cell, `rakun-cache`'s Redis provider and 09's Redis arm have nothing to
connect to in the gate. A `#[listener]` handler cannot be driven from a test without the in-process
broker's configuration. `bootAndExit` — boot the application, bind nothing, exit with a code —
does not exist, so a CI gate for a rakun application is `botopink test`, which asserts nothing
about wiring. `mocks_pairing_test.bp` pairs a hand-written double with `#[bean]` because `#[mock]`
fires only inside std's `mocks.bp`.

## Current state

`modules/rakun-test`: `src/` = `root.bp`, `fake_request.bp`, `assertions.bp` (`expect*`),
`mockmvc.bp`, `context.bp`; `test/` = 5 files, green; depends on `rakun` only. `context.bp:7`
documents `rkOnReset`. No `sidecars/`. No `.snap` under `repository/rakun`.

## Mechanism

- **The Redis double (step 1).** `src/sidecars/rakun_redis_double.erl`: a `gen_tcp` acceptor per
  `redisDoubleStart(port)` (`0` = ephemeral; the call answers the bound port), RESP2 parsing of
  inline and multi-bulk commands, the twelve commands 12 and 09 use over one ETS table per port
  (`SETEX`/`EXPIRE` with a sweeper on `erlang:send_after`), a command log (`redisDoubleLog`), a
  fault injector (`redisDoubleFail(port, cmd)` closes the socket on the next `cmd`), and
  `redisDoubleStop`. Exposed as `#[@External.Erlang]` cells in `src/redis_double.bp`, `pub` from
  `root.bp`. A consumer's test imports `{redisDoubleStart, …} from "rakun-test"`; the sidecar ships
  by its atom.
- **The broker double (step 3, 03r-am).** Measure first: add `rakun-messaging` to `rakun-test`'s
  manifest in the worktree and run `botopink test --target erlang` in `modules/rakun-messaging`. If
  the loader refuses the cycle, the double lives beside the module (`rakun-messaging/src/broker_double.bp`)
  under this front's carve-out, and `rakun-test` documents it; either way the double reaches the
  registry through 15's hooks (`rkDeliver`, `rakun_listener_names`, `rkOnReset`).
- **`bootAndExit` (step 4).** Runs 04's `bootSequenceFor` with a listener factory that binds nothing
  and a broker factory that connects nothing, then the shutdown path; answers 06's exit code (R06-6's
  table). The 2-second budget is asserted with `io.clock` over `fixtures/fifty` (fifty components).

## Gate stance

The double is test-only, ships no production path, and is what makes three env-gated or untested
Redis arms into gate assertions. No cell of this member is gated.

## Steps

### Step 1 — The Redis double (03r-aa)

**Acceptance:**
- [ ] `test/redis_double_test.bp`: `redisDoubleStart(0)` answers a port; `PING` → `PONG`; `SET`/`GET`/`DEL`/`INCRBY`/`HSET`/`HGET`/`LPUSH`/`RPOP`/`TTL`/`EXPIRE`/`SETEX` behave as Redis documents them (one cell per command, asserting the reply bytes)
- [ ] `SETEX k 1 v` is gone after 1.1 s and `TTL k` reports `1` then `0` before that
- [ ] `redisDoubleFail(port, "GET")` closes the socket on the next `GET`; the following connection succeeds
- [ ] two doubles on two ports do not share keys; `redisDoubleStop` frees the port
- [ ] `AGENTS.md` § Test utilities documents the double, its command set and its limits ("not Redis: no `SCAN`, no pipelines, no pub/sub")

### Step 2 — Context control (R19-1, R19-2)

**Acceptance:**
- [ ] `context_test.bp`: after 15 step 1, `resetContext()` empties the listener and task registries (asserted through `contextSnapshot()`), and a dispatch afterwards is 404
- [ ] `contextSnapshot()` reports listener destinations from `rakun_listener_names`, stable across two runs

### Step 3 — The broker double (R19-3, 03r-am)

**Acceptance:**
- [ ] the loader measurement is recorded in the README (cycle refused or accepted) and the double's location follows it
- [ ] `deliver(broker, destination, payload)` reaches a `#[listener]` handler with no broker configured; `published(broker)` lists every destination and payload sent through that arm's template, in order; `clearPublished()` empties it and two tests do not see each other's publishes
- [ ] `rakun-messaging/test/container_test.bp` runs through the double — one container cell rewritten to it, the rest already on the in-process broker

### Step 4 — `bootAndExit` (R19-4)

**Acceptance:**
- [ ] `test/boot_test.bp`: `bootAndExit(app)` on `fixtures/ok` exits `0`; on `fixtures/{missing-bean,cycle,dup-route,dup-listener,bad-cron,bad-config}` exits with six distinct non-zero codes, each message naming the declaration
- [ ] no port is bound (`rkListenerCount()` is 0 after the run) and no broker connection is attempted (the in-process broker's connect count is 0)
- [ ] `fixtures/fifty` boots and exits in under 2 s, measured with `io.clock`

### Step 5 — The pairing and the example (R19-5, STD-2)

**Acceptance:**
- [ ] `mocks_pairing_test.bp` uses `testing.mocks`'s `#[mock]` with `#[bean]` if std's `#[mock]` fires outside `mocks.bp` in this milestone (`01-std`'s row); otherwise the README states the hand-written pairing and the box stays open naming the std row
- [ ] `examples/controller-test-example.bp` imports nothing `from "onze"`; it compiles against `rakun-test` + `testing.mocks`

### Step 6 — The snapshot layer (RX-5, 03r-ag)

**Acceptance:**
- [ ] under (a): `test-snap-helpers.md` is deleted here and `AGENTS.md` says the member ships no snapshot helpers; under (b) or (c): the helpers named in the answer are written one per subject with the rendering rules of the carried contract, and each front re-records its boxes as it lands

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-test`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § Test utilities updated
- [ ] commit on `fix/19-rakun-test-utilities`

## Blast radius

Step 1 adds a sidecar and three `pub` functions; nothing existing changes. Step 3 may add a
manifest edge (measured first). Step 4 adds fixtures under `test/fixtures/` only.

## Notes

- `test-snap-helpers.md` is the carried contract (the two sections of the closed `test-snap.md`
  that RX-5 still needs); it exists to give 03r-ag its material and goes with the answer.
- `FakeRequest` hands handlers `toRequest()` until an implementer converts to its behavior
  (closed `status.md`); not an open box, recorded in `AGENTS.md`.
