# Front 129 — import-without-from

**Priority:** high — decision 206: with the bundled `log` and `http` present, an import that named a
module of its own package with `from` started meaning the bundled package of the same name.
**Depends on:** the integration tip that carries the bundled `log` / `http` packages and the
checker's shorthand-import rule (`import {x};` resolves only among the importing package's own
modules, decision 170).
**Owns:** `modules/compiler-cli/src/cli/{resolver,sources}.zig` (the refusal) ·
`modules/compiler-core/src/{ast,comptime}.zig`, `comptime/{env,diagnostics}.zig` (the package
scope and the owner rewrite) · `codegen/commonJS.zig` (`collectClassNames` / `collectDeclIndexes`) ·
`scripts/codemod-import-without-from.py` · `docs.md` § Imports · the three cells below · the
migration of every tree in the seven repositories.
**Does not touch:** the formatter (`format.zig`), the language server's project graph, the backends'
`crossModule.pick`.

---

## Rule

`import {…} from "<name>"` resolves only to a **package** — std, a bundled package (`routing`,
`http`, `actions`, `validation`, `log`) or a declared dependency. A module of the importing package
is imported by its path inside the braces, with no `from`:

```botopink
import {log.levelName as ownLevel};    // the package's module `log`
import {Level, levelName} from "log";  // the bundled package `log`
import {components.card.Card};
import {reliability.policy.nextDelay as policyDelay};
```

`from "<a module of this package>"` is refused at the source string, the brace form written as the
fix:

```text
error[module-import-with-from]: "geometry" is a module of this package — write import {geometry.area, geometry.perimeter as around};
 --> src/main.bp:7:41
```

A package wins its name: `from "log"` in a package that has a module `log` is the bundled `log`, so
a bundled package added later never changes what an existing import means.

## Mechanism

| Where | What |
|---|---|
| `compiler-cli/src/cli/resolver.zig` `checkImportSources` (F4) | a source whose first segment is bundled or a declared dependency passes; one whose path is a module of the package is `ModuleImportWithFrom` (`Diagnostic.fix` = `braceForm`: every leaf behind the module's dotted path, the spelling `botopink format` prints); anything else stays `UnresolvedImportSource`. `sources.zig` renders it `error[module-import-with-from]` with an excerpt and a caret on the string. |
| `resolver.zig` `importOwner`, `checkImportResolution`, `orderPackageModules` | a `from` import draws no dependency edge to a module of the package and is not export-checked against one (`has_from`); a dependency naming its own sibling by its package name (`from "<pkg>.a"`) is still a sibling edge. |
| `compiler-core/src/comptime.zig` `packageScope` / `outOfScope` (+ `ast.ImportSource.packageName` / `ofPackage`) | once the program holds modules of `<pkg>` (`<pkg>/…`), a `from "<pkg>"` lookup admits only those — in the owner, ambiguity, value, type, namespace and extension scans of `resolveImports` and in `addImportedTypeScope`. No such module (a bundled library's own tests) reads as before. |
| `comptime.zig` `withImportSourcesNamed`, `Env.itemOwners` | an item whose name another module the backends would also read declares (a bundled module beside a shorthand — decision 170 —, a module of the package beside `from "<pkg>"`, a package beside a module path) is written `from "<the module it resolved to>"`, reduced to its leaf, in the transformed program; the backends' name-keyed `crossModule.pick` then reads the checker's answer. |
| `codegen/commonJS.zig` | an imported record (built with `new`) or enum is found by the item's leaf in the module its path names (`leafSource`), so `import {parser.Outcome};` narrows as `from "parser"` did. |

The refusal lives in the CLI resolver because it is the one stage that knows which modules are the
package's; `compiler-core` sees a flat module list (`comptime.module_import_with_from` exports the
code).

## Cells

- `tests/language/modules/import_own_module_with_from` — the refusal, `<target>.expect` on all
  four targets (compiled and ran on the parent binary).
- `tests/language/modules/import_bundled_package_beside_own_module` — `from "log"` reaches the
  bundled `log` beside a module `log`; commonJS, erlang, beam (wasm excluded: `log` has no wasm
  host binding).
- `tests/language/modules/import_module_path_in_braces` — nested paths and an alias, four targets.
- `resolver.zig` unit tests: the refusal's location and fix text (one leaf, several, a nested path,
  an alias, an activation and a group), a package winning its name, no edge / no export check.

## Migration

`scripts/codemod-import-without-from.py [--write] [--format <botopink>] <root>…` (contract in
`repository/botopink-lang/scripts/AGENTS.md`). Measured over the seven repositories: 1 166
imports in 477 files — botopink-lang 166 / 106, rakun 707 / 262, onze 128 / 57, jhonstart 135 /
46, emilia 30 / 6, erika 0. No file changed canonical state under `botopink format --check`
(the non-canonical sets of rakun 285, onze 85, jhonstart 54, emilia 26 files are the ones at the
tip, byte for byte as lists). Seven imports the codemod reports UNDECIDED were edited by hand:
five named a decorator-emitted name (`__jhClient_*`, `__rkQuery_*`, `__rkMake_*` — one of them in
rakun-cache's `test/fixtures/twin`, a `*.bp.fixture` project the codemod reads), two named a module
that does not declare the item (`registerRoute` is `route_handler`'s, the middleware names are
`middleware`'s — the old `from` reached them through the whole program). onze's `build_test`
fixture strings (`app.card`, `app.widget`, `styles.app_home`) were edited by hand too. Generators that write an import of a
module of the package were changed by hand too: `rakun-cli`'s `inspectSource`, onze's
`routesModule`, `serverMainSource`, the bundler's client entry, the alias staging
(`rewriteImports` stages `from "@/lib.x"` as `import {lib.x.…};`) and the bundler graph (a dotted
item is an edge to the module its path names).

## Gate

- [ ] `zig build`, `zig fmt --check modules`, `scripts/format-check.sh`, cold `zig build test`
- [ ] `tests/language/run.sh --target all`; `botopink test` in `libs/{std,routing,actions,
      validation,log,http}` on commonJS and erlang; `zig build test-docs`, `zig build test-cli`
- [ ] each library's pre-commit hook, `BOTOPINK_BIN` = this worktree's compiler

## Remaining

- The language server runs no import-source check (F4 or this refusal): an editor shows
  `from "<own module>"` as resolving until `botopink check` refuses it.
- `docs.md` § Imports says "there is no formatter rule that converts one into the other" (dot and
  group); `botopink format` flattens a group into dotted leaves. The codemod and the fix-it write
  the formatter's spelling.
- `from "<own package name>"` inside the package itself (a bundled library's own tests: `log` 1,
  `routing` 1, `validation` 2, `std` 8 files) still reads the package's own modules.
- onze's `@/` alias now stages to the brace form; whether the alias stays a user spelling once the
  brace form names a module by its path from the package root is onze's question.
