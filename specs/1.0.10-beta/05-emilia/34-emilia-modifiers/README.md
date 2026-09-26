# Front 34 — emilia modifiers

**Track:** D emilia · **Priority:** critical · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 56 (`Variant`, `nestVariant`, `markImportant`), 54 (`Theme`, `darkAtRule`/`darkSelector`, `--breakpoint-*`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 34 — modifiers` block, closing
`pub type Token`) · `src/emilia.bp` (`//// ═══ FRONT 34` block: one `Variant`-returning fn per name, and
the modifier arms of `tokenToSheet`, after every section arm)
**User docs:** `repository/emilia/docs.md` § *Modifiers — the variant table*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.2` (*Referência Completa de Variantes*), `§ 3.3`, `§ 3.4` · https://tailwindcss.com/docs/hover-focus-and-other-states

**Open:** none.

---

## What it delivers

The variant table: **83 modifiers** — 82 `Variant`-returning fns plus `Important` (decision 81),
which is `markImportant` rather than a `Variant`. A modifier is a top-level `Token` variant carrying
`inner: Token[]`; this front writes the two-field `Variant(atRule, selector)` per name and owns no
emission — front 56's `nestVariant` applies it. Every `selector` carries exactly one `&`; no fn here
builds a `{` or `}`.

Each arm is one line: `Hover(inner) -> nestVariant(tokensToSheet(inner, th), hoverVariant());`.
Nesting is source order — the outer modifier is outermost. A **range** is nesting, not a name:
`md:max-xl:` is `Token.Md([Token.MaxXl([…])])`.

| Family | Tokens | `Variant` |
|---|---|---|
| Breakpoints, min (`sm:`…`2xl:`) | `Sm`, `Md`, `Lg`, `Xl`, `X2xl` | `@media (width >= <--breakpoint-*>)` · `&` — each fn takes `th` and reads the theme (decision 82), so an override moves the query and the class hash |
| Breakpoints, max (`max-sm:`…) | `MaxSm`, `MaxMd`, `MaxLg`, `MaxXl`, `MaxX2xl` | `@media (width < <--breakpoint-*>)` · `&` |
| Dark mode | `Dark` | `darkAtRule(th)` · `darkSelector(th)` — `Media` puts the strategy in the at-rule, `Class`/`Attribute` in the selector; the variant never learns which is in force |
| Other media | `Print`, `Portrait`, `Landscape`, `MotionSafe`, `MotionReduce`, `ContrastMore`, `ContrastLess`, `ForcedColors` | `@media print`, `@media (orientation: …)`, `@media (prefers-reduced-motion: no-preference\|reduce)`, `@media (prefers-contrast: more\|less)`, `@media (forced-colors: active)` · `&` |
| Interaction | `Hover`, `Focus`, `FocusWithin`, `FocusVisible`, `Active`, `Visited`, `Target`, `Open`, `Inert` | `Hover` = `@media (hover: hover)` · `&:hover`; the rest selector-only: `&:focus` … `&:target`, `Open` = `&:is([open], :popover-open, :open)` (upstream v4; one `&` — the reference's `&:open, &:popover-open` has two and omits `[open]`), `Inert` = `&:is([inert], [inert] *)` |
| Form state | `Disabled`, `Enabled`, `Checked`, `Indeterminate`, `Default`, `Optional`, `Required`, `Valid`, `Invalid`, `UserValid`, `UserInvalid`, `InRange`, `OutOfRange`, `PlaceholderShown`, `Autofill`, `ReadOnly` | `&:<pseudo-class>` |
| Structural | `First`, `Last`, `Only`, `Odd`, `Even`, `FirstOfType`, `LastOfType`, `OnlyOfType`, `Empty`, `Nth(index, inner)`, `NthLast(index, inner)` | `&:first-child`, …, `&:nth-child(odd\|even)`, `&:nth-child(N)`, `&:nth-last-child(N)` |
| Pseudo-elements | `Before`, `After`, `FirstLetter`, `FirstLine`, `Placeholder`, `File`, `Marker`, `Selection`, `Backdrop` | `&::before` …, `&::file-selector-button`; `Marker` = `& *::marker`, `&::marker` and the same two for `::-webkit-details-marker`, `Selection` = `& *::selection`, `&::selection` — upstream v4's lists, each a list of one-`&` variants (`markerVariants()`, `selectionVariants()`) wrapped once each by `nestVariants` |
| Parent state | `GroupHover`, `GroupFocus`, `GroupActive`, `GroupVisited`, `GroupDisabled`, `GroupOpen` | `&:is(:where(.group)<state> *)` |
| Sibling state | `PeerHover`, `PeerFocus`, `PeerActive`, `PeerChecked`, `PeerInvalid`, `PeerRequired`, `PeerDisabled`, `PeerPlaceholderShown` | `&:is(:where(.peer)<state> ~ *)` |
| Direction and descent | `Rtl`, `Ltr`, `Children` (`*:`), `Descendants` (`**:`) | `&:where(:dir(rtl), [dir="rtl"], [dir="rtl"] *)` and its `ltr` twin (upstream v4.1), `:is(& > *)`, `:is(& *)` |
| Important | `Important(inner)` | `markImportant(tokensToSheet(inner, th))` |

The `.group` / `.peer` classes are the consumer's markup; emilia never emits them. `2xl` is spelled
`X2xl` because an identifier cannot start with a digit. Rendered on a class, `Token.Hover([.Text.Bold])`
is `@media (hover: hover){.e_x:hover{font-weight:bold}}`.

## Acceptance

### Delivered

- [x] `focusVariant()` is `Variant(atRule: "", selector: "&:focus")`; `mdVariant(th)` is
      `Variant(atRule: "@media (width >= 48rem)", selector: "&")` under the default theme.
- [x] Every variant fn's selector carries exactly one `&`; the front builds no brace; every at-rule
      is an at-rule.
- [x] `Hover`, `Focus`/`Active`, `Md`/`Lg`/`Xl` emit the v4.3 form (`@media (hover: hover)` +
      `&:hover`, `&:focus`, `@media (width >= 48rem)`, …) and no assertion in the repository expects
      the old nested `:hover{` spelling.
- [x] All ten breakpoints emit their reference query byte for byte; none resolves a `px` value or is
      `min-width`; `Token.Md([Token.MaxXl([.Text.Bold])])` nests the two `@media` rules.
- [x] `Token.Dark([.Bg.Color.Slate.900])` renders under `@media (prefers-color-scheme: dark)`, and a
      cell proves each `DarkMode` strategy; the eight other media variants emit their query; `Dark`
      nests with a breakpoint in both orders, in source order.
- [x] The nullary state, form and structural variants emit their reference selectors; `Nth` and
      `NthLast` at three indices including a two-digit one; `Open` is the one-`&` `:is()` form;
      `Inert` is the attribute pair.
- [x] Pseudo-elements emit `&::…`; `Marker`/`Selection` carry the space; a `Before` over two tokens
      folds into one `&::before{…}` rule (renderer's same-context fold).
- [x] Group and peer variants match their templates; `Rtl` puts the `&` last; `Children` and
      `Descendants` wrap the `&`; the `.group`/`.peer` classes are documented as the consumer's.
- [x] `dark:md:hover:` three deep comes out in source order; a modifier over an empty inner list is
      an empty sheet and is dropped.
- [x] Every non-arbitrary row of `§ 3.2`'s table has a token (82 `Variant` fns, 83 modifier tokens,
      no duplicate row).
- [x] The front-34 banners fence its blocks; `repository/emilia/AGENTS.md` and the `tokens.bp` header
      record the modifier map; green on commonJS and erlang.

## Known gaps

- Arbitrary variants (`[&.is-dragging]:`, `supports-[…]:`, `aria-*`, `data-*`, `has-*`, `not-*`) are
  front 57's `arbSel`/`arbAt` and front 59's `selector(v, inner)`; named groups/peers
  (`group/item`) are not covered.

## Examples

- [`./examples/modifiers-example.bp`](./examples/modifiers-example.bp) — one token list per family,
  ending with a responsive navigation bar that uses eight of them.
- [`./examples/nesting-example.bp`](./examples/nesting-example.bp) — breakpoint ranges,
  dark-plus-hover, group-plus-breakpoint, three-deep chains; a form field with a peer-driven error.
