# Front 38 — emilia-typography

**Track:** D emilia
**Priority:** high — `§ 9` is thirty-two property groups. emilia covers four of them, partially, and three of those four emit CSS that is not what Tailwind v4.3 emits.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 3
**Depends on:** 54 (`Theme`, `themeVar`, `spacing(n)`), 56 (`declSheet` — this front emits declarations only, no selector), 33 (`Text.Decoration.Color` calls `paletteVar`)
**Owns:** `repository/emilia/src/tokens.bp` (the `Text` and `Font` sections and the new `List` section) · `repository/emilia/src/emilia.bp` (`textTokenToCss`, `textSizeToCss`, `fontTokenToCss`, `fontWeightToCss`, `listTokenToCss` and the new sub-dispatchers) · `repository/emilia/test/typography_test.bp`
**Does not touch:** `Color` (front 33) — `text-red-500` is a colour token, not a typography token
**Reference:** `TAILWIND_CSS_DOCS.md § 9. Tipografia` (9.1–9.32), `§ 21.3 Tipografia Padrão` · https://tailwindcss.com/docs/font-size
**Replaces:** `1.0.8-beta/04-emilia-typography`

---

## Problem

`Text` (`tokens.bp:38-57`) covers three of `§ 9`'s thirty-two groups: two decoration lines, four
alignment values and eight font sizes. `Font` (`tokens.bp:59-70`) covers family and five of the nine
weights. Twenty-eight groups have no token: no letter-spacing, no line-height, no line-clamp, no
list styling, no text-transform, no text-overflow, no text-wrap, no indent, no vertical-align, no
whitespace, no word-break, no overflow-wrap, no hyphens, no `content`, no font-smoothing, no
font-stretch, no font-variant-numeric, no tab-size, no decoration style, thickness, colour or
offset.

Three of the four groups that exist do not emit the v4.3 form:

- `textSizeToCss` (`emilia.bp:121-133`) emits `font-size:1.125rem`. `§ 9.2` emits
  `font-size: var(--text-lg); line-height: var(--text-lg--line-height)` — a variable, and a paired
  line-height that emilia drops entirely. A `text-lg` in Tailwind changes leading; in emilia it does
  not.
- `fontTokenToCss` (`emilia.bp:135-143`) emits the literal stack
  `font-family:ui-sans-serif,system-ui,sans-serif`. `§ 9.1` emits `font-family: var(--font-sans)`.
- `textTokenToCss` (`emilia.bp:106-119`) emits `text-decoration:underline`. `§ 9.17` emits
  `text-decoration-line: underline` — the longhand, which is what makes `underline` and
  `decoration-dotted` composable instead of overwriting each other.

Font sizes also stop at `4xl`. `§ 21.3` lists thirteen, up to `9xl`.

## Current state

| What | Where | State |
|---|---|---|
| `Text { Bold, Italic, Underline, LineThrough, Left, Center, Right, Justify }` | `tokens.bp:39-46` | 8 leaves across 3 property groups |
| `Text.Size { Xs … X4xl }` | `tokens.bp:47-56` | 8 of the 13 sizes |
| `Font { Sans, Serif, Mono }` | `tokens.bp:60-62` | 3 families |
| `Font.Weight { Light, Normal, Medium, Bold, Black }` | `tokens.bp:63-69` | 5 of 9 weights |
| `textTokenToCss` | `emilia.bp:106-119` | `text-decoration:` shorthand instead of `text-decoration-line:` |
| `textSizeToCss` | `emilia.bp:121-133` | literal `rem`, no paired line-height |
| `fontTokenToCss` | `emilia.bp:135-143` | literal family stack instead of `var(--font-*)` |
| `fontWeightToCss` | `emilia.bp:145-154` | correct — numeric weights |
| everything else in `§ 9` | — | no token |

## Mechanism

`§ 9` is thirty-two independent properties over two existing sections, so `Text` and `Font` become
sections of sub-sections and a third section, `List`, is added for `§ 9.12`–`§ 9.14`. The bare
leaves that exist today stay bare leaves, so every path that compiles keeps compiling — even where
its output changes.

Three emission shapes:

- **One keyword → one declaration.** Most of `§ 9`.
- **One token → two declarations.** `Text.Size.*` pairs font-size with line-height (`§ 9.2`);
  `truncate` is three declarations (`§ 9.23`); `break-normal` is two (`§ 9.29`); `line-clamp-N` is
  four (`§ 9.10`).
- **A theme variable.** Family, size, tracking and leading all reference `var(--…)` in v4.3, the
  same two-layer shape front 33 uses for colour. The utility side emits front 54's
  `themeVar(name)`; the values live in front 54's theme, reached with `themeValue(th, name)`.
  `§ 21.3` and `§ 9.9`/`§ 9.11` print every one of them, so unlike the colour grid this half of the
  theme is fully specifiable from the reference and is contributed as a `ThemeEntry[]` the same way
  front 33 contributes `paletteEntries()`.

Every sub-dispatcher here has the contract-4a shape
`fn <name>(t: Token.<Section>.<Sub>, th: Theme) -> string` (see
[`contracts.md`](../../contracts.md) § 4a), and every one of them goes through `declSheet`: no token in
this front needs a selector of its own. `Text.Indent` calls front 54's `spacing(n)`, so it emits
`calc(var(--spacing) * 8)` and never a resolved length.

## Token surface

### Family, size, weight — `§ 9.1`, `§ 9.2`, `§ 9.5`, `§ 21.3`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `font-sans` | `.Font.Sans` | `font-family:var(--font-sans)` |
| `font-serif` | `.Font.Serif` | `font-family:var(--font-serif)` |
| `font-mono` | `.Font.Mono` | `font-family:var(--font-mono)` |
| `text-xs` | `.Text.Size.Xs` | `font-size:var(--text-xs);line-height:var(--text-xs--line-height)` |
| `text-sm` | `.Text.Size.Sm` | `font-size:var(--text-sm);line-height:var(--text-sm--line-height)` |
| `text-base` | `.Text.Size.Base` | `font-size:var(--text-base);line-height:var(--text-base--line-height)` |
| `text-lg` | `.Text.Size.Lg` | `font-size:var(--text-lg);line-height:var(--text-lg--line-height)` |
| `text-xl` | `.Text.Size.Xl` | `font-size:var(--text-xl);line-height:var(--text-xl--line-height)` |
| `text-2xl` | `.Text.Size.X2xl` | `font-size:var(--text-2xl);line-height:var(--text-2xl--line-height)` |
| `text-3xl` | `.Text.Size.X3xl` | `font-size:var(--text-3xl);line-height:var(--text-3xl--line-height)` |
| `text-4xl` | `.Text.Size.X4xl` | `font-size:var(--text-4xl);line-height:var(--text-4xl--line-height)` |
| `text-5xl` | `.Text.Size.X5xl` | `font-size:var(--text-5xl);line-height:var(--text-5xl--line-height)` |
| `text-6xl` | `.Text.Size.X6xl` | `font-size:var(--text-6xl);line-height:var(--text-6xl--line-height)` |
| `text-7xl` | `.Text.Size.X7xl` | `font-size:var(--text-7xl);line-height:var(--text-7xl--line-height)` |
| `text-8xl` | `.Text.Size.X8xl` | `font-size:var(--text-8xl);line-height:var(--text-8xl--line-height)` |
| `text-9xl` | `.Text.Size.X9xl` | `font-size:var(--text-9xl);line-height:var(--text-9xl--line-height)` |
| `font-thin` | `.Font.Weight.Thin` | `font-weight:100` |
| `font-extralight` | `.Font.Weight.Extralight` | `font-weight:200` |
| `font-light` | `.Font.Weight.Light` | `font-weight:300` |
| `font-normal` | `.Font.Weight.Normal` | `font-weight:400` |
| `font-medium` | `.Font.Weight.Medium` | `font-weight:500` |
| `font-semibold` | `.Font.Weight.Semibold` | `font-weight:600` |
| `font-bold` | `.Font.Weight.Bold` | `font-weight:700` |
| `font-extrabold` | `.Font.Weight.Extrabold` | `font-weight:800` |
| `font-black` | `.Font.Weight.Black` | `font-weight:900` |

### Smoothing, style, stretch, variant-numeric — `§ 9.3`, `§ 9.4`, `§ 9.6`, `§ 9.7`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `antialiased` | `.Font.Smoothing.Antialiased` | `-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale` |
| `subpixel-antialiased` | `.Font.Smoothing.Subpixel` | `-webkit-font-smoothing:auto;-moz-osx-font-smoothing:auto` |
| `italic` | `.Font.Style.Italic` | `font-style:italic` |
| `not-italic` | `.Font.Style.Normal` | `font-style:normal` |
| `font-stretch-ultra-condensed` | `.Font.Stretch.UltraCondensed` | `font-stretch:ultra-condensed` |
| `font-stretch-extra-condensed` | `.Font.Stretch.ExtraCondensed` | `font-stretch:extra-condensed` |
| `font-stretch-condensed` | `.Font.Stretch.Condensed` | `font-stretch:condensed` |
| `font-stretch-semi-condensed` | `.Font.Stretch.SemiCondensed` | `font-stretch:semi-condensed` |
| `font-stretch-normal` | `.Font.Stretch.Normal` | `font-stretch:normal` |
| `font-stretch-semi-expanded` | `.Font.Stretch.SemiExpanded` | `font-stretch:semi-expanded` |
| `font-stretch-expanded` | `.Font.Stretch.Expanded` | `font-stretch:expanded` |
| `font-stretch-extra-expanded` | `.Font.Stretch.ExtraExpanded` | `font-stretch:extra-expanded` |
| `font-stretch-ultra-expanded` | `.Font.Stretch.UltraExpanded` | `font-stretch:ultra-expanded` |
| `normal-nums` | `.Font.Nums.Normal` | `font-variant-numeric:normal` |
| `ordinal` | `.Font.Nums.Ordinal` | `font-variant-numeric:ordinal` |
| `slashed-zero` | `.Font.Nums.SlashedZero` | `font-variant-numeric:slashed-zero` |
| `lining-nums` | `.Font.Nums.Lining` | `font-variant-numeric:lining-nums` |
| `oldstyle-nums` | `.Font.Nums.Oldstyle` | `font-variant-numeric:oldstyle-nums` |
| `proportional-nums` | `.Font.Nums.Proportional` | `font-variant-numeric:proportional-nums` |
| `tabular-nums` | `.Font.Nums.Tabular` | `font-variant-numeric:tabular-nums` |
| `diagonal-fractions` | `.Font.Nums.DiagonalFractions` | `font-variant-numeric:diagonal-fractions` |
| `stacked-fractions` | `.Font.Nums.StackedFractions` | `font-variant-numeric:stacked-fractions` |

`.Text.Italic` exists today and emits `font-style:italic`; it stays, and `.Font.Style.Italic` is the
v4-shaped spelling of the same declaration.

### Tracking and leading — `§ 9.9`, `§ 9.11`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `tracking-tighter` | `.Text.Tracking.Tighter` | `letter-spacing:var(--tracking-tighter)` |
| `tracking-tight` | `.Text.Tracking.Tight` | `letter-spacing:var(--tracking-tight)` |
| `tracking-normal` | `.Text.Tracking.Normal` | `letter-spacing:var(--tracking-normal)` |
| `tracking-wide` | `.Text.Tracking.Wide` | `letter-spacing:var(--tracking-wide)` |
| `tracking-wider` | `.Text.Tracking.Wider` | `letter-spacing:var(--tracking-wider)` |
| `tracking-widest` | `.Text.Tracking.Widest` | `letter-spacing:var(--tracking-widest)` |
| `leading-tight` | `.Text.Leading.Tight` | `line-height:var(--leading-tight)` |
| `leading-snug` | `.Text.Leading.Snug` | `line-height:var(--leading-snug)` |
| `leading-normal` | `.Text.Leading.Normal` | `line-height:var(--leading-normal)` |
| `leading-relaxed` | `.Text.Leading.Relaxed` | `line-height:var(--leading-relaxed)` |
| `leading-loose` | `.Text.Leading.Loose` | `line-height:var(--leading-loose)` |
| `leading-none` | `.Text.Leading.None` | `line-height:1` |

`leading-none` is the one leaf that is a literal, not a variable — `§ 9.11` prints it that way.

### Clamp, alignment, transform, overflow, wrap — `§ 9.10`, `§ 9.15`, `§ 9.22`–`§ 9.24`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `line-clamp-1` | `.Text.Clamp.1` | `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:1` |
| `line-clamp-6` | `.Text.Clamp.6` | `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:6` |
| `line-clamp-none` | `.Text.Clamp.None` | `overflow:visible;display:block;-webkit-box-orient:horizontal;-webkit-line-clamp:none` |
| `text-left` | `.Text.Left` | `text-align:left` |
| `text-center` | `.Text.Center` | `text-align:center` |
| `text-right` | `.Text.Right` | `text-align:right` |
| `text-justify` | `.Text.Justify` | `text-align:justify` |
| `text-start` | `.Text.Start` | `text-align:start` |
| `text-end` | `.Text.End` | `text-align:end` |
| `uppercase` | `.Text.Transform.Uppercase` | `text-transform:uppercase` |
| `lowercase` | `.Text.Transform.Lowercase` | `text-transform:lowercase` |
| `capitalize` | `.Text.Transform.Capitalize` | `text-transform:capitalize` |
| `normal-case` | `.Text.Transform.None` | `text-transform:none` |
| `truncate` | `.Text.Truncate` | `overflow:hidden;text-overflow:ellipsis;white-space:nowrap` |
| `text-ellipsis` | `.Text.Overflow.Ellipsis` | `text-overflow:ellipsis` |
| `text-clip` | `.Text.Overflow.Clip` | `text-overflow:clip` |
| `text-wrap` | `.Text.Wrap.Wrap` | `text-wrap:wrap` |
| `text-nowrap` | `.Text.Wrap.Nowrap` | `text-wrap:nowrap` |
| `text-balance` | `.Text.Wrap.Balance` | `text-wrap:balance` |
| `text-pretty` | `.Text.Wrap.Pretty` | `text-wrap:pretty` |

### Decoration — `§ 9.17`–`§ 9.21`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `underline` | `.Text.Underline` | `text-decoration-line:underline` |
| `overline` | `.Text.Overline` | `text-decoration-line:overline` |
| `line-through` | `.Text.LineThrough` | `text-decoration-line:line-through` |
| `no-underline` | `.Text.NoUnderline` | `text-decoration-line:none` |
| `decoration-solid` | `.Text.Decoration.Style.Solid` | `text-decoration-style:solid` |
| `decoration-double` | `.Text.Decoration.Style.Double` | `text-decoration-style:double` |
| `decoration-dotted` | `.Text.Decoration.Style.Dotted` | `text-decoration-style:dotted` |
| `decoration-dashed` | `.Text.Decoration.Style.Dashed` | `text-decoration-style:dashed` |
| `decoration-wavy` | `.Text.Decoration.Style.Wavy` | `text-decoration-style:wavy` |
| `decoration-auto` | `.Text.Decoration.Thickness.Auto` | `text-decoration-thickness:auto` |
| `decoration-from-font` | `.Text.Decoration.Thickness.FromFont` | `text-decoration-thickness:from-font` |
| `decoration-0` | `.Text.Decoration.Thickness.0` | `text-decoration-thickness:0px` |
| `decoration-1` | `.Text.Decoration.Thickness.1` | `text-decoration-thickness:1px` |
| `decoration-2` | `.Text.Decoration.Thickness.2` | `text-decoration-thickness:2px` |
| `decoration-4` | `.Text.Decoration.Thickness.4` | `text-decoration-thickness:4px` |
| `decoration-red-500` | `.Text.Decoration.Color.Red.500` | `text-decoration-color:var(--color-red-500)` |
| `underline-offset-auto` | `.Text.Decoration.Offset.Auto` | `text-underline-offset:auto` |
| `underline-offset-0` | `.Text.Decoration.Offset.0` | `text-underline-offset:0px` |
| `underline-offset-1` | `.Text.Decoration.Offset.1` | `text-underline-offset:1px` |
| `underline-offset-2` | `.Text.Decoration.Offset.2` | `text-underline-offset:2px` |
| `underline-offset-4` | `.Text.Decoration.Offset.4` | `text-underline-offset:4px` |

### Whitespace, breaking, hyphens, indent, vertical-align, tab, content — `§ 9.25`–`§ 9.32`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `whitespace-normal` | `.Text.Whitespace.Normal` | `white-space:normal` |
| `whitespace-nowrap` | `.Text.Whitespace.Nowrap` | `white-space:nowrap` |
| `whitespace-pre` | `.Text.Whitespace.Pre` | `white-space:pre` |
| `whitespace-pre-line` | `.Text.Whitespace.PreLine` | `white-space:pre-line` |
| `whitespace-pre-wrap` | `.Text.Whitespace.PreWrap` | `white-space:pre-wrap` |
| `whitespace-break-spaces` | `.Text.Whitespace.BreakSpaces` | `white-space:break-spaces` |
| `break-normal` | `.Text.Break.Normal` | `overflow-wrap:normal;word-break:normal` |
| `break-words` | `.Text.Break.Words` | `overflow-wrap:break-word` |
| `break-all` | `.Text.Break.All` | `word-break:break-all` |
| `break-keep` | `.Text.Break.Keep` | `word-break:keep-all` |
| `wrap-normal` | `.Text.OverflowWrap.Normal` | `overflow-wrap:normal` |
| `wrap-break-word` | `.Text.OverflowWrap.BreakWord` | `overflow-wrap:break-word` |
| `wrap-anywhere` | `.Text.OverflowWrap.Anywhere` | `overflow-wrap:anywhere` |
| `hyphens-none` | `.Text.Hyphens.None` | `hyphens:none` |
| `hyphens-manual` | `.Text.Hyphens.Manual` | `hyphens:manual` |
| `hyphens-auto` | `.Text.Hyphens.Auto` | `hyphens:auto` |
| `indent-8` | `.Text.Indent.8` | `text-indent:calc(var(--spacing) * 8)` |
| `align-baseline` | `.Text.Align.Baseline` | `vertical-align:baseline` |
| `align-top` | `.Text.Align.Top` | `vertical-align:top` |
| `align-middle` | `.Text.Align.Middle` | `vertical-align:middle` |
| `align-bottom` | `.Text.Align.Bottom` | `vertical-align:bottom` |
| `align-text-top` | `.Text.Align.TextTop` | `vertical-align:text-top` |
| `align-text-bottom` | `.Text.Align.TextBottom` | `vertical-align:text-bottom` |
| `align-sub` | `.Text.Align.Sub` | `vertical-align:sub` |
| `align-super` | `.Text.Align.Super` | `vertical-align:super` |
| `tab-0` | `.Text.Tab.0` | `tab-size:0` |
| `tab-2` | `.Text.Tab.2` | `tab-size:2` |
| `tab-4` | `.Text.Tab.4` | `tab-size:4` |
| `tab-8` | `.Text.Tab.8` | `tab-size:8` |
| `content-none` | `.Text.Content.None` | `content:none` |
| `content-['']` | `.Text.Content.Empty` | `content:""` |

### Lists — `§ 9.12`–`§ 9.14`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `list-none` | `.List.None` | `list-style-type:none` |
| `list-disc` | `.List.Disc` | `list-style-type:disc` |
| `list-decimal` | `.List.Decimal` | `list-style-type:decimal` |
| `list-inside` | `.List.Inside` | `list-style-position:inside` |
| `list-outside` | `.List.Outside` | `list-style-position:outside` |
| `list-image-none` | `.List.ImageNone` | `list-style-image:none` |

## Steps

### Step 1 — the three corrections

`textSizeToCss` emits the variable pair; `fontTokenToCss` emits `var(--font-*)`;
`textTokenToCss`'s two decoration arms emit `text-decoration-line`.

| Token | today | after |
|---|---|---|
| `.Text.Size.Lg` | `font-size:1.125rem` | `font-size:var(--text-lg);line-height:var(--text-lg--line-height)` |
| `.Font.Sans` | `font-family:ui-sans-serif,system-ui,sans-serif` | `font-family:var(--font-sans)` |
| `.Text.Underline` | `text-decoration:underline` | `text-decoration-line:underline` |
| `.Text.LineThrough` | `text-decoration:line-through` | `text-decoration-line:line-through` |

**This changes the CSS four existing tokens emit**, for the same reason front 34's correction does:
what they emit today is not what Tailwind v4.3 emits. Two assertions in
`repository/emilia/src/emilia.bp` break and must be updated in the same commit — `:411-413`
(`Text.Size.Lg` → `font-size:1.125rem`) and `:482-487` (the mixed-token flush, which contains the
same literal). `.Text.Bold`, asserted at `:407-409`, `:443-447`, `:449-453`, `:475-480`, `:505-511`
and `:513-520`, is **not** affected: `font-weight:bold` is emilia's own leaf, not a transcription of
a Tailwind utility, and this front leaves it alone.

**Acceptance:**
- [ ] `.Text.Size.Lg` emits two declarations, `;`-joined, from one token
- [ ] `.Font.Sans` emits `font-family:var(--font-sans)`
- [ ] `.Text.Underline` emits `text-decoration-line:underline`
- [ ] `.Text.Bold` still emits `font-weight:bold`, and `emilia.bp:407-409` is untouched
- [ ] the two affected assertions in `src/emilia.bp` are updated, and `grep -R 'font-size:1.125rem' repository/emilia`
      returns nothing outside front 54's theme entries

### Step 2 — widen size, weight and family

Five sizes (`X5xl` … `X9xl`) and four weights (`Thin`, `Extralight`, `Semibold`, `Extrabold`).
The `--text-*` and `--font-weight-*` theme entries are contributed as a `ThemeEntry[]` and composed
into front 54's theme with `extend`, beside front 33's `paletteEntries()`; `§ 21.3` prints every size
and its line-height, so this half is fully specifiable from the reference.

**Acceptance:**
- [ ] thirteen sizes, `Xs` through `X9xl`
- [ ] the entries define `--text-xs` as `0.75rem` with `--text-xs--line-height` as `calc(1 / 0.75)`, and
      `--text-5xl` as `3rem` with line-height `1` — the two shapes `§ 21.3` distinguishes
- [ ] nine weights, `100` through `900`
- [ ] `.Font.Weight.Bold` still emits `font-weight:700`

### Step 3 — smoothing, style, stretch, variant-numeric

Four sub-sections under `Font`.

**Acceptance:**
- [ ] `antialiased` emits both vendor properties, `;`-joined, from one token
- [ ] nine stretch values
- [ ] nine variant-numeric values
- [ ] `.Font.Style.Normal` emits `font-style:normal` — the Tailwind name is `not-italic` and the CSS
      value is `normal`, and the test says so

### Step 4 — tracking, leading, clamp

**Acceptance:**
- [ ] six tracking values, each a `var(--tracking-*)`
- [ ] six leading values, five of them `var(--leading-*)` and `None` the literal `1`
- [ ] the theme entries carry the six tracking and five leading values `§ 9.9` and `§ 9.11` print in
      parentheses
- [ ] `.Text.Clamp.3` emits four declarations in the order `§ 9.10` prints them
- [ ] `.Text.Clamp.None` emits the four-declaration reset, not an omission

### Step 5 — transform, overflow, wrap, whitespace, breaking, hyphens

**Acceptance:**
- [ ] `.Text.Truncate` emits three declarations
- [ ] `.Text.Break.Normal` emits two; `.Text.Break.Words` emits one
- [ ] `Break` (`§ 9.29`, `word-break`) and `OverflowWrap` (`§ 9.30`) are separate sub-sections —
      Tailwind's `break-*` and `wrap-*` overlap in effect and not in property, and merging them
      would lose `wrap-anywhere`
- [ ] six whitespace values, three hyphens values

### Step 6 — decoration, indent, vertical-align, tab, content, and the `List` section

`Text.Decoration.Color` calls front 33's `paletteVar`, so a decoration colour and a text colour
cannot drift.

**Acceptance:**
- [ ] `Decoration.Style` answers five values, `Thickness` six, `Offset` five
- [ ] `.Text.Decoration.Color.Red.500` emits `text-decoration-color:var(--color-red-500)` and is
      produced by front 33's helper, not a copy
- [ ] `.Text.Indent.8` calls front 54's `spacing(8)` and emits `calc(var(--spacing) * 8)`
- [ ] eight vertical-align values, four tab sizes
- [ ] `.Text.Content.Empty` emits `content:""` — two quote characters inside the CSS value
- [ ] `List` answers six leaves across three properties
- [ ] one arm added to the top-level `tokenToCss` case for `List`; `Text` and `Font` already have theirs

## Examples

- `./examples/typography-example.bp` — family, size, weight, smoothing, stretch, variant-numeric,
  tracking, leading, clamp, transform, overflow and wrap; ends with an article header and a clamped
  excerpt.
- `./examples/text-decoration-example.bp` — the decoration family in full, lists, whitespace,
  breaking, hyphens, indent, vertical-align and `content`; ends with a footnote-bearing paragraph
  whose links are wavy-underlined.

## Language gaps

None — every construct in this front's examples parses today.

## Reference gaps

| Item | Why it is missing | What implementation must do |
|---|---|---|
| `text-indent` scale | `§ 9.25` shows `indent-8` as HTML with no CSS | the `calc(var(--spacing) * N)` form is inferred from `§ 21.2`; confirm before merge |
| `list-style-type` beyond `none`/`disc`/`decimal` | `§ 9.14` prints three | this front declares three |
| `list-image-[url(...)]` | `§ 9.12` shows the arbitrary form only | the escape-hatch front |
| `content-['Hello']` | `§ 9.32` shows the arbitrary form only | the escape-hatch front; `.Text.Content.None` and `.Text.Content.Empty` are the two non-arbitrary cases |
| `decoration-2` vs `decoration-red-500` sharing a prefix | `§ 9.18`–`§ 9.20` are three tables under one Tailwind prefix | the token tree separates them by sub-section, which is a deliberate divergence from the class naming |
| `font-feature-settings` | `§ 9.8` shows only the arbitrary form | the escape-hatch front |

## Test plan

`repository/emilia/test/typography_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`.

What the tests assert:

1. **The four corrections**, each asserted against both the new string and the absence of the old one.
2. **`.Text.Bold` is untouched** — an explicit regression test, because it sits next to three
   declarations that do change.
3. **Size** — thirteen asserts on the paired-declaration form, plus two theme-entry asserts covering
   the `calc(1 / 0.75)` and the bare `1` line-height shapes.
4. **Weight** — nine asserts.
5. **Multi-declaration tokens**, each with the exact declaration order: `antialiased`, `truncate`,
   `break-normal`, `line-clamp-N`, `line-clamp-none`.
6. **Tracking and leading** — twelve asserts, including `leading-none`'s literal.
7. **Decoration** — style, thickness, offset and colour, with the colour asserted to equal
   front 33's `paletteVar` output.
8. **Lists, whitespace, breaking, hyphens, align, tab, content** — one test each.
9. **End to end** — `emilia([.Font.Sans, .Text.Size.X3xl, .Text.Tracking.Tight, .Text.Wrap.Balance])`
   then `await flush()`, asserting the whole `<style>` block.

## Definition of done

- [ ] every utility in `§ 9.1`–`§ 9.32` that is not an arbitrary-value form has a token
- [ ] the four corrected tokens emit the v4.3 form and the two affected assertions in
      `src/emilia.bp` are updated in the same commit
- [ ] `.Text.Bold` is unchanged
- [ ] the `--text-*`, `--font-weight-*`, `--tracking-*` and `--leading-*` entries are contributed as a
      `ThemeEntry[]` composed into front 54's theme, with the values `§ 21.3`, `§ 9.9` and `§ 9.11` print
- [ ] every sub-dispatcher takes `th: Theme` and returns a declaration string, per contract 4a
- [ ] the banner `// ── front 38 — typography ──` fences the block in both files
- [ ] one arm added to the top-level `tokenToCss` case for `List`, in front-number order
- [ ] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the widened sections
- [ ] the front's tests are green on its assigned target — here, both backends, since emilia is comptime

## Carried from 1.0.8-beta F04 emilia-typography

The 1.0.8 draft (`1.0.8-beta/04-emilia-typography`, Portuguese) was compared section by section
with the front above. Its token tree is absorbed in full, under new paths in several places — the
renames are listed first so the two drafts can be read side by side — and the items after that are
the details the 1.0.8 draft pins that the text above does not.

### Path renames — mapping only, nothing missing

Complements *Token surface*: the 1.0.8 draft spelled several groups as top-level sections or with
longer leaf names; every one is present above under the path in the right-hand column.

| 1.0.8 path | 1.0.10 path above |
|---|---|
| `Text.Decoration.{Underline, Overline, LineThrough, None}` | `.Text.Underline`, `.Text.Overline`, `.Text.LineThrough`, `.Text.NoUnderline` |
| `Text.DecorationStyle.*` | `.Text.Decoration.Style.*` |
| `Text.DecorationThickness.*` | `.Text.Decoration.Thickness.*` |
| `Text.UnderlineOffset.*` | `.Text.Decoration.Offset.*` |
| `Text.LineClamp.{1..6, None}` | `.Text.Clamp.{1..6, None}` |
| `Font.Smoothing.Auto` | `.Font.Smoothing.Subpixel` — same two declarations, `-webkit-font-smoothing:auto` |
| `Font.VariantNumeric.{Normal, Ordinal, SlashedZero, LiningNums, OldstyleNums, ProportionalNums, TabularNums, DiagonalFractions, StackedFractions}` | `.Font.Nums.{Normal, Ordinal, SlashedZero, Lining, Oldstyle, Proportional, Tabular, DiagonalFractions, StackedFractions}` |
| `Leading.*` (top-level section) | `.Text.Leading.*` |
| `Tracking.*` (top-level section) | `.Text.Tracking.*` |
| `Align.*` (top-level section) | `.Text.Align.*` |
| `Whitespace.*` (top-level section) | `.Text.Whitespace.*` |
| `Break.*` (top-level section) | `.Text.Break.*` |
| `Hyphens.*` (top-level section) | `.Text.Hyphens.*` |
| `Content.None` (top-level section) | `.Text.Content.None` |
| `List.{None, Disc, Decimal, Inside, Outside}` (top-level) | `.List.*` — still top-level, plus `.List.ImageNone` |

### Numeric leading ladder — `leading-3` … `leading-10`

Complements *Tracking and leading — `§ 9.9`, `§ 9.11`*: the table above carries only the six named
leading values. The 1.0.8 draft also declared the eight numeric steps of the spacing-scale
line-height (`leading-N` → `line-height:calc(var(--spacing) * N)`, the same `spacing(n)` call
`.Text.Indent` makes). Missing because `§ 9.11` prints only the named values.

```bp
Leading {             // line-height
    3, 4, 5, 6, 7, 8, 9, 10,
    None,             // 1
    Tight,            // 1.25
    Snug,             // 1.375
    Normal,           // 1.5
    Relaxed,          // 1.625
    Loose,            // 2
}
```

### The literal tracking and leading values

Complements Step 4's bullet "the theme entries carry the six tracking and five leading values
`§ 9.9` and `§ 9.11` print in parentheses": the front above emits `var(--tracking-*)` /
`var(--leading-*)` and leaves the values to front 54's theme entries without printing them. The
1.0.8 draft pins them, as comments on the leaves:

| 1.0.8 token | Value (theme entry above) |
|---|---|
| `Tracking.Tighter` | `-0.05em` (`--tracking-tighter`) |
| `Tracking.Tight` | `-0.025em` (`--tracking-tight`) |
| `Tracking.Normal` | `0em` (`--tracking-normal`) |
| `Tracking.Wide` | `0.025em` (`--tracking-wide`) |
| `Tracking.Wider` | `0.05em` (`--tracking-wider`) |
| `Tracking.Widest` | `0.1em` (`--tracking-widest`) |
| `Leading.None` | `1` (literal, as above) |
| `Leading.Tight` | `1.25` (`--leading-tight`) |
| `Leading.Snug` | `1.375` (`--leading-snug`) |
| `Leading.Normal` | `1.5` (`--leading-normal`) |
| `Leading.Relaxed` | `1.625` (`--leading-relaxed`) |
| `Leading.Loose` | `2` (`--leading-loose`) |

The two 1.0.8 acceptance bullets that read these as resolved literals are superseded by the
`var(--…)` form above and are kept here only as the value they pin:

- [ ] `Leading.Tight` → `line-height:1.25`
- [ ] `Tracking.Wide` → `letter-spacing:0.025em`

### The `8` step on indent, decoration thickness and underline offset

Complements *Decoration — `§ 9.17`–`§ 9.21`* and *Whitespace, breaking, hyphens, indent, …*: the
tables above stop the thickness and offset ladders at `4` and print indent only at `8`. The 1.0.8
draft declared the full `{0, 1, 2, 4, 8}` ladder on all three. Missing because `§ 9.18`, `§ 9.21`
and `§ 9.25` print fewer steps than the 1.0.8 draft assumed.

```bp
    Indent {          // text-indent
        0, 1, 2, 4, 8,
    }
    DecorationThickness {
        Auto,
        FromFont,
        0, 1, 2, 4, 8,
    }
    UnderlineOffset {
        Auto,
        0, 1, 2, 4, 8,
    }
```

Under the paths above that is `.Text.Indent.{0,1,2,4,8}` → `text-indent:calc(var(--spacing) * N)`,
`.Text.Decoration.Thickness.8` → `text-decoration-thickness:8px` and
`.Text.Decoration.Offset.8` → `text-underline-offset:8px`. If the `8` step is kept, Step 6's counts
("`Thickness` six, `Offset` five") become seven and six.

### 1.0.8 acceptance bullets covered above under renamed paths

Complements the per-step acceptance above; listed so the two drafts diff cleanly. Each declaration
appears above verbatim, only the token path differs:

- [ ] `Text.Transform.Uppercase` → `text-transform:uppercase`
- [ ] `Text.Truncate` → `overflow:hidden;text-overflow:ellipsis;white-space:nowrap`
- [ ] `Text.LineClamp.__3` → `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3`
- [ ] `Text.Decoration.Underline` → `text-decoration-line:underline`
- [ ] `Font.Weight.Thin` → `font-weight:100`
- [ ] `Font.Smoothing.Antialiased` → `-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale`
- [ ] `List.Disc` → `list-style-type:disc`
- [ ] `Align.Middle` → `vertical-align:middle`
- [ ] `Whitespace.Nowrap` → `white-space:nowrap`

### Gate and blast radius

Complements *Definition of done*; missing because the 1.0.10 fronts carry no size estimate.

- [ ] `botopink test` green on commonJS and erlang
- [ ] every new token mapped to the correct CSS
- [ ] existing tokens not broken
- [ ] `AGENTS.md` updated

Blast radius: `tokens.bp` +~150 lines · `emilia.bp` +~250 lines · `test/typography_test.bp` new
file, ~40 tests.

Examples carried:
- [`./examples/typography-example-1.0.8.bp`](./examples/typography-example-1.0.8.bp) — the 1.0.8
  example (smoothing, stretch, variant-numeric, tracking, clamp, leading, lists, decoration,
  transform, overflow, wrap, vertical-align, whitespace, breaking, hyphens, content); a same-named
  file already exists above and differs, so the older one is kept with the `-1.0.8` suffix.
