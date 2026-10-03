# Front 19 — rakun test utilities: the Redis double, context control, the broker double, `bootAndExit`

**Priority:** high, blocking — step 1's Redis double is what 12 and 09 assert against; `bootAndExit`
is the CI gate every rakun application should run · **State:** not started
**Depends on:** 128 · step 1: nothing else (decision 160) · steps 2–5: 15 step 1 (the registries on
`rkOnReset`), 04 step 4 (the exit-code table) · 03r-am (steps 3–4) · step 6: 03r-ag
**Group:** A (step 1) · C (steps 2–5) · step 6 on 03r-ag
**Owns:** `modules/rakun-test/**` · `repository/rakun/AGENTS.md` § Test utilities · under 03r-am (a),
by carve-out: `modules/rakun-messaging/src/broker_double.bp`,
`modules/rakun-messaging/src/sidecars/rakun_messaging_double.erl`, `modules/rakun-scheduling/src/task_double.bp`
(named here so 15 does not write them)
**Does not touch:** every other member (the doubles' consumers import them) ·
`repository/botopink-lang/libs/std/**` (`testing.mocks` is std's)

## Goal

`rakun-test` ships a RESP2 Redis double on a loopback port; `resetContext()` and `contextSnapshot()`
cover the listener and task registries; a broker double drives a `#[listener]` with no broker
configured; `bootAndExit` boots an application binding nothing and exits with a code; the `#[mock]`
pairing and the example are current; the snapshot layer is settled by 03r-ag.

## Mechanism

Today `rakun-test/src` is `root.bp`, `fake_request.bp`, `assertions.bp` (`expect*`), `mockmvc.bp`,
`context.bp` (which documents `rkOnReset`); 5 test files; depends on `rakun` only; no `sidecars/`;
no `.snap` under `repository/rakun`.

- **The Redis double (step 1).** `src/sidecars/rakun_redis_double.erl`: a `gen_tcp` acceptor per
  `redisDoubleStart(port)` (`0` = ephemeral; answers the bound port), RESP2 parsing of inline and
  multi-bulk commands, the twelve commands 12 and 09 use (`GET SET SETEX DEL INCRBY HGET HSET LPUSH
  RPOP TTL EXPIRE PING`) over one ETS table per port (`SETEX` / `EXPIRE` with a sweeper on
  `erlang:send_after`), a command log (`redisDoubleLog`), a fault injector
  (`redisDoubleFail(port, cmd)` closes the socket on the next `cmd`), `redisDoubleStop`. Exposed as
  `#[@External.Erlang]` cells in `src/redis_double.bp`, `pub` from `root.bp`; a consumer imports
  `{redisDoubleStart, …} from "rakun-test"`.
- **Context control (step 2).** The `rakun_listener_names` term is already kept by `rakun-messaging`
  and read by the core; what 15 step 1 adds is the two registries' `rkOnReset` registration.
- **The broker double (step 3, 03r-am).** Measure first: add `rakun-messaging` to `rakun-test`'s
  manifest in the worktree and run `botopink test --target erlang` in `modules/rakun-messaging`. If
  the loader refuses the cycle, the double lives beside the module under this front's carve-out and
  `rakun-test` documents it; either way it reaches the registry through 15's hooks (`rkDeliver`,
  `rakun_listener_names`, `rkOnReset`).
- **`bootAndExit` (step 4).** Runs 04's `bootSequenceFor` with a listener factory that binds nothing
  and a broker factory that connects nothing, then the shutdown path; answers 04 step 4's exit code.
  The 2-second budget is asserted with `io.clock` over `fixtures/fifty` (fifty components).

The double is test-only and ships no production path; no cell of this member is gated.

## Open

### Step 1 — The Redis double (decision 160)

- [ ] `test/redis_double_test.bp`: `redisDoubleStart(0)` answers a port; `PING` → `PONG`; `SET`/`GET`/`DEL`/`INCRBY`/`HSET`/`HGET`/`LPUSH`/`RPOP`/`TTL`/`EXPIRE`/`SETEX` behave as Redis documents them (one cell per command, asserting the reply bytes)
- [ ] `SETEX k 1 v` is gone after 1.1 s and `TTL k` reports `1` then `0` before that
- [ ] `redisDoubleFail(port, "GET")` closes the socket on the next `GET`; the following connection succeeds
- [ ] two doubles on two ports do not share keys; `redisDoubleStop` frees the port
- [ ] `AGENTS.md` § Test utilities documents the double, its command set and its limits ("not Redis: no `SCAN`, no pipelines, no pub/sub")

### Step 2 — Context control (R19-1, R19-2; after 15 step 1)

- [ ] `context_test.bp`: `resetContext()` empties the listener and task registries (asserted through `contextSnapshot()`), and a dispatch afterwards is 404
- [ ] `contextSnapshot()` reports listener destinations from `rakun_listener_names`, stable across two runs

### Step 3 — The broker double (R19-3, 03r-am)

- [ ] the loader measurement is recorded in the README (cycle refused or accepted) and the double's location follows it
- [ ] `deliver(broker, destination, payload)` reaches a `#[listener]` handler with no broker configured; `published(broker)` lists every destination and payload sent through that arm's template, in order; `clearPublished()` empties it and two tests do not see each other's publishes
- [ ] `rakun-messaging/test/container_test.bp` runs through the double — one container cell rewritten to it, the rest already on the in-process broker

### Step 4 — `bootAndExit` (R19-4; after 04 step 4)

- [ ] `test/boot_test.bp`: `bootAndExit(app)` on `fixtures/ok` exits `0`; on `fixtures/{missing-bean,cycle,dup-route,dup-listener,bad-cron,bad-config}` exits with six distinct non-zero codes, each message naming the declaration
- [ ] no port is bound (no listening socket is opened during the run — `rakun-messaging`'s `rkListenerCount()` counts message listeners, not sockets) and no broker connection is attempted (the in-process broker's connect count is 0)
- [ ] `fixtures/fifty` boots and exits in under 2 s, measured with `io.clock`

### Step 5 — The pairing and the example (R19-5, STD-2)

- [ ] `mocks_pairing_test.bp` uses `testing.mocks`'s `#[mock]` with `#[bean]` if std's `#[mock]` fires outside `mocks.bp` in this milestone; otherwise the README states the hand-written pairing and the box stays open naming the std row
- [ ] `examples/controller-test-example.bp` imports nothing `from "onze"`; it compiles against `rakun-test` + `testing.mocks`

### Step 6 — The snapshot layer (RX-5, 03r-ag)

- [ ] under (a): [`test-snap-helpers.md`](./test-snap-helpers.md) is deleted and `AGENTS.md` says the member ships no snapshot helpers; under (b) or (c): the helpers named in the answer are written one per subject with that file's rendering rules, and each front re-records its boxes as it lands

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-test`.

Blast radius: step 1 adds a sidecar and `pub` functions; nothing existing changes. Step 3 may add a
manifest edge (measured first). Step 4 adds fixtures under `test/fixtures/` only.

## Notes

- `test-snap-helpers.md` holds the snapshot-helper contract 03r-ag decides on; it goes with the answer.
- `FakeRequest` hands handlers `toRequest()` until an implementer converts it to its behavior; not a
  box, recorded in `AGENTS.md`.
