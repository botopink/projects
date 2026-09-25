# Front 33 — emilia-color-palette

**Track:** D emilia
**Priority:** critical — every other emilia front that names a colour (borders, backgrounds, gradients, rings, shadows, SVG) resolves its value through this front's table. Until it lands they each invent a private one.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 2
**Depends on:** 54 (`Theme`, `themeVar`, `ThemeEntry`, `extendTheme`), 56 (`declSheet` — this front emits declarations only)
**Owns:** `repository/emilia/src/tokens.bp` (the `Color` section, the `Bg.Color` sub-section, the `Alpha` wrapper variant) · `repository/emilia/src/emilia.bp` (`colorTokenToCss`, `bgColorTokenToCss`, `paletteVar`, `alphaWrap`) · `repository/emilia/test/colors_test.bp`
**Does not touch:** every other token section; `Bg`'s non-colour sub-sections (front 39); the modifier variants (front 34)
**Reference:** `TAILWIND_CSS_DOCS.md § 3.6 Cores`, `§ 21.1 Paleta de Cores Padrão`, `§ 3.5 Namespaces de Variáveis de Tema` · https://tailwindcss.com/docs/colors

---

## Problem

A developer using `emilia` today can write four colours. `tokens.bp:72-116` declares `Color` with
`Red`, `Blue`, `Green` and `Gray`; `tokens.bp:118-138` declares `Bg` with `Red`, `Blue` and `Gray`.
Tailwind v4.3 ships twenty-six families of eleven shades each (`§ 3.6`, `§ 21.1`). So twenty-two
families have no token at all, and of the four that exist, `Green` carries five shades instead of
eleven and `Bg.Red` carries three.

The dispatcher is worse than the enum. `colorTokenToCss` (`emilia.bp:156-167`) matches
`Red(_inner) -> "color:red"` — it discards the shade it was handed and emits the CSS keyword `red`.
`.Color.Red.100` and `.Color.Red.900` produce byte-identical CSS today, which means the shade level
exists in the type and does nothing in the output. `bgTokenToCss` (`emilia.bp:169-179`) does the
same. There is one correct palette function in the file, `redPaletteHex` (`emilia.bp:385-398`), and
nothing calls it — it is dead code holding nine Tailwind v3 hex values.

Opacity has no surface whatsoever. `bg-red-500/50` is the single most used colour form in real
Tailwind markup and there is no token that expresses it.

## Current state

Examples use the pre-118 effect annotations; front 24's codemod rewrites them ([`00 · 24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)).

| What | Where | State |
|---|---|---|
| `Color { Red, Blue, Green, Gray, White, Black, Hex(value) }` | `tokens.bp:72-116` | 4 families; Red/Blue/Gray carry `100..900`, Green carries `100,300,500,700,900` |
| `Bg { Red, Blue, Gray, White, Black, Hex(value) }` | `tokens.bp:118-138` | 3 families, 3–4 shades each |
| `colorTokenToCss` | `emilia.bp:156-167` | shade discarded; emits `color:red` / `color:blue` / `color:green` / `color:gray` |
| `bgTokenToCss` | `emilia.bp:169-179` | shade discarded; emits `background:red` etc. — and `background`, not `background-color` |
| `redPaletteHex` | `emilia.bp:385-398` | correct shape, v3 hex values, zero callers |
| opacity on a colour | — | does not exist |

`Color.Hex(value: string)` and `Bg.Hex(value: string)` exist in the enum and are matched by the
dispatchers, but **no caller can construct them**. See *Language gaps* — this is a compiler
limitation, verified, not a missing library function.

## Mechanism

Tailwind v4 does not inline colour values into utility rules. It defines them once in the theme
layer as custom properties and every utility references one:

```css
@theme { --color-red-500: oklch(0.637 0.237 25.331); }   /* § 3.6 */
.text-red-500 { color: var(--color-red-500); }
```

That two-layer shape is visible throughout the reference: `§ 9.1` emits `font-family: var(--font-sans)`,
`§ 9.2` emits `font-size: var(--text-xs)`, `§ 11.1` emits `border-radius: var(--radius-sm)`,
`§ 12.1` emits `box-shadow: var(--shadow-sm)`. emilia mirrors it exactly, which is what makes the
utility half byte-equal without needing all 286 numeric values in the repository:

- **The token emits the reference.** `.Color.Red.500` produces `color:var(--color-red-500)`. That
  string is byte-equal to Tailwind's utility rule body, and it is derivable entirely from the
  reference's own convention.
- **The theme block is a separate, one-time artifact, and front 54 owns the machinery.**
  `defaultTheme()` carries only `--color-black` and `--color-white`; the 286-entry grid is this
  front's, handed over as `paletteEntries() -> ThemeEntry[]` and composed in by a consumer through
  front 54's `extend`. The utility side reads it back with `paletteVar(family, shade)`, which is a
  one-line wrapper over front 54's `themeVar`:
  `themeVar("color-" + family + "-" + shade)` → `var(--color-red-500)`. The numeric OKLCH values in
  those entries come from upstream `theme.css`, not from this spec — the reference prints only two
  of them (`§ 3.6`). See *Reference gaps*.

The enum shape follows the path form the language already supports. A four-segment path resolves
(`.Bg.Color.Red.500`), a numeric leaf is bare digits in the declaration and in expression position,
and `__`-prefixed in a `case` pattern. Both were verified against the compiler at
`zig-out/bin/botopink` before this spec was written.

Opacity cannot be a leaf under the family, because the shade level is already the leaf and a second
numeric level would multiply 26 × 11 × 21 leaves. It is instead a **top-level payload variant**,
`Alpha(percent: i32, inner: Token[])`, which is the one payload shape the compiler can actually
construct (see *Language gaps*). Its dispatcher rewrites each inner declaration's value into a
`color-mix()` call. A payload variant carrying an `i32` alongside a `Token[]` was verified to
construct and destructure correctly.

## Token surface

The grid is regular, so the table below is written once per shape rather than once per leaf: every
one of the 26 families answers all 11 shades on both properties, which is 572 paths.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `text-red-50` | `.Color.Red.50` | `color:var(--color-red-50)` |
| `text-red-100` | `.Color.Red.100` | `color:var(--color-red-100)` |
| `text-red-200` | `.Color.Red.200` | `color:var(--color-red-200)` |
| `text-red-300` | `.Color.Red.300` | `color:var(--color-red-300)` |
| `text-red-400` | `.Color.Red.400` | `color:var(--color-red-400)` |
| `text-red-500` | `.Color.Red.500` | `color:var(--color-red-500)` |
| `text-red-600` | `.Color.Red.600` | `color:var(--color-red-600)` |
| `text-red-700` | `.Color.Red.700` | `color:var(--color-red-700)` |
| `text-red-800` | `.Color.Red.800` | `color:var(--color-red-800)` |
| `text-red-900` | `.Color.Red.900` | `color:var(--color-red-900)` |
| `text-red-950` | `.Color.Red.950` | `color:var(--color-red-950)` |
| `text-orange-500` | `.Color.Orange.500` | `color:var(--color-orange-500)` |
| `text-amber-500` | `.Color.Amber.500` | `color:var(--color-amber-500)` |
| `text-yellow-500` | `.Color.Yellow.500` | `color:var(--color-yellow-500)` |
| `text-lime-500` | `.Color.Lime.500` | `color:var(--color-lime-500)` |
| `text-green-500` | `.Color.Green.500` | `color:var(--color-green-500)` |
| `text-emerald-500` | `.Color.Emerald.500` | `color:var(--color-emerald-500)` |
| `text-teal-500` | `.Color.Teal.500` | `color:var(--color-teal-500)` |
| `text-cyan-500` | `.Color.Cyan.500` | `color:var(--color-cyan-500)` |
| `text-sky-500` | `.Color.Sky.500` | `color:var(--color-sky-500)` |
| `text-blue-500` | `.Color.Blue.500` | `color:var(--color-blue-500)` |
| `text-indigo-500` | `.Color.Indigo.500` | `color:var(--color-indigo-500)` |
| `text-violet-500` | `.Color.Violet.500` | `color:var(--color-violet-500)` |
| `text-purple-500` | `.Color.Purple.500` | `color:var(--color-purple-500)` |
| `text-fuchsia-500` | `.Color.Fuchsia.500` | `color:var(--color-fuchsia-500)` |
| `text-pink-500` | `.Color.Pink.500` | `color:var(--color-pink-500)` |
| `text-rose-500` | `.Color.Rose.500` | `color:var(--color-rose-500)` |
| `text-slate-500` | `.Color.Slate.500` | `color:var(--color-slate-500)` |
| `text-gray-500` | `.Color.Gray.500` | `color:var(--color-gray-500)` |
| `text-zinc-500` | `.Color.Zinc.500` | `color:var(--color-zinc-500)` |
| `text-neutral-500` | `.Color.Neutral.500` | `color:var(--color-neutral-500)` |
| `text-stone-500` | `.Color.Stone.500` | `color:var(--color-stone-500)` |
| `text-mauve-500` | `.Color.Mauve.500` | `color:var(--color-mauve-500)` |
| `text-olive-500` | `.Color.Olive.500` | `color:var(--color-olive-500)` |
| `text-mist-500` | `.Color.Mist.500` | `color:var(--color-mist-500)` |
| `text-taupe-500` | `.Color.Taupe.500` | `color:var(--color-taupe-500)` |
| `text-white` | `.Color.White` | `color:var(--color-white)` |
| `text-black` | `.Color.Black` | `color:var(--color-black)` |
| `text-transparent` | `.Color.Transparent` | `color:transparent` |
| `text-current` | `.Color.Current` | `color:currentColor` |
| `text-inherit` | `.Color.Inherit` | `color:inherit` |
| `bg-red-500` | `.Bg.Color.Red.500` | `background-color:var(--color-red-500)` |
| `bg-sky-100` | `.Bg.Color.Sky.100` | `background-color:var(--color-sky-100)` |
| `bg-slate-900` | `.Bg.Color.Slate.900` | `background-color:var(--color-slate-900)` |
| `bg-taupe-950` | `.Bg.Color.Taupe.950` | `background-color:var(--color-taupe-950)` |
| `bg-white` | `.Bg.Color.White` | `background-color:var(--color-white)` |
| `bg-black` | `.Bg.Color.Black` | `background-color:var(--color-black)` |
| `bg-transparent` | `.Bg.Color.Transparent` | `background-color:transparent` |
| `bg-red-500/50` | `Token.Alpha(percent: 50, inner: [.Bg.Color.Red.500])` | `background-color:color-mix(in oklab, var(--color-red-500) 50%, transparent)` |
| `text-blue-600/80` | `Token.Alpha(percent: 80, inner: [.Color.Blue.600])` | `color:color-mix(in oklab, var(--color-blue-600) 80%, transparent)` |

The eleven shades are `50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950`. The 26 families are
the seventeen chromatic (`Red Orange Amber Yellow Lime Green Emerald Teal Cyan Sky Blue Indigo
Violet Purple Fuchsia Pink Rose`) and the nine neutral (`Slate Gray Zinc Neutral Stone Mauve Olive
Mist Taupe`) of `§ 21.1`.

**Note on the family count.** `overview.md` says "22 families × 11 shades". The reference says 17
chromatic + 9 neutral = 26 (`§ 3.6`, `§ 21.1`). This front implements 26; the overview's figure is
the one that is wrong.

## Steps

### Step 1 — the family and shade grid

One section per family under `Color`, eleven numeric leaves each. Families from `§ 3.6` and
`§ 21.1`: seventeen chromatic and nine neutral.

```bp
// appended to `pub type Token { … }` in tokens.bp, under the front-33 banner
    Color {
        Red    { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Orange { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Amber  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Yellow { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Lime   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Green  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Emerald{ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Teal   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Cyan   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Sky    { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Indigo { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Violet { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Purple { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Fuchsia{ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Pink   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Rose   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Slate  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Gray   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Zinc   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Neutral{ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Stone  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Mauve  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Olive  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Mist   { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Taupe  { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        White,
        Black,
        Transparent,
        Current,
        Inherit,
        Hex(value: string),
    }
```

The existing `Red`, `Blue`, `Green` and `Gray` sections are widened in place, not replaced — every
path that compiles today still compiles. `Green` gains `50, 200, 400, 600, 800, 950`; `Red`, `Blue`
and `Gray` gain `50` and `950`.

**Acceptance:**
- [ ] `.Color.Red.500` type-checks and emits `color:var(--color-red-500)`
- [ ] `.Color.Taupe.950` type-checks and emits `color:var(--color-taupe-950)`
- [ ] `.Color.Green.400` type-checks — it does not today
- [ ] every one of the 26 families answers all 11 shades: 286 assertions, generated as one test per family
- [ ] `.Color.Blue.700`, valid today, still emits under the new dispatcher — with a different body than before, which is the point
- [ ] `tokens.bp` carries no `//` comment inside the `pub type Token` braces (parser constraint — the section map stays in the `////` header)

### Step 2 — `Bg.Color`, the same grid for background-color

`fronts.md` assigns `Bg.Color` to this front and the rest of `Bg` to front 39. The grid is
identical; only the emitted property differs.

```bp
    Bg {
        Color {
            Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
            // … the same 26 families, White, Black, Transparent, Current, Inherit …
        }
    }
```

Note that today's `Bg` emits `background:red` — the shorthand property, not `background-color`.
Tailwind emits `background-color` (`§ 10.3`). The new sub-section emits the correct property; the
legacy `Bg.Red` / `Bg.Blue` / `Bg.Gray` paths keep their current output so nothing that compiles
today changes meaning.

**Acceptance:**
- [ ] `.Bg.Color.Red.500` emits `background-color:var(--color-red-500)`
- [ ] `.Bg.Color.White` emits `background-color:var(--color-white)`
- [ ] `.Bg.White`, the legacy path, still emits `background:#ffffff` — `emilia.bp:419-421` still passes
- [ ] the four-segment path `.Bg.Color.<Family>.<shade>` resolves for all 26 families

### Step 3 — the palette helper and the theme preamble

`paletteVar` is one fn per level, matching emilia's existing dispatcher shape (`val out = case …;
return out;`). The family dispatcher returns the family's kebab name, the shade dispatcher returns
the numeral, and the caller concatenates.

Per contract 4a in [`contracts.md`](../../contracts.md), every sub-dispatcher takes the `Theme`:

```bp
fn colorTokenToCss(t: Token.Color, th: Theme) -> string {
    val out = case t {
        Red(_inner) -> "color:var(--color-red-" + shadeName(_inner) + ")";
        // … one arm per family …
        White -> "color:var(--color-white)";
        Black -> "color:var(--color-black)";
        Transparent -> "color:transparent";
        Current -> "color:currentColor";
        Inherit -> "color:inherit";
        Hex(value) -> "color:" + value;
    };
    return out;
}
```

`paletteEntries() -> ThemeEntry[]` is this front's contribution to front 54's theme. It is a plain
list of entries, not a rendered block: a consumer composes it with `extend`, and front 54's
`themeCss` renders it into the `theme` layer. Keeping it a list rather than a string is what lets a
project that already imports Tailwind's own theme leave it out and still use every colour token.

**Acceptance:**
- [ ] `paletteEntries()` carries `--color-red-500` as `oklch(0.637 0.237 25.331)` — the value the reference prints (`§ 3.6`)
- [ ] it carries `--color-blue-500` as `oklch(0.623 0.214 259.815)` — likewise
- [ ] it returns 286 entries; `--color-white` and `--color-black` stay in front 54's `defaultTheme()` and are **not** duplicated here
- [ ] `paletteVar(family, shade)` is `themeVar("color-" + family + "-" + shade)` and spells the prefix once
- [ ] every other numeric value is transcribed from upstream `theme.css`, with the upstream commit recorded in the test file's header — see *Reference gaps*
- [ ] `emilia(tokens)` output contains no `@theme` block: composing `paletteEntries()` into the theme is the consumer's call

### Step 4 — opacity

Tailwind's `/N` suffix (`§ 3.6`, "Opacidade com cores") mixes the colour with transparent. The token
is a wrapper, because the payload must be constructible and only a top-level variant is.

```bp
    Alpha(percent: i32, inner: Token[]),
```

```bp
fn tokenToCss(t: Token) -> string {
    val out = case t {
        // …
        Alpha(percent, inner) -> alphaWrap(percent, tokensToCss(inner));
    };
    return out;
}
```

`alphaWrap` splits each `;`-separated declaration of the composed inner CSS at its first `:` and
rebuilds it as `prop:color-mix(in oklab, value <percent>%, transparent)`. Only string ops that exist
on `behavior String` are used — `split`, `indexOf`, `slice`, `join` — and the fn lives in ordinary
`.bp`, not in a comptime template body, so there is no prelude restriction on it.

**Acceptance:**
- [ ] `Token.Alpha(percent: 50, inner: [.Bg.Color.Red.500])` emits
      `background-color:color-mix(in oklab, var(--color-red-500) 50%, transparent)`
- [ ] `Token.Alpha(percent: 80, inner: [.Color.Blue.600])` emits
      `color:color-mix(in oklab, var(--color-blue-600) 80%, transparent)`
- [ ] an `Alpha` over two colour tokens rewrites both declarations
- [ ] an `Alpha` over a non-colour token leaves the declaration's value structurally intact — the
      front documents that the result is meaningless CSS rather than silently dropping it
- [ ] `Alpha` nests inside `Hover` and vice versa

### Step 5 — the palette stays compatible with a string-carrying leaf

`Color.Hex(value: string)` (`tokens.bp:115`) proves that an enum leaf can carry an arbitrary string
payload and splice it into the emitted CSS: `emilia.bp:164` matches it and concatenates. Tailwind's
arbitrary values are therefore expressible in principle, and **this front's palette is designed to
stay compatible with that rather than assuming a closed enum.**

One qualification, verified against `zig-out/bin/botopink` before this spec was written and recorded
in [`language-gaps.md`](../../language-gaps.md): a payload leaf **nested inside a section** has no
constructible spelling, so `Color.Hex` is reachable by a `case` arm and by nothing else. A
string-carrying leaf has to be a **top-level** `Token` variant to be built, which is the shape
`Token.Hover(inner: Token[])` already has and which does construct.

What that means for this front is concrete and small: nothing in the palette assumes its input comes
from an enum leaf. `paletteVar(family, shade)` takes two plain strings, and the property prefix lives
in the dispatcher rather than in the value, so front 57's escape hatch can hand a raw colour string
to the same formatter and get a well-formed declaration without a second palette table and without
this front changing shape. `Color.Hex`'s arm is kept, unchanged, as the proof that the splice works.

**Acceptance:**
- [ ] `colorTokenToCss`'s `Hex(value)` arm is retained unchanged
- [ ] `paletteVar(family: string, shade: string) -> string` is `pub` so front 57 can call it
- [ ] no fn in this front takes a `Token.Color` where a `string` would do — the palette is a
      string-to-string mapping with the enum only at its edge
- [ ] the README records that `.Color.Hex("#abc")` is unconstructible today, with the exact compiler
      error text, and that a top-level variant is the shape that works

## Examples

- `./examples/palette-example.bp` — the family/shade grid across chromatic and neutral families, the
  named colours, and a pricing badge that composes four colour tokens with `emilia(...)` and `flush()`.
- `./examples/opacity-example.bp` — the `Alpha` wrapper at four percentages, over text and background,
  and nested with a modifier; ends with a translucent overlay panel.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A payload leaf **nested inside an enum section** cannot be constructed by any spelling. `Tok.Color.Hex("#abc")` reds `'Hex' is not declared in any behavior implemented for 'Tok'`; `val h: Tok = .Color.Hex("#abc")` reds `unbound variable 'Color'`. The variant type-checks in a `case` pattern, so the surface looks complete and is not. | `examples/palette-example.bp`, the `Color.Hex` note | move the payload variant to the **top level** of the enum (`Token.ColorHex(value: string)`), where construction works | let the section-path resolver accept a trailing payload call, so `.Color.Hex("#abc")` builds `Color(Hex(value: "#abc"))` |
| A value of a **section type** cannot be constructed standalone. `val a: Token.Alpha = .50;` reds `this token cannot appear here`. Consequently a payload variant cannot take a section-typed field — `Token.Fade(amount: .Alpha.50, …)` reds `type mismatch: expected __Token__Alpha, got Token`. | the `Alpha` variant, Step 4 | give the payload a builtin type (`percent: i32`) | allow a dot-shorthand rooted at the declared section type of the parameter |

Both were verified by compiling probe libraries against `zig-out/bin/botopink` at the time of
writing, not inferred from the sources.

## Reference gaps

`TAILWIND_CSS_DOCS.md` does not carry these, and the CSS below must be checked against upstream
before implementation rather than trusted from this spec:

| Item | Why it is missing | What implementation must do |
|---|---|---|
| The 286 per-shade OKLCH values | `§ 3.6` prints exactly two (`--color-red-500`, `--color-blue-500`) and `§ 21.1` describes the grid without listing it | transcribe from upstream `packages/tailwindcss/theme.css`, record the commit in `test/colors_test.bp`'s header, and pin the two documented values as the conformance anchors |
| `color-mix()` and the `/N` opacity expansion | `§ 3.6` shows the class form `bg-red-500/50` but never its CSS | verify the emitted `color-mix(in oklab, … %, transparent)` against upstream; the `in oklab` colour space in particular is not documented locally |
| P3 / wide-gamut colour | absent entirely | out of scope for this front; do not invent a token for it |
| The utility CSS for `text-*` and `bg-*` colours | `§ 9.16` and `§ 10.3` show HTML, not CSS | the `prop: var(--token)` form is derived from the reference's own convention for theme-backed utilities (`§ 9.1`, `§ 9.2`, `§ 11.1`, `§ 12.1`); confirm against upstream before merge |

## Test plan

`repository/emilia/test/colors_test.bp`, a flat suite that bare-imports across `src`. Run with `botopink test` from
`repository/emilia`, and in the ecosystem gate with `zig build test-libs --  --lib emilia`.

Target: emilia has no target split, so the suite runs on **both** backends —
`botopink test` (commonJS, the default) and `botopink test --target erlang`. Both must produce the
same strings; a colour token that differs between them is a bug in `tokensToCss`, not in the palette.

What the tests assert:

1. **One test per family** — eleven asserts each, comparing `tokenToCss(.Color.<F>.<N>)` against the
   literal `"color:var(--color-<f>-<n>)"`. 26 tests, 286 asserts.
2. **`Bg.Color` mirror** — the same grid against `background-color:`.
3. **Named colours** — `White`, `Black`, `Transparent`, `Current`, `Inherit` on both properties.
4. **Legacy paths unchanged** — `.Color.Black`, `.Bg.White`, `.Color.Blue.700` still answer what
   `emilia.bp`'s existing tests assert.
5. **Theme entry anchors** — `paletteEntries()` contains an entry named `color-red-500` whose value
   is `oklch(0.637 0.237 25.331)`, and the blue equivalent; and `paletteVar("red", "500")` returns
   `var(--color-red-500)`.
6. **Alpha** — four percentages over text and background, one nested inside `Hover`.
7. **End to end** — `emilia([.Bg.Color.Slate.900, .Color.Slate.50])` then `await flush()` returns
   `"<style>." + cls + "{background-color:var(--color-slate-900);color:var(--color-slate-50)}</style>"`.

## Definition of done

- [ ] 26 families × 11 shades declared under `Color` and under `Bg.Color`, plus the five named colours
- [ ] `colorTokenToCss` and `bgColorTokenToCss` emit the shade; no arm discards its payload
- [ ] `paletteEntries()` returns the full 286-entry grid, with the two reference-documented values exact
- [ ] `Alpha(percent, inner)` composes with every colour token and with the modifiers
- [ ] the banner `// ── front 33 — colour palette ──` fences this front's block in both `tokens.bp` and `emilia.bp`, appended at the end of each file
- [ ] one arm added to the top-level `tokenToCss` case, in front-number order
- [ ] `repository/emilia/AGENTS.md` records the new section map in the same commit
- [ ] the front's tests are green on its assigned target — here, both backends, since emilia is comptime
