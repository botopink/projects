# onze — unification (1.0.7 → 1.0.9 → 1.0.10)

Proof that nothing was lost. Per 1.0.7 draft: the 1.0.9 front that absorbed it, what the 1.0.10 copy
carries, and what had to be appended under `## Carried from 1.0.7-beta FNN <name>` in the copy's
README. Then the Next.js reference rows the merge still misses.

## 1.0.9 → 1.0.10: what the copy changed

| Change | Where | Count |
|---|---|---|
| Directories copied verbatim (`cp -r`) | `49 · 50 · 51 · 52 · 53 · 68 · 69 · 70 · 71` — 9 READMEs, 38 example `.bp` files | 9 fronts |
| `onze13` → `onze` (prose, `Replaces:` paths, `OnzeConfig`, `OnzeProject`, `Onze.run`) | all 9 READMEs + `49/examples/config-example.bp`, `49/examples/integration-example.bp` | 34 identifiers |
| One note per README, first paragraph, naming the 1.0.7 draft directory | all 9 READMEs | 9 |
| `**Replaces:** \`1.0.7-beta/NN-onze13-…\`` → "the 1.0.7-beta draft named in the note above" | 49 · 50 · 51 · 52 · 53 | 5 |
| `](../language-gaps.md)` → `](../language-gaps.md)` | 53 | 1 |
| `` `specs/1.0.9-beta/contracts.md § N` `` → `` `../../contracts.md § N` `` | 68 · 69 | 2 |
| Cross-front references are by number in prose, not links; none rewritten | — | 0 |

Residual `onze13` after normalisation: the note (9), the `## Carried from 1.0.7-beta FNN onze13-…`
headings, the quoted source paths and the `[sic: onze13]` markers (49–53) — nothing else.

## 1.0.7 → 1.0.9: per draft

| 1.0.7 path | 1.0.9 → 1.0.10 path | Verdict | Appended |
|---|---|---|---|
| `specs/1.0.7-beta/01-onze13-stand-up/README.md` | `06-onze/49-onze-stand-up/README.md` | **appended** | `ActionResponse` → 24's `ActionResult`, `RouteSegmentConfig` → 60's `SegmentConfig` (missing from 49's *does not build* table); `bpmp` registry recognition; opt-in note; `requires` map spelling superseded |
| `specs/1.0.7-beta/19-onze13-cli/README.md` | `06-onze/50-onze-cli/README.md` | **appended** | `create` runs `bpmp install`; `bpmp` integration → deferred; `lang` attribute on the scaffolded document (`--lang`); `botopink dev` superseded |
| `specs/1.0.7-beta/20-onze13-image-optimization/README.md` | `06-onze/51-onze-image/README.md` | **appended** | `h` query parameter dropped, stated as a decision; redirect-from-handler superseded; `<outDir>/images/` cache location |
| `specs/1.0.7-beta/21-onze13-font-optimization/README.md` | `06-onze/52-onze-font/README.md` | **appended** | `Font.style` (the inline-style string) added as a sixth field; variable fonts → deferred; preconnect unnecessary |
| `specs/1.0.7-beta/22-onze13-example-app/README.md` | `06-onze/53-onze-example-app/README.md` | **appended** | `app/dashboard/page.bp`, `lib/auth.bp`, `app/globals.css` row, `app/blog/[slug]/opengraph-image.bp` row, `public/images/hero.jpg` + `favicon.ico`, `DEPLOY.md` |
| `specs/1.0.7-beta/examples-bp.md` §§ F01 · F19 · F20 · F21 · F22 | the `examples/` of 49 · 50 · 51 · 52 · 53 | **fully covered** (table below) | the two details that were not — `lang` on the document, two Google families — are in the 50 and 52 sections |
| `specs/1.0.7-beta/overview.md` rows 7 · 25–28 · Arquitetura onze13 · Mapeamento Next.js → onze13 · Estrutura de um projeto | 1.0.9 `overview.md` Track E rows · this track's [`README.md`](./README.md) · [`modules.md`](./modules.md) | **fully covered** | the mapping table's onze rows (`next/image`, `next/font`, `ImageResponse`, `create-next-app`, `next dev/build/start`, `next.config.js`) each have a front: 51 · 52 · 70 · 50 · 50 · 49 |
| `specs/1.0.7-beta/fronts.md` rows F01 · F19 · F20 · F21 · F22 | [`modules.md`](./modules.md) § *Front → submodule ownership* | **superseded** | the 1.0.7 paths (`repository/onze13/src/**`, `modules/onze13-cli/**`) become `modules/onze/**`, `modules/onze-cli/**`, `modules/onze-assets/**` |

### `examples-bp.md` snippets → files

No new file was extracted: every snippet has a 1.0.9 example that carries it against the settled
API, and the snippet's own API (`PageProps`, `googleFont(family, subsets:)`, `NextResponse`,
`MiddlewareConfig`) is the one the 1.0.9 fronts retired.

| Snippet | Carried by |
|---|---|
| F01 *Configuração do projeto (onze13.json)* | `49/examples/config-example.bp` (`OnzeConfig`, `defaultConfig`) |
| F01 *Importando onze13* (`HomePage`) | `50/examples/scaffold-example.bp` |
| F01 *Usando tipos de integração* (`BlogPost(props: PageProps<…>)`) | `49/examples/integration-example.bp` and `53/examples/blog-slug-page-example.bp` (`PageContext`, `route.params.lookup`) |
| F19 *Criando um novo projeto* (`onze13 create / dev`) | `50/README.md` *Steps 5–6* |
| F19 *layout.bp gerado*, *page.bp gerado* | `50/examples/scaffold-example.bp` — the `lang` attribute is appended to 50's README |
| F20 *Componente Image* (`sizes: "(max-width: 768px) 100vw, 50vw"`) | `51/examples/image-example.bp` |
| F21 *Google Fonts* (Inter + Fira Code), *Local Font* | `52/examples/font-example.bp` — the two-family case is appended to 52's README |
| F22 `app/layout.bp` | `53/examples/app-layout-example.bp` |
| F22 `app/blog/page.bp` | `53/examples/blog-list-page-example.bp` |
| F22 `components/post-card.bp` | `53/examples/post-card-example.bp` |
| F22 `middleware.bp` | `53/examples/middleware-example.bp` |

## Reference coverage the merge still misses

The framework half of `NEXTJS-DOCS.md`, section by section, against the nine fronts. **Covered** rows
are omitted; each row below is a hole, with where it goes.

| § | Feature | Nearest front | Status |
|---|---|---|---|
| 2 | System requirement statement ("Node.js ≥ 20.9") → OTP version | 49 DoD | stated as a `docs.md` line, no acceptance test; add `onze info` printing the required and found OTP |
| 7 | `import 'server-only'` / `'client-only'` markers | 68 refusal 1 | `server-only` covered; **`client-only`** (a module that must not run on the server) has no refusal — `../deferred.md` |
| 15 | CSS-in-JS (`useServerInsertedHTML` for styled-components / emotion) | 69 | the seam exists for emilia only; third-party CSS-in-JS is not a botopink concept — no row |
| 15 | Tailwind | emilia (track D) | by design; not onze |
| 15 | `:global(...)` in CSS modules | 69 § *CSS Modules* | out of scope, stated |
| 16 | `images.loader` / custom loader, `unoptimized`, `imageSizes`, `minimumCacheTTL`, `dangerouslyAllowSVG`, `onLoad`/`onError` | 51 | not chartered; `deviceWidths` covers `deviceSizes`; **`unoptimized: true` per image** is the one operationally needed (pass-through exists only as a global degradation) — `../deferred.md` |
| 16 | `getImageProps` | 51 | not needed: `Image` returns an `Element`, its attrs are readable |
| 17 | Variable fonts (`axes`) | 52 | appended as deferred |
| 17 | `next/font` `.style` object | 52 | appended (`Font.style` string) |
| 18 | `ImageResponse` options `emoji`, `debug`, `status`, `headers` | 70 | `status`/`headers` are 25's `HandlerResponse`; `emoji`/`debug` not chartered |
| 18 | `twitter-image`, `icon`, `apple-icon` generated routes | 70 · rakun 66 | 66 registers the files; 70 renders only `opengraph-image`. `twitter-image` is the same renderer under a second file name — one row for 66 |
| 24 | Vercel / managed adapters | 71 | deliberately none: the release is the artifact |
| 24 | `output: 'standalone'` file tracing | 71 | not needed: an OTP release is the traced set |
| 28 | `redirects()` · `rewrites()` · `headers()` · `trailingSlash` | rakun 65 | rakun's `url-rules`; `onze.json` does not carry them — the README of 49 should say where they live |
| 28 | `assetPrefix` (CDN prefix for `/_onze/static/`) | 68 · 69 | **missing**: chunk URLs are absolute paths under `/_onze/static/<buildId>/`; a CDN origin cannot be prefixed. One config key, threaded through `ChunkRef.url` and `servedPrefixes` — a small front or a 68 step |
| 28 | `poweredByHeader`, `compress` | rakun 07 · 82 | server concerns, not onze |
| 28 | `env` (build-time inlined values) | 49 · 68 | covered via `ONZE_PUBLIC_` only; a non-public `env` map inlined into the **server** at build time is refused by design (71: configuration at boot, not at build) |
| 28 | `transpilePackages`, `serverExternalPackages` | 68 | n/a: no npm packages in the graph |
| 28 | `webpack` / `turbopack` config, loaders, plugins | 68 | deferred by the audit; one process invocation (`preprocess`) is the whole extension surface |
| 28 | `experimental.serverActions.bodySizeLimit` / `allowedOrigins` | rakun 24 | rakun's; the `Origin`/`Host` check is in 53's acceptance |
| 28 | `productionBrowserSourceMaps` | 68 | **missing**: no source maps anywhere; the compiler emits none — language gap, `../language-gaps.md` |
| 28 | `pageExtensions` | 50 | only `.bp`; no row |
| 28 | `distDir` | 49 | `outDir` |
| 28 | `generateBuildId` | 71 | covered |
| 28 | `instrumentation.js` / `register()` hook | — | **missing**: no boot hook for telemetry; the nearest is rakun 11/75 (actuator, metrics). `../deferred.md` |
| 29 | `next dev --hostname/-H`, `--experimental-https` | 50 | **missing** `-H` (bind address); `dev` binds `localhost` only. One flag, 50 *Step 6* |
| 29 | `next build --debug` / `--profile` | 50 | not chartered |
| 29 | `next lint`, `next typegen`, `next upgrade`, `next telemetry` | 50 | n/a (`botopink check` / `format`; no telemetry by design) |
| 29 | `create-next-app --typescript --eslint --tailwind --app --turbopack` | 50 | `--emilia` is the `--tailwind` analogue; the rest have no botopink counterpart |
| 29 | Fast Refresh (component state preserved across a rebuild) | 68 § *Dev mode* | **missing**: the entry is re-run and island state is lost; stated nowhere — add to 68's README as a non-goal and to `../deferred.md` |
| 25 | `<Script onReady / onError>` | 68 *Step 7* | only `onLoad`; two callbacks — 68 *Step 7* row |
| — | `next/dynamic` / lazy `import()` code splitting | 68 | deferred by the audit ("one chunk per route group plus one shared chunk") |
| — | Minification | 68 | declined (the fourth job); `../deferred.md` |
