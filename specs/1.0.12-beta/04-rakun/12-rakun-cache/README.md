# Front 12 — Cache and session: the Redis arms in the gate, the tag epoch

**Priority:** medium — `rakun-session`'s Redis arm has no cell, `rakun-cache`'s Redis provider is
asserted only on `DOWN`; onze 51's single flight and 53's revalidation read this member ·
**State:** not started (premise changed: env-gated cell already deleted)
**Depends on:** 128 · 19 step 1 (RESP double — decision 160) · 04 step 1 (`rkBumpTag` — decision
185: plugs into the core's epoch, no edge to `rakun-client`) · 03r-f … 03r-j (confirmations)
**Owns:** `modules/rakun-cache/**` · `modules/rakun-session/**` · `repository/rakun/AGENTS.md` § Cache,
§ Session
**Does not touch:** `rakun-test` (imports `redisDouble*`) · `rakun-client` (13's; only the tag epoch
crosses, through the core) · `rakun-data/src/nosql/**` (09's)

## Goal

Session store suite runs on its third arm, Redis, against 19's double; the cache's Redis provider
runs its suite against the double; revalidation verbs bump the core's tag epoch; R62-1's phase
assertion complete.

## Mechanism

- `00-gate/99` deleted the cell that read `RAKUN_TEST_REDIS_URL`, printed `SKIPPED` and passed;
  `rakun-session/test/store_test.bp`'s Redis arm has no cell (`deferred.md` row "The Redis arm of
  `rakun-session`'s store suite"); `RAKUN_TEST_` appears nowhere in `modules/`. ETS and SQL arms run
  `suite(repo)`. `rakun-session/src/store_redis.bp` is the RESP wire (`rkSessRedis`), reused by
  `rakun-cache`'s provider (`cache.bp` `rkCacheFlight("redis\n" + rkey, …)`, 03r-i).
- A cell starts `redisDoubleStart(0)` on an ephemeral loopback port, points the arm at
  `redis://127.0.0.1:<port>`, runs the suite, reads `redisDoubleLog(port)`, stops it. Nothing gated.
- `// LANGUAGE GAP:` markers in `rakun-cache/src/cache.bp` and `test/granularity_test.bp` (lg2-m,
  file-level `'use cache'`) have their rows; nothing to file.

## Open

### Step 1 — The session Redis arm (R18-1)

- [ ] `store_test.bp`: "the suite runs on the Redis arm" starts the double, runs `suite(redisRepository(url, 60))`, asserts `out == ""` and the double's log has `SETEX` for the write and `DEL` for the removal; no env variable read
- [ ] ETS, SQL and Redis arms run the same `suite` unchanged ("the arms are interchangeable or one of them is wrong")
- [ ] `rotation_test.bp`: rotation on the Redis arm deletes the old id (one `DEL` in the log)
- [ ] the `deferred.md` row keeps only the real-server run

### Step 2 — The cache Redis provider

- [ ] `store_test.bp` (cache): provider suite (`put`, `get`, TTL, `revalidateTag` deletes, single flight) runs against the double
- [ ] an unreachable port runs the loader uncached, health `DOWN` naming redis (03r-i) — existing `endpoint_test.bp` cell "health is UP on ets and DOWN naming redis when Redis does not answer", kept
- [ ] `redisDoubleFail(port, "GET")` mid-suite: the read raises once, the next succeeds (retry rule stated in the member README)

### Step 3 — The tag epoch (decision 185) and the phase assertion (R62-1, RX-2)

- [ ] `revalidate_test.bp`: `revalidateTag("t")` bumps `rkTagEpoch("t")` by one; `revalidatePath("/p")` bumps the path's tag; `updateTag` bumps too
- [ ] `revalidate_test.bp`: after `setPhase(RequestPhase.Action)`, `requestPhase()` and `rkCachePhase()` both answer the action phase in the same process — cell "in a server action all three verbs are legal" (already asserts `rkCachePhase() == "action"` for a request opened in that phase) gains the `setPhase` call and the `requestPhase()` read; 04's R62-1 ticks with it
- [ ] RX-2: decorator-argument default of `#[cacheable]` / `#[cached]` re-measured in `consumer_test.bp`; README records the result

### Step 4 — references, not strings (decision 281)

- [ ] `#[cacheable(products)]` takes a `Cache<T>` value whose `T` is the function's return (280
      example 5); the cache's own name (`Cache<Product[]>("products")`) stays a string

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-cache` and `modules/rakun-session`; `grep -rn RAKUN_TEST_ modules/rakun-session modules/rakun-cache` empty.

Blast radius: none on consumers — provider and arm unchanged, their tests change. Tag bump: one call
per revalidation verb; `rakun-client` reads it in 13.

## Notes

- 03r-f (`hash.strongCacheKey`), 03r-g (private scope with no session), 03r-h (twin keys), 03r-i
  (Redis provider on the session wire), 03r-j (phase `none`, the `none` kill switch) implemented; confirmation only.
- Folding both Redis wires onto 09's `nosql/redis.bp`: a follow-up the member README names; not this front's.
