# Front 55 — emilia preflight

**Track:** D emilia · **Priority:** high · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 56 (`Rule`, the `base` layer, `Options`, `withBase`, `renderRule`)
**Code:** `repository/emilia/modules/emilia/src/preflight.bp` (`preflightRules`, `preflight`; inline
tests; no externals)
**User docs:** `repository/emilia/docs.md` § *Preflight — the reset, opt-in*
**Reference:** `TAILWIND_CSS_DOCS.md § 4` (with `§ 3.2` for `::before`/`::after`, `§ 11.2` for the border default) · https://tailwindcss.com/docs/preflight

**Open:** none.

---

## What it delivers

The base reset Tailwind's utilities are designed against — without it `Border.W.1` draws nothing
(the browser's `border-style: none`) and `before:`/`after:` render nothing (no `content`).

```bp
pub fn preflightRules() -> Rule[]   // eleven rules, layer "base", literal selectors
pub fn preflight() -> string        // the same rules rendered as a CSS fragment (no @layer, no <style>)
```

| # | Selector | Declarations | `§ 4` bullet |
|---|---|---|---|
| 1 | `*,::before,::after` | `box-sizing:border-box;border-width:0;border-style:solid` | box-sizing; border width 0 |
| 2 | `html` | `line-height:1.5;-webkit-text-size-adjust:100%;tab-size:4` | line-height |
| 3 | `body` | `margin:0` | margins |
| 4 | `h1,h2,h3,h4,h5,h6` | `font-size:inherit;font-weight:inherit;margin:0` | heading margins |
| 5 | `p,blockquote,figure,pre,dl,dd,hr` | `margin:0` | margins |
| 6 | `ol,ul,menu` | `list-style:none;margin:0;padding:0` | list margins |
| 7 | `a` | `color:inherit;text-decoration:inherit` | links |
| 8 | `img,svg,video,canvas,audio,iframe,embed,object` | `display:block;vertical-align:middle` | images block |
| 9 | `img,video` | `max-width:100%;height:auto` | images |
| 10 | `button,input,select,optgroup,textarea` | `font:inherit;color:inherit;margin:0;padding:0;background-color:transparent` | inherited fonts |
| 11 | `::before,::after` | `content:""` | pseudo-element content |

- **Opt-in by argument.** `withBase(defaultOptions(), preflightRules())` turns it on; `defaultOptions()`
  (`base: []`) leaves it off — a deliberate inversion of Tailwind's default, because emilia renders
  into a page it does not own. No function, field, file or environment variable turns it on
  otherwise.
- **`border-style:solid`** beside `border-width:0` in rule 1 is a decision: `§ 4` names only the
  width, and without the style every `Border.W.*` token is inert.
- No selector carries `&`, so `Options.prefix` never reaches one.
- **Non-claim:** parity with `§ 4`'s eight bullets, not byte-equality with upstream `preflight.css`
  (which the reference does not print); the selector grouping is emilia's, one rule per bullet.

## Acceptance

### Delivered

- [x] Eleven rules, every one in the `base` layer with no at-rule; no selector carries `&`; each of
      `§ 4`'s eight bullets is covered by a test naming it; `content:""` appears once, on
      `::before,::after`.
- [x] With preflight, `border-style:solid` precedes every utilities body, and `Border.W.1` lands after
      the zero-width solid base rule; without it, the same class carries no `border-style` at all.
- [x] With preflight, `::before,::after{content:""}` precedes the utilities (asserted in
      `preflight.bp`).
- [x] `preflight()` starts with `*,::before,::after{box-sizing:border-box`, carries no `@layer` or
      `<style>`, and is one literal on both targets.
- [x] Off by default, on when passed, off again after `withBase(o, [])`; the check that no ambient
      switch exists is recorded in the test header.
- [x] `preflight.bp` is declared in `root.bp` and listed in `botopink.json`; green on commonJS and
      erlang.

## Examples

- [`./examples/preflight-example.bp`](./examples/preflight-example.bp) — a page turns the reset on
  through `Options` and renders a heading and a bordered card; the border is visible and the heading
  has no inherited margin.
