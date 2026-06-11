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
- [ ] Resolver from the package root (`main.bp` binary / `root.bp` library, per
      `botopink.json` entry) following `ModDecl`s. `mod Name;` resolves `Name.bp` OR
      `Name/mod.bp` (ambiguous/missing → error). CLI `scanner.zig` stops blind-walking
      `src/`; an unreferenced `.bp` is reported orphaned.

## F2 — visibility / path resolution
- [ ] Track visibility + parent per module; enforce path-visibility (every `mod` on the
      path must be `pub mod` + decl `pub` to cross a boundary). Name the private segment.

## F3 — imports resolve through the tree
- [ ] `import {x} from "a.b"` follows the `mod` chain; `from "<lib>"` unchanged; bare
      `import {x};` = from the root module.

## F4 — codegen: module boundaries + reexports
- [ ] Emit each module per the tree; `pub mod` reexports through the parent. Parity on
      all four backends.

## F5 — migration mechanism + pilot
- [ ] Migration generator (filesystem → `root.bp`/`main.bp` + `mod.bp`). Pilot
      `examples/*` + `libs/std`. Record the breaking change in `CHANGELOG.md`.
      (Other libs = `libs-module-migration`, Wave 2.)

## F6 — docs + tests
- [ ] `docs.md` §Modules; parser/resolver/visibility tests (sibling vs folder,
      ambiguous-module error, private-import error, `pub mod` reexport). LSP go-to-def
      across `mod` boundaries still works.

## Open decisions (resolve in F1/F5)
- [ ] implicit-scan: deprecated fallback or remove? (recommend: deprecate 1 release)
- [ ] `root.bp`/`main.bp` coexistence in one package
- [ ] `Name.bp` + `Name/mod.bp` both present = error (no silent precedence)

## Done gate
- [ ] a multi-folder package builds + runs on commonJS via the declared tree.
- [ ] a private `mod` is provably not importable across a boundary.
- [ ] `zig build && zig build test` green.
