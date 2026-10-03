# Front 116 — bpp file format: a `.bpp` file is another spelling of a `.bp` module

**Priority:** medium — it changes how a page looks, not what a page can do; every feature of the
track is reachable from a `.bp` module (118). · **State:** not started
**Depends on:** `118-bpp-components` (the template language the literal is written in) ·
`05-jhonstart/26` step 0 (it merges `jhonstart-html` into the core and makes `html` its default
function, decision 200) · `01-compiler/26-cli-tooling` (it owns `compiler-cli/**` and
`language-server/**` this milestone; 116 opens after it) · `01-compiler`'s prelude scope
(decision 266: a module's last scope, a list of import items, imported only when used) · open:
`bpp-f` (step 2), `bpp-g` (step 6). Written against decisions 198, 199, 200, 212, 213, 221, 266.
**Owns:** in `repository/botopink-lang`: `modules/manifest/src/root.zig` (one key),
`modules/compiler-cli/src/cli/{scanner,resolver,libs,format_cmd,migrate}.zig` (the extension
lists, the unfold, the formatter's view of the file), `modules/lib-test-runner/src/discovery.zig`,
`modules/language-server/src/{project_index,project_graph,engine}.zig` (the extension lists, the
span mapping), `docs.md` § Modules, `tests/language/modules/bpp_*` · in
`repository/vscode-extension`: `package.json`, `src/extension.ts`, `src/testExplorer.ts` (the
registration)
**Does not touch:** any `codegen/*.zig`, `parser/*.zig` or `lexer.zig` — the toolchain learns no
syntax · `modules/compiler-core/src/comptime.zig` and `comptime/infer.zig` — a template body
gains nothing (no `template.emit` / `template.slice`, decision 198) · the prelude scope in
`compiler-core` (`01-compiler/01-checker`'s; this front hands it the list) ·
`repository/jhonstart/**` — the default function is `05-jhonstart/26`'s and 118's, the
`prelude.bp` 118's.

Reference: `astro-docs/09-astro-components.md` § Estrutura do Componente.

## Goal

A component written as a `.bp` module after 118 —

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

— can be written as `components/PostCard.bpp`, with the import of the template function, the
function header and the `return html """` left out:

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

Every tool — build, check, run, test, format, the language server, the editor — reads it, and the
compiler knows no library and no syntax it did not know before.

## Mechanism

**The application names the package** (decision 198). One key in its `botopink.json`:

```json
{ "name": "notes", "dependencies": { "jhonstart": { … }, "onze": { … } }, "bpp": "jhonstart" }
```

The value is the name of one dependency; the toolchain uses that package's `pub default fn`, a
template function, and names no library itself. For jhonstart it is `html`
(`import html from "jhonstart";`, decision 200).

**The toolchain unfolds the file onto that function** (decisions 198, 199, 212, 213). The header
sits between two `---` lines at the very start of the file and is ordinary botopink, copied into
the module as written; everything after the second `---` — or the whole file, when it has no
header — is the literal handed to the default function. A first line that is not `---` in a file
that contains one, or a header opened and never closed, is an error at that line
(`error: a .bpp header opens with --- on the first line and closes with a second ---`). The file
always unfolds to the module's `pub default fn`, named after the file, never to a `pub val`:

| The header | The module of `components/PostCard.bpp` |
|---|---|
| declares `type Props(…)` | the header's declarations, then `pub default fn PostCard(props: Props) -> Element { <the header's statements> return html """<the markup>"""; }` |
| declares no `Props` | the header's declarations, then `pub default fn PostCard() -> Element { <the header's statements> return html """<the markup>"""; }` |

`import {components.PostCard};` binds it with no alias; a file named otherwise is imported with
one (`import {components.post_card as PostCard};`). No case conversion happens anywhere; a file
name that is not a valid function name is an error located at the file. The return type
`-> Element` is question `bpp-f`.

The header's **declarations** — `import`, `type`, `pub` — stay at module level; its
**statements** — `val`, `use` — become the function's body ahead of the `return`, so they may read
`props` and call a hook. The attributes a caller writes are the fields of `Props` (decision 192)
and its children arrive through the `children` field (decision 193). An import in the header is
in the language's own form — `import {components.card.Card};` for a module of the same package,
`import {x} from "pkg";` for a package; there is no relative-path import.

**The decorator of an app file** (decision 221). The header may write a decorator on the line just
before its closing `---`; it annotates the unfolded function. When it writes none, the decorator
comes from the file's name, through the map the `bpp` package declares in its own `botopink.json`
(`"bppKinds": {"page": "page", "layout": "layout", "template": "template", …}`, read from
`routing`'s conventions, decision 171) — the toolchain applies what the manifest says and names no
library. A header decorator that differs from the file name's (`page.bpp` with `#[layout]`) is an
error at the header line; the same one is allowed and redundant. A page's `route: PageContext`
parameter and its `params` are question `bpp-g`.

**Nothing is added to a template body.** The module-level half of the file is the header, so no
function emits declarations and none keeps an origin. A diagnostic inside the markup lands on its
line of the `.bpp` because the literal *is* the file: a span of the literal is a span of the file,
`template.failAt` underlines the file, and the `CustomNode` overlay the default function returns
is the file's tokens, hover and go-to-definition in the editor. The header is copied, not rebuilt,
so the unfold maps a module position back to its `.bpp` position, and a type error in the header
is reported at its own line and column.

**The package's prelude** (decision 266). When the package the manifest names has a module
`prelude` (`src/prelude.bp`, listed in `files`), a `.bpp` file reaches what that module imports
without writing it — `Element`, the builders its tags name. The prelude holds `import` items of
the package's own modules only (no other package — decision 242; no activation `X*`; an alias is
allowed) and is compiled and tested with the package; no manifest key names or overrides it. It is
not pasted into the module: the unfold hands `compiler-core` the items as the module's last scope
— a generic list of import items naming no library — and an item becomes an import only when a
name of the file resolves through it. The module of a file that is only `<article></article>` is
`import html from "jhonstart"; import {element.Element, elements.article} from "jhonstart";
pub default fn Card() -> Element { … }` and nothing else; the emitted code imports the same. **The
header wins** by scope order: a name the header declares or imports never reaches the prelude; a
tag that then resolves to the header's declaration and is not a builder fails at the tag, naming
the header line. A header that binds the default function's name is an error at that line. With no
prelude, a `.bpp` file imports the default function only.

```bp
// jhonstart/modules/jhonstart/src/prelude.bp — written by 118
import {element.Element};
import {element: {text, fragment, div, span, p, h1, ul, li}};
import {elements: {article, h2, header, footer, main, title, timeTag as time}};
```

**The extension in every tool.** compiler-core takes `Module{path, source, declaration, srcPath}`
(`modules/compiler-core/src/module.zig`) and never reads an extension. The sites that spell `.bp`
read one shared list instead: `compiler-cli/src/cli/scanner.zig` (`EXTS`), `resolver.zig`
(`collectChildren`'s sibling lookup, `isSource`, `stripBpExt`), `libs.zig` (`stripSourceExt`),
`format_cmd.zig` (`EXTS`), `migrate.zig` (`isSource`, `stripBpExt`);
`lib-test-runner/src/discovery.zig` (`srcHasBpFile`, `isBpSource`);
`language-server/src/project_index.zig` (`scanDir`), `project_graph.zig` (`loadSrcTree`),
`engine.zig` (`findModuleFile`); the editor, `vscode-extension/package.json`
(`"extensions": [".bp"]`), `src/extension.ts`, `src/testExplorer.ts`. The CLI, the test runner and
the language server unfold the file the same way and hand compiler-core the same module, with
`srcPath` the `.bpp` path. `mod PostCard;` and `import {components.PostCard};` resolve
`PostCard.bp`, then `PostCard.bpp`, then `PostCard/mod.bp`. A bundled package still ships `.bp`
only (`build.zig`, decision 117 rule 8). The manifest (`modules/manifest/src/root.zig`, `parse`)
has no key that names a package for a file kind today.

**The formatter treats the header as botopink.** `botopink format` formats the header between the
two `---` lines as it formats a module and leaves the markup after it byte-identical;
`format --check` checks the header and passes the markup.

**Refusals, all at compile time.** A `.bpp` file in a project with no `bpp` key: an error at the
file, naming the key. A `bpp` that names a package the project does not depend on, or a package
with no `pub default fn` taking `comptime _: @Expr<string>`: an error at the key. `X.bp` and
`X.bpp` in one directory: an error naming both.

## Open

### Step 0 — Measure what the unfold stands on

- [ ] a `tests/language/modules/` cell: a package declaring `pub default fn` over
      `comptime template: @Expr<string>`, imported `import t from "<package>";` and called with a
      literal from a consumer, on every target the language suite runs
- [ ] the header rule of decision 199 run over every `.bpp` file under
      `specs/1.0.12-beta/*/*/examples/`: each header item is listed as a declaration (`import`,
      `type`, `pub`) or a statement (`val`, `use`), and every item the rule does not name — an
      `if`, an expression statement, a private `fn`, a `test`, a decorated declaration — is listed
      with the file it appears in
- [ ] a module assembled by hand the way the unfold assembles it: a type error on a header line
      and one inside the literal are each reported at the line a `.bpp` would have it

### Step 1 — `bpp` in the manifest model

- [ ] `modules/manifest`: the key parsed and validated — a string, the name of a dependency
- [ ] unit tests for the refusals: not a string, a package that is not a dependency, a package
      with no `pub default fn` over `@Expr<string>`, the key on a project with no `.bpp` file
      (accepted), a `.bpp` file with no key

### Step 2 — The unfold (the return type waits on `bpp-f`)

- [ ] `tests/language/modules/bpp_*`: a fixture package whose default function is **not**
      jhonstart's (it answers the literal's length) — a `.bpp` with `type Props` unfolds to
      `pub default fn <Name>(props: Props)`, one without to `pub default fn <Name>()`, one with no
      header is all literal; the toolchain serves the fixture unchanged, which is the proof that it
      knows no library
- [ ] the header between two `---` lines (decision 212): a first line that is not `---` in a file
      containing one, and a header never closed, are each refused at the line
- [ ] the function is named after the file and imported by its path with no alias (decision 213);
      a file name that is not a function name is refused at the file
- [ ] the header's declarations are at module level and its statements in the body, in order; a
      statement reads `props`
- [ ] the decorator (decision 221): one written before the closing `---` annotates the function;
      without one, the fixture package's `bppKinds` gives it from the file name; a header decorator
      that differs from the file name's is refused at the header line
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

### Step 3 — The extension in every tool's list

- [ ] every site of § Mechanism reads one shared list instead of spelling `.bp`
- [ ] `botopink build`, `check`, `run`, `test` over a project with `.bpp` files; the test runner
      discovers a `test` declared in a header
- [ ] `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp`

### Step 4 — The span mapping and the editor

- [ ] a type error on a header line and a `failAt` inside the markup are reported at their line
      and column of the `.bpp` file by `botopink check` and by the language server
- [ ] hover and go-to-definition work in the header; the overlay the default function returns is
      served as the tokens of the markup — the extension ships no grammar of the file
- [ ] `vscode-extension`: `.bpp` registered; `zig build test-vscode` green

### Step 5 — The formatter

- [ ] `botopink format` rewrites a badly indented header and leaves every byte after the second
      `---` line as it was; `format --check` fails on the first and passes the second
- [ ] `scripts/format-check.sh` walks `.bpp` files — the header is under the gate's format stage
      like any `.bp`

### Step 6 — A project of `.bpp` files (a page's parameter waits on `bpp-g`)

- [ ] `examples/` of this front, and the `examples/src/` tree of every front of the track,
      compile as a test project of onze whose `botopink.json` carries `"bpp": "jhonstart"`
- [ ] so do the `.bpp` forms of the other tracks' examples: `05-jhonstart/{26-jhonstart-router,
      27-jhonstart-link, 67-jhonstart-forms}/examples/src/` and
      `07-onze/53-onze-example-app/examples/{app, components}/` — the blog of `07-onze/53`, every
      app file kind that holds markup
- [ ] `examples/PostCard.bpp` unfolds to what `examples/PostCard-desugared-example.bp` spells,
      and the two render the same markup on both targets

## Decisions

- `bpp-f` — the return type of the unfolded function: `-> Element` is jhonstart's name, which the
  toolchain cannot spell (decision 113), and a header that `await`s or `use`s needs
  `-> @Component<ElementBase, Element>` today. Step 2.
- `bpp-g` — how a `page.bpp` gets its `route: PageContext` and its `params` (decision 221 gives it
  only the decorator). Step 6, and 117 step 1.

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents the `.bpp` spelling, every fence compiled by `zig build test-docs`

## Blast radius

- **The extension sites, in four tools, become one list.** A site missed is a tool that silently
  ignores `.bpp` files — step 3 runs every command over a `.bpp` project for that reason.
- **A new manifest key.** `botopink.json` ignores unknown keys today (`AGENTS.md` § Manifest), so
  an older toolchain reads a new manifest without error and then fails on the first `.bpp` file
  with "no such module".
- **compiler-core gains only the prelude scope** (01-checker's). No template member is added, no
  backend changes, no snapshot directory is touched: the unfold answers a module the four backends
  already compile.
- **The formatter and `00-gate/112`.** `format --check` is a hard gate over every source file; a
  `.bpp` file's header is under it, its markup is not.

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
     no type `Children` (`element.bp`, `elements.bp` use the name). 118 adds it, and the prelude
     imports it. Decision 223 names jhonstart's node type `Node` and says every spec and example
     writes `Node`; the examples have not followed.
