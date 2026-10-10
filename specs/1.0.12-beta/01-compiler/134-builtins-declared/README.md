# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high · **State:** partial: steps 1, 3, 4 and 5 done; step 2 partial (calls, `@Result`'s
methods, the mirrored types and `@is` held; std's `Type` declared with `pick` / `omit`, `Decl.fields`'
`Type.Field<unknown>` open; `?T` methods and the `result` namespace removed under 330); step 6 (354, 357)
partial: boxes 1, 2, 5 (357) and 6 (the codemod) done; box 4's hidden map on erlang, beam and commonJS is
rewritten by 388 (a component is a lambda over a `RenderScope`), after the measurement box; box 3 waits on
`01-checker` step 23 (277)
**Depends on:** step 6: backend fronts 02–05 and 18 for each lowering of 388's lambda · answered: `134-f` → 354, 134-e → 329, 330, 134-d → 322, 134-a → 267, 134-b → 268, 134-c → 269
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
- Step 6 box 1 (354 (1)) — `@Component<R>`: the parser refuses `@Component<C, R>` at the base
  (`generic-arg-count-exceeded`, naming `@Component<R>`), `@Context<…>`
  (`context-marker-removed`, naming `implement @Renderable`) and `@Renderable<…>`; `builtins.d.bp` declares
  `pub behavior Renderable {}` and `Component<R> extends Task`, `Context<Base>` and `getContext` gone with the
  `context-getcontext-*`, `context-anchor-violation` and `effect-wrapper-mismatch` codes and decision 96's one
  base per body; `TypeDef.isRenderable` tells a component from a `@Component` read with `use`; a hand-written
  `@getContext(…)` is `unknown-builtin` naming `use context(C)` — `reject/component_base_parameter`,
  `reject/context_marker_removed`, `reject/renderable_type_argument`, `reject/getcontext_removed` (each red on
  the parent); `parser: decision 354 — …` (`effect_rejections.zig`)
- Step 6 box 2 (354 (2), (3)) — std's `context` module: `Context<T>()`, `provide`, `context` (`use` only,
  lowered by the compiler); `use-outside-render-tree` in a decorator body, a template body and a `comptime`;
  `context-hook-without-use`, `context-not-declared` (a `Context<T>()` that is not a module-level `val`'s whole
  initializer, a `val` naming another context, a context named by a local or a parameter),
  `context-provide-outside-component` (a body whose `R` is not `@Renderable`, or a provide that is not a
  statement of its own) and `context-provide-after-render` — `reject/use_in_comptime_block`,
  `reject/use_in_decorator_body`, `reject/use_in_template_body`, `reject/context_hook_without_use`,
  `reject/context_hook_as_value`, `reject/context_not_declared`, `reject/context_val_alias`,
  `reject/context_read_of_parameter`, `reject/context_provide_in_hook`, `reject/context_provide_after_render`,
  `reject/context_provide_bound`
- Step 6 box 4, on erlang, beam and commonJS (354 (8)) — `comptime/context_lower.zig` over the transformed
  module: the hidden `bpContextMap__` on every function whose type answers `@Component<R>` (aliases, methods,
  `implement` methods, function types and `is` tests included), the children map after each `use provide`,
  `use context` a lookup in std's `context.find` (`context-unbound` at run time); a host function is called
  with no map and a `@Component` value handed to it keeps the map as its first parameter — a host that calls one
  passes `null` (jhonstart's `jhonstart_signal`) — `run/context_provide_read`, `run/context_nearest_wins`,
  `run/context_unbound` (`.exit`, `.<t>.stderr`) on the three; wasm refuses the `use` (`.wasm.expect`,
  `language-gaps.md` 354-wasm)
- Step 6 box 5 (357) — `use-not-top-level` in the checker (`Env.useConstruct`, `Env.earlyExitLine`), the
  parser's static-prefix rule gone — `reject/use_in_if`, `reject/use_in_loop`, `reject/use_in_lambda`,
  `reject/use_after_early_return`, `run/use_conditional_argument`; `reject/use_after_return` and
  `reject/generator_loop_use` meet it; the short-circuit operands too (410)
- Step 6 box 6 — `scripts/codemod-component-contexts.py` (`scripts/AGENTS.md`); run over botopink-lang, jhonstart,
  onze, styled, rakun and the VS Code extension (patches); no `use @getContext(T)` remained to report
- Step 2, `Type.pick` / `Type.omit` — `types.bp` declares both `(comptime source: type T, comptime ..fields:
  Type.Field<T>[]) -> type`, bodyless; std tests green on erlang and commonJS
- Step 6 box 4, host thunks (374) — `infer.zig` `noteHostCall` records every call of a host function, this
  module's or an imported one (`Env.hostCalls`), and a declared `@Component` named as its argument
  (`Env.hostComponentRefs`); `context_lower.zig` `lowerHostArg` walks a `@Component` lambda written as a host
  argument under the enclosing frame (no hidden parameter: it reads the map where it is written) and
  `hostThunk` wraps a named one as `{ a0 -> C(<map>, a0) }`; a host's parameter types keep their written arity —
  `run/context_host_thunk` (a thunk called at once, one with the host's argument, a named component, and one
  the host keeps and `main` calls twice after the render) green on erlang, beam and commonJS and red on the
  parent (`context-unbound` / `badarity`); wasm refuses the `use` (`.wasm.expect`, unchanged); the comptime
  runtimes do not lower the map (354-comptime); `run/context_provide_read`, `run/context_nearest_wins` green;
  jhonstart's `styled_sheet_test` "a page under an error segment writes its sheet" (patch)
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
- [ ] `Expr`'s surface for 415 and 426: `lookup(name)` answers `?Decl<unknown>` (the `Binding` record goes), `build<R>`'s
      `R` is the type the built code infers to, `note(message)` declared — the drift test follows
- [ ] `docs.md` § Builtins generated from or checked against the declarations

### Step 6 — contexts: `@Component<R>`, `use provide` / `use context` (decision 354, replaces 269)

```bp
import {context.createContext} from "std";

pub val themeContext = comptime createContext(Theme(mode: .Light));   // declares Theme's default (378, 379)

fn App() -> @Component<Element> {
    use provide(createContext(Theme(mode: .Dark)));   // for everything App renders below it
    return <Page />;
}

fn Button() -> @Component<Element> {
    val theme = use context(Theme);                    // the nearest Theme above, else the default
    …
}
```

- [x] `@Component<R>`: `@Component<C, R>` a type-arity error naming `@Component<R>`; a component is the
      `@Component<R>` whose `R` implements `@Renderable`, any other `@Component<R>` read with `use` (no `@Hook`: `@Component` is the one wrapper); `@Context<C>` and
      `@getContext` leave `builtins.d.bp` (`context-getcontext-*` codes go with them)
- [x] std declares `Context<T>`, `provide(ctx: Context<T>, value: T)` and `context(ctx: Context<T>) -> T`
      as hooks (`use` only); `use` inside a decorator body, a template body or a `comptime { … }` refused,
      located (354 (3))
- [x] `Decl.hooks` (277) carries each `provide` / `context` with its object, for the frameworks' build check (354 (4)) —
      built with `01-checker` step 23 (`front/checker-s23`): `HookUse.context: ?Declared<unknown>`, the `val` that
      declares the context (`run/decl_hooks_context`; the field's name is s23-a)
- [ ] measure before the rewrite (388 (6)): onze's blog rendered 1 000 times on erlang and commonJS, today's
      hidden map against one lambda per component call; the numbers in this README; a cost the front judges
      too high comes back as a question before box 4b
- [ ] box 4b, a component is a lambda over a `RenderScope` (388): `fn C(…) -> @Component<R>` lowers to a function
      answering `(scope) => …`, a call runs nothing; std's `context` declares the opaque `RenderScope`
      (`RenderScope.root()`) and `c.run(scope)` (the result and the children's scope; a `@Task` for a node 375
      marks asynchronous); `use provide(ctx)` makes the children's scope, `use context(T)` reads the received
      one or the default; `await c` in a body runs `c` with the children's scope — `run/component_is_lambda`
      (`itens.map(Card)` answers lambdas, the template's tree runs them with `Lista`'s scope),
      `run/context_provide_read`, `run/context_nearest_wins`, `run/component_run_root` on erlang, beam,
      commonJS, wasm and both comptime runtimes (handed to 02–05 and 18); the built map lowering
      (`comptime/context_lower.zig`, 374's `lowerHostArg`) replaced, not kept beside it; lands with jhonstart's
      renderer under 414 (`05-jhonstart/26` step 14: boundaries and fills as nodes the renderer runs with the scope —
      the suite back at 207 / 0 on erlang from 173 / 34)
- [ ] until box 4b lands, a `@Component` value handed where the parameter's declared type is not a written
      `fn(…) -> @Component<…>` is refused at build (`component-value-to-generic`, naming the template's `for`)
- [ ] every context declares its default, named by its value's type (378, 379): std's `context` module
      answers `createContext(value)`, `provide(ctx)`, `context(T)`, and `Context<T>()` goes; one module-level
      declaration per type (a second refused naming both), found through the catalogue; a read answers the
      nearest context of its type or the declared default on every target (`context-unbound` goes,
      `run/context_default`), a type with no declaration refused at the read (`reject/context_undeclared_type`);
      `comptime createContext(…)` refuses a run-time argument; the codemod over `tests/language` (20 cells),
      `styled`, jhonstart
- [ ] dependency injection over contexts (416): `createContext(value, Behavior)` keys the context by the behavior,
      the value checked to implement it (`reject/context_behavior_not_implemented`); `use inject(T)` builds the record
      `T` from the context of each field's type — provided above, else the declared default, else the field's default,
      else an error at build naming the field (`reject/inject_field_undeclared`); a behavior refused
      (`reject/inject_behavior`) — `run/inject_record`, `run/inject_behavior_keyed`, `run/inject_test_root_fake`
      (a test's root providing a fake) on the four targets; `docs.md` § Contexts
- [ ] a context read known at build (379 (6)): every `createContext` that can reach it of build and of one
      value, or none — computed from the hooks list from the roots; the reading function then `Any` with build
      arguments — `run/context_read_at_build` (`corDoTema()` a constant when `Theme` is never provided),
      `run/context_read_run_time` (a provide from `use request()` keeps it at run time)
- [ ] a `Build` / `Any` component called at build (378 (4)): the comptime runtime runs its lambda with
      `RenderScope.root()` (388; the comptime-runtime half of box 4b), a context answering
      its providers within the tree or its default — `run/comptime_render_component`
      (`comptime renderToString(<Rodape ano={2026} />)` a constant), `reject/component_run_hook_at_build`
- [x] the rules of hooks (357): `use` only at the top level of a `@Component` body —
      `error[use-not-top-level]` inside `if` / `else`, a `case` arm, a loop, a lambda, `try` /
      `catch`, or after a statement that may return early, naming the enclosing construct;
      `reject/use_in_if`, `reject/use_in_loop`, `reject/use_in_lambda`, `reject/use_after_early_return`;
      `run/use_conditional_argument` (`use provide(Ctx, if (c) a else b)` accepted)
- [x] the codemod: `@Component<C, R>` → `@Component<R>`, `implement @Context<C>` → `implement @Renderable`,
      `use @getContext(T)` reported at its line (no mechanical rewrite: the provider is the author's)

## Decisions

`134-g` → 388 (a component is a lambda over a `RenderScope`, run by the render library); `134-i` → 387, replaced by 388.

Answered: `134-f` → 354 (contexts), 329, 330 (`134-e`: a namespace type, `?T` methodless, `result` deleted,
`Type.Field<T>` associated — step 2), 322 (`@is` refused, step 2), 267 (step 4), 268 (step 5), 269 (step 6).

**Gate:** standard (fronts.md § Gate) + `zig build test-language`, `test-docs`, `test-libs`, `tsc-check` green
