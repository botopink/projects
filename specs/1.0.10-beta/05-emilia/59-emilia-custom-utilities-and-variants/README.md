# Front 59 — emilia custom utilities and variants

**Track:** D emilia · **Priority:** medium-high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 34 (`Variant`-built modifiers), 56 (`Variant`, `Sheet`, the `components` layer), 57 (`arbValue`, `arbSel`, the `cssIdent` reject set)
**Code:** `repository/emilia/modules/emilia/src/compose.bp` (`scrollbarHidden`, `compose`, `hocus`,
`selector`, `themeMidnight`; no `declare fn`, no `#[@`, no `comptime`, no `@emit`) · `src/emilia.bp`
(`// ── front 59 · the named-class escape`: `named`, beside the read-only `lookupRule` cell — here because
a sibling module cannot import `emilia.bp` and a host cell does not cross modules). No `Token` variant,
no `tokenToSheet` arm.
**User docs:** `repository/emilia/docs.md` § *Your own utilities and variants*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1`, `§ 3.7`, `§ 3.9`, `§ 20.3 @custom-variant`, `§ 20.4 @utility`, `§ 20.5 @apply`, `§ 20.7 @variant` · https://tailwindcss.com/docs/functions-and-directives

**Open:** none.

---

## What it delivers

Tailwind's extension directives as ordinary functions — botopink has functions, so it needs no
directive layer and nothing from the compiler.

| Tailwind | botopink |
|---|---|
| `@utility scrollbar-hidden { … }` (`§ 20.4`) | `pub fn scrollbarHidden() -> Token[]` — `[arbValue("scrollbar-width", "none"), arbSel("&::-webkit-scrollbar", [arbValue("display", "none")])]` |
| `@apply rounded-md px-4 py-2` (`§ 20.5`) | `btn().append(extra)`; `compose(bundles: Token[][]) -> Token[]` flattens in order, last wins (`§ 3.1`) |
| `@custom-variant hocus (&:hover, &:focus)` (`§ 20.3`) | `hocus(inner) -> Token[]` = `[Token.Hover(inner), Token.Focus(inner)]` — a variant returns `Token[]` because a custom variant may be a selector list |
| `@variant …` / `@slot` (`§ 20.7`) | a function taking the inner tokens; `@slot` is the parameter. General form: `selector(v: Variant, inner) -> Token`; e.g. `themeMidnight(inner)` = `&:where([data-theme="midnight"] *)` |
| `@layer components { .card { … } }` (`§ 3.7`) | `named(className, tokens) -> string` |

**The named-class escape**, `named(className, tokens)`:

1. Registers the composed sheet under `className`, its rules moved to the **`components`** layer, and
   returns `className` — so a utility on the same element always wins. There is no `layer:` argument;
   a named class that must beat a utility is marked `Important` at the call site.
2. Never hashes and never changes a hash: `emilia(list)` gives the same class whether or not
   `named(…, list)` was called. Contract 4 governs the `utilities` layer only.
3. The name passes front 57's `cssIdent` set and must not start with `e_` (emilia's generated space);
   a second **different** registration under one name is refused, not last-write-wins.
4. For front 48 a named class is a static class: it goes on the left of `mergeClass`.

## Acceptance

### Delivered

- [x] `emilia(scrollbarHidden())` renders `scrollbar-width:none` and a second rule on
      `<class>::-webkit-scrollbar`, matching `§ 20.4`'s body; the bundle is callable from another
      package (`repository/emilia/examples/emilia-cascade`, both targets).
- [x] `btn().append(extra)` renders the bundle then the extra declarations; `compose([a(), b(), c()])`
      equals chained `append`; the later of two bundles on one property is emitted second (`§ 3.1`);
      `compose([])` gives `emilia([])`'s class.
- [x] `emilia(hocus(bold))` renders `:hover` and `:focus` rules with one body; a custom variant
      composes with a built-in one in both orders; `selector(Variant(atRule: "", selector:
      "&:where([data-theme=\"midnight\"] *)"), inner)` substitutes the class; a wrong `&` count is
      refused by front 56 with no path around it.
- [x] `named("btn", btn())` returns `"btn"` and renders `.btn{…}` in `@layer components`, beside the
      hashed class in `utilities`; the hashed class is byte-identical either way (a literal hex);
      `named("e_abc", …)`, a bad ident and a second different registration are refused; with a named
      and a utility class on one element, the test asserts the layer order that makes the utility
      win.
- [x] `compose.bp` has no `declare fn`, `#[@`, `comptime` or `@emit`; `tokens.bp` is untouched; the
      example carries no language-gap marker.
- [x] `compose.bp` is declared in `root.bp` and listed in `botopink.json`; green on commonJS and
      erlang.

## Examples

- [`./examples/compose-example.bp`](./examples/compose-example.bp) — a design system with three
  bundles, one custom variant, an `@apply`-style override, and a named class that is part of a
  component's public API.
