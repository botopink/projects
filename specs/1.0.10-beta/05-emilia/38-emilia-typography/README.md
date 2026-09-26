# Front 38 — emilia typography

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`themeVar`, `spacing(n)`, `--text-*`), 56 (`declSheet`), 33 (`paletteVar` for decoration colours)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (front-38 fences: `Text`, `Font`, `List`) ·
`src/emilia.bp` (front-38 block: `textTokenToCss`, `textSizeToCss`, `fontTokenToCss`, `fontWeightToCss`,
`listTokenToCss` and their sub-dispatchers, `typographyEntries`; the `List` arm of `tokenToSheet`)
**Does not own:** `Color` (front 33) — `text-red-500` is a colour token
**User docs:** `repository/emilia/docs.md` § *Text, Font and List*, § *List*
**Reference:** `TAILWIND_CSS_DOCS.md § 9` (9.1–9.32), `§ 21.3` · https://tailwindcss.com/docs/font-size

**Open:** none.

---

## What it delivers

All of `§ 9` — **437 leaves** over `Text`, `Font` and the `List` section. Family, size, tracking and
leading emit theme references; every sub-dispatcher takes `th: Theme` and goes through `declSheet`.

| Group | Tokens | CSS |
|---|---|---|
| Family (`§ 9.1`) | `.Font.{Sans, Serif, Mono}` | `font-family:var(--font-sans)` |
| Size (`§ 9.2`, `§ 21.3`) | `.Text.Size.{Xs, Sm, Base, Lg, Xl, X2xl … X9xl}` (13) | `font-size:var(--text-lg);line-height:var(--text-lg--line-height)` — the pair |
| Weight (`§ 9.5`) | `.Font.Weight.{Thin, Extralight, Light, Normal, Medium, Semibold, Bold, Extrabold, Black}` | `font-weight:100` … `900` |
| Smoothing / style / stretch / numeric (`§ 9.3`, `9.4`, `9.6`, `9.7`) | `.Font.Smoothing.{Antialiased, Subpixel}`, `.Font.Style.{Italic, Normal}`, `.Font.Stretch.*` (9), `.Font.Nums.*` (9) | `antialiased` → `-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale`; `not-italic` → `font-style:normal` |
| Tracking / leading (`§ 9.9`, `9.11`) | `.Text.Tracking.*` (6), `.Text.Leading.*` (6) | `letter-spacing:var(--tracking-*)`, `line-height:var(--leading-*)`; `Leading.None` → `line-height:1` |
| Clamp (`§ 9.10`) | `.Text.Clamp.{1…6, None}` | `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:N`; `None` is the four-declaration reset |
| Alignment / transform / overflow / wrap (`§ 9.15`, `9.22`–`9.24`) | `.Text.{Left, Center, Right, Justify, Start, End}`, `.Text.Transform.*`, `.Text.Truncate`, `.Text.Overflow.*`, `.Text.Wrap.*` | `truncate` → `overflow:hidden;text-overflow:ellipsis;white-space:nowrap` |
| Decoration (`§ 9.17`–`9.21`) | `.Text.{Underline, Overline, LineThrough, NoUnderline}`, `.Text.Decoration.Style` (5), `.Thickness` (6), `.Offset` (5), `.Color.<Family>.<shade>` | `text-decoration-line:underline` (the longhand); `text-decoration-color:var(--color-red-500)` via front 33's `paletteVar` |
| Whitespace / breaking / hyphens (`§ 9.26`–`9.31`) | `.Text.Whitespace` (6), `.Text.Break.{Normal, Words, All, Keep}`, `.Text.OverflowWrap.{Normal, BreakWord, Anywhere}`, `.Text.Hyphens` (3) | `break-normal` → `overflow-wrap:normal;word-break:normal`; `Break` and `OverflowWrap` are separate (otherwise `wrap-anywhere` is lost) |
| Indent / vertical-align / tab / content (`§ 9.25`, `9.27`, `9.28`, `9.32`) | `.Text.Indent.N`, `.Text.Align.*` (8), `.Text.Tab.{0, 2, 4, 8}`, `.Text.Content.{None, Empty}` | `text-indent:calc(var(--spacing) * 8)`; `content:""` |
| Lists (`§ 9.12`–`9.14`) | `.List.{None, Disc, Decimal, Inside, Outside, ImageNone}` | `list-style-type` / `-position` / `-image` |

`.Text.Bold` (`font-weight:bold`) and `.Text.Italic` (`font-style:italic`) are emilia's own earlier
leaves and stay unchanged. **`typographyEntries()`** (23 entries in four namespaces) contributes
`--font-weight-*`, `--tracking-*`, `--leading-*` and the three `--font-*` family stacks to
`fullTheme()`; `--text-*` and its line heights are front 54's `defaultTheme()`, not a second copy.

## Acceptance

### Delivered

- [x] `.Text.Size.Lg` emits the size/line-height pair; `.Font.Sans` → `var(--font-sans)`;
      `.Text.Underline` → `text-decoration-line:underline`; no test asserts the old literals as output;
      `.Text.Bold` is untouched.
- [x] Thirteen sizes, `--text-*` half of the theme is front 54's; nine weights, `.Font.Weight.Bold` →
      `font-weight:700`.
- [x] `antialiased` is two vendor properties; nine stretch and nine variant-numeric values;
      `not-italic` is `Style.Normal`.
- [x] Six tracking values (references), six leading values (five references, `None` literal `1`), the
      theme values `§ 9.9`/`§ 9.11` print; `line-clamp-N` four declarations in the reference's order,
      `line-clamp-none` the reset.
- [x] `truncate` three declarations; `break-normal` two, `break-words` one; `OverflowWrap` separate;
      six whitespace and three hyphens values.
- [x] Five decoration styles, six thicknesses, five offsets; a decoration colour is front 33's
      reference; `indent` answers `spacing(n)`; eight vertical-align values, four tab sizes;
      `content:""`; `List` six leaves.
- [x] Every non-arbitrary utility in `§ 9.1`–`§ 9.32` has a token; all 437 leaves declare something
      well formed.
- [x] `typographyEntries()` composes into the theme via `extendTheme`, like `paletteEntries()`.
- [x] Every dispatcher takes `th: Theme` (the per-family decoration shade helpers return a shade, as
      front 33's do); the front-38 banners fence both files; the `List` arm sits between fronts 37 and
      39; `repository/emilia/AGENTS.md` and the `tokens.bp` header record the sections; green on
      commonJS and erlang.

## Not declared

- Arbitrary forms: `list-image-[url(…)]`, `content-['Hello']`, `font-feature-settings` — front 57.
- `list-style-type` beyond `none`/`disc`/`decimal` (`§ 9.14` prints three).

## Examples

- [`./examples/typography-example.bp`](./examples/typography-example.bp) — family, size, weight,
  smoothing, stretch, variant-numeric, tracking, leading, clamp, transform, overflow, wrap; an article
  header and a clamped excerpt.
- [`./examples/text-decoration-example.bp`](./examples/text-decoration-example.bp) — decoration,
  lists, whitespace, breaking, hyphens, indent, vertical-align, `content`; a paragraph with
  wavy-underlined links.
