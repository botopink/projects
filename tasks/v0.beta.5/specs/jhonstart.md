# jhonstart — a React/Next-style UI & app framework, written in botopink

**Slug**: jhonstart        <!-- branch task/jhonstart + worktree .tasks/jhonstart/ -->
**Depends on**: use-await-prefix, async-generators (compiler prerequisites — see Notes) <!-- context-inference already ✅ -->
**Files**: libs/jhonstart/ (new package: botopink.json, AGENTS.md, docs.md, src/{element,dom,hooks,render,router,server}.d.bp + src/{fragment,html,link}.bp), examples/jhonstart-counter/, examples/jhonstart-todo/, examples/jhonstart-app/
**Touches docs**: libs/AGENTS.md (add the package row), libs/jhonstart/AGENTS.md (new), examples/AGENTS.md (add the three demos), docs.md (a "Frameworks" pointer), README.md (feature mention)
**Status**: pending

> **Goal**: a first-party botopink framework that is to botopink what **React +
> Next.js** are to JavaScript — but built *on the language's own primitives*, not
> bolted on. The component model is plain functions returning `Element`; the hook
> model is the existing `@Context<Element, _>` capability gated by the `use`
> prefix; data loading is `*fn` + `await` gated by `@Future`; server rendering is
> the `Http` ContextBase. The framework adds **no new compiler features** — it is
> a *consumer* of `expr-templates`, `context-inference`, `use-await-prefix` and
> `async-generators`. Everything jhonstart needs already exists in the language
> design; this spec assembles it into a library + canonical examples.
>
> Two layers in **one** package `libs/jhonstart/`:
>
> | Layer | Analog | ContextBase | Surface |
> |---|---|---|---|
> | **core** (`element`, `dom`, `hooks`, `render`) | React | `Element` | components, hooks, DOM builders, client mount |
> | **app** (`router`, `server`) | Next.js | `Http` | file-based routing, layouts, server components, SSR/data loading |
>
> Design rule (inherited from the language): library `.d.bp` files declare
> **signatures only**; the host runtime intrinsics (`state`, `effect`, `div`, …)
> bind to a JS/Erlang runtime through `#[@external(...)]`. Composite ergonomics
> (`Fragment`, `Link`, the `html` authoring DSL, custom hooks) are ordinary `.bp`
> built *on* those intrinsics — no privileged access.

## Target syntax

A **component** is any `fn(...) -> Element`. PascalCase by convention (matching
`Button`/`Dashboard`/`Page1` already used across the codebase). A **hook** is any
function whose return implements `@Context<Element, _>`; the `use` prefix is only
legal inside a `-> Element` (or `-> @Context<Element, _>`) body — enforced today
by `context-inference`.

```bp
import { div, p, button, state, effect } from "jhonstart";

// A component: plain function, returns Element.
fn Counter() -> Element {
    val {value, set} = use state(0);            // hook: @Context<Element, {value, set}>
    use effect({ -> log("count = " + value) }); // void hook: expression statement

    div {
        [
            p { "count: " + value },
            button({ -> set(value + 1) }) { "+" },
            button({ -> set(value - 1) }) { "-" },
        ]
    }
}
```

Grammar: **none added.** Every construct above already parses:
- trailing-lambda children — the existing trailing-lambda block (`docs.md` §Lambdas);
- `use <expr>` / `await <expr>` — prefix operators from `use-await-prefix`;
- `*fn` server loaders — from `async-generators`;
- `html """…"""` authoring — tagged-call + `@Expr<Element>` from `expr-templates`.

### Core surface (`.d.bp`, intrinsics bound via `#[@external]`)

```bp
// element.d.bp — the UI node; the ContextBase for every client hook.
pub interface Element {
    fn key(self: Self) -> ?string                 // reconciliation key (optional)
}

// A list of child elements. A bare `string` coerces to a text node; a bare
// `Element` coerces to a one-element list (fragment-of-one).
pub interface Children { }                          // = Element[]

// dom.d.bp — host intrinsics, one per tag (external-bound, no body).
#[@external(node, "jhonstart/runtime", "el")]
pub fn div(children: fn() -> Children) -> Element
pub fn span(children: fn() -> Children) -> Element
pub fn p(children: fn() -> Children) -> Element
pub fn h1(children: fn() -> Children) -> Element
pub fn ul(children: fn() -> Children) -> Element
pub fn li(children: fn() -> Children) -> Element
pub fn button(onClick: fn(), children: fn() -> Children) -> Element
pub fn input(value: string, onInput: fn(next: string)) -> Element
pub fn text(value: string) -> Element              // explicit text node

// hooks.d.bp — every hook returns @Context<Element, _>; `use`-only.
pub fn state<T>(initial: T) -> @Context<Element, {value: T, set: fn(next: T)}>
pub fn effect(run: fn(), deps: any[]) -> @Context<Element, {}>
pub fn memo<T>(compute: fn() -> T, deps: any[]) -> @Context<Element, T>
pub fn ref<T>(initial: T) -> @Context<Element, {current: T}>
pub fn reducer<S, A>(reduce: fn(s: S, a: A) -> S, initial: S)
    -> @Context<Element, {state: S, dispatch: fn(action: A)}>

// render.d.bp — client entry + SSR entry.
pub fn mount(app: Element, selector: string)       // client: attach to a DOM node
*fn renderToString(app: Element) -> @Future<string> // SSR: serialize to HTML
```

### App surface (`.d.bp`, Next-style)

```bp
// router.d.bp — Element-context navigation.
pub interface Router {
    get pathname(self: Self) -> string
    get params(self: Self) -> Dict<string, string>
    fn push(self: Self, href: string)
    fn replace(self: Self, href: string)
}
pub fn useRouter() -> @Context<Element, Router>     // client hook
pub fn Link(href: string, children: fn() -> Children) -> Element

// server.d.bp — the Http ContextBase: server components & loaders.
pub interface Request {
    get path(self: Self) -> string
    get params(self: Self) -> Dict<string, string>
    get query(self: Self) -> Dict<string, string>
}
// A server hook runs in the Http context (cf. context-inference `connection()`).
pub fn request() -> @Context<Http, Request>
// A loader is a `*fn` returning @Future — awaited inside a server component.
//   *fn loadPost(id: string) -> @Future<Post> { ... }
```

### Composite ergonomics (`.bp`, ordinary code on the intrinsics)

```bp
// fragment.bp — group siblings without a wrapper element.
pub fn Fragment(children: fn() -> Children) -> Element {
    return span { children() };   // V1: thin wrapper; real fragment = future
}

// a custom hook composes primitive hooks (transitive @Context<Element, _>)
pub fn useToggle(initial: bool) -> @Context<Element, {on: bool, toggle: fn()}> {
    val {value, set} = use state(initial);
    return { on: value, toggle: { -> set(!value) } };
}
```

### `html` — JSX-like authoring DSL (core, `html.bp`)

A first-class authoring style alongside the builder API: a template function that
receives the caller's markup **unevaluated** (`@Expr<string>`) and expands it, at
compile time, into an `Element` tree. This is the `expr-templates` machinery
(`q.parts()` / `q.lookup()` / `q.build()`, already shipped in
`examples/jonhstar/`) applied to building elements instead of strings:

```bp
// libs/jhonstart/src/html.bp
pub fn html(comptime q: @Expr<string>) -> @Expr<Element> {
    var acc = "fragment([])";                 // start with an empty element list
    loop (q.parts()) { p ->
        if (p.kind == "Text") {
            // a run of markup: parse tags, splicing component references.
            acc = appendMarkup(q, acc, p.text);
        };
        if (p.kind == "Interp") {
            // a ${…} hole: splice the caller's typed expression as a text node.
            acc = acc + ".push(text(" + p.code + "))";
        };
    };
    return q.build(acc);
}
```

Two splice rules make the user-facing template work:

1. **`${expr}` interpolation** — the hole is the caller's already-typed
   expression (a `Part.Interp` exposes `p.code`); it is spliced as a child
   (text node for strings, element for `Element`-typed holes). If the hole's
   type doesn't fit, the error points **at the interpolation in the caller**.
2. **`<Component/>` tags** — a capitalized tag is resolved in the **caller's
   origin scope** via `q.lookup("Component")`. A hit splices `Component()` as a
   child element (hygiene: resolved where the template was written); a miss is a
   rustc-style diagnostic pointing **inside the template** (`q.failAt`), e.g.
   `error: component 'Page9' not found in scope`.

Lowercase tags (`<div>`, `<p>`) map to the DOM builder intrinsics; uppercase
tags (`<Page1/>`) are component calls. The call site pays zero runtime cost —
`html` never reaches codegen; the expansion is an ordinary `Element` expression,
re-type-checked in the caller.

## Examples

The spec ships three runnable demos under `examples/` (illustrative, not snapshot
fixtures — `examples/AGENTS.md` rule).

### Case 1 — `jhonstart-counter` (React core: state + effect + events)

```bp
import { div, p, button, state, effect, mount } from "jhonstart";

fn Counter() -> Element {
    val {value, set} = use state(0);
    use effect({ -> log("rendered with " + value) });
    div {
        [
            p { "count: " + value },
            button({ -> set(value + 1) }) { "+" },
        ]
    }
}

fn main() {
    mount(Counter(), "#app");
}
```

### Case 2 — `jhonstart-todo` (lists, a custom hook, reducer)

```bp
import { div, ul, li, input, button, state, mount } from "jhonstart";

fn TodoApp() -> Element {
    val items = use state([]);            // items.value : string[]
    val draft = use state("");

    val add = { -> items.set(items.value + [draft.value]); draft.set(""); };

    div {
        [
            input(draft.value, { next -> draft.set(next) }),
            button(add) { "add" },
            ul { items.value.map({ it -> li { it } }) },
        ]
    }
}

fn main() { mount(TodoApp(), "#app"); }
```

### Case 3 — `jhonstart-app` (Next-style: file routing + server data loading + SSR)

File-based routing under `app/` — `page.bp` is a route, `layout.bp` wraps it,
`[id]` is a dynamic segment. A server component is an ordinary `*fn` that
`await`s a loader before returning its `Element`.

```bp
// examples/jhonstart-app/app/layout.bp
import { div, h1 } from "jhonstart";
pub fn Layout(children: fn() -> Children) -> Element {
    div { [ h1 { "my blog" }, children() ] }
}
```

```bp
// examples/jhonstart-app/app/posts/[id]/page.bp
import { div, p } from "jhonstart";
import { request } from "jhonstart/server";

*fn loadPost(id: string) -> @Future<{title: string, body: string}> {
    val resp = await fetch("/api/posts/" + id);   // await: @Future
    return resp.json();
}

*fn Page() -> @Future<Element> {
    val req = use request();                        // Http context
    val post = await loadPost(req.params.get("id").unwrapOr("0"));
    div { [ p { post.title }, p { post.body } ] }
}
```

```bp
// examples/jhonstart-app/main.bp — SSR entry
import { renderToString } from "jhonstart";
import { Page } from "jhonstart/app/posts/[id]/page";

*fn main() {
    val html = await renderToString(await Page());
    @print(html);
}
```

### Case 4 — `jhonstart-html` (JSX-like `html` DSL: `<Component/>` + `${…}`)

The `html` template captures the markup unevaluated, expands it at **compile
time**, resolves each `<PageN/>` against the caller's imports, splices `${name}`
as a typed text node, and yields a plain `Element` — no template engine, no
runtime parse. This is the canonical jhonstart authoring demo and **must** be
supported verbatim:

```bp
// examples/jhonstart-html/main.bp
import { html } from "jhonstart";

import { Page1, Page2, Page3 };          // components from the project root

val name = "world";

val page = html
    \\<div>
    \\  <p>${name}</p>
    \\  <Page1/>
    \\  <Page2/>
    \\  <Page3/>
    \\</div>
;

fn main() {
    @print(page);
}
```

```bp
// examples/jhonstart-html/pages.bp — the components the template references
import { p } from "jhonstart";

pub fn Page1() -> Element { p { "page one" } }
pub fn Page2() -> Element { p { "page two" } }
pub fn Page3() -> Element { p { "page three" } }
```

Conceptually expands (in `main.bp`'s scope) to an `Element` tree equivalent to:

```bp
val page = div { [ p { "world" }, Page1(), Page2(), Page3() ] };
```

- `<Page1/>` etc. resolve **in main.bp's scope** (via `q.lookup`) — hygiene by
  provenance; an unknown `<Page9/>` is a diagnostic pointing inside the template.
- `${name}` crosses as a typed hole; `@print(page)` then prints the rendered
  element (its `renderToString` / `toString` on the `commonJS` target).

## Steps

### F0 — package scaffold
- [ ] `libs/jhonstart/botopink.json` (name `jhonstart`, version `0.0.1`, list the `.d.bp`/`.bp` files)
- [ ] `libs/jhonstart/AGENTS.md` + `libs/jhonstart/docs.md`
- [ ] Add the package row to `libs/AGENTS.md` (Packages table + tree), mark "embedded? no — resolved as a project dependency"
- [ ] Decide resolution: jhonstart is a **normal package** imported via `from "jhonstart"`, NOT embedded into the prelude (unlike `std`)

### F1 — core types (`element.d.bp`)
- [ ] `interface Element { fn key(self) -> ?string }`
- [ ] `Children` (alias for `Element[]`); document the `string`→text and `Element`→`[Element]` coercions
- [ ] Confirm `Element` is accepted as a ContextBase by `context-inference` from a library declaration (today it is a builtin in `builtins.d.bp` — decide: re-export vs. library-declared)

### F2 — DOM builders (`dom.d.bp`)
- [ ] One `#[@external]` intrinsic per tag (`div`, `span`, `p`, `h1`, `ul`, `li`, `button`, `input`, `text`)
- [ ] Trailing-lambda children signature `fn() -> Children`; `button` takes `onClick` first, children last
- [ ] Node runtime stub `jhonstart/runtime` (`el`, `mount`, `text`) so demos run on the `commonJS` target
- [ ] Document attrs strategy for V1 (event handlers as explicit params; full attrs record = future)

### F3 — hooks + composite ergonomics (`hooks.d.bp`, `fragment.bp`, `html.bp`)
- [ ] `state`, `effect`, `memo`, `ref`, `reducer` — all `-> @Context<Element, _>`, `#[@external]`-bound
- [ ] Verify `use state(0)` type-checks inside `fn Counter() -> Element` and is rejected inside `-> string` (reuse `context-inference` scenarios)
- [ ] `Fragment` + `useToggle` in `.bp` — confirm transitive ContextBase propagation
- [ ] `html.bp`: `html(comptime q: @Expr<string>) -> @Expr<Element>` — walk `q.parts()`, splice `${…}` holes (`p.code`) as children, resolve `<Component/>` via `q.lookup` (hit → `Component()`; miss → `q.failAt`), map lowercase tags to DOM builders, `q.build` the result
- [ ] Confirm the `expr-templates` surface (`parts`/`lookup`/`build`/`failAt`) composes for building `Element` (not just `string`); record any gap as a language issue, not a workaround

### F4 — render (`render.d.bp`)
- [ ] `mount(app, selector)` intrinsic (client)
- [ ] `*fn renderToString(app) -> @Future<string>` intrinsic (SSR) — depends on `async-generators`
- [ ] Node runtime stub renders `Element` → HTML string

### F5 — app layer (`router.d.bp`, `server.d.bp`)
- [ ] `Router` interface + `useRouter()` (`@Context<Element, Router>`) + `Link`
- [ ] `Http` ContextBase: `request() -> @Context<Http, Request>` (mirror `connection()` in `context-inference`)
- [ ] Document the file-routing convention (`app/`, `page.bp`, `layout.bp`, `[id]`) as **library convention** (no compiler routing — a build step / convention only in V1)

### F6 — examples + docs
- [ ] `examples/jhonstart-counter/main.bp`
- [ ] `examples/jhonstart-todo/main.bp`
- [ ] `examples/jhonstart-html/` (`main.bp` — the `<Component/>` + `${…}` demo, `pages.bp` — `Page1/2/3`)
- [ ] `examples/jhonstart-app/` (`main.bp`, `app/layout.bp`, `app/page.bp`, `app/posts/[id]/page.bp`)
- [ ] `examples/AGENTS.md` — add the four demos to the tree
- [ ] `libs/jhonstart/docs.md` — component model, hook table, DOM builders, app layer, V1 limits
- [ ] `docs.md` + `README.md` — a short "Frameworks → jhonstart" pointer

## Test scenarios

```
check ---- counter_typechecks            (Counter() -> Element; use state/effect ok)
check ---- use_outside_element_rejected  (use state in -> string → context error)
check ---- hook_compose_transitive       (useToggle propagates @Context<Element,_>)
check ---- server_loader_await           (*fn Page awaits loadPost; @Future unwrap)
check ---- request_http_context          (use request() in Http context ok; in Element → mismatch)
check ---- html_component_tags           (html with <Page1/><Page2/> → div{[Page1(),Page2()]})
check ---- html_unknown_component        (<Page9/> → failAt diagnostic inside the template)
check ---- html_interp_hole              (${name} splices as a typed text child)
codegen/node ---- counter_runs           (mount + state + button click via runtime stub)
codegen/node ---- todo_runs              (list .map → li children; input onInput)
codegen/node ---- html_expands_to_tree   (the Case 4 template compiles + @print renders)
codegen/node ---- ssr_render_to_string   (renderToString(Page) → HTML string)
codegen/erlang ---- counter_typechecks   (parity: at least type-checks/compiles)
```

## Notes

- **Language gaps surfaced by F1–F3 (must be split out as language specs).**
  Building the framework against the current `feat` toolchain (this branch)
  surfaced capabilities the spec's snippets assume but the language cannot yet
  express. Per the "no new compiler features" rule, jhonstart does **not** work
  around these — they are recorded here and gate the corresponding framework
  steps. Verified empirically via `modules/compiler-core/src/comptime/tests/jhonstart.zig`
  (probe scenarios) on the F0 branch:
  1. **Records cannot carry function-typed fields.** Both the type-decl form
     `record Box { set: fn(next: i32) }` and the literal-with-lambda form
     `(record { set: { next -> } })` fail to **parse** (a bare `fn(next: i32)`
     *parameter* type parses, so the gap is record-field-specific). ⇒ The hook
     return shape `{value, set}` / `{on, toggle}` / `{state, dispatch}` is
     inexpressible, which blocks the **builder-API hook ergonomics** in F3
     (`val {value, set} = use state(0)`). **Biggest blocker.**
  2. **No anonymous record TYPE syntax.** `record { value: i32 }` / `{ value: i32 }`
     in *type* position fail to parse (only value literals like
     `(record { port: 8080 })` work). ⇒ Hooks cannot declare inline structural
     returns; a named `record` would be required (but callback fields still hit
     gap #1).
  3. **`fn() -> T[]` does not parse.** An array as a function-type's *return*
     (`children: fn() -> Element[]`) is rejected, even parenthesized. The DOM
     builders' declared `fn() -> Children` parses only because `Children` is an
     interface *name*, not `Element[]`.
  4. **No `Element[]` → `Children` coercion.** The empty `Children` interface is
     not satisfied by an `Element[]` (`expected: Children, found: Element[]`). ⇒
     The builder children model `div { [a, b] }` does not type-check (F1/F2).
     **This also caps the `html` DSL**: lowering a lowercase tag `<div>…</div>`
     to `div(fn() -> Children)` hits the same wall, so V1 `html` cannot emit DOM
     builder calls with children — only `fragment(Element[])` assembly works.
  5. **`fn() -> {}` (empty-record return type) does not parse** — same root as #2.

  **What DOES compile today** (also in the `jhonstart.zig` check tests): `use`
  gating on `@Context<Element, _>` hooks with *simple* / *named-record* (no
  function-field) returns; and the **`html` DSL building an `Element` tree** via
  `q.build` — `<Component/>` → caller-scope `q.lookup` → `Component()`,
  `${expr}` → `text(expr)` child, children assembled with `fragment(Element[])`
  (sidesteps gaps #3/#4). Comptime string ops inside a template body
  (`q.text()`, `.split()`, `.trim()`, accumulate, `q.build()`) are verified to
  run, so a real markup-scanning `html.bp` body is feasible. **V1 `html` scope**:
  self-closing component tags + `${…}` interpolation assembled flat via
  `fragment([…])`; lowercase/nested builder tags (`<div>`, `<p>…</p>`) are
  blocked by gap #4, exactly like the builder API. The canonical Case-4 demo's
  `<div>` wrapper therefore needs gap #4 resolved first; the component-only
  subset (`<Page1/><Page2/>` + `${name}`) is the buildable V1 surface.

- **Compiler prerequisites (cross-set).** jhonstart is a *consumer*; it cannot be
  built until these land in `feat`:
  - `use-await-prefix` (the `use`/`await` prefix operators) — **pending** in
    `tasks/v0.beta.1/specs/`.
  - `async-generators` (`*fn`, `await`, `@Future`) — **pending**; needed for
    server loaders and `renderToString`.
  - `context-inference` (`@Context<B,R>` gating `use`) — **already ✅** (branch
    `task/context-inference`).
  - `expr-templates` (`@Expr<Element>`, tagged calls) — **✅ landed** (c5434bf);
    optional `html """…"""` authoring style.
  If `use-await-prefix`/`async-generators` are not yet in `feat` when this task
  starts, scope F0–F3 (core types/builders/hooks signatures + the counter/todo
  examples) and gate F4–F5 (SSR/server loaders) behind the async work.
- **No new compiler features.** This is a deliberate constraint and a litmus
  test: if jhonstart needs something the language can't express, that is a
  *language* spec, not a framework one. Record any such gap here and split it out.
- **Not embedded.** Unlike `std`, jhonstart is resolved as an ordinary project
  dependency (`from "jhonstart"`); do **not** wire it into
  `comptime/stdlib/prelude.zig` or `build.zig`.
- **`Element` as library ContextBase.** Today `@Context`'s base `Element` is a
  builtin (`builtins.d.bp`). F1 must decide whether jhonstart re-declares it or
  re-exports the builtin; the cleanest is: keep `Element` builtin, let jhonstart
  add methods/builders around it (extension-dispatch).
- **File routing is a convention, not a compiler feature** in V1. `app/…/page.bp`
  is resolved by a (future) jhonstart build step / CLI integration; the demo wires
  it manually in `main.bp`. Real file-system routing = a separate spec.
- **Naming.** Components PascalCase (`Counter`, `TodoApp`, `Page`, `Layout`);
  hooks/intrinsics camelCase (`state`, `useToggle`, `renderToString`) — matches
  the project's `camelCase` rule for functions and the existing `Button`/`Page1`
  component casing.
- **The existing `examples/jonhstar/`** (the `html` *string* template toy) is the
  `expr-templates` showcase and stays as-is. jhonstart's `html` (Case 4) is the
  same machinery promoted to build an **`Element`** tree and resolve
  `<Component/>` tags — `examples/jhonstart-html/` is the canonical version inside
  this package. The builder-API demos (counter/todo) and the `html` demo are two
  authoring styles over the **one** component model; both must work.
- **`html` depends only on shipped features.** `@Expr`, tagged calls,
  `parts`/`lookup`/`build`/`failAt`, and `${…}` interpolation all landed with
  `expr-templates` (c5434bf). The Case 4 demo (`<Component/>` + `${name}`) is
  therefore buildable **before** the async work — it does not need
  `use-await-prefix`/`async-generators`. If building `Element` (vs. `string`)
  surfaces a gap in the expr-template surface, that is a language issue to split
  out, never a runtime workaround.
- Everything in English, including this file.
