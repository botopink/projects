# onze — what no front covers yet

**Track:** E — onze · **Cut:** [`modules.md`](./modules.md)

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
| 17 | Variable fonts (`axes`) | 52 | deferred — `../deferred.md` |
| 17 | `next/font` `.style` object | 52 | `Font.style` string (52 § the `Font` record) |
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
