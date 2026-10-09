# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1, 3, 4 and 5 done; step 2 partial (calls, `@Result`'s
methods, the mirrored types and `@is` held; std's `Type` declared with `pick` / `omit`, `Decl.fields`'
`Type.Field<unknown>` open; `?T` methods and the `result` namespace removed under 330); step 6 partial
(the hook typed and refused bare; its run cell waits on `134-f`)
**Depends on:** `134-f` (step 6's run cell; decision 352 needs it lowered — `styled`'s render-time registration) · answered: 134-e → 329, 330, 134-d → 322, 134-a → 267, 134-b → 268, 134-c → 269
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
- Step 4 (267) — `..name: T[]` parsed (`Param.variadic`; `comptime ..name: T[]` too) and formatted back; refused at the
  declaration: `variadic-not-last` (at the first `..`), `variadic-twice` (at the second), `variadic-default` (at the `=`),
  `variadic-not-array` (at the type). `infer.zig` `variadicCalleeParams` / `packVariadicCall`: a call of a free fn, an
  imported one, a method or an associated fn whose last parameter is variadic is typed with the arguments past the fixed
  ones packed into one array literal (`variadicPacked`), spliced by `transform.zig`; `variadic-spread` (`f(..xs)`),
  `variadic-label` (a label on a variadic argument, a trailing lambda), `'f' expects at least N argument(s)`. erlang,
  beam and wasm read one list / array; commonJS a rest parameter (`function f(a, ...rest)`, the call's elements written
  back — `Math.max(3, 9, 4)`), `.d.ts` `...rest: T[]`. `builtins.d.bp` declares `print`, `println`, `debug` as
  `(..values: unknown[])`, the rows held `.declaration` (`checkDeclaredArguments` binds the variadic), `Held.open_question`
  removed — `run/variadic_parameter`, `run/variadic_parameter_host` (wasm refuses the host fn by `wasm.expect`),
  `modules/variadic_across_modules`, `reject/variadic_{not_last,twice,default,not_array,label,spread_at_call}` (all red on
  the parent); the twenty cells that pass `@print` zero or two-plus arguments green on the four targets; `format: a
  variadic parameter keeps its `..``; `docs.md` § A variadic parameter (`docs-check: reject variadic-spread`)
- Step 6 (269), but its run cell — `builtins.d.bp` declares `getContext<T>(comptime _: type) -> Component<T, T>` (row and
  drift green); after RC5, RC4 and RC3 the arm answers `Component<T, T>` and a call that is not `use`'s operand
  (`Env.useOperandLoc`) is `context-getcontext-without-use` at the `@`; `use` reads it as a `T` — `infer: use
  @getContext(T) reads the context as a T`, `infer error: use @getContext(T) is a T, not anything else`
  (`found: BasePagamento`), `reject/getcontext_without_use` (`8:15`, red on the parent); the three
  `context-getcontext-*` snapshots unchanged; `docs.md` § Builtins and § use show the `use` form
- Step 2, `Type.pick` / `Type.omit` — `types.bp` declares both `(comptime source: type T, comptime ..fields:
  Type.Field<T>[]) -> type`, bodyless; std tests green on erlang and commonJS
- Step 5 (268) — `builtins.d.bp` declares `pub behavior Decorator {}` and `all(with: Decorator | Decorator[], member: ?string = null)`; the row held `.declaration`, drift green. `infer.zig` `checkCatalogueArguments` types `with:` by `decoratorArgumentType` (a name of a body-carrying `comptime _: @Decl` function is `Decorator`, an array literal of them `Decorator[]`) and holds the call to the declaration; `typeinfo_all.plan` leaves a query naming anything else unanswered; `typeinfo-all-not-decorator` removed, its cell moved to `reject/typeinfo_all_with_ordinary_fn` beside `reject/typeinfo_all_with_number` (the ordinary mismatch at the argument); `run/typeinfo_all_decorator_argument` (a decorator with an argument, a single one, a list) on the four targets; `docs.md` § Builtins

## Open

### Step 2 — declare the rest

Left: `?T`'s methods (`map`, `flatMap`, `unwrapOr`) and the builtin `result` namespace
(`result.map/then/unwrap/isOk/isError`), prose in `builtins.d.bp` — under 330 the first leave and the
second is deleted; `Type`'s namespace-type spelling (329), `Type.Field<T>` and `Type.pick` / `Type.omit`.

- [x] the rest declared under 330: `?T` declares no method (its surface is `01-checker` step 31's operators) — the
      `?T` rows (`map`, `flatMap`, `unwrapOr`) leave `infer.zig` `inferResultOptionMethod`; the `result` namespace
      (`inferResultNamespaceCall`) is deleted, not declared; the prose in `builtins.d.bp` goes
- [x] std's `types.bp` spells `pub type Type { … }` — a namespace type, no field list and no value (329): `Type()`
      refused, a `self` function in its body refused
- [ ] `Type` also declares the associated type `Field<T>` inside its body (308, 330), `keys` answering it —
      declared (`pub type Field<T>(name, typeName, annotations)`, `run/std_type_field_associated`);
      `builtins.d.bp`'s `Field` record leaves, `Decl.fields` typed `Type.Field<unknown>[]` — open: the record
      `decl.fields` hands out is the compiler's `__Decl__Field` (`comptime.zig` `decl_reflection_src`, aliased
      `Field` and drift-checked against `builtins.d.bp`'s `Field`), so std's hoisted `Type__Field` has to become
      that record, and rakun-data's `orm/entity.bp` (`fn marked(f: Field, …)`) moves to `Type.Field<unknown>`; `pick` /
      `omit` are declared (Done); the spelling of a `type` answer is fixed here with `01-checker` step 28
- [ ] the four bare names (`partial`, `pick`, `omit`, `mergeRecords`) leave `tryResolveTypeManipulationCall`
      when `01-checker` step 28 keys its resolver on `Type`
- [ ] [`examples/types.bp`](./examples/types.bp) — the whole `Type` surface, signatures and results —
      compiles and passes on the four targets; its "does not compile" lines are `01-checker` step 28's
      `reject/` cells; `Type.merge` with a field on both sides is an error, `Type.required` drops every `?`
- [ ] `docs.md` § Builtins generated from or checked against the declarations

### Step 6 — `@getContext(T)` is a hook (decision 269)

`builtins.d.bp` declares `getContext<T>(comptime _: type) -> Component<T, T>`; the checker's RC3 arm
types the call as that declaration instead of `T`. `use @getContext(T)` reads the context as a `T`;
the bare call is refused.

- [ ] `val ctx = use @getContext(BasePagamento);` — the typing is done (Done); the `run/` cell on the
      four targets waits on `134-f`: no backend lowers `@getContext` (commonJS writes `await
      @getContext(BasePagamento)` verbatim, a syntax error; erlang calls an undefined `getContext/1`;
      wasm refuses it, no lowering), and what it reads at run time (RC1's provider stack) is not decided

## Decisions

Open: `134-f` (what `use @getContext(T)` is at run time — step 6's run cell). Answered: 329, 330 (`134-e`: a namespace type, `?T` methodless, `result` deleted,
`Type.Field<T>` associated — step 2), 322 (`@is` refused, step 2), 267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
