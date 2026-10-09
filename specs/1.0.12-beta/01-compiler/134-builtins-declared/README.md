# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1 and 3 on feat; step 2 partial (builtin calls
declared; type functions, `result` namespace, `@Result` / `?T` methods and `@is` open); steps 4–6
(decisions 267–269) open
**Depends on:** nothing open · answered: 134-d → 322, 134-a → 267, 134-b → 268, 134-c → 269
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
`ast.is_builtin_name` — hand-written `@is(1)` types `bool` with no tested type; refused by 322); two naming
differences — `@ExprCustom<T>` declared as `CustomExpr<T>`, mirror's `Annotation(name, args)` is
`DeclAnnotation`. The check covers calls; types not walked yet.

- [ ] every builtin above declared; the drift test walks the types and their methods too
- [ ] `@is(…)` written by hand is refused (322; 252: a builtin not declared in `builtins.d.bp` is unknown, and
      `builtins.d.bp` declares no `is`). Where: `comptime/infer.zig`, `inferCallExpr`'s `call.is_builtin` arm for
      `ast.is_builtin_name` — today it types `bool` whether or not `isType` is set; a call with `isType == null`
      (only a hand-written `@is(…)`: the parser's carrier of `x is T` always sets it) returns
      `unknown-builtin: unknown builtin `@is` — `is` is an operator`, hint "Test a type with the operator: `x is T`.",
      located at the `@`. `isKnownBuiltinName` keeps `is` / `[]` for the parser's carriers only; `ast.zig`'s doc
      on `is_builtin_name` stops saying no source can write the call. Cells: `infer error: hand-written is builtin
      is refused` (`snapshots/comptime/errors/hand_written_is_builtin_is_refused.snap.md`) and
      `tests/language/reject/hand_written_is_builtin` (`val b = @is(1);` on line 5 → `.expect` the message and
      `5:13`); `x is T` unchanged — measured on a scratch build: the refusal located at `5:13`, `x is i32` prints
      `true`
- [ ] std's `types.bp` declares `pub type Type { … }` — a namespace type, no field list and no value (329):
      `Type()` refused, a `self` function in its body refused — with five static compile-time methods answering a type
      (decision 307): `partial`, `required` (new), `pick`, `omit`, `merge` (was `mergeRecords`) —
      `pub fn pick<T>(comptime source: type T, comptime ..fields: Type.Field<T>[]) -> type`, the spelling of a
      `type` answer fixed here with `01-checker` step 28; bodies are the compiler's; `root.bp` exports
      `types`; the four bare names leave the builtin list
- [ ] `Type` also declares the associated type `Field<T>` and `keys<T>(comptime source: type T) -> type`
      (decision 308); `builtins.d.bp`'s `Field` record leaves, `Decl.fields` typed `Type.Field<unknown>[]`
- [ ] [`examples/types.bp`](./examples/types.bp) — the whole `Type` surface, signatures and results —
      compiles and passes on the four targets; its "does not compile" lines are `01-checker` step 28's
      `reject/` cells; `Type.merge` with a field on both sides is an error, `Type.required` drops every `?`
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
      the drift test green on the new signature (`member` becomes a reference with 281 —
      `130-decorator-outputs` step 7)
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

None open. Answered: 322 (`@is` refused, step 2), 267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
