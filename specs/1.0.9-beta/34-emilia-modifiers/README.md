# Front 34 — emilia-modifiers

**Track:** D emilia
**Priority:** critical — a modifier is the only way a token reaches a state, a breakpoint or a pseudo-element. Six of them exist; the other seventy are the difference between a demo and a stylesheet.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 0
**Depends on:** none
**Owns:** `repository/emilia/src/tokens.bp` (modifier variants only) · `repository/emilia/src/emilia.bp` (the modifier arms of `tokenToCss`, and the `wrapRule` / `wrapMedia` helpers) · `repository/emilia/test/modifiers_test.bp`
**Does not touch:** any token section — this front adds no declaration, only wrappers around declarations other fronts produce
**Reference:** `TAILWIND_CSS_DOCS.md § 3.2 Hover, Focus e Outros Estados` (and its *Referência Completa de Variantes*), `§ 3.3 Design Responsivo`, `§ 3.4 Dark Mode` · https://tailwindcss.com/docs/hover-focus-and-other-states
**Replaces:** `1.0.8-beta/15-emilia-modifiers`

---

## Problem

`tokens.bp:264-269` declares exactly six modifiers: `Hover`, `Focus`, `Active`, `Md`, `Lg`, `Xl`.
The reference's variant table (`§ 3.2`, *Referência Completa de Variantes*) lists seventy-six. What
is missing is not decoration: there is no `Sm` and no `2xl`, so the smallest and largest breakpoints
cannot be addressed at all; there is no `max-*` form, so a range like `md:max-xl:` is inexpressible;
there is no `dark`, so a dark theme cannot be written; there is no `disabled`, `checked`, `required`
or `invalid`, so a form cannot be styled; there is no `group-*` or `peer-*`, so a parent or sibling
state cannot reach a child; and there is no `before`, `after`, `placeholder`, `marker` or
`selection`, so no pseudo-element can be styled.

The six that exist do not emit what Tailwind v4.3 emits. `emilia.bp:85-90` produces `":hover{…}"`,
without the `&`. Under CSS nesting a relative selector that does not start with `&` takes an implied
descendant combinator, so `.e_x { :hover { … } }` styles a *descendant* in the hover state, not the
element itself. Tailwind's own table says `hover` is `@media (hover: hover) { &:hover }`. The
breakpoints are equally off: `Md` emits `@media(min-width:768px)` where v4.3 emits
`@media (width >= 48rem)`.

## Current state

| What | Where | State |
|---|---|---|
| `Hover/Focus/Active/Md/Lg/Xl(inner: Token[])` | `tokens.bp:264-269` | the complete modifier set today |
| the six arms of `tokenToCss` | `emilia.bp:85-90` | `":hover{"`, `":focus{"`, `":active{"`, `"@media(min-width:768px){"`, `"…1024px…"`, `"…1280px…"` |
| nesting | `emilia.bp:455-461` | works: `Token.Hover([Token.Md([.Text.Bold])])` produces `":hover{@media(min-width:768px){font-weight:bold}}"` |
| `tokensToCss` | `emilia.bp:102-104` | joins with `;`, drops empty declarations — a modifier block is just another element of that join |

Nesting is the one part that already works and needs no change. Everything else in this front is
either new or a correction.

## Mechanism

A modifier is a top-level `Token` variant carrying `inner: Token[]`. That shape is the only payload
shape the compiler can construct — a payload leaf nested inside a section cannot be built by any
spelling (front 33 records the verification). All seventy-plus modifiers are therefore siblings of
the section heads at the top level of `Token`, exactly as the six existing ones are.

Emission is one of two shapes, and the reference says which for every variant:

- **A selector wrapper.** `wrapRule(sel, inner)` produces `<sel>{<inner>}`, where `<sel>` is the
  reference's selector text verbatim: `&:focus`, `&::before`, `[dir="rtl"] &`, `:is(& > *)`.
- **An at-rule wrapper.** `wrapMedia(query, inner)` produces `@media <query>{<inner>}`, where
  `<query>` is the reference's query verbatim: `(width >= 48rem)`, `(prefers-color-scheme: dark)`,
  `print`.

`hover` is the one variant that is both — `@media (hover: hover) { &:hover }` — and it composes the
two helpers.

Two modifiers take an index rather than being nullary: `Nth(index: i32, inner: Token[])` and
`NthLast(index: i32, inner: Token[])`, matching `nth-[...]` and `nth-last-[...]`. A payload variant
carrying an `i32` beside a `Token[]` was verified to construct and destructure.

Nesting falls out of `tokensToCss` recursion and is already proven. Order is source order: the
outermost modifier is the outermost block, which is how a `dark:md:hover:` chain is written in
Tailwind and how it must read here.

## Token surface

Every row's selector or query text is copied from `§ 3.2`'s *Referência Completa de Variantes*, and
every row's emitted CSS is `<selector>{…}` or `@media <query>{…}` around the composed inner tokens.

### Breakpoints — `§ 3.3`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `sm:` | `Token.Sm(inner)` | `@media (width >= 40rem){…}` |
| `md:` | `Token.Md(inner)` | `@media (width >= 48rem){…}` |
| `lg:` | `Token.Lg(inner)` | `@media (width >= 64rem){…}` |
| `xl:` | `Token.Xl(inner)` | `@media (width >= 80rem){…}` |
| `2xl:` | `Token.X2xl(inner)` | `@media (width >= 96rem){…}` |
| `max-sm:` | `Token.MaxSm(inner)` | `@media (width < 40rem){…}` |
| `max-md:` | `Token.MaxMd(inner)` | `@media (width < 48rem){…}` |
| `max-lg:` | `Token.MaxLg(inner)` | `@media (width < 64rem){…}` |
| `max-xl:` | `Token.MaxXl(inner)` | `@media (width < 80rem){…}` |
| `max-2xl:` | `Token.MaxX2xl(inner)` | `@media (width < 96rem){…}` |

`2xl` cannot be an identifier, so the leaf is `X2xl` — the spelling `tokens.bp:53` already uses for
`Text.Size.X2xl`.

### Dark mode and other media — `§ 3.2`, `§ 3.4`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `dark:` | `Token.Dark(inner)` | `@media (prefers-color-scheme: dark){…}` |
| `print:` | `Token.Print(inner)` | `@media print{…}` |
| `portrait:` | `Token.Portrait(inner)` | `@media (orientation: portrait){…}` |
| `landscape:` | `Token.Landscape(inner)` | `@media (orientation: landscape){…}` |
| `motion-safe:` | `Token.MotionSafe(inner)` | `@media (prefers-reduced-motion: no-preference){…}` |
| `motion-reduce:` | `Token.MotionReduce(inner)` | `@media (prefers-reduced-motion: reduce){…}` |
| `contrast-more:` | `Token.ContrastMore(inner)` | `@media (prefers-contrast: more){…}` |
| `contrast-less:` | `Token.ContrastLess(inner)` | `@media (prefers-contrast: less){…}` |
| `forced-colors:` | `Token.ForcedColors(inner)` | `@media (forced-colors: active){…}` |

### Interaction state

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `hover:` | `Token.Hover(inner)` | `@media (hover: hover){&:hover{…}}` |
| `focus:` | `Token.Focus(inner)` | `&:focus{…}` |
| `focus-within:` | `Token.FocusWithin(inner)` | `&:focus-within{…}` |
| `focus-visible:` | `Token.FocusVisible(inner)` | `&:focus-visible{…}` |
| `active:` | `Token.Active(inner)` | `&:active{…}` |
| `visited:` | `Token.Visited(inner)` | `&:visited{…}` |
| `target:` | `Token.Target(inner)` | `&:target{…}` |
| `open:` | `Token.Open(inner)` | `&:open, &:popover-open{…}` |
| `inert:` | `Token.Inert(inner)` | `&:is([inert], [inert] *){…}` |

### Form state

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `disabled:` | `Token.Disabled(inner)` | `&:disabled{…}` |
| `enabled:` | `Token.Enabled(inner)` | `&:enabled{…}` |
| `checked:` | `Token.Checked(inner)` | `&:checked{…}` |
| `indeterminate:` | `Token.Indeterminate(inner)` | `&:indeterminate{…}` |
| `default:` | `Token.Default(inner)` | `&:default{…}` |
| `optional:` | `Token.Optional(inner)` | `&:optional{…}` |
| `required:` | `Token.Required(inner)` | `&:required{…}` |
| `valid:` | `Token.Valid(inner)` | `&:valid{…}` |
| `invalid:` | `Token.Invalid(inner)` | `&:invalid{…}` |
| `user-valid:` | `Token.UserValid(inner)` | `&:user-valid{…}` |
| `user-invalid:` | `Token.UserInvalid(inner)` | `&:user-invalid{…}` |
| `in-range:` | `Token.InRange(inner)` | `&:in-range{…}` |
| `out-of-range:` | `Token.OutOfRange(inner)` | `&:out-of-range{…}` |
| `placeholder-shown:` | `Token.PlaceholderShown(inner)` | `&:placeholder-shown{…}` |
| `autofill:` | `Token.Autofill(inner)` | `&:autofill{…}` |
| `read-only:` | `Token.ReadOnly(inner)` | `&:read-only{…}` |

### Structural

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `first:` | `Token.First(inner)` | `&:first-child{…}` |
| `last:` | `Token.Last(inner)` | `&:last-child{…}` |
| `only:` | `Token.Only(inner)` | `&:only-child{…}` |
| `odd:` | `Token.Odd(inner)` | `&:nth-child(odd){…}` |
| `even:` | `Token.Even(inner)` | `&:nth-child(even){…}` |
| `first-of-type:` | `Token.FirstOfType(inner)` | `&:first-of-type{…}` |
| `last-of-type:` | `Token.LastOfType(inner)` | `&:last-of-type{…}` |
| `only-of-type:` | `Token.OnlyOfType(inner)` | `&:only-of-type{…}` |
| `empty:` | `Token.Empty(inner)` | `&:empty{…}` |
| `nth-3:` | `Token.Nth(index: 3, inner)` | `&:nth-child(3){…}` |
| `nth-last-5:` | `Token.NthLast(index: 5, inner)` | `&:nth-last-child(5){…}` |

### Pseudo-elements

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `before:` | `Token.Before(inner)` | `&::before{…}` |
| `after:` | `Token.After(inner)` | `&::after{…}` |
| `first-letter:` | `Token.FirstLetter(inner)` | `&::first-letter{…}` |
| `first-line:` | `Token.FirstLine(inner)` | `&::first-line{…}` |
| `placeholder:` | `Token.Placeholder(inner)` | `&::placeholder{…}` |
| `file:` | `Token.File(inner)` | `&::file-selector-button{…}` |
| `marker:` | `Token.Marker(inner)` | `& ::marker{…}` |
| `selection:` | `Token.Selection(inner)` | `& ::selection{…}` |
| `backdrop:` | `Token.Backdrop(inner)` | `&::backdrop{…}` |

`marker` and `selection` carry a space before `::` in the reference's table. That is not a typo in
this spec: copy it.

### Parent and sibling state

The reference gives these as templates — `group-[...]` is `&:is(:where(.group) ... *)` and
`peer-[...]` is `&:is(:where(.peer) ... ~ *)`, where `...` is the state selector. Each row below is
that template with its state substituted.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `group-hover:` | `Token.GroupHover(inner)` | `&:is(:where(.group):hover *){…}` |
| `group-focus:` | `Token.GroupFocus(inner)` | `&:is(:where(.group):focus *){…}` |
| `group-active:` | `Token.GroupActive(inner)` | `&:is(:where(.group):active *){…}` |
| `group-disabled:` | `Token.GroupDisabled(inner)` | `&:is(:where(.group):disabled *){…}` |
| `group-open:` | `Token.GroupOpen(inner)` | `&:is(:where(.group):open *){…}` |
| `peer-hover:` | `Token.PeerHover(inner)` | `&:is(:where(.peer):hover ~ *){…}` |
| `peer-focus:` | `Token.PeerFocus(inner)` | `&:is(:where(.peer):focus ~ *){…}` |
| `peer-checked:` | `Token.PeerChecked(inner)` | `&:is(:where(.peer):checked ~ *){…}` |
| `peer-invalid:` | `Token.PeerInvalid(inner)` | `&:is(:where(.peer):invalid ~ *){…}` |
| `peer-disabled:` | `Token.PeerDisabled(inner)` | `&:is(:where(.peer):disabled ~ *){…}` |
| `peer-placeholder-shown:` | `Token.PeerPlaceholderShown(inner)` | `&:is(:where(.peer):placeholder-shown ~ *){…}` |

### Direction and descent

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `rtl:` | `Token.Rtl(inner)` | `[dir="rtl"] &{…}` |
| `ltr:` | `Token.Ltr(inner)` | `[dir="ltr"] &{…}` |
| `*:` | `Token.Children(inner)` | `:is(& > *){…}` |
| `**:` | `Token.Descendants(inner)` | `:is(& *){…}` |

## Steps

### Step 1 — the two wrappers, and the correction to the six that exist

```bp
fn wrapRule(sel: string, inner: Token[]) -> string {
    return sel + "{" + tokensToCss(inner) + "}";
}

fn wrapMedia(query: string, inner: Token[]) -> string {
    return "@media " + query + "{" + tokensToCss(inner) + "}";
}
```

Every arm this front adds goes through one of the two. The six existing arms are rewritten to go
through them as well, which changes their output:

| Token | today (`emilia.bp:85-90`) | after |
|---|---|---|
| `Hover` | `:hover{…}` | `@media (hover: hover){&:hover{…}}` |
| `Focus` | `:focus{…}` | `&:focus{…}` |
| `Active` | `:active{…}` | `&:active{…}` |
| `Md` | `@media(min-width:768px){…}` | `@media (width >= 48rem){…}` |
| `Lg` | `@media(min-width:1024px){…}` | `@media (width >= 64rem){…}` |
| `Xl` | `@media(min-width:1280px){…}` | `@media (width >= 80rem){…}` |

**This is the one non-additive change in the front, and it is deliberate.** No token is renamed and
no path stops compiling; what changes is the CSS six existing tokens emit, because what they emit
today is not what Tailwind v4.3 emits and the milestone's stated bar is byte-equality. The change
breaks five assertions that live in `repository/emilia/src/emilia.bp`, not in a test file this front
owns: `:435-440`, `:442-447`, `:455-461`, `:505-511` and the `Md` reference inside `:455-461`. They
must be updated in the same commit. `fronts.md` gives this front "modifier wrap in `tokenToCss`",
which is exactly those lines; the assertions are collateral and are named here so the coordinator
sees them before the merge rather than in it.

**Acceptance:**
- [ ] `wrapRule("&:focus", inner)` returns `"&:focus{" + tokensToCss(inner) + "}"`
- [ ] `wrapMedia("(width >= 48rem)", inner)` returns `"@media (width >= 48rem){…}"`
- [ ] `Token.Hover([.Text.Bold])` emits `@media (hover: hover){&:hover{font-weight:bold}}`
- [ ] `Token.Md([.Text.Bold])` emits `@media (width >= 48rem){font-weight:bold}`
- [ ] the five assertions in `src/emilia.bp` are updated, and no sixth assertion anywhere in the
      repository still expects the old spelling (`grep -R ':hover{' repository/emilia` returns only
      the new form)

### Step 2 — breakpoints, both directions

Five `min` and five `max` variants, queries verbatim from `§ 3.3` and `§ 3.2`.

```bp
    Sm(inner: Token[]),
    X2xl(inner: Token[]),
    MaxSm(inner: Token[]),
    MaxMd(inner: Token[]),
    MaxLg(inner: Token[]),
    MaxXl(inner: Token[]),
    MaxX2xl(inner: Token[]),
```

A breakpoint range — Tailwind's `md:max-xl:` — is nesting, not a new variant:
`Token.Md([Token.MaxXl(inner)])`.

**Acceptance:**
- [ ] all ten breakpoints emit their reference query, byte for byte, spaces included
- [ ] `Token.Md([Token.MaxXl([.Text.Bold])])` emits
      `@media (width >= 48rem){@media (width < 80rem){font-weight:bold}}`
- [ ] no breakpoint emits a `px` value — v4.3 breakpoints are `rem`

### Step 3 — dark mode and the other media variants

Nine at-rule variants. `Dark` is media-query based, which is v4.3's default (`§ 3.4`). The
class-based and attribute-based forms in `§ 3.4` are `@custom-variant` registrations, which emilia
has no equivalent of; they are out of scope and named as such in *Reference gaps*.

**Acceptance:**
- [ ] `Token.Dark([.Bg.Color.Slate.900])` emits `@media (prefers-color-scheme: dark){background-color:var(--color-slate-900)}`
- [ ] `Print`, `Portrait`, `Landscape`, `MotionSafe`, `MotionReduce`, `ContrastMore`, `ContrastLess`, `ForcedColors` each emit their reference query
- [ ] `Dark` nests with a breakpoint in both orders and the blocks come out in source order

### Step 4 — state, structural and form variants

Thirty-six nullary selector variants plus `Nth` and `NthLast`.

```bp
    Nth(index: i32, inner: Token[]),
    NthLast(index: i32, inner: Token[]),
```

```bp
        Nth(index, inner) -> wrapRule("&:nth-child(" + index.toString() + ")", inner);
```

**Acceptance:**
- [ ] each of the 36 nullary variants emits exactly the selector its reference row names
- [ ] `Token.Nth(index: 3, inner: [.Text.Underline])` emits `&:nth-child(3){text-decoration-line:underline}`
- [ ] `Token.NthLast(index: 5, inner: […])` emits `&:nth-last-child(5){…}`
- [ ] `Open` emits the two-selector form `&:open, &:popover-open` — the comma is inside the selector,
      not a separator emilia added
- [ ] `Inert` emits `&:is([inert], [inert] *)`

### Step 5 — pseudo-elements

Nine variants. `Before` and `After` are useless without `content`, which front 38 delivers as
`Text.Content.*`; the example names that dependency.

**Acceptance:**
- [ ] `Before`, `After`, `FirstLetter`, `FirstLine`, `Placeholder`, `File`, `Backdrop` emit `&::…`
- [ ] `Marker` emits `& ::marker` and `Selection` emits `& ::selection` — with the space
- [ ] `Token.Before([.Text.Content.Empty, .Color.Red.500])` composes both declarations inside one
      `&::before{…}` block

### Step 6 — group, peer, direction and descent

Eleven group/peer variants built from the reference's two templates, plus `Rtl`, `Ltr`, `Children`,
`Descendants`.

**Acceptance:**
- [ ] every group variant matches `&:is(:where(.group)<state> *)`
- [ ] every peer variant matches `&:is(:where(.peer)<state> ~ *)`
- [ ] `Rtl` emits `[dir="rtl"] &{…}` — the `&` is at the end, not the start
- [ ] `Children` emits `:is(& > *){…}` and `Descendants` emits `:is(& *){…}`
- [ ] the group and peer class names (`.group`, `.peer`) are documented as the consumer's
      responsibility: emilia does not emit them, the markup carries them

### Step 7 — nesting, ordering and the top-level arm

All seventy-plus arms are added to `tokenToCss` in one block, fenced by this front's banner, and one
line is added to the top-level `case` per the shared-file convention in `fronts.md`.

**Acceptance:**
- [ ] a three-deep nest emits three nested blocks in source order:
      `Token.Dark([Token.Md([Token.Hover([.Text.Bold])])])` →
      `@media (prefers-color-scheme: dark){@media (width >= 48rem){@media (hover: hover){&:hover{font-weight:bold}}}}`
- [ ] a modifier whose inner list is empty emits `<wrapper>{}` and is not dropped by
      `tokensToCss`'s `filter({ d -> d != "" })` — the front states which behaviour it chose and
      tests it
- [ ] `tokens.bp` carries no `//` comment inside the `pub type Token` braces
- [ ] the modifier block is appended at the end of `tokens.bp`, after every section, matching the
      position the six existing modifiers occupy

## Examples

- `./examples/modifiers-example.bp` — one token list per variant family: breakpoints both ways, dark
  mode, state, structural, pseudo-element, group/peer, direction; ends with a responsive navigation
  bar that uses eight of them together.
- `./examples/nesting-example.bp` — how modifiers compose: breakpoint ranges, dark-plus-hover,
  group-plus-breakpoint, three-deep chains; ends with a form field whose error state is
  peer-driven.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| An arbitrary variant (`[&.is-dragging]:`, `supports-[…]:`, `aria-[…]:`, `data-[size=large]:`, `has-[…]:`, `not-[…]:`, `@custom-variant`) needs a modifier that carries a **selector string**. A top-level payload variant carrying a `string` does construct, so this is expressible — but it is an escape hatch, and the coordinator has allocated a separate front for escape hatches. | `examples/modifiers-example.bp`, the arbitrary-variant note | omit; use a named variant | `Token.Variant(selector: string, inner: Token[])` on the escape-hatch front |

No other gap. Every construct in this front's examples parses today: a top-level payload variant
with a `Token[]` field is what `Hover` already is, and one with an `i32` beside it was verified to
construct and destructure before this spec was written.

## Reference gaps

| Item | Why it is missing | What implementation must do |
|---|---|---|
| The concrete group/peer selectors | `§ 3.2` gives the templates `&:is(:where(.group) ... *)` and `&:is(:where(.peer) ... ~ *)`, never a substituted instance | check one substituted selector per family against upstream before merge; if upstream differs, the template's `...` placement is what this spec got wrong |
| Named groups and peers (`group/item`, `peer//name`) | `§ 3.2` shows the class syntax with no CSS | out of scope for this front |
| Container queries (`@container`, `@md:`) | `§ 3.3` lists the container sizes but no emitted CSS | out of scope; it is a separate wrapper shape (`@container (width >= …)`) and deserves its own front |
| `@custom-variant`, class-based and attribute-based dark mode | `§ 3.4` and `§ 20.3` show the CSS directive, not a utility | emilia has no directive layer; not expressible as a token |
| `@starting-style` | absent entirely from the reference | do not invent a token for it |

## Test plan

`repository/emilia/test/modifiers_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`. A modifier whose output differs between them is a `tokensToCss`
bug, since the wrappers are pure string concatenation.

What the tests assert:

1. **One assert per variant** — the composed CSS for `<Variant>([.Text.Bold])` against the literal
   from the token-surface table above. Seventy-plus asserts, grouped into one test per family.
2. **The six corrected variants** — explicitly, with the old spelling asserted absent.
3. **Breakpoint ranges** — `Md(MaxXl(…))` and `Sm(MaxMd(…))`.
4. **Three-deep nesting**, in source order.
5. **Indexed variants** — `Nth` and `NthLast` at three indices each, including a two-digit index.
6. **Empty inner list** — the documented behaviour, whichever way it was decided.
7. **End to end** — `emilia([.Bg.Color.White, Token.Dark([.Bg.Color.Slate.900])])` then
   `await flush()`, asserting the full `<style>` block.

The existing assertions in `src/emilia.bp` are updated, not duplicated here; this file owns the new
surface and the regression that the old surface now emits the v4.3 form.

## Definition of done

- [ ] every variant in `§ 3.2`'s reference table that is not an arbitrary-value form has a token
- [ ] `wrapRule` and `wrapMedia` are the only two places a modifier string is built
- [ ] the six pre-existing modifiers emit the v4.3 form, and the five affected assertions in
      `src/emilia.bp` are updated in the same commit
- [ ] the banner `// ── front 34 — modifiers ──` fences this front's block in both files
- [ ] one arm added to the top-level `tokenToCss` case, in front-number order
- [ ] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new modifier map
- [ ] the front's tests are green on its assigned target — here, both backends, since emilia is comptime
