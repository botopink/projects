# Front 44 — emilia transitions and animation

**Track:** D emilia
**Priority:** high — every hover, focus and open/close state `emilia` already emits snaps instantly today, because there is no transition token anywhere in the library
**Target:** comptime
**Wave:** 1
**Depends on:** 34 (modifiers — a transition is only observable when a state variant changes a property, so the examples pair every `Transition` token with a `Hover` or `Focus`)
**Owns:** token sections `Transition`, `Animate` in `repository/emilia/src/tokens.bp` · dispatcher `transitionTokenToCss` (and its sibling `animateTokenToCss`) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/transitions_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 15. Transições & Animação` (animation literals from `§ 21.6`) · https://tailwindcss.com/docs/transition-property
**Replaces:** `1.0.8-beta/10-emilia-transitions`

---

## Problem

`emilia` has had `Hover`, `Focus` and `Active` modifiers since `tokens.bp:264-266`, and every one of
them changes a property instantly. There is no `transition` token, no `duration`, no timing function
and no `animation` — `repository/emilia/src/tokens.bp:36-270` has nothing under any of those names.
A button that darkens on hover darkens in one frame; a panel that fades in does not fade.

The gap is more than cosmetic for one specific reason: a loading state has no token at all. Tailwind's
four built-in animations — `spin`, `ping`, `pulse`, `bounce` — are the entire vocabulary most apps
use for "something is happening", and without them a spinner needs a hand-written stylesheet, which
puts a second styling mechanism next to `emilia` in the same codebase.

This front is also where `emilia`'s one-rule-body model meets its first hard limit. A `transition`
utility is one property/value pair and maps cleanly. An `animation` utility is a shorthand that
names a `@keyframes` block, and `emilia`'s host cell registers `name → body` and renders
`.name{body}` — there is no channel for a top-level at-rule. The front ships the shorthand, states
the limit, and does not pretend the keyframes arrive with it.

## Current state

- No `Transition`, no `Animate`, no `transition`, `animation`, `duration` or `ease` string anywhere
  in `repository/emilia/src/`.
- Six modifiers exist and all of them are instantaneous — `tokens.bp:264-269`,
  `emilia.bp:85-90`.
- `register(name, body)` writes one `name → body` pair and `flushSheet()` renders each as
  `.<name>{<body>}` — `emilia.bp:23-30`. Every rule emilia can emit is a class selector with a
  declaration list, which is exactly what a `@keyframes` block is not.
- `tokensToCss` joins tokens with `;` — `emilia.bp:103`. A token whose body is itself several
  declarations joined by `;` composes with no special handling, which is what makes the multi-
  declaration `transition-*` utilities expressible as single tokens.

## Mechanism

`§ 15.1` is the unusual part and it decides the design. `transition-all` is not one declaration —
the reference's column for it reads
`transition-property: all; transition-timing-function: var(--ease-out); transition-duration: 150ms`,
three declarations from one utility, and the same for `transition`, `transition-colors`,
`transition-opacity`, `transition-shadow` and `transition-transform`. `emilia` handles this without
new machinery: `tokensToCss` already joins with `;`, so a leaf that returns
`"transition-property:all;transition-timing-function:var(--ease-out);transition-duration:150ms"` drops
into a rule body unchanged. Every such leaf is one token that means one utility, which keeps the
token-to-class mapping one-to-one.

`Transition` therefore has three kinds of leaf: the six preset bundles (three declarations each),
`None` (one declaration), and the three scales — `Duration`, `Ease`, `Delay` — which are one
declaration each and override whatever a preset set.

`Animate` is five leaves against `§ 15.6`, with the literals from `§ 21.6`.

**Where the values come from.** Every property and value is copied from the reference. `§ 21.6`
gives the four animation shorthands literally, so `Animate.Spin` emits `animation:spin 1s linear infinite`
rather than `animation:var(--animate-spin)` — `emilia` registers a bare rule body with no `@theme`
block in front of it, so the variable would resolve to nothing. `--ease-in`, `--ease-out` and
`--ease-in-out` have no literal anywhere in the reference, so those tokens emit the `var(--…)`
reference verbatim exactly as `§ 15.1` and `§ 15.4` write it, and the front records the dependency
rather than inventing a cubic-bezier.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`), and the multi-declaration bodies join with `;` and no space, matching
`tokensToCss`. The **values** are byte-equal to the reference; the separators are emilia's.

## Steps

### Step 1 — `transition-property`, the six presets and `none`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `transition-none` | `.Transition.None` | `transition-property:none` |
| `transition` | `.Transition.Base` | `transition-property:color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-all` | `.Transition.All` | `transition-property:all;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-colors` | `.Transition.Colors` | `transition-property:color, background-color, border-color, text-decoration-color, fill, stroke;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-opacity` | `.Transition.Opacity` | `transition-property:opacity;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-shadow` | `.Transition.Shadow` | `transition-property:box-shadow;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-transform` | `.Transition.Transform` | `transition-property:transform;transition-timing-function:var(--ease-out);transition-duration:150ms` |
| `transition-[…]` | `Token.Transition.Property(value: v)` | `transition-property:<v>` |

The bare `transition` utility is spelled `.Transition.Base`, not `.Transition.Default`: `default` is
in the language's keyword table (`modules/compiler-core/src/lexer.zig:721-767`), and a leaf whose
name differs from a keyword only by case is an avoidable hazard.

Note the space after each comma inside `transition-property` — `color, background-color, …`. That is
the reference's spelling and byte-equality is the gate; a serialiser that strips the spaces fails.

```bp
pub type Token {
    // ── front 44 · transitions and animation ─────────────────────────────
    Transition {
        None,
        Base,
        All,
        Colors,
        Opacity,
        Shadow,
        Transform,
        Property(value: string),
        Behavior {
            Normal,
            Discrete,
        }
        Duration {
            0,
            75,
            100,
            150,
            200,
            300,
            500,
            700,
            1000,
        }
        Ease {
            Linear,
            In,
            Out,
            InOut,
        }
        Delay {
            0,
            75,
            100,
            150,
            200,
            300,
            500,
            700,
            1000,
        }
    }
}
```

**Acceptance:**
- [ ] The seven preset leaves return the exact strings above, commas and spaces included.
- [ ] `.Transition.Base` lists eleven properties in the reference's order; a test asserts the whole
      string, not a `contains`.
- [ ] `.Transition.None` returns one declaration, not three.
- [ ] `transitionTokenToCss` is exhaustive with no `_` arm.

### Step 2 — `transition-behavior`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `transition-normal` | `.Transition.Behavior.Normal` | `transition-behavior:normal` |
| `transition-discrete` | `.Transition.Behavior.Discrete` | `transition-behavior:allow-discrete` |

`transition-discrete` emits `allow-discrete`, not `discrete` — the class name and the CSS value do
not match, which is exactly the kind of row that gets written from memory and gets written wrong.

**Acceptance:**
- [ ] `tokensToCss([.Transition.Behavior.Discrete])` returns `transition-behavior:allow-discrete`.

### Step 3 — `duration`, `ease`, `delay`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `duration-0` | `.Transition.Duration.0` | `transition-duration:0ms` |
| `duration-75` | `.Transition.Duration.75` | `transition-duration:75ms` |
| `duration-100` | `.Transition.Duration.100` | `transition-duration:100ms` |
| `duration-150` | `.Transition.Duration.150` | `transition-duration:150ms` |
| `duration-200` | `.Transition.Duration.200` | `transition-duration:200ms` |
| `duration-300` | `.Transition.Duration.300` | `transition-duration:300ms` |
| `duration-500` | `.Transition.Duration.500` | `transition-duration:500ms` |
| `duration-700` | `.Transition.Duration.700` | `transition-duration:700ms` |
| `duration-1000` | `.Transition.Duration.1000` | `transition-duration:1000ms` |
| `ease-linear` | `.Transition.Ease.Linear` | `transition-timing-function:linear` |
| `ease-in` | `.Transition.Ease.In` | `transition-timing-function:var(--ease-in)` |
| `ease-out` | `.Transition.Ease.Out` | `transition-timing-function:var(--ease-out)` |
| `ease-in-out` | `.Transition.Ease.InOut` | `transition-timing-function:var(--ease-in-out)` |
| `delay-0` | `.Transition.Delay.0` | `transition-delay:0ms` |
| `delay-75` | `.Transition.Delay.75` | `transition-delay:75ms` |
| `delay-100` | `.Transition.Delay.100` | `transition-delay:100ms` |
| `delay-150` | `.Transition.Delay.150` | `transition-delay:150ms` |
| `delay-200` | `.Transition.Delay.200` | `transition-delay:200ms` |
| `delay-300` | `.Transition.Delay.300` | `transition-delay:300ms` |
| `delay-500` | `.Transition.Delay.500` | `transition-delay:500ms` |
| `delay-700` | `.Transition.Delay.700` | `transition-delay:700ms` |
| `delay-1000` | `.Transition.Delay.1000` | `transition-delay:1000ms` |

`ease-linear` is the one timing function with a literal in the reference; the other three emit the
`var(--…)` reference the reference's column writes, and are inert until a theme preamble defines
them. A list that pairs a preset with `Ease.Out` therefore emits `var(--ease-out)` twice — harmless,
and the second wins, which is the intent.

**Acceptance:**
- [ ] All nine duration steps and all nine delay steps carry the `ms` unit, `0ms` included.
- [ ] `.Transition.Ease.Linear` emits the literal; the other three emit `var(--ease-…)` verbatim.
- [ ] `tokensToCss([.Transition.Colors, .Transition.Duration.300])` returns the preset's three
      declarations followed by `;transition-duration:300ms` — the override is last and therefore wins.

### Step 4 — `Animate`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `animate-none` | `.Animate.None` | `animation:none` |
| `animate-spin` | `.Animate.Spin` | `animation:spin 1s linear infinite` |
| `animate-ping` | `.Animate.Ping` | `animation:ping 1s cubic-bezier(0, 0, 0.2, 1) infinite` |
| `animate-pulse` | `.Animate.Pulse` | `animation:pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite` |
| `animate-bounce` | `.Animate.Bounce` | `animation:bounce 1s infinite` |
| `animate-[…]` | `Token.Animate.Raw(value: v)` | `animation:<v>` |

The four literals are `§ 21.6`'s, commas and spaces included: `cubic-bezier(0, 0, 0.2, 1)` has a
space after each comma.

**These four tokens emit a shorthand that names a `@keyframes` block `emilia` cannot emit.** The
host cell registers `name → body` and renders `.<name>{<body>}` (`emilia.bp:23-30`); there is no
channel for a top-level at-rule. The token is correct and the animation does not run until the four
`@keyframes` blocks are present in the document by some other means. This is stated in *Deferred*,
in the `tokens.bp` docblock, and in a test that asserts the shorthand and says in its name that the
keyframes are out of scope.

**Acceptance:**
- [ ] `tokensToCss([.Animate.Pulse])` returns `animation:pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite`.
- [ ] `animateTokenToCss` is exhaustive over six leaves with no `_` arm.
- [ ] No test in this front asserts that a `@keyframes` block was emitted, and the `tokens.bp`
      docblock says why.

### Step 5 — two new arms in `tokenToCss`

```bp
        Transition(_inner) -> transitionTokenToCss(_inner);
        Animate(_inner) -> animateTokenToCss(_inner);
```

**Acceptance:**
- [ ] The two arms sit between front 43's arm and front 45's, in front-number order.
- [ ] `tokenToCss` still has no `_` arm.

## Examples

- [`./examples/transitions-example.bp`](./examples/transitions-example.bp) — the `Transition` and
  `Animate` catalogues as typed `Token[]` lists, the preset-then-override ordering shown as working
  code, then a submit button that transitions its colours on hover and swaps to a spinner while the
  form is in flight.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Animate.Raw("fade 300ms ease-out")]` trips the parser | `Transition.Property` and `Animate.Raw` — the arbitrary-value escape hatches, and the only way to name a custom animation | wrap the constructor in a fn (`fn rawAnimate(v: string) -> Token { return Token.Animate.Raw(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Animate.Raw("fade 300ms ease-out")];` |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| The four `@keyframes` blocks | `register(name, body)` renders `.<name>{<body>}` — every rule `emilia` emits is a class selector with a declaration list. A `@keyframes` block is a top-level at-rule with nested percentage selectors and does not fit that shape. Emitting it needs a second host cell (a raw-rule channel) in `emilia.bp`, which is outside this front's dispatcher-only ownership. Until then the four `Animate` tokens are correct shorthands whose keyframes the application supplies. |
| `--ease-in`, `--ease-out`, `--ease-in-out` literals | The reference names the variables at `§ 15.1` and `§ 15.4` and never gives their values. The three tokens emit the `var(--…)` reference verbatim and are inert until a theme preamble defines them. |
| `@starting-style` | Not in the reference. `§ 15` has five subsections — property, behavior, duration, timing function, delay — plus `§ 15.6` animation, and none of them mentions `@starting-style`. A token for it would be written from memory, which this milestone does not do. If it belongs in `emilia`, it belongs in a front whose reference section covers it. |

## Test plan

`repository/emilia/test/transitions_test.bp`, run by `botopink test` from `repository/emilia/` and
by `zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it
emits a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the four
   tables. The six multi-declaration presets are asserted whole, never with `contains` — the whole
   point of those rows is the exact property list and its exact punctuation.
2. **The punctuation that is easy to lose.** `color, background-color` keeps its space after the
   comma; `cubic-bezier(0, 0, 0.2, 1)` keeps all three. A test asserting these as literals is what
   stops a well-meaning whitespace normaliser.
3. **`allow-discrete`.** Asserted by itself, because the class name says `discrete` and the value
   says `allow-discrete`.
4. **Override ordering.** `tokensToCss([.Transition.All, .Transition.Duration.700, .Transition.Ease.Linear])`
   returns the preset followed by the two overrides in list order, so the later declarations win.
   The test asserts the full string, which pins the ordering contract `emilia()` hashes.
5. **Modifier nesting.** `Token.Hover([.Transition.Colors])` wraps as
   `:hover{transition-property:color, …;transition-timing-function:var(--ease-out);transition-duration:150ms}`
   — the realistic shape, and the one that proves a multi-declaration body survives the recursive
   `tokensToCss` path.
6. **The keyframes limit, asserted as a limit.** A test named for it asserts
   `tokensToCss([.Animate.Spin]) == "animation:spin 1s linear infinite"` and asserts nothing about
   keyframes, so the gap is visible in the suite rather than only in this document.
7. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   `commonJS` and `erlang` must agree on the `djb2` hash. Every value here is ASCII, the condition
   `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Transition` and `Animate` exist as top-level sections, fenced by a `front 44` banner in
      `tokens.bp` and appended after front 43's block.
- [ ] `transitionTokenToCss`, `animateTokenToCss` and their sub-dispatchers are fenced by a
      `front 44` banner in `emilia.bp`, appended after front 43's block.
- [ ] Two arms added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] The `@keyframes` limit and the `--ease-*` dependency are stated in the `tokens.bp` docblock,
      not only here.
- [ ] `repository/emilia/AGENTS.md` records the two new sections and both limits.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
