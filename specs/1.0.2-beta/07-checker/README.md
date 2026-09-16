# Front 07 — checker

**Priority:** high — the checker accepts wrong programs, so a large share of the "happy path"
suite asserts nothing
**Depends on:** [`01-comptime-dispatch`](../01-comptime-dispatch/README.md) for the rows whose
size can only be *measured* once erika compiles (C9 above all). Nothing blocks starting on the
G0 rows
**Owns:** `comptime/infer.zig` · `comptime/types.zig` · `comptime/env.zig` ·
`comptime/transform.zig` · `comptime/eval.zig` · `comptime/error.zig` ·
`parser/{decls,exprs,patterns}.zig` (C5 and the parser gaps; no other front lists them) ·
`snapshots/comptime/**`, and it can move **all four** codegen snapshot directories
**Does not touch:** `codegen/**` (owned by [`04-beam`](../04-beam/README.md),
[`05-erlang`](../05-erlang/README.md), [`06-wasm`](../06-wasm/README.md),
[`08-js-bridges`](../08-js-bridges/README.md)) · `libs/std/**`
([`03-std-surface`](../03-std-surface/README.md)) · `utils/snap.zig`, `comptime/snapshot.zig`
and the test harness ([`09-review-tooling`](../09-review-tooling/README.md),
[`10-comptime-dedup`](../10-comptime-dedup/README.md)). This front **runs alone**: it moves the
typed AST every backend consumes

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless stated
otherwise. Line numbers are at `botopink-lang` HEAD; re-locate by the quoted symbol.

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
| Libraries | 3 of 6 compile at HEAD (`jhonstart`, `onze`, `emilia`); `libs/std` is red on C6, erika on the comptime-dispatch front, rakun on [`12-library-repos`](../12-library-repos/README.md) |
| Library migration cost | ~117 sites, **92 of them in emilia on 680 lines**; C7, C11 and C12's pipeline half cost **zero** |

**Consequence for measurement:** a library-class row can only be *compiled* against jhonstart,
onze and emilia today. `libs/std` contributes nothing until C6 lands, and erika nothing until
[`01-comptime-dispatch`](../01-comptime-dispatch/README.md) lands — which is exactly where C9's
79 swallowed method bodies live (39 of them erika's). Fix C6 first, then re-measure.

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

### Step 1 — G0, the free wins (C6, C4b, C11, C7, C12's pipeline half)

Five rows with **zero** library migration between them, file-disjoint from each other and from
everything below. **C6 is first of all**: `libs/std` is red on it today and every measurement
in the steps below needs std to compile. Per-row mechanism and probe: [`rows.md`](./rows.md).

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
and read the list. That measurement needs std compiling (step 1's C6), erika compiling
([`01-comptime-dispatch`](../01-comptime-dispatch/README.md)) and G1 landed — many swallowed
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
[`types-as-values.md`](./types-as-values.md). A0 is the `libs/std` half and belongs to
[`03-std-surface`](../03-std-surface/README.md); A5 supersedes C6's builtin-specific rows but
**not** its shadowing fix, which must land first.

**Acceptance:**
- [ ] `val T = i32`, `comptime T: type` and `-> type` are usable as annotation, value, parameter
      and return; `id(i32, "s")` reds; `val n = 5; val x: n = 7` reds
- [ ] `types.bp`/`reflect.bp` fns are **executed**, not resolved by name
- [ ] `comptime/tests/builtins_typeinfo.zig` (31 tests) passes without the special cases, and
      `tryResolveTypeManipulationCall` plus the `@makeRecord`/`@RecordKeys`/`@field` builtins are
      deleted

### Step 8 — Narrowing

Every narrowing fixture compiles today or is a documented skip; what they *assert* is still
open. The per-pattern checker table, the 4-backend RUN LOG table and steps B6/B7 are in
[`narrowing.md`](./narrowing.md). B7's "identical RUN LOG" acceptance is blocked on the `@print`
string-rendering decision owned by
[`09-review-tooling`](../09-review-tooling/semantics-decisions.md#decision-1) — it is a
codegen decision, not a checker one.

**Acceptance:**
- [ ] Every kept narrowing pattern has a positive **and** a negative test; no fixture whose only
      assertion is "it compiles"; dropped patterns are deleted from both test files
- [ ] Each executing backend of a narrowing fixture prints the same, correct value under the
      decided string-rendering rule

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-libs` green once [`02-cli-gate`](../02-cli-gate/README.md) has landed
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
type rendering). That is why it runs alone — see `fronts.md` note 3.

## Notes

- **Assigned here by `fronts.md` but not analysed here:** trailing default parameters at the
  call site. It is a checker fix (`comptime/infer.zig` arity checks #1–#7 relaxed to the rule
  already implemented at l.2205-2213, plus a `name → []ast.Param` side table), it needs no
  codegen change, and it must land in this worktree because it edits `comptime/infer.zig`. Its
  analysis travels with the module-health split; pick it up before starting step 2.
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
- **C6 versus [`03-std-surface`](../03-std-surface/README.md).** Both name the `pick` collision.
  The std front cannot fix it without renaming a public std function; the durable fix is C6 (or
  step 7's A5). Decide before the std front lands, or it renames `random.pick` and this front
  renames it back.
- **Do not parallelise inside this front.** Part 0, step 7's A2–A5 and step 8's B6 all touch
  `comptime/infer.zig`. Only C4b, B7 and the `parser/exprs.zig` half of step 6 are independent.
- **C7's chained-default claim** (`record Sym<T, U = T>` accepting `Sym<i32>` with
  `right: "two"`) is a C1 observation, not a separate defect. It becomes visible the moment C1
  lands; verify it then.
