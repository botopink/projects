# Front 43 — emilia tables

**Track:** D emilia · **Priority:** low · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 35 (the spacing scale), 54 (`spacing(n)`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 43 — tables` block: `Table`,
and the top-level `TableSpacingRaw`) · `src/emilia.bp` (front-43 block: `tableTokenToCss` and its
sub-dispatchers taking `th: Theme`, `rawTableSpacing`; two `tokenToSheet` arms between fronts 42 and 44)
**User docs:** `repository/emilia/docs.md` § *Table*
**Reference:** `TAILWIND_CSS_DOCS.md § 14` (spacing base `§ 21.2`) · https://tailwindcss.com/docs/border-collapse

**Open:** none.

---

## What it delivers

The four table-only properties — **21 leaves**, none resolving a length.

| Tailwind | Token | CSS |
|---|---|---|
| `border-collapse` / `border-separate` | `.Table.Collapse` / `.Table.Separate` | `border-collapse:collapse` / `separate` |
| `table-auto` / `table-fixed` | `.Table.Layout.Auto` / `.Fixed` | `table-layout:auto` / `fixed` |
| `border-spacing-{0,1,2,4,8}` | `.Table.Spacing.N` | `border-spacing:calc(var(--spacing) * N)`; `0` → `border-spacing:0` |
| `border-spacing-x-N` | `.Table.SpacingX.N` | `border-spacing:calc(var(--spacing) * N) 0` |
| `border-spacing-y-N` | `.Table.SpacingY.N` | `border-spacing:0 calc(var(--spacing) * N)` |
| `caption-top` / `caption-bottom` | `.Table.Caption.Top` / `.Bottom` | `caption-side:top` / `bottom` |
| `border-spacing-[…]` | `Token.TableSpacingRaw(value)` / `rawTableSpacing(v)` | `border-spacing:<v>` |

- The step set `{0, 1, 2, 4, 8}` is `spacing(n)`; under the default theme `calc(var(--spacing) * 2)`
  resolves to the reference's `0.5rem`. The zero rows carry no unit and no `calc`
  (`SpacingX.0`/`SpacingY.0` → `border-spacing:0 0`).
- The two axes are the two-value form of one property, so an X and a Y token in one list do not add
  up — the last wins.
- `Collapse`/`Separate` are bare leaves (the property has two values); `Layout` is a sub-section so
  `table-layout` is not confused with `border-collapse`.

## Acceptance

### Delivered

- [x] `.Table.Collapse` → `border-collapse:collapse`; `.Table.Layout.Fixed` → `table-layout:fixed`;
      `tableTokenToCss` and its sub-dispatchers have no `_` arm.
- [x] `.Table.Spacing.2` → `border-spacing:calc(var(--spacing) * 2)`; no `rem` or `px` in the block.
- [x] `SpacingX.2` and `SpacingY.2` are asserted as two different strings; `Spacing.0` is
      `border-spacing:0`; both axis zeros are `border-spacing:0 0`.
- [x] `.Table.Caption.Bottom` → `caption-side:bottom`; `Caption` has exactly two leaves.
- [x] Two `tokenToSheet` arms (`Table`, `TableSpacingRaw`), each one `declSheet(…)`, between fronts 42
      and 44; `Token.TableSpacingRaw(value: "1px 2px")` constructs; no payload leaf inside a section;
      no `_` arm.
- [x] `Table` carries `Collapse`, `Separate`, `Layout`, `Spacing`, `SpacingX`, `SpacingY`, `Caption`;
      the front-43 banners fence both files; `repository/emilia/AGENTS.md` records the section; green
      on commonJS and erlang.

## Examples

- [`./examples/tables-example.bp`](./examples/tables-example.bp) — the `Table` catalogue, then a data
  table: `border-separate` with a `border-spacing-y-2` row gap, a fixed layout and a bottom caption.
