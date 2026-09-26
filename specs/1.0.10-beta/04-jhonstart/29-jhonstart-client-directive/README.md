# Front 29 — Jhonstart Client Directive

**Track:** C jhonstart
**Priority:** high — without a boundary every component is a server component and nothing is interactive; without a *checked* boundary, a secret read on the server reaches the browser and nobody notices
**Target:** js (client) — `client.bp` is pure and its tests run on both rows
**Wave:** 5
**Depends on:** 28 · 30 (payload envelope and the render, read-only) · 68 (soft — build-time enforcement; 29 lands without it) · 94 (element builders used by the examples)
**Owns:** `modules/jhonstart/src/client.bp` — including `islandAttr`, the island marker pair, which front 30's render calls directly and front 68's generated entry imports (decision 113: one definition, in the package that writes the marker) — with `island_runtime.mjs` / `sidecars/jhonstart_island.erl`, and `modules/jhonstart/test/client_test.bp`
**Does not touch:** `element.bp`, `hooks.bp`, `jhonstart-html/src/html.bp` (frozen), `router.bp` (26), `jhonstart-link` (27), `server.bp` (28)
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` · `§ 27. Diretivas` · https://nextjs.org/docs/app/api-reference/directives/use-client · https://nextjs.org/docs/app/guides/server-and-client-boundary

---

## Outcome

`'use client'` has no directive syntax in botopink; the boundary is built from a `@Decl`-first
comptime function and `@emit`. `client.bp` is the boundary's **vocabulary**; what enforces it over
the module graph is front 68's. Everything is reached as `import {…} from "jhonstart"`.

| What | Where | Shape |
|---|---|---|
| The marker | `#[client]` | a comptime fn on a component (`fn … -> Element` or `fn … -> @Component<ElementBase, Element>`). Emits `pub fn __jhClient_<Name>() -> string` — a **pure** function, never a call into a host registry, because an `@emit` fires on every target and a Node-only call would break the erlang server render. The `@emit` precedes the `fail` checks, so a misplaced marker contributes nothing |
| The props rule | `#[clientProps]` | on the props **record**, because `@Decl` does not expose a function's parameters. Whitelist: `string` · `i32` · `f64` · `bool` |
| The island marker | `islandId(n)` · `islandAttrOf(id)` · `islandAttr(n)` | `islandAttrOf` is the one occurrence of `"data-jh-i"`; `islandAttr(0)` is `#("data-jh-i", "i0")`. Front 30's render assigns the ordinals and calls it; front 68's entry imports it |
| The island | `Island(id, component, props)` · `clientMount(island, children)` | the placeholder `<div data-jh-i="i0">` carries the id and nothing else; the component name and props go to the payload's `i` row |
| The payload row | `islandEntry(island)` | `#(id, component, "k=v&k=v")`, encoded with std's `encoding.formStringify` (decision 116 rule 4) |
| The decode | `propsOf(raw)` | pure; `propsOf("")` is `[]` |
| The hole | `serverSlotAttr()` · `serverSlot(children)` | `data-jh-s="1"` — server markup inside an island that the client adopts and must not reconstruct |
| The poison pill | `serverOnly() -> i32` | returns `1`; the value is meaningless, its presence in a module's import list is the signal |
| The browser half | `hydrate()` · `propsFor(name)` | over two dual-target cells, `__jhHydrate` and `__jhClientPropsRaw` (`island_runtime.mjs` / `sidecars/jhonstart_island.erl`), reading `globals().payload`; the erlang twins answer the server's truth — nothing hydrated, no props (pending decision 27-a) |

A client component that activates a hook is `fn … -> @Component<ElementBase, Element>`; one that
activates nothing is `fn … -> Element`. A server component returns the same
`@Component<ElementBase, Element>`, so `#[client]` cannot tell the two apart by return type: the
server/client split is front 68's graph walk. `#[client]` on a fn whose return reflects as `"Task"`
(a `-> @Task<Element>` server component, a loader) is refused.

### The whitelist is four names

`Field.typeName` erases an array's element type (`Array<string>` and `Array<Element>` both reflect
as `"Array"`; `string[]` reflects as `""`), so admitting arrays would admit an array of `Element`s
through the check whose purpose is to refuse exactly that. No array crosses; an array-valued prop is
spelled as an encoded `string`. `Element` is never a prop: server-rendered content reaches a client
component as *children*, inside a `serverSlot`.

### The hole in the payload

A client component may wrap server-rendered children (the Context Provider pattern, `NEXTJS-DOCS.md
§ 7`). Inside `data-jh-i`, that subtree is server markup the client must adopt as-is — re-rendering it
would need the server's data and secrets. The rules, enforced by front 68:

1. A `data-jh-s` subtree is adopted by the client reconciler, never reconstructed.
2. A server component may be a *child* of a client component, never a *prop* of one.
3. A client component may not read request scope: reaching front 28's `request()`, `cookies()` or
   `headers()` from a `#[client]` module is a build failure, not a runtime one.

### What this front is not

`#[client]` is a convention. **Front 29 defines the boundary; front 68 enforces it at build time.**
What is enforced today is four comptime refusals, each located at the annotation (decision 67, no
flag): `#[client]` on a non-`fn`; `#[client]` on a fn whose return is not a component;
`#[clientProps]` on an enum; a field outside the whitelist. What nothing in jhonstart enforces —
module-graph predicates, front 68's:

- that a `#[client]` component's parameter record carries `#[clientProps]` at all (`@Decl` has no
  parameters);
- that no module reachable from a `#[client]` component imports `serverOnly`, or
  `request`/`cookies`/`headers`;
- that the props written into an island's `i` row are the ones the record declares.

Until front 68 lands, a secret read on the server still reaches the browser if it is written into an
island's props.

Form state — `formStatus`, `actionState`, optimistic updates, the form's action binding — is **front
67**'s; those hooks cross this boundary and front 67 applies these rules.

### `hydrate()`

The **per-island** hydrate point: walks every `[data-jh-i]`, finds that island's `i` row and starts
the starter registered for its component in the island starter table, handing it the encoded props
and `commit(html)`; idempotent. It is not the bundle's entry module and it mounts no links or forms —
front 68 generates the entry, which registers the starters, calls `hydrate()` and then front 27's
`linkMount()` and front 67's `formMount()` once each.

**The starter table** is the globals registry's fourth entry, `globals.starters` (`__bp3`), so the
entry writes no `__` name and holds no host cell for it:

```bp
pub fn registerStarter(name: string, start: fn(raw: string, commit: fn(html: string) -> i32) -> i32) -> i32
pub fn registerRouteStarters(pattern: string, load: fn() -> @Task<i32>) -> i32
pub fn registeredStarters() -> string[]
pub fn registeredRouteStarters() -> string[]
```

One starter per component and one loader per route pattern — a second registration fails, naming
it. `hydrate()` calls the loader registered for the payload's matched pattern `r` once and runs again
when it resolves, so a route's islands live in that route's chunk and the bundle splits by route
(`decisions-pending.md` 29-a).

### The front-68 contract

| Front 68 input | Produced by |
|---|---|
| the set of client component names | `__jhClient_<Name>` functions emitted by `#[client]` |
| the island rows | `islandEntry` per island, collected into the payload's `i` key by front 30's render |
| the starter table | `registerStarter` / `registerRouteStarters` into `globals.starters` — the entry names no global |
| the client module graph | the transitive imports of every module declaring one |
| the poison-pill predicate | a module in that graph importing `serverOnly` |
| the request-scope predicate | a module in that graph importing `request`/`cookies`/`headers` from front 28 |

### Delivered

- `#[client]` emits `__jhClient_X` returning `"X"` on `-> Element` and on `-> @Component<ElementBase, Element>`; the emitted marker is a value, not a host call.
- The four refusals (placement on a `type`, a non-component return, an enum, a non-whitelisted field — the message names the field and its type), each by `decl.fail`, located at the declaration, recorded in `client_test.bp`'s header.
- The application site must import `client`/`clientProps` for the emitted name to resolve (recorded in `client_test.bp`); `botopink check` cannot see an emitted name — the gate is `botopink test` (`docs.md` § *`#[client]` — the marker*).
- `renderToString(clientMount(Island(id: "i0", component: "Counter", props: [#("start", "3")]), []))` is `<div data-jh-i="i0"></div>`; children render inside unmodified; `islandEntry` is `#("i0", "Counter", "start=3")`; `serverSlot` emits `data-jh-s="1"` and nothing else — all pure, both rows.
- `hydrate()` idempotent and mounting islands only; `propsFor` of a component with no row is `[]`; `serverOnly()` is `pub` and documented.
- The island pair and slot pair are each spelled once in `client.bp`; `data-jh-on-click` is the handler marker; the props cell is `__jhClientPropsRaw`; no `data-onze-` string under `modules/jhonstart/src/`.
- `client.bp` builds and escapes no payload; front 30's `writePayload` writes `i`.
- `repository/jhonstart/AGENTS.md` § *Front 29 — the client boundary* records the boundary and what it does not check.
- The three language gaps below are rows of `language-gaps.md`. The front's tests are green on both rows.

## Steps

Only the open boxes are listed; everything else is under *Delivered*.

### Step 1 — `#[client]`

Done.

### Step 2 — `#[clientProps]` and the serializable whitelist

Done (the whitelist is the four scalars — § *The whitelist is four names*).

### Step 3 — `clientMount` and `serverSlot`

Done.

### Step 4 — Hydration entry and `server-only`

- [x] every cell in the file is dual-target — `island_runtime.mjs` beside
      `sidecars/jhonstart_island.erl`, whose twin starts nothing and reads back registrations: the
      core is compiled on both rows and a called node-only cell reds its erlang compile
      (`decisions-pending.md` 27-a) — held: `client.bp:328-349`
- [x] the island starter table is `globals.starters` (`__bp3`), filled by `registerStarter` and
      `registerRouteStarters`, one per component / per route, a second failing with its name, on both
      rows — `client_test.bp` "client: registerStarter fills the registry's table…", "client: a second
      starter for one component fails, naming it", "client: registerRouteStarters keeps one loader per
      route pattern", "client: the starter table is the registry's fourth global"; `render_test.bp`
      "render: the four globals come from the registry's declaration order"

### Step 5 — Module wiring and the front-68 contract

- [ ] `pub mod client;` and the `files` entry are handed to front 94; this front edits neither file
- [ ] the four-row table above is in `repository/jhonstart/docs.md` and front 68's README cites it

### Step 6 — Decision 113's spellings

Done.

## Examples

- [`examples/like-button-client-example.bp`](./examples/like-button-client-example.bp) — a like
  button with serializable props, rendered as a placeholder on the server and started in the browser.
- [`examples/theme-provider-example.bp`](./examples/theme-provider-example.bp) — a client provider
  wrapping server-rendered children, and the hole that leaves in the payload.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `@Decl` exposes `fields`, `variants`, `methods`, `returnType` but **not a function's parameters**; and `Field.typeName` carries **no element type** for an array | `#[client]` cannot check a component's props; `#[clientProps]` cannot admit `string[]`/`i32[]` | a second decorator `#[clientProps]` on the props record; arrays spelled as an encoded `string` | `val params: Param[]` on `Decl` for `DeclKind.Fn`, and the full type on `Field` |
| A decorator body cannot call a sibling function | the whitelist predicate is one inlined boolean expression, duplicated if a third marker needs it | inline everything | emit the module's other top-level fns alongside the decorator |
| `botopink check` skips decorator invocation, so every `@emit`ted name reads as unbound | `__jhClient_<Name>` is invisible to `check` | gate on `botopink test`, never on `check` | run decorators under `check` too, or report emitted names as known |

## Test plan

`modules/jhonstart/test/client_test.bp`, both rows, in the gate through
`zig build test-libs -- --lib jhonstart`: `#[client]` on a real component and the emitted
`__jhClient_X()` (only under `botopink test`); `#[clientProps]` on a whitelisted record; the
`clientMount` / `serverSlot` literals and `islandEntry`'s three-tuple; `propsFor` including the empty
case; `hydrate()` idempotent. Wrong placements are compile failures, recorded in the file's header
by expected message. The module-graph predicates are front 68's to test.

## Definition of done

- [ ] `client.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [x] `#[client]` and `#[clientProps]` both enforce placement and both emit located diagnostics
- [x] the emitted marker is a pure function — no `@emit` in this file produces a host call
- [ ] the five-row front-68 contract table is written down and cited by front 68
- [x] the island marker is `data-jh-i` and the props are in the payload's `i` key, per
      `contracts.md § 2`; nothing about the payload is escaped or built here
- [ ] `islandAttr(ordinal)` is exported and is the only place the pair is spelled — front 30's render
      calls it and front 68's entry imports it (decision 113)
- [x] the README states, in *Mechanism*, that 29 without 68 is a convention nobody checks — § *What this front is not*
- [x] all three language gaps appear in a `specs/1.0.10-beta/` spec
- [x] the front's tests are green on its assigned target
