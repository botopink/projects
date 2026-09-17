# Front 06 — checker

**Status:** in progress (`fix/checker`) — **step 1 (G0) delivered** 2026-09-17 (merge `13f61fa`: C4b, C6, C7, C11, C12 pipeline, N17, N26 with `loop (condition)` also lowered on the four backends — 01 step 6's D8-6 pulled forward — and N27). Left from G0: N4/N23, N5, C6's `@makeRecord`-with-comptime-binding case; a condition loop used as a value is refused on erlang/beam (`ConditionLoopValueUnsupported`, unlocated). Opens **after [`../12-surface-cutover/`](../12-surface-cutover/README.md)** (reordered by the maintainer, 2026-09-17): its rules are written on the unified `TypeDecl`/`BehaviorDecl` AST. Carried whole from 1.0.2-beta front 07, plus the rows
collected since — [Step 0](#step-0--rows-added-in-104-beta), N1–N26, including the checker half of
[decision 8](../08-review-backlog/decision-8-language.md).

**Priority:** high — the checker accepts wrong programs, so a large share of the "happy path"
suite asserts nothing
**Depends on:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) (landed first). Before the reorder: [`01-backend-residuals`](../01-backend-residuals/README.md) steps 1–4
and [`05-cli-residuals`](../05-cli-residuals/README.md) landed (2026-09-17, `b4cf700`), and erika
compiles for C9's measurement (`libs/std`'s `String.split("")` fixed, `c8c2541`). 01's steps 5–6 wait
for this front
**Owns:** `comptime/infer.zig` · `comptime/types.zig` · `comptime/env.zig` · `comptime/unify.zig` ·
`comptime/transform.zig` · `comptime/eval.zig` · `comptime/error.zig` ·
`parser/{decls,exprs,patterns}.zig` (C5, the parser gaps, decision 8's syntax) · `lexer.zig` and `lexer/**` (the `new`/`delegate`/`.@"const"` removal) ·
`snapshots/comptime/**`, and it can move **all four** codegen snapshot directories
**Does not touch:** `codegen/**` (owned by [`01-backend-residuals`](../01-backend-residuals/README.md)) · `libs/std/**` (no owner
this milestone — stop and report) · `utils/snap.zig`, `comptime/snapshot.zig`
and the test harness ([`08-review-backlog`](../08-review-backlog/README.md),
[`07-comptime-dedup`](../07-comptime-dedup/README.md)). This front **runs alone**: it moves the
typed AST every backend consumes

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers were measured at the 1.0.2-beta commit this spec was written against; re-locate by the
quoted symbol.

---

## Problem

`zig-out/bin/botopink check` on a scratch project accepts every one of these:

```
fn f() -> i32 { return "s"; }                                  → Checked
val a: bool = case 42 { 0 -> "a"; _ -> "b"; };                 → Checked
val q = "a" * "b";        val q = -"s";                        → Checked
enum E { A(v: i32), B }   case e { A(v) -> f(v); … }           → Checked   (f takes a string)
record D { val id: i32, fn bad(self: Self) -> string { val z: string = self.id; return z; } }
                                                               → Checked
val d = D(id: 1); val q = d.swim();                            → Checked   (no `swim`)
record Q { lat: bogusType }                                    → Checked
val n = 5; val x: n = 7;                                       → Checked
fn f(x: ?i32) -> i32 { return x + 1; }                         → Checked
val q = comptime 1 / 0;                                        → Checked
val assert 42 = answer catch 0;   (`answer` unbound)           → Checked
```

and rejects these, which are correct:

```
val q: bool = (1 && true);                  → expected i32, got bool at main:1:18   (reversed)
val n: Option2<i32> = Option2.None;         → expected Option2, got Option2
val b: bool = isPositive(5);                → expected bool, got i32   (a `-> n is i32` guard)
val alice = Person(name: "a", age: 1);
val b = Person(..alice, age: 25);           → expected string, got Person at main:3:18
fn pick(a: i32, b: i32) -> i32 { … } val v: i32 = pick(1, 2);
                                            → pick: first argument must be a type name
```

The last one is why `libs/std` does not compile at HEAD:
`error: pick expects a type and field names at random:141:13`.

## Current state

Every row was re-confirmed at HEAD by reading the code and by `zig-out/bin/botopink check` on a
scratch project; the probe output is quoted per row in [`rows.md`](./rows.md).

**Closed by the 1.0.1-beta comptime-folding wave — do not re-open:** C4 (`comptime val`
folding). `comptime/eval.zig` folds by operand kind, `comptime { … }` has a scope in
`comptime/error.zig` + `eval.zig`, and `comptime <RecordCtor>(…)` is rejected on purpose. One
residual remains, **C4b**.

`comptime/infer.zig` and `comptime/env.zig` were touched in 1.0.1-beta only by the parser wave
(which removed `captureExprArg`'s mirror compensation) and by the snapshot-trace wave. No
checker row was fixed.

| What | Measured at HEAD |
|---|---|
| Rows | 13 correctness rows (C1…C13, C4b), 4 of them behind one shared mechanism each — [`rows.md`](./rows.md) |
| Suite | 733 `test` declarations (437 comptime + 296 codegen), 726 carrying inline `.bp` source |
| Fixtures a fix moves | 76 `assertInfersOk` · 212 error-snapshot files · 796 typed-AST files · 9 documented compile-error skips — [`blast-radius.md`](./blast-radius.md) |
| The tripwire set | 17 slugs / 68 files carry a `typeNameOf` `?` — the checker visibly punting |
| Libraries | *(1.0.2-beta measurement; re-measure — see below)* 3 of 6 compile at HEAD (`jhonstart`, `onze`, `emilia`); `libs/std` is red on C6, erika on the comptime-dispatch front, rakun on [`10-library-repos`](../10-library-repos/README.md) |
| Library migration cost | ~117 sites, **92 of them in emilia on 680 lines**; C7, C11 and C12's pipeline half cost **zero** |

**Consequence for measurement** *(as written for 1.0.2-beta)*: a library-class row can only be
*compiled* against jhonstart, onze and emilia. `libs/std` contributed nothing until C6 landed, and
erika nothing until the comptime-dispatch front landed — which is exactly where C9's 79 swallowed
method bodies live (39 of them erika's).

**Since then** (library gate on `botopink-lang` `ed15323`): the comptime-dispatch front, C6's
shadowing half (the `env.lookup` guard at the type-manipulation intercept, landed by the 1.0.2-beta
std-surface front) and the four backend fronts are in. `test-libs` passes emilia, onze, rakun and
`libs/std` (commonJS + erlang); erika (commonJS + erlang) and jhonstart (commonJS) are known-red on
`libs/std`'s `String.split("")` alone ([`../fronts.md`](../fronts.md#unowned-items)). Re-measure every
library count in this front, and in [`blast-radius.md`](./blast-radius.md), before step 1.

## Mechanism

Four mechanisms produce almost every row. Fixing a mechanism once is cheaper than fixing its
instances, and the rows that share a mechanism share a snapshot regeneration.

| # | Mechanism | Rows |
|---|---|---|
| M1 | **A fresh type variable is the escape hatch.** `env.freshVar()` unifies with anything, so any construct the checker cannot type yet is given one and nothing downstream ever contradicts it | C1, C2, C5, C8, C9, C12 |
| M2 | **`unifyAt` is target-first and several callers pass operand-first** (`infer.zig` l.3769-3777 documents `a` = the declared/expected type) | C3, C13 |
| M3 | **One-way optional subsumption is reached from the wrong side** — `unify.zig` l.48-52 lets an *expected* `?T` accept a plain `T`, and arithmetic passes an operand as `a` | C3, and every "narrowing is not needed" false negative in [`narrowing.md`](./narrowing.md) |
| M4 | **Best-effort walks swallow errors** — `inferTypeMethods` (l.2916-2967) skips a method body that trips an inference gap | C9 |

Why each is written that way, and the one row (C6) that belongs to none of them, is in
[`rows.md`](./rows.md#the-four-mechanisms). `unify` itself never carries a location: a location
appears only when the caller went through `unifyAt`, and the two arithmetic call sites
(`infer.zig` l.5386, l.5394) do not.

## Steps

The rows are grouped so that each group is one landing unit; the ordering argument, including
what breaks if a group is split, is [`groups.md`](./groups.md).

### Step 0 — rows added in 1.0.4-beta

Found after this front's spec was written — by the 1.0.2-beta comptime-dispatch and review-tooling
fronts, by the 1.0.3-beta example review (compiled at `botopink-lang` `41981e3`), by the maintainer's
decision 2, and by the four 1.0.4-beta backend landings (N10–N15, and new evidence on N5 and N6;
[`../01-backend-residuals/`](../01-backend-residuals/README.md#routed-out)). None is a new mechanism; each **lands with the group named**, in that
group's commit, so no family of snapshots is regenerated twice.

| # | Row | Lands with | Evidence |
|---|---|---|---|
| N1 | **Trailing default parameters at the call site.** `h1(x)` against `fn h1(children: Children, attrs: … = [])` reds `'h1' expects 2 argument(s), got 1`: inference rejects the call before `transform.expandTrailingDefaultsWithParams` can fill it. Relax the arity checks to the rule the decorator-application check already implements (`required ≤ args ≤ params.len`); record constructors are the same defect; instance methods must expand too (today they neither red nor expand). No codegen change | before G1 (step 2) — it was 1.0.2-beta comptime-dispatch step 3, never executed | [`trailing-defaults.md`](./trailing-defaults.md) |
| N2 | **A default on a non-last record field is not applied:** `record P { x: i32 = 0, y: i32 }` then `P(y: 2)` → `'P' expects 2 argument(s)` | with N1 (same arity checks, labelled form) | 1.0.3-beta review row 6 |
| N3 | **`if (guard(v))` with `v: ?string`** reds `type mismatch expected bool, found string` (`narrow_type_guard_basic_codegen`) | G2 (step 3) — it is C5 seen from a call site | review report 3.3 (`codegen-wat-narrowing.md:65`) |
| N4 | **(Investigated as N23; land them together.)** **The degraded completion path drops every `val`:** `infer.zig` ~`:235` `.val => {}`, so `usePost` is missing from its own completion list (LSP `completion_decorator_record`) | G0 (step 1) | review report 3.12 (`lsp.md:104`) |
| N5 | **`transform.zig` `makeLiteralExpr` wraps a comptime array as a `numberLit`**, which erlang renders as a charlist and beam now refuses: it aborts with `{unlowered_comptime_value, …}` | G0 (step 1) | review report 3.6 (`codegen-comptime-misc.md:186`); 1.0.4-beta beam |
| N6 | **Decision 2 — a block is a statement; its value comes from `break`.** The checker rejects a valueless block in value position and a non-`unit` fn that falls off its end (`case_nested_case_in_block_arm` becomes a checker error). This is the enforcement half of C1/C2. It also settles `if_simple_conditional_in_fn_body` — a value-less `if` that still prints `undefined` / `ok` / `undefined` / `0` on the four backends after they landed | G1 (step 2) | [`../08-review-backlog/semantics-decisions.md#decision-2`](../08-review-backlog/semantics-decisions.md#decision-2) (decided 2026-09-16) |
| N7 | **A record field typed by a behavior rejects an implementing record:** `expected Handler, got H` | G1 (step 2) — the unify direction it needs is C1's; move it to G3 if it proves to be method-table strictness | 1.0.3-beta review row 5 |
| N8 | **`botopink check` misses unknown type names** (`NoSuchType`, `Dict` without its import) and `return "x"` in a fn returning `i32` — the CLI view of C10 and C1; add the two programs to their acceptance as `botopink check` runs, not only unit tests | G1 (step 2) | 1.0.3-beta review row 7 |
| N9 | **Error snapshots render `┌─ :L:C` with no file name** (`comptime/error.zig` ~`:33`) — every error snapshot | G4 (step 5), which already rewrites that family | review-tooling step 4 (unowned until now) |
| N10 | **E8 — the `#[@result]` wrap goes into each non-jumping arm.** `return case s { Ok -> 1; Fail -> throw "failed"; }` wraps the whole `case`, so a throwing arm answers `isOk()` `true` on erlang (`throw_inside_case_arm`); the wrap is decided in `transform.zig`, so fixing it once re-records erlang **and** commonJS. The erlang landing left it for want of an owner — **the maintainer confirms 06 takes it** | G1 (step 2) — it is the "return target inside an effect body" contract | 1.0.4-beta erlang (E8); [`../01-backend-residuals/measurement.md`](../01-backend-residuals/measurement.md#erlang-is-not-the-oracle) |
| N11 | **JS-4 — a pattern in binding position.** `val Circle(r) = s` parses and the checker reports `r` unbound; `assert x is Some(n)` does not parse (`narrow_assert_pattern_with_print`). The commonJS lowering follows 06 — [`../01-backend-residuals/pattern-binding.md`](../01-backend-residuals/pattern-binding.md) | step 6 (the `assert x is P` form) with C8 (G1) | 1.0.4-beta js-bridges (`src/codegen/js/AGENTS.md` names the blocker) |
| N12 | **`loop_break_with_value`: `fn find(arr) -> i32` returns a list.** commonJS and erlang print `[15, 20]`, wasm formats the array's address; which the program means is a return-type question | with N6 (G1) | 1.0.4-beta beam (old B7), wasm (`tests/control_flow.zig` `KNOWN-WRONG` note) |
| N13 | **An undeclared name passes the check.** `val assert 42 = answer catch 0;` with `answer` unbound compiles on every backend; beam now aborts at run time with `{unresolved_identifier, answer}` — a backstop, not the diagnostic. Every read of an undeclared value name reds with a location | G1 (step 2), beside C10 — C12's `val assert` half (G2) is one instance | 1.0.4-beta beam (`tests/values.zig` "unresolved name aborts" test) |
| N14 | **`run {…}` / `use effect {…}` arity mismatches** reach codegen: the block's parameters and the call's arguments disagree, and beam cannot lower them | with N1 (the arity checks) | 1.0.4-beta beam |
| N15 | **No lowering is recorded for a method called on an associated fn's result** (`Array.range(…).map(…)`): inference leaves the receiver's type open, so erlang falls back to runtime dispatch | G3 (step 4) — method typing on a receiver whose type another call produced | 1.0.4-beta erlang |
| N16 | **(Folded into N26.)** **`while` is not part of the language** (decided 2026-09-17). `while (c) { … }` parses as a call to an unbound `while` with a block; the checker's "not in scope" is the right verdict, but the message should name it (`\`while\` does not exist — use \`loop\``), and commonJS's special case lowering that call to a JS `while` goes (01/12 files, handed over) | G0 (step 1) — a targeted diagnostic | maintainer decision C4 |
| N17 | **The caret of a path error points at the last segment, not the offending one** (`path_access_with_bad_tail_raises_focused_error`, col 25 instead of 19; decided 2026-09-17) | G0 (step 1) | 1.0.1-beta report 3.8 |
| N18 | **Decision 8 §1 — generic types**: written types carry all arguments (1.1), `Self<…>` in generic types and behaviors plus the non-generic implementer rule (1.2), explicit type arguments at a use (1.3), type arguments decided only where a value is born, with the `unknown` fallback warning (1.4) | G3 | decision 8 |
| N19 | **Decision 8 §2 — `unknown`**: one-way assignability, allowed operations, value equality with numbers, `pub` inferred-`unknown` error, no `any` | G3 | decision 8 |
| N20 | **Decision 8 §3 — union types**: `A \| B` syntax, inference from literals and branches (no error), errors at the use, joining of single-value immutable containers and `Dict`, not arrays | G3 | decision 8 |
| N21 | **Decision 8 §4 — `is` by value**: the pattern forms, narrowing with conversion, the always-false warning | G3 | decision 8 |
| N22 | **Decision 8 §5 — `case` arms**: `Pattern { n -> … }`, variant/tuple/literal/`_` patterns, `..`, `.Variant`, names in patterns, `when (…)`, exhaustiveness | G3 | decision 8, plus the inclusive range pattern `A...B` (Zig spelling, decided 2026-09-17) and the located refusal of `A..B` in a pattern |
| N23 | **The `@emit` fallback drops every module `val` binding** (`comptime/infer.zig` ~`:223-243`: the first pass skips `.val` because a body may cite code not yet emitted; when the second pass fails, `comptime.zig` ~`:529-547` returns that list). Infer `val`s tolerantly there — a failure leaves that one `val` unbound. Found by the B6 investigation (`completion_decorator_record`: `other` and `usePost` missing) | G0 (step 1) | 08 report 3.12, 2026-09-17 |
| N24 | **Decision 8 §6 — tuple labels**: labels from construction variables and written types, `row.label` → index at compile time, labels ignored by type comparison, the mismatch warning | G3 | decision 8 |
| N25 | **Decision 8 §9 — effects**: `#[@result]` requires `@Result<T, E>` (and the other effect/wrapper pairs); `val assert Ok/Err` on a `@Result`, refused after `catch` | G2 | decision 8 (was decision 7) |
| N26 | **Decision 8 §10 — `loop (condition)`** and `while` refused with a located message (replaces N16's diagnostic text) | G0 | decision 8 |
| N27 | **`delegate` and `new` stop being keywords** (`throw Error(…)`; `new` is no longer skipped after `throw`), and the unmapped `.@"const"` token variant is deleted (decided 2026-09-17; the VS Code grammar half is [`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md)'s) | G0 | 1.0.4-beta 11 notes |

**Acceptance:**
- [ ] N1: a free fn, a record constructor and an instance method each accept a call that omits a
      trailing default, and the injected argument reaches codegen through `transform.zig`; a
      missing *required* argument still reds (D3); jhonstart's `element.bp` padding `attrs: []`
      can be deleted
- [ ] N2: `P(y: 2)` checks and `x` is `0` at run time
- [ ] N3: `narrow_type_guard_basic_codegen` compiles and narrows
- [ ] N4: the `completion_decorator_record` LSP snapshot lists `usePost`
- [ ] N5: a comptime array reaches erlang as a list of its elements
- [ ] N6: a valueless block in value position and a non-`unit` fn with no final `return`/`break`
      each red with a location; the decision is written into the language reference
- [ ] N7: a behavior-typed field accepts an implementing record and rejects a non-implementing one
- [ ] N8: both programs red under `botopink check`, exit 1, with a location
- [ ] N9: every error snapshot's box names its file
- [ ] N10: `throw_inside_case_arm` prints `true false` on all four backends; no emitted erlang carries
      `{ok, {error, …}}`, and the commonJS module passes `node --check`
- [ ] N11: `val Circle(r) = s` binds `r`; `assert x is Some(n)` parses and narrows
- [ ] N12: `loop_break_with_value` either reds (a list is not `i32`) or is rewritten to what it means;
      its `KNOWN-WRONG` note goes
- [ ] N13: the "unresolved name aborts" program reds under `botopink check` with a location
- [ ] N14: an arity mismatch in `run {…}` / `use effect {…}` reds at the call
- [ ] N15: `Array.range(0, 3).map(…)` records a lowering; erlang emits no runtime dispatch for it
- [ ] N16: `while (i < n) { … }` reds under `botopink check` with a located message naming `loop`; no backend lowers a `while` call
- [ ] N17: the path error's caret points at the offending segment
- [ ] N18–N22, N24–N26: every example of [decision 8](../08-review-backlog/decision-8-language.md) sections 1–6, 9, 10 compiles or fails exactly as annotated (checker half; run time is 01 step 6)
- [ ] N23: a module with a failing `@emit` still binds its well-typed `val`s
- [ ] N27: `val new = 1; val delegate = 2;` check; `throw new Error("x")` reds with a located message naming `throw Error(…)`; no `.@"const"` variant is left

### Step 1 — G0, the free wins (C6, C4b, C11, C7, C12's pipeline half)

Five rows with **zero** library migration between them, file-disjoint from each other and from
everything below. **C6 is first of all**: `libs/std` is red on it today and every measurement
in the steps below needs std to compile. Per-row mechanism and probe: [`rows.md`](./rows.md).
**C6's shadowing half landed** with the 1.0.2-beta std-surface front (a user `pick` beats the
builtin intercept; `libs/std` checks). Re-derive the method half and the `@RecordKeys`/`@field`
typing rows before starting; strike what holds.

**Acceptance:**
- [ ] A user fn **or method** named `pick`/`omit`/`partial`/`mergeRecords` resolves to the
      user's; `botopink check` in `libs/std` no longer reds at `random:141:13`
- [ ] `val k: string[] = @RecordKeys(P)` checks; `@field(p, "x")` has the field's type
- [ ] `comptime 1 / 0` and `comptime -"s"` are comptime errors located at the expression
- [ ] `Person(..alice, age: 25)` checks; an unknown label reds at the label, a wrong value type
      at the value
- [ ] `val n: Option2<i32> = Option2.None;` checks
- [ ] `val r: i32 = 1 |> double;` checks; `1 |> add(1, 2)` for a 2-ary `add` reds

### Step 2 — G1, the emilia wave (C2a, C1, C8, C10 — in that order, one commit each)

The four rows land together because emilia does not compile at any intermediate point: its
nested-section `Token` enum supplies C10's 28 undeclared annotations, C8's 35 payload bindings
and C1's 28 `return out;` at once, and 31 of C1's 44 library sites are `return <ident>` where
the ident came from a `case`, so C1 cannot check them and C2a has nothing to check them
against. emilia is migrated alongside, in the same wave.

**The target of a `return` inside an effect body is the wrapper's inner channel, not the
wrapper** — `#[@result]` → `R`, `#[@future]` → `T`, `#[@generator]` → the `R` channel,
`#[@context]` → the `X` of `@Context<B, X>`. That is the auto-wrap contract the lowering
already records (`wrap_ok` l.5544, `wrap_resolved` l.5560), and it covers 9 library sites, 5 of
them `@Context` in `jhonstart/src/hooks.bp`, which has no `@Context` lowering today.

Land C1 and C8 behind a walk that **reports** instead of failing, triage the two risky
sub-populations (the `return case` fixtures and the 107 bare-identifier returns), then flip to
hard errors — see [`blast-radius.md`](./blast-radius.md#c1--migration).

**Acceptance:**
- [ ] `val a: bool = case 42 { 0 -> "a"; _ -> "b"; };` reds; the mismatched-arm policy is
      pinned in `case_arms_with_different_types_string_i32_union` and
      `case_union_return_type_from_mismatched_arms`
- [ ] `val h = comptime { break 1; }; val z: i32 = h;` checks
- [ ] `fn f() -> i32 { return "s"; }` reds at the value with a caret; `#[@generator]`
      `return 42` against `R = string` reds; `val f = fn(x: i32) -> i32 { return "s"; };` reds
- [ ] `A(v) -> f(v)` reds; same for `Dog(b) | Cat(b)`, `x if (x > 0) -> f(x)`, `Ok(v)`/`Err(e)`
      on `@Result`, `[first, ..rest]`
- [ ] An unknown type name reds at the TypeRef; a non-type binding in annotation position reds;
      forward references to records/enums declared later still check
- [ ] emilia, jhonstart, onze and `libs/std` compile at the end of the wave; the four `-> unit`
      `declare fn`s in `libs/std` are renamed to `void`

### Step 3 — G2, the narrowing prerequisites (C5, then C12's `val assert` half)

C5 makes a guard call usable in an `if`: it is typed `T` today, so the narrowing at
`infer.zig` l.5836-5845 is dead code. `val assert` needs the pattern-vs-type machinery C8
builds. Together with G1 these unblock [`narrowing.md`](./narrowing.md) step B6.

**Acceptance:**
- [ ] `val b: bool = isPositive(5);` checks; the guard body must return `bool`
- [ ] `if (isStr(y)) { val s: string = y; }` checks with `y: ?string`
- [ ] `val assert 42 = answer catch 0;` with `answer` unbound reds

### Step 4 — G3, strictness (C9)

Method bodies join the strict contract that `default fn` interface bodies already have. Before
deciding whether C9 is one row or three, **instrument**: make `inferTypeMethods` count and
print the swallowed errors (swallow site l.2970-2975) over `libs/std` plus the five siblings,
and read the list. That measurement needs std compiling (step 1's C6), erika compiling (its compiler
half landed with 1.0.4-beta erlang; `libs/std`'s `String.split("")` is left) and G1 landed — many swallowed
errors are `return`- and `case`-shaped.

**Acceptance:**
- [ ] A type error in a record method body reds; `val a: string = d.quack()` reds when `quack`
      returns `self.id`
- [ ] Calling an undefined method reds (`methodNotActive` / `unknownMethod`) when the receiver's
      type is known and nominal, and stays permissive for an unresolved type variable
- [ ] An unannotated method's return type is inferred from its body once, then stored
- [ ] The swallowed-error count over the six libraries is published before the flip, and is 0
      after it

### Step 5 — G4, diagnostics, land last (C3, C13)

Both rewrite the 212 files under `snapshots/comptime/*/errors/`; doing them separately
regenerates that family twice, and G1/G3 add new error snapshots that would otherwise be
written in the old format.

**Acceptance:**
- [ ] `1 && true` → `expected: bool, found: i32` with a caret on `1`; `"a" * "b"` and `-"s"`
      red with a location
- [ ] `fn f(x: ?i32) -> i32 { return x + 1; }` reds
- [ ] `#[@result] fn f() -> i32` reports `effect-missing-wrapper` at the return type, not at the
      first body statement
- [ ] Every error snapshot named in the review corpus' unlocated-error root cause has a `┌─` box

### Step 6 — The parser gaps

Five grammar gaps own **seven of the nine** `assertComptimeCompileError` documented skips plus
two `codegen/tests/narrowing.zig` skips. **No checker row can close any of them.** Two carry a
recommendation to delete the tests instead of implementing the grammar — the full table, with
each gap's site, grammar change and blast radius, is [`parser-gaps.md`](./parser-gaps.md).

**Acceptance:**
- [ ] `if (a && b)` and `if (a || b)` parse (`parser/exprs.zig` l.136 → `prec.lowest`), and the
      other five `prec.equality` call sites are unchanged
- [ ] `if (x) { _ -> … }` parses with `binding = null`
- [ ] Each of the remaining three gaps is implemented, or its tests are deleted and the decision
      recorded in [`parser-gaps.md`](./parser-gaps.md)

### Step 7 — Types as values

Replace the name-keyed type functions and the type-resolving builtins with `type` as a
first-class comptime value, `#[@code]`, and std type functions written in `.bp` that are
actually executed. Six steps A0…A5, with what each assumes versus what exists at HEAD, in
[`types-as-values.md`](./types-as-values.md). A0 was the `libs/std` half; 1.0.2-beta std-surface
deleted `types.bp` and `reflect.bp` instead, so the `.bp` type functions A4/A5 execute are written
afresh — see the note under A0 there. A5 supersedes C6's builtin-specific rows but **not** its
shadowing fix, which has landed.

**Acceptance:**
- [ ] `val T = i32`, `comptime T: type` and `-> type` are usable as annotation, value, parameter
      and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds
- [ ] the std type functions (formerly `types.bp`/`reflect.bp`) are **executed**, not resolved by name
- [ ] `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases, and
      `tryResolveTypeManipulationCall` plus the `@makeRecord`/`@RecordKeys`/`@field` builtins are
      deleted

### Step 8 — Narrowing

Every narrowing fixture compiles today or is a documented skip; what they *assert* is still
open. The per-pattern checker table, the 4-backend RUN LOG table and steps B6/B7 are in
[`narrowing.md`](./narrowing.md). B7's "identical RUN LOG" acceptance is blocked on the `@print`
string-rendering decision owned by
[`08-review-backlog`](../08-review-backlog/semantics-decisions.md#decision-1) — it is a
codegen decision, not a checker one.

**Acceptance:**
- [ ] Every kept narrowing pattern has a positive **and** a negative test; no fixture whose only
      assertion is "it compiles"; dropped patterns are deleted from both test files
- [ ] Each executing backend of a narrowing fixture prints the same, correct value under the
      decided string-rendering rule

### Step 9 — Decision 8 in the sources (moved from 12)

Once this front's checker accepts decision 8's forms, migrate the sources to them — compiler test
sources, `libs/std`, `examples/` (the libraries are 13's): `Self<T>` in every generic `type` and
`behavior` (§1.2, then a bare `Self` in a generic declaration is an error); `#[@result] … ->
@Result<T, E>` and the other effect wrappers (§9); annotations on the `val`/`var … = []` that would
fall to `unknown` (§1.4 — 5 in `libs/std`); `while` → `loop (condition)` (§10, `Array.chunked` /
`sliding`); `Display` for `Dict` (§7). `libs/std` is in this step's scope by the reorder.

**Acceptance:**
- [ ] No bare `Self` in a generic declaration, no effect fn without its wrapper, no `while`, in the owned sources
- [ ] `zig build test` and `test-libs` std cells green

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-libs` green once [`05-cli-residuals`](../05-cli-residuals/README.md) has landed
- [ ] `botopink check` clean in `libs/std`, jhonstart, onze and emilia; erika and rakun green if
      their own fronts have landed
- [ ] Regenerated snapshots **reviewed, not blanket-accepted** — a re-recorded error snapshot is
      read for expected/found orientation and for the presence of a `┌─` box
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/checker`; no push, no merge — landing is the maintainer's step

## Blast radius

Full table per row, with the class and the named library, in
[`blast-radius.md`](./blast-radius.md). In summary:

| Class | Rows |
|---|---|
| **library** (a library stops compiling — needs a migration plan) | C1, C8, C9, C10, and possibly C3 |
| **many** (≥ 100 files regenerate, review needed) | C1, C2a, C3, C8, C13 |
| **few** (under ~20 files, mechanical) | C5, C6, C7, C11, C12 |
| **none** | C4b, C2b |
| **unblocks** (something red today goes green) | C5, C6 |

The three rows that cost **zero** library migration do so for a measured reason: there is no
`..` record-update spread, no `|>` pipeline and no `Option`-shaped generic enum in any `.bp`
file in the repository.

This front can move all four codegen snapshot directories, because a fixture that **newly fails
to compile** takes its codegen snapshots with it (all-or-nothing; codegen snapshots carry no
type rendering). That is why it runs alone — see [`../fronts.md`](../fronts.md#conflict-matrix) note 4.

## Notes

- **Trailing default parameters** (Step 0, N1) were analysed by the 1.0.2-beta comptime-dispatch
  front and never executed; the analysis is [`trailing-defaults.md`](./trailing-defaults.md). Pick
  it up before starting step 2.
- **Decision 2 moves code this front does not own.** Once N6 lands, the block-as-value lowerings in
  the four backends (the erlang tail `case`, beam's `make_fun3`, commonJS's IIFE, wasm's
  `;; lambda`) are dead. Deleting them is [`01-backend-residuals`](../01-backend-residuals/README.md)'s work if it is still open,
  else a follow-up registered in [`../fronts.md`](../fronts.md#unowned-items).
- **[`external-annotations.md`](./external-annotations.md)** is carried here as the reference for
  how `#[@External.<Target>(…)]` is used. Its `libs/std` half landed with 1.0.2-beta std-surface;
  its compiler-work rows C1 (one validator for every annotated declaration) and C8 (STD-001 keyed
  on what each backend lowers) name this front. They were **not** in the 1.0.2-beta checker's
  steps: decide with the maintainer whether they join G0/G4 or move to a later milestone.
- **Open questions**, all of which need an answer before the row that depends on them lands:
  - `@code(text)` already exists as a builtin valid only inside template fns (`infer.zig`
    l.3808-3828, lowered through `template_eval.zig`); `#[@code]` would be the first `#[@…]`
    annotation that is neither an effect (`ast.zig` `EffectKind`) nor `@external`. The positions
    do not clash syntactically — confirm the shared name is intended or pick another.
  - **Mismatched `case` arms (C2a): a union type or an error?** `typeNameOf` already renders
    `.union_` and `unify.zig` l.115-130 unifies unions element-wise, so a union is implementable;
    an error is simpler and matches every other position in the language. The library survey says
    the cheaper answer is free — all 32 `case`-as-value blocks in all six libraries are
    type-homogeneous. Two fixture slugs were named for the union answer; read them before
    overruling it.
  - `<Pattern> as <name>`: implement or delete the three tests. A new `Pattern` node reaches all
    four backends for a form no library uses.
  - Unnamed enum variant payloads: the recommendation is to drop them and keep `name: Type` as
    the convention, keeping only the nested-pattern half.
- **C6 and the std front.** The 1.0.2-beta std-surface front landed the shadowing guard without
  renaming `random.pick`; this front must not rename it either. A5 (step 7) supersedes the builtin
  rows, not the guard.
- **Do not parallelise inside this front.** Part 0, step 7's A2–A5 and step 8's B6 all touch
  `comptime/infer.zig`. Only C4b, B7 and the `parser/exprs.zig` half of step 6 are independent.
- **C7's chained-default claim** (`record Sym<T, U = T>` accepting `Sym<i32>` with
  `right: "two"`) is a C1 observation, not a separate defect. It becomes visible the moment C1
  lands; verify it then.
