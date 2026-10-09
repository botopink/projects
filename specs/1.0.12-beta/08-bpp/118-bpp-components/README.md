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

**Slots.** `<slot />` reads `children`; `<slot name="footer">fallback</slot>` renders the fallback
when empty. Named-slot mapping (`<p slot="footer">` / `<slot name="footer">`) is open (`props-e`);
`footer` as a props field below is one reading, not a decision:

```bp
pub default fn Card(props: type(title: string, children: Node = [], footer: Node = [])) -> View {
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

**Tag annotations** (278; **since 302 the same thing as a declaration's decorator**: `fn name(comptime
decl: @Decl, …)`, no return, typed meta through `decl` — the text below reads "return type" as "meta
the annotation records", and `comptime tag: Tag` as `comptime decl: @Decl` of kind `Element`). Astro's `prefix:name` directives are not in the grammar. `#[name(args)]`
inside a tag resolves `name` in the caller's scope (hygiene below; unbound = the ordinary unbound-name
error at its span, never a rendered attribute) and `html` calls it at comptime with typed arguments.
Its first parameter says what it receives: `comptime decl: @Decl` — the tag's component (written on
an element: error at the annotation, "`div` is an element"); `comptime tag: Tag` — any tag (`Tag`,
declared by this front: the tag's name and, for a component, its `@Decl`). `html` acts on the
**return type**, never the name: `RawBody` (this front), `isInline`'s style meta (119; `isGlobal` and `defineVars` went with 338), `Hydrate` / `Defer`
(120), the transition types (126) — each arm appended by its front —, `void` a check only; any other
type is an error at the annotation, two results of one type on one tag an error at the second.
Values are not annotations: `set:html={s}` is `{raw(s)}`, `set:text={s}` is `{s}`, `class:list` is
`class={classList([…])}`. Arguments are embedded expressions — the same compiler need as holes.
This front: `isRaw`, `classList` (no `Tag` type — 302); 119 `isInline` (`isGlobal`, `defineVars` gone, 338); 120
`clientLoad` … `clientOnly`, `serverDefer`; 126 `transition…`.

**Hygiene, prelude.** Tag names and expressions resolve in the caller's scope; `fragment`, `raw`,
`el`, `classIf` resolve in the library (decision 112) — a page imports only what it names. In a
`.bpp` the caller's scope ends in jhonstart's `prelude.bp` (270): `<article>` resolves without a
header import, only named builders imported. This front writes
`jhonstart/modules/jhonstart/src/prelude.bp` and the node type (undeclared today).

## Done

Landed in `jhonstart-html` (tests in `test/`, refusals in the workspace's `refusals/html_*`), the
core's `node.bp`, `prelude.bp` and `element.bp`'s `View`; green on commonJS and erlang.

- Step 0: `test/platform_test.bp` — a call out of the body (private, `pub` or imported) and recursion
  refused (rows **A template body cannot call a function**), `xs.at(i)`, a `?T`, a nested `i32`, a
  `//` comment work; `src/AGENTS.md` § Comptime constraints from those results plus three met while
  writing (statement closures, label reads, the bounded frame); `test/defects_test.bp` pins the
  four § Goal defects, red on the old body, green now.
- Step 1: `name="text"`, `'text'`, `name={expr}` (`string`, `bool` bare / absent, `?string` absent
  when null), bare; `[name]={…}`
  refused naming `name={…}`, its code uses rewritten (`html_test.bp`, `elements_test.bp`,
  `jhonstart-emilia`'s `bridge_test.bp`, `document-shell`'s `shell_dsl.bp`); `{...}` on a component
  refused (props-f, the recommended reading); the five basic entities decoded, any other refused.
- Step 1, decision 351's names (part): a multi-word attribute is camelCase and renders in HTML's
  spelling (`ariaLabel` → `aria-label`, `httpEquiv` → `http-equiv`, `encType` → `enctype`), `data-*`
  the one kebab-case family and a `string` (`data-x={true}` the checker's type mismatch); any other
  kebab-case name refused naming its camelCase form, an event attribute (`onClick`) refused at its
  name, the pair spread `{...pairs}` on an element refused (`refusals/html_kebab_attribute`,
  `html_event_attribute`, `html_element_spread`, `html_data_attribute_type`; the spread test of
  `template_test.bp` replaced by the two naming tests).
- Step 2: a hole lowers through core `Node` — text for a string, a number or a `bool`, an `Element`,
  a list; a `?T`, a record, a function are the checker's type mismatch at the literal's line
  (`refusals/html_hole_*`); void and self-closing tags in place, `<>` / `<Fragment>`, comments and
  `<!doctype>` rendered, raw-text bodies unparsed; the spec example landed as
  `test/template_expressions_example_test.bp`.
- Step 3: markup after `->` (lambda body, `case` arm) and at the start of an `if` / `else` block; an
  `if` without `else` gets `else { htmlFragment([]) }`; markup anywhere else fails at the `<`
  (`refusals/html_markup_operand`); three nesting levels in `template_test.bp`.
- Step 4 (part): a component tag is a call — attributes as labelled arguments, content as
  `children` (one bare, several a list), `<slot />` / `<slot>fallback</slot>` read the `children`
  parameter; an unbound upper-case tag fails at the tag; content to a component without `children`
  and a narrower `children` are refused (`refusals/html_component_without_children`,
  `html_narrower_children`); `slot="…"` refused on any child (`refusals/html_slot_attribute`); the
  spec example landed without its named slots as `test/components_and_slots_example_test.bp`.
- Step 5 (part): `{raw(s)}`, `classList` / `classIf` (in `html.bp`, the core's at 26 step 0),
  `hasContent`; `#[isRaw]` makes the body text, a second one refused; an unbound annotation fails at
  its name; `class:list`, `set:html`, `set:text` and any `prefix:name` refused naming their form;
  the spec example landed without `#[mustBeBox]` as `test/directives_example_test.bp`.
- Step 6 (part): the overlay carries a component's and an annotation's `Binding`, attribute names as
  `property`; a mismatched close fails at the tag (`refusals/html_mismatched_close`); core `node.bp`
  declares `Node` as a union — a `children: Node` field takes a list, an `Element`, a string without
  learning anything from the checker; `prelude.bp` (core imports only, `timeTag as time`) compiles
  with the member; `element.bp` declares `View`, `test/view_test.bp` returns each spelling from the
  other; the track's examples write `Node`. `jhonstart-markup` build (7 templates, three runs):
  commonJS 1.8 s → 3.6 s, erlang 3.2 s → 3.7 s.

## Open

- Step 1 — native-tag props (decision 351 (1), (2), (4), (5)): each builder takes its element's
  props record (`GlobalAttrs`, `AriaAttrs` and the element's own, layered with `Type.merge`), lowered
  as a component tag, so an unknown attribute, a value of the wrong type and content in a void
  element are refused; a tag the prelude does not name refused at the tag; the element spread takes
  the element's props type. Blocked three ways, measured on botopink-lang `56d4bc29`:
  `pub val AnchorProps = Type.merge(GlobalAttrs, AnchorAttrs);` used as a parameter type is
  `'AnchorProps' is a value, not a type` (`01-checker` s28); a named props record is filled by no
  labelled call (`<anchor href="/x">` → `'anchor' expects 1 argument(s), got 2`, by hand too —
  **Template-built code cannot build an inline props type**, `01-checker`); the builders are
  `element.bp` (frozen) and `elements.bp` (`05-jhonstart/26`'s, which opens after 118) — `118-a`.
  `html`'s `lookup` answers `(name, kind)`, so a prelude builder and a local function of the same
  name are one to it (4).
- Slots and spread on a component — waiting on `props-e` (named slots, step 4) and `props-f`
  (`{...expr}` on a component, step 1, refused today as its recommendation reads).
- Step 4 — named slots and the slot transfer through two layouts: `props-e`. The props as one
  record (192, `props: type(…)`, 207): **Template-built code cannot build an inline props type**
  (`01-checker`); until then components take parameters and `<slot />` reads `children`.
- Step 5 — the 302 arm (build a tag's `@Decl`, call every annotation, read its meta by type; two
  annotations in order on `<Carousel>`; an argument of the wrong type at the argument): **A tag
  annotation cannot be called by the template function** (`01-compiler/130` step 9). The box "an
  annotation whose first parameter is `@Decl` written on an element fails" is 278's, replaced by 302
  (every annotation takes `@Decl`; on a tag its `kind` says element or component).
- Step 6 — the language server's `@ExprCustom` snapshot: hand-off to `01-compiler/26`. `html`
  declared `-> @ExprCustom<View>`: **A template function declared `-> @ExprCustom<View>` refuses
  built code of type `Element`**, and **A type alias of `@Component<…>` is not the effect in a
  return** (`01-checker`). `#[client]` comparing the resolved type: hand-off to `05-jhonstart/26`
  (decision 276 names it).
- Gate: `zig build test-libs` over jhonstart, emilia, erika, onze is the coordinator's cold gate.

## Decisions

- `props-e` — **named slot** onto props (193 names `children` only) — step 4 · waiting
- `props-f` — `{...expr}` on a component — step 1 · waiting
- `118-a` — who rewrites the native builders into props form, and when — step 1's props box

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
  member component, and the builders the core lacks (`em`, `strong`, `small`, `pre`, `code`, `ol`,
  `figure`, … — a template's tag resolves to a builder in scope, so today a page declares them with
  `el`), are hand-offs to `05-jhonstart`
  ([`../../05-jhonstart/README.md`](../../05-jhonstart/README.md) § Handed to this track by
  `08-bpp/118`), not steps here.
- **Not added.** Dynamic tags (`<Element>` from a variable): `{el(tag, children, attrs)}` in a hole. `.html`/`.svg` components:
  none — `@embedFile` (342) reads the file as text, which a component may hold; no file becomes a component.
- **`Astro.self`** = own name; **`Astro.props`** = props parameter; **`Astro.slots.has("x")`** = `hasContent(x)`.
