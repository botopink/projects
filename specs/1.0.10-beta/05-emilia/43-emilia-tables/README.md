# Front 43 — emilia tables

**Track:** D emilia
**Priority:** low — four CSS properties, all of them table-only; nothing else in the milestone waits on this front, and no other front can substitute for it
**Target:** comptime
**Wave:** 3
**Depends on:** 35 (the spacing scale `border-spacing` is a multiple of — this front reuses the step values, not front 35's tokens)
**Owns:** token section `Table` in `repository/emilia/src/tokens.bp` · dispatcher `tableTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/tables_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, the class-name hash (std `content_hash.contentHash` since decision 116), `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 14. Tabelas` (the spacing base from `§ 21.2`) · https://tailwindcss.com/docs/border-collapse

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
every spacing utility is a multiplier of it.

Contract `§ 4a` says how that multiplier is spelled: **`spacing(n)` returns
`calc(var(--spacing) * n)` and never a resolved `rem`.** The first draft of this front emitted
`border-spacing:0.5rem` for `border-spacing-2`, matching `§ 14.2`'s row literally; that is wrong
under the contract, because it hard-codes a base the theme may change. The emitted value is
`calc(var(--spacing) * 2)`, and `§ 14.2`'s `0.5rem` is what it resolves to under `defaultTheme()`.

The scale this front ships is `{0, 1, 2, 4, 8}` — the same step set `Pad` and `Margin` already use
at `tokens.bp:140-183`, so a developer reading `.Pad.All.4` and `.Table.Spacing.4` reads the same
number twice and means the same distance twice.

The `0` step emits `border-spacing:0`, not `spacing(0)` — `§ 14.2`'s own row says `0`, and a
`calc(var(--spacing) * 0)` would be a longer way to write the same zero.

**Dispatcher shape.** Per contract `§ 4a`:

```bp
fn tableTokenToCss(t: Token.Table, th: Theme) -> string
```

No table token needs a selector outside its own class — `border-collapse` and friends all apply to
the element carrying them — so this front keeps the declaration-string form and does not take the
`…TokenToSheet(t, th) -> Sheet` shape.

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

    // The arbitrary-value escape hatch is a TOP-LEVEL variant, never a section
    // leaf — a payload leaf inside a section cannot be constructed by any
    // spelling (`language-gaps.md` row 52, contract `§ 4a`).
    TableSpacingRaw(value: string),
}
```

**Acceptance:**
- [x] `tableTokenToCss(.Collapse, th)` returns `border-collapse:collapse`. — held: test "Table — border-collapse and table-layout, `§ 14.1` and `§ 14.3`"
- [x] `tableTokenToCss(.Layout.Fixed, th)` returns `table-layout:fixed`. — held: same test
- [x] `tableTokenToCss` is exhaustive with no `_` arm. — held: `tableTokenToCss` and its sub-dispatchers have no `_` arm

### Step 2 — `border-spacing`, all three axes

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `border-spacing-0` | `.Table.Spacing.0` | `border-spacing:0` |
| `border-spacing-1` | `.Table.Spacing.1` | `border-spacing:calc(var(--spacing) * 1)` |
| `border-spacing-2` | `.Table.Spacing.2` | `border-spacing:calc(var(--spacing) * 2)` |
| `border-spacing-4` | `.Table.Spacing.4` | `border-spacing:calc(var(--spacing) * 4)` |
| `border-spacing-8` | `.Table.Spacing.8` | `border-spacing:calc(var(--spacing) * 8)` |
| `border-spacing-x-0` | `.Table.SpacingX.0` | `border-spacing:0 0` |
| `border-spacing-x-1` | `.Table.SpacingX.1` | `border-spacing:calc(var(--spacing) * 1) 0` |
| `border-spacing-x-2` | `.Table.SpacingX.2` | `border-spacing:calc(var(--spacing) * 2) 0` |
| `border-spacing-x-4` | `.Table.SpacingX.4` | `border-spacing:calc(var(--spacing) * 4) 0` |
| `border-spacing-x-8` | `.Table.SpacingX.8` | `border-spacing:calc(var(--spacing) * 8) 0` |
| `border-spacing-y-0` | `.Table.SpacingY.0` | `border-spacing:0 0` |
| `border-spacing-y-1` | `.Table.SpacingY.1` | `border-spacing:0 calc(var(--spacing) * 1)` |
| `border-spacing-y-2` | `.Table.SpacingY.2` | `border-spacing:0 calc(var(--spacing) * 2)` |
| `border-spacing-y-4` | `.Table.SpacingY.4` | `border-spacing:0 calc(var(--spacing) * 4)` |
| `border-spacing-y-8` | `.Table.SpacingY.8` | `border-spacing:0 calc(var(--spacing) * 8)` |
| `border-spacing-[…]` | `Token.TableSpacingRaw(value: v)` — **top-level** | `border-spacing:<v>` |

Every non-zero row is `spacing(n)` per contract `§ 4a`. Under `defaultTheme()` those resolve to the
reference's own values — `calc(var(--spacing) * 2)` is `0.5rem`, which is what `§ 14.2` prints — so
the front is byte-equal to Tailwind's **rendered** output while staying overridable, which is the
point of the theme layer.

The three axes are separate sub-sections rather than one section with an axis payload, because
`border-spacing` is a single property with a one- or two-value syntax, and a leaf that knows which
form it emits is simpler than a dispatcher that reassembles it.

**Acceptance:**
- [x] `tableTokenToCss(.Spacing.2, th)` returns `border-spacing:calc(var(--spacing) * 2)` — spaces
      around the `*` kept, and **no `rem` literal anywhere in this front's block**. — held: test "Table.Spacing — the five steps as spacing multipliers"; walk "front 43 — 21 leaves … none resolving a length"
- [x] `tableTokenToCss(.SpacingX.2, th)` returns `border-spacing:calc(var(--spacing) * 2) 0` and
      `.SpacingY.2` returns `border-spacing:0 calc(var(--spacing) * 2)` — the two are not
      interchangeable and a test asserts both. — held: test "Table.SpacingX / SpacingY — the axes are not interchangeable"
- [x] `.Table.Spacing.0` returns `border-spacing:0`, with no unit and no `calc`. — held: test "Table.Spacing — the zero rows carry no unit and no calc"
- [x] `.Table.SpacingX.0` and `.Table.SpacingY.0` both return `border-spacing:0 0`, which is the
      one place the two axes agree. — held: same test

### Step 3 — `caption-side`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `caption-top` | `.Table.Caption.Top` | `caption-side:top` |
| `caption-bottom` | `.Table.Caption.Bottom` | `caption-side:bottom` |

**Acceptance:**
- [x] `tableTokenToCss(.Caption.Bottom, th)` returns `caption-side:bottom`. — held: test "Table.Caption — the two rows of `§ 14.4`"
- [x] `Caption` has exactly two leaves; `§ 14.4` lists two. — held: `tokens.bp` `Table.Caption { Top, Bottom }`

### Step 4 — one new arm in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, reached through `declSheet(...)`.

```bp
        Table(_inner) -> declSheet(tableTokenToCss(_inner, th));
        TableSpacingRaw(value) -> declSheet("border-spacing:" + value);
```

Two arms, not one: `TableSpacingRaw` is a sibling of `Table`, not a leaf inside it, and it
destructures by its declared field name (`value`) — a positional bind type-checks and is `undefined`
at run time.

**Acceptance:**
- [x] The two arms sit between front 42's arms and front 44's, in front-number order. — held: `tokenToSheet`'s `// ── front 43 — tables` fence between front 42's and front 44's
- [x] Each arm is one `declSheet(...)` call; neither builds a `Rule` or a `Sheet` by hand. — held: both arms are `declSheet(…)`
- [x] `Token.TableSpacingRaw(value: "1px 2px")` **constructs** — a test builds one. — held: test "TableSpacingRaw — the escape hatch constructs and emits"
- [x] No section in this front's `tokens.bp` block contains a payload leaf. — held: `tokens.bp` front 43 block — leaves only
- [x] `tokenToSheet` still has no `_` arm. — held: `tokenToSheet` has no `_` arm

## Examples

- [`./examples/tables-example.bp`](./examples/tables-example.bp) — the whole `Table` catalogue, then
  a striped data table whose outer element is `border-separate` with a `border-spacing-y-2` row gap
  and a fixed layout, with a bottom caption.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's one escape hatch, written `Table.Spacing.Raw` in the first draft | the variant moves to the **top level** of `Token` per contract `§ 4a`: `Token.TableSpacingRaw(value: string)`, with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same variant, now top-level: `[.TableSpacingRaw("1px 2px")]` still trips the parser | a wrapper fn returning the token (`fn rawSpacing(v: string) -> Token { return Token.TableSpacingRaw(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Test plan

`repository/emilia/test/tables_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tableTokenToCss(<token>, th) == "<css>"` per row of
   the three tables — twenty-two assertions, which is the whole front.
2. **The axis distinction.** `SpacingX.2` and `SpacingY.2` asserted as two different strings in
   adjacent lines, because a copy-paste error between them is the likeliest defect in this front and
   it is invisible to a test that checks only one.
3. **The unitless zero.** `.Table.Spacing.0` is `border-spacing:0`, asserted as an exact string, so
   a refactor that pushes every step through one `spacing(n)` call fails here.
4. **No `rem` literal.** A test greps this front's block of `emilia.bp` for `rem` and fails if it
   finds one — contract `§ 4a` says `spacing(n)` never resolves, and the first draft of this front
   got it wrong, which is exactly why the grep is cheap insurance.
5. **The real rule.** `[.Table.Separate, .Table.SpacingY.2, .Table.Layout.Fixed, .Table.Caption.Bottom]`
   produces four entries in `Rule.declarations` in list order — one assertion proving the four
   properties compose.
6. **Variant nesting.** `Token.Md([.Table.Layout.Fixed])` reaches front 34's `nestVariant` with the
   inner declaration `table-layout:fixed`, which is the realistic use — a table that goes
   fixed-layout only once there is room for it. This front asserts its declaration, not the wrap;
   the wrap is front 34's contract.
7. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [x] `Table` exists as a top-level section with `Collapse`, `Separate`, `Layout`, `Spacing`,
      `SpacingX`, `SpacingY`, `Caption`, fenced by a `front 43` banner in `tokens.bp` and appended
      after front 42's block. — held: `tokens.bp` `// ── front 43 — tables` fence after front 42's
- [x] `tableTokenToCss` and its sub-dispatchers are fenced by a `front 43` banner in `emilia.bp`,
      appended after front 42's block, and take `th: Theme` per contract `§ 4a`. — held: `emilia.bp` `// ── front 43 — tables` block after front 42's; `tableTokenToCss(t, th)`
- [x] One arm added to `tokenToSheet`, a `declSheet(...)` call, in front-number order, and no other
      line of that `case` moved. — held (shape: two arms — `Table` and the top-level `TableSpacingRaw`, as step 4 says): after front 42's fence, no other line moved
- [x] Every non-zero spacing step is `spacing(n)`; no `rem` literal appears in this front's block. — held: `tableSpacing*Value` all `spacing(n)`; the walk finds no `rem` or `px`
- [x] `repository/emilia/AGENTS.md` records the new section. — held: emilia `AGENTS.md` "Front 43 owns **tables**"
- [x] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them. — held: `modules/emilia` 608/608 on commonJS and erlang (+10 inline tests; shape: inline, no `test/tables_test.bp`)
