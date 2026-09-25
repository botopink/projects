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
│   ├── onze-assets/              style sink, CSS modules, stylesheet, public/, Image, fonts
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
| `onze-image`, `onze-font` | implied by 51/52 *Owns* lines | **merge** into `onze-assets` | One file each; 95's rule: a submodule is not warranted by file count, only by a consumer wanting one part without the rest — nobody serves fonts without the sink that inserts them |
| `onze-pipeline` | the 1.0.10 plan's starting list | **drop** (merged) | "Pipeline" is 69's style sink, and the sink is the styling half of the asset pipeline. A separate module would mirror front 23's render pipeline with no consumer able to take it without `onze-assets` — the same argument 95 uses against splitting emilia's cascade |
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
| `onze-assets` | both | `image.bp` component half + `font.bp` arithmetic both; `style_sink.bp`, `assets.bp`, the `/_onze/image` handler and the encoder port erlang; `style_module.bp` / `stylesheet.bp` run at build time under the CLI and are asserted on erlang (69) |
| `onze-og` | erlang | tree→SVG pure; SVG→PNG leaves the VM through a port |
| `onze-release` | both | `spec.bp`, `otp.bp` (text), `docker.bp`, `lifecycle.bp` (order as data) both; `package.bp` erlang |

## Dependency graph

```
   std ──────────────┐
   rakun ────────────┤            (onze depends on rakun, jhonstart, emilia — never the reverse)
   jhonstart ────────┼──► onze ──► onze-bundler ──► onze-assets ──► onze-og
   emilia ───────────┘     │              │              │
   rakun-cache · rakun-web ┘              └──► onze-release ◄┘
                                          
   onze-cli  ──► onze · onze-bundler · onze-assets · onze-release · std      (commonJS)
   onze-test ──► testing.asserts · testing.snapshots · every submodule above          (both)
   examples/* ──► onze · onze-assets · onze-og · rakun* · jhonstart* · emilia · std
```

Edges, with the file that creates each:

| From | To | Because |
|---|---|---|
| `onze` | `rakun` | `integration.bp`: `Rakun.run(App(port, basePath))` |
| `onze-bundler` | `onze` | `refusal.bp` calls `isPublicEnvName` — one definition of the prefix (49 · 68) |
| `onze-assets` | `onze-bundler` | `stylesheet.bp` emits `Y` records `parseManifest` reads back; `image.bp`'s `data-src` swap is documented against the entry |
| `onze-assets` | `emilia` · `jhonstart` · `rakun` · `rakun-cache` | `flush()` · `Element` · `Request`/`HandlerResponse` (25) · the optimizer cache (12) |
| `onze-og` | `onze-assets` | `metrics.bp` reads 52's `<face>.metrics.txt` sidecar |
| `onze-release` | `onze-bundler` · `onze-assets` | `package.bp` verifies every chunk and `Y` record exists; copies `public/` |
| `onze-cli` | everything | `build.bp` drives the bundler, the stylesheet build, the release; `start.bp` runs `bin/onze` |

### The three seams, and where each lives (decision 77)

rakun and jhonstart never call into onze; the three seams that would are inverted, not excepted:

| Seam | Direction it must not have | Where it lives |
|---|---|---|
| Front 23 (`rakun/src/ssr.bp`) calls 69's `openSink` / `collectHead` / `collectChunk` / `closeSink` | rakun → onze-assets | Those four are fields of `RenderHooks`, declared by front 23 with working defaults; `Onze.run` (core `integration.bp`) installs `onze-assets`'s implementation at boot. rakun names no module of onze |
| Front 23 emits the bundle's `<script>` tags by calling 68's `headScriptTags` / `scriptTags` | rakun → onze-bundler | Same record: `RenderHooks.headExtra(route) -> string` and `RenderHooks.bodyExtra(route) -> string`, filled from 68. The payload tag stays 23's (`contracts.md § 2`) |
| Front 29 (`jhonstart`) and 68's entry generator share `islandAttr(ordinal)` — "one definition, cited in both READMEs" | jhonstart → onze-bundler if the definition lives in the bundler | The definition lives in jhonstart (29 owns the island marker); `onze-bundler/src/entry.bp` imports it and front 23 reads it as `RenderHooks.islandAttr`. `contracts.md § 2` is the text all three cite |

The README of front 49 (*Step 4*) already requires `integration.bp` to be the place these are wired:
"`Onze.run` … the entire seam". The hooks record is what makes that sentence true once 23, 68 and
69 exist.

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
| assets (69 · 51 · 52) | `assertHead`, `assertStyleSink`, `assertStyleModule`, `assertStylesheet`, `assertAsset`, `assertImage`, `assertImageSource`, `assertImageHandler`, `assertFontCss`, `assertFontHead` | head fragment; per-chunk blocks + `emittedClasses`; generated module + rewritten CSS; the sheet; resolution table; `<img>` markup; refusal table; response headers; `@font-face` CSS; the head string |
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
| 69 styling-pipeline | `modules/onze-assets/` | `botopink.json`, `src/root.bp`, `src/style_sink.bp`, `src/style_module.bp`, `src/stylesheet.bp`, `src/assets.bp`, `src/preprocess.bp` | `test/sink_test.bp`, `style_module_test.bp`, `assets_test.bp`, `stylesheet_test.bp` | owns `root.bp` and `botopink.json` of the submodule |
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
