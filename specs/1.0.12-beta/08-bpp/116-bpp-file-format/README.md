# Front 116 — bpp file format: a `.bpp` file is another spelling of a `.bp` module

**Priority:** medium — changes how a page looks, not what it can do; every feature is reachable
from a `.bp` module (118). · **State:** step 1 done (std's `bpp`, the key, the roles; with `01-compiler/130` step 10 box 1, decision 356); steps 0, 2–6 not started
**Depends on:** `01-compiler/01-checker` step 25 (the anonymous default, 289) · `118-bpp-components` (the literal's template language) · `05-jhonstart/26` step 0
(merges `jhonstart-html` into the core, `html` its default function, decision 200) ·
`01-compiler/26-cli-tooling` (owns `compiler-cli/**`, `language-server/**` this milestone; 116
opens after it) · `01-compiler`'s prelude scope (decision 270) · `119-bpp-styling` step 2
(the core's `#[style]` function — 361 merged `jhonstart-styled` into the core; step 6's style-section examples only).
Written against decisions 198, 199, 200, 212, 213, 221, 270, 284, 285, 338.
**Owns:** `libs/std/src/bpp.bp` (new module, 361; carve-out of `02-std-and-packaging`, with its `pub mod bpp;` line in `libs/std/src/root.bp`) · in `repository/botopink-lang`: `modules/manifest/src/root.zig` (one key), `modules/compiler-cli/src/cli/bpp.zig` (the roles) and `build.zig`'s `reportDependencyError` (one arm),
`modules/compiler-cli/src/cli/{scanner,resolver,libs,format_cmd,migrate}.zig` (extension lists,
unfold, formatter's view), `modules/lib-test-runner/src/discovery.zig`,
`modules/language-server/src/{project_index,project_graph,engine}.zig` (extension lists, span
mapping), `docs.md` § Modules, `tests/language/modules/bpp_*` · in `repository/vscode-extension`:
`package.json`, `src/extension.ts`, `src/testExplorer.ts` (registration)
**Does not touch:** any `codegen/*.zig`, `parser/*.zig`, `lexer.zig` (no new syntax) ·
`modules/compiler-core/src/comptime.zig`, `comptime/infer.zig` (no `template.emit` /
`template.slice`, decision 198) · the prelude scope in `compiler-core` (`01-compiler/01-checker`'s;
this front hands it the list) · `repository/jhonstart/**` (default function: `05-jhonstart/26`'s
and 118's; `prelude.bp`: 118's; `jhonstart-styled`: 119's).

Reference: `astro-docs/09-astro-components.md` § Estrutura do Componente.

## Goal

A `.bp` component (after 118: `import html, {View} from "jhonstart";` + `pub default fn
(props: Props) -> View { val kind = …; return html """<article …>…</article>"""; }` — 276, 289)
written as `components/PostCard.bpp`, dropping the template import, function header and
`return html """` (full pair: `examples/PostCard.bpp`, `examples/PostCard-desugared-example.bp`):

```bpp
import {lib.db.Post};

type Props(post: Post, featured: bool = false)

val kind = if (props.featured) { "card featured" } else { "card" };
---
<article class={kind}>
  <h2>{props.post.title}</h2>
</article>
```

Read by every tool (build, check, run, test, format, language server, editor); the compiler learns
no library and no syntax.

## Mechanism

**The application names the package** (198, 284, 361): `botopink.json` key `"bpp"`, one package
name, an entry of `dependencies`. The toolchain finds the four roles in that package by std's `bpp`
annotations (`libs/std/src/bpp.bp`): `#[bpp.html]` on the template function the markup unfolds onto
(exactly one), `#[bpp.style]` on the style section's (at most one), `#[bpp.htmlPrelude]` /
`#[bpp.stylePrelude]` on the marker `val` of each prelude module (at most one each). The object form
is refused at the key: `error: "bpp" is a package name — write "bpp": "jhonstart"`.

```json
{ "name": "notes", "dependencies": { "jhonstart": { … }, "onze": { … } }, "bpp": "jhonstart" }
```

**The file** (212, 338). The header starts on the first line, with no opening `---`, and ends at
the first separator line: `---` (the markup follows, to the end of the file) or `--- style ---`
(the style section follows, closed by a `---` line, then the markup to the end of the file). A file
with no separator line is markup only. One style section; an unscoped rule is written
`:global(…)`. Each refused at its line: a first line `---` (`error: the header starts on the first
line; a .bpp has no opening ---`); a `--- style ---` after the markup; a second style section; an
unclosed style section; a style section in a project with no `"bpp".style`.

**The unfold** (198, 199, 212, 213, 338). Always the module's **anonymous** `pub default fn` (289),
never `pub val`; its name is the importer's (the file name or an alias), and `decl.name` reads the
file name:

| The file | The module of `components/PostCard.bpp` |
|---|---|
| header declares `type Props(…)` | the header's declarations, then `pub default fn (props: Props) -> R { <the header's statements> return html """<the markup>"""; }` |
| header declares no `Props` | the header's declarations, then `pub default fn () -> R { <the header's statements> return html """<the markup>"""; }` |
| has a style section | as above, plus `import <style> from "<bpp.style>";` and `use <style> """<the section>""";` in the body, after the header's statements, before `return` |

The style section's import names the `"bpp".style` package's default function; its name is the
unfold's and binds no name the header can reach. The section is a literal like the markup: its
diagnostics map to the `.bpp` line. With `"bpp": {"default": "jhonstart", "style":
"jhonstart-styled"}`, the file

```bpp
type Props(title: string)
--- style ---
.title { font-size: 2rem; }
---
<h1 class="title">{props.title}</h1>
```

unfolds to (the prelude's imports, 270, aside)

```bp
import html, {View} from "jhonstart";
import styled from "jhonstart-styled";

type Props(title: string)

pub default fn (props: Props) -> View {
    use styled """.title { font-size: 2rem; }""";
    return html """<h1 class="title">{props.title}</h1>""";
}
```

- `import {components.PostCard};` binds it without alias; another file name needs one
  (`import {components.post_card as PostCard};`). No case conversion; the importer's name is the file's,
  so a file name that is no identifier needs an alias at the importer (289). `R` (decision 275) is the `R` of the default function's declared
  `@ExprCustom<R>` — the toolchain reads it from the signature and names no library; for jhonstart
  it is `View` (= `@Component<Element>`, decision 276 as amended by 354), whether or not the header uses `use` / `await`.
- Declarations (`import`, `type`, `pub`) module-level; statements (`val`, `use`) body ahead of
  `return` (may read `props`, call a hook). Attributes = `Props` fields (192); children via
  `children` (193). Header imports in the language's form (`import {components.card};`,
  `import {x} from "pkg";`); no relative import.

**What the toolchain knows** (285, 361): the package `"bpp"` names and, in it, the declarations std's
`bpp` annotations mark — the markup's unfold target, the style section's, and the two preludes —
nothing else; it names no library. A file's role
(page, layout, …) is the framework's: the route table `rakun-app` generates from `routing`'s file
kinds (`04-rakun/22`) calls jhonstart's `page` / `layout` on the unfolded function; the toolchain
applies no decorator by file name and reads no `bppKinds`. A decorator written on the header's last
line, before the separator line, is ordinary header code annotating the function (221 (1)).
A page takes no parameter: `use params<P>()`, `use pageData<D>()` in the header (293; was `bpp-g`).

**Nothing added to a template body.** The header is the module-level half; no function emits
declarations or keeps an origin. The literal *is* the file: a literal span is a file span,
`template.failAt` underlines the file, the default function's `CustomNode` overlay is the file's
tokens, hover, go-to-definition. Header is copied, so the unfold maps module positions back; a
header type error reports at its own line and column.

**The package's prelude** (270). The `"bpp".default` package's module `prelude` (`src/prelude.bp`, listed in `files`) gives a `.bpp` what it imports (`Element`, the builders its tags name): `import` items of the
package's own modules only (no other package — decision 242; no activation `X*`; alias allowed),
compiled and tested with the package; no manifest key names/overrides it. Handed to
`compiler-core` as the module's last scope (generic import-item list, no library); an item becomes
an import only when a file name resolves through it. A file that is only `<article></article>` is
`import html from "jhonstart"; import {element.Element, elements.article} from "jhonstart";
pub default fn () -> View { … }`, emitted code likewise. **Header wins** by scope order; a
tag then resolving to a header declaration that is not a builder fails at the tag, naming the
header line. The default function binds no name in its module (289), so a header may import a
decorator named like the file (`import {page} from "jhonstart";` in `page.bpp`). No prelude: only the
default function is imported.

```bp
// jhonstart/modules/jhonstart/src/prelude.bp — written by 118
import {element.Element};
import {element: {text, fragment, div, span, p, h1, ul, li}};
import {elements: {article, h2, header, footer, main, title, timeTag as time}};
```

**Extension in every tool.** compiler-core takes `Module{path, source, declaration, srcPath}`
(`modules/compiler-core/src/module.zig`), reads no extension. Sites spelling `.bp`, to read one
shared list: `compiler-cli/src/cli/scanner.zig` (`EXTS`), `resolver.zig` (`collectChildren`'s
sibling lookup, `isSource`, `stripBpExt`), `libs.zig` (`stripSourceExt`), `format_cmd.zig`
(`EXTS`), `migrate.zig` (`isSource`, `stripBpExt`); `lib-test-runner/src/discovery.zig`
(`srcHasBpFile`, `isBpSource`); `language-server/src/project_index.zig` (`scanDir`),
`project_graph.zig` (`loadSrcTree`), `engine.zig` (`findModuleFile`); editor
`vscode-extension/package.json` (`"extensions": [".bp"]`), `src/extension.ts`,
`src/testExplorer.ts`. CLI, test runner, language server unfold identically, `srcPath` = the
`.bpp` path. `mod PostCard;` / `import {components.PostCard};` resolve `PostCard.bp`, then
`PostCard.bpp`, then `PostCard/mod.bp`. Bundled packages still ship `.bp` only (`build.zig`,
decision 117 rule 8). The manifest (`modules/manifest/src/root.zig`, `parse`) has no file-kind key today.

**Formatter.** `botopink format` formats the header as a module, leaves every byte of the style
section and the markup unchanged; `format --check` checks the header, passes the style section and
the markup.

**Refusals (compile time).** `.bpp` with no `bpp` key: error at the file, naming the key. `"bpp"`
an object (or any non-string): error at the key, naming the string form. `"bpp"` naming a
non-dependency: error at the value. `#[bpp.html]` missing or twice, another role twice: error at the
key, naming the declarations. A role declaration that is not `pub`, and a declaration beside a
prelude module's imports and marker: error at that declaration. `#[bpp.html]` / `#[bpp.style]` on
anything but a function answering `@ExprCustom<R>`, a prelude role on anything but a `val`: std's
decorator refuses it at the annotation. A style section in a project whose package marks no
`#[bpp.style]`: error at its `--- style ---` line. `X.bp` + `X.bpp` in one directory: error naming
both.

## Open

### Step 0 — Measure what the unfold stands on

- [ ] `tests/language/modules/` cell: a package's `pub default fn` over `comptime template:
      @Expr<string>`, imported `import t from "<package>";`, called with a literal from a consumer,
      on every target the language suite runs
- [ ] decision 199's header rule over every `.bpp` under `specs/1.0.12-beta/*/*/examples/`: each
      header item listed as declaration (`import`, `type`, `pub`) or statement (`val`, `use`);
      every unnamed item (`if`, expression statement, private `fn`, `test`, decorated
      declaration) listed with its file
- [ ] a module hand-assembled as the unfold would: a header-line type error and one inside the
      literal each reported at the `.bpp` line

### Step 1 — `bpp` in the manifest model, the roles by `bpp`'s annotations (decision 361)

```bp
// libs/std/src/bpp.bp — the four role annotations (302's shape)
// repository/jhonstart/modules/jhonstart/src/root.bp
import {bpp} from "std";
#[bpp.html] pub default fn html(comptime t: @Expr<string>) -> @ExprCustom<View> { … }
#[bpp.style] pub fn style(comptime css: @Expr<string>) -> @ExprCustom<StyledView> { … }
// src/prelude.bp — imports, and the marker
#[bpp.htmlPrelude] pub val prelude = bpp.Prelude();
```

- [x] std's module `bpp` (`libs/std/src/bpp.bp`): `html`, `htmlPrelude`, `style`, `stylePrelude`,
      `Prelude`; listed in std's module table (`docs.md` § std, `libs/std/AGENTS.md`); a carve-out of
      `02-std-and-packaging` (one new file and its `pub mod` line)
- [x] `modules/manifest`: `"bpp"` is one package name (`"bpp": "jhonstart"`), a dependency; the object
      form refused at the key: `error: "bpp" is a package name — write "bpp": "jhonstart"`
- [x] the roles found in that package by `bpp`'s annotations: `#[html]` exactly once (missing or twice
      refused at the key, naming the declarations), `#[style]`, `#[htmlPrelude]`, `#[stylePrelude]` at
      most once; a marker on a prelude module holding other declarations refused at the declaration
- [x] the key on a project with no `.bpp` accepted; a `.bpp` with no key refused at the file
- [x] a style section in a project whose package has no `#[style]` refused at the section's
      `--- style ---` line
- [x] jhonstart: `#[bpp.html]` on `jhonstart-html`'s `html`, `#[bpp.htmlPrelude] pub val prelude =
      bpp.Prelude();` in the core's `src/prelude.bp`; no style function exists yet (119 step 2), and no
      manifest in any repository wrote the object form. Until `05-jhonstart/26` step 0 moves `html`
      into the core, the core marks no `#[bpp.html]` and `"bpp": "jhonstart"` is refused at the key

### Step 2 — The unfold

- [ ] the return type is read from the default function's signature (decision 275): the fixture
      package's `@ExprCustom<i32>` gives `-> i32`; jhonstart's gives `-> @Component<Element>`
      for a header with and without `use` / `await`; the toolchain spells no type name
- [ ] `tests/language/modules/bpp_*`: fixture package whose default function is **not**
      jhonstart's (answers the literal's length) — `.bpp` with `type Props` unfolds to
      `pub default fn (props: Props)`, without to `pub default fn ()`, no header = all
      literal; fixture served unchanged (proof the toolchain knows no library)
- [ ] the file's grammar (212, 338): the header from the first line to the first separator line;
      `---` → markup to the end of the file; `--- style ---` → style section closed by `---`, then
      markup; no separator line → markup only (a markup-only file compiles)
- [ ] a first line `---` refused at line 1: `error: the header starts on the first line; a .bpp has
      no opening ---`
- [ ] each refused at its line: a `--- style ---` after the markup; a second style section; an
      unclosed style section (at its `--- style ---` line)
- [ ] the style section unfolds to `use <style> """<the section>""";` after the header's
      statements, before `return html """…""";`, with `import <style> from "<bpp.style>";` binding
      no name the header can reach — § Mechanism's `Props(title)` example unfolds as spelled there
- [ ] fixture style package (not `jhonstart-styled`) whose default function answers something
      trivial (the section's length): a `.bpp` with a style section compiles onto it unchanged —
      the toolchain knows no library for the style section either
- [ ] a diagnostic inside the style section reported at its `.bpp` line, like the markup's
- [ ] the default function anonymous (289): `import {components.PostCard};` binds `PostCard` in the
      importer, an alias another name; a file name that is no identifier (`not-found.bpp`) unfolds;
      `decl.name` is the file name; `page.bpp` whose header imports and writes `#[page(…)]` compiles
- [ ] declarations at module level, statements in the body in order; a statement reads `props`
- [ ] a decorator on the header's last line, before the separator line, annotates the function
      (221 (1)); without one the function carries none — no decorator from the file name, no
      `bppKinds` read (285)
- [ ] `X.bp` beside `X.bpp`, and `.bpp` with no key — each refused with § Mechanism's message
- [ ] prelude (270): fixture with `prelude.bp` — markup-only `.bpp` compiles; module and emitted
      code import only used items; header name beats prelude's; `prelude.bp` holding a `fn`, another
      package's item or an activation refused at its line. The scope (`compiler-core`: last scope, import-item list) is
      `01-compiler/01-checker`'s, handed by this front
- [ ] `grep -riE 'rakun|jhonstart|erika|emilia|onze'` over `modules/compiler-core/src` and the
      edited `compiler-cli` files is empty

### Step 3 — The extension in every tool's list

- [ ] every § Mechanism site reads one shared list instead of spelling `.bp`
- [ ] `botopink build`, `check`, `run`, `test` over a `.bpp` project; test runner discovers a
      `test` declared in a header
- [ ] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

### Step 4 — The span mapping and the editor

- [ ] header-line type error and a `failAt` in the markup reported at their `.bpp` line and
      column by `botopink check` and the language server
- [ ] hover, go-to-definition in the header; default function's overlay served as the markup's
      tokens — the extension ships no grammar of the file
- [ ] `vscode-extension`: `.bpp` registered; `zig build test-vscode` green

### Step 5 — The formatter

- [ ] `botopink format` rewrites a badly indented header as a module, leaves every byte of the style
      section and the markup unchanged; `format --check` fails on the header, passes the style
      section and the markup
- [ ] `scripts/format-check.sh` walks `.bpp` files — header under the gate's format stage like any `.bp`

### Step 6 — A project of `.bpp` files (a page reads its route by hook: 293)

- [ ] this front's `examples/` and every track front's `examples/src/` compile as an onze test
      project whose `botopink.json` carries `"bpp": {"default": "jhonstart"}`
- [ ] `119-bpp-styling/examples/src/components/` (`Box.bpp`, `Post.bpp`, which carry style
      sections) compile with `"bpp": {"default": "jhonstart", "style": "jhonstart-styled"}` — once
      119 step 2 has landed
- [ ] so do other tracks' `.bpp` forms: `05-jhonstart/{26-jhonstart-router, 27-jhonstart-link,
      67-jhonstart-forms}/examples/src/` and `07-onze/53-onze-example-app/examples/{app,
      components}/` — `07-onze/53`'s blog, every markup-holding app file kind
- [ ] `examples/PostCard.bpp` unfolds to what `examples/PostCard-desugared-example.bp` spells;
      both render the same markup on both targets

## Decisions

Open, raised by step 1 (`decisions-pending.md` § 08-bpp): `116-a` (the prelude module's own
`import {bpp} from "std"` — blocks step 2's prelude box), `116-b ★` (roles checked with no `.bpp`
file — built as (a)), `116-c ★` (a decorator on a module `var` — refused, built as (a)).

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents `.bpp`, every fence compiled by `zig build test-docs`

## Blast radius

- **Extension sites in four tools become one list.** A missed site silently ignores `.bpp` — hence step 3.
- **New manifest key, an object.** `botopink.json` ignores unknown keys (`AGENTS.md` § Manifest): an
  older toolchain reads `"bpp"`, then fails on the first `.bpp` with "no such module".
- **compiler-core gains only the prelude scope** (01-checker's). No template member, no backend
  change, no snapshot directory: the unfold yields a module all four backends compile.
- **Formatter and `00-gate/112`.** `format --check` is a hard gate; a `.bpp` header is under it, the style section and the markup are not.

## Notes

- **App names the packages**: no rule needed for two libraries claiming one file kind.
- **Not a syntax**: neither a compiler-owned fence nor a library writing the module; the header is
  botopink, the style section and the markup are literals handed to the two default functions.
- **Still to be stated**, before the step named: (1) page parameter — answered by 293 (hooks, no parameter) — `117-bpp-routing`
  step 1; (2) return type — decision 275; (3) header statements other than `val` / `use` — step 0's list;
  (4) `Node`: track examples write `children: Children = []`, declared by no jhonstart module
  (`element.bp`, `elements.bp` use it; checker knows it by name); per 223, 118 declares `Node`, its
  prelude imports it, examples' `Children` → `Node` — `118-bpp-components` step 6 boxes; (5) app-file
  kind not a function name: answered by 289 — the default function is anonymous.
