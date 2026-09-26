# Front 94 — Jhonstart Element Surface

**Track:** C jhonstart
**Priority:** critical — front 31's `global-error.bp` cannot be written without it, and nine other fronts each carry a private copy of `form`/`input`/`button` that will drift the first time an attribute convention changes
**Target:** both — the surface is rendered on the server by front 30 and hydrated in the browser by front 68, so every constructor must produce the identical `Element` on both targets
**Wave:** 0
**Depends on:** none — only the already-public `Element` record (`element.bp:3-8`)
**Owns:** `repository/jhonstart/src/elements.bp` (plus its inline `test` blocks), `repository/jhonstart/test/elements_test.bp`, `repository/jhonstart/src/root.bp`, `repository/jhonstart/botopink.json`
**Does not touch:** `src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen), `src/router.bp` (26), `src/link.bp` (27), `src/server.bp` (28), `src/client.bp` (29), `src/suspense.bp`/`src/streaming.bp` (30), `src/error_boundary.bp` (31), `src/metadata.bp` (32), `src/form.bp` (67)
**Reference:** `NEXTJS-DOCS.md § 4. App Router — Fundamentos` · Root Layout (obrigatório) · `NEXTJS-DOCS.md § 10. Mutação de Dados` · <https://html.spec.whatwg.org/multipage/indices.html#elements-3> · <https://html.spec.whatwg.org/multipage/syntax.html#void-elements> · <https://nextjs.org/docs/app/api-reference/file-conventions/layout>

---

## Problem

`repository/jhonstart/src/element.bp` declares eight element constructors — `text`, `fragment`,
`div`, `span`, `p`, `h1`, `ul`, `li` (`element.bp:10-53`) — and `fronts.md` freezes that file for the
whole milestone. Ten fronts need more than eight tags. Front 24 needs `form`, `input` and `button`;
front 67 needs those plus `label`, `select` and `textarea`; fronts 26, 27, 29, 30 and 53 need `nav`,
`section`, `article`, `header`, `main` and `h2`; front 31's `global-error.bp` needs `html`, `body`
and `head`, and is recorded as *Blocked* in its own README for exactly that reason.

The `html """…"""` DSL does not solve this. It resolves a lowercase tag to a bare `tag(...)` call in
the **caller's** scope (`html.bp:20-23`, and the lowering that writes the call at `html.bp:230`), so
`<nav>` compiles to `nav([...], attrs: [...])` and fails to resolve unless the consumer has already
imported a `nav`. The DSL consumes an element surface; it does not provide one.

Without an owner, each of those fronts builds the constructors it needs through the public `Element`
record in its own file. That works — `Element` is `pub` and the `attrs` slot exists — and it is what
front 24's README currently describes (`24-rakun-server-actions/README.md:121-128`). It also means
ten copies of `form`, at least five of `button`, and a void-element decision taken independently in
each of them. `language-gaps.md` already records this under *Unowned surface*: "A jhonstart front
should own the element surface."

## Current state

- `repository/jhonstart/src/element.bp:3-8` — `pub type Element(tag, value, children, attrs)
  implement @Context<ElementBase>` (decision 102: `@Context<Base>` is the context-owner marker, and
  `ElementBase` is the base every hook in this track anchors on). Public, and everything this front
  needs.
- `repository/jhonstart/src/element.bp:10-53` — the eight constructors plus `bracketPair`. Every one
  has the same shape: `pub fn <tag>(children: Children, attrs: Array<#(string, string)> = []) ->
  Element`, returning `Element(tag: "<tag>", value: "", children: children, attrs: attrs)`.
- `repository/jhonstart/src/element.bp:55-67` — `renderToString`. `#text` renders `value`,
  `#fragment` renders children only, everything else renders
  `<tag attr="v">children</tag>` — **unconditionally, including the closing tag**, and with
  attribute values interpolated verbatim (`element.bp:64`). No escaping, no void set.
- `repository/jhonstart/src/html.bp:230` — the DSL writes `cname + "([" + kids + "], attrs: [" +
  attrsContent + "])"`. Children positional, `attrs:` labeled: the same shape as the eight.
- `repository/jhonstart/src/root.bp:15-17` — three `pub mod` lines. `botopink.json` `files` lists
  `element.bp`, `hooks.bp`, `html.bp`, `router.d.bp`, `server.d.bp`.
- `repository/jhonstart/test/` exists and holds one file, `test/html_test.bp` — a flat suite that
  bare-imports across `src` modules. jhonstart therefore uses **both** conventions: inline `test`
  blocks in `src/element.bp:69-97` and `src/hooks.bp`, and a flat `test/` suite for the DSL. This
  front follows both, for the reason given under *Test plan*.
- `repository/jhonstart/AGENTS.md` still says "the `Element` model has no **attribute** slot, so
  `Link`/form controls can't render `href`/`onClick` in pure `.bp` yet". That sentence is stale —
  `attrs` landed — and this front's closeout corrects it.

## Mechanism

There is no upstream mechanism to map here: HTML's element set is a list, and the work is to write
it once in the shape the rest of the milestone already assumes. What matters is that every decision
below is the *same* decision the eight existing constructors took, so that a reader cannot tell from
a call site whether a tag came from `element.bp` or from `elements.bp`.

### One signature, copied rather than improved

```bp
pub fn nav(children: Children, attrs: Array<#(string, string)> = []) -> Element
```

Children positional, `attrs:` labeled, `Array<#(string, string)>`, and a declared default that is
never applied — so **every call spells `attrs:`**, inner ones included
(`language-gaps.md`, "Declared parameter defaults are never applied"). The default stays in the
declaration because the eight have it and a reader comparing the two files should find them
identical, not because anything relies on it.

The shape is not a free choice. `html.bp:230` writes exactly `tag([kids], attrs: [pairs])`, so a
constructor with any other arity is unreachable from the DSL. Fronts 53 and 67 already write
`input([], attrs: [#("name", "title")])` in their examples. A second convention here would break
both, and there is no version of "better" that is worth that.

Every constructor funnels through one builder, so there is one place where an `Element` is
constructed:

```bp
pub fn el(tag: string, children: Children, attrs: Array<#(string, string)>) -> Element {
    return Element(tag: tag, value: "", children: children, attrs: attrs);
}

pub fn nav(children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return el("nav", children, attrs);
}
```

`el` is also the public escape hatch for a tag the surface does not name — `el("figure", kids,
attrs: [])`, `el("wbr", [], attrs: [])` — which is what keeps the named list from having to be the
whole HTML index.

### Void elements

A void element is one that cannot have children at all (`<input>`, `<img>`, `<meta>`, `<link>`,
`<br>`, `<hr>` and eight rarer ones —
<https://html.spec.whatwg.org/multipage/syntax.html#void-elements>). With the existing `Element`
record that is expressed in the **constructor body**, not in the signature: the void constructors
keep the uniform two-parameter shape and store `children: []` regardless of what they were handed.

```bp
pub fn voidEl(tag: string, attrs: Array<#(string, string)>) -> Element {
    return Element(tag: tag, value: "", children: [], attrs: attrs);
}

pub fn input(_children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return voidEl("input", attrs);
}
```

The one-parameter alternative — `pub fn input(attrs: …)`, which would make children an arity error
and is the more restrictive form — was rejected: it is a second convention, it breaks the DSL's
call shape, and it breaks the `input([], attrs: […])` that fronts 53 and 67 already write. The
children argument is dropped, and a test asserts that it is dropped rather than leaving it to be
discovered.

`children: []` in the record constructor is what `text` already does (`element.bp:15`), and an empty
array literal in a `Children` **positional** needs no annotation either: an array literal with no
elements types as `array<fresh>` (`infer.zig:9182-9193`), and `childrenCoercion` fires on any
`.named` type spelled `array` (`infer.zig:4236-4242`). So `div([], attrs: [])` — which `html.bp`
generates for `<div></div>` — type-checks. The ground truth's array-literal gotcha (§2.34) is about a
dot-shorthand path followed by a payload call inside a literal, which is a different shape and does
not arise here.

**What `renderToString` does with a void element is not fixable from this front.** `element.bp:55-67`
is frozen and writes `"</" + e.tag + ">"` for every non-text, non-fragment tag, so
`renderToString(input([], attrs: []))` answers `<input></input>`. See *Blocked*.

What this front can do is name the set, once, so that the renderer that **is** void-aware does not
re-list it:

```bp
pub fn isVoidTag(tag: string) -> bool
pub fn isRawTextTag(tag: string) -> bool
```

`isVoidTag` answers true for the fourteen HTML void elements — `area, base, br, col, embed, hr, img,
input, link, meta, param, source, track, wbr` — which is the same list front 30's README already
names (`30-jhonstart-streaming/README.md` § *The escaping walker*). Front 30's `renderNode` consults this function instead
of holding its own copy; two lists that must agree and are written twice will eventually not agree.

`isRawTextTag` answers true for `script` and `style`, the two elements whose text content is raw text
and must **not** be HTML-escaped. Front 30's walker escapes every `#text` with `escape.html`
(`30-jhonstart-streaming/README.md` § *The escaping walker*), which would turn a `>` inside a CSS rule into `&gt;` and a
`<` inside a script into `&lt;`. `title` and `textarea` are *escapable* raw text, where
`escape.html` is the correct treatment, so they are deliberately not in this set.

### Escaping is not this front's job

A constructor stores the attribute value it was given, byte for byte. Escaping happens once, at
render, and it is `escape.attribute` from front 01, called by front 30's walker
(`30-jhonstart-streaming/README.md` § *The escaping walker*, `01-std-lib-enablement/README.md:249`). Escaping in the
constructor as well would double-escape every attribute the moment both layers are present, and a
constructor cannot know whether its output is bound for HTML, for the payload envelope, or for a
test. A test in `elements.bp` asserts the verbatim behaviour so that nobody adds escaping here later
by mistake.

### Three names that could not be the obvious one

| Tag | Constructor | Why |
|---|---|---|
| `<html>` | `htmlTag` | `html` is already a `pub fn` in the same package — the `html """…"""` template fn (`html.bp:94`). Two `pub fn html` reachable from `import {…} from "jhonstart"` is a collision, and the DSL is the one with ten years of muscle memory behind the name. |
| `<time>` | `timeTag` | Parity with `htmlTag`, and front 53 already writes `timeTag` (`53-onze-example-app/examples/blog-slug-page-example.bp:19`). Std's clock is `io.clock` (decision 106), so `import {io.clock} from "std"` brings `clock`, not `time`, and the bare word is free — the constructor keeps its landed name anyway. |
| `<main>` | `main` | Shipped under its own name, because fronts 53 and 30 import it that way. The caveat is real and belongs in `docs.md`: a module that declares the program entry point `fn main()` must not also import `main` from `"jhonstart"` in that same module. `el("main", kids, attrs: [])` is the remedy; import aliasing is not — `import {main as m}` parses (`parser/decls.zig:242-258`) but nothing outside the parser reads the alias for a package import, so the binding still lands under `main`. |

`link` and `element` are Erlang auto-imported BIFs, at arity 1 and 2 respectively. `link/2` and
`el/3` differ in arity from both, and in any case the erlang backend emits
`-compile({no_auto_import,[…]})` for any user function whose **name and arity** shadow a BIF
(`modules/compiler-core/src/codegen/erlang.zig:1260-1267`). The erlang test row is what proves it.

### The `html """…"""` import a consumer writes

The DSL resolves `<nav>` in the caller's scope, so the tag must be imported there by name. There is
no wildcard import and no implicit prelude:

```bp
import {html} from "jhonstart";              // the DSL — src/html.bp
import {nav, span, text, renderToString} from "jhonstart";   // the tags used in the markup

val bar = html """<nav><span>home</span></nav>""";
```

A tag that is not imported is an unbound-name diagnostic at the call site, which is the behaviour
`html.bp:23-24` describes and is the one case where the surface being a plain set of functions is an
advantage: the error names the tag.

### What the consuming fronts do when this lands

Each of these keeps the helpers that encode *its* contract and deletes the element constructors
underneath them. Front 26 sits in wave 1 alongside this front rather than above it, and that is
correct: it cites front 94 for the builders its **examples** use, not for anything in `router.bp`.
No front reads this one's source, which is why this front depends on nothing and nothing has to wait
a level for it.

| Front | Today | After |
|---|---|---|
| **24** rakun-server-actions | Builds `form`, `input` and `button` through the public `Element` record in `src/actions.bp` (`24/README.md:121-128`) | rakun builds no markup and imports nothing from jhonstart (decision 113): the action form is front 67's `formAttrs` / `hiddenActionField`, built from this surface and fed the action id by onze; rakun keeps the id and the envelope (contract 3). The local constructors go with the form. |
| **26** router · **27** link · **28** server-components · **29** client-directive · **30** streaming | Examples cite "the element-surface front of track C" for `nav`, `section`, `header`, `h2`, `button` | `import {…} from "jhonstart"` with `// provided by front 94`. None of them defines a constructor. |
| **31** error-boundaries | `global-error.bp` listed under *Blocked* for want of `html` and `body` | Unblocked. `global-error.bp` builds its document with `htmlTag`, `head`, `body`, `title`, `meta`, `link` — the shape in `examples/document-shell-example.bp`. |
| **32** metadata | `renderHead` produces head content | `renderHead` emits `meta`/`link`/`title` elements from this surface rather than a string. |
| **53** onze example app | Eleven builders imported from `"jhonstart"` against a front with no number | The same imports, now resolvable. The README's "The element surface has no front number" note is answered. |
| **67** forms | Already states that front 94 owns `form`, `input`, `button`, `label`, `select`, `textarea` (`67/README.md:39-42`) | No change needed — 67 was written against this front. |

### The two shared files

Front 94 owns `repository/jhonstart/src/root.bp` and `repository/jhonstart/botopink.json`, and every
other track-C front hands it a line rather than editing either file — the rule `fronts.md` states for
emilia's `root.bp`, applied here. **Append in front-number order, never reorder, never edit another
front's line.** The merged result:

```bp
// src/root.bp
pub mod element;
pub mod hooks;
pub mod html;
pub mod router;          // front 26, replacing router.d.bp
pub mod link;            // front 27
pub mod server;          // front 28, replacing server.d.bp
pub mod client;          // front 29
pub mod suspense;        // front 30
pub mod streaming;       // front 30
pub mod error_boundary;  // front 31
pub mod metadata;        // front 32
pub mod form;            // front 67
pub mod elements;        // front 94
```

`botopink.json`'s `files` list takes the same entries, with `router.d.bp` and `server.d.bp` removed
by fronts 26 and 28. `elements.bp` is appended last, which is also the resolution order the compiler
wants: it imports `element` and `html`, both of which precede it.

## Steps

### Step 1 — `el`, `voidEl`, and the void/raw-text predicates

The three functions every other line in the file goes through, and the two the renderer consumes.

```bp
import {Element} from "element";

pub fn el(tag: string, children: Children, attrs: Array<#(string, string)>) -> Element {
    return Element(tag: tag, value: "", children: children, attrs: attrs);
}

pub fn voidEl(tag: string, attrs: Array<#(string, string)>) -> Element {
    return Element(tag: tag, value: "", children: [], attrs: attrs);
}

pub fn isVoidTag(tag: string) -> bool {
    val voids = [
        "area", "base", "br", "col", "embed", "hr", "img",
        "input", "link", "meta", "param", "source", "track", "wbr",
    ];
    return voids.contains(tag);
}

pub fn isRawTextTag(tag: string) -> bool {
    val raws = ["script", "style"];
    return raws.contains(tag);
}
```

**Acceptance:**
- [x] `renderToString(el("figure", [text("x", attrs: [])], attrs: [])) == "<figure>x</figure>"` — `modules/jhonstart/src/elements.bp` test "el builds a tag the named surface does not carry"
- [x] `voidEl("wbr", []).children` renders as the empty string — `renderToString` of it is
      `"<wbr></wbr>"`, with nothing between the tags — `modules/jhonstart/src/elements.bp` test "voidEl stores no children"
- [x] `isVoidTag` answers true for all fourteen and false for `"div"`, `"span"`, `"form"` and `""` — `modules/jhonstart/src/elements.bp` test "isVoidTag answers the HTML spec's list and nothing else"
- [x] `isRawTextTag("script")` and `isRawTextTag("style")` are true; `isRawTextTag("title")` and
      `isRawTextTag("textarea")` are false — escapable raw text is not raw text — `modules/jhonstart/src/elements.bp` test "isRawTextTag is script and style"
- [ ] The fourteen tags of `isVoidTag` are the same fourteen front 30's walker treats as void, and
      front 30's `render.bp` calls the predicate rather than restating the list

### Step 2 — the non-void constructors

Thirty-two of them, one line of body each, in the order a reader looks for them: sectioning,
headings, text-level, forms, tables, document.

```bp
pub fn a(children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return el("a", children, attrs);
}
pub fn nav(children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return el("nav", children, attrs);
}
// … section, article, header, footer, main, aside
// … h2, h3, h4, h5, h6, label, timeTag
// … form, button, select, option, textarea
// … table, thead, tbody, tr, th, td
// … htmlTag, head, body, title, script, style
```

**Acceptance:**
- [x] Every constructor's declaration is byte-identical to `element.bp`'s apart from the name and the
      tag string — same parameter names, same order, same types, same declared default — `modules/jhonstart/src/elements.bp`, every constructor is `(children: Children, attrs: Array<#(string, string)> = []) -> Element`
- [x] `renderToString(section([h2([text("Posts", attrs: [])], attrs: [])], attrs: []))` is
      `"<section><h2>Posts</h2></section>"` — `modules/jhonstart/src/elements.bp` test "a constructor renders its tag, nested"
- [x] A constructor whose name differs from its tag renders the tag: `htmlTag(…).tag == "html"`,
      `timeTag(…).tag == "time"` — `modules/jhonstart/src/elements.bp` test "a renamed constructor still renders the HTML tag"
- [x] Attribute order is preserved: `renderToString(a([text("x", attrs: [])], attrs: [#("href",
      "/p"), #("rel", "next")]))` is `"<a href=\"/p\" rel=\"next\">x</a>"` — array order is the
      rendered order, which is what `contracts.md § 4` clause 5 depends on — `modules/jhonstart/src/elements.bp` test "attribute order is the array order"
- [x] An attribute value is stored verbatim: an `href` of `/a&b` renders `/a&b`, not `/a&amp;b`.
      Escaping belongs to front 30 — `modules/jhonstart/src/elements.bp` test "an attribute value is stored verbatim"

### Step 3 — the void constructors

`input`, `img`, `meta`, `link`, `br`, `hr`. Same signature, children discarded.

```bp
pub fn input(_children: Children, attrs: Array<#(string, string)> = []) -> Element {
    return voidEl("input", attrs);
}
```

**Acceptance:**
- [x] `input([], attrs: [#("name", "title")])` type-checks with a bare `[]` and no annotation — `modules/jhonstart/src/elements.bp` test "a void constructor type-checks with a bare empty children list"
- [x] `input([text("x", attrs: [])], attrs: []).children` is empty — a void element handed children
      drops them, and the rendered markup contains no `x` — `modules/jhonstart/src/elements.bp` test "a void element handed children drops them"
- [x] `isVoidTag` is true for the tag of each of the six — `modules/jhonstart/src/elements.bp` test "every void constructor's tag is in the void set"
- [x] `renderToString(input([], attrs: []))` is `"<input></input>"` — the frozen renderer's answer,
      asserted so the *Blocked* item below is a failing literal and not a paragraph — `modules/jhonstart/src/elements.bp` tests "a void constructor type-checks…" and "renderToString closes a void element"

### Step 4 — the `html """…"""` resolution test

The DSL resolves tags in the caller's scope, so the only honest test is one written from a
consumer's position: `test/elements_test.bp`, the flat suite, next to `test/html_test.bp`.

```bp
import { html, nav, section, h2, span, text, renderToString };

test "a tag from the element surface resolves inside an html template" {
    val bar = html """<nav><span>home</span></nav>""";
    assert renderToString(bar) == "<nav><span>home</span></nav>";
}
```

**Acceptance:**
- [x] A single-root template over a tag from `elements.bp` renders identically to the equivalent
      constructor call — `modules/jhonstart-html/test/elements_test.bp` test 1
- [x] A nested template mixing an `element.bp` tag with an `elements.bp` tag
      (`<section><p>hi</p></section>`) resolves both — `modules/jhonstart-html/test/elements_test.bp` test 2
- [x] A bracket-prop attribute reaches `attrs` on an `elements.bp` tag:
      `html """<nav [class]={c}><span>x</span></nav>"""` renders `class="card"` — `modules/jhonstart-html/test/elements_test.bp` test 3
- [x] The README states the import a consumer writes, and the test file is that import — `elements_test.bp`'s two import lines; `docs.md` § *The element surface*

### Step 5 — `root.bp`, `botopink.json`, `docs.md`, `AGENTS.md`

**Acceptance:**
- [x] `pub mod elements;` appended to `src/root.bp` after every other front's line — jhonstart `08950fd` — last `pub mod`
- [x] `"elements.bp"` appended to `botopink.json`'s `files` — `modules/jhonstart/botopink.json` `files`
- [x] `docs.md` gains the constructor table, the three renamed tags with their reasons, and the
      `main` caveat — `docs.md` § *The element surface* (*The tags*, *Three names that could not be the obvious one*)
- [x] `AGENTS.md`'s "the `Element` model has no **attribute** slot" line is corrected, and
      `elements.bp` appears in the tree diagram — `AGENTS.md` § *Compiler prerequisites* ("(closed) the `Element` model **does** carry an `attrs` slot") and the tree diagram
- [x] `zig build test-libs --lib jhonstart` green on `commonJS` and on `erlang` — core 120/120 on commonJS and erlang (`botopink test` per member, compiler `248d0896`)

## Examples

| File | Demonstrates |
|---|---|
| [`examples/form-example.bp`](./examples/form-example.bp) | A form bound to a server action through `form`, `label`, `input`, `select`, `option` and `button`, matching front 24's binding from `contracts.md § 3` — `data-jh-a` on the form, a hidden field named by the `actionField` onze passes (`__bp_action`, decision 114). Every call spells `attrs:`. |
| [`examples/document-shell-example.bp`](./examples/document-shell-example.bp) | The `htmlTag`/`head`/`body` shell front 31's `global-error.bp` needs, with `title`, `meta` and `link`, and the doctype prefix that is a string because it is not an element. |

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **Declared parameter defaults are never applied** (`language-gaps.md`, row "Declared parameter defaults are never applied") | every constructor in both examples, and every constructor declaration in `elements.bp` | Pass every argument explicitly — `attrs:` on every call, inner ones included | Apply declared defaults at the call site. This is the single gap that shapes the whole file: with defaults applied, `div([p("hi")])` would be the surface and the examples would be a third shorter |
| **No assignment to a `self` field** (`language-gaps.md`, row "No assignment to a `self` field") | `elements.bp` builds each `Element` in one `Element(…)` call rather than constructing and then filling `attrs` | Construct complete, or return a new value | A mutable field form, or a documented statement that records are immutable by design |
| **A package import alias is parsed and then ignored** — `import {main as mainTag} from "jhonstart";` parses (`modules/compiler-core/src/parser/decls.zig:242-258`) but nothing outside the parser reads `.alias` for a package import, so the binding still lands under `main` | the `main` constructor, whose name collides with the program entry point in a module that declares both | Use `el("main", children, attrs: [])`, or keep the two in different modules | Honour the alias in the resolver and in codegen, so a collision has a fix that does not change the call |

## Blocked

**`renderToString` emits a closing tag for a void element.** `element.bp:55-67` is frozen, so
`renderToString(input([], attrs: []))` answers `<input></input>` and
`renderToString(meta([], attrs: [#("charset", "utf-8")]))` answers
`<meta charset="utf-8"></meta>`. Browsers ignore the stray end tag, but the output is not valid HTML
and it is not what front 24's test asserts (`assert markup.contains("</input>") == false` —
`24-rakun-server-actions/examples/form-action-example.bp`).

The nearest valid form today, and the one this front delivers: the void set is exported as
`isVoidTag`, and the render that ships is front 30's `renderNode`, which is void-aware
(`30-jhonstart-streaming/README.md` § *The escaping walker*). `renderToString` stays the in-repo test renderer, and
every assertion in this front that goes through it spells the `</input>` out, so that the day
`element.bp` is unfrozen the failing tests point straight at the four lines to change. Unfreezing
`renderToString` — one `if (isVoidTag(e.tag)) return "<" + e.tag + attrStr + ">";` before
`element.bp:66` — belongs to 1.0.10-beta, not to this milestone.

**A void element cannot be authored inside `html """…"""`.** The DSL lowers a self-closing tag to
`pendingSc + "([])"` (`html.bp:250`) — one positional argument, no `attrs:` — and flushes it *after*
the token loop rather than at its position, from a single `pendingSc` variable that holds one tag.
Since declared defaults are never applied, a one-argument call on a two-parameter constructor is an
arity error, and even if it were not, `<div><img/></div>` would place the `img` beside the `div`
rather than inside it. The same line of reasoning applies to a multi-root template, which emits
`fragment([...])` with no `attrs:` (`html.bp:266`). Neither shape has a test today — `html_test.bp`
covers two single-root templates with no self-closing tag — so this is read off the arity rule and
the two lowering sites, not observed. `html.bp` is frozen; the valid form is to build void elements
with the constructor directly and interpolate the result, and `<html>` in markup is doubly
unavailable because the tag would resolve to the DSL's own `html` template fn.

## Test plan

Two files, because jhonstart has two conventions and each test belongs to a different one.

**`src/elements.bp`, inline `test` blocks at the foot** — the same place `element.bp:69-97` and
`hooks.bp` keep theirs. These are unit tests of the constructors: tag, attrs, attribute order, the
verbatim-attribute rule, the void-children drop, and both predicates. They compile as part of the
module, so a constructor that does not type-check fails its own file.

**`test/elements_test.bp`, the flat suite** — the `html """…"""` resolution tests, next to
`test/html_test.bp` for the same reason that file exists: the flat suite bare-imports across `src`
modules (`test/html_test.bp:1`), which is exactly the consumer's scope the DSL resolves tags in. A
resolution test written inside `elements.bp` would prove only that a module can see its own
functions.

Both run on **both targets** — `botopink test --target commonJS` and `botopink test --target erlang`
from `repository/jhonstart/`, and through `zig build test-libs -- --lib jhonstart` in the ecosystem
gate. Both targets are required, not preferred: the surface is rendered on the server (front 30,
erlang) and rebuilt in the browser (front 68, commonJS), and a constructor that produced a different
`Element` on the two targets would break hydration silently. The tests assert string literals, so a
divergence is a red cell and not a hydration mismatch discovered by a reader.

What the tests do **not** cover: escaping (front 01 and front 30 own it and test it), the void
closing tag beyond asserting today's wrong answer, and self-closing tags in markup. Those three
absences are stated above rather than papered over.

## Definition of done

- [x] `repository/jhonstart/src/elements.bp` exists with thirty-eight constructors, `el`, `voidEl`,
      `isVoidTag` and `isRawTextTag`, and touches no frozen file — 32 non-void + 6 void, `el`, `voidEl`, both predicates
- [x] Every constructor's signature is identical in shape to the eight in `element.bp`
- [x] The six void constructors store no children, and a test asserts the drop — `modules/jhonstart/src/elements.bp` test "a void element handed children drops them"
- [x] `test/elements_test.bp` proves a tag from this file resolves inside an `html """…"""` template,
      and the README states the import that makes it resolve — `modules/jhonstart-html/test/elements_test.bp`
- [x] `pub mod elements;` and the `botopink.json` entry are appended in front-number order, and the
      lines fronts 26–32 and 67 hand this front are appended alongside them — jhonstart `08950fd`: 26, 27, 28, 29, 31, 94
- [ ] Fronts 26, 27, 28, 29, 30, 31, 32, 53 and 67 import from `"jhonstart"` and define no
      element constructor locally; front 31's *Blocked* entry for `global-error.bp` is removed
- [x] The `language-gaps.md` row "New jhonstart element constructors" moves out of *Unowned surface*
      and names this front — the row is no longer in `language-gaps.md` § *Unowned surface*
- [ ] Front 30's `renderNode` calls `isVoidTag` and `isRawTextTag` rather than holding its own lists
- [x] The front's tests are green on both of its assigned targets — 120/120 on both rows
