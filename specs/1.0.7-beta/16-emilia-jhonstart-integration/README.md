# Front 16 — Emilia-Jhonstart Integration

**Referência Next.js:** [CSS](https://nextjs.org/docs/app/getting-started/css) · **Análogo:** [Tailwind CSS](https://tailwindcss.com/docs/utility-first)

**Priority:** high — html DSL needs to support emilia attributes
**Depends on:** F15 (emilia-attributes)
**Owns:** `repository/emilia/src/html_hook.bp`, `repository/jhonstart/src/html_attrs.bp`
**Does not touch:** `emilia.bp`, `tokens.bp`, `attributes.bp`, `element.bp`, `html.bp`

---

## Problem

The `html """..."""` DSL in jhonstart doesn't support emilia attributes. Users want to write `<div [emilia]={[.Pad.All.4]}>` in the html DSL and have it generate the class.

## Current state

- `html """..."""` parses HTML-like markup and expands to builder calls
- Attributes in html are static strings: `<div class="foo">`
- No dynamic attribute syntax
- No integration with emilia

## Mechanism

Extend the html DSL to support `[name]={expr}` attributes:

```bp
val page = html """
<div [emilia]={[.Pad.All.4, .Bg.White]}>
  <p>Hello</p>
</div>
""";
```

Expands to:

```bp
div([p([text("Hello", attrs: [])], attrs: [])], attrs: [#("class", emilia([.Pad.All.4, .Bg.White]))])
```

## Exemplos em bp

### Atributo [emilia] no html DSL

```bp
val page = html """
<div [emilia]={[.Pad.All.8, .Bg.Gray100]}>
  <h1 [emilia]={[.Text.Size.X3xl, .Text.Bold]}>Título</h1>
  <button [emilia]={[.Pad.X.4, .Bg.Blue500, .Hover([.Bg.Blue700])]}>
    Clique
  </button>
</div>
""";
```

## Steps

### Step 1 — html DSL extension

Update `html.bp` to recognize `[name]={expr}` syntax:

```bp
// In html.bp's parser
// When encountering [name]={expr}:
// 1. Look up `name` in registered annotation handlers
// 2. Pass `expr` to the handler
// 3. Replace with the handler's output (e.g., class="emilia(...)")
```

**Acceptance:**
- [ ] html DSL parses `[name]={expr}`
- [ ] Looks up handler by name
- [ ] Passes expr to handler

### Step 2 — emilia handler registration

```bp
// src/html_hook.bp
pub fn registerEmiliaHandler() {
    // Register emilia as an html attribute handler
    // When html sees [emilia]={tokens}, call emilia(tokens)
}
```

**Acceptance:**
- [ ] emilia registered as html handler
- [ ] `[emilia]={tokens}` calls `emilia(tokens)`

### Step 3 — jhonstart html_attrs

```bp
// src/html_attrs.bp
// Bridge between jhonstart's html DSL and emilia
// Provides the handler registration
```

**Acceptance:**
- [ ] Bridge module created
- [ ] jhonstart and emilia both updated

### Step 4 — Tests

```bp
test "html DSL supports [emilia] attribute" {
    val page = html """<div [emilia]={[.Pad.All.4]}>Hello</div>""";
    val html = renderToString(page);
    assert html.contains("class=\"e_");
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `html_hook.bp` and `html_attrs.bp` in place
- [ ] html DSL integration works
- [ ] AGENTS.md updated (both repos)
- [ ] Commit on `fix/emilia-jhonstart-integration`

## Blast radius

- New files `html_hook.bp` (emilia), `html_attrs.bp` (jhonstart)
- html DSL extended with `[name]={expr}` syntax
- Both emilia and jhonstart updated

## Notes

- This front touches two repos — coordination required.
- The `[name]={expr}` syntax is generic — other libs can register handlers.
- Future: more attribute handlers (data attributes, ARIA, etc.).
