# Front 117 — bpp routing: what Astro's router has that the route tree does not

**Priority:** high — a `.bpp` or `.md` page the scan does not see is not a page. · **State:** not started
**Depends on:** `03-bundled-libs/102-routing-conventions` (step 3: the eight app-file kinds and
`classify` move into `routing.conventions`, not on feat yet; extended there, once) · `04-rakun/22`
(rakun-app router, static generation) · `07-onze/50` (ONZ-50-7: `prerender/` in the build output),
`07-onze/49` (`paginate.bp` new in its member) · 121 steps 1–2 (`page.md`) · `03-bundled-libs/125` step 12 (step 8: the `#[validated]` type, 306).
Written against decisions 203, 221, 186 and 202, 222.
**Owns:** `botopink-lang/libs/routing/src/{segment.bp, conventions.bp}` (lines named in the steps)
· `rakun/modules/rakun-app/src/static_gen.bp` (`StaticParams`' data column, endpoint export) · new
`onze/modules/onze/src/paginate.bp` · `onze/modules/onze-cli/src/scan.bp` (extension, exported
names) · their tests
**Does not touch:** `rakun-app/src/file_router.bp` beyond what `routing.conventions` gives it; `onze-server`; the compiler.

Reference: `astro-docs/07-astro-pages.md`, `08-routing.md`, `16-endpoints.md`.

## Goal

The `app/` tree (decision 203) gains:

| Astro | Today |
|---|---|
| a page file that is not `.bp` (`.astro`, `.md`, `.html`) | `conventionFiles()` lists eight `.bp` names (`rakun-app/src/file_router.bp`); scan requires a decorator per kind (`onze-cli/src/scan.bp`) |
| `getStaticPaths` returning `props` beside `params` | a `StaticParams` row binds parameters only (`static_gen.bp`, `registerStaticParams`) |
| `paginate(items, { pageSize })` and the `page` prop | not found |
| a page partial (`export const partial = true`) | not found: every page composed with layout chain and document shell (`jhonstart/src/render.bp`) |
| an endpoint built into a static file (`rss.xml.ts` → `/rss.xml`) | not added (decisions 222, 273): a route handler is served per request; a static feed is a page-kind file prerendered by 202 |
| two parameters in one segment (`[lang]-[version]`) | `parseSegment` reads one parameter named `lang]-[version` (`libs/routing/src/segment.bp`) |
| eight documented priority rules | `matchPath` (`libs/routing/src/match.bp`) — order is whatever the code does; no test |

## Mechanism

Exists: segment grammar `[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `_private`, static
(`segment.bp`, `parseSegment`); a `.bp` page names its directory in its decorator
(`#[page("blog/[slug]")]`, `onze/examples/blog/src/app/blog/[slug]/page.bp`) since `@Decl` has no
source location (`language-gaps.md` lg2-q); `#[page]` emits `<fn>Params(route)` (`jhonstart/src/routes.bp`, `page`),
moved by decision 236 to `paramsOf(…seg, route)` (gone by 293) (`01-compiler/130`); static generation:
`registerStaticParams(seg, fn() -> @Task<StaticParams[]>)`, `decideKind`, `prerenderAll(strict)`,
`prerenderPath`, `serveStatic` (stale-while-revalidate), `staticExport(outDir)` (`static_gen.bp`);
no segment config — `revalidate` and `dynamicParams` are `#[page]` arguments (290); `page` +
`route` in one segment refused (`file_router.bp`). onze's scan records each decorator argument,
never compares it with the directory (read, not run — step 0).

**Kind = stem** (`page`, `layout`, …), **form = extension**:

| Form | Is | Declares its route by |
|---|---|---|
| `page.bp` | a module with a decorated function | `#[page("<dir>")]`, checked against the directory by the scan |
| `page.bpp` | a `.bp` module in another spelling (front 116, decision 198) | its directory below `app/`; a page by its file name in the route table `rakun-app` generates (285; `04-rakun/22`), or `#[page]` written in the header (221 (1)); no parameter — `use params<P>()`, `use pageData<D>()` (293) |
| `page.md` | Markdown with frontmatter | the scan, which stages a page module calling 121's renderer |
| `page.html` | a complete document | the scan, which stages a page that answers the file's bytes |

Two forms of one kind in one directory: refused, naming both.

**Two optional exports**, read by the scan, registered in the staged routes module (generated form
of today's hand-written `val _ = registerStaticParams(…)`) — until step 6: a role is a decorator,
never an export name (282), so both become `#[page(…, paths: …, partial: true)]`:

| Export | Meaning | Registers |
|---|---|---|
| `pub fn staticPaths() -> @Task<Array<StaticPath>>` | values of the dynamic segments, each with optional data | `registerStaticParams` |
| `pub val partial = true` | rendered without layouts and document shell | a flag on the route record |

No `prerender` export (202): `#[page]` prerenders unless the page reaches a `#[serverOnly]` hook.

`StaticPath(params: Array<#(string, string)>, data: Json)`. `data` = Astro's `props`, carried
beside the prerendered page, read back with a schema (`pageData(route, schemaOfPost())`) so the page
does not reload it. `Json`, not typed: the route record is one shape for every page. Steps 7–8
replace this: `paths: fn() -> @Task<#(P, D)[]>`, read with `use pageData<D>()` (293), `D` a
`#[validated]` type, never a `Schema<T>` value (306).

**Pagination over `staticPaths`.** `paginate(items, size, T)` — `T` the `#[validated]` item type
(306; today a schema value) — answers one `StaticPath` per page, segment `page` = `1 … n`, carrying
the slice; the page reads it with `use pageData<D>()` (293; today `pageOf(route, schema)`):

```bp
pub type Page<T>(
    data: Array<T>, start: i32, end: i32, total: i32,
    currentPage: i32, size: i32, lastPage: i32,
    url: PageUrls,
)
pub type PageUrls(current: string, prev: ?string, next: ?string, first: ?string, last: ?string)
```

**Endpoint with an extension in its directory.** `app/rss.xml/route.bp` answers `/rss.xml` with
its extension's content type, **per request** — never exported by the build (decisions 222, 273). A
feed that must be a static file is a page-kind file, prerendered by 202.

## Open

### Step 0 — Measure

- [ ] a `page.bp` whose decorator names another directory: what `onze build` does. If it builds,
      the comparison is this step's first change and `07-onze/50` is told
- [ ] the reference's eight priority rules, each a `match_test.bp` case over a two-route table —
      failures are step 5's list

### Step 1 — `.bpp`, `.md` and `.html` as app files (a page takes no parameter: 293)

- [ ] `routing.conventions.classify` answers kind and form for the four extensions; rakun-app and
      onze-cli read it (after 102)
- [ ] two forms of one kind in a directory fail the scan with both paths
- [ ] `page.html` served byte for byte, with its extension's content type

### Step 2 — The exports

Per decision 202 (no `prerender` export).

- [ ] `examples/static-paths-example.bp` passes; scan finds `staticPaths` and `partial` in a `.bp`
      and a `.bpp` page; no `prerender` read
- [ ] a page reading a cookie (`use cookieValue(sessionCookie)`, 294) is not prerendered (rendered per request): its kind is `D` and its
      `why` names the read (`@typeInfo(Page).meta(PageMeta)`, recorded by `#[page]` from `Decl.hooks`, 277)
- [ ] a dynamic route `#[page]` prerenders with no `staticPaths` fails the build (`prerenderAll(strict)`)

### Step 3 — `StaticPath.data`, `paginate`, `Page<T>`

- [ ] `examples/pagination-example.bp` passes: four items, size two → `/astronauts/1`,
      `/astronauts/2`; `url.prev` `null` on the first, `url.next` on the last
- [ ] data survives `staticExport` and a restart: exported page renders without calling the loader

### Step 4 — Partials and endpoints with an extension

- [ ] partial response = page markup alone — no `<!DOCTYPE`, no `data-jh-root`, no payload script
- [ ] `app/rss.xml/route.bp` is served per request with its extension's content type; `onze build`
      writes no `<outDir>/rss.xml` (decisions 222, 273)
- [ ] `examples/partial-and-endpoint-example.bp` passes

### Step 5 — Two parameters in a segment, and the priority rules

- [ ] `[lang]-[version]` parses to two parameters with a literal between; `/en-v1/info` binds
      both; touching parameters (`[a][b]`) refused
- [ ] eight rules green in `match_test.bp`; rule 6 ("an endpoint over a page") stays a scan refusal, asserted as one

### Step 6 — a role in the decorator, not in an export's name (decision 282)

- [ ] `pub fn staticPaths()` and `pub val partial = true` are no longer read: `#[page("dogs/[dog]",
      paths: dogPaths, partial: true)]`, `paths` typed against the page's `PageContext<P, D>`
      (`fn() -> @Task<#(P, D)[]>`, 280 example 4); the scan stops looking for export names
- [ ] a `staticPaths` left in a page module is refused, naming `#[page(…, paths: …)]`

### Step 7 — route parameters and page data are hooks (decision 293)

- [ ] `StaticPath.data: Json` and `pageData(route, schemaOf…)` go: `paths: fn() -> @Task<#(P, D)[]>`
      (282), the page reads `use params<P>()` / `use pageData<D>()`
- [ ] `static-paths-example.bp`, `pagination-example.bp`, `partial-and-endpoint-example.bp` and the
      `.bpp` tree rewritten to the hooks; a `page.bpp` header with `type Props(route: …)` no longer needed

### Step 8 — page data typed by the type, not a schema value (decision 306)

- [ ] `paginate(…, schemaOfAstronaut())`, `pageOf(route, schemaOfAstronaut())` take the `#[validated]`
      type (`paginate(astronauts(), 2, "/astronauts", Astronaut)`; with 293, `use pageData<Astronaut>()`);
      `pagination-example.bp`, `static-paths-example.bp` and the two `page.bpp` rewritten

## Decisions


**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `libs/routing`, on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `onze/examples/blog` builds unchanged

## Blast radius

- **`libs/routing` is embedded in the compiler** — the segment change reaches every consumer and
  the browser's matcher; hence `match_test.bp` on both targets.
- **Route record gains a column** (partial flag, data). The route-table wire
  (`kind|pattern|slot|verb`, `libs/routing/src/table.bp`) is `contracts.md` § 1; step 2 amends it
  and both readers in the same commit.
- **No existing page changes**: a `.bp` page keeps decorator and hand-written `registerStaticParams`; `#[page(…, paths: …)]` is a shorter spelling (282).

## Notes

- **Not added.** `pages/` tree (203). `src/fetch.ts` / Hono: rakun's pipeline. Config redirects:
  table in `routing/url_rules`; the key is 124's.
- **`Astro.params`** = `use params<P>()` (293), in `.bp` and `.bpp` alike.
  **`Astro.props`** of a paginated page = `use pageData<D>()` (293; `D` a `#[validated]` type, 306).
- **Reserved prefixes.** `/_onze/` is onze's (`/_onze/image`; `/_onze/island/` after 120); a
  `_onze` directory under `app/` is skipped by `_private`, so no page claims it.
