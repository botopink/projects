# Front 04 — js

**Priority:** high — commonJS is the default target, the one every `botopink new` project runs, and
the one that emits a `.d.ts` contradicting its own JavaScript
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies). The §7 formatter, the sibling `require` and the `.d.ts` rows depend on
nothing
**Owns:** `modules/compiler-core/src/codegen/commonJS.zig` ·
`modules/compiler-core/src/codegen/typescript.zig` · `modules/compiler-core/src/codegen/js/**` ·
`modules/compiler-core/snapshots/codegen/commonJS/**` (315 files, each carrying the TypeScript
typedef of the same program) · the `KNOWN` notes and new fixtures of its rows in
`modules/compiler-core/src/codegen/tests/**` (a carve-out from [`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/wat.zig`, `src/codegen/wat/**` ([`05-wasm`](../05-wasm/README.md)) ·
`modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`. Every output below was produced against
`botopink-lang` `c2dd780` on 2026-09-18 with the command shown (node v25.8.0).

---

## Problem

**The formatter prints the host's shape, not the program's.**
`botopink run --target commonJS` over `tests/language/run/print_formatter.bp`:

| Value | §7 wants | commonJS prints |
|---|---|---|
| `5.0` | `5.0` | `5` |
| `[1, 2]` | `[1, 2]` | `[1,2]` |
| `#(1, "a")` | `#(1, "a")` | `#(1,"a")` |
| `Point(x: 1, y: 2)` | `Point(x: 1, y: 2)` | `Point { x: 1, y: 2 }` |
| `Shape.Square(side: 4)` | `Shape.Square(side: 4)` | `{ tag: 'Square', side: 4 }` |
| `Shape.Nothing` | `Shape.Nothing` | `Nothing` |
| `Money(cents: 5)` with `implement Display` | `$5` | `Money { cents: 5 }` |

**A `break` with a value yields a one-element array.**

```
var k = 0;
val r = loop { k = k + 1; if (k > 2) { break k; }; };   →  [3]      (§10 wants 3)
val found = loop (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };  →  [8]
```

**`==` on tuples compares references.** `val a = #(1, "a"); val b = #(1, "a"); a == b` → `false`
(erlang prints `true`). A tuple is a JS array and `==` is `===`.

**A sibling-module import with no `from` emits a path that does not exist.**

```
src/leaf.bp: pub type Leaf(v: i32)
src/main.bp: pub mod leaf;  import { Leaf };  @print(Leaf(v: 7).v);

  build: Compiled in 67ms   (exit 0)
  node:  Error: Cannot find module './module'
  out/main.js:20: const { Leaf } = require("./module");
```

The literal word `module` is written as the path. Inside a **dependency** the same defect reads
`require("../module")` and is what made `examples/jhonstart-counter` and `-todo` build and then die;
`repository/jhonstart` carries a written rule telling authors to always name the module as a
workaround.

**The emitted `.d.ts` contradicts the emitted `.js`.**

```
src/main.bp: pub type Shape { Square(side: i32), Nothing }

out/main.d.ts: export declare type Shape = { tag: "Square", side: i32 } | { tag: "Nothing" };
out/main.js:   const Shape = Object.freeze({ Square: (side) => ({ tag: "Square", side }),
                                             Nothing: "Nothing" });
```

Two defects in three lines: a unit variant is a bare string where the typedef promises a tagged
object, and `i32` — a botopink primitive, not a TypeScript type — is written into the `.d.ts`.

## Current state

`zig build test-language` at `c2dd780` is **205 passed, 54 expected failures, 0 failed**. **Seven**
of the 54 lines are this front's:

| Line | Row |
|---|---|
| `commonJS \| test/tuple_equality.bp::§6 T6 two tuples with the same elements are equal` | step 4 |
| `commonJS \| test/tuple_equality.bp::§6 T1 T6 a labeled and an unlabeled tuple …` | step 4 |
| `commonJS \| run/tuple_print.bp` | step 1 (F1) |
| `commonJS \| run/print_formatter.bp` | step 1 — **F2/F3 need [`13-module-identity`](../13-module-identity/README.md)** |
| `commonJS \| run/display_print.bp` | step 1 — **F4 needs [`13-module-identity`](../13-module-identity/README.md)** |
| `commonJS \| test/loop_break_value.bp::§10 break with a value is the loop's value` | step 3 |
| `commonJS \| test/loop_break_value.bp::§10 break with a value out of a condition loop` | step 3 |

The last two are attributed to `06 N12` in the file. They are a commonJS **lowering** — the checker
types `break k` correctly and `[3]` is what the emitter writes — so they are re-attributed here. The
same defect reproduces on wasm ([`05-wasm`](../05-wasm/README.md) step 4), where no line exists
because `botopink test` does not run wasm.

Measured over `snapshots/codegen/commonJS/` (315 files):

| Measurement | Count |
|---|---|
| snapshots carrying a `----- RUN LOG -----` block | 306 |
| of those, with a non-empty log | 153 |
| of those, whose text changes under §7 (array, tuple, float or record text) | **14** |
| snapshots whose emitted JS carries the `__bp_show` / `__bp_print_as` prelude | **163** |
| snapshots carrying a `----- TYPESCRIPT TYPEDEF --` section | 306 |
| of those, with a **non-empty** typedef | **25** |
| of those, writing a botopink primitive name (`i32`, `f64`, `bool`, `string`) into the `.d.ts` | **24** |
| of those, writing a tagged union | **2** |

There is **no `snapshots/codegen/typescript/` directory**: the TypeScript output is a section inside
each commonJS snapshot, so `typescript.zig` and `commonJS.zig` cannot be split across fronts even if
the ownership table names them separately. That is why they are one front.

## Handed over by `01-checker` — three defects its step 4 exposes

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

| # | Row | Acceptance |
|---|---|---|
| F1 | spaces after the separator — `[1, 2]`, `["a", "b"]`, `#(1, "a")`, nested strings quoted with source escapes | `run/tuple_print.bp` passes |
| F2 | a record prints `Point(x: 1, y: 2)`, not `Point { x: 1, y: 2 }` | needs named-type identity — [Dependencies](#dependencies) |
| F3 | a variant prints `Shape.Square(side: 4)` / `Shape.Nothing`, not `{ tag: 'Square', side: 4 }` / `Nothing` | the same |
| F4 | `Display` is consulted, nested too: `[$1, $2]` | `run/display_print.bp` passes |
| F5 | **`f64` always carries its decimal part** — `@print(5.0)` prints `5.0`, not `5` | decision 8 §7 ends decision 1's accepted numeric divergence; this is the half commonJS owes |

F1 and F5 are this front's alone; F2, F3 and F4 land with [`13-module-identity`](../13-module-identity/README.md). Land F1 and F5 in
one commit so the 14 RUN LOGs move once.

F5 is not cosmetic: it needs the emitter to know the value is an `f64` at the print site, because JS
has one number type. The type is on the typed AST (`@print`'s argument already carries a shape
descriptor — `__bp_print_as([["[", ["#", …]]], …)`), so extend that descriptor rather than sniffing
the value at run time.

### Step 2 — decision 8 at run time: `is`, unions, `unknown`, `case` arms, labels

| # | Row |
|---|---|
| D1 | `x is T` by value (§4.1, §4.2): `typeof` + `Number.isInteger` + range for the integer types, any number for `f64`, `typeof` for `string`/`bool`, `Array.isArray` + arity + each element for a tuple |
| D2 | `unknown` and unions at run time: commonJS stores nothing extra (§11) |
| D3 | §2.3 — `==` with an `unknown` operand compares numbers by value |
| D4 | `case` arms (§5): type tests, `..`, `when (…)` guards, the dot shorthand, labelled payloads |
| D5 | tuple labels → positional (§6 T4). N24 (`174e0e4`) landed the read path and the fn-typed element (`c[1](9)`); re-verify and close |

`x is Person` — a **named** type — is not in this step.

### Step 3 — `break <value>`

`break k` out of a `loop { … }` and out of a `loop (condition)` both yield `[3]` / `[8]`: the loop
lowering accumulates into an array and the `break` value is appended instead of returned.

**Acceptance:** both `test/loop_break_value.bp` tests pass; a `loop` used as a value with no `break`
still answers what it answered before (measure first); the two `expected-failures.txt` lines go.

### Step 4 — `==` on tuples

A tuple is a JS array, and `==` lowers to `===`, so two structurally equal tuples are unequal. §6 T6:
run time is positional and equality compares elements; T5: labels take no part.

**Acceptance:** all three `test/tuple_equality.bp` tests pass — including the negative one, which
passes today for the wrong reason (`#(1,"a") !== #(1,"b")` is true by reference as well). The
comparison must be structural and must not make two *different* tuples equal.

### Step 5 — the sibling-module `require`

A `mod` sibling imported without a `from` clause emits `require("./module")` inside a project and
`require("../module")` inside a dependency. Both are literal — the importing statement has no module
name and the emitter writes the word.

**Acceptance:**
- [x] the repro in [Problem](#problem) runs under node and prints `7` — `require("./leaf.js")`,
      re-measured 2026-09-26 on `b6ba65a3` (the defect was fixed before this front re-opened)
- [x] the same shape inside a dependency (a `libs/<name>` project with a `files` manifest) runs —
      `require("../tree/leaf.js")` from `tree/api.js`, prints `7`
- [x] a fixture in `src/codegen/tests/**` pins both (`features.zig` `a sibling module imported with no
      from requires its own path`, needles for both shapes), with the RUN LOG in
      `tests/language/modules/sibling_import_in_a_dependency` — green on all four targets
- [ ] the workaround rule in `repository/jhonstart/AGENTS.md` can be deleted — the deletion itself is [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s

### Step 6 — the `.d.ts` and the JavaScript agree

| # | Row | Acceptance |
|---|---|---|
| T1 (= [`../decisions-pending.md` #5](../../../1.0.5-beta/decisions-pending.md)) | a **unit variant** is emitted as the tagged object the `.d.ts` declares — `Nothing: { tag: "Nothing" }` — or the `.d.ts` declares the string. Pick one and make both ends say it; the tagged object is the shape §7's F3 and step 2's D4 both read | `pub type Shape { Square(side: i32), Nothing }` emits a `.js` and a `.d.ts` that agree, and `node --check` passes |
| T2 | **botopink primitive names stop leaking into the `.d.ts`** — `i32` → `number`, `f64` → `number`, `string` → `string`, `bool` → `boolean`, `?T` → `T \| null`, `#(A, B)` → `[A, B]` | **24** of the 25 non-empty typedefs carry one today; after the row, 0 do, and `tsc --noEmit` accepts every emitted `.d.ts` |
| T3 | decision 8's new types reach the `.d.ts`: `unknown` → `unknown`, `A \| B` → `A \| B` | a fixture per form |

T2 is the row that makes the `.d.ts` worth emitting at all: a declaration file naming `i32` is not
TypeScript. Measure `tsc --noEmit` over the 25 non-empty typedefs before and after.

### Step 7 — JS-4: a botopink pattern as a JS binding target

Carried whole in [`pattern-binding.md`](./pattern-binding.md). Once
[`01-checker`](../01-checker/README.md) step 8's R5 makes `val Circle(r) = s` bind, a `ctor`
destructuring lowers to a real JS test-plus-destructure and `Pattern.match` goes.

**Acceptance:** 0 `Pattern.match` build sites; `MatchPattern` and `writeMatchPattern` deleted; the
row leaves the bridge table in `src/codegen/js/AGENTS.md`; commonJS snapshots otherwise
byte-identical — a diff is a bug found.

### Step 8 — the block-as-value IIFE lowerings

`grep -c '(() =>' modules/compiler-core/src/codegen/commonJS.zig` → **27** sites. Once
[`01-checker`](../01-checker/README.md) step 8's R7 enforces decision 2, the ones that exist to give
a block a value have no producer.

**Acceptance:** the dead sites are gone; `snapshots/codegen/commonJS/` is otherwise byte-identical;
`src/codegen/js/AGENTS.md` records which of the 27 were block-as-value and which are genuine
(a lambda, a `return case`, an optional chain).

## Dependencies

| This front's step | Needs from [`01-checker`](../01-checker/README.md) |
|---|---|
| 1 (formatter) F1, F5 | nothing |
| 2 D1–D3 (`is`, unions, `unknown`) | steps 1–3 |
| 2 D4 (`case` arms) | steps 4–5 |
| 2 D5 (labels) | nothing — N24 landed |
| 3 (`break <value>`) | nothing |
| 4 (`==` on tuples) | nothing |
| 5 (sibling `require`) | nothing |
| 6 (`.d.ts`) | step 1 and step 2 for T3 only |
| 7 (JS-4) | step 8's R5 |
| 8 (dead IIFEs) | step 8's R7 |

**The named-type half of decision 8 is not this front's.** `is Person`, a union of named types, a
`case` over them and §7's F2/F3/F4 all need a value to answer which named type it is at run time —
the third half of [`13-module-identity`](../13-module-identity/README.md). The agreed cut: the backends take primitives, tuples, the
wasm box and `loop`; 13 takes named-type identity. Consequence for acceptance: of this front's seven
`expected-failures.txt` lines, **five** close here (`run/tuple_print.bp`, both `tuple_equality`
tests, both `loop_break_value` tests) and **two** — `run/print_formatter.bp` and
`run/display_print.bp` — stay listed until [`13-module-identity`](../13-module-identity/README.md) lands, because each prints a record
and two variants.

There is a second, quieter dependency in the same direction: step 6's T1 decides the **run-time
shape** of a unit variant, and [`13-module-identity`](../13-module-identity/README.md) decides how a value answers its own type. If 13
adds a tag to every named value, T1's answer must be 13's. **Decide T1 with 13, not before it.**

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program** under node, and checked against decision 8 §7
- [x] every emitted module still passes `node --check`; every non-empty `.d.ts` passes `tsc --noEmit` after step 6 — measured 2026-09-26 on `front/04-05-js-wasm`: 356 / 356 emitted modules of `snapshots/codegen/beam/commonJS/` pass `node --check`, 33 / 33 typedef projects pass `tsc` ([below](#the-dts-under-tsc))
- [ ] `zig build test-libs` green — the six libraries' commonJS cells still pass
- [ ] `src/codegen/AGENTS.md` and `src/codegen/js/AGENTS.md` updated in the same commit as each row
- [ ] Commit on `fix/js`; no push, no merge

## Blast radius

| What | Count | How measured |
|---|---|---|
| `snapshots/codegen/commonJS/` | **315** | `find … -name '*.snap.md' \| wc -l` |
| with a `RUN LOG` block | 306 | parsed out of each file |
| with a **non-empty** log | 153 | the same |
| whose log text changes under §7 F1/F5 | **14** | matched for `[…]`, `#(`, `\d+\.\d+` |
| whose emitted JS changes when the print prelude changes | **163** | `grep -rl "__bp_show\|__bp_print_as"` |
| with a non-empty TypeScript typedef (step 6) | **25**, of which **24** carry a botopink primitive name and **2** a tagged union | parsed out of the `TYPESCRIPT TYPEDEF` section |
| `(() =>` sites (step 8) | **27** | `grep -c '(() =>' src/codegen/commonJS.zig` |

Step 7 is a **shape-only** bridge: commonJS snapshots must come out byte-identical apart from the
removed pattern spellings. Steps 2, 3, 4 and 5 move whatever fixture they newly lower — measure per
row.

**This front does not move any other directory.** If a change here moves
`snapshots/codegen/{erlang,beam,wasm}/`, something crossed a boundary — stop and report.

## Notes

- **`typescript.zig` cannot be separated from `commonJS.zig`** for snapshot purposes: the typedef is
  a section of the commonJS snapshot, not a directory of its own. One front, one worktree.
- **Step 3's `[3]` and step 4's `false` both reproduce on wasm**, where the language suite cannot see
  them — [`05-wasm`](../05-wasm/README.md) steps 4 and 5 carry the twins. Coordinate the *meaning*
  (what `break <value>` and `==` answer), not the code.

## Rows for `fronts.md`

**Ownership row**

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **04** [`js`](./README.md) | `modules/compiler-core/src/codegen/commonJS.zig` · `modules/compiler-core/src/codegen/typescript.zig` · `modules/compiler-core/src/codegen/js/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/commonJS/**` (315, each carrying the TypeScript typedef; there is no separate `typescript/` directory) | steps 1–8; 7 of the 54 `expected-failures.txt` lines |

**Conflict notes**

1. **04 × 02 × 03 × 05 — `yes`.** File-disjoint and snapshot-disjoint. Two rows have twins on wasm
   (`break <value>`, `==` on tuples): the *answer* is shared, the code is not.
2. **04 × 01 — `yes`.** No shared file. Per-row dependency in [Dependencies](#dependencies); the
   formatter's F1/F5, the sibling `require` and the `.d.ts` rows depend on nothing. When an 01
   strictness step kills a fixture, its commonJS snapshot goes with it — 01 reports rather than
   deletes.
3. **04 × [`13-module-identity`](../13-module-identity/README.md) — `no` in effect, `yes` on paper.** 13 does not own
   `commonJS.zig`, but §7's F2/F3/F4 and step 6's T1 both wait on 13's answer for how a value
   carries its type. **Recommended order: 04 runs now** (five of its seven lines need nothing from
   13) and its named-type rows land with 13, in 13's commit, so no RUN LOG carries two reasons.
4. **04 × [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — `yes`.** No shared file.
5. **04 × [`07-review-backlog`](../07-review-backlog/README.md) — `no`.** It owns `src/codegen/tests/**`; this front's fixtures
   and `KNOWN` notes are a carve-out, and its codegen report wave runs after step 1.
6. **04 × [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) — `yes`.** No shared file; step 5 fixes the emitted `require`,
   not how the CLI ships a dependency.
7. **04 × [`08-hygiene`](../08-hygiene/README.md) — `no`.** Its comment sweep over `commonJS.zig` and `js/**` lands after
   this front.
8. **04 × [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — `seq`.** Step 5 removes the workaround `repository/jhonstart`
   documents; [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) deletes the rule and the padded call sites.
9. **04 × [`12-language-tests`](../12-language-tests/README.md) — `yes`**, delete-only on `expected-failures.txt`.

**Front-table row**

| [`04-js/`](./README.md) | high | Decision 8 at run time on commonJS — the §7 formatter (`f64` as `5.0`, source-shaped records and variants), `is`, unions, `case` arms and tuple labels — plus `break <value>` returning a one-element array, `==` on tuples comparing references, the sibling-module `require("./module")`, a `.d.ts` that contradicts its own JavaScript, and JS-4's pattern binding |

---

## Handed over by `15-language-surface` (2026-09-18, `109f6c9`)

**One lowering: the index expression.** [Decision 30](../../../1.0.5-beta/decisions-taken.md) landed in the parser as a
builtin call — `ast.index_builtin_name` (`"[]"`) over `(receiver, index)`, contract at
`ast.zig:1681-1703` — so `xs[0]`, `d["k"]`, `s[0]` and the slice `xs[0..2]` (the same node with a
`range` second argument) all arrive as one shape. Until this backend lowers it, the form falls into the
unrecognised-builtin path — the same place `x is T` sat before it was lowered.

**`a ?? b` asks nothing of this backend.** It desugars in the parser into the optional-binding `if`
the language already has (`ast.nullish_binding_name`), which this backend already emits.

---

## Handed over by `12-language-tests` (2026-09-18) — two defects no step of this front names

1. **The optional-binding `if` and `?.` disagree about what absent means.** The lowering emits
   `if (n !== null)` while `?.` answers `undefined`, so `o.inner?.v ?? 9` answers **`undefined` on
   commonJS** and `9` on erlang and wasm. `test/optional.bp` never caught it because its optionals are
   explicit `null`s. This matters more now that `??` exists (decision 28): every `??` after a `?.`
   chain is wrong on this backend.
2. **`42.toString()` emits `__bp_print(42.toString())`**, which node refuses — `42.` lexes as a float —
   while erlang and wasm print `42`. The form landed today with front 15's `46f8c5d`.

The suite records the index expression's owner cells as `04 handover 15`, because decision 30 says
"one lowering in each of fronts 02–05" and this front has no numbered step for it — only the handover
section above. Worth giving it a number when the step is planned.

---

## Landed — 2026-09-18, merged into `feat` as `1379659`

Six commits on `fix/js`, cold gate green, 4 of 315 snapshots re-recorded and each one classified.

| commit | row |
|---|---|
| `f1757f4` | the three defects [`01-checker`](../01-checker/README.md) handed over |
| `17e2059` | [decision 30](../../../1.0.5-beta/decisions-taken.md#30-is-there-an-index-expression)'s index expression |
| `6196b86` | step 2 **D4** — decision 8 §5's arm shapes |
| `37efbd4` | step 6 **T3** — a union in the `.d.ts` |
| `1b86bc3` | step 8 — the IIFE sites classified (docs only) |
| `b5d63ac` | the optional-binding guard was loose — front 12's finding, owned by no step |

**The three defects, measured on `case s { Shape.Circle(r) { @print(r); } _ { v -> @print(v); } }`:**

```js
// before
if (_s.tag === "Shape.Circle") { const { r } = _s; __bp_print(r); }   // never matches; ctor wrote "Circle"
{ __bp_print(v); }                                                     // ReferenceError: v
// after
if (_s.tag === "Circle") { const { radius: r } = _s; return __bp_print(r); }
{ const v = _s; return __bp_print(v); }
```

Defect 2's fix also stopped **arm fall-through**: an un-returned arm ran the arms below it.
`bareVariantName` / `isVariantPath` did **not** exist in `infer.zig` at `bef762b`, contrary to the
handover's text; local helpers were written instead.

**The snapshots.** One is a behaviour change worth naming: `case_nested_case_in_block_arm` — an arm
`0 -> { case 1 {…}; }` dropped its nested `case` and `result` was `undefined`; it is now `54`. The
other three are the operator-only `!==` → `!=` of `b5d63ac`, with no RUN LOG movement, because their
optionals are explicit `null`s. D4's five shapes and the index expression moved **zero** snapshots.

**`expected-failures.txt`:** the two commonJS lines this front made pass were deleted with the merge —
`run/index_expression.bp` (prints `10 / 30 / 2 / 3`, byte-equal to its `.out`) and
`test/nullish_default.bp::?? chains after ?.` (`o.inner?.v ?? 9` now answers `9`). Suite: **252 passed
/ 59 expected / 0 failed**.

**Three of this README's premises did not reproduce**, and the corrections are the measurement:

- step 6's *"24 of 25 typedefs carry a botopink primitive name"* is now **0 of 25** — `d20ac68` closed
  T1/T2 before this front opened;
- step 8's **27** IIFE sites are **11** text hits and **10** build sites, of which exactly **one**
  (`@block { body }`) is a block-as-value. Recorded in `js/AGENTS.md`;
- the handover's `bareVariantName` / `isVariantPath` did not exist.

**Left undone:** step 1 F2/F3/F4 (land with [`13-module-identity`](../13-module-identity/README.md);
the commonJS half already passes) · step 7 / JS-4 — `val Circle(r) = s` still reds `unbound variable
'r'`, waiting on 01 step 8 R5, so the 8 `Pattern.match` build sites stay · step 8's removal, which
needs R7 · `d["k"]` on a `Dict`, which is [question 46](../../../1.0.5-beta/decisions-pending.md) · `tsc --noEmit`,
which the gate line asks for and which **could not be run** — there is no `tsc` in the checkout or on
`PATH`, so it is unverified rather than claimed.

**Three questions opened:** [45](../../../1.0.5-beta/decisions-pending.md) (a member access on a `?T`, which also moves
front 12's `§6 T4` owner row to 01), [46](../../../1.0.5-beta/decisions-pending.md) (`d["k"]`) and
[47](../../../1.0.5-beta/decisions-pending.md) (`undefined` vs `null` for an out-of-range read).


## Handed over by `01-std/01-std-lib-enablement` (2026-09-25)

1. **`import {process} from "std"` shadows Node's global `process` in the generated test runner.** A
   consumer test module importing it binds a local `process`, and the runner's own
   `const filter = process.argv[2] || null;` throws `TypeError: Cannot read properties of undefined
   (reading '2')` before any test runs. An imported module named after a host global needs a
   renamed binding (or the runner must reach the global through `globalThis.process`).
2. **`try` inside a `while` body does not propagate** (shared with `02-erlang`, repro there): the loop
   keeps running after the `Error`, and the function answers `Ok`.

---

## Re-verified and continued — 2026-09-26, `front/04-05-js-wasm`

Every row re-measured against `feat` (`b6ba65a3`) before anything was written; a row ticked here
is ticked with the program that answered it.

| Row | State | Evidence |
|---|---|---|
| Step 1 F1, F5 | **holds** | `@print(5.0)` → `5.0`, `[1, 2]`, `#(1, "a")`; `run/tuple_print.bp` green, its line gone |
| Step 1 F2, F3, F4 | **holds** (landed with C-01 half 3) | `run/print_formatter.bp`, `run/display_print.bp` green on commonJS, no line |
| Step 2 D1–D3 | **holds** | `show(x: unknown)` answers `i32` / `string` / `other` for `1`, `"s"`, `2.5`; `300 is i8` → `false`; `#(1, "a") is #(i32, string)` → `true`; `val u: unknown = 2.0; u == 2` → `true` |
| Step 2 D4 | **holds** (`6196b86`) | |
| Step 2 D5 | **open — not this backend's** | `test/tuple_labels.bp::§6 T4 a label survives a generic array method`: the label `rs.at(0).b` reaches the backend unresolved (the checker resolves a label to `_N` only at the written type), and decision 45 says a member access on the `?T` `at` answers is a check error — both halves are `01-checker`'s (C-18) |
| Step 3 `break <value>` | **superseded** by decision 105 (`break v` only in a generator scope, C-30); `test/loop_break_value.bp`'s lines are gone | |
| Step 4 `==` on tuples | **holds** | `#(1, "a") == #(1, "a")` → `true`, `… == #(1, "b")` → `false` (`__bp_eq`); `test/tuple_equality.bp` green |
| Step 5 sibling `require` | **holds**, now pinned | boxes above |
| Step 6 T1–T3 | **hold**; the `tsc` gate was **red** (14 of 33) and is green here | see [the `.d.ts` under `tsc`](#the-dts-under-tsc) |
| Step 7 JS-4 | **landed here** | [`pattern-binding.md`](./pattern-binding.md) acceptance |
| Step 8 | **waits on R7** | `@block { 1 + 2 }` still type-checks and lowers to `(() => {(1 + 2);})()` — `undefined`, exit 0 |
| 12's handovers | **hold** | `o.inner?.v ?? 9` → `9`; `42.toString()` → `(42).toString()` prints `42` |
| 01-std handover 1 (`process` shadow) | **holds** | the runner reads `globalThis.process` (`codegen/AGENTS.md`) |

**Landed here** (compiler commit in `status.md`):

- **JS-4** — `val Circle(r) = s;` is `const { r } = s;`, `val Sq(side) = q;` `const { side } = q;`;
  `Pattern.match`, `MatchPattern` and `writeMatchPattern` deleted; a nested constructor is a nested
  object pattern (`ObjectPattern.Prop.nested`). Zero commonJS snapshots moved — no fixture reached a
  build site, which is why the bridge survived four landings.
- **C-09's commonJS half of `adder(3)(4)`** — `calleeExpr` is the callee; `test/curried_call.bp`'s
  commonJS line deleted (both tests pass).
- **C-18's commonJS half of decision 47** — `Array.at` goes through `__bp_array_at`, `null` out of
  range (a negative index included, as `String.at` and wasm answer); `run/index_past_the_end_is_null.bp`'s
  commonJS line deleted. 8 commonJS snapshots per tree moved: the helper and the call, and two RUN LOGs
  `undefined` → `null` (`array_at_lowers_byte_identically_across_backends`,
  `index_an_index_past_the_end_answers_zero`).

### The `.d.ts` under `tsc`

`npx -p typescript tsc --noEmit --strict --lib es2022 --module commonjs` (TypeScript 7.0.2) over
every snapshot of `snapshots/codegen/beam/commonJS/` with a non-empty typedef, each module's `.d.ts`
laid out at its module path so an import resolves the way it would under `out/`: **33 projects,
14 rejected** at `b6ba65a3`. Every failure was the `.d.ts` disagreeing with the `.js` beside it or
with TypeScript:

| Defect | Projects | Now |
|---|---|---|
| an import's source written verbatim — `from "geometry"`, a bare specifier — where the `.js` requires `./geometry.js`; `from "std"` for a std symbol | 9 | relative to the module's own path, one `import` per owning file (`CrossModule.picked`); a std module is `import * as dict from "./std/dict"`, a std symbol `import { empty as newDict } from "./std/dict"` |
| the same `import` written once per imported name | 7 | once per `ImportDecl`, each name bound once |
| an activated `implement` (`PatoNada*`) imported, which no `.d.ts` declares | 2 | left out |
| type parameters never declared — `class Dict`, `empty(): Dict<K, V>`, `fold(…): A` | 2 | `Dict<K, V>`, `empty<K, V>()`, `fold<A>(…)` |
| `Self` in a signature | 1 | the declaring type |
| a function type with unnamed parameters — `(A, K, V) => A` makes each `A` a parameter NAME | 2 | `(acc: A, key: K, value: V) => A` |
| a decorator declared (`describe(decl: Decl)`) though the program drops it | 2 | no declaration |

And one the `tsc` run could not see, because the typedef is valid TypeScript: **`@Result<T, E>` was
declared `{ tag: "Ok"; result: T } | { tag: "Error"; error: E }`** while every module builds and
reads `{ ok }` / `{ error }` — now `{ ok: T } | { error: E }` (2 snapshots). After: **33 of 33
accepted**. 16 commonJS snapshots per tree moved, typedef sections only; `tsc` is not in the checkout
or on `PATH` (it ran through `npx`), so the gate stays a measurement rather than a script.

**Decision 47 on the printer** (compiler `d798775b`, `decisions-pending.md` 0405-b): JavaScript's
`undefined` — what `?.` on an absent receiver and an `if` with no `else` answer — prints `null`, as
`Array.at`'s absence already did. 196 commonJS snapshots per tree moved, each by the one prelude line
(verified mechanically), and two RUN LOGs `undefined` → `null`.

**The status rows no step named** (re-measured 2026-09-26): a behavior literal's `self` method is an
object method now (compiler `ccfe6561`, `hi undefined` → `hi bo`); `\"` in an `@External.Node`
template, `await` inside an `if`/`else` of a `-> @Task<T>` body, a `try` inside a `while`, a
leading-dot variant, `x is <Enum>.<Variant>`, a function-valued record field and the `process` shadow
(01-std's handover 1) all answer right on commonJS at this branch — no change needed.
