# Front 135 — snap: the second test layer, re-evaluated case by case

**Priority:** low — last · **State:** evaluated; no step started
**Depends on:** `snap-a` ([`decisions-pending.md`](../decisions-pending.md)) · step 4: `06-emilia/34` landed (it moves the output the helpers record)
**Owns:** the snapshot steps every other front used to carry — `02-std-and-packaging/97` step 7 ·
`04-rakun/19` step 6 · `05-jhonstart/26` step 7 · `06-emilia/33` steps 1, 3, 4 (the helper and
suite parts) · `07-onze/50` step 8 · `51` step 7 · `71` step 6 · the
helpers named below in `emilia-test`, `rakun-test`, onze's harness
**Does not touch:** any test or `.snap` that exists today — they are evidence and change only with
their test

## Goal

The nine snapshot maps carried from 1.0.10 specified a second test layer (`assert<Subject>(loc, …)`
helpers writing a `.snap` per acceptance box, ~2 500 files). Every case was re-checked against the
code on `feat` and the decisions: is it still applicable, is it already verified, and can it be
written another way. When this front lands, each library verifies those values once — by the tests
it has, by the few helpers a contract needs, and by plain tests for the 21 values nothing verifies.

The maps themselves are history: `../../1.0.11-beta/` holds them at
`02-std-and-packaging/97-std-dedupe/test-snap.md`, `04-rakun/19-rakun-test-utilities/test-snap-helpers.md`,
`05-jhonstart/26-jhonstart-router/test-snap.md`, `06-emilia/33-emilia-color-palette/test-snap{,-examples}.md`,
`07-onze/{50-onze-cli,51-onze-image,71-onze-release-packaging}/test-snap.md`,
`07-onze/53-onze-example-app/test-snap-examples.md`. Their recorded literals predate the code and
are not expected values (finding 4).

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

Verdicts are checked in this order:

| Verdict | Meaning |
|---|---|
| **OBSOLETE** | the case no longer applies: the module, file or function was renamed or removed, a decision changed the recorded output, or the subject is deferred. The decision or code fact is named. |
| **RETIRE** | the value is verified today. The test that verifies it is named, either an inline assert or an existing `.snap`. |
| **KEEP** | the value is verified nowhere, or a contract needs the helper or the `.snap`. The contract is named. |
| **CONVERT** | the value is worth a test, but a plain test is enough. The form is given, with a sketch. |

**Rewrite as** uses the coordinator's scale: (1) a plain inline assert, (2) a property or round-trip test,
(3) a table-driven test, (4) a test over an existing helper or double, (5) a snapshot, only when
nothing cheaper fits. For a RETIRE group, the rewritten form is the existing test, so the existing
test is cited and no sketch is given. A sketch is given only where a new test or helper is proposed.
For KEEP and CONVERT the report also says whether the recorded expected value must be **re-derived**.

### Five findings that hold across files

1. **The rakun and emilia maps use the wrong slug separator.** Both write `-` (`route-…`,
   `color-red-500-text.snap`). std's engine, which these maps cite as their contract, uses `_`. You
   can see it in `snapshots.slugOf` and in the four existing std `.snap` files, such as
   `path_named_second_snapshot.snap`. Every path these two maps record would come out under a
   different name. Onze's 50/51/71 maps have the same flaw, and the realised onze `.snap` files
   already use `_`.
2. **The onze maps' former "Measured" text was stale.** It says §§ 50 · 51 · 52 · 70 · 71 have "inline
   literals, no `.snap`". In fact 24 `.snap` files already realise most of them. They are written
   with `snapshots.assertAs` called directly, not through the map's `onze-test` helpers:
   onze-cli 5, onze-assets 10, onze-og 4, onze-release 5. So 71 step 6 (c) is almost met on disk
   already.
3. **Front 98's packaging check conflicts with retiring rakun's helpers.** Check (2) of
   `02-std-and-packaging/98-packaging-tail` § Mechanism requires every `modules/*-test/src` to hold
   at least one `pub fn assert[A-Z]…(loc: SourceLocation` that hands `loc` to `snapshots.`. Option
   Retiring rakun's maps outright ("the member ships no snapshot helpers") That fails the check. Contract 7 and
   `snapshots.md` rule 3 say the same thing as the check ("every library … exposes, from
   `<lib>-test`, the `assert<Subject>` helpers"). The decision has to resolve this one way or the
   other: one rakun helper, or an amended rule. This report proposes one helper.
4. **Several recorded values contradict the landed code,** not only later decisions. Examples:
   - rakun's map renders HAL `_links` **first**, while `hal_test.bp:55` pins it **last**.
   - std's map expects `normalize("/app/./blog/../page.bp") == "/app/page.bp"`, while
     `path.bp:90-94` documents that `..` popping is deferred.
   - emilia's `assertClassName` is specified as `emilia(tokens)` "under `fullTheme()`", but
     `emilia()` uses `defaultTheme()`, and the contract-4 literal `e_39b87d03` is
     `className(cardTokens(), defaultTheme())` (`emilia.bp:16516`).
   - the onze 53 bodies carry resolved colours (`#fff`) where emilia emits `var(--color-…)`.

   The maps were written before the code, and their literals cannot be trusted as expected values.
5. **The maps miscount themselves, slightly.** rakun's question said 57 helpers, but
   `test-snap-helpers.md` lists 60. jhonstart's said `helpers_test.bp` holds 21 tests, but it holds 20,
   with 7 `.snap`. The other counts check out: std's ~40 files with 4 existing, jhonstart's 32
   example snapshots, emilia's 610 inline tests in `emilia.bp`.

---

## 1 · `02-std-and-packaging/97-std-dedupe/test-snap.md` (14.1 KB) — `snap-a`, 97 step 7

std has no `-test` member, so the map calls `snapshots.assertText` directly. It names 40 `.snap`
files plus 7 engine tests that are plain asserts. The front step was 97 step 7: under (b) it writes the ~40 files;
under (a) it adds one `AGENTS.md` line.

| Group | Specifies | In code today | Verdict | Rewrite as |
|---|---|---|---|---|
| S1 `testing/asserts.bp` messages | 27 `.snap` of the form `asserts: message ---- <fn>`, body `asserts.<fn>: <what>` | each message is pinned with `try equals(errorText(r), "…")` in the fail-path inline test, e.g. `asserts.bp:335, 346, 360 … 642`. All 27 are there, including both `throwsWith` texts and `approxEquals` | **RETIRE** — exact literal on both targets | (1) already, at the foot of `asserts.bp` |
| S2 `testing/snapshots.bp` path rule | 4 `.snap`: suite and slug, named second snapshot, slug punctuation, a name without a suite | **already realised**: the 4 files under `libs/std/src/testing/__snapshots__/snapshots/`, plus inline `snapshots: path ---- the pure half` (line 436) | **KEEP** (no work) — the one place a committed `.snap` proves the engine's read path against the package tree on both targets. The tmpdir engine tests cannot prove that | (5) existing; value correct, no re-derivation |
| S3 engine outcomes | 7 tests with plain asserts, no snapshot (missing, mismatch, match removes stale `.new`, header, CRLF, not a snapshot file, full test name) | `snapshots.bp:452-645` has 11 `engine ----` tests, covering all 7 and adding body-line counting, trailing newlines, named snapshot and module-level refusal | **RETIRE** | (1) already |
| S4 `testing/mocks.bp` verify message | 1 `.snap` via `mockCounter()` / `verifyMessage`, body `mocks.verify: tick - expected exactly 1 matching call(s), got 2` | **no test** pins the text. The Node template (`mocks.bp:73`) appends ` [recorded: …]` / ` [no calls recorded]` and the Erlang one (line 74) does not, so the two diverge today. The map's fixture API is stale: the code has `UserRepo.mock()`, not `mockCounter()` | **CONVERT** — the only std text the map pins that no test reads. **Re-derive**: the fixture names change; the value holds as a prefix on both targets | (1) one inline test in `mocks.bp`, replacing 1 snapshot — see sketch S4 |
| S5 `escape.bp` | 2 (`html` ampersand; `jsString` script close) | `escape.bp:104` (`html("<a href=\"x\">&") == "&lt;a href=\"x\"&gt;&amp;"`, the map's exact input) and `:129-133` (`jsString("</script>") == "\\u003c/script>"`) | **RETIRE** | (1) already |
| S6 `hash.bp` content hashes and digest | 4 (`etag("hello")`, `cacheKey` framing, `fingerprint("app.js",…)`, `sha256Base64Url("")`) | `contentHash("hello") == "f923099"` (`:377`) together with `etag` quoting (`:432-438`); `cacheKey` `62d9003d` / `8aac687d` (`:405-411`, the map's exact values); `fingerprint` "extension stays last" (`:462-477`, other contents); `sha256Base64Url("")` (`:179`, the exact value) | **RETIRE** — decision 260 changes `contentHash` only above U+FFFF, so none of these move | (1) already |
| S7 `encoding.bp` | 1 (`percentEncode("a b&c=d")`) | `encoding.bp:175`, exact | **RETIRE** | (1) already |
| S8 `path.bp` | 1 (`normalize("/app/./blog/../page.bp") == "/app/page.bp"`) | `normalize` drops `.` only. `path.bp:90-94` says "Full `..` pop semantics are deferred", so the recorded value is false today | **OBSOLETE** — the subject is deferred by the code's own note. The test belongs to whichever front implements `..` popping | — |

Sketch S4 (`libs/std/src/testing/mocks.bp`, beside `verify atLeastOnce / times / never`; it needs
`import {testing.asserts}`, or the private `tryCatch` shape `asserts.bp` uses):

```bp
test "mocks: verify message ---- expected exactly one call" {
    val repo = UserRepo.mock();
    val _1 = repo.find(7);
    val _2 = repo.find(7);
    try asserts.throwsWith({ -> val _v = verify(repo, times(1)).find(eq(7)); 0; },
        "mocks.verify: find - expected exactly 1 matching call(s), got 2");
}
```

`throwsWith` checks that the text contains the needle, so it passes on both targets even while
Node keeps its suffix. Making the two templates byte-identical is a separate choice. If the
maintainer wants it, it is a one-line change to the Node template, and the test above becomes
`equals` over a caught message.

**97 step 7 under this evaluation:** the (b) branch is gone. The step shrinks to the
`AGENTS.md` § Tests line plus the one S4 test. The 4 existing files stay.

---

## 2 · `04-rakun/19-rakun-test-utilities/test-snap-helpers.md` (12.7 KB) — `snap-a`, 19 step 6

The map specifies 60 `assert<Subject>(loc, …)` helpers in `rakun-test`, each with a rendering rule,
for about 1 900 `.snap` files. The case lists stayed in the closed 1.0.10 record. `rakun-test/src`
holds `assertions.bp` (`expect*` booleans), `context.bp`, `fake_request.bp`, `mockmvc.bp`,
`root.bp`. There are 0 `.snap` files under `repository/rakun`. Member suites hold about 1 850
inline tests. The front step is 19 step 6 (RX-5): under (a), delete `test-snap-helpers.md` and
write the `AGENTS.md` line; under (b)/(c), write the helpers. Decision 187 merges 25 members into
16, so the groups below follow the post-187 homes.

| Group (post-187 home) | Helpers (n) | Covered by (inline literals) | Verdict | Note |
|---|---|---|---|---|
| R1 `rakun` core | `assertContext`, `assertConfig`, `assertLifecycle`, `assertAutoConfig`, `assertRequestContext`, `assertSslBundle`, `assertBoot` (7) | `rakun/test/` with 374 tests: `di_test`, `scopes_test`, `config_test`, `typed_config_test`, `events_test`, `autoconfig_test`, `conditions_test`, `request_context_test`, `request_memo_test`, `ssl_bundle_test`, `server_test`, `erlang_runtime_test`; `contextSnapshot()` in `rakun-test` | **RETIRE** | `assertBoot`'s exit codes are 19 step 4's `bootAndExit` work, already planned with plain asserts |
| R2 `rakun-web` (+ `rakun-hateoas`, 187) | `assertRoute`, `assertMiddleware`, `assertProblem`, `assertCors`, `assertUrlRules`, `assertStatic`, `assertHal` (7) | `rakun-web/test/` with 209 tests (`middleware_test`, `error_test` 40 asserts, `cors_test` 53, `rules_test`, `static_test`, `dispatch_seam_test`); the route-table wire format (contract 1) in `libs/routing/test/table_test.bp:47-61`; `hal_test.bp` exact JSON | `assertHal` **OBSOLETE**: the map renders `_links` first, the code pins it last (`hal_test.bp:55-58`). `assertRoute` **KEEP, reduced** (see R-K). The other 5 **RETIRE**. `assertProblem`'s digest moves to `log.errorDigest` (decision 194), so its recorded body would change anyway | |
| R3 `rakun-websocket` | `assertWebSocket` (1) | `upgrade_test`, `limits_test`, `broadcast_test` (27 tests) | **RETIRE** | |
| R4 `rakun-app` | `assertRouteTree`, `assertSsr`, `assertPageDispatch`, `assertAction`, `assertHandler`, `assertStaticGen`, `assertSlots`, `assertNavigation`, `assertLocale`, `assertMetadataRoutes` (10) | `rakun-app/test/` with 208 tests (`file_router_test`, `file_router_scan_test`, `ssr_test`, `actions_test`, `route_handler_test`, `route_slots_test`, `route_intercept_test`, `navigation_test`, `i18n_test`, `metadata_routes_test`, `static_gen_test`) | `assertStaticGen` **OBSOLETE**: "`static\|dynamic because <reason>`" is a run-time mark, and decisions 186/202 make the stage a compile-time fact of `#[page]` (jhonstart 26 step 8; rakun 22 step 4 deletes the bridge). The other 9 **RETIRE** | |
| R5 `rakun-data` (+ `rakun-tx`, `rakun-devtools`, 187) | `assertQuery`, `assertMigration`, `assertEntity`, `assertStore`, `assertOutbox`, `assertSaga`, `assertReload` (7) | `rakun-data/test/` with 128 tests (`sql_query_test`, `sql_template_test`, `migration_test`, `orm_test`), `rakun-tx` (`outbox_test`, `saga_test`: 32), `rakun-devtools` (21) | **RETIRE** | the module names change under 187; the subjects stay |
| R6 `rakun-security`, `rakun-session` | `assertSecurity`, `assertOAuth`, `assertSession` (3) | 108 + 35 tests (`policy_test`, `oauth2_test`, `session_test`, `cookie_test`, `rotation_test`) | **RETIRE** | |
| R7 `validation` (bundled, decision 116) | `assertValidation` (1) | `botopink-lang/libs/validation/test/` (`schema_test`, `constraints_test`, `messages_test`, …) | **RETIRE** | decision 144 (undeclared key refused) is asserted there |
| R8 `rakun-cache`, `rakun-client` (+ `rakun-ws` SOAP, 187) | `assertCache`, `assertClient`, `assertSoap` (3) | 69 + 70 + 13 tests (`key_test`, `revalidate_test`, `exchange_test`, `request_test`, `rakun-ws/envelope_test`) | **RETIRE** | |
| R9 actuator (+ `rakun-actuator-api` into the core, 187) | `assertRegistry`, `assertHealth`, `assertEndpoint`, `assertExposure`, `assertProbe`, `assertAudit`, `assertExchanges` (7) | 103 + 10 tests (`health_test`, `endpoint_test`, `exposure_test`, `probes_test`, `recording_test`, `registration_test`) | **RETIRE** | |
| R10 `rakun-metrics`, logging (into the core, 187) | `assertMetrics`, `assertTrace`, `assertLog` (3) | the Prometheus text pinned byte for byte (`endpoints_test.bp:24-30`, `registry_test.bp:33,56`), `tracing_test`, `rakun-logging` with 54 tests (`format_test`, `correlation_test`) | **RETIRE** | rakun-logging's `errorDigest` is deleted for `log`'s (decision 194) |
| R11 `rakun-messaging` (+ `rakun-rsocket`, `rakun-stream`, 187), pulsar | `assertListener`, `assertRetry`, `assertPulsar`, `assertStream`, `assertRSocket` (5) | 91 + 16 + 24 tests | `assertPulsar` **OBSOLETE**: front 91's data plane is deferred (`03r-ad`, `status.md:95`), and no module exists. The other 4 **RETIRE** | |
| R12 `rakun-scheduling` | `assertSchedule`, `assertJobStore` (2) | 100 tests (`cron_test`, `store_test`, `cluster_test`) | **RETIRE** | |
| R13 `rakun-mail` | `assertMail` (1) | `compose_test` checks the MIME lines (`:38,45,115`) | **RETIRE** | |
| R14 `rakun-cli` (+ `rakun-release`, 187) | `assertRelease`, `assertCli` (2) | `release_test.bp` (12 tests: `.rel`, `vm.args`, `sys.config` byte stability, Dockerfile, SBOM), `scaffold_test`, `inspect_test` | **RETIRE** | byte identity with onze is `03-bundled-libs/107` step 1's equality test, not a snapshot |
| R15 starters | `assertStarter` (1) | `rakun/test/starter_manifest_test.bp` | **RETIRE** | |

**R-K — the one rakun helper a contract needs.** Contract 7 (`contracts.md:545-570`),
`snapshots.md` rule 3 and front 98 check (2) all require that `rakun-test` expose at least one
`assert<Subject>` that writes through `snapshots`. Contract 7's own table names rakun's subjects
`route` and `response`. The proposal: keep the response half of `assertRoute` as
`assertResponse` over `MockMvc.perform`'s `Response(status, body)`. It is rewrite form (4), over
the existing `mockmvc.bp`. It adds 1 helper and 1 accepted `.snap` in a `helpers_test.bp`, and
re-records no member box. The value must be derived fresh, since no recorded value exists.

```bp
// modules/rakun-test/src/assertions.bp
pub fn assertResponse(loc: SourceLocation, res: Response) -> @Result<void, string> {
    try snapshots.assertAs(loc, "response", "status " + res.status.toString() + "\n\n" + res.body);
    return;
}
// test/assertions_test.bp: try assertResponse(@src(), MockMvc.standalone().perform(fakeGet("/missing")));
```

The alternative is to amend 98 check (2) to read "a `-test` member that exposes a snapshot helper
hands `loc` to `snapshots.`", and to amend contract 7 / rule 3 to match. That costs nothing in
rakun but weakens one shared rule. This report recommends the helper.

**19 step 6 under this evaluation:** `test-snap-helpers.md` is deleted. `rakun-test` gains one
helper and one `.snap`. `AGENTS.md` names the helper and says the member suites are the evidence.

---

## 3 · `05-jhonstart/26-jhonstart-router/test-snap.md` (61.6 KB) — `snap-a`, 26 step 7

The map specifies the § 0.2 helpers (11 helper files, which exist) and 92 cases, one `.snap` each:
76 code blocks plus 17 table rows in render and bridge. They would land under
`modules/*/test/__snapshots__/`. What exists: about 204 inline tests in the member suites; the
`jhonstart-test` helpers, with 20 tests and 7 `.snap` in `helpers_test.bp`; and 32 `.snap` across 5
examples (blog-ssr 10, document-shell 4, forms 7, islands 5, nav-shell 6), written through 14 of
the helpers. The front step is 26 step 7: under (b), re-record everything, alone, last; under
(a), one `AGENTS.md` paragraph.

| Group | Cases | Covered by | Verdict | Rewrite as |
|---|---|---|---|---|
| J0 § 0.2 helpers (`assertHtml`, `assertRoute`, `assertStream`, `assertDocument`, `assertResponse`, … plus `harness.bp`) | — | `modules/jhonstart-test/src/*.bp` (46 `pub fn`), `helpers_test.bp` | **KEEP** (exists): contract 7 and 98 check (2), and the 32 example `.snap` consume them | no work. `assertDocument`, `assertResponse`, `assertPayload`, `assertRequest` and `assertLink` have no example consumer. They are cheap, so they stay |
| J1 § 94 element surface (`elements:` ×8) | 8 | inline in `jhonstart/src/elements.bp:366-527` (15 tests: `el`, `voidEl`, `isVoidTag`, `isRawTextTag`, renamed constructors, attribute order, verbatim value, document shell, the frozen `</input>`) | **RETIRE** | (1) already. The map's file `modules/jhonstart/test/elements_test.bp` does not exist; the tests are inline |
| J2 § 94 DSL resolution (`html-dsl:` ×3) | 3 | `modules/jhonstart-html/test/elements_test.bp` (3 tests, the same three rows) | **OBSOLETE (location)**: decision 200 deletes `jhonstart-html`. The 3 tests move into the core at 26 step 0, and the subject stays covered | — |
| J3 § 26 router | 7 | `router_test.bp` (29), including the snapshot codec, first match, segments, out-of-range segment, hooks; active nav in `helpers_test` `activeLinkText` and the nav-shell example | **RETIRE** | (1) already |
| J4 § 27 link and reconcile | 10 | `link_test.bp` (28), `reconcile_test.bp` (10); `helpers_test` `simulateNavigation` and the `reconcile/` `.snap` | **RETIRE** | (1), with (5) existing |
| J5 § 28 server components | 5 | `server_test.bp` (19); `helpers_test` request and its `request/` `.snap` | **RETIRE** | |
| J6 § 29 client directive | 5 of 6 | `client_test.bp` (29); `island/` helper `.snap`; islands example | **RETIRE** | |
| J6b `island: server-only is a value nobody reads` | 1 | `client.bp:292` `serverOnly() -> i32` still exists | **OBSOLETE**: decisions 186/202 replace the value with the `#[serverOnly]` / `#[clientOnly]` attributes (26 step 8) | — |
| J7 § 30 streaming | 6 | `streaming_test.bp` (33), covering shell, fills, completion order, loading convention, hole ids; the declaration-order harness case is `helpers_test` `renderToStream` and its `stream/` `.snap` | **RETIRE** | |
| J8 § 30 render (5 blocks plus 13 rows) | 18 | `render_test.bp` (22) for escaping, void, raw text, `#raw`, payload; `streaming_test` `compose:`, `signal:`, `plugin:` for nesting, redirect, depths, plugin order and owned keys | **RETIRE**. Contract 2's payload keys are pinned here and read by onze | |
| J9 § 30 bridge (1 block plus 4 rows) | 5 | `jhonstart-emilia/test/bridge_test.bp` (10), including the contract-4 literal `e_39b87d03` (`:165-186`) | **RETIRE** — the contract has three readers: emilia, the bridge and onze's `build_test.bp:99` | |
| J10 § 31 error boundaries | 6 of 7 | `error_boundary_test.bp` (19); `boundary/` helper `.snap` | **RETIRE** | |
| J10b `boundary: the reader's digest is the server's digest` | 1 | `digestOf(message)` (`error_boundary.bp:77`) | **OBSOLETE**: decision 194 deletes `digestOf` for `log.errorDigest(module, errorClass, message, topFrames)`. Agreement holds by construction ("one call both logs and answers it"); 26 step 4 tests it | — |
| J11 § 32 metadata | 9 | `metadata_test.bp` (16), one for one including both viewport cases and escaping | **RETIRE** | |
| J12 § 67 forms | 8 | `jhonstart-forms/test/form_test.bp` (15); `form/` helper `.snap`; forms example (7 `.snap`) | **RETIRE** | |

**26 step 7 under this evaluation:** the step disappears except for its (a) box, the `AGENTS.md`
paragraph. J2 travels with step 0. J10b is replaced by step 4's test. J6b goes with step 8.

---

## 4 · `06-emilia/33-emilia-color-palette/test-snap.md` (95.3 KB) — `snap-a`, 33 steps 1 and 3

The map specifies 8 helpers in `emilia-test/src/asserts.bp` and 185 shown cases over 21 per-front
suites. The 1.0.10 text implies about 600 files ("one `css:` per leaf in the real file"). What
exists: `emilia-test/src/root.bp` holds one resolve test and no helper. `emilia.bp` holds 610 inline
tests, and the member 734 with `output.bp` (47), `theme.bp` (37), `preflight.bp` (14),
`arbitrary.bp` (9), `container.bp` (6), `spacing.bp` (6), `attributes.bp` (3), `compose.bp` (2).
Fifteen per-front examples assert inline. No `.snap` exists, and no repository imports
`emilia-test`. The front steps: 33 step 1 writes `assertCss`, `assertCssWith` and
`assertClassName` unconditionally; step 3 writes the 21 suites (conditional); 34 step 2 moves five
families' literals.

### Helpers

| Helper | Verdict | Reason / re-derivation |
|---|---|---|
| `assertClassName` | **KEEP** | 98 check (2) and contract 7 need at least one helper in `emilia-test`. It records the one value a consumer reads, the contract-4 class. **Re-derive the spec:** it must be `className(tokens, defaultTheme())`, not "`emilia(tokens)` under `fullTheme()`", because `e_39b87d03` is the `defaultTheme()` value (`emilia.bp:16516`) |
| `assertCss` | **KEEP** | the one CSS helper a consumer can use (the former emilia question's (a)). Contract 7's emilia row (`assertSheet` / `assertUtility`) under its 1.0.11 name. **Re-derive the spec:** the map renders `tokensToSheet(tokens, fullTheme())`, but `tokensToSheet` is private (`emilia.bp:459`). The helper needs a `pub` CSS-of-one-list surface (render the rules with `renderRule("e", r, defaultOptions())`), or it falls back to `styleRule(tokens, th)._1`, which is the encoded sheet and not CSS |
| `assertCssWith` | **CONVERT** — fold into `assertCss(loc, tokens, th)` | one helper with an explicit theme instead of two; a caller passes `fullTheme()` |
| `assertUtility`, `assertVariant`, `assertTheme`, `assertRules`, `assertCascade` | **RETIRE** | no consumer, no contract; each subject is asserted inline (below) |

Sketch, rewrite form (4) (`modules/emilia-test/test/helpers_test.bp`, 33 step 1, two `.snap`
files, both rows):

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
| E34 modifiers | 18 | the variants' two-halves tests (`:1002-1024`), dark strategies (`:1530-1557`), `three deep` (`:1582`), breakpoints, group/peer | **RETIRE** |
| E35 spacing and sizing | 11 | `spacing.bp` (6), `Size —`, `Space —` (`:4972`, `:5207`) | **RETIRE** |
| E36 layout / E37 grid / E38 typography / E39 backgrounds | 8 + 8 + 10 + 5 | the per-front banners (`front 36`…`front 39`, the `columns —` and `flex shorthand` tests, `gradient` ×14) | **RETIRE** |
| E40 borders, outline, ring | 7 of 9 | `Border.*`, `Ring.W`, `Ring composes …` (`:10560-10803`) | **RETIRE** |
| E40d `divide ---- y two x one colour reverse`, `ast: divide ---- same sibling selector as space` | 2 | — | **OBSOLETE**: 34 step 2 (05emilia-l) adds `border-*-style:var(--tw-border-style)` to `divide-*` |
| E41 effects | 8 | `front 41` banner, shadow ladder, opacity | **RETIRE** |
| E42 filters | 5 of 7 | `Filter.* — every row` (`:12379-12430`), `Filter — blur and grayscale … compose` (`:12689`) | **RETIRE** |
| E42b `backdrop blur and opacity`, `raw filter and raw backdrop` | 2 | — | **OBSOLETE**: 34 step 2 changes `backdrop-opacity` to `opacity(50%)` and adds `-webkit-backdrop-filter` first |
| E43 tables | 2 of 4 | `Table` tests | **RETIRE** |
| E43b `spacing all x y and zero`, `raw spacing` | 2 | — | **OBSOLETE**: 34 step 2 makes `border-spacing-*` write `--tw-border-spacing-x` / `-y` |
| E44 transitions and animation | 6 of 10 | `Animate` ×4, keyframes once, `transitionEntries` (`:13451`) | **RETIRE** |
| E44b `presets`, `base preset lists eleven properties`, `colours then duration override`, `raw property and raw animation` | 4 | — | **OBSOLETE**: 34 step 2 moves the presets to `var(--tw-ease, …)` / `var(--tw-duration, …)`. `duration delay ease behavior` may move too; 34's diff decides |
| E45 transforms / E46 interactivity / E47 SVG and accessibility | 8 + 6 + 5 | `Transform —` ×5, `Transform.Skew`, `Interact.*`, `front 47` (`:16125`) | **RETIRE** |
| E48 attributes | 9 | the shared fixture (`:16511-16520`); `attributes.bp`; bridge and onze readers | **RETIRE**. The literal lives in J9 and in `assertClassName`'s one `.snap` |
| E54 theme / E55 preflight / E56 cascade and output | 7 + 3 + 14 | `theme.bp` (37), `preflight.bp` (14), `output.bp` (47), `drainRules` ×5, `two flushes are independent` | **RETIRE** |
| E57 escape hatches / E58 container / E59 compose | 7 + 7 + 10 | `arbitrary.bp` (9), `container.bp` (6) plus `ContainerAt*` (`:16226-16276`), `named —` ×4, `hocus`, `scrollbarHidden`, `a custom variant composes …` | **RETIRE** |

For the retired groups the rewritten form is the existing one: (1), and (3) where the file already
runs a family as one table, such as `palette — red, eleven shades`. No sketch is needed.

**33 step 1:** two helpers instead of three, with the two spec corrections above, plus 2 `.snap`
files. **33 step 3:** disappears except its (a) box (`AGENTS.md`). 34 step 2 needs nothing from the
map: its moved families have inline literals already, so no snapshot would have to be re-recorded.

---

## 5 · `06-emilia/33-emilia-color-palette/test-snap-examples.md` (34.3 KB) — `snap-a`, 33 steps 2 and 4

The map specifies 39 cases over 9 example projects. `emilia-card` exists; the other 8 do not. Each
project would have its own `__snapshots__/` through `assertCss`, `assertCascade` and
`assertClassName`. The front steps: 33 step 2 makes `emilia-card` emilia-only with 4 or more inline
tests (unconditional); step 4 builds the 8 examples (conditional on (c)).

| Group | Cases | In code | Verdict | Rewrite as |
|---|---|---|---|---|
| X1 `emilia-card` | 5 | `examples/emilia-card` still depends on jhonstart (`botopink.json`); 4 inline tests (`main.bp:100-120`), including "identical token lists collapse" | **CONVERT** into 33 step 2's inline tests. The map's distinct value (one list repeated across calls with other classes between) is one assert. **Re-derive:** all bodies, since the map's palette spelling and theme predate 1.0.11 | (1), replacing 5 snapshots — sketch below |
| X2 `theme-brand`, `dashboard-layout`, `typography-article`, `interactive-button`, `dark-mode-nav`, `media-gallery`, `arbitrary-and-compose`, `class-attributes` | 34 | none built. Every family they combine is asserted inline (§ 4 above). The "adds" rows are covered: dark strategies `:1530-1557`; `named` beside utilities `:named —`; partition order (`output.bp`); `Alpha` with backdrop (`:19073-19137`); the contract-4 literal (three readers) | **RETIRE**. The fifteen per-front examples are the example layer. Risk to note: `theme-brand`'s cascade clears `Ns.Breakpoint` / `Ns.Container`, and 34 step 3 and `container.bp:196` turn that into a refusal for any `Md` / `ContainerAt` leaf | — |

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

**33 step 4:** disappears except its (a)/(b) box (`AGENTS.md` points at the fifteen).

---

## 6 · `07-onze/50-onze-cli/test-snap.md` (8.4 KB) — `snap-a`, 50 step 8

The map specifies 11 cases through 7 `onze-test` helpers (`assertScan`, `assertGeneratedTree`,
`assertTreeCheck`, `assertScaffold`, `assertBuildOutput`, `assertDevServer`, `assertInfo`). None of
these helpers exists; `onze-test/src/core.bp` holds `assertConfig`, `assertAppFiles`,
`assertAlias`, `assertPublicEnv`. **Already realised in `modules/onze-cli/test/__snapshots__/`, 5
`.snap` via `snapshots.assertAs`:** `scan/every_folder_form…`, `scan/refusals_…`,
`generate/staged_the_tree…`, `create/help_…`, `create/usage_errors_…`. The front step is 50 step 8,
already struck under (a)/(c).

| Group | Cases | In code | Verdict |
|---|---|---|---|
| C1 scan: the route table, a page-and-route conflict, a staging collision | 3 | the subject is realised in `scan/every_folder_form_the_staging_table.snap` and `scan/refusals_page_and_route_together_a_missing_decorator_a_staging_clash.snap` (`scan_test.bp:52-79`) | **OBSOLETE (recorded value)**. The map's `/blog/:slug` and `*rest?` patterns and its message wording are superseded: the landed table keeps contract 1's bracket spelling, and the messages read `app/api: a segment holds both page.bp and route.bp` … The two existing `.snap` files are the current truth; keep them as they are |
| C2 generate: the app tree | 1 | `generate/staged_the_tree_sorted_deterministic.snap` | **OBSOLETE (recorded value)**. The map's `.onze/app_tree.bp` / `root.bp` layout became `src/app/mod.bp` … `src/onze_routes.bp`; the existing `.snap` holds the current one |
| C3 generate: check | 1 | `generate_test.bp:77-85` (inline `checkTree` asserts) | **RETIRE** |
| C4 create: scaffold `--yes`, and `--src-dir` with `--import-alias ~/` | 2 | `create_test.bp:54-66`, `:92-122` (`botopink check` passes), `:152` (committed scaffold equals `create --yes`) | **OBSOLETE**: decision 218 removes onze's `@/` alias, so the recorded `"@/components"` / `--import-alias` lines go. The code still carries `importAlias: "@/"` (`create.bp:37`) until 218 lands; the rest is covered inline |
| C5 create: refuse a non-empty directory | 1 | `create_test.bp:83` | **RETIRE** |
| C6 build: the output tree and build id | 1 | `build_test.bp:63-80` (`src`, `server/erl`, `server/beam`, `static`, `client-manifest.txt`, `build-id`, stable on the second build) | **OBSOLETE (recorded value)**: the map's `server/app.beam` / `.onze/app_tree.bp` tree predates 50-a's staging (`server/beam/<pkg>@onze_main.beam`). The build-id half is covered inline |
| C7 dev: the route table on boot | 1 | `main.bp:101`: `onze dev` is "not available yet" (50 step 6, a reload design with no boot table) | **OBSOLETE**: the subject is redesigned; 50 step 6 owns its test |
| C8 info: outside a project | 1 | `create_test.bp:133-138` (`project       (none)`, `botopink      1.0.10-beta`) | **RETIRE** (the version literals are not a contract) |

No KEEP and no CONVERT. **50 step 8** stays struck. Under decision 218, `onze-test`'s
`assertAlias` and its two `alias/` `.snap` files in both `onze` and `onze-test` go too. That is
outside these maps, but it is the same decision's blast radius.

---

## 7 · `07-onze/51-onze-image/test-snap.md` (14.6 KB) — `snap-a`, 51 step 7

The map specifies 12 cases (image 5, font 3, og 4). **All 12 are realised already, in 10 existing
`.snap` files.** The map's `-` slugs are recorded as `_`, and the three image markup cases are
merged into one. The front step is 51 step 7, struck under (a)/(c).

| Group | Cases | Existing `.snap` (test) | Verdict |
|---|---|---|---|
| I1 image: lazy / priority / fill markup | 3 | `image/markup_lazy_with_sizes_priority_fill_blur.snap` (`image_test.bp:87`) | **RETIRE** |
| I2 image: the allowlist matrix | 1 | `image/allowlist_the_matrix.snap` (`:52`) | **RETIRE** |
| I3 image: cache-hit headers and the 400s | 1 | `image/encoder_an_argument_vector_pass_through_a_timeout_a_failure.snap` (`:113-150`, rows #1-#7 including `w=999` and `q=101`) | **RETIRE** |
| I4 font: google / head / refusals | 3 | `font/google_inter_400_and_700_latin_swap_adjusted.snap`, `font/head_preload_before_faces…`, `font/refusals_…` (`font_test.bp:93-127`) | **RETIRE** |
| I5 og: style / layout / svg / rasterizer | 4 | `og/style_supported…`, `og/layout_row_space_between…`, `og/svg_the_card…`, `og/rasterizer_png…` (`og_test.bp:32-127`) | **RETIRE**. ONZ-70-7 adds `margin` and `border` to the supported table, which re-records `og/style_…` once. That is the existing file's ordinary change |

Rewrite: none needed; the snapshots exist. They could be thinned into inline asserts. That would
cost 10 edits and gain nothing, since the files already exist and are evidence. **51 step 7**
stays struck.

---

## 8 · `07-onze/71-onze-release-packaging/test-snap.md` (5.6 KB) — `snap-a`, 71 step 6

The map specifies 6 cases. They are meant to go through a helper `assertReleaseText` /
`assertReleaseTree` that does not exist; the tests call `snapshots.assertAs` directly.
**Five are realised:** `release/{build_id_…, text_rel_sys_config_vm_args_and_the_boot_script,
dockerfile_two_stages_…, shutdown_the_five_steps…, static_export_three_routes…}.snap`. The front
step is 71 step 6 (c): "five `.snap` files … `107-release`'s README names them".

| Group | Cases | In code | Verdict | Rewrite as |
|---|---|---|---|---|
| L1 release text (`.rel`, `sys.config`, `vm.args`, `bin/onze`, the no-erts line) | 1 | `release_text_test.bp:22-37` with the `.snap` | **KEEP** (exists): it is the byte-for-byte text `03-bundled-libs/107-release` must reproduce (`snap-a` (3)), and 107 step 1/2 extracts the renderers. **No re-derivation**; the file is current | (5): a multi-file text whose exact bytes are the contract another package keeps |
| L2 Dockerfile and `.dockerignore` | 1 | `release_text_test.bp:40-55` with the `.snap` | **KEEP** (exists): 107 also extracts `dockerfile(spec)`, so it is the same contract | (5) existing |
| L3 build id / shutdown / static export | 3 | `build_id_test.bp:10`, `package_test.bp:66`, `:129`, each with its `.snap` | **RETIRE** (covered by the existing `.snap`; no other library reads them) | (5) existing, no work |
| L4 release tree: the standalone layout plus `scanForSecrets` | 1 | `package_test.bp:87-128` (secrets refusal, manifest chunks present, `packageAssets` copies). No test lists the tree. `includeErts` and `bin/onze` are open (ONZ-71-2) | **CONVERT**. **Re-derive:** the map's `erts-16.0/`, `lib/*-0.0.1/` and `b7f2a1` are illustrative | (3) a table of the paths a release must hold, in `package_test.bp`, replacing 1 snapshot — sketch below |

Sketch L4 (`modules/onze-release/test/package_test.bp`; `assembleRelease` / `releaseSpec` are the
real names in `otp.bp` / `spec.bp`; the scratch `out` comes from the suite's `testTmp()`):

```bp
test "release: tree ---- the standalone layout" {
    val out = try assembleRelease(releaseSpec("blog", "0.1.0", "b7f2a1"), testTmp());
    for (["BUILD_ID", "bin/onze", "releases/b7f2a1/onze.rel", "releases/b7f2a1/sys.config",
          "releases/b7f2a1/vm.args", "static", "public"]) { p -> assert fs.exists(path.join([out, p])), p; };
}
```

**71 step 6 under this evaluation:** the five files exist. What remains is "`107-release`'s README
names `text_…` and `dockerfile_…`". Drop "through `assertReleaseText`". L4 joins 71 step 2's or
the DoD's acceptance as a plain test.

---

## 9 · `07-onze/53-onze-example-app/test-snap-examples.md` (31.5 KB) — `snap-a`, 53 steps 1–6

The map specifies the E2E runner: 5 harness functions (`bootApp`, `stopApp`, `buildApp`,
`request`, `requestChunks`) and 7 snapshot writers (`assertResponse`, `assertResponseStream`,
`assertBundle`, `assertCss`, `assertServeGate`, `assertScaffoldEquals`, `assertExport`). It also
specifies 21 cases over `examples/blog`, `scaffold` and `static-site`. What exists: no `e2e.bp`;
`examples/blog` with `db_test`, `render_test`, `tags_test`; no `middleware.bp`, `actions.bp`,
`route.bp` or `loading.bp`; no `static-site` example. The front steps: 53 step 1 (the runner,
unconditional) and steps 2–6, whose acceptance is phrased through these helpers. **Every recorded
body is illustrative and must be re-derived.** The map's home page carries `background-color:#fff`
where emilia emits `var(--color-white)`, its classes are invented (`e_3f9a1c`), and its hashes are
fixed fakes.

| Group | Cases | Covered by | Verdict | Rewrite as |
|---|---|---|---|---|
| B0 runner: harness (`bootApp`, `stopApp`, `buildApp`, `request`, `requestChunks`) | — | none | **KEEP** (53 step 1) — the harness the acceptance runs on; not a snapshot | — |
| B0w runner: writers (`assertResponse`, `assertResponseStream`, `assertBundle`, `assertCss`, `assertServeGate`, `assertScaffoldEquals`, `assertExport`) | — | none | **CONVERT**: the cases below need plain asserts over `Reply`, not writers. Drop all 7. Note that `assertCss` here would also collide by name with emilia-test's `assertCss` | — |
| B1 `pages_test`: home, blog post with island and chunk, not found 404, route group, streaming (dev) | 5 | nothing at the app level (jhonstart and onze-server member suites cover the mechanisms) | **CONVERT** (53 steps 2–3); re-derive | (1) status, header and `contains` over `request` (sketch B) — replaces 5 |
| B2 `write_path_test`: middleware ×2, action ×2 | 4 | none (the files do not exist yet) | **CONVERT** (53 step 4); re-derive | (1), replaces 4 |
| B3 `api_test`: `GET /api/posts` JSON and 415; the og card | 2 | og's SVG at module level in `og/svg_the_card…` | **CONVERT** (53 step 4) | (1), replaces 2 |
| B4 `assets_test`: favicon served, `content/` and `.onze/` not | 1 | none | **CONVERT** (53 step 5) | (3) a table of `#(path, status)`, replaces 1 |
| B5 bundle chunks, CSS stylesheet, build refusal | 3 | bundler `chunks/plan_shared_one_route_chunk_entry.snap`, `manifest/text_the_fixture_app_s_bundle.snap`, `refusal/server_only_the_chain_from_the_root.snap`; assets `stylesheet/cascade_global_before_module_css_fingerprinted.snap`; `onze-cli/build_test.bp:127` (the blog's `lib/db` refusal) | **RETIRE** | existing (5) and (1) |
| B6 `gate_test`: dev vs start, the same bytes on every static route | 1 | none; `onze dev` is not available (50 step 6) | **CONVERT** (53 step 6) | (2) a property, `dev` reply == `start` reply per path, with no mask snapshot (sketch B6) — replaces 1 |
| B7 `unit_test`: merged head | 1 | jhonstart `metadata_test` `the page merged onto the root` (the mechanism) | **CONVERT** — the blog's own literal, in the existing `examples/blog/test/render_test.bp` | (1), replaces 1 |
| B8 scaffold: `create --yes` equals the committed tree; `GET /` | 2 | `onze-cli/create_test.bp:152`; `start_test.bp:103` (`onze build && onze start serves the scaffold's /`) | **RETIRE** | (1) already |
| B9 static-site export: the tree; a dynamic route refused | 2 | `onze-release/package_test.bp:129` with `release/static_export_three_routes_out_a_dynamic_route_refused.snap` | **RETIRE** at module level. The example itself is ONZ-71-5's; its own test is a plain `fs.exists` table like L4 | — |

None are OBSOLETE. The map's coverage row "`botopink.json` alias" is obsolete under decision 218,
but no case depends on it. The 500-with-digest box in 53 step 3 already follows decision 194.

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

`(expr).method()` does not parse, so the real test binds each reply to a `val` first. Same rule
as the maps' style notes.

**53 under this evaluation:** step 1 shrinks to the five harness functions plus one
`helpers_test` case each. Steps 2–6 keep their boxes but read as plain asserts. Step 6's gate is a
property, and it waits on 50 step 6 (`onze dev`).

---

## Summary table

"Cases" counts the map's cases. Helper rows are counted separately where the map defines helpers
as a contract.

| File | KB | Cases | OBSOLETE | RETIRE | KEEP | CONVERT | Rewrite as |
|---|---|---|---|---|---|---|---|
| std `97/test-snap.md` | 14.1 | 47 (40 `.snap` + 7 asserts) | 1 (`normalize` `..`) | 41 | 4 (existing path-rule `.snap`) | 1 (mocks verify) | (1) one `throwsWith` in `mocks.bp`; the rest already (1) inline |
| rakun `19/test-snap-helpers.md` | 12.7 | 60 helpers (~1 900 implied `.snap`) | 3 (`assertHal`, `assertStaticGen`, `assertPulsar`) | 56 | 1 (`assertRoute`, reduced to `assertResponse`) | 0 | (4) one helper over `MockMvc.perform`; the member suites already (1) |
| jhonstart `26/test-snap.md` | 61.6 | 92 + helper group | 5 (DSL ×3 by 200, digest by 194, `serverOnly` by 186) | 87 | helpers (exist) | 0 | (1) already: 204 inline, 7 + 32 existing `.snap` |
| emilia `33/test-snap.md` | 95.3 | 185 + 8 helpers | 10 cases (34 step 2's four families) | 175 cases + 5 helpers | 2 helpers (`assertClassName`, `assertCss`) | 1 helper (`assertCssWith` folded in) | (4) two helpers with 2 `.snap`; cases already (1)/(3) in `emilia.bp` |
| emilia `33/test-snap-examples.md` | 34.3 | 39 | 0 | 34 | 0 | 5 (`emilia-card`) | (1) inline in `emilia-card` (33 step 2) |
| onze `50/test-snap.md` | 8.4 | 11 | 8 (values superseded, 218 alias, 50-a layout, dev redesign) | 3 | 0 | 0 | existing 5 `.snap` plus inline |
| onze `51/test-snap.md` | 14.6 | 12 | 0 | 12 | 0 | 0 | existing 10 `.snap` |
| onze `53/test-snap-examples.md` | 31.5 | 21 + runner (12 fns) | 0 | 7 (B5, B8, B9) | runner harness (5 fns) | 14 cases; the 7 writers dropped | (1) over `request`; (2) dev == start; (3) asset table |
| onze `71/test-snap.md` | 5.6 | 6 | 0 | 3 | 2 (text, Dockerfile — 107's contract; exist) | 1 (tree) | (3) a path table in `package_test.bp`; the rest existing (5) |
| **Total** | **278.1** | **473 cases** (plus the helper tables: emilia 8, jhonstart § 0.2, onze runner 12) | **27** | **418** (plus 5 emilia helpers) | **7 cases** (6 existing `.snap` + rakun's reduced `assertRoute`); helpers: emilia 2, jhonstart's set, onze harness 5 | **21 cases** (plus `assertCssWith` folded in, onze's 7 writers dropped) | |

Snapshots that must be **newly** recorded under these verdicts: 3. Two in `emilia-test`
(`assertClassName`, `assertCss`) and one in `rakun-test` (`assertResponse`). Everything else KEPT
already exists on disk.

## Front steps that disappear or shrink

| Step | Today | After the verdicts |
|---|---|---|
| `02-std-and-packaging/97` step 7 | (b) writes ~40 `.snap` | **disappears** except the `AGENTS.md` line; plus one inline mocks test (S4) |
| `04-rakun/19` step 6 | (b) 57/60 helpers and re-recording every box | **shrinks**: delete `test-snap-helpers.md`, add `assertResponse` plus 1 `.snap`, add the `AGENTS.md` line |
| `05-jhonstart/26` step 7 | (b) ~150 `.snap`, runs alone and last | **disappears** except the `AGENTS.md` paragraph (J2 travels with step 0, J10b with step 4, J6b with step 8) |
| `06-emilia/33` step 1 | 3 helpers, one `.snap` per helper | **shrinks** to 2 helpers (`assertCss(loc, tokens, th)`, `assertClassName`) and 2 `.snap`, with two spec fixes (`defaultTheme()`; a `pub` CSS surface) |
| `06-emilia/33` step 3 | 21 suites, ~600 `.snap` | **disappears** except the (a) box |
| `06-emilia/33` step 4 | 8 example members | **disappears** except the (a)/(b) box |
| `06-emilia/33` step 2 | `emilia-card` emilia-only, 4 or more inline tests | unchanged; absorbs X1's one extra assert |
| `07-onze/50` step 8 | struck under (a)/(c) | stays struck |
| `07-onze/51` step 7 | struck under (a)/(c) | stays struck (already realised in any case) |
| `07-onze/71` step 6 | (c): five `.snap` through `assertReleaseText` | **shrinks** to "`107-release`'s README names `text_…` and `dockerfile_…`" (files exist, no helper); L4 tree as a plain test |
| `07-onze/53` step 1 | the runner with 6–7 writers | **shrinks** to 5 harness functions; the writers are not written |
| `07-onze/53` steps 2–6 | acceptance through `assertResponse` / `assertServeGate` | same boxes, as plain asserts; step 6's gate is a property |
| `02-std-and-packaging/98` step 2 | check (2): at least one snapshot helper per `-test` | unchanged: rakun-test's `assertResponse`, emilia-test's two, jhonstart's and onze's existing helpers satisfy it (erika's is 98 step 1). Without R-K it would have to be amended |
