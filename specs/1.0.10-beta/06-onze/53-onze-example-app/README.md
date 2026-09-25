# Front 53 — onze Example App

**Track:** E onze
**Priority:** medium — nothing depends on it, and it is the only front that can falsify the other
fifty-two. A milestone whose fronts are individually green and collectively unusable passes every gate
except this one
**Target:** both — full stack. The pages, layouts, actions, handlers and middleware compile to BEAM;
the client island, the `Link` navigation and the form's pending state compile to commonJS; the route
table and the serialized payload cross
**Wave:** 10
**Depends on:** all — and specifically, in critical-path order, 01 → 04 · 22 · 26 → 06 · 23 · 28 · 62
→ 24 · 60 · 63 · 68 → 67 → this
**Owns:** `examples/blog/**`, `examples/blog/test/**`
**Does not touch:** anything. This front is read-only against every other repository and against
`repository/onze/src/**`. A change it needs in a library is filed against that library's front, not
made here
**Reference:** `NEXTJS-DOCS.md § 3. Estrutura do Projeto`, `§ 5. Layouts e Páginas`,
`§ 6. Rotas Dinâmicas`, `§ 9. Busca de Dados`, `§ 10. Mutação de Dados`, `§ 11. Cache`,
`§ 13. Streaming`, `§ 14. Tratamento de Erros`, `§ 18. Metadata`, `§ 19. Route Handlers`,
`§ 20. Middleware`, plus the *Guia de Referência Rápida* structure ·
<https://nextjs.org/learn/dashboard-app> ·
<https://nextjs.org/docs/app/getting-started/project-structure>

---

## Problem

Fifty-two fronts each claim a green test on their assigned target. That claim is compatible with the
milestone not working, in three ways that unit tests structurally cannot catch.

**Vocabulary drift.** Front 22 extracts a route param; front 49 wraps it in `Params`; front 28 reads it
in a server component; front 32 reads it again in `generateMetadata`; front 60 produces the list of
values it can take at build time. Five fronts, one value, and each of them has its own test that
passes against its own idea of the shape. Nothing checks that the five ideas are the same idea.

**Ordering.** `emilia(tokens)` registers a class and `flush()` clears the sheet. jhonstart's render
(front 30) streams, and awaits the `jhonstart-emilia` plugin front 49 registers for the head, for
each chunk and for the payload's `s` key (decision 114). Front 52 wants its preload links before any other style. Each of those is
testable alone and the composition is not, because the composition only exists once something renders
a real document with fonts, styles, a streamed chunk and a late-arriving component in it.

**The halves.** Front 29 marks a client boundary, front 68 bundles it, jhonstart's render (front 30) serializes a payload
and front 67 reconnects a form to it. Four fronts, two targets, one round trip. The exit gate says no
server front carries an `@External.Node` cell and no client front carries an `#[@external(erlang)]`
cell — a static property. Whether the two halves actually meet is a dynamic one.

This front is a blog that exercises every one of those seams at once, and its README is the
milestone's acceptance script: walk the app file by file, and each file names the fronts it proves.

## Current state

Examples use the pre-118 effect annotations; front 24's codemod rewrites them ([`00 · 24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)).

- `repository/onze/examples/blog/` does not exist; `repository/onze/` does not exist until
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
make the milestone's proof depend on a service being installed. `std`'s `io.fs` and `path` already exist,
and a file is a mutation target with the same cache-invalidation problem a row has.

## The acceptance script

Each row is a file. The *Proves* column is the claim that fails if that file does not work, and the
fronts named are the ones whose surface the file uses. Run top to bottom; the first row that fails
names the front to look at.

### Top level

| File | Fronts | Proves |
|---|---|---|
| `botopink.json` | 49 · 50 | The alias map resolves: `@/components.post_card` reaches `components/post_card.bp` from four directories down |
| `onze.json` | 49 · 50 | `appDir`, `outDir`, `port` and `basePath` are read once and every command agrees on them |
| `middleware.bp` | 07 · 62 · 65 | A request to `/dashboard` with no session cookie is redirected before any page renders; a request to `/images/hero.jpg` is not matched at all |
| `content/posts/*.md` | — | Seed data, three posts, committed |

### `app/` — the routing tree

| File | Fronts | Proves |
|---|---|---|
| `app/layout.bp` | 49 · 52 · 27 · 69 · D | The root layout returns the body subtree; fonts, the nav, and emilia's sheet all reach the document head exactly once and in the right order |
| `app/page.bp` | 30 · 51 · 60 | `/` resolves; the hero image is optimized and eager; the route is prerendered at build time and served from the manifest |
| `app/loading.bp` | 30 | A slow render flushes the shell and the fallback before the body |
| `app/error.bp` | 31 · 17 | A thrown error renders the boundary and the digest, and the message never reaches the client |
| `app/not-found.bp` | 31 · 63 | An unmatched URL renders the 404 page with status 404, not status 200 |
| `app/blog/layout.bp` | 23 | Layout nesting: the blog shell wraps every `/blog/*` route and is not re-rendered on client navigation between them |
| `app/blog/page.bp` | 28 · 12 · 30 | A server component loads posts, the load is cached under a tag, and the list streams behind `loading.bp` |
| `app/blog/loading.bp` | 30 | The segment's own fallback, not the root one |
| `app/blog/[slug]/page.bp` | 30 · 28 · 32 · 60 · 63 | The dynamic segment reaches the page as `route.params.lookup("slug").unwrapOr("")`; `generateStaticParams` prerenders all three posts; `generateMetadata` produces the head; a missing slug calls `notFound()` |
| `app/blog/[slug]/loading.bp` | 30 | Per-post fallback |
| `app/blog/[slug]/not-found.bp` | 31 · 63 | The signal from the page lands in *this* boundary, not the root one |
| `app/blog/[slug]/opengraph-image.bp` | 66 · 70 · 32 · 52 | `image/svg+xml`, so the gate needs no rasterizer; `generateMetadata`'s `openGraph.images` points at it |
| `app/(marketing)/about/page.bp` | 22 | The route group contributes no URL segment: the page serves at `/about`, not `/(marketing)/about` |
| `app/dashboard/layout.bp` | 28 · 31 | The layout reads the session cookie with `use cookies()` and raises jhonstart's `redirect("/login")` — the one auth gate inside the render, above every `/dashboard/*` page, which is the pattern `NEXTJS-DOCS.md § 23` describes; the layout renders before the page, so a page under it never runs without a session (decision 117) |
| `app/dashboard/page.bp` | 62 · 28 | Lists the author's posts and links to `posts/new`; it does not check the session again |
| `app/dashboard/posts/new/page.bp` | 24 · 67 | A form bound to a server action: pending state, a returned validation message rendered beside the field, and a redirect on success; no session check of its own — the dashboard layout is the gate |
| `app/api/posts/route.bp` | 25 · 62 | `GET /api/posts` returns JSON; `POST` reads the body and the `Authorization` header |
| `app/globals.css` | 69 | One fingerprinted `<link>` in the head, before the module CSS |

### `components/`

| File | Fronts | Proves |
|---|---|---|
| `components/nav.bp` | 26 · 27 | `Link` navigates without a document load, and the active item is highlighted from the router's selected segment |
| `components/post_card.bp` | 33 · 35 · 40 · 48 | emilia's palette, spacing and border tokens compose into one class, and front 48's attribute slot puts it on the element |
| `components/like_button.bp` | 29 · 68 · jhonstart hooks | A `'use client'` island: server-rendered once, bundled, hydrated, and its `state` hook works after hydration |

### `lib/`

| File | Fronts | Proves |
|---|---|---|
| `lib/db.bp` | 01 (`path`) · std `io.fs` · 12 | The store: list, read, write, every read through front 12's `"posts"` tag. Blocking, not `@Future` — on the BEAM a render is a process |
| `lib/actions.bp` | 24 · 12 · 63 | The mutation: write the file, `cache.revalidateTag("posts")`, rakun's `redirect("/blog/<slug>")` — encoded into the `actions` envelope's `n` for a scripted submit (decision 117) — and the list page shows the new post on the next request, which is the whole point of the tag |
| `lib/auth.bp` | 62 · 10 | `sessionOf(cookies) -> ?Session`, read by `middleware.bp` and `app/dashboard/layout.bp`, so the cookie name is spelled once |

Also committed: `public/images/hero.jpg` (the hero on `app/page.bp`) and `public/favicon.ico`, so
front 69's `public/` row has a file to serve; and `examples/blog/DEPLOY.md` — the `generateDockerfile`
output and the three commands that build and run the image (front 71).

### The four commands

| Command | Proves |
|---|---|
| `onze create blog --yes` | Front 50's scaffold produces something that passes `botopink check` with no edits |
| `onze dev` | Every route above renders; editing `app/page.bp` takes effect without a restart; adding a route takes effect without a restart |
| `onze build` | The client bundle exists and is content-hashed; the three posts are prerendered; the build id is stable across two runs |
| `onze build && onze start` | The same routes render from the release, with no compiler on the path |

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

`botopink.json`, `onze.json`, `content/posts/*.md`, `lib/db.bp`, `components/tags.bp`. Nothing here
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
- [ ] `onze build` prerenders `/blog/<slug>` for each of the three posts and no others
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
- [ ] The layout is the gate inside the render: rendering `/dashboard/posts/new` in process with a
      `RequestData` that carries no session cookie answers 307 with `location: /login` through the
      `Response`, writes no chunk, and never invokes `newPostPage` — the redirect comes from
      `app/dashboard/layout.bp`, and no page under `/dashboard` checks the session (decision 117)
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
- [ ] `onze build` emits a client chunk containing `like_button` and not containing `lib/db.bp`
- [ ] The rendered page carries a `<script>` tag pointing at a content-hashed chunk
- [ ] Clicking the like button increments without a request — the hook is live, so hydration happened
- [ ] `Link` navigation between `/blog` and `/blog/<slug>` does not re-request the document, and the
      blog layout is not remounted
- [ ] The build fails if `like_button.bp` imports `lib/db.bp` — the server-only module must not reach
      the client graph

### Step 7 — The gate

**Acceptance:**
- [ ] `onze dev` serves every route in the acceptance script
- [ ] `onze build && onze start` serves the same bytes for every static route
- [ ] `examples/blog/test/` is green on both targets
- [ ] Every `// front NN` comment in the app names a front that exists and delivers what the comment
      says it delivers — checked by a script, because fifty-two fronts is too many to check by reading

## Examples

`examples/` here is the app skeleton, not a separate set of demonstrations. Each file is the content of
the app file named in its header.

| Example | App file | Fronts it exercises |
|---|---|---|
| [`examples/lib-db-example.bp`](./examples/lib-db-example.bp) | `lib/db.bp` | 01 · std `io.fs`/`path` · 12 |
| [`examples/app-tree-example.bp`](./examples/app-tree-example.bp) | the `app/` tree: root and blog layouts, home, a dynamic post and a route-group page | 30 · 22 · 23 |
| [`examples/app-layout-example.bp`](./examples/app-layout-example.bp) | `app/layout.bp` | 30 · 27 · 48 · 52 · 69 |
| [`examples/app-page-example.bp`](./examples/app-page-example.bp) | `app/page.bp` | 30 · 51 · 60 |
| [`examples/blog-list-page-example.bp`](./examples/blog-list-page-example.bp) | `app/blog/page.bp` + `layout.bp` + `loading.bp` | 30 · 28 · 12 |
| [`examples/blog-slug-page-example.bp`](./examples/blog-slug-page-example.bp) | `app/blog/[slug]/page.bp` | 30 · 28 · 32 · 60 · 63 |
| [`examples/boundaries-example.bp`](./examples/boundaries-example.bp) | `app/loading.bp`, `app/error.bp`, `app/blog/[slug]/not-found.bp` | 30 · 31 · 63 · 17 |
| [`examples/post-card-example.bp`](./examples/post-card-example.bp) | `components/post_card.bp` | 33 · 35 · 40 · 48 · 27 |
| [`examples/server-action-example.bp`](./examples/server-action-example.bp) | `lib/actions.bp` | 24 · 12 · 63 |
| [`examples/new-post-form-example.bp`](./examples/new-post-form-example.bp) | `app/dashboard/posts/new/page.bp` + `app/dashboard/layout.bp` | 24 · 67 · 62 · 63 |
| [`examples/client-island-example.bp`](./examples/client-island-example.bp) | `components/like_button.bp` | 29 · 68 · 49 |
| [`examples/route-handler-example.bp`](./examples/route-handler-example.bp) | `app/api/posts/route.bp` | 25 · 22 · 12 |
| [`examples/middleware-example.bp`](./examples/middleware-example.bp) | `middleware.bp` | 07 · 65 · 04 |

There is no `components/tags.bp` example any more. The extra element builders
(`nav`, `header`, `main`, `section`, `article`, `h2`, `form`, `input`, `label`, `button`, `timeTag`)
are imported from `"jhonstart"` and are provided by **front 94 — `jhonstart-element-surface`**, in
`repository/jhonstart/src/elements.bp`. Building them locally, as an earlier draft of this front did
through the public `Element` record, would have been a twelfth copy of the same file.

## Assumed API shapes

This front was drafted before the other fronts landed and then reconciled against them once their
READMEs and examples were on disk. The table separates what is now **verified** against a front's own
example from what is still **assumed**, because only the second column is a risk.

### Verified against the owning front's example

| Front | Shape as that front actually writes it |
|---|---|
| 07 · 65 | `import {Filter, Chain, Next, middleware, matcher} from "rakun-web";` · `#[middleware] #[matcher("/dashboard/:path*")] pub fn middleware(req: Request, chain: Chain) -> Response` · `Next.redirect` / `Next.rewrite` / `chain.next(req)` · `rkSetReplyHeader`, `rkChainNext`, `rkTestRequest`, `rkTestRequestAuthed`, `rkReplyHeaderValue` |
| 12 | `import {cachePolicy, cacheThrough, cacheLife, CacheScope} from "rakun-cache";` · `import {cache} from "rakun-cache";` for `cache.revalidateTag`, `cache.revalidatePath`, `cache.revalidatedPaths()` · **loaders are blocking, not `@Future`** |
| 30 | `import {page, layout, PageContext, LayoutProps} from "jhonstart";` · `#[page("blog/[slug]")]` / `#[layout("blog")]`, argument = app-relative directory, segment grammar front 22's · every page, layout and template is `#[@use] pub fn … -> @Component<Element>`, and the marker refuses any other form at compile time (decision 117) · `route.params.lookup(k).unwrapOr("")` (a `Dict`) · `PageContext(pathname, pattern, params, query, rest)` · `LayoutProps.children` · the decorators fill jhonstart's UI registry; onze's boot copies each record into rakun's route table and hands rakun one `PageRenderer` per page (decision 114) |
| 22 · 23 | no call surface in the app — rakun's route table and `page(pattern, render: PageRenderer)` over `ChunkWriter` are reached by onze's boot only; `rkAppRegisterHandler` is imported by any module carrying a front 25 route handler |
| 24 | `import {serverAction, FormData, ActionResult} from "rakun";` · `#[serverAction] #[@future] fn(form: FormData) -> @Future<ActionResult>` · `form.field(name)` · `ActionResult.invalid(field, message)` / `ActionResult.done()` · `result.state.lookup(field)` |
| 25 | `import {getRoute, postRoute, HandlerResponse, bodyJson} from "rakun";` · `#[getRoute("api/posts")] #[@future] fn(req: Request) -> @Future<HandlerResponse>` · `HandlerResponse.json/created/notFound/badRequest/unsupportedMedia/withStatus` + `.withHeader` |
| 27 | `import {Link, linkProps, withPrefetch, withClass} from "jhonstart";` · `Link(linkProps("/blog"), [children])` |
| 29 | `import {client, clientProps, clientMount, Island} from "jhonstart";` · `#[client]`, `#[clientProps]` · `Island(id, component, props)` · `clientMount(island, [])` |
| 30 | `import {Boundary, Suspense, boundaryId, shellHtml} from "jhonstart";` · `Boundary(id, fallback, child)` where `child` is a thunk · `loading.bp` exports `pub fn Loading() -> Element` |
| 31 | `import {ErrorInfo, ErrorBoundary, catchError, renderBoundaryChecked, isSignal} from "jhonstart";` · a signal's reason is one of the bundled library `routing`'s `nav:` reasons (`nav:not-found`, `nav:redirect:<url>` — decision 116) · `catchError(id, fallbackFn, childThunk)` · `ErrorInfo.digest` · `not-found.bp` exports `pub fn NotFound() -> Element` |
| 32 | `Metadata(title, titleTemplate, description, openGraph, twitter, icons)` · `OpenGraph(title, description, url, ogType, siteName, images)` · `TwitterCard(card, title, description, images)` · `Icons(icon, apple)` · `mergeMetadata`, `pairValue` · `generateMetadata(params: Array<#(string, string)>) -> @Future<Metadata>` |
| 48 | `import {styled, styledWith, withAttrs, Token} from "emilia";` · `styled(t) == #("class", emilia(t))` · `styledWith(base, t)` is static-first, one ASCII space · token lists live in named functions because token order is class identity |
| 60 | `import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";` · `SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` · `StaticParams(bindings: [ParamBinding(name, value)])` |
| 62 | in an action or a handler (rakun's code): `import {cookies, headers, after, CookieAttrs} from "rakun";` · `cookies().get(name) -> ?string` · a cookie write is legal there and raises from a render. **In a page, layout or template** the reader is jhonstart's: `import {cookies, pairValue} from "jhonstart";` · `val jar = use cookies();` · `pairValue(jar, name) -> string` (front 28 over the `RequestData` onze hands in — decisions 114, 115, 117) |
| 63 · 31 | **in a page, layout or template**: `import {notFound, redirect} from "jhonstart";` (front 31, decision 115) · both are thrown — `throw notFound();`, `throw redirect("/login");` — from a page, layout or template (each a `#[@use] … -> @Component<Element>`) or a `#[@result]` helper. jhonstart handles them itself (decision 117): before the first chunk its render answers 404 with the nearest not-found boundary or 307 with `location`, after it they are markup, status 200; onze takes no part. In an action: `import {redirect} from "rakun";` — rakun's `redirect`, written into the envelope's `n`; in a handler: `import {notFound, redirect} from "rakun";` — both diverge and are called as `val _gone = redirect(…);` |
| 67 | `import {actionState, FormBinding, formAction, formAttrs, useActionState} from "jhonstart";` · `import {state.ActionState, envelope.parseActionState} from "actions";` — the action protocol is the bundled library `actions` (`01-std/05-actions-lib`, decision 116) · `use useActionState(name, initial)` inside a `#[@use] fn … -> @Component<Element>` (decision 104) read POSITIONALLY (`s.0` state, `s.1` binding, `s.2` pending) · `state.fieldError(name)` |
| 68 | no call surface — the bundle is produced from front 29's markers; the env prefix is `ONZE_PUBLIC_`, matching front 49 |
| 94 | `import {nav, header, main, section, article, h2, form, input, label, button, timeTag} from "jhonstart";` — `repository/jhonstart/src/elements.bp` |

### Still assumed — reconcile these first

| Front | Assumed shape | Why it is still open |
|---|---|---|
| 30 | `LayoutProps(children: leaf)` is constructible with one named field | `LayoutProps` is jhonstart front 30's record (decision 114); no example there constructs one, so the field list is unverified and three of this front's tests construct one |
| 51 · 52 | `Image(props, cfg, publicDir)`, `googleFont(family, opts) -> @Future<Font>`, `fontHead(fonts) -> string` | These are fronts 51 and 52's own shapes, defined in this milestone by the same author; nothing external has confirmed them |
| 30 | emilia's block reaches the head and each streamed chunk, and the payload's `s` key, through the asynchronous `jhonstart-emilia` plugin that front 49 registers (decisions 113, 114) | This front's layout produces the head string and hands it over; it does not call the plugin, so the seam is cited rather than exercised |
| 12 | `cache.revalidatedPaths()` is a test seam available to an app's own tests | Front 12's example uses it, but it is described there as a seam rather than public surface |
| 94 | how a void element (`input`, `img`) renders | Front 94 owns `elements.bp` and is settling it; this app's `input` assertions and front 51's `Image` both depend on the answer |

Four rows that were open when this front was drafted have since been settled by their owners — the
route-handler decorator (`#[getRoute]`), the form binding (`data-jh-a` + the action field), the
streaming marker (ordinal `data-jh-h`) and the element-surface front number (94). This front's
examples were already written against the settled form in all four cases; the reasoning is kept under
*Contradictions*.

## Language gaps

Every row here is already in [`language-gaps.md`](../../language-gaps.md); this table says where in the
app each one bites, and does not restate the proposed surface.

| Gap (see `language-gaps.md`) | Where it bites in this app |
|---|---|
| Declared parameter defaults are never applied | every element constructor call in all twelve examples writes `attrs:` |
| `xs[0]` silently drops the index on the BEAM backend | `lib/db.bp` parses a post with `.at(0)` / `.at(1)` / `.drop(2)` |
| Tuple labels are lost through generic instantiation | `useActionState` is read positionally in `new-post-form-example.bp` (`s.0` / `s.1` / `s.2`) |
| `if (a && b)` does not parse in condition position | `middleware.bp` binds each conjunction to a `val` before testing it |
| No assignment to a `self` field | `Post` is rebuilt rather than updated; the form's state is copied |
| No byte or binary type | `app/api/posts/route.bp` refuses `multipart/form-data` with 415 rather than reading it lossily |
| No `await` inside a `loop` or a closure | no page in this app awaits inside a loop; the store is blocking instead, which is front 12's shape |

One gap is new here and is **not** yet in `language-gaps.md`:

| Gap | Bites | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No bottom type** — a diverging call (`notFound()`, `redirect()`) still leaves the caller obliged to produce a value | 53 · 63 · and every `[slug]` page in every onze app | `if (found.isEmpty()) { val _gone = notFound(); }; val post = found.first().unwrapOr(missingPost(slug));` — the `unwrapOr` default is unreachable and exists only to satisfy the type | a `never` / `!` return type, so `notFound()` ends the function and the statements after it are a compile error rather than dead code |

## Contradictions found while writing this front

Each of these is two fronts disagreeing about one thing. None is a defect in this front. The reasoning
is kept for the rows that have since been settled, because the reasoning is what stops the same
disagreement recurring; **RESOLVED** marks the ones already fixed on disk by their owners.

**Two spellings for the route-handler decorator. — RESOLVED.** Front 25 wrote `#[getRoute("api/posts")]`
and `#[postRoute("api/posts")]`; front 62's example wrote `#[getHandler("api/whoami")]` for the same
registration. Front 25 owns `route_handler.bp`, so `#[getRoute]` wins and front 62 is being corrected.
This app's `app/api/posts/route.bp` already uses `#[getRoute]` / `#[postRoute]`.

**Two form bindings. — RESOLVED.** `contracts.md § 3` and front 24 agree: `data-jh-a="<id>"` plus a
hidden action field, the action addressed by an HMAC'd id and never by its name. The field's name
(and the scripted header's) is passed by onze to both sides — `actionField` / `actionHeader` to
jhonstart, `rakun.actions.field` / `rakun.actions.header` to rakun — and is `__bp_action` /
`X-Bp-Action` by onze's default (decision 114). Front 67's
example had asserted `data-jh-form="createPost"` and `action="/_onze/action/createPost"` — the
function's own name in both the attribute and the URL, which is exactly what front 24 tests the absence
of. Front 67 now follows `contracts.md`, and this app's form assertions were already written against it.

**Two streaming markers. — RESOLVED.** Front 30's example had asserted
`data-jh-suspense="blog.page"` — a route-derived id. `contracts.md § 2` pins the streaming hole as
`<div data-jh-h="h0">` with ORDINAL ids assigned by jhonstart's render in shell order. Front 30 now
emits the ordinal form; `boundaryId` remains front 30's own bookkeeping name and is
not the wire id, which is the distinction worth keeping written down.

**The element surface is front 94. — RESOLVED.** Fronts 26–31, 67 and 68 had all cited "the
element-surface front of track C (number allocated from 54 up)" without naming it. It is
`94-jhonstart-element-surface`, owning `repository/jhonstart/src/elements.bp`, and those eight fronts
have been substituted the way this front's examples were.

**Registration is jhonstart's and rakun's, wired by onze.** `#[page("…")]` / `#[layout("…")]` are
jhonstart front 30's and fill its UI registry; onze's boot (front 49) copies the records into rakun's
route table and hands rakun one `PageRenderer` per page through `page(pattern, render)` (decision
114). Nothing in this app calls an onze registry.

**Wave 0 for front 49 is too early for its integration layer.** `fronts.md` puts front 49 in wave 0,
blocked by nothing, but the wiring it was chartered to deliver reads fronts 22, 23 and 69. Front 49 now
splits explicitly: package, config, alias map and env rule in wave 0; the wiring is documentation of
other fronts' seams rather than code of its own.

**`modules/onze-cli/botopink.json` has no owner.** `fronts.md` gives front 50
`modules/onze-cli/src/**` and `modules/onze-cli/test/**`; a module package also needs its own
`botopink.json`, outside both globs. Front 50 lands it under the same hand-off rule track A uses for
`libs/std/src/root.bp`.

**`renderToString` has no void-element table. — OPEN, owned by front 94.** It emits
`<tag …>children</tag>` for everything (`element.bp:55-67`), so `<img>` and `<input>` render as
`<img …></img>` and `<input …></input>`. Front 24's example asserts
`markup.contains("</input>") == false`, which cannot hold through the frozen renderer, and this app's
`input` fields and front 51's `Image` both hit it. Front 94 owns `elements.bp` and has been asked to
settle how a void element renders; until it does, this row stays open and the assertion above is the
one that will fail first.

**Nothing states that `content/` is not served. — RESOLVED.** Front 69 serves `public/`. This app keeps
its posts in `content/`, read by the server at request time, and relies on that directory not being
reachable over HTTP. The rule is being written into front 69 rather than left implied by an allowlist.

## Test plan

`examples/blog/test/`, on **both** targets, plus a serving gate that is not a `test` block.

**In-process tests** (`botopink test`, both targets) cover everything that is a pure function of
inputs: `lib/db.bp`'s parse, list, read and write; `components/post_card.bp`'s emitted class;
`components/tags.bp`'s markup; `generateStaticParams`'s output; `generateMetadata`'s head string; the
middleware's decision given a `Request` and a `Chain`; and each page fn's `Element` given a
`PageContext`. These
are the tests that catch vocabulary drift, and they run without a server.

**The serving gate** is the exit-gate line from `fronts.md`: `examples/blog` builds, serves and renders
its routes under both `onze dev` and `onze build && onze start`. It is a script under
`examples/blog/test/serve.sh` that starts each, curls every route in the acceptance script, and diffs
against committed expected bodies with the content hashes masked. It runs on erlang only, because that
is what serves.

**The client half** is asserted structurally, not behaviourally: the build emits a chunk, the chunk
contains `like_button` and does not contain `db`, and the document references it. Whether a click
increments a counter needs a browser, and the milestone has no browser harness; the README says so
rather than claiming hydration is tested.

## Definition of done

- [ ] Every file in the acceptance script exists and every row's *Proves* column is a green assertion
- [ ] `onze dev` and `onze build && onze start` both serve every route
- [ ] The *Assumed API shapes* table has been reconciled against each owning front, and every row
      either matches or has been changed here
- [ ] Every `// front NN` comment names a front that exists
- [ ] Every `// LANGUAGE GAP:` marker in `examples/blog/**` appears in a `specs/1.0.10-beta/` spec
- [ ] The front's tests are green on its assigned target — both, here
