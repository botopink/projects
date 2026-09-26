# Front 56 — emilia cascade and output

**Track:** D emilia
**Priority:** high — and the highest-leverage front in track D. Roughly forty rows of the Tailwind coverage audit bottom out here: without a rule model, `group-*`, `peer-*`, `rtl`, `in-*`, `*`, `**`, `space-*`, `divide-*`, `@keyframes`, `@layer`, `@supports`, `@container` and the `important` flag have nowhere to go, and there is no defined winner when two tokens set the same property.
**Target:** comptime
**Wave:** 1 — immediately after 54, which is wave 0. Fronts 33, 34 and 35 are wave 2 and all three consume the `Sheet`/`Variant` interface defined here.
**Depends on:** 54 (the `Theme` that `Options` carries and the `themeCss`/`keyframeCss` strings the theme layer is built from)
**Owns:** `repository/emilia/src/output.bp`; the host-cell and public-entry half of `repository/emilia/src/emilia.bp` (`register`, `flushSheet`, `emilia`, `emiliaWith`, `styleRule`, `flush`, `tokenToCss`, `tokensToCss`; the class-name hash is std's `content_hash.contentHash`, and deleting emilia's `hashHex` duplicate is this front's — decision 116), fenced under a banner naming this front; `repository/emilia/test/output_test.bp`, `repository/emilia/test/cascade_test.bp`; the `pub mod output;` line in `src/root.bp` and its entry in `botopink.json`
**Does not touch:** any `Token` section in `src/tokens.bp`, and any per-section sub-dispatcher in `src/emilia.bp` — those belong to fronts 33–47, 57 and 58
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1 Conflitos de Estilo`, `§ 3.2 Referência Completa de Variantes`, `§ 3.5 Animações Customizadas`, `§ 3.7 CSS Customizado com @layer`, `§ 20.1 @import "tailwindcss"` · https://tailwindcss.com/docs/styling-with-utility-classes

---

## Problem

`emilia` emits one flat class body with every block nested inside it. `tokenToCss`
(`repository/emilia/src/emilia.bp:73-93`) returns a `string`, and a modifier arm wraps that string
in braces: `Hover(inner) -> ":hover{" + tokensToCss(inner) + "}"`. The document that reaches the
page is one `<style>` element containing `.e_x{background:#000000;:hover{background:#ffffff}}`
(asserted at `emilia.bp:505-511`). Everything a token can express has to fit inside one class body.

That shape cannot carry most of what fronts 34, 40, 44, 55 and 58 are for:

- **Selectors outside the class.** `group-hover` is `&:is(:where(.group):hover *)`, `rtl` is
  `[dir="rtl"] &`, `in-*` is `:where(...) &`, `*` is `:is(& > *)` (`§ 3.2` reference table). The
  class is not at the start of those selectors, and two of them do not contain the class as a
  leading token at all. A nested `":hover{…}"` string cannot express any of them.
- **`space-x-*` and `divide-*`** select siblings of the styled element, not the element.
- **`@keyframes`.** A keyframes rule is not a style rule; it cannot be nested inside one, so
  `animate-spin` (front 44) has no legal output today.
- **`@layer`.** `§ 3.7` and `§ 20.1` put theme, preflight, components and utilities in named layers
  so that a project's own CSS can beat a utility deliberately. There are no layers in the output at
  all, which means front 55's reset would have the same weight as a utility and win or lose by
  accident of order.
- **Conflicts.** `§ 3.1` says the last rule in the stylesheet wins. `emilia` has no defined order:
  `flushSheet` iterates a `Map`'s insertion order in JS and a `lists:keystore` list in Erlang
  (`emilia.bp:23-29`), and nothing says what happens when two tokens in the same list set `padding`.
- **`important` and `prefix`.** `§ 3.1` gives both as build-level options. There is nowhere to put
  either.

The nested form is also not obviously valid CSS everywhere: `.e_x{…;:hover{…}}` is CSS Nesting, and
its `:hover` — a bare pseudo-class with no `&` — relies on the relaxed nesting parse. That may be
fine; nothing tests it, which is the actual problem.

## Current state

- `fn tokenToCss(t: Token) -> string` — `emilia.bp:73`. Sixteen arms, ten of them section
  sub-dispatchers, six of them modifier wraps producing nested blocks.
- `fn tokensToCss(tokens: Token[]) -> string` — `emilia.bp:102-104`. Maps, filters empties, joins
  with `";"`.
- `pub fn emilia(tokens: Token[]) -> string` — `emilia.bp:46-51`. Folds to a string, hashes it with
  `hashHex`, registers `name -> body`, returns `"e_" + hex`.
- `declare fn hashHex(s: string) -> string` — `emilia.bp:80`, a private host cell whose two templates
  are byte-identical to std's `content_hash.contentHash` (`libs/std/src/content_hash.bp:34-37`, whose
  own header records the duplicate). Decision 116 deletes it: the class name is
  `"e_" + contentHash(…)`, and every hex a fixture pins is unchanged, because the fold is the same.
- `declare fn register(name: string, body: string) -> void` — `emilia.bp:23-25`. A `Map` on
  `globalThis` in commonJS, a keyed list in the Erlang process dictionary.
- `declare fn flushSheet() -> @Task<string>` — `emilia.bp:28-30`. **Builds the `<style>` string
  inside the host cell**, in JS and in Erlang independently: `"<style>" + entries.map(e => "." + k + "{" + v + "}") + "</style>"`.
  All document assembly is in the two `#[@External]` templates, where botopink cannot reach it.
- The six modifier at-rules are literal and wrong against `§ 3.2`: `@media(min-width:768px)` where
  the doc says `@media (width >= 48rem)`, and `:hover` where the doc says
  `@media (hover: hover) { &:hover }`.

## Mechanism

**The rule model.** One record replaces the declaration string.

```bp
pub type Rule(
    layer: string,
    atRules: string[],
    selector: string,
    declarations: string,
    important: bool,
)

pub type Block(header: string, body: string)

pub type Sheet(rules: Rule[], blocks: Block[])
```

`selector` is a **nesting template**: it contains exactly one `&`, and `&` stands for the class. The
base selector is `"&"`. A variant substitutes its own template for the `&` it finds, which is
exactly CSS nesting semantics, and it is the reason this single field covers every row of `§ 3.2`
without a second one — the doc writes those rows as `&:hover`, `[dir="rtl"] &`, `:is(& > *)`,
`&:is(:where(.group) ... *)`, and each is a template with one `&`. A `selector` **without** an `&`
is a literal selector, used by front 55's reset and by 54's `:root` block. A selector with two or
more `&` is refused at build time; there is no option to allow it.

`atRules` is outermost-first. `declarations` is a `;`-joined list with no braces around it.
`Block` is for rules that are not style rules — today only `@keyframes`, whose `header` is
`"@keyframes spin"` and whose `body` is the brace-balanced keyframe list.

**The variant.**

```bp
pub type Variant(atRule: string, selector: string)
```

Two fields, and the whole `§ 3.2` table fits: `hover` is
`Variant(atRule: "@media (hover: hover)", selector: "&:hover")`; `rtl` is
`Variant(atRule: "", selector: "[dir=\"rtl\"] &")`; `md` is
`Variant(atRule: "@media (width >= 48rem)", selector: "&")`; `group-hover` is
`Variant(atRule: "", selector: "&:is(:where(.group):hover *)")`. **This is the interface front 34
implements**: front 34 writes one `Variant`-returning function per variant name and nothing else
about emission.

**The interface the sixteen utility fronts implement.** A section dispatcher keeps returning a
declaration string — `fn textTokenToCss(t: Token.Text, th: Theme) -> string` — and the top-level
dispatcher adapts it. Fronts 33–47 therefore never see `Rule`, `Sheet` or `Variant`:

```bp
fn tokenToSheet(t: Token, th: Theme) -> Sheet {
    val out = case t {
        Text(_inner) -> declSheet(textTokenToCss(_inner, th));
        Divide(_inner) -> divideTokenToSheet(_inner, th);
        Hover(inner) -> nestVariant(tokensToSheet(inner, th), hoverVariant());
    };
    return out;
}
```

`declSheet(decls)` is the one-line adapter for the common case; it returns an empty `Sheet` when
`decls` is `""`, which preserves today's `filter({ d -> d != "" })` behaviour. A front whose tokens
genuinely need a selector — `space-x-*`, `divide-*` in front 35 and 40 — writes a
`…TokenToSheet(t, th) -> Sheet` instead and says so in its own README. Two shapes, one line each in
the shared `case`, exactly as `fronts.md` requires.

The dispatcher signature gains the `Theme` parameter from front 54. That is a change to every
sub-dispatcher's signature, which is why 54 and 56 land before 33/34/35 rather than beside them.

**Where the document is assembled.** Today it is assembled twice, in JS and in Erlang, inside two
`#[@External]` templates. That is where the byte-level divergence risk lives and it is not testable
from botopink. 56 moves assembly into botopink: the host cell becomes a dumb string store, and a new
`drainRules()` external returns the raw registered payloads. Rendering — layer order, at-rule
hoisting, `!important`, the class prefix, keyframe dedup — happens in `output.bp`, in one place, on
both targets.

The host cells stay in `emilia.bp`. They cannot move to `output.bp`: a cross-module bare import of
an `#[@External.…]` declaration resolves at type level and is `undefined` at run time, which is
exactly why emilia folded its host cells into `emilia.bp` in the first place
(`repository/emilia/src/root.bp:9-22`). `output.bp` holds the pure model, the codec and the
renderer; `emilia.bp` holds the cells and the public entry points.

**Carrying a `Sheet` through a string-keyed cell.** `register(name, body)` stores one string. A
`Sheet` is a record tree, so it is encoded: fields joined by `"\t"`, the `atRules` list joined by
`"\r"`, records joined by `"\n"`, each record tagged `"R"` or `"B"`. None of those three characters
can appear in a rendered declaration, and a test asserts it for every front's output. The encoding
is also what gets hashed, so the class name is stable for a given `Sheet` and two different token
lists that render identically still get different names — which is correct, because they are
different inputs.

**The class name, and contract 4.** [`../contracts.md`](../../contracts.md) § 4 pins the class scheme as
`"e_" + djb2hex(tokensToCss(tokens))` — the djb2 fold, the seed, the multiplier, the mask, and the
five clauses front 48 tests. Everything in that contract survives this front except the *name of the
function whose output is folded*: `tokensToCss` becomes `encodeSheet(tokensToSheet(tokens, th))`,
because a `Sheet` is what a token list now produces. The fold itself is std's `content_hash.contentHash`
(decision 116) — the same djb2 templates emilia's `hashHex` carried, so no literal moves on that
account. The properties the contract actually rests on
are unchanged and this front keeps them:

- still a pure function of the token list, with nothing else entering the hash;
- token order is still class identity, since `tokensToSheet` preserves list order and `encodeSheet`
  writes rules in that order;
- still ASCII-only for the same reason — the JS cell folds UTF-16 units and the Erlang cell folds
  codepoints;
- the shared fixture in `emilia/modules/emilia/test/attributes_test.bp` (front 48) still asserts one
  literal hex string on both targets.

What does change is the literal itself: the fixture's expected hex is regenerated once, in this
front, and fronts 23 and 68 take the new value. **The theme is now an input to the hash**, because
a token whose value comes from `themeValue` renders differently under a different theme; contract 4's
clause 1 therefore reads "a pure function of the token list *and the theme*" after this front. That
is a contract amendment, not a private decision, and it belongs to the coordinator and front 48.

**Order.** `§ 3.1` says the last rule wins. 56 makes that deterministic:

1. `@layer theme, base, components, utilities;` is emitted first when layers are on.
2. The `theme` layer: 54's `themeCss(o.theme)` as a `:root` rule.
3. The `base` layer: `o.base`, which is empty unless front 55 filled it.
4. The `components` layer: rules a front 59 named utility placed there.
5. The `utilities` layer: registered classes in registration order; within one class, tokens in the
   order they were listed; within one class, rules with no at-rules before rules with at-rules, so
   a `md:` override beats the unconditioned utility on a mobile-first read.
6. `@keyframes` blocks last, outside every layer, deduplicated by header. Keyframe rules are not
   subject to the cascade, so their placement is a formatting choice and the doc does not specify
   one; it is written down here so it is not re-litigated.

**`important` and `prefix`.** Both are `Options` fields, per `§ 3.1`'s build-level `important` flag
and `prefix(tw)`. Emilia's class names are content hashes over `[a-z0-9_]`, so a prefix is a plain
concatenation — Tailwind's escaped `.tw\:text-red-500` form has no analogue here because emilia has
no literal class names to escape. That divergence is intentional and is stated in the README rather
than hidden in the renderer.

## Steps

### Step 1 — the model and its constructors

```bp
pub type Rule(layer: string, atRules: string[], selector: string, declarations: string, important: bool)
pub type Block(header: string, body: string)
pub type Sheet(rules: Rule[], blocks: Block[])
pub type Variant(atRule: string, selector: string)

pub fn emptySheet() -> Sheet
pub fn declSheet(decls: string) -> Sheet
pub fn staticSheet(layer: string, selector: string, decls: string) -> Sheet
pub fn blockSheet(header: string, body: string) -> Sheet
pub fn mergeSheet(a: Sheet, b: Sheet) -> Sheet
```

`declSheet("")` returns `emptySheet()`. `staticSheet` is how 54 and 55 produce rules whose selector
is literal. `mergeSheet` concatenates rules then blocks, preserving order.

**Acceptance:**
- [x] `declSheet("color:red")` has one rule with `layer == "utilities"`, `atRules.length == 0`,
      `selector == "&"` and `important == false`. — held: output.bp test "declSheet — one utilities rule, no at-rules, the bare ampersand, not important"
- [x] `declSheet("")` has zero rules and zero blocks. — held: output.bp test "declSheet — an empty declaration is an empty sheet, not an empty rule"
- [x] `mergeSheet` is associative on rule order — `mergeSheet(mergeSheet(a, b), c)` and
      `mergeSheet(a, mergeSheet(b, c))` produce the same rendered string. — held: output.bp test "mergeSheet — associative on rule order, so the rendered string is the same"

### Step 2 — variant nesting

```bp
pub fn nestVariant(s: Sheet, v: Variant) -> Sheet
```

For each rule: the new selector is `v.selector` with its single `&` replaced by the rule's current
selector; the new `atRules` is `v.atRule` prepended, unless it is `""`. Blocks pass through
untouched — an at-rule does not wrap a keyframes rule.

The outer variant's template wraps the inner one, so `Hover([Before([...])])` gives `&:hover::before`
and `Hover([Md([...])])` gives `@media (width >= 48rem)` around `&:hover` — the outer modifier is
outermost, which is what the nesting test in `emilia.bp:455-461` asserts today and which this step
must keep true in the new shape.

**Acceptance:**
- [x] `nestVariant(declSheet("color:red"), Variant(atRule: "", selector: "&:hover"))` yields a rule
      whose selector is `"&:hover"`. — held: output.bp test "nestVariant — a selector-only variant rewrites the selector and adds no at-rule"
- [x] Nesting twice yields `"&:hover::before"` for hover-outside-before and `"&::before:hover"` for
      the reverse, and a test pins both so the order is not accidental. — held: output.bp tests "nestVariant — hover outside before is `&:hover::before`" and "nestVariant — before outside hover is `&::before:hover`, the other order"
- [x] `nestVariant` with `Variant(atRule: "@media (width >= 48rem)", selector: "&")` prepends the
      at-rule and leaves the selector alone. — held: output.bp test "nestVariant — a breakpoint variant prepends its at-rule and leaves the selector alone"
- [x] A `Variant` whose selector holds zero or two `&` fails the build. The message names the
      selector. There is no argument that permits it. — held (shape: output.bp:checkVariantSelector `@panic`s when the variant is applied, naming the selector; no opt-out)
- [x] Blocks in the input `Sheet` are byte-identical in the output. — held: output.bp test "nestVariant — blocks are byte-identical through the nesting"

### Step 3 — the important flag, per rule

```bp
pub fn markImportant(s: Sheet) -> Sheet
```

Sets `important` on every rule. Front 34's `Important(inner)` modifier is one line on top of it;
`Options.important` applies it to everything at render time. Rendering appends `!important` to each
declaration, not to the rule.

**Acceptance:**
- [x] `markImportant(declSheet("color:red;font-weight:700"))` renders
      `color:red!important;font-weight:700!important`. — held: output.bp test "markImportant — every declaration of the rule, not the rule"
- [x] `markImportant` on an empty sheet is a no-op. — held: output.bp test "markImportant — an empty sheet is a no-op"

### Step 4 — the codec

```bp
pub fn encodeSheet(s: Sheet) -> string
pub fn decodeSheet(raw: string) -> Sheet
```

Records joined by `"\n"` and tagged `R`/`B`; fields joined by `"\t"`; the `atRules` list joined by
`"\r"`.

**Acceptance:**
- [x] `decodeSheet(encodeSheet(s))` renders identically to `s`, for a sheet carrying two at-rules,
      a non-`&` selector, an important rule and a block. — held: output.bp test "codec — a round trip preserves two at-rules, a non-ampersand selector, important, and a block"
- [x] `encodeSheet(emptySheet()) == ""` and `decodeSheet("")` is `emptySheet()`. — held: output.bp test "codec — an empty sheet encodes to the empty string and back"
- [x] A test walks every front's dispatcher output and asserts no declaration contains `"\n"`,
      `"\t"` or `"\r"`. This is the assumption the codec rests on, so it is checked, not assumed. — held: emilia.bp test "codec — every walked leaf of fronts 34-46 carries no codec separator" (every front leaf list, >5000 tokens, with a planted-`\n` control)

### Step 5 — the host cell and the new drain

`register(name, body)` stays as it is — a name-keyed string store, already correct for encoded
payloads. `flushSheet()` stays as it is so nothing that depends on it breaks mid-milestone. A new
cell returns the raw store instead of a rendered document:

```bp
declare fn drainRules() -> @Task<string>;
```

It returns the registered entries as `name + "\t" + payload` records joined by `"\n"`, in insertion
order, and clears the cell — the same per-render contract `flushSheet` has today
(`emilia.bp:53-56`). Both the commonJS and the Erlang template do exactly that and nothing else: no
`<style>`, no braces, no ordering.

**Acceptance:**
- [x] `drainRules()` returns `""` when nothing was registered. — held: emilia.bp test "drainRules — nothing registered drains to the empty string"
- [x] Two consecutive drains: the second is `""`. — held: emilia.bp test "drainRules — a drain clears the cell, so the second of two is empty"
- [x] The commonJS and Erlang templates return byte-identical strings for the same register
      sequence, asserted by running the same test on both targets. — held: emilia.bp test "drainRules — the payloads come back verbatim, in insertion order", green on both targets
- [x] Neither template contains the characters `<`, `{` or `}`. — held (shape: asserted on the drain's output — the JS template's function braces and Erlang's `<<>>` binaries are syntax, not assembly): emilia.bp test "drainRules — the cell assembles nothing: no `<style>`, no brace, in what it hands back"

### Step 6 — options and the render

```bp
pub type Options(theme: Theme, base: Rule[], prefix: string, important: bool, layers: bool)

pub fn defaultOptions() -> Options
pub fn withTheme(o: Options, th: Theme) -> Options
pub fn withBase(o: Options, base: Rule[]) -> Options
pub fn withPrefix(o: Options, prefix: string) -> Options
pub fn withImportant(o: Options, important: bool) -> Options
pub fn withLayers(o: Options, layers: bool) -> Options

pub fn renderRule(className: string, r: Rule, o: Options) -> string
pub fn renderDocument(raw: string, o: Options) -> string
```

`defaultOptions()` is `Options(theme: defaultTheme(), base: [], prefix: "", important: false, layers: true)`.
`withBase` is how front 55 turns preflight on; the opt-out `§ 4` describes is `withBase(o, [])`,
which is the default, so preflight is opt-in here rather than opt-out. That is a deliberate
inversion of Tailwind's default and front 55 states it in its own README.

`renderRule` substitutes `"." + o.prefix + className` for the `&` in the rule's selector, wraps the
declarations in the rule's at-rules outermost-first, and appends `!important` per declaration when
either the rule or `o.important` says so.

**Acceptance:**
- [x] `renderRule("e_1", declSheet("color:red").rules.at(0)…, defaultOptions())` renders
      `.e_1{color:red}`. — held: output.bp test "renderRule — a bare utility is a class and a brace pair"
- [x] With `withPrefix(o, "tw_")` the same rule renders `.tw_e_1{color:red}`. — held: output.bp test "renderRule — the prefix is a plain concatenation, emilia having no name to escape"
- [x] A rule with `atRules: ["@media (width >= 48rem)"]` renders
      `@media (width >= 48rem){.e_1{color:red}}`. — held: output.bp test "renderRule — one at-rule wraps the rule"
- [x] A rule with two at-rules nests them outermost-first. — held: output.bp test "renderRule — two at-rules nest outermost-first"
- [x] A rule whose selector is `"html"` renders `html{…}` and ignores the prefix. — held: output.bp test "renderRule — a literal selector renders literally and ignores the prefix"
- [x] `renderDocument` emits `@layer theme, base, components, utilities;` first when
      `layers == true`, and emits no `@layer` token at all when `layers == false`. — held: output.bp tests "renderDocument — the layer statement comes first when layers are on" and "renderDocument — no @layer token at all when layers are off"
- [x] Keyframe blocks appear once each even when three classes registered the same animation. — held: output.bp test "renderDocument — a keyframes block appears once however many classes registered it"

### Step 7 — the public entry points

```bp
import {content_hash} from "std";

pub fn styleRule(tokens: Token[], th: Theme) -> #(string, string)   // (class name, encoded body), registers nothing
pub fn emiliaWith(tokens: Token[], th: Theme) -> string              // styleRule, then register
pub fn emilia(tokens: Token[]) -> string
pub fn flushWith(o: Options) -> @Task<string>
pub fn flush() -> @Task<string>
```

`emilia(tokens)` is `emiliaWith(tokens, defaultTheme())` and `flush()` is
`flushWith(defaultOptions())`. Both keep the signatures they have today, so no consumer changes.

`styleRule` is the pure half of `emiliaWith`: `"e_" + content_hash.contentHash(encodeSheet(
tokensToSheet(tokens, th)))` and the encoded body, with no host cell touched. It is the function onze
front 68 calls at build time to fill its `styleMap` (decision 116 rule 7): onze imports emilia
directly, and the `jhonstart-emilia` bridge stays the render plugin only. `hashHex` is deleted; the
class name comes from std.

**What does change is the emitted CSS for modifiers**, and this front owns that break. The document
for `[.Bg.Black, Token.Hover([.Bg.White])]` goes from

```
<style>.e_x{background:#000000;:hover{background:#ffffff}}</style>
```

to

```
<style>@layer theme, base, components, utilities;@layer theme{:root{--spacing:0.25rem …}}@layer utilities{.e_x{background:#000000}.e_x:hover{background:#ffffff}}</style>
```

The six existing modifier tests in `emilia.bp:435-461` and `:505-511` are rewritten to the new
shape as part of this step. They are the only existing assertions this front invalidates, and the
token surface they use is unchanged.

**Acceptance:**
- [x] `emilia(tokens)` still returns `"e_" + hex` and still collapses two identical token lists to
      one class. — held: emilia.bp tests "two emilia sites with the same token list collapse to one class" and "emilia of an empty token list is a stable class that contributes no rule"
- [x] `styleRule(tokens, th)._0 == emiliaWith(tokens, th)` for the contract-4 fixture, and
      `styleRule` leaves the sheet cell empty (a following `flush()` has no `@layer utilities` body). — held: emilia.bp test "styleRule — the class emiliaWith returns, and no registration"
- [ ] `grep -n "hashHex" repository/emilia/modules/emilia/src` is empty; the class name is computed
      with std's `content_hash.contentHash`, and the contract-4 fixture's hex is unchanged by the switch. — **open:** `hashHex` stays — switching to std's `content_hash.contentHash` is a std import line in `emilia.bp`, which `00 · 23-std-purity` (std's new tree, running in parallel) owns; the switch lands with or after it
- [x] `flush()` still clears the cell; two consecutive flushes give two independent documents and
      the second has no `@layer utilities` body. — held: emilia.bp test "two consecutive flushes emit two independent documents"
- [x] Every rewritten test in `emilia.bp` names the section of `§ 3.2` its expected selector comes
      from. — held: the Hover, Focus/Active, Md/Lg/Xl, nested-modifier, sibling-rule and conflict-variant tests name their `§ 3.2` row
- [x] A rule and a variant of the same rule appear in the document in that order. — held: emilia.bp test "conflict — a variant of a rule follows the rule it varies"

### Step 8 — the conflict rule, written down and tested

`§ 3.1`: the last rule in the stylesheet wins. Inside one `emilia()` call that is the token list
order; across calls it is registration order.

**Acceptance:**
- [x] `emilia([.Layout.Grid, .Layout.Flex])` renders `display:grid;display:flex` in that order, and
      a comment in the test cites `§ 3.1`'s `grid flex` example. — held: emilia.bp test "conflict — `grid flex` renders in list order, so the last one wins" (its banner cites the reference's `grid flex` example)
- [x] Two `emilia()` calls registering the same property render in call order. — held: emilia.bp test "conflict — two emilia calls setting the same property render in CALL order"
- [x] Reordering an unrelated token does not change any other rule's position. — held: emilia.bp test "conflict — reordering an unrelated token moves no other rule"

## Examples

- [`./examples/cascade-example.bp`](./examples/cascade-example.bp) — one card whose styles reach
  outside its own class: a hover that is a sibling rule rather than a nested block, a breakpoint
  that is a hoisted `@media`, a reset supplied through `Options`, and a layered document a project's
  own CSS could deliberately beat.

## Language gaps

None — every construct in the example parses today. Nothing this front needs is missing from the
language; see [`../language-gaps.md`](../../language-gaps.md) for the milestone's list.

Three real constraints shaped the design. None of them is a language gap; all three are recorded so
that the next reader does not try to design them away:

| Constraint | Where it bites | How 56 lives with it |
|---|---|---|
| A cross-module bare import of an `#[@External.…]` declaration is `undefined` at run time (`repository/emilia/src/root.bp:9-22`) | `output.bp` cannot declare `register`/`drainRules` | The cells stay in `emilia.bp`; `output.bp` is pure |
| There is no module-level mutable state | Nothing can accumulate rules in botopink between calls | The host cell is the accumulator, and a `Sheet` is encoded into it |
| Records are immutable | `nestVariant`, `markImportant` and every `with…` | They return new values; no in-place update appears anywhere |

## Test plan

`repository/emilia/test/output_test.bp` covers the model, the codec, `nestVariant`, `renderRule` and
`renderDocument`. `repository/emilia/test/cascade_test.bp` covers order: the `§ 3.1` conflict rule,
layer order, at-rule hoisting, keyframe dedup and the two-flush contract.

Both run under `botopink test` at `repository/emilia/` and under `zig build test-libs`. Track D is
target-independent, so both files must be green on `--target commonJS` and on `--target erlang`.
That is not a formality for this front: the two host-cell templates are written twice, once per
target, and the whole point of moving assembly into botopink is that the divergence becomes
testable. A cascade test that is green on commonJS only means the Erlang drain is wrong.

Two cases cannot be runtime asserts and are recorded in the test file and carried into the
compiler's own suite, following `repository/rakun/test/di_test.bp:14-16`: a `Variant` selector with
the wrong number of `&`, and a declaration containing a codec separator.

## Definition of done

- `src/output.bp` exists, is declared in `src/root.bp`, listed in `botopink.json`, and declares no
  externals.
- `Rule`, `Block`, `Sheet`, `Variant` and `Options` are final; fronts 33–47, 55, 57, 58 and 59 are
  written against them without editing `output.bp`.
- `tokenToSheet(t, th)` is the shared dispatcher and every front's arm is one line.
- Document assembly happens once, in botopink, not twice in two `#[@External]` templates.
- The six modifier tests in `emilia.bp` are rewritten to the hoisted shape and cite `§ 3.2`.
- The front's tests are green on its assigned target — for track D, both of them.

