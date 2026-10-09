# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1, 3 and 5 done; step 2 partial (calls, `@Result`'s
methods, the mirrored types and `@is` held; std's `Type` declared but for `pick` / `omit` / `Field<T>`;
`?T` methods and the `result` namespace open on `134-e`); steps 4 and 6 (decisions 267, 269) open
**Depends on:** `134-e` (step 2's last declarations) · answered: 134-d → 322, 134-a → 267, 134-b → 268, 134-c → 269
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
- Step 2, `@is` (322) — a hand-written `@is(…)` (no `isType`) is `unknown-builtin: unknown builtin `@is` — `is` is an operator` at the `@`, hint naming `x is T`; `ast.zig`'s doc on `is_builtin_name` corrected — `infer error: hand-written is builtin is refused` (`snapshots/comptime/errors/hand_written_is_builtin_is_refused.snap.md`), `reject/hand_written_is_builtin` (`5:13`); `x is i32` prints `true`
- Step 2, types — the drift test walks the types: `builtins.zig` `collectTypes` / `typeDrift` hold every type the compiler mirrors (`comptime.zig` `builtin_type_mirrors`: the `@Decl` cluster, `CustomNode`, `TypeInfo`, `RecordField`, `YieldStep`) to its declaration — fields, variants, instance methods, `__Decl__X` read through its alias — and `methods` (`Result`'s `map`, `flatMap`, `unwrapOr`, `isOk`, `isError`, declared in the enum's body; `infer.zig` reads `hasMethod`) to the owner's `declare fn`s; tests red a mirrored field the declaration lacks, a mirror under another name, a method with another signature, a missing one and an extra one. The two naming differences closed: `CustomExpr<T>` declared `ExprCustom<T>`, the mirror's alias `Annotation` is `DeclAnnotation`; the stale `@block` tail and `$stringify` comments corrected
- Step 2, std `Type` (307) — `libs/std/src/types.bp` declares `pub type Type()` with `keys`, `partial`, `required`, `merge` (`comptime source: type T` → `type`, bodyless: the checker is the body); `root.bp` exports `types` — `run/std_types_module` on the four targets
- Step 5 (268) — `builtins.d.bp` declares `pub behavior Decorator {}` and `all(with: Decorator | Decorator[], member: ?string = null)`; the row held `.declaration`, drift green. `infer.zig` `checkCatalogueArguments` types `with:` by `decoratorArgumentType` (a name of a body-carrying `comptime _: @Decl` function is `Decorator`, an array literal of them `Decorator[]`) and holds the call to the declaration; `typeinfo_all.plan` leaves a query naming anything else unanswered; `typeinfo-all-not-decorator` removed, its cell moved to `reject/typeinfo_all_with_ordinary_fn` beside `reject/typeinfo_all_with_number` (the ordinary mismatch at the argument); `run/typeinfo_all_decorator_argument` (a decorator with an argument, a single one, a list) on the four targets; `docs.md` § Builtins

## Open

### Step 2 — declare the rest

Left undeclared: `?T`'s methods (`map`, `flatMap`, `unwrapOr`) and the builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`) — prose in `builtins.d.bp` until `134-e` (1) says how they are
spelled; `Type.Field<T>` and `Type.pick` / `Type.omit`.

- [ ] `?T`'s methods and the `result` namespace declared as `134-e` (1) answers, rows in `builtins.zig`
      `methods` (or the namespace gone)
- [ ] `Type` also declares the associated type `Field<T>` (decision 308; spelling `134-e` (2)), `keys`
      answering it; `builtins.d.bp`'s `Field` record leaves, `Decl.fields` typed `Type.Field<unknown>[]`;
      `pick` / `omit` declared with the variadic `comptime ..fields: Type.Field<T>[]` (after step 4); the
      `Type` spelling as `134-e` (3) answers
- [ ] the four bare names (`partial`, `pick`, `omit`, `mergeRecords`) leave `tryResolveTypeManipulationCall`
      when `01-checker` step 28 keys its resolver on `Type`
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

Open: `134-e` (step 2 — how `?T`'s methods and `result`, `Type.Field<T>` and a type of static
functions are spelled). Answered: 322 (`@is` refused, step 2), 267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
