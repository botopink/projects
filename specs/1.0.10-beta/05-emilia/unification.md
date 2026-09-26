# emilia — cross-front seams and open work

**Track:** D — emilia · **Cut:** [`modules.md`](./modules.md) · **Coverage:** [`reference-coverage.md`](./reference-coverage.md)

The Tailwind rows no front covers are in [`reference-coverage.md`](./reference-coverage.md)
§ *Missing and partial rows, consolidated*. Every seam two fronts share has one owner and one
current answer:

| Seam | Fronts | How it is settled |
|---|---|---|
| Composing the per-front theme entries into the rendered document | 33 · 38 · 41 · 42 · 44 · 45 · 54 · 56 | `fullTheme()` in `emilia.bp` (56, decision 80): `defaultTheme()` extended by `paletteEntries`, `typographyEntries`, `effectEntries`, `filterEntries`, `transitionEntries`, `transformEntries`, one line per front; `flush()` renders with `fullOptions()`. `defaultOptions()` stays theme-only (`output.bp` cannot import `emilia.bp`) |
| `Important(inner)` | 34 · 56 | a top-level modifier in 34's table, `markImportant` on the inner sheet (decision 81) |
| `accent-auto` | 46 | the nullary leaf `Interact.AccentAuto` beside the payload variant (decision 81) |
| Dark mode by class / attribute | 34 · 54 | 34's `darkVariant(th)` reads `darkAtRule(th)`/`darkSelector(th)`; a test proves each `DarkMode` strategy |
| Breakpoints under a theme override | 34 · 54 · 58 | every breakpoint fn takes `th` and reads `--breakpoint-*` (decision 82); container sizes read `--container-*` |
| The filter, snap and transform `--tw-*` readers | 42 · 45 · 46 | a `--tw-*` name cannot be a theme entry; filters and snap inline the reader with `cssVarOr` fallbacks (`filterChain()`, `var(--tw-scroll-snap-strictness, proximity)`); the transform variables are upstream's `@property` blocks with the document's `properties` layer (05emilia-i) |
| Shadow and ring composition | 40 · 41 | one five-channel `box-shadow` reader shared by every shadow and ring token |
| `space-*` and `divide-*` child selector | 35 · 40 | one `siblingSelector()` (`:where(& > :not(:last-child))`), asserted byte-identical |
| `sr-only` bodies and the keyframes bodies | 44 · 47 · 54 | read from upstream (`utilities.ts`, `theme.css`), dated in the source comment, asserted as literals |
| `skew-x` in the reference file | 45 | not CSS; the leaves emit upstream v4's `--tw-skew-x:skewX(…)` and the `transform` chain |
| The class-name hash | 48 · 56 | contract 4, fixture `e_39b87d03`; the switch to std's `hash.contentHash` is open (below) |

## Open boxes

| Box | Front | Owner of the remaining work |
|---|---|---|
| The unknown-prefix refusal of `extendTheme` is in the compiler's Zig suite | [54](./54-emilia-theme/README.md) | compiler test suite |
| `hashHex` is gone; the class name is std's `hash.contentHash`, fixture unchanged (decision 116) | [56](./56-emilia-cascade-and-output/README.md) | one std import in `emilia.bp`, with or after `00 · 23-std-purity` |
| No file under jhonstart's `src/` names emilia | [48](./48-emilia-attributes/README.md) | jhonstart front 30 (`streaming.bp` comment) |
| …asserted by the `jhonstart-emilia` bridge test | [48](./48-emilia-attributes/README.md) | jhonstart front 30 |
| The literal fixture is asserted by the bridge test and onze 68 | [48](./48-emilia-attributes/README.md) | jhonstart front 30, onze front 68 |
