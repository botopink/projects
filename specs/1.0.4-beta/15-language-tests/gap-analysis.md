# Gap analysis — what `tests/language/**` does not pin

Ranked by risk. Risk here is *how much working behaviour could break without this suite noticing*,
weighted by how much of the ecosystem depends on it.

**Measured at** `botopink-lang` `1193d3c` (2026-09-17), node v25.8.0, OTP 29. Every "verified" claim
was produced by running the program; every program quoted here is in
[`example-programs.md`](./example-programs.md) with its measured result.

## The shape of the gap

The first delivery of front 15 did exactly what its README says: it wrote **decision 8's** `case`,
tuples and `loop`, and listed what does not pass yet — 104 results over both targets, 27 of them
expected failures at the classification `AGENTS.md` records. But the
suite's own scope statement — "a front only for tests written in botopink" — has been read as
"only for decision 8", and the consequence is structural. The delivered suite is **34 files**
(17 `test/`, 3 `run/`, 14 `reject/`), three of them smoke cells:

| | Cells | Passing today |
|---|---|---|
| `loop` (§10) | 5 test + 2 reject | **all** |
| tuples (§6) | 5 test + 1 run + 2 reject | all but `tuple_equality` on commonJS and `tuple_print` |
| `case` (§5) | 6 test + 1 run + 9 reject | **none** — every cell is an expected failure of 06 N22 |
| everything else in the language | **0** | — |

So the only botopink-level regression net that exists covers `loop`, tuple labels and tuple
construction. Generics, behaviors, effects, comptime, decorators, externals, modules, closures,
primitive methods and the printer have **no botopink-level test anywhere in the compiler
repository** — their only coverage is Zig unit tests over the parser and the inferencer, and
snapshot fixtures that pin *emitted text*, not *observed behaviour*.

---

## G-1 — `val assert Ok(n) = f();` aborts the compiler · **critical**

Decision 8 §9 and `docs.md` both document it; decision 4 defines its failure semantics. Today it is
not a diagnostic and not a wrong answer — it is a **SIGSEGV** (`General protection exception`,
exit 134) in the parser's AST teardown, for `check`, `run` and `test` alike.

```botopink
type Opt { Some(v: i32), None }
pub fn main() {
    val assert Some(n) = Opt.Some(v: 3);
    @print(n);
}
```
→ `General protection exception (no address available)`, exit 134 (verified).

The same crash with `Ok(n) = parse(7)` on a `#[@result]` fn. With a non-call right-hand side
(`val assert Ok(n) = 5;`) it is a plain parse error instead, so the crash is on the path where the
right-hand side is a call or a constructor.

**Why it ranks first.** A crash cannot be classified as an expected failure — `run.sh` records it as
"does not compile", which understates it, and no cell exercises it at all. It is also the one
decision-8 construct that `libs/std` deliberately routes around: `libs/std/test/result_test.bp`
carries a comment explaining that it uses `unwrapOr` instead, and the reason given is a *different*
limitation (`isOk`/`isError` not lowered), so the crash is not recorded anywhere.

**Owner:** 06 (binding patterns / N11) — but the crash itself should be reported to the maintainer
before 06 starts, because "the compiler aborts" is not the same class of work as "the checker
accepts a wrong program".

## G-2 — §7's formatter is unimplemented and the two runnable backends disagree · **critical**

Decision 8 §7 replaces decision 1a with "one formatter per type, source-shaped, that every backend
uses". The suite pins **one row of a twelve-row table** (`run/tuple_print.bp`), and that one is
already listed as an expected failure. Measured, both backends, same program:

| Value | §7 requires | commonJS | erlang |
|---|---|---|---|
| `"hi"` top level | `hi` | `hi` ✓ | `hi` ✓ |
| `5.0` | `5.0` | `5` ✗ | `5.0` ✓ |
| `true` | `true` | `true` ✓ | `true` ✓ |
| `[1, 2]` | `[1, 2]` | `[1,2]` ✗ | `[1,2]` ✗ |
| `["a", "b"]` | `["a", "b"]` | `["a","b"]` ✗ | `["a","b"]` ✗ |
| `#(1, "a")` | `#(1, "a")` | `#(1,"a")` ✗ | `#(1,"a")` ✗ |
| `Point(x: 1, y: 2)` | `Point(x: 1, y: 2)` | `Point { x: 1, y: 2 }` ✗ | `#{x => 1,y => 2}` ✗ |
| `Shape.Square(side: 4)` | `Shape.Square(side: 4)` | `{ tag: 'Square', side: 4 }` ✗ | `{'Square',4}` ✗ |
| `Shape.Nothing` | `Shape.Nothing` | `Nothing` ✗ | `'Nothing'` ✗ |
| a `Display` implementation | its `display()` | `Money { cents: 5 }` ✗ | `#{cents => 5}` ✗ |

Two separate failures are stacked here. The **formatter** is wrong on nine of ten rows, and the two
backends are wrong **differently** on four of them — records, variants, `f64` and bare variant tags
each render in a host-native shape rather than a botopink shape. `f64` is the sharpest: `@print(5.0)`
is `5` on commonJS and `5.0` on erlang, which is precisely the "accepted numeric divergence" §7 says
it ends.

**Why it ranks second.** `@print` is how every `run/` cell asserts, and how users read their
programs. 01 step 6 will re-record every print-text snapshot in all four backends; without a
botopink-level table pinning the intended text first, the re-recording has no oracle other than the
prose table in decision 8 — exactly the situation the milestone rule "a snapshot is evidence, not a
baseline" exists to prevent.

**Owner:** 01 step 6 (run time, all four backends). The cell belongs here **now**, listed, so that
step 6 has a executable target rather than a table to re-read.

## G-3 — today's `case` has no test at all · **high**

Every `case` cell in the suite is written in decision 8's `Pattern { body }` form and every one is an
expected failure of 06 N22. The syntax that **works** today — arrow arms with `;` separators — is
what `libs/std/src/order.bp`, `libs/std/src/unicode.bp` and all of `emilia` are written in:

```botopink
type Order { Lt, Eq, Gt }
val n = case o { Lt -> -1; Eq -> 0; _ -> 1; };     // verified: compiles and runs, both targets
```

Nothing in `tests/language/**` executes that. If 06 N22's parser work broke arrow arms before the
ecosystem migrated (13), the language suite would stay green — every `case` cell is already listed as
failing, so the runner cannot distinguish "still not implemented" from "implemented and broke the old
form".

This is not an argument for pinning the old surface permanently: the front's rule ("tests describe
decision 8, not today's behaviour") is right. It is an argument that the **transition** is unguarded,
and that the guard belongs in `expected-failures.txt`'s discipline rather than in a new cell: a
listed cell that starts passing already fails the run. The concrete gap is that there is no cell
whose *passing* proves 06 N22 did not regress `libs/std`'s own `case` sites — which today only
`zig build test-libs` would catch, at a different layer.

**Owner:** 06 N22 landing; the mitigation is in the proposed layout (a `migration/` note, not a new
permanent cell).

## G-4 — `break <value>` is missing from the suite, wrong on commonJS, unsupported on erlang · **high**

The front's own README lists the scenario — "`loop { … break; }`; `break` with a value (loop as an
expression)" — and `test/loop_break.bp` contains three tests, none of which breaks with a value.

```botopink
var k = 0;
val r = loop { k = k + 1; if (k > 2) { break k; }; };
```

| Target | Result |
|---|---|
| commonJS | `r` is `[3]` — an array, not `3` (verified) |
| erlang | does not compile: `ConditionLoopValueUnsupported` (verified) |

A scenario the spec claims is covered, is not; and the behaviour underneath it is wrong in two
different ways. This is the clearest instance of the suite's gate ("every scenario bullet above has
at least one test") not actually holding.

**Owner:** 06 N6/N12 (value-less `if`, `loop_break_with_value`) and 01 step 6 for the erlang half.

## G-5 — effects have no botopink-level test · **high**

`#[@result]`, `#[@future]`, `#[@iterator]`, `#[@generator]`, `#[@asyncGenerator]`, `@Context` — six
effect annotations, each with a required return wrapper (§9). `libs/std` depends on two of them
(`fs`, `json`, `asserts` on `#[@result]`; `http` on `#[@future]`), `emilia` and `jhonstart` on
`#[@future]` and `@Context`. The suite touches none.

Measured today:

| Cell | commonJS | erlang |
|---|---|---|
| `#[@result]` + `catch` + `try` + `map`/`flatMap` | 5/5 pass | 5/5 pass |
| `#[@iterator]` + `yield` consumed by `loop (gen)` | 2/2 pass | **0/2** — `{case_clause,4}` at run time |

So `#[@result]` is a working, unpinned feature — a pure regression risk — and `#[@iterator]` is a
silent cross-backend divergence: the program compiles on erlang and then fails inside the generator
protocol at run time. Neither is visible to any botopink-level test.

§9's three rejection rules are also unpinned. Two of them are already right (verified) and one is
not:

| Rule | Today |
|---|---|
| annotation without its wrapper | ✓ `effect-wrapper-mismatch: #[@result] requires a -> @Result<…> return type` |
| `throw` outside a fallible fn | ✓ `effect-throw-without-fallible-channel: …` |
| wrapper without its annotation | ✗ reported as `type mismatch: expected Result, got i32` — not §9's rule |

**Owner:** 01 step 6 (the erlang iterator), 06 (the third diagnostic). The `#[@result]` cell is
pinnable **green today** and should be.

## G-6 — comptime, templates and sub-languages have no botopink-level test · **high**

This is the machinery the ecosystem is built on: `erika` compiles a SQL subset inside a comptime
body, `jhonstart` compiles markup inside one, `onze`'s `#[mock]` synthesises a whole type from
`@Decl` reflection, and all five of `rakun`'s DI markers emit their wiring with `@emit`. Four
distinct capabilities, zero cells:

| Capability | Verified today |
|---|---|
| `comptime n: i32` value parameter | works, both targets |
| `comptime q: @Expr<string>`, `sql "SELECT 1"` and `sql """…"""` | works, both targets |
| `#[d]` decorator + `@Decl` reflection + `decl.fail` | works, both targets |
| `@emit("<source>")` splicing a referenceable declaration | works, both targets |
| `@ExprCustom<T>` / `q.custom` / `CustomNode` | **unverified** — needs a project with a library dependency, which the current layout cannot express |

All four verified capabilities are green **today** and therefore pure regression risk: 06 owns
`src/comptime/{infer,transform,eval}.zig` and will move all of it, with nothing but Zig unit tests
and `test-libs` to catch a break. `test-libs` is a coarse net — it reports that `erika` went red, not
which construct did.

Two sharp edges found while writing the cells, both worth pinning because they are the kind of thing
that changes silently:

- a bare `if` (no `else`) inside a decorator body must be the **last** statement of the block;
  putting `@emit(…)` after it is `error: Unexpected token`.
- `(sql """ab""").length` does not parse — a template call needs a `val` intermediate before a
  method.

**Owner:** none open — these are green; the cells are a net for 06 and 07.

## G-7 — host externals have no botopink-level test, and the lower-case form is silently accepted · **high**

353 `#[@External.…]` occurrences in `libs/std` alone; every library binds its host state through
them. The suite has no cell. A two-target external works today (verified, both backends):

```botopink
#[@External.Node("Math.max($0, $1)")]
#[@External.Erlang("erlang", "max")]
declare fn hostMax(a: i32, b: i32) -> i32;
```

The rejection side is worse than unpinned — it is wrong. `fronts.md` records it as an unowned item
and it is confirmed:

```botopink
#[@external(node, "console.log($0)")]
declare fn hostLog(msg: string);
```
→ `botopink check` exits **0**. No host is bound, no diagnostic is produced. A user who writes the
lower-case form gets a program that type-checks and then fails at run time with an undefined symbol.

**Owner:** 06 (the annotation grammar), per fronts.md § unowned items.

## G-8 — modules are structurally untestable in the current layout · **high**

`run.sh` copies **one** file into `src/main.bp` (or `test/<n>.bp`). There is no way to express a cell
with two modules, a `mod` tree, a `.d.bp` sidecar, or a library dependency. So M1–M6 of the
inventory — `pub mod`, `import … from "module"`, `pub default mod`, `from "std"`, git dependencies,
`.d.bp` through `files` — are not merely unpinned, they are **unpinnable** without a layout change.

That matters right now, because a two-module program is broken on erlang at this commit:

```
src/main.bp      pub mod geometry; import { Point, origin } from "geometry"; …
src/geometry.bp  pub type Point(x: i32, y: i32) { pub fn norm(self: Self) -> i32 { … } }
```

| Target | Result |
|---|---|
| commonJS | `3` / `0` — correct (verified) |
| erlang | `escript: exception error: undefined function geometry:norm/1` (verified) |

A method on a `pub type` imported from a sibling module is emitted as a call to the *module*
`geometry:norm/1` instead of resolving the record's method. This is adjacent to the two unowned items
about cross-module emission (the commonJS `require("../module")` row and the erlang
`userTemplateNode` row) but is not either of them.

The same defect reaches `libs/std`. A three-line user program importing the std `Dict`:

```botopink
import { dict } from "std";
pub fn main() {
    val d = dict.empty().insert("a", 1);
    @print(d.lookup("a").unwrapOr(0));
}
```

| Target | Result |
|---|---|
| commonJS | `1` — correct (verified) |
| erlang | does not compile: `out/main.erl: function insert/3 undefined` (verified) |

So a method on a type imported from **any** module — a sibling or a std module — is unresolved on
erlang. `libs/std`'s own `zig build test-libs` does not catch it, because `dict.bp`'s tests call
`insert` from *inside* `dict.bp`, where the method resolves. It takes a consumer in another module to
expose it, and the language suite is exactly where that consumer should live.

**Owner:** the layout change is front 15's own (see [`proposed-layout.md`](./proposed-layout.md));
the erlang defect is 01 step 6 or a follow-up, and should be reported.

## G-9 — generics and behaviors have no botopink-level test; §1.1 is accepted today · **medium**

`Dict<K, V>`, `Queue<T>`, `Query<T>`, `Bag<T>` — generics are everywhere in std and the libraries,
and §1.1–§1.4 are among the largest pieces of 06's work. The suite has no cell.

Three measurements:

| Program | Today |
|---|---|
| a generic type + a generic method changing the argument (`Bag<T>.map<U>`) | works, both targets |
| a `behavior` `default fn` running against an implementation | works on commonJS; **fails on erlang** |
| `fn get(b: Box) -> i32` — §1.1's "Box needs 1 type argument" | **accepted**, exit 0 (verified) |

The `default fn` divergence is notable because `libs/std/src/primitives.bp` is built on interface
default methods (`default fn clamp`, and the whole `Number`/`Integer`/`Signed` chain) — a user type
implementing a `behavior` with a default method gets different behaviour on the two runnable
backends, and nothing says so.

**Owner:** 06 N18 (§1.1's diagnostic); the `default fn` erlang half is 01 step 6.

## G-10 — primitive methods are unpinned, and `toUpperCase` does not compile on erlang · **medium**

`tests/language/**` never calls a string or array method except incidentally. Isolated, one method
per cell, on erlang:

| Method | erlang |
|---|---|
| `"abc".toUpperCase()` | **does not compile** — `function toUpperCase/1 undefined` (verified) |
| `.split`, `.trim`, `.startsWith`; `.filter/.map/.join`, `.slice`, `.at`, `.indexOf`, `.fold` | all pass |

One method out of nine emits a call to a function it never defines. `libs/std/test/primitives_test.bp`
covers the primitive surface from inside `libs/std`, and `zig build test-libs` runs it — so this is
not *entirely* unguarded — but it is invisible to the language suite, and `primitives_test.bp` runs
against `libs/std`'s own scratch project rather than a user project.

**Owner:** 01 step 6 / an erlang follow-up. Report it.

## G-11 — trailing parameter defaults are documented and not implemented · **medium**

`docs.md` documents them, `libs/std/src/builtins_fns.d.bp` declares one
(`message: string = "not implemented"`), 06 N1 owns them (1.0.2-beta comptime-dispatch step 3,
"never executed"). Measured:

```botopink
fn connect(host: string, port: i32 = 80, timeout: i32 = 30) -> string { … }
connect("a")            // error: 'connect' expects 3 argument(s), got 1  (verified, both targets)
```

Unpinned, so 06 N1 has no acceptance test.

**Owner:** 06 N1.

## G-12 — a labeled tuple element of function type is not callable · **medium**

`fronts.md` records this as an unowned item found by the erlang-calls fix, suggested owner 06 N24. It
is confirmed on both backends:

```botopink
fn counter(start: i32) -> #(value: i32, bump: fn(n: i32) -> i32) { … }
val c = counter(1);
c.bump(8)               // commonJS: "c.bump is not a function"; erlang: does not compile
```

It matters beyond the tuple rules because `jhonstart/src/hooks.bp` returns exactly this shape from
`reducer` (`#(state: S, dispatch: fn(action: A))`) and `State<T>(value: T, set: fn(next: T))`, so
front 13's jhonstart migration is blocked on it. The suite's five tuple cells cover T1–T6 for data
elements and stop there.

**Owner:** 06 N24.

## G-13 — closures as arguments and as return values are unpinned · **medium**

The suite exercises lambdas only as `loop` bodies. Not covered: a lambda passed as a parameter, a
closure returned from a function, a closure capturing an outer `var` inside `forEach`/`map` (as
opposed to inside `loop`), and a closure nested in a loop body. All four work today on both targets
(verified) — pure regression risk, and closure/loop variable threading is a row that has already been
re-fixed once per backend (01's "closure var threading" on erlang, beam and wasm).

One parse limit found: `adder(3)(4)` — calling the result of a call directly — is
`error: Unexpected token`. A `val` intermediate is required. Worth a `reject/` cell only if the
maintainer decides it should parse; today it is a documented shape, not a bug.

**Owner:** none open — a net for 06 and 01 step 6.

## G-14 — beam and wasm are outside the suite by construction · **low, structural**

`botopink test` and `run` execute commonJS and erlang. Decision 8's run time is 01 step 6 on **four**
backends. The README says beam and wasm stay in the codegen snapshots, which is correct and
unavoidable today — but it means "the language tests are green" is a statement about half the
matrix, and the §7 formatter table (G-2) in particular will be pinned on two backends and
snapshot-recorded on two others, with nothing tying the two halves together.

**Owner:** none; recorded so the gate wording does not overclaim. A `build`-only smoke cell per
backend (does this program still *compile* to beam and wasm?) is cheap and is proposed in the layout.

## G-15 — `case` scenarios in the README that no cell covers even in future form · **low**

Cross-reading the README's §5 bullet list against the 16 `case` cells: nested patterns
(`Option.Some(#(a, b))`) appear in the bullet list and in no cell; §5.3b's section-as-a-type and
"matching into a section is a refinement" (06 N28, decided after the suite was written) have no cell
at all, in any form; P5's "the bound variable's type from the matched value" is covered for
`unknown` but not for a union or a generic payload. These are cheap to add while the whole area is
already listed as failing.

**Owner:** 06 N22/N28.

---

## Summary ranking

| # | Gap | Risk | Owner |
|---|---|---|---|
| G-1 | `val assert Ok(n) = f()` aborts the compiler | critical | 06 (report first) |
| G-2 | §7 formatter unimplemented; backends disagree | critical | 01 step 6 |
| G-3 | today's working `case` has no test | high | 06 N22 (transition guard) |
| G-4 | `break <value>` missing, wrong, unsupported | high | 06 N6/N12, 01 step 6 |
| G-5 | effects unpinned; `#[@iterator]` breaks on erlang | high | 01 step 6, 06 |
| G-6 | comptime/templates/decorators unpinned | high | net for 06, 07 |
| G-7 | externals unpinned; lower-case form accepted | high | 06 |
| G-8 | modules structurally untestable; erlang cross-module method broken | high | 15 (layout) + report |
| G-9 | generics/behaviors unpinned; §1.1 accepted; `default fn` erlang divergence | medium | 06 N18, 01 step 6 |
| G-10 | primitive methods unpinned; `toUpperCase` erlang | medium | 01 step 6 |
| G-11 | trailing defaults documented, not implemented | medium | 06 N1 |
| G-12 | labeled tuple element of fn type not callable | medium | 06 N24 |
| G-13 | closures as arguments/returns unpinned | medium | net |
| G-14 | beam and wasm outside the suite | low, structural | — |
| G-15 | README `case` scenarios with no cell | low | 06 N22/N28 |

## Items to report to the maintainer before 06 starts

1. **G-1** — a compiler abort, not a checker gap. Different class of work.
2. **G-8's erlang defect** — a method on a type imported from another module is undefined on erlang
   (`geometry:norm/1` for a sibling module, `insert/3` for `libs/std`'s `Dict`). Not the same as
   either cross-module unowned item already listed in `fronts.md`, and it means a user program that
   imports the std `Dict` does not compile on erlang.
3. **G-10** — `"abc".toUpperCase()` emits an undefined erlang function.
4. **`Option` does not exist.** Decision 8 writes `Option<i32>.None`, `Option.Some(v)` and
   `Option<string>` in §1.3, §1.4, §3.4, §4.2, §5.1, §5.2 and §5.3; `libs/std/src/builtins.d.bp:58`
   says the optional type is `?T` and that `Option<T>` annotations are **rejected**. `val z =
   Option<i32>.None;` is "unbound variable 'Option'" today. Either §8 introduces `Option` as a named
   type (which 06 would have to build) or its examples must be rewritten against `?T`. This is a
   decision, not a bug, and it blocks writing correct `case`-on-variant cells.
