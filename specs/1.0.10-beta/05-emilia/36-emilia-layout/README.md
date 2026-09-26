# Front 36 — emilia layout

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`spacing(n)`, `spacingHalf(n)`, `--container-*`), 56 (`declSheet`), 33 (examples only)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 36 — layout` block: `Layout`) ·
`src/emilia.bp` (front-36 block: `layoutTokenToCss` and one sub-dispatcher per sub-section, all taking
`th: Theme`; the existing `Layout(_inner) -> declSheet(layoutTokenToCss(_inner, th))` arm)
**Does not own:** the flex/grid container properties and `Gap` (front 37); `Size` (front 35)
**User docs:** `repository/emilia/docs.md` § *Layout*
**Reference:** `TAILWIND_CSS_DOCS.md § 5` (5.1–5.19) · https://tailwindcss.com/docs/display

**Open:** none.

---

## What it delivers

The whole of `§ 5` — **776 leaves**. The eleven display values are `Layout`'s own leaves (so
`.Layout.Flex` is `display:flex`); every other property group is a sub-section beside them. **No leaf
resolves a length:** `Inset` answers front 54's `spacing(n)`/`spacingHalf(n)` over front 35's scale,
named column widths answer `var(--container-*)`, and `Z` is a bare integer.

| Group | Tokens | CSS |
|---|---|---|
| Display (`§ 5.8`) | `.Layout.Block`, `InlineBlock`, `Inline`, `Flex`, `InlineFlex`, `Grid`, `InlineGrid`, `Contents`, `FlowRoot`, `ListItem`, `Hidden` | `display:<value>`; `Hidden` → `display:none` |
| Position (`§ 5.16`) | `Position.{Static, Fixed, Absolute, Relative, Sticky}` | `position:<value>` |
| Inset (`§ 5.17`) | `Inset.{All, X, Y, T, R, B, L, S, E}` over the spacing scale plus `Auto`, `Full`, `Frac { Half, Third, TwoThirds }`, `Neg { … }` | `.Inset.All.0` → `inset:0`; `.Inset.X.0` → `left:0;right:0`; `.Inset.Y.0` → `top:0;bottom:0`; `.Inset.T.4` → `top:calc(var(--spacing) * 4)`; `.Inset.T.Neg.4` → `top:calc(var(--spacing) * -4)`; `.Inset.T.Frac.Half` → `top:50%`; `S`/`E` → `inset-inline-start`/`-end` |
| Overflow / overscroll (`§ 5.14`, `5.15`) | `Overflow.{Auto, Hidden, Clip, Visible, Scroll}` and `.X`/`.Y`; `Overscroll.{Auto, Contain, None}` and `.X`/`.Y` | `overflow[-x\|-y]:…`, `overscroll-behavior[-x\|-y]:…` |
| Visibility (`§ 5.18`) | `Visibility.{Visible, Invisible, Collapse}` | `Invisible` → `visibility:hidden` |
| Z-index (`§ 5.19`) | `Z.{0, 10, 20, 30, 40, 50, Auto}` | `z-index:50` — a bare integer |
| Isolation (`§ 5.11`) | `Isolation.{Isolate, Auto}` | `isolation:…` |
| Float / clear (`§ 5.9`, `5.10`) | `Float.{Start, End, Right, Left, None}`, `Clear.{Start, End, Left, Right, Both, None}` | `Start` → `inline-start`, `End` → `inline-end` |
| Replaced content (`§ 5.12`, `5.13`) | `Object.Fit.{Contain, Cover, Fill, None, ScaleDown}`, `Object.Pos.{Bottom, Center, Left, LeftBottom, LeftTop, Right, RightBottom, RightTop, Top}` | two-word positions carry one space (`left bottom`) |
| Aspect (`§ 5.1`) | `Aspect.{Auto, Square, Video}` | `aspect-ratio:1 / 1`, `16 / 9` — spaces around the slash |
| Columns (`§ 5.2`) | `Columns.{1, 2, 3, Auto}` and the named widths `X3xs`…`X7xl` | `columns:2`; `.Columns.Md` → `columns:var(--container-md)` (the same reference as `.Size.MaxW.Md`) |
| Fragmentation (`§ 5.3`–`5.5`) | `BreakAfter`, `BreakBefore`, `BreakInside` (flat sub-sections — a head named `After`/`Before` would shadow front 34's modifiers) | `break-after:page`, `break-inside:avoid-column`; `BreakInside` has the shorter `§ 5.5` set |
| Box (`§ 5.6`, `5.7`) | `Box.{Border, Content}`, `BoxDecoration.{Clone, Slice}` | `box-sizing:border-box`, `box-decoration-break:clone` |

## Acceptance

### Delivered

- [x] All eleven `§ 5.8` display values have a token; the six earlier ones (`Block`, `Flex`, `Grid`,
      `Hidden`, `Inline`, `InlineBlock`) emit byte-identical CSS.
- [x] Five position values; `Inset.All.0` → `inset:0`; `Inset.X.0`/`Y.0` → the two-declaration forms;
      `Inset.T.Frac.Half` → `top:50%`; `Inset.T.Neg.4` → `top:calc(var(--spacing) * -4)`; `S`/`E` are
      the logical pair.
- [x] `.Layout.Inset.T.4` and `.Pad.T.4` differ only in the property name — one scale, asserted.
- [x] `Overflow` five values on the shorthand and each axis; `Overscroll` three on each; `invisible` →
      `visibility:hidden`; `Z` a bare integer; `Isolation` both values.
- [x] `float-start`/`clear-start` → `inline-start`; five `Object.Fit` and nine `Object.Pos` values
      (two-word values with one space); `aspect-ratio:1 / 1` and `16 / 9`.
- [x] `Columns`: the three integers, `Auto`, and the thirteen named widths as `var(--container-*)`;
      `BreakAfter`/`BreakBefore`/`BreakInside` with their full leaf sets; `box-sizing` and
      `box-decoration-break`.
- [x] `layoutTokenToCss` and every sub-dispatcher use the `val out = case …; return out;` idiom with
      arrow arms and take `th: Theme`; `Inset` calls `spacing`/`spacingHalf`; no leaf of the 776
      resolves a length.
- [x] Every non-arbitrary utility in `§ 5.1`–`§ 5.19` has a token (`columns-4`…`12` excepted — see
      below); the front-36 banners fence both blocks in front-number position; no new top-level arm;
      `repository/emilia/AGENTS.md` and the `tokens.bp` header record the section; green on
      commonJS and erlang.

## Not declared

- `columns-4` … `columns-12` (upstream resolves them through the bare-integer rule, not a theme key).
- Arbitrary `aspect-[4/3]` and `z-[999]` — front 57's `arbValue`.

## Examples

- [`./examples/layout-example.bp`](./examples/layout-example.bp) — display, overflow, visibility,
  float, clear, isolation, object-fit, aspect-ratio, columns, box-sizing; a media card that crops its
  image and clips its overflow.
- [`./examples/position-example.bp`](./examples/position-example.bp) — position and the inset family
  with negatives and fractions, plus z-index; a sticky header over a scrolling panel with a pinned
  badge.
