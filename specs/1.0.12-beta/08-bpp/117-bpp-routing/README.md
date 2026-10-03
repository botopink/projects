# Front 117 — bpp routing: what Astro's router has that the route tree does not

**Priority:** high — a `.bpp` or `.md` page that the scan does not see is not a page. ·
**State:** not started
**Depends on:** `03-bundled-libs/102-routing-conventions` (step 3: the eight app-file kinds and
`classify` move into `routing.conventions`, which is not on feat yet; this front extends them
there, once) · `04-rakun/22` (rakun-app's router and static generation) · `07-onze/50` (ONZ-50-7:
`prerender/` in the build output) and `07-onze/49` (`paginate.bp` is a new file in its member) ·
121 steps 1–2 (`page.md`) · open: `bpp-g` (a `page.bpp`'s `route` and `params`, step 1). Written
against decisions 203 (one convention), 221 (a `page.bpp`'s decorator), 186 and 202 (`#[page]`
decides the stage at comptime), 222 (a route handler is never prerendered).
**Owns:** `botopink-lang/libs/routing/src/{segment.bp, conventions.bp}` — the lines named in the
steps · `rakun/modules/rakun-app/src/static_gen.bp` — `StaticParams`' data column and the endpoint
export · new `onze/modules/onze/src/paginate.bp` · `onze/modules/onze-cli/src/scan.bp` — the
extension and the exported names · their tests
**Does not touch:** `rakun-app/src/file_router.bp` beyond what `routing.conventions` gives it;
`onze-server`; the compiler.

Reference: `astro-docs/07-astro-pages.md`, `08-routing.md`, `16-endpoints.md`.

## Goal

The `app/` tree (decision 203: one convention, a directory per route) gains what Astro's router has
and it lacks:

| Astro | Today |
|---|---|
| a page file that is not `.bp` (`.astro`, `.md`, `.html`) | `conventionFiles()` lists eight `.bp` names (`rakun-app/src/file_router.bp`); onze's scan requires a decorator per kind (`onze-cli/src/scan.bp`) |
| `getStaticPaths` returning `props` beside `params` | a `StaticParams` row binds parameters only (`static_gen.bp`, `registerStaticParams`) |
| `paginate(items, { pageSize })` and the `page` prop | not found |
| a page partial (`export const partial = true`) | not found: every page is composed with its layout chain and the document shell (`jhonstart/src/render.bp`) |
| an endpoint built into a static file (`rss.xml.ts` → `/rss.xml`) | `staticExport` writes `<path>/index.html` and `payload.json` for pages (`static_gen.bp`) — and decision 222 rules that a route handler is never prerendered (step 4) |
| two parameters in one segment (`[lang]-[version]`) | `parseSegment` reads `[lang]-[version]` as one parameter named `lang]-[version` (`libs/routing/src/segment.bp`) |
| eight documented priority rules | `matchPath` (`libs/routing/src/match.bp`) — the order is whatever the code does; no test states it as a rule |

## Mechanism

What exists: the segment grammar `[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `_private`,
static (`segment.bp`, `parseSegment`); a `.bp` page carries its directory in its decorator —
`#[page("blog/[slug]")]` (`onze/examples/blog/src/app/blog/[slug]/page.bp`) — because `@Decl` has
no source location (`language-gaps.md` lg2-q), and `#[page]` emits `<fn>Params(route)`
(`jhonstart/src/routes.bp`, `page`) — decision 236 moves that to `paramsOf(…meta.page.seg, route)`
(`01-compiler/130`); static generation is
`registerStaticParams(seg, fn() -> @Task<StaticParams[]>)`, `decideKind`, `prerenderAll(strict)`,
`prerenderPath`, `serveStatic` (stale-while-revalidate), `staticExport(outDir)` (`static_gen.bp`);
`SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` (`segment_config.bp`); `page` and
`route` in one segment are refused (`file_router.bp`). onze's scan records each decorator's
argument and nothing compares it with the file's directory (read, not run — step 0 runs it).

**A page file has a kind and a form.** The kind is the stem (`page`, `layout`, …); the form is the
extension:

| Form | Is | Declares its route by |
|---|---|---|
| `page.bp` | a module with a decorated function | `#[page("<dir>")]`, checked against the directory by the scan |
| `page.bpp` | a `.bp` module in another spelling (front 116, decision 198) | its directory below `app/`; its `#[page]` comes from the file name through the `bpp` package's `bppKinds`, or from the header (decision 221); its `route` parameter and `params` are question `bpp-g` |
| `page.md` | Markdown with frontmatter | the scan, which stages a page module calling 121's renderer |
| `page.html` | a complete document | the scan, which stages a page that answers the file's bytes |

Two forms of one kind in one directory are refused, naming both files.

**A page exports two optional names**, read by the scan and registered in the staged routes
module — the generated counterpart of the `val _ = registerStaticParams(…)` lines a `.bp` page
writes by hand today:

| Export | Meaning | Registers |
|---|---|---|
| `pub fn staticPaths() -> @Task<Array<StaticPath>>` | the values the dynamic segments take, each with optional data | `registerStaticParams` |
| `pub val partial = true` | rendered without layouts and without the document shell | a flag on the route record |

There is no `prerender` export (decision 202): `#[page]` reads at comptime whether the page
reaches a `#[serverOnly]` hook and prerenders it when it reaches none; a page that reaches one is
rendered per request, and nothing forces either.

`StaticPath(params: Array<#(string, string)>, data: Json)`. The data is what Astro calls `props`:
it is carried beside the prerendered page and read back with a schema —
`pageData(route, schemaOfPost())` — so the page that was told which post to render does not load
it a second time. It is `Json` and decoded, not a typed argument, because the route record is one
shape for every page.

**Pagination is a function over `staticPaths`.** `paginate(items, size, schema)` answers one
`StaticPath` per page, binding the segment `page` to `1 … n` and carrying the slice; the page
reads `pageOf(route, schema)` and gets the reference's record, field for field:

```bp
pub type Page<T>(
    data: Array<T>, start: i32, end: i32, total: i32,
    currentPage: i32, size: i32, lastPage: i32,
    url: PageUrls,
)
pub type PageUrls(current: string, prev: ?string, next: ?string, first: ?string, last: ?string)
```

**An endpoint with an extension in its directory.** `app/rss.xml/route.bp` answers `/rss.xml`,
with the content type of its extension. The text this front was written with has `staticExport`
write a prerendered `GET` handler's body to `rss.xml`, not `rss.xml/index.html`; decision 222
rules that a route handler is always server, at request time, and never prerendered, so that
export **contradicts decision 222** and is pending the maintainer (step 4).

## Open

### Step 0 — Measure

- [ ] a `page.bp` whose decorator names another directory: what `onze build` does today. If it
      builds, the comparison is this step's first change and `07-onze/50` is told
- [ ] the eight priority rules of the reference, each as a `match_test.bp` case over a two-route
      table — the ones that fail are the list of step 5

### Step 1 — `.bpp`, `.md` and `.html` as app files (a `page.bpp`'s parameter waits on `bpp-g`)

- [ ] `routing.conventions.classify` answers kind and form for the four extensions; rakun-app and
      onze-cli read it (they do after 102)
- [ ] two forms of one kind in a directory fail the scan with both paths
- [ ] `page.html` is served byte for byte, with the content type of its extension

### Step 2 — The exports

Reworded against decision 202 (no `prerender` export; `#[page]` decides the stage at comptime).

- [ ] `examples/static-paths-example.bp` passes; the scan finds `staticPaths` and `partial` in a
      `.bp` and in a `.bpp` page, and no `prerender` is read
- [ ] a page that calls `cookies()` is not prerendered — `#[page]`'s comptime decision renders it
      per request, and `dynamicReason()` names the read
- [ ] a dynamic route that `#[page]` prerenders and that declares no `staticPaths` fails the build
      (`prerenderAll(strict)`)

### Step 3 — `StaticPath.data`, `paginate`, `Page<T>`

- [ ] `examples/pagination-example.bp` passes: four items, size two → `/astronauts/1`,
      `/astronauts/2`; `url.prev` is `null` on the first and `url.next` on the last
- [ ] the data survives `staticExport` and a restart: the exported page renders without calling
      the loader

### Step 4 — Partials and static endpoints

- [ ] a partial's response is the page's markup alone — no `<!DOCTYPE`, no `data-jh-root`, no
      payload script
- [ ] `app/rss.xml/route.bp` exports to `<outDir>/rss.xml` — **contradicts decision 222** (a
      route handler is never prerendered); kept as written, pending the maintainer
- [ ] `examples/partial-and-endpoint-example.bp` passes

### Step 5 — Two parameters in a segment, and the priority rules

- [ ] `[lang]-[version]` parses to two parameters with a literal between them; `/en-v1/info`
      binds both; a segment whose two parameters touch (`[a][b]`) is refused
- [ ] the eight rules green in `match_test.bp`. Rule 6 ("an endpoint over a page") stays a refusal
      at the scan and is asserted as one

## Decisions

- `bpp-g` — how a `page.bpp` gets its `route: PageContext` and its `params`. Step 1.
- Step 4's static endpoint against decision 222 — no id; the maintainer's to settle.

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `libs/routing`, and on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `onze/examples/blog` builds unchanged

## Blast radius

- **`libs/routing` is embedded in the compiler** — the segment change reaches every consumer
  through a rebuilt compiler, and the browser's matcher with it. `match_test.bp` runs on both
  targets for that reason.
- **The route record gains a column** (the partial flag, the data). The route-table wire
  (`kind|pattern|slot|verb`, `libs/routing/src/table.bp`) is contract § 1 of `contracts.md`; step 2
  amends the contract in the same commit and both readers with it.
- **No existing page changes.** A `.bp` page keeps its decorator and its hand-written
  `registerStaticParams`; the exports are a second, shorter spelling of the same registration.

## Notes

- **Not added.** A `pages/` tree (decision 203). `src/fetch.ts` / Hono: the server is rakun's
  pipeline, already composed in botopink. Redirects in config: the table exists in
  `routing/url_rules`; the config key is 124's.
- **`Astro.params`** is what `#[page]` gives a `.bp` page from its segment (`<fn>Params(route)`,
  `paramsOf` under decision 236); in a `.bpp` page it is question `bpp-g`. **`Astro.props`** of a
  paginated page is `pageOf(route, schema)`.
- **Reserved prefixes.** `/_onze/` is onze's (`/_onze/image` today, `/_onze/island/` after 120). A
  directory named `_onze` under `app/` is skipped by the `_private` rule, so no page can claim it.
