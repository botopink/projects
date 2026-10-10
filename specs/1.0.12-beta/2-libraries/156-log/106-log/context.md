# Front 106 — log: a shared `log`, one error digest, one way to the logger

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [156-log](../README.md): s2 → 156 s1 · s3 → 156 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — `05-jhonstart/26` step 4, `04-rakun/17`, `07-onze/49` step 3 written against it
(decisions 194, 195) · **State:** partial: step 1 (the package) on feat; step 2 open; step 3 built on
erlang, beam and commonJS (`front/106-s3`), its wasm column waiting on two gap rows (`fileSink` on wasm: decision 405)
**Depends on:** step 2 — `04-rakun/17` and `05-jhonstart/26` step 4 (their boxes), `04-rakun/65`
landed (own commit)
**Owns:** `repository/log/**` · one consumer commit:
`repository/rakun/modules/rakun-web/src/error.bp` (`problem_digest` erlang cell) and
`rakun-web/src/sidecars/rakun_chain.erl`'s `problem_digest/1` — after `04-rakun/65`, never in a wave
with it, `08-bpp/123` or `104-http` step 5 (same member, decision 188)
**Does not touch:** owners' consumer edits, each in its own step:
`repository/rakun/modules/rakun/src/logging/**` (`04-rakun/17` — `rakun-logging`'s home after
`04-rakun/128`, decision 187; imports `log`, installs one of its sinks — 349),
`repository/jhonstart/modules/jhonstart/src/error_boundary.bp` (`05-jhonstart/26` step 4), onze's sink
line (`07-onze/49` step 3) · `rakun-logging`'s `cells.bp` (its sink and capture cells are ported here by step 3
and deleted by `04-rakun/17`; the correlation-id cell stays rakun's), the `rkProp` levels and groups (a typed
`#[config]` record with 299 — rakun's), actuator endpoints

## Goal

One digest everywhere: `log.errorDigest(module, errorClass, message, topFrames)` — first 16 hex of
`strongHash` over `module|errorClass|message|topFrames`, frames normalised (first three, line numbers
stripped), one known-answer fixture on every target (decision 194). Three remain beside it:
jhonstart `digestOf(message)` (`contentHash`, 8 hex, `error_boundary.bp`), rakun-logging
`errorDigest` (`digest.bp`), rakun-web's `problem_digest` erlang cell. The render reaches the logger
through `Logger.logError` (writes the record via the injected sink, answers the digest — the
fallback shows the log line's digest); no `RenderHooks.onError` (decision 195).
