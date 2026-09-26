# Reference coverage — Tailwind CSS v4 against the emilia fronts

Reference: `/home/ericfillipe/develop/tailwindcss/TAILWIND_CSS_DOCS.md` (Tailwind v4.3, § 3–§ 21 plus the *Referência Rápida*), walked against the 22 emilia fronts 33–48 and 54–59 as they ship.
Status: `covered` — the front's token surface delivers the row byte-equal to the reference (or to what the reference prints); `partial` — a named subset, or a row only an escape hatch reaches; `missing` — no front declares it; `n/a` — a build-time or scanner concern emilia has no counterpart for (emilia hashes per call site and has no scanner).

## Summary

| Tailwind section | Fronts | Rows | covered | partial | missing | n/a |
|---|---|---|---|---|---|---|
| § 1 Introdução | — | 1 | 0 | 0 | 0 | 1 |
| § 2 Instalação | — | 1 | 0 | 0 | 0 | 1 |
| § 3 Conceitos fundamentais (3.1–3.9) | [33](./33-emilia-color-palette/README.md) [34](./34-emilia-modifiers/README.md) [35](./35-emilia-spacing-sizing/README.md) [36](./36-emilia-layout/README.md) [38](./38-emilia-typography/README.md) [40](./40-emilia-borders/README.md) [41](./41-emilia-effects/README.md) [42](./42-emilia-filters/README.md) [44](./44-emilia-transitions/README.md) [45](./45-emilia-transforms/README.md) [48](./48-emilia-attributes/README.md) [54](./54-emilia-theme/README.md) [56](./56-emilia-cascade-and-output/README.md) [57](./57-emilia-escape-hatches/README.md) [58](./58-emilia-container-queries/README.md) [59](./59-emilia-custom-utilities-and-variants/README.md) | 80 | 64 | 12 | 1 | 3 |
| § 4 Preflight | [55](./55-emilia-preflight/README.md) | 2 | 2 | 0 | 0 | 0 |
| § 5 Layout | [36](./36-emilia-layout/README.md) | 19 | 19 | 0 | 0 | 0 |
| § 6 Flexbox & Grid | [37](./37-emilia-grid/README.md) | 24 | 24 | 0 | 0 | 0 |
| § 7 Espaçamento (+ `space-*`) | [35](./35-emilia-spacing-sizing/README.md) | 3 | 3 | 0 | 0 | 0 |
| § 8 Dimensionamento | [35](./35-emilia-spacing-sizing/README.md) | 7 | 7 | 0 | 0 | 0 |
| § 9 Tipografia | [38](./38-emilia-typography/README.md) [33](./33-emilia-color-palette/README.md) [57](./57-emilia-escape-hatches/README.md) | 32 | 32 | 0 | 0 | 0 |
| § 10 Backgrounds | [39](./39-emilia-backgrounds/README.md) [33](./33-emilia-color-palette/README.md) [57](./57-emilia-escape-hatches/README.md) | 8 | 7 | 1 | 0 | 0 |
| § 11 Bordas (+ `ring-*`, `divide-*`) | [40](./40-emilia-borders/README.md) | 10 | 10 | 0 | 0 | 0 |
| § 12 Efeitos | [41](./41-emilia-effects/README.md) | 6 | 5 | 1 | 0 | 0 |
| § 13 Filtros | [42](./42-emilia-filters/README.md) [56](./56-emilia-cascade-and-output/README.md) | 11 | 11 | 0 | 0 | 0 |
| § 14 Tabelas | [43](./43-emilia-tables/README.md) | 4 | 4 | 0 | 0 | 0 |
| § 15 Transições & Animação | [44](./44-emilia-transitions/README.md) | 6 | 6 | 0 | 0 | 0 |
| § 16 Transforms | [45](./45-emilia-transforms/README.md) | 11 | 10 | 1 | 0 | 0 |
| § 17 Interatividade | [46](./46-emilia-interactivity/README.md) | 20 | 20 | 0 | 0 | 0 |
| § 18 SVG | [47](./47-emilia-svg-accessibility/README.md) | 3 | 3 | 0 | 0 | 0 |
| § 19 Acessibilidade | [47](./47-emilia-svg-accessibility/README.md) | 2 | 2 | 0 | 0 | 0 |
| § 20 Funções e Diretivas | [54](./54-emilia-theme/README.md) [56](./56-emilia-cascade-and-output/README.md) [59](./59-emilia-custom-utilities-and-variants/README.md) | 9 | 8 | 0 | 0 | 1 |
| § 21 Temas e Customização | [54](./54-emilia-theme/README.md) [33](./33-emilia-color-palette/README.md) [35](./35-emilia-spacing-sizing/README.md) [38](./38-emilia-typography/README.md) [40](./40-emilia-borders/README.md) [44](./44-emilia-transitions/README.md) | 7 | 7 | 0 | 0 | 0 |
| Referência Rápida | — | 1 | 0 | 0 | 0 | 1 |
| **Total** | 22 fronts | **267** | **244** | **15** | **1** | **7** |

## Main table

| Tailwind § / utility group | Front | Status | Note |
|---|---|---|---|
| § 1 Introdução | — | n/a | Prose. |
| § 2 Instalação (2.1–2.5 Vite / PostCSS / CLI / Play CDN / framework guides) | — | n/a | emilia is a comptime library that hashes per call site; there is no build plugin, CLI or CDN to install. |
| § 3.1 styling with utility classes | [48](./48-emilia-attributes/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | `emilia(tokens)` returns `e_<hex>`; 48 hands it on as attribute data (`styled`, `styledWith`) and as the bare string a `[class]={…}` hole takes (`cls`, `clsWith`); emilia renders no HTML. 48 records that a `[class]={…}` hole may not contain a space (`html.bp` frozen). |
| § 3.1 arbitrary values `bg-[#316ff6]` | [57](./57-emilia-escape-hatches/README.md) | covered | `Token.Arb(prop, value)` via `arbValue`, gated by `cssValue`/`cssIdent`; composes with `spacing(6)` and `themeVar`. |
| § 3.1 arbitrary CSS properties `[--gutter-width:1rem]` | [57](./57-emilia-escape-hatches/README.md) | covered | `Token.ArbProp(name, value)` via `arbProp`. |
| § 3.1 managing duplication (`@layer components { .btn-primary }`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | Bundles are `pub fn … -> Token[]`; `named("card", tokens)` lands in `@layer components`. |
| § 3.1 style conflicts (last rule wins) | [56](./56-emilia-cascade-and-output/README.md) | covered | Within a class, token order; across calls, registration order; unconditioned rules before at-rule rules. |
| § 3.1 important modifier `bg-red-500!` (per utility) | [34](./34-emilia-modifiers/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | `Token.Important(inner)` — `markImportant` on the inner sheet (decision 81). |
| § 3.1 important flag (`@import "tailwindcss" important`) | [56](./56-emilia-cascade-and-output/README.md) | covered | `Options.important` / `withImportant`; `!important` appended per declaration. |
| § 3.1 prefix (`prefix(tw)`) | [56](./56-emilia-cascade-and-output/README.md) | covered | `withPrefix(o, "tw_")` renders `.tw_e_1`; plain concatenation, no escaped `.tw\:` form — stated divergence. |
| § 3.2 pseudo-classes hover / focus / focus-within / focus-visible / active / visited / target | [34](./34-emilia-modifiers/README.md) | covered | `Hover` is `@media (hover: hover)` + `&:hover`; the others are `&:<state>`. |
| § 3.2 structural first / last / only / odd / even / *-of-type / empty | [34](./34-emilia-modifiers/README.md) | covered | Nine `selector`-only variants. |
| § 3.2 `nth-*` / `nth-last-*` | [34](./34-emilia-modifiers/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `Nth(index: i32, inner)`, `NthLast(index, inner)`; a formula (`nth-[2n+1]`) goes through `arbSel`. |
| § 3.2 form states disabled / enabled / checked / indeterminate / default / optional / required / valid / invalid / user-valid / user-invalid / in-range / out-of-range / placeholder-shown / autofill / read-only | [34](./34-emilia-modifiers/README.md) | covered | Sixteen variants, selectors verbatim from the reference table. |
| § 3.2 `:has()` (`has-checked:`, `has-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | No named `Has*` token; expressible as `arbSel("&:has(:checked)", inner)`. |
| § 3.2 `:not()` (`hover:not-focus:`, `not-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | Same shape: `arbSel("&:not(:focus)", inner)` only. |
| § 3.2 parent state `group-*` | [34](./34-emilia-modifiers/README.md) | partial | `GroupHover/Focus/Active/Visited/Disabled/Open` from the `&:is(:where(.group) … *)` template; other states via `arbSel`. Named groups (`group/item`) are not declared. |
| § 3.2 sibling state `peer-*` | [34](./34-emilia-modifiers/README.md) | partial | `PeerHover/Focus/Active/Checked/Invalid/Required/Disabled/PlaceholderShown`; named peers not declared. |
| § 3.2 `in-[…]` (`:where(…) &`) | [57](./57-emilia-escape-hatches/README.md) | partial | No named form; the selector has one `&`, so `arbSel` carries it. |
| § 3.2 pseudo-elements before / after / first-letter / first-line / placeholder / file / marker / selection / backdrop | [34](./34-emilia-modifiers/README.md) | covered | Nine variants; `Marker`/`Selection` are upstream v4's lists — the element's own and its descendants' (`& *::marker, &::marker`, plus WebKit's details marker), one rule per one-`&` variant; the reference's `& ::marker` reached descendants only; `Before`/`After` pair with 38's `Text.Content.*`. |
| § 3.2 media: responsive `md:` | [34](./34-emilia-modifiers/README.md) | covered | See § 3.3 rows. |
| § 3.2 media: `dark:` | [34](./34-emilia-modifiers/README.md) | covered | `@media (prefers-color-scheme: dark)`; class/attribute strategies see § 3.4. |
| § 3.2 media: `motion-safe:` / `motion-reduce:` | [34](./34-emilia-modifiers/README.md) | covered | `MotionSafe`, `MotionReduce`. |
| § 3.2 media: `contrast-more:` / `contrast-less:` / `forced-colors:` | [34](./34-emilia-modifiers/README.md) | covered | `ContrastMore`, `ContrastLess`, `ForcedColors`. |
| § 3.2 media: `print:` | [34](./34-emilia-modifiers/README.md) | covered | `Print` → `@media print`. |
| § 3.2 media: `supports-[…]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbAt("supports(display:grid)", inner)` → `@supports(display:grid){…}`; `cssQuery` refuses a leading `@`. |
| § 3.2 media: `portrait:` / `landscape:` | [34](./34-emilia-modifiers/README.md) | covered | `Portrait`, `Landscape`. |
| § 3.2 ARIA (`aria-checked:`, `aria-[…]`) | [57](./57-emilia-escape-hatches/README.md) | partial | No named `Aria*` token; `arbSel("&[aria-checked=\"true\"]", inner)` only. |
| § 3.2 data attributes (`data-active:`, `data-[size=large]:`) | [57](./57-emilia-escape-hatches/README.md) | partial | Same: `arbSel("&[data-size=large]", inner)` only. |
| § 3.2 `rtl:` / `ltr:` | [34](./34-emilia-modifiers/README.md) | covered | Upstream v4.1's `&:where(:dir(rtl), [dir="rtl"], [dir="rtl"] *)`; the reference's pre-v4 `[dir="rtl"] &` is not emitted. |
| § 3.2 `open:` / `inert:` | [34](./34-emilia-modifiers/README.md) | covered | `Open` → upstream v4's `&:is([open], :popover-open, :open)` (one `&`; the reference's `&:open, &:popover-open` has two and omits the legacy `[open]`); `GroupOpen` carries the same three; `Inert` → `&:is([inert], [inert] *)`. |
| § 3.2 child selectors `*:` / `**:` | [34](./34-emilia-modifiers/README.md) | covered | `Children` → `:is(& > *)`, `Descendants` → `:is(& *)`; `**:data-avatar:` is `Descendants([arbSel(…)])`. |
| § 3.2 arbitrary variants `[&.is-dragging]:` / `[@supports(…)]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `arbSel(selector, inner)` (`ArbVariant`; exactly one `&`), `arbAt(query, inner)`. |
| § 3.2 registering custom variants (`@custom-variant theme-midnight`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | A custom variant is `fn (inner: Token[]) -> Token[]`; `selector(Variant(atRule: "", selector: "&:where([data-theme=\"midnight\"] *)"), inner)`. |
| § 3.2 full variant reference table (72 rows) | [34](./34-emilia-modifiers/README.md) · [57](./57-emilia-escape-hatches/README.md) | partial | Every non-bracket row has a token in 34 (82 `Variant` fns + `Important`). The bracket-template rows `has-[…]`, `group-[…]`, `peer-[…]`, `in-[…]`, `not-[…]` route through `arbSel`. |
| § 3.3 default breakpoints sm / md / lg / xl / 2xl | [34](./34-emilia-modifiers/README.md) · [54](./54-emilia-theme/README.md) | covered | `Sm … X2xl` → `@media (width >= 40rem)` … `96rem`, read from `--breakpoint-*`. |
| § 3.3 mobile-first | [34](./34-emilia-modifiers/README.md) | covered | `width >=` queries; 56 orders unconditioned rules before at-rule rules. |
| § 3.3 breakpoint range `md:max-xl:` | [34](./34-emilia-modifiers/README.md) | covered | Nesting: `Md([MaxXl(inner)])`. |
| § 3.3 `max-*` breakpoints | [34](./34-emilia-modifiers/README.md) | covered | `MaxSm … MaxX2xl` → `@media (width < …)`. |
| § 3.3 custom breakpoints (`--breakpoint-xs: 30rem`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | Overriding an existing `--breakpoint-*` moves its query and the class hash (decision 82). A new name adds no variant — `arbMin`/`arbMax` cover an extra width. |
| § 3.3 removing breakpoints (`--breakpoint-2xl: initial`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | partial | `clearNamespace(th, Ns.Breakpoint)` empties the entries, but `Token.X2xl` then emits `@media (width >= )` rather than being refused, unlike 58's container sizes. |
| § 3.3 arbitrary breakpoints `min-[320px]:` / `max-[600px]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `ArbMin(px, inner)` / `ArbMax(px, inner)`, gated by `cssLength`. |
| § 3.3 container queries `@container` + `@3xs … @7xl` | [58](./58-emilia-container-queries/README.md) | covered | `.Container.Inline/Normal/Size`; `containerAtMd(inner)` → `@container (width >= 28rem){…}`; the thirteen sizes read `--container-*` from the theme and panic on an empty value. |
| § 3.3 named containers `@container/main`, `@sm/main:` | [58](./58-emilia-container-queries/README.md) | covered | `containerName(name)` emits `container-type` + `container-name`; `containerNamed(size, name, inner)` → `@container main (width >= 24rem){…}`. |
| § 3.4 dark mode via `prefers-color-scheme` | [34](./34-emilia-modifiers/README.md) | covered | `Dark(inner)`. |
| § 3.4 class-based dark (`@custom-variant dark (&:where(.dark, .dark *))`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | covered | `withDarkMode(th, DarkMode.Class("dark"))`; `Dark` reads `darkAtRule`/`darkSelector` → `&:where(.dark, .dark *)`. |
| § 3.4 data-attribute dark (`[data-theme=dark]`) | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | covered | `DarkMode.Attribute("data-theme", "dark")` → `&:where([data-theme=dark], [data-theme=dark] *)`. |
| § 3.4 JavaScript toggle | — | n/a | Runtime script, outside the stylesheet. |
| § 3.5 theme variables (`@theme { --color-mint-500 }`) | [54](./54-emilia-theme/README.md) | covered | `Theme(entries, keyframes, darkMode)`, `ThemeEntry`, `extendTheme`, `themeVar`, `themeValue`; utilities emit `var(--…)` references. A new entry adds a variable, never a token — new utilities come from `arbValue` + `themeVar`. |
| § 3.5 namespace `--color-*` | [33](./33-emilia-color-palette/README.md) · [54](./54-emilia-theme/README.md) | covered | `paletteEntries()` (286 entries) composed into `fullTheme()`; `--color-white`/`--color-black` in `defaultTheme()`. |
| § 3.5 namespace `--font-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `.Font.Sans` → `font-family:var(--font-sans)`; the three stacks come from `typographyEntries()`. |
| § 3.5 namespace `--text-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `.Text.Size.*` emits the `--text-*` / `--text-*--line-height` pair; 54 carries both entries. |
| § 3.5 namespace `--font-weight-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | Entries contributed by 38; the utility emits the literal `font-weight:700`, which is what § 9.5 prints. |
| § 3.5 namespace `--tracking-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `letter-spacing:var(--tracking-wide)`. |
| § 3.5 namespace `--leading-*` | [38](./38-emilia-typography/README.md) · [54](./54-emilia-theme/README.md) | covered | `line-height:var(--leading-tight)`; `leading-none` is the literal `1`, as § 9.11 prints. |
| § 3.5 namespace `--breakpoint-*` | [54](./54-emilia-theme/README.md) · [34](./34-emilia-modifiers/README.md) | covered | Read by every breakpoint variant; see § 3.3 for new and removed names. |
| § 3.5 namespace `--container-*` | [58](./58-emilia-container-queries/README.md) · [54](./54-emilia-theme/README.md) · [35](./35-emilia-spacing-sizing/README.md) | covered | Thirteen entries in `defaultTheme()`, read by 58's container queries and by 35's `.Size.MaxW.*` / 36's `.Layout.Columns.*` (`var(--container-md)`). |
| § 3.5 namespace `--spacing-*` | [54](./54-emilia-theme/README.md) · [35](./35-emilia-spacing-sizing/README.md) | covered | `--spacing:0.25rem` (single variable, per § 21.2); `spacing(n)` → `calc(var(--spacing) * n)`, `spacing(0)` → `0`. |
| § 3.5 namespace `--radius-*` | [40](./40-emilia-borders/README.md) · [54](./54-emilia-theme/README.md) | covered | `border-radius:var(--radius-lg)`; `rounded-full` stays the literal `9999px`. |
| § 3.5 namespace `--shadow-*` | [41](./41-emilia-effects/README.md) · [54](./54-emilia-theme/README.md) | covered | `--tw-shadow:var(--shadow-md)` plus the shared `box-shadow` reader; seven values byte-equal to § 21.4. |
| § 3.5 namespace `--inset-shadow-*` | [41](./41-emilia-effects/README.md) · [54](./54-emilia-theme/README.md) | covered | `--tw-inset-shadow:inset var(--inset-shadow-sm)` plus the reader; the values are `effectEntries()`. |
| § 3.5 namespace `--drop-shadow-*` | [42](./42-emilia-filters/README.md) · [54](./54-emilia-theme/README.md) | covered | `filter:drop-shadow(var(--drop-shadow-md))`. |
| § 3.5 namespace `--blur-*` | [42](./42-emilia-filters/README.md) · [54](./54-emilia-theme/README.md) | covered | `blur(var(--blur-sm))`, shared by `Filter` and `BackdropFilter`; the values are `filterEntries()`. |
| § 3.5 namespace `--perspective-*` | [45](./45-emilia-transforms/README.md) · [54](./54-emilia-theme/README.md) | covered | `perspective:var(--perspective-near)` (`300px` in the theme). |
| § 3.5 namespace `--aspect-*` | [54](./54-emilia-theme/README.md) · [36](./36-emilia-layout/README.md) | covered | Validated prefix in 54; `.Layout.Aspect.Video` emits the literal `aspect-ratio:16 / 9` that § 5.1 prints — no theme lookup. |
| § 3.5 namespace `--ease-*` | [44](./44-emilia-transitions/README.md) · [54](./54-emilia-theme/README.md) | covered | `transition-timing-function:var(--ease-in)`; `ease-linear` is the keyword; the values (`transitionEntries()`) are upstream v4's `theme.css` — the reference prints only the names. |
| § 3.5 namespace `--animate-*` | [44](./44-emilia-transitions/README.md) · [54](./54-emilia-theme/README.md) | covered | `animation:var(--animate-spin)`; four values byte-equal to § 21.6. |
| § 3.5 extending the theme | [54](./54-emilia-theme/README.md) | covered | `extendTheme(th, entries)`; an entry outside the nineteen prefixes panics, no relaxing argument. |
| § 3.5 overriding the theme | [54](./54-emilia-theme/README.md) | covered | `extendTheme` with an existing name replaces the value in place. |
| § 3.5 replacing a namespace (`--color-*: initial`) | [54](./54-emilia-theme/README.md) | covered | `clearNamespace(th, Ns.Color)`. |
| § 3.5 fully custom theme (`--*: initial`) | [54](./54-emilia-theme/README.md) | covered | `emptyTheme()`. |
| § 3.5 custom animations (`@keyframes` inside `@theme`) | [54](./54-emilia-theme/README.md) · [44](./44-emilia-transitions/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | `Theme.keyframes` entries; `Block(header, body)` hoisted by `renderDocument`, deduplicated by header; `Token.AnimateRaw` / `rawAnimate` names the animation. |
| § 3.5 `@theme inline` | — | missing | No front mentions it. emilia always emits `var(--x)` references; the inline (value-resolving) form has no equivalent. |
| § 3.5 `@theme static` | [54](./54-emilia-theme/README.md) | covered | emilia always emits the whole theme; tree-shaking would need a whole-program pass over every `emilia()` site. |
| § 3.6 default palette (26 families × 11 shades, black, white) | [33](./33-emilia-color-palette/README.md) | covered | `.Color.<Family>.<Shade>` and `.Bg.Color.…`; plus `Transparent`, `Current`, `Inherit`. |
| § 3.6 OKLCH values | [33](./33-emilia-color-palette/README.md) | covered | 286 values transcribed from upstream `tailwindcss` 4.3.2 `theme.css`; the reference's two anchors (`red-500`, `blue-500`) match in upstream's `%` spelling. |
| § 3.6 colour opacity `bg-red-500/50` | [33](./33-emilia-color-palette/README.md) | covered | `Token.Alpha(percent, inner)` → `color-mix(in oklab, var(--color-red-500) 50%, transparent)`; `in oklab` flagged for upstream check. |
| § 3.7 arbitrary values | [57](./57-emilia-escape-hatches/README.md) | covered | Same as § 3.1. |
| § 3.7 arbitrary variants `[&>[data-active]+span]:` | [57](./57-emilia-escape-hatches/README.md) | covered | `arbSel`. |
| § 3.7 custom CSS with `@layer components` / `@layer utilities` | [59](./59-emilia-custom-utilities-and-variants/README.md) | partial | `named()` always lands in `components` (no per-call layer, by design); unnamed bundles land in `utilities` under their hash. A named class in `utilities` (`.text-balance`) is not expressible. |
| § 3.8 detecting classes in source files | — | n/a | emilia hashes per call site and has no scanner; the class exists because the call ran. |
| § 3.9 functions and directives | — | n/a | Duplicate of § 20; see those rows. |
| § 4 preflight resets (eight bullets) | [55](./55-emilia-preflight/README.md) | covered | `preflightRules()` — eleven `layer: "base"` rules; parity with the eight bullets, not byte-equality with upstream `preflight.css`. Adds `border-style:solid` beside `border-width:0`, a stated decision. |
| § 4 disabling preflight (`@source not "tailwindcss/preflight"`) | [55](./55-emilia-preflight/README.md) | covered | Inverted: off by default, on via `withBase(defaultOptions(), preflightRules())`; no ambient switch exists. |
| § 5.1 aspect-ratio | [36](./36-emilia-layout/README.md) | covered | `Aspect.Auto/Square/Video`; `aspect-[4/3]` → `arbValue`. |
| § 5.2 columns | [36](./36-emilia-layout/README.md) | covered | `1, 2, 3, Auto` + thirteen named widths as `var(--container-*)`; `columns-4…12` not declared (upstream resolves them through the bare-integer rule). |
| § 5.3 break-after | [36](./36-emilia-layout/README.md) | covered | `BreakAfter.*`, seven leaves. |
| § 5.4 break-before | [36](./36-emilia-layout/README.md) | covered | `BreakBefore.*`, same leaf set. |
| § 5.5 break-inside | [36](./36-emilia-layout/README.md) | covered | `BreakInside.Auto/Avoid/AvoidPage/AvoidColumn`. |
| § 5.6 box-decoration-break | [36](./36-emilia-layout/README.md) | covered | `BoxDecoration.Clone/Slice`. |
| § 5.7 box-sizing | [36](./36-emilia-layout/README.md) | covered | `Box.Border/Content`. |
| § 5.8 display | [36](./36-emilia-layout/README.md) | covered | Eleven leaves, `Layout`'s own. |
| § 5.9 float | [36](./36-emilia-layout/README.md) | covered | `float-start` → `float:inline-start`. |
| § 5.10 clear | [36](./36-emilia-layout/README.md) | covered | Six leaves. |
| § 5.11 isolation | [36](./36-emilia-layout/README.md) | covered | `Isolate`, `Auto`. |
| § 5.12 object-fit | [36](./36-emilia-layout/README.md) | covered | Five leaves. |
| § 5.13 object-position | [36](./36-emilia-layout/README.md) | covered | Nine leaves, two-word values single-spaced. |
| § 5.14 overflow | [36](./36-emilia-layout/README.md) | covered | Shorthand + `X` + `Y`, five values each. |
| § 5.15 overscroll-behavior | [36](./36-emilia-layout/README.md) | covered | Shorthand + `X` + `Y`, three values each. |
| § 5.16 position | [36](./36-emilia-layout/README.md) | covered | Five leaves. |
| § 5.17 top / right / bottom / left / inset | [36](./36-emilia-layout/README.md) | covered | `Inset.All/X/Y/T/R/B/L/S/E` over the spacing scale + `Auto`, `Full`, `Frac`, `Neg`; `top-[17px]` → `arbValue`. |
| § 5.18 visibility | [36](./36-emilia-layout/README.md) | covered | `invisible` → `visibility:hidden`. |
| § 5.19 z-index | [36](./36-emilia-layout/README.md) | covered | `0 10 20 30 40 50 Auto`; `z-[999]` → `arbValue`. |
| § 6.1 flex-basis | [37](./37-emilia-grid/README.md) | covered | Scale + `Auto`, `Full`, three fractions (the three the reference prints). |
| § 6.2 flex-direction | [37](./37-emilia-grid/README.md) | covered | `Row/RowReverse/Col/ColReverse`. |
| § 6.3 flex-wrap | [37](./37-emilia-grid/README.md) | covered | `Wrap/WrapReverse/NoWrap`. |
| § 6.4 flex | [37](./37-emilia-grid/README.md) | covered | `Flex.Value.One/Auto/Initial/None` (`Value` because a section cannot carry a sub-section of its own name). |
| § 6.5 flex-grow | [37](./37-emilia-grid/README.md) | covered | `Grow.0/1`. |
| § 6.6 flex-shrink | [37](./37-emilia-grid/README.md) | covered | `Shrink.0/1`. |
| § 6.7 order | [37](./37-emilia-grid/README.md) | covered | `1–12`, `First/Last/None`; the reference prints `1`, `2` and the keywords. |
| § 6.8 grid-template-columns | [37](./37-emilia-grid/README.md) | covered | `Cols.1–12/None/Subgrid` via `gridRepeat(n)`; the reference prints 1–6 and 12. |
| § 6.9 grid-column | [37](./37-emilia-grid/README.md) | covered | `Col.Auto`, `Col.Span.*`/`Full`, `Col.Start.*`, `Col.End.*`. |
| § 6.10 grid-template-rows | [37](./37-emilia-grid/README.md) | covered | `Rows.*/None/Subgrid`. |
| § 6.11 grid-row | [37](./37-emilia-grid/README.md) | covered | `Row.Auto/Span/Start/End`. |
| § 6.12 grid-auto-flow | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.13 grid-auto-columns | [37](./37-emilia-grid/README.md) | covered | `Auto/Min/Max/Fr`. |
| § 6.14 grid-auto-rows | [37](./37-emilia-grid/README.md) | covered | `Auto/Min/Max/Fr`. |
| § 6.15 gap | [37](./37-emilia-grid/README.md) | covered | `Gap.All/X/Y` over the spacing scale + `Px`; `.Flex.Gap.{1,2,4,8}` emit the same declarations. |
| § 6.16 justify-content | [37](./37-emilia-grid/README.md) | covered | Eight leaves, `flex-start`/`flex-end` asymmetry copied. |
| § 6.17 justify-items | [37](./37-emilia-grid/README.md) | covered | Four leaves. |
| § 6.18 justify-self | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.19 align-content | [37](./37-emilia-grid/README.md) | covered | Eight leaves. |
| § 6.20 align-items | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 6.21 align-self | [37](./37-emilia-grid/README.md) | covered | Six leaves. |
| § 6.22 place-content | [37](./37-emilia-grid/README.md) | covered | Seven leaves. |
| § 6.23 place-items | [37](./37-emilia-grid/README.md) | covered | Four leaves. |
| § 6.24 place-self | [37](./37-emilia-grid/README.md) | covered | Five leaves. |
| § 7.1 padding | [35](./35-emilia-spacing-sizing/README.md) | covered | Nine directions incl. `S`/`E` over 35 leaves. |
| § 7.2 margin | [35](./35-emilia-spacing-sizing/README.md) | covered | Nine directions + `Auto` + `Neg`. |
| § 7 `space-x-*` / `space-y-*` (not in the reference) | [35](./35-emilia-spacing-sizing/README.md) | covered | Beyond the reference: `.Space.X/Y` as a rule on `:where(& > :not(:last-child))` with upstream's reverse-aware start/end margins (read from upstream `utilities.ts`); byte-identical selector to 40's `Divide`. |
| § 8.1 width | [35](./35-emilia-spacing-sizing/README.md) | covered | Scale, `Px`, eleven fractions, `Full/Screen/Svw/Lvw/Dvw/Min/Max/Fit/Auto`; fractions beyond the three printed follow upstream. |
| § 8.2 min-width | [35](./35-emilia-spacing-sizing/README.md) | covered | Five leaves. |
| § 8.3 max-width | [35](./35-emilia-spacing-sizing/README.md) | covered | `X3xs…X7xl` → `var(--container-*)`, `Screen.Sm…X2xl` → `var(--breakpoint-*)`, `None/Full/0`. |
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
| § 9.12 list-style-image | [38](./38-emilia-typography/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `List.ImageNone`; `list-image-[url(…)]` → `arbValue`. |
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
| § 9.25 text-indent | [38](./38-emilia-typography/README.md) | covered | `Indent.{0,1,2,4,8}` → `calc(var(--spacing) * N)`. |
| § 9.26 tab-size | [38](./38-emilia-typography/README.md) | covered | `0/2/4/8`. |
| § 9.27 vertical-align | [38](./38-emilia-typography/README.md) | covered | Eight leaves. |
| § 9.28 white-space | [38](./38-emilia-typography/README.md) | covered | Six leaves. |
| § 9.29 word-break | [38](./38-emilia-typography/README.md) | covered | `Text.Break.Normal/Words/All/Keep`. |
| § 9.30 overflow-wrap | [38](./38-emilia-typography/README.md) | covered | `OverflowWrap.Normal/BreakWord/Anywhere`. |
| § 9.31 hyphens | [38](./38-emilia-typography/README.md) | covered | Three leaves. |
| § 9.32 content | [38](./38-emilia-typography/README.md) · [57](./57-emilia-escape-hatches/README.md) | covered | `Content.None/Empty`; `content-['Hello']` → `arbValue`. |
| § 10.1 background-attachment | [39](./39-emilia-backgrounds/README.md) | covered | `Bg.Attachment.Fixed/Local/Scroll`. |
| § 10.2 background-clip | [39](./39-emilia-backgrounds/README.md) | covered | Four leaves incl. `Text`. |
| § 10.3 background-color | [33](./33-emilia-color-palette/README.md) | covered | `.Bg.Color.*` → `background-color:`; legacy `.Bg.Red` keeps `background:`. |
| § 10.4 background-image | [39](./39-emilia-backgrounds/README.md) · [57](./57-emilia-escape-hatches/README.md) | partial | `Bg.Image.None`, the eight `Gradient.To.*` and the `Gradient.From/Via/Stop` stops (property names checked against upstream; `transparent` fallbacks in place of `@property`) covered. Stop positions, radial/conic gradients and interpolation modifiers are not declared. `bg-[url(…)]` → `arbValue`. |
| § 10.5 background-origin | [39](./39-emilia-backgrounds/README.md) | covered | Three leaves. |
| § 10.6 background-position | [39](./39-emilia-backgrounds/README.md) | covered | Nine leaves under `Bg.Pos`. |
| § 10.7 background-repeat | [39](./39-emilia-backgrounds/README.md) | covered | Six leaves; `Repeat.None` for `no-repeat`. |
| § 10.8 background-size | [39](./39-emilia-backgrounds/README.md) | covered | `Auto/Cover/Contain`; `bg-size-[…]` → `arbValue`. |
| § 11.1 border-radius | [40](./40-emilia-borders/README.md) | covered | Ten leaves × fourteen directions; the six logical corners follow upstream. |
| § 11.2 border-width | [40](./40-emilia-borders/README.md) | covered | `W.0/1/2/4/8` + eight directional sub-sections. |
| § 11.3 border-color | [40](./40-emilia-borders/README.md) | covered | `Border.Color.<Family>.<Shade>` + named. |
| § 11.4 border-style | [40](./40-emilia-borders/README.md) | covered | Six leaves. |
| § 11.5 outline-width | [40](./40-emilia-borders/README.md) | covered | `0/1/2/4/8`. |
| § 11.6 outline-color | [40](./40-emilia-borders/README.md) | covered | `Outline.Color.*`. |
| § 11.7 outline-style | [40](./40-emilia-borders/README.md) | covered | `outline-none` emits the two-declaration transparent form; `outline-hidden` not declared. |
| § 11.8 outline-offset | [40](./40-emilia-borders/README.md) | covered | `0/1/2/4/8` + `Neg`. |
| § 11 `ring-*` (not in the reference) | [40](./40-emilia-borders/README.md) | covered | Beyond the reference: `Ring.W/Color/Offset/Inset` via `--tw-ring-*` and the five-channel `box-shadow` reader; property names and the v4 1px default checked against upstream, the composed list and `ring-offset-*` not confirmed there. |
| § 11 `divide-*` (not in the reference) | [40](./40-emilia-borders/README.md) | covered | Beyond the reference: `Divide.X/Y/Color/Style/XReverse/YReverse` as a rule on `:where(& > :not(:last-child))`, byte-identical to 35's `Space`. |
| § 12.1 box-shadow | [41](./41-emilia-effects/README.md) | partial | Nine leaves + three `InsetShadow` + `EffectShadowRaw` covered. `shadow-red-500/50`: the reference gives no property/value row. |
| § 12.2 text-shadow | [41](./41-emilia-effects/README.md) | covered | Six leaves + `EffectTextShadowRaw`. |
| § 12.3 opacity | [41](./41-emilia-effects/README.md) | covered | Fifteen steps + six the reference omits, all confirmed upstream; upstream v4's `opacity:60%`, where the reference prints `opacity:0.6`. |
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
| § 13.1 filter composition (`blur-sm grayscale brightness-110`) | [42](./42-emilia-filters/README.md) · [56](./56-emilia-cascade-and-output/README.md) | covered | Each leaf writes `--tw-<family>` plus one inlined chain reader (`var(--tw-blur, ) … var(--tw-drop-shadow, )`), so families compose in one rule. |
| § 13.2 backdrop-filter | [42](./42-emilia-filters/README.md) | covered | `BackdropFilter`: nine families incl. `Opacity` (fifteen steps from § 12.3), no `DropShadow` (matches the reference); `BackdropRaw`. |
| § 14.1 border-collapse | [43](./43-emilia-tables/README.md) | covered | `Table.Collapse/Separate`. |
| § 14.2 border-spacing | [43](./43-emilia-tables/README.md) | covered | `Spacing/SpacingX/SpacingY` emit `calc(var(--spacing) * 2)`, which resolves to the `0.5rem` § 14.2 prints under the default theme; `TableSpacingRaw`. |
| § 14.3 table-layout | [43](./43-emilia-tables/README.md) | covered | `Layout.Auto/Fixed`. |
| § 14.4 caption-side | [43](./43-emilia-tables/README.md) | covered | `Caption.Top/Bottom`. |
| § 15.1 transition-property | [44](./44-emilia-transitions/README.md) | covered | `None/Base/All/Colors/Opacity/Shadow/Transform` with the timing/duration pair; `TransitionProperty(value)`. |
| § 15.2 transition-behavior | [44](./44-emilia-transitions/README.md) | covered | `Normal/Discrete`. |
| § 15.3 transition-duration | [44](./44-emilia-transitions/README.md) | covered | Nine steps. |
| § 15.4 transition-timing-function | [44](./44-emilia-transitions/README.md) | covered | `Linear` keyword + three `var(--ease-*)`. |
| § 15.5 transition-delay | [44](./44-emilia-transitions/README.md) | covered | Nine steps. |
| § 15.6 animation | [44](./44-emilia-transitions/README.md) | covered | `Animate.None/Spin/Ping/Pulse/Bounce` + `AnimateRaw`; the four `@keyframes` bodies are read from the theme (upstream `theme.css`) and hoisted. `@starting-style` is not declared. |
| § 16.1 backface-visibility | [45](./45-emilia-transforms/README.md) | covered | `Backface.Visible/Hidden`. |
| § 16.2 perspective | [45](./45-emilia-transforms/README.md) | covered | `None` keyword + five `var(--perspective-*)`. |
| § 16.3 perspective-origin | [45](./45-emilia-transforms/README.md) | covered | Five leaves. |
| § 16.4 rotate | [45](./45-emilia-transforms/README.md) | covered | `Rotate.0/1/45/90/180` + `Neg`; `TransformRotateRaw`. `rotate-x/y/z` not declared. |
| § 16.5 scale | [45](./45-emilia-transforms/README.md) | covered | Ten steps + `ScaleX`/`ScaleY`; no `z` (matches the reference). |
| § 16.6 skew | [45](./45-emilia-transforms/README.md) | covered | upstream v4's `--tw-skew-x:skewX(3deg)` and five-variable `transform` chain, so the axes compose; the reference's `skew-x:` column is not CSS and is never emitted. |
| § 16.7 transform | [45](./45-emilia-transforms/README.md) | covered | `Shorthand.None`; `Cpu`/`Gpu` are upstream v4's chain rows (the reference's `translate3d(…) rotate(…) scaleX(…)` values are v3's), reading the variables the skew leaves write. |
| § 16.8 transform-origin | [45](./45-emilia-transforms/README.md) | covered | Nine leaves. |
| § 16.9 transform-style | [45](./45-emilia-transforms/README.md) | covered | `Flat/Preserve3d`. |
| § 16.10 translate | [45](./45-emilia-transforms/README.md) | partial | `TranslateX/Y` write their axis's `--tw-translate-*` and `translate:var(--tw-translate-x) var(--tw-translate-y)` (upstream v4), registered with `@property`, so the axes compose; `Translate.*` writes both variables, `rawTranslate` the whole value. Negative translate (`-translate-y-2`) has no token. |
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
| § 17.17 scroll-snap-type | [46](./46-emilia-interactivity/README.md) | covered | `Type.None/X/Y/Both` + `Strictness.Mandatory/Proximity` through `--tw-scroll-snap-strictness` (fallback `proximity`). |
| § 17.18 touch-action | [46](./46-emilia-interactivity/README.md) | covered | Ten leaves. |
| § 17.19 user-select | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 17.20 will-change | [46](./46-emilia-interactivity/README.md) | covered | Four leaves. |
| § 18.1 fill | [47](./47-emilia-svg-accessibility/README.md) | covered | `Svg.Fill.Current/None` + `Token.SvgFill(value)`; `currentcolor` "derived rather than transcribed". |
| § 18.2 stroke | [47](./47-emilia-svg-accessibility/README.md) | covered | `Svg.Stroke.Current/None` + `Token.SvgStroke(value)`. |
| § 18.3 stroke-width | [47](./47-emilia-svg-accessibility/README.md) | covered | `0/1/2` + `SvgStrokeWidthRaw`. |
| § 19.1 forced-color-adjust | [47](./47-emilia-svg-accessibility/README.md) | covered | `A11y.ForcedColorAdjust.Auto/None`. |
| § 19.2 screen readers `sr-only` / `not-sr-only` | [47](./47-emilia-svg-accessibility/README.md) | covered | Upstream's bodies (`utilities.ts`), asserted as literals; `not-sr-only` restores eight of nine properties, as upstream. |
| § 20.1 `@import "tailwindcss"` (and layered partial imports) | [56](./56-emilia-cascade-and-output/README.md) | covered | `renderDocument` emits `@layer theme, base, components, utilities;` then the four layers; `withLayers(o, false)` drops the `@layer` tokens; `withBase` supplies the base layer. |
| § 20.2 `@theme` | [54](./54-emilia-theme/README.md) | covered | See § 3.5 rows; `inline` is missing, `static` is the default. |
| § 20.3 `@custom-variant` (incl. `@slot`) | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `fn hocus(inner: Token[]) -> Token[]`; "`@slot` … is the parameter". |
| § 20.4 `@utility` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `pub fn scrollbarHidden() -> Token[]`, declaration for declaration with the reference example. |
| § 20.5 `@apply` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | `btn().append(extra)`, `compose([...])`. |
| § 20.6 `@source` | — | n/a | No scanner; nothing to point it at. |
| § 20.7 `@variant` | [59](./59-emilia-custom-utilities-and-variants/README.md) | covered | Same shape as `@custom-variant`: a function over the inner list. |
| § 20.8 `--spacing()` | [54](./54-emilia-theme/README.md) | covered | `spacing(n)` / `spacingHalf(n)`; identical strings on both targets. |
| § 20.9 `theme()` | [54](./54-emilia-theme/README.md) | covered | `themeValue(th, name)` returns the value, `themeVar(name)` the `var(…)` reference. |
| § 21.1 default colour palette | [33](./33-emilia-color-palette/README.md) | covered | Same as § 3.6: 286 values from upstream 4.3.2. |
| § 21.2 spacing scale | [54](./54-emilia-theme/README.md) · [35](./35-emilia-spacing-sizing/README.md) | covered | `--spacing:0.25rem`; every spacing utility is a `calc(var(--spacing) * n)`. |
| § 21.3 default typography | [54](./54-emilia-theme/README.md) · [38](./38-emilia-typography/README.md) | covered | Thirteen `--text-*` + `--text-*--line-height` pairs from the table. |
| § 21.4 default shadows | [54](./54-emilia-theme/README.md) | covered | Seven `--shadow-*` byte-equal. |
| § 21.5 default border radius | [54](./54-emilia-theme/README.md) · [40](./40-emilia-borders/README.md) | covered | Eight `--radius-*`; 40 follows § 21.5's longer list over § 11.1's. |
| § 21.6 default animations | [54](./54-emilia-theme/README.md) · [44](./44-emilia-transitions/README.md) | covered | Four `--animate-*` shorthands byte-equal; the four keyframes bodies from upstream `theme.css`. |
| § 21.7 sharing themes between projects | [54](./54-emilia-theme/README.md) | covered | "a theme is a function in a module, so sharing it is an ordinary package dependency". |
| Referência Rápida de Utilitários | — | n/a | Index of the sections above; no new utilities except `ring`/`divide`/`space`/`sr-only`, handled in their rows. |

## Missing and partial rows, consolidated

Category: (a) follow-up for an existing front · (b) out of scope by design · (c) unplaced — no front claims it.

| Row | Status | Owner | Category | Detail |
|---|---|---|---|---|
| § 3.2 `:has()`, `:not()`, ARIA, data-attribute and `in-[…]` named forms | partial | [34](./34-emilia-modifiers/README.md) / [57](./57-emilia-escape-hatches/README.md) | (c) | Reachable only through `arbSel`; no named tokens or recipes. |
| § 3.2 `group-*` / `peer-*` beyond the declared states; named groups and peers | partial | [34](./34-emilia-modifiers/README.md) | (c) | Six group and eight peer states are named; `group/item`, `peer/name` are not declared. |
| § 3.2 full variant table — five bracket rows | partial | [34](./34-emilia-modifiers/README.md) / [57](./57-emilia-escape-hatches/README.md) | (c) | Aggregate of the rows above. |
| § 3.3 custom breakpoints — a new name | partial | [34](./34-emilia-modifiers/README.md) · [54](./54-emilia-theme/README.md) | (b) | Overrides move the query; a new `--breakpoint-*` name adds no variant (use `arbMin`/`arbMax`). |
| § 3.3 removing breakpoints | partial | [34](./34-emilia-modifiers/README.md) | (c) | A cleared `--breakpoint-*` makes the variant emit `@media (width >= )`; refusing it, as 58 does for container sizes, is unowned. |
| § 3.5 `@theme inline` | missing | — | (c) | emilia always emits `var(--x)` references; no inline (value-resolving) render mode. |
| § 3.7 named class in `@layer utilities` | partial | [59](./59-emilia-custom-utilities-and-variants/README.md) | (b) | `named()` takes no `layer:` argument; `components` only. |
| § 10.4 stop positions, radial/conic, interpolation | partial | [39](./39-emilia-backgrounds/README.md) | (b) | Not in the reference; not declared. |
| § 12.1 `shadow-<color>/<opacity>` | partial | [41](./41-emilia-effects/README.md) | (b) | The reference gives the class and no property/value row. |
| § 16.10 negative translate (`-translate-y-2`) | partial | [45](./45-emilia-transforms/README.md) | (c) | A `Neg` sub-section under `TranslateX`/`TranslateY`, as `Rotate.Neg` does, is not declared. |
| § 16.4 `rotate-x/y/z`, `translate-z`, `scale-z` | — | [45](./45-emilia-transforms/README.md) | (b) | Not in the reference; not a reference row. |
| § 11.7 `outline-hidden`, § 15.6 `@starting-style` | — | [40](./40-emilia-borders/README.md) / [44](./44-emilia-transitions/README.md) | (b) | Not in the reference; not declared. |

## Deviations from Tailwind the library states

- **Preflight is opt-in, not opt-out.** `defaultOptions()` has `base: []`; the reset arrives only through `withBase(defaultOptions(), preflightRules())` — [55](./55-emilia-preflight/README.md). Parity is with § 4's eight bullets, not with upstream `preflight.css`; `border-style:solid` is added beside `border-width:0` so `Border.W.*` is not inert.
- **`@theme static` is always on; no tree-shaking.** Every theme variable is emitted into `:root` in the `theme` layer regardless of use — [54](./54-emilia-theme/README.md).
- **The theme is a flat entry list, not one field per namespace** — [54](./54-emilia-theme/README.md). Extending the theme adds a variable; it never adds a token. New utilities are reached through [57](./57-emilia-escape-hatches/README.md)'s `arbValue` + `themeVar`.
- **Class names are content hashes.** `e_<hex>`, the djb2 fold (std `hash.contentHash`'s) of `encodeSheet(tokensToSheet(tokens, theme))`; a pure function of the token list *and the theme*; order is identity; ASCII only — [48](./48-emilia-attributes/README.md), [56](./56-emilia-cascade-and-output/README.md). There are no literal utility names to scan (§ 3.8 n/a) and no scanner (§ 20.6 n/a).
- **Class prefix is plain concatenation.** `withPrefix(o, "tw_")` → `.tw_e_1`; there is no escaped `.tw\:` form — [56](./56-emilia-cascade-and-output/README.md).
- **`!important`** is per declaration, via `Token.Important(inner)` or `Options.important` — [34](./34-emilia-modifiers/README.md), [56](./56-emilia-cascade-and-output/README.md).
- **Declarations are written `prop:value` with no space after the colon**; the value is the reference's.
- **Breakpoint ranges are nesting, not a variant:** `md:max-xl:` is `Md([MaxXl(inner)])`; breakpoint queries read `--breakpoint-*` from the theme — [34](./34-emilia-modifiers/README.md).
- **Named containers emit both halves.** `containerName(name)` writes `container-type:inline-size;container-name:<name>` in one rule; sizes come from `--container-*` and an emptied namespace panics rather than emitting `@container (width >= )` — [58](./58-emilia-container-queries/README.md).
- **Arbitrary values are validated, and a rejected payload fails the build or panics;** media range syntax is unreachable through `cssQuery` by design, `arbMin`/`arbMax` carry it — [57](./57-emilia-escape-hatches/README.md).
- **Payload-carrying tokens are top-level `Token` variants, never section leaves** (`EffectShadowRaw`, `FilterRaw`, `InteractAccent`, `SvgFill`, `ContainerAt`, `Arb`…), because a nested payload leaf cannot be constructed ([`../language-gaps.md`](../language-gaps.md)).
- **`--tw-*` readers carry inline fallbacks** (`var(--tw-scroll-snap-strictness, proximity)`, the filter chain's empty fallbacks, the gradient stops' `transparent`) in place of upstream's `@property` registrations — [39](./39-emilia-backgrounds/README.md), [42](./42-emilia-filters/README.md), [46](./46-emilia-interactivity/README.md). The transform variables are the exception: front 45 registers them with `@property` blocks and the document's `properties` layer, as upstream does — [45](./45-emilia-transforms/README.md).
- **Token names diverge from class names where the class prefix is overloaded:** `.Gradient.To.*` is direction, `.Gradient.Stop.*` the terminal stop ([39](./39-emilia-backgrounds/README.md)); `.Bg.Pos` vs `.Layout.Position` ([39](./39-emilia-backgrounds/README.md)); `.Flex.Value.One` for `flex-1` and `.Flex.AlignSelf` for `self-*` ([37](./37-emilia-grid/README.md)); `.BackdropFilter` for `backdrop-*` ([42](./42-emilia-filters/README.md)); `.Interact.Cursor.Standard` for `cursor-default` ([46](./46-emilia-interactivity/README.md)); `.Transition.Base` for `transition` ([44](./44-emilia-transitions/README.md)); `Preserve3d` for `transform-3d` ([45](./45-emilia-transforms/README.md)).
- **Negative utilities are a `Neg` sub-section** (`.Margin.T.Neg.4`, `.Transform.Rotate.Neg.12`, `.Outline.Offset.Neg.1`) because a numeric leaf has no signed spelling.
- **`@apply` is array concatenation and `@utility` is a function;** `named()` writes only to `@layer components` and refuses `e_`-prefixed or colliding names — [59](./59-emilia-custom-utilities-and-variants/README.md).
- **`.group` / `.peer` marker classes are the consumer's responsibility;** emilia does not emit them — [34](./34-emilia-modifiers/README.md).
- **`transform`/`transform-cpu` are one token** (`Shorthand.Cpu`) because upstream gives them the same value — [45](./45-emilia-transforms/README.md).
- **Keyframes are hoisted outside every layer and deduplicated by header** — [56](./56-emilia-cascade-and-output/README.md).

## Ordering

54 theme is the root: every value ladder resolves through `spacing(n)` and the theme. 56
cascade-and-output comes next: every front emits through its rule model, and `@media` beside
`@layer`, `@keyframes`, `group-*`, `peer-*`, `rtl`, `space-*` and `divide-*` all need a selector or
at-rule outside the class body. The palette (33), the modifiers (34) and spacing/sizing (35) are the
transversal level after them. The resulting levels are the table in [`README.md`](./README.md).

## The shared files

Every utility front writes one banner-fenced block in `tokens.bp` and one in `emilia.bp`
(`// ── front NN — <domain> ──` … `// ── end front NN ──`); the only lines genuinely shared are the
arms of the top-level `tokenToSheet` `case`, one contiguous block per front — one arm per top-level
section the front owns and one per top-level payload variant (57 adds six, 58 four). A front that
has to edit another front's block has found a design error. `root.bp` and `botopink.json` are
append-only in front-number order. Two sections are shared by design: `Bg { … }` (33 owns
`Bg.Color`, 39 the rest) and the child selector of `space-*` / `divide-*` (35 and 40, one
`siblingSelector()`). [`modules.md`](./modules.md) has the layout.
