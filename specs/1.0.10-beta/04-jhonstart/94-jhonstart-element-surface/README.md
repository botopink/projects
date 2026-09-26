# Front 94 — Jhonstart Element Surface

**Track:** C jhonstart
**Priority:** critical — the one owner of the HTML tag constructors every other track-C front builds with
**Target:** both — the surface is rendered on the server by front 30 and hydrated in the browser by front 68, so every constructor must produce the identical `Element` on both targets
**Wave:** 0
**Depends on:** none — only the public `Element` record (`element.bp`)
**Owns:** `repository/jhonstart/modules/jhonstart/src/elements.bp` (plus its inline `test` blocks), `repository/jhonstart/modules/jhonstart-html/test/elements_test.bp`
**Does not touch:** `element.bp`, `hooks.bp`, `html.bp` (frozen), and every other front's module
**Reference:** `NEXTJS-DOCS.md § 4. App Router — Fundamentos` · Root Layout (obrigatório) · `NEXTJS-DOCS.md § 10. Mutação de Dados` · <https://html.spec.whatwg.org/multipage/indices.html#elements-3> · <https://html.spec.whatwg.org/multipage/syntax.html#void-elements> · <https://nextjs.org/docs/app/api-reference/file-conventions/layout>

---

## Outcome

`modules/jhonstart/src/elements.bp` is the element surface of the core member, imported
`from "jhonstart"` beside `element.bp`'s eight (`text`, `fragment`, `div`, `span`, `p`, `h1`, `ul`,
`li`). A reader cannot tell from a call site which file a tag came from.

| Symbol | Contract |
|---|---|
| `el(tag, children, attrs) -> Element` | the one builder every constructor funnels through, and the public escape hatch for a tag the surface does not name (`el("figure", kids, attrs: [])`) |
| `voidEl(tag, attrs) -> Element` | builds a void element with `children: []` |
| 32 non-void constructors | `a` · `nav` `section` `article` `header` `footer` `main` `aside` · `h2`–`h6` `label` `timeTag` · `form` `button` `select` `option` `textarea` · `table` `thead` `tbody` `tr` `th` `td` · `htmlTag` `head` `body` `title` `script` `style` |
| 6 void constructors | `input` `img` `meta` `link` `br` `hr` — same two parameters, the children argument is dropped |
| `isVoidTag(tag) -> bool` | the fourteen HTML void elements: `area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr`. Front 30's `renderNode` calls it and keeps no list of its own |
| `isRawTextTag(tag) -> bool` | `script` and `style` only — their text is not HTML-escaped. `title` and `textarea` are escapable raw text and are not in the set |

### One signature, copied from `element.bp`

```bp
pub fn nav(children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return el("nav", children, attrs);
}

pub fn input(_children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return voidEl("input", attrs);
}
```

Children positional, `attrs:` labeled — the exact call the `html """…"""` DSL writes
(`tag([kids], attrs: [pairs])`), so every constructor is reachable from markup. `attrs` defaults to
`[]`, and the default travels with the imported function, so `div([p([text("hi")])])` is a call.

A constructor stores attribute values **verbatim**. Escaping happens once, at render, with std's
`escape.attribute` inside front 30's walker; escaping here too would double-escape.

### Three names that could not be the obvious one

| Tag | Constructor | Why |
|---|---|---|
| `<html>` | `htmlTag` | `html` is the `html """…"""` template DSL (`jhonstart-html`), which a consumer imports beside the tags. |
| `<time>` | `timeTag` | Parity with `htmlTag`; front 53's example already writes `timeTag`. |
| `<main>` | `main` | Shipped under its own name. Caveat (in `docs.md`): a module that declares the program entry point `fn main()` must not also import `main` from `"jhonstart"`. The remedy is `el("main", kids, attrs: [])`; an import alias is parsed and ignored for a package import (see *Language gaps*). |

`link/2` and `el/3` differ in arity from the Erlang auto-imported BIFs `link/1` and `element/2`, and the
erlang backend emits `-compile({no_auto_import,[…]})` for any name/arity that would shadow one; the
erlang test row covers it.

### The `html """…"""` import a consumer writes

The DSL resolves a lowercase tag to a bare call in the **caller's** scope, so every tag used in markup
is imported by name:

```bp
import {html} from "jhonstart-html";
import {nav, span, text, renderToString} from "jhonstart";

val bar = html """<nav><span>home</span></nav>""";
```

A tag that is not imported is an unbound-name diagnostic at the call site, naming the tag.

### What the consuming fronts do

| Front | Uses |
|---|---|
| **24** rakun-server-actions | Builds no markup (decision 113); the action form is front 67's `formAttrs` / `hiddenActionField`, built from this surface. |
| **26** · **27** · **28** · **29** · **30** | `import {…} from "jhonstart"` for `nav`, `section`, `header`, `h2`, `button`, …; none defines a constructor. |
| **31** error-boundaries | `global-error.bp` builds its document with `htmlTag`, `head`, `body`, `title`, `meta`, `link` — the shape in `examples/document-shell-example.bp`. |
| **32** metadata | Nothing: `renderHead(m) -> string` writes its `title` / `meta` / `link` tags as strings over std `escape` (`metadata.bp` is pure; see `../unification.md` § 2). |
| **53** onze example app | Its builders resolve from `"jhonstart"`. |
| **67** forms | `form`, `input`, `button`, `label`, `select`, `textarea`. |

## Delivered

- [x] `el`, `voidEl`, `isVoidTag`, `isRawTextTag`, with inline tests: `el` builds an unnamed tag;
      `voidEl` stores no children; `isVoidTag` answers the fourteen and false for `"div"`, `"span"`,
      `"form"`, `""`; `isRawTextTag` is `script`/`style`, not `title`/`textarea`
- [x] Front 30's `render.bp` `renderNode` calls `isVoidTag` / `isRawTextTag` and restates no list
- [x] The 32 non-void constructors, each declared `(children: Children, attrs: Array<#(string, string)> = []) -> Element`;
      tests: nested render (`<section><h2>Posts</h2></section>`), a renamed constructor renders the HTML
      tag (`htmlTag(…).tag == "html"`, `timeTag(…).tag == "time"`), attribute order is array order
      (`contracts.md § 4` clause 5), an attribute value is stored verbatim (`/a&b`, not `/a&amp;b`)
- [x] The 6 void constructors: `input([], attrs: [#("name", "title")])` type-checks with a bare `[]`;
      children handed to a void element are dropped; every void tag is in `isVoidTag`;
      `renderToString(input([], attrs: []))` is `"<input></input>"`, asserted as the frozen renderer's answer
- [x] `modules/jhonstart-html/test/elements_test.bp`: a single-root template over an `elements.bp` tag
      renders like the constructor call; a template mixing `element.bp` and `elements.bp` tags resolves
      both; `html """<nav [class]={c}><span>x</span></nav>"""` renders `class="card"`
- [x] `pub mod elements;` in `root.bp` and `"elements.bp"` in `botopink.json`'s `files`; `docs.md`
      § *The element surface* (the tags, the three renamed ones, the `main` caveat); `AGENTS.md` tree
- [x] The `language-gaps.md` row "New jhonstart element constructors" left *Unowned surface*
- [x] Green on both rows

## Open

- [ ] Fronts 26, 27, 28, 29, 30, 31, 32, 53 and 67 import from `"jhonstart"` and define no
      element constructor locally; front 31's *Blocked* entry for `global-error.bp` is removed

**`renderToString` emits a closing tag for a void element.** `element.bp` is frozen, so
`renderToString(input([], attrs: []))` answers `<input></input>` and a `meta` answers
`<meta charset="utf-8"></meta>` — not valid HTML, and not what front 24's form test asserts
(`markup.contains("</input>") == false`). The render that ships is front 30's `renderNode`, which is
void-aware; `renderToString` stays the in-repo test renderer, and every assertion that goes through it
spells the `</input>` out so the day `element.bp` is unfrozen the failing tests point at the lines to
change (one `if (isVoidTag(e.tag)) return "<" + e.tag + attrStr + ">";` before the closing tag).
Unfreezing it is not this milestone's.

**A void element cannot be authored inside `html """…"""`.** The DSL lowers a self-closing tag to a
one-argument call with no `attrs:` and flushes it after the token loop rather than at its position, so
`<img/>` is an arity error and `<div><img/></div>` would place the `img` beside the `div`. A multi-root
template likewise emits `fragment([...])` with no `attrs:`. Neither shape has a test — this is read off
the arity rule and the two lowering sites. `html.bp` is frozen; build void elements with the
constructor and interpolate the result. `<html>` in markup is doubly unavailable: the tag would resolve
to the DSL's own `html`.

## Examples

| File | Demonstrates |
|---|---|
| [`examples/form-example.bp`](./examples/form-example.bp) | A form bound to a server action through `form`, `label`, `input`, `select`, `option` and `button`, matching the binding in `contracts.md § 3` — `data-jh-a` on the form, a hidden field named by the `actionField` onze passes (`__bp_action`, decision 114). Every call spells `attrs:`. |
| [`examples/document-shell-example.bp`](./examples/document-shell-example.bp) | The `htmlTag`/`head`/`body` shell front 31's `global-error.bp` uses, with `title`, `meta` and `link`, and the doctype prefix that is a string because it is not an element. |
| [`examples/carried-emilia-attribute-html-dsl-example.bp`](./examples/carried-emilia-attribute-html-dsl-example.bp) · [`examples/carried-responsive-modifiers-example.bp`](./examples/carried-responsive-modifiers-example.bp) | An emilia class in markup through the `[class]={c}` hole, bound first with `cls(tokens, th)` (front 48). |

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No assignment to a `self` field** (`language-gaps.md`, row "No assignment to a `self` field") | `elements.bp` builds each `Element` in one `Element(…)` call | Construct complete, or return a new value | A mutable field form, or a documented statement that records are immutable by design |
| **A package import alias is parsed and then ignored** — `import {main as mainTag} from "jhonstart";` parses but nothing outside the parser reads the alias for a package import, so the binding lands under `main` | the `main` constructor beside a program entry point `fn main()` | `el("main", children, attrs: [])`, or keep the two in different modules | Honour the alias in the resolver and in codegen |

## Test plan

Inline `test` blocks at the foot of `elements.bp` (the constructors, attribute order, the verbatim rule,
the void drop, both predicates), and the flat suite `modules/jhonstart-html/test/elements_test.bp` for
DSL resolution — written from a consumer's position, because the DSL resolves tags in the caller's
scope. Both run on **both targets** (`zig build test-libs -- --lib jhonstart`): a constructor that
produced a different `Element` on the two targets would break hydration silently, and string-literal
assertions turn that into a red cell. Not covered: escaping (fronts 01 and 30), the void closing tag
beyond pinning today's answer, self-closing tags in markup.
