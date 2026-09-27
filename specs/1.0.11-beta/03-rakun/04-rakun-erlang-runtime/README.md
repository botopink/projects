# Front 04 — rakun Erlang Runtime (the core's tail)

**Priority:** critical — four B fronts (13, 17, 22, 12) wait on the two seams of step 1, onze 49 waits on the page `Request` enumerating its query and headers (R62-3), and 88's `beans` waits on the scan registry recording injected fields
**Carries:** 05 · 06 · 14 · 62 (and the files of 72; 74 is its own front)
**Depends on:** none in this track. Maintainer: 03r-y, 03r-z (step 1), 03r-b/c/d/e (confirmations). Compiler: lg2-e (R06-4's comptime refusal), lg2-g (`@typeName<T>()` — the context's registry key stays a string), lg2-j (comptime state — the `#[provides]` duplicate check runs at boot, not comptime)
**Owns:** `modules/rakun/**` except 74's four files (`src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`) · `modules/rakun/test/fixtures/**` · `modules/rakun/botopink.json`, `src/root.bp` · `repository/rakun/AGENTS.md` § the core sections
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen) · 74's files · any other member · `repository/botopink-lang/**`

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/`) | Box, as written |
|---|---|---|
| R04-1 | `04-rakun-erlang-runtime/README.md` § Step 7 — Boot options | "With a `banner.txt` present, `${application.version}`, `${rakun.version}` and `${otp.version}` are substituted; the file is printed once, before the first log line" · "`rakun.main.banner-mode=off` prints nothing; a test run prints nothing regardless of the setting" · "`rakun.main.headless=true` with `keep-alive=true` does not halt; with `keep-alive=false` it halts with status 0" |
| R04-2 | same § Step 8 — Startup failure diagnostics | "A dependency cycle prints the construction stack, innermost last" |
| R04-3 | same § Step 10 | "`zig build test-libs -- --target erlang --lib rakun` is green … the `rakun erlang 2` line is now stale" — closes on tick: the erlang ledger lines were rewritten in 1.0.10 |
| R05-1 | `05-rakun-config-profiles/README.md` § Step 7 — `#[configurationProperties]` binding | "`bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration` and `DataSize` all coerce" |
| R05-2 | same § Step 9 — Validation and the catalogue | "The report names the key, the offending value and the source file it came from" |
| R06-1 | `06-rakun-context-api/README.md` § Step 2 — `Context` | "`ctx.beanNames()` matches `rkScannedNames()` filtered to `#[managed]` types" |
| R06-2 | same § Step 3 — `#[provides]`, qualifiers and primary | "Two `#[provides]` of the same type without qualifiers fail the build naming both functions" |
| R06-3 | same § Step 4 — Lifecycle | "`#[postConstruct]` runs after the instance is constructed and before `eagerInit` returns" |
| R06-4 | same § Step 6 — Scopes | "`#[scope("request")]` on a type whose factory is constructor-injected somewhere fails at comptime naming the injection site's limitation" |
| R06-5 | same § Step 7 — Eager initialization and lazy | "With defaults, every registered bean is constructed before `Rakun.run` returns" · "A component whose `#[value]` key is missing fails the boot, not the first request" |
| R06-6 | same § Step 8 — Shutdown and exit codes | "With no generator, a clean stop is status 0 and a failed boot is non-zero" |
| R06-7 | same § Step 9 — Retire the `rakun.d.bp` stub | "A consumer that previously named the behavior in a signature still compiles, because the concrete type carries `resolve`/`has` with the same names" |
| R14-1 | `14-rakun-validation/README.md` § Step 6 — Boot-time configuration validation | "A valid configuration adds no measurable startup cost beyond one pass over the record's fields." |
| R62-1 | `62-rakun-request-context/README.md` § Step 1 — The frame | "`setPhase(RequestPhase.Action)` is visible to `requestPhase()` and to front 12's `rkCachePhase()` in the same process, asserted through front 12's own verb." — the assertion is 12's (its test imports both); this front ticks when 12 lands it |
| R62-2 | same § Step 5 — `after()` | "A deferred function that raises does not affect the response, and the failure is reported once to front 17 with the request id." |
| R62-3 | closed `status.md` L82 (RX-4) | "the page `Request` enumerates neither its query nor its headers, so onze's `RequestData.query` / `.headers` are empty" — `headerNames()` / `headers()` / `queryDict()` exist on the core; the page `Request` onze receives must expose them |
| R64-1 (core half) | `64-rakun-i18n-routing/README.md` § Step 4 | "the raw bytes of the original query are not available to a filter" — the core `Request` keeps `rawQuery()`; the redirect (22's) reuses it |
| RX-1 | closed `status.md` L117 | `modules/rakun/test/config_test.bp:548` — `?? Doc(…)` replaced by `if (x == null)` narrowing |
| RX-2 | closed READMEs of 14 and 72 | "declared parameter defaults are never applied" — re-measure the decorator-argument case in `config_check_test.bp` and `autoconfig_test.bp`; record the result |

## Problem

`cd repository/rakun/modules/rakun && botopink test --target erlang` is green (355 tests, 0 failed),
and eighteen acceptance boxes of the core's five fronts are still open: three boot options are not
asserted, the DI cycle message has no construction stack, `beanNames()` is not compared to the scan,
two unqualified `#[provides]` of one type do not fail, a missing `#[value]` fails at first injection
instead of at boot, `after()`'s failure goes to standard error, and the page `Request` onze builds
`RequestData` from cannot list its own headers or query. The `rakun.d.bp` stub is still in
`botopink.json`'s `files`.

## Current state

Measured at the opening of the milestone on `modules/rakun`:

- `test/`: 21 files, 355 tests green on erlang; `test/fixtures/` holds 14 scratch projects
  (`activate`, `autoconfig`, `config`, `cycle`, `groupcycle`, `groups`, `imports`, `name`, `order`,
  `phcycle`, `phmissing`, `placeholders`, `random`, `tree`, `typed`).
- `src/runtime.bp:212` — `pub declare fn rkOnReset(name: string, reset: fn() -> i32) -> i32;` exists
  and `rakun-test/src/context.bp:7` documents it; nothing outside the core registers with it yet.
- `src/request_context.bp` — `after()` runs deferred functions; a raise is written to standard error
  (`request_context_test.bp` "a deferred function that outlives the budget is killed and the kill is
  logged" asserts the kill, not the report).
- `src/context.bp` — `bootSequenceFor` runs the configuration check after event 3 and before the eager
  pass (03r-d); the scan registry records the component name only (why 88's `beans` cannot print
  injected fields).
- `botopink.json` `files` still lists `rakun.d.bp`.
- The core `Request` behavior: `headerNames()`, `headers()`, `queryDict()` exist on the core's request
  (closed `status.md` § onze-adopt), but the page `Request` `rakun-app` hands a `PageRenderer` does
  not expose them (onze-server hardcodes `[]` at `onze-server/src/server.bp:76-77`).

## Mechanism

- **Seams (step 1).** The core is the only member every other member depends on, so a hook two
  members must share without depending on each other lives here: `rakun_runtime.erl` already keeps
  the ETS tables the reset hooks use (`rkOnReset`). 03r-y adds a failure sink; 03r-z adds a tag epoch.
- **`#[provides]` duplicates (R06-2).** The decorator emits one registration per function; a
  comptime check across two decorator invocations needs lg2-j. Until then the refusal is at boot,
  in `bootSequenceFor`, naming both functions — the box's "fail the build" is read as "fail before
  the first request"; the README records which.
- **Eager by default (R06-5).** `bootSequenceFor` constructs `#[managed]` types on the eager pass;
  a `#[value]` binding is read at construction, so a missing key already fails inside the pass — the
  open box is the assertion, in `context_test.bp`, that `Rakun.run` does not return.
- **Page `Request` (R62-3).** `rakun-app`'s dispatch builds the page request from the core's request
  frame; the frame holds the raw header list and the raw query (`rakun_request_context.erl`). The
  behavior gains `headerNames()`, `headers()`, `queryDict()`, `rawQuery()` with the core's existing
  implementations; `rakun-app` (22) forwards them.

## Gate stance

No cell of this member is env-gated or skipped. R04-3's box closes on tick (`zig build test-libs`
lists `rakun · erlang` green; the ledger's erlang lines for rakun were deleted in 1.0.10). The
`botopink run` of the examples is 73's re-measure, not this front's.

## Steps

### Step 1 — The two seams (lands first, alone)

`rkReportFailure(kind, requestId, text)` + `rkInstallFailureSink(sink)` (03r-y) and
`rkTagEpoch(tag)` + `rkBumpTag(tag)` (03r-z) in `src/runtime.bp` and `rakun_runtime.erl`. The default
sink writes `kind requestId text` to standard error; an installed sink replaces it (one sink; a
second install is refused naming the first — no chain, no configuration).

**Acceptance:**
- [ ] `erlang_runtime_test.bp`: with no sink, `rkReportFailure("after", "r1", "boom")` writes one line to standard error and answers `0`; with a sink installed, the sink receives `("after", "r1", "boom")` once and standard error is untouched
- [ ] a second `rkInstallFailureSink` answers non-zero and the first sink stays installed
- [ ] `rkTagEpoch("t")` is `0` before any bump, `1` after `rkBumpTag("t")`, and `rkBumpTag` of another tag leaves it `1`
- [ ] the four functions are `pub` in `src/root.bp` and documented in `AGENTS.md` § The erlang host module

### Step 2 — Boot options and the cycle stack (R04-1, R04-2)

**Acceptance:**
- [ ] `erlang_runtime_test.bp`: a scratch project with `banner.txt` containing the three placeholders boots under the headless runner and the captured output starts with the substituted banner, once, before any log line
- [ ] `rakun.main.banner-mode=off` prints nothing; under `botopink test` nothing is printed whatever the setting
- [ ] `headless=true` + `keep-alive=true` does not halt within the test's budget; `keep-alive=false` halts with `0`
- [ ] a `fixtures/cycle` boot fails with a message listing the construction stack, innermost last (`A -> B -> C -> A`), asserted line by line

### Step 3 — Configuration (R05-1, R05-2, R14-1)

**Acceptance:**
- [ ] `typed_config_test.bp`: one bound record with a field of each of the eight types, each asserted from a property source; an unparsable value of each type is a boot refusal naming the key
- [ ] `config_check_test.bp`: the refusal's text names the key, the offending value and the file it came from, asserted against `fixtures/typed`
- [ ] `config_check_test.bp`: the check over a valid 50-field record runs in under 5 ms measured with `io.clock` over 100 iterations (the "no measurable cost" box, made measurable)
- [ ] RX-2: the decorator-argument default case (`#[configurationProperties("prefix")]` with an omitted argument) is re-measured; the README records "applied" or "still the language-gaps decorator-default row"

### Step 4 — Context (R06-1 … R06-7)

**Acceptance:**
- [ ] `context_test.bp`: `ctx.beanNames()` equals `rkScannedNames()` filtered to `#[managed]` types, order-insensitive, on `fixtures/tree`
- [ ] two unqualified `#[provides]` of one type refuse the boot naming both functions (`fixtures/phmissing` gains the case); the README says "at boot, until lg2-j"
- [ ] `#[postConstruct]` runs after construction and before `eagerInit` returns — a hook that records the eager pass's state
- [ ] `#[scope("request")]` on a constructor-injected factory is refused; at comptime if lg2-e allows the decorator to see the injection site, at boot otherwise, naming the site — the README says which
- [ ] with defaults every registered bean is constructed before `Rakun.run` returns, and a missing `#[value]` key fails inside `Rakun.run`, asserted by a component whose constructor records
- [ ] `scopes_test.bp` / `context_test.bp`: a clean stop exits `0`; a failed boot exits non-zero with a distinct code per failure kind (the table 19's `bootAndExit` consumes)
- [ ] `rakun.d.bp` leaves `botopink.json`'s `files` and the tree; `fixtures/imports` (a consumer naming `Context` in a signature) still compiles
- [ ] the scan registry records each component's injected field names; `rkScannedDeps(name) -> string[]` answers them (for 88's `beans`)

### Step 5 — Request context (R62-2, R62-3, R64-1)

**Acceptance:**
- [ ] `request_context_test.bp`: a deferred function that raises leaves the response as written and calls the failure sink exactly once with the request id
- [ ] the `Request` behavior gains `headerNames()`, `headers()`, `queryDict()`, `rawQuery()`; `request_context_test.bp` asserts all four from a request with two headers and `?x=1&y=%20`, `rawQuery()` answering the bytes as received
- [ ] `config_test.bp:548`'s `?? Doc(…)` is an `if (x == null)` narrowing (RX-1)

## Gate

- [ ] `zig build test` from a cold runtime cache, green, in `repository/botopink-lang` (nothing there changes)
- [ ] `botopink test --target erlang` in `modules/rakun` green; `zig build test-libs -- --target erlang --lib rakun` green with the `rakun · erlang` cell listed
- [ ] `botopink format --check` clean in `modules/rakun`
- [ ] `repository/rakun/AGENTS.md` and `modules/README.md` updated in the same commit
- [ ] commit on `fix/04-rakun-erlang-runtime`; landing is the maintainer's step

## Blast radius

Step 1 adds four `pub` functions and no behaviour change. Step 4's `#[value]` refusal at boot may
red a consumer that relied on the first-request failure — none in the repository (`grep -rn
'#\[value' examples starters` finds keys the examples define). Removing `rakun.d.bp` removes a
`Context` behavior stub; `fixtures/imports` is the consumer test. `rkScannedDeps` widens the scan
registry's ETS row; `rakun-test`'s `contextSnapshot()` reads names only and is unaffected.

## Notes

- 03r-b (`rkPropInt("12abc")` is `12`), 03r-c (no `rakun_config.erl`), 03r-d (the check in
  `bootSequenceFor`) and 03r-e (`decodeComponent`) are implemented; this front keeps them and asks
  the maintainer to confirm. A reversal of 03r-b is one function here and one in the typed readers.
- R64-1's filter half (the i18n redirect using `rawQuery()`) is 22's.
- `examples/context-lifecycle-example.bp` is copied here for its open `// LANGUAGE GAP:` (lg2-g).
