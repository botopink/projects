# Front 29 — Jhonstart Client Directive

**Track:** C jhonstart
**Priority:** high — without a boundary every component is a server component and nothing is interactive; without a *checked* boundary, a secret read on the server reaches the browser and nobody notices
**Target:** js (client)
**Wave:** 3
**Depends on:** 28 · 23 (payload envelope, read-only) · 68 (soft — build-time enforcement; 29 lands without it) · 94 (element builders used by the examples)
**Owns:** `repository/jhonstart/src/client.bp`, `repository/jhonstart/test/client_test.bp`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/root.bp` and `botopink.json` (front 94)
**Reference:** `NEXTJS-DOCS.md § 7. Server e Client Components` · `§ 27. Diretivas` · https://nextjs.org/docs/app/api-reference/directives/use-client · https://nextjs.org/docs/app/guides/server-and-client-boundary
**Replaces:** `1.0.7-beta/05-jhonstart-client-directive`

---

## Problem

jhonstart has hooks and it has an SSR renderer, and nothing tells them apart. `hooks.bp` says so in
its own header: the bodies "model the FIRST render (SSR). `state` yields its initial value, `memo`
computes eagerly, `effect` is a no-op" (`hooks.bp:6-9`). A component calling `use state(0)` renders
once on the server, emits its initial markup, and then stops — there is no record anywhere that this
component needs to be shipped to the browser and started again. `jhonstart-counter`'s own header
records the consequence: "`use state` lowers to the client runtime's `useState` (React), so a
`use`-prefixed component can't be rendered in a plain `botopink test` process."

So the boundary is invisible in three directions at once. The build does not know which modules
belong in the browser bundle. The renderer does not know which subtrees to leave as placeholders.
And nothing checks the rule that actually causes production incidents: **props that cross the
boundary must be serializable** (`NEXTJS-DOCS.md § 7`, *Regras fundamentais*, rule 2). A function
passed as a prop, or a record holding a database handle, fails at hydration time with an error that
points at the wrong file.

botopink has no directive syntax. `'use client'` is a string literal at the top of a file and means
nothing to the parser, and the milestone forbids compiler changes. The mechanism has to be built out
of what annotation processing already gives: a `@Decl`-first comptime function and `@emit`.

## Current state

- No boundary mechanism of any kind in `repository/jhonstart/src/`. `root.bp:15-17` declares three
  modules; none of them is `client`.
- `hooks.bp:30-60` — five hooks with SSR-only bodies, no marker distinguishing them from a server
  component's helpers.
- `repository/rakun/src/decorators.bp` is the working precedent: fifteen decorators, each
  `pub fn name(comptime decl: @Decl, …)`, each enforcing placement with `decl.fail` and contributing
  wiring with `@emit`.
- The constraints that shape this front, all verified: a decorator body **cannot call sibling
  functions** (`decorators.bp:44-46` — which is why rakun duplicates the same injection block six
  times); a `//` comment inside a comptime body breaks the emitted line; `@emit` runs under
  `botopink test` but `botopink check` skips decorator invocation entirely, so `check` reports
  emitted names as unbound.
- `@Decl` exposes `kind`, `name`, `fields`, `variants`, `methods`, `returnType`, `annotations`
  (`libs/std/src/builtins.d.bp:466-477`). **It does not expose a function's parameters.** That one
  omission decides the shape of this front — see *Language gaps*.

## Mechanism

Next.js `'use client'` does two things: it marks a module as the boundary, and it makes everything
imported from that module part of the client bundle (`NEXTJS-DOCS.md § 7`, rule 1). jhonstart splits
those two into the two places they belong.

### The marker — a decorator, at comptime

`#[client]` is an ordinary comptime function taking `@Decl` first. It checks placement and emits one
pure declaration:

```bp
pub fn client(comptime decl: @Decl) {
    @emit("pub fn __jhClient_" + decl.name + "() -> string { return \"" + decl.name + "\"; }");
    if (decl.kind != DeclKind.Fn) decl.fail("#[client] must annotate a function");
    if (decl.returnType != "Element") decl.fail("#[client] must annotate a component returning Element");
}
```

The emitted declaration is a **pure function returning a string**, not a call into a runtime
registry. That is deliberate and it is the difference between this design and the 1.0.7 draft, which
emitted a call to an `#[@External.Node]` cell. An `@emit` fires on every target, so emitting a call
into a Node-only cell would make every `#[client]` component fail to link during the erlang server
render — the exact case the boundary exists to support. A pure marker links everywhere and carries
the same information.

The `@emit` comes **before** the `fail` checks, matching rakun's ordering: the contributions are
discarded when the placement check fails, so only correctly placed declarations wire up
(`decorators.bp:36-40`).

### The props — a second decorator, on the record

The serializability rule is checked where the type information actually is. A client component takes
**one** record parameter, and that record carries `#[clientProps]`:

```bp
pub fn clientProps(comptime decl: @Decl) {
    if (decl.kind != DeclKind.Type) decl.fail("#[clientProps] must annotate a type");
    if (decl.variants.length > 0) decl.fail("#[clientProps] must annotate a record, not an enum");
    decl.fields.forEach({ f ->
        val ok = f.typeName == "string" || f.typeName == "i32" || f.typeName == "f64" || f.typeName == "bool" || f.typeName == "string[]" || f.typeName == "i32[]";
        if (!ok) decl.fail("a client prop must be serializable; '" + f.name + "' is " + f.typeName);
    });
}
```

The whitelist is closed on purpose: a type not on it is refused rather than guessed at. `Element` is
not on it — a client component receives server-rendered children as *children*, never as a prop, for
the reason in *The hole in the payload* below.

Splitting the marker in two is not an aesthetic choice. `@Decl` cannot see a function's parameters,
so `#[client]` alone can check nothing about props. The record is the only place the information
exists.

### The placeholder — an island, and the format is front 23's

During the server render a client component contributes an **island**. The marker is pinned in
`contracts.md § 2`: `<div data-onze-i="i0">`. The component name and the encoded props do **not**
live on the element — they live in the payload's `i` array as `[id, component, props]`, which is how
the client finds the island without parsing attributes off the DOM.

```bp
pub type Island(
    id: string,
    component: string,
    props: Array<#(string, string)>,
)

pub fn clientMount(island: Island, children: Children) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: children,
        attrs: [#("data-onze-i", island.id)],
    );
}

pub fn islandEntry(island: Island) -> #(string, string, string) {
    return #(island.id, island.component, querystring.stringify(island.props));
}
```

Front 23 assigns the ids (`i0`, `i1`, … in render order), collects one `islandEntry` per island into
the payload's `i` key, and escapes the whole script per `contracts.md § 2` — this front does not
escape the payload and does not build it.

`clientMount` touches no host cell, so it renders identically during front 23's BEAM pass and during
a client re-render. The props encoding is `querystring.stringify` — the same `k=v&k=v` string
fronts 26 and 28 use. One encoder for the whole milestone.

Putting the props in the payload rather than on the element is what makes the boundary auditable:
every crossing value is in one place, in render order, and front 68 can walk it.

### The hole in the payload — the subtle part

A client component may wrap server-rendered children: the Context Provider pattern
(`NEXTJS-DOCS.md § 7`, *Padrão: Context Provider*) puts a `'use client'` provider in the root layout
with the entire server tree inside it. The provider is client code; its children are not.

The payload therefore has a **hole**: inside `data-onze-i`, the subtree is server markup that the
client must adopt as-is and must not re-render, because re-rendering it would need the server's data
and the server's secrets. jhonstart marks the hole explicitly rather than leaving it implicit:

```bp
pub fn serverSlot(children: Children) -> Element {
    return Element(tag: "div", value: "", children: children, attrs: [#("data-onze-s", "1")]);
}
```

`data-onze-s` is this front's one addition to the `data-onze-` marker family, and it is registered
in `contracts.md § 2` alongside the island and hole markers rather than invented locally.

The rules that follow from it, and that front 68 enforces:

1. A `data-onze-s` subtree is adopted by the client reconciler, never reconstructed.
2. A server component may be a *child* of a client component. It may never be a *prop* of one —
   which is why `Element` is off the serializable whitelist.
3. A client component may not read request scope. `request()`, `cookies()` and `headers()` are front
   28's server functions and reaching them from a `#[client]` module is a build failure, not a
   runtime one.

### `server-only` — the poison pill

`import 'server-only'` upstream is a module that exists only to fail the build when it lands in the
client graph (`NEXTJS-DOCS.md § 7`, *Protegendo código server-only*). jhonstart's is the same trick
in botopink's vocabulary: `client.bp` exports a marker function, a module that touches the server
imports it, and front 68 fails the build when a module reachable from a `#[client]` component
imports it.

```bp
pub fn serverOnly() -> i32 { return 1; }
```

The value is never used. Its presence in a module's import list is the signal.

### What this front is not

`#[client]` is a convention. **Front 29 defines the boundary; front 68 enforces it at build time.**
29 without 68 is a convention nobody checks: the decorator rejects a non-serializable field of a
record it was applied to, and nothing else. Every rule above about "may not" is a rule front 68
computes over the module graph. This README says so rather than implying the decorator is a
sandbox.

Form state — `formStatus`, `actionState`, optimistic updates and the `form` element's action
binding — is **front 67**'s. Those hooks are client hooks and they cross this boundary, so front 67
applies these rules; it does not restate them.

## Steps

### Step 1 — `#[client]`

```bp
// src/client.bp
import {Element} from "element";
import {querystring} from "std";

pub fn client(comptime decl: @Decl) {
    @emit("pub fn __jhClient_" + decl.name + "() -> string { return \"" + decl.name + "\"; }");
    if (decl.kind != DeclKind.Fn) decl.fail("#[client] must annotate a function");
    if (decl.returnType != "Element") decl.fail("#[client] must annotate a component returning Element");
}
```

The body calls no sibling function and contains no `//` comment — both are hard constraints on a
decorator body.

**Acceptance:**
- [ ] `#[client]` on `#[@context] fn X() -> Element` emits `__jhClient_X` returning `"X"`
- [ ] `#[client]` on a `type` fails with the placement message
- [ ] `#[client]` on a fn returning `@Future<Element>` fails — a server component is not a client one
- [ ] the emitted name is reachable at the application site, which must therefore import `client`;
      the test file records that import requirement the way `rakun/test/server_test.bp:13-18` does
- [ ] `botopink check` is documented as unable to see the emitted name; the gate is `botopink test`

### Step 2 — `#[clientProps]` and the serializable whitelist

The whitelist, exactly: `string`, `i32`, `f64`, `bool`, `string[]`, `i32[]`.

**Acceptance:**
- [ ] a record of whitelisted fields passes
- [ ] a field typed `Element` fails, and the message names the field and its type
- [ ] a field typed with a function type fails
- [ ] an enum-shaped `type` fails with the record placement message
- [ ] the failing message is produced by `decl.fail`, so it is located at the declaration

### Step 3 — `clientMount` and `serverSlot`

**Acceptance:**
- [ ] `renderToString(clientMount(Island(id: "i0", component: "Counter", props: [#("start", "3")]), []))`
      is `<div data-onze-i="i0"></div>` — the id only; the component and props are payload, not markup
- [ ] children passed to `clientMount` render inside the placeholder, unmodified
- [ ] `islandEntry` produces `#("i0", "Counter", "start=3")` — the payload `i` row for that island
- [ ] `serverSlot` emits `data-onze-s="1"` and nothing else
- [ ] neither function reaches a host cell; both render on erlang and js

### Step 4 — Hydration entry and `server-only`

```bp
#[@External.Node("jhonstart/client-runtime", "hydrate")]
pub declare fn hydrate() -> i32;

#[@External.Node("jhonstart/client-runtime", "islandProps")]
declare fn __onzeClientPropsRaw(name: string) -> string;

pub fn propsFor(name: string) -> Array<#(string, string)> {
    return querystring.parse(__onzeClientPropsRaw(name));
}

pub fn serverOnly() -> i32 { return 1; }
```

`hydrate()` is the **per-island** hydrate point: it walks every `[data-onze-i]`, decodes that
island's props from the payload's `i` row and starts the component. It is not the bundle's entry
module and it does not mount links or forms — front 68 generates the entry, which calls `hydrate()`
and then front 27's `__onzeLinkMount()` and front 67's `__jhFormMount()` once each.

**Acceptance:**
- [ ] every cell in the file is `#[@External.Node]`; there is no `#[@External.Erlang]` cell
- [ ] `propsFor` of a component with no props returns `[]`
- [ ] `hydrate()` is idempotent
- [ ] `hydrate()` mounts islands only; it calls no link or form mount, and front 68's README says
      its generated entry does
- [ ] `serverOnly()` is `pub`, returns `1`, and its doc comment says the value is meaningless and the
      import is the signal

### Step 5 — Module wiring and the front-68 contract

front 94 owns `src/root.bp` and `botopink.json`'s `files` list; this front hands it the line(s) below rather than editing either file, and front 94 appends in front-number order: `pub mod client;` and `client.bp`. The contract handed to front 68 is written down in
`repository/jhonstart/docs.md`:

| Front 68 input | Produced by |
|---|---|
| the set of client component names | `__jhClient_<Name>` functions emitted by `#[client]` |
| the island rows | `islandEntry` per island, collected into the payload's `i` key by front 23 |
| the client module graph | the transitive imports of every module declaring one |
| the poison-pill predicate | a module in that graph importing `serverOnly` |
| the request-scope predicate | a module in that graph importing `request`/`cookies`/`headers` from front 28 |

**Acceptance:**
- [ ] `pub mod client;` and the `files` entry are handed to front 94; this front edits neither file
- [ ] the four-row table above is in `repository/jhonstart/docs.md` and front 68's README cites it
- [ ] `repository/jhonstart/AGENTS.md` updated in the same commit

## Examples

- [`examples/like-button-client-example.bp`](./examples/like-button-client-example.bp) — a like
  button with serializable props, rendered as a placeholder on the server and started in the browser.
- [`examples/theme-provider-example.bp`](./examples/theme-provider-example.bp) — a client provider
  wrapping server-rendered children, and the hole that leaves in the payload.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| `@Decl` exposes `fields`, `variants`, `methods`, `returnType` but **not a function's parameters** (`libs/std/src/builtins.d.bp:466-477`); `Param` exists but is only reachable through `Method.params` | `#[client]` cannot check that a component's props are serializable | a second decorator `#[clientProps]` on the props record, where `decl.fields` is available | `val params: Param[]` on `Decl`, populated for `DeclKind.Fn` |
| A decorator body cannot call a sibling function — only the decorator itself is emitted into the eval script (`repository/rakun/src/decorators.bp:44-46`) | the whitelist predicate is one inlined boolean expression instead of a named helper, and would be duplicated if a third marker needed it | inline everything | emit the module's other top-level fns alongside the decorator |
| `botopink check` skips decorator invocation, so every `@emit`ted name reads as unbound | `__jhClient_<Name>` is invisible to `check` | gate on `botopink test`, never on `check` | run decorators under `check` too, or report emitted names as known |
| Declared parameter defaults are never applied | every `Element` builder call in both examples spells `attrs: []` | write every argument | apply the declared default when an argument is omitted |

## Test plan

`repository/jhonstart/test/client_test.bp`, run by `botopink test --target commonJS` from
`repository/jhonstart`, and in the ecosystem gate by
`zig build test-libs -- --target commonJS --lib jhonstart`.

Assertions:

1. `#[client]` applied to a real component, and the emitted `__jhClient_X()` returning `"X"` —
   this is the assertion that proves `@emit` fired, and it only works under `botopink test`.
2. `#[clientProps]` on a record of whitelisted fields, applied and compiling.
3. `clientMount` markup, exact string, with and without children, and `islandEntry`'s three-tuple —
   the literal both sides assert, per `contracts.md`'s rule that a contract only one side tests is a
   contract that drifts.
4. `serverSlot` markup.
5. `propsFor` decoding, over a stubbed cell, including the empty case.

Wrong-placement cases cannot be expressed as a runtime `assert` — a rejected decorator is a compile
failure, not a value. They are recorded in the test file as comments naming the expected message,
the way `repository/rakun/test/di_test.bp:14-16` does, and the compile-failure coverage lives in the
compiler's own suites.

The erlang row is not this front's gate, but `clientMount` and `serverSlot` are pure and do render
there; one assertion covers that, because a client placeholder that did not render on the server
would be a boundary that never starts.

## Definition of done

- [ ] `client.bp` in the build tree, its `root.bp` and `files` lines handed to front 94
- [ ] `#[client]` and `#[clientProps]` both enforce placement and both emit located diagnostics
- [ ] the emitted marker is a pure function — no `@emit` in this file produces a host call
- [ ] the five-row front-68 contract table is written down and cited by front 68
- [ ] the island marker is `data-onze-i` and the props are in the payload's `i` key, per
      `contracts.md § 2`; nothing about the payload is escaped or built here
- [ ] the README states, in *Mechanism*, that 29 without 68 is a convention nobody checks
- [ ] all four language gaps appear in a `specs/1.0.10-beta/` spec
- [ ] the front's tests are green on its assigned target

## Carried from 1.0.7-beta F05 jhonstart-client-directive

Items of the 1.0.7 draft not restated above, quoted so nothing is lost; where the milestone decided differently the 1.0.9 decision stands and the old text is kept for the record.

### Current state — the `use` prefix and context-inference

`1.0.7-beta/05-jhonstart-client-directive/README.md § Current state`

> The `use` prefix is legal in any `-> Element` body (context-inference).

Superseded by decision 88: `use` is legal in a `#[@context]` body whose return type owns the context, not in *any* `-> Element` body — a component without the annotation is an ordinary function and a `use` in it is `use-without-context-effect`. The rule is [`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md) § *The rule for libraries*; front 28's *Language gaps* carries the server-component half.

### Old inline examples — zero-param `Counter` and direct client call from a server component (different decision)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Exemplos em bp`, `§ Mechanism`

Client component with state:

```bp
#[client]
#[@context]
pub fn Counter() -> Element {
    val count = use state(0);
    return div([
        p([text("Count: " + count.value.toString())]),
        button([text("+1")], attrs: [#("onClick", "increment")]),
    ], attrs: []);
}
```

Mixing server and client:

```bp
#[@future]
pub fn DashboardPage() -> @Future<Element> {
    return div([
        Counter(),           // client component
        await RecentPosts(), // server component
    ], attrs: []);
}
```

The *Mechanism* variant of `Counter` (`attrs: []` on every builder, `"count: "` / `"increment"` labels):

```bp
#[client]
#[@context]
pub fn Counter() -> Element {
    val c = use state(0);
    return div([
        p([text("count: " + c.value.toString(), attrs: [])], attrs: []),
        button([text("increment", attrs: [])], attrs: [#("onClick", "increment")]),
    ], attrs: []);
}
```

| Old | 1.0.9 decision (above) |
|---|---|
| client component takes no parameter | one record parameter carrying `#[clientProps]` (*Mechanism § The props*) |
| `#("onClick", "increment")` attribute | `data-onze-on-click` handler name bound by the client runtime (`like-button-client-example.bp`) |
| server component calls `Counter()` directly | server component emits the island via `clientMount(Island, children)`; the component name lives in the payload's `i` row (*Mechanism § The placeholder*) |
| `await RecentPosts()` inside an array literal | `await` at statement level only (front 28 *Step 4*) |
| `text("…")` without `attrs` | `attrs: []` on every builder (*Language gaps*, row 4) |

### Mechanism — "serialized as references" wording

`1.0.7-beta/05-jhonstart-client-directive/README.md § Mechanism`

> - The decorator is a comptime fn that emits metadata
> - At runtime, client components are serialized as references (not rendered HTML)
> - The client runtime hydrates them with real interactivity
>
> Since botopink has no `'use client'` directive syntax, we use a decorator: `#[client]`.

Restated above as the island + payload row + `hydrate()`; kept for the original phrasing.

### Step 1 — `#[client]` emitting a `val` flag (different decision)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Step 1 — #[client] decorator`

```bp
// src/client.bp
pub fn client(comptime decl: @Decl) {
    if (decl.kind != DeclKind.Fn) decl.fail("#[client] must annotate a function");
    // Emit metadata: this function is a client component
    @emit("val __jhonstart_client_" + decl.name + " = true;");
}
```

Old acceptance (restated in *Step 1*): decorator compiles; applicable to `fn(...) -> Element`; fails with a diagnostic on a non-function.

| Old | 1.0.9 decision (above) |
|---|---|
| emits `val __jhonstart_client_<name> = true;` | emits `pub fn __jhClient_<Name>() -> string { return "<Name>"; }` — a pure function testable as `__jhClient_X() == "X"` |
| `fail` before `@emit` | `@emit` before the `fail` checks, matching rakun's ordering (`decorators.bp:36-40`) |
| no return-type check | `decl.returnType != "Element"` fails — a `@Future<Element>` fn is a server component |
| `//` comment inside the decorator body | forbidden — a `//` comment inside a comptime body breaks the emitted line (*Current state*) |

### Step 2 — runtime `isClientComponent` registry (different decision)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Step 2 — Client component detection`

```bp
// Runtime check: is a component a client component?
#[@External.Node("onze13/runtime", "isClientComponent")]
#[@External.Erlang("onze13_runtime", "is_client_component")]
declare fn isClientComponent(name: string) -> bool;
```

Old acceptance:
- Host cells declared for both targets
- Returns true for `#[client]`-annotated components

Decided differently: no runtime registry and no `#[@External.Erlang]` cell in `client.bp`. The set of client component names is the emitted `__jhClient_<Name>` functions, read by front 68's build-time graph walk (*Step 5* contract table). An `@emit` that called a Node-only cell would fail to link during the erlang server render (*Mechanism § The marker*).

### Step 3 — `renderClientComponent` placeholder with name and props on the element (different decision)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Step 3 — SSR behavior for client components`

> When `renderToString` encounters a client component:
> - Renders a placeholder `<div data-jhonstart-client="Counter"></div>`
> - The client runtime replaces this with the real interactive component

```bp
// In renderToString (or a wrapper)
pub fn renderClientComponent(name: string, props: string) -> Element {
    return Element(
        tag: "div",
        value: "",
        children: [],
        attrs: [
            #("data-jhonstart-client", name),
            #("data-jhonstart-props", props),
        ],
    );
}
```

Old acceptance:
- Client components render as placeholder divs during SSR
- Placeholder carries component name and props

| Old | 1.0.9 decision (above) |
|---|---|
| `renderClientComponent(name: string, props: string)` | `clientMount(island: Island, children: Children)` + `islandEntry(island)` (*Mechanism § The placeholder*, *Step 3*) |
| `data-jhonstart-client` / `data-jhonstart-props` attributes | `data-onze-i="<id>"` only, per `contracts.md § 2`; component name and encoded props go to the payload's `i` row `[id, component, props]` |
| props as an opaque `string` | `Array<#(string, string)>` encoded with `querystring.stringify` |
| no children | children render inside the placeholder; `serverSlot` marks the server-owned hole (`data-onze-s`) |

### Step 4 — test asserting only that the decorator compiles (different decision)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Step 4 — Tests`

```bp
test "#[client] decorator can be applied to a component" {
    #[client]
    fn TestComponent() -> Element {
        return div([text("hello", attrs: [])], attrs: []);
    }
    // The decorator emits metadata; we verify it compiles
    assert true;
}
```

Old acceptance:
- Tests pass on commonJS + erlang

Decided differently: the test asserts the emitted `__jhClient_X()` returns `"X"` (proves `@emit` fired; only under `botopink test`); gate is `botopink test --target commonJS`, with one erlang assertion for the pure `clientMount`/`serverSlot` (*Test plan*).

### Gate — branch name

`1.0.7-beta/05-jhonstart-client-directive/README.md § Gate`

- Commit on `fix/jhonstart-client-directive`

### Blast radius

`1.0.7-beta/05-jhonstart-client-directive/README.md § Blast radius`

> - New file `client.bp` — no changes to existing files
> - Consumers can opt-in to client components with `#[client]`

Restated by *Does not touch* and *Mechanism*; kept for the record. Above adds `client_test.bp`, the `docs.md` contract table and the AGENTS.md entry as the front's footprint.

### Notes — hydration out of scope; future native directive (different decision / absent)

`1.0.7-beta/05-jhonstart-client-directive/README.md § Notes`

> - The actual client-side hydration (replacing the placeholder with a real React-like component) is a client runtime concern — not implemented here.
> - `#[client]` is a convention, not a compiler directive. The compiler core remains unaware.
> - Future: if botopink adds a `'use client'` directive syntax, this front's decorator can be deprecated in favor of the native syntax.

| Old | 1.0.9 decision (above) |
|---|---|
| hydration not implemented here | `hydrate()` and `propsFor` are declared here as `#[@External.Node("jhonstart/client-runtime", …)]` cells; front 68 generates the bundle entry that calls them (*Step 4*) |
| convention, compiler unaware | restated: "29 defines the boundary; 68 enforces it at build time" (*What this front is not*) |
| deprecate in favor of a future `'use client'` syntax | not restated; the milestone forbids compiler changes (*Problem*) |

### Reference rows from 1.0.7 overview/fronts

| Source | Row | Status above |
|---|---|---|
| `overview.md` front table | `05-jhonstart-client-directive` · **high** · repo `jhonstart` · module `jhonstart-core` · "'use client' directive: boundary between server and client modules" | priority and repo restated; module column `jhonstart-core` not restated |
| `overview.md § Mapeamento Next.js → onze13` | 'use client' directive → `#[client]` decorator / convention · jhonstart | restated in *Mechanism § The marker* and *What this front is not* |
| `fronts.md § Ownership` | F05 · jhonstart · jhonstart-core · `repository/jhonstart/src/client.bp` · `repository/jhonstart/test/client_test.bp` | both paths restated in *Owns* |
| `fronts.md § Conflict Matrix` | F05 row: `yes` against every other front, no conflict note | not restated (the 1.0.10 dependency list replaces the matrix) |
| `overview.md § Order`, `fronts.md § Order` | Phase 2 (core features, 7 in parallel): F05 · F06 · F07 · F10 · F11 · F12 · F15, after F04 | replaced by *Wave 3*, depends on 28 · 23 · 68 (soft) · 94 |
