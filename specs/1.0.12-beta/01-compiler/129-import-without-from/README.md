# Front 129 — import-without-from: `from` names a package, never a module of the importing package

**Priority:** high · **State:** partial — 206 done; reopened for decision 337 (steps 1–4)
**Owns (337):** the shorthand arms of `comptime.zig` `resolveImports` and `outsideShorthandReach` · the
`mod` declaration's namespace binding (`comptime.zig`, `comptime/infer.zig`, a carve-out of
`01-checker` named in the commit) · `compiler-cli/src/cli/resolver.zig`'s import checks · the cells
under `tests/language/modules/` it names · `docs.md` § Modules and § Imports · the migration commit in
each repository (a consumer commit under 188, never beside the owning front's open commit)

## Goal

Decision 206: `import {…} from "<name>"` resolves only to a package (std, bundled, declared
dependency); an own module is imported by path in braces (`import {log.levelName as ownLevel};`);
`from "<a module of this package>"` = `error[module-import-with-from]` at the source string, brace
form as fix. A later bundled package never changes an import's meaning.

Decision 337: an import always names where its names come from, and `mod` binds the module it
declares. The shorthand (`import {splitPath};`, no module path, no `from`) goes:

```bp
// src/main.bp
pub mod config;                // declares the module and binds the namespace `config`
import {config.splitPath};     // brings the name — the same in any module of the package
// or, with no import:
config.splitPath(x)

// src/mod1/mod.bp declares `pub mod mod2;` — the namespace walks the tree, no import:
pub mod mod1;
mod1.mod2.splitPath(x)
```

## Open (decision 337)

### Step 1 — `mod m;` binds `m`

- [ ] `mod config;` and `pub mod config;` bind `config` as a namespace in the declaring module, as
      `import {config};` does elsewhere: `config.splitPath(x)`, `config.Type`
- [ ] the namespace walks a folder module's tree with no import: `src/mod1/mod.bp` declares
      `pub mod mod2;`, and `mod mod1;` alone allows `mod1.mod2.splitPath(x)` (110's walk, as
      `io.fs.readText` after `import {io} from "std"`); every step a `pub mod`, the leaf `pub` — a plain
      `mod mod2;` is private to `mod1`'s subtree, so `mod1.mod2` from `main` is `private-module` at `mod2`
- [ ] a folder's `mod.bp` re-exports with a value, no syntax of its own: `mod mod2; pub val splitPath =
      mod2.splitPath;` and `import {mod1.splitPath};` elsewhere — today green on commonJS and erlang through
      `import {mod1.mod2.splitPath as sp}; pub val splitPath = sp;` (measured 9 Oct), red through the
      namespace (`unbound variable 'mod2'`)
- [ ] `import {mod1.mod2};` binds `mod2` in any module of the package (docs.md § Imports: "an item whose
      whole path names a module binds a namespace") — measured 9 Oct: `unbound variable 'mod2'` for a
      nested module of the package, while `import {config};` (a top-level one) binds
- [ ] in the declaring module `import {config};` is `redundant-module-import` at the item (fix: delete it);
      a top-level declaration named like a declared module is `import-name-collision`
- [ ] cells `modules/mod_binds_namespace`, `modules/mod_namespace_cascade`, `modules/mod_reexport_by_val`,
      `modules/import_nested_module_namespace` (four targets) and
      `reject/private_module_through_namespace`, `reject/redundant_module_import`,
      `reject/declaration_named_like_module`

### Step 2 — the shorthand is refused

- [ ] an item with no `from` whose first segment names no module of the package is
      `error[shorthand-import]` at the item: one module declaring the name `pub` → `write import
      {config.splitPath};`; several → the candidates listed; none → `unresolved import`
- [ ] the shorthand arms of `resolveImports` and `outsideShorthandReach` deleted; 170's
      `ambiguous-import-use` stays for `from "<pkg>"` alone
- [ ] cells `reject/shorthand_import` (one candidate, several, none); every accept cell that wrote a
      shorthand rewritten to the module path

### Step 3 — the migration, in the refusal's commit

- [ ] `scripts/codemod-import-without-from.py` (or a sibling) rewrites each shorthand to the path the
      refusal names: about 75 items in 32 files — botopink-lang (std, the libraries until 138 moves
      them, tests), rakun, jhonstart; each library's commit a consumer commit (188), its `botopink test`
      green

### Step 4 — docs and tools

- [ ] `docs.md` § Modules (`mod` binds the namespace) and § Imports (the shorthand paragraph and the
      `perimeter` example go; the `ambiguous-import-use` sentence keeps the `from` case)
- [ ] the language server's completion and go-to-definition follow `mod`'s namespace (26 s8's carve-out
      named in the commit)

**Gate:** standard (fronts.md § Gate) — `zig build test`, `zig build test-language`, `zig build test-libs`.

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
