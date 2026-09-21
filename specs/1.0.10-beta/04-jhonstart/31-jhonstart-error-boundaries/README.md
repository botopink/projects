# Front 31 — Jhonstart Error Boundaries

**Track:** C jhonstart
**Priority:** high — one throwing component currently takes the whole response with it, and the reader gets a blank page with a 500
**Target:** erlang (server)
**Boundary:** the server catches render errors and emits a fallback plus a digest; the browser catches runtime and transition errors and shows the same fallback. The `ErrorInfo` shape and the digest are defined here and read by front 29's `hydrate()` and by front 17's logger. This front carries no browser cell.
**Wave:** 3
**Depends on:** 28 · 03 (content hash) · 94 (`htmlTag`/`body` builders for `global-error.bp`) · 17 (logging, read-only) · 24 (action envelope, read-only) · 63 (navigation signals, read-only)
**Owns:** `repository/jhonstart/src/error_boundary.bp`, `repository/jhonstart/test/error_boundary_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/suspense.bp`/`src/streaming.bp` (30), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 14. Tratamento de Erros` · `§ 3. Estrutura do Projeto` · https://nextjs.org/docs/app/getting-started/error-handling · https://nextjs.org/docs/app/api-reference/file-conventions/error · https://nextjs.org/docs/app/api-reference/file-conventions/not-found
**Replaces:** `1.0.7-beta/07-jhonstart-error-boundaries`

---

## Problem

A jhonstart render has exactly one failure mode: the whole thing. `renderToString` is a recursive
walk with no recovery point (`element.bp:55-67`), and a loader that raises inside a server component
takes the entire response down with it. A blog whose comment service is down cannot serve the post.

There is no vocabulary for any of the four things upstream provides
(`NEXTJS-DOCS.md § 14`): a per-segment fallback (`error.tsx`), a 404 surface (`not-found.tsx`), a
root fallback that owns its own document (`global-error.tsx`), and a `reset`/`retry` that re-runs the
failed subtree without a full reload. Nor is there a way to *not* leak: an error message from a
server render is a string built from an exception, and putting it in the HTML hands the reader a
stack trace and possibly a connection string. Upstream solves that with `digest` — the server logs
the error and the client sees only an opaque id (`NEXTJS-DOCS.md § 14`, `error: Error & { digest?:
string }`). jhonstart has neither the digest nor the logging it correlates with.

The 1.0.7 draft's `ErrorBoundary` rendered its children inside a `<div
data-jhonstart-error-boundary>` and caught nothing — there was no `try`, no `@Result`, and no point
at which a throwing child could have been intercepted. It was the shape of an error boundary without
the mechanism.

## Current state

- No error handling anywhere in `repository/jhonstart/src/`. `root.bp:15-17` declares three modules.
- `#[@result] fn … -> @Result<D, E>` with `throw`/`try`/`case` is landed and documented
  (`docs.md:513-524`). `@Result` variants are `Ok(result: R)` and `Error(error: E)`
  (`libs/std/src/builtins.d.bp:24-27`); there is no `Err` and no `.unwrap()`.
- `libs/std/src/crypto.bp` exists; a stable content hash for the digest is front 03's
  `content_hash`, not a private hash here.
- `notFound()`, `redirect()`, `permanentRedirect()`, `forbidden()` and `unauthorized()` are **front
  63**'s navigation signals. This front does not define them; it defines what happens to the render
  when one is raised.
- `html` and `body` are not among the eight element builders (`element.bp:10-53`), which
  `global-error.bp` needs — see *Mechanism*.

## Mechanism

Upstream nests a boundary per route segment and lets each segment's `error.tsx` catch what its
subtree throws (`NEXTJS-DOCS.md § 14`). jhonstart's version uses the language's own failure channel:
a boundary's child is a `#[@result]` thunk, and the boundary is a `case` over its result. That is the
only mechanism in botopink that can catch anything, and using anything else would be a fiction.

### The erlang half — this front

```bp
pub type ErrorInfo(
    message: string,
    digest: string,
)

pub type ErrorBoundary(
    id: string,
    fallback: fn(info: ErrorInfo) -> Element,
    child: fn() -> @Result<Element, string>,
)
```

`renderBoundary(b)` calls the thunk once and branches:

```bp
pub fn renderBoundary(b: ErrorBoundary) -> Element {
    val outcome = b.child();
    return case outcome {
        Ok(tree) -> wrap(b.id, tree);
        Error(message) -> wrap(b.id, b.fallback(infoFor(message)));
    };
}
```

The child is a thunk for the same reason front 30's is: a value passed in has already run, and a
boundary that receives a value cannot catch anything that happened while producing it.

### Digests — the thing that makes the fallback safe to ship

`infoFor(message)` never puts the message in the `ErrorInfo` that reaches the browser. It computes a
digest — front 03's content hash of the message — and returns `ErrorInfo(message: "", digest: d)`
for the client-visible path, while handing the full message plus the digest to front 17's logger.
The correlation is the digest: the reader reports `a3f19c2b`, the operator greps the log for
`a3f19c2b` and finds the stack.

The split is enforced by two functions rather than by care:

| Function | Returns | Used by |
|---|---|---|
| `infoFor(message)` | `ErrorInfo(message: "", digest: …)` | the fallback that renders into HTML |
| `serverInfoFor(message)` | `ErrorInfo(message: message, digest: …)` | front 17's logger, and nothing that renders |

A fallback that wants to show the message anyway can, on a development build, by calling
`serverInfoFor` — which is exactly one grep away for a reviewer.

### Navigation signals are not errors

Front 63 raises `notFound()`, `redirect()` and the rest. They travel the same `@Result` channel as a
real error, so this front has to tell them apart and must not render a fallback for a redirect. The
discriminator is front 63's signal prefix, checked by `isSignal(message)`; a boundary re-throws a
signal rather than catching it, so it reaches front 23 which turns it into a 404 or a 307.
`not-found.bp` is rendered by front 23 when it sees front 63's not-found signal, using the boundary
type defined here — this front owns the type, not the dispatch.

### The three file conventions

| File | Exports | Rendered when | Owns its document? |
|---|---|---|---|
| `error.bp` | `pub fn ErrorPage(info: ErrorInfo) -> Element` | the segment's subtree returns `Error(…)` | no |
| `not-found.bp` | `pub fn NotFound() -> Element` | front 63's not-found signal reaches this segment | no |
| `global-error.bp` | `pub fn GlobalError(info: ErrorInfo) -> Element` | the root segment fails, or no other boundary caught | **yes** — it renders its own `htmlTag` and `body` |

The export is `ErrorPage`, not `Error`, and the difference matters: `Error(error: E)` is the
`@Result` variant (`libs/std/src/builtins.d.bp:24-27`). A module-level `pub fn Error` would shadow
the variant constructor inside every `case` arm in that file, and the failure would be a type error
somewhere else entirely. The convention takes the two extra characters.

`global-error.bp` needing the document root and `body` is the one place these conventions touch the
element surface: neither builder exists in `element.bp`, which is frozen. Both come from front 94
(jhonstart-element-surface), which is why this front depends on it. The document-root builder is
spelled **`htmlTag`**, not `html`: `html` is already the markup DSL template function in the same
package (`html.bp:94`), and a second `html` in a consumer's flat import would shadow it. Front 94 is wave 0, so the
dependency costs nothing in ordering — `global-error.bp` is writable as soon as this front starts.

Front 22 discovers the files; front 23 builds the boundaries. This front defines the record and the
render, and nothing about file discovery.

### The js half — front 29 and front 68

Three rules, and all three are contract, not code in this repository:

1. A `[data-onze-e="ID"]` element is the catch target. A client component that throws
   during render is replaced by the nearest enclosing one's fallback, rendered from the same
   `ErrorInfo` shape.
2. **Event-handler errors are not caught.** `NEXTJS-DOCS.md § 14`, *Erros em event handlers*, is
   explicit: error boundaries do not capture them, and the handler must `try`/`catch` itself. In
   jhonstart this is structural rather than a rule to remember — a handler is a
   `data-onze-on-click` attribute naming a handler, so it is not inside the boundary's `@Result`
   channel at all, and there is nothing for `renderBoundary` to branch on.
3. **`startTransition` errors are caught.** The same section names the exception. Front 68's runtime
   wraps a transition and routes a failure to the nearest `data-onze-e`, with a digest
   computed the same way.

### A failing server action is not a render error

Front 24's response envelope is
`{"v":1,"ok":…,"state":"<querystring>","revalidated":[…],"redirect":"…","payload":"…"}`
(`contracts.md § 3`). An action that fails returns `ok: false` with a `state` the form re-renders
from — it is an **expected** error, in upstream's vocabulary (`NEXTJS-DOCS.md § 14`, *Erros
esperados*), and it must not reach a boundary. A boundary that caught it would replace the form with
"something went wrong" and lose what the reader typed.

So the rule is: an action envelope with `ok: false` is data, handled by front 67's form state. A
boundary sees an action only when the POST itself raised — a 500, not a validation failure — and in
that case `state` is absent and the digest path applies. Front 67 implements the split; this front
states it so that neither side assumes the other is catching.

### `reset` / `retry`

Upstream's `reset()` re-renders the failed subtree. jhonstart's fallback emits
`data-onze-reset="ID"`; front 29's `hydrate()` binds it, and the action it performs is front
26's `refresh()` — re-request the route's payload and re-reconcile. On the server a reset is not
available at all (there is nothing to re-render into), so the fallback's reset affordance is inert
in the first HTML and becomes live at hydration. The README says so rather than emitting a button
that does nothing forever.

## Steps

### Step 1 — `ErrorInfo`, `ErrorBoundary`, `renderBoundary`

```bp
// src/error_boundary.bp
import {Element} from "element";
import {content_hash} from "std";

pub type ErrorInfo(message: string, digest: string)

pub type ErrorBoundary(
    id: string,
    fallback: fn(info: ErrorInfo) -> Element,
    child: fn() -> @Result<Element, string>,
)

pub fn digestOf(message: string) -> string {
    return content_hash.short(message);
}

pub fn infoFor(message: string) -> ErrorInfo {
    return ErrorInfo(message: "", digest: digestOf(message));
}

pub fn serverInfoFor(message: string) -> ErrorInfo {
    return ErrorInfo(message: message, digest: digestOf(message));
}
```

**Acceptance:**
- [ ] `infoFor("boom")` carries an empty message and a non-empty digest
- [ ] `serverInfoFor("boom")` carries the message and the **same** digest
- [ ] `digestOf` is front 03's hash; this file defines no hash of its own
- [ ] `digestOf` is stable across runs and across the erlang and js backends

### Step 2 — The catch

```bp
pub fn wrap(id: string, tree: Element) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: [tree],
        attrs: [#("data-onze-e", id)],
    );
}
```

`data-onze-e` and `data-onze-reset` are this front's two additions to the `data-onze-` marker family
(`contracts.md § 2`), registered there rather than invented locally.

```bp

pub fn renderBoundary(b: ErrorBoundary) -> Element {
    val outcome = b.child();
    return case outcome {
        Ok(tree) -> wrap(b.id, tree);
        Error(message) -> wrap(b.id, b.fallback(infoFor(message)));
    };
}
```

**Acceptance:**
- [ ] a child returning `Ok` renders the child inside the boundary wrapper
- [ ] a child that `throw`s renders the fallback, and the child's markup is absent
- [ ] the fallback receives an `ErrorInfo` whose `message` is `""`
- [ ] `renderBoundary` calls the thunk exactly once
- [ ] the arms are arrow arms (`Ok(tree) -> …;`), not block arms — block arms parse but do not yield
      a value (`tests/language/expected-failures.txt`, `case_sections.bp`)

### Step 3 — Signals pass through

```bp
pub fn isSignal(message: string) -> bool {
    return message.startsWith("jhonstart:");
}
```

`renderBoundary` re-raises a signal instead of catching it. Because `renderBoundary` is not itself
`#[@result]`, the re-raise is done by the caller: `renderBoundary` returns the tree, and
`renderBoundaryChecked` is the `#[@result]` wrapper front 23 calls.

```bp
#[@result]
pub fn renderBoundaryChecked(b: ErrorBoundary) -> @Result<Element, string> {
    val outcome = b.child();
    return case outcome {
        Ok(tree) -> wrap(b.id, tree);
        Error(message) -> rethrowOrFallback(b, message);
    };
}
```

**Acceptance:**
- [ ] a child failing with `"jhonstart:not-found"` is not caught — the boundary's result is `Error`
      with the same message
- [ ] a child failing with an ordinary message is caught and yields `Ok` of the fallback
- [ ] `isSignal` recognises every prefix front 63 defines, and front 63's README lists them
- [ ] the prefix string appears in exactly one place in this file

### Step 4 — `catchError`, the functional form

Upstream's `catchError(Fallback)` returns a component (`NEXTJS-DOCS.md § 14`). The direct port is a
curried call, which does not type-check in botopink — `adder(3)(4)` reports `unbound variable ''`
(`tests/language/expected-failures.txt`). So `catchError` returns the **boundary record**, and the
call site renders it:

```bp
pub fn catchError(id: string, fallback: fn(info: ErrorInfo) -> Element, child: fn() -> @Result<Element, string>) -> ErrorBoundary {
    return ErrorBoundary(id: id, fallback: fallback, child: child);
}
```

That is `ErrorBoundary(…)` with a different name, and the README says so: the value of the form is
that it reads like the upstream one at the call site, not that it does anything more.

**Acceptance:**
- [ ] `catchError` is documented as the readable spelling of the constructor, not a second mechanism
- [ ] the curried form is recorded as a language gap, with the expected-failure citation

### Step 5 — The three file conventions, written down

`repository/jhonstart/docs.md` gains the three-row table from *Mechanism* plus the three browser
rules. Front 22 cites the table for discovery; front 23 cites it for wrapping; front 29 cites the
browser rules.

**Acceptance:**
- [ ] the table and the browser rules are in `repository/jhonstart/docs.md`
- [ ] `global-error.bp`'s requirement to render its own `htmlTag`/`body` is stated, and names front 94
      as the source of both builders
- [ ] this front's `pub mod error_boundary;` line and its `botopink.json` `files` entry are handed
      to front 94, which owns `src/root.bp` and the `files` list and appends in front-number order
- [ ] `repository/jhonstart/AGENTS.md` updated in the same commit

## Examples

- [`examples/segment-error-example.bp`](./examples/segment-error-example.bp) — a dashboard segment
  whose metrics service fails: the `error.bp` a developer writes, the boundary around it, and the
  digest the reader sees.
- [`examples/not-found-example.bp`](./examples/not-found-example.bp) — a `not-found.bp`, and a
  boundary proving front 63's signal passes through instead of being swallowed.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Curried calls parse but do not type — `adder(3)(4)` reports `unbound variable ''` (`tests/language/expected-failures.txt`) | `catchError(Fallback)` cannot return a component the way upstream does | `catchError(id, fallback, child) -> ErrorBoundary`, rendered by the caller | type a call whose callee is a returned function |
| No assignment to a `self` field; a record has no in-place update | a boundary cannot record "I already failed once" to suppress a retry loop; the retry budget lives in front 29's runtime instead | host-side state | a `var` field or a copy-update expression |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []` | write every argument | apply the declared default when an argument is omitted |

## Test plan

`repository/jhonstart/test/error_boundary_test.bp`, run by `botopink test --target erlang` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target erlang --lib jhonstart`.

Assertions:

1. `Ok` child renders inside the wrapper; `Error` child renders the fallback and not the child.
2. The fallback's `ErrorInfo` has an empty `message` and a non-empty `digest`.
3. `infoFor` and `serverInfoFor` agree on the digest and disagree on the message.
4. A signal message passes through `renderBoundaryChecked` uncaught; an ordinary message does not.
5. **Event-handler errors are not caught** — a child that renders a `data-onze-on-click` attribute
   renders `Ok`, the boundary's fallback is not involved, and the handler name survives into the
   markup. The assertion is that the handler is outside the `@Result` channel by construction.
6. **`startTransition` errors are caught** — the boundary's wrapper carries
   `data-onze-e="ID"`, which is the anchor front 68's runtime routes a transition failure
   to. The assertion is on the anchor's presence and its id; the routing itself is front 68's test.
7. The thunk is called exactly once, proved by a thunk that appends to a module-level marker.

The js row is not this front's gate. Rules 1–3 of *The js half* are asserted by front 29's
`test/client_test.bp` against markup produced here; if that coverage is absent, this front's browser
contract is untested and the milestone should treat it as a red rather than as done.

## Definition of done

- [ ] `error_boundary.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [ ] `renderBoundary` catches with a `case` over `@Result` — the only catching mechanism the
      language has — and a test proves a throwing child does not reach the output
- [ ] no client-visible `ErrorInfo` ever carries a message; a test asserts it
- [ ] the digest is front 03's hash and correlates with front 17's log line
- [ ] front 63's signals pass through, and the prefix is agreed with front 63
- [ ] the event-handler and `startTransition` semantics each have a test
- [ ] `data-onze-e` and `data-onze-reset` are registered in `contracts.md § 2`
- [ ] an action envelope with `ok: false` is documented as data, not as something a boundary catches,
      and front 67's README agrees
- [ ] `global-error.bp` renders its own document root with front 94's `htmlTag` and `body`, and a
      test asserts both tags are present exactly once
- [ ] no example or step in this front calls `html(...)` as a constructor — that name is the markup
      DSL (`html.bp:94`)
- [ ] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F07 jhonstart-error-boundaries

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### `ErrorBoundaryProps` / `ErrorBoundary(props)` / `NotFoundBoundary`

`1.0.7-beta/07-jhonstart-error-boundaries/README.md § Mechanism`, `§ Steps › Step 1 — ErrorBoundary component`. Superseded by the `ErrorBoundary` record with a `#[@result]` thunk and `renderBoundary`'s `case` (*Mechanism › The erlang half*, Step 1, Step 2). `NotFoundBoundary` has no counterpart: `not-found.bp` is rendered by front 23 using the single boundary type (*Mechanism › Navigation signals are not errors*).

> Introduce error boundary components:
> - `ErrorBoundary` wraps children and catches rendering errors
> - `error.bp` convention: file router wraps each route segment in an error boundary
> - `not-found.bp` convention: 404 UI when a route is not found
> - `global-error.bp` convention: root-level error boundary

```bp
// src/error_boundary.bp
import {Element} from "element";

pub type ErrorBoundaryProps(
    fallback: fn(error: string) -> Element,
    children: Children,
)

pub fn ErrorBoundary(props: ErrorBoundaryProps) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [#("data-jhonstart-error-boundary", "true")],
    );
}

pub fn NotFoundBoundary(props: ErrorBoundaryProps) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: props.children,
        attrs: [#("data-jhonstart-not-found-boundary", "true")],
    );
}
```

| Old item | Status |
|---|---|
| `data-jhonstart-error-boundary` marker | replaced — `data-onze-e="ID"` (`contracts.md § 2`) |
| `fallback: fn(error: string) -> Element` | replaced — `fn(info: ErrorInfo) -> Element`; the raw message never reaches the fallback |
| `NotFoundBoundary` / `data-jhonstart-not-found-boundary` | absent — one boundary type; signals pass through |
| Acceptance: `ErrorBoundary` and `NotFoundBoundary` compile; render children with boundary metadata | replaced — Step 1/2 acceptance |

### `error.bp` exporting `Error` (with `#[client]` and `retry: fn()`)

`1.0.7-beta/07-jhonstart-error-boundaries/README.md § Exemplos em bp › error.bp` and `§ Steps › Step 2 — error.bp / not-found.bp conventions`. Superseded: the export is `ErrorPage(info: ErrorInfo)` (*Mechanism › The three file conventions*, with the shadowing rationale); the retry is `data-onze-reset="ID"` bound by front 29 (*Mechanism › `reset` / `retry`*); there is no `#[client]` marker on the file.

```bp
#[client]
pub fn Error(error: string, retry: fn()) -> Element {
    return div([
        h2([text("Algo deu errado!")]),
        button([text("Tentar novamente")], attrs: [#("onClick", "retry")]),
    ], attrs: []);
}
```

> `error.bp`: exports `fn Error() -> Element` — fallback UI for errors in this segment

```bp
// app/blog/error.bp
pub fn Error() -> Element {
    return div([
        h1([text("Something went wrong", attrs: [])], attrs: []),
        p([text("Please try again later.", attrs: [])], attrs: []),
    ], attrs: []);
}
```

### `notFound()` as a host-backed declaration

`1.0.7-beta/07-jhonstart-error-boundaries/README.md § Steps › Step 3 — notFound() function`, `§ Exemplos em bp › notFound()`, `§ Notes`. Superseded: `notFound()` is front 63's signal builder, thrown through the `@Result` channel and **not** caught by the boundary (*Current state*, *Mechanism › Navigation signals are not errors*, Step 3). The old front declared it as an external in this file for both targets.

```bp
// Throw a special error to trigger not-found UI
#[@External.Node("onze13/runtime", "notFound")]
#[@External.Erlang("onze13_runtime", "not_found")]
declare fn notFound() -> void;
```

```bp
#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val post = await getPost(params.get("slug"));
    if (post == null) { notFound(); };
    return div([h1([text(post.title)])], attrs: []);
}
```

| Old item | Status |
|---|---|
| `notFound()` declared for both targets (`#[@External.Node]` + `#[@External.Erlang]`) | different decision — front 63 owns it; no host cell in this front |
| Acceptance: throws an error the error boundary catches | reversed — the boundary re-raises signals (`isSignal`) so front 23 turns them into a 404 |
| Note: "`notFound()` throws a special error; the file router catches it and renders `not-found.bp`" | covered — front 23 renders `not-found.bp` on the not-found signal |
| `params: Dict<string, string>` / `params.get("slug")` / `post == null` | absent — new examples take `slug: string` and test `raw == ""` |

### Step 4 — old test, and the commonJS + erlang test target

`1.0.7-beta/07-jhonstart-error-boundaries/README.md § Steps › Step 4 — Tests`. The assertion `html.contains("data-jhonstart-error-boundary")` is replaced by `data-onze-e`; the target list `commonJS + erlang` is narrowed to erlang (*Target*, *Test plan*).

```bp
test "ErrorBoundary renders children" {
    val el = ErrorBoundary(ErrorBoundaryProps(
        fallback: { error -> div([text(error, attrs: [])], attrs: []) },
        children: [div([text("Content", attrs: [])], attrs: [])],
    ));
    val html = renderToString(el);
    assert html.contains("Content");
    assert html.contains("data-jhonstart-error-boundary");
}
```

| Old acceptance | Status |
|---|---|
| Tests pass on commonJS + erlang | narrowed — erlang only; js rules asserted by front 29 |

### Gate — branch name

`1.0.7-beta/07-jhonstart-error-boundaries/README.md § Gate`. Not restated above.

| Old gate item | Status |
|---|---|
| Commit on `fix/jhonstart-error-boundaries` | absent — no branch convention in the new front |
| `error_boundary.bp` in `botopink.json` and `root.bp` | covered — handed to front 94 (Step 5) |
| `botopink test` green · AGENTS.md updated | covered — *Definition of done*, Step 5 |

### Reference rows from 1.0.7 overview/fronts

| Source | Row | Status |
|---|---|---|
| `1.0.7-beta/overview.md` front table | `07-jhonstart-error-boundaries` · **high** · jhonstart · jhonstart-core · "Error boundaries: error.bp, not-found.bp, global-error.bp" | covered — header block + *The three file conventions* |
| `1.0.7-beta/overview.md` Next.js mapping | `error.tsx` → `error.bp` → jhonstart (error boundaries) | covered — conventions table |
| `1.0.7-beta/overview.md` Next.js mapping | `not-found.tsx` → `not-found.bp` → jhonstart (error boundaries) | covered — conventions table |
| `1.0.7-beta/overview.md` app tree | `app/error.bp` — "Global error boundary" (root-segment `error.bp`) | different decision — the root fallback that owns its document is `global-error.bp`; a root-level `error.bp` is not distinguished above |
| `1.0.7-beta/overview.md` app tree | `app/not-found.bp` — "Global 404" | absent — only the per-segment `not-found.bp` is described; root-level 404 dispatch is front 23's |
| `1.0.7-beta/overview.md` app tree | `app/blog/[slug]/not-found.bp` (nested segment) | covered — `examples/not-found-example.bp` |
| `1.0.7-beta/fronts.md` ownership | owns `repository/jhonstart/src/error_boundary.bp`; tests `repository/jhonstart/test/error_boundary_test.bp` | covered — *Owns* |
| `1.0.7-beta/fronts.md` conflict matrix | F07 row: `yes` (parallel-safe) against every other front | covered in spirit — *Does not touch* |
| `1.0.7-beta/fronts.md` phases | Phase 2 (Core features — 7 in parallel): F05 ∥ F06 ∥ F07 ∥ F10 ∥ F11 ∥ F12 ∥ F15 | different decision — *Wave 3*, depends on 28 · 03 · 94 · 17 · 24 · 63 |
| `1.0.7-beta/07-…/README.md` header | Depends on: F04 (jhonstart-server-components); does not touch `suspense.bp` | covered — depends on 28; `src/suspense.bp`/`src/streaming.bp` (30) in *Does not touch* |
