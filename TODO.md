# Import Syntax — `import {A, X*} [from "module"]`

**Branch**: `task/import-rework`
**Phase**: F0 → F1 → F2
**Depends on**: nothing (independent)
**Status**: ✅ done (F0 + F1 + F2 implemented, 914/914 tests pass)

> **SUPERSEDES** the `@root()`/`@module()` approach. This branch **reverts** the
> `@root()`/`@module()` import-expression model in favor of `import {…} [from "name"]`.

## Target syntax

```bp
import {A, X*};                          // A = name; X = name + active dispatch (implicit root)
import {Pato, PatoNada*} from "ducks";   // from a named dependency
import {std.List as L, math.Trig*};      // dotted path + alias + activation
X*;                                       // fallback: activate an already-visible symbol
```

Grammar (flat — nesting `path.{…}` is a future phase):
```
import   ::=  "import" "{" item ("," item)* "}" from? ";"
from     ::=  "from" string
item     ::=  dottedPath "*"? ("as" ident)?
```

- no `from` → resolves from the project root
- `from "name"` → resolves from the named dependency
- trailing `*` on an item → activates dispatch of that symbol's methods (impl or extend)
- bare name (no `*`) → brings the name only; `obj.m()` does **not** resolve, only qualified `Sym.m(obj)`
- `as` renames the final binding

## Examples

### Mixed bare name + activation + alias
```bp
import {Pato, PatoNada*, PatoVoa* as Voa, std.List as L} from "ducks";

val p = new Pato();          // Pato: name only
p.swim();                    // PatoNada*: active
Voa.move(p);                 // PatoVoa imported as Voa, qualified
val xs = L.of(1, 2, 3);      // std.List as L
```

### Implicit root vs named dependency
```bp
import {Config};                 // from the current project (root)
import {fetch} from "http";      // from an external dependency
```

### Activation fallback (local symbol)
```bp
extend Pato { fn quack(self: Self) -> string { return "quack"; } }  // defined here
PatoExtra*;                       // activate the local extension without re-importing
```

## Steps

### F0 — revert to `import`/`from` ✅
1. ✅ AST: `ImportPath { segments, activate: bool, alias: ?[]const u8 }`
2. ✅ AST: `ImportDecl { imports, source, activationOnly }` + `ImportSource = union { root, module: []const u8 }` — dropped `Source: *Expr`
3. ✅ AST: removed modeling of `@root()`/`@module()` as import expressions
4. ✅ Parser: `import {…};` → `source = .root`; `import {…} from "name";` → `.module`
5. ✅ Parser: removed parsing of `= @root()` / `= @module()`; dropped dead `removedFromSyntax` error
6. ✅ Format/print: emits `import {…} [from "name"];`
7. ✅ Snapshots: `codegen/*/import_named_imports`, `import_multi_module_*`; `parser/import_from_root`, `import_from_module`
8. ✅ Docs: `docs.md` Imports section, AGENTS.md, language-server docs, vscode snippet

### F1 — suffix `*` + dotted path + alias ✅
1. ✅ Parser: after dotted path, `match(.star)` → `activate = true`
2. ✅ Parser: then `match(.as)` → `alias` (order `path "*"? ("as" id)?`)
3. ✅ Format: emits `a.b.C* as Q` in the correct order
4. ✅ Snapshots: `import_activate_suffix`, `import_dotted_activate`, `import_activate_with_alias`, `import_mixed_plain_and_activate`

### F2 — fallback `X*;` ✅
1. ✅ AST: reused `ImportDecl` with single `ImportPath` (`activate = true`) + `activationOnly` flag
2. ✅ Parser: `isActivationStmt()` lookahead + `parseActivationStmt()`; disambiguates from multiplication via `*` followed by `;`
3. ✅ Snapshots: `activate_statement`, `activate_dotted_statement`

## LSP / tooling follow-ups (done alongside)
- `import` keyword recognized in folding-range + add/remove-import code actions
- "Add missing import" now emits `import { X } from "name";`

## Test scenarios

```
parser ---- import {X};
parser ---- import {X} from "module";
parser ---- import {A, X*}                      (activation suffix)
parser ---- import {ducks.PatoNada*}            (dotted activate)
parser ---- import {std.List as L, X* as Q}     (alias + activate)
parser ---- X*;                                 (fallback statement)
```

## Notes

- Import **resolution** (dotted path navigates submodules, `import {X};` vs `from "name"`)
  is consumed by `feat/extension-dispatch` and integration — see open point P5
  (import relative to a subfolder?).
- `*` appears in 3 contexts (multiply, `*fn`, `X*`) — contextually distinct.