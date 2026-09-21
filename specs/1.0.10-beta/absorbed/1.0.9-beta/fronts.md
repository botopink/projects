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
| **F01 std-lib-enablement** | `src/net.bp`, `src/process.bp`, `src/path.bp`, `src/clock.bp`, `src/random.bp`, `src/regex.bp`, `src/encoding.bp`, `src/hmac.bp`, `src/escape.bp`, `src/root.bp` (exports only) | inline `test` blocks at the foot of each `src/*.bp` it owns |
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
| **F04 erlang-runtime** | rakun-core | `src/sidecars/rakun_runtime.erl`, `src/runtime.bp` (`#[@external(erlang)]` block only), `src/root.bp`, `botopink.json` · `test/erlang_runtime_test.bp` | `test/erlang_runtime_test.bp` |
| **F05 config-profiles** | rakun-core | `src/config.bp`, `src/profiles.bp`, `src/sidecars/rakun_config.erl` · `test/config_test.bp` | `test/config_test.bp` |
| **F06 context-api** | rakun-core | `src/context.bp`, `src/events.bp`, `src/lifecycle.bp`, `src/rakun.d.bp` (removal of the `Context` stub only), `src/sidecars/rakun_context.erl` · `test/context_test.bp`, `test/events_test.bp` | `test/context_test.bp`, `test/events_test.bp` |
| **F07 middleware** | rakun-web | `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` · `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp` | `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp` |
| **F08 data-sql** | rakun-data | `modules/rakun-data/src/datasource.bp`, `modules/rakun-data/src/sql/**` · `modules/rakun-data/test/sql/**` | `modules/rakun-data/test/sql/**` |
| **F09 data-nosql** | rakun-data | `modules/rakun-data/src/nosql/**` · `modules/rakun-data/test/nosql/**` | `modules/rakun-data/test/nosql/**` |
| **F10 security-auth** | rakun-security | `modules/rakun-security/src/**` · `modules/rakun-security/test/**` | `modules/rakun-security/test/**` |
| **F11 actuator** | rakun-actuator | `modules/rakun-actuator-api/src/**`, `modules/rakun-actuator-api/test/**` · `modules/rakun-actuator/src/*.bp`, `modules/rakun-actuator/src/sidecars/rakun_actuator.erl`, `modules/rakun-actuator/test/**` | `modules/rakun-actuator/test/**` |
| **F12 cache** | rakun-cache | `modules/rakun-cache/src/**`, `modules/rakun-cache/test/**` | `modules/rakun-cache/test/**` |
| **F13 http-clients** | rakun-client | `modules/rakun-client/src/**`, `modules/rakun-client/test/**` | `modules/rakun-client/test/**` |
| **F14 validation** | rakun-validation | `modules/rakun-validation/src/**`, `modules/rakun-validation/test/**` | `modules/rakun-validation/test/**` |
| **F15 messaging** | rakun-messaging | `modules/rakun-messaging/src/**`, `modules/rakun-messaging/test/**` | `modules/rakun-messaging/test/**` |
| **F16 scheduling** | rakun-scheduling | `modules/rakun-scheduling/src/**`, `modules/rakun-scheduling/test/**` | `modules/rakun-scheduling/test/**` |
| **F17 logging** | rakun-logging | `modules/rakun-logging/src/**`, `modules/rakun-logging/test/**` | `modules/rakun-logging/test/**` |
| **F18 session** | rakun-session | `modules/rakun-session/src/**`, `modules/rakun-session/test/**` | `modules/rakun-session/test/**` |
| **F19 test-utilities** | rakun-test | `modules/rakun-test/src/**`, `modules/rakun-test/test/**` | `modules/rakun-test/test/**` |
| **F20 websocket** | rakun-web | `modules/rakun-web/src/websocket/**`, `modules/rakun-web/test/websocket/**` | `modules/rakun-web/test/websocket/**` |
| **F21 hateoas** | rakun-hateoas | `modules/rakun-hateoas/src/**`, `modules/rakun-hateoas/test/**` | `modules/rakun-hateoas/test/**` |
| **F22 file-routing** | rakun-core | `src/file_router.bp`, `src/file_router.mjs`, | `test/file_router_test.bp` |
| **F23 ssr-pipeline** | rakun-core | `src/ssr.bp`, `src/ssr.mjs`, | `test/ssr_test.bp` |
| **F24 server-actions** | rakun-core | `src/actions.bp`, `src/actions.mjs`, | `test/actions_test.bp` |
| **F25 route-handlers** | rakun-core | `src/route_handler.bp`, `test/route_handler_test.bp` | `test/route_handler_test.bp` |

| **F60 static-generation** | rakun-core | `src/static_gen.bp`, `src/segment_config.bp`, | `test/static_gen_test.bp` |
| **F61 parallel-intercepting-routes** | rakun-core | `src/route_slots.bp`, `src/route_intercept.bp`, | `test/parallel_routes_test.bp` |
| **F62 request-context** | rakun-core | `src/request_context.bp`, `src/request_memo.bp`, | `test/request_context_test.bp` |
| **F63 navigation-signals** | rakun-core | `src/navigation.bp`, | `test/navigation_test.bp` |
| **F64 i18n-routing** | rakun-core | `modules/rakun-i18n/botopink.json`, | `test/i18n_test.bp` |
| **F65 url-rules** | rakun-core | `modules/rakun-web/src/rules/**`, | `test/url_rules_test.bp` |
| **F66 metadata-file-routes** | rakun-core | `src/metadata_routes.bp`, | `test/metadata_routes_test.bp` |
| **F72 auto-configuration** | rakun-core | `src/autoconfig.bp`, `src/conditions.bp`, `src/condition_report.bp`, `src/autoconfig_registry.bp`, `src/sidecars/rakun_autoconfig.erl` · `test/autoconfig_test.bp`, `test/conditions_test.bp` | `test/autoconfig_test.bp` |
| **F73 starters** | rakun-starters | `starters/rakun-starter-*/botopink.json`, `starters/rakun-starter-*/src/root.bp`, `starters/README.md`, `src/version_set.bp` · `test/version_set_test.bp`, `test/starter_manifest_test.bp` | `modules/rakun-starters/test/**` |
| **F74 tls-ssl-bundles** | rakun-core | `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `modules/rakun-web/src/tls.bp` · `test/ssl_bundle_test.bp`, `modules/rakun-web/test/tls_test.bp` | `test/ssl_bundles_test.bp` |
| **F75 observability-metrics** | rakun-observability | `modules/rakun-metrics/botopink.json`, `modules/rakun-metrics/src/**`, `modules/rakun-metrics/test/**`, `modules/rakun-metrics/src/sidecars/rakun_metrics.erl` | `modules/rakun-observability/test/**` |
| **F76 actuator-security-probes** | rakun-actuator | `modules/rakun-actuator/src/exposure.bp`, `src/access.bp`, `src/management_listener.bp`, `src/probes.bp`, `src/sanitize.bp`, `src/availability.bp` · `modules/rakun-actuator/test/exposure_test.bp`, `test/access_test.bp`, `test/probes_test.bp`, `test/sanitize_test.bp` | `modules/rakun-actuator/test/security/**` |
| **F77 db-migrations** | rakun-data | `modules/rakun-data/src/migration/**` · `modules/rakun-data/test/migration/**` | `modules/rakun-data/test/migrate/**` |
| **F78 orm-entities** | rakun-data | `modules/rakun-data/src/orm/**` · `modules/rakun-data/test/orm/**` | `modules/rakun-data/test/orm/**` |
| **F79 oauth2-sso** | rakun-security | `modules/rakun-security/src/oauth2/**`, `modules/rakun-security/src/oidc/**`, `modules/rakun-security/src/ldap/**`, `modules/rakun-security/src/saml2/**` · `modules/rakun-security/test/oauth2/**`, `test/oidc/**`, `test/ldap/**`, `test/saml2/**` | `modules/rakun-security/test/oauth2/**` |
| **F80 devtools** | rakun-devtools | `modules/rakun-devtools/botopink.json`, `modules/rakun-devtools/src/**` · `modules/rakun-devtools/test/**` | `modules/rakun-devtools/test/**` |
| **F81 packaging-release** | rakun-release | `modules/rakun-release/botopink.json`, `modules/rakun-release/src/**`, `modules/rakun-release/templates/**` · `modules/rakun-release/test/**` | `modules/rakun-release/test/**` |
| **F82 static-assets** | rakun-web | `modules/rakun-web/src/static/**` · `modules/rakun-web/test/static/**` | `modules/rakun-web/test/static/**` |
| **F83 distributed-transactions** | rakun-tx | `modules/rakun-tx/botopink.json`, `modules/rakun-tx/src/**` · `modules/rakun-tx/test/**` | `modules/rakun-tx/test/**` |
| **F84 persistent-jobs** | rakun-scheduling | `modules/rakun-scheduling/src/jobstore/**` · `modules/rakun-scheduling/test/jobstore/**` | `modules/rakun-scheduling/test/jobstore/**` |
| **F85 mail** | rakun-mail | `modules/rakun-mail/botopink.json`, `modules/rakun-mail/src/**` · `modules/rakun-mail/test/**` | `modules/rakun-mail/test/**` |
| **F86 messaging-reliability** | rakun-messaging | `modules/rakun-messaging/src/reliability/**`, `modules/rakun-messaging/test/reliability/**` | `modules/rakun-messaging/test/reliability/**` |
| **F87 audit-and-exchanges** | rakun-actuator | `modules/rakun-actuator/src/audit/**`, `modules/rakun-actuator/src/exchanges/**`, `modules/rakun-actuator/test/audit/**`, `modules/rakun-actuator/test/exchanges/**` | `modules/rakun-actuator/test/audit/**` |
| **F88 cli** | rakun-cli | `modules/rakun-cli/src/**`, `modules/rakun-cli/templates/**`, `modules/rakun-cli/test/**` | `modules/rakun-cli/test/**` |
| **F89 stream-pipelines** | rakun-messaging | `modules/rakun-stream/src/**`, `modules/rakun-stream/test/**` | `modules/rakun-messaging/test/streams/**` |
| **F90 jms-brokers** | rakun-messaging | `modules/rakun-messaging/src/jms/**`, `modules/rakun-messaging/test/jms/**` | `modules/rakun-messaging/test/jms/**` |
| **F91 pulsar** | rakun-messaging | `modules/rakun-messaging/src/pulsar/**`, `modules/rakun-messaging/test/pulsar/**` | `modules/rakun-messaging/test/pulsar/**` |
| **F92 rsocket** | rakun-rsocket | `modules/rakun-rsocket/src/**`, `modules/rakun-rsocket/test/**` | `modules/rakun-rsocket/test/**` |
| **F93 soap-webservices** | rakun-ws | `modules/rakun-ws/src/**`, `modules/rakun-ws/test/**` | `modules/rakun-ws/test/**` |

**Sidecars.** Every erlang host module a rakun front ships is `src/sidecars/rakun_<name>.erl` —
never a bare `<name>.erl`. `shipErlSidecars` skips any atom that matches a module this build emitted
(`libs.zig:596`), and rakun emits `rakun/runtime`, `rakun/config`, `rakun/file_router`; a sidecar
with one of those basenames is silently not shipped and the program dies at run time with
`undefined function runtime:scan/1`. This is recorded as a toolchain gap in
[`language-gaps.md`](./language-gaps.md); until it is a build error, the naming rule is the guard.

**Shared files in `repository/rakun/`.** `src/root.bp` and `botopink.json`'s `files` list are
appended to by every core front that adds a module (05, 06, 22, 23, 24, 25, 60, 61, 62, 63, 64, 65,
66, 72, 74). Front 04 owns both; the others append their lines in front-number order and never
reorder. Each `modules/<name>/` directory's `botopink.json` and `src/root.bp` are owned by the
**lowest-numbered front in that module** and appended to by the rest under the same rule.

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
| **F26 router** | `src/router.bp` (promoted from `router.d.bp`, and the package's one `pairValue` pair-list decoder), `test/router_test.bp` | `test/router_test.bp` |
| **F27 link** | `src/link.bp`, `src/reconcile.bp` (the client-navigation reconciler), `test/link_test.bp`, `test/reconcile_test.bp` | `test/link_test.bp` |
| **F28 server-components** | `src/server.bp` (promoted from `server.d.bp`), `test/server_test.bp` | `test/server_test.bp` |
| **F29 client-directive** | `src/client.bp`, `test/client_test.bp` | `test/client_test.bp` |
| **F30 streaming** | `src/streaming.bp`, `src/suspense.bp`, `test/streaming_test.bp` | `test/streaming_test.bp` |
| **F31 error-boundaries** | `src/error_boundary.bp`, `test/error_boundary_test.bp` | `test/error_boundary_test.bp` |
| **F32 metadata** | `src/metadata.bp`, `test/metadata_test.bp` | `test/metadata_test.bp` |

| **F67 forms** | `src/form.bp`, `src/form_state.bp`, `test/form_test.bp`, `test/form_state_test.bp` | `test/forms_test.bp` |
| **F94 element-surface** | `src/elements.bp` (plus its inline `test` blocks), `test/elements_test.bp`, `src/root.bp`, `botopink.json` | inline tests in `src/elements.bp` |

`repository/jhonstart/src/root.bp` and `botopink.json`'s `files` list are appended to by all nine
track-C fronts. Front 94 owns both (it is wave 0 and lands first); the others append in
front-number order.

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

**Three track-D files are append-only, and here is who appends.** `repository/emilia/src/root.bp`
(the `pub mod` lines) and `repository/emilia/botopink.json` (the `files` list) are touched by every
front that adds a module — 54, 55, 56, 57, 58, 59 and 48 — and a banner cannot fence a `pub mod`
line or a JSON array element. The rule is the same as for std's `root.bp`: **append in
front-number order, never reorder, never edit another front's line.** A merge conflict on either
file is resolved by re-sorting, not by choosing a side.

`repository/emilia/` has **no `test/` directory today** — every emilia test is an inline `test`
block in `src/*.bp`, the same convention std uses. The "Tests it owns" column below names the file
a front *would* create if the repo moves to `test/`; until it does, the tests live at the foot of
the front's own source file, and the exit gate reads either.

**How eighteen fronts share `tokens.bp` and `emilia.bp`.** They do not merge into the same lines. The
rule is one variant block per front in `tokens.bp` and one sub-dispatcher per front in `emilia.bp`,
each fenced by a comment banner naming its front, and each appended at the end of its file rather
than interleaved. The only genuinely shared lines are the arms each front adds to the top-level `tokenToCss` `case` —
**one contiguous block per front**, added in front-number order. A front adds one arm per
top-level section it owns *and one arm per top-level payload variant it owns* — payload-carrying
tokens must be top-level variants (contract 4a), so fronts 33, 34, 40, 46, 47, 57 and 58 add
several arms each (57 adds six, 58 adds four). The arms sit together under the front's banner, which
is the property the convention exists for; front-number ordering still makes the merged result
deterministic. A front that has to edit
another front's block has found a design error, not a merge conflict, and files it as such.

F48 owns `repository/emilia/src/attributes.bp` and `repository/emilia/src/html_hook.bp`, plus
`repository/jhonstart/src/html_attrs.bp` — the single cross-repo front in the milestone. It touches
no token section and no dispatcher, which is what makes it safe to run alongside all fifteen others.

### Track E — onze (`repository/onze/`, new)

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F49 stand-up** | `botopink.json`, `modules/onze/src/root.bp`, `modules/onze/src/types.bp`, `modules/onze/src/config.bp`, `modules/onze/src/integration.bp`, | `modules/onze/test/config_test.bp`, `modules/onze/test/types_test.bp` |
| **F50 cli** | `modules/onze-cli/src/**`, `modules/onze-cli/test/**` | `modules/onze-cli/test/**` |
| **F51 image** | `modules/onze-assets/src/image.bp`, `modules/onze-assets/test/image_test.bp` | `modules/onze-assets/test/image_test.bp` |
| **F52 font** | `modules/onze-assets/src/font.bp`, `modules/onze-assets/test/font_test.bp` | `modules/onze-assets/test/font_test.bp` |
| **F53 example-app** | `examples/blog/**`, `examples/blog/test/**` | `examples/blog/test/**` |

| **F68 client-bundle** | `modules/onze-bundler/src/**`, | `modules/onze-bundler/test/**` |
| **F69 styling-pipeline** | `modules/onze-assets/src/styling/**`, | `modules/onze-assets/test/styling_test.bp` |
| **F70 image-response** | `modules/onze-assets/src/og/**`, `modules/onze-assets/test/og/**` | `modules/onze-assets/test/image_response_test.bp` |
| **F71 release-packaging** | `modules/onze-release/src/**`, | `modules/onze-release/test/**` |

### Track F — cross-cutting (95)

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F95 ecosystem-package-restructure** | `libs/std/src/asserts.bp` (expands existing), `repository/onze/botopink.json` + `modules/**` (new structure), `repository/jhonstart/botopink.json` + `modules/**` (restructure), `repository/emilia/botopink.json` + `modules/**` (restructure), `repository/rakun/botopink.json` + `modules/rakun/` (new core submodule) | inline `test` blocks in `libs/std/src/asserts.bp`; structural verification via `zig build test-libs` |

F95 is cross-cutting: it touches every repository but only structurally (directory moves and `botopink.json` edits). It does not rewrite behaviour in any library. The std/asserts expansion is additive to the existing module.

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
| F33 · F39 | the `Bg { … }` section of `tokens.bp` | The one place in track D where two fronts share a *section*, not just a file: 33 owns `Bg.Color`, 39 owns everything else under `Bg`. Resolved by wave order — 33 is wave 0, 39 appends after 33's block |
| F35 · F40 | the sibling selector for `space-*` and `divide-*` | Neither is documented upstream; both READMEs require one cross-front test asserting the two selectors are byte-identical |
| F56 | the `flush`/`register` half of `emilia/src/emilia.bp` | Fenced under its own banner. F33–F48 append sub-dispatchers; F56 rewrites the emitter they feed |
| F53 | everything, read-only | Consumes all fronts, writes only under `examples/blog/` |
| F95 | every repository, structurally | Cross-cutting: directory moves and `botopink.json` edits only. The std/asserts expansion is additive (no existing function changes). Package restructures land alongside each library's first front, so no front has created files in the old paths yet. F95 sequences before F49 (onze stand-up) because F49 creates files in the new `modules/onze/` structure that F95 establishes |

## Waves

| Wave | Fronts | Blocked by |
|---|---|---|
| **0** | 01 · 02 · 03 · 49 · 54 · 94 · 95 | nothing |
| **1** | 04 · 05 · 22 · 50 · 51 · 52 · 56 | 01 · 49 · 54 |
| **2** | 06 · 26 · 33 · 34 · 35 · 55 · 57 · 58 · 61 · 62 · 63 · 65 · 71 · 81 · 88 | 04 · 05 · 22 · 50 · 56 |
| **3** | 07 · 08 · 11 · 12 · 13 · 14 · 15 · 16 · 17 · 19 · 28 · 36 · 37 · 38 · 39 · 40 · 41 · 42 · 43 · 44 · 45 · 46 · 47 · 48 · 59 · 60 · 64 · 72 · 75 · 80 · 85 | 06 · 26 · 33 · 34 · 35 · 62 · 65 |
| **4** | 09 · 10 · 18 · 20 · 21 · 23 · 27 · 29 · 30 · 73 · 74 · 76 · 77 · 78 · 82 · 83 · 84 · 86 · 87 · 89 · 90 · 91 · 92 · 93 | 07 · 08 · 11 · 12 · 15 · 16 · 28 · 60 · 72 |
| **5** | 24 · 25 · 66 · 68 · 69 · 70 · 79 | 10 · 23 · 29 · 30 |
| **6** | 31 · 32 · 67 | 24 · 66 · 68 |
| **7** | 53 | all |

Within wave 0, front 54 lands before front 56: `Options.theme` is a `Theme` and `defaultOptions()`
calls `defaultTheme()`, so without 54 the default `flush()` would emit no `--spacing` and every
spacing utility would be dead.

A dependency annotated **`(soft)`** or **`(read-only)`** in a README's `Depends on` line is a
citation, not an edge: the front lands without it and merely reads its contract. Only unannotated
dependencies enter the graph. This is what keeps the graph acyclic where two fronts define and
enforce one thing (29 and 68), or own a store and its transport (12 and 13), or sequence a
shutdown (07 and 76).

A wave is a **level in the dependency graph, not a sprint**: a front sits one level below everything
it consumes, so no front shares a wave with something it reads. The table is computed from every front's `Depends on` line, not hand-placed — when a front's
dependencies change, the table is regenerated, not edited. Front 26 sits a level below 22 because it
calls 22's `matchPath` rather than shipping a second matcher; front 23 sits below 28 because it
renders 28's components; front 67 waits on 24, 68 and 94, which makes it the deepest front in the
milestone apart from the example app.

Wave 1 is 7 fronts wide, wave 3 is 31, wave 4 is 24. That is the point of the
cut: the milestone's critical path is `01 → 22 → 26 → 28 → 23 → 24 → 31 → 53`, 7 levels deep,
and the other 87 fronts are breadth. Ninety-five fronts is a large milestone, but it is not
a long one — nothing waits on more than 6 levels ahead of it.

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
- no server front carries a **new** `@External.Node` cell, and no client front carries an
  `#[@external(erlang)]` cell; the target split in the overview is checked, not assumed. Two things
  are not violations: an **explicit refusal cell** — a host cell that exists only to return an error
  naming the target it does not serve, as `std/net` does on commonJS — and the **seventeen
  pre-existing Node forms in `rakun/src/runtime.bp`**, which front 04 leaves in place and adds
  Erlang forms beside
- every erlang sidecar is named `src/sidecars/rakun_<name>.erl`, and no `.mjs` file exists in a
  server front
- `repository/onze/examples/blog` builds, serves, and renders its routes under both `onze dev`
  and `onze build && onze start`
- the seven remotes (meta plus six submodules) are unified on `feat`
- every `// LANGUAGE GAP:` marker left in an example file appears in a spec under
  `specs/1.0.10-beta/` — a gap that is only a comment in a `.bp` file is a gap nobody will fix
- every row in [`deferred.md`](./deferred.md) is still true: a deferred feature that turned out to
  have a BEAM path during implementation gets a front, not a silent carry-forward
