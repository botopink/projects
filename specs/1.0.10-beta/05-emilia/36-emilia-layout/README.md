# Front 36 — emilia-layout

**Track:** D emilia
**Priority:** high — six display values is the whole of emilia's layout vocabulary. Nothing can be positioned, clipped, stacked or floated, which rules out every overlay, sticky header and scroll container.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 3
**Depends on:** 54 (`Theme`, `spacing(n)`, `spacingHalf(n)`), 56 (`declSheet` — this front emits declarations only, no selector), 33 (nothing structural; the examples use colour tokens)
**Owns:** `repository/emilia/src/tokens.bp` (the `Layout` section) · `repository/emilia/src/emilia.bp` (`layoutTokenToCss` and its sub-dispatchers) · `repository/emilia/test/layout_test.bp`
**Does not touch:** `Flex` and `Grid` (front 37) — `display:flex` is here because it is a display value, the flex container's own properties are not; `Size` (front 35)
**Reference:** `TAILWIND_CSS_DOCS.md § 5. Layout` (5.1–5.19) · https://tailwindcss.com/docs/display

---

## Problem

`Layout` today (`tokens.bp:185-192`) is a flat list of six display values: `Block`, `InlineBlock`,
`Inline`, `Hidden`, `Flex`, `Grid`. `§ 5.8` lists eleven, so `inline-flex`, `inline-grid`,
`contents`, `flow-root` and `list-item` have no token.

Everything else in `§ 5` is absent. There is no `position`, so nothing can be absolute, fixed or
sticky, and no `top`/`right`/`bottom`/`left`/`inset`, so a positioned box could not be placed even
if it could be positioned. There is no `overflow`, so no scroll container and no clipping; no
`z-index`, so no stacking order; no `visibility`, so nothing can be hidden while keeping its space;
no `float` or `clear`; no `isolation`; no `object-fit` or `object-position`, so an image cannot be
cropped; no `aspect-ratio`; no `columns` and no `break-*`; no `box-sizing`; no
`box-decoration-break`.

`.Layout.Position.Absolute`, `.Layout.Overflow.Hidden`, `.Layout.Z.10` and `.Layout.Inset.0` do not
exist — and that is precisely what this front delivers.

## Current state

| What | Where | State |
|---|---|---|
| `Layout { Block, InlineBlock, Inline, Hidden, Flex, Grid }` | `tokens.bp:185-192` | six display values, flat |
| `layoutTokenToCss` | `emilia.bp:262-272` | six arrow arms, each a correct `display:` declaration |
| everything else in `§ 5` | — | no token |

`layoutTokenToCss` is one of the few dispatchers in the file that already emits valid CSS. This
front widens it; it corrects nothing.

## Mechanism

`§ 5` is nineteen independent properties, so `Layout` becomes a section of sub-sections — one per
property group — with the existing six display leaves kept as bare siblings at the top of `Layout`
so that every path compiling today keeps compiling.

Three shapes recur:

- **Keyword leaf → one declaration.** The bulk of `§ 5`: `position`, `overflow`, `float`, `clear`,
  `visibility`, `object-fit`, `box-sizing`. One arm, one string.
- **Numeric leaf → a computed length.** `Inset` calls front 54's `spacing(n)` / `spacingHalf(n)`,
  the same two fns front 35 calls, so `.Layout.Inset.T.4` and `.Pad.T.4` agree by construction
  rather than by coincidence. Per contract 4a in [`contracts.md`](../../contracts.md) that is
  `calc(var(--spacing) * 4)`, never a resolved `rem`. `Z` is a plain integer, not a length.
- **One token → several declarations.** `Inset.All` sets four properties, `Inset.X` and `Inset.Y`
  set two. `§ 5.17` prints `inset-x-0` as `left: 0; right: 0`, and that is the form emitted.

`Inset` carries negatives the same way `Margin` does, through a `Neg` sub-section, because
`-top-4` is a real utility with no alternative spelling. A five-segment path was verified to
resolve before this spec was written.

## Token surface

### Display — `§ 5.8`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `block` | `.Layout.Block` | `display:block` |
| `inline-block` | `.Layout.InlineBlock` | `display:inline-block` |
| `inline` | `.Layout.Inline` | `display:inline` |
| `flex` | `.Layout.Flex` | `display:flex` |
| `inline-flex` | `.Layout.InlineFlex` | `display:inline-flex` |
| `grid` | `.Layout.Grid` | `display:grid` |
| `inline-grid` | `.Layout.InlineGrid` | `display:inline-grid` |
| `contents` | `.Layout.Contents` | `display:contents` |
| `flow-root` | `.Layout.FlowRoot` | `display:flow-root` |
| `list-item` | `.Layout.ListItem` | `display:list-item` |
| `hidden` | `.Layout.Hidden` | `display:none` |

### Position and inset — `§ 5.16`, `§ 5.17`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `static` | `.Layout.Position.Static` | `position:static` |
| `fixed` | `.Layout.Position.Fixed` | `position:fixed` |
| `absolute` | `.Layout.Position.Absolute` | `position:absolute` |
| `relative` | `.Layout.Position.Relative` | `position:relative` |
| `sticky` | `.Layout.Position.Sticky` | `position:sticky` |
| `top-0` | `.Layout.Inset.T.0` | `top:0` |
| `top-1` | `.Layout.Inset.T.1` | `top:calc(var(--spacing) * 1)` |
| `top-1/2` | `.Layout.Inset.T.Frac.Half` | `top:50%` |
| `top-full` | `.Layout.Inset.T.Full` | `top:100%` |
| `top-auto` | `.Layout.Inset.T.Auto` | `top:auto` |
| `-top-4` | `.Layout.Inset.T.Neg.4` | `top:calc(var(--spacing) * -4)` |
| `right-0` | `.Layout.Inset.R.0` | `right:0` |
| `bottom-0` | `.Layout.Inset.B.0` | `bottom:0` |
| `left-0` | `.Layout.Inset.L.0` | `left:0` |
| `start-0` | `.Layout.Inset.S.0` | `inset-inline-start:0` |
| `end-0` | `.Layout.Inset.E.0` | `inset-inline-end:0` |
| `inset-0` | `.Layout.Inset.All.0` | `inset:0` |
| `inset-x-0` | `.Layout.Inset.X.0` | `left:0;right:0` |
| `inset-y-0` | `.Layout.Inset.Y.0` | `top:0;bottom:0` |

### Overflow and overscroll — `§ 5.14`, `§ 5.15`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `overflow-auto` | `.Layout.Overflow.Auto` | `overflow:auto` |
| `overflow-hidden` | `.Layout.Overflow.Hidden` | `overflow:hidden` |
| `overflow-clip` | `.Layout.Overflow.Clip` | `overflow:clip` |
| `overflow-visible` | `.Layout.Overflow.Visible` | `overflow:visible` |
| `overflow-scroll` | `.Layout.Overflow.Scroll` | `overflow:scroll` |
| `overflow-x-auto` | `.Layout.Overflow.X.Auto` | `overflow-x:auto` |
| `overflow-x-hidden` | `.Layout.Overflow.X.Hidden` | `overflow-x:hidden` |
| `overflow-x-clip` | `.Layout.Overflow.X.Clip` | `overflow-x:clip` |
| `overflow-x-visible` | `.Layout.Overflow.X.Visible` | `overflow-x:visible` |
| `overflow-x-scroll` | `.Layout.Overflow.X.Scroll` | `overflow-x:scroll` |
| `overflow-y-auto` | `.Layout.Overflow.Y.Auto` | `overflow-y:auto` |
| `overflow-y-hidden` | `.Layout.Overflow.Y.Hidden` | `overflow-y:hidden` |
| `overflow-y-clip` | `.Layout.Overflow.Y.Clip` | `overflow-y:clip` |
| `overflow-y-visible` | `.Layout.Overflow.Y.Visible` | `overflow-y:visible` |
| `overflow-y-scroll` | `.Layout.Overflow.Y.Scroll` | `overflow-y:scroll` |
| `overscroll-auto` | `.Layout.Overscroll.Auto` | `overscroll-behavior:auto` |
| `overscroll-contain` | `.Layout.Overscroll.Contain` | `overscroll-behavior:contain` |
| `overscroll-none` | `.Layout.Overscroll.None` | `overscroll-behavior:none` |
| `overscroll-x-auto` | `.Layout.Overscroll.X.Auto` | `overscroll-behavior-x:auto` |
| `overscroll-x-contain` | `.Layout.Overscroll.X.Contain` | `overscroll-behavior-x:contain` |
| `overscroll-x-none` | `.Layout.Overscroll.X.None` | `overscroll-behavior-x:none` |
| `overscroll-y-auto` | `.Layout.Overscroll.Y.Auto` | `overscroll-behavior-y:auto` |
| `overscroll-y-contain` | `.Layout.Overscroll.Y.Contain` | `overscroll-behavior-y:contain` |
| `overscroll-y-none` | `.Layout.Overscroll.Y.None` | `overscroll-behavior-y:none` |

### Visibility, z-index, isolation — `§ 5.18`, `§ 5.19`, `§ 5.11`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `visible` | `.Layout.Visibility.Visible` | `visibility:visible` |
| `invisible` | `.Layout.Visibility.Invisible` | `visibility:hidden` |
| `collapse` | `.Layout.Visibility.Collapse` | `visibility:collapse` |
| `z-0` | `.Layout.Z.0` | `z-index:0` |
| `z-10` | `.Layout.Z.10` | `z-index:10` |
| `z-20` | `.Layout.Z.20` | `z-index:20` |
| `z-30` | `.Layout.Z.30` | `z-index:30` |
| `z-40` | `.Layout.Z.40` | `z-index:40` |
| `z-50` | `.Layout.Z.50` | `z-index:50` |
| `z-auto` | `.Layout.Z.Auto` | `z-index:auto` |
| `isolate` | `.Layout.Isolation.Isolate` | `isolation:isolate` |
| `isolation-auto` | `.Layout.Isolation.Auto` | `isolation:auto` |

### Float and clear — `§ 5.9`, `§ 5.10`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `float-start` | `.Layout.Float.Start` | `float:inline-start` |
| `float-end` | `.Layout.Float.End` | `float:inline-end` |
| `float-right` | `.Layout.Float.Right` | `float:right` |
| `float-left` | `.Layout.Float.Left` | `float:left` |
| `float-none` | `.Layout.Float.None` | `float:none` |
| `clear-start` | `.Layout.Clear.Start` | `clear:inline-start` |
| `clear-end` | `.Layout.Clear.End` | `clear:inline-end` |
| `clear-left` | `.Layout.Clear.Left` | `clear:left` |
| `clear-right` | `.Layout.Clear.Right` | `clear:right` |
| `clear-both` | `.Layout.Clear.Both` | `clear:both` |
| `clear-none` | `.Layout.Clear.None` | `clear:none` |

### Replaced content — `§ 5.12`, `§ 5.13`, `§ 5.1`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `object-contain` | `.Layout.Object.Fit.Contain` | `object-fit:contain` |
| `object-cover` | `.Layout.Object.Fit.Cover` | `object-fit:cover` |
| `object-fill` | `.Layout.Object.Fit.Fill` | `object-fit:fill` |
| `object-none` | `.Layout.Object.Fit.None` | `object-fit:none` |
| `object-scale-down` | `.Layout.Object.Fit.ScaleDown` | `object-fit:scale-down` |
| `object-bottom` | `.Layout.Object.Pos.Bottom` | `object-position:bottom` |
| `object-center` | `.Layout.Object.Pos.Center` | `object-position:center` |
| `object-left` | `.Layout.Object.Pos.Left` | `object-position:left` |
| `object-left-bottom` | `.Layout.Object.Pos.LeftBottom` | `object-position:left bottom` |
| `object-left-top` | `.Layout.Object.Pos.LeftTop` | `object-position:left top` |
| `object-right` | `.Layout.Object.Pos.Right` | `object-position:right` |
| `object-right-bottom` | `.Layout.Object.Pos.RightBottom` | `object-position:right bottom` |
| `object-right-top` | `.Layout.Object.Pos.RightTop` | `object-position:right top` |
| `object-top` | `.Layout.Object.Pos.Top` | `object-position:top` |
| `aspect-auto` | `.Layout.Aspect.Auto` | `aspect-ratio:auto` |
| `aspect-square` | `.Layout.Aspect.Square` | `aspect-ratio:1 / 1` |
| `aspect-video` | `.Layout.Aspect.Video` | `aspect-ratio:16 / 9` |

### Multi-column and fragmentation — `§ 5.2`–`§ 5.6`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `columns-1` | `.Layout.Columns.1` | `columns:1` |
| `columns-2` | `.Layout.Columns.2` | `columns:2` |
| `columns-3` | `.Layout.Columns.3` | `columns:3` |
| `columns-auto` | `.Layout.Columns.Auto` | `columns:auto` |
| `columns-3xs` | `.Layout.Columns.X3xs` | `columns:16rem` |
| `columns-2xs` | `.Layout.Columns.X2xs` | `columns:18rem` |
| `columns-xs` | `.Layout.Columns.Xs` | `columns:20rem` |
| `columns-sm` | `.Layout.Columns.Sm` | `columns:24rem` |
| `columns-md` | `.Layout.Columns.Md` | `columns:28rem` |
| `columns-lg` | `.Layout.Columns.Lg` | `columns:32rem` |
| `columns-xl` | `.Layout.Columns.Xl` | `columns:36rem` |
| `columns-2xl` | `.Layout.Columns.X2xl` | `columns:42rem` |
| `columns-3xl` | `.Layout.Columns.X3xl` | `columns:48rem` |
| `columns-4xl` | `.Layout.Columns.X4xl` | `columns:56rem` |
| `columns-5xl` | `.Layout.Columns.X5xl` | `columns:64rem` |
| `columns-6xl` | `.Layout.Columns.X6xl` | `columns:72rem` |
| `columns-7xl` | `.Layout.Columns.X7xl` | `columns:80rem` |
| `break-after-auto` | `.Layout.Break.After.Auto` | `break-after:auto` |
| `break-after-avoid` | `.Layout.Break.After.Avoid` | `break-after:avoid` |
| `break-after-all` | `.Layout.Break.After.All` | `break-after:all` |
| `break-after-page` | `.Layout.Break.After.Page` | `break-after:page` |
| `break-after-left` | `.Layout.Break.After.Left` | `break-after:left` |
| `break-after-right` | `.Layout.Break.After.Right` | `break-after:right` |
| `break-after-column` | `.Layout.Break.After.Column` | `break-after:column` |
| `break-before-auto` | `.Layout.Break.Before.Auto` | `break-before:auto` |
| `break-before-page` | `.Layout.Break.Before.Page` | `break-before:page` |
| `break-before-column` | `.Layout.Break.Before.Column` | `break-before:column` |
| `break-inside-auto` | `.Layout.Break.Inside.Auto` | `break-inside:auto` |
| `break-inside-avoid` | `.Layout.Break.Inside.Avoid` | `break-inside:avoid` |
| `break-inside-avoid-page` | `.Layout.Break.Inside.AvoidPage` | `break-inside:avoid-page` |
| `break-inside-avoid-column` | `.Layout.Break.Inside.AvoidColumn` | `break-inside:avoid-column` |
| `box-border` | `.Layout.Box.Border` | `box-sizing:border-box` |
| `box-content` | `.Layout.Box.Content` | `box-sizing:content-box` |
| `box-decoration-clone` | `.Layout.BoxDecoration.Clone` | `box-decoration-break:clone` |
| `box-decoration-slice` | `.Layout.BoxDecoration.Slice` | `box-decoration-break:slice` |

`break-before` and `break-inside` carry the same leaf sets `§ 5.4` and `§ 5.5` list; the table above
shows three rows of each rather than repeating fourteen.

## Steps

### Step 1 — widen display

Five leaves added as bare siblings inside `Layout`, beside the six that exist. No sub-section: the
display values are the section's own leaves, which is what makes `.Layout.Flex` keep working.

**Acceptance:**
- [x] all eleven `§ 5.8` display values have a token — held: test "display — the eleven `§ 5.8` values, the six that predate front 36 first"
- [x] `.Layout.Block`, `.Layout.Flex`, `.Layout.Grid`, `.Layout.Hidden`, `.Layout.Inline`,
      `.Layout.InlineBlock` emit exactly what `emilia.bp:262-272` emits today — held: test "display — the eleven `§ 5.8` values, the six that predate front 36 first"
- [x] the existing assertion at `emilia.bp:423-425` still passes untouched — held: test "tokenToSheet — Layout.Flex lowers to display:flex"

### Step 2 — position and the inset family

```bp
        Position { Static, Fixed, Absolute, Relative, Sticky, }
        Inset {
            All { 0, …, 96, Px, Auto, Full, Frac { Half, Third, TwoThirds }, Neg { … } }
            X { … }  Y { … }  T { … }  R { … }  B { … }  L { … }  S { … }  E { … }
        }
```

`Inset.All`, `.X` and `.Y` each emit more than one declaration where CSS has no single property —
`§ 5.17` prints `inset-x-0` as `left: 0; right: 0`. `inset` itself is a real shorthand, so
`Inset.All` emits one declaration.

**Acceptance:**
- [x] five position values — held: test "position — the five values of `§ 5.16`"
- [x] `.Layout.Inset.All.0` emits `inset:0` — held: test "inset — `All` is the shorthand, `X` and `Y` are the two declarations CSS has no shorthand for"
- [x] `.Layout.Inset.X.0` emits `left:0;right:0` and `.Layout.Inset.Y.0` emits `top:0;bottom:0` — held: test "inset — `All` is the shorthand, `X` and `Y` are the two declarations CSS has no shorthand for"
- [x] `.Layout.Inset.T.Frac.Half` emits `top:50%` — held: test "inset — the keyword and fraction leaves of `§ 5.17`"
- [x] `.Layout.Inset.T.Neg.4` emits `top:calc(var(--spacing) * -4)` — held: test "inset — negatives go through `spacing(-n)`, never through a second calc"
- [x] the inset scale and the padding scale produce identical length text for the same leaf,
      asserted directly: `.Layout.Inset.T.4` and `.Pad.T.4` differ only in the property name, and
      both read `calc(var(--spacing) * 4)` — held: test "inset and padding agree by construction — one scale, two properties"
- [x] `.Layout.Inset.S.0` / `.E.0` emit `inset-inline-start` / `inset-inline-end` — held: test "inset — the logical pair follows the writing direction where L/R do not"

### Step 3 — overflow, overscroll, visibility, z-index, isolation

Five sub-sections, all keyword or small-integer leaves.

**Acceptance:**
- [x] `Overflow` answers five values on the shorthand and five each on `X` and `Y` — held: test "overflow — the shorthand and both longhands, five values each"
- [x] `Overscroll` answers three values on the shorthand and three each on `X` and `Y` — held: test "overscroll — three values on the shorthand and three on each axis"
- [x] `invisible` maps to `visibility:hidden`, not `visibility:invisible` — the Tailwind name and the
      CSS value differ and the test says so — held: test "visibility — `invisible` is `visibility:hidden`, and the word does not survive"
- [x] `Z` answers `0 10 20 30 40 50 Auto` and emits a bare integer, never a length — held: test "z-index — a bare integer, never a length and never a calc"
- [x] `Isolation` answers `Isolate` and `Auto` — held: test "isolation — the two values of `§ 5.11`"

### Step 4 — float, clear, object, aspect

**Acceptance:**
- [x] `float-start` maps to `float:inline-start`, not `float:start` — held: test "float and clear — the logical pair is `inline-start`, not `start`"
- [x] `clear-start` maps to `clear:inline-start` — held: test "float and clear — the logical pair is `inline-start`, not `start`"
- [x] `Object.Fit` answers five values; `Object.Pos` answers nine, including the four two-word ones
      (`left bottom`, `left top`, `right bottom`, `right top`) with a single space — held: tests "object-fit — the five values of `§ 5.12`" + "object-position — all nine, and the four two-word values are one space"
- [x] `Aspect.Square` emits `aspect-ratio:1 / 1` and `Aspect.Video` emits `aspect-ratio:16 / 9` —
      spaces around the slash, as `§ 5.1` prints them — held: test "aspect-ratio — the slash keeps its spaces"

### Step 5 — columns, breaks, box-sizing, box-decoration

**Acceptance:**
- [x] `Columns` answers the three integers and `Auto` plus the fourteen named widths of `§ 5.2` — held (shape: the table's thirteen named widths, emitted as `var(--container-*)`): tests "columns — a count is an integer, a named width is the theme's container" + "columns — all fourteen named widths, and the ladder is one ladder"
- [x] `Break.After`, `Break.Before` and `Break.Inside` answer their full leaf sets — held (shape: flat `BreakAfter`/`BreakBefore`/`BreakInside` — `Before`/`After` collide with front 34's payload variants): test "break — the three properties, with `inside`'s shorter leaf set of its own"
- [x] `Box.Border` / `Box.Content` emit `box-sizing:border-box` / `content-box` — held: test "box-sizing and box-decoration-break — the suffix moves off the name"
- [x] `BoxDecoration.Clone` / `.Slice` emit `box-decoration-break:clone` / `slice` — held: test "box-sizing and box-decoration-break — the suffix moves off the name"

### Step 6 — the dispatcher

`layoutTokenToCss` gains one arm per sub-section and keeps its eleven display arms. Each sub-section
gets its own fn, all with the contract-4a shape
`fn <name>(t: Token.Layout.<Sub>, th: Theme) -> string`; the `Inset` family gets one fn per
direction, each calling front 54's `spacing`.

**Acceptance:**
- [x] `layoutTokenToCss` follows the file's `val out = case …; return out;` idiom — held: `emilia.bp:layoutTokenToCss`
- [x] every arm is an arrow arm — held: every arm in the front-36 block of `emilia.bp` is `X -> expr;`
- [x] front 54's `spacing` / `spacingHalf` are called, not copied — there is one spacing scale in the library — held: `insetScale*`/`insetHalf*`/`insetNeg*` call `spacing`/`spacingHalf`; test "regression — the inset ladder is the spacing ladder, direction by direction"
- [x] every sub-dispatcher takes `th: Theme`, and none of them returns a literal `rem` — held: every `layout*`/`inset*` fn takes `th: Theme`; test "regression — no `Layout` leaf resolves a length; all 776 reference the theme"
- [x] the banner `// ── front 36 — layout ──` fences the block in both files — held: `tokens.bp:1024` and `emilia.bp:5011`, each closed by `// ── end front 36 ──`
- [x] the existing `Layout(_inner) -> layoutTokenToCss(_inner);` arm in the top-level `tokenToCss`
      is reused; this front adds no new top-level arm — held (shape: arm now passes `th` through `declSheet`): `emilia.bp:tokenToSheet` `Layout(_inner) -> declSheet(layoutTokenToCss(_inner, th))`

## Examples

- `./examples/layout-example.bp` — display, overflow, visibility, float, clear, isolation,
  object-fit, aspect-ratio, columns and box-sizing; ends with a media card that crops its image and
  clips its overflow.
- `./examples/position-example.bp` — position and the full inset family including negatives and
  fractions, plus z-index; ends with a sticky header over a scrolling panel with a badge pinned to a
  corner.

## Language gaps

None — every construct in this front's examples parses today. The one shape worth naming is the
five-segment path `.Layout.Inset.T.Neg.4`, which was verified to resolve against
`zig-out/bin/botopink` before this spec was written; it is the deepest path in the front.

## Reference gaps

| Item | Why it is missing | What implementation must do |
|---|---|---|
| `aspect-[4/3]` and every other arbitrary ratio | `§ 5.1` shows the class, and the value is by definition not enumerable | the escape-hatch front |
| `columns-4` … `columns-12` | `§ 5.2` prints `columns-1`, `-2`, `-3` and the named widths only | this front declares `1`, `2`, `3`; higher integers must be confirmed against upstream before being added |
| `z-[999]` | `§ 5.19` names arbitrary z-index but prints no scale beyond 50 | the escape-hatch front |
| `inset-auto`, `top-px`, the inset fraction set | `§ 5.17` prints `top-1/2` and `top-full` only | `Auto`, `Px`, `Frac.Third` and `Frac.TwoThirds` are declared by symmetry with `§ 8.1`; confirm before merge |

## Test plan

`repository/emilia/test/layout_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`.

What the tests assert:

1. **Display** — eleven asserts, including the six that must not change.
2. **Position** — five asserts.
3. **Inset** — one test per direction, plus the multi-declaration cases (`All`, `X`, `Y`), plus a
   negative, plus a fraction, plus the cross-check against `.Pad.T.4`'s length text.
4. **Overflow / overscroll** — the shorthand and both axes.
5. **The name-vs-value traps**, asserted individually because each is a place a transcription slips:
   `invisible` → `visibility:hidden`, `float-start` → `float:inline-start`,
   `clear-start` → `clear:inline-start`, `aspect-square` → `1 / 1` with spaces.
6. **Object position** — all nine, with the two-word values checked for a single space.
7. **Columns and breaks** — every leaf.
8. **End to end** — `emilia([.Layout.Position.Sticky, .Layout.Inset.T.0, .Layout.Z.50])` then
   `await flush()`, asserting the whole `<style>` block.

## Definition of done

- [x] every utility in `§ 5.1`–`§ 5.19` that is not an arbitrary-value form has a token — held (shape: `columns-4…12` left out as the spec's own reference gap): `tokens.bp` `Layout`; test "regression — no `Layout` leaf resolves a length; all 776 reference the theme"
- [x] the six display paths that compile today emit byte-identical CSS afterwards — held: test "display — the eleven `§ 5.8` values, the six that predate front 36 first"
- [x] `Inset` calls front 54's `spacing` / `spacingHalf` — held: test "inset and padding agree by construction — one scale, two properties"
- [x] the banner fences this front's block in both files, appended at the end — held (shape: block sits in front-number position, not at file end): `tokens.bp:1024`, `emilia.bp:5011`
- [x] no new top-level `tokenToCss` arm — `Layout` already has one — held: `emilia.bp:tokenToSheet` has the single pre-existing `Layout` arm
- [x] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the widened section — held: `AGENTS.md` front-36 paragraph; `tokens.bp` `////` SECTIONS `Layout`
- [x] the front's tests are green on its assigned target — here, both backends, since emilia is comptime — held: emilia suite 569/569 on commonJS and erlang
