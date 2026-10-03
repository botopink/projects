# Modules — `repository/onze` as it is on disk

The members' `src/` and `test/` files and their `botopink.json`, as on `feat`. Prefer the
function names below to line numbers; the file names differ from the 1.0.10 plan where noted.

## Members — eight

| Member | `src/` | `test/` | Targets | Depends on |
|---|---|---|---|---|
| **`onze`** (core) | `root.bp`, `config.bp` (with `lang`, `parsePort`, the `pub` Json accessors `membersOf` / `isObject` / `kindName` / `isString` / `strOf`), `types.bp` (`AppFile`, `AliasMap`, the segment classification), `integration.bp` (`bootSite`, `siteRender`, `rakunEntries`, `responseOver`, `chainFor`, `pageInput`) | `config_test`, `types_test`, `integration_test` (23 tests, both rows) | inherits `["commonJS", "erlang"]` | `jhonstart`, `jhonstart-forms`, `jhonstart-emilia`, `emilia` (by `path`) |
| **`onze-server`** | `root.bp`, `server.bp` (`Onze.run`, `cookiePairs`, `requestData` — `query: []`, `headers: []` —, `responseFor`, `staticRootOf`, `servedRoots`, `servePages`) | `server_test` (10 tests over a real listener) | `["erlang"]` — imports rakun | `rakun`, `rakun-app`, `rakun-web` (by `path`), `onze`, `onze-assets` |
| **`onze-test`** | `root.bp`, `core.bp` (`assertConfig`, `assertAppFiles`, `assertAlias`, `assertPublicEnv`), `fixtures.bp` (`Fixture`, `fixtureTree`) | `helpers_test` (7) | inherits | `onze` — a helper group for another member needs that member added (front 49 step 6, which 50 · 51 · 71 · 53 wait on for their group file) |
| **`onze-cli`** | `root.bp`, `main.bp` (`dev` prints "not available yet"), `resolve.bp`, `scan.bp` (the segment walk), `generate.bp`, `create.bp` (`createDefaults`, `createHelp`, the flag parser), `info.bp`, `build.bp` (`info` and `build` each declare a local `membersOf`), `start.bp` — no `dev.bp` | `scan_test`, `generate_test`, `create_test`, `build_test`, `start_test` — no `resolve_test` (31 tests) | inherits | `onze`, `onze-bundler`, `onze-assets`, `onze-release` |
| **`onze-bundler`** | `root.bp`, `manifest.bp`, `scan.bp`, `graph.bp`, `refusal.bp`, `chunk.bp` (the segment read), `fixture.bp` (the frozen fixture app every suite reads), `entry.bp` (a local `itemsOf`), `script.bp`, `rebuild.bp`, `hooks.bp` (the tags as jhonstart's `RenderHooks`), `link.bp` | `manifest_test` (both), `graph_test`, `refusal_test`, `entry_test`, `chunk_test`, `link_test`, `rebuild_test` (42 tests, both rows) | inherits | `jhonstart` (by `path`), `emilia`, `onze` |
| **`onze-assets`** | `root.bp`, `style_module.bp`, `stylesheet.bp`, `assets.bp`, `preprocess.bp`, `head.bp` (`pageRenderHooks`), `font_metrics.bp` (the transcribed table), `font.bp`, `image.bp`, `image_handler.bp` (the MIME table) | `style_module_test`, `stylesheet_test`, `preprocess_test`, `font_test`, `image_test` — no `assets_test` (its cases are in `stylesheet_test`); 28 tests | inherits | `jhonstart` (by `path`), `onze-bundler` |
| **`onze-og`** | `root.bp`, `card_style.bp` (the plan's `style.bp` — jhonstart exports a `style` element), `metrics.bp` (a local `intOf` cell), `layout.bp`, `svg.bp` (a local `intOf` cell), `raster.bp`, `response.bp` | `og_test` (one file, 10 tests) | inherits | `jhonstart` (by `path`); it parses front 52's sidecar itself — no `onze-assets` edge |
| **`onze-release`** | `root.bp`, `spec.bp`, `otp.bp` (`bootScriptText`'s `BUILD_ID` check), `docker.bp`, `package.bp`, `lifecycle.bp`, `static_export.bp` (the plan's `export.bp`) | `build_id_test` (both), `release_text_test` (both), `package_test` — no `dockerfile_test` (its cases are in `release_text_test`); 9 tests, five `.snap` under `__snapshots__/release/` | inherits | `onze`, `onze-bundler` |

The workspace `botopink.json` is `name onze`, targets `["commonJS", "erlang"]`, workspaces
`["modules/*", "examples/*"]`.

## Examples — two members (a third planned)

| Example | Front | What | `README.md` |
|---|---|---|---|
| `blog/` | 53 | the acceptance app under `src/` (53-a): `app/{layout,page,not-found}.bp`, `app/blog/**`, `app/(marketing)/about/`, `app/login/`, `app/dashboard/**`, `components/{nav,post_card,like_button}.bp`, `lib/db.bp`; tests `db_test`, `render_test`, `tags_test` (both rows) | missing |
| `scaffold/` | 50 | `onze create --yes`'s committed output at the project root (`app/`, `root.bp`; `"src": "."`), targets both | missing |
| `static-site/` | 71 | `output: export` — **does not exist** (71 step 4) | — |

`examples/README.md` (directory-level) describes the three; it is not an example's README.

## Front → files, in this milestone

Four fronts run together on disjoint files; the fifth is read-only against them.

| Front | Owns | Hand-offs |
|---|---|---|
| **49** (carries 69) | `modules/onze/**`, `modules/onze-server/**`, `modules/onze-test/{botopink.json,src/root.bp,src/core.bp,src/fixtures.bp}` and the group stubs it creates (`src/{cli,bundler,assets,og,release,e2e}.bp` — empty modules with their `pub mod` lines, so no later front touches `root.bp`), `docs.md`, `AGENTS.md` | 50 · 51 · 71 · 53 fill the group file each owns |
| **50** (carries 68) | `modules/onze-cli/**`, `modules/onze-bundler/**`, `examples/scaffold/**`, `modules/onze-test/src/{cli,bundler}.bp` | step 5 consumes 71's `bin/onze` |
| **51** (carries 52 · 70) | `modules/onze-assets/**` (its `root.bp` and `botopink.json` included — the lowest-numbered front owning the member here; 69's items moved to 49, which touches only `onze-server`), `modules/onze-og/**`, `modules/onze-test/src/{assets,og}.bp` | the `/_onze/image` route's registration line in `onze-server/src/server.bp` is handed to 49 (one line, one commit, 49's) |
| **71** | `modules/onze-release/**`, `examples/static-site/**` (new), `modules/onze-test/src/release.bp` | `onze-cli/src/{build,start}.bp`'s two lines (`includeErts` passed; `start` execs `bin/onze`) are 50 step 5's |
| **53** | `examples/blog/**`, `modules/onze-test/src/e2e.bp`, `examples/blog/test/serve.sh` | read-only elsewhere; a needed change is reported to its owner |

Files a `03-bundled-libs` front owns for the duration of its landing, never edited at the same
time: `onze/src/types.bp`'s segment classification, `onze-cli/src/scan.bp`'s segment walk, `onze-bundler/src/chunk.bp`'s segment read
(`102-routing-conventions` step 3 — before 49 and 50 open, decision 188); `onze-server/src/server.bp`'s `cookiePairs`,
`onze-assets/src/image_handler.bp`'s MIME table (`104-http`'s consumer sweep — after 49 and 51 have
landed); `onze-release/src/{otp,docker,spec}.bp` (`107-release`, after 71).

Files an `08-bpp` front adds or edits here, each after the front that owns the member has landed:

| Member | `08-bpp` front | Files | After |
|---|---|---|---|
| `onze-content` (new, the ninth member) | 121 | the whole member | — (no other front) |
| `onze` (core) | 117 · 122 · 124 | new `src/paginate.bp` (117); the `site` key of `src/config.bp` (122) and the other four keys (124) — decision 189 | 49 |
| `onze-server` | 120 | one line of `src/server.bp` (the island route) | 49 |
| `onze-cli`, `onze-bundler` | 117 · 124 | `onze-cli/src/scan.bp` (117); `main.bp`, `build.bp`, new `sync.bp`, `key.bp`, new `onze-bundler/src/{component_script,style_sheet}.bp` (124) | 50 and 102; 124 last of the track |
| `examples/scaffold` | 124 | the `.bpp` scaffold | 50 |
| `examples/blog` | 121 step 7 | `content/**`, `src/lib/db.bp` | 53 |

## Targets

A manifest's `targets` is the single source of truth (decision 153): `onze-server` is
`["erlang"]` (it imports rakun); every other member and both examples run both rows.

## Relations

Unchanged from 1.0.10's cut: onze imports jhonstart, rakun (through `onze-server` only) and the
bridge; nothing imports onze; onze defines no style sink; onze reads no navigation signal. New in
this milestone: `onze-server` sets the bundled `log`'s sink to rakun's logger and nothing else
(49 step 3; decisions 194, 195); `types.bp` consumes `routing.conventions` once `102` lands
(49-d amended).
