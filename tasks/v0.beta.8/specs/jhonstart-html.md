# jhonstart-html — the `html """…"""` authoring DSL (markup → Element tree)

**Slug**: jhonstart-html
**Depends on**: [`generic-loader-binding`](generic-loader-binding.md) — so a bare `import {html} from "jhonstart"` binds the template fn into value scope
**Files**: `libs/jhonstart/src/html.bp` (promote `html.d.bp` → real body), `libs/jhonstart/botopink.json`, `examples/jhonstart-html/src/*`
**Touches docs**: `libs/jhonstart/AGENTS.md`, `libs/jhonstart/src/AGENTS.md`, `libs/jhonstart/docs.md`
**Status**: pending

> Lib-side only — **zero** core code. Promotes the last deferred jhonstart marker
> (v0.beta.7 jhonstart F2) to a real comptime body on the already-shipped
> expr-templates machinery. The compiler stays unaware of jhonstart (memory:
> [[feedback_compiler_unaware_of_jhonstart]]).

## Intent

The `html` DSL was deferred in v0.beta.7. **Eric's decision (2026-06-10):** the
authoring surface is the **triple-quoted string template** abandoned in the old
`examples/jonhstar` — `html """<div>…</div>"""` with `${…}` holes — and `html`
expands that markup, at compile time, into an **Element tree**:

```bp
pub fn html(comptime template: @Expr<string>) -> @Expr<Element> {
    @todo()
}
```

`html` receives the caller's markup **unevaluated** (`@Expr<string>` — the
`"""…"""` literal), walks/parses it at compile time, and builds an `@Expr<Element>`
— the `div`/`p`/`text` builder pipeline from `element.bp`:

- lowercase tags (`<div>`, `<p>`) → the DOM builders in `element.bp`;
- `${expr}` → the caller's already-typed expression, spliced as a child
  (text node / element);
- the call site pays zero parsing cost at runtime — `val page = html """…"""`
  compiles to the builder calls; `html` never reaches codegen.

The two v0.beta.7 blockers are handled: the **bare-import** binding is closed by
[`generic-loader-binding`](generic-loader-binding.md); the **markup parser** is
written with native-JS-only comptime ops (no Option runtime — see Notes).

## Target syntax

```bp
import {html, Element, div, p} from "jhonstart";   // bare binding via generic-loader-binding

val name = "world";

val page = html """
<div>
  <p>${name}</p>
</div>
""";

fn main() {
    print(renderToString(page));            // <div><p>world</p></div>
}
```

`page : Element` — the built tree, identical to writing
`div([p([text(name)])])` by hand. The `"""…"""` triple-quoted form is the
authoring surface (re-homed from the abandoned `jonhstar` example).

The builders the markup names (`div`, `p`, …) must be **imported by the caller**:
the expansion resolves each lowercase tag to a builder **in the call site's scope**
(the expr-template `lookup` model), not inside `html` — so `<div>`/`<p>` require
`div`/`p` in scope. An unknown tag is a diagnostic pointing inside the template.

## Examples

### markup → builder pipeline
```bp
val page = html """<p>${name}</p>""";
// expands to:  p([text(name)])            : Element
```

### `${…}` splices the caller's typed expression
```bp
val n = 3;
val row = html """<li>item ${n.toString()}</li>""";
// expands to:  li([text("item " + n.toString())])
```

## Steps

### F0 — confirm the authoring surface
- [ ] Keep the signature `pub fn html(comptime template: @Expr<string>) ->
      @Expr<Element>` (rename `q` → `template`); the input is the `"""…"""`
      markup literal, the output an Element tree. `html.d.bp` stays a marker only
      until F2 lands the body.

### F1 — markup parse (comptime, native-JS-only)
- [ ] Parse the template's `Text` parts into a tag/children structure: a frame
      stack built from `split`/`map`/`append`/`join`/`length`/`+`/`==`/`loop`
      **only** — no `.at()/.pop()` returning `?T` (the comptime eval has no Option
      runtime; memory: [[reference_bp_parser_comptime_gotchas]]). Open/close tags
      nest; lowercase names map to the `element.bp` builder of the same name.

### F2 — build the Element expression (builders resolved in the CALLER's scope)
- [ ] Promote `html.d.bp` → `html.bp`: walk the parsed structure and
      `template.build(…)` the builder pipeline — `<tag>` → `tag([...children])`,
      text runs → `text("…")`, and each `${expr}` `Interp` part spliced via its
      `code` placeholder as a child. List `html.bp` in `botopink.json`.
- [ ] A lowercase `<tag>` emits a bare `tag(...)` call resolved **in the call
      site's scope** (the expr-template `lookup` model), so the caller must
      `import {div, p, …}` the builders it uses; an unknown tag is a diagnostic
      pointing inside the template (rustc-style), not at `html`.

### F3 — examples + tests
- [ ] `examples/jhonstart-html` imports the builders it authors with
      (`import {html, Element, div, p} from "jhonstart"`), writes its page as
      `html """<div><p>${x}</p></div>"""`, and asserts
      `renderToString(page) == "<div><p>…</p></div>"`. Tests live in the lib /
      example `.bp`, never in Zig.

### F4 — docs
- [ ] Update `libs/jhonstart/AGENTS.md`, `src/AGENTS.md`, `docs.md` to the
      `"""…"""` authoring model + the `from "jhonstart"` bare-import path, in the
      **same commit** as the code.

## Test scenarios

```
infer    ---- html """<p>${name}</p>""" type-checks as @Expr<Element>
run      ---- a lowercase tag maps to its builder: html """<p>hi</p>""" renders "<p>hi</p>"
run      ---- a ${…} hole splices the caller's value as a child node
run      ---- nested tags build a nested Element tree (<div><p>…</p></div>)
loader   ---- bare `html` resolves post-import (depends on generic-loader-binding)
gate     ---- grep -riE "jhonstart" modules/compiler-core/src returns nothing
```

## Notes

- **Sibling of `erika "…"`.** `html """…"""` (markup) and [`erika`](erika.md)'s
  `erika "…"` (SQL) are the **same mechanism** — a `fn(comptime q: @Expr<string>) ->
  @Expr<T>` template fn whose string is a mini-language expanded at comptime, with
  references resolved in the caller's scope (html's builders / erika's collection).
  Both share the single keystone edge to
  [`generic-loader-binding`](generic-loader-binding.md). Build them to the same bar.
- **Authoring = `"""…"""` string; output = Element tree.** The triple-quoted
  string is the input surface (Eric's correction, 2026-06-10); `html` returns
  `@Expr<Element>`, expanding markup into the `element.bp` builders. This is the
  full JSX-like DSL the deferred `html.d.bp` described, now unblocked.
- **Native-JS-only parser.** The comptime body must avoid `?T`/Option ops (the
  template eval has no Option runtime). If the stack parser proves infeasible
  within that constraint, the **recorded fallback** is a generic
  `comptime-eval-option` core spec (a new v0.beta.8/v0.beta.9 task) — out of scope
  here; this spec stays pure-lib unless that fallback is opened.
- **`<Component/>` lookup is a future layer.** Capitalized-tag resolution against
  the caller's scope (`q.lookup`) is recorded, not built here — start with
  lowercase tags + `${…}` holes.
- **Zero core surface.** Reuses the shipped expr-templates machinery
  (`parts()`/`build()`); the only new dependency is the bare template-fn binding
  from [`generic-loader-binding`](generic-loader-binding.md). Memory:
  [[feedback_prefer_bp_over_dbp]], [[feedback_compiler_unaware_of_jhonstart]].
