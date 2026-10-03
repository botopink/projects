# Front 118 — bpp components: the template language

**Priority:** critical — every other front of the track writes markup through it, and it is the
only one none of them can be tested without.
**Depends on:** `00-gate` (`101-gate-jhonstart`). Nothing in this track, and no open question:
what a template accepts is decided — 190 (`08-c`: the library decides the types of an embedded
expression; the surface is `{expr}`), 191 (the closed list `jhonstart-html` accepts), 192 (a
component's attributes are the fields of its first parameter's type), 193 (children go through
the props).
**Owns:** `repository/jhonstart/modules/jhonstart-html/**` (`src/html.bp`, `src/root.bp`,
`test/**`, `botopink.json`, `src/AGENTS.md`) — the front lands there, and `05-jhonstart/26`
step 0 then merges the member into the core, `html` becoming the core's `pub default fn`
(decision 200); the appends of 119, 120 and 126 are to `jhonstart/src/html.bp` · `repository/jhonstart/examples/jhonstart-markup/**`
except its `README.md` (`05-jhonstart/26` step 6) · the one-line carve-outs of step 1: each
`[name]={expr}` attribute outside this member — in emilia's `attributes.bp` and `emilia.bp`
(`06-emilia/34`'s files), `examples/emilia-card` (`06-emilia/33`'s), the two files of the core
that use the DSL (`05-jhonstart/26`'s), `jhonstart-emilia`'s bridge test (119's), `document-shell`
— rewritten by this front, one commit per repository, landed before the owning front opens
(decision 189)
**Does not touch:** `modules/jhonstart/**` beyond those lines (`05-jhonstart/26`'s — a need there
is reported, § Handed); the compiler; emilia beyond those lines. Fronts 119, 120 and 126 each
**append** one lowering arm to `html.bp` after this front lands, in that order (`fronts.md` rule 2).

Reference: `astro-docs/09-astro-components.md`, `10-layouts.md`, `13-astro-syntax.md`.

---

## Problem

`html """…"""` is the markup DSL the stack has, and a page cannot be written in it:

```bp
val cls = "card";
val page = html """<div class="card" [id]={cls}><p>${name}</p><br/></div>""";
```

| What the author wrote | What happens | Where |
|---|---|---|
| `class="card"` | dropped — a static attribute goes to the editor overlay and never to the `Element` | `html.bp:138-146`, `:233-234` |
| `[id]={cls}` | the one attribute form that renders | `html.bp:117-136`, `:241` |
| `title="two words"` | the tag body is split on single spaces, so the value is cut | `html.bp:110` |
| `${name}` | lowered to `text(name)` — a hole is a string; an `Element`, a list, an `if` cannot be one | `html.bp:189` |
| `<br/>` | stored and emitted after the loop, at the root, not inside `<div>` | `html.bp:212-217`, `:250-253` — read, not run |
| `<Card title="x"/>` | lowered like any tag: `Card([…], attrs: […])` | `html.bp:231`; "`<Component/>` lookup stays a future layer" (`:30`) |
| a comment, a fragment, a slot, a loop, a condition | not in the grammar | — |

So every page in the tree is written with builders (`onze/examples/blog/src/app/blog/[slug]/page.bp:9-16`),
and the DSL has 12 files using it — four of them its own tests.

## Current state

Measured 2026-10-01 at `repository/jhonstart/modules/jhonstart-html/`:

| | |
|---|---|
| `src/html.bp` | 270 lines; one function, `pub fn html(comptime template: @Expr<string>) -> @ExprCustom<Element>` (`:95`) |
| `test/` | 2 files, 34 lines |
| Files using `html """` | 12: jhonstart-html 4, jhonstart 2, document-shell 2, jhonstart-markup 1, jhonstart-emilia 1, emilia 1, erika-linq 1 |
| `[name]={expr}` uses | 10, in 7 files (emilia's `attributes.bp` and `emilia.bp` among them) |
| Manifest `target` | `commonJS`; the workspace gives both rows |

The body is written under the rules its header states (`html.bp:56-75`): no optional, no array
index, no comment inside the body, a counter reassigned only in the flat loop, the token tuple
read positionally. Those rules were written for an evaluator that has since been replaced
(decisions 83 · 84 — comptime runs on the BEAM and wat runtimes); which of them still hold is not
known, and step 0 finds out.

The building blocks the lowering targets exist in the core member: `Element(tag, value, children,
attrs)` (`jhonstart/src/element.bp:12-17`), `el(tag, children, attrs)` and `voidEl(tag, attrs)`
(`elements.bp:31`, `:43`), `fragment` (`element.bp:27`), `raw(html)` (`render.bp:204`), and
`Children`, which coerces from a list, one `Element` or a `string` (`element.bp:122-132`). The
renderer escapes text and attributes and refuses `</script` inside a raw-text body
(`render.bp:158-200`).

## Mechanism

The function keeps its shape — lex, parse, lower twice (code and `CustomNode` overlay), return
`q.custom(overlay, q.build(code))` — and its grammar grows to this:

```
template  := node*
node      := element | component | fragment | text | comment | hole | slot
element   := '<' name attr* '>' node* '</' name '>'  |  '<' name attr* '/>'
component := the same, with a name that starts with an upper-case letter
attr      := name | name '=' '"' text '"' | name '=' '{' expr '}' | '{...' expr '}' | directive
directive := prefix ':' name ( '=' value )?          set: class: is: client: server: transition: define:
hole      := '{' expr '}'  |  '${' expr '}'
expr      := botopink, in which markup may start a lambda body, an if / else block or a case arm
```

**A hole is one of a closed list** (decisions 190, 191). The library — this template function —
decides which types an embedded `{expr}` may have and refuses the others with a comptime error
located at the expression. It accepts: a `string`; a number of any numeric type and a `bool`,
each written as its `toString()` text, the same on every target; a component of the same base
context as the template (an `Element` whose base is `ElementBase`); a list of such components;
and the node type, which names exactly that set. A record, an optional, a function and a
component of another base are refused. `{expr}` is the surface; `${expr}` keeps working and keeps
its meaning — text — and the located diagnostics a real hole has. The compiler owes the means —
an embedded expression of any type reaching the template function with its type readable at
comptime and its position (`language-gaps.md`, owner `01-compiler`); until it does, `{expr}` is
read out of the literal's raw text and re-emitted through `build`, where a wrong type is the
checker's own error at the template call, and the function moves to the typed form without
changing the surface.

**A component's attributes are its props** (decision 192). The attributes written on `<Comp …>`
are the fields of the type of the **first parameter** of `Comp`'s function: each name must be one
of those fields and each value — a literal or `{expr}` — has that field's type. An attribute the
parameter does not declare, a value of another type, and a field with no default left unwritten
are comptime errors located at the attribute. **Children go through the props** (decision 193):
a component takes children only when that type declares a `children` field, whose type says what
is acceptable — `children: Node`, the node type (the set of decision 191; the type
jhonstart calls `Children` today takes this name). Content inside the tag of a component whose
props declare no `children` is a comptime error located at the tag, a `children` field of a
narrower type refuses what it does not name, and a second `children` parameter beside the props
goes away.

The paragraphs and the table below, down to the slot example, were written before decisions 192
and 193: they lower a component to a call with labelled arguments and take a slot as a
`Children` parameter. Under the decisions the arguments are the fields of one props value and
`children` is one of them; how a named slot (`slot="footer"`) maps onto the props is not stated
by either decision (§ Notes — open).

**A component is a call with labelled arguments.** Labels name parameters on every call path and a
parameter default is applied at the call (`docs.md:1333-1375`), so there is no props object:

| Markup | Lowering |
|---|---|
| `<Card title="Hi" count={n} />` | `Card(title: "Hi", count: n)` |
| `<Card title="Hi"><p>body</p></Card>` | `Card(title: "Hi", children: [p(["body"])])` |
| `<Card><p slot="footer">x</p><p>body</p></Card>` | `Card(children: [p(["body"])], footer: [p(["x"])])` |

and a slot is a `Children` parameter with a default:

```bp
pub fn Card(title: string, children: Children = [], footer: Children = []) -> @Component<ElementBase, Element> {
    return html """
      <article>
        <h2>{title}</h2>
        <slot />
        <footer><slot name="footer"><small>no footer</small></slot></footer>
      </article>
    """;
}
```

`<slot />` reads `children`; `<slot name="footer">fallback</slot>` reads `footer` and renders the
fallback when it is empty. A component that declares no `footer` parameter and is given
`slot="footer"` fails where the call is checked, with the parameter's name — the checker's own
error, not a rule this front writes.

**Markup inside an expression.** Astro writes `{items.map((x) => <li>{x}</li>)}`,
`{cond && <p/>}` and `{cond ? <a/> : <b/>}`. The language has no ternary and no `&&` value
(`docs.md:2334-2335`); it has lambdas, and `if` and `case` are expressions. So markup may begin
exactly where one of those yields its value:

```
{items.map({ x -> <li>{x}</li> })}
{if (visible) { <p>shown</p> }}                       // no else: nothing is rendered
{if (a) { <p>a</p> } else { <p>b</p> }}
{case status { Draft -> <em>draft</em>; _ -> <span>live</span>; }}
```

**A directive is checked against a table.** `prefix:name` on a tag is looked up; one the table
does not hold is a compile error at its span — it never falls through to a rendered attribute.
This front fills the `set:`, `class:` and `is:raw` rows; 119 adds `is:global` and `define:`, 120
`client:` and `server:`, 126 `transition:`.

## Steps

### Step 0 — Measure the body's language, and pin the defects as red tests

- [ ] `test/platform_test.bp`: from a template body — call a bodied private function of the
      module; recurse; read `xs.at(i)`; bind a `?T`; reassign an `i32` inside a nested lambda;
      write a `//` comment. Each is one test that passes or names the refusal
- [ ] `src/AGENTS.md` § Comptime constraints rewritten from the six results; `html.bp:56-75`
      keeps only what is still true
- [ ] four red tests, one per row of § Problem that is a defect: the dropped static attribute, the
      attribute value with a space, the nested self-closing tag, the element-valued hole

A parser for the grammar above wants recursion. If the body cannot recurse, the grammar is
parsed by the explicit stack the function already uses, and `language-gaps.md` gets the row.

### Step 1 — Attributes render

`name="text"` (any text up to the closing quote), `name={expr}`, a bare `name`, kebab-case names.
A `bool` expression renders the bare attribute when true and nothing when false; a `?string`
renders nothing when null. `{...expr}` on an **element** appends an `Array<#(string, string)>` —
the list `formAttrs(binding)` and `styled(tokens)` already answer; on a component it is a compile
error, because a component's attributes are labelled arguments and there is no record to spread. `[name]={expr}` is refused with a message naming `name={expr}`, and its
10 uses are rewritten in the same landing — the ones outside this member as the one-line
carve-outs § Owns names, each landed before the front that owns the file opens (decision 189).

On a **component** tag an attribute is a field of the props (decision 192): its name is checked
against the fields of the first parameter's type and its value against that field's type, and
the three refusals — an undeclared attribute, a value of another type, a field with no default
left unwritten — are comptime errors located at the attribute. The rule for the attributes of a
**native** tag (`fn <tag>(children: Children, attrs: Array<#(string, string)> = [])`) is not
covered by the decision and is still to be stated (§ Notes — open).

**Acceptance:**
- [ ] `<a href="/a b" title={t} hidden={off} data-x="1">` renders all four as written, escaped by
      `escape.attribute`
- [ ] `<form {...formAttrs(binding)}>` renders the pairs in order, after the written attributes
- [ ] the four red tests of step 0 that concern attributes are green
- [ ] `grep -rn '\]={' repository/*/` over `.bp` files finds no bracket attribute

### Step 2 — Holes of any renderable type, and the tag-shaped corners

`{expr}`; void and self-closing tags in place; `<>…</>` and `<Fragment>`; `<!-- … -->` (rendered);
a doctype; raw-text elements (`script`, `style`, `textarea`, `title`) whose body is not parsed;
`is:raw` on any element.

The step is written against decision 190 and is not blocked: it reads `{expr}` from the raw text
and re-emits it through `build` until the compiler provides typed embedded expressions. The rule
it implements is decision 191's closed list — a `string`; a number of any numeric type and a
`bool`, each as its `toString()` text; a component of the same base context; a list of such
components; the node type — and everything else is a comptime error located at the expression.
The acceptance below predates the two decisions: it needs a refusal case per rejected type (a
record, an optional, a function, a component of another base), and its second box (`{n}` for an
`i32` fails) states the opposite of decision 191, under which `{n}` renders the number's text.

**Acceptance:**
- [ ] `examples/template-expressions-example.bp` passes on both targets
- [ ] `{n}` for an `i32` fails with the checker's own mismatch, at the template call
- [ ] `<br/>` inside `<p>` renders inside `<p>`

### Step 3 — Markup inside `if`, `case` and lambdas

**Acceptance:**
- [ ] the four forms of § Mechanism render; an `if` without `else` renders nothing when false
- [ ] markup in any other expression position (`{1 + <p/>}`, an argument that is not a lambda body)
      fails at the `<`, naming the three positions that allow it
- [ ] three levels of nesting — a list of lists of conditionals — in one template

### Step 4 — Components and slots

A component tag lowers to a call whose first argument is the props value built from the tag's
attributes (decision 192), and the content inside the tag is the props' `children` field
(decision 193): a component whose props declare no `children` and is given content fails at the
tag, and `children: Node` accepts the set of decision 191. The acceptance below predates
the two decisions — it needs a case for content given to a component without a `children` field,
one for a `children` field of a narrower type, and its slot boxes wait on how a named slot maps
onto the props (§ Notes — open).

**Acceptance:**
- [ ] `examples/components-and-slots-example.bp` passes on both targets
- [ ] a tag whose name starts upper-case and resolves to nothing in the caller's scope fails at
      the tag, as an unbound name
- [ ] `slot="x"` on a child of an **element** (not a component) is a compile error
- [ ] slot transfer (`<slot name="head" slot="head" />`) through two layouts

### Step 5 — `set:html`, `set:text`, `class:list`, and the directive table

`set:html={s}` is `raw(s)` as the element's only child — children beside it are a compile error;
`set:text={s}` is the escaped form; `class:list={[…]}` takes an `Array<string>`, drops empty
strings and joins with one space, merged after a static `class`. `classIf(cond, name)` answers the
name or `""`.

**Acceptance:**
- [ ] `examples/directives-example.bp` passes on both targets
- [ ] `<div foo:bar="1">` fails at `foo:bar` with the list of known prefixes
- [ ] `<div set:html={s}>x</div>` fails at the child

### Step 6 — The overlay

Every token the grammar adds reaches the `CustomNode` tree: a component tag carries its `Binding`
(go-to-definition lands on the function), an attribute name of a component is a `property`, a
directive is a `keyword`, an expression region is left to the host language.

**Acceptance:**
- [ ] the language server's `@ExprCustom` snapshot for a template with a component, a slot and a
      directive (`language-server/snapshots/lsp/` — the snapshot is recorded by this front and
      owned by `01-compiler/26`; the row goes in § Handed if the directory is closed to a library
      front)
- [ ] a mismatched close tag underlines the tag, not the template

## Gate

- [ ] `botopink test --target commonJS` and `--target erlang` green in `modules/jhonstart-html`
- [ ] `zig build test-libs`: jhonstart, emilia, erika and onze — the 12 files that use the DSL —
      green
- [ ] `scripts/gate.sh --cold` green in the front's worktree
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/118-bpp-components`; landing is the maintainer's step

## Blast radius

- **12 files use the DSL; 10 bracket attributes are rewritten** (emilia's `attributes.bp` and
  `emilia.bp`, `jhonstart-emilia`'s bridge test, `document-shell`, `emilia-card`).
- **A template that has a static attribute changes its output.** Today the attribute is silently
  absent from the HTML; after step 1 it is there. Every snapshot or literal that pinned the
  absence moves — step 1 lists them before it changes them.
- **`html.bp` grows several times over**, inside a comptime body. Its speed is part of the gate:
  step 6 reports the template-evaluation time of `jhonstart-markup` before and after.
- **Fronts 119, 120, 126 append to `html.bp`.** They land after this front and one at a time.

## Notes

- **Open, after decisions 190–193.** (1) The rule for the attributes of a **native** HTML tag
  (`fn <tag>(children: Children, attrs: Array<#(string, string)> = [])`) is still to be stated:
  decision 192 covers component tags only. (2) How a **named slot** (`<p slot="footer">`,
  `<slot name="footer">`) maps onto the props: decision 193 names the `children` field and no
  other. (3) Whether `{...expr}` on a component becomes legal now that its attributes are the
  fields of one record — step 1 refuses it for a reason decision 192 removes. (4) The rename of
  `Children` to `Node` and the move of a component's children into its props touch
  `modules/jhonstart/src/element.bp` (frozen) and every component of the track's members: they
  are hand-offs to `05-jhonstart` ([`../../05-jhonstart/README.md`](../../05-jhonstart/README.md)
  § Handed to this track by `08-bpp/118`), not steps of this front.
- **What is not added.** A props spread on a component (`<Card {...props} />`): a labelled call
  is the form. Dynamic tags (`<Element>` from a variable): `{el(tag, children, attrs)}` in a hole
  is the form, and it is ordinary code. `.html` and `.svg` files as components: a comptime body
  cannot read a file (`language-gaps.md` lg2-o); the markup is pasted into a component.
- **`Astro.self`** is the function's own name; **`Astro.props`** are its parameters;
  **`Astro.slots.has("x")`** is `hasContent(x)`.
- **Hygiene.** A tag name and an expression come from the literal and resolve in the caller's
  scope; `fragment`, `raw`, `el`, `classIf` are written by the library and resolve in the library
  (decision 112) — so a page imports the builders and components it names, and nothing else.
  In a `.bpp` file the builders come from jhonstart's `prelude.bp` (decision 266): the caller's
  scope ends in the prelude, so `<article>` resolves without a header import and only the builders
  a file names are imported. This front writes `jhonstart/modules/jhonstart/src/prelude.bp` (a
  carve-out of `05-jhonstart/26`'s member) and the type `Children` the track's examples use, which
  jhonstart does not declare today.
