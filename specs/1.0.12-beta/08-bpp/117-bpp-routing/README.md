# Front 117 — bpp routing: what Astro's router has that the route tree does not

**Priority:** high — a `.bpp` or `.md` page that the scan does not see is not a page.
**Depends on:** `03-bundled-libs/102-routing-conventions` (the eight app-file kinds and `classify`
move into `routing.conventions`; this front extends them there, once) · `04-rakun/22` (rakun-app's
router and static generation) · `07-onze/50` (ONZ-50-7: `prerender/` in the build output) and
`07-onze/49` (`paginate.bp` is a new file in its member) · decisions 186 and 202 (the stage a
page renders in is deduced at comptime by `#[page]`; no page declares it) · the open question
[`08-b`](../README.md#08-b--one-routing-convention-or-two) (step 1).
**Owns:** `botopink-lang/libs/routing/src/{segment.bp, conventions.bp}` — the lines named in the
steps · `rakun/modules/rakun-app/src/static_gen.bp` — `StaticParams`' data column and the endpoint
export · new `onze/modules/onze/src/paginate.bp` · `onze/modules/onze-cli/src/scan.bp` — the
extension and the three exported names · their tests
**Does not touch:** `rakun-app/src/file_router.bp` beyond what `routing.conventions` gives it;
`onze-server`; the compiler.

Reference: `astro-docs/07-astro-pages.md`, `08-routing.md`, `16-endpoints.md`.

---

## Problem

File routing is the part of Astro the stack already has, in more detail than Astro: eight file
kinds, route groups, parallel slots, optional catch-alls, a matcher shared by server and browser
(`libs/routing`), static generation with revalidation (`rakun-app/src/static_gen.bp`). The first
cut of this front specified it again from zero, inside the compiler
(`modules/compiler-core/src/bpp/routing.zig`), as a second `src/pages/` convention beside the one
onze scans.

What the reference has and the tree does not is seven things:

| Astro | Today |
|---|---|
| a page file that is not `.bp` (`.astro`, `.md`, `.html`) | `conventionFiles()` lists eight `.bp` names (`rakun-app/src/file_router.bp:193-202`); onze's scan requires a decorator per kind (`onze-cli/src/scan.bp:24`, `:66-96`) |
| `getStaticPaths` returning `props` beside `params` | a `StaticParams` row binds parameters only (`static_gen.bp:106`, `:196`) |
| `paginate(items, { pageSize })` and the `page` prop | not found |
| a page partial (`export const partial = true`) | not found: every page is composed with its layout chain and the document shell (`jhonstart/src/render.bp:341`, `:551-590`) |
| an endpoint built into a static file (`rss.xml.ts` → `/rss.xml`) | `staticExport` writes `<path>/index.html` and `payload.json` for pages (`static_gen.bp:620`) |
| two parameters in one segment (`[lang]-[version]`) | `parseSegment` reads `[lang]-[version]` as one parameter named `lang]-[version` (`libs/routing/src/segment.bp:36-74`) |
| eight documented priority rules | `matchPath` (`libs/routing/src/match.bp:178`) — the order is whatever the code does; no test states it as a rule |

## Current state

Measured 2026-10-01:

- Segment grammar: `[x]`, `[...x]`, `[[...x]]`, `(group)`, `@slot`, `_private`, static
  (`segment.bp:36-74`).
- Declaration: the decorator carries the directory — `#[page("blog/[slug]")]`
  (`onze/examples/blog/src/app/blog/[slug]/page.bp:9`) — because `@Decl` has no source location
  (`language-gaps.md` lg2-q). `#[page]` emits `<fn>Params(route)` (`jhonstart/src/routes.bp:233-262`).
- Static generation: `registerStaticParams(seg, fn() -> @Task<StaticParams[]>)`, `decideKind`,
  `prerenderAll(strict)`, `prerenderPath`, `serveStatic` (stale-while-revalidate),
  `staticExport(outDir)` (`static_gen.bp:63-620`); `SegmentConfig(dynamic, dynamicParams,
  revalidate, fetchCache)` (`segment_config.bp:38`).
- `page` and `route` in one segment are refused (`file_router.bp:382`).
- Not measured, read only: onze's scan records each decorator's argument (`scan.bp:36-56`) and
  nothing compares it with the file's directory. Step 0 runs it.

## Mechanism

One convention (decision `08-b`): the `app/` tree, a directory per route. This front widens what
a file in it may be and what a page may export.

**A page file has a kind and a form.** The kind is the stem (`page`, `layout`, …); the form is the
extension:

| Form | Is | Declares its route by |
|---|---|---|
| `page.bp` | a module with a decorated function | `#[page("<dir>")]`, checked against the directory by the scan |
| `page.bpp` | a `.bp` module in another spelling (front 116, decision 198) | its directory below `app/` — how the unfold gives it `#[page]` is not stated (116 § Notes) |
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
reads `pageOf(route, schema)` and gets

```bp
pub type Page<T>(
    data: Array<T>, start: i32, end: i32, total: i32,
    currentPage: i32, size: i32, lastPage: i32,
    url: PageUrls,
)
pub type PageUrls(current: string, prev: ?string, next: ?string, first: ?string, last: ?string)
```

— the reference's record, field for field.

**An endpoint with an extension in its directory is a file.** `app/rss.xml/route.bp` answers
`/rss.xml`; when its segment is prerendered, `staticExport` writes the `GET` handler's body to
`rss.xml`, not to `rss.xml/index.html`.

## Steps

### Step 0 — Measure

- [ ] a `page.bp` whose decorator names another directory: what `onze build` does today. If it
      builds, the comparison is this step's first change and `07-onze/50` is told
- [ ] the eight priority rules of the reference, each as a `match_test.bp` case over a two-route
      table — the ones that fail are the list of step 5

### Step 1 — `.bpp`, `.md` and `.html` as app files

- [ ] `routing.conventions.classify` answers kind and form for the four extensions; rakun-app and
      onze-cli read it (they do after 102)
- [ ] two forms of one kind in a directory fail the scan with both paths
- [ ] `page.html` is served byte for byte, with the content type of its extension

### Step 2 — The exports

Written against decision 202: the step reads `staticPaths` and `partial`; there is no
`prerender` export to read. The boxes below predate the decision — the scan of `prerender` in the
first and the two `prerender = true` boxes describe a declaration that does not exist; what they
assert (a page that reads the request is not prerendered, a dynamic route with no `staticPaths`
is refused by `prerenderAll(strict)`) is reworded by the front against `#[page]`'s comptime
decision when it opens.

- [ ] `examples/static-paths-example.bp` passes; the scan finds `staticPaths`, `prerender` and
      `partial` in a `.bp` and in a `.bpp` page
- [ ] `prerender = true` on a page that calls `cookies()` fails the build, naming the page and the
      read — `dynamicReason()` is what it prints
- [ ] a dynamic route with no `staticPaths` and `prerender = true` fails the build
      (`prerenderAll(strict)`)

### Step 3 — `StaticPath.data`, `paginate`, `Page<T>`

- [ ] `examples/pagination-example.bp` passes: four items, size two → `/astronauts/1`,
      `/astronauts/2`; `url.prev` is `null` on the first and `url.next` on the last
- [ ] the data survives `staticExport` and a restart: the exported page renders without calling
      the loader

### Step 4 — Partials and static endpoints

Decision 202 removes the `prerender` declaration; how a route handler — which `#[page]` does not
decorate — becomes a prerendered static file is not stated by it, and the second box below waits
on that answer.

- [ ] a partial's response is the page's markup alone — no `<!DOCTYPE`, no `data-jh-root`, no
      payload script
- [ ] `app/rss.xml/route.bp` exports to `<outDir>/rss.xml`
- [ ] `examples/partial-and-endpoint-example.bp` passes

### Step 5 — Two parameters in a segment, and the priority rules

- [ ] `[lang]-[version]` parses to two parameters with a literal between them; `/en-v1/info`
      binds both; a segment whose two parameters touch (`[a][b]`) is refused
- [ ] the eight rules green in `match_test.bp`. Rule 6 ("an endpoint over a page") stays a refusal
      at the scan and is asserted as one

## Gate

- [ ] `botopink test` green on both targets in `libs/routing`, and on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `onze/examples/blog` builds unchanged
- [ ] `scripts/gate.sh --cold` green
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/117-bpp-routing`; landing is the maintainer's step

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

- **Not added.** A `pages/` tree (decision `08-b`). `src/fetch.ts` / Hono: the server is rakun's
  pipeline, already composed in botopink. Redirects in config: the table exists in
  `routing/url_rules`; the config key is 124's.
- **`Astro.params`** is the accessor `#[page]` emits, `<function>Params(route)` — `params` in a
  `.bpp` page, where jhonstart's `bpp` function binds it; **`Astro.props`** of a paginated page is
  `pageOf(route, schema)`.
- **Reserved prefixes.** `/_onze/` is onze's (`/_onze/image` today, `/_onze/island/` after 120). A
  directory named `_onze` under `app/` is skipped by the `_private` rule, so no page can claim it.
