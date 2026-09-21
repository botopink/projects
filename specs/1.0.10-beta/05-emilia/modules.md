# Modules — the `emilia` package cut

**Track:** D — emilia · **Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 (`TAILWIND_CSS_DOCS.md`)

The final granularity of `repository/emilia/modules/**` and `repository/emilia/examples/**`, the
dependency graph, the target, what `emilia-test` exposes, and the front → directory ownership that
[`README.md`](./README.md) copies. The cut is evaluated against the milestone's starting proposal
(one submodule per domain: `emilia-theme`, `emilia-modifiers`, …), against front
[95](../02-packaging/95-ecosystem-package-restructure/README.md)'s verdict (`emilia` + `emilia-test`,
nothing else), and against what the language permits.

> **Amended 2026-09-21, after fronts 54, 56, 33, 34, 35, 36, 37, 39, 40 and 38 landed.** The package
> cut below (two members) is correct and is what the tree has. What is **not** in the tree is the
> file split this document and every front's `Owns:` line describe:
>
> - paths are `repository/emilia/modules/emilia/src/…`, not `repository/emilia/src/…` — the repo
>   became a workspace under `02-packaging` step 2 and the front specs predate it;
> - there is **no `utilities/` directory** and **no `test/` directory**. Ten fronts have now landed
>   the same way: banner-fenced blocks inside `modules/emilia/src/emilia.bp`, with inline `test {}`
>   beside the code they test. That is the convention, and a front that creates `utilities/x.bp` to
>   satisfy a table would be the only one;
> - there is no `fullTheme()`; front 54's `defaultTheme()` is the theme a test passes.
>
> Every front's `Owns:` line should be read as *"the banner-fenced block for this domain"*. Whoever
> does want the file split does it as its own front, across the whole file at once — doing it one
> front at a time would leave the library half in each shape.

## Verdict

Two submodules — front 95's cut survives the audit. The candidates it was tested against are below.

| Submodule | Holds | Target | Depends on |
|---|---|---|---|
| **`emilia`** (core) | the `Token` enum, theme, spacing, the rule model and renderer, the variant table, the sixteen utility dispatchers, preflight, escape hatches, container queries, compose, the attribute slot (`styled`, `cls`, `mergeClass`) | comptime — compiled and tested on **both** `commonJS` and `erlang`; a string that differs by backend is a defect | `std`; dev-only: `emilia-test`, `jhonstart` (the integration test renders a page) |
| **`emilia-test`** | `assert<Subject>(loc, …) -> @Result<void, string>` snapshot helpers over compiled CSS and over the style AST | same as core — the `.snap` files are shared by both targets, which is how byte-equality across backends is enforced | `emilia`, `std` (`asserts`, `snapshots`) |

## The candidates, each with its verdict

| Candidate | Fronts | Verdict | Reason |
|---|---|---|---|
| `emilia-theme` | 54 | **merge** into core (`theme.bp`, `spacing.bp`) | `Options.theme` is a `Theme`, `defaultOptions()` calls `defaultTheme()`, every sub-dispatcher takes `th: Theme` ([contract 4a](../contracts.md)), and front 33's `paletteEntries()` composes into it. No consumer takes the theme without emitting through emilia. Tailwind ships `theme.css` as a *file* inside one package, not as a package |
| `emilia-modifiers` | 34 | **drop** as submodule; keep as `variants.bp` | 34 delivers one `Variant`-returning fn per name and nothing else; `Variant` is 56's type, and `tokenToSheet` in core applies them. Core would depend on the submodule and the submodule on core — a cycle |
| `emilia-preflight` | 55 | **merge**; keep as `preflight.bp` | `preflightRules() -> Rule[]` is a value handed to `withBase`; opting in or out is already an `Options` decision, not a dependency decision. Tailwind ships `preflight.css` as a file. This is the one candidate a consumer could plausibly want alone; the cost of the file is nil and the cost of a package is a second manifest for eleven rules |
| `emilia-escape-hatches` | 57 | **merge** (language constraint) | Its six payload variants are **top-level `Token` variants** ([language-gaps](../language-gaps.md): a payload leaf inside a section cannot be constructed). A `Token` variant must live in the file that declares `Token` |
| `emilia-container` | 58 | **merge** (language constraint) | Same: one section plus three top-level variants on `Token` |
| `emilia-compose` | 59 | **merge**; keep as `compose.bp` | Functions over `Token[]` and `Variant`, nothing core reads back. It is the one file that *could* leave core later with no surface change; splitting one file into a package is the "one file each" anti-pattern front 95 names |
| `emilia-utilities-<domain>` (layout, typography, …) | 33 · 35–47 | **drop** | A sub-dispatcher takes `Token.<Section>` and is called from `tokenToSheet`'s exhaustive `case` in core. Moving it out makes core depend on the domain package and the domain package on core's `Token` — a cycle for each of fourteen packages |
| `emilia-jhonstart` | 48 | **drop** — evaluated because dependency direction would have justified it, dropped because the direction does not exist | Front 48's source is jhonstart-free: `styled(tokens, th) -> #("class", string)`, `styledWith`, `className`, `mergeClass`, `assertAsciiBody` (`attributes.bp`) and `cls`/`clsWith` (`html_hook.bp`) return tuples and strings; the one jhonstart file (`repository/jhonstart/src/html_attrs.bp`) imports only `element` and a test asserts the string `emilia` is absent from `repository/jhonstart/src/`. Only `integration_test.bp` renders a page. A package that holds tests and no source is not a package; `jhonstart` is a **dev-dependency** of core instead. **The trigger that makes it one:** the day jhonstart ships a handler registry that emilia must *import* to register itself (the 1.0.7 `[name]={expr}` design, rejected in 1.0.9 because `html.bp` is frozen), the bridge moves to `modules/emilia-jhonstart/` and core's dev-dependency on jhonstart goes away |

Tailwind's own shape is the tie-breaker everywhere a call was close: one package (`tailwindcss`),
with `theme.css`, `preflight.css` and `utilities.css` as files inside it, imported into named
layers by `@import "tailwindcss"` (`§ 20.1`). `emilia` mirrors that: one core package with those
files, and `renderDocument` playing the part of the `@layer theme, base, components, utilities;`
preamble.

## The `tokens.bp` problem, resolved

Sixteen fronts (33–47, 57, 58 — and 34 for the modifier variants) add variants to one `pub type
Token { … }`. In 1.0.9 they also added a sub-dispatcher each to one `emilia.bp`. Two files, sixteen
writers each, fenced by comment banners.

**What the language allows.** `Token` is one declaration. A section is a type written by its path
(`Token.Text`, `Token.Border.Color` — decision 8 §5.3b) and is not declarable elsewhere; there is no
partial type, no `extend`-adds-variants, and the compiler is not asked for one (no front touches the
compiler). Splitting `Token` into per-package enums would change the authored surface
(`[.Bg.White, .Text.Bold, Token.Hover(inner)]` needs one element type), which the milestone forbids.
So **`tokens.bp` stays one file, and that is a constraint, not a choice.**

**What moves.** Everything that is not the enum body leaves the shared files:

| Was (1.0.9) | Becomes (1.0.10) | Writers |
|---|---|---|
| `src/tokens.bp` — sections + payload variants | `modules/emilia/src/tokens.bp` — **unchanged role**; one contiguous banner block per front, appended in front-number order | 16 fronts, one block each |
| `src/emilia.bp` — `tokenToCss` + sixteen sub-dispatchers + their value ladders + host cells + public entry | `modules/emilia/src/emilia.bp` — host cells, `emilia`/`emiliaWith`/`flush`/`flushWith`, and `tokenToSheet` **only**; one arm block per front under its banner | 56 owns the file; 16 fronts add one contiguous arm block each |
| (the sixteen sub-dispatchers, interleaved in `emilia.bp`) | `modules/emilia/src/utilities/<front>.bp` — **one file per front**, front-owned, no sharing: the sub-dispatcher(s), the value ladders, the front's theme entries, and nothing else | 1 front each |
| (inline `test` blocks at the foot of `emilia.bp`) | `modules/emilia/test/<front>_test.bp` + `modules/emilia/test/__snapshots__/<suite>/<slug>.snap` | 1 front each |

**The `utilities/mod.bp` trap, closed up front.** A per-front file needs a `pub mod <name>;` line,
and a `pub mod` line cannot be banner-fenced — which is exactly the append-only problem `root.bp` has
today. So the package restructure (front 95's emilia step, or 56 if 95 has landed without it) creates
`utilities/mod.bp` with **all sixteen `pub mod` lines** and sixteen stub files, each holding only a
docblock naming its front. Every utility front then edits only its own stub. No front appends to
`utilities/mod.bp`; a merge conflict on it is a design error.

`root.bp` and `botopink.json` keep the 1.0.9 rule for the fronts that still add a module file
(48 · 54 · 55 · 56 · 57 · 58 · 59): **append in front-number order, never reorder, never edit another
front's line; a conflict is resolved by re-sorting.**

**What remains shared, in full.** Two files, one contiguous block per front in each:
`tokens.bp` (the enum body) and `emilia.bp` (the `tokenToSheet` arms). A front that edits another
front's block has found a design error and files it as such. The compiler is the guard: a section
without an arm reds the exhaustive `case`; an arm without a section reds the pattern.

**One more shared thing, named so it is owned.** Five fronts contribute theme entries beyond
`defaultTheme()` — 33 `paletteEntries()`, 38 `--font-weight-*`/`--tracking-*`/`--leading-*`,
41 `--inset-shadow-*`/`--text-shadow-*`, 42 `--blur-*`/`--drop-shadow-*`, 44/45 `--ease-*`/`--perspective-*`
— each as a `ThemeEntry[]`-returning function in its own `utilities/<front>.bp`. 54 says the consumer
composes them with `extend`; 56 says `defaultOptions()` carries `defaultTheme()`. Nobody composes
them by default, so a default document would reference `var(--color-red-500)` and never define it.
The resolution here: **56 owns `fullTheme()`** in `emilia.bp` — `defaultTheme()` extended by every
front's entries function, in front-number order — and `defaultOptions()` carries `fullTheme()`.
Each front adds its one `extendTheme(…)` line under its banner in `fullTheme()`, exactly as it adds its
`tokenToSheet` arm. `defaultTheme()` itself stays 54's and stays palette-free.

## The tree

```
repository/emilia/
├── botopink.json                        (workspace manifest — points at modules/)
├── AGENTS.md
├── modules/
│   ├── emilia/                          core
│   │   ├── botopink.json                {"name":"emilia","targets":["commonJS","erlang"],"src":"src/","files":[…],"devDependencies":["emilia-test","jhonstart"]}
│   │   ├── src/
│   │   │   ├── root.bp                  pub mod … lines, `pub default mod emilia`
│   │   │   ├── tokens.bp                the one `Token` enum                         (33–47 · 57 · 58, banners)
│   │   │   ├── theme.bp                 Theme, Ns, defaultTheme, extend, themeValue…  (54)
│   │   │   ├── spacing.bp               spacing(n), spacingHalf(n)                    (54)
│   │   │   ├── output.bp                Rule, Block, Sheet, Variant, Options, codec, renderer (56)
│   │   │   ├── emilia.bp                host cells · emilia/emiliaWith · flush/flushWith · fullTheme · tokenToSheet (56 + one arm block per front)
│   │   │   ├── variants.bp              one Variant-returning fn per variant name     (34)
│   │   │   ├── preflight.bp             preflightRules() -> Rule[], preflight()       (55)
│   │   │   ├── arbitrary.bp             arbValue/arbProp/arbSel/arbAt/arbMin/arbMax + css* validators (57)
│   │   │   ├── container.bp             ContainerSize, containerAt*, containerNamed   (58)
│   │   │   ├── compose.bp               compose, named, hocus, selector, …            (59)
│   │   │   ├── attributes.bp            styled, styledWith, className, mergeClass, assertAsciiBody (48)
│   │   │   ├── html_hook.bp             cls, clsWith — the pre-bound `[class]={…}` hole (48)
│   │   │   └── utilities/
│   │   │       ├── mod.bp               sixteen `pub mod` lines, written once
│   │   │       ├── color.bp             colorTokenToCss, bgColorTokenToCss, paletteVar, alphaWrap, paletteEntries (33)
│   │   │       ├── spacing_sizing.bp    padTokenToCss, marginTokenToCss, sizeTokenToCss, spaceTokenToSheet (35)
│   │   │       ├── layout.bp            (36)
│   │   │       ├── grid.bp              flex, grid, gap                               (37)
│   │   │       ├── typography.bp        text, font, list + typographyEntries()        (38)
│   │   │       ├── backgrounds.bp       bg (non-colour), gradient                     (39)
│   │   │       ├── borders.bp           border, outline, ringTokenToSheet, divideTokenToSheet (40)
│   │   │       ├── effects.bp           effect, blend, mask + effectsEntries()        (41)
│   │   │       ├── filters.bp           filter, backdrop + filtersEntries()           (42)
│   │   │       ├── tables.bp            (43)
│   │   │       ├── transitions.bp       transition, animateTokenToSheet + easeEntries() (44)
│   │   │       ├── transforms.bp        + perspectiveEntries()                        (45)
│   │   │       ├── interactivity.bp     (46)
│   │   │       └── svg_a11y.bp          svg, a11y                                     (47)
│   │   └── test/
│   │       ├── <front>_test.bp          one per front (see ownership table)
│   │       ├── integration_test.bp      48 — renders through jhonstart (dev-dependency)
│   │       └── __snapshots__/<suite>/<slug>.snap
│   └── emilia-test/
│       ├── botopink.json                {"name":"emilia-test","dependencies":["emilia","std"]}
│       ├── src/root.bp                  re-exports asserts.bp
│       ├── src/asserts.bp               assertCss, assertCssWith, assertUtility, assertVariant, assertTheme, assertRules, assertCascade, assertClassName
│       └── test/                        the helpers' own tests + __snapshots__/
└── examples/                            see below
```

The three modules the 1.0.9 `root.bp` docblock wanted (`tokens` / `stylesheet` / `emilia`) are here
as `tokens.bp` / `output.bp` + the cells in `emilia.bp` / `emilia.bp`. The host cells cannot leave
`emilia.bp`: a cross-module bare import of an `#[@External.…]` declaration is `undefined` at run time
(`repository/emilia/src/root.bp:9-22`). `output.bp` declares no externals and is pure.

The one file outside the repo: `repository/jhonstart/src/html_attrs.bp` (`classAttr`, `withAttrs`,
`attrValue`), owned by front 48, importing only jhonstart's `element`.

### `botopink.json`, workspace and core

```jsonc
// repository/emilia/botopink.json
{ "name": "emilia", "version": "0.1.0", "modules": ["modules/emilia", "modules/emilia-test"] }

// repository/emilia/modules/emilia/botopink.json
{
  "name": "emilia",
  "target": "commonJS",
  "targets": ["commonJS", "erlang"],
  "src": "src/",
  "files": ["root.bp", "tokens.bp", "theme.bp", "spacing.bp", "output.bp", "emilia.bp", "variants.bp",
            "preflight.bp", "arbitrary.bp", "container.bp", "compose.bp", "attributes.bp", "html_hook.bp",
            "utilities/mod.bp", "utilities/color.bp", "utilities/spacing_sizing.bp", "utilities/layout.bp",
            "utilities/grid.bp", "utilities/typography.bp", "utilities/backgrounds.bp", "utilities/borders.bp",
            "utilities/effects.bp", "utilities/filters.bp", "utilities/tables.bp", "utilities/transitions.bp",
            "utilities/transforms.bp", "utilities/interactivity.bp", "utilities/svg_a11y.bp"],
  "devDependencies": ["emilia-test", "jhonstart"]
}
```

The `files` list is written once by the restructure step, in full, including the sixteen utility
stubs — so no utility front appends to it either. Only 48 · 54 · 55 · 56 · 57 · 58 · 59 add a line,
in front-number order.

## Dependency graph

```
              std ────────────────────────────┐
               │                              │
               ▼                              ▼
            emilia  ◄──── emilia-test      jhonstart ◄── (dev-only) emilia/test/integration_test.bp
           (core)                             ▲
             ▲  ▲                             │
             │  └── onze 69 (flushWith)        └── jhonstart 94 (element surface: the attrs array the slot writes into)
             └───── onze 68 (contract 4 literal)

Inside core, by file (arrows = imports):
  tokens.bp ◄── utilities/*.bp ◄── emilia.bp ──► output.bp ──► theme.bp ◄── spacing.bp
                    ▲                 │                             ▲
                    └── theme.bp      ├──► variants.bp ──► output.bp│
                                      ├──► arbitrary.bp ──► output.bp, theme.bp
                                      ├──► container.bp ──► output.bp, theme.bp
                                      └──► compose.bp   ──► output.bp, variants.bp
  preflight.bp ──► output.bp            attributes.bp ──► emilia.bp (styled calls emiliaWith)
                                        html_hook.bp  ──► attributes.bp
```

No cycle: `theme.bp`, `spacing.bp`, `output.bp` import nothing from emilia; `utilities/*` import
`tokens`, `theme`, `spacing`, `output` (for `Sheet` where a selector is needed) and, for colour
payloads, `utilities/color` (`paletteVar`); `emilia.bp` imports every dispatcher and is imported only
by `attributes.bp`, which nothing else imports but `html_hook.bp`.

## Target

`emilia` runs at comptime and emits strings. It sits nowhere on the erlang/js axis
([overview](../overview.md) *Which target runs what*) and is compiled and tested on **both**
`commonJS` and `erlang`; the only state it has — the per-render `Stylesheet` cell — exists as a
`Map` on `globalThis` and as a process-dictionary list, behind one contract. `emilia-test`'s `.snap`
files are the byte-equality gate between the two: one snapshot, two targets, one result.

Front 48's output is the one thing both halves of an application read: the class attribute is
written by the server render (rakun [23](../03-rakun/23-rakun-ssr-pipeline/README.md), erlang) and
recomputed by the client bundle (onze [68](../06-onze/68-onze-client-bundle/README.md), js). Contract
4's shared fixture asserts the same literal on both.

## What `emilia-test` exposes

Every helper is `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>`; the
snapshot path is `snapshots.path(loc)` per [`../01-std/snapshots.md`](../01-std/snapshots.md); a
mismatch or a missing file writes `<path>.new` and fails; there is no update flag. Rendering is
always through front 56's renderer under `defaultOptions()` unless the helper takes an `Options` or a
`Theme`.

| Helper | Snapshots | Rendering rule |
|---|---|---|
| `assertCss(loc, tokens: Token[])` | the **utilities-layer rules** of one class | `tokensToSheet(tokens, fullTheme())`, each `Rule` through `renderRule("e", r, defaultOptions())`, one rule per line, then each `Block` one per line. The class is fixed to `.e` so a theme default changing does not invalidate every utility snapshot |
| `assertCssWith(loc, tokens, th: Theme)` | same | same, under `th` |
| `assertUtility(loc, token: Token)` | the **style AST** of one token | `tokenToSheet(token, fullTheme())` decoded: one line per rule `layer \| atRules (outermost-first, comma-joined, `-` when empty) \| selector \| declarations \| important`, then `block \| header \| body` |
| `assertVariant(loc, v: Variant)` | two lines | `atRule: …` and `selector: …` |
| `assertTheme(loc, th: Theme)` | the theme layer | `themeCss(th)` split on `;`, one entry per line, then the `@keyframes` blocks from `keyframeCss(th)`, one per line |
| `assertRules(loc, rules: Rule[])` | literal-selector rules (preflight, named utilities) | each through `renderRule("", r, defaultOptions())`, one per line |
| `assertCascade(loc, lists: Token[][], o: Options)` | the **whole document** | each list through `emiliaWith(list, o.theme)`, then `flushWith(o)`; `<style>`/`</style>` stripped; a newline after the `@layer …;` preamble and after every top-level `}`; class names rewritten to `e1 … eN` in registration order so ordering is what the snapshot pins |
| `assertClassName(loc, tokens: Token[])` | one line: the literal `e_<hex>` | `emilia(tokens)` under `fullTheme()` — the contract 4 fixture; the shared `.snap` is what makes "identical on both targets" a test rather than a claim |

What it does not do: refusals. A `Variant` with two `&`, an `extend` with an unknown prefix, an
`Arb` carrying a codec separator — these are build failures, not values a test can read. They are
recorded in the test file as notes and carried into the compiler's suite, as every 1.0.9 front says.

`emilia-test` imports `std/asserts` and `std/snapshots` and nothing from `jhonstart`. Front 48's
rendered-HTML checks compare `renderToString` output with `std/asserts.equal` in
`modules/emilia/test/integration_test.bp`.

## Front → directory ownership

Each front to exactly one directory; the two shared files are named explicitly where a front writes
a block to them.

| Front | Submodule | Owns (under `modules/emilia/`) | Shared-file blocks |
|---|---|---|---|
| 54 theme | `emilia` | `src/theme.bp`, `src/spacing.bp`, `test/theme_test.bp`, `test/spacing_test.bp` | `root.bp` + `botopink.json` lines |
| 56 cascade-and-output | `emilia` (+ writes `emilia-test`) | `src/output.bp`, `src/emilia.bp` (cells, entry points, `fullTheme` shell, `tokenToSheet` shell), `test/output_test.bp`, `test/cascade_test.bp`; `modules/emilia-test/**` | `root.bp` + `botopink.json` lines |
| 33 color-palette | `emilia` | `src/utilities/color.bp`, `test/colors_test.bp` | `tokens.bp` block (`Color`, `Bg.Color`, `Alpha`); `emilia.bp` arm block + `fullTheme` line |
| 34 modifiers | `emilia` | `src/variants.bp`, `test/modifiers_test.bp` | `tokens.bp` block (modifier variants); `emilia.bp` arm block |
| 35 spacing-sizing | `emilia` | `src/utilities/spacing_sizing.bp`, `test/spacing_test.bp` | `tokens.bp` (`Pad`, `Margin`, `Size`, `Space`); `emilia.bp` arm block |
| 36 layout | `emilia` | `src/utilities/layout.bp`, `test/layout_test.bp` | `tokens.bp` (`Layout`); `emilia.bp` arm |
| 37 grid | `emilia` | `src/utilities/grid.bp`, `test/grid_test.bp` | `tokens.bp` (`Flex`, `Grid`, `Gap`); `emilia.bp` arm block |
| 38 typography | `emilia` | `src/utilities/typography.bp`, `test/typography_test.bp` | `tokens.bp` (`Text`, `Font`, `List`); `emilia.bp` arm block + `fullTheme` line |
| 39 backgrounds | `emilia` | `src/utilities/backgrounds.bp`, `test/backgrounds_test.bp` | `tokens.bp` (`Bg` non-colour, `Gradient`); `emilia.bp` arm block |
| 40 borders | `emilia` | `src/utilities/borders.bp`, `test/borders_test.bp` | `tokens.bp` (`Border`, `Outline`, `Ring`, `Divide`); `emilia.bp` arm block |
| 41 effects | `emilia` | `src/utilities/effects.bp`, `test/effects_test.bp` | `tokens.bp` (`Effect`, `Blend`, `Mask` + 3 payload variants); `emilia.bp` arm block + `fullTheme` line |
| 42 filters | `emilia` | `src/utilities/filters.bp`, `test/filters_test.bp` | `tokens.bp` (`Filter`, `Backdrop` + 2 payload variants); `emilia.bp` arm block + `fullTheme` line |
| 43 tables | `emilia` | `src/utilities/tables.bp`, `test/tables_test.bp` | `tokens.bp` (`Table` + 1 payload variant); `emilia.bp` arm block |
| 44 transitions | `emilia` | `src/utilities/transitions.bp`, `test/transitions_test.bp` | `tokens.bp` (`Transition`, `Animate` + 2 payload variants); `emilia.bp` arm block + `fullTheme` line |
| 45 transforms | `emilia` | `src/utilities/transforms.bp`, `test/transforms_test.bp` | `tokens.bp` (`Transform` + 2 payload variants); `emilia.bp` arm block + `fullTheme` line |
| 46 interactivity | `emilia` | `src/utilities/interactivity.bp`, `test/interactivity_test.bp` | `tokens.bp` (`Interact` + 3 payload variants); `emilia.bp` arm block |
| 47 svg-accessibility | `emilia` | `src/utilities/svg_a11y.bp`, `test/svg_a11y_test.bp` | `tokens.bp` (`Svg`, `A11y` + 3 payload variants); `emilia.bp` arm block |
| 55 preflight | `emilia` | `src/preflight.bp`, `test/preflight_test.bp` | `root.bp` + `botopink.json` lines |
| 57 escape-hatches | `emilia` | `src/arbitrary.bp`, `test/arbitrary_test.bp` | `tokens.bp` (six top-level variants); `emilia.bp` arm block (six arms); `root.bp` + `botopink.json` |
| 58 container-queries | `emilia` | `src/container.bp`, `test/container_test.bp` | `tokens.bp` (`Container` + three top-level variants); `emilia.bp` arm block (four arms); `root.bp` + `botopink.json` |
| 59 custom-utilities-and-variants | `emilia` | `src/compose.bp`, `test/compose_test.bp` | `root.bp` + `botopink.json` lines |
| 48 attributes | `emilia` | `src/attributes.bp`, `src/html_hook.bp`, `test/attributes_test.bp`, `test/integration_test.bp`; plus `repository/jhonstart/src/html_attrs.bp` (the cross-repo file) | `root.bp` + `botopink.json` lines (two modules; `devDependencies` gains `jhonstart`); none in `tokens.bp` / `emilia.bp` |

`emilia-test` has no front of its own. Front 56 owns the renderer and therefore the helpers that
render, and lands them in the same wave so that 33/34/35 write snapshot tests from their first
commit. A front that finds a helper missing files it against 56, not into `emilia-test` itself.

**Contract 4 path amendment.** [Contract 4](../contracts.md) clause 4 names `mergeClass` at
`emilia/src/attributes.bp` and the shared fixture at `emilia/test/integration_test.bp`. Under
`modules/` those are `modules/emilia/src/attributes.bp` and `modules/emilia/test/integration_test.bp`
— the same function and the same fixture, moved with the package.

## Relation to `jhonstart` and `onze`

| Neighbour | Front | What crosses | Direction |
|---|---|---|---|
| jhonstart | 48 (this track) | `styled(tokens, th)` returns the `#("class", …)` pair a builder's `attrs` array takes; `cls(tokens, th)` returns the string a pre-bound `[class]={…}` hole in the `html """…"""` DSL takes (a hole may not contain a space — `html.bp:109` splits the tag body on `" "`). `repository/jhonstart/src/html_attrs.bp` (`classAttr`, `withAttrs`, `attrValue`) is the one cross-repo file. The value carried is `mergeClass(static, emilia(tokens, th))` per contract 4 | none at package level: jhonstart never imports emilia; emilia imports jhonstart only in a test |
| jhonstart | [94](../04-jhonstart/94-jhonstart-element-surface/README.md) | the element constructors' `attrs` array that the slot writes into; attribute array order is class identity (contract 4 clause 5) | read-only |
| onze | [69](../06-onze/69-onze-styling-pipeline/README.md) | `flushWith(o)` called once per server render; the document inserted into `<head>`; the client bundle never calls `flush()` (contract 6a) | `onze` → `emilia` |
| onze | [68](../06-onze/68-onze-client-bundle/README.md) | the hydration entry recomputes `emilia(tokens)` and asserts the contract 4 literal | `onze` → `emilia` |
| rakun | [23](../03-rakun/23-rakun-ssr-pipeline/README.md) | the SSR test asserts the same contract 4 literal the integration fixture pins | `rakun` → `emilia` (test) |

Front 48's README names 23 and 68 as the two consumers of the shared literal; 94 and 69 are the
surfaces it writes into and is collected by. The core package is what all four depend on, and it
never grows a runtime import of `jhonstart`.

## `repository/emilia/examples/**`

Each example is a package (`botopink.json` + `src/main.bp` + `test/` + `__snapshots__/`), builds
under the examples gate (`runExamplesGate`), and its snapshot map is in
[`test-snap-examples.md`](./test-snap-examples.md).

| Example | Exercises | Depends on |
|---|---|---|
| `emilia-card` (exists; migrated to the 1.0.10 surface) | one card: palette, spacing, hover/md, `flush()` document | `emilia`, `jhonstart` |
| `theme-brand` | 54 + 33: a brand theme extending the default, a cleared colour namespace, `flushWith(withTheme(…))`, `themeValue` readback | `emilia` |
| `dashboard-layout` | 35 · 36 · 37 · 58: grid template, spans, gap, sizing, sticky header, container queries on a card | `emilia` |
| `typography-article` | 38 · 55 · 34: prose sizes with `--text-*--line-height`, decoration, `line-clamp`, `first-letter`, preflight via `withBase` | `emilia` |
| `interactive-button` | 34 · 40 · 41 · 44 · 45 · 46: hover/focus-visible/disabled, ring, shadow, transition, scale, cursor | `emilia` |
| `dark-mode-nav` | 34 · 54: `Dark` under the three `DarkMode` strategies, breakpoint ladder, group-hover | `emilia` |
| `media-gallery` | 39 · 42 · 47 · 36 · 43: gradients, object-fit, filters and backdrop, svg fill/stroke, a captioned table | `emilia` |
| `arbitrary-and-compose` | 57 · 59: arbitrary values/properties/variants, a named utility in `components`, `apply`, a custom variant | `emilia` |
| `jhonstart-attributes` | 48: `styled` on a builder and `cls` in a `[class]={…}` hole on one rendered page, the contract 4 literal | `emilia`, `jhonstart` |

Nine projects, every front reached by at least one, `jhonstart` pulled by exactly two.
