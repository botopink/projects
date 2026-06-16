# emilia — CSS-in-bp lib (type-safe utility tokens, for jhonstart)

**Slug**: emilia
**Depends on**: [`enum-sections`](frente-a.md) — emilia's `Token`
enum uses nested sections with path access (`.Color.Red.500`, `.Pad.X.4`,
`.Text.Size.X3xl`) and numeric variant leaves; without enum-sections the
authored surface degrades to wrapped `Token.Color(TokenColor.Red(_500))`
form, which is unusable in practice. The template-fn /
`@ExprCustom` mechanism (`expr-custom-done`, `sublanguage-lsp`,
`package-default-dsl`) plus the generic `from "<lib>"` loader are in
`feat`; emilia is otherwise a pure `.bp` client.

**Files**:
- `repository/emilia/src/tokens.bp` — the `Token` enum (sections: Text,
  Color, Bg, Pad, Margin, Border, Layout, Flex, Effect; modifiers:
  Hover/Focus/Active/Md/Lg/Xl).
- `repository/emilia/src/emilia.bp` — the `#[emilia(tokens)]` annotation
  handler: walks the `@Expr<[Token]>` arg, resolves each token to a CSS
  declaration, accumulates into `EmiliaClass`, registers in the
  `Stylesheet` host cell, returns the class to the caller.
- `repository/emilia/src/stylesheet.bp` — the `Stylesheet` host-cell
  seam (the single `#[@External.<Target>(...)]` surface in emilia v1;
  commonJS only at v1).
- `repository/emilia/src/root.bp` — `pub default mod emilia;` re-exports
  + the `Token` enum public surface.
- `repository/emilia/botopink.json` — package manifest.
- `repository/emilia/examples/emilia-card/{botopink.json, src/main.bp}` —
  runnable smoke that renders a jhonstart page with collected CSS via
  `renderToString + emilia.flush()`.
- `repository/jhonstart/src/element.bp` — two minimal additions:
  - **annotation hook** for `#[emilia(...)]` on element builder calls
    (the decorator transforms the call to inject `attr(class: …)` into
    the produced `Element`).
  - **`[emilia]={...}` attribute** in the `html """…"""` DSL — the html
    scanner recognises the `[name]={expr}` syntax as "annotation
    attribute"; it routes to the matching annotation handler
    (`emilia`), passes the `@Expr` to it, and inlines the returned
    class.

**Touches docs**: `repository/emilia/{README.md, AGENTS.md, docs.md,
CHANGELOG.md}`, `repository/jhonstart/{AGENTS.md, src/element.bp}`'s
comment block on the `#[emilia(...)]` decorator hook and the
`[emilia]={...}` html attribute, `repository/botopink-lang/libs/AGENTS.md`
cross-reference (one bullet).

**Status**: pending

> **Ecosystem-expansion keystone (v0.beta.20).** v0.beta.19 closed the
> language's recorded gaps; v0.beta.20 opens the **ecosystem-expansion**
> line. emilia is its keystone — a net-new framework library that
> proves a *type-safe* token surface on top of the existing template-fn
> / `@ExprCustom` mechanism. Markup (`jhonstart/html`) and SQL
> (`erika/erika`) used `@Expr<string>` sub-languages parsed at
> comptime; emilia uses `@Expr<[Token]>` — the sub-language is an
> *array literal of typed enum variants*, not a string. The Token
> enum is the entire surface; the `enum-sections` language extension
> in this same set makes it ergonomic.

## Intent

A consumer authors styles by **listing typed tokens** — never by
writing CSS strings. The token surface is exhaustively typed via the
`Token` enum (with nested sections per CSS family). Unknown tokens are
parse / type errors at the call site, not runtime fall-throughs.

Two attachment forms, both surfaced by jhonstart (emilia only exposes
the annotation):

1. **`#[emilia([…])]` decorator on an element builder call.**
2. **`[emilia]={[…]}` attribute inside an `html """…"""` DSL.**

Both forms accept the same `[Token]` array literal. emilia normalises
the array → assigns a stable class name → registers into the
per-render `Stylesheet` → returns the class to the host (jhonstart) so
it can append it to the produced `Element`.

Output side, the SSR caller composes:

```bp
val markup = renderToString(page);   // jhonstart's existing walk
val styles = emilia.flush();          // returns a <style>…</style> block
val html   = "<html><head>" + styles + "</head><body>" + markup + "</body></html>";
```

`emilia.flush()` serialises the registry and clears it (per-render
semantics; the in-file `test {}`s call it after each tree-render).

## Target syntax

### Token enum (`tokens.bp`)

```bp
pub enum Token {
  Text {
    Bold, Italic, Underline, LineThrough,
    Left, Center, Right, Justify,
    Size { Xs, Sm, Base, Lg, Xl, X2xl, X3xl, X4xl }
  }

  Font {
    Sans, Serif, Mono,
    Weight { Light, Normal, Medium, Bold, Black }
  }

  Color {
    Red    { 100, 200, 300, 400, 500, 600, 700, 800, 900 }
    Blue   { 100, 200, 300, 400, 500, 600, 700, 800, 900 }
    Green  { 100, 300, 500, 700, 900 }
    Gray   { 100, 200, 300, 400, 500, 600, 700, 800, 900 }
    Hex(string),
  }

  Bg {
    Red    { 100, 500, 700 }
    Blue   { 100, 500, 700 }
    Gray   { 100, 200, 500, 900 }
    White, Black,
    Hex(string),
  }

  Pad {
    X { 1, 2, 4, 8, 16 }
    Y { 1, 2, 4, 8 }
    All { 1, 2, 4, 8, 16 }
  }

  Margin {
    X { Auto, 1, 2, 4, 8 }
    Y { 1, 2, 4, 8 }
    All { 1, 2, 4, 8 }
  }

  Layout { Block, InlineBlock, Inline, Hidden, Flex, Grid }

  Flex {
    Row, Col, Wrap, NoWrap,
    Items { Start, Center, End, Stretch }
    Justify { Start, Center, End, Between, Around }
    Gap { 1, 2, 4, 8 }
  }

  Border {
    W { 0, 1, 2, 4 }
    Color {
      Red   { 100, 500, 700 }
      Gray  { 100, 500, 700 }
      Hex(string),
    }
    Rounded { Sm, Md, Lg, Full }
  }

  Effect {
    Shadow { Sm, Md, Lg, Xl }
    Opacity { 0, 25, 50, 75, 100 }
  }

  // modifiers — carry a nested array of tokens
  Hover([Token]),
  Focus([Token]),
  Active([Token]),
  Md([Token]),
  Lg([Token]),
  Xl([Token]),
}
```

### Form 1 — `#[emilia(…)]` decorator on builders

```bp
import { div, p, text } from "jhonstart";

val name = "world";

val page = #[emilia([
  .Pad.All.4,
  .Bg.White,
  .Border.Rounded.Md,
])] div([
  #[emilia([.Text.Size.X3xl, .Text.Bold, .Text.Underline])]
  p([text("hello, " + name)])
]);
```

### Form 2 — `[emilia]={…}` attribute inside `html """…"""`

```bp
import { html } from "jhonstart";

val name = "world";

val page = html """
  <div [emilia]={[.Pad.All.4, .Bg.White, .Border.Rounded.Md]}>
    <p [emilia]={[.Text.Size.X3xl, .Text.Bold, .Text.Underline]}>
      hello, ${name}
    </p>
  </div>
""";
```

Both forms compile to identical Element trees. The html scanner
recognises `[<name>]={<expr>}` as an "annotation attribute" — the
host (jhonstart) resolves `<name>` to a known annotation handler
(here `emilia`), passes `<expr>` as `@Expr<[Token]>`, and inlines
the result into the parent element's attribute list.

### Modifiers (hover / focus / breakpoints)

```bp
val btn = #[emilia([
  .Bg.Blue.500,
  .Text.Bold,
  .Pad.X.4,
  .Hover([.Bg.Blue.700, .Text.Underline]),
  .Focus([.Border.W.2, .Border.Color.Blue.700]),
  .Md([.Pad.X.8]),         // responsive: at md breakpoint, pad-x:8
  .Lg([.Pad.X.16]),
])] button([text("click me")]);
```

### Arbitrary colors

```bp
val brand = #[emilia([
  .Bg.Hex("#abc123"),
  .Text.Color(.Hex("#fffaa0")),
  .Border.Color.Hex("#330000"),
])] div([…]);
```

### Render output

```bp
val markup = renderToString(page);
val styles = emilia.flush();
```

Produces something like:
```html
<style>
.e_a31f{padding:1rem;background:white;border-radius:0.375rem}
.e_b07c{font-size:1.875rem;font-weight:bold;text-decoration:underline}
</style>
<div class="e_a31f">
  <p class="e_b07c">hello, world</p>
</div>
```

Class names are stable, content-derived hashes (so identical token
lists collapse to one class across the document).

## Mechanism

### Annotation handler

`#[emilia(tokens: [Token])]` is registered as an annotation handler
in `repository/emilia/src/emilia.bp`. The handler:

1. Receives the `@Expr<[Token]>` argument list.
2. Walks the array at comptime, resolving each `Token` to a CSS
   declaration via `tokenToCss(t: Token) -> string`.
3. Concatenates declarations into a CSS rule body, hashes the body
   into a stable class name.
4. Registers `(className, body)` in the `Stylesheet` host cell.
5. Returns `className` (a `string`) — the host inlines it into the
   element's `class` attribute.

```bp
// emilia.bp (sketch)
#[annotation(target: .Builder, target: .HtmlAttribute)]
pub fn emilia(tokens: [Token]) -> string {
  val rules = tokens
    .map(tokenToCss)
    .filter(notEmpty)
    .join(";")

  val name = "e_" + hash(rules)
  Stylesheet.register(name, rules)
  return name
}

fn tokenToCss(t: Token) -> string {
  match t {
    .Text.Bold                  => "font-weight:bold",
    .Text.Underline             => "text-decoration:underline",
    .Text.Size.X3xl             => "font-size:1.875rem",
    .Text.Size.Lg               => "font-size:1.125rem",
    // …
    .Color.Red.500              => "color:#ef4444",
    .Color.Hex(h)               => "color:" + h,
    .Bg.White                   => "background:white",
    .Bg.Hex(h)                  => "background:" + h,
    .Pad.X.4                    => "padding-left:1rem;padding-right:1rem",
    .Pad.All.4                  => "padding:1rem",
    .Border.Rounded.Md          => "border-radius:0.375rem",
    .Hover(inner)               => ":hover{" + inner.map(tokenToCss).join(";") + "}",
    .Md(inner)                  => "@media(min-width:768px){" + inner.map(tokenToCss).join(";") + "}",
    _                           => "",
  }
}
```

The `match` is **exhaustive** (`enum-sections` extends exhaustiveness
to walk every leaf in the section tree). The compiler errors if a leaf
is unreached.

### jhonstart hooks (2 additions)

1. **Annotation-on-builder hook.** When the comptime sees
   `#[emilia([...])] tag(children)`, it transforms the call to
   `tag(children, attrs: [class: emilia(tokens)])`. This is the same
   pattern jhonstart's `#[memo]` already uses (decorator that wraps
   the call site).

2. **`html` DSL attribute hook.** When the html scanner sees
   `<tag [name]={expr}>`, it looks up `name` in the registered
   annotation handlers. If found, the comptime expansion replaces the
   attribute with `class={name(expr)}` (or whatever the handler
   returns — the contract is "any string-returning annotation can be
   used as an attribute via this syntax"). The handler chooses how to
   interpret `expr`.

Both hooks are **generic** — they don't mention emilia by name.
Jhonstart owns the mechanism; emilia is one consumer. A future
ecosystem lib (e.g., data-attribute helpers) plugs into the same
hooks.

### Stylesheet host cell

```bp
// stylesheet.bp
#[@External.<commonJS>("globalThis.__emilia_sheet ||= new Map(); globalThis.__emilia_sheet")]
declare fn sheet() -> any

pub fn register(name: string, body: string) {
  sheet().set(name, body)
}

pub fn flush() -> string {
  val m = sheet()
  val out = "<style>" + m.entries().map(([n, b]) => "." + n + "{" + b + "}").join("") + "</style>"
  m.clear()
  return out
}
```

At v1 commonJS only. Erlang/beam ports are listed as v21+ candidates
(structurally identical — swap `Map` for a `persistent_term`-style
cell).

## Phases

| Phase | Description |
|---|---|
| **F0** | **Stand up the lib + jhonstart hooks.** `repository/emilia` submodule seed already in place (`f3b6ef7`); bump to add `tokens.bp` skeleton (Token enum with 3 sections — Text, Color, Pad — to prove the shape), `emilia.bp` stub (annotation handler signature, empty body), `stylesheet.bp` (commonJS `Map` host cell), `root.bp` re-exports. Jhonstart half: register the two hooks (annotation-on-builder + `[name]={expr}` html attribute) — generic, no emilia reference. Smoke test: `#[emilia([])] div([])` produces a `<div>` with empty class. |
| **F1** | **Fill out the Token enum.** All 9+ top-level sections from "Target syntax" above (Text, Font, Color, Bg, Pad, Margin, Layout, Flex, Border, Effect) + the modifier variants (Hover, Focus, Active, Md, Lg, Xl). Cross-reference Tailwind utility class names for the leaf inventory. |
| **F2** | **`tokenToCss` handler.** The exhaustive match. Per-section helper fns to keep arms manageable (`textTokenToCss`, `colorTokenToCss`, etc.). In-file `test {}` blocks for each section. |
| **F3** | **Modifier composition.** `.Hover([…])`, `.Focus([…])`, `.Md([…])` etc. wrap inner tokens with the appropriate CSS prefix (`:hover{…}`, `@media(...){…}`). Test the nesting (e.g., `.Md([.Hover([…])])`). |
| **F4** | **`Stylesheet.flush()` semantics.** Per-render clearing; two consecutive renders produce two independent `<style>` blocks. Hash stability across renders (identical token list → identical class name). |
| **F5** | **Runnable `examples/emilia-card/`.** A jhonstart page with mixed `#[emilia(…)]` decorator and `[emilia]={…}` html attribute. `botopink test` green. `bpmp install emilia` resolves the lib from its GitHub Releases tag. Docs sweep: `docs.md`, `AGENTS.md`, jhonstart `AGENTS.md` paragraph on the two hooks. |

## Acceptance gates

```text
parse  ---- `#[emilia([.Text.Bold, .Pad.X.4])] div([])` parses without diagnostic
parse  ---- `<div [emilia]={[.Bg.Red.500]}>...</div>` inside html """…""" parses
type   ---- `#[emilia([.UnknownToken])]` is a type error at the unknown variant
type   ---- `#[emilia([.Pad.X.99])]` errors — 99 not in the Pad.X variant list
match  ---- `tokenToCss` exhaustiveness: missing any leaf surfaces an ES5 diag
render ---- `renderToString(page) + emilia.flush()` produces stable HTML + CSS
hash   ---- two `#[emilia([.Bg.White])]` sites on different elements share one class
flush  ---- two consecutive `flush()` calls emit two independent <style> blocks
modif  ---- `.Hover([.Bg.Red.700])` produces ":hover{background:#dc2626}" prefix
modif  ---- `.Md([.Pad.X.8])` produces "@media(min-width:768px){padding-left:2rem;...}"
hex    ---- `.Color.Hex("#abc")` and `.Bg.Hex("#abc123")` emit literal hex output
example---- `examples/emilia-card/` renders a card matching the golden HTML+CSS pair
```

## Trade-offs / chosen designs

1. **Tokens as enum variants (not strings).** Pays the type-safety
   premium for a finite catalog. Unknown utility = compile error; LSP
   completes per section. Inspired by Eric's design feedback during
   the v20 emilia opener — the string-shorthand approach (`tw "p-4
   bg-white"`) was considered and dropped in favour of this.

2. **Two attachment surfaces (decorator + html attribute), one
   handler.** emilia exposes one annotation; jhonstart offers two
   syntaxes to invoke it. The hooks are generic — any future
   annotation can ride them.

3. **`enum-sections` is a hard dependency, not a workaround.** The
   spec for it lives in the same v0.beta.20 set. Without it,
   `Token.Color(TokenColor.Red(_500))` is the surface — unusable.
   The two specs are jointly authored and merged.

4. **commonJS only at v1.** Erlang/beam port is recorded for v21+.
   Same `EmiliaClass` value; swap `Map` for `persistent_term`.

5. **`Hex(string)` escape for arbitrary colors.** The fixed palette
   covers the common case; `.Color.Hex("…")` / `.Bg.Hex("…")` /
   `.Border.Color.Hex("…")` accept arbitrary strings. No CSS-string
   escape outside this — flat rules only, no nested selectors, no
   media queries beyond the typed `.Md` / `.Lg` / `.Xl` modifiers.

## Non-goals

- **No `styled.<tag>` namespace.** Eric chose to focus on the
  Tailwind-style functional surface; the styled-components form is
  not in v1.
- **No `css """…"""` arbitrary-CSS escape.** All styling goes through
  the typed token surface; the `.Hex(...)` variant covers arbitrary
  colors. If a v21+ need emerges for arbitrary declarations, a
  `.Raw(string)` variant can be added then.
- **No nested selectors (`&:hover`, `& > p`).** The `.Hover(...)`,
  `.Focus(...)` modifiers cover state pseudo-classes; descendant
  selectors are deferred.
- **No animations / keyframes** at v1.
- **No dark-mode / theme variants.** Each token resolves to one CSS
  declaration; theming is the consumer app's responsibility (or a
  v21 follow-up).
- **No compiler change beyond `enum-sections`.** The annotation hook
  in jhonstart and the html attribute hook are generic mechanisms,
  not emilia-specific.

## Recorded follow-ups (v0.beta.21+)

- emilia: erlang/beam Stylesheet host port (alongside rakun's erlang
  server port).
- emilia: theme provider (`emilia.theme(Dark) { … }` context block).
- emilia: nested selectors via a `.Child(.Tag.p, [...])` variant.
- emilia: animations / `@keyframes` via `.Animate(.Name, .Duration.X300)`.
- emilia: `.Raw(string)` escape if non-token CSS truly becomes necessary.
- emilia: dev-mode `pretty` flush (one declaration per line for
  devtools readability).
