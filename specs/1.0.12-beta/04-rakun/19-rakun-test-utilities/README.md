# Front 19 — rakun test utilities: the Redis double, context control, the broker double, `bootAndExit`

**Priority:** high, blocking — 12 and 09 assert against step 1's Redis double; `bootAndExit` is the
CI gate every rakun application should run · **State:** not started
**Depends on:** 128 · step 1: nothing else (decision 160) · steps 2–5: 15 step 1 (registries on
`rkOnReset`), 04 step 4 (exit-code table) · 03r-am (steps 3–4)
**Group:** A (step 1) · C (steps 2–5) · step 6 → 20-snap
**Owns:** `modules/rakun-test/**` · `repository/rakun/AGENTS.md` § Test utilities · under 03r-am (a),
by carve-out: `modules/rakun-messaging/src/broker_double.bp`,
`modules/rakun-messaging/src/sidecars/rakun_messaging_double.erl`, `modules/rakun-scheduling/src/task_double.bp`
(named so 15 does not write them)
**Does not touch:** every other member (consumers import the doubles) ·
`repository/botopink-lang/libs/std/**` (`testing.mocks` is std's)

## Goal

`rakun-test` ships a RESP2 Redis double on a loopback port; `resetContext()`, `contextSnapshot()`
cover listener and task registries; a broker double drives a `#[listener]` with no broker
configured; `bootAndExit` boots an app binding nothing, exits with a code; `#[mock]` pairing and the
example current; the snapshot layer is front 135's (`20-snap`, on `snap-a`).

## Mechanism

Today `rakun-test/src`: `root.bp`, `fake_request.bp`, `assertions.bp` (`expect*`), `mockmvc.bp`,
`context.bp` (documents `rkOnReset`); 5 test files; depends on `rakun` only; no `sidecars/`; no
`.snap` under `repository/rakun`.

- **Redis double (step 1).** `src/sidecars/rakun_redis_double.erl`: a `gen_tcp` acceptor per
  `redisDoubleStart(port)` (`0` = ephemeral; answers the bound port), RESP2 parsing of inline and
  multi-bulk commands, the twelve commands 12 and 09 use (`GET SET SETEX DEL INCRBY HGET HSET LPUSH
  RPOP TTL EXPIRE PING`) over one ETS table per port (`SETEX` / `EXPIRE` sweeper on
  `erlang:send_after`), a command log (`redisDoubleLog`), a fault injector
  (`redisDoubleFail(port, cmd)` closes the socket on the next `cmd`), `redisDoubleStop`. `#[@External.Erlang]` cells in
  `src/redis_double.bp`, `pub` from `root.bp`; consumers import `{redisDoubleStart, …} from "rakun-test"`.
- **Context control (step 2).** `rakun-messaging` already keeps `rakun_listener_names`, the core reads
  it; 15 step 1 adds the two registries' `rkOnReset` registration.
- **Broker double (step 3, 03r-am).** Measure first: add `rakun-messaging` to `rakun-test`'s
  manifest in the worktree, run `botopink test --target erlang` in `modules/rakun-messaging`. Cycle
  refused → double lives beside the module under this front's carve-out, documented by
  `rakun-test`; either way it reaches the registry through 15's hooks (`rkDeliver`,
  `rakun_listener_names`, `rkOnReset`).
- **`bootAndExit` (step 4).** 04's `bootSequenceFor` with a listener factory binding nothing and a
  broker factory connecting nothing, then the shutdown path; answers 04 step 4's exit code. 2-second
  budget asserted with `io.clock` over `fixtures/fifty` (fifty components).

Test-only, no production path; no gated cell.

## Open

### Step 1 — The Redis double (decision 160)

- [ ] `test/redis_double_test.bp`: `redisDoubleStart(0)` answers a port; `PING` → `PONG`; `SET`/`GET`/`DEL`/`INCRBY`/`HSET`/`HGET`/`LPUSH`/`RPOP`/`TTL`/`EXPIRE`/`SETEX` behave as Redis documents (one cell per command, asserting reply bytes)
- [ ] `SETEX k 1 v` gone after 1.1 s; `TTL k` reports `1` then `0` before that
- [ ] `redisDoubleFail(port, "GET")` closes the socket on the next `GET`; the following connection succeeds
- [ ] two doubles on two ports share no keys; `redisDoubleStop` frees the port
- [ ] `AGENTS.md` § Test utilities documents the double, its command set and limits ("not Redis: no `SCAN`, no pipelines, no pub/sub")

### Step 2 — Context control (R19-1, R19-2; after 15 step 1)

- [ ] `context_test.bp`: `resetContext()` empties listener and task registries (via `contextSnapshot()`); a later dispatch is 404
- [ ] `contextSnapshot()` reports listener destinations from `rakun_listener_names`, stable across two runs

### Step 3 — The broker double (R19-3, 03r-am)

- [ ] loader measurement recorded in the README (cycle refused or accepted); the double's location follows it
- [ ] `deliver(broker, destination, payload)` reaches a `#[listener]` handler with no broker configured; `published(broker)` lists every destination and payload sent through that arm's template, in order; `clearPublished()` empties it; two tests do not see each other's publishes
- [ ] `rakun-messaging/test/container_test.bp` runs through the double — one container cell rewritten to it, the rest already on the in-process broker

### Step 4 — `bootAndExit` (R19-4; after 04 step 4)

- [ ] `test/boot_test.bp`: `bootAndExit(app)` on `fixtures/ok` exits `0`; on `fixtures/{missing-bean,cycle,dup-route,dup-listener,bad-cron,bad-config}` six distinct non-zero codes, each message naming the declaration
- [ ] no port bound (no listening socket opened during the run — `rakun-messaging`'s `rkListenerCount()` counts message listeners, not sockets), no broker connection attempted (in-process broker's connect count 0)
- [ ] `fixtures/fifty` boots and exits in under 2 s (`io.clock`)

### Step 5 — The pairing and the example (R19-5, STD-2)

- [ ] `mocks_pairing_test.bp` uses `testing.mocks`'s `#[mock]` with `#[bean]` if std's `#[mock]` fires outside `mocks.bp` this milestone; otherwise README states the hand-written pairing, box stays open naming the std row
- [ ] `examples/controller-test-example.bp` imports nothing `from "onze"`; compiles against `rakun-test` + `testing.mocks`

### Step 6 — The snapshot layer (RX-5)

→ 20-snap (front 135) step 2

### Step 7 — rakun's own names (decision 318 (8))

- [ ] `MockMvc` and the `@MockBean`-style override renamed after their role in botopink (front's choice,
      recorded in the member README — e.g. `TestClient`, a container override taking a `#[mocks.mock]`
      double); no Spring name or alias left in `rakun-test`'s public surface; 135's `assertResponse`
      follows the new name

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-test`.

Blast radius: step 1 adds a sidecar and `pub` functions, nothing existing changes; step 3 may add a
manifest edge (measured first); step 4 adds fixtures under `test/fixtures/` only.

## Notes

- `FakeRequest` hands handlers `toRequest()` until an implementer converts it to its behavior; not a box, recorded in `AGENTS.md`.
