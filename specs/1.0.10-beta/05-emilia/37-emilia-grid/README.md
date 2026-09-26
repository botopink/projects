# Front 37 — emilia flexbox, grid and gap

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`spacing(n)`, `spacingHalf(n)`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 37 — flexbox, grid and gap`
block: `Flex`, `Grid`, top-level `Gap`) · `src/emilia.bp` (front-37 block: `flexTokenToCss`,
`gridTokenToCss`, `gapTokenToCss`, `gridRepeat`, `gridFr` and the sub-dispatchers, all taking
`th: Theme`; the `Grid`/`Gap` arms of `tokenToSheet` after `Flex`)
**Does not own:** `display:flex`/`display:grid` (front 36's display values); `Pad`/`Margin`/`Size` (front 35)
**User docs:** `repository/emilia/docs.md` § *Flex*, § *Grid*, § *Gap*
**Reference:** `TAILWIND_CSS_DOCS.md § 6` (6.1–6.24) · https://tailwindcss.com/docs/flex-basis

**Open:** none.

---

## What it delivers

All of `§ 6` — **356 leaves** (`Flex` 126, `Grid` 125, `Gap` 105). This front owns `Flex`, `Grid` and
`Gap` (the directory keeps its frozen name `37-emilia-grid`). Only `Flex.Basis` and `Gap` are lengths
and both answer `spacing(n)`/`spacingHalf(n)` over front 35's scale; grow, shrink, order, counts, spans
and line numbers are bare integers.

| Group | Tokens | CSS |
|---|---|---|
| Direction / wrap (`§ 6.2`, `6.3`) | `.Flex.{Row, RowReverse, Col, ColReverse, Wrap, WrapReverse, NoWrap}` | `flex-direction:column`, `flex-wrap:wrap-reverse`, … |
| Shorthand (`§ 6.4`) | `.Flex.Value.{One, Auto, Initial, None}` (`Value`, since a section cannot hold a sub-section of its own name) | `flex:1 1 0%`, `flex:1 1 auto`, `flex:0 1 auto`, `flex:none` |
| Grow / shrink (`§ 6.5`, `6.6`) | `.Flex.Grow.{0, 1}`, `.Flex.Shrink.{0, 1}` | `flex-grow:1`, … |
| Basis (`§ 6.1`) | `.Flex.Basis` over the spacing scale + `Auto`, `Full`, `Frac { Half, Third, TwoThirds }` | `flex-basis:calc(var(--spacing) * 4)`, `flex-basis:33.333333%` (the same percentage as `.Size.W.Frac.Third`) |
| Order (`§ 6.7`) | `.Flex.Order.{1…12, First, Last, None}` | `order:-9999`, `order:9999`, `order:0` |
| Alignment (`§ 6.16`–`6.24`) | `.Flex.Justify` (8), `.Flex.Items` (5), `.Flex.AlignSelf`, `.Flex.Content`, `.Flex.JustifyItems`, `.Flex.JustifySelf`, `.Flex.PlaceContent`, `.Flex.PlaceItems`, `.Flex.PlaceSelf` | `justify-content`, `align-items`, `align-self`, `align-content` take `flex-start`/`flex-end`; `justify-items`, `justify-self` and `place-*` take `start`/`end` — upstream's asymmetry, copied; `place-content:space-between` |
| Templates (`§ 6.8`) | `.Grid.Cols.{1…12, None, Subgrid}`, `.Grid.Rows.{…}` | `grid-template-columns:repeat(12, minmax(0, 1fr))` via `gridRepeat(n)`; keywords for `None`/`Subgrid` |
| Placement (`§ 6.9`–`6.11`) | `.Grid.Col` / `.Grid.Row`: `Auto`, `Span.{1…12, Full}`, `Start.{1…13, Auto}`, `End.{1…13, Auto}` | `grid-column:span 2 / span 2`, `grid-column:1 / -1`, `grid-column-start:13` |
| Flow / implicit tracks (`§ 6.12`–`6.14`) | `.Grid.Flow.{Row, Col, Dense, RowDense, ColDense}`, `.Grid.AutoCols`/`AutoRows.{Auto, Min, Max, Fr}` | `grid-auto-flow:row dense`, `grid-auto-columns:min-content`, `grid-auto-rows:minmax(0, 1fr)` (via `gridFr()`) |
| Gap (`§ 6.15`) | `.Gap.{All, X, Y}` over the spacing scale | `gap:…`, `column-gap:…`, `row-gap:…`; `.Gap.All.0` → `gap:0` |

**The whole alignment family lives under `Flex` although it applies to grid too**: `align-items` and
`justify-content` were spelled there before, and a grid container writing `.Flex.Justify.Center`
gets the correct CSS. `AlignSelf` and the flat `Place*` exist because `Self` is a language keyword.
The earlier `.Flex.Gap.{1,2,4,8}` paths still compile and emit the same declaration as
`.Gap.All.N`, asserted side by side.

## Acceptance

### Delivered

- [x] `.Flex.Value.One` → `flex:1 1 0%`; `.Flex.Value.None` → `flex:none`; `.Flex.Grow.1`/`.0`;
      `.Flex.Basis.Frac.Third` equals `.Size.W.Frac.Third`'s percentage; `.Flex.Order.First` →
      `order:-9999`, `.Last` → `order:9999`, `.None` → `order:0`; `.Flex.Row/Col/Wrap/NoWrap`
      unchanged.
- [x] `Justify` answers all eight `§ 6.16` values, `Items` all five; `flex-start` and `start` both
      come out of their own tokens; `place-content:space-between`; the family is reachable from a
      grid container (`repository/emilia/examples/emilia-grid`).
- [x] `.Grid.Cols.12` → `repeat(12, minmax(0, 1fr))`; `None`/`Subgrid` are keywords; `Span.2` →
      `span 2 / span 2`, `Span.Full` → `1 / -1`; line 13 exists on both axes and ends;
      `Flow.RowDense` → `row dense`; `AutoCols.Fr` → `minmax(0, 1fr)`; `gridRepeat`/`gridFr` are the
      only spellings of those strings.
- [x] `.Gap.All.4` → `gap:calc(var(--spacing) * 4)`; `.Gap.X.1` → `column-gap`, `.Gap.Y.1` →
      `row-gap`; `.Gap.All.0` → `gap:0`; `.Flex.Gap.4` and `.Gap.All.4` are one declaration;
      `spacing` is called, not copied.
- [x] Every non-arbitrary utility of `§ 6.1`–`§ 6.24` has a token (basis quarters and below
      excepted); no leaf of the 356 resolves a length.
- [x] The three dispatchers use the `val out = case …; return out;` idiom with arrow arms and take
      `th: Theme`; the front-37 banners fence both blocks in front-number position; `Grid`/`Gap` arms
      in front-number order; `repository/emilia/AGENTS.md` and the `tokens.bp` header record the
      sections and the alignment note; green on commonJS and erlang.

## Not declared

- Basis fractions below thirds; every arbitrary form (`grid-cols-[200px_1fr]`, `col-start-[7]`) —
  front 57's `arbValue`.

## Examples

- [`./examples/flex-example.bp`](./examples/flex-example.bp) — direction, wrap, the shorthand,
  grow/shrink/basis, order, the alignment family; a toolbar whose middle item takes the remaining
  space.
- [`./examples/grid-example.bp`](./examples/grid-example.bp) — templates, spans, starts and ends,
  auto-flow, implicit tracks and gap; a twelve-column dashboard reflowing per breakpoint.
