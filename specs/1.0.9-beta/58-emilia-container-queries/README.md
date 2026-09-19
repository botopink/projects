# Front 58 — emilia container queries

**Track:** D emilia
**Priority:** medium — without it component-scoped responsiveness is impossible and every `emilia`-styled `jhonstart` component stays coupled to the viewport. For a library whose only consumer is a component framework that is a structural limitation, not a missing utility.
**Target:** comptime
**Wave:** 1 — both dependencies land in wave 0.
**Depends on:** 54 (the `--container-*` namespace: the thirteen sizes are theme values, not constants), 56 (`@container` is an at-rule and has to be hoisted out of the class body)
**Owns:** `repository/emilia/src/container.bp`, `repository/emilia/test/container_test.bp`; one `Container` section appended to `src/tokens.bp` under a banner naming this front; one arm in `tokenToSheet`; the `pub mod container;` line in `src/root.bp` and its entry in `botopink.json`
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
that `onze13` assembles pages out of them (front 53). A card that can only ask about the viewport
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

**In botopink.** One `Container` section in `tokens.bp`:

```bp
    Container {
        Inline,
        Normal,
        Size,
        Named(name: string),
        At {
            X3xs(inner: Token[]),
            X2xs(inner: Token[]),
            Xs(inner: Token[]),
            Sm(inner: Token[]),
            Md(inner: Token[]),
            Lg(inner: Token[]),
            Xl(inner: Token[]),
            X2xl(inner: Token[]),
            X3xl(inner: Token[]),
            X4xl(inner: Token[]),
            X5xl(inner: Token[]),
            X6xl(inner: Token[]),
            X7xl(inner: Token[]),
        }
        AtNamed(size: string, name: string, inner: Token[]),
    }
```

`Inline`, `Normal` and `Size` are plain declarations. `Named(name)` emits both halves of what
`@container/main` means — `container-type: inline-size` and `container-name: <name>` — because
naming a container without making it one is never what the author meant, and emitting only the name
would produce a rule that does nothing.

The thirteen `At.*` variants wrap `Token[]` exactly as `Hover` does (`tokens.bp:264`), so they
compose with every other modifier for free. Each lowers through front 56's `Variant` with an empty
selector and an at-rule built from the theme:

```bp
Variant(atRule: "@container (width >= " + themeValue(th, "--container-md") + ")", selector: "&")
```

**Sizes come from the theme, never from a constant.** That is the whole reason this front depends on
54 rather than hard-coding thirteen strings. A project that narrows `--container-md` gets narrower
containers everywhere, and the thirteen values live in exactly one place. A size the theme does not
define resolves to `""`, which would emit `@container (width >= )` — a silently broken rule — so the
dispatcher refuses it instead: an unresolvable container size is a `@panic`, with no fallback and no
option to emit the rule anyway.

**Named queries.** `AtNamed(size, name, inner)` carries the size as its theme key (`"md"`) and the
container name alongside it, producing `@container main (width >= 28rem)` — the `@sm/main:` form of
`§ 3.3`. The key is a string in the token because a section variant cannot carry another section as
a payload field; it is typed at the call site instead, by a builder that takes an enum:

```bp
pub type ContainerSize { X3xs, X2xs, Xs, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, X5xl, X6xl, X7xl }

pub fn containerKey(s: ContainerSize) -> string
pub fn containerNamed(size: ContainerSize, name: string, inner: Token[]) -> Token
```

`containerNamed` is also the documented way around the parser limitation that stops
`[.Container.AtNamed(size: "md", name: "main", inner: xs)]` from parsing inside an array literal
(`repository/emilia/src/emilia.bp:498-503`) — the same limitation front 57 marks as a language gap,
and the same workaround.

## Steps

### Step 1 — the container markers

```bp
Inline -> "container-type:inline-size"
Normal -> "container-type:normal"
Size   -> "container-type:size"
Named(name) -> "container-type:inline-size;container-name:" + name
```

The payload is destructured by its declared field name; a positional bind type-checks and is
`undefined` at run time.

**Acceptance:**
- [ ] `emilia([.Container.Inline])` renders `.e_x{container-type:inline-size}`.
- [ ] `emilia([Token.Container.Named("main")])` renders
      `.e_x{container-type:inline-size;container-name:main}` — one rule, two declarations, in that
      order.
- [ ] `Normal` and `Size` each have their own test.
- [ ] `container-name` is validated by front 57's `cssIdent` reject set before it is emitted; a name
      carrying `}` or `<` panics rather than reaching the document.

### Step 2 — the thirteen sizes, sourced from the theme

```bp
pub fn containerKey(s: ContainerSize) -> string
fn containerAtRule(key: string, name: string, th: Theme) -> string
```

`containerAtRule` looks `"--container-" + key` up in the theme, refuses an empty result, and builds
`"@container " + name + " (width >= " + value + ")"` with the name omitted when it is `""`.

**Acceptance:**
- [ ] All thirteen sizes render, and each test asserts the rem value from the `§ 3.3` table:
      `3xs` 16rem, `2xs` 18rem, `xs` 20rem, `sm` 24rem, `md` 28rem, `lg` 32rem, `xl` 36rem,
      `2xl` 42rem, `3xl` 48rem, `4xl` 56rem, `5xl` 64rem, `6xl` 72rem, `7xl` 80rem.
- [ ] `emilia([Token.Container.At.Md(inner)])` renders
      `@container (width >= 28rem){.e_x{…}}` as a hoisted rule, not as a block inside the class
      body.
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
- [ ] `Token.Md([Token.Container.At.Sm(inner)])` renders the viewport query outside the container
      query, and the reverse nesting renders them the other way round; both are asserted.
- [ ] `Token.Hover([Token.Container.At.Sm(inner)])` renders
      `@container (width >= 24rem){.e_x:hover{…}}` — the at-rule hoists, the pseudo-class stays on
      the selector.
- [ ] A container query wrapping an arbitrary selector from front 57 composes without a special
      case.

### Step 5 — the pair that makes it work

The two halves are useless apart: a size variant with no ancestor container matches nothing, and a
container with no queries does nothing. The example and one test carry both.

**Acceptance:**
- [ ] `examples/container-example.bp` renders a parent and a child from the same file and asserts
      both rules in one flushed document.
- [ ] A test asserts the child's rule and the parent's `container-type` appear in the same
      `@layer utilities` body.

## Examples

- [`./examples/container-example.bp`](./examples/container-example.bp) — one card that lays out as a
  column in a narrow slot and as a row in a wide one, without knowing the viewport, plus a named
  container so a nested card can query the page shell rather than its own parent.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path followed by a payload call does not propagate the typed-array context inside an array literal: `[.Container.At.Md(inner)]` does not parse | every size variant and `AtNamed`, at every call site; recorded at `repository/emilia/src/emilia.bp:498-503` | bind a typed `val` first, or call the builder (`containerNamed(ContainerSize.Md, "main", inner)`) | `[.Container.At.Md(inner)]` parses, with the array's element type driving the dot-shorthand resolution through the call |

This is the same gap front 57 files; it is repeated here because it is hit independently by this
front's token shape and the exit gate reads per front. One 1.0.10-beta spec closes both.

One thing that is **not** a gap and is worth naming so it is not mistaken for one: a section variant
cannot carry another section as a payload field, which is why `AtNamed` takes its size as a string
key rather than as a `Token.Container.At`. The typed builder removes the ergonomic cost and the enum
`ContainerSize` keeps the call site typed, so no compiler change is wanted here.

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

- The `Container` section is in `tokens.bp` under its banner, and `tokenToSheet` gained exactly one
  line.
- `src/container.bp` exists, is declared in `src/root.bp` and listed in `botopink.json`.
- No container width appears as a literal anywhere in `repository/emilia/src/` outside
  `theme.bp`'s defaults.
- An unresolvable size panics; there is no fallback width and no option that emits the rule anyway.
- The dot-shorthand gap is marked in the example and filed for 1.0.10-beta alongside front 57's.
- The front's tests are green on its assigned target — for track D, both of them.
