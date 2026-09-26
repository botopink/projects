# Front 35 — emilia spacing and sizing

**Track:** D emilia · **Priority:** critical · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`spacing(n)`, `spacingHalf(n)`, `themeVar`, `--container-*`, `--breakpoint-*`), 56 (`declSheet`; `Sheet` for `Space`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 35 — spacing and sizing` block:
`Pad`, `Margin`, `Size`, `Space`) · `src/emilia.bp` (front-35 block: `padTokenToCss`, `marginTokenToCss`,
`sizeTokenToCss`, `spaceTokenToSheet`, `siblingSelector`, and their sub-dispatchers)
**Does not own:** `Gap` (front 37), `Layout.Inset` (front 36)
**User docs:** `repository/emilia/docs.md` § *Pad and Margin*, § *Size*, § *Space*
**Reference:** `TAILWIND_CSS_DOCS.md § 7`, `§ 8`, `§ 21.2` · https://tailwindcss.com/docs/padding

**Open:** none.

---

## What it delivers

Padding, margin, sizing and child spacing over one scale. **No leaf resolves a length**: every step
is front 54's `spacing(n)` / `spacingHalf(n)` (`calc(var(--spacing) * n)`), every named width is a
theme reference. Every sub-dispatcher takes `th: Theme`.

**The scale** (every direction of `Pad`, `Margin`, `Space`, and the numeric part of `Size`):
`0 1 2 3 4 5 6 7 8 9 10 11 12 14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 96`, `Px`, and
`Half { 0, 1, 2, 3 }` (`0.5`, `1.5`, `2.5`, `3.5` — a numeric leaf is a digit run, so `0.5` cannot be
one).

| Shape | Token | CSS |
|---|---|---|
| zero | `.Pad.All.0` | `padding:0` |
| step | `.Pad.All.4` | `padding:calc(var(--spacing) * 4)` |
| half step | `.Pad.All.Half.1` | `padding:calc(var(--spacing) * 1.5)` |
| pixel | `.Pad.All.Px` | `padding:1px` |

| Family | Tokens | CSS |
|---|---|---|
| Padding (`§ 7.1`) | `Pad.{All, X, Y, T, R, B, L, S, E}` | `padding`, `padding-left`+`padding-right`, `padding-top`+`padding-bottom`, `padding-top` … `padding-inline-start`, `padding-inline-end` |
| Margin (`§ 7.2`) | `Margin.{All, X, Y, T, R, B, L, S, E}` + `Auto` and `Neg { … }` on every direction | as padding with `margin-*`; `.Margin.X.Auto` → `margin-left:auto;margin-right:auto`; `.Margin.T.Neg.4` → `margin-top:calc(var(--spacing) * -4)` (no negative `0`/`Auto`) |
| Width / height (`§ 8.1`, `§ 8.4`) | `Size.W`, `Size.H`: the scale, `Frac { Half, Third, TwoThirds, Quarter, ThreeQuarters, Fifth, TwoFifths, ThreeFifths, FourFifths, Sixth, FiveSixths }`, `Full`, `Screen`, `Svw/Lvw/Dvw` (`Svh/Lvh/Dvh` on `H`), `Min`, `Max`, `Fit`, `Auto` | `width:33.333333%`, `width:66.666667%` (upstream's decimals); `Screen` is `100vw` on `W` and `100vh` on `H` |
| Min / max (`§ 8.2`, `8.3`, `8.5`, `8.6`) | `Size.MinW`, `MaxW`, `MinH`, `MaxH` | `MaxW` named widths `X3xs`…`X7xl` → `max-width:var(--container-*)`; `MaxW.Screen.{Sm…X2xl}` → `max-width:var(--breakpoint-*)` |
| Logical (`§ 8.7`) | `Size.Inline`, `Block`, `MinInline`, `MaxInline`, `MinBlock`, `MaxBlock` | `inline-size`, `block-size` and their min/max forms |
| `size-*` | `Size.Both` | `width:…;height:…` from one leaf |
| Child spacing | `Space.X`, `Space.Y` (scale incl. `Neg`), `XReverse`, `YReverse` | a second rule on `:where(& > :not(:last-child))`: `--tw-space-y-reverse:0;margin-block-start:calc(<step> * var(--tw-space-y-reverse));margin-block-end:calc(<step> * calc(1 - var(--tw-space-y-reverse)))` (inline pair for `X`); the reverse tokens set the flag to `1` |

`Space` is the one section here that returns a `Sheet` (`spaceTokenToSheet`), because its
declarations sit on the children; its selector comes from `siblingSelector()` and is byte-identical
to front 40's `Divide`. The form is upstream v4's, read from upstream `utilities.ts` (the local
reference omits `space-*`).

## Acceptance

### Delivered

- [x] `.Pad.All.4` → `padding:calc(var(--spacing) * 4)`; `.Pad.X.4` → the two-declaration form;
      `.Pad.All.0` → `padding:0`.
- [x] No fn in the block returns a literal length except the `Px` leaf's `1px`/`-1px`; no token emits
      a non-CSS property (`padding-x`, `padding-y`, `margin-y`) or a Tailwind class fragment
      (`m-1`, `m-0.25`, `margin-auto`); every sub-dispatcher takes `th: Theme`.
- [x] The earlier paths (`.Pad.X.4`, `.Pad.All.16`, `.Margin.Y.8`, `.Margin.X.Auto`) still compile.
- [x] Nine padding directions × 35 leaves; nine margin directions with `Auto` and `Neg` each;
      `.Margin.T.Neg.4` and `.Margin.X.Neg.2` negative; `.Pad.S.4`/`.Pad.E.4` logical.
- [x] `Size`: `W.Full` → `width:100%`, `W.Screen` → `width:100vw`, `H.Screen` → `height:100vh`; the
      eleven fractions at upstream's decimals; named `MaxW` widths are `var(--container-*)` references
      whose theme values match `§ 8.3`; `MaxW.Screen.X2xl` → `max-width:var(--breakpoint-2xl)`;
      `Both.12` emits two declarations; the six logical forms.
- [x] `Space.Y.4`/`Space.X.4` emit upstream's reverse-aware block/inline pair under
      `:where(& > :not(:last-child))`; composing with a `Pad` token gives two rules of one class in
      order; `Space.X.Neg.2` pulls up; the selector carries one `&` and is byte-identical to
      `Divide`'s.
- [x] Every dispatcher uses the `val out = case …; return out;` idiom with arrow arms only; the
      front-35 banners fence both blocks, in front-number position, with arms between fronts 33
      and 36; `repository/emilia/AGENTS.md` and the `tokens.bp` header record the sections.
- [x] `spacing`/`spacingHalf` are the only spellings of `calc(var(--spacing) *` outside tests.
- [x] Green on commonJS and erlang.

## Reference notes

- The `--tw-space-*-reverse` names are upstream-internal; they are pinned by a test so a change is
  visible.
- Fractions beyond `1/2`, `1/3`, `2/3`, the 30 multiplier keys and the `px` step are not printed in
  the local reference; they follow upstream's default theme.

## Examples

- [`./examples/spacing-example.bp`](./examples/spacing-example.bp) — the scale, nine padding
  directions, margin with `Auto` and negatives, child spacing; a comment thread using `Space.Y` and a
  negative pull-up.
- [`./examples/sizing-example.bp`](./examples/sizing-example.bp) — width, height, fractions, viewport
  and intrinsic sizes, min/max, logical forms; a centred article shell with a full-bleed header.
