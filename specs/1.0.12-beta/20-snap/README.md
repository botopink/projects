# Front 135 — snap: the second test layer, re-evaluated case by case

**Priority:** low — last · **State:** evaluated; no step started
**Depends on:** `snap-a` ([`decisions-pending.md`](../decisions-pending.md)) · step 4: `06-emilia/34` landed (it moves the output the helpers record)
**Owns:** the snapshot steps other fronts carried — `02-std-and-packaging/97` step 7 ·
`04-rakun/19` step 6 · `05-jhonstart/26` step 7 · `06-emilia/33` steps 1, 3, 4 (helper and
suite parts) · `07-onze/50` step 8 · `51` step 7 · `71` step 6 · the helpers named below in
`emilia-test`, `rakun-test`, onze's harness
**Does not touch:** any existing test or `.snap` — evidence; changes only with its test

## Goal

The nine snapshot maps from 1.0.10 specified a second layer (`assert<Subject>(loc, …)` helpers,
one `.snap` per box, ~2 500 files). Every case re-checked against `feat` and the decisions. When
this lands, each library verifies those values once: existing tests, the few helpers a contract
needs, plain tests for the 21 values nothing verifies.

The maps are history, in `../../1.0.11-beta/`: `02-std-and-packaging/97-std-dedupe/test-snap.md`,
`04-rakun/19-rakun-test-utilities/test-snap-helpers.md`, `05-jhonstart/26-jhonstart-router/test-snap.md`,
`06-emilia/33-emilia-color-palette/test-snap{,-examples}.md`,
`07-onze/{50-onze-cli,51-onze-image,71-onze-release-packaging}/test-snap.md`,
`07-onze/53-onze-example-app/test-snap-examples.md`. Their literals predate the code; not expected values (finding 4).

## Done

- Step 5, box 2 — `03-bundled-libs/107-release`'s README names `text_…` and `dockerfile_…`, the two snapshots it must reproduce (§ 8, KEEP — on disk)

## Open

### Step 1 — std (on `snap-a`)
- [ ] `mocks.verify`'s message pinned with `throwsWith` on both targets (§ 1, CONVERT)
- [ ] `libs/std/AGENTS.md`: the inline literals and the four `__snapshots__/` path-rule files are the evidence

### Step 2 — rakun-test (on `snap-a`)
- [ ] `assertResponse(loc, res)` over `MockMvc.perform`, one `.snap` (§ 2, KEEP — contract 7, 98 check (2))
- [ ] `rakun-test/AGENTS.md` states the member ships that helper only

### Step 3 — jhonstart (on `snap-a`)
- [ ] `AGENTS.md` paragraph: 204 inline asserts and the 39 existing `.snap` are the evidence; the
      helpers that exist stay (§ 3)

### Step 4 — emilia-test (on `snap-a`)
- [ ] `assertClassName` under `defaultTheme()` (records `e_39b87d03`) and `assertCss(loc, tokens, th)`
      over a `pub` CSS surface (`tokensToSheet` is private today), two `.snap` (§ 4, KEEP)
- [ ] `emilia-card`'s repeat collapse as an inline test (§ 5, CONVERT — goes with 33 step 2)
- [ ] `repository/emilia/AGENTS.md` § Tests: the inline literals, the three readers of the
      contract-4 literal and the two helper `.snap` are the evidence; the 1.0.10 suites and eight
      examples are retired (33 steps 3–4)

### Step 5 — onze (on `snap-a`)
- [ ] onze-release: the release tree as a path table in `package_test.bp` (§ 8, CONVERT)
- [ ] onze 53's runner: written by `07-onze/53` step 1 in the plain form § 9 gives (no snapshot writers)
- [ ] `repository/onze/AGENTS.md`: the inline literals and the existing `__snapshots__/` (onze-cli
      5, onze-assets 10, onze-og 4, onze-release 5) are the evidence of §§ 50 · 51 · 52 · 70 · 71
      (50 step 8, 51 step 7)

**Gate:** standard (fronts.md § Gate) · no `.snap` recorded that this README does not name

## The evaluation

Verdicts, in check order: **OBSOLETE** — case no longer applies (renamed/removed, a decision
changed the output, subject deferred; decision or code fact named) · **RETIRE** — verified today
(inline assert or existing `.snap` named) · **KEEP** — verified nowhere, or a contract needs the
helper/`.snap` (contract named) · **CONVERT** — a plain test is enough (form and sketch given).

**Rewrite as** (coordinator's scale): (1) inline assert, (2) property/round-trip, (3)
table-driven, (4) test over an existing helper or double, (5) snapshot, only when nothing cheaper
fits. RETIRE cites the existing test, no sketch. KEEP/CONVERT say whether the value is **re-derived**.

### Five findings that hold across files

1. **Wrong slug separator** in rakun and emilia maps (`-`: `route-…`, `color-red-500-text.snap`);
   std's engine uses `_` (`snapshots.slugOf`; e.g. `path_named_second_snapshot.snap`). Onze
   50/51/71 maps too; realised onze `.snap` already use `_`.
2. **Onze maps' "Measured" text was stale** ("inline literals, no `.snap`" for §§ 50 · 51 · 52 ·
   70 · 71): 24 of onze's 51 `.snap` realise them via `snapshots.assertAs` directly (onze-cli 5, onze-assets 10,
   onze-og 4, onze-release 5); 71 step 6 (c) almost met.
3. **98 check (2) conflicts with retiring rakun's helpers** — resolved by R-K (§ 2).
4. **Recorded values contradict landed code:** HAL `_links` first vs last at `hal_test.bp:55`
   (R2); `normalize` `..` (S8); `assertClassName` "under `fullTheme()`" though `emilia()` uses
   `defaultTheme()` and `e_39b87d03` is `className(cardTokens(), defaultTheme())` (§ 4); onze 53's
   `#fff` vs emilia's `var(--color-…)` (§ 9). Maps predate code; literals are not expected values.
5. **Miscounts:** rakun's question said 57 helpers, `test-snap-helpers.md` lists 60; jhonstart's
   said `helpers_test.bp` holds 21 tests, it holds 20 (7 `.snap`). Correct: std ~40 files (4
   existing), jhonstart 32 example snapshots, emilia 610 inline tests in `emilia.bp`.

## 1 · `02-std-and-packaging/97-std-dedupe/test-snap.md` (14.1 KB) — `snap-a`, 97 step 7

No std `-test` member; map calls `snapshots.assertText` directly. 40 `.snap` + 7 engine tests
(plain asserts). 97 step 7: (b) writes ~40 files; (a) one `AGENTS.md` line.

| Group | Specifies | In code today | Verdict | Rewrite as |
|---|---|---|---|---|
| S1 `testing/asserts.bp` messages | 27 `.snap` `asserts: message ---- <fn>`, body `asserts.<fn>: <what>` | each pinned with `try equals(errorText(r), "…")` in the fail-path inline test (`asserts.bp:335, 346, 360 … 642`); all 27, incl. both `throwsWith` texts and `approxEquals` | **RETIRE** — exact literal, both targets | (1) already, foot of `asserts.bp` |
| S2 `testing/snapshots.bp` path rule | 4 `.snap`: suite and slug, named second snapshot, slug punctuation, name without suite | **realised**: 4 files under `libs/std/src/testing/__snapshots__/snapshots/`, plus inline `snapshots: path ---- the pure half` (line 436) | **KEEP** (no work) — only place a committed `.snap` proves the engine's read path against the package tree on both targets; tmpdir engine tests cannot | (5) existing; correct, no re-derivation |
| S3 engine outcomes | 7 plain-assert tests (missing, mismatch, match removes stale `.new`, header, CRLF, not a snapshot file, full test name) | `snapshots.bp:452-645`: 11 `engine ----` tests, all 7 plus body-line counting, trailing newlines, named snapshot, module-level refusal | **RETIRE** | (1) already |
| S4 `testing/mocks.bp` verify message | 1 `.snap` via `mockCounter()` / `verifyMessage`, body `mocks.verify: tick - expected exactly 1 matching call(s), got 2` | **no test** pins it. Node template (`mocks.bp:73`) appends ` [recorded: …]` / ` [no calls recorded]`, Erlang (line 74) does not — diverge today. Fixture API stale: code has `UserRepo.mock()`, not `mockCounter()` | **CONVERT** — only std text pinned that no test reads. **Re-derive**: fixture names change; value holds as prefix on both targets | (1) one inline test in `mocks.bp`, replaces 1 snapshot — sketch S4 |
| S5 `escape.bp` | 2 (`html` ampersand; `jsString` script close) | `escape.bp:104` (`html("<a href=\"x\">&") == "&lt;a href=\"x\"&gt;&amp;"`, map's exact input), `:129-133` (`jsString("</script>") == "\\u003c/script>"`) | **RETIRE** | (1) already |
| S6 `hash.bp` content hashes and digest | 4 (`etag("hello")`, `cacheKey` framing, `fingerprint("app.js",…)`, `sha256Base64Url("")`) | `contentHash("hello") == "f923099"` (`:377`) + `etag` quoting (`:432-438`); `cacheKey` `62d9003d` / `8aac687d` (`:405-411`, exact); `fingerprint` "extension stays last" (`:462-477`, other contents); `sha256Base64Url("")` (`:179`, exact) | **RETIRE** — decision 260 changes `contentHash` only above U+FFFF; none move | (1) already |
| S7 `encoding.bp` | 1 (`percentEncode("a b&c=d")`) | `encoding.bp:175`, exact | **RETIRE** | (1) already |
| S8 `path.bp` | 1 (`normalize("/app/./blog/../page.bp") == "/app/page.bp"`) | `normalize` drops `.` only; `path.bp:90-94`: "Full `..` pop semantics are deferred" — value false today | **OBSOLETE** — deferred by the code's note; test belongs to the front implementing `..` popping | — |

Sketch S4 (`libs/std/src/testing/mocks.bp`, beside `verify atLeastOnce / times / never`; needs
`import {testing.asserts}`, or the private `tryCatch` shape of `asserts.bp`):

```bp
test "mocks: verify message ---- expected exactly one call" {
    val repo = UserRepo.mock();
    val _1 = repo.find(7);
    val _2 = repo.find(7);
    try asserts.throwsWith({ -> val _v = verify(repo, times(1)).find(eq(7)); 0; },
        "mocks.verify: find - expected exactly 1 matching call(s), got 2");
}
```

`throwsWith` is a contains-check, so it passes on both targets while Node keeps its suffix.
Byte-identical templates are a separate choice (one-line Node change; test becomes `equals` over
a caught message).

## 2 · `04-rakun/19-rakun-test-utilities/test-snap-helpers.md` (12.7 KB) — `snap-a`, 19 step 6

Map: 60 `assert<Subject>(loc, …)` helpers in `rakun-test`, each with a rendering rule, ~1 900
`.snap`; case lists stayed in the closed 1.0.10 record. `rakun-test/src` today: `assertions.bp`
(`expect*` booleans), `context.bp`, `fake_request.bp`, `mockmvc.bp`, `root.bp`. 0 `.snap` under
`repository/rakun`; member suites ~1 850 inline tests. 19 step 6 (RX-5): (a) delete
`test-snap-helpers.md` + `AGENTS.md` line; (b)/(c) write the helpers. Groups follow post-187 homes
(decision 187: 25 members into 16).

| Group (post-187 home) | Helpers (n) | Covered by (inline literals) | Verdict — Note |
|---|---|---|---|---|
| R1 `rakun` core | `assertContext`, `assertConfig`, `assertLifecycle`, `assertAutoConfig`, `assertRequestContext`, `assertSslBundle`, `assertBoot` (7) | `rakun/test/`, 374 tests: `di_test`, `scopes_test`, `config_test`, `typed_config_test`, `events_test`, `autoconfig_test`, `conditions_test`, `request_context_test`, `request_memo_test`, `ssl_bundle_test`, `server_test`, `erlang_runtime_test`; `contextSnapshot()` in `rakun-test` | **RETIRE** — `assertBoot`'s exit codes: 19 step 4's `bootAndExit`, planned with plain asserts |
| R2 `rakun-web` (+ `rakun-hateoas`, 187) | `assertRoute`, `assertMiddleware`, `assertProblem`, `assertCors`, `assertUrlRules`, `assertStatic`, `assertHal` (7) | `rakun-web/test/`, 209 tests (`middleware_test`, `error_test` 40 asserts, `cors_test` 53, `rules_test`, `static_test`, `dispatch_seam_test`); route-table wire format (contract 1) in `libs/routing/test/table_test.bp:47-61`; `hal_test.bp` exact JSON | `assertHal` **OBSOLETE**: map renders `_links` first, code pins it last (`hal_test.bp:55-58`). `assertRoute` **KEEP, reduced** (R-K). Other 5 **RETIRE**. `assertProblem`'s digest moves to `log.errorDigest` (decision 194), so its body would change anyway |
| R3 `rakun-websocket` | `assertWebSocket` (1) | `upgrade_test`, `limits_test`, `broadcast_test` (27 tests) | **RETIRE** |
| R4 `rakun-app` | `assertRouteTree`, `assertSsr`, `assertPageDispatch`, `assertAction`, `assertHandler`, `assertStaticGen`, `assertSlots`, `assertNavigation`, `assertLocale`, `assertMetadataRoutes` (10) | `rakun-app/test/`, 208 tests (`file_router_test`, `file_router_scan_test`, `ssr_test`, `actions_test`, `route_handler_test`, `route_slots_test`, `route_intercept_test`, `navigation_test`, `i18n_test`, `metadata_routes_test`, `static_gen_test`) | `assertStaticGen` **OBSOLETE**: "`static\|dynamic because <reason>`" is a run-time mark; decisions 186/202 make the stage a compile-time fact of `#[page]` (jhonstart 26 step 8; rakun 22 step 4 deletes the bridge). Other 9 **RETIRE** |
| R5 `rakun-data` (+ `rakun-tx`, `rakun-devtools`, 187) | `assertQuery`, `assertMigration`, `assertEntity`, `assertStore`, `assertOutbox`, `assertSaga`, `assertReload` (7) | `rakun-data/test/`, 128 tests (`sql_query_test`, `sql_template_test`, `migration_test`, `orm_test`), `rakun-tx` (`outbox_test`, `saga_test`: 32), `rakun-devtools` (21) | **RETIRE** — module names change under 187; subjects stay |
| R6 `rakun-security`, `rakun-session` | `assertSecurity`, `assertOAuth`, `assertSession` (3) | 108 + 35 tests (`policy_test`, `oauth2_test`, `session_test`, `cookie_test`, `rotation_test`) | **RETIRE** |
| R7 `validation` (bundled, decision 116) | `assertValidation` (1) | `botopink-lang/libs/validation/test/` (`schema_test`, `constraints_test`, `messages_test`, …) | **RETIRE** — decision 144 (undeclared key refused) asserted there |
| R8 `rakun-cache`, `rakun-client` (+ `rakun-ws` SOAP, 187) | `assertCache`, `assertClient`, `assertSoap` (3) | 69 + 70 + 13 tests (`key_test`, `revalidate_test`, `exchange_test`, `request_test`, `rakun-ws/envelope_test`) | **RETIRE** |
| R9 actuator (+ `rakun-actuator-api` into the core, 187) | `assertRegistry`, `assertHealth`, `assertEndpoint`, `assertExposure`, `assertProbe`, `assertAudit`, `assertExchanges` (7) | 103 + 10 tests (`health_test`, `endpoint_test`, `exposure_test`, `probes_test`, `recording_test`, `registration_test`) | **RETIRE** |
| R10 `rakun-metrics`, logging (into the core, 187) | `assertMetrics`, `assertTrace`, `assertLog` (3) | Prometheus text byte for byte (`endpoints_test.bp:24-30`, `registry_test.bp:33,56`), `tracing_test`, `rakun-logging` 54 tests (`format_test`, `correlation_test`) | **RETIRE** — rakun-logging's `errorDigest` deleted for `log`'s (decision 194) |
| R11 `rakun-messaging` (+ `rakun-rsocket`, `rakun-stream`, 187), pulsar | `assertListener`, `assertRetry`, `assertPulsar`, `assertStream`, `assertRSocket` (5) | 91 + 16 + 24 tests | `assertPulsar` **OBSOLETE**: front 91's data plane deferred (`03r-ad`, `status.md:95`), no module. Other 4 **RETIRE** |
| R12 `rakun-scheduling` | `assertSchedule`, `assertJobStore` (2) | 100 tests (`cron_test`, `store_test`, `cluster_test`) | **RETIRE** |
| R13 `rakun-mail` | `assertMail` (1) | `compose_test` checks the MIME lines (`:38,45,115`) | **RETIRE** |
| R14 `rakun-cli` (+ `rakun-release`, 187) | `assertRelease`, `assertCli` (2) | `release_test.bp` (12 tests: `.rel`, `vm.args`, `sys.config` byte stability, Dockerfile, SBOM), `scaffold_test`, `inspect_test` | **RETIRE** — byte identity with onze is `03-bundled-libs/107` step 1's equality test, not a snapshot |
| R15 starters | `assertStarter` (1) | `rakun/test/starter_manifest_test.bp` | **RETIRE** |

**R-K — the one rakun helper a contract needs.** 98 check (2)
(`02-std-and-packaging/98-packaging-tail` § Mechanism: every `modules/*-test/src` holds ≥ 1
`pub fn assert[A-Z]…(loc: SourceLocation` handing `loc` to `snapshots.`), contract 7
(`contracts.md:486-510`) and `snapshots.md` rule 3 ("every library … exposes, from `<lib>-test`,
the `assert<Subject>` helpers") all fail under "the member ships no snapshot helpers" (each needs an `assert<Subject>` writing through `snapshots`);
`02-std-and-packaging/98-packaging-tail/test-helpers.md`'s table (`:66`) names rakun's subjects `route` and `response`. Proposal: the response half of
`assertRoute` as `assertResponse` over `MockMvc.perform`'s `Response(status, body)` — form (4),
over `mockmvc.bp`; +1 helper, +1 accepted `.snap` in a `helpers_test.bp`, no member box
re-recorded, value derived fresh.

```bp
// modules/rakun-test/src/assertions.bp
pub fn assertResponse(loc: SourceLocation, res: Response) -> @Result<void, string> {
    try snapshots.assertAs(loc, "response", "status " + res.status.toString() + "\n\n" + res.body);
    return;
}
// test/assertions_test.bp: try assertResponse(@src(), MockMvc.standalone().perform(fakeGet("/missing")));
```

Alternative: amend 98 check (2) to "a `-test` member that exposes a snapshot helper hands `loc` to
`snapshots.`", and contract 7 / rule 3 to match — free in rakun, weakens a shared rule.
Recommended: the helper.

## 3 · `05-jhonstart/26-jhonstart-router/test-snap.md` (61.6 KB) — `snap-a`, 26 step 7

Map: § 0.2 helpers (11 helper files, exist) and 92 cases, one `.snap` each (76 code blocks + 17
table rows in render and bridge), under `modules/*/test/__snapshots__/`. Exists: ~204 inline tests
in member suites; `jhonstart-test` helpers with 20 tests and 7 `.snap` in `helpers_test.bp`; 32
`.snap` across 5 examples (blog-ssr 10, document-shell 4, forms 7, islands 5, nav-shell 6) through
14 helpers. 26 step 7: (b) re-record everything, alone, last; (a) one `AGENTS.md` paragraph.

| Group | Cases | Covered by | Verdict | Rewrite as |
|---|---|---|---|---|
| J0 § 0.2 helpers (`assertHtml`, `assertRoute`, `assertStream`, `assertDocument`, `assertResponse`, … plus `harness.bp`) | — | `modules/jhonstart-test/src/*.bp` (46 `pub fn`), `helpers_test.bp` | **KEEP** (exists): contract 7, 98 check (2); the 32 example `.snap` consume them | no work. `assertDocument`, `assertResponse`, `assertPayload`, `assertRequest`, `assertLink` have no example consumer; cheap, stay |
| J1 § 94 element surface (`elements:` ×8) | 8 | inline in `jhonstart/src/elements.bp:366-527` (15 tests: `el`, `voidEl`, `isVoidTag`, `isRawTextTag`, renamed constructors, attribute order, verbatim value, document shell, the frozen `</input>`) | **RETIRE** | (1) already. Map's `modules/jhonstart/test/elements_test.bp` does not exist; tests are inline |
| J2 § 94 DSL resolution (`html-dsl:` ×3) | 3 | `modules/jhonstart-html/test/elements_test.bp` (3 tests, same rows) | **OBSOLETE (location)**: decision 200 deletes `jhonstart-html`; the 3 tests move into the core at 26 step 0, subject stays covered | — |
| J3 § 26 router | 7 | `router_test.bp` (29): snapshot codec, first match, segments, out-of-range segment, hooks; active nav in `helpers_test` `activeLinkText` and the nav-shell example | **RETIRE** | (1) already |
| J4 § 27 link and reconcile | 10 | `link_test.bp` (28), `reconcile_test.bp` (10); `helpers_test` `simulateNavigation` and the `reconcile/` `.snap` | **RETIRE** | (1), with (5) existing |
| J5 § 28 server components | 5 | `server_test.bp` (19); `helpers_test` request and its `request/` `.snap` | **RETIRE** | |
| J6 § 29 client directive | 5 of 6 | `client_test.bp` (29); `island/` helper `.snap`; islands example | **RETIRE** | |
| J6b `island: server-only is a value nobody reads` | 1 | `client.bp:292` `serverOnly() -> i32` still exists | **OBSOLETE**: decisions 186/202 replace the value with `#[serverOnly]` / `#[clientOnly]` (26 step 8) | — |
| J7 § 30 streaming | 6 | `streaming_test.bp` (33): shell, fills, completion order, loading convention, hole ids; declaration-order harness case is `helpers_test` `renderToStream` and its `stream/` `.snap` | **RETIRE** | |
| J8 § 30 render (5 blocks plus 13 rows) | 18 | `render_test.bp` (22): escaping, void, raw text, `#raw`, payload; `streaming_test` `compose:`, `signal:`, `plugin:` for nesting, redirect, depths, plugin order, owned keys | **RETIRE**. Contract 2's payload keys pinned here, read by onze | |
| J9 § 30 bridge (1 block plus 4 rows) | 5 | `jhonstart-emilia/test/bridge_test.bp` (10), incl. contract-4 literal `e_39b87d03` (`:165-186`); deleted with the member by `08-bpp/119` (decision 338), the literal's reader moving to `jhonstart-styled`'s test | **RETIRE** — contract has three readers: emilia, `jhonstart-styled`'s test (the bridge's until 119), onze's `build_test.bp:99` | |
| J10 § 31 error boundaries | 6 of 7 | `error_boundary_test.bp` (19); `boundary/` helper `.snap` | **RETIRE** | |
| J10b `boundary: the reader's digest is the server's digest` | 1 | `digestOf(message)` (`error_boundary.bp:77`) | **OBSOLETE**: decision 194 deletes `digestOf` for `log.errorDigest(module, errorClass, message, topFrames)`; agreement by construction ("one call both logs and answers it"); 26 step 4 tests it | — |
| J11 § 32 metadata | 9 | `metadata_test.bp` (16), one for one incl. both viewport cases and escaping | **RETIRE** | |
| J12 § 67 forms | 8 | `jhonstart-forms/test/form_test.bp` (15); `form/` helper `.snap`; forms example (7 `.snap`) | **RETIRE** | |

## 4 · `06-emilia/33-emilia-color-palette/test-snap.md` (95.3 KB) — `snap-a`, 33 steps 1 and 3

Map: 8 helpers in `emilia-test/src/asserts.bp`, 185 shown cases over 21 per-front suites; 1.0.10
text implies ~600 files ("one `css:` per leaf in the real file"). Exists: `emilia-test/src/root.bp`
one resolve test, no helper; `emilia.bp` 610 inline tests, member 734 with `output.bp` (47),
`theme.bp` (37), `preflight.bp` (14), `arbitrary.bp` (9), `container.bp` (6), `spacing.bp` (6),
`attributes.bp` (3), `compose.bp` (2); fifteen per-front examples assert inline; no `.snap`; no
repository imports `emilia-test`. Steps: 33 step 1 writes `assertCss`, `assertCssWith`,
`assertClassName` unconditionally; step 3 the 21 suites (conditional); 34 step 2 moves five
families' literals.

### Helpers

| Helper | Verdict | Reason / re-derivation |
|---|---|---|
| `assertClassName` | **KEEP** | 98 check (2), contract 7 need ≥ 1 helper in `emilia-test`; records the one value a consumer reads, the contract-4 class. **Re-derive the spec:** `className(tokens, defaultTheme())`, not "`emilia(tokens)` under `fullTheme()`" — `e_39b87d03` is the `defaultTheme()` value (`emilia.bp:16503-16516`: `className(cardTokens(), defaultTheme())`) |
| `assertCss` | **KEEP** | the one CSS helper a consumer can use (former emilia question's (a)); `02-std-and-packaging/98-packaging-tail/test-helpers.md`'s emilia row (`:64`, `assertSheet` / `assertUtility`) under its 1.0.11 name. **Re-derive the spec:** map renders `tokensToSheet(tokens, fullTheme())`, but `tokensToSheet` is private (`emilia.bp:459`). Needs a `pub` CSS-of-one-list surface (render with `renderRule("e", r, defaultOptions())`), else falls back to `styleRule(tokens, th)._1` (encoded sheet, not CSS) |
| `assertCssWith` | **CONVERT** — fold into `assertCss(loc, tokens, th)` | one helper with explicit theme; caller passes `fullTheme()` |
| `assertUtility`, `assertVariant`, `assertTheme`, `assertRules`, `assertCascade` | **RETIRE** | no consumer, no contract; each subject asserted inline (below) |

Sketch, form (4) (`modules/emilia-test/test/helpers_test.bp`, 33 step 1, two `.snap`, both rows):

```bp
test "class: helpers ---- the contract-4 list" {
    try assertClassName(@src(), cardTokens());          // records e_39b87d03
}
test "css: helpers ---- red 500 text" { try assertCss(@src(), [.Color.Red.500], fullTheme()); }
```

### Per-front suites (185 cases)

| Group | Cases | Covered by (inline, `emilia.bp` unless named) | Verdict |
|---|---|---|---|
| E33 colour palette | 11 | `palette — <family>, eleven shades` (`:17425…`, table-driven per family), `Alpha` (`:19128-19137`), `paletteEntries().length == 286` (`:18997`), `paletteVar` | **RETIRE** |
| E34 modifiers | 18 | variants' two-halves tests (`:1002-1024`), dark strategies (`:1530-1557`), `three deep` (`:1582`), breakpoints, group/peer | **RETIRE** |
| E35 spacing and sizing | 11 | `spacing.bp` (6), `Size —`, `Space —` (`:4972`, `:5207`) | **RETIRE** |
| E36 layout / E37 grid / E38 typography / E39 backgrounds | 8 + 8 + 10 + 5 | per-front banners (`front 36`…`front 39`, `columns —` and `flex shorthand` tests, `gradient` ×14) | **RETIRE** |
| E40 borders, outline, ring | 7 of 9 | `Border.*`, `Ring.W`, `Ring composes …` (`:10560-10803`) | **RETIRE** |
| E40d `divide ---- y two x one colour reverse`, `ast: divide ---- same sibling selector as space` | 2 | — | **OBSOLETE**: 34 step 2 (05emilia-l) adds `border-*-style:var(--tw-border-style)` to `divide-*` |
| E41 effects | 8 | `front 41` banner, shadow ladder, opacity | **RETIRE** |
| E42 filters | 5 of 7 | `Filter.* — every row` (`:12379-12430`), `Filter — blur and grayscale … compose` (`:12689`) | **RETIRE** |
| E42b `backdrop blur and opacity`, `raw filter and raw backdrop` | 2 | — | **OBSOLETE**: 34 step 2 changes `backdrop-opacity` to `opacity(50%)`, adds `-webkit-backdrop-filter` first |
| E43 tables | 2 of 4 | `Table` tests | **RETIRE** |
| E43b `spacing all x y and zero`, `raw spacing` | 2 | — | **OBSOLETE**: 34 step 2 makes `border-spacing-*` write `--tw-border-spacing-x` / `-y` |
| E44 transitions and animation | 6 of 10 | `Animate` ×4, keyframes once, `transitionEntries` (`:13451`) | **RETIRE** |
| E44b `presets`, `base preset lists eleven properties`, `colours then duration override`, `raw property and raw animation` | 4 | — | **OBSOLETE**: 34 step 2 moves presets to `var(--tw-ease, …)` / `var(--tw-duration, …)`; `duration delay ease behavior` may move too, 34's diff decides |
| E45 transforms / E46 interactivity / E47 SVG and accessibility | 8 + 6 + 5 | `Transform —` ×5, `Transform.Skew`, `Interact.*`, `front 47` (`:16125`) | **RETIRE** |
| E48 attributes | 9 | shared fixture (`:16511-16520`); `attributes.bp`; bridge and onze readers | **RETIRE**. Literal lives in J9 and in `assertClassName`'s `.snap` |
| E54 theme / E55 preflight / E56 cascade and output | 7 + 3 + 14 | `theme.bp` (37), `preflight.bp` (14), `output.bp` (47), `drainRules` ×5, `two flushes are independent` | **RETIRE** |
| E57 escape hatches / E58 container / E59 compose | 7 + 7 + 10 | `arbitrary.bp` (9), `container.bp` (6) plus `ContainerAt*` (`:16226-16276`), `named —` ×4, `hocus`, `scrollbarHidden`, `a custom variant composes …` | **RETIRE** |

Retired groups' form: (1), and (3) where a family already runs as one table
(`palette — red, eleven shades`). 34 step 2 needs nothing from the map: its moved families have inline literals, no
snapshot to re-record.

## 5 · `06-emilia/33-emilia-color-palette/test-snap-examples.md` (34.3 KB) — `snap-a`, 33 steps 2 and 4

Map: 39 cases over 9 example projects (`emilia-card` exists, 8 do not), each with its own
`__snapshots__/` through `assertCss`, `assertCascade`, `assertClassName`. 33 step 2: `emilia-card`
emilia-only with ≥ 4 inline tests (unconditional); step 4 builds the 8 (conditional on (c)).

| Group | Cases | In code | Verdict | Rewrite as |
|---|---|---|---|---|
| X1 `emilia-card` | 5 | `examples/emilia-card` still depends on jhonstart (`botopink.json`); 4 inline tests (`main.bp:100-120`), incl. "identical token lists collapse" | **CONVERT** into 33 step 2's inline tests; the map's distinct value (one list repeated across calls, other classes between) is one assert. **Re-derive:** all bodies (palette spelling and theme predate 1.0.11) | (1), replaces 5 snapshots — sketch X1 |
| X2 `theme-brand`, `dashboard-layout`, `typography-article`, `interactive-button`, `dark-mode-nav`, `media-gallery`, `arbitrary-and-compose`, `class-attributes` | 34 | none built. Every combined family asserted inline (§ 4). "Adds" rows covered: dark strategies `:1530-1557`; `named` beside utilities `:named —`; partition order (`output.bp`); `Alpha` with backdrop (`:19073-19137`); contract-4 literal (three readers) | **RETIRE**; the fifteen per-front examples are the example layer. Risk: `theme-brand`'s cascade clears `Ns.Breakpoint` / `Ns.Container`; 34 step 3 and `container.bp:196` make that a refusal for any `Md` / `ContainerAt` leaf | — |

Sketch X1 (`examples/emilia-card/src/main.bp` or `test/main_test.bp`; `bareOptions()` is the
example's own small theme):

```bp
test "card: a repeated list is one class even with another between" {
    val a = emilia(cardTokens()); val b = emilia(titleTokens()); val c = emilia(cardTokens());
    assert a == c && a != b;
    val sheet = await flushWith(bareOptions());
    assert sheet.split("." + a + "{").length == 2;          // one rule, not two
}
```

## 6 · `07-onze/50-onze-cli/test-snap.md` (8.4 KB) — `snap-a`, 50 step 8

Map: 11 cases through 7 `onze-test` helpers (`assertScan`, `assertGeneratedTree`,
`assertTreeCheck`, `assertScaffold`, `assertBuildOutput`, `assertDevServer`, `assertInfo`), none
existing; `onze-test/src/core.bp` holds `assertConfig`, `assertAppFiles`, `assertAlias`,
`assertPublicEnv`. **Realised in `modules/onze-cli/test/__snapshots__/`, 5 `.snap` via
`snapshots.assertAs`:** `scan/every_folder_form…`, `scan/refusals_…`, `generate/staged_the_tree…`,
`create/help_…`, `create/usage_errors_…`. 50 step 8 already struck under (a)/(c).

| Group | Cases | In code | Verdict |
|---|---|---|---|
| C1 scan: the route table, a page-and-route conflict, a staging collision | 3 | realised in `scan/every_folder_form_the_staging_table.snap` and `scan/refusals_page_and_route_together_a_missing_decorator_a_staging_clash.snap` (`scan_test.bp:52-79`) | **OBSOLETE (recorded value)**: map's `/blog/:slug`, `*rest?` and wording superseded — table keeps contract 1's bracket spelling, messages read `app/api: a segment holds both page.bp and route.bp` …; the two `.snap` are current truth, kept as is |
| C2 generate: the app tree | 1 | `generate/staged_the_tree_sorted_deterministic.snap` | **OBSOLETE (recorded value)**: map's `.onze/app_tree.bp` / `root.bp` became `src/app/mod.bp` … `src/onze_routes.bp`; existing `.snap` holds current |
| C3 generate: check | 1 | `generate_test.bp:77-85` (inline `checkTree` asserts) | **RETIRE** |
| C4 create: scaffold `--yes`, and `--src-dir` with `--import-alias ~/` | 2 | `create_test.bp:54-66`, `:92-122` (`botopink check` passes), `:152` (committed scaffold equals `create --yes`) | **OBSOLETE**: decision 218 removes onze's `@/` alias, so recorded `"@/components"` / `--import-alias` lines go; code keeps `importAlias: "@/"` (`create.bp:37`) until 218 lands; rest covered inline |
| C5 create: refuse a non-empty directory | 1 | `create_test.bp:83` | **RETIRE** |
| C6 build: the output tree and build id | 1 | `build_test.bp:63-80` (`src`, `server/erl`, `server/beam`, `static`, `client-manifest.txt`, `build-id`, stable on second build) | **OBSOLETE (recorded value)**: map's `server/app.beam` / `.onze/app_tree.bp` tree predates 50-a's staging (`server/beam/<pkg>@onze_main.beam`); build-id half covered inline |
| C7 dev: the route table on boot | 1 | `main.bp:101`: `onze dev` "not available yet" (50 step 6, reload design, no boot table) | **OBSOLETE**: subject redesigned; 50 step 6 owns its test |
| C8 info: outside a project | 1 | `create_test.bp:133-138` (`project       (none)`, `botopink      1.0.10-beta`) | **RETIRE** (version literals not a contract) |

No KEEP, no CONVERT. Same decision 218 (outside these maps): `onze-test`'s `assertAlias` and its
two `alias/` `.snap` in both `onze` and `onze-test` go too.

## 7 · `07-onze/51-onze-image/test-snap.md` (14.6 KB) — `snap-a`, 51 step 7

Map: 12 cases (image 5, font 3, og 4). **All 12 realised in 10 existing `.snap`** (`-` slugs
recorded as `_`; three image markup cases merged into one). 51 step 7 struck under (a)/(c).

| Group | Cases | Existing `.snap` (test) | Verdict |
|---|---|---|---|
| I1 image: lazy / priority / fill markup | 3 | `image/markup_lazy_with_sizes_priority_fill_blur.snap` (`image_test.bp:87`) | **RETIRE** |
| I2 image: the allowlist matrix | 1 | `image/allowlist_the_matrix.snap` (`:52`) | **RETIRE** |
| I3 image: cache-hit headers and the 400s | 1 | `image/encoder_an_argument_vector_pass_through_a_timeout_a_failure.snap` (`:113-150`, rows #1-#7 incl. `w=999` and `q=101`) | **RETIRE** |
| I4 font: google / head / refusals | 3 | `font/google_inter_400_and_700_latin_swap_adjusted.snap`, `font/head_preload_before_faces…`, `font/refusals_…` (`font_test.bp:93-127`) | **RETIRE** |
| I5 og: style / layout / svg / rasterizer | 4 | `og/style_supported…`, `og/layout_row_space_between…`, `og/svg_the_card…`, `og/rasterizer_png…` (`og_test.bp:32-127`) | **RETIRE**. ONZ-70-7 adds `margin`, `border` to the supported table, re-recording `og/style_…` once — the file's ordinary change |

No rewrite: thinning into inline asserts costs 10 edits, gains nothing.

## 8 · `07-onze/71-onze-release-packaging/test-snap.md` (5.6 KB) — `snap-a`, 71 step 6

Map: 6 cases through `assertReleaseText` / `assertReleaseTree` (do not exist; tests call
`snapshots.assertAs` directly). **Five realised:** `release/{build_id_…,
text_rel_sys_config_vm_args_and_the_boot_script, dockerfile_two_stages_…, shutdown_the_five_steps…,
static_export_three_routes…}.snap`. 71 step 6 (c): "five `.snap` files … `107-release`'s README names them".

| Group | Cases | In code | Verdict | Rewrite as |
|---|---|---|---|---|
| L1 release text (`.rel`, `sys.config`, `vm.args`, `bin/onze`, the no-erts line) | 1 | `release_text_test.bp:22-37` with the `.snap` | **KEEP** (exists): the byte-for-byte text `03-bundled-libs/107-release` must reproduce (`snap-a` (3)); 107 step 1/2 extracts the renderers. **No re-derivation**; current | (5): multi-file text whose exact bytes are another package's contract |
| L2 Dockerfile and `.dockerignore` | 1 | `release_text_test.bp:40-55` with the `.snap` | **KEEP** (exists): 107 also extracts `dockerfile(spec)`, same contract | (5) existing |
| L3 build id / shutdown / static export | 3 | `build_id_test.bp:10`, `package_test.bp:66`, `:129`, each with its `.snap` | **RETIRE** (existing `.snap`; no other library reads them) | (5) existing, no work |
| L4 release tree: the standalone layout plus `scanForSecrets` | 1 | `package_test.bp:87-128` (secrets refusal, manifest chunks present, `packageAssets` copies); no test lists the tree. `includeErts` and `bin/onze` open (ONZ-71-2) | **CONVERT**. **Re-derive:** map's `erts-16.0/`, `lib/*-0.0.1/`, `b7f2a1` are illustrative | (3) table of paths a release must hold, in `package_test.bp`, replaces 1 snapshot — sketch L4 |

Sketch L4 (`modules/onze-release/test/package_test.bp`; `assembleRelease` / `releaseSpec` are the
real names in `otp.bp` / `spec.bp`; scratch `out` from the suite's `testTmp()`):

```bp
test "release: tree ---- the standalone layout" {
    val out = try assembleRelease(releaseSpec("blog", "0.1.0", "b7f2a1"), testTmp());
    for (["BUILD_ID", "bin/onze", "releases/b7f2a1/onze.rel", "releases/b7f2a1/sys.config",
          "releases/b7f2a1/vm.args", "static", "public"]) { p -> assert fs.exists(path.join([out, p])), p; };
}
```

## 9 · `07-onze/53-onze-example-app/test-snap-examples.md` (31.5 KB) — `snap-a`, 53 steps 1–6

Map: E2E runner — 5 harness functions (`bootApp`, `stopApp`, `buildApp`, `request`,
`requestChunks`), 7 snapshot writers (`assertResponse`, `assertResponseStream`, `assertBundle`,
`assertCss`, `assertServeGate`, `assertScaffoldEquals`, `assertExport`) — and 21 cases over
`examples/blog`, `scaffold`, `static-site`. Exists: no `e2e.bp`; `examples/blog` with `db_test`,
`render_test`, `tags_test`; no `middleware.bp`, `actions.bp`, `route.bp`, `loading.bp`; no
`static-site`. 53 step 1 (runner, unconditional), steps 2–6 phrased through these helpers.
**Every recorded body illustrative, re-derive:** home page carries `background-color:#fff` where
emilia emits `var(--color-white)`, invented classes (`e_3f9a1c`), fixed fake hashes.

| Group | Cases | Covered by | Verdict | Rewrite as |
|---|---|---|---|---|
| B0 runner: harness (`bootApp`, `stopApp`, `buildApp`, `request`, `requestChunks`) | — | none | **KEEP** (53 step 1) — harness the acceptance runs on; not a snapshot | — |
| B0w runner: writers (`assertResponse`, `assertResponseStream`, `assertBundle`, `assertCss`, `assertServeGate`, `assertScaffoldEquals`, `assertExport`) | — | none | **CONVERT**: cases need plain asserts over `Reply`, not writers; drop all 7 (`assertCss` would also collide with emilia-test's) | — |
| B1 `pages_test`: home, blog post with island and chunk, not found 404, route group, streaming (dev) | 5 | nothing at app level (jhonstart and onze-server member suites cover the mechanisms) | **CONVERT** (53 steps 2–3); re-derive | (1) status, header, `contains` over `request` (sketch B) — replaces 5 |
| B2 `write_path_test`: middleware ×2, action ×2 | 4 | none (files do not exist yet) | **CONVERT** (53 step 4); re-derive | (1), replaces 4 |
| B3 `api_test`: `GET /api/posts` JSON and 415; the og card | 2 | og's SVG at module level in `og/svg_the_card…` | **CONVERT** (53 step 4) | (1), replaces 2 |
| B4 `assets_test`: favicon served, `content/` and `.onze/` not | 1 | none | **CONVERT** (53 step 5) | (3) table of `#(path, status)`, replaces 1 |
| B5 bundle chunks, CSS stylesheet, build refusal | 3 | bundler `chunks/plan_shared_one_route_chunk_entry.snap`, `manifest/text_the_fixture_app_s_bundle.snap`, `refusal/server_only_the_chain_from_the_root.snap`; assets `stylesheet/cascade_global_before_module_css_fingerprinted.snap`; `onze-cli/build_test.bp:127` (blog's `lib/db` refusal) | **RETIRE** | existing (5) and (1) |
| B6 `gate_test`: dev vs start, the same bytes on every static route | 1 | none; `onze dev` not available (50 step 6) | **CONVERT** (53 step 6) | (2) property, `dev` reply == `start` reply per path, no mask snapshot (sketch B6) — replaces 1 |
| B7 `unit_test`: merged head | 1 | jhonstart `metadata_test` `the page merged onto the root` (mechanism) | **CONVERT** — the blog's own literal, in existing `examples/blog/test/render_test.bp` | (1), replaces 1 |
| B8 scaffold: `create --yes` equals the committed tree; `GET /` | 2 | `onze-cli/create_test.bp:152`; `start_test.bp:103` (`onze build && onze start serves the scaffold's /`) | **RETIRE** | (1) already |
| B9 static-site export: the tree; a dynamic route refused | 2 | `onze-release/package_test.bp:129` with `release/static_export_three_routes_out_a_dynamic_route_refused.snap` | **RETIRE** at module level. The example is ONZ-71-5's; its test a plain `fs.exists` table like L4 | — |

None OBSOLETE. Map's coverage row "`botopink.json` alias" obsolete under 218, no case depends on
it. 53 step 3's 500-with-digest box already follows 194.

Sketch B (form (1); `examples/blog/test/pages_test.bp`, on erlang):

```bp
test "e2e: home ---- GET / renders the hero, the nav and one style block" {
    val app = await bootApp("examples/blog", "start");
    val r = await request(app, "GET", "/", [], "");
    await stopApp(app);
    assert r.status == 200;
    assert r.body.contains("<h1") && r.body.split("<style>").length == 3;   // fonts + emilia
}
```

Sketch B6 (form (2)):

```bp
test "gate: dev vs start ---- the same bytes for every static route" {
    val d = await bootApp("examples/blog", "dev"); val s = await bootApp("examples/blog", "start");
    for (["/", "/about", "/blog/hello-world"]) { p ->
        assert (await request(d, "GET", p, [], "")).body == (await request(s, "GET", p, [], "")).body, p; };
}
```

`(expr).method()` does not parse; the real test binds each reply to a `val` first (maps' style notes).

## Summary table

"Cases" = map's cases; helpers counted separately where the map makes them a contract.

| File | Cases | OBSOLETE | RETIRE | KEEP | CONVERT |
|---|---|---|---|---|---|
| std `97/test-snap.md` | 47 (40 `.snap` + 7 asserts) | 1 | 41 | 4 (existing) | 1 |
| rakun `19/test-snap-helpers.md` | 60 helpers (~1 900 implied `.snap`) | 3 | 56 | 1 (`assertRoute` → `assertResponse`) | 0 |
| jhonstart `26/test-snap.md` | 92 + helper group | 5 (DSL ×3 by 200, digest by 194, `serverOnly` by 186) | 87 | helpers (exist) | 0 |
| emilia `33/test-snap.md` | 185 + 8 helpers | 10 cases (34 step 2) | 175 cases + 5 helpers | 2 helpers | 1 helper (folded) |
| emilia `33/test-snap-examples.md` | 39 | 0 | 34 | 0 | 5 |
| onze `50/test-snap.md` | 11 | 8 | 3 | 0 | 0 |
| onze `51/test-snap.md` | 12 | 0 | 12 | 0 | 0 |
| onze `53/test-snap-examples.md` | 21 + runner (12 fns) | 0 | 7 (B5, B8, B9) | harness (5 fns) | 14 cases; 7 writers dropped |
| onze `71/test-snap.md` | 6 | 0 | 3 | 2 (exist) | 1 |
| **Total** (278.1 KB) | **473 cases** (plus helper tables: emilia 8, jhonstart § 0.2, onze runner 12) | **27** | **418** (plus 5 emilia helpers) | **7 cases** (6 existing `.snap` + rakun's reduced `assertRoute`); helpers: emilia 2, jhonstart's set, onze harness 5 | **21 cases** (plus `assertCssWith` folded, onze's 7 writers dropped) |

**Newly** recorded snapshots: 3 — `emilia-test` (`assertClassName`, `assertCss`), `rakun-test`
(`assertResponse`). Every other KEEP is on disk.

## Front steps that disappear or shrink

| Step | Today | After the verdicts |
|---|---|---|
| `02-std-and-packaging/97` step 7 | (b) writes ~40 `.snap` | **disappears** except the `AGENTS.md` line; plus one inline mocks test (S4); 4 existing files stay |
| `04-rakun/19` step 6 | (b) 57/60 helpers and re-recording every box | **shrinks**: delete `test-snap-helpers.md`, add `assertResponse` plus 1 `.snap`, `AGENTS.md` names the helper, member suites are the evidence |
| `05-jhonstart/26` step 7 | (b) ~150 `.snap`, runs alone and last | **disappears** except the `AGENTS.md` paragraph (J2 travels with step 0, J10b with step 4, J6b with step 8) |
| `06-emilia/33` step 1 | 3 helpers, one `.snap` per helper | **shrinks** to 2 helpers (`assertCss(loc, tokens, th)`, `assertClassName`), 2 `.snap`, two spec fixes (`defaultTheme()`; a `pub` CSS surface) |
| `06-emilia/33` step 3 | 21 suites, ~600 `.snap` | **disappears** except the (a) box |
| `06-emilia/33` step 4 | 8 example members | **disappears** except the (a)/(b) box (`AGENTS.md` points at the fifteen) |
| `06-emilia/33` step 2 | `emilia-card` emilia-only, ≥ 4 inline tests | unchanged; absorbs X1's one extra assert |
| `07-onze/50` step 8 | struck under (a)/(c) | stays struck |
| `07-onze/51` step 7 | struck under (a)/(c) | stays struck (already realised) |
| `07-onze/71` step 6 | (c): five `.snap` through `assertReleaseText` | **shrinks** to "`107-release`'s README names `text_…` and `dockerfile_…`" (files exist, drop "through `assertReleaseText`"); L4 tree a plain test in 71 step 2's or the DoD's acceptance |
| `07-onze/53` step 1 | the runner with 6–7 writers | **shrinks** to 5 harness functions plus one `helpers_test` case each; writers not written |
| `07-onze/53` steps 2–6 | acceptance through `assertResponse` / `assertServeGate` | same boxes, plain asserts; step 6's gate a property, waits on 50 step 6 (`onze dev`) |
| `02-std-and-packaging/98` step 2 | check (2): ≥ 1 snapshot helper per `-test` | unchanged: rakun-test's `assertResponse`, emilia-test's two, jhonstart's and onze's existing helpers satisfy it (erika's is 98 step 1). Without R-K it must be amended |
