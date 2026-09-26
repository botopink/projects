# Front 33 — emilia color palette

**Track:** D emilia · **Priority:** critical · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`Theme`, `themeVar`, `ThemeEntry`, `extendTheme`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 33 — colour palette` banner:
`Color`, `Bg.Color`, the top-level `Alpha`) · `src/emilia.bp` (front-33 block: `colorTokenToCss`,
`bgColorTokenToCss`, `paletteVar`, `alphaWrap`, `paletteEntries`; the `Color`/`Bg`/`Alpha` arms of
`tokenToSheet`)
**User docs:** `repository/emilia/docs.md` § *Color*, § *Bg.Color*, § *Alpha*, § *The colour palette*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.6`, `§ 21.1`, `§ 3.5` · https://tailwindcss.com/docs/colors

**Open:** none.

---

## What it delivers

The colour table every other front resolves through: 26 families × 11 shades on `color` and on
`background-color`, the five named colours, and upstream's `/N` opacity suffix.

- **Families** — seventeen chromatic (`Red Orange Amber Yellow Lime Green Emerald Teal Cyan Sky Blue
  Indigo Violet Purple Fuchsia Pink Rose`) and nine neutral (`Slate Gray Zinc Neutral Stone Mauve
  Olive Mist Taupe`); **shades** `50 100 200 300 400 500 600 700 800 900 950`.
- **The token emits the reference, never the value**; the theme holds the value:

| Tailwind | emilia token | CSS |
|---|---|---|
| `text-red-500` | `.Color.Red.500` | `color:var(--color-red-500)` |
| `text-white` / `text-black` | `.Color.White` / `.Color.Black` | `color:var(--color-white)` / `color:var(--color-black)` |
| `text-transparent` / `text-current` / `text-inherit` | `.Color.Transparent` / `.Current` / `.Inherit` | `color:transparent` / `color:currentColor` / `color:inherit` |
| `bg-red-500` | `.Bg.Color.Red.500` | `background-color:var(--color-red-500)` |
| `bg-white` / `bg-transparent` | `.Bg.Color.White` / `.Bg.Color.Transparent` | `background-color:var(--color-white)` / `background-color:transparent` |
| `bg-red-500/50` | `Token.Alpha(percent: 50, inner: [.Bg.Color.Red.500])` | `background-color:color-mix(in oklab, var(--color-red-500) 50%, transparent)` |
| `text-blue-600/80` | `Token.Alpha(percent: 80, inner: [.Color.Blue.600])` | `color:color-mix(in oklab, var(--color-blue-600) 80%, transparent)` |

- **`paletteEntries() -> ThemeEntry[]`** — the 286 `--color-<family>-<shade>` entries, transcribed from
  upstream `tailwindcss` 4.3.2 `theme.css` in upstream's spelling (`--color-red-500:
  oklch(63.7% 0.237 25.331)`, `--color-blue-500: oklch(62.3% 0.214 259.815)` — the two values the
  reference prints in decimal-lightness form). `--color-white`/`--color-black` stay in 54's
  `defaultTheme()`. Composed into `fullTheme()` by front 56; `emilia(tokens)` itself emits no
  `@theme` block.
- **`paletteVar(family, shade)`** — `themeVar(nsPrefix(Ns.Color) + family + "-" + shade)`; two plain
  strings in, the `--color-` prefix spelled once. `pub`, so front 57 and every colour-carrying front
  reuse it.
- **`alphaWrap(percent, css)`** — rewrites each `;`-separated declaration's value into
  `color-mix(in oklab, <value> <percent>%, transparent)`. A non-colour token under `Alpha` is rewritten
  too, into meaningless CSS, documented rather than dropped. `Alpha` nests inside modifiers and vice
  versa.
- **Legacy leaves** — `Bg`'s `Red`/`Blue`/`Gray`/`White`/`Black`/`Hex` keep the `background` shorthand
  and their earlier output (`.Bg.White` → `background:#ffffff`).
- **`Color.Hex(value)`** — the arm (`Hex(value) -> "color:" + value`) is kept, but the leaf is
  unconstructible (see *Language gaps*); arbitrary colours go through front 57.

## Acceptance

### Delivered

- [x] `.Color.Red.500` → `color:var(--color-red-500)`, `.Color.Taupe.950` →
      `color:var(--color-taupe-950)`; every family answers all eleven shades (26 tests, 286 asserts).
- [x] The widened `Red`/`Blue`/`Green`/`Gray` paths still compile (e.g. `.Color.Green.400`,
      `.Color.Blue.700`) and now carry their shade.
- [x] `tokens.bp` carries `//` banners inside the `pub type Token` braces, green on both targets.
- [x] `.Bg.Color.Red.500` → `background-color:var(--color-red-500)`; `.Bg.Color.White` →
      `background-color:var(--color-white)`; the four-segment path resolves for all 26 families; the
      legacy `.Bg.White` still emits `background:#ffffff`.
- [x] `paletteEntries()` returns 286 entries, carries the two reference anchors in upstream's `%`
      spelling, does not duplicate white/black, and records its source (upstream 4.3.2 `theme.css`)
      in the banner above it.
- [x] `paletteVar` spells the prefix once; no fn takes a `Token.Color` where a string would do.
- [x] `emilia(tokens)` output carries no `@theme` block.
- [x] `Alpha` emits the two reference rows, rewrites both declarations of two colour tokens, rewrites
      a non-colour token into meaningless CSS, and nests with `Hover` both ways.
- [x] The shade survives: two shades of one family are different CSS.
- [x] The front-33 banner fences its block in `tokens.bp` and `emilia.bp`; its arms lead the section
      arms of `tokenToSheet`; `repository/emilia/AGENTS.md` records the section map.
- [x] Green on commonJS and erlang.

## Language gaps

| Gap | Nearest valid form | Proposed surface |
|---|---|---|
| A payload leaf nested inside an enum section cannot be constructed: `Tok.Color.Hex("#abc")` reds `'Hex' is not declared in any behavior implemented for 'Tok'`; `val h: Tok = .Color.Hex("#abc")` reds `unbound variable 'Color'` — while the variant type-checks in a `case` pattern | a **top-level** payload variant (`Token.Alpha(…)`, front 57's `Arb*`) | let the section-path resolver accept a trailing payload call |
| A value of a section type cannot be constructed standalone (`val a: Token.Alpha = .50;` reds `this token cannot appear here`), so a payload cannot take a section-typed field | a builtin-typed payload (`percent: i32`) | a dot-shorthand rooted at the parameter's declared section type |

## Examples

- [`./examples/palette-example.bp`](./examples/palette-example.bp) — the grid across chromatic and
  neutral families, the named colours, and a pricing badge composing four colour tokens.
- [`./examples/opacity-example.bp`](./examples/opacity-example.bp) — `Alpha` at four percentages, over
  text and background, nested with a modifier; a translucent overlay panel.
