# Audit — track `03-bundled-libs/` vs code (2026-10-03)

Measured at: botopink-lang `ec77f649` (= `origin/feat`), rakun `fac248b`, onze `b1a3110`,
jhonstart `eddd681`. The specs are read from the meta checkout (`specs/1.0.11-beta/`, last
`status.md` commit `9509581`, 2026-10-03). Front branches cannot be reached from here: `git log
--all` in botopink-lang has no ref that touches `libs/routing/src/conventions.bp` or
`libs/actions/src/id.bp`, and the remote has only `feat`, `main` and `std/02-async-primitives`.

Landed in botopink-lang `feat` (merges):
- `6d9e06cb` Merge front/104-http into gate-integration-3, with commits `fd8b3ba8` (step 1), `234963ba` (step 2), `ca0a9027` (step 3) and `bfbad0fb` (step 4)
- `3b715323` Merge front/106-log into gate-integration-3, with commit `71fa1d91`
- `88679116` Merge front/125-validation-zod into gate-integration-4, with commit `27ae181d` ("steps 0-2"); `2d267123` followed on feat
- `d83613db` Merge front/97-std-dedupe into gate-integration-13
- **no merge of 102 or 103.** The meta repo's `d623cd2` "Merge front/102-routing-conventions into gate-integration-4" changed **only** `specs/.../102-routing-conventions/README.md`. No code was merged.

Registration (decision 189) is done for http and log:
- `build.zig:763` `bundled_packages = { "std", "routing", "http", "actions", "validation", "log" }`
- `scripts/format-check.sh:39-50` TREES lists `libs/log` and `libs/http`
- `libs/AGENTS.md:47,50` has the rows

Which consumers import what (counts of `from "<pkg>"` in `.bp` files):
- rakun: routing 23, validation 6, actions 1
- jhonstart: actions 10, routing 8
- onze: routing 1
- **No consumer imports `http` or `log`.**

---

## 102 — routing `conventions` + segment helpers

**Verdict: NOT STARTED on feat.** The steps 1–2 work is claimed done, but only on an unmerged
branch that cannot be verified from here.

**Evidence**
- `libs/routing/src/` holds 9 modules: root, segment, table, match, route_kinds, slot_states, url_rules, navigation, pattern. There is no `conventions.bp`. `libs/routing/botopink.json` `files` lists the same 9.
- `grep -rn "fileKinds\|classify\|conventionConflicts\|paramNamesOf\|fillPattern\|toColonPattern" libs/` finds nothing. There is no `test/conventions_test.bp`.
- The only `kindLetter` is the private `fn kindLetter(k: RouteKind)` at `route_kinds.bp:16`. That is the route-kind letter, not decision 172's `conventions.kindLetter(kind)`.
- Every consumer copy is still on disk:
  - rakun-app `file_router.bp:193` `conventionFiles`, `:206` `conventionKind`, `:379` `conflictProblems`
  - rakun-app `static_gen.bp:124` `segmentName`, `:139` `expandRow`
  - rakun-hateoas `hal.bp:139` `bracketToColon`
  - onze `types.bp:108` `appFileKinds`, `:115` `classifyAppFile`
  - onze-cli `scan.bp:58` and onze-bundler `chunk.bp:31` `patternOfSegment`
  - jhonstart `routes.bp:220` `page`, with the hand walk

**Remaining:** all of it on feat — steps 1–2 (land the branch, if it exists) and step 3
(6 members), plus the gate.

**Blockers**
- The branch `front/102-routing-conventions` exists only outside this checkout. If it was never pushed, the work is at risk.
- Step 3 waits on a green gate and on 97. 97 has landed (`d83613db`).
- 49-d must be confirmed.
- 128 and the rakun group A wait on 102 step 3. This is the critical path into track 04.

## 103 — actions `id`

**Verdict: NOT STARTED on feat.** Step 1 is claimed to sit on an unmerged branch.

**Evidence**
- `libs/actions/src/` holds root, state, envelope, rpc and refresh. There is no `id.bp` and no `isActionId`.
- The derivation is still in rakun: `rakun-app/src/actions.bp:237-243` `pub fn actionId(module, name, buildId)`. It reads the secret itself through `rkProp("rakun.actions.secret")`.
- The loose check is still in jhonstart: `jhonstart-forms/src/form.bp:117-121`.

**Remaining:** step 1 (land it), step 2 (2 consumers), gate.

**Blockers**
- Same as 102: the branch cannot be seen from here.
- rakun-app already exports `actionId`. Decision 163 forbids a bundled `actions.id.actionId` while rakun-app exports the same name, unless rakun-app's copy is deleted in the same wave. The README is silent on this.

## 104 — bundled `http`

**Verdict: PARTIAL.** The package half (steps 1–4) has landed on feat. Step 5, the consumer sweep, has not started.

**Evidence**
- `libs/http/src/`:
  - `cookie.bp`: `CookieAttributes`, `parse`, `get`, `serialize`, `formatHeader`
  - `accept.bp`: `qValue`, `parseAccept`, `mediaQuality`, `negotiateMedia`, `tokenQuality`, `negotiateToken`, `parseAcceptLanguage`
  - `mime.bp`: `extensionOf`, `contentTypeOf`, `isText`
  - `status.bp`: `reasonPhrase`
  - `date.bp`: `formatHttpDate`, `parseHttpDate`
  - `byteRange.bp`: `ByteRange`, `parseRange`, `contentRange`
  - `cacheControl.bp`: `directives`, `with*`, `render`, `staticFile`
  - plus an internal `lexical.bp`, which is in `files` but not `pub mod` in root.bp
- Tests: cookie 15, accept 11, codecs 11, date 7. `cookie_test.bp:27` covers tossing `a=1; a=2`, and `date_test.bp:27` covers the epoch date. All of this matches steps 1–4.
- Registration is done (above). `libs/http/AGENTS.md` is present.
- The step 5 sites are all still present:
  - `session_cookie.bp:24` `cookieFromHeader` (still last-wins)
  - `csrf.bp:44` `cookieValue`
  - `request_context.bp:681` `cookieLookup`
  - `i18n.bp:162` `qPerMille`, `:309` `cookieFrom`
  - `negotiation.bp:15` `rangeQ`
  - `compression.bp:89` `qMillis`
  - `static.bp:503` `etagMatches`
  - `error.bp:86` `statusReason` table
  - onze-server and onze-assets unchanged

**Remaining:** step 5 (10 consumer files) and the cold `zig build test` box of the gate.

**Blockers:** step 5 waits on 04, 65, 123, 79, 12, 19, 22, 49 and 51 (decision 188). Almost all
of these are behind 128, which is not started. rakun-logging, rakun-hateoas and rakun-release are
still separate modules.

## 105 — bundled `i18n`

**Verdict: NOT STARTED.**

**Evidence**
- `libs/i18n` is absent.
- `rakun-app/i18n.bp:75` `wellFormedTag` is present.
- jhonstart `render.bp:539` `isLangTag` is present. The spec says `:453`.
- `libs/validation/src/messages.bp:96` `interpolate` is present.

**Remaining:** all of it.

**Blockers:** 104 must land both halves, so 105 waits on the whole 104 sweep chain, plus 22, 26
and the confirmation of 03r-q.

## 106 — bundled `log`

**Verdict: PARTIAL.** Step 1, the package, has landed on feat (`71fa1d91`, merge `3b715323`). Step 2, the consumers, has not started.

**Evidence**
- `libs/log/src/`:
  - `levels.bp`: `Level`
  - `formats.bp`: `LogRecord`, `Format`, `parseFormat`, `renderRecord` and 4 renderers
  - `digest.bp`: `errorDigest`, `clientErrorBody`
  - `sink.bp`: `LogSink`, `defaultSink`, `setSink`
  - `logging.bp`: `Logger` with `logError` at `:157`
- Tests: digest 4, formats 10, levels 3, logging 5. `digest_test.bp:31,33` pins `90e4cc2a07abe1fb` and `be5be69f55e91af2`.
- Registration is done. `libs/log/AGENTS.md:122-126` documents beam and wasm.
- The consumer copies are untouched:
  - `rakun-logging/src/digest.bp:67` `errorDigest`
  - jhonstart `error_boundary.bp:77` `digestOf`, still `contentHash`
  - `rakun-web/error.bp:56-57,199` together with `rakun_chain.erl:480` `problem_digest`

**Remaining:** the 3 step 2 boxes. The first two belong to 17 and 26 step 4. The third is this
front's own commit, after 65. The `zig build test` gate box is also open.

**Blockers:** none from 106 itself. It now *unblocks* 26 step 4, 17 and 49 step 3. Those are
still behind 128, 101 and 100 respectively.

## 107 — bundled `release`

**Verdict: NOT STARTED** (conditional).

**Evidence:** `libs/release` is absent. `rakun-release/src/release.bp:21,96` `rkRelTerm` is still
present, and onze-release `otp.bp`, `docker.bp` and `spec.bp` are unchanged.

**Remaining:** all of it.

**Blockers:**
- `07-g` is open.
- 71 and 81 must land first.
- 128 must move rakun-release into rakun-cli (the Owns path assumes this).

## 125 — validation: Zod's feature set

**Verdict: PARTIAL.** Steps 0–2 landed on feat, but some acceptance items are missing. Steps 3–10 are not started.

**Evidence**
- `27ae181d` "steps 0-2", merged by `88679116`, then `2d267123`:
  - `path.bp` (93 lines)
  - `schemas.bp` (430 lines): `Schema<T>` with `parse`, `parseAt`, `decode`, `accepts`, `optional`, `array`; `text`, `int`, `long`, `float`, `boolean`, `anyJson`; `fieldOf`, `memberPath`, `objectProblems`, `unknownKeys`, `optionalOf`, `decodeArrayOf`, `decodeText`
  - `#[schema]` in `decorators.bp:337-590`, which emits `parse<T>At`, `parse<T>`, `decode<T>`, `schemaOf<T>`
  - the seven structural templates in `messages.bp`
- New tests: `platform_test.bp` (8 cases), `path_test.bp` (8), `schema_test.bp` (21), and `schema_parity_test.bp` (one digest over 20 documents).
- Decision 257 (`07-n`) is recorded in `decisions-taken.md:160`.

**Missing against the step 0–2 acceptance boxes, as read from the code:**
- Step 0:
  - There is no `f32` round-trip case and no `url.parse` WHATWG case in `platform_test.bp`. Its 8 cases are a different set from the README's 8 facts.
  - `AGENTS.md:245` records the `f32` limitation as a note, not as a test.
- Step 2:
  - `examples/signup-schema-example.bp` and `nested-and-arrays-example.bp` are not cases of the suite. `test/schema_test.bp` defines its own `Signup`, and no test references `examples/`.
  - There is no 2 000-level self-reference depth test. `schema_test.bp:257` is 3 levels.
  - The unsupported-field-type refusal exists (`decorators.bp:501-507`). No refusal test was seen.
- **Every box in the README, steps 0–10, is unticked**, although steps 0–2 landed.

**Steps 3–10:** nothing exists. There is no `e164`, `uuidV`, `checks.`, `union2`, `stringbool`,
`encode<T>`, `jsonSchemaOf`, `locales/` or `refusal_test.bp`.

**Remaining:** the step 0–2 residue above, then steps 3–10.

**Blockers:** `07-j` (the front's size) is open. Step 6 has decision 183. 105's `messages.bp`
edit sits between two steps. 121 step 4 and 127 are now unblocked on the 125 side.

---

## Spec inconsistencies (file:line — issue — proposed fix)

1. **`status.md:53`** — 97 is listed as "committed on `front/97-std-dedupe` … lands after the checker's import fix". It is merged on feat (`d83613db`), and the meta repo has `df03bc1` "Merge front/97-std-dedupe into feat". **Fix:** move 97 steps 0–5, 8–10 to landed, and keep only the "left:" items.
2. **`status.md:60`** (106) says "waits on `00-gate` green and 97". The package is merged (`3b715323`, `71fa1d91`). **Fix:** "step 1 landed (`71fa1d91`); step 2 boxes owned by 17, 26 step 4 and the `problem_digest` commit after 65".
3. **`status.md:61`** (104) says "the package half (steps 1–4) waits on `00-gate` green and 97". It has landed (`fd8b3ba8`…`bfbad0fb`, merge `6d9e06cb`). **Fix:** "steps 1–4 landed; step 5 waits on 04, 65, 123, 79, 12, 19, 22, 49, 51".
4. **`status.md:56`** (125) says "steps 0–2 on `front/125-validation-zod`, written against the recommendation of `07-n`, which is open". Steps 0–2 are merged (`88679116`), and 07-n is answered by decision 257 (`decisions-taken.md:160`; `decisions-pending.md:31` agrees). **Fix:** "steps 0–2 landed (decision 257); residue: f32/url platform cases, examples as suite cases, 2 000-deep test; steps 3–10 on `07-j`".
5. **`status.md:54-55`** (102, 103) say "committed on `front/102…` / `front/103…`". Neither branch is on any remote ref here. The meta merge `d623cd2` carried only the README. **Fix:** state where the branch lives (push it to origin), or mark the steps as not landed. Do not count them as progress.
6. **`status.md:20-22`** say "The next integration (`gate-integration-3`: 97, 104, 106 …) was red". That integration and integrations 4–14 have since merged into feat. **Fix:** rewrite "The gate now" against `ec77f649`.
7. **`03-bundled-libs/102-routing-conventions/README.md`, § Current state and Steps 1–2 `[x]`**:
   - It says "Steps 1 and 2 are in the package" and "9 modules and 95 tests". On feat the package has 9 modules **without** `conventions.bp`, and about 66 tests. The text describes the branch, not the tip.
   - **Fix:** say "on `front/102-routing-conventions`, not landed" until the code merges, and untick or annotate the `[x]` boxes.
8. **`102-routing-conventions/README.md`, § Notes questions 1–2 and the step 3 table** ("question 2 below"; "The package ships onze's order"):
   - Decision 171 answered question 1 (the wrap order `layout, template, error, loading, not-found, page, default, route`), and decision 172 answered question 2 (`conventions.kindLetter`). `status.md:54` already says both are committed.
   - **Fix:** delete both questions. Add `kindLetter` to the surface table. Change the step 3 rakun-app row: the records come out in the wrap order, and `onze/test/types_test.bp:14`'s assertion is rewritten (decision 171).
9. **102 README** says "`hal.bp:140-142`". The code is at `hal.bp:139`. Minor; fix the line refs, or cite by function name.
10. **`103-actions-id/README.md`, Problem and Owns**:
    - It says "`actions.bp:199-203` / lines 199-203 only". The derivation is now at `rakun-app/src/actions.bp:237-243`, and it is already named `actionId(module, name, buildId)`. That collides with the package's `actionId` under decision 163.
    - The step 2 box says "`resolveAction` calls `actionId`", which is ambiguous between the two.
    - **Fix:** update the lines. Name the package function differently (`deriveActionId`, as the track README row says), or state that rakun-app's `actionId` is deleted in step 2.
11. **`03-bundled-libs/README.md`, 103 row** names `deriveActionId(secret, …)`, while `103/README.md` step 1 names `actionId(secret, …)`. **Fix:** pick one. `deriveActionId` avoids the clash (item 10).
12. **`103/README.md` step 1** says "`isActionId` … exactly 24 lowercase hex digits". `hmacSha256(...).slice(0,24)` is only lowercase if std's `hmacSha256` returns lowercase hex. **Fix:** add a line that pins the std casing, or a test.
13. **`03-bundled-libs/README.md:136`** says "Open: `07-b`, `07-g`, `07-h`, `07-j`, `07-n`". `07-n` is decision 257. **Fix:** move it to the answered list, and change the 07-n row of the table at `:174` to "answered (257)".
14. **`03-bundled-libs/README.md:131`** says "next free **225**". `decisions-pending.md:10` says 266. **Fix:** point to `decisions-pending.md` and do not keep a number here.
15. **`fronts.md:146-148`** says "Three package halves exist on branches and land first, in this order … 102, 103, 125". 125 has landed. 104 and 106 landed before 102 and 103, so the stated order no longer holds. **Fix:** "125, 104 and 106 package halves landed; 102 steps 1–2 and 103 step 1 remain on branches".
16. **`fronts.md:179`** lists `07-n` as a dependency of 125 steps 0–2, and **`fronts.md:276,291`** list `07-n` as open. **Fix:** drop it, or cite decision 257.
17. **`104-http/README.md:107` (step 5 grep)** includes `bracketToColon`. That name is 102's site, not 104's. **Fix:** drop it from 104's grep, since 102 step 3 owns it.
18. **`104-http/README.md:18,32`** say onze-server `server.bp:61` is a `Cookie:` reader copy. Lines 60-62 are `cookiePairs`, which calls rakun's `cookieLookup` (`server.bp:28` imports it), so the line is a delegation, not a fourth rule. **Fix:** describe it as "switches from rakun's `cookieLookup` to `http.cookie`".
19. **`104-http/README.md:111`** (gate box) mixes "package half: green" into an unticked box. **Fix:** split it into a ticked package-half box and an open sweep box, as 106 does.
20. **`105-i18n/README.md:12,46`** say "`render.bp:453` (`isLangTag`)". It is at `render.bp:539`. The same stale `:453` is in `03-bundled-libs/README.md` § Who else owns. **Fix:** cite by name.
21. **`125-validation-zod/README.md:54-69`** (§ Current state, "Measured 2026-10-01") describes the package before steps 0–2: `decorators.bp` 338 lines (now 590), and no `schemas.bp` or `path.bp`. AGENTS.md says specs describe current state. **Fix:** re-measure, and add `path.bp`, `schemas.bp` and the 4 new test files.
22. **`125-validation-zod/README.md:172-195, 208-249`**: all step 0–2 boxes are unticked although they landed. **Fix:** tick what is verified (path tests, seven templates, the twenty-document parity digest, the three-violation order, the undeclared-key refusal). Leave open, by name, f32, url.parse, examples-as-cases and the 2 000-deep test.
23. **`125-validation-zod/surface.md:3`** cites the reference as `/home/ericfillipe/develop/zod/ZOD_DOCUMENTATION.md`, a path on one person's machine that nobody else can open. **Fix:** cite the Zod 4 docs URL and version, or check the transcription into the spec tree.
24. **`125-validation-zod/surface.md` § Count (`:388-400`)** still counts the step 1–2 rows as "add". They are now "have". **Fix:** recount after steps 0–2, or note "counted before steps 0–2 landed".
25. **`03-bundled-libs/README.md` (the Order diagram and the "packages … land with the gate, after 97" lines)** read as if no package has landed. **Fix:** mark 104 package, 106 package and 125 steps 0–2 as landed.
