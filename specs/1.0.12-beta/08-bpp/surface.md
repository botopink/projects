# 08-bpp — surface: every Astro feature, and where it lands on the stack

The reference is the Astro documentation transcribed under
`/home/ericfillipe/develop/astro/astro-docs/` (25 pages, `01-why-astro.md` … `25-actions.md`). This
file walks it page by page. The botopink side is the six repositories under `repository/`; paths
below are relative to that directory, and a "not found" means a search of the tree, not of
memory.

## How to read it

The stack is already a port of a file-routed, server-first framework: decision 113 gives jhonstart
the HTML, rakun the service, emilia the CSS and onze the wiring, and their Next.js-shaped halves
are on disk. So most of Astro is not new work — it is either there, or there and not
connected. Each row falls in one box:

| Box | Meaning |
|---|---|
| **have** | It exists and runs today; the row names the file |
| **wire** | A library has it, onze does not connect it; the row names the front of another track that owns the wiring |
| **add · NNN** | This track adds it, in front *NNN* |
| **gap** | It needs a compiler change; the row names the nearest form and the `language-gaps.md` row |
| **n/a** | It has no meaning on this stack; the reason is stated |

---

## 01 · Why Astro, 02 · Islands architecture

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| Server-first: a component renders to HTML and ships no JavaScript | every component renders on the server; only `#[client]` functions reach the bundle (`jhonstart/modules/jhonstart/src/client.bp:102`) | have | — |
| Zero JS by default | the client graph is built from `#[client]` entries and refuses server-only imports (`onze/modules/onze-bundler/src/refusal.bp:55-138`) | have | — |
| Client islands, hydrated in isolation | `Island(id, component, props)`, `clientMount`, `mountIsland` (`client.bp:206-218`, `render.bp:218`) — eager, and a re-render through `innerHTML` rather than DOM-preserving hydration (`island_runtime.mjs`) | have | — |
| "load when idle", "load when visible" | not found: hydration is eager; the only strategies in the tree are `<Script>`'s (`onze-bundler/src/script.bp:18-21`) | add · 120 | 120 |
| Server islands | not found; a `Suspense` boundary streams inside the same response (`suspense.bp:19-45`), which is a different thing — it cannot make the shell cacheable | add · 120 | 120 |
| UI-agnostic (React, Vue, Svelte, …) | one UI library | n/a | decision 113: jhonstart writes the HTML |
| Content collections | not found | add · 121 | 121 |
| Integrations (`astro add`) | a dependency in `botopink.json` | n/a | no plugin host exists, and the track adds none |

## 03 · Install, 05 · Develop and build, 06 · Configuration

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `create astro` | `onze create` (`onze/modules/onze-cli/src/main.bp:19-104`) | have | — |
| `--template`, `--add` | `--example` is an open tail of `07-onze/50` | wire | `07-onze/50` |
| `astro dev` on `localhost:4321`, live reload | `onze dev` answers "not available yet" (`main.bp:101`) | wire | `07-onze/50` (decision 50-b) |
| `astro build` → `dist/` | `onze build` stages and compiles to `.onze/`; `staticExport(outDir)` writes `<path>/index.html` (`rakun/modules/rakun-app/src/static_gen.bp:620`) and is not called by the build | wire | `07-onze/50` (ONZ-50-7: `prerender/` in the build output) · `07-onze/71` (ONZ-71-7: static export to disk) |
| `astro preview` | `onze start` runs what `onze build` produced (50-a) | have | — |
| `astro check` | `botopink check` | have | — |
| `astro.config.mjs` + `defineConfig` | `onze.json`, unknown key refused (49-c); keys `name port basePath appDir publicDir outDir dev actionsBodyLimit allowedRedirects lang` (`onze/src/config.bp:192-193`) | have | — |
| `site`, `trailingSlash`, `output`, `redirects`, `image.domains`, `prefetch` | not in `onze.json`; `base` is `basePath`; `output` is not added (decision 202) | add · 124 (`site` · 122) | 124 |
| `tsconfig.json`, editor extension | `botopink.json`; the VS Code extension registers `.bp` only (`vscode-extension/package.json:24-31`) | add · 116 | 116 (for `.bpp`) |
| Dev toolbar | — | n/a | out of scope: a browser-side tool, not a framework feature |
| SEO head by a `<Head />` component | `Metadata`, `mergeMetadata`, `renderHead` (`jhonstart/src/metadata.bp:59-254`) — onze passes `[]` (`onze-server/src/server.bp:116`) | wire | `07-onze/53` (ONZ-53-3) |

## 04 · Project structure

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `src/pages/` | `app/` (`appDir`), one directory per route, eight file kinds: `page layout template default loading error not-found route` (`onze/src/types.bp` `appFileKinds`) | have | decision 203 (one convention) |
| `src/components/`, `src/layouts/`, `src/styles/` | free directories; layouts are `layout.bp` files in the route tree | have | — |
| `public/` | `publicDir`, not registered yet — `/**` before the routes once rakun-web's miss falls through (decision 201) | wire | `07-onze/49` |
| `src/content.config.ts` | not found | add · 121 | 121 |
| import aliases | `alias` in `botopink.json` (`@/lib.db`) | have | — |

## 07 · Pages, 08 · Routing

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `.astro` pages | `page.bp` with `#[page("<dir>")]` on a `fn(route: PageContext) -> @Component<ElementBase, Element>` (`jhonstart/src/routes.bp:220`) | have | — |
| the page as a single file — script fence + markup | not found: a page is a function that returns builder calls | add · 116 · 118 | 116, 118 |
| `.md` pages | not found | add · 121 | 121 |
| `.html` pages | not found | add · 117 | 117 |
| `.js` / `.ts` endpoints | `route.bp`, `#[getRoute]` … `#[optionsRoute]` (`rakun-app/src/route_handler.bp:243-381`); `serveApp` is not installed by onze | wire | `07-onze/49` |
| file → route | `[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `_private` (`botopink-lang/libs/routing/src/segment.bp:36-74`) | have | — |
| two parameters in one segment (`[lang]-[version]`) | not found: `parseSegment` reads a segment that starts with `[` and ends with `]` as one parameter, so this one is a parameter named `lang]-[version` (`botopink-lang/libs/routing/src/segment.bp:36-74`) | add · 117 | 117 |
| `getStaticPaths()` returning `params` | `registerStaticParams(seg, fn() -> @Task<StaticParams[]>)` (`static_gen.bp:106`) | have | — |
| `getStaticPaths()` returning `props` | not found: a row binds parameters only | add · 117 | 117 |
| a dynamic route with no `getStaticPaths` is an error in static mode | `prerenderAll(strict)` (`static_gen.bp:478`) | have | — |
| `export const prerender = false` | `SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` registered by a `val` (`segment_config.bp:38`); the mode is also derived — reading request data marks the render dynamic | n/a | decision 202 — no page declares its stage: `#[page]` prerenders at comptime a page that reaches no `#[serverOnly]` hook, and nothing forces per-request |
| redirects in config | a redirect table in `routing/url_rules` | wire · add · 124 | `04-rakun/65`, 124 (the config key) |
| `Astro.redirect(url, status)` | `redirect(url)` raises `nav:redirect:<loc>` with 303 / 307 / 308 on the wire (`jhonstart/src/error_boundary.bp:187`, `routing/navigation`) | have | — |
| `Astro.rewrite(url)` from a page | not found; `Next.rewrite` exists in middleware only (`rakun-web/src/middleware.bp:41-58`) | add · 122 | 122 |
| route priority (8 rules) | `matchPath` (`routing/src/match.bp:178`); rule 6 (an endpoint over a page) is a **refusal** here — `page` and `route` in one segment do not build (`file_router.bp:382`) | have · add · 117 | 117 asserts the eight rules as tests |
| reserved routes (`_astro/`, `_server_islands/`, `_actions/`) | `/_onze/image` (`onze-assets/src/image_handler.bp:107`) | add · 120 | 120 reserves `/_onze/island/` |
| `paginate()` and the `page` prop | not found | add · 117 | 117 |
| `_`-prefixed files excluded | `_folder` skipped by the scan | have | — |
| `404`, `500` with the `error` prop | `not-found.bp`, `error.bp`; `ErrorInfo(message, digest)` (`error_boundary.bp:67`) | have | — |
| page partials (`export const partial = true`) | not found | add · 117 | 117 |
| links are plain `<a>` | `Link(props, children)` with prefetch, and a plain `a(…)` (`jhonstart-link/src/link.bp:123`) | have | — |
| advanced routing (`src/fetch.ts`, Hono) | the server is rakun's pipeline, composed in botopink | n/a | the pipeline is already the program's own code |

## 09 · Components, 10 · Layouts, 13 · Template syntax

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| component script between `---` fences | the body of the component function | have | 116 gives it the fence |
| `Astro.props`, a `Props` interface, defaults | the function's parameters; a parameter default is applied at the call (`docs.md:1320-1356`) | have | — |
| `{expression}` in markup | `html """…"""`: a `${expr}` hole lowers to `text(expr)`, so a hole is a string (`jhonstart-html/src/html.bp:189`) | add · 118 | 118 |
| attributes | **static attributes are dropped from the tree** — they reach the LSP overlay only (`html.bp:138-146`, `:233-234`); `[name]={expr}` is the one form that renders (`:117-136`) | add · 118 | 118 |
| a value with a space in an attribute | the tag body is split on single spaces (`html.bp:110`) | add · 118 | 118 |
| `{items.map((x) => <li>{x}</li>)}` — markup inside an expression | not found | add · 118 | 118 |
| `{cond && <p/>}`, `{cond ? a : b}` | not found; the language has no ternary and no `&&` value form — the spelling is `{if (cond) { <p/> }}` | add · 118 | 118 |
| `<Component prop={v} />` | `<Card>` lowers to `Card([kids], attrs: […])` like any tag; "`<Component/>` lookup stays a future layer" (`html.bp:30`) | add · 118 | 118 |
| a self-closing tag | stored and emitted at the **root** after the loop (`html.bp:212-217`, `:250-253`) — read from the code, not run | add · 118 | 118 step 0 measures it |
| dynamic tags (`const Element = "div"`) | `el(tag, children, attrs)` (`jhonstart/src/elements.bp:31`), written in a hole | have | — |
| `<> </>`, `<Fragment>` | `fragment([...])`; several roots are wrapped automatically (`html.bp:265-267`) | have · add · 118 | 118 (the tag spelling) |
| `<Fragment set:html={s} />`, `set:html`, `set:text` | `raw(html)` (`jhonstart/src/render.bp:204`) | add · 118 | 118 |
| kebab-case attributes, several roots, HTML comments | builders take any attribute name; comments not found in the DSL | add · 118 | 118 |
| `<slot />` | a builder's `children` argument | have | 118 gives it the tag |
| named slots, fallback content, slot transfer | `LayoutProps.slots` exists and is always `[]` (`render.bp:296`); a component has no named slot | add · 118 | 118 |
| `Astro.slots.has()` / `.render()` | not found | add · 118 | 118 |
| `Astro.self` | a function calls itself by name | have | — |
| `.html` components | not found | gap | a comptime body cannot read a file (lg2-o); nearest: the markup pasted into a component |
| layouts with `<slot />` | `layout.bp` + `LayoutProps.children`; nested by directory (`render.bp:341` `compose`) | have | — |
| a layout chosen by the page, by import | the directory chain; a page may also call any component | have | — |
| Markdown layouts (`layout:` in frontmatter, the `frontmatter` / `headings` props) | not found | add · 121 | 121 |
| `template.bp`, `loading.bp`, parallel `@slot` routes | have — and Astro has no equivalent | have | — |

## 11 · Styling

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| scoped `<style>` in a component | not found. emilia is a typed utility compiler over `Token[]`, not a CSS processor (`emilia/AGENTS.md:602`); `<style>` in the DSL lowers to the `style` builder, verbatim | add · 119 | 119 |
| `is:global`, `:global()` | not found | add · 119 | 119 |
| `class:list` | `cls` / `clsWith` for emilia tokens (`emilia/src/emilia.bp:186-210`); nothing for plain class names | add · 118 | 118 |
| `define:vars` | not found | add · 119 | 119 |
| inline `style` as an object | a string attribute | n/a | there is no object literal; the string is the form |
| importing a stylesheet | `globals.css` is read at build (`onze-cli/src/build.bp:112-114`); `*.module.css` renames classes to `<file>_<class>_<hash6>` (`onze-assets/src/style_module.bp:1-36`) | have | — |
| Tailwind | emilia: `emilia(tokens)`, `flush()`, `@layer`s, class `e_<hash>` (`emilia.bp:112-235`) | have | — |
| Sass / Less / Stylus / PostCSS / LightningCSS | — | n/a | no preprocessor host; CSS is written as CSS or as emilia tokens |
| cascade order: link, imported, scoped | the bridge puts emilia's flush in the head (`jhonstart-emilia/src/root.bp:95`) | add · 119 | 119 fixes the order |
| per-page CSS chunks, inlining under 4 kB | one stylesheet | add · 124 | 124 |

## 12 · Framework components

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `client:load` | `#[client]` + `mountIsland` — the only behaviour | have | — |
| `client:idle`, `client:visible`, `client:media` | not found | add · 120 | 120 |
| `client:only` | not found | add · 120 | 120 |
| props to an island: plain data only | `#[clientProps]` whitelists `string`, `i32`, `f64`, `bool` (`client.bp:137`) — narrower than Astro's list | have · add · 120 | 120 (arrays, nested `#[clientProps]` records) |
| children passed to an island | `serverSlot(children)` (`client.bp:277`) | have | — |
| nesting islands | not measured | add · 120 | 120 step 0 |
| mixing frameworks | — | n/a | one UI library |
| hydrating an Astro component is an error | `client:*` on a function without `#[client]` | add · 120 | 120 — a compile error |
| event handlers in an island | the attribute is written (`data-jh-on-click="LikeButton:like"`, `jhonstart/modules/jhonstart/test/client_test.bp:150`) and no listener reads it: the one `addEventListener` under `modules/jhonstart/src` is the `jh:refresh` button (`island_runtime.mjs:98`) | wire | handed to `05-jhonstart` — README § Handed |

## 14 · Markdown, 15 · Content collections, 19 · Images

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| Markdown → HTML, GFM, heading ids, smart punctuation | not found anywhere. The blog's posts are text files: line 1 title, line 2 date, then the body (`onze/examples/blog/src/lib/db.bp:52-59`) | add · 121 | 121 |
| YAML / TOML frontmatter | rakun config's YAML subset (`rakun/modules/rakun/src/config.bp:340`); TOML not found | add · 121 | 121 (decision `08-f`) |
| importing a `.md`: `frontmatter`, `<Content />`, `rawContent()`, `compiledContent()`, `getHeadings()` | not found | add · 121 | 121 |
| `import.meta.glob` | `fs.glob` at run time (`libs/std/src/io/fs.bp:122`) | gap | a comptime body has no filesystem (lg2-o); collections load at build and at boot |
| processor choice (Sätteri / Unified), remark / rehype plugins | — | n/a | no plugin host; 121 takes one `fn(MdNode) -> MdNode` |
| MDX | — | n/a | Markdown with components is a template; 118 is the form |
| `defineCollection`, `glob()`, `file()` loaders, custom loaders | not found | add · 121 | 121 |
| schema validation of entries with Zod | `libs/validation` validates typed values only | add · 125 | `03-bundled-libs/125` |
| `reference("authors")` | not found | add · 121 | 121 |
| `getCollection`, `getEntry`, filters, `render(entry)` | not found | add · 121 | 121 |
| live collections | a function that fetches at request time | n/a | that is an ordinary `@Task` function; a second API adds nothing |
| JSON Schema files for data entries | not found | add · 125 | `jsonSchemaOf<T>` |
| `<Image />` with `srcset`, an optimising endpoint | `Image(p, cfg, publicDir)`, `/_onze/image` (`onze-assets/src/image.bp:196`, `image_handler.bp:107`); the route is not registered | wire | `07-onze/51` |
| `<Picture />`, `getImage()`, `image.domains`, remote patterns | not found; remote sources answer 501 | wire | `07-onze/51` (ONZ-51-DoD) |
| SVG as a component | not found | gap | the same row (lg2-o); nearest: an inline `<svg>` in a component |
| images in Markdown, `image()` in a collection schema | not found | add · 121 | 121 |
| Sharp, the asset cache | an encoder port; single-flight is an open box (ONZ-51-5) | wire | `07-onze/51` |

## 16 · Endpoints, 17 · Middleware, 18 · Data fetching, 21 · On-demand rendering

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `GET` / `POST` / … / `ALL` exported from a file | one decorated function per verb in `route.bp` | have | — |
| `HEAD` answered from `GET` | the dispatcher falls back to the `GET` handler (`route_handler.bp:16`, `:495`) | have | — |
| static file endpoints (`data.json.ts` built into a file) | `staticExport` writes pages only | add · 117 | 117 — contradicts decision 222 (a route handler is never prerendered); pending the maintainer |
| `params`, `request`, `redirect` in an endpoint | `Request`, `HandlerResponse` (`route_handler.bp:45`) | have | — |
| `src/middleware.ts`, `onRequest(context, next)` | `middleware.bp`, `#[middleware]` + `#[matcher]`, `Next.pass / redirect / rewrite` (`rakun-web/src/middleware.bp:41-83`) | have | — |
| `context.locals` | **not found** | add · 123 | 123 |
| `sequence(a, b, c)` | an ordered filter chain with bands (`rakun-web/src/filter.bp:162-173`, `:319`) | have · add · 123 | 123 (the one-line spelling) |
| rewriting the response body after `next()` | not found: `Response` is a frozen record | add · 123 | 123 |
| `context.rewrite()`, `next(request)` | `Next.rewrite` | have | — |
| middleware runs for 404 and 500 | not measured | add · 123 | 123 step 0 |
| `fetch()` in the component script, top-level `await` | `io.http.fetch(url)` — GET only (`libs/std/AGENTS.md`); `await` in a `@Component` body | have · wire | `02-std-and-packaging` (method, headers, body) |
| adapters (Node, Netlify, Vercel, Cloudflare) | one runtime: the BEAM, packaged by `onze-release` | n/a | rakun is erlang-only by manifest |
| `output: "server"` | every page is `Auto`: the mode is derived from what the render reads | n/a | decision 202 — no `output` key |
| HTML streaming | `App.renderStream`, boundaries in completion order (`streaming.bp:935-957`) | have | — |
| `Astro.cookies` | `cookies()` reads (`jhonstart/src/server.bp:270`); writes belong to a handler, an action or middleware (`rakun/src/request_context.bp:586`, `:752`) | have | — |
| `Astro.request`, `.url`, `.method`, `.headers` | `request()` → `RequestData(method, path, params, query, headers, cookies)` (`server.bp:106`, `:252`); onze fills `query` and `headers` with `[]` | wire | `07-onze/49` (ONZ-49-4.3) |
| `Astro.response.status`, `.headers` | not found from a page | add · 122 | 122 |
| returning a `Response` from a page | the navigation signals only | add · 122 | 122 |
| sessions | `Session`, three stores (`rakun-session`) | have | — |
| i18n routing | `registerLocales`, `negotiate`, the locale redirect (`rakun-app/src/i18n.bp`) | have | `03-bundled-libs/105` |

## 20 · View transitions

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `<ClientRouter />` — client-side navigation | click interception and `pushState` (`jhonstart-link/src/link_runtime.mjs:41-71`); the transition driver `reconcile()` is not written (`reconcile.bp:40`) | wire | `05-jhonstart/27` |
| `transition:name`, `transition:animate`, built-in `fade` / `slide` / `none` / `initial`, custom animations | not found — no `startViewTransition` in the tree | add · 126 | 126 |
| `transition:persist`, `transition:persist-props` | not found | add · 126 | 126 |
| `data-astro-reload`, `data-astro-history` | not found | add · 126 | 126 |
| `navigate(href)` | not found as a public function | add · 126 | 126 |
| forms through the router | `formMount` (`jhonstart-forms/src/form.bp:173`) | have | — |
| lifecycle events (`before-preparation` … `page-load`) | not found | add · 126 | 126 |
| route announcer, `prefers-reduced-motion` | not found | add · 126 | 126 |
| prefetch | `prefetchMode`, `IntersectionObserver` + `x-jh-prefetch` (`link.bp:163`, `link_runtime.mjs`) | have | — |

## 22 · Server islands

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `server:defer` | not found | add · 120 | 120 |
| `slot="fallback"` | `Boundary.fallback` is the same idea inside one response | add · 120 | 120 |
| props serialised, encrypted, in the query; `POST` past 2 048 bytes | not found | add · 120 | 120 (decision 224: sealed by default; `08-e2` open) |
| `Cache-Control` on the island response | not found | add · 120 | 120 |
| the page URL through `Referer` | — | add · 120 | 120 |
| `astro create-key`, `ASTRO_KEY` | not found | add · 124 | 124 |

## 23 · Client-side scripts

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `<script>` in a component: bundled, deduplicated, `type="module"` | `script` builder, verbatim; `<Script>` with four strategies in onze (`onze-bundler/src/script.bp:18-21`) | add · 124 | 124 |
| `is:inline` | the verbatim behaviour above | have | — |
| scripts from `src/` and from `public/` | `<Script>` | have | — |
| passing data through `data-*` | any attribute | have | — |
| custom elements | plain HTML | have | — |
| TypeScript in a script | a `#[client]` function is botopink compiled to commonJS | n/a | the typed client code is an island |

## 24 · TypeScript

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| typed props, `ComponentProps<typeof X>` | a function's parameters | have | — |
| `HTMLAttributes<"a">`, polymorphic components | attributes are `Array<#(string, string)>` | n/a | no per-tag attribute typing exists, and the template checks names against a table instead (118) |
| `InferGetStaticPropsType` | `<name>Params(route)` emitted by `#[page]` (`routes.bp:233-262`) | have | — |
| `App.Locals`, `env.d.ts` | — | add · 123 | 123 (a typed `locals` record) |
| `astro check` | `botopink check` | have | — |

## 25 · Actions

| Astro | The stack today | Box | Owner |
|---|---|---|---|
| `defineAction({ handler })`, called from the client | `#[serverAction]` on `fn(form: FormData) -> @Task<ActionResult>`, HMAC ids (`rakun-app/src/actions.bp:170`, `:237`); the dispatcher is not installed by onze | wire | `07-onze/49` (ONZ-49-4.5) |
| `input:` — a schema that validates and types the input | `form.field("title")` read by hand, checks written inline (`07-onze/53/examples/server-action-example.bp`) | add · 127 | 127, on 125 |
| `accept: "form"` and the per-input rules | `bodyForm` (`route_handler.bp:168`) | add · 127 | 127 — `bind<T>` |
| `{ data, error }`, `.orThrow()` | `ActionResult`, `ActionEnvelope` (`libs/actions`) | have · add · 127 | 127 (a typed `data`) |
| `ActionError` with a `code` | `ActionResult.invalid(field, message)` | add · 127 | 127 |
| `isInputError(error)`, `error.fields` | `ActionState.fields`, `fieldError(name)` (`libs/actions`) | have | — |
| `<form action={actions.x}>` without JavaScript | `formAction`, `actionForm` (`jhonstart-forms/src/form.bp:119-137`) | have | — |
| `Astro.getActionResult()` | `actionState` (`form.bp:182`) | have | — |
| `Astro.callAction()` | an action is a function; it is called | have | — |
| `getActionContext()` in middleware | not found | add · 123 | 123 |
| actions nested in objects (`actions.user.getUser`) | the module path | have | — |

---

## Count

161 rows. By the first word of the Box column (a row that is partly there counts for what it
already is):

| Box | Rows |
|---|---|
| have | 59 |
| wire (another track's front owns the connection) | 14 |
| add (this track) | 70 |
| gap | 3 |
| n/a | 15 |

More than a third of the reference is already on disk, and one row in eleven is on disk and not
connected. The additions are not spread evenly — counting each front a row names: the template
language (118) 14, islands (120) 13, content (121) 11, routing (117) 7, middleware (123) and view
transitions (126) 6 each, the CLI (124) 5, styling (119) and actions (127) 4 each, the request
surface (122) 4, the file kind (116) 2, and 2 land in `03-bundled-libs/125`.
