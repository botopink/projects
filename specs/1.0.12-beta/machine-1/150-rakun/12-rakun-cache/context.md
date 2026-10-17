# Front 12 — Cache and session: the Redis arms in the gate, the tag epoch

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s12 · s2 → 150 s12 · s3 → 150 s12 · s4 → 150 s12 · s5 → 150 s12 · s6 → 150 s12. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — `rakun-session`'s Redis arm has no cell, `rakun-cache`'s Redis provider is
asserted only on `DOWN`; onze 51's single flight and 53's revalidation read this member ·
**State:** not started (premise changed: env-gated cell already deleted)
**Depends on:** 128 · 19 step 1 (RESP double — decision 160) · 04 step 1 (`rkBumpTag` — decision
185: plugs into the core's epoch, no edge to `rakun-client`) · 03r-f … 03r-j (confirmations) ·
`01-checker` step 30 (step 5)
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
- `// LANGUAGE GAP:` markers in `rakun-cache/src/cache.bp` and `test/granularity_test.bp` (file-level
  `'use cache'`): no module annotation by design (315); the cache is chosen per function (316) — step 5.

## Notes

- 03r-f (`hash.strongCacheKey`), 03r-g (private scope with no session), 03r-h (twin keys), 03r-i
  (Redis provider on the session wire), 03r-j (phase `none`, the `none` kill switch) implemented; confirmation only.
- Folding both Redis wires onto 09's `nosql/redis.bp`: a follow-up the member README names; not this front's.
