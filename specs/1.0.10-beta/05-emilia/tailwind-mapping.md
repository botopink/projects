# Tailwind CSS → Emilia Mapping Reference

> The complete mapping of every Tailwind CSS v4.3 utility to emilia tokens.
> This document is the implementation reference and the usage guide for consumers. The status
> glyphs are the mapping's own view; the per-front coverage verdicts are in
> [`reference-coverage.md`](./reference-coverage.md), the module cut in [`modules.md`](./modules.md).

---

## Conventions

| Symbol | Meaning |
|---------|------------|
| ✅ | Implemented (v0 or v1) |
| 🔲 | To implement in this milestone |
| ❌ | Not applicable / no equivalent |

**Spacing scale:** `1 = 0.25rem`, `2 = 0.5rem`, `3 = 0.75rem`, `4 = 1rem`, `8 = 2rem`, `12 = 3rem`, `16 = 4rem`, `20 = 5rem`, `24 = 6rem`, `32 = 8rem`, `40 = 10rem`, `48 = 12rem`, `56 = 14rem`, `64 = 16rem`, `72 = 18rem`, `80 = 20rem`, `96 = 24rem`

---

## 1. Layout

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `aspect-auto` | `aspect-ratio: auto` | `Layout.Aspect.Auto` | 🔲 |
| `aspect-square` | `aspect-ratio: 1 / 1` | `Layout.Aspect.Square` | 🔲 |
| `aspect-video` | `aspect-ratio: 16 / 9` | `Layout.Aspect.Video` | 🔲 |
| `columns-1` – `columns-12` | `columns: N` | `Layout.Columns.__1` – `.__12` | 🔲 |
| `columns-auto` | `columns: auto` | `Layout.Columns.Auto` | 🔲 |
| `break-after-auto` | `break-after: auto` | `Layout.BreakAfter.Auto` | 🔲 |
| `break-after-avoid` | `break-after: avoid` | `Layout.BreakAfter.Avoid` | 🔲 |
| `break-after-all` | `break-after: all` | `Layout.BreakAfter.All` | 🔲 |
| `break-after-page` | `break-after: page` | `Layout.BreakAfter.Page` | 🔲 |
| `break-after-left` | `break-after: left` | `Layout.BreakAfter.Left` | 🔲 |
| `break-after-right` | `break-after: right` | `Layout.BreakAfter.Right` | 🔲 |
| `break-after-column` | `break-after: column` | `Layout.BreakAfter.Column` | 🔲 |
| `break-before-*` | (same as break-after) | `Layout.BreakBefore.*` | 🔲 |
| `break-inside-auto` | `break-inside: auto` | `Layout.BreakInside.Auto` | 🔲 |
| `break-inside-avoid` | `break-inside: avoid` | `Layout.BreakInside.Avoid` | 🔲 |
| `break-inside-avoid-page` | `break-inside: avoid-page` | `Layout.BreakInside.AvoidPage` | 🔲 |
| `break-inside-avoid-column` | `break-inside: avoid-column` | `Layout.BreakInside.AvoidColumn` | 🔲 |
| `box-decoration-clone` | `box-decoration-break: clone` | `Layout.BoxDecoration.Clone` | 🔲 |
| `box-decoration-slice` | `box-decoration-break: slice` | `Layout.BoxDecoration.Slice` | 🔲 |
| `box-border` | `box-sizing: border-box` | `Layout.BoxSizing.Border` | 🔲 |
| `box-content` | `box-sizing: content-box` | `Layout.BoxSizing.Content` | 🔲 |
| `block` | `display: block` | `Layout.Block` | ✅ |
| `inline-block` | `display: inline-block` | `Layout.InlineBlock` | ✅ |
| `inline` | `display: inline` | `Layout.Inline` | ✅ |
| `flex` | `display: flex` | `Layout.Flex` | ✅ |
| `inline-flex` | `display: inline-flex` | `Layout.InlineFlex` | 🔲 |
| `grid` | `display: grid` | `Layout.Grid` | ✅ |
| `inline-grid` | `display: inline-grid` | `Layout.InlineGrid` | 🔲 |
| `contents` | `display: contents` | `Layout.Contents` | 🔲 |
| `flow-root` | `display: flow-root` | `Layout.FlowRoot` | 🔲 |
| `list-item` | `display: list-item` | `Layout.ListItem` | 🔲 |
| `hidden` | `display: none` | `Layout.Hidden` | ✅ |
| `float-right` | `float: right` | `Layout.Float.Right` | 🔲 |
| `float-left` | `float: left` | `Layout.Float.Left` | 🔲 |
| `float-none` | `float: none` | `Layout.Float.None` | 🔲 |
| `clear-left` | `clear: left` | `Layout.Clear.Left` | 🔲 |
| `clear-right` | `clear: right` | `Layout.Clear.Right` | 🔲 |
| `clear-both` | `clear: both` | `Layout.Clear.Both` | 🔲 |
| `clear-none` | `clear: none` | `Layout.Clear.None` | 🔲 |
| `isolate` | `isolation: isolate` | `Layout.Isolation.Isolate` | 🔲 |
| `isolation-auto` | `isolation: auto` | `Layout.Isolation.Auto` | 🔲 |
| `object-contain` | `object-fit: contain` | `Layout.ObjectFit.Contain` | 🔲 |
| `object-cover` | `object-fit: cover` | `Layout.ObjectFit.Cover` | 🔲 |
| `object-fill` | `object-fit: fill` | `Layout.ObjectFit.Fill` | 🔲 |
| `object-none` | `object-fit: none` | `Layout.ObjectFit.None` | 🔲 |
| `object-scale-down` | `object-fit: scale-down` | `Layout.ObjectFit.ScaleDown` | 🔲 |
| `object-bottom` | `object-position: bottom` | `Layout.ObjectPosition.Bottom` | 🔲 |
| `object-center` | `object-position: center` | `Layout.ObjectPosition.Center` | 🔲 |
| `object-left` | `object-position: left` | `Layout.ObjectPosition.Left` | 🔲 |
| `object-right` | `object-position: right` | `Layout.ObjectPosition.Right` | 🔲 |
| `object-top` | `object-position: top` | `Layout.ObjectPosition.Top` | 🔲 |
| `overflow-auto` | `overflow: auto` | `Layout.Overflow.Auto` | 🔲 |
| `overflow-hidden` | `overflow: hidden` | `Layout.Overflow.Hidden` | 🔲 |
| `overflow-clip` | `overflow: clip` | `Layout.Overflow.Clip` | 🔲 |
| `overflow-visible` | `overflow: visible` | `Layout.Overflow.Visible` | 🔲 |
| `overflow-scroll` | `overflow: scroll` | `Layout.Overflow.Scroll` | 🔲 |
| `overflow-x-*` | `overflow-x: *` | `Layout.OverflowX.*` | 🔲 |
| `overflow-y-*` | `overflow-y: *` | `Layout.OverflowY.*` | 🔲 |
| `overscroll-auto` | `overscroll-behavior: auto` | `Layout.Overscroll.Auto` | 🔲 |
| `overscroll-contain` | `overscroll-behavior: contain` | `Layout.Overscroll.Contain` | 🔲 |
| `overscroll-none` | `overscroll-behavior: none` | `Layout.Overscroll.None` | 🔲 |
| `static` | `position: static` | `Layout.Position.Static` | 🔲 |
| `fixed` | `position: fixed` | `Layout.Position.Fixed` | 🔲 |
| `absolute` | `position: absolute` | `Layout.Position.Absolute` | 🔲 |
| `relative` | `position: relative` | `Layout.Position.Relative` | 🔲 |
| `sticky` | `position: sticky` | `Layout.Position.Sticky` | 🔲 |
| `top-0` – `top-96` | `top: N` | `Layout.Top.__0` – `.__96` | 🔲 |
| `right-*` | `right: N` | `Layout.Right.*` | 🔲 |
| `bottom-*` | `bottom: N` | `Layout.Bottom.*` | 🔲 |
| `left-*` | `left: N` | `Layout.Left.*` | 🔲 |
| `inset-0` | `inset: 0` | `Layout.Inset.__0` | 🔲 |
| `visible` | `visibility: visible` | `Layout.Visibility.Visible` | 🔲 |
| `invisible` | `visibility: hidden` | `Layout.Visibility.Hidden` | 🔲 |
| `collapse` | `visibility: collapse` | `Layout.Visibility.Collapse` | 🔲 |
| `z-0` – `z-50` | `z-index: N` | `Layout.Z.__0` – `.__50` | 🔲 |
| `z-auto` | `z-index: auto` | `Layout.Z.Auto` | 🔲 |

---

## 2. Flexbox & Grid

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `basis-0` – `basis-full` | `flex-basis: N` | `Flex.Basis.*` | 🔲 |
| `flex-row` | `flex-direction: row` | `Flex.Row` | ✅ |
| `flex-row-reverse` | `flex-direction: row-reverse` | `Flex.RowReverse` | 🔲 |
| `flex-col` | `flex-direction: column` | `Flex.Col` | ✅ |
| `flex-col-reverse` | `flex-direction: column-reverse` | `Flex.ColReverse` | 🔲 |
| `flex-wrap` | `flex-wrap: wrap` | `Flex.Wrap` | ✅ |
| `flex-wrap-reverse` | `flex-wrap: wrap-reverse` | `Flex.WrapReverse` | 🔲 |
| `flex-nowrap` | `flex-wrap: nowrap` | `Flex.NoWrap` | ✅ |
| `flex-1` | `flex: 1 1 0%` | `Flex.Flex1` | 🔲 |
| `flex-auto` | `flex: 1 1 auto` | `Flex.FlexAuto` | 🔲 |
| `flex-initial` | `flex: 0 1 auto` | `Flex.FlexInitial` | 🔲 |
| `flex-none` | `flex: none` | `Flex.FlexNone` | 🔲 |
| `grow` | `flex-grow: 1` | `Flex.Grow` | 🔲 |
| `grow-0` | `flex-grow: 0` | `Flex.Grow0` | 🔲 |
| `shrink` | `flex-shrink: 1` | `Flex.Shrink` | 🔲 |
| `shrink-0` | `flex-shrink: 0` | `Flex.Shrink0` | 🔲 |
| `order-1` – `order-12` | `order: N` | `Flex.Order.__1` – `.__12` | 🔲 |
| `order-first` | `order: -9999` | `Flex.Order.First` | 🔲 |
| `order-last` | `order: 9999` | `Flex.Order.Last` | 🔲 |
| `grid-cols-1` – `grid-cols-12` | `grid-template-columns: repeat(N, ...)` | `Grid.Cols.__1` – `.__12` | 🔲 |
| `grid-cols-none` | `grid-template-columns: none` | `Grid.Cols.None` | 🔲 |
| `col-auto` | `grid-column: auto` | `Grid.Col.Auto` | 🔲 |
| `col-span-1` – `col-span-12` | `grid-column: span N / span N` | `Grid.Col.Span1` – `.Span12` | 🔲 |
| `col-start-1` – `col-start-13` | `grid-column-start: N` | `Grid.ColStart.__1` – `.__13` | 🔲 |
| `col-end-*` | `grid-column-end: N` | `Grid.ColEnd.*` | 🔲 |
| `grid-rows-*` | `grid-template-rows: repeat(N, ...)` | `Grid.Rows.*` | 🔲 |
| `row-span-*` | `grid-row: span N / span N` | `Grid.Row.Span*` | 🔲 |
| `grid-flow-row` | `grid-auto-flow: row` | `Grid.AutoFlow.Row` | 🔲 |
| `grid-flow-col` | `grid-auto-flow: column` | `Grid.AutoFlow.Col` | 🔲 |
| `grid-flow-dense` | `grid-auto-flow: dense` | `Grid.AutoFlow.Dense` | 🔲 |
| `auto-cols-auto` | `grid-auto-columns: auto` | `Grid.AutoCols.Auto` | 🔲 |
| `auto-rows-*` | `grid-auto-rows: *` | `Grid.AutoRows.*` | 🔲 |
| `gap-0` – `gap-24` | `gap: N` | `Flex.Gap.__0` – `.__24` | 🔲 |
| `gap-x-*` | `column-gap: N` | `Flex.GapX.*` | 🔲 |
| `gap-y-*` | `row-gap: N` | `Flex.GapY.*` | 🔲 |
| `justify-start` | `justify-content: flex-start` | `Flex.Justify.Start` | ✅ |
| `justify-center` | `justify-content: center` | `Flex.Justify.Center` | ✅ |
| `justify-end` | `justify-content: flex-end` | `Flex.Justify.End` | ✅ |
| `justify-between` | `justify-content: space-between` | `Flex.Justify.Between` | ✅ |
| `justify-around` | `justify-content: space-around` | `Flex.Justify.Around` | ✅ |
| `justify-evenly` | `justify-content: space-evenly` | `Flex.Justify.Evenly` | 🔲 |
| `justify-items-*` | `justify-items: *` | `Grid.JustifyItems.*` | 🔲 |
| `justify-self-*` | `justify-self: *` | `Grid.JustifySelf.*` | 🔲 |
| `align-content-*` | `align-content: *` | `Flex.AlignContent.*` | 🔲 |
| `items-start` | `align-items: flex-start` | `Flex.Items.Start` | ✅ |
| `items-center` | `align-items: center` | `Flex.Items.Center` | ✅ |
| `items-end` | `align-items: flex-end` | `Flex.Items.End` | ✅ |
| `items-baseline` | `align-items: baseline` | `Flex.Items.Baseline` | 🔲 |
| `items-stretch` | `align-items: stretch` | `Flex.Items.Stretch` | ✅ |
| `self-auto` | `align-self: auto` | `Flex.AlignSelf.Auto` | 🔲 |
| `self-start` | `align-self: flex-start` | `Flex.AlignSelf.Start` | 🔲 |
| `self-center` | `align-self: center` | `Flex.AlignSelf.Center` | 🔲 |
| `self-end` | `align-self: flex-end` | `Flex.AlignSelf.End` | 🔲 |
| `self-stretch` | `align-self: stretch` | `Flex.AlignSelf.Stretch` | 🔲 |
| `place-content-*` | `place-content: *` | `Flex.PlaceContent.*` | 🔲 |
| `place-items-*` | `place-items: *` | `Flex.PlaceItems.*` | 🔲 |
| `place-self-*` | `place-self: *` | `Flex.PlaceSelf.*` | 🔲 |

---

## 3. Spacing

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `p-0` – `p-96` | `padding: N` | `Pad.All.__0` – `.__96` | 🔲 (expanded scale) |
| `px-*` | `padding-left/right: N` | `Pad.X.*` | 🔲 (expanded scale) |
| `py-*` | `padding-top/bottom: N` | `Pad.Y.*` | 🔲 (expanded scale) |
| `pt-*` | `padding-top: N` | `Pad.T.*` | 🔲 |
| `pr-*` | `padding-right: N` | `Pad.R.*` | 🔲 |
| `pb-*` | `padding-bottom: N` | `Pad.B.*` | 🔲 |
| `pl-*` | `padding-left: N` | `Pad.L.*` | 🔲 |
| `ps-*` | `padding-inline-start: N` | `Pad.S.*` | 🔲 |
| `pe-*` | `padding-inline-end: N` | `Pad.E.*` | 🔲 |
| `m-0` – `m-96` | `margin: N` | `Margin.All.*` | 🔲 (expanded scale) |
| `mx-auto` | `margin-left/right: auto` | `Margin.X.Auto` | ✅ |
| `mx-*` | `margin-left/right: N` | `Margin.X.*` | 🔲 |
| `my-*` | `margin-top/bottom: N` | `Margin.Y.*` | 🔲 |
| `mt-*` | `margin-top: N` | `Margin.T.*` | 🔲 |
| `mr-*` | `margin-right: N` | `Margin.R.*` | 🔲 |
| `mb-*` | `margin-bottom: N` | `Margin.B.*` | 🔲 |
| `ml-*` | `margin-left: N` | `Margin.L.*` | 🔲 |
| `-mx-*` | `margin-left/right: -N` | `Margin.NegX.*` | 🔲 |
| `-my-*` | `margin-top/bottom: -N` | `Margin.NegY.*` | 🔲 |

---

## 4. Sizing

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `w-0` – `w-96` | `width: N` | `Size.W.__0` – `.__96` | 🔲 |
| `w-auto` | `width: auto` | `Size.W.Auto` | 🔲 |
| `w-full` | `width: 100%` | `Size.W.Full` | 🔲 |
| `w-screen` | `width: 100vw` | `Size.W.Screen` | 🔲 |
| `w-min` | `width: min-content` | `Size.W.Min` | 🔲 |
| `w-max` | `width: max-content` | `Size.W.Max` | 🔲 |
| `w-fit` | `width: fit-content` | `Size.W.Fit` | 🔲 |
| `min-w-0` | `min-width: 0` | `Size.MinW.__0` | 🔲 |
| `min-w-full` | `min-width: 100%` | `Size.MinW.Full` | 🔲 |
| `max-w-none` | `max-width: none` | `Size.MaxW.None` | 🔲 |
| `max-w-xs` | `max-width: 20rem` | `Size.MaxW.Xs` | 🔲 |
| `max-w-sm` | `max-width: 24rem` | `Size.MaxW.Sm` | 🔲 |
| `max-w-md` | `max-width: 28rem` | `Size.MaxW.Md` | 🔲 |
| `max-w-lg` | `max-width: 32rem` | `Size.MaxW.Lg` | 🔲 |
| `max-w-xl` | `max-width: 36rem` | `Size.MaxW.Xl` | 🔲 |
| `max-w-2xl` – `max-w-7xl` | `max-width: Nrem` | `Size.MaxW.X2xl` – `.X7xl` | 🔲 |
| `max-w-full` | `max-width: 100%` | `Size.MaxW.Full` | 🔲 |
| `h-0` – `h-96` | `height: N` | `Size.H.*` | 🔲 |
| `h-screen` | `height: 100vh` | `Size.H.Screen` | 🔲 |
| `min-h-screen` | `min-height: 100vh` | `Size.MinH.Screen` | 🔲 |
| `max-h-screen` | `max-height: 100vh` | `Size.MaxH.Screen` | 🔲 |
| `size-*` | `width: N; height: N` | ❌ (combine Size.W + Size.H) | — |

---

## 5. Typography

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `font-sans` | `font-family: var(--font-sans)` | `Font.Sans` | ✅ |
| `font-serif` | `font-family: var(--font-serif)` | `Font.Serif` | ✅ |
| `font-mono` | `font-family: var(--font-mono)` | `Font.Mono` | ✅ |
| `text-xs` | `font-size: 0.75rem` | `Text.Size.Xs` | ✅ |
| `text-sm` | `font-size: 0.875rem` | `Text.Size.Sm` | ✅ |
| `text-base` | `font-size: 1rem` | `Text.Size.Base` | ✅ |
| `text-lg` | `font-size: 1.125rem` | `Text.Size.Lg` | ✅ |
| `text-xl` – `text-9xl` | `font-size: N` | `Text.Size.Xl` – `.X9xl` | 🔲 (X5xl–X9xl) |
| `antialiased` | `-webkit-font-smoothing: antialiased` | `Font.Smoothing.Antialiased` | 🔲 |
| `subpixel-antialiased` | `-webkit-font-smoothing: auto` | `Font.Smoothing.Auto` | 🔲 |
| `italic` | `font-style: italic` | `Text.Italic` | ✅ |
| `not-italic` | `font-style: normal` | ❌ (do not apply Text.Italic) | — |
| `font-thin` | `font-weight: 100` | `Font.Weight.Thin` | 🔲 |
| `font-extralight` | `font-weight: 200` | `Font.Weight.Extralight` | 🔲 |
| `font-light` | `font-weight: 300` | `Font.Weight.Light` | ✅ |
| `font-normal` | `font-weight: 400` | `Font.Weight.Normal` | ✅ |
| `font-medium` | `font-weight: 500` | `Font.Weight.Medium` | ✅ |
| `font-semibold` | `font-weight: 600` | `Font.Weight.Semibold` | 🔲 |
| `font-bold` | `font-weight: 700` | `Font.Weight.Bold` | ✅ |
| `font-extrabold` | `font-weight: 800` | `Font.Weight.Extrabold` | 🔲 |
| `font-black` | `font-weight: 900` | `Font.Weight.Black` | ✅ |
| `tracking-tighter` | `letter-spacing: -0.05em` | `Tracking.Tighter` | 🔲 |
| `tracking-tight` | `letter-spacing: -0.025em` | `Tracking.Tight` | 🔲 |
| `tracking-normal` | `letter-spacing: 0em` | `Tracking.Normal` | 🔲 |
| `tracking-wide` | `letter-spacing: 0.025em` | `Tracking.Wide` | 🔲 |
| `tracking-wider` | `letter-spacing: 0.05em` | `Tracking.Wider` | 🔲 |
| `tracking-widest` | `letter-spacing: 0.1em` | `Tracking.Widest` | 🔲 |
| `line-clamp-*` | `-webkit-line-clamp: N` | `Text.LineClamp.*` | 🔲 |
| `leading-*` | `line-height: N` | `Leading.*` | 🔲 |
| `list-none` | `list-style-type: none` | `List.None` | 🔲 |
| `list-disc` | `list-style-type: disc` | `List.Disc` | 🔲 |
| `list-decimal` | `list-style-type: decimal` | `List.Decimal` | 🔲 |
| `list-inside` | `list-style-position: inside` | `List.Inside` | 🔲 |
| `list-outside` | `list-style-position: outside` | `List.Outside` | 🔲 |
| `text-left` | `text-align: left` | `Text.Left` | ✅ |
| `text-center` | `text-align: center` | `Text.Center` | ✅ |
| `text-right` | `text-align: right` | `Text.Right` | ✅ |
| `text-justify` | `text-align: justify` | `Text.Justify` | ✅ |
| `text-start` | `text-align: start` | `Text.Start` | 🔲 |
| `text-end` | `text-align: end` | `Text.End` | 🔲 |
| `underline` | `text-decoration-line: underline` | `Text.Decoration.Underline` | 🔲 |
| `overline` | `text-decoration-line: overline` | `Text.Decoration.Overline` | 🔲 |
| `line-through` | `text-decoration-line: line-through` | `Text.Decoration.LineThrough` | 🔲 |
| `no-underline` | `text-decoration-line: none` | `Text.Decoration.None` | 🔲 |
| `uppercase` | `text-transform: uppercase` | `Text.Transform.Uppercase` | 🔲 |
| `lowercase` | `text-transform: lowercase` | `Text.Transform.Lowercase` | 🔲 |
| `capitalize` | `text-transform: capitalize` | `Text.Transform.Capitalize` | 🔲 |
| `normal-case` | `text-transform: none` | `Text.Transform.None` | 🔲 |
| `truncate` | `overflow:hidden; text-overflow:ellipsis; white-space:nowrap` | `Text.Truncate` | 🔲 |
| `text-wrap` | `text-wrap: wrap` | `Text.Wrap.Wrap` | 🔲 |
| `text-nowrap` | `text-wrap: nowrap` | `Text.Wrap.Nowrap` | 🔲 |
| `text-balance` | `text-wrap: balance` | `Text.Wrap.Balance` | 🔲 |
| `text-pretty` | `text-wrap: pretty` | `Text.Wrap.Pretty` | 🔲 |
| `align-baseline` | `vertical-align: baseline` | `Align.Baseline` | 🔲 |
| `align-top` | `vertical-align: top` | `Align.Top` | 🔲 |
| `align-middle` | `vertical-align: middle` | `Align.Middle` | 🔲 |
| `align-bottom` | `vertical-align: bottom` | `Align.Bottom` | 🔲 |
| `whitespace-normal` | `white-space: normal` | `Whitespace.Normal` | 🔲 |
| `whitespace-nowrap` | `white-space: nowrap` | `Whitespace.Nowrap` | 🔲 |
| `whitespace-pre` | `white-space: pre` | `Whitespace.Pre` | 🔲 |
| `break-normal` | `overflow-wrap: normal` | `Break.Normal` | 🔲 |
| `break-words` | `overflow-wrap: break-word` | `Break.Words` | 🔲 |
| `break-all` | `word-break: break-all` | `Break.All` | 🔲 |
| `hyphens-none` | `hyphens: none` | `Hyphens.None` | 🔲 |
| `hyphens-auto` | `hyphens: auto` | `Hyphens.Auto` | 🔲 |

---

## 6. Backgrounds

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `bg-fixed` | `background-attachment: fixed` | `Bg.Attachment.Fixed` | 🔲 |
| `bg-local` | `background-attachment: local` | `Bg.Attachment.Local` | 🔲 |
| `bg-scroll` | `background-attachment: scroll` | `Bg.Attachment.Scroll` | 🔲 |
| `bg-clip-border` | `background-clip: border-box` | `Bg.Clip.Border` | 🔲 |
| `bg-clip-padding` | `background-clip: padding-box` | `Bg.Clip.Padding` | 🔲 |
| `bg-clip-content` | `background-clip: content-box` | `Bg.Clip.Content` | 🔲 |
| `bg-clip-text` | `background-clip: text` | `Bg.Clip.Text` | 🔲 |
| `bg-{color}` | `background-color: {color}` | `Bg.{Color}.*` | 🔲 (expanded by F14) |
| `bg-none` | `background-image: none` | ❌ (default) | — |
| `bg-gradient-to-t` | `background-image: linear-gradient(...)` | `Gradient.To.T` | 🔲 |
| `bg-gradient-to-r` | `background-image: linear-gradient(...)` | `Gradient.To.R` | 🔲 |
| `bg-gradient-to-b` | `background-image: linear-gradient(...)` | `Gradient.To.B` | 🔲 |
| `from-{color}` | `--tw-gradient-from: {color}` | `Gradient.From.{Color}.*` | 🔲 |
| `via-{color}` | `--tw-gradient-via: {color}` | `Gradient.Via.{Color}.*` | 🔲 |
| `to-{color}` | `--tw-gradient-to: {color}` | `Gradient.To.{Color}.*` | 🔲 |
| `bg-origin-border` | `background-origin: border-box` | `Bg.Origin.Border` | 🔲 |
| `bg-origin-padding` | `background-origin: padding-box` | `Bg.Origin.Padding` | 🔲 |
| `bg-origin-content` | `background-origin: content-box` | `Bg.Origin.Content` | 🔲 |
| `bg-bottom` | `background-position: bottom` | `Bg.Position.Bottom` | 🔲 |
| `bg-center` | `background-position: center` | `Bg.Position.Center` | 🔲 |
| `bg-left` | `background-position: left` | `Bg.Position.Left` | 🔲 |
| `bg-right` | `background-position: right` | `Bg.Position.Right` | 🔲 |
| `bg-top` | `background-position: top` | `Bg.Position.Top` | 🔲 |
| `bg-repeat` | `background-repeat: repeat` | `Bg.Repeat.Repeat` | 🔲 |
| `bg-no-repeat` | `background-repeat: no-repeat` | `Bg.Repeat.NoRepeat` | 🔲 |
| `bg-repeat-x` | `background-repeat: repeat-x` | `Bg.Repeat.RepeatX` | 🔲 |
| `bg-repeat-y` | `background-repeat: repeat-y` | `Bg.Repeat.RepeatY` | 🔲 |
| `bg-auto` | `background-size: auto` | `Bg.Size.Auto` | 🔲 |
| `bg-cover` | `background-size: cover` | `Bg.Size.Cover` | 🔲 |
| `bg-contain` | `background-size: contain` | `Bg.Size.Contain` | 🔲 |

---

## 7. Borders

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `rounded-none` | `border-radius: 0` | `Border.Rounded.None` | 🔲 |
| `rounded-sm` | `border-radius: 0.125rem` | `Border.Rounded.Sm` | ✅ |
| `rounded` | `border-radius: 0.25rem` | `Border.Rounded.Md` | ✅ |
| `rounded-md` | `border-radius: 0.375rem` | `Border.Rounded.Md` | ✅ |
| `rounded-lg` | `border-radius: 0.5rem` | `Border.Rounded.Lg` | ✅ |
| `rounded-xl` | `border-radius: 0.75rem` | `Border.Rounded.Xl` | 🔲 |
| `rounded-2xl` | `border-radius: 1rem` | `Border.Rounded.X2xl` | 🔲 |
| `rounded-3xl` | `border-radius: 1.5rem` | `Border.Rounded.X3xl` | 🔲 |
| `rounded-full` | `border-radius: 9999px` | `Border.Rounded.Full` | ✅ |
| `rounded-t-*` | `border-top-left/right-radius: *` | `Border.RoundedT.*` | 🔲 |
| `rounded-r-*` | `border-top-right/bottom-right-radius: *` | `Border.RoundedR.*` | 🔲 |
| `rounded-b-*` | `border-bottom-right/left-radius: *` | `Border.RoundedB.*` | 🔲 |
| `rounded-l-*` | `border-top-left/bottom-left-radius: *` | `Border.RoundedL.*` | 🔲 |
| `border-0` | `border-width: 0px` | `Border.W.__0` | ✅ |
| `border` | `border-width: 1px` | `Border.W.__1` | ✅ |
| `border-2` | `border-width: 2px` | `Border.W.__2` | ✅ |
| `border-4` | `border-width: 4px` | `Border.W.__4` | ✅ |
| `border-8` | `border-width: 8px` | `Border.W.__8` | 🔲 |
| `border-solid` | `border-style: solid` | `Border.Style.Solid` | 🔲 |
| `border-dashed` | `border-style: dashed` | `Border.Style.Dashed` | 🔲 |
| `border-dotted` | `border-style: dotted` | `Border.Style.Dotted` | 🔲 |
| `border-double` | `border-style: double` | `Border.Style.Double` | 🔲 |
| `border-none` | `border-style: none` | `Border.Style.None` | 🔲 |
| `border-{color}` | `border-color: {color}` | `Border.Color.{Color}.*` | 🔲 |
| `outline-0` – `outline-8` | `outline-width: Npx` | `Outline.W.*` | 🔲 |
| `outline-none` | `outline: 2px solid transparent` | `Outline.Style.None` | 🔲 |
| `outline` | `outline-style: solid` | `Outline.Style.Solid` | 🔲 |
| `outline-dashed` | `outline-style: dashed` | `Outline.Style.Dashed` | 🔲 |
| `outline-dotted` | `outline-style: dotted` | `Outline.Style.Dotted` | 🔲 |
| `outline-{color}` | `outline-color: {color}` | `Outline.Color.{Color}.*` | 🔲 |
| `outline-offset-0` – `outline-offset-8` | `outline-offset: Npx` | `Outline.Offset.*` | 🔲 |

---

## 8. Effects

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `shadow-2xs` | `box-shadow: 0 1px rgb(0 0 0 / 0.05)` | `Effect.Shadow.__2xs` | 🔲 |
| `shadow-xs` | `box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05)` | `Effect.Shadow.Xs` | 🔲 |
| `shadow-sm` | `box-shadow: ...` | `Effect.Shadow.Sm` | ✅ |
| `shadow-md` | `box-shadow: ...` | `Effect.Shadow.Md` | ✅ |
| `shadow-lg` | `box-shadow: ...` | `Effect.Shadow.Lg` | ✅ |
| `shadow-xl` | `box-shadow: ...` | `Effect.Shadow.Xl` | ✅ |
| `shadow-2xl` | `box-shadow: 0 25px 50px -12px ...` | `Effect.Shadow.X2xl` | 🔲 |
| `shadow-none` | `box-shadow: none` | `Effect.Shadow.None` | 🔲 |
| `shadow-inner` | `box-shadow: inset 0 2px 4px ...` | `Effect.Shadow.Inner` | 🔲 |
| `text-shadow-*` | `text-shadow: ...` | `Effect.TextShadow.*` | 🔲 |
| `opacity-0` – `opacity-100` | `opacity: N` | `Effect.Opacity.*` | 🔲 (expanded scale) |
| `mix-blend-*` | `mix-blend-mode: *` | `Blend.*` | 🔲 |
| `bg-blend-*` | `background-blend-mode: *` | `BgBlend.*` | 🔲 |
| `mask-*` | `mask-*: *` | `Mask.*` | 🔲 |

---

## 9. Filters

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `blur-none` | `filter: none` | `Filter.Blur.None` | 🔲 |
| `blur-sm` | `filter: blur(8px)` | `Filter.Blur.Sm` | 🔲 |
| `blur-md` | `filter: blur(12px)` | `Filter.Blur.Md` | 🔲 |
| `blur-lg` | `filter: blur(16px)` | `Filter.Blur.Lg` | 🔲 |
| `blur-xl` | `filter: blur(24px)` | `Filter.Blur.Xl` | 🔲 |
| `brightness-*` | `filter: brightness(N)` | `Filter.Brightness.*` | 🔲 |
| `contrast-*` | `filter: contrast(N)` | `Filter.Contrast.*` | 🔲 |
| `drop-shadow-*` | `filter: drop-shadow(...)` | `Filter.DropShadow.*` | 🔲 |
| `grayscale-0` | `filter: grayscale(0)` | `Filter.Grayscale.__0` | 🔲 |
| `grayscale` | `filter: grayscale(100%)` | `Filter.Grayscale.Full` | 🔲 |
| `hue-rotate-*` | `filter: hue-rotate(Ndeg)` | `Filter.HueRotate.*` | 🔲 |
| `invert-0` | `filter: invert(0)` | `Filter.Invert.__0` | 🔲 |
| `invert` | `filter: invert(100%)` | `Filter.Invert.Full` | 🔲 |
| `saturate-*` | `filter: saturate(N)` | `Filter.Saturate.*` | 🔲 |
| `sepia-0` | `filter: sepia(0)` | `Filter.Sepia.__0` | 🔲 |
| `sepia` | `filter: sepia(100%)` | `Filter.Sepia.Full` | 🔲 |
| `backdrop-blur-*` | `backdrop-filter: blur(Npx)` | `BackdropFilter.Blur.*` | 🔲 |
| `backdrop-brightness-*` | `backdrop-filter: brightness(N)` | `BackdropFilter.Brightness.*` | 🔲 |
| `backdrop-contrast-*` | `backdrop-filter: contrast(N)` | `BackdropFilter.Contrast.*` | 🔲 |
| `backdrop-grayscale-*` | `backdrop-filter: grayscale(N)` | `BackdropFilter.Grayscale.*` | 🔲 |
| `backdrop-hue-rotate-*` | `backdrop-filter: hue-rotate(Ndeg)` | `BackdropFilter.HueRotate.*` | 🔲 |
| `backdrop-invert-*` | `backdrop-filter: invert(N)` | `BackdropFilter.Invert.*` | 🔲 |
| `backdrop-opacity-*` | `backdrop-filter: opacity(N)` | `BackdropFilter.Opacity.*` | 🔲 |
| `backdrop-saturate-*` | `backdrop-filter: saturate(N)` | `BackdropFilter.Saturate.*` | 🔲 |
| `backdrop-sepia-*` | `backdrop-filter: sepia(N)` | `BackdropFilter.Sepia.*` | 🔲 |

---

## 10. Tables

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `border-collapse` | `border-collapse: collapse` | `Table.BorderCollapse.Collapse` | 🔲 |
| `border-separate` | `border-collapse: separate` | `Table.BorderCollapse.Separate` | 🔲 |
| `border-spacing-*` | `border-spacing: N` | `Table.BorderSpacing.*` | 🔲 |
| `table-auto` | `table-layout: auto` | `Table.Layout.Auto` | 🔲 |
| `table-fixed` | `table-layout: fixed` | `Table.Layout.Fixed` | 🔲 |
| `caption-top` | `caption-side: top` | `Table.CaptionSide.Top` | 🔲 |
| `caption-bottom` | `caption-side: bottom` | `Table.CaptionSide.Bottom` | 🔲 |

---

## 11. Transitions & Animation

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `transition-none` | `transition-property: none` | `Transition.None` | 🔲 |
| `transition-all` | `transition-property: all` | `Transition.All` | 🔲 |
| `transition` | `transition: (default properties)` | `Transition.Default` | 🔲 |
| `transition-colors` | `transition-property: colors` | `Transition.Colors` | 🔲 |
| `transition-opacity` | `transition-property: opacity` | `Transition.Opacity` | 🔲 |
| `transition-shadow` | `transition-property: box-shadow` | `Transition.Shadow` | 🔲 |
| `transition-transform` | `transition-property: transform` | `Transition.Transform` | 🔲 |
| `duration-*` | `transition-duration: Nms` | `Transition.Duration.*` | 🔲 |
| `ease-linear` | `transition-timing-function: linear` | `Transition.Ease.Linear` | 🔲 |
| `ease-in` | `transition-timing-function: ease-in` | `Transition.Ease.In` | 🔲 |
| `ease-out` | `transition-timing-function: ease-out` | `Transition.Ease.Out` | 🔲 |
| `ease-in-out` | `transition-timing-function: ease-in-out` | `Transition.Ease.InOut` | 🔲 |
| `delay-*` | `transition-delay: Nms` | `Transition.Delay.*` | 🔲 |
| `animate-none` | `animation: none` | `Animate.None` | 🔲 |
| `animate-spin` | `animation: spin 1s linear infinite` | `Animate.Spin` | 🔲 |
| `animate-ping` | `animation: ping 1s ... infinite` | `Animate.Ping` | 🔲 |
| `animate-pulse` | `animation: pulse 2s ... infinite` | `Animate.Pulse` | 🔲 |
| `animate-bounce` | `animation: bounce 1s infinite` | `Animate.Bounce` | 🔲 |

---

## 12. Transforms

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `rotate-0` – `rotate-180` | `transform: rotate(Ndeg)` | `Transform.Rotate.*` | 🔲 |
| `-rotate-*` | `transform: rotate(-Ndeg)` | `Transform.NegRotate.*` | 🔲 |
| `scale-0` – `scale-150` | `transform: scale(N)` | `Transform.Scale.*` | 🔲 |
| `scale-x-*` | `transform: scaleX(N)` | `Transform.ScaleX.*` | 🔲 |
| `scale-y-*` | `transform: scaleY(N)` | `Transform.ScaleY.*` | 🔲 |
| `skew-x-*` | `transform: skewX(Ndeg)` | `Transform.SkewX.*` | 🔲 |
| `skew-y-*` | `transform: skewY(Ndeg)` | `Transform.SkewY.*` | 🔲 |
| `translate-x-*` | `transform: translateX(N)` | `Transform.TranslateX.*` | 🔲 |
| `translate-y-*` | `transform: translateY(N)` | `Transform.TranslateY.*` | 🔲 |
| `-translate-x-*` | `transform: translateX(-N)` | `Transform.NegTranslateX.*` | 🔲 |
| `-translate-y-*` | `transform: translateY(-N)` | `Transform.NegTranslateY.*` | 🔲 |
| `origin-center` | `transform-origin: center` | `Transform.Origin.Center` | 🔲 |
| `origin-top` | `transform-origin: top` | `Transform.Origin.Top` | 🔲 |
| `perspective-*` | `perspective: Npx` | `Transform.Perspective.*` | 🔲 |
| `backface-visible` | `backface-visibility: visible` | `Transform.Backface.Visible` | 🔲 |
| `backface-hidden` | `backface-visibility: hidden` | `Transform.Backface.Hidden` | 🔲 |

---

## 13. Interactivity

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `cursor-pointer` | `cursor: pointer` | `Interact.Cursor.Pointer` | 🔲 |
| `cursor-default` | `cursor: default` | `Interact.Cursor.Default` | 🔲 |
| `cursor-not-allowed` | `cursor: not-allowed` | `Interact.Cursor.NotAllowed` | 🔲 |
| `pointer-events-none` | `pointer-events: none` | `Interact.PointerEvents.None` | 🔲 |
| `pointer-events-auto` | `pointer-events: auto` | `Interact.PointerEvents.Auto` | 🔲 |
| `resize-none` | `resize: none` | `Interact.Resize.None` | 🔲 |
| `resize-y` | `resize: vertical` | `Interact.Resize.Y` | 🔲 |
| `resize-x` | `resize: horizontal` | `Interact.Resize.X` | 🔲 |
| `resize` | `resize: both` | `Interact.Resize.Both` | 🔲 |
| `scroll-auto` | `scroll-behavior: auto` | `Interact.ScrollBehavior.Auto` | 🔲 |
| `scroll-smooth` | `scroll-behavior: smooth` | `Interact.ScrollBehavior.Smooth` | 🔲 |
| `scrollbar-thin` | `scrollbar-width: thin` | `Interact.ScrollbarWidth.Thin` | 🔲 |
| `scrollbar-none` | `scrollbar-width: none` | `Interact.ScrollbarWidth.None` | 🔲 |
| `snap-start` | `scroll-snap-align: start` | `Interact.SnapAlign.Start` | 🔲 |
| `snap-center` | `scroll-snap-align: center` | `Interact.SnapAlign.Center` | 🔲 |
| `snap-x` | `scroll-snap-type: x` | `Interact.SnapType.X` | 🔲 |
| `snap-y` | `scroll-snap-type: y` | `Interact.SnapType.Y` | 🔲 |
| `snap-mandatory` | `--tw-scroll-snap-strictness: mandatory` | `Interact.SnapStrictness.Mandatory` | 🔲 |
| `touch-none` | `touch-action: none` | `Interact.TouchAction.None` | 🔲 |
| `touch-manipulation` | `touch-action: manipulation` | `Interact.TouchAction.Manipulation` | 🔲 |
| `select-none` | `user-select: none` | `Interact.UserSelect.None` | 🔲 |
| `select-text` | `user-select: text` | `Interact.UserSelect.Text` | 🔲 |
| `select-all` | `user-select: all` | `Interact.UserSelect.All` | 🔲 |
| `will-change-transform` | `will-change: transform` | `Interact.WillChange.Transform` | 🔲 |
| `appearance-none` | `appearance: none` | `Interact.Appearance.None` | 🔲 |
| `accent-{color}` | `accent-color: {color}` | `Interact.AccentColor.{Color}.*` | 🔲 |
| `caret-{color}` | `caret-color: {color}` | `Interact.CaretColor.{Color}.*` | 🔲 |
| `field-sizing-content` | `field-sizing: content` | `Interact.FieldSizing.Content` | 🔲 |

---

## 14. SVG

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `fill-none` | `fill: none` | `Svg.Fill.None` | 🔲 |
| `fill-current` | `fill: currentColor` | `Svg.Fill.Current` | 🔲 |
| `fill-{color}` | `fill: {color}` | `Svg.Fill.{Color}.*` | 🔲 |
| `stroke-none` | `stroke: none` | `Svg.Stroke.None` | 🔲 |
| `stroke-current` | `stroke: currentColor` | `Svg.Stroke.Current` | 🔲 |
| `stroke-{color}` | `stroke: {color}` | `Svg.Stroke.{Color}.*` | 🔲 |
| `stroke-0` | `stroke-width: 0` | `Svg.StrokeWidth.__0` | 🔲 |
| `stroke-1` | `stroke-width: 1` | `Svg.StrokeWidth.__1` | 🔲 |
| `stroke-2` | `stroke-width: 2` | `Svg.StrokeWidth.__2` | 🔲 |

---

## 15. Accessibility

| Tailwind | CSS | Emilia Token | Status |
|----------|-----|-------------|--------|
| `sr-only` | `position:absolute;width:1px;height:1px;...` | `A11y.SrOnly` | 🔲 |
| `not-sr-only` | `position:static;width:auto;height:auto;...` | `A11y.NotSrOnly` | 🔲 |
| `forced-color-adjust-auto` | `forced-color-adjust: auto` | `A11y.ForcedColorAdjust.Auto` | 🔲 |
| `forced-color-adjust-none` | `forced-color-adjust: none` | `A11y.ForcedColorAdjust.None` | 🔲 |

---

## 16. Modifiers (Variants)

| Tailwind Prefix | CSS | Emilia Modifier | Status |
|----------------|-----|----------------|--------|
| `sm:` | `@media (width >= 640px)` | `Sm([...])` | 🔲 |
| `md:` | `@media (width >= 768px)` | `Md([...])` | ✅ |
| `lg:` | `@media (width >= 1024px)` | `Lg([...])` | ✅ |
| `xl:` | `@media (width >= 1280px)` | `Xl([...])` | ✅ |
| `2xl:` | `@media (width >= 1536px)` | `X2xl([...])` | 🔲 |
| `max-sm:` | `@media (width < 640px)` | `MaxSm([...])` | 🔲 |
| `max-md:` | `@media (width < 768px)` | `MaxMd([...])` | 🔲 |
| `dark:` | `@media (prefers-color-scheme: dark)` | `Dark([...])` | 🔲 |
| `hover:` | `:hover` | `Hover([...])` | ✅ |
| `focus:` | `:focus` | `Focus([...])` | ✅ |
| `focus-visible:` | `:focus-visible` | `FocusVisible([...])` | 🔲 |
| `focus-within:` | `:focus-within` | `FocusWithin([...])` | 🔲 |
| `active:` | `:active` | `Active([...])` | ✅ |
| `visited:` | `:visited` | `Visited([...])` | 🔲 |
| `first:` | `:first-child` | `First([...])` | 🔲 |
| `last:` | `:last-child` | `Last([...])` | 🔲 |
| `only:` | `:only-child` | `Only([...])` | 🔲 |
| `odd:` | `:nth-child(odd)` | `Odd([...])` | 🔲 |
| `even:` | `:nth-child(even)` | `Even([...])` | 🔲 |
| `empty:` | `:empty` | `Empty([...])` | 🔲 |
| `disabled:` | `:disabled` | `Disabled([...])` | 🔲 |
| `enabled:` | `:enabled` | `Enabled([...])` | 🔲 |
| `checked:` | `:checked` | `Checked([...])` | 🔲 |
| `required:` | `:required` | `Required([...])` | 🔲 |
| `invalid:` | `:invalid` | `Invalid([...])` | 🔲 |
| `valid:` | `:valid` | `Valid([...])` | 🔲 |
| `placeholder:` | `::placeholder` | `Placeholder([...])` | 🔲 |
| `before:` | `::before` | `Before([...])` | 🔲 |
| `after:` | `::after` | `After([...])` | 🔲 |
| `selection:` | `::selection` | `Selection([...])` | 🔲 |
| `marker:` | `::marker` | `Marker([...])` | 🔲 |
| `first-line:` | `::first-line` | `FirstLine([...])` | 🔲 |
| `first-letter:` | `::first-letter` | `FirstLetter([...])` | 🔲 |
| `file:` | `::file-selector-button` | `File([...])` | 🔲 |
| `backdrop:` | `::backdrop` | `Backdrop([...])` | 🔲 |
| `group-hover:` | `.group:hover &` | `GroupHover([...])` | 🔲 |
| `group-focus:` | `.group:focus &` | `GroupFocus([...])` | 🔲 |
| `peer-focus:` | `.peer:focus ~ &` | `PeerFocus([...])` | 🔲 |
| `peer-checked:` | `.peer:checked ~ &` | `PeerChecked([...])` | 🔲 |
| `print:` | `@media print` | `Print([...])` | 🔲 |
| `motion-reduce:` | `@media (prefers-reduced-motion: reduce)` | `MotionReduce([...])` | 🔲 |
| `motion-safe:` | `@media (prefers-reduced-motion: no-preference)` | `MotionSafe([...])` | 🔲 |
| `portrait:` | `@media (orientation: portrait)` | `Portrait([...])` | 🔲 |
| `landscape:` | `@media (orientation: landscape)` | `Landscape([...])` | 🔲 |
| `contrast-more:` | `@media (prefers-contrast: more)` | `ContrastMore([...])` | 🔲 |
| `rtl:` | `[dir="rtl"] &` | `Rtl([...])` | 🔲 |
| `ltr:` | `[dir="ltr"] &` | `Ltr([...])` | 🔲 |
| `open:` | `&[open]` | `Open([...])` | 🔲 |
| `inert:` | `&:is([inert], [inert] *)` | `Inert([...])` | 🔲 |
| `@sm:` | `@container (width >= 24rem)` | `ContainerSm([...])` | 🔲 |
| `@md:` | `@container (width >= 28rem)` | `ContainerMd([...])` | 🔲 |
| `@lg:` | `@container (width >= 32rem)` | `ContainerLg([...])` | 🔲 |

---

## Coverage Summary

| Category | Tailwind Utils | Emilia Today | Emilia After This Milestone | Final Coverage |
|-----------|---------------|-------------|-------------------|----------------|
| Layout | ~60 | 6 | ~60 | 100% |
| Flexbox & Grid | ~60 | 14 | ~60 | 100% |
| Spacing | ~40 | 12 | ~40 | 100% |
| Sizing | ~40 | 0 | ~40 | 100% |
| Typography | ~50 | 15 | ~50 | 100% |
| Backgrounds | ~30 | 8 | ~30 | 100% |
| Borders | ~30 | 10 | ~30 | 100% |
| Effects | ~30 | 9 | ~30 | 100% |
| Filters | ~40 | 0 | ~40 | 100% |
| Tables | 6 | 0 | 6 | 100% |
| Transitions & Animation | ~20 | 0 | ~20 | 100% |
| Transforms | ~30 | 0 | ~30 | 100% |
| Interactivity | ~30 | 0 | ~30 | 100% |
| SVG | 6 | 0 | 6 | 100% |
| Accessibility | 4 | 0 | 4 | 100% |
| Modifiers | ~50 | 6 | ~50 | 100% |
| Colors | ~200 | ~20 | ~200 | 100% |
| **Total** | **~700** | **~100** | **~700** | **100%** |
