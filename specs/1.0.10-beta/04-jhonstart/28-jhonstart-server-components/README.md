# Front 28 — Jhonstart Server Components

**Track:** C jhonstart
**Priority:** critical — this is the front the whole server/client split exists for; without it every component is a client component and the BEAM render has nothing to render
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 26 · 01 (escaping) · 23 (payload envelope, read-only) · 62 (request context, read-only) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/server.bp` (promoted from `server.d.bp`), `repository/jhonstart/test/server_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (front 26), `src/link.bp` (front 27), `src/client.bp` (front 29), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` · `§ 9. Busca de Dados (Fetching)` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/getting-started/server-and-client-components · https://nextjs.org/docs/app/getting-started/fetching-data
**Replaces:** `1.0.7-beta/04-jhonstart-server-components`

---

## Problem

Every component jhonstart can express today is synchronous. `renderToString(e: Element) -> string`
walks a finished tree (`element.bp:55-67`); there is no point at which a component can say "wait, I
am fetching the post". A page that needs a database row has to be handed the row by someone else,
which means the data layer and the component tree cannot be written in the same file — the thing
server components exist to fix.

`src/server.d.bp` is where the answer was supposed to live and it is 26 lines of declaration. Its
header lists three blockers (`server.d.bp:9-17`): `request()` is host-bound, "the async SSR data
layer … is gated on the effect-await surface", and `Http` is "a phantom `@Context` base (no
members)". The first has a producer now — front 62 owns request scope on the BEAM. The second is
closed: `#[@future] fn … -> @Future<T>` with `await` is landed and in production use
(`repository/emilia/src/emilia.bp:62-65`). The third never worked and this front drops it; see
*Language gaps*.

The third problem is the one that bites hardest in practice. Next.js pages read `params` as a
promise and destructure it (`NEXTJS-DOCS.md § 6`); jhonstart's route params arrive as
`Array<#(string, string)>` from front 26's snapshot, and there is no shared vocabulary for "the
value of `slug`, or `""`" anywhere in the tree except rakun's own `Request.param`
(`repository/rakun/src/http.bp:38`). A server component front that does not settle that spelling
leaves every page inventing it.

## Current state

- `src/server.d.bp` — `behavior Request` with three bodyless methods (`:19-23`), `request()` behind
  `#[@External.Node("jhonstart/runtime", "request")]` (`:25-26`). Node-only, which a server front
  may not carry.
- `src/root.bp:15-17` — `server` is not a declared module; `.d.bp` files are not resolved by `mod`.
- `repository/jhonstart/examples/jhonstart-app/app/posts/[id]/page.bp` is the intended shape and is
  headed "⛔ GATED / ASPIRATIONAL EXAMPLE — does not build yet". It calls `use request()`,
  `req.params().get("id").unwrapOr("0")` and `resp.json()` — none of which exist.
- `#[@future]` works and is mandatory: `#[@result]` without `-> @Result<…>` is a located error
  (`tests/language/reject/result_without_wrapper.bp`), and the inverse is rejected too.
- `await` works directly inside a `test` block (`repository/emilia/src/emilia.bp:475-480`), which is
  what makes this front testable at all.
- `libs/std/src/http.bp:16-18` — "Erlang is eager: `@Future<T>` resolves to `T` … so the caller's
  `await fetch(url)` is identity on that backend." There is no concurrent scheduler behind `@Future`
  on the BEAM.
- `libs/std/src/` has nineteen modules today and **no HTML escaping** among them. `escape.html` and
  `escape.attribute` are front 01's, new.

## Mechanism

A Next.js Server Component is an `async function` that returns JSX; it runs once, on the server, and
never ships to the browser (`NEXTJS-DOCS.md § 7`). jhonstart's equivalent is exact and needs no new
language surface:

```
async function Page() { … }        →    #[@future] pub fn Page(…) -> @Future<Element>
await getPost(slug)                →    await loadPost(slug)
```

`#[@future]` is not optional decoration — the annotation and the `@Future<…>` wrapper go together or
the compiler rejects the declaration. This front's contribution is not the syntax, it is the five
things around it.

### 0. `@Future` is eager on erlang, and that changes the port

This is the fact that most easily makes a server-component spec wrong. On the erlang backend a
`@Future<T>` is not a handle to work in progress: `libs/std/src/http.bp:16-18` states it outright —
"Erlang is eager: `@Future<T>` resolves to `T` in the eager-lowering arm documented in
`codegen/erlang.zig`, so the caller's `await fetch(url)` is identity on that backend."

The consequence is blunt. Two `#[@future]` server components do **not** load their data in parallel
because they are futures. They run one after the other, in the order the enclosing body reaches
them, and the page costs the sum of its loaders. The Next.js pattern this front ports assumes the
opposite, so porting it shape-for-shape and stopping there would produce a page that is slower than
the synchronous version and a spec that never says why.

Parallel loading on the BEAM is a spawned process per unit of work, gathered by index. **Front 02
provides that**, and it takes **unstarted tasks** — `Array<fn() -> @Future<T>>` — not futures that
have already run. A page with independent loaders hands front 02 a list of thunks; a page with
dependent loaders awaits in sequence and pays for it knowingly. This front provides neither
mechanism and defers to front 02 by name, in the README and in every example that has more than one
loader.

### 1. `RequestData` — the request as a record

One record, six fields, every plural field an `Array<#(string, string)>`. That is the same shape
front 26's snapshot uses, the same shape `querystring.parse` produces
(`libs/std/src/querystring.bp:35`), and the same shape `Element.attrs` uses — so a value read off
the request can be handed straight to an attribute without a conversion. No `Dict`: naming
`dict.Dict<string, string>` as a type across a module boundary is unexercised anywhere in the tree,
and the pair list is what actually crosses the wire.

### 2. Accessors that cannot fail

`param`, `query`, `header` and `cookie` return a plain `string`, `""` when absent. This is not
laziness; it is the ecosystem's decided shape — rakun's `Request` does exactly this and says so
(`repository/rakun/src/http.bp:30-34`). An optional would force `.unwrapOr` at every call site in
every page, and `?T` handling is the single most common place the old spec examples went wrong.

### 3. Request scope comes from front 62, not from here

`cookies()`, `headers()`, `after()`, `connection()`, `draftMode()` and per-request memoization are
**front 62**'s (`rakun-request-context`). This front does not declare a parallel set. `server.bp`
binds to front 62's erlang module by name:

```bp
#[@External.Erlang("rakun_request_context", "cookies")]
declare fn __jhCookies() -> string;
```

The encoding is front 62's and is the same `k=v&k=v` string front 26 uses, decoded by
`querystring.parse`. If front 62 changes the module name or the encoding, this file changes and
nothing else in jhonstart does — which is the point of keeping it to five `declare fn` lines.

### 4. The loader convention

A loader is an ordinary `#[@future] fn` returning `@Future<T>` for a `T` the component can render.
It is awaited in the component body, at statement level, never inside a closure — a closure body
whose last statement is an `await` is not a form any file in the tree uses, and the lambda rule
(`§2.38`: a lambda's last statement must be an implicit-return expression) makes it a poor bet.
Components that need N rows await a loader that returns `Array<T>` and then map synchronously.

### 5. Escaping is not optional and is not ours

`renderToString` writes `e.value` straight into the output (`element.bp:56`) and every attribute
value straight into a quoted pair (`element.bp:63-65`). Neither escapes. A server component renders
attacker-influenced text — a post body, a comment, a search term echoed back — so every such value
goes through **front 01**'s `escape.html` for text and `escape.attribute` for attribute values.
std has no escaping today; front 01 adds both in pure botopink. This front hand-rolls neither, and
its examples call them at the point the untrusted value enters the tree.

### What crosses to the client

Nothing from this file. A server component's output is markup; front 23 serializes the `__onze`
payload (`contracts.md § 2`) and front 29 turns the client subtrees into islands. The one thing this
front owes the boundary is that `RequestData` never appears in the payload's `i` array: a value read
from a header or a cookie must not be reachable from an island's props, and the check that it is not
is front 68's build-time graph walk.

The payload is front 23's to build and to escape — this front neither serializes nor escapes it, and
the only escaping it performs is front 01's on values it renders into markup.

## Steps

### Step 1 — `RequestData` and its accessors

```bp
// src/server.bp
import {Element} from "element";
import {pairValue} from "router";     // provided by front 26
import {querystring} from "std";

pub type RequestData(
    method: string,
    path: string,
    params: Array<#(string, string)>,
    query: Array<#(string, string)>,
    headers: Array<#(string, string)>,
    cookies: Array<#(string, string)>,
) {
    pub fn param(self: Self, name: string) -> string {
        return pairValue(self.params, name);
    }

    pub fn queryParam(self: Self, name: string) -> string {
        return pairValue(self.query, name);
    }

    pub fn header(self: Self, name: string) -> string {
        return pairValue(self.headers, name);
    }

    pub fn cookie(self: Self, name: string) -> string {
        return pairValue(self.cookies, name);
    }
}
```

`pairValue` is **front 26's** (`router.bp`) and is imported, not redefined — one pair-list decoder in
the package, so "the value of `slug`, or the empty string" cannot mean two different things about a
duplicated key.

**Acceptance:**
- [ ] each accessor returns `""` for an absent key and never raises
- [ ] `pairValue` is imported from front 26's `router` module; this file defines no decoder of its own
- [ ] no field of `RequestData` shares a name with one of its methods
- [ ] `RequestData` is constructible in a test with no host present
- [ ] the body is the empty string nowhere: there is no `body` field, because a render never reads
      one — form bodies are front 24's and route-handler bodies are front 25's

### Step 2 — Binding front 62's request context

> **Amended 2026-09-21, on landing (jhonstart `6d6c007`).** The six cells below are **not writable
> as spelled**, in either direction, and both halves were measured rather than assumed:
>
> - an `#[@External.Erlang(…)]` cell with no `#[@External.Node]` sibling reds the **commonJS
>   compile** at the wrapper's call site — `` `__jhMethod` has no `#[@External.<Target>(…)]` for the
>   node backend `` — so one erlang-only accessor takes the whole member off the commonJS row even
>   though nothing there calls it;
> - and on erlang the cells resolve, then die `{error, undef}` at run time, because nothing named
>   `rakun_request_context` is on the BEAM: rakun's module is not jhonstart's to load.
>
> What landed instead is front 26's precedent exactly: **dual-target cells against jhonstart's own**
> `jhonstart_server` / `./server_runtime.mjs`, both halves shipped, with `fillRequest` as the single
> `pub` writer that front 62's dispatcher calls once per request. That keeps the seam where
> `02-packaging` puts it — the app names the framework, never the reverse — and if front 62 would
> rather own the module atom, it is one line per accessor in `server.bp`.
>
> The three acceptance bullets naming `rakun_request_context` are amended with it. The compile-time
> refusal itself is right under decision 67 and is recorded as a compiler row in `status.md`: the
> open question there is whether the refusal can be owed by the **reachable call** rather than by
> the declaration's presence.
>
> `querystring.parse` below is **front 26's `decodePairs`** in the landed file. `std/querystring` is
> dead on the erlang row (`querystring.bp:22` emits a bare `slice/3` it never defines, `erlc`
> refuses the module and the runner skips it silently — worktree `.tasks/std-slice-shim`), and this
> front's gate is erlang. That also satisfies this track's own "one pair-list decoder in the
> package" principle, so it stands whether or not std is fixed.

```bp
#[@External.Erlang("rakun_request_context", "method")]
declare fn __jhMethod() -> string;

#[@External.Erlang("rakun_request_context", "path")]
declare fn __jhPath() -> string;

#[@External.Erlang("rakun_request_context", "params")]
declare fn __jhParams() -> string;

#[@External.Erlang("rakun_request_context", "query")]
declare fn __jhQuery() -> string;

#[@External.Erlang("rakun_request_context", "headers")]
declare fn __jhHeaders() -> string;

#[@External.Erlang("rakun_request_context", "cookies")]
declare fn __jhCookies() -> string;

pub fn request() -> RequestData {
    return RequestData(
        method: __jhMethod(),
        path: __jhPath(),
        params: querystring.parse(__jhParams()),
        query: querystring.parse(__jhQuery()),
        headers: querystring.parse(__jhHeaders()),
        cookies: querystring.parse(__jhCookies()),
    );
}

pub fn cookies() -> Array<#(string, string)> {
    return querystring.parse(__jhCookies());
}

pub fn headers() -> Array<#(string, string)> {
    return querystring.parse(__jhHeaders());
}
```

`request()` is a plain function, not a hook, until front 19 step 2 lands. See *Language gaps* for
what it becomes then (a `@Context<Element, Request>` hook activated inside the `#[@future]` body).

**Acceptance:**
- [ ] every cell is `#[@External.Erlang]`; there is no `#[@External.Node]` cell in the file
- [ ] every cell names front 62's erlang module, and the module name appears in exactly one place
      per accessor
- [ ] `cookies()` and `headers()` are the only two re-exported shortcuts; `after`, `connection`,
      `draftMode` and memoization are called from front 62 directly and are not re-declared here
- [ ] `request()` over a stubbed context reconstructs the six fields

### Step 3 — The server-component convention

A server component is a `#[@future] pub fn` taking its route params and returning `@Future<Element>`.
`server.bp` ships no decorator for it: the marker is `#[@future]`, which the language already
enforces, and a second marker would be a second thing to get wrong.

```bp
#[@future]
pub fn renderServerComponent(component: fn() -> @Future<Element>) -> @Future<string> {
    val tree = await component();
    return renderToString(tree);
}
```

**Acceptance:**
- [ ] a `#[@future] fn … -> @Future<Element>` that awaits a loader compiles on erlang
- [ ] omitting `#[@future]` is a compile error, and the test suite records the expected message
- [ ] `renderServerComponent` awaits exactly once and renders synchronously afterwards
- [ ] a component that awaits two loaders in sequence compiles and both awaits are at statement
      level, not inside a closure

### Step 4 — The loader convention

A loader is `#[@future] fn name(args) -> @Future<T>`. `server.bp` ships **no** loader machinery:
`libs/std/src/http.bp:55` already has `fetch(url) -> @Future<Response>`, a database loader is front
08's, and parallel awaiting (`all`, `race`, `allSettled`) is front 02's. What this front owns is the
rule about where an `await` may stand.

Every `await` is at statement level in the component or loader body. It is never the last statement
of a lambda: a lambda's last statement must be an implicit-return expression, and no file in the
tree awaits inside one. So a component that needs N rows awaits **one** loader returning
`Array<T>` and maps synchronously afterwards — not N awaits inside a `map`.

```bp
#[@future]
fn loadPost(slug: string) -> @Future<Post> { … }

#[@future]
pub fn PostPage(params: Array<#(string, string)>) -> @Future<Element> {
    val post = await loadPost(pairValue(params, "slug"));
    val comments = await loadComments(post.id);
    return article([ … comments.map({ c -> commentRow(c) }) … ], attrs: []);
}
```

Two sequential awaits cost two round trips, and on erlang they cost them even when the results are
independent, because `@Future` there is eager. When the loaders are independent the fix is front
02's spawn-and-gather over **unstarted tasks** — `[{ -> loadPost(slug) }, { -> loadSidebar() }]` —
not a `map` over futures, which would simply run them in order. This front's doc says so and does
not provide a second answer.

**Acceptance:**
- [ ] the convention is written in `repository/jhonstart/docs.md` with the rule about lambdas
- [ ] the test suite contains a component with two sequential awaits at statement level
- [ ] `server.bp` exports no `awaitAll`-style helper, and the README says front 02 owns that
- [ ] the doc names the erlang eager-`@Future` fact and cites `libs/std/src/http.bp:16-18`

### Step 5 — Module promotion

Delete `server.d.bp`. front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod server;`, and `server.bp` in place of
`server.d.bp` in `files`. The `Http` phantom context base and the `Request` behavior do not come
along.

**Acceptance:**
- [ ] `server.d.bp` is gone; `git grep -n "server.d.bp"` finds nothing outside the changelog
- [ ] `pub mod server;` and the `files` swap are handed to front 94; this front edits neither file
- [ ] `repository/jhonstart/AGENTS.md` records the promotion and the dropped `Http` base

## Examples

- [`examples/blog-post-page-example.bp`](./examples/blog-post-page-example.bp) — the `/blog/[slug]`
  page: two loaders awaited in sequence, then a synchronous render.
- [`examples/request-scope-example.bp`](./examples/request-scope-example.bp) — a greeting that reads
  a cookie and a header, and the same page rendered from an explicit `RequestData` so it is testable
  without a host.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A server component returns `@Future<Element>`, and the compiler does not yet look through `@Future<T>` for the context owner, so `use request()` cannot be written — the reason `server.d.bp` stayed gated | `request()`, `cookies()`, `headers()` in `server.bp` | plain functions over the BEAM process dictionary | **decided, unwritten**: [`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md) step 2 — decision 89 unwraps `@Future<T>` to `T`'s owner, decision 90 lets the wrapper effect activate on its own, so `#[@future] fn Page() -> @Future<Element>` writes `use request()` with no second annotation and `request()` is re-declared `-> @Context<Element, Request>` |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []`, inner `text(…)` included | write every argument | apply the declared default when an argument is omitted |
| `xs[0]` silently drops the index on the beam backend (`tests/language/expected-failures.txt`) | reading the first row of a loader's result | `.at(0).unwrapOr(default)` | make the index expression lower correctly on beam, or reject it there |

## Test plan

`repository/jhonstart/test/server_test.bp`, run by `botopink test --target erlang` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`.

Assertions:

1. `RequestData` construction and each of the four accessors, present and absent.
2. Each accessor over an empty list, a single pair, and a duplicated key — `pairValue` itself is
   front 26's and is tested there, not re-tested here.
3. `request()` over a stubbed `rakun_request_context` module: six strings in, the record out.
4. A `#[@future]` component that awaits a stub loader and renders — `await` works directly in a
   `test` block, so this runs without a host render loop.
5. A component with two sequential awaits at statement level.

The `commonJS` row is not this front's gate and this file must not pass it by accident: the six
cells have no Node body, so a js run of `request()` is expected to fail at the first cell. The test
file guards that by keeping every host-touching assertion in tests that are only meaningful on
erlang, and by making every other assertion construct its `RequestData` explicitly.

## Definition of done

- [ ] `server.d.bp` removed, `server.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [ ] `RequestData`, four accessors, `request`, `cookies`, `headers` all `pub` and tested
- [ ] no `#[@External.Node]` cell in the file
- [ ] the six cell names and the `k=v&k=v` encoding are agreed with front 62 and written down in
      `repository/jhonstart/docs.md`
- [ ] the `Http` phantom base and the `Request` behavior are gone, and `AGENTS.md` says why
- [ ] every untrusted value in an example passes through front 01's `escape.html` /
      `escape.attribute`; this front hand-rolls no escaping
- [ ] the erlang eager-`@Future` fact is stated in the README and in `repository/jhonstart/docs.md`,
      and every multi-loader example routes through front 02's unstarted-task list
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F04 jhonstart-server-components

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### History note on the effect-await gap

`1.0.7-beta/04-jhonstart-server-components/README.md § Problem`

> The `#[@future]` annotation itself landed in v0.beta.12, but the `use-await-prefix` / `async-generators` gap for awaiting data in components is partially closed.

Above: *Current state* records the gap as closed (`#[@future]` mandatory, `await` works in fn and `test` bodies); the version tag and the two gap names are kept here only.

### Request provider — F09 rakun-ssr-pipeline (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Current state`, `§ Notes`

> The SSR pipeline (F09 in rakun) will provide the actual Request object.
> The actual HTTP request lifecycle (receiving requests, setting context) is rakun's job (F09).

Decided differently: request scope is **front 62** (`rakun-request-context`) via the BEAM process dictionary; the SSR pipeline is front 23 and only carries the payload envelope. See *Mechanism § 3*.

### `RequestData` as a `Request` behavior implementation over `Dict` (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Mechanism`, `§ Step 1 — Concrete RequestData type`

> Promote `server.d.bp` → `server.bp`:
> - `Request` behavior gets a concrete type `RequestData` (carries path, params, query, headers, body)
> - `request()` returns `@Context<Http, Request>` backed by a host cell
> - Server components are `#[@future] fn(…) -> @Future<Element>` — they can `await` data fetching
> - The host runtime (rakun SSR) sets the request context before rendering

```bp
// src/server.bp
import {Element} from "element";

pub type RequestData(
    path: string,
    params: Dict<string, string>,
    query: Dict<string, string>,
    headers: Dict<string, string>,
    body: string,
    method: string,
) implement Request

pub fn path(self: Self) -> string { return self.path; }
pub fn params(self: Self) -> Dict<string, string> { return self.params; }
pub fn query(self: Self) -> Dict<string, string> { return self.query; }
```

Old acceptance:
- `RequestData` implements `Request` behavior
- All methods have real bodies

| Old | 1.0.9 decision (above) |
|---|---|
| `implement Request` behavior | `Request` behavior and `Http` phantom base dropped (*Step 5*, *Definition of done*) |
| `Dict<string, string>` plural fields | `Array<#(string, string)>` — one pair-list shape shared with front 26, `querystring.parse` and `Element.attrs` (*Mechanism § 1*) |
| `body: string` field | no `body` field — form bodies are front 24's, route-handler bodies front 25's (*Step 1* acceptance) |
| no `cookies` field | `cookies: Array<#(string, string)>` |
| whole-collection accessors `params()`, `query()`, method `path()` shadowing field `path` | by-name accessors `param`, `queryParam`, `header`, `cookie` returning `""` when absent; no field shares a name with a method (*Mechanism § 2*, *Step 1*) |

### `request()` as a `@Context<Http, Request>` hook with dual host cells (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Step 2 — request() hook`

```bp
#[@External.Node("onze13/runtime", "getRequest")]
#[@External.Erlang("onze13_runtime", "get_request")]
declare fn getRequest() -> RequestData;

pub fn request() -> @Context<Http, Request> {
    return getRequest();
}
```

Old acceptance:
- `request()` returns request data from host cell
- Host cells declared for both targets

| Old | 1.0.9 decision (above) |
|---|---|
| one cell `getRequest` returning the record | six string cells (`method`, `path`, `params`, `query`, `headers`, `cookies`) decoded with `querystring.parse` (*Step 2*) |
| `#[@External.Node("onze13/runtime", …)]` + `#[@External.Erlang("onze13_runtime", …)]` | `#[@External.Erlang("rakun_request_context", …)]` only; no Node cell in the file |
| `request() -> @Context<Http, Request>`, consumed as `use request()` | `request() -> RequestData`, a plain function until front 19 step 2 lands decisions 89 and 90; then `request() -> @Context<Element, Request>`, activated as `use request()` inside the `#[@future]` body itself (*Language gaps*, row 1) |

### Old inline examples — `.then` closure and `use request()` (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Exemplos em bp`

Server component with data fetching:

```bp
#[@future]
pub fn BlogPage() -> @Future<Element> {
    val posts = await fetch("https://api.example.com/posts").then({ r -> r.json() });
    return div([
        h1([text("Blog")]),
        ul(posts.map({ post -> li([text(post.title)]) })),
    ], attrs: []);
}
```

Accessing the request:

```bp
#[@future]
pub fn SearchPage() -> @Future<Element> {
    val req = use request();
    val query = req.query("q");
    return div([h1([text("Busca: " + query)])], attrs: []);
}
```

Decided differently: a loader is a named `#[@future] fn … -> @Future<T>` awaited at statement level, never a `.then` closure (*Mechanism § 4*, *Step 4*); `use request()` is decided and waits on front 19 step 2 (*Language gaps*); the query accessor is `queryParam` (*Step 1*); rendered untrusted text goes through front 01's `escape.html` (*Mechanism § 5*); `text(…)` and `h1(…)` spell `attrs: []` (*Language gaps*, row 2).

### Step 3 pattern with `Dict` params

`1.0.7-beta/04-jhonstart-server-components/README.md § Step 3 — Server component pattern`

```bp
// A server component: #[@future] fn that awaits data
#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val slug = params.get("slug");
    val post = await fetchPost(slug);
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
        p([text(post.body, attrs: [])], attrs: []),
    ], attrs: []);
}
```

Old acceptance (all restated in *Step 3* above): pattern compiles; `await` works inside `#[@future]` fn; returns `@Future<Element>`. Kept for the `Dict` param shape, replaced by `Array<#(string, string)>` + `pairValue(params, "slug")`.

### Step 4 — this front edits `botopink.json` and `root.bp` (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Step 4 — Remove server.d.bp`, `§ Gate`, `§ Blast radius`

> Delete `server.d.bp`, update `botopink.json` and `root.bp`.
> - `server.d.bp` removed
> - `server.bp` in `botopink.json` and `root.bp`
> - `root.bp` gains `pub mod server;`

Decided differently: front 94 owns `src/root.bp` and `botopink.json`; this front hands it `pub mod server;` and the `files` swap (*Step 5*).

> **Amended 2026-09-21, on landing.** Front 28 made both edits itself — one line each. Front 94 had
> already landed, so there was no one to hand them to, and the intermediate state the hand-off
> implies does not build: deleting `server.d.bp` while `botopink.json` still lists it is not a tree
> any gate passes. Routing a one-line edit through a front that has closed costs more than it
> protects; if the ownership line matters more than the buildability, both lines revert trivially.

### Step 5 — test on `dict` and `req.path()`; commonJS + erlang gate (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Step 5 — Tests`

```bp
test "RequestData holds path and params" {
    val req = RequestData(
        path: "/blog/hello",
        params: dict.fromList([#("slug", "hello")]),
        query: dict.empty(),
        headers: dict.empty(),
        body: "",
        method: "GET",
    );
    assert req.path() == "/blog/hello";
}
```

Old acceptance:
- Tests pass on commonJS + erlang

Decided differently: gate is `botopink test --target erlang`; the commonJS row is not this front's gate and `request()` is expected to fail at the first cell there (*Test plan*). Record shape per *Step 1*.

### Gate — branch name

`1.0.7-beta/04-jhonstart-server-components/README.md § Gate`

- Commit on `fix/jhonstart-server-components`

### Blast radius — "no API change for consumers" (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Blast radius`

> No API change for consumers (same `from "jhonstart"` import).

Decided differently: the `Request` behavior, the `Http` phantom base and the `@Context` return type are dropped; `server.d.bp` was never in the module tree (`.d.bp` files are not resolved by `mod`, *Current state*), so no built consumer existed to break.

### Notes — `Http` phantom mirrors `Element` (different decision)

`1.0.7-beta/04-jhonstart-server-components/README.md § Notes`

> `Http` ContextBase is a phantom type supplied by the host — mirrors `Element` for client components.

Decided differently: `Http` is dropped. Decision 89 makes `@Future<Element>` unwrap to the owner `Element`, so one base serves the whole render tree and a server hook is `-> @Context<Element, Request>`; decision 90 lets the `#[@future]` annotation activate on its own (*Language gaps*, row 1).

### Reference rows from 1.0.7 overview/fronts

| Source | Row | Status above |
|---|---|---|
| `overview.md` front table | `04-jhonstart-server-components` · **critical** · repo `jhonstart` · module `jhonstart-core` · "Server components (`#[@future] fn → @Future<Element>`), data loading, `request()` hook" | priority and repo restated; module column `jhonstart-core` not restated; "`request()` hook" replaced by a plain function |
| `overview.md § Mapeamento Next.js → onze13` | React Server Components → `#[@future] fn → @Future<Element>` · jhonstart | restated as the `async function Page()` → `#[@future] pub fn Page(…) -> @Future<Element>` mapping in *Mechanism* |
| `fronts.md § Ownership` | F04 · jhonstart · jhonstart-core · `repository/jhonstart/src/server.bp` (promote from .d.bp) · `repository/jhonstart/test/server_test.bp` | both paths restated in *Owns* |
| `fronts.md § Conflict Matrix` | F04 row: `yes` against every other front, no conflict note | not restated (the 1.0.10 dependency list replaces the matrix) |
| `overview.md § Order`, `fronts.md § Order` | Phase 1 (critical path): F01 → F02 → F03 · F04 · F09 in parallel; F04 feeds Phase 2 | replaced by *Wave 2*, depends on 26 · 01 · 23 · 62 · 94 |
