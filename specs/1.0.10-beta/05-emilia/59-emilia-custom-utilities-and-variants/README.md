# Front 59 — emilia custom utilities and variants

**Track:** D emilia
**Priority:** medium-high — without it a consumer cannot name a reusable bundle or a project-specific variant, so every application re-lists the same twelve tokens at every call site. That is the duplication problem `§ 3.1` is entirely about, and `@apply` and `@utility` are the two most-used extension points in real Tailwind codebases.
**Target:** comptime
**Wave:** 3 — 56 lands in wave 1 and 34 in wave 2.
**Depends on:** 34 (a custom variant is built out of the `Variant` shape front 34 defines for the named ones), 56 (`Variant`, `Sheet`, and the question of where a named utility lands in the cascade)
**Owns:** `repository/emilia/src/compose.bp`, `repository/emilia/test/compose_test.bp`; the `pub mod compose;` line in `src/root.bp` and its entry in `botopink.json`
**Does not touch:** `src/tokens.bp` — this front adds **no** `Token` variant and **no** `tokenToSheet` arm, which is what makes it safe beside all twenty other track-D fronts; `src/output.bp`; any other front's dispatcher
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1 Gerenciando Duplicação`, `§ 3.7 CSS Customizado com @layer`, `§ 3.9 Funções e Diretivas`, `§ 20.3 @custom-variant`, `§ 20.4 @utility`, `§ 20.5 @apply`, `§ 20.7 @variant` · https://tailwindcss.com/docs/functions-and-directives

---

## Problem

`emilia` has exactly one authoring form: a `Token[]` literal at a call site
(`repository/emilia/src/emilia.bp:475-511`). There is no way to name a bundle of tokens, no way to
name a variant, and no way to give a generated class a stable name. A twelve-token button is written
out twelve tokens at a time wherever a button appears, and the day the button changes, every call
site changes.

`§ 3.1` calls this out as *the* problem with utility classes and gives four answers: loops,
multi-cursor editing, components, and `@layer components` with a named class. Botopink already has
the first three — they are ordinary language features, and the doc's own advice there is editing
practice, not library surface. The fourth is the one a CSS library has to provide, and `§ 20.4`
(`@utility`), `§ 20.5` (`@apply`) and `§ 20.3`/`§ 20.7` (`@custom-variant`/`@variant`) are its three
shapes.

The second half of the problem is narrower and harder to work around. A generated class name is a
content hash — `"e_" + djb2hex(…)`, pinned as contract 4 in
[`../contracts.md`](../../contracts.md) — which is exactly right when the class name is an
implementation detail and exactly wrong when it is part of an API. A component that documents
`.btn` for consumers to override, a design-system class a QA selector targets, a class a third-party
script toggles: none of those can be a hash, because the hash changes whenever a token in the bundle
changes. Today there is no way to opt out.

## Current state

- `pub fn emilia(tokens: Token[]) -> string` (`emilia.bp:46-51`) is the only registration path and it
  always names its output `"e_" + hashHex(rules)`. There is no second entry point and no parameter
  that changes the name.
- There is no composition helper anywhere. `tokensToCss` (`emilia.bp:102-104`) folds a list; nothing
  builds one.
- The six modifier variants (`tokens.bp:264-269`) are the complete variant vocabulary, and each is a
  hard-coded arm in `tokenToCss` (`emilia.bp:85-90`). A project cannot add a seventh without editing
  emilia.
- `repository/emilia/examples/emilia-card/src/main.bp` is the only real consumer in the tree, and it
  is a single component — the duplication this front is about has not been felt yet, and will be the
  moment front 53's blog is written.

## Mechanism

The whole point of this front is that **none of it needs a compiler change, and none of it needs a
new `Token` variant.** Tailwind needs three CSS directives here because CSS has no functions.
Botopink has functions, so:

| Tailwind | botopink |
|---|---|
| `@utility scrollbar-hidden { … }` | `pub fn scrollbarHidden() -> Token[]` |
| `@apply rounded-md px-4 py-2` inside `.btn` | `btn().append(extra)` — array concatenation |
| `@custom-variant hocus (&:hover, &:focus)` | `pub fn hocus(inner: Token[]) -> Token[]` |
| `@variant dark { @media … { @slot } }` | a function taking the inner tokens; `@slot` is the parameter |
| `@layer components { .card { … } }` | `named("card", tokens)` with `layer: "components"` |

A bundle is a function returning `Token[]`. Composing bundles is `append`. A variant is a function
from `Token[]` to `Token[]`. The `@slot` of `§ 20.3`/`§ 20.7` — the hole a custom variant wraps — is
the parameter, which is why this front does not need a `@slot` equivalent and why the audit could
record "we did not implement `@slot`" as a decision rather than an omission.

**Why a variant returns `Token[]` and not `Token`.** `§ 20.3`'s own example is
`@custom-variant hocus (&:hover, &:focus)` — a *selector list*, two selectors for one body. A single
`Token` cannot carry two selectors, and front 56's `Variant` is deliberately one at-rule and one
selector template. Two tokens produce two rules with the same declarations, which is what a selector
list compiles to anyway. So the return type is the list, and the one-selector case is a list of one.

**The named-class escape, and how it coexists with contract 4.** A second registration entry point:

```bp
pub fn named(className: string, tokens: Token[]) -> string
```

It registers the composed `Sheet` under `className` instead of under a content hash, places its
rules in the `components` layer rather than `utilities`, and returns `className`. Four rules keep it
from undermining contract 4:

1. **It is a different layer.** `§ 3.7` puts named classes in `components` and utilities in
   `utilities`, and front 56 emits `@layer theme, base, components, utilities;` in that order. A
   named class therefore always loses to a utility class on the same element, which is what a
   consumer expects when they write `<div class="btn bg-red-500">`. Contract 4 governs the
   `utilities` layer; `named` does not put anything there.
2. **It never enters the hash and never changes one.** `named` does not call `emilia()`, does not
   compute a hash, and does not register under an `e_` key. A token list passed to both `emilia` and
   `named` produces two independent registrations; the `e_` one is byte-identical to what it would
   have been without this front. Contract 4's clause 1 — a pure function of the token list — is
   untouched because nothing this front does is an input to it.
3. **The name is validated, and a name in emilia's own space is refused.** A `className` is checked
   against front 57's `cssIdent` reject set, and additionally refused if it starts with `e_`. That
   prefix belongs to the generated scheme, and a collision would let a named class silently replace
   a hashed one in the host cell — which is a single `Map` keyed by name (`emilia.bp:23-25`). Refuse,
   do not rename: a name that collides is a bug in the caller, and there is no argument that allows
   it.
4. **Contract 4 clause 4's merge order still holds.** Front 48 merges a static class and an emilia
   class as `<static> + " " + <emilia class>`. A `named` result is a static class from front 48's
   point of view — it is written by the author, not generated per render — so it goes on the left,
   and nothing in `attributes.bp` changes.

**Where a named utility lands in the cascade, stated once.** `components` for `named()`. A consumer
who genuinely wants a named class to beat a utility has one honest route: mark it important through
front 34's modifier, which is visible at the call site. There is no `layer:` argument on `named`,
because a per-call layer choice is how a cascade stops being predictable.

## Steps

### Step 1 — bundles are functions

No new API. This step is the convention plus one worked example plus the test that pins it.

```bp
pub fn scrollbarHidden() -> Token[] {
    val hidden: Token[] = [arbValue("display", "none")];
    return [
        arbValue("scrollbar-width", "none"),
        arbSel("&::-webkit-scrollbar", hidden),
    ];
}
```

That is `§ 20.4`'s `@utility scrollbar-hidden` example, declaration for declaration, written with
front 57's builders. A bundle is an ordinary `pub fn`, so it is exported, imported, typed, and
findable by go-to-definition — none of which a CSS `@utility` is.

**Acceptance:**
- [ ] `emilia(scrollbarHidden())` renders `scrollbar-width:none` and a second rule whose selector is
      the class followed by `::-webkit-scrollbar`.
- [ ] The bundle function takes no arguments and is callable from another package.
- [ ] A test asserts that the emitted declarations match `§ 20.4`'s example body.

### Step 2 — `@apply` is `append`

```bp
pub fn compose(bundles: Token[][]) -> Token[]
```

`compose` flattens a list of bundles in order, so the last one wins on a conflicting property,
matching `§ 3.1`'s last-rule-wins rule. The two-bundle case needs no helper at all — `btn().append(extra)`
is the array method — and `compose` exists for the four-or-five-bundle case where nesting `append`
calls stops being readable.

**Acceptance:**
- [ ] `btn().append(extra)` renders the bundle's declarations followed by the extra ones, in that
      order.
- [ ] `compose([a(), b(), c()])` equals `a().append(b()).append(c())` by rendered output.
- [ ] Where two bundles set the same property, the later one is emitted second and the test cites
      `§ 3.1`.
- [ ] `compose([])` renders an empty rule body, the same as `emilia([])` does today
      (`emilia.bp:465-473`).

### Step 3 — custom variants are functions over the inner list

```bp
pub fn hocus(inner: Token[]) -> Token[] {
    return [Token.Hover(inner), Token.Focus(inner)];
}

pub fn selector(v: Variant, inner: Token[]) -> Token
pub fn themeMidnight(inner: Token[]) -> Token[]
```

`hocus` is `§ 20.3`'s example. `selector(v, inner)` is the general form: it takes a front 56
`Variant` and wraps the inner tokens with it, which is how a project registers a variant the library
has never heard of — `§ 3.2`'s `@custom-variant theme-midnight (&:where([data-theme="midnight"] *))`
becomes a `Variant` with that selector and a one-line function around it.

**Acceptance:**
- [ ] `emilia(hocus(bold))` renders two rules, `:hover` and `:focus`, with identical declarations.
- [ ] A custom variant composes with a built-in one in both nesting orders, and both are asserted.
- [ ] `selector(Variant(atRule: "", selector: "&:where([data-theme=\"midnight\"] *)"), inner)`
      renders that selector with the class substituted for `&`.
- [ ] A `Variant` whose selector holds the wrong number of `&` is refused by front 56, and this
      front adds no path around that check.

### Step 4 — the named-class escape

```bp
pub fn named(className: string, tokens: Token[]) -> string
```

**Acceptance:**
- [ ] `named("btn", btn())` returns `"btn"` and renders `.btn{…}` inside `@layer components{…}`.
- [ ] The same token list passed to `emilia()` renders inside `@layer utilities{…}` under its hash,
      and the two rules coexist in one document.
- [ ] The hex produced by `emilia()` for a token list is byte-identical whether or not `named()` was
      called with the same list — the shared fixture from contract 4 is re-run as this front's own
      test to prove it.
- [ ] `named("e_abc", …)` is refused. So is a name carrying a character outside front 57's
      `cssIdent` set.
- [ ] Calling `named` twice with the same class name and different token lists is refused rather
      than last-write-wins, because the host cell is keyed by name and the loser would vanish
      silently.
- [ ] A named class and a utility class on one element: the utility wins, and the test asserts the
      layer order that makes it win rather than the outcome alone.

### Step 5 — the statement that this needs nothing from the compiler

The audit asked for this in writing, and it is the front's reason to exist: everything above is
functions over `Token[]`, `append`, and two records front 56 already defines. `compose.bp` declares
no `#[@External]` cell, adds no `Token` variant, adds no `tokenToSheet` arm, and contains no
comptime block.

**Acceptance:**
- [ ] `compose.bp` contains no `declare fn`, no `#[@`, no `comptime` and no `@emit`.
- [ ] `git diff` for this front touches `tokens.bp` in zero lines and `emilia.bp` in zero lines.
- [ ] The front's `## Language gaps` section reads `None`, and that is asserted by the absence of a
      `// LANGUAGE GAP:` marker in its example.

## Examples

- [`./examples/compose-example.bp`](./examples/compose-example.bp) — a design system with three
  bundles, one custom variant, a `@apply`-style override at a call site, and one named class whose
  name is part of the component's public API.

## Language gaps

None — every construct in the example parses today, and this front needs nothing from the compiler.
See [`../language-gaps.md`](../../language-gaps.md) for the milestone's list; this front adds no row to
it, which is the claim step 5 makes testable.

Two design constraints, recorded so they are not mistaken for gaps: a bundle returns `Token[]`
rather than a new `Token` because a custom variant may expand to a selector *list*
(`§ 20.3`), and `named()` takes no `layer:` argument because a per-call-site layer choice makes the
cascade unpredictable — both are decisions, and both are reversible by a later spec that argues
against them.

## Test plan

`repository/emilia/test/compose_test.bp`, run by `botopink test` at `repository/emilia/` and by
`zig build test-libs`. Green on `--target commonJS` and `--target erlang`.

Four groups. **Composition**: bundle emission, `append` order, `compose` equivalence, the
conflicting-property case. **Variants**: `hocus`, the general `selector` form, and both nesting
orders against a built-in variant. **Naming**: the layer a named class lands in, the refusals
(`e_` prefix, invalid ident, duplicate name), and coexistence with a hashed class in one document.
**Contract 4**: the shared fixture's literal hex re-asserted here, so that a change to this front
which accidentally reached the hash is red in this file rather than in front 23's SSR test three
waves later.

That last group is the one worth defending in review. This front is the only one in track D that
registers a class without hashing it, so it is the only place where the class-name contract could be
broken without a token front noticing.

## Definition of done

- `src/compose.bp` exists, is declared in `src/root.bp`, listed in `botopink.json`, and adds nothing
  to `tokens.bp` or `emilia.bp`.
- The three Tailwind directives have their botopink equivalent, each with the `§` it implements
  written next to it.
- `named()` exists, lands in `components`, validates its name, refuses the `e_` prefix and refuses a
  duplicate.
- Contract 4 is re-asserted from this front's own test file, with the same literal hex the shared
  fixture uses.
- The front's tests are green on its assigned target — for track D, both of them.

