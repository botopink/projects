# Track D — emilia

**Track:** D — emilia · **Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 docs (`/home/ericfillipe/develop/tailwindcss/TAILWIND_CSS_DOCS.md`, v4.3)

Type-safe CSS: a `Token` enum resolved through a theme and emitted through a rule model as a layered
`<style>` document. Twenty-two fronts, all landed; **five boxes remain open**, all at seams owned
elsewhere — see [`unification.md`](./unification.md).
Target: comptime — compiled and tested on both `commonJS` and `erlang`; front 48's class name is the
one output both halves of an app read.

| File | Holds |
|---|---|
| [`modules.md`](./modules.md) | the package cut — `emilia` · `emilia-test`, the file layout, the `tokens.bp` rule, ownership, examples |
| [`reference-coverage.md`](./reference-coverage.md) | the Tailwind v4 walk against the 22 fronts |
| [`unification.md`](./unification.md) | the cross-front seams, how each is settled, and the open boxes |
| [`tailwind-mapping.md`](./tailwind-mapping.md) | the utility → token mapping |
| [`test-snap.md`](./test-snap.md) | the snapshot-test map of the modules |
| [`test-snap-examples.md`](./test-snap-examples.md) | the snapshot-test map of `examples/**` |

User-facing reference: `repository/emilia/docs.md`; maintainer notes: `repository/emilia/AGENTS.md`.

## The fronts, in dependency order

Level = distance from the root of the track's dependency graph (`Depends on` lines, as in
[`../fronts.md`](../fronts.md)). Every front's code is a banner-fenced block in
`modules/emilia/src/tokens.bp` and `emilia.bp`, plus the module file named below where it has one.

| # | Front | Priority | Level | Code | Depends on | Open |
|---|---|---|---|---|---|---|
| 54 | [emilia-theme](./54-emilia-theme/README.md) | **critical** | 0 | `theme.bp`, `spacing.bp` | — | 1 |
| 56 | [emilia-cascade-and-output](./56-emilia-cascade-and-output/README.md) | high | 1 | `output.bp`; cells, entry points, `fullTheme`, `tokenToSheet` in `emilia.bp` | 54 | 1 |
| 33 | [emilia-color-palette](./33-emilia-color-palette/README.md) | **critical** | 2 | banner blocks | 54 · 56 | — |
| 34 | [emilia-modifiers](./34-emilia-modifiers/README.md) | **critical** | 2 | banner blocks | 54 · 56 | — |
| 35 | [emilia-spacing-sizing](./35-emilia-spacing-sizing/README.md) | **critical** | 2 | banner blocks | 54 · 56 | — |
| 55 | [emilia-preflight](./55-emilia-preflight/README.md) | high | 2 | `preflight.bp` | 56 | — |
| 57 | [emilia-escape-hatches](./57-emilia-escape-hatches/README.md) | high | 2 | `arbitrary.bp` | 54 · 56 | — |
| 58 | [emilia-container-queries](./58-emilia-container-queries/README.md) | medium | 2 | `container.bp` | 54 · 56 | — |
| 36 | [emilia-layout](./36-emilia-layout/README.md) | high | 3 | banner blocks | 54 · 56 · 33 | — |
| 37 | [emilia-grid](./37-emilia-grid/README.md) | high | 3 | banner blocks | 54 · 56 | — |
| 38 | [emilia-typography](./38-emilia-typography/README.md) | high | 3 | banner blocks | 54 · 56 · 33 | — |
| 39 | [emilia-backgrounds](./39-emilia-backgrounds/README.md) | high | 3 | banner blocks | 33 · 54 · 56 | — |
| 40 | [emilia-borders](./40-emilia-borders/README.md) | high | 3 | banner blocks | 33 · 54 · 56 | — |
| 41 | [emilia-effects](./41-emilia-effects/README.md) | high | 3 | banner blocks | 33 · 34 | — |
| 42 | [emilia-filters](./42-emilia-filters/README.md) | medium | 3 | banner blocks | — (arm order after 33 · 34 · 35) | — |
| 43 | [emilia-tables](./43-emilia-tables/README.md) | low | 3 | banner blocks | 35 | — |
| 44 | [emilia-transitions](./44-emilia-transitions/README.md) | high | 3 | banner blocks | 34 | — |
| 45 | [emilia-transforms](./45-emilia-transforms/README.md) | medium | 3 | banner blocks | 44 | — |
| 46 | [emilia-interactivity](./46-emilia-interactivity/README.md) | medium | 3 | banner blocks | 33 | — |
| 47 | [emilia-svg-accessibility](./47-emilia-svg-accessibility/README.md) | low | 3 | banner blocks | 33 | — |
| 59 | [emilia-custom-utilities-and-variants](./59-emilia-custom-utilities-and-variants/README.md) | medium-high | 3 | `compose.bp`; `named` in `emilia.bp` | 34 · 56 | — |
| 48 | [emilia-attributes](./48-emilia-attributes/README.md) | high | 3 | `attributes.bp`; the slot fns in `emilia.bp`; `repository/jhonstart/modules/jhonstart/src/html_attrs.bp` (emilia-unaware) | [26](../04-jhonstart/26-jhonstart-router/README.md) · 33–47 | 3 |

54 is the root because every value ladder resolves through `spacing(n)` and the theme; 56 comes next
because every front emits through its rule model (`group-*`, `peer-*`, `space-*`, `divide-*`,
`@keyframes`, `@container` and `@layer` all need a selector or an at-rule outside the class body).

Track D needs nothing from tracks A, B, C or E. Its contacts are outbound: front 48's
`html_attrs.bp`, written into jhonstart's tree and emilia-unaware; the `jhonstart-emilia` bridge
(jhonstart [30](../04-jhonstart/30-jhonstart-streaming/README.md)) reading `flush` / `flushWith`,
whose test is where a rendered page and emilia's class meet; and onze
[68](../06-onze/68-onze-client-bundle/README.md) reading the contract 4 literal through `styleRule`.
emilia imports nobody and carries no dependency, dev-dependency included, on another library: every
emilia example and test produces CSS and asserts the string, and an example that renders styled HTML
is an onze example (decisions 113 and 114).

## Dependency graph

```
L0   54 theme ─────────────────────────────────────────────────────────────┐
      │                                                                    │
L1   56 cascade-and-output                                                 │
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

Outbound:  48 ──► html_attrs.bp in jhonstart's tree (emilia-unaware)      56 ──► jhonstart-emilia (flush/flushWith)   48/56 ──► onze 68 (styleRule, class literal)
```

## Numbering

Front numbers are identifiers, not positions: 33–48 are the sixteen utility fronts; 54–59 are the six
CSS-authored fronts (theme, reset, cascade, escape hatches, container queries, custom utilities).
49–53 between them are onze, not gaps.
