# Front 57 — emilia escape hatches

**Track:** D emilia · **Priority:** high · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (arbitrary values sit beside theme lookups), 56 (`Variant`, `nestVariant`, `declSheet`)
**Code:** `repository/emilia/modules/emilia/src/arbitrary.bp` (validators, builders, the `…ToSheet`
helpers; imports `tokens` and `output` only) · `src/tokens.bp` (`// ── front 57 — escape hatches`: six
top-level variants, after front 34's block) · `src/emilia.bp` (six contiguous `tokenToSheet` arms under
the front-57 banner)
**User docs:** `repository/emilia/docs.md` § *Arbitrary values — the escape hatches*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1`, `§ 3.2`, `§ 3.3`, `§ 3.7` · https://tailwindcss.com/docs/adding-custom-styles

**Open:** none.

---

## What it delivers

Tailwind's four bracket escapes as six **top-level** `Token` variants (a payload leaf nested in a
section cannot be constructed — [`language-gaps.md`](../../language-gaps.md), contract 4a in
[`contracts.md`](../../contracts.md)), each with a validating builder:

| Upstream | Variant | Builder | Renders |
|---|---|---|---|
| `bg-[#316ff6]` (`§ 3.1`) | `Arb(prop, value)` | `arbValue(prop, value)` | `.e_x{background-color:#316ff6}` |
| `[--gutter-width:1rem]` (`§ 3.1`) | `ArbProp(name, value)` | `arbProp(name, value)` | `.e_x{--gutter-width:1rem}` |
| `[&.is-dragging]:` (`§ 3.2`) | `ArbVariant(selector, inner)` | `arbSel(selector, inner)` | a second rule, the class substituted for the `&` |
| `[@supports(display:grid)]:` (`§ 3.2`) | `ArbAt(query, inner)` | `arbAt(query, inner)` | `@supports(display:grid){…}` — emilia adds the `@` |
| `min-[320px]:` (`§ 3.3`) | `ArbMin(px, inner)` | `arbMin(px, inner)` | `@media (width >= 320px){…}`, hoisted |
| `max-[600px]:` (`§ 3.3`) | `ArbMax(px, inner)` | `arbMax(px, inner)` | `@media (width < 600px){…}` |

The four `Token[]`-carrying variants compose with every modifier (`ArbVariant` inside `Md`: the media
query wraps the arbitrary selector). The builders exist also because `[.Arb(prop: …, value: …)]` does
not parse — a leading-dot path followed by a payload call does not carry the typed-array context.

**The security surface: refuse, do not sanitise, no way around.** A payload that reaches the document
unread can close the rule with `}` or the `<style>` element with `<`. Two gates share five reject sets:

| Reject set | For | Refuses |
|---|---|---|
| value | a declaration value | `{` `}` `<` `>` `;` `@` `\` |
| ident | a property or custom-property name | anything outside `[A-Za-z0-9-_]`, or empty |
| selector | an `&`-relative selector | `{` `}` `<` `;` `@` `\`, and any count of `&` other than one |
| query | an at-rule condition, without its leading `@` | `{` `}` `<` `>` `;` `@` `\` |
| length | a breakpoint length | anything but digits, `.` and one unit of `px em rem ch vw vh %` |

- **Comptime:** the template functions `cssValue`, `cssIdent`, `cssSelector`, `cssQuery`, `cssLength`
  read a literal (`cssValue """#316ff6"""`) and fail the build with the offending text.
- **Run time:** the builders and the dispatcher helpers (`arbValueToSheet` …) `@panic` naming the
  property and payload — the `Token.Arb*` constructors cannot be made private, so the dispatcher
  re-checks every payload. Neither gate has a flag.
- The cost, deliberate: media range syntax is unreachable through `cssQuery` (`ArbMin`/`ArbMax` cover
  breakpoints), and CSS escapes (`\2014`) are unreachable everywhere.
- Theme composition needs no validator change: `arbValue("max-height", "calc(100dvh - " + spacing(6) + ")")`
  → `max-height:calc(100dvh - calc(var(--spacing) * 6))`; `arbValue("color", themeVar("--color-brand"))`
  → `color:var(--color-brand)`.

## Acceptance

### Delivered

- [x] Six top-level variants with `string`/`Token[]` fields only; each built through its builder and
      its rendered output asserted; every `case` arm destructures by declared field name; appended
      after front 34's block, with six contiguous arms under the front-57 banner.
- [x] `cssValue """#316ff6"""` yields `"#316ff6"`; `cssValue """red}</style><script>"""` fails the
      build naming the text; `cssIdent` accepts `--gutter-width`/`background-color` and refuses
      `background color`/`a;b`; `cssSelector` accepts `&.is-dragging` and refuses zero or two `&`;
      `cssQuery` refuses a leading `@`; `cssLength` accepts `320px`/`40rem` and refuses `320` and
      `calc(1px)`. The refusals were verified against the compiler and are recorded in
      `arbitrary.bp`'s test header.
- [x] The five template bodies are flat — no comment, no parenthesised receiver, no `.at()`, no loop.
- [x] `arbValue("color", "red}</style>")` panics naming the property and payload; `arbValue("color",
      "red")` builds; all six builders are covered; the panic text is one string on both targets.
- [x] `Arb`, `ArbProp`, `ArbVariant`, `ArbMin`/`ArbMax` render the cited `§` rows; `ArbVariant`
      inside `Md` nests in both orders.
- [x] The `spacing()`/`themeVar()` compositions render as above, and the reject-set test asserts
      `calc(…var(…))` is admitted.
- [x] `arbitrary.bp` is declared in `root.bp` and listed in `botopink.json`; green on commonJS and
      erlang.

## Known gaps

- The comptime refusals are build failures, not values a test can read; their reject fixtures belong
  in the compiler's Zig suite and are not there yet.
- The three nested `Hex(value)` leaves (`Color.Hex`, `Bg.Hex`, `Border.Color.Hex`) are still declared
  and unconstructible; they carry no run-time gate because nothing can build them. `arbValue` is the
  constructible form.

## Examples

- [`./examples/arbitrary-example.bp`](./examples/arbitrary-example.bp) — a brand button colour outside
  every palette, a custom property on a container, a drag-state selector, an arbitrary breakpoint,
  and the rejected payload that does not compile.
