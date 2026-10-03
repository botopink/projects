# Audit — `specs/1.0.11-beta/04-rakun/` against `repository/rakun` (remote `feat`, HEAD `fac248b`, 2026-10-02)

Read-only audit. The code was judged from source and git history. Nothing was run (no zig/erl here).

## Track-level facts

- **Front count.** `status.md:7` says `04-rakun 20`. There are 20 directories (19 carried plus 128), and README:23 agrees. Consistent.
- **Front 128 has not happened.** All 25 members still exist under `modules/`, including the nine
  that 128 is meant to merge: `rakun-actuator-api`, `rakun-logging`, `rakun-hateoas`, `rakun-ws`, `rakun-tx`,
  `rakun-devtools`, `rakun-release`, `rakun-rsocket`, `rakun-stream`. There are 8 starters and 3 examples.
  `starters/rakun-starter/botopink.json` still brings `rakun-logging`.
- **128's prerequisites.** `99-gate-rakun` is done (status.md § Done; commits e3c6482, aeaf7e5,
  81948db, cd6afc3 on 2026-09-27). The rakun consumer commits of 102 step 3 and 103 step 2 have
  **not landed**. 102 and 103 are "in analysis": only their package steps are on front branches.
  `rakun-app/src/static_gen.bp:55` still defines its own `kindLetter`. So 128 is blocked, and every
  other front in this track waits on 128.
- **Rakun commits since the milestone opened** (2026-09-27 … 10-02). These are gate fronts (99, 115,
  133, 132/228) and fixes: `rakun-tx` outbox lock (5e17443), `rakun-cache` row race (b538b33),
  `rakun-scheduling` jobstore claim (63d8595), `rakun-websocket` outbound cap (bb5f32a), `rakun-app`
  scan (f3801dd), decision 206 brace imports (4a0e9f2, 263 files), and **130-decorator-outputs**:
  - 5326ffb: `rakun/src/config.bp` `validate()` member.
  - cf0d994: `#[entity]` / `#[entityRepository]` / `#[belongsTo]` / `#[query]` in `rakun-data`,
    `#[cached]` in `rakun-cache` and `#[halResource]` in `rakun-hateoas` now write members (decision 216).
  - No commit since the open is the work of any 04-rakun front.
- **Open maintainer decisions for this track** (still open; none is in `decisions-taken.md`): 03r-ab, 03r-ad,
  03r-ae, 03r-af, 03r-ag, 03r-ak, 03r-al, 03r-am. The confirmations 03r-b…x of 1.0.10 are also unconfirmed.
  There is one more open question with **no id**: whether the RSocket WebSocket edge (R92-1) is taken
  after 187 (92 README § Notes).
- **The 194-box arithmetic is consistent.** In carried.md § Counts, 138 + 8 + 5 + 7 + 36 = 194.

## Per front

| Front | Verdict | Evidence | Remaining | Blockers |
|---|---|---|---|---|
| **128** consolidation | NOT STARTED | All 9 members on disk. Step 0's import grep has no hit outside `repository/rakun`. `rkInstallFailureSink` / `rkReportFailure` never existed, so step 2's grep box is vacuously true. Measured: source lines 51 978 (spec 51 932); member sizes match the table. | Steps 0–10, the gate | 102 step 3 and 103 step 2 rakun commits (unlanded); 130 step 5 is still editing rakun files and is not sequenced |
| **04** core runtime | NOT STARTED | No `rkTagEpoch` / `rkBumpTag` / `rkScannedDeps` / `rawQuery`. `rakun.d.bp` is still in `botopink.json:18`. The `??` workaround is now at `config_test.bp:569` (spec says 548). `rkOnReset` is at `runtime.bp:215` (spec says 212). `headerNames()` exists (`request_context.bp:408`). 20 test `.bp` files (spec says 21). | Steps 1–5 | 128; lg2-e/g/j; 03r-b…e confirmations |
| **74** TLS | NOT STARTED (partly true already) | `verify=full` builds `customize_hostname_check` / `pkix_verify_hostname_match_fun` (`rakun_ssl.erl:397-404`). A cell for "verify none resolves with a warning naming the bundle" exists (`ssl_bundle_test.bp:938`, via `sslWarnings()`, not the logger). "sslReload … next handshake presents the new certificate" exists (`tls_listener_test.bp:225`). No loopback hostname-mismatch cell, no live-connection-survives cell, no reload-interval cell. | Step 1 (mismatch, positive control, warning through the logger); step 2 (live connection survives, 400 ms rotation) | 128 |
| **08** data-sql | NOT STARTED | No lazy exclusion from the eager pass and no `rkExcludeFromEager` (the spec claims 04 "already exposes" it — it does not exist). No `pg_advisory_lock`. The ORM decorators were rewritten by 130 (`T.Columns`, `T.columns()`, `<Repo>.<m>Sql()`). | Steps 1–3 | 128; lg2-e/f (R78-1); decision 147 |
| **15** messaging | NOT STARTED (two premises already true) | The `rakun_listener_names` term is **already kept** (`rakun_messaging.erl:65`, since 116eb7c, 1.0.10). **Producer transactions with read_committed visibility already exist** (`reliability/transaction.bp`, `withProducerTransaction`, 86 step 7, with tests). No `rkOnReset` registration in messaging or scheduling. No `publishWithRetry`, `x-attempt`, `#[jmsListener]` or windows/watermark. | Steps 1–6. Step 5 is "enrol 83's outbox path into the existing producer transaction", not a new broker feature. | 128; 03r-al; lg2-w (R16-1) |
| **79** oauth2/SSO | NOT STARTED | `saml2.bp:42` still answers 501. No `AuthenticationManager`. The `??` dummies are at `basic_test.bp:137,174` (lines are accurate). | Steps 1–3 | 128; 03r-ae; 03r-w |
| **81** release | NOT STARTED (mechanism half present) | `rakun_release.erl:77 compile_dir/1` already compiles every `.erl` of an application dir into `ebin` entries (`release.bp:117`). The spec's "gains `compile_sidecars`" partly exists. No boot cell, no upgrade cell, no `bom-1.5.schema.json`. | Steps 1–3; re-measure whether `compile_dir` already covers `out/erl` | 128; 03r-ak; whether `release_handler` / distribution works under the runner |
| **93** SOAP | NOT STARTED | `rakun-ws/src` = `root.bp`, `ws.bp`; no `generate.bp`. The member is not renamed (as decision 187 wants). | Steps 2–3 | 128; lg2-o |
| **19** test utilities | NOT STARTED | `rakun-test` has no `sidecars/` and no Redis double. 5 test files. | Steps 1–6 | 128; 03r-ag, 03r-am; 15 step 1; 04 step 4 |
| **73** starters/examples | NOT STARTED (target moved) | No `rakun-starter-app`. `rakun-starter-test` now names **`onze` and `onze-test`** by path `../../../onze/modules/{onze,onze-test}` (cd6afc3, gate 99, which also allow-listed them in the starter lint) — the opposite of 73 step 1. No example `README.md`. PK-5 reformat already done (a340dac). | Steps 1–3; undo cd6afc3's allow-list | 128; 03r-af; lg2-v; the toolchain re-measure |
| **13** http clients | PARTIAL (step 4 done) | The RX-8 row "No `record ↔ Json` derivation" is in `language-gaps.md:117`. Both example files are in the Marker index (`language-gaps.md:47-48`). `scripts/language-gap-markers.sh` exits 0. No epoch read, pool, interceptor or `retrieveStream`. | Steps 1–3; tick step 4 | 04 step 1; 128; lg2-a/b |
| **17** logging/metrics | NOT STARTED | `correlationFromHeaders` still has no `traceId()` fallback (`correlation.bp:31-36`). `errorDigest` is local (`digest.bp:67`). `file_test.bp:32` and `endpoint_test.bp:96` still write `$HOME/.cache/bp-rakun`. | Steps 1–3 | 128; 106-log (pending); 13 step 2 |
| **22** app router | NOT STARTED | The implicit mark is still in `rakun_ssr.erl:269`. Root middleware is found at `file_router.bp:343-351` (spec cites 301-303). The refresh cell is at `actions_test.bp:511-514` (spec cites 365) and still uses the literal `"refresh"`. No `startSpan` in the member. | Steps 1–6 | 128; 04 step 5; 102/103 consumer commits; onze 50/53; jhonstart 30/32; decision 186's checker capability |
| **12** cache/session | NOT STARTED (premise changed) | Gate 99 (aeaf7e5, gate-h) **deleted** the env-gated Redis cell, and a `deferred.md:85` row holds it. `RAKUN_TEST_` is gone from `modules/`, so step 1's box "env.read … no longer appears" is already true. The `rkCachePhase() == "action"` cell exists (`revalidate_test.bp:34`), so R62-1's assertion looks present. No epoch bump. | Re-add the Redis arm against the double (step 1); steps 2–3; tick R62-1 | 19 step 1; 04 step 1; 128 |
| **11** actuator | NOT STARTED | The `??` dummies are at `endpoint_host.bp:136,152`. No source field in `configprops` and no source label in `mappings`. | Steps 1–4 | 128; 22 (R11-7) |
| **65** url rules/static | NOT STARTED (one rule already in code) | Decision 201's **rule 2 (GET/HEAD only, else the chain) is already in code** (`static.bp:390-391`). A miss is still 404 (`static.bp:410`, doc at 44-49). The relay is OTP `httpc` inline (`rules.bp:389-390`), not `rakun-client`. It forwards no request headers and only the content type back, so hop-by-hop headers are dropped by construction (not asserted). `devtools.bp` does not set `cache.period`. | Rule 1 fall-through; R65-1 streaming (needs the relay rewritten onto 13, or a different mechanism); R65-2 assertion; step 3 | 128; 13 step 3 |
| **09** nosql | NOT STARTED | No `rakun-data/src/nosql/`. | Steps 1–5 | 128; 19 step 1; 13; 03r-ab; lg2-a |
| **91** pulsar | NOT STARTED | Still `rakun-messaging/src/pulsar/**`. `pulsar.bp` is the only `rakun-client` importer in messaging, so the split does drop the edge. | Steps 1–2 | 128; 15; **03r-ad** |
| **92** rsocket | PARTIAL (step 1 box 1 done) | aeaf7e5 (gate 99) replaced the two-node cell with `pg_broadcast/2`, two same-node subscribers; no `skipped:`, no peer start. The `deferred.md` row for the two-node run is **missing** (no hit for broadcast or distribution). Transports, TLS, channel, `#[messageMapping]` not done. | Step 1 box 2 (deferred row); steps 2–3 | 128; 15; 74; the unnamed R92-1 edge decision |
| **88** cli | NOT STARTED | `rakun-cli` has 4 test files; no `ws generate`, no deps column. | Steps 1–4 | 81, 93, 92, 04 step 4, 73's re-measure; lg2-j; onze 50 |

**Tally:** 0 DONE · 2 PARTIAL (13, 92) · 18 NOT STARTED. Of the 18, six have steps or premises that are
already true in the code: 74, 15, 81, 12, 65, 73.

## Spec inconsistencies (file:line — issue — proposed fix)

1. **`04-rakun/README.md:41,171-172`** — The "cells green only by skipping" row and the gate-stance rows
   for `store_test.bp` and `broadcast_test.bp:102` describe the state before gate 99. Gate-h (aeaf7e5)
   deleted the Redis arm (deferred.md:85) and turned the broadcast into a same-node `pg` assertion.
   — Rewrite both rows: the Redis arm is absent (12 re-adds it once 19's double exists); the
   broadcast is done (92 owes only the deferred row).
2. **`12-rakun-cache/README.md:23-26,34,53`** — The Problem block (`SKIPPED` output) and the
   `store_test.bp:68-73` "gated cell" no longer exist. — Restate it as "the Redis arm has no cell
   (deferred.md:85); step 1 adds it against the double", and mark the "env.read no longer appears" box as already true.
3. **`92-rakun-rsocket/README.md` § Current state, § Problem, Step 1** — It says `rakun_websocket.erl:507-539`
   starts a peer and answers `skipped:`. It no longer does: `pg_broadcast/2` is at :534. — Tick
   step 1 box 1. Add the missing `deferred.md` row (step 1 box 2). Fix Gate `:90`, which says
   `modules/rakun-rsocket`; after 128 that is `modules/rakun-messaging`.
4. **`04-rakun/README.md:48` and the RX-8 rows (README:345, carried.md R13 row)** — These say "markers without a row". The row
   exists (`language-gaps.md:117`, Marker index :47-48). — Close RX-8 and tick `13` step 4.
5. **`modules.md:109-110`** — "decision 187's headline says 17". `decisions-taken.md:90` says
   "25 members become 16", and `128/README.md:235` agrees with it. — Delete the parenthesis.
6. **`modules.md:32`** — The `rakun-ws` row's 1.0.11 column still says "(→ `rakun-soap`, 03r-ac)". — Change it to "merged into
   `rakun-client` by 128 (decision 187)".
7. **`modules.md:84,164`, `73-rakun-starters/README.md:16,30`** — These quote `"onze": { "path": "../../../onze" }`.
   On disk (since cd6afc3) the manifest has `onze` and `onze-test` at `../../../onze/modules/<name>`, and the
   starter lint allow-lists them. — Update the measured text, and say that 73 step 1 also removes the lint allow-list entries.
8. **`73-rakun-starters/README.md:98`** — It says PK-5's format drift is 04's and 22's. a340dac already reformatted
   `modules/rakun` and `modules/rakun-app`. — Drop the note.
9. **`88-rakun-cli/README.md:49-50,104`** — "calls `rakun-soap`'s `generate`… the manifest gains
   `rakun-soap`" contradicts its own `:7` and decision 187. — Change it to `rakun-client` (`src/ws/generate.bp`).
10. **`93-rakun-soap-webservices/README.md:24,38,67`** — The Problem still says "named like a WebSocket
    library" (a rename that is no longer planned). The generator is placed at `src/generate.bp` and
    `test/generate_test.bp`, but the front owns only `src/ws/**` and `test/ws/**`. — Delete the sentence and use
    `src/ws/generate.bp` and `test/ws/generate_test.bp`.
11. **`11-rakun-actuator/README.md:22,38` and Step 3's last box** — R11-8's DoD says "`modules/rakun-actuator-api/`
    exists … depends on nothing", and step 3 rewords it to "depends on the core only". After 128 the member
    does not exist. — Reword it to "the actuator API lives in the core (`src/actuator_api/**`), decision 187".
12. **`17-rakun-logging/README.md:91`** — The gate grep is over `modules/rakun-logging`. After 128 that is
    `modules/rakun/src/logging` and `test/logging`. — Fix the path (the file's own header says to read it as the new path,
    but a grep command is literal).
13. **`08-rakun-data-sql/README.md:37,69`** — The property is `rakun.data.bootstrap-mode`. The code uses
    `rakun.data.repositories.bootstrap-mode` (`datasource.bp:224,238`). Also, `rkExcludeFromEager` "which 04
    already exposes" does not exist anywhere. — Fix the key, and either add the hook to 04 step 4 or say that 08 adds it.
14. **`08-rakun-data-sql/README.md:45-52` (R78-1)** — This describes the emitted `CityCol().ciudad` read. After
    130 / decision 216 the decorators emit `T.Columns` / `T.columns()` members, and `@TypeInfo` (decisions 235, 248)
    may let a decorator reflect another type. — Re-measure the refusal text and re-check whether lg2-e/f still blocks it.
15. **`09-rakun-data-nosql/README.md:89,135`** — `#[documentQuery]` "emits `__rkQuery_<name>()`". Decision 216
    (130) moved `#[query]` to members (`<Repo>.<m>Sql()`). — Align with `#[query]`'s current shape.
    Also `:42` says std's ETS cells are "`any`"; they are `unknown` (`beam.bp:85`).
16. **`04-rakun/README.md:307` (03r-al Measured)** — It says "The in-process broker (03r-k) has no transaction".
    `rakun-messaging/src/reliability/transaction.bp` already provides `withProducerTransaction` with
    read_committed hold/drop, and it is tested (`transaction_test.bp:27-47`). — Restate 03r-al as "83's outbox path
    enrols in 86's existing producer transaction"; 15 step 5 then shrinks.
17. **`15-rakun-messaging/README.md:71-73` and `19/README.md:16,78`** — These say "keeps the `rakun_listener_names` term" as
    work still to do. The term is already put on every registration (`rakun_messaging.erl:65`), and the core reads it
    (`rakun_runtime.erl:257-263`). — Only the `rkOnReset` registration is open; say so.
18. **`65-rakun-url-rules/README.md:39` and Mechanism R65-1** — It says "the relay over `rakun-client`". The relay is an
    inline OTP `httpc` call (`rules.bp:389-390`) that buffers the whole body, so 13's `retrieveStream` does not
    reach it as written. — Either move the relay onto `rakun-client` in step 2, or drop the 13 dependency and stream
    through `httpc`'s `{stream, self}`. Also, Step 1's note that rule 2 "has no box" — rule 2 is already
    implemented (`static.bp:390-391`). Add the box as an assertion of existing code.
19. **`04-rakun/README.md:63,101` vs `status.md:66` and `fronts.md:241`** — The track README places 19 in "A (step 1) · C
    (steps 3–5)". status.md and fronts.md say "19 steps 2–5". Step 2 depends on 15 step 1, so it cannot be A, and
    step 6 (03r-ag) is in no group. — Use "C (steps 2–5); step 6 on 03r-ag" everywhere.
20. **`128/README.md:58`** — It says "`rakun-actuator-api` … is a dependency of 12 members". The manifests show 14
    (actuator, cache, client, data, logging, mail, messaging, metrics, release, scheduling, security,
    session, stream, websocket). — Fix to 14. (Decision 187's "18 of 25 load the four" also measures
    17 with a transitive closure; restate or drop the number.)
21. **Front 130 is invisible to the track.** `01-compiler/130` step 5 still plans edits to
    `rakun/src/decorators.bp`, `autoconfig.bp`, `config.bp`, `context.bp` (04's), `rakun-web/src/convention.bp` (65's),
    `rakun-app` (22's), `rakun-scheduling` / `rakun-messaging` (15's), `rakun-cli` (88's) and `rakun-actuator-api`
    (which 128 moves). It has already landed edits in rakun-data, rakun-cache and rakun-hateoas.
    Neither `04-rakun/README.md` nor `fronts.md` mentions 130 or decision 216. The track's rule
    (README:374) says `src/decorators.bp` "stay[s] frozen". — Add 130 to 128's Depends on (or sequence 130
    step 5's rakun commits before or after 128 as decision 188 does for 102/103), and add a row to § Cross-track
    dependencies. Amend the frozen-files rule to except 130's decorator rewrite.
22. **`92-rakun-rsocket/README.md` § Notes** — The R92-1 edge question ("not decided") has no id and is not in
    `decisions-pending.md` or in README § What the maintainer must decide. — Raise it as `03r-an`.
23. **Line drift in "Current state" blocks** (they are measured-at-open, but are cited as anchors):
    - `04/README.md:52,135`: `runtime.bp:212` → 215; `config_test.bp:548` → 569 (also README:49,338 and carried.md).
    - `22/README.md:15,18,44,47,125`: `file_router.bp:301-303` → 343-351; `actions_test.bp:365` → 511-514.
    - `17/README.md:47-48`: `correlation.bp:32` → 31.
    - Proposed fix: re-pin them, or cite by function name.
24. **Commit branch naming.** Every carried front's Gate says "commit on `fix/NN-…`". 128 says
    `front/128-…`, and the meta `AGENTS.md` § Worktrees / `scripts/worktree-add.sh` creates `front/<name>`. — Use
    `front/<NN-name>` throughout.
25. **`74/README.md:6`** — It says "74's four files", but it lists six (four in the core, two in rakun-web). — "the four core files and two
    of rakun-web".
26. **`91/README.md` Steps** — Step 1 (the split) comes before step 2 (03r-ad). Under 03r-ad (c) there is no split.
    — Make step 1 conditional on 03r-ad (a) or (b). Blast radius names `rakun-stream` / `rakun-rsocket` / `rakun-tx` as
    separate consumers; after 128 they are inside `rakun-messaging` and `rakun-data`.
27. **`status.md:3` vs `:7-8`** (outside this track, noticed in passing) — "13 of 84 fronts" vs the count total of 79; the
    `00-gate 11` count vs the 13 gate fronts listed in § Done plus 114 in analysis (overview.md:27 says 14). — Reconcile the counts.
