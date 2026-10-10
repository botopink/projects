# Front 119 — bpp styling: `css`, `styled`, `jhonstart-styled`, the style section

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [148-styled](../../148-styled/README.md): s1 → 148 s1 · s4 boxes 2, 4 → 148 s2 · gate → 148 s2; [149-jhonstart](../README.md): s2 → 149 s5 · s3 → 149 s5 · s4 boxes 1, 3, 5 → 149 s5 · s5 → 149 s5. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** step 1 **high** — emilia moves onto `styled` first (decision 350; `06-emilia/34` step 5 waits on it); steps 2–5 medium — a page is complete without them (emilia tokens, global stylesheet); a
self-styled component is not. · **State:** step 1: `css` and `styled` done but for the theme read from the program (box 5, blocked: row 134 — `01-compiler/130` step 10, 353); `StyledContext`'s provider in jhonstart's core (step 2's) written and held: a program holding emilia and `styled` does not compile (`language-gaps.md`, "Two packages with a module of one name")
**Decision 361:** `jhonstart-styled` merges into the core `jhonstart` — every step below that names
that member writes its modules in the core (`jhonstart/src/styled_*.bp`), the style function carrying
`bpp`'s `#[style]`; the manifest is `"bpp": "jhonstart"`.
**Depends on:** (written against 278, 301, 302, 326, 338, 361) step 1: the two repositories
`botopink/css` and `botopink/styled` exist (created; each needs a first commit on `feat` before
it becomes a submodule — CI check 1) · step 2: `118-bpp-components` (the template arm), 118 step 1's
carve-out in `jhonstart-emilia`'s bridge test landed before this opens (189), `05-jhonstart/26` for
step 2's `jhonstart-dom-test` file · step 5: `06-emilia/34` step 5 (emilia over `styled`). The
`.bpp` style section's unfold is `116`'s (steps 1, 2), against step 2's package; the `.bpp`
examples compile at 116 step 6.
**Owns:** `repository/css/**` and `repository/styled/**` (new repositories, decision 326's rule for
a new shared package; their submodule entries in the meta `.gitmodules` and the `AGENTS.md`
§ Layout row, added when each has a `feat` commit) · in `repository/jhonstart`: the new member
`modules/jhonstart-styled/**`; the deletion of `modules/jhonstart-emilia/**` (step 5); one lowering
arm appended to `html.bp` (`jhonstart/src/html.bp` after `05-jhonstart/26` step 0; after 118; first
of three appenders) · step 2's `jhonstart-dom-test` file for the selector matcher (`fake_dom.mjs`
stays `05-jhonstart/26`'s, 189)
**Does not touch:** `repository/emilia/**` (`06-emilia/34`: the theme values in step 3, emilia over
`styled` in step 5); `onze-assets/src/style_module.bp`; `repository/botopink-lang/**` (the
toolchain is `116`'s); `modules/jhonstart/**` but the `html.bp` arm.

Reference: `astro-docs/11-styling.md`.

## Goal

A component's style applies to it only, written in the `.bpp` style section or activated with
`use` in a `.bp`; `:global(…)` leaves a selector unscoped; a run-time value in the style is a CSS
variable; CSS is built in three layers — `css`, `styled`, emilia — that know nothing of `.bpp`;
`jhonstart-styled` is the only place that does; every sheet a render writes goes out through one
sink; cascade: linked sheets, emilia's layers, scoped styles (decision 338).

```json
{ "bpp": { "default": "jhonstart", "style": "jhonstart-styled" } }
```

```bpp
type Props(title: string, children: Node)
--- style ---
.title { font-size: 2rem; }
article :global(p) { line-height: 1.6; }
---
<article>
  <h1 class="title">{props.title}</h1>
  {props.children}
</article>
```

## Problem

`<style>` in `html """…"""` lowers to the `style` builder verbatim (`jhonstart/src/elements.bp`,
`render.bp:188-200`): `h1 { color: red }` in one component colours every `h1`. Nearby, none scopes:

| | Is | Is not |
|---|---|---|
| emilia | typed utility compiler: `emilia([.Pad.All.4])` → class `e_<hash>` + a rule in a per-render sheet (`emilia/src/emilia.bp:112-235`), its own sheet model (`output.bp:44-593`) | a CSS processor — `emilia/AGENTS.md:602`: "Not a runtime CSS engine. No selector parsing"; never reads author CSS |
| `*.module.css` | class renaming to `<file>_<class>_<hash6>` at build (`onze-assets/src/style_module.bp:1-36`) | scoping: `h1 { }` in a module file is still global |
| `globals.css` | read at build (`onze-cli/src/build.bp:112-114`) | per component |

No package reads author CSS; emilia's `Rule` / `Sheet` / `renderDocument` is the only sheet model,
and only emilia uses it. Stands on:

- Bridge today: `jhonstart-emilia/src/root.bp:95` `plugin() -> RenderPlugin` puts emilia's flush in
  the head and each boundary fill, adds payload key `s` (`contracts.md` § 6a).
- `hashHex` is djb2 in a host cell on both targets (`emilia.bp:79-97`); std's `hash.contentHash` is
  the pure form (`06-emilia/34` step 1); a decorator calls a host function only with the cells its package's targets need (decision
  341, `01-compiler/14` step 6).
- `q.source()` answers `Source(file, line, col)` (`libs/std/src/builtins.d.bp`, `Source`).
- A `@Component<T>` body (354) may write `use`; a template function reads a function's hooks through
  `@typeInfo(f).hooks` (128, 277).

## Mechanism

**Three layers** (338), each importing only the one below it and std, none knowing `.bpp`, the
manifest, `data-s` or jhonstart:

| Layer | Where | Is | Imported by |
|---|---|---|---|
| `css` — the base for building CSS | `repository/css` (`botopink/css`) | a reader of a stylesheet (rules, at-rules, comments, strings, `{ }` nesting) into a typed `Sheet`; its renderer; `scope(id, css) -> @Result<string, string>`. Pure botopink, both targets, no host cell | `styled` |
| `styled` — the base for building CSS components | `repository/styled` (`botopink/styled`) | `styled "…"` and `styledProperty "…"`; the layered sheet; the theme mechanism; `behavior Styleable` | emilia · `jhonstart-styled` |
| emilia — a series of components built with `styled` | `repository/emilia` | the tokens, Tailwind's theme values (`defaultTheme()`), each family a `styledProperty` (`06-emilia/34` steps 3, 5) | the application |

Two consumers of `styled` (emilia, `jhonstart-styled`): decisions 115–117's criterion, under 326
(own repositories, ordinary dependencies).

**`styled`.** Two template functions over `comptime css: @Expr<string>`, both components in the
language's model (354, the pattern of 276's `View`):

```bp
// styled/src/styled.bp
pub type StyledSheet(…);                                  // the render's sheet, the layer
pub val StyledContext = comptime createContext(StyledSheet.missing());  // read use context(StyledSheet) (378, 379)
pub type Styled(className: string, rules: string) implement @Renderable;
pub type StyledView = @Component<Styled>;
pub type StyledProperty(declarations: string);        // a value, never a component (381)

pub default fn styled(comptime css: @Expr<string>) -> @ExprCustom<StyledView> { … }
pub fn styledProperty(comptime css: @Expr<string>) -> @ExprCustom<StyledProperty> { … }
pub behavior Styleable { fn toStyled(self: Self) -> StyledView; }   // StyledView
```

```bp
import styled, {styledProperty} from "styled";

pub val tab4 = styledProperty "tab-size: 4;";                         // declarations only
fn padAll(n: i32) -> StyledProperty { return styledProperty "padding: --spacing(${n});"; }   // Any (376)

pub val code = styled """
  ${tab4}                                                             // @apply: declarations inlined
  font-family: var(--font-mono);
  &:hover { ${padAll(2)} }
  @variant md { max-width: --theme(--breakpoint-md); }
""";
```

| Tailwind v4 | In `styled` |
|---|---|
| `--spacing(4)`, `--alpha(var(--c) / 50%)`, `--theme(--breakpoint-md)` | the same, expanded at build (`calc(var(--spacing) * 4)`, `color-mix(…)`, the theme's value) |
| `@variant hover { … }`, `@variant md { … }`, `@custom-variant hocus (&:hover, &:focus);` | the same; `md` from the theme |
| `@apply p-4;` | a hole of a `StyledProperty`: `${padAll(4)}` |
| `@utility tab-4 { … }`, `@utility tab-* { … --value(integer) … }` | refused: `pub val tab4 = styledProperty "…";`, `fn tab(n: i32) -> StyledProperty` |
| `@theme { … }` | refused: the typed `#[theme]` (300) |

- A component's class is std's `hash.contentHash` over its rules, with its layer's prefix (`s_` by
  default; emilia's layer keeps `e_`, `contracts.md` § 4).
- A component that reaches no run-time hook is computed at build (class and rule constant, nothing
  registered at render); one that does is computed per render — on commonJS an `async function`
  (120, 128), accepted (338).
- `styledProperty`'s literal holds declarations only: a `{`, `&` or `@` is an error at the character.
- **The theme mechanism is `styled`'s**: 300's `Theme`, `entry`, `clear`, `clearNs`, `clearAll`,
  `extendTheme`, the app's one `#[theme]` (`@TypeInfo.all(with: theme)`) and the cleared-breakpoint
  refusal (`@variant 2xl` with `2xl` cleared is a compile error). emilia supplies the values:
  `#[theme] pub val appTheme = comptime extendTheme(defaultTheme(), [entry(.Breakpoint, "md", Rem(52.0))]);`.

**`jhonstart-styled`**, the only package that knows `.bpp`:

| Piece | Does |
|---|---|
| its `pub default fn` — what `"bpp".style` names | a template function over the section's text answering a scoped `@Component<Styled>`: scope id (module path and section line, sanitised to `[a-z0-9-]`, `components-post-card-12`), the sheet scoped through `css.scope`, the run-time holes |
| run-time holes | a hole whose value is known at build is written into the rule; one known only at render becomes `var(--s-<n>)` in the rule and `style="--s-<n>: …"` on the template's root element, escaped by `escape.css` (a `97-std-dedupe` row) — Astro's `define:vars`, with no annotation |
| the `StyledContext` provider | `use provide(createContext(<the render's StyledSheet>))` at the render's root (379): styled components computed at render write to that sheet (352, 354); at a prerender, the build's sheet |
| the sink | writes the render's one `styled` sheet — emilia's layers, then scoped styles in render order — in the head and each boundary fill (step 3), after linked sheets; payload key `s` (`contracts.md` § 6a) |
| `#[styled(comptime decl: @Decl, comptime ..items: Styleable[])]` | records `ClassName(names: […])` (302); takes the application's `styled` components only — emilia's tokens reach a tag through emilia's own `#[emilia(…)]` (369), whose meta, a type `styled` declares, `html` reads beside `ClassName`: `<button #[styled(btn)] #[emilia(.Pad.All.4)]>` (step 4) |

**A component activates its style with `use`** (338): `html` reads the `use` of a scoped style in
the function's hooks and writes `data-s="<id>"` on every element that function's template writes; a
child's own template is not scoped by its parent.

```bp
import html, {View} from "jhonstart";
import styled from "jhonstart-styled";

pub default fn (props: Props) -> View {
    use styled """.title { font-size: 2rem; }""";          // what a .bpp style section unfolds to
    return html """<h1 class="title">{props.title}</h1>""";
}

val cardStyle = styled """.title { font-size: 2rem; }""";  // shared by several components
pub fn Card(props: Props) -> View { use cardStyle; return html """…"""; }
```

`html.bp` imports neither package: it reads a hook's type and the `ClassName` meta, both jhonstart's
own contracts.

**Scoping** (`css.scope`):

```css
/* written */                      /* served */
h1 { color: red; }                 h1[data-s="a1"] { color: red; }
.text :global(em) { … }            .text[data-s="a1"] em { … }
article > p:hover { … }            article[data-s="a1"] > p:hover[data-s="a1"] { … }
:global(h1) { margin: 0; }         h1 { margin: 0; }
```

| Written | Meaning |
|---|---|
| the style section / `use styled """…"""` | scoped |
| `:global(sel)` | `sel` left alone; the rest of the selector scoped |
| `${props.color}` | a value: constant into the rule, run-time into a CSS variable |
| `<style #[isInline]>` in markup | the `style` builder, verbatim — today's behaviour, by name |
| `<style>` in markup, any other form | error at the tag, naming the style section (338) |

**Cascade** (head order): linked stylesheets (`globals.css`), emilia's layers, scoped component
styles in render order — scoped last, winning at equal specificity; one `styled` sheet holds the
last two. The build shortens scope ids to a declaration-order counter in the final sheet (124).

## Decisions

Answered: `34-f` → 383 (`StyledMeta`, step 4), `34-a` → 369 (`#[emilia(…)]`'s meta and its reader, step 4), `34-c` → 368 (the reader's source order, step 1), `05emilia-e` → 358, `119-e` → 356, `119-c` → 355, `08-d` → 338, `119-b` → 352, `134-f` → 354, `119-d` → 353 (box 5 waits on `01-compiler/130` step 10).
Answered since: `119-g` → 374, replaced by 388 (the renderer runs a kept component with its scope, `01-compiler/134` step 6). `119-f` → 377 (a `styled` value registers where it is used, so a module `val` of one is legal; 376, 378).

## Blast radius

- **Two new repositories**; emilia gains its first non-std import (`styled`, `06-emilia/34` step 5).
- **A jhonstart member goes** (`jhonstart-emilia`) and one comes (`jhonstart-styled`); onze's
  plugin registration changes with it.
- **Every element of a styled component gains an attribute**; literal-markup tests change when a
  component gains a style, not before.
- **`<style>` in markup is refused** but `#[isInline]`: a template that writes one today fails at the
  tag, naming the section.
- **`contracts.md` § 4** (emilia class contract) untouched: `e_<hash>` classes and scoped attributes
  do not meet; 34 step 5 keeps the fixture byte-identical.

## Notes

- **Not added.** Sass, Less, Stylus, PostCSS, LightningCSS (no preprocessor host); a
  `--- style lang="…" ---` line is an error. Inline `style` object: no object literal; string is the form.
- **`classList`** (Astro's `class:list`) is 118's.
- **Minification, per-page chunks**: the build's (124); the runtime sheet is as `styled` renders it.
- **The unfold's spelling** of the section (`use <style> """…""";`, the generated import) is 116's.
