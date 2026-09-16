# Spec 02 — Type System

**Version:** 1.0.1-beta
**Status:** partially delivered — the comptime folder; the checker work carried into
`specs/1.0.2-beta/02-type-system.md`

---

## Objective

Of this spec's scope, 1.0.1-beta delivered one part: **`val x = comptime …` folds to the
value the expression actually has**, and a `comptime { … }` block has a scope.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Delivered — C4, kinded comptime folding

The folder ran both sides of every binary operation through a single integer evaluator, so
`comptime 3.14 * 2.0` and `comptime "Hello, " + "World"` both folded to `0`, every comparison
folded to `0`, and an `if` inside a folded block therefore always took its `else`.

| Behaviour | Where |
|---|---|
| Each operand folds to a kinded `Value` (`integer` / `float` / `string` / `boolean` / `list` / `object` / `null_`) and the operator is applied on the kinds | `comptime/eval.zig` `Value`, `valueOf`, `binary` |
| Int arithmetic stays integral; one float operand promotes the other; `+` concatenates two strings; relational, equality and logical operators yield a `boolean` | `eval.zig` `binary`, `compare`, `equals`, `numeric` |
| An irreducible fold (a record operand, a division by zero) is `null`, not a stand-in `0` | `eval.zig` `binary`, `literal` |
| `comptime { … }` has a scope: a `val`/`var` validates its initialiser in the scope before it, the rest of the block sees the new name | `comptime/error.zig` `CtScope`, `validateBody`; `eval.zig` `Scope`, `blockResult`, `execStmt` |
| The gate accepts `if`, assignment, `&&`/`||`, unary and `true`/`false`/`null` inside a comptime block; the folder follows an `if` into the arm that `break`s | `error.zig` `validateComptimeExpr`; `eval.zig` `valueOf` (`.branch`), `execStmt` |
| `comptime <RecordCtor>(…)` stays rejected, with the reasoning in the code: a fold is spliced as one literal text into all four backends, and a record has no cross-backend literal form | `error.zig` `validateComptimeExpr` (`.collection` → `recordLit` rejected) |
| Each fold is shown next to its source as `ct_N: <declaration> → literal` under `COMPTIME VALUES` | `eval.zig` `evaluate`, `writeListing`, `literal` |

Fixtures that were documented skips and are now real assertions: `comptime_block_with_break`
(folds to `20`), `comptime_folding_float_multiplication_folds_to_literal` (`6.28`),
`template_end_to_end_lookup_ref_splices_a_caller_scope_reference` (prints `ola mundo`, once
`template_eval.zig` emitted the missing `ref/1` host function).

## Verified today

- `zig build test` from `repository/botopink-lang`, cold and warm runtime cache: exit 0, no
  leaks, no `.snap.md.new`.
- The `comptime_folding_*` and `comptime_val_*` snapshots under
  `modules/compiler-core/snapshots/codegen/<backend>/` carry the folded literal on all four
  backends.

## Carried into 1.0.2-beta

`specs/1.0.2-beta/02-type-system.md` — Part 0 rows C1–C3 and C5–C13 (the checker), Part A
(types as comptime values) and Part B (narrowing). C4 is closed and is not repeated there.
