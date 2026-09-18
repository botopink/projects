# Front 05 — wasm

**Priority:** high — wasm is the backend that answers a **wrong value with exit 0 and no
diagnostic**: a record prints as its raw heap address and a `Dict` lookup answers the fallback for a
key that is present
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies). The formatter and the `Dict` row depend on nothing
**Owns:** `modules/compiler-core/src/codegen/wat.zig` ·
`modules/compiler-core/src/codegen/wat/**` (`wat_ast.zig`, `wat_emitter.zig`, `wat_prelude.zig`) ·
`modules/compiler-core/snapshots/codegen/wasm/**` (314 files) · the `KNOWN` notes and new fixtures of
its rows in `modules/compiler-core/src/codegen/tests/**` (a carve-out from [`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`. Every output below was produced against
`botopink-lang` `c2dd780` on 2026-09-18 with `botopink run --target wasm` (wasmtime).

---

## Problem

**A record or a variant prints as a number.** `tests/language/run/print_formatter.bp`:

```
hi
5            (§7: 5.0)
true
[1,2]        (§7: [1, 2])
["a","b"]    (§7: ["a", "b"])
#(1,"a")     (§7: #(1, "a"))
328          (§7: Point(x: 1, y: 2))
336          (§7: Shape.Square(side: 4))
344          (§7: Shape.Nothing)
```

Those three numbers are heap addresses. `run/display_print.bp` prints `264` and `[280,284]` where §7
wants `$5` and `[$1, $2]`.

**A `Dict` lookup answers the fallback for a key that is present.**

```
import { dict } from "std";
val d = dict.empty().insert("a", 1);
@print(d.lookup("a").unwrapOr(0));    → 0   on wasm,  1 on commonJS   (exit 0, no diagnostic)
@print(d.lookup("zz").unwrapOr(9));   → 9   on both — the fallback path is the only one that works
```

`libs/std/src/dict.bp`'s `lookup` is written with `forEach` plus a captured accumulator
(`self.pairs.forEach({ p -> if (p._0 == key) found = p._1 });`), so what fails is a closure writing an
outer variable, read after the loop.

**`break <value>` yields a one-element array**, and **`==` on tuples compares references** — both the
twins of [`04-js`](../04-js/README.md) steps 3 and 4:

```
val r = loop { k = k + 1; if (k > 2) { break k; }; };  →  [3]     (§10: 3)
val a = #(1, "a"); val b = #(1, "a"); a == b;          →  false   (§6 T6: true)
```

Neither has a line in `expected-failures.txt`, because `botopink test` refuses wasm and only `run/`
and `modules/` cells reach it.

**Two string primitives trap.** `"aB".toUpperCase()` → `error while executing at wasm backtrace: …
!main`. The erlang twin emits an undefined function; wasm traps.

## Current state

`zig build test-language` at `c2dd780` is **205 passed, 54 expected failures, 0 failed**. **Four** of
the 54 lines are this front's:

| Line | Row |
|---|---|
| `wasm \| run/tuple_print.bp` | step 1 (F1) |
| `wasm \| run/print_formatter.bp` | step 1 — **F2/F3 need [`13-module-identity`](../13-module-identity/README.md)** |
| `wasm \| run/display_print.bp` | step 1 — **F4 needs [`13-module-identity`](../13-module-identity/README.md)** |
| `wasm \| modules/std_import` | step 3 |

A fifth wasm line, `wasm | run/case_values.bp`, is [`01-checker`](../01-checker/README.md)'s — its
reason text ("case arms and guards do not parse") predates `dff3446`; the arms parse and are not
resolved.

Measured over `snapshots/codegen/wasm/` (314 files):

| Measurement | Count |
|---|---|
| snapshots carrying a `----- RUN LOG -----` block | 305 |
| of those, **empty** (the program printed nothing) | 143 |
| of those, carrying `RUNTIME TRAP (wasmtime):` | **24** — each a shape wasm cannot lower, documented per fixture |
| of those, whose text changes under §7 (array, tuple, float or record text) | **14** |
| files carrying a `RUNTIME TRAP` anywhere | 25 |

The 24 traps are the honest part of this backend: `executeWat` runs (`HARNESS_VERSION =
"3-wasm-runs"`, front 03 wasm of 1.0.4), so a shape wasm cannot do says so instead of printing
nothing. The three heap addresses above are the dishonest part — they are not traps, they are wrong
answers with exit 0.

## Handed over by `01-checker` (2026-09-18) — three defects its step 4 exposes

Front 01's `case`-arm typing is written and measured; six cells **compile** and then fail at run time
on the backends, which is why that step waits for these three. Each is stated with the AST shape, so it
can be implemented without re-deriving it.

1. **A pattern's variant name reaches the backend with its written path.** The constructor emits the
   **bare** name, the pattern emits what was written, so a dotted arm never matches:

   ```js
   if (_s.tag === ".Circle") { … }     // ctor wrote  Shape$Circle.prototype.tag = "Circle"
   ```
   ```erlang
   area(S) -> case S of {'.Circle', R} -> …    %% ctor wrote  {'Circle', 2}
   ```

   Fix: take the last `.`-separated segment of `ast.Pattern.variant.name`, and of `ast.Pattern.ident`
   when it contains a `.`. `infer.zig` already carries `bareVariantName` / `isVariantPath`. **No AST
   change** — the written form is what `format.zig` round-trips.

2. **An arm whose value is its final expression is emitted as a statement**, so the value is dropped
   (commonJS, and beam/wasm through the same IIFE shape; erlang is already right):

   ```js
   if (_s.tag === "Circle") { const { r } = _s; ((r * r) * 3); }   // value discarded
   ```

   The `break` form already lowers correctly. Shape: `ast.Expr.function` with
   `kind.syntax == .lambda` and `kind.params.len <= 1`; the value is the last statement of `kind.body`,
   unless a `jump.@"break"` carries one, which wins.

3. **A one-parameter binder arm never binds its parameter**, on all four:

   ```js
   { "other"; }     // missing `const n = _s;` — `case_guards` fails with "v is not defined"
   ```

   Fix: when `kind.params.len == 1`, bind `kind.params[0]` to the subject at the top of the arm. The
   checker types it as the subject narrowed by that arm's pattern (`inferCaseArmBody`).

Front 01 deliberately did **not** route 1 and 2 through `comptime/transform.zig`, which could reach
them: 3 cannot be done there (binding the parameter needs the subject expression in each backend's arm
scope), and splitting one row across two fronts would move all four codegen snapshot directories —
1258 files — from fixtures that belong to the backends.

## Steps

### Step 1 — the §7 formatter

wasm's printer is type-directed in `src/codegen/wat/wat_prelude.zig` (no named `__bp_print` helper
appears in the snapshots; only 3 carry a named print symbol), which makes it the backend where §7 is
least mechanical and most valuable.

| # | Row | Acceptance |
|---|---|---|
| F1 | spaces after the separator — `[1, 2]`, `["a", "b"]`, `#(1, "a")`, nested strings quoted with source escapes | `run/tuple_print.bp` passes on wasm |
| F2 | **a record prints `Point(x: 1, y: 2)` instead of its heap address** | needs named-type identity — [Dependencies](#dependencies) |
| F3 | **a variant prints `Shape.Square(side: 4)` / `Shape.Nothing` instead of its heap address** | the same |
| F4 | `Display` is consulted, nested too | `run/display_print.bp` passes |
| F5 | `f64` always carries its decimal part — `@print(5.0)` prints `5.0`, not `5` | this front's alone |

**Until F2 and F3 land, a record reaching `@print` must trap, not print a number.** A wrong answer
with exit 0 is worse than a documented `RUNTIME TRAP`, and this backend already has the mechanism:
24 fixtures use it. Make that the interim behaviour in the same commit as F1/F5, and say so in
`src/codegen/wat/AGENTS.md`.

### Step 2 — decision 8 at run time: `is`, unions, `unknown`, `case` arms, labels

wasm is the backend where §2, §3 and §4 cost something. §11: *"one small allocation (tag + payload) —
the boxed `?T` of decision 3, generalised"*.

| # | Row |
|---|---|
| D1 | **the box**: a value entering `unknown` or a union is boxed with a tag; the `?T` box of decision 3 is the shape to generalise, not a second one |
| D2 | `x is T` reads the box tag, then the range (§4.1): an integer within range, any number for `f64`, the primitives, tuple arity and each element |
| D3 | §2.3 — `==` with an `unknown` operand compares numbers by value |
| D4 | `case` arms (§5): type tests, `..`, `when (…)` guards, the dot shorthand, labelled payloads |
| D5 | tuple labels → positional (§6 T4) — the read path works; see step 7 for the call path |

`x is Person` — a **named** type — is not in this step.

### Step 3 — `Dict.lookup` answers the fallback

`modules/std_import` prints `0` where `1` is stored, with exit 0. The std source is a `forEach` with
a captured accumulator, so the suspect is a closure writing an outer local and that write being read
after the loop — the shape 1.0.4's WR1 (closure captures) touched. Reproduce at the smallest level
first: a `forEach` over a two-element array assigning to an outer `var`, printed after.

**Acceptance:**
- [ ] the probe in [Problem](#problem) prints `1` and `9`
- [ ] `wasm | modules/std_import` leaves `expected-failures.txt`
- [ ] a fixture in `src/codegen/tests/**` pins the minimal shape (a `forEach` writing an outer `var`) with a RUN LOG, so the next regression is caught before `Dict` is
- [ ] the wrong-answer class is audited: any other shape that answers a value with exit 0 and no diagnostic is listed in `src/codegen/wat/AGENTS.md` or fixed

### Step 4 — `break <value>`

`[3]` and `[8]` where §10 wants `3` and `8` — the same defect as
[`04-js`](../04-js/README.md) step 3, in a different emitter. No `expected-failures.txt` line exists
because `botopink test` refuses wasm.

**Acceptance:** `tests/language/test/loop_break_value.bp`, run by hand through `botopink run --target
wasm` with an `@print` in place of each `assert`, prints `3` and `8`; a fixture pins both.

### Step 5 — `==` on tuples

`#(1, "a") == #(1, "a")` is `false` — the twin of [`04-js`](../04-js/README.md) step 4. §6 T6: run
time is positional and equality compares elements; T5: labels take no part.

**Acceptance:** the three shapes of `tests/language/test/tuple_equality.bp` answer `true`, `false`,
`true`, run by hand; the negative one must stay `false` for the right reason.

### Step 6 — `String.toUpperCase` / `toLowerCase` trap

`"aB".toUpperCase()` traps at run time. The erlang twin emits an undefined function
([`02-erlang`](../02-erlang/README.md) step 7); wasm has no lowering at all.

**Acceptance:** both methods answer `AB` and `ab`; an audit of the primitive method table lists every
method wasm does not lower, and each is either lowered or carries a documented `RUNTIME TRAP` fixture
— never a silent wrong answer.

### Step 7 — a function value held in a value cannot be applied

`174e0e4` added `tuple_a_labeled_element_of_function_type_is_called_like_a_method` and recorded wasm's
answer as a documented `RUNTIME TRAP`: **wasm has no function values**, so a lambda held in a tuple,
a record field or a variable cannot be applied. Three of the 24 traps are this one shape
(`tuple_a_labeled_element_of_function_type_is_called_like_a_method`,
`call_trailing_lambda_block`, `call_trailing_lambda_with_multiple_params`).

This is a backend capability, not a bug in a row: it needs a function table and `call_indirect`.
Decide in this front whether it lands here or is deferred with its reason written into
`src/codegen/wat/AGENTS.md` — it blocks `Display` (F4 calls a method through a behavior), every
trailing-lambda fixture, and the `forEach` shape step 3 depends on.

**Acceptance:** either a lambda held in a value is applied on wasm and the three `KNOWN-WRONG` notes
go, or the deferral is written down with the list of fixtures it keeps trapping.

### Step 8 — the block-as-value lowering decision 2 leaves dead

Once [`01-checker`](../01-checker/README.md) step 8's R7 enforces decision 2, wasm's block-as-value
lowering (the `;; lambda` shape 1.0.4 names) has no producer. **Locate it first** — `grep ';; lambda'`
over `src/codegen/wat.zig` and `src/codegen/wat/**` returns 0 at `c2dd780`, so either the comment was
renamed or the shape was already removed by the 1.0.4 wasm landing.

**Acceptance:** either the dead lowering is found and deleted, with `snapshots/codegen/wasm/`
byte-identical apart from it, or this row is struck with the evidence that no such lowering exists.

## Dependencies

| This front's step | Needs from [`01-checker`](../01-checker/README.md) |
|---|---|
| 1 (formatter) F1, F5 | nothing |
| 2 D1–D3 (the box, `is`, `unknown`) | steps 1–3 |
| 2 D4 (`case` arms) | steps 4–5 |
| 2 D5 (labels) | nothing |
| 3 (`Dict.lookup`) | nothing |
| 4 (`break <value>`) | nothing |
| 5 (`==` on tuples) | nothing |
| 6 (string primitives) | nothing |
| 7 (function values) | nothing |
| 8 (dead lowering) | step 8's R7 |

**The named-type half of decision 8 is not this front's.** `is Person`, a union of named types, a
`case` over them and §7's F2/F3/F4 all need a value to answer which named type it is at run time —
the third half of [`13-module-identity`](../13-module-identity/README.md). The agreed cut: the backends take primitives, tuples, **the
wasm box** and `loop`; 13 takes named-type identity.

That cut lands on wasm harder than anywhere else, and the front must say so: **the box this front
builds in step 2 is the mechanism 13 needs.** A tag that distinguishes `i32` from `string` and a tag
that says "this is a `Point`" are the same field. So step 2's D1 should be designed **with**
[`13-module-identity`](../13-module-identity/README.md), not merely before it: agree the tag's encoding once, in D1, and let 13 fill in
the named-type range. If that agreement is not reached, D1 is written twice and every boxed value's
snapshot moves twice.

Consequence for acceptance: of this front's four `expected-failures.txt` lines, **two** close here
(`run/tuple_print.bp`, `modules/std_import`) and **two** — `run/print_formatter.bp` and
`run/display_print.bp` — stay listed until [`13-module-identity`](../13-module-identity/README.md) lands.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program** under wasmtime, and checked against decision 8 §7
- [ ] no new `RUN LOG` answers a value with exit 0 that another backend answers differently — a shape wasm cannot do is a `RUNTIME TRAP`, never a wrong number
- [ ] the 24 existing `RUNTIME TRAP` fixtures are re-read: each is still a shape wasm cannot do, or it is fixed
- [ ] `src/codegen/AGENTS.md` and `src/codegen/wat/AGENTS.md` updated in the same commit as each row
- [ ] Commit on `fix/wasm`; no push, no merge

## Blast radius

| What | Count | How measured |
|---|---|---|
| `snapshots/codegen/wasm/` | **314** | `find … -name '*.snap.md' \| wc -l` |
| with a `RUN LOG` block | 305 | parsed out of each file |
| with an **empty** log | 143 | the same |
| with `RUNTIME TRAP (wasmtime):` in the log | **24** | the same |
| whose log text changes under §7 F1/F5 | **14** | matched for `[…]`, `#(`, `\d+\.\d+` |
| with a named print helper in the emitted WAT | 3 | `grep -rl` — the printer is inlined, so step 1 moves emitted text broadly; **measure before starting** |

Step 2's box is the widest row: every fixture whose program puts a value into `?T`, `unknown` or a
union moves, and the boxed representation is visible in the emitted WAT. Measure the set before
starting and record it in the landing note.

**This front does not move any other directory.** If a change here moves
`snapshots/codegen/{erlang,beam,commonJS}/`, something crossed a boundary — stop and report.

## Notes

- **wasm is the only backend that can answer wrongly and silently.** Three §7 values and one `Dict`
  lookup do it today. The rule this front adopts: where wasm cannot do a shape, it traps with the
  existing `RUNTIME TRAP` mechanism; a wrong value with exit 0 is a bug even when a fixture records it.
- **Steps 4 and 5 have twins on commonJS** ([`04-js`](../04-js/README.md) steps 3 and 4). Agree the
  answer — what `break <value>` and `==` mean — and write the emitters separately.
- **`botopink test` refuses wasm**, so only `run/` and `modules/` cells reach it. Four of this
  front's rows have no listed line and are asserted by hand plus a fixture. If the language suite
  ever runs `test/` cells on wasm, this front gains roughly the same lines commonJS carries.

## Rows for `fronts.md`

**Ownership row**

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **05** [`wasm`](./05-wasm/README.md) | `modules/compiler-core/src/codegen/wat.zig` · `modules/compiler-core/src/codegen/wat/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/wasm/**` (314) | steps 1–8; 4 of the 54 `expected-failures.txt` lines |

**Conflict notes**

1. **05 × 02 × 03 × 04 — `yes`.** File-disjoint and snapshot-disjoint. Two rows have twins on
   commonJS (`break <value>`, `==` on tuples): the *answer* is shared, the code is not.
2. **05 × 01 — `yes`.** No shared file. Per-row dependency in [Dependencies](#dependencies); the
   formatter's F1/F5, the `Dict` row, the two twins, the string primitives and the function-value
   question depend on nothing. When an 01 strictness step kills a fixture, its wasm snapshot goes
   with it — 01 reports rather than deletes.
3. **05 × [`13-module-identity`](../13-module-identity/README.md) — `no` in substance, `yes` on paper.** 13 does not own `wat.zig`, but
   **step 2's box is the mechanism 13's named-type identity needs on this backend.** Do not merely
   sequence them: agree the tag encoding once, in step 2's D1, with 13's owner — the same question
   [`../decisions-pending.md` #5](../decisions-pending.md) asks on the commonJS side. **Recommended order:
   05 runs now**, D1 designed jointly, and F2/F3/F4 land in 13's commit. Sequencing without the
   agreement costs the box being written twice and every boxed value's snapshot re-recorded twice.
4. **05 × [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — `yes`.** No shared file.
5. **05 × [`07-review-backlog`](../07-review-backlog/README.md) — `no`.** It owns `src/codegen/tests/**`; this front's fixtures
   and `KNOWN` / `KNOWN-WRONG` notes are a carve-out, and its codegen report wave runs after step 1.
6. **05 × [`10-cli-residuals`](../10-cli-residuals/README.md) — `yes`.** No shared file. One row worth its attention: the
   language suite cannot run `test/` cells on wasm, which hides four of this front's rows.
7. **05 × [`08-hygiene`](../08-hygiene/README.md) — `no`.** Its sweep over `wat.zig` and `wat/**` — including the stale
   `wasm3` / `wat_runtime` comments 1.0.4 recorded — lands after this front.
8. **05 × [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — `yes`.** No library cell runs on wasm.
9. **05 × [`12-language-tests`](../12-language-tests/README.md) — `yes`**, delete-only on `expected-failures.txt`, and
   the front to ask for wasm cells covering `break <value>` and tuple equality.

**Front-table row**

| [`05-wasm/`](./05-wasm/README.md) | high | Decision 8 at run time on wasm — the §7 formatter (a record prints as a raw heap address today), the box that carries `unknown` and unions, `is`, `case` arms and `loop` — plus a `Dict` lookup that answers the fallback with exit 0 and no diagnostic, `break <value>` returning a one-element array, `==` on tuples comparing references, and two string primitives that trap |

---

## Handed over by `15-language-surface` (2026-09-18, `109f6c9`)

**One lowering: the index expression.** [Decision 30](../decisions-taken.md) landed in the parser as a
builtin call — `ast.index_builtin_name` (`"[]"`) over `(receiver, index)`, contract at
`ast.zig:1681-1703` — so `xs[0]`, `d["k"]`, `s[0]` and the slice `xs[0..2]` (the same node with a
`range` second argument) all arrive as one shape. Until this backend lowers it, the form falls into the
unrecognised-builtin path — the same place `x is T` sat before it was lowered.

**`a ?? b` asks nothing of this backend.** It desugars in the parser into the optional-binding `if`
the language already has (`ast.nullish_binding_name`), which this backend already emits.
