# Front 37 — emilia-flexbox-and-grid

**Track:** D emilia
**Priority:** high — emilia can say `display:flex` and then nothing. A flex item cannot grow, shrink, reorder or set a basis, and grid has no token at all, so no two-dimensional layout is expressible.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 3
**Depends on:** 54 (`Theme`, `spacing(n)` — `Gap` and `Flex.Basis` call it), 56 (`declSheet` — this front emits declarations only, no selector)
**Owns:** `repository/emilia/src/tokens.bp` (the `Flex` and `Grid` sections and the new top-level `Gap` section) · `repository/emilia/src/emilia.bp` (`flexTokenToCss`, `gridTokenToCss`, `gapTokenToCss` and their sub-dispatchers) · `repository/emilia/test/grid_test.bp`
**Does not touch:** `Layout` (front 36) — `display:flex` and `display:grid` are display values and stay there; `Pad`/`Margin`/`Size` (front 35)
**Reference:** `TAILWIND_CSS_DOCS.md § 6. Flexbox & Grid` (6.1–6.24) · https://tailwindcss.com/docs/flex-basis

---

**Scope note.** `fronts.md` gives this front the name `37-emilia-grid` and the token section `Grid`.
That was an ownership defect: `Flex` already exists in `tokens.bp` and was assigned to no front, and
`Gap` was listed under front 35 in `fronts.md` and under this front in `overview.md`. The
coordinator resolved both — **this front owns `Grid`, `Flex` and `Gap`**, which is also how Tailwind
cuts it: `§ 6` is one chapter covering flexbox, grid and the gap that separates the items of either.
The directory name stays `37-emilia-grid`, because front numbers and directory names are frozen
identifiers.

---

## Problem

`Flex` today (`tokens.bp:194-218`) has four bare leaves — `Row`, `Col`, `Wrap`, `NoWrap` — plus
`Items`, `Justify` and a four-value `Gap`. `§ 6` has twenty-four property groups. Missing from flex
alone: `flex-row-reverse`, `flex-col-reverse`, `flex-wrap-reverse`, the `flex` shorthand
(`flex-1`, `flex-auto`, `flex-initial`, `flex-none`), `flex-grow`, `flex-shrink`, `flex-basis` and
`order`. A flex item therefore cannot be told to take the remaining space, which is the reason most
people reach for flexbox in the first place.

Alignment is a third present. `Flex.Items` has four of the five `align-items` values (no
`baseline`); `Flex.Justify` has five of the eight `justify-content` values (no `normal`, no
`evenly`, no `stretch`). `align-self`, `align-content`, `justify-items`, `justify-self`,
`place-content`, `place-items` and `place-self` have no token at all — seven of `§ 6`'s twenty-four
groups.

Grid does not exist. `.Layout.Grid` emits `display:grid` and there is nothing to put in it: no
`grid-template-columns`, no span, no start or end, no auto-flow, no auto-columns or auto-rows.

`Flex.Gap` exists with four values and the wrong scope — `gap` applies to grid as much as to flex,
and it has an `x` and a `y` form (`§ 6.15`) that emilia has no spelling for.

## Current state

| What | Where | State |
|---|---|---|
| `Flex { Row, Col, Wrap, NoWrap }` | `tokens.bp:195-198` | 4 of the 7 direction/wrap values |
| `Flex.Items { Start, Center, End, Stretch }` | `tokens.bp:199-204` | 4 of 5 |
| `Flex.Justify { Start, Center, End, Between, Around }` | `tokens.bp:205-211` | 5 of 8 |
| `Flex.Gap { 1, 2, 4, 8 }` | `tokens.bp:212-217` | 4 values, no axis forms |
| `flexTokenToCss` + `flexItemsToCss` + `flexJustifyToCss` + `flexGapScale` | `emilia.bp:274-316` | emit valid CSS; `gap:` is correct |
| `Grid` | — | no section |
| grow / shrink / basis / order / the `flex` shorthand | — | no tokens |
| self / content / justify-items / justify-self / place-* | — | no tokens |

`flexTokenToCss` is one of the dispatchers that already emits correct CSS. This front widens it and
corrects nothing.

## Mechanism

`§ 6` splits three ways and the token tree follows the split:

- **`Flex`** — properties that only make sense on a flex container or a flex item: direction, wrap,
  the `flex` shorthand, grow, shrink, basis, order.
- **`Grid`** — properties that only make sense on a grid container or a grid item: templates, spans,
  starts, ends, auto-flow, auto-columns, auto-rows.
- **`Gap`** — a new top-level section, because `gap`, `column-gap` and `row-gap` apply to both.

Alignment (`§ 6.16`–`§ 6.24`) applies to both too, and emilia already puts `align-items` and
`justify-content` under `Flex`. Moving them would rename a token that compiles today, which the
milestone forbids, so the whole alignment family stays under `Flex` and the README says why. A grid
container writes `.Flex.Justify.Center` and gets `justify-content:center`, which is the correct CSS
for a grid; only the token's spelling reads as though it were flex-only.

Two numeric families call front 54's `spacing(n)`: `Gap` and `Flex.Basis`. `§ 6.15` prints `gap-1`
as `calc(var(--spacing) * 1)` and `§ 6.1` prints `basis-1` the same way, so sharing the fn is not a
convenience — it is what makes them agree. Per contract 4a in [`contracts.md`](../../contracts.md),
`spacing(n)` never resolves to a `rem`, and every sub-dispatcher here has the shape
`fn <name>(t: Token.<Section>.<Sub>, th: Theme) -> string`.

`grid-template-columns` is the one family where the emitted value is a function of the leaf rather
than a lookup: `§ 6.8` prints `repeat(N, minmax(0, 1fr))`. One fn builds it from the leaf's numeral
so that adding a column count is one line, not two.

## Token surface

### Flex direction and wrap — `§ 6.2`, `§ 6.3`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `flex-row` | `.Flex.Row` | `flex-direction:row` |
| `flex-row-reverse` | `.Flex.RowReverse` | `flex-direction:row-reverse` |
| `flex-col` | `.Flex.Col` | `flex-direction:column` |
| `flex-col-reverse` | `.Flex.ColReverse` | `flex-direction:column-reverse` |
| `flex-wrap` | `.Flex.Wrap` | `flex-wrap:wrap` |
| `flex-wrap-reverse` | `.Flex.WrapReverse` | `flex-wrap:wrap-reverse` |
| `flex-nowrap` | `.Flex.NoWrap` | `flex-wrap:nowrap` |

### The flex shorthand, grow, shrink, basis, order — `§ 6.1`, `§ 6.4`–`§ 6.7`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `flex-1` | `.Flex.Value.One` | `flex:1 1 0%` |
| `flex-auto` | `.Flex.Value.Auto` | `flex:1 1 auto` |
| `flex-initial` | `.Flex.Value.Initial` | `flex:0 1 auto` |
| `flex-none` | `.Flex.Value.None` | `flex:none` |
| `grow` | `.Flex.Grow.1` | `flex-grow:1` |
| `grow-0` | `.Flex.Grow.0` | `flex-grow:0` |
| `shrink` | `.Flex.Shrink.1` | `flex-shrink:1` |
| `shrink-0` | `.Flex.Shrink.0` | `flex-shrink:0` |
| `basis-0` | `.Flex.Basis.0` | `flex-basis:0` |
| `basis-1` | `.Flex.Basis.1` | `flex-basis:calc(var(--spacing) * 1)` |
| `basis-auto` | `.Flex.Basis.Auto` | `flex-basis:auto` |
| `basis-full` | `.Flex.Basis.Full` | `flex-basis:100%` |
| `basis-1/2` | `.Flex.Basis.Frac.Half` | `flex-basis:50%` |
| `basis-1/3` | `.Flex.Basis.Frac.Third` | `flex-basis:33.333333%` |
| `basis-2/3` | `.Flex.Basis.Frac.TwoThirds` | `flex-basis:66.666667%` |
| `order-1` | `.Flex.Order.1` | `order:1` |
| `order-2` | `.Flex.Order.2` | `order:2` |
| `order-12` | `.Flex.Order.12` | `order:12` |
| `order-first` | `.Flex.Order.First` | `order:-9999` |
| `order-last` | `.Flex.Order.Last` | `order:9999` |
| `order-none` | `.Flex.Order.None` | `order:0` |

`Value` rather than `Flex` for the shorthand: a section cannot carry a sub-section of its own name.

### Alignment — `§ 6.16`–`§ 6.24`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `justify-normal` | `.Flex.Justify.Normal` | `justify-content:normal` |
| `justify-start` | `.Flex.Justify.Start` | `justify-content:flex-start` |
| `justify-end` | `.Flex.Justify.End` | `justify-content:flex-end` |
| `justify-center` | `.Flex.Justify.Center` | `justify-content:center` |
| `justify-between` | `.Flex.Justify.Between` | `justify-content:space-between` |
| `justify-around` | `.Flex.Justify.Around` | `justify-content:space-around` |
| `justify-evenly` | `.Flex.Justify.Evenly` | `justify-content:space-evenly` |
| `justify-stretch` | `.Flex.Justify.Stretch` | `justify-content:stretch` |
| `justify-items-start` | `.Flex.JustifyItems.Start` | `justify-items:start` |
| `justify-items-end` | `.Flex.JustifyItems.End` | `justify-items:end` |
| `justify-items-center` | `.Flex.JustifyItems.Center` | `justify-items:center` |
| `justify-items-stretch` | `.Flex.JustifyItems.Stretch` | `justify-items:stretch` |
| `justify-self-auto` | `.Flex.JustifySelf.Auto` | `justify-self:auto` |
| `justify-self-start` | `.Flex.JustifySelf.Start` | `justify-self:start` |
| `justify-self-end` | `.Flex.JustifySelf.End` | `justify-self:end` |
| `justify-self-center` | `.Flex.JustifySelf.Center` | `justify-self:center` |
| `justify-self-stretch` | `.Flex.JustifySelf.Stretch` | `justify-self:stretch` |
| `items-start` | `.Flex.Items.Start` | `align-items:flex-start` |
| `items-end` | `.Flex.Items.End` | `align-items:flex-end` |
| `items-center` | `.Flex.Items.Center` | `align-items:center` |
| `items-baseline` | `.Flex.Items.Baseline` | `align-items:baseline` |
| `items-stretch` | `.Flex.Items.Stretch` | `align-items:stretch` |
| `self-auto` | `.Flex.Self.Auto` | `align-self:auto` |
| `self-start` | `.Flex.Self.Start` | `align-self:flex-start` |
| `self-end` | `.Flex.Self.End` | `align-self:flex-end` |
| `self-center` | `.Flex.Self.Center` | `align-self:center` |
| `self-stretch` | `.Flex.Self.Stretch` | `align-self:stretch` |
| `self-baseline` | `.Flex.Self.Baseline` | `align-self:baseline` |
| `content-normal` | `.Flex.Content.Normal` | `align-content:normal` |
| `content-center` | `.Flex.Content.Center` | `align-content:center` |
| `content-start` | `.Flex.Content.Start` | `align-content:flex-start` |
| `content-end` | `.Flex.Content.End` | `align-content:flex-end` |
| `content-between` | `.Flex.Content.Between` | `align-content:space-between` |
| `content-around` | `.Flex.Content.Around` | `align-content:space-around` |
| `content-evenly` | `.Flex.Content.Evenly` | `align-content:space-evenly` |
| `content-stretch` | `.Flex.Content.Stretch` | `align-content:stretch` |
| `place-content-center` | `.Flex.Place.Content.Center` | `place-content:center` |
| `place-content-start` | `.Flex.Place.Content.Start` | `place-content:start` |
| `place-content-end` | `.Flex.Place.Content.End` | `place-content:end` |
| `place-content-between` | `.Flex.Place.Content.Between` | `place-content:space-between` |
| `place-content-around` | `.Flex.Place.Content.Around` | `place-content:space-around` |
| `place-content-evenly` | `.Flex.Place.Content.Evenly` | `place-content:space-evenly` |
| `place-content-stretch` | `.Flex.Place.Content.Stretch` | `place-content:stretch` |
| `place-items-start` | `.Flex.Place.Items.Start` | `place-items:start` |
| `place-items-end` | `.Flex.Place.Items.End` | `place-items:end` |
| `place-items-center` | `.Flex.Place.Items.Center` | `place-items:center` |
| `place-items-stretch` | `.Flex.Place.Items.Stretch` | `place-items:stretch` |
| `place-self-auto` | `.Flex.Place.Self.Auto` | `place-self:auto` |
| `place-self-start` | `.Flex.Place.Self.Start` | `place-self:start` |
| `place-self-end` | `.Flex.Place.Self.End` | `place-self:end` |
| `place-self-center` | `.Flex.Place.Self.Center` | `place-self:center` |
| `place-self-stretch` | `.Flex.Place.Self.Stretch` | `place-self:stretch` |

Note the asymmetry `§ 6` documents and this front copies without smoothing: `justify-content` and
`align-items` use `flex-start`/`flex-end`, while `justify-items`, `justify-self` and the `place-*`
family use `start`/`end`. `align-self` uses `flex-start`/`flex-end`; `align-content` uses
`flex-start`/`flex-end` too.

### Grid templates and placement — `§ 6.8`–`§ 6.11`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `grid-cols-1` | `.Grid.Cols.1` | `grid-template-columns:repeat(1, minmax(0, 1fr))` |
| `grid-cols-2` | `.Grid.Cols.2` | `grid-template-columns:repeat(2, minmax(0, 1fr))` |
| `grid-cols-6` | `.Grid.Cols.6` | `grid-template-columns:repeat(6, minmax(0, 1fr))` |
| `grid-cols-12` | `.Grid.Cols.12` | `grid-template-columns:repeat(12, minmax(0, 1fr))` |
| `grid-cols-none` | `.Grid.Cols.None` | `grid-template-columns:none` |
| `grid-cols-subgrid` | `.Grid.Cols.Subgrid` | `grid-template-columns:subgrid` |
| `grid-rows-1` | `.Grid.Rows.1` | `grid-template-rows:repeat(1, minmax(0, 1fr))` |
| `grid-rows-3` | `.Grid.Rows.3` | `grid-template-rows:repeat(3, minmax(0, 1fr))` |
| `grid-rows-none` | `.Grid.Rows.None` | `grid-template-rows:none` |
| `grid-rows-subgrid` | `.Grid.Rows.Subgrid` | `grid-template-rows:subgrid` |
| `col-auto` | `.Grid.Col.Auto` | `grid-column:auto` |
| `col-span-1` | `.Grid.Col.Span.1` | `grid-column:span 1 / span 1` |
| `col-span-2` | `.Grid.Col.Span.2` | `grid-column:span 2 / span 2` |
| `col-span-full` | `.Grid.Col.Span.Full` | `grid-column:1 / -1` |
| `col-start-1` | `.Grid.Col.Start.1` | `grid-column-start:1` |
| `col-start-auto` | `.Grid.Col.Start.Auto` | `grid-column-start:auto` |
| `col-end-1` | `.Grid.Col.End.1` | `grid-column-end:1` |
| `col-end-auto` | `.Grid.Col.End.Auto` | `grid-column-end:auto` |
| `row-auto` | `.Grid.Row.Auto` | `grid-row:auto` |
| `row-span-1` | `.Grid.Row.Span.1` | `grid-row:span 1 / span 1` |
| `row-span-full` | `.Grid.Row.Span.Full` | `grid-row:1 / -1` |
| `row-start-1` | `.Grid.Row.Start.1` | `grid-row-start:1` |
| `row-end-1` | `.Grid.Row.End.1` | `grid-row-end:1` |

### Grid flow and implicit tracks — `§ 6.12`–`§ 6.14`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `grid-flow-row` | `.Grid.Flow.Row` | `grid-auto-flow:row` |
| `grid-flow-col` | `.Grid.Flow.Col` | `grid-auto-flow:column` |
| `grid-flow-dense` | `.Grid.Flow.Dense` | `grid-auto-flow:dense` |
| `grid-flow-row-dense` | `.Grid.Flow.RowDense` | `grid-auto-flow:row dense` |
| `grid-flow-col-dense` | `.Grid.Flow.ColDense` | `grid-auto-flow:column dense` |
| `auto-cols-auto` | `.Grid.AutoCols.Auto` | `grid-auto-columns:auto` |
| `auto-cols-min` | `.Grid.AutoCols.Min` | `grid-auto-columns:min-content` |
| `auto-cols-max` | `.Grid.AutoCols.Max` | `grid-auto-columns:max-content` |
| `auto-cols-fr` | `.Grid.AutoCols.Fr` | `grid-auto-columns:minmax(0, 1fr)` |
| `auto-rows-auto` | `.Grid.AutoRows.Auto` | `grid-auto-rows:auto` |
| `auto-rows-min` | `.Grid.AutoRows.Min` | `grid-auto-rows:min-content` |
| `auto-rows-max` | `.Grid.AutoRows.Max` | `grid-auto-rows:max-content` |
| `auto-rows-fr` | `.Grid.AutoRows.Fr` | `grid-auto-rows:minmax(0, 1fr)` |

### Gap — `§ 6.15`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `gap-0` | `.Gap.All.0` | `gap:0` |
| `gap-1` | `.Gap.All.1` | `gap:calc(var(--spacing) * 1)` |
| `gap-2` | `.Gap.All.2` | `gap:calc(var(--spacing) * 2)` |
| `gap-4` | `.Gap.All.4` | `gap:calc(var(--spacing) * 4)` |
| `gap-x-1` | `.Gap.X.1` | `column-gap:calc(var(--spacing) * 1)` |
| `gap-y-1` | `.Gap.Y.1` | `row-gap:calc(var(--spacing) * 1)` |
| `gap-px` | `.Gap.All.Px` | `gap:1px` |

The existing `.Flex.Gap.{1,2,4,8}` paths keep working and keep emitting `gap:` — they are the same
declaration by a narrower name. The new `Gap` section is where the scale, the axes and the pixel
step live.

## Steps

### Step 1 — the flex item properties

`Value`, `Grow`, `Shrink`, `Basis`, `Order`, plus the three reverse direction/wrap leaves.

**Acceptance:**
- [x] `.Flex.Value.One` emits `flex:1 1 0%` — three components, spaces as `§ 6.4` prints them — held: test "the flex shorthand keeps all three components, and `none` is a keyword"
- [x] `.Flex.Value.None` emits `flex:none`, not `flex:0 0 auto` — held: test "the flex shorthand keeps all three components, and `none` is a keyword"
- [x] `.Flex.Grow.1` emits `flex-grow:1`; `.Flex.Grow.0` emits `flex-grow:0` — held: test "grow and shrink are bare numbers on their own properties"
- [x] `.Flex.Basis.Frac.Third` emits `flex-basis:33.333333%` and agrees with `.Size.W.Frac.Third`'s
      percentage, asserted directly — held: test "a basis fraction and a width fraction are the same percentage"
- [x] `.Flex.Order.First` emits `order:-9999` and `.Flex.Order.Last` emits `order:9999` — held: test "order — a count, the two sentinels, and the one that is not a keyword"
- [x] `.Flex.Order.None` emits `order:0`, not `order:none` — held: test "order — a count, the two sentinels, and the one that is not a keyword"
- [x] `.Flex.Row`, `.Flex.Col`, `.Flex.Wrap`, `.Flex.NoWrap` emit exactly what they emit today — held: test "flex direction and wrap — the four that compile today, unchanged"

### Step 2 — the alignment family

Seven new sub-sections (`JustifyItems`, `JustifySelf`, `Self`, `Content`, `Place.Content`,
`Place.Items`, `Place.Self`), plus the four leaves missing from `Justify` and the one missing from
`Items`.

**Acceptance:**
- [x] `Justify` answers all eight `§ 6.16` values — held: test "justify-content — all eight values of `§ 6.16`, three of them new"
- [x] `Items` answers all five `§ 6.20` values, `Baseline` included — held: test "align-items — all five values of `§ 6.20`, `baseline` included"
- [x] `justify-content:flex-start` and `justify-items:start` are both emitted, from different tokens —
      the asymmetry is asserted rather than normalised — held: test "`flex-start` and `start` are both right, and each from its own token"
- [x] `place-content-between` emits `place-content:space-between` — held: test "the three `place-*` shorthands, and `place-content-between` spells space"
- [x] every alignment token is reachable from a grid container as well as a flex one, which is a
      documentation claim the README makes and the grid example exercises — held (shape: `Self` is a keyword, so `Flex.AlignSelf` and flat `Flex.PlaceContent`/`PlaceItems`/`PlaceSelf`): `AGENTS.md` front-37 paragraph + `tokens.bp` `////` Flex note; `examples/emilia-grid/src/main.bp` uses the family on grid containers

### Step 3 — `Grid`

```bp
    Grid {
        Cols { 1, …, 12, None, Subgrid }
        Rows { 1, …, 12, None, Subgrid }
        Col { Auto, Span { 1, …, 12, Full }, Start { 1, …, 13, Auto }, End { 1, …, 13, Auto } }
        Row { Auto, Span { 1, …, 12, Full }, Start { 1, …, 13, Auto }, End { 1, …, 13, Auto } }
        Flow { Row, Col, Dense, RowDense, ColDense }
        AutoCols { Auto, Min, Max, Fr }
        AutoRows { Auto, Min, Max, Fr }
    }
```

`Start` and `End` run to 13 because a twelve-column grid has thirteen lines.

```bp
fn gridRepeat(n: string) -> string {
    return "repeat(" + n + ", minmax(0, 1fr))";
}
```

**Acceptance:**
- [x] `.Grid.Cols.12` emits `grid-template-columns:repeat(12, minmax(0, 1fr))` — one space after the
      comma, in both places — held: test "a column template is a repeat built from the leaf, with its spaces"
- [x] `.Grid.Cols.None` and `.Grid.Cols.Subgrid` emit the keyword, not a `repeat()` — held: test "`none` and `subgrid` are keywords, not a repeat of anything"
- [x] `.Grid.Col.Span.2` emits `grid-column:span 2 / span 2` and `.Grid.Col.Span.Full` emits
      `grid-column:1 / -1` — held: test "a span is doubled, and `full` is the line-based form instead"
- [x] `.Grid.Col.Start.13` resolves — the thirteenth line exists — held: test "the thirteenth line exists, on both axes and on both ends"
- [x] `.Grid.Flow.RowDense` emits `grid-auto-flow:row dense` with a single space — held: test "auto-flow keeps one space, and `col` is `column` in the value"
- [x] `.Grid.AutoCols.Fr` emits `grid-auto-columns:minmax(0, 1fr)` — held: test "the implicit tracks — `min`/`max` are `-content`, `fr` is a minmax"
- [x] `gridRepeat` is the only place `repeat(…, minmax(0, 1fr))` is spelled — held: `emilia.bp:gridRepeat`/`gridFr`; test "`gridRepeat` and `gridFr` are the only places those two strings live"

### Step 4 — the top-level `Gap` section

```bp
    Gap {
        All { 0, 1, …, 96, Px, Half { 0, 1, 2, 3 } }
        X { … }
        Y { … }
    }
```

**Acceptance:**
- [x] `.Gap.All.4` emits `gap:calc(var(--spacing) * 4)` — held: test "gap — the shorthand over the ladder, and zero is the literal 0"
- [x] `.Gap.X.1` emits `column-gap:…` and `.Gap.Y.1` emits `row-gap:…` — held: test "gap — the two axes are two different properties"
- [x] `.Gap.All.0` emits `gap:0` — held: test "gap — the shorthand over the ladder, and zero is the literal 0"
- [x] `.Flex.Gap.4` still emits `gap:1rem`'s replacement — the same string `.Gap.All.4` emits,
      asserted side by side, so the two spellings cannot drift — held: test "`.Flex.Gap.N` and `.Gap.All.N` are one declaration by two names"
- [x] front 54's `spacing` is called, not copied, and `.Gap.All.4` reads `calc(var(--spacing) * 4)` — held: `gapScale*` call `spacing`/`spacingHalf`; test "gap reads front 54's ladder, so halving `--spacing` moves no rule"

### Step 5 — the three dispatchers and the top-level arms

`flexTokenToCss` is widened; `gridTokenToCss` and `gapTokenToCss` are new, all three with the
contract-4a signature. Two arms are added to the top-level `tokenToSheet` case (`Grid`, `Gap`);
`Flex` already has one. All three go through `declSheet` — no token in this front needs a selector.

**Acceptance:**
- [x] each dispatcher follows the file's `val out = case …; return out;` idiom and takes `th: Theme` — held: `flexTokenToCss`/`gridTokenToCss`/`gapTokenToCss` and every sub-dispatcher take `th: Theme`
- [x] every arm is an arrow arm — held: every arm in the front-37 block of `emilia.bp` is `X -> expr;`
- [x] the banner `// ── front 37 — flexbox, grid and gap ──` fences the block in both files — held: `tokens.bp:1220` and `emilia.bp:6512`, each closed by `// ── end front 37 ──`
- [x] the two new top-level arms sit in front-number order — held: `emilia.bp:tokenToSheet` — `Grid`/`Gap` after `Flex`, before front 40's `Border`

## Examples

- `./examples/flex-example.bp` — direction, wrap, the shorthand, grow/shrink/basis, order and the
  whole alignment family; ends with a toolbar whose middle item takes the remaining space.
- `./examples/grid-example.bp` — templates, spans, starts and ends, auto-flow, implicit tracks and
  gap; ends with a twelve-column dashboard whose panels span different widths per breakpoint.

## Language gaps

None — every construct in this front's examples parses today.

## Reference gaps

| Item | Why it is missing | What implementation must do |
|---|---|---|
| `grid-cols-7` … `grid-cols-11` | `§ 6.8` prints 1–6 and 12 | this front declares 1–12 by interpolation; confirm the set against upstream before merge |
| `col-span-3` … `col-span-12`, `col-start-2` … | `§ 6.9` prints `col-span-1`, `col-span-2`, `col-span-full`, `col-start-1`, `col-end-1` | same — the pattern is unambiguous, the extent is not documented locally |
| `order-3` … `order-12` | `§ 6.7` prints `order-1`, `order-2` and the three keywords | same |
| `basis-*` beyond the three printed fractions | `§ 6.1` prints `1/2`, `1/3`, `2/3` | quarters and below are not declared by this front |
| `gap` scale extent | `§ 6.15` prints `0`, `1`, `2`, `4` | the scale is front 35's, which `§ 21.2` describes as open; the closed leaf set is a library decision |

## Test plan

`repository/emilia/test/grid_test.bp`, flat, bare-importing across `src`. Run with `botopink test`
from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`.

What the tests assert:

1. **Flex direction and wrap** — seven asserts, four of them regressions on today's output.
2. **The shorthand** — four asserts, each on the exact multi-component value.
3. **Grow, shrink, basis, order** — including `First`/`Last`/`None` and the basis/width fraction
   cross-check.
4. **Alignment** — one test per sub-section, and one test dedicated to the
   `flex-start`-vs-`start` asymmetry, asserting both spellings come out of the right tokens.
5. **Grid templates** — `repeat()` construction at 1, 6 and 12, plus `none` and `subgrid`.
6. **Grid placement** — spans, `full`, starts and ends including line 13.
7. **Flow and implicit tracks** — every leaf.
8. **Gap** — the shorthand, both axes, and the `.Flex.Gap.4` / `.Gap.All.4` equality.
9. **End to end** — `emilia([.Layout.Grid, .Grid.Cols.12, .Gap.All.4])` then `await flush()`,
   asserting the whole `<style>` block.

## Definition of done

- [x] every utility in `§ 6.1`–`§ 6.24` that is not an arbitrary-value form has a token — held (shape: basis quarters and below left out, as the spec's reference gap says): `tokens.bp` `Flex`/`Grid`/`Gap`; test "regression — no leaf of this front resolves a length; all 356 declare"
- [x] `Flex`'s existing nine paths emit byte-identical CSS afterwards — held (shape: `.Flex.Gap.{1,2,4,8}` deliberately moved from `rem` to the `spacing` reference, per Step 4): tests "flex direction and wrap — the four that compile today, unchanged" + "`.Flex.Gap.N` and `.Gap.All.N` are one declaration by two names"
- [x] `Grid` and `Gap` exist as sections, with `Gap` shared by flex and grid — held: `tokens.bp` top-level `Grid` and `Gap`; `examples/emilia-grid` uses `Gap` on flex and grid
- [x] `gridRepeat` is spelled once, and `spacing` comes from front 54 — held: test "`gridRepeat` and `gridFr` are the only places those two strings live"; test "regression — `Gap` and `Basis` are the ladder `Pad` is, property aside"
- [x] the banner fences this front's block in both files, appended at the end — held (shape: block sits in front-number position, not at file end): `tokens.bp:1220`, `emilia.bp:6512`
- [x] two arms added to the top-level `tokenToCss` case, in front-number order — held: `emilia.bp:tokenToSheet` `Grid`/`Gap` arms
- [x] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new sections and
      the note that alignment lives under `Flex` while applying to grid — held: `AGENTS.md` front-37 paragraph ("The whole alignment family stays under `Flex`…"); `tokens.bp` `////` SECTIONS `Flex`/`Grid`/`Gap`
- [x] the front's tests are green on its assigned target — here, both backends, since emilia is comptime — held: emilia suite 569/569 on commonJS and erlang
