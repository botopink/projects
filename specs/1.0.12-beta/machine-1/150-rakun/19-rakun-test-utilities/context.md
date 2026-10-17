# Front 19 — rakun test utilities: the Redis double, context control, the broker double, `bootAndExit`

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s10 · s2 → 150 s21 · s3 → 150 s21 · s4 → 150 s21 · s5 → 150 s21 · s7 → 150 s21. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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
example current; the snapshot layer is front 135's (`20-snap`, 390).

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

## Notes

- `FakeRequest` hands handlers `toRequest()` until an implementer converts it to its behavior; not a box, recorded in `AGENTS.md`.
