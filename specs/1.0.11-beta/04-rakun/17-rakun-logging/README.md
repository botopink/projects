# Front 17 — Logging and Metrics (the observability tail)

**Priority:** medium — the logger every other member reports through, in the core after 128 (decision 187); one digest scheme with jhonstart (decision 194) is the only cross-library correctness item rakun owes
**Carries:** 75
**Depends on:** `128-rakun-consolidation` (it merges `rakun-logging` into the core) · `03-bundled-libs/106-log`'s package, landed (step 2 — decisions 194 and 195: `errorDigest` and the pure half live in the bundled `log`; this member imports them and installs itself as `log`'s sink) · `13-rakun-http-clients` step 2 (the keep-alive pool, for R75-1) · maintainer 03r-s (confirmation). The core's own failure-report seam does not exist (decision 187 supersedes 184): the core calls the logger directly
**Owns:** `modules/rakun/src/logging/**`, `modules/rakun/test/logging/**`, `modules/rakun/src/sidecars/rakun_logging.erl` — where `rakun-logging`'s files live after 128; the paths below that start with `rakun-logging` read as these · `modules/rakun-metrics/**` · `repository/rakun/AGENTS.md` § Logging, § Metrics
**Does not touch:** the rest of the core (04's — `botopink.json` and `src/root.bp` included) · `rakun-actuator` (11's; the `loggers` / `logfile` refusal is asserted here through 76's exposure rule, not by editing it) · `rakun-client` · `libs/log/**` (`03-bundled-libs/106-log` — this front imports the package, it does not write it) · `rakun-web/src/error.bp`'s `problem_digest` cell (106's own consumer commit, after 65)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R17-1 | `17-rakun-logging/README.md` § Step 5 — `error.digest` | "Front 31's client half renders the digest string this front produced; the two agree in a shared fixture rather than by convention." |
| R17-2 | same § Step 7 — The `loggers` and `logfile` endpoints | "Both routes are refused with front 11's standard response when the caller is not authorized, and no key in this module changes that." |
| R17-3 | `75-rakun-observability-metrics/README.md` § Step 8 (the blocker it names) | "front 17's correlation id takes the trace id from an inbound `traceparent`, but for a trace minted at the edge it mints its own id instead of reading `traceId()`; wiring that is front 17's" |
| R75-1 | same § Step 5 — OTLP and StatsD | "Metrics and spans share one OTLP connection — open: front 13's client opens one connection per request and closes it" |
| R75-2 | same § Step 8 — tracing | "Front 17's log line carries the same trace id, asserted from this front's test against front 17's formatter" |
| decision 187 (was 03r-y) | this milestone | the core and `rakun-app` log a failure through the logger directly — it is the core's after 128; nothing is installed |

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
- R17-1 (decisions 194, 195): the digest has one implementation, `errorDigest` in the bundled
  `log`, and one known-answer fixture, `log`'s, on every target. This member's `errorDigest`
  (`digest.bp:63-70`) is deleted for it; `formats.bp`, `levels.bp` and `digest.bp` import the pure
  half from `log`, and the erlang cells stay here. The member installs itself as `log`'s sink at
  boot, so a record jhonstart's boundary writes through `log` reaches rakun's handlers and carries
  the digest the fallback shows. jhonstart and rakun agree because they call one function, not
  because two functions are compared.
- R17-2: `endpoint_test.bp` mounts the actuator host with 76's default exposure and asserts 403
  for `loggers` and `logfile` without a grant, and that setting every `rakun.logging.*` key changes
  nothing about it.
- R75-1: after 13's pool, `export.bp`'s two pushes (metrics, traces) reuse one origin connection;
  the double's accept count is 1 for a push cycle.
- Decision 187: the logger exposes one entry the core's `after()` (04 step 5) and rakun-app's
  regeneration (22 step 3) call — a line at `error` with the request id as the correlation field.

## Gate stance

No env-gated cell. The OTLP collector is an in-process HTTP double (13's), the log file lives under
`BOTOPINK_TEST_TMPDIR` (today `endpoint_test.bp:96` and `file_test.bp:32` write under `$HOME/.cache/bp-rakun/` — this front moves them to the scratch directory, which is a gate hygiene item of its own).

## Steps

### Step 1 — Correlation and the failure line (R17-3, R75-2, decision 187)

**Acceptance:**
- [ ] `correlation_test.bp`: a request with no `traceparent` and no `X-Request-Id`, inside an edge span, gets `traceId()` as its correlation id; with a `traceparent` it gets that header's trace id (the existing cell)
- [ ] `rakun-metrics/test/tracing_test.bp`: the log line rendered by 17's formatter for a traced request carries the span's trace id (R75-2, asserted from the metrics suite against `formats.bp`)
- [ ] `level_test.bp` asserts that the failure entry the core calls (`after`, request `r1`, text `boom`) produces one `error` line with `correlation=r1` — no sink is installed (decision 187)
- [ ] `file_test.bp` and `endpoint_test.bp` write under `BOTOPINK_TEST_TMPDIR`, never `$HOME`

### Step 2 — The digest and the sink (R17-1, decisions 194 and 195)

After `03-bundled-libs/106`'s package has landed.

**Acceptance:**
- [ ] `grep -n "fn errorDigest" modules/rakun/src/logging` is empty; `digest_test.bp` asserts the lines of `log`'s known-answer fixture through the imported `errorDigest` — the fixture is `log`'s, not a file of this member
- [ ] the member installs itself as `log`'s sink at boot; a record written through `log`'s error-logging function produces one `error` line carrying the digest the call answered, asserted in `digest_test.bp`; the README documents that onze sets the sink for the render (`07-onze/49` step 3) and that the box ticks when jhonstart 26 step 4's cell reads the same fixture

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
With the logger in the core, `after()` failures (04) and regeneration failures (22) appear in the
log at `error` instead of on standard error — the behaviour the boxes asked for.

## Notes

03r-s (OTLP as HTTP/JSON) is implemented; confirmation only.
