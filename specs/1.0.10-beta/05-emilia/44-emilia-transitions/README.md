# Front 44 — emilia transitions and animation

**Track:** D emilia
**Priority:** high — every hover, focus and open/close state `emilia` already emits snaps instantly today, because there is no transition token anywhere in the library
**Target:** comptime
**Wave:** 3
**Depends on:** 34 (modifiers — a transition is only observable when a state variant changes a property, so the examples pair every `Transition` token with a `Hover` or `Focus`)
**Owns:** token sections `Transition`, `Animate` in `repository/emilia/src/tokens.bp` · dispatcher `transitionTokenToCss` (and its sibling `animateTokenToCss`) in `repository/emilia/src/emilia.bp` · `repository/emilia/test/transitions_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, the class-name hash (std `content_hash.contentHash` since decision 116), `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 15. Transições & Animação` (animation literals from `§ 21.6`) · https://tailwindcss.com/docs/transition-property

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

This front is also the first one whose output is not a declaration list. A `transition` utility is
one property/value pair and maps cleanly. An `animation` utility is a shorthand that **names** a
`@keyframes` block, and a keyframes block is not a class rule. Front 56 provides the channel —
`blockSheet(header, body)` and `Sheet.blocks`, hoisted by `renderDocument` — so `Animate` is the one
sub-dispatcher in this front that returns a `Sheet` rather than a declaration string.

## Current state

- No `Transition`, no `Animate`, no `transition`, `animation`, `duration` or `ease` string anywhere
  in `repository/emilia/src/`.
- Six modifiers exist and all of them are instantaneous — `tokens.bp:264-269`,
  `emilia.bp:85-90`.
- `register(name, body)` writes one `name → body` pair and `flushSheet()` renders each as
  `.<name>{<body>}` — `emilia.bp:23-30`. That was the whole output model when this front was first
  drafted, and it is the reason the draft called `@keyframes` inexpressible. Front 56 replaced it:
  a `Sheet` carries `blocks` alongside its rules, `blockSheet(header, body)` builds one, and
  `renderDocument` hoists every block to the top level of the emitted stylesheet.
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

**Where the values come from.** Every property and value is copied from the reference, and every
theme variable stays a variable. `§ 15.6` writes `animation: var(--animate-spin)`, so `Animate.Spin`
emits exactly that — `themeVar("animate-spin")` from front 54 — and `§ 21.6`'s literal
(`spin 1s linear infinite`) is the **theme entry**, not the dispatcher's constant. `--ease-in`,
`--ease-out` and `--ease-in-out` are the same arrangement, `themeVar("ease-out")` and friends; that
the reference never prints their literals no longer matters, because the dispatcher never needs
them. Contract `§ 4a` refuses a dispatcher that resolves a theme variable, and the first draft of
this front resolved the four animation shorthands, which was wrong.

**Dispatcher shape.** Per contract `§ 4a`, and note that the two differ:

```bp
fn transitionTokenToCss(t: Token.Transition, th: Theme) -> string
fn animateTokenToSheet(t: Token.Animate, th: Theme) -> Sheet
```

`Transition` is a plain declaration string. `Animate` takes the `…TokenToSheet` form, because
`animate-spin` needs content outside its class: the declaration `animation:var(--animate-spin)` in
the rule, and the `@keyframes spin{…}` block beside it. `animateTokenToSheet` composes
`declSheet(...)` with `blockSheet("@keyframes spin", ...)` and returns the merge.

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
| `transition-[…]` | `Token.TransitionProperty(value: v)` — **top-level** | `transition-property:<v>` |

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

    // Payload-carrying variants are TOP-LEVEL, never section leaves — a payload
    // leaf inside a section cannot be constructed by any spelling
    // (`language-gaps.md` row 52, contract `§ 4a`).
    TransitionProperty(value: string),
    AnimateRaw(value: string),
}
```

**Why `TransitionProperty` and `AnimateRaw` sit at the top of `Token`.** A payload leaf nested inside
an enum section cannot be constructed by any spelling — verified against the real compiler,
`language-gaps.md` row 52. Contract `§ 4a` puts every payload-carrying variant at the top level with
builtin-typed fields, and the name keeps the path it would have had, flattened.

**Acceptance:**
- [ ] The seven preset leaves return the exact strings above, commas and spaces included.
- [ ] `.Transition.Base` lists eleven properties in the reference's order; a test asserts the whole
      string, not a `contains`.
- [ ] `.Transition.None` returns one declaration, not three.
- [ ] `transitionTokenToCss(t, th)` is exhaustive with no `_` arm and takes the theme per contract
      `§ 4a`, even though only its `Ease` arms read it.

### Step 2 — `transition-behavior`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `transition-normal` | `.Transition.Behavior.Normal` | `transition-behavior:normal` |
| `transition-discrete` | `.Transition.Behavior.Discrete` | `transition-behavior:allow-discrete` |

`transition-discrete` emits `allow-discrete`, not `discrete` — the class name and the CSS value do
not match, which is exactly the kind of row that gets written from memory and gets written wrong.

**Acceptance:**
- [ ] `transitionTokenToCss(.Behavior.Discrete, th)` returns `transition-behavior:allow-discrete`.

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
| `ease-linear` | `.Transition.Ease.Linear` | `transition-timing-function:linear` — a CSS keyword, not a lookup |
| `ease-in` | `.Transition.Ease.In` | `transition-timing-function:var(--ease-in)` — `themeVar("ease-in")` |
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

`ease-linear` is a CSS keyword; the other three are `themeVar(...)` lookups from front 54, and the
cubic-beziers they resolve to are theme entries rather than anything this front writes. A list that
pairs a preset with `Ease.Out` emits `var(--ease-out)` twice — harmless, and the second declaration
wins, which is the intent.

**Acceptance:**
- [ ] All nine duration steps and all nine delay steps carry the `ms` unit, `0ms` included.
- [ ] `.Transition.Ease.Linear` emits the keyword; the other three emit `var(--ease-…)`, and no
      `cubic-bezier(` literal appears in any `Ease` arm.
- [ ] `[.Transition.Colors, .Transition.Duration.300]` produces the preset's three declarations
      followed by `transition-duration:300ms` in `Rule.declarations` — the override is last and
      therefore wins.

### Step 4 — `Animate`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `animate-none` | `.Animate.None` | declaration `animation:none`, no block |
| `animate-spin` | `.Animate.Spin` | declaration `animation:var(--animate-spin)` + block `@keyframes spin` |
| `animate-ping` | `.Animate.Ping` | declaration `animation:var(--animate-ping)` + block `@keyframes ping` |
| `animate-pulse` | `.Animate.Pulse` | declaration `animation:var(--animate-pulse)` + block `@keyframes pulse` |
| `animate-bounce` | `.Animate.Bounce` | declaration `animation:var(--animate-bounce)` + block `@keyframes bounce` |
| `animate-[…]` | `Token.AnimateRaw(value: v)` — **top-level** | declaration `animation:<v>`, no block |

`§ 21.6`'s four literals — `spin 1s linear infinite`,
`ping 1s cubic-bezier(0, 0, 0.2, 1) infinite`,
`pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite`, `bounce 1s infinite` — are the **theme entries**
for `--animate-spin` … `--animate-bounce`, contributed by this front to front 54's theme through
`extend`. They are not dispatcher constants, and the commas and spaces
(`cubic-bezier(0, 0, 0.2, 1)`) are the reference's, byte for byte, wherever they are written.

**The `@keyframes` bodies.** `blockSheet(header, body)` takes them and `renderDocument` hoists them,
so the mechanism is settled. The **content** is not in the reference: `§ 15.6` and `§ 21.6` give the
shorthand and never print a keyframes body. This front therefore treats the four bodies exactly as
front 47 treats `sr-only` — read from the upstream page in one sitting, pasted into
`animateTokenToSheet` with a comment naming the URL and the date, with a `TODO.md` checkbox that
must be ticked before the front lands, and asserted in the test file as literals.

**Acceptance:**
- [ ] `animateTokenToSheet(.Pulse, th)` returns a `Sheet` whose rule declaration is
      `animation:var(--animate-pulse)` and whose `blocks` carries one `@keyframes pulse` block.
- [ ] `.Animate.None` returns a `Sheet` with an empty `blocks` list, and so does the top-level
      `Token.AnimateRaw` arm — a token that names no built-in keyframes hoists none.
- [ ] `Token.AnimateRaw(value: "fade 300ms ease-out")` and
      `Token.TransitionProperty(value: "width")` **construct** — a test builds both, which is the
      check that would have failed against the nested spelling.
- [ ] No section in this front's `tokens.bp` block contains a payload leaf.
- [ ] Two `Animate` tokens naming the same animation hoist **one** block, not two: `blocks` is
      deduplicated by header, which front 56 owns and this front asserts.
- [ ] `animateTokenToSheet` is exhaustive over six leaves with no `_` arm.
- [ ] The four `--animate-*` theme entries are contributed by this front and named in its `TODO.md`.
- [ ] The upstream page has been read, the date recorded in the dispatcher comment, and the
      `TODO.md` checkbox ticked.

### Step 5 — two new arms in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`. `Transition` reaches it through
`declSheet(...)`; `Animate` already returns a `Sheet` and goes in directly — the one arm in fronts
41–47 that does.

```bp
        Transition(_inner) -> declSheet(transitionTokenToCss(_inner, th));
        Animate(_inner) -> animateTokenToSheet(_inner, th);
        TransitionProperty(value) -> declSheet("transition-property:" + value);
        AnimateRaw(value) -> declSheet("animation:" + value);
```

Four arms, not two: the two top-level payload variants are siblings of `Transition` and `Animate`,
not leaves inside them. Each destructures by its declared field name (`value`) — a positional bind
type-checks and is `undefined` at run time. Note that `AnimateRaw` goes through `declSheet` and not
through `animateTokenToSheet`: a custom animation names keyframes this front does not own, so it
hoists no block.

**Acceptance:**
- [ ] The four arms sit between front 43's arm and front 45's, in front-number order.
- [ ] The `Animate` arm is the only arm in this front that does not go through `declSheet`, and the
      `emilia.bp` banner says why in one line.
- [ ] `tokenToSheet` still has no `_` arm.

## Examples

- [`./examples/transitions-example.bp`](./examples/transitions-example.bp) — the `Transition` and
  `Animate` catalogues as typed `Token[]` lists, the preset-then-override ordering shown as working
  code, then a submit button that transitions its colours on hover and swaps to a spinner while the
  form is in flight.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's two escape hatches, written `Transition.Property` and `Animate.Raw` in the first draft. `AnimateRaw` is the only way to name a custom animation, so the defect would have closed that door entirely | the variants move to the **top level** of `Token` per contract `§ 4a`: `Token.TransitionProperty(value: string)` and `Token.AnimateRaw(value: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same two, now top-level: `[.AnimateRaw("fade 300ms ease-out")]` still trips the parser | a wrapper fn returning the token (`fn rawAnimate(v: string) -> Token { return Token.AnimateRaw(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Deferred — not a gap, and not this front's to fix

| Item | Why |
|---|---|
| ~~The four `@keyframes` blocks~~ | **Mechanism closed by front 56.** `blockSheet(header, body)` and `Sheet.blocks`, hoisted by `renderDocument`, are the channel the first draft of this front said did not exist. `Animate` takes the `…TokenToSheet(t, th) -> Sheet` form and emits declaration and block together. What remains is **content**, not mechanism: the four keyframes bodies are absent from the reference and are gated in Step 4 the way front 47 gates `sr-only`. |
| ~~`--ease-*` literals~~ | **Closed by front 54.** `themeVar("ease-out")` and friends; the cubic-beziers are theme entries, not dispatcher constants. |
| `@starting-style` | Not in the reference. `§ 15` has five subsections — property, behavior, duration, timing function, delay — plus `§ 15.6` animation, and none of them mentions `@starting-style`. A token for it would be written from memory, which this milestone does not do. If it belongs in `emilia`, it belongs in a front whose reference section covers it. Front 56's `Sheet.blocks` would carry it if it did. |

## Test plan

`repository/emilia/test/transitions_test.bp`, run by `botopink test` from `repository/emilia/` and
by `zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it
emits a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert transitionTokenToCss(<token>, th) == "<css>"` per row
   of the three `Transition` tables. The six multi-declaration presets are asserted whole, never
   with `contains` — the whole point of those rows is the exact property list and its exact
   punctuation. `Animate` is asserted through `animateTokenToSheet`, declaration and block
   separately.
2. **The punctuation that is easy to lose.** `color, background-color` keeps its space after the
   comma; `cubic-bezier(0, 0, 0.2, 1)` keeps all three. A test asserting these as literals is what
   stops a well-meaning whitespace normaliser.
3. **`allow-discrete`.** Asserted by itself, because the class name says `discrete` and the value
   says `allow-discrete`.
4. **Override ordering.** `[.Transition.All, .Transition.Duration.700, .Transition.Ease.Linear]`
   produces the preset's declarations followed by the two overrides in list order in
   `Rule.declarations`, so the later ones win. The test asserts the full list, which pins the
   ordering contract the class hash depends on.
5. **Variant nesting.** `Token.Hover([.Transition.Colors])` reaches front 34's `nestVariant` with
   the preset's three declarations — the one case proving a multi-declaration body survives the
   recursive path. This front asserts the declarations, not the wrap.
6. **The keyframes hoist.** `[.Animate.Spin]` produces one rule declaration and one `blocks` entry;
   `[.Animate.Spin, .Animate.Spin]` produces one block, not two; `[.Animate.None]` produces none.
   The block bodies are asserted as literals, so a later tidy-up of the keyframes fails the test.
7. **No resolved theme literals.** A test greps this front's block of `emilia.bp` for
   `cubic-bezier(` and `infinite` and fails if it finds either outside a keyframes body — the four
   animation shorthands and the three easings are theme entries.
8. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Transition` and `Animate` exist as top-level sections, fenced by a `front 44` banner in
      `tokens.bp` and appended after front 43's block.
- [ ] `transitionTokenToCss`, `animateTokenToSheet` and their sub-dispatchers are fenced by a
      `front 44` banner in `emilia.bp`, appended after front 43's block, and both take `th: Theme`
      per contract `§ 4a`.
- [ ] Two arms added to `tokenToSheet`, in front-number order — `Transition` through `declSheet`,
      `Animate` directly — and no other line of that `case` moved.
- [ ] The four `--animate-*` and three `--ease-*` theme entries are contributed to front 54 and no
      literal for them appears in a dispatcher.
- [ ] The keyframes gate is closed: upstream page read, date recorded, `TODO.md` ticked, bodies
      asserted as literals.
- [ ] `repository/emilia/AGENTS.md` records the two new sections, the `…TokenToSheet` exception and
      the keyframes gate.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
