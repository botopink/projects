# Front 129 — import-without-from: `from` names a package, never a module of the importing package

**Priority:** high · **State:** done (on feat in botopink-lang and the four libraries)

## Goal

Decision 206: `import {…} from "<name>"` resolves only to a package — std, a bundled package or a
declared dependency; a module of the importing package is imported by its path in braces
(`import {log.levelName as ownLevel};`), and `from "<a module of this package>"` is
`error[module-import-with-from]` at the source string with the brace form as its fix. A bundled
package added later never changes what an import means.

## Done

- The refusal (`compiler-cli/src/cli/resolver.zig` `checkImportSources`), the package scope
  (`comptime.zig` `packageScope` / `outOfScope`), the owner rewrite (`withImportSourcesNamed`) and
  commonJS's `leafSource` — cells `modules/import_own_module_with_from`,
  `modules/import_bundled_package_beside_own_module`, `modules/import_module_path_in_braces`
- `scripts/codemod-import-without-from.py` and the migration of every tree: botopink-lang, rakun,
  onze, jhonstart, emilia (erika had no such import)

The four residuals moved to their owners: the language server's import-source check and a package
importing itself by its own name → [`26-cli-tooling`](../26-cli-tooling/README.md) step 8; the
`docs.md` § Imports sentence → [`07-residuals`](../07-residuals/README.md) step 7; whether onze's
`@/` alias stays a user spelling → the onze track (`07-onze`).
