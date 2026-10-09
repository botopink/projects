# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17, 19, 20 on feat; step 18 built on
feat (botopink-lang `49455602` merges `19d59508`, `6185db3c`) with one box open; step 6 box 3, steps
13, 21–31 and ten rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `05-wasm` nested
constructor in a `val` (step 13) · `08-bpp/116` prelude list (step 22) · decision-gated rows lg2-a, lg2-q, lg2-e — each a step here only once
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
`Ok`/`Error` never constructors; integer literal under `f64`; `f64 == 1` refused. Rows: an `@block`
used as a value with no valued `return` is `block-tail-value` (decision 2; `reject/block_tail_value`)
· `$stringify` in an `@External` template is `template-stringify-marker` (239;
`reject/template_stringify_marker`) · a module-level `fn`/`val`/`var` named like a primitive type is
`primitive-type-name-taken` (`reject/primitive_type_name_taken{,_val}`) · T17: the reflection
records a `@Decl` hands out are `__Decl__{Annotation,Param,Field,Method}` (`comptime.zig`, shown
`Decl.Param`), so an imported `Param` no longer hides them
(`modules/reflection_type_not_shadowed_by_import`) · row 33 re-measured in its two-package shape:
refused at the aliased item (imp-a), the package named `` `srv` `` not `` `srv:` ``
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
second import re-registers — `infer.zig` `constructs`; `modules/typeinfo_all_type_also_imported`).
Rows from other
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
- [ ] a `comptime { … }` block in a function body builds on commonJS and wasm (it fails at codegen there)

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
- [ ] `Field<T>` — `Type.Field<T>` in std's `types.bp` (decision 308), not `builtins.d.bp` — (`name`, the
      field's type); `.name` resolved against the expected `T`, a missing field refused at it; variadic
      `..fields: Type.Field<T>[]` (267); `decl.fields` hands out `Type.Field<unknown>`
- [ ] `.Name` case-exact for fields and variants (`.custom` against `Custom` is the missing-name error)
- [ ] the seven examples green on every target where they run; each "não compila" line a `reject/`
      cell with its caret
- [ ] `docs.md` § Decorators documents the four rules; `comptime/AGENTS.md` states how a comptime
      argument reaches the decorator body; `language-gaps.md`'s lg2-f and lg2-i rows close

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

`pub val RecipeTitle = Type.pick(Recipe, .title);` — today `tryResolveTypeManipulationCall` (`infer.zig`)
resolves the bare names `partial`, `pick`, `omit`, `mergeRecords` to an anonymous record no decorator can
annotate. After, the five are static methods of std's `Type` (`libs/std/src/types.bp`, declared by 134
step 2) and the resolver keys on that declaration.

- [ ] `Type.partial`, `Type.required`, `Type.pick`, `Type.omit`, `Type.merge` are compile-time functions:
      every parameter `comptime`, fields as `Type.Field<T>` (`.title`); a string field (`"title"`) is a located
      error naming `.title`; an unknown field the ordinary `Type.Field<T>` error at the argument (280); the bare
      `partial(…)` / `mergeRecords(…)` are unbound names
- [ ] the answer is a new nominal record named after its `val`: `RecipeTitle` in diagnostics and hover,
      usable in every type position, constructed `RecipeTitle(title: "…")`, matched, exported and
      imported (`import {recipes.RecipeTitle};`); two `val`s over the same call are two types
- [ ] a decorator on that `val` sees a type declaration (`decl.kind`, `decl.fields`):
      `#[validated] pub val RecipePatch = Type.partial(Recipe);` emits as on a written record; each field
      keeps the source field's annotations (`partial` makes it `?T`)
- [ ] the call is refused outside a module-level `val` (a local, a parameter default) — located
- [ ] `run/derived_type_functions` on the four targets; `language-gaps.md`'s derived-record row closed
- [ ] `Type.keys(Recipe)` is `Type.Field<Recipe>` (decision 308) — the same type, not a copy
- [ ] a `Type.Field<T>` at run time: stored, passed, compared; `case key { .title -> … }` exhaustive over
      `T`'s fields (a field added to `T` makes a `case` without it an error); `key.name`, `Key.of(text) ->
      ?Key`, `Key.all()` in declaration order — `run/field_key_runtime` on the four targets

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

- [ ] parser: `?.[i]`, `?.(args)` and the postfix `!` (`x!`, `x!.f()`); the prefix `!x` unchanged
- [ ] checker: an operator over a value whose type is not `?T` is a located error naming the type (`s?.length()`,
      `s ?? "y"`, `s!` with `s: string`); `?.` over a member answering `?U` is `?U` (flattened); `??` beside
      `&&` / `||` without parentheses is a located error asking for them
- [ ] `x!`: `null` aborts with `value is null — <expr> at <file>:<line>:<col>`, one text on the four targets
      (the lowering is each backend's, 02–05; cells `run/optional_operators`, `run/optional_bang_aborts`)
- [ ] `?T` has no methods: `.map`, `.flatMap`, `.unwrapOr` on a `?T` are `unknown method` naming `?.` / `??`; on
      `@Result` they stay; `result.map(…)` and the rest of the namespace are unbound names
- [ ] a migration script (`scripts/codemod-optional-operators.py`, as 129's) rewrites `.unwrapOr(d)` on a `?T` to
      `?? d` and `result.<op>(r, …)` to `r.<op>(…)` in every tree — one commit per repository, before the
      refusals land
- [ ] a `type` declared in a type's body is that type's associated type (the `decl.addType` node, 216):
      `pub type Type { pub type Field<T>(…) { … } }` reads `Type.Field<T>` (308); `reject/` cells for a nested
      type named like a member
- [ ] `docs.md` § Operators and § Optionals (07's prose) list the five operators and the five rules

### Rows other fronts found

- [ ] comptime body diagnostic names the body's file: `infer.zig` (`decoratorError`) passes the
      display path, or locates at the body call for the module's own decorator — asserted in
      `comptime_module.zig`, `decorator_invocation.zig` (from `14-comptime-on-beam` step 1)
- [ ] package module namespace in type and value position (`import {report} from "validation"`, then
      `report.X`) as for std modules — exports known only to `comptime.zig`'s `resolveImports`
- [ ] two aliased imports of two same-named **types** are legal (310): every backend qualifies a type by
      its module; `modules/import_two_types_one_name` becomes an accept cell on every target (until
      then the refusal is a `language-gaps.md` row)
- [ ] `@External.Wasm` binding read on every target: checker walk over `external_variants` with
      `codegen/wat/host_binding.zig`'s `parse`, so a misspelt `op:` no wasm build reaches is refused
      (from `05-wasm` step 5)
- [ ] `infer.zig`'s template memo key appends the whole scope's JSON per call site — O(scope) per
      template call (`14-comptime-on-beam` step 2's remaining cost)

- [ ] two diagnostics teach a retired spelling (from `07` step 6): `std-unsupported-on-target`
      reads "std/beam has no `@external` for target 'node'" (`infer.zig` `refuseStdUnsupported`; the
      annotation is `#[@External.<Target>(…)]`, the target `commonJS`), and the `PersistentTerm`
      write's hint for a `Dict` names `#[@BeamMemory.Ets(keyed = true)]` where the argument is
      written `keyed: true`
- [ ] a partially returning `@block` (a `return` on some paths, no value on the fall-through)
      type-checks; commonJS prints `null` on the fall-through (from `04-js` step 1)
- [ ] a type error in a decorator body (`decl.nope`) escapes the checker and surfaces at run time as
      `{badkey,nope}`

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
