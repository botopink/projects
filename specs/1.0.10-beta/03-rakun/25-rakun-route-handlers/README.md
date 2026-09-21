# Front 25 — Rakun Route Handlers

**Track:** B rakun
**Priority:** high — an application that renders pages but cannot answer `/api/posts` is not an
application; this is also the only path by which a webhook, a health probe or a non-browser client
reaches an `onze` app
**Target:** erlang (server). Nothing here runs in a browser and nothing here declares an
`@External.Node` cell — the exit gate checks that, and this front is the easiest place to break it
**Wave:** 6
**Depends on:** 22 (route table and the `R` registration cell), 06 (scopes), 62 (request context —
`cookies()`, `headers()`, `after()`), 07 (the filter chain a handler runs inside), 23 (the shared
dispatch entry), 30 (the flush primitive streaming reuses), 01 (percent-decoding for form bodies)
**Owns:** `repository/rakun/src/route_handler.bp`, `repository/rakun/test/route_handler_test.bp`
**Does not touch:** `repository/rakun/src/http.bp`, `src/decorators.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen), and the files owned by 22 · 23 · 24. It declares no host cell of its own:
registration goes through front 22's `rkAppRegisterHandler`, which is why this front has no `.erl`
and no `.mjs`
**Reference:** `NEXTJS-DOCS.md § 19. Route Handlers (API)` ·
<https://nextjs.org/docs/app/getting-started/route-handlers-and-middleware> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/route>
**Replaces:** `1.0.7-beta/11-rakun-route-handlers`

---

## Problem

`rakun` can already answer an HTTP request: `#[restController]` on a type, `#[route("/api")]` for a
prefix, `#[getMapping("/users")]` on a method, and the emitted wiring registers the handler
(`repository/rakun/test/server_test.bp:16-66`). That is Spring's model, and it stays. What it cannot
do is live in the `app/` tree next to the pages it belongs with.

The consequence is a split an application feels immediately. A blog's pages come from
`app/blog/[slug]/page.bp` and its JSON API comes from a controller type declared somewhere else
entirely, with its path written out in full in two places and nothing checking that the two agree.
Next.js's answer is that `route.bp` is a sibling of `page.bp`: the same folder tree, the same dynamic
segments, the same params, one route table, and one rule — a segment holds a page or a handler, never
both (`§ 19`).

The second problem is what a handler can actually read and write. `Request.body()` returns the whole
body as one string and `Request.query(name)` returns `""` for anything absent
(`repository/rakun/src/http.bp:35-43`); there is no JSON accessor, no form decoder, no cookie jar, no
header map. `Response` is `(status, body)` with no header list at all
(`repository/rakun/src/http.bp:45-73`), so a handler cannot set `Content-Type`, cannot set a cookie,
and cannot stream. Both files are frozen for this milestone, so this front supplies the missing shapes
in its own file and converts at the boundary.

## Current state

- `repository/rakun/src/decorators.bp:222-244` — `getMapping`/`postMapping`/`putMapping`/
  `patchMapping`/`deleteMapping`, all method-level, all taking a full path. No `head`/`options`
  mapping exists.
- `repository/rakun/src/http.bp:12-20` — `HttpMethod` already enumerates
  `Get, Post, Put, Patch, Delete, Head, Options`. The verb set this front needs is already named.
- `repository/rakun/src/http.bp:35-43` — `Request`: `method`, `path`, `param`, `query`, `header`,
  `body`, all returning `string`.
- `repository/rakun/src/http.bp:45-73` — `Response`: `status` and `body`, six builders, no headers.
- `libs/std/src/json.bp:36-45` — `parse` and `stringify` are both `string -> @Result<string, string>`.
  There is no structured JSON value and no walker, and no front in this milestone delivers one.
- `libs/std/src/querystring.bp` — exists; percent-decoding does not, and front 01 adds it.
- `repository/rakun/src/route_handler.bp` does not exist.

## Mechanism

### What Next.js does

A `route.ts` in a segment exports one function per HTTP method — `GET`, `POST`, `PUT`, `PATCH`,
`DELETE`, `HEAD`, `OPTIONS` — each taking the request and returning a response (`§ 19`). The segment's
dynamic params reach the handler the same way they reach a page. `route.ts` and `page.tsx` may not
coexist in one segment. A handler may return a stream, which is how LLM and event endpoints are
written.

### How it maps onto botopink

**Seven decorators, one per verb, each taking the app-relative segment.** The export-name convention
(`export function GET`) has no botopink analogue: nothing reflects a module's export names, and a
`@Decl` handle carries no source location, so neither the file nor the function name can carry the
information. The verb goes in the marker instead, which also matches the shape rakun already uses for
`#[getMapping]`:

```bp
pub fn getRoute(comptime decl: @Decl, seg: string)
pub fn postRoute(comptime decl: @Decl, seg: string)
pub fn putRoute(comptime decl: @Decl, seg: string)
pub fn patchRoute(comptime decl: @Decl, seg: string)
pub fn deleteRoute(comptime decl: @Decl, seg: string)
pub fn headRoute(comptime decl: @Decl, seg: string)
pub fn optionsRoute(comptime decl: @Decl, seg: string)
```

Each `@emit`s the registration into front 22's table as an `R` record carrying its verb:

```bp
val __rkHandler_listPosts = rkAppRegisterHandler("GET", "api/posts", listPosts);
```

`rkAppRegisterHandler` is declared in front 22's `file_router.bp`, generic over the response type the
way `rkRegisterRoute<Req>` is generic over the request type (`repository/rakun/src/runtime.bp:76-81`),
so front 22 does not have to know this front's types and this front does not have to declare a host
cell. That is what keeps this front pure server code with nothing to exempt from the target rule.

**Reading the request.** Free functions over rakun's `Request`, named so they do not collide with
`jhonstart`'s `text`:

```bp
pub fn bodyText(req: Request) -> string
pub fn bodyForm(req: Request) -> Dict<string, string>
#[@result]
pub fn bodyJson(req: Request) -> @Result<string, string>
pub fn queryAll(req: Request) -> Dict<string, string>
```

`bodyJson` validates through `std/json` and returns the **raw text**, not a structured value, because
`std/json` is `string -> @Result<string, string>` with no walker (`libs/std/src/json.bp:36`). A handler
that needs fields reads them with `regex` or hands the text to a typed decoder its own application
supplies. This is a real limitation and it is written down rather than papered over; a JSON walker is
std's to own and nothing in this milestone delivers one.

`bodyForm` decodes `application/x-www-form-urlencoded` with `querystring` plus front 01's
percent-decode. `multipart/form-data` is refused with 415, for the same reason front 24 refuses it:
botopink has no byte type, every `#[@external]` cell marshals through `string`, and a multipart body
read as UTF-8 is a corrupted upload rather than an upload.

**The phase word.** A handler runs with front 62's `setPhase(RequestPhase.Handler)` entered before it
and the previous phase restored after. It is the same word front 12's `rkCachePhase()` reads, so a
handler that revalidates without it raises; it is also what makes `cookies().set(...)` legal here and
what lets a handler mark its render dynamic (`contracts.md § 5`).

Cookies and headers are **not** re-implemented here. `cookies()` and `headers()` come from front 62,
bound to the in-flight request; a handler is one of the two places where `cookies().set(...)` is legal
(the other is a server action). This front adds no request-scope mechanism of its own.

**Writing the response.**

```bp
pub type HandlerResponse(
    status: i32,
    headers: Array<#(string, string)>,
    chunks: string[],
) {
    pub fn json(body: string) -> HandlerResponse
    pub fn text(body: string) -> HandlerResponse
    pub fn created(body: string) -> HandlerResponse
    pub fn noContent() -> HandlerResponse
    pub fn notFound() -> HandlerResponse
    pub fn badRequest(message: string) -> HandlerResponse
    pub fn unsupportedMedia(message: string) -> HandlerResponse
    pub fn withHeader(self: Self, name: string, value: string) -> HandlerResponse
}

pub fn toResponse(h: HandlerResponse) -> Response
```

`withHeader` returns a new record; nothing here mutates a `self` field, because assigning to one is
not a thing botopink does and no library in the checkout tries. `json` sets
`Content-Type: application/json`, `text` sets `text/plain; charset=utf-8`, `noContent` is 204 with no
chunks. `toResponse` joins the chunks and exists only so the frozen transport can carry a
single-chunk answer; the streaming path never calls it.

**Streaming.** `§ 19` writes streaming endpoints as the normal shape for anything incremental. The
response carries an ordered chunk list, and the same constraint front 23 works under applies here:
`@Future<T>` lowers eagerly on erlang (`libs/std/src/http.bp:16-18`), so a list of futures is a list
of values that have already been computed and streaming them buys nothing. The source is therefore a
list of **unstarted thunks**, driven by the same flush primitive front 30 uses:

```bp
pub fn streamed(status: i32, tasks: Array<fn() -> @Future<string>>) -> HandlerResponse
```

The transport (front 04) writes each chunk as its thunk completes, in index order, with
`Transfer-Encoding: chunked`. A handler that wants one chunk per row of a query builds one thunk per
row. What it cannot stream is bytes: there is no binary type, so a file download or an image endpoint
is not expressible and is marked as a gap rather than faked with a lossy string.

**Coexistence with pages.** A segment holding both `page.bp` and `route.bp` is a scan error naming
the segment (front 22, step 5). The verb decorators additionally refuse a second registration of the
same verb at the same segment, at module load, naming both functions — `route.bp` exporting `GET`
twice is a typo, not a merge.

**`OPTIONS` and CORS.** `§ 19. CORS` writes the headers by hand in the handler. Here the preflight is
front 07's: the filter chain answers `OPTIONS` before a handler is reached unless the segment
registered an explicit `#[optionsRoute]`, in which case the explicit one wins. This front documents
that precedence and tests it; it does not implement a second CORS policy.

## Steps

### Step 1 — The seven verb decorators

**Acceptance:**
- [ ] `#[getRoute("api/posts")]` on a `#[@future] fn(req: Request) -> @Future<HandlerResponse>`
      compiles and adds `R|/api/posts||GET` to front 22's table.
- [ ] Each of the seven verbs registers with its own verb string, and the set matches
      `HttpMethod` (`repository/rakun/src/http.bp:12-20`) exactly — no eighth verb, no missing one.
- [ ] A verb decorator on a type fails with a message naming the decorator and `function`.
- [ ] A handler that is not `#[@future]` fails, naming the required return type.
- [ ] Registering the same verb twice at one segment fails at module load, naming both functions.
- [ ] `#[getRoute("blog/[slug]")]` binds `slug` through `req.param("slug")`, using front 22's matcher
      and not a second path parser.

### Step 2 — Reading the request

**Acceptance:**
- [ ] `bodyText` returns the body verbatim, including an empty body as `""`.
- [ ] `bodyForm("a=1&b=two+words")` yields `a -> "1"`, `b -> "two words"`; a percent-encoded `%26`
      does not split a field.
- [ ] `bodyJson` on malformed input is `Error`, and the handler that ignores the error returns 400
      rather than 500 — asserted, because the default when nobody looks is 500.
- [ ] `bodyJson` on valid input returns the raw text, and the test says so in its name, so nobody
      later assumes it returns a structure.
- [ ] `Content-Type: multipart/form-data` gives 415 before the body is read.
- [ ] `cookies()` and `headers()` inside a handler come from front 62 and see the in-flight request;
      `cookies().set(...)` inside a handler is legal and its value reaches the response.
- [ ] `setPhase(RequestPhase.Handler)` is entered before the handler body and the previous phase is
      restored after. Removing the call makes a revalidation from a handler raise, and that negative
      case is the test.

### Step 3 — Writing the response

**Acceptance:**
- [ ] `HandlerResponse.json("{}")` is 200 with `Content-Type: application/json`.
- [ ] `HandlerResponse.noContent()` is 204 with no chunks and no `Content-Type`.
- [ ] `withHeader` returns a new value and leaves the original unchanged — asserted on both.
- [ ] A header name that repeats is emitted twice rather than replacing, because `Set-Cookie` needs
      that.
- [ ] `toResponse` joins chunks in order and sets the status; it is not called on the streaming path.

### Step 4 — Streaming

**Acceptance:**
- [ ] `streamed(200, tasks)` produces one chunk per thunk, in index order, regardless of completion
      order.
- [ ] The response carries `Transfer-Encoding: chunked` and no `Content-Length`.
- [ ] Three 50 ms thunks complete in well under 150 ms on `--target erlang`, which is the assertion
      that the thunks were spawned rather than awaited in sequence. The variant written over
      already-started `@Future` values is kept as a failing regression case.
- [ ] A thunk that throws ends the stream and the already-written chunks stand; the status cannot be
      changed after the first chunk, and the test says what the client sees.

### Step 5 — Coexistence, precedence and the method-not-allowed answer

**Acceptance:**
- [ ] `page.bp` and `route.bp` in one segment is a scan error naming the segment (the error text is
      front 22's; this front asserts the handler side registered nothing).
- [ ] A segment with a `GET` handler and no `POST` answers `POST` with 405 and an `Allow` header
      listing exactly the registered verbs.
- [ ] `HEAD` falls back to the `GET` handler with the body dropped when no `#[headRoute]` is
      registered.
- [ ] `OPTIONS` is answered by front 07's chain unless an `#[optionsRoute]` is registered for the
      segment, in which case the explicit handler runs and the chain does not.
- [ ] A handler runs inside front 07's filter chain, so a filter that rejects the request means the
      handler is never entered — asserted by a handler that records having run.

## Examples

- [`examples/route-handler-example.bp`](./examples/route-handler-example.bp) — an
  `app/api/posts/route.bp` with a `GET` that lists and a `POST` that creates, plus a streaming export
  endpoint. Shows the dynamic-segment param, the JSON limitation, and the 405 the segment gives to a
  verb it does not register.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| No byte or binary type — every host cell marshals through `string` | a file download, an image endpoint, a `multipart/form-data` upload | text responses only; binary bodies are refused (415 in, unsupported out) rather than corrupted | a `bytes` type and `@External` cells that marshal a binary |
| `@Future<T>` lowers eagerly on erlang (stated in full in front 23), so streaming cannot be driven by a list of futures | `streamed` | the source is `Array<fn() -> @Future<string>>`, spawned per thunk by front 30's flush primitive | a scheduler behind `@Future` on erlang, or an explicit `@Task<T>` |
| Declared parameter defaults are never applied | every builder call that would otherwise take an optional header list | pass every argument explicitly | apply declared defaults at call sites |

## Blocked

- `repository/rakun/src/http.bp` is frozen. `Response` has no header list and no chunked body, so
  `HandlerResponse` lives in this front's file and `toResponse` converts. When `http.bp` unfreezes,
  `HandlerResponse` should replace `Response` rather than sit beside it — two response types is a
  cost this milestone accepts and 1.0.10-beta should pay off.
- `std/json` has no structured value and no walker, so `bodyJson` can only validate. This is not this
  front's to fix and no front in the milestone owns it; it should be a 1.0.10-beta std front.

## Test plan

`repository/rakun/test/route_handler_test.bp`, run by `botopink test --target erlang` from
`repository/rakun/` and by `zig build test-libs -- --target erlang --lib rakun`. This is a server
front: the commonJS row is not a coverage target and the front declares nothing that would build for
it. What that costs is stated plainly — nothing in this front is exercised in a browser, because
nothing in this front runs in one.

Registration, request reading, response building, streaming order and the 405/`Allow` answer are
runtime asserts. The two compile-time rules — `page.bp` with `route.bp`, and a duplicate verb at one
segment — are module-load and scan failures and cannot be written as a runtime `assert`; they are
asserted from the CLI suite (front 50) and from front 22's scan, following the precedent in
`repository/rakun/test/di_test.bp:14-16`.

## Definition of done

- Seven verb decorators, one registration path, and no host cell declared in this front's file.
- No `@External.Node` cell anywhere in `route_handler.bp` — the exit gate's target check passes for
  this front by construction, not by review.
- `HandlerResponse` and the `bodyText`/`bodyForm`/`bodyJson` trio are the shapes fronts 30, 50 and 53
  build on, cited rather than re-derived.
- `repository/rakun/AGENTS.md` names `route_handler.bp`, the verb set and the `page`/`route`
  exclusivity rule.
- The front's tests are green on its assigned target — here, erlang.

## Carried from 1.0.7-beta F11 rakun-route-handlers

Source: `specs/1.0.7-beta/11-rakun-route-handlers/README.md` and `specs/1.0.7-beta/examples-bp.md § F11`.
Items below are absent from the 1.0.9 text above; items the merge already covers elsewhere are listed
at the end with the front that holds them.

### Reference rows

| 1.0.7 reference | 1.0.9 status |
|---|---|
| `[Route Handlers](https://nextjs.org/docs/app/getting-started/route-handlers)` (header, line 3) | 25 cites the renamed page `getting-started/route-handlers-and-middleware`; same content |

### Requirements and API names (quoted)

| # | 1.0.7 item | Where in 1.0.7 | Note |
|---|---|---|---|
| 1 | Export-name convention: "Exports `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS` functions · Each receives `Request` and returns `Response`" — `#[@future] pub fn GET(request: Request) -> @Future<Response>` | Step 1, Mechanism | superseded by: 25 § Seven decorators ("The export-name convention (`export function GET`) has no botopink analogue … The verb goes in the marker instead") |
| 2 | "File router (F14) detects `route.bp` files and registers them" — `pub fn scanRouteHandlers(appDir: string) { // Find all route.bp files // Register each with the appropriate HTTP method }` in `file_router.bp`; acceptance "`route.bp` files are detected · HTTP methods are registered" | Steps 1–2 | superseded by: 22 § Problem (registration-driven; no runtime load by path) and 25 § Seven decorators (`rkAppRegisterHandler("GET", "api/posts", listPosts)`) |
| 3 | `Response.json(posts)` / `Response.created(post)` with a non-string argument; `Response.json(json.stringify(posts))` over an array | Mechanism, examples | 25 § Writing the response: `HandlerResponse.json(body: string)`; `std/json.stringify` is `string -> @Result<string, string>` (25 § Current state), so `json.stringify(posts)` over a record array has no 1.0.9 spelling |
| 4 | `val body = await request.json();` — a JSON accessor on `Request` | Mechanism, examples | 25 § Reading the request: free fn `bodyJson(req) -> @Result<string, string>` returning the raw text |
| 5 | Acceptance: "Route handlers can return JSON, text, redirects" | Step 3 | JSON/text → 25 Step 3; redirect from a handler → 63 § Where a signal becomes a response ("a route handler | the same status codes, with no boundary rendering"). `HandlerResponse` itself has no redirect builder |
| 6 | Acceptance: "Route handlers can access request params, query, headers, body" | Step 3 | params/body → 25 Step 2; headers → 62 `headers()`; `queryAll(req)` → 25 § Reading the request |
| 7 | Test: `test "route.bp files are detected" { // Mock file system with route.bp // Verify handlers are registered }` | Step 5 | superseded by: 25 § Test plan (registration is a module-load fact; scan failures live in the CLI suite, front 50) |
| 8 | Gate: "Commit on `fix/rakun-route-handlers`" | Gate | Branch-naming convention; 1.0.9 fronts name no branch |
| 9 | Blast radius: "File router updated to detect `route.bp` files" | Blast radius | Not carried; see row 2 |

### Example material (quoted from `examples-bp.md § F11`)

Carried verbatim to [`examples/verb-exports-carried-example.bp`](./examples/verb-exports-carried-example.bp). The `GET` list / `POST` create / dynamic `[id]` GET are covered by [`examples/route-handler-example.bp`](./examples/route-handler-example.bp) in the 1.0.9 shape; the `DELETE` handler (`return Response(status: 204, body: "");` → 25's `HandlerResponse.noContent()`) has no 1.0.9 example and is the reason the file exists. The verb-as-export-name spelling is marked as a language gap in the file (no export-name reflection, no `@Decl` source location — 25 § Seven decorators, 22 § Language gaps).

### Covered elsewhere (not carried)

- "Coexists with `page.bp` in the same segment (but not at the same level)" / "A route segment can have either `page.bp` OR `route.bp`, not both" / "Clear error if both exist" → 22 Step 5, 25 Step 5.
- Tree `app/blog/page.bp → HTML · app/api/posts/route.bp → JSON` → 22 examples header, 25 example header.
- "Route handlers are the file-based equivalent of `#[restController]`. They coexist with controllers — you can use either pattern." → 25 § Problem ("That is Spring's model, and it stays").
- "Route handlers are async because they may need to fetch data." → 25 Step 1 ("A handler that is not `#[@future]` fails").
- `Response.notFound()` on a missing param → 25 example `showPost`.
