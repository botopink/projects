# Front 12 — Cache and Session (the Redis arms in the gate)

**Priority:** medium — holds the one rakun cell that passes by skipping (18's Redis arm) and the Redis provider nothing exercises; onze 51's single flight and 53's revalidation read this member
**Carries:** 18
**Depends on:** `128-rakun-consolidation` · `19-rakun-test-utilities` step 1 (the RESP double — decision 160) · `04-rakun-erlang-runtime` step 1 (`rkBumpTag` — decision 185: this member plugs into the core's tag epoch and gains no edge to `rakun-client`) · maintainer 03r-f … 03r-j (confirmations)
**Owns:** `modules/rakun-cache/**` · `modules/rakun-session/**` · `repository/rakun/AGENTS.md` § Cache, § Session
**Does not touch:** `rakun-test` (imports `redisDouble*`) · `rakun-client` (13's; the tag epoch is the only thing that crosses, through the core) · `rakun-data/src/nosql/**` (09's)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R18-1 | `18-rakun-session/README.md` § Step 3 — The three store arms | "The same store test suite runs against all three arms and passes unchanged — the arms are interchangeable or one of them is wrong. — runs on ETS and SQL (`test/store_test.bp`); the Redis arm runs only with `RAKUN_TEST_REDIS_URL` (no Redis on this machine), so it stays open" |
| R62-1 (the assertion) | `62-rakun-request-context/README.md` § Step 1 | "`setPhase(RequestPhase.Action)` is visible to `requestPhase()` and to front 12's `rkCachePhase()` in the same process, asserted through front 12's own verb." — the test lives here (`revalidate_test.bp` imports both) |
| decision 185 (the bump; was 03r-z) | this milestone | `revalidateTag` / `updateTag` / `revalidatePath` bump the core's tag epoch so `rakun-client`'s response cache sees them |
| RX-2 | closed `12-rakun-cache/README.md` | "declared parameter defaults are never applied" — re-measure in `consumer_test.bp` |
| 12's Redis provider | closed `12-rakun-cache/README.md` step 3 (all ticked) | the provider is asserted only on its `DOWN` path (`endpoint_test.bp:83`); against the double it gains the store suite |

## Problem

```
$ cd repository/rakun/modules/rakun-session && botopink test --target erlang
store: Redis arm SKIPPED - RAKUN_TEST_REDIS_URL is not set
… 0 failed
```

The cell is green and asserts `out == ""` — nothing. `rakun-cache`'s Redis provider (`cache.bp:363`,
`rkCacheFlight("redis\n" + rkey, …)`) has no cell that reaches a RESP server at all.

## Current state

- `rakun-session/test/store_test.bp:68-73` — the gated cell; the ETS and SQL arms run the suite
  (`suite(repo)`) and pass.
- `rakun-session/src/store_redis.bp` — the RESP wire (`rkSessRedis`), reused by `rakun-cache`
  (03r-i).
- `rakun-cache`: 7 test files + `fixtures/{imports,twin}`, 55 tests green; `revalidate_test.bp` holds
  the phase cells ("inside a server action revalidateTag and revalidatePath expire").
- `rakun-cache/src/cache.bp:540` and `test/granularity_test.bp:20` carry the two code-side
  `// LANGUAGE GAP:` markers (lg2-m, `'use cache'` at file level) — rows exist; nothing to file.

## Mechanism

19 step 1 ships `rakun-test`'s `redisDoubleStart(port) -> i32` / `redisDoubleLog(port) -> string[]`
/ `redisDoubleFail(port, command)` / `redisDoubleStop(port)` over `rakun_redis_double.erl`, a
`gen_tcp` acceptor speaking RESP2 for `GET SET SETEX DEL INCRBY HGET HSET LPUSH RPOP TTL EXPIRE
PING` with one ETS table per port. A cell starts it on an ephemeral loopback port, points the arm
at `redis://127.0.0.1:<port>`, runs the suite, stops it.

## Gate stance

R18-1's env gate and `SKIPPED` print are **deleted**; the cell runs against the double
unconditionally. No other cell in either member is gated.

## Steps

### Step 1 — The session Redis arm (R18-1)

**Acceptance:**
- [ ] `store_test.bp`: "the suite runs on the Redis arm" starts the double, runs `suite(redisRepository(url, 60))`, asserts `out == ""` and that the double's log contains `SETEX` for the write and `DEL` for the removal; `env.read("RAKUN_TEST_REDIS_URL")` no longer appears in the member
- [ ] the ETS, SQL and Redis arms run the same `suite` unchanged (the box as written)
- [ ] `rotation_test.bp`: rotation on the Redis arm deletes the old id (one `DEL` in the log)

### Step 2 — The cache Redis provider

**Acceptance:**
- [ ] `store_test.bp` (cache): the provider suite (`put`, `get`, TTL, `revalidateTag` deletes, single flight) runs against the double
- [ ] an unreachable port runs the loader uncached and health reports `DOWN` naming redis (03r-i) — the existing `endpoint_test.bp:83` cell, kept
- [ ] `redisDoubleFail(port, "GET")` mid-suite: the read raises once and the next read succeeds (the retry rule stated in the member README)

### Step 3 — The tag epoch (decision 185) and the phase assertion (R62-1)

**Acceptance:**
- [ ] `revalidate_test.bp`: `revalidateTag("t")` bumps `rkTagEpoch("t")` by one; `revalidatePath("/p")` bumps the path's tag; `updateTag` bumps too
- [ ] `revalidate_test.bp`: inside `setPhase(RequestPhase.Action)` the `rkCachePhase()` read answers `"action"` (R62-1's assertion, here)
- [ ] RX-2: the decorator-argument default of `#[cacheable]` / `#[cached]` re-measured in `consumer_test.bp` and the README records the result

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-cache` and `modules/rakun-session`; `grep -rn RAKUN_TEST_ modules/rakun-session modules/rakun-cache` answers nothing
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` § Cache and § Session updated
- [ ] commit on `fix/12-rakun-cache`

## Blast radius

None on consumers: the provider and the arm do not change, their tests do. The tag bump is one
call per revalidation verb; `rakun-client` (13) starts reading it in its own front.

## Notes

- 03r-f (`hash.strongCacheKey`), 03r-g (private scope with no session), 03r-h (twin keys), 03r-i
  (the Redis provider on the session wire), 03r-j (phase `none`, the `none` kill switch) are
  implemented; confirmation only.
- Folding both Redis wires onto 09's `nosql/redis.bp` is named in the member README as a follow-up;
  not this front's.
