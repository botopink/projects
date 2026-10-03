# Front 17 — Logging and metrics: one correlation id, one digest, the endpoints' refusals

**Priority:** medium — the logger every member reports through, in the core after 128 (decision 187);
one digest scheme with jhonstart (decision 194) is the one cross-library correctness item rakun owes ·
**State:** not started
**Depends on:** 128 · `03-bundled-libs/106-log`'s package, landed (decisions 194, 195 — step 2) ·
13 step 2 (the keep-alive pool, R75-1) · 03r-s (confirmation)
**Owns:** `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` ·
`modules/rakun-metrics/**` · `repository/rakun/AGENTS.md` § Logging, § Metrics
**Does not touch:** the rest of the core (04's — `botopink.json` and `src/root.bp` included) ·
`rakun-actuator` (11's; the `loggers` / `logfile` refusal is asserted here through 76's exposure rule) ·
`rakun-client` · `libs/log/**` (106's — imported, not written) · `rakun-web/src/error.bp`'s
`problem_digest` cell (106's own consumer commit, after 65)

## Goal

An edge-minted request's correlation id is its trace id, so the log line and the span agree; the
core's failure entry (04's `after()`, 22's regeneration) is one `error` line with the request id;
the digest has one implementation, `log`'s, and the logger is `log`'s sink; `loggers` / `logfile`
are refused without a grant; metrics and traces share one connection; no test writes under `$HOME`.

## Mechanism

- **R17-3 / R75-2.** `logging/correlation.bp` `correlationFromHeaders(traceparent, xRequestId)`
  answers `traceIdOf` of the header, else `X-Request-Id`, else a fresh id — never `traceId()`. It
  gains a third fallback before the fresh id: the current span's `traceId()` (the core's after 128),
  which the edge span sets before the filter chain runs. Both boxes assert the same value from two
  suites.
- **R17-1 (decisions 194, 195).** `logging/digest.bp` `errorDigest(module, errorClass, message,
  topFrames)` is deleted for `log`'s; `formats.bp`, `levels.bp`, `digest.bp` import the pure half from
  `log`, the erlang cells stay here. The logger installs itself as `log`'s sink at boot, so a record
  jhonstart's boundary writes through `log` reaches rakun's handlers with the digest the fallback
  shows — one function, not two compared.
- **R17-2.** `endpoint_test.bp` mounts the actuator host with 76's default exposure and asserts 403
  for `loggers` and `logfile` without a grant, and that no `rakun.logging.*` key changes it.
- **R75-1.** After 13's pool, `rakun-metrics`' `export.bp` pushes metrics and traces (OTLP/JSON,
  03r-s) over one origin connection; the double's accept count is 1 per push cycle.
- **The failure entry (decision 187).** One entry the core's `after()` (04 step 5) and `rakun-app`'s
  regeneration (22 step 3) call: a line at `error` with the request id as the correlation field. No
  sink is installed.
- **Scratch files.** `test/logging/file_test.bp` and `endpoint_test.bp` write under
  `$HOME/.cache/bp-rakun/front-17/`; they move to `BOTOPINK_TEST_TMPDIR`. The OTLP collector is 13's
  in-process HTTP double; nothing is env-gated.

## Open

### Step 1 — Correlation and the failure line (R17-3, R75-2, decision 187)

- [ ] `logging/correlation_test.bp`: a request with no `traceparent` and no `X-Request-Id`, inside an edge span, gets `traceId()` as its correlation id; with a `traceparent` it gets that header's trace id (the existing cell)
- [ ] `rakun-metrics/test/tracing_test.bp`: the log line rendered by the logger's formatter for a traced request carries the span's trace id (R75-2, asserted from the metrics suite against `formats.bp`)
- [ ] `logging/level_test.bp`: the failure entry the core calls (`after`, request `r1`, text `boom`) produces one `error` line with `correlation=r1` — no sink installed
- [ ] `file_test.bp` and `endpoint_test.bp` write under `BOTOPINK_TEST_TMPDIR`, never `$HOME`

### Step 2 — The digest and the sink (R17-1; after 106's package)

- [ ] `grep -n "fn errorDigest" modules/rakun/src/logging` is empty; `digest_test.bp` asserts the lines of `log`'s known-answer fixture through the imported `errorDigest` — the fixture is `log`'s, not a file of this member
- [ ] the logger installs itself as `log`'s sink at boot; a record written through `log`'s error-logging function produces one `error` line carrying the digest the call answered (`digest_test.bp`); the README documents that onze sets the sink for the render (`07-onze/49` step 3) and that the box ticks when jhonstart 26 step 4's cell reads the same fixture

### Step 3 — Endpoints and export (R17-2, R75-1)

- [ ] `endpoint_test.bp`: `loggers` and `logfile` are 403 under the default exposure; with every `rakun.logging.*` key set to its permissive value they are still 403; with 76's grant they answer
- [ ] `rakun-metrics/test/export_test.bp`: one push cycle (metrics + traces) opens one connection on the double (accept count 1) after 13's pool; before it the cell is written and marked in the README as waiting on 13, not skipped

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` (the `test/logging/` files in the run) and `modules/rakun-metrics`;
`grep -rn '\.cache/bp-rakun' modules/rakun/src/logging modules/rakun/test/logging` empty.

Blast radius: an edge-minted request's id changes from a fresh id to the trace id (same length and
format; onze's `RequestData` reads it through the header). `after()` failures (04) and regeneration
failures (22) appear in the log at `error` instead of on standard error.
