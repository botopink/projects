# Front 57 — emilia escape hatches

**Track:** D emilia
**Priority:** high — without it any value outside the theme scale is unreachable, `emilia` is a closed set, and real applications route around it by writing raw CSS beside it, which defeats a typed token surface entirely. Tailwind has arbitrary values precisely because no scale is complete.
**Target:** comptime
**Wave:** 1 — both of its dependencies land in wave 0.
**Depends on:** 54 (arbitrary values sit next to theme lookups and must not bypass them silently), 56 (an arbitrary variant is a selector, and only 56 can emit one)
**Owns:** `repository/emilia/src/arbitrary.bp`, `repository/emilia/test/arbitrary_test.bp`; one `Arb` section appended to `src/tokens.bp` under a banner naming this front; one arm in `tokenToSheet`; the `pub mod arbitrary;` line in `src/root.bp` and its entry in `botopink.json`
**Does not touch:** any other front's token section or dispatcher; `src/output.bp`; `src/theme.bp`
**Reference:** `TAILWIND_CSS_DOCS.md § 3.1 Valores Arbitrários`, `§ 3.1 Propriedades CSS Arbitrárias`, `§ 3.2 Variantes Arbitrárias`, `§ 3.3 Valores Arbitrários` (breakpoints), `§ 3.7 Usando Arbitrary Values` · https://tailwindcss.com/docs/adding-custom-styles
**Replaces:** new — from the Tailwind coverage audit

---

## Problem

`emilia`'s token enum is the entire authored surface, by design
(`repository/emilia/src/tokens.bp:1-6`). A value that is not a variant does not exist. Today the
only way out is three `Hex(value: string)` leaves — `Color.Hex` (`tokens.bp:115`), `Bg.Hex`
(`tokens.bp:137`) and `Border.Color.Hex` (`tokens.bp:238`) — which between them reach exactly two
CSS properties and one of `border-color`. Everything else in CSS is unreachable: a one-off
`grid-template-columns`, a `calc()` height, a custom property, a selector the library does not know
about, a breakpoint at 320px.

That is not a small hole. The consequence is not "this feature is missing" — it is that a project
which hits the hole once stops using the typed surface for that element and writes CSS beside it,
and then the class emilia generates and the CSS the developer wrote have no relationship and no
shared cascade position. A closed set with no escape hatch produces more untyped CSS than an open
one, not less.

The audit that produced this front also established that the hole is closable today: `Color.Hex`
already works, which proves an enum leaf carries a string payload and splices it into the emitted
CSS. Nothing in the compiler has to change.

## Current state

- Three `Hex(value: string)` leaves exist and work: `emilia.bp:164`, `:176`, `:341`, each
  `"<prop>:" + value`. Destructuring uses the declared field name `value`, not an arbitrary bind —
  a positional name type-checks and is `undefined` at run time.
- No arbitrary *property* exists: every dispatcher hard-codes the property name.
- No arbitrary *variant* exists: `tokenToCss` (`emilia.bp:85-90`) has six modifier arms and all six
  wrap a fixed string.
- No arbitrary *breakpoint* exists: `Md`, `Lg`, `Xl` carry three literal widths and there is no
  fourth form.
- **There is no validation of any kind on a `Hex` payload.** `emilia([Color.Hex("red}</style><script>")])`
  produces a rule body that closes the class body, closes the `<style>` element and opens a script
  tag. The payload reaches the document verbatim through `emilia.bp:164` and the host cell at
  `emilia.bp:28-29`, neither of which inspects it. This front is the first thing in
  `repository/emilia/` to look at a string before emitting it.

## Mechanism

**Upstream.** Four escapes, all bracket syntax (`§ 3.1`, `§ 3.2`, `§ 3.3`, `§ 3.7`):
`bg-[#316ff6]` is an arbitrary *value* for a known property; `[--gutter-width:1rem]` is an arbitrary
*property*; `[&.is-dragging]:cursor-grabbing` and `[@supports(display:grid)]:grid` are arbitrary
*variants*; `min-[320px]:` and `max-[600px]:` are arbitrary *breakpoints*.

**In botopink.** One `Arb` section in `tokens.bp`, six variants, each the general form of a leaf
that already exists:

```bp
    Arb {
        Value(prop: string, value: string),
        Prop(name: string, value: string),
        Sel(selector: string, inner: Token[]),
        At(query: string, inner: Token[]),
        MinWidth(px: string, inner: Token[]),
        MaxWidth(px: string, inner: Token[]),
    }
```

`Sel`, `At`, `MinWidth` and `MaxWidth` carry a `Token[]` exactly as `Hover` does
(`tokens.bp:264`), so they compose with every other modifier for free. `Sel` and `At` lower through
front 56's `Variant`; `MinWidth` and `MaxWidth` lower to `@media (width >= …)` and
`@media (width < …)`, the two forms the `§ 3.2` reference table uses for `sm` and `max-sm`.

**The validation pass — this front's security surface.** A string payload that reaches the document
unread can close the rule body with `}` and can close the `<style>` element with `<`. Both are
breakouts, and both are reachable today through `Color.Hex`. The rule this front adopts is the
project's standing one: **refuse, do not sanitise, and give it no way around.** A rejected value is
not escaped, not stripped, not replaced with a fallback and not logged-and-continued. The build
fails, or the render dies.

Two gates, because there are two ways to reach the payload:

1. **Comptime.** The authored path is a template function, so the literal is read at compile time
   and a bad one fails the build with the offending text in the message. Five validators, each with
   its own reject set, because a selector legitimately contains `>` and a value legitimately does
   not:

   | Validator | For | Refuses |
   |---|---|---|
   | `cssValue` | a declaration value | `{` `}` `<` `>` `;` `@` `\` |
   | `cssIdent` | a property or custom-property name | anything outside `[A-Za-z0-9-_]` |
   | `cssSelector` | an `&`-relative selector | `{` `}` `<` `;` `@` `\`, and any count of `&` other than one |
   | `cssQuery` | an at-rule condition, written without its leading `@` | `{` `}` `<` `>` `;` `@` `\` |
   | `cssLength` | a breakpoint length | anything outside digits, `.`, and one unit from `px em rem ch vw vh %` |

2. **Run time.** The `Token.Arb.*` constructors are ordinary enum constructors and cannot be made
   private, so a caller can build one from a computed string that never passed a validator. The
   dispatcher therefore re-checks every payload against the same reject sets and `@panic`s on a
   violation. The comptime gate exists to move the failure earlier for the path people actually
   write; the run-time gate is the one that makes the guarantee. Neither has a flag.

**What the validators cost.** Media-feature range syntax (`(width >= 40rem)`) is unreachable through
`cssQuery`, because `<` and `>` are refused there. That is not an oversight: `MinWidth`/`MaxWidth`
cover the breakpoint case with a validated length, and front 34 owns the named breakpoints. A
`@supports` condition never needs an angle bracket. CSS escape sequences (`\2014`) are unreachable
everywhere, because `\` is refused; a codepoint goes in as a literal character.

**The builder functions, and why they exist twice over.** `arbValue(prop, value) -> Token` wraps the
constructor. It is where the run-time gate lives, and it is also the documented workaround for a
parser limitation: `[.Color.Hex("#abc")]` does not parse, because a dot-chain followed by a payload
call inside an array literal does not propagate the typed-array context
(`repository/emilia/src/emilia.bp:498-503`). Wrapping the call in a function or binding a typed
`val` first is what emilia's own code already does. That limitation is a language gap and it is
marked as one below.

## Steps

### Step 1 — the `Arb` token section

Appended to `tokens.bp` under a banner naming front 57, per the ownership convention in
`fronts.md`. One arm in `tokenToSheet`: `Arb(_inner) -> arbTokenToSheet(_inner, th);`.

**Acceptance:**
- [ ] Six variants, spelled exactly as above; payload fields destructured by their declared names in
      every `case` arm.
- [ ] The section is appended at the end of `tokens.bp`, not interleaved, and carries no `//`
      comment inside the enum body — a line comment inside a `type` brace body trips the parser.
- [ ] Exactly one line is added to `tokenToSheet`.

### Step 2 — the five validators

Template functions in `arbitrary.bp`. Each one is self-contained: a decorator or template body sees
only itself plus a minimal prelude, so a shared helper would be `undefined` at expansion time.

```bp
pub fn cssValue(comptime q: @Expr<string>) -> @Expr<string> {
    val raw = q.text();
    val braces = raw.split("{").length + raw.split("}").length;
    val angles = raw.split("<").length + raw.split(">").length;
    val others = raw.split(";").length + raw.split("@").length + raw.split("\\").length;
    val hits = braces + angles + others;
    val safe = if (hits > 6) { q.fail("emilia: an arbitrary value may not contain { } < > ; @ or a backslash"); raw; } else { raw; };
    return @expr(safe);
}
```

Six splits, each contributing at least one part, so `hits == 6` means every reject character is
absent. The check is written as arithmetic rather than as six conditions because a template body
flattens each block to one line and cannot carry a comment to explain a longer form; the reasoning
lives here instead.

`cssIdent` scans against a whitelist instead of a blacklist, accumulating rejects in an array rather
than an integer counter — a closure that reassigns both an array and an `i32` trips comptime
inference, so the count is the array's length.

**Acceptance:**
- [ ] `cssValue """#316ff6"""` compiles and yields `"#316ff6"`.
- [ ] `cssValue """red}</style><script>"""` fails the build, and the message contains the rejected
      text.
- [ ] `cssIdent """--gutter-width"""` and `cssIdent """background-color"""` compile;
      `cssIdent """background color"""` and `cssIdent """a;b"""` fail.
- [ ] `cssSelector """&.is-dragging"""` compiles; `cssSelector """.is-dragging"""` fails for having
      no `&`; `cssSelector """&.a &.b"""` fails for having two.
- [ ] `cssQuery """supports(display:grid)"""` compiles; `cssQuery """@supports(display:grid)"""`
      fails, because the leading `@` is emilia's to add.
- [ ] `cssLength """320px"""` and `cssLength """40rem"""` compile; `cssLength """320"""` fails for
      having no unit and `cssLength """calc(1px)"""` fails for its parentheses.
- [ ] No validator body contains a `//` comment, a parenthesised receiver, an `.at()` call or a
      `loop` in tail position — the four comptime landmines that surface as a bare
      `template evaluator produced no result`.

### Step 3 — the builders and the run-time gate

```bp
pub fn arbValue(prop: string, value: string) -> Token
pub fn arbProp(name: string, value: string) -> Token
pub fn arbSel(selector: string, inner: Token[]) -> Token
pub fn arbAt(query: string, inner: Token[]) -> Token
pub fn arbMin(px: string, inner: Token[]) -> Token
pub fn arbMax(px: string, inner: Token[]) -> Token
```

Each applies the matching reject set and `@panic`s with the offending payload before constructing
the token. A `@panic` is not recoverable and takes no handler, which is the intent: a document that
can escape its own `<style>` element is not a degraded render, it is a defect that must stop the
build.

**Acceptance:**
- [ ] `arbValue("color", "red}</style>")` panics; the message names the property and the payload.
- [ ] `arbValue("color", "red")` returns a `Token.Arb.Value`.
- [ ] Every builder is covered, including the two that take a `Token[]`.
- [ ] The panic message is byte-identical on `--target commonJS` and `--target erlang`.

### Step 4 — the dispatcher

```bp
fn arbTokenToSheet(t: Token.Arb, th: Theme) -> Sheet
```

- `Value(prop, value)` → `declSheet(prop + ":" + value)` — the `bg-[#316ff6]` row of `§ 3.1`.
- `Prop(name, value)` → `declSheet(name + ":" + value)` — the `[--gutter-width:1rem]` row of `§ 3.1`.
- `Sel(selector, inner)` → `nestVariant(tokensToSheet(inner, th), Variant(atRule: "", selector: selector))`
  — the `[&.is-dragging]:` row of `§ 3.2`.
- `At(query, inner)` → the same with `Variant(atRule: "@" + query, selector: "&")` — the
  `[@supports(display:grid)]:` row of `§ 3.2`.
- `MinWidth(px, inner)` → `Variant(atRule: "@media (width >= " + px + ")", selector: "&")` — the
  `min-[320px]:` row of `§ 3.3`.
- `MaxWidth(px, inner)` → `Variant(atRule: "@media (width < " + px + ")", selector: "&")` — the
  `max-[600px]:` row of `§ 3.3`, matching the `max-sm` row's `width <` form in `§ 3.2`.

**Acceptance:**
- [ ] `emilia([arbValue("background-color", "#316ff6")])` renders `.e_x{background-color:#316ff6}`.
- [ ] `emilia([arbProp("--gutter-width", "1rem")])` renders `.e_x{--gutter-width:1rem}`.
- [ ] An `Arb.Sel` wrapping one token renders a second rule with the arbitrary selector and the
      original class substituted for its `&`.
- [ ] `Arb.MinWidth("320px", …)` renders `@media (width >= 320px){…}` hoisted by front 56, not
      nested in the class body.
- [ ] An `Arb.Sel` nested inside a `Token.Md` composes: the media query wraps the arbitrary
      selector, not the other way round.

### Step 5 — the theme interaction

An arbitrary value must not become the easy way to avoid the theme. `§ 3.1`'s own example,
`max-h-[calc(100dvh-(--spacing(6)))]`, reaches back into the theme from inside an arbitrary value,
and that composition works here without a new mechanism: `spacing(6)` from front 54 returns a
string, so it concatenates into the value the builder receives.

**Acceptance:**
- [ ] `arbValue("max-height", "calc(100dvh - " + spacing(6) + ")")` renders
      `max-height:calc(100dvh - calc(var(--spacing) * 6))`.
- [ ] `arbValue("color", themeVar("--color-brand"))` renders `color:var(--color-brand)`.
- [ ] Neither composition needs a validator change: `calc(` and `var(` contain no rejected
      character, and a test asserts exactly that so nobody widens a reject set by accident.

## Examples

- [`./examples/arbitrary-example.bp`](./examples/arbitrary-example.bp) — a brand button whose colour
  is not in any palette, a custom property set on a container and read by its children, a
  drag-state selector the library does not know about, an arbitrary breakpoint, and the rejected
  payload that does not compile.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path followed by a payload call does not propagate the typed-array context inside an array literal: `[.Color.Hex("#abc")]` does not parse | every `Arb` variant with a payload, at every consumer call site; already recorded at `repository/emilia/src/emilia.bp:498-503` | bind a typed `val` first (`val c: Token = Token.Arb.Value(prop: "color", value: "#abc");`) or call a wrapper function (`arbValue("color", "#abc")`), which is what this front ships | `[.Arb.Value(prop: "color", value: "#abc")]` parses, with the array's element type driving the dot-shorthand resolution through the call |

The gap is ergonomic rather than expressive — the feature ships either way — but it stands
unresolved in the compiler today and it is hit by every consumer of this front, so it is marked in
the example and carried to `specs/1.0.10-beta/` as the milestone's exit gate requires.

## Test plan

`repository/emilia/test/arbitrary_test.bp`, run by `botopink test` at `repository/emilia/` and by
`zig build test-libs`. Green on `--target commonJS` and `--target erlang`.

The tests fall into three groups. **Emission**: one per `Arb` variant, asserting the rendered
document against the cited `§` row. **Composition**: an arbitrary variant inside a breakpoint and a
breakpoint inside an arbitrary variant, asserting both orders. **Refusal**: the run-time gate, for
which a `@panic` is observable, is asserted per builder.

The comptime gate cannot be asserted with a runtime `assert` — a build that must fail produces no
value to read. Those five cases follow the convention rakun uses for decorator placement
(`repository/rakun/test/di_test.bp:14-16`): the intent is recorded in the test file, and the case
itself lives in the compiler's own Zig suite as a reject fixture with its expected message.

The security cases are not optional coverage. A test that only asserts the happy path for
`cssValue` would have passed against today's unvalidated `Color.Hex` too.

## Definition of done

- The `Arb` section is in `tokens.bp` under its banner, and `tokenToSheet` gained exactly one line.
- `src/arbitrary.bp` exists, is declared in `src/root.bp` and listed in `botopink.json`.
- All five validators exist, with the reject sets in this README, and no opt-out anywhere in the
  library.
- The run-time gate covers every builder, and `Color.Hex`, `Bg.Hex` and `Border.Color.Hex` are
  routed through the same check by their owning fronts — noted here, owned by 33 and 40.
- The dot-shorthand gap is marked in the example and filed for 1.0.10-beta.
- The front's tests are green on its assigned target — for track D, both of them.
