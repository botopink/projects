# Front 17 — Logging and Metrics (the observability tail)

**Priority:** medium — installs the failure sink every other member reports through (03r-y); one digest scheme with jhonstart (31-b) is the only cross-library correctness item rakun owes
**Carries:** 75
**Depends on:** `04-rakun-erlang-runtime` step 1 (`rkInstallFailureSink`) · `13-rakun-http-clients` step 2 (the keep-alive pool, for R75-1) · maintainer 31-b (the digest scheme; recommendation (a): jhonstart's `onError` hook set by onze to `logErrorWithDigest`), 03r-s (confirmation)
**Owns:** `modules/rakun-logging/**` · `modules/rakun-metrics/**` · `repository/rakun/AGENTS.md` § Logging, § Metrics
**Does not touch:** `rakun-actuator` (11's; the `loggers` / `logfile` refusal is asserted here through 76's exposure rule, not by editing it) · `rakun-client`

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R17-1 | `17-rakun-logging/README.md` § Step 5 — `error.digest` | "Front 31's client half renders the digest string this front produced; the two agree in a shared fixture rather than by convention." |
| R17-2 | same § Step 7 — The `loggers` and `logfile` endpoints | "Both routes are refused with front 11's standard response when the caller is not authorized, and no key in this module changes that." |
| R17-3 | `75-rakun-observability-metrics/README.md` § Step 8 (the blocker it names) | "front 17's correlation id takes the trace id from an inbound `traceparent`, but for a trace minted at the edge it mints its own id instead of reading `traceId()`; wiring that is front 17's" |
| R75-1 | same § Step 5 — OTLP and StatsD | "Metrics and spans share one OTLP connection — open: front 13's client opens one connection per request and closes it" |
| R75-2 | same § Step 8 — tracing | "Front 17's log line carries the same trace id, asserted from this front's test against front 17's formatter" |
| 03r-y (install) | this milestone | rakun-logging installs the core's failure sink at boot |

## Problem

A trace minted at the edge (no inbound `traceparent`) gets a correlation id that is not its trace
id (`correlation.bp:32-36`: `traceIdOf` of the header, else `X-Request-Id`, else a fresh id — never
`traceId()`), so the log line and the span disagree on the request. The digest jhonstart shows in
a fallback is `contentHash(message)`; the one rakun logs is 16 hex of `strongHash` over four parts;
no fixture holds both. `POST /actuator/loggers` is guarded by 76 but 17's own tests do not assert
the refusal.

## Current state

- `rakun-logging`: 7 test files, 54 tests green. `correlation.bp:25` `traceIdOf`, `:32`
  `correlationFromHeaders(traceparent, xRequestId)`. `digest.bp` `errorDigest(module, errorClass,
  message, topFrames)` and `logErrorWithDigest`. `endpoints.bp` registers `loggers` / `logfile`
  through `rakun-actuator-api`.
- `rakun-metrics`: 6 files, 41 tests green; `export.bp` pushes OTLP/JSON (03r-s) through
  `rakun-client`, one request per push, one connection per request.

## Mechanism

- R17-3 / R75-2: `correlationFromHeaders` gains a third fallback before the fresh id — the
  current span's trace id (`rakun-actuator-api`'s `traceId()`), which the edge span sets before the
  filter chain runs. One line; both boxes assert the same value from two suites.
- R17-1: a fixture file `modules/rakun-logging/test/fixtures/digest.txt` holding
  `module|class|message|frames` → digest lines; `digest_test.bp` asserts every line; jhonstart 31's
  test reads the same file by path (`../../../rakun/modules/rakun-logging/test/fixtures/digest.txt`)
  — or, under 31-b (a), jhonstart never computes a digest and the fixture is rakun's alone, read
  by onze's wiring test. The front writes the fixture either way; which side reads it is 31-b's.
- R17-2: `endpoint_test.bp` mounts the actuator host with 76's default exposure and asserts 403
  for `loggers` and `logfile` without a grant, and that setting every `rakun.logging.*` key changes
  nothing about it.
- R75-1: after 13's pool, `export.bp`'s two pushes (metrics, traces) reuse one origin connection;
  the double's accept count is 1 for a push cycle.
- 03r-y: `setup.bp` calls `rkInstallFailureSink` with a function that logs at `error` with the
  request id as the correlation field.

## Gate stance

No env-gated cell. The OTLP collector is an in-process HTTP double (13's), the log file lives under
`BOTOPINK_TEST_TMPDIR` (today `endpoint_test.bp:96` and `file_test.bp:32` write under `$HOME/.cache/bp-rakun/` — this front moves them to the scratch directory, which is a gate hygiene item of its own).

## Steps

### Step 1 — Correlation and the sink (R17-3, R75-2, 03r-y)

**Acceptance:**
- [ ] `correlation_test.bp`: a request with no `traceparent` and no `X-Request-Id`, inside an edge span, gets `traceId()` as its correlation id; with a `traceparent` it gets that header's trace id (the existing cell)
- [ ] `rakun-metrics/test/tracing_test.bp`: the log line rendered by 17's formatter for a traced request carries the span's trace id (R75-2, asserted from the metrics suite against `formats.bp`)
- [ ] `setup.bp` installs the failure sink at boot; `level_test.bp` asserts that `rkReportFailure("after", "r1", "boom")` produces one `error` line with `correlation=r1`
- [ ] `file_test.bp` and `endpoint_test.bp` write under `BOTOPINK_TEST_TMPDIR`, never `$HOME`

### Step 2 — The digest fixture (R17-1, 31-b)

**Acceptance:**
- [ ] `test/fixtures/digest.txt` exists with ten lines; `digest_test.bp` asserts `errorDigest` over each
- [ ] under 31-b (a): the README documents the `onError` wiring onze makes and the fixture is the source of truth; under (b)/(c): the fixture is read by jhonstart 31's test (its path recorded in `04-jhonstart/31`) — the box ticks when the other side's cell reads it

### Step 3 — Endpoints and export (R17-2, R75-1)

**Acceptance:**
- [ ] `endpoint_test.bp`: `loggers` and `logfile` are 403 under the default exposure; with every `rakun.logging.*` key set to its permissive value they are still 403; with 76's grant they answer
- [ ] `export_test.bp`: one push cycle (metrics + traces) opens one connection on the double (accept count 1) after 13's pool; before it, the cell is written and marked as waiting on 13 in the README, not skipped

## Gate

- [ ] `botopink test --target erlang` green in both members; `grep -rn '\.cache/bp-rakun' modules/rakun-logging` answers nothing
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/17-rakun-logging`

## Blast radius

The correlation fallback changes the id of edge-minted requests from a fresh id to the trace id —
same length, same format; onze's `RequestData` reads it through the header and is unaffected.
Installing the sink changes where `after()` failures (04) and regeneration failures (22) appear:
from standard error to the log at `error` — the behaviour the boxes asked for.

## Notes

03r-s (OTLP as HTTP/JSON) is implemented; confirmation only.
