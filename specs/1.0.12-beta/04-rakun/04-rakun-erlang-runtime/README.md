# Front 04 — rakun Erlang runtime: the core's open boxes

**Priority:** critical — waiting: 08 step 1 on step 4's eager-pass hook; 22 on step 5's `Request`
accessors; onze 49 on the page `Request` listing query and headers (R62-3); 88's `beans` on step 4's
injected fields; 19 on step 4's exit codes · **State:** partial (step 1)
**Depends on:** 128 · decisions 343, 347 (R06-2's and R06-4's refusals at compile time, where the
entry point builds the bean table) · decision 321 (qualified beans, step 6) · decision 318 (step 8) · 03r-c/e (confirmations);
lg2-g closed by 281 (no registry key as a type's name — step 6), 03r-b and 03r-d by 299 (step 7)
**Owns:** `modules/rakun/**` except 74's four files (`src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`,
`test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`), 11's `src/actuator_api/**` and 17's
`src/logging/**` with their tests and sidecars · `test/fixtures/**` · `botopink.json`, `src/root.bp` ·
`repository/rakun/AGENTS.md` § the core sections
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen; 130's rewrite the
one writer — track README § Order) · 74's, 11's, 17's files · any other member ·
`src/request_context.bp`'s cookie lookup while `03-bundled-libs/104`'s sweep holds it (after this
front) · `src/locals.bp` (`08-bpp/123` adds it after) · `modules/rakun/test/starter_manifest_test.bp` (73's)

## Goal

The core's open 1.0.10 boxes: the tag epoch (decision 185), boot options and cycle stack, typed
configuration and refusals, the context's bean list, duplicate providers, lifecycle, scopes, eager
construction and exit codes, `rakun.d.bp` gone, an eager-pass exclusion hook, a request context
logging `after()` failures through the core's logger and exposing headers and raw query to the page `Request`.

## Mechanism

- **Tag epoch (step 1, done).** The core is the one member all depend on, so what two optional
  members share lives here (decision 185): `rkTagEpoch(tag) -> i64` / `rkBumpTag(tag) -> i64` in
  `src/runtime.bp`, a `rakun_tag_epochs` ETS table in `rakun_runtime.erl` bumped with
  `ets:update_counter/4` (atomic across request processes). An epoch only grows: `rkResetContext`
  leaves it, so an epoch a reader stored never matches a later state (`04-a`). The empty tag is
  refused in both cells. No failure seam: after 128 the logger is the core's (decision 187);
  `after()` logs through it.
- **`#[provides]` duplicates (R06-2).** Each decorator invocation is independent (343): the
  duplicate is refused at compile time where the entry point builds the bean table with
  `@TypeInfo.all(with: provides)` (256), naming both functions — "fail the build" as written.
- **Eager by default (R06-5).** `eagerInitIn` constructs every non-`lazy` singleton; `#[value]` read
  at construction today (the `#[config]` record of step 7 replaces it, 299), so a missing key already
  fails in the pass — the open box asserts `Rakun.run` does not return.
- **Eager-pass hook (for 08).** No `rkExcludeFromEager` exists. `eagerInitIn` skips `lazy`
  registrations; gains a run-time exclusion list (`rkExcludeFromEager`, taking the type — step 6,
  281) so 08 keeps `#[repository]` beans out under `bootstrapMode: Lazy` (08's
  `#[config("rakun.data")]` record, 299).
- **Page `Request` (R62-3, R64-1).** `headerNames()`, `headers()`, `queryDict()` exist on the core's
  request (`src/request_context.bp`); the frame holds raw headers and raw query
  (`rakun_request_context.erl`). The `Request` behavior gains those three and `rawQuery()`;
  `rakun-app` (22) forwards them (onze-server hardcodes `[]` today).

## Done

- R04-3 — `zig build test-libs` green on erlang with the ledger lines gone (`00-gate/113`, decision 153)
- Step 1 — the tag epoch (decision 185): `rkTagEpoch(tag)` is `0` before any bump, `1` after
  `rkBumpTag(tag)`, and a bump of another tag leaves it `1`; the empty tag refused in both cells,
  located; both `pub` through `src/root.bp`'s `pub mod runtime`, documented in `AGENTS.md` § The
  erlang host module (`test/erlang_runtime_test.bp`; `botopink test --target erlang` in the 16 members: 1 819 → 1 822 passed, 0 failed, the core 439 → 442)

## Open

### Step 2 — Boot options and the cycle stack (R04-1, R04-2)

- [ ] `erlang_runtime_test.bp`: scratch project, `banner.txt` with `${application.version}`, `${rakun.version}`, `${otp.version}`, booted headless; captured output starts with the substituted banner, once, before any log line
- [ ] `rakun.main`'s `bannerMode` off prints nothing (299: the key is the field's name; `banner-mode` today); under `botopink test` nothing printed whatever the setting
- [ ] `rakun.main`'s `headless: true` + `keepAlive: true` does not halt within the test's budget; `keepAlive: false` halts with `0` (299; `keep-alive` today)
- [ ] a `fixtures/cycle` boot fails listing the construction stack, innermost last (`A -> B -> C -> A`), asserted line by line

### Step 3 — Configuration (R05-1, R05-2, R14-1, RX-2)

- [ ] `typed_config_test.bp`: one bound record with a field of each of `bool`, `i32`, `i64`, `f64`, `string`, `string[]`, `Duration`, `DataSize`, each from a property source; an unparsable value of each refuses the boot naming the key
- [ ] `config_check_test.bp`: the refusal names key, offending value and source file, against `fixtures/typed`
- [ ] `config_check_test.bp`: the check over a valid 50-field record under 5 ms, `io.clock` over 100 iterations
- [ ] RX-2 (14, 72): the decorator-argument default (`#[configurationProperties("prefix")]` today, `#[config]` after step 7 — 299, argument omitted) re-measured in `config_check_test.bp` / `autoconfig_test.bp`; README records "applied" or "still the language-gaps decorator-default row"

### Step 4 — Context (R06-1 … R06-7)

- [ ] `context_test.bp`: `ctx.beanNames()` equals `rkScannedNames()` filtered to `#[component]` types (318), order-insensitive, on `fixtures/tree`
- [ ] two unqualified `#[provides]` of one type fail the build at the entry point's bean table, naming both functions (343; `fixtures/phmissing` gains the case)
- [ ] `#[postConstruct]` runs after construction, before `eagerInit` returns — a hook recording the eager pass's state
- [ ] `#[scope("request")]` on a constructor-injected factory refused at compile time naming the injection site — where the entry point builds the bean table, which sees both declarations (343, 347: a method's `@Decl` has no `owner`)
- [ ] with defaults every registered bean constructed before `Rakun.run` returns; a missing required config key (`#[value]` today, a `#[config]` field after step 7 — 299) fails inside `Rakun.run` (a recording constructor)
- [ ] `scopes_test.bp` / `context_test.bp`: clean stop exits `0`; failed boot exits non-zero, a distinct code per failure kind (the table 19's `bootAndExit` consumes)
- [ ] `rakun.d.bp` leaves `botopink.json`'s `files` and the tree; `fixtures/imports` (a consumer naming `Context` in a signature) still compiles — the concrete type carries `resolve` / `has`
- [ ] the scan registry records each component's injected field names; `rkScannedDeps(name) -> string[]` answers them (88's `beans`)
- [ ] `rkExcludeFromEager(T)` (by type, step 6 — 281): a registered type skipped by `eagerInitIn`, constructed on first resolution (`context_test.bp`); `pub` from `src/root.bp` (08 step 1 consumes it)

### Step 5 — Request context (R62-2, R62-3, R64-1's core half, RX-1)

- [ ] `request_context_test.bp`: a raising deferred function leaves the response as written, logged exactly once at `error` through the core's logger with the request id (decision 187 — no sink)
- [ ] `Request` behavior gains `headerNames()`, `headers()`, `queryDict()`, `rawQuery()`; `request_context_test.bp` asserts all four from a request with two headers and `?x=1&y=%20`, `rawQuery()` the bytes as received
- [ ] `config_test.bp:569`'s `?? Doc(…)` is an `if (x == null)` narrowing (RX-1)

R62-1 (`setPhase(RequestPhase.Action)` visible to `requestPhase()` and `rkCachePhase()`) asserted in
12's `revalidate_test.bp`, ticks here when 12 lands it. R64-1's filter half (i18n redirect reusing
`rawQuery()`) is 22's.

### Step 6 — references, not strings (decision 281)

A bean, an event or a condition is named by its type or its function, never its text
(`examples/context-lifecycle-example.bp`).

- [ ] `ctx.resolve("OrderCache")` → resolution by type (`use bean(OrderCache)`, the shape of a
      context read by type, `use context(T)` — 354, 379); `resolveNamed("Clock", "fixed")` → `resolveNamed(Clock, "fixed")` (321: the type as a type,
      the label a `comptime` string checked against the registry at build; `resolveNamed(Clock)` the `#[primary]`);
      `#[qualifier("…")]` also on a constructor field; an unknown label, a duplicate label or two `#[primary]` a build error
- [ ] `#[eventListener("OrderPlaced")]` → `#[on] fn f(e: OrderPlaced)`, the event the parameter's type
      (280 example 2); the string form refused
- [ ] `#[conditionalOnMissingBean(MailSender)]` takes a `type` (280 example 3); `rkExcludeFromEager`
      takes the type
- [ ] `examples/context-lifecycle-example.bp` rewritten to decision 281 (`ctx.resolve("…")` /
      `resolveNamed` / `#[eventListener("…")]` / `has("…")` by type; its `// LANGUAGE GAP:` on
      `@typeName<T>()` goes with lg2-g, closed by 281); the qualifier half follows 321

### Step 7 — configuration as a typed record (decision 299)

- [ ] `#[config("rakun.data")] pub type DataConfig(poolSize: i32 = 10, bootstrapMode: BootstrapMode =
      .Eager)`: bound at boot from the config file (and `#[env("…")]` fields from the environment),
      injected by type (`use config(DataConfig)` in a body under the request's `RequestContext` (354), or as a bean); `#[configurationProperties]`
      folds into it
- [ ] a field's key is its exact name (`poolSize`, `Lazy` — no case conversion, 280 (4)); `#[key("pool-size")]`
      names an existing file's spelling; a wrong type, an unknown variant, an unknown key or a malformed
      number (`"12abc"`) stops the boot naming the file, line and expected type (03r-b's lenient parse goes)
- [ ] `#[value("…")]` and `rkProp*` leave the rakun members; `rakun.profiles.active` is a field of a
      `#[config("rakun")]` record (`profiles: string[]`)

### Step 8 — one decorator per role (decision 318; the core's `decorators.bp` through 130 step 5)

- [ ] `#[component(lazy: …, scope: …)]` the one type stereotype; `#[service]`, `#[managed]` and the core's
      `#[repository]` on a `type` deleted, their sites `#[component]` (the scan and `T.make()` unchanged)
- [ ] `#[provides]` on a free function the one way to provide a bean, reading 299's typed config;
      `#[configuration]`, `#[bean]` and their `rkRegisterBean` emission deleted; `examples/rakun/src/config.bp`
      and `test/{autoconfig,conditions,scopes,context}_test.bp` rewritten
- [ ] one `#[controller]`: the answer by the method's return type — `View` HTML, a record JSON, `Response`
      as is; `#[restController]` deleted, its sites `#[controller]`
- [ ] no Spring name left in the core's public surface (`grep` over `src/` for the deleted names is empty)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` green in `modules/rakun`;
`botopink format --check` clean there; `modules/README.md` updated.

## Blast radius

Step 1 (done): two `pub` functions, no behaviour change. Step 4's boot-time `#[value]` refusal may red a
consumer relying on first-request failure — none in the repository (`grep -rn '#\[value' examples
starters` finds keys the examples define). Removing `rakun.d.bp` removes a `Context` stub;
`fixtures/imports` is the consumer test. `rkScannedDeps` widens the scan registry's row;
`rakun-test`'s `contextSnapshot()` reads names only.

## Notes

- 03r-c (no `rakun_config.erl`), 03r-e (`decodeComponent`) implemented, await confirmation.
  03r-b (`rkPropInt("12abc")` is `12`) reversed by 299 and 03r-d (check in `bootSequenceFor`) closed
  by 299 — both are step 7's.
- `examples/context-lifecycle-example.bp`: its `// LANGUAGE GAP:` (lg2-g) is closed by 281; rewritten
  by step 6's last box.
