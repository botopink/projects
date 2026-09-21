# Unification — what the drafts still owed, and where it went

**Track:** D — emilia · **Sources:** `specs/1.0.8-beta/` (15 fronts + `overview.md`, `fronts.md`, `tailwind-mapping.md`), `specs/1.0.7-beta/15-emilia-attributes`, `specs/1.0.7-beta/16-emilia-jhonstart-integration`, `specs/1.0.9-beta/` (22 fronts, `tracks/README.md`, `fronts.md` Track D)

The 1.0.9 merge absorbed the drafts and said so in each front's `Replaces:` line. This is the check
that it did so losslessly: every old README compared section by section against its 1.0.10 copy;
anything present in the draft and absent from the copy appended under `## Carried from …` at the end
of the copy (quoted, Portuguese prose translated, every token name, value, table row and bullet
kept); every old `examples/*.bp` copied beside the new ones.

## Fronts

| Old path | New path | Verdict | What was appended |
|---|---|---|---|
| `1.0.8-beta/14-emilia-color-palette` | [`33-emilia-color-palette`](./33-emilia-color-palette/README.md) | appended | the literal hex ladder (Red 50–950) and 27 hex acceptance bullets (1.0.10 emits `var(--color-*)`, the hex is now theme data); blast radius; opacity-was-F15 note; 19 old test names; `Border.Color.*` usage. Example `color-palette-example.bp` carried under its own name (no clash) |
| `1.0.8-beta/15-emilia-modifiers` | [`34-emilia-modifiers`](./34-emilia-modifiers/README.md) | appended | `GroupVisited`, `PeerActive`, `PeerRequired` (absent from the 1.0.10 table); the five `Container*` modifiers (`@container(min-width:24/28/32/36/42rem)` — now front 58's `containerAt*`); the pre-v4.3 `px` / `&[open]` / no-`&` forms and 24 acceptance bullets; blast radius. `modifiers-example-1.0.8.bp` |
| `1.0.8-beta/03-emilia-spacing-sizing` | [`35-emilia-spacing-sizing`](./35-emilia-spacing-sizing/README.md) | appended | the `Full` leaf (100%) on every `Pad`/`Margin` direction; `Size.MaxW.Prose` → `max-width:65ch`; the resolved rem ladder (`1=0.25rem … 96=24rem`); the exhaustive-no-`_` dispatcher rule; blast radius; spelling map (`NegX`→`X.Neg`, `InlineSize`→`Inline`, `ScreenSm`→`Screen.Sm`). `spacing-sizing-example.bp` carried under its own name |
| `1.0.8-beta/01-emilia-layout` | [`36-emilia-layout`](./36-emilia-layout/README.md) | appended | the 19-URL per-utility reference list; `Columns { 4 … 12 }` (1.0.10 declares 1–3); the six-step offset scale; verbatim acceptance (`aspect-ratio:16/9` without spaces, `Visibility.Hidden` vs `Invisible`); no-`_` rule; blast radius; spelling map. `layout-example-1.0.8.bp` |
| `1.0.8-beta/02-emilia-grid` | [`37-emilia-grid`](./37-emilia-grid/README.md) | appended | the short `Basis`/`Gap`/`GapX`/`GapY` subsets; the narrower `Rows 1–6` / `Row.Span 1–6` / `RowStart 1–7`; verbatim acceptance (`repeat(3,minmax(0,1fr))` without spaces, `gap:1rem`); no-`_` rule; blast radius; spelling map (`Grid.JustifyItems`→`Flex.JustifyItems`, `Flex1`→`Value.One`, `SpanN`→`Span.N`). `grid-example-1.0.8.bp` |
| `1.0.8-beta/04-emilia-typography` | [`38-emilia-typography`](./38-emilia-typography/README.md) | appended | numeric `Leading.{3..10}`; the `8` step on `Indent`/`Thickness`/`Offset`; the literal tracking/leading values; blast radius; rename map (`Smoothing.Auto`→`Subpixel`, `VariantNumeric`→`Nums`). `typography-example-1.0.8.bp` |
| `1.0.8-beta/05-emilia-backgrounds` | [`39-emilia-backgrounds`](./39-emilia-backgrounds/README.md) | appended (minor) | the v3-shaped stop pin (`#ef4444` + `var(--tw-gradient-to,transparent)`, no space after comma); blast radius; rename map (`Position`→`Pos`, `NoRepeat`→`None`, `RepeatX/Y`→`X/Y`, stop `To`→`Stop`). `backgrounds-example-1.0.8.bp` |
| `1.0.8-beta/06-emilia-borders` | [`40-emilia-borders`](./40-emilia-borders/README.md) | appended (minor) | the literal radius ladder (v3-shaped, no `Xs`, `Sm`=`0.125rem`); resolved-literal acceptance bullets; blast radius; rename map (`RoundedT`→`Rounded.T` …). `borders-example-1.0.8.bp` |
| `1.0.8-beta/07-emilia-effects` | [`41-emilia-effects`](./41-emilia-effects/README.md) | appended | six opacity steps (`15,35,45,55,65,85`); `Mask.Position.{Top,Bottom,Left,Right}`; `Mask.Repeat.{RepeatX,RepeatY,Round,Space}`; `Mask.Size.Auto`; the shadow literals; blast radius; renames (`Blend`/`BgBlend`→`.Blend.Mix`/`.Blend.Bg`, `2xs`→`X2xs`). `effects-example-1.0.8.bp` |
| `1.0.8-beta/08-emilia-filters` | [`42-emilia-filters`](./42-emilia-filters/README.md) | appended (minor) | the literal blur ladder (`xs 4px … 3xl 64px`); the resolved single-declaration / leading-zero acceptance bullets (superseded by the `--tw-*` form); blast radius; renames (`BackdropFilter`→`Backdrop`, `Grayscale.Full`→`.100`). `filters-example-1.0.8.bp` |
| `1.0.8-beta/09-emilia-tables` | [`43-emilia-tables`](./43-emilia-tables/README.md) | appended | the `16` step on all three spacing axes; old `BorderCollapse`/`CaptionSide`/`__N` spellings; resolved-`rem` acceptance values; blast radius; 9 old test names. `tables-example-1.0.8.bp` |
| `1.0.8-beta/10-emilia-transitions` | [`44-emilia-transitions`](./44-emilia-transitions/README.md) | appended | the easing literals (`--ease-in: cubic-bezier(0.4, 0, 1, 1)` …); `Default`→`Base` rename; resolved acceptance values; the keyframes-in-flush note; blast radius; 10 old test names. `transitions-example-1.0.8.bp` |
| `1.0.8-beta/11-emilia-transforms` | [`45-emilia-transforms`](./45-emilia-transforms/README.md) | appended | rotate steps `2,3,6,12` and `Neg {2,3,6}`; translate steps `2,4,8,16` and the whole `NegTranslateX/Y` family; v3 `transform:rotate(45deg)`-style acceptance (superseded); blast radius; 12 old test names. `transforms-example-1.0.8.bp` |
| `1.0.8-beta/12-emilia-interactivity` | [`46-emilia-interactivity`](./46-emilia-interactivity/README.md) | appended | **`accent-auto` → `accent-color:auto`** (a real Tailwind utility the payload-only `InteractAccent` cannot express — two candidate spellings recorded, token block untouched); the `16` step on scroll-margin/padding; old palette-leaf `AccentColor`/`CaretColor` sections; hex acceptance values; blast radius; 13 old test names. `interactivity-example-1.0.8.bp` |
| `1.0.8-beta/13-emilia-svg-accessibility` | [`47-emilia-svg-accessibility`](./47-emilia-svg-accessibility/README.md) | appended | **the two `sr-only` / `not-sr-only` declaration bodies** (the 1.0.10 copy gates them on an upstream read and prints none); old palette-leaf `Fill`/`Stroke` sections; `currentColor` spelling; hex acceptance values; blast radius; 10 old test names. `svg-a11y-example-1.0.8.bp` |
| `1.0.7-beta/15-emilia-attributes` | [`48-emilia-attributes`](./48-emilia-attributes/README.md) | appended | the `#[emilia([...])]` decorator expansion, multi-annotation composition (`class="e_abc123 e_def456"`), conditional tokens (`if (isActive) .Text.Bold` — does not parse, bare `if` needs `else`), the two old test names, the `fix/emilia-attributes` gate; all recorded as the rejected 1.0.7 design (no expression-position decorator; `html.bp` frozen). No examples existed |
| `1.0.7-beta/16-emilia-jhonstart-integration` | [`48-emilia-attributes`](./48-emilia-attributes/README.md) | appended | the `[emilia]={…}` DSL expansion and its example, the generic `[name]={expr}` handler registry (`registerEmiliaHandler`), the `fix/emilia-jhonstart-integration` gate, the data/ARIA-handler note (already covered by `bracketPair` for any name). No examples existed |

Every one of the seventeen old fronts owed something; none was fully covered as merged. Twelve of
the fifteen 1.0.8 examples had a same-named 1.0.10 file that differed (every one at byte 5, line 1
— the header comment) and were carried with the `-1.0.8` suffix; two (33, 35) had no same-named
file and kept their names; the 1.0.7 fronts had no examples.

## Documents

| Old path | New path | Verdict |
|---|---|---|
| `1.0.8-beta/overview.md` (§ Order, § Regras do Milestone, § Mapeamento) | [`reference-coverage.md`](./reference-coverage.md) § *Ordering, carried from the drafts* | the four phases, the three foundation reasons, the critical path and the milestone rules carried; the coverage-percentage table superseded by the walk |
| `1.0.8-beta/fronts.md` (ownership table, 15 × 15 conflict matrix, rules for a front) | [`reference-coverage.md`](./reference-coverage.md) § *The shared files* and [`modules.md`](./modules.md) § *The `tokens.bp` problem* | the matrix reduced to the banner rule it footnoted; ownership re-stated per `modules/emilia/src/utilities/<front>.bp` |
| `1.0.8-beta/tailwind-mapping.md` | [`tailwind-mapping.md`](./tailwind-mapping.md) | verbatim, with a one-line provenance note; its 1.0.8 status glyphs left as authored |
| `1.0.8-beta/closure.md` (never written; on disk today as an untracked pointer to this directory) | [`reference-coverage.md`](./reference-coverage.md) | the Tailwind v4 walk, 267 rows |
| `1.0.9-beta/fronts.md` § Track D | [`modules.md`](./modules.md), [`reference-coverage.md`](./reference-coverage.md) | the ownership table and the shared-file rule carried verbatim; the `test/` column realised as `modules/emilia/test/<front>_test.bp` |
| `1.0.9-beta/overview.md` § Track D | [`README.md`](./README.md) | the 22 rows re-ordered by level with submodule and dependency columns |
| `1.0.9-beta/tracks/README.md` | this directory | the five per-track files it promised for D (`modules`, `reference-coverage`, `test-snap`, `test-snap-examples`, plus `unification`, which D lacked in the 1.0.9 table) |
| `1.0.9-beta/33 … 48, 54 … 59` | `./NN-<same name>/` | verbatim copies; links `../contracts.md` → `../../contracts.md`, `../language-gaps.md` → `../../language-gaps.md`; sibling links unchanged |

## What the merge still misses

The coverage walk's non-covered rows are in [`reference-coverage.md`](./reference-coverage.md)
§ *Missing and partial rows, consolidated*. The items surfaced by this unification that no front
owns yet, or that two fronts state differently:

| Item | Fronts | Resolution proposed here |
|---|---|---|
| Nobody composes the per-front theme entries (`paletteEntries()`, 38's weight/tracking/leading, 41's inset/text shadows, 42's blur/drop-shadow, 44's ease, 45's perspective) into the default document; `defaultOptions()` carries `defaultTheme()`, which is palette-free, so a default flush references `var(--color-red-500)` and never defines it | 33 · 38 · 41 · 42 · 44 · 45 · 54 · 56 | `fullTheme()` in `emilia.bp`, owned by 56, one `extend` line per contributing front under its banner; `defaultOptions()` carries it — [`modules.md`](./modules.md) |
| `Important(inner)` — 56 says "front 34's `Important(inner)` modifier is one line on top of `markImportant`"; 34 never declares it | 34 · 56 | one top-level variant and one `variants.bp` fn in 34; unplaced until 34 takes it |
| `accent-auto` (`accent-color:auto`) has no token — the 1.0.8 draft had it as a section leaf, 1.0.10 made accent a payload variant | 46 | a nullary `Interact.Accent.Auto` leaf beside the payload variant (carried section records both spellings) |
| Dark mode by class / attribute: 54 ships `DarkMode.Class`/`Attribute` and says 34 builds the variant; 34 Step 3 declares those forms out of scope | 34 · 54 | 34's `darkVariant(th)` reads `darkAtRule(th)`/`darkSelector(th)`; the snapshot `css: modifiers ---- dark inside md inside hover` is written for `Media` and a second one is owed for `Class("dark")` |
| Breakpoint fns in 34 return literal queries and take no `Theme`, so `--breakpoint-*` overrides are inert | 34 · 54 | `smVariant(th)` … read `themeValue(th, "--breakpoint-sm")`; 58 already does this for containers |
| 42's tables print single-declaration bodies (`filter:brightness(.5)`) while its mechanism and acceptance pin the two-declaration `--tw-*` + `filter:var(--tw-filter)` form | 42 | the snapshots follow the acceptance form; the tables are stale |
| 41's test plan asserts `startsWith("box-shadow:0 4px")` against its own no-`rgb(` acceptance | 41 | the snapshots follow the acceptance (`box-shadow:var(--shadow-md)`) |
| 55's and 59's examples assert `background:#ffffff` / `color:#ffffff` (the pre-33 spelling); 48's example calls `styled(tokens)` without the `th: Theme` the README mandates | 48 · 55 · 59 | examples are code, not contract; the snapshots use 33's `var(--color-*)` and 48's two-argument form |
| `sr-only`/`not-sr-only` bodies and the four keyframe bodies are gated on an upstream read | 44 · 47 | the 1.0.8 bodies (carried) and upstream `theme.css`'s are the snapshot content; regenerated by hand if the read disagrees |
| `skew-x:3deg` transcribed from the reference is not a CSS property | 45 | the front's own flag stands; the snapshot line is marked for hand regeneration |
