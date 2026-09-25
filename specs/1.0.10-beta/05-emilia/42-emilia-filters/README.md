# Front 42 — emilia filters

**Track:** D emilia
**Priority:** medium — no filter token exists at all, so a frosted panel, a dimmed disabled control and a greyed-out avatar each have to leave `emilia` entirely
**Target:** comptime
**Wave:** 3
**Depends on:** none of the emilia fronts directly — `Filter` and `Backdrop` are self-contained scales. Wave 1 places it after wave 0 (33 · 34 · 35) so the `tokenToCss` arms land in front-number order.
**Owns:** token sections `Filter`, `Backdrop` in `repository/emilia/src/tokens.bp` · dispatcher `filterTokenToCss` (and its sibling `backdropTokenToCss`) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/filters_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 13. Filtros` (blur literals inline at `§ 13.1`; the opacity scale mirrored from `§ 12.3`) · https://tailwindcss.com/docs/filter

---

## Problem

There is no `Filter` token and no `Backdrop` token. `repository/emilia/src/tokens.bp:36-270`
declares ten sections and none of them touches `filter` or `backdrop-filter`. A developer building
the single most common modern surface — a translucent panel over a photo, which needs
`backdrop-blur` and nothing else — has no token for it.

The absence is worse than it looks because `filter` does not compose the way the rest of CSS does.
Two `filter` declarations in one rule do not add up; the second wins. Tailwind sidesteps this with
a chain of custom properties that one `filter` declaration reads back. `emilia` emits a flat rule
body with no custom-property cascade, so it cannot sidestep it the same way, and a design that
pretends otherwise would produce a rule where `.Filter.Blur.Md` silently deletes `.Filter.Grayscale.100`.
That constraint has to be designed for, not discovered in a test.

`backdrop-filter` doubles every leaf: `§ 13.2` is the same nine families applied to the backdrop
instead of the element. Fifteen rows of the reference become two mirrored sections here.

## Current state

- No `Filter`, no `Backdrop`, no `filter:` or `backdrop-filter:` string anywhere in
  `repository/emilia/src/`.
- `tokensToCss` joins each token's declaration with `;` — `emilia.bp:103`. Two tokens that emit the
  same property name therefore both land in the rule body, and the last one wins at render time.
  This is the composition problem above, stated in emilia's own terms.
- `Color.Hex(value: string)` — `tokens.bp:115` — is the working precedent for a leaf carrying an
  arbitrary string, which is how this front spells `filter-[…]`.

## Mechanism

`Filter` and `Backdrop` are two top-level sections with an identical sub-section tree. Each leaf
maps to one property/value pair; the only difference between the two trees is the property name,
`filter` or `backdrop-filter`. Two sub-dispatchers, `filterTokenToCss` and `backdropTokenToCss`,
each routing to one shared shape.

The `FilterRaw` / `BackdropRaw` escape hatches are top-level `Token` variants, not leaves inside
`Filter` — see Step 1.

**The composition rule, and how front 56 settles it.** Tailwind's
`blur-sm grayscale brightness-110` (`§ 13.1`, "Composição de filtros") compiles to three utilities
that chain through `--tw-blur`, `--tw-grayscale` and `--tw-brightness` into a single `filter`
declaration. The first draft of this front called that inexpressible; front 56's `Rule.declarations`
makes it expressible, and this is how it lands.

Each filter leaf emits **two** declarations: the custom property for its own family, and the one
`filter` shorthand that reads every family back.

```
.Filter.Blur.Sm        -> --tw-blur:blur(var(--blur-sm));filter:var(--tw-filter)
.Filter.Grayscale.100  -> --tw-grayscale:grayscale(100%);filter:var(--tw-filter)
```

where `--tw-filter` is a theme entry (front 54) composing the nine family variables in Tailwind's
order. Two `Filter` tokens in one list therefore write two different custom properties and two
identical `filter:` declarations into the **same** `Rule.declarations` — the duplicate shorthand is
idempotent, and both families survive. This is the same shape front 46's scroll-snap chain uses, and
the reason it works here and did not before is that `Rule.declarations` is an ordered list of
declarations in one rule rather than a flat string the last writer wins.

The `Raw` leaf stays, for a filter function the token set does not name.

**Where the values come from.** Every property name and value is copied from the reference.
`§ 13.1` writes `filter: blur(var(--blur-sm))`, and that is what this front emits —
`themeVar("blur-sm")` from front 54 returns `var(--blur-sm)`. The literal the row gives in
parentheses (`8px`) is the **theme's** value for that entry, not the dispatcher's: contract `§ 4a`
refuses a dispatcher that resolves a theme variable. `§ 13.2`'s rows use the *same* `--blur-*`
variables, so the backdrop scale reads the same entries.

`§ 13.2` writes `backdrop-brightness-*` with a `*` and never enumerates the steps. The steps are
taken from that family's own row in `§ 13.1` — the same document, one section earlier — and
`backdrop-opacity-*`, which has no `§ 13.1` counterpart, takes the fifteen-step scale from
`§ 12.3`. Both derivations are stated in the tables below so a reviewer can check them without
reading this paragraph.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`). The **value** is byte-equal to the reference; the separator is emilia's.

## Steps

### Step 1 — `Filter.Blur` and the filter scales

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `blur-none` | `.Filter.Blur.None` | `filter:none` |
| `blur-xs` | `.Filter.Blur.Xs` | `--tw-blur:blur(var(--blur-xs));filter:var(--tw-filter)` |
| `blur-sm` | `.Filter.Blur.Sm` | `--tw-blur:blur(var(--blur-sm));filter:var(--tw-filter)` |
| `blur-md` | `.Filter.Blur.Md` | `--tw-blur:blur(var(--blur-md));filter:var(--tw-filter)` |
| `blur-lg` | `.Filter.Blur.Lg` | `--tw-blur:blur(var(--blur-lg));filter:var(--tw-filter)` |
| `blur-xl` | `.Filter.Blur.Xl` | `--tw-blur:blur(var(--blur-xl));filter:var(--tw-filter)` |
| `blur-2xl` | `.Filter.Blur.X2xl` | `--tw-blur:blur(var(--blur-2xl));filter:var(--tw-filter)` |
| `blur-3xl` | `.Filter.Blur.X3xl` | `--tw-blur:blur(var(--blur-3xl));filter:var(--tw-filter)` |
| `brightness-0` | `.Filter.Brightness.0` | `filter:brightness(0)` |
| `brightness-50` | `.Filter.Brightness.50` | `filter:brightness(.5)` |
| `brightness-75` | `.Filter.Brightness.75` | `filter:brightness(.75)` |
| `brightness-90` | `.Filter.Brightness.90` | `filter:brightness(.9)` |
| `brightness-95` | `.Filter.Brightness.95` | `filter:brightness(.95)` |
| `brightness-100` | `.Filter.Brightness.100` | `filter:brightness(1)` |
| `brightness-105` | `.Filter.Brightness.105` | `filter:brightness(1.05)` |
| `brightness-110` | `.Filter.Brightness.110` | `filter:brightness(1.1)` |
| `brightness-125` | `.Filter.Brightness.125` | `filter:brightness(1.25)` |
| `brightness-150` | `.Filter.Brightness.150` | `filter:brightness(1.5)` |
| `brightness-200` | `.Filter.Brightness.200` | `filter:brightness(2)` |
| `contrast-0` | `.Filter.Contrast.0` | `filter:contrast(0)` |
| `contrast-50` | `.Filter.Contrast.50` | `filter:contrast(.5)` |
| `contrast-75` | `.Filter.Contrast.75` | `filter:contrast(.75)` |
| `contrast-100` | `.Filter.Contrast.100` | `filter:contrast(1)` |
| `contrast-125` | `.Filter.Contrast.125` | `filter:contrast(1.25)` |
| `contrast-150` | `.Filter.Contrast.150` | `filter:contrast(1.5)` |
| `contrast-200` | `.Filter.Contrast.200` | `filter:contrast(2)` |
| `grayscale-0` | `.Filter.Grayscale.0` | `filter:grayscale(0)` |
| `grayscale` | `.Filter.Grayscale.100` | `filter:grayscale(100%)` |
| `hue-rotate-0` | `.Filter.HueRotate.0` | `filter:hue-rotate(0deg)` |
| `hue-rotate-15` | `.Filter.HueRotate.15` | `filter:hue-rotate(15deg)` |
| `hue-rotate-30` | `.Filter.HueRotate.30` | `filter:hue-rotate(30deg)` |
| `hue-rotate-60` | `.Filter.HueRotate.60` | `filter:hue-rotate(60deg)` |
| `hue-rotate-90` | `.Filter.HueRotate.90` | `filter:hue-rotate(90deg)` |
| `hue-rotate-180` | `.Filter.HueRotate.180` | `filter:hue-rotate(180deg)` |
| `invert-0` | `.Filter.Invert.0` | `filter:invert(0)` |
| `invert` | `.Filter.Invert.100` | `filter:invert(100%)` |
| `saturate-0` | `.Filter.Saturate.0` | `filter:saturate(0)` |
| `saturate-50` | `.Filter.Saturate.50` | `filter:saturate(.5)` |
| `saturate-100` | `.Filter.Saturate.100` | `filter:saturate(1)` |
| `saturate-150` | `.Filter.Saturate.150` | `filter:saturate(1.5)` |
| `saturate-200` | `.Filter.Saturate.200` | `filter:saturate(2)` |
| `sepia-0` | `.Filter.Sepia.0` | `filter:sepia(0)` |
| `sepia` | `.Filter.Sepia.100` | `filter:sepia(100%)` |

The remaining forty rows follow the same two-declaration shape: the family's own `--tw-<family>`
custom property carrying the function call from the reference's column, then
`filter:var(--tw-filter)`. The table's third column shows only the function for those rows, to keep
it readable; the emitted string is `--tw-brightness:brightness(.5);filter:var(--tw-filter)` and so
on, and the test file asserts the whole thing.

`brightness-50` emits `brightness(.5)`, not `brightness(0.5)` — the reference writes the leading dot
off, and byte-equality is the gate.

**Dispatcher shape.** Per contract `§ 4a`:

```bp
fn filterTokenToCss(t: Token.Filter, th: Theme) -> string
fn backdropTokenToCss(t: Token.Backdrop, th: Theme) -> string
```

Neither needs a selector outside its own class, so both keep the declaration-string form; a
multi-declaration token is a `;`-joined string, which is exactly what the two-declaration shape
above produces.

```bp
pub type Token {
    // ── front 42 · filters ───────────────────────────────────────────────
    Filter {
        Blur {
            None,
            Xs,
            Sm,
            Md,
            Lg,
            Xl,
            X2xl,
            X3xl,
        }
        Brightness {
            0,
            50,
            75,
            90,
            95,
            100,
            105,
            110,
            125,
            150,
            200,
        }
    }

    // Arbitrary values are TOP-LEVEL variants, never section leaves — a payload
    // leaf inside a section cannot be constructed by any spelling
    // (`language-gaps.md` row 52, contract `§ 4a`).
    FilterRaw(value: string),
    BackdropRaw(value: string),
}
```

**Why `FilterRaw` and `BackdropRaw` sit at the top of `Token`.** A payload leaf nested inside an enum
section cannot be constructed by any spelling — verified against the real compiler,
`language-gaps.md` row 52. `Token.Filter.Raw("blur(8px)")` reports
`'Raw' is not declared in any behavior implemented for 'Token'`. Contract `§ 4a` puts every
payload-carrying variant at the top level with builtin-typed fields, and the name keeps the path it
would have had, flattened. This matters more here than in most fronts: `FilterRaw` is the escape
hatch for a filter function the token set does not name, so a spelling that does not compile would
close the only door.

**Acceptance:**
- [ ] All forty-three rows above have an arm; every `case` is exhaustive with no `_`.
- [ ] `filterTokenToCss(.Brightness.50, th)` returns
      `--tw-brightness:brightness(.5);filter:var(--tw-filter)` — a leading `0` in `.5` fails.
- [ ] `filterTokenToCss(.Blur.X2xl, th)` returns `--tw-blur:blur(var(--blur-2xl));filter:var(--tw-filter)`;
      no `px` literal appears in any `Filter` arm, because the blur scale is a theme entry.
- [ ] Every non-`None` arm ends in `filter:var(--tw-filter)`, so two filter tokens in one rule
      compose instead of overwriting.
- [ ] `.Filter.Grayscale.100`, `.Filter.Invert.100` and `.Filter.Sepia.100` carry the `%` sign;
      `.Filter.Brightness.100` does not.

### Step 2 — `Filter.DropShadow`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `drop-shadow-none` | `.Filter.DropShadow.None` | `filter:drop-shadow(none)` |
| `drop-shadow-xs` | `.Filter.DropShadow.Xs` | `filter:drop-shadow(var(--drop-shadow-xs))` |
| `drop-shadow-sm` | `.Filter.DropShadow.Sm` | `filter:drop-shadow(var(--drop-shadow-sm))` |
| `drop-shadow-md` | `.Filter.DropShadow.Md` | `filter:drop-shadow(var(--drop-shadow-md))` |
| `drop-shadow-lg` | `.Filter.DropShadow.Lg` | `filter:drop-shadow(var(--drop-shadow-lg))` |
| `drop-shadow-xl` | `.Filter.DropShadow.Xl` | `filter:drop-shadow(var(--drop-shadow-xl))` |
| `drop-shadow-2xl` | `.Filter.DropShadow.X2xl` | `filter:drop-shadow(var(--drop-shadow-2xl))` |

`--drop-shadow-*` has no literal anywhere in the reference, and it does not need one: these are
`themeVar("drop-shadow-md")` lookups from front 54 and the literals are theme entries a project
composes through `extend`. The emitted form is the two-declaration shape,
`--tw-drop-shadow:drop-shadow(var(--drop-shadow-md));filter:var(--tw-filter)`; the table's third
column shows only the function.

**Acceptance:**
- [ ] `filterTokenToCss(.DropShadow.Md, th)` returns
      `--tw-drop-shadow:drop-shadow(var(--drop-shadow-md));filter:var(--tw-filter)`.
- [ ] `.Filter.DropShadow.None` returns `filter:drop-shadow(none)` — a keyword, not a theme lookup.

### Step 3 — the `Backdrop` mirror

Same tree, `backdrop-filter` instead of `filter`. `§ 13.2` enumerates only the blur scale and writes
the other eight families as `backdrop-<family>-*`; each `*` expands to that family's own steps from
`§ 13.1`, and `backdrop-opacity-*`, which `§ 13.1` has no counterpart for, takes the fifteen-step
scale from `§ 12.3`.

| Tailwind utility | emilia token | CSS emitted | steps from |
|---|---|---|---|
| `backdrop-blur-none` | `.Backdrop.Blur.None` | `backdrop-filter:none` | `§ 13.2` |
| `backdrop-blur-sm` | `.Backdrop.Blur.Sm` | `--tw-backdrop-blur:blur(var(--blur-sm));backdrop-filter:var(--tw-backdrop-filter)` | `§ 13.2` |
| `backdrop-blur-md` | `.Backdrop.Blur.Md` | `blur(var(--blur-md))` | `§ 13.2` |
| `backdrop-blur-lg` | `.Backdrop.Blur.Lg` | `blur(var(--blur-lg))` | `§ 13.2` |
| `backdrop-blur-xl` | `.Backdrop.Blur.Xl` | `blur(var(--blur-xl))` | `§ 13.2` |
| `backdrop-blur-2xl` | `.Backdrop.Blur.X2xl` | `blur(var(--blur-2xl))` | `§ 13.2` |
| `backdrop-blur-3xl` | `.Backdrop.Blur.X3xl` | `blur(var(--blur-3xl))` | `§ 13.2` |
| `backdrop-brightness-110` | `.Backdrop.Brightness.110` | `brightness(1.1)` | `§ 13.1` steps |
| `backdrop-contrast-125` | `.Backdrop.Contrast.125` | `contrast(1.25)` | `§ 13.1` steps |
| `backdrop-grayscale` | `.Backdrop.Grayscale.100` | `grayscale(100%)` | `§ 13.1` steps |
| `backdrop-hue-rotate-90` | `.Backdrop.HueRotate.90` | `hue-rotate(90deg)` | `§ 13.1` steps |
| `backdrop-invert` | `.Backdrop.Invert.100` | `invert(100%)` | `§ 13.1` steps |
| `backdrop-saturate-150` | `.Backdrop.Saturate.150` | `saturate(1.5)` | `§ 13.1` steps |
| `backdrop-sepia` | `.Backdrop.Sepia.100` | `sepia(100%)` | `§ 13.1` steps |
| `backdrop-opacity-0` | `.Backdrop.Opacity.0` | `opacity(0)` | `§ 12.3` steps |
| `backdrop-opacity-50` | `.Backdrop.Opacity.50` | `opacity(0.5)` | `§ 12.3` steps |
| `backdrop-opacity-100` | `.Backdrop.Opacity.100` | `opacity(1)` | `§ 12.3` steps |
| `backdrop-[…]` | `Token.BackdropRaw(value: v)` — **top-level** | `backdrop-filter:<v>` | — |

The first `Blur` row shows the full emitted string; every row below it shows only the function, and
the emitted form is `--tw-backdrop-<family>:<function>;backdrop-filter:var(--tw-backdrop-filter)`.

`Backdrop` carries no `DropShadow`: `§ 13.2` has no `backdrop-drop-shadow-*` row, and the front does
not invent one.

**Acceptance:**
- [ ] `Backdrop` has nine sub-sections — `Blur`, `Brightness`, `Contrast`, `Grayscale`, `HueRotate`,
      `Invert`, `Opacity`, `Saturate`, `Sepia` — plus `Raw` as a leaf, and no `DropShadow`.
- [ ] Every non-blur `Backdrop` leaf has a `Filter` twin with the same name, and the two outputs
      differ only in the `backdrop-` prefix — checked by a test that walks both lists.
- [ ] `Backdrop.Opacity` has the fifteen steps of `§ 12.3`, not the five of `emilia`'s existing
      `Effect.Opacity`.

### Step 4 — two new arms in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, reached through `declSheet(...)`.

```bp
        Filter(_inner) -> declSheet(filterTokenToCss(_inner, th));
        Backdrop(_inner) -> declSheet(backdropTokenToCss(_inner, th));
        FilterRaw(value) -> declSheet("filter:" + value);
        BackdropRaw(value) -> declSheet("backdrop-filter:" + value);
```

Four arms, not two: the two top-level payload variants are siblings of `Filter`, not leaves inside
it. Each destructures by its declared field name (`value`) — a positional bind type-checks and is
`undefined` at run time.

**Acceptance:**
- [ ] The four arms sit between front 41's block and front 43's, in that order.
- [ ] Each arm is one `declSheet(...)` call; none builds a `Rule` or a `Sheet` by hand.
- [ ] `Token.FilterRaw(value: "blur(8px) grayscale(100%)")` **constructs** — a test builds one.
- [ ] No section in this front's `tokens.bp` block contains a payload leaf.
- [ ] `tokenToSheet` still has no `_` arm.
- [ ] The two `--tw-filter` / `--tw-backdrop-filter` composition entries are owed to front 54's
      theme and are named in this front's `TODO.md` as a dependency, not redefined here.

## Examples

- [`./examples/filters-example.bp`](./examples/filters-example.bp) — the `Filter` and `Backdrop`
  catalogues as typed `Token[]` lists, the single-`Filter`-per-list rule shown as working code and
  as the `Raw` composition that replaces it, then a frosted navigation bar that uses
  `backdrop-blur` and `backdrop-saturate` together over a dimmed hero image.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's two escape hatches, which the first draft wrote as `Filter.Raw` and `Backdrop.Raw`. Load-bearing here: they are the only way to name a filter function the token set does not cover | the variants move to the **top level** of `Token` per contract `§ 4a`: `Token.FilterRaw(value: string)` and `Token.BackdropRaw(value: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same two, now top-level: `[.FilterRaw("blur(8px)")]` still trips the parser | a wrapper fn returning the token (`fn rawFilter(v: string) -> Token { return Token.FilterRaw(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| ~~Composing two filter families without `Raw`~~ | **Closed by front 56.** `Rule.declarations` is an ordered list of declarations in one rule, so the `--tw-<family>` writer and the `filter:var(--tw-filter)` reader coexist and two filter tokens compose. See *Mechanism*. What front 42 still owes front 54 is the `--tw-filter` and `--tw-backdrop-filter` composition entries. |
| ~~`--drop-shadow-*` literals~~ | **Closed by front 54.** `themeVar("drop-shadow-md")` like every other scale here; the literals are theme entries, not dispatcher constants. |

## Test plan

`repository/emilia/test/filters_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert filterTokenToCss(<token>, th) == "<css>"` per row of
   the three tables, asserting the **whole** two-declaration string and not only the function. A
   table row and a test line are the same fact written twice.
2. **The leading-dot decimals.** `brightness(.5)`, `saturate(.5)`, `contrast(.75)` — asserted as
   exact strings, because a normaliser that turns them into `0.5` would pass a looser test and fail
   byte-equality with Tailwind.
3. **The mirror is a mirror.** For each of the eight shared families, the `Backdrop` output equals
   `"backdrop-" + <the Filter output>`. One test, eight assertions, and it catches a typo in either
   tree.
4. **The composition, asserted as composition.** `[.Filter.Blur.Sm, .Filter.Grayscale.100]`
   produces a `Rule.declarations` carrying `--tw-blur`, `--tw-grayscale` and `filter:var(--tw-filter)`
   — both families present, the shorthand idempotent. The first draft of this front asserted the
   opposite (last-wins); that test is replaced, not kept.
5. **No resolved theme literals.** A test greps this front's block of `emilia.bp` for `px)` and
   fails if it finds one — the blur scale belongs to the theme.
6. **Variant nesting.** `Token.Hover([.Filter.Brightness.110])` reaches front 34's `nestVariant`
   with the inner declaration this front emits. This front asserts its declaration, not the wrap.
7. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, which is
   the condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Filter` and `Backdrop` exist as top-level sections, fenced by a `front 42` banner in
      `tokens.bp` and appended after front 41's block.
- [ ] `filterTokenToCss`, `backdropTokenToCss` and their sub-dispatchers are fenced by a `front 42`
      banner in `emilia.bp`, appended after front 41's block, and both take `th: Theme` per contract
      `§ 4a`.
- [ ] Two arms added to `tokenToSheet`, each a `declSheet(...)` call, in front-number order, and no
      other line of that `case` moved.
- [ ] Every non-`None` arm emits the family custom property **and** the shorthand, so two filter
      tokens compose; the composition is stated in the `tokens.bp` docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the two new sections and the two-declaration shape.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
