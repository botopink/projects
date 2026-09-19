# Front 41 — emilia effects

**Track:** D emilia
**Priority:** high — a card without a shadow and a modal without a backdrop blend read as unfinished, and today `Effect.Shadow.Sm` emits `box-shadow:sm`, which no browser accepts
**Target:** comptime
**Wave:** 1
**Depends on:** 33 (the palette the coloured-shadow escape hatch resolves against), 34 (modifiers — the examples use the six that already exist)
**Owns:** token sections `Effect`, `Blend`, `Mask` in `repository/emilia/src/tokens.bp` · dispatcher `effectTokenToCss` (plus `blendTokenToCss` and `maskTokenToCss`, its two siblings) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/effects_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`; `repository/emilia/src/root.bp` beyond nothing — this front adds no module
**Reference:** `TAILWIND_CSS_DOCS.md § 12. Efeitos` (shadow scale values from `§ 21.4 Sombras Padrão`) · https://tailwindcss.com/docs/box-shadow
**Replaces:** `1.0.8-beta/07-emilia-effects`

---

## Problem

`emilia` has an `Effect` section, and it is two leaves deep and one of them is wrong.
`repository/emilia/src/tokens.bp:248-262` declares `Effect { Shadow { Sm, Md, Lg, Xl }, Opacity { 0, 25, 50, 75, 100 } }`, and
`repository/emilia/src/emilia.bp:364-372` lowers those four shadows to the strings
`"box-shadow:sm"`, `"box-shadow:md"`, `"box-shadow:lg"`, `"box-shadow:xl"`. Those are not CSS
values. A page that uses `.Effect.Shadow.Md` today gets a declaration the browser discards, and
nothing in the test suite catches it because no test asserts the shadow body.

Beyond the four broken leaves, the whole of Tailwind's effects surface is absent. There is no
`text-shadow`, no inset shadow, no blend mode of either kind, and no mask family. The opacity scale
stops at five steps where Tailwind has fifteen. A developer who wants a translucent overlay
(`opacity-60`), a dimmed photo caption (`mix-blend-multiply`) or a fade-to-transparent image edge
(`mask-image`) has no token to reach for and no escape hatch short of leaving `emilia` and hand-
writing a stylesheet, which defeats the point of the library.

This front replaces the four wrong strings, extends the two existing scales, and adds the three
families that are missing. It is the largest single correction in track D: every other emilia front
adds new surface, and this one also fixes shipped output.

## Current state

- `Token.Effect` exists with exactly two sub-sections — `tokens.bp:248-262`.
- `effectTokenToCss` exists and routes to `shadowToCss` / `opacityToCss` — `emilia.bp:356-362`.
- `shadowToCss` emits invalid CSS — `emilia.bp:364-372`.
- `opacityToCss` is correct for the five steps it covers — `emilia.bp:373-382`.
- No `Blend` section, no `Mask` section, no `text-shadow` anywhere in the repository.
- `tokensToCss` joins declarations with `;` — `emilia.bp:103`. A token whose body is itself two
  declarations (`transition-all` in front 44, and nothing here) composes without special handling.

## Mechanism

Tailwind's effects are, with one exception, a class name mapped to a single property/value pair.
The exception is `shadow-<color>/<opacity>`, which sets a custom property that the shadow utility
reads back — a two-step protocol `emilia` has no place for, because `emilia` emits one flat rule
body per class and has no `@theme` layer and no custom-property cascade.

The mapping onto botopink is the shape every emilia section already uses: a nested section per CSS
property family, arrow-armed `case` dispatchers one per section level, and a string return. Three
new top-level variants (`Effect` already exists; `Blend` and `Mask` are added) with three sub-
dispatchers, each fenced by its own banner in `tokens.bp` and `emilia.bp`.

**Where the values come from, and the one place emilia differs from Tailwind.** Every property name
and every value is copied from `TAILWIND_CSS_DOCS.md`. The document's "Propriedade CSS" column
writes `box-shadow: var(--shadow-sm)`; `§ 21.4` then gives the literal that variable holds. `emilia`
registers a bare rule body with no `@theme` block in front of it, so a `var(--shadow-sm)` reference
would resolve to nothing at render time. Therefore:

- where the reference gives the literal (`§ 21.4` shadows, `§ 21.6` animations, `§ 13.1` blur px,
  `§ 16.2` perspective px), `emilia` emits the literal;
- where it does not (`--inset-shadow-*`, `--text-shadow-*`), `emilia` emits the `var(--…)`
  reference verbatim, exactly as the column writes it, and this front records the dependency on a
  future theme-preamble front rather than inventing a value.

The second difference is cosmetic and applies to the whole library: `emilia` writes `prop:value`
with no space after the colon (`emilia.bp:108-115`). The **value** is byte-equal to the reference;
the separator is emilia's, and it is the same separator every shipped token already uses.

**Arbitrary values.** Tailwind's `shadow-[0_0_0_1px_red]` bracket syntax maps onto an enum leaf with
a string payload — the shape `Color.Hex(value: string)` already proves works (`tokens.bp:115`).
Every section this front adds carries a `Raw(value: string)` leaf for that reason. See *Language
gaps* for the parser constraint that makes `Raw` awkward to write inline.

## Steps

### Step 1 — replace the four broken shadow bodies and extend the scale

`shadow-2xs` … `shadow-2xl` plus `none` and `inner`. The four existing leaf names keep their
spelling and change their output; four leaves are added.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `shadow-2xs` | `.Effect.Shadow.X2xs` | `box-shadow:0 1px rgb(0 0 0 / 0.05)` |
| `shadow-xs` | `.Effect.Shadow.Xs` | `box-shadow:0 1px 2px 0 rgb(0 0 0 / 0.05)` |
| `shadow-sm` | `.Effect.Shadow.Sm` | `box-shadow:0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)` |
| `shadow-md` | `.Effect.Shadow.Md` | `box-shadow:0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` |
| `shadow-lg` | `.Effect.Shadow.Lg` | `box-shadow:0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` |
| `shadow-xl` | `.Effect.Shadow.Xl` | `box-shadow:0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)` |
| `shadow-2xl` | `.Effect.Shadow.X2xl` | `box-shadow:0 25px 50px -12px rgb(0 0 0 / 0.25)` |
| `shadow-none` | `.Effect.Shadow.None` | `box-shadow:none` |
| `shadow-inner` | `.Effect.Shadow.Inner` | `box-shadow:inset 0 2px 4px 0 rgb(0 0 0 / 0.05)` |
| `shadow-[…]` | `Token.Effect.Shadow.Raw(value: v)` | `box-shadow:<v>` |
| `inset-shadow-2xs` | `.Effect.InsetShadow.X2xs` | `box-shadow:inset var(--inset-shadow-2xs)` |
| `inset-shadow-xs` | `.Effect.InsetShadow.Xs` | `box-shadow:inset var(--inset-shadow-xs)` |
| `inset-shadow-sm` | `.Effect.InsetShadow.Sm` | `box-shadow:inset var(--inset-shadow-sm)` |

```bp
pub type Token {
    // ── front 41 · effects ───────────────────────────────────────────────
    Effect {
        Shadow {
            X2xs,
            Xs,
            Sm,
            Md,
            Lg,
            Xl,
            X2xl,
            None,
            Inner,
            Raw(value: string),
        }
        InsetShadow {
            X2xs,
            Xs,
            Sm,
        }
    }
}
```

**Acceptance:**
- [ ] `tokensToCss([.Effect.Shadow.Md])` returns `box-shadow:0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` — the string `box-shadow:md` appears nowhere in `repository/emilia/src/`.
- [ ] All nine bare shadow leaves plus the three inset leaves have an arm in `shadowToCss` / `insetShadowToCss`; the `case` is exhaustive with no `_` arm.
- [ ] `.Effect.Shadow.Sm`, `.Md`, `.Lg`, `.Xl` still type-check at every existing call site — the leaf names did not move.
- [ ] Each of the twelve values is character-identical to its row above, which is character-identical to `TAILWIND_CSS_DOCS.md § 21.4` / `§ 12.1`.

### Step 2 — text-shadow

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `text-shadow-2xs` | `.Effect.TextShadow.X2xs` | `text-shadow:var(--text-shadow-2xs)` |
| `text-shadow-xs` | `.Effect.TextShadow.Xs` | `text-shadow:var(--text-shadow-xs)` |
| `text-shadow-sm` | `.Effect.TextShadow.Sm` | `text-shadow:var(--text-shadow-sm)` |
| `text-shadow-md` | `.Effect.TextShadow.Md` | `text-shadow:var(--text-shadow-md)` |
| `text-shadow-lg` | `.Effect.TextShadow.Lg` | `text-shadow:var(--text-shadow-lg)` |
| `text-shadow-none` | `.Effect.TextShadow.None` | `text-shadow:none` |
| `text-shadow-[…]` | `Token.Effect.TextShadow.Raw(value: v)` | `text-shadow:<v>` |

`§ 12.2` names the variables and no section of the reference gives their literals. The emitted
declaration is therefore the reference's column verbatim, and the token is only useful once a theme
preamble defines `--text-shadow-*`. This is recorded under *Deferred*, not fabricated.

**Acceptance:**
- [ ] `tokensToCss([.Effect.TextShadow.Sm])` returns `text-shadow:var(--text-shadow-sm)`.
- [ ] `.Effect.TextShadow.None` returns `text-shadow:none`, which needs no theme.
- [ ] `textShadowToCss` is exhaustive over the seven leaves.

### Step 3 — the full opacity scale

Existing leaves `0 25 50 75 100` keep their output; ten leaves are added.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `opacity-0` | `.Effect.Opacity.0` | `opacity:0` |
| `opacity-5` | `.Effect.Opacity.5` | `opacity:0.05` |
| `opacity-10` | `.Effect.Opacity.10` | `opacity:0.1` |
| `opacity-20` | `.Effect.Opacity.20` | `opacity:0.2` |
| `opacity-25` | `.Effect.Opacity.25` | `opacity:0.25` |
| `opacity-30` | `.Effect.Opacity.30` | `opacity:0.3` |
| `opacity-40` | `.Effect.Opacity.40` | `opacity:0.4` |
| `opacity-50` | `.Effect.Opacity.50` | `opacity:0.5` |
| `opacity-60` | `.Effect.Opacity.60` | `opacity:0.6` |
| `opacity-70` | `.Effect.Opacity.70` | `opacity:0.7` |
| `opacity-75` | `.Effect.Opacity.75` | `opacity:0.75` |
| `opacity-80` | `.Effect.Opacity.80` | `opacity:0.8` |
| `opacity-90` | `.Effect.Opacity.90` | `opacity:0.9` |
| `opacity-95` | `.Effect.Opacity.95` | `opacity:0.95` |
| `opacity-100` | `.Effect.Opacity.100` | `opacity:1` |

A numeric leaf is declared as bare digits, written `.Effect.Opacity.60` in expression position, and
matched as `__60` in a `case` pattern — three spellings for one leaf, and the existing
`opacityToCss` at `emilia.bp:373-382` is the model to copy.

**Acceptance:**
- [ ] Fifteen arms in `opacityToCss`, each matching `__N`.
- [ ] `tokensToCss([.Effect.Opacity.60])` returns `opacity:0.6` — not `opacity:.6`.
- [ ] The five pre-existing leaves return exactly what they returned before this front.

### Step 4 — blend modes

`Blend` is a new top-level section with two sub-sections, because `mix-blend-mode` and
`background-blend-mode` take the same seventeen values (`§ 12.5`: "Mesmas opções que
mix-blend-mode, mas com prefixo `bg-blend-*`").

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `mix-blend-normal` | `.Blend.Mix.Normal` | `mix-blend-mode:normal` |
| `mix-blend-multiply` | `.Blend.Mix.Multiply` | `mix-blend-mode:multiply` |
| `mix-blend-screen` | `.Blend.Mix.Screen` | `mix-blend-mode:screen` |
| `mix-blend-overlay` | `.Blend.Mix.Overlay` | `mix-blend-mode:overlay` |
| `mix-blend-darken` | `.Blend.Mix.Darken` | `mix-blend-mode:darken` |
| `mix-blend-lighten` | `.Blend.Mix.Lighten` | `mix-blend-mode:lighten` |
| `mix-blend-color-dodge` | `.Blend.Mix.ColorDodge` | `mix-blend-mode:color-dodge` |
| `mix-blend-color-burn` | `.Blend.Mix.ColorBurn` | `mix-blend-mode:color-burn` |
| `mix-blend-hard-light` | `.Blend.Mix.HardLight` | `mix-blend-mode:hard-light` |
| `mix-blend-soft-light` | `.Blend.Mix.SoftLight` | `mix-blend-mode:soft-light` |
| `mix-blend-difference` | `.Blend.Mix.Difference` | `mix-blend-mode:difference` |
| `mix-blend-exclusion` | `.Blend.Mix.Exclusion` | `mix-blend-mode:exclusion` |
| `mix-blend-hue` | `.Blend.Mix.Hue` | `mix-blend-mode:hue` |
| `mix-blend-saturation` | `.Blend.Mix.Saturation` | `mix-blend-mode:saturation` |
| `mix-blend-color` | `.Blend.Mix.Color` | `mix-blend-mode:color` |
| `mix-blend-luminosity` | `.Blend.Mix.Luminosity` | `mix-blend-mode:luminosity` |
| `mix-blend-plus-lighter` | `.Blend.Mix.PlusLighter` | `mix-blend-mode:plus-lighter` |
| `bg-blend-normal` | `.Blend.Bg.Normal` | `background-blend-mode:normal` |
| `bg-blend-multiply` | `.Blend.Bg.Multiply` | `background-blend-mode:multiply` |
| `bg-blend-<rest>` | `.Blend.Bg.<Rest>` | `background-blend-mode:<rest>` — the seventeen values above |

**Acceptance:**
- [ ] `Blend` has exactly two sub-sections and each has exactly seventeen leaves.
- [ ] `blendTokenToCss` routes `Mix` and `Bg` to two sub-dispatchers that differ only in the
      property name they prepend.
- [ ] `tokensToCss([.Blend.Mix.PlusLighter])` returns `mix-blend-mode:plus-lighter`.

### Step 5 — the mask family

`§ 12.6` lists twenty utilities across nine properties. Every one is a one-to-one mapping.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `mask-clip-border` | `.Mask.Clip.Border` | `mask-clip:border-box` |
| `mask-clip-padding` | `.Mask.Clip.Padding` | `mask-clip:padding-box` |
| `mask-clip-content` | `.Mask.Clip.Content` | `mask-clip:content-box` |
| `mask-composite-add` | `.Mask.Composite.Add` | `mask-composite:add` |
| `mask-composite-subtract` | `.Mask.Composite.Subtract` | `mask-composite:subtract` |
| `mask-composite-intersect` | `.Mask.Composite.Intersect` | `mask-composite:intersect` |
| `mask-composite-exclude` | `.Mask.Composite.Exclude` | `mask-composite:exclude` |
| `mask-image-none` | `.Mask.Image.None` | `mask-image:none` |
| `mask-image-[…]` | `Token.Mask.Image.Raw(value: v)` | `mask-image:<v>` |
| `mask-mode-alpha` | `.Mask.Mode.Alpha` | `mask-mode:alpha` |
| `mask-mode-luminance` | `.Mask.Mode.Luminance` | `mask-mode:luminance` |
| `mask-origin-border` | `.Mask.Origin.Border` | `mask-origin:border-box` |
| `mask-origin-padding` | `.Mask.Origin.Padding` | `mask-origin:padding-box` |
| `mask-origin-content` | `.Mask.Origin.Content` | `mask-origin:content-box` |
| `mask-position-center` | `.Mask.Position.Center` | `mask-position:center` |
| `mask-repeat-no-repeat` | `.Mask.Repeat.NoRepeat` | `mask-repeat:no-repeat` |
| `mask-repeat-repeat` | `.Mask.Repeat.Repeat` | `mask-repeat:repeat` |
| `mask-size-cover` | `.Mask.Size.Cover` | `mask-size:cover` |
| `mask-size-contain` | `.Mask.Size.Contain` | `mask-size:contain` |
| `mask-type-alpha` | `.Mask.Type.Alpha` | `mask-type:alpha` |
| `mask-type-luminance` | `.Mask.Type.Luminance` | `mask-type:luminance` |

**Acceptance:**
- [ ] `Mask` has nine sub-sections: `Clip`, `Composite`, `Image`, `Mode`, `Origin`, `Position`,
      `Repeat`, `Size`, `Type`.
- [ ] `maskTokenToCss` has nine arms and each routes to a sub-dispatcher with no `_` fallback.
- [ ] `tokensToCss([.Mask.Clip.Padding, .Mask.Mode.Luminance])` returns
      `mask-clip:padding-box;mask-mode:luminance` — the `;` join comes from `tokensToCss`, unchanged.

### Step 6 — two new arms in `tokenToCss`

`Effect` already has an arm at `emilia.bp:84`. `Blend` and `Mask` need one each, appended in front-
number order per the `fronts.md` banner convention.

```bp
        Effect(_inner) -> effectTokenToCss(_inner);
        Blend(_inner) -> blendTokenToCss(_inner);
        Mask(_inner) -> maskTokenToCss(_inner);
```

**Acceptance:**
- [ ] The two arms sit between front 40's arm and front 42's, in that order.
- [ ] The modifier arms (`Hover`, `Focus`, `Active`, `Md`, `Lg`, `Xl`) remain last in the `case`.
- [ ] `tokenToCss` still has no `_` arm — a token with no arm is a compile error, not a silent `""`.

## Examples

- [`./examples/effects-example.bp`](./examples/effects-example.bp) — the full `Effect` / `Blend` /
  `Mask` catalogue as typed `Token[]` lists, then a photo-card component that layers a shadow, a
  blend mode and an opacity under a `Hover` modifier and flushes the sheet.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Effect.Shadow.Raw("0 0 0 1px red")]` trips the parser | every `Raw(value: string)` leaf this front adds — the arbitrary-value escape hatch | wrap the constructor in a fn (`fn rawShadow(v: string) -> Token { return Token.Effect.Shadow.Raw(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` already documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Effect.Shadow.Raw("0 0 0 1px red")];` |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| `shadow-red-500/50` (coloured shadow with opacity) | `§ 12.1` gives the class and the prose "Cor da sombra com opacidade" and **no property/value pair**. Upstream it is a two-step protocol: the colour utility sets `--tw-shadow-color` and the shadow utility reads it back. `emilia` emits one flat rule body with no custom-property cascade, so there is nothing to read it back. A token that emitted `--tw-shadow-color:#ef4444` alone would be inert. Needs a theme/custom-property front. |
| `--inset-shadow-*` and `--text-shadow-*` literals | The reference names the variables and never gives their values. The tokens emit the `var(--…)` reference verbatim and are inert until a theme preamble front defines them. |

## Test plan

`repository/emilia/test/effects_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence between them is a real bug, not a
coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the five
   tables above. This is the byte-equality gate; a table row and a test line are the same fact
   written twice, and a mismatch fails the build.
2. **The regression this front exists for.** `assert tokensToCss([.Effect.Shadow.Md]).startsWith("box-shadow:0 4px")`
   plus `assert tokensToCss([.Effect.Shadow.Md]) != "box-shadow:md"`.
3. **Composition.** A three-token list joins with `;` in list order, and the same list through
   `emilia()` + `await flush()` produces `<style>.e_<hex>{…}</style>` with the declarations in the
   same order — the class name is a function of the body, so order changes the class.
4. **Modifier nesting.** `Token.Hover([.Effect.Shadow.Lg])` wraps as
   `:hover{box-shadow:0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)}`,
   proving the new leaves survive the recursive `tokensToCss` path unchanged.
5. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   the `commonJS` row and the `erlang` row must agree on the `djb2` hash. Every value in this front
   is ASCII, which is the condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Effect` carries `Shadow`, `InsetShadow`, `TextShadow`, `Opacity`; `Blend` and `Mask` exist as
      top-level sections; all three blocks are fenced by a `front 41` banner in `tokens.bp`.
- [ ] `effectTokenToCss`, `blendTokenToCss`, `maskTokenToCss` and their sub-dispatchers are fenced
      by a `front 41` banner in `emilia.bp`, appended after front 40's block.
- [ ] `box-shadow:sm` and its three siblings are gone from the repository.
- [ ] Two arms added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] `repository/emilia/AGENTS.md` records the three new sections and the shadow-body correction.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
