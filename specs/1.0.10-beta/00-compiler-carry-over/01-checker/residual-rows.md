# Residual rows — what 1.0.4-beta's front 06 did not close

Everything this front owes that is not decision 8's inference. Each row is: **where** it is decided,
**why** it was written that way, what **correct** means, the **probe** at `botopink-lang` `c2dd780`
(run 2026-09-18), and the **acceptance**. Rows that no longer reproduce are at the end, with the
evidence that closed them, so nobody re-opens one.

Paths are relative to `repository/botopink-lang/` (compiler sites to
`modules/compiler-core/src/`). Line numbers are at `c2dd780`; re-locate by the quoted symbol.

---

## R1 — the four declaration-name builders spell surfaces the language deleted

| | |
|---|---|
| **Where** | `comptime/infer.zig:1832` `buildRecordDeclName` (`"record"`), `:1859` `buildStructDeclName` (`"struct"`), `:1891` `buildInterfaceDeclName` (`"interface"`), `:1936` `buildEnumDeclName` (`"enum"`). Called at `:489`, `:498`, `:508`, `:2074`, `:2078`, `:2083` |
| **Why** | they predate front 12's surface cutover: they build the binding's *display* name from the declaration, and nothing renamed them when `record`/`enum`/`interface` became `type`/`type`/`behavior` and `struct` was removed outright |
| **Correct** | one builder per `TypeDecl` / `BehaviorDecl` shape, spelling the 1.0.3 surface: `type Name(field: T)` for a record-shaped `type`, `type Name { Variant(…) }` for an enum-shaped one, `behavior Name { … }`. `buildStructDeclName` is dead — `struct` does not parse — and goes with it |
| **Probe** | read at `c2dd780`; the string is the one hover and completion print, so the language server shows a surface that no longer parses. The 1.0.4 tooling front named it as the one user-visible string it could not reach |
| **Acceptance** | hover on a `type` declaration prints its 1.0.3 spelling; `completion_decorator_record` is re-recorded and read; no `record {`, `enum {`, `interface ` or `struct {` literal is left in `infer.zig` |

`modules/language-server/src/**` is **not** this front's. The string is built here, so the fix is
here; the LSP snapshot it moves is re-recorded here and the change reported to whoever owns the
language server this milestone.

## R2 — importing a type requires importing its whole type closure

| | |
|---|---|
| **Where** | the import/type registration path — `comptime/env.zig` `resolveTypeName` plus `codegen/crossModule.zig`'s registration of an imported module's typedefs |
| **Why** | an import binds the names in its `from` clause; a typedef reached only through an imported declaration's *field* or *method signature* is never registered, and C10's two-pass registration (which landed) registers the module's own typedefs, not a dependency's transitive ones |
| **Correct** | importing a type registers the closure of the types its declaration mentions — field types and method signature types, transitively — without binding their constructors unless they are named |
| **Probe** | `src/users.bp`: `pub type Role(name: string)`, `pub type User(role: Role) { pub fn roleName(self: Self) -> string {…} }`, `pub fn makeUser() -> User`. `src/main.bp`: `pub mod users; import { User, makeUser } from "users";` → `error: unknown type 'Role' --> src/main.bp:2:21` (the caret sits on `makeUser`). Adding `Role` to the clause checks |
| **Acceptance** | the probe checks without naming `Role`; naming it still checks; a type genuinely absent from the module still reds, at the annotation |

Two sub-defects in one probe: the rule itself, and the caret, which points at the wrong element of
the import list. Fix both.

## R3 — `#[@external(node, "…")]` in lower case binds nothing, silently

| | |
|---|---|
| **Where** | the annotation grammar in `parser/**`; only `External.<Target>` matches `FnDecl.isExternal` |
| **Why** | the annotation parser accepts any `#[@name(...)]` and the external check keys on the capitalised form; a lower-case one falls through as an unknown annotation and is dropped |
| **Correct** | a located error naming the correct spelling — `#[@External.Node(…)]` — at the annotation |
| **Probe** | `#[@external(node, "Math.abs($0)")] declare fn absVal(x: i32) -> i32;` then `@print(absVal(-3));` → `Checked`, exit 0 |
| **Acceptance** | `reject/external_lowercase_target.bp` is rejected with a located message naming the capitalised form |

## R4 — a record field typed by a behavior rejects an implementing record

| | |
|---|---|
| **Where** | `comptime/unify.zig` — a nominal type is compared to a behavior by name |
| **Why** | behaviors are types only at the method-table level; a field annotated with a behavior has never accepted an implementer |
| **Correct** | a value whose type implements the behavior (following the behavior's `extends` chain) unifies with the behavior-typed field; one that does not reds at the value |
| **Probe** | `behavior Handler { fn run(self: Self) -> i32; }`, `type H(id: i32) implement Handler { … }`, `type Holder(h: Handler)`, `Holder(h: H(id: 1))` → `type mismatch: expected Handler, got H` at `4:35` |
| **Landed** | `unifyArgument` / `behaviorReaches` in `comptime/infer.zig` — every call-argument and constructor-field site; the `return` coercion follows `extends` too |
| **Acceptance** | the probe checks; a non-implementing record in the same position reds at the value |

`typeAnswersMember`, added by C9 (`75a6906`), already walks an `implement`ed behavior and its
`extends` chain — reuse it rather than writing a second walk.

## R5 — a pattern in binding position binds nothing

| | |
|---|---|
| **Where** | the `val <Pattern> = <expr>` path in `comptime/infer.zig`; `parseLocalBindExpr` parses it |
| **Why** | `bindPatternNamesForSubject` is called for a `case` arm and (since `d2b468d`) for a `val assert`, but not for a plain destructuring bind |
| **Correct** | the same walk, with the same typing, and the same refusal when the pattern cannot fail-safely cover the subject |
| **Probe** | `val s = Shape.Circle(r: 2); val Circle(r) = s; @print(r);` → `unbound variable 'r'` at `2:71` |
| **Landed** | `bindDestructPattern` in `comptime/infer.zig`. Decided failure behaviour: the bare form checks only where the pattern is irrefutable over the subject's type (one-variant `type`, record constructor, spread-only list); otherwise `refutable-val-pattern` at the binding |
| **Acceptance** | `val Circle(r) = s;` binds `r: i32`; `val s: string = r;` after it reds. The commonJS lowering that follows is [`../04-js/pattern-binding.md`](../04-js/pattern-binding.md) |

## R6 — no lowering is recorded for a method on an associated fn's result

| | |
|---|---|
| **Where** | `comptime/infer.zig` — the receiver's type is left open when the receiver is the result of a qualified associated-fn call |
| **Why** | associated-fn calls resolve through a different path from instance calls, and it stores no result type for the receiver of the next `.` |
| **Correct** | the associated fn's declared return type becomes the receiver's type, and the method resolves against it, recording the lowering the backends read |
| **Probe** | `@print(Array.range(0, 3).map({ x -> x + 1 }));` → `Checked`, and the emitted erlang is `'__bp_prim_map'(array:range(0, 3), fun(X) -> …)` — a run-time dispatch helper with an `erlang:error({bp_unsupported_method, …})` tail |
| **Acceptance** | the probe records a lowering; no emitted erlang carries `'__bp_prim_map'` for it. The erlang half (and the separate `array:range/2` defect the same probe exposes) is [`../02-erlang/`](../02-erlang/README.md) |

## R7 — decision 2 is not enforced

| | |
|---|---|
| **Where** | `comptime/infer.zig` — the block/`if` walk; `stmtsYieldValue` (added by `75a6906`) already distinguishes a block that has a value from one that does not, and is used only to gate the `if`-branch unification |
| **Why** | the enforcement half of C1/C2 was never written; a valueless block in value position and a non-`unit` fn falling off its end both type as `void` and unify with anything reachable |
| **Correct** | [decision 2](../../../1.0.4-beta/08-review-backlog/semantics-decisions.md#decision-2) — a block is a statement and its value comes from `break`. A valueless block in value position reds with a location; a non-`unit` fn with no final `return`/`break` reds at the declaration |
| **Probe** | `fn f() -> i32 { val x = 1; }` → `Checked`. `fn f(c: bool) -> i32 { val y = if (c) { 1 }; return 0; }` → `Checked` |
| **Acceptance** | both probes red with a location; the decision is written into the language reference; the four backend fronts are told, **by name**, which of their lowerings become dead: erlang's tail `case`, beam's `make_fun3` (12 sites in `codegen/beam_asm.zig`), commonJS's IIFE (27 `(() =>` sites in `codegen/commonJS.zig`), wasm's `;; lambda` |

## R8 — `type` as a value is still any binding

| | |
|---|---|
| **Where** | `comptime/env.zig` `resolveTypeName` — the bindings arm. C10 (`3a5ac7a`) replaced the *opaque named type* fallback with a located `unknown type`; the bindings arm survived, by design ("do C10's two-pass registration there and let A1 delete the bindings arm") |
| **Why** | the bindings arm is load-bearing for imported records/enums, where the import binds a constructor value while the typedef stays in the defining module |
| **Correct** | types-as-values **A1**: a real `type` kind in `comptime/types.zig`. `val T = i32` is a type value; `val n = 5; val x: n = 7` reds; the constructor carve-out becomes a property of the `type` kind rather than of any binding |
| **Probe** | `val n = 5; val x: n = 7;` → `Checked` (while `val T = i32; val x: T = "s";` correctly reds) |
| **Landed (narrow)** | `Env.resolveTypeName`'s bindings arm accepts a function-typed binding, a declaration's own binding, a primitive and a `val` recorded in `Env.typeValueNames`; any other binding is refused. A1's `type` kind itself is not built — the arm is narrowed, not deleted |
| **Acceptance** | `val n = 5; val x: n = 7;` reds; `val T = i32; val x: T = 1;` checks; every existing import of a type still checks |

A2–A5 of types-as-values (`#[@code]`, `@typeInfo` as a value, a comptime eval loop, std type
functions in `.bp`) are **not** in this milestone: A2 needs decision D7 and a call in TypeRef
position, and A4's evaluator is [`14-comptime-on-beam`](../14-comptime-on-beam/README.md)'s subject matter. A1 is the half C10 left
half-done and is cheap here.

## R9 — three N25 diagnostics

`3e7cd62` landed §9's missing-annotation rule; three rejection cells still fail for the wrong reason.

| Cell | Today | §9 |
|---|---|---|
| `reject/wrapper_without_annotation.bp` | a return-type mismatch at the `return` | the missing-annotation rule, at the return type |
| `reject/val_assert_after_catch.bp` | accepted (exit 0), then fails at run time — `Ok is not defined` on commonJS, `variable 'N' unsafe in 'case'` on erlang | `val assert Ok(n) = f() catch 0` is an error: after `catch` the value is not a `@Result` |
| `reject/two_effect_markers.bp` | the R5 message is right; the caret points at the body's `{` (5:41) | the caret points at the second annotation |

`d2b468d` added `checkAssertPatternSubject`, which reds a `catch` after a `@Result` — the second row
is that check not reaching the `f() catch 0` shape, where the trailing `catch` binds to the assert
under the grammar and `fatal` is what tells the forms apart.

**Landed** (compiler `912467b8`): all three cells pass; one snapshot re-recorded (`comptime/errors/a_result_return_without_result`, caret moved to the return type).

**Acceptance:** the three cells are rejected for their own reason, each with a caret on the offending
token, and their lines leave `expected-failures.txt`.

---

## The parser gaps

Five gaps, all probed at `c2dd780`. The pattern half of the nested-payload gap parses since
`dff3446` (`.Some(#(a, b))`) and is not listed.

| Gap | Probe at `c2dd780` | Site | Change | Blast radius |
|---|---|---|---|---|
| `if (a && b)` / `if (a \|\| b)` | `Unexpected token` at `&&` | `parser/exprs.zig` — the `if` condition parses at `prec.equality` | `prec.lowest`, **at that call site only** | few. Safe because the condition is parenthesised by the grammar; `if ((a && b))` already parses and checks |
| `_` as an `if` binder | `Unexpected token` at `_` | the binder lookahead accepts `.identifier` before `->` only | also accept `.underscore`, `binding = null` | none — no AST change |
| `assert <expr> is <Pattern>` | `is-variant-binding` at the `(`, since `3b491e3` | no production | a statement form binding into the **enclosing** scope | few parser + new checker work. Needs step 4's pattern typing. The three skips it closes are `comptime/tests/narrowing.zig:213`, `:230` and `codegen/tests/narrowing.zig:83` |
| `<Pattern> as <name>` | `Unexpected token` at `as` | `parser/patterns.zig` | a `Pattern.bound` variant | **many** — every pattern consumer, including four backend lowerings this front does not own. **Decided (decision 11): the form is not part of the language**; the three `comptime/tests/variants.zig` tests are deleted |
| unnamed variant payload, **declaration half** | — | `parser/decls.zig`, the variant field list | optional field names with positional fallbacks | **many** — four backends and the reflected `TypeInfo`/`EnumVariant` surface. **Recommend: drop; `name: Type` is the convention** (decision D3) |

**What must not be widened.** There are eleven other `prec.equality` call sites and none of them is
delimited the way an `if` condition is: `comptime <expr>`, the value after `yield [:label]`,
`ident.field = <expr>`, `ident.field += <expr>`, both ends of `parseRangeExpr`, three default-value
sites in `parser/decls.zig`, and the two `case`-subject sites in `parser/patterns.zig` (of which the
single parenthesised one is delimited and *would* be safe, but no fixture needs it — leave it and
record the fact if it is ever widened).

---

## Does not reproduce — closed, with the evidence

Closed. Each was probed at `c2dd780`.

| 1.0.4 row | Probe | Result | Closed by |
|---|---|---|---|
| **A type error's location names the wrong module** (13, 2026-09-18) | `mod other;` where `src/other.bp` writes `pub type Svc(x: Nope)` | `error: unknown type 'Nope' --> src/other.bp:1:17`; the failing module is reported as `other` | C10 + N30 (`3a5ac7a`) gave `TypeRef` a `Loc` |
| **C12's pipeline half** | `val r: i32 = 1 \|> double;` · `val r = 1 \|> add(1, 2);` for a 2-ary `add` | `Checked` · `'add' expects 2 argument(s), got 3` at the RHS | G0 (`ada3911`) |
| **N3** — `if (guard(v))` with `v: ?string` | `fn isStr(v: ?string) -> v is string`, then `if (isStr(y)) { val s: string = y; }` | `Checked` | C5 (`2b03e41`) |
| **N9's CLI half** | any type error | ` --> src/main.bp:5:12` with a source line and a caret | the CLI renderer; the **snapshot** renderer still writes `┌─ :L:C` — step 9 keeps that half |
| **N13** — an undeclared name passes the check | `val assert 42 = answer catch 0;` with `answer` unbound | reds at the name | C12 (`ae146e0`) |
| **N24** — labels lost through instantiation; a fn-typed label called as a method; a label on an array element; a label on a lambda parameter | decision 8 §6's own programs | all four check; two of them never reproduced | `174e0e4` |
| **`while` in `libs/std`** | `grep -rn while libs/std examples --include=*.bp` | 5 hits, **all comments** | front 12 step 3 / the `loop (condition)` landing |
| **erlang's `MissingExternalTarget` with no location** | a `declare fn` annotated for one backend, compiled for another | `error: 'absVal' has no '#[@External.<Target>(…)]' for the erlang backend --> src/main.bp:5:12` with a caret | C13's located half (`7b1db40`) |
| **an imported host-backed `declare fn` has nothing to call on erlang** | `pub mod host; import { up } from "host";` with `#[@External.Erlang(…)] pub declare fn up(s: string)` | `out/host.erl` exports `up/1`; `out/main.erl` calls `host:up/1`; `erlc host.erl main.erl` + `erl` prints `AB` | `063e16b`. The `botopink run --target erlang` failure on the same program is a **CLI** defect, not a codegen one — see [`../02-erlang/README.md`](../02-erlang/README.md#not-this-fronts--reassign) |
| **`assert e is P;`** (C-08's row; the decision record numbers no question for it — decision 11 is the `as` form below) | nothing in `libs/std`, the five libraries, the language suite or the examples writes it; the whole population was three `DOCUMENTED SKIP`s pinning a parse error | **deleted**, with the refusal pinned by `tests/language/reject/assert_is_pattern.bp` (`is-variant-binding` at `16:28`, green by running). The argument, recorded as C-08 asks: the skips claimed the form is promised in `docs.md`, and `docs.md` already lists `assert x is Some(n)` under *deliberately absent*; `val assert <Pattern> = <expr>;` (decision 8 §9) already binds a pattern's names into the enclosing scope and is fatal on mismatch, so implementing it would be a second spelling for one meaning (decision 67); `is` answers a `bool` and tests a type, and making `assert` a hole in that rule reopens exactly what `is-variant-binding` was added to refuse; and the alternative costs a new statement form, pattern typing and four backend lowerings for zero callers | C-08 (`561727e8`) |
| **decision 11 — `<Pattern> as <name>`** | `comptime/tests/variants.zig` held three `DOCUMENTED SKIP`s (`pattern: assign pattern in enum`, `type_unification_does_not_allow_different_variants_to_be_treated_as_safe`, `pattern: assign pattern in record`) whose only claim was that the form does not parse | **deleted**, with their three `snapshots/comptime/ast/` files; nothing in `libs/std`, the five libraries, the language suite, the examples or `docs.md` writes it, and decision 8 does not ask for it. The negative intent of the second test (two arms of different variant types must not unify) is a claim about arm typing, which step 4's `caseArmTypesAgree` pins without the `as` form | C-08 (front/01-checker step 10 close-out) |
