# onze — the package cut

`repository/onze/modules/**` and `repository/onze/examples/**` for track E. The old `repository/onze`
(the mocking library: `src/onze.bp`, `src/onze.mjs`, one module, `botopink.json` `"files": ["onze.bp"]`)
is removed by front 01-std ([`../01-std/onze-migration.md`](../01-std/onze-migration.md)); nothing
below inherits a file from it. The orchestrator's code does not exist yet — this is the cut the nine
fronts land into.

Sources: `NEXTJS-DOCS.md` §§ 2, 3, 7, 15, 16, 17, 18, 24, 28, 29 (the framework half);
`../02-packaging/95-ecosystem-package-restructure/README.md` § 2 (the five-submodule proposal);
the [`../fronts.md`](../fronts.md) Track E ownership table; the front READMEs in this directory;
`repository/botopink-lang/modules/compiler-cli/src/cli/` (one file per subcommand, pure `parseXxxOpts`,
no parser drops a token — the shape `onze-cli` copies).

## The cut

```
repository/onze/
├── botopink.json                 { "name": "onze", … }  — lists the seven submodules
├── modules/
│   ├── onze/                     core — config, project vocabulary, alias map, env rule, boot adapter
│   ├── onze-test/                assert<Subject>(loc, …) helpers, fixtures, the E2E runner
│   ├── onze-cli/                 create · dev · build · start · info
│   ├── onze-bundler/             client module graph, refusals, chunks, manifest, hydration entry
│   ├── onze-assets/              CSS modules, stylesheet, public/, Image, fonts
│   ├── onze-og/                  ImageResponse: style parse, layout, SVG, rasterizer port
│   └── onze-release/             build id, OTP release, Dockerfile, boot script, static export
└── examples/
    ├── blog/                     front 53 — the acceptance app
    ├── scaffold/                 what `onze create --yes` writes, committed
    └── static-site/              `output: export` proof — every route prerenderable
```

Seven submodules. Front 95 proposed five (`onze`, `onze-test`, `onze-cli`, `onze-bundler`,
`onze-assets`); the front READMEs drifted to seven. The verdicts below reconcile them.

## Verdicts on every candidate

| Candidate | Proposed by | Verdict | Reason |
|---|---|---|---|
| `onze` (core) | 95 · 49 | **keep** | The vocabulary the three libraries do not share: `OnzeConfig`, `OnzeProject`, `AppFile`, `AliasMap`/`resolveAlias`, `publicEnvPrefix`/`isPublicEnvName`/`publicEnv`, `Onze.run`. Its `test/` imports only `std` (49 *Test plan*), so nothing heavier may live here |
| `onze-core` | — | **drop** (renamed) | 95's pattern names the core after the package: `modules/onze/` |
| `onze-test` | 95 | **keep** | Every library has one; this one also owns the E2E runner (`bootApp`, `request`) because booting a built app and hitting routes is what onze's tests are |
| `onze-cli` | 95 · 50 | **keep** | Runs on a developer's machine before any BEAM node exists (commonJS only); a production deploy never loads it. Copies `compiler-cli`'s shape: `main.bp` dispatch + one file per command + pure option parsers |
| `onze-bundler` | 95 · 68 | **keep, one module, two targets** | The build half (graph, refusals, chunks, entry) runs in the CLI process; `manifest.bp` compiles for both because the BEAM server reads the manifest on every render. Splitting a `onze-manifest` out would be a submodule with one file whose only consumer is the sibling next to it — 68's own argument ("one parser, two targets, one round-trip test") holds better inside one module |
| `onze-assets` | 95 (69 + 51 + 52 + 70) | **keep, and it takes 51 and 52** | One asset pipeline: one build step, one served prefix (`/_onze/static/<buildId>/`), one producer of the manifest's `Y` records. 51 and 52 both *depend on* 69 (asset manifest, `public/` serving, the head seam) — same direction, same target profile. The READMEs of 51/52 still say `repository/onze/src/image.bp` / `src/font.bp` (core); that is superseded here — core must stay `std`-only, and `Image` needs `jhonstart`, `rakun` and `rakun-cache` |
| `onze-image`, `onze-font` | implied by 51/52 *Owns* lines | **merge** into `onze-assets` | One file each; 95's rule: a submodule is not warranted by file count, only by a consumer wanting one part without the rest — nobody serves fonts without the asset pipeline that fingerprints and serves them |
| `onze-pipeline` | the 1.0.10 plan's starting list | **drop** | The render pipeline is jhonstart's (front 30) and the moments emilia's sheet is flushed are jhonstart's `RenderPlugin` calls, adapted by the `jhonstart-emilia` bridge (decision 113). onze keeps no render pipeline and no style sink for a module to hold |
| `onze-og` | 70 (95 put it under `onze-assets/src/og/`) | **keep separate** | Different target profile: erlang only, one genuine external dependency (`resvg`/`rsvg-convert` port, NIF opt-in) that front 71 must package per deployment. A site with no social cards should not carry it. Direction is `onze-og → onze-assets` (70 reads 52's metrics sidecar), never the reverse |
| `onze-release` | 71 (absent from 95's five) | **keep** | Deploy-time only: text generators (both targets) + packaging (erlang). `onze-cli` depends on it (`start` runs what it produces); a dev loop never loads it |
| `onze-dev` (dev server / HMR) | — | **drop** | `dev` is a command (`onze-cli/src/dev.bp`) over `onze-bundler`'s `rebuild`; there is no third piece |

## Target per submodule

| Submodule | Target | Split, by file |
|---|---|---|
| `onze` | both | plain records; both backends must agree on them (49) |
| `onze-test` | both | snapshot writers both; `bootApp`/`request` erlang (that is what serves) |
| `onze-cli` | commonJS | the process; its *artifacts* are tested on erlang by `examples/blog` |
| `onze-bundler` | both | `manifest.bp` both; `scan.bp`, `graph.bp`, `refusal.bp`, `chunk.bp`, `entry.bp`, `script.bp`, `rebuild.bp` commonJS (68 *Test plan*) |
| `onze-assets` | both | `image.bp` component half + `font.bp` arithmetic both; `assets.bp`, the `/_onze/image` handler and the encoder port erlang; `style_module.bp` / `stylesheet.bp` run at build time under the CLI and are asserted on erlang (69) |
| `onze-og` | erlang | tree→SVG pure; SVG→PNG leaves the VM through a port |
| `onze-release` | both | `spec.bp`, `otp.bp` (text), `docker.bp`, `lifecycle.bp` (order as data) both; `package.bp` erlang |

## Dependency graph

```
   std ──────────────┐
   rakun ────────────┤            (onze depends on rakun, rakun-routing, jhonstart, jhonstart-emilia —
   rakun-routing ────┤             never the reverse; emilia only through the bridge)
   jhonstart ────────┼──► onze ──► onze-bundler ──► onze-assets ──► onze-og
   jhonstart-emilia ─┘     │              │              │
   rakun-cache · rakun-web ┘              └──► onze-release ◄┘
                                          
   onze-cli  ──► onze · onze-bundler · onze-assets · onze-release · std      (commonJS)
   onze-test ──► testing.asserts · testing.snapshots · every submodule above          (both)
   examples/* ──► onze · onze-assets · onze-og · rakun* · jhonstart* · emilia · std
```

Edges, with the file that creates each:

| From | To | Because |
|---|---|---|
| `onze` | `rakun` | `integration.bp`: `Rakun.run(App(port, basePath))`, the UI records copied into rakun's route table, one `PageRenderer` per page through `page(pattern, render)` over rakun's `ChunkWriter`, and `rakun.actions.field` / `rakun.actions.header` set in rakun's configuration (decision 114) |
| `onze` | `jhonstart` · `jhonstart-emilia` | `integration.bp`: `app(plugins: [emiliaPlugin()])`, the `RenderHooks` tag fields, `renderStream` handed `RequestData` built from rakun's `Request`, `actionField` / `actionHeader` (decisions 113, 114) |
| `onze-bundler` | `rakun-routing` · `jhonstart` | `entry.bp` generates a client entry importing `parseTable` / `matchPath` from `rakun-routing` (compiled for commonJS) and handing jhonstart's router `match` (decision 114) |
| `onze-bundler` | `onze` | `refusal.bp` calls `isPublicEnvName` — one definition of the prefix (49 · 68) |
| `onze-assets` | `onze-bundler` | `stylesheet.bp` emits `Y` records `parseManifest` reads back; `image.bp`'s `data-src` swap is documented against the entry |
| `onze-assets` | `jhonstart` · `rakun` · `rakun-cache` | `Element` · `Request`/`HandlerResponse` (25) · the optimizer cache (12) |
| `onze-og` | `onze-assets` | `metrics.bp` reads 52's `<face>.metrics.txt` sidecar |
| `onze-release` | `onze-bundler` · `onze-assets` | `package.bp` verifies every chunk and `Y` record exists; copies `public/` |
| `onze-cli` | everything | `build.bp` drives the bundler, the stylesheet build, the release; `start.bp` runs `bin/onze` |

### The seams, and where each lives (decision 113)

onze is the only package that imports jhonstart, rakun and the `jhonstart-emilia` bridge together.
jhonstart and rakun never import each other, emilia imports nobody, and neither jhonstart nor rakun
names onze; every value that crosses is handed across by `Onze.run` (core `integration.bp`, front 49):

| Seam | Direction it must not have | Where it lives |
|---|---|---|
| emilia's sheet reaches the head and each streamed chunk, and its class list the payload's `s` | onze → emilia `flush()`, or jhonstart → emilia | jhonstart front 30 declares the asynchronous `RenderPlugin` and awaits it; the `jhonstart-emilia` bridge (`repository/jhonstart/modules/jhonstart-emilia`) awaits `flush()` in `head` / `chunk` and returns `#("s", …)` from `payload()`; `Onze.run` registers it with `app(plugins: [emiliaPlugin()])`. onze defines no sink |
| The bundle's `<script>` tags reach the document | jhonstart → onze-bundler | jhonstart's `RenderHooks.headExtra(route) -> string` and `RenderHooks.bodyExtra(route) -> string`, filled by `Onze.run` from 68's `headScriptTags` / `scriptTags`. The payload script stays jhonstart's render's (`contracts.md § 2`) |
| 68's entry generator and the render agree on the island marker and the two browser globals | jhonstart → onze-bundler if the definitions live in the bundler | The island marker is jhonstart's (front 29) and the globals registry is jhonstart's (front 30, `globals.payload` / `globals.fill`); `onze-bundler/src/entry.bp` imports both. `contracts.md § 2` is the text all cite |
| A matched route becomes a rendered page | rakun → jhonstart, or jhonstart → rakun | jhonstart's `#[page]` / `#[layout]` decorators (front 30) fill jhonstart's UI registry; `Onze.run` copies the records into rakun's table and registers one opaque `PageRenderer` per page (rakun 23, decision 114); rakun matches (22, through `rakun-routing`) and calls the renderer with its `Request` and `ChunkWriter`; the renderer calls `site.renderStream(page, requestData(req), write)`, so jhonstart receives the segment chain, the payload's rakun-side strings (`t`, `a`, `b`), the `RequestData` its `headers()` / `cookies()` read, and a plain `fn(string)` writer; jhonstart's router receives `rakun-routing`'s matcher as `match` from 68's client entry; jhonstart's not-found signal is translated by onze into rakun's 404 |
| A form names its server action | jhonstart ↔ rakun spelling one name | onze passes the field and header names to both sides — `actionField` / `actionHeader` to jhonstart (67), `rakun.actions.field` / `rakun.actions.header` to rakun (24) — default `__bp_action` / `X-Bp-Action`; neither library spells them (decision 114) |
| An example combines libraries | rakun or emilia examples importing jhonstart | onze: combined examples are front 53's application; each library's examples use that library only (decision 114) |

## What `onze-test` exposes

`modules/onze-test/src/root.bp`; every helper is `assert<Subject>(loc: SourceLocation, …) ->
@Result<void, string>` and writes `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap` per
[`../01-std/snapshots.md`](../01-std/snapshots.md). Signatures and the text each renders are in
[`test-snap.md`](./test-snap.md).

| Group | Helpers | Renders |
|---|---|---|
| core (49) | `assertConfig`, `assertAppFiles`, `assertAlias`, `assertPublicEnv` | resolved config table; classification table; alias resolutions; the filtered env table |
| cli (50) | `assertScan`, `assertGeneratedTree`, `assertTreeCheck`, `assertScaffold`, `assertBuildOutput`, `assertDevServer`, `assertInfo` | route table; `app_tree.bp` source; check errors; file tree + `onze.json`; the `<outDir>/` tree; the route table `dev` prints; `onze info` |
| bundler (68) | `assertGraph`, `assertRefusal`, `assertChunks`, `assertManifest`, `assertScriptTags`, `assertEntry` | node/chain listing; refusal messages; chunk plan; `client-manifest.txt`; tags for a route; generated `entry.bp` |
| assets (69 · 51 · 52) | `assertHead`, `assertStyleModule`, `assertStylesheet`, `assertAsset`, `assertImage`, `assertImageSource`, `assertImageHandler`, `assertFontCss`, `assertFontHead` | head fragment; generated module + rewritten CSS; the sheet; resolution table; `<img>` markup; refusal table; response headers; `@font-face` CSS; the head string |
| og (70) | `assertStyleParse`, `assertLayout`, `assertSvg`, `assertRasterizer` | property report; box tree; the SVG document; `requireRasterizer` outcome |
| release (71) | `assertBuildId`, `assertReleaseText`, `assertDockerfile`, `assertReleaseTree`, `assertShutdown`, `assertStaticExport` | id + verification; `.rel`/`sys.config`/`vm.args`/boot script; the Dockerfile; the release tree; the drain order/report; the exported tree |
| E2E (53) | `bootApp(dir, mode) -> @Future<RunningApp>`, `stopApp`, `assertResponse`, `assertBundle`, `assertCss`, `assertServeGate` | status + headers + body (hashes literal, build id masked to `<buildId>` only in `assertServeGate`); the chunk tree; a stylesheet; the dev-vs-start diff |
| builders | `fixtureTree(text) -> Fixture` (`== path` headers), `fixtureGraph(text)`, `tmpProject(fixture)` (under `.botopinkbuild/tmp/`), `sampleManifest()`, `sampleSpec()` | — |

Rules (95 § 5): import `testing.asserts`, never re-implement; no mocking runtime here — a doubled encoder is
a config value (`encoder: "/bin/true"`), a doubled datasource is front 19's.

## Front → submodule ownership

Each front lands in exactly one directory. Shared files inside a submodule follow the
`libs/std/src/root.bp` hand-off rule: the owner is named, the others hand it their line.

| Front | Directory | Source it owns | Tests it owns | Hand-offs |
|---|---|---|---|---|
| 49 stand-up | `modules/onze/` | `botopink.json`, `src/root.bp`, `src/config.bp`, `src/types.bp`, `src/integration.bp`; also the package `repository/onze/botopink.json` | `test/config_test.bp`, `test/types_test.bp` | receives nothing (51/52 no longer hand it `pub mod` lines — they moved to assets) |
| 50 cli | `modules/onze-cli/` | `botopink.json`, `src/**` (`main`, `resolve`, `scan`, `generate`, `create`, `dev`, `build`, `start`, `info`) | `test/resolve_test.bp`, `scan_test.bp`, `generate_test.bp`, `create_test.bp` | — |
| 51 image | `modules/onze-assets/` | `src/image.bp`, `src/image_handler.bp` | `test/image_test.bp` | hands 69 `pub mod image; pub mod image_handler;` |
| 52 font | `modules/onze-assets/` | `src/font.bp`, `src/font_metrics.bp` (the committed table + generator script) | `test/font_test.bp` | hands 69 `pub mod font; pub mod font_metrics;` |
| 53 example-app | `examples/blog/` | everything under it, read-only elsewhere | `examples/blog/test/**`, `test/serve.sh` | — |
| 68 client-bundle | `modules/onze-bundler/` | `botopink.json`, `src/root.bp`, `src/scan.bp`, `graph.bp`, `refusal.bp`, `chunk.bp`, `manifest.bp`, `entry.bp`, `script.bp`, `rebuild.bp` | `test/manifest_test.bp` (both), `graph_test.bp`, `refusal_test.bp`, `entry_test.bp`, `chunk_test.bp` | — |
| 69 styling-pipeline | `modules/onze-assets/` | `botopink.json`, `src/root.bp`, `src/style_module.bp`, `src/stylesheet.bp`, `src/assets.bp`, `src/preprocess.bp` | `test/style_module_test.bp`, `assets_test.bp`, `stylesheet_test.bp` | owns `root.bp` and `botopink.json` of the submodule |
| 70 image-response | `modules/onze-og/` | `botopink.json`, `src/root.bp`, `src/style.bp`, `layout.bp`, `svg.bp`, `raster.bp`, `metrics.bp`, `response.bp` | `test/style_test.bp`, `layout_test.bp`, `svg_test.bp`, `rasterize_test.bp` | — |
| 71 release-packaging | `modules/onze-release/` | `botopink.json`, `src/root.bp`, `src/spec.bp`, `otp.bp`, `docker.bp`, `package.bp`, `lifecycle.bp`, `export.bp` | `test/build_id_test.bp` (both), `release_text_test.bp` (both), `dockerfile_test.bp`, `package_test.bp` | — |
| `onze-test` | `modules/onze-test/` | filled by each front for its own `assert<Subject>`; `root.bp` owned by 49, each front hands its `pub mod` line | `test/helpers_test.bp` (49) | 49 owns `root.bp` |

Lines in the front READMEs that this table supersedes: 49 *Owns* (`src/…` → `modules/onze/src/…`);
49 *Does not touch* (`repository/onze/src/image.bp` → `modules/onze-assets/src/image.bp`); 51 and
52 *Owns* and *Does not touch*; 50 *Does not touch* (`repository/onze/src/**`); 68 *Does not touch*
(`repository/onze/src/**` → `modules/onze/src/**`).

## `repository/onze/examples/**`

| Example | Front | What it proves | Tests |
|---|---|---|---|
| `examples/blog/` | 53 | The milestone: every route in the acceptance script under `onze dev` and `onze build && onze start`; the client chunk; the stylesheet; the OG route; the release | `examples/blog/test/*_test.bp` (both) + `test/serve.sh` (erlang) — [`test-snap-examples.md`](./test-snap-examples.md) |
| `examples/scaffold/` | 50 | The committed output of `onze create scaffold --yes`; `create_test.bp` diffs a fresh `create` against it, and `--example scaffold` copies it | `examples/scaffold/test/scaffold_test.bp` |
| `examples/static-site/` | 71 · 60 | `output: export`: three static routes, no dynamic segment, no boot script; a fourth, dynamic route added in a test fails the export naming itself | `examples/static-site/test/export_test.bp` |

Each example is a package (`botopink.json` with `"dependencies"` by `path`), has its own
`__snapshots__/` beside its tests, and is compiled by `zig build test-libs` like a library.
