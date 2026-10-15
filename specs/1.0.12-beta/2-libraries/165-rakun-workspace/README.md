# Front 165 — rakun-workspace: one `rakun` repository, a workspace of 17 plug-and-play packages

**Priority:** high (decision 433's tier of the libraries) — opens now (the maintainer, 2026-10-14), ahead of every open
step of 148, 149, 150, 153, 154 and 162, which pause until s1 lands; the threads open in those repositories land
first. **Repository:** rakun, erika, emilia, styled, jhonstart, onze, dbcontext, botopink-lang (s4), the meta (s8) —
a full worktree; each step one commit per repository (rule 10). **Model:** sonnet for s1, s3, s5; haiku for s2 (the
rename, the gate its oracle); opus for s4 and s7. **Gate:** standard (fronts.md § Gate); every step lands with rakun's
gate green, and s7 with its conformance whole. **Decision:** mono-a (awaiting its number); amends 326, 338, 391, 398,
433. **Depends on:** nothing open; s4 is 144 B-86.

## Alias table

| Old id | Step here |
|---|---|
| (new front; the six library fronts' open steps are refiled by s8, each with its own alias row) | — |

## The result

`botopink/rakun` is a botopink workspace (512): one directory per package under `modules/`, the package's name the
directory's name, each with its own `botopink.json` (name, `targets`, declared dependencies), `src/`, tests, `AGENTS.md`;
the cells under `conformance/<package>/`; one version, one tag, one release; one gate, one hook, one CI. A package
depends on packages of lower layers only (the compiler refuses a cycle); `src/internal/` is private (B-55-a).

| Package | Absorbs (today's modules) | Depends on |
|---|---|---|
| `rakun` | `rakun` | `validation` |
| `rakun-data` | `dbcontext`, `rakun-data` | `rakun`, `query` |
| `rakun-restclient` | `rakun-client` | `rakun`, `http` |
| `rakun-style` | `styled` | `css` |
| `rakun-bpp` | `jhonstart`, `jhonstart-html`, `jhonstart-link`, `jhonstart-forms`, `jhonstart-test`, `jhonstart-dom-test` | `rakun-style`, `actions`, `routing` |
| `rakun-stylesheet` | `emilia`, `emilia-test`, `jhonstart-emilia` | `rakun-bpp` |
| `rakun-service` | `rakun-web`, `rakun-actuator` | `rakun`, `routing` |
| `rakun-scheduling` | `rakun-scheduling` | `rakun-service`, `rakun-data` |
| `rakun-session` | `rakun-session` | `rakun-service`, `rakun-data`, `rakun-scheduling` |
| `rakun-cache` | `rakun-cache` | `rakun-service`, `rakun-session` |
| `rakun-security` | `rakun-security` | `rakun-service`, `rakun-session`, `rakun-data`, `rakun-restclient` |
| `rakun-websocket` | `rakun-websocket` | `rakun-service`, `rakun-security`, `rakun-data` |
| `rakun-metrics` | `rakun-metrics` | `rakun-service`, `rakun-restclient` |
| `rakun-messaging` | `rakun-messaging` | `rakun-service`, `rakun-metrics`, `rakun-restclient`, `rakun-data` |
| `rakun-mail` | `rakun-mail` | `rakun-service`, `rakun-data` |
| `rakun-app` | `rakun-app` | `rakun-service`, `rakun-cache`, `actions`, `routing` |
| `rakun-ssr` | `onze`, `onze-cli`, `onze-server`, `onze-bundler`, `onze-assets`, `onze-content`, `onze-og`, `onze-release`, `onze-test` | `rakun-app`, `rakun-bpp`, `rakun-stylesheet`, `markdown`, `snap` |

Outside, as external dependencies: `query` (erika renamed, a pure typed-query DSL depending on nothing of rakun —
front 145 continues as `query`), `css`, `actions`, `routing`, `validation`, `snap`, `markdown`, `http`, `log`, `json`,
`yaml`. The `rakun-starter-*` go (a starter was a combination of thin packages; `examples/` shows the combinations); each
`*-test` module becomes its package's `testing/` module (`import {testing.Client} from "rakun-service"`).

**Plug-and-play.** Adding a package to `botopink.json` is all a program does. Each package declares what it contributes
at its root, `#[rakun.module] pub fn service() -> Module`, and `rakun.boot()` in the program's `main` discovers every
module of the program's dependencies through the catalogue (`@TypeInfo.all(with: rakun.module)`), orders them by the
declared layers and starts them; a module carries its defaults and reads the program's overrides from a
`#[rakun.config]` record (a typed config: a wrong field is a build error). Everything resolves at build: two packages
contributing one thing (two HTTP servers) is a build error naming both; a package another requires and the program
lacks is a build error naming it; removing the dependency removes the module; no run-time discovery, no reflection.

## Steps

### s1 — the six repositories joined, history kept, names unchanged

**Repository:** rakun (and the six, read) · **Model:** sonnet

- [x] after every open thread of 148, 149, 150, 153, 154, 162 has landed: `git subtree add --prefix=modules/<name>`
      of erika, dbcontext, emilia, styled, jhonstart and onze into rakun (each repository's history kept, as 326 kept
      the libraries'); each one's `modules/*` lifted to rakun's `modules/`, its `examples/` and `conformance/` into
      the per-package folders; the workspace `botopink.json` lists every member
- [x] rakun's gate green with every package under its old name — nothing renamed in this step
- [x] `AGENTS.md` of rakun: the workspace, the layers, the per-package rule; one `AGENTS.md` per package
- [x] the shared runner (`scripts/git-hooks/lib/runner-standalone.sh`) walks `examples/<package>/<name>/` and
      `refusals/<package>/<name>/` and finds cells anywhere under `conformance/`, one text in every library's `feat`
- The meta repository's pointers of rakun and the libraries move at s8, with the six submodules removed: a checkout
  holding rakun past s1 beside the six repositories sees each joined package twice (`"styled" is declared by two
  libraries`), and the runner is one text only across the new `feat`s
- Open, not this step's: `conformance/rakun/{cors,filter_chain,middleware,problem_details,response_headers,web_tls}` red
  on `feat` through their per-cell `deps/` (150 s27); every `conformance/emilia/` cell refused on beam (144 B-89);
  dbcontext holds no package yet (its notes at `modules/dbcontext/AGENTS.md`, not a member; s3); question 165-a

### s2 — the rename, by codemod

**Repository:** rakun · **Model:** haiku (the gate is the oracle)

- [x] directories and `name` in every `botopink.json` per the table; the `jhonstart-*`, `onze-*`, `emilia`, `styled`
      packages folded into their new package as modules (`rakun-bpp/src/html/`, `rakun-ssr/src/cli/`, …); erika
      stays out (s6)
- [x] a codemod over every `.bp`, `.bpp`, example and test: `from "jhonstart"` → `from "rakun-bpp"` and the rest of
      the table; `onze.json` → `rakun-ssr.json`, `onze create-key` → `rakun-ssr create-key`, `ONZE_KEY` →
      `RAKUN_SSR_KEY`; the `*-test` packages become `testing/` modules; the `rakun-starter-*` removed
- [x] `rakun-ssr create` writes workspace dependencies or the `botopink/rakun` git source, never an archived
      repository's; its `--libs` help text says a rakun checkout
- [x] rakun's gate green; no import of a package that no longer exists (the build refuses one)
- Open: `onze-server`, `jhonstart-dom-test` and `rakun-cli` stay packages of their own (question 165-b); the five
  `MdNode` patterns of `rakun-ssr/src/content/element.bp` write their labels out until 144 B-93

### s3 — dbcontext folded into `rakun-data`

**Repository:** rakun · **Model:** sonnet

- [x] dbcontext's modules moved into `rakun-data/src/` (`entity/`, `context/`, `repository/`), the imports of
      `dbcontext` → `rakun-data`, one root; `rakun-data` declares `query`
- [x] rakun's gate green; the cells of both under `conformance/rakun-data/`

### s4 — the compiler: the lib-agnostic gate, the catalogue across packages (144 B-86)

**Repository:** botopink-lang (`--lang`) · **Model:** opus

- [x] the lib-agnostic gate of `zig build test` refuses `rakun|query` in `compiler-core/src` (was `rakun|jhonstart|erika`)
- [x] `@TypeInfo.all` reaches the declarations of the program's dependencies: a dependency's analysis exports its
      catalogue, level B (B-60) stores it with the entry, the program's catalogue is the union — the mechanism
      `rakun.boot()` discovers modules with; a cell: a dependency's `#[m]`-annotated declaration listed by the program
- [x] the reference: § Decorators, the catalogue's reach
- Open: question B-86-a (the gate's spelling of `query`; a dependency's `module` path and the transitive reach)

### s5 — plug-and-play: `rakun.module`, `rakun.boot()`, `rakun.config`

**Repository:** rakun · **Model:** sonnet (the design is this README's) · **After:** s4, 144 B-98, B-99 (the language gap: a library call reading the caller's catalogue, `language-gaps.md`); `boot_modules` on beam after B-97

- [ ] `rakun`: the `Module` record, the `#[rakun.module]` decorator, `rakun.boot()` (discovery by the catalogue, the
      layer order, the start), `#[rakun.config]` and the typed overrides; the two build errors (one thing contributed
      twice; a required package absent), each a cell
- [ ] every package declares its module at its root with its defaults; `examples/` of a program that adds one package
      at a time; the gate green

### s6 — erika renamed `query`, outside rakun

**Repository:** erika · **Model:** haiku

- [x] the repository renamed `botopink/query` (the meta's `.gitmodules` names it), the package `query` and `query-test`,
      its imports, examples, refusals and cells; its gate green
- [x] rakun: `modules/erika` and `modules/erika-test` (joined by s1) removed, `rakun-data` and every example declaring
      `query` as an external dependency, the imports `from "query"`; rakun's gate green · after s3
- [x] front 145 renamed 145 query

### s7 — Conformance, the front's last step (decisions 465, 477, 478, 479, 480)

**Repository:** rakun · **Model:** opus

- [ ] `feat`'s pipeline runs `botopink cell check conformance/` over the whole `rakun/conformance/` green; every red
      reproduced locally and fixed at once (430); for each, the cheap test the hook runs that would have caught it
      (478); the reference (`docs.md` beside each cell) updated (480)

### s8 — the specs and the meta

**Repository:** the meta · **Model:** sonnet

- [x] the open steps of 148 styled, 149 jhonstart, 153 dbcontext, 154 emilia and 162 onze refiled under 150 rakun,
      one section per former front with its alias table, their context folders moved into `2-libraries/150-rakun/`;
      145 erika renamed 145 query
- [x] every library's pointer and rakun's moved to its `feat` in the same commit that removes the six submodules, with 144 B-100 (botopink-lang's tooling reading the libraries at their new homes)
- [x] `fronts.md` (ownership: one row for rakun with lanes by layer — data, style/bpp/stylesheet, service and its
      optionals, app/ssr — a lane never editing another's `modules/`; conflicts), `status.md`, `language-gaps.md`
      (owners), `README.md` (the high tier from 18 to 13 fronts), `AGENTS.md` § Layout and CI check 4 (12 library
      repositories), `language-gap-markers.sh`, `decisions-split.py` (one `decisions-taken.md` for rakun, the six
      former repositories' rows mapped to it through the alias tables); the six submodules removed
- [ ] the five former GitHub repositories (emilia, styled, jhonstart, onze, dbcontext) archived with a README naming
      `rakun/modules/<new name>` — the maintainer's (erika is `botopink/query`)

**Impacted:** every library's `test-libs` row (six rows become one workspace of 17 members), the vscode-extension's
library list if it names repositories, the meta CI.
