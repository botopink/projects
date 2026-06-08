# v0.beta.5 — working notes

This set holds **two** framework specs — `jhonstart` (frontend, React/Next-style)
and `rakun` (backend, Spring-style). They are independent; the notes below are
grouped per spec.

## jhonstart (frontend)

### Why now

The hook machinery already exists in the language design: `context-inference`
landed `@Context<B, R>` gating `use`; `use-await-prefix` + `async-generators`
add the `use`/`await` prefix and `*fn`/`@Future`. That is *exactly* React's
component+hooks model expressed in the type system. jhonstart is the library that
names it: components = `fn(...) -> Element`, hooks = `@Context<Element, _>`,
server components = `*fn ... -> @Future<Element>`.

### Design decisions

- **No new compiler features — consumer only.** This is the litmus test: if
  jhonstart needs something the language can't express, that's a *language* spec.
- **Element is the ContextBase.** Client hooks (`state`/`effect`/`memo`/`ref`/
  `reducer`) all return `@Context<Element, _>`; `Http` is the server ContextBase
  for `request()`/loaders (mirrors `connection()` in `context-inference`).
- **Two authoring styles, one model.** Builder API (`div { ... }`,
  `button(onClick) { ... }`) for everyday code; an optional JSX-like `html
  """…"""`/`html \\…` DSL that reuses `expr-templates` (`@Expr<Element>`) and
  resolves `<Component/>` tags in the *caller's* scope at compile time (the
  `q.lookup`/`q.build` machinery already shipped in `examples/jonhstar`).
- **Intrinsics via `@[external]`; ergonomics in `.bp`.** Primitive hooks and DOM
  builders bind to a host runtime; `Fragment`, `Link`, custom hooks, and `html`
  are ordinary botopink on top.
- **Imported, not prelude.** `from "jhonstart"` — never auto-loaded into the `Env`.

### Open questions

- Does `Element` stay a builtin (in `builtins.d.bp`) that jhonstart extends, or
  does the library re-declare it? Leaning: keep builtin, extend via dispatch.
- `state` return shape: record `{value, set}` (chosen — destructure single, or
  `s.value`/`s.set` for many) vs. tuple `[v, set]` (React-idiomatic, needs the
  `[a,b] = use …` tuple destructure from `use-await-prefix`). Revisit once the
  prefix lands.
- `html` return: `@Expr<Element>` (bounded, LSP-friendly) — the `<Component/>`
  tag walker needs `q.parts()`/`q.lookup()`/`q.build()`, all V1-shipped for
  strings; confirm they compose for the Element-building case.
- File-based routing is a *library convention* in V1 (manual wiring in `main.bp`);
  real filesystem routing = a future CLI/build-step spec.

## rakun (backend)

### Why a framework now

### Design decisions

- **Comptime wiring over runtime reflection.** botopink has no host reflection,
  but it *does* have comptime (`@Expr`, the `expr-templates` work). Component
  discovery and DI graph resolution happen at compile time over the compilation
  unit — discover annotated decls, topo-sort by constructor-field type, emit the
  wiring + router. Zero runtime scanning cost, fully type-checked.
- **Constructor injection only.** A dependency is a `record` field; rakun
  resolves it by type. This is immutable-first — no setter/field injection, no
  mutability needed to wire the graph.
- **Singleton scope only (v1).** One instance per component type. Prototype and
  request scopes wait until the web layer is real.
- **Scaffold-first.** Declare the surface (`.d.bp`) and prove the design before
  embedding anything. Mirrors how `server`/`client` exist as inert scaffolds.
- **Imported, not prelude.** `from "rakun"`. App-level libs must be opt-in per
  project — never auto-loaded into the type `Env`.

### Open questions

- `Context.get<T>()` — is `get` usable as an associated-fn name, or is it a
  reserved keyword token (like `new`/`set`)? If reserved → `resolve<T>()`.
- Stacked annotations: one bracket comma-separated (`@[restController, route("/api")]`)
  vs. multiple `@[...]` blocks. The `@[external(...)]` precedent uses one bracket;
  confirm the parser accepts multiple blocks before relying on them.
- `@[bean]` factories on a `@[configuration]` record vs. top-level `@[bean] fn`.
- Path-param binding: `:name` segments → `req.param("name")`. Typed params later.

### Sequencing

F0–F4 are self-contained (HTTP types, container, annotations, router) and can be
designed/declared without any host. Only F5 (`Rakun.run` → start server) blocks
on `libs/server` graduating from scaffold to real HTTP backing — that is its own
task in `libs/server`, not part of this spec.
