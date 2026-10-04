# Front 116 — bpp file format: a `.bpp` file is another spelling of a `.bp` module

**Priority:** medium — changes how a page looks, not what it can do; every feature is reachable
from a `.bp` module (118). · **State:** not started
**Depends on:** `118-bpp-components` (the literal's template language) · `05-jhonstart/26` step 0
(merges `jhonstart-html` into the core, `html` its default function, decision 200) ·
`01-compiler/26-cli-tooling` (owns `compiler-cli/**`, `language-server/**` this milestone; 116
opens after it) · `01-compiler`'s prelude scope (decision 270) · open: `bpp-g`
(step 6). Written against decisions 198, 199, 200, 212, 213, 221, 270.
**Owns:** in `repository/botopink-lang`: `modules/manifest/src/root.zig` (one key),
`modules/compiler-cli/src/cli/{scanner,resolver,libs,format_cmd,migrate}.zig` (extension lists,
unfold, formatter's view), `modules/lib-test-runner/src/discovery.zig`,
`modules/language-server/src/{project_index,project_graph,engine}.zig` (extension lists, span
mapping), `docs.md` § Modules, `tests/language/modules/bpp_*` · in `repository/vscode-extension`:
`package.json`, `src/extension.ts`, `src/testExplorer.ts` (registration)
**Does not touch:** any `codegen/*.zig`, `parser/*.zig`, `lexer.zig` (no new syntax) ·
`modules/compiler-core/src/comptime.zig`, `comptime/infer.zig` (no `template.emit` /
`template.slice`, decision 198) · the prelude scope in `compiler-core` (`01-compiler/01-checker`'s;
this front hands it the list) · `repository/jhonstart/**` (default function: `05-jhonstart/26`'s
and 118's; `prelude.bp`: 118's).

Reference: `astro-docs/09-astro-components.md` § Estrutura do Componente.

## Goal

A `.bp` component (after 118: `import html, {Element} from "jhonstart";` + `pub default fn
PostCard(props: Props) -> Element { val kind = …; return html """<article …>…</article>"""; }`)
written as `components/PostCard.bpp`, dropping the template import, function header and
`return html """` (full pair: `examples/PostCard.bpp`, `examples/PostCard-desugared-example.bp`):

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

Read by every tool (build, check, run, test, format, language server, editor); the compiler learns
no library and no syntax.

## Mechanism

**The application names the package** (198): `botopink.json` key, value = one dependency's name;
the toolchain uses its `pub default fn` (for jhonstart `html`, `import html from "jhonstart";`, 200).

```json
{ "name": "notes", "dependencies": { "jhonstart": { … }, "onze": { … } }, "bpp": "jhonstart" }
```

**The unfold** (198, 199, 212, 213). Header/literal split per 212; bad first line or unclosed
header: `error: a .bpp header opens with --- on the first line and closes with a second ---` at
that line. Always the module's `pub default fn`, named after the file, never `pub val`:

| The header | The module of `components/PostCard.bpp` |
|---|---|
| declares `type Props(…)` | the header's declarations, then `pub default fn PostCard(props: Props) -> R { <the header's statements> return html """<the markup>"""; }` |
| declares no `Props` | the header's declarations, then `pub default fn PostCard() -> R { <the header's statements> return html """<the markup>"""; }` |

- `import {components.PostCard};` binds it without alias; another file name needs one
  (`import {components.post_card as PostCard};`). No case conversion; a non-function file name is an
  error at the file. `R` (decision 275) is the `R` of the default function's declared
  `@ExprCustom<R>` — the toolchain reads it from the signature and names no library; for jhonstart
  it is `View` (= `@Component<ElementBase, Element>`, decision 276), whether or not the header uses `use` / `await`.
- Declarations (`import`, `type`, `pub`) module-level; statements (`val`, `use`) body ahead of
  `return` (may read `props`, call a hook). Attributes = `Props` fields (192); children via
  `children` (193). Header imports in the language's form (`import {components.card.Card};`,
  `import {x} from "pkg";`); no relative import.

**What the toolchain knows** (285): the package named by `"bpp"`, its `pub default fn` (`html`, the
unfold target) and its prelude (270) — nothing else. A file's role (page, layout, …) is the
framework's: the route table `rakun-app` generates from `routing`'s file kinds (`04-rakun/22`) calls
jhonstart's `page` / `layout` on the unfolded function; the toolchain applies no decorator by file
name and reads no `bppKinds`. A decorator written on the line before the closing `---` is ordinary
header code annotating the function (221 (1)).
`route: PageContext` and `params`: `bpp-g`.

**Nothing added to a template body.** The header is the module-level half; no function emits
declarations or keeps an origin. The literal *is* the file: a literal span is a file span,
`template.failAt` underlines the file, the default function's `CustomNode` overlay is the file's
tokens, hover, go-to-definition. Header is copied, so the unfold maps module positions back; a
header type error reports at its own line and column.

**The package's prelude** (270). Module `prelude` (`src/prelude.bp`, listed in `files`) gives a `.bpp` what it imports (`Element`, the builders its tags name): `import` items of the
package's own modules only (no other package — decision 242; no activation `X*`; alias allowed),
compiled and tested with the package; no manifest key names/overrides it. Handed to
`compiler-core` as the module's last scope (generic import-item list, no library); an item becomes
an import only when a file name resolves through it. A file that is only `<article></article>` is
`import html from "jhonstart"; import {element.Element, elements.article} from "jhonstart";
pub default fn Card() -> Element { … }`, emitted code likewise. **Header wins** by scope order; a
tag then resolving to a header declaration that is not a builder fails at the tag, naming the
header line. Header binding the default function's name: error at the line. No prelude: only the
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

**Formatter.** `botopink format` formats the header as a module, leaves the markup byte-identical;
`format --check` checks the header, passes the markup.

**Refusals (compile time).** `.bpp` with no `bpp` key: error at the file, naming the key. `bpp`
naming a non-dependency, or a package with no `pub default fn` taking `comptime _: @Expr<string>`:
error at the key. `X.bp` + `X.bpp` in one directory: error naming both.

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

### Step 1 — `bpp` in the manifest model

- [ ] `modules/manifest`: key parsed and validated — a string naming a dependency
- [ ] unit tests: not a string, non-dependency, package with no `pub default fn` over
      `@Expr<string>`, key on a project with no `.bpp` (accepted), `.bpp` with no key

### Step 2 — The unfold

- [ ] the return type is read from the default function's signature (decision 275): the fixture
      package's `@ExprCustom<i32>` gives `-> i32`; jhonstart's gives `-> @Component<ElementBase,
      Element>` for a header with and without `use` / `await`; the toolchain spells no type name
- [ ] `tests/language/modules/bpp_*`: fixture package whose default function is **not**
      jhonstart's (answers the literal's length) — `.bpp` with `type Props` unfolds to
      `pub default fn <Name>(props: Props)`, without to `pub default fn <Name>()`, no header = all
      literal; fixture served unchanged (proof the toolchain knows no library)
- [ ] header between two `---` (212): non-`---` first line in a file containing one, and an
      unclosed header, each refused at the line
- [ ] function named after the file, imported by path without alias (213); non-function file name
      refused at the file
- [ ] declarations at module level, statements in the body in order; a statement reads `props`
- [ ] a decorator before the closing `---` annotates the function (221 (1)); without one the
      function carries none — no decorator from the file name, no `bppKinds` read (285)
- [ ] `X.bp` beside `X.bpp`, and `.bpp` with no key — each refused with § Mechanism's message
- [ ] prelude (270): fixture with `prelude.bp` — markup-only `.bpp` compiles; module and emitted
      code import only used items; header name beats prelude's; `prelude.bp` holding a `fn`, another
      package's item or an activation refused at its line; header binding the default function's
      name refused at its line. The scope (`compiler-core`: last scope, import-item list) is
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

- [ ] `botopink format` rewrites a badly indented header, leaves every byte after the second `---`
      line; `format --check` fails on the first, passes the second
- [ ] `scripts/format-check.sh` walks `.bpp` files — header under the gate's format stage like any `.bp`

### Step 6 — A project of `.bpp` files (a page's parameter waits on `bpp-g`)

- [ ] this front's `examples/` and every track front's `examples/src/` compile as an onze test
      project whose `botopink.json` carries `"bpp": "jhonstart"`
- [ ] so do other tracks' `.bpp` forms: `05-jhonstart/{26-jhonstart-router, 27-jhonstart-link,
      67-jhonstart-forms}/examples/src/` and `07-onze/53-onze-example-app/examples/{app,
      components}/` — `07-onze/53`'s blog, every markup-holding app file kind
- [ ] `examples/PostCard.bpp` unfolds to what `examples/PostCard-desugared-example.bp` spells;
      both render the same markup on both targets

## Decisions

- `bpp-g` — how a `page.bpp` gets `route: PageContext` and `params` (221 gives only the decorator).
  Step 6, and 117 step 1.

**Gate:** standard (fronts.md § Gate), in `repository/botopink-lang` and `repository/vscode-extension`, plus:
- [ ] `zig build test-libs`: every library green — no existing `.bp` file changes meaning
- [ ] `docs.md` § Modules documents `.bpp`, every fence compiled by `zig build test-docs`

## Blast radius

- **Extension sites in four tools become one list.** A missed site silently ignores `.bpp` — hence step 3.
- **New manifest key.** `botopink.json` ignores unknown keys (`AGENTS.md` § Manifest): an older
  toolchain reads it, then fails on the first `.bpp` with "no such module".
- **compiler-core gains only the prelude scope** (01-checker's). No template member, no backend
  change, no snapshot directory: the unfold yields a module all four backends compile.
- **Formatter and `00-gate/112`.** `format --check` is a hard gate; a `.bpp` header is under it, markup is not.

## Notes

- **App names the package**: no rule needed for two libraries claiming one file kind.
- **Not a syntax**: neither a compiler-owned fence nor a library writing the module; header is botopink, rest is literal.
- **Still to be stated**, before the step named: (1) page parameter, `bpp-g` — step 6, `117-bpp-routing`
  step 1; (2) return type — decision 275; (3) header statements other than `val` / `use` — step 0's list;
  (4) `Node`: track examples write `children: Children = []`, declared by no jhonstart module
  (`element.bp`, `elements.bp` use it; checker knows it by name); per 223, 118 declares `Node`, its
  prelude imports it, examples' `Children` → `Node` — `118-bpp-components` step 6 boxes; (5) app-file
  kind not a function name: 213 refuses it, 221 maps kinds by file name, `not-found.bpp`
  (`124-bpp-cli/examples/scaffold/app/`) is one — `ctr-t`, step 2.
