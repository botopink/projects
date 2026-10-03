# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1 and 3 on feat; step 2 partial (the builtin calls
declared; the type functions, the `result` namespace, the `@Result` / `?T` methods and `@is` open)
**Depends on:** 134-a, 134-b, 134-c, 134-d (open questions)
**Owns:** `libs/std/src/builtins.d.bp`, `libs/std/src/builtins_fns.d.bp` (with 130 for the `Decl`
surface) · the compiler's builtin table and the check that ties it to the declarations
(`modules/compiler-core/src/comptime/builtins.zig`, `Env.builtinDecls`, `comptime.zig`
`registerBuiltinDecls`, `infer.zig` `checkBuiltinArguments`) · `docs.md` § Builtins · the
`tests/language/reject/` cells for a builtin call the declaration refuses · the `AGENTS.md` of each
directory touched
**Does not touch:** what a builtin does on any backend (its owner front's) · decorator outputs (130)

## Goal

Decision 252: every builtin reachable from a program — a `@name(…)` call, a `@name` type or value,
a builtin type with static members — is declared in `builtins.d.bp` (or `builtins_fns.d.bp`), a unit
test holds the compiler's implementation to the declarations, and `docs.md` documents each builtin
from its declaration.

## Done

- Step 1 — the inventory: twenty-one builtin calls (`comptime/builtins.zig` `table`, reached from `infer.zig` `inferBuiltinCallReturnType`)
- Step 2, the calls — every builtin call declared (two the closest honest declaration: `@print`/`@println`/`@debug` for 134-a, `@TypeInfo.all`'s `with:` for 134-b); `@typeInfo.all` renamed `@TypeInfo.all` (decision 253); the catalogue typed `Declared<unknown>[]` (254) with `returnTypeName` (256) — `run/typeinfo_all_unknown_value`, `reject/typeinfo_all_value_unknown`
- Step 3 — the check: `builtins.zig` `collectDeclared` / `drift` and its tests (a removed declaration, a changed signature, a declaration with no implementation each red it); `builtin-arguments` at the call (`reject/builtin_arguments`); `docs.md` § Builtins with its `docs-check: reject builtin-arguments` fence

## Open

### Step 2 — declare the rest

Not declared yet: the comptime type functions called without `@` — `mergeRecords`, `partial`,
`omit`, `pick` (`infer.zig` `tryResolveTypeManipulationCall`); the builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`) and the `@Result` / `?T` methods (`map`, `flatMap`,
`unwrapOr`, `isOk`, `isError`), today comments in `builtins.d.bp`; `@is(…)` (the parser's carrier of
`x is T`, `ast.is_builtin_name` — written by hand `@is(1)` types `bool` with no tested type, 134-d);
two naming differences — `@ExprCustom<T>` is declared as `CustomExpr<T>`, the mirror's
`Annotation(name, args)` is `DeclAnnotation`. The check covers the builtin calls; the types are not
walked yet.

- [ ] every builtin above declared; the drift test walks the types and their methods too
- [ ] `docs.md` § Builtins generated from or checked against the declarations

## Decisions

- **134-a** — `@print`, `@println` and `@debug` take any number of arguments (`@print(a, b)` in four
  `tests/language/run` cells): a variadic declaration, or one argument
- **134-b** — the type of `@TypeInfo.all`'s `with:` (declared `unknown` today)
- **134-c** — what `@getContext(T)` answers (declared `-> T`)
- **134-d** — `@is(…)` written by hand

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
</content>
</invoke>
