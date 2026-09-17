# Front 12 (and 13): blast radius re-measured

Measured 2026-09-17 at `botopink-lang` `4eadb70`. Since then: **R3 is decided** — the text of a
tuple is [decision 1a](../08-review-backlog/semantics-decisions.md#decision-1a) (`#(a,b)`, nested
strings quoted), implemented by 01 step 4, which must land before this front's step 2; **R9 is
closed** — std-split landed (`c8c2541`); **R12 is closed** — the meta pointers of jhonstart and
onze were bumped.

- botopink-lang: `41981e3` (where the spec measured) → `4eadb70` (origin/feat after front 01 landed). 50 commits between them.
- Libraries: at the meta commit `6ecfd7cf` pointers → at each library's `origin/feat`.
- Everything was read from committed trees (`git show <rev>:path`, `git ls-tree`, `git grep <rev>`), never from a worktree.
- Each count names its regex; the counting scripts were throwaway.
- Every script was first run at the old commit to check it reproduces the spec's numbers. Where it does not, both numbers are given.

## 1. "Why one front": the files that use the three declaration kinds

**What changed since `41981e3`:**
- Only the four backend files changed.
- Unchanged byte-for-byte (no diff between the commits): `ast.zig`, `parser/decls.zig`, `parser/{exprs,types}.zig`, `format.zig`, `comptime.zig`, `comptime/{env,snapshot}.zig`, `crossModule.zig`, `project_index.zig`, `cli/resolver.zig`.
- Changed, but not at any declaration-kind site:
  - `lexer.zig`: −13 lines, the dead keywords;
  - `parser.zig`: `isMemberName`;
  - `comptime/infer.zig`: the `pick` intercept;
  - `typescript.zig`: +13 lines;
  - `engine.zig`: 9 lines.
- No file was added or removed from the set of files that use these kinds.
- How that was checked: `git grep -c -E '\b(RecordDecl|EnumDecl|InterfaceDecl|recordLit|interfaceLit|record_type|RecordLit|recordType)\b|\.(record|@"enum"|interface)\b' <rev> -- 'modules/*.zig' build.zig`. It lists 32 files at both commits, and only 4 of them have a different count.

**How the table is counted (`count.py`).** Per file, excluding lines that start with `\\` or `//`:
- **A** = matches of `\.(record|@"enum"|interface)\b`
- **B** = matches of `\b(RecordDecl|EnumDecl|InterfaceDecl)\b`

This is a consistent proxy, not the spec's exact method (the spec did not state its regex). Read the **delta**, not the absolute number.

| File | 41981e3 A/B (A+B) | 4eadb70 A/B (A+B) | Δ | Spec column (41981e3) |
|---|---|---|---|---|
| `ast.zig` | 2/9 (11) | 2/9 (11) | 0 | 9 |
| `parser.zig` | 8/6 (14) | 8/6 (14) | 0 | 3 |
| `parser/decls.zig` | 4/18 (22) | 4/18 (22) | 0 | 15 |
| `lexer.zig` | 2/0 (2) | 2/0 (2) | 0 | 3 |
| `comptime/infer.zig` | 32/10 (42) | 32/10 (42) | 0 | ~36 |
| `comptime/env.zig` | 4/4 (8) | 4/4 (8) | 0 | 4 |
| `comptime.zig` | 5/2 (7) | 5/2 (7) | 0 | 13 |
| `comptime/snapshot.zig` | 5/0 (5) | 5/0 (5) | 0 | 3 |
| `format.zig` | 6/3 (9) | 6/3 (9) | 0 | 12 |
| `codegen/commonJS.zig` | 6/3 (9) | 11/5 (16) | **+7** | 10 |
| `codegen/typescript.zig` | 6/3 (9) | 6/3 (9) | 0 | 6 |
| `codegen/erlang.zig` | 17/5 (22) | 22/5 (27) | **+5** | ~24 |
| `codegen/beam_asm.zig` | 14/7 (21) | 17/7 (24) | **+3** | ~22 |
| `codegen/wat.zig` | 4/0 (4) | 11/0 (11) | **+7** | 5 |
| `codegen/crossModule.zig` | 2/0 (2) | 2/0 (2) | 0 | 2 |
| `language-server/engine.zig` | 51/1 (52) | 51/1 (52) | 0 | ~20 (+~30 keyword tokens) |
| `language-server/project_index.zig` | 4/0 (4) | 4/0 (4) | 0 | 3 |
| `compiler-cli/.../resolver.zig` | 2/0 (2) | 2/0 (2) | 0 | 3 |

With the wider regex (the literal kinds included), the four backends go: beam_asm 25→32, commonJS 12→19, erlang 26→31, wat 12→21.

**The new consumers.** Every line below was added by the front 01 beam, wasm and commonJS work (`backends.diff`, the added lines):

- **commonJS**
  - `local_interfaces: std.StringHashMap(ast.InterfaceDecl)`, filled from `.interface => |i|` over the declarations: a user interface's default fns become class methods of the implementing record (CR4).
  - `if (decl == .interface) { const iface = decl.interface; … }`.
- **erlang**
  - `if (decl != .interface) continue; const i = decl.interface;`: default fns found by scanning the interfaces.
  - `.record => |r| for (r.methods) |m| try self.putLocalFn(...)`.
- **beam_asm**
  - `.interface => |i| for (i.methods)`.
  - `.recordLit` / `.interfaceLit` arms in `countFieldStaging`, in the closure walker `walk`, and in two literal lowerings.
- **wat**
  - `.record => |r| r.name`, `.interface => |i| i.name`, `.record => |r| try self.emitInterfaceMethods(r.name, r.methods)`, `.interface => |i| for (i.methods)`.
  - `.use, .@"enum", .interface, … => {}`.
  - `.recordLit` / `.interfaceLit` in `collectIdents`.
  - `local_types` fed from the records.

**Careful:** several of the new `.record =>` / `.record = …` arms (commonJS ×2, erlang ×2, wat ×3, beam ×2) are not `DeclKind`. They are the `.record` tag of `comptime/env.zig:294 InstanceLowering = union(enum) { prim: PrimKind, record: []const u8 }`. See risk R2.

## 2. Blast radius

| What | Spec (41981e3) | 41981e3, re-measured with the scripts | **4eadb70** | Script / regex |
|---|---|---|---|---|
| `.bp` declarations in `libs/std` | 22 record / 11 enum / 24 interface | 22/11/24 ✓ | **22/11/24** (one `record User` moved from `src/primitives.bp` to `test/primitives_test.bp`) | `bp_counts.py`: `^\s*(#\[..\]\s*)*(pub\s+)?(default\s+)?(record\|enum\|interface)\s+[A-Za-z_]`, `//` lines excluded |
| `.bp` in `examples/` | part of the 60 | 2 records + 2 `record {` literals | **2 + 2** (`generic-loader-binding/src/main.bp`, `stdlib-tour/src/main.bp`, `yamlconf/yamlconf.bp:12–13`) | same, plus `\brecord\s*\{` |
| Declarations in Zig `\\` test strings (core + LSP) | ~423 (220 record, 92 enum, 82 interface) | 430 (record 247, enum 99, interface 84) | **437** (core record 157 + val-form 74, enum 41 + 52, interface 17 + 67; LSP record 14 + 6, enum 1 + 6, interface 2) → **+7** | `zig_counts.py`: `\\` lines, `DECL` regex above plus `\bval\s+\w+\s*=\s*(record\|enum\|interface)\b` |
| `record {` literals in `\\` strings | ~20 | 13 real literals + 61 val-form `val X = record {` | **13 + 61** (unchanged) | `\brecord\s*\{` minus `\bval\s+\w+\s*(:[^=]*)?=\s*record\s*\{` |
| Where the +7 declarations are | — | — | `codegen/tests/aggregates.zig` +1, `dispatch.zig` +3, `features.zig` +3 (the CR4 fixtures: `record Doc`, `interface Bounded`, `record Money implement Bounded`, `interface Number`, `pub enum Shape`, `record User`, `record Service`) | `zig-<rev>.txt` |
| Single-line Zig strings | ~25 | 7 (strict) / 49 (broad) | **8 / 50** | strict: string with `record\|enum\|interface Name {\|implement\|(`; broad: a string containing `(record\|enum\|interface)` plus `{` or `(`. The broad count includes **diagnostic texts** (infer.zig 13, error.zig 3, snapshot.zig 4, erlang.zig 3, engine.zig 2), not only test sources |
| `*.snap.md` files | 2442 | 2442 ✓ (core 2342 + LSP 100) | **2515** (core 2415 = codegen 1194 + comptime 1009 + parser 212; LSP 100) → **+73** | `git ls-tree -r` |
| SOURCE sections with a keyword | 688 | 688 ✓ | **712** (declaration/literal form: 664 → **688**) | `snap_counts.py`: `----- SOURCE*` sections, `\b(record\|enum\|interface)\b` |
| Same, by directory (declaration/literal form) | — | codegen/{beam,commonJS,erlang,wasm} 74 each; comptime beam 73, erlang 103, node 103, wasm 73; LSP 16 | codegen **80** each (+6 × 4); the rest unchanged | |
| Parser JSON keys `"record":` / `"enum":` / `"interface":` | 59 | 59 files (occurrences 16/11/35) ✓ | **59** (unchanged) | "59" = files with any of the three keys, all under `snapshots/parser/` |
| Typed AST `record_def` / `enum_def` / `interface_def` | 172/104/44 | 172/104/44 occurrences ✓ (156/104/40 files) | **172/104/44** (unchanged) | occurrences in the whole snapshot |
| Output naming the declaration (`%% interface Name` / `// interface`) | not counted | 36 snapshots | **48** (+12) | an output section contains `%% interface` or `// interface` |

## 3. Step 3, by location

**Embedded prelude in `comptime.zig`**
- It is not `:541–594`. The sources are three constants:
  - `decl_reflection_src` `:540–557`
  - `custom_ast_reflection_src` `:566–574`
  - `type_info_src` `:581–606`
- The file did not change between the commits.
- Inside: **9 `pub record`** (Span, Annotation, Param, Field, Method, Decl, CustomNode, RecordField, EnumVariant) and **3 `pub enum`** (DeclKind `:541`, TypeInfoKind `:592`, TypeInfo `:594`).
- Every record field uses the `val name: T` form, which step 3 must remove (the new field list has no `val` prefix).
- The *variants* `DeclKind { Record, Struct, Enum, Interface, … }` and `TypeInfoKind { …, Record, Enum, … }` are read by library code (R6).

**`comptime/stdlib/*.bp`: no longer exists.**
- The directory holds only `prelude.zig` and `AGENTS.md`, at both commits.
- The `.bp` sources are embedded from `libs/std/src/` through the `std_prelude` imports declared in `build.zig:30–40` (`primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`, …).
- So this row folds into `libs/std`.

**`libs/std`: 22/11/24 still true.**
- `types.bp` and `reflect.bp`, which the spec cites (doc comments with `record { … }`), **were deleted** (they exist at `41981e3`, not at `4eadb70`).
- `libs/std/test/primitives_test.bp` now has one `record User`.
- No `record {` literal remains in `libs/std`.

**`examples/`: 2 declarations + 2 literals**, `yamlconf.bp:12–13` still valid. Also the `record { … }` mention in `examples/AGENTS.md:36`.

## 4. Front 13 by library (`lib_counts.py`: same regex; `//` lines excluded; markdown = `\b(record|enum|interface)\s+([A-Z]\w*|\{)|\brecord\s*\{`)

| Library | spec pointer → origin/feat | record | enum | interface | `record {` literals | .md | Delta |
|---|---|---|---|---|---|---|---|
| emilia | `da98db4` → `da98db4` | 0 | 1 | 0 | 0 | 1 file / 1 | none |
| erika | `670134a` → `670134a` | 7 (+1 val-form) | 0 | 0 | 6 (`erika.bp:375, 417, 466, 503, 570, 839`) | 3 / 15 | none |
| jhonstart | `a79d654` → **`8668c40`** | 2 | 0 | 2 | 10 (`hooks.bp:37, 49, 57`; `html.bp:91, 99, 106, 128, 133, 137, 148`) + 1 `@Context<…, {}>` | 2 / 3 | counts equal; the new commit is only `ci(test.yml): default BOTOPINK_LANG_REF to feat` |
| onze | `8889441` → **`2fcf860`** | 4 | 0 | 3 | 0 | 4 / 6 | counts equal; CI commit only |
| rakun | `d4a6794` → **`d28d430`** | 30 (3 in `src/`) | 1 | 2 | 0 | 2 / 4 | counts equal |

Total with this regex: **53 declarations** (emilia 1, erika 8, jhonstart 4, onze 7, rakun 33), **16 literals** ✓, **12 md files / 29 occurrences** ✓. The per-library columns in the spec match exactly. The spec's "113 declarations" does **not** reproduce from its own table (which sums to 53); it probably counted something else (fields/methods?). Treat 53 as the number of keyword sites. Nothing changed between the meta pointers and `origin/feat`.

## 5. `file:line` citations that drifted

"OK" means the symbol is still on the cited line (the file did not change or the line did not move). Only the ones that moved or no longer exist:

| Cited in | Citation | Now |
|---|---|---|
| type-grammar.md | `lexer.zig:729` (`"type"`) | `lexer.zig:722` |
| behavior.md | `commonJS.zig:1296` `buildInterface` | `commonJS.zig:1602` |
| behavior.md (×2) | `erlang.zig:4004` `interfaceForms` | `erlang.zig:4864` |
| behavior.md | `typescript.zig:78–127` (record + interface) | `typescript.zig:82–152` (`record` 82, `enumDecl` 105, `interface` 131–152) |
| behavior.md | `beam_asm.zig` `reserveInterfaceMethods` / `emitInterfaceAssoc` (no line) | `:1526` / `:1534` |
| labeled-tuples.md | `erlang.zig:3169` (`recordLit` → `fieldMap`) | `erlang.zig:3777` (`interfaceLit` `:3778`, `fn fieldMap` `:3986`) |
| README.md | `build.zig:141–191` (test step compiling core + LSP + CLI) | `build.zig:143–195` |
| README.md, behavior.md | `comptime.zig:541–594` (prelude) | `comptime.zig:540–606` (three constants, see §3) |
| README.md step 3 | `comptime/stdlib/*.bp` | does not exist; the sources are `libs/std/src/*` via `build.zig:30–40` |
| labeled-tuples.md | `libs/std/src/types.bp`, `reflect.bp` | **deleted** |
| 13 README | rakun `src/bootstrap.bp:30` (record with methods and no fields) | `src/bootstrap.bp:27` (`pub record Rakun`) |
| separators.md / behavior.md | `parser/decls.zig:604,605` | valid ±1: `:603` is the `consume(.identifier)` of the bare type, `:604` the `match(.comma)`, `:605` the append |

Unchanged and still correct:
- `ast.zig:1621`, `1454`, `1838`, `1860`
- `parser.zig:90`, `444–453`, `450`, `1112`
- `parser/decls.zig:57`, `285–324`, `551–1007`, `628`, `755–813`, `1013–1073`
- `parser/exprs.zig:1121`, `1159`
- `parser/types.zig:46–60`, `104–121`, `162–177`
- `infer.zig:280–283`, `915`, `1043`, `1209`
- `format.zig:722–788`, `1634`, `1746`
- `examples/yamlconf/yamlconf.bp:12–13`
- emilia `tokens.bp:37`
- erika `erika.bp:570`, `examples/erika-linq/src/main.bp:95`
- rakun `examples/rakun/src/config.bp:22`, `posts.bp:15`, `test/scopes_test.bp:64`
- jhonstart `router.d.bp:20`, `server.d.bp:22`
- vscode `tmLanguage.json:42`

## 6. Risks the spec does not mention

- **R1: backend consumers written after the plan (+22 sites).** Step 1 ("every consumer moves in this commit") must also port:
  - commonJS `local_interfaces` (a map typed `ast.InterfaceDecl`) and the interface scan;
  - erlang's `decl != .interface` scan and `putLocalFn` over record methods;
  - wat `emitInterfaceMethods` over records, `local_types`, `collectIdents`;
  - beam `countFieldStaging` / `walk` over `recordLit` / `interfaceLit`.

  None of them is in the Codegen row of `behavior.md`.
- **R2: `InstanceLowering.record` (`comptime/env.zig:294`) collides with the textual acceptance checks.** The new backend code has 9 `.record =>` / `.record = …` arms over this union, not over `DeclKind`. A `grep '\.record\b'` after step 1 will not reach zero. Either rename the tag (e.g. `.named`) in step 1, or exclude it from the check explicitly.
- **R3: labeled tuples meet WR4, which is still open.** The spec says "anonymous records change from map/object to tuple".
  - After front 01, wasm prints a tuple as addresses, and the text of an array of tuples is waiting on a maintainer decision (WR4, decision 1). Erlang/beam print `{1,<<"a">>}`, commonJS `[ 1, 'a' ]`.
  - Every `@print` of a migrated anonymous record (erika rows, jhonstart tokens, yamlconf) will change its `RUN LOG` from map/object to that tuple text. That is the "behaviour-changed" class of step 3, not "output-changed" as the spec expects.
  - **Settle WR4 before step 2.**
- **R4: bare-digit access `pair.0` → `pair[0]` is new in commonJS (CR4, `a9d8a23`).** Access by label `#(x: …).x` must lower to an index on all four backends (JS `[i]`, erlang `element(i+1, T)`, beam, wasm). The fresh `pair.0` path is the natural attachment point, but it exists only in commonJS; beam, wasm and erlang need their own check.
- **R5: `%% interface Name` comments grew 36 → 48 snapshots.** Step 1's acceptance says "generated code unchanged", while `behavior.md` renames the comment to `%% behavior`. The spec contradicts itself. Decide whether the rename happens in step 1 (48 snapshots output-changed, comment only) or in step 4.
- **R6: library comptime code reads the prelude's variants.** rakun `src/decorators.bp` has **15** `DeclKind.Record` checks (`decl.kind != DeclKind.Record`).
  - The compiler has test uses too: `comptime/tests/decorator_invocation.zig` ×8, `codegen/tests/aggregates.zig` ×2, `decorator_eval.zig` ×2, `transform.zig`, `decorator_regression.zig`.
  - If `DeclKind` exposes `Type`/`Behavior` (behavior.md), rakun stops compiling at step 1 or 2, not at step 4 as the 13 README says. Front 13's rakun row does not mention it.
- **R7: the prelude uses `val field: T`.** The "no `val` prefix" rule of the field list reaches the 9 prelude records and `decl.fields` read by libraries. `Field`/`RecordField` are exposed shapes: confirm their names are not renamed.
- **R8: `comptime/stdlib/*.bp` does not exist.** The `.bp` prelude files come from `libs/std/src` through `build.zig:30–40`. `build.zig` belongs to 05, not 12. If step 3 renames or adds a file to that list, it needs the handoff.
- **R9: std-split is in flight on `libs/std/src/primitives.bp`** (the `split` template) and `libs/std/test/primitives_test.bp`, the same files step 3 migrates (15 declarations in `primitives.bp`). Land std-split before 12 starts.
- **R10: diagnostic texts in single-line strings.** The broad count (50) includes user-facing messages in `infer.zig` (13), `comptime/error.zig` (3), `comptime/snapshot.zig` (4), `erlang.zig` (3), `engine.zig` (2). The "Texts saying *interface* say *behavior*" rename crosses into 14's territory (user-facing `engine.zig` texts). Split it explicitly: the compiler is 12's, the LSP is 14's.
- **R11: more snapshots to classify: 2515 (+73), 712 SOURCE with a keyword (+24, all in `snapshots/codegen/*`).** The 6 new fixtures per backend (CR4 plus BR/WR) carry keywords and **real RUN LOGs**, including `interface_a_default_fn_calls_members…` and `enum_a_method_is_called_on_a_variant_value`. Step 1 must keep them byte-identical.
- **R12: jhonstart/onze `origin/feat` moved** (`8668c40` / `2fcf860`, CI commits from 10 step 3) since the meta pointer. Front 13's counts do not change, but the meta pointer is behind.
