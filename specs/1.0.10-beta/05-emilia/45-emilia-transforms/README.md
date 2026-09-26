# Front 45 — emilia transforms

**Track:** D emilia · **Priority:** medium · **Level:** 3 (after 44 inside the level) · **Target:** comptime (commonJS and erlang)
**Depends on:** 44 (the `Transition.Transform` token exists; examples pair the two), 54 (`spacing(n)`, `themeVar`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 45 — transforms` block:
`Transform`, and the top-level `TransformRotateRaw`, `TransformTranslateRaw`) · `src/emilia.bp`
(front-45 block: `transformTokenToCss` and its sub-dispatchers — `transformRotateToCss`,
`transformRotateNegToCss`, … — all taking `th: Theme`; `transformEntries`, `rawRotate`,
`rawTranslate`; `transformSheet` and the `@property` registrations `twProperty` /
`translateProperties` / `chainProperties`; three `tokenToSheet` arms after front 44's) ·
`src/output.bp` (`propertiesFallback`, the `properties` layer in `renderDocument`)
**User docs:** `repository/emilia/docs.md` § *Transform*
**Reference:** `TAILWIND_CSS_DOCS.md § 16` · https://tailwindcss.com/docs/rotate · upstream Tailwind v4
(4.3.2, compiled output) where the reference file disagrees with it

**Open:** none.

---

## What it delivers

`§ 16` — one `Transform` section over seventeen sub-sections. In v4 `rotate`, `scale` and `translate`
are properties, not functions, so `[.Transform.Rotate.45, .Transform.Scale.110, .Transform.TranslateY.Full]`
is three declarations in one rule and none overwrites another. No leaf resolves a length (the `Px`
leaves' `1px` is the reference's own value).

| Group | Tokens | CSS |
|---|---|---|
| Rotate (`§ 16.4`) | `.Transform.Rotate.{0, 1, 45, 90, 180}`, `.Transform.Rotate.Neg.{1, 12, 45, 90, 180}` | `rotate:45deg`, `rotate:calc(12deg * -1)` (`Neg`: no spelling for a negative numeric leaf; upstream negates by multiplying) |
| Scale (`§ 16.5`) | `.Transform.Scale.{0, 50, 75, 90, 95, 100, 105, 110, 125, 150}`, `.ScaleX.*`, `.ScaleY.*` | upstream v4: `Scale.50` → `--tw-scale-x:50%;--tw-scale-y:50%;--tw-scale-z:50%;scale:var(--tw-scale-x) var(--tw-scale-y)`; `ScaleX.50` → `--tw-scale-x:50%` + the reader, so the axes compose; the three variables registered with `@property` (initial `1`) |
| Translate, one axis (`§ 16.10`) | `.Transform.TranslateX.{0, Px, 1, Half, Full}`, `.TranslateY.*` | the axis's variable, then both: `--tw-translate-x:calc(1 / 2 * 100%);translate:var(--tw-translate-x) var(--tw-translate-y)`; `TranslateX.1` writes `--tw-translate-x:calc(var(--spacing) * 1)` |
| Translate, both axes | `.Transform.Translate.{0, Px, 1, Half, Full}` | `--tw-translate-x:calc(1 / 2 * 100%);--tw-translate-y:calc(1 / 2 * 100%);translate:var(--tw-translate-x) var(--tw-translate-y)` |
| Skew (`§ 16.6`) | `.Transform.SkewX.{0, 1, 2, 3, 6, 12}`, `.SkewY.*` | `--tw-skew-x:skewX(3deg);transform:var(--tw-rotate-x,) var(--tw-rotate-y,) var(--tw-rotate-z,) var(--tw-skew-x,) var(--tw-skew-y,)` — upstream's; the reference file's `skew-x:` is not CSS and is never emitted |
| Origin (`§ 16.8`) | `.Transform.Origin.{Center, Top, TopRight, Right, BottomRight, Bottom, BottomLeft, Left, TopLeft}` | `transform-origin:top right` (two keywords) |
| Style / backface (`§ 16.9`, `16.1`) | `.Transform.Style.{Flat, Preserve3d}`, `.Transform.Backface.{Visible, Hidden}` | `transform-style:preserve-3d`, `backface-visibility:hidden` |
| Perspective (`§ 16.2`, `16.3`) | `.Transform.Perspective.{None, Dramatic, Near, Normal, Midrange, Distant}`, `.Transform.PerspectiveOrigin.{Center, Top, Bottom, Left, Right}` | `perspective:var(--perspective-near)`; `None` → `perspective:none` |
| Zoom (`§ 16.11`) | `.Transform.Zoom.{0, 50, 75, 100, 125, 150, 200}` | `zoom:0.5` (with the leading zero, as `§ 16.11` prints) |
| Shorthand (`§ 16.7`) | `.Transform.Shorthand.{None, Cpu, Gpu}` | `transform:none`; `Cpu` is the skew chain (`transform:var(--tw-rotate-x,) … var(--tw-skew-y,)`), `Gpu` puts `translateZ(0) ` in front of it — upstream v4's rows; `§ 16.7`'s `translate3d(…) rotate(…) scaleX(…)` values are v3's and are not emitted |
| Arbitrary | `Token.TransformRotateRaw(value)` / `rawRotate(v)`, `Token.TransformTranslateRaw(value)` / `rawTranslate(v)` | `rotate:<v>`, `translate:<v>` |

- **Translate axes compose.** A one-axis token writes its own `--tw-translate-<axis>` and reads both,
  so `[.TranslateX.Half, .TranslateY.Half]` moves diagonally. An axis no token set reads `0`:
  the identity default is not a theme entry (`--tw-` is in no `Ns` namespace and `extendTheme`
  panics on it) but upstream's `@property --tw-translate-{x,y,z}` registration (initial `0`), which
  each translate sheet carries as a `Block`.
- **Skews compose.** Each axis writes its `--tw-skew-<axis>`; the chain's empty fallbacks make an
  unset variable nothing, and each skew sheet registers the chain's five variables (no initial value).
- **The `@property` fallback.** For an engine without `@property`, `renderDocument` declares
  `@layer properties;` before every other layer and writes upstream's `@supports (…)` rule setting
  every registered variable's initial value (`initial` where it has none) on `*, ::before, ::after,
  ::backdrop` after the blocks; a document with no `@property` block declares no `properties` layer
  (`decisions-pending.md` 05emilia-i).
- **`transformEntries()`** contributes the five `--perspective-*` values (`100px`, `300px`, `500px`,
  `800px`, `1200px` — all printed by `§ 16.2`, none provisional) to `fullTheme()`.

## Acceptance

### Delivered

- [x] `.Transform.Rotate.90` → `rotate:90deg`; `Rotate.Neg.12` → `rotate:calc(12deg * -1)`;
      `Token.TransformRotateRaw(value: "17deg")` constructs; no payload leaf inside a section; the
      rotate dispatchers are exhaustive with no `_` arm.
- [x] `Scale.75` → the three `--tw-scale-*` at `75%` and the reader; `ScaleX.50` → `--tw-scale-x:50%`
      and `ScaleY.50` → `--tw-scale-y:50%`, asserted adjacently; the reference file's `scale:.5` /
      `scale:.5 1` asserted absent; `[.ScaleX.50, .ScaleY.150]` composes.
- [x] The ten one-axis translate rows write their axis's variable and the two-variable composition;
      `TranslateX.1` carries `calc(var(--spacing) * 1)`; no `rem` anywhere in the block;
      `[.TranslateX.Half, .TranslateY.Half]` writes both variables; every translate sheet carries the
      three `@property` blocks with initial `0`, and no rotate sheet carries one — `emilia.bp`
      "Transform.TranslateX — the five rows of `§ 16.10`, upstream v4's form", "… two axes write two
      variables…", "… the sheet carries upstream's three `@property` blocks".
- [x] `Transform.Translate` writes both variables and the composition — "Transform.Translate — both
      axes: both variables, then the composition".
- [x] The twelve skew leaves write `--tw-skew-*` and upstream's chain, each sheet registering the
      chain's five variables; `skew-x:` is asserted absent; two skews write both variables — "Transform.SkewX
      — upstream v4's variable and chain…", "Transform.Skew — the sheet carries the chain's five
      `@property` blocks", "… the reference file's `skew-x:` column is never emitted, and the axes compose".
- [x] `renderDocument` declares `@layer properties;` first and writes the `@supports` fallback last
      when a `@property` block is present, and nothing of it otherwise — `output.bp` "renderDocument —
      `@property` blocks bring upstream's `properties` layer", "renderDocument — no `@property` block,
      no `properties` layer".
- [x] Origin, style, backface, perspective, perspective-origin and zoom rows return the reference's
      strings; a scale percentage and `zoom:0.5` are asserted adjacently; the perspective keywords are theme
      references with no `px`, contributed by `transformEntries()`.
- [x] `Shorthand.Cpu` is the skew chain and `.Gpu` `translateZ(0)` + the chain, with no `@property`
      block; a `Cpu` reads the chain a `SkewX` writes — "Transform.Shorthand — upstream v4's three rows",
      "Transform.Shorthand — the chain it reads is the skew leaves' chain".
- [x] Three `tokenToSheet` arms after front 44's — `Transform` through `transformSheet`, the two raw
      variants `declSheet(…)`; no `_` arm.
- [x] The `skew` note, the translate shape and the `Neg` convention are stated in the `tokens.bp`
      docblock; `repository/emilia/AGENTS.md` records the section and the notes; the class name for a
      fixed list is a literal both targets agree on; green on commonJS and erlang.

## Not declared

- `rotate-x-*`, `rotate-y-*`, `rotate-z-*`, `translate-z-*`, `scale-z-*`: `§ 16` enumerates no 3-D
  axis variant. The rest of the 3-D surface (`transform-style`, `backface-*`, perspective) is shipped.

## Examples

- [`./examples/transforms-example.bp`](./examples/transforms-example.bp) — the `Transform` catalogue,
  a card that lifts and scales on hover with a
  transition, and a disclosure chevron that rotates 180° when open.
