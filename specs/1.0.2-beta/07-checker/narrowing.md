# Narrowing — what exists, what the tests assert, and the steps

Every narrowing fixture compiles today or is a documented compile-error skip: the 1.0.1-beta
harness wave rebased them, and the codegen fixtures that wrote 0-byte snapshots are gone. What the
tests *assert* is still open — and for most of them the answer is "that the program compiles".

The rows this depends on (C3, C5, C8) are in [`rows.md`](./rows.md); the grammar gaps are in
[`parser-gaps.md`](./parser-gaps.md); where B6 sits in the landing order is in
[`groups.md`](./groups.md).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers are at `botopink-lang` HEAD; re-locate by the quoted symbol.

## What exists

| Machinery | Site | State |
|---|---|---|
| Optional unwrap through a binder, `if (x) { n -> … }` | `infer.zig` l.5795-5806 unwraps `optional<T>` | works |
| Type guards `-> x is T` | parsed at `parser/decls.zig` l.349-357 → `FnDecl.typeGuardParam`; registered in `env.typeGuardFns` (`infer.zig` l.539, l.2865); then-branch narrowing at `infer.zig` l.5808-5845, reading `env.typeGuardFns.narrowedTypeName` (l.5822-5826) | **dead code** — see C5 below |
| `&&` narrowing an optional LHS identifier | `inferBinaryOpExpr` l.5348-5359 narrows before inferring the RHS | implemented, but undone three lines later by C3 |
| Optional chaining `?.` | l.5251-5257 | works (`o.inner?.value` : `?i32`) |
| Comparison narrowing (`x == null`, `x != null`, the `else` of a check) | — | **does not exist**: `inferBranchExpr` narrows only through a binder (l.5795) or a type guard (l.5810-5832) |
| Negative / early-return narrowing (`if (!x) { return …; }`) | — | **does not exist** |

## Checker, per pattern

From `botopink check` at HEAD:

| Pattern | Checker | Mechanism |
|---|---|---|
| `if (x) { n -> … }` | works — `n` is the inner type | `infer.zig` l.5795-5806 unwraps `optional<T>` |
| `if (x) { _ -> … }` | does not parse | parser gap (binder accepts `.identifier` only, `parser/exprs.zig` l.145) — [`parser-gaps.md`](./parser-gaps.md#_-as-an-if-binder) |
| early return / negative check (`if (!x) { return …; }`) | not implemented — `!` requires `bool` and reports it reversed (`expected i32, got bool`) | C3 (M2) at l.5413 |
| `x == null` / `x != null`, and the `else` of a check | parses and checks, but **does not narrow**: inside the branch `x` is still `?i32` (`val y: i32 = x;` → `expected i32, got optional`) | no comparison-narrowing exists; `inferBranchExpr` narrows only through a binder (l.5795) or a type guard (l.5810-5832) |
| `?i32` used arithmetically with no narrowing at all | **wrongly accepted** — `return x + 1` checks | C3 / M3: the optional subsumption in `unify.zig` l.48-52 reached from the operand side |
| `case` on `@Result` / enum payloads | bindings untyped | C8 |
| OR patterns | bindings untyped, and only the first alternative's names are bound | C8 (l.4890) |
| guards `x if (…) ->` | bindings untyped | C8 |
| `assert x is P;` | does not parse | parser gap — [`parser-gaps.md`](./parser-gaps.md#assert-expr-is-pattern) |
| type guard `-> x is T` | the call is typed `T`, so the `if` rejects it before the narrowing at l.5836-5845 runs | C5 |
| `&&` | `if (a && b)` is a parse error (parser gap); `if ((a && b))` parses, and `inferBinaryOpExpr` l.5348-5359 *does* narrow an optional LHS identifier before inferring the RHS — but l.5374-5375 then unifies the LHS with `bool`, so `b && b.weight > 10` on `?Box` reds | parser gap + C3 |
| `?.` | works (`o.inner?.value` : `?i32`) | l.5251-5257 |
| `else if` chain | n/a — the fixture has no null check (`x == 0` on `?i32`) | fixture defect, see B7 |

### The three checker rows behind the table

- **C3 / M3 — why "narrowing is not needed" compiles.** Arithmetic calls
  `unify(env, lhsTy, rhsTy)` (`infer.zig` l.5386, l.5394) with the operand as `unify`'s `a`, so
  `unify.zig` l.48-52 (an *expected* `?T` accepts a plain `T`) fires in the operand direction.
  `fn f(x: ?i32) -> i32 { return x + 1; }` checks at HEAD and the result type is `?i32`. Every "why
  does this compile without narrowing" question resolves here. The subsumption itself is correct
  and load-bearing (`val x: ?i32 = 5`); only the call direction is wrong. The same row makes `!`
  (l.5413) and `&&`/`||` (l.5374-5375) unify operand-first, which is why the negative check reports
  `expected i32, got bool` and why `&&` undoes its own LHS narrowing.
- **C5 — why type guards never narrow.** The parser sets `typeGuardParam = x` **and**
  `returnType = T` on `-> x is T`; `buildFnSignatureType` (l.709-712) and `inferFnDecl`
  (l.2731-2734) then type the call as `T`. The `if` condition path calls `unifyAt(bool, condType)`
  at l.5833, so the branch errors before the narrowed binding is used. Probe:
  `fn isPositive(n: i32) -> n is i32 { return n > 0; } val b: bool = isPositive(5);` →
  `expected bool, got i32 at main:2:15`. C5 is the prerequisite for the two `type_guard_*` rows.
- **C8 — why `case` narrowing asserts nothing.** `bindPatternNamesForSubject` (l.4851-4894) binds
  every name to `freshVar()`; `.@"or"` (l.4890) binds only the first alternative's names. Probe:
  `enum E { A(v: i32), B } fn f(s: string) -> string {…} case e { A(v) -> f(v); B -> "b"; }` →
  `Checked`. **36** fixtures in the suite bind and use a pattern name, concentrated in
  `comptime/tests/narrowing.zig` (9) and `codegen/tests/narrowing.zig` (4) among others — C8 is
  what makes half of this file assertable.

(The type-guard narrowing range is cited as l.5808-5845, l.5810-5832 and l.5836-5845 in different
places of the source analysis; it is one piece of code — re-locate by `typeGuardFns`.)

## What the snapshots actually assert

### Comptime tests — `comptime/tests/narrowing.zig`, 19 tests

The 15 success fixtures all record a `TYPED AST JSON` section (3 more are documented compile-error
skips, 1 is an error snapshot), but **none of them asserts a narrowed type**:

- A fn body is shown as raw source lines (`comptime/snapshot.zig` `extractFnBody`, l.246-257), so
  nothing inside a body — where every narrowing happens — is typed in the snapshot.
- An annotation is rendered by `typeNameFromTypeRef` (`comptime/snapshot.zig` l.239-244), which is
  purely syntactic: only `.named` survives, so `?i32` renders as `?`. It never consults inference.
- A narrowed type is by definition the one no annotation wrote.

So the snapshot only proves the program compiles. The assertion has to be an **annotated top-level
`val`** (whose inferred side goes through `typeNameOf`, `comptime/snapshot.zig` l.477) **plus a
negative error snapshot** — the narrowed use accepted, the un-narrowed use rejected.

The 3 skips are grammar, not checker: two `assert … is` (`:213`, `:230`) and one `&&` (`:285`) —
see [`parser-gaps.md`](./parser-gaps.md).

`comptime/snapshot.zig` is owned by [`10-comptime-dedup`](../10-comptime-dedup/README.md); if that
front renders annotations from inference, the `?` rendering changes for a reason unrelated to this
file, but a narrowed type inside a body still would not appear.

### Codegen tests — `codegen/tests/narrowing.zig`, 11 tests × 4 backends

9 run; 2 are documented compile-error skips (`assert_pattern` l.83, `and_condition` l.144). Every
RUN LOG at HEAD, read from `snapshots/codegen/<backend>/narrow_<slug>.snap.md`:

| Fixture | commonJS | erlang | beam | wasm |
|---|---|---|---|---|
| `if_null_check_with_print` | `42` | `42` | *(empty)* | *(empty)* |
| `case_enum_area_with_print` | `NaN` `NaN` | `12.56` `9.0` | `12.56` `9.0` | *(empty)* |
| `case_result_ok_err_with_print` | `undefined` ×2 | `<<"OK:data">>` `<<"ERR:fail">>` | `{ok,<<"data">>}` `{error,<<"fail">>}` | *(empty)* |
| `early_return_with_print` | `hello world` `nobody` | `<<"hello world">>` `<<"nobody">>` | *(empty)* | *(empty)* |
| `type_guard_basic_codegen` | `true` | `true` | `true` | *(empty)* |
| `type_guard_if_codegen` | `true` | `false` | `false` | *(empty)* |
| `case_option_some_none` | `value: undefined` `empty` | *(empty)* | *(empty)* | *(empty)* |
| `optional_chaining_field_access` | `42` | `42` | `42` | *(empty)* |
| `else_if_chain_with_null_checks` | *(empty)* | *(empty)* | *(empty)* | *(empty)* |

Only `optional_chaining_field_access` and `type_guard_basic_codegen` agree across the three
executing backends. `type_guard_if_codegen` is a live cross-backend disagreement (`true` vs
`false`); the JS payload bindings (`undefined`, `NaN`) and the BEAM `case` arm that prints the raw
`{ok,…}` tuple are backend bugs. wasm prints nothing for any row.

`narrow_type_guard_basic_codegen` and `narrow_type_guard_if_codegen` are also C5's blast radius:
the JS lowering already emits a plain `return true`, so C5 should move only the typed-AST
snapshots, not emitted text — check that no backend keys on the guard fn's return type being `T`.

### Caveat for B7's "identical RUN LOG"

erlang and beam print a string as an Erlang binary (`<<"hello world">>`) where commonJS prints
`hello world`. Rows that print a string therefore cannot be byte-identical across backends without
either a `@print` lowering that formats a binary as text, or a normalisation rule in the
comparison. Decide which before B7 starts — it is a **codegen decision, not a checker one**, owned
by [`09-review-tooling`](../09-review-tooling/semantics-decisions.md#decision-1), and it affects
`early_return_with_print` and `case_result_ok_err_with_print` here as well as rows in the backend
fronts.

## Steps

| Step | What | Acceptance |
|---|---|---|
| B6 | Make `comptime/tests/narrowing.zig` assert the narrowing: each pattern gets an annotated top-level `val` pinning the narrowed type plus a negative error snapshot. Decide and implement or drop the documented skips: `&&`/`\|\|` in `if` conditions (`parser/exprs.zig` l.136 → `prec.lowest`), `_` as an `if` binder (l.145), `assert x is P`, negative/early-return and `else` narrowing, nested patterns. Depends on C5, C8 and — for the "no narrowing needed" false negatives — C3's fix to the subsumption leak | every kept pattern has a positive and a negative test; no fixture whose only assertion is "it compiles"; dropped patterns are deleted from both test files |
| B7 | Narrowing codegen on the 4 backends: every executing backend of a fixture prints the same, correct value under the string-rendering rule decided above. Fix the `else_if_chain` fixture (no null check, `"nonzero: " + x`). Backend output bugs found here belong to the backend fronts, not this one (see below) | the table above has one identical, correct RUN LOG per row across commonJS, erlang and beam (wasm once the WAT runner executes) |

### B6 — dependencies, per pattern

| Pattern | Needs before it can have a negative test |
|---|---|
| `if (x) { n -> … }` | nothing — works today; only the assertion is missing |
| `if (x) { _ -> … }` | the `_` binder grammar change ([`parser-gaps.md`](./parser-gaps.md)) |
| `if (a && b)` / `if (a \|\| b)` | the `prec.lowest` grammar change, **and** C3 (G4) so `b && b.weight > 10` on `?Box` stops redding |
| `x == null` / `x != null` / `else` | new comparison narrowing in `inferBranchExpr` — no row owns it yet; B6 decides implement or drop |
| early return / `if (!x) { return …; }` | C3 (G4) for `!`, then new flow narrowing — B6 decides implement or drop |
| `?i32` arithmetic without narrowing | C3 (G4) — the negative test is exactly the M3 leak |
| `case` payloads, OR patterns, guards | C8 (G1) |
| nested constructor patterns | the pattern half of the unnamed-payload gap ([`parser-gaps.md`](./parser-gaps.md)) + C8 |
| `assert x is P;` | the new statement form ([`parser-gaps.md`](./parser-gaps.md)) + C8 |
| type guard `-> x is T` | C5 (G2) |
| `?.` | nothing — works today |

The landing groups say G1 + G2 "unblock B6"; per the table above that is true for the positive
tests, but the negative tests for `&&`, `!` and optional arithmetic also need G4 (C3), which lands
last. B6 can start after G2 and finish after G4.

### B7 — where the bugs it finds go

| Bug found at HEAD | Owner |
|---|---|
| JS destructuring payloads by binder name (`NaN`, `undefined` in `case_enum_area_with_print`, `case_result_ok_err_with_print`, `case_option_some_none`); `return if` in JS | [`08-js-bridges`](../08-js-bridges/README.md) |
| erlang variant patterns | [`05-erlang`](../05-erlang/README.md) |
| beam variant patterns; BEAM printing the unmatched `{ok,…}` tuple; beam's empty RUN LOGs | [`04-beam`](../04-beam/README.md) |
| wasm narrowing bindings; every wasm RUN LOG empty (the WAT runner does not execute) | [`06-wasm`](../06-wasm/README.md) |
| `type_guard_if_codegen` `true` vs `false` | first confirm C5 does not change it; then the backend that is wrong |
| `else_if_chain_with_null_checks` has no null check | this front — a fixture defect in `codegen/tests/narrowing.zig`, whose harness is owned by [`09-review-tooling`](../09-review-tooling/README.md): coordinate |

B7 touches no `comptime/infer.zig` and can run beside everything else; B6 touches `infer.zig` and
must not run beside Part 0 or [`types-as-values.md`](./types-as-values.md) A2–A5.
