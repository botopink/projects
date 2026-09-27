# Carried from 1.0.10 — rakun

One row per 1.0.10 front. *Carried* are the open items that need code or a test; *closed on tick*
are boxes whose behaviour already exists and only needs the assertion run and the box ticked;
*closed by amendment* are boxes whose wording the maintainer confirmed differently (an `03r-*`
choice) and that close when the choice is confirmed; *other track* are boxes rakun owns nothing in.
Item ids are the closing audit's (`R<front>-<n>`, `RX-<n>`); the spec path is under
`specs/1.0.10-beta/03-rakun/`.

| 1.0.10 front | 1.0.11 front | Carried | Closed on tick | Closed by amendment | Other track |
|---|---|---|---|---|---|
| 04 erlang-runtime (57/5) | [`04-rakun-erlang-runtime/`](./04-rakun-erlang-runtime/README.md) | R04-1 (banner, `banner-mode=off`, headless × keep-alive — step 7), R04-2 (DI cycle prints the construction stack — step 8) | R04-3 (`test-libs --lib rakun` green; the stale `rakun erlang 2` ledger line was rewritten — step 10) | — | the `botopink run` re-measure of the three examples → 73 |
| 05 config-profiles (60/2) | 04 | R05-1 (every coercion asserted — step 7), R05-2 (the report names key, value, source file — step 9) | — | 03r-b, 03r-c, 03r-d confirmations | — |
| 06 context-api (45/8) | 04 | R06-1 (`beanNames()` = scanned `#[managed]`), R06-2 (two unqualified `#[provides]` fail the build), R06-3 (`#[postConstruct]` before `eagerInit` returns), R06-4 (`#[scope("request")]` on a ctor-injected factory fails at comptime — lg2-e), R06-5 (eager by default; a missing `#[value]` fails the boot), R06-6 (exit codes), R06-7 (retire `rakun.d.bp`) | — | — | — |
| 07 middleware (87/0) | — | — | — | — | the stale "Open:" note at README L22 stays in the frozen record |
| 08 data-sql (51/2) | [`08-rakun-data-sql/`](./08-rakun-data-sql/README.md) | R08-1 (`bootstrap-mode=lazy` excludes repositories from the eager pass) | R08-2 (DoD umbrella, after R08-1) | — | — |
| 09 data-nosql (0/41) | [`09-rakun-data-nosql/`](./09-rakun-data-nosql/README.md) | steps 1, 2, 3, 5, 6 and the DoD (29 boxes) | — | steps 4 and 7 (12 boxes) → refusal cells and `deferred.md` rows under 03r-ab | — |
| 10 security-auth (56/0) | 79 (files) | — | — | — | — |
| 11 actuator (50/13) | [`11-rakun-actuator/`](./11-rakun-actuator/README.md) | R11-1 (`configprops` with source), R11-2 (`mappings` labelled by source), R11-3 (named startup steps), R11-5 (`#[instrumentation]` before config and beans), R11-8 (DoD 3 boxes) | R11-4 (`POST /actuator/shutdown` — 4 boxes, implemented by 76 in `management.bp`), R11-6 (`traceparent` from 13's client — `transport.bp:236-237`) | — | R11-7 (the spans) is written by 22 under 03r-aj; 11 ticks it |
| 12 cache (35/0) | [`12-rakun-cache/`](./12-rakun-cache/README.md) | the Redis provider's cells against the double (03r-aa), the tag-epoch bump (03r-z), R62-1's assertion moved here | — | 03r-f … 03r-j confirmations | — |
| 13 http-clients (27/1) | [`13-rakun-http-clients/`](./13-rakun-http-clients/README.md) | R13-1 (`revalidateTag` reaches the transport — 03r-z), R13-2 (keep-alive pool; unblocks R75-1), R13-3 (request-interceptor seam; unblocks 03r-w option 2), RX-8 (the missing language-gaps row) | — | — | — |
| 14 validation (33/1) | 04 | R14-1 (no measurable startup cost — a timed assertion) | — | — | — |
| 15 messaging (26/0) | [`15-rakun-messaging/`](./15-rakun-messaging/README.md) | R15-1 as the gate stance (no gated integration cell; `deferred.md` rows for the real drivers), the listener registry on `rkOnReset` and the listener-names term (for 19) | — | 03r-k, 03r-l confirmations | — |
| 16 scheduling (25/1) | 15 | R16-1 (the cron parser called by the decorator — lg2-w), the task registry on `rkOnReset` (for 19) | — | — | — |
| 17 logging (35/2) | [`17-rakun-logging/`](./17-rakun-logging/README.md) | R17-1 (the shared `error.digest` fixture — 31-b), R17-2 (`loggers` / `logfile` refused when unauthorised), R17-3 (`traceId()` in the line for an edge-minted trace), the failure sink install (03r-y) | — | — | jhonstart 31's half of R17-1 |
| 18 session (31/1) | 12 | R18-1 (the Redis arm against the double; the env gate deleted) | — | — | — |
| 19 test-utilities (17/11) | [`19-rakun-test-utilities/`](./19-rakun-test-utilities/README.md) | the Redis double (03r-aa), R19-1 (registries in `resetContext`), R19-2 (`contextSnapshot` listener destinations), R19-3 (broker double — 3 boxes + the "container tests through the double" box), R19-4 (`bootAndExit` — 4 boxes), R19-5 (`#[mock]` + `#[bean]` pairing), RX-5 (03r-ag), the example's `from "onze"` import (STD-2) | — | — | — |
| 20 websocket (22/0) | 92 (one test, carve-out) | the `skipped:` arm of `broadcast_test.bp` (03r-aa) | — | — | — |
| 21 hateoas (23/0) | 13 (example file) | RX-8's second marker | — | — | the broken "Unowned surface" reference and the stale "reader, no writer" text stay in the frozen record; the row 13 files is the correction |
| 22 file-routing (33/1) | [`22-rakun-file-routing/`](./22-rakun-file-routing/README.md) | R22-1 (root `middleware.bp` handed to the chain — `file_router.bp:301`) | — | — | — |
| 23 ssr-pipeline (22/0) | 22 | R23-1 (one writer for the dynamic mark — 03r-ai) | — | — | onze 49's `pageInput` |
| 24 server-actions (37/2) | 22 | R24-1 (`pub val useServer = true` — waits onze 50), R24-2 (refresh payload is contract 2 — waits onze 53, jhonstart 30) | — | 03r-m, 03r-n confirmations | onze 50 · 53 |
| 25 route-handlers (23/4) | 22 | R25-1 (`setPhase(Handler)` negative test), R25-2 (`page.bp` + `route.bp` registers nothing), R25-3 (`OPTIONS` through the chain unless `#[optionsRoute]`), R25-4 (a handler inside the filter chain) | — | — | — |
| 60 static-generation (43/1) | 22 | R60-1 (a failed regeneration reported through the sink — 03r-y) | — | — | — |
| 61 parallel-intercepting (34/0) | 22 (files) | — | — | 03r-p confirmation | — |
| 62 request-context (43/2) | 04 | R62-2 (`after()` failure reported once — 03r-y), R62-3 (the page `Request` enumerates query and headers — onze 49) | R62-1 (assertion through 12's `rkCachePhase()` — moved to 12's tests) | 03r-e confirmation | — |
| 63 navigation-signals (28/0) | 22 (files) | — | — | — | — |
| 64 i18n-routing (39/2) | 22 · 04 | R64-1 (the redirect keeps the raw query bytes — the raw query on the core `Request` is 04's, the filter is 22's) | — | 03r-q confirmation | R64-2 (`Alternate[]` consumed by jhonstart 32) |
| 65 url-rules (40/2) | [`65-rakun-url-rules/`](./65-rakun-url-rules/README.md) | R65-1 (a 50 MB relay streams — needs 13's streaming body), R65-2 (hop-by-hop headers not relayed) | — | — | — |
| 66 metadata-file-routes (38/2) | 22 (files) | — | — | — | both boxes are jhonstart 32's consumption |
| 72 auto-configuration (31/0) | 04 (files) | — | — | — | — |
| 73 starters (25/0) | [`73-rakun-starters/`](./73-rakun-starters/README.md) | `rakun-starter-app`, the `onze` path edge of `rakun-starter-test`, RX-6 (03r-af), the `botopink run` re-measure, a `README.md` per example (PK-2) | — | 03r-r confirmation | lg2-v (a git dependency with a subdirectory) |
| 74 tls-ssl-bundles (31/4) | [`74-rakun-tls-ssl-bundles/`](./74-rakun-tls-ssl-bundles/README.md) | R74-1 (`verify=full` hostname mismatch), R74-2 (`verify=none` warns), R74-3 (live connections survive a reload), R74-4 (`reload-on-update` within two intervals) | — | — | — |
| 75 observability-metrics (44/2) | 17 | R75-1 (one OTLP connection — after R13-2), R75-2 (the trace id in 17's line — same fix as R17-3) | — | 03r-s confirmation | — |
| 76 actuator-security-probes (43/0) | 11 (files) | — | — | 03r-t, 03r-u confirmations | — |
| 77 db-migrations (40/1) | 08 | R77-1 (an advisory-lock arm for the PostgreSQL driver, or the box narrowed to the `global` arm — 08 decides and says which) | — | — | — |
| 78 orm-entities (47/2) | 08 | R78-1 (`findByCiudad` lists the entity's fields — lg2-e/f), R78-2 (a 100-row join count — the ETS arm has no JOIN) | — | 03r-v confirmation | — |
| 79 oauth2-sso (48/6) | [`79-rakun-oauth2-sso/`](./79-rakun-oauth2-sso/README.md) | R79-1 (LDAP `Unavailable` as 10's manager — a seam in `security_filter.bp`), R79-2 (SAML ACS — 03r-ae, 3 boxes), RX-1 (`basic_test.bp:137,174`) | — | R79-3 (`#[clientCredentials]` is `withClientToken` — 03r-w), R79-4 (one `AGENTS.md` at the root) | — |
| 80 devtools (45/0) | 65 (carve-out) | R80-1 (the dev-profile default `rakun.web.resources.cache.period=0`) | — | — | — |
| 81 packaging-release (38/5) | [`81-rakun-packaging-release/`](./81-rakun-packaging-release/README.md) | R81-1 (the tarball boots — compile the shipped sidecars into the release), R81-2 (upgrade and downgrade on a running node — 2 boxes), R81-3 (CycloneDX — 03r-ak) | — | R81-4 (no `templates/`; files render from line arrays) | — |
| 82 static-assets (46/3) | 65 | R82-1 (dev default — with R80-1), R82-4 (a miss falls through to the router — 69-b) | — | R82-2 (a symlink escape is found by resolving the link) | R82-3 (onze 69 registers its roots) |
| 83 distributed-transactions (40/3) | 15 | R83-1 (Kafka producer transactions over the in-process broker — 03r-al, 3 boxes) | — | 03r-x confirmation | — |
| 84 persistent-jobs (40/0) | 15 (files) | — | — | — | — |
| 85 mail (44/0) | — | — | — | — | — |
| 86 messaging-reliability (29/2) | 15 | R86-1 (`Auto`: a `Retry` does not settle the original — reject-without-requeue on the in-process broker), R86-2 (a batch is flushed on shutdown), R86-3 (`publishWithRetry` — the combinator 90 needs) | — | — | — |
| 87 audit-and-exchanges (30/0) | 11 (files) | — | — | — | the audit's "SQL arm env-gated" note of the closing report was not reproduced: no `RAKUN_TEST_DATABASE_URL` exists under `modules/` |
| 88 cli (24/9) | [`88-rakun-cli/`](./88-rakun-cli/README.md) | R88-1 (`rakun run`: profile, `--port`, `--watch`, SIGTERM — 4 boxes, after the re-measure), R88-2 (a failed build exits 1 with the builder's message), R88-3 (`beans` prints injected fields — needs 04's scan registry), R88-4 (two concurrent inspect runs), the `ws generate` command (after 93), `rakun routes` listing rsocket routes (R92-6, after 92) | — | — | R88-5 (cross-type `#[cliCommand]` at comptime — lg2-j), R88-6 (the mirror table in onze 50's README) |
| 89 stream-pipelines (24/3) | 15 | R89-1 (prefetch-1: the second message is not fetched), R89-2 (per-window emission on a watermark), R89-3 (lateness allowance and the late branch) | — | — | — |
| 90 jms-brokers (19/8) | 15 | R90-1 (heart-beat asserted), R90-2 (`jmsSend` through `publishWithRetry`), R90-3 (`#[jmsListener]`), R90-4 (a STOMP redelivery carries the attempt count), R90-5 (86's ack modes mapped), R90-6 (the late reply discarded), R90-7 (the reply destination removed on a raise), R90-8 (health hidden behind 76's exposure) | — | — | — |
| 91 pulsar (6/21) | [`91-rakun-pulsar/`](./91-rakun-pulsar/README.md) | the member split, the refusal cell | — | the 20 data-plane boxes → `deferred.md` under 03r-ad (a) | — |
| 92 rsocket (16/10) | [`92-rakun-rsocket/`](./92-rakun-rsocket/README.md) | R92-1 (WS transport through `rakun-websocket`), R92-2 (TLS from 74's bundles), R92-3 (channel), R92-4 (`#[messageMapping]`), R92-7 (`ws://`, `wss://` requester), R92-8 (a dropped connection fails the request only), R92-9 (spec vectors instead of captured frames) | — | R92-5 (a duplicate route refused at load, not comptime — lg2-j; reworded) | R92-6 (`rakun routes`) → 88 |
| 93 soap-webservices (17/11) | [`93-rakun-soap-webservices/`](./93-rakun-soap-webservices/README.md) | R93-1 (the WSDL/XSD generator — 9 boxes, as a run-time tool under lg2-o), R93-2 (`WsClient` passes 74's bundle), R93-3 (`?wsdl` hash matches the generated header), the rename (03r-ac) | — | — | the `rakun ws generate` command → 88 |

## Closed in 1.0.10, nothing carried

07 · 10 · 12 (by box) · 15 (by box) · 20 · 21 · 23 (by box) · 61 · 63 · 66 (rakun side) · 72 · 73
(by box) · 76 · 80 (by box) · 84 · 85 · 87. Decisions 113–117's rakun halves are landed (RX-3):
every manifest `["erlang"]`, `runtime.mjs` gone, `rakun-app` split, `PageRenderer` / `ChunkWriter`,
the wire names read from `rakun.actions.*`, `routing` / `actions` / `validation` imported as bundled
libraries.

## Counts

194 open boxes in the closed record → 19 fronts here. Of the 194: 138 carried as work; 8 closed on
tick (R04-3, R08-2, R11-4 ×4, R11-6, R62-1); 5 closed by a wording amendment once the named
`03r-*` choice is confirmed (R79-3, R79-4, R81-4, R82-2, R92-5); 7 owned by another track or a
compiler decision (R64-2, 66 ×2, R82-3, R88-5, R88-6, R92-6); 36 decided by a scope question — 09's
steps 4 and 7 and its "report skipped" box (13, 03r-ab), 91's data plane (20, 03r-ad), SAML's ACS
(3, 03r-ae) — each of which either becomes work in its front or a `deferred.md` row, never an open
box left behind.
