# Front 04 — rakun Erlang runtime: the core's open boxes

**Priority:** critical — 13 and 12 wait on step 1's tag epoch, 08 step 1 on step 4's eager-pass
hook, 22 on step 5's `Request` accessors, onze 49 on the page `Request` listing its query and
headers (R62-3), 88's `beans` on step 4's injected fields, 19 on step 4's exit codes ·
**State:** not started
**Depends on:** 128 · lg2-e (R06-4's comptime refusal), lg2-g (`@typeName<T>()` — the registry key
stays a string), lg2-j (comptime state — the `#[provides]` duplicate check runs at boot) · 03r-b/c/d/e
(confirmations)
**Owns:** `modules/rakun/**` except 74's four files (`src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`,
`test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`), 11's `src/actuator_api/**` and 17's
`src/logging/**` with their tests and sidecars · `test/fixtures/**` · `botopink.json`, `src/root.bp` ·
`repository/rakun/AGENTS.md` § the core sections
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen; 130's rewrite is
the one writer — track README § Order) · 74's, 11's, 17's files · any other member ·
`src/request_context.bp`'s cookie lookup while `03-bundled-libs/104`'s sweep holds it (after this
front) · `src/locals.bp` (`08-bpp/123` adds it after this front) · `modules/rakun/test/starter_manifest_test.bp` (73's)

## Goal

The core's open 1.0.10 boxes close: the tag epoch other members plug into (decision 185), the boot
options and cycle stack, typed configuration and its refusals, the context's bean list, duplicate
providers, lifecycle, scopes, eager construction and exit codes, `rakun.d.bp` gone, an eager-pass
exclusion hook, and a request context that logs `after()` failures through the core's logger and
exposes its headers and raw query to the page `Request`.

## Mechanism

- **The tag epoch (step 1).** The core is the only member every other depends on, so what two
  optional members share lives here (decision 185): `rakun_runtime.erl` keeps the ETS tables the
  reset hooks use (`rkOnReset` in `src/runtime.bp`) and gains a per-tag epoch. No failure seam:
  after 128 the logger is the core's (decision 187) and `after()` logs through it.
- **`#[provides]` duplicates (R06-2).** A comptime check across two decorator invocations needs
  lg2-j; the refusal is at boot in `bootSequenceFor` (`src/context.bp`), naming both functions — "fail
  the build" read as "fail before the first request"; the README records which.
- **Eager by default (R06-5).** `eagerInitIn` constructs every singleton not flagged `lazy`; a
  `#[value]` binding is read at construction, so a missing key already fails inside the pass — the
  open box is the assertion that `Rakun.run` does not return.
- **The eager-pass hook (for 08).** No `rkExcludeFromEager` exists anywhere. `eagerInitIn` skips a
  bean whose registration carries `lazy`; it gains a run-time exclusion list (`rkExcludeFromEager(name)`)
  so 08 can keep `#[repository]` beans out of the pass under `rakun.data.repositories.bootstrap-mode=lazy`.
- **Page `Request` (R62-3, R64-1).** `headerNames()`, `headers()`, `queryDict()` exist on the core's
  request (`src/request_context.bp`); the frame holds the raw header list and the raw query
  (`rakun_request_context.erl`). The `Request` behavior gains those three and `rawQuery()`;
  `rakun-app` (22) forwards them (onze-server hardcodes `[]` today).

## Done

- R04-3 — `zig build test-libs` green on erlang with the ledger lines gone (`00-gate/113`, decision 153)

## Open

### Step 1 — The tag epoch (lands first, alone; decision 185)

`rkTagEpoch(tag)` + `rkBumpTag(tag)` in `src/runtime.bp` and `rakun_runtime.erl`.

- [ ] `rkTagEpoch("t")` is `0` before any bump, `1` after `rkBumpTag("t")`, and `rkBumpTag` of another tag leaves it `1`
- [ ] both are `pub` in `src/root.bp` and documented in `AGENTS.md` § The erlang host module

### Step 2 — Boot options and the cycle stack (R04-1, R04-2)

- [ ] `erlang_runtime_test.bp`: a scratch project with `banner.txt` holding `${application.version}`, `${rakun.version}`, `${otp.version}` boots under the headless runner; the captured output starts with the substituted banner, once, before any log line
- [ ] `rakun.main.banner-mode=off` prints nothing; under `botopink test` nothing is printed whatever the setting
- [ ] `rakun.main.headless=true` + `keep-alive=true` does not halt within the test's budget; `keep-alive=false` halts with `0`
- [ ] a `fixtures/cycle` boot fails with a message listing the construction stack, innermost last (`A -> B -> C -> A`), asserted line by line

### Step 3 — Configuration (R05-1, R05-2, R14-1, RX-2)

- [ ] `typed_config_test.bp`: one bound record with a field of each of `bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration`, `DataSize`, each asserted from a property source; an unparsable value of each is a boot refusal naming the key
- [ ] `config_check_test.bp`: the refusal names the key, the offending value and the source file, asserted against `fixtures/typed`
- [ ] `config_check_test.bp`: the check over a valid 50-field record runs in under 5 ms, measured with `io.clock` over 100 iterations
- [ ] RX-2 (14, 72): the decorator-argument default (`#[configurationProperties("prefix")]` with an omitted argument) re-measured in `config_check_test.bp` / `autoconfig_test.bp`; the README records "applied" or "still the language-gaps decorator-default row"

### Step 4 — Context (R06-1 … R06-7)

- [ ] `context_test.bp`: `ctx.beanNames()` equals `rkScannedNames()` filtered to `#[managed]` types, order-insensitive, on `fixtures/tree`
- [ ] two unqualified `#[provides]` of one type refuse the boot naming both functions (`fixtures/phmissing` gains the case); the README says "at boot, until lg2-j"
- [ ] `#[postConstruct]` runs after construction and before `eagerInit` returns — a hook that records the eager pass's state
- [ ] `#[scope("request")]` on a constructor-injected factory is refused naming the injection site — at comptime if lg2-e lets the decorator see it, at boot otherwise; the README says which
- [ ] with defaults every registered bean is constructed before `Rakun.run` returns, and a missing `#[value]` key fails inside `Rakun.run`, asserted by a component whose constructor records
- [ ] `scopes_test.bp` / `context_test.bp`: a clean stop exits `0`; a failed boot exits non-zero with a distinct code per failure kind (the table 19's `bootAndExit` consumes)
- [ ] `rakun.d.bp` leaves `botopink.json`'s `files` and the tree; `fixtures/imports` (a consumer naming `Context` in a signature) still compiles, because the concrete type carries `resolve` / `has`
- [ ] the scan registry records each component's injected field names; `rkScannedDeps(name) -> string[]` answers them (88's `beans`)
- [ ] `rkExcludeFromEager(name)`: a name registered through it is skipped by `eagerInitIn` and constructed on its first `resolve` (`context_test.bp`); `pub` from `src/root.bp` (08 step 1 consumes it)

### Step 5 — Request context (R62-2, R62-3, R64-1's core half, RX-1)

- [ ] `request_context_test.bp`: a deferred function that raises leaves the response as written and is logged exactly once, at `error`, through the core's logger with the request id (decision 187 — no sink)
- [ ] the `Request` behavior gains `headerNames()`, `headers()`, `queryDict()`, `rawQuery()`; `request_context_test.bp` asserts all four from a request with two headers and `?x=1&y=%20`, `rawQuery()` answering the bytes as received
- [ ] `config_test.bp:569`'s `?? Doc(…)` is an `if (x == null)` narrowing (RX-1)

R62-1 (`setPhase(RequestPhase.Action)` visible to `requestPhase()` and to `rkCachePhase()`) is
asserted in 12's `revalidate_test.bp` and ticks here when 12 lands it. R64-1's filter half (the i18n
redirect reusing `rawQuery()`) is 22's.

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` green in `modules/rakun`;
`botopink format --check` clean there; `modules/README.md` updated.

## Blast radius

Step 1 adds two `pub` functions, no behaviour change. Step 4's `#[value]` refusal at boot may red a
consumer that relied on the first-request failure — none in the repository (`grep -rn '#\[value'
examples starters` finds keys the examples define). Removing `rakun.d.bp` removes a `Context` stub;
`fixtures/imports` is the consumer test. `rkScannedDeps` widens the scan registry's row;
`rakun-test`'s `contextSnapshot()` reads names only.

## Notes

- 03r-b (`rkPropInt("12abc")` is `12`), 03r-c (no `rakun_config.erl`), 03r-d (the check in
  `bootSequenceFor`), 03r-e (`decodeComponent`) are implemented and await confirmation; a reversal
  of 03r-b is one function here and one in the typed readers.
- `examples/context-lifecycle-example.bp` is kept for its open `// LANGUAGE GAP:` (lg2-g).
