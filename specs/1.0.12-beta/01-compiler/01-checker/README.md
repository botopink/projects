# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17, 19, 20 on feat; step 18 built on
feat (botopink-lang `49455602` merges `19d59508`, `6185db3c`) with one box open; step 6 box 3, steps
10, 13, 21–28 and ten rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `16-formatter` step 8 (step 10) · `05-wasm` nested
constructor in a `val` (step 13) · `08-bpp/116` prelude list (step 22) · decision-gated rows lg2-a, lg2-q, lg2-e, lg2-m, lg2-r, lg2-t — each a step here only once
answered.
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
`Ok`/`Error` never constructors; integer literal under `f64`; `f64 == 1` refused. Rows from other
fronts: decision 170's type half, std type's constructor through its namespace, `unwrapOr`'s width,
behavior `default fn` body checked, shorthand import never reaching a bundled package, occurs-check
message, primitive behavior extending std's, type parameter widening to its optional, std module's
`pub type`/`pub fn` through its namespace, `import-name-collision` for a `fn`/`val` named like an
import.

## Open

Steps 6, 10, 13 all touch `infer.zig`/`parser/**`: one commit per step, serial.

### Step 6 — `throw` in a `case` arm under `@Result` (box 3)

Checker keeps the fn's fallible channel in an arm's block; erlang, wasm, beam answer `Error` on the
`throw` path, commonJS refuses at codegen (`JumpInValuePosition`, `04-js` step 6). Cell lands with 04.

- [ ] `run/throw_in_case_arm_result` — `return case v { Num(n) -> g(n); _ -> throw "x"; }` under
      `-> @Result<i32, string>`: `isError()` true on the throw path, four targets

### Step 10 — a lambda parameter annotation (T12)

`{ n: i32 -> f(n) }` parses: lambda-head scan (`parser/exprs.zig`) takes `name: Type` per parameter
= declared type, unified with the expected one. Blocked on `16-formatter` step 8 (printer arm;
otherwise `format --check` strips it).

- [ ] `run/lambda_param_annotation` on four targets; `reject/lambda_param_annotation_mismatch` when
      the expected type disagrees

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

### Step 21 — a `comptime` is evaluated at compile time everywhere (decision 266)

`comptime <expr>` and its block form run on the comptime runtime at module level and in a body; a
call is evaluated there, and the value is lifted into the emitted program — a literal as a literal,
a record or a collection as the construction each backend emits. A value with no emitted
construction (a function, a resource) is a located refusal.

- [ ] `validateComptime` admits a call the comptime runtime can run, at module level and in a body
- [ ] a body's `comptime` is folded at build — `val a = comptime two();` emits `2`, never `two()`
- [ ] a record and a collection are lifted: `val d: Dict<string, unknown> = comptime Dict.empty();`
      builds at compile time on commonJS, erlang, beam and wasm (`run/comptime_expression_static_call`
      loses its `.wasm.expect`)
- [ ] `reject/comptime_value_not_liftable` — a function value out of a `comptime`, located at it
- [ ] the module-level `comptime` `val` after an import (step 20's finding) emitted on every target

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
HookCall[])`; `Decl` gains `val hooks: HookNode[]`; `extend Decorator { pub fn is(self, other:
Decorator) -> bool; }`. The checker (`comptime/infer.zig`, `env.zig`) computes, once per function:
its node — each `use h(…)` written in it (with `h`'s annotations), each call of a `@Component`
function (the calls `html` generates from tags included); `hooks` = that node then every node
reachable through `calls`, breadth-first in body order, each function once; a cycle is an edge
back; a `use` over a function value enters with `hook: null`; a host function gets no node; nodes
shared across the compilation. No backend, no codegen snapshot changes; the compiler names no stage
or library.

- [ ] `run/decl_hooks_direct` — `use session()` → `[HookNode(f, uses: [session], calls: [])]`
- [ ] `run/decl_hooks_all_nodes` — a page over `UserMenu` → `Avatar`, `Badge` and `Avatar` again: four
      nodes, `Avatar` once, `calls` in body order
- [ ] `run/decl_hooks_custom_hook` — `use user()` where `user` uses `session()`: the user's node has
      `user`, `user`'s node has `session`
- [ ] `run/decl_hooks_cycle` — `A → B → A`: two nodes, `B`'s call goes back to `A`
- [ ] `run/decl_hooks_function_value` — `use f()` with `f` a parameter → `HookUse(hook: null)`
- [ ] `HookUse` carries the `use`'s explicit type arguments (`typeArgs: TypeInfo[]` — `use params<BlogParams>()`
      → `[BlogParams]`), so `#[page]` checks them (293); `run/decl_hooks_type_args`
- [ ] `run/decorator_is_identity` — `#[srv]` with `import {serverOnly as srv}` → `a.decorator.is(serverOnly)`;
      a same-named decorator of another package → false
- [ ] `docs.md` § Decorators documents `decl.hooks`, `HookNode`, `Decorator.is`; `comptime/AGENTS.md`
      states the computation; `language-gaps.md`'s row "A function's `@Decl` does not say which hooks
      it activates" closes

### Step 24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (decision 280)

Today a decorator argument is a raw lexeme checked only as `string`, number or `bool` (lg2-i), a
type cannot be passed (lg2-f), and `Decl` (`builtins.d.bp`) is untyped. The cases are
[`examples/decorator-arguments-280.md`](./examples/decorator-arguments-280.md) — each example a
`run/` cell, its "não compila" lines `reject/` cells.

- [ ] a decorator parameter without `comptime` refused at the parameter (`decorator-param-not-comptime`);
      the decorators of std and of the seven repositories migrated in the same landing (`botopink
      check` of every package identical but for the added keyword)
- [ ] arguments of any type checked at the argument and handed over as values: a function, a
      `type`, an enum variant, a record, an array (`[1, 2]` has length 2); a value not known at
      comptime (`env("X")`) refused at the argument (`decorator-arg-not-comptime`)
- [ ] `@Decl<T>` in `builtins.d.bp`; `T` bound from the annotated declaration (type, field, function)
      when the signature uses it, through a pattern too (`@Decl<fn(e: E) -> unknown>`); `@Decl` =
      `@Decl<unknown>`; a declaration not matching the pattern refused at the annotation
- [ ] `Field<T>` in `builtins.d.bp` (`name`, the field's type); `.name` resolved against the
      expected `T`, a missing field refused at it; variadic `..fields: Field<T>[]` (267)
- [ ] `.Name` case-exact for fields and variants (`.custom` against `Custom` is the missing-name error)
- [ ] the seven examples green on every target where they run; each "não compila" line a `reject/`
      cell with its caret
- [ ] `docs.md` § Decorators documents the four rules; `comptime/AGENTS.md` states how a comptime
      argument reaches the decorator body; `language-gaps.md`'s lg2-f and lg2-i rows close

### Step 25 — the anonymous default function and `pub default <name>;` (decision 289)

`pub default fn (params) -> R { … }` — a module's default function with no name in its module — and
`pub default <name>;` — an existing function of the module made its default — parse and check;
`pub default fn Name(…)` stays, the shorthand of `fn Name(…)` + `pub default Name;`. One default per
module. An anonymous default's `decl.name` (and `@typeInfo`) is the module's file name; the
importer binds it under the module path's last segment or an alias (213, 288).

- [ ] `run/default_anonymous` — `pub default fn (x: i32) -> i32` imported `import {m.double};` and
      called; `decl.name == "double"` in a decorator on it
- [ ] `run/default_named_later` — `fn Tree(n: Node) -> View { … <Tree …/> … }` + `pub default Tree;`:
      recursion through the name, imported by the module path
- [ ] `reject/default_twice` (two defaults), `reject/default_unknown` (`pub default nope;`) at the line
- [ ] a decorator named like the file imported beside an anonymous default (`page.bpp`'s case) checks
- [ ] the formatter prints both forms (`16-formatter` hand-off if its arm is missing); `docs.md` § Modules

### Step 26 — a `comptime` parameter that takes a value or a type (decision 297)

`comptime source: X<T> | type T`: an argument of type `X<T>` binds `T` from it (or checks it against
an explicit `<T>`); a type argument binds `T` to that type; `source is type` answers which, at comptime.

- [ ] `run/value_or_type_param` — `fn pick<T>(comptime s: Box<T> | type T) -> string` called with a
      `Box<i32>` value and with `string`; `@typeName`-free assertion on the branch taken
- [ ] `reject/value_or_type_mismatch` — `pick<i32>(Box("x"))` at the argument; a runtime value where
      the parameter is `comptime` at the argument (280 (0))
- [ ] `docs.md` § Generics documents it; `language-gaps.md`'s row closes

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

`pub val RecipeTitle = pick(Recipe, .title);` — today `tryResolveTypeManipulationCall` (`infer.zig`)
resolves `partial`, `pick`, `omit`, `mergeRecords` to an anonymous record no decorator can annotate.

- [ ] the five (`partial`, `required`, `pick`, `omit`, `mergeRecords`) are compile-time functions: every
      parameter `comptime`, fields as `Field<T>` (`.title`); a string field (`"title"`) is a located
      error naming `.title`; an unknown field the ordinary `Field<T>` error at the argument (280)
- [ ] the answer is a new nominal record named after its `val`: `RecipeTitle` in diagnostics and hover,
      usable in every type position, constructed `RecipeTitle(title: "…")`, matched, exported and
      imported (`import {recipes.RecipeTitle};`); two `val`s over the same call are two types
- [ ] a decorator on that `val` sees a type declaration (`decl.kind`, `decl.fields`):
      `#[validated] pub val RecipePatch = partial(Recipe);` emits as on a written record; each field
      keeps the source field's annotations (`partial` makes it `?T`)
- [ ] the call is refused outside a module-level `val` (a local, a parameter default) — located
- [ ] `run/derived_type_functions` on the four targets; `language-gaps.md`'s derived-record row closed

### Rows other fronts found

- [ ] `@block` tail form refused: `val a = @block { 1 + 2 };` checks today (`inferBuiltinCallReturnType`
      types a block by its tail; decision 2 refuses), prints `3` erlang/beam/wasm, `null` commonJS;
      `@block { return 3; }`, statement `@block { … };` stay legal — closes `02-erlang` step 10,
      `04-js` step 1
- [ ] `$stringify` refused in every `@External` template, std included (decisions 164, 239): located
      parser refusal beside `template-self-marker` / `template-marker-out-of-range`
      (`parser/template_markers.zig`, `parser.zig` `ParseErrorType`, `print.zig`); std's
      `Array.join` stops writing it — `04-js` step 2 adds the cell
- [ ] module-level `fn` / `val` / `var` named like a primitive type = `primitive-type-name-taken` at
      the name (`language-gaps.md` row "A function named like a primitive type shadows the type in
      its module") — was parked on std's `random.bool` (dropped by decision 250): can land; not on feat
- [ ] comptime body diagnostic names the body's file: `infer.zig` (`decoratorError`) passes the
      display path, or locates at the body call for the module's own decorator — asserted in
      `comptime_module.zig`, `decorator_invocation.zig` (from `14-comptime-on-beam` step 1)
- [ ] T17 — reflection model (`Decl`, `Param`, `Field`, `Method`) resolves in a decorator body by its
      own identity, not shadowed by an import named `Param`/`Field` —
      `modules/reflection_type_not_shadowed_by_import` (decorator module importing a user `Param`
      reads `m.params` of a `@Decl`); today `unknown field 'name' on type 'Param'`
- [ ] package module namespace in type and value position (`import {report} from "validation"`, then
      `report.X`) as for std modules — exports known only to `comptime.zig`'s `resolveImports`
- [ ] two aliased imports of two same-named **types** stay refused (decision 170 makes them legal)
      until backends tell types apart by module — maintainer's question (imp-a)
- [ ] `@External.Wasm` binding read on every target: checker walk over `external_variants` with
      `codegen/wat/host_binding.zig`'s `parse`, so a misspelt `op:` no wasm build reaches is refused
      (from `05-wasm` step 5)
- [ ] `infer.zig`'s template memo key appends the whole scope's JSON per call site — O(scope) per
      template call (`14-comptime-on-beam` step 2's remaining cost)
- [ ] row 33 (`as` alias of an imported type binds the declared name) re-measured in its exact shape
      (two packages, one `App` aliased); step-4-sized import-binding row if it reproduces, else
      closed (decision 110's `as` on a type leaf landed — `modules/import_alias_on_type`)

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
