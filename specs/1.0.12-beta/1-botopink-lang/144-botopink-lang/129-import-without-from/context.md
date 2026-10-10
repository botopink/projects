# Front 129 — import-without-from: `from` names a package, never a module of the importing package

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial — 206 done; 337's steps 1–4 built (patches landing with the coordinator)
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
