# Front 42 — emilia filters

**Track:** D emilia · **Priority:** medium · **Level:** 3 (no edge; arms after 33 · 34 · 35) · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (`themeVar`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 42 — filters` block: `Filter`,
`BackdropFilter`, and the top-level `FilterRaw`, `BackdropRaw`) · `src/emilia.bp` (front-42 block:
`filterTokenToCss`, `backdropFilterTokenToCss`, `filterFamilyDecl`, `backdropFamilyDecl`, `filterChain`,
`backdropFilterChain`, `filterEntries`, `rawFilter`, `rawBackdropFilter`; four `tokenToSheet` arms after
front 41's)
**User docs:** `repository/emilia/docs.md` § *Filter and BackdropFilter*
**Reference:** `TAILWIND_CSS_DOCS.md § 13` (blur literals `§ 13.1`; backdrop opacity from `§ 12.3`) · https://tailwindcss.com/docs/filter

**Open:** none.

---

## What it delivers

`§ 13` — **108 leaves**, none resolving a length. `Filter` is `§ 13.1` on `filter`;
`BackdropFilter` is `§ 13.2` on `backdrop-filter` (not `Backdrop`, which is front 34's `::backdrop`
modifier).

| Section | Sub-sections | Emits |
|---|---|---|
| `Filter` | `Blur` (`None`, `Xs`, `Sm`, `Md`, `Lg`, `Xl`, `X2xl`, `X3xl`), `Brightness` (0 50 75 90 95 100 105 110 125 150 200), `Contrast` (0 50 75 100 125 150 200), `DropShadow` (`None`, `Xs` … `X2xl`), `Grayscale` (0, 100), `HueRotate` (0 15 30 60 90 180), `Invert` (0, 100), `Saturate` (0 50 100 150 200), `Sepia` (0, 100) | `--tw-<family>:<fn>;filter:<chain>` |
| `BackdropFilter` | the same families without `DropShadow`, plus `Opacity` (`§ 12.3`'s fifteen steps) | `--tw-backdrop-<family>:<fn>;backdrop-filter:<backdrop chain>` |
| arbitrary | `Token.FilterRaw(value)`, `Token.BackdropRaw(value)`; wrappers `rawFilter(v)`, `rawBackdropFilter(v)` | `filter:<v>`, `backdrop-filter:<v>` |

- **Filters compose.** Each leaf writes its own family's custom property and one reader, the chain
  `var(--tw-blur, ) var(--tw-brightness, ) var(--tw-contrast, ) var(--tw-grayscale, ) var(--tw-hue-rotate, ) var(--tw-invert, ) var(--tw-saturate, ) var(--tw-sepia, ) var(--tw-drop-shadow, )`
  (`filterChain()`), inlined in each rule — the empty fallbacks make an unset family contribute
  nothing, so `[.Filter.Blur.Sm, .Filter.Grayscale.100]` keeps both. The reader cannot be a
  `--tw-filter` theme entry: `extendTheme` refuses `--tw-`, and a `:root` definition would resolve
  where no family is set.
- **Values** are the reference's own: `brightness(.5)` (leading dot kept), `grayscale(100%)`,
  `hue-rotate(90deg)`; blur and drop shadows are theme references — `blur(var(--blur-md))`,
  `drop-shadow(var(--drop-shadow-md))` — whose values are `filterEntries()`, composed into
  `fullTheme()`.
- `Blur.None` is `filter:none` (replaces the whole chain); `DropShadow.None` empties its own family
  (`--tw-drop-shadow: ` plus the reader), as upstream does — the reference's `drop-shadow(none)` is
  not valid CSS.
- Every non-blur `BackdropFilter` leaf has a `Filter` twin writing the same function call.

## Acceptance

### Delivered

- [x] Every row of `§ 13.1` has an arm; every `case` is exhaustive with no `_`.
- [x] `.Filter.Brightness.50` → `--tw-brightness:brightness(.5)` plus the chain reader;
      `.Filter.Blur.X2xl` → `--tw-blur:blur(var(--blur-2xl))` plus the reader; no `px` in any
      `Filter` arm.
- [x] Every non-`None` arm ends in the reader, so blur and grayscale in one list compose.
- [x] `Grayscale.100`, `Invert.100`, `Sepia.100` carry `%`; `Brightness.100` does not.
- [x] `.Filter.DropShadow.Md` → `--tw-drop-shadow:drop-shadow(var(--drop-shadow-md))` plus the
      reader; `DropShadow.None` is upstream's empty family, with the reference form absent.
- [x] `BackdropFilter` has nine families plus `Opacity`, no `DropShadow`; every twin writes the
      `Filter` leaf's function call; `BackdropFilter.Opacity` has the fifteen `§ 12.3` steps.
- [x] Four `tokenToSheet` arms right after front 41's, each one `declSheet(…)`;
      `Token.FilterRaw(value: "blur(8px) grayscale(100%)")` constructs; no payload leaf inside a
      section; no `_` arm.
- [x] The composition is stated in the `tokens.bp` docblock; `repository/emilia/AGENTS.md` records the
      two sections and the two-declaration shape; both dispatchers take `th: Theme`; green on commonJS
      and erlang.

## Examples

- [`./examples/filters-example.bp`](./examples/filters-example.bp) — the `Filter` and
  `BackdropFilter` catalogues, composition in one list, and a frosted navigation bar using
  `backdrop-blur` and `backdrop-saturate` over a dimmed hero image.
