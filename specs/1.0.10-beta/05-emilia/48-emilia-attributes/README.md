# Front 48 — emilia attributes: the class slot

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime — the class name is read by both halves: the server render (erlang, jhonstart front 30) writes it, the client bundle (js, onze front 68) recomputes it
**Depends on:** jhonstart [26](../../04-jhonstart/26-jhonstart-router/README.md) (router gate) · 33–47 for the tokens it carries (the slot is token-agnostic) · 56 (`emiliaWith`)
**Code:** `repository/emilia/modules/emilia/src/attributes.bp` (`mergeClass`, `nonAsciiIn`, and the
contract docblock) · `src/emilia.bp` (`// ── front 48 · the class slot` block: `className`, `styled`,
`styledWith`, `cls`, `clsWith`, `assertAsciiBody` — here because a sibling module cannot import
`emilia.bp`) · `repository/jhonstart/modules/jhonstart/src/html_attrs.bp` (`classAttr`, `withAttrs`,
`attrValue` — jhonstart code, emilia-unaware)
**Reference:** `TAILWIND_CSS_DOCS.md § 3` · https://tailwindcss.com/docs/styling-with-utility-classes · [contract 4](../../contracts.md)

**Open:** three boxes, all at the jhonstart/onze seam — the one-way-dependency assertion (twice) and
the shared literal in the bridge test and onze 68.

---

## What it delivers

The seam between an emilia `Token[]` and an element's `class` attribute, and contract 4's class-name
scheme, pinned and tested on both targets.

> **Contract 4 (emilia side).** An element's emilia class is `e_<hex>`, the lowercase-hex djb2-33
> fold (seed 5381, masked to 32 bits) of `encodeSheet(tokensToSheet(tokens, theme))`, with `tokens`
> in author order. Nothing else enters the hash. With a static class, the attribute value is
> `<static> + " " + <emilia class>` — static first, one ASCII space, no de-duplication, no sorting.

The six ways the two halves can disagree, each a test: (1) purity — no counter, salt or path; (1b)
**the theme is an input** — both halves must be handed the same `Theme` value; (2) order is identity;
(3) ASCII only — the JS fold reads UTF-16 units and the erlang fold codepoints; (4) merge order is
fixed; (5) attribute order is fixed — the slot appends.

| Function | Contract |
|---|---|
| `className(tokens, th) -> string` | `assertAsciiBody` first, then `emiliaWith(tokens, th)` |
| `styled(tokens, th) -> #(string, string)` | `#("class", className(tokens, th))` — drops into any builder's `attrs:` |
| `styledWith(base, tokens, th)` | `#("class", mergeClass(base, className(tokens, th)))` |
| `cls(tokens, th)` / `clsWith(base, tokens, th)` | the bare string for a `[class]={…}` hole in jhonstart's `html """…"""` DSL; the hole may not contain a space (the DSL splits the tag body on `" "`), so the form is always a pre-bound `val c = cls(tokens, th);` |
| `mergeClass(base, extra)` | `a + " " + b`; `mergeClass("", b) == b`, `mergeClass(a, "") == a`; no sorting, de-duplication or trimming. The one function without a `Theme`, and the only implementation in the workspace |
| `assertAsciiBody(tokens, th)` | panics naming the offending text when the composed body is not ASCII (only a top-level payload variant can carry one) — a call-time failure, never a silently different class |
| jhonstart `classAttr(value)`, `withAttrs(base, extra)`, `attrValue(attrs, name)` | `#("class", value)`; append, base first; the value or `""` — imports only `element` |

The contract is written in `attributes.bp`'s docblock, matching contract 4 word for word, along with
the no-space rule. emilia imports no library but std and nothing of this front imports jhonstart; the
rendered-HTML round trip is the `jhonstart-emilia` bridge's test (jhonstart
[30](../../04-jhonstart/30-jhonstart-streaming/README.md)).

**The shared fixture:** `className(cardTokens(), defaultTheme())` is `e_39b87d03` on both targets,
where `cardTokens()` is `[.Bg.White, .Pad.All.4, .Text.Bold, Token.Hover([.Bg.Gray.100])]`; the flushed
sheet carries `.e_39b87d03{` and its `:hover` rule.

## Acceptance

### Delivered

- [x] `styled(tokens, th)._0 == "class"` and `._1` is the class `emiliaWith(tokens, th)` returns;
      `cls`, `className` and `emiliaWith` agree; `cls` begins `e_` and holds no space.
- [x] `className(tokens, themeA) != className(tokens, themeB)` for themes differing in an entry the
      tokens read (a moved breakpoint).
- [x] `mergeClass("card", "e_abc") == "card e_abc"`, `mergeClass("", "e_abc") == "e_abc"`,
      `mergeClass("card", "") == "card"`; no sorting, no de-duplication, interior spaces kept.
- [x] `root.bp` declares `attributes` and `botopink.json` lists it.
- [x] The ASCII gate passes an ASCII list and refuses a non-ASCII payload with a message naming it,
      at call time; both halves asserted.
- [x] The docblock shows the pre-bound `val` form first, says an inline `cls(tokens, th)` in a hole
      fails, and cites the DSL's space split.
- [x] jhonstart: `withAttrs` keeps the base first and appends in order; `attrValue` returns the class
      or `""`; `html_attrs.bp` imports only `element`; jhonstart's `root.bp` declares it and
      `botopink.json` lists it.
- [x] Purity (same class twice, and after an unrelated `emilia()` call); the theme is an input; order
      is identity; merge order (`startsWith("card ")`, `endsWith(<class>)`); attribute order (the slot
      appends after the base attributes); the cross-target literal `e_39b87d03`; the flushed sheet
      carries the class.
- [x] The literal was first written after front 56 landed, so it has never been regenerated.
- [x] No test or example of this front imports jhonstart; emilia's core `botopink.json` has no
      dependency; `mergeClass` has one implementation; every slot function but `mergeClass` takes
      `th: Theme` and no call site in emilia builds a theme inline.
- [x] `repository/emilia/AGENTS.md` and `repository/jhonstart/AGENTS.md` record the modules and the
      cross-repo seam; green on commonJS and erlang.

### Open

- [x] No file under `repository/jhonstart/modules/jhonstart/src/` names emilia — `git grep -i emilia
      -- modules/jhonstart/src` is empty.
- [x] No file under `repository/jhonstart/modules/jhonstart/src/` names emilia, asserted by the
      `jhonstart-emilia` bridge test — `bridge_test.bp` "bridge: no file of the core's src names
      emilia" (every file read with std's `io.fs`).
- [ ] The literal-hex fixture (`e_39b87d03`) is shared with the `jhonstart-emilia` bridge test and onze
      front 68, and all three assert it — emilia and the bridge assert it (`bridge_test.bp` "bridge:
      the contract-4 literal on a rendered document"); onze front 68's bundle test does not yet.

## Constraints

- There is no expression-position decorator, and a decorator body cannot call sibling functions, so
  the slot is a plain function call in `attrs:` rather than an annotation.
- jhonstart's `html """…"""` DSL has no `[emilia]={…}` attribute; the existing `[class]={…}` hole
  carries the class string. A plain `class="card"` in the DSL sets nothing — a static class goes
  through `clsWith`.

## Examples

- [`./examples/attributes-example.bp`](./examples/attributes-example.bp) — a card's attribute arrays
  built with `styled` / `styledWith`, the class a `[class]={…}` hole receives through `cls`, the
  static-class merge and the no-space rule; every assertion is on a class name, an attribute array
  or the flushed CSS.
