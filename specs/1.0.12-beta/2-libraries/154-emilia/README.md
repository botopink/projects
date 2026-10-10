# Front 154 — emilia: emilia over `styled`, the five families, the theme

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/emilia/**`
**Depends on:** 148 s1 (119 s1) · 148 s2 (119 s4) · 144 B-00c / B-12 (`contentHash` as a host function at build), B-17 (379), B-19 (353)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `34-emilia-modifiers` open | 154 s1 |
| `34-emilia-modifiers` s5 | 154 s1 |
| `34-emilia-modifiers` s2 | 154 s2 |
| `34-emilia-modifiers` s3 | 154 s3 |
| `20-snap` s4 | 154 s4 |

## Steps

### 154 s1 — emilia over `styled` — first (34 s5)

#### Open (was `34-emilia-modifiers` open)

Order (decision 350: the library on `styled` first): step 5 → step 2 → step 3; step 4 (401) at any point. Step 5 keeps today's CSS byte for byte (368) — only the class names move, once
(367) —, so the five families move only in step 2, each as its `styledProperty` literal.

#### Step 5 — emilia over `styled` — first (decisions 338, 350; after `08-bpp/119` step 1) (was `34-emilia-modifiers` s5)

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

### 154 s2 — the five families in `styled`'s literal (34 s2)

#### Step 2 — the five families to upstream's form, in `styled`'s literal (decision 350; after step 5) (was `34-emilia-modifiers` s2)

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

### 154 s3 — the theme (34 s3)

#### Step 3 — the theme: Tailwind's values over `styled`'s mechanism (decisions 300, 338; after `08-bpp/119` step 1) (was `34-emilia-modifiers` s3)

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

### 154 s4 — `emilia-test`'s asserts (135 s4, after 154 s1–s3)

#### Step 4 — emilia-test (390) (was `20-snap` s4)

- [ ] `assertClassName` under `defaultTheme()` (records `e_f51c2501`, the class 367 re-derives in `06-emilia/34` step 5) and `assertCss(loc, tokens, th)`
      over a `pub` CSS surface (`tokensToSheet` is private today), two `.snap` (§ 4, KEEP)
- [ ] `emilia-card`'s repeat collapse as an inline test (§ 5, CONVERT — goes with 33 step 2)
- [ ] `repository/emilia/AGENTS.md` § Tests: the inline literals, the three readers of the
      contract-4 literal and the two helper `.snap` are the evidence; the 1.0.10 suites and eight
      examples are retired (33 steps 3–4)
