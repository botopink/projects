# Front 45 — emilia transforms

**Track:** D emilia · **Priority:** medium · **Level:** 3 (after 44 inside the level) · **Target:** comptime (commonJS and erlang)
**Depends on:** 44 (the `Transition.Transform` token exists; examples pair the two), 54 (`spacing(n)`, `themeVar`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 45 — transforms` block:
`Transform`, and the top-level `TransformRotateRaw`, `TransformTranslateRaw`) · `src/emilia.bp`
(front-45 block: `transformTokenToCss` and its sub-dispatchers — `transformRotateToCss`,
`transformRotateNegToCss`, … — all taking `th: Theme`; `transformEntries`, `rawRotate`,
`rawTranslate`; three `tokenToSheet` arms after front 44's)
**User docs:** `repository/emilia/docs.md` § *Transform*
**Reference:** `TAILWIND_CSS_DOCS.md § 16` · https://tailwindcss.com/docs/rotate

**Open:** none.

---

## What it delivers

`§ 16` — one `Transform` section over seventeen sub-sections. In v4 `rotate`, `scale` and `translate`
are properties, not functions, so `[.Transform.Rotate.45, .Transform.Scale.110, .Transform.TranslateY.Full]`
is three declarations in one rule and none overwrites another. No leaf resolves a length (the `Px`
leaves' `1px` is the reference's own value).

| Group | Tokens | CSS |
|---|---|---|
| Rotate (`§ 16.4`) | `.Transform.Rotate.{0, 1, 45, 90, 180}`, `.Transform.Rotate.Neg.{1, 12, 45, 90, 180}` | `rotate:45deg`, `rotate:-12deg` (`Neg`: no spelling for a negative numeric leaf) |
| Scale (`§ 16.5`) | `.Transform.Scale.{0, 50, 75, 90, 95, 100, 105, 110, 125, 150}`, `.ScaleX.*`, `.ScaleY.*` | `scale:.5` (no leading zero), `scale:1`; `ScaleX.50` → `scale:.5 1`, `ScaleY.50` → `scale:1 .5` |
| Translate, one axis (`§ 16.10`) | `.Transform.TranslateX.{0, Px, 1, Half, Full}`, `.TranslateY.*` | one declaration: `translate:50% var(--tw-translate-y, 0)`, `translate:var(--tw-translate-x, 0) 50%`; `TranslateX.1` → `translate:calc(var(--spacing) * 1) var(--tw-translate-y, 0)` |
| Translate, both axes | `.Transform.Translate.{0, Px, 1, Half, Full}` | `translate:50% 50%` — the value on each axis, no `--tw-` fallback |
| Skew (`§ 16.6`) | `.Transform.SkewX.{0, 1, 2, 3, 6, 12}`, `.SkewY.*` | `transform:skewX(3deg)` — upstream's property; the reference file's `skew-x:` is not CSS and is never emitted |
| Origin (`§ 16.8`) | `.Transform.Origin.{Center, Top, TopRight, Right, BottomRight, Bottom, BottomLeft, Left, TopLeft}` | `transform-origin:top right` (two keywords) |
| Style / backface (`§ 16.9`, `16.1`) | `.Transform.Style.{Flat, Preserve3d}`, `.Transform.Backface.{Visible, Hidden}` | `transform-style:preserve-3d`, `backface-visibility:hidden` |
| Perspective (`§ 16.2`, `16.3`) | `.Transform.Perspective.{None, Dramatic, Near, Normal, Midrange, Distant}`, `.Transform.PerspectiveOrigin.{Center, Top, Bottom, Left, Right}` | `perspective:var(--perspective-near)`; `None` → `perspective:none` |
| Zoom (`§ 16.11`) | `.Transform.Zoom.{0, 50, 75, 100, 125, 150, 200}` | `zoom:0.5` (with the leading zero, as `§ 16.11` prints) |
| Shorthand (`§ 16.7`) | `.Transform.Shorthand.{None, Cpu, Gpu}` | `transform:none`; `Cpu`/`Gpu` emit `§ 16.7`'s composed values verbatim (`translate3d(var(--tw-translate-x), var(--tw-translate-y), 0) rotate(var(--tw-rotate)) …`) |
| Arbitrary | `Token.TransformRotateRaw(value)` / `rawRotate(v)`, `Token.TransformTranslateRaw(value)` / `rawTranslate(v)` | `rotate:<v>`, `translate:<v>` |

- **Translate axes do not compose.** Each one-axis token is one `translate:` declaration carrying the
  other axis as `var(--tw-translate-<other>, 0)` (the `0` is upstream's `@property` default, inlined
  through `cssVarOr` because `--tw-` is in no theme namespace); two axes in one list are two
  declarations of one property, last wins. `.Transform.Translate.*` or `rawTranslate` gives a
  diagonal.
- **Skews do not compose**: both axes write `transform`.
- **The `Cpu`/`Gpu` shorthand is inert**: the six `--tw-*` variables it reads are set by no emilia
  token. It is shipped for byte-equality and marked inert (docblock, `AGENTS.md`, `docs.md`, the
  example); fallbacks would make `Cpu` an identity transform overwriting a `skewX` beside it. Making
  it resolve needs `@property` emission, a new output kind of front 56's.
- **`transformEntries()`** contributes the five `--perspective-*` values (`100px`, `300px`, `500px`,
  `800px`, `1200px` — all printed by `§ 16.2`, none provisional) to `fullTheme()`.

## Acceptance

### Delivered

- [x] `.Transform.Rotate.90` → `rotate:90deg`; `Rotate.Neg.12` → `rotate:-12deg`;
      `Token.TransformRotateRaw(value: "17deg")` constructs; no payload leaf inside a section; the
      rotate dispatchers are exhaustive with no `_` arm.
- [x] `Scale.75` → `scale:.75`; `ScaleX.50` → `scale:.5 1` and `ScaleY.50` → `scale:1 .5`, asserted
      adjacently; `Scale.100` → `scale:1`.
- [x] The ten one-axis translate rows emit the one-declaration form; `TranslateX.1` carries
      `calc(var(--spacing) * 1)`; no `rem` anywhere in the block; `[.TranslateX.Half,
      .TranslateY.Half]` is two declarations, last wins; the inline `0` is asserted to be there
      because `--tw-*` is in no namespace.
- [x] `Transform.Translate` emits both axes with no fallback.
- [x] The twelve skew leaves emit `transform:skewX(…)`/`skewY(…)` and `skew-x:` is asserted absent;
      the upstream check is recorded with URL and date in the `emilia.bp` banner and `AGENTS.md`; the
      `tokens.bp` docblock carries the note.
- [x] Origin, style, backface, perspective, perspective-origin and zoom rows return the reference's
      strings; `scale:.5` and `zoom:0.5` are asserted adjacently; the perspective keywords are theme
      references with no `px`, contributed by `transformEntries()`.
- [x] `Shorthand.Cpu` and `.Gpu` are `§ 16.7`'s strings verbatim and are marked inert.
- [x] Three `tokenToSheet` arms after front 44's, each one `declSheet(…)`; no `_` arm.
- [x] The `skew` note, the translate shape and the `Neg` convention are stated in the `tokens.bp`
      docblock; `repository/emilia/AGENTS.md` records the section and the notes; the class name for a
      fixed list is a literal both targets agree on; green on commonJS and erlang.

## Not declared

- `rotate-x-*`, `rotate-y-*`, `rotate-z-*`, `translate-z-*`, `scale-z-*`: `§ 16` enumerates no 3-D
  axis variant. The rest of the 3-D surface (`transform-style`, `backface-*`, perspective) is shipped.

## Examples

- [`./examples/transforms-example.bp`](./examples/transforms-example.bp) — the `Transform` catalogue
  with the inert shorthand marked at its declaration, a card that lifts and scales on hover with a
  transition, and a disclosure chevron that rotates 180° when open.
