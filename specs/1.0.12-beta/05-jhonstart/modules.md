# Modules — `repository/jhonstart` as it is on disk

The tree on `feat` (`find repository/jhonstart -name '*.bp' -o -name '*.mjs' -o -name '*.erl'`),
and what each front of this track owns in it.

## Members — seven

| Member | `src/` | `test/` | Targets | Depends on |
|---|---|---|---|---|
| **`jhonstart`** (core) | `root.bp`, `element.bp`, `elements.bp`, `hooks.bp`, `router.bp` + `router_runtime.mjs` / `sidecars/jhonstart_router.erl`, `client_app.bp` + `client_app.mjs` / `sidecars/jhonstart_client_app.erl`, `server.bp` + `server_runtime.mjs` / `sidecars/jhonstart_server.erl`, `client.bp` + `island_runtime.mjs` / `sidecars/jhonstart_island.erl`, `suspense.bp`, `streaming.bp`, `render.bp`, `render.mjs`, `plugin.bp`, `globals.bp`, `routes.bp`, `routes.mjs` / `sidecars/jhonstart_routes.erl`, `sidecars/jhonstart_render.erl`, `error_boundary.bp` + `signal_runtime.mjs` / `sidecars/jhonstart_signal.erl`, `metadata.bp`, `html_attrs.bp` (front 48's, emilia-unaware), `client_runtime.bp` + `client_runtime.mjs` | `client_app_test`, `client_test`, `error_boundary_test`, `metadata_test`, `render_test`, `router_test`, `routes_test`, `server_test`, `streaming_test` (179 tests, plus 25 inline) | inherits `["commonJS", "erlang"]` | std, `routing`, `actions` (bundled) |
| **`jhonstart-html`** | `root.bp`, `html.bp` | `elements_test`, `html_test` | inherits | `jhonstart` |
| **`jhonstart-link`** | `root.bp`, `link.bp` + `link_runtime.mjs` / `sidecars/jhonstart_link.erl`, `reconcile.bp` | `link_test` (28), `reconcile_test` (10) | inherits | `jhonstart` |
| **`jhonstart-forms`** | `root.bp`, `form.bp` + `form_runtime.mjs` / `sidecars/jhonstart_forms.erl` | `form_test` (15) | inherits | `jhonstart`, `jhonstart-link`; `actions` (bundled) |
| **`jhonstart-emilia`** | `root.bp` | `bridge_test` (10) | inherits | `jhonstart`, `jhonstart-html`, `emilia` (by `path`) |
| **`jhonstart-test`** | `root.bp`, `harness.bp`, `assert_html.bp`, `assert_route.bp`, `assert_link.bp`, `assert_server.bp`, `assert_island.bp`, `assert_stream.bp`, `assert_render.bp`, `assert_error_boundary.bp`, `assert_metadata.bp`, `assert_form.bp` | `helpers_test` (20 tests, 7 accepted snapshots) | inherits | `jhonstart`, `jhonstart-link`, `jhonstart-forms`, std |
| **`jhonstart-dom-test`** | `root.bp`, `fake_dom.mjs` | `dom_test` (8) | `["commonJS"]` — structural: no DOM on the BEAM (30-g), `botopink build --target erlang` refuses it at `src/root.bp:37`; no erlang row | `jhonstart` |

Decision 200 deletes `jhonstart-html`: front 26 step 0 moves `html.bp` and its two tests into the
core, `html` becomes the core's `pub default fn` (`import html, {Element, renderToString} from
"jhonstart";`), and `jhonstart-emilia`, `examples/jhonstart-markup` and `examples/document-shell`
import from the core — six members after it. Before that, `08-bpp/118` adds the core's
`src/prelude.bp` (decision 266) as a carve-out.

Every browser cell has an erlang twin answering the server's truth (27-a); `jhonstart-dom-test`
is the one member that needs a document. The core's `botopink.json` lists `files` in dependency
order and its `root.bp` the `pub mod` lines in front order.

## Examples — eight members

| Example | Shape | Fronts (1.0.10) | Target | `README.md` |
|---|---|---|---|---|
| `blog-ssr/` | root layout, `/blog/[slug]` with two loaders, `loading` / `error` / `not_found` / `global_error`, static + dynamic metadata | 26 · 28 · 30 · 31 · 32 · 94 | both | missing |
| `nav-shell/` | sidebar with active segment, prefetch per route kind, pending checkout link, shared-layout reuse | 26 · 27 · 94 | both | missing |
| `islands/` | like-button island, theme provider over server children, the payload `i` rows | 28 · 29 · 94 | both | missing |
| `forms/` | create-post form, optimistic like with nested `formStatus`, GET search form | 67 · 29 · 26 · 27 · 94 | both | missing — and it spells `"__bp_action"` in `src/like.bp:23`, `src/main.bp:14`, `test/forms_test.bp` and four `.snap` files (front 67 step 4) |
| `document-shell/` | the document once with constructors, once with `html """…"""` | 94 · DSL | both | missing |
| `jhonstart-counter/` | v0: `state` counter re-rendered under `client.mjs` | v0 | both | missing |
| `jhonstart-markup/` | v0: the DSL cross-module | v0 | both | missing |
| `jhonstart-todo/` | v0: pure client | v0 | both | missing |

The examples hold 32 snapshots through `jhonstart-test`. `refusals/` and `repro/` are not
members (no manifest).

## Front → files

| Front | Owns | Adds to `jhonstart-test` |
|---|---|---|
| **26** | `modules/jhonstart/**` (the core, its tests, `src/AGENTS.md`), `modules/jhonstart-dom-test/**`, `docs.md`, `examples/*/README.md` (eight), and — step 7 only — every member's `test/__snapshots__/` | nothing new; `harness.bp` gains a recording `log` sink if step 4 needs it |
| **27** | `modules/jhonstart-link/**` | `assert_link.bp` (`assertNavigation` over the driver's decision) |
| **67** | `modules/jhonstart-forms/**` except `src/form.bp:117-121` (`03-bundled-libs/103-actions-id`), `examples/forms/src/**` and `test/**`, `modules/jhonstart-dom-test/test/forms_dom_test.bp` (new; `fake_dom.mjs` is 26's — 67 stops and reports if it needs a primitive it lacks) | `assert_form.bp` (`assertActionState` over a `-test` envelope); `harness.bp`'s `stubWireNames()` (step 4) |

Files no front of this track edits: `element.bp`, `hooks.bp` (frozen — the `Children` → `Node`
rename of decisions 193 and 223 reaches `element.bp` as a hand-off from `08-bpp/118`),
`html_attrs.bp` (emilia's), the segment walk in `routes.bp`'s `page` (`:233-251`,
`03-bundled-libs/102-routing-conventions`), `render.bp:539` (`isLangTag` — `105-i18n`).

Files another track's front edits in these members, each after the front that owns the member has
landed and one at a time (`../fronts.md` § Execution order of tracks 03–08):

| Member | Front | Files |
|---|---|---|
| `jhonstart-html` (until 26 step 0), then the core's `src/html.bp` | `08-bpp/118` (in `jhonstart-html`, before 26 step 0), then one lowering arm each from 119, 120, 126 (in the core) | `html.bp`, its tests |
| `jhonstart` (core) | `08-bpp/118` before 26 opens; then 120, then 122; 116 | 118: `src/prelude.bp` (new, decision 266), the type `Children`, its step-1 bracket-attribute lines (comments only in the core) · 120: new `island_strategy.bp`, `deferred.bp`, lines of `client.bp`, `render.bp`, `island_runtime.mjs` · 122: new `response.bp`, lines of `server.bp`, `error_boundary.bp` · 116: new `bpp.bp`, `test/bpp_test.bp` |
| `jhonstart-link` | `08-bpp/126` (after 27) | new `transitions.bp`, `sidecars/transitions_runtime.mjs`, two call sites of `link_runtime.mjs` |
| `jhonstart-forms` | `08-bpp/127` (after 67 and 103) | new `typed_call.bp` |
| `jhonstart-emilia` | `08-bpp/119` | the whole member (`scopedStyle`, the sink) |
| `jhonstart-dom-test` | 67 · `08-bpp` 119, 120, 126, 127 | a test file each, owned by the front that adds it; `fake_dom.mjs` stays 26's, edited by one front at a time after 26 (decision 189) |
| `examples/jhonstart-markup` | `08-bpp/118` | the example's sources; its `README.md` is 26's |

## Relations

jhonstart and rakun never import each other; onze is the one package that names both; emilia
enters through `jhonstart-emilia` only; the bundled `routing` and `actions` are imported like
std. The core will import the bundled `log` (decision 195, 26 step 4): the boundary logs and
digests through it, and onze hands in the sink, like `allowedRedirects`; no rakun type crosses.
