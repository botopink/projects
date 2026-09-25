# Front 47 — emilia SVG and accessibility

**Track:** D emilia
**Priority:** low — five CSS properties, and one of them (`sr-only`) is the difference between a screen reader announcing an icon button and announcing nothing
**Target:** comptime
**Wave:** 3
**Depends on:** 33 (the palette — `fill` and `stroke` take colours, and this front takes them as payloads rather than duplicating front 33's families)
**Owns:** token sections `Svg`, `A11y` in `repository/emilia/src/tokens.bp` · dispatchers `svgTokenToCss` and `a11yTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/svg_a11y_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, the class-name hash (std `content_hash.contentHash` since decision 116), `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 18. SVG` and `§ 19. Acessibilidade` · https://tailwindcss.com/docs/fill · https://tailwindcss.com/docs/screen-readers

---

## Problem

`emilia` has no way to colour an SVG and no way to hide text visually while leaving it in the
accessibility tree. `repository/emilia/src/tokens.bp:36-270` covers `color` and `background` and
stops there — an inline icon inherits nothing, because `fill` and `stroke` are separate properties
and `.Color.Blue.500` sets neither.

The accessibility half is the part that matters more than its priority suggests. An icon-only button
— a close X, a search magnifier, a kebab menu — is the most common control on a modern page and it
is also the most common accessibility defect, because the label that makes it announceable has to be
present in the DOM and absent from the layout. `sr-only` is the one-class answer and `emilia` cannot
express it, so today the choice is a visible duplicate label or no label at all.

This is the smallest front in track D after 43, and it has the reference-quality problem the rest do
not: `§ 18` and `§ 19.2` give class names and HTML examples and **no property/value table at all**.
Four of this front's twelve rows therefore cannot be transcribed, only derived — and one of them
cannot even be derived. That is stated openly below and gated in Step 3, rather than filled in from
memory.

## Current state

- No `Svg`, no `A11y`, and no `fill`, `stroke`, `stroke-width`, `sr-only` or `forced-color-adjust`
  string anywhere in `repository/emilia/src/`.
- `Color.Hex(value: string)` — `tokens.bp:115` — is the working precedent for a leaf carrying a
  colour as a string, which is how this front takes `fill` and `stroke` without reaching into front
  33's palette.
- `register(name, body)` renders `.<name>{<body>}` — `emilia.bp:23-30`. A multi-declaration body
  joined by `;` drops in unchanged, which is what `sr-only` needs.
- `tokensToCss` joins tokens with `;` — `emilia.bp:103`.

## Mechanism

Two top-level sections and two dispatchers, per the ownership table. `Svg` holds `fill`, `stroke`
and `stroke-width`; `A11y` holds `sr-only`, `not-sr-only` and `forced-color-adjust`.

**How the values are obtained, one case at a time.** This is the front where "take the value from
the reference" does not resolve every row, so the derivation is spelled out per row rather than
assumed:

| Rows | Source | Confidence |
|---|---|---|
| `forced-color-adjust-auto` / `-none` | `§ 19.1` gives a property/value table | transcribed |
| `fill-none`, `stroke-none` | Property from the `§ 18.1` / `§ 18.2` heading; value is the class suffix `none`, which is a legal value for both properties | derived, mechanical |
| `fill-current`, `stroke-current` | Property from the heading; value is `currentcolor`, which is what the suffix `current` abbreviates and the only CSS value it can mean | derived, one step |
| `fill-red-500`, `stroke-blue-500` | Property from the heading; value is a palette colour owned by front 33, taken here as a payload | derived, mechanical |
| `stroke-1`, `stroke-2`, `stroke-[3]` | Property from the `§ 18.3` heading; value is the class suffix, unitless, which is what `stroke-width` takes | derived, mechanical |
| `sr-only`, `not-sr-only` | **Nothing.** `§ 19.2` gives two HTML examples and one comment in Portuguese. There is no property, no value, and no count of declarations | **not derivable — gated** |

The last row is the reason Step 3 exists as its own step with an explicit gate. `sr-only` is a
seven-declaration block upstream and writing it from memory is exactly what this milestone forbids.
The front ships the token with its body confirmed against the upstream page and recorded in the
front's `TODO.md` before it lands; until that happens the token is declared and its dispatcher arm
is the only line in this front that a reviewer must check against something other than the reference
file.

**Colours are top-level payload variants, and their values come from front 33.** Same reasoning as
front 46, and the same two compiler facts. A payload leaf nested inside an enum section cannot be
constructed by any spelling (`language-gaps.md` row 52), so `Svg.Fill.Color` does not exist;
contract `§ 4a` names these at the **top level** of `Token` as `Token.SvgFill(value: string)` and
`Token.SvgStroke(value: string)`. Their fields are `string` rather than a colour section type,
because a section-typed value cannot be constructed standalone either (row 53). The **value** is
front 33's `paletteVar(family, shade)` → `var(--color-red-500)`, never a hex, so `fill-red-500` and
`bg-red-500` read one theme entry and cannot drift. `Token.SvgStrokeWidthRaw(value: string)` moves
to the top level for the same reason.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`).

**Dispatcher shape.** Per contract `§ 4a`:

```bp
fn svgTokenToCss(t: Token.Svg, th: Theme) -> string
fn a11yTokenToCss(t: Token.A11y, th: Theme) -> string
```

Both keep the declaration-string form. I checked `sr-only` against the `…TokenToSheet(t, th) -> Sheet`
question the contract raises: `sr-only` is a multi-declaration body on the element's **own** class —
position, size, clip, overflow, whitespace — and needs no selector outside it, unlike `space-*` or
`divide-*`, which target children. So it is a `;`-joined declaration string and `a11yTokenToCss`
stays in the ordinary form.

## Steps

### Step 1 — `fill` and `stroke`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `fill-current` | `.Svg.Fill.Current` | `fill:currentcolor` |
| `fill-none` | `.Svg.Fill.None` | `fill:none` |
| `fill-red-500` | `Token.SvgFill(value: v)` — **top-level**, `v` = `paletteVar("red", 500)` | `fill:var(--color-red-500)` |
| `stroke-current` | `.Svg.Stroke.Current` | `stroke:currentcolor` |
| `stroke-none` | `.Svg.Stroke.None` | `stroke:none` |
| `stroke-blue-500` | `Token.SvgStroke(value: v)` — **top-level**, `v` = `paletteVar("blue", 500)` | `stroke:var(--color-blue-500)` |

`fill:currentcolor` is written lowercase and as one word — that is the CSS keyword, and the two
tokens that use it are the only place this front writes a value the reference does not print.

**Acceptance:**
- [ ] `svgTokenToCss(.Fill.Current, th)` returns `fill:currentcolor`.
- [ ] `Token.SvgStroke(value: paletteVar("blue", 500))` **constructs** and its arm returns
      `stroke:var(--color-blue-500)` — construction is the check that would have failed against a
      nested `Svg.Stroke.Color`.
- [ ] No hex literal appears in any test or example of this front.
- [ ] No section in this front's `tokens.bp` block contains a payload leaf.
- [ ] `svgTokenToCss` and its sub-dispatchers are exhaustive with no `_` arm.
- [ ] The `tokens.bp` docblock records that `currentcolor` is derived from the class suffix, not
      transcribed.

### Step 2 — `stroke-width`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `stroke-0` | `.Svg.StrokeWidth.0` | `stroke-width:0` |
| `stroke-1` | `.Svg.StrokeWidth.1` | `stroke-width:1` |
| `stroke-2` | `.Svg.StrokeWidth.2` | `stroke-width:2` |
| `stroke-[3]` | `Token.SvgStrokeWidthRaw(value: v)` — **top-level** | `stroke-width:<v>` |

`§ 18.3` gives `stroke-1`, `stroke-2` and the arbitrary form `stroke-[3]`. `stroke-0` is the zero
step of the same scale and is included because a scale that starts at one has no way to say "no
stroke width", which is different from `stroke-none`.

The value is unitless — `stroke-width:2`, not `2px`. That is what `stroke-width` takes in the SVG
coordinate system and what the class suffix says.

**Acceptance:**
- [ ] `svgTokenToCss(.StrokeWidth.2, th)` returns `stroke-width:2`, with no unit.
- [ ] `Token.SvgStrokeWidthRaw(value: "3")` **constructs** and its arm returns `stroke-width:3`.
- [ ] `.Svg.StrokeWidth.0` and `.Svg.Stroke.None` are two different tokens emitting two different
      declarations, and a test asserts both so the distinction survives review.

### Step 3 — `sr-only` and `not-sr-only` — the gated pair

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `sr-only` | `.A11y.SrOnly` | **not in the reference — confirm against https://tailwindcss.com/docs/screen-readers before landing** |
| `not-sr-only` | `.A11y.NotSrOnly` | **not in the reference — confirm against the same page before landing** |

`§ 19.2` is two HTML snippets and one comment. It does not say which properties `sr-only` sets, how
many declarations it is, or what `not-sr-only` restores them to. Every other row in every front I
own is copied from a table in the reference; these two cannot be, and writing them from memory is
what this milestone exists to stop.

What the front commits to instead:

- the two tokens are declared and their dispatcher arms exist;
- the body of each is taken from the upstream page named above, in one sitting, and pasted into
  `a11yTokenToCss` with a comment naming the URL and the date it was read;
- the front's `TODO.md` carries a checkbox for that reading, and the front does not land with it
  unticked;
- the test file asserts the body as a literal string, so a later edit that "tidies" it fails.

`sr-only` is a multi-declaration body, so it composes through `tokensToCss`'s `;` join like front
44's transition presets — no new machinery.

**Acceptance:**
- [ ] The upstream page has been read, the date recorded in the dispatcher comment, and the
      `TODO.md` checkbox ticked.
- [ ] `a11yTokenToCss(.SrOnly, th)` is asserted against a literal in the test file.
- [ ] `sr-only` is a `;`-joined declaration string on the element's own class, **not** a
      `…TokenToSheet` return: it needs no selector outside the class, which is the test contract
      `§ 4a` sets for that choice.
- [ ] `.A11y.NotSrOnly` restores every property `.A11y.SrOnly` sets — the two declaration lists name
      the same properties, checked by reading them side by side, and a test asserts both whole.

### Step 4 — `forced-color-adjust`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `forced-color-adjust-auto` | `.A11y.ForcedColorAdjust.Auto` | `forced-color-adjust:auto` |
| `forced-color-adjust-none` | `.A11y.ForcedColorAdjust.None` | `forced-color-adjust:none` |

The only rows in this front that `§ 19` gives as a table.

```bp
pub type Token {
    // ── front 47 · svg and accessibility ─────────────────────────────────
    Svg {
        Fill {
            Current,
            None,
        }
        Stroke {
            Current,
            None,
        }
        StrokeWidth {
            0,
            1,
            2,
        }
    }

    A11y {
        SrOnly,
        NotSrOnly,
        ForcedColorAdjust {
            Auto,
            None,
        }
    }

    // Payload-carrying variants are TOP-LEVEL, never section leaves — a payload
    // leaf inside a section cannot be constructed by any spelling
    // (`language-gaps.md` row 52, contract `§ 4a`). The colour values are front
    // 33's `paletteVar(family, shade)`, never a hex.
    SvgFill(value: string),
    SvgStroke(value: string),
    SvgStrokeWidthRaw(value: string),
}
```

**Acceptance:**
- [ ] `a11yTokenToCss(.ForcedColorAdjust.None, th)` returns `forced-color-adjust:none`.
- [ ] `a11yTokenToCss` is exhaustive over `SrOnly`, `NotSrOnly` and `ForcedColorAdjust`, with no `_`.

### Step 5 — five new arms in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, reached through `declSheet(...)`,
and each top-level payload variant needs its own arm.

```bp
        Svg(_inner) -> declSheet(svgTokenToCss(_inner, th));
        A11y(_inner) -> declSheet(a11yTokenToCss(_inner, th));
        SvgFill(value) -> declSheet("fill:" + value);
        SvgStroke(value) -> declSheet("stroke:" + value);
        SvgStrokeWidthRaw(value) -> declSheet("stroke-width:" + value);
```

**Acceptance:**
- [ ] The five arms sit after front 46's four and are the last section arms in the `case`, before
      the variant arms front 34 owns.
- [ ] Each arm is one `declSheet(...)` call; none builds a `Rule` or a `Sheet` by hand.
- [ ] Every payload arm destructures by its declared field name (`value`).
- [ ] `tokenToSheet` still has no `_` arm.

## Examples

- [`./examples/svg-a11y-example.bp`](./examples/svg-a11y-example.bp) — the `Svg` and `A11y`
  catalogues, the gated `sr-only` pair marked at its declaration site, then an icon-only close
  button whose visible glyph is a stroked SVG and whose label is `sr-only`.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's three payload variants, written `Svg.Fill.Color`, `Svg.Stroke.Color` and `Svg.StrokeWidth.Raw` in the first draft. They are the only way this front takes a colour | the variants move to the **top level** of `Token` per contract `§ 4a`: `Token.SvgFill(value: string)`, `Token.SvgStroke(value: string)`, `Token.SvgStrokeWidthRaw(value: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path |
| **A section-typed value cannot be constructed standalone** — `language-gaps.md` row 53 | the same three: their fields cannot be typed as a colour section | fields stay builtin-typed (`string`) and carry front 33's `paletteVar(family, shade)` result | dot-shorthand rooted at the parameter's declared section type |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same three, now top-level: `[.SvgFill(paletteVar("red", 500))]` still trips the parser | a wrapper fn returning the token (`fn fillColor(v: string) -> Token { return Token.SvgFill(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Could not map from the reference

| Item | Why |
|---|---|
| `sr-only`, `not-sr-only` bodies | `§ 19.2` gives two HTML examples and no CSS. The property list, the values and even the number of declarations are absent. Gated in Step 3: read from the upstream page, dated in the dispatcher comment, ticked in `TODO.md`, and asserted as a literal in the test file. |
| `fill-current` / `stroke-current` values | `§ 18` gives no property/value table for any row. `currentcolor` is the only CSS value the `current` suffix can abbreviate, so it is derived rather than transcribed — a one-step derivation, recorded as such in the `tokens.bp` docblock. |

## Reconciled with front 33

The first draft left the colour payload as an open question. Contract `§ 4a` closed it, identically
for this front and for front 46: `Token.SvgFill` and `Token.SvgStroke` keep `string` fields — a
section-typed field would not construct (`language-gaps.md` row 53) — and the **value** is always
front 33's `paletteVar(family, shade)`, which returns `var(--color-red-500)`. This front holds no
copy of the palette and cannot drift from it: `fill-red-500` and `bg-red-500` read one theme entry.
A hex literal anywhere in this front is a defect, and a test asserts their absence.

## Test plan

`repository/emilia/test/svg_a11y_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert svgTokenToCss(<token>, th) == "<css>"` or
   `a11yTokenToCss(<token>, th)` per row of the four tables — fourteen assertions, which is the whole
   front. The three top-level payload variants are asserted through their `tokenToSheet` arms, and a
   test constructs each one, which is the check that would have failed against the nested spelling.
2. **The two derived values.** `fill:currentcolor` and `stroke:currentcolor` asserted as literals
   with a comment saying they are derived from the class suffix, not transcribed, so a reviewer
   knows which line to doubt.
3. **`stroke-width` has no unit.** `stroke-width:2` asserted exactly, so a refactor that appends
   `px` to every numeric value fails here.
4. **`stroke-0` versus `stroke-none`.** Two tokens, two properties, asserted adjacently.
5. **The gated pair, asserted as literals.** `.A11y.SrOnly` and `.A11y.NotSrOnly` asserted against
   full strings, never `contains`, so the bodies are pinned the moment they are read from upstream
   and any later edit fails the test.
6. **The realistic composition.** The close-button example's token list —
   `[.Svg.Stroke.Current, .Svg.StrokeWidth.2, .Svg.Fill.None]` — round-trips through `emilia()` and
   `await flush()` to a literal `<style>` string, proving the three properties compose in list order.
7. **Variant nesting.** `Token.Hover([Token.SvgFill(value: paletteVar("red", 500))])` reaches front
   34's `nestVariant` with the inner declaration `fill:var(--color-red-500)` — the realistic use, an
   icon that changes colour under the pointer. This front asserts the declaration, not the wrap.
8. **No hex.** A test greps this front's block of `emilia.bp` and this front's tests for `#`
   followed by six hex digits and fails if it finds one: colours come from `paletteVar`.
9. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Svg` and `A11y` exist as top-level sections with **no payload leaf**, fenced by a `front 47`
      banner in `tokens.bp` and appended after front 46's block.
- [ ] `Token.SvgFill`, `Token.SvgStroke` and `Token.SvgStrokeWidthRaw` exist as top-level variants
      with `string` fields, in the same banner.
- [ ] `svgTokenToCss`, `a11yTokenToCss` and their sub-dispatchers are fenced by a `front 47` banner
      in `emilia.bp`, appended after front 46's block, and take `th: Theme` per contract `§ 4a`.
- [ ] Five arms added to `tokenToSheet`, each a `declSheet(...)` call, in front-number order, and no
      other line of that `case` moved.
- [ ] No hex literal appears in this front's block or tests.
- [ ] The `sr-only` gate is closed: upstream page read, date recorded in the dispatcher comment,
      `TODO.md` checkbox ticked, body asserted as a literal.
- [ ] The `currentcolor` derivation and the `paletteVar` rule are stated in the `tokens.bp`
      docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the two new sections and both notes.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
