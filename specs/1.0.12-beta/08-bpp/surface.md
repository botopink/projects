# 08-bpp — surface: every Astro feature, and where it lands on the stack

Reference: Astro docs under `/home/ericfillipe/develop/astro/astro-docs/` (25 pages,
`01-why-astro.md` … `25-actions.md`), page by page. Paths relative to `repository/` (six repos);
"not found" = a tree search.

## How to read it

Decision 113: jhonstart HTML, rakun service, emilia CSS, onze wiring; their Next.js-shaped halves
are on disk, so most of Astro is there, or there and unwired.

| Box | Meaning |
|---|---|
| **have** | Exists and runs; row names the file |
| **wire** | A library has it, onze does not connect it; row names the owning front of another track |
| **add · NNN** | Added by this track, front *NNN* |
| **gap** | Needs a compiler change; row names nearest form and `language-gaps.md` row |
| **n/a** | Meaningless on this stack; reason stated |

---

## 01 · Why Astro, 02 · Islands architecture

| Astro | The stack today | Box · owner |
|---|---|---|
| Server-first: a component renders to HTML and ships no JavaScript | all components render on the server; only `#[client]` functions reach the bundle (`jhonstart/modules/jhonstart/src/client.bp:102`) | have |
| Zero JS by default | client graph built from `#[client]` entries, refuses server-only imports (`onze/modules/onze-bundler/src/refusal.bp:55-138`) | have |
| Client islands, hydrated in isolation | `Island(id, component, props)`, `clientMount`, `mountIsland` (`client.bp:206-218`, `render.bp:218`) — eager; re-render via `innerHTML`, not DOM-preserving (`island_runtime.mjs`) | have |
| "load when idle", "load when visible" | not found: eager; only strategies are `<Script>`'s (`onze-bundler/src/script.bp:18-21`) | add · 120 |
| Server islands | not found; `Suspense` streams in the same response (`suspense.bp:19-45`) — cannot make the shell cacheable | add · 120 |
| UI-agnostic (React, Vue, Svelte, …) | one UI library | n/a — decision 113: jhonstart writes the HTML |
| Content collections | not found | add · 121 |
| Integrations (`astro add`) | a dependency in `botopink.json` | n/a — no plugin host; the track adds none |

## 03 · Install, 05 · Develop and build, 06 · Configuration

| Astro | The stack today | Box · owner |
|---|---|---|
| `create astro` | `onze create` (`onze/modules/onze-cli/src/main.bp:19-104`) | have |
| `--template`, `--add` | `--example`, an open tail of `07-onze/50` | wire · `07-onze/50` |
| `astro dev` on `localhost:4321`, live reload | `onze dev` answers "not available yet" (`main.bp:101`) | wire · `07-onze/50` (decision 50-b) |
| `astro build` → `dist/` | `onze build` compiles to `.onze/`; `staticExport(outDir)` writes `<path>/index.html` (`rakun/modules/rakun-app/src/static_gen.bp:620`), not called by the build | wire · `07-onze/50` (ONZ-50-7: `prerender/` in the build output) · `07-onze/71` (ONZ-71-7: static export to disk) |
| `astro preview` | `onze start` runs `onze build`'s output (50-a) | have |
| `astro check` | `botopink check` | have |
| `astro.config.mjs` + `defineConfig` | `onze.json`, unknown key refused (49-c); keys `name port basePath appDir publicDir outDir dev actionsBodyLimit allowedRedirects lang` (`onze/src/config.bp:192-193`) | have |
| `site`, `trailingSlash`, `output`, `redirects`, `image.domains`, `prefetch` | not in `onze.json`; `base` is `basePath`; no `output` (decision 202) | add · 124 (`site` · 122) |
| `tsconfig.json`, editor extension | `botopink.json`; VS Code extension registers `.bp` only (`vscode-extension/package.json:24-31`) | add · 116 (for `.bpp`) |
| Dev toolbar | — | n/a — out of scope: browser tool, not framework |
| SEO head by a `<Head />` component | `Metadata`, `mergeMetadata`, `renderHead` (`jhonstart/src/metadata.bp:59-254`); onze passes `[]` (`onze-server/src/server.bp:116`) | wire · `07-onze/53` (ONZ-53-3) |

## 04 · Project structure

| Astro | The stack today | Box · owner |
|---|---|---|
| `src/pages/` | `app/` (`appDir`), a directory per route, eight kinds: `page layout template default loading error not-found route` (`onze/src/types.bp` `appFileKinds`) | have — decision 203 (one convention) |
| `src/components/`, `src/layouts/`, `src/styles/` | free directories; layouts are `layout.bp` in the route tree | have |
| `public/` | `publicDir`, unregistered — `/**` before the routes once rakun-web's miss falls through (decision 201) | wire · `07-onze/49` |
| `src/content.config.ts` | not found | add · 121 |
| import aliases | app module imported by braced path (`import {lib.db.findPost};`, decisions 206, 218); onze's `alias` key and `@/` go (`07-onze/50` step 9) | have |

## 07 · Pages, 08 · Routing

| Astro | The stack today | Box · owner |
|---|---|---|
| `.astro` pages | `page.bp`, `#[page("<dir>")]` on `fn(route: PageContext) -> @Component<Element>` (`jhonstart/src/routes.bp:14`, `:315`) | have |
| the page as a single file — script fence + markup | not found: a function returning builder calls | add · 116 · 118 |
| `.md` pages | not found | add · 121 |
| `.html` pages | not found | add · 117 |
| `.js` / `.ts` endpoints | `route.bp`, `#[getRoute]` … `#[optionsRoute]` (`rakun-app/src/route_handler.bp:243-381`); `serveApp` not installed by onze | wire · `07-onze/49` |
| file → route | `[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `_private` (`botopink-lang/libs/routing/src/segment.bp:36-74`) | have |
| two parameters in one segment (`[lang]-[version]`) | not found: `parseSegment` reads `[`…`]` as one parameter, named `lang]-[version` (`botopink-lang/libs/routing/src/segment.bp:36-74`) | add · 117 |
| `getStaticPaths()` returning `params` | `registerStaticParams(seg, fn() -> @Task<StaticParams[]>)` (`static_gen.bp:106`) | have |
| `getStaticPaths()` returning `props` | not found: a row binds parameters only | add · 117 |
| a dynamic route with no `getStaticPaths` is an error in static mode | `prerenderAll(strict)` (`static_gen.bp:478`) | have |
| `export const prerender = false` | `SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` registered by a `val` (`segment_config.bp:38`) — deleted by 290 (`revalidate`, `dynamicParams` become `#[page]` arguments); mode derived — reading request data marks it dynamic | n/a — decision 202 — no page declares its stage: `#[page]` prerenders at comptime a page reaching no `#[serverOnly]` hook; nothing forces per-request |
| redirects in config | redirect table in `routing/url_rules` | wire · add · 124 — `04-rakun/65`, 124 (the config key) |
| `Astro.redirect(url, status)` | `redirect(url)` raises `nav:redirect:<loc>`, 303 / 307 / 308 on the wire (`jhonstart/src/error_boundary.bp:187`, `routing/navigation`) | have |
| `Astro.rewrite(url)` from a page | not found; `Next.rewrite` in middleware only (`rakun-web/src/middleware.bp:41-58`) | add · 122 |
| route priority (8 rules) | `matchPath` (`routing/src/match.bp:178`); rule 6 (endpoint over page) is a **refusal** — `page` + `route` in one segment do not build (`file_router.bp:382`) | have · add · 117 — asserts the eight rules as tests |
| reserved routes (`_astro/`, `_server_islands/`, `_actions/`) | `/_onze/image` (`onze-assets/src/image_handler.bp:107`) | add · 120 — reserves `/_onze/island/` |
| `paginate()` and the `page` prop | not found | add · 117 |
| `_`-prefixed files excluded | scan skips `_folder` | have |
| `404`, `500` with the `error` prop | `not-found.bp`, `error.bp`; `ErrorInfo(message, digest)` (`error_boundary.bp:67`) | have |
| page partials (`export const partial = true`) | not found | add · 117 |
| links are plain `<a>` | `Link(props, children)` with prefetch; plain `a(…)` (`jhonstart-link/src/link.bp:123`) | have |
| advanced routing (`src/fetch.ts`, Hono) | rakun's pipeline, composed in botopink | n/a — already the program's own code |

## 09 · Components, 10 · Layouts, 13 · Template syntax

| Astro | The stack today | Box · owner |
|---|---|---|
| component script between `---` fences | the component function's body | have — 116 gives it the fence |
| `Astro.props`, a `Props` interface, defaults | the function's parameters; default applied at the call (`docs.md:1320-1356`) | have |
| `{expression}` in markup | `html """…"""`: `${expr}` lowers to `text(expr)`, so a hole is a string (`jhonstart-html/src/html.bp:189`) | add · 118 |
| attributes | **static attributes dropped from the tree** — LSP overlay only (`html.bp:138-146`, `:233-234`); only `[name]={expr}` renders (`:117-136`) | add · 118 |
| a value with a space in an attribute | tag body split on single spaces (`html.bp:110`) | add · 118 |
| `{items.map((x) => <li>{x}</li>)}` — markup inside an expression | not found | add · 118 |
| `{cond && <p/>}`, `{cond ? a : b}` | not found; no ternary, no `&&` value form — spelled `{if (cond) { <p/> }}` | add · 118 |
| `<Component prop={v} />` | `<Card>` lowers to `Card([kids], attrs: […])` like any tag; "`<Component/>` lookup stays a future layer" (`html.bp:30`) | add · 118 |
| a self-closing tag | stored, emitted at the **root** after the loop (`html.bp:212-217`, `:250-253`) — read, not run | add · 118 — step 0 measures it |
| dynamic tags (`const Element = "div"`) | `el(tag, children, attrs)` (`jhonstart/src/elements.bp:31`) in a hole | have |
| `<> </>`, `<Fragment>` | `fragment([...])`; several roots wrapped automatically (`html.bp:265-267`) | have · add · 118 (the tag spelling) |
| `<Fragment set:html={s} />`, `set:html`, `set:text` | `raw(html)` (`jhonstart/src/render.bp:204`) | have — as values: `{raw(s)}`, `{s}` (278); 118 makes `raw` a hole |
| kebab-case attributes, several roots, HTML comments | builders take any attribute name; no comments in the DSL | add · 118 |
| `<slot />` | a builder's `children` argument | have — 118 gives it the tag |
| named slots, fallback content, slot transfer | `LayoutProps.slots` always `[]` (`render.bp:296`); no named slot on a component | add · 118 |
| `Astro.slots.has()` / `.render()` | not found | add · 118 |
| `Astro.self` | a function calls itself by name | have |
| `.html` components | not found | gap — no file becomes a component; nearest: the markup pasted into a component, or read with `@embedFile` (342) |
| layouts with `<slot />` | `layout.bp` + `LayoutProps.children`; nested by directory (`render.bp:341` `compose`) | have |
| a layout chosen by the page, by import | the directory chain; a page may call any component | have |
| Markdown layouts (`layout:` in frontmatter, the `frontmatter` / `headings` props) | not found | add · 121 |
| `template.bp`, `loading.bp`, parallel `@slot` routes | have — no Astro equivalent | have |

## 11 · Styling

| Astro | The stack today | Box · owner |
|---|---|---|
| scoped `<style>` in a component | not found. emilia: typed utility compiler over `Token[]`, no CSS processor (`emilia/AGENTS.md:602`); DSL `<style>` lowers to the `style` builder, verbatim | add · 119 — the `--- style ---` section (or `use styled """…"""` in a `.bp`), scoped by `jhonstart-styled` through the repositories `styled` and `css`; `<style>` in markup refused but `#[isInline]` (338) |
| `is:global`, `:global()` | not found | add · 119 — `:global(…)` only; site-wide CSS in `globals.css` (338) |
| `class:list` | `cls` / `clsWith` for emilia tokens (`emilia/src/emilia.bp:186-210`); nothing for plain class names | add · 118 — a value, `class={classList([…])}` (278) |
| `define:vars` | not found | add · 119 — a run-time hole in the style section, `${value}` → a CSS variable on the root element (338) |
| inline `style` as an object | a string attribute | n/a — no object literal; the string is the form |
| importing a stylesheet | `globals.css` read at build (`onze-cli/src/build.bp:112-114`); `*.module.css` renames classes to `<file>_<class>_<hash6>` (`onze-assets/src/style_module.bp:1-36`) | have |
| Tailwind | emilia: `emilia(tokens)`, `flush()`, `@layer`s, class `e_<hash>` (`emilia.bp:112-235`) | have — in markup `<h1 #[styled(…)]>`, `class={emilia(tokens)}` leaves templates (301; 119 step 4) |
| Sass / Less / Stylus / PostCSS / LightningCSS | — | n/a — no preprocessor host; CSS or emilia tokens |
| cascade order: link, imported, scoped | bridge puts emilia's flush in the head (`jhonstart-emilia/src/root.bp:95`) | add · 119 — fixes the order; `jhonstart-styled`'s one sheet (338) |
| per-page CSS chunks, inlining under 4 kB | one stylesheet | add · 124 |

## 12 · Framework components

| Astro | The stack today | Box · owner |
|---|---|---|
| `client:load` | `#[client]` + `mountIsland` — the only behaviour | have · named `#[clientLoad]` · 120 (278) |
| `client:idle`, `client:visible`, `client:media` | not found | add · 120 — `#[clientIdle]`, `#[clientVisible]`, `#[clientMedia]` (278) |
| `client:only` | not found | add · 120 — `#[clientOnly]`, the same function as the hook marker (278) |
| props to an island: plain data only | `#[clientProps]` whitelists `string`, `i32`, `f64`, `bool` (`client.bp:137`) — narrower than Astro | have · add · 120 (arrays, nested `#[clientProps]` records) |
| children passed to an island | `serverSlot(children)` (`client.bp:277`) | have |
| nesting islands | not measured | add · 120 step 0 |
| mixing frameworks | — | n/a — one UI library |
| hydrating an Astro component is an error | a `Hydrate` annotation on a function without `#[client]` | add · 120 — a compile error |
| event handlers in an island | attribute written (`data-jh-on-click="LikeButton:like"`, `jhonstart/modules/jhonstart/test/client_test.bp:150`), no listener reads it: the one `addEventListener` under `modules/jhonstart/src` is the `jh:refresh` button (`island_runtime.mjs:98`) | wire · handed to `05-jhonstart` — README § Handed |

## 14 · Markdown, 15 · Content collections, 19 · Images

| Astro | The stack today | Box · owner |
|---|---|---|
| Markdown → HTML, GFM, heading ids, smart punctuation | not found anywhere. Blog posts are text files: line 1 title, line 2 date, then body (`onze/examples/blog/src/lib/db.bp:52-59`) | add · 121 |
| YAML / TOML frontmatter | rakun config's YAML subset (`rakun/modules/rakun/src/config.bp:340`); no TOML | add · 121 (decision `08-f`) |
| importing a `.md`: `frontmatter`, `<Content />`, `rawContent()`, `compiledContent()`, `getHeadings()` | not found | add · 121 |
| `import.meta.glob` | `fs.glob` at run time (`libs/std/src/io/fs.bp:122`) | gap — comptime reads named files only (`@embedFile`, 342), no glob; collections load at build and boot |
| processor choice (Sätteri / Unified), remark / rehype plugins | — | n/a — no plugin host; 121 takes one `fn(MdNode) -> MdNode` |
| MDX | — | n/a — Markdown with components is a template; 118 is the form |
| `defineCollection`, `glob()`, `file()` loaders, custom loaders | not found | add · 121 |
| schema validation of entries with Zod | `libs/validation` validates typed values only | add · 125 — `03-bundled-libs/125` |
| `reference("authors")` | not found | add · 121 |
| `getCollection`, `getEntry`, filters, `render(entry)` | not found | add · 121 |
| live collections | a function that fetches at request time | n/a — an ordinary `@Task` function; a second API adds nothing |
| JSON Schema files for data entries | not found | add · 125 — the `#[validated]` type's `jsonSchema` member (306) |
| `<Image />` with `srcset`, an optimising endpoint | `Image(p, cfg, publicDir)`, `/_onze/image` (`onze-assets/src/image.bp:196`, `image_handler.bp:107`); route unregistered | wire · `07-onze/51` |
| `<Picture />`, `getImage()`, `image.domains`, remote patterns | not found; remote sources answer 501 | wire · `07-onze/51` (ONZ-51-DoD) |
| SVG as a component | not found | gap — same row; nearest: inline `<svg>` in a component, or `@embedFile` (342) |
| images in Markdown, `image()` in a collection schema | not found | add · 121 |
| Sharp, the asset cache | an encoder port; single-flight an open box (ONZ-51-5) | wire · `07-onze/51` |

## 16 · Endpoints, 17 · Middleware, 18 · Data fetching, 21 · On-demand rendering

| Astro | The stack today | Box · owner |
|---|---|---|
| `GET` / `POST` / … / `ALL` exported from a file | one decorated function per verb in `route.bp` | have |
| `HEAD` answered from `GET` | dispatcher falls back to `GET` (`route_handler.bp:16`, `:495`) | have |
| static file endpoints (`data.json.ts` built into a file) | `staticExport` writes pages only | n/a — decisions 222, 273: a route handler is served per request; a static file is a page-kind file (117) |
| `params`, `request`, `redirect` in an endpoint | `Request`, `HandlerResponse` (`route_handler.bp:45`) | have |
| `src/middleware.ts`, `onRequest(context, next)` | `middleware.bp`, `#[middleware]` + `#[matcher]`, `Next.pass / redirect / rewrite` (`rakun-web/src/middleware.bp:41-83`) | have |
| `context.locals` | **not found** | add · 123 — request-scoped cardume atoms, store `rakun-cardume`'s (295, 296) |
| `sequence(a, b, c)` | ordered filter chain with bands (`rakun-web/src/filter.bp:162-173`, `:319`) | have · add · 123 (the one-line spelling) |
| rewriting the response body after `next()` | not found: `Response` is a frozen record | add · 123 |
| `context.rewrite()`, `next(request)` | `Next.rewrite` | have |
| middleware runs for 404 and 500 | not measured | add · 123 step 0 |
| `fetch()` in the component script, top-level `await` | `io.http.fetch(url)` — GET only (`libs/std/AGENTS.md`); `await` in a `@Component` body | have · wire — `02-std-and-packaging` (method, headers, body) |
| adapters (Node, Netlify, Vercel, Cloudflare) | one runtime: BEAM, packaged by `onze-release` | n/a — rakun is erlang-only by manifest |
| `output: "server"` | every page `Auto`: mode derived from what the render reads | n/a — decision 202 — no `output` key |
| HTML streaming | `App.renderStream`, boundaries in completion order (`streaming.bp:935-957`) | have |
| `Astro.cookies` | `cookies()` reads (`jhonstart/src/server.bp:270`); writes in a handler, action or middleware (`rakun/src/request_context.bp:586`, `:752`) | have — becomes `use cookie(decl)` over a declared `Cookie<T>` (294) |
| `Astro.request`, `.url`, `.method`, `.headers` | `request()` → `RequestData(method, path, params, query, headers, cookies)` (`server.bp:106`, `:252`); onze fills `query`, `headers` with `[]` | wire · `07-onze/49` (ONZ-49-4.3); read with `use request()` (291) |
| `Astro.response.status`, `.headers` | not found from a page | add · 122 |
| returning a `Response` from a page | navigation signals only | add · 122 |
| sessions | `Session`, three stores (`rakun-session`) | have |
| i18n routing | `registerLocales`, `negotiate`, locale redirect (`rakun-app/src/i18n.bp`) | have — `03-bundled-libs/105` |

## 20 · View transitions

| Astro | The stack today | Box · owner |
|---|---|---|
| `<ClientRouter />` — client-side navigation | click interception, `pushState` (`jhonstart-link/src/link_runtime.mjs:41-71`); driver `reconcile()` unwritten (`reconcile.bp:40`) | wire · `05-jhonstart/27` |
| `transition:name`, `transition:animate` → `#[transitionName]`, `#[transitionAnimate]` (278), built-in `fade` / `slide` / `none` / `initial`, custom animations | not found — no `startViewTransition` in the tree | add · 126 |
| `transition:persist`, `transition:persist-props` | not found | add · 126 — `#[transitionPersist]`, `#[transitionPersistProps]` (278) |
| `data-astro-reload`, `data-astro-history` | not found | add · 126 — `#[reload]`, `#[history(.Replace)]` (292) |
| `navigate(href)` | no public function | add · 126 |
| forms through the router | `formMount` (`jhonstart-forms/src/form.bp:173`) | have |
| lifecycle events (`before-preparation` … `page-load`) | not found | add · 126 |
| route announcer, `prefers-reduced-motion` | not found | add · 126 |
| prefetch | `prefetchMode`, `IntersectionObserver` + `x-jh-prefetch` (`link.bp:163`, `link_runtime.mjs`) | have |

## 22 · Server islands

| Astro | The stack today | Box · owner |
|---|---|---|
| `server:defer` | not found | add · 120 — `#[serverDefer]` (278) |
| `slot="fallback"` | `Boundary.fallback`, same idea within one response | add · 120 — `#[serverDefer(fallback: …)]`, an annotation argument, no `slot="…"` (287) |
| props serialised, encrypted, in the query; `POST` past 2 048 bytes | not found | add · 120 (decisions 224, 272: `sealed` by default, or `server`) |
| `Cache-Control` on the island response | not found | add · 120 |
| the page URL through `Referer` | — | add · 120 |
| `astro create-key`, `ASTRO_KEY` | not found | add · 124 |

## 23 · Client-side scripts

| Astro | The stack today | Box · owner |
|---|---|---|
| `<script>` in a component: bundled, deduplicated, `type="module"` | `script` builder, verbatim; onze's `<Script>` with four strategies (`onze-bundler/src/script.bp:18-21`) | add · 124 |
| `is:inline` | the verbatim behaviour above | have · named `#[isInline]` (278) |
| scripts from `src/` and from `public/` | `<Script>` | have |
| passing data through `data-*` | any attribute | have |
| custom elements | plain HTML | have |
| TypeScript in a script | a `#[client]` function, botopink compiled to commonJS | n/a — typed client code is an island |

## 24 · TypeScript

| Astro | The stack today | Box · owner |
|---|---|---|
| typed props, `ComponentProps<typeof X>` | a function's parameters | have |
| `HTMLAttributes<"a">`, polymorphic components | attributes are `Array<#(string, string)>` | n/a — no per-tag attribute typing; the template checks names against a table (118) |
| `InferGetStaticPropsType` | `<name>Params(route)` emitted by `#[page]` (`routes.bp:233-262`) | have — becomes `use params<P>()` / `use pageData<D>()` (293) |
| `App.Locals`, `env.d.ts` | — | add · 123 (one atom declaration per local, 295) |
| `astro check` | `botopink check` | have |

## 25 · Actions

| Astro | The stack today | Box · owner |
|---|---|---|
| `defineAction({ handler })`, called from the client | `#[serverAction]` on `fn(form: FormData) -> @Task<ActionResult>`, HMAC ids (`rakun-app/src/actions.bp:170`, `:237`); dispatcher not installed by onze | wire · `07-onze/49` (ONZ-49-4.5) |
| `input:` — a schema that validates and types the input | `form.field("title")` by hand, inline checks (`07-onze/53/examples/server-action-example.bp`) | add · 127, on 125 — a `#[validated]` input type (306) |
| `accept: "form"` and the per-input rules | `bodyForm` (`route_handler.bp:168`) | add · 127 — `bind<T>` |
| `{ data, error }`, `.orThrow()` | `ActionResult`, `ActionEnvelope` (`libs/actions`) | have · add · 127 (a typed `data`) |
| `ActionError` with a `code` | `ActionResult.invalid(field, message)` | add · 127 |
| `isInputError(error)`, `error.fields` | `ActionState.fields`, `fieldError(name)` (`libs/actions`) | have |
| `<form action={actions.x}>` without JavaScript | `formAction`, `actionForm` (`jhonstart-forms/src/form.bp:119-137`) | have |
| `Astro.getActionResult()` | `actionState` (`form.bp:182`) | have |
| `Astro.callAction()` | an action is a function; it is called | have |
| `getActionContext()` in middleware | not found | add · 123 |
| actions nested in objects (`actions.user.getUser`) | the module path | have |

---

## Count

161 rows, by the Box column's first word (a partial row counts for what it already is):

| Box | Rows |
|---|---|
| have | 59 |
| wire (another track's front owns the connection) | 14 |
| add (this track) | 70 |
| gap | 3 |
| n/a | 15 |

Additions per named front: 118 14, 120 13, 121 11, 117 7, 123 and 126 6 each, 124 5, 119 and
127 4 each, 122 4, 116 2; 2 land in `03-bundled-libs/125`.
