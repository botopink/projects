# Fronts — 1.0.10-beta: who may touch what, when

The front-number → directory map is in [`unification.md`](./unification.md).

The overview says *what* each front delivers; this says *who owns which file*. A front is one
worktree (`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts may run at the same
time only when they share no source file and no snapshot directory. Two traps, both
handled below and neither by hoping: emilia's `tokens.bp`, which eighteen fronts write to, and
rakun's core `src/`, which fourteen fronts write to. A third: the compiler changes **while** the
libraries are written, by `00-compiler-carry-over` — so the rule that no library front touches
`repository/botopink-lang/modules/**` is stated first.

Paths are relative to the repository named in the section or row.

## Blocking order

```
wave 0    01-std ──────────────────────────────┐   asserts · snapshots · mocks · @src() ·
          std enablement 01/02/03              │   the onze takeover (old onze dir removed,
          01-std/04-routing-lib ───────────────┤   onze13 → onze)
          01-std/05-actions-lib ───────────────┤   the bundled routing / actions / validation
          01-std/06-validation-lib ────────────┤   libraries
                                               │
wave 1    02-packaging ────────────────────────┤   alongside each library's first front:
          modules/<lib>/ · modules/<lib>-test/ │   rakun 04 · jhonstart 94 · emilia 54 · onze 49
          examples/<project>/ · workspaces     │   (each library's modules.md refines the cut)
                                               ▼
waves 1–10 03-rakun · 04-jhonstart · 05-emilia · 06-onze  — the levels of § Waves, computed
                                                            from the fronts' `Depends on` lines

beside    00-compiler-carry-over — the open compiler items, on their own order
```

Why this order and not another: `01-std` first because every `-test` submodule imports
`testing.asserts` and `testing.snapshots`, and the `onze` name cannot be taken while the mocking
library holds it. `02-packaging` second because it is the directory every library front writes *into*; a
front that lands before its library's `modules/` tree exists creates files in a path the next commit
moves. The compiler beside, not ahead: the libraries do not wait on `00`; a missing compiler feature
is a row in [`language-gaps.md`](./language-gaps.md) and a workaround.

## Ownership

### `00-compiler-carry-over` (`repository/botopink-lang/modules/**`)

The surface fronts `19-use-activation`, `20-builtins-surface`, `21-effect-chain`, `22-loops` and
`24-effects-by-return` are closed; their files belong to the sub-fronts in the table below
(`builtins.d.bp`, `EffectKind` and `comptime/effect_chain.zig` to 01-checker; each backend's effect
and loop lowering to that backend; `docs.md`'s sections to their owners).

**The compiler fronts are the only fronts that touch the compiler.** No library front, no packaging
step and no std front edits a file under `repository/botopink-lang/modules/**` — with one named
exception, `@src()` (below). A library front that needs a compiler change files a row in
[`language-gaps.md`](./language-gaps.md) with the `00` sub-front it belongs to, and works around it.

`00`'s internal ownership is [`00-compiler-carry-over/README.md`](./00-compiler-carry-over/README.md)'s.
The sub-areas, so that a library front can name the one its gap belongs to:

| Sub-front | Owns (relative to `modules/compiler-core/src/` unless stated) | Snapshots |
|---|---|---|
| **01-checker** | `comptime/{infer,types,unify,env,transform,eval,error}.zig` · `parser/{decls,exprs,patterns}.zig` (named sites) · decision-8 items in `libs/std/**` and `examples/**` | `snapshots/comptime/**` |
| **02-erlang** | `codegen/erlang.zig` (module-atom sites are 13's) · `codegen/crossModule.zig` (13's) · its fixtures | `snapshots/codegen/erlang/**` |
| **03-beam** | `codegen/beam_asm.zig` · `codegen/beam/**` · `scripts/beam_export_audit.sh` | `snapshots/codegen/beam/**` |
| **04-js** | `codegen/commonJS.zig` · `codegen/typescript.zig` · `codegen/js/**` | `snapshots/codegen/commonJS/**` |
| **05-wasm** | `codegen/wat.zig` · `codegen/wat/**` | `snapshots/codegen/wasm/**` |
| **06-comptime-dedup** | `comptime/snapshot.zig` · `comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout) |
| **07-review-backlog** | `utils/snap.zig` · `scripts/snap_audit.sh` · `codegen/tests/**` · `comptime/tests/**` (not `helpers.zig`) · `parser/tests/**` · `modules/language-server/src/tests/**` | — |
| **08-hygiene** | `docs.md`, `README.md`, every `AGENTS.md`, the relative links of `specs/` · `libs/std/botopink.json`, `libs/std/AGENTS.md` · comments after their owners (C-23) | — |
| **09-ecosystem-residuals** | `repository/erika/**` and the meta submodule pointers **only** — the other library trees are tracks B–E's in this milestone (see Conflict rules) | the libraries' own outputs |
| **10-cli-residuals** | `modules/compiler-cli/**` except `src/cli/{build,run}.zig` (13's) · `modules/lib-test-runner/**` where a fix needs it · `modules/bpmp/**` (the manifest reader) | — |
| **11-tooling** | `modules/language-server/**` except `src/tests/**` (07's) · `repository/vscode-extension/**` | `modules/language-server/snapshots/lsp/` |
| **12-language-tests** | `repository/botopink-lang/tests/language/**` | — |
| **13-module-identity** | `codegen/crossModule.zig` · the module-atom sites, then the emitters wholesale, of `codegen/{erlang,beam_asm,runtime}.zig` · `modules/compiler-cli/src/cli/{build,run}.zig` · the module-atom lines of `comptime/{template_eval,decorator_eval}.zig` | `snapshots/codegen/{erlang,beam}/` (≈318 cells) |
| **14-comptime-on-beam** | `comptime/{template_eval,decorator_eval}.zig` · `comptime/runtime/prelude.zig` · the `evaluate(…)` call sites and memo cache of `comptime/infer.zig` (carve-out of 01) | the `COMPTIME ERLANG` cells |
| **15-language-surface** | `parser/types.zig` · `lexer.zig`, `lexer/token.zig` · `print.zig` · the `ParseErrorType` enum in `parser.zig` · four named sites in `parser/exprs.zig` | — (strictly accepting) |
| **16-formatter** | `format.zig` · `format/**` · the trivia/member-order fields of `ast.zig` and their fill sites in `parser/decls.zig` | — (inline expectations) |
| **17-beam-memory** | `parser.zig`'s top-level dispatch (not the `ParseErrorType` enum) · `ast.zig`'s `ValDecl` · two `infer.zig` diagnostics · one emission site per backend · a new `Form` variant in `codegen/beam/erl_ast.zig` | only cells its step 2 makes legal |
| **18-comptime-runtimes** | `comptime/runtime/**` · the comptime halves of `codegen/{beam_asm,wat}.zig` · `codegen/snapshot.zig`, `comptime/snapshot.zig` · root `build.zig` (the resident step, the wasm build) · `modules/wasm3/**` | `snapshots/codegen/**` (the `{beam,wat}/<target>` re-layout) |
| **23-std-purity** (step 6 open) | `parseImportItem` in `parser/decls.zig` · the import binding in `comptime/infer.zig` · the four `emitUse` · `modules/language-server/src/project_graph.zig` (carve-out of 11) · `build.zig`'s `stdPkgFilesFromRoot` · `libs/std/src/**`, `libs/std/AGENTS.md` · `docs.md` § imports / std · `scripts/known-red-libs.txt` (during the consumer sweep) | every snapshot carrying a std module name |
| **25-gate-perf** (C-33) | `scripts/{gate.sh,check-docs.sh,test-libs.sh,lib/pool.sh}` · the runner `tests/language/run.sh` (not its cells, not `expected-failures.txt`) · `modules/lib-test-runner/**` | none |

`00` runs beside the libraries on its own order.

### `01-std` (`repository/botopink-lang/libs/std/` — and one carve-out in the compiler)

`01-std` owns the files the whole test story stands on, the std modules of track A below, and one
compiler carve-out.

| Front / item | Source it owns | Tests it owns |
|---|---|---|
| **asserts** ([`01-std/asserts-api.md`](./01-std/asserts-api.md)) | `libs/std/src/testing/asserts.bp` | inline `test` blocks in `asserts.bp` |
| **snapshots** ([`01-std/snapshots.md`](./01-std/snapshots.md)) | `libs/std/src/testing/snapshots.bp` (`path(loc)`, the `.snap` writer/reader, the `.new` refusal) | inline `test` blocks in `snapshots.bp`, plus one `__snapshots__/` fixture beside `libs/std/src/` |
| **`@src()`** ([`01-std/src-builtin.md`](./01-std/src-builtin.md)) | the `SourceLocation` record and `@src` entry in `libs/std/src/builtins.d.bp`; **by carve-out from `00`**: the builtin's typing site in `comptime/infer.zig` and the literal lowering in each of the four backends — named file by file in `src-builtin.md`, granted in `00`'s README before the work opens | one `tests/language/` cell per backend (coordinated with `00 · 12-language-tests`, which owns that directory) |
| **old `onze` removal + `onze13 → onze`** | `repository/onze/**` (the mocking library — removed; its assertions live in `asserts.bp` from this milestone on) · every `onze13` in a directory name, an `**Owns:**` line or a manifest under `specs/1.0.10-beta/**` (the history rows of `unification.md` and the carried front 95 excepted) | `grep -rl onze13 repository` answers nothing |

### Track A — std (`repository/botopink-lang/libs/std/`) — the library rows of `01-std`

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F01 std-lib-enablement** | `src/io/net.bp`, `src/io/process.bp`, `src/path.bp`, `src/io/clock.bp`, `src/io/random.bp`, `src/regex.bp`, `src/encoding.bp`, `src/hash.bp` (HMAC), `src/escape.bp` (with `scriptJson`) · `src/json.bp`'s additions — `quote`, `unquote`, `array`, `object`, `Json` and `decode`; `parse` / `stringify` untouched (decisions 116, 117) | inline `test` blocks at the foot of each file it owns |
| **F02 std-async-primitives** | `src/async.bp` | inline `test` blocks in `src/async.bp` |
| **F03 std-content-hash** | `contentHash` in `src/hash.bp` | inline `test` blocks in `src/hash.bp` |

The bundled `routing` library is `01-std`'s too, in its own directory beside `libs/std/` (decision
115). Its directory number is its index inside `01-std`, not a milestone front number (front 04 is
rakun's erlang runtime):

| Front | Source it owns | Tests it owns |
|---|---|---|
| **routing-lib** ([`01-std/04-routing-lib/`](./01-std/04-routing-lib/README.md)) | `repository/botopink-lang/libs/routing/**` — `segment`, `table`, `match` (ported from rakun's `file_router.bp`), `route_kinds` (front 60's `k` codec), `slot_states` (61's `z` codec), `url_rules` (65's `canonicalize` / `clientHref` / redirect-table codec), `navigation` (63's signal vocabulary and `n` codec, `nav:` reasons — decision 116), `pattern` (rakun-web's `:param` grammar — decision 116) · **by carve-out from `00`**: the bundled-package registry in `build.zig` and the `"std"` package checks it generalises (named in its README) | `libs/routing/test/**`, both targets |
| **actions-lib** ([`01-std/05-actions-lib/`](./01-std/05-actions-lib/README.md)) | `repository/botopink-lang/libs/actions/**` — `state` (`ActionState`, the `state` grammar), `envelope` (the v1 envelope, read with std's `json.decode`, `parseActionState` — decision 117), `rpc` (the JSON-RPC body), `refresh` · the name `actions` in the bundled-package list (decision 116) | `libs/actions/test/**`, both targets |
| **validation-lib** ([`01-std/06-validation-lib/`](./01-std/06-validation-lib/README.md)) | `repository/botopink-lang/libs/validation/**` — rakun front 14's `modules/rakun-validation` moved (all but `boot.bp`), the message source injected, the host tables as inline templates · the name `validation` in the bundled-package list (decision 116) | `libs/validation/test/**`, both targets |

The bundled libraries ship `.bp` files only: target-native code is an inline `#[@External]`
template, and no `.erl` / `.mjs` sidecar exists under `libs/` (decision 117).

`src/root.bp` (and `io/mod.bp`, `testing/mod.bp`) list the std modules (decision 106); a front
that adds a module appends its `pub mod` line.

std tests are **inline**, not in `test/`: `test/` compiles against the ambient global environment
with no module import path (`libs/std/AGENTS.md`), so a file there cannot reach the module it would
be testing. Every std test sits in a `test` block at the foot of its own `src/*.bp`.

### `02-packaging` (every repository, structurally) — [`02-packaging/README.md`](./02-packaging/README.md)

Front 95's rows, re-cut. The std/asserts half is `01-std`'s above; what stays here is the package
shape and the discovery mechanism that finds it.

| Item | Source it owns | Tests it owns |
|---|---|---|
| **rakun tree** | `repository/rakun/botopink.json` (the `files` list and the `targets` array — F04 sets the arrays of decision 113, `02-packaging` adds no target) · `modules/rakun/{botopink.json,src/root.bp}` (new core, re-exports `../../src/**` until `03-rakun/modules.md` moves the core) · `modules/rakun-test/botopink.json` (the `files` list; F19 owns `src/**`) · `modules/README.md` | structural: `zig build test-libs` lists every submodule cell |
| **jhonstart tree** | `repository/jhonstart/botopink.json` · `modules/jhonstart/{botopink.json,src/root.bp}` · `modules/jhonstart-test/{botopink.json,src/root.bp}` (skeleton; fronts 26–32/67/94 fill it) · the directory moves `src/*.bp → modules/jhonstart/src/`, `test/html_test.bp → modules/jhonstart/test/` — the split into `jhonstart-html` and any further submodule is `04-jhonstart/modules.md`'s | `modules/jhonstart/test/html_test.bp` green at its new path |
| **emilia tree** | `repository/emilia/botopink.json` · `modules/emilia/{botopink.json,src/root.bp}` · `modules/emilia-test/{botopink.json,src/root.bp}` (skeleton; F33's snapshot helper is the first content) · the moves `src/{tokens,emilia}.bp → modules/emilia/src/` | inline tests green at the new paths |
| **onze tree** | `repository/onze/botopink.json` (`"name": "onze"`, the five submodules) · `modules/{onze,onze-test,onze-cli,onze-bundler,onze-assets,onze-release}/{botopink.json,src/root.bp}` skeletons — F49 owns the *content* of `modules/onze/src/**` | `zig build test-libs` does not red on the empty modules |
| **examples** | `repository/<lib>/examples/<project>/botopink.json` for every example project that exists today (`rakun/examples/rakun`, `jhonstart/examples/{jhonstart-app,jhonstart-counter,jhonstart-html,jhonstart-todo}`, `emilia/examples/emilia-card`) — re-pointed from `"git"` + `"branch": "feat"` to the **path form** so the example builds against the checkout; `examples/README.md` per library | each example compiles under `zig build test-libs` on its declared target |
| **discovery** | `repository/botopink-lang/scripts/test-libs.sh` (the `BOTOPINK_LIB_ROOTS` it exports: every `repository/<lib>/modules` and `repository/<lib>/examples`) · `repository/botopink-lang/scripts/known-red-libs.txt` (rows for the cells that go red at their new paths, each naming its front) · **by carve-out from `00 · 10-cli-residuals`**: `modules/lib-test-runner/src/discovery.zig`'s nested discovery, if the env route proves insufficient (README § Discovery states both routes and which is preferred) · `docs/botopink-json.md` (the object form of `dependencies`, workspaces) | `modules/lib-test-runner/src/discovery.zig`'s unit tests for the nested case; `tests/cli_contract.sh` unchanged |
| **`AGENTS.md`** | every `AGENTS.md` of a directory it moves (`repository/{rakun,jhonstart,emilia,onze}/AGENTS.md`, `src/AGENTS.md` where present) — in the same commit as the move | — |

`02-packaging` moves directories and edits manifests. It does not rewrite behaviour in any library,
add a token, a decorator or a host cell, or touch `libs/std/src/**` (that is `01-std`). A library's
first front lands in the same wave and the two are sequenced: the tree first, the front's files into
it.

### Track B — rakun (`repository/rakun/`) — `03-rakun/`

A `src/…` path in a row is relative to the member its *Module* column names (`rakun-core` is `modules/rakun/`); fronts 22–25, 60, 61, 63 and 66 read `rakun-app`, the member holding 22's `file_router.bp` and 23's `ssr.bp` ([`03-rakun/modules.md`](./03-rakun/modules.md) § The cut).

| Front | Module | Source it owns | Tests it owns |
|---|---|---|---|
| **F04 erlang-runtime** | rakun-core | `src/sidecars/rakun_runtime.erl`, `src/runtime.bp` (the `#[@external(erlang)]` block, and the removal of the Node forms when it closes), `src/runtime.mjs` (its deletion), `src/root.bp`, `botopink.json` (the `targets` array only — the `files` list is `02-packaging`'s) · `test/erlang_runtime_test.bp` | `test/erlang_runtime_test.bp` |
| **F05 config-profiles** | rakun-core | `src/config.bp`, `src/profiles.bp`, `src/sidecars/rakun_config.erl` · `test/config_test.bp` | `test/config_test.bp` |
| **F06 context-api** | rakun-core | `src/context.bp`, `src/events.bp`, `src/lifecycle.bp`, `src/rakun.d.bp` (removal of the `Context` stub only), `src/sidecars/rakun_context.erl` · `test/context_test.bp`, `test/events_test.bp` | `test/context_test.bp`, `test/events_test.bp` |
| **F07 middleware** | rakun-web | `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` (the `:param` matcher is `routing`'s `pattern`, the problem body is written with std `json` — decision 116) · `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp` | `modules/rakun-web/test/middleware_test.bp`, `cors_test.bp`, `error_test.bp` |
| **F08 data-sql** | rakun-data | `modules/rakun-data/src/datasource.bp`, `modules/rakun-data/src/sql/**` · `modules/rakun-data/test/sql/**` | `modules/rakun-data/test/sql/**` |
| **F09 data-nosql** | rakun-data | `modules/rakun-data/src/nosql/**` · `modules/rakun-data/test/nosql/**` | `modules/rakun-data/test/nosql/**` |
| **F10 security-auth** | rakun-security | `modules/rakun-security/src/**` · `modules/rakun-security/test/**` | `modules/rakun-security/test/**` |
| **F11 actuator** | rakun-actuator | `modules/rakun-actuator-api/src/**`, `modules/rakun-actuator-api/test/**` · `modules/rakun-actuator/src/*.bp`, `modules/rakun-actuator/src/sidecars/rakun_actuator.erl`, `modules/rakun-actuator/test/**` | `modules/rakun-actuator/test/**` |
| **F12 cache** | rakun-cache | `modules/rakun-cache/src/**`, `modules/rakun-cache/test/**` | `modules/rakun-cache/test/**` |
| **F13 http-clients** | rakun-client | `modules/rakun-client/src/**`, `modules/rakun-client/test/**` | `modules/rakun-client/test/**` |
| **F14 validation** | rakun-core | `modules/rakun-validation`, whose library moves to the bundled `libs/validation` (`01-std/06-validation-lib`, decision 116) and this front's Step 7 deletes the member, moves `boot.bp` to `src/config_check.bp` with `test/config_check_test.bp`, and sets the message source at boot | `test/config_check_test.bp` |
| **F15 messaging** | rakun-messaging | `modules/rakun-messaging/src/**`, `modules/rakun-messaging/test/**` | `modules/rakun-messaging/test/**` |
| **F16 scheduling** | rakun-scheduling | `modules/rakun-scheduling/src/**`, `modules/rakun-scheduling/test/**` | `modules/rakun-scheduling/test/**` |
| **F17 logging** | rakun-logging | `modules/rakun-logging/src/**`, `modules/rakun-logging/test/**` | `modules/rakun-logging/test/**` |
| **F18 session** | rakun-session | `modules/rakun-session/src/**`, `modules/rakun-session/test/**` | `modules/rakun-session/test/**` |
| **F19 test-utilities** | rakun-test | `modules/rakun-test/src/**`, `modules/rakun-test/test/**` | `modules/rakun-test/test/**` |
| **F20 websocket** | rakun-web | `modules/rakun-web/src/websocket/**`, `modules/rakun-web/test/websocket/**` | `modules/rakun-web/test/websocket/**` |
| **F21 hateoas** | rakun-hateoas | `modules/rakun-hateoas/src/**`, `modules/rakun-hateoas/test/**` | `modules/rakun-hateoas/test/**` |
| **F22 file-routing** | rakun-app | `src/file_router.bp` (the registry: `R` handlers, the opaque `PageRenderer` per page pattern, the UI records onze copies in, the scan; the matcher is imported from the bundled library `routing` — decision 115, `01-std/04-routing-lib`), `src/sidecars/rakun_file_router.erl` | `test/file_router_test.bp` |
| **F23 ssr-pipeline** | rakun-app | `src/ssr.bp` (page serving: route → the route's `PageRenderer` onze registered → chunks, status and headers through `ChunkWriter` — `setStatus` / `setHeader` before the first write; no page signal is translated — decision 117), `src/sidecars/rakun_ssr.erl` | `test/ssr_test.bp` |
| **F24 server-actions** | rakun-app | `src/actions.bp` (the action id, the checks, dispatch over the wire names onze configures; the envelope, `state` and RPC texts are the bundled library `actions` — decision 116; the form markup is F67's) | `test/actions_test.bp` |
| **F25 route-handlers** | rakun-app | `src/route_handler.bp`, `test/route_handler_test.bp` | `test/route_handler_test.bp` |

| **F60 static-generation** | rakun-app | `src/static_gen.bp`, `src/segment_config.bp` (the `k` blob codec the browser reads is `routing`'s `route_kinds`), | `test/static_gen_test.bp` |
| **F61 parallel-intercepting-routes** | rakun-app | `src/route_slots.bp`, `src/route_intercept.bp` (the `z` codec is `routing`'s `slot_states`), | `test/parallel_routes_test.bp` |
| **F62 request-context** | rakun-core | `src/request_context.bp`, `src/request_memo.bp`, | `test/request_context_test.bp` |
| **F63 navigation-signals** | rakun-app | `src/navigation.bp` (the signals of server actions and route handlers only — page signals are jhonstart's, decision 117: the throw, the capture, the redirect checks, the response composition; the vocabulary and the `n` codec are `routing`'s `navigation` — decision 116), `src/sidecars/rakun_navigation.erl` | `test/navigation_test.bp` |
| **F64 i18n-routing** | rakun-core | `modules/rakun-i18n/botopink.json`, | `test/i18n_test.bp` |
| **F65 url-rules** | rakun-web | `modules/rakun-web/src/rules/**` (`canonicalize`, `clientHref` and the redirect-table codec are `routing`'s `url_rules`), | `test/url_rules_test.bp` |
| **F66 metadata-file-routes** | rakun-app | `src/metadata_routes.bp`, | `test/metadata_routes_test.bp` |
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

rakun targets erlang (decision 113): the core member is `"target": "erlang"`, `"targets":
["erlang"]`, and so is every other member and the workspace root — what both sides run is a bundled
library, not a rakun member: the matcher and the navigation vocabulary are `routing` (decisions 115,
116), the action protocol is `actions`, and validation is `validation` (decision 116, which removed
`rakun-validation`, the last member on commonJS); `rakun-test` is `["erlang"]` too — every rakun
manifest is (decision 117); erlang is the default target of `botopink run` / `test` in rakun. `repository/rakun/botopink.json` declares
`"targets": ["commonJS"]` at HEAD, so until front 04 sets those arrays **no rakun front can have a
green erlang row** — which would make the exit gate unfalsifiable for the whole of track B. That
change is front 04's, together with deleting `runtime.mjs` and the node server when it closes, and
it is why the manifest is in its ownership row.

Front 22 also owns the host registration cell that puts a route handler into the app
(`rkAppRegisterHandler`, generic over the response type). That is what keeps front 25 free of host
cells and true to its single-file ownership below.

Three files in `repository/rakun/src/` are **frozen for the whole milestone**: `decorators.bp`,
`http.bp`, `bootstrap.bp`. A front that believes it needs one of them stops and says so in its
README under *Blocked*; it does not edit them. `runtime.mjs` is F04's to delete when it closes
(decision 113); until then no other front edits it.

### Track C — jhonstart (`repository/jhonstart/`) — `04-jhonstart/`

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F26 router** | `src/router.bp` (promoted from `router.d.bp`, and the package's one `pairValue` pair-list decoder; `clientApp` and the client half of page signals — decision 117), `test/router_test.bp` | `test/router_test.bp` |
| **F27 link** | `modules/jhonstart-link/src/link.bp`, `modules/jhonstart-link/src/reconcile.bp` (the client-navigation reconciler), `modules/jhonstart-link/test/link_test.bp`, `modules/jhonstart-link/test/reconcile_test.bp` | `modules/jhonstart-link/test/link_test.bp` |
| **F28 server-components** | `src/server.bp` (promoted from `server.d.bp`), `test/server_test.bp` | `test/server_test.bp` |
| **F29 client-directive** | `src/client.bp`, `test/client_test.bp` | `test/client_test.bp` |
| **F30 render and streaming** | `src/render.bp` (the escaping walker, composition, the document, the payload — contract 2), `src/plugin.bp` (`RenderPlugin`, contract 6a), `Response` and the page-signal translation (contract 5d, decision 117), `src/globals.bp` (the `__bp<N>` registry: `payload`, `fill`, `signal`), `src/render.mjs`, `src/streaming.bp`, `src/suspense.bp`, `src/routes.bp` (the UI file conventions — `#[page]` / `#[layout]` / `#[template]` / `#[defaultView]`, `PageContext`, `LayoutProps`, the parameter accessors; decision 114) with `src/routes.mjs` and `src/sidecars/jhonstart_routes.erl`, `test/render_test.bp`, `test/streaming_test.bp` · the bridge member `modules/jhonstart-emilia/**` (decision 113) | `test/render_test.bp`, `test/streaming_test.bp`, `modules/jhonstart-emilia/test/**` |
| **F31 error-boundaries** | `src/error_boundary.bp`, `test/error_boundary_test.bp` | `test/error_boundary_test.bp` |
| **F32 metadata** | `src/metadata.bp`, `test/metadata_test.bp` | `test/metadata_test.bp` |

| **F67 forms** | `src/form.bp` (the binding, the hooks, `invokeAction`; `ActionState` and the envelope reader are the bundled library `actions` — decision 116), `test/form_test.bp` | `test/form_test.bp` |
| **F94 element-surface** | `src/elements.bp` (plus its inline `test` blocks), `test/elements_test.bp`, `src/root.bp`, `botopink.json` | inline tests in `src/elements.bp` |

`repository/jhonstart/src/root.bp` and `botopink.json`'s `files` list are appended to by all nine
track-C fronts. Front 94 owns both (it is wave 0 and lands first); the others append in
front-number order.

`src/element.bp`, `src/hooks.bp` and `src/html.bp` are frozen. F48 is the only front that adds to
the element attribute path, and it does so in its own file.

### Track D — emilia (`repository/emilia/`) — `05-emilia/`

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
`html_hook.bp` is jhonstart-free (it returns strings and pairs), so emilia keeps importing nobody
(decision 113); the one package that knows both is jhonstart's `jhonstart-emilia` bridge (F30).

### Track E — onze (`repository/onze/`, recreated) — `06-onze/`

| Front | Source it owns | Tests it owns |
|---|---|---|
| **F49 stand-up** | `botopink.json` (content; the skeleton is `02-packaging`'s), `modules/onze/src/root.bp`, `modules/onze/src/types.bp`, `modules/onze/src/config.bp`, `modules/onze/src/integration.bp`, | `modules/onze/test/config_test.bp`, `modules/onze/test/types_test.bp` |
| **F50 cli** | `modules/onze-cli/src/**`, `modules/onze-cli/test/**` | `modules/onze-cli/test/**` |
| **F51 image** | `modules/onze-assets/src/image.bp`, `modules/onze-assets/test/image_test.bp` | `modules/onze-assets/test/image_test.bp` |
| **F52 font** | `modules/onze-assets/src/font.bp`, `modules/onze-assets/test/font_test.bp` | `modules/onze-assets/test/font_test.bp` |
| **F53 example-app** | `examples/blog/**` (a runnable example project: its own `botopink.json`, `src/`, `test/`, `__snapshots__/`) | `examples/blog/test/**` |

| **F68 client-bundle** | `modules/onze-bundler/src/**`, | `modules/onze-bundler/test/**` |
| **F69 styling-pipeline** | `modules/onze-assets/src/**` except `src/image.bp` (F51) and `src/font.bp` (F52) | `modules/onze-assets/test/**` except `test/image_test.bp` (F51) and `test/font_test.bp` (F52) |
| **F70 image-response** | `modules/onze-og/src/**` | `modules/onze-og/test/**` |
| **F71 release-packaging** | `modules/onze-release/src/**`, | `modules/onze-release/test/**` |

## Conflict rules

Rather than a 96×96 matrix that nobody reads, the rule is stated once, the exceptions are listed, and a
section-level matrix at the end says which of the seven directories may run beside which.

**The rule.** Two fronts conflict when they write the same file. Track A, B, C and E fronts own
disjoint files by construction, so within those tracks nothing conflicts. Track D fronts share two
files by design and are made disjoint by the banner convention above.

**The exceptions, in full.**

| Pair | Shared file | Resolution |
|---|---|---|
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
| F95 → `02-packaging` | every repository, structurally | Cross-cutting: directory moves, `botopink.json` edits and empty `modules/<lib>-test/` skeletons only. Its std/asserts half moved to `01-std`. The restructure of a library lands **alongside that library's first front** (04 for rakun, 94 for jhonstart, 54 for emilia, 49 for onze), so no front creates files in an old path; `02-packaging` sequences before 49 because 49 creates files in the `modules/onze/` tree it establishes |
| `01-std` · `02-packaging` | `repository/onze/` | `01-std` removes the old mocking library (its assertions are `testing.asserts`, its mocks `testing.mocks`); `02-packaging` creates the orchestrator tree under the same path. The removal lands first; the two never hold the directory at the same time |
| `00` · `01-std` | the compiler files of `@src()` and the bundled-package registry | `01-std`'s two **named carve-outs** of `00`'s files (the `@src()` builtin and its lowering; the bundled-package registry in `build.zig`) |
| `00` · every library track | `repository/{emilia,erika,jhonstart,onze,rakun}/**` | 1.0.5's `09-ecosystem-residuals` owned the library trees. Here it does not: the trees are tracks B–E's. `09` keeps `repository/erika/**` (no track) and the meta submodule pointers, and its "re-run every library's erlang cell after 13" is an exit-gate step, run by each track after `00 · 13-module-identity` lands |
| `00 · 13-module-identity` · every erlang front | the erlang/beam emitters | No shared file; a change to the module atom or the record representation re-runs every server front's erlang cell |
| `01-std/04-routing-lib` · `05-actions-lib` · `06-validation-lib` | the bundled-package list in `build.zig` | the list holds `std`, `routing`, `actions`, `validation`; a new bundled library adds its name under the same carve-out; their `libs/<name>/**` share nothing |


## Who may run together — section level

`yes` = no shared file or snapshot directory · `seq` = no shared file, but the order matters and the
note says why · `no` = shares a file, sequence them. Symmetric. Within a section the front-level rule
above applies.

|  | 00 compiler | 01 std | 02 packaging | 03 rakun | 04 jhonstart | 05 emilia | 06 onze |
|---|---|---|---|---|---|---|---|
| **00 compiler** | — | no¹ | seq² | seq³ | seq³ | seq³ | seq³ |
| **01 std** | no¹ | — | no⁴ | seq⁵ | seq⁵ | yes | seq⁵ |
| **02 packaging** | seq² | no⁴ | — | seq⁶ | seq⁶ | seq⁶ | seq⁶ |
| **03 rakun** | seq³ | seq⁵ | seq⁶ | — | no⁷ | yes | seq⁸ |
| **04 jhonstart** | seq³ | seq⁵ | seq⁶ | no⁷ | — | no⁹ | seq⁸ |
| **05 emilia** | seq³ | yes | seq⁶ | yes | no⁹ | — | seq⁸ |
| **06 onze** | seq³ | seq⁵ | seq⁶ | seq⁸ | seq⁸ | seq⁸ | — |

1. `01-std` works in `00`'s files only through its two named carve-outs (`@src()`, the
   bundled-package registry); `libs/std/src/**` is shared with `00 · 23-std-purity` (step 6)
   and `00 · 01-checker` (`builtins.d.bp`).
2. `02-packaging` needs `modules/lib-test-runner/src/discovery.zig` only if the `BOTOPINK_LIB_ROOTS`
   route in `scripts/test-libs.sh` proves insufficient; if it does, that is a carve-out of
   `00 · 10-cli-residuals`, granted the same way as note 1.
3. A library compiles against the compiler: no shared file, but a compiler change that rewrites
   library sources lands as a named sweep through `scripts/known-red-libs.txt` — the compiler commit
   with the library in the ledger, the library sweep next, the ledger line deleted in the next
   compiler commit; never a standing red.
4. `repository/onze/`: `01-std` removes the mocking library, `02-packaging` creates the orchestrator
   tree at the same path. Removal first; never both in flight.
5. Every `-test` submodule imports `testing.asserts` and `testing.snapshots`, and every server front imports
   what front 01 adds to std. `01-std` lands first (wave 0); after that the tracks read std and never
   write it — a std need is a row handed to F01, not an edit.
6. `02-packaging` establishes the tree a library's fronts write into; the library's **first** front
   (04 · 94 · 54 · 49) lands in the same wave, after the tree. Later fronts never see the old paths.
7. Front 48 is the one cross-repository front: it adds `repository/jhonstart/src/html_attrs.bp` and
   edits nothing there. It is a track-D front; 04-jhonstart's rows do not touch that file.
8. `06-onze` consumes rakun (22–25, 62, 63), jhonstart (26–32, 94) and the
   `jhonstart-emilia` bridge (30) by contract, and is the one package that imports jhonstart and
   rakun together (decision 113); an example that combines libraries is onze's, in front 53's
   application — a library's own examples use that library only, with no dev-dependency on another
   (decision 114); front 53 consumes everything read-only. No shared file; the waves carry the order.
9. Front 48's `html_attrs.bp` (note 7), and the shared literal of contract 4 asserted on both sides
   (emilia `test/attributes_test.bp`, the `jhonstart-emilia` bridge test of F30, onze 68).

## Waves

Computed from every front README's `Depends on` line, across all five tracks at once. The inputs
are the per-track computed tables —
[`03-rakun/README.md`](./03-rakun/README.md) § *The fronts, in blocking order* (levels, with the
seven corrections of its `modules.md`), [`05-emilia/README.md`](./05-emilia/README.md) § levels,
[`04-jhonstart/README.md`](./04-jhonstart/README.md) and
[`06-onze/README.md`](./06-onze/README.md) — lifted here by the cross-track edges, which a
track-internal level cannot see: a track level is a lower bound, and this table is the milestone
level. `00-compiler-carry-over` runs beside every wave (its own order is in its README).

Three `Depends on` pairs are mutual and would make the graph cyclic; each is resolved by the
citation rule below and the resolution is recorded here rather than left to the reader: **24 ↔ 67**
(24 cites "the browser half", 67 cites "the action endpoint and its envelope" — 24 lands first, as
[`03-rakun/README.md`](./03-rakun/README.md)'s graph and
[`04-jhonstart/README.md`](./04-jhonstart/README.md)'s critical path both have it), **68 ↔ 50** and
**71 ↔ 50** (both cite the CLI that invokes them; the CLI consumes them, so it lands after —
[`06-onze/README.md`](./06-onze/README.md)). Front 11's API module has no dependency at all and can
land in wave 1; the wave below is its host half, which is what the fronts citing "11 (host)" wait on.


| Wave | Fronts | Blocked by |
|---|---|---|
| **0** | 01 · 02 · 03 · 54 · 94 · `02-packaging` · `01-std`'s asserts/snapshots/`@src()` · `01-std/04-routing-lib` · `05-actions-lib` · `06-validation-lib` | nothing |
| **1** | 04 · 05 · 26 · 56 | 01 · 54 · 94 · routing-lib |
| **2** | 06 · 22 · 27 · 28 · 33 · 34 · 35 · 55 · 57 · 58 · 62 · 74 · 80 | 04 · 05 · 26 · 56 · routing-lib |
| **3** | 07 · 08 · 11 · 13 · 14 · 15 · 19 · 21 · 23 · 29 · 31 · 32 · 36 · 37 · 38 · 39 · 40 · 41 · 42 · 43 · 44 · 45 · 46 · 47 · 59 · 72 | 06 · 22 · 28 · 33 · 34 · 35 · 62 |
| **4** | 09 · 10 · 16 · 17 · 18 · 30 · 48 · 63 · 66 · 73 · 75 · 77 · 78 · 82 · 93 | 07 · 08 · 11 · 13 · 14 · 23 · 29 · 31 · 32 · 33–47 · 72 |
| **5** | 12 · 20 · 25 · 49 · 61 · 65 · 76 · 79 · 83 · 84 · 86 | 10 · 16 · 18 · 30 · 63 · 75 · 77 |
| **6** | 24 · 60 · 64 · 68 · 81 · 85 · 87 · 89 · 90 · 91 · 92 | 12 · 20 · 49 · 76 · 79 · 83 · 86 |
| **7** | 67 · 69 · 88 | 24 · 68 · 81 |
| **8** | 51 · 52 · 71 | 69 |
| **9** | 50 · 70 | 52 · 71 |
| **10** | 53 | all |

Front 54 is track D's only wave-0 front and 56 its only wave-1 front: `Options.theme` is a `Theme`
and `defaultOptions()` calls `defaultTheme()`, so without 54 the default `flush()` would emit no
`--spacing` and every spacing utility would be dead.

A dependency annotated **`(soft)`** or **`(read-only)`** in a README's `Depends on` line is a
citation, not an edge: the front lands without it and merely reads its contract. Only unannotated
dependencies enter the graph. This is what keeps the graph acyclic where two fronts define and
enforce one thing (29 and 68), or own a store and its transport (12 and 13), or sequence a
shutdown (07 and 76).

A wave is a **level in the dependency graph, not a sprint**: a front sits one level below everything
it consumes, so no front shares a wave with something it reads. The table is computed from every
front's `Depends on` line, not hand-placed — when a front's dependencies change, the table is
regenerated, not edited. Front 22 sits below 05 because `rakun.appDir` is one of its config values;
front 26 sits directly on 01, 94 and routing-lib, because it imports `matchPath` from the bundled
library `routing` rather than from rakun (decision 115); front 23 sits below 22 and 62 only, because it serves a page and renders nothing;
front 30 sits below 29, 31 and 32, because its render calls `islandAttr`, `renderBoundaryChecked`
and `renderHead`; and onze's 49 sits below 30, 23 and 22, because its boot wires the render, the
page dispatch and the configuration together — so every onze front that needs 49 follows the render
(decision 113). The rakun corrections of [`03-rakun/modules.md § The graph`](./03-rakun/modules.md#the-graph)
(09→07 and 21→22 read-only, 07→76 and 13→12 soft, 85→23 and 86→83 seams, 93→88 reversed) and the
three mutual pairs above are applied before the levels are taken.

Wave 3 is 26 fronts wide, wave 4 is 15 and waves 5 and 6 are 11 — that is the point of the cut. The
critical path is `01 → 26 → 28 → 29 → 30 → 49 → 68 → 69 → 52 → 70 → 53`, 10 levels deep and every
step of it one `Depends on` line; the other 84 fronts are breadth. The deep tail is the full-stack one:
everything past wave 6 is a server action, a URL rule, the CLI, or an onze artifact that packages
what the waves before it produced. Ninety-five fronts is a large milestone, and the levels say where
it is long — tracks A–D reach wave 7, and only onze's own chain runs to 10.

Two fronts earn their place in wave 0 by consequence rather than by convention. `54-emilia-theme`
comes before the token fronts because four copies of the spacing ladder already exist in `emilia.bp`
and have already drifted; every front admitted after it would add a fifth. `56-emilia-cascade-and-output`
comes before them because the shape emilia emits today cannot express `@media` beside `@layer`, cannot
hold `@keyframes`, and cannot carry `group-*`, `peer-*`, `rtl`, `space-*` or `divide-*` — fronts 34,
40, 44, 55 and 58 all emit through it, and building them first means building them twice.

## Exit gate

The milestone closes when, on `feat`, all of the following hold at once:

- `zig build test` green in `repository/botopink-lang`
- `zig build test-libs` green — which covers std, emilia, jhonstart, rakun, onze and erika, **and, once
  `02-packaging` lands, every `repository/<lib>/modules/*` submodule and every `repository/<lib>/examples/*`
  project** — a submodule or example the runner does not discover is not tested, and the gate says so
  by listing the discovered cells
- every front's own test file green on **its assigned target** — erlang for the server fronts, js
  for the client fronts, both for the boundary fronts named in their READMEs and for track A
- no server front carries a **new** `@External.Node` cell, and no client front carries an
  `#[@External.Erlang]` cell; the target split in the overview is checked, not assumed. Two things
  are not violations: an **explicit refusal cell** — a host cell that exists only to return an error
  naming the target it does not serve, as std's `io.net` does on commonJS — and the **pre-existing Node forms in rakun's `modules/rakun/src/runtime.bp`** until front 04 closes, when they leave with
  `runtime.mjs` (decision 113)
- every erlang sidecar is named `src/sidecars/rakun_<name>.erl`, and no `.mjs` file exists in a
  server front
- `repository/onze/examples/blog` builds, serves, and renders its routes under both `onze dev`
  and `onze build && onze start`
- the seven remotes (meta plus six submodules) are unified on `feat`
- every `// LANGUAGE GAP:` marker left in an example file appears in [`language-gaps.md`](./language-gaps.md)
  — a gap that is only a comment in a `.bp` file is a gap nobody will fix
- every row in [`deferred.md`](./deferred.md) is still true: a deferred feature that turned out to
  have a BEAM path during implementation gets a front, not a silent carry-forward
- no `__snapshots__/**/*.snap.new` file exists in any repository — a `.new` is a snapshot nobody
  accepted (contract 7), and it is never committed
- `botopink format --check` is clean in every library, submodule and example
- every library's `modules.md` ownership table and this file agree row for row — the per-lib file is
  the source; a row that differs here is corrected here
- `00-compiler-carry-over`'s own gate (`scripts/gate.sh --cold` in `repository/botopink-lang`) is
  green — the library gate is not a substitute for the compiler gate, and the milestone does not close
  on a compiler that passes `test-libs` and fails `zig build test`

## Rules for a front

1. **One worktree, one branch, one `todo.md`** — `git worktree add .tasks/<front-name> -b fix/<front-name>`
   from the repository that owns the code. A library front's worktree is under `repository/<lib>/`;
   a `00` front's is under `repository/botopink-lang/`; `02-packaging` opens one worktree per
   repository it moves.
2. **Never edit a file you do not own** — if a fix needs one, stop and report. The carve-outs granted
   by name in this file are the only exceptions.
3. **Verify by running** — execute the emitted code, drive the server, run the CLI. Re-record a
   snapshot only for a value that was verified; a `.snap` is evidence, not a baseline.
4. **Target is assigned, not chosen** (`overview.md` § Which target runs what): a front tests on its
   assigned target and does not ship a second one for completeness.
5. **Only your sections** — in a shared file, add your fenced block and your arm; never modify
   another front's. The banner convention above is the mechanism.
6. **Exhaustive `case`, no `_` catch-all** — [`contracts.md § 4a`](./contracts.md).
7. **Tailwind values / byte-equality** — `overview.md` § Rules, the named exception to *additive
   only*.
8. **Land:** merge into `feat`, suite green in the main checkout, push, submodule bump in the meta
   repository — for a front that commits in a sibling repository, push that repository in the same
   sweep — then delete the worktree and the branch. No pull request; no `--no-verify`.
