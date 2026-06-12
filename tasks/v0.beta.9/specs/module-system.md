# module-system — explicit `mod`/`pub mod` declarations, `root.bp`/`main.bp`, `mod.bp` folder index

**Slug**: module-system
**Depends on**: nothing
**Files**: `modules/compiler-core/src/parser.zig` (the `mod` declaration), `modules/compiler-core/src/ast.zig` (a `ModDecl` node), `modules/compiler-core/src/comptime/infer.zig` + `env.zig` (visibility / module-tree resolution), `modules/compiler-core/src/codegen/*` (module boundaries / reexports), `modules/compiler-cli/src/cli/scanner.zig` + `libs.zig` (drive resolution from the tree, not a blind walk)
**Touches docs**: `docs.md` (§Modules), `modules/compiler-core/src/comptime/AGENTS.md`, `modules/compiler-cli/AGENTS.md`
**Status**: pending

> A real, Rust-style module system: a package declares its tree explicitly from a
> root, instead of the compiler implicitly compiling every `.bp` it finds under
> `src/`. Memory: [[feedback_everything_english]], [[feedback_camelcase_naming]].

## Context — how modules work today

The CLI `scanner.zig` walks `src/` recursively and turns **every** `.bp` into a
module keyed by its path (`utils/math.bp` → module `utils/math`). Cross-module
references resolve by file name (`import { double } from "math"` finds `math.bp`),
visibility is only per-declaration (`pub fn` / `pub val`). There is **no** `mod`
declaration, no folder index, no explicit tree — the filesystem *is* the module
graph, and anything present is implicitly part of the build and importable.

## Target model (Eric, 2026-06-10) — Rust-style explicit tree

```
src/
  main.bp          ← binary entry (holds `fn main`); roots a binary package
  root.bp          ← module-tree root of a library package (its public surface)
  geometry.bp      ← a leaf module, pulled in by `mod geometry;`
  shapes/
    mod.bp         ← the `shapes` module — the FOLDER INDEX (Rust's mod.rs)
    circle.bp      ← pulled in by `mod circle;` inside shapes/mod.bp
    square.bp
```

```bp
// root.bp — the tree root declares the top-level modules
pub mod geometry;     // public: re-exported, importable by consumers of this package
pub mod shapes;       // public: resolves shapes/mod.bp (folder index)
mod internal;         // private: visible only within this package's subtree

// shapes/mod.bp — a folder index declares the folder's submodules
pub mod circle;       // resolves shapes/circle.bp
pub mod square;       // resolves shapes/square.bp
mod helpers;          // private to the shapes subtree
```

- **`mod Name;`** declares a submodule, **private** to the declaring module's
  subtree. **`pub mod Name;`** declares it **public** (re-exported through the
  parent, reachable from outside the package / parent module).
- **Resolution of `mod Name;`** (in the declaring file's directory): `Name.bp`
  (sibling file) **or** `Name/mod.bp` (folder index). Exactly one must exist —
  both or neither is an error.
- **`mod.bp`** is a folder's index module (like Rust's `mod.rs`): it is the module
  named after its folder, and it declares that folder's submodules + re-exports.
- **`main.bp`** roots a **binary** package (the entry holding `fn main`).
  **`root.bp`** roots a **library** package (`libs/<x>/` — its public API tree). A
  package's `botopink.json` `entry` points at whichever root applies.
- A declaration is importable across a boundary only if **every `mod` on its path
  is `pub mod`** *and* the declaration itself is `pub` — the path-visibility rule.

## Steps

### F0 — parse `mod` / `pub mod`
- [ ] Lexer/parser: a top-level `mod ident ;` and `pub mod ident ;` statement → a
      `ModDecl { name, is_pub }` AST node (`ast.zig`). Only valid at module top
      level (a `mod` inside a fn body is a parse error). `mod` becomes a keyword.

### F1 — build the module tree from a root (replace the blind walk)
- [ ] A resolver that starts at the package root (`main.bp` for a binary, `root.bp`
      for a library — chosen by `botopink.json` `entry`) and follows `ModDecl`s
      transitively to collect the modules that are actually in the package. `mod
      Name;` in `dir/X.bp` resolves `dir/Name.bp` or `dir/Name/mod.bp`; error on
      ambiguous/missing. The CLI `scanner.zig` stops blindly walking `src/` — a
      `.bp` not reached through a `mod` path is **not** compiled (warn that it is
      orphaned). The compiler-core gains the tree; the CLI feeds it the root.

### F2 — visibility / path resolution
- [ ] Track each module's visibility (from its declaring `mod`/`pub mod`) and parent
      in `env`. Enforce the path-visibility rule: an import or qualified reference
      crossing into a module succeeds only if every `mod` on the path is `pub mod`
      and the target decl is `pub`. A private `mod` is reachable only from within its
      own subtree. Diagnostics name the offending private segment.

### F3 — imports resolve through the tree
- [ ] `import { x } from "geometry"` / `import { x } from "shapes.circle"` resolve
      via the declared module tree (dotted path = the `mod` chain), not a raw file
      lookup. `from "<lib>"` for external packages is unchanged (the generic loader).
      A bare `import { x };` resolving from the package root now means "from the root
      module" (`root.bp`/`main.bp`), made explicit.

### F4 — codegen: module boundaries + reexports
- [ ] Emit each module as its target module (commonJS `require`/`exports`, erlang
      module atom, etc.) following the tree; `pub mod` re-exports the submodule's
      public surface through the parent so a consumer importing the parent sees it.
      Keep parity across the four backends (mirrors the cross-module work in
      [[project_v0beta9_tail]]'s `cross-module-codegen`).

### F5 — migration mechanism + pilot (the rest of the libs is its own spec)
- [ ] Existing packages rely on the implicit scan; this is a breaking change. Ship
      the migration *mechanism* (a generator that derives a `root.bp`/`main.bp` +
      folder `mod.bp`s from a package's current filesystem) and prove it end-to-end
      by migrating **`examples/*` + `libs/std` as the pilot** (std is the most
      load-bearing — if the tree model carries std, it carries anything). Record the
      breaking change in `CHANGELOG.md`. The remaining `libs/*` (erika, jhonstart,
      rakun, onze, server, client) are migrated in parallel by
      [[libs-module-migration]] once this lands. (Decide whether the implicit scan
      stays as a deprecated fallback — see Open decisions.)

### F6 — docs + tests
- [ ] `docs.md` §Modules: the `mod`/`pub mod`/`mod.bp`/`root.bp`/`main.bp` model with
      examples. Parser + resolver + visibility tests (sibling vs folder resolution,
      ambiguous-module error, private-module import error, `pub mod` reexport). LSP
      go-to-definition across `mod` boundaries keeps working.

## Open design decisions (resolve during F1/F5 — recommendations inline)

1. **Implicit scan: remove or keep as fallback?** *Recommend:* explicit tree is the
   rule; keep the old blind scan only behind a deprecation warning for one release,
   then remove — clearest semantics, matches the Rust model Eric asked for.
2. **`root.bp` vs `main.bp` in one package.** *Recommend:* a `libs/<x>` library roots
   at `root.bp` (public API); an app roots at `main.bp` (`fn main`). A package may
   have both (a library with a thin binary) — `main.bp` then `mod`s into the same
   tree. `botopink.json` `entry` disambiguates.
3. **`mod Name;` file vs folder precedence.** *Recommend:* error if both `Name.bp`
   and `Name/mod.bp` exist (no silent precedence), as Rust's later editions do.

## Test scenarios

```
parse   ---- `pub mod foo;` / `mod foo;` parse as ModDecl; `mod` in a fn body errors
resolve ---- `mod shapes;` finds shapes/mod.bp; `mod circle;` finds shapes/circle.bp
resolve ---- both shapes.bp AND shapes/mod.bp present → ambiguous-module error
visib   ---- importing through a private `mod` fails with the private segment named
visib   ---- `pub mod` chain + `pub fn` target imports successfully across packages
run     ---- a multi-folder package builds + runs on commonJS via the declared tree
build   ---- a .bp not reached by any `mod` path is reported orphaned (not compiled)
```

## Notes

- This is a breaking change to module resolution — keep it its own cycle (`v0.beta.11`).
  The core lands here with the migration *mechanism* + `examples/*` + `libs/std`
  migrated; the rest of `libs/*` follows in [[libs-module-migration]] (disjoint
  packages, parallel) so the whole tree ends green in the same set.
- Touches the same codegen cross-module machinery as `cross-module-codegen`
  ([[project_v0beta9_tail]]); if both are in flight, sequence the codegen merges.
- Parser/comptime gotchas still apply to any `.bp` written here:
  [[reference_bp_parser_comptime_gotchas]].
