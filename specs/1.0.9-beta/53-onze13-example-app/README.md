# Front 53 — onze13 Example App

**Track:** E onze13
**Priority:** medium — nothing depends on it, and it is the only front that can falsify the other
fifty-two. A milestone whose fronts are individually green and collectively unusable passes every gate
except this one
**Target:** both — full stack. The pages, layouts, actions, handlers and middleware compile to BEAM;
the client island, the `Link` navigation and the form's pending state compile to commonJS; the route
table and the serialized payload cross
**Wave:** 5
**Depends on:** all — and specifically, in critical-path order, 01 → 04 · 22 · 26 → 06 · 23 · 28 · 62
→ 24 · 60 · 63 · 68 → 67 → this
**Owns:** `examples/blog/**`, `examples/blog/test/**`
**Does not touch:** anything. This front is read-only against every other repository and against
`repository/onze13/src/**`. A change it needs in a library is filed against that library's front, not
made here
**Reference:** `NEXTJS-DOCS.md § 3. Estrutura do Projeto`, `§ 5. Layouts e Páginas`,
`§ 6. Rotas Dinâmicas`, `§ 9. Busca de Dados`, `§ 10. Mutação de Dados`, `§ 11. Cache`,
`§ 13. Streaming`, `§ 14. Tratamento de Erros`, `§ 18. Metadata`, `§ 19. Route Handlers`,
`§ 20. Middleware`, plus the *Guia de Referência Rápida* structure ·
<https://nextjs.org/learn/dashboard-app> ·
<https://nextjs.org/docs/app/getting-started/project-structure>
**Replaces:** `1.0.7-beta/22-onze13-example-app`

---

## Problem

Fifty-two fronts each claim a green test on their assigned target. That claim is compatible with the
milestone not working, in three ways that unit tests structurally cannot catch.

**Vocabulary drift.** Front 22 extracts a route param; front 49 wraps it in `Params`; front 28 reads it
in a server component; front 32 reads it again in `generateMetadata`; front 60 produces the list of
values it can take at build time. Five fronts, one value, and each of them has its own test that
passes against its own idea of the shape. Nothing checks that the five ideas are the same idea.

**Ordering.** `emilia(tokens)` registers a class and `flush()` clears the sheet. Front 23 streams. Front
69 inserts into the head. Front 52 wants its preload links before any other style. Each of those is
testable alone and the composition is not, because the composition only exists once something renders
a real document with fonts, styles, a streamed chunk and a late-arriving component in it.

**The halves.** Front 29 marks a client boundary, front 68 bundles it, front 23 serializes a payload
and front 67 reconnects a form to it. Four fronts, two targets, one round trip. The exit gate says no
server front carries an `@External.Node` cell and no client front carries an `#[@external(erlang)]`
cell — a static property. Whether the two halves actually meet is a dynamic one.

This front is a blog that exercises every one of those seams at once, and its README is the
milestone's acceptance script: walk the app file by file, and each file names the fronts it proves.

## Current state

- `repository/onze13/examples/blog/` does not exist; `repository/onze13/` does not exist until
  front 49.
- `repository/jhonstart/examples/` and `repository/rakun/examples/` exist as per-library demos. None
  of them crosses a library boundary; the largest, `repository/rakun/test/server_test.bp`, is a
  three-type DI + routing exercise inside one package.
- There is no test anywhere in the workspace that compiles a page, serves it over HTTP, and asserts
  the bytes. `zig build test-libs` compiles each library and runs its in-file `test` blocks
  (`repository/botopink-lang/AGENTS.md`); it does not start a server.

## What the app is

A blog with an author dashboard. Chosen because it is the smallest shape that needs every mechanism
without needing any of them twice: a list, a detail page with a dynamic segment, a page that can 404,
a form that mutates, a cache that has to be invalidated by that mutation, an authenticated area, and
one piece of genuinely interactive UI.

Posts live on disk as Markdown-ish text files under `content/posts/<slug>.md` — line 1 is the title,
line 2 the publication date, the rest is the body. There is no database, and that is deliberate: front
08 is `rakun-data-sql` and it is not on this front's critical path, so introducing Postgres here would
make the milestone's proof depend on a service being installed. `std`'s `fs` and `path` already exist,
and a file is a mutation target with the same cache-invalidation problem a row has.

## The acceptance script

Each row is a file. The *Proves* column is the claim that fails if that file does not work, and the
fronts named are the ones whose surface the file uses. Run top to bottom; the first row that fails
names the front to look at.

### Top level

| File | Fronts | Proves |
|---|---|---|
| `botopink.json` | 49 · 50 | The alias map resolves: `@/components.post_card` reaches `components/post_card.bp` from four directories down |
| `onze13.json` | 49 · 50 | `appDir`, `outDir`, `port` and `basePath` are read once and every command agrees on them |
| `middleware.bp` | 07 · 62 · 65 | A request to `/dashboard` with no session cookie is redirected before any page renders; a request to `/images/hero.jpg` is not matched at all |
| `content/posts/*.md` | — | Seed data, three posts, committed |

### `app/` — the routing tree

| File | Fronts | Proves |
|---|---|---|
| `app/layout.bp` | 49 · 52 · 27 · 69 · D | The root layout returns the body subtree; fonts, the nav, and emilia's sheet all reach the document head exactly once and in the right order |
| `app/page.bp` | 22 · 51 · 60 | `/` resolves; the hero image is optimized and eager; the route is prerendered at build time and served from the manifest |
| `app/loading.bp` | 30 | A slow render flushes the shell and the fallback before the body |
| `app/error.bp` | 31 · 17 | A thrown error renders the boundary and the digest, and the message never reaches the client |
| `app/not-found.bp` | 31 · 63 | An unmatched URL renders the 404 page with status 404, not status 200 |
| `app/blog/layout.bp` | 23 | Layout nesting: the blog shell wraps every `/blog/*` route and is not re-rendered on client navigation between them |
| `app/blog/page.bp` | 28 · 12 · 30 | A server component loads posts, the load is cached under a tag, and the list streams behind `loading.bp` |
| `app/blog/loading.bp` | 30 | The segment's own fallback, not the root one |
| `app/blog/[slug]/page.bp` | 22 · 28 · 32 · 60 · 63 | The dynamic segment reaches the page as `params.param("slug")`; `generateStaticParams` prerenders all three posts; `generateMetadata` produces the head; a missing slug calls `notFound()` |
| `app/blog/[slug]/loading.bp` | 30 | Per-post fallback |
| `app/blog/[slug]/not-found.bp` | 31 · 63 | The signal from the page lands in *this* boundary, not the root one |
| `app/(marketing)/about/page.bp` | 22 | The route group contributes no URL segment: the page serves at `/about`, not `/(marketing)/about` |
| `app/dashboard/layout.bp` | 62 · 63 | The layout reads the session cookie and redirects — an auth gate above the page, which is the pattern `NEXTJS-DOCS.md § 23` describes |
| `app/dashboard/posts/new/page.bp` | 24 · 67 | A form bound to a server action: pending state, a returned validation message rendered beside the field, and a redirect on success |
| `app/api/posts/route.bp` | 25 · 62 | `GET /api/posts` returns JSON; `POST` reads the body and the `Authorization` header |

### `components/`

| File | Fronts | Proves |
|---|---|---|
| `components/tags.bp` | — | The element constructors the app needs and jhonstart does not have, built on the public `Element` record. See *Findings* — this file exists because `element.bp` is frozen |
| `components/nav.bp` | 26 · 27 | `Link` navigates without a document load, and the active item is highlighted from the router's selected segment |
| `components/post_card.bp` | 33 · 35 · 40 · 48 | emilia's palette, spacing and border tokens compose into one class, and front 48's attribute slot puts it on the element |
| `components/like_button.bp` | 29 · 68 · jhonstart hooks | A `'use client'` island: server-rendered once, bundled, hydrated, and its `state` hook works after hydration |

### `lib/`

| File | Fronts | Proves |
|---|---|---|
| `lib/db.bp` | 01 (`path`) · std `fs` | The store: list, read, write. No effects beyond `@Result` |
| `lib/actions.bp` | 24 · 12 · 63 | The mutation: write the file, `revalidateTag("posts")`, `redirect("/blog")` — and the list page shows the new post on the next request, which is the whole point of the tag |

### The four commands

| Command | Proves |
|---|---|
| `onze13 create blog --yes` | Front 50's scaffold produces something that passes `botopink check` with no edits |
| `onze13 dev` | Every route above renders; editing `app/page.bp` takes effect without a restart; adding a route takes effect without a restart |
| `onze13 build` | The client bundle exists and is content-hashed; the three posts are prerendered; the build id is stable across two runs |
| `onze13 build && onze13 start` | The same routes render from the release, with no compiler on the path |

## Mechanism

There is no mechanism here. This front writes no library code; every file in it is code an app author
would write, and where it cannot be written that way the file says so in a comment naming the front
that would fix it.

Two rules govern how it is written, and both exist because this front is the place inconsistency
becomes visible:

**Every file names the front it exercises, in a comment on the line that uses it.**
`// front 22 — dynamic segment` above the `params.param("slug")` read. When front 22's actual surface
turns out to differ, the grep is one line, not a file.

**Where this front had to assume an API shape, the assumption is in the file, not in the author's
head.** The list of assumptions is reproduced in *Assumed API shapes* below and is the first thing to
reconcile when the other fronts land. An assumption that turns out wrong is a one-line edit here and a
conversation with one front — which is the cheap failure mode, and the reason this front is written
before those fronts land rather than after.

## Steps

### Step 1 — The app skeleton and the store

`botopink.json`, `onze13.json`, `content/posts/*.md`, `lib/db.bp`, `components/tags.bp`. Nothing here
needs a front beyond 49 and std, so it can be written and tested first, and it is what everything else
stands on.

**Acceptance:**
- [ ] `listPosts()` returns the three seeded posts, sorted by publication date descending
- [ ] `readPost("missing")` reds with a message naming the slug
- [ ] `writePost` then `listPosts` shows four
- [ ] `tags.bp` renders `<nav>`, `<article>`, `<h2>`, `<a>`, `<form>`, `<label>`, `<input>`,
      `<button>`, `<time>` — the nine tags the app needs and jhonstart does not have
- [ ] The alias `@/lib.db` resolves from `app/blog/[slug]/page.bp`

### Step 2 — The read path

`app/layout.bp`, `app/page.bp`, `app/blog/layout.bp`, `app/blog/page.bp`,
`app/blog/[slug]/page.bp`, `app/(marketing)/about/page.bp`, `components/post_card.bp`,
`components/nav.bp`.

**Acceptance:**
- [ ] `/` renders with the hero image, the nav and one `<style>` block
- [ ] `/blog` lists three posts, each in a `PostCard` carrying one emilia class
- [ ] `/blog/hello-world` renders that post's title and body
- [ ] `/about` renders — the route group does not appear in the URL
- [ ] The document has exactly one `<style>` element and it is non-empty
- [ ] Two consecutive requests both have a non-empty `<style>` — which is the test that catches a
      sheet flushed once per process instead of once per request

### Step 3 — Static generation and metadata

`generateStaticParams` and `generateMetadata` on `app/blog/[slug]/page.bp`.

**Acceptance:**
- [ ] `onze13 build` prerenders `/blog/<slug>` for each of the three posts and no others
- [ ] A prerendered post is served without invoking the page fn — asserted by a counter in `lib/db.bp`
- [ ] `generateMetadata` produces `<title>` and the OG tags for the post, not for the blog index
- [ ] The metadata of `/blog/<slug>` merges with the root layout's rather than replacing it

### Step 4 — Streaming and boundaries

`app/loading.bp`, `app/error.bp`, `app/not-found.bp`, `app/blog/loading.bp`,
`app/blog/[slug]/loading.bp`, `app/blog/[slug]/not-found.bp`.

**Acceptance:**
- [ ] A deliberately slow `loadPosts` flushes the shell and the fallback before the list
- [ ] `/blog/does-not-exist` renders `app/blog/[slug]/not-found.bp`, with status 404
- [ ] A page that throws renders `app/error.bp`, with status 500, and the response contains the digest
      and not the message
- [ ] The nearest boundary wins: the post's `not-found.bp` is used, not the root's

### Step 5 — The write path

`app/dashboard/layout.bp`, `app/dashboard/posts/new/page.bp`, `lib/actions.bp`, `middleware.bp`.

**Acceptance:**
- [ ] `/dashboard` with no session cookie redirects to `/login` from the middleware, before the layout
      runs
- [ ] `/dashboard` with a session cookie renders
- [ ] Submitting the new-post form with an empty title re-renders the form with the message beside the
      field and creates nothing
- [ ] Submitting a valid form writes the file, and the next request to `/blog` shows the new post —
      which fails if `revalidateTag("posts")` did not reach the same store `loadPosts` reads from
- [ ] The form works with scripting disabled: a plain POST, a full re-render, the same outcome
- [ ] An action request whose `Origin` does not match `Host` is rejected with 403

### Step 6 — The client half

`components/like_button.bp`, `components/nav.bp`.

**Acceptance:**
- [ ] `onze13 build` emits a client chunk containing `like_button` and not containing `lib/db.bp`
- [ ] The rendered page carries a `<script>` tag pointing at a content-hashed chunk
- [ ] Clicking the like button increments without a request — the hook is live, so hydration happened
- [ ] `Link` navigation between `/blog` and `/blog/<slug>` does not re-request the document, and the
      blog layout is not remounted
- [ ] The build fails if `like_button.bp` imports `lib/db.bp` — the server-only module must not reach
      the client graph

### Step 7 — The gate

**Acceptance:**
- [ ] `onze13 dev` serves every route in the acceptance script
- [ ] `onze13 build && onze13 start` serves the same bytes for every static route
- [ ] `examples/blog/test/` is green on both targets
- [ ] Every `// front NN` comment in the app names a front that exists and delivers what the comment
      says it delivers — checked by a script, because fifty-two fronts is too many to check by reading

## Examples

`examples/` here is the app skeleton, not a separate set of demonstrations. Each file is the content of
the app file named in its header.

| Example | App file | Fronts it exercises |
|---|---|---|
| [`examples/tags-example.bp`](./examples/tags-example.bp) | `components/tags.bp` | the frozen-`element.bp` workaround |
| [`examples/lib-db-example.bp`](./examples/lib-db-example.bp) | `lib/db.bp` | 01 · std `fs`/`path` |
| [`examples/app-layout-example.bp`](./examples/app-layout-example.bp) | `app/layout.bp` | 49 · 52 · 27 · 69 · D |
| [`examples/app-page-example.bp`](./examples/app-page-example.bp) | `app/page.bp` | 22 · 51 · 60 |
| [`examples/blog-list-page-example.bp`](./examples/blog-list-page-example.bp) | `app/blog/page.bp` | 28 · 12 · 30 |
| [`examples/blog-slug-page-example.bp`](./examples/blog-slug-page-example.bp) | `app/blog/[slug]/page.bp` | 22 · 28 · 32 · 60 · 63 |
| [`examples/boundaries-example.bp`](./examples/boundaries-example.bp) | `app/loading.bp`, `app/error.bp`, `app/blog/[slug]/not-found.bp` | 30 · 31 · 63 |
| [`examples/post-card-example.bp`](./examples/post-card-example.bp) | `components/post_card.bp` | 33 · 35 · 40 · 48 |
| [`examples/server-action-example.bp`](./examples/server-action-example.bp) | `lib/actions.bp` | 24 · 12 · 63 |
| [`examples/new-post-form-example.bp`](./examples/new-post-form-example.bp) | `app/dashboard/posts/new/page.bp` | 24 · 67 |
| [`examples/client-island-example.bp`](./examples/client-island-example.bp) | `components/like_button.bp` | 29 · 68 |
| [`examples/route-handler-example.bp`](./examples/route-handler-example.bp) | `app/api/posts/route.bp` | 25 · 62 |
| [`examples/middleware-example.bp`](./examples/middleware-example.bp) | `middleware.bp` | 07 · 62 · 65 |

## Assumed API shapes

This front was written before fronts 01–48 and 60–71 landed, against the API each is chartered to
deliver in `overview.md` and in the coverage audit. Every shape below is an **assumption**, not a
specification, and the owning front's actual surface wins. Reconciling this table is the first task of
wave 5.

| Front | Assumed shape | Used in |
|---|---|---|
| 12 rakun-cache | `cacheTag(tag: string) -> void`, `cacheLife(profile: string) -> void`, `revalidateTag(tag: string) -> void`, `#[@future] cached<T>(key: string, produce: fn() -> T) -> @Future<T>` | `lib/db.bp`, `lib/actions.bp`, `app/blog/page.bp` |
| 07 · 65 middleware | `middleware.bp` exports `#[@future] pub fn middleware(ctx: RouteContext) -> @Future<MiddlewareResult>` and `pub fn matcher() -> string[]`; `MiddlewareResult.next()` / `.redirect(href)` / `.rewrite(path)` | `middleware.bp` |
| 22 file-routing | a `[slug]` segment reaches the page as one `Params` entry keyed `"slug"` | `app/blog/[slug]/page.bp` |
| 23 ssr-pipeline | consumes an `Element` and a head string; layout order outermost-first | every layout |
| 24 server-actions | `#[serverAction]` on a `#[@future] fn(form: Params) -> @Future<ActionResult>` | `lib/actions.bp` |
| 25 route-handlers | `route.bp` exports `#[@future] pub fn GET(ctx: RouteContext) -> @Future<Response>`, one fn per method | `app/api/posts/route.bp` |
| 26 router | `useRouter() -> Router` with `pathname()`, `push(href)`; `useSelectedLayoutSegment() -> string` | `components/nav.bp` |
| 27 link | `Link(href: string, children: Element[], attrs: Array<#(string, string)>) -> Element` — note the existing `router.d.bp:28` declares `children: fn() -> Children`, which this front assumes front 27 changes | `components/nav.bp`, `components/post_card.bp` |
| 28 server-components | a page may be `#[@future] pub fn P(props: PageProps) -> @Future<Element>`; front 50's scan reads the return type to choose the registry entry point | `app/blog/page.bp`, `app/blog/[slug]/page.bp` |
| 29 client-directive | `#[client]` on a module-level fn marks it and its import closure as the client graph | `components/like_button.bp` |
| 30 streaming | `loading.bp` exports `pub fn Loading() -> Element`; `suspense(fallback: Element, body: fn() -> @Future<Element>) -> Element` for an inline boundary | `app/blog/page.bp`, all `loading.bp` |
| 31 error-boundaries | `error.bp` exports `pub fn ErrorBoundary(props: ErrorProps) -> Element`; `ErrorProps(message: string, digest: string, reset: fn())`; `not-found.bp` exports `pub fn NotFound() -> Element` | `app/error.bp`, `app/blog/[slug]/not-found.bp` |
| 32 metadata | `Metadata(title, description, canonical, ogTitle, ogDescription, ogImage, ogType, twitterCard)` — flat, no nested option records; `#[@future] generateMetadata(props: PageProps) -> @Future<Metadata>` as a page-module export | `app/blog/[slug]/page.bp` |
| 33 · 35 · 40 emilia | `.Color.Gray.<n>`, `.Bg.White`, `.Pad.All.<n>`, `.Margin.Y.<n>`, `.Border.Rounded.Md`, `.Border.W.1`, `.Border.Color.Gray.100` — all present in `tokens.bp` today, so the assumption is only that these fronts do not rename them | `components/post_card.bp` and every styled file |
| 48 emilia-attributes | `classAttr(tokens: Token[]) -> #(string, string)` returning `#("class", emilia(tokens))` | `components/post_card.bp` |
| 51 image | `Image(props: ImageProps, cfg: ImageConfig, publicDir: string) -> Element` — front 51's own shape, restated here | `app/page.bp` |
| 52 font | `#[@future] googleFont(family, opts) -> @Future<Font>`; `fontHead(fonts: Font[]) -> string` | `app/layout.bp` |
| 60 static-generation | a page module exports `pub fn generateStaticParams() -> Params[]`, called at build time | `app/blog/[slug]/page.bp` |
| 62 request-context | `cookies() -> Cookies` with `get(name) -> string` (empty when absent), `set(name, value, opts)`, `remove(name)`; `headers() -> Headers` with `get(name) -> string`; `after(work: fn())` | `middleware.bp`, `app/dashboard/layout.bp`, `app/api/posts/route.bp` |
| 63 navigation-signals | `notFound()`, `redirect(href)`, `permanentRedirect(href)` — all diverging, none returning a value | `app/blog/[slug]/page.bp`, `app/dashboard/layout.bp`, `lib/actions.bp` |
| 67 forms | `Form(action: string, children: Element[], attrs: Array<#(string, string)>) -> Element`; `useActionState<S>(actionName: string, initial: S) -> @Context<Element, ActionState<S>>` with `ActionState(state: S, pending: bool)` as a **record**, not a tuple, because tuple labels are lost through generic instantiation (ground truth §2.39) | `app/dashboard/posts/new/page.bp` |
| 68 client-bundle | no call surface — the bundle is produced from front 29's markers; this front only asserts the emitted `<script>` tag and the graph exclusion | `components/like_button.bp` |
| 69 styling-pipeline | the head seam consumes the string `fontHead` and `flush()` produce; this front does not call it directly | `app/layout.bp` |

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | every `jhonstart` and `tags.bp` call in every example spells `attrs:` | pass every argument explicitly | apply the declared default at the call site (ground truth §2.24) |
| No assignment to a `self` field | `lib/db.bp`'s `Post` is rebuilt rather than updated; the form's state record is copied | return a new record | mutable record fields, or a `with` expression |
| `#[@future]` is required on any fn returning `@Future<T>` | every server component, action, handler and the middleware | write the marker | infer the effect from the return type |
| `xs[0]` silently drops the index on the BEAM backend | `lib/db.bp` parses a post with `.at(0)` / `.at(1)` / `.drop(2)` rather than indexing | `.at(i)` / `.slice(…)` / `.drop(n)` | fix the beam lowering |
| No bodyless methods in a `type` body | `Post` and `Params` carry no abstract members; the store is module-level fns | module-level `pub fn`, or `declare fn` with `#[@external]` | allow a bodyless method as a behavior requirement in a `type` body |
| Tuple labels are lost through generic instantiation | `useActionState` is assumed to return a **record**, not the `#(state, action, pending)` tuple Next's hook returns | a named record | preserve labels through instantiation (ground truth §2.39) |
| `if (a && b)` does not parse in condition position | the middleware's two-condition guard binds the conjunction to a `val` first | bind, then test | fix the condition parser (ground truth §2.1) |

## Findings that are not language gaps

These are library gaps this milestone does **not** currently close. Each is a note to the coordinator,
not a defect in a front.

**`element.bp` is frozen, and the app needs nine tags it does not have.** `fronts.md` freezes
`repository/jhonstart/src/element.bp`, which provides `text, fragment, div, span, p, h1, ul, li`. The
blog needs `nav`, `header`, `article`, `section`, `h2`, `a`, `form`, `label`, `input`, `button` and
`time`. No front in the milestone adds them, because the only file they could go in is frozen. The app
therefore builds them itself, in `components/tags.bp`, on the public `Element(tag, value, children,
attrs)` record — which works, and which every onze13 app would have to copy. Either a front gets the
file unfrozen, or onze13 grows a `tags` module, or every app writes this file.

**`renderToString` has no void-element table.** It emits `<tag …>children</tag>` for everything
(`element.bp:55-67`), so `<img>` and `<input>` render as `<img …></img>` and `<input …></input>`.
Browsers tolerate it; validators do not. Front 51's `Image` and this app's `input` both hit it, and it
cannot be fixed without touching the frozen file.

**Nothing serves `content/`.** The app's data directory is read by the server at request time, which is
fine, but front 69 serves `public/` and nothing states that a directory outside `public/` is *not*
served. The app relies on that; the rule should be written down in front 69.

## Test plan

`examples/blog/test/`, on **both** targets, plus a serving gate that is not a `test` block.

**In-process tests** (`botopink test`, both targets) cover everything that is a pure function of
inputs: `lib/db.bp`'s parse, list, read and write; `components/post_card.bp`'s emitted class;
`components/tags.bp`'s markup; `generateStaticParams`'s output; `generateMetadata`'s head string; the
middleware's decision given a `RouteContext`; and each page fn's `Element` given a `PageProps`. These
are the tests that catch vocabulary drift, and they run without a server.

**The serving gate** is the exit-gate line from `fronts.md`: `examples/blog` builds, serves and renders
its routes under both `onze13 dev` and `onze13 build && onze13 start`. It is a script under
`examples/blog/test/serve.sh` that starts each, curls every route in the acceptance script, and diffs
against committed expected bodies with the content hashes masked. It runs on erlang only, because that
is what serves.

**The client half** is asserted structurally, not behaviourally: the build emits a chunk, the chunk
contains `like_button` and does not contain `db`, and the document references it. Whether a click
increments a counter needs a browser, and the milestone has no browser harness; the README says so
rather than claiming hydration is tested.

## Definition of done

- [ ] Every file in the acceptance script exists and every row's *Proves* column is a green assertion
- [ ] `onze13 dev` and `onze13 build && onze13 start` both serve every route
- [ ] The *Assumed API shapes* table has been reconciled against each owning front, and every row
      either matches or has been changed here
- [ ] Every `// front NN` comment names a front that exists
- [ ] Every `// LANGUAGE GAP:` marker in `examples/blog/**` appears in a `specs/1.0.10-beta/` spec
- [ ] The front's tests are green on its assigned target — both, here
