# TODO — jhonstart-html  (sub-language DSL · Wave 2)

> Task branch `task/jhonstart-html` · spec
> [`tasks/v0.beta.8/specs/jhonstart-html.md`](../../tasks/v0.beta.8/specs/jhonstart-html.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> ⛔ **GATED on `generic-loader-binding`** (binds bare `html`). `git merge feat`
> once the keystone lands before the bare-import scenario passes; the body (F1/F2)
> is independently testable within one project. Sibling of `erika` (same mechanism).
>
> Lib-side only — **zero** core code. `html """…""" -> @Expr<Element>`: triple-quoted
> markup authoring surface, Element output, builders resolved in the CALLER's scope.

## F0 — confirm the authoring surface
- [ ] Keep `pub fn html(comptime template: @Expr<string>) -> @Expr<Element>` (rename
      `q` → `template`); input is the `"""…"""` markup literal, output an Element tree.
      `html.d.bp` stays a marker until F2.

## F1 — markup parse (comptime, native-JS-only)
- [ ] Parse the `Text` parts into a tag/children structure: frame stack from
      `split`/`map`/`append`/`join`/`length`/`+`/`==`/`loop` **only** — no `?T`/Option
      (the eval has no Option runtime). Open/close tags nest; lowercase → builder name.

## F2 — build the Element expression (builders resolved in the CALLER's scope)
- [ ] Promote `html.d.bp` → `html.bp`: walk the structure, `template.build(…)` the
      pipeline — `<tag>` → `tag([...children])`, text → `text("…")`, `${expr}` `Interp`
      spliced via its `code` placeholder. List `html.bp` in `botopink.json`.
- [ ] Lowercase `<tag>` emits a bare `tag(...)` resolved in the call site's scope
      (expr-template `lookup`); unknown tag → diagnostic pointing inside the template.

## F3 — examples + tests
- [ ] `examples/jhonstart-html` imports the builders it uses
      (`import {html, Element, div, p} from "jhonstart"`), authors
      `html """<div><p>${x}</p></div>"""`, asserts `renderToString(page) == "<…>"`.
      Tests in `.bp`, never Zig.

## F4 — docs
- [ ] `libs/jhonstart/AGENTS.md`, `src/AGENTS.md`, `docs.md` → the `"""…"""` model +
      `from "jhonstart"` bare-import path, same commit as the code.

## Done gate
- [ ] `html """…"""` expands to the builder pipeline + renders; `botopink test` green.
- [ ] bare `html` import works cross-module (after `generic-loader-binding` merged).
- [ ] `grep -riE "jhonstart" modules/compiler-core/src` returns nothing.
