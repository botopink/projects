# Specs — 1.0.6-beta (Rakun: Spring Boot 4 em Botopink/Erlang)

O milestone 1.0.6-beta transforma o Rakun de um framework básico de IoC + REST (commonJS-only) em um framework completo estilo Spring Boot 4, focado em Erlang/BEAM para serviços de produção. O Rakun será subdividido em múltiplos módulos mantidos no mesmo repositório (`repository/rakun/modules/`), cada um cobrindo uma área específica do ecossistema Spring Boot.

| Front | Prioridade | Módulo | Descrição |
|---|---|---|---|
| [`01-erlang-runtime/`](./01-erlang-runtime/README.md) | **critical** | rakun-core | Runtime Erlang equivalente ao runtime.mjs (DI, router, HTTP server via cowboy) |
| [`02-config-profiles/`](./02-config-profiles/README.md) | **critical** | rakun-core | Configuração externalizada (YAML, env vars, profiles, @Value melhorado) |
| [`03-context-api/`](./03-context-api/README.md) | **high** | rakun-core | Context API completa (resolve<T>(), scopes, lifecycle, events) |
| [`04-web-middleware/`](./04-web-middleware/README.md) | **high** | rakun-web | Middleware/Filter chain, CORS, error handling (RFC 9457) |
| [`05-data-sql/`](./05-data-sql/README.md) | **high** | rakun-data | DataSource abstraction, PostgreSQL/MySQL, connection pooling |
| [`06-security-auth/`](./06-security-auth/README.md) | **high** | rakun-security | Authentication/Authorization, JWT, Basic Auth, roles |
| [`07-actuator-health/`](./07-actuator-health/README.md) | **medium** | rakun-actuator | Health endpoints, info, metrics básicos |
| [`08-cache-abstraction/`](./08-cache-abstraction/README.md) | **medium** | rakun-cache | @Cacheable, @CacheEvict, in-memory + Redis |
| [`09-rest-client/`](./09-rest-client/README.md) | **medium** | rakun-client | RestClient equivalente (HTTP client fluente) |
| [`10-validation/`](./10-validation/README.md) | **medium** | rakun-validation | Bean validation decorators (@NotNull, @Size, etc.) |
| [`11-messaging-amqp/`](./11-messaging-amqp/README.md) | **medium** | rakun-messaging | AMQP/RabbitMQ (@RabbitListener, RabbitTemplate) |
| [`12-scheduling/`](./12-scheduling/README.md) | **medium** | rakun-scheduling | @Scheduled, cron expressions, task executor |
| [`13-logging-structured/`](./13-logging-structured/README.md) | **low** | rakun-logging | Structured logging, log levels, log groups |
| [`14-session-management/`](./14-session-management/README.md) | **low** | rakun-session | Session management, in-memory store |
| [`15-test-utilities/`](./15-test-utilities/README.md) | **low** | rakun-test | MockMvc, test slices, test utilities |
| [`16-messaging-kafka/`](./16-messaging-kafka/README.md) | **low** | rakun-messaging | Kafka (@KafkaListener, KafkaTemplate) |
| [`17-data-nosql/`](./17-data-nosql/README.md) | **low** | rakun-data | MongoDB, Redis, Elasticsearch |
| [`18-web-websocket/`](./18-web-websocket/README.md) | **low** | rakun-web | WebSocket support |
| [`19-web-client-reactive/`](./19-web-client-reactive/README.md) | **low** | rakun-client | WebClient (reativo) |
| [`20-hateoas/`](./20-hateoas/README.md) | **low** | rakun-hateoas | Hypermedia (HAL, links) |

## Order

```
01-erlang-runtime ──┐
02-config-profiles ─┤
                    └──► 03-context-api ──┐
                                          ├──► 04-web-middleware ──┐
                                          │                        ├──► 06-security-auth
                                          │                        │
                                          ├──► 05-data-sql ────────┤
                                          │                        │
                                          └──► 07-actuator-health ─┘
                                                                    │
08-cache-abstraction ───────────────────────────────────────────────┤
09-rest-client ─────────────────────────────────────────────────────┤
10-validation ──────────────────────────────────────────────────────┤
11-messaging-amqp ──────────────────────────────────────────────────┤
12-scheduling ──────────────────────────────────────────────────────┤
13-logging-structured ──────────────────────────────────────────────┘
                                                                    │
14-session-management ──────────────────────────────────────────────┤
15-test-utilities ──────────────────────────────────────────────────┤
16-messaging-kafka ─────────────────────────────────────────────────┤
17-data-nosql ──────────────────────────────────────────────────────┤
18-web-websocket ───────────────────────────────────────────────────┤
19-web-client-reactive ─────────────────────────────────────────────┤
20-hateoas ─────────────────────────────────────────────────────────┘
```

**Fase 1 (Critical Path):** `01` + `02` (paralelo) → `03` → `04` + `05` + `07` (paralelo) → `06`

**Fase 2 (Parallel):** `08`–`13` podem rodar em paralelo após Fase 1

**Fase 3 (Parallel):** `14`–`20` podem rodar em paralelo após Fase 2

**Por que 01-erlang-runtime é primeiro:** Sem o runtime Erlang, nenhum outro módulo pode ser testado em BEAM. O runtime.mjs atual é Node.js-only e todos os `rk*` host cells usam `@External.Node`. O runtime.erl é a fundação sobre a qual todos os outros módulos serão construídos e testados.

**Por que 02-config-profiles é crítico:** Spring Boot's power vem da configuração externalizada. Sem profiles e YAML, aplicações reais não podem ser configuradas para diferentes ambientes (dev, test, prod).

## Regras do Milestone

- **Multi-módulo:** Cada funcionalidade Spring Boot vira um módulo separado em `repository/rakun/modules/<nome>/`
- **Erlang-first:** Todos os módulos devem ter runtime.erl (não apenas .mjs)
- **Decorator-based:** Seguir o padrão existente (`#[decorator]`) para todas as anotações
- **IoC integration:** Todos os módulos se integram com o container IoC
- **Test coverage:** Cada módulo tem testes em commonJS E erlang
- **No compiler changes:** O compiler core não conhece rakun — tudo é plain botopink + @Decl + comptime + @emit
- **Std lib reuse:** Usar módulos da std (json, http, fs, env, crypto, etc.) quando possível

## Estrutura de Módulos

```
repository/rakun/
├── src/                          # rakun-core (existing, enhanced)
│   ├── decorators.bp
│   ├── http.bp
│   ├── runtime.bp
│   ├── runtime.mjs
│   ├── runtime.erl               # NEW: Erlang runtime
│   ├── bootstrap.bp
│   ├── config.bp                 # NEW: externalized config
│   ├── context.bp                # NEW: Context API
│   └── events.bp                 # NEW: application events
├── modules/                      # NEW: subdivided modules
│   ├── rakun-web/                # middleware, CORS, error handling, websocket
│   ├── rakun-data/               # SQL + NoSQL
│   ├── rakun-security/           # auth, JWT, roles
│   ├── rakun-actuator/           # health, metrics, info
│   ├── rakun-cache/              # caching abstraction
│   ├── rakun-client/             # REST clients
│   ├── rakun-validation/         # bean validation
│   ├── rakun-messaging/          # AMQP, Kafka
│   ├── rakun-scheduling/         # @Scheduled
│   ├── rakun-logging/            # structured logging
│   ├── rakun-session/            # session management
│   ├── rakun-test/               # test utilities
│   └── rakun-hateoas/            # hypermedia
└── examples/                     # example apps using modules
```

## Mapeamento Spring Boot 4 → Rakun

| Spring Boot 4 | Rakun Module | Status |
|---|---|---|
| SpringApplication, AutoConfiguration | rakun-core | ✅ Existing + Enhanced |
| Externalized Config, Profiles | rakun-core | 🔨 Front 02 |
| Web (MVC, WebFlux) | rakun-web | 🔨 Front 04, 18 |
| Data (SQL, NoSQL) | rakun-data | 🔨 Front 05, 17 |
| Security | rakun-security | 🔨 Front 06 |
| Actuator | rakun-actuator | 🔨 Front 07 |
| Cache | rakun-cache | 🔨 Front 08 |
| REST Clients | rakun-client | 🔨 Front 09, 19 |
| Validation | rakun-validation | 🔨 Front 10 |
| Messaging (JMS, AMQP, Kafka) | rakun-messaging | 🔨 Front 11, 16 |
| Scheduling (Quartz) | rakun-scheduling | 🔨 Front 12 |
| Logging | rakun-logging | 🔨 Front 13 |
| Session | rakun-session | 🔨 Front 14 |
| Test | rakun-test | 🔨 Front 15 |
| HATEOAS | rakun-hateoas | 🔨 Front 20 |
| Erlang/BEAM Runtime | rakun-core | 🔨 Front 01 |
