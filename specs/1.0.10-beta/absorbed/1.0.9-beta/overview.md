# Specs — 1.0.9-beta: the ecosystem milestone

1.0.9-beta is the single front that replaces three drafts. [1.0.6-beta](../1.0.6-beta/overview.md)
proposed Spring Boot 4 parity for `rakun`, [1.0.7-beta](../1.0.7-beta/overview.md) proposed a Next.js
equivalent called `onze`, and [1.0.8-beta](../1.0.8-beta/overview.md) proposed Tailwind CSS parity
for `emilia`. They were written independently, and independently they do not hold: 1.0.7 needs a
cache layer that 1.0.6 also builds, a middleware chain that 1.0.6 also builds, and an `emilia`
attribute slot that 1.0.8 never mentions. Read together they are one program — a full-stack
ecosystem — cut three ways by accident of authorship. This milestone is that program, cut once.

**What changed in the merge.** Fifty-seven fronts became fifty-three. Five pairs were the same work
written twice and are now single fronts; one front is new. The rest carry over with their numbering
rebuilt so that a front number means the same thing in every document here.

| Merged into | Came from | Why they were the same work |
|---|---|---|
| [`07-rakun-middleware`](./07-rakun-middleware/README.md) | 1.0.6 F04 web-middleware + 1.0.7 F12 rakun-middleware | One filter chain. Next-style `middleware.bp` is a file convention over it, not a second mechanism. |
| [`12-rakun-cache`](./12-rakun-cache/README.md) | 1.0.6 F08 cache-abstraction + 1.0.7 F13 rakun-cache | One cache store and one key protocol. `#[cacheable]` and `'use cache'` are two entry points to it. |
| [`13-rakun-http-clients`](./13-rakun-http-clients/README.md) | 1.0.6 F09 rest-client + 1.0.6 F19 web-client-reactive | Same builder, same transport; the reactive one differs only by returning `@Future`. |
| [`15-rakun-messaging`](./15-rakun-messaging/README.md) | 1.0.6 F11 amqp + 1.0.6 F16 kafka | One listener registry and one dispatch loop, two brokers behind it. |
| [`48-emilia-attributes`](./48-emilia-attributes/README.md) | 1.0.7 F15 emilia-attributes + 1.0.7 F16 emilia-jhonstart-integration | The attribute slot is useless without the `html` DSL hook that reads it; splitting them split one commit in half. |
| [`01-std-lib-enablement`](./01-std-lib-enablement/README.md) | **new** | All three drafts assumed std primitives that std does not have. See below. |

**What is new, and why it comes first.** Every one of the three drafts quietly assumed the standard
library already does things it does not do. 1.0.6 assumes sockets, a connection pool, HMAC and a
clock. 1.0.7 assumes path manipulation, directory walking, a process spawner and HTML escaping.
1.0.8 assumes nothing — and that is why `emilia` is the only one of the three that could have been
built as drafted. Front [`01-std-lib-enablement`](./01-std-lib-enablement/README.md) is the audit of
that gap and the work to close it, and it is the keystone: it is the only front that every other
track depends on, and the only front whose absence turns the rest of the milestone into
`#[@external]` declarations with nothing behind them.

**Then the three references were read end to end, and fifty-three became ninety-five.** Each of the
three sources was audited section by section against the merged cut: 245 Spring Boot feature rows,
178 Next.js features, 304 Tailwind utilities and features. The result is not a longer wish list, it
is a measurement — and what it measured was that the merged cut covered the rendering spine and the
utility catalogue well, and missed the things underneath both.

| What the audit found missing | Fronts it produced |
|---|---|
| The request scope — `cookies()`, `headers()`, `after()`, `draftMode()`, per-request memoization. Eleven separate features bottomed out in it. | 62 |
| The client bundle. Five fronts were already js-target, and nothing computed the module graph, emitted a bundle, or wrote a hydration entry. `onze build` would have shipped a server with no browser half. | 68 |
| Conditional bean registration — the mechanism the whole Spring auto-configuration story rests on. | 72 |
| The theme system. Four copies of the spacing ladder already exist in `emilia.bp` today, and they have already drifted: `marginScaleX` emits `m-0.25`, which is not CSS. | 54 |
| The CSS cascade. `emilia` emits one nested class body, which cannot carry `@media` beside `@layer`, cannot hold `@keyframes` at all, and cannot express `group-*`, `peer-*`, `rtl`, `space-*` or `divide-*`. Roughly forty audit rows ended here. | 56 |
| Static generation, navigation signals, URL rules, the form half of server actions, the base reset, the escape hatches, and thirty-three more. | 55 · 57–61 · 63–67 · 69–71 · 73–93 |

Two ownership defects surfaced with them and are fixed here: the `Flex` token section, which already
exists in `tokens.bp`, had been assigned to no front at all, and `gap` had been assigned to two.
Front 37 now owns `Grid`, `Flex` and `Gap` together, which is also how Tailwind groups them.

What the audit did **not** do is pad. Features with no workable path on BEAM were deferred rather
than dressed up as fronts, and the reasoning for each is recorded in
[`deferred.md`](./deferred.md) — GraalVM native images, AOT class caches, CRaC, JNDI, the Servlet
API, JVM bytecode agents, Vercel hosting, the two JavaScript bundler plugin APIs, and the CSS
features that require reading a file the user wrote. Each row says why the mechanism does not exist
here, what would have to exist first, and when to revisit. Where a BEAM analogue did exist it was
specified instead of deferred: OTP releases for fat jars, hot code loading for DevTools restart,
`:telemetry` for JMX, supervised process pools for thread pools, sagas for JTA, ETS and Mnesia for
in-memory caches.

## How fronts are numbered

A front number is an identifier, not a position. Numbers are allocated in the order fronts are
admitted to the milestone and are never reassigned, because every other document here — the
ownership table, the conflict rules, the waves, the example headers — cites them. Fronts 01–53 were
allocated when the three drafts were merged; anything admitted afterwards is allocated from 54 up
and appears in its track's table below, out of numeric order. **Read the `**Track:**` line in a
front's README, not its number, to know where it belongs.**

## Tracks

| Track | Fronts | Repo | Delivers |
|---|---|---|---|
| **A — std** | 01–03 | `libs/std` | The primitives the libs stand on |
| **B — rakun** | 04–25 · 60–66 · 72–93 | `repository/rakun` | Spring Boot 4 parity, plus the server half of Next.js |
| **C — jhonstart** | 26–32 · 67 · 94 | `repository/jhonstart` | The React half of Next.js |
| **D — emilia** | 33–48 · 54–59 | `repository/emilia` | Tailwind CSS v4 parity, plus the attribute slot |
| **E — onze** | 49–53 · 68–71 | `repository/onze` (recreated: the mocking lib of that name is removed by 95) | The orchestrator, the CLI, and the app that proves it |
| **F — cross-cutting** | 95 | all repos | Ecosystem package restructure: the old `onze` mocking lib is removed and absorbed into `std/asserts`; the orchestrator drafted as `onze13` takes the name `onze`; every library gets `modules/` (core, `<name>-test`, domain submodules) and `examples/` |

### Track A — std (01–03)

| Front | Priority | Description |
|---|---|---|
| [`01-std-lib-enablement`](./01-std-lib-enablement/README.md) | **critical** | The gap audit: net, process, path, clock, random, regex, encoding, hashing, escaping — every primitive a downstream front assumes |
| [`02-std-async-primitives`](./02-std-async-primitives/README.md) | high | Parallel task combinators — `all`, `allSettled`, `race`, `timeout` — over unstarted tasks |
| [`03-std-content-hash`](./03-std-content-hash/README.md) | medium | Stable content hashes for cache keys, ETags and asset fingerprints |

### Track B — rakun (04–25 · 60–66 · 72–93)

| Front | Priority | Module | Description |
|---|---|---|---|
| [`04-rakun-erlang-runtime`](./04-rakun-erlang-runtime/README.md) | **critical** | rakun-core | The BEAM runtime: DI, router and HTTP server, the Erlang twin of `runtime.mjs` |
| [`05-rakun-config-profiles`](./05-rakun-config-profiles/README.md) | **critical** | rakun-core | Externalized configuration, profiles, `#[value]` binding |
| [`06-rakun-context-api`](./06-rakun-context-api/README.md) | high | rakun-core | Programmatic resolution, scopes, lifecycle hooks, application events |
| [`07-rakun-middleware`](./07-rakun-middleware/README.md) | high | rakun-web | Filter chain, CORS, RFC 9457 problem details, `middleware.bp` convention |
| [`08-rakun-data-sql`](./08-rakun-data-sql/README.md) | high | rakun-data | DataSource, pooling, `SqlTemplate`, `#[repository]`, `#[transactional]` |
| [`09-rakun-data-nosql`](./09-rakun-data-nosql/README.md) | low | rakun-data | Document and key-value stores |
| [`10-rakun-security-auth`](./10-rakun-security-auth/README.md) | high | rakun-security | Authentication, authorization, JWT, roles, method security |
| [`11-rakun-actuator`](./11-rakun-actuator/README.md) | medium | rakun-actuator | Health, info, metrics endpoints |
| [`12-rakun-cache`](./12-rakun-cache/README.md) | medium | rakun-cache | `#[cacheable]`/`#[cacheEvict]`, `'use cache'`, tags, revalidation |
| [`13-rakun-http-clients`](./13-rakun-http-clients/README.md) | medium | rakun-client | Blocking `RestClient` and future-returning `WebClient` over one builder |
| [`14-rakun-validation`](./14-rakun-validation/README.md) | medium | rakun-validation | Constraint decorators and the violation report |
| [`15-rakun-messaging`](./15-rakun-messaging/README.md) | medium | rakun-messaging | Listener registry with AMQP and Kafka behind it |
| [`16-rakun-scheduling`](./16-rakun-scheduling/README.md) | medium | rakun-scheduling | `#[scheduled]`, cron, fixed rate, task executor |
| [`17-rakun-logging`](./17-rakun-logging/README.md) | low | rakun-logging | Structured logging, levels, groups, correlation |
| [`18-rakun-session`](./18-rakun-session/README.md) | low | rakun-session | Session store and cookie binding |
| [`19-rakun-test-utilities`](./19-rakun-test-utilities/README.md) | low | rakun-test | Test slices, a `MockMvc` equivalent, context caching |
| [`20-rakun-websocket`](./20-rakun-websocket/README.md) | low | rakun-web | WebSocket upgrade, sessions, broadcast |
| [`21-rakun-hateoas`](./21-rakun-hateoas/README.md) | low | rakun-hateoas | HAL representation, link builders |
| [`22-rakun-file-routing`](./22-rakun-file-routing/README.md) | **critical** | rakun-core | The `app/` convention: segments, `[dynamic]`, `(groups)`, `@slots` |
| [`23-rakun-ssr-pipeline`](./23-rakun-ssr-pipeline/README.md) | **critical** | rakun-core | Page to HTML, layout nesting, the payload a client reconnects to |
| [`24-rakun-server-actions`](./24-rakun-server-actions/README.md) | **critical** | rakun-core | `'use server'`, form dispatch, revalidation on mutation |
| [`25-rakun-route-handlers`](./25-rakun-route-handlers/README.md) | high | rakun-core | `route.bp`: method exports as HTTP endpoints |


The Next.js server half and the Spring Boot features the first cut missed were admitted after a
coverage audit of both references; they carry numbers from 60 up.

| Front | Priority | Description |
|---|---|---|
| [`60-rakun-static-generation`](./60-rakun-static-generation/README.md) | **critical** | `generateStaticParams`, build-time prerender, `revalidate`, the static/dynamic decision |
| [`61-rakun-parallel-intercepting-routes`](./61-rakun-parallel-intercepting-routes/README.md) | high | `@slot` parallel routes and `(.)`/`(..)`/`(...)` intercepting routes |
| [`62-rakun-request-context`](./62-rakun-request-context/README.md) | **critical** | `cookies()`, `headers()`, `after()`, `connection()`, `draftMode()`, per-request memoization |
| [`63-rakun-navigation-signals`](./63-rakun-navigation-signals/README.md) | high | `redirect`, `permanentRedirect`, `notFound`, `forbidden`, `unauthorized` |
| [`64-rakun-i18n-routing`](./64-rakun-i18n-routing/README.md) | medium | Locale segments, negotiation, localized routing |
| [`65-rakun-url-rules`](./65-rakun-url-rules/README.md) | high | Matchers, rewrites, redirects, `basePath`, trailing slash |
| [`66-rakun-metadata-file-routes`](./66-rakun-metadata-file-routes/README.md) | medium | `sitemap`, `robots`, `manifest`, `opengraph-image` file conventions |
| [`72-rakun-auto-configuration`](./72-rakun-auto-configuration/README.md) | **critical** | Conditional registration, ordering, and the report of what was and was not applied |
| [`73-rakun-starters`](./73-rakun-starters/README.md) | high | Dependency bundles that bring a subsystem in configured |
| [`74-rakun-tls-ssl-bundles`](./74-rakun-tls-ssl-bundles/README.md) | high | TLS material and SSL bundles, consumed by the listener and the clients |
| [`75-rakun-observability-metrics`](./75-rakun-observability-metrics/README.md) | high | Metrics and tracing export over `:telemetry` |
| [`76-rakun-actuator-security-probes`](./76-rakun-actuator-security-probes/README.md) | high | Endpoint access control and Kubernetes readiness/liveness probes |
| [`77-rakun-db-migrations`](./77-rakun-db-migrations/README.md) | high | Schema migration, versioning, and the refusal to auto-generate under production |
| [`78-rakun-orm-entities`](./78-rakun-orm-entities/README.md) | high | Entity mapping, relations, and the query surface over them |
| [`79-rakun-oauth2-sso`](./79-rakun-oauth2-sso/README.md) | high | OAuth2, OIDC, SAML, LDAP |
| [`80-rakun-devtools`](./80-rakun-devtools/README.md) | high | Hot code loading, remote shell, dev-only endpoints |
| [`81-rakun-packaging-release`](./81-rakun-packaging-release/README.md) | high | OTP releases, `relup`, SBOM, container image, systemd unit |
| [`82-rakun-static-assets`](./82-rakun-static-assets/README.md) | medium | Static resource serving, caching headers, fingerprinting |
| [`83-rakun-distributed-transactions`](./83-rakun-distributed-transactions/README.md) | medium | Outbox, saga, two-phase commit — the JTA analogue |
| [`84-rakun-persistent-jobs`](./84-rakun-persistent-jobs/README.md) | medium | Durable, cluster-coordinated jobs |
| [`85-rakun-mail`](./85-rakun-mail/README.md) | medium | Mail over `gen_smtp`, templating, its own health indicator |
| [`86-rakun-messaging-reliability`](./86-rakun-messaging-reliability/README.md) | medium | Retry, dead-letter, idempotency |
| [`87-rakun-audit-and-exchanges`](./87-rakun-audit-and-exchanges/README.md) | medium | Audit events and HTTP exchange recording |
| [`88-rakun-cli`](./88-rakun-cli/README.md) | medium | rakun's own CLI — distinct from `50-onze-cli` |
| [`89-rakun-stream-pipelines`](./89-rakun-stream-pipelines/README.md) | low | GenStage pipelines: the Spring Integration and Kafka Streams analogue |
| [`90-rakun-jms-brokers`](./90-rakun-jms-brokers/README.md) | low | AMQP 1.0 and STOMP in place of JMS |
| [`91-rakun-pulsar`](./91-rakun-pulsar/README.md) | low | Apache Pulsar |
| [`92-rakun-rsocket`](./92-rakun-rsocket/README.md) | low | RSocket's four interaction models over BEAM processes |
| [`93-rakun-soap-webservices`](./93-rakun-soap-webservices/README.md) | low | A stated SOAP subset, and what it refuses |
### Track C — jhonstart (26–32 · 67 · 94)

| Front | Priority | Description |
|---|---|---|
| [`26-jhonstart-router`](./26-jhonstart-router/README.md) | **critical** | `useRouter`, pathname, params, push/replace — `router.d.bp` becomes real |
| [`27-jhonstart-link`](./27-jhonstart-link/README.md) | **critical** | `Link` with prefetch, scroll control, client navigation |
| [`28-jhonstart-server-components`](./28-jhonstart-server-components/README.md) | **critical** | Components that return `@Future<Element>`, data loading, request scope |
| [`29-jhonstart-client-directive`](./29-jhonstart-client-directive/README.md) | high | The server/client boundary and what may cross it |
| [`30-jhonstart-streaming`](./30-jhonstart-streaming/README.md) | high | Suspense boundaries, `loading.bp`, progressive flush |
| [`31-jhonstart-error-boundaries`](./31-jhonstart-error-boundaries/README.md) | high | `error.bp`, `not-found.bp`, `global-error.bp`, recovery |
| [`32-jhonstart-metadata`](./32-jhonstart-metadata/README.md) | medium | `generateMetadata`, OG images, the head it produces |


| [`67-jhonstart-forms`](./67-jhonstart-forms/README.md) | high | Form action binding, pending state, action result state, optimistic updates |
| [`94-jhonstart-element-surface`](./94-jhonstart-element-surface/README.md) | **critical** | The element constructors jhonstart does not have — `form`, `input`, `button`, `a`, `img`, `nav`, `html`, `head`, `body`… — which seven fronts were each about to duplicate |
### Track D — emilia (33–48 · 54–59)

| Front | Priority | Description |
|---|---|---|
| [`33-emilia-color-palette`](./33-emilia-color-palette/README.md) | **critical** | 26 families (17 chromatic, 9 neutral) × 11 shades, plus `black`/`white` and opacity |
| [`34-emilia-modifiers`](./34-emilia-modifiers/README.md) | **critical** | Breakpoints, dark mode, structural and state pseudo-classes, group/peer |
| [`35-emilia-spacing-sizing`](./35-emilia-spacing-sizing/README.md) | **critical** | The full spacing scale and every width/height/min/max form |
| [`36-emilia-layout`](./36-emilia-layout/README.md) | high | Display, position, overflow, visibility, z-index, float, object, aspect, columns |
| [`37-emilia-grid`](./37-emilia-grid/README.md) | high | Template columns and rows, spans, auto flow, gap, place/justify/align |
| [`38-emilia-typography`](./38-emilia-typography/README.md) | high | Tracking, leading, clamp, decoration, transform, wrap, list, content |
| [`39-emilia-backgrounds`](./39-emilia-backgrounds/README.md) | high | Attachment, clip, origin, position, repeat, size, gradients |
| [`40-emilia-borders`](./40-emilia-borders/README.md) | high | Radius, width, style, divide, outline, ring |
| [`41-emilia-effects`](./41-emilia-effects/README.md) | high | Box and text shadow, opacity, blend modes, masks |
| [`42-emilia-filters`](./42-emilia-filters/README.md) | medium | Filter and backdrop-filter in full |
| [`43-emilia-tables`](./43-emilia-tables/README.md) | low | Collapse, spacing, layout, caption side |
| [`44-emilia-transitions`](./44-emilia-transitions/README.md) | high | Property, duration, timing, delay, behavior, animation |
| [`45-emilia-transforms`](./45-emilia-transforms/README.md) | medium | Rotate, scale, skew, translate, origin, perspective, 3-D |
| [`46-emilia-interactivity`](./46-emilia-interactivity/README.md) | medium | Cursor, pointer events, resize, scroll, touch, select, accent, caret |
| [`47-emilia-svg-accessibility`](./47-emilia-svg-accessibility/README.md) | low | Fill, stroke, `sr-only`, forced colour adjust |
| [`48-emilia-attributes`](./48-emilia-attributes/README.md) | high | The attribute slot and the `html` DSL hook that consumes it |


The CSS-authored half of Tailwind — the theme, the reset, the cascade, the escape hatches — was
unowned by the first cut. A coverage audit found it and these six fronts close it.

| Front | Priority | Description |
|---|---|---|
| [`54-emilia-theme`](./54-emilia-theme/README.md) | **critical** | The theme record, `spacing(n)`, `theme(...)`, theme threading, dark-mode strategy |
| [`55-emilia-preflight`](./55-emilia-preflight/README.md) | high | The base reset, in full, plus its opt-out |
| [`56-emilia-cascade-and-output`](./56-emilia-cascade-and-output/README.md) | high | The rule model: at-rule hoisting, ancestor and sibling selectors, layers, precedence |
| [`57-emilia-escape-hatches`](./57-emilia-escape-hatches/README.md) | high | Arbitrary values, properties, variants and breakpoints — and the refusal that keeps them safe |
| [`58-emilia-container-queries`](./58-emilia-container-queries/README.md) | medium | Container type, the size variants, named containers |
| [`59-emilia-custom-utilities-and-variants`](./59-emilia-custom-utilities-and-variants/README.md) | medium | The `@utility`, `@apply` and `@custom-variant` equivalents, as functions over `Token[]` |
### Track E — onze (49–53 · 68–71)

| Front | Priority | Description |
|---|---|---|
| [`49-onze-stand-up`](./49-onze-stand-up/README.md) | **critical** | The new repository: manifest, module tree, shared types, integration layer |
| [`50-onze-cli`](./50-onze-cli/README.md) | medium | `create`, `dev`, `build`, `start` |
| [`51-onze-image`](./51-onze-image/README.md) | low | The `Image` component and the optimizer behind it |
| [`52-onze-font`](./52-onze-font/README.md) | low | Font loading without layout shift |
| [`53-onze-example-app`](./53-onze-example-app/README.md) | medium | The blog that exercises every front above |


| [`68-onze-client-bundle`](./68-onze-client-bundle/README.md) | **critical** | The `'use client'` module graph, the browser bundle, the hydration entry, the secret-leak refusal |
| [`69-onze-styling-pipeline`](./69-onze-styling-pipeline/README.md) | medium | Where `emilia.flush()` output is collected and inserted during the server render |
| [`70-onze-image-response`](./70-onze-image-response/README.md) | low | Programmatic OG image generation |
| [`71-onze-release-packaging`](./71-onze-release-packaging/README.md) | medium | Self-hosting: OTP release, container image, standalone output |

### Track F — cross-cutting (95)

| Front | Priority | Description |
|---|---|---|
| [`95-ecosystem-package-restructure`](./95-ecosystem-package-restructure/README.md) | high | Removes the old `onze` mocking lib (100 % of its assertions into `std/asserts`); the orchestrator drafted as `onze13` takes the name `onze`; every library gets `modules/` + `examples/` and a `<name>-test` submodule |
## Order

The dependency graph has one root. Nothing in tracks B, C or E can be tested before `01` lands,
because every one of them bottoms out in a socket, a clock, a path or a hash. Track D is the
exception and may start on day one.

```
Wave 0 — nothing blocks these
  01-std-lib-enablement ──────────────┐
  02-std-async-primitives             │  (02 and 03 need nothing from 01, but
  03-std-content-hash                 │   01 lands last: its `root.bp` commit
  95-ecosystem-package-restructure    │   carries their exports; 95's std/asserts
  54-emilia-theme                     │   half is wave 0, package moves are wave 1)
  56-emilia-cascade-and-output        │  (54 and 56 come before 33/34/35:
  33-emilia-color-palette             │   the palette, the modifiers and the
  34-emilia-modifiers                 │   scale all emit through them)
  35-emilia-spacing-sizing            │
  49-onze-stand-up                  │
                                      │
Wave 1 — the foundations              ▼
  04-rakun-erlang-runtime ────┐   36 · 37 · 38 · 39 · 40 · 41 · 42 · 43 · 44 · 45 · 46 · 47
  05-rakun-config-profiles ───┤   55 · 57 · 58 · 59   (all of track D, in parallel)
  22-rakun-file-routing ──────┤
  26-jhonstart-router ────────┤
  72-rakun-auto-configuration ┘
                              │
Wave 2 — the services         ▼
  06-rakun-context-api ──► 07 · 08 · 11 · 12 · 13 · 14 · 15 · 16 · 17 · 19 · 21
  06 + 72 ──► 73 · 74 · 75 · 80 · 82 · 85 · 88
  22 ──► 23-rakun-ssr-pipeline · 61 · 65
  26 ──► 27-jhonstart-link · 28-jhonstart-server-components
  04 ──► 62-rakun-request-context · 63-rakun-navigation-signals
                              │
Wave 3 — what stands on them  ▼
  07 ──► 09 · 10 · 18 · 20 · 76 · 87       23 ──► 24 · 25 · 66 · 69
  28 ──► 29 · 30 · 31 · 32                 08 ──► 77 · 78 · 83
  62 ──► 60-rakun-static-generation · 64   12 ──► 86
  29 ──► 68-onze-client-bundle           16 ──► 84
  10 ──► 79                                15 ──► 89 · 90 · 91 · 92 · 93
  26 + 48 ──► 50 · 51 · 52 · 70 · 71 · 81
                              │
Wave 4 — the last dependents  ▼
  24 + 68 ──► 67-jhonstart-forms
                              │
Wave 5 — the proof            ▼
  53-onze-example-app
```

**Why `04-rakun-erlang-runtime` still comes before the rest of track B.** The current `runtime.mjs`
is Node-only and every `rk*` host cell reaches for `@External.Node`. Until the BEAM twin exists, a
front can claim dual-target coverage and never be contradicted, because half its tests cannot run.
Front 04 makes that claim falsifiable, which is the only reason it is worth making.

**Why `22-rakun-file-routing` comes before `23-rakun-ssr-pipeline`.** The pipeline renders a route;
without the router there is no route to render, only a function someone calls by hand.

**Why track D can start immediately.** `emilia` emits CSS from a `Token` enum. It needs no socket,
no clock and no filesystem, and its only contact with the rest of the milestone is front 48.

**Why `62-rakun-request-context` and `68-onze-client-bundle` are on the critical path.** The audit
traced eleven features into 62 and five js-target fronts into 68. Without 62 there is no per-request
scope, so nothing that reads a cookie or a header can be written, and the static/dynamic decision in
60 has no input. Without 68 the client-target fronts compile to nothing that reaches a browser. The
critical path is therefore `01 → 04 · 22 · 26 → 06 · 23 · 28 · 62 → 24 · 60 · 63 · 68 → 67 → 53` —
eight fronts deep, not six.

## Rules

- **One repo per front.** A front owns files in exactly one repository. Front 48 is the single
  documented exception, and it says so in its own header.
- **The compiler knows none of this.** `rakun`, `jhonstart`, `emilia` and `onze` are libraries.
  Every mechanism here is plain botopink plus `@Decl`, comptime, `@emit` and `#[@external]`. A front
  that needs a compiler change does not get one — it files a language gap instead, in the form the
  front README prescribes.
- **Target is assigned, not chosen.** Erlang is the server, JavaScript is the client, and the
  section *Which target runs what* below says which one a given front compiles for. A front does
  not ship a second target "for completeness".
- **Reuse std.** A front that needs a primitive asks front 01 for it. It does not grow a private
  copy, and it does not reach for `@External.Node` when std could carry it.
- **Additive only, with one named exception.** No existing `emilia` token is renamed, no existing
  `rakun` decorator changes shape, no existing `jhonstart` signature moves. Everything here is new
  surface. The exception is a token whose current output is **not valid CSS** — `shadowToCss` emits
  `box-shadow:sm`, and `marginScaleX` emits `m-0.25`. Fixing those changes shipped behaviour under
  an unchanged token name, which is a correction rather than a breaking change, and the front making
  it says so in its README and covers the old and new output in one test. The same exception
  covers **output that is not byte-equal to Tailwind** — track D's stated goal is byte-equality,
  and `emilia` today emits `:hover` where Tailwind emits `@media (hover: hover) { &:hover }`, a
  `768px` breakpoint where Tailwind emits `48rem`, and literal font stacks where Tailwind emits
  `var(--font-sans)`. Token *names* and *signatures* are the compatibility surface; emitted CSS is
  not, for this milestone. A front changing existing output names the assertions in
  `repository/emilia/src/emilia.bp` it breaks (34: `:435-461`, `:505-511`; 38: `:411-413`,
  `:482-487`; 35: the `padding-x:`/`margin-y:`/`m-1` corrections) and updates them in the same
  commit.
- **Examples are code, not prose.** Every front carries `examples/*.bp` that compile against the
  syntax that exists today. Where an example needs syntax that does not exist yet, the file marks
  the line `// LANGUAGE GAP:` and the README repeats it under *Language gaps*. An example that
  silently invents syntax is worse than no example.

## Which target runs what

This is the architectural decision the milestone is built on, and it is not negotiable per front.

**Erlang/BEAM is the server.** Everything that runs while a request is in flight compiles to BEAM:
the DI container, configuration, the router, the middleware chain, SQL and NoSQL access, the cache,
sessions, security, scheduling, messaging, the actuator — and, critically, the render half that
Next.js calls server rendering. Server components, layout nesting, the SSR pipeline, server actions
and route handlers all execute on BEAM. This is what the whole track B ordering is for: front
[`04-rakun-erlang-runtime`](./04-rakun-erlang-runtime/README.md) exists because without a BEAM
runtime the server does not exist, and every other server front would be a Node program wearing a
botopink hat.

**JavaScript is the client.** Everything that runs in the browser compiles to commonJS: hydration,
stateful hooks, event handlers, client-side navigation in `Link`, client components behind the
`'use client'` boundary, lazy image loading, font swap. These never compile to BEAM and their
fronts do not pretend otherwise.

**The boundary is the small part, and it is where the bugs live.** Three things cross it and
therefore build for both: the payload format that the server serializes and the client reconnects
to, the route table that the server matches and the client prefetches against, and the validation
constraints that the server enforces and the client mirrors. A front that touches the boundary says
so in its header and tests the round trip, not each side alone.

**Where `emilia` sits.** Nowhere on that axis. `emilia` runs at comptime and emits a CSS string; by
the time either target exists the work is done. Track D is target-independent, which is the second
reason it can run from day one.

| Track | Fronts | Target |
|---|---|---|
| A — std | 01–03 | both — std is the floor under both halves, except `net`, which is server-only and whose commonJS cells are explicit refusals |
| B — rakun | 04–25 | **erlang**, except the payload/route-table boundary in 22–24 |
| C — jhonstart | 28 · 32 | **erlang** — these render on the server |
| C — jhonstart | 26 · 30 · 31 · 94 | **both — boundary** — 26's navigation cell is the one dual-target cell in an erlang router; 30 produces chunks on BEAM and consumes them in the browser; 31 catches on both sides; 94's constructors must produce the identical `Element` on both |
| C — jhonstart | 27 · 29 · 67 | **js** — these run in the browser |
| D — emilia | 33–48 · 54–59 | comptime; 48 emits attributes both halves read |
| E — onze | 49–53 · 68–71 | orchestrator: serves from BEAM, ships a JS bundle. 68 and 71 are both-target build work; 69 and 70 are erlang |
| F — cross-cutting | 95 | both — std/asserts runs on every backend; each `-test` submodule runs on its library's assigned target |

## Mapping the three sources

| Upstream | Reference | Front |
|---|---|---|
| Spring Boot 4 | `/home/ericfillipe/develop/spring-boot-4/docs/` | 04–21 · 72–93 |
| Next.js | `/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md` | 22–32 · 49–53 · 60–71 |
| Tailwind CSS v4 | `/home/ericfillipe/develop/tailwindcss/TAILWIND_CSS_DOCS.md` | 33–48 · 54–59 |

Each front README cites the exact section of its reference that it implements, and each example file
carries the upstream URL for the feature it demonstrates. A front that cannot point at its upstream
section is a front nobody asked for.
