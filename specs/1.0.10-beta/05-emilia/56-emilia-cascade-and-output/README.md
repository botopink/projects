# Front 56 — emilia cascade and output

**Track:** D emilia · **Priority:** high · **Level:** 1 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (the `Theme` that `Options` carries; `themeCss`/`keyframeCss`)
**Code:** `repository/emilia/modules/emilia/src/output.bp` (pure: model, codec, renderer — no
externals); in `src/emilia.bp` the host cells (`register`, `drainRules`, `lookupRule`, `hashHex`), the
public entry points, `fullTheme`/`fullOptions`, and the shared `tokenToSheet` dispatcher shell
**User docs:** `repository/emilia/docs.md` § *The runtime*, § *The cascade and the output*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1`, `§ 3.2`, `§ 3.5`, `§ 3.7`, `§ 20.1` · https://tailwindcss.com/docs/styling-with-utility-classes

**Open:** one box — the class name still comes from emilia's own `hashHex`, not std's content hash (Step 7).

---

## What it delivers

The rule model every token lowers to, the codec that carries it through the host cell, and the
renderer that assembles the layered `<style>` document — once, in botopink, for both targets.

```bp
pub type Rule(layer: string, atRules: string[], selector: string, declarations: string, important: bool)
pub type Block(header: string, body: string)          // a non-style rule: `@keyframes spin` + body
pub type Sheet(rules: Rule[], blocks: Block[])
pub type Variant(atRule: string, selector: string)
pub type Options(theme: Theme, base: Rule[], prefix: string, important: bool, layers: bool)
```

- **`selector` is a nesting template** with exactly one `&` standing for the class (`&`, `&:hover`,
  `[dir="rtl"] &`, `:is(& > *)`, `&:is(:where(.group):hover *)`). No `&` is a literal selector
  (54's `:root`, 55's reset); two or more is refused when the variant is applied, naming the
  selector, with no opt-out. `atRules` is outermost-first; `declarations` is `;`-joined, no braces.
- **Constructors:** `emptySheet()`, `declSheet(decls)` (`declSheet("")` is empty), `staticSheet(layer,
  selector, decls)`, `blockSheet(header, body)`, `mergeSheet(a, b)` (rules then blocks, in order),
  `declarationsOf(s)`, `layerNames()`.
- **Variants:** `nestVariant(s, v)` substitutes the rule's selector into `v.selector`'s `&` and
  prepends `v.atRule` (unless `""`); blocks pass through untouched. The outer modifier is outermost
  (`Hover([Before(…)])` → `&:hover::before`). `markImportant(s)` sets `important` on every rule;
  rendering appends `!important` per declaration.
- **Codec:** `encodeSheet`/`decodeSheet` — records tagged `R`/`B` joined by `\n`, fields by `\t`,
  `atRules` by `\r`; `carriesSeparator` is the check the codec rests on, asserted over every walked
  leaf of every front.
- **Host cell:** `register(name, payload)` stores; `drainRules()` returns `name\tpayload` records in
  insertion order and clears — both templates assemble nothing (no `<style>`, no braces).
- **Options:** `defaultOptions()` = `Options(theme: defaultTheme(), base: [], prefix: "", important:
  false, layers: true)` and `withTheme`/`withBase`/`withPrefix`/`withImportant`/`withLayers`. Preflight
  is opt-in (`withBase`), a deliberate inversion of Tailwind's default. The prefix is a plain
  concatenation — class names are hashes over `[a-z0-9_]`, so there is nothing to escape.
- **Render:** `renderRule(className, r, o)` writes `.<prefix><class>` for `&` (a literal selector
  ignores the prefix) inside the rule's at-rules; `renderDocument(raw, o)` emits, in order:
  1. `@layer theme, base, components, utilities;` (absent entirely when `layers` is off);
  2. `theme` — `themeCss(o.theme)` as a `:root` rule;
  3. `base` — `o.base` (front 55's reset when opted in);
  4. `components` — front 59's named classes;
  5. `utilities` — classes in registration order, tokens in list order, unconditioned rules before
     at-rule rules within one class;
  6. `@keyframes` blocks, outside every layer, deduplicated by header.
- **Entry points** (`emilia.bp`): `styleRule(tokens, th) -> #(className, encodedSheet)` (pure, registers
  nothing — onze front 68's build-time `styleMap`), `emiliaWith(tokens, th)` (styleRule + register),
  `emilia(tokens)` = `emiliaWith(tokens, defaultTheme())`, `flushWith(o) -> @Task<string>`,
  `flush()` = `flushWith(fullOptions())`.
- **`fullTheme()` / `fullOptions()`** (decision 80): `defaultTheme()` extended by every contributing
  front's entries, one line per front in front-number order — 33 `paletteEntries`, 38
  `typographyEntries`, 41 `effectEntries`, 42 `filterEntries`, 44 `transitionEntries`, 45
  `transformEntries`. `defaultOptions()` cannot carry it (`output.bp` cannot import `emilia.bp`), so
  `fullOptions()` is the carrier `flush()` renders with.
- **Shared dispatcher:** `tokenToSheet(t, th) -> Sheet`, one line per section. A section dispatcher
  returns a declaration string adapted by `declSheet(…)`; a section that needs a selector (`space-*`,
  `divide-*`, rings) returns a `Sheet` itself.
- **Conflicts (`§ 3.1`):** the last rule wins — inside one `emilia()` call that is token-list order,
  across calls registration order; a variant of a rule follows the rule it varies.
- **Class name and contract 4:** `"e_" + hex(encodeSheet(tokensToSheet(tokens, th)))` — a pure
  function of the token list *and the theme*; token order is class identity; ASCII-only.

## Acceptance

### Delivered

- [x] `declSheet("color:red")` is one `utilities` rule, no at-rules, selector `&`, not important;
      `declSheet("")` is empty; `mergeSheet` is associative on rendered output.
- [x] `nestVariant`: a selector-only variant rewrites the selector; hover-outside-before is
      `&:hover::before` and the reverse `&::before:hover`, both pinned; a breakpoint prepends its
      at-rule; a selector with zero or two `&` fails naming it; blocks are byte-identical.
- [x] `markImportant(declSheet("color:red;font-weight:700"))` renders
      `color:red!important;font-weight:700!important`; on an empty sheet it is a no-op.
- [x] The codec round-trips two at-rules, a non-`&` selector, an important rule and a block; the empty
      sheet encodes to `""` and back; no walked leaf of any front carries `\n`, `\t` or `\r`.
- [x] `drainRules()` is `""` when nothing was registered; a second drain is `""`; payloads come back
      verbatim in insertion order, byte-identical on both targets; neither template assembles.
- [x] `renderRule`: `.e_1{color:red}`; with prefix `tw_` `.tw_e_1{color:red}`; one and two at-rules
      nest outermost-first; a literal `html` selector renders literally and ignores the prefix.
- [x] `renderDocument` opens with the `@layer` statement when layers are on and carries no `@layer`
      token when off; a keyframes block appears once however many classes registered it.
- [x] `emilia(tokens)` returns `"e_" + hex` and collapses identical lists to one class;
      `styleRule(tokens, th)._0 == emiliaWith(tokens, th)` and registers nothing.
- [x] Two consecutive flushes give two independent documents; the second has no `utilities` body.
- [x] Every modifier test names the `§ 3.2` row its selector comes from; a rule precedes its variant.
- [x] `[.Layout.Grid, .Layout.Flex]` renders `display:grid;display:flex` (citing `§ 3.1`'s
      `grid flex`); two calls setting one property render in call order; reordering an unrelated
      token moves no other rule.

### Open

- [ ] `grep -n "hashHex" repository/emilia/modules/emilia/src` is empty; the class name is computed
      with std's content hash (`hash.contentHash`), and the contract-4 fixture's hex is unchanged by
      the switch (decision 116) — `emilia.bp` still declares its own `hashHex` host cell (byte-identical
      templates); the switch is one std import line in `emilia.bp`, landing with or after
      `00 · 23-std-purity`.

## Constraints

| Constraint | Consequence |
|---|---|
| A cross-module bare import of an `#[@External.…]` declaration is `undefined` at run time | the cells stay in `emilia.bp`; `output.bp` is pure |
| No module-level mutable state | the host cell is the accumulator; a `Sheet` is encoded into it |
| Records are immutable | `nestVariant`, `markImportant` and every `with…` return new values |

A `Variant` with the wrong number of `&` and a declaration containing a codec separator are build
failures, not values a test can read; they are recorded as notes beside the tests.

## Examples

- [`./examples/cascade-example.bp`](./examples/cascade-example.bp) — one card whose hover is a sibling
  rule, whose breakpoint is a hoisted `@media`, with a reset supplied through `Options` and a layered
  document a project's own CSS could deliberately beat.
