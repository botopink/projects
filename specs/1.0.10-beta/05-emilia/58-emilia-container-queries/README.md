# Front 58 — emilia container queries

**Track:** D emilia
**Priority:** medium — without it component-scoped responsiveness is impossible and every `emilia`-styled `jhonstart` component stays coupled to the viewport. For a library whose only consumer is a component framework that is a structural limitation, not a missing utility.
**Target:** comptime
**Wave:** 2 — 54 lands in wave 0 and 56 in wave 1.
**Depends on:** 54 (the `--container-*` namespace: the thirteen sizes are theme values, not constants), 56 (`@container` is an at-rule and has to be hoisted out of the class body)
**Owns:** `repository/emilia/src/container.bp`, `repository/emilia/test/container_test.bp`; one payload-free `Container` section plus three **top-level `Token` variants** appended to `src/tokens.bp` under a banner naming this front, and their four arms in `tokenToSheet`; the `pub mod container;` line in `src/root.bp` and its entry in `botopink.json`
**Does not touch:** any other front's token section or dispatcher; `src/output.bp`; `src/theme.bp`
**Reference:** `TAILWIND_CSS_DOCS.md § 3.3 Container Queries`, with its thirteen-row container-size table, and `§ 3.5 Namespaces de Variáveis de Tema` for `--container-*` · https://tailwindcss.com/docs/responsive-design#container-queries
**Replaces:** new — from the Tailwind coverage audit

---

## Problem

Every conditional style `emilia` can express today is a viewport query. `Md`, `Lg` and `Xl`
(`repository/emilia/src/tokens.bp:267-269`) wrap their inner tokens in
`@media(min-width:768px)` and friends (`emilia.bp:88-90`). A component styled with them behaves the
same whether it is rendered full-bleed or inside a 300px sidebar, because it is asking about the
window rather than about the space it was given.

That is the wrong question for the one consumer emilia has. `jhonstart` components are composed —
the same card appears in a three-column grid and in a drawer — and the milestone's whole point is
that `onze` assembles pages out of them (front 53). A card that can only ask about the viewport
has to be parameterised by its context by hand, which means the layout decision leaks out of the
component and into every caller.

`§ 3.3` answers it with `@container`: a parent declares itself a container, and a descendant queries
the container's width. Nothing in `emilia` and nothing in fronts 33–48 owns it.

## Current state

- `tokens.bp:264-269` holds six modifiers. Three are pseudo-classes and three are viewport media
  queries. There is no container token and no `container-type` declaration anywhere.
- The three viewport widths are literal and wrong against `§ 3.3`: `768px`/`1024px`/`1280px` where
  the doc's breakpoint table gives `48rem`/`64rem`/`80rem`, and `min-width:` where the doc writes
  `width >=`. Front 34 fixes the named breakpoints; this front does not touch them, but it uses the
  doc's `width >=` form from the start rather than inheriting the wrong one.
- There is no `--container-*` namespace, because there is no theme. Front 54 adds it with the
  thirteen values of `§ 3.3`.
- An `@container` rule cannot be emitted today for the same reason `@media` cannot be hoisted: the
  output is one class body with blocks nested inside it (`emilia.bp:85-90`). Front 56 fixes that,
  which is why this front waits for it rather than working around it.

## Mechanism

**Upstream.** `§ 3.3` has two halves. A parent gets `@container`, which sets `container-type:
inline-size`. A descendant gets a size variant — `@md:flex-row` — which compiles to
`@container (width >= 28rem)`. Containers may be named: `@container/main` on the parent and
`@sm/main:` on the descendant, so a component can query a specific ancestor rather than the nearest
one. The thirteen sizes run `@3xs` (16rem) through `@7xl` (80rem) and live in the theme's
`--container-*` namespace (`§ 3.5`), which means a project can change them.

**In botopink.** A payload-free section for the markers, and three **top-level `Token` variants**
for everything that carries a payload:

```bp
    Container {
        Inline,
        Normal,
        Size,
    }

    ContainerNamed(name: string),
    ContainerAt(size: string, inner: Token[]),
    ContainerAtNamed(size: string, name: string, inner: Token[]),
```

**Why the split.** A payload leaf nested inside a section cannot be constructed by any spelling, and
a section-typed value cannot be constructed standalone — both verified against the real compiler,
both filed in [`../language-gaps.md`](../../language-gaps.md), and the rule stated once in
[`../contracts.md`](../../contracts.md) § 4a. `Inline`, `Normal` and `Size` carry no payload, so they
stay section leaves exactly like `Layout.Block`. Everything else moves to the top of `Token` with
builtin-typed fields only.

`ContainerNamed(name)` emits both halves of what `@container/main` means —
`container-type: inline-size` and `container-name: <name>` — because naming a container without
making it one is never what the author meant, and emitting only the name would produce a rule that
does nothing.

**One variant, thirteen names.** The audit asked for the thirteen `@3xs`–`@7xl` sizes as
`Token[]`-wrapping modifiers. Thirteen *top-level* variants would deliver that and put thirteen
container names at the top of `Token`, next to the thirteen `ContainerAtNamed` duplicates the named
form would then need. One `ContainerAt(size, inner)` carrying the size as its theme key, plus
thirteen **typed builder functions**, delivers the same authoring surface — `containerAtMd(inner)`
is a name a developer writes and a language server completes — with two variants instead of
twenty-six and one dispatcher arm instead of thirteen. The size key is never written by hand:

```bp
pub type ContainerSize { X3xs, X2xs, Xs, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, X5xl, X6xl, X7xl }

pub fn containerKey(s: ContainerSize) -> string
pub fn containerAt(size: ContainerSize, inner: Token[]) -> Token
pub fn containerNamed(size: ContainerSize, name: string, inner: Token[]) -> Token

pub fn containerAt3xs(inner: Token[]) -> Token
pub fn containerAt2xs(inner: Token[]) -> Token
pub fn containerAtXs(inner: Token[]) -> Token
pub fn containerAtSm(inner: Token[]) -> Token
pub fn containerAtMd(inner: Token[]) -> Token
pub fn containerAtLg(inner: Token[]) -> Token
pub fn containerAtXl(inner: Token[]) -> Token
pub fn containerAt2xl(inner: Token[]) -> Token
pub fn containerAt3xl(inner: Token[]) -> Token
pub fn containerAt4xl(inner: Token[]) -> Token
pub fn containerAt5xl(inner: Token[]) -> Token
pub fn containerAt6xl(inner: Token[]) -> Token
pub fn containerAt7xl(inner: Token[]) -> Token
```

A key that is not one of the thirteen is refused by the builder, so the string field is not a way in.
The builders are also the documented workaround for the second gap — a dot-shorthand path followed
by a payload call does not propagate the typed-array context inside an array literal, so
`[.ContainerAt(size: "md", inner: xs)]` does not parse even with the top-level shape.

`ContainerAt` and `ContainerAtNamed` wrap `Token[]` exactly as `Hover` does (`tokens.bp:264`) — the
shape that already works today — so they compose with every other modifier for free. Each lowers
through front 56's `Variant` with an unchanged selector and an at-rule built from the theme:

```bp
Variant(atRule: "@container (width >= " + themeValue(th, "--container-md") + ")", selector: "&")
```

**Sizes come from the theme, never from a constant.** That is the whole reason this front depends on
54 rather than hard-coding thirteen strings. A project that narrows `--container-md` gets narrower
containers everywhere, and the thirteen values live in exactly one place. A size the theme does not
define resolves to `""`, which would emit `@container (width >= )` — a silently broken rule — so the
dispatcher refuses it instead: an unresolvable container size is a `@panic`, with no fallback and no
option to emit the rule anyway.

**Named queries.** `ContainerAtNamed(size, name, inner)` carries the theme key (`"md"`) and the
container name alongside it, producing `@container main (width >= 28rem)` — the `@sm/main:` form of
`§ 3.3`.

## Steps

### Step 1 — the container markers

```bp
Container(Inline)    -> "container-type:inline-size"
Container(Normal)    -> "container-type:normal"
Container(Size)      -> "container-type:size"
ContainerNamed(name) -> "container-type:inline-size;container-name:" + name
```

Three of the four are section leaves with no payload, which construct today. The fourth is a
top-level variant, because a payload leaf inside a section does not. Its payload is destructured by
its declared field name; a positional bind type-checks and is `undefined` at run time.

**Acceptance:**
- [ ] `emilia([.Container.Inline])` renders `.e_x{container-type:inline-size}`.
- [ ] `emilia([Token.ContainerNamed("main")])` renders
      `.e_x{container-type:inline-size;container-name:main}` — one rule, two declarations, in that
      order.
- [ ] `Normal` and `Size` each have their own test.
- [ ] `container-name` is validated by front 57's `cssIdent` reject set before it is emitted; a name
      carrying `}` or `<` panics rather than reaching the document.

### Step 2 — the thirteen sizes, sourced from the theme

```bp
pub fn containerKey(s: ContainerSize) -> string
pub fn containerAt(size: ContainerSize, inner: Token[]) -> Token
fn containerAtRule(key: string, name: string, th: Theme) -> string
```

Thirteen one-line builders (`containerAtMd(inner)` and friends) sit on top of `containerAt`, so the
authoring surface has thirteen names even though `Token` has one variant.
`containerAtRule` looks `"--container-" + key` up in the theme, refuses an empty result, and builds
`"@container " + name + " (width >= " + value + ")"` with the name omitted when it is `""`.

**Acceptance:**
- [ ] All thirteen sizes render, and each test asserts the rem value from the `§ 3.3` table:
      `3xs` 16rem, `2xs` 18rem, `xs` 20rem, `sm` 24rem, `md` 28rem, `lg` 32rem, `xl` 36rem,
      `2xl` 42rem, `3xl` 48rem, `4xl` 56rem, `5xl` 64rem, `6xl` 72rem, `7xl` 80rem.
- [ ] `emilia(containerAtMd(inner))` renders `@container (width >= 28rem){.e_x{…}}` as a hoisted
      rule, not as a block inside the class body.
- [ ] `containerKey` has thirteen arms and a `ContainerAt` built with a key outside them is refused
      by the builder, so the `string` field is not a way past the enum.
- [ ] Narrowing `--container-md` to `20rem` in the theme changes that rule's width and changes
      nothing else.
- [ ] `clearNamespace(th, Ns.Container)` makes every size token panic rather than emit
      `@container (width >= )`.
- [ ] The emitted syntax is `width >=`, matching the `§ 3.3` breakpoint table, not `min-width:`.

### Step 3 — named containers

**Acceptance:**
- [ ] `containerNamed(ContainerSize.Sm, "main", inner)` renders
      `@container main (width >= 24rem){.e_x{…}}`.
- [ ] The unnamed form emits no name and exactly one space after `@container`.
- [ ] A named query and an unnamed query on the same class produce two separate hoisted rules.

### Step 4 — composition with the other modifiers

A container query is a `Variant` like any other, so nesting comes free from front 56. The order
matters and is pinned rather than left to the implementation.

**Acceptance:**
- [ ] `Token.Md([containerAtSm(inner)])` renders the viewport query outside the container query, and
      the reverse nesting renders them the other way round; both are asserted.
- [ ] `Token.Hover([containerAtSm(inner)])` renders
      `@container (width >= 24rem){.e_x:hover{…}}` — the at-rule hoists, the pseudo-class stays on
      the selector.
- [ ] A container query wrapping an arbitrary selector from front 57 composes without a special
      case.

### Step 5 — the pair that makes it work

The two halves are useless apart: a size variant with no ancestor container matches nothing, and a
container with no queries does nothing. The example and one test carry both.

**Acceptance:**
- [ ] `examples/container-queries-example.bp` renders a parent and a child from the same file and asserts
      both rules in one flushed document.
- [ ] A test asserts the child's rule and the parent's `container-type` appear in the same
      `@layer utilities` body.

## Examples

- [`./examples/container-queries-example.bp`](./examples/container-queries-example.bp) — one card that lays out as a
  column in a narrow slot and as a row in a wide one, without knowing the viewport, plus a named
  container so a nested card can query the page shell rather than its own parent.

## Language gaps

Two rows, both already in [`../language-gaps.md`](../../language-gaps.md), both verified against the
real compiler:

- **A payload leaf nested inside an enum section cannot be constructed by any spelling.** This is
  why `ContainerNamed`, `ContainerAt` and `ContainerAtNamed` are top-level `Token` variants and only
  the payload-free markers stay in a `Container` section. The rule is stated once in
  [`../contracts.md`](../../contracts.md) § 4a.
- **A section-typed value cannot be constructed standalone**, so a payload variant cannot take a
  section-typed field. This is why `ContainerAt` carries its size as a `string` theme key rather
  than as a `Token.Container.At`, and why the typing lives in the `ContainerSize` enum and the
  thirteen builders instead.
- **A dot-shorthand path followed by a payload call does not propagate the typed-array context
  inside an array literal**, so `[.ContainerAt(size: "md", inner: xs)]` does not parse. Nearest
  valid form: the builders this front ships.

Front 57 hits the same rows through its own token shape; they cover both fronts and one 1.0.10-beta
spec closes them.

## Test plan

`repository/emilia/test/container_test.bp`, run by `botopink test` at `repository/emilia/` and by
`zig build test-libs`. Green on `--target commonJS` and `--target erlang`.

The tests are: four marker tokens; thirteen sizes against the `§ 3.3` table, each asserting the rem
value rather than a class name; the theme-narrowing case and the cleared-namespace refusal; named
containers; four nesting orders; and the parent/child pair in one document.

The theme cases are the ones that matter most. A container-query implementation that hard-codes
thirteen strings passes every emission test and fails the one that changes `--container-md`, which
is why that test is written first.

## Definition of done

- The payload-free `Container` section and the three top-level `Container*` variants are in
  `tokens.bp` under this front's banner, and `tokenToSheet` gained four contiguous arms.
- `src/container.bp` exists, is declared in `src/root.bp` and listed in `botopink.json`.
- No container width appears as a literal anywhere in `repository/emilia/src/` outside
  `theme.bp`'s defaults.
- An unresolvable size panics; there is no fallback width and no option that emits the rule anyway.
- The thirteen sizes exist as named builders, and `containerKey` is the only place a size key is
  written.
- All three language-gap rows are marked in the example and already carried in
  [`../language-gaps.md`](../../language-gaps.md).
- The front's tests are green on its assigned target — for track D, both of them.
