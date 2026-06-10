# TODO — jhonstart-html  (sub-language DSL · Wave 2) ✅ DONE

> Task branch `task/jhonstart-html` · spec
> [`tasks/v0.beta.8/specs/jhonstart-html.md`](../../tasks/v0.beta.8/specs/jhonstart-html.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> ✅ `generic-loader-binding` merged from `feat` (144b4e8) — bare `html` import works.
> Sibling of `erika` (same mechanism).
>
> Lib-side only — **zero** core code. `html """…""" -> @Expr<Element>`: triple-quoted
> markup authoring surface, Element output, builders resolved in the CALLER's scope.

## F0 — confirm the authoring surface
- [x] `pub fn html(comptime template: @Expr<string>) -> @Expr<Element>` (renamed
      `q` → `template`); input is the `"""…"""` markup literal, output an Element tree.

## F1 — markup parse (comptime, native-JS-only)
- [x] Parse the `Text` parts into a tag/children structure: frame stack from
      `split`/`slice`/`trim`/`join`/`append`/`forEach`/`length`/`+`/`==` **only** — no
      `?T`/Option (top read via `slice(len-1,len).join("")`, pop via `slice(0,len-1)`).
      Open/close tags nest; lowercase → builder name.

## F2 — build the Element expression (builders resolved in the CALLER's scope)
- [x] Promoted `html.d.bp` → `html.bp`: walk the structure, `template.build(…)` the
      pipeline — `<tag>` → `tag([...children])`, text → `text("…")`, `${expr}` `Interp`
      spliced via its `code` placeholder. `html.bp` listed in `botopink.json`.
- [x] Lowercase `<tag>` emits a bare `tag(...)` resolved in the call site's scope
      (expr-template model); an unknown tag is an unbound diagnostic at the call site.

## F3 — examples + tests
- [x] `examples/jhonstart-html` imports the builders it uses
      (`import {html, Element, div, p, …} from "jhonstart"`), authors
      `html """<div><p>${name}</p></div>"""`, asserts `renderToString(page) == "<…>"`.
      6 `.bp` tests (never Zig); `botopink test` + `run` green.

## F4 — docs
- [x] `libs/jhonstart/AGENTS.md`, `src/AGENTS.md`, `docs.md`, `examples/AGENTS.md` →
      the `"""…"""` model + `from "jhonstart"` bare-import path, same commit as the code.

## Done gate
- [x] `html """…"""` expands to the builder pipeline + renders; `botopink test` green.
- [x] bare `html` import works (example `import … from "jhonstart"`, after merge).
- [x] `grep -riE "jhonstart" modules/compiler-core/src` returns nothing.

## Comptime-eval gotchas surfaced (for [[reference_bp_parser_comptime_gotchas]])
- A template-fn comptime body must carry **no `//` comments inside its blocks**: the
  commonJS emitter flattens each block to one line, so a `//` comments out the code
  after it on that line (lexer is fine; the emitted JS breaks). Keep all prose in the
  file header, above `pub fn`.
- A nested `loop` cannot be the **tail of an if/else branch**: the emitter lowers the
  if/else to an expression and `return`s each branch tail, but `loop` → a `for`
  STATEMENT (`return for (...)` is invalid JS). Use `.forEach(...)` (an expression).
- A closure that reassigns **both an array and an `i32`**, called from another
  closure, trips comptime type inference (`expected i32, got array`). Track counts as
  an array LENGTH instead.
