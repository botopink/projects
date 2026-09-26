# Front 39 — emilia backgrounds

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 33 (`paletteVar` for the gradient stops), 54 (`Theme`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (front-39 fences: the non-colour sub-sections
of `Bg`, after `Bg.Color` and the legacy leaves, and the top-level `Gradient`) · `src/emilia.bp`
(front-39 block: the new `bgTokenToCss` arms, `gradientTokenToCss`, `gradientToTokenToCss`,
`linearGradient`, the stop dispatchers; the `Gradient` arm of `tokenToSheet`)
**Does not own:** `Bg.Color` and the legacy `Bg` leaves (front 33)
**User docs:** `repository/emilia/docs.md` § *Bg — the rest of the background*, § *Gradient*
**Reference:** `TAILWIND_CSS_DOCS.md § 10` (10.1–10.8) · https://tailwindcss.com/docs/background-attachment

**Open:** none.

---

## What it delivers

The non-colour half of `§ 10` and linear gradients — **910 leaves**. Every sub-dispatcher is
`(t, th: Theme) -> string` through `declSheet`; none resolves a length or holds a colour table.

| Group | Tokens | CSS |
|---|---|---|
| Attachment (`§ 10.1`) | `.Bg.Attachment.{Fixed, Local, Scroll}` | `background-attachment:…` |
| Clip (`§ 10.2`) | `.Bg.Clip.{Border, Padding, Content, Text}` | `background-clip:border-box` …; `Text` → `background-clip:text` |
| Origin (`§ 10.5`) | `.Bg.Origin.{Border, Padding, Content}` | `background-origin:…-box` |
| Position (`§ 10.6`) | `.Bg.Pos.{Bottom, Center, Left, LeftBottom, LeftTop, Right, RightBottom, RightTop, Top}` | `background-position:left bottom` (one space). `Pos`, not `Position`: distinct from `.Layout.Position` |
| Repeat (`§ 10.7`) | `.Bg.Repeat.{Repeat, None, X, Y, Round, Space}` | `None` → `background-repeat:no-repeat`; `X` → `repeat-x` |
| Size (`§ 10.8`) | `.Bg.Size.{Auto, Cover, Contain}` | `background-size:…` |
| Image (`§ 10.4`) | `.Bg.Image.None` | `background-image:none` |
| Direction (`§ 10.4`) | `.Gradient.To.{T, Tr, R, Br, B, Bl, L, Tl}` | `background-image:linear-gradient(to top right, var(--tw-gradient-stops))` — corners are two keywords, one space after the comma, phrases spelled once |
| Stops | `.Gradient.From`, `.Gradient.Via`, `.Gradient.Stop` — each the full 26 × 11 grid plus `White`, `Black`, `Transparent`, `Current`, `Inherit` | see below |

```
.Gradient.From.Indigo.500
  --tw-gradient-from:var(--color-indigo-500);
  --tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to, transparent)
.Gradient.Via.Purple.500
  --tw-gradient-via:var(--color-purple-500);
  --tw-gradient-stops:var(--tw-gradient-from, transparent), var(--tw-gradient-via), var(--tw-gradient-to, transparent)
.Gradient.Stop.Pink.500
  --tw-gradient-to:var(--color-pink-500)
```

- `To` is the direction and `Stop` the terminal colour — Tailwind's shared word `to` is not copied.
- The stop colour is `paletteVar(family, shade)`, so a stop and `.Bg.Color.*` reference one custom
  property by construction.
- The property names are upstream's; the composition is simpler (no position variables, no
  `@property` block), and upstream's `#0000` `@property` default is carried as a `var(…, transparent)`
  fallback so a lone `From` still paints.
- **Token order is load-bearing:** `Via`'s three-stop list overrides `From`'s two-stop list only when
  listed after it; `Stop` writes no list.

## Acceptance

### Delivered

- [x] Three attachment, four clip, three origin values; nine positions (two-word values with one
      space); six repeat values (`None` → `no-repeat`); three sizes; `.Bg.Image.None`.
- [x] `.Bg.Pos.*` and `.Layout.Position.*` are distinct paths; the legacy `Bg` leaves (`.Bg.White` →
      `background:#ffffff`) are byte-identical.
- [x] The eight direction phrases exactly as `§ 10.4` prints them, one space after the comma, spelled
      in one place.
- [x] `.Gradient.From.Indigo.500` and `.Bg.Color.Indigo.500` read one custom property; `From`, `Via`
      and `Stop` emit the shapes above; a `From` + `Via` + `Stop` triple composes and reversing the
      lists reverses which wins; the names were checked against upstream.
- [x] Arrow arms, the `val out = case …; return out;` idiom, `(t, th: Theme) -> string` everywhere, no
      `…TokenToSheet`; the `Bg` sub-sections follow front 33's block; the `Gradient` arm sits between
      fronts 38 and 40.
- [x] Every documented `§ 10.1`–`§ 10.8` utility has a token; all 910 leaves declare something; the
      undocumented gradient families are recorded below, not guessed.
- [x] `repository/emilia/AGENTS.md` and the `tokens.bp` header record the sections; green on
      commonJS and erlang.

## Not declared

The local reference documents none of these, and emilia does not invent CSS for them:

- colour-stop positions (`from-10%`, `via-30%`, `to-90%`);
- radial and conic gradients (`bg-radial`, `bg-conic`);
- gradient interpolation suffixes (`bg-linear-to-r/oklch`, `/srgb`, `/longer`);
- arbitrary images, sizes and positions (`bg-[url(…)]`, `bg-size-[…]`, `bg-position-[…]`) — front 57.

## Examples

- [`./examples/backgrounds-example.bp`](./examples/backgrounds-example.bp) — attachment, clip,
  origin, position, repeat, size and `bg-none`; a hero panel whose photograph covers and is anchored
  to the top.
- [`./examples/gradients-example.bp`](./examples/gradients-example.bp) — the eight directions and the
  three stops; a gradient call-to-action and a `bg-clip-text` heading.
