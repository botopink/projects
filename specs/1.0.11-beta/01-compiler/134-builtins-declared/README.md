# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high — decision 252: a builtin the user calls has its full declaration — its type, its
static and its instance methods — in `libs/std/src/builtins.d.bp`, and the compiler checks the
implementation against that declaration.
**Depends on:** nothing. The catalogue's name (decision 253: `@TypeInfo.all`, a static method of
`TypeInfo<T>`) and what it answers (decision 254: `Declared<unknown>[]`, each entry with its `returnTypeName` — decision 256) are
answered and landed here.
**Owns:** `libs/std/src/builtins.d.bp`, `libs/std/src/builtins_fns.d.bp`, the compiler's builtin
table and the check that ties it to the declarations (`modules/compiler-core/src/comptime/` — the
place where `@name(…)` calls are resolved), `docs.md` § builtins, the cells under
`tests/language/reject/` for a builtin whose implementation disagrees with its declaration, and the
`AGENTS.md` of each directory touched.
**Does not touch:** what a builtin does on any backend (a builtin whose behavior is wrong is its
owner front's); decorator outputs (130).

---

## Problem

`builtins.d.bp` declared ten of the twenty-one `@name` builtin calls the compiler implements, four of
them with a signature the compiler did not have (`@print`/`@println`/`@debug` take any value, not a
`string`; `@getContext(T)` answers `T`, not `Component<T, unknown>`), and the compiler checked no
builtin call's arguments against anything (`@todo(1)`, `@trap(1)`, `@panic("a", "b")` compiled).
A user could not read a signature anywhere, and nothing kept the compiler and the documented surface
in step.

## Decision 252

1. Every builtin reachable from a program — a `@name(…)` call, a `@name` type or value, a builtin
   type with static members (`TypeInfo.all`) — is declared in `builtins.d.bp` (or
   `builtins_fns.d.bp`): a function as `pub declare fn`, a type as `pub type` with its fields, its
   instance methods and its static methods as `declare fn` inside the type (the house rule for a
   host function with an owner).
2. The compiler refuses a builtin it implements but the declarations do not name, and a declaration
   whose signature differs from what the compiler accepts — checked once, by a unit test over the
   builtin table and the parsed declarations, so the two cannot drift.
3. `docs.md` documents each builtin from its declaration.

## Steps

### Step 1 — the inventory

Every name the compiler treats as a builtin (call, type, value, comptime-only), where it is resolved
(file:line), its accepted signature, and whether `builtins.d.bp` declares it — one table in this
README.

**Builtin calls** — the compiler's table is `modules/compiler-core/src/comptime/builtins.zig`
(`table`); every call reaches `infer.zig` `inferBuiltinCallReturnType` (`:6802`), which first runs
`checkBuiltinArguments` (`:7095`) for a row held `declaration`. Paths are under
`modules/compiler-core/src/`. "Before" is `feat` at the front's base; "now" is this branch.

| Builtin | Resolved | Declaration (accepted signature) | Held at the call | Before | Now |
|---|---|---|---|---|---|
| `@print` / `@println` / `@debug` | `infer.zig:7026` (fallback `void`); lowered `codegen/commonJS.zig:5602`, `erlang.zig:2956`, `wat.zig:5363` | `print(value: unknown)` — but ANY NUMBER of arguments is accepted (`@print(a, b)` in four `tests/language/run` cells) | decision 267 (variadic, step 4) | `message: string` (wrong) | closest honest until step 4 |
| `@panic` | `infer.zig:7012`; `builtins_fns.d.bp` | `panic(message: string = "panic") -> noreturn` | declaration | yes | yes |
| `@todo` | `infer.zig:7012`; `builtins_fns.d.bp` | `todo(message: string = "not implemented") -> noreturn` | declaration | yes | yes |
| `@trap` | `infer.zig:7012` | `trap() -> noreturn` | declaration | yes | yes |
| `@block` | `infer.zig:6813` | `block<T>(body: fn() -> T) -> T` (the trailing lambda) | declaration | no | yes |
| `@module` | `infer.zig:7016` (`builtin-not-lowered`) | `module() -> module` | declaration (then refused) | yes | yes |
| `@getContext` | `infer.zig:6925` | `getContext<T>(comptime _: type) -> T` | own rule (RC4/RC5/RC3) | `-> Component<T, unknown>` (wrong; `134-c`) | yes |
| `@field` | `infer.zig:6883` | `field<T, F>(obj: T, comptime name: string) -> F` — comptime name | declaration | yes | yes |
| `@src` | `infer.zig:13979` (`inferSrcBuiltin`) | `src() -> SourceLocation` — COMPTIME-ONLY | own rule (`src-takes-no-arguments`) | no | yes |
| `@typeInfo` | `infer.zig:6853`; reads `:4001` (`inferTypeinfoRead`) | `typeInfo<T>(comptime _: type) -> TypeInfo<T>` — COMPTIME-ONLY | own rule | no | yes |
| `@TypeInfo.all` | `parser/exprs.zig:1303`; `infer.zig:13959`, `typeinfo_all.zig` `plan` | static `all(with: unknown, member: ?string = null) -> Declared<unknown>[]` of `TypeInfo<T>` — COMPTIME-ONLY | own rule (`typeinfo-all-*`); `with:`'s type is `134-b` | no | closest honest, `134-b` |
| `@TypeOf` | `infer.zig:6866` | `TypeOf<T>(value: T) -> T` — COMPTIME-ONLY | declaration | no | yes |
| `@makeRecord` | `infer.zig:6872`, `:14182` (`tryEvalMakeRecord`) | `makeRecord<R>(fields: RecordField[]) -> R` — COMPTIME-ONLY | declaration | no | yes |
| `@RecordKeys` | `infer.zig:6877` | `RecordKeys(comptime _: type) -> string[]` — COMPTIME-ONLY | declaration | no | yes |
| `@comptimeError` | `infer.zig:6984` | `comptimeError(comptime message: string) -> noreturn` — COMPTIME-ONLY | own rule | no | yes |
| `@emit` | `infer.zig:6914`; `decorator_eval.zig` | `emit(source: string)` — COMPTIME-ONLY | declaration | yes | yes |
| `@compilerError` | `infer.zig:7012`; `decorator_eval.zig`, `codegen/commonJS.zig:5661`, `wat.zig:6003` | `compilerError(message: string) -> noreturn` — COMPTIME-ONLY | declaration | no | yes |
| `@expr` / `@code` | `infer.zig:6827` | `expr<T>(comptime value: T) -> Expr<T>`, `code<T>(text: string) -> Expr<T>` — COMPTIME-ONLY | declaration | no | yes |
| `@is(…)` | `infer.zig:14156` | the parser's carrier of `x is T` (`ast.is_builtin_name`); written by hand `@is(1)` types `bool` with no tested type | — | no | not declared: `134-d` |
| `xs[i]` | `infer.zig:13945` | the parser's carrier of an index (`ast.index_builtin_name`); `@[` does not lex, so it is not reachable as a call | — | — | not a builtin |
| `@typeInfo.all` / `@typeinfo…` | `infer.zig:13950`, `:13974` | refused (`typeinfo-all-on-function`, `typeinfo-lowercase`) | — | — | not a builtin |

Twenty-one builtin calls: ten declared before (four of them wrongly), twenty-one now, two of them
the closest honest declaration with an open question (`134-a`, `134-b`).

**Builtin types and values.**

| Type | Resolved | Declared |
|---|---|---|
| `@Result<R, E>`, `@Task<T>`, `@Iterator<T>`, `@Stream<T>`, `@Context<Base>`, `@Component<C, T>`, `@Expr<E>` | `infer.zig:7847` (`builtinRequiredGenericArgs`), `env.zig` `registerBuiltins` | yes (`Result` a `type`, the others `behavior`s) — before and now |
| `@ExprCustom<T>` | `infer.zig` (mapped to `CustomExpr`) | as `CustomExpr<T>` — the `@` name is not the declared one (row for the remainder) |
| `@Decl` | `parser/types.zig:229`; `comptime.zig` `decl_reflection_src` | yes (`behavior Decl`) |
| `TypeInfo<T>` | `comptime.zig:1334` (`type_info_src`) | now — `name`, `module`, `fields`, `methods`, `meta`, static `all`; the structural enum `TypeInfo` and its `EnumVariant` / `TypeInfoKind` are gone (decision 248's fold) |
| `RecordField` | `comptime.zig:1334` | now |
| `SourceLocation`, `Declared<T>`, `DeclaredMeta`, `Span`, `Param`, `Field`, `Method`, `CustomNode`, `YieldStep<T>` | `comptime.zig` mirrors | yes — the mirror's `Annotation(name, args)` is `DeclAnnotation` in `builtins.d.bp` (row for the remainder) |
| `Display`, `Index`, `Slice`, `Annotation`, `External`, `Host`, `Target` | ambient behaviors / annotations | yes |

**Not declared yet (the remainder of step 2).** The comptime type functions called without `@` —
`mergeRecords`, `partial`, `omit`, `pick` (`infer.zig:7346`, `tryResolveTypeManipulationCall`);
the builtin `result` namespace (`result.map/then/unwrap/isOk/isError`, `infer.zig:12646`) and the
`@Result` / `?T` methods (`map`, `flatMap`, `unwrapOr`, `isOk`, `isError`, `infer.zig:12775`), today
comments in `builtins.d.bp`; the two naming differences above. The check covers the builtin calls;
the types are not walked yet.

**Acceptance:**
- [x] the table, complete: a builtin the compiler accepts and the table omits is a defect of this step

### Step 2 — declare them

Each undeclared builtin gets its declaration, comptime-only ones marked as such (`comptime`
parameters, a doc comment saying it never reaches run time). `@typeInfo` is declared as a function
answering `TypeInfo<T>` (`name`, `module`, `fields`, `methods`, `meta`) and the catalogue as the
static `declare fn all` of that type (decisions 253, 254), its answer `Declared<unknown>[]`.

Landed: every builtin call of step 1 declared; `@typeInfo.all` renamed `@TypeInfo.all` across the
compiler, the cells, `docs.md`, std and jhonstart (two comments; rakun had no use), the old spelling
refused; the catalogue typed `Declared<unknown>[]` (`infer.zig` `inferCatalogueAnswer`), so entries
of different value types sit in one answer (`run/typeinfo_all_unknown_value`) and a `value` used
without a test is refused (`reject/typeinfo_all_value_unknown`). Each entry carries
`returnTypeName` (decision 256): a function's declared return type as written, `""` for a type
(`typeinfo_all.zig` from `DeclaredEntry.returnTypeName`; `run/typeinfo_all_unknown_value`,
`run/typeinfo_all_list`). The two cells that called a `value`
through a typed local read `name`, `module` and `meta` only; calling it through `is fn() -> T` is
front 130's. No library reads `d.value` today (rakun's DI still goes through `__rkMake_<T>`).

**Acceptance:**
- [ ] every row of step 1 declared; `docs.md` § builtins generated from or checked against them — the
  builtin calls are; the remainder above (type functions, the `result` namespace, the `@Result` /
  `?T` methods, `@is`) is not

### Step 3 — the check

A unit test parses `builtins.d.bp` and walks the compiler's builtin table: every builtin declared,
every declaration implemented, signatures equal. A `reject/` cell where a program calls a builtin
with arguments the declaration refuses, located.

Landed: `comptime/builtins.zig` — `table`, `collectDeclared`, `drift` and the test "builtins: every
implemented builtin is declared, every declaration implemented, signatures equal", plus three tests
that prove each kind of drift against an altered copy of the file (a removed declaration, a changed
signature, a declaration with no implementation). The checker holds a call to every row
`declaration` to the parsed declaration (`Env.builtinDecls`, `comptime.zig` `registerBuiltinDecls`;
`infer.zig` `checkBuiltinArguments`): too many arguments, a missing parameter without a default and
an unknown label are `builtin-arguments`, an argument of another type the ordinary mismatch.
`tests/language/reject/builtin_arguments` (`@panic("first", "second")`, at `6:5`); the
`docs.md` § Builtins table and its `docs-check: reject builtin-arguments` fence.

**Acceptance:**
- [x] removing one declaration or changing one signature turns the test red, naming the builtin
  (measured: deleting `emit` and changing `RecordKeys`'s return reds it with
  ``builtin `@emit` is implemented (comptime/builtins.zig) and builtins.d.bp does not declare it`` and
  ``builtin `@RecordKeys`: the compiler implements `…-> string[]`, builtins.d.bp declares `…-> string` ``)
- [x] `zig build test`, `test-language`, `test-docs` green (and `test-libs`: 123 passed, 0 failed; `tsc-check`)

### Step 4 — a variadic parameter, and the three print builtins declared with it (decision 267)

`..name: T[]` as a function's last parameter: at most one, no default, no label; a call passes zero
or more positional arguments after the fixed ones, each checked against `T`; the body reads `name`
as a `T[]`. No spread at the call site. commonJS lowers it as a rest parameter, erlang/beam as one
list argument, wasm as one array.

**Acceptance:**
- [ ] parser and formatter: `fn f(a: i32, ..rest: string[])` round-trips through `botopink format`
- [ ] refused, located: a variadic that is not last, two variadics, a default on one, a type that is
      not `T[]`, a spread `f(..xs)` at a call (`reject/` cells, one per refusal)
- [ ] `run/variadic_parameter` on the four targets — zero, one and three arguments, a method and a
      `declare fn` bound to a host function
- [ ] `builtins.d.bp` declares `print`, `println` and `debug` as `(..values: unknown[])`; the three
      rows of `comptime/builtins.zig` held to `declaration`; the four cells that pass two arguments
      unchanged and green

## Gate

- [ ] `scripts/gate.sh --cold` green on the integrated branch
- [ ] `bash scripts/format-check.sh` and `zig fmt --check modules` before every commit
- [ ] every `AGENTS.md` of a touched directory updated in the same commit
- [ ] commits on `front/134-builtins-declared`; no push, no merge — landing is the coordinator's step
