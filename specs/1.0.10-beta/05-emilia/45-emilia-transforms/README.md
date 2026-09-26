# Front 45 — emilia transforms

> **Amended 2026-09-21, on landing (emilia `9c19e22`, 528 → 569 on both rows).** Three acceptance
> claims in this document are **falsified**, two of them by upstream itself. The front checked rather
> than transcribing — and on the first, this spec had told it to.
>
> **§ 16.6's property column is wrong.** Upstream (`https://tailwindcss.com/docs/skew`, fetched
> 2026-09-21) prints `transform: skewX(<n>deg)` / `transform: skewY(<n>deg)` and carries **no**
> `--tw-skew-*` row. The twelve skew leaves emit upstream's property and `skew-x:` / `skew-y:` are
> asserted **absent**. Consequence, recorded rather than glossed: both skew axes write `transform`,
> so unlike rotate, scale and translate they do **not** compose.
>
> **Step 3's translate shape appears in neither source.** This document asks for
> `--tw-translate-x:50%; translate:var(--tw-translate-x) var(--tw-translate-y)`. The reference file's
> `§ 16.10` prints **one** declaration (`translate: 50% var(--tw-translate-y)`) and so does upstream,
> which additionally carries the five `translate-y-*` rows the reference file omits — so the y mirror
> is **confirmed, not interpolated**. Reference and upstream agree against this spec.
>
> That exposed a second error in the same step: **the `--tw-*` identity defaults cannot be theme
> entries.** `extendTheme` `@panic`s on a name in no known namespace (`theme.bp:318`) and `--tw-` is
> in none of `Ns`'s nineteen prefixes. Front 39's `cssVarOr` is the house answer and is **called, not
> re-spelled**: every row carries `var(--tw-translate-y, 0)`, without which a lone `translate-x-4` is
> invalid at computed-value time and moves nothing. So Step 3's acceptance bullet asserting *three
> deduplicated declarations* is wrong, and what is asserted instead is the truth:
> `[.TranslateX.Half, .TranslateY.Half]` does **not** compose — two declarations of one property,
> last wins.
>
> **Step 6's "they now resolve" is false.** `§ 16.7`'s four shorthand rows read six `--tw-*`
> variables that **no token in emilia sets** — `rotate-*` writes `rotate`, `scale-*` writes `scale`,
> `translate-*` writes `translate`, `skew-*` writes its own `transform`. They are transcribed
> **verbatim** (byte-equality is the gate) and **marked inert** at the declaration, in the `Token`
> docblock, in `AGENTS.md`, in `docs.md` and in the example. They were deliberately given **no**
> fallbacks: `.Shorthand.Cpu` would then emit an identity transform that silently overwrites the
> `skewX` beside it. Making them resolve needs `@property` emission — a new output kind, and front
> 56's — which is the condition under which the "inert" half of that test should be deleted.
>
> **Two smaller disagreements.** The *Definition of done* lists a `Translate` (both-axes) section
> that this spec's own Step 3 table does not contain and `§ 16` does not enumerate; it was **not
> declared**, and `rawTranslate` covers the use. And the acceptance names `rotateToCss` /
> `rotateNegToCss`; the landed names are `transformRotateToCss` / `transformRotateNegToCss`, because
> a bare `originToCss` / `styleToCss` / `scaleToCss` in a 16 000-line shared file collides in spirit
> with fronts 35 and 37's `padScale*` / `gapScale*` families.
>
> **Nothing about perspective is provisional** — `§ 16.2` prints the variable *and* its length on all
> five rows — which the front states explicitly as the contrast with front 44's three `--ease-*`.

**Track:** D emilia
**Priority:** medium — a hover that lifts a card, a chevron that flips when a menu opens and a modal that scales in are all one property, and `emilia` has no token for it
**Target:** comptime
**Wave:** 3
**Depends on:** 44 (transitions — a transform without a transition snaps, so the examples pair the two; the dependency is on the token existing, not on its dispatcher)
**Owns:** token section `Transform` in `repository/emilia/src/tokens.bp` · dispatcher `transformTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/transforms_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, the class-name hash (std `content_hash.contentHash` since decision 116), `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 16. Transforms` · https://tailwindcss.com/docs/rotate

---

## Problem

There is no `Transform` token. `repository/emilia/src/tokens.bp:36-270` has no `rotate`, no `scale`,
no `translate`, no `skew`, no `perspective` and no `transform-origin`. Every motion-adjacent
interaction in a UI — the card that rises on hover, the icon that rotates 180° when a disclosure
opens, the toast that slides in from the edge, the avatar that scales up on focus — needs one of
those six properties and can get none of them from `emilia` today.

The gap compounds with front 44. A transition is only visible if something changes, and the thing
that most often changes is a transform. Shipping `Transition.Transform` (front 44) without a
`Transform` section would ship a token that can only animate a property no other token can set.

The reference's `§ 16` is also the section where Tailwind's own documentation is least uniform: two
subsections give a property name that is not a registered CSS property, one gives values in a
`var(--tw-*)` chain `emilia` has no cascade for, and the 3-D variants the milestone brief asks about
are not enumerated anywhere in it. Each of those is called out below rather than smoothed over.

## Current state

- No `Transform` section; no `rotate`, `scale`, `skew`, `translate`, `perspective`,
  `transform-origin`, `transform-style`, `backface-visibility` or `zoom` string anywhere in
  `repository/emilia/src/`.
- Numeric leaves are declared as bare digits (`tokens.bp:73-83`), written `.Section.500` in
  expression position and matched as `__500` in a `case` pattern (`emilia.bp:387-395`). There is no
  spelling for a negative numeric leaf, which `-rotate-12` needs — see *Language gaps*.
- `rotate`, `scale` and `translate` are independent CSS properties in v4 (not `transform`
  functions), so two of them in one rule compose with no extra machinery. `skew` is the exception —
  see Step 4.
- Front 56's `Rule.declarations` is an ordered list of declarations in one rule, which is what makes
  the `--tw-translate-x` / `--tw-translate-y` pair below work; the first draft of this front called
  those tokens inert because the output model was a flat string.

## Mechanism

`Transform` is one top-level section with eleven sub-sections, one per `§ 16` subsection, and one
dispatcher routing to eleven sub-dispatchers. Every leaf maps to one property/value pair.

**Where the values come from.** Every property name and value is copied from the reference, and
every theme variable stays a variable. `§ 16.2` writes `perspective: var(--perspective-near)` and
gives the literal in parentheses — `(300px)`. The emitted value is `var(--perspective-near)`
(`themeVar("perspective-near")` from front 54) and `300px` is the **theme entry**; contract `§ 4a`
refuses a dispatcher that resolves a theme variable, and the first draft of this front resolved all
five perspective keywords, which was wrong.

**The `--tw-*` chain, and how front 56 settles it.** `§ 16.7` (`transform`) and `§ 16.10`
(`translate`) give values that reference `var(--tw-translate-x)`, `var(--tw-rotate)` and friends.
The first draft called those tokens inert. They are not: `Rule.declarations` is an ordered list of
declarations in one rule, so a leaf writes its own axis variable **and** the shorthand that reads
both back.

```
.Transform.TranslateX.Half -> --tw-translate-x:50%;translate:var(--tw-translate-x) var(--tw-translate-y)
.Transform.TranslateY.Half -> --tw-translate-y:50%;translate:var(--tw-translate-x) var(--tw-translate-y)
```

Both tokens in one list write two different axis variables and two identical `translate:`
declarations into the same rule — the duplicate shorthand is idempotent, and both axes survive. The
identity defaults (`--tw-translate-x: 0`, `--tw-rotate: 0deg`, `--tw-scale-x: 1`, …) are theme
entries this front contributes to front 54, so a lone `TranslateX` token still renders. This is the
same shape front 42's filter chain and front 46's scroll-snap chain use.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`). The **value** is byte-equal to the reference; the separator is emilia's.

**Dispatcher shape.** Per contract `§ 4a`:

```bp
fn transformTokenToCss(t: Token.Transform, th: Theme) -> string
```

No transform token needs a selector outside its own class, so this front keeps the
declaration-string form and does not take the `…TokenToSheet(t, th) -> Sheet` shape. A
two-declaration token is a `;`-joined string, which is what the axis-variable pairs above produce.

## Steps

### Step 1 — `rotate`, including negatives

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `rotate-0` | `.Transform.Rotate.0` | `rotate:0deg` |
| `rotate-1` | `.Transform.Rotate.1` | `rotate:1deg` |
| `rotate-45` | `.Transform.Rotate.45` | `rotate:45deg` |
| `rotate-90` | `.Transform.Rotate.90` | `rotate:90deg` |
| `rotate-180` | `.Transform.Rotate.180` | `rotate:180deg` |
| `-rotate-1` | `.Transform.Rotate.Neg.1` | `rotate:-1deg` |
| `-rotate-12` | `.Transform.Rotate.Neg.12` | `rotate:-12deg` |
| `-rotate-45` | `.Transform.Rotate.Neg.45` | `rotate:-45deg` |
| `-rotate-90` | `.Transform.Rotate.Neg.90` | `rotate:-90deg` |
| `-rotate-180` | `.Transform.Rotate.Neg.180` | `rotate:-180deg` |
| `rotate-[17deg]` | `Token.TransformRotateRaw(value: v)` — **top-level** | `rotate:<v>` |

`§ 16.4`'s table gives the five positive steps; the same subsection's HTML example gives
`-rotate-12` and `rotate-[17deg]`, which is where the negative form and the arbitrary form come
from. `Neg` is a sub-section rather than a sign on the leaf because a numeric enum leaf is declared
as bare digits and there is no spelling for a negative one — see *Language gaps*. `Neg.12` exists
because the reference names it; the other four `Neg` steps mirror the positive table.

```bp
pub type Token {
    // ── front 45 · transforms ────────────────────────────────────────────
    Transform {
        Rotate {
            0,
            1,
            45,
            90,
            180,
            Neg {
                1,
                12,
                45,
                90,
                180,
            }
        }
    }

    // Payload-carrying variants are TOP-LEVEL, never section leaves — a payload
    // leaf inside a section cannot be constructed by any spelling
    // (`language-gaps.md` row 52, contract `§ 4a`).
    TransformRotateRaw(value: string),
    TransformTranslateRaw(value: string),
}
```

**Why the two `Raw` variants sit at the top of `Token`.** A payload leaf nested inside an enum
section cannot be constructed by any spelling — verified against the real compiler,
`language-gaps.md` row 52. Contract `§ 4a` puts every payload-carrying variant at the top level with
builtin-typed fields, and the name keeps the path it would have had, flattened.

**Acceptance:**
- [x] `transformTokenToCss(.Rotate.90, th)` returns `rotate:90deg`. — held: `Transform.Rotate — the five positive steps of § 16.4`
- [x] `Token.TransformRotateRaw(value: "17deg")` **constructs** — a test builds one, which is the
      check that would have failed against a nested `Transform.Rotate.Raw`. — held: `TransformRotateRaw / TransformTranslateRaw — they construct, and they emit`
- [x] No section in this front's `tokens.bp` block contains a payload leaf. — held: `tokens.bp` front 45 block — the two payloads are top-level
- [x] `transformTokenToCss(.Rotate.Neg.12, th)` returns `rotate:-12deg` — one `-`, no space. — held: `Transform.Rotate.Neg — the negative half, one - and no space`
- [x] `rotateToCss` and `rotateNegToCss` are exhaustive with no `_` arm. — held (shape: named `transformRotateToCss` / `transformRotateNegToCss`, per the amendment above)

### Step 2 — `scale`, both axes

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `scale-0` | `.Transform.Scale.0` | `scale:0` |
| `scale-50` | `.Transform.Scale.50` | `scale:.5` |
| `scale-75` | `.Transform.Scale.75` | `scale:.75` |
| `scale-90` | `.Transform.Scale.90` | `scale:.9` |
| `scale-95` | `.Transform.Scale.95` | `scale:.95` |
| `scale-100` | `.Transform.Scale.100` | `scale:1` |
| `scale-105` | `.Transform.Scale.105` | `scale:1.05` |
| `scale-110` | `.Transform.Scale.110` | `scale:1.1` |
| `scale-125` | `.Transform.Scale.125` | `scale:1.25` |
| `scale-150` | `.Transform.Scale.150` | `scale:1.5` |
| `scale-x-50` | `.Transform.ScaleX.50` | `scale:.5 1` |
| `scale-y-50` | `.Transform.ScaleY.50` | `scale:1 .5` |

`scale-50` emits `.5`, not `0.5` — the reference writes the leading zero off, and byte-equality is
the gate. `ScaleX` and `ScaleY` carry the same ten steps as `Scale`; the reference enumerates only
the `50` row of each and states the shape, which is the two-value `scale` syntax with the other axis
pinned at `1`.

**Acceptance:**
- [x] `transformTokenToCss(.Scale.75, th)` returns `scale:.75`; a leading `0` fails. — held: `Transform.Scale — no leading zero, no trailing zero`
- [x] `transformTokenToCss(.ScaleX.50, th)` returns `scale:.5 1` and `.ScaleY.50` returns
      `scale:1 .5` — asserted in adjacent lines, because a copy-paste between them is invisible
      otherwise. — held: `Transform.ScaleX / ScaleY — the two-value scale, the other axis at 1`
- [x] `.Transform.Scale.100` returns `scale:1`, not `scale:1.0`. — held: `Transform.Scale — the ten unaxed steps of § 16.5`

### Step 3 — `translate`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `translate-x-0` | `.Transform.TranslateX.0` | `--tw-translate-x:0;translate:var(--tw-translate-x) var(--tw-translate-y)` |
| `translate-x-px` | `.Transform.TranslateX.Px` | `--tw-translate-x:1px;` + the shorthand |
| `translate-x-1` | `.Transform.TranslateX.1` | `--tw-translate-x:calc(var(--spacing) * 1);` + the shorthand |
| `translate-x-1/2` | `.Transform.TranslateX.Half` | `--tw-translate-x:50%;` + the shorthand |
| `translate-x-full` | `.Transform.TranslateX.Full` | `--tw-translate-x:100%;` + the shorthand |
| `translate-y-0` | `.Transform.TranslateY.0` | `--tw-translate-y:0;` + the shorthand |
| `translate-y-px` | `.Transform.TranslateY.Px` | `--tw-translate-y:1px;` + the shorthand |
| `translate-y-1` | `.Transform.TranslateY.1` | `--tw-translate-y:calc(var(--spacing) * 1);` + the shorthand |
| `translate-y-1/2` | `.Transform.TranslateY.Half` | `--tw-translate-y:50%;` + the shorthand |
| `translate-y-full` | `.Transform.TranslateY.Full` | `--tw-translate-y:100%;` + the shorthand |
| `translate-[…]` | `Token.TransformTranslateRaw(value: v)` — **top-level** | `translate:<v>` — both axes at once, no variable |

"the shorthand" is `translate:var(--tw-translate-x) var(--tw-translate-y)`, byte-identical in every
row; the first row shows it in full. `translate-x-1` uses `spacing(1)` per contract `§ 4a` —
`calc(var(--spacing) * 1)`, never a resolved `rem`.

`§ 16.10` enumerates the five `translate-x-*` rows and this front mirrors them for `y` by swapping
the two components — the derivation is mechanical and is stated here so it can be checked.

**These ten tokens compose.** Each writes its own axis variable and the shared shorthand, so
`[.TranslateX.Half, .TranslateY.Half]` moves an element on both axes — the first draft of this front
said the opposite, and front 56's `Rule.declarations` is what changed. The `Raw` leaf stays, for a
translate the token set does not name. The identity defaults `--tw-translate-x: 0` and
`--tw-translate-y: 0` are theme entries this front contributes to front 54.

**Acceptance:**
- [x] Every one of the ten rows emits its axis variable **and** the shorthand, in that order. — superseded: reference and upstream print one declaration, `translate:<axis> var(--tw-translate-<other>, 0)` (amendment above; AGENTS.md front 45): `Transform.TranslateX — the five rows of § 16.10, whole`
- [x] `transformTokenToCss(.TranslateX.1, th)` contains `calc(var(--spacing) * 1)` — spaces around
      the `*` kept — and no `rem` literal appears anywhere in this front's block. — held: `Transform.TranslateX.1 — front 54's spacing, not a resolved length`, `regression — no walked leaf of this front resolves a length`
- [x] `[.TranslateX.Half, .TranslateY.Half]` produces three distinct declarations in
      `Rule.declarations`: the two axis variables and one shorthand, deduplicated. — superseded: the two axes are two `translate:` declarations and the last wins (amendment above; AGENTS.md front 45): `Transform.Translate — two axes are two declarations, and the last wins`
- [x] The two `--tw-translate-*` identity defaults are contributed to front 54's theme and named in
      this front's `TODO.md`. — superseded: `--tw-` is in no `Ns` prefix and `extendTheme` panics, so the `0` rides in `cssVarOr` (AGENTS.md front 45): `regression — --tw-* is in no namespace, which is why the 0 is inline`

### Step 4 — `skew`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `skew-x-0` | `.Transform.SkewX.0` | `skew-x:0deg` |
| `skew-x-1` | `.Transform.SkewX.1` | `skew-x:1deg` |
| `skew-x-2` | `.Transform.SkewX.2` | `skew-x:2deg` |
| `skew-x-3` | `.Transform.SkewX.3` | `skew-x:3deg` |
| `skew-x-6` | `.Transform.SkewX.6` | `skew-x:6deg` |
| `skew-x-12` | `.Transform.SkewX.12` | `skew-x:12deg` |
| `skew-y-0` | `.Transform.SkewY.0` | `skew-y:0deg` |
| `skew-y-1` | `.Transform.SkewY.1` | `skew-y:1deg` |
| `skew-y-2` | `.Transform.SkewY.2` | `skew-y:2deg` |
| `skew-y-3` | `.Transform.SkewY.3` | `skew-y:3deg` |
| `skew-y-6` | `.Transform.SkewY.6` | `skew-y:6deg` |
| `skew-y-12` | `.Transform.SkewY.12` | `skew-y:12deg` |

**`skew-x` and `skew-y` are what `§ 16.6`'s "Propriedade CSS" column says, and neither is a
registered CSS property.** The rule for this milestone is that the emitted CSS is byte-equal to the
reference, so these twelve tokens emit exactly what the column writes. That is a faithful
transcription and a declaration no browser will apply. This is the single row set in my fronts where
following the reference produces something that certainly does not work, and it is flagged rather
than silently corrected: correcting it means writing `transform:skewX(1deg)`, which appears nowhere
in the reference. **Confirm against https://tailwindcss.com/docs/skew before this step lands**, and
if the upstream page disagrees with the reference file, the reference file is wrong and this step's
table changes with a note saying so.

**Acceptance:**
- [x] All twelve rows emit the reference's property name verbatim. — superseded: upstream prints `transform:skewX(Ndeg)`/`skewY`, checked 2026-09-21 (AGENTS.md front 45): `Transform.Skew — the reference file's skew-x: column is never emitted`
- [x] The `tokens.bp` docblock carries the flag above, so the next reader does not have to rediscover
      it. — held: `tokens.bp` header `Transform` entry and front 45 block comment
- [x] A reviewer has checked the upstream page and recorded the outcome in the front's `TODO.md`. — held (shape: recorded with URL and date in the `emilia.bp` front 45 banner, AGENTS.md and the amendment above; `TODO.md` is git-ignored)

### Step 5 — `transform-origin`, `transform-style`, `backface-visibility`, `perspective`, `zoom`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `origin-center` | `.Transform.Origin.Center` | `transform-origin:center` |
| `origin-top` | `.Transform.Origin.Top` | `transform-origin:top` |
| `origin-top-right` | `.Transform.Origin.TopRight` | `transform-origin:top right` |
| `origin-right` | `.Transform.Origin.Right` | `transform-origin:right` |
| `origin-bottom-right` | `.Transform.Origin.BottomRight` | `transform-origin:bottom right` |
| `origin-bottom` | `.Transform.Origin.Bottom` | `transform-origin:bottom` |
| `origin-bottom-left` | `.Transform.Origin.BottomLeft` | `transform-origin:bottom left` |
| `origin-left` | `.Transform.Origin.Left` | `transform-origin:left` |
| `origin-top-left` | `.Transform.Origin.TopLeft` | `transform-origin:top left` |
| `transform-flat` | `.Transform.Style.Flat` | `transform-style:flat` |
| `transform-3d` | `.Transform.Style.Preserve3d` | `transform-style:preserve-3d` |
| `backface-visible` | `.Transform.Backface.Visible` | `backface-visibility:visible` |
| `backface-hidden` | `.Transform.Backface.Hidden` | `backface-visibility:hidden` |
| `perspective-none` | `.Transform.Perspective.None` | `perspective:none` — a keyword, not a lookup |
| `perspective-dramatic` | `.Transform.Perspective.Dramatic` | `perspective:var(--perspective-dramatic)` (theme entry `100px`) |
| `perspective-near` | `.Transform.Perspective.Near` | `perspective:var(--perspective-near)` (`300px`) |
| `perspective-normal` | `.Transform.Perspective.Normal` | `perspective:var(--perspective-normal)` (`500px`) |
| `perspective-midrange` | `.Transform.Perspective.Midrange` | `perspective:var(--perspective-midrange)` (`800px`) |
| `perspective-distant` | `.Transform.Perspective.Distant` | `perspective:var(--perspective-distant)` (`1200px`) |
| `perspective-origin-center` | `.Transform.PerspectiveOrigin.Center` | `perspective-origin:center` |
| `perspective-origin-top` | `.Transform.PerspectiveOrigin.Top` | `perspective-origin:top` |
| `perspective-origin-bottom` | `.Transform.PerspectiveOrigin.Bottom` | `perspective-origin:bottom` |
| `perspective-origin-left` | `.Transform.PerspectiveOrigin.Left` | `perspective-origin:left` |
| `perspective-origin-right` | `.Transform.PerspectiveOrigin.Right` | `perspective-origin:right` |
| `zoom-0` | `.Transform.Zoom.0` | `zoom:0` |
| `zoom-50` | `.Transform.Zoom.50` | `zoom:0.5` |
| `zoom-75` | `.Transform.Zoom.75` | `zoom:0.75` |
| `zoom-100` | `.Transform.Zoom.100` | `zoom:1` |
| `zoom-125` | `.Transform.Zoom.125` | `zoom:1.25` |
| `zoom-150` | `.Transform.Zoom.150` | `zoom:1.5` |
| `zoom-200` | `.Transform.Zoom.200` | `zoom:2` |

`zoom-50` emits `0.5` **with** the leading zero while `scale-50` emits `.5` **without** it. That is
what `§ 16.11` and `§ 16.5` respectively say, and the two rows sit four subsections apart, which is
exactly why they must be copied and not remembered.

`.Transform.Style.Preserve3d` is the leaf name for `transform-3d`: a leaf cannot begin with a digit,
and naming it after the value it emits is clearer than `X3d`.

**Acceptance:**
- [x] All thirty-one rows return the reference's strings. — held: `Transform.Origin — the nine rows…`, `Transform.Style / Backface — four rows…`, `Transform.Perspective — six rows…`, `Transform.PerspectiveOrigin — …`, `Transform.Zoom — the seven rows of § 16.11`
- [x] `.Transform.Zoom.50` returns `zoom:0.5` and `.Transform.Scale.50` returns `scale:.5` — the two
      asserted in adjacent lines, with a comment saying the difference is the reference's. — held: `Transform — scale:.5 and zoom:0.5, and the difference is the reference's`
- [x] The five perspective keywords emit `themeVar(...)` lookups; **no `px` literal appears in any
      perspective arm**, and the five entries are contributed to front 54's theme. — held (shape: the five entries are `transformEntries()`, composed with `extendTheme`, not in `defaultTheme()`): `Transform.Perspective — six rows, five of them theme references`, `transformEntries — the five --perspective-* of § 16.2`

### Step 6 — `transform` (the shorthand) and one new arm in `tokenToSheet`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `transform-none` | `.Transform.Shorthand.None` | `transform:none` |
| `transform` | `.Transform.Shorthand.Cpu` | `transform:translate(var(--tw-translate-x), var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))` |
| `transform-cpu` | `.Transform.Shorthand.Cpu` | as above — `§ 16.7` gives `transform` and `transform-cpu` the identical value, so they are one token |
| `transform-gpu` | `.Transform.Shorthand.Gpu` | `transform:translate3d(var(--tw-translate-x), var(--tw-translate-y), 0) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))` |

Three of these four reference the `--tw-*` chain variables. They now resolve: the axis tokens write
them and front 54's theme carries the identity defaults, so `transform-gpu` alongside
`.Transform.Rotate.45` composes as upstream does. `None` needs neither.

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, reached through `declSheet(...)`.

```bp
        Transform(_inner) -> declSheet(transformTokenToCss(_inner, th));
        TransformRotateRaw(value) -> declSheet("rotate:" + value);
        TransformTranslateRaw(value) -> declSheet("translate:" + value);
```

Three arms, not one: the two top-level payload variants are siblings of `Transform`, not leaves
inside it. Each destructures by its declared field name (`value`) — a positional bind type-checks
and is `undefined` at run time.

**Acceptance:**
- [x] `.Transform.Shorthand.Cpu` and `.Gpu` emit the reference's strings verbatim, `translate3d` and
      the `, 0` argument included — and now resolve, because the `--tw-*` identity defaults are
      theme entries and the axis tokens write their own. — superseded: verbatim held (`Transform.Shorthand — § 16.7's four rows, verbatim`); they do not resolve — no emilia token sets the `--tw-*` chain, marked inert (AGENTS.md front 45; `…the --tw-* chain it reads is written by nothing`)
- [x] The arm sits between front 44's two arms and front 46's, in front-number order, and is one
      `declSheet(...)` call. — held (shape: three arms, after front 44's four; front 46 has no arm yet): `emilia.bp:tokenToSheet`
- [x] `tokenToSheet` still has no `_` arm. — held: `emilia.bp:tokenToSheet` has no `_` arm

## Examples

- [`./examples/transforms-example.bp`](./examples/transforms-example.bp) — the whole `Transform`
  catalogue, the inert `var(--tw-*)` families marked as such at their declaration site, then a card
  that lifts and scales on hover with the front 44 transition that makes the motion visible, plus a
  disclosure chevron that rotates 180° when open.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A numeric enum leaf is declared as bare digits and there is no spelling for a negative one, so `-rotate-12`, `-translate-y-2` and every other negative utility has no direct token | `Transform.Rotate.Neg`, and every negative scale any emilia front would want | a `Neg { … }` sub-section holding the magnitudes: `.Transform.Rotate.Neg.12`, read as "rotate, negative, twelve" | allow a signed numeric leaf in a section body — `Rotate { -12, 0, 12 }` declared, `.Transform.Rotate.-12` in expression position — or a documented `Neg` convention blessed by the grammar |
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's two escape hatches, written `Transform.Rotate.Raw` and `Transform.Translate.Raw` in the first draft | the variants move to the **top level** of `Token` per contract `§ 4a`: `Token.TransformRotateRaw(value: string)` and `Token.TransformTranslateRaw(value: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same two, now top-level: `[.TransformRotateRaw("17deg")]` still trips the parser | a wrapper fn returning the token (`fn rawRotate(v: string) -> Token { return Token.TransformRotateRaw(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| ~~`translate-*`, `transform`, `transform-cpu`, `transform-gpu` doing anything~~ | **Closed by front 56.** `Rule.declarations` keeps the `--tw-*` writer and the shorthand reader in one rule, so the chain resolves; front 54's theme carries the identity defaults. What this front owes front 54 is those default entries, named in its `TODO.md`. |
| `rotate-x-*`, `rotate-y-*`, `rotate-z-*`, `translate-z-*`, `scale-z-*` | Not in the reference. `§ 16` has eleven subsections and none of them enumerates a 3-D axis variant: `§ 16.5` gives `scale-x-50` and `scale-y-50` and no `z`, `§ 16.10` gives `translate-x-*` and no `translate-z`, and `§ 16.4` gives a single unaxed `rotate`. Tokens for them would be written from memory, which this milestone does not do. `.Transform.Style.Preserve3d`, `.Transform.Backface.*` and the perspective family — the rest of the 3-D surface — **are** in the reference and this front ships them. |
| `skew-x` / `skew-y` as property names | See Step 4. The reference's column says it; no browser applies it. Flagged, transcribed, and pending a check against the upstream page. |

## Test plan

`repository/emilia/test/transforms_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert transformTokenToCss(<token>, th) == "<css>"` per row
   of the six tables, asserting the **whole** string including the shorthand half of a
   two-declaration row. A table row and a test line are the same fact written twice.
2. **The two decimal conventions.** `scale:.5` and `zoom:0.5` asserted in adjacent lines with the
   comment that the difference is the reference's, so the next person to "fix" one of them fails a
   test instead of shipping a divergence.
3. **The axis pairs.** `ScaleX.50` / `ScaleY.50` and `TranslateX.Half` / `TranslateY.Half` asserted
   adjacently — swapped components are the likeliest defect here and are invisible to a one-sided
   test.
4. **The chain, asserted as composition.** `[.Transform.TranslateX.Half, .Transform.TranslateY.Half]`
   produces `--tw-translate-x:50%`, `--tw-translate-y:50%` and one `translate:` shorthand in
   `Rule.declarations`. The first draft of this front asserted the opposite (two shorthands,
   last-wins); that test is replaced, not kept.
5. **No resolved theme literals.** A test greps this front's block of `emilia.bp` for `px` and
   `rem` and fails on either outside the `Px` leaves, whose `1px` is the reference's own literal
   value rather than a theme entry.
6. **The one that needs no chain.** `[.Transform.Rotate.180, .Transform.Origin.TopLeft]` produces
   `rotate:180deg` and `transform-origin:top left` — two independent properties in v4, which is the
   realistic use of this front.
7. **Variant nesting with front 44.** `Token.Hover([.Transform.Scale.105])` reaches front 34's
   `nestVariant` with the inner declaration `scale:1.05`; this front asserts the declaration, not
   the wrap. The card example's full token list round-trips through `emilia()` and `await flush()`
   to a literal `<style>` string.
8. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Transform` exists as a top-level section with `Rotate`, `Scale`, `ScaleX`, `ScaleY`,
      `TranslateX`, `TranslateY`, `Translate`, `SkewX`, `SkewY`, `Origin`, `Style`, `Backface`,
      `Perspective`, `PerspectiveOrigin`, `Zoom`, `Shorthand`, fenced by a `front 45` banner in
      `tokens.bp` and appended after front 44's block. — **open:** no `Translate` (both-axes) section — left as a reference gap (AGENTS.md front 45), `rawTranslate` covers the use; the other fifteen exist, fenced, after front 44's block
- [ ] `transformTokenToCss` and its sub-dispatchers are fenced by a `front 45` banner in
      `emilia.bp`, appended after front 44's block, and take `th: Theme` per contract `§ 4a`. — **open:** fenced and appended after front 44's block, but only `transformTokenToCss` takes `th: Theme`; its sixteen sub-dispatchers do not
- [x] One arm added to `tokenToSheet`, a `declSheet(...)` call, in front-number order, and no other
      line of that `case` moved. — held (shape: three arms — `Transform` and the two `Raw` variants, as Step 6 counts): `emilia.bp:tokenToSheet`
- [x] Every axis token emits its `--tw-*` variable and the shorthand; the five perspective keywords
      are `themeVar(...)` lookups; the `--tw-*` identity defaults and the five `--perspective-*`
      entries are contributed to front 54. — superseded for the axis half: one declaration with a `cssVarOr` fallback, no theme entry possible (AGENTS.md front 45); perspective held — `transformEntries — the five --perspective-* of § 16.2`
- [x] The `skew-x` flag, the `--tw-*` chain shape and the `Neg` convention are stated in the
      `tokens.bp` docblock, not only here. — held: `tokens.bp` header `Transform` entry and front 45 block comment
- [x] `repository/emilia/AGENTS.md` records the new section and all three notes. — held: AGENTS.md front 45 section ("THREE ROWS OF § 16 DID NOT SURVIVE")
- [x] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them. — held: `modules/emilia` 569/569 on commonJS and erlang (AGENTS.md § Test surface); `Transform — the class name is a literal, and both targets must agree`
