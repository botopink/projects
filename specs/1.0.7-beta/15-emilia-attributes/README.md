# Front 15 — Emilia Attributes

**Referência Next.js:** [CSS / Tailwind](https://nextjs.org/docs/app/getting-started/css) · **Análogo:** [Tailwind CSS](https://tailwindcss.com/docs/utility-first)

**Priority:** high — emilia needs to integrate class names into jhonstart elements
**Depends on:** F02 (jhonstart-router)
**Owns:** `repository/emilia/src/attributes.bp`
**Does not touch:** `emilia.bp`, `tokens.bp`, `root.bp`

---

## Problem

Emilia generates class names from tokens, but jhonstart's `Element` model doesn't automatically apply them. Components need a way to attach emilia classes to elements.

## Current state

- `emilia(tokens)` returns a class name string
- `Element` has `attrs: Array<#(string, string)>` — can carry `class`
- No integration between emilia and element attrs
- Consumers manually compose: `div([text("hi")], attrs: [#("class", emilia([...]))])`

## Mechanism

Introduce `#[emilia]` decorator on element builders:

```bp
#[emilia([.Pad.All.4, .Bg.White])]
div([text("Hello", attrs: [])], attrs: [])
```

Expands to:

```bp
div([text("Hello", attrs: [])], attrs: [#("class", emilia([.Pad.All.4, .Bg.White]))])
```

## Exemplos em bp

### Emilia em builders

```bp
pub fn Card() -> Element {
    val cardClass = emilia([.Pad.All.4, .Bg.White, .Border.Rounded.Lg]);
    return div([
        h1([text("Título")], attrs: [#("class", emilia([.Text.Bold]))]),
    ], attrs: [#("class", cardClass)]);
}
```

### Modifiers

```bp
val buttonClass = emilia([
    .Pad.X.4, .Bg.Blue500,
    .Hover([.Bg.Blue700]),
    .Md([.Pad.X.8]),
]);
```

## Steps

### Step 1 — #[emilia] decorator

```bp
// src/attributes.bp
pub fn emilia(comptime tokens: @Expr<Token[]>) {
    // Transform the annotated builder call
    // Add class attribute with emilia(tokens)
}
```

**Acceptance:**
- [ ] `#[emilia]` decorator compiles
- [ ] Can be applied to element builders
- [ ] Transforms the call to add class attr

### Step 2 — Class composition

Multiple `#[emilia]` on the same element compose:

```bp
#[emilia([.Pad.All.4])]
#[emilia([.Bg.White])]
div([...])
// → class="e_abc123 e_def456"
```

**Acceptance:**
- [ ] Multiple emilia decorators compose
- [ ] Class names are space-separated

### Step 3 — Conditional classes

```bp
#[emilia([.Bg.White, if (isActive) .Text.Bold])]
div([...])
```

**Acceptance:**
- [ ] Conditional tokens work
- [ ] Only applied tokens generate classes

### Step 4 — Tests

```bp
test "#[emilia] adds class attribute" {
    val el = #[emilia([.Pad.All.4])] div([text("hi", attrs: [])], attrs: []);
    val html = renderToString(el);
    assert html.contains("class=\"e_");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `attributes.bp` in `botopink.json` and `root.bp`
- [ ] AGENTS.md updated
- [ ] Commit on `fix/emilia-attributes`

## Blast radius

- New file `attributes.bp`
- No changes to existing emilia or jhonstart files
- Consumers can use `#[emilia]` on builders

## Notes

- The decorator is a comptime transformation — it modifies the AST before codegen.
- Class names are generated at runtime by `emilia(tokens)` — the decorator just wires it up.
- Future: `[emilia]={expr}` syntax in the `html` DSL (F16).
