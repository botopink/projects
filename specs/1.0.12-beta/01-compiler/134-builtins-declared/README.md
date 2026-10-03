# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1 and 3 on feat; step 2 partial (builtin calls
declared; type functions, `result` namespace, `@Result` / `?T` methods and `@is` open); steps 4–6
(decisions 267–269) open
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

### Step 4 — a variadic parameter, and the three print builtins declared with it (decision 267)

`..name: T[]` as a function's last parameter: at most one, no default, no label; a call passes zero
or more positional arguments after the fixed ones, each checked against `T`; the body reads `name`
as a `T[]`. No spread at the call site. commonJS lowers it as a rest parameter, erlang/beam as one
list argument, wasm as one array. With `01-checker` (parser, checker) and the backend fronts.

- [ ] parser and formatter: `fn f(a: i32, ..rest: string[])` round-trips through `botopink format`
- [ ] refused, located: a variadic that is not last, two variadics, a default on one, a type that is
      not `T[]`, a spread `f(..xs)` at a call (`reject/` cells, one per refusal)
- [ ] `run/variadic_parameter` on the four targets — zero, one and three arguments, a method and a
      `declare fn` bound to a host function
- [ ] `builtins.d.bp` declares `print`, `println` and `debug` as `(..values: unknown[])`; the three
      rows of `comptime/builtins.zig` held to `declaration`; the four cells that pass two arguments
      unchanged and green

### Step 5 — the `Decorator` type, and `with:` declared with it (decision 268)

`Decorator` is a builtin type in `builtins.d.bp`: a name has it when it names a function whose first
parameter is `comptime _: @Decl` (further arguments included); nothing else is assignable to it, and
it cannot be constructed. `TypeInfo.all` declares `with: Decorator | Decorator[]`.

- [ ] `builtins.d.bp` declares `Decorator` and `all(with: Decorator | Decorator[], member: ?string = null)`;
      the drift test green on the new signature
- [ ] `@TypeInfo.all(with: 42)` and `with: someOrdinaryFn` refused as the ordinary mismatch, located
      at the argument (`reject/` cells); `typeinfo-all-not-decorator` removed with its cell moved
- [ ] a decorator with arguments, a single decorator and a list of them accepted (`run/` cell on the
      four targets)

### Step 6 — `@getContext(T)` is a hook (decision 269)

`builtins.d.bp` declares `getContext<T>(comptime _: type) -> Component<T, T>`; the checker's RC3 arm
types the call as that declaration instead of `T`. `use @getContext(T)` reads the context as a `T`;
the bare call is refused.

- [ ] `val ctx = use @getContext(BasePagamento);` types `ctx` as `BasePagamento` (`run/` cell on the
      four targets, inside a `-> @Component<…>` body)
- [ ] `@getContext(BasePagamento)` without `use` refused, located, naming `use` (`reject/` cell)
- [ ] the three existing `context-getcontext-*` refusals unchanged; the drift test green on the new
      signature; `docs.md` § Builtins shows the `use` form

## Decisions

134-d (`@is(…)` by hand) — in [`../../decisions-pending.md`](../../decisions-pending.md). Answered:
267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
