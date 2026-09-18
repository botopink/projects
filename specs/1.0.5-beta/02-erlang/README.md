# Front 02 — erlang

**Priority:** high — erlang is the backend the six libraries' CI cells run on, and it is the only
one whose generator protocol crashes at run time
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies). The §7 formatter depends on nothing
**Owns:** `modules/compiler-core/src/codegen/erlang.zig` ·
`modules/compiler-core/src/codegen/crossModule.zig` ·
`modules/compiler-core/snapshots/codegen/erlang/**` (315 files) · the `KNOWN` notes and new fixtures
of its rows in `modules/compiler-core/src/codegen/tests/**` (a carve-out from [`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `src/codegen/wat.zig`, `src/codegen/wat/**`
([`05-wasm`](../05-wasm/README.md)) · `modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`. Every output below was produced against
`botopink-lang` `c2dd780` on 2026-09-18 with the command shown.

---

## Problem

Decision 8 §7 says one formatter per type, source-shaped, the same text on every backend. Run
`tests/language/run/print_formatter.bp` through `botopink run --target erlang` at `c2dd780`:

| Value | §7 wants | erlang prints |
|---|---|---|
| `5.0` | `5.0` | `5.0` ✓ |
| `[1, 2]` | `[1, 2]` | `[1,2]` |
| `["a", "b"]` | `["a", "b"]` | `["a","b"]` |
| `#(1, "a")` | `#(1, "a")` | `#(1,"a")` |
| `Point(x: 1, y: 2)` | `Point(x: 1, y: 2)` | `#{x => 1,y => 2}` |
| `Shape.Square(side: 4)` | `Shape.Square(side: 4)` | `{'Square',4}` |
| `Shape.Nothing` | `Shape.Nothing` | `'Nothing'` |
| `Money(cents: 5)` with `implement Display` | `$5` | `#{cents => 5}` |

And a generator whose body is a condition loop crashes:

```
#[@generator] fn nums(n: i32) -> @Generator<i32> { var i = 0; loop (i < n) { yield i; i = i + 1; }; }
loop (nums(3)) { x -> acc = acc + x.toString(); };

  escript: exception error: no case clause matching 3
    in function lists:foldl/3 (lists.erl:2464)
```

## Current state

`zig build test-language` at `c2dd780` is **205 passed, 54 expected failures, 0 failed**. Twelve of
the 54 lines name the erlang target. Of those, **seven are this front's**, two need
[`13-module-identity`](../13-module-identity/README.md) and **three are not a codegen defect at all** — see
[Not this front's — reassign](#not-this-fronts--reassign).

Measured over `snapshots/codegen/erlang/` (315 files):

| Measurement | Count |
|---|---|
| snapshots carrying a `----- RUN LOG -----` block | 306 |
| of those, with a non-empty log (the program printed something) | 153 |
| of those, whose text carries an array, a tuple, a float or a record — the §7 formatter's text | **17** |
| snapshots whose emitted erlang carries the `'__bp_print'/1` / `'__bp_show'/2` / `'__bp_text'/1` prelude | **164** |

`zig build test-libs` at `c2dd780` is 11 cells, 0 failed; `scripts/known-red-libs.txt` is empty.

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

### Step 1 — the §7 formatter (decision 8 §7)

One derived formatter per type, replacing the decision-1a printer `a40daf4` landed. What erlang owes:

| # | Row | Acceptance |
|---|---|---|
| F1 | **spaces after the separator** — `[1, 2]`, `["a", "b"]`, `#(1, "a")`, nested strings quoted with source escapes | `run/tuple_print.bp` passes on erlang |
| F2 | **a record prints as `Point(x: 1, y: 2)`**, not as the map that represents it | needs the type's name and field order at the print site — [Dependencies](#dependencies) |
| F3 | **a variant prints as `Shape.Square(side: 4)` / `Shape.Nothing`**, not `{'Square',4}` / `'Nothing'` | the same |
| F4 | **`Display` is consulted, nested too** — `@print([Money(cents: 1), Money(cents: 2)])` prints `[$1, $2]` | `run/display_print.bp` passes on erlang |
| F5 | `f64` always carries its decimal part | already holds on erlang (`5.0`); keep it and delete the "intended divergence" note in `src/codegen/AGENTS.md`, which decision 8 §7 ends |

F1 and F5 are this front's alone. **F2, F3 and F4 need a value to answer which named type it is** —
that is [`13-module-identity`](../13-module-identity/README.md)'s third half. Land F1 first, in its own commit, so the 17 RUN LOGs move
once for a reason a reviewer can check by eye.

### Step 2 — decision 8 at run time: `is`, unions, `unknown`

| # | Row | Acceptance |
|---|---|---|
| D1 | `x is T` by value (§4.1, §4.2): `is_integer` + range for the integer types, `is_float` plus an integral check and a conversion for a float that fits, `is_binary`, `is_boolean`, tuple arity and each element | each form of §4.2 answers §4.1's truth table on erlang |
| D2 | `unknown` and unions at run time (§2, §3): erlang stores nothing extra — a value entering `unknown` is the value | §11's table: "erlang / beam: nothing" |
| D3 | **§2.3** — `==` / `!=` with an `unknown` operand compares numbers by value (`2.0 == 2` is true) while two statically-typed operands keep decision B2's exact equality | a fixture pins both halves |

`x is Person` — a **named** type — is not in this step; see [Dependencies](#dependencies).

### Step 3 — `case` arms at run time (§5)

Type-test arms (`i32 { … }`, `string { … }`), `..` (P7), `when (…)` guards, the dot shorthand and
labelled payloads, lowered to erlang `case` clauses and guards.

**Acceptance:** `test/case_arms.bp`, `test/case_variants.bp`, `test/case_tuples.bp`,
`test/case_guards.bp`, `test/case_exhaustive.bp`, `test/case_unknown.bp`, `run/case_values.bp` and
`test/case_sections.bp` pass on erlang once [`01-checker`](../01-checker/README.md) steps 1–5 land.

### Step 4 — tuple labels (§6 T4)

`row.pop` → `row.1` is resolved by the checker and lowered as an index. N24 (`174e0e4`) landed the
member-access and the fn-typed-element call paths on erlang (`element(2, C)` applied). **Re-verify
and close**: what is left is a labelled tuple that crosses a module boundary, and `format.zig`'s idea
of a labelled tuple, which belongs to the front that owns `src/format.zig`.

**Acceptance:** decision 8 §6's own programs print `5` and `18` on erlang; no emitted erlang carries a
label as an atom key.

### Step 5 — `loop`: a condition loop used as a value

```
var i = 0;
val found = loop (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
   → error: compilation failed
       ConditionLoopValueUnsupported
```

`c51aadd` lowered `loop (condition)` on all four backends; a condition loop whose `break` carries a
value is refused on erlang (and beam) with an **unlocated** `ConditionLoopValueUnsupported`.

**Acceptance:** `test/loop_break_value.bp` passes on erlang — `break <value>` out of a condition loop
is the loop's value — and the error kind is gone. Its `expected-failures.txt` line goes with it.

### Step 6 — the generator protocol

`#[@generator]` and `#[@iterator]` compile on erlang and raise `case_clause` at run time, but only
when the generator body drives itself with a **condition loop**:

| Body | erlang |
|---|---|
| `yield 1; yield 2;` | works — prints `1`, `2` |
| `var i = 0; loop (i < n) { yield i; i = i + 1; };` | `exception error: no case clause matching 3` in `lists:foldl/3` |

So the defect is in how the protocol's driver folds a *condition* loop's yields, not in `yield`
itself. Fix that shape.

**Acceptance:** all four lines of `test/effect_iterator.bp` and `test/effect_generator.bp` pass on
erlang; a generator body written with a collection loop, a condition loop and bare `yield`s each run.

### Step 7 — primitive methods that emit an undefined function

```
@print("aB".toUpperCase());   →  out/main.erl:5:19: function toUpperCase/1 undefined
@print("aB".toLowerCase());   →  out/main.erl:6:19: function toLowerCase/1 undefined
```

The call is emitted as a bare local call and nothing defines it. The other string primitives resolve;
these two do not.

**Acceptance:** `test/string_case_conversion.bp` passes on erlang; an audit of the primitive method
table names every method that emits a call to a function no emitted module defines, and the list is
empty or written into `src/codegen/AGENTS.md` with its reason.

### Step 8 — a method on an associated fn's result (01's R6, codegen half)

```
@print(Array.range(0, 3).map({ x -> x + 1 }));
```

emits, at `c2dd780`:

```erlang
'__bp_print'(['__bp_prim_map'(array:range(0, 3), fun(X) -> …)])
…
'__bp_prim_map'(Recv, Arg0) when is_list(Recv) -> lists:map(Arg0, Recv);
'__bp_prim_map'(Recv, _)    -> erlang:error({bp_unsupported_method, <<"map">>, 1, Recv}).
```

Two defects in one line. The run-time dispatch helper is inference recording no lowering
([`01-checker`](../01-checker/README.md) R6); `array:range/2` is this front's — a std associated fn
emitted as a remote call into an `array` module no program declares, which is `undef` at run time.

**Acceptance:** with 01's R6 landed, no emitted erlang carries `'__bp_prim_map'` for this program;
`Array.range(0, 3)` resolves to something defined, and the program prints `[2, 3, 4]` under §7.

### Step 9 — the block-as-value lowerings decision 2 leaves dead

Once [`01-checker`](../01-checker/README.md) step 8's R7 enforces decision 2 — a block is a
statement, its value comes from `break` — erlang's tail-`case` block-as-value lowering has no
producer. Delete it.

**Acceptance:** the lowering is gone; `snapshots/codegen/erlang/` is otherwise byte-identical (a diff
outside the deleted shape is a bug found); `src/codegen/AGENTS.md` records the deletion. The three
twins are each their own front's: beam's `make_fun3` (12 sites), commonJS's IIFE (27 `(() =>` sites),
wasm's `;; lambda`.

## Dependencies

This front shares **no source file and no snapshot directory** with
[`01-checker`](../01-checker/README.md) or with the other three backends. What it shares with 01 is
the typed AST, so it depends on the **step** that feeds each row, never on the whole front:

| This front's step | Needs from 01 |
|---|---|
| 1 (§7 formatter) F1, F5 | nothing — it is emitter text |
| 2 (`is`, unions, `unknown`) | steps 1–3 |
| 3 (`case` arms) | steps 4–5 |
| 4 (tuple labels) | nothing — N24 landed |
| 5 (`loop` value break) | nothing |
| 6 (generator protocol) | nothing |
| 7 (primitive methods) | nothing |
| 8 (associated-fn result) | step 8's R6 |
| 9 (dead lowerings) | step 8's R7 |

**The named-type half of decision 8 is not this front's.** `is Person`, a union of named types, a
`case` over them and §7's F2/F3/F4 all need a **value to answer which named type it is** at run time.
That is the third half of [`13-module-identity`](../13-module-identity/README.md). The cut agreed with the maintainer: the backends take
primitives, tuples, the wasm box and `loop`; [`13-module-identity`](../13-module-identity/README.md) takes named-type identity. The
consequence for acceptance is concrete and must not be glossed over — of the twelve erlang lines in
`expected-failures.txt`, this front can delete **seven**; `run/print_formatter.bp` and
`run/display_print.bp` print a record and two variants and stay listed until [`13-module-identity`](../13-module-identity/README.md)
lands; three are not this front's at all.

### Ordering against [`13-module-identity`](../13-module-identity/README.md)

[`13-module-identity`](../13-module-identity/README.md) owns `codegen/erlang.zig` **whole** in its second and third halves (policy 3,
and identity inside the value), and re-records 188 + 130 snapshots in the two directories this front
and [`03-beam`](../03-beam/README.md) own. The two cannot run at the same time.

[`../decisions-pending.md` #4](../decisions-pending.md) already asks this question for the milestone
and recommends **(a) 14 → 13 → the backends**, noting that it costs 02 and 03 standing still for the
whole of 13. This front's measurement adds a third option and recommends it:

| Order | Cost, measured |
|---|---|
| **(a) 13 → 02** (`decisions-pending.md`'s recommendation) | every §7 snapshot is recorded once, in its final module layout, and F2/F3/F4 land with F1 as one formatter. **02 stands still for the whole of 13.** Six of this front's seven lines need nothing from 13, so six `expected-failures.txt` lines — including the generator crash, the only run-time crash in the milestone, and the two erlang cells the six libraries' CI runs against — stay red for that time |
| (b) 02 → 13 | 02 re-records 17 RUN LOGs (F1/F5) and up to 164 prelude-carrying snapshots; 13 then re-records 188 + 130 in the same directory. That second pass is a **superset** of the first — the 17 and the 164 are inside the 188 + 130 — so it is not extra work for 13, it is the same files touched twice. Under the agreed cut 02 never writes the record/variant arms, so there is no *rework*, only a re-record. But two reasons pass over the same snapshots, which is exactly what the "one reason per re-record" rule exists to prevent |
| **(c) a pre-pass, then 13, then the tail** — **recommended** | 02 lands steps 5, 6 and 7 first (a condition loop's value break, the generator protocol, the two undefined string primitives). None of them touches the print prelude, the module atom or a record's representation, so **none of them re-records a file 13 will re-record**: they move the fixtures they lower and nothing else. Six lines close in that pass. 13 then runs whole on `erlang.zig`, and §7 (F1–F5 together) plus steps 2, 3, 8 and 9 land after it, recording each snapshot once |

(c) is (a) with the rows that are provably disjoint from 13 pulled forward. It needs one thing
verified before it starts, and the verification is cheap: **measure that steps 5, 6 and 7 move no
snapshot carrying a `%% type` / `%% behavior` / `%% implement` marker** — the set
[`13-module-identity`](../13-module-identity/README.md)'s policy 3 re-records — and abandon the
pre-pass for any row that does.

Under every option, **F2/F3/F4 land with [`13-module-identity`](../13-module-identity/README.md), in
one commit with the rest of §7**, so no RUN LOG carries two reasons.

## Not this front's — reassign

Three of the twelve erlang lines in `expected-failures.txt` are attributed to "01 step 6" (the
1.0.4 backend front) and are **not a codegen defect**. The emitted erlang is correct:

| Cell | `botopink run --target erlang` | `erlc *.erl` then `erl -pa . -eval "main:main()"` |
|---|---|---|
| `modules/two_modules` | `undefined function geometry:norm/1` | prints `3`, `0` — correct |
| `modules/mod_tree` | `undefined function shapes:describe/0` | prints `circle`, `7` — correct |
| `modules/std_import` | `undefined function dict:empty/0` | prints `1` — correct |

`modules/compiler-cli/src/cli/run.zig` runs `escript out/main.erl`. `escript` compiles that one file;
every sibling module the build emitted beside it (`out/geometry.erl`, `out/shapes/circle.erl`,
`out/std/dict.erl`) is never loaded. The same shape makes an imported host-backed `declare fn` look
broken — `pub mod host; import { up } from "host";` dies under `run` and prints `AB` when the two
modules are compiled and put on the code path — which is why `063e16b`'s fix reads as not having
landed when it has.

**The fix is in the CLI**, in [`10-cli-residuals`](../10-cli-residuals/README.md): compile the emitted
modules (`erlc`) into the output directory and run them with `erl -pa`, or give `escript` the code
path. It interacts with [`13-module-identity`](../13-module-identity/README.md), which decides the module atom and the output layout
those paths are built from. This front does not touch it; the three lines are re-attributed with this
evidence.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program**, and checked against decision 8 §7 — never bulk-accepted
- [ ] `zig build test-libs` green: the six libraries' erlang cells still pass, with no `known-red-libs.txt` line added
- [ ] `src/codegen/AGENTS.md` and `src/codegen/erlang.zig`'s own notes updated in the same commit as each row
- [ ] Commit on `fix/erlang`; no push, no merge

## Blast radius

| What | Count | How measured |
|---|---|---|
| `snapshots/codegen/erlang/` | **315** | `find … -name '*.snap.md' \| wc -l` |
| with a `RUN LOG` block | 306 | parsed out of each file |
| with a **non-empty** log | 153 | the same |
| whose log text changes under §7 F1 (array, tuple, float or record text) | **17** | the same, matched for `[…]`, `#(`, `\d+\.\d+`, `{…}` |
| whose **emitted erlang** changes when the print prelude changes | **164** | `grep -rl "__bp_print\|__bp_text"` |
| step 9 (dead lowerings) | 0 expected — a refactor landing, byte-identical apart from the removed shape | |

Steps 2, 3 and 8 move whatever fixture they newly lower; measure per row before starting, and record
each re-recorded RUN LOG against the value you ran.

**This front does not move any other directory.** If a change here moves a `snapshots/comptime/**`
file, something crossed into [`01-checker`](../01-checker/README.md)'s territory — stop and report.

## Notes

- **Erlang is not the oracle.** Where two backends disagree, the assertion is what the program means
  under decision 8, not what erlang prints. Decision 8 §7 ends the one divergence that was
  deliberate (`5.0` vs `5`) by making `5.0` the answer everywhere — erlang keeps its text and
  commonJS and wasm change.
- **`crossModule.zig` is shared with [`13-module-identity`](../13-module-identity/README.md) by subject, not by row.** This front reads
  it for step 8; every module-atom and layout decision in it is 13's.

## Rows for `fronts.md`

**Ownership row**

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **02** [`erlang`](./02-erlang/README.md) | `modules/compiler-core/src/codegen/erlang.zig` · `modules/compiler-core/src/codegen/crossModule.zig` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/erlang/**` (315) | steps 1–9; 7 of the 54 `expected-failures.txt` lines |

**Conflict notes**

1. **02 × 03 × 04 × 05 — `yes`.** The four backend fronts are file-disjoint and
   snapshot-disjoint from each other. That is the point of the cut.
2. **02 × 01 — `yes`.** No shared file, no shared directory. Each of 02's rows depends on the
   **01 step** that feeds it (the table in [Dependencies](#dependencies)); the §7 formatter's F1 and
   F5 depend on nothing. The one caveat: when an 01 strictness step makes a fixture stop compiling,
   that fixture's erlang snapshot goes with it — 01 reports it here rather than deleting it.
3. **02 × [`13-module-identity`](../13-module-identity/README.md) — `no`.** 13 owns `codegen/erlang.zig` and `crossModule.zig` whole in
   its second and third halves and re-records 188 + 130 snapshots in this directory.
   **Recommended order: a pre-pass, then 13, then the tail** — 02's steps 5, 6 and 7 first (they
   re-record no file 13 re-records), 13 whole, then §7 and the rest; the three options and their
   measured costs are in
   [Ordering against `13-module-identity`](#ordering-against-13-module-identity), and the milestone
   question is [`../decisions-pending.md` #4](../decisions-pending.md). §7's F2/F3/F4 land with 13
   either way.
4. **02 × [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — `yes`** as written today; if 14 needs the erlang emitter to render
   a comptime module, it takes a carve-out named in its own README.
5. **02 × [`07-review-backlog`](../07-review-backlog/README.md) — `no`.** It owns `src/codegen/tests/**`, which this front adds
   fixtures and `KNOWN` notes to; that is a carve-out, named in each landing note, and its codegen
   report wave runs after this front's step 1.
6. **02 × [`10-cli-residuals`](../10-cli-residuals/README.md) — `yes`**, and it **gains three rows** from this front: the
   `modules/two_modules`, `modules/mod_tree` and `modules/std_import` erlang lines are
   `modules/compiler-cli/src/cli/run.zig`'s, with the evidence in
   [Not this front's](#not-this-fronts--reassign).
7. **02 × [`08-hygiene`](../08-hygiene/README.md) — `no`.** Its comment sweep over `codegen/erlang.zig` lands after this
   front.
8. **02 × [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — `seq`.** The libraries' erlang cells execute what this front emits.
9. **02 × [`12-language-tests`](../12-language-tests/README.md) — `yes`**, delete-only on
   `tests/language/expected-failures.txt`.

**Front-table row**

| [`02-erlang/`](./02-erlang/README.md) | high | Decision 8 at run time on erlang — the §7 formatter, `is`, unions, `case` arms, tuple labels and a condition loop's value break — plus the generator protocol's `case_clause`, two undefined string primitives, and the block-as-value lowering decision 2 leaves dead |
