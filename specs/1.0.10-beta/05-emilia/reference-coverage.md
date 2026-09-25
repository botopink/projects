# Reference coverage — Tailwind CSS v4 against the emilia fronts

Reference: `/home/ericfillipe/develop/tailwindcss/TAILWIND_CSS_DOCS.md` (Tailwind v4.3, § 3–§ 21 plus the *Referência Rápida*), walked against the 22 emilia fronts 33–48 and 54–59 in this directory.
Status: `covered` — the front's token surface delivers the row byte-equal to the reference (or to what the reference prints); `partial` — a named subset, a value the front itself flags as unverified, or a mechanism split across fronts that neither claims; `missing` — no front declares it; `n/a` — a build-time or scanner concern emilia has no counterpart for (emilia hashes per call site and has no scanner).

## Summary

| Tailwind section | Fronts | Rows | covered | partial | missing | n/a |
|---|---|---|---|---|---|---|
| § 1 Introdução | — | 1 | 0 | 0 | 0 | 1 |
| § 2 Instalação | — | 1 | 0 | 0 | 0 | 1 |
| § 3 Conceitos fundamentais (3.1–3.9) | [33](./33-emilia-color-palette/README.md) [34](./34-emilia-modifiers/README.md) [35](./35-emilia-spacing-sizing/README.md) [36](./36-emilia-layout/README.md) [38](./38-emilia-typography/README.md) [40](./40-emilia-borders/README.md) [41](./41-emilia-effects/README.md) [42](./42-emilia-filters/README.md) [44](./44-emilia-transitions/README.md) [45](./45-emilia-transforms/README.md) [48](./48-emilia-attributes/README.md) [54](./54-emilia-theme/README.md) [56](./56-emilia-cascade-and-output/README.md) [57](./57-emilia-escape-hatches/README.md) [58](./58-emilia-container-queries/README.md) [59](./59-emilia-custom-utilities-and-variants/README.md) | 80 | 60 | 16 | 1 | 3 |
| § 4 Preflight | [55](./55-emilia-preflight/README.md) | 2 | 2 | 0 | 0 | 0 |
| § 5 Layout | [36](./36-emilia-layout/README.md) | 19 | 19 | 0 | 0 | 0 |
| § 6 Flexbox & Grid | [37](./37-emilia-grid/README.md) | 24 | 24 | 0 | 0 | 0 |
| § 7 Espaçamento (+ `space-*`) | [35](./35-emilia-spacing-sizing/README.md) | 3 | 3 | 0 | 0 | 0 |
| § 8 Dimensionamento | [35](./35-emilia-spacing-sizing/README.md) | 7 | 7 | 0 | 0 | 0 |
| § 9 Tipografia | [38](./38-emilia-typography/README.md) [33](./33-emilia-color-palette/README.md) [57](./57-emilia-escape-hatches/README.md) | 32 | 32 | 0 | 0 | 0 |
| § 10 Backgrounds | [39](./39-emilia-backgrounds/README.md) [33](./33-emilia-color-palette/README.md) [57](./57-emilia-escape-hatches/README.md) | 8 | 7 | 1 | 0 | 0 |
| § 11 Bordas (+ `ring-*`, `divide-*`) | [40](./40-emilia-borders/README.md) | 10 | 10 | 0 | 0 | 0 |
| § 12 Efeitos | [41](./41-emilia-effects/README.md) | 6 | 5 | 1 | 0 | 0 |
| § 13 Filtros | [42](./42-emilia-filters/README.md) [56](./56-emilia-cascade-and-output/README.md) | 11 | 10 | 1 | 0 | 0 |
| § 14 Tabelas | [43](./43-emilia-tables/README.md) | 4 | 4 | 0 | 0 | 0 |
| § 15 Transições & Animação | [44](./44-emilia-transitions/README.md) | 6 | 5 | 1 | 0 | 0 |
| § 16 Transforms | [45](./45-emilia-transforms/README.md) | 11 | 9 | 2 | 0 | 0 |
| § 17 Interatividade | [46](./46-emilia-interactivity/README.md) | 20 | 20 | 0 | 0 | 0 |
| § 18 SVG | [47](./47-emilia-svg-accessibility/README.md) | 3 | 3 | 0 | 0 | 0 |
| § 19 Acessibilidade | [47](./47-emilia-svg-accessibility/README.md) | 2 | 1 | 1 | 0 | 0 |
| § 20 Funções e Diretivas | [54](./54-emilia-theme/README.md) [56](./56-emilia-cascade-and-output/README.md) [59](./59-emilia-custom-utilities-and-variants/README.md) | 9 | 8 | 0 | 0 | 1 |
| § 21 Temas e Customização | [54](./54-emilia-theme/README.md) [33](./33-emilia-color-palette/README.md) [35](./35-emilia-spacing-sizing/README.md) [38](./38-emilia-typography/README.md) [40](./40-emilia-borders/README.md) [44](./44-emilia-transitions/README.md) | 7 | 6 | 1 | 0 | 0 |
| Referência Rápida | — | 1 | 0 | 0 | 0 | 1 |
| **Total** | 22 fronts | **267** | **235** | **24** | **1** | **7** |

## Main table

| Tailwind § / utility group | Front | Status | Note |
|---|---|---|---|
| § 1 Introdução | — | n/a | Prose. |
| § 2 Instalação (2.1–2.5 Vite / PostCSS / CLI / Play CDN / framework guides) | — | n/a | emilia is a comptime library that hashes per call site; there is no build plugin, CLI or CDN to install. |
| § 3.1 styling with utility classes | [48](./48-emilia-attributes/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | `emilia(tokens)` returns `e_<hex>`; 48 hands it on as attribute data (`styled`, `styledWith`) and as the bare string a `[class]={…}` hole takes (`cls`, `clsWith`); emilia renders no HTML. 48 records that a `[class]={…}` hole may not contain a space (`html.bp` frozen). |
| § 3.1 arbitrary values `bg-[#316ff6]` | [57](./57-emilia-escape-hatches/README.md) | covered | `Token.Arb(prop, value)` via `arbValue`, gated by `cssValue`/`cssIdent`; composes with `spacing(6)` and `themeVar`. |
| § 3.1 arbitrary CSS properties `[--gutter-width:1rem]` | [57](./57-emilia-escape-hatches/README.md) | covered | `Token.ArbProp(name, value)` via `arbProp`. |
| § 3.1 managing duplication (`@layer components { .btn-primary }`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | Bundles are `pub fn … -> Token[]`; `named("card", tokens)` lands in `@layer components`. |
| § 3.1 style conflicts (last rule wins) | [56](./56-emilia-cascade-and-output/README.md) | covered | Step 8: within a class, token order; across calls, registration order; unconditioned rules before at-rule rules. |
| § 3.1 important modifier `bg-red-500!` (per utility) | [56](./56-emilia-cascade-and-output/README.md) · [34](./34-emilia-modifiers/README.md) | partial | 56 ships `markImportant(Sheet)` and says "Front 34's `Important(inner)` modifier is one line on top of it"; 34's token surface declares no `Important` variant. The per-utility token is unplaced. |
| § 3.1 important flag (`@import "tailwindcss" important`) | [56](./56-emilia-cascade-and-output/README.md) | covered | `Options.important` / `withImportant`; `!important` appended per declaration. |
| § 3.1 prefix (`prefix(tw)`) | [56](./56-emilia-cascade-and-output/README.md) | covered | `withPrefix(o, "tw_")` renders `.tw_e_1`; plain concatenation, no escaped `.tw\:` form — stated divergence. |
| § 3.2 pseudo-classes hover / focus / focus-within / focus-visible / active / visited / target | [34](./34-emilia-modifiers/README.md) | covered | `Hover` emits `@media (hover: hover){&:hover{…}}`; six pre-existing modifiers corrected to the v4.3 form. |
| § 3.2 structural first / last / only / odd / even / *-of-type / empty | [34](./34-emilia-modifiers/README.md) | covered | Nine `selector`-only variants. |
| § 3.2 `nth-*` / `nth-last-*` | [34](./34-emilia-modifiers/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `Nth(index: i32, inner)`, `NthLast(index, inner)`; a formula (`nth-[2n+1]`) goes through 57 `ArbVariant`. |
| § 3.2 form states disabled / enabled / checked / indeterminate / default / optional / required / valid / invalid / user-valid / user-invalid / in-range / out-of-range / placeholder-shown / autofill / read-only | [34](./34-emilia-modifiers/README.md) | covered | Sixteen variants, selectors verbatim from the reference table. |
| § 3.2 `:has()` (`has-checked:`, `has-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | No named `Has*` token; 34 defers "arbitrary variant … on the escape-hatch front" and 57 does not name `has`. Expressible as `ArbVariant("&:has(:checked)", inner)`. |
| § 3.2 `:not()` (`hover:not-focus:`, `not-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | Same shape as `:has()`: only through `ArbVariant("&:not(:focus)", inner)`. |
| § 3.2 parent state `group-*` | [34](./34-emilia-modifiers/README.md) | partial | `GroupHover/Focus/Active/Disabled/Open` from the `&:is(:where(.group) … *)` template; other states via 57 `ArbVariant`. Named groups (`group/item`): "out of scope for this front". |
| § 3.2 sibling state `peer-*` | [34](./34-emilia-modifiers/README.md) | partial | `PeerHover/Focus/Checked/Invalid/Disabled/PlaceholderShown`; named peers out of scope (same note). |
| § 3.2 `in-[…]` (`:where(…) &`) | [57](./57-emilia-escape-hatches/README.md) | partial | Not named by 34 or 57; the selector has one `&`, so `ArbVariant` carries it. |
| § 3.2 pseudo-elements before / after / first-letter / first-line / placeholder / file / marker / selection / backdrop | [34](./34-emilia-modifiers/README.md) | covered | Nine variants; `Marker`/`Selection` keep the reference's `& ::` space; `Before`/`After` pair with 38's `Text.Content.*`. |
| § 3.2 media: responsive `md:` | [34](./34-emilia-modifiers/README.md) | covered | See § 3.3 rows. |
| § 3.2 media: `dark:` | [34](./34-emilia-modifiers/README.md) | covered | `@media (prefers-color-scheme: dark)`; class/attribute strategies see § 3.4. |
| § 3.2 media: `motion-safe:` / `motion-reduce:` | [34](./34-emilia-modifiers/README.md) | covered | `MotionSafe`, `MotionReduce`. |
| § 3.2 media: `contrast-more:` / `contrast-less:` / `forced-colors:` | [34](./34-emilia-modifiers/README.md) | covered | `ContrastMore`, `ContrastLess`, `ForcedColors`. |
| § 3.2 media: `print:` | [34](./34-emilia-modifiers/README.md) | covered | `Print` → `@media print`. |
| § 3.2 media: `supports-[…]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbAt("supports(display:grid)", inner)` → `@supports(display:grid){…}`; `cssQuery` refuses a leading `@`. |
| § 3.2 media: `portrait:` / `landscape:` | [34](./34-emilia-modifiers/README.md) | covered | `Portrait`, `Landscape`. |
| § 3.2 ARIA (`aria-checked:`, `aria-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | No named `Aria*` token in any front; `ArbVariant("&[aria-checked=\"true\"]", inner)` only. |
| § 3.2 data attributes (`data-active:`, `data-[size=large]:`) | [57](./57-emilia-escape-hatches/README.md) | partial | Same: `ArbVariant("&[data-size=large]", inner)` only. |
| § 3.2 `rtl:` / `ltr:` | [34](./34-emilia-modifiers/README.md) | covered | `[dir="rtl"] &` — `&` at the end. |
| § 3.2 `open:` / `inert:` | [34](./34-emilia-modifiers/README.md) | covered | `Open` → `&:open, &:popover-open`; `Inert` → `&:is([inert], [inert] *)`. |
| § 3.2 child selectors `*:` / `**:` | [34](./34-emilia-modifiers/README.md) | covered | `Children` → `:is(& > *)`, `Descendants` → `:is(& *)`; `**:data-avatar:` is `Descendants([ArbVariant(…)])`. |
| § 3.2 arbitrary variants `[&.is-dragging]:` / `[@supports(…)]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbVariant(selector, inner)` (`cssSelector` requires exactly one `&`), `ArbAt(query, inner)`. |
| § 3.2 registering custom variants (`@custom-variant theme-midnight`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | A custom variant is `fn (inner: Token[]) -> Token[]`; `selector(Variant(atRule: "", selector: "&:where([data-theme=\"midnight\"] *)"), inner)`. |
| § 3.2 full variant reference table (72 rows) | [34](./34-emilia-modifiers/README.md) · [57](./57-emilia-escape-hatches/README.md) | partial | Every non-bracket row has a token in 34. The five bracket-template rows `has-[…]`, `group-[…]`, `peer-[…]`, `in-[…]`, `not-[…]` have no named form and route through 57 `ArbVariant`. |
| § 3.3 default breakpoints sm / md / lg / xl / 2xl | [34](./34-emilia-modifiers/README.md) | covered | `Sm … X2xl` → `@media (width >= 40rem)` … `96rem`, rem not px. |
| § 3.3 mobile-first | [34](./34-emilia-modifiers/README.md) | covered | `width >=` queries; 56 orders unconditioned rules before at-rule rules. |
| § 3.3 breakpoint range `md:max-xl:` | [34](./34-emilia-modifiers/README.md) | covered | Nesting: `Md([MaxXl(inner)])`. |
| § 3.3 `max-*` breakpoints | [34](./34-emilia-modifiers/README.md) | covered | `MaxSm … MaxX2xl` → `@media (width < …)`. |
| § 3.3 custom breakpoints (`--breakpoint-xs: 30rem`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | 54 validates the `--breakpoint-*` namespace, but 34's ten variant fns return literal queries (`mdVariant()` = `@media (width >= 48rem)`) and read no theme; a theme entry adds no variant and moves none. |
| § 3.3 removing breakpoints (`--breakpoint-2xl: initial`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | `clearNamespace(th, Ns.Breakpoint)` empties the entries; `Token.X2xl` still exists and still emits `96rem`. |
| § 3.3 arbitrary breakpoints `min-[320px]:` / `max-[600px]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbMin(px, inner)` / `ArbMax(px, inner)`, gated by `cssLength`. |
| § 3.3 container queries `@container` + `@3xs … @7xl` | [58](./58-emilia-container-queries/README.md) | covered | `.Container.Inline/Normal/Size`; `containerAtMd(inner)` → `@container (width >= 28rem){…}`; the thirteen sizes read `--container-*` from the theme and panic on an empty value. |
| § 3.3 named containers `@container/main`, `@sm/main:` | [58](./58-emilia-container-queries/README.md) | covered | `ContainerNamed(name)` emits `container-type` + `container-name`; `containerNamed(size, name, inner)` → `@container main (width >= 24rem){…}`. |
| § 3.4 dark mode via `prefers-color-scheme` | [34](./34-emilia-modifiers/README.md) | covered | `Dark(inner)`. |
| § 3.4 class-based dark (`@custom-variant dark (&:where(.dark, .dark *))`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | 54 Step 6 ships `DarkMode.Class("dark")`, `darkSelector`, `darkAtRule` and says "Front 34 reads both and builds the variant"; 34 Step 3 says the class and attribute forms "are out of scope and named as such in *Reference gaps*". Neither wires `Dark` to the strategy. |
| § 3.4 data-attribute dark (`[data-theme=dark]`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | Same split: `DarkMode.Attribute("data-theme", "dark")` exists in 54; not consumed by 34. |
| § 3.4 JavaScript toggle | — | n/a | Runtime script, outside the stylesheet. |
| § 3.5 theme variables (`@theme { --color-mint-500 }`) | [54](./54-emilia-theme/README.md) | covered | `Theme(entries, keyframes, darkMode)`, `ThemeEntry`, `extend`, `themeVar`, `themeValue`; utilities emit `var(--…)` references. A new entry adds a variable, never a token — new utilities come from 57 `Arb` + `themeVar`. |
| § 3.5 namespace `--color-*` | [33](./33-emilia-color-palette/README.md) · [54](./54-emilia-theme/README.md) | covered | `paletteEntries()` (286 entries) composed by `extend`; `--color-white`/`--color-black` in `defaultTheme()`. |
| § 3.5 namespace `--font-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `.Font.Sans` → `font-family:var(--font-sans)`. |
| § 3.5 namespace `--text-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `.Text.Size.*` emits the `--text-*` / `--text-*--line-height` pair; 54 carries both entries. |
| § 3.5 namespace `--font-weight-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | Entries contributed by 38; the utility emits the literal `font-weight:700`, which is what § 9.5 prints. |
| § 3.5 namespace `--tracking-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `letter-spacing:var(--tracking-wide)`. |
| § 3.5 namespace `--leading-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `line-height:var(--leading-tight)`; `leading-none` is the literal `1`, as § 9.11 prints. |
| § 3.5 namespace `--breakpoint-*` | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | Validated prefix only; see § 3.3 custom breakpoints. |
| § 3.5 namespace `--container-*` | [58](./58-emilia-container-queries/README.md) · [54](./54-emilia-theme/README.md) | covered | Thirteen entries in `defaultTheme()`, read by 58; 35's `.Size.MaxW.Md` emits the literal `28rem` that § 8.3 prints. |
| § 3.5 namespace `--spacing-*` | [54](./54-emilia-theme/README.md) · [35](./35-emilia-spacing-sizing/README.md) | covered | `--spacing:0.25rem` (single variable, per § 21.2); `spacing(n)` → `calc(var(--spacing) * n)`, `spacing(0)` → `0`. |
| § 3.5 namespace `--radius-*` | [40](./40-emilia-borders/README.md) · [54](./54-emilia-theme/README.md) | covered | `border-radius:var(--radius-lg)`; `rounded-full` stays the literal `9999px`. |
| § 3.5 namespace `--shadow-*` | [41](./41-emilia-effects/README.md) · [54](./54-emilia-theme/README.md) | covered | `box-shadow:var(--shadow-md)`; seven values byte-equal to § 21.4. |
| § 3.5 namespace `--inset-shadow-*` | [41](./41-emilia-effects/README.md) · [54](./54-emilia-theme/README.md) | covered | `box-shadow:inset var(--inset-shadow-sm)`; literals are theme entries ("Closed by front 54"). |
| § 3.5 namespace `--drop-shadow-*` | [42](./42-emilia-filters/README.md) · [54](./54-emilia-theme/README.md) | covered | `filter:drop-shadow(var(--drop-shadow-md))`. |
| § 3.5 namespace `--blur-*` | [42](./42-emilia-filters/README.md) · [54](./54-emilia-theme/README.md) | covered | `blur(var(--blur-sm))`, shared by `Filter` and `Backdrop`. |
| § 3.5 namespace `--perspective-*` | [45](./45-emilia-transforms/README.md) · [54](./54-emilia-theme/README.md) | covered | `perspective:var(--perspective-near)` (`300px` in the theme). |
| § 3.5 namespace `--aspect-*` | [54](./54-emilia-theme/README.md) · [36](./36-emilia-layout/README.md) | covered | Validated prefix in 54; `.Layout.Aspect.Video` emits the literal `aspect-ratio:16 / 9` that § 5.1 prints — no theme lookup. |
| § 3.5 namespace `--ease-*` | [44](./44-emilia-transitions/README.md) · [54](./54-emilia-theme/README.md) | covered | `transition-timing-function:var(--ease-in)`; `ease-linear` is the keyword. |
| § 3.5 namespace `--animate-*` | [44](./44-emilia-transitions/README.md) · [54](./54-emilia-theme/README.md) | covered | `animation:var(--animate-spin)`; four values byte-equal to § 21.6. |
| § 3.5 extending the theme | [54](./54-emilia-theme/README.md) | covered | `extend(th, entries)`; an entry outside the nineteen prefixes fails the build, no relaxing argument. |
| § 3.5 overriding the theme | [54](./54-emilia-theme/README.md) | covered | `extend` with an existing name replaces the value. |
| § 3.5 replacing a namespace (`--color-*: initial`) | [54](./54-emilia-theme/README.md) | covered | `clearNamespace(th, Ns.Color)`. |
| § 3.5 fully custom theme (`--*: initial`) | [54](./54-emilia-theme/README.md) | covered | `emptyTheme()`. |
| § 3.5 custom animations (`@keyframes` inside `@theme`) | [54](./54-emilia-theme/README.md) · [44](./44-emilia-transitions/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | `Theme.keyframes` entries; `Block(header, body)` hoisted by `renderDocument`, deduplicated by header; `Token.AnimateRaw` names the animation. |
| § 3.5 `@theme inline` | — | missing | No front mentions it. emilia always emits `var(--x)` references; the inline (value-resolving) form has no equivalent. |
| § 3.5 `@theme static` | [54](./54-emilia-theme/README.md) | covered | emilia's always-on behaviour: "emilia's behaviour is `@theme static`, always, and the tree-shaken form is out of scope for this milestone". |
| § 3.6 default palette (26 families × 11 shades, black, white) | [33](./33-emilia-color-palette/README.md) | covered | `.Color.<Family>.<Shade>` and `.Bg.Color.…`; plus `Transparent`, `Current`, `Inherit`. |
| § 3.6 OKLCH values | [33](./33-emilia-color-palette/README.md) | partial | The reference prints two values (`red-500`, `blue-500`); the other 284 must be "transcribed from upstream `packages/tailwindcss/theme.css`" — front's own reference gap. |
| § 3.6 colour opacity `bg-red-500/50` | [33](./33-emilia-color-palette/README.md) | covered | `Token.Alpha(percent, inner)` → `color-mix(in oklab, var(--color-red-500) 50%, transparent)`; `in oklab` flagged for upstream check. |
| § 3.7 arbitrary values | [57](./57-emilia-escape-hatches/README.md) | covered | Same as § 3.1. |
| § 3.7 arbitrary variants `[&>[data-active]+span]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbVariant`. |
| § 3.7 custom CSS with `@layer components` / `@layer utilities` | [59](./59-emilia-custom-utilities-and-variants/README.md) | partial | `named()` always lands in `components`; a named class in `utilities` (`.text-balance`) is not possible: "`named()` takes no `layer:` argument because a per-call-site layer choice makes the …" (design constraint). Unnamed bundles land in `utilities` under their hash. |
| § 3.8 detecting classes in source files | — | n/a | emilia hashes per call site and has no scanner; the class exists because the call ran. |
| § 3.9 functions and directives | — | n/a | Duplicate of § 20; see those rows. |
| § 4 preflight resets (eight bullets) | [55](./55-emilia-preflight/README.md) | covered | `preflightRules()` — eleven `layer: "base"` rules; parity with the eight bullets, "explicitly **does not** claim byte-equality with upstream `preflight.css`". Adds `border-style:solid` beside `border-width:0`, stated as a decision. |
| § 4 disabling preflight (`@source not "tailwindcss/preflight"`) | [55](./55-emilia-preflight/README.md) | covered | Inverted: off by default, on via `withBase(defaultOptions(), preflightRules())`; "no function, field, file or environment variable … turns preflight on without passing it". |
| § 5.1 aspect-ratio | [36](./36-emilia-layout/README.md) | covered | `Aspect.Auto/Square/Video`; `aspect-[4/3]` → 57. |
| § 5.2 columns | [36](./36-emilia-layout/README.md) | covered | `1, 2, 3, Auto` + fourteen named widths; `columns-4…12` not declared ("must be confirmed against upstream"). |
| § 5.3 break-after | [36](./36-emilia-layout/README.md) | covered | Seven leaves. |
| § 5.4 break-before | [36](./36-emilia-layout/README.md) | covered | Same leaf set. |
| § 5.5 break-inside | [36](./36-emilia-layout/README.md) | covered | `Auto/Avoid/AvoidPage/AvoidColumn`. |
| § 5.6 box-decoration-break | [36](./36-emilia-layout/README.md) | covered | `BoxDecoration.Clone/Slice`. |
| § 5.7 box-sizing | [36](./36-emilia-layout/README.md) | covered | `Box.Border/Content`. |
| § 5.8 display | [36](./36-emilia-layout/README.md) | covered | Eleven leaves; the six existing paths keep their bytes. |
| § 5.9 float | [36](./36-emilia-layout/README.md) | covered | `float-start` → `float:inline-start`. |
| § 5.10 clear | [36](./36-emilia-layout/README.md) | covered | Six leaves. |
| § 5.11 isolation | [36](./36-emilia-layout/README.md) | covered | `Isolate`, `Auto`. |
| § 5.12 object-fit | [36](./36-emilia-layout/README.md) | covered | Five leaves. |
| § 5.13 object-position | [36](./36-emilia-layout/README.md) | covered | Nine leaves, two-word values single-spaced. |
| § 5.14 overflow | [36](./36-emilia-layout/README.md) | covered | Shorthand + `X` + `Y`, five values each. |
| § 5.15 overscroll-behavior | [36](./36-emilia-layout/README.md) | covered | Shorthand + `X` + `Y`, three values each. |
| § 5.16 position | [36](./36-emilia-layout/README.md) | covered | Five leaves. |
| § 5.17 top / right / bottom / left / inset | [36](./36-emilia-layout/README.md) | covered | `Inset.All/X/Y/T/R/B/L/S/E` over the spacing scale + `Auto`, `Full`, `Frac`, `Neg`; `top-[17px]` → 57. |
| § 5.18 visibility | [36](./36-emilia-layout/README.md) | covered | `invisible` → `visibility:hidden`. |
| § 5.19 z-index | [36](./36-emilia-layout/README.md) | covered | `0 10 20 30 40 50 Auto`; `z-[999]` → 57. |
| § 6.1 flex-basis | [37](./37-emilia-grid/README.md) | covered | Scale + `Auto`, `Full`, three fractions (the three the reference prints). |
| § 6.2 flex-direction | [37](./37-emilia-grid/README.md) | covered | `Row/RowReverse/Col/ColReverse`. |
| § 6.3 flex-wrap | [37](./37-emilia-grid/README.md) | covered | `Wrap/WrapReverse/NoWrap`. |
| § 6.4 flex | [37](./37-emilia-grid/README.md) | covered | `Flex.Value.One/Auto/Initial/None` (`Value` because a section cannot carry a sub-section of its own name). |
| § 6.5 flex-grow | [37](./37-emilia-grid/README.md) | covered | `Grow.0/1`. |
| § 6.6 flex-shrink | [37](./37-emilia-grid/README.md) | covered | `Shrink.0/1`. |
| § 6.7 order | [37](./37-emilia-grid/README.md) | covered | `1–12`, `First/Last/None`; 3–11 "by interpolation; confirm the set against upstream". |
| § 6.8 grid-template-columns | [37](./37-emilia-grid/README.md) | covered | `Cols.1–12/None/Subgrid`; 7–11 by interpolation (same note). |
| § 6.9 grid-column | [37](./37-emilia-grid/README.md) | covered | `Col.Auto`, `Col.Span.*`/`Full`, `Col.Start.*`, `Col.End.*`. |
| § 6.10 grid-template-rows | [37](./37-emilia-grid/README.md) | covered | `Rows.*/None/Subgrid`. |
| § 6.11 grid-row | [37](./37-emilia-grid/README.md) | covered | `Row.Auto/Span/Start/End`. |
| § 6.12 grid-auto-flow | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.13 grid-auto-columns | [37](./37-emilia-grid/README.md) | covered | `Auto/Min/Max/Fr`. |
| § 6.14 grid-auto-rows | [37](./37-emilia-grid/README.md) | covered | `Auto/Min/Max/Fr`. |
| § 6.15 gap | [37](./37-emilia-grid/README.md) | covered | `Gap.All/X/Y` over the spacing scale + `Px`; legacy `.Flex.Gap.*` kept. |
| § 6.16 justify-content | [37](./37-emilia-grid/README.md) | covered | Eight leaves, `flex-start`/`flex-end` asymmetry copied. |
| § 6.17 justify-items | [37](./37-emilia-grid/README.md) | covered | Four leaves. |
| § 6.18 justify-self | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.19 align-content | [37](./37-emilia-grid/README.md) | covered | Eight leaves. |
| § 6.20 align-items | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.21 align-self | [37](./37-emilia-grid/README.md) | covered | Six leaves. |
| § 6.22 place-content | [37](./37-emilia-grid/README.md) | covered | Seven leaves. |
| § 6.23 place-items | [37](./37-emilia-grid/README.md) | covered | Four leaves. |
| § 6.24 place-self | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 7.1 padding | [35](./35-emilia-spacing-sizing/README.md) | covered | Nine directions incl. `S`/`E` over 35 leaves; `padding-x:` defect removed. |
| § 7.2 margin | [35](./35-emilia-spacing-sizing/README.md) | covered | Nine directions + `Auto` + `Neg`. |
| § 7 `space-x-*` / `space-y-*` (not in the reference) | [35](./35-emilia-spacing-sizing/README.md) | covered | Beyond the reference: `.Space.X/Y` as `& > :not(:last-child){margin-inline-end:…}`; "a proposal, not a transcription", must match 40's `Divide` selector. |
| § 8.1 width | [35](./35-emilia-spacing-sizing/README.md) | covered | Scale, `Px`, eleven fractions, `Full/Screen/Svw/Lvw/Dvw/Min/Max/Fit/Auto`; fractions beyond the three printed "must be checked against upstream". |
| § 8.2 min-width | [35](./35-emilia-spacing-sizing/README.md) | covered | Five leaves. |
| § 8.3 max-width | [35](./35-emilia-spacing-sizing/README.md) | covered | `Xs…X7xl`, `Screen.Sm…X2xl`, `None/Full/0`. |
| § 8.4 height | [35](./35-emilia-spacing-sizing/README.md) | covered | `vh`/`svh`/`lvh`/`dvh` per axis. |
| § 8.5 min-height | [35](./35-emilia-spacing-sizing/README.md) | covered | Seven leaves. |
| § 8.6 max-height | [35](./35-emilia-spacing-sizing/README.md) | covered | Eight leaves. |
| § 8.7 logical properties (inline/block size) | [35](./35-emilia-spacing-sizing/README.md) | covered | `Inline/Block/MinInline/MaxInline/MinBlock/MaxBlock`; `Both` is `size-*`. |
| § 9.1 font-family | [38](./38-emilia-typography/README.md) | covered | `.Font.Sans/Serif/Mono` → `var(--font-*)`. |
| § 9.2 font-size | [38](./38-emilia-typography/README.md) | covered | Thirteen sizes, `font-size` + `line-height` pair. |
| § 9.3 font-smoothing | [38](./38-emilia-typography/README.md) | covered | Two two-declaration leaves. |
| § 9.4 font-style | [38](./38-emilia-typography/README.md) | covered | `Font.Style.Italic/Normal`; legacy `.Text.Italic` kept. |
| § 9.5 font-weight | [38](./38-emilia-typography/README.md) | covered | Nine literals, as printed. |
| § 9.6 font-stretch | [38](./38-emilia-typography/README.md) | covered | Nine leaves. |
| § 9.7 font-variant-numeric | [38](./38-emilia-typography/README.md) | covered | Nine leaves. |
| § 9.8 font-feature-settings | [57](./57-emilia-escape-hatches/README.md) | covered | Reference prints only the arbitrary form; `arbValue("font-feature-settings", …)`. |
| § 9.9 letter-spacing | [38](./38-emilia-typography/README.md) | covered | Six `var(--tracking-*)`. |
| § 9.10 line-clamp | [38](./38-emilia-typography/README.md) | covered | `Clamp.1–6/None`, four-declaration bodies. |
| § 9.11 line-height | [38](./38-emilia-typography/README.md) | covered | Five `var(--leading-*)` + `None` → `1`. |
| § 9.12 list-style-image | [38](./38-emilia-typography/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `List.ImageNone`; `list-image-[url(…)]` → 57. |
| § 9.13 list-style-position | [38](./38-emilia-typography/README.md) | covered | `Inside/Outside`. |
| § 9.14 list-style-type | [38](./38-emilia-typography/README.md) | covered | `None/Disc/Decimal` — the three printed. |
| § 9.15 text-align | [38](./38-emilia-typography/README.md) | covered | Six leaves. |
| § 9.16 color | [33](./33-emilia-color-palette/README.md) | covered | `.Color.*` → `color:var(--color-*)`. |
| § 9.17 text-decoration-line | [38](./38-emilia-typography/README.md) | covered | Four leaves; `text-decoration-line`, not `text-decoration`. |
| § 9.18 text-decoration-color | [38](./38-emilia-typography/README.md) | covered | `Decoration.Color.<Family>.<Shade>`. |
| § 9.19 text-decoration-style | [38](./38-emilia-typography/README.md) | covered | Five leaves. |
| § 9.20 text-decoration-thickness | [38](./38-emilia-typography/README.md) | covered | `Auto/FromFont/0/1/2/4`. |
| § 9.21 text-underline-offset | [38](./38-emilia-typography/README.md) | covered | `Auto/0/1/2/4`. |
| § 9.22 text-transform | [38](./38-emilia-typography/README.md) | covered | Four leaves. |
| § 9.23 text-overflow | [38](./38-emilia-typography/README.md) | covered | `Truncate` (three declarations), `Overflow.Ellipsis/Clip`. |
| § 9.24 text-wrap | [38](./38-emilia-typography/README.md) | covered | `Wrap/Nowrap/Balance/Pretty`. |
| § 9.25 text-indent | [38](./38-emilia-typography/README.md) | covered | `Indent.*` → `calc(var(--spacing) * N)`; form "inferred from § 21.2; confirm before merge". |
| § 9.26 tab-size | [38](./38-emilia-typography/README.md) | covered | `0/2/4/8`. |
| § 9.27 vertical-align | [38](./38-emilia-typography/README.md) | covered | Eight leaves. |
| § 9.28 white-space | [38](./38-emilia-typography/README.md) | covered | Six leaves. |
| § 9.29 word-break | [38](./38-emilia-typography/README.md) | covered | `Break.Normal/Words/All/Keep`. |
| § 9.30 overflow-wrap | [38](./38-emilia-typography/README.md) | covered | `OverflowWrap.Normal/BreakWord/Anywhere`. |
| § 9.31 hyphens | [38](./38-emilia-typography/README.md) | covered | Three leaves. |
| § 9.32 content | [38](./38-emilia-typography/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `Content.None/Empty`; `content-['Hello']` → 57. |
| § 10.1 background-attachment | [39](./39-emilia-backgrounds/README.md) | covered | `Bg.Attachment.Fixed/Local/Scroll`. |
| § 10.2 background-clip | [39](./39-emilia-backgrounds/README.md) | covered | Four leaves incl. `Text`. |
| § 10.3 background-color | [33](./33-emilia-color-palette/README.md) | covered | `.Bg.Color.*` → `background-color:`; legacy `.Bg.Red` keeps `background:`. |
| § 10.4 background-image | [39](./39-emilia-backgrounds/README.md) · [57](./57-emilia-escape-hatches/README.md) | partial | `Bg.Image.None` + eight `Gradient.To.*` covered. `Gradient.From/Via/Stop` declared but their CSS is "inferred … must be checked against upstream". Stop positions, radial/conic gradients and interpolation modifiers: "not declared by this front". `bg-[url(…)]` → 57. |
| § 10.5 background-origin | [39](./39-emilia-backgrounds/README.md) | covered | Three leaves. |
| § 10.6 background-position | [39](./39-emilia-backgrounds/README.md) | covered | Nine leaves under `Bg.Pos`. |
| § 10.7 background-repeat | [39](./39-emilia-backgrounds/README.md) | covered | Six leaves; `Repeat.None` for `no-repeat`. |
| § 10.8 background-size | [39](./39-emilia-backgrounds/README.md) | covered | `Auto/Cover/Contain`; `bg-size-[…]` → 57. |
| § 11.1 border-radius | [40](./40-emilia-borders/README.md) | covered | Ten leaves × fourteen directions; eight logical corners are "not in the local reference" and specified from upstream. |
| § 11.2 border-width | [40](./40-emilia-borders/README.md) | covered | `W.0/1/2/4/8` + eight directional sub-sections. |
| § 11.3 border-color | [40](./40-emilia-borders/README.md) | covered | `Border.Color.<Family>.<Shade>` + named. |
| § 11.4 border-style | [40](./40-emilia-borders/README.md) | covered | Six leaves. |
| § 11.5 outline-width | [40](./40-emilia-borders/README.md) | covered | `0/1/2/4/8`. |
| § 11.6 outline-color | [40](./40-emilia-borders/README.md) | covered | `Outline.Color.*`. |
| § 11.7 outline-style | [40](./40-emilia-borders/README.md) | covered | `outline-none` emits the two-declaration transparent form; `outline-hidden` "not declared by this front". |
| § 11.8 outline-offset | [40](./40-emilia-borders/README.md) | covered | `0/1/2/4/8` + `Neg`. |
| § 11 `ring-*` (not in the reference) | [40](./40-emilia-borders/README.md) | covered | Beyond the reference: `Ring.W/Color/Offset/Inset` via `--tw-ring-*`; "must be verified before implementation". |
| § 11 `divide-*` (not in the reference) | [40](./40-emilia-borders/README.md) | covered | Beyond the reference: `Divide.X/Y/Color/Style/XReverse/YReverse` as a `Sheet`; selector must equal 35's `Space`. |
| § 12.1 box-shadow | [41](./41-emilia-effects/README.md) | partial | Nine leaves + three `InsetShadow` + `EffectShadowRaw` covered. `shadow-red-500/50` deferred: "A reference gap, not a mechanism gap, and it reopens the moment a row exists." |
| § 12.2 text-shadow | [41](./41-emilia-effects/README.md) | covered | Six leaves + `EffectTextShadowRaw`. |
| § 12.3 opacity | [41](./41-emilia-effects/README.md) | covered | Fifteen steps; `opacity:0.6`, not `.6`. |
| § 12.4 mix-blend-mode | [41](./41-emilia-effects/README.md) | covered | Seventeen leaves. |
| § 12.5 background-blend-mode | [41](./41-emilia-effects/README.md) | covered | Seventeen leaves under `Blend.Bg`. |
| § 12.6 mask utilities | [41](./41-emilia-effects/README.md) | covered | Twenty leaves across nine sub-sections + `MaskImageRaw`. |
| § 13.1 filter: blur | [42](./42-emilia-filters/README.md) | covered | `Blur.None/Xs…X3xl` → `blur(var(--blur-*))`. |
| § 13.1 filter: brightness | [42](./42-emilia-filters/README.md) | covered | Eleven steps. |
| § 13.1 filter: contrast | [42](./42-emilia-filters/README.md) | covered | Seven steps. |
| § 13.1 filter: drop-shadow | [42](./42-emilia-filters/README.md) | covered | `None/Xs…X2xl` → `drop-shadow(var(--drop-shadow-*))`. |
| § 13.1 filter: grayscale | [42](./42-emilia-filters/README.md) | covered | `0/100`. |
| § 13.1 filter: hue-rotate | [42](./42-emilia-filters/README.md) | covered | Six steps. |
| § 13.1 filter: invert | [42](./42-emilia-filters/README.md) | covered | `0/100`. |
| § 13.1 filter: saturate | [42](./42-emilia-filters/README.md) | covered | Five steps. |
| § 13.1 filter: sepia | [42](./42-emilia-filters/README.md) | covered | `0/100`. |
| § 13.1 filter composition (`blur-sm grayscale brightness-110`) | [42](./42-emilia-filters/README.md) · [56](./56-emilia-cascade-and-output/README.md) | partial | Mechanism: each leaf writes `--tw-<family>` + `filter:var(--tw-filter)` in one `Rule.declarations`. The Step 1 table still prints single-declaration bodies (`filter:brightness(.5)`); the two halves of the README disagree and one must be corrected before tests are written. `--tw-filter` composition entry owed to 54. |
| § 13.2 backdrop-filter | [42](./42-emilia-filters/README.md) | covered | Nine families incl. `Opacity` (fifteen steps from § 12.3), no `DropShadow` (matches the reference); `BackdropRaw`. |
| § 14.1 border-collapse | [43](./43-emilia-tables/README.md) | covered | `Table.Collapse/Separate`. |
| § 14.2 border-spacing | [43](./43-emilia-tables/README.md) | covered | `Spacing/SpacingX/SpacingY` emit `calc(var(--spacing) * 2)` where § 14.2 prints the resolved `0.5rem`; front states the resolved literal "is wrong" under a retuned theme. `TableSpacingRaw`. |
| § 14.3 table-layout | [43](./43-emilia-tables/README.md) | covered | `Layout.Auto/Fixed`. |
| § 14.4 caption-side | [43](./43-emilia-tables/README.md) | covered | `Caption.Top/Bottom`. |
| § 15.1 transition-property | [44](./44-emilia-transitions/README.md) | covered | `None/Base/All/Colors/Opacity/Shadow/Transform` with the timing/duration pair; `TransitionProperty(value)`. |
| § 15.2 transition-behavior | [44](./44-emilia-transitions/README.md) | covered | `Normal/Discrete`. |
| § 15.3 transition-duration | [44](./44-emilia-transitions/README.md) | covered | Nine steps. |
| § 15.4 transition-timing-function | [44](./44-emilia-transitions/README.md) | covered | `Linear` keyword + three `var(--ease-*)`. |
| § 15.5 transition-delay | [44](./44-emilia-transitions/README.md) | covered | Nine steps. |
| § 15.6 animation | [44](./44-emilia-transitions/README.md) | partial | `Animate.None/Spin/Ping/Pulse/Bounce` + `AnimateRaw`, keyframes hoisted via 56. The four `@keyframes` bodies "are absent from the reference and are gated"; `@starting-style` deferred ("not in the reference"). |
| § 16.1 backface-visibility | [45](./45-emilia-transforms/README.md) | covered | `Backface.Visible/Hidden`. |
| § 16.2 perspective | [45](./45-emilia-transforms/README.md) | covered | `None` keyword + five `var(--perspective-*)`. |
| § 16.3 perspective-origin | [45](./45-emilia-transforms/README.md) | covered | Five leaves. |
| § 16.4 rotate | [45](./45-emilia-transforms/README.md) | covered | `Rotate.0/1/45/90/180` + `Neg`; `TransformRotateRaw`. `rotate-x/y/z` deferred ("not in the reference"). |
| § 16.5 scale | [45](./45-emilia-transforms/README.md) | covered | Ten steps + `ScaleX`/`ScaleY`; no `z` (matches the reference). |
| § 16.6 skew | [45](./45-emilia-transforms/README.md) | partial | Transcribed as `skew-x:`/`skew-y:` — the reference's column; front flags "no browser applies it … pending a check against the upstream page". |
| § 16.7 transform | [45](./45-emilia-transforms/README.md) | covered | `Shorthand.None/Cpu/Gpu` verbatim. |
| § 16.8 transform-origin | [45](./45-emilia-transforms/README.md) | covered | Nine leaves. |
| § 16.9 transform-style | [45](./45-emilia-transforms/README.md) | covered | `Flat/Preserve3d`. |
| § 16.10 translate | [45](./45-emilia-transforms/README.md) | partial | Emits `--tw-translate-x:…;translate:var(--tw-translate-x) var(--tw-translate-y)` where § 16.10 prints `translate: 0 var(--tw-translate-y)` — not byte-equal to the row. `-translate-y-2` (shown in the HTML) has no token: "every negative utility has no direct token" beyond `Rotate.Neg`. `TransformTranslateRaw`. |
| § 16.11 zoom | [45](./45-emilia-transforms/README.md) | covered | Seven steps. |
| § 17.1 accent-color | [46](./46-emilia-interactivity/README.md) | covered | `Token.InteractAccent(value)` with `paletteVar(family, shade)`; top-level payload per contract 4a. |
| § 17.2 appearance | [46](./46-emilia-interactivity/README.md) | covered | `None/Auto`. |
| § 17.3 caret-color | [46](./46-emilia-interactivity/README.md) | covered | `Token.InteractCaret(value)`. |
| § 17.4 color-scheme | [46](./46-emilia-interactivity/README.md) | covered | Six leaves. |
| § 17.5 cursor | [46](./46-emilia-interactivity/README.md) | covered | Thirty-six leaves (`Standard` for `default`). |
| § 17.6 field-sizing | [46](./46-emilia-interactivity/README.md) | covered | `Fixed/Content`. |
| § 17.7 pointer-events | [46](./46-emilia-interactivity/README.md) | covered | `None/Auto`. |
| § 17.8 resize | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 17.9 scroll-behavior | [46](./46-emilia-interactivity/README.md) | covered | `Scroll.Behavior.Auto/Smooth`. |
| § 17.10 scrollbar-color | [46](./46-emilia-interactivity/README.md) | covered | `Token.InteractScrollbarColor(thumb, track)`. |
| § 17.11 scrollbar-width | [46](./46-emilia-interactivity/README.md) | covered | `Auto/Thin/None`. |
| § 17.12 scrollbar-gutter | [46](./46-emilia-interactivity/README.md) | covered | Three leaves. |
| § 17.13 scroll-margin | [46](./46-emilia-interactivity/README.md) | covered | `M/Mx/My/Mt/Mr/Mb/Ml` — the seven the reference prints. |
| § 17.14 scroll-padding | [46](./46-emilia-interactivity/README.md) | covered | `P/Px/Py/Pt/Pr/Pb/Pl`. |
| § 17.15 scroll-snap-align | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 17.16 scroll-snap-stop | [46](./46-emilia-interactivity/README.md) | covered | `Normal/Always`. |
| § 17.17 scroll-snap-type | [46](./46-emilia-interactivity/README.md) | covered | `Type.None/X/Y/Both` + `Strictness.Mandatory/Proximity` through `--tw-scroll-snap-strictness`. |
| § 17.18 touch-action | [46](./46-emilia-interactivity/README.md) | covered | Ten leaves. |
| § 17.19 user-select | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 17.20 will-change | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 18.1 fill | [47](./47-emilia-svg-accessibility/README.md) | covered | `Svg.Fill.Current/None` + `Token.SvgFill(value)`; `currentcolor` "derived rather than transcribed". |
| § 18.2 stroke | [47](./47-emilia-svg-accessibility/README.md) | covered | `Svg.Stroke.Current/None` + `Token.SvgStroke(value)`. |
| § 18.3 stroke-width | [47](./47-emilia-svg-accessibility/README.md) | covered | `0/1/2` + `SvgStrokeWidthRaw`. |
| § 19.1 forced-color-adjust | [47](./47-emilia-svg-accessibility/README.md) | covered | `A11y.ForcedColorAdjust.Auto/None`. |
| § 19.2 screen readers `sr-only` / `not-sr-only` | [47](./47-emilia-svg-accessibility/README.md) | partial | Tokens declared, bodies gated: "not in the reference — confirm against https://tailwindcss.com/docs/screen-readers before landing". |
| § 20.1 `@import "tailwindcss"` (and layered partial imports) | [56](./56-emilia-cascade-and-output/README.md) | covered | `renderDocument` emits `@layer theme, base, components, utilities;` then the four layers; `withLayers(o, false)` drops the `@layer` tokens; `withBase` supplies the base layer. |
| § 20.2 `@theme` | [54](./54-emilia-theme/README.md) | covered | See § 3.5 rows; `inline` is missing, `static` is the default. |
| § 20.3 `@custom-variant` (incl. `@slot`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `fn hocus(inner: Token[]) -> Token[]`; "`@slot` … is the parameter". |
| § 20.4 `@utility` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `pub fn scrollbarHidden() -> Token[]`, declaration for declaration with the reference example. |
| § 20.5 `@apply` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `btn().append(extra)`, `compose([...])`. |
| § 20.6 `@source` | — | n/a | No scanner; nothing to point it at. |
| § 20.7 `@variant` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | Same shape as `@custom-variant`: a function over the inner list. |
| § 20.8 `--spacing()` | [54](./54-emilia-theme/README.md) | covered | `spacing(n)` / `spacingHalf(n)`; identical strings on both targets. |
| § 20.9 `theme()` | [54](./54-emilia-theme/README.md) | covered | `themeValue(th, name)` returns the value, `themeVar(name)` the `var(…)` reference. |
| § 21.1 default colour palette | [33](./33-emilia-color-palette/README.md) | partial | Same gap as § 3.6: 284 OKLCH values transcribed from upstream, not from the reference. |
| § 21.2 spacing scale | [54](./54-emilia-theme/README.md) · [35](./35-emilia-spacing-sizing/README.md) | covered | `--spacing:0.25rem`; every spacing utility is a `calc(var(--spacing) * n)`. |
| § 21.3 default typography | [54](./54-emilia-theme/README.md) · [38](./38-emilia-typography/README.md) | covered | Thirteen `--text-*` + `--text-*--line-height` pairs from the table. |
| § 21.4 default shadows | [54](./54-emilia-theme/README.md) | covered | Seven `--shadow-*` byte-equal. |
| § 21.5 default border radius | [54](./54-emilia-theme/README.md) · [40](./40-emilia-borders/README.md) | covered | Eight `--radius-*`; 40 follows § 21.5's longer list over § 11.1's. |
| § 21.6 default animations | [54](./54-emilia-theme/README.md) · [44](./44-emilia-transitions/README.md) | covered | Four `--animate-*` shorthands byte-equal; keyframes bodies are the § 15.6 gap. |
| § 21.7 sharing themes between projects | [54](./54-emilia-theme/README.md) | covered | "a theme is a function in a module, so sharing it is an ordinary package dependency". |
| Referência Rápida de Utilitários | — | n/a | Index of the sections above; no new utilities except `ring`/`divide`/`space`/`sr-only`, handled in their rows. |

## Missing and partial rows, consolidated

Category: (a) 1.0.10 follow-up for an existing front · (b) intentionally out of scope, in the front's own words · (c) unplaced — no front claims it.

| Row | Status | Owner | Category | Detail |
|---|---|---|---|---|
| § 3.1 important modifier per utility (`bg-red-500!`) | partial | [34](./34-emilia-modifiers/README.md) | (c) | 56 attributes `Important(inner)` to 34; 34's surface and *Definition of done* do not mention it. Either 34 adds the variant on top of `markImportant` or 56 owns it. |
| § 3.2 `:has()` named forms | partial | [34](./34-emilia-modifiers/README.md) / [57](./57-emilia-escape-hatches/README.md) | (a) | 34: "omit; use a named variant … `Token.Variant(selector: string, inner: Token[])` on the escape-hatch front". 57 ships `ArbVariant` but no `has`/`not`/`aria`/`data`/`in` recipes or named tokens. |
| § 3.2 `:not()` named forms | partial | same | (a) | Same. |
| § 3.2 ARIA variants | partial | same | (a) | Same. |
| § 3.2 data-attribute variants | partial | same | (a) | Same. |
| § 3.2 `in-[…]` | partial | same | (a) | Same. |
| § 3.2 `group-*` beyond five states; named groups | partial | [34](./34-emilia-modifiers/README.md) | (a) states · (b) named | "Named groups and peers (`group/item`, `peer//name`) … out of scope for this front". |
| § 3.2 `peer-*` beyond six states; named peers | partial | [34](./34-emilia-modifiers/README.md) | (a) states · (b) named | Same quote. |
| § 3.2 full variant table — five bracket rows | partial | [34](./34-emilia-modifiers/README.md) / [57](./57-emilia-escape-hatches/README.md) | (a) | Aggregate of the five rows above. |
| § 3.3 custom breakpoints | partial | [34](./34-emilia-modifiers/README.md) · [54](./54-emilia-theme/README.md) | (a) | 34's variant fns take no `Theme`; the `--breakpoint-*` namespace 54 validates feeds nothing. Follow-up: `smVariant(th)` reading `themeValue(th, "--breakpoint-sm")`, the pattern 58 already uses for `--container-*`. |
| § 3.3 removing breakpoints | partial | same | (a) | Same fix; an emptied namespace should make the variant panic as 58's sizes do. |
| § 3.4 class-based dark mode | partial | [34](./34-emilia-modifiers/README.md) | (a) | 54 provides `DarkMode.Class` + `darkSelector`/`darkAtRule` and expects 34 to consume them; 34 declares the class/attribute forms out of scope. One README must change; 54's mechanism is the smaller delta. |
| § 3.4 data-attribute dark mode | partial | same | (a) | Same. |
| § 3.5 `--breakpoint-*` namespace | partial | same as § 3.3 | (a) | Same. |
| § 3.5 `@theme inline` | missing | — | (c) | No front names it; 54's model always emits `var(--x)`. Either declare it out of scope in 54 or add a `themeInline` render mode. |
| § 3.6 / § 21.1 OKLCH palette values | partial | [33](./33-emilia-color-palette/README.md) | (a) | "transcribe from upstream `packages/tailwindcss/theme.css`, record the commit in `test/colors_test.bp`'s header". |
| § 3.7 named class in `@layer utilities` | partial | [59](./59-emilia-custom-utilities-and-variants/README.md) | (b) | "`named()` takes no `layer:` argument because a per-call-site layer choice makes the …"; `components` only. |
| § 10.4 gradient stops CSS | partial | [39](./39-emilia-backgrounds/README.md) | (a) | "verify `--tw-gradient-from`, `--tw-gradient-via`, `--tw-gradient-to` and the `--tw-gradient-stops` composition against upstream". |
| § 10.4 stop positions, radial/conic, interpolation | partial | [39](./39-emilia-backgrounds/README.md) | (b) | "not declared by this front … specifying it from memory would be guessing". |
| § 12.1 `shadow-<color>/<opacity>` | partial | [41](./41-emilia-effects/README.md) | (b) | "A reference gap, not a mechanism gap, and it reopens the moment a row exists." |
| § 13.1 filter composition — README inconsistency | partial | [42](./42-emilia-filters/README.md) | (a) | Mechanism says two declarations per leaf; Step 1/2 tables print one. Align the tables, and land the `--tw-filter` / `--tw-backdrop-filter` entries in 54 ("What front 42 still owes front 54"). |
| § 15.6 keyframes bodies | partial | [44](./44-emilia-transitions/README.md) | (a) | Gated on the upstream page, "the way front 47 gates `sr-only`". |
| § 15.6 `@starting-style` | partial | [44](./44-emilia-transitions/README.md) | (b) | "A token for it would be written from memory, which this milestone does not do." |
| § 16.6 skew property names | partial | [45](./45-emilia-transforms/README.md) | (a) | "Flagged, transcribed, and pending a check against the upstream page." |
| § 16.10 translate row shape | partial | [45](./45-emilia-transforms/README.md) | (a) | Front emits the `--tw-translate-x` writer + shorthand reader; the reference row is `translate: 0 var(--tw-translate-y)`. Pick one and state the divergence if the writer form stays. |
| § 16.10 negative translate (`-translate-y-2`) | partial | [45](./45-emilia-transforms/README.md) | (a) | Language-gap row names it; a `Neg` sub-section under `TranslateX`/`TranslateY`, as `Rotate.Neg` does. |
| § 16.4 `rotate-x/y/z`, `translate-z`, `scale-z` | — | [45](./45-emilia-transforms/README.md) | (b) | "Not in the reference … Tokens for them would be written from memory." Listed for completeness; not a reference row. |
| § 19.2 `sr-only` / `not-sr-only` bodies | partial | [47](./47-emilia-svg-accessibility/README.md) | (a) | "read from the upstream page, dated in the dispatcher comment, ticked in `TODO.md`, and asserted as a literal in the test file". |
| § 11.7 `outline-hidden` | — | [40](./40-emilia-borders/README.md) | (b) | "absent … not declared by this front". Not a reference row. |
| § 5.2 `columns-4…12`, § 6.7/6.8 interpolated integers, § 8.1 fractions beyond three | — | [36](./36-emilia-layout/README.md) / [37](./37-emilia-grid/README.md) / [35](./35-emilia-spacing-sizing/README.md) | (a) | Rows are `covered` against what the reference prints; each front asks that the extent be "confirmed against upstream before merge". |

## Deviations from Tailwind stated by the fronts

- **Preflight is opt-in, not opt-out.** `defaultOptions()` has `base: []`; the reset arrives only through `withBase(defaultOptions(), preflightRules())`. "That inverts Tailwind's default, and the inversion is deliberate" — [55](./55-emilia-preflight/README.md). Parity is with § 4's eight bullets, not with upstream `preflight.css`; `border-style:solid` is added beside `border-width:0` so `Border.W.*` is not inert.
- **`@theme static` is always on; no tree-shaking.** "emilia's behaviour is `@theme static`, always, and the tree-shaken form is out of scope for this milestone" — [54](./54-emilia-theme/README.md). Every theme variable is emitted into `:root` in the `theme` layer regardless of use.
- **The theme is a flat entry list, not one field per namespace.** "one deliberate deviation from the audit's brief … The flat set is what CSS actually has" — [54](./54-emilia-theme/README.md). Extending the theme adds a variable; it never adds a token. New utilities are reached through [57](./57-emilia-escape-hatches/README.md) `Arb` + `themeVar`.
- **Class names are content hashes.** `e_<hex>` = djb2 of `encodeSheet(tokensToSheet(tokens, theme))`; "a pure function of the token list *and the theme*"; order is identity; ASCII only — [48](./48-emilia-attributes/README.md), [56](./56-emilia-cascade-and-output/README.md). There are no literal utility names to scan (§ 3.8 n/a) and no scanner (§ 20.6 n/a).
- **Class prefix is plain concatenation.** `withPrefix(o, "tw_")` → `.tw_e_1`; "Tailwind's escaped `.tw\:text-red-500` form has no analogue here" — [56](./56-emilia-cascade-and-output/README.md).
- **`!important` is per declaration, via `markImportant` or `Options.important`;** the per-utility `!` suffix has no declared token (see consolidated table) — [56](./56-emilia-cascade-and-output/README.md).
- **Declarations are written `prop:value` with no space after the colon.** "The **value** is byte-equal to the reference; the separator is emilia's" — [41](./41-emilia-effects/README.md), [42](./42-emilia-filters/README.md).
- **`hover` and the five other pre-existing modifiers change their emitted CSS** to the v4.3 form (`@media (hover: hover){&:hover{…}}`, `@media (width >= 48rem)`); "the one non-additive change in the front, and it is deliberate" — [34](./34-emilia-modifiers/README.md). Same for `Text.Size.*`, `Font.*`, `Text.Underline` in [38](./38-emilia-typography/README.md) and `Border.Rounded.Sm/Md/Lg` in [40](./40-emilia-borders/README.md).
- **Breakpoint ranges are nesting, not a variant:** `md:max-xl:` is `Md([MaxXl(inner)])` — [34](./34-emilia-modifiers/README.md). Breakpoint queries are literals, not theme lookups (see consolidated table).
- **Named containers emit both halves.** `ContainerNamed(name)` writes `container-type:inline-size;container-name:<name>` in one rule; sizes come from `--container-*` and an emptied namespace panics rather than emitting `@container (width >= )` — [58](./58-emilia-container-queries/README.md).
- **Arbitrary values are validated, and a rejected payload fails the build or panics;** "There is no option to allow it" for a selector with the wrong number of `&`; media range syntax is unreachable through `cssQuery` by design, `ArbMin`/`ArbMax` carry it — [57](./57-emilia-escape-hatches/README.md), [56](./56-emilia-cascade-and-output/README.md).
- **Payload-carrying tokens are top-level `Token` variants, never section leaves** (`EffectShadowRaw`, `FilterRaw`, `InteractAccent`, `SvgFill`, `ContainerAt`, `Arb`…), because a nested payload leaf cannot be constructed (`language-gaps.md` row 52) — every front from 41 onward.
- **Token names diverge from class names where the class prefix is overloaded:** `.Gradient.To.*` is direction, `.Gradient.Stop.*` is the terminal stop ([39](./39-emilia-backgrounds/README.md)); `.Text.Decoration.Thickness.2` vs `.Text.Decoration.Color.Red.500` ([38](./38-emilia-typography/README.md)); `.Bg.Pos` vs `.Layout.Position` ([39](./39-emilia-backgrounds/README.md)); `.Flex.Value.One` for `flex-1` ([37](./37-emilia-grid/README.md)); `.Interact.Cursor.Standard` for `cursor-default` ([46](./46-emilia-interactivity/README.md)); `Preserve3d` for `transform-3d` ([45](./45-emilia-transforms/README.md)).
- **Negative utilities are a `Neg` sub-section** (`.Margin.T.Neg.4`, `.Transform.Rotate.Neg.12`, `.Outline.Offset.Neg.1`) because a numeric leaf has no signed spelling — [35](./35-emilia-spacing-sizing/README.md), [45](./45-emilia-transforms/README.md), [40](./40-emilia-borders/README.md).
- **`border-spacing` emits `calc(var(--spacing) * n)`** where § 14.2 prints the resolved `0.5rem`; "that is wrong" under a retuned theme — [43](./43-emilia-tables/README.md).
- **`@apply` is array concatenation and `@utility` is a function;** `named()` writes only to `@layer components`, never to `utilities`, and refuses `e_`-prefixed or colliding names — [59](./59-emilia-custom-utilities-and-variants/README.md).
- **`.group` / `.peer` marker classes are the consumer's responsibility;** emilia does not emit them — [34](./34-emilia-modifiers/README.md).
- **`transform`/`transform-cpu` are one token** (`Shorthand.Cpu`) because § 16.7 gives them the same value — [45](./45-emilia-transforms/README.md).
- **Keyframes are hoisted outside every layer and deduplicated by header;** placement "is written down here so it is not re-litigated" — [56](./56-emilia-cascade-and-output/README.md).

## Ordering

Three fronts are foundation: the palette (33) is transversal — borders, backgrounds, text, shadows,
drop-shadows all name a colour; the modifiers (34) wrap tokens of every section, so without
`Sm`/`2Xl`/`Dark`/`GroupHover` nothing added later is usable responsively or in a state; and
`Width`/`Height`/`Gap`/`Pad`/`Margin` (35) are in every layout, so the full scale precedes layout and
grid.

Two fronts come *in front of them*: 54 theme, because four copies of the spacing ladder already exist
in `emilia.bp` and have drifted (`marginScaleX` emits `m-0.25`, which is not CSS), so every front
admitted before a theme would add a fifth; and 56 cascade-and-output, because the nested class body
emilia emits cannot carry `@media` beside `@layer`, cannot hold `@keyframes`, and cannot express
`group-*`, `peer-*`, `rtl`, `space-*` or `divide-*` — fronts 34, 40, 44, 55 and 58 all emit through it,
and building them first means building them twice. 54 lands before 56 inside that pair:
`Options.theme` is a `Theme` and `defaultOptions()` calls `defaultTheme()`. The resulting levels are
the table in [`README.md`](./README.md).

All fronts touch `tokens.bp` and `emilia.bp`; each adds only its own section and dispatcher, and the
shared-file rule below is what makes that mergeable.

## The shared files — sixteen fronts, one enum

The rule for the shared files:

> **How eighteen fronts share `tokens.bp` and `emilia.bp`.** They do not merge into the same lines.
> The rule is one variant block per front in `tokens.bp` and one sub-dispatcher per front in
> `emilia.bp`, each fenced by a comment banner naming its front, and each appended at the end of its
> file rather than interleaved. The only genuinely shared lines are the arms each front adds to the
> top-level `tokenToCss` `case` — **one contiguous block per front**, added in front-number order. A
> front adds one arm per top-level section it owns *and one arm per top-level payload variant it
> owns* — payload-carrying tokens must be top-level variants (contract 4a), so fronts 33, 34, 40, 46,
> 47, 57 and 58 add several arms each (57 adds six, 58 adds four). The arms sit together under the
> front's banner, which is the property the convention exists for; front-number ordering still makes
> the merged result deterministic. A front that has to edit another front's block has found a design
> error, not a merge conflict, and files it as such.

> **Three track-D files are append-only, and here is who appends.** `root.bp` (the `pub mod` lines)
> and `botopink.json` (the `files` list) are touched by every front that adds a module — 54, 55, 56,
> 57, 58, 59 and 48 — and a banner cannot fence a `pub mod` line or a JSON array element. The rule
> is the same as for std's `root.bp`: **append in front-number order, never reorder, never edit
> another front's line.** A merge conflict on either file is resolved by re-sorting, not by choosing
> a side.

The three exceptions for track D: **33 · 39** share the `Bg { … }` section (33 owns
`Bg.Color`, 39 everything else under `Bg`; 33 lands first and 39 appends after its block);
**35 · 40** share the sibling selector for `space-*` and `divide-*` (neither is documented upstream;
both READMEs require a cross-front test asserting the two selectors are byte-identical); **56** owns
the `flush`/`register` half of `emilia.bp` under its own banner while 33–48 append sub-dispatchers.

What 1.0.10 changes is where the sub-dispatchers live — one file per front under
`modules/emilia/src/utilities/`, so `emilia.bp` shrinks to the cells, the entry points and the
`tokenToSheet` arms — and adds one shared line per contributing front to `fullTheme()`. The enum
body itself stays one file by language constraint. [`modules.md`](./modules.md) has the full
resolution.
