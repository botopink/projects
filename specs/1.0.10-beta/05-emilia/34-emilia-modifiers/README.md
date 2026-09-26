# Front 34 — emilia-modifiers

**Track:** D emilia
**Priority:** critical — a modifier is the only way a token reaches a state, a breakpoint or a pseudo-element. Six of them exist; the other seventy are the difference between a demo and a stylesheet.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 2
**Depends on:** 56 (`Variant`, `nestVariant`, `Rule.selector` — front 34 writes the variant table and owns no wrapping logic), 54 (`Theme`)
**Owns:** `repository/emilia/src/tokens.bp` (modifier variants only) · `repository/emilia/src/emilia.bp` (the modifier arms of `tokenToSheet`, and one `Variant`-returning fn per variant name) · `repository/emilia/test/modifiers_test.bp`
**Does not touch:** any token section — this front adds no declaration, only wrappers around declarations other fronts produce
**Reference:** `TAILWIND_CSS_DOCS.md § 3.2 Hover, Focus e Outros Estados` (and its *Referência Completa de Variantes*), `§ 3.3 Design Responsivo`, `§ 3.4 Dark Mode` · https://tailwindcss.com/docs/hover-focus-and-other-states

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

**This front owns no wrapping logic.** Per contract 4a in [`contracts.md`](../../contracts.md), the
entire emission interface is front 56's two-field record:

```bp
pub type Variant(atRule: string, selector: string)
```

Front 34 writes **one `Variant`-returning fn per variant name** and nothing else about emission;
front 56's `nestVariant(sheet, variant)` applies it. The reference's table maps onto the two fields
exactly, which is why two fields are enough for all seventy-plus rows:

| Kind | `atRule` | `selector` | example |
|---|---|---|---|
| selector only | `""` | the reference's selector text | `focus` → `Variant(atRule: "", selector: "&:focus")` |
| at-rule only | the reference's query | `"&"` | `md` → `Variant(atRule: "@media (width >= 48rem)", selector: "&")` |
| both | the query | the selector | `hover` → `Variant(atRule: "@media (hover: hover)", selector: "&:hover")` |

`selector` is a nesting template carrying **exactly one `&`**, which is what lets `[dir="rtl"] &`
and `:is(& > *)` — selectors where the class is not leading — go through the same field as `&:focus`.
Two or more `&` is refused by front 56 with no opt-out, so a variant fn that builds one is a build
failure, not a silent mis-render.

The `CSS emitted` column in the tables below shows the *rendered* result of applying the variant, so
that a row can be read against Tailwind's output. What this front actually writes is the two-field
`Variant`.

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

### Step 1 — the variant table, and the correction to the six that exist

```bp
fn hoverVariant() -> Variant {
    return Variant(atRule: "@media (hover: hover)", selector: "&:hover");
}

fn focusVariant() -> Variant {
    return Variant(atRule: "", selector: "&:focus");
}

fn mdVariant() -> Variant {
    return Variant(atRule: "@media (width >= 48rem)", selector: "&");
}
```

One such fn per variant name, and one arm per variant in `tokenToSheet`:

```bp
        Hover(inner) -> nestVariant(tokensToSheet(inner, th), hoverVariant());
```

The six existing arms move to the same shape, which changes their output:

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
- [x] `focusVariant()` is `Variant(atRule: "", selector: "&:focus")` — held: emilia.bp test "interaction state — the two halves of every Variant in the family"
- [x] `mdVariant()` is `Variant(atRule: "@media (width >= 48rem)", selector: "&")` — held (shape: `mdVariant(th)` reads `--breakpoint-md`, decision 82): emilia.bp test "breakpoints, min-width — the two halves of every Variant in the family"
- [x] every variant fn returns a `selector` containing exactly one `&` — held: emilia.bp test "the walk — every selector template carries exactly one ampersand"
- [x] this front contains no string concatenation that builds a `{` or a `}` — wrapping is front 56's — held: emilia.bp test "the walk — this front builds no brace, and every at-rule is an at-rule"
- [x] `Token.Hover([.Text.Bold])` renders `@media (hover: hover){&:hover{font-weight:bold}}` — held (shape: rendered on a class, `.x:hover`): emilia.bp test "interaction state — the CSS each row renders around one declaration"
- [x] `Token.Md([.Text.Bold])` emits `@media (width >= 48rem){font-weight:bold}` — held (shape: rendered on a class, `.x{…}`): emilia.bp test "breakpoints, min-width — the CSS each row renders around one declaration"
- [ ] the five assertions in `src/emilia.bp` are updated, and no sixth assertion anywhere in the
      repository still expects the old spelling (`grep -R ':hover{' repository/emilia` returns only
      the new form) — **open:** the assertions are updated, but `grep -R ':hover{'` still hits emilia `README.md:60` (`Token.Hover([Token.ColorRed500]), // :hover{color:#ef4444}`), the old nested form

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
- [x] all ten breakpoints emit their reference query, byte for byte, spaces included — held: emilia.bp tests "breakpoints, min-width — the CSS each row renders …" and "breakpoints, max-width — the CSS each row renders …"
- [x] `Token.Md([Token.MaxXl([.Text.Bold])])` emits
      `@media (width >= 48rem){@media (width < 80rem){font-weight:bold}}` — held: emilia.bp test "a breakpoint RANGE is nesting, not a variant — `md:max-xl:`"
- [x] no breakpoint emits a `px` value — v4.3 breakpoints are `rem` — held: emilia.bp test "the walk — no breakpoint query resolves a pixel, and none is min-width"

### Step 3 — dark mode and the other media variants

Nine `atRule`-only variants, each with `selector: "&"`. `Dark` is media-query based, which is v4.3's default (`§ 3.4`). The
class-based and attribute-based forms in `§ 3.4` are `@custom-variant` registrations, which emilia
has no equivalent of; they are out of scope and named as such in *Reference gaps*.

**Acceptance:**
- [x] `Token.Dark([.Bg.Color.Slate.900])` emits `@media (prefers-color-scheme: dark){background-color:var(--color-slate-900)}` — held: emilia.bp test "end to end — a light background and its dark override, as one document"
- [x] `Print`, `Portrait`, `Landscape`, `MotionSafe`, `MotionReduce`, `ContrastMore`, `ContrastLess`, `ForcedColors` each emit their reference query — held: emilia.bp test "dark mode and the other media features — the CSS each row renders around one declaration"
- [ ] `Dark` nests with a breakpoint in both orders and the blocks come out in source order — **open:** only dark-outside-md is pinned ("three deep — `dark:md:hover:`…"); no test nests `Dark` inside a breakpoint

### Step 4 — state, structural and form variants

Thirty-six `selector`-only variants (`atRule: ""`) plus `Nth` and `NthLast`, which build their
selector from the payload.

```bp
    Nth(index: i32, inner: Token[]),
    NthLast(index: i32, inner: Token[]),
```

```bp
fn nthVariant(index: i32) -> Variant {
    return Variant(atRule: "", selector: "&:nth-child(" + index.toString() + ")");
}
```

**Acceptance:**
- [x] each of the 36 nullary variants emits exactly the selector its reference row names — held (shape: `Open` is `&:is(:open, :popover-open)`, see below): emilia.bp tests "interaction state / form state / structural position — the CSS each row renders around one declaration"
- [x] `Token.Nth(index: 3, inner: [.Text.Underline])` emits `&:nth-child(3){text-decoration-line:underline}` — held (shape: pinned over `.Text.Bold`): emilia.bp test "Nth — three indices, including a two-digit one"
- [x] `Token.NthLast(index: 5, inner: […])` emits `&:nth-last-child(5){…}` — held: emilia.bp test "NthLast — the same three, counted from the end"
- [x] `Open` emits the two-selector form `&:open, &:popover-open` — the comma is inside the selector,
      not a separator emilia added — held (shape: `&:is(:open, :popover-open)`, one `&`, because front 56 refuses two): emilia.bp test "the two states of `open` live inside one selector, not a selector list"
- [x] `Inert` emits `&:is([inert], [inert] *)` — held: emilia.bp test "`inert` is the attribute pair the reference gives, not a pseudo-class"

### Step 5 — pseudo-elements

Nine variants. `Before` and `After` are useless without `content`, which front 38 delivers as
`Text.Content.*`; the example names that dependency.

**Acceptance:**
- [x] `Before`, `After`, `FirstLetter`, `FirstLine`, `Placeholder`, `File`, `Backdrop` emit `&::…` — held: emilia.bp test "pseudo-elements — the CSS each row renders around one declaration"
- [x] `Marker` emits `& ::marker` and `Selection` emits `& ::selection` — with the space — held: emilia.bp test "`marker` and `selection` carry the space before `::`, and the others do not"
- [x] `Token.Before([.Text.Content.Empty, .Color.Red.500])` composes both declarations inside one
      `&::before{…}` block — held (shape: by renderDocument's same-context fold, output.bp test "renderDocument — consecutive rules of one class in one context fold into one"; no `Before`-specific test)

### Step 6 — group, peer, direction and descent

Eleven group/peer variants built from the reference's two templates, plus `Rtl`, `Ltr`, `Children`,
`Descendants`.

**Acceptance:**
- [x] every group variant matches `&:is(:where(.group)<state> *)` — held: emilia.bp test "parent state (`group-*`) — the two halves of every Variant in the family"
- [x] every peer variant matches `&:is(:where(.peer)<state> ~ *)` — held: emilia.bp test "sibling state (`peer-*`) — the two halves of every Variant in the family"
- [x] `Rtl` emits `[dir="rtl"] &{…}` — the `&` is at the end, not the start — held: emilia.bp test "`rtl` and `ltr` put the ampersand LAST, and the class still lands there"
- [x] `Children` emits `:is(& > *){…}` and `Descendants` emits `:is(& *){…}` — held: emilia.bp test "`*:` and `**:` wrap the ampersand rather than following it"
- [x] the group and peer class names (`.group`, `.peer`) are documented as the consumer's
      responsibility: emilia does not emit them, the markup carries them — held: emilia `docs.md` "Parent state — the `.group` class is the consumer's, never emilia's"; tokens.bp MODIFIERS header

### Step 7 — nesting, ordering and the top-level arms

All seventy-plus arms are added to `tokenToSheet` in one block, fenced by this front's banner. Each
arm is one line of the form `<Name>(inner) -> nestVariant(tokensToSheet(inner, th), <name>Variant());`,
per the shared-file convention in `fronts.md`.

**Acceptance:**
- [x] a three-deep nest emits three nested blocks in source order:
      `Token.Dark([Token.Md([Token.Hover([.Text.Bold])])])` →
      `@media (prefers-color-scheme: dark){@media (width >= 48rem){@media (hover: hover){&:hover{font-weight:bold}}}}` — held: emilia.bp test "three deep — `dark:md:hover:` comes out in source order"
- [x] a modifier whose inner list is empty produces an empty `Sheet`, which front 56's `declSheet`
      contract already drops — the front states the behaviour and tests it — held: emilia.bp tests "a modifier whose inner list is empty produces an empty sheet, and is dropped" and "an empty modifier beside a real token leaves exactly the real rule"
- [ ] `tokens.bp` carries no `//` comment inside the `pub type Token` braces — **open:** tokens.bp carries `//` comments inside the braces — this front's own `// ── front 34 — modifiers ──` fence among them — and parses; the constraint is obsolete
- [x] the modifier block is appended at the end of `tokens.bp`, after every section, matching the
      position the six existing modifiers occupy — held: tokens.bp `// ── front 34 — modifiers ──` … `// ── end front 34 ──` closes `pub type Token`

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

1. **One assert per variant** — two, in fact: the `Variant` record's two fields against their
   literals, and the rendered CSS for `<Variant>([.Text.Bold])` against the literal from the
   token-surface table above. Seventy-plus of each, grouped into one test per family.
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

- [x] every variant in `§ 3.2`'s reference table that is not an arbitrary-value form has a token — held (shape: checked against this README's token-surface tables — every row has a token, 83 modifiers; the reference file is not in the checkout): emilia.bp test "the table — 82 Variant fns and 83 modifier tokens, and no row is a copy"
- [x] one `Variant`-returning fn per variant name, and no brace-building anywhere in this front — held: emilia.bp front-34 block + test "the walk — this front builds no brace, and every at-rule is an at-rule"
- [x] the six pre-existing modifiers emit the v4.3 form, and the five affected assertions in
      `src/emilia.bp` are updated in the same commit — held: emilia.bp tests "Hover — the `hover` row is …", "Focus and Active — …", "Md, Lg and Xl — …"
- [x] the banner `// ── front 34 — modifiers ──` fences this front's block in both files — held: tokens.bp and the `tokenToSheet` arms carry `// ── front 34 — modifiers ──`; the variant fns sit under `//// ═══ FRONT 34 ·`
- [ ] one arm added to the top-level `tokenToCss` case, in front-number order — **open:** the front-34 block of `tokenToSheet` comes after fronts 38/40/41/44/45/39, not in front-number order
- [x] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new modifier map — held: AGENTS.md (front-34 paragraph) and tokens.bp `//// MODIFIERS — front 34's table`
- [x] the front's tests are green on its assigned target — here, both backends, since emilia is comptime — held: 569/569 on commonJS and erlang
