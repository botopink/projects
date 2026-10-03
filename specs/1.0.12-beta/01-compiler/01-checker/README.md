# Front 01 — checker: every program `botopink check` accepts runs the same on four targets

**Priority:** high · **State:** partial: steps 1–9, 11, 12, 14–17 on feat; step 6 box 3, steps 10,
13, 18–20 and ten rows open
**Depends on:** `04-js` step 6 (step 6 box 3) · `16-formatter` step 8 (step 10) · `05-wasm` nested
constructor in a `val` (step 13) · `08-bpp/116` prelude list (step 22) · decision-gated rows lg2-a, lg2-f, lg2-q, lg2-e, lg2-m, lg2-r, lg2-t — each a step here only once
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

### Step 18 — numeric literal suffixes (decision 247)

Kotlin's, lowercase, every numeric type: `1.5f` `f32`, `1.5d` `f64`, `42l` `i64`, `42u` `u32`,
`42ul` `u64`, `42i8`, `42i16`, `42u8`, `42u16`, `42isize`, `42usize`. Uppercase = located error
naming the lowercase; unsuffixed never changes type to fit (`val x: f64 = 1` refused — 209 reversed;
215 stands). Lexer rule (hex digits vs suffixes, exponent, member access on a literal) here; target
representation of `i64` / `u64` / `f32` the backends'. Lexer has no suffix handling today.

- [ ] the suffixes lex and type, the uppercase and the unsuffixed-mismatch refusals located — one
      `run/` and one `reject/` cell each; the `language-gaps.md` row "`f32` has no literal" closes

### Step 19 — a type application before a member (decision 255 (1)) — done

`Dict<string, unknown>.empty()`: a type name with explicit type arguments followed by `.` or `(` is a
type application (1.0.10 decision 8 §1.3 extended to a type's member); elsewhere `<` is a comparison.
The list goes to the chain's first link (`receiverTypeArgs`); the checker binds the type's parameters
(`applyReceiverTypeArgs`). Built: `run/type_application_static_member` on four targets,
`reject/type_application_{argument_mismatch,argument_count,variant_payload_mismatch,on_a_field}`,
`botopink format` round-trip (`parser/tests/decision255.zig`, `format.zig` `typeArgsDoc`), `docs.md`
§ Generics.

- [ ] a type application through a module namespace (`collections.Dict<K, V>.empty()` — the head is a
      value's name, so the list is a comparison there): built, or refused with a located message

### Step 20 — `comptime <expr>` (decision 255 (2)) — done (measured and pinned)

`comptime <expr>` is `comptime { break <expr>; }`: parser, checker, evaluator (`eval.zig`) and gate
(`validateComptime`) read it as the block. Built: `run/comptime_expression_is_block`,
`run/comptime_expression_static_call` (commonJS, erlang, beam; wasm `.wasm.expect`),
`reject/comptime_expression_type_mismatch`, format round-trip. What it *means* was question `ck4-a`,
answered by decision 266 (step 21).

### Step 21 — `comptime` evaluated at compile time everywhere (decision 266, `ck4-a` (c))

Measured: at module level `validateComptime` refuses any call ("'call' is a runtime identifier"); in a
body nothing is evaluated (`val a = comptime two();` lowers as `const a = two();`), and wasm lowers no
comptime construct in a body. Decision 266: a `comptime <expr>` is built at compilation wherever it is
written, a record value (`Dict`) included, the registry hoisted.

- [ ] `val d: Dict<string, unknown> = comptime Dict.empty();` built at compile time at module level and
      in a body, on four targets (each backend emits the record's construction)
- [ ] a call in a `comptime` is evaluated by the comptime runtime; a body's `comptime` goes through the
      same gate and fold as a module-level one
- [ ] the libraries' bodies that write `comptime` around a call counted and green
- [ ] found by step 20: a module-level `comptime` `val` after an import is dropped on commonJS
      (`ReferenceError: short is not defined`) and refused on wasm — `import {collections.Dict} from
      "std"; val short = comptime 2 + 3;` (`comptime.zig` `evaluateComptime` against the backends —
      with `14-comptime-on-beam` / `04-js`)

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
