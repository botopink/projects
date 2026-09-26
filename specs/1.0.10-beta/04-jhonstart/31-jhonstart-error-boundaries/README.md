# Front 31 — Jhonstart Error Boundaries

**Track:** C jhonstart
**Priority:** high — without a boundary one throwing component takes the whole response with it
**Target:** erlang (server); the module compiles and its tests run on both rows
**Boundary:** the server catches render errors and emits a fallback plus a digest; the browser catches runtime and transition errors and shows the same fallback. The `ErrorInfo` shape and the digest are defined here and read by front 29's `hydrate()` and by front 17's logger.
**Wave:** 5
**Depends on:** 28 · 03 (content hash) · 94 (`htmlTag`/`body` builders for `global-error.bp`) · 17 (logging, read-only) · 24 (action envelope, read-only) · `01-std/04-routing-lib` Step 7 (`navigation.signalReason`, `isSignalReason`, `signalPrefixes` — the `nav:` reasons of `contracts.md § 5b`, decision 116) · 63 (the server half of the same signals, read-only — never an import)
**Owns:** `repository/jhonstart/modules/jhonstart/src/error_boundary.bp`, its host halves `signal_runtime.mjs` / `sidecars/jhonstart_signal.erl`, `modules/jhonstart/test/error_boundary_test.bp`
**Reference:** `NEXTJS-DOCS.md § 14. Tratamento de Erros` · `§ 3. Estrutura do Projeto` · https://nextjs.org/docs/app/getting-started/error-handling · https://nextjs.org/docs/app/api-reference/file-conventions/error · https://nextjs.org/docs/app/api-reference/file-conventions/not-found · [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only)

---

## Outcome

A render failure is contained to the segment that raised it: a boundary's child is a thunk
returning `@Result`, the boundary branches on its outcome, and the reader sees a fallback carrying
an opaque digest rather than the message. Navigation signals travel the same channel and pass
through every boundary untouched. Upstream's four surfaces (`NEXTJS-DOCS.md § 14`) — a per-segment
fallback (`error.tsx`), a 404 surface (`not-found.tsx`), a root fallback that owns its document
(`global-error.tsx`) and a `reset` — map to the three file conventions and the `data-jh-reset`
marker below.

### The surface — `error_boundary.bp`

```bp
pub type ErrorInfo(message: string, digest: string)

pub type ErrorBoundary(
    id: string,
    fallback: fn(info: ErrorInfo) -> Element,
    child: fn() -> @Result<Element, string>,
)

pub fn digestOf(message: string) -> string            // std's hash.contentHash
pub fn infoFor(message: string) -> ErrorInfo          // message "", the digest — what renders
pub fn serverInfoFor(message: string) -> ErrorInfo    // the message and the SAME digest — the logger's
pub fn wrap(id: string, tree: Element) -> Element     // <div data-jh-e="id">…</div>
pub fn resetAttr(id: string) -> #(string, string)     // #("data-jh-reset", id)
pub fn outcomeOf(b: ErrorBoundary) -> @Result<Element, string>
pub fn renderBoundary(b: ErrorBoundary) -> Element    // a signal is re-raised, never rendered
pub fn renderBoundaryChecked(b: ErrorBoundary) -> @Result<Element, string>   // what front 30's compose calls
pub fn isSignal(message: string) -> bool              // routing's navigation.isSignalReason
pub fn notFoundReason() -> string                     // "nav:not-found"
pub fn redirectReason(url: string) -> string          // "nav:redirect:<url>"
pub fn notFound() -> string                           // raises notFoundReason()
pub fn redirect(url: string) -> string                // raises redirectReason(url)
pub fn catchError(id, fallback, child) -> ErrorBoundary
```

**The catch.** `outcomeOf(b)` calls the thunk **exactly once** through `__jhCapture`, the one host
cell that turns a raise into a value (`signal_runtime.mjs` / `sidecars/jhonstart_signal.erl`,
dual-target): a normal answer passes through, a raised signal reason becomes `Error(reason)`, any
other raise becomes `Error` of its message — so a component that crashed is caught like one that
returned `Error`. The child is a thunk for the same reason front 30's is: a value passed in has
already run, and a boundary that receives a value cannot catch anything that happened while
producing it. `renderBoundaryChecked` answers `Ok` of the wrapped child, `Ok` of the wrapped fallback
for an ordinary failure, and `Error` of the reason, unchanged, for a signal. The `case` arms are arrow
arms (`Ok(tree) -> …;`).

**Digests — the fallback is safe to ship.** `infoFor(message)` never puts the message in the
`ErrorInfo` that reaches the browser: it carries `message: ""` and the digest (front 03's content
hash of the message), while `serverInfoFor` hands the full message plus the same digest to front
17's logger. The reader reports the digest, the operator greps the log for it and finds the stack. A
fallback that shows the message anyway calls `serverInfoFor` — one grep away for a reviewer.

### Navigation signals are not errors

A jhonstart page signals "not found" and "go elsewhere" with **jhonstart's own** `notFound()` and
`redirect(url)`: they raise the `nav:not-found` and `nav:redirect:<url>` reasons of
`contracts.md § 5b` — spelled by `routing`'s `navigation.signalReason`, never by a literal here
(decision 116) — and import nothing from rakun (decisions 113 and 115). A page, layout or template —
each a `fn … -> @Component<ElementBase, Element>` (decision 117 rule 3) — imports `notFound`,
`redirect` and `cookies` (front 28's reader) from `"jhonstart"` only, and cannot `throw` (decision
121): there the signal is the call `notFound();` / `redirect(url);`, which raises through the host
cell (`decisions-pending.md` 31-a). Inside a `-> @Result<…>` thunk — what a boundary's child is — the
form is `throw notFound();`. rakun's front 63 raises the same reasons from route handlers and server
actions; a server action's `redirect` is rakun's, carried to the browser in the action envelope's
`n` and read by front 26's router (decision 117 rule 4).

A boundary re-raises a signal rather than catching it (`isSignal` — the bare prefix `nav:` and an
unknown verb are not signals), so it reaches front 30's render, which translates it (decision 117
rule 1): before the first chunk into `status(404)` and a document whose body is the nearest
`not-found` boundary, or `status(307)` with a `location` header after checking the target; after the
first chunk into `data-jh-g` markup, status 200 (decision 115). In a client-only app front 26's
`clientApp` does the same in the browser. This front owns the boundary type, not the dispatch.

### The three file conventions

| File | Exports | Rendered when | Owns its document? |
|---|---|---|---|
| `error.bp` | `pub fn ErrorPage(info: ErrorInfo) -> Element` | the segment's subtree returns `Error(…)` | no |
| `not-found.bp` | `pub fn NotFound() -> Element` | a not-found signal reaches this segment | no |
| `global-error.bp` | `pub fn GlobalError(info: ErrorInfo) -> Element` | the root segment fails, or no other boundary caught | **yes** — it renders its own `htmlTag` and `body` (front 94) |

All three activate nothing, so each returns bare `Element`. The export is `ErrorPage`, not `Error`:
`Error(error: E)` is the `@Result` variant, and a module-level `pub fn Error` would shadow it in every
`case` arm of that file. The document-root builder is `htmlTag`, not `html` — `html` is the markup
DSL (`jhonstart-html`). Front 22 discovers the files; onze registers them (`jhError`,
`jhNotFound`); front 30's `compose` builds the boundaries. The table and the browser rules are in
`repository/jhonstart/docs.md` § *Error boundaries*.

### The js half — front 29 and front 68

Three rules, contract rather than code here:

1. A `[data-jh-e="ID"]` element is the catch target. A client component that throws during render
   is replaced by the nearest enclosing one's fallback, rendered from the same `ErrorInfo` shape.
2. **Event-handler errors are not caught** (`NEXTJS-DOCS.md § 14`, *Erros em event handlers*). A
   handler is a `data-jh-on-click` attribute naming a handler, so it is outside the boundary's
   `@Result` channel by construction.
3. **`startTransition` errors are caught.** Front 68's runtime wraps a transition and routes a
   failure to the nearest `data-jh-e`, with a digest computed the same way.

### A failing server action is not a render error

An action that fails answers the envelope of `contracts.md § 3` with `ok: false` and a `state` the
form re-renders from — an **expected** error (`NEXTJS-DOCS.md § 14`, *Erros esperados*). It is data,
handled by front 67's form state, and never reaches a boundary. A boundary sees an action only when
the POST itself raised — no envelope at all — and then the digest path applies.

### `reset` / `retry`

A fallback offering a retry puts `resetAttr(id)` (`data-jh-reset="ID"`) on its control; front 29's
`hydrate()` binds it, and the action it performs is front 26's `refresh()` — re-request the route's
payload and re-reconcile. On the server the control is inert; it becomes live at hydration.

`catchError(id, fallback, child)` is `ErrorBoundary(…)` under upstream's name: the curried
`catchError(Fallback)` of upstream does not type in botopink, so it returns the boundary record and
the call site renders it.

## Delivered

- `ErrorInfo`, `ErrorBoundary`, the digest pair `infoFor` / `serverInfoFor` over std's
  `hash.contentHash`, stable across runs and both rows (Step 1).
- The catch through `__jhCapture`, calling the thunk once; the fallback never carries a message;
  `data-jh-e` / `data-jh-reset` registered in `contracts.md § 2` (Step 2).
- Signals pass through `renderBoundaryChecked` unchanged, recognised through `routing`'s
  `signalPrefixes()`; no `"nav:` or `"jhonstart:` literal in the file; `redirect("/a:b")` keeps the
  target whole (Step 3).
- `catchError` documented as the readable spelling of the constructor; the curried form is the
  `language-gaps.md` row "A curried call does not type" (Step 4).
- `docs.md` § *Error boundaries* holds the file-convention table, the `global-error.bp` requirement
  naming front 94, the three browser rules and the `ok: false` rule, which front 67's README agrees
  with (Step 5).
- `global-error.bp` renders its own `htmlTag` and `body`, each exactly once; the event-handler and
  `startTransition` semantics each have a test.
- `repository/jhonstart/AGENTS.md` records the module.

## Steps

Every step's acceptance is `modules/jhonstart/test/error_boundary_test.bp` unless noted; the open
boxes are listed with their step.

### Step 1 — `ErrorInfo`, `ErrorBoundary`, `renderBoundary`

- [x] `infoFor("boom")` carries an empty message and a non-empty digest
- [x] `serverInfoFor("boom")` carries the message and the **same** digest
- [x] `digestOf` is front 03's hash; this file defines no hash of its own
- [x] `digestOf` is stable across runs and across the erlang and js backends

### Step 2 — The catch

- [x] a child returning `Ok` renders the child inside the boundary wrapper
- [x] a child that `throw`s renders the fallback, and the child's markup is absent
- [x] the fallback receives an `ErrorInfo` whose `message` is `""`
- [x] `renderBoundary` calls the thunk exactly once
- [x] the arms are arrow arms (`Ok(tree) -> …;`), not block arms

### Step 3 — Signals pass through

- [x] a child failing with `"nav:not-found"` is not caught — the boundary's result is `Error`
      with the same message
- [x] a child failing with an ordinary message is caught and yields `Ok` of the fallback
- [x] `isSignal` recognises every entry of `routing`'s `signalPrefixes()` — the test iterates that
      function, not a copy of the list — and answers `false` for `"nav:"` and `"boom"`
- [x] no `"nav:` or `"jhonstart:` literal appears in `error_boundary.bp`; the reasons come from
      `routing`'s `navigation`
- [x] `notFound()` is `pub`, raises `"nav:not-found"` (the reason in `contracts.md § 5b`), and
      nothing under `repository/jhonstart/` imports `rakun`
- [x] `redirect("/login")` is `pub`, raises `"nav:redirect:/login"`, passes through
      `renderBoundaryChecked` uncaught, and a target containing `:` is kept whole
      (`redirect("/a:b")` → `"nav:redirect:/a:b"`)

### Step 4 — `catchError`, the functional form

- [x] `catchError` is documented as the readable spelling of the constructor, not a second mechanism
- [x] the curried form is recorded as a language gap, with the expected-failure citation

### Step 5 — The three file conventions, written down

- [x] the table and the browser rules are in `repository/jhonstart/docs.md`
- [x] `global-error.bp`'s requirement to render its own `htmlTag`/`body` is stated, and names front 94
      as the source of both builders
- [ ] this front's `pub mod error_boundary;` line and its `botopink.json` `files` entry are handed
      to front 94, which owns `src/root.bp` and the `files` list and appends in front-number order
- [x] `repository/jhonstart/AGENTS.md` updated

## Examples

- [`examples/segment-error-example.bp`](./examples/segment-error-example.bp) — a dashboard segment
  whose metrics service fails: the `error.bp` a developer writes, the boundary around it, and the
  digest the reader sees.
- [`examples/not-found-example.bp`](./examples/not-found-example.bp) — a `not-found.bp`, and a
  boundary proving a not-found signal passes through instead of being swallowed.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Curried calls parse but do not type — `adder(3)(4)` reports `unbound variable ''` (`tests/language/expected-failures.txt`) | `catchError(Fallback)` cannot return a component the way upstream does | `catchError(id, fallback, child) -> ErrorBoundary`, rendered by the caller | type a call whose callee is a returned function |
| No assignment to a `self` field; a record has no in-place update | a boundary cannot record "I already failed once" to suppress a retry loop; the retry budget lives in front 29's runtime instead | host-side state | a `var` field or a copy-update expression |

Both are rows of `language-gaps.md`.

## Test plan

`modules/jhonstart/test/error_boundary_test.bp`, run by `botopink test` in `modules/jhonstart/` on
both rows and by `zig build test-libs -- --lib jhonstart`. It asserts: `Ok` renders inside the
wrapper and `Error` renders the fallback and not the child; the fallback's `ErrorInfo` has an empty
`message` and a non-empty `digest`; `infoFor` and `serverInfoFor` agree on the digest and disagree
on the message; a signal passes through `renderBoundaryChecked` uncaught and an ordinary message does
not; a child rendering a `data-jh-on-click` attribute renders `Ok` with the handler name intact (the
handler is outside the channel); the wrapper carries `data-jh-e="ID"`, the anchor front 68 routes a
transition failure to; the thunk is called exactly once.

The js row of rules 1–3 of *The js half* is front 29's `test/client_test.bp` against markup produced
here, and the transition routing itself is front 68's test; if that coverage is absent, this front's
browser contract is untested and the milestone treats it as a red rather than as done.

## Definition of done

- [ ] `error_boundary.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [x] `renderBoundary` catches with a `case` over `@Result` — the only catching mechanism the
      language has — and a test proves a throwing child does not reach the output
- [x] no client-visible `ErrorInfo` ever carries a message; a test asserts it
- [ ] the digest is front 03's hash and correlates with front 17's log line — open: the two schemes
      differ. `digestOf(message)` is std's `contentHash` of the message (8 hex); rakun's
      `errorDigest` is the first 16 hex of std's `strongHash` over `module|errorClass|message|topFrames`
      (`rakun-logging/src/digest.bp`), so no log line carries the digest a fallback shows, and the
      render calls no logger. Which side owns the scheme, and how the render reaches a logger it may
      not import, is `decisions-pending.md` 31-b
- [x] every signal passes through, recognised by `routing`'s `isSignalReason` — the one vocabulary
      rakun front 63 also imports (decision 116); the test asserts through `signalPrefixes()`
- [ ] `notFound` and `redirect` are jhonstart's, and every page example in the milestone imports
      them (and `cookies`) from `"jhonstart"` (decision 115); jhonstart turns them into a status or
      markup itself — no onze or rakun code translates a page signal (decision 117)
- [x] the event-handler and `startTransition` semantics each have a test
- [x] `data-jh-e` and `data-jh-reset` are registered in `contracts.md § 2`
- [x] an action envelope with `ok: false` is documented as data, not as something a boundary catches,
      and front 67's README agrees — `docs.md` § *Error boundaries*; 67's README § *The envelope, and who owns which half*
- [x] `global-error.bp` renders its own document root with front 94's `htmlTag` and `body`, and a
      test asserts both tags are present exactly once
- [x] no example or step in this front calls `html(...)` as a constructor — that name is the markup
      DSL
- [x] both language gaps appear in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target — on both rows
