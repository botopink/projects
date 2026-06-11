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
- [ ] Migration generator (filesystem → `root.bp`/`main.bp` + `mod.bp`). Pilot
      `examples/*` + `libs/std`. Record the breaking change in `CHANGELOG.md`.
      (Other libs = `libs-module-migration`, Wave 2.)

## F6 — docs + tests
- [x] `docs.md` §Modules (tree, `mod`/`pub mod`/`mod.bp`/`root.bp`/`main.bp`,
      path-visibility, imports-through-tree, migration). CHANGELOG breaking-change
      entry recorded.
- [x] parser tests (F0); resolver/visibility/import-resolution unit tests
      (`resolver.zig`: stripBpExt, isSource, topological order, cycle-safety,
      withinSubtree, visibility both directions, unexported-import). CLI tests now
      run in `zig build test`.
- [ ] LSP go-to-def across `mod` boundaries still works (verify; LSP path-aware
      handling if needed).

## Open decisions (resolve in F1/F5)
- [x] implicit-scan: deprecated fallback (kept behind a deprecation warning when
      no `main.bp`/`root.bp` root exists; remove in a future release).
- [ ] `root.bp`/`main.bp` coexistence in one package (F1: auto-detect prefers
      `main.bp` then `root.bp`; `entry` overrides — finalize during F5 pilot)
- [x] `Name.bp` + `Name/mod.bp` both present = error (no silent precedence)

## Done gate
- [ ] a multi-folder package builds + runs on commonJS via the declared tree.
- [ ] a private `mod` is provably not importable across a boundary.
- [ ] `zig build && zig build test` green.
