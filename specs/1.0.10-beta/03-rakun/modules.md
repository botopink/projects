# rakun — the package cut

**Track:** B — rakun · **Repo:** `repository/rakun` · **Reference:** Spring Boot 4 starters (`/home/ericfillipe/develop/spring-boot-4/docs/02-desenvolvendo-com-spring-boot.md § Starters`) · Next.js server half · **Cross-cutting rules:** [`../02-packaging/`](../02-packaging/) · **Tests:** [`test-snap.md`](./test-snap.md) · [`test-snap-examples.md`](./test-snap-examples.md) · **Starting proposal:** [`../02-packaging/README.md § Per-library proposal`](../02-packaging/README.md#per-library-proposal--the-starting-point)

This is the decision document for `repository/rakun/modules/**`: the final submodule list, why each
one exists, the dependency graph between them, the target each compiles for, what `rakun-test`
exposes, which front delivers into which directory, and the example projects under
`repository/rakun/examples/**`. It overrides the per-front `**Owns:**` lines where they disagree; a front README that names a different directory is
read through the ownership table below.

## Inputs

| Source | What it says |
|---|---|
| `repository/rakun/modules/` | 13 scaffolds, every one a `botopink.json` (`targets: ["commonJS", "erlang"]`, `dependencies.rakun.path = "../../"`) plus a two-comment `src/root.bp` and an empty `test/`. `rakun-data` has empty `src/sql/` and `src/nosql/`; `rakun-messaging` has empty `src/amqp/` and `src/kafka/`. Zero lines of code. |
| `repository/rakun/src/` | The core today: `decorators.bp`, `http.bp`, `bootstrap.bp`, `runtime.bp`, `runtime.mjs`, `rakun.d.bp`, `root.bp`; `botopink.json` declares `"targets": ["commonJS"]` until front 04 makes it `["erlang"]` (decision 113). Five tests in `test/`. |
| `repository/rakun/examples/` | One project, `examples/rakun` (`main`, `users`, `posts`, `config`), commonJS. |
| Front 95 § 2 | "thirteen existing + one new": a core `modules/rakun/` that re-exports `src/`; every other submodule depends on it. |
| Front 73 | Eight starters over "twenty-two `rakun-*` modules". |
| Spring Boot 4 starters | `spring-boot-starter` (core, logging, YAML) · `-webmvc`/`-webflux` · `-websocket` · `-data-jpa`/`-data-jdbc`/`-jdbc`/`-r2dbc`/`-jooq` · `-data-mongodb`/`-data-redis` · `-security` · `-security-oauth2-client`/`-saml2` · `-session-jdbc`/`-session-data-redis` · `-actuator` · `-cache` · `-validation` · `-amqp`/`-kafka`/`-activemq`/`-artemis`/`-pulsar`/`-rsocket`/`-integration` · `-quartz` · `-mail` · `-hateoas` · `-webservices` · `-test`; plus `spring-boot-devtools`, the CLI and the build plugins as separate artefacts |

## Three facts that decide the cut

1. **The Next.js server half is its own module, and it imports no HTML library.** Fronts 22–25 and
   60–66 are the server half of the `app/` router: the route table, the page dispatch, actions, route
   handlers, static generation, slots, signals, i18n, metadata routes. Their READMEs name
   `repository/rakun/src/` — the core — but a Spring-style REST service has no use for any of it, so
   the app router leaves the core: **`rakun-app`**. Under decision 113 rakun does not build HTML:
   `rakun-app` depends on neither `jhonstart` nor `emilia`. The HTML of a page arrives as the chunks
   an opaque `PageRenderer` onze registers per route writes through rakun's `ChunkWriter` (front 23,
   decision 114), and jhonstart and rakun never import each other. The pure routing code both sides
   run — the matcher and the codecs of the wires the browser reads — is not a rakun module at all:
   it is the compiler-bundled library **`routing`** (`libs/routing`, decision 115), neutral like
   std, which rakun imports on erlang and jhonstart on commonJS.
2. **Two module-level cycles hide in the front dependencies.** 20 (websocket, in `rakun-web`) depends
   on 10 (security), and 10 depends on 07 (in `rakun-web`): `rakun-web ⇄ rakun-security`. 86 (in
   `rakun-messaging`) depends on 83 (`rakun-tx`), and 83 depends on 15 (`rakun-messaging`):
   `rakun-messaging ⇄ rakun-tx`. The first is cut by giving websocket its own module — which is also
   Spring's cut (`spring-boot-starter-websocket`). The second is cut by making 86's hand-off to the
   outbox a seam 83 implements (`Publisher` behavior registered into 86's dead-letter path), so the
   only package edge is `rakun-tx → rakun-messaging`.
3. **The actuator API/host split is load-bearing.** Eleven fronts register a health indicator, an
   info contributor or an endpoint. If registration lived in the host, `rakun-data` would depend on
   `rakun-actuator`, which depends on `rakun-security`, which depends on `rakun-web`, which depends on
   nothing of the sort. Front 11's Step 0 (`rakun-actuator-api`, no dependencies) is kept as a
   module in its own right.

## The cut

One row per directory the maps are written against. *Depends on* is the package edge
(`botopink.json` `dependencies`), derived from the unannotated `Depends on` lines after the three
corrections above plus four more (85→23 seam, 09→07 and 21→22 read-only, 07→76 soft); this column
is the normative graph and [§ The graph](#the-graph) draws it. `std` is implicit everywhere.

| Submodule | Target | Fronts | Depends on (packages) | Exposes | Spring Boot 4 |
|---|---|---|---|---|---|
| `rakun` | erlang | 04 · 05 · 06 · 62 · 72 · 74 | — | `App`, `#[bean]`/`#[configuration]`/`#[value]`, `rkDispatchHttp`, `context` (resolve, scopes, lifecycle, events, exit codes), `config`/`profiles`, `autoconfig` + the condition report, request context (`cookies()`/`headers()`/`after()`, memo), SSL bundles | `spring-boot` + `spring-boot-autoconfigure` (`spring-boot-starter`) |
| `rakun-actuator-api` | erlang | 11 (Step 0) | `rakun` | `Health`, `HealthIndicator`, `InfoContributor`, `Endpoint`, `Span`; `#[healthIndicator]`/`#[infoContributor]`/`#[endpoint]`; the three registration cells and their ETS sidecar | `spring-boot-actuator` (the API half) |
| `rakun-validation` | erlang, commonJS — boundary | 14 | `rakun` | constraint decorators, `#[validated]`, the violation report | `spring-boot-starter-validation` |
| `rakun-client` | erlang | 13 | `rakun` (12 soft) | `RestClient`/`WebClient` over one builder, `#[httpExchange]`, global + per-client settings, the SSRF address filter | `RestClient` / `WebClient` / HTTP service interfaces |
| `rakun-logging` | erlang | 17 | `rakun`, `rakun-actuator-api` | `logger`, levels and groups, structured formats, file output/rotation, correlation id, the `loggers` endpoint | `spring-boot-starter-logging` |
| `rakun-devtools` | erlang (dev only) | 80 | `rakun` | watcher + hot reload, dev property source, trigger file, remote shell | `spring-boot-devtools` |
| `rakun-web` | erlang | 07 · 65 · 82 | `rakun`, `rakun-actuator-api`, `rakun-validation` (76 soft) | `#[middleware]`/`#[matcher]`, `Chain`/`Next`, `CorsPolicy`, RFC 9457 problem details, static error pages, API versioning, graceful drain, URL rules (`basePath`, trailing slash, rewrites, redirects), static assets (ETag, fingerprint), `tls.bp` listener arm | `spring-boot-starter-webmvc` |
| `rakun-data` | erlang | 08 · 09 · 77 · 78 | `rakun`, `rakun-actuator-api`, `rakun-validation` | `DataSource` + pool, `SqlTemplate`, `#[repository]`, `#[transactional]` (`<Type>Tx` proxy), NoSQL stores (Redis, Mongo, Neo4j, Elasticsearch, Cassandra, Couchbase; Redis pub/sub), migrations + `ddl-auto` refusal, entities + typed query builder | `-data-jpa` / `-data-jdbc` / `-data-mongodb` / `-data-redis` / `-flyway` / `-liquibase` |
| `rakun-session` | erlang | 18 | `rakun`, `rakun-web`, `rakun-data`, `rakun-actuator-api` | session store (memory, SQL, Redis), cookie binding, the session filter | `spring-session-jdbc` / `spring-session-data-redis` |
| `rakun-scheduling` | erlang | 16 · 84 | `rakun`, `rakun-actuator-api`, `rakun-data` | `#[scheduled]`, the cron parser, the executor, the durable job store (`rakun_job*` tables) | `@Scheduled` / `spring-boot-starter-quartz` |
| `rakun-metrics` | erlang | 75 | `rakun`, `rakun-actuator-api`, `rakun-client`, `rakun-web` | meters over `:telemetry`, Prometheus exposition, common tags, `MeterFilter` analogue, traces/spans export, the request timer filter | Micrometer + `micrometer-registry-prometheus` + Micrometer Tracing |
| `rakun-security` | erlang | 10 · 79 | `rakun`, `rakun-web`, `rakun-data`, `rakun-client`, `rakun-session`, `rakun-actuator-api` | security context, authorities, JWT + Basic, method security, CSRF; OAuth2 client, OIDC login, SAML2, LDAP | `-security`, `-oauth2-client`, `-security-saml2`, `-data-ldap` |
| `rakun-cache` | erlang | 12 | `rakun`, `rakun-actuator-api`, `rakun-client`, `rakun-session` | `#[cacheable]`/`#[cacheEvict]`, `'use cache'`, tags, `revalidatePath`/`revalidateTag`, the private scope, memory + Redis stores | `spring-boot-starter-cache` |
| `rakun-messaging` | erlang | 15 · 86 · 90 | `rakun`, `rakun-actuator-api`, `rakun-metrics` (83 seam) | the listener registry and dispatch loop, AMQP + Kafka + RabbitMQ Streams + JMS (AMQP 1.0 / STOMP) arms, the publisher, retry / dead-letter / idempotency | `-amqp` / `-kafka` / `-activemq` / `-artemis` |
| `rakun-tx` | erlang | 83 | `rakun`, `rakun-data`, `rakun-messaging`, `rakun-scheduling` | outbox + relay, saga + compensations, two-phase commit; the `Publisher` seam 86 hands off to | JTA (`07-io.md § JTA`) |
| `rakun-actuator` | erlang | 11 (host) · 76 · 87 | `rakun`, `rakun-actuator-api`, `rakun-web`, `rakun-security`, `rakun-data` | the endpoint host (`/actuator/<id>`, TTL, CORS, path mapping), health/info aggregation, exposure + access levels, management listener, sanitization, probes + availability, audit events, HTTP exchanges | `spring-boot-starter-actuator` |
| `rakun-app` | erlang | 22 · 23 · 24 · 25 · 60 · 61 · 63 · 64 · 66 | `rakun`, `rakun-web`, `rakun-cache` | the route registry (table records + one opaque `PageRenderer` per page pattern) and the `app/` scan, the page dispatch that calls the renderer onze registered with a `ChunkWriter`, server actions (id, envelope, dispatch), route handlers, static generation, slots + intercepts, navigation signals, i18n negotiation, metadata file routes | none — the server half of the Next.js `app/` router |
| `rakun-hateoas` | erlang | 21 | `rakun`, `rakun-app` (ro) | `#[halResource]`, `Link`, `linkTo` over the route table | `spring-boot-starter-hateoas` |
| `rakun-websocket` | erlang | 20 | `rakun`, `rakun-web`, `rakun-security`, `rakun-actuator-api` | `#[wsEndpoint]`, upgrade on the HTTP path, sessions, broadcast | `spring-boot-starter-websocket` |
| `rakun-stream` | erlang | 89 | `rakun`, `rakun-messaging`, `rakun-data`, `rakun-actuator-api` | topology builder, sources/sinks/stages over GenStage, durable state, the graph endpoint | `spring-boot-starter-integration` / Kafka Streams |
| `rakun-pulsar` | erlang | 91 | `rakun`, `rakun-messaging`, `rakun-security`, `rakun-tx`, `rakun-client` | `#[pulsarListener]`/`#[pulsarReader]`, producer, admin arm, OAuth2 client-credentials, transactions | `spring-boot-starter-pulsar` |
| `rakun-rsocket` | erlang | 92 | `rakun`, `rakun-websocket`, `rakun-messaging` | `#[messageMapping]`, the four interaction models, the requester, TCP + WebSocket transports | `spring-boot-starter-rsocket` |
| `rakun-mail` | erlang | 85 | `rakun`, `rakun-actuator-api`, `rakun-tx` (23 seam) | `MailSender`, MIME builder, STARTTLS/implicit TLS through a bundle, templated bodies via the `Renderer` seam, the `mail` health indicator | `spring-boot-starter-mail` |
| `rakun-soap` | erlang | 93 | `rakun`, `rakun-client`, `rakun-web` | `WebServiceTemplate` analogue, envelope codec, a published endpoint, the schema reader `rakun soap:generate` uses | `spring-boot-starter-webservices` |
| `rakun-release` | erlang (build time) | 81 | `rakun`, `rakun-actuator` | OTP release + `sys.config`, `relup`, SBOM, container image, systemd unit, Kubernetes probe fragments | `bootJar` / `bootBuildImage`, `08-container-images.md`, `11 § Servico de SO` |
| `rakun-cli` | erlang (escript) | 88 | `rakun`, `rakun-release`, `rakun-devtools` (`rakun-soap` optional) | `rakun new / run --watch / build / inspect`, project templates | Spring Boot CLI (`12 § Spring Boot CLI`) |
| `rakun-test` | erlang | 19 | every module above, `testing.asserts`, `testing.snapshots` (test scope) | [§ What `rakun-test` exposes](#what-rakun-test-exposes) | `spring-boot-starter-test` |
| `starters/*` | none (manifests) | 73 | the modules each aggregates | [§ Starters](#starters-repositoryrakunstarters) | `spring-boot-starters/` |

## Verdicts

| Candidate | Origin | Verdict | Reason |
|---|---|---|---|
| `rakun` (core) | 95 § 2, new | **keep (create)** | DI, bootstrap, configuration, context, auto-configuration, request context, SSL bundles. `modules/rakun/` re-exports `src/` (95 Step 5); `src/` stays where the frozen files are. Depends on `std` only. |
| `rakun-app` | new | **split** from core | Fronts 22–25, 60–66. Reason 1 above. erlang. Depends on no HTML or CSS library: the page's markup is the output of the function onze hands front 23 (decision 113). |
| `rakun-web` | scaffold | **keep, slimmed** | 07 (chain, CORS, problem details, `middleware.bp`), 65 (`src/rules/**`), 82 (`src/static/**`). Loses websocket (reason 2). No dependency on `rakun-app`: 65 depends on 07 only. |
| `rakun-websocket` | new | **split** from `rakun-web` | Front 20. Reason 2; matches `spring-boot-starter-websocket`. 92 (rsocket) stands on it. |
| `rakun-data` | scaffold | **keep** | 08 `src/sql/**` + `datasource.bp`, 09 `src/nosql/**`, 77 `src/migration/**`, 78 `src/orm/**`. One directory per front, as the conflict rule says. **Not** 83: see `rakun-tx`. Must not depend on `rakun-web`; 09's "07" citation is read-only. |
| `rakun-tx` | ownership row | **keep, separate** | Front 83 depends on 15 (publisher), 16 (relay tick) and 77 — a `rakun-data/src/tx/**` placement would make the data layer depend on messaging and scheduling. Spring's JTA support is its own module too. |
| `rakun-security` | scaffold | **keep** | 10 core, 79 `src/oauth2/**`, `src/oidc/**`, `src/ldap/**`, `src/saml2/**`. Spring ships `-security`, `-security-oauth2-client`, `-security-saml2` as starters over one security module; the starter cut is 73's, not this one. |
| `rakun-session` | scaffold | **keep** | Front 18. 12's private scope and 79's flow state key on it; both would otherwise depend on `rakun-web` for a session id. |
| `rakun-validation` | scaffold | **keep** | Front 14. A submodule that declares `["erlang", "commonJS"]` (decision 113): the constraints the server enforces are mirrored in the browser. Depends on core only, so `rakun-data` (78) and `rakun-web` (07) can both consume it. |
| `rakun-cache` | scaffold | **keep** | Front 12: both entry points, `#[cacheable]` and `'use cache'`. Depends on `rakun-session` (private scope) and `rakun-client` (Redis transport), never on `rakun-app` — 60 consumes it, not the reverse. |
| `rakun-client` | scaffold | **keep** | Front 13, RestClient + WebClient over one builder. 12's dependency on it is what keeps 13 free of the cache. |
| `rakun-actuator-api` | 11 Step 0 | **keep (create)** | Reason 3. `Health`, `HealthIndicator`, `InfoContributor`, `Endpoint`, `Span`, the four decorators, the three registration cells, the sidecar that owns the ETS registries. No rakun dependency beyond core. |
| `rakun-actuator` | scaffold | **keep** | 11 host (`src/*.bp`), 76 (`exposure.bp`, `access.bp`, `management_listener.bp`, `probes.bp`, `sanitize.bp`, `availability.bp`), 87 (`src/audit/**`, `src/exchanges/**`). Depends on `rakun-security` (76) and `rakun-web` (87's recorder sits in the chain). |
| `rakun-metrics` | 75 ownership row | **keep, one name** | 75. The ownership row owns `modules/rakun-metrics/` and tests under `modules/rakun-observability/test/**` — one module, one name: `rakun-metrics`. Not merged into `rakun-actuator`: it depends on `rakun-client` (export) and ships a filter into `rakun-web`'s chain, neither of which the host needs. |
| `rakun-logging` | scaffold | **keep** | 17. Registers the `loggers` endpoint through `rakun-actuator-api`, not the host. |
| `rakun-messaging` | scaffold | **keep** | 15 (registry, `src/amqp/**`, `src/kafka/**`), 86 (`src/reliability/**`), 90 (`src/jms/**` — AMQP 1.0 and STOMP add no dependency 15 lacks). |
| `rakun-pulsar` | new | **split** from `rakun-messaging` | 91 depends on 79 (OAuth2 client-credentials), 83 (transactions) and 13 (admin HTTP). Inside `rakun-messaging` those edges would pull security, tx and client into every AMQP consumer. Spring: `spring-boot-starter-pulsar`. |
| `rakun-stream` | 89 ownership row | **keep, separate** | 89 depends on `rakun-data` (durable state) and 86. Spring Integration / Kafka Streams are their own starters. |
| `rakun-rsocket` | ownership row | **keep, separate** | 92 depends on `rakun-websocket` and `rakun-messaging`; nothing depends on it. |
| `rakun-scheduling` | scaffold | **keep** | 16 (in-VM), 84 (`src/jobstore/**`, adds a store behind 16's registry; depends on `rakun-data`). |
| `rakun-mail` | ownership row | **keep, separate** | 85. Its "23 (the render path for an HTML body)" edge is a `Renderer` seam `rakun-app` fills when present; `rakun-mail` depends on neither `rakun-app` nor any HTML library. Depends on `rakun-tx` for the outbox hand-off. |
| `rakun-hateoas` | scaffold | **keep** | 21. `linkTo` reads 22's route table; the edge `rakun-hateoas → rakun-app` is read-only and is the one place a Spring-side module reaches the Next side. |
| `rakun-soap` | `rakun-ws` (ownership row) | **rename** | 93. `ws` reads as websocket now that `rakun-websocket` exists. Its "88 (the CLI step that generates types)" edge is reversed: `rakun-cli` gets a `rakun soap:generate` command that depends on `rakun-soap`'s schema reader; a library does not depend on the CLI. |
| `rakun-i18n` | 64 ownership row | **merge** into `rakun-app/src/i18n/**` | A locale is a route segment first (`[locale]`), negotiation writes a redirect through 07's chain, and nothing outside the app router consumes it. One front with one consumer is a directory, not a package. |
| `rakun-devtools` | ownership row | **keep, separate** | 80. Dev-only; nothing at run time may depend on it. Spring ships it as a separate artefact for the same reason. |
| `rakun-release` | ownership row | **keep, separate** | 81. Build-time. Depends on `rakun-actuator` for the probe paths and the SBOM endpoint. |
| `rakun-cli` | ownership row | **keep, separate** | 88. Escript. Depends on `rakun-release`, `rakun-devtools`; `rakun-soap` as an optional command. |
| `rakun-test` | scaffold | **keep, widen** | 19. The `-test` submodule of the library: the snapshot helpers of every submodule live here, so it depends on all of them. Test-only edge; see *What `rakun-test` exposes*. Hosts `#[mock]` (95 § 5: "the first `-test` submodule that needs it"). |
| `rakun-starters` (as a module) | module column for 73 | **drop as a module** | Starters are manifests, not code. They live in `repository/rakun/starters/rakun-starter-*/` as 73 owns them — the Spring Boot repository keeps `spring-boot-starters/` beside the modules for the same reason. One starter is added: `rakun-starter-app`. |
| `rakun-observability` | module column for 75 | **drop (alias)** | Same module as `rakun-metrics`. |
| `rakun-core` | overview name | **drop (alias)** | The core is `rakun`. `import {…} from "rakun"` resolves through `modules/rakun/` (95 Step 5 acceptance). |

**Final count: 27 submodules** under `modules/` (13 scaffolds kept, 14 created), plus `starters/`.

## The graph

Edges are package dependencies (`botopink.json` `dependencies`), derived from the unannotated
`Depends on` lines of the front READMEs after the three corrections above (86→83 seam, 93→88
reversed, 85→23 seam). `(ro)` marks a read-only edge: the consumer imports a type or a table and
registers nothing back. `std` is below everything and omitted, and it is the only external edge:
no rakun module depends on `jhonstart`, `emilia` or `onze` (decision 113). The bundled library
`routing` (decision 115) sits beside `std` and is not drawn either: `rakun-app` (22, 60, 61) and
`rakun-web` (65) import it, and like `std` it is never listed in a manifest.

```
                                  rakun  (core: 04 05 06 62 72 74)
        ┌──────────┬──────────┬──────┴──────┬────────────┬─────────────┐
 rakun-actuator-api  rakun-validation  rakun-client  rakun-logging  rakun-devtools
   (11 § step 0)        (14)              (13)          (17)           (80)
        │                  │               │
        ├──────────────────┼───────────────┼─────────────────────────┐
        ▼                  ▼               │                         │
    rakun-web ◄────────── rakun-data ◄─────┼── (78→14)               │
  (07 65 82)           (08 09 77 78)       │                         │
        │   │                │   │         │                         │
        │   │   ┌────────────┘   │         │                         │
        │   ▼   ▼                ▼         ▼                         │
        │ rakun-session      rakun-scheduling    rakun-metrics ◄─────┘ (75: api, client, web-filter)
        │   (18)                (16 84)               │
        │   │                     │                   │
        ▼   ▼                     │                   ▼
   rakun-security ◄── rakun-client│           rakun-messaging  (15 86 90)
     (10 79)          (79)        │             │       │
        │  │                      │             │       └──────────────┐
        │  └──► rakun-cache (12) ◄┼── session   │                      │
        │             │           │             ▼                      ▼
        ▼             ▼           └──► rakun-tx (83) ◄── messaging   rakun-stream (89) ◄── data
  rakun-actuator   rakun-app                      │
  (11 host 76 87)  (22–25 60 61 63 64 66)       ├──► rakun-mail (85)
        │          ▲ (ro: 21 linkTo)            └──► rakun-pulsar (91) ◄── security, client
        │     rakun-hateoas (21)
        ▼
  rakun-release (81) ──► rakun-cli (88) ◄── devtools, (soap, optional)
                                            
  rakun-websocket (20) ◄── web, security       rakun-rsocket (92) ◄── websocket, messaging
  rakun-soap (93) ◄── client, web

  rakun-test (19) ◄── every module above (test-only edge)
  starters/rakun-starter-* ──► manifests over the modules; no code
```

The normative form is the *Depends on* column of [§ The cut](#the-cut); the drawing is a reading aid.

**Acyclic.** Every edge points at a row above it. A front whose README cites a front in a row below
its own module — 09→07, 21→22, 85→23, 86→83, 93→88, 07→76 — has that edge listed as `(ro)`, seam,
reversed or soft here, and the README's *Depends on* line is read through this table.

## Targets

| Submodule | Target | Why |
|---|---|---|
| `rakun`, `rakun-app`, `rakun-web`, `rakun-websocket`, `rakun-data`, `rakun-tx`, `rakun-security`, `rakun-session`, `rakun-cache`, `rakun-client`, `rakun-actuator-api`, `rakun-actuator`, `rakun-metrics`, `rakun-logging`, `rakun-messaging`, `rakun-pulsar`, `rakun-stream`, `rakun-rsocket`, `rakun-scheduling`, `rakun-mail`, `rakun-hateoas`, `rakun-soap`, `rakun-devtools`, `rakun-release`, `rakun-cli` | **erlang** | rakun is the service, and the service runs on BEAM (decision 113). `botopink.json` declares `"target": "erlang"`, `"targets": ["erlang"]`; the scaffolds' `["commonJS", "erlang"]` is corrected by the lowest-numbered front of each module. The core reaches it when front 04 closes: `runtime.mjs`, the node server and the Node forms in `src/runtime.bp` leave, so there is no second runtime with the same semantics to keep. |
| `rakun-validation` | **erlang, commonJS** — boundary | The constraints the server enforces are the constraints the client's form mirrors (14): a real client/server boundary. `"targets": ["erlang", "commonJS"]`. |
| `rakun-test` | **erlang** | It follows the packages it tests. |
| `starters/*` | none | Manifests. |

The workspace root `repository/rakun/botopink.json` declares `"targets": ["erlang", "commonJS"]` only
to admit the boundary member `rakun-validation`. erlang is first in every list and is the default target of
`botopink run` and `botopink test` in rakun.

## What `rakun-test` exposes

`modules/rakun-test/src/root.bp`, filled by front 19 and widened by every front that adds a
subject. Nothing here re-implements `testing.asserts` (95 § 5, rule 1).

| Group | Surface | From |
|---|---|---|
| Request doubles | `FakeRequest(method, path, params, queries, heads, payload) implement Request`, builders `fakeGet(path)`, `fakePost(path, contentType, body)`, `fakeWith(req, header, value)` | 19 § 1 |
| Response assertions | `expectStatus`, `expectBodyContains`, `expectBodyEquals`, `expectJsonField` | 19 § 2 |
| Dispatch | `MockMvc(basePath)`, `MockMvc.standalone()`, `perform(req) -> Response` — through `rkDispatchHttp`, no socket | 19 § 3 |
| Context control | `rkScanSource(text) -> i32` (scratch context from a source string), `resetContext()`, `resetSingletons()`, `contextSnapshot()` | 19 § 4 + [`test-snap.md`](./test-snap.md) § *The contract* |
| Broker double | `deliver(broker, destination, payload)`, `published(broker)`, `clearPublished()` | 19 § 5 |
| Boot | `bootAndExit(app: App) -> i32` | 19 § 6 |
| Mocking | `#[mock]` host runtime and the `#[mock]` + `#[bean]` pairing (the `@MockBean` equivalent); the assertion half is `testing.asserts` | 95 § 3 · 19 § 8 |
| Test clock and seed | `testClock("2026-01-01T00:00:00Z")`, `testSeed(n)` — installed by every snapshot helper so no `.snap` holds a wall-clock or random value | [`test-snap.md`](./test-snap.md) |
| Snapshot helpers | `assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>` — one per subject, 57 in all, listed with their rendering rules in [`test-snap.md § Helpers`](./test-snap.md#helpers-rakun-test-exposes) | this milestone |

The package edge `rakun-test → <every module>` is a test-only edge: `modules/<x>/test/*.bp` imports
`rakun-test`, and `rakun-test` imports `<x>`. The resolver must treat `<lib>-test` as a
test-scope dependency — the rule is cross-cutting and lives in
[`../02-packaging/`](../02-packaging/); this document only states that rakun needs it.

## Front → directory ownership

Every one of the 51 fronts owns exactly one directory. Where two fronts share a submodule, each
owns a sub-directory and the lowest-numbered front owns `botopink.json` and `src/root.bp` ([`../fronts.md`](../fronts.md)
rule). Sidecars are `src/sidecars/rakun_<name>.erl` in every module.

| Front | Submodule | Owns (`modules/<submodule>/…` unless stated) |
|---|---|---|
| 04 erlang-runtime | `rakun` | `repository/rakun/src/sidecars/rakun_runtime.erl`, `src/runtime.bp` (erlang block), `src/root.bp`, `botopink.json` (adds `erlang`), `modules/rakun/{botopink.json,src/root.bp}` |
| 05 config-profiles | `rakun` | `src/config.bp`, `src/profiles.bp`, `src/sidecars/rakun_config.erl` |
| 06 context-api | `rakun` | `src/context.bp`, `src/events.bp`, `src/lifecycle.bp`, `src/sidecars/rakun_context.erl` |
| 62 request-context | `rakun` | `src/request_context.bp`, `src/request_memo.bp` |
| 72 auto-configuration | `rakun` | `src/autoconfig.bp`, `src/conditions.bp`, `src/condition_report.bp`, `src/autoconfig_registry.bp`, `src/sidecars/rakun_autoconfig.erl` |
| 74 tls-ssl-bundles | `rakun` | `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl` · plus `modules/rakun-web/src/tls.bp` (the listener arm, read-only for 07) |
| 07 middleware | `rakun-web` | `src/{middleware,cors,error,filter,convention}.bp`, `botopink.json`, `src/root.bp` |
| 65 url-rules | `rakun-web` | `src/rules/**` (the boundary half — `canonicalize`, `clientHref`, the redirect-table codec — is `routing`'s `url_rules`, owned by `01-std/04-routing-lib`) |
| 82 static-assets | `rakun-web` | `src/static/**` |
| 20 websocket | `rakun-websocket` | `**` |
| 08 data-sql | `rakun-data` | `src/datasource.bp`, `src/sql/**`, `botopink.json`, `src/root.bp` |
| 09 data-nosql | `rakun-data` | `src/nosql/**` |
| 77 db-migrations | `rakun-data` | `src/migration/**` |
| 78 orm-entities | `rakun-data` | `src/orm/**` |
| 83 distributed-transactions | `rakun-tx` | `**` |
| 10 security-auth | `rakun-security` | `src/*.bp`, `botopink.json`, `src/root.bp` |
| 79 oauth2-sso | `rakun-security` | `src/oauth2/**`, `src/oidc/**`, `src/ldap/**`, `src/saml2/**` |
| 18 session | `rakun-session` | `**` |
| 14 validation | `rakun-validation` | `**` |
| 12 cache | `rakun-cache` | `**` |
| 13 http-clients | `rakun-client` | `**` |
| 11 actuator | `rakun-actuator` | `src/*.bp`, `src/sidecars/rakun_actuator.erl`, `botopink.json`, `src/root.bp` · **and** all of `modules/rakun-actuator-api/**` (Step 0) — the one front with two directories, because the API module exists only to be depended on before the host |
| 76 actuator-security-probes | `rakun-actuator` | `src/exposure.bp`, `src/access.bp`, `src/management_listener.bp`, `src/probes.bp`, `src/sanitize.bp`, `src/availability.bp` |
| 87 audit-and-exchanges | `rakun-actuator` | `src/audit/**`, `src/exchanges/**` |
| 75 observability-metrics | `rakun-metrics` | `**` |
| 17 logging | `rakun-logging` | `**` |
| 15 messaging | `rakun-messaging` | `src/*.bp`, `src/amqp/**`, `src/kafka/**`, `botopink.json`, `src/root.bp` |
| 86 messaging-reliability | `rakun-messaging` | `src/reliability/**` |
| 90 jms-brokers | `rakun-messaging` | `src/jms/**` |
| 91 pulsar | `rakun-pulsar` | `**` |
| 89 stream-pipelines | `rakun-stream` | `**` |
| 92 rsocket | `rakun-rsocket` | `**` |
| 16 scheduling | `rakun-scheduling` | `src/*.bp`, `botopink.json`, `src/root.bp` |
| 84 persistent-jobs | `rakun-scheduling` | `src/jobstore/**` |
| 85 mail | `rakun-mail` | `**` |
| 21 hateoas | `rakun-hateoas` | `**` |
| 93 soap-webservices | `rakun-soap` | `**` |
| 22 file-routing | `rakun-app` | `src/file_router.bp`, `src/route_table.bp`, `botopink.json`, `src/root.bp` (the matcher is imported from `routing`, Step 7) |
| 23 ssr-pipeline | `rakun-app` | `src/ssr.bp` (`ChunkWriter`, `PageRenderer`, `page`, the page dispatch; the render and the payload are jhonstart front 30's) |
| 24 server-actions | `rakun-app` | `src/actions.bp` |
| 25 route-handlers | `rakun-app` | `src/route_handler.bp` |
| 60 static-generation | `rakun-app` | `src/static_gen.bp`, `src/segment_config.bp` (the `k` codec is `routing`'s `route_kinds`) |
| 61 parallel-intercepting-routes | `rakun-app` | `src/route_slots.bp`, `src/route_intercept.bp` (the `z` codec is `routing`'s `slot_states`) |
| 63 navigation-signals | `rakun-app` | `src/navigation.bp` |
| 64 i18n-routing | `rakun-app` | `src/i18n/**` |
| 66 metadata-file-routes | `rakun-app` | `src/metadata_routes.bp` |
| 80 devtools | `rakun-devtools` | `**` |
| 81 packaging-release | `rakun-release` | `**` (incl. `templates/**`) |
| 88 cli | `rakun-cli` | `**` (incl. `templates/**`) |
| 73 starters | `starters/` | `repository/rakun/starters/rakun-starter-*/{botopink.json,src/root.bp}`, `starters/README.md`, `starters/test/**` |
| 19 test-utilities | `rakun-test` | `**` |

Tests: every front owns `modules/<submodule>/test/<subject>_test.bp` and the
`test/__snapshots__/<suite>/` beside it, per [`test-snap.md`](./test-snap.md).

## Starters (`repository/rakun/starters/`)

Front 73's eight, plus one. A starter is a `botopink.json` whose `dependencies` name modules and a
`src/root.bp` that re-exports them; it ships no code and no test but the manifest test.

| Starter | Brings | Spring |
|---|---|---|
| `rakun-starter` | `rakun`, `rakun-logging` | `spring-boot-starter` |
| `rakun-starter-web` | `rakun-starter`, `rakun-web`, `rakun-validation` | `-webmvc` |
| `rakun-starter-app` | `rakun-starter-web`, `rakun-app`, `rakun-cache` | (Next.js app router; consumed by `onze`) |
| `rakun-starter-data-sql` | `rakun-starter`, `rakun-data` | `-data-jpa` + `-jdbc` |
| `rakun-starter-security` | `rakun-starter`, `rakun-security`, `rakun-session` | `-security` |
| `rakun-starter-actuator` | `rakun-starter`, `rakun-actuator`, `rakun-metrics` | `-actuator` |
| `rakun-starter-cache` | `rakun-starter`, `rakun-cache` | `-cache` |
| `rakun-starter-messaging` | `rakun-starter`, `rakun-messaging` | `-amqp` + `-kafka` |
| `rakun-starter-test` | `rakun-starter`, `rakun-test` | `-test` |

## Examples (`repository/rakun/examples/`)

Eight projects. Every one of the 51 fronts is exercised by at least one; each project's own tests
are mapped in [`test-snap-examples.md`](./test-snap-examples.md).

| Project | Exercises | Depends on |
|---|---|---|
| `examples/rakun` (exists) | 04 · 05 · 06 — the sixty-second app; erlang, with 04 | `rakun` |
| `examples/rest-service` | 05 · 06 · 07 · 08 · 11 · 14 · 17 · 19 · 72 · 77 · 78 — users and orders, CRUD, validation, migrations, health | `rakun-starter-web`, `rakun-starter-data-sql`, `rakun-starter-actuator`, `rakun-starter-test` |
| `examples/secured-api` | 10 · 18 · 74 · 76 · 79 · 87 — JWT + OIDC login, sessions, HTTPS, guarded actuator, audit trail | `rakun-security`, `rakun-session`, `rakun-actuator`, `rakun-web` |
| `examples/blog-server` | 12 · 22 · 23 · 24 · 25 · 60 · 61 · 62 · 63 · 64 · 65 · 66 · 82 — a blog's routes answered by rakun alone: pages are `PageRenderer`s writing text, handlers answer JSON (decision 114). The blog rendered by jhonstart and styled by emilia is onze's (`repository/onze/examples/blog`, onze front 53) | `rakun-app`, `rakun-web`, `rakun-cache` |
| `examples/order-pipeline` | 15 · 16 · 83 · 84 · 85 · 86 · 89 · 90 — order events, outbox, saga, retry and dead-letter, nightly job, mail | `rakun-messaging`, `rakun-tx`, `rakun-stream`, `rakun-scheduling`, `rakun-mail`, `rakun-data` |
| `examples/observed-service` | 11 · 12 · 13 · 17 · 21 · 75 · 76 · 87 — a service that calls another, with metrics, traces, structured logs, HAL | `rakun-actuator`, `rakun-metrics`, `rakun-logging`, `rakun-cache`, `rakun-client`, `rakun-hateoas` |
| `examples/realtime-gateway` | 09 · 20 · 91 · 92 · 93 — chat over WebSocket and RSocket, a Pulsar feed, a SOAP bridge, a document store | `rakun-websocket`, `rakun-rsocket`, `rakun-pulsar`, `rakun-soap`, `rakun-data` |
| `examples/release-kit` | 72 · 73 · 80 · 81 · 88 — `rakun new`, `rakun run --watch`, the condition report, `rakun build` to an OTP release | `starters/*`, `rakun-devtools`, `rakun-release`, `rakun-cli` |

## Layout

```
repository/rakun/
├── botopink.json                  targets ["erlang","commonJS"] (commonJS only for rakun-validation); "rakun" = modules/rakun
├── src/                           the frozen four + runtime.bp + root.bp; core fronts append here
├── modules/
│   ├── rakun/                     core re-export (95 Step 5)
│   ├── rakun-actuator-api/
│   ├── rakun-validation/
│   ├── rakun-client/
│   ├── rakun-logging/
│   ├── rakun-devtools/
│   ├── rakun-web/
│   ├── rakun-data/
│   ├── rakun-session/
│   ├── rakun-scheduling/
│   ├── rakun-metrics/
│   ├── rakun-security/
│   ├── rakun-cache/
│   ├── rakun-messaging/
│   ├── rakun-tx/
│   ├── rakun-actuator/
│   ├── rakun-app/
│   ├── rakun-hateoas/
│   ├── rakun-websocket/
│   ├── rakun-stream/
│   ├── rakun-pulsar/
│   ├── rakun-rsocket/
│   ├── rakun-mail/
│   ├── rakun-soap/
│   ├── rakun-release/
│   ├── rakun-cli/
│   └── rakun-test/
├── starters/
│   ├── rakun-starter/ … rakun-starter-test/   (nine)
│   └── test/
└── examples/
    ├── rakun/  rest-service/  secured-api/  blog-server/
    └── order-pipeline/  observed-service/  realtime-gateway/  release-kit/
```

Each `modules/<name>/` is `botopink.json` + `src/root.bp` + `src/**` + `src/sidecars/rakun_<name>.erl`
+ `test/**` + `test/__snapshots__/**`, the shape the thirteen scaffolds already have.

## What this changes in the front READMEs

The rows below are the only places a README's `**Owns:**` or `**Depends on:**` line is read
differently, and each row's reason is in *Verdicts* or *The graph*.

| Front | README says | Read as |
|---|---|---|
| 22 · 23 · 24 · 25 · 60 · 61 · 63 · 66 | `repository/rakun/src/<file>.bp` | `modules/rakun-app/src/<file>.bp` |
| 64 | `modules/rakun-i18n/**` | `modules/rakun-app/src/i18n/**` |
| 20 | `modules/rakun-web/src/websocket/**` | `modules/rakun-websocket/**` |
| 75 | `modules/rakun-metrics/**`, tests in `rakun-observability` | `modules/rakun-metrics/**` for both |
| 93 | `modules/rakun-ws/**`; depends on 88 | `modules/rakun-soap/**`; 88 depends on 93 (optional) |
| 86 | depends on 83 | seam; 83 depends on 15 |
| 85 | depends on 23 | seam; no edge to `rakun-app` |
| 09 | depends on 07 | read-only; no edge `rakun-data → rakun-web` |
| 83 (conflict rule) | `modules/rakun-data/src/tx/**` | `modules/rakun-tx/**` (its own ownership row) |
| 73 | module `rakun-starters` | `repository/rakun/starters/` |
| 76 · 77 · 84 ([`../fronts.md § Conflict rules`](../fronts.md#conflict-rules), not the READMEs) | `src/security/**` + `src/probes/**`, `src/migrate/**`, `src/persistent/**` | the READMEs' own `Owns` lines: 76's six flat files, `src/migration/**`, `src/jobstore/**` |
| 23 | `**Depends on:**` names jhonstart fronts | no package edge: `modules/rakun-app/botopink.json` lists neither `jhonstart` nor `emilia`; the page HTML arrives through the `PageRenderer` onze registers (decisions 113, 114) |

## Reconsider

Things in the cut the maps are written against that this document would cut differently, or that
a later front should re-decide. None is applied here: the maps cite the names below as they stand.

| Item | As the maps have it | Reconsider | Verdict for now |
|---|---|---|---|
| `starters` as a map heading | `## 73-rakun-starters — \`starters\`` sits among the submodule headings and `assertStarter` is listed as a `starters` helper | It is `repository/rakun/starters/`, a directory of manifests beside `modules/`, not a package; a `modules/rakun-starters/` package would need `files` (mandatory, `02-packaging § 2`) and has none | keep the heading; read `starters` as the directory |
| `rakun-actuator-api` vs folding the API into core `rakun` | two packages | Every module already depends on core, so the API types could ride there and eleven manifests would lose one line. Against: the core would carry `Health`, `Endpoint`, `Span` and an ETS registry sidecar that a service without actuator never runs, and Spring keeps `spring-boot-actuator` apart from the autoconfigure module for the same reason | keep two |
| `rakun-tx` size | one front, three mechanisms, its own package | Small. Into `rakun-data` — rejected, pulls messaging and scheduling into the data layer; into `rakun-messaging` — rejected, the outbox writes through `rakun-data` and 86's hand-off would become a real cycle | keep; a `src/` of three files is a fine package |
| `rakun-metrics` vs `rakun-observability` | `rakun-metrics` (the ownership row's `modules/rakun-metrics/**` and sidecar `rakun_metrics.erl`) | 75 also ships traces (`assertTrace`); Spring's word is observability. If tracing grows a module of its own, `rakun-observability` is the umbrella name — and the maps' heading changes with it | keep `rakun-metrics` until 75 lands |
| `rakun-hateoas → rakun-app (ro)` | the one Spring-side edge to the Next side | `linkTo` needs only the route-table *type* and lookup. If 22's `route_table.bp` type moved into core `rakun` (with `rakun-app` filling it), the edge disappears and `rakun-hateoas` depends on core alone | decide when 21 lands; a type move is additive |
| Fifteen single-front packages | `rakun-rsocket`, `-pulsar`, `-stream`, `-mail`, `-soap`, `-hateoas`, `-devtools`, `-release`, `-cli`, `-websocket`, `-logging`, `-session`, `-validation`, `-cache`, `-client` | Spring's cut is equally fine; the cost is one manifest with `files` and one discovery cell each (`02-packaging § 5`). The only merge that reverses no edge is `rakun-release` + `rakun-cli` (both build-time, 88 → 81): a `rakun-tooling` if the count ever matters. `rakun-devtools` must stay alone — nothing at run time may depend on it | keep fifteen |
| Example project names | `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` | `02-packaging § 4` says `examples/<lib>-<thing>/` (`rakun-app`, `onze-blog`) so the flat listing across repositories reads. Only `examples/rakun` (existing) is exempt as "the existing project" | either prefix (`rakun-rest-service`, …) before the first one lands and re-point [`test-snap-examples.md`](./test-snap-examples.md), or record the exception in `02-packaging`; this document prefers the prefix |
| Scaffold `targets` | thirteen manifests say `["commonJS", "erlang"]` | 26 of 27 modules are erlang-only (decision 113); the lowest-numbered front of each module corrects the array, and front 04 the core's | as stated in [§ Targets](#targets) |
| `rakun-i18n` merged into `rakun-app` | `modules/rakun-app/src/i18n/**` | 64 is the only front whose ownership row named a package that has one consumer; if a non-app consumer appears (a locale-aware `rakun-web` rule, say), split it back out — the directory is already package-shaped | keep merged |

