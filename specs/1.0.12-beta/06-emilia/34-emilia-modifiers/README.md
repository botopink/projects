# Front 34 — emilia source tail: std's hash, five families at upstream parity, the breakpoint refusal (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56)

**Priority:** high — emilia on `styled` first (decision 350): step 5 before step 2, so the five
families move once, in `styled`'s literal; step 2 moves output every later snapshot (`20-snap`
step 4) would otherwise record twice · **State:** step 1 done; next step 5, after `08-bpp/119`
step 1's two open boxes; then step 2 (decision 350) and step 3 (358); step 4 on 401 (no wait) · step 5's two text boxes and its class box
(367) done; boxes 1–3 and 6 wait on 381's literal in `styled` (34-d: `styledProperty` answers the record),
box 4 on `08-bpp/119` step 4 (383's `StyledMeta` and its reader), `01-compiler/130` step 8 and the toolchain row "A nested-section enum value at comptime",
box 5 on that row and "emilia's dispatcher at comptime", box 8 on box 1
**Depends on:** `08-bpp/119` step 1 (step 5, and through it step 2 — its box 4 registers through
`use context(StyledSheet)`, 352, 354, 379, so `flush()` — which provides `StyledContext` — waits on
`01-compiler/134` step 6; step 3: the repositories `css`
and `styled` — the components and the theme mechanism, decision 338) · nothing for step 4 (401).
Nothing else:
`hash.contentHash` exists; `08-bpp/118` step 1's bracket-attribute carve-out is comments only here,
reworded by step 1 (no code uses `[name]={`).
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; edited blocks named per step),
`modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory · step 5
only, the carve-out of 369 and 367 (emilia's run-time calls moved to `comptime` / `#[emilia]`, and the re-recorded class):
`repository/jhonstart/modules/jhonstart-emilia/{src/root.bp,test/bridge_test.bp}`, onze 68's
`styleRule` reader and bundle test, `onze-cli`, `examples/emilia-card/**` and the other eleven
examples' `src/main.bp`
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (`20-snap`) · the other eleven examples' `src/main.bp` (none pins a moved
family; if one does, report to 33) · `repository/jhonstart/**` (`html_attrs.bp` is 48's, closed) ·
`.gitignore`, the hooks, `.github/` (`00-gate`) · `repository/css/**`, `repository/styled/**`
(`08-bpp/119` step 1)

## Goal

Class name is std's `hash.contentHash` (decision 116) over the class's rules, the `e_` prefix (367):
the contract-4 fixture re-derived once in step 5, `e_f51c2501`;
`modules/` names no other library (decision 114); five families render what Tailwind 4.3.2 renders;
the theme is typed and declared once with `#[theme]` — the mechanism `styled`'s, the Tailwind values
emilia's `defaultTheme()` —, a token naming a cleared breakpoint a compile error (decisions 300, 338);
negative translate and named groups / peers added, the other two feature rows stated as deviations (401); emilia runs at compile
time — a tag decorator `#[emilia(…)]` over typed tokens, its families compile-time functions written
with `styled`'s literal, its own sheet model gone (338, 369).
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

  Each (step 2, over step 5's components): its family's `styledProperty` literal + the `@property` / theme entries the chain reads
  (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`; `fullTheme()`
  gains no entry — per-utility variables with `@property` registrations like the transform ones; no
  new `Ns` prefix — 05emilia-a, -d, -i stand). Decision 350: a family moves whole, one helper per
  shape. A token list using a moved family changes class-name hash (hash is over the rules, 367); the
  contract-4 fixture (padding / colour / hover) uses none and does not move in step 2. jhonstart and onze
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

Step 5, the class (367): `output.bp` `classRules(sheet)` writes the class's rules as the document does
— layer order, plain rules before conditioned ones, runs of one context folded — with the class
`\u{1}` (`styled`'s hashed form), and `styleRule` names the class `"e_" + hash.contentHash(classRules(sheet))`;
the codec payload is still what the cell stores and `flush()` renders. `className(cardTokens(),
defaultTheme())` is `e_f51c2501` and its hashed text is asserted beside it; re-recorded by running, on
both targets: emilia's eleven pinned classes (the fixture, the eight family literals, `named`'s
`btn`), `emilia-card`'s `e_13df5d57` / `e_41222bb0` / `e_bcdc3f6a` (main and README),
`jhonstart-emilia`'s bridge test, onze-bundler's `entry_test` / `refusal_test` and onze-cli's
`build_test` (whose build evaluates the class). No CSS byte moved: one document per `Token` leaf
(6 980), per modifier and per fixture list (7 078 lists, 7 061 classes) before and after, on erlang and
commonJS, equal once each class is renamed, the renaming one-to-one; every example's printed output
renamed only. `emilia` 735 passed, 0 failed on erlang and on commonJS (+1: `classRules`); every example
green on both; `jhonstart-emilia` 10/0, onze-bundler 42/0, onze-cli 31/0 on both; jhonstart's
refusals 21/21.

Step 5, the two text boxes: `AGENTS.md` § What emilia is NOT opens "Not a CSS processor — emilia reads
no author CSS: author CSS is `css`'s, components are `styled`'s"; `grep -rn "bpp\|jhonstart"
repository/emilia/modules` is empty. No code moved: `emilia` 734 passed, 0 failed on erlang and on
commonJS, and every example's printed output and test log byte-identical to `a122dce` on both.

## Open

Order (decision 350: the library on `styled` first): step 5 → step 2 → step 3; step 4 (401) at any point. Step 5 keeps today's CSS byte for byte (368) — only the class names move, once
(367) —, so the five families move only in step 2, each as its `styledProperty` literal.

### Step 5 — emilia over `styled` — first (decisions 338, 350; after `08-bpp/119` step 1)

emilia is the third layer: `css` the base for building CSS, `styled` the base for building CSS
components, emilia a compile-time library written with `styled`'s literal, applied to a tag with its
own decorator `#[emilia(…)]` (`<h1 #[emilia(.Text.Bold)]>`, 369, 382: the parameter is `..tokens: @Expr<Token[]>`,
so the leading-dot path resolves — the reader of its meta is `08-bpp/119` step 4). emilia's own sheet model — `Rule`, `Sheet`, `Variant`, `renderRule`,
`renderDocument` (`output.bp:44-593`) and the per-render store `flush()` drains
(`emilia.bp:227-235`) — is what `css` and `styled` now hold. Each family is a compile-time function
answering `StyledProperty` (never a `@Component`, 369), written with the `styledProperty` literal; the
ladder of `spacing.bp` becomes the literal's `--spacing()`, and a variant wraps declarations in a
`styled`:

```bp
import styled, {styledProperty, Styled, StyledProperty} from "styled";

// Tailwind: @utility p-*  { padding: --spacing(--value(integer)); }
fn padAll(n: i32) -> StyledProperty { return styledProperty "padding: --spacing(${n});"; }
// Tailwind: @utility px-* { padding-inline: --spacing(--value(integer)); }
fn padX(n: i32) -> StyledProperty { return styledProperty "padding-inline: --spacing(${n});"; }
fn padAllHalf(n: i32) -> StyledProperty { return styledProperty "padding: --spacing(${n}.5);"; }

fn hover(inner: StyledProperty) -> Styled { return styled "&:hover { ${inner} }"; }

// the tag decorator: runs at build, records `decl.setMeta(StyledMeta(layer: .Utilities, className: c, rules: r))` (369, 383)
pub fn emilia(comptime decl: @Decl, comptime ..tokens: @Expr<Token[]>) { val list = tokens.value; … }
```

emilia imports `styled` and std — no framework, no `.bpp`, no jhonstart (113, 338).

- [ ] every family's `*TokenToCss` / `oneDecl` / `axisDecl` string building replaced by
      `styledProperty "…"` components; `spacing.bp`'s `spacing` / `spacingHalf` / `spacingNegHalf`
      replaced by `--spacing(…)` in the literal; no CSS text assembled with `+`
- [ ] each `styledProperty` literal is the upstream `@utility`'s declarations in Tailwind's CSS
      syntax, the 4.3.2 `@utility` quoted in a comment beside it (decision 350)
- [ ] variants (`.Hover(…)`, `.Md(…)`, `.Dark(…)`, …) wrap their inner declarations in a `styled`;
      a token list is the composition of its tokens' components in order, its order the class's
      identity — `[.Bg.White, Token.Focus([.Bg.Color.Gray.__100]), .Pad.All.__4]` renders three rules,
      the `padding` after the `:focus` (368, through `styled`'s source-order reader)
- [ ] `#[emilia(…)]`: `pub fn emilia(comptime decl: @Decl, comptime ..tokens: @Expr<Token[]>)` (382), no return
      (302) — `<div #[emilia(.Pad.All.4, .Bg.White)]>` resolves the dot paths against `Token`, computes
      the class and the rules at build and sets them as `styled`'s `StyledMeta(layer: .Utilities,
      className, rules)` (369, 383; one per tag); no family answers a `@Component`, no function of emilia answers `@Task`
- [ ] no run-time entry point: `emilia(tokens)`, `emiliaWith`, `className`, emilia's `styled` /
      `styledWith`, `cls`, `clsWith`, `named` leave the run-time API; every caller moves in this
      landing — `jhonstart-emilia` (until `08-bpp/119` step 5), onze 68's reader, `onze-cli`, the
      examples — to `#[emilia(…)]` in a template or `comptime className(…)` elsewhere (369)
- [ ] `output.bp`'s sheet model and codec (`Rule`, `Sheet`, `encodeSheet`) deleted; `flush()` writes the
      document frame — `<style>`, the `@layer …;` statement, `:root`, the base rules, keyframes, the
      `@property` fallback, the options — around `styled`'s `Sheet.render()`, byte-identical to today's
      CSS (368)
- [x] the class is `"e_" + hash.contentHash(<rules>)` (367, `contracts.md` § 4): the fixture
      re-derived, `className(cardTokens(), defaultTheme()) == "e_f51c2501"`, and its readers
      re-recorded in this landing — emilia's inline test, `jhonstart-emilia`'s bridge test (until
      `08-bpp/119` step 5), onze 68's bundle test, `emilia-card`'s three classes
- [ ] `emilia` 734 or more on both rows; `botopink.json` lists `styled` and nothing else outside std
- [x] `AGENTS.md`: "Not a runtime CSS engine. No selector parsing" (`:602`) reworded — emilia reads
      no author CSS; author CSS is `css`'s, components `styled`'s
- [x] `grep -rn "bpp\|jhonstart" repository/emilia/modules` empty

Waits on (measured on botopink-lang `90d50ae3`, styled `01a5299`; `119` step 1's source-order reader
and `StyledContext` have landed):
- 381 (34-d) in `styled` — `styledProperty "…"` answering the record `StyledProperty` (`08-bpp/119`
  step 1): until it lands, 369 (3)'s `fn padAll(n: i32) -> StyledProperty { return styledProperty "…"; }`
  is `type mismatch: expected StyledProperty, got Component` — boxes 1–3, 6, and 8 through them.
- `08-bpp/119` step 4 (383's `StyledMeta` in `styled` and its reader in jhonstart) and typed meta
  (`01-compiler/130` step 8) — box 4 (its parameter is 382's `comptime ..tokens: @Expr<Token[]>`,
  which compiles).
- The toolchain rows "A nested-section enum value at comptime" (`comptime f([.Pad.All.__4])` and a
  decorator's `tokens.value` raise `{badmap,'Pad'}`) and "emilia's dispatcher at comptime" (`comptime`
  over `tokensToSheet`: `MissingPackage`), and T19 (`contentHash` in a `comptime` block) — boxes 4
  and 5: `comptime className(.Pad.All.4)` cannot evaluate, so no caller can leave the run-time API.

### Step 2 — the five families to upstream's form, in `styled`'s literal (decision 350; after step 5)

- [ ] `transition` / `transition-*` presets render upstream's `var(--tw-ease, …)` /
      `var(--tw-duration, …)` pair, set `--tw-ease` / `--tw-duration` with `@property`
      registrations; `rawTransitionProperty` takes the same pair
- [ ] `backdrop-opacity-50` is `opacity(50%)`; every backdrop utility writes
      `-webkit-backdrop-filter` before `backdrop-filter`
- [ ] `border-spacing-*` writes `--tw-border-spacing-x` / `-y` and the reader
- [ ] `divide-x-*` / `divide-y-*` write `border-*-style:var(--tw-border-style)` beside the width
- [ ] each moved family's `styledProperty` literal is the 4.3.2 `@utility`, quoted beside it; its
      inline tests and the four examples' inline strings assert the new literal, measured against
      4.3.2's output quoted in the test's comment; `docs.md` and its
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
<div #[emilia(.Lg(.Pad.All.4))]>…</div>        // compile error: breakpoint lg was cleared in the theme
```

The theme is always declared (358): an application with no `#[theme]` is a compile error at its
first literal, naming `#[theme] pub val appTheme = comptime defaultTheme();`; emilia's
`defaultTheme()` is the whole Tailwind theme, palette included.

- [ ] `theme.bp` builds `defaultTheme()` — the whole Tailwind theme, `fullTheme()`'s entries folded in,
      `fullTheme()` / `fullOptions()` gone — as a value of `styled`'s `Theme`; emilia's
      own `extendTheme`, `#("--…", "…")` pairs and `""`-as-clear leave its API
- [ ] a token's breakpoint, colour or spacing resolves through the app's `#[theme]` (`styled`'s), so a
      token naming a cleared or absent breakpoint (`Lg` after `clear(.Breakpoint, "lg")`) is refused at
      compile time when the token list is comptime-known (every `#[emilia(…)]` annotation, 301, 338, 369),
      naming the theme's line; the run-time refusal stays only for a list built at run time
- [ ] an emilia token reading an entry the declared theme lacks is a compile error at the token
      (358); `flush()` renders with the declared theme; every example and test program declares
      `#[theme] pub val appTheme = comptime defaultTheme();`
- [ ] `reference-rows.md` § 3.3 "removing breakpoints" reads as a deviation in `docs.md`

### Step 4 — the unplaced rows (decision 401; the refusal is step 3, 300)

`TranslateX.Neg` / `TranslateY.Neg` in `tokens.bp` (`:2259-2279`) beside `Rotate.Neg` (314: a numeric leaf
has no sign), with 350's `calc(… * -1)` form; named groups and peers as `GroupNamed(name, inner)` /
`PeerNamed(name, inner)` payload variants (top-level, like every payload-carrying token) with
`.group\/<name>` / `.peer\/<name>` selectors. The named `has` / `not` / ARIA / data / `in` forms keep
`arbSel`; `@theme inline` is not added.

- [ ] `-translate-y-2` is `.Transform.TranslateY.Neg.2`, rendering `--tw-translate-y:calc(var(--spacing) * -2)`
      and the composed `translate`; `TranslateX.Neg` likewise — measured against 4.3.2
- [ ] `GroupNamed("card", …)` / `PeerNamed(…)`: `group-hover/card:underline` renders `.group\/card:hover .e_…`,
      every unnamed group and peer state available named — measured against 4.3.2
- [ ] `docs.md` § Deviations: the named `has` / `not` / ARIA / data / `in` forms written with `arbSel`
      (`arbSel("&:has(img)", [.Pad.All.4])`), `@theme inline` not supported; `reference-rows.md`'s rows marked
- [ ] `tokens.bp:2190-2195`'s comment states `Neg` as the decided form (314), not a language gap

**Gate:** standard (fronts.md § Gate) + `emilia` 734 or more on both rows; the fifteen examples
green on both rows; `jhonstart-emilia` and `onze-cli` (the two fixture readers) green, the class
re-recorded (367) ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` empty (decision 114; step 1's last box)
