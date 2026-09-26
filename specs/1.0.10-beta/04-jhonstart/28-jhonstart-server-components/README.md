# Front 28 — Jhonstart Server Components

**Track:** C jhonstart
**Priority:** critical — this is the front the whole server/client split exists for; without it every component is a client component and the BEAM render has nothing to render
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 26 · 01 (escaping, `encoding.formParse`) · 30 (payload envelope, read-only; its `render` / `renderStream` receive the `RequestData` and enter it) · 94 (element builders used by the examples) — and no rakun module: the request reaches jhonstart as a `RequestData` onze builds from rakun's `Request` and hands to the render (decision 114, item 8)
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
members)". The first has a producer now — onze hands every render the request as a `RequestData`
(decision 114), and the render is what `request()` reads. The second is
closed: `fn … -> @Task<T>` with `await` is landed and in production use
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
- `await` works under a `@Task` return. The compiler still wants the effect annotation beside the
  wrapper (`tests/language/reject/result_without_wrapper.bp`); front 24 removes the annotation and
  makes the return the whole declaration (decision 118).
- `await` works directly inside a `test` block (`repository/emilia/src/emilia.bp:475-480`), which is
  what makes this front testable at all.
- `libs/std/src/http.bp:16-18` — "Erlang is eager: `@Task<T>` resolves to `T` … so the caller's
  `await fetch(url)` is identity on that backend." There is no concurrent scheduler behind `@Task`
  on the BEAM.
- `libs/std/src/` has nineteen modules today and **no HTML escaping** among them. `escape.html` and
  `escape.attribute` are front 01's, new.

## Mechanism

A Next.js Server Component is an `async function` that returns JSX; it runs once, on the server, and
never ships to the browser (`NEXTJS-DOCS.md § 7`). jhonstart's equivalent is exact and needs no new
language surface:

```
async function Page() { … }        →    pub fn Page(…) -> @Component<ElementBase, Element>
await getPost(slug)                →    await loadPost(slug)
```

The `@Component<ElementBase, …>` return is not optional decoration — it is the declaration of the effect
(decision 118): without it `use` is refused, and `@Component ⊃ @Task` is what lets the body
`await`. A failure the component awaits is handled in its body (`try await load() catch …`, a `case`,
`notFound()`), because `Element` is not a `@Result` and a component never propagates (decision 121). This front's contribution is not the syntax, it is the five things around it.

### 0. `@Task` is eager on erlang, and that changes the port

This is the fact that most easily makes a server-component spec wrong. On the erlang backend a
`@Task<T>` is not a handle to work in progress: `libs/std/src/http.bp:16-18` states it outright —
"Erlang is eager: `@Task<T>` resolves to `T` in the eager-lowering arm documented in
`codegen/erlang.zig`, so the caller's `await fetch(url)` is identity on that backend."

The consequence is blunt. Two server components do **not** load their data in parallel
because they are futures. They run one after the other, in the order the enclosing body reaches
them, and the page costs the sum of its loaders. The Next.js pattern this front ports assumes the
opposite, so porting it shape-for-shape and stopping there would produce a page that is slower than
the synchronous version and a spec that never says why.

Parallel loading on the BEAM is a spawned process per unit of work, gathered by index. **Front 02
provides that**, and it takes **unstarted tasks** — `Array<fn() -> @Task<T>>` — not futures that
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

### 3. The request is handed in by onze, through the render

onze builds a `RequestData` from rakun's `Request` and passes it to front 30's
`render` / `renderStream(input, req, write)` (decision 114, item 8). The render enters it through
`enterRequest(req)` before the tree is built and leaves it when the render ends; `request()`,
`headers()` and `cookies()` read the value the render entered, from jhonstart's own
`jhonstart_server` module (Step 2). No rakun code calls into jhonstart and no jhonstart cell names a
rakun module — the two share nothing at run time. The stored encoding is the same `k=v&k=v` string
front 26 uses, decoded with std's `encoding.formParse` — the one percent-aware pair codec on both
sides of the stack (decision 116 rule 4; front 26's stand-in `decodePairs` is deleted); if it
changes, this file changes and nothing else in jhonstart does.

`after()`, `connection()`, `draftMode()` and per-request memoization stay **front 62**'s
(`rakun-request-context`): an application that needs them imports rakun itself. This front neither
re-declares nor calls them.

### 4. The loader convention

A loader is an ordinary `fn` returning `@Task<T>` for a `T` the component can render.
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
import {pairValue} from "router";                 // provided by front 26
import {encoding} from "std";                     // formParse — decision 116 rule 4

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
- [x] each accessor returns `""` for an absent key and never raises — `test/server_test.bp` "server: an absent key is the empty string, not a runtime error"
- [x] `pairValue` is imported from front 26's `router` module; this file defines no decoder of its own — `server.bp` imports it from `"router"`
- [x] no field of `RequestData` shares a name with one of its methods — `test/server_test.bp` "server: the fields are readable beside the methods that never shadow them"
- [x] `RequestData` is constructible in a test with no host present — `test/server_test.bp` "server: the same page renders from an explicit request, with no host"
- [x] the body is the empty string nowhere: there is no `body` field, because a render never reads
      one — form bodies are front 24's and route-handler bodies are front 25's — `RequestData` has six fields and no `body`

### Step 2 — Binding the request context

The six cells are **dual-target against jhonstart's own** `jhonstart_server` erlang module and
`./server_runtime.mjs` sidecar — front 26's precedent — with `enterRequest(req: RequestData)` as the
single writer and `leaveRequest()` as its pair, both called only by front 30's render, once per
render, with the `RequestData` onze handed it. That keeps the seam where `02-packaging` puts it: the
app names the framework, never the reverse.

An erlang-only cell is not writable here. A `#[@External.Erlang(…)]` cell with no `#[@External.Node]`
sibling reds the **commonJS compile** at the wrapper's call site (`` `__jhMethod` has no
`#[@External.<Target>(…)]` for the node backend ``) even though nothing on that row calls it — the
refusal is right under decision 67, and whether it can be owed by the **reachable call** rather than
by the declaration's presence is a compiler row in `status.md`.

The pair decoder is std's **`encoding.formParse`** (`01-std-lib-enablement` Step 3), not
`std/querystring` — `querystring` is escape-naive, and `querystring.bp:22` emits a bare `slice/3` it
never defines (worktree `.tasks/std-slice-shim`). The landed code used front 26's stand-in
`decodePairs`, which does not percent-decode; decision 116 rule 4 deletes it, so a cookie or query
value carrying `%20` reads as a space here exactly as it does in rakun. `pairValue` stays front 26's
one lookup over the decoded list.

```bp
#[@External.Node("./server_runtime.mjs", "method"),
  @External.Erlang("jhonstart_server", "method")]
declare fn __jhMethod() -> string;

// … `__jhPath`, `__jhParams`, `__jhQuery`, `__jhHeaders`, `__jhCookies`, each dual-target
//    on the same two modules, `-> string`

// the writer pair, called only by front 30's render with the `req` onze handed it
pub fn enterRequest(req: RequestData) -> i32
pub fn leaveRequest() -> i32

pub fn request() -> RequestData {
    return RequestData(
        method: __jhMethod(),
        path: __jhPath(),
        params: encoding.formParse(__jhParams()),
        query: encoding.formParse(__jhQuery()),
        headers: encoding.formParse(__jhHeaders()),
        cookies: encoding.formParse(__jhCookies()),
    );
}

pub fn cookies() -> Array<#(string, string)> {
    return encoding.formParse(__jhCookies());
}

pub fn headers() -> Array<#(string, string)> {
    return encoding.formParse(__jhHeaders());
}
```

`request()` is a plain function, not a hook, until front 24 lands the `@Component` return as the
grant of `use`. See *Language gaps* for what it becomes then: `fn request() -> @Component<ElementBase,
RequestData>`, activated as `use request()` inside a `fn … -> @Component<ElementBase, Element>` body.

**Acceptance:**
- [x] every cell is dual-target — `#[@External.Erlang("jhonstart_server", …)]` with its
      `#[@External.Node]` twin in `./server_runtime.mjs`; there is no erlang-only cell in the file,
      and the member compiles on both rows — `server.bp` six cells + `fill`, twins in `server_runtime.mjs` / `sidecars/jhonstart_server.erl`; 120/120 on both rows
- [x] `enterRequest` is the only writer and `leaveRequest` its pair; outside `server.bp` and front
      30's `render.bp` nothing calls either (grep in the gate) — `server.bp` (jhonstart `0101ad1`); in `src/` only `server.bp` names either until front 30's `render.bp`
- [x] `cookies()` and `headers()` are the only two shortcuts; `after`, `connection`, `draftMode` and
      memoization are front 62's, not re-declared here and not called from jhonstart — `server.bp`
- [x] `request()` after `enterRequest(req)` reconstructs the six fields of `req` — `test/server_test.bp` "server: request() after enterRequest(req) reconstructs the six fields"
- [x] no cell in `server.bp` names a rakun module, and `grep -rn rakun modules/jhonstart/src` is
      empty — `grep -rn rakun modules/jhonstart/src` names rakun only in comments

### Step 3 — The server-component convention

A server component is a `pub fn` taking its route params and returning `@Component<ElementBase, Element>`
(decision 128): the base is written, `Element: @Context<ElementBase>` is the owner (decision 102),
and `@Component ⊃ @Task`, so the body awaits its loaders and may activate `request()` under the one
return. A component that awaits nothing and activates nothing is a
plain `fn … -> Element` (question 92-b). `server.bp` ships no decorator for it: the marker is
the `@Component` return, which the language already enforces, and a second marker would be a second
thing to get wrong.

```bp
pub fn renderServerComponent(component: fn() -> @Component<ElementBase, Element>) -> @Task<string> {
    val tree = await component();
    return renderToString(tree);
}
```

**Acceptance:**
- [x] a `fn … -> @Component<ElementBase, Element>` that awaits a loader compiles on erlang — `test/server_test.bp` "server: a @Component component activates a hook and awaits a loader"
- [x] a body that awaits under a plain `-> Element` return is a compile error
      (`effect-await-without-task`), and the test suite records the expected message — `test/server_test.bp` header records `effect-await-without-task`
- [x] a component body that writes `try await loader()` without a `catch` is a compile error
      (`effect-try-without-fallible-channel`: `Element` is not a `@Result`) — `test/server_test.bp` header records `effect-try-without-fallible-channel`
- [x] on commonJS every `@Component` body is emitted as `async function` (decision 104), so
      `renderServerComponent`'s `await component()` is a real await there — the commonJS row runs `test/server_test.bp`'s awaiting tests green
- [x] `renderServerComponent` awaits exactly once and renders synchronously afterwards — `test/server_test.bp` "server: renderServerComponent awaits once and then is renderToString"
- [x] a component that awaits two loaders in sequence compiles and both awaits are at statement
      level, not inside a closure — `test/server_test.bp` "server: two sequential awaits at statement level, then a sync render"

### Step 4 — The loader convention

A loader is `fn name(args) -> @Task<T>`. `server.bp` ships **no** loader machinery:
`libs/std/src/http.bp:55` already has `fetch(url) -> @Task<Response>`, a database loader is front
08's, and parallel awaiting (`all`, `race`, `allSettled`) is front 02's. What this front owns is the
rule about where an `await` may stand.

Every `await` is at statement level in the component or loader body. It is never the last statement
of a lambda: a lambda's last statement must be an implicit-return expression, and no file in the
tree awaits inside one. So a component that needs N rows awaits **one** loader returning
`Array<T>` and maps synchronously afterwards — not N awaits inside a `map`.

```bp
fn loadPost(slug: string) -> @Task<Post> { … }

pub fn PostPage(params: Array<#(string, string)>) -> @Component<ElementBase, Element> {
    val post = await loadPost(pairValue(params, "slug"));
    val comments = await loadComments(post.id);
    return article([ … comments.map({ c -> commentRow(c) }) … ], attrs: []);
}
```

Two sequential awaits cost two round trips, and on erlang they cost them even when the results are
independent, because `@Task` there is eager. When the loaders are independent the fix is front
02's spawn-and-gather over **unstarted tasks** — `[{ -> loadPost(slug) }, { -> loadSidebar() }]` —
not a `map` over futures, which would simply run them in order. This front's doc says so and does
not provide a second answer.

**Acceptance:**
- [x] the convention is written in `repository/jhonstart/docs.md` with the rule about lambdas — `docs.md` § *The loader convention*
- [x] the test suite contains a component with two sequential awaits at statement level — `test/server_test.bp` "server: two sequential awaits at statement level, then a sync render"
- [x] `server.bp` exports no `awaitAll`-style helper, and the README says front 02 owns that — `server.bp`; `docs.md` names front 02
- [x] the doc names the erlang eager-`@Task` fact and cites `libs/std/src/http.bp:16-18` — `docs.md` § *The loader convention*

### Step 5 — Module promotion

Delete `server.d.bp`. front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod server;`, and `server.bp` in place of
`server.d.bp` in `files`. The `Http` phantom context base and the `Request` behavior do not come
along.

**Acceptance:**
- [x] `server.d.bp` is gone; `git grep -n "server.d.bp"` finds nothing outside the changelog — jhonstart `6d6c007`
- [ ] `pub mod server;` and the `files` swap are handed to front 94; this front edits neither file
- [x] `repository/jhonstart/AGENTS.md` records the promotion and the dropped `Http` base — `AGENTS.md` § *Front 28 — the request*

## Examples

- [`examples/blog-post-page-example.bp`](./examples/blog-post-page-example.bp) — the `/blog/[slug]`
  page: two loaders awaited in sequence, then a synchronous render.
- [`examples/request-scope-example.bp`](./examples/request-scope-example.bp) — a greeting that reads
  a cookie and a header, and the same page rendered from an explicit `RequestData` so it is testable
  without a host.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| The `@Component<C, T>` return as the grant of `use` is not in the compiler yet (front 24), so `use request()` cannot be written | `request()`, `cookies()`, `headers()` in `server.bp` | plain functions over the request the render entered, called without `use` | **decided, unwritten** (decisions 118 and 128; [`24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)): `fn Page() -> @Component<ElementBase, Element>` writes `use request()` and awaits its loaders under the one return, and `request()` is re-declared `fn request() -> @Component<ElementBase, RequestData>` |
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
3. `request()` after `enterRequest(req)`: the record in, the same record out.
4. A `-> @Component<ElementBase, Element>` component that awaits a stub loader and renders — `await` works directly in a
   `test` block, so this runs without a host render loop.
5. A component with two sequential awaits at statement level.

The `commonJS` row is not this front's gate. The cells have Node twins, so the member compiles
there; the test file keeps every host-touching assertion in tests that are only meaningful on
erlang, and makes every other assertion construct its `RequestData` explicitly.

## Definition of done

- [ ] `server.d.bp` removed, `server.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [x] `RequestData`, four accessors, `request`, `cookies`, `headers` all `pub` and tested — `test/server_test.bp`
- [x] every cell is dual-target; no erlang-only cell in the file — `server.bp`
- [x] `enterRequest` / `leaveRequest`, their one caller (front 30's render) and the `k=v&k=v`
      encoding are written down in `repository/jhonstart/docs.md` — `docs.md` § *The six cells, and where they point*
- [x] the `Http` phantom base and the `Request` behavior are gone, and `AGENTS.md` says why — `AGENTS.md` § *The `Http` base, and why it is gone*
- [ ] every untrusted value in an example passes through front 01's `escape.html` /
      `escape.attribute`; this front hand-rolls no escaping
- [ ] the erlang eager-`@Task` fact is stated in the README and in `repository/jhonstart/docs.md`,
      and every multi-loader example routes through front 02's unstarted-task list
- [x] all three language gaps appear in a `specs/1.0.10-beta/` spec — `language-gaps.md` rows "Declared parameter defaults…", "`xs[0]` silently drops the index…"; the `@Component` grant landed with `00 · 24`
- [x] the front's tests are green on its assigned target — `server_test.bp` 19/19 on erlang and commonJS
