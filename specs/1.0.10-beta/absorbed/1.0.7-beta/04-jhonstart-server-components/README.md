# Front 04 — Jhonstart Server Components

**Referência Next.js:** [Server and Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components) · [Fetching Data](https://nextjs.org/docs/app/getting-started/fetching-data)

**Priority:** critical — server components are the foundation of SSR data loading
**Depends on:** F02 (jhonstart-router)
**Owns:** `repository/jhonstart/src/server.bp` (promote from `server.d.bp`)
**Does not touch:** `router.bp`, `link.bp`, `element.bp`, `hooks.bp`, `html.bp`

---

## Problem

`server.d.bp` declares `request()` and `Request` behavior as host-bound stubs. Server components (`#[@future] fn → @Future<Element>`) and data loading are gated. The `#[@future]` annotation itself landed in v0.beta.12, but the `use-await-prefix`/`async-generators` gap for awaiting data in components is partially closed.

## Current state

- `server.d.bp` has `Request` behavior + `request()` as `#[@External.Node]` stubs
- `#[@future] fn … -> @Future<Element>` is parseable (effect annotation landed)
- `await` works inside `#[@future]` functions
- The SSR pipeline (F09 in rakun) will provide the actual Request object

## Exemplos em bp

### Server component com data fetching

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

### Acessando a request

```bp
#[@future]
pub fn SearchPage() -> @Future<Element> {
    val req = use request();
    val query = req.query("q");
    return div([h1([text("Busca: " + query)])], attrs: []);
}
```

## Mechanism

Promote `server.d.bp` → `server.bp`:
- `Request` behavior gets a concrete type `RequestData` (carries path, params, query, headers, body)
- `request()` returns `@Context<Http, Request>` backed by a host cell
- Server components are `#[@future] fn(…) -> @Future<Element>` — they can `await` data fetching
- The host runtime (rakun SSR) sets the request context before rendering

## Steps

### Step 1 — Concrete RequestData type

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

**Acceptance:**
- [ ] `RequestData` implements `Request` behavior
- [ ] All methods have real bodies

### Step 2 — request() hook

```bp
#[@External.Node("onze13/runtime", "getRequest")]
#[@External.Erlang("onze13_runtime", "get_request")]
declare fn getRequest() -> RequestData;

pub fn request() -> @Context<Http, Request> {
    return getRequest();
}
```

**Acceptance:**
- [ ] `request()` returns request data from host cell
- [ ] Host cells declared for both targets

### Step 3 — Server component pattern

Document and test the server component pattern:

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

**Acceptance:**
- [ ] Server component pattern compiles
- [ ] `await` works inside `#[@future]` fn
- [ ] Returns `@Future<Element>`

### Step 4 — Remove server.d.bp

Delete `server.d.bp`, update `botopink.json` and `root.bp`.

**Acceptance:**
- [ ] `server.d.bp` removed
- [ ] `server.bp` in `botopink.json` and `root.bp`

### Step 5 — Tests

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

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `server.d.bp` removed, `server.bp` in place
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-server-components`

## Blast radius

- `server.d.bp` → `server.bp` promotion
- No API change for consumers (same `from "jhonstart"` import)
- `root.bp` gains `pub mod server;`

## Notes

- The actual HTTP request lifecycle (receiving requests, setting context) is rakun's job (F09).
- `Http` ContextBase is a phantom type supplied by the host — mirrors `Element` for client components.
