# Front 40 — emilia borders, outlines, rings and divides

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 33 (`paletteVar`), 54 (`Theme`, `--radius-*`), 56 (`Sheet` for `Ring` and `Divide`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 40 — borders, outlines, rings
and divides` block: `Border`, `Outline`, `Ring`, `Divide`) · `src/emilia.bp` (front-40 block:
`borderTokenToCss` and sub-dispatchers, `outlineTokenToCss`, `ringTokenToSheet`, `divideTokenToSheet`;
the `Outline`/`Ring`/`Divide` arms of `tokenToSheet`)
**Does not own:** the colour grid (front 33); `Effect.Shadow` (front 41), which `Ring` composes with
**User docs:** `repository/emilia/docs.md` § *Border*, § *Outline*, § *Ring*, § *Divide*
**Reference:** `TAILWIND_CSS_DOCS.md § 11` (11.1–11.8), `§ 21.5` · https://tailwindcss.com/docs/border-radius

**Open:** none.

---

## What it delivers

`§ 11` plus the ring and divide families — **1704 leaves** (`Border` 492, `Outline` 310, `Ring` 593,
`Divide` 309). No leaf resolves a colour or a radius: every colour cell is `paletteVar`, every named
radius is `var(--radius-*)`. `Border` and `Outline` are declaration dispatchers (`declSheet`); `Ring`
and `Divide` are the front's two `…ToSheet` dispatchers.

| Group | Tokens | CSS |
|---|---|---|
| Width (`§ 11.2`) | `.Border.W.{0, 1, 2, 4, 8}` and `.Border.W.{X, Y, T, R, B, L, S, E}.<width>` | `border-width:1px`; an axis is two declarations (`border-left-width:1px;border-right-width:1px`), a side one; `S`/`E` → `border-inline-start-width`/`-end-width` |
| Style (`§ 11.3`) | `.Border.Style.{Solid, Dashed, Dotted, Double, Hidden, None}` | `border-style:…` |
| Colour (`§ 11.4`) | `.Border.Color.<Family>.<shade>`, `White`, `Black`, `Transparent`, `Current`, `Inherit` | `border-color:var(--color-slate-200)` — the shade is kept |
| Radius (`§ 11.1`, `§ 21.5`) | `.Border.Rounded.{None, Xs, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, Full}` on the shorthand and on each of `T R B L Tl Tr Br Bl S E Ss Se Es Ee` | `border-radius:var(--radius-lg)`; `Full` → `9999px`, `None` → `0`; a side form emits two corner properties, a corner form one; logical corners use `border-start-start-radius` … |
| Outline (`§ 11.5`–`11.8`) | `.Outline.W.{0, 1, 2, 4, 8}`, `.Outline.Style.{Solid, Dashed, Dotted, Double, None}`, `.Outline.Color.*`, `.Outline.Offset.{0, 1, 2, 4, 8}` and `.Offset.Neg.*` | `outline-width:2px`, `outline-offset:-1px`; **`Style.None` → `outline:2px solid transparent;outline-offset:2px`**, never `outline-style:none` |
| Ring | `.Ring.W.{0, 1, 2, 4, 8}`, `.Ring.Color.*`, `.Ring.Offset.W.*`, `.Ring.Offset.Color.*`, `.Ring.Inset` | `.Ring.W.2` → `--tw-ring-shadow:var(--tw-ring-inset, ) 0 0 0 calc(2px + var(--tw-ring-offset-width, 0px)) var(--tw-ring-color, currentcolor)` plus the five-channel `box-shadow` reader (below); `.Ring.W.1` is bare `ring` (v4 default 1px) |
| Divide | `.Divide.{X, Y}.<width>`, `.Divide.Color.*`, `.Divide.Style.*`, `XReverse`, `YReverse` | a rule on `:where(& > :not(:last-child))`: `--tw-divide-y-reverse:0;border-top-width:calc(1px * var(--tw-divide-y-reverse));border-bottom-width:calc(1px * calc(1 - var(--tw-divide-y-reverse)))`; width, colour and style merge into one child rule; the class body itself is empty |

**Shadow composition.** Every shadow and ring token writes one channel and the same reader,
upstream v4's five-channel `box-shadow`:
`var(--tw-inset-shadow, 0 0 transparent), var(--tw-inset-ring-shadow, 0 0 transparent), var(--tw-ring-offset-shadow, 0 0 transparent), var(--tw-ring-shadow, 0 0 transparent), var(--tw-shadow, 0 0 transparent)`
— so `[.Ring.W.2, .Effect.Shadow.Md]` draws both, and swapping them is a different class (contract 4:
token order is class identity).

**Divide and Space share one selector**, `siblingSelector()` (front 35), asserted byte-identical.

## Acceptance

### Delivered

- [x] `.Border.W.{0,1,2,4}` emit what they did; `W.8` exists; every directional sub-section answers
      all five widths; an axis is two declarations, a side one; `S` is the logical start.
- [x] Six border styles; `.Border.Color.Slate.200` → `border-color:var(--color-slate-200)` (the
      shade is kept); every colour sub-section calls `paletteVar` — no colour table here; the
      `Border.Color.Hex(value)` arm is kept (unconstructible, see front 33).
- [x] Ten radius leaves, eight of them theme references; `Full` stays `9999px`; `Lg` is
      `var(--radius-lg)`; the referenced `--radius-*` names are all in the theme; side and corner
      forms; every directional sub-section carries the full ladder.
- [x] Five outline widths and four real styles; `Outline.Style.None` is the transparent two-declaration
      form; `Outline.Color` through `paletteVar`; five positive and four negative offsets; a
      `FocusVisible` outline ring is one modified rule.
- [x] `.Ring.W.2` emits the custom property and the composed `box-shadow`; `Ring` composes with
      `Effect.Shadow`; `Ring.Inset` and the offset families; ring colours through `paletteVar`;
      `ringTokenToSheet` says in its header that it is a `…ToSheet`; property names verified against
      upstream `utilities.ts`, with fallbacks for the `@property` initials emilia does not emit.
- [x] `.Divide.Y.2` is a rule on the children; width, colour and style share one child rule; the
      selector comes from front 35's `siblingSelector()` and is byte-identical to `Space`'s; verified
      against upstream.
- [x] Arrow arms, the `val out = case …; return out;` idiom; the two `…ToSheet` dispatchers are named
      in `repository/emilia/AGENTS.md`; the front-40 banners fence both files; the three arms follow
      front 38's; swapping `Ring` and `Effect.Shadow` changes the class.
- [x] Every `§ 11.1`–`§ 11.8` utility has a token; all 1704 leaves declare something; the 1440 colour
      cells are `var(--color-…)` references, distinct per section; green on commonJS and erlang.

## Known gaps

- The composed `box-shadow` list and the whole `ring-offset-*` family are declared but not confirmed
  upstream — v4's documentation no longer carries `ring-offset-*`. Recorded in the `emilia.bp` banner
  and `docs.md`.
- `outline-hidden` is not declared.

## Examples

- [`./examples/borders-example.bp`](./examples/borders-example.bp) — width per side, style, colour,
  the radius family with corners; a card with a rounded top, square bottom and a dashed rule.
- [`./examples/outline-ring-example.bp`](./examples/outline-ring-example.bp) — outline and its `none`
  case, ring, offset, inset and divide; a focus-ringed control and a `divide-y` list.
