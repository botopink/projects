# Front 05 — Jhonstart Client Directive

**Referência Next.js:** [Server and Client Boundary](https://nextjs.org/docs/app/guides/server-and-client-boundary) · ["use client"](https://nextjs.org/docs/app/api-reference/directives/use-client)

**Priority:** high — client components need a clear boundary mechanism
**Depends on:** F04 (jhonstart-server-components)
**Owns:** `repository/jhonstart/src/client.bp`
**Does not touch:** `router.bp`, `link.bp`, `server.bp`, `element.bp`, `hooks.bp`, `html.bp`

---

## Problem

Next.js uses `'use client'` to mark the boundary between server and client components. In botopink, all components are server components by default (they render on the server). Components that need interactivity (state, event handlers, browser APIs) need a way to declare themselves as client components.

## Current state

- jhonstart has no client/server boundary mechanism
- All components render via `renderToString` (SSR)
- Hooks (`state`, `effect`, etc.) have SSR-only bodies (no-op on server)
- The `use` prefix is legal in any `-> Element` body (context-inference)

## Exemplos em bp

### Componente cliente com state

```bp
#[client]
pub fn Counter() -> Element {
    val count = use state(0);
    return div([
        p([text("Count: " + count.value.toString())]),
        button([text("+1")], attrs: [#("onClick", "increment")]),
    ], attrs: []);
}
```

### Misturando server e client

```bp
#[@future]
pub fn DashboardPage() -> @Future<Element> {
    return div([
        Counter(),           // client component
        await RecentPosts(), // server component
    ], attrs: []);
}
```

## Mechanism

Introduce a `#[client]` decorator (or convention) that marks a component as client-only:
- The decorator is a comptime fn that emits metadata
- At runtime, client components are serialized as references (not rendered HTML)
- The client runtime hydrates them with real interactivity

Since botopink has no `'use client'` directive syntax, we use a decorator: `#[client]`.

```bp
#[client]
pub fn Counter() -> Element {
    val c = use state(0);
    return div([
        p([text("count: " + c.value.toString(), attrs: [])], attrs: []),
        button([text("increment", attrs: [])], attrs: [#("onClick", "increment")]),
    ], attrs: []);
}
```

## Steps

### Step 1 — #[client] decorator

```bp
// src/client.bp
pub fn client(comptime decl: @Decl) {
    if (decl.kind != DeclKind.Fn) decl.fail("#[client] must annotate a function");
    // Emit metadata: this function is a client component
    @emit("val __jhonstart_client_" + decl.name + " = true;");
}
```

**Acceptance:**
- [ ] `#[client]` decorator compiles
- [ ] Can be applied to `fn(...) -> Element` functions
- [ ] Fails with diagnostic if applied to non-function

### Step 2 — Client component detection

```bp
// Runtime check: is a component a client component?
#[@External.Node("onze13/runtime", "isClientComponent")]
#[@External.Erlang("onze13_runtime", "is_client_component")]
declare fn isClientComponent(name: string) -> bool;
```

**Acceptance:**
- [ ] Host cells declared for both targets
- [ ] Returns true for `#[client]`-annotated components

### Step 3 — SSR behavior for client components

When `renderToString` encounters a client component:
- Renders a placeholder `<div data-jhonstart-client="Counter"></div>`
- The client runtime replaces this with the real interactive component

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

**Acceptance:**
- [ ] Client components render as placeholder divs during SSR
- [ ] Placeholder carries component name and props

### Step 4 — Tests

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

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `client.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/jhonstart-client-directive`

## Blast radius

- New file `client.bp` — no changes to existing files
- Consumers can opt-in to client components with `#[client]`

## Notes

- The actual client-side hydration (replacing the placeholder with a real React-like component) is a client runtime concern — not implemented here.
- `#[client]` is a convention, not a compiler directive. The compiler core remains unaware.
- Future: if botopink adds a `'use client'` directive syntax, this front's decorator can be deprecated in favor of the native syntax.
