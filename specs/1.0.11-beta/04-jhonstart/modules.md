# Modules — `repository/jhonstart` as it is on disk

Measured with `find repository/jhonstart -name '*.bp' -o -name '*.mjs' -o -name '*.erl'` at the
opening of this milestone. This file supersedes the 1.0.10 `modules.md`: the cut it argued for
landed, with one member it did not foresee (`jhonstart-dom-test`, decision 30-g) and the five
example projects it planned.

## Members — seven

| Member | `src/` | `test/` | Targets | Depends on |
|---|---|---|---|---|
| **`jhonstart`** (core) | `root.bp`, `element.bp`, `elements.bp`, `hooks.bp`, `router.bp` + `router_runtime.mjs` / `sidecars/jhonstart_router.erl`, `client_app.bp` + `client_app.mjs` / `sidecars/jhonstart_client_app.erl`, `server.bp` + `server_runtime.mjs` / `sidecars/jhonstart_server.erl`, `client.bp` + `island_runtime.mjs` / `sidecars/jhonstart_island.erl`, `suspense.bp`, `streaming.bp`, `render.bp`, `render.mjs`, `plugin.bp`, `globals.bp`, `routes.bp`, `routes.mjs` / `sidecars/jhonstart_routes.erl`, `sidecars/jhonstart_render.erl`, `error_boundary.bp` + `signal_runtime.mjs` / `sidecars/jhonstart_signal.erl`, `metadata.bp`, `html_attrs.bp` (front 48's, emilia-unaware), `client_runtime.bp` + `client_runtime.mjs` | `client_app_test`, `client_test`, `error_boundary_test`, `metadata_test`, `render_test`, `router_test`, `routes_test`, `server_test`, `streaming_test` | inherits `["commonJS", "erlang"]` | std, `routing`, `actions` (bundled) |
| **`jhonstart-html`** | `root.bp`, `html.bp` | `elements_test`, `html_test` | inherits | `jhonstart` |
| **`jhonstart-link`** | `root.bp`, `link.bp` + `link_runtime.mjs` / `sidecars/jhonstart_link.erl`, `reconcile.bp` | `link_test`, `reconcile_test` | inherits | `jhonstart` |
| **`jhonstart-forms`** | `root.bp`, `form.bp` + `form_runtime.mjs` / `sidecars/jhonstart_forms.erl` | `form_test` | inherits | `jhonstart`, `jhonstart-link`; `actions` (bundled) |
| **`jhonstart-emilia`** | `root.bp` | `bridge_test` | inherits | `jhonstart`, `jhonstart-html`, `emilia` (by `path`) |
| **`jhonstart-test`** | `root.bp`, `harness.bp`, `assert_html.bp`, `assert_route.bp`, `assert_link.bp`, `assert_server.bp`, `assert_island.bp`, `assert_stream.bp`, `assert_render.bp`, `assert_error_boundary.bp`, `assert_metadata.bp`, `assert_form.bp` | `helpers_test` (21 cases, one accepted snapshot per family) | inherits | `jhonstart`, `jhonstart-link`, `jhonstart-forms`, std |
| **`jhonstart-dom-test`** | `root.bp`, `fake_dom.mjs` | `dom_test` | `["commonJS"]` — no DOM on the BEAM (30-g); the erlang cell is a ledger line (`00-gate`) | `jhonstart` |

Every browser cell has an erlang twin answering the server's truth (27-a); `jhonstart-dom-test`
is the one member that needs a document. The core's `botopink.json` lists `files` in dependency
order and its `root.bp` the `pub mod` lines in front order (the hand-off boxes of 1.0.10 are
closed on tick).

## Examples — eight members

| Example | Shape | Fronts | Target | `README.md` |
|---|---|---|---|---|
| `blog-ssr/` | root layout, `/blog/[slug]` with two loaders, `loading` / `error` / `not_found` / `global_error`, static + dynamic metadata | 26 · 28 · 30 · 31 · 32 · 94 | both | missing |
| `nav-shell/` | sidebar with active segment, prefetch per route kind, pending checkout link, shared-layout reuse | 26 · 27 · 94 | both | missing |
| `islands/` | like-button island, theme provider over server children, the payload `i` rows | 28 · 29 · 94 | both | missing |
| `forms/` | create-post form, optimistic like with nested `formStatus`, GET search form | 67 · 29 · 26 · 27 · 94 | both | missing — and `src/like.bp:23` spells `"__bp_action"` (front 67 step 4) |
| `document-shell/` | the document once with constructors, once with `html """…"""` | 94 · DSL | both | missing |
| `jhonstart-counter/` | v0: `state` counter re-rendered under `client.mjs` | v0 | both (101 dropped the stale restriction) | missing |
| `jhonstart-markup/` | v0: the DSL cross-module | v0 | both | missing |
| `jhonstart-todo/` | v0: pure client | v0 | both (101 dropped the stale restriction) | missing |

The five planned projects hold 32 snapshots through `jhonstart-test`. `refusals/` and `repro/`
are not members (no manifest; the 1.0.10 repros are closed in the compiler).

## Front → files, in this milestone

| Front | Owns | Adds to `jhonstart-test` |
|---|---|---|
| **26** | `modules/jhonstart/**` (the core, its tests, `src/AGENTS.md`), `modules/jhonstart-dom-test/**`, `docs.md`, `examples/*/README.md` (eight), and — step 7 only — every member's `test/__snapshots__/` | nothing new; `harness.bp` gains a recording of `RenderHooks.onError` if step 4 needs it |
| **27** | `modules/jhonstart-link/**` | `assert_link.bp` (`assertNavigation` over the driver's decision) |
| **67** | `modules/jhonstart-forms/**` except `src/form.bp:117-121` (`07-bundled-libs/103-actions-id`), `examples/forms/src/**`, `modules/jhonstart-dom-test/test/forms_dom_test.bp` (new; `fake_dom.mjs` is 26's — 67 stops and reports if it needs a primitive it lacks) | `assert_form.bp` (`assertActionState` over a `-test` envelope) |

Files no front of this track edits: `element.bp`, `hooks.bp`, `html.bp` (frozen), `html_attrs.bp`
(emilia's), `routes.bp:178-195` (`07-bundled-libs/102-routing-conventions`), `render.bp:453`
(`isLangTag` — `105-i18n`), `error_boundary.bp:77` beyond step 4's `onError` (`106-log`, if `07-f`
chooses the package).

## Relations

Unchanged from 1.0.10: jhonstart and rakun never import each other; onze is the one package that
names both; emilia enters through `jhonstart-emilia` only; the bundled `routing` and `actions` are
imported like std. Front 26's `RenderHooks.onError` is a function value onze hands in, like
`allowedRedirects` — no rakun type crosses.
