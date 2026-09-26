# Front 47 — emilia SVG and accessibility

**Track:** D emilia · **Priority:** low · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 33 (`paletteVar` for the fill/stroke payloads), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 47 — svg and accessibility`
block: `Svg`, `A11y`, and the top-level `SvgFill`, `SvgStroke`, `SvgStrokeWidthRaw`) ·
`src/emilia.bp` (front-47 block: `svgTokenToCss`, `a11yTokenToCss` and sub-dispatchers taking
`th: Theme`; the wrappers `fillColor`, `strokeColor`, `rawStrokeWidth`; five `tokenToSheet` arms — the
last section arms, before front 34's modifiers)
**User docs:** `repository/emilia/docs.md` § *Svg and A11y*
**Reference:** `TAILWIND_CSS_DOCS.md § 18`, `§ 19` · https://tailwindcss.com/docs/fill · https://tailwindcss.com/docs/screen-readers

**Open:** none.

---

## What it delivers

| Token | CSS | Source |
|---|---|---|
| `.Svg.Fill.Current` / `.None` | `fill:currentcolor` / `fill:none` | derived from the class suffix (`§ 18` prints no table) |
| `.Svg.Stroke.Current` / `.None` | `stroke:currentcolor` / `stroke:none` | derived |
| `.Svg.StrokeWidth.{0, 1, 2}` | `stroke-width:N` — unitless; `0` differs from `Stroke.None` | derived |
| `Token.SvgFill(value)` / `fillColor(v)` | `fill:var(--color-red-500)` with `v = paletteVar("red", "500")` | palette payload, never a hex |
| `Token.SvgStroke(value)` / `strokeColor(v)` | `stroke:<v>` | palette payload |
| `Token.SvgStrokeWidthRaw(value)` / `rawStrokeWidth(v)` | `stroke-width:<v>` | `stroke-[3]` |
| `.A11y.SrOnly` | upstream's nine declarations: `position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip-path:inset(50%);white-space:nowrap;border-width:0` | upstream `utilities.ts` (`staticUtility('sr-only')`), the URL and read date in the `emilia.bp` banner |
| `.A11y.NotSrOnly` | upstream's eight — every `sr-only` property except `border-width` | same |
| `.A11y.ForcedColorAdjust.{Auto, None}` | `forced-color-adjust:auto` / `none` | `§ 19.1` table |

- `sr-only` is a `;`-joined declaration string on the element's own class, not a `…TokenToSheet`: it
  needs no selector outside the class.
- The colour payloads are top-level variants with `string` fields carrying a `paletteVar(…)` result,
  so `fill-red-500` and `bg-red-500` read one theme entry. The `currentcolor` derivation and the
  `paletteVar` rule are stated in the `tokens.bp` docblock.
- An icon-only button: glyph `[.Svg.Stroke.Current, .Svg.StrokeWidth.2, .Svg.Fill.None]`, label
  `[.A11y.SrOnly]`.

## Acceptance

### Delivered

- [x] `.Svg.Fill.Current` → `fill:currentcolor`; `Token.SvgStroke(value: paletteVar("blue", "500"))`
      constructs and emits `stroke:var(--color-blue-500)`; no hex in any test or example; no payload
      leaf inside a section; `svgTokenToCss` and its sub-dispatchers have no `_` arm.
- [x] `.Svg.StrokeWidth.2` → `stroke-width:2`; `Token.SvgStrokeWidthRaw(value: "3")` →
      `stroke-width:3`; `StrokeWidth.0` and `Stroke.None` asserted as different declarations.
- [x] The `sr-only` bodies were read from upstream (URL and date in the dispatcher banner) and are
      asserted whole as literals; `NotSrOnly` restores eight of `sr-only`'s nine properties, leaving
      `border-width`, as upstream does.
- [x] `.A11y.ForcedColorAdjust.None` → `forced-color-adjust:none`; `a11yTokenToCss` has no `_` arm.
- [x] Five `tokenToSheet` arms, the last section fence before front 34's, each one `declSheet(…)`,
      destructuring by declared field name; no `_` arm.
- [x] `Svg` and `A11y` hold no payload leaf; the eleven leaves and two palette payloads are well formed
      with no resolved colour; `repository/emilia/AGENTS.md` records the sections and both notes; green
      on commonJS and erlang.

## Examples

- [`./examples/svg-a11y-example.bp`](./examples/svg-a11y-example.bp) — the `Svg` and `A11y`
  catalogues, then an icon-only close button whose glyph is a stroked SVG and whose label is
  `sr-only`.
