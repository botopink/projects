# Front 118 — bpp components: the template language

**Priority:** critical — every other front writes markup through it; none is testable without it.
· **State:** not started · ready to open
**Depends on:** nothing open (`00-gate/101-gate-jhonstart` done). Written against decisions 190,
191, 192, 193 and 223, 204, 207, 200, 270, 189, 278.
**Owns:** `repository/jhonstart/modules/jhonstart-html/**` (`src/html.bp`, `src/root.bp`,
`test/**`, `botopink.json`, `src/AGENTS.md`) — lands there; `05-jhonstart/26` step 0 then merges
it into the core, `html` the core's `pub default fn` (200); 119, 120, 126 append to
`jhonstart/src/html.bp` · `repository/jhonstart/examples/jhonstart-markup/**` except its
`README.md` (`05-jhonstart/26` step 6) · new `jhonstart/modules/jhonstart/src/prelude.bp` and the
core's node type `Node` (223; carve-outs of `05-jhonstart/26`'s member, 270) · the `Children` →
`Node` rewrite of this track's `examples/**` · step 1's one-line carve-outs: each `[name]={expr}`
attribute outside this member — `jhonstart-emilia`'s bridge test (119's),
`examples/document-shell`, the core's comment lines naming the DSL (`root.bp`, `elements.bp`,
`05-jhonstart/26`'s) — one commit per repository, landed before the owning front opens (189)
**Does not touch:** `modules/jhonstart/**` beyond those lines (`05-jhonstart/26`'s — a need is a
hand-off, § Notes); the compiler; emilia — its `[class]={…}` lines are comments, reworded by
`06-emilia/34` step 1, `examples/emilia-card`'s by `06-emilia/33` step 2. 119, 120, 126 each
**append** one lowering arm to `html.bp` after this front, in that order (`fronts.md` rule 2).

Reference: `astro-docs/09-astro-components.md`, `10-layouts.md`, `13-astro-syntax.md`.

## Goal

Pages, layouts, components in `html """…"""`: every attribute renders, holes take any renderable
type, a component tag is a call with its props, children and slots via props, markup inside `if`
/ `case` / lambdas, annotations in tags (`#[isRaw]`, `#[clientVisible]`) resolved as names (278). Today:

```bp
val cls = "card";
val page = html """<div class="card" [id]={cls}><p>${name}</p><br/></div>""";
```

| What the author wrote | What happens | Where |
|---|---|---|
| `class="card"` | dropped — static attribute reaches the editor overlay, never the `Element` | `html.bp:138-146`, `:233-234` |
| `[id]={cls}` | the one rendering attribute form | `html.bp:117-136`, `:241` |
| `title="two words"` | tag body split on single spaces; value cut | `html.bp:110` |
| `${name}` | `text(name)` — a hole is a string; no `Element`, list or `if` | `html.bp:189` |
| `<br/>` | stored, emitted after the loop at the root, not inside `<div>` | `html.bp:212-217`, `:250-253` — read, not run |
| `<Card title="x"/>` | lowered like any tag: `Card([…], attrs: […])` | `html.bp:231`; "`<Component/>` lookup stays a future layer" (`:30`) |
| a comment, a fragment, a slot, a loop, a condition | not in the grammar | — |

So every page is builders (`onze/examples/blog/src/app/blog/[slug]/page.bp`).

## Mechanism

**Where it stands** (`repository/jhonstart/modules/jhonstart-html/`): `src/html.bp` 270 lines, one
function `pub fn html(comptime template: @Expr<string>) -> @ExprCustom<Element>`; `test/` two
files; 12 files use `html """` (jhonstart-html 4, jhonstart 2, document-shell 2, jhonstart-markup
1, jhonstart-emilia 1, emilia 1, erika-linq 1); `[name]={expr}` 10 uses in 7 files outside the
parser. Body rules in its header (`html.bp:56-75`: no optional, no array index, no comment in the
body, a counter reassigned only in the flat loop, token tuple read positionally) were for a
replaced evaluator (comptime now on BEAM and wat); step 0 checks which hold. Lowering targets in
the core: `Element(tag, value, children, attrs)` (`jhonstart/src/element.bp`), `el(tag, children,
attrs)`, `voidEl(tag, attrs)` (`elements.bp`), `fragment` (`element.bp`), `raw(html)`
(`render.bp`), and `Children` — children type of `element.bp`/`elements.bp`, coercing from a list,
one `Element` or a `string`, declared by no jhonstart module (checker knows it by name:
`compiler-core/src/comptime/env.zig` known names, `infer.zig`'s `Children` coercion); 223 renames
it `Node`, declared here (step 6). Renderer escapes text and attributes, refuses `</script` in a
raw-text body (`render.bp`).

Shape kept — lex, parse, lower twice (code and `CustomNode` overlay), return
`q.custom(overlay, q.build(code))`; grammar becomes:

```
template  := node*
node      := element | component | fragment | text | comment | hole | slot
element   := '<' name attr* '>' node* '</' name '>'  |  '<' name attr* '/>'
component := the same, with a name that starts with an upper-case letter
attr      := name | name '=' '"' text '"' | name '=' '{' expr '}' | '{...' expr '}' | annotation
annotation := '#[' item ( ',' item )* ','? ']'      one list per tag (279)
item      := name ( '(' args ')' )?                 a function in the caller's scope (278)
hole      := '{' expr '}'  |  '${' expr '}'
expr      := botopink, in which markup may start a lambda body, an if / else block or a case arm
```

**Holes** (190, 191, 204): accepted set per 191 (`string`; number/`bool` as `toString()`; same-base component — `Element`, base `ElementBase`; a list of them; the node type); refused `?T` message `error: a hole
of type ?string — write {subtitle ?? ""}`; record, function, other-base component refused at the
expression. `{expr}` is the surface; `${expr}` keeps meaning text, with real-hole diagnostics.
Compiler owes typed, positioned embedded expressions (`language-gaps.md`, owner `01-compiler`);
meanwhile `{expr}` is read from the raw text and re-emitted through `build` (a wrong type = the
checker's error at the template call); the move to the typed form keeps the surface.

**Component tag = call with one props value** (192, 193, 207, 223). Attributes on `<Comp …>` are fields of the
**first parameter**'s type of `Comp` (named or inline `type(…)`); undeclared attribute, wrong type, missing
non-default field: comptime error at the attribute. Children only via a `children: Node` field
(examples' `Children` rewritten in step 6); content in a component without one: error at the tag;
a narrower `children` type refuses what it does not name; a second `children` parameter goes away.

| Markup | Lowering |
|---|---|
| `<Card title="Hi" count={n} />` | `Card` called with the props value `(title: "Hi", count: n)` |
| `<Card title="Hi"><p>body</p></Card>` | the same, with `children: [p(["body"])]` among the fields |

**Slots.** `<slot />` reads `children`; `<slot name="footer">fallback</slot>` renders the fallback
when empty. Named-slot mapping (`<p slot="footer">` / `<slot name="footer">`) is open (`props-e`);
`footer` as a props field below is one reading, not a decision:

```bp
pub default fn Card(props: type(title: string, children: Node = [], footer: Node = [])) -> Element {
    return html """
      <article>
        <h2>{props.title}</h2>
        <slot />
        <footer><slot name="footer"><small>no footer</small></slot></footer>
      </article>
    """;
}
```

**Markup inside an expression.** No ternary, no `&&` value; markup begins where a lambda, `if` or
`case` yields its value (Astro's `{items.map((x) => <li>{x}</li>)}`, `{cond && <p/>}`,
`{cond ? <a/> : <b/>}`):

```
{items.map({ x -> <li>{x}</li> })}
{if (visible) { <p>shown</p> }}                       // no else: nothing is rendered
{if (a) { <p>a</p> } else { <p>b</p> }}
{case status { Draft -> <em>draft</em>; _ -> <span>live</span>; }}
```

**Tag annotations** (278). Astro's `prefix:name` directives are not in the grammar. `#[name(args)]`
inside a tag resolves `name` in the caller's scope (hygiene below; unbound = the ordinary unbound-name
error at its span, never a rendered attribute) and `html` calls it at comptime with typed arguments.
Its first parameter says what it receives: `comptime decl: @Decl` — the tag's component (written on
an element: error at the annotation, "`div` is an element"); `comptime tag: Tag` — any tag (`Tag`,
declared by this front: the tag's name and, for a component, its `@Decl`). `html` acts on the
**return type**, never the name: `RawBody` (this front), the style types (119), `Hydrate` / `Defer`
(120), the transition types (126) — each arm appended by its front —, `void` a check only; any other
type is an error at the annotation, two results of one type on one tag an error at the second.
Values are not annotations: `set:html={s}` is `{raw(s)}`, `set:text={s}` is `{s}`, `class:list` is
`class={classList([…])}`. Arguments are embedded expressions — the same compiler need as holes.
This front: `isRaw`, `classList`, `Tag`; 119 `isGlobal`, `isInline`, `defineVars`; 120
`clientLoad` … `clientOnly`, `serverDefer`; 126 `transition…`.

**Hygiene, prelude.** Tag names and expressions resolve in the caller's scope; `fragment`, `raw`,
`el`, `classIf` resolve in the library (decision 112) — a page imports only what it names. In a
`.bpp` the caller's scope ends in jhonstart's `prelude.bp` (270): `<article>` resolves without a
header import, only named builders imported. This front writes
`jhonstart/modules/jhonstart/src/prelude.bp` and the node type (undeclared today).

## Open

### Step 0 — Measure the body's language, and pin the defects as red tests

- [ ] `test/platform_test.bp`, from a template body: call a bodied private function of the module;
      recurse; read `xs.at(i)`; bind a `?T`; reassign an `i32` in a nested lambda; write a `//`
      comment — one test each, passing or naming the refusal
- [ ] `src/AGENTS.md` § Comptime constraints rewritten from the six results; `html.bp:56-75` keeps only what holds
- [ ] four red tests, one per § Goal defect row: dropped static attribute, attribute value with a
      space, nested self-closing tag, element-valued hole

No recursion → parse with the function's explicit stack, plus a `language-gaps.md` row.

### Step 1 — Attributes render

`name="text"` (to the closing quote), `name={expr}`, bare `name`, kebab-case. `bool`: bare
attribute when true, nothing when false; `?string`: nothing when null. `{...expr}` on an
**element** appends an `Array<#(string, string)>` (what `formAttrs(binding)`, `styled(tokens)`
answer); on a component refused (`props-f`). `[name]={expr}` refused with a message naming
`name={expr}`; its code uses rewritten in the same landing — `jhonstart-html`'s `html_test.bp`,
`elements_test.bp`, and the § Owns carve-outs `jhonstart-emilia`'s `bridge_test.bp`,
`document-shell`'s `shell_dsl.bp`, each before the owning front opens (189). Component attributes
per 192 (§ Mechanism). Native-tag attributes (`fn <tag>(children: Children, attrs: Array<#(string,
string)> = [])`): `props-d`.

- [ ] `<a href="/a b" title={t} hidden={off} data-x="1">` renders all four as written, escaped by `escape.attribute`
- [ ] `<form {...formAttrs(binding)}>` renders the pairs in order, after the written attributes
- [ ] step 0's attribute red tests green
- [ ] `grep -rn '\]={' repository/*/` over `.bp` files finds no bracket attribute

### Step 2 — Holes of any renderable type, and the tag-shaped corners

`{expr}` under 190, 191, 204 (raw text via `build` until typed embedded expressions); void and
self-closing tags in place; `<>…</>`, `<Fragment>`; `<!-- … -->` (rendered); doctype; raw-text
elements (`script`, `style`, `textarea`, `title`) unparsed; `#[isRaw]` on any element (278).

- [ ] `examples/template-expressions-example.bp` passes on both targets
- [ ] `{n}` for an `i32` renders its `toString()` text, same on both targets (191 — the box once asked for a refusal)
- [ ] record, optional, function, other-base component in a hole each refused at the expression
- [ ] `<br/>` inside `<p>` renders inside `<p>`

### Step 3 — Markup inside `if`, `case` and lambdas

- [ ] § Mechanism's four forms render; `if` without `else` renders nothing when false
- [ ] markup elsewhere (`{1 + <p/>}`, a non-lambda-body argument) fails at the `<`, naming the three allowed positions
- [ ] three nesting levels — list of lists of conditionals — in one template

### Step 4 — Components and slots

Tag → call with props from attributes (192); tag content = `children` (193, 223). Slot boxes wait on `props-e`.

- [ ] `examples/components-and-slots-example.bp` passes on both targets
- [ ] upper-case tag resolving to nothing in the caller's scope fails at the tag, as an unbound name
- [ ] content to a component without `children` fails at the tag; a narrower `children` type refuses what it does not name
- [ ] `slot="x"` on a child of an **element** (not a component) is a compile error
- [ ] slot transfer (`<slot name="head" slot="head" />`) through two layouts

### Step 5 — Tag annotations, `raw`, `classList` (278)

The § Mechanism arm: resolve, call with what the first parameter asks for, act on the return type.
Astro's `set:html={s}` is `{raw(s)}` (the core's `raw`, unescaped); `set:text` has no form — `{s}`
already escapes. `classList(xs: Array<string>) -> string` drops empty strings and joins with one
space: `class={classList(["box", classIf(isRed, "red"), extra])}`; `classIf(cond, name)` answers the
name or `""`. `#[isRaw]` returns `RawBody`: the tag's body is text.

- [ ] `examples/directives-example.bp` passes on both targets
- [ ] `<div #[fooBar]>` fails at `fooBar` as an unbound name; `<div class:list={…}>` fails at
      `class:list`, naming `class={classList(…)}`; `set:html` likewise, naming `{raw(…)}`
- [ ] an annotation whose first parameter is `@Decl` written on an element fails at the annotation
- [ ] an annotation returning a type `html` has no arm for fails at the annotation, naming the type;
      two `RawBody` on one tag fail at the second; a `void` annotation runs and changes nothing
- [ ] `<Carousel #[clientVisible("200px"), transitionPersist] />` = two annotations in order;
      two `#[…]` blocks on one tag accepted, the editor overlay hinting the joined form (279)
- [ ] an annotation's argument of the wrong type fails at the argument (raw text via `build` until
      typed embedded expressions, as holes)

### Step 6 — The overlay, and the prelude

Every new token reaches the `CustomNode` tree: component tag carries its `Binding`
(go-to-definition → the function), component attribute name = `property`, an annotation's name
carries its `Binding` as a component tag does (go-to-definition → the annotation function),
expression region left to the host language. jhonstart's `prelude.bp` (270) written, compiled,
tested with the core.

- [ ] language server's `@ExprCustom` snapshot for a template with a component, a slot, an
      annotation (`language-server/snapshots/lsp/` — recorded here, owned by `01-compiler/26`; a
      hand-off if closed to a library front)
- [ ] mismatched close tag underlines the tag, not the template
- [ ] core declares `Node` (223) — 191's set — importable `import {Node} from "jhonstart";`; a
      `children: Node` field coerces as `Children` does (coercion keyed on the name `Children`: if
      it must learn `Node`, hand-off to `01-compiler/01-checker`, named here before closing)
- [ ] `jhonstart/src/prelude.bp` holds `import` items of the core's own modules only (`Element`,
      `ElementBase`, `View`, builders, `Node`), compiles with the member
- [ ] `element.bp` declares `pub type View = @Component<ElementBase, Element>;` (decision 276) and the
      prelude imports `View`; a cell shows `-> View` and `-> @Component<ElementBase, Element>` accepted
      for one another
- [ ] `html` declares `-> @ExprCustom<View>` (decisions 275, 276): a `.bpp` and a `.bp` that
      `return html """…"""` both return `View`; the 12 files that use `html """` and the track's
      examples written `-> Element` follow
- [ ] `#[client]` (`client.bp`, today a text comparison with `"@Component<ElementBase, Element>"`)
      accepts a component declared `-> View`: it compares the resolved type (decision 276)
- [ ] examples' `Children` → `Node`: `grep -rnw Children 08-bpp/*/examples` (33 lines in 16 files today) is empty

## Decisions

- `props-d` — attributes of a **native** HTML tag (192 covers components only) — steps 1, 4
- `props-e` — **named slot** onto props (193 names `children` only) — step 4
- `props-f` — `{...expr}` on a component — step 1

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test --target commonJS` and `--target erlang` green in `modules/jhonstart-html`
- [ ] `zig build test-libs`: jhonstart, emilia, erika, onze — the 12 DSL files — green

## Blast radius

- **12 DSL files; four bracket attributes in code rewritten** (this member's two tests,
  `jhonstart-emilia`'s bridge test, `document-shell`); emilia's are comments (34, 33).
- **Templates with static attributes change output** (absent today, present after step 1); pinned
  snapshots/literals move — step 1 lists them first.
- **`html.bp` grows several-fold in a comptime body**; speed is gated: step 6 reports
  `jhonstart-markup` template-evaluation time before/after.
- **119, 120, 126 append to `html.bp`**, after this front, one at a time.

## Notes

- **Hand-offs.** Renaming every
  `Children` signature (`element.bp`, `elements.bp`) and moving children into props in every track
  member component are hand-offs to `05-jhonstart`
  ([`../../05-jhonstart/README.md`](../../05-jhonstart/README.md) § Handed to this track by
  `08-bpp/118`), not steps here.
- **Not added.** Dynamic tags (`<Element>` from a variable): `{el(tag, children, attrs)}` in a hole. `.html`/`.svg` components:
  comptime cannot read a file (lg2-o); paste the markup.
- **`Astro.self`** = own name; **`Astro.props`** = props parameter; **`Astro.slots.has("x")`** = `hasContent(x)`.
