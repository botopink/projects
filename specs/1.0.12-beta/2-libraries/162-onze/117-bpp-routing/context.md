# Front 117 — bpp routing: what Astro's router has that the route tree does not

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [157-routing](../../157-routing/README.md): s0 box 2 → 157 s1 · s1 box 1 → 157 s1 · s5 → 157 s1 · gate → 157 s1; [162-onze](../README.md): s0 box 1 → 162 s5 · s1 boxes 2, 3 → 162 s5 · s2 → 162 s5 · s3 → 162 s5 · s4 → 162 s5 · s6 → 162 s5 · s7 → 162 s5 · s8 → 162 s5. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — a `.bpp` or `.md` page the scan does not see is not a page. · **State:** not started
**Depends on:** `03-bundled-libs/102-routing-conventions` (step 3: the eight app-file kinds and
`classify` move into `routing.conventions`, not on feat yet; extended there, once) · `04-rakun/22`
(rakun-app router, static generation) · `07-onze/50` (ONZ-50-7: `prerender/` in the build output),
`07-onze/49` (`paginate.bp` new in its member) · 121 steps 1–2 (`page.md`) · `03-bundled-libs/125` step 12 (step 8: the `#[validated]` type, 306).
Written against decisions 203, 221, 186 and 202, 222.
**Owns:** `repository/routing/src/{segment.bp, conventions.bp}` (lines named in the steps)
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
source location (403: by design); `#[page]` emits `<fn>Params(route)` (`jhonstart/src/routes.bp`, `page`),
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

## Decisions

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
