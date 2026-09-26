# Front 28 — Jhonstart Server Components

**Track:** C jhonstart
**Priority:** critical — this is the front the whole server/client split exists for; without it every component is a client component and the BEAM render has nothing to render
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 26 · 01 (`escape`, `encoding.formParse`) · 30 (its `render` / `renderStream` receive the `RequestData` and enter it) · 94 (element builders used by the examples) — and no rakun module: the request reaches jhonstart as a `RequestData` onze builds from rakun's `Request` and hands to the render (decision 114, item 8)
**Owns:** `modules/jhonstart/src/server.bp` (with `server_runtime.mjs` / `sidecars/jhonstart_server.erl`), `modules/jhonstart/test/server_test.bp`
**Does not touch:** `element.bp`, `hooks.bp`, `jhonstart-html/src/html.bp` (frozen), `router.bp` (front 26), `jhonstart-link` (front 27), `client.bp` (front 29)
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` · `§ 9. Busca de Dados (Fetching)` · `§ 26. Referência de Funções` · https://nextjs.org/docs/app/getting-started/server-and-client-components · https://nextjs.org/docs/app/getting-started/fetching-data

---

## Outcome

A Next.js Server Component — an `async function` that returns JSX, runs once on the server and never
ships — is a jhonstart function whose return declares the effect:

```
async function Page() { … }        →    pub fn Page(…) -> @Component<ElementBase, Element>
await getPost(slug)                →    await loadPost(slug)
```

A component that only loads data is `fn … -> @Task<Element>`; one that also activates a hook is
`fn … -> @Component<ElementBase, Element>` (decision 128: `@Component ⊃ @Task`). Neither is a
`@Result`, so a component handles a failed load in its body (`try await load() catch …`, a `case`,
`notFound()`) and never propagates (decision 121). There is no server-component decorator: the
return is the marker, and the language enforces it (`effect-await-without-task`,
`effect-try-without-fallible-channel`).

| What | Shape |
|---|---|
| The request | `RequestData(method, path, params, query, headers, cookies)` — a plain record, every plural field `Array<#(string, string)>` (the shape of front 26's snapshot and of `Element.attrs`). No `Dict`, no `body` field: form bodies are front 24's, route-handler bodies front 25's |
| Its accessors | `r.param(n)` · `r.queryParam(n)` · `r.header(n)` · `r.cookie(n)` — plain `string`, `""` when absent, never raise; all through front 26's `pairValue` |
| The hook | `request() -> @Component<ElementBase, RequestData>` — `val req = use request()` in a component; called without `use` it answers the same value (awaited on commonJS) |
| The shortcuts | `cookies()` · `headers()` — the only two. `after`, `connection`, `draftMode` and per-request memoization are front 62's |
| The writer pair | `enterRequest(req)` · `leaveRequest()` — the one way request state is installed and removed, called by front 30's render once per render with the `RequestData` onze handed it. Outside the pair, `request()` / `cookies()` / `headers()` raise |
| The render entries | `renderServerComponent(component: fn() -> @Task<Element>) -> @Task<string>` · `renderComponent(component: fn() -> @Component<ElementBase, Element>) -> @Task<string>` — each takes an **unstarted thunk**, awaits once, renders synchronously |

**Call-site rule.** Pass a lambda, never a bare function name: `renderServerComponent({ -> Page(ps) })`
is green on both rows, `renderServerComponent(Page)` fails `variable 'Page' is unbound` on erlang (a
compiler defect, reported, not worked around).

### Binding the request context

The six read cells (`__jhReqMethod`, `__jhReqPath`, `__jhReqParams`, `__jhReqQuery`,
`__jhReqHeaders`, `__jhReqCookies`) plus the enter/leave cells are dual-target against jhonstart's own
`jhonstart_server` erlang module and `./server_runtime.mjs` — an erlang-only cell reds the commonJS
compile at its call site, and the core member compiles on both rows. The BEAM store is the calling
process's dictionary: a request is a process, so two concurrent renders cannot see each other's
cookies. No cell names a rakun module; jhonstart and rakun share nothing at run time.

The four pair lists are stored `k=v&k=v`, encoded with std's `encoding.formStringify` and decoded
with `encoding.formParse` — the one percent-aware pair codec on both sides of the stack (decision
116 rule 4), so a `%20` reads as a space here exactly as in rakun.

`enterRequest` is deliberately separate from front 26's `fill`: a route snapshot is re-filled during
a render (its `selected` is the layout depth), a request is entered once and constant.

### `@Task` is eager on erlang

On the erlang backend `@Task<T>` resolves eagerly and `await` is identity (decision 120). Two
server components or two loaders do **not** run in parallel: they run in the order the body
reaches them, and the page costs the sum of its loaders. Parallel loading on the BEAM is **front
02**'s spawn-and-gather over **unstarted tasks** — `[{ -> loadPost(slug) }, { -> loadSidebar() }]`
— not a `map` over tasks, which would simply run them in order. This front ships no `awaitAll`,
`race` or `allSettled`.

### The loader convention

A loader is an ordinary `fn name(args) -> @Task<T>` (a fallible one `-> @Task<@Result<T, E>>`,
consumed with `try await … catch`). `server.bp` ships no loader machinery: std's `io.http` has
`fetch`, a database loader is front 08's. Every `await` stands at statement level in the component
or loader body, never as the last statement of a lambda; a component that needs N rows awaits one
loader returning `Array<T>` and maps synchronously.

```bp
fn loadPost(slug: string) -> @Task<Post> { … }

pub fn PostPage(params: Array<#(string, string)>) -> @Task<Element> {
    val post = await loadPost(pairValue(params, "slug"));
    val comments = await loadComments(post.id);
    return article([ … comments.map({ c -> commentRow(c) }) … ], attrs: []);
}
```

### Escaping is not ours

`renderToString` escapes nothing (frozen `element.bp`); the render that ships is front 30's
`renderNode`, which escapes through std's `escape`. A server component calls `escape.html` /
`escape.attribute` (std, front 01) where an untrusted value enters the tree if it renders through
`renderToString`; this front hand-rolls neither.

### What crosses to the client

Nothing from this file. A server component's output is markup; front 30's render writes the payload
(`globals().payload`, `contracts.md § 2`) and front 29 turns client subtrees into islands.
`RequestData` must never reach an island's props — the check is front 68's build-time graph walk.

### Delivered

- `RequestData`, its four accessors, `request`, `cookies`, `headers`, `enterRequest`, `leaveRequest`, `renderServerComponent`, `renderComponent` — `pub`, tested in `server_test.bp`, both rows.
- `pairValue` is imported from front 26's `router`; `server.bp` defines no decoder of its own; no field shares a name with a method; `RequestData` is constructible with no host.
- Every cell is dual-target; `enterRequest`/`leaveRequest` are called only by `server.bp` and front 30's render; no rakun module is named in a cell.
- `request()` after `enterRequest(req)` reconstructs the six fields of `req`.
- A `@Component` component that awaits a loader and activates a hook compiles and runs; `effect-await-without-task` and `effect-try-without-fallible-channel` are recorded in `server_test.bp`'s header; on commonJS every `@Component` body is an `async function` (decision 104).
- `renderServerComponent` awaits exactly once; a component with two sequential statement-level awaits compiles and renders.
- `docs.md` § *The loader convention* (with the lambda rule, front 02 as the owner of parallel awaiting, the eager-`@Task` fact) and § *The six cells, and where they point* (the writer pair, its caller, the `k=v&k=v` encoding).
- `server.d.bp` is gone; `AGENTS.md` § *The `Http` base, and why it is gone* records why the phantom `Http` base and the `Request` behavior were dropped: one base, `ElementBase`, serves the whole render tree.
- `use request()` is granted by the `@Component` return (`00 · 24`); the other language gap is a row of `language-gaps.md`.

## Steps

Only the open boxes are listed; everything else is under *Delivered*.

### Step 1 — `RequestData` and its accessors

Done.

### Step 2 — Binding the request context

Done.

### Step 3 — The server-component convention

Done.

### Step 4 — The loader convention

Done.

### Step 5 — Module promotion

- [ ] `pub mod server;` and the `files` swap are handed to front 94; this front edits neither file

## Examples

- [`examples/blog-post-page-example.bp`](./examples/blog-post-page-example.bp) — the `/blog/[slug]`
  page: two loaders awaited in sequence, then a synchronous render.
- [`examples/request-scope-example.bp`](./examples/request-scope-example.bp) — a greeting that reads
  a cookie and a header, and the same page rendered from an explicit `RequestData` so it is testable
  without a host.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `xs[0]` silently drops the index on the beam backend (`tests/language/expected-failures.txt`) | reading the first row of a loader's result | `.at(0).unwrapOr(default)` | make the index expression lower correctly on beam, or reject it there |

## Test plan

`modules/jhonstart/test/server_test.bp`, both rows, in the gate through
`zig build test-libs -- --lib jhonstart`: `RequestData` and each accessor (present, absent, empty
list, single pair — `pairValue` itself is front 26's); `request()` after `enterRequest(req)`; a
`@Component` component awaiting a stub loader (`await` works in a `test` block); two sequential
statement-level awaits.

## Definition of done

- [ ] `server.d.bp` removed, `server.bp` in the build tree, its `root.bp` and `files` lines handed
      to front 94
- [x] `RequestData`, four accessors, `request`, `cookies`, `headers` all `pub` and tested
- [x] every cell is dual-target; no erlang-only cell in the file
- [x] `enterRequest` / `leaveRequest`, their one caller (front 30's render) and the `k=v&k=v`
      encoding are written down in `repository/jhonstart/docs.md`
- [x] the `Http` phantom base and the `Request` behavior are gone, and `AGENTS.md` says why
- [ ] every untrusted value in an example passes through front 01's `escape.html` /
      `escape.attribute`; this front hand-rolls no escaping
- [ ] the erlang eager-`@Task` fact is stated in the README and in `repository/jhonstart/docs.md`,
      and every multi-loader example routes through front 02's unstarted-task list
- [x] both language gaps appear in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target
