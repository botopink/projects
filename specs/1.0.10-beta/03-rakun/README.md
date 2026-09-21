# Track B — rakun

**Track:** B — rakun · **Repo:** `repository/rakun` · **Reference:** Spring Boot 4 (`/home/ericfillipe/develop/spring-boot-4/docs/`, 13 files) + the server half of Next.js (`/home/ericfillipe/develop/nextjs/NEXTJS-DOCS.md`) · **Cut:** [`modules.md`](./modules.md) · **Maps:** [`test-snap.md`](./test-snap.md) · [`test-snap-examples.md`](./test-snap-examples.md) · **Proof:** [`unification.md`](./unification.md) · **Target:** erlang, except the boundary fronts named below

| Document | Holds |
|---|---|
| [`modules.md`](./modules.md) | The package cut: 27 submodules under `modules/`, `starters/`, 8 example projects, the dependency graph, targets, what `rakun-test` exposes, front → directory ownership, the reconciliation with the 13 scaffolds, what to reconsider |
| [`unification.md`](./unification.md) | Proof of lossless carry from 1.0.6-beta (20 fronts, 10 examples) and 1.0.7-beta (6 rakun fronts, 15 snippets): per old front what was appended, where the old top-level rows live, and the reference sections still missed |
| [`test-snap.md`](./test-snap.md) | The preventive snapshot-test map of the modules, front by front, with the exact `.snap` each case writes |
| [`test-snap-examples.md`](./test-snap-examples.md) | The same map for `examples/**` |
| `NN-<name>/README.md` | The 51 front specifications, carried verbatim from `specs/1.0.9-beta/` (now [`../absorbed/1.0.9-beta/`](../absorbed/1.0.9-beta/) for its top-level documents) plus `## Carried from …` sections (26 of them) |

## How the numbering works

A front number is an identifier allocated by 1.0.9-beta, not a position. `04–25` were allocated
when the 1.0.6/1.0.7/1.0.8 drafts were merged; `60–66` and `72–93` when the Spring Boot and Next.js
references were audited end to end. Numbers are never reassigned: the ownership table, the
conflict rules, the test maps and every example header cite them, and a jhonstart, emilia, onze or
std document that says "front 62" means the same thing this one does. The directory names are the
1.0.9 names, unchanged. **Read the table below for order; read the number for identity.**

Rakun holds 51 of the 1.0.9 numbers: 04–25 (22), 60–66 (7), 72–93 (22). Everything else is another
track: 01–03 [`../01-std/`](../01-std/) · 26–32, 67, 94 [`../04-jhonstart/`](../04-jhonstart/) ·
33–48, 54–59 [`../05-emilia/`](../05-emilia/) · 49–53, 68–71 [`../06-onze/`](../06-onze/) ·
95 [`../02-packaging/`](../02-packaging/).

## The fronts, in blocking order

Three wave numberings exist for these fronts and they do not agree: the 1.0.9 [`overview.md § Order`](../absorbed/1.0.9-beta/overview.md)
diagram (three bands: wave 1 = 04 · 05 · 22 · 72; wave 2 = 06 · 62 · 63 · 23 · 61 · 65 · 07 · 08 ·
11–17 · 19 · 21 · 73–75 · 80 · 82 · 85 · 88; wave 3 = the rest), each README's own `**Wave:**`
header, and the computed table in [`../fronts.md § Waves`](../fronts.md#waves). The order below
follows the overview bands, and inside a band the **level** — computed from each README's
unannotated `Depends on` line (read through the seven corrections in
[`modules.md § The graph`](./modules.md#the-graph): 09→07 and 21→22 read-only, 07→76 and 13→12
soft, 85→23 and 86→83 seams, 93→88 reversed; front 11's API half has no dependency and its host
half depends on 06, and a citation of 11 is read as one or the other). Ties break on number.
*Wave* reads `overview · header`. `std` 01–03 are level 0.

| # | Front | Priority | Wave | Level | Submodule | Depends on (track B) | Depends on (other tracks) |
|---|---|---|---|---|---|---|---|
| 04 | [`04-rakun-erlang-runtime`](./04-rakun-erlang-runtime/README.md) | critical | 1 · 1 | 1 | `rakun` | — | std 01 |
| 05 | [`05-rakun-config-profiles`](./05-rakun-config-profiles/README.md) | critical | 1 · 1 | 1 | `rakun` | — | std 01 |
| 22 | [`22-rakun-file-routing`](./22-rakun-file-routing/README.md) | critical | 1 · 1 | 2 | `rakun-app` | 05 | std 01 |
| 72 | [`72-rakun-auto-configuration`](./72-rakun-auto-configuration/README.md) | critical | 1 · 3 | 3 | `rakun` | 04 · 05 · 06 | — |
| 06 | [`06-rakun-context-api`](./06-rakun-context-api/README.md) | high | 2 · 2 | 2 | `rakun` | 04 · 05 | — |
| 62 | [`62-rakun-request-context`](./62-rakun-request-context/README.md) | critical | 2 · 2 | 2 | `rakun` | 04 | std 01 |
| 74 | [`74-rakun-tls-ssl-bundles`](./74-rakun-tls-ssl-bundles/README.md) | high | 2 · 2 | 2 | `rakun` | 04 · 05 | — |
| 80 | [`80-rakun-devtools`](./80-rakun-devtools/README.md) | high | 2 · 2 | 2 | `rakun-devtools` | 04 · 05 | std 01 |
| 07 | [`07-rakun-middleware`](./07-rakun-middleware/README.md) | high | 2 · 3 | 3 | `rakun-web` | 06 · 76 (soft) | — |
| 08 | [`08-rakun-data-sql`](./08-rakun-data-sql/README.md) | high | 2 · 3 | 3 | `rakun-data` | 06 | — |
| 11 | [`11-rakun-actuator`](./11-rakun-actuator/README.md) | medium | 2 · 1/3 | 1 (API) · 3 (host) | `rakun-actuator-api` · `rakun-actuator` | — (API) · 06 (host) | — |
| 13 | [`13-rakun-http-clients`](./13-rakun-http-clients/README.md) | medium | 2 · 3 | 3 | `rakun-client` | 05 · 06 · 12 (soft) | std 01 |
| 14 | [`14-rakun-validation`](./14-rakun-validation/README.md) | medium | 2 · 3 | 3 | `rakun-validation` | 05 · 06 | std 01 |
| 15 | [`15-rakun-messaging`](./15-rakun-messaging/README.md) | medium | 2 · 3 | 3 | `rakun-messaging` | 05 · 06 · 11 (API) | std 01 |
| 19 | [`19-rakun-test-utilities`](./19-rakun-test-utilities/README.md) | low (blocking as a dependency) | 2 · 3 | 3 | `rakun-test` | 04 · 06 | `repository/onze` for mocking in 1.0.9 — closed: `#[mock]` is `rakun-test`'s ([`../02-packaging/README.md § 3`](../02-packaging/README.md)) |
| 21 | [`21-rakun-hateoas`](./21-rakun-hateoas/README.md) | low | 2 · 3 | 3 | `rakun-hateoas` | 06 · 22 (ro) | — |
| 23 | [`23-rakun-ssr-pipeline`](./23-rakun-ssr-pipeline/README.md) | critical | 2 · 2 | 3 | `rakun-app` | 04 · 06 · 22 · 62 | jhonstart 28 · 94 · emilia `flush()` (23 line 61) · std 01 · 02 · 03 |
| 16 | [`16-rakun-scheduling`](./16-rakun-scheduling/README.md) | medium | 2 · 3 | 4 | `rakun-scheduling` | 05 · 06 · 11 (host) | std 01 |
| 17 | [`17-rakun-logging`](./17-rakun-logging/README.md) | low (high as a dependency) | 2 · 3 | 4 | `rakun-logging` | 05 · 06 · 11 (host) · 62 | std 03 |
| 61 | [`61-rakun-parallel-intercepting-routes`](./61-rakun-parallel-intercepting-routes/README.md) | high | 2 · 4 | 4 | `rakun-app` | 22 · 23 · 62 | jhonstart 27 · 30 |
| 63 | [`63-rakun-navigation-signals`](./63-rakun-navigation-signals/README.md) | high | 2 · 3 | 4 | `rakun-app` | 22 · 23 · 62 | — |
| 73 | [`73-rakun-starters`](./73-rakun-starters/README.md) | high | 2 · 4 | 4 | `starters/` | 04 · 72 · the modules each starter aggregates | — |
| 75 | [`75-rakun-observability-metrics`](./75-rakun-observability-metrics/README.md) | high | 2 · 4 | 4 | `rakun-metrics` | 11 (API) · 13 · 74 · 17 (reads its correlation field, owns nothing there) | — |
| 82 | [`82-rakun-static-assets`](./82-rakun-static-assets/README.md) | medium | 2 · 4 | 4 | `rakun-web` | 04 · 05 · 07 | std 01 · 03 |
| 12 | [`12-rakun-cache`](./12-rakun-cache/README.md) | medium | 2 · 3 | 5 | `rakun-cache` | 05 · 06 · 11 (host) · 13 · 18 · 62 | std 01 · 03 |
| 65 | [`65-rakun-url-rules`](./65-rakun-url-rules/README.md) | high | 2 · 4 | 5 | `rakun-web` | 07 · 13 · 22 · 62 · 63 | std 01 |
| 85 | [`85-rakun-mail`](./85-rakun-mail/README.md) | medium | 2 · 4 | 6 | `rakun-mail` | 05 · 11 (API) · 74 · 83 · 23 (seam) | std 01 |
| 88 | [`88-rakun-cli`](./88-rakun-cli/README.md) | medium | 2 · 5 | 7 | `rakun-cli` | 04 · 05 · 06 · 80 · 81 · 93 (optional, reversed) | std 01 |
| 66 | [`66-rakun-metadata-file-routes`](./66-rakun-metadata-file-routes/README.md) | medium | 3 · 4 | 3 | `rakun-app` | 22 · 62 · 60 (optional) | jhonstart 32 · onze 70 (optional) · std 01 · 03 |
| 09 | [`09-rakun-data-nosql`](./09-rakun-data-nosql/README.md) | low | 3 · 4 | 4 | `rakun-data` | 08 · 07 (ro) | — |
| 10 | [`10-rakun-security-auth`](./10-rakun-security-auth/README.md) | high | 3 · 4 | 4 | `rakun-security` | 07 · 08 | std 01 |
| 18 | [`18-rakun-session`](./18-rakun-session/README.md) | low (high as a security surface) | 3 · 4 | 4 | `rakun-session` | 05 · 06 · 07 · 08 · 11 (host) · 62 | std 01 |
| 25 | [`25-rakun-route-handlers`](./25-rakun-route-handlers/README.md) | high | 3 · 3 | 4 | `rakun-app` | 06 · 07 · 22 · 23 · 62 | jhonstart 30 · std 01 |
| 77 | [`77-rakun-db-migrations`](./77-rakun-db-migrations/README.md) | high | 3 · 4 | 4 | `rakun-data` | 08 · 72 | std 03 |
| 78 | [`78-rakun-orm-entities`](./78-rakun-orm-entities/README.md) | high | 3 · 4 | 4 | `rakun-data` | 08 · 14 | — |
| 93 | [`93-rakun-soap-webservices`](./93-rakun-soap-webservices/README.md) | low | 3 · 4 | 4 | `rakun-soap` | 05 · 07 · 13 · 74 | — |
| 20 | [`20-rakun-websocket`](./20-rakun-websocket/README.md) | low | 3 · 4 | 5 | `rakun-websocket` | 04 · 05 · 06 · 07 · 10 · 11 (API) · 62 | std 01 |
| 76 | [`76-rakun-actuator-security-probes`](./76-rakun-actuator-security-probes/README.md) | high | 3 · 5 | 5 | `rakun-actuator` | 10 · 11 · 74 | — |
| 79 | [`79-rakun-oauth2-sso`](./79-rakun-oauth2-sso/README.md) | high | 3 · 5 | 5 | `rakun-security` | 05 · 10 · 11 (API) · 13 · 18 · 74 | std 01 |
| 83 | [`83-rakun-distributed-transactions`](./83-rakun-distributed-transactions/README.md) | medium | 3 · 4 | 5 | `rakun-tx` | 05 · 08 · 15 · 16 · 77 | — |
| 84 | [`84-rakun-persistent-jobs`](./84-rakun-persistent-jobs/README.md) | medium | 3 · 4 | 5 | `rakun-scheduling` | 05 · 08 · 11 (host) · 16 · 77 | — |
| 86 | [`86-rakun-messaging-reliability`](./86-rakun-messaging-reliability/README.md) | medium | 3 · 4 | 5 | `rakun-messaging` | 05 · 15 · 75 · 83 (seam) | std 01 |
| 24 | [`24-rakun-server-actions`](./24-rakun-server-actions/README.md) | critical | 3 · 3 | 6 | `rakun-app` | 06 · 12 · 14 · 22 · 23 · 62 · 63 | jhonstart 67 · 94 · std 01 · 03 |
| 60 | [`60-rakun-static-generation`](./60-rakun-static-generation/README.md) | critical | 3 · 4 | 6 | `rakun-app` | 12 · 22 · 23 · 62 | std 01 · 02 · 03 |
| 64 | [`64-rakun-i18n-routing`](./64-rakun-i18n-routing/README.md) | medium | 3 · 4 | 6 | `rakun-app` | 07 · 12 · 22 · 62 · 63 | jhonstart 32 · std 01 |
| 81 | [`81-rakun-packaging-release`](./81-rakun-packaging-release/README.md) | high | 3 · 2 | 6 | `rakun-release` | 04 · 05 · 11 (host) · 76 | std 01 |
| 87 | [`87-rakun-audit-and-exchanges`](./87-rakun-audit-and-exchanges/README.md) | medium | 3 · 5 | 6 | `rakun-actuator` | 07 · 08 · 10 · 11 · 76 | std 01 |
| 89 | [`89-rakun-stream-pipelines`](./89-rakun-stream-pipelines/README.md) | low | 3 · 5 | 6 | `rakun-stream` | 05 · 08 · 11 (host) · 15 · 86 | std 01 |
| 90 | [`90-rakun-jms-brokers`](./90-rakun-jms-brokers/README.md) | low | 3 · 5 | 6 | `rakun-messaging` | 05 · 11 (API) · 15 · 74 · 86 | — |
| 91 | [`91-rakun-pulsar`](./91-rakun-pulsar/README.md) | low | 3 · 5 | 6 | `rakun-pulsar` | 05 · 13 · 15 · 74 · 79 · 83 · 86 | — |
| 92 | [`92-rakun-rsocket`](./92-rakun-rsocket/README.md) | low | 3 · 5 | 6 | `rakun-rsocket` | 07 · 15 · 20 · 74 · 86 | std 01 · 02 |

Seven levels: 2 · 5 · 11 · 14 · 8 · 10 · 1 fronts (plus 11's API half at level 1). The critical path
is `04 → 06 → 07 → 10 → 76 → 81 → 88`; on the Next side `05 → 22 → 23 → 61 · 63`, with `24` and `60`
two levels later because both wait on the cache, which waits on the session, which waits on the
chain and the datasource (`06 → 07 · 08 → 18 → 12 → 24 · 60`). Levels 3 and 4 are where the
parallelism is.

### Where the wave numbers and the dependency lines disagree

Checked front by front against each README's `Depends on` line. The level column wins in every
case; the wave columns are kept as written so the other tracks' cross-references still resolve.

- **Overview band earlier than a dependency's band** (the band cannot hold): **72** is band 1 and
  depends on 06 (band 2) — it cannot land before the context it registers into; **12** is band 2 and
  depends on 18 (band 3); **85** is band 2 and depends on 83 (band 3); **88** is band 2 and depends
  on 81 (band 3). The four rows above sit in their overview band with the level that follows from
  the line.
- **README header earlier than a dependency's header:** **12** says wave 3 and depends on 18 (wave 4);
  **81** says wave 2 and depends on 76 (wave 5) and 11's host (wave 3).
- **Header vs overview:** the header is the overview band plus one for 07 · 08 · 09 · 10 · 11 · 12 ·
  13 · 14 · 15 · 16 · 17 · 18 · 19 · 20 · 21 · 60 · 63 · 64 · 66 · 77 · 78 · 83 · 84 · 86 · 93 (the
  overview counts std as wave 0, the headers count 04/05 as wave 1 and then diverge); equal for 04 ·
  05 · 06 · 22 · 23 · 24 · 25 · 62 · 74 · 80; two or more later for 61 · 65 · 72 · 73 · 75 · 76 · 79
  · 82 · 85 · 87 · 88 · 89 · 90 · 91 · 92; and earlier for 81. Only the header of 62 states an
  intra-wave order ("must land before 23").
- **Same band or same header as a dependency** (needs an intra-wave order the wave gives no room
  for): 22←05 · 23←06/62 · 61/63←23 · 65←07/13/63 · 12←13 · 15/16/17←11 · 20←10 · 24←12/63/14 ·
  25←07 · 75←11/13/74 · 76←10 · 79←10/18 · 81←76 · 82←07 · 83/84←77 · 85←83 · 86←75 · 87←76 ·
  88←80 · 89/90/92←86 · 91←86/79/83. The level column is that order.
- **[`../fronts.md § Waves`](../fronts.md#waves)** (the third numbering, "computed") was
  regenerated from this table on 2026-09-21 and no longer disagrees: 60 · 61 · 63 · 65 sit below 23
  there, and 81 · 88 are no longer in wave 2. Its numbers are the *milestone* levels — the levels
  below, lifted by the cross-track edges a track-B level cannot see — so they are equal or larger,
  never smaller: 23 is level 3 here and wave 5 there, because it renders jhonstart 28.
- **Cross-track:** 66 is level 3 in track B and depends on jhonstart 32, which is wave 5 in the
  regenerated [`../fronts.md § Waves`](../fronts.md#waves); 61 on 27 (wave 4); 23 on 28 (wave 4).
  24 and 67 cite each other, and `fronts.md` resolves the pair with 24 first, because 67 consumes
  the action envelope 24 defines. [`../04-jhonstart/README.md`](../04-jhonstart/README.md) still
  carries its 1.0.9 wave column (28 = 3, 32 = 6, 67 = 6), which is the track's own numbering, not
  the milestone's. A track-B level is a lower bound, not a date.

## Dependency graph

Front level, one line per level; `X ◄ a·b` reads "X depends on a and b". Only unannotated edges
are drawn (read-only, soft and seam citations are not edges — see `modules.md`); `std` 01–03 and
the other tracks sit under everything and are not drawn. The normative form is the table above.

```
L1  04                05                                              11api (no dependency)
    │╲                │╲
L2  06 ◄ 04·05        22 ◄ 05        62 ◄ 04        74 ◄ 04·05        80 ◄ 04·05
    │
L3  07 08 11host 13 14 15 19 21 ◄ 06      72 ◄ 04·05·06      23 ◄ 04·06·22·62      66 ◄ 22·62
    │  │  │      │
L4  10 ◄ 07·08   09 ◄ 08   18 ◄ 07·08·11host·62   16 17 ◄ 11host   77 ◄ 08·72   78 ◄ 08·14
    73 ◄ 72   82 ◄ 07   93 ◄ 07·13·74   75 ◄ 11api·13·74   25 ◄ 07·23   61 63 ◄ 22·23·62
    │
L5  76 ◄ 10·11·74   20 ◄ 07·10   79 ◄ 10·13·18·74   12 ◄ 11host·13·18·62   65 ◄ 07·13·63
    83 ◄ 08·15·16·77   84 ◄ 08·16·77   86 ◄ 15·75
    │
L6  81 ◄ 76·11host   87 ◄ 07·08·10·76   24 ◄ 12·14·23·63   60 ◄ 12·22·23·62   64 ◄ 07·12·22·63
    85 ◄ 74·83   89 ◄ 08·15·86   90 ◄ 15·74·86   91 ◄ 13·15·74·79·83·86   92 ◄ 07·15·20·74·86
    │
L7  88 ◄ 04·05·06·80·81
```

Module level, the same graph collapsed onto the 27 submodules, is drawn in
[`modules.md § The graph`](./modules.md#the-graph).

## Cross-track dependencies

| Direction | Front | Other track | What crosses |
|---|---|---|---|
| rakun → std | 04 · 05 · 10 · 12 · 13 · 14 · 15 · 16 · 18 · 20 · 22 · 23 · 24 · 25 · 60 · 62 · 64 · 65 · 66 · 79 · 80 · 81 · 82 · 85 · 86 · 87 · 88 · 89 · 92 | 01 | `net`, `path`, `fs`, `process`, `clock`, `random`, `hmac`, `encoding`, `regex`, `escape` — named per front in its `Depends on` line |
| rakun → std | 23 · 60 · 92 | 02 | spawn/gather over unstarted thunks (`async.all`) — `@Future` carries no concurrency on BEAM |
| rakun → std | 12 · 17 · 23 · 24 · 60 · 66 · 77 · 82 | 03 | content hash: cache keys, error digest, build id, fingerprints, migration checksums |
| rakun → jhonstart | 23 | 28 · 94 | server components rendered by the pipeline; `isVoidTag`/`isRawTextTag` and the element surface the walker renders |
| rakun → jhonstart | 24 | 67 · 94 | the browser half of a server action; `form`/`input`/`button` constructors for the action form |
| rakun → jhonstart | 25 | 30 | the flush primitive a streaming handler reuses |
| rakun → jhonstart | 61 | 27 · 30 | the soft-navigation marker `Link` sets; per-slot `loading` boundaries |
| rakun → jhonstart | 64 · 66 | 32 | the metadata model (`alternates`, `<link>`/`<meta>` feeds) |
| rakun → emilia | 23 | 56 (`flush()`, `repository/emilia/src/emilia.bp:62-65`) | one `<style>` block per document; 48's attribute hook is reached through jhonstart, never directly. `modules/rakun-app/botopink.json` lists `emilia` as well as `jhonstart` |
| rakun → onze | 66 | 70 (optional) | dynamic OG image bodies — does not block 66 |
| rakun → onze | 19 | — | 1.0.9 said `repository/onze` for mocking; the mocking library is retired and `#[mock]` is hosted by `rakun-test` ([`../02-packaging/README.md § 3`](../02-packaging/README.md), [`../01-std/onze-migration.md`](../01-std/onze-migration.md)) — no edge |
| jhonstart → rakun | 26 | 22 (`matchPath`) · 23 (ro) | one matcher, not two |
| jhonstart → rakun | 28 · 29 · 30 | 62 (ro) · 23 (ro) | the erlang module `server.bp` binds; the payload shape |
| jhonstart → rakun | 27 | 60 (ro) · 23 (ro) | prefetch reads the static/dynamic decision |
| jhonstart → rakun | 31 | 17 (ro) · 24 (ro) · 63 (ro) | `error.digest`; the action envelope; the `jhonstart:` signal prefix |
| jhonstart → rakun | 32 | 66 (ro) | the paths `openGraph.images` names |
| jhonstart → rakun | 67 | 24 · 14 (ro) · 63 (ro) | the action envelope it decodes; constraints it mirrors |
| onze → rakun | 68 · 69 · 50 · 51 · 70 · 71 · 53 | 04 · 05 · 07 · 11 · 12 · 20 · 22 · 23 · 24 · 25 · 60 · 62 · 63 · 65 · 66 | listed per front in [`../06-onze/README.md`](../06-onze/README.md); 68 and 69 fill the `RenderHooks` record front 23 declares — the head extras, the body scripts and the style sink — and rakun names neither (decision 77); `examples/blog-server` here is the erlang half of `repository/onze/examples/blog` |
| emilia → rakun | — | — | none; 82 serves emilia's emitted CSS as a file, which is consumption, not a dependency |

The package-level consequence — `rakun` core depends on `std` only; `rakun-app` is the one submodule
with edges to other libraries — is in [`modules.md § Three facts`](./modules.md#three-facts-that-decide-the-cut).

## Targets

| Fronts | Target |
|---|---|
| 04–13 · 15–21 · 25 · 62–64 · 66 · 72–93 | **erlang** — runs while a request is in flight, or at build/dev time on the server box |
| 14 | **both — boundary**: the constraints the server enforces are the ones the client mirrors |
| 22 · 23 · 24 · 60 · 61 · 65 | **both — boundary**: the route table is matched on BEAM and prefetched in the browser; the payload is serialized on BEAM and reconnected in the browser; `basePath`/trailing-slash rules are read by both. The render, the escaping, the chunk writer and every handler are erlang |

## Rules carried from 1.0.9, unchanged

- One repo per front; the compiler knows none of this; target is assigned, not chosen; reuse `std`;
  additive only; examples are code, not prose — [`../contracts.md`](../contracts.md).
- Every erlang host module is `src/sidecars/rakun_<name>.erl`, never a bare `<name>.erl`.
- `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` are frozen; 04 appends
  one `#[@external(erlang)]` block to `src/runtime.bp` and touches nothing else there.
- `botopink.json` and `src/root.bp` of a shared module belong to the lowest-numbered front in it;
  the rest append their lines in front-number order and never reorder.
- A front that needs a compiler change files a row in [`../language-gaps.md`](../language-gaps.md)
  instead; every `// LANGUAGE GAP:` in an example appears there.
