# Front 34 — emilia source tail: std's hash, five families at upstream parity, the breakpoint refusal (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56)

**Priority:** high — step 2 moves output every later snapshot (`20-snap` step 4) would otherwise
record twice · **State:** step 1 done; steps 2–4 wait on 05emilia-l / -e / -n, steps 3 and 5 on `08-bpp/119` step 1
**Depends on:** `05emilia-l` confirmed (step 2's rule) · `05emilia-e` (step 3's base theme — open
again with 300) · `05emilia-n` (step 4, the four feature rows only) · `08-bpp/119` step 1 (steps 3
and 5: the repositories `css` and `styled` — the theme mechanism and the components, decision 338).
Nothing else:
`hash.contentHash` exists; `08-bpp/118` step 1's bracket-attribute carve-out is comments only here,
reworded by step 1 (no code uses `[name]={`).
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; edited blocks named per step),
`modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (`20-snap`) · the other eleven examples' `src/main.bp` (none pins a moved
family; if one does, report to 33) · `repository/jhonstart/**` (`html_attrs.bp` is 48's, closed) ·
`.gitignore`, the hooks, `.github/` (`00-gate`) · `repository/css/**`, `repository/styled/**`
(`08-bpp/119` step 1)

## Goal

Class name is std's `hash.contentHash` (decision 116), contract-4 fixture `e_39b87d03` unchanged;
`modules/` names no other library (decision 114); five families render what Tailwind 4.3.2 renders;
the theme is typed and declared once with `#[theme]` — the mechanism `styled`'s, the Tailwind values
emilia's `defaultTheme()` —, a token naming a cleared breakpoint a compile error (decisions 300, 338);
the four unplaced feature rows declared or stated as deviations (05emilia-n); emilia is a series of
components built with `styled`, its families `styledProperty`s, its own sheet model gone (338).
`emilia`: 734 tests on both rows; the five families pinned by inline tests in their blocks and by
the four owned examples.

## Mechanism

- **The hash.** `hashHex` (`emilia.bp:95-97`: Node and Erlang templates of the djb2 fold, used in
  `styleRule` at `:114`) is what `hash.contentHash` implements (decision 116 chose it *because* it
  is emilia's). `import {hash} from "std"` in `emilia.bp`, `hash.contentHash(payload)` in
  `styleRule`, both templates deleted; the fixture proves equivalence. `output.bp:379-388`'s comment
  ("NEITHER OF THESE MAY USE `String.slice`") explains a commonJS prelude defect (C-37: a
  self-recursive `charCodeAt` patch) closed in the compiler (`01-compiler/04-js`,
  `run/string_char_code_after_slice` on four targets).
- **The families**, against Tailwind 4.3.2's compiled output:

| Family | emilia writes | upstream writes | Block |
|---|---|---|---|
| transition presets | `transition-timing-function:var(--ease-out);transition-duration:150ms` (`transitionPreset`, `emilia.bp:13053`; tests from `:13263`) | `…:var(--tw-ease, var(--default-transition-timing-function));…:var(--tw-duration, var(--default-transition-duration))` and sets `--tw-ease` / `--tw-duration` | 44 |
| `backdrop-opacity-*` | `opacity(0.5)` | `opacity(50%)` | 42 |
| backdrop filters | `backdrop-filter:…` | `-webkit-backdrop-filter:…;backdrop-filter:…` | 42 |
| `border-spacing-*` | `border-spacing:calc(…) 0` (`emilia.bp:313`, `:12805-12897`) | `--tw-border-spacing-x:…;--tw-border-spacing-y:…;border-spacing:var(--tw-border-spacing-x) var(--tw-border-spacing-y)` | 43 |
| `divide-*` | the width | `border-*-style:var(--tw-border-style);` beside the width | 40 |

  Each: one dispatcher arm in its block + the `@property` / theme entries the chain reads
  (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`; `fullTheme()`
  gains no entry — per-utility variables with `@property` registrations like the transform ones; no
  new `Ns` prefix — 05emilia-a, -d, -i stand). 05emilia-l: a family moves whole, one helper per
  shape. A token list using a moved family changes class-name hash (hash is over the sheet); the
  contract-4 fixture (padding / colour / hover) uses none and does not move. jhonstart and onze
  assert class names, not bodies.
- **The refusal.** Today a cleared `--breakpoint-*` (`extendTheme` with an empty value) silently
  emits `@media (width >= )`. Decision 300: a token naming a cleared or absent breakpoint is a compile
  error where the token list is comptime-known (a `#[styled(…)]` tag annotation's tokens always are,
  280/301); `theme.bp`'s breakpoint reader panics on an empty entry naming it, as `container.bp`'s
  does for an emptied `--container-*` (front 58), only for a list built at run time (step 3).
- **The unplaced rows:** [`reference-rows.md`](./reference-rows.md), category (c).

## Done

Step 1 `emilia.bp` imports `{hash} from "std"` and `styleRule` names the class
`"e_" + hash.contentHash(payload)`; the `hashHex` templates are gone and no file under
`modules/emilia/src` names it. std's fold is emilia's (djb2, seed 5381, 32-bit mask, unpadded
lowercase hex) over code points, and a class body is ASCII (`assertAsciiBody`), so every class name is
unchanged: contract-4 fixture `e_39b87d03` and `emilia-card`'s `e_486b0b4f` / `e_b63a108` /
`e_74f3ae56` pass unedited. `output.bp`'s `String.slice` comment is one line naming C-37 closed (the
`split("\t")` code stays); the cross-library and `[class]={…}` comments in `attributes.bp` and
`emilia.bp` state the shape without a neighbour or a template surface, and
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` is empty. `botopink test`: `emilia`
734 passed, 0 failed on commonJS and on erlang; `emilia-card` 4/0, `jhonstart-emilia` 10/0 and
`onze-cli` 31/0 on both.

## Open

### Step 2 — the five families to upstream's form (05emilia-l applied)

- [ ] `transition` / `transition-*` presets render upstream's `var(--tw-ease, …)` /
      `var(--tw-duration, …)` pair, set `--tw-ease` / `--tw-duration` with `@property`
      registrations; `rawTransitionProperty` takes the same pair
- [ ] `backdrop-opacity-50` is `opacity(50%)`; every backdrop utility writes
      `-webkit-backdrop-filter` before `backdrop-filter`
- [ ] `border-spacing-*` writes `--tw-border-spacing-x` / `-y` and the reader
- [ ] `divide-x-*` / `divide-y-*` write `border-*-style:var(--tw-border-style)` beside the width
- [ ] each moved arm's inline tests and the four examples' inline strings assert the new literal,
      measured against 4.3.2's output quoted in the test's comment; `docs.md` and its
      `tailwind-mapping` rows updated
- [ ] no other family's literal moves: `emilia` stays 734 or more, every unrelated test
      byte-identical (test-file diff shows only the five families)

### Step 3 — the theme: Tailwind's values over `styled`'s mechanism (decisions 300, 338; after `08-bpp/119` step 1)

The theme stays CSS's flat entry list, typed, declared once with `#[theme]` (300). Since 338 the
**mechanism** is `styled`'s — `Theme`, the namespaces, `entry`, `clear`, `clearNs`, `clearAll`,
`extendTheme`, the app's one `#[theme]` and the cleared-breakpoint refusal, built by `08-bpp/119`
step 1 —, and emilia keeps the **values**: `defaultTheme()`, Tailwind's palette, spacing,
breakpoints, radii (`theme.bp`'s nineteen namespaces and three reset forms).

```bp
import {defaultTheme} from "emilia";
import {theme, extendTheme, entry, clear} from "styled";

#[theme]
pub val appTheme = comptime extendTheme(defaultTheme(), [
    entry(.Breakpoint, "md", Rem(40.0)),       // was #("--breakpoint-md", "40rem")
    clear(.Breakpoint, "lg"),                  // was #("--breakpoint-lg", "")
]);
```
```bpp
<div #[styled(.Lg(.Pad.All.4))]>…</div>        // compile error: breakpoint lg was cleared in the theme
```

The base (`defaultTheme()` as 300 writes it, palette-free, against `fullTheme()`, which `flush()`
renders with) is `05emilia-e`, open — the boxes below do not settle it.

- [ ] `theme.bp` builds `defaultTheme()` (and `fullTheme()`) as a value of `styled`'s `Theme`; emilia's
      own `extendTheme`, `#("--…", "…")` pairs and `""`-as-clear leave its API
- [ ] a token's breakpoint, colour or spacing resolves through the app's `#[theme]` (`styled`'s), so a
      token naming a cleared or absent breakpoint (`Lg` after `clear(.Breakpoint, "lg")`) is refused at
      compile time when the token list is comptime-known (every `#[styled(…)]` annotation, 301, 338),
      naming the theme's line; the run-time refusal stays only for a list built at run time
- [ ] `reference-rows.md` § 3.3 "removing breakpoints" reads as a deviation in `docs.md`

### Step 4 — the unplaced rows (on `05emilia-n`, reduced to the four features; the refusal is step 3, 300)

(b): `TranslateX.Neg` / `TranslateY.Neg` in `tokens.bp` (`:2259-2279`) beside `Rotate.Neg`, with
05emilia-l's `calc(… * -1)` form; named groups and peers as `GroupNamed(name, inner)` /
`PeerNamed(name, inner)` payload variants (top-level, like every payload-carrying token) with
`.group\/<name>` / `.peer\/<name>` selectors. (c): also `@theme inline` as an `Options` field
resolving every `var(--x)` at render. (a), recommended: only `docs.md` § Deviations stating
`arbSel` as the spelling.

- [ ] under (b): `-translate-y-2` renders `--tw-translate-y:calc(var(--spacing) * -2)` and the
      composed `translate`; `group/item:hover` renders `.group\/item:hover .e_…`; both measured
      against 4.3.2
- [ ] under (a): the `docs.md` paragraph; `reference-rows.md` rows marked (b)
- [ ] `tokens.bp:2190-2195`'s comment states `Neg` as the decided form (decision 314), not a language gap;
      `TranslateX.Neg` / `TranslateY.Neg`, when (b) adds them, follow it

### Step 5 — emilia over `styled` (decision 338; after `08-bpp/119` step 1)

emilia is the third layer: `css` the base for building CSS, `styled` the base for building CSS
components, emilia a series of components built with `styled`, applied to a tag with
`jhonstart-styled`'s `#[styled(…)]` (`<h1 #[styled(.Text.Bold)]>`, 301 — the template side is
`08-bpp/119` step 4). emilia's own sheet model — `Rule`, `Sheet`, `Variant`, `renderRule`,
`renderDocument` (`output.bp:44-593`) and the per-render store `flush()` drains
(`emilia.bp:227-235`) — is what `css` and `styled` now hold. Each family is a `styledProperty`, the
ladder of `spacing.bp` becomes the literal's `--spacing()`, and a variant wraps declarations in a
`styled`:

```bp
import styled, {styledProperty, StyledView, StyledPropertyView, Styleable} from "styled";

// Tailwind: @utility p-*  { padding: --spacing(--value(integer)); }
fn padAll(n: i32) -> StyledPropertyView { return styledProperty "padding: --spacing(${n});"; }
// Tailwind: @utility px-* { padding-inline: --spacing(--value(integer)); }
fn padX(n: i32) -> StyledPropertyView { return styledProperty "padding-inline: --spacing(${n});"; }
fn padAllHalf(n: i32) -> StyledPropertyView { return styledProperty "padding: --spacing(${n}.5);"; }

fn hover(inner: StyledPropertyView) -> StyledView { return styled "&:hover { ${inner} }"; }

Token implement Styleable { fn toStyled(self: Self) -> StyledView { … } }   // each token → its component
```

emilia imports `styled` and std — no framework, no `.bpp`, no jhonstart (113, 338).

- [ ] every family's `*TokenToCss` / `oneDecl` / `axisDecl` string building replaced by
      `styledProperty "…"` components; `spacing.bp`'s `spacing` / `spacingHalf` / `spacingNegHalf`
      replaced by `--spacing(…)` in the literal; no CSS text assembled with `+`
- [ ] variants (`.Hover(…)`, `.Md(…)`, `.Dark(…)`, …) wrap their inner declarations in a `styled`;
      a token list is the composition of its tokens' components, its order the class's identity
- [ ] `Token implement Styleable`
- [ ] `output.bp`'s sheet model deleted; `flush()` renders `styled`'s sheet with emilia's `@layer`s,
      byte-identical to today's
- [ ] contract-4 fixture `e_39b87d03` unchanged (`contracts.md` § 4) — emilia's layer keeps the `e_`
      prefix; onze 68's `styleRule` reader and `jhonstart-emilia` (until `08-bpp/119` step 5) green
      without an edit to the class names they assert
- [ ] `emilia` 734 or more on both rows; `botopink.json` lists `styled` and nothing else outside std
- [ ] `AGENTS.md`: "Not a runtime CSS engine. No selector parsing" (`:602`) reworded — emilia reads
      no author CSS; author CSS is `css`'s, components `styled`'s
- [ ] `grep -rn "bpp\|jhonstart" repository/emilia/modules` empty

**Gate:** standard (fronts.md § Gate) + `emilia` 734 or more on both rows; the fifteen examples
green on both rows; `jhonstart-emilia` and `onze-cli` (the two fixture readers) green ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` empty (decision 114; step 1's last box)
