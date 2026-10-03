# Front 119 — bpp styling: scoped `<style>`

**Priority:** medium — a page is complete without it (emilia tokens and a global stylesheet exist);
a component that carries its own CSS is not.
**Depends on:** decision [`08-d`](../README.md#08-d--who-scopes-css), open — it decides where
the scoping code lives, so the whole front waits on it, step 1 included · `118-bpp-components`
for step 2 (the template hands `<style>` over), and 118 step 1's one-line carve-out in
`jhonstart-emilia`'s bridge test, landed before this front opens (decision 189) ·
`05-jhonstart/26` landed, for the test file step 2 adds to `jhonstart-dom-test`. Step 1 depends
on no front of this track and runs beside `06-emilia/34`.
**Owns:** new `repository/emilia/modules/emilia/src/scoped.bp` + `test/scoped_test.bp` (and the
one line each appends to emilia's `root.bp` / `botopink.json`, which are 34's by ownership and
which no step of 34 edits) · `repository/jhonstart/modules/jhonstart-emilia/**` · one lowering
arm appended to `jhonstart-html/src/html.bp` (after 118; first of the three appending fronts) ·
the test file step 2 adds to `jhonstart-dom-test` for the selector matcher — the front owns the
file it adds; `fake_dom.mjs` stays `05-jhonstart/26`'s (decision 189)
**Does not touch:** `emilia/src/{emilia,output,arbitrary}.bp` (`06-emilia/34`'s);
`onze-assets/src/style_module.bp`; `modules/jhonstart/**`.

Reference: `astro-docs/11-styling.md`.

---

## Problem

A component cannot carry CSS that applies to itself only. `<style>` in `html """…"""` lowers to
the `style` builder with the text verbatim (`jhonstart/src/elements.bp`, `render.bp:188-200`), so
`h1 { color: red }` written in one component colours every `h1` on the page.

The three things in the tree that are near it are each something else:

| | Is | Is not |
|---|---|---|
| emilia | a typed utility compiler: `emilia([.Pad.All.4])` → class `e_<hash>` and a rule in a per-render sheet (`emilia/src/emilia.bp:112-235`) | a CSS processor — `emilia/AGENTS.md:602` says so; it never reads author CSS |
| `*.module.css` | class renaming to `<file>_<class>_<hash6>` at build (`onze-assets/src/style_module.bp:1-36`) | scoping: it renames classes, so `h1 { }` in a module file is still global |
| `globals.css` | read at build (`onze-cli/src/build.bp:112-114`) | per component |

So "emilia processes the `<style>` block" names nothing that exists: emilia has no entry point
that takes CSS text. Scoping is new code, and decision `08-d` is about where it goes.

## Current state

Measured 2026-10-01:

- emilia's rendering model: `Rule`, `Sheet`, `Variant`, `renderRule`, `renderDocument`
  (`emilia/src/output.bp:44-593`); `flush() -> @Task<string>` renders the per-render `<style>`
  with `@layer`s and drains the store (`emilia.bp:227-235`).
- The bridge: `jhonstart-emilia/src/root.bp:95` `plugin() -> RenderPlugin` puts the flush in the
  document head and in each boundary fill, and adds payload key `s`.
- `hashHex` is djb2 in a host cell on both targets (`emilia.bp:79-97`) — and a comptime body
  cannot call a host function (`language-gaps.md`, the lg2-w row), so a template cannot hash.
- A template knows where it was written: `q.source()` answers `Source(file, line, col)`
  (`builtins.d.bp:434-438`).

## Mechanism

Scoping is Astro's: every element written in a component's template gets one attribute, and every
selector in the component's `<style>` gets that attribute appended to its last compound.

```css
/* written */                      /* served */
h1 { color: red; }                 h1[data-s="a1"] { color: red; }
.text :global(em) { … }            .text[data-s="a1"] em { … }
article > p:hover { … }            article[data-s="a1"] > p[data-s="a1"]:hover { … }
```

**The scope id is computed without a hash.** The template function numbers the scope from where
the template is written — the module path and the line of the literal, sanitised to
`[a-z0-9-]` — because it cannot call `hashHex`. The id is long (`components-post-card-12`); the
build shortens ids to a counter in declaration order when it writes the final sheet (124), and the
runtime form stays readable.

**Three pieces, three owners.**

| Piece | Owner | Does |
|---|---|---|
| `scopeCss(scope: string, css: string) -> @Result<string, string>` | emilia, `scoped.bp` | reads the stylesheet — rules, at-rules, comments, strings — and rewrites selectors. Pure botopink, both targets, no host cell |
| the lowering arm in `html.bp` | jhonstart-html | adds `data-s="<scope>"` to every element of a template that has a scoped `<style>`; replaces the `<style>` element with `scopedStyle("<scope>", "<css>", vars)` |
| `scopedStyle` and the sink | jhonstart-emilia (the bridge) | calls `scopeCss` once per scope per process, registers the result with the render's style sink; the sheet goes out after emilia's flush |

jhonstart-html does not import emilia: `scopedStyle` resolves in the **caller's** scope, like a
tag's builder does (`html.bp:231`), so a page that writes `<style>` imports `scopedStyle` from
the bridge and a page that does not pays nothing.

**The directives.**

| Directive | Meaning |
|---|---|
| `<style>` | scoped |
| `<style is:global>` | handed to the sink as written; no attribute is added to the template's elements on its account |
| `:global(sel)` inside a scoped sheet | `sel` is left alone |
| `<style define:vars={a, b}>` | each name is a value in the template's scope; the template's root elements get `style="--a: …; --b: …"`, escaped by `escape.css` — a `97-std-dedupe` row (`03-bundled-libs/README.md` § "What does not move") |
| `<style is:inline>` | the `style` builder, verbatim — today's behaviour, now asked for by name |

**The cascade.** In the head, in this order: linked stylesheets (`globals.css`), emilia's layers,
scoped component styles in render order. Scoped styles come last, so they win at equal
specificity — Astro's order.

## Steps

### Step 1 — `scopeCss`

A CSS reader that understands exactly as much as scoping needs: comments, strings, `{ }` nesting,
at-rules that hold rules (`@media`, `@supports`, `@layer`, `@container`), at-rules that do not
(`@keyframes` — its selectors are percentages; `@font-face`), selector lists, compound selectors,
combinators, pseudo-classes and pseudo-elements (the attribute goes before a pseudo-element),
`:global(…)`, `:is(…)` and `:where(…)` (scoped inside).

**Acceptance:**
- [ ] `examples/scope-css-example.bp` passes on both targets
- [ ] 40 selector cases in `scoped_test.bp`, each a literal pair; the reference's own two
      (`h1`, `.text`) among them
- [ ] a stylesheet that does not parse — an unclosed brace, an unterminated string — is an `Error`
      naming the byte offset, never a sheet with the tail dropped
- [ ] `scopeCss(s, scopeCss(s, css))` is refused: a sheet already scoped with `s` is an `Error`
- [ ] one digest of the 40 outputs, compared on both targets

### Step 2 — The template arm and the bridge

**Acceptance:**
- [ ] `examples/scoped-style-example.bp` passes on both targets
- [ ] two components that both write `.title` render two rules and two attributes; neither rule
      matches the other's element — asserted on the rendered document with a selector matcher in
      `jhonstart-dom-test`
- [ ] a component rendered twenty times registers its sheet once
- [ ] the head order: `<link>`, emilia's `<style>`, the scoped `<style>`
- [ ] `define:vars` with a value containing `;` or `}` is escaped, and the test injects one

### Step 3 — A streamed boundary's styles

A component first rendered inside a `Suspense` fill needs its sheet in that fill.

**Acceptance:**
- [ ] a boundary's fill carries the scoped sheet of a component the shell did not render, as
      emilia's flush does today (`jhonstart-emilia/src/root.bp:95`)

## Gate

- [ ] `botopink test` green on both targets in `emilia/modules/emilia` and `jhonstart-emilia`
- [ ] `zig build test-libs`: emilia, jhonstart, onze green
- [ ] `scripts/gate.sh --cold` green
- [ ] `AGENTS.md` of every directory touched; `emilia/AGENTS.md:602` amended — emilia reads author
      CSS in one function, and says which
- [ ] Commit on `front/119-bpp-styling`; landing is the maintainer's step

## Blast radius

- **emilia gains a second input.** Until now everything emilia emits comes from `Token[]`;
  `scoped.bp` is a separate module that imports nothing from the token pipeline and is imported
  by nothing in it.
- **Every element of a styled component gains an attribute.** A test that pins a component's
  markup as a literal changes when the component gains a `<style>` — not before.
- **`contracts.md` § 4** (the emilia class contract) is untouched: `e_<hash>` classes and scoped
  attributes do not meet.

## Notes

- **Not added.** Sass, Less, Stylus, PostCSS, LightningCSS — there is no preprocessor host.
  `<style lang="…">` is a compile error naming the attribute. Inline `style` as an object — there
  is no object literal; the string is the form.
- **`class:list`** is 118's.
- **Minification and per-page chunks** are the build's (124); the runtime sheet is written as
  `scopeCss` answers it.
