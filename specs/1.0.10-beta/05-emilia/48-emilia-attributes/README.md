# Front 48 — emilia attributes: the class slot

**Track:** D emilia
**Priority:** high — every token the other fifteen emilia fronts deliver is unreachable from a jhonstart element until this front exists, and the class name it produces is read by both halves of the app
**Target:** comptime — the class name is computed at comptime and emitted as a string. The attribute carrying it is consumed by **both** halves: the server render (erlang, jhonstart front 30) writes it into the HTML, and the client (js) recomputes it during hydration. A class-name scheme that differs between the two halves breaks hydration, and preventing that is what this front is for.
**Wave:** 4
**Depends on:** 26 (jhonstart router — the wave-2 gate) · 33–47 for the tokens carried through the slot, though the slot itself is token-agnostic and carries any `Token[]`
**Owns:** `repository/emilia/src/attributes.bp` · `repository/emilia/src/html_hook.bp` · `repository/jhonstart/src/html_attrs.bp` (emilia-unaware) · `repository/emilia/test/attributes_test.bp` (the slot, and contract 4's emilia-side literal; renders no HTML)
**Does not touch:** `repository/emilia/src/tokens.bp` and `repository/emilia/src/emilia.bp` — no token section, no dispatcher, which is what makes this front safe to run alongside all fifteen others; `repository/jhonstart/src/element.bp`, `src/hooks.bp`, `src/html.bp` — frozen for the milestone
**Reference:** `TAILWIND_CSS_DOCS.md § 3. Conceitos Fundamentais` (utility-first: the class attribute is the whole interface) · https://tailwindcss.com/docs/styling-with-utility-classes · `NEXTJS-DOCS.md` CSS / hydration

---

## Problem

`emilia(tokens)` returns a class name (`repository/emilia/src/emilia.bp:46-51`) and `Element` carries
`attrs: Array<#(string, string)>` (`repository/jhonstart/src/element.bp:3-8`). Nothing connects them.
A developer who wants a styled `div` writes the tuple by hand:

```bp
div([text("hi", attrs: [])], attrs: [#("class", emilia(cardTokens))])
```

That works, and it is wrong in the way that matters. The string `"class"` is spelled at every call
site, the merge with a static class is re-invented at every call site, and — because the server
renders on BEAM and the client hydrates in JavaScript — the two halves each spell it independently.
Two independent spellings of one contract is the definition of a hydration bug.

The `html """…"""` DSL has the same hole from the other side. It supports `[class]={expr}` attributes
that reach `attrs` (`repository/jhonstart/src/html.bp:234-241`, `repository/jhonstart/test/html_test.bp:8-12`)
and the expression can be anything in the caller's scope — but nothing in the caller's scope turns a
`Token[]` into a string with the right name, and `html.bp` is frozen for this milestone, so the DSL
cannot grow an `[emilia]={…}` attribute of its own.

**The failure this front exists to prevent, stated concretely.** The server renders
`<div class="e_1f3a9b">`. The client mounts the same component, recomputes the class, and gets
`e_7c0e42`. Depending on the hydrator that is a console warning, a silent double-application of two
rules, or a patched DOM that discards the server's markup — and in every case the page flashes. The
class name is the only thing the two halves have to agree on, and there are exactly five ways for
them to disagree: a different hash, a different token order, a different merge order, an extra class
from a counter or a salt, and a different attribute order in the tag. This front pins all five and
tests all five.

## Current state

- `emilia(tokens: Token[]) -> string` returns `"e_" + hashHex(rules)` where
  `rules = tokensToCss(tokens)` — `emilia.bp:46-51`. This is already a pure function of the token
  list.
- `hashHex` is a djb2 fold, seeded 5381, multiplier 33, masked to 32 bits, rendered lowercase hex,
  declared for both `node` and `Erlang` — `emilia.bp:38-42`. The file's own comment at `:32-37` says
  the two agree "for ASCII rule bodies (astral characters are one codepoint in erlang, two UTF-16
  units in JS)". That sentence is the hydration contract, and nothing enforces it today.
- `tokensToCss` is `tokens.map(tokenToCss).filter(!= "").join(";")` — `emilia.bp:103`. Order-
  preserving, so the token list's order is part of the class identity.
- `renderToString` writes attributes in array order — `element.bp:62-66`. Attribute order is part
  of the rendered string.
- `bracketPair(name, value) -> #(string, string)` exists — `element.bp:10-12` — and `html.bp:240`
  emits a call to it for every `[name]={expr}` attribute.
- Parameter defaults are declared and never applied
  (`repository/botopink-lang/tests/language/expected-failures.txt`), so every `attrs:` must be
  written explicitly at every constructor call, inner ones included — `element.bp:70-73`.
- `repository/emilia/src/attributes.bp`, `repository/emilia/src/html_hook.bp` and
  `repository/jhonstart/src/html_attrs.bp` **do not exist**.
- emilia imports nobody and carries no dependency, dev-dependency included, on jhonstart
  (decisions 113 and 114): every test and example of this front uses emilia only and asserts class
  names and CSS strings. The rendered-markup cells — a builder tree and a DSL tree rendering the
  same bytes, the attribute order in a rendered tag, the flushed selector matching a rendered
  attribute — are the `jhonstart-emilia` bridge's test
  ([jhonstart front 30](../../04-jhonstart/30-jhonstart-streaming/README.md), step 9), the one
  package that knows both.

## Mechanism

### The class-name scheme, stated as a contract

This front owns contract `§ 4`, and the wording below is that contract.

> **A jhonstart element's emilia class is `e_<hex>`, where `<hex>` is the lowercase hexadecimal
> djb2-33 fold (seed 5381, masked to 32 bits) of `encodeSheet(tokensToSheet(tokens, theme))`, and
> `tokens` is the element's token list in author order. Nothing else enters the hash. When a static
> class is also present, the `class` attribute value is `<static> + " " + <emilia class>` — static
> first, one ASCII space, no de-duplication, no sorting.**

Front 56 replaced the body being hashed — the first draft of this front hashed `tokensToCss(tokens)`
— so the **expected literal in the shared fixture is regenerated exactly once** when 56 lands, and
the `jhonstart-emilia` bridge test (jhonstart front 30) and front 68 take the new value. The djb2 parameters and clauses 2–5 are unchanged; only the
input to the fold moved.

Six consequences, each of which is a test:

1. **Pure function of the token list _and the theme_.** No counter, no module path, no request id,
   no build salt, no timestamp — but the `Theme` **is** an input, because a themed value changes the
   rendered body, and the same tokens under a different `Theme` are a different class. The server
   and the client compute it from the same two inputs and must get the same output. This front's
   contribution is to make that a stated contract with a test, so a later "optimization" that adds a
   per-render prefix fails visibly.
1b. **The theme is the sixth way the halves can disagree**, and the one the first draft of this
   front did not know about. A `Theme` assembled independently on each side — one composing
   `paletteEntries()` in a different order, one missing an `extend` — produces a different encoded
   sheet and therefore a different class, with no other symptom. The theme comes from one shared
   value on both halves, exactly as the token list does.
2. **Order is identity.** `[.Text.Bold, .Color.Black]` and `[.Color.Black, .Text.Bold]` are two
   different classes, because `tokensToCss` joins in list order. The two halves must build the same
   list in the same order — which they do when the token list comes from one shared function, and do
   not when each half assembles it inline.
3. **ASCII only.** The JS cell folds UTF-16 code units and the erlang cell folds codepoints; they
   agree for every character below U+10000 and diverge above it. The attribute slot therefore
   accepts only rule bodies that are ASCII, which every token in fronts 41–47 satisfies. The one way
   a non-ASCII body can arise is a **top-level payload variant** — `Token.FilterRaw`,
   `Token.AnimateRaw`, `Token.InteractAccent`, `Token.SvgFill` and their siblings — carrying a
   non-ASCII string. (Payload-carrying tokens are top-level variants and never section leaves, per
   contract `§ 4a`: a nested payload leaf cannot be constructed at all — `language-gaps.md` row 52.)
   `attributes.bp` is where that is checked.
4. **Merge order is fixed.** `"card e_1f3a9b"` and `"e_1f3a9b card"` are the same CSS and two
   different attribute strings, and a hydrator comparing strings sees two different values. The
   merge is one function in one file, so there is one order.
5. **Attribute order is fixed.** `renderToString` writes attrs in array order, so
   `[#("id","x"), #("class","c")]` and `[#("class","c"), #("id","x")]` render two different tags.
   The slot appends, never prepends, and the append order is the argument order.

The client's own `emilia()` call also `register`s into its sheet. That is harmless — the server has
already shipped the `<style>` block through `flush()` — and only the **returned class name** is part
of the contract. The client never flushes.

### Three files, and why the seam is where it is

**`repository/emilia/src/attributes.bp` — the slot.** Turns a `Token[]` into the attribute tuple
that `Element.attrs` accepts. It is the only place the string `"class"` is spelled on the emilia
side and the only place two class names are joined.

```bp
import {Token} from "tokens";
import {Theme} from "theme";        // front 54
import {emilia} from "emilia";

// `#("class", <the emilia class>)` — drops straight into any builder's `attrs:`.
pub fn styled(tokens: Token[], th: Theme) -> #(string, string) { … }

// Static class first, emilia class second, one ASCII space between them.
pub fn styledWith(base: string, tokens: Token[], th: Theme) -> #(string, string) { … }

// The class name alone, for the `[class]={…}` hole and for a hydrator that
// wants to compare without building an attribute.
pub fn className(tokens: Token[], th: Theme) -> string { … }

// The merge, spelled once. `mergeClass("", b)` is `b`; `mergeClass(a, "")` is
// `a`; otherwise `a + " " + b`. No de-duplication, no sorting, no trimming of
// interior spaces — the caller's static string is passed through unchanged.
// The one function here that takes no `Theme`: it joins two strings and knows
// nothing about tokens.
pub fn mergeClass(base: string, extra: string) -> string { … }
```

Every function but `mergeClass` carries the theme, because the theme is part of the class identity
(clause 1). An app with one theme passes the same value everywhere, which is the point: one value,
both halves.

`mergeClass` lives here and nowhere else. A second implementation on the jhonstart side would be the
fifth failure mode above, written into the design.

**`repository/emilia/src/html_hook.bp` — the DSL bridge.** `html.bp` is frozen, so the DSL cannot
grow an `[emilia]={…}` attribute. It does not need one: `[class]={expr}` already reaches `attrs`,
and the expression resolves in the **caller's** scope. This module supplies what the caller puts in
that hole — functions returning a bare `string`.

```bp
pub fn cls(tokens: Token[], th: Theme) -> string { … }   // className, under a short name
pub fn clsWith(base: string, tokens: Token[], th: Theme) -> string { … }
```

The theme argument makes `cls(tokens, th)` a call containing a space, and a `[class]={…}` hole may
not contain one. The DSL form is therefore always a **pre-bound `val`**, never the call written
inline — which the no-space rule already recommended and the theme argument now makes mandatory.

**The constraint that shapes this module.** `html.bp:109` splits a tag's body on `" "` before
parsing attributes, so **a `[class]={…}` hole may not contain a space**.
`[class]={styled([.Text.Bold, .Color.Blue.500])}` is lexed as four attributes and fails. The
supported forms are a pre-bound identifier and a no-space call:

```bp
val card = cls(cardTokens);
val page = html """<div [class]={card}><p>hi</p></div>""";
```

That is why `cls` is short and why the front ships component-level token functions rather than inline
arrays. It is a constraint of a frozen file, recorded under *Blocked*, not a language gap.

**`repository/jhonstart/src/html_attrs.bp` — the attribute plumbing, emilia-unaware.** jhonstart
must not know that emilia exists, and emilia imports nothing from jhonstart; this file is jhonstart
code that this front writes, not a dependency of emilia's.
This module never concatenates a class name and never imports emilia. It owns the attribute array's
shape and order.

```bp
import {Element} from "element";

pub fn classAttr(value: string) -> #(string, string) { … }   // #("class", value)
pub fn withAttrs(
    base: Array<#(string, string)>,
    extra: Array<#(string, string)>,
) -> Array<#(string, string)> { … }                          // append, base first
pub fn attrValue(attrs: Array<#(string, string)>, name: string) -> string { … }
```

`attrValue` returns `""` for an absent name rather than `?string`, matching the convention rakun's
`Request` already uses (`repository/rakun/src/http.bp:30-43`). It exists so a test — and a hydrator —
can read a class back out of a built tree without indexing, which is what makes the bridge test's
round-trip assertion possible.

### Why the attribute slot is a function, not a decorator

A decorator on an expression (`#[emilia([.Pad.All.4])] div(...)`) or an extension to `html.bp`'s
parser would be the two other shapes. Neither is available:

- A decorator function is `@Decl`-first and annotates a **declaration**
  (`repository/rakun/src/decorators.bp:222-224`). There is no expression-position decorator in
  botopink. See *Language gaps*.
- Even a declaration-level decorator could not help: a decorator body cannot call sibling functions,
  because only the decorator itself is emitted into the evaluation script
  (`repository/rakun/src/decorators.bp:44-46`). A `#[styled]` decorator could not call `emilia()`.
- `html.bp` is frozen (`fronts.md`, track C: "`src/element.bp`, `src/hooks.bp` and `src/html.bp` are
  frozen").

The replacement is a plain function call, which needs no comptime machinery at all. This front is
comptime-light by necessity, and that is a feature: the fewer moving parts between the two halves,
the fewer ways they can disagree.

## Steps

### Step 1 — `attributes.bp`: the slot and the merge

```bp
// repository/emilia/src/attributes.bp
import {Token} from "tokens";
import {Theme} from "theme";        // front 54
import {emilia} from "emilia";

pub fn mergeClass(base: string, extra: string) -> string {
    val joined = base + " " + extra;
    val withBase = if (extra == "") base else joined;
    val out = if (base == "") extra else withBase;
    return out;
}

pub fn className(tokens: Token[], th: Theme) -> string {
    return emilia(tokens, th);
}

pub fn styled(tokens: Token[], th: Theme) -> #(string, string) {
    return #("class", emilia(tokens, th));
}

pub fn styledWith(base: string, tokens: Token[], th: Theme) -> #(string, string) {
    return #("class", mergeClass(base, emilia(tokens, th)));
}
```

The module names its sibling explicitly (`from "tokens"`, `from "emilia"`): the bare
`import { Token };` shorthand type-checks but lowers to `require("../module")`, which resolves inside
the package and not when emilia is consumed as a dependency — the reason `emilia.bp:1` and
`root.bp:26-30` already spell it out.

`root.bp` gains `pub mod attributes;` and `pub mod html_hook;`, and `botopink.json`'s `files` array
gains both — a consumer cannot import a module the manifest does not list.

**Acceptance:**
- [ ] `styled(tokens, th)._0 == "class"` and `styled(tokens, th)._1 == emilia(tokens, th)` for a
      fixed list and a fixed theme.
- [ ] `className(tokens, themeA) != className(tokens, themeB)` when the two themes differ in an
      entry the tokens read — clause 1's theme half, asserted rather than assumed.
- [ ] `mergeClass("card", "e_abc") == "card e_abc"`; `mergeClass("", "e_abc") == "e_abc"`;
      `mergeClass("card", "") == "card"` — one space, never two, never a leading or trailing one.
- [ ] `mergeClass` does not sort, does not de-duplicate, and does not trim the base's interior
      spaces: `mergeClass("a  b", "e_x") == "a  b e_x"`.
- [ ] `repository/emilia/src/root.bp` declares both new modules and `botopink.json` lists both.

### Step 2 — the ASCII gate

The hash agrees between JS and erlang only for rule bodies without astral characters
(`emilia.bp:32-37`). Every token in fronts 41–47 emits ASCII; a payload leaf can carry anything.

`attributes.bp` therefore checks the class it is about to hand out and fails loudly rather than
handing the two halves a class they will disagree on:

```bp
pub fn assertAsciiBody(tokens: Token[]) -> bool { … }
```

The check runs over the composed rule body, not over the class name (the class name is hex and
always ASCII). Where a non-ASCII body is found the slot fails at that call site — a build-time error
naming the offending token — rather than emitting a class that renders correctly on one half and
mismatches on the other.

**Acceptance:**
- [ ] A token list whose rule body is pure ASCII passes and produces a class.
- [ ] A token list carrying a non-ASCII payload is rejected with a message naming the payload.
- [ ] The rejection is a compile-time or call-time failure, never a silently different class.
- [ ] The test file asserts both halves of that behaviour.

### Step 3 — `html_hook.bp`: the `[class]={…}` bridge

```bp
// repository/emilia/src/html_hook.bp
import {Token} from "tokens";
import {Theme} from "theme";        // front 54
import {className, mergeClass} from "attributes";

pub fn cls(tokens: Token[], th: Theme) -> string {
    return className(tokens, th);
}

pub fn clsWith(base: string, tokens: Token[], th: Theme) -> string {
    return mergeClass(base, className(tokens, th));
}
```

Two functions, both returning `string`, both short enough to sit in a `[class]={…}` hole without a
space. The module's docblock carries the no-space rule and the worked example, because the failure
mode — a hole with a space in it — surfaces as a parse error inside a template body with no line
number (`repository/jhonstart/src/html.bp:68-85`).

**Acceptance:**
- [ ] `cls(tokens, th)` is a `string` beginning `e_` and containing no space, so a pre-bound
      `val c = cls(tokens, th);` sits in a `[class]={c}` hole; the render of that hole is asserted by
      the `jhonstart-emilia` bridge test, not here.
- [ ] `cls(tokens, th) == className(tokens, th) == emilia(tokens, th)` for the same list and theme
      — three names, one value, asserted so a refactor cannot split them.
- [ ] The docblock shows the pre-bound `val` form first and says that `cls(tokens, th)` written
      inline in a hole fails, because of the space after the comma.
- [ ] The docblock states the no-space rule and cites `html.bp:109`.

### Step 4 — `html_attrs.bp`: jhonstart's half, with no knowledge of emilia

```bp
// repository/jhonstart/src/html_attrs.bp
import {Element} from "element";

pub fn classAttr(value: string) -> #(string, string) {
    return #("class", value);
}

pub fn withAttrs(
    base: Array<#(string, string)>,
    extra: Array<#(string, string)>,
) -> Array<#(string, string)> {
    return base.append(extra);
}

pub fn attrValue(attrs: Array<#(string, string)>, name: string) -> string {
    var found = "";
    for (attrs) { a ->
        if (a._0 == name) found = a._1;
    };
    return found;
}
```

Tuple fields are read as `a._0` / `a._1` — the spelling `element.bp:63-65` already uses.
`root.bp` gains `pub mod html_attrs;` and `botopink.json`'s `files` array gains it.

The module imports `element` and nothing else. **A test asserts that the string `emilia` does not
appear in `repository/jhonstart/src/`** — the dependency runs one way, and the one-way-ness is
checkable.

**Acceptance:**
- [ ] `withAttrs([#("id","x")], [styled(tokens, th)])` returns `[#("id","x"), #("class","e_…")]` — base
      first, appended, order preserved.
- [ ] `attrValue(attrs, "class")` returns the class; `attrValue(attrs, "missing")` returns `""`.
- [ ] `repository/jhonstart/src/html_attrs.bp` imports only `element`.
- [ ] No file under `repository/jhonstart/src/` names emilia.
- [ ] `repository/jhonstart/src/root.bp` declares the module and `botopink.json` lists it.

### Step 5 — the five ways the halves can disagree, asserted on the class

`test/attributes_test.bp` asserts the contract clauses on the class name and the CSS string alone;
it imports emilia and nothing else, and renders no HTML.

```bp
fn cardTokens() -> Token[] {
    val hovered: Token[] = [.Bg.Gray.100];
    val card: Token[] = [.Bg.White, .Pad.All.4, .Text.Bold, Token.Hover(hovered)];
    return card;
}

#[@future]
test "class: the card class is the shared fixture" {
    val th = defaultTheme();
    val c = className(cardTokens(), th);
    assert c == "e_<hex>";                    // the literal, one value on both rows
    val sheet = await flush();
    assert sheet.indexOf("." + c) != -1;      // the flushed rules carry the class they were hashed for
}
```

**Acceptance:**
- [ ] **Purity.** `className(cardTokens(), th)` called twice in one test returns the same string,
      and called after an intervening `emilia()` of a different list still returns the same string —
      no counter leaks in.
- [ ] **The theme is an input.** `className(cardTokens(), themeA) != className(cardTokens(), themeB)`
      for two themes differing in one entry the tokens read — clause 1, and the hazard a
      single-theme test would never show.
- [ ] **Order is identity.** `className([.Text.Bold, .Color.Black], th) != className([.Color.Black, .Text.Bold], th)`,
      asserted, so the contract is visible rather than incidental.
- [ ] **Merge order.** `styledWith("card", tokens, th)._1` starts with `"card "` and ends with the
      emilia class — asserted with `startsWith` and `endsWith`, in that order.
- [ ] **Attribute order.** `withAttrs([#("id","x")], [styled(tokens, th)])` keeps `id` before
      `class`, asserted on the array; the same order in a rendered tag is the bridge test's cell.
- [ ] **Cross-target agreement.** The class for `cardTokens()` under `defaultTheme()` is asserted
      against a **literal hex string**. That one line is the hydration gate: the `commonJS` and
      `erlang` rows run the same assertion, and if the two hashes ever diverge the erlang row goes
      red. The `jhonstart-emilia` bridge test (jhonstart front 30) and front 68's bundle test assert
      the same literal.
- [ ] **The flushed sheet carries the class.** `await flush()` after `className(cardTokens(), th)`
      contains the selector `.<class>` — the stylesheet half of the pair the server ships.
- [ ] **The literal is regenerated exactly once**, when front 56 lands and the hashed body becomes
      `encodeSheet(tokensToSheet(tokens, th))`; the bridge test and front 68 take the new value in
      the same commit. A second regeneration means something other than 56 changed the encoding,
      which is a defect rather than a routine update.

## Examples

- [`./examples/attributes-example.bp`](./examples/attributes-example.bp) — a card component's
  attribute arrays built with `styled` / `styledWith` as plain data, the class a `[class]={…}` hole
  receives through `cls`, the static-class merge, and the no-space rule shown both as the form that
  works and, in a comment, as the form that does not; every assertion is on a class name, an
  attribute array or the flushed CSS.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| There is no expression-position decorator. A decorator function is `@Decl`-first and annotates a declaration, so `#[emilia([.Pad.All.4])] div(…)` cannot exist | the whole attribute slot; it is why this front ships functions instead of an annotation | a plain call in the `attrs:` argument: `div([…], attrs: [styled(cardTokens())])` | allow an annotation on an expression that receives the expression as `@Expr<T>` and returns a replacement, so `#[styled([.Pad.All.4])] div(…)` expands to the call above |
| A decorator body cannot call sibling functions — only the decorator itself is emitted into the evaluation script | a hypothetical declaration-level `#[styled]`, which could not call `emilia()` even if the first gap were closed | inline the whole body, or do not use a decorator — this front does the latter | emit the decorator's module scope into the evaluation script, so a decorator may call the library it belongs to |
| A dot-shorthand path ending in a payload call does not propagate the typed-array context | a token list written inline in a `styled([…])` argument when it contains a payload leaf | bind the list to a typed `val` first, or build it in a named function — which this front does anyway, for the no-space rule below | let a leading-dot path carry a payload call inside a typed array literal |

## Blocked — constraints of frozen files

| Constraint | File | Consequence |
|---|---|---|
| A `[name]={…}` hole may not contain a space | `repository/jhonstart/src/html.bp:109` splits the tag body on `" "` before parsing attributes; `html.bp` is frozen for this milestone | `[class]={styled([.Text.Bold, .Color.Blue.500])}` is lexed as four attributes and fails with a parse error carrying no line number. The supported forms are a pre-bound identifier (`[class]={card}`) and a no-space call (`[class]={cls(cardTokens())}` — no space after the comma, so single-argument calls only). `html_hook.bp` exists to make the second form short. |
| The DSL has no `[emilia]={…}` attribute | same frozen file | The `[class]={…}` hole carries the class string instead. This is not a workaround for a missing feature; it is the same feature reached through the attribute that already exists. If `html.bp` unfreezes in 1.0.10, an `[emilia]={…}` handler is a one-arm addition to its `attrBracketProp` branch. |
| Plain `name="value"` attributes are captured for the LSP overlay and do not change the built tree | `repository/jhonstart/src/html.bp:28-30`, `:232-233` | `<div class="card">` in the DSL sets nothing. A static class must go through `[class]={…}` too, which is what `clsWith` is for. |

## Test plan

One file, `repository/emilia/test/attributes_test.bp`, run by `botopink test` from `repository/emilia/` and
by `zig build test-libs` on **both** `commonJS` and `erlang`. Both rows are required, and the reason
is this front's entire point: the class name must be identical on the two targets, and a single-
target test cannot show that.

**`test/attributes_test.bp`** — the slot in isolation, and the contract. `styled`, `styledWith`, `className`,
`mergeClass` and the ASCII gate, each asserted against literals: the three merge cases, the
no-sorting and no-de-duplication clauses, the `""` edge on both sides, and a non-ASCII payload being
rejected rather than hashed.

It also carries contract 4's emilia-side literal (the `class: attributes ---- the shared fixture`
snapshot) and the five contract clauses of Step 5, asserted on class names, attribute arrays and the
flushed CSS. It renders no HTML and imports nothing but emilia, `emilia-test` and std; it is the
emilia half of the shared fixture.

The rendered-markup round trip — the builder tree and the DSL tree rendered and compared byte for
byte, the attribute order in the rendered tag, the flushed selector matching the class in the
rendered attribute — is the `jhonstart-emilia` bridge's test (`modules/jhonstart-emilia/test/
bridge_test.bp`, [jhonstart front 30](../../04-jhonstart/30-jhonstart-streaming/README.md) step 9),
because that member is the one package that imports both. It also exercises `html_attrs.bp`'s three
functions in the composition that ships, and carries the one-way-dependency assertion — the string
`emilia` absent from `repository/jhonstart/modules/jhonstart/src/`.

**What the coordinator must check against jhonstart front 30 and onze front 68.** The render writes
the `class` attribute into the HTML on the erlang side; the client bundle recomputes it in
JavaScript. Both must use `styled` / `styledWith` / `classAttr`, must not spell `"class"` or join
class names themselves, and must be handed the **same `Theme` value** — the sixth disagreement mode
above. The literal-hex assertion in `attributes_test.bp` is the shared fixture: the bridge test and
front 68's bundle test assert the same literal for the same token list and theme, per contract
`§ 4`. If the three ever differ, hydration is broken and a test is red before a user sees it.

## Definition of done

- [ ] `repository/emilia/src/attributes.bp` and `repository/emilia/src/html_hook.bp` exist, are
      declared in `emilia/src/root.bp`, and are listed in `emilia/botopink.json`.
- [ ] `repository/jhonstart/src/html_attrs.bp` exists, is declared in `jhonstart/src/root.bp`, is
      listed in `jhonstart/botopink.json`, and imports only `element`.
- [ ] No file under `repository/jhonstart/src/` names emilia, asserted by the bridge test.
- [ ] No test or example of this front imports jhonstart, and emilia's `botopink.json` names no
      jhonstart dependency, dev-dependency included.
- [ ] `mergeClass` has exactly one implementation in the workspace.
- [ ] The class-name contract — the six clauses, the theme among them — is written in
      `attributes.bp`'s docblock, not only in this README, and matches `contracts.md § 4` word for
      word where they overlap.
- [ ] Every slot function but `mergeClass` takes `th: Theme`, and no call site in the milestone
      builds a `Theme` inline.
- [ ] The no-space rule for `[class]={…}` is written in `html_hook.bp`'s docblock with the
      `html.bp:109` citation.
- [ ] `repository/emilia/AGENTS.md` and `repository/jhonstart/AGENTS.md` both record the new modules
      and the cross-repo seam.
- [ ] The literal-hex fixture in `attributes_test.bp` is shared with the `jhonstart-emilia` bridge
      test and front 68 and all three assert it, and it was regenerated exactly once, when 56 landed.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because agreement between the two is the deliverable.
