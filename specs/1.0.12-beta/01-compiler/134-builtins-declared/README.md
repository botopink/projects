# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1 and 3 on feat; step 2 partial (builtin calls
declared; type functions, `result` namespace, `@Result` / `?T` methods and `@is` open)
**Depends on:** 134-d (open question) · answered: 134-a → 267, 134-b → 268, 134-c → 269
**Owns:** `libs/std/src/builtins.d.bp`, `libs/std/src/builtins_fns.d.bp` (with 130 for the `Decl`
surface) · compiler's builtin table and the check tying it to the declarations
(`modules/compiler-core/src/comptime/builtins.zig`, `Env.builtinDecls`, `comptime.zig`
`registerBuiltinDecls`, `infer.zig` `checkBuiltinArguments`) · `docs.md` § Builtins ·
`tests/language/reject/` cells for declaration-refused builtin calls · `AGENTS.md` of each touched dir
**Does not touch:** what a builtin does on any backend (its owner's) · decorator outputs (130)

## Goal

Decision 252: every builtin a program reaches (`@name(…)` call, `@name` type or value, builtin type
with static members) declared in `builtins.d.bp` (or `builtins_fns.d.bp`); a unit test holds the
implementation to the declarations; `docs.md` documents each from its declaration.

## Done

- Step 1 — inventory: twenty-one builtin calls (`comptime/builtins.zig` `table`, from `infer.zig` `inferBuiltinCallReturnType`)
- Step 2, calls — every builtin call declared (two closest-honest: `@print`/`@println`/`@debug` for 134-a, `@TypeInfo.all`'s `with:` for 134-b); `@typeInfo.all` → `@TypeInfo.all` (253); catalogue typed `Declared<unknown>[]` (254) with `returnTypeName` (256) — `run/typeinfo_all_unknown_value`, `reject/typeinfo_all_value_unknown`
- Step 3 — check: `builtins.zig` `collectDeclared` / `drift` + tests (removed declaration, changed signature, declaration without implementation each red it); `builtin-arguments` at the call (`reject/builtin_arguments`); `docs.md` § Builtins with its `docs-check: reject builtin-arguments` fence

## Open

### Step 2 — declare the rest

Undeclared: comptime type functions called without `@` — `mergeRecords`, `partial`, `omit`, `pick`
(`infer.zig` `tryResolveTypeManipulationCall`); builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`) and `@Result` / `?T` methods (`map`, `flatMap`, `unwrapOr`,
`isOk`, `isError`), today comments in `builtins.d.bp`; `@is(…)` (parser's carrier of `x is T`,
`ast.is_builtin_name` — hand-written `@is(1)` types `bool` with no tested type, 134-d); two naming
differences — `@ExprCustom<T>` declared as `CustomExpr<T>`, mirror's `Annotation(name, args)` is
`DeclAnnotation`. The check covers calls; types not walked yet.

- [ ] every builtin above declared; the drift test walks the types and their methods too
- [ ] `docs.md` § Builtins generated from or checked against the declarations

## Decisions

134-d (`@is(…)` by hand) — in [`../../decisions-pending.md`](../../decisions-pending.md). Answered,
to build in step 2: 267 (`@print`/`@println`/`@debug` declared variadic, `..values: T[]`), 268
(`with:` takes the builtin type `Decorator`), 269 (`@getContext(T)` is a hook, behind `use`).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
