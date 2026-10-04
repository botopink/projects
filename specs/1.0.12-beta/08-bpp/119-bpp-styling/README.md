# Front 119 — bpp styling: scoped `<style>`

**Priority:** medium — a page is complete without it (emilia tokens, global stylesheet); a
self-styled component is not. · **State:** not started · blocked by `08-d`
**Depends on:** (written against 278) open: [`08-d`](../README.md#08-d--who-scopes-css) (where scoping lives — every
step, step 1 included) · `118-bpp-components` for step 2 (`<style>` handed over), and 118 step 1's
carve-out in `jhonstart-emilia`'s bridge test, landed before this opens (189) · `05-jhonstart/26`
for step 2's `jhonstart-dom-test` file. Step 1 needs no track front; runs beside `06-emilia/34`.
**Owns:** new `repository/emilia/modules/emilia/src/scoped.bp` + `test/scoped_test.bp` (plus one
line each in emilia's `root.bp` / `botopink.json` — 34's, untouched by 34's steps) ·
`repository/jhonstart/modules/jhonstart-emilia/**` · one lowering arm appended to `html.bp`
(`jhonstart/src/html.bp` after `05-jhonstart/26` step 0; after 118; first of three appenders) ·
step 2's `jhonstart-dom-test` file for the selector matcher (`fake_dom.mjs` stays
`05-jhonstart/26`'s, 189)
**Does not touch:** `emilia/src/{emilia,output,arbitrary}.bp` (`06-emilia/34`'s); `onze-assets/src/style_module.bp`; `modules/jhonstart/**`.

Reference: `astro-docs/11-styling.md`.

## Goal

A component's `<style>` applies to it only; `#[isGlobal]`, `:global()`, `#[defineVars(…)]` work
(Astro's `is:global`, `define:vars` as annotations, 278); cascade:
linked sheets, emilia's layers, scoped styles.

## Problem

`<style>` in `html """…"""` lowers to the `style` builder verbatim (`jhonstart/src/elements.bp`,
`render.bp:188-200`): `h1 { color: red }` in one component colours every `h1`. Nearby, none scopes:

| | Is | Is not |
|---|---|---|
| emilia | typed utility compiler: `emilia([.Pad.All.4])` → class `e_<hash>` + a rule in a per-render sheet (`emilia/src/emilia.bp:112-235`) | a CSS processor — `emilia/AGENTS.md:602`: "Not a runtime CSS engine. No selector parsing"; never reads author CSS |
| `*.module.css` | class renaming to `<file>_<class>_<hash6>` at build (`onze-assets/src/style_module.bp:1-36`) | scoping: `h1 { }` in a module file is still global |
| `globals.css` | read at build (`onze-cli/src/build.bp:112-114`) | per component |

emilia has no CSS-text entry point; scoping is new code (where: `08-d`). Stands on:

- emilia's model: `Rule`, `Sheet`, `Variant`, `renderRule`, `renderDocument`
  (`emilia/src/output.bp:44-593`); `flush() -> @Task<string>` renders the per-render `<style>`
  with `@layer`s, drains the store (`emilia.bp:227-235`).
- Bridge: `jhonstart-emilia/src/root.bp:95` `plugin() -> RenderPlugin` puts the flush in the head
  and each boundary fill, adds payload key `s`.
- `hashHex` is djb2 in a host cell on both targets (`emilia.bp:79-97`); comptime cannot call a host
  function (`language-gaps.md` lg2-w), so a template cannot hash.
- `q.source()` answers `Source(file, line, col)` (`libs/std/src/builtins.d.bp`, `Source`).

## Mechanism

Astro's scoping: each element of the component's template gets one attribute; each selector in its
`<style>` gets it appended to the last compound.

```css
/* written */                      /* served */
h1 { color: red; }                 h1[data-s="a1"] { color: red; }
.text :global(em) { … }            .text[data-s="a1"] em { … }
article > p:hover { … }            article[data-s="a1"] > p[data-s="a1"]:hover { … }
```

**Scope id, no hash**: module path + literal's line, sanitised to `[a-z0-9-]`
(`components-post-card-12`); the build shortens ids to a declaration-order counter in the final
sheet (124); runtime form stays readable.

| Piece | Owner | Does |
|---|---|---|
| `scopeCss(scope: string, css: string) -> @Result<string, string>` | emilia, `scoped.bp` | reads the stylesheet — rules, at-rules, comments, strings — and rewrites selectors. Pure botopink, both targets, no host cell |
| the lowering arm in `html.bp` | jhonstart (`html`) | adds `data-s="<scope>"` to every element of a template with a scoped `<style>`; replaces the `<style>` with `scopedStyle("<scope>", "<css>", vars)` |
| `scopedStyle` and the sink | jhonstart-emilia (the bridge) | calls `scopeCss` once per scope per process, registers the result with the render's style sink; sheet goes out after emilia's flush |

`html.bp` imports no emilia: `scopedStyle` resolves in the **caller's** scope like a tag builder
(`html.bp:231`); only pages writing `<style>` import it from the bridge.

Annotations on `<style>` (278, 302) — `isGlobal`, `isInline`, `defineVars` — take `comptime decl: @Decl`
(kind `Element`) and record the style metas this front's arm reads (`StyleMode.Global`, `StyleMode.Inline`,
`StyleVars`); one of each per tag. Declared with the arm in `html.bp`, imported by the core's prelude.

| Written | Meaning |
|---|---|
| `<style>` | scoped |
| `<style #[isGlobal]>` | handed to the sink as written; adds no attribute to the template's elements |
| `:global(sel)` inside a scoped sheet | `sel` left alone |
| `<style #[defineVars(a, b)]>` | each name a value in the template's scope; root elements get `style="--a: …; --b: …"`, escaped by `escape.css` — a `97-std-dedupe` row (`03-bundled-libs/README.md` § "What does not move") |
| `<style #[isInline]>` | the `style` builder, verbatim — today's behaviour, by name |

**Cascade** (head order): linked stylesheets (`globals.css`), emilia's layers, scoped component
styles in render order — scoped last, winning at equal specificity.

## Open

### Step 1 — `scopeCss`

Reader scope: comments, strings, `{ }` nesting, rule-holding at-rules (`@media`, `@supports`,
`@layer`, `@container`), others (`@keyframes` — percentage selectors; `@font-face`), selector
lists, compounds, combinators, pseudo-classes/elements (attribute before a pseudo-element),
`:global(…)`, `:is(…)` and `:where(…)` (scoped inside).

- [ ] `examples/scope-css-example.bp` passes on both targets
- [ ] 40 selector cases in `scoped_test.bp`, each a literal pair, incl. the reference's two (`h1`, `.text`)
- [ ] unparsable sheet (unclosed brace, unterminated string) → `Error` naming the byte offset, never a truncated sheet
- [ ] `scopeCss(s, scopeCss(s, css))` refused: an already-`s`-scoped sheet is an `Error`
- [ ] one digest of the 40 outputs, compared on both targets

### Step 2 — The template arm and the bridge

- [ ] `examples/scoped-style-example.bp` passes on both targets
- [ ] `isGlobal`, `isInline`, `defineVars` and their return types in `html.bp`, in `prelude.bp`;
      `#[isGlobal]` on a `<div>` fails at the annotation (a `<style>` annotation)
- [ ] two components both writing `.title` render two rules and two attributes; neither rule
      matches the other's element — asserted on the rendered document with a `jhonstart-dom-test` selector matcher
- [ ] a component rendered twenty times registers its sheet once
- [ ] head order: `<link>`, emilia's `<style>`, scoped `<style>`
- [ ] a `#[defineVars]` value containing `;` or `}` is escaped; the test injects one

### Step 3 — A streamed boundary's styles

A component first rendered in a `Suspense` fill needs its sheet in that fill.

- [ ] a boundary's fill carries the scoped sheet of a component the shell did not render, as
      emilia's flush does (`jhonstart-emilia/src/root.bp:95`)

### Step 4 — emilia as a tag annotation: `#[styled(..tokens)]` (decision 301)

```bpp
<h1 #[styled(.Text.Size.X3xl, .Text.Bold, .Color.Gray.900)]>{post.title}</h1>
<div class="onze-font-inter" #[styled(.Pad.All.4, .Lg(.Pad.All.8))]>…</div>
```

- [ ] `jhonstart-emilia` declares `pub fn styled(comptime decl: @Decl, comptime ..tokens: Token[])` —
      no return (302): it records `decl.addMeta(ClassName(names: [hashOf(tokens)]))`; `ClassName(names:
      string[])` is jhonstart's (the core; `html` merges every `ClassName` meta into the tag's `class`,
      after a static `class`); `html` names no emilia (113)
- [ ] the token list is comptime: its order is the class's identity (`contracts.md` § 4) by
      construction; the class name and its rule computed at build once `hashHex` is std's pure
      `hash.contentHash` (`06-emilia/34` step 1) — the sheet a build artefact, the render registers
      nothing for a fixed list; until then computed at run time, unchanged
- [ ] a token naming a cleared breakpoint refused at compile time (300) — always, the list being comptime
- [ ] `class={emilia(tokens)}` leaves markup: refused in a template, naming `#[styled(…)]`; a style
      chosen at run time picks among annotated branches (`{if (urgent) { <p #[styled(.Color.Red.600)]>…</p> } else { … }}`)

## Decisions

- `08-d` — who scopes CSS: (a) emilia's `scopeCss` via the bridge (recommended), (b) onze-assets, (c) jhonstart's `html`. Every step.

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `emilia/modules/emilia` and `jhonstart-emilia`
- [ ] `zig build test-libs`: emilia, jhonstart, onze green
- [ ] `emilia/AGENTS.md:602` ("Not a runtime CSS engine") amended — emilia reads author CSS in one function, named

## Blast radius

- **emilia gains a second input** (all else from `Token[]`); `scoped.bp` imports nothing from the token pipeline, nor it from `scoped.bp`.
- **Every element of a styled component gains an attribute**; literal-markup tests change when a component gains `<style>`, not before.
- **`contracts.md` § 4** (emilia class contract) untouched: `e_<hash>` classes and scoped attributes do not meet.

## Notes

- **Not added.** Sass, Less, Stylus, PostCSS, LightningCSS (no preprocessor host);
  `<style lang="…">` is a compile error naming the attribute. Inline `style` object: no object literal; string is the form.
- **`classList`** (Astro's `class:list`) is 118's.
- **Minification, per-page chunks**: the build's (124); runtime sheet is as `scopeCss` answers.
