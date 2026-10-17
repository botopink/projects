# Front 17 — Logging and metrics: one correlation id, one digest, the endpoints' refusals

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s14 · s2 → 150 s14 · s3 → 150 s14 · s4 → 150 s14. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — the logger every member reports through, in the core after 128 (decision
187); one digest scheme with jhonstart (decision 194) is rakun's one cross-library correctness item ·
**State:** not started
**Depends on:** 128 · `03-bundled-libs/106-log`'s package, landed (decisions 194, 195 — step 2), and its
step 3 (`log`'s sinks, decision 349) ·
13 step 2 (keep-alive pool, R75-1) · 03r-s (confirmation)
**Owns:** `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` ·
`modules/rakun-metrics/**` · `repository/rakun/AGENTS.md` § Logging, § Metrics
**Does not touch:** rest of the core (04's — `botopink.json`, `src/root.bp` included) ·
`rakun-actuator` (11's; `loggers` / `logfile` refusal asserted here through 76's exposure rule) ·
`rakun-client` · `libs/log/**` (106's — imported, not written) · `rakun-web/src/error.bp`'s
`problem_digest` cell (106's own consumer commit, after 65)

## Goal

An edge-minted request's correlation id is its trace id (log line and span agree); the core's
failure entry (04's `after()`, 22's regeneration) is one `error` line with the request id; one
digest implementation, `log`'s, and the core installs one of `log`'s sinks at boot (349); `loggers` / `logfile` refused
without a grant; metrics and traces share one connection; no test writes under `$HOME`.

## Mechanism

- **R17-3 / R75-2.** `logging/correlation.bp` `correlationFromHeaders(traceparent, xRequestId)`
  answers the header's `traceIdOf`, else `X-Request-Id`, else a fresh id — never `traceId()`. Gains
  a fallback before the fresh id: the current span's `traceId()` (core's after 128), set by the edge
  span before the filter chain. Both boxes assert the same value from two suites.
- **R17-1 (decisions 194, 195).** `logging/digest.bp` `errorDigest(module, errorClass, message,
  topFrames)` deleted for `log`'s; `formats.bp`, `levels.bp`, `digest.bp` import `log`; the sink and
  capture cells go to `log` (349) — the core keeps the correlation id, its typed config and the
  endpoints, and at boot installs `log`'s sink configured from `rakun.logging.*` and calls
  `log.captureRuntimeReports()`, so a record
  jhonstart's boundary writes through `log` reaches rakun's handlers with the fallback's digest —
  one function, not two compared.
- **R17-2.** `endpoint_test.bp` mounts the actuator host with 76's default exposure, asserts 403 for
  `loggers`, `logfile` without a grant, unchanged by any `rakun.logging.*` key.
- **R75-1.** After 13's pool, `rakun-metrics`' `export.bp` pushes metrics and traces (OTLP/JSON,
  03r-s) over one origin connection; double's accept count 1 per push cycle.
- **Failure entry (decision 187).** One entry called by the core's `after()` (04 step 5) and
  `rakun-app`'s regeneration (22 step 3): an `error` line, request id as correlation field. No sink.
- **Scratch files.** `test/logging/file_test.bp`, `endpoint_test.bp` write under
  `$HOME/.cache/bp-rakun/front-17/`; move to `BOTOPINK_TEST_TMPDIR`. OTLP collector is 13's
  in-process HTTP double; nothing env-gated.
