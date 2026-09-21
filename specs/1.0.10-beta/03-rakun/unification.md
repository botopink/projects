# rakun — unification: what the 1.0.6 / 1.0.7 drafts said that 1.0.9 dropped

**Track:** B — rakun · **Cut:** [`modules.md`](./modules.md) · **Order:** [`README.md`](./README.md) · **Top-level rows:** [`../unification.md`](../unification.md) · **Method:** every 1.0.6-beta front (20) and every 1.0.7-beta rakun front (6) was read whole against the 1.0.9 counterpart named in 1.0.9's [`overview.md`](../absorbed/1.0.9-beta/overview.md) merge table; anything present in the draft and absent from the counterpart was appended verbatim (translated where the draft was Portuguese, identifiers untouched) to the 1.0.10 copy of the counterpart README under `## Carried from <milestone> FNN <name>`. Items the 1.0.9 text explicitly rejects are still quoted and labelled `superseded by: <section>` so the rejection is visible as a decision. Draft example files were copied into the counterpart's `examples/` with a first-line `// carried from …` comment.

The originals of `specs/1.0.6-beta/`, `specs/1.0.7-beta/` and `specs/1.0.9-beta/` are kept verbatim under [`../absorbed/`](../absorbed/) (`1.0.6-beta/{overview,fronts}.md` + 20 front READMEs · `1.0.7-beta/{overview,fronts,examples-bp}.md` + 22 front READMEs · `1.0.9-beta/{overview,fronts,contracts,deferred,language-gaps}.md`); the *old* columns below cite the paths they had when they were read.

Nothing was removed from any README; the 1.0.9 text of each front is byte-identical above the appended section, save the link paths (`../contracts.md` → `../../contracts.md`, `../language-gaps.md` → `../../language-gaps.md`, `../fronts.md` → `../../fronts.md`).

## Per old front

| Old front | New front (1.0.10) | Appended under `## Carried from …` | Example carried |
|---|---|---|---|
| `1.0.6-beta/01-erlang-runtime` | `04-rakun-erlang-runtime` | 11 items: full `-export` arity list + module `init()` (superseded: `rakun_registry`); concern→storage table (HTTP row superseded: gen_tcp); `botopink check` acceptance (no counterpart); cowboy `serve/2` + rebar gate/blast radius (superseded: *Why gen_tcp*); router `match/find_match` sketch; `ets:insert` singleton (superseded: `insert_new`); `done/1` (`get(...) orelse []` is a badarg); CI `allow_fail: true` (superseded: `known-red-libs.txt`); `botopink build` sidecar + "built app serves HTTP" boxes (qualified by *Blocked*); two blast-radius lines; two notes | `examples/01-erlang-runtime-example.bp` |
| `1.0.6-beta/02-config-profiles` | `05-rakun-config-profiles` | 8 items: loader API `loadConfigFile`/`loadEnvVars`/`loadProfileConfig`/`resolveProperty` + `env.vars()` (superseded: `rkConfigLoad`); `rakun_config` exports (superseded: one table); "non-`RAKUN_` vars ignored" acceptance (unstated); `#[value("rakun.profiles.active")]` vs `profiles.active()`; `configurationProperties(comptime decl, prefix)` signature; bootstrap `rkLoadConfig()` + "`server.port` beats `App.port`" (frozen bootstrap; the port-override rule has no home in 04 or 05); commonJS gate; Spring Cloud Vault note + JSON-first YAML note | `examples/02-config-profiles-example.bp` |
| `1.0.6-beta/03-context-api` | `06-rakun-context-api` | 9 items: `getBean`/`containsBean`/`ApplicationListener` + `behavior ApplicationEventPublisher` (superseded: `ctx.publish`); Node + Erlang `resolve` sketches (superseded: factory-valued registry); rename table (`getBeanNames`→`beanNames`, `rkHas`→`rkHasBean`, `rkRegisterEventListener`→`rkRegisterListener`); `postConstruct` emission (superseded: placement-only markers); typed events incl. `ContextRefreshedEvent`/`ApplicationStoppedEvent` (superseded: single `Event`; neither in the nine-event list, shutdown publishes no event); `eventListener` emission; `rkPublishEvent` in `Rakun.run` (superseded: `context.bootSequence()`); SIGTERM/SIGINT wiring (SIGINT unnamed anywhere in 1.0.9); sync-only events + `postConstruct` order notes | `examples/03-context-api-example.bp` |
| `1.0.6-beta/04-web-middleware` | `07-rakun-middleware` | 6 items: `Filter.doFilter`/`FilterChain` + JS `registerFilter` + `#[filter]` emission and rename table (request-side `request.withHeader` has no counterpart); global CORS via `#[bean] corsConfiguration()` + `CorsFilter` at −100 (superseded: `CorsPolicy`/`#[provides]`, −200); type-keyed `#[exceptionHandler("NotFoundException")]` + `controllerAdvice` (superseded: string tags); `ProblemDetail.type` wire sample (`type` vs `typeUri` mapping unstated); built-in `RequestIdFilter`/`LoggingFilter`/`TimingFilter` + per-filter enable keys (uncovered by any front); module tree (superseded: Owns) | `examples/04-web-middleware-example.bp` |
| `1.0.6-beta/05-data-sql` | `08-rakun-data-sql` | 8 items: `DataSource.getConnection`/`Connection.execute|query|close` behaviors (superseded: Contradictions 3; `Connection` methods still unspelled); `PostgresDataSource`/`MySqlDataSource` + `spring.datasource.url|username|password` + `createDataSource(url)` (`username`/`password` keys named nowhere in 08); `SqlTemplate(dataSource)` positional `$1` + `mapRow` (superseded: named `Param`, 78 for mapping); body-emitting `#[query]` sketch (superseded: helper emission); `#[bean] dataSource()` + hikari `maximum-pool-size`/`minimum-idle` (superseded: fixed pool); method-level `#[transactional]` + `rkTransactional` (superseded: `<Type>Tx` proxy); module tree; deps `poolboy`/`pg`/`mysql` + notes | `examples/05-data-sql-example.bp` |
| `1.0.6-beta/06-security-auth` | `10-rakun-security-auth` | 10 items: `@EnableWebSecurity`/`@PostAuthorize`/`JwtDecoder` names (no 1.0.9 analogue); `SecurityContext`/`credentials`/`SecurityContextRepository` (superseded); builder-DSL policy + bare `SecurityFilter` (superseded); `rakun.security.jwt.secret` + `verifyJwt`/`JwtClaims` (key absent in 1.0.9); `BasicAuthenticationFilter`/bcrypt (superseded); `loadUserByUsername`→`loadByUsername` + in-memory user format + JDBC arm SQL (absent); `rkCheckAuthority`/JS runtime (superseded); header-rotation CSRF `X-CSRF-TOKEN` (superseded); src tree; commonJS gate + `jose`/`bcrypt` (superseded) | `examples/06-security-auth-example.bp` |
| `1.0.6-beta/07-actuator-health` | `11-rakun-actuator` | 7 items + a 6-row "covered by sibling fronts" table (metrics/`MetricsFilter` → 75, `env` masking → 76, Prometheus → 75, logging → 17, `DataSourceHealthIndicator` → 08): `DiskSpaceHealthIndicator` 100 MB threshold (absent everywhere); `DataSourceHealthIndicator` acceptance rows for owner 08; `buildTime` + `profile` info keys (absent); old `Health`/`HealthIndicator` shape (superseded); per-endpoint `#[restController]` (superseded); src tree; commonJS gate | `examples/07-actuator-health-example.bp` |
| `1.0.6-beta/08-cache-abstraction` | `12-rakun-cache` | 8 items: `#[cachePut]` (named only as old proposal, neither shipped nor declined); `Cache`/`CacheManager` handles incl. `getCacheNames` (absent); `ConcurrentMapCache*` + `rkCache*` rename table + ETS snippet (superseded); `spring.redis.host/port` + JSON serialization (superseded); `allEntries:` spelling (superseded); key rule (namespace = cache name — unstated) + TTL/max-size defaults + Caffeine (declined); src tree; both-targets gate | `examples/08-cache-abstraction-example.bp` |
| `1.0.6-beta/09-rest-client` | `13-rakun-http-clients` | 7 items: `ClientHttpRequestInterceptor` + `.interceptor()` (absent; front 79 consumes an undeclared seam); `.uri("…/{id}", id)` templates on the fluent client (absent; only `#[httpExchange]` substitutes); auto `Content-Type` on bodied requests (absent) + typed `body<T>` (superseded); `RestClientException`/`onStatus` (superseded); 30 s timeout/`std.http.fetch`/WebClient (superseded) + retry (no decision anywhere); src tree; both-targets gate | `examples/09-rest-client-example.bp` |
| `1.0.6-beta/10-validation` | `14-rakun-validation` | 1 item: proposed src tree (`constraints.bp`, `validator.bp`). Everything else present or explicitly superseded | `examples/10-validation-example.bp` |
| `1.0.6-beta/11-messaging-amqp` | `15-rakun-messaging` | 5 items: `receive(queue) -> ?string` pull API (absent everywhere); `convertAndSend<T>`/JSON conversion (superseded: Out of scope); `amqp_connection:start` snippet; `src/amqp/**` layout (superseded: Problem); `amqplib`/both targets (superseded: Target) | none (draft had none) |
| `1.0.6-beta/16-messaging-kafka` | `15-rakun-messaging` (own heading) | 7 items: `sendDefault(topic, value)`; labelled `#[kafkaListener(topics:, groupId:)]` + `(key, value)` handler (superseded: Step 3); `brod:produce_sync(..., Partition, ...)` — explicit partition on produce absent; key→partition ordering guarantee absent; `src/kafka/**` (superseded); `kafkajs` (superseded); `Depends on: F11` (superseded) | none |
| `1.0.6-beta/12-scheduling` | `16-rakun-scheduling` | 6 items: `parseCron(expr) -> CronExpression` public name (84 reuses "the cron parser", unnamed); `@EnableScheduling` mapping; labelled args (superseded: Problem); pool size (superseded: The executor); `setInterval`/both targets (superseded); module tree | none |
| `1.0.6-beta/13-logging-structured` | `17-rakun-logging` | 5 items: `getLogger` → `logger` rename unstated; sample ECS JSON line; Log4j2 not named anywhere in 1.0.9; module tree; both targets (superseded) | none |
| `1.0.6-beta/14-session-management` | `18-rakun-session` | 7 items: `@EnableRedisHttpSession`/`@EnableJdbcHttpSession` mapping; `attributes: Dict` vs `Array<#(...)>` unexplained; UUID id (superseded: Ids rule 1); `InMemorySessionRepository` (superseded); `#[filter] #[order(-50)]` + `doFilter(req, res, chain)` — marker/order/signature absent; module tree; both targets (superseded) | none |
| `1.0.6-beta/15-test-utilities` | `19-rakun-test-utilities` | 6 items: `MockRequest`/`MockResult` (superseded: §1–§3); `MockMvc.builder().controller(T)` (superseded); `@mockBean` + `when("list")` DSL (superseded: §8); `@WebMvcTest`/`@DataJpaTest` names unmapped; module tree; both targets (superseded) | none |
| `1.0.6-beta/17-data-nosql` | `09-rakun-data-nosql` | 7 items: `update(collection, query, update)`/`delete(collection, query)` by-filter mutations absent (1.0.9 is by-id only); typed `<T>` API (superseded: JSON strings); per-store config keys allowing Redis+Mongo+ES concurrently vs singular `rakun.nosql.url`; `eredis_cluster` absent; `#[query("{email: $1}")]` (superseded: `#[documentQuery]`); Node drivers (superseded); module tree | none |
| `1.0.6-beta/18-web-websocket` | `20-rakun-websocket` | 5 items: `onError(session, error)` callback absent (1011 close with no hook); no-arg `close()` defaults gap; Cowboy `websocket_handle`/`websocket_info` snippet; module tree; both targets (superseded) | none |
| `1.0.6-beta/19-web-client-reactive` | `13-rakun-http-clients` (own heading) | 5 items: `.uri("/users/{id}", [id])` on `RequestSpec` absent; `bodyToFuture<T>`/`bodyToFlux<T>` (superseded: Language gaps); streaming body via `@Iterator<T>` absent; `@Future({...})` wrapper (superseded); "non-blocking via httpc async" (superseded) | none |
| `1.0.6-beta/20-hateoas` | `21-rakun-hateoas` | 5 items: `Link.name` attribute absent; `Links(self: Link, others)` required-self type absent; `RepresentationModel<T>`/`CollectionModel<T>` (superseded: comptime `#[halResource]`); module tree; both targets (superseded) | none |
| `1.0.7-beta/09-rakun-ssr-pipeline` | `23-rakun-ssr-pipeline` | 10 items + 1 reference row + example-diff table: `Accept: text/html` bootstrap switch (open); `wrapInHtmlDocument`/`renderMetadataToHtml`/`collectMetadata` (superseded: § The document + 32); `<!DOCTYPE>`/`<title>` document assertion (open); `ssr.mjs renderPage` via `renderToString` (superseded: Target/Step 3); load-by-path (superseded: 22 § Problem); single-string `renderPageToHtml` (superseded: `RenderedPage`); branch name | `examples/ssr-page-and-layout-carried-example.bp` — `// LANGUAGE GAP:` parameter defaults |
| `1.0.7-beta/10-rakun-server-actions` | `24-rakun-server-actions` | 11 items + 2 reference rows + example-diff table: action-by-name form + `_action` hidden field (superseded: `__onze_action` id); `handleFormSubmission`/`rkInvokeAction` (superseded: `dispatchAction`); 1.0.7 `@External` cell names + `actions.mjs` (24 leaves the Node side unspecified); `@Future<void>`/`formData.get` vs `ActionResult`/`form.field`; `__rakun_action_` emit spelling; `revalidatePath` as `@External` (superseded: 12); "POST-only" (open: `GET` on an action id undecided); decorator-inside-`test`; branch name | `examples/action-by-name-carried-example.bp` |
| `1.0.7-beta/11-rakun-route-handlers` | `25-rakun-route-handlers` | 9 items + 1 reference row: export-name verbs `pub fn GET…` (superseded: § Seven decorators); `scanRouteHandlers` (superseded: 22 registration); `Response.json(non-string)`/`request.json()` vs `HandlerResponse.json(string)`/`bodyJson`; return-redirects → 63 (no builder on `HandlerResponse`); headers → 62; mock-FS detection test (superseded: CLI suite); branch name | `examples/verb-exports-carried-example.bp` — `// LANGUAGE GAP:` no export-name reflection |
| `1.0.7-beta/12-rakun-middleware` | `07-rakun-middleware` (second heading) | 11 items + 1 reference row + example-diff table: `NextResponse` with status-200 continue sentinel (superseded: `Next`/status 0); `X-Rewrite` header rewrite (superseded: `rkChainSignal`); SSR-pipeline invocation (superseded, explicit); `pub val config = MiddlewareConfig(matcher: [...])` (superseded: `#[matcher]` + 65; list-of-matchers per entry is open); `app/middleware.bp` location (superseded: 22 Step 5); async `#[@future]` signature (eager on erlang); chain-vs-`matchPath` ordering (open); `Response.withHeader`/`getHeader`/`hasHeader` methods; commonJS row; logging/timing middleware; branch name | `examples/next-response-middleware-carried-example.bp` |
| `1.0.7-beta/13-rakun-cache` | `12-rakun-cache` (second heading) | 12 items + 2 reference rows + example-diff table: `#[cache]` + `cacheLife`/`cacheTag` statements (superseded via § Language gaps); `CacheLifeProfile` enum (strings in 1.0.9); 1.0.7 host-cell names vs 12's; `cache.mjs` Map (superseded: erlang-only); key = name + JSON args; **default in-memory vs 1.0.9 default `rakun.cache.type=none` — reversed, recorded**; tag-vs-path rationale; `.revalidate == 3600` test; stale-then-fresh vs immediate refetch; commonJS row; branch name; "extends 1.0.6 module" | `examples/use-cache-directive-carried-example.bp` — `// LANGUAGE GAP:` decorator cannot wrap a body |
| `1.0.7-beta/14-rakun-file-routing` | `22-rakun-file-routing` | 10 items + example-diff table: `scanAppDir` host cell at startup (superseded: § Problem); `RouteNode` tree with has* flags + `filePath` (superseded: `RouteEntry`); `matchRoute`/`RouteMatch(node, params)` (covered: `matchPath`); `renderWithLayouts` root-first loop (covered: `layoutChain`+`compose`; nests root innermost, opposite of 23 — noted); `file_router.mjs` (superseded); ssr snippet (superseded); tests (covered); dev-watch → 50/80; branch name; blast radius | `examples/layout-and-params-carried-example.bp` — `// LANGUAGE GAP:` parameter defaults, `@Decl` source location |

Fronts 60–66 and 72–93 replace no draft (`**Replaces:** new`) and carry nothing.

## 1.0.6 `examples/*.bp` → destination

`ls specs/1.0.6-beta/examples/` lists ten files; drafts F11–F20 shipped none, which is why the
*Example carried* column above reads *none* for them. Each copy keeps its 1.0.6 name and carries a
first-line `// carried from …` comment; the front's own 1.0.9 examples sit beside it untouched.

| 1.0.6 file | Destination |
|---|---|
| `01-erlang-runtime-example.bp` | `04-rakun-erlang-runtime/examples/` |
| `02-config-profiles-example.bp` | `05-rakun-config-profiles/examples/` |
| `03-context-api-example.bp` | `06-rakun-context-api/examples/` |
| `04-web-middleware-example.bp` | `07-rakun-middleware/examples/` |
| `05-data-sql-example.bp` | `08-rakun-data-sql/examples/` |
| `06-security-auth-example.bp` | `10-rakun-security-auth/examples/` |
| `07-actuator-health-example.bp` | `11-rakun-actuator/examples/` |
| `08-cache-abstraction-example.bp` | `12-rakun-cache/examples/` |
| `09-rest-client-example.bp` | `13-rakun-http-clients/examples/` |
| `10-validation-example.bp` | `14-rakun-validation/examples/` |

## 1.0.7 `examples-bp.md` rakun snippets → destination

Fifteen rakun snippets (F09–F14: 2 · 3 · 3 · 2 · 2 · 3) plus F22's `middleware.bp`. Each carried
file holds its snippets verbatim under `// --- <1.0.7 heading>` markers, with a note above any
snippet whose shape 1.0.9 settled differently, and a top-level `// LANGUAGE GAP:` line where the
syntax is one — listed in [`../language-gaps.md`](../language-gaps.md) by the owning front.

| `examples-bp.md` | Snippet | Destination | 1.0.9 form beside it |
|---|---|---|---|
| F09 — Rakun SSR Pipeline | Página SSR completa (`app/page.bp`) · Layout com SSR (`app/layout.bp`) | `23-rakun-ssr-pipeline/examples/ssr-page-and-layout-carried-example.bp` | `server-render-example.bp` |
| F10 — Rakun Server Actions | Action simples · Formulário usando a action · Action com redirect | `24-rakun-server-actions/examples/action-by-name-carried-example.bp` | `form-action-example.bp` (redirect → 63) |
| F11 — Rakun Route Handlers | GET handler · POST handler · Dynamic route handler | `25-rakun-route-handlers/examples/verb-exports-carried-example.bp` — the file notes the DELETE handler has no 1.0.9 counterpart (`#[deleteRoute(...)]` is 25's spelling) | `route-handler-example.bp` |
| F12 — Rakun Middleware | Middleware de autenticação · Middleware de logging | `07-rakun-middleware/examples/next-response-middleware-carried-example.bp` | `middleware-convention-example.bp`, `filter-chain-example.bp` |
| F13 — Rakun Cache | Cache com cacheLife · Cache com revalidação on-demand | `12-rakun-cache/examples/use-cache-directive-carried-example.bp` | `use-cache-example.bp`, `cacheable-service-example.bp` |
| F14 — Rakun File Routing | Estrutura de arquivos | **not extracted** — a directory listing, not code; the tree is what 22 § Problem restates and `app-tree-example.bp` encodes | `app-tree-example.bp` |
| F14 — Rakun File Routing | Layout aninhado · Dynamic segment | `22-rakun-file-routing/examples/layout-and-params-carried-example.bp` | `app-tree-example.bp`, `route-table-example.bp` |
| F22 — Onze13 Example App | `middleware.bp` (session-cookie gate) | `07-rakun-middleware/examples/next-response-middleware-carried-example.bp` (third marker) | — |
| F22 — Onze13 Example App | `app/layout.bp` · `app/blog/page.bp` · `components/post-card.bp` | **not rakun's** — jhonstart/onze surface; mapped in [`../06-onze/unification.md`](../06-onze/unification.md) | — |


## Draft features the merge still misses

Features a draft named that no 1.0.9 rakun front covers (verified by `grep -ril` over
the 1.0.9 rakun READMEs — the text above each `## Carried from` section here, byte-identical). Each is now quoted in the counterpart's `## Carried from`
section; this table is the index. A row here is a candidate for a fold-in to the named front, not a
new front.

| Feature (upstream) | Draft that named it | Nearest front | State |
|---|---|---|---|
| Spring Cloud Vault / encrypted property sources | 1.0.6 F02 Notes | 05 | out of scope in the draft too; nowhere restated |
| `ContextRefreshedEvent`, a shutdown-time event (`ContextClosedEvent`) | 1.0.6 F03 Steps 4, 7 | 06 | 06's nine-event list has neither; shutdown publishes no event |
| `SIGINT` handling beside `SIGTERM` | 1.0.6 F03 Step 7 | 06 · 07 · 76 · 88 | only `SIGTERM` appears |
| Request/access logging filter (`CommonsRequestLoggingFilter`), `X-Response-Time` timing filter, per-filter enable keys | 1.0.6 F04 Step 6 | 07 · 17 · 75 | 75 ships the `http.server.requests` timer, no header; 07 defines no built-in filter set |
| `spring.datasource.username` / `.password` keys | 1.0.6 F05 Steps 1, 6 | 08 | 08 names only `rakun.datasource.url` and `.pool.size` |
| `@PostAuthorize`, `@EnableWebSecurity`, `JwtDecoder`, `SecurityContextRepository` | 1.0.6 F06 Mechanism, Step 1 | 10 | 10 declines only `@PreAuthorize`; no named verification entry point |
| `management.health.diskspace.threshold` | 1.0.6 F07 Step 1 | 11 | `diskSpace` named, no threshold or key |
| `@CachePut`; `CacheManager.getCacheNames()` / programmatic `Cache` handle; EhCache in the declined-provider list | 1.0.6 F08 Mechanism, Steps 1, 5 | 12 | `#[cachePut]` neither shipped nor declined |
| `ClientHttpRequestInterceptor` chain; `ResponseSpec.onStatus`; HTTP client retry | 1.0.6 F09 Steps 4, 5, Notes | 13 | front 79 assumes an interceptor seam 13 never defines |
| `RabbitTemplate.receive` (synchronous pull); `convertAndSend` / typed conversion | 1.0.6 F11 Mechanism | 15 | 15 declares conversion out of scope; pull has no owner |
| `KafkaTemplate.sendDefault`; explicit partition on produce; key→partition ordering guarantee | 1.0.6 F16 Mechanism | 15 | |
| `@EnableScheduling` | 1.0.6 F12 Mechanism | 16 | implicit in `#[scheduler]`, never named |
| Log4j2 | 1.0.6 F13 Mechanism | 17 | Logback → `sys.config` is mapped; Log4j2 nowhere |
| `@EnableRedisHttpSession` / `@EnableJdbcHttpSession` | 1.0.6 F14 Mechanism | 18 | |
| `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest` names | 1.0.6 F15 Mechanism | 19 | slices and whole-context boot covered conceptually, names unmapped |
| `MongoTemplate` / `RedisTemplate` / `ElasticsearchTemplate`; `eredis_cluster`; by-filter `update`/`delete` | 1.0.6 F17 Mechanism, Step 2 | 09 | 09's stores are by-id only |
| `@ServerEndpoint` mapping; `onError(session, error)` | 1.0.6 F18 Mechanism | 20 | renamed `#[wsEndpoint]` without the mapping; 1011 close has no hook |
| `bodyToMono`/`bodyToFlux`; `@Iterator<T>` streaming body | 1.0.6 F19 Mechanism | 13 | |
| `CollectionModel` / `EntityModel`; `Link.name` | 1.0.6 F20 Mechanism | 21 | `RepresentationModel` named, the collection type not |
| `Accept: text/html` content negotiation between a `P` route and an `R` route | 1.0.7 F09 lines 131–133 | 22 · 25 | both decide by table kind only |
| Server action `GET` answer (405 vs 404) | 1.0.7 F10 line 200 | 24 | |
| Multiple matchers per middleware entry | 1.0.7 F12 line 120 | 07 · 65 | 65 defines the grammar, not a list per entry |
| Middleware ordering relative to `matchPath` | 1.0.7 F12 Step 2 | 07 | chain sits inside `dispatch_http/5`; before/after unstated |
| Upstream URLs `…/building-your-application/rendering`, `…/guides/server-actions`, `…/getting-started/caching`, `…/getting-started/revalidating`, `…/getting-started/proxy` | 1.0.7 F09–F13 line 3 | 23 · 24 · 12 · 60 · 65 | content covered, URL uncited |

## Redirects recorded by the module cut

Not a loss — a relocation. The front READMEs still name their 1.0.9 directory; [`modules.md § What
this changes in the front READMEs`](./modules.md#what-this-changes-in-the-front-readmes) is the table
of every path read differently in 1.0.10 (22–25 and 60–66 → `modules/rakun-app/`, 64 → `rakun-app/src/i18n/`,
20 → `rakun-websocket/`, 93 → `rakun-soap/`, 75 → one name, 73 → `starters/`).

## 1.0.6 / 1.0.7 top-level rows → where they live now

[`../unification.md § 1.0.6-beta`](../unification.md) and [`§ 1.0.7-beta`](../unification.md) hold
the generic map; these are the rakun-specific pointers. The old documents are read from
[`../absorbed/1.0.6-beta/`](../absorbed/1.0.6-beta/) and [`../absorbed/1.0.7-beta/`](../absorbed/1.0.7-beta/).

| Old row | Lives now |
|---|---|
| 1.0.6 `overview.md` front table — F01–F20, priority, module | [`README.md § The fronts`](./README.md#the-fronts-in-blocking-order) (priority = 1.0.9's, module column superseded by [`modules.md § Front → directory ownership`](./modules.md#front--directory-ownership)); per-front rows above |
| 1.0.6 `overview.md § Order` — phases 1–3, *why 01 / 02 first* | [`README.md § The fronts`](./README.md#the-fronts-in-blocking-order) (levels); 1.0.9 [`overview.md § Order`](../absorbed/1.0.9-beta/overview.md) (*why 04 still comes before the rest of track B*) |
| 1.0.6 `overview.md § Regras` — multi-module · Erlang-first · decorator-based · IoC integration · both-target tests · no compiler changes · std reuse | multi-module → [`../02-packaging/README.md`](../02-packaging/README.md) + [`modules.md`](./modules.md); Erlang-first → 1.0.9 [`overview.md § Which target runs what`](../absorbed/1.0.9-beta/overview.md) (superseding *both-target tests*: target is assigned); decorator-based / IoC → [`../contracts.md`](../contracts.md); no compiler changes → [`../language-gaps.md`](../language-gaps.md) route; std reuse → *reuse std* rule |
| 1.0.6 `overview.md § Estrutura de Módulos` — `src/` + thirteen `modules/rakun-*` + `examples/` | [`modules.md § Layout`](./modules.md#layout) (27 + `starters/` + 8 examples); the thirteen are reconciled in [`modules.md § Verdicts`](./modules.md#verdicts) |
| 1.0.6 `overview.md § Mapeamento Spring Boot 4 → Rakun` | [`../02-packaging/README.md § Carried from 1.0.6-beta`](../02-packaging/README.md#carried-from-106-beta--module--spring-starter) (re-pointed at 1.0.9 numbers); the *Spring Boot 4* column of [`modules.md § The cut`](./modules.md#the-cut) |
| 1.0.6 `fronts.md § Ownership` — module, source, tests per front | [`../fronts.md § Track B`](../fronts.md) rows (renumbered); read through [`modules.md § What this changes in the front READMEs`](./modules.md#what-this-changes-in-the-front-readmes) |
| 1.0.6 `fronts.md § Conflict Matrix` + notes — F01↔F03 `runtime.bp`; F04↔F06/F14/F18 chain; F05↔F17; F09↔F19; F11↔F16 | [`../fronts.md § Conflict rules`](../fronts.md#conflict-rules): F01↔F03 dissolved (04 appends one block, 06 does not touch `runtime.bp`); F04↔F06/F14/F18 → 07 owns the chain, 10/18/20 register filters; F05↔F17 → the 08/09 row; F09↔F19 and F11↔F16 dissolved by the merges into 13 and 15 |
| 1.0.6 `fronts.md § Order` | [`README.md § The fronts`](./README.md#the-fronts-in-blocking-order) |
| 1.0.6 `fronts.md § Rules for a Front` | [`../fronts.md § Carried from 1.0.6/1.0.7/1.0.8-beta`](../fronts.md#carried-from-106107108-beta--rules-for-a-front) (rule 4, *Erlang + commonJS*, superseded) |
| 1.0.7 `overview.md` front table — F09–F14 (module `rakun-core` / `rakun-cache`) | [`README.md § The fronts`](./README.md#the-fronts-in-blocking-order) rows 23 · 24 · 25 · 07 · 12 · 22; module → `rakun-app` (`rakun-web` for 07, `rakun-cache` for 12) |
| 1.0.7 `overview.md § Order` — *14 before 09* | 1.0.9 [`overview.md § Order`](../absorbed/1.0.9-beta/overview.md) (*why 22 before 23*); level 2 → 3 above |
| 1.0.7 `overview.md § Mapeamento Next.js → onze13` — rakun rows (App Router, `layout`/`page`, `route.ts`, Server Actions, Middleware, `fetch` + cache, `revalidatePath/Tag`) | [`../02-packaging/README.md § Carried from 1.0.7-beta`](../02-packaging/README.md#carried-from-107-beta--which-library-owns-each-nextjs-surface-and-convention-over-configuration) — 22 · 22/61 · 25 · 24 · 07 · 12 · 12 |
| 1.0.7 `overview.md § Estrutura de um projeto onze13` — `app/` tree, root `middleware.bp` | 22 § Problem (the tree), 22 Step 5 (`middleware.bp` location, restated in 07's carried section); the rest is [`../06-onze/`](../06-onze/) |
| 1.0.7 `fronts.md § Ownership` — F09–F14 rakun rows | [`../fronts.md § Track B`](../fronts.md) rows 22–25, 07, 12 |
| 1.0.7 `fronts.md § Conflict Matrix` — F09↔F14 (`runtime.bp`/`runtime.mjs`) | dissolved: `runtime.mjs` is frozen and 22/23 own one file each ([`../fronts.md § Conflict rules`](../fronts.md#conflict-rules)) |
| 1.0.7 `fronts.md § Cross-repo Coordination` — "rakun requires nothing new" | changed: `rakun` core still requires nothing, but `rakun-app` requires `jhonstart` and `emilia` ([`modules.md § Three facts`](./modules.md#three-facts-that-decide-the-cut)); the direction rule is [`../02-packaging/README.md § 6`](../02-packaging/README.md) |
| 1.0.7 `examples-bp.md` — F09–F14, F22 `middleware.bp` | table above |

## Reference coverage still missed — Spring Boot 4 sections

Sections of the thirteen files under `/home/ericfillipe/develop/spring-boot-4/docs/` that no rakun
front covers, verified by `grep -i` over the 51 READMEs for the section's terms (a front that names
the section in its `**Reference:**` line and then declines it counts as covered — 78 on Envers, 12 on
Caffeine, 11/75 on JMX, 08 on R2DBC). *Absorb* names the front whose `**Reference:**` line should
gain the section and whose README gains a paragraph or a refusal; nothing here is a new front.

| Section | Nearest front(s) | State | Absorb |
|---|---|---|---|
| `04-web.md § WebMvc.fn (Funcional)`, `§ WebFlux.fn (Funcional)` | 07 · 25 | no front names a programmatic route builder (`RouterFunction`); 04's decorators and 25's `route.bp` are the two registration forms | 25 — state whether a `routes()` builder over 22's table exists or is refused |
| `04-web.md § Template Engines` (Thymeleaf, FreeMarker, Mustache, Groovy) | 23 | by design the engine is jhonstart's `html` DSL rendered by 23; no README says so | 23 — one refusal line |
| `05-data.md § DataSource · Banco Embutido` (H2, HSQL, Derby), `§ H2 Web Console` | 08 · 19 · 80 | 08 mentions "Spring's embedded-database convenience" and names no engine; 19 declines Testcontainers-style services; 80 declines a database browser | 19 — an in-memory `SqlTemplate` double for slices, or 08 — refuse and name SQLite/`mnesia` as the local-dev answer |
| `05-data.md § DataSource · Lazy Connection Proxy` | 08 | absent | 08 — one line: pool checkout is per call, there is no proxy to make lazy |
| `05-data.md § Elasticsearch · Sniffer` | 09 | absent | 09 — node auto-discovery, or refuse |
| `05-data.md § Couchbase · Autenticacao com Certificado` | 09 · 74 | 09 lists the Couchbase driver; client-certificate auth through a bundle is unnamed | 09 — one row pointing at 74's bundle |
| `05-data.md § LDAP · LDAP Embutido (UnboundID)` | 79 · 19 | 79's `ldap` arm has no test double | 19 — an LDAP double beside the broker double, or 79 — refuse |
| `09-actuator.md § Monitoramento HTTP · Discovery Page` (`/actuator` root with `_links`) | 11 · 21 | 11 serves `/actuator/<id>` and names no root document | 11 — one endpoint listing the exposed ids in 21's HAL shape |
| `11-topicos-avancados.md § Apendice · Configuration Metadata` (`spring-configuration-metadata.json`, IDE completion) | 05 | absent; 05 owns the key registry the file would be generated from | 05 — emit a key manifest; a [`../language-gaps.md`](../language-gaps.md) row if the LSP needs a hook |
| `11-topicos-avancados.md § Apendice · Application Properties` (the key index) | 05 · every front's config table | keys are listed per front; no single index | 05 — the same key manifest, rendered; or `docs/` |
| `11-topicos-avancados.md § Deploy · Cloud Deployment` (Cloud Foundry, Heroku, OpenShift, AWS, Azure, Google Cloud) | 81 | 81 covers Kubernetes fragments and a container image; PaaS targets unnamed | 81 — "any OCI host" statement and a refusal for buildpack-driven PaaS, or `deferred.md § Out of scope` |
| `11-topicos-avancados.md § Deploy · Servico de SO` (init.d, Windows service) | 81 | systemd only | 81 — refuse init.d and Windows; name the OTP release's own `bin/<app>` as the daemon |
| `02-desenvolvendo-com-spring-boot.md § Estrutura do Codigo` (default package, main class location) | 88 | the only layout convention lives in 88's `rakun new` template; no rule is stated | 88 — state the generated layout as the convention |
| `06-messaging.md § JMS · JNDI ConnectionFactory`, `07-io.md § Email · JNDI Session`, `§ JTA · JNDI Locations`, `05-data.md § JNDI DataSource` | 90 · 85 · 83 · 08 | — | deferred — see [`../deferred.md § JNDI lookups`](../deferred.md) |
| `10-otimizacao-producao.md § GraalVM`, `§ AOT Cache`, `§ CDS`, `§ Checkpoint e Restore (CRaC)`; `08-container-images.md § Com AOT Cache`, `§ Com CDS` | 81 | — | deferred — see [`../deferred.md § Deferred — Spring Boot 4`](../deferred.md) |
| `01-primeiros-passos.md § Com Debug Remoto`; `10 § Tracing Agent` | 80 | — | deferred — see [`../deferred.md`](../deferred.md) (bytecode agents); 80's remote shell is the BEAM answer |
| `04-web.md § Container Servlet Embutido`, `§ Container Reativo Embutido`; `01 § Servidores Embutidos Suportados` | 04 | — | deferred — see [`../deferred.md § Servlet API surface`](../deferred.md); 04's `gen_tcp` listener is the server |
| `12-upgrading.md` (all but `§ Spring Boot CLI`) | — | — | deferred — see [`../deferred.md § Out of scope`](../deferred.md) (upgrade guides, support-window policy) |
| `04-web.md § JAX-RS (Jersey)`; `§ Kotlin` sub-sections of `01`, `02`, `03`; `03 § Virtual Threads`; `03 § Constructor Binding`; `05 § Open EntityManager in View`, `§ Bootstrapping de repositorios`; `09 § Reactive Health`; `04 § Redis Session (Reativo)`; `02 § Sistemas de Build · Maven / Gradle / Ant com Ivy` | — | not applicable: JVM APIs, a second language, JVM threading, JPA session semantics, or Maven/Gradle where `botopink.json` + `bpmp` is the build (88 · 73) | `deferred.md § Out of scope` should list JAX-RS beside the Servlet row; the rest needs no row |

