# Front 42 — emilia filters

**Track:** D emilia
**Priority:** medium — no filter token exists at all, so a frosted panel, a dimmed disabled control and a greyed-out avatar each have to leave `emilia` entirely
**Target:** comptime
**Wave:** 1
**Depends on:** none of the emilia fronts directly — `Filter` and `Backdrop` are self-contained scales. Wave 1 places it after wave 0 (33 · 34 · 35) so the `tokenToCss` arms land in front-number order.
**Owns:** token sections `Filter`, `Backdrop` in `repository/emilia/src/tokens.bp` · dispatcher `filterTokenToCss` (and its sibling `backdropTokenToCss`) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/filters_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 13. Filtros` (blur literals inline at `§ 13.1`; the opacity scale mirrored from `§ 12.3`) · https://tailwindcss.com/docs/filter
**Replaces:** `1.0.8-beta/08-emilia-filters`

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

**The composition rule, stated once.** One `Filter` token per token list. Tailwind's
`blur-sm grayscale brightness-110` (`§ 13.1`, "Composição de filtros") compiles to three utilities
that chain through `--tw-blur`, `--tw-grayscale` and `--tw-brightness` into a single `filter`
declaration. `emilia` has no such chain, so the composed form is a single `Raw` leaf:

```bp
val stack: Token[] = [rawFilter("blur(8px) grayscale(100%) brightness(1.1)")];
```

The README's tables and the front's tests say so, and the tests assert the failure mode as well as
the success one: two `Filter` tokens in a list produce two `filter:` declarations, the second wins,
and that is documented behaviour rather than a bug report waiting to happen. Escalating this to a
real composition pass needs a theme/custom-property layer — recorded under *Deferred*.

**Where the values come from.** Every property name and value is copied from the reference.
`§ 13.1` writes `filter: blur(var(--blur-sm))` and then gives the literal in the same row, in
parentheses: `(8px)`. `emilia` registers a bare rule body with no `@theme` block in front of it, so
the `var(--blur-sm)` reference would resolve to nothing at render time; the front therefore emits
the literal the reference itself supplies. `§ 13.2`'s rows use the *same* `--blur-*` variables, so
the backdrop scale resolves to the same seven literals.

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
| `blur-xs` | `.Filter.Blur.Xs` | `filter:blur(4px)` |
| `blur-sm` | `.Filter.Blur.Sm` | `filter:blur(8px)` |
| `blur-md` | `.Filter.Blur.Md` | `filter:blur(12px)` |
| `blur-lg` | `.Filter.Blur.Lg` | `filter:blur(16px)` |
| `blur-xl` | `.Filter.Blur.Xl` | `filter:blur(24px)` |
| `blur-2xl` | `.Filter.Blur.X2xl` | `filter:blur(40px)` |
| `blur-3xl` | `.Filter.Blur.X3xl` | `filter:blur(64px)` |
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

`brightness-50` emits `brightness(.5)`, not `brightness(0.5)` — the reference writes the leading dot
off, and byte-equality is the gate.

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
        Raw(value: string),
    }
}
```

**Acceptance:**
- [ ] All forty-three rows above have an arm; every `case` is exhaustive with no `_`.
- [ ] `tokensToCss([.Filter.Brightness.50])` returns `filter:brightness(.5)` — a leading `0` fails.
- [ ] `tokensToCss([.Filter.Blur.X2xl])` returns `filter:blur(40px)`; no `var(` appears in any
      `Filter` output.
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

`--drop-shadow-*` has no literal anywhere in the reference. Unlike `--blur-*`, `§ 13.1` gives no
parenthesised value, and `§ 21` lists the namespace without its contents. These seven tokens emit
the reference's column verbatim and stay inert until a theme preamble defines the variables —
recorded under *Deferred*, not fabricated.

**Acceptance:**
- [ ] `tokensToCss([.Filter.DropShadow.Md])` returns `filter:drop-shadow(var(--drop-shadow-md))`.
- [ ] `.Filter.DropShadow.None` returns `filter:drop-shadow(none)`, which needs no theme.

### Step 3 — the `Backdrop` mirror

Same tree, `backdrop-filter` instead of `filter`. `§ 13.2` enumerates only the blur scale and writes
the other eight families as `backdrop-<family>-*`; each `*` expands to that family's own steps from
`§ 13.1`, and `backdrop-opacity-*`, which `§ 13.1` has no counterpart for, takes the fifteen-step
scale from `§ 12.3`.

| Tailwind utility | emilia token | CSS emitted | steps from |
|---|---|---|---|
| `backdrop-blur-none` | `.Backdrop.Blur.None` | `backdrop-filter:none` | `§ 13.2` |
| `backdrop-blur-sm` | `.Backdrop.Blur.Sm` | `backdrop-filter:blur(8px)` | `§ 13.2` |
| `backdrop-blur-md` | `.Backdrop.Blur.Md` | `backdrop-filter:blur(12px)` | `§ 13.2` |
| `backdrop-blur-lg` | `.Backdrop.Blur.Lg` | `backdrop-filter:blur(16px)` | `§ 13.2` |
| `backdrop-blur-xl` | `.Backdrop.Blur.Xl` | `backdrop-filter:blur(24px)` | `§ 13.2` |
| `backdrop-blur-2xl` | `.Backdrop.Blur.X2xl` | `backdrop-filter:blur(40px)` | `§ 13.2` |
| `backdrop-blur-3xl` | `.Backdrop.Blur.X3xl` | `backdrop-filter:blur(64px)` | `§ 13.2` |
| `backdrop-brightness-110` | `.Backdrop.Brightness.110` | `backdrop-filter:brightness(1.1)` | `§ 13.1` steps |
| `backdrop-contrast-125` | `.Backdrop.Contrast.125` | `backdrop-filter:contrast(1.25)` | `§ 13.1` steps |
| `backdrop-grayscale` | `.Backdrop.Grayscale.100` | `backdrop-filter:grayscale(100%)` | `§ 13.1` steps |
| `backdrop-hue-rotate-90` | `.Backdrop.HueRotate.90` | `backdrop-filter:hue-rotate(90deg)` | `§ 13.1` steps |
| `backdrop-invert` | `.Backdrop.Invert.100` | `backdrop-filter:invert(100%)` | `§ 13.1` steps |
| `backdrop-saturate-150` | `.Backdrop.Saturate.150` | `backdrop-filter:saturate(1.5)` | `§ 13.1` steps |
| `backdrop-sepia` | `.Backdrop.Sepia.100` | `backdrop-filter:sepia(100%)` | `§ 13.1` steps |
| `backdrop-opacity-0` | `.Backdrop.Opacity.0` | `backdrop-filter:opacity(0)` | `§ 12.3` steps |
| `backdrop-opacity-50` | `.Backdrop.Opacity.50` | `backdrop-filter:opacity(0.5)` | `§ 12.3` steps |
| `backdrop-opacity-100` | `.Backdrop.Opacity.100` | `backdrop-filter:opacity(1)` | `§ 12.3` steps |
| `backdrop-[…]` | `Token.Backdrop.Raw(value: v)` | `backdrop-filter:<v>` | — |

`Backdrop` carries no `DropShadow`: `§ 13.2` has no `backdrop-drop-shadow-*` row, and the front does
not invent one.

**Acceptance:**
- [ ] `Backdrop` has nine sub-sections — `Blur`, `Brightness`, `Contrast`, `Grayscale`, `HueRotate`,
      `Invert`, `Opacity`, `Saturate`, `Sepia` — plus `Raw` as a leaf, and no `DropShadow`.
- [ ] Every non-blur `Backdrop` leaf has a `Filter` twin with the same name, and the two outputs
      differ only in the `backdrop-` prefix — checked by a test that walks both lists.
- [ ] `Backdrop.Opacity` has the fifteen steps of `§ 12.3`, not the five of `emilia`'s existing
      `Effect.Opacity`.

### Step 4 — two new arms in `tokenToCss`

```bp
        Filter(_inner) -> filterTokenToCss(_inner);
        Backdrop(_inner) -> backdropTokenToCss(_inner);
```

**Acceptance:**
- [ ] The two arms sit between front 41's block and front 43's, in that order.
- [ ] `tokenToCss` still has no `_` arm.

## Examples

- [`./examples/filters-example.bp`](./examples/filters-example.bp) — the `Filter` and `Backdrop`
  catalogues as typed `Token[]` lists, the single-`Filter`-per-list rule shown as working code and
  as the `Raw` composition that replaces it, then a frosted navigation bar that uses
  `backdrop-blur` and `backdrop-saturate` together over a dimmed hero image.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Filter.Raw("blur(8px) grayscale(100%)")]` trips the parser | `Filter.Raw` and `Backdrop.Raw` — the only way to compose more than one filter function, so this gap is load-bearing here rather than cosmetic | wrap the constructor in a fn (`fn rawFilter(v: string) -> Token { return Token.Filter.Raw(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Filter.Raw("blur(8px)")];` |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| Composing two filter families without `Raw` | Upstream, `blur-sm grayscale` works because each utility writes a `--tw-*` custom property and one `filter` declaration reads them all back. `emilia` emits a flat rule body with no custom-property cascade; two `Filter` tokens produce two `filter:` declarations and the second wins. Needs a theme/custom-property front before the chain can exist. |
| `--drop-shadow-*` literals | The reference names the variables and never gives their values. The seven `DropShadow` tokens emit the `var(--…)` reference verbatim and are inert until a theme preamble defines them. |

## Test plan

`repository/emilia/test/filters_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the three
   tables. A table row and a test line are the same fact written twice.
2. **The leading-dot decimals.** `brightness(.5)`, `saturate(.5)`, `contrast(.75)` — asserted as
   exact strings, because a normaliser that turns them into `0.5` would pass a looser test and fail
   byte-equality with Tailwind.
3. **The mirror is a mirror.** For each of the eight shared families, the `Backdrop` output equals
   `"backdrop-" + <the Filter output>`. One test, eight assertions, and it catches a typo in either
   tree.
4. **The composition rule, asserted as it actually behaves.** `tokensToCss([.Filter.Blur.Sm, .Filter.Grayscale.100])`
   returns `filter:blur(8px);filter:grayscale(100%)` — two declarations, last-wins at render — and
   the `Raw` form returns the single `filter:blur(8px) grayscale(100%)`. The test documents the
   sharp edge rather than hiding it.
5. **Modifier nesting.** `Token.Hover([.Filter.Brightness.110])` wraps as
   `:hover{filter:brightness(1.1)}`.
6. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   `commonJS` and `erlang` must agree on the `djb2` hash. Every value here is ASCII, which is the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Filter` and `Backdrop` exist as top-level sections, fenced by a `front 42` banner in
      `tokens.bp` and appended after front 41's block.
- [ ] `filterTokenToCss`, `backdropTokenToCss` and their sub-dispatchers are fenced by a `front 42`
      banner in `emilia.bp`, appended after front 41's block.
- [ ] Two arms added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] The single-`Filter`-per-list rule is stated in the `tokens.bp` docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the two new sections and the composition constraint.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
