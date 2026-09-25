# Front 28 — Jhonstart Server Components

**Track:** C jhonstart
**Priority:** critical — this is the front the whole server/client split exists for; without it every component is a client component and the BEAM render has nothing to render
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 26 · 01 (escaping) · 30 (payload envelope, read-only) · 62 (request context, read-only) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/server.bp` (promoted from `server.d.bp`), `repository/jhonstart/test/server_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (front 26), `src/link.bp` (front 27), `src/client.bp` (front 29), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` · `§ 9. Busca de Dados (Fetching)` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/getting-started/server-and-client-components · https://nextjs.org/docs/app/getting-started/fetching-data

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
async function Page() { … }        →    #[@use] pub fn Page(…) -> @Component<Element>
await getPost(slug)                →    await loadPost(slug)
```

`#[@use]` is not optional decoration — the annotation and the `@Component<…>` wrapper go together or
the compiler rejects the declaration (decision 102), and `@Component ⊃ @Future` is what lets the body
`await` (decision 104). This front's contribution is not the syntax, it is the five things around it.

### 0. `@Future` is eager on erlang, and that changes the port

This is the fact that most easily makes a server-component spec wrong. On the erlang backend a
`@Future<T>` is not a handle to work in progress: `libs/std/src/http.bp:16-18` states it outright —
"Erlang is eager: `@Future<T>` resolves to `T` in the eager-lowering arm documented in
`codegen/erlang.zig`, so the caller's `await fetch(url)` is identity on that backend."

The consequence is blunt. Two server components do **not** load their data in parallel
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
`collections.Dict<string, string>` as a type across a module boundary is unexercised anywhere in the tree,
and the pair list is what actually crosses the wire.

### 2. Accessors that cannot fail

`param`, `query`, `header` and `cookie` return a plain `string`, `""` when absent. This is not
laziness; it is the ecosystem's decided shape — rakun's `Request` does exactly this and says so
(`repository/rakun/src/http.bp:30-34`). An optional would force `.unwrapOr` at every call site in
every page, and `?T` handling is the single most common place the old spec examples went wrong.

### 3. Request scope comes from front 62, not from here

`cookies()`, `headers()`, `after()`, `connection()`, `draftMode()` and per-request memoization are
**front 62**'s (`rakun-request-context`). This front does not declare a parallel set. `server.bp`
owns the seam: front 62's dispatcher calls `fillRequest` once per request, and the six cells read
jhonstart's own `jhonstart_server` module (Step 2). The encoding is the same `k=v&k=v` string front
26 uses, decoded by front 26's `decodePairs`. If the encoding changes, this file changes and nothing
else in jhonstart does — which is the point of keeping it to six `declare fn` lines.

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

Nothing from this file. A server component's output is markup; front 30's render serializes the payload
(`globals.payload`) (`contracts.md § 2`) and front 29 turns the client subtrees into islands. The one thing this
front owes the boundary is that `RequestData` never appears in the payload's `i` array: a value read
from a header or a cookie must not be reachable from an island's props, and the check that it is not
is front 68's build-time graph walk.

The payload is front 30's to build and to escape — this front neither serializes nor escapes it, and
the only escaping it performs is front 01's on values it renders into markup.

## Steps

### Step 1 — `RequestData` and its accessors

```bp
// src/server.bp
import {Element} from "element";
import {pairValue, decodePairs} from "router";     // provided by front 26

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

### Step 2 — Binding the request context

The six cells are **dual-target against jhonstart's own** `jhonstart_server` erlang module and
`./server_runtime.mjs` sidecar — front 26's precedent — with `fillRequest` as the single `pub`
writer that front 62's dispatcher calls once per request. That keeps the seam where `02-packaging`
puts it: the app names the framework, never the reverse. If front 62 would rather own the module
atom, it is one line per accessor in `server.bp`.

An erlang-only cell is not writable here. A `#[@External.Erlang(…)]` cell with no `#[@External.Node]`
sibling reds the **commonJS compile** at the wrapper's call site (`` `__jhMethod` has no
`#[@External.<Target>(…)]` for the node backend ``) even though nothing on that row calls it — the
refusal is right under decision 67, and whether it can be owed by the **reachable call** rather than
by the declaration's presence is a compiler row in `status.md`. And a cell bound to
`rakun_request_context` would resolve on erlang and then die `{error, undef}`: rakun's module is not
jhonstart's to load.

The pair decoder is **front 26's `decodePairs`**, not `std/querystring`: `querystring.bp:22` emits a
bare `slice/3` it never defines, `erlc` refuses the module and the runner skips it silently on the
erlang row (worktree `.tasks/std-slice-shim`), and this front's gate is erlang. It also satisfies
this track's "one pair-list decoder in the package" principle, so it stands whether or not std is
fixed.

```bp
#[@External.Node("./server_runtime.mjs", "method"),
  @External.Erlang("jhonstart_server", "method")]
declare fn __jhMethod() -> string;

// … `__jhPath`, `__jhParams`, `__jhQuery`, `__jhHeaders`, `__jhCookies`, each dual-target
//    on the same two modules, `-> string`

pub fn request() -> RequestData {
    return RequestData(
        method: __jhMethod(),
        path: __jhPath(),
        params: decodePairs(__jhParams()),
        query: decodePairs(__jhQuery()),
        headers: decodePairs(__jhHeaders()),
        cookies: decodePairs(__jhCookies()),
    );
}

pub fn cookies() -> Array<#(string, string)> {
    return decodePairs(__jhCookies());
}

pub fn headers() -> Array<#(string, string)> {
    return decodePairs(__jhHeaders());
}
```

`request()` is a plain function, not a hook, until the effect-chain task (front 19 step 2) lands
`#[@use]`. See *Language gaps* for what it becomes then: `#[@use] fn request() -> @Use<ElementBase,
RequestData>`, activated as `use request()` inside a `#[@use] fn … -> @Component<Element>` body
(decision 104).

**Acceptance:**
- [ ] every cell is dual-target — `#[@External.Erlang("jhonstart_server", …)]` with its
      `#[@External.Node]` twin in `./server_runtime.mjs`; there is no erlang-only cell in the file,
      and the member compiles on both rows
- [ ] `fillRequest` is the only `pub` writer, and front 62's dispatcher calls it once per request
- [ ] `cookies()` and `headers()` are the only two re-exported shortcuts; `after`, `connection`,
      `draftMode` and memoization are called from front 62 directly and are not re-declared here
- [ ] `request()` over a context filled by `fillRequest` reconstructs the six fields

### Step 3 — The server-component convention

A server component is a `#[@use] pub fn` taking its route params and returning `@Component<Element>`
(decision 104): `@Component<Element>` is `@Use<ElementBase, Element>` for `Element: @Context<ElementBase>`
(decision 102), and `@Component ⊃ @Future`, so the body awaits its loaders and may activate
`request()` under the one annotation. A component that awaits nothing and activates nothing is a
plain `fn … -> Element` (question 92-b). `server.bp` ships no decorator for it: the marker is
`#[@use]`, which the language already enforces, and a second marker would be a second thing to get
wrong.

```bp
#[@future]
pub fn renderServerComponent(component: fn() -> @Component<Element>) -> @Future<string> {
    val tree = await component();
    return renderToString(tree);
}
```

**Acceptance:**
- [ ] a `#[@use] fn … -> @Component<Element>` that awaits a loader compiles on erlang
- [ ] omitting `#[@use]` on a body that awaits is a compile error, and the test suite records the
      expected message
- [ ] on commonJS every `#[@use]` body is emitted as `async function` (decision 104), so
      `renderServerComponent`'s `await component()` is a real await there
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

#[@use]
pub fn PostPage(params: Array<#(string, string)>) -> @Component<Element> {
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
| `#[@use]`, `@Component` and `@Use` are not in the compiler yet, so `use request()` cannot be written | `request()`, `cookies()`, `headers()` in `server.bp` | plain functions over the filled request context, called without `use` | **decided, unwritten** (decision 104; [`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md) step 2): `#[@use] fn Page() -> @Component<Element>` writes `use request()` and awaits its loaders under the one annotation, and `request()` is re-declared `#[@use] fn request() -> @Use<ElementBase, RequestData>` |
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
3. `request()` over a context filled by `fillRequest`: six strings in, the record out.
4. A `#[@use]` component that awaits a stub loader and renders — `await` works directly in a
   `test` block, so this runs without a host render loop.
5. A component with two sequential awaits at statement level.

The `commonJS` row is not this front's gate. The cells have Node twins, so the member compiles
there; the test file keeps every host-touching assertion in tests that are only meaningful on
erlang, and makes every other assertion construct its `RequestData` explicitly.

## Definition of done

- [ ] `server.d.bp` removed, `server.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [ ] `RequestData`, four accessors, `request`, `cookies`, `headers` all `pub` and tested
- [ ] every cell is dual-target; no erlang-only cell in the file
- [ ] `fillRequest` and the `k=v&k=v` encoding are agreed with front 62 and written down in
      `repository/jhonstart/docs.md`
- [ ] the `Http` phantom base and the `Request` behavior are gone, and `AGENTS.md` says why
- [ ] every untrusted value in an example passes through front 01's `escape.html` /
      `escape.attribute`; this front hand-rolls no escaping
- [ ] the erlang eager-`@Future` fact is stated in the README and in `repository/jhonstart/docs.md`,
      and every multi-loader example routes through front 02's unstarted-task list
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target
