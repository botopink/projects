# Front 01 — checker

**Priority:** high — every backend front reads the typed AST this front produces; the open rows are
programs that check and then fail at run time, which is the one class of defect a backend cannot
fix.
**Depends on:** `00-gate` (ZF-1…11 — `comptime/{env,infer}.zig` and `parser/patterns.zig` are three of
the eleven `zig fmt` files; nothing here stages them before the gate lands) · maintainer decisions
D5 (step 1), 01c-c (step 3), 01c-d (step 5), lg-a (step 6), lg-b (step 7), ck2-c (step 9) ·
decision-gated rows lg2-a (a byte type), lg2-f (type-valued decorator arguments), lg2-q (`@Decl`'s
source location), lg2-e (a method-level `@Decl`'s owner and parameters), lg2-m (a module-level
annotation), lg2-r (a decorator-supplied body), lg2-t (a negative numeric enum leaf) — each opens a
step here when answered, none before.
**Owns:** `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error,diagnostics}.zig`
· `modules/compiler-core/src/parser/{decls,exprs,patterns,types}.zig`, `src/parser.zig`, `src/print.zig`,
`src/lexer.zig`, `src/lexer/**` (the parser area — 15's files, closed) · `src/ast.zig` (the node
fields its steps add; the formatter's trivia fields are 16's) · `modules/compiler-core/snapshots/comptime/**`
· `snapshots/parser/**` · the cells its steps add under `tests/language/{run,reject,modules}/` (one
file per cell, a carve-out of 12)
**Does not touch:** `src/codegen/**` (02–05) · `src/comptime/runtime/**`, `template_eval.zig`,
`decorator_eval.zig` (14, 18) · `src/format.zig`, `src/format/**`, and the trivia fields of `ast.zig`
(16) · `parser.zig`'s `isBracedBlockStmt` and the `blockStatementSemicolon` kind (16's C-13 patch, a
carve-out sequenced after this front's parser rows) · `modules/compiler-cli/**`,
`modules/language-server/src/**` (26) · `libs/std/**` (the std track) · `tests/language/expected-failures.txt`
(delete-only, 12's file)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. Every `file:line` is at HEAD, measured at the milestone's open.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| C-04's last box | `00-compiler-carry-over/README.md` | § C-04, box 6 (ck2-c) |
| `[1, "a"]` / `[1, 2.5]` join | `01-checker/README.md` | § Step 2 — union types, §3.2; § Decisions the maintainer owes, D5 |
| a `fn` in a section body | `01-checker/README.md` | § Step 4, "the parser half of (d)" |
| the tuple label through `?T` | `02-erlang/README.md` · `04-js/README.md` | § Step 4 (the checker's box) · § Step 2 D5 |
| `val [..rest]`, a nested constructor | `04-js/pattern-binding.md` | last paragraph |
| the language-gaps rows | `language-gaps.md` | rows 22 (a section-typed value standalone), 28 (a lambda as an arm's value), 29 (`throw` in a `case` arm), 31 (function-typed arms), 32 (calling a record value), 33 (an `as` alias binds the declared name), 34 (a second binding); T5 (`try` in a lambda, lg-a), T6 (the captured-`var` write, lg-b — the check-time half), T9 (`unknown` as a binding name), T11 (a tuple after `??`, a postfix read on `( … )`), T12 (a lambda parameter annotation) |
| the comment sweeps in this front's files | `08-hygiene/README.md` | § Open, items 1 and 2 (the `01-checker` rows of the ownership table) |

## Problem

Programs that `botopink check` accepts and a backend then refuses or answers wrongly, each
reproduced on a one-module project at the open:

```
val g = G(a: "x"); @print(g().a);              → Checked; node: g is not a function; erlang: {badfun, …}
var n: i32 = 1; n = n + 1; var n: i32 = 10;    → Checked; node: SyntaxError (already declared); erlang: 10
return case s { A(k) -> k; _ -> other(); };    → expected function, got function | function
fn f() -> @Result<i32, string> { return case v { Num(n) -> g(n); _ -> throw "x"; }; }
                                               → Checked; isError() false on the throw path (commonJS and erlang)
val xs = [1, "a"];                             → type mismatch (no join)          [D5]
type T { S { A  fn m(self: Self) {} } }        → this token cannot appear here    [01c-c]
val a: Tok.Alpha = .50;                        → this token cannot appear here
rs.at(0).b  with rs: #(a: i32, b: string)[]    → Checked; erlang badarg, commonJS undefined
{ n: i32 -> f(n) }                             → There must be a 'val' or 'var' …
hit.at(0) ?? #("", "")   ·   (x ?? d)._1       → this token cannot appear here
val unknown: Response = …                      → this token cannot appear here (no name for the reserved word)
```

And one the checker accepts by design of an unanswered rule: `[1, 2].forEach({ x -> try bad(); })`
in a `-> @Result` fn answers `Ok(2)` on commonJS and erlang (lg-a).

## Current state

`tests/language`: 370 `run/`, 346 `reject/`, 58 `modules/`, 64 `test/` cells; the three
`expected-failures.txt` lines are 03's and 05's, none this front's. `zig fmt --check` is red on
`comptime/env.zig`, `comptime/infer.zig` and `parser/patterns.zig` (00-gate). Every row of the
1.0.10 README's steps 1–14 is ticked except step 4 (d)'s parser half and step 2's D5; the checker
half of every carried row above holds (R1–R9, 01c-a, 01c-b). Measured with `botopink check` on
scratch projects at the open; the language-gaps rows were re-run by the audit and each named
above reproduces.

## Mechanism

| Row | Deciding site | What it decides |
|---|---|---|
| a record value called | `infer.zig`'s call inference: a callee whose type is a record value falls through to the record's constructor signature instead of a "not a function" refusal | any value with a constructor-shaped type is callable |
| a second binding | `Env` body scopes (`Env.openBodyScope`) shadow silently; nothing records that a name was already bound in this body | erlang rebinds (a fresh `N@k`), commonJS redeclares |
| function-typed arms | `unify.zig` unifies two `function` types nominally, so two arms with the same signature do not join | `function \| function` |
| `throw` in a `case` arm | the arm body is a lambda body (P3); its `throw` is typed against the lambda's own context, not the enclosing fn's fallible channel | the `throw` becomes the arm's value, not the fn's `Error` |
| `[1, "a"]` | `infer.zig`'s array-literal walk unifies every element with the first (§3.2's join is not built for literals) | type mismatch |
| a `fn` in a section body | `parser/decls.zig`'s section body loop admits leaves and nested sections only; `EnumSection` has no method slot | parse error |
| a section-typed value standalone | `parser/exprs.zig` reads `.50` as a float continuation, and the leading-dot form has no numeric-leaf arm; `infer.zig` resolves a leading dot by the expected type only for identifier leaves | parse error |
| the tuple label through `?T` | `infer.zig`'s label rewrite (`tupleLabelIndex`, `enumSectionRewrites`) runs only when the receiver's type is the tuple itself; decision 45 says a member access on a `?T` is a located error | nothing rewrites, nothing refuses |
| `try` in a lambda | `inferFunctionExprExpected` gives every lambda body `throwContext = .unchecked` | the `try` checks, the `Error` is dropped by the callee |
| a lambda parameter annotation | `parser/exprs.zig`'s lambda-head scan takes identifiers only before `->` | falls back to a block |
| a tuple after `??`, a postfix read on `( … )` | `??` desugars to the optional-binding `if` before its right operand is parsed as a full operand; `parsePrimary`'s grouped-expression arm returns before `parsePostfixChain` | parse error |
| `unknown` as a binding name | `unknown` is a keyword token; the binding-name site has no `reserved-word-as-name` arm for it (the field/parameter sites have one) | the catch-all message |

## Steps

Steps 1–5 all touch `infer.zig`; do not parallelise inside this front. Steps 10–12 (the parser
area) touch `parser/**` only and may run beside 1–5 in the same worktree, one commit each.

### Step 1 — the literal join (§3.2, D5)

An array literal, an `if` and a `case` whose branches disagree infer the union; `[1, 2.5]` is
`f64[]`, `[1, null]` is `?i32[]`, `[1, "a"]` is `(i32 | string)[]` — with no error, the misuse
reported at the use. The maintainer's D5 decides whether a mismatched `case` is the union (the
recommendation, §3.2's own words) or an error; the array literal follows the same answer.

**Acceptance:**
- [x] `val xs = [1, "a"]; @print(xs.length)` prints `2` on four targets; `xs.at(0) + 1` reds at the use naming the widening element — `run/array_literal_union`, `reject/array_literal_union_misuse` — wasm cannot read an element of a union array (`05-wasm`'s row), so the cell reads `length`
- [x] `[1, 2.5]` is `f64[]` and `[1, null]` is `?i32[]` (`run/array_literal_numeric_join`)
- [x] the `case`-as-value answer per D5, one cell (`run/case_value_union` or `reject/case_arms_mismatch`) — `test/case_value_union` (a `test/` cell: wasm traps on a union of primitives a `case` produces)
- [x] no existing `snapshots/comptime/**` file moves except the two slugs named for the union answer — no `snapshots/comptime/**` file moved

### Step 2 — function-typed arms and a lambda as an arm's value (rows 28, 31)

`unify.zig` joins two `function` types structurally — same arity, unifiable parameters, unifiable
return — so `case s { A(k) -> k; _ -> other(); }` with both arms `fn(string) -> string` types. A
lambda literal in arm-value position (`A(x) -> { item -> f(item) }`) parses as the lambda it is:
the `{` after `->` is a lambda when a `->` follows its parameter list, a block otherwise (the same
disambiguation `parseBlockBody` makes for a trailing lambda).

**Acceptance:**
- [x] `run/case_function_typed_arms` prints the applied result on four targets
- [x] `run/case_arm_lambda_value` — an arm whose value is `{ item -> f(item) }` is applied after the `case` — as `test/case_arm_lambda_value` (beam answers `{badfun, ok}` for a lambda an arm produces, `03-beam`'s row)
- [x] two arms whose function types differ in arity still red at the second arm, located — `reject/case_function_arms_arity`

### Step 3 — a `fn` in a section body (01c-c) and a section-typed value standalone (row 22)

Per 01c-c's answer: (a) `section-body-method` at the `fn`, naming the enum's own method list; or (b)
the method slot. Independently, a section-typed value stands alone: `val a: Tok.Alpha = .50;` when
`Tok.Alpha`'s leaves are numeric — the leading-dot form takes a numeric leaf where the expected type
is a section whose leaves are numbers (the same rule 01c-b gave identifier leaves), so a payload
variant may declare a section-typed field.

**Acceptance:**
- [x] `reject/section_body_method` (01c-c (a)) or `run/section_body_method` ((b)) — (a), `reject/section_body_method`
- [x] `val a: Tok.Alpha = .50; @print(a)` prints the leaf's text on four targets — `run/section_numeric_leaf_standalone`; with no expected type the leaf is refused naming its section (01c-b's rule) — the leaf resolves and runs on four targets; a section leaf prints its mangled name (`__Tok__Percent.__50`) on every target, so the cell reads it through `==`; a `.50` pattern is not built
- [x] emilia's `Token.Alpha(percent: 50, inner: xs)` workaround (front 33) deletable — the library's row, not this front's

### Step 4 — calling a record value (row 32)

A call whose callee's type is a record value (not a constructor, not a function) is
`callee-not-a-function` at the call, naming the value's type and the field access the author
likely meant.

**Acceptance:**
- [x] `reject/call_of_record_value` — `val g = G(a: "x"); g().a` refused at `g(`, located; the same through an imported `pub val` — `reject/call_of_record_value`, `modules/call_of_imported_record_value`
- [x] `G(a: "x")` (the constructor) and a function-typed field `r.f()` still check

### Step 5 — a second binding of one name (row 34, 01c-d)

Per 01c-d's answer: (a) `binding-redeclared` at the second `val` / `var` in a body, naming the first
(a parameter counts as the first); or (b) a fresh binding lowered on commonJS (04's step).

**Acceptance:**
- [x] `reject/binding_redeclared_in_body` and `reject/binding_shadows_parameter` ((a)), or `run/binding_rebound_in_body` printing `10` on four targets ((b)) — (a), at decision 205's reach: every block and `case` arm of the function, parameters included — `reject/binding_shadows_in_inner_block`, `reject/case_arm_binder_reuses_name`; a sibling block's bindings end with it (the strictest reading, any name bound anywhere earlier, refuses 1 674 sites of std and the libraries — the maintainer's to confirm)
- [x] decision 205 replaces this box: an inner block's `val` reusing an enclosing name is refused

### Step 6 — `try` in a lambda (lg-a) and `throw` in a `case` arm (row 29)

Per lg-a's answer (recommendation (1)): a lambda's return is its expected type's; a `try` or
`throw` in a lambda whose expected return carries no `@Result` is `effect-try-without-fallible-channel`
at the `try`. A `case` arm's body is not a lambda for this purpose: its `throw` is the enclosing
function's, so `return case v { … _ -> throw "x"; }` under `-> @Result<i32, string>` answers
`Error("x")` on that path.

**Acceptance:**
- [x] `reject/try_in_lambda_without_result` — `[1, 2].forEach({ x -> try bad(); })` refused at the `try`
- [x] `run/lambda_result_return_try` — a lambda under an expected `fn(x: i32) -> @Result<i32, string>` may `try`
- [x] `run/throw_in_case_arm_result` — `isError()` true on the `throw` path, on four targets (02 and 04 own the lowering if the typed AST already says so; this front's cell pins the type) — **open:** the checker keeps the enclosing channel in an arm's block (commonJS, wasm, beam answer `Error`); erlang lowers the arm's `throw` raw (`02-erlang`), so no cell yet
- [x] the std track's front 08 assertion helpers' lambdas located by the checker (measured, their row) — `libs/std` tests 442/0 on commonJS after the change; every library and example `botopink check`s as before

### Step 7 — the captured-`var` write (lg-b, the check-time half)

Per lg-b's answer (recommendation (1)): a write to a captured `var` from a lambda that is neither a
`forEach` body nor a local closure called at statement position is refused at the write, on every
target, naming the module-level `var` and `#[@BeamMemory]` as the shared-counter form.

**Acceptance:**
- [x] `reject/captured_var_write_in_lambda` — `var n = 0; run({ -> n = n + 1; 1; }, 0)` refused at `n =`
- [x] `test/closure_capture.bp`'s threaded forms still pass on commonJS and erlang; `run/closure_capture_statement_position` on beam too (03 verifies the beam side) — `run/closure_capture_statement_position` on four targets

### Step 8 — the tuple label through `?T` (decision 45)

A member access on the `?T` that `at` answers is the located error decision 45 names, hinting
`?.`; `rs.at(0)?.b` rewrites the label to its position through the optional. Closes 02 step 4's
box and 04's D5.

**Acceptance:**
- [x] `reject/tuple_label_on_optional` — `rs.at(0).b` refused naming `?.` — the checker half held at this base (decision 45); the cell pins it
- [x] `test/tuple_labels.bp` §6 T4 passes on commonJS and erlang with `rs.at(0)?.b`; `run/tuple_label_through_optional` on four targets — present half on four targets; `?.b` on an absent element traps on wasm and raises `badarg` on beam (backend rows)

### Step 9 — C-04's last box (ck2-c)

Decision only: the maintainer answers ck2-c; (a) closes the box as the rule
(`fn-param-default-trailing-only` stays, `docs.md` § defaults says why a record differs); (b) opens
one arity site in `infer.zig` (the free-fn one, `trailing-defaults.md` names the nine) and a cell.

**Acceptance:**
- [x] the box ticked with the answer's id, or `run/fn_leading_default_by_label` under (b) — **open:** ck2-c unanswered

### Step 10 — the parser area: a lambda parameter annotation (T12)

`{ n: i32 -> f(n) }` parses: the lambda-head scan accepts `name: Type` per parameter; the
annotation is the parameter's declared type (unified with the expected one when both exist).

**Acceptance:**
- [x] `run/lambda_param_annotation` on four targets; `reject/lambda_param_annotation_mismatch` when the expected type disagrees — **open:** blocked: the formatter prints no lambda parameter annotation (`format.zig`, front 16), so a `.bp` written with one is reformatted away by `format --check`; the parser/checker half waits for 16's printer arm
- [x] the formatter round-trips the form (`format/tests/expressions.zig` — 16's file; reported, not edited; the arm is 16's) — **open:** 16's

### Step 11 — the parser area: a tuple after `??`, a postfix read on `( … )` (T11)

`hit.at(0) ?? #("", "")` parses (the right operand of `??` is a full operand, a tuple literal
included); `(hit.at(0) ?? d)._1` parses (the grouped-expression arm continues into
`parsePostfixChain`, as R2 already does for `("ab").length`).

**Acceptance:**
- [x] `run/nullish_tuple_operand` and `run/postfix_on_grouped_nullish` on four targets
- [x] no parser snapshot re-recorded; new ones classified

### Step 12 — the parser area: `unknown` as a binding name (T9)

`val unknown: Response = …` is `reserved-word-as-name` at the name, naming the word, as a field or
parameter already is.

**Acceptance:**
- [x] `reject/reserved_word_as_binding_name` — the code and the caret at `unknown` — held at this base; the cell pins it

### Step 13 — JS-4's two checker gaps

`val [..rest] = xs;` binds `rest`; `val Pair(Circle(r), n) = p;` is irrefutable when neither
level can fail and is accepted.

**Acceptance:**
- [x] `run/val_spread_only_list_pattern` prints `rest`'s length; `run/val_nested_ctor_pattern` prints `r` and `n` — on the backends whose destructure lowers (03's twin decides beam) — **open:** measured: the checker half (bind `rest`, accept a nested record constructor) works on commonJS, while erlang (`Rest` unbound / no clause matches), wasm (no lowering) and beam (`unresolved_identifier`) do not lower the destructure; left refused until 02/03/05 lower it

### Step 14 — the comment sweeps in this front's files (08 items 1–2)

After every step above, one commit: `env.zig:1057`, `infer.zig:11816,12068` (`primitives.d.bp` →
`primitives.bp`); the `@external(<target>, …)` comments in `infer.zig`, `env.zig`,
`diagnostics.zig`, `ast.zig`, `parser.zig`, `parser/decls.zig` (at HEAD `grep -c '@external('` over
them answers 0 — re-measure; the 1.0.10 sites may have moved or closed). 08 verifies.

**Acceptance:**
- [x] `grep -rIn 'primitives\.d\.bp' src/comptime` returns nothing; no comment presents a retired form as current — `@external(` stays only where a comment describes the refused lower-case form

### Step 15 — an imported type re-checked at a second import site loses its field types (report L, R3)

`rakun-metrics/src/export.bp` imports `RestClient` from rakun-client; `export_test` fails
`unknown type 'CacheLife'` — the checker re-checks `RestClient`'s declaration at the importer's site,
in a scope that does not hold rakun-client's `CacheLife`, and the diagnostic is attributed to
`test/export_test.bp:137`, a line past that 122-line file (the site is
`rakun-client/src/client.bp:137`). The `language-gaps.md` row of the same name; `00-gate/99-gate-rakun`
carries the library workaround (import `CacheLife` into rakun-metrics) until this lands.

**Acceptance:**
- [x] `modules/imported_type_field_closure`: package `a` declares `type Life(ms: i32)` and
      `type Client(life: Life)`; package `b` imports `Client` only and names it in a fn signature;
      the root imports from `b` and calls it — `botopink check` accepts; today it refuses
- [x] a located error inside an imported declaration names the declaring file and line; the — `modules/imported_declaration_error_location` (located at `a/client.bp:8:26`); neither half reproduces at this base — rakun-metrics' `export_test` passes without its `CacheLife` workaround — and both cells pin it
      `reject/` cell asserts the path in the message

### Rows other fronts found

- [x] decision 170's type half — a std module namespace registers its `pub` types only where the
      module declares or names no type of that name; a namespace call whose signature names the
      shadowed type is refused; two types of one declared name in one module (aliased or not) are
      `import-name-collision` — `run/std_namespace_beside_own_type`,
      `modules/std_namespace_beside_aliased_type`, `reject/std_namespace_signature_names_shadowed_type`,
      `modules/import_two_types_one_name`, `reject/own_type_beside_std_type_import`. Two aliased
      imports of two same-named TYPES stay refused until the backends tell types apart by module
      (decision 170 makes them legal; the question is open for the maintainer)
- [x] a std type's constructor through its module namespace (`url.Url(…)`) —
      `run/std_type_ctor_through_namespace`
- [x] `unwrapOr`'s default takes the payload's integer width — `run/unwrap_or_literal_width`
- [x] a behavior's `default fn` body is checked, its `@Result` wrapped, its adopted call typed —
      `reject/behavior_default_fn_body_checked`, `test/behavior_default_fn_result` (beam answers
      `{unresolved_method, …}` for any adopted default, `03-beam`'s row)
- [x] the shorthand import never reaches a bundled package —
      `modules/shorthand_import_beside_bundled_package`; a non-bundled path dependency is still in
      reach (the core has no package identity for a module path; the CLI loader is 26's)
- [x] an occurs-check failure is the type mismatch naming the type parameter —
      `reject/generic_index_answers_optional`, `run/generic_index_optional_return`; a declared type
      parameter is still a flexible variable inside its body (`fn f<T>(x: T) -> T { return 1; }`
      checks)

## Gate

- [x] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [x] `tests/language/run.sh --target all` and `--target beam` green with the new cells; every cell above **proved able to fail** by running it on the parent binary — 1 617 / 0 at the front's tip; each new cell was run on the parent binary (the ones that pass there are named as pins)
- [x] every re-recorded `snapshots/comptime/**` file read for expected/found orientation; the four `snapshots/codegen/**` directories byte-identical except for a fixture a step newly refuses, which is reported to its backend front, never deleted here — moved only where a step's fixture changed source (`throw inside nested fn …`, `test body ---- try on an Error …`, `narrow ---- case enum area with print`, `access variant-specific field after matching`), each by its own source line
- [ ] `libs/std` and every `examples/` project `botopink check` clean; `zig build test-libs` at baseline — a library that reds gets a migration plan in the commit — `botopink check` of every package of the seven repositories identical to the parent binary; `libs/std` tests 442 / 0 on commonJS; `test-libs` is the coordinator's
- [x] `AGENTS.md` of `src/comptime/` and `src/parser/` in the same commit as each step
- [ ] Commit on `fix/01-checker`; no push, no merge

## Blast radius

`snapshots/comptime/**` (1 079 files at 1.0.10's count) is this front's; a step that refuses a
program a fixture writes moves that fixture's codegen snapshots in all four directories — steps
4, 5 (a), 6 and 7 are the refusals, and each is run once against the four backend directories
before landing. Step 6 under lg-a (1) reds every library lambda that writes a `try` (the audit did
not count them; the step counts before it lands and the count goes in this README). Step 5 (a)
reds rakun front 50's two sites (`build.bp`'s `styles`, `generate.bp`'s `root`) — the row's
workaround already renames them. Step 7 reds jhonstart front 63's counter (the row's workaround
holds).

## Notes

- **The four backend fronts read this front's output, not its files.** A row here depends on a
  step, not on the front: 02 step 8 and 03 step 4 wait on step 7; 04 step 4 on step 5; 02's and
  04's `throw`-in-arm lowering on step 6's typed AST.
- **`parser.zig` is shared by name with 16:** this front's parser rows land first; 16's
  `decision-29-parser-half.patch` (one `ParseErrorType` member, `isBracedBlockStmt`, one
  `print.zig` message) rebases on them and lands last in the milestone.
- Row 33 (an `as` alias of an imported type binds the declared name) was not re-verified by the
  audit; decision 110's `as` on a type leaf landed (`modules/import_alias_on_type`). Re-measure the
  row's exact shape (two packages, one `App` aliased) as the first act of this front; if it
  reproduces it is a step 4-sized row of `infer.zig`'s import binding, otherwise the row closes.
- The `1.0.10` deep dives (`blast-radius.md`, `decision-8-inference.md`, `residual-rows.md`,
  `trailing-defaults.md`) stay where they are; nothing open cites them beyond ck2-c.
