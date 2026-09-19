# Front 43 — emilia tables

**Track:** D emilia
**Priority:** low — four CSS properties, all of them table-only; nothing else in the milestone waits on this front, and no other front can substitute for it
**Target:** comptime
**Wave:** 1
**Depends on:** 35 (the spacing scale `border-spacing` is a multiple of — this front reuses the step values, not front 35's tokens)
**Owns:** token section `Table` in `repository/emilia/src/tokens.bp` · dispatcher `tableTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/tables_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 14. Tabelas` (the spacing base from `§ 21.2`) · https://tailwindcss.com/docs/border-collapse
**Replaces:** `1.0.8-beta/09-emilia-tables`

---

## Problem

There is no `Table` token. `repository/emilia/src/tokens.bp:36-270` covers text, colour, spacing,
layout, flex, borders and effects and stops there — none of the four table-layout properties has a
token.

The consequence is narrow and total. `border-collapse`, `border-spacing`, `table-layout` and
`caption-side` have no substitute: a `Border` token does not collapse a table's borders, a `Pad`
token does not set `border-spacing`, and a column that will not stay at a fixed width because
`table-layout` is `auto` cannot be fixed by anything else in the library. A dashboard with a data
table is the ordinary case where this bites, and today the only way out is to leave `emilia` and
hand-write four declarations.

This is the smallest front in track D — four properties, twenty tokens — and it is worth its own
front precisely because it shares nothing with any other. `Table` touches no colour, no spacing
token, no modifier behaviour, and it can land any time after wave 0 without waiting for anything.

## Current state

- No `Table` section; no `border-collapse`, `border-spacing`, `table-layout` or `caption-side`
  string anywhere in `repository/emilia/src/`.
- `Pad` and `Margin` — `tokens.bp:140-183` — carry the scale `{1, 2, 4, 8, 16}` and `{1, 2, 4, 8}`,
  which is the house precedent for how a spacing-derived scale is spelled in this library.
- `tokensToCss` joins with `;` — `emilia.bp:103`. A table needs `border-collapse:separate` and
  `border-spacing:0.5rem` in one rule, which is two tokens in one list and needs nothing special.

## Mechanism

Four CSS properties, four sub-sections, one dispatcher. Every leaf is a one-to-one mapping from a
Tailwind class to a property/value pair; there is no composition problem, no custom property, and no
theme variable involved.

**Where the values come from.** `§ 14.1`, `§ 14.3` and `§ 14.4` give the property and the value
directly and this front copies them. `§ 14.2` gives four rows — `border-spacing-0`,
`border-spacing-2`, `border-spacing-x-2`, `border-spacing-y-2` — and leaves the rest of the scale
implicit. `§ 21.2` states the rule that makes it explicit: the `--spacing` base is `0.25rem` and
every spacing utility is a multiplier of it. `border-spacing-2` → `0.5rem` is exactly `2 × 0.25rem`,
which confirms the multiplier rather than assuming it. The scale this front ships is `{0, 1, 2, 4,
8}` — the same step set `Pad` and `Margin` already use at `tokens.bp:140-183`, so a developer
reading `.Pad.All.4` and `.Table.Spacing.4` reads the same number twice and means the same distance
twice.

The `0` step emits `border-spacing:0`, not `border-spacing:0rem` — `§ 14.2`'s own row says so.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`). The **value** is byte-equal to the reference; the separator is emilia's.

## Steps

### Step 1 — `border-collapse` and `table-layout`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `border-collapse` | `.Table.Collapse` | `border-collapse:collapse` |
| `border-separate` | `.Table.Separate` | `border-collapse:separate` |
| `table-auto` | `.Table.Layout.Auto` | `table-layout:auto` |
| `table-fixed` | `.Table.Layout.Fixed` | `table-layout:fixed` |

`Collapse` and `Separate` are bare leaves rather than a `Collapse { Collapse, Separate }` sub-section:
the property has two values and a sub-section named after one of them reads wrong. `Layout` is a
sub-section because `table-layout` and `border-collapse` are different properties that would
otherwise sit at the same level with no hint which is which.

```bp
pub type Token {
    // ── front 43 · tables ────────────────────────────────────────────────
    Table {
        Collapse,
        Separate,
        Layout {
            Auto,
            Fixed,
        }
    }
}
```

**Acceptance:**
- [ ] `tokensToCss([.Table.Collapse])` returns `border-collapse:collapse`.
- [ ] `tokensToCss([.Table.Layout.Fixed])` returns `table-layout:fixed`.
- [ ] `tableTokenToCss` is exhaustive with no `_` arm.

### Step 2 — `border-spacing`, all three axes

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `border-spacing-0` | `.Table.Spacing.0` | `border-spacing:0` |
| `border-spacing-1` | `.Table.Spacing.1` | `border-spacing:0.25rem` |
| `border-spacing-2` | `.Table.Spacing.2` | `border-spacing:0.5rem` |
| `border-spacing-4` | `.Table.Spacing.4` | `border-spacing:1rem` |
| `border-spacing-8` | `.Table.Spacing.8` | `border-spacing:2rem` |
| `border-spacing-x-0` | `.Table.SpacingX.0` | `border-spacing:0 0` |
| `border-spacing-x-1` | `.Table.SpacingX.1` | `border-spacing:0.25rem 0` |
| `border-spacing-x-2` | `.Table.SpacingX.2` | `border-spacing:0.5rem 0` |
| `border-spacing-x-4` | `.Table.SpacingX.4` | `border-spacing:1rem 0` |
| `border-spacing-x-8` | `.Table.SpacingX.8` | `border-spacing:2rem 0` |
| `border-spacing-y-0` | `.Table.SpacingY.0` | `border-spacing:0 0` |
| `border-spacing-y-1` | `.Table.SpacingY.1` | `border-spacing:0 0.25rem` |
| `border-spacing-y-2` | `.Table.SpacingY.2` | `border-spacing:0 0.5rem` |
| `border-spacing-y-4` | `.Table.SpacingY.4` | `border-spacing:0 1rem` |
| `border-spacing-y-8` | `.Table.SpacingY.8` | `border-spacing:0 2rem` |
| `border-spacing-[…]` | `Token.Table.Spacing.Raw(value: v)` | `border-spacing:<v>` |

Two rows of that table are the reference's verbatim (`border-spacing-0`, `border-spacing-2`,
`border-spacing-x-2`, `border-spacing-y-2` — four rows); the rest are `N × 0.25rem` per `§ 21.2`,
with the multiplication shown so a reviewer can check it in one glance instead of trusting it.

The three axes are separate sub-sections rather than one section with an axis payload, because
`border-spacing` is a single property with a one- or two-value syntax, and a leaf that knows which
form it emits is simpler than a dispatcher that reassembles it.

**Acceptance:**
- [ ] `tokensToCss([.Table.Spacing.2])` returns `border-spacing:0.5rem` — character-identical to
      `§ 14.2`.
- [ ] `tokensToCss([.Table.SpacingX.2])` returns `border-spacing:0.5rem 0` and
      `tokensToCss([.Table.SpacingY.2])` returns `border-spacing:0 0.5rem` — the two are not
      interchangeable and a test asserts both.
- [ ] `.Table.Spacing.0` returns `border-spacing:0`, with no unit.
- [ ] `.Table.SpacingX.0` and `.Table.SpacingY.0` both return `border-spacing:0 0`, which is the
      one place the two axes agree.

### Step 3 — `caption-side`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `caption-top` | `.Table.Caption.Top` | `caption-side:top` |
| `caption-bottom` | `.Table.Caption.Bottom` | `caption-side:bottom` |

**Acceptance:**
- [ ] `tokensToCss([.Table.Caption.Bottom])` returns `caption-side:bottom`.
- [ ] `Caption` has exactly two leaves; `§ 14.4` lists two.

### Step 4 — one new arm in `tokenToCss`

```bp
        Table(_inner) -> tableTokenToCss(_inner);
```

**Acceptance:**
- [ ] The arm sits between front 42's two arms and front 44's, in front-number order.
- [ ] `tokenToCss` still has no `_` arm.

## Examples

- [`./examples/tables-example.bp`](./examples/tables-example.bp) — the whole `Table` catalogue, then
  a striped data table whose outer element is `border-separate` with a `border-spacing-y-2` row gap
  and a fixed layout, with a bottom caption.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Table.Spacing.Raw("1px 2px")]` trips the parser | `Table.Spacing.Raw` — the arbitrary-value escape hatch, used when a design needs a spacing that is not a multiple of `0.25rem` | wrap the constructor in a fn (`fn rawSpacing(v: string) -> Token { return Token.Table.Spacing.Raw(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Table.Spacing.Raw("1px 2px")];` |

## Test plan

`repository/emilia/test/tables_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the three
   tables — twenty-two assertions, which is the whole front.
2. **The axis distinction.** `SpacingX.2` and `SpacingY.2` asserted as two different strings in
   adjacent lines, because a copy-paste error between them is the likeliest defect in this front and
   it is invisible to a test that checks only one.
3. **The unitless zero.** `.Table.Spacing.0` is `border-spacing:0`, asserted as an exact string, so a
   refactor that formats every step through one `"…rem"` template fails here.
4. **The real rule.** `tokensToCss([.Table.Separate, .Table.SpacingY.2, .Table.Layout.Fixed, .Table.Caption.Bottom])`
   returns `border-collapse:separate;border-spacing:0 0.5rem;table-layout:fixed;caption-side:bottom`
   — one assertion proving the four properties compose in list order through the unchanged `;` join.
5. **Modifier nesting.** `Token.Md([.Table.Layout.Fixed])` wraps as
   `@media(min-width:768px){table-layout:fixed}`, which is the realistic use — a table that goes
   fixed-layout only once there is room for it.
6. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   `commonJS` and `erlang` must agree on the `djb2` hash. Every value here is ASCII, the condition
   `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Table` exists as a top-level section with `Collapse`, `Separate`, `Layout`, `Spacing`,
      `SpacingX`, `SpacingY`, `Caption`, fenced by a `front 43` banner in `tokens.bp` and appended
      after front 42's block.
- [ ] `tableTokenToCss` and its sub-dispatchers are fenced by a `front 43` banner in `emilia.bp`,
      appended after front 42's block.
- [ ] One arm added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] The `N × 0.25rem` derivation is stated in the `tokens.bp` docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the new section.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
