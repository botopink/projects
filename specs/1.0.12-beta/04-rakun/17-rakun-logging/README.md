# Front 17 — Logging and metrics: one correlation id, one digest, the endpoints' refusals

**Priority:** medium — the logger every member reports through, in the core after 128 (decision
187); one digest scheme with jhonstart (decision 194) is rakun's one cross-library correctness item ·
**State:** not started
**Depends on:** 128 · `03-bundled-libs/106-log`'s package, landed (decisions 194, 195 — step 2) ·
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
digest implementation, `log`'s, and the logger is `log`'s sink; `loggers` / `logfile` refused
without a grant; metrics and traces share one connection; no test writes under `$HOME`.

## Mechanism

- **R17-3 / R75-2.** `logging/correlation.bp` `correlationFromHeaders(traceparent, xRequestId)`
  answers the header's `traceIdOf`, else `X-Request-Id`, else a fresh id — never `traceId()`. Gains
  a fallback before the fresh id: the current span's `traceId()` (core's after 128), set by the edge
  span before the filter chain. Both boxes assert the same value from two suites.
- **R17-1 (decisions 194, 195).** `logging/digest.bp` `errorDigest(module, errorClass, message,
  topFrames)` deleted for `log`'s; `formats.bp`, `levels.bp`, `digest.bp` import the pure half from
  `log`, erlang cells stay. The logger installs itself as `log`'s sink at boot, so a record
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

## Open

### Step 1 — Correlation and the failure line (R17-3, R75-2, decision 187)

- [ ] `logging/correlation_test.bp`: a request with no `traceparent`, no `X-Request-Id`, inside an edge span, gets `traceId()` as correlation id; with a `traceparent` that header's trace id (existing cell)
- [ ] `rakun-metrics/test/tracing_test.bp`: the logger formatter's line for a traced request carries the span's trace id (R75-2, from the metrics suite against `formats.bp`)
- [ ] `logging/level_test.bp`: the core's failure entry (`after`, request `r1`, text `boom`) produces one `error` line with `correlation=r1` — no sink installed
- [ ] `file_test.bp` and `endpoint_test.bp` write under `BOTOPINK_TEST_TMPDIR`, never `$HOME`

### Step 2 — The digest and the sink (R17-1; after 106's package)

- [ ] `grep -n "fn errorDigest" modules/rakun/src/logging` empty; `digest_test.bp` asserts the lines of `log`'s known-answer fixture through the imported `errorDigest` — fixture is `log`'s, not this member's
- [ ] the logger installs itself as `log`'s sink at boot; a record through `log`'s error-logging function produces one `error` line carrying the digest the call answered (`digest_test.bp`); README documents that onze sets the sink for the render (`07-onze/49` step 3) and that the box ticks when jhonstart 26 step 4's cell reads the same fixture

### Step 3 — Endpoints and export (R17-2, R75-1)

- [ ] `endpoint_test.bp`: `loggers`, `logfile` 403 under default exposure; still 403 with every `rakun.logging.*` key permissive; answer with 76's grant
- [ ] `rakun-metrics/test/export_test.bp`: one push cycle (metrics + traces) opens one connection on the double (accept count 1) after 13's pool; before it the cell is written, marked in the README as waiting on 13, not skipped

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` (`test/logging/` in the run) and `modules/rakun-metrics`;
`grep -rn '\.cache/bp-rakun' modules/rakun/src/logging modules/rakun/test/logging` empty.

Blast radius: an edge-minted request's id changes from fresh to the trace id (same length, format;
onze's `RequestData` reads it through the header). `after()` (04) and regeneration (22) failures
appear in the log at `error`, not on standard error.
