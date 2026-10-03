# Front 53 — the acceptance script: what the blog is and what each file proves

The record of the app, its acceptance script, the assumed API shapes and the definition of done.
The open half, its order and its blockers are in [`README.md`](./README.md); its steps cite the
sections below. `[x]` marks what holds on `feat`.

**Why a combined app.** Each library front's tests pass against its own idea of a shape; three
things only a real app can falsify: **vocabulary drift** (one route param read by five fronts —
22, 49, 28, 32, 60 — each with its own test), **ordering** (emilia's sheet, jhonstart's streamed
chunks and the payload's `s` key through the `jhonstart-emilia` plugin, front 52's preload links
first — decision 114), and **the halves** (front 29 marks a client boundary, 68 bundles it,
jhonstart's render serializes the payload, 67 reconnects a form: two targets, one round trip).
**Target:** both — pages, layouts, actions, handlers and middleware compile to BEAM; the island,
the `Link` navigation and the form's pending state to commonJS; the route table and the payload
cross. **Reference:** `NEXTJS-DOCS.md` §§ 3, 5, 6, 9, 10, 11, 13, 14, 18, 19, 20 and the *Guia de
Referência Rápida* structure · <https://nextjs.org/learn/dashboard-app> ·
<https://nextjs.org/docs/app/getting-started/project-structure>

## What the app is

A blog with an author dashboard — the smallest shape that needs every mechanism once: a list, a
detail page with a dynamic segment, a page that can 404, a form that mutates, a cache that the
mutation invalidates, an authenticated area, and one interactive island. Posts live on disk under
`content/posts/<slug>.md` (line 1 the title, line 2 the publication date, the rest the body); no
database, so the proof depends on no installed service (`rakun-data-sql` is off this path), and a
file is a mutation target with the same cache-invalidation problem a row has.

**Two rules for every file.** (1) Every file names the front it exercises, in a comment on the
line that uses it (`// front 22 — dynamic segment` above the param read), so a surface that turns
out different is a one-line grep. (2) Where an API shape had to be assumed, the assumption is in
the file and in § Assumed API shapes below — the first thing to reconcile when a front lands.
This front writes no library code; where a file cannot be written as an app author would, it
says so in a comment naming the front that would fix it.

## The acceptance script

Each row is a file; *Proves* is the claim that fails if the file does not work; the fronts named
are those whose surface it uses. Run top to bottom; the first failing row names the front to
look at.

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
| `app/dashboard/layout.bp` | 28 · 31 | The layout reads the session cookie with `use cookies()` and raises jhonstart's `redirect("/login")` — the one auth gate inside the render, above every `/dashboard/*` page (`NEXTJS-DOCS.md § 23`); the layout renders before the page, so a page under it never runs without a session (decision 117) |
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
| `lib/db.bp` | 01 (`path`) · std `io.fs` · 12 | The store: list, read, write, every read through front 12's `"posts"` tag. Blocking, not `@Task` — on the BEAM a render is a process |
| `lib/actions.bp` | 24 · 12 · 63 | The mutation: write the file, `cache.revalidateTag("posts")`, rakun's `redirect("/blog/<slug>")` — encoded into the `actions` envelope's `n` for a scripted submit (decision 117) — and the list page shows the new post on the next request, which is the whole point of the tag |
| `lib/auth.bp` | 62 · 10 | `sessionOf(cookies) -> ?Session`, read by `middleware.bp` and `app/dashboard/layout.bp`, so the cookie name is spelled once |

Also committed: `public/images/hero.jpg` (the hero on `app/page.bp`) and `public/favicon.ico`, so
the `public/` row has a file to serve; and `examples/blog/DEPLOY.md` — the `generateDockerfile`
output and the three commands that build and run the image (front 71).

### The four commands

| Command | Proves |
|---|---|
| `onze create blog --yes` | Front 50's scaffold produces something that passes `botopink check` with no edits |
| `onze dev` | Every route above renders; editing `app/page.bp` takes effect without a restart; adding a route takes effect without a restart |
| `onze build` | The client bundle exists and is content-hashed; the three posts are prerendered; the build id is stable across two runs |
| `onze build && onze start` | The same routes render from the release, with no compiler on the path |

## Steps

### Done

- Step 1 — the skeleton and the store: `listPosts()` returns the three seeded posts newest first;
  `readPost("missing")` reds naming the slug; `writePost` then `listPosts` shows four;
  `tags_test`: `<nav>`, `<article>`, `<h2>`, `<a>`, `<form>`, `<label>`, `<input>`, `<button>`,
  `<time>` render; `@/lib.db` resolves from `app/blog/[slug]/page.bp`
- Step 2 — the read path: `/` (hero, nav, one `<style>`), `/blog` (three `PostCard`s, one emilia
  class each), `/blog/hello-world` and `/about` (`/marketing/about` 404) served by `onze start`
  (`onze-cli/test/start_test.bp`); exactly one non-empty `<style>`, on two consecutive requests
- Step 4 — `/blog/does-not-exist` renders `app/blog/[slug]/not-found.bp` with 404, and none of
  `app/not-found.bp`'s text (the nearest boundary wins) — `start_test.bp`
- Step 5 — the dashboard layout is the gate inside the render: `/dashboard/posts/new` in process
  with no session cookie answers 307 `location: /login`, writes no chunk and never invokes the
  page (`examples/blog/test/render_test.bp`, both rows); with `session=s1` `/dashboard` renders
  (in process and over the socket, `start_test.bp`)
- Step 6 — `onze build` emits a `shared` chunk holding `components/like_button` and no `lib/db`;
  the page's `<script>` names a content-hashed `entry.<hash>.js` that is served; a
  `like_button.bp` importing `@/lib.db` fails the build with "server-only module lib.db reached
  from client root components.like_button" (`onze-cli/test/build_test.bp`)
- Step 7 — `examples/blog/test/` is green on both targets

### Step 3 — static generation and metadata

`generateStaticParams` and `generateMetadata` on `app/blog/[slug]/page.bp`.

- [ ] `onze build` prerenders `/blog/<slug>` for each of the three posts and no others
- [ ] A prerendered post is served without invoking the page fn — asserted by a counter in `lib/db.bp`
- [ ] `generateMetadata` produces `<title>` and the OG tags for the post, not for the blog index
- [ ] The metadata of `/blog/<slug>` merges with the root layout's rather than replacing it

### Step 4 — streaming and boundaries

`app/loading.bp`, `app/error.bp`, `app/blog/loading.bp`, `app/blog/[slug]/loading.bp`.

- [ ] A deliberately slow `loadPosts` flushes the shell and the fallback before the list
- [ ] A page that throws renders `app/error.bp`, with status 500, and the response contains the
      digest and not the message

### Step 5 — the write path

`app/dashboard/posts/new/page.bp`, `lib/actions.bp`, `middleware.bp`.

- [ ] `/dashboard` with no session cookie redirects to `/login` from the middleware, before the
      layout runs
- [ ] Submitting the new-post form with an empty title re-renders the form with the message
      beside the field and creates nothing
- [ ] Submitting a valid form writes the file, and the next request to `/blog` shows the new post
      — which fails if `revalidateTag("posts")` did not reach the same store `loadPosts` reads
- [ ] The form works with scripting disabled: a plain POST, a full re-render, the same outcome
- [ ] An action request whose `Origin` does not match `Host` is rejected with 403

### Step 6 — the client half

`components/like_button.bp`, `components/nav.bp`.

- [ ] Clicking the like button increments without a request — the hook is live, so hydration
      happened
- [ ] `Link` navigation between `/blog` and `/blog/<slug>` does not re-request the document, and
      the blog layout is not remounted

### Step 7 — the gate

- [ ] `onze dev` serves every route in the acceptance script
- [ ] `onze build && onze start` serves the same bytes for every static route
- [ ] Every `// front NN` comment in the app names a front that exists and delivers what the
      comment says — checked by a script, not by reading

## Examples

`examples/` is the app skeleton; each file is the content of the app file named in its header.

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

There is no `components/tags.bp` example: the element builders (`nav`, `header`, `main`,
`section`, `article`, `h2`, `form`, `input`, `label`, `button`, `timeTag`) are imported from
`"jhonstart"` (front 94, `repository/jhonstart/modules/jhonstart/src/elements.bp`). The `.bpp`
files under `examples/app/` and `examples/components/` are the same app in the `.bpp` file kind.

## Assumed API shapes

Reconciled row by row by README step 6. **Verified** is checked against the owning front's
example; **still assumed** is the risk.

### Verified against the owning front's example

| Front | Shape as that front actually writes it |
|---|---|
| 07 · 65 | `import {Filter, Chain, Next, middleware, matcher} from "rakun-web";` · `#[middleware] #[matcher("/dashboard/:path*")] pub fn middleware(req: Request, chain: Chain) -> Response` · `Next.redirect` / `Next.rewrite` / `chain.next(req)` · `rkSetReplyHeader`, `rkChainNext`, `rkTestRequest`, `rkTestRequestAuthed`, `rkReplyHeaderValue` |
| 12 | `import {cachePolicy, cacheThrough, cacheLife, CacheScope} from "rakun-cache";` · `import {cache} from "rakun-cache";` for `cache.revalidateTag`, `cache.revalidatePath`, `cache.revalidatedPaths()` · **loaders are blocking, not `@Task`** |
| 30 | `import {page, layout, PageContext, LayoutProps} from "jhonstart";` · `#[page("blog/[slug]")]` / `#[layout("blog")]`, argument = app-relative directory, segment grammar front 22's · every page, layout and template is `pub fn … -> @Component<ElementBase, Element>`, and the marker refuses any other form at compile time (decision 117) · `route.params.lookup(k).unwrapOr("")` (a `Dict`) · `PageContext(pathname, pattern, params, query, rest)` · `LayoutProps.children` · the decorators fill jhonstart's UI registry; onze's boot copies each record into rakun's route table and hands rakun one `PageRenderer` per page (decision 114) |
| 22 · 23 | no call surface in the app — rakun's route table and `page(pattern, render: PageRenderer)` over `ChunkWriter` are reached by onze's boot only; `rkAppRegisterHandler` is imported by any module carrying a front 25 route handler |
| 24 | `import {serverAction, FormData, ActionResult} from "rakun";` · `#[serverAction] fn(form: FormData) -> @Task<ActionResult>` · `form.field(name)` · `ActionResult.invalid(field, message)` / `ActionResult.done()` · `result.state.lookup(field)` |
| 25 | `import {getRoute, postRoute, HandlerResponse, bodyJson} from "rakun";` · `#[getRoute("api/posts")] fn(req: Request) -> @Task<HandlerResponse>` · `HandlerResponse.json/created/notFound/badRequest/unsupportedMedia/withStatus` + `.withHeader` |
| 27 | `import {Link, linkProps, withPrefetch, withClass} from "jhonstart";` · `Link(linkProps("/blog"), [children])` |
| 29 | `import {client, clientProps, clientMount, Island} from "jhonstart";` · `#[client]`, `#[clientProps]` · `Island(id, component, props)` · `clientMount(island, [])` |
| 30 | `import {Boundary, Suspense, boundaryId, shellHtml} from "jhonstart";` · `Boundary(id, fallback, child)` where `child` is a thunk · `loading.bp` exports `pub fn Loading() -> Element` |
| 31 | `import {ErrorInfo, ErrorBoundary, catchError, renderBoundaryChecked, isSignal} from "jhonstart";` · a signal's reason is one of the bundled library `routing`'s `nav:` reasons (`nav:not-found`, `nav:redirect:<url>` — decision 116) · `catchError(id, fallbackFn, childThunk)` · `ErrorInfo.digest` · `not-found.bp` exports `pub fn NotFound() -> Element` |
| 32 | `Metadata(title, titleTemplate, description, openGraph, twitter, icons)` · `OpenGraph(title, description, url, ogType, siteName, images)` · `TwitterCard(card, title, description, images)` · `Icons(icon, apple)` · `mergeMetadata`, `pairValue` · `generateMetadata(params: Array<#(string, string)>) -> @Task<Metadata>` |
| 48 | `import {styled, styledWith, withAttrs, Token} from "emilia";` · `styled(t) == #("class", emilia(t))` · `styledWith(base, t)` is static-first, one ASCII space · token lists live in named functions because token order is class identity |
| 60 | `import {registerSegmentConfig, registerStaticParams, SegmentConfig, DynamicMode, FetchCache, StaticParams, ParamBinding} from "rakun";` · `SegmentConfig(dynamic, dynamicParams, revalidate, fetchCache)` · `StaticParams(bindings: [ParamBinding(name, value)])` |
| 62 | in an action or a handler (rakun's code): `import {cookies, headers, after, CookieAttrs} from "rakun";` · `cookies().get(name) -> ?string` · a cookie write is legal there and raises from a render. **In a page, layout or template** the reader is jhonstart's: `import {cookies, pairValue} from "jhonstart";` · `val jar = use cookies();` · `pairValue(jar, name) -> string` (front 28 over the `RequestData` onze hands in — decisions 114, 115, 117) |
| 63 · 31 | **in a page, layout or template**: `import {notFound, redirect} from "jhonstart";` (front 31, decision 115) · in a page, layout or template (each a `fn … -> @Component<ElementBase, Element>`, which cannot `throw` — decision 121) both are called — `notFound();`, `redirect("/login");` (front 24's `guide.md` § 7) — and in a `-> @Result<…>` helper both are thrown — `throw notFound();`. jhonstart handles them itself (decision 117): before the first chunk its render answers 404 with the nearest not-found boundary or 307 with `location`, after it they are markup, status 200; onze takes no part. In an action: `import {redirect} from "rakun";` — rakun's `redirect`, written into the envelope's `n`; in a handler: `import {notFound, redirect} from "rakun";` — both diverge and are called as `val _gone = redirect(…);` |
| 67 | `import {actionState, FormBinding, formAction, formAttrs, useActionState} from "jhonstart";` · `import {state.ActionState, envelope.parseActionState} from "actions";` — the action protocol is the bundled library `actions` (decision 116) · `use useActionState(name, initial)` inside a `fn … -> @Component<ElementBase, Element>` (decision 104) read POSITIONALLY (`s.0` state, `s.1` binding, `s.2` pending) · `state.fieldError(name)` |
| 68 | no call surface — the bundle is produced from front 29's markers; the env prefix is `ONZE_PUBLIC_`, matching front 49 |
| 94 | `import {nav, header, main, section, article, h2, form, input, label, button, timeTag} from "jhonstart";` — `repository/jhonstart/modules/jhonstart/src/elements.bp`; a void element (`input`, `img`) renders with no closing tag (`elements.isVoidTag`, called by `render.bp`) |

### Still assumed — reconcile these first

| Front | Assumed shape | Why it is still open |
|---|---|---|
| 30 | `LayoutProps(children: leaf)` is constructible with one named field | `LayoutProps` is jhonstart's record (decision 114); no example there constructs one, and three of this front's tests do |
| 51 · 52 | `Image(props, cfg, publicDir)`, `googleFont(family, opts) -> @Task<Font>`, `fontHead(fonts) -> string` | fronts 51 and 52's own shapes, defined by the same author; nothing external has confirmed them |
| 30 | emilia's block reaches the head, each streamed chunk and the payload's `s` key through the asynchronous `jhonstart-emilia` plugin onze registers (decisions 113, 114) | the layout produces the head string and hands it over; it does not call the plugin, so the seam is cited rather than exercised |
| 12 | `cache.revalidatedPaths()` is a test seam available to an app's own tests | front 12's example uses it, but describes it as a seam rather than public surface |

## Rules two fronts must agree on

- **Route handlers:** front 25's `#[getRoute("api/posts")]` / `#[postRoute("api/posts")]`
  (`route_handler.bp`); `app/api/posts/route.bp` uses them.
- **One form binding** (`contracts.md` § 3, front 24): `data-jh-a="<id>"` plus a hidden action
  field, the action addressed by an HMAC'd id, never by its name. The field and header names are
  passed by onze to both sides — `actionField` / `actionHeader` to jhonstart,
  `rakun.actions.field` / `rakun.actions.header` to rakun — `__bp_action` / `X-Bp-Action` by
  onze's default (decision 114). The function's name appears in neither the attribute nor the URL.
- **One streaming marker** (`contracts.md` § 2): the hole is `<div data-jh-h="h0">` with ordinal
  ids in shell order, never a route-derived id; `boundaryId` is front 30's bookkeeping name, not
  the wire id.
- **Registration is jhonstart's and rakun's, wired by onze:** `#[page]` / `#[layout]` fill
  jhonstart's UI registry; onze's boot copies the records into rakun's route table and hands one
  `PageRenderer` per page through `page(pattern, render)` (decision 114). Nothing in the app
  calls an onze registry.
- **`content/` is not served:** only `public/` is reachable over HTTP; the posts in `content/` are
  read by the server at request time.

## Language gaps

Rows of [`language-gaps.md`](../../language-gaps.md) that bite in this app (the proposed surface is
there):

| Gap | Where it bites in this app |
|---|---|
| The navigation signals do not return `noreturn` (lg2-l) | every `[slug]` page: `if (found.isEmpty()) { val _gone = notFound(); }; val post = found.first().unwrapOr(missingPost(slug));` — the `unwrapOr` default is unreachable (the marker in `blog-slug-page-example.bp`) |
| No assignment to a `self` field (by design) | `Post` is rebuilt rather than updated; the form's state is copied |
| No byte or binary type | `app/api/posts/route.bp` refuses `multipart/form-data` with 415 rather than reading it lossily |
| `@Decl` carries no source location (lg2-q) | the app-relative segment is the decorator's argument (the marker in `app-tree-example.bp`) |

The 1.0.10 table's other rows (parameter defaults, `xs[0]` on the BEAM, tuple labels through
generics, `if (a && b)`, `await` in a loop) are no longer rows of `language-gaps.md`; step 6's
reconcile drops a workaround the examples still carry for one of them.

## Test plan

`examples/blog/test/`, on **both** targets, plus a serving gate that is not a `test` block.

- **In-process tests** (`botopink test`, both targets) cover the pure functions: `lib/db.bp`'s
  parse, list, read and write; `post_card`'s class; the tags' markup; `generateStaticParams`;
  `generateMetadata`'s head; the middleware's decision given a `Request` and a `Chain`; each page
  fn's `Element` given a `PageContext`. These catch vocabulary drift, without a server.
- **The serving gate**: `examples/blog` builds, serves and renders its routes under both `onze
  dev` and `onze build && onze start` — `gate_test.bp` (the dev/start equality property) and
  `examples/blog/test/serve.sh`, which starts each, requests every route of the script and diffs
  against committed bodies with the content hashes masked. Erlang only: that is what serves.
- **The client half**: structurally (the build emits a chunk, it holds `like_button` and not
  `db`, the document references it) and behaviourally in a headless browser driven by `serve.sh`
  (README step 5).

## Definition of done

- [ ] Every file in the acceptance script exists and every row's *Proves* column is a green assertion
- [ ] `onze dev` and `onze build && onze start` both serve every route
- [ ] The *Assumed API shapes* table has been reconciled against each owning front, and every row
      either matches or has been changed here
- [ ] Every `// front NN` comment names a front that exists (a directory under `specs/1.0.12-beta/`)
- [ ] Every `// LANGUAGE GAP` marker in `examples/blog/**` is a row of
      `specs/1.0.12-beta/language-gaps.md` § Marker index (CI check 5, `scripts/language-gap-markers.sh`)
- [ ] The front's tests are green on its assigned target — both, here
