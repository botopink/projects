# Decisions the maintainer owes — 1.0.5-beta

One open question the milestone cannot answer for itself — the other twenty-six are answered, in
[`decisions-taken.md`](./decisions-taken.md). Each is stated with the evidence that
produced it, the options, a recommendation, and what it blocks. **The numbers are stable**: a question
that has been answered leaves this file for [`decisions-taken.md`](./decisions-taken.md) and its number
is not reused, so a front citing "decision 5" keeps citing the same thing. They were found by the fronts of
1.0.4-beta while implementing, not while planning: every "measured" line below was produced by a
command or by running a program, and the file or commit is named so it can be repeated.

| # | Question | Blocks | Recommended |
|---|---|---|---|
| [26](#26-case-arms-of-different-types-union-or-error) | Union, or an error? | two fixture slugs named for the answer | union |

---

## Carve-outs to grant

Three small grants the schedule needs. Each was verified cheap, and each belongs to a front that is
not the one asking:

| Grant | From | To | Verified |
|---|---|---|---|
| Two call sites in `infer.zig` — `decoratorEval.evaluate` (`:2341`) and `templateEval.evaluate` (`:3522`) | `01-checker` | `14-comptime-on-beam` | the lines were relocated at `c2dd780`; nothing else in the file moves |
| The evaluation-protocol half of `runtime/persistent_erl.zig` | `08-hygiene` | `14-comptime-on-beam` | no open hygiene step names the file; the group that touched it is delivered |
| The four module-atom sites in `erlang.zig` / `beam_asm.zig` (13's first half) | `02-erlang`, `03-beam` | `13-module-identity` | no emitted shape changes — a carve-out, not a stop |


---

## 26. `case` arms of different types — and what an inferred union costs

**Reformulated 2026-09-18**, with the examples the question was missing. The question is not really
about `case`: it is about whether a **union type can be produced by inference**, or only by being
written down.

**The program in question.**

```botopink
fn describe(n: i32) -> string {
    val label = case n {
        0 { "zero" }        // this arm is a string
        _ { n }             // this arm is an i32
    };
    return label;           // …so what is `label`?
}
```

**(a) the arms union** — `label` is `string | i32`, and nothing more happens here. The cost lands on
the next line: to *use* `label` you must narrow it, and the union travels through inference into
places nobody wrote one:

```botopink
val label = case n { 0 { "zero" } _ { n } };   // label: string | i32
@print(label);                                  // which formatter? the printer must handle both
val up = label.toUpper();                       // error — `i32` has no `toUpper`
if (label is string) { @print(label.toUpper()); }   // this is what the programmer must write
```

**(b) the arms must agree** — the `case` above is an error, and the programmer converts:

```botopink
val label = case n { 0 { "zero" } _ { n.toString() } };   // label: string
```

**(c) — the counter-proposal, which the file did not have: the arms must agree *unless the union is
written*.**

```botopink
val a = case n { 0 { "zero" } _ { n } };                  // error: arms disagree —
                                                          // annotate `string | i32` if that is meant
val b: string | i32 = case n { 0 { "zero" } _ { n } };    // fine: the union is written
```

**Why (c).** Under (a) a union can appear in a type nobody wrote, and then every backend must carry a
value whose type is a union, every error message must print one, and `@print` must decide what to do
with it at run time — that is the same problem [decision 22](./decisions-taken.md) is solving for
wasm, arriving by a second road. Under (c) unions stay a thing the programmer asks for, which is
where decision 8 §3 actually uses them (annotations, parameters, returns), and the diagnostic teaches
the annotation instead of silently widening.

**Measured, so the cost of each is known:** all **32** `case`-as-value blocks across the six
libraries are homogeneous — every arm already agrees. So (a), (b) and (c) cost **zero migration**
today; the difference is entirely about what the language promises next. Two fixture slugs are named
for answer (a) (`case_arms_with_different_types_string_i32_union`) and would be renamed under (b) or
(c).

**Recommendation: (c).** It is (b)'s cost with (a)'s expressiveness, and it is the only one of the
three where an inferred type never contains a union the programmer did not write.

**Blocks:** `01-checker`'s steps 2 and 4 — union inference and `case` arm typing are the same step
under (a), and two different steps under (c).
