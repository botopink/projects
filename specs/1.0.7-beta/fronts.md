# Fronts — 1.0.7-beta

## Ownership

| Front | Repo | Module | Source it owns | Tests it owns |
|---|---|---|---|---|
| **F01 onze13-stand-up** | onze13 (new) | onze13-core | `repository/onze13/src/**`, `repository/onze13/botopink.json` | `repository/onze13/test/**` |
| **F02 jhonstart-router** | jhonstart | jhonstart-core | `repository/jhonstart/src/router.bp` (promote from .d.bp) | `repository/jhonstart/test/router_test.bp` |
| **F03 jhonstart-link** | jhonstart | jhonstart-core | `repository/jhonstart/src/link.bp` | `repository/jhonstart/test/link_test.bp` |
| **F04 jhonstart-server-components** | jhonstart | jhonstart-core | `repository/jhonstart/src/server.bp` (promote from .d.bp) | `repository/jhonstart/test/server_test.bp` |
| **F05 jhonstart-client-directive** | jhonstart | jhonstart-core | `repository/jhonstart/src/client.bp` | `repository/jhonstart/test/client_test.bp` |
| **F06 jhonstart-streaming** | jhonstart | jhonstart-core | `repository/jhonstart/src/streaming.bp`, `repository/jhonstart/src/suspense.bp` | `repository/jhonstart/test/streaming_test.bp` |
| **F07 jhonstart-error-boundaries** | jhonstart | jhonstart-core | `repository/jhonstart/src/error_boundary.bp` | `repository/jhonstart/test/error_boundary_test.bp` |
| **F08 jhonstart-metadata** | jhonstart | jhonstart-core | `repository/jhonstart/src/metadata.bp` | `repository/jhonstart/test/metadata_test.bp` |
| **F09 rakun-ssr-pipeline** | rakun | rakun-core | `repository/rakun/src/ssr.bp`, `repository/rakun/src/ssr.mjs` | `repository/rakun/test/ssr_test.bp` |
| **F10 rakun-server-actions** | rakun | rakun-core | `repository/rakun/src/actions.bp`, `repository/rakun/src/actions.mjs` | `repository/rakun/test/actions_test.bp` |
| **F11 rakun-route-handlers** | rakun | rakun-core | `repository/rakun/src/route_handler.bp` | `repository/rakun/test/route_handler_test.bp` |
| **F12 rakun-middleware** | rakun | rakun-core | `repository/rakun/src/middleware.bp` | `repository/rakun/test/middleware_test.bp` |
| **F13 rakun-cache** | rakun | rakun-cache | `repository/rakun/modules/rakun-cache/src/**` | `repository/rakun/modules/rakun-cache/test/**` |
| **F14 rakun-file-routing** | rakun | rakun-core | `repository/rakun/src/file_router.bp`, `repository/rakun/src/file_router.mjs` | `repository/rakun/test/file_router_test.bp` |
| **F15 emilia-attributes** | emilia | emilia-core | `repository/emilia/src/attributes.bp` | `repository/emilia/test/attributes_test.bp` |
| **F16 emilia-jhonstart-integration** | emilia + jhonstart | emilia-core | `repository/emilia/src/html_hook.bp`, `repository/jhonstart/src/html_attrs.bp` | `repository/emilia/test/integration_test.bp` |
| **F17 std-async-primitives** | std | std-core | `libs/std/src/async.bp` | `libs/std/test/async_test.bp` |
| **F18 std-crypto-hash** | std | std-core | `libs/std/src/content_hash.bp` | `libs/std/test/content_hash_test.bp` |
| **F19 onze13-cli** | onze13 | onze13-cli | `repository/onze13/modules/onze13-cli/src/**` | `repository/onze13/modules/onze13-cli/test/**` |
| **F20 onze13-image-optimization** | onze13 | onze13-core | `repository/onze13/src/image.bp` | `repository/onze13/test/image_test.bp` |
| **F21 onze13-font-optimization** | onze13 | onze13-core | `repository/onze13/src/font.bp` | `repository/onze13/test/font_test.bp` |
| **F22 onze13-example-app** | onze13 | examples | `repository/onze13/examples/blog/**` | `repository/onze13/examples/blog/test/**` |

## Conflict Matrix

|  | F01 | F02 | F03 | F04 | F05 | F06 | F07 | F08 | F09 | F10 | F11 | F12 | F13 | F14 | F15 | F16 | F17 | F18 | F19 | F20 | F21 | F22 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **F01** | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F02** | yes | — | no¹ | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F03** | yes | no¹ | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F04** | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F05** | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F06** | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F07** | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F08** | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F09** | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | no² | yes | yes | yes | yes | yes | yes | yes | yes |
| **F10** | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F11** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F12** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F13** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| **F14** | yes | yes | yes | yes | yes | yes | yes | yes | no² | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | yes |
| **F15** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | no³ | yes | yes | yes | yes | yes | yes |
| **F16** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | no³ | — | yes | yes | yes | yes | yes | yes |
| **F17** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes |
| **F18** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes |
| **F19** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes |
| **F20** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes |
| **F21** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes |
| **F22** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — |

### Conflict Notes

1. **F02 ↔ F03:** Both touch `router.d.bp`/`router.bp` (F02 promotes it to real .bp, F03 adds Link). **Sequence:** F02 first (router foundation), then F03 (Link uses router).
2. **F09 ↔ F14:** Both touch `runtime.bp`/`runtime.mjs` (F09 adds SSR pipeline, F14 adds file router). **Sequence:** F14 first (file router defines what to render), then F09 (SSR pipeline renders it).
3. **F15 ↔ F16:** Both touch emilia source (F15 adds attribute slots, F16 adds html DSL integration). **Sequence:** F15 first (attribute mechanism), then F16 (html DSL uses attributes).

## Order

```
Phase 1 (Critical Path — foundation):
  F01 ──┐
  F17 ──┴──► F02 ──┐
                F14 ─┤
                     └──► F03 · F04 · F09   (3 in parallel)

Phase 2 (Core features — 7 in parallel):
  F05 · F06 · F07 · F10 · F11 · F12 · F15

Phase 3 (Integration — 7 in parallel):
  F08 · F13 · F16 · F18 · F19 · F20 · F21

Phase 4 (Validation):
  F22
```

**Critical path:** F01 → F02 → F03/F04/F09

**Parallelism:**
- Phase 1: F01 ∥ F17, then F02 ∥ F14, then F03 ∥ F04 ∥ F09
- Phase 2: F05 ∥ F06 ∥ F07 ∥ F10 ∥ F11 ∥ F12 ∥ F15 (all independent modules)
- Phase 3: F08 ∥ F13 ∥ F16 ∥ F18 ∥ F19 ∥ F20 ∥ F21 (all independent modules)
- Phase 4: F22 (validates everything)

## Rules for a Front

1. **One worktree, one branch, one `todo.md`** — `git worktree add .tasks/<front-name> -b fix/<front-name>` from the submodule that owns the code
2. **Never edit a file you don't own** — if you need a file another front owns, stop and report
3. **Verify by running** — execute the code, drive the server, run the tests
4. **Dual-target** — every front must work on commonJS and erlang (where applicable)
5. **Land:** merge into `feat`, suite green, push, submodule bump in meta repo

## Cross-repo Coordination

Since this milestone spans 4+ repos, coordination rules:

1. **Interface contracts:** When a front in repo A exposes an API consumed by repo B, the API is documented in the front's README with exact types and signatures.
2. **Dependency order:** Consumer repos declare dependencies in `botopink.json` `requires`. onze13 requires jhonstart, rakun, emilia. jhonstart requires nothing new. rakun requires nothing new. emilia requires jhonstart (for Element type).
3. **Version pinning:** During development, `requires.<lib> = "feat"` in consumer's `botopink.json` + `bpmp sync` to preview unreleased work.
4. **Integration testing:** F22 (example app) is the integration test — it exercises all fronts together. If it fails, the failing front's owner fixes it.
