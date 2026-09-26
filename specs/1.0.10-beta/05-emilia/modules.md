# Modules — the `emilia` package cut

**Track:** D — emilia · **Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 (`TAILWIND_CSS_DOCS.md`)

The granularity of `repository/emilia/modules/**` and `repository/emilia/examples/**`, the dependency
graph, the target, what `emilia-test` is for, and the front → code ownership that
[`README.md`](./README.md) copies.

## Verdict

Two members — front [95](../02-packaging/95-ecosystem-package-restructure/README.md)'s cut: one core
package with the theme, preflight and utilities as files inside it, as Tailwind ships `theme.css`,
`preflight.css` and `utilities.css` inside one `tailwindcss` package. A per-domain package would
make core depend on it and it on core's `Token` — a cycle — and the payload variants must live in
the file that declares `Token`.

| Member | Holds | Target | Depends on |
|---|---|---|---|
| **`emilia`** (core) | the `Token` enum, theme, spacing, the rule model and renderer, the variant table, the sixteen utility dispatchers, preflight, escape hatches, container queries, compose, the class slot | comptime — compiled and tested on **both** `commonJS` and `erlang`; a string that differs by backend is a defect | `std` only — no other library, dev-dependency included (decision 114) |
| **`emilia-test`** | the snapshot helpers of [`test-snap.md`](./test-snap.md) | as core | `emilia`, `std` (`testing.asserts`, `testing.snapshots`) |

## The tree

```
repository/emilia/
├── botopink.json            workspace: "workspaces": ["modules/*", "examples/*"], targets commonJS + erlang
├── AGENTS.md · docs.md · README.md · CHANGELOG.md
├── modules/
│   ├── emilia/
│   │   ├── botopink.json    files: root, tokens, theme, spacing, output, preflight, arbitrary,
│   │   │                    container, compose, attributes, emilia
│   │   └── src/
│   │       ├── root.bp          pub mod lines; `pub default mod emilia`
│   │       ├── tokens.bp        the one `Token` enum, one banner block per front          (33–47 · 34 · 57 · 58)
│   │       ├── theme.bp         Theme, Ns, DarkMode, defaultTheme, extendTheme, themeValue… (54)
│   │       ├── spacing.bp       spacing(n), spacingHalf(n)                                (54)
│   │       ├── output.bp        Rule, Block, Sheet, Variant, Options, codec, renderer — pure (56)
│   │       ├── preflight.bp     preflightRules(), preflight()                             (55)
│   │       ├── arbitrary.bp     validators, arb* builders, arb*ToSheet helpers             (57)
│   │       ├── container.bp     ContainerSize, containerAt*, containerNamed, containerName (58)
│   │       ├── compose.bp       scrollbarHidden, compose, hocus, selector, themeMidnight  (59)
│   │       ├── attributes.bp    mergeClass, nonAsciiIn, contract 4's docblock             (48)
│   │       └── emilia.bp        host cells · emilia/emiliaWith/styleRule/flush/flushWith ·
│   │                            fullTheme/fullOptions · tokenToSheet · named (59) · the class-slot
│   │                            fns (48) · one banner-fenced dispatcher block per utility front
│   └── emilia-test/
│       ├── botopink.json    dependencies: { "emilia": { "workspace": true } }
│       └── src/root.bp      a resolve test; the helpers are not written yet
└── examples/                emilia-backgrounds · -borders · -card · -cascade · -effects · -grid · -layout ·
                             -modifiers · -outline-ring · -spacing · -text-decoration · -theme ·
                             -transforms · -transitions · -typography
```

- **Banner blocks, not per-front files.** Every utility front's code is a block fenced
  `// ── front NN — <domain> ──` … `// ── end front NN ──` in `tokens.bp` and in `emilia.bp`, with its
  tests inline (`test {}` beside the code). A file split would be its own front, across the whole
  file at once.
- **`tokens.bp` stays one file** — `Token` is one declaration and a section is not declarable
  elsewhere. Each front appends one contiguous block; the exhaustive `case` in `tokenToSheet` is the
  guard (a section without an arm, or an arm without a section, reds the build).
- **The host cells stay in `emilia.bp`**: a cross-module bare import of an `#[@External.…]`
  declaration is `undefined` at run time. For the same reason — and because a sibling module cannot
  import `emilia.bp` — `named` (59) and the slot functions `className`, `styled`, `styledWith`,
  `cls`, `clsWith`, `assertAsciiBody` (48) live in `emilia.bp`; their pure halves live in
  `compose.bp` and `attributes.bp`.
- `root.bp`, `botopink.json` and `tokens.bp` follow one rule: append in front-number order, never
  edit another front's line.
- The one file outside the repo: `repository/jhonstart/modules/jhonstart/src/html_attrs.bp`
  (`classAttr`, `withAttrs`, `attrValue`), front 48's, importing only jhonstart's `element`.

## Dependency graph

```
              std ────────────────────────────┐
               │                              │
               ▼                              ▼
            emilia  ◄──── emilia-test
           (core)
             ▲  ▲
             │  ├── jhonstart-emilia (flush/flushWith; its test renders a page and asserts the contract 4 literal)
             │  └── onze 69 (flushWith)
             └───── onze 68 (styleRule at build time; contract 4 literal)

Inside core, by file (arrows = imports):
  theme.bp, spacing.bp, tokens.bp, attributes.bp   import nothing
  output.bp     ──► theme
  preflight.bp  ──► output, theme
  arbitrary.bp  ──► tokens, output
  container.bp  ──► tokens, theme, output, arbitrary
  compose.bp    ──► tokens, output, arbitrary
  emilia.bp     ──► tokens, theme, spacing, output, arbitrary, container, compose, preflight, attributes
```

No cycle: `emilia.bp` is imported by no sibling.

## Target

`emilia` runs at comptime and emits strings. It sits nowhere on the erlang/js axis
([overview](../overview.md) *Which target runs what*) and is compiled and tested on both targets;
its only state — the per-render stylesheet cell — is a `Map` on `globalThis` in commonJS and a
process-dictionary list in erlang, behind one contract. Front 48's class name is the one output both
halves of an application read: the server render (jhonstart
[30](../04-jhonstart/30-jhonstart-streaming/README.md), erlang) writes it, the client bundle (onze
[68](../06-onze/68-onze-client-bundle/README.md), js) recomputes it; contract 4's fixture
(`e_39b87d03`) asserts the same literal on both.

## What `emilia-test` is for

The helpers [`test-snap.md`](./test-snap.md) specifies — `assertCss`, `assertCssWith`,
`assertUtility`, `assertVariant`, `assertTheme`, `assertRules`, `assertCascade`, `assertClassName`,
each `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void, string>` writing a `.snap`
shared by both targets (`snapshots.path(loc)`, a `.new` on mismatch, no update flag; see
[`../01-std/snapshots.md`](../01-std/snapshots.md)). **Not written yet:** the member holds a resolve
test, and the fronts landed with inline string asserts instead of snapshot files. The snapshot suite
of `test-snap.md` / `test-snap-examples.md` is remaining track-D work with no front assigned.

Refusals (a `Variant` with two `&`, `extendTheme` with an unknown prefix, `arbValue` with `}`) are
build failures, not values a helper can read; they belong in the compiler's suite.

## Front → code ownership

| Front | Module file | Shared-file blocks |
|---|---|---|
| 54 theme | `theme.bp`, `spacing.bp` | `root.bp` + `botopink.json` lines |
| 56 cascade-and-output | `output.bp` | `emilia.bp`: cells, entry points, `fullTheme`/`fullOptions`, `tokenToSheet` shell; `root.bp` + `botopink.json` |
| 33 color-palette | — | `tokens.bp` (`Color`, `Bg.Color`, `Alpha`); `emilia.bp` block + `fullTheme` line |
| 34 modifiers | — | `tokens.bp` (modifier variants, closing the enum); `emilia.bp` block (the `Variant` fns and the modifier arms) |
| 35 spacing-sizing | — | `tokens.bp` (`Pad`, `Margin`, `Size`, `Space`); `emilia.bp` block |
| 36 layout | — | `tokens.bp` (`Layout`); `emilia.bp` block |
| 37 grid | — | `tokens.bp` (`Flex`, `Grid`, `Gap`); `emilia.bp` block |
| 38 typography | — | `tokens.bp` (`Text`, `Font`, `List`); `emilia.bp` block + `fullTheme` line |
| 39 backgrounds | — | `tokens.bp` (`Bg` non-colour, `Gradient`); `emilia.bp` block |
| 40 borders | — | `tokens.bp` (`Border`, `Outline`, `Ring`, `Divide`); `emilia.bp` block |
| 41 effects | — | `tokens.bp` (`Effect`, `Blend`, `Mask` + 3 payload variants); `emilia.bp` block + `fullTheme` line |
| 42 filters | — | `tokens.bp` (`Filter`, `BackdropFilter` + 2 payload variants); `emilia.bp` block + `fullTheme` line |
| 43 tables | — | `tokens.bp` (`Table` + 1 payload variant); `emilia.bp` block |
| 44 transitions | — | `tokens.bp` (`Transition`, `Animate` + 2 payload variants); `emilia.bp` block + `fullTheme` line |
| 45 transforms | — | `tokens.bp` (`Transform` + 2 payload variants); `emilia.bp` block + `fullTheme` line |
| 46 interactivity | — | `tokens.bp` (`Interact` + 3 payload variants); `emilia.bp` block |
| 47 svg-accessibility | — | `tokens.bp` (`Svg`, `A11y` + 3 payload variants); `emilia.bp` block |
| 55 preflight | `preflight.bp` | `root.bp` + `botopink.json` |
| 57 escape-hatches | `arbitrary.bp` | `tokens.bp` (six top-level variants); `emilia.bp` (six arms); `root.bp` + `botopink.json` |
| 58 container-queries | `container.bp` | `tokens.bp` (`Container` + three top-level variants); `emilia.bp` (four arms); `root.bp` + `botopink.json` |
| 59 custom-utilities-and-variants | `compose.bp` | `emilia.bp` (`named`); `root.bp` + `botopink.json` |
| 48 attributes | `attributes.bp`; jhonstart's `html_attrs.bp` (emilia-unaware) | `emilia.bp` (the slot fns); `root.bp` + `botopink.json` |

`emilia-test` has no front of its own; its helpers are the snapshot suite's first step.
[Contract 4](../contracts.md) names `mergeClass` at `modules/emilia/src/attributes.bp`.

## Relation to `jhonstart` and `onze`

| Neighbour | Front | What crosses | Direction |
|---|---|---|---|
| jhonstart | 48 | `styled(tokens, th)` returns the `#("class", …)` pair a builder's `attrs` takes; `cls(tokens, th)` the string a pre-bound `[class]={…}` hole takes (a hole may not contain a space); `html_attrs.bp` is the one cross-repo file | none at package level: jhonstart never imports emilia, emilia imports jhonstart nowhere |
| jhonstart | [94](../04-jhonstart/94-jhonstart-element-surface/README.md) | the element constructors' `attrs` array the slot writes into; attribute order is class identity (contract 4 clause 5) | read-only |
| jhonstart | [30](../04-jhonstart/30-jhonstart-streaming/README.md) | the `jhonstart-emilia` bridge implements jhonstart's asynchronous `RenderPlugin` by awaiting `flush() -> @Task<string>` / `flushWith(o)`: the head's `<style>` once, each streamed boundary's `<style>` inside its fill, and `payload()` answering `#("s", <the class names it flushed>)`; the client bundle never calls `flush()` (contract 6a, decisions 113 and 114). The bridge's test is the one that renders a page with emilia's classes and asserts the contract 4 literal | `jhonstart-emilia` → `emilia` |
| onze | [69](../06-onze/69-onze-styling-pipeline/README.md) | registers the bridge's plugin at boot; the stylesheet records of the manifest | `onze` → `jhonstart-emilia` |
| onze | [68](../06-onze/68-onze-client-bundle/README.md) | at build time the bundler calls `styleRule(tokens, th)` for every client `emilia(...)` call to fill its `styleMap`, and asserts the contract 4 literal; onze imports emilia directly (decisions 113, 116) | `onze` → `emilia` |

emilia never imports `jhonstart`, `rakun` or `onze`, dev-only included. Its class-name hash is the
djb2 fold std's `hash.contentHash` implements (decision 116; the switch from emilia's own `hashHex`
is front 56's open box), the same function onze 68's parity check runs.

## `repository/emilia/examples/**`

Each example is a workspace member (`botopink.json` + `src/main.bp`, inline tests) built under the
examples gate. The fifteen that exist are per-front worked examples (named in each front's README
and in `docs.md`). Remaining work, unowned:

- `emilia-card` still depends on jhonstart and targets commonJS only; decision 114 makes it an
  emilia-only example that prints its class names and flushed sheet, on both targets.
- [`test-snap-examples.md`](./test-snap-examples.md) maps nine cross-front snapshot examples
  (`theme-brand`, `dashboard-layout`, `typography-article`, `interactive-button`, `dark-mode-nav`,
  `media-gallery`, `arbitrary-and-compose`, `class-attributes`, and `emilia-card`); only
  `emilia-card` exists. A page that renders emilia's classes into HTML is an onze example
  ([front 53](../06-onze/53-onze-example-app/README.md)).
