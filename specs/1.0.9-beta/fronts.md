# Fronts — 1.0.9-beta: who may touch what, when

The overview says *what* each front delivers; this says *who owns which file*. A front is one
worktree (`.tasks/<name>`), one branch, one `TODO.md`, one owner. Two fronts may run at the same
time only when they share no source file and no snapshot directory. In this milestone the trap is
not the compiler — no front touches it — it is `repository/emilia/src/tokens.bp`, which sixteen
fronts write to, and `repository/rakun/src/`, which eight fronts write to. Both are handled below,
and neither is handled by hoping.

Paths are relative to the repository named in the row.

## Ownership

### Track A — std (`repository/botopink-lang/libs/std/`)

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F01 std-lib-enablement** | New: `src/net.bp`, `src/clock.bp`, `src/encoding.bp`, `src/hmac.bp`, `src/escape.bp`. Extended: `src/path.bp`, `src/random.bp`, `src/regex.bp`, `src/process.bp`, `src/time.bp`, `src/crypto.bp`, `src/base64.bp`, `src/querystring.bp`, `src/url.bp`. Plus `src/root.bp` (exports only) | inline `test` blocks at the foot of each `src/*.bp` it owns |
| **F02 std-async-primitives** | `src/async.bp` | inline `test` blocks in `src/async.bp` |
| **F03 std-content-hash** | `src/content_hash.bp` | inline `test` blocks in `src/content_hash.bp` |

`src/root.bp` is the one shared file in track A. F01 owns it; F02 and F03 hand F01 their export
lines rather than editing it, and F01 lands last of the three.

**Two corrections that came out of writing front 01, and that the rest of the milestone depends on.**

std is not empty. Nineteen of the fifty primitives the milestone needs already exist — `path.bp` is
a complete posix calculator, `regex.bp` already wraps `re:run/3`, `crypto.bp` has SHA-256/512 and
HMAC-SHA256, `time.bp` has both clocks and RFC-3339 formatting, `base64.bp` has the url-safe
alphabet. Front 01 therefore **extends** those files rather than shipping parallel copies beside
them, which is why they appear in its ownership row. Seven absences are the ones that actually block
the milestone: no socket at all, no directory walk, no child process, no percent-encoding, no
constant-time compare, no base64url of a raw digest, and no HTML escaping.

std tests are **inline**, not in `test/`. `libs/std/AGENTS.md` is explicit that `test/` compiles
against the ambient global environment with no module import path, so a file there cannot reach the
module it would be testing. Every real std test sits in a `test` block at the foot of its own
`src/*.bp`. Any front adding to std follows that, and an earlier draft of this table that assigned
nine `test/*.bp` files to front 01 was wrong.

### Track B — rakun (`repository/rakun/`)

| Front | Module | Source it owns | Tests it owns |
|---|---|---|---|
| **F04 erlang-runtime** | rakun-core | `src/runtime.erl`, `src/sidecars/runtime.erl`, `src/runtime.bp` (`#[@external(erlang)]` block only), **`botopink.json`** (the `targets` list) | `test/erlang_runtime_test.bp` |
| **F05 config-profiles** | rakun-core | `src/config.bp`, `src/config.erl`, `src/config.mjs`, `src/profiles.bp` | `test/config_test.bp` |
| **F06 context-api** | rakun-core | `src/context.bp`, `src/events.bp`, `src/lifecycle.bp` | `test/context_test.bp`, `test/events_test.bp` |
| **F07 middleware** | rakun-web | `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` | `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp` |
| **F08 data-sql** | rakun-data | `modules/rakun-data/src/datasource.bp`, `src/sql/**` | `modules/rakun-data/test/sql/**` |
| **F09 data-nosql** | rakun-data | `modules/rakun-data/src/nosql/**` | `modules/rakun-data/test/nosql/**` |
| **F10 security-auth** | rakun-security | `modules/rakun-security/src/**` | `modules/rakun-security/test/**` |
| **F11 actuator** | rakun-actuator | `modules/rakun-actuator/src/**` | `modules/rakun-actuator/test/**` |
| **F12 cache** | rakun-cache | `modules/rakun-cache/src/**` | `modules/rakun-cache/test/**` |
| **F13 http-clients** | rakun-client | `modules/rakun-client/src/**` | `modules/rakun-client/test/**` |
| **F14 validation** | rakun-validation | `modules/rakun-validation/src/**` | `modules/rakun-validation/test/**` |
| **F15 messaging** | rakun-messaging | `modules/rakun-messaging/src/**` | `modules/rakun-messaging/test/**` |
| **F16 scheduling** | rakun-scheduling | `modules/rakun-scheduling/src/**` | `modules/rakun-scheduling/test/**` |
| **F17 logging** | rakun-logging | `modules/rakun-logging/src/**` | `modules/rakun-logging/test/**` |
| **F18 session** | rakun-session | `modules/rakun-session/src/**` | `modules/rakun-session/test/**` |
| **F19 test-utilities** | rakun-test | `modules/rakun-test/src/**` | `modules/rakun-test/test/**` |
| **F20 websocket** | rakun-web | `modules/rakun-web/src/websocket/**` | `modules/rakun-web/test/websocket/**` |
| **F21 hateoas** | rakun-hateoas | `modules/rakun-hateoas/src/**` | `modules/rakun-hateoas/test/**` |
| **F22 file-routing** | rakun-core | `src/file_router.bp`, `src/file_router.mjs`, `src/file_router.erl` | `test/file_router_test.bp` |
| **F23 ssr-pipeline** | rakun-core | `src/ssr.bp`, `src/ssr.mjs`, `src/ssr.erl` | `test/ssr_test.bp` |
| **F24 server-actions** | rakun-core | `src/actions.bp`, `src/actions.mjs`, `src/actions.erl` | `test/actions_test.bp` |
| **F25 route-handlers** | rakun-core | `src/route_handler.bp` | `test/route_handler_test.bp` |

| **F60 static-generation** | rakun-core | `src/static_gen.bp` | `test/static_gen_test.bp` |
| **F61 parallel-intercepting-routes** | rakun-core | `src/parallel_routes.bp` | `test/parallel_routes_test.bp` |
| **F62 request-context** | rakun-core | `src/request_context.bp` | `test/request_context_test.bp` |
| **F63 navigation-signals** | rakun-core | `src/navigation.bp` | `test/navigation_test.bp` |
| **F64 i18n-routing** | rakun-core | `src/i18n.bp` | `test/i18n_test.bp` |
| **F65 url-rules** | rakun-core | `src/url_rules.bp` | `test/url_rules_test.bp` |
| **F66 metadata-file-routes** | rakun-core | `src/metadata_routes.bp` | `test/metadata_routes_test.bp` |
| **F72 auto-configuration** | rakun-core | `src/autoconfig.bp`, `src/conditions.bp` | `test/autoconfig_test.bp` |
| **F73 starters** | rakun-starters | `modules/rakun-starters/**` | `modules/rakun-starters/test/**` |
| **F74 tls-ssl-bundles** | rakun-core | `src/ssl_bundles.bp` | `test/ssl_bundles_test.bp` |
| **F75 observability-metrics** | rakun-observability | `modules/rakun-observability/src/**` | `modules/rakun-observability/test/**` |
| **F76 actuator-security-probes** | rakun-actuator | `modules/rakun-actuator/src/security/**`, `src/probes/**` | `modules/rakun-actuator/test/security/**` |
| **F77 db-migrations** | rakun-data | `modules/rakun-data/src/migrate/**` | `modules/rakun-data/test/migrate/**` |
| **F78 orm-entities** | rakun-data | `modules/rakun-data/src/orm/**` | `modules/rakun-data/test/orm/**` |
| **F79 oauth2-sso** | rakun-security | `modules/rakun-security/src/oauth2/**`, `src/ldap/**` | `modules/rakun-security/test/oauth2/**` |
| **F80 devtools** | rakun-devtools | `modules/rakun-devtools/src/**` | `modules/rakun-devtools/test/**` |
| **F81 packaging-release** | rakun-packaging | `modules/rakun-packaging/**` | `modules/rakun-packaging/test/**` |
| **F82 static-assets** | rakun-web | `modules/rakun-web/src/static/**` | `modules/rakun-web/test/static/**` |
| **F83 distributed-transactions** | rakun-data | `modules/rakun-data/src/tx/**` | `modules/rakun-data/test/tx/**` |
| **F84 persistent-jobs** | rakun-scheduling | `modules/rakun-scheduling/src/persistent/**` | `modules/rakun-scheduling/test/persistent/**` |
| **F85 mail** | rakun-mail | `modules/rakun-mail/src/**` | `modules/rakun-mail/test/**` |
| **F86 messaging-reliability** | rakun-messaging | `modules/rakun-messaging/src/reliability/**` | `modules/rakun-messaging/test/reliability/**` |
| **F87 audit-and-exchanges** | rakun-actuator | `modules/rakun-actuator/src/audit/**` | `modules/rakun-actuator/test/audit/**` |
| **F88 cli** | rakun-cli | `modules/rakun-cli/**` | `modules/rakun-cli/test/**` |
| **F89 stream-pipelines** | rakun-messaging | `modules/rakun-messaging/src/streams/**` | `modules/rakun-messaging/test/streams/**` |
| **F90 jms-brokers** | rakun-messaging | `modules/rakun-messaging/src/jms/**` | `modules/rakun-messaging/test/jms/**` |
| **F91 pulsar** | rakun-messaging | `modules/rakun-messaging/src/pulsar/**` | `modules/rakun-messaging/test/pulsar/**` |
| **F92 rsocket** | rakun-rsocket | `modules/rakun-rsocket/**` | `modules/rakun-rsocket/test/**` |
| **F93 soap-webservices** | rakun-soap | `modules/rakun-soap/**` | `modules/rakun-soap/test/**` |

`repository/rakun/botopink.json` today declares `"targets": ["commonJS"]`. Until front 04 adds
`"erlang"` to it, **no rakun front can have a green erlang row** — which would make the exit gate
unfalsifiable for the whole of track B. That one-line change is front 04's, and it is why the
manifest is in its ownership row.

Front 22 also owns the host registration cell that puts a route handler into the app
(`rkAppRegisterHandler`, generic over the response type). That is what keeps front 25 free of host
cells and true to its single-file ownership below.

Four files in `repository/rakun/src/` are **frozen for the whole milestone**: `decorators.bp`,
`http.bp`, `bootstrap.bp`, `runtime.mjs`. A front that believes it needs one of them stops and says
so in its README under *Blocked*; it does not edit them. The exception is F04, which appends an
`#[@external(erlang)]` block to `runtime.bp` and touches nothing else in that file.

### Track C — jhonstart (`repository/jhonstart/`)

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F26 router** | `src/router.bp` (promoted from `router.d.bp`) | `test/router_test.bp` |
| **F27 link** | `src/link.bp` | `test/link_test.bp` |
| **F28 server-components** | `src/server.bp` (promoted from `server.d.bp`) | `test/server_test.bp` |
| **F29 client-directive** | `src/client.bp` | `test/client_test.bp` |
| **F30 streaming** | `src/streaming.bp`, `src/suspense.bp` | `test/streaming_test.bp` |
| **F31 error-boundaries** | `src/error_boundary.bp` | `test/error_boundary_test.bp` |
| **F32 metadata** | `src/metadata.bp` | `test/metadata_test.bp` |

| **F67 forms** | `src/forms.bp` | `test/forms_test.bp` |

`src/element.bp`, `src/hooks.bp` and `src/html.bp` are frozen. F48 is the only front that adds to
the element attribute path, and it does so in its own file.

### Track D — emilia (`repository/emilia/`)

| Front | Token sections it owns | Dispatcher it owns | Tests it owns |
|---|---|---|---|
| **F33 color-palette** | `Color`, `Bg.Color` | `colorTokenToCss` | `test/colors_test.bp` |
| **F34 modifiers** | modifier variants only | modifier wrap in `tokenToCss` | `test/modifiers_test.bp` |
| **F35 spacing-sizing** | `Pad`, `Margin`, `Size`, `Space` | `padTokenToCss`, `marginTokenToCss`, `sizeTokenToCss` | `test/spacing_test.bp` |
| **F36 layout** | `Layout` | `layoutTokenToCss` | `test/layout_test.bp` |
| **F37 grid** | `Grid`, `Flex`, `Gap` | `gridTokenToCss`, `flexTokenToCss` | `test/grid_test.bp`, `test/flexbox_test.bp` |
| **F38 typography** | `Text`, `Font`, `List` | `textTokenToCss`, `fontTokenToCss` | `test/typography_test.bp` |
| **F39 backgrounds** | `Bg` (non-colour), `Gradient` | `bgTokenToCss` | `test/backgrounds_test.bp` |
| **F40 borders** | `Border`, `Outline`, `Ring`, `Divide` | `borderTokenToCss` | `test/borders_test.bp` |
| **F41 effects** | `Effect`, `Blend`, `Mask` | `effectTokenToCss` | `test/effects_test.bp` |
| **F42 filters** | `Filter`, `Backdrop` | `filterTokenToCss` | `test/filters_test.bp` |
| **F43 tables** | `Table` | `tableTokenToCss` | `test/tables_test.bp` |
| **F44 transitions** | `Transition`, `Animate` | `transitionTokenToCss` | `test/transitions_test.bp` |
| **F45 transforms** | `Transform` | `transformTokenToCss` | `test/transforms_test.bp` |
| **F46 interactivity** | `Interact` | `interactTokenToCss` | `test/interactivity_test.bp` |
| **F47 svg-accessibility** | `Svg`, `A11y` | `svgTokenToCss`, `a11yTokenToCss` | `test/svg_a11y_test.bp` |
| **F48 attributes** | — | — | `test/attributes_test.bp`, `test/integration_test.bp` |

| **F54 theme** | — (no token section) | `src/theme.bp`, `src/spacing.bp` | `test/theme_test.bp`, `test/spacing_test.bp` |
| **F55 preflight** | — | `src/preflight.bp` | `test/preflight_test.bp` |
| **F56 cascade-and-output** | — | `src/output.bp` + the `flush`/`register` half of `src/emilia.bp` | `test/output_test.bp`, `test/cascade_test.bp` |
| **F57 escape-hatches** | `Arb` | `src/arbitrary.bp` | `test/arbitrary_test.bp` |
| **F58 container-queries** | `Container` | `src/container.bp` | `test/container_test.bp` |
| **F59 custom-utilities-and-variants** | — | `src/compose.bp` | `test/compose_test.bp` |

Fronts 54, 55, 56 and 59 add no token section and no `tokenToCss` arm, which is what lets them run
alongside all sixteen token fronts. They are the ones the token fronts consume: 54 supplies the
scales, 56 supplies the rule model every modifier and animation emits through.

**How sixteen fronts share `tokens.bp` and `emilia.bp`.** They do not merge into the same lines. The
rule is one variant block per front in `tokens.bp` and one sub-dispatcher per front in `emilia.bp`,
each fenced by a comment banner naming its front, and each appended at the end of its file rather
than interleaved. The only genuinely shared lines are the arms each front adds to the top-level `tokenToCss` `case` —
**one block per front**, added in front-number order. Most fronts add one arm; fronts 41, 42 and 47
each own two top-level sections (`Effect`/`Blend`/`Mask`, `Filter`/`Backdrop`, `Svg`/`A11y`) and add
two. Front-number ordering still makes the merged result deterministic. A front that has to edit
another front's block has found a design error, not a merge conflict, and files it as such.

F48 owns `repository/emilia/src/attributes.bp` and `repository/emilia/src/html_hook.bp`, plus
`repository/jhonstart/src/html_attrs.bp` — the single cross-repo front in the milestone. It touches
no token section and no dispatcher, which is what makes it safe to run alongside all fifteen others.

### Track E — onze13 (`repository/onze13/`, new)

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F49 stand-up** | `botopink.json`, `src/root.bp`, `src/types.bp`, `src/config.bp`, `src/integration.bp` | `test/config_test.bp`, `test/types_test.bp` |
| **F50 cli** | `modules/onze13-cli/src/**` | `modules/onze13-cli/test/**` |
| **F51 image** | `src/image.bp` | `test/image_test.bp` |
| **F52 font** | `src/font.bp` | `test/font_test.bp` |
| **F53 example-app** | `examples/blog/**` | `examples/blog/test/**` |

| **F68 client-bundle** | `modules/onze13-bundler/src/**` | `modules/onze13-bundler/test/**` |
| **F69 styling-pipeline** | `src/styling.bp` | `test/styling_test.bp` |
| **F70 image-response** | `src/image_response.bp` | `test/image_response_test.bp` |
| **F71 release-packaging** | `modules/onze13-release/**` | `modules/onze13-release/test/**` |

## Conflict rules

Rather than a 53×53 matrix that nobody reads, the rule is stated once and the exceptions are listed.

**The rule.** Two fronts conflict when they write the same file. Track A, B, C and E fronts own
disjoint files by construction, so within those tracks nothing conflicts. Track D fronts share two
files by design and are made disjoint by the banner convention above.

**The exceptions, in full.**

| Pair | Shared file | Resolution |
|---|---|---|
| F01 · F02 · F03 | `libs/std/src/root.bp` | F01 owns it; F02 and F03 land first and hand F01 their export lines |
| F07 · F20 | `modules/rakun-web/` | F07 owns `src/*.bp`; F20 owns `src/websocket/**` only and adds no arm to F07's chain |
| F08 · F09 | `modules/rakun-data/` | F08 owns `src/sql/**` and `datasource.bp`; F09 owns `src/nosql/**` and consumes `datasource.bp` read-only |
| F22 · F23 · F24 · F25 | `repository/rakun/src/` | One file each, named in the table; none reads another's internals, all four go through `context` from F06 |
| F33 … F47 | `emilia/src/tokens.bp`, `emilia/src/emilia.bp` | Banner convention; one `tokenToCss` arm each, in front-number order |
| F48 | `jhonstart/src/html_attrs.bp` | The one cross-repo front; it adds a file to jhonstart and edits none |
| F11 · F76 · F87 | `modules/rakun-actuator/` | F11 owns `src/*.bp` (health, info, the endpoint host); F76 owns `src/security/**` and `src/probes/**`; F87 owns `src/audit/**` |
| F08 · F09 · F77 · F78 · F83 | `modules/rakun-data/` | One subdirectory each — `src/sql/**`, `src/nosql/**`, `src/migrate/**`, `src/orm/**`, `src/tx/**`. F08 also owns `datasource.bp`, which the other four consume read-only |
| F15 · F86 · F89 · F90 · F91 | `modules/rakun-messaging/` | One subdirectory each; F15 owns the listener registry the other four register arms with |
| F16 · F84 | `modules/rakun-scheduling/` | F16 owns the in-VM scheduler; F84 owns `src/persistent/**` and adds a store behind F16's registry |
| F10 · F79 | `modules/rakun-security/` | F10 owns the core; F79 owns `src/oauth2/**` and `src/ldap/**` |
| F07 · F20 · F82 | `modules/rakun-web/` | F07 owns `src/*.bp`; F20 owns `src/websocket/**`; F82 owns `src/static/**` |
| F22 · F23 · F24 · F25 · F60 · F61 · F62 · F63 · F64 · F65 · F66 · F72 · F74 | `repository/rakun/src/` | One file each, named in the ownership table. The four frozen files stay frozen for all of them |
| F54 · F55 · F56 · F59 | `repository/emilia/src/` | New files only; none adds a token section or a `tokenToCss` arm, so none collides with F33–F48 |
| F56 | the `flush`/`register` half of `emilia/src/emilia.bp` | Fenced under its own banner. F33–F48 append sub-dispatchers; F56 rewrites the emitter they feed |
| F53 | everything, read-only | Consumes all fronts, writes only under `examples/blog/` |

## Waves

| Wave | Fronts | Blocked by |
|---|---|---|
| **0** | 01 · 02 · 03 · 33 · 34 · 35 · 49 · 54 · 56 | nothing |
| **1** | 04 · 05 · 22 · 26 · 36 · 37 · 38 · 39 · 40 · 41 · 42 · 43 · 44 · 45 · 46 · 47 · 55 · 57 · 58 · 59 · 72 | wave 0 |
| **2** | 06 · 27 · 28 · 48 · 61 · 62 · 63 · 65 | 04 · 05 · 22 · 26 · 72 |
| **3** | 07 · 08 · 11 · 12 · 13 · 14 · 15 · 16 · 17 · 19 · 21 · 23 · 29 · 30 · 31 · 32 · 60 · 64 · 68 · 73 · 74 · 75 · 80 · 82 · 85 · 88 | 06 · 28 · 62 · 65 |
| **4** | 09 · 10 · 18 · 20 · 24 · 25 · 50 · 51 · 52 · 66 · 69 · 70 · 71 · 76 · 77 · 78 · 81 · 83 · 84 · 86 · 87 · 89 · 90 · 91 · 92 · 93 | 07 · 08 · 12 · 15 · 16 · 23 · 29 · 30 |
| **5** | 67 · 79 | 10 · 24 · 68 |
| **6** | 53 | all |

A wave is a **level in the dependency graph, not a sprint**: a front sits one level below everything
it consumes, so no front shares a wave with something it reads. Three placements are worth naming
because an earlier draft of this table got them wrong. Front 23 cannot share wave 2 with front 06 —
it resolves beans through it. Fronts 24 and 25 cannot share a wave with 23, 12 and 07 — they render
and cache through all three. Front 67 waits on both 24 and 68, which is what makes it the deepest
front in the milestone apart from the example app.

Wave 1 is twenty-one fronts wide, wave 3 is twenty-six, wave 4 is twenty-six. That is the point of the
cut: the milestone's critical path is `01 → 04 · 22 · 26 → 06 · 28 · 62 → 23 · 68 → 24 → 67 → 53`, seven levels deep,
and the other eighty-six fronts are breadth. Ninety-three fronts is a large milestone, but it is not
a long one — nothing waits on more than six levels ahead of it.

Two fronts earn their place in wave 0 by consequence rather than by convention. `54-emilia-theme`
comes before the token fronts because four copies of the spacing ladder already exist in `emilia.bp`
and have already drifted; every front admitted after it would add a fifth. `56-emilia-cascade-and-output`
comes before them because the shape emilia emits today cannot express `@media` beside `@layer`, cannot
hold `@keyframes`, and cannot carry `group-*`, `peer-*`, `rtl`, `space-*` or `divide-*` — fronts 34,
40, 44, 55 and 58 all emit through it, and building them first means building them twice.

## Exit gate

The milestone closes when, on `feat`, all of the following hold at once:

- `zig build test` green in `repository/botopink-lang`
- `zig build test-libs` green — which covers std, emilia, jhonstart, rakun, onze and erika
- every front's own test file green on **its assigned target** — erlang for the server fronts, js
  for the client fronts, both for the three boundary fronts (22 · 23 · 24) and for track A
- no server front carries an `@External.Node` cell, and no client front carries an
  `#[@external(erlang)]` cell; the target split in the overview is checked, not assumed. An
  **explicit refusal cell** — a host cell that exists only to return an error naming the target it
  does not serve, as `std/net` does on commonJS — is not a violation: it is how the absence is
  asserted instead of hoped for
- `repository/onze13/examples/blog` builds, serves, and renders its routes under both `onze13 dev`
  and `onze13 build && onze13 start`
- the seven remotes (meta plus six submodules) are unified on `feat`
- every `// LANGUAGE GAP:` marker left in an example file appears in a spec under
  `specs/1.0.10-beta/` — a gap that is only a comment in a `.bp` file is a gap nobody will fix
- every row in [`deferred.md`](./deferred.md) is still true: a deferred feature that turned out to
  have a BEAM path during implementation gets a front, not a silent carry-forward
