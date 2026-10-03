# rakun — the members on disk

**Repo:** `repository/rakun` · **Workspace:** `botopink.json` → `"workspaces": ["modules/*", "starters/*", "examples/*"]`, `"targets": ["erlang"]` · **Closed cut:** `specs/1.0.10-beta/03-rakun/modules.md` (the decision document of 1.0.10; superseded where this file differs)

This file is the tree as it is, read from the manifests at the opening of the milestone (`cat
modules/*/botopink.json`, `starters/*/botopink.json`, `examples/*/botopink.json`; `find modules -path
'*sidecars*' -name '*.erl'`). The closed `modules.md` described a cut of 27 submodules, 9 starters
and 8 example projects; 25 members, 8 starters and 3 examples exist. Where the two disagree, the
disk wins and the difference is listed in § Drift, each with the front that resolves it or the
decision that decides it.

Decision 187 consolidates the 25 members: § After front 128 is the cut
[`128-rakun-consolidation`](./128-rakun-consolidation/README.md) leaves, and § Front → directory
ownership is written against it, because every other front of the track runs after 128.

## Members (25)

Every member is `"target": "erlang"`, `"targets": ["erlang"]` (decisions 113, 117). `std` and the
bundled `routing`, `actions`, `validation` are implicit and never listed. *Depends on* is the
manifest's `dependencies`, every one `{ "workspace": true }`.

| Member | Depends on | Sidecars (`src/sidecars/`) | Tests (`test/`) | 1.0.10 fronts | 1.0.11 front |
|---|---|---|---|---|---|
| `rakun` (core) | — | `rakun_runtime`, `rakun_context`, `rakun_request_context`, `rakun_autoconfig`, `rakun_ssl` | 21 files + `fixtures/` (14 projects) | 04 · 05 · 06 · 14 · 62 · 72 · 73 (`version_set`) · 74 | [`04`](./04-rakun-erlang-runtime/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) |
| `rakun-actuator-api` | `rakun` | `rakun_actuator_api` | `registration_test`, `span_test` | 11 (step 0) · 87 (audit seam) | [`11`](./11-rakun-actuator/README.md) |
| `rakun-web` | `rakun` | `rakun_chain`, `rakun_static` | 15 files + `fixtures/` | 07 · 65 · 82 · 74 (`tls.bp`) | [`65`](./65-rakun-url-rules/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) (`tls.bp`) |
| `rakun-test` | `rakun` | — | `assertions`, `context`, `fake_request`, `mockmvc`, `mocks_pairing` | 19 | [`19`](./19-rakun-test-utilities/README.md) |
| `rakun-client` | `rakun`, `rakun-actuator-api` | `rakun_client` | 8 files | 13 | [`13`](./13-rakun-http-clients/README.md) |
| `rakun-logging` | `rakun`, `rakun-actuator-api` | `rakun_logging` | 7 files | 17 | [`17`](./17-rakun-logging/README.md) |
| `rakun-actuator` | `rakun`, `rakun-actuator-api`, `rakun-web` | `rakun_actuator`, `rakun_probes` | 11 files + `audit/`, `exchanges/` | 11 (host) · 76 · 87 | [`11`](./11-rakun-actuator/README.md) |
| `rakun-hateoas` | `rakun`, `rakun-web` | — | `hal_test` | 21 | — (closed; its example file is under 13 for RX-8) |
| `rakun-ws` | `rakun`, `rakun-client` | `rakun_ws` | `client_test`, `envelope_test` | 93 | [`93`](./93-rakun-soap-webservices/README.md) (→ `rakun-soap`, 03r-ac) |
| `rakun-data` | `rakun`, `rakun-actuator-api`, `rakun-actuator` | `rakun_sql`, `rakun_orm`, `rakun_migration` | 9 files | 08 · 77 · 78 (`nosql/` absent — 09) | [`08`](./08-rakun-data-sql/README.md) · [`09`](./09-rakun-data-nosql/README.md) |
| `rakun-metrics` | `rakun`, `rakun-web`, `rakun-actuator-api`, `rakun-client`, `rakun-actuator` | `rakun_metrics`, `rakun_telemetry` | 6 files | 75 | [`17`](./17-rakun-logging/README.md) (carries 75) |
| `rakun-release` | `rakun`, `rakun-web`, `rakun-actuator-api`, `rakun-actuator` | `rakun_release` | `release_test` | 81 | [`81`](./81-rakun-packaging-release/README.md) |
| `rakun-scheduling` | `rakun`, `rakun-web`, `rakun-actuator-api`, `rakun-actuator`, `rakun-data` | `rakun_scheduling` | 7 files + `jobstore/` | 16 · 84 | [`15`](./15-rakun-messaging/README.md) (carries 16) |
| `rakun-tx` | `rakun`, `rakun-data` | — | `outbox_test`, `saga_test` | 83 | [`15`](./15-rakun-messaging/README.md) (carries 83) |
| `rakun-devtools` | `rakun`, `rakun-data` | `rakun_devtools` | `db_console_test`, `devtools_test` | 80 | — (one line, carve-out of [`65`](./65-rakun-url-rules/README.md)) |
| `rakun-messaging` | `rakun`, `rakun-actuator-api`, `rakun-metrics`, `rakun-client` | `rakun_messaging`, `rakun_jms`, `rakun_jms_fixture`, `rakun_pulsar` | 8 files + `jms/`, `pulsar/`, `reliability/` | 15 · 86 · 90 · 91 | [`15`](./15-rakun-messaging/README.md) · [`91`](./91-rakun-pulsar/README.md) (`pulsar/**`) |
| `rakun-cli` | `rakun`, `rakun-actuator`, `rakun-release` | — | 4 files; `templates/{plain,library,full-stack}/test/` | 88 | [`88`](./88-rakun-cli/README.md) |
| `rakun-mail` | `rakun`, `rakun-actuator-api`, `rakun-data`, `rakun-tx` | `rakun_mail`, `rakun_mail_fixture` | 3 files | 85 | — (closed) |
| `rakun-session` | `rakun`, `rakun-actuator-api`, `rakun-web`, `rakun-actuator`, `rakun-data`, `rakun-scheduling` | `rakun_session` | 6 files | 18 | [`12`](./12-rakun-cache/README.md) (carries 18) |
| `rakun-stream` | `rakun`, `rakun-actuator-api`, `rakun-actuator`, `rakun-data`, `rakun-messaging` | `rakun_stream` | 3 files | 89 | [`15`](./15-rakun-messaging/README.md) (carries 89) |
| `rakun-rsocket` | `rakun`, `rakun-messaging` | `rakun_rsocket` | `codec_test`, `interaction_test` | 92 | [`92`](./92-rakun-rsocket/README.md) |
| `rakun-security` | `rakun`, `rakun-actuator-api`, `rakun-web`, `rakun-data`, `rakun-client`, `rakun-session` | `rakun_security`, `rakun_oauth2`, `rakun_ldap` | 13 files | 10 · 79 | [`79`](./79-rakun-oauth2-sso/README.md) |
| `rakun-cache` | `rakun`, `rakun-actuator-api`, `rakun-web`, `rakun-actuator`, `rakun-session` | `rakun_cache` | 7 files + `fixtures/` | 12 | [`12`](./12-rakun-cache/README.md) |
| `rakun-websocket` | `rakun`, `rakun-actuator-api`, `rakun-web`, `rakun-data`, `rakun-security` | `rakun_websocket` | 6 files | 20 | — (closed; `test/broadcast_test.bp` is a carve-out of [`92`](./92-rakun-rsocket/README.md)) |
| `rakun-app` | `rakun`, `rakun-web`, `rakun-cache` | `rakun_file_router`, `rakun_ssr`, `rakun_actions`, `rakun_navigation`, `rakun_static_gen`, `rakun_metadata_routes` | 14 files + `fixtures/` | 22 · 23 · 24 · 25 · 60 · 61 · 63 · 64 · 66 | [`22`](./22-rakun-file-routing/README.md) |

Sidecars follow `rakun_<name>.erl`; the two `_fixture` files are test-only host modules that play
the remote side of a wire in-process. No `.mjs` file exists anywhere under `repository/rakun`.

## The graph

Levels are computed from the manifests; every edge points at a lower level, so the graph is acyclic.

```
L0  rakun
L1  rakun-actuator-api ◄ rakun        rakun-web ◄ rakun        rakun-test ◄ rakun
L2  rakun-client ◄ api      rakun-logging ◄ api      rakun-actuator ◄ api·web      rakun-hateoas ◄ web      rakun-ws ◄ client
L3  rakun-data ◄ api·actuator      rakun-metrics ◄ web·api·client·actuator      rakun-release ◄ web·api·actuator
L4  rakun-scheduling ◄ web·api·actuator·data    rakun-tx ◄ data    rakun-devtools ◄ data    rakun-mail ◄ api·data·tx
    rakun-messaging ◄ api·metrics·client    rakun-cli ◄ actuator·release
L5  rakun-session ◄ api·web·actuator·data·scheduling    rakun-stream ◄ api·actuator·data·messaging    rakun-rsocket ◄ messaging
L6  rakun-security ◄ api·web·data·client·session    rakun-cache ◄ api·web·actuator·session
L7  rakun-websocket ◄ api·web·data·security    rakun-app ◄ web·cache
```

Two of 1.0.10's three cut-deciding facts hold on disk: the app router is its own member with no HTML
edge (`rakun-app` → `rakun`, `rakun-web`, `rakun-cache`), and `rakun-websocket` is separate. The
third — "the API/host split keeps `rakun-data` off `rakun-actuator`" — does **not**: `rakun-data`
depends on the host (`rakun-actuator`), and the host no longer depends on `rakun-data` or
`rakun-security`; the direction flipped and the graph stays acyclic. `rakun-tx` → `rakun-messaging`
(the 86→83 seam) was never written: `rakun-tx` depends on `rakun-data` only.

### Drift from the closed cut, row by row

| Row | Closed `modules.md` | On disk | Resolution |
|---|---|---|---|
| `rakun-pulsar` | its own member | `rakun-messaging/src/pulsar/**`, `pulsar_host.bp`, `rakun_pulsar.erl`; `rakun-messaging` carries `rakun-client` for it | 03r-ad (front 91) |
| `rakun-soap` | renamed from `rakun-ws` | `rakun-ws` | not renamed: front 128 merges it into `rakun-client` (decision 187, which supersedes 03r-ac) |
| `rakun-validation` | dropped (decision 116) | absent; `config_check.bp` in the core | done |
| `rakun-starter-app` | ninth starter | absent | front 73 adds it |
| `rakun-starter-test` | `rakun-starter`, `rakun-test` | also `"onze": { "path": "../../../onze" }` | front 73 deletes the edge (decision 113: rakun names no onze module) |
| `rakun-data` | `rakun`, `api` | + `rakun-actuator` | kept: the host is where the `db` indicator's details render; acyclic |
| `rakun-actuator` | + `rakun-security`, `rakun-data` | neither | kept: 76's access rules read the security context through `rakun-web`'s request, 87's exchanges record in the chain |
| `rakun-session` | `rakun`, `web`, `data`, `api` | + `rakun-actuator`, `rakun-scheduling` (the expiry sweep) | kept |
| `rakun-scheduling` | `rakun`, `api`, `data` | + `rakun-web`, `rakun-actuator` | kept |
| `rakun-metrics` | `rakun`, `api`, `client`, `web` | + `rakun-actuator` | kept |
| `rakun-cache` | `rakun`, `api`, `client`, `session` | − `rakun-client` (03r-i), + `rakun-web`, `rakun-actuator` | kept |
| `rakun-tx` | + `rakun-messaging`, `rakun-scheduling` | `rakun`, `rakun-data` | kept; the relay tick is the core's timer, the publisher is a seam (03r-x) |
| `rakun-hateoas` | `rakun`, `rakun-app` (ro) | `rakun`, `rakun-web` | kept: `linkTo` reads the decorator route table, not the file router's |
| `rakun-websocket` | `rakun`, `web`, `security`, `api` | + `rakun-data` | kept |
| `rakun-stream` | `rakun`, `messaging`, `data`, `api` | + `rakun-actuator` | kept |
| `rakun-rsocket` | `rakun`, `websocket`, `messaging` | `rakun`, `messaging` | front 128 merges it into `rakun-messaging`; the edge R92-1 needs for the WS transport is front 92's |
| `rakun-mail` | `rakun`, `api`, `tx` | + `rakun-data` | kept |
| `rakun-ws` | `rakun`, `client`, `web` | `rakun`, `client` | kept; a published endpoint registers through the core's route table |
| `rakun-release` | `rakun`, `actuator` | + `rakun-web`, `rakun-actuator-api` | kept |
| `rakun-cli` | `rakun`, `release`, `devtools` (+`soap` optional) | `rakun`, `actuator`, `release` | kept; `rakun run --watch` delegates to `botopink run`'s watcher, not to `rakun-devtools`; front 128 merges `rakun-release` into it; the `ws generate` command (front 88, after 93) adds `rakun-client`, where the generator lives after 128 |
| `rakun-devtools` | `rakun` | + `rakun-data` (the read-only DB console) | kept |
| `rakun-test` | every member (test-only) | `rakun` | 03r-am (front 19) |
| `rakun-app` (03r-aj) | `rakun`, `web`, `cache` | same | kept: the span API is the core's after front 128, so front 22 adds no edge (decision 187) |
| examples | 8 projects | 3: `rakun`, `rakun-container`, `rakun-ssr` | 03r-af (front 73) |
| `starters/test/**` | 73 owns it | absent; the manifest test is `modules/rakun/test/starter_manifest_test.bp` | front 73 (a test under `starters/` if one is added; otherwise the row is corrected here) |

## After front 128 — the consolidated cut (decision 187)

Nine members move into the member that always loads or solely uses them; `rakun-web` and
`rakun-actuator` stay members. The nine moves leave 16 members (decision 187's headline says 17 —
[`128-rakun-consolidation/README.md`](./128-rakun-consolidation/README.md) § Notes). A merged
member's files sit in a sub-directory of the absorbing member's `src/` and `test/` named after it;
its sidecar keeps its name.

| Member | Absorbs | Depends on | 1.0.11 fronts |
|---|---|---|---|
| `rakun` (core) | `rakun-actuator-api` (`src/actuator_api/**`) · `rakun-logging` (`src/logging/**`) | — | [`04`](./04-rakun-erlang-runtime/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) · [`11`](./11-rakun-actuator/README.md) (`actuator_api/**`) · [`17`](./17-rakun-logging/README.md) (`logging/**`) |
| `rakun-web` | `rakun-hateoas` (`src/hateoas/**`) | `rakun` | [`65`](./65-rakun-url-rules/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) (`tls.bp`) |
| `rakun-test` | — | `rakun` | [`19`](./19-rakun-test-utilities/README.md) |
| `rakun-client` | `rakun-ws` (`src/ws/**`) | `rakun` | [`13`](./13-rakun-http-clients/README.md) · [`93`](./93-rakun-soap-webservices/README.md) (`ws/**`) |
| `rakun-actuator` | — | `rakun`, `rakun-web` | [`11`](./11-rakun-actuator/README.md) |
| `rakun-data` | `rakun-tx` (`src/tx/**`) · `rakun-devtools` (`src/devtools/**`) | `rakun`, `rakun-actuator` | [`08`](./08-rakun-data-sql/README.md) · [`09`](./09-rakun-data-nosql/README.md) (`nosql/**`) · [`15`](./15-rakun-messaging/README.md) (`tx/**`) · [`65`](./65-rakun-url-rules/README.md) (one line of `devtools/devtools.bp`) |
| `rakun-metrics` | — | `rakun`, `rakun-web`, `rakun-client`, `rakun-actuator` | [`17`](./17-rakun-logging/README.md) |
| `rakun-cli` | `rakun-release` (`src/release/**`) | `rakun`, `rakun-actuator`, `rakun-web` | [`88`](./88-rakun-cli/README.md) · [`81`](./81-rakun-packaging-release/README.md) (`release/**`) |
| `rakun-scheduling` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-data` | [`15`](./15-rakun-messaging/README.md) |
| `rakun-mail` | — | `rakun`, `rakun-data` | — (closed) |
| `rakun-messaging` | `rakun-rsocket` (`src/rsocket/**`) · `rakun-stream` (`src/stream/**`) | `rakun`, `rakun-metrics`, `rakun-client`, `rakun-actuator`, `rakun-data` | [`15`](./15-rakun-messaging/README.md) · [`91`](./91-rakun-pulsar/README.md) (`pulsar/**`) · [`92`](./92-rakun-rsocket/README.md) (`rsocket/**`) |
| `rakun-session` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-data`, `rakun-scheduling` | [`12`](./12-rakun-cache/README.md) |
| `rakun-security` | — | `rakun`, `rakun-web`, `rakun-data`, `rakun-client`, `rakun-session` | [`79`](./79-rakun-oauth2-sso/README.md) |
| `rakun-cache` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-session` | [`12`](./12-rakun-cache/README.md) |
| `rakun-websocket` | — | `rakun`, `rakun-web`, `rakun-data`, `rakun-security` | — (closed; `test/broadcast_test.bp` is a carve-out of [`92`](./92-rakun-rsocket/README.md)) |
| `rakun-app` | — | `rakun`, `rakun-web`, `rakun-cache` | [`22`](./22-rakun-file-routing/README.md) |

```
L0  rakun (+ actuator-api, logging)
L1  rakun-web (+ hateoas) ◄ rakun      rakun-test ◄ rakun      rakun-client (+ ws) ◄ rakun
L2  rakun-actuator ◄ web
L3  rakun-data (+ tx, devtools) ◄ actuator      rakun-metrics ◄ web·client·actuator      rakun-cli (+ release) ◄ web·actuator
L4  rakun-scheduling ◄ web·actuator·data      rakun-mail ◄ data      rakun-messaging (+ rsocket, stream) ◄ metrics·client·actuator·data
L5  rakun-session ◄ web·actuator·data·scheduling
L6  rakun-security ◄ web·data·client·session      rakun-cache ◄ web·actuator·session
L7  rakun-websocket ◄ web·data·security      rakun-app ◄ web·cache
```

Edges the merges add: `rakun-cli → rakun-web` (from `rakun-release`); `rakun-messaging →
rakun-actuator` and `→ rakun-data` (from `rakun-stream`). Edges they remove: every one to
`rakun-actuator-api`, `rakun-logging`, `rakun-tx`. `rakun-cache` and `rakun-client` stay separate
and meet through the core's tag epoch (decision 185). The member question still open is 03r-ad
(`rakun-pulsar`, front 91).

## Starters (8) — `repository/rakun/starters/`

A starter is a manifest and a `src/root.bp` that re-exports; `{ "workspace": true }` to every sibling
(03r-r). Asserted by `modules/rakun/test/starter_manifest_test.bp` and `version_set_test.bp`.

| Starter | Brings |
|---|---|
| `rakun-starter` | `rakun`, `rakun-logging` — `rakun` only after front 128 (logging is in the core) |
| `rakun-starter-web` | `rakun-starter`, `rakun-web` |
| `rakun-starter-data-sql` | `rakun-starter`, `rakun-data` |
| `rakun-starter-security` | `rakun-starter`, `rakun-security`, `rakun-session` |
| `rakun-starter-actuator` | `rakun-starter`, `rakun-actuator`, `rakun-metrics` |
| `rakun-starter-cache` | `rakun-starter`, `rakun-cache` |
| `rakun-starter-messaging` | `rakun-starter`, `rakun-messaging` |
| `rakun-starter-test` | `rakun-starter`, `rakun-test` — and `onze` by path, which front 73 removes |
| `rakun-starter-app` (to add, front 73) | `rakun-starter-web`, `rakun-app`, `rakun-cache` |

## Examples (3) — `repository/rakun/examples/`

| Project | Manifest name | Depends on | Sources | Cell |
|---|---|---|---|---|
| `examples/rakun` | `rakun-example` | `rakun` | `main.bp`, `config.bp`, `posts.bp`, `users.bp` | erlang `build`; `botopink run` re-measured by front 73 |
| `examples/rakun-container` | `rakun-container-example` | `rakun` | `main.bp` | erlang `build` |
| `examples/rakun-ssr` | `rakun-ssr-example` | `rakun`, `rakun-app` | `main.bp` | erlang `build` |

No example has a test file; each is a build cell. The seven projects of the closed cut are 03r-af.

## Front → directory ownership, this milestone

Every front owns whole files; two fronts in one member own disjoint files and test files. A shared
member's `botopink.json` and `src/root.bp` belong to the lowest-numbered front; the other appends.
The paths are the tree front 128 leaves (§ After front 128): 128 runs first and alone, and owns
every member while it is open.

| Front | Owns | Does not touch |
|---|---|---|
| 128 | every member, the starters, the examples and the workspace manifest, for the nine moves and the imports they rewrite | what any file does; the frozen core files |
| 04 | `modules/rakun/**` except 74's files, `src/actuator_api/**` (11) and `src/logging/**` (17) with their tests and sidecars; `modules/rakun/test/fixtures/**` | `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen); 74's, 11's and 17's files |
| 74 | `modules/rakun/src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp` · `modules/rakun-web/src/tls.bp`, `test/tls_test.bp` | everything else in both members |
| 08 | `modules/rakun-data/**` except 09's, 15's `src/tx/**` and 65's line in `src/devtools/devtools.bp` | `src/nosql/**`, `test/nosql/**`, `src/tx/**`, `test/tx/**`; in this milestone it edits neither `botopink.json` nor `src/root.bp` |
| 09 | `modules/rakun-data/src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**`; appends to `botopink.json` `files` and `src/root.bp` | `datasource.bp`, `sql/**`, `orm/**`, `migration/**` |
| 11 | `modules/rakun-actuator/**` · `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` (was `rakun-actuator-api`) | the rest of the core (04's) |
| 12 | `modules/rakun-cache/**`, `modules/rakun-session/**` | `rakun-test` (imports the double) |
| 13 | `modules/rakun-client/**` except 93's `src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` | `rakun-cache`; 93's files |
| 15 | `modules/rakun-messaging/**` except 91's and 92's (`src/stream/**`, was `rakun-stream`, is 15's); `modules/rakun-data/src/tx/**` and `test/tx/**` (was `rakun-tx`); `modules/rakun-scheduling/**` | `src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**` (91) · `src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` (92) · the rest of `rakun-data` (08, 09) |
| 17 | `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` (was `rakun-logging`); `modules/rakun-metrics/**` | the rest of the core (04's) |
| 19 | `modules/rakun-test/**` | every other member (03r-am decides whether a double may live beside its module — then that file is 19's by carve-out, named in its README) |
| 22 | `modules/rakun-app/**` | — |
| 65 | `modules/rakun-web/**` except 74's two files (`src/hateoas/**`, was `rakun-hateoas`, included — no open box) · one line in `modules/rakun-data/src/devtools/devtools.bp` and `test/devtools/devtools_test.bp` (carve-out; was `rakun-devtools`) | `tls.bp`, `test/tls_test.bp` |
| 73 | `starters/**`, `examples/**`, `modules/README.md` § starters and examples | `modules/**` otherwise |
| 79 | `modules/rakun-security/**` | — |
| 81 | `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` (was `rakun-release`) | the rest of `rakun-cli` (88's) |
| 88 | `modules/rakun-cli/**` except 81's `release/**` | 81's files; `rakun-client/src/ws/**` (93's) |
| 91 | `modules/rakun-messaging/src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`; if 03r-ad splits: `modules/rakun-pulsar/**` and the removal lines in `rakun-messaging/{botopink.json,src/root.bp}` after 15 lands | the rest of `rakun-messaging` |
| 92 | `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` (was `rakun-rsocket`) · `modules/rakun-websocket/test/broadcast_test.bp` and the broadcast runner in `src/sidecars/rakun_websocket.erl` (carve-out) | the rest of `rakun-messaging` (15's) and of `rakun-websocket` |
| 93 | `modules/rakun-client/src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` (was `rakun-ws`), `modules/README.md` row, `AGENTS.md` § SOAP | the rest of `rakun-client` (13's) · `rakun-cli` (88 writes the command) |

`repository/rakun/AGENTS.md` and `modules/README.md` are shared: each front edits its own section
in the same commit as the code, and never another front's.
