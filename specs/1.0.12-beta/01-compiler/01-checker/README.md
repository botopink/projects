# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17 on feat; step 6 box 3, steps 10,
13, 18–20 and nine rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `16-formatter` step 8 (step 10) · `02-erlang` and
`05-wasm` lowering `val [..rest]` / a nested constructor (step 13) · `08-bpp/116` hands the prelude
list (step 19) · decision-gated rows lg2-a (a byte type), lg2-f (type-valued decorator arguments),
lg2-q (`@Decl`'s source location), lg2-e (a method-level `@Decl`'s owner and parameters), lg2-m (a
module-level annotation), lg2-r (a decorator-supplied body), lg2-t (a negative numeric enum leaf) —
each opens a step here when answered, none before.
**Owns:** `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error,diagnostics}.zig`
· `src/parser/**`, `src/parser.zig`, `src/print.zig`, `src/lexer.zig`, `src/lexer/**` · `src/ast.zig`
(the node fields its steps add) · `snapshots/comptime/**`, `snapshots/parser/**` · the cells its
steps add under `tests/language/` (one file per cell)
**Does not touch:** `src/codegen/**` (02–05) · `src/comptime/runtime/**`, `template_eval.zig`,
`decorator_eval.zig` (14, 18) · `src/format.zig`, `src/format/**`, the trivia fields of `ast.zig`
(16) · `parser.zig`'s `isBracedBlockStmt` and the `blockStatementSemicolon` kind (16's C-13 patch,
sequenced after this front's parser rows) · `modules/compiler-cli/**`, `modules/language-server/src/**`
(26) · `libs/std/**` (the std track)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

Every program the checker accepts is one every backend can run with the answer decision 8 gives,
and every program it refuses is refused located, by name. When the front lands, the open rows
below are cells on four targets, and the checker carries decision 266's prelude scope and
decision 247's numeric suffixes and decision 255's two expression forms.

## Done

- Step 1 — the literal join: `[1, "a"]` is a union (decision 150)
- Step 2 — function-typed `case` arms join structurally; a lambda as an arm's value
- Step 3 — `section-body-method` (decision 151); a numeric section leaf standalone
- Step 4 — a record value called is `callee-not-a-function`
- Step 5 — `binding-redeclared` at decision 205's reach (decisions 152, 205)
- Step 6, boxes 1, 2, 4 — `try` in a lambda (decision 147)
- Step 7 — the captured-`var` write refused (decision 148)
- Step 8 — the tuple label through `?T` (decision 45)
- Step 9 — ck2-c (decision 244, built as step 17)
- Step 11 — a tuple after `??`, a postfix read on `( … )`
- Step 12 — `unknown` as a binding name is `reserved-word-as-name`
- Step 14 — the `primitives.d.bp` / `@external(` comment sweep in this front's files
- Step 15 — an imported type re-checked at a second import site keeps its field types
- Step 16 — an inline parameter type (decision 207)
- Step 17 — a default is trailing everywhere (decision 244)
- Decisions 208, 209, 215 — `Ok`/`Error` never constructors; integer literal under `f64`; `f64 == 1` refused
- Rows found by other fronts: decision 170's type half, a std type's constructor through its
  namespace, `unwrapOr`'s width, a behavior `default fn` body checked, the shorthand import never
  reaching a bundled package, the occurs-check message, a primitive behavior extending std's, a
  type parameter widening to its optional, a std module's `pub type`/`pub fn` through its
  namespace, `import-name-collision` for a `fn`/`val` named like an import

## Open

Steps 6, 10 and 13 touch `infer.zig`/`parser/**` like everything else here: one commit per step,
not parallel inside the front.

### Step 6 — `throw` in a `case` arm under `@Result` (box 3)

The checker keeps the enclosing fn's fallible channel in an arm's block; erlang, wasm and beam
answer `Error` on the `throw` path, commonJS refuses at code generation (`JumpInValuePosition`,
`04-js` step 6). The cell lands with 04's lowering.

- [ ] `run/throw_in_case_arm_result` — `return case v { Num(n) -> g(n); _ -> throw "x"; }` under
      `-> @Result<i32, string>`: `isError()` true on the throw path, four targets

### Step 10 — a lambda parameter annotation (T12)

`{ n: i32 -> f(n) }` parses: the lambda-head scan (`parser/exprs.zig`) takes `name: Type` per
parameter; the annotation is the parameter's declared type, unified with the expected one. Blocked:
the formatter prints no lambda parameter annotation, so a `.bp` written with one is reformatted
away by `format --check` — `16-formatter` step 8 adds the printer arm first.

- [ ] `run/lambda_param_annotation` on four targets; `reject/lambda_param_annotation_mismatch` when
      the expected type disagrees

### Step 13 — JS-4's two checker gaps

`val [..rest] = xs;` binds `rest`; `val Pair(Circle(r), n) = p;` is irrefutable when no level can
fail and is accepted. The checker half works (measured with the refusal lifted: commonJS and beam
answer); erlang leaves `Rest` unbound (`erlc` refuses — `02-erlang`) and wasm refuses the nested
pattern (`05-wasm`), so the refusal stays until both lower it.

- [ ] `run/val_spread_only_list_pattern` prints `rest`'s length; `run/val_nested_ctor_pattern`
      prints `r` and `n` — four targets

### Step 18 — numeric literal suffixes (decision 247)

Kotlin's suffixes, lowercase, for every numeric type: `1.5f` `f32`, `1.5d` `f64`, `42l` `i64`, `42u`
`u32`, `42ul` `u64`, `42i8`, `42i16`, `42u8`, `42u16`, `42isize`, `42usize`; an uppercase suffix is a
located error naming the lowercase one; a literal without a suffix never changes type to fit
(`val x: f64 = 1` is refused — decision 209 reversed; 215 stands). The lexer's rule (hex digits
against suffixes, the exponent, a member access on a literal) is this front's; the targets'
representation of `i64` / `u64` / `f32` is the backends'. The lexer has no suffix handling today.

- [ ] the suffixes lex and type, the uppercase and the unsuffixed-mismatch refusals located — one
      `run/` and one `reject/` cell each; the `language-gaps.md` row "`f32` has no literal" closes

### Step 19 — the prelude scope (decision 266)

`compiler-core` accepts, with a module, a list of import items (`element.Element`,
`elements.article`, aliases allowed) as the module's **last scope**: consulted only for a name the
module does not bind itself, so a name the module declares or imports never reaches it. An item
becomes an ordinary import (`import {elements.article} from "<package>"`) in the transformed
program and the emitted code **only when a name of the module resolves through it**; an unused
item emits nothing. The scope names no library — `08-bpp/116` hands it the package's `prelude.bp`
items for a `.bpp` file and owns the `.bpp`-specific refusals (a `prelude.bp` line that is not an
`import`, an item of another package, an activation, the default function's name bound by the
header).

- [ ] a `comptime/tests` fixture: a module handed `[element.Element, elements.article]` that names
      only `article` — the transformed program imports `elements.article` and not `Element`; a name
      the module declares itself resolves to its own declaration; nothing in `src/` names a library
- [ ] `src/comptime/AGENTS.md` states the scope order

### Step 20 — two expression forms (decision 255)

(1) A type name with explicit type arguments followed by `.member` or `(` is a type application —
`Dict<string, unknown>.empty()` (1.0.10's decision 8 §1.3, `Box<i32>(value: 1)`, extended to a
static member); elsewhere `<` is a comparison: a type-argument list is tried only after a type name
and only when its `>` is followed by `.` or `(`, and a list that does not parse as types is a
comparison. (2) `comptime <expr>` is `comptime { break <expr>; }` (`val x = comptime 10 + 5;`
already parses — `test/comptime_template.bp`). Decision 256's bean registry is written with both.

- [ ] `run/type_application_static_member` (`Dict<string, unknown>.empty()`, and `a < b > (c)`
      still a comparison) on four targets; `comptime <expr>` pinned equal to its block form

### Rows other fronts found

- [ ] `@block`'s tail form refused: `val a = @block { 1 + 2 };` checks (`inferBuiltinCallReturnType`
      types a block by its tail expression, which decision 2 refuses) and prints `3` on erlang, beam
      and wasm, `null` on commonJS; `@block { return 3; }` and `@block { … };` as a statement stay
      legal — closes `02-erlang` step 10 and `04-js` step 1
- [ ] `$stringify` refused in every `@External` template, std included (decisions 164, 239): a
      located parser refusal beside `template-self-marker` / `template-marker-out-of-range`
      (`parser/template_markers.zig`, `parser.zig` `ParseErrorType`, `print.zig`); std's
      `Array.join` no longer writes it — `04-js` step 2 adds the cell
- [ ] a module-level `fn` / `val` / `var` named like a primitive type is `primitive-type-name-taken`
      at the name (the `language-gaps.md` row "A function named like a primitive type shadows the
      type in its module") — built and parked on std's `random.bool`, which decision 250 dropped:
      it can land; no such code is on feat
- [ ] a comptime body's diagnostic names the body's file: `infer.zig` (`decoratorError`) hands the
      evaluator the display path, not only the owner's module path, or locates the error at the
      body call when the decorator is the module's own — `comptime_module.zig`,
      `decorator_invocation.zig` assert it (from `14-comptime-on-beam` step 1; `L:C` and the caret
      are already asserted)
- [ ] T17 — the reflection model (`Decl`, `Param`, `Field`, `Method`) resolves inside a decorator
      body by its own identity, so an import named `Param` or `Field` does not shadow it —
      `modules/reflection_type_not_shadowed_by_import` (a decorator module importing a user `Param`
      reads `m.params` of a `@Decl`); today `unknown field 'name' on type 'Param'`
- [ ] a package's module namespace in a type and a value position (`import {report} from
      "validation"`, then `report.X`) as a std module's already works — its exports are known only
      to `comptime.zig`'s `resolveImports`
- [ ] two aliased imports of two same-named **types** stay refused although decision 170 makes them
      legal, until the backends tell types apart by module — the maintainer's question, raised here
- [ ] `infer.zig`'s template memo key appends the whole scope's JSON per call site — O(scope) per
      template call (`14-comptime-on-beam` step 2's remaining cost)
- [ ] row 33 (an `as` alias of an imported type binds the declared name) re-measured in its exact
      shape (two packages, one `App` aliased); a step-4-sized row of the import binding if it
      reproduces, closed otherwise (decision 110's `as` on a type leaf landed —
      `modules/import_alias_on_type`)

**Gate:** standard (fronts.md § Gate) + every re-recorded `snapshots/comptime/**` file read for
expected/found orientation; a refusal that moves a backend fixture is reported to that backend's
front, never deleted here · `botopink check` of every package of the seven repositories identical
to the parent binary and `zig build test-libs` at baseline (a library that reds gets a migration
plan in the commit)

## Notes

- A refusal step (6's throw, 13, the `@block` tail, `$stringify`, the primitive name) is run once
  against the four backend snapshot directories before landing; jhonstart's and rakun's
  workarounds for steps 5 and 7 already hold.
- `parser.zig` is shared by name with 16: this front's parser rows land first; 16's
  `decision-29-parser-half.patch` rebases on them and lands last.
