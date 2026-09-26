# Unification — where every 1.0.6 / 1.0.7 / 1.0.8 / 1.0.9 document lives in 1.0.10-beta

1.0.9-beta absorbed three drafts (1.0.6 rakun, 1.0.7 onze13, 1.0.8 emilia) into one milestone of
ninety-five fronts; 1.0.10-beta cuts that milestone by **library** — `01-std/`, `03-rakun/`,
`04-jhonstart/`, `05-emilia/`, `06-onze/` — beside the compiler carry-over
(`00-compiler-carry-over/`) and the package restructure (`02-packaging/`), and keeps every front
number. The earlier milestone directories are deleted (decision 68); this file maps their documents
and their front numbers to where the content is now. The per-front map is each library's own
`unification.md`: [`03-rakun/unification.md`](./03-rakun/unification.md),
[`04-jhonstart/unification.md`](./04-jhonstart/unification.md),
[`05-emilia/unification.md`](./05-emilia/unification.md),
[`06-onze/unification.md`](./06-onze/unification.md).

## Top-level documents

| Earlier document | Where it is now |
|---|---|
| 1.0.9 `overview.md` (tracks, order, rules, *Which target runs what*) | [`overview.md`](./overview.md); the track tables in each library's `README.md`; the blocking order and target table in [`fronts.md`](./fronts.md) |
| 1.0.9 `fronts.md` (ownership, shared-file rules, frozen files, waves, exit gate) | [`fronts.md`](./fronts.md); each library's `modules.md` for its own rows |
| 1.0.9 `contracts.md` (contracts 1–6a) | [`contracts.md`](./contracts.md), plus contract 7 (tests and snapshots) and 1.0.8's dispatcher rules under 4a |
| 1.0.9 `deferred.md` | [`deferred.md`](./deferred.md) |
| 1.0.9 `language-gaps.md` | [`language-gaps.md`](./language-gaps.md) |
| 1.0.9 `tracks/README.md` (the per-track file plan and the test contract) | the layout `0N-<lib>/{README,modules,unification,test-snap,test-snap-examples}.md`; the test contract is [`contracts.md` § 7](./contracts.md#7--test-and-snapshot-contract--owned-by-01-std-consumed-by-every--test-submodule) |
| 1.0.9 front 96 `src-builtin-and-snapshots` | [`01-std/src-builtin.md`](./01-std/src-builtin.md) · [`01-std/snapshots.md`](./01-std/snapshots.md) · [`01-std/asserts-api.md`](./01-std/asserts-api.md) |
| 1.0.9 `95-ecosystem-package-restructure/` | [`02-packaging/95-ecosystem-package-restructure/`](./02-packaging/95-ecosystem-package-restructure/README.md); its rules generalised in [`02-packaging/README.md`](./02-packaging/README.md) |
| 1.0.8 `overview.md` (fronts F01–F15, rules, the emilia → Tailwind coverage) | fronts 33–47 under `05-emilia/`; exhaustive dispatch and naming in [`contracts.md` § 4a](./contracts.md); the coverage in [`05-emilia/reference-coverage.md`](./05-emilia/reference-coverage.md) |
| 1.0.8 `tailwind-mapping.md` | [`05-emilia/tailwind-mapping.md`](./05-emilia/tailwind-mapping.md) |
| 1.0.7 `overview.md` (fronts F01–F22, architecture, Next.js → library map, project layout) | the fronts under `06-onze/`, `04-jhonstart/`, `03-rakun/`, `05-emilia/48`, `01-std/02`–`03`; *convention over configuration* and the Next.js → library map in [`02-packaging/README.md`](./02-packaging/README.md); the architecture in [`06-onze/README.md`](./06-onze/README.md) |
| 1.0.7 `fronts.md` (cross-repo coordination) | interface contracts in [`contracts.md`](./contracts.md); the dependency direction in [`02-packaging/README.md`](./02-packaging/README.md) |
| 1.0.7 `examples-bp.md` | the per-front `examples/*.bp` |
| 1.0.6 `overview.md` (fronts F01–F20, module tree, Spring Boot 4 → rakun map) | fronts 04–21 under `03-rakun/`; the module tree and the starter map in [`02-packaging/README.md`](./02-packaging/README.md) and [`03-rakun/modules.md`](./03-rakun/modules.md) |
| 1.0.6 `examples/01…10-*-example.bp` | the per-front `examples/` of fronts 04–14 under `03-rakun/` |
| *Rules for a front* (1.0.6 / 1.0.7 / 1.0.8 `fronts.md`) | [`fronts.md`](./fronts.md) |

## Front-number map — 01 … 96

A front number is an identifier and never moves. Paths are relative to `specs/1.0.10-beta/`.

| # | 1.0.9 directory | 1.0.10 path | Came from |
|---|---|---|---|
| 01 | `01-std-lib-enablement/` | `01-std/01-std-lib-enablement/` | new in 1.0.9 |
| 02 | `02-std-async-primitives/` | `01-std/02-std-async-primitives/` | 1.0.7 F17 |
| 03 | `03-std-content-hash/` | `01-std/03-std-content-hash/` | 1.0.7 F18 |
| 04 | `04-rakun-erlang-runtime/` | `03-rakun/04-rakun-erlang-runtime/` | 1.0.6 F01 |
| 05 | `05-rakun-config-profiles/` | `03-rakun/05-rakun-config-profiles/` | 1.0.6 F02 |
| 06 | `06-rakun-context-api/` | `03-rakun/06-rakun-context-api/` | 1.0.6 F03 |
| 07 | `07-rakun-middleware/` | `03-rakun/07-rakun-middleware/` | 1.0.6 F04 + 1.0.7 F12 |
| 08 | `08-rakun-data-sql/` | `03-rakun/08-rakun-data-sql/` | 1.0.6 F05 |
| 09 | `09-rakun-data-nosql/` | `03-rakun/09-rakun-data-nosql/` | 1.0.6 F17 |
| 10 | `10-rakun-security-auth/` | `03-rakun/10-rakun-security-auth/` | 1.0.6 F06 |
| 11 | `11-rakun-actuator/` | `03-rakun/11-rakun-actuator/` | 1.0.6 F07 |
| 12 | `12-rakun-cache/` | `03-rakun/12-rakun-cache/` | 1.0.6 F08 + 1.0.7 F13 |
| 13 | `13-rakun-http-clients/` | `03-rakun/13-rakun-http-clients/` | 1.0.6 F09 + F19 |
| 14 | `14-rakun-validation/` | `03-rakun/14-rakun-validation/` | 1.0.6 F10 |
| 15 | `15-rakun-messaging/` | `03-rakun/15-rakun-messaging/` | 1.0.6 F11 + F16 |
| 16 | `16-rakun-scheduling/` | `03-rakun/16-rakun-scheduling/` | 1.0.6 F12 |
| 17 | `17-rakun-logging/` | `03-rakun/17-rakun-logging/` | 1.0.6 F13 |
| 18 | `18-rakun-session/` | `03-rakun/18-rakun-session/` | 1.0.6 F14 |
| 19 | `19-rakun-test-utilities/` | `03-rakun/19-rakun-test-utilities/` | 1.0.6 F15 |
| 20 | `20-rakun-websocket/` | `03-rakun/20-rakun-websocket/` | 1.0.6 F18 |
| 21 | `21-rakun-hateoas/` | `03-rakun/21-rakun-hateoas/` | 1.0.6 F20 |
| 22 | `22-rakun-file-routing/` | `03-rakun/22-rakun-file-routing/` | 1.0.7 F14 |
| 23 | `23-rakun-ssr-pipeline/` | `03-rakun/23-rakun-ssr-pipeline/` | 1.0.7 F09 |
| 24 | `24-rakun-server-actions/` | `03-rakun/24-rakun-server-actions/` | 1.0.7 F10 |
| 25 | `25-rakun-route-handlers/` | `03-rakun/25-rakun-route-handlers/` | 1.0.7 F11 |
| 26 | `26-jhonstart-router/` | `04-jhonstart/26-jhonstart-router/` | 1.0.7 F02 |
| 27 | `27-jhonstart-link/` | `04-jhonstart/27-jhonstart-link/` | 1.0.7 F03 |
| 28 | `28-jhonstart-server-components/` | `04-jhonstart/28-jhonstart-server-components/` | 1.0.7 F04 |
| 29 | `29-jhonstart-client-directive/` | `04-jhonstart/29-jhonstart-client-directive/` | 1.0.7 F05 |
| 30 | `30-jhonstart-streaming/` | `04-jhonstart/30-jhonstart-streaming/` | 1.0.7 F06 |
| 31 | `31-jhonstart-error-boundaries/` | `04-jhonstart/31-jhonstart-error-boundaries/` | 1.0.7 F07 |
| 32 | `32-jhonstart-metadata/` | `04-jhonstart/32-jhonstart-metadata/` | 1.0.7 F08 |
| 33 | `33-emilia-color-palette/` | `05-emilia/33-emilia-color-palette/` | 1.0.8 F14 |
| 34 | `34-emilia-modifiers/` | `05-emilia/34-emilia-modifiers/` | 1.0.8 F15 |
| 35 | `35-emilia-spacing-sizing/` | `05-emilia/35-emilia-spacing-sizing/` | 1.0.8 F03 |
| 36 | `36-emilia-layout/` | `05-emilia/36-emilia-layout/` | 1.0.8 F01 |
| 37 | `37-emilia-grid/` | `05-emilia/37-emilia-grid/` | 1.0.8 F02 (+ the unowned `Flex` section and the double-owned `gap`) |
| 38 | `38-emilia-typography/` | `05-emilia/38-emilia-typography/` | 1.0.8 F04 |
| 39 | `39-emilia-backgrounds/` | `05-emilia/39-emilia-backgrounds/` | 1.0.8 F05 |
| 40 | `40-emilia-borders/` | `05-emilia/40-emilia-borders/` | 1.0.8 F06 |
| 41 | `41-emilia-effects/` | `05-emilia/41-emilia-effects/` | 1.0.8 F07 |
| 42 | `42-emilia-filters/` | `05-emilia/42-emilia-filters/` | 1.0.8 F08 |
| 43 | `43-emilia-tables/` | `05-emilia/43-emilia-tables/` | 1.0.8 F09 |
| 44 | `44-emilia-transitions/` | `05-emilia/44-emilia-transitions/` | 1.0.8 F10 |
| 45 | `45-emilia-transforms/` | `05-emilia/45-emilia-transforms/` | 1.0.8 F11 |
| 46 | `46-emilia-interactivity/` | `05-emilia/46-emilia-interactivity/` | 1.0.8 F12 |
| 47 | `47-emilia-svg-accessibility/` | `05-emilia/47-emilia-svg-accessibility/` | 1.0.8 F13 |
| 48 | `48-emilia-attributes/` | `05-emilia/48-emilia-attributes/` | 1.0.7 F15 + F16 |
| 49 | `49-onze-stand-up/` | `06-onze/49-onze-stand-up/` | 1.0.7 F01 |
| 50 | `50-onze-cli/` | `06-onze/50-onze-cli/` | 1.0.7 F19 |
| 51 | `51-onze-image/` | `06-onze/51-onze-image/` | 1.0.7 F20 |
| 52 | `52-onze-font/` | `06-onze/52-onze-font/` | 1.0.7 F21 |
| 53 | `53-onze-example-app/` | `06-onze/53-onze-example-app/` | 1.0.7 F22 |
| 54 | `54-emilia-theme/` | `05-emilia/54-emilia-theme/` | 1.0.9 audit |
| 55 | `55-emilia-preflight/` | `05-emilia/55-emilia-preflight/` | 1.0.9 audit |
| 56 | `56-emilia-cascade-and-output/` | `05-emilia/56-emilia-cascade-and-output/` | 1.0.9 audit |
| 57 | `57-emilia-escape-hatches/` | `05-emilia/57-emilia-escape-hatches/` | 1.0.9 audit |
| 58 | `58-emilia-container-queries/` | `05-emilia/58-emilia-container-queries/` | 1.0.9 audit |
| 59 | `59-emilia-custom-utilities-and-variants/` | `05-emilia/59-emilia-custom-utilities-and-variants/` | 1.0.9 audit |
| 60 | `60-rakun-static-generation/` | `03-rakun/60-rakun-static-generation/` | 1.0.9 audit |
| 61 | `61-rakun-parallel-intercepting-routes/` | `03-rakun/61-rakun-parallel-intercepting-routes/` | 1.0.9 audit |
| 62 | `62-rakun-request-context/` | `03-rakun/62-rakun-request-context/` | 1.0.9 audit |
| 63 | `63-rakun-navigation-signals/` | `03-rakun/63-rakun-navigation-signals/` | 1.0.9 audit |
| 64 | `64-rakun-i18n-routing/` | `03-rakun/64-rakun-i18n-routing/` | 1.0.9 audit |
| 65 | `65-rakun-url-rules/` | `03-rakun/65-rakun-url-rules/` | 1.0.9 audit |
| 66 | `66-rakun-metadata-file-routes/` | `03-rakun/66-rakun-metadata-file-routes/` | 1.0.9 audit |
| 67 | `67-jhonstart-forms/` | `04-jhonstart/67-jhonstart-forms/` | 1.0.9 audit |
| 68 | `68-onze-client-bundle/` | `06-onze/68-onze-client-bundle/` | 1.0.9 audit |
| 69 | `69-onze-styling-pipeline/` | `06-onze/69-onze-styling-pipeline/` | 1.0.9 audit |
| 70 | `70-onze-image-response/` | `06-onze/70-onze-image-response/` | 1.0.9 audit |
| 71 | `71-onze-release-packaging/` | `06-onze/71-onze-release-packaging/` | 1.0.9 audit |
| 72 | `72-rakun-auto-configuration/` | `03-rakun/72-rakun-auto-configuration/` | 1.0.9 audit |
| 73 | `73-rakun-starters/` | `03-rakun/73-rakun-starters/` | 1.0.9 audit |
| 74 | `74-rakun-tls-ssl-bundles/` | `03-rakun/74-rakun-tls-ssl-bundles/` | 1.0.9 audit |
| 75 | `75-rakun-observability-metrics/` | `03-rakun/75-rakun-observability-metrics/` | 1.0.9 audit |
| 76 | `76-rakun-actuator-security-probes/` | `03-rakun/76-rakun-actuator-security-probes/` | 1.0.9 audit |
| 77 | `77-rakun-db-migrations/` | `03-rakun/77-rakun-db-migrations/` | 1.0.9 audit |
| 78 | `78-rakun-orm-entities/` | `03-rakun/78-rakun-orm-entities/` | 1.0.9 audit |
| 79 | `79-rakun-oauth2-sso/` | `03-rakun/79-rakun-oauth2-sso/` | 1.0.9 audit |
| 80 | `80-rakun-devtools/` | `03-rakun/80-rakun-devtools/` | 1.0.9 audit |
| 81 | `81-rakun-packaging-release/` | `03-rakun/81-rakun-packaging-release/` | 1.0.9 audit |
| 82 | `82-rakun-static-assets/` | `03-rakun/82-rakun-static-assets/` | 1.0.9 audit |
| 83 | `83-rakun-distributed-transactions/` | `03-rakun/83-rakun-distributed-transactions/` | 1.0.9 audit |
| 84 | `84-rakun-persistent-jobs/` | `03-rakun/84-rakun-persistent-jobs/` | 1.0.9 audit |
| 85 | `85-rakun-mail/` | `03-rakun/85-rakun-mail/` | 1.0.9 audit |
| 86 | `86-rakun-messaging-reliability/` | `03-rakun/86-rakun-messaging-reliability/` | 1.0.9 audit |
| 87 | `87-rakun-audit-and-exchanges/` | `03-rakun/87-rakun-audit-and-exchanges/` | 1.0.9 audit |
| 88 | `88-rakun-cli/` | `03-rakun/88-rakun-cli/` | 1.0.9 audit |
| 89 | `89-rakun-stream-pipelines/` | `03-rakun/89-rakun-stream-pipelines/` | 1.0.9 audit |
| 90 | `90-rakun-jms-brokers/` | `03-rakun/90-rakun-jms-brokers/` | 1.0.9 audit |
| 91 | `91-rakun-pulsar/` | `03-rakun/91-rakun-pulsar/` | 1.0.9 audit |
| 92 | `92-rakun-rsocket/` | `03-rakun/92-rakun-rsocket/` | 1.0.9 audit |
| 93 | `93-rakun-soap-webservices/` | `03-rakun/93-rakun-soap-webservices/` | 1.0.9 audit |
| 94 | `94-jhonstart-element-surface/` | `04-jhonstart/94-jhonstart-element-surface/` | 1.0.9 audit |
| 95 | `95-ecosystem-package-restructure/` | `02-packaging/95-ecosystem-package-restructure/` · generalised in `02-packaging/README.md` · std half in `01-std/` | 1.0.9 audit |
| 96 | — | `01-std/src-builtin.md` · `01-std/snapshots.md` · `01-std/asserts-api.md` | 1.0.9 `tracks/README.md` |

The 1.0.5-beta compiler fronts (`01-checker` … `17-beam-memory`) keep **their own** numbering inside
[`00-compiler-carry-over/`](./00-compiler-carry-over/README.md); they are cited as `00 · 13-module-identity`
and never as a bare number, so a bare number in this milestone is always a library front.
