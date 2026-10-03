# Front 129 — import-without-from: `from` names a package, never a module of the importing package

**Priority:** high · **State:** done (on feat in botopink-lang and the four libraries)

## Goal

Decision 206: `import {…} from "<name>"` resolves only to a package (std, bundled, declared
dependency); an own module is imported by path in braces (`import {log.levelName as ownLevel};`);
`from "<a module of this package>"` = `error[module-import-with-from]` at the source string, brace
form as fix. A later bundled package never changes an import's meaning.

## Done

- Refusal (`compiler-cli/src/cli/resolver.zig` `checkImportSources`), package scope (`comptime.zig`
  `packageScope` / `outOfScope`), owner rewrite (`withImportSourcesNamed`), commonJS's `leafSource`
  — cells `modules/import_own_module_with_from`, `modules/import_bundled_package_beside_own_module`,
  `modules/import_module_path_in_braces`
- `scripts/codemod-import-without-from.py`, every tree migrated: botopink-lang, rakun, onze,
  jhonstart, emilia (erika had none)

Residuals moved: LSP import-source check and a package importing itself by name →
[`26-cli-tooling`](../26-cli-tooling/README.md) step 8; `docs.md` § Imports sentence →
[`07-residuals`](../07-residuals/README.md) step 7; onze's `@/` alias as user spelling → `07-onze`.
