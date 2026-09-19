# Fronts — 1.0.6-beta

## Ownership

| Front | Module | Source it owns | Tests it owns |
|---|---|---|---|
| **F01 erlang-runtime** | rakun-core | `src/runtime.erl`, `src/runtime.bp` (add @External.Erlang) | `test/erlang_runtime_test.bp` |
| **F02 config-profiles** | rakun-core | `src/config.bp`, `src/config.erl`, `src/config.mjs` | `test/config_test.bp` |
| **F03 context-api** | rakun-core | `src/context.bp`, `src/events.bp`, `src/lifecycle.bp` | `test/context_test.bp`, `test/events_test.bp` |
| **F04 web-middleware** | rakun-web | `modules/rakun-web/src/**` | `modules/rakun-web/test/**` |
| **F05 data-sql** | rakun-data | `modules/rakun-data/src/sql/**` | `modules/rakun-data/test/sql/**` |
| **F06 security-auth** | rakun-security | `modules/rakun-security/src/**` | `modules/rakun-security/test/**` |
| **F07 actuator-health** | rakun-actuator | `modules/rakun-actuator/src/**` | `modules/rakun-actuator/test/**` |
| **F08 cache-abstraction** | rakun-cache | `modules/rakun-cache/src/**` | `modules/rakun-cache/test/**` |
| **F09 rest-client** | rakun-client | `modules/rakun-client/src/rest.bp` | `modules/rakun-client/test/rest_test.bp` |
| **F10 validation** | rakun-validation | `modules/rakun-validation/src/**` | `modules/rakun-validation/test/**` |
| **F11 messaging-amqp** | rakun-messaging | `modules/rakun-messaging/src/amqp/**` | `modules/rakun-messaging/test/amqp/**` |
| **F12 scheduling** | rakun-scheduling | `modules/rakun-scheduling/src/**` | `modules/rakun-scheduling/test/**` |
| **F13 logging-structured** | rakun-logging | `modules/rakun-logging/src/**` | `modules/rakun-logging/test/**` |
| **F14 session-management** | rakun-session | `modules/rakun-session/src/**` | `modules/rakun-session/test/**` |
| **F15 test-utilities** | rakun-test | `modules/rakun-test/src/**` | `modules/rakun-test/test/**` |
| **F16 messaging-kafka** | rakun-messaging | `modules/rakun-messaging/src/kafka/**` | `modules/rakun-messaging/test/kafka/**` |
| **F17 data-nosql** | rakun-data | `modules/rakun-data/src/nosql/**` | `modules/rakun-data/test/nosql/**` |
| **F18 web-websocket** | rakun-web | `modules/rakun-web/src/websocket/**` | `modules/rakun-web/test/websocket/**` |
| **F19 web-client-reactive** | rakun-client | `modules/rakun-client/src/webclient.bp` | `modules/rakun-client/test/webclient_test.bp` |
| **F20 hateoas** | rakun-hateoas | `modules/rakun-hateoas/src/**` | `modules/rakun-hateoas/test/**` |

## Conflict Matrix

|  | F01 | F02 | F03 | F04 | F05 | F06 | F07 | F08 | F09 | F10 | F11 | F12 | F13 | F14 | F15 | F16 | F17 | F18 | F19 | F20 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **F01** | — | yes | no¹ | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F02** | yes | — | no¹ | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F03** | no¹ | no¹ | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F04** | yes | yes | yes | — | yes | no² | yes | yes | yes | yes | yes | yes | yes | no² | yes | yes | yes | no² | yes | yes |
| **F05** | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | no³ | yes | yes | yes |
| **F06** | yes | yes | yes | no² | yes | — | yes | yes | yes | yes | yes | yes | yes | no² | yes | yes | yes | no² | yes | yes |
| **F07** | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F08** | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F09** | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | no⁴ | yes |
| **F10** | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F11** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | no⁵ | yes | yes | yes | yes |
| **F12** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes |
| **F13** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes |
| **F14** | yes | yes | yes | no² | yes | no² | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | no² | yes | yes |
| **F15** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes |
| **F16** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | no⁵ | yes | yes | yes | yes | — | yes | yes | yes | yes |
| **F17** | yes | yes | yes | yes | no³ | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes |
| **F18** | yes | yes | yes | no² | yes | no² | yes | yes | yes | yes | yes | yes | yes | no² | yes | yes | yes | — | yes | yes |
| **F19** | yes | yes | yes | yes | yes | yes | yes | yes | no⁴ | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes |
| **F20** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — |

### Conflict Notes

1. **F01 ↔ F03:** Both touch `src/runtime.bp` (F01 adds @External.Erlang, F03 adds Context API). **Sequence:** F01 first, then F03.
2. **F04 ↔ F06, F14, F18:** Both touch middleware chain. **Merge:** F06/F14/F18 define middleware interfaces in their own modules; F04 provides the chain infrastructure. No actual conflict if interfaces are clean.
3. **F05 ↔ F17:** Both in `rakun-data`. **Sequence:** F05 first (SQL foundation), then F17 (NoSQL builds on data abstraction).
4. **F09 ↔ F19:** Both in `rakun-client`. **Sequence:** F09 first (RestClient), then F19 (WebClient builds on client abstraction).
5. **F11 ↔ F16:** Both in `rakun-messaging`. **Sequence:** F11 first (AMQP foundation), then F16 (Kafka builds on messaging abstraction).

## Order

```
Phase 1 (Critical Path):
  F01 ──┐
  F02 ──┴──► F03 ──┐
                   ├──► F04 ──┐
                   │          ├──► F06
                   ├──► F05 ──┤
                   │          │
                   └──► F07 ──┘

Phase 2 (Parallel):
  F08 · F09 · F10 · F11 · F12 · F13

Phase 3 (Parallel):
  F14 · F15 · F16 · F17 · F18 · F19 · F20
```

**Critical path:** F01 → F03 → F04/F05/F07 → F06

**Parallelism:**
- Phase 1: F01 ∥ F02, then F03, then F04 ∥ F05 ∥ F07, then F06
- Phase 2: F08 ∥ F09 ∥ F10 ∥ F11 ∥ F12 ∥ F13 (all independent modules)
- Phase 3: F14 ∥ F15 ∥ F16 ∥ F17 ∥ F18 ∥ F19 ∥ F20 (all independent modules)

## Rules for a Front

1. **One worktree, one branch, one `todo.md`** — `git worktree add .tasks/<front-name> -b fix/<front-name>`
2. **Never edit a file you don't own** — if you need a file another front owns, stop and report
3. **Verify by running** — execute the code, drive the server, run the tests
4. **Erlang + commonJS** — every front must work on both targets
5. **Land:** merge into `feat`, suite green, push, submodule bump in meta repo
