# rakun — what no front covers yet

**Track:** B — rakun · **Cut:** [`modules.md`](./modules.md) · **Order:** [`README.md`](./README.md) · **Top-level rows:** [`../unification.md`](../unification.md)

Two ledgers of remaining work. A row is a candidate for a fold-in to the named front, not a new
front.

## Features no front covers

Upstream features no rakun front covers, verified by `grep -ril` over the 51 READMEs.

| Feature (upstream) | Nearest front | State |
|---|---|---|
| Spring Cloud Vault / encrypted property sources | 05 | out of scope; nowhere restated |
| `env.vars()` as the environment reader; "configured `server.port` beats `App.port`" | 05 · 04 | 05 names `env.args()` and `env.write` only; 04 names `rakun.server.port` only in its failure table |
| `ContextRefreshedEvent`, a shutdown-time event (`ContextClosedEvent`) | 06 | 06's nine-event list has neither; shutdown publishes no event |
| `SIGINT` handling beside `SIGTERM` | 06 · 07 · 76 · 88 | only `SIGTERM` appears |
| Request/access logging filter (`CommonsRequestLoggingFilter`), `X-Response-Time` timing filter, per-filter enable keys | 07 · 17 · 75 | 75 ships the `http.server.requests` timer, no header; 07 defines no built-in filter set |
| `ProblemDetail.typeUri` → wire member `type` (RFC 9457 § 3.1); the request-id header name, honour-incoming and echo-on-response rules | 07 · 17 | the serializer mapping is unstated; the order band has "request id" at −400 with no header name (`X-Request-Id` appears only in `examples/filter-chain-example.bp`) |
| `spring.datasource.username` / `.password` keys | 08 | 08 names only `rakun.datasource.url` and `.pool.size` |
| `@PostAuthorize`, `@EnableWebSecurity`, `JwtDecoder`, `SecurityContextRepository` | 10 | 10 declines only `@PreAuthorize`; no named verification entry point |
| `management.health.diskspace.threshold` | 11 | `diskSpace` named, no threshold or key |
| `build.buildTime` and `profile` info keys | 11 | absent from `build`/`otp`/`os`/`process`; `env` reads only `info.*` |
| `@CachePut`; `CacheManager.getCacheNames()` / programmatic `Cache` handle; EhCache in the declined-provider list | 12 | `#[cachePut]` neither shipped nor declined |
| `ClientHttpRequestInterceptor` chain; `ResponseSpec.onStatus`; HTTP client retry | 13 | front 79 assumes an interceptor seam 13 never defines |
| `.uri("/users/{id}", [id])` templates on `RequestSpec`; automatic `Content-Type` on a bodied request | 13 | `RestClient.get(path)` takes a finished path — `:param` substitution exists only inside `#[httpExchange]`; no default content type named |
| `RabbitTemplate.receive` (synchronous pull); `convertAndSend` / typed conversion | 15 | 15 declares conversion out of scope; pull has no owner |
| `KafkaTemplate.sendDefault`; explicit partition on produce; key→partition ordering guarantee | 15 | |
| `@EnableScheduling` | 16 | implicit in `#[scheduler]`, never named |
| `parseCron(expr) -> CronExpression` as a public name | 16 · 84 | 16 calls the parser "an ordinary compiled function" and names neither it nor a `CronExpression` type; 84 depends on "the cron parser this reuses" |
| Log4j2 | 17 | Logback → `sys.config` is mapped; Log4j2 nowhere |
| `@EnableRedisHttpSession` / `@EnableJdbcHttpSession` | 18 | |
| The session filter's marker, order and signature | 18 · 07 | 18 says "ordered before authentication" and names no marker, no order value and no `FilterChain` signature |
| `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest` names | 19 | slices and whole-context boot covered conceptually, names unmapped |
| `MongoTemplate` / `RedisTemplate` / `ElasticsearchTemplate`; `eredis_cluster`; by-filter `update`/`delete`; one application holding two store arms at once | 09 | 09's stores are by-id only; `rakun.nosql.url` selects one arm |
| `@ServerEndpoint` mapping; `onError(session, error)` | 20 | renamed `#[wsEndpoint]` without the mapping; a raising handler closes with `1011` and the handler is never told |
| `bodyToMono`/`bodyToFlux`; a streamed response body (`@FutureGenerator<string, E>`, decision 103) | 13 | `ClientResponse.body` is one `string`; no chunked or iterated body for a large or server-sent response |
| `CollectionModel` / `EntityModel`; `Link.name`; `Links(self: Link, others)` — a type-level required `self` | 21 | `RepresentationModel` named, the collection type not; `Array<Link>` carries no guarantee that `self` is present |
| `Accept: text/html` content negotiation between a `P` route and an `R` route | 22 · 25 | both decide by table kind only |
| `<!DOCTYPE html>` / `<title>` assertion on the finished document | 23 · 32 | no acceptance asserts either from 23's side |
| Server action `GET` answer (405 vs 404) | 24 | undecided |
| `HandlerResponse.noContent()` for a `DELETE` handler | 25 | no example exercises it |
| Multiple matchers per middleware entry | 07 · 65 | 65 defines the grammar, not a list per entry |
| Middleware ordering relative to `matchPath` | 07 | chain sits inside `dispatch_http/5`; before/after unstated |
| Upstream URLs `…/building-your-application/rendering`, `…/guides/server-actions`, `…/getting-started/caching`, `…/getting-started/revalidating`, `…/getting-started/proxy` | 23 · 24 · 12 · 60 · 65 | content covered, URL uncited |

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
