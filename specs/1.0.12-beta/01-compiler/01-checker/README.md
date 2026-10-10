# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17, 19, 20 on feat; step 18 built on
feat (botopink-lang `49455602` merges `19d59508`, `6185db3c`) with one box open; step 24 built on
`front/checker-s24` but three boxes; step 23 built on `front/checker-s23` and `front/decl-hooks-371-372` (371, 372); step 28 built on `front/checker-s28` but `Type.keys` and the run-time `Type.Field<T>`; step 6
box 3, steps 13, 21, 22, 24–33 and ten rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `05-wasm` nested
constructor in a `val` (step 13) · `08-bpp/116` prelude list (step 22) · (lg2-q answered by 403, by design: `@Decl` carries no source location; lg2-a is step 32, decision 346;
lg2-e answered by 347 with nothing to build: a method's `@Decl` has no `owner`).
**Owns:** `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error,diagnostics}.zig`
· `src/parser/**`, `src/parser.zig`, `src/print.zig`, `src/lexer.zig`, `src/lexer/**` · `src/ast.zig`
(node fields its steps add) · `snapshots/comptime/**`, `snapshots/parser/**` · its cells under
`tests/language/` (one file per cell)
**Does not touch:** `src/codegen/**` (02–05) · `src/comptime/runtime/**`, `template_eval.zig`,
`decorator_eval.zig` (14, 18) · `src/format.zig`, `src/format/**`, `ast.zig` trivia fields (16) ·
`parser.zig`'s `isBracedBlockStmt` and `blockStatementSemicolon` kind (16's C-13 patch, after this
front's parser rows) · `modules/compiler-cli/**`, `modules/language-server/src/**` (26) ·
`libs/std/**` (std track)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

Accepted ⇒ every backend gives decision 8's answer; refused ⇒ located, by name. Open rows become
four-target cells; checker gains decisions 270 (prelude scope), 247 (suffixes), 255 (two forms).

## Done

Steps: 1 literal join `[1, "a"]` is a union (decision 150) · 2 function-typed `case` arms join
structurally; lambda as arm value · 3 `section-body-method` (decision 151); numeric section leaf
standalone · 4 record value called = `callee-not-a-function` · 5 `binding-redeclared` at decision
205's reach (152, 205) · 6 boxes 1, 2, 4 `try` in a lambda (147) · 7 captured-`var` write refused
(148) · 8 tuple label through `?T` (45) · 9 ck2-c (244, built as step 17) · 11 tuple after `??`,
postfix read on `( … )` · 12 `unknown` as binding = `reserved-word-as-name` · 14 `primitives.d.bp` /
`@external(` comment sweep · 15 imported type re-checked at a second import site keeps field types ·
16 inline parameter type (207) · 17 default trailing everywhere (244). Decisions 208, 209, 215 —
`Ok`/`Error` never constructors; integer literal under `f64`; `f64 == 1` refused. Rows: an `@block`
used as a value with no valued `return` is `block-tail-value` (decision 2; `reject/block_tail_value`)
· `$stringify` in an `@External` template is `template-stringify-marker` (239;
`reject/template_stringify_marker`) · a module-level `fn`/`val`/`var` named like a primitive type is
`primitive-type-name-taken` (`reject/primitive_type_name_taken{,_val}`) · T17: the reflection
records a `@Decl` hands out are `__Decl__{Annotation,Param,Field,Method}` (`comptime.zig`, shown
`Decl.Param`), so an imported `Param` no longer hides them
(`modules/reflection_type_not_shadowed_by_import`) · row 33 re-measured in its two-package shape:
refused at the aliased item (until 310's backend half lands), the package named `` `srv` `` not `` `srv:` ``
(`modules/import_same_type_name_two_packages_one_aliased`). Step 25 (289): `pub default fn (…)`
(named `default`, a keyword; `decl.name` the file's), `pub default <name>;`, `import {m.card};`
binding a module's default (`comptime/default_fn.zig`), `default-unknown` / `default-twice`;
`modules/default_{anonymous,named_later}`, `reject/default_{unknown,twice,named_twice}`, `docs.md` §
Modules; the formatter arm is `16-formatter`'s (handed over as a patch). Step 26 (297): `comptime s:
V<T> | type T` — the value form keeps `V<T>` with `s is type` folded false, a twin `<f>__type` without
`s` takes a type argument (`comptime/value_or_type.zig`; the call rewritten, the twin imported beside
an imported callee); `type-arg-read`, `is-type-outside-value-or-type`, and 280 (0)'s
`comptime-arg-not-known` for every `comptime` parameter (`twice(k)` used to drop `twice` and fail
erlc); `run/value_or_type_param`, `modules/value_or_type_param_imported`,
`reject/{value_or_type_mismatch,comptime_arg_not_known,type_arg_read,is_type_outside_value_or_type}`,
`docs.md` § Generics; the last union member's printer arm handed to 16. A type `@TypeInfo.all`
lists from another module, imported explicitly too, is one type reached twice: accepted (the
package's own item named `catalog`, not `catalog:`; the catalogue's alias keeps naming the type a
second import re-registers — `infer.zig` `constructs`; `modules/typeinfo_all_type_also_imported`). Step 24 (280), all but the function/type handover
(364: step 35), `decl.fields` as `Type.Field<unknown>` (134 s2) and example 7: every decorator parameter
`comptime` (`decorator-param-not-comptime`, a `comptime` default); an argument is one located
expression, checked against its parameter with the decorator's generics bound by `@Decl<P>`
(refused at the annotation) and the arguments, `.name` a field of `Type.Field<T>`'s `T` or a variant,
case-exact; `decorator-arg-not-comptime`; arrays, records, variants, field keys handed over as values
(built by a function of the decorator module); `run/decorator_{arguments_check,argument_values,decl_pattern,type_argument,function_arguments,record_argument,field_keys}`,
`modules/decorator_typed_arguments_import`, 19 `reject/` cells (`comptime-default-outside-decorator`
for a `comptime` default no call fills), `parser/tests/decision280.zig`, `docs.md` § Decorators.
Rows from other
fronts: decision 170's type half, std type's constructor through its namespace, `unwrapOr`'s width,
behavior `default fn` body checked, shorthand import never reaching a bundled package (goes with the shorthand: 337, 129 s2), occurs-check
message, primitive behavior extending std's, type parameter widening to its optional, std module's
`pub type`/`pub fn` through its namespace, `import-name-collision` for a `fn`/`val` named like an
import. This front's own rows (status L1): a partially returning value-position `@block`
(`if (c) return 3; 4`) is `block-tail-value` at the block (`stmtsMayFallThrough` on the typed
body; `reject/block_partial_return`) · the module's own decorator body, and the module's helpers it
reaches, are checked when the evaluator refuses them, so `decl.nope` is the checker's unknown field
located in the body, not `{badkey,nope}` at the annotation
(`reject/decorator_{body,helper}_unknown_field`; `reject/comptime_method_nothing_answers` now carets
the call) · step 21's last box for every block `eval.zig` folds: a body's `comptime <expr>` /
`comptime { … }` admitted by `error.zig` `isFoldable` is folded by the checker (`foldBodyComptime` →
`Env.srcRewrites`, spliced by `transform.zig`), so no backend meets it (`run/comptime_block_in_body`,
four targets; `run/comptime_expression_is_block` lost its `.wasm.expect`) ·
`std-unsupported-on-target` names `#[@External.<Member>]` and the `--target` spelling (`commonJS`),
every `@BeamMemory` diagnostic spells `keyed: true`, and the evaluator hints name `erl` alone.


Step 35 (364): every `comptime`
parameter other than `@Decl` is `comptime x: @Expr<T>` — a non-template function's wrapper read off
after the parse (`parser/expr_params.zig`, `Param.exprWrapped`; the formatter prints it back), `comptime
x: T` refused at the parameter (`comptime-param-not-expr`, fn / method / `declare fn`); the body binds
`x` as `Expr<T>`, `x.value` is `T`, refused for a function (`expr-value-of-function`) or a type
(`expr-value-of-type`), any other method of a parameter's `@Expr` `expr-param-method`; a decorator's
argument not known at build refused at it only where the body reads it (`decorator-value-not-comptime`,
`decorator-arg-not-comptime` gone), `x.fail` at the argument (`'__bp_failArg'/2`); `x.value` erased to
`x` for what runs (`comptime/expr_param.zig`); a template's `q.value` of a hole-less literal
(`template-value-not-known` for a holed one); `run/decorator_expr_{value,unread_argument}`, 9 `reject/`
cells, `docs.md` § Generics, § Template functions, § Decorators, the builtin table and § Decided, not
yet implemented; the codemod over std, `tests/language`, the compiler's own tests, jhonstart, rakun and
validation; decision 370 (`s35-a`), questions `s35-b`–`s35-d` (answered by 411, 412, 417). Box 3 (370 (2), the typed member): a
function expression takes typed parameters and a return (`FunctionExpr.paramTypes` / `.returnType`,
`parser/exprs.zig`, the formatter prints them), admitted only as `decl.addMember(name, fn(self: T) -> R
{ … })` (`fn-expr-typed` elsewhere); `infer.zig` `inferMemberFnCall` types it as program code, each
`@Expr<T>` parameter a `T`, the handle and the body's locals refused (`decorator-member-captures`),
untyped parameters `decorator-member-fn-untyped`, a non-literal `decorator-member-not-fn`;
`expr_param.useOf` skips the member, `eraseFn` hands the runtime its index (prelude `addMember/3`,
`Contribution.memberFn`); `memberFnSource` / `comptime/member_fn.zig` `render` splice each argument as
the annotation wrote it and each type parameter as bound (`DecoratorArgValue.lexeme`,
`Env.decoratorTypeArgs`), `decorator-member-type` for a foreign `self` or an unbound type parameter,
`decorator-member-fn-imported-name` for a library member naming anything but its parameters (until 384) —
cells `run/decorator_expr_rule_called`, `run/decorator_expr_message_runtime`,
`modules/decorator_member_fn_import{,ed_name}` (four targets) and six `reject/` cells, red on `90d50ae3`;
questions answered: `s35-f` by 413 (the member reads no local of the decorator, for now), `s35-e` by 408 — the typed form legal everywhere, step 37; `s35-g` by 384; `s35-h` by 404: one member name, several annotations through typed meta).
Step 23, `HookNode.async` (375) — `hooks.zig` `Node.is_async` (the term's `async`), set by a written `await`, an
`async { … }`, a `use` with `hook: null` or of a host hook, a call of a host answering `@Task` / `@Component`, a call
of a function value or a method answering `@Component<R>` (or open); `markHookAsync` follows the `use`s and calls
to a fixpoint before the `.hooks` readers (a cycle with one asynchronous node is asynchronous) and fills
`Env.syncFns` / `syncCalls` for commonJS; `builtins.d.bp` and `comptime.zig`'s mirror declare `async: bool` —
`run/decl_hooks_async` (`Card` and `Header` sync, `Comments` and `Page` async, the `Ring` / `Link` cycle async,
`Feed` over a function value async) and `modules/decl_hooks_async_imported` (an imported node's published mark),
four targets, red on the parent; question `s23-j`.
## Open

Steps 6, 10, 13 all touch `infer.zig`/`parser/**`: one commit per step, serial.

### Step 6 — `throw` in a `case` arm under `@Result` (box 3)

Checker keeps the fn's fallible channel in an arm's block; erlang, wasm, beam answer `Error` on the
`throw` path, commonJS refuses at codegen (`JumpInValuePosition`, `04-js` step 6). Cell lands with 04.

- [ ] `run/throw_in_case_arm_result` — `return case v { Num(n) -> g(n); _ -> throw "x"; }` under
      `-> @Result<i32, string>`: `isError()` true on the throw path, four targets

### Step 13 — JS-4's two checker gaps

`val [..rest] = xs;` binds `rest`; irrefutable `val Pair(Circle(r), n) = p;` accepted. Checker half
works (refusal lifted, commonJS/beam answer); erlang binds a lone spread (`Rest = Xs`,
`run/list_pattern_spread_alone`); wasm refuses nested (`05-wasm` row). Re-measure erlang's nested
constructor; keep the nested refusal until wasm lowers it. Contract: `../03-beam/pattern-binding.md`.

- [ ] `run/val_spread_only_list_pattern` prints `rest`'s length; `run/val_nested_ctor_pattern`
      prints `r` and `n` — four targets

### Step 18 — numeric literal suffixes (decision 247) — built (`19d59508`, on feat through `49455602`)

Kotlin's, lowercase, every numeric type: `1.5f` `f32`, `1.5d` `f64`, `42l` `i64`, `42u` `u32`,
`42ul` `u64`, `42i8`, `42i16`, `42u8`, `42u16`, `42isize`, `42usize`. Uppercase = located error
naming the lowercase; unsuffixed never changes type to fit (`val x: f64 = 1` refused — 209 reversed;
215 stands). Built: the suffix kept in the
number's token (`lexer.zig` `splitNumber`, `numberSuffixType`, `numberBackendText`; hex digits vs
`f`/`d`, exponent, member access on a literal — `parser/tests/decision247.zig`);
`run/numeric_literal_suffixes` (every suffix, a suffixed number pattern);
`reject/number_suffix_{uppercase,unknown,float_on_radix,integer_on_float}`,
`reject/number_exponent_without_digits`, `reject/integer_suffix_out_of_range`,
`reject/number_pattern_{of_another_type,suffix_disagrees}`; the unsuffixed mismatch
`reject/integer_literal_{never_fits_f64,operand_of_f64,beside_float_in_array}`,
`reject/float_literal_never_fits_f32` (`run/integer_literal_fits_f64` deleted); an `l` literal past
2^53 refused on commonJS (`run/wide_literal_past_js_safe_integer.commonJS.expect`); `docs.md` §
Numeric literals.

- [ ] an integer literal past its type's range refused on every target (decision 319): `refuseBeyondJsSafeInteger`
      (`comptime/infer.zig`) deleted, its 247 citation with it; `run/wide_literal_past_js_safe_integer` answers
      the value on the four targets (after `04-js` step 9)
- [ ] `language-gaps.md`'s rows "`f32` has no literal" and "An `i64` has no literal" lose their
      literal half; a cold gate green on `49455602` (no gate has run on the merge)

### Step 19 — a type application before a member (decision 255 (1)) — built (`6185db3c`, on feat through `49455602`)

`Dict<string, unknown>.empty()`: a type name with explicit type arguments followed by `.` or `(` is a
type application (1.0.10 decision 8 §1.3 extended to a type's member); elsewhere `<` is a comparison.
The list goes to the chain's first link (`receiverTypeArgs`); the checker binds the type's parameters
(`applyReceiverTypeArgs`). Built: `run/type_application_static_member` on four targets,
`reject/type_application_{argument_mismatch,argument_count,variant_payload_mismatch,on_a_field}`,
`botopink format` round-trip (`parser/tests/decision255.zig`, `format.zig` `typeArgsDoc`), `docs.md`
§ Generics.

- [ ] a type application through a module namespace (`collections.Dict<K, V>.empty()` — the head is a
      value's name, so the list is a comparison there): built, or refused with a located message

### Step 20 — `comptime <expr>` (decision 255 (2)) — measured and pinned (`6185db3c`, on feat through `49455602`)

`comptime <expr>` is `comptime { break <expr>; }`: parser, checker, evaluator (`eval.zig`) and gate
(`validateComptime`) read it as the block. Built: `run/comptime_expression_is_block`,
`run/comptime_expression_static_call` (commonJS, erlang, beam; wasm `.wasm.expect`),
`reject/comptime_expression_type_mismatch`, format round-trip. What it *means* was question `ck4-a`,
answered by decision 266 (step 21).

### Step 21 — a `comptime` is evaluated at compile time everywhere (decisions 266, 331) — built (front `step21-331`)

A `comptime <expr>` / `comptime { … }` the Zig folder (`eval.zig`) cannot read runs on the comptime
runtime (BEAM or WAT by the target, front 18) through `comptime/block_eval.zig`: the block becomes
`'__bp_ct_value'/0`, its function values go through makers `'__bp_fn_<i>'/0` (a fun from one site with no
environment is `=:=` on both runtimes, so `'__bp_lift'/2` names it), and the reply is lifted — a literal,
an array, a tuple, a record as its constructor, a declared function as its name, a closed lambda as written.

- [x] `validateComptime` admits a call the comptime runtime can run, at module level and in a body (it
      refuses a module-level `val` the block does not declare, `/0`, `-"s"`; a body's twin is
      `block_eval.runtimeRead`)
- [x] a body's `comptime` is folded at build — `val a = comptime two();` emits `2`
      (`run/comptime_block_with_loop`, codegen `comptime runtime ---- a block with a call and a loop …`)
- [x] a record and a collection are lifted: `run/comptime_expression_static_call` on the four targets (its
      `.wasm.expect` deleted); `eval pipeline: comptime record lit` is an accept snapshot now
- [x] a reference to a declared top-level function lifted as the reference (`run/comptime_function_reference`,
      codegen `… a record holding a function reference is lifted`); rakun's `beans()` (every `return comptime {
      … @TypeInfo.all … }` of the workspace) green unchanged on erlang
- [x] `reject/comptime_value_not_liftable` — a lambda capturing the block's state, located at the `comptime`;
      the resource half is `block_eval.zig`'s unit test (the WAT runtime has no process to answer)
- [x] the module-level `comptime` `val` after an import emitted on every target
      (`run/comptime_val_after_import`; `transform.zig` reads `Env.srcRewrites` before the `ct_<i>` entries)
- [x] `run/comptime_block_with_loop` answers `6` from one `.out` on the four targets, its evaluation in the
      codegen snapshots of both runtimes (`snap_audit.sh --mode=runtime-parity`); no `comptimeBlock` reaches a
      backend in a compile (every node is folded, lifted or refused)
- [x] (row from the coordinator) a decorator body calling a helper of another module that builds that module's
      record: the record and its called methods travel into the decorator module (`block_eval.typesReached`,
      `decorator_eval.evaluate`'s `types`; `decorator invocation: a helper of another module builds …`)

### Step 22 — the prelude scope (decision 270)

`compiler-core` takes, with a module, a list of import items (`element.Element`,
`elements.article`, aliases allowed) as the module's **last scope**: only for names the module does
not bind (declared or imported names never reach it). An item becomes an ordinary import (`import
{elements.article} from "<package>"`) in the transformed program and emitted code **only when a
name resolves through it**; unused items emit nothing. Names no library — `08-bpp/116` hands it
`prelude.bp` items for a `.bpp` file and owns the `.bpp` refusals (non-`import` `prelude.bp` line,
item of another package, an activation, default function's name bound by the header).

- [ ] `comptime/tests` fixture: module handed `[element.Element, elements.article]` naming only
      `article` — transformed program imports `elements.article`, not `Element`; a self-declared
      name resolves to its own declaration; nothing in `src/` names a library
- [ ] `src/comptime/AGENTS.md` states the scope order

### Step 23 — the hooks a function reaches, in its `@Decl` (decision 277)

`libs/std/src/builtins.d.bp`: `DeclAnnotation` gains `decorator: Decorator`; new `HookUse(hook:
?Declared<unknown>, annotations: DeclAnnotation[], at: string)`, `HookCall(callee:
Declared<unknown>, at: string)`, `HookNode(fn: Declared<unknown>, uses: HookUse[], calls:
HookCall[])`; `Decl` gains `val hooks: HookNode[]`; `extend Decorator { pub fn same(self, other:
Decorator) -> bool; }` (371). The checker (`comptime/infer.zig`, `env.zig`) computes, once per function:
its node — each `use h(…)` written in it (with `h`'s annotations), each call of a `@Component`
function (the calls `html` generates from tags included); `hooks` = that node then every node
reachable through `calls`, breadth-first in body order, each function once; a cycle is an edge
back; a `use` over a function value enters with `hook: null`; a host function gets no node; nodes
shared across the compilation. No backend, no codegen snapshot changes; the compiler names no stage
or library.

Built on `front/checker-s23` (botopink-lang patch): `comptime/hooks.zig`, the node recorded as `inferFnDecl`
infers a top-level function's body and published to the session (`Reflection.hookFns`); `decl.hooks` computed
for a function one of whose decorators reads it (questions s23-a – s23-f). 371 and 372 built on
`front/decl-hooks-371-372` (botopink-lang patch): `comptime/decorator_same.zig`, `infer.zig`'s two decorator
phases (questions s23-g – s23-i).

- [x] `run/decl_hooks_direct` — `use session()` (a host hook) → one node, `Page(uses: [session], calls: [])`
      (commonJS, erlang, beam: `session` has no wasm binding)
- [x] `run/decl_hooks_all_nodes` — a page over `UserMenu` → `Avatar`, `Badge` and `Avatar` again: four
      nodes, `Avatar` once, `calls` in body order
- [x] `run/decl_hooks_custom_hook` — `use user()` where `user` uses `session()`: the user's node has
      `user`, `user`'s node has `session`
- [x] `run/decl_hooks_cycle` — `A → B → A`: two nodes, `B`'s call goes back to `A`
- [ ] a component named as a value is a reached node (389): `itens.map(Card)`, a `val` or a field holding
      `Card`, a lambda answering a component — `run/decl_hooks_component_value` (a `#[page]` over `itens.map(Card)`
      with `Card` using `request()` is per-request); a call the checker cannot follow (a parameter called, a method)
      enters `HookCall(callee: null, at)` (`HookCall.callee: ?Declared<unknown>` in `builtins.d.bp`) —
      `run/decl_hooks_dynamic_call`
- [x] `run/decl_hooks_function_value` — `use f()` with `f` a parameter → `HookUse(hook: null)`
- [x] `HookUse` carries the `use`'s explicit type arguments (`typeArgs: TypeInfo<unknown>[]` — `use
      params<BlogParams>()` → `[BlogParams]`, its fields with their types), so `#[page]` checks them (293);
      `run/decl_hooks_type_args` (a field's annotations and the methods: s23-f)
- [x] across modules — `modules/decl_hooks_imported`: another module's nodes as it published them, a hook through
      an alias with its own annotations
- [x] `DeclAnnotation` gains `decorator: Decorator` — the declaration's identity, an alias and a namespace resolved
      (every handle's annotations, a field key's included); `HookNode`'s `fn` is `function` (`fn` is reserved, s23-a)
- [x] `modules/decorator_same` (a `modules/` cell: the second package is a path dependency) — `#[srv]` with
      `import {serverOnly as srv} from "web"` → `a.decorator.same(serverOnly)` true; the project's own
      `serverOnly` (`#[local.serverOnly]`) → false (371: `same`, `is` stays a keyword); `reject/decorator_same_not_decorator`
      (`same("serverOnly")`, the mismatch at the argument). `same` is a member of `behavior Decorator` (s23-g); a
      project module's decorator through a namespace is 386 (below)
- [ ] a namespace import registers the module's body-carrying decorators under `<ns>.<name>`, as std's are
      (386): `#[markers.tag]` runs `tag`, `markers.serverOnly` is a `Decorator` value for `same` —
      `modules/decorator_through_namespace` (the meta `tag` sets read back; `same(markers.serverOnly)` true)
- [x] `HookNode.async: bool` (375): `true` when the body writes `await` / `async { … }`, `use`s an asynchronous
      hook or calls an asynchronous component (written `await` or not), calls a host function answering
      `@Task`, or calls what the checker cannot follow (a function value, a method, `hook: null`); a cycle
      asynchronous when any node in it is; published with the module's nodes; `builtins.d.bp` declares the
      field — `run/decl_hooks_async` (a page over a synchronous `Card` and an awaiting `Comments`: `Card`
      `false`, `Comments` and the page `true`), `modules/decl_hooks_async_imported` — built on
      `front/ctx-async-374-375`: `Builder.is_async` / `dynamicCalls`, `noteAsyncCall`, `markHookAsync` before the
      `.hooks` readers; the reading of "cannot follow" and of a host `@Component` is `s23-j`
- [x] a decorator reading `.hooks` runs after the module's bodies (372, provisional): the decorators that
      read no `.hooks` first, then the bodies, then the `.hooks` readers, which may only `setMeta` /
      `fail` — `run/decl_hooks_reads_member` (`#[graph] fn Page() { return
      Account(…).validate(); }` above `#[check] pub type Account`, `validate` added by `#[check]`,
      compiles), `reject/decorator_hooks_output` (`addMember` in a `.hooks` reader, at the call);
      a same-module `@TypeInfo.all` of a reader is `typeinfo-all-hooks-reader` (s23-i,
      `reject/typeinfo_all_hooks_reader`)
- [x] `docs.md` § Decorators documents `decl.hooks` and `HookNode` (`Decorator.same` with 371); `comptime/AGENTS.md`
      states the computation; `language-gaps.md`'s row "A function's `@Decl` does not say which hooks it activates"
      closes

### Step 24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (decision 280)

The cases are [`examples/decorator-arguments-280.md`](./examples/decorator-arguments-280.md) — each
example a `run/` cell, its "não compila" lines `reject/` cells. Built on `front/checker-s24`
(botopink-lang patch; the library halves are patches of their own, below).

- [x] a decorator parameter without `comptime` refused at the parameter (`decorator-param-not-comptime`,
      `reject/decorator_param_not_comptime`); a `comptime` parameter takes a default; the decorators of
      the compiler's cells and docs, jhonstart (4), rakun (74, 21 files) and validation (8) migrated
      (the keyword only; std declares none with a further parameter); `botopink check` of every library
      member clean
- [ ] arguments of any type checked at the argument and handed over as values: a function, a `type`,
      an enum variant, a record, an array (`[1, 2]` has length 2); a value not known at comptime
      (`env("X")`) refused at the argument (`decorator-arg-not-comptime`) — built but for the
      function and the `type`, which the body still receives as their name: 364 replaces the box
      with step 35 (every argument an `@Expr<T>`)
- [x] `@Decl<T>` in `builtins.d.bp`; `T` bound from the annotated declaration (type, field, function)
      when the signature uses it, through a pattern too (`@Decl<fn(e: E) -> unknown>`); `@Decl` =
      `@Decl<unknown>`; a declaration not matching the pattern refused at the annotation
      (`reject/decorator_decl_pattern_{mismatch,return}`)
- [ ] `Field<T>` — `Type.Field<T>` in std's `types.bp` (decision 308), not `builtins.d.bp` — (`name`, the
      field's type); `.name` resolved against the expected `T`, a missing field refused at it; variadic
      `..fields: Type.Field<T>[]` (267); `decl.fields` hands out `Type.Field<unknown>` — built but the
      last clause (`decl.fields` is still `builtins.d.bp`'s `Field`, the same shape; `types.bp` gives it
      to `134` step 2)
- [x] `.Name` case-exact for fields and variants (`.custom` against `Custom` is the missing-name error;
      `reject/decorator_variant_case`, `reject/decorator_field_key_case`)
- [ ] the seven examples green on every target where they run; each "não compila" line a `reject/`
      cell with its caret — examples 1–6 green on the four targets
      (`run/decorator_{arguments_check,decl_pattern,type_argument,function_arguments,record_argument,field_keys}`,
      `run/decorator_argument_values`, `modules/decorator_typed_arguments_import`), 19 `reject/` cells
      (`comptime_default_outside_decorator` among them: a `comptime` default outside a decorator); example 1's signature is 406's (`message` first; a field's rule `#[refine]`); example 7
      (`#[onClick(like)]` in a tag) is the html template's (`08-bpp/118`, `05-jhonstart/26`)
- [x] `docs.md` § Decorators documents the four rules; `comptime/AGENTS.md` states how a comptime
      argument reaches the decorator body; `language-gaps.md`'s lg2-f and lg2-i rows marked built (they
      go when their markers do: 125 s7, rakun 04 s6)

### Step 27 — the compiler's annotations speak botopink (decision 305)

- [ ] parser: `label = value` in an annotation's arguments is a located error naming `label:`
      (`reject/annotation_label_equals`); `Annotation.labels` read from `label: value` only;
      `parser/AGENTS.md`'s labelled-argument line rewritten
- [ ] `@External.<Target>(fn: name)` — `name` resolves to a private botopink function of the same module,
      its signature checked against the bound one; a misspelt name is the ordinary unbound-name error at
      the argument (`reject/external_fn_unbound`); renaming the function renames the binding
- [ ] `@External.Wasm(op: "f64.sqrt")` checked against the opcode table (238's check, now on the label);
      `@External.Wasm(wasi: .RandomF64)` — `wasi`'s type is an enum of docs.md's adapter list
- [ ] the old prefixed strings (`"fn:…"`, `"op:…"`, `"wasi:…"`) are no longer recognised: an unlabelled
      string is host code, always; a string starting with one of the old prefixes is a located error
      naming the labelled form (one release, then removed)
- [ ] std's 88 bindings migrated (79 `fn:`, 6 `op:`, 3 `wasi:`), `scripts/` grep cell: no `"fn:` /
      `"op:` / `"wasi:` left in `libs/**`; `docs.md` § External rewritten

### Step 28 — a derived type: a compile-time function answering a new type (decision 307)

`pub val RecipeTitle = Type.pick(Recipe, .title);` — built on `front/checker-s28`
(`comptime/derived_types.zig`): the `val` is rewritten, before the checker, into the record declaration
it answers; `tryResolveTypeManipulationCall` and its bare names are gone. Questions `s28-a`–`s28-d`
(built as their recommendation, confirmed by 421–424).

- [x] `Type.partial`, `Type.required`, `Type.pick`, `Type.omit`, `Type.merge` answered at build, keyed on
      the receiver bound to std's `types.Type` (an alias included); fields as `.title`; a string field
      `derived-type-field-string` naming `.title`; an unknown field the `Type.Field<T>` error at it; a field
      twice, no field, an `omit` leaving none `derived-type-fields`; a non-record source (enum, namespace
      type, primitive, generic record, imported alias) `derived-type-source-not-record`; a field on both
      sides of `merge` `derived-type-merge-duplicate` at the second argument; arity / label
      `derived-type-arguments`; the bare `partial(…)` / `mergeRecords(…)` unbound
- [x] the answer is a new nominal record named after its `val`: usable in every type position,
      constructed, told apart by `is`, printed by its name, exported and imported; a derived or nested
      derivation as source (`Type.merge(Type.merge(A, B), C)`); `AnchorProps` as a parameter type
      (`modules/derived_type_imported`) — the s28 prerequisite of 362
- [x] a decorator on that `val` sees a type declaration (`decl.kind`, `decl.fields`); each field keeps
      the source field's annotations, `partial` makes it `?T` (`run/derived_type_decorated`)
- [x] the call is refused outside a module-level `val` — a body, a `var`, an annotated `val`
      (`derived-type-outside-val`, at the call)
- [x] `run/derived_type_functions`, `run/derived_type_decorated`, `modules/derived_type_imported` on the
      four targets; eleven `reject/derived_type_*` cells; all red on the parent — the derived-record
      row of `language-gaps.md` closes when 125 s5's example runs (its `#[validated]` half is 125's)
- [ ] `Type.keys(Recipe)` is `Type.Field<Recipe>` (decision 308) — the same type, not a copy: not a record
      derivation, not answered
- [ ] a `Type.Field<T>` at run time: stored, passed, compared; `case key { .title -> … }` exhaustive over
      `T`'s fields (a field added to `T` makes a `case` without it an error); `key.name`, `Key.of(text) ->
      ?Key`, `Key.all()` in declaration order — `run/field_key_runtime` on the four targets
- [ ] `decl.fields` as `Type.Field<unknown>` (134 s2's box) — not part of this mechanism (the reflection
      record is `comptime.zig`'s `__Decl__Field`): left to 134 s2

### Step 29 — the template annotation `#[f "…"]` (decision 311)

`#[erika "select * from User where id = ${id} limit 1"]` on a method is a parse error today: an
annotation is `#[name]` or `#[name(args)]`, and its arguments are comptime values (280), so a hole
naming a parameter cannot be written. After, the template call `f "…"` may be written as an annotation.

- [ ] parser: `#[f "…"]` and `#[f """…"""]` (also inside a `#[a, b]` list) — a node of its own beside
      the call form, printed as written (`16-formatter` step 9 gains the cell)
- [ ] checker: `f` resolves to a template function (first parameter `comptime q: @Expr<…>`); any other
      function is a located error at the annotation; `#[f(…)]` naming a template function is a located
      error naming `#[f "…"]`
- [ ] the literal is captured unevaluated, as at a call site; a `${…}` hole resolves in the annotated
      declaration's scope — on a method its parameters, by name and type (an unknown name is the
      ordinary unbound-name error at the hole) —; other names in the module's scope (112)
- [ ] the template function receives the annotated declaration's `@Decl` beside `q` (spelling decided
      here and recorded in `docs.md` § Decorators); a method's own `@Decl` carries `params` — closes
      `language-gaps.md`'s row "A method's own `@Decl` has no parameter list" (280)
- [ ] what the function produces goes to 216's four places, as a decorator's (typed meta, 298, for
      erika's query)
- [ ] `run/template_annotation` (a method annotation whose meta a type-level decorator reads) on the
      four targets; `reject/` cells for `#[f(…)]` on a template function, a non-template `#[f "…"]` and an
      unknown hole name
- [ ] `docs.md` § Decorators and § Template functions document the form; `comptime/AGENTS.md` states
      how the literal and the `@Decl` reach the body

- [ ] a template method (397, 415): `comptime self: @Expr<R>` then `comptime q: @Expr<…>` — the receiver the call site's code (`self.text()`)
      is called `value.method "…"` / `value.method """…"""` as `f "…"` is — the literal captured
      unevaluated, `self` the receiver; erika's `QueryContext.query` its first user —
      `run/template_method_call`
- [ ] a template call expands wherever an expression may stand (425): a type's method body, a destructuring
      initializer (`val #(n, total) = erika "…";`), a lambda, an argument, a field default, a `case` arm —
      `run/template_in_type_method`, `run/template_destructuring_init` and one cell per position, on the four
      targets; a call left unexpanded is a compiler error (`template-call-unexpanded`), never a run-time `undefined`

### Step 30 — a decorator wraps the function it annotates: `decl.wrapWith(f)` (decision 316)

A decorator answers only 216's four outputs today; a free function's decorator has nowhere to put a
proxy (`decorator-member-without-type`). After, it may wrap the function, typed:

```bp
pub fn useCache(comptime decl: @Decl<fn(..) -> string>, comptime ttl: Duration = hours(1)) {
    decl.wrapWith({ call -> cacheThrough(policyFor(decl, ttl), call.args, { -> call.run() }) });
}

#[useCache(ttl: minutes(5))]
pub fn posts() -> string { return loadPosts(); }
```

- [ ] `decl.wrapWith(f)` in `builtins.d.bp` (with 134): `f` receives the call value (the arguments and
      running the original body — spelling decided here, recorded in `docs.md` § Decorators) and answers
      the function's return type; a wrapper whose type does not match the annotated signature
      (`@Decl<fn(..) -> T>`, 280) is an error at the decorator
- [ ] the wrapped function keeps its name, signature and identity for callers (a reference to it is
      the wrapped behaviour); the original body is reachable only through the call value
- [ ] two or more wrappers compose in annotation order, the first written outermost — one cell
- [ ] on a method it wraps that method; on a function or method of another module the wrapper runs
      wherever it is called (the importer sees the wrapped behaviour)
- [ ] a decorator still reads no body (lg2-d) and writes none as a string (281)
- [ ] `run/decorator_wraps_function` (a counting wrapper, a cache wrapper, two composed) on the four
      targets; `reject/` cells for a wrapper of the wrong return type and for `wrapWith` outside a
      function or method decorator
- [ ] `01-checker/examples/decorator-arguments-280.md` example 5 runs (no longer illustrative);
      `language-gaps.md`'s row "A decorator cannot rewrite or wrap the body it annotates" closes once
      its marker (rakun 15's `publish-reliability-example.bp`) is rewritten

### Step 31 — `?T` by TypeScript's operators, no methods; a type in a type is associated (decision 330)

Today `??` and `?.` work; `?.[i]`, `?.(args)` and the postfix `!` do not parse; `?T`'s `map` / `flatMap` /
`unwrapOr` and the `result` namespace work in prose only (`builtins.d.bp` comments); a `type` in a
type's body is a parse error.

- [x] parser: `?.[i]`, `?.(args)` and the postfix `!` (`x!`, `x!.f()`); the prefix `!x` unchanged
- [x] checker: an operator over a value whose type is not `?T` is a located error naming the type (`s?.length()`,
      `s ?? "y"`, `s!` with `s: string`); `?.` over a member answering `?U` is `?U` (flattened); `??` beside
      `&&` / `||` without parentheses is a located error asking for them
- [ ] `x!`: `null` aborts with `value is null — <expr> at <file>:<line>:<col>` — built (`?? @panic(…)`,
      `run/optional_bang_aborts`); commonJS prints the text, erlang and beam abort with it as an Erlang binary
      (the `—` makes it non-latin1), wasm aborts without it: one text on the four targets is the backends'
      panic printing (02, 03, 05)
- [x] `?T` has no methods: `.map`, `.flatMap`, `.unwrapOr` on a `?T` are `unknown method` naming `?.` / `??`; on
      `@Result` they stay; `result.map(…)` and the rest of the namespace are unbound names. A method after a
      `?.` link continues its chain (`e?.key.length()`), as TypeScript's does
- [ ] a migration script (`scripts/codemod-optional-operators.py`, as 129's) rewrites `.unwrapOr(d)` on a `?T` to
      `?? d` and `result.<op>(r, …)` to `r.<op>(…)` in every tree — one commit per repository, before the
      refusals land. Built and run over botopink-lang (std, the five shared libraries, the language suite,
      `examples/`); the five library repositories' migrations are prepared, one per repository
- [x] a `type` declared in a type's body is that type's associated type (the `decl.addType` node, 216):
      `pub type Type { pub type Field<T>(…) { … } }` reads `Type.Field<T>` (308); `reject/` cells for a nested
      type named like a member
- [x] `docs.md` § Operators and § Optionals (07's prose) list the five operators and the five rules
- [ ] wasm: `?.()` over a function answering a plain value is refused (`run/optional_call_operator`'s
      `.wasm.expect`) — the answer has to be boxed (05)
- [ ] erlang, beam, wasm: `recv?.m()` over an absent receiver — `s?.length()` raises `badarg` on erlang and
      beam and answers `8` on wasm (the backends' `?.` method lowering; a method continuing a `?.member` chain
      is right on the four)
- [ ] erlang: `a ?? ns.f()` with a package-module namespace call as the default (std's own
      `os.tmpdir()`) lowers as a method call on `ns`; std reads it into a `val` first

### Step 32 — a `Bytes` primitive (decision 346)

Today no primitive, std type or literal holds bytes (`val b: Bytes = "a";` mismatches everywhere) and
every host cell marshals through `string`.

- [ ] `Bytes` in `builtins.d.bp` / `primitives.bp`: an immutable byte sequence; `Bytes.fromUtf8(s: string)
      -> Bytes`; `b.toUtf8()` answering `@Result` (an `Error` on invalid UTF-8)
- [ ] no conversion between `string` and `Bytes` without those calls: a string literal where `Bytes` is
      expected, and `Bytes` where `string` is, are located mismatches (`reject/` cells)
- [ ] a host cell may take and answer `Bytes`; the lowering is each backend's (an Erlang binary, a
      `Uint8Array` on commonJS, a buffer in wasm memory — 02–05), one `run/bytes_round_trip` cell on the
      four targets
- [ ] the rest of the surface (length, slice, concatenation, `encoding`'s bridges) written in the step's
      commit under 67; `docs.md` § Primitives (07's prose) and `language-gaps.md`'s byte row point here

### Step 33 — `@embedFile` / `@embedBytes` checked (decision 342)

- [ ] `@embedFile(comptime path: string) -> string` and `@embedBytes(comptime path: string) -> Bytes` in
      `builtins.d.bp`, callable in any context; a `path` not known at compile time is 280 (0)'s error at
      the argument; an absolute path or one leaving the package (`..`) refused at the argument (`reject/`
      cells); the read itself is `14-comptime-on-beam` step 6's

### Step 34 — a spread copies a record's fields (decision 359)

```bp
val pessoa = Pessoa(...pessoaOld, nome: "Ana");
pub val Contato = Type.pick(Pessoa, .email, .telefone);
val outra = Pessoa(...base, ...contato, nome: n);   // left to right, the later winning
```

- [ ] the parser reads `...expr` at the start of a record constructor's argument; `a...b` stays the
      inclusive range; the formatter prints `...src` (with `01-compiler/16`)
- [ ] the source is the record's type or a 307 type derived from it (`pick`, `omit`, `merge`); any
      other record refused at the `...` naming both types; a `Type.partial` value refused
- [ ] arguments apply left to right; a field without a default supplied by neither a spread nor a
      label is an error at the call; a label written twice stays an error
- [ ] `run/record_spread` on the four targets (a new record, the source unchanged and evaluated once);
      `reject/record_spread_other_type`, `reject/record_spread_partial`, `reject/record_spread_missing_field`
- [ ] a plain function call takes no spread (267): `reject/call_spread`

### Step 35 — every `comptime` parameter is an `@Expr<T>` (decision 364)

```bp
fn check<T>(comptime decl: @Decl<T>, comptime message: @Expr<string>, comptime rule: @Expr<fn(v: T) -> bool>) {
    decl.addMeta(Check(message: message, rule: rule));   // passed on; the program calls `rule`
}
fn page(comptime decl: @Decl, comptime pattern: @Expr<string>) {
    val p = pattern.value;                                // "blog/[slug]", read at build
}
```

- [x] every `comptime` parameter other than `@Decl` — a decorator's, a tag annotation's, a template
      function's, any function's, a builtin's in `builtins.d.bp` — is `comptime x: @Expr<T>`; `comptime x: T`
      refused at the declaration naming `@Expr<T>` (`reject/comptime_param_not_expr`,
      `reject/comptime_param_not_expr_function`; a method, a `declare fn` too) — the parser reads a
      non-template function's wrapper off (`Param.exprWrapped`, `parser/expr_params.zig`), a variadic is
      `comptime ..xs: @Expr<T[]>` (412)
- [x] the argument checked against `T` at the argument, as s24; `x.value` answers it when known at build
      and `T` is data (`run/decorator_expr_value`: a string, a number, a `bool`, a variant, a record, a field
      key, an array; an ordinary function's `n.value` specialised; a template's `q.value` of a literal without
      holes, `reject/template_value_not_known`); `.value` of an argument not known at build refused at the
      argument (`reject/decorator_value_not_comptime`), and accepted where the body never reads it
      (`run/decorator_expr_unread_argument`); an `@Expr` of a function or a type has no `.value`
      (`reject/decorator_call_expr_fn`, `reject/decorator_inspect_expr_type`); any other method of a
      parameter's `@Expr` refused (`reject/expr_param_method`); an optional function's null test refused (411),
      an ordinary function's unknown argument refused (417)
- [x] an `@Expr` handed to a typed member is evaluated by the program at run time (370 (2)):
      `decl.addMember("validate", fn(self: T) -> Violation[] { … rule(self) … message … })` — a
      function value, each parameter's `@Expr` spliced where it was written, checked like any function —
      `run/decorator_expr_rule_called` (the rule runs at validation, on the four targets),
      `run/decorator_expr_message_runtime` (a message from a function call, `t("…")`); the typed-meta
      channel (370 (1), a record with `@Expr<T>` fields) is `01-compiler/130` step 8's; an argument's
      source text spliced into a string output stays refused (`rule.text()` is `expr-param-method`)
- [x] `x.fail("…")` located at the argument (`reject/decorator_expr_fail_at_argument`; the prelude's
      `'__bp_failArg'/2`)
- [ ] a library member's names resolve where they were written (384, 112's hygiene): the decorator's names in
      its module, bound under an unspellable alias and imported into the annotated module (a private helper as
      `templatePrivateKey`), the annotation's arguments in the annotated module; `decorator-member-fn-imported-name`
      goes — `modules/decorator_member_fn_imported_name` turns `run` (`validation`'s `Violation` and a private
      helper reached, a user `Violation` not captured)
- [x] the codemod: every `comptime` parameter in std (`builtins.d.bp`, `types.bp`), jhonstart (4), rakun (73,
      20 files), validation (46) and styled (none — its templates were already `@Expr<string>`, its
      decorators `@Decl` alone) takes `@Expr<T>` and its body reads `.value`; cardume is not a repository yet;
      `botopink check` of every library member clean

### Step 36 — every function's stage: `Build`, `Run`, `Any` (decision 376)

```bp
fn padAll(n: i32) -> StyledProperty { return styledProperty "padding: --spacing(${n});"; }   // Any
fn agora() -> i64 { return clock.nowMs(); }                                                    // Run
fn campos(comptime t: type) -> string[] { return @typeInfo(t).fields.map({ f -> f.name }); }   // Build
fn cabecalho() -> string { val n = comptime campos(Post); return n.join(",") + agora().toString(); }   // Run
```

- [ ] each function's stage from its resources (376 (1)) and its calls (376 (2)); `use h(…)` takes `h`'s;
      `provide` / `context` `Any`; a host function `Run` unless std (or its library) declares it `Any`;
      `HookNode.stage` published with the module's nodes — `run/stage_of_functions`,
      `modules/stage_imported`
- [ ] `build-and-run` at the second resource, naming the first; a `comptime { … }` block separates them —
      `reject/stage_build_and_run`, `run/stage_comptime_block_in_run`
- [ ] a body that runs at build (decorator, template, `comptime`) calls `Build` / `Any` functions, a
      program's helper included, and refuses a `Run` one at the call (`run-in-build`) —
      `run/decorator_calls_any_helper`, `reject/decorator_calls_run`; `language-gaps.md`'s sibling-fn row
      closes
- [ ] std declares `Any` on its pure host primitives (`string`, `math`), every other host binding `Run`

### Step 37 — the typed function expression in every position (decision 408)

```bp
val inc = fn(x: i32) -> i32 { return x + 1; };            // inc: fn(i32) -> i32
xs.map(fn(n: i32) -> string { return n.toString(); });
val f: fn(x: i32) -> i32 = fn(x: string) -> i32 { … };     // ❌ at the expression: expected fn(i32) -> i32
```

- [ ] `fn(x: T, …) -> R { … }` typed where it stands — a `val` / `var`, an argument, a return, `decl.addMember`;
      written types checked against the position's when it has one — `run/fn_expr_typed_anywhere`,
      `reject/fn_expr_typed_mismatch`
- [ ] `fn-expr-typed` and `reject/fn_expr_typed` deleted; `docs.md` § Lambdas and § Decorators rewritten; the
      braced lambda still untyped (328)

### Step 38 — a body's last expression without `;` is its value (decision 409)

```bp
fn inc(x: i32) -> i32 { x + 1 }
fn sign(n: i32) -> i32 { if (n < 0) return -1; n }
val inc = fn(x: i32) -> i32 { x + 1 };
fn bad(x: i32) -> i32 { "a" }           // ❌ expected i32, got string — at "a"
fn semi(x: i32) -> i32 { x + 1; }       // ❌ as today: the body falls off its end
```

- [ ] the parser keeps a body's last expression statement written without `;` as the tail (`ast` flag), in a named
      `fn`, a method, a `fn` expression and a lambda; a braced `if` / `case` / loop at the end stays a statement (16)
- [ ] the checker types the tail against `-> R` (`stmtsMayFallThrough` answers `false` after it); a non-`void` tail in
      a body answering nothing refused at it — `run/fn_tail_value`, `run/method_tail_value`,
      `run/fn_expr_tail_value`, `reject/fn_tail_type_mismatch`, `reject/fn_tail_in_void`
- [ ] every backend returns the tail (erlang the last expression, commonJS a `return`, wasm the block value) —
      the four targets
- [ ] measured first: the bodies in std, `tests/language` and the libraries whose last line has no `;` today,
      the count in this README; `docs.md` § Functions, § Lambdas

### Step 39 — a template body reads a declaration through `@Decl` (decision 415)

```bp
val decl = q.lookup("User") ?? q.fail("`User` is not in scope");   // ?@Decl, resolved at the call site
val table = decl.meta(QueryTable) ?? q.fail("`User` is not an entity — annotate it with #[entity(…)]");
decl.setMeta(…);                                                    // ❌ the looked-up handle is read-only
```

- [ ] `e.lookup(name)` answers `?@Decl` — `name`, `kind`, `module`, `fields`, `meta(T)`, `metaAll(T)` — of the declaration
      the name resolves to at the call site (112), `null` when none; `setMeta` / `addMeta` / `addMember` / `addType` on it
      refused at the call — `run/template_lookup_decl`, `reject/template_lookup_decl_write`
- [ ] `decl.meta(T)` / `metaAll(T)` answered at build when `T` is data (380); a meta with a run-time `@Expr` field refused at
      the read naming the field — `run/template_lookup_meta`, `reject/template_lookup_meta_expr_field`; `@typeInfo(X).meta(T)`
      in a template body stays `typeinfo-meta-at-build`
- [ ] the looked-up declaration's decorators run before the template body: another module as today, one module ordered
      (372's pattern) — `modules/template_lookup_meta_other_module`, `run/template_lookup_meta_same_module`
- [ ] `docs.md` § Template functions documents `lookup`'s handle; `comptime/AGENTS.md` states the order

### Step 40 — a template call is typed by the code it built (decision 426)

```bp
val n: i32 = erika "select name from cities";     // ❌ expected i32, got Array<string> — compiles today
val nomes = erika "select name from cities";      // nomes: Array<string>
```

- [ ] `finishExpansion` types the call by the expansion: no free `T` survives a template call; the built type is
      checked against the signature's answer (a bound) at the template's `build`, then unified with the expected type
      at the call — `run/template_call_typed_by_expansion`, `reject/template_call_expected_mismatch`,
      `reject/template_build_outside_bound`
- [ ] `q.note(message)` attached to an error reported at the call — `reject/template_note_on_mismatch` (the note
      in the expected text); `docs.md` § Template functions

### Step 41 — built code located by its expansion (decision 429)

```bp
val porRegiao = erika "select region, count(*) from boxes group by region";   // expansion 1
val quadrados = erika "select label from boxes where w = h";                  // expansion 2
// each query's `row.w` keeps its own plan on erlang — no padding in `erika.bp`
```

- [x] every expansion carries an id: `infer.builtCodeOrigin` hands each parse of built text (`@code`, a template's
      `code`, the `code` half of `custom`) the module's next id (`Env.expansionCount`), and `parseCodeText` stamps
      every token with it; `ast.Loc` is (line, column, expansion), a built node's line and column its offset in the
      built string read from the literal's line and column. Every plan keyed by location reads the pair — each
      `AutoHashMap(ast.Loc, …)` hashes the whole `Loc`: in `Env`, `defaultInjections` (C-04), `instanceLowerings`,
      `method_lowerings`, `dispatchRewrites`, `jsMethodRenames`, `stdArrayLowerings`, `indexRewrites`,
      `enumSectionRewrites`, `srcRewrites`, `optionalNullCases`, `result_jump_lowerings`, `resultPatternLocs`,
      `templateExpansions`, `templateLowerings`, `customAstByLoc`, `tupleLabelReads`, `keyedRowAccess`,
      `componentCalls`, `componentLambdas`, `contextUses`, `hookTargets`, `hostCalls`, `hostComponentRefs`,
      `syncCalls`, `divisions`, `exprCaptures`, `itemOwners`, `localDepth`, `decoratorArgValues`, `decoratorSame`,
      `decoratorTypeArgs`, `typeinfoAll`; the backends' `rewrites` / `instance_lowerings` / `renames` / `lowerings`
      (erlang's field-access and lambda plans among them), erlang's `hoisted_steps`, `transform`'s `result_patterns`,
      `typeinfo_all`'s answers and rewrites, `typed_meta`'s types, `std_namespace`'s locs, the comptime beam
      lowering's locals. The comparisons written field by field (`statementBlockLoc`, `memberFnAt`, a `@Result`'s
      first throw, `Env.warn`'s repeat, the parser's token search) are `Loc.eql`; a location made from a node's
      (`optional_synthetic_col`, an inline type's constructor, a lifted `comptime` node, a field read's column, a
      template span) keeps its expansion; the names made from a location carry a non-zero one (`__bp_opt_…`,
      erlang's `BpAssert…` and seed keys, wat's `__anon_L…_C…`); `dsl_hygiene` reads a node's offset back through the
      same origin. `componentCalls` holds one type per location — the per-callee list that kept two expansions'
      calls apart is gone
- [x] a diagnostic in built code maps to the literal's line and column for the reader (`q.source()`) plus its offset —
      `reject/template_built_code_diagnostic_located` (17:42; the parent binary located it at 1:20)
- [x] `run/template_two_alike_expansions` (two expansions whose code sits at the same offsets, no padding) and
      `run/template_default_arg_two_expansions` (the `<GreetingHeadline>` / `<Footer />` shape) green on the four
      targets, both red on the parent on erlang (`erlang:element/2` badarg over an array; `footer/2 undefined`)
- [x] `repository/erika` (`erika.bp`) and `repository/jhonstart` (`html.bp`) drop the padding — `q.build(pipe)`,
      `template.build(code)` —, one consumer commit each; their two `// LANGUAGE GAP` markers go and
      `language-gaps.md`'s row and its marker-index entries close; erika-test (15), erika (34) and erika-linq (14)
      green on erlang without it, erika's and jhonstart's pre-commit gates green

### Step 42 — a host binding that throws answers a `@Result` (decision 431)

```bp
#[@External.Node("JSON.parse($0)", throws: true), @External.Erlang("json:decode($0)", throws: true)]
declare fn jsParse(s: string) -> @Result<Json, HostError>;
val doc = try jsParse(texto);                      // a JS SyntaxError / an erlang raise is Error(HostError(…))
```

- [ ] `throws: true` on every `@External` variant, a `bool` at the last position (as `inline:`); refused unless the
      declared return is `@Result<…, HostError>` or `@Task<@Result<…, HostError>>` — `reject/external_throws_return`
- [ ] each backend wraps the cell (commonJS `try/catch`, a rejected Promise; erlang and beam `try … catch Class:Reason`;
      wasm the `wasi:` adapter's error) — handed to 02–05 —, `run/external_throws_host_error` on the four targets
- [ ] `effect-try-without-fallible-channel`'s message names `try … catch` and `throws: true`; `docs.md` § Results, § Host bindings

### Rows other fronts found

- [ ] comptime body diagnostic names the body's file: `infer.zig` (`decoratorError`) passes the
      display path, or locates at the body call for the module's own decorator — asserted in
      `comptime_module.zig`, `decorator_invocation.zig` (from `14-comptime-on-beam` step 1)
- [ ] package module namespace in type and value position (`import {report} from "validation"`, then
      `report.X`) as for std modules — exports known only to `comptime.zig`'s `resolveImports`
- [x] a module is its package plus its path (170, 337): an item with no `from` names one module of
      the importing package by its registry key (`ImportSource.key`, `Module.package` stamped on each
      import as `ImportDecl.ownPackage`), so `a/theme` and `b/theme` are two modules to the checker,
      `crossModule.pick`, every backend (erlang's imported-enum owner), the `.d.ts` and the comptime
      runtime (`block_eval.findType` by module); a dependency's shorthand stays in its package
      (`modules/two_packages_one_module_name`, four targets; from `08-bpp/119` step 1 box 4)
- [ ] two aliased imports of two same-named **types** are legal (310): every backend qualifies a type by
      its module; `modules/import_two_types_one_name` becomes an accept cell on every target (until
      then the refusal is a `language-gaps.md` row)
- [ ] `@External.Wasm` binding read on every target: checker walk over `external_variants` with
      `codegen/wat/host_binding.zig`'s `parse`, so a misspelt `op:` no wasm build reaches is refused
      (from `05-wasm` step 5)
- [x] `infer.zig`'s template memo key appends the whole scope's JSON per call site — O(scope) per
      template call: now `template_eval.memoKey` — the callee, each capture's text with the scope
      entries of its words (decision 237), the plain arguments; 0.034 → 0.002 ms per N=200 call
      (`14-comptime-on-beam` step 2)
- [x] an unsuffixed integer literal is range-checked in the type its position asks for, `i32` with
      nothing asking (247): `val e: i32 = 3000000000` and an unannotated `3000000000` are refused at
      the literal (`reject/integer_literal_unsuffixed_out_of_range`,
      `reject/integer_literal_unsuffixed_default_out_of_range`); `run/i64_full_width`'s
      `@print(4294967296)` is written `4294967296l` (from `04-js` step 9; bugs-sweep)
- [x] the operand of a unary `-` is read as the negative value: `-9223372036854775808l` is `i64`'s
      minimum, `-129` is below `i8`, a negated literal takes its width from the other operand
      (`isIntegerLiteralOperand`), wasm emits a type's minimum as the constant
      (`run/integer_literal_type_minimum`, `reject/integer_literal_below_minimum`; bugs-sweep, bs-b)
- [x] `refuseIntegerOutOfRange` cites 319 (`infer_errors` "cites decision 319"; bugs-sweep)

**Gate:** standard (fronts.md § Gate) + every re-recorded `snapshots/comptime/**` file read for
expected/found orientation; a refusal moving a backend fixture is reported to that backend's front,
never deleted here · `botopink check` of every package of the seven repositories identical to the
parent binary, `zig build test-libs` at baseline (a library that reds gets a migration plan in the
commit)

## Notes

- Refusal steps (6's throw, 13, `@block` tail, `$stringify`, primitive name) run once against the
  four backend snapshot dirs before landing; jhonstart's and rakun's workarounds for steps 5, 7 hold.
- `parser.zig` shared with 16: this front's parser rows first; 16's `decision-29-parser-half.patch`
  rebases on them, lands last.
