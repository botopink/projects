# Front 118 — bpp components: the template language

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [149-jhonstart](../README.md): open → 149 s4 · gate → 149 s4. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** critical — every other front writes markup through it; none is testable without it.
· **State:** partial — what it builds alone is done; the rest on `01-compiler/130` step 9,
`01-checker` step 34 and its `View` rows, `01-compiler/26`, `05-jhonstart/26` step 13 (§ Open)
**Depends on:** nothing open (`00-gate/101-gate-jhonstart` done). Written against decisions 190,
191, 192, 193 and 223, 204, 207, 200, 270, 189, 278.
**Owns:** `repository/jhonstart/modules/jhonstart-html/**` (`src/html.bp`, `src/root.bp`,
`test/**`, `botopink.json`, `src/AGENTS.md`) — lands there; `05-jhonstart/26` step 0 then merges
it into the core, `html` the core's `pub default fn` (200); 119, 120, 126 append to
`jhonstart/src/html.bp` · `repository/jhonstart/examples/jhonstart-markup/**` except its
`README.md` (`05-jhonstart/26` step 6) · new `jhonstart/modules/jhonstart/src/prelude.bp` and the
core's node type `Node` (223; carve-outs of `05-jhonstart/26`'s member, 270) · the `Children` →
`Node` rewrite of this track's `examples/**` · step 1's one-line carve-outs: each `[name]={expr}`
attribute outside this member in code — `jhonstart-emilia`'s bridge test (119's),
`examples/document-shell` — one commit per repository, landed before the owning front opens (189)
**Does not touch:** `modules/jhonstart/**` beyond those lines (`05-jhonstart/26`'s — a need is a
hand-off, § Notes); the core's comment lines naming the DSL (`root.bp`, `elements.bp`) — a
comments-only carve-out is taken by the owning front, `05-jhonstart/26` (`ctr-v` (a)); the compiler;
emilia — its `[class]={…}` lines are comments, reworded by `06-emilia/34` step 1,
`examples/emilia-card`'s by `06-emilia/33` step 2. 119, 120, 126 each
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
annotation := '#[' item ( ',' item )* ','? ']'      a tag may carry several blocks (286)
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

**Slots** (decision 360, Astro's in annotation form — never props). `<Slot />` renders the default
slot; `<Slot name="footer">fallback</Slot>` declares and renders the `footer` slot; a child
`#[slot("footer")]` fills it; `use hasSlot("footer")` tells whether it was filled:

```bp
pub default fn Card(props: type(title: string)) -> View {
    return html """
      <article>
        <h2>{props.title}</h2>
        <Slot />
        <footer><Slot name="footer"><small>no footer</small></Slot></footer>
      </article>
    """;
}

<Card title="Hi">
  <p>body</p>                          <!-- default slot -->
  <p #[slot("footer")]>© 2026</p>     <!-- footer slot; "foter" would be a compile error -->
</Card>
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

**Tag annotations** (278, 302: the same thing as a declaration's decorator — `fn name(comptime decl:
@Decl, …)`, no return, typed meta through `decl`). Astro's `prefix:name` directives are not in the
grammar. `#[name(args)]` inside a tag resolves `name` in the caller's scope (hygiene below; unbound = the
ordinary unbound-name error at its span, never a rendered attribute) and `html` calls it at comptime with
typed arguments. `decl.kind` says what it receives — `Element` (a native tag: `decl.name`, its static
attributes) or `Component` (`decl.component` the component's own `@Decl`); an annotation that takes only
one refuses the other at the annotation ("`div` is an element"). `html` reads the **meta the annotation
records**, by type, never the name: `RawBody` (this front), `isInline`'s style meta (119; `isGlobal` and `defineVars` went with 338), `Hydrate` / `Defer`
(120), the transition types (126), `styled`'s `StyledMeta` (383) — each reader appended by its front —; an
annotation that records nothing is a check only; a meta type no reader knows is another reader's (302),
two `setMeta` of one type on one tag an error at the second.
Values are not annotations: `set:html={s}` is `{raw(s)}`, `set:text={s}` is `{s}`, `class:list` is
`class={classList([…])}`. Arguments are embedded expressions — the same compiler need as holes.
This front: `isRaw`, `classList` (no `Tag` type — 302); 119 `isInline` (`isGlobal`, `defineVars` gone, 338); 120
`clientLoad` … `clientOnly`, `serverDefer`; 126 `transition…`.

**Hygiene, prelude.** Tag names and expressions resolve in the caller's scope; `fragment`, `raw`,
`el`, `classIf` resolve in the library (decision 112) — a page imports only what it names. In a
`.bpp` the caller's scope ends in jhonstart's `prelude.bp` (270): `<article>` resolves without a
header import, only named builders imported. This front writes
`jhonstart/modules/jhonstart/src/prelude.bp` and the node type (undeclared today).

## Decisions

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
  member component, and the builders the core lacks (`em`, `strong`, `small`, `pre`, `code`, `ol`,
  `figure`, … — a template's tag resolves to a builder in scope, so today a page declares them with
  `el`), are hand-offs to `05-jhonstart`
  ([`../../05-jhonstart/README.md`](../05-jhonstart/track.md) § Handed to this track by
  `08-bpp/118`), not steps here.
- **Not added.** Dynamic tags (`<Element>` from a variable): `{el(tag, children, attrs)}` in a hole. `.html`/`.svg` components:
  none — `@embedFile` (342) reads the file as text, which a component may hold; no file becomes a component.
- **`Astro.self`** = own name; **`Astro.props`** = props parameter; **`Astro.slots.has("x")`** = `hasContent(x)`.
