# Front 05 — wasm

**Priority:** high — wasm is the backend that can answer a **wrong value with exit 0 and no
diagnostic**; the rule this front holds is that a shape wasm cannot do traps instead
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies)
**Owns:** `modules/compiler-core/src/codegen/wat.zig` ·
`modules/compiler-core/src/codegen/wat/**` (`wat_ast.zig`, `wat_emitter.zig`, `wat_prelude.zig`) ·
the wasm snapshots under `modules/compiler-core/snapshots/codegen/<runtime>/wasm/**` · the `KNOWN`
notes and new fixtures of its rows in `modules/compiler-core/src/codegen/tests/**` (a carve-out from
[`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/beam_asm.zig`, `src/codegen/beam/**` ([`03-beam`](../03-beam/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `modules/compiler-cli/**` · `libs/std/**`

Paths are relative to `repository/botopink-lang/`; programs run with `botopink run --target wasm`
(wasmtime). Carry-over items: C-06, C-07, C-09, C-18 — see [`../README.md`](../README.md).

---

## Steps

Decision 8 at run time holds on wasm. The named-type half rides on C-01's descriptor header (a value
carries its declaration); the box of step 2 generalises that header, so one field answers "which
primitive" and "which declaration".

### Step 1 — the §7 formatter — delivered

`5.0`, `[1, 2]`, `["a", "b"]`, `#(1, "a")`, `Point(x: 1, y: 2)`, `Shape.Square(side: 4)`,
`Shape.Nothing`; `Display` is consulted first (`$__print_tagged_raw` asks `$__display_of(v)`, which
`wat.zig` fills after lowering with one descriptor compare per record type declaring
`display(self) -> string`). The empty `?T` prints `null` (`$__print_null`, decision 47).
`run/tuple_print.bp`, `run/print_formatter.bp` and `run/display_print.bp` pass.

### Step 2 — decision 8 at run time: the box, `is`, `unknown`, `case` arms, labels — delivered

A value entering an `unknown` or union slot carries the header a declared value already carries; a
primitive is boxed with a `'P' <n> name` descriptor, so 13's named-type tests read an `unknown` value
unchanged. `x is T` by value (§4.1), `==` by value (§2.3), `@print` by the box, `if (x is T)`
narrowing, primitive-type `case` arms (§5.2), `x is Enum.Variant` (the one variant's descriptor);
tuple labels resolve to positions on the read and the call path (`run/unknown_by_value.bp`,
`tuple_labels_resolve_to_positions_on_every_backend`). Known limits, each a trap rather than a guess:
a value whose type nothing proves (a type parameter's slot — nothing monomorphises; `tests/wat.zig`
pins it); an array or tuple through `unknown` (boxed with a descriptor, but no printed form and no
element-wise `is`); a leading-dot variant two enums declare.

### Step 3 — `Dict.at` answers the fallback — delivered

`import {collections.Dict} from "std"`; `Dict.empty().insert("a", 1)` then `d.at("a")` answers the
present value. The cause was two `?T` writer/reader disagreements; the `?T` has one carrier now, its
readers agree with it, and an unregistered shape is loud.

- [x] the probe prints `1` and `9` (`d.at("a").unwrapOr(0)`, `d.at("zz").unwrapOr(9)`)
- [x] `wasm | modules/std_import` left `expected-failures.txt`; the cell is green
- [x] a fixture in `src/codegen/tests/**` pins the minimal shape (a `forEach` writing an outer `var`)
      with a RUN LOG — `wat.zig` `option ---- a value assigned into a declared ?T is boxed like one`
      (`[1, 2].forEach({ n -> seen = n }); @print(seen)` → `2`)
- [x] the wrong-answer class is audited: any other shape that answers a value with exit 0 and no
      diagnostic is listed in `src/codegen/wat/AGENTS.md` or fixed — § *Where this backend refuses to
      answer* and § *The carrier of a `?T`*

### Step 4 — `break <value>` — superseded

Decision 105: `break v` exists only in a generator scope (C-30); a bare `break` at a generator fn's
own level ends it (`run/generator_break_value.bp`).

### Step 5 — `==` on tuples — delivered

`#(1, "a") == #(1, "a")` → `true`, `… == #(1, "b")` → `false`; labels take no part (§6 T5, T6).

### Step 6 — the primitive method table — delivered

`"aB".toUpperCase()` / `toLowerCase()` answer `AB` / `ab` (`$__str_case`).

- [x] `AB` / `ab`
- [x] the audit — `src/codegen/wat/AGENTS.md` § The primitive method table: `Float.toString`,
      `String.charCodeAt`/`lastIndexOf`/`padStart`/`padEnd`/`replace`/`replaceAll`/`chars` lowered, and
      the methods left (`String.lines`/`words`, `Array.pop`/`flatMap`/`flatten`/`flat`/`chunked`/
      `sliding`/`fill`/`unique`) each pinned as a trap by one program in `src/codegen/tests/wat.zig`;
      `Array.find` is lowered since (`filter` then `at(0)`)

### Step 7 — a function value held in a value — delivered

A lambda held in a tuple, a record field or a variable is applied (a function table and
`call_indirect`; `src/codegen/wat/AGENTS.md` § Function values). Calling the result of a call —
`adder(3)(4)`, `greeter("a")("b")` — goes through `lowerValueCall` (`calleeExpr`, `valueCallTypeRef`,
`expected_fn`), C-09's wasm half.

### Step 8 — the block-as-value lowering decision 2 leaves dead — struck

Measured: wasm has no such lowering (`src/codegen/wat/AGENTS.md`).

### Step 9 — the `?T` carrier rows

| Shape | State |
|---|---|
| **Self-recursion** — `return f(args)` inside `fn f` | delivered: re-binds the parameters and `br`s to a `(loop $__tail …)` wrapping the body; `run/tail_self_call.bp` green on four targets. Only the explicit `return f(…)` spelling is recognised (`src/codegen/wat/AGENTS.md`) |
| **`es.map({ e -> e.key })` as a string array** — `ks.at(0)?.length()` | wasm prints `3`; the commonJS half (`.length` renamed on an unresolved element type) is [`04-js`](../04-js/README.md)'s `run/map_record_field_length.bp` line |
| **A primitive method on the rest of a `?.` chain** — `es.at(9)?.key.length()` | wasm: runs under the chain's guard (`lowerChainedCall`) — absent stays absent, present unboxes the receiver and boxes a scalar result; `run/optional_chain_method.bp` green on commonJS and wasm; the erlang and beam lines are [`02-erlang`](../02-erlang/README.md)'s and [`03-beam`](../03-beam/README.md)'s |
| **beam: `modules/field_name_collision`, `modules/method_name_collision`** | moved to 03, which closed them |

**Acceptance:** one `run/` cell per row on four targets, green by running — open while the commonJS,
erlang and beam lines above stand.

### Rows no step named — delivered

An enum's methods are emitted and its associated fn is a call; a method declared `-> @Iterator<T>`
accumulates its yields; a method on a value of an imported type resolves through the receiver's
record; the optional binder takes the payload's record type; a `_`-named top-level statement runs at
load; a constructor in binding position reads each binding off its field's slot (JS-4's twin); a
behavior's `default fn`s are adopted by a type that does not write them; a method answers the record
its return names; `opt.map(…)` is a registered optional; a slice's `null` end is the end; a variant
reached through its enum is the enum's even beside a same-named record; a function two linked
modules declare is mangled per module (`<module>/<name>`) and every call that means it is rewritten
to it, and a module-level `val` two modules declare traps where it is read; a float literal is an
`f64.const` and a radix literal its decimal value; a named record's `f64` field is a boxed `f64`
cell, and a method's float parameter and result are the float it declares; a `?V` over a type
parameter is always a box (C-18's wasm half), a method's `return` boxes into its declared `?T`, and
a `?T[]` of a scalar prints as the array or `null`; a lambda in a function-typed field takes its
parameter types from the field, and the call its return type; `try f()` over a `-> @Result<T[], E>`
is an array, and a `for` over an iterable wasm cannot walk traps; a bare `return;` in a function
with a result leaves with the neutral value.

### Open rows with no numbered step

- **`==` between two type-parameter values compares words** —
  `modules/method_on_unimported_type`: `Dict.at` finds a string key only when both sides are one
  interned literal; nothing monomorphises (`src/codegen/wat/AGENTS.md` § the generic-parameter
  limit).
- **`val assert` over a record's constructor** — `run/val_assert_record_pattern.bp`: the pattern is
  neither tested nor bound.

## Dependencies

| This front's row | Needs |
|---|---|
| type-parameter `==` | the instantiated type at the call site — monomorphisation or a tagged word |

## Gate

- [x] `scripts/gate.sh --cold` green in this front's worktree — stage by stage (a worktree nested in
  the meta checkout cannot run `test-libs` whole, `decisions-pending.md` 24-f)
- [x] every re-recorded RUN LOG **verified by running the program** under wasmtime, and checked
  against decision 8 §7 — each moved log compared with commonJS's for the same fixture
- [x] no new `RUN LOG` answers a value with exit 0 that another backend answers differently — a shape
  wasm cannot do is a `RUNTIME TRAP`, never a wrong number
- [x] the `RUNTIME TRAP` fixtures are re-read: each is still a shape wasm cannot do, or it is fixed —
  those left are the program's own `@todo()`, a fatal `assert` outside test mode, and a
  module-level `val` two linked modules declare
- [x] `src/codegen/AGENTS.md` and `src/codegen/wat/AGENTS.md` updated in the same commit as each row
- [x] Commit on a branch; no push, no merge — `front/04-05-js-wasm`

## Notes

- **wasm must not answer wrongly and silently.** Where wasm cannot do a shape, it traps with the
  `RUNTIME TRAP` mechanism; a wrong value with exit 0 is a bug even when a fixture records it.
- **`botopink test` refuses wasm**, so only `run/` and `modules/` cells reach it; rows with no
  listed line are asserted by hand plus a fixture.
- **This front moves only wasm snapshots.** If a change here moves the erlang, beam or commonJS
  snapshots, something crossed a boundary — stop and report.
