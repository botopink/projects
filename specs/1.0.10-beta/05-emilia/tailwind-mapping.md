# Tailwind CSS → emilia mapping

> Every Tailwind CSS v4.3 utility family and the emilia token that emits it, in the spelling the
> library ships. The per-front detail is in each front's README; the section-by-section coverage
> walk is [`reference-coverage.md`](./reference-coverage.md); the user reference is
> `repository/emilia/docs.md`.

---

## Conventions

- A token is written as a path under `Token` (`.Pad.All.4`, or `Token.Hover(inner)` for a modifier).
  A numeric leaf is bare digits in expression position (`.Pad.All.4`) and `__4` in a `case` pattern;
  both spellings are accepted in expression position.
- emilia writes `prop:value` with no space after the colon; the **value** is Tailwind's.
- **No leaf resolves a theme value.** Spacing is `calc(var(--spacing) * N)` (`spacing(n)`), a named
  width is `var(--container-*)`, a colour is `var(--color-<family>-<shade>)`, radii, shadows, blurs,
  perspectives, easings and animations are `var(--…)` references; the values live in `fullTheme()`.
- **Payload variants are top-level** (`Token.Alpha(…)`, `Token.Arb(…)`, `Token.SvgFill(…)`) with a
  builder function each, because a payload leaf nested in a section cannot be constructed.
- **Spacing scale** (every spacing family): `0 1 2 3 4 5 6 7 8 9 10 11 12 14 16 20 24 28 32 36 40 44
  48 52 56 60 64 72 80 96`, `Px` (`1px`), `Half.{0,1,2,3}` (`0.5` … `3.5`), and `Neg.*` where a
  negative exists. `0` is the bare `0`.
- ❌ marks a Tailwind utility emilia does not declare; the arbitrary-value form is always available
  through front 57 (`arbValue`, `arbProp`, `arbSel`, `arbAt`, `arbMin`, `arbMax`).

---

## 1. Layout — front 36

| Tailwind | emilia token | CSS |
|---|---|---|
| `block` `inline-block` `inline` `flex` `inline-flex` `grid` `inline-grid` `contents` `flow-root` `list-item` | `.Layout.Block` … `.Layout.ListItem` | `display:<value>` |
| `hidden` | `.Layout.Hidden` | `display:none` |
| `aspect-auto` / `-square` / `-video` | `.Layout.Aspect.{Auto, Square, Video}` | `aspect-ratio:auto` / `1 / 1` / `16 / 9` |
| `columns-1` `-2` `-3` / `columns-auto` | `.Layout.Columns.{1, 2, 3, Auto}` | `columns:2` |
| `columns-3xs` … `columns-7xl` | `.Layout.Columns.{X3xs … X7xl}` | `columns:var(--container-md)` |
| `columns-4` … `columns-12` | ❌ | — |
| `break-after-*` / `break-before-*` / `break-inside-*` | `.Layout.BreakAfter.*` / `.BreakBefore.*` / `.BreakInside.*` | `break-after:page` … |
| `box-border` / `box-content` | `.Layout.Box.{Border, Content}` | `box-sizing:border-box` / `content-box` |
| `box-decoration-clone` / `-slice` | `.Layout.BoxDecoration.{Clone, Slice}` | `box-decoration-break:clone` / `slice` |
| `float-start` `-end` `-right` `-left` `-none` | `.Layout.Float.{Start, End, Right, Left, None}` | `float:inline-start` … |
| `clear-start` `-end` `-left` `-right` `-both` `-none` | `.Layout.Clear.*` | `clear:inline-start` … |
| `isolate` / `isolation-auto` | `.Layout.Isolation.{Isolate, Auto}` | `isolation:isolate` / `auto` |
| `object-contain` … `object-scale-down` | `.Layout.Object.Fit.*` | `object-fit:<value>` |
| `object-bottom` … `object-top` (9) | `.Layout.Object.Pos.*` | `object-position:left bottom` … |
| `overflow-*`, `overflow-x-*`, `overflow-y-*` | `.Layout.Overflow.*`, `.Overflow.X.*`, `.Overflow.Y.*` | `overflow[-x\|-y]:auto` … |
| `overscroll-*` (and `-x`, `-y`) | `.Layout.Overscroll.*`, `.X.*`, `.Y.*` | `overscroll-behavior[-x\|-y]:contain` … |
| `static` `fixed` `absolute` `relative` `sticky` | `.Layout.Position.*` | `position:<value>` |
| `inset-*` `inset-x-*` `inset-y-*` `top-*` `right-*` `bottom-*` `left-*` `start-*` `end-*` | `.Layout.Inset.{All, X, Y, T, R, B, L, S, E}` + `Auto`, `Full`, `Frac.{Half, Third, TwoThirds}`, `Neg.*` | `inset:0`; `left:0;right:0`; `top:calc(var(--spacing) * 4)`; `top:50%`; `inset-inline-start:0` |
| `visible` / `invisible` / `collapse` | `.Layout.Visibility.{Visible, Invisible, Collapse}` | `visibility:visible` / `hidden` / `collapse` |
| `z-0` … `z-50` / `z-auto` | `.Layout.Z.{0, 10, 20, 30, 40, 50, Auto}` | `z-index:50` |

## 2. Flexbox, grid and gap — front 37

| Tailwind | emilia token | CSS |
|---|---|---|
| `flex-row` `-row-reverse` `-col` `-col-reverse` | `.Flex.{Row, RowReverse, Col, ColReverse}` | `flex-direction:<value>` |
| `flex-wrap` `-wrap-reverse` `-nowrap` | `.Flex.{Wrap, WrapReverse, NoWrap}` | `flex-wrap:<value>` |
| `flex-1` `-auto` `-initial` `-none` | `.Flex.Value.{One, Auto, Initial, None}` | `flex:1 1 0%` … `flex:none` |
| `grow` / `grow-0`, `shrink` / `shrink-0` | `.Flex.Grow.{1, 0}`, `.Flex.Shrink.{1, 0}` | `flex-grow:1` … |
| `basis-*` | `.Flex.Basis` over the spacing scale + `Auto`, `Full`, `Frac.{Half, Third, TwoThirds}` | `flex-basis:calc(var(--spacing) * 4)`, `flex-basis:33.333333%` |
| `order-1` … `order-12` / `order-first` / `-last` / `-none` | `.Flex.Order.{1 … 12, First, Last, None}` | `order:-9999` / `9999` / `0` |
| `justify-*` (8) | `.Flex.Justify.*` | `justify-content:flex-start` … `space-evenly` |
| `justify-items-*` / `justify-self-*` | `.Flex.JustifyItems.*` / `.Flex.JustifySelf.*` | `justify-items:start` … |
| `items-*` (5) / `self-*` / `content-*` | `.Flex.Items.*` / `.Flex.AlignSelf.*` / `.Flex.Content.*` | `align-items:flex-start` … |
| `place-content-*` / `place-items-*` / `place-self-*` | `.Flex.PlaceContent.*` / `.PlaceItems.*` / `.PlaceSelf.*` | `place-content:space-between` … |
| `grid-cols-1` … `-12` / `-none` / `-subgrid` (rows likewise) | `.Grid.Cols.*` / `.Grid.Rows.*` | `grid-template-columns:repeat(12, minmax(0, 1fr))` |
| `col-auto`, `col-span-N`, `col-span-full`, `col-start-N`, `col-end-N` (rows likewise) | `.Grid.Col.{Auto, Span.{1…12, Full}, Start.{1…13, Auto}, End.{1…13, Auto}}` / `.Grid.Row.*` | `grid-column:span 2 / span 2`; `grid-column:1 / -1` |
| `grid-flow-row` `-col` `-dense` `-row-dense` `-col-dense` | `.Grid.Flow.*` | `grid-auto-flow:row dense` |
| `auto-cols-*` / `auto-rows-*` | `.Grid.AutoCols.*` / `.Grid.AutoRows.*` | `grid-auto-columns:minmax(0, 1fr)` |
| `gap-*` / `gap-x-*` / `gap-y-*` | `.Gap.{All, X, Y}` over the spacing scale | `gap:…` / `column-gap:…` / `row-gap:…` |

## 3. Spacing — front 35

| Tailwind | emilia token | CSS |
|---|---|---|
| `p-*` `px-*` `py-*` `pt-*` `pr-*` `pb-*` `pl-*` `ps-*` `pe-*` | `.Pad.{All, X, Y, T, R, B, L, S, E}.*` | `padding:calc(var(--spacing) * 4)`; axes are two declarations; `S`/`E` → `padding-inline-start`/`-end` |
| `m-*` … `me-*`, `m-auto` …, `-m-*` … | `.Margin.{All, X, Y, T, R, B, L, S, E}.*` + `Auto`, `Neg.*` | `margin-top:calc(var(--spacing) * -4)`; `margin-left:auto;margin-right:auto` |
| `space-x-*` / `space-y-*` / `-reverse` | `.Space.{X, Y}.*`, `.Space.{XReverse, YReverse}` | a rule on `:where(& > :not(:last-child))` with upstream's reverse-aware start/end margins |

## 4. Sizing — front 35

| Tailwind | emilia token | CSS |
|---|---|---|
| `w-*` / `h-*` | `.Size.W.*` / `.Size.H.*`: the scale, `Frac.*` (11), `Full`, `Screen`, `Svw`/`Lvw`/`Dvw` (`Svh`/`Lvh`/`Dvh`), `Min`, `Max`, `Fit`, `Auto` | `width:33.333333%`; `width:100vw`; `height:100vh` |
| `size-*` | `.Size.Both.*` | `width:…;height:…` |
| `min-w-*` `max-w-*` `min-h-*` `max-h-*` | `.Size.{MinW, MaxW, MinH, MaxH}.*` | `max-width:var(--container-md)`; `max-width:var(--breakpoint-2xl)` (`MaxW.Screen.*`) |
| `inline-*` `block-*` and their min/max | `.Size.{Inline, Block, MinInline, MaxInline, MinBlock, MaxBlock}.*` | `inline-size:…` |

## 5. Typography — front 38

| Tailwind | emilia token | CSS |
|---|---|---|
| `font-sans` `-serif` `-mono` | `.Font.{Sans, Serif, Mono}` | `font-family:var(--font-sans)` |
| `text-xs` … `text-9xl` | `.Text.Size.{Xs, Sm, Base, Lg, Xl, X2xl … X9xl}` | `font-size:var(--text-lg);line-height:var(--text-lg--line-height)` |
| `font-thin` … `font-black` | `.Font.Weight.{Thin, Extralight, Light, Normal, Medium, Semibold, Bold, Extrabold, Black}` | `font-weight:100` … `900` |
| `antialiased` / `subpixel-antialiased` | `.Font.Smoothing.{Antialiased, Subpixel}` | `-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale` |
| `italic` / `not-italic` | `.Font.Style.{Italic, Normal}` (`.Text.Italic` also emits `font-style:italic`) | `font-style:italic` / `normal` |
| `font-stretch-*` / numeric variants | `.Font.Stretch.*` (9) / `.Font.Nums.*` (9) | `font-stretch:condensed`; `font-variant-numeric:tabular-nums` |
| `tracking-*` / `leading-*` | `.Text.Tracking.*` (6) / `.Text.Leading.*` (6) | `letter-spacing:var(--tracking-tight)`; `line-height:var(--leading-snug)`; `leading-none` → `line-height:1` |
| `line-clamp-N` / `-none` | `.Text.Clamp.{1…6, None}` | `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:N` |
| `text-left` … `text-end` | `.Text.{Left, Center, Right, Justify, Start, End}` | `text-align:<value>` |
| `underline` `overline` `line-through` `no-underline` | `.Text.{Underline, Overline, LineThrough, NoUnderline}` | `text-decoration-line:<value>` |
| `decoration-*` (style, thickness, colour), `underline-offset-*` | `.Text.Decoration.{Style, Thickness, Color, Offset}.*` | `text-decoration-color:var(--color-red-500)` … |
| `uppercase` … `normal-case` | `.Text.Transform.*` | `text-transform:<value>` |
| `truncate` / `text-ellipsis` / `text-clip` | `.Text.Truncate` / `.Text.Overflow.{Ellipsis, Clip}` | `overflow:hidden;text-overflow:ellipsis;white-space:nowrap` |
| `text-wrap` `-nowrap` `-balance` `-pretty` | `.Text.Wrap.*` | `text-wrap:<value>` |
| `indent-*` | `.Text.Indent.*` | `text-indent:calc(var(--spacing) * 8)` |
| `align-*` (8) | `.Text.Align.*` | `vertical-align:<value>` |
| `whitespace-*` (6) | `.Text.Whitespace.*` | `white-space:<value>` |
| `break-normal` `-words` `-all` `-keep` | `.Text.Break.*` | `overflow-wrap:normal;word-break:normal` … |
| `wrap-normal` `-break-word` `-anywhere` | `.Text.OverflowWrap.*` | `overflow-wrap:<value>` |
| `hyphens-*` / `tab-*` / `content-none` / `content-['']` | `.Text.Hyphens.*` / `.Text.Tab.{0, 2, 4, 8}` / `.Text.Content.{None, Empty}` | `content:""` |
| `list-none` `-disc` `-decimal` `-inside` `-outside` `list-image-none` | `.List.*` | `list-style-type:disc` … |

## 6. Colour — front 33

| Tailwind | emilia token | CSS |
|---|---|---|
| `text-<family>-<shade>` (26 × 11) | `.Color.<Family>.<shade>` | `color:var(--color-red-500)` |
| `text-white` `-black` `-transparent` `-current` `-inherit` | `.Color.{White, Black, Transparent, Current, Inherit}` | `color:var(--color-white)`; `color:currentColor` |
| `bg-<family>-<shade>` and the named five | `.Bg.Color.*` | `background-color:var(--color-red-500)` |
| `<utility>/N` | `Token.Alpha(percent: N, inner: […])` | `<prop>:color-mix(in oklab, <value> N%, transparent)` |

## 7. Backgrounds — front 39

| Tailwind | emilia token | CSS |
|---|---|---|
| `bg-fixed` `-local` `-scroll` | `.Bg.Attachment.*` | `background-attachment:<value>` |
| `bg-clip-*` / `bg-origin-*` | `.Bg.Clip.{Border, Padding, Content, Text}` / `.Bg.Origin.*` | `background-clip:border-box` … `text` |
| `bg-bottom` … `bg-top` (9) | `.Bg.Pos.*` | `background-position:left bottom` |
| `bg-repeat` `-no-repeat` `-repeat-x` `-repeat-y` `-repeat-round` `-repeat-space` | `.Bg.Repeat.{Repeat, None, X, Y, Round, Space}` | `background-repeat:no-repeat` … |
| `bg-auto` `-cover` `-contain` | `.Bg.Size.*` | `background-size:<value>` |
| `bg-none` | `.Bg.Image.None` | `background-image:none` |
| `bg-gradient-to-*` (8) | `.Gradient.To.{T, Tr, R, Br, B, Bl, L, Tl}` | `background-image:linear-gradient(to top right, var(--tw-gradient-stops))` |
| `from-*` / `via-*` / `to-*` | `.Gradient.From.*` / `.Via.*` / `.Stop.*` | `--tw-gradient-from:var(--color-indigo-500);--tw-gradient-stops:…` |
| stop positions, `bg-radial`, `bg-conic`, interpolation suffixes | ❌ | — |

## 8. Borders, outlines, rings, divides — front 40

| Tailwind | emilia token | CSS |
|---|---|---|
| `border` `border-0` `-2` `-4` `-8`, `border-x-*` … `border-e-*` | `.Border.W.{0, 1, 2, 4, 8}`, `.Border.W.{X, Y, T, R, B, L, S, E}.*` | `border-width:1px`; `border-left-width:1px;border-right-width:1px` |
| `border-solid` … `border-none` | `.Border.Style.{Solid, Dashed, Dotted, Double, Hidden, None}` | `border-style:<value>` |
| `border-<colour>` | `.Border.Color.*` | `border-color:var(--color-slate-200)` |
| `rounded-*` and the 14 directional forms | `.Border.Rounded.{None, Xs, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, Full}` and `.Border.Rounded.{T, R, B, L, Tl, Tr, Br, Bl, S, E, Ss, Se, Es, Ee}.*` | `border-radius:var(--radius-lg)`; `Full` → `9999px` |
| `outline-*` width, style, colour, offset | `.Outline.{W, Style, Color, Offset}.*` | `outline-width:2px`; `Style.None` → `outline:2px solid transparent;outline-offset:2px` |
| `ring-*`, `ring-<colour>`, `ring-offset-*`, `ring-inset` | `.Ring.{W, Color, Offset.W, Offset.Color, Inset}` | `--tw-ring-shadow:…` plus the five-channel `box-shadow` reader |
| `divide-x-*` `divide-y-*` colour, style, reverse | `.Divide.{X, Y, Color, Style, XReverse, YReverse}` | a rule on `:where(& > :not(:last-child))` |
| `outline-hidden` | ❌ | — |

## 9. Effects — front 41

| Tailwind | emilia token | CSS |
|---|---|---|
| `shadow-2xs` … `shadow-2xl`, `shadow-none`, `shadow-inner` | `.Effect.Shadow.{X2xs, Xs, Sm, Md, Lg, Xl, X2xl, None, Inner}` | `--tw-shadow:var(--shadow-md);box-shadow:<five-channel reader>` |
| `inset-shadow-*` | `.Effect.InsetShadow.{X2xs, Xs, Sm}` | `--tw-inset-shadow:inset var(--inset-shadow-sm);box-shadow:<reader>` |
| `text-shadow-*` | `.Effect.TextShadow.{X2xs, Xs, Sm, Md, Lg, None}` | `text-shadow:var(--text-shadow-sm)` |
| `opacity-*` | `.Effect.Opacity.*` (15 + 6 provisional) | `opacity:0.6` |
| `mix-blend-*` / `bg-blend-*` | `.Blend.Mix.*` / `.Blend.Bg.*` (17 each) | `mix-blend-mode:multiply` |
| `mask-clip-*` … `mask-type-*` | `.Mask.{Clip, Composite, Image, Mode, Origin, Position, Repeat, Size, Type}.*` | `mask-clip:padding-box` … |
| `shadow-<colour>/<opacity>` | ❌ | — |

## 10. Filters — front 42

| Tailwind | emilia token | CSS |
|---|---|---|
| `blur-*` `brightness-*` `contrast-*` `drop-shadow-*` `grayscale` `hue-rotate-*` `invert` `saturate-*` `sepia` | `.Filter.{Blur, Brightness, Contrast, DropShadow, Grayscale, HueRotate, Invert, Saturate, Sepia}.*` | `--tw-blur:blur(var(--blur-sm));filter:<chain reader>`; `Blur.None` → `filter:none` |
| `backdrop-*` | `.BackdropFilter.{Blur, Brightness, Contrast, Grayscale, HueRotate, Invert, Opacity, Saturate, Sepia}.*` | `--tw-backdrop-blur:…;backdrop-filter:<chain reader>` |

## 11. Tables — front 43

| Tailwind | emilia token | CSS |
|---|---|---|
| `border-collapse` / `border-separate` | `.Table.{Collapse, Separate}` | `border-collapse:<value>` |
| `border-spacing-*` / `-x-*` / `-y-*` | `.Table.{Spacing, SpacingX, SpacingY}.{0, 1, 2, 4, 8}` | `border-spacing:calc(var(--spacing) * 2) 0` |
| `table-auto` / `table-fixed` | `.Table.Layout.{Auto, Fixed}` | `table-layout:<value>` |
| `caption-top` / `caption-bottom` | `.Table.Caption.{Top, Bottom}` | `caption-side:<value>` |

## 12. Transitions and animation — front 44

| Tailwind | emilia token | CSS |
|---|---|---|
| `transition` `-all` `-colors` `-opacity` `-shadow` `-transform` | `.Transition.{Base, All, Colors, Opacity, Shadow, Transform}` | `transition-property:…;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-none` | `.Transition.None` | `transition-property:none` |
| `transition-normal` / `-discrete` | `.Transition.Behavior.{Normal, Discrete}` | `transition-behavior:allow-discrete` |
| `duration-*` / `delay-*` | `.Transition.Duration.*` / `.Transition.Delay.*` | `transition-duration:300ms` |
| `ease-linear` `-in` `-out` `-in-out` | `.Transition.Ease.{Linear, In, Out, InOut}` | `transition-timing-function:linear` / `var(--ease-in)` … |
| `animate-none` `-spin` `-ping` `-pulse` `-bounce` | `.Animate.*` | `animation:var(--animate-spin)` + the `@keyframes spin` block |
| `@starting-style` | ❌ | — |

## 13. Transforms — front 45

| Tailwind | emilia token | CSS |
|---|---|---|
| `rotate-*` / `-rotate-*` | `.Transform.Rotate.*` / `.Transform.Rotate.Neg.*` | `rotate:45deg` / `rotate:-12deg` |
| `scale-*` / `scale-x-*` / `scale-y-*` | `.Transform.{Scale, ScaleX, ScaleY}.*` | `scale:.5`; `scale:.5 1` |
| `translate-x-*` / `translate-y-*` / `translate-*` | `.Transform.{TranslateX, TranslateY, Translate}.{0, Px, 1, Half, Full}` | `--tw-translate-x:50%;translate:var(--tw-translate-x) var(--tw-translate-y)` (+ `@property`); both axes write both variables |
| `skew-x-*` / `skew-y-*` | `.Transform.{SkewX, SkewY}.*` | `--tw-skew-x:skewX(3deg);transform:var(--tw-rotate-x,) … var(--tw-skew-y,)` (+ `@property`) |
| `origin-*` (9) | `.Transform.Origin.*` | `transform-origin:top right` |
| `transform-flat` / `transform-3d`, `backface-*` | `.Transform.Style.{Flat, Preserve3d}`, `.Transform.Backface.*` | `transform-style:preserve-3d` |
| `perspective-*` / `perspective-origin-*` | `.Transform.Perspective.*` / `.Transform.PerspectiveOrigin.*` | `perspective:var(--perspective-near)` |
| `zoom-*` | `.Transform.Zoom.*` | `zoom:0.5` |
| `transform-none` `transform` `transform-cpu` `transform-gpu` | `.Transform.Shorthand.{None, Cpu, Gpu}` | `transform:none`; upstream v4's chain rows (`Gpu` with `translateZ(0)`) |
| `rotate-x-*` … `scale-z-*` | ❌ | — |

## 14. Interactivity — front 46

| Tailwind | emilia token | CSS |
|---|---|---|
| `cursor-*` (36) | `.Interact.Cursor.*` (`cursor-default` is `.Standard`) | `cursor:<value>` |
| `appearance-*` / `field-sizing-*` / `color-scheme-*` | `.Interact.{Appearance, FieldSizing, ColorScheme}.*` | `color-scheme:light dark` |
| `accent-<colour>` / `accent-auto` / `caret-<colour>` | `accent(v)`, `.Interact.AccentAuto`, `caret(v)` with `v = paletteVar(…)` | `accent-color:var(--color-indigo-600)` |
| `pointer-events-*` `resize-*` `select-*` `will-change-*` `touch-*` | `.Interact.{PointerEvents, Resize, Select, WillChange, Touch}.*` | `resize:vertical`; `will-change:scroll-position` |
| `scroll-auto` / `-smooth`, `scroll-m*-*`, `scroll-p*-*` | `.Interact.Scroll.Behavior.*`, `.Interact.Scroll.{M, Mx, My, Mt, Mr, Mb, Ml, P, Px, Py, Pt, Pr, Pb, Pl}.{0, 1, 2, 4, 8}` | `scroll-margin-top:calc(var(--spacing) * 4)` |
| `scrollbar-*`, `scrollbar-gutter-*`, `scrollbar-thumb-*`/`-track-*` | `.Interact.Scrollbar.{Width, Gutter}.*`, `scrollbarColor(thumb, track)` | `scrollbar-color:<thumb> <track>` |
| `snap-*` | `.Interact.Snap.{Align, Stop, Type, Strictness}.*` | `scroll-snap-type:x var(--tw-scroll-snap-strictness, proximity)` |

## 15. SVG and accessibility — front 47

| Tailwind | emilia token | CSS |
|---|---|---|
| `fill-none` / `fill-current` / `fill-<colour>` | `.Svg.Fill.{None, Current}` / `fillColor(v)` | `fill:currentcolor`; `fill:var(--color-red-500)` |
| `stroke-none` / `stroke-current` / `stroke-<colour>` | `.Svg.Stroke.*` / `strokeColor(v)` | `stroke:<value>` |
| `stroke-0` `-1` `-2` / `stroke-[N]` | `.Svg.StrokeWidth.{0, 1, 2}` / `rawStrokeWidth(v)` | `stroke-width:2` |
| `sr-only` / `not-sr-only` | `.A11y.{SrOnly, NotSrOnly}` | upstream's nine declarations / eight restored |
| `forced-color-adjust-*` | `.A11y.ForcedColorAdjust.{Auto, None}` | `forced-color-adjust:<value>` |

## 16. Modifiers — front 34

| Tailwind | emilia modifier | Emits around the inner rules |
|---|---|---|
| `sm:` … `2xl:` | `Sm`, `Md`, `Lg`, `Xl`, `X2xl` | `@media (width >= 40rem)` … from `--breakpoint-*` |
| `max-sm:` … `max-2xl:` | `MaxSm` … `MaxX2xl` | `@media (width < 40rem)` … |
| `dark:` | `Dark` | `@media (prefers-color-scheme: dark)` or the class/attribute selector, per `DarkMode` |
| `print:` `portrait:` `landscape:` `motion-safe:` `motion-reduce:` `contrast-more:` `contrast-less:` `forced-colors:` | `Print` … `ForcedColors` | the matching `@media` |
| `hover:` | `Hover` | `@media (hover: hover)` + `&:hover` |
| `focus:` `focus-within:` `focus-visible:` `active:` `visited:` `target:` | `Focus` … `Target` | `&:<state>` |
| `open:` / `inert:` | `Open` / `Inert` | `&:is(:open, :popover-open)` / `&:is([inert], [inert] *)` |
| form states (16) | `Disabled` … `ReadOnly` | `&:<state>` |
| `first:` … `empty:`, `nth-N:`, `nth-last-N:` | `First` … `Empty`, `Nth(index, inner)`, `NthLast(index, inner)` | `&:nth-child(3)` … |
| `before:` … `backdrop:` | `Before` … `Backdrop` | `&::before`; `& ::marker`; `& ::selection` |
| `group-hover:` `-focus:` `-active:` `-visited:` `-disabled:` `-open:` | `GroupHover` … `GroupOpen` | `&:is(:where(.group):hover *)` |
| `peer-*:` (8) | `PeerHover` … `PeerPlaceholderShown` | `&:is(:where(.peer):checked ~ *)` |
| `rtl:` `ltr:` `*:` `**:` | `Rtl`, `Ltr`, `Children`, `Descendants` | `[dir="rtl"] &`; `:is(& > *)`; `:is(& *)` |
| `!` | `Important` | `!important` on every inner declaration |
| `@3xs:` … `@7xl:`, `@sm/main:` | `containerAt3xs(inner)` … `containerAt7xl(inner)`, `containerNamed(size, name, inner)` (front 58) | `@container (width >= 28rem)`, `@container main (width >= 24rem)` |
| `@container` / `@container/main` | `.Container.{Inline, Normal, Size}`, `containerName(name)` | `container-type:inline-size;container-name:main` |
| `[&.x]:` `[@supports(…)]:` `min-[320px]:` `max-[600px]:` | `arbSel`, `arbAt`, `arbMin`, `arbMax` (front 57) | the given selector / at-rule |
| `group/item`, named peers, `aria-*`, `data-*`, `has-*`, `not-*` named variants | ❌ (use `arbSel` or `compose.selector`) | — |

## 17. Custom utilities and variants — front 59

| Tailwind | emilia |
|---|---|
| `@utility x { … }` | a `pub fn x() -> Token[]` bundle |
| `@apply …` | `bundle().append(extra)` / `compose([…])` |
| `@custom-variant` / `@variant` / `@slot` | a function over `Token[]`; `selector(v, inner)` |
| `@layer components { .x { … } }` | `named("x", tokens)` |
