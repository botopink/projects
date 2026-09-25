# Track D — emilia

**Track:** D — emilia · **Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 docs (`/home/ericfillipe/develop/tailwindcss/TAILWIND_CSS_DOCS.md`, v4.3)

Type-safe CSS: a `Token` enum walked at comptime, resolved through a theme, emitted through a rule
model as a layered document. Twenty-two fronts.
Target: comptime — compiled and tested on both `commonJS` and `erlang`; front 48 is the one front
whose output both halves of an app read.

| File | Holds |
|---|---|
| [`modules.md`](./modules.md) | the package cut — `emilia` · `emilia-test` (the domain candidates and `emilia-jhonstart` evaluated and dropped), the `tokens.bp` resolution, ownership, examples |
| [`reference-coverage.md`](./reference-coverage.md) | the Tailwind v4 walk against the 22 fronts; ordering and the shared-file rule |
| [`unification.md`](./unification.md) | what no front owns yet, or two fronts state differently |
| [`tailwind-mapping.md`](./tailwind-mapping.md) | the utility → token mapping |
| [`test-snap.md`](./test-snap.md) | the snapshot-test map of the modules |
| [`test-snap-examples.md`](./test-snap-examples.md) | the snapshot-test map of `examples/**` |

## The fronts, in blocking order

Level = distance from the root of the track's dependency graph; a front sits one level below
everything it consumes (`Depends on` lines, unannotated edges only — as in [`../fronts.md`](../fronts.md)).
Fronts on one level may run in parallel; the two shared files are fenced per
[`modules.md`](./modules.md).

| # | Front | Priority | Level | Submodule | Depends on |
|---|---|---|---|---|---|
| 54 | [emilia-theme](./54-emilia-theme/README.md) | **critical** | 0 | `emilia` (`theme.bp`, `spacing.bp`) | — |
| 56 | [emilia-cascade-and-output](./56-emilia-cascade-and-output/README.md) | high | 1 | `emilia` (`output.bp`, `emilia.bp`) + `emilia-test` | 54 |
| 33 | [emilia-color-palette](./33-emilia-color-palette/README.md) | **critical** | 2 | `emilia` (`utilities/color.bp`) | 54 · 56 |
| 34 | [emilia-modifiers](./34-emilia-modifiers/README.md) | **critical** | 2 | `emilia` (`variants.bp`) | 54 · 56 |
| 35 | [emilia-spacing-sizing](./35-emilia-spacing-sizing/README.md) | **critical** | 2 | `emilia` (`utilities/spacing_sizing.bp`) | 54 · 56 |
| 55 | [emilia-preflight](./55-emilia-preflight/README.md) | high | 2 | `emilia` (`preflight.bp`) | 56 |
| 57 | [emilia-escape-hatches](./57-emilia-escape-hatches/README.md) | high | 2 | `emilia` (`arbitrary.bp`) | 54 · 56 |
| 58 | [emilia-container-queries](./58-emilia-container-queries/README.md) | medium | 2 | `emilia` (`container.bp`) | 54 · 56 |
| 36 | [emilia-layout](./36-emilia-layout/README.md) | high | 3 | `emilia` (`utilities/layout.bp`) | 54 · 56 · 33 |
| 37 | [emilia-grid](./37-emilia-grid/README.md) | high | 3 | `emilia` (`utilities/grid.bp`) | 54 · 56 |
| 38 | [emilia-typography](./38-emilia-typography/README.md) | high | 3 | `emilia` (`utilities/typography.bp`) | 54 · 56 · 33 |
| 39 | [emilia-backgrounds](./39-emilia-backgrounds/README.md) | high | 3 | `emilia` (`utilities/backgrounds.bp`) | 33 · 54 · 56 |
| 40 | [emilia-borders](./40-emilia-borders/README.md) | high | 3 | `emilia` (`utilities/borders.bp`) | 33 · 54 · 56 |
| 41 | [emilia-effects](./41-emilia-effects/README.md) | high | 3 | `emilia` (`utilities/effects.bp`) | 33 · 34 |
| 42 | [emilia-filters](./42-emilia-filters/README.md) | medium | 3 | `emilia` (`utilities/filters.bp`) | — (arm order after 33 · 34 · 35) |
| 43 | [emilia-tables](./43-emilia-tables/README.md) | low | 3 | `emilia` (`utilities/tables.bp`) | 35 |
| 44 | [emilia-transitions](./44-emilia-transitions/README.md) | high | 3 | `emilia` (`utilities/transitions.bp`) | 34 |
| 45 | [emilia-transforms](./45-emilia-transforms/README.md) | medium | 3 | `emilia` (`utilities/transforms.bp`) | 44 (token existence; lands after 44 inside the level) |
| 46 | [emilia-interactivity](./46-emilia-interactivity/README.md) | medium | 3 | `emilia` (`utilities/interactivity.bp`) | 33 |
| 47 | [emilia-svg-accessibility](./47-emilia-svg-accessibility/README.md) | low | 3 | `emilia` (`utilities/svg_a11y.bp`) | 33 |
| 59 | [emilia-custom-utilities-and-variants](./59-emilia-custom-utilities-and-variants/README.md) | medium-high | 3 | `emilia` (`compose.bp`) | 34 · 56 |
| 48 | [emilia-attributes](./48-emilia-attributes/README.md) | high | 3 | `emilia` (`attributes.bp`, `html_hook.bp`; `jhonstart` dev-only for the integration test) + `repository/jhonstart/src/html_attrs.bp` | [26](../04-jhonstart/26-jhonstart-router/README.md) · 33–47 (the slot is token-agnostic; the tokens are what it carries) |

Why 54 and 56 are first: 54 *because four copies of the spacing ladder already
exist in `emilia.bp` and have already drifted; every front admitted after it would add a fifth*;
56 *because the shape emilia emits today cannot express `@media` beside `@layer`, cannot hold
`@keyframes`, and cannot carry `group-*`, `peer-*`, `rtl`, `space-*` or `divide-*` — fronts 34, 40,
44, 55 and 58 all emit through it, and building them first means building them twice*. Within level
0/1, 54 lands before 56: `Options.theme` is a `Theme` and `defaultOptions()` calls `defaultTheme()`.

Track D needs nothing from tracks A, B, C or E to start: no socket, no clock, no filesystem. Its
only contacts are outbound — front 48 into jhonstart, and onze [69](../06-onze/69-onze-styling-pipeline/README.md)
/ [68](../06-onze/68-onze-client-bundle/README.md) reading `flushWith` and the contract 4 literal.

## Dependency graph

```
L0   54 theme ─────────────────────────────────────────────────────────────┐
      │                                                                    │
L1   56 cascade-and-output  (+ emilia-test helpers)                         │
      │                                                                    │
      ├──────────┬──────────┬──────────┬──────────┬──────────┐             │
L2   33 palette  34 modifiers  35 spacing  55 preflight  57 escape  58 container
      │  │  │  │   │   │   │    │                                          │
      │  │  │  │   │   │   │    └── 43 tables                              │
      │  │  │  │   │   │   └─────── 59 compose                             │
      │  │  │  │   │   └─────────── 44 transitions ── 45 transforms        │
      │  │  │  │   └─────────────── 41 effects  ◄──── 33                   │
      │  │  │  └── 36 layout                                               │
L3    │  │  └───── 38 typography      37 grid ◄── 54 · 56                   │
      │  └──────── 39 backgrounds     42 filters (no edge; arm order)       │
      └─────────── 40 borders · 46 interactivity · 47 svg-a11y             │
                                                                           │
L3   48 attributes ◄── jhonstart 26 (router gate) · the tokens of 33–47 ◄──┘

Outbound:  48 ──► jhonstart (html_attrs.bp)      56 ──► onze 69 (flushWith)   48 ──► onze 68 (class literal)
```

## Numbering

Front numbers are identifiers, not positions: 33–48 are the sixteen utility fronts; 54–59 are the six
CSS-authored fronts (theme, reset, cascade, escape hatches, container queries, custom utilities).
49–53 between them are onze, not gaps. [`unification.md`](./unification.md) records what no front
owns yet.
