# Front 41 — emilia effects

**Track:** D emilia
**Priority:** high — a card without a shadow and a modal without a backdrop blend read as unfinished, and today `Effect.Shadow.Sm` emits `box-shadow:sm`, which no browser accepts
**Target:** comptime
**Wave:** 3
**Depends on:** 33 (the palette the coloured-shadow escape hatch resolves against), 34 (modifiers — the examples use the six that already exist)
**Owns:** token sections `Effect`, `Blend`, `Mask` in `repository/emilia/src/tokens.bp` · dispatcher `effectTokenToCss` (plus `blendTokenToCss` and `maskTokenToCss`, its two siblings) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/effects_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, the class-name hash (std `content_hash.contentHash` since decision 116), `register`, `flushSheet`; `repository/emilia/src/root.bp` beyond nothing — this front adds no module
**Reference:** `TAILWIND_CSS_DOCS.md § 12. Efeitos` (shadow scale values from `§ 21.4 Sombras Padrão`) · https://tailwindcss.com/docs/box-shadow

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

**Where the values come from.** Every property name and every value is copied from
`TAILWIND_CSS_DOCS.md`. The document's "Propriedade CSS" column writes
`box-shadow: var(--shadow-sm)`, and that is exactly what this front emits: `themeVar("shadow-sm")`
from front 54 returns `var(--shadow-sm)`. The literal each variable holds — `§ 21.4` for the shadow
scale — belongs to the **theme**, not to the dispatcher. Front 54's `defaultTheme()` carries only
`--color-black` and `--color-white`, so the shadow entries reach a project through `extend`, the
same way front 33's `paletteEntries()` does for colours. A dispatcher that resolved
`var(--shadow-md)` to `0 4px 6px -1px rgb(0 0 0 / 0.1), …` would hard-code a value the theme is
allowed to override, and contract `§ 4a` refuses it.

`--inset-shadow-*` and `--text-shadow-*` are therefore no different in kind from `--shadow-*`: the
reference never gives their literals, and it does not need to, because the dispatcher never needs
them. What was a deferred dependency in this front's first draft is now front 54's ordinary job.

The one place `emilia` differs from Tailwind is cosmetic and applies to the whole library: `emilia`
writes `prop:value` with no space after the colon (`emilia.bp:108-115`). The **value** is byte-equal
to the reference; the separator is emilia's, and it is the same separator every shipped token
already uses.

**Dispatcher shape.** Per contract `§ 4a`, every sub-dispatcher takes the theme:

```bp
fn effectTokenToCss(t: Token.Effect, th: Theme) -> string
fn blendTokenToCss(t: Token.Blend, th: Theme) -> string
fn maskTokenToCss(t: Token.Mask, th: Theme) -> string
```

No token in this front needs a selector outside its own class — a shadow, a blend mode and a mask
all paint the element they are on — so all three keep the declaration-string form and none takes the
`…TokenToSheet(t, th) -> Sheet` shape.

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
| `shadow-2xs` | `.Effect.Shadow.X2xs` | `box-shadow:var(--shadow-2xs)` — `themeVar("shadow-2xs")` |
| `shadow-xs` | `.Effect.Shadow.Xs` | `box-shadow:var(--shadow-xs)` |
| `shadow-sm` | `.Effect.Shadow.Sm` | `box-shadow:var(--shadow-sm)` |
| `shadow-md` | `.Effect.Shadow.Md` | `box-shadow:var(--shadow-md)` |
| `shadow-lg` | `.Effect.Shadow.Lg` | `box-shadow:var(--shadow-lg)` |
| `shadow-xl` | `.Effect.Shadow.Xl` | `box-shadow:var(--shadow-xl)` |
| `shadow-2xl` | `.Effect.Shadow.X2xl` | `box-shadow:var(--shadow-2xl)` |
| `shadow-none` | `.Effect.Shadow.None` | `box-shadow:none` |
| `shadow-inner` | `.Effect.Shadow.Inner` | `box-shadow:inset 0 2px 4px 0 rgb(0 0 0 / 0.05)` |
| `shadow-[…]` | `Token.EffectShadowRaw(value: v)` — **top-level** | `box-shadow:<v>` |
| `inset-shadow-2xs` | `.Effect.InsetShadow.X2xs` | `box-shadow:inset var(--inset-shadow-2xs)` — `"inset " + themeVar("inset-shadow-2xs")` |
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
        }
        InsetShadow {
            X2xs,
            Xs,
            Sm,
        }
    }

    // Arbitrary values are TOP-LEVEL variants, never section leaves — a payload
    // leaf inside a section cannot be constructed by any spelling
    // (`language-gaps.md` row 52, contract `§ 4a`).
    EffectShadowRaw(value: string),
    EffectTextShadowRaw(value: string),
    MaskImageRaw(value: string),
}
```

**Why the three `Raw` variants sit at the top of `Token` and not under `Effect.Shadow`.** A payload
leaf nested inside an enum section cannot be constructed by any spelling — verified against the real
compiler and recorded as `language-gaps.md` row 52. `Token.Effect.Shadow.Raw("…")` reports
`'Raw' is not declared in any behavior implemented for 'Token'` and the dot form reports
`unbound variable 'Effect'`. Contract `§ 4a` therefore puts every payload-carrying variant at the top
level, with builtin-typed fields. The name keeps the path it would have had, flattened:
`EffectShadowRaw`, `EffectTextShadowRaw`, `MaskImageRaw`.

**Acceptance:**
- [x] `effectTokenToCss(.Shadow.Md, th)` returns `box-shadow:var(--shadow-md)` — the string
      `box-shadow:md` appears nowhere in `repository/emilia/src/`. — held (shape: the string survives only in comments, negative asserts and probe controls; no arm emits it): `the defect — the four pre-41 shadow leaves emit a theme reference, never a class suffix`
- [x] `Token.EffectShadowRaw(value: "0 0 0 1px red")` **constructs** — a test builds one, which is
      the check that would have failed against a nested `Effect.Shadow.Raw`. — held: `the three Raw variants construct, and each reaches its own arm`
- [x] No section in this front's `tokens.bp` block contains a payload leaf. — held: `tokens.bp` front 41 block — `Effect`/`Blend`/`Mask` are keyword/numeric only; the three payloads are top-level
- [x] No shadow arm contains an `rgb(` literal: the scale's values live in the theme, and a resolved
      literal inside a dispatcher is the defect this acceptance exists to catch. — superseded: `Shadow.Inner` is upstream's literal with no `--shadow-inner` (AGENTS.md front 41 row); `regression — exactly one leaf resolves a shadow value, and it is Shadow.Inner`
- [x] All nine bare shadow leaves plus the three inset leaves have an arm in `shadowToCss` / `insetShadowToCss`; the `case` is exhaustive with no `_` arm. — held: `emilia.bp:shadowToCss`, `insetShadowToCss` — no `_` arm
- [x] `.Effect.Shadow.Sm`, `.Md`, `.Lg`, `.Xl` still type-check at every existing call site — the leaf names did not move. — held: `the defect — the four pre-41 shadow leaves emit a theme reference, never a class suffix`
- [x] Each of the twelve values is character-identical to its row above, which is character-identical to the "Propriedade CSS" column of `TAILWIND_CSS_DOCS.md § 12.1`. — held: `Effect.Shadow — the seven scale steps are --shadow-* references`, `…None is a keyword and Inner is the reference's own literal`, `Effect.InsetShadow — inset leads the value…`

### Step 2 — text-shadow

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `text-shadow-2xs` | `.Effect.TextShadow.X2xs` | `text-shadow:var(--text-shadow-2xs)` |
| `text-shadow-xs` | `.Effect.TextShadow.Xs` | `text-shadow:var(--text-shadow-xs)` |
| `text-shadow-sm` | `.Effect.TextShadow.Sm` | `text-shadow:var(--text-shadow-sm)` |
| `text-shadow-md` | `.Effect.TextShadow.Md` | `text-shadow:var(--text-shadow-md)` |
| `text-shadow-lg` | `.Effect.TextShadow.Lg` | `text-shadow:var(--text-shadow-lg)` |
| `text-shadow-none` | `.Effect.TextShadow.None` | `text-shadow:none` |
| `text-shadow-[…]` | `Token.EffectTextShadowRaw(value: v)` — **top-level** | `text-shadow:<v>` |

`§ 12.2` names the variables and no section of the reference gives their literals — and it does not
need to. Each of these is `themeVar("text-shadow-sm")` and friends from front 54, and the literals
are theme entries a project composes through `extend`. That is the same arrangement as the box-shadow
scale in Step 1, not a weaker one.

**Acceptance:**
- [x] `effectTokenToCss(.TextShadow.Sm, th)` returns `text-shadow:var(--text-shadow-sm)`. — held: `Effect.TextShadow — five references and a keyword`
- [x] `.Effect.TextShadow.None` returns `text-shadow:none` — a keyword, not a theme lookup. — held: `Effect.TextShadow — five references and a keyword`
- [x] `textShadowToCss` is exhaustive over the seven leaves. — held (shape: six section leaves; the seventh, `EffectTextShadowRaw`, is a top-level arm): `emilia.bp:textShadowToCss`

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
- [x] Fifteen arms in `opacityToCss`, each matching `__N`. — held (shape: 21 arms — six provisional steps 15/35/45/55/65/85 beside § 12.3's fifteen, marked at the arm): `emilia.bp:opacityToCss`
- [x] `effectTokenToCss(.Opacity.60, th)` returns `opacity:0.6` — not `opacity:.6`. — held: `Effect.Opacity — the ten steps § 12.3 adds, each with a leading zero`
- [x] The five pre-existing leaves return exactly what they returned before this front. — held: `Effect.Opacity — the five pre-41 leaves emit exactly what they emitted before`

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
- [x] `Blend` has exactly two sub-sections and each has exactly seventeen leaves. — held: `tokens.bp` `Blend { Mix, Bg }`, 17 leaves each; `Blend.Mix — the seventeen values…`, `Blend.Bg — …`
- [x] `blendTokenToCss` routes `Mix` and `Bg` to two sub-dispatchers that differ only in the
      property name they prepend. — held (shape: `blendTokenToCss` prepends the property; `blendMixValue`/`blendBgValue` are identical value tables): `Blend — the Mix and Bg value tables agree, value for value and in order`
- [x] `blendTokenToCss(.Mix.PlusLighter, th)` returns `mix-blend-mode:plus-lighter`. — held: `Blend.Mix — the seventeen values of § 12.4`

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
| `mask-image-[…]` | `Token.MaskImageRaw(value: v)` — **top-level** | `mask-image:<v>` |
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
- [x] `Mask` has nine sub-sections: `Clip`, `Composite`, `Image`, `Mode`, `Origin`, `Position`,
      `Repeat`, `Size`, `Type`. — held: `tokens.bp` `Mask` nine sub-sections
- [x] `maskTokenToCss` has nine arms and each routes to a sub-dispatcher with no `_` fallback. — held: `emilia.bp:maskTokenToCss`
- [x] A list of `[.Mask.Clip.Padding, .Mask.Mode.Luminance]` composes to the two declarations
      `mask-clip:padding-box` and `mask-mode:luminance` in `Rule.declarations`, in list order. — held: `composition — a list is its declarations, in list order`

### Step 6 — three arms in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, and a front that emits plain
declarations reaches it through `declSheet(...)`. `Effect` already has an arm; `Blend` and `Mask`
need one each, appended in front-number order per the `fronts.md` banner convention.

```bp
        Effect(_inner) -> declSheet(effectTokenToCss(_inner, th));
        Blend(_inner) -> declSheet(blendTokenToCss(_inner, th));
        Mask(_inner) -> declSheet(maskTokenToCss(_inner, th));
        EffectShadowRaw(value) -> declSheet("box-shadow:" + value);
        EffectTextShadowRaw(value) -> declSheet("text-shadow:" + value);
        MaskImageRaw(value) -> declSheet("mask-image:" + value);
```

Five new arms, not two: the three top-level payload variants each need one, because a top-level
variant is a sibling of `Effect` rather than a leaf inside it. Each destructures by its **declared
field name** (`value`) — an arbitrary positional bind type-checks and is `undefined` at run time.

**Acceptance:**
- [x] The five new arms sit between front 40's arm and front 42's, in that order. — held (shape: front 42 had no arm yet; the five sit directly after front 40's and before front 44's)
- [x] Each arm is one `declSheet(...)` call; no arm in this front builds a `Rule` or a `Sheet` by
      hand. — held: `emilia.bp:tokenToSheet` front 41 arms
- [x] The variant arms remain last in the `case`, and front 34 owns their wrapping — this front adds
      none. — held: the front 34 modifier arms close `tokenToSheet`
- [x] `tokenToSheet` still has no `_` arm — a token with no arm is a compile error, not a silent `""`. — held: `emilia.bp:tokenToSheet` has no `_` arm

## Examples

- [`./examples/effects-example.bp`](./examples/effects-example.bp) — the full `Effect` / `Blend` /
  `Mask` catalogue as typed `Token[]` lists, then a photo-card component that layers a shadow, a
  blend mode and an opacity under a `Hover` modifier and flushes the sheet.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` (`Tok.Color.Hex("#abc")` → `'Hex' is not declared in any behavior implemented for 'Tok'`; the dot form → `unbound variable 'Color'`) | this front's three arbitrary-value escape hatches, which the first draft wrote as `Effect.Shadow.Raw`, `Effect.TextShadow.Raw` and `Mask.Image.Raw` | the variant moves to the **top level** of `Token` with builtin-typed fields, per contract `§ 4a`: `Token.EffectShadowRaw(value: string)`, `Token.EffectTextShadowRaw(value: string)`, `Token.MaskImageRaw(value: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path, so the token tree and the CSS tree keep the same shape |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same three variants, now at top level: `[.EffectShadowRaw("0 0 0 1px red")]` still trips the parser | a wrapper fn returning the token (`fn rawShadow(v: string) -> Token { return Token.EffectShadowRaw(value: v); }`) or a typed `val` intermediate — the workaround `repository/emilia/src/emilia.bp:498-503` documents | let a leading-dot path carry a payload call inside a typed array literal |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| `shadow-red-500/50` (coloured shadow with opacity) | `§ 12.1` gives the class and the prose "Cor da sombra com opacidade" and **no property/value pair**. Upstream it is a two-step protocol: the colour utility sets `--tw-shadow-color` and the shadow utility reads it back. Front 56's `Rule.declarations` makes that protocol expressible — writer and reader are two declarations of one rule, the same shape front 46's scroll-snap chain uses — so the mechanism is no longer missing. The **value** still is: the reference has no row for it, so there is nothing byte-equal to emit. A reference gap, not a mechanism gap, and it reopens the moment a row exists. |
| ~~`--inset-shadow-*` and `--text-shadow-*` literals~~ | **Closed by front 54.** These are `themeVar(...)` lookups like every other scale in this front; the literals are theme entries, not dispatcher constants. |

## Test plan

`repository/emilia/test/effects_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence between them is a real bug, not a
coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert effectTokenToCss(<token>, th) == "<css>"` per row of
   the five tables above, with `th` the theme the test fixes; `blendTokenToCss` and `maskTokenToCss`
   are asserted the same way. This is the byte-equality gate; a table row and a test line are the
   same fact written twice, and a mismatch fails the build.
2. **No resolved theme literals.** A test greps this front's block of `emilia.bp` for `rgb(` and
   fails if it finds one. The scale belongs to the theme, and the cheapest way for it to leak back
   into a dispatcher is a well-meaning "make it work without a theme" patch.
2. **The regression this front exists for.** `assert tokensToCss([.Effect.Shadow.Md]).startsWith("box-shadow:0 4px")`
   plus `assert tokensToCss([.Effect.Shadow.Md]) != "box-shadow:md"`.
3. **Composition.** A three-token list produces three entries in `Rule.declarations` in list order,
   and the same list through `emilia()` + `await flush()` produces one rule whose declarations are in
   that order — the class name is a function of the encoded sheet, so order changes the class.
4. **Variant nesting.** `Token.Hover([.Effect.Shadow.Lg])` reaches front 34's `nestVariant` with
   `Variant(atRule: "@media (hover: hover)", selector: "&:hover")` and the inner declaration
   `box-shadow:var(--shadow-lg)`. This front asserts the declaration it contributes and **not** the
   wrapping: the wrapping is front 34's contract, and asserting it here would duplicate a literal
   only one front owns.
5. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so the `commonJS` and `erlang` rows must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value in this front is ASCII,
   which is the condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [x] `Effect` carries `Shadow`, `InsetShadow`, `TextShadow`, `Opacity`; `Blend` and `Mask` exist as
      top-level sections; all three blocks are fenced by a `front 41` banner in `tokens.bp`. — held: `tokens.bp` front 41 block
- [ ] `effectTokenToCss`, `blendTokenToCss`, `maskTokenToCss` and their sub-dispatchers are fenced
      by a `front 41` banner in `emilia.bp`, appended after front 40's block, and every one of them
      takes `th: Theme` per contract `§ 4a`. — **open:** only the three section dispatchers take `th: Theme`; the sub-dispatchers (`shadowToCss`, `insetShadowToCss`, `textShadowToCss`, `opacityToCss`, `blendMixValue`, `blendBgValue`, `mask*ToCss`) do not
- [x] `box-shadow:sm` and its three siblings are gone from the repository. — held (shape: survives only in comments, negative asserts and probe controls): `the defect — …never a class suffix`
- [x] The shadow, inset-shadow and text-shadow scales are `themeVar(...)` lookups; no `rgb(` literal
      appears anywhere in this front's block. — held (shape: the one `rgb(` is `Shadow.Inner`, upstream's literal — AGENTS.md front 41 row): `emilia.bp:shadowVar`/`insetShadowVar`/`textShadowVar`
- [x] Two arms added to `tokenToSheet`, each a `declSheet(...)` call, in front-number order, and no
      other line of that `case` moved. — held (shape: five arms — `Blend`, `Mask` and the three `Raw` variants, as Step 6 counts): `emilia.bp:tokenToSheet`
- [x] `repository/emilia/AGENTS.md` records the three new sections and the shadow-body correction. — held: AGENTS.md § Surface and the front 41 row
- [x] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them. — held: `modules/emilia` 569/569 on commonJS and erlang (AGENTS.md § Test surface); `determinism — a fixed effects list hashes to the same class on both targets`
