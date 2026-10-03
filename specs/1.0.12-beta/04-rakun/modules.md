# rakun — the members

**Repo:** `repository/rakun` · **Workspace:** `botopink.json` → `"workspaces": ["modules/*", "starters/*", "examples/*"]`, `"targets": ["erlang"]`

§ Members and § The graph: the cut [`128-rakun-consolidation`](./128-rakun-consolidation/README.md)
leaves (decision 187: 25 → 16); every front is written against them. § On disk until 128 lands:
the 25-member facts 128 step 0 measures from; 128 step 10 deletes it.

Every member `"target": "erlang"`, `"targets": ["erlang"]` (decisions 113, 117). `std` and bundled
`routing`, `actions`, `validation` implicit, never listed. *Depends on* = manifest `dependencies`,
all `{ "workspace": true }`. Sidecars `src/sidecars/rakun_<name>.erl`; `_fixture` = test-only host
module playing a wire's remote side. No `.mjs` under `repository/rakun`.

## Members (16, after 128)

A merged member's files sit in a same-named sub-directory of the absorber's `src/` and `test/`;
its sidecar keeps its name.

| Member | Absorbs | Depends on | Fronts |
|---|---|---|---|
| `rakun` (core) | `rakun-actuator-api` (`actuator_api/`) · `rakun-logging` (`logging/`) | — | [`04`](./04-rakun-erlang-runtime/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) · [`11`](./11-rakun-actuator/README.md) (`actuator_api/**`) · [`17`](./17-rakun-logging/README.md) (`logging/**`) |
| `rakun-web` | `rakun-hateoas` (`hateoas/`) | `rakun` | [`65`](./65-rakun-url-rules/README.md) · [`74`](./74-rakun-tls-ssl-bundles/README.md) (`tls.bp`) |
| `rakun-test` | — | `rakun` | [`19`](./19-rakun-test-utilities/README.md) |
| `rakun-client` | `rakun-ws` (`ws/`, SOAP) | `rakun` | [`13`](./13-rakun-http-clients/README.md) · [`93`](./93-rakun-soap-webservices/README.md) (`ws/**`) |
| `rakun-actuator` | — | `rakun`, `rakun-web` | [`11`](./11-rakun-actuator/README.md) |
| `rakun-data` | `rakun-tx` (`tx/`) · `rakun-devtools` (`devtools/`) | `rakun`, `rakun-actuator` | [`08`](./08-rakun-data-sql/README.md) · [`09`](./09-rakun-data-nosql/README.md) (`nosql/**`) · [`15`](./15-rakun-messaging/README.md) (`tx/**`) · [`65`](./65-rakun-url-rules/README.md) (one line of `devtools/devtools.bp`) |
| `rakun-metrics` | — | `rakun`, `rakun-web`, `rakun-client`, `rakun-actuator` | [`17`](./17-rakun-logging/README.md) |
| `rakun-cli` | `rakun-release` (`release/`) | `rakun`, `rakun-actuator`, `rakun-web` | [`88`](./88-rakun-cli/README.md) · [`81`](./81-rakun-packaging-release/README.md) (`release/**`) |
| `rakun-scheduling` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-data` | [`15`](./15-rakun-messaging/README.md) |
| `rakun-mail` | — | `rakun`, `rakun-data` | — (closed) |
| `rakun-messaging` | `rakun-rsocket` (`rsocket/`) · `rakun-stream` (`stream/`) | `rakun`, `rakun-metrics`, `rakun-client`, `rakun-actuator`, `rakun-data` | [`15`](./15-rakun-messaging/README.md) · [`91`](./91-rakun-pulsar/README.md) (`pulsar/**`) · [`92`](./92-rakun-rsocket/README.md) (`rsocket/**`) |
| `rakun-session` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-data`, `rakun-scheduling` | [`12`](./12-rakun-cache/README.md) |
| `rakun-security` | — | `rakun`, `rakun-web`, `rakun-data`, `rakun-client`, `rakun-session` | [`79`](./79-rakun-oauth2-sso/README.md) |
| `rakun-cache` | — | `rakun`, `rakun-web`, `rakun-actuator`, `rakun-session` | [`12`](./12-rakun-cache/README.md) |
| `rakun-websocket` | — | `rakun`, `rakun-web`, `rakun-data`, `rakun-security` | — (closed) |
| `rakun-app` | — | `rakun`, `rakun-web`, `rakun-cache` | [`22`](./22-rakun-file-routing/README.md) |

Only under `03r-ad` (a)/(b) (front 91): a 17th member `rakun-pulsar` (from
`rakun-messaging/src/pulsar/**`, `pulsar_host.bp`, `rakun_pulsar.erl`) on `rakun`,
`rakun-messaging`, `rakun-client`, plus, as 03r-ad (a) lists, `rakun-security` and `rakun-data`
(91's mechanism adds those two only with the data plane); `rakun-messaging` loses its direct
`rakun-client` edge (transitive through `rakun-metrics`).

## The graph

Every edge points lower; acyclic.

```
L0  rakun (+ actuator_api, logging)
L1  rakun-web (+ hateoas) ◄ rakun      rakun-test ◄ rakun      rakun-client (+ ws) ◄ rakun
L2  rakun-actuator ◄ web
L3  rakun-data (+ tx, devtools) ◄ actuator      rakun-metrics ◄ web·client·actuator      rakun-cli (+ release) ◄ web·actuator
L4  rakun-scheduling ◄ web·actuator·data      rakun-mail ◄ data      rakun-messaging (+ rsocket, stream) ◄ metrics·client·actuator·data
L5  rakun-session ◄ web·actuator·data·scheduling      [rakun-pulsar ◄ messaging·client, 03r-ad — L7 with security]
L6  rakun-security ◄ web·data·client·session      rakun-cache ◄ web·actuator·session
L7  rakun-websocket ◄ web·data·security      rakun-app ◄ web·cache
```

128 adds `rakun-cli → rakun-web` (from `rakun-release`), `rakun-messaging → rakun-actuator`,
`→ rakun-data` (from `rakun-stream`; every `rakun-messaging` consumer loads the data member); removes
every edge to `rakun-actuator-api`, `rakun-logging`, `rakun-tx`. `rakun-cache` and `rakun-client`
stay separate, meet through the core's tag epoch (decision 185). Owed or in question:
`rakun-test`'s test-only edges (03r-am, 19), `rakun-cli → rakun-client` for `rakun ws generate`
(88, after 93), `rakun-messaging → rakun-websocket` for RSocket's WebSocket transport (03r-an, 92).

## On disk until 128 lands (25 members)

128 step 0's baseline (manifests on `feat`); `→` = merged by 128.

| Member | Depends on (`rakun` omitted) | Sidecars | `*_test.bp` |
|---|---|---|---|
| `rakun` | — | `runtime`, `context`, `request_context`, `autoconfig`, `ssl` | 20 + `fixtures/` |
| `rakun-actuator-api` → core | — | `actuator_api` | 2 |
| `rakun-logging` → core | api | `logging` | 7 |
| `rakun-web` | — | `chain`, `static` | 14 + `fixtures/` |
| `rakun-hateoas` → web | web | — | 1 |
| `rakun-test` | — | — | 5 |
| `rakun-client` | api | `client` | 8 |
| `rakun-ws` → client | client | `ws` | 2 |
| `rakun-actuator` | api, web | `actuator`, `probes` | 13 (incl. `audit/`, `exchanges/`) |
| `rakun-data` | api, actuator | `sql`, `orm`, `migration` | 9 |
| `rakun-tx` → data | data | — | 2 |
| `rakun-devtools` → data | data | `devtools` | 2 |
| `rakun-metrics` | web, api, client, actuator | `metrics`, `telemetry` | 6 |
| `rakun-release` → cli | web, api, actuator | `release` | 1 |
| `rakun-cli` | actuator, release | — | 4 |
| `rakun-scheduling` | web, api, actuator, data | `scheduling` | 10 (incl. `jobstore/`) |
| `rakun-mail` | api, data, tx | `mail`, `mail_fixture` | 3 |
| `rakun-messaging` | api, metrics, client | `messaging`, `jms`, `jms_fixture`, `pulsar` | 15 (incl. `jms/`, `pulsar/`, `reliability/`) |
| `rakun-rsocket` → messaging | messaging | `rsocket` | 2 |
| `rakun-stream` → messaging | api, actuator, data, messaging | `stream` | 3 |
| `rakun-session` | api, web, actuator, data, scheduling | `session` | 6 |
| `rakun-security` | api, web, data, client, session | `security`, `oauth2`, `ldap` | 13 |
| `rakun-cache` | api, web, actuator, session | `cache` | 7 + `fixtures/` |
| `rakun-websocket` | api, web, data, security | `websocket` | 6 |
| `rakun-app` | web, cache | `file_router`, `ssr`, `actions`, `navigation`, `static_gen`, `metadata_routes` | 13 + `fixtures/` |

`rakun-actuator-api`: dependency of 14 members (each naming `api`). The core already merged the
old `rakun-validation` (`config_check.bp`, decision 116).

## Starters (8) — `repository/rakun/starters/`

Manifest + re-exporting `src/root.bp`; `{ "workspace": true }` to every sibling (03r-r). Asserted
by `modules/rakun/test/starter_manifest_test.bp`, `version_set_test.bp`.

| Starter | Brings |
|---|---|
| `rakun-starter` | `rakun` (on disk also `rakun-logging`; 128 step 2 drops it) |
| `rakun-starter-web` | `rakun-starter`, `rakun-web` |
| `rakun-starter-data-sql` | `rakun-starter`, `rakun-data` |
| `rakun-starter-security` | `rakun-starter`, `rakun-security`, `rakun-session` |
| `rakun-starter-actuator` | `rakun-starter`, `rakun-actuator`, `rakun-metrics` |
| `rakun-starter-cache` | `rakun-starter`, `rakun-cache` |
| `rakun-starter-messaging` | `rakun-starter`, `rakun-messaging` |
| `rakun-starter-test` | `rakun-starter`, `rakun-test` — and `onze`, `onze-test` by path (`../../../onze/modules/<name>`), allow-listed by the starter lint; front 73 removes both |
| `rakun-starter-app` (to add, front 73) | `rakun-starter-web`, `rakun-app`, `rakun-cache` |

No `starters/test/`: the two core tests are the manifest cells.

## Examples (3) — `repository/rakun/examples/`

| Project | Manifest name | Depends on | Sources | Cell |
|---|---|---|---|---|
| `examples/rakun` | `rakun-example` | `rakun` | `main.bp`, `config.bp`, `posts.bp`, `users.bp` | erlang `build`; `botopink run` re-measured by 73 |
| `examples/rakun-container` | `rakun-container-example` | `rakun` | `main.bp` | erlang `build` |
| `examples/rakun-ssr` | `rakun-ssr-example` | `rakun`, `rakun-app` | `main.bp` | erlang `build` |

No example has a test file or `README.md`. The closed cut's seven projects: 03r-af.

## Front → directory ownership

Fronts own whole files; two in one member own disjoint files and tests. Shared member's
`botopink.json`, `src/root.bp`: lowest-numbered front; others append. 128 runs first, alone, owns
every member while open.

| Front | Owns | Does not touch |
|---|---|---|
| 128 | every member, the starters, the examples and the workspace manifest, for the nine moves and the imports they rewrite | what any file does; the frozen core files |
| 04 | `modules/rakun/**` except 74's, 11's and 17's files below; `test/fixtures/**` | `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (frozen) |
| 74 | `modules/rakun/src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `test/ssl_bundle_test.bp`, `test/tls_listener_test.bp` · `modules/rakun-web/src/tls.bp`, `test/tls_test.bp` | everything else in both members |
| 08 | `modules/rakun-data/**` except 09's, 15's and 65's files | `src/nosql/**`, `src/tx/**` and their tests; `botopink.json`, `src/root.bp` this milestone |
| 09 | `modules/rakun-data/src/nosql/**`, `src/nosql_host.bp`, `src/sidecars/rakun_nosql.erl`, `test/nosql/**`; appends to `botopink.json` and `src/root.bp` | `datasource.bp`, `sql/**`, `orm/**`, `migration/**` |
| 11 | `modules/rakun-actuator/**` · `modules/rakun/src/actuator_api/**`, `test/actuator_api/**`, `src/sidecars/rakun_actuator_api.erl` | the rest of the core |
| 12 | `modules/rakun-cache/**`, `modules/rakun-session/**` | `rakun-test` (imports the double) |
| 13 | `modules/rakun-client/**` except 93's files | `rakun-cache`; 93's files |
| 15 | `modules/rakun-messaging/**` except 91's and 92's (`src/stream/**` is 15's) · `modules/rakun-data/src/tx/**`, `test/tx/**` · `modules/rakun-scheduling/**` | 91's and 92's files; the rest of `rakun-data` |
| 17 | `modules/rakun/src/logging/**`, `test/logging/**`, `src/sidecars/rakun_logging.erl` · `modules/rakun-metrics/**` | the rest of the core |
| 19 | `modules/rakun-test/**`; under 03r-am (a) the doubles beside their module, named in 19's README | every other member |
| 22 | `modules/rakun-app/**` | — |
| 65 | `modules/rakun-web/**` except 74's two files · one line of `modules/rakun-data/src/devtools/devtools.bp` and `test/devtools/devtools_test.bp` | `tls.bp`, `test/tls_test.bp` |
| 73 | `starters/**`, `examples/**`, `modules/README.md` § starters and examples, `modules/rakun/test/starter_manifest_test.bp` | `modules/**` otherwise |
| 79 | `modules/rakun-security/**` | — |
| 81 | `modules/rakun-cli/src/release/**`, `test/release/**`, `src/sidecars/rakun_release.erl` | the rest of `rakun-cli` |
| 88 | `modules/rakun-cli/**` except 81's files | `rakun-client/src/ws/**` |
| 91 | `modules/rakun-messaging/src/pulsar/**`, `src/pulsar_host.bp`, `src/sidecars/rakun_pulsar.erl`, `test/pulsar/**`; under 03r-ad (a)/(b) `modules/rakun-pulsar/**` and the removal lines in `rakun-messaging/{botopink.json,src/root.bp}` after 15 lands | the rest of `rakun-messaging` |
| 92 | `modules/rakun-messaging/src/rsocket/**`, `test/rsocket/**`, `src/sidecars/rakun_rsocket.erl` | the rest of `rakun-messaging`; `rakun-websocket` |
| 93 | `modules/rakun-client/src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl`, its `modules/README.md` row, `AGENTS.md` § SOAP | the rest of `rakun-client`; `rakun-cli` |

`repository/rakun/AGENTS.md`, `modules/README.md` shared: each front edits its own section, in the
code's commit, never another's.
