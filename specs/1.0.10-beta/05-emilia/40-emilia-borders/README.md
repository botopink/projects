# Front 40 — emilia-borders

**Track:** D emilia
**Priority:** high — `Border` has four widths, four radii and two colour families. Per-side widths, per-corner radii, border styles, outlines, rings and divided lists all have no token, and three of those five are how a real component shows focus, separation and state.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 3
**Depends on:** 33 (`Border.Color`, `Outline.Color`, `Ring.Color` and `Divide.Color` all go through `paletteVar`), 54 (the `Theme` parameter and the `--radius-*` ladder), 56 (`Divide` needs a sibling selector, and `Ring` needs shadow composition — neither is expressible as a bare declaration)
**Owns:** `repository/emilia/src/tokens.bp` (the `Border` section and the new `Outline`, `Ring` and `Divide` sections) · `repository/emilia/src/emilia.bp` (`borderTokenToCss` and its sub-dispatchers, `outlineTokenToCss`, `ringTokenToSheet`, `divideTokenToSheet`) · `repository/emilia/test/borders_test.bp`
**Does not touch:** the colour grid itself (front 33); `Effect.Shadow` (front 41) — `Ring` composes with it and does not own it
**Reference:** `TAILWIND_CSS_DOCS.md § 11. Bordas` (11.1–11.8), `§ 21.5 Border Radius Padrão` · https://tailwindcss.com/docs/border-radius

---

## Problem

`Border` (`tokens.bp:220-246`) has three sub-sections. `W` carries four widths and only the
shorthand — no `border-t`, no `border-x`, no logical `border-s`. `Color` carries two families of
three shades against front 33's twenty-six of eleven, and its dispatcher
(`emilia.bp:337-344`) discards the shade: `Red(_inner) -> "border-color:red"`. `Rounded` carries
four of the nine radii `§ 21.5` lists and has no per-corner or per-side form, so a card with a
rounded top and a square bottom cannot be described.

`border-style` has no token at all, which means a dashed or dotted border is inexpressible.

Three whole families are missing. `outline-*` is how Tailwind draws a focus ring that does not move
layout — `§ 11.5`–`§ 11.8` — and none of its four properties has a token. `ring-*` is the other
half of that story. `divide-*` is how a list separates its rows without a border on every child.

## Current state

| What | Where | State |
|---|---|---|
| `Border.W { 0, 1, 2, 4 }` | `tokens.bp:221-226` | shorthand only; `§ 11.2` also has `8` and eight per-side forms |
| `Border.Color { Red{100,500,700}, Gray{100,500,700}, Hex(value) }` | `tokens.bp:227-239` | 2 families; `Hex` is unconstructible |
| `Border.Rounded { Sm, Md, Lg, Full }` | `tokens.bp:240-245` | 4 of 9 radii, no corners |
| `borderWidthToCss` | `emilia.bp:327-335` | correct `px` values |
| `borderColorToCss` | `emilia.bp:337-344` | discards the shade — `border-color:red` |
| `borderRoundedToCss` | `emilia.bp:346-354` | literal `rem`; `§ 11.1` emits `var(--radius-*)` |
| `border-style` | — | no token |
| `Outline`, `Ring`, `Divide` | — | no sections |

## Mechanism

`Border` gains the per-side and per-corner dimensions Tailwind has and emilia does not, plus a
`Style` sub-section. Three new top-level sections carry the three missing families.

Two of the four families cannot be a bare declaration, and that is why this front depends on
front 56:

- **`Divide`** styles the element's *children*, not the element: `divide-y-2` puts a border on every
  child but the last. Its dispatcher is therefore `divideTokenToSheet(t, th) -> Sheet`, the
  second shape [front 56's README](../56-emilia-cascade-and-output/README.md) defines for exactly
  this case, returning a `Rule` whose `selector` is a sibling template rather than the bare `"&"`.
- **`Ring`** is a box-shadow, not a border: it composes with `Effect.Shadow` (front 41) through the
  same `--tw-shadow` / `--tw-ring-shadow` custom properties rather than overwriting it. That
  composition is a `Rule` with several declarations and an ordering constraint, which is again
  front 56's model. `ringTokenToSheet` is this front's second `…ToSheet` dispatcher.

`Border`, `Border.Style`, `Border.Rounded` and `Outline` are ordinary declarations and keep the
`(t, th: Theme) -> string` shape that front 56's `declSheet` adapts.

Every colour sub-section — `Border.Color`, `Outline.Color`, `Ring.Color`, `Divide.Color` — calls
front 33's `paletteVar`. Four colour tables would be four chances to drift.

Radii come from the theme: `§ 11.1` emits `border-radius: var(--radius-sm)` and `§ 21.5` lists the
eight `--radius-*` values, so the radius half of this front is fully specifiable from the reference.

## Token surface

### Border width — `§ 11.2`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `border` | `.Border.W.1` | `border-width:1px` |
| `border-0` | `.Border.W.0` | `border-width:0px` |
| `border-2` | `.Border.W.2` | `border-width:2px` |
| `border-4` | `.Border.W.4` | `border-width:4px` |
| `border-8` | `.Border.W.8` | `border-width:8px` |
| `border-x` | `.Border.W.X.1` | `border-left-width:1px;border-right-width:1px` |
| `border-y` | `.Border.W.Y.1` | `border-top-width:1px;border-bottom-width:1px` |
| `border-t` | `.Border.W.T.1` | `border-top-width:1px` |
| `border-t-4` | `.Border.W.T.4` | `border-top-width:4px` |
| `border-r` | `.Border.W.R.1` | `border-right-width:1px` |
| `border-b` | `.Border.W.B.1` | `border-bottom-width:1px` |
| `border-l` | `.Border.W.L.1` | `border-left-width:1px` |
| `border-s` | `.Border.W.S.1` | `border-inline-start-width:1px` |
| `border-e` | `.Border.W.E.1` | `border-inline-end-width:1px` |

`.Border.W.{0,1,2,4}` keeps its current spelling and its current output; `8` and the eight
directional sub-sections are new. Tailwind's bare `border` is `border-width: 1px`, so `.Border.W.1`
is its token and there is no separate default leaf.

### Border style and colour — `§ 11.3`, `§ 11.4`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `border-solid` | `.Border.Style.Solid` | `border-style:solid` |
| `border-dashed` | `.Border.Style.Dashed` | `border-style:dashed` |
| `border-dotted` | `.Border.Style.Dotted` | `border-style:dotted` |
| `border-double` | `.Border.Style.Double` | `border-style:double` |
| `border-hidden` | `.Border.Style.Hidden` | `border-style:hidden` |
| `border-none` | `.Border.Style.None` | `border-style:none` |
| `border-red-500` | `.Border.Color.Red.500` | `border-color:var(--color-red-500)` |
| `border-slate-200` | `.Border.Color.Slate.200` | `border-color:var(--color-slate-200)` |
| `border-white` | `.Border.Color.White` | `border-color:var(--color-white)` |
| `border-transparent` | `.Border.Color.Transparent` | `border-color:transparent` |
| `border-current` | `.Border.Color.Current` | `border-color:currentColor` |

All twenty-six families and eleven shades, from front 33's grid.

### Border radius — `§ 11.1`, `§ 21.5`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `rounded-none` | `.Border.Rounded.None` | `border-radius:0` |
| `rounded-xs` | `.Border.Rounded.Xs` | `border-radius:var(--radius-xs)` |
| `rounded-sm` | `.Border.Rounded.Sm` | `border-radius:var(--radius-sm)` |
| `rounded-md` | `.Border.Rounded.Md` | `border-radius:var(--radius-md)` |
| `rounded-lg` | `.Border.Rounded.Lg` | `border-radius:var(--radius-lg)` |
| `rounded-xl` | `.Border.Rounded.Xl` | `border-radius:var(--radius-xl)` |
| `rounded-2xl` | `.Border.Rounded.X2xl` | `border-radius:var(--radius-2xl)` |
| `rounded-3xl` | `.Border.Rounded.X3xl` | `border-radius:var(--radius-3xl)` |
| `rounded-4xl` | `.Border.Rounded.X4xl` | `border-radius:var(--radius-4xl)` |
| `rounded-full` | `.Border.Rounded.Full` | `border-radius:9999px` |
| `rounded-t-lg` | `.Border.Rounded.T.Lg` | `border-top-left-radius:var(--radius-lg);border-top-right-radius:var(--radius-lg)` |
| `rounded-r-lg` | `.Border.Rounded.R.Lg` | `border-top-right-radius:var(--radius-lg);border-bottom-right-radius:var(--radius-lg)` |
| `rounded-b-lg` | `.Border.Rounded.B.Lg` | `border-bottom-right-radius:var(--radius-lg);border-bottom-left-radius:var(--radius-lg)` |
| `rounded-l-lg` | `.Border.Rounded.L.Lg` | `border-top-left-radius:var(--radius-lg);border-bottom-left-radius:var(--radius-lg)` |
| `rounded-tl-lg` | `.Border.Rounded.Tl.Lg` | `border-top-left-radius:var(--radius-lg)` |
| `rounded-tr-lg` | `.Border.Rounded.Tr.Lg` | `border-top-right-radius:var(--radius-lg)` |
| `rounded-br-lg` | `.Border.Rounded.Br.Lg` | `border-bottom-right-radius:var(--radius-lg)` |
| `rounded-bl-lg` | `.Border.Rounded.Bl.Lg` | `border-bottom-left-radius:var(--radius-lg)` |
| `rounded-s-lg` | `.Border.Rounded.S.Lg` | `border-start-start-radius:var(--radius-lg);border-end-start-radius:var(--radius-lg)` |
| `rounded-e-lg` | `.Border.Rounded.E.Lg` | `border-start-end-radius:var(--radius-lg);border-end-end-radius:var(--radius-lg)` |
| `rounded-ss-lg` | `.Border.Rounded.Ss.Lg` | `border-start-start-radius:var(--radius-lg)` |
| `rounded-se-lg` | `.Border.Rounded.Se.Lg` | `border-start-end-radius:var(--radius-lg)` |
| `rounded-es-lg` | `.Border.Rounded.Es.Lg` | `border-end-start-radius:var(--radius-lg)` |
| `rounded-ee-lg` | `.Border.Rounded.Ee.Lg` | `border-end-end-radius:var(--radius-lg)` |

Each of the fourteen directional sub-sections carries the full ten-leaf radius ladder, so
`.Border.Rounded.Tl.Full` is a path as much as `.Border.Rounded.Tl.Lg` is.

The existing `.Border.Rounded.{Sm,Md,Lg,Full}` paths keep working. `Sm`, `Md` and `Lg` change what
they emit — from a literal `rem` to `var(--radius-*)` — and `Full` does not, because `§ 11.1` prints
`rounded-full` as the literal `9999px`. The assertion at `emilia.bp:427-429` (`Border.Rounded.Full`)
is therefore **not** affected; no existing assertion covers `Sm`, `Md` or `Lg`.

The eight logical corner forms (`s`, `e`, `ss`, `se`, `es`, `ee`) are not in the local reference —
see *Reference gaps*.

### Outline — `§ 11.5`–`§ 11.8`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `outline-0` | `.Outline.W.0` | `outline-width:0px` |
| `outline-1` | `.Outline.W.1` | `outline-width:1px` |
| `outline-2` | `.Outline.W.2` | `outline-width:2px` |
| `outline-4` | `.Outline.W.4` | `outline-width:4px` |
| `outline-8` | `.Outline.W.8` | `outline-width:8px` |
| `outline` | `.Outline.Style.Solid` | `outline-style:solid` |
| `outline-dashed` | `.Outline.Style.Dashed` | `outline-style:dashed` |
| `outline-dotted` | `.Outline.Style.Dotted` | `outline-style:dotted` |
| `outline-double` | `.Outline.Style.Double` | `outline-style:double` |
| `outline-none` | `.Outline.Style.None` | `outline:2px solid transparent;outline-offset:2px` |
| `outline-blue-500` | `.Outline.Color.Blue.500` | `outline-color:var(--color-blue-500)` |
| `outline-offset-0` | `.Outline.Offset.0` | `outline-offset:0px` |
| `outline-offset-1` | `.Outline.Offset.1` | `outline-offset:1px` |
| `outline-offset-2` | `.Outline.Offset.2` | `outline-offset:2px` |
| `outline-offset-4` | `.Outline.Offset.4` | `outline-offset:4px` |
| `outline-offset-8` | `.Outline.Offset.8` | `outline-offset:8px` |
| `-outline-offset-1` | `.Outline.Offset.Neg.1` | `outline-offset:-1px` |

`outline-none` is the trap in this table: `§ 11.7` prints it as two declarations of the shorthand
and an offset, **not** as `outline-style: none`. It is transparent rather than absent, so a
high-contrast mode still shows it. The token is under `Style` because that is where Tailwind puts
it, and the dispatcher emits the two-declaration form.

### Ring and divide

Neither family is in the local reference. Everything below is specified from upstream and must be
verified before implementation — see *Reference gaps*.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `ring` | `.Ring.W.1` | `--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow)` |
| `ring-0` | `.Ring.W.0` | the same with `0px` |
| `ring-2` | `.Ring.W.2` | the same with `2px` |
| `ring-4` | `.Ring.W.4` | the same with `4px` |
| `ring-8` | `.Ring.W.8` | the same with `8px` |
| `ring-indigo-500` | `.Ring.Color.Indigo.500` | `--tw-ring-color:var(--color-indigo-500)` |
| `ring-offset-2` | `.Ring.Offset.W.2` | `--tw-ring-offset-width:2px` |
| `ring-offset-white` | `.Ring.Offset.Color.White` | `--tw-ring-offset-color:var(--color-white)` |
| `ring-inset` | `.Ring.Inset` | `--tw-ring-inset:inset` |
| `divide-x` | `.Divide.X.1` | `& > :not(:last-child){border-inline-start-width:0px;border-inline-end-width:1px}` |
| `divide-x-2` | `.Divide.X.2` | `& > :not(:last-child){border-inline-start-width:0px;border-inline-end-width:2px}` |
| `divide-y` | `.Divide.Y.1` | `& > :not(:last-child){border-top-width:0px;border-bottom-width:1px}` |
| `divide-y-2` | `.Divide.Y.2` | `& > :not(:last-child){border-top-width:0px;border-bottom-width:2px}` |
| `divide-slate-200` | `.Divide.Color.Slate.200` | `& > :not(:last-child){border-color:var(--color-slate-200)}` |
| `divide-dashed` | `.Divide.Style.Dashed` | `& > :not(:last-child){border-style:dashed}` |
| `divide-x-reverse` | `.Divide.XReverse` | `& > :not(:last-child){--tw-divide-x-reverse:1}` |
| `divide-y-reverse` | `.Divide.YReverse` | `& > :not(:last-child){--tw-divide-y-reverse:1}` |

## Steps

### Step 1 — border width, style and colour

Eight directional sub-sections under `W`, a new `Style` sub-section, and `Color` widened to front
33's grid.

**Acceptance:**
- [ ] `.Border.W.{0,1,2,4}` emit exactly what they emit today
- [ ] `.Border.W.8` exists; every directional sub-section answers all five widths
- [ ] `.Border.W.X.1` emits two declarations; `.Border.W.T.1` emits one
- [ ] `.Border.W.S.1` emits `border-inline-start-width`
- [ ] six border styles
- [ ] `.Border.Color.Slate.200` emits `border-color:var(--color-slate-200)` — the shade is no longer
      discarded, which is a change to what `.Border.Color.Red.500` emits today
- [ ] `Border.Color` is produced by front 33's `paletteVar`; this front holds no colour table
- [ ] `.Border.Color.Hex(value)`'s arm is retained unchanged, and the README records that it is
      unconstructible (see [`language-gaps.md`](../../language-gaps.md))

### Step 2 — border radius

Ten radius leaves on the shorthand and on each of the fourteen directional sub-sections.

**Acceptance:**
- [ ] ten leaves: `None`, `Xs`, `Sm`, `Md`, `Lg`, `Xl`, `X2xl`, `X3xl`, `X4xl`, `Full`
- [ ] `.Border.Rounded.Full` still emits `border-radius:9999px` and `emilia.bp:427-429` passes untouched
- [ ] `.Border.Rounded.Lg` emits `border-radius:var(--radius-lg)`, not `border-radius:0.5rem`
- [ ] the eight `--radius-*` values of `§ 21.5` are in front 54's theme layer
- [ ] a side form emits two corner properties, a corner form emits one
- [ ] `.Border.Rounded.Tl.Full` resolves — every directional sub-section carries the full ladder

### Step 3 — outline

Four sub-sections: `W`, `Style`, `Color`, `Offset` (with a `Neg`).

**Acceptance:**
- [ ] five widths, four styles plus the `outline-none` special case
- [ ] `.Outline.Style.None` emits `outline:2px solid transparent;outline-offset:2px` — two
      declarations, and never `outline-style:none`
- [ ] `Outline.Color` goes through `paletteVar`
- [ ] five offsets plus four negative offsets, emitting `-1px` and so on
- [ ] a focus ring built from `Token.FocusVisible([.Outline.W.2, .Outline.Color.Indigo.500])`
      composes correctly with front 34's modifier

### Step 4 — ring, as a `Sheet`

`ringTokenToSheet(t, th) -> Sheet`. A ring is a box-shadow that must not clobber `Effect.Shadow`
(front 41), so the two compose through `--tw-shadow` and `--tw-ring-shadow`, and the `box-shadow`
declaration lists both.

**Acceptance:**
- [ ] `.Ring.W.2` emits both the `--tw-ring-shadow` custom property and the composed `box-shadow`
- [ ] a `Ring` token and an `Effect.Shadow` token in the same list produce one `box-shadow`
      declaration that references both, not two competing ones — asserted directly
- [ ] `.Ring.Inset` sets `--tw-ring-inset`
- [ ] `Ring.Color` and `Ring.Offset.Color` go through `paletteVar`
- [ ] the dispatcher is a `…ToSheet`, per front 56's second shape, and says so in its own header
- [ ] every custom-property name is verified against upstream before merge

### Step 5 — divide, as a `Sheet`

`divideTokenToSheet(t, th) -> Sheet`, returning a `Rule` whose `selector` is the sibling template.
Both the selector and the reversed-order custom properties are unverified — see *Reference gaps*.

**Acceptance:**
- [ ] `.Divide.Y.2` emits a rule whose selector is the sibling template and whose declarations are
      the two border widths
- [ ] `.Divide.Color.Slate.200` and `.Divide.Style.Dashed` target the same selector, so a width, a
      colour and a style compose into one child rule rather than three
- [ ] the selector is spelled in exactly one place in this front
- [ ] `Divide` and front 35's `Space` use the same child selector, asserted by comparing the two
      outputs — two fronts writing two different sibling selectors would be a silent inconsistency
- [ ] the selector is verified against upstream before merge

### Step 6 — the dispatchers and the top-level arms

`borderTokenToCss` is widened; `outlineTokenToCss` is new; `ringTokenToSheet` and
`divideTokenToSheet` are the two `Sheet`-returning dispatchers. Three arms are added to the
top-level case (`Outline`, `Ring`, `Divide`); `Border` already has one.

**Acceptance:**
- [ ] every arm is an arrow arm and each dispatcher follows the `val out = case …; return out;` idiom
- [ ] the two `…ToSheet` dispatchers are the only two in this front, and both are named in the
      front's README and in `AGENTS.md`
- [ ] the banner `// ── front 40 — borders, outlines, rings and divides ──` fences the block in both files
- [ ] three arms added to the top-level dispatcher, in front-number order
- [ ] nothing in this front contradicts contract 4 in [`contracts.md`](../../contracts.md): the class
      name stays a pure function of the token list, and token order stays class identity — which the
      `Ring`/`Effect.Shadow` composition test exercises directly, since swapping the two changes the
      emitted `box-shadow`

## Examples

- `./examples/borders-example.bp` — width per side, style, colour and the whole radius family
  including corners; ends with a table-like card with a rounded top, a square bottom and a dashed
  internal rule.
- `./examples/outline-ring-example.bp` — outline, its `none` special case, ring, ring offset, ring
  inset and the divide family; ends with a form control whose focus ring is an outline and a
  segmented list separated by `divide-y`.

## Language gaps

None new. `Border.Color.Hex(value: string)` is declared in `tokens.bp:238` and matched in
`emilia.bp:341`, and no caller can construct it — a payload leaf nested inside a section has no
constructible spelling. That gap is recorded once in [`language-gaps.md`](../../language-gaps.md) and
this front neither works around it nor builds on it: the escape hatch belongs to front 57, and it
has to be a **top-level** `Token` variant to be constructible.

## Reference gaps

`TAILWIND_CSS_DOCS.md` carries `§ 11` for border and outline and nothing at all for ring and divide.
The `## Reference gaps` rows below are utilities this front specifies **from upstream**, not from
the local doc, and each one must be checked before implementation.

| Item | Why it is missing | What implementation must do |
|---|---|---|
| The whole `ring-*` family | absent from `TAILWIND_CSS_DOCS.md` — not in `§ 11`, not in `§ 12`, not in the *Referência Rápida* under Borders or Effects | verify `--tw-ring-shadow`, `--tw-ring-color`, `--tw-ring-offset-width`, `--tw-ring-offset-color`, `--tw-ring-inset` and the composed `box-shadow` list against `tailwindcss.com/docs/box-shadow#adding-a-ring`. The default ring width in v4 differs from v3 and must be read, not remembered |
| The whole `divide-*` family | likewise absent | verify the child selector and the reversed-order custom properties against `tailwindcss.com/docs/border-width#divide` |
| The `divide` child selector | — | front 35's `Space` family has the same problem and this spec proposes the same `& > :not(:last-child)` for both. Whatever upstream turns out to use, **the two fronts must agree**, and a test asserts it |
| The eight logical radius corners (`rounded-s`, `-e`, `-ss`, `-se`, `-es`, `-ee`) | `§ 11.1` prints the four sides and four physical corners only | verify the `border-start-start-radius` family against upstream |
| `rounded-xs` and `rounded-4xl` | `§ 11.1` prints `rounded-sm` through `rounded-3xl`; `§ 21.5` lists `--radius-xs` through `--radius-4xl` | the two tables disagree on the extent; `§ 21.5` is the longer list and this front follows it |
| `border-x-2`, `border-t-4` and every directional width other than `1px` | `§ 11.2` prints the directional forms at their default width only | the pattern is unambiguous; the extent is not documented locally |
| `outline-hidden` | absent | not declared by this front |

## Test plan

`repository/emilia/test/borders_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`. The two `…ToSheet` dispatchers make this the front where a
target divergence is most likely, because a `Sheet` crosses the host cell as an encoded string —
front 56's encoding test covers the codec, and this front's tests cover the two producers.

What the tests assert:

1. **Width** — the four existing leaves unchanged, `8`, and one test per directional sub-section
   with the two-declaration axis forms checked explicitly.
2. **Style** — six asserts.
3. **Colour** — a family/shade sample on each of the four colour sub-sections, plus one assert that
   all four produce the same `var(--color-*)` text for the same family and shade.
4. **Radius** — ten leaves on the shorthand; one test per directional form; an explicit regression
   that `Full` is still `9999px` and `Lg` is now a variable.
5. **`outline-none`** — its own test, asserting the two-declaration form and the absence of
   `outline-style:none`.
6. **Ring** — the composed `box-shadow`, the offset, the inset, and the `Ring` + `Effect.Shadow`
   composition, asserted both ways round so the order-sensitivity in contract 4 is exercised.
7. **Divide** — the sibling rule, the composition of width, colour and style into one child rule,
   and the cross-front assert that `Divide` and `Space` use the same selector.
8. **End to end** — `emilia([.Border.W.1, .Border.Color.Slate.200, .Border.Rounded.T.Lg])` then
   `await flush()`, asserting the whole `<style>` block.

## Definition of done

- [ ] every utility in `§ 11.1`–`§ 11.8` has a token
- [ ] `ring-*` and `divide-*` have tokens, and every value they emit is verified against upstream
      and recorded in *Reference gaps* until it is
- [ ] the four colour sub-sections call front 33's `paletteVar`; this front holds no colour table
- [ ] `Divide` and front 35's `Space` share one child selector, asserted by a test
- [ ] `Ring` composes with `Effect.Shadow` rather than overwriting it
- [ ] the banner fences this front's block in both files, appended at the end
- [ ] three arms added to the top-level dispatcher, in front-number order
- [ ] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new sections and
      the two `…ToSheet` dispatchers
- [ ] the front's tests are green on its assigned target — here, both backends, since emilia is comptime
