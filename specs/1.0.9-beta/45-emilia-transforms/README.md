# Front 45 — emilia transforms

**Track:** D emilia
**Priority:** medium — a hover that lifts a card, a chevron that flips when a menu opens and a modal that scales in are all one property, and `emilia` has no token for it
**Target:** comptime
**Wave:** 1
**Depends on:** 44 (transitions — a transform without a transition snaps, so the examples pair the two; the dependency is on the token existing, not on its dispatcher)
**Owns:** token section `Transform` in `repository/emilia/src/tokens.bp` · dispatcher `transformTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/transforms_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 16. Transforms` · https://tailwindcss.com/docs/rotate
**Replaces:** `1.0.8-beta/11-emilia-transforms`

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
- `tokensToCss` joins tokens with `;` — `emilia.bp:103`. `rotate`, `scale` and `translate` are
  independent CSS properties in v4 (not `transform` functions), so two of them in one list compose
  correctly with no extra machinery. `skew` is the exception — see Step 4.

## Mechanism

`Transform` is one top-level section with eleven sub-sections, one per `§ 16` subsection, and one
dispatcher routing to eleven sub-dispatchers. Every leaf maps to one property/value pair.

**Where the values come from.** Every property name and value is copied from the reference.
`§ 16.2` gives each perspective keyword's literal in parentheses — `(100px)`, `(300px)`, `(500px)`,
`(800px)`, `(1200px)` — so those tokens emit the literal rather than `var(--perspective-near)`:
`emilia` registers a bare rule body with no `@theme` block in front of it, so the variable would
resolve to nothing at render time.

`§ 16.7` (`transform`) and `§ 16.10` (`translate`) give values that reference `var(--tw-translate-x)`,
`var(--tw-rotate)` and friends. Those are Tailwind's internal chain variables and `emilia` has no
custom-property cascade to feed them, so a token emitting them is inert. They are shipped verbatim —
the reference's column, unmodified — and the front says plainly that they do nothing until a
custom-property layer exists. Inventing a resolved value for them would mean writing CSS the
reference does not contain.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`). The **value** is byte-equal to the reference; the separator is emilia's.

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
| `rotate-[17deg]` | `Token.Transform.Rotate.Raw(value: v)` | `rotate:<v>` |

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
            Raw(value: string),
        }
    }
}
```

**Acceptance:**
- [ ] `tokensToCss([.Transform.Rotate.90])` returns `rotate:90deg`.
- [ ] `tokensToCss([.Transform.Rotate.Neg.12])` returns `rotate:-12deg` — one `-`, no space.
- [ ] `rotateToCss` and `rotateNegToCss` are exhaustive with no `_` arm.

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
- [ ] `tokensToCss([.Transform.Scale.75])` returns `scale:.75`; a leading `0` fails.
- [ ] `tokensToCss([.Transform.ScaleX.50])` returns `scale:.5 1` and `.ScaleY.50` returns `scale:1 .5`
      — asserted in adjacent lines, because a copy-paste between them is invisible otherwise.
- [ ] `.Transform.Scale.100` returns `scale:1`, not `scale:1.0`.

### Step 3 — `translate`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `translate-x-0` | `.Transform.TranslateX.0` | `translate:0 var(--tw-translate-y)` |
| `translate-x-px` | `.Transform.TranslateX.Px` | `translate:1px var(--tw-translate-y)` |
| `translate-x-1` | `.Transform.TranslateX.1` | `translate:calc(var(--spacing) * 1) var(--tw-translate-y)` |
| `translate-x-1/2` | `.Transform.TranslateX.Half` | `translate:50% var(--tw-translate-y)` |
| `translate-x-full` | `.Transform.TranslateX.Full` | `translate:100% var(--tw-translate-y)` |
| `translate-y-0` | `.Transform.TranslateY.0` | `translate:var(--tw-translate-x) 0` |
| `translate-y-px` | `.Transform.TranslateY.Px` | `translate:var(--tw-translate-x) 1px` |
| `translate-y-1` | `.Transform.TranslateY.1` | `translate:var(--tw-translate-x) calc(var(--spacing) * 1)` |
| `translate-y-1/2` | `.Transform.TranslateY.Half` | `translate:var(--tw-translate-x) 50%` |
| `translate-y-full` | `.Transform.TranslateY.Full` | `translate:var(--tw-translate-x) 100%` |
| `translate-[…]` | `Token.Transform.Translate.Raw(value: v)` | `translate:<v>` |

`§ 16.10` enumerates the five `translate-x-*` rows and this front mirrors them for `y` by swapping
the two components — the derivation is mechanical and is stated here so it can be checked.

**Every one of these ten tokens is inert on its own.** The value references `--tw-translate-x` or
`--tw-translate-y`, which Tailwind sets from the sibling utility and `emilia` cannot set at all. A
list containing both `.TranslateX.Half` and `.TranslateY.Half` emits two `translate:` declarations
and the second wins, so the pair does not combine either. The usable form is the `Raw` leaf:
`rawTranslate("50% 50%")`. This is recorded under *Deferred*, stated in the `tokens.bp` docblock,
and asserted as a documented behaviour in the test file.

**Acceptance:**
- [ ] The ten scale rows return the reference's strings verbatim, `var(--tw-…)` included.
- [ ] `tokensToCss([.Transform.TranslateX.1])` returns
      `translate:calc(var(--spacing) * 1) var(--tw-translate-y)` — spaces around the `*` kept.
- [ ] A test asserts that two translate tokens in one list produce two `translate:` declarations,
      naming the behaviour rather than hiding it.

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
- [ ] All twelve rows emit the reference's property name verbatim.
- [ ] The `tokens.bp` docblock carries the flag above, so the next reader does not have to rediscover
      it.
- [ ] A reviewer has checked the upstream page and recorded the outcome in the front's `TODO.md`.

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
| `perspective-none` | `.Transform.Perspective.None` | `perspective:none` |
| `perspective-dramatic` | `.Transform.Perspective.Dramatic` | `perspective:100px` |
| `perspective-near` | `.Transform.Perspective.Near` | `perspective:300px` |
| `perspective-normal` | `.Transform.Perspective.Normal` | `perspective:500px` |
| `perspective-midrange` | `.Transform.Perspective.Midrange` | `perspective:800px` |
| `perspective-distant` | `.Transform.Perspective.Distant` | `perspective:1200px` |
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
- [ ] All thirty-one rows return the reference's strings.
- [ ] `.Transform.Zoom.50` returns `zoom:0.5` and `.Transform.Scale.50` returns `scale:.5` — the two
      asserted in adjacent lines, with a comment saying the difference is the reference's.
- [ ] The five perspective keywords emit `px` literals; no `var(` appears in any perspective output.

### Step 6 — `transform` (the shorthand) and one new arm in `tokenToCss`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `transform-none` | `.Transform.Shorthand.None` | `transform:none` |
| `transform` | `.Transform.Shorthand.Cpu` | `transform:translate(var(--tw-translate-x), var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))` |
| `transform-cpu` | `.Transform.Shorthand.Cpu` | as above — `§ 16.7` gives `transform` and `transform-cpu` the identical value, so they are one token |
| `transform-gpu` | `.Transform.Shorthand.Gpu` | `transform:translate3d(var(--tw-translate-x), var(--tw-translate-y), 0) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))` |

Three of these four reference `--tw-*` chain variables `emilia` cannot set, so they are inert for the
same reason `translate` is. `None` works.

```bp
        Transform(_inner) -> transformTokenToCss(_inner);
```

**Acceptance:**
- [ ] `.Transform.Shorthand.Cpu` and `.Gpu` emit the reference's strings verbatim, `translate3d` and
      the `, 0` argument included.
- [ ] The `tokenToCss` arm sits between front 44's two arms and front 46's, in front-number order.
- [ ] `tokenToCss` still has no `_` arm.

## Examples

- [`./examples/transforms-example.bp`](./examples/transforms-example.bp) — the whole `Transform`
  catalogue, the inert `var(--tw-*)` families marked as such at their declaration site, then a card
  that lifts and scales on hover with the front 44 transition that makes the motion visible, plus a
  disclosure chevron that rotates 180° when open.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A numeric enum leaf is declared as bare digits and there is no spelling for a negative one, so `-rotate-12`, `-translate-y-2` and every other negative utility has no direct token | `Transform.Rotate.Neg`, and every negative scale any emilia front would want | a `Neg { … }` sub-section holding the magnitudes: `.Transform.Rotate.Neg.12`, read as "rotate, negative, twelve" | allow a signed numeric leaf in a section body — `Rotate { -12, 0, 12 }` declared, `.Transform.Rotate.-12` in expression position — or a documented `Neg` convention blessed by the grammar |
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Transform.Rotate.Raw("17deg")]` trips the parser | every `Raw(value: string)` leaf — and here `Translate.Raw` is not a convenience but the only translate form that works | wrap the constructor in a fn (`fn rawRotate(v: string) -> Token { return Token.Transform.Rotate.Raw(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Transform.Rotate.Raw("17deg")];` |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| `translate-*`, `transform`, `transform-cpu`, `transform-gpu` doing anything | Their values reference `--tw-translate-x`, `--tw-rotate`, `--tw-skew-x`, `--tw-scale-x` and friends. Upstream these are set by sibling utilities and read back by one declaration; `emilia` emits a flat rule body with no custom-property cascade and cannot set them. The tokens are faithful transcriptions and are inert. The working form is the `Raw` leaf. A custom-property layer is a separate front. |
| `rotate-x-*`, `rotate-y-*`, `rotate-z-*`, `translate-z-*`, `scale-z-*` | Not in the reference. `§ 16` has eleven subsections and none of them enumerates a 3-D axis variant: `§ 16.5` gives `scale-x-50` and `scale-y-50` and no `z`, `§ 16.10` gives `translate-x-*` and no `translate-z`, and `§ 16.4` gives a single unaxed `rotate`. Tokens for them would be written from memory, which this milestone does not do. `.Transform.Style.Preserve3d`, `.Transform.Backface.*` and the perspective family — the rest of the 3-D surface — **are** in the reference and this front ships them. |
| `skew-x` / `skew-y` as property names | See Step 4. The reference's column says it; no browser applies it. Flagged, transcribed, and pending a check against the upstream page. |

## Test plan

`repository/emilia/test/transforms_test.bp`, run by `botopink test` from `repository/emilia/` and by
`zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it emits
a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the six
   tables. A table row and a test line are the same fact written twice.
2. **The two decimal conventions.** `scale:.5` and `zoom:0.5` asserted in adjacent lines with the
   comment that the difference is the reference's, so the next person to "fix" one of them fails a
   test instead of shipping a divergence.
3. **The axis pairs.** `ScaleX.50` / `ScaleY.50` and `TranslateX.Half` / `TranslateY.Half` asserted
   adjacently — swapped components are the likeliest defect here and are invisible to a one-sided
   test.
4. **The inert families, asserted as inert.** A test named for it asserts that
   `tokensToCss([.Transform.TranslateX.Half, .Transform.TranslateY.Half])` contains two `translate:`
   declarations, which documents the non-composition instead of leaving it to be discovered.
5. **The one that actually moves.** `tokensToCss([.Transform.Rotate.180, .Transform.Origin.TopLeft])`
   returns `rotate:180deg;transform-origin:top left` — two independent properties in v4, composing
   correctly, which is the realistic use of this front.
6. **Modifier nesting with front 44.** `Token.Hover([.Transform.Scale.105])` wraps as
   `:hover{scale:1.05}`, and the card example's full token list round-trips through `emilia()` and
   `await flush()` to a literal `<style>` string.
7. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   `commonJS` and `erlang` must agree on the `djb2` hash. Every value here is ASCII, the condition
   `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Transform` exists as a top-level section with `Rotate`, `Scale`, `ScaleX`, `ScaleY`,
      `TranslateX`, `TranslateY`, `Translate`, `SkewX`, `SkewY`, `Origin`, `Style`, `Backface`,
      `Perspective`, `PerspectiveOrigin`, `Zoom`, `Shorthand`, fenced by a `front 45` banner in
      `tokens.bp` and appended after front 44's block.
- [ ] `transformTokenToCss` and its sub-dispatchers are fenced by a `front 45` banner in
      `emilia.bp`, appended after front 44's block.
- [ ] One arm added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] The `skew-x` flag, the inert `var(--tw-*)` families and the `Neg` convention are stated in the
      `tokens.bp` docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the new section and all three caveats.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
