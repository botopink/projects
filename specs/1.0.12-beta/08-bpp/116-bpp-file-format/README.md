# Front 116 — bpp file format: a `.bpp` file is another spelling of a `.bp` module

**Priority:** medium — it changes how a page looks, not what a page can do; every feature of the
track is reachable from a `.bp` module (`118`).
**Depends on:** decisions 198 (what the file is), 199 (`type Props`, the function it unfolds to)
and 200 (`html` is the `pub default fn` of the core member `jhonstart`; the manifest reads
`"bpp": "jhonstart"`), 212 (the header between two `---`), 213 (the name), 221 (the app-file
kinds) and 266 (the package's `prelude.bp`) · open: `bpp-f` (the return type, step 2) and `bpp-g`
(a page's `route` and `params`, step 6) · `01-compiler`'s prelude scope (decision 266: a module's
last scope, a list of import items, imported only when used) · `05-jhonstart/26` step 0 (it merges `jhonstart-html` into the core and makes `html`
its default function) · `118-bpp-components` (the template language the literal is written in) ·
`01-compiler/26-cli-tooling` landed — it owns `compiler-cli/**` and `language-server/**` in this
milestone (`fronts.md` § Conflict rules).
**Owns:** in `repository/botopink-lang`: `modules/manifest/src/root.zig` (one key),
`modules/compiler-cli/src/cli/{scanner,resolver,libs,format_cmd,migrate}.zig` (the extension
lists, the unfold, the formatter's view of the file), `modules/lib-test-runner/src/discovery.zig`,
`modules/language-server/src/{project_index,project_graph,engine}.zig` (the extension lists, the
span mapping), `docs.md` § Modules, `tests/language/modules/bpp_*` · in
`repository/vscode-extension`: `package.json`, `src/extension.ts`, `src/testExplorer.ts` (the
registration)
**Does not touch:** any `codegen/*.zig`, `parser/*.zig` or `lexer.zig` — the toolchain learns no
syntax · `modules/compiler-core/src/comptime.zig` and `comptime/infer.zig` — a template body
gains nothing (`template.emit` and `template.slice` are not added, decision 198) ·
`repository/jhonstart/**` — the default function is `05-jhonstart/26`'s and 118's.

Reference: `astro-docs/09-astro-components.md` § Estrutura do Componente.

---

## Problem

After 118 a component is this, and it is correct and complete:

```bp
import html, {Element} from "jhonstart";
import {lib.db.Post};

type Props(post: Post, featured: bool = false)

pub default fn PostCard(props: Props) -> Element {
    val kind = if (props.featured) { "card featured" } else { "card" };
    return html """
      <article class={kind}>
        <h2>{props.post.title}</h2>
      </article>
    """;
}
```

Three of its lines are the same in every file that holds markup: the import of the template
function, the function header, and the `return html """` around the markup. Astro's file format
is those lines removed:

```bpp
---
import {lib.db.Post};

type Props(post: Post, featured: bool = false)

val kind = if (props.featured) { "card featured" } else { "card" };
---
<article class={kind}>
  <h2>{props.post.title}</h2>
</article>
```

Two implementations cannot land. The compiler lexing HTML and emitting `div(…)` calls into
jhonstart fails `zig build test` — `build.zig:342-355` refuses a library's name in
`modules/compiler-core/src`. And a syntax of the file's own, read by a library function, would
need that function to emit declarations and keep origins — two things a template body cannot do.
Neither is needed: the file is a `.bp` module with its boilerplate left out.

## Current state

Measured 2026-10-01 and, for the default function, at the answer of decision 198:

| Fact | Where |
|---|---|
| compiler-core takes `Module{path, source, declaration, srcPath}` and never reads an extension | `modules/compiler-core/src/module.zig:5-15` |
| the extension lists — seven sites in four tools | `compiler-cli/src/cli/scanner.zig:10` (`.bp`, `.botopink`), `resolver.zig:239-240`, `:369`, `:965-975`, `libs.zig:845-856`, `format_cmd.zig:94`, `migrate.zig:223-232`; `lib-test-runner/src/discovery.zig:365-377`; `language-server/src/project_index.zig:165`, `project_graph.zig:319`, `:391`, `:410`, `engine.zig:1467-1480` |
| the editor | `vscode-extension/package.json:24-31` (`"extensions": [".bp"]`), `:186-188`, `src/extension.ts:168-171`, `src/testExplorer.ts:50`, `:75` |
| a bundled package ships `.bp` only | `build.zig:779` (decision 117 rule 8) — unchanged by this front |
| the markup language is a template function: `pub fn html(comptime template: @Expr<string>) -> @ExprCustom<Element>` | `jhonstart/modules/jhonstart-html/src/html.bp` — the core's after `05-jhonstart/26` step 0 |
| `pub default fn` and `import html from "<package>";` check and run, and the tests of the package that declares one pass | measured at the answer of decision 198 |
| a template body fails at a span of its literal (`template.failAt`) and answers a `CustomNode` overlay the language server reads | `html.bp:153`, `:220`, `:269` |
| a type error inside code a template *builds* is reported at the built string's own offset laid over the calling file | measured — `language-gaps.md`; not this front's to fix, and not in its way: the header is copied, not built |
| the manifest has no key that names a package for a file kind | `modules/manifest/src/root.zig:214-231` |
| a `mod X;` resolves `X.bp` or `X/mod.bp` | `resolver.zig:239-240` |
| `.bpp` appears in no code in any repository | grep over `repository/` |

## Mechanism

**The application names the package** (decision 198). One key in its `botopink.json`:

```json
{ "name": "notes", "dependencies": { "jhonstart": { … }, "onze": { … } }, "bpp": "jhonstart" }
```

The value is the name of one dependency; the toolchain uses that package's `pub default fn`, a
template function, and names no library itself. For jhonstart that function is `html`, the
default function of the core member (decision 200) — `import html from "jhonstart";`.

**The toolchain unfolds the file onto that function** (decisions 198, 199, 212). The header sits
between two `---` lines at the very start of the file (Astro's form) and is ordinary botopink,
copied into the module as written; everything after the second `---` — or the whole file, when it
has no header — is the literal handed to the default function. A first line that is not `---` in
a file that contains one, or a header opened and never closed, is an error at that line. A
`.bpp` file always unfolds to a function, never to a `pub val`:

| The header | The module of `card.bpp` |
|---|---|
| declares `type Props(title: string, children: Node)` | the header's declarations, then `pub default fn card(props: Props) -> Element { <the header's statements> return html """<the markup>"""; }` |
| declares no `Props` | the header's declarations, then `pub default fn card() -> Element { <the header's statements> return html """<the markup>"""; }` |

The header's **declarations** — `import`, `type`, `pub` — stay at module level; its
**statements** — `val`, `use` — become the function's body ahead of the `return`, so they may
read `props` and call a hook. The attributes a caller writes on the component are the fields of
`Props` (decision 192) and its children arrive through the `children` field (decision 193). An
import in the header is written in the language's own form — `import {components.card.Card};`
for a module of the same package, `import {x} from "pkg";` for a package; there is no
relative-path import.

**Nothing is added to a template body.** The module-level half of the file is the header, so no
function emits declarations and none keeps an origin. A diagnostic inside the markup lands on its
line of the `.bpp` because the literal *is* the file: a span of the literal is a span of the
file, `template.failAt` underlines the file, and the `CustomNode` overlay the default function
returns is the file's tokens, hover and go-to-definition in the editor.

**The header keeps its lines.** It is copied, not rebuilt, so the unfold maps a position in the
module back to the position in the `.bpp` it came from, and a type error in the header is
reported at its own line and column of the file.

**The package's prelude** (decision 266). When the package the manifest names has a module
`prelude` (`src/prelude.bp`), a `.bpp` file reaches what that module imports without writing it —
`Element`, the builders its tags name. The prelude holds `import` items of the package's own
modules only (no other package, no activation; an alias is allowed) and is compiled and tested
with the package. It is not pasted into the module: the unfold hands `compiler-core` the items as
the module's last scope, and an item becomes an import only when a name of the file resolves
through it, so the module of a file that is only `<article></article>` imports `html`, `Element`
and `article` and nothing else. The header wins by scope order; a header that binds the default
function's name is an error at its line.

```bp
// jhonstart/modules/jhonstart/src/prelude.bp
import {element.Element};
import {element: {text, fragment, div, span, p, h1, ul, li}};
import {elements: {article, h2, header, footer, main, title, timeTag as time}};
```

**Seven lists learn one extension.** The sites of § Current state read one shared list instead
of spelling `.bp`. The CLI, the test runner and the language server unfold the file the same way
and hand compiler-core the same module, with `srcPath` the `.bpp` path. `mod PostCard;` and
`import {components.PostCard};` resolve `PostCard.bp`, then `PostCard.bpp`, then
`PostCard/mod.bp`.

**The formatter treats the header as botopink.** `botopink format` formats the header between the two
`---` lines as it formats a module and leaves the markup after it byte-identical; `format --check`
checks the header and passes the markup.

**Refusals, all at compile time.** A `.bpp` file in a project with no `bpp` key: an error at the
file, naming the key. A `bpp` that names a package the project does not depend on, or a package
with no `pub default fn` taking `comptime _: @Expr<string>`: an error at the key. `X.bp` and
`X.bpp` in one directory: an error naming both.

## Steps

### Step 0 — Measure what the unfold stands on

**Acceptance:**
- [ ] a `tests/language/modules/` cell: a package declaring `pub default fn` over
      `comptime template: @Expr<string>`, imported `import t from "<package>";` and called with a
      literal from a consumer, on every target the language suite runs
- [ ] the header rule of decision 199 run over every `.bpp` file under `specs/1.0.11-beta/*/*/examples/`:
      each header item is listed as a declaration (`import`, `type`, `pub`) or a statement (`val`,
      `use`), and every item the rule does not name — an `if`, an expression statement, a private
      `fn`, a `test`, a decorated declaration — is listed with the file it appears in
- [ ] a module assembled by hand the way the unfold assembles it: a type error on a header line
      and one inside the literal are each reported at the line a `.bpp` would have it

### Step 1 — `bpp` in the manifest model

**Acceptance:**
- [ ] `modules/manifest`: the key parsed and validated — a string, the name of a dependency
- [ ] unit tests for the refusals: not a string, a package that is not a dependency, a package
      with no `pub default fn` over `@Expr<string>`, the key on a project with no `.bpp` file
      (accepted), a `.bpp` file with no key

### Step 2 — The unfold

**Acceptance:**
- [ ] `tests/language/modules/bpp_*`: a fixture package whose default function is **not**
      jhonstart's (it answers the literal's length) — a `.bpp` with `type Props` unfolds to
      `pub default fn <name>(props: Props)`, one without to `pub default fn <name>()`, one with no `---` line is
      all literal; the toolchain serves the fixture unchanged, which is the proof that it knows no
      library
- [ ] the header's declarations are at module level and its statements in the body, in order; a
      statement reads `props`
- [ ] `X.bp` beside `X.bpp`, and a `.bpp` file with no key — each refused with the message of
      § Mechanism
- [ ] the prelude (decision 266): a fixture package with a `prelude.bp` — a `.bpp` that is markup
      only compiles; its module and its emitted code import only the items the file uses; a header
      name beats the prelude's; `prelude.bp` holding a `fn`, an item of another package or an
      activation is refused at its line; a header binding the default function's name is refused
      at its line. The scope itself (`compiler-core`: a module's last scope, a list of import
      items) is `01-compiler/01-checker`'s, handed to it by this front
- [ ] `grep -riE 'rakun|jhonstart|erika|emilia|onze'` over `modules/compiler-core/src` and the
      edited `compiler-cli` files is empty

### Step 3 — The extension in the seven lists

**Acceptance:**
- [ ] every site of § Current state reads one shared list instead of spelling `.bp`
- [ ] `botopink build`, `check`, `run`, `test` over a project with `.bpp` files; the test runner
      discovers a `test` declared in a header
- [ ] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

### Step 4 — The span mapping and the editor

**Acceptance:**
- [ ] a type error on a header line and a `failAt` inside the markup are reported at their line
      and column of the `.bpp` file by `botopink check` and by the language server
- [ ] hover and go-to-definition work in the header; the overlay the default function returns is
      served as the tokens of the markup — the extension ships no grammar of the file
- [ ] `vscode-extension`: `.bpp` registered; `zig build test-vscode` green

### Step 5 — The formatter

**Acceptance:**
- [ ] `botopink format` rewrites a badly indented header and leaves every byte after the `---`
      line as it was; `format --check` fails on the first and passes the second
- [ ] `scripts/format-check.sh` walks `.bpp` files — the header is under the gate's format stage
      like any `.bp`

### Step 6 — A project of `.bpp` files

**Acceptance:**
- [ ] `examples/` of this front, and the `examples/src/` tree of every front of the track,
      compile as a test project of onze whose `botopink.json` carries `"bpp": "jhonstart"`
- [ ] so do the `.bpp` forms of the other tracks' examples: `05-jhonstart/{26-jhonstart-router,
      27-jhonstart-link, 67-jhonstart-forms}/examples/src/` and
      `07-onze/53-onze-example-app/examples/{app, components}/` — the blog of `07-onze/53`, every
      app file kind that holds markup
- [ ] `examples/PostCard.bpp` unfolds to what `examples/PostCard-desugared-example.bp` spells,
      and the two render the same markup on both targets

## Gate

- [ ] `scripts/gate.sh --cold` green in `repository/botopink-lang`
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents the `.bpp` spelling, every fence compiled by `zig build test-docs`
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `front/116-bpp-file-format` in the two submodules; landing is the maintainer's
      step

## Blast radius

- **The extension sites of § Current state, in four tools, become one list.** A site missed is a
  tool that silently ignores `.bpp` files — step 3's acceptance runs every command over a `.bpp`
  project for that reason.
- **A new manifest key.** `botopink.json` ignores unknown keys today (`AGENTS.md` § Manifest), so
  an older toolchain reads a new manifest without error and then fails on the first `.bpp` file
  with "no such module".
- **compiler-core does not change.** No template member is added, no backend changes, no
  snapshot directory is touched: the unfold answers a module the four backends already compile.
- **The formatter and `00-gate/112`.** `format --check` is a hard gate over every source file; a
  `.bpp` file's header is under it, its markup is not.
- **`01-compiler/26-cli-tooling`** owns `compiler-cli/**` and the language server in this
  milestone; 116 opens after it.

## Notes

- **Why the application names the package.** A file kind discovered across dependencies needs a
  rule for two libraries that both claim it. One key in the application's manifest has no such
  case: the application chose.
- **Why the file is not a syntax.** A fence the compiler splits into a library's shapes is a
  syntax the compiler owns for one library's files; a syntax a library function reads needs that
  function to write the module. A header that is botopink and a literal that is the rest of the
  file need neither.
- **Still to be stated**, before the step named:
  1. *A page's parameter.* Decision 221 gives a `page.bpp` its decorator; its `route: PageContext`
     and its `params` are question `bpp-g`. Step 6, and `117-bpp-routing` step 1.
  2. *The return type.* `-> Element`, while a header statement may `await` a loader or call a
     hook with `use`, which today need `-> @Component<ElementBase, Element>` — question `bpp-f`.
     Step 2.
  3. *Header statements other than `val` and `use`* — step 0's list.
  4. *`Children`.* The examples of the track write `children: Children = []`; jhonstart declares
     no type `Children` (`element.bp`, `elements.bp`). 118 adds it, and the prelude imports it.
- **`examples/bpp-template-function-example.bp`** shows the mechanism decision 198 replaced — a
  library function named `bpp` that emits the module through `template.emit` and
  `template.slice`. Nothing in this README refers to it; it is to be deleted.
