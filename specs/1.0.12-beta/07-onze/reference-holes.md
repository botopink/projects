# onze — what no front covers yet

**Track:** E — onze · **Cut:** [`modules.md`](./modules.md) · the 1.0.10 `06-onze/unification.md`,
carried whole. **missing** rows naming a front are that front's steps here (`assetPrefix` → 50,
`<Script onReady/onError>` → 50, `-H` → 50); the rest stay deferred.

Framework half of `NEXTJS-DOCS.md` vs the nine fronts. **Covered** rows omitted; each row is a
hole and where it goes.

| § | Feature | Nearest front | Status |
|---|---|---|---|
| 2 | System requirement ("Node.js ≥ 20.9") → OTP version | 49 DoD | a `docs.md` line, no acceptance test; add `onze info` printing required and found OTP |
| 7 | `import 'server-only'` / `'client-only'` markers | 68 refusal 1 | `server-only` covered; **`client-only`** (must not run on the server) has no refusal — `../deferred.md` |
| 15 | CSS-in-JS (`useServerInsertedHTML` for styled-components / emotion) | 69 | seam exists for emilia only; third-party CSS-in-JS not a botopink concept — no row |
| 15 | Tailwind | emilia (track D) | by design; not onze |
| 15 | `:global(...)` in CSS modules | 69 § *CSS Modules* | out of scope, stated |
| 16 | `images.loader` / custom loader, `unoptimized`, `imageSizes`, `minimumCacheTTL`, `dangerouslyAllowSVG`, `onLoad`/`onError` | 51 | not chartered; `deviceWidths` covers `deviceSizes`; **`unoptimized: true` per image** is the one operationally needed (pass-through only as global degradation) — `../deferred.md` |
| 16 | `getImageProps` | 51 | not needed: `Image` returns an `Element`, attrs readable |
| 17 | Variable fonts (`axes`) | 52 | deferred — `../deferred.md` |
| 17 | `next/font` `.style` object | 52 | `Font.style` string (52 § the `Font` record) |
| 18 | `ImageResponse` options `emoji`, `debug`, `status`, `headers` | 70 | `status`/`headers` are 25's `HandlerResponse`; `emoji`/`debug` not chartered |
| 18 | `twitter-image`, `icon`, `apple-icon` generated routes | 70 · rakun 66 | 66 registers the files; 70 renders only `opengraph-image`. `twitter-image` = same renderer, second file name — one row for 66 |
| 24 | Vercel / managed adapters | 71 | deliberately none: the release is the artifact |
| 24 | `output: 'standalone'` file tracing | 71 | not needed: an OTP release is the traced set |
| 28 | `redirects()` · `rewrites()` · `headers()` · `trailingSlash` | rakun 65 | rakun's `url-rules`; not in `onze.json` today — 49's README should say where they live; 124 plans `trailingSlash` / `redirects` keys there, open as `nat-f2` |
| 28 | `assetPrefix` (CDN prefix for `/_onze/static/`) | 68 · 69 | **missing**: chunk URLs are absolute under `/_onze/static/<buildId>/`; no CDN prefix. One config key through `ChunkRef.url` and `servedPrefixes` — 50 step 6 |
| 28 | `poweredByHeader`, `compress` | rakun 07 · 82 | server concerns, not onze |
| 28 | `env` (build-time inlined values) | 49 · 68 | `ONZE_PUBLIC_` only; a non-public `env` map inlined into the **server** at build is refused by design (71: config at boot, not build) |
| 28 | `transpilePackages`, `serverExternalPackages` | 68 | n/a: no npm packages in the graph |
| 28 | `webpack` / `turbopack` config, loaders, plugins | 68 | deferred by the audit; one process invocation (`preprocess`) is the whole extension surface |
| 28 | `experimental.serverActions.bodySizeLimit` / `allowedOrigins` | rakun 24 | rakun's; the `Origin`/`Host` check is in 53's acceptance |
| 28 | `productionBrowserSourceMaps` | 68 | **missing**: no source maps; compiler emits none — language gap, `../language-gaps.md` |
| 28 | `pageExtensions` | 50 | only `.bp`; no row |
| 28 | `distDir` | 49 | `outDir` |
| 28 | `generateBuildId` | 71 | covered |
| 28 | `instrumentation.js` / `register()` hook | — | **missing**: no boot hook for telemetry; nearest rakun 11/75 (actuator, metrics). `../deferred.md` |
| 29 | `next dev --hostname/-H`, `--experimental-https` | 50 | **missing** `-H` (bind address); `dev` binds `localhost` only. One flag, 50 step 2 |
| 29 | `next build --debug` / `--profile` | 50 | not chartered |
| 29 | `next lint`, `next typegen`, `next upgrade`, `next telemetry` | 50 | n/a (`botopink check` / `format`; no telemetry by design) |
| 29 | `create-next-app --typescript --eslint --tailwind --app --turbopack` | 50 | `--emilia` is the `--tailwind` analogue; rest have no counterpart |
| 29 | Fast Refresh (component state kept across a rebuild) | 68 § *Dev mode* | **missing**: entry re-runs, island state lost; stated nowhere — add to 68's README as a non-goal and to `../deferred.md` |
| 25 | `<Script onReady / onError>` | 68 *Step 7* | only `onLoad`; two callbacks — 50 step 6 |
| — | `next/dynamic` / lazy `import()` code splitting | 68 | deferred by the audit ("one chunk per route group plus one shared chunk") |
| — | Minification | 68 | declined (the fourth job); `../deferred.md` |
