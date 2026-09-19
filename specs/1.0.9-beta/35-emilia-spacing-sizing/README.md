# Front 35 — emilia-spacing-sizing

**Track:** D emilia
**Priority:** critical — padding, margin and width are the three utilities every component uses first. Thirteen padding values and one width token exist today; nothing can be laid out with that.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 0
**Depends on:** none
**Owns:** `repository/emilia/src/tokens.bp` (the `Pad`, `Margin`, `Size` and `Space` sections) · `repository/emilia/src/emilia.bp` (`padTokenToCss`, `marginTokenToCss`, `sizeTokenToCss`, `spaceTokenToCss`, `spacingScale`) · `repository/emilia/test/spacing_test.bp`
**Does not touch:** `Gap` — it belongs to front 37, next to the flex and grid containers it spaces; `Layout.Inset` — front 36, which spaces a positioned box rather than a flowed one
**Reference:** `TAILWIND_CSS_DOCS.md § 7. Espaçamento`, `§ 8. Dimensionamento`, `§ 21.2 Escala de Espaçamento` · https://tailwindcss.com/docs/padding
**Replaces:** `1.0.8-beta/03-emilia-spacing-sizing`

---

## Problem

`Pad` today (`tokens.bp:140-161`) offers three directions — `X`, `Y`, `All` — over a five-value
scale `{1, 2, 4, 8, 16}`. Tailwind offers nine directions over an open multiplier scale (`§ 7.1`,
`§ 21.2`). There is no `p-0`, no per-side padding at all, and no logical `ps-*`/`pe-*`.

`Margin` (`tokens.bp:163-183`) is the same shape minus `16`, plus an `Auto` that only exists on the
`X` axis. There is no negative margin, which is the form `-mt-4` — one of the few Tailwind utilities
with no alternative spelling.

The dispatchers do not emit CSS. `padTokenToCss` (`emilia.bp:181-188`) emits `"padding-x:" + …` and
`"padding-y:" + …`. There is no `padding-x` property in CSS; that declaration is discarded by every
browser. `marginScaleX` (`emilia.bp:231-240`) is worse: it returns `"m-0.25"`, `"m-1"`,
`"margin-auto"` — Tailwind class fragments, emitted into a CSS rule body where they are not
declarations at all. Three of emilia's ten sections currently emit text that is not CSS, and all
three are in this front.

Sizing does not exist. There is no `Size` section, so no width, height, min or max token of any
kind. A component cannot be given a width today.

## Current state

| What | Where | State |
|---|---|---|
| `Pad { X{1,2,4,8,16}, Y{1,2,4,8}, All{1,2,4,8,16} }` | `tokens.bp:140-161` | 3 directions, no `0` |
| `Margin { X{Auto,1,2,4,8}, Y{1,2,4,8}, All{1,2,4,8} }` | `tokens.bp:163-183` | `Auto` on `X` only, no negatives |
| `padTokenToCss` | `emilia.bp:181-188` | emits `padding-x:` / `padding-y:` — not CSS properties |
| `padScaleX/Y/All` | `emilia.bp:190-220` | correct `rem` values, wrong property |
| `marginScaleX` | `emilia.bp:231-240` | emits `m-0.25`, `m-1`, `margin-auto` — class fragments, not declarations |
| `marginScaleY/All` | `emilia.bp:242-260` | `rem` values under a `margin-y:` property that does not exist |
| width / height / min / max | — | no section |
| `space-x` / `space-y` | — | no section |

## Mechanism

Tailwind v4 computes every spacing value from one variable (`§ 21.2`): `--spacing` is `0.25rem` and
each utility is a multiplier, `calc(var(--spacing) * N)`. The scale is open — any integer works. A
`Token` enum is closed, so this front declares the multipliers Tailwind's own default theme names
and the escape-hatch front carries the rest.

`spacingScale(n) -> string` is the single fn that turns a scale leaf into a length. Every direction
dispatcher calls it and prefixes the property, so there is one place where `calc(var(--spacing) * N)`
is spelled and thirty-odd places that consume it.

Four leaf shapes appear under every scale:

| Shape | Spelling | Emits |
|---|---|---|
| integer multiplier | `.Pad.All.4` | `calc(var(--spacing) * 4)` |
| zero | `.Pad.All.0` | `0` — `§ 7.1` shows `p-0` as `padding: 0`, not a `calc` |
| half step | `.Pad.All.Half.1` | `calc(var(--spacing) * 1.5)` |
| the pixel step | `.Pad.All.Px` | `1px` |

The half-step spelling exists because `0.5` cannot be an enum leaf: a numeric leaf is a run of
digits. `Half.1` reads "one and a half" and covers Tailwind's `0.5`, `1.5`, `2.5`, `3.5` as
`Half.0`, `Half.1`, `Half.2`, `Half.3`.

Negative values take the same route. `-mt-4` becomes `.Margin.T.Neg.4`, a `Neg` sub-section under
each direction whose dispatcher emits `calc(var(--spacing) * -4)`. A five-segment path
(`.Margin.T.Neg.4`) was verified to resolve before this spec was written.

Fractions cannot be leaves either — `1/2` is not an identifier and not a digit run — so `Size.W`
carries a `Frac` sub-section with named leaves.

`space-x` / `space-y` are not declarations on the element; they are declarations on its children.
emilia emits declaration text into a class body, and a nested rule is legal there, so a `Space`
token emits a whole nested rule rather than a single declaration. That is the same shape front 34's
modifiers emit, and `tokensToCss`'s `;` join handles it unchanged.

## Token surface

### The scale

Leaves shared by every direction under `Pad`, `Margin`, `Space` and the numeric part of `Size`:

`0 1 2 3 4 5 6 7 8 9 10 11 12 14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 96`, plus `Px` and
`Half { 0, 1, 2, 3 }`.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `p-0` | `.Pad.All.0` | `padding:0` |
| `p-1` | `.Pad.All.1` | `padding:calc(var(--spacing) * 1)` |
| `p-4` | `.Pad.All.4` | `padding:calc(var(--spacing) * 4)` |
| `p-96` | `.Pad.All.96` | `padding:calc(var(--spacing) * 96)` |
| `p-0.5` | `.Pad.All.Half.0` | `padding:calc(var(--spacing) * 0.5)` |
| `p-1.5` | `.Pad.All.Half.1` | `padding:calc(var(--spacing) * 1.5)` |
| `p-px` | `.Pad.All.Px` | `padding:1px` |

### Padding — `§ 7.1`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `p-4` | `.Pad.All.4` | `padding:calc(var(--spacing) * 4)` |
| `px-4` | `.Pad.X.4` | `padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4)` |
| `py-4` | `.Pad.Y.4` | `padding-top:calc(var(--spacing) * 4);padding-bottom:calc(var(--spacing) * 4)` |
| `pt-4` | `.Pad.T.4` | `padding-top:calc(var(--spacing) * 4)` |
| `pr-4` | `.Pad.R.4` | `padding-right:calc(var(--spacing) * 4)` |
| `pb-4` | `.Pad.B.4` | `padding-bottom:calc(var(--spacing) * 4)` |
| `pl-4` | `.Pad.L.4` | `padding-left:calc(var(--spacing) * 4)` |
| `ps-4` | `.Pad.S.4` | `padding-inline-start:calc(var(--spacing) * 4)` |
| `pe-4` | `.Pad.E.4` | `padding-inline-end:calc(var(--spacing) * 4)` |

### Margin — `§ 7.2`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `m-0` | `.Margin.All.0` | `margin:0` |
| `m-4` | `.Margin.All.4` | `margin:calc(var(--spacing) * 4)` |
| `m-auto` | `.Margin.All.Auto` | `margin:auto` |
| `mx-4` | `.Margin.X.4` | `margin-left:calc(var(--spacing) * 4);margin-right:calc(var(--spacing) * 4)` |
| `mx-auto` | `.Margin.X.Auto` | `margin-left:auto;margin-right:auto` |
| `my-4` | `.Margin.Y.4` | `margin-top:calc(var(--spacing) * 4);margin-bottom:calc(var(--spacing) * 4)` |
| `mt-4` | `.Margin.T.4` | `margin-top:calc(var(--spacing) * 4)` |
| `mr-4` | `.Margin.R.4` | `margin-right:calc(var(--spacing) * 4)` |
| `mb-4` | `.Margin.B.4` | `margin-bottom:calc(var(--spacing) * 4)` |
| `ml-4` | `.Margin.L.4` | `margin-left:calc(var(--spacing) * 4)` |
| `ms-4` | `.Margin.S.4` | `margin-inline-start:calc(var(--spacing) * 4)` |
| `me-4` | `.Margin.E.4` | `margin-inline-end:calc(var(--spacing) * 4)` |
| `-mt-4` | `.Margin.T.Neg.4` | `margin-top:calc(var(--spacing) * -4)` |
| `-mx-2` | `.Margin.X.Neg.2` | `margin-left:calc(var(--spacing) * -2);margin-right:calc(var(--spacing) * -2)` |

### Width — `§ 8.1`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `w-0` | `.Size.W.0` | `width:0` |
| `w-1` | `.Size.W.1` | `width:calc(var(--spacing) * 1)` |
| `w-64` | `.Size.W.64` | `width:calc(var(--spacing) * 64)` |
| `w-px` | `.Size.W.Px` | `width:1px` |
| `w-1/2` | `.Size.W.Frac.Half` | `width:50%` |
| `w-1/3` | `.Size.W.Frac.Third` | `width:33.333333%` |
| `w-2/3` | `.Size.W.Frac.TwoThirds` | `width:66.666667%` |
| `w-full` | `.Size.W.Full` | `width:100%` |
| `w-screen` | `.Size.W.Screen` | `width:100vw` |
| `w-svw` | `.Size.W.Svw` | `width:100svw` |
| `w-lvw` | `.Size.W.Lvw` | `width:100lvw` |
| `w-dvw` | `.Size.W.Dvw` | `width:100dvw` |
| `w-min` | `.Size.W.Min` | `width:min-content` |
| `w-max` | `.Size.W.Max` | `width:max-content` |
| `w-fit` | `.Size.W.Fit` | `width:fit-content` |
| `w-auto` | `.Size.W.Auto` | `width:auto` |

### Height — `§ 8.4`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `h-0` | `.Size.H.0` | `height:0` |
| `h-1` | `.Size.H.1` | `height:calc(var(--spacing) * 1)` |
| `h-1/2` | `.Size.H.Frac.Half` | `height:50%` |
| `h-full` | `.Size.H.Full` | `height:100%` |
| `h-screen` | `.Size.H.Screen` | `height:100vh` |
| `h-svh` | `.Size.H.Svh` | `height:100svh` |
| `h-lvh` | `.Size.H.Lvh` | `height:100lvh` |
| `h-dvh` | `.Size.H.Dvh` | `height:100dvh` |
| `h-min` | `.Size.H.Min` | `height:min-content` |
| `h-max` | `.Size.H.Max` | `height:max-content` |
| `h-fit` | `.Size.H.Fit` | `height:fit-content` |
| `h-auto` | `.Size.H.Auto` | `height:auto` |

### Min and max — `§ 8.2`, `§ 8.3`, `§ 8.5`, `§ 8.6`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `min-w-0` | `.Size.MinW.0` | `min-width:0` |
| `min-w-full` | `.Size.MinW.Full` | `min-width:100%` |
| `min-w-min` | `.Size.MinW.Min` | `min-width:min-content` |
| `min-w-max` | `.Size.MinW.Max` | `min-width:max-content` |
| `min-w-fit` | `.Size.MinW.Fit` | `min-width:fit-content` |
| `max-w-0` | `.Size.MaxW.0` | `max-width:0` |
| `max-w-none` | `.Size.MaxW.None` | `max-width:none` |
| `max-w-xs` | `.Size.MaxW.Xs` | `max-width:20rem` |
| `max-w-sm` | `.Size.MaxW.Sm` | `max-width:24rem` |
| `max-w-md` | `.Size.MaxW.Md` | `max-width:28rem` |
| `max-w-lg` | `.Size.MaxW.Lg` | `max-width:32rem` |
| `max-w-xl` | `.Size.MaxW.Xl` | `max-width:36rem` |
| `max-w-2xl` | `.Size.MaxW.X2xl` | `max-width:42rem` |
| `max-w-3xl` | `.Size.MaxW.X3xl` | `max-width:48rem` |
| `max-w-4xl` | `.Size.MaxW.X4xl` | `max-width:56rem` |
| `max-w-5xl` | `.Size.MaxW.X5xl` | `max-width:64rem` |
| `max-w-6xl` | `.Size.MaxW.X6xl` | `max-width:72rem` |
| `max-w-7xl` | `.Size.MaxW.X7xl` | `max-width:80rem` |
| `max-w-full` | `.Size.MaxW.Full` | `max-width:100%` |
| `max-w-screen-sm` | `.Size.MaxW.Screen.Sm` | `max-width:40rem` |
| `max-w-screen-md` | `.Size.MaxW.Screen.Md` | `max-width:48rem` |
| `max-w-screen-lg` | `.Size.MaxW.Screen.Lg` | `max-width:64rem` |
| `max-w-screen-xl` | `.Size.MaxW.Screen.Xl` | `max-width:80rem` |
| `max-w-screen-2xl` | `.Size.MaxW.Screen.X2xl` | `max-width:96rem` |
| `min-h-0` | `.Size.MinH.0` | `min-height:0` |
| `min-h-full` | `.Size.MinH.Full` | `min-height:100%` |
| `min-h-screen` | `.Size.MinH.Screen` | `min-height:100vh` |
| `min-h-svh` | `.Size.MinH.Svh` | `min-height:100svh` |
| `min-h-lvh` | `.Size.MinH.Lvh` | `min-height:100lvh` |
| `min-h-dvh` | `.Size.MinH.Dvh` | `min-height:100dvh` |
| `min-h-fit` | `.Size.MinH.Fit` | `min-height:fit-content` |
| `max-h-0` | `.Size.MaxH.0` | `max-height:0` |
| `max-h-none` | `.Size.MaxH.None` | `max-height:none` |
| `max-h-full` | `.Size.MaxH.Full` | `max-height:100%` |
| `max-h-screen` | `.Size.MaxH.Screen` | `max-height:100vh` |
| `max-h-svh` | `.Size.MaxH.Svh` | `max-height:100svh` |
| `max-h-lvh` | `.Size.MaxH.Lvh` | `max-height:100lvh` |
| `max-h-dvh` | `.Size.MaxH.Dvh` | `max-height:100dvh` |
| `max-h-fit` | `.Size.MaxH.Fit` | `max-height:fit-content` |

### Logical size — `§ 8.7`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `inline-size-4` | `.Size.Inline.4` | `inline-size:calc(var(--spacing) * 4)` |
| `min-inline-size-full` | `.Size.MinInline.Full` | `min-inline-size:100%` |
| `max-inline-size-md` | `.Size.MaxInline.Md` | `max-inline-size:28rem` |
| `block-size-4` | `.Size.Block.4` | `block-size:calc(var(--spacing) * 4)` |
| `min-block-size-full` | `.Size.MinBlock.Full` | `min-block-size:100%` |
| `max-block-size-full` | `.Size.MaxBlock.Full` | `max-block-size:100%` |
| `size-12` | `.Size.Both.12` | `width:calc(var(--spacing) * 12);height:calc(var(--spacing) * 12)` |
| `size-full` | `.Size.Both.Full` | `width:100%;height:100%` |

### Child spacing

`space-x-*` and `space-y-*` are not in the local reference — see *Reference gaps*.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `space-x-4` | `.Space.X.4` | `& > :not(:last-child){margin-inline-end:calc(var(--spacing) * 4)}` |
| `space-y-4` | `.Space.Y.4` | `& > :not(:last-child){margin-block-end:calc(var(--spacing) * 4)}` |
| `space-x-reverse` | `.Space.XReverse` | `& > :not(:last-child){--tw-space-x-reverse:1}` |
| `space-y-reverse` | `.Space.YReverse` | `& > :not(:last-child){--tw-space-y-reverse:1}` |

## Steps

### Step 1 — one scale fn, and the correction to `padding-x`

```bp
fn spacingScale(n: string) -> string {
    val out = if (n == "0") { "0"; } else { "calc(var(--spacing) * " + n + ")"; };
    return out;
}
```

Each direction dispatcher maps its leaf to the multiplier string and prefixes the property. The
existing `padScaleX`, `padScaleY`, `padScaleAll`, `marginScaleX`, `marginScaleY`, `marginScaleAll`
are folded into it; `padTokenToCss` stops emitting `padding-x:` and emits the two real properties;
`marginScaleX` stops emitting `m-1` and `margin-auto`.

This changes the CSS four existing tokens emit. It is a correction, not a rename: no path that
compiles today stops compiling, and what those paths emitted was never valid CSS. The assertions
affected are in this front's own test file; `src/emilia.bp` has no spacing assertion.

**Acceptance:**
- [ ] `.Pad.All.4` emits `padding:calc(var(--spacing) * 4)`
- [ ] `.Pad.X.4` emits `padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4)` — two declarations, `;`-joined, inside one token
- [ ] `.Pad.All.0` emits `padding:0`, not `padding:calc(var(--spacing) * 0)`
- [ ] no token anywhere in `emilia.bp` emits a property name that is not a real CSS property —
      `padding-x`, `padding-y`, `margin-y` are gone
- [ ] no token emits a Tailwind class fragment — `m-0.25`, `m-1`, `margin-auto` are gone
- [ ] the paths that compile today (`.Pad.X.4`, `.Pad.All.16`, `.Margin.Y.8`, `.Margin.X.Auto`) all
      still compile

### Step 2 — nine directions for padding, ten for margin

```bp
    Pad {
        All { 0, 1, …, 96, Px, Half { 0, 1, 2, 3 } }
        X { … }  Y { … }  T { … }  R { … }  B { … }  L { … }  S { … }  E { … }
    }
    Margin {
        All { 0, …, 96, Auto, Px, Half { … }, Neg { 1, …, 96, Px, Half { … } } }
        X { … }  Y { … }  T { … }  R { … }  B { … }  L { … }  S { … }  E { … }
    }
```

`Auto` is on every margin direction, not only `X`. `Neg` is on every margin direction and carries no
`0` and no `Auto` — a negative zero and a negative auto are not utilities.

**Acceptance:**
- [ ] all nine padding directions answer all 35 scale leaves
- [ ] all nine margin directions answer the scale plus `Auto`
- [ ] `.Margin.T.Neg.4` emits `margin-top:calc(var(--spacing) * -4)` — the five-segment path resolves
- [ ] `.Margin.X.Neg.2` emits both sides negative
- [ ] `.Margin.All.Auto` emits `margin:auto` and `.Margin.X.Auto` emits the two-property form
- [ ] `.Pad.S.4` / `.Pad.E.4` emit `padding-inline-start` / `padding-inline-end`

### Step 3 — the `Size` section

Thirteen sub-sections: `W`, `H`, `Both`, `MinW`, `MaxW`, `MinH`, `MaxH`, `Inline`, `Block`,
`MinInline`, `MaxInline`, `MinBlock`, `MaxBlock`.

```bp
    Size {
        W {
            0, 1, …, 96, Px,
            Frac { Half, Third, TwoThirds, Quarter, ThreeQuarters,
                   Fifth, TwoFifths, ThreeFifths, FourFifths,
                   Sixth, FiveSixths },
            Full, Screen, Svw, Lvw, Dvw, Min, Max, Fit, Auto,
        }
        // …
    }
```

`MaxW` additionally carries the named container widths `Xs … X7xl` and a `Screen { Sm, Md, Lg, Xl,
X2xl }` sub-section. `Both` is `size-*`: it emits `width` and `height` from one leaf.

**Acceptance:**
- [ ] `.Size.W.Full` emits `width:100%`; `.Size.W.Screen` emits `width:100vw`; `.Size.H.Screen`
      emits `height:100vh` — the viewport unit differs by axis and the test says so
- [ ] `.Size.W.Frac.Third` emits `width:33.333333%` — six decimal places, as `§ 8.1` prints it
- [ ] `.Size.W.Frac.TwoThirds` emits `width:66.666667%`
- [ ] every `MaxW` named width matches `§ 8.3` exactly, `Xs` through `X7xl`
- [ ] `.Size.MaxW.Screen.X2xl` emits `max-width:96rem`
- [ ] `.Size.Both.12` emits two declarations from one token
- [ ] the six logical sub-sections emit `inline-size`, `block-size` and their min/max forms

### Step 4 — `Space`

```bp
    Space {
        X { 0, 1, …, 96, Px, Half { … }, Neg { … } }
        Y { … }
        XReverse,
        YReverse,
    }
```

The emitted string is a nested rule, not a declaration. `tokensToCss` joins it into the class body
with `;` like anything else, and a nested rule preceded by `;` is legal CSS.

**Acceptance:**
- [ ] `.Space.Y.4` emits `& > :not(:last-child){margin-block-end:calc(var(--spacing) * 4)}`
- [ ] `.Space.X.4` emits the `margin-inline-end` form
- [ ] a `Space` token composes with a `Pad` token in the same list and the result is
      `padding:…;& > :not(:last-child){…}`
- [ ] `.Space.X.Neg.2` emits a negative child margin
- [ ] the selector this front chose is recorded in the README and verified against upstream before
      merge — see *Reference gaps*

### Step 5 — the four dispatchers and the top-level arms

`padTokenToCss` and `marginTokenToCss` are rewritten; `sizeTokenToCss` and `spaceTokenToCss` are
new. Two arms are added to the top-level `tokenToCss` case (`Size`, `Space`); `Pad` and `Margin`
already have theirs.

**Acceptance:**
- [ ] each dispatcher follows the file's `val out = case …; return out;` idiom
- [ ] every arm is an arrow arm — no block arm anywhere, since a block arm parses but yields no value
- [ ] the banner `// ── front 35 — spacing and sizing ──` fences the block in both files
- [ ] the two new `tokenToCss` arms sit in front-number order relative to the other fronts' arms

## Examples

- `./examples/spacing-example.bp` — the scale, all nine padding directions, margin with `Auto` and
  negatives, and child spacing; ends with a stacked comment thread that uses `Space.Y` and a
  negative pull-up.
- `./examples/sizing-example.bp` — width, height, fractions, viewport units, intrinsic sizes, min and
  max, the logical forms; ends with a centred article shell with a max width and a full-bleed header.

## Language gaps

None — every construct in this front's examples parses today. Three shapes were verified against
`zig-out/bin/botopink` before the spec was written, because each is load-bearing here:

| Shape | Result |
|---|---|
| numeric leaf in expression position (`.Pad.All.4`) | resolves; `__4` is the pattern spelling only |
| a five-segment path (`.Margin.T.Neg.4`) | resolves |
| a `Neg` sub-section holding numeric leaves | resolves and destructures |

## Reference gaps

| Item | Why it is missing | What implementation must do |
|---|---|---|
| `space-x-*` / `space-y-*` | absent from `TAILWIND_CSS_DOCS.md` entirely — not in `§ 7`, not in the *Referência Rápida* | verify the child selector and the property against upstream `tailwindcss.com/docs/margin#adding-space-between-children`; this spec's `& > :not(:last-child)` and `margin-inline-end` are a proposal, not a transcription |
| `space-x-reverse` / `space-y-reverse` | likewise absent | the `--tw-space-*-reverse` custom property name is upstream-internal and must be confirmed |
| Fractions beyond `1/2`, `1/3`, `2/3` | `§ 8.1` prints only those three; quarters, fifths, sixths and twelfths are not documented locally | `Frac.Quarter` and below are declared by this front but their percentages must be checked against upstream before merge |
| The full spacing multiplier set | `§ 21.2` says the scale is multiplicative and open, and `§ 7.1` prints only `0`, `1`, `2`, `4` | the 30 multipliers this front declares are Tailwind's default theme keys; confirm the list against upstream `theme.css` |
| `p-px`, `w-px` | not printed in `§ 7` or `§ 8` | `1px` is the only sensible value but it is not documented locally |

## Test plan

`repository/emilia/test/spacing_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`.

What the tests assert:

1. **The scale, once** — `spacingScale` over `0`, `1`, `4`, `96`, `Half.1`, `Px`, exercised through
   `.Pad.All.*` so it is tested via the public surface.
2. **One test per padding direction** — nine tests, each asserting the property name and the
   two-property expansion where there is one.
3. **One test per margin direction**, plus `Auto` on each and `Neg` on each.
4. **The regression this front is here for** — explicit asserts that the emitted text contains
   neither `padding-x`, `padding-y`, `margin-y`, nor `m-1`, `m-0.25`, `margin-auto`.
5. **Width and height** — numeric, fractional, viewport, intrinsic, `auto`, with the `vw`/`vh` split
   asserted directly.
6. **Min and max** — every named `MaxW` width against `§ 8.3`, and the `Screen` sub-section.
7. **Logical sizes** — six properties.
8. **`Space`** — the nested-rule shape, and its composition with a plain declaration in one class.
9. **End to end** — `emilia([.Size.MaxW.X3xl, .Margin.X.Auto, .Pad.X.6])` then `await flush()`,
   asserting the whole `<style>` block.

## Definition of done

- [ ] `Pad` carries nine directions, `Margin` nine plus `Auto` and `Neg`, over a 35-leaf scale
- [ ] `Size` carries thirteen sub-sections covering `§ 8.1`–`§ 8.7`
- [ ] `Space` carries `X`, `Y` and the two reverse tokens
- [ ] no emilia token emits a non-CSS property name or a Tailwind class fragment
- [ ] `spacingScale` is the only place `calc(var(--spacing) * N)` is spelled
- [ ] the banner fences this front's block in both files, appended at the end
- [ ] two arms added to the top-level `tokenToCss` case, in front-number order
- [ ] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new sections
- [ ] the front's tests are green on its assigned target — here, both backends, since emilia is comptime
