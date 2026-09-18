# The JS half — commonJS and typescript

Secondary by the maintainer's own framing ("js é mais simples e mais flexível"). This file says what
the JS backends do today, what the erlang decision implies for them, and whether the two backends
should share one module identity. **The recommendation is that JS output does not change.**

---

## 1. What the JS backends do today

### 1.1 The identity is the path, not a basename

`src/codegen/commonJS.zig:1850-1905` (`buildUse`) builds every `require` target from the **full
module path**, with a `../` prefix per path segment of the *requiring* module:

```zig
// All emitted `require` targets are module paths relative to the OUTPUT
// ROOT (`std/x`, `<dep>/<mod>`, …), but node resolves a `require` relative
// to the requiring FILE. A module nested under a package prefix (a
// dependency's `<dep>/<mod>`, depth 1) must therefore reach back up to the
// root with one `../` per path segment before descending …
const depth = std.mem.count(u8, self.module_name, "/");
```

- `from "std"`: `require("<prefix>std/<mod>.js")` (`:1874-1879`).
- a package import: the owner module is looked up in `CrossModule.exports` and required by **its
  path**, one `require` per distinct owner (`:1893-1905`).

`src/codegen/typescript.zig:181-186` emits the `.d.ts` import source as the raw import string
(`u.source.module`, or `"./module"` for a root import) — a type-level reference only, never
executed.

### 1.2 The file layout matches

`modules/compiler-cli/src/cli/build.zig:190` writes `out/<module path><ext>` and creates the
intermediate directories (`:194-199`); the `.d.ts` sidecar goes to `out/<module path>.d.ts`
(`:203-208`). `shipMjsSidecars` (`cli/libs.zig:404-537`) copies a dependency's `.mjs` next to its
emitted `.js`, i.e. under `out/<dep>/`, rewriting the `require` text when the sidecar has to be
relocated (`:472-489`, `relocatedRequire` `:544-556`).

### 1.3 Consequence: **JS has no collision**

Two modules with the same basename in different directories are two different files at two
different paths and two different `require` targets. There is nothing to fix on this side, and
nothing the erlang scheme needs from it.

The one known JS naming defect is already tracked elsewhere: a dependency's *sibling* import is
emitted as `require("../module")` and fails at run time with `Cannot find module '../module'`
(emilia-card, jhonstart-counter, jhonstart-todo) — listed in
[`../fronts.md` § Unowned items](../fronts.md#unowned-items) — filed in 1.0.4-beta against 12 and
01 step 6; in 1.0.5-beta it belongs to [`../04-js/`](../04-js/README.md). It is a
`depth`/target mismatch in the code quoted above, **not** a module-identity question, and this front
does not take it.

---

## 2. What the erlang decision implies here

| Erlang change | JS impact |
|---|---|
| The atom becomes `atom(path)` instead of `basename(path)` | none — JS never reads the atom |
| `out/` goes flat for `.erl`/`.S` | none, **if** the flattening is per target (`out/erl/`, `out/beam/`) and not global |
| `CrossModule.ownerModuleAtom` gains a sibling `ownerModulePath` | JS already uses `info.module` directly (`commonJS.zig:1897`); the two just stop being the same function |

The one thing the front must **not** do is flatten `out/` globally. `commonJS.zig:1858-1870`
computes `../` from the number of `/` in the requiring module's path; a flat JS output would make
every one of those prefixes wrong and break every multi-module JS program.

---

## 3. Should the two backends share one canonical module identity?

**Yes — one identity, two renderings.** The identity already exists and is already shared: the
module path (`ComptimeOutput.name`). What is missing is a single place that turns it into a
backend-specific name. Today the truncation is written three times
(`crossModule.zig:81`, `erlang.zig:964-968`, `runtime.zig:451-455`) and the JS path is used raw in
a fourth.

Proposed shape, in `src/codegen/crossModule.zig` (it already owns `moduleBasename` and is already
the file all three backends import):

```zig
/// The canonical identity of a module: the path the front end produced.
/// Every backend renders it; none invents its own.
pub const ModuleId = []const u8;

/// Erlang/BEAM: a legal unquoted atom (see specs 13-module-identity/atom-options.md option A).
pub fn erlAtom(alloc, id: ModuleId) ![]const u8 { … }

/// commonJS/typescript: the path, unchanged — it is the require target.
pub fn jsPath(id: ModuleId) []const u8 { return id; }

/// The output file name for a target, without its extension.
pub fn outputStem(target, alloc, id: ModuleId) ![]const u8 { … }
```

`ownerModuleAtom` becomes `erlAtom(exports.get(name).?.module)`; `runtime.zig:451` and
`beam_asm.zig:913` call `erlAtom`; `build.zig:190` calls `outputStem`. That is the whole change on
the identity side, and it is what stops a fourth backend from inventing a fifth rule.

**What stays different on purpose:** the erlang rendering flattens the path into the name because
`erlc` demands it ([E1](./atom-evidence.md#e1--the--module-atom-must-equal-the-source-files-basename)); the
JS rendering keeps the path as a path because node resolves it as one. Forcing either to adopt the
other's shape would be cosmetics paid for with a broken backend.
