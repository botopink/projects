# TODO — module-system  (core keystone · Wave 1)

> Task branch `task/module-system` · spec
> [`tasks/v0.beta.9/specs/module-system.md`](tasks/v0.beta.9/specs/module-system.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** Keystone — unblocks `libs-module-migration` (Wave 2). Start now.
> Breaking change to module resolution.

## F0 — parse `mod` / `pub mod`
- [x] Top-level `mod ident;` / `pub mod ident;` → `ModDecl { name, is_pub }` (`ast.zig`).
      `mod` becomes a keyword; `mod` in a fn body = parse error.

## F1 — build the module tree from a root
- [x] Resolver from the package root (`main.bp` binary / `root.bp` library, per
      `botopink.json` entry) following `ModDecl`s. `mod Name;` resolves `Name.bp` OR
      `Name/mod.bp` (ambiguous/missing → error). CLI `scanner.zig` stops blind-walking
      `src/`; an unreferenced `.bp` is reported orphaned.
      (`resolver.zig` + `sources.zig`; topological order so imports resolve;
      blind scan kept as deprecated fallback when no root exists.)

## F2 — visibility / path resolution
- [x] Track visibility + parent per module; enforce path-visibility (every `mod` on the
      path must be `pub mod` + decl `pub` to cross a boundary). Name the private segment.
      (Enforced in `resolver.zig` where the tree lives — `checkVisibility` walks each
      import edge; decl-level `pub` already gated by core `registerExports`.)

## F3 — imports resolve through the tree
- [x] `import {x} from "a.b"` follows the `mod` chain (dotted path = `mod` chain →
      slashed logical path); a `from` that names a real package module must export
      the symbol (`checkImportResolution`). `from "<lib>"`/`from "std"` unchanged
      (generic loader / global). Bare `import {x};` still resolves package-wide
      (strict root-only semantics deferred to F4 reexports).

## F4 — codegen: module boundaries + reexports
- [~] Emit each module per the tree; `pub mod` reexports through the parent. Parity on
      all four backends. (Largely covered by the existing cross-module codegen —
      verified end-to-end on commonJS: `require`/`exports` per module in dependency
      order. erlang/beam share the same `crossModule.zig` analysis; wasm stays
      single-module (known gap). Cross-PACKAGE `pub mod` reexport surface ties into
      F5/libs-module-migration. No new code needed for the within-package case.)

## F5 — migration mechanism + pilot
- [x] Migration generator (`botopink migrate [--dry-run]`, `migrate.zig`): walks
      `src/`, prepends `pub mod X;` to each directory's index (`root.bp`/`main.bp`
      at the root, `mod.bp` per folder), creating index files as needed.
      Defaults to `pub mod` to preserve old reachability; idempotent. Verified
      migrate→build→run on a multi-folder package. Breaking change in `CHANGELOG.md`.
- [x] Pilot — `examples/modules/`: a committed multi-folder package (root + leaf +
      folder index + a private submodule used within its subtree) that builds and
      runs on commonJS (`12`/`circle`/`7`) and demonstrates the path-visibility rule
      (importing the private `helpers` from `main.bp` is rejected). Existing examples
      are either single-file in `src/` (already tree-compatible, nothing to migrate)
      or illustrative lib-dependent (non-standard layouts).
- [x] `libs/std` pilot — std now carries the tree: `libs/std/src/root.bp` declares
      `pub mod <name>;` per importable std module and is the **single source of
      truth**. `build.zig` (`stdPkgFilesFromRoot`) reads root.bp at build time and
      embeds exactly the declared modules — the generated `std_pkg` table is
      byte-identical to the old hardcoded `std_pkg_files`, so behavior is unchanged
      but tree-driven (adding a std module = drop `<name>.bp` + `pub mod <name>;` in
      root.bp, no build/core edit). `.d.bp` ambient modules stay separate (flattened
      into the env). Other libs = Wave 2 `libs-module-migration`.

## F6 — docs + tests
- [x] `docs.md` §Modules (tree, `mod`/`pub mod`/`mod.bp`/`root.bp`/`main.bp`,
      path-visibility, imports-through-tree, migration). CHANGELOG breaking-change
      entry recorded.
- [x] parser tests (F0); resolver/visibility/import-resolution unit tests
      (`resolver.zig`: stripBpExt, isSource, topological order, cycle-safety,
      withinSubtree, visibility both directions, unexported-import). CLI tests now
      run in `zig build test`.
- [x] LSP go-to-def across `mod` boundaries still works. The LSP (`project_index.zig`)
      walks the workspace itself and indexes every `.bp`'s `pub` symbols by name,
      independently of the module tree, so cross-`mod` go-to-def resolves unchanged;
      `pub mod X;` is correctly ignored (not a value/type symbol). `lsp_tests` green
      in the gate. (Visibility-aware completion/def is a future enhancement, not
      required here.)

## Open decisions (resolve in F1/F5)
- [x] implicit-scan: deprecated fallback (kept behind a deprecation warning when
      no `main.bp`/`root.bp` root exists; remove in a future release).
- [x] `root.bp`/`main.bp` coexistence in one package — resolved: auto-detect prefers
      `main.bp` then `root.bp`, `botopink.json` `entry` overrides. Validated by the
      `examples/modules/` pilot (binary root via `main.bp` + `entry`).
- [x] `Name.bp` + `Name/mod.bp` both present = error (no silent precedence)

## Done gate
- [x] a multi-folder package builds + runs on commonJS via the declared tree.
      (`examples/modules/`: root + leaf + folder index + nested module → `12`/`circle`/`7`.)
- [x] a private `mod` is provably not importable across a boundary.
      (Importing `shapes.helpers` from `main.bp` is rejected, naming the private segment.)
- [x] `zig build && zig build test` green. (Every commit's pre-commit gate; merged to feat.)

> **Status: module-system keystone COMPLETE.** F0–F6 done and merged+pushed to
> `origin/feat` (core `662b64c`, example pilot `1eae5ea`). Sole deferred item: the
> `libs/std` pilot (std is embedded at compile time, outside the CLI resolver — a
> separate embedding rework; belongs with the broader libs migration / Wave 2).
