# Front 55 — emilia preflight

**Track:** D emilia
**Priority:** high — without it `Border.W.1` means something different in emilia than `border` means in Tailwind, `before:`/`after:` render nothing, and every emilia page inherits browser defaults Tailwind removes. "Tailwind CSS v4 parity" is then unfalsifiable for the whole of track D, not just for this front.
**Target:** comptime
**Wave:** 2 — it needs 56's rule model, which lands in wave 1.
**Depends on:** 56 (a document-level rule is not a class body, and there is nowhere to put one until `Rule` and the `base` layer exist)
**Owns:** `repository/emilia/src/preflight.bp`, `repository/emilia/test/preflight_test.bp`; the `pub mod preflight;` line in `src/root.bp` and its entry in `botopink.json`
**Does not touch:** `src/tokens.bp` (it adds no `Token`), `src/output.bp` (it consumes `Rule` and `Options`, and edits neither), any per-section dispatcher
**Reference:** `TAILWIND_CSS_DOCS.md § 4. Estilos Base (Preflight)`, with `§ 3.2 Pseudo-elementos` for the `::before`/`::after` precondition and `§ 11.2 border-width` for the border default · https://tailwindcss.com/docs/preflight

---

## Problem

Tailwind's utilities are designed against a reset. `border` means `border-width: 1px` *because*
preflight already set `border-width: 0` on everything (`§ 4`), and `border-style: solid` is already
in place, so one class produces a visible border. `emilia` has no reset, so `Border.W.1`
(`repository/emilia/src/emilia.bp:330`) emits `border-width:1px` onto whatever the browser's default
`border-style: none` gives — nothing. The same utility, the same CSS, a different result.

The same gap makes front 34's pseudo-element variants inert. `before:` and `after:` only render when
`content` is set, which preflight does (`§ 4`: `::before` e `::after` com `content: ""`). Without it,
`Token.Before([.Text.Bold])` emits a correct `::before` rule that displays nothing, and no test
against the emitted CSS can tell the difference.

And with no reset, every emilia page inherits `h1` margins, `ul` bullets, underlined links, inline
image baselines and the browser's `line-height`. Every fold-in in the Tailwind audit that asks a
track-D front to match upstream output is measuring against a document that Tailwind never renders
into. That is the actual cost: not a missing feature, an unfalsifiable claim for sixteen fronts.

## Current state

- There is no reset anywhere in `repository/emilia/`. `flushSheet` (`emilia.bp:28-29`) emits
  `<style>` plus the registered class bodies and nothing else.
- `borderWidthToCss` (`emilia.bp:327-335`) emits `border-width:0|1px|2px|4px` with no accompanying
  `border-style`.
- There is no pseudo-element token today; `tokens.bp:264-269` has six modifiers and none of them is
  `Before` or `After`. Front 34 adds the nine of `§ 3.2`.
- `emilia` has no notion of a document-level rule. Every rule it can emit is keyed by a generated
  class name (`emilia.bp:46-51`).

## Mechanism

**Upstream.** Preflight is a stylesheet Tailwind injects into the `base` layer
(`§ 20.1`: `@import "tailwindcss/preflight.css" layer(base)`). `§ 4` lists what it does in eight
bullets. It is opted out of with `@source not "tailwindcss/preflight"` (`§ 4`), which removes the
file from the build.

**In botopink.** Preflight is a function returning `Rule[]` with literal selectors and
`layer: "base"`. Front 56's `Rule.selector` is a nesting template only when it contains an `&`;
preflight's selectors contain none, so they render verbatim, and the class prefix does not apply to
them.

```bp
pub fn preflightRules() -> Rule[]
pub fn preflight() -> string
```

`preflightRules()` is the form 56 consumes. `preflight()` is the same content rendered to a plain
CSS string, for a consumer who wants to ship the reset in a static file rather than through
`flush()`.

**The opt-out is an argument.** `§ 4` opts out by deleting a file from the build; emilia has no
build graph to delete from, so the opt-out is the absence of a call:
`withBase(defaultOptions(), preflightRules())` turns it on, and `defaultOptions()` — which has
`base: []` — leaves it off. That inverts Tailwind's default, and the inversion is deliberate:
emilia renders into a `<style>` block inside a page it does not own, and a library that silently
resets the host document's `h1` margins is worse than one that makes you ask. There is no ambient
configuration file, no environment variable and no global toggle; the only way to get the reset is
to pass it.

**What this front does not claim.** `§ 4` gives eight bullets, not a stylesheet. The
property/value pairs below are taken from those eight bullets; the selector *grouping* is emilia's,
chosen so that each bullet is one rule and testable on its own. This front therefore claims parity
with `§ 4`, and explicitly **does not** claim byte-equality with upstream `preflight.css`, which the
reference does not print. Anyone who wants that claim has to bring the file.

## Steps

### Step 1 — the eight bullets, one rule each

```bp
pub fn preflightRules() -> Rule[] {
    return [
        baseRule("*,::before,::after", "box-sizing:border-box;border-width:0;border-style:solid"),
        baseRule("html", "line-height:1.5;-webkit-text-size-adjust:100%;tab-size:4"),
        baseRule("body", "margin:0"),
        baseRule("h1,h2,h3,h4,h5,h6", "font-size:inherit;font-weight:inherit;margin:0"),
        baseRule("p,blockquote,figure,pre,dl,dd,hr", "margin:0"),
        baseRule("ol,ul,menu", "list-style:none;margin:0;padding:0"),
        baseRule("a", "color:inherit;text-decoration:inherit"),
        baseRule("img,svg,video,canvas,audio,iframe,embed,object", "display:block;vertical-align:middle"),
        baseRule("img,video", "max-width:100%;height:auto"),
        baseRule("button,input,select,optgroup,textarea", "font:inherit;color:inherit;margin:0;padding:0;background-color:transparent"),
        baseRule("::before,::after", "content:\"\""),
    ];
}
```

`baseRule(sel, decls)` is a private helper returning
`Rule(layer: "base", atRules: [], selector: sel, declarations: decls, important: false)`.

Mapping to `§ 4`, bullet by bullet: `box-sizing: border-box` in all elements → rule 1; margins
removed from headings and lists → rules 4, 5, 6; links without text decoration → rule 7; images with
`display: block` → rule 8; borders with `border-width: 0` → rule 1; `line-height: 1.5` on `html` →
rule 2; fonts inherited in `button`, `input` and friends → rule 10; `::before` and `::after` with
`content: ""` → rule 11.

Rule 1 carries `border-style: solid` alongside `border-width: 0`. `§ 4` names only the width, but a
width of zero with the browser's default `border-style: none` makes every `Border.W.*` token in
front 40 inert — which is precisely the defect this front exists to stop. The pairing is stated here
so it reads as a decision rather than as an unsourced addition.

**Acceptance:**
- [x] Eleven rules, every one with `layer == "base"` and an empty `atRules`. — held: preflight.bp test "preflight — eleven rules, every one in the base layer with no at-rule"
- [x] No rule's selector contains `&`, so none of them is affected by `Options.prefix`. — held: preflight.bp test "preflight — no selector carries `&`, so a prefix never reaches one"
- [x] Each of `§ 4`'s eight bullets is covered by at least one rule, and the test names the bullet. — held: the eight preflight.bp tests "… (`§ 4` bullet N)"
- [x] `content:""` appears exactly once, on `::before,::after`. — held: preflight.bp test "preflight — content: \"\" on ::before and ::after, once (`§ 4` bullet 8)"

### Step 2 — `border` means what it means in Tailwind

The reset's reason for existing is testable against front 40's output.

**Acceptance:**
- [x] With preflight in `Options.base`, the document contains `border-style:solid` before any
      `@layer utilities` body. — held: preflight.bp test "preflight — border-style:solid precedes every utilities body"
- [x] `emilia([.Border.W.1])` plus preflight produces a document in which `border-width:1px` is
      preceded by the `border-width:0;border-style:solid` base rule, in that order. — held: preflight.bp test "preflight — Border.W.1 lands after the zero-width solid base rule"
- [x] Without preflight, the same call produces a document containing no `border-style` at all — the
      test asserts the absence, so the difference the reset makes is recorded rather than assumed. — held: preflight.bp test "preflight — without it, the same class carries no border-style at all"

### Step 3 — the pseudo-element precondition

**Acceptance:**
- [x] With preflight, the document contains `::before,::after{content:""}`. — held: preflight.bp test "preflight — ::before,::after{content:\"\"} precedes the utilities"
- [x] A test in this file — not in front 34's — asserts that the `content` rule precedes the
      `@layer utilities` body, because a `::before` utility that sets `content` must be able to
      override it. — held: same test, in `preflight.bp`

### Step 4 — the rendered form

```bp
pub fn preflight() -> string
```

The same eleven rules rendered through 56's `renderRule` with `defaultOptions()`, joined with no
separator. For a consumer shipping a static `reset.css`.

**Acceptance:**
- [x] `preflight()` starts with `*,::before,::after{box-sizing:border-box`. — held: preflight.bp test "preflight() — a fragment that starts with the box-sizing rule"
- [x] `preflight()` contains no `@layer` token and no `<style>` token — it is a fragment, not a
      document. — held: same test
- [x] `preflight()` is byte-identical on `--target commonJS` and `--target erlang`. — held: preflight.bp test "preflight() — the whole fragment, as one literal", green on both targets

### Step 5 — the opt-out, stated once

**Acceptance:**
- [x] `defaultOptions()` renders a document with no `@layer base` body. — held: preflight.bp test "preflight — off by default, on when passed, off again when removed"
- [x] `withBase(defaultOptions(), preflightRules())` renders one. — held: same test
- [x] `withBase(o, [])` on an options value that had preflight removes it again. — held: same test
- [x] There is no function, field, file or environment variable in `repository/emilia/` that turns
      preflight on without passing it. A grep in the test file's comment records what was checked. — held: the check is recorded in `preflight.bp`'s test header; `preflight` appears only in that module and in `output.bp` comments

## Examples

- [`./examples/preflight-example.bp`](./examples/preflight-example.bp) — a page turns the reset on
  through `Options`, renders a heading and a bordered card, and asserts the two things the reset
  changes: the border is visible and the heading has no inherited margin.

## Language gaps

None — every construct in the example parses today.

One note, for the reader who expects a decorator: preflight is a plain function returning `Rule[]`,
not a `#[…]` annotation, because there is no declaration for it to annotate. A reset is document
state, and the only document state emilia has is the host cell front 56 owns.

## Test plan

`repository/emilia/test/preflight_test.bp`, run by `botopink test` at `repository/emilia/` and by
`zig build test-libs`. Green on `--target commonJS` and `--target erlang` — the reset is a constant
string, so a difference between targets would mean the renderer diverges, which is exactly what
front 56's move of document assembly into botopink is meant to prevent.

The tests assert: the eleven rules and their layer; the `§ 4` bullet coverage; the ordering claims in
steps 2 and 3; the absence of `border-style` when preflight is off; and that `preflight()` is a
fragment rather than a document. The ordering assertions are the load-bearing ones — a reset that is
present but emitted after the utilities is worse than no reset, and only an order assertion catches
it.

## Definition of done

- `src/preflight.bp` exists, is declared in `src/root.bp`, listed in `botopink.json`, and declares
  no externals.
- All eight bullets of `§ 4` are covered, and the README says which rule covers which.
- The `border-style: solid` addition is documented as a decision with its reason.
- The opt-out is an argument and nothing else; the absence of any ambient switch is asserted.
- The non-claim — parity with `§ 4`, not byte-equality with upstream `preflight.css` — is in the
  README and repeated in the test file header.
- The front's tests are green on its assigned target — for track D, both of them.

