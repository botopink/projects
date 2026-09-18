# Front 03 — beam

**Priority:** high — beam is the backend furthest behind: it never received decision 1a's print text,
so it is two decisions behind the other three, and it is the only one that cannot execute a method on
a type from another module
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies). BR5 and the formatter depend on nothing
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` ·
`modules/compiler-core/src/codegen/beam/**` ·
`modules/compiler-core/snapshots/codegen/beam/**` (314 files) · `scripts/beam_export_audit.sh` ·
the `KNOWN` notes and new fixtures of its rows in `modules/compiler-core/src/codegen/tests/**`
(a carve-out from [`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `src/codegen/wat.zig`, `src/codegen/wat/**`
([`05-wasm`](../05-wasm/README.md)) · `modules/compiler-cli/**`

Paths are relative to `repository/botopink-lang/`. Every output below was produced against
`botopink-lang` `c2dd780` on 2026-09-18: `botopink build --target beam`, then
`erlc +from_asm out/*.S`, then `erl -noshell -pa out -eval "main:'_botopink_main'(), halt()."`.

---

## Problem

**Beam has no formatter.** 1.0.4's front 01 step 4 landed decision 1a on commonJS, erlang and wasm
(`a40daf4`); PR3, the beam row, was deferred to step 6 and never ran. Decision 8 §7 then superseded
decision 1a, so beam owes both at once. `tests/language/run/print_formatter.bp`, run as above:

| Value | §7 wants | beam prints | commonJS / erlang / wasm |
|---|---|---|---|
| `5.0` | `5.0` | `5.0` | `5` / `5.0` / `5` |
| `[1, 2]` | `[1, 2]` | `[1,2]` | `[1,2]` everywhere |
| `["a", "b"]` | `["a", "b"]` | **`[<<"a">>,<<"b">>]`** | `["a","b"]` everywhere |
| `#(1, "a")` | `#(1, "a")` | **`{1,<<"a">>}`** | `#(1,"a")` everywhere |
| `Point(x: 1, y: 2)` | `Point(x: 1, y: 2)` | `#{x => 1,y => 2}` | — |
| `Shape.Square(side: 4)` | `Shape.Square(side: 4)` | `{'Square',4}` | — |
| `Shape.Nothing` | `Shape.Nothing` | `'Nothing'` | — |

The two rows in bold are decision 1a, which beam alone never got: a nested string reaches the log as
an Erlang binary and a tuple as a bare Erlang tuple.

**A method on a type from another module is not applied.** `tests/language/modules/two_modules`,
every module assembled and on the code path:

```
Runtime terminating during boot ({{badfun,#{x=>1,y=>2}}, [{main,main,0,…}]})
```

and `modules/std_import`, the same shape through the std `Dict`:

```
Runtime terminating during boot ({{badfun,#{pairs=>[]}}, [{main,main,0,…}]})
```

`modules/mod_tree` — a *fn*, not a method, from a folder-index module — prints `circle`, `7`
correctly. So the defect is precisely: **a method whose owning type came from another module is
lowered as `call_fun` on the record's map.** Erlang emits the same programs correctly
(`geometry:norm/1`), which is the twin this front owes.

## Current state

`scripts/beam_export_audit.sh` at `c2dd780`: **315/315 modules assembled**.

**This front has no line in `tests/language/expected-failures.txt`, and that is the problem.** The
language runner excludes beam by design — `botopink run --target beam` writes `out/main.S` and stops,
because BEAM assembly is an artifact, not a run (`tests/language/AGENTS.md`: *"beam is excluded …
decision-8 coverage stays in `snapshots/codegen/beam/`"*). So every row below is asserted by a
`snapshots/codegen/beam/` RUN LOG and by running the program by hand with `erlc +from_asm`, and
**not one of the 54 expected-failure lines belongs to this front**. Say so in the landing note: a
front with no listed failure is not a front with no work, it is a front the suite cannot see.

Measured over `snapshots/codegen/beam/` (314 files):

| Measurement | Count |
|---|---|
| snapshots carrying a `----- RUN LOG -----` block | 305 |
| of those, with a non-empty log | 151 |
| of those, whose text changes under §7 (array, tuple, float, record, or an Erlang binary) | **17** |
| snapshots whose emitted `.S` carries the `'__bp_print'` prelude | **163** |
| snapshots carrying `'__bp_erl_eval'` | **11** files, **22** occurrences |

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

### Step 1 — BR5: `@External.Erlang` templates compiled at build time

The maintainer answered BR4 in 1.0.4: beam stops evaluating `@External.Erlang` templates at run time.
A partial, untested start exists in the 1.0.4 `.tasks/beam-templates` worktree (branch
`fix/beam-templates`); treat it as a sketch, not a base.

```
#[@External.Erlang("string:uppercase($0)")] declare fn up(s: string) -> string;
   → out/main.S:37: {function, '__bp_erl_eval', 2, 9}.
```

The erlang backend already renders the same template to source. **Reuse that rendering or a shared
template walker — do not add a second template language.** The eleven snapshots that carry the
helper today:

```
string_slice_copies_bytes_into_a_new_buffer      string_slice_result_length_is_readable
string_slice_both_bounds                         string_methods_map_to_native_js_names
external_1_arg_host_expression_declare_fn_renders_at_the_call_site
external_a2_chained_host_call_renders_verbatim   external_a2_method_on_global_template_keeps_receiver_bound
external_a3_result_template_owned_declare_fn     external_an_imported_host_backed_declare_fn_is_wrapped_by_its_owner
array_zip_via_external_node_template             bool_instance_default_fn_methods
```

**Acceptance:**
- [ ] no `'__bp_erl_eval'` left in any beam snapshot, **or** each remaining use named with its reason in `src/codegen/beam/AGENTS.md`
- [ ] every RUN LOG unchanged — this is a lowering change, not a behaviour change
- [ ] `scripts/beam_export_audit.sh` still assembles every module (315/315 at `c2dd780`)
- [ ] the measured cost that motivated BR4 (`'__bp_erl_eval'/2` at roughly 50× a direct call, recorded in `src/codegen/beam/AGENTS.md`) is re-measured and the note updated

### Step 2 — the formatter: decision 1a **and** §7, in one landing

Beam is the only backend that needs both, so it writes one formatter and records its snapshots once.

| # | Row | Acceptance |
|---|---|---|
| F0 | a nested string prints as `"a"` with source escapes, not `<<"a">>`; a tuple prints as `#(1, "a")`, not `{1,<<"a">>}` (this is 1.0.4's PR3) | `run/tuple_print.bp`, run by hand, matches its `.out` |
| F1 | spaces after the separator — `[1, 2]`, `["a", "b"]`, `#(1, "a")` (§7) | the same |
| F2 | a record prints `Point(x: 1, y: 2)`, not `#{x => 1,y => 2}` | needs named-type identity — [Dependencies](#dependencies) |
| F3 | a variant prints `Shape.Square(side: 4)` / `Shape.Nothing` | the same |
| F4 | `Display` is consulted, nested too | `run/display_print.bp`, by hand |
| F5 | `f64` always carries its decimal part | already holds on beam |

F0, F1 and F5 are this front's alone; F2, F3 and F4 land with [`13-module-identity`](../13-module-identity/README.md).

### Step 3 — decision 8 at run time: `is`, unions, `unknown`, `case` arms, labels, `loop`

The beam twin of [`02-erlang`](../02-erlang/README.md)'s steps 2–5, written against BEAM assembly
rather than erlang source:

| # | Row |
|---|---|
| D1 | `x is T` by value (§4.1, §4.2) — `is_integer` + range guards, `is_float` plus an integral check and a conversion, `is_binary`, `is_boolean`, tuple arity and each element |
| D2 | `unknown` and unions at run time: beam stores nothing extra (§11) |
| D3 | §2.3 — `==` with an `unknown` operand compares numbers by value |
| D4 | `case` arms (§5): type tests, `..`, `when (…)` guards, the dot shorthand, labelled payloads |
| D5 | tuple labels → positional (§6 T4). N24 (`174e0e4`) landed the read path and the fn-typed-element call on beam; re-verify and close |
| D6 | `loop (condition)` with a value `break` — refused today with the same unlocated `ConditionLoopValueUnsupported` erlang raises |
| D7 | `break <value>` — verify against the commonJS and wasm defect (both yield a one-element array); beam's behaviour is unmeasured because the language suite does not run it |

**Acceptance:** every `tests/language` cell that names `§4`, `§5`, `§6` or `§10` runs by hand on beam
and matches its `.out`; each gets a `snapshots/codegen/beam/` fixture whose RUN LOG is the value that
was run.

### Step 4 — a method on a type from another module

The row measured in [Problem](#problem): `{badfun, #{x=>1,y=>2}}`. The record's map reaches a
`call_fun` where a remote call to the owning module's function belongs. Erlang's landing
(`7783fd6`, `1193d3c`) is the model: name the owning module and call `<module>:<method>/N`.

**Acceptance:**
- [ ] `modules/two_modules` and `modules/std_import`, assembled and run by hand, print `3`/`0` and `1`
- [ ] a fixture in `src/codegen/tests/**` pins a method on an imported type, with a RUN LOG
- [ ] `beam_export_audit.sh` still assembles every module

### Step 5 — the block-as-value lowering decision 2 leaves dead

`grep -c make_fun3 modules/compiler-core/src/codegen/beam_asm.zig` → **12** sites. Once
[`01-checker`](../01-checker/README.md) step 8's R7 enforces decision 2, the ones that exist to give
a block a value have no producer.

**Acceptance:** the dead sites are gone; `snapshots/codegen/beam/` is otherwise byte-identical (a
diff outside the removed shape is a bug found); `src/codegen/beam/AGENTS.md` records which of the 12
were block-as-value and which are genuine closures.

## Dependencies

| This front's step | Needs from [`01-checker`](../01-checker/README.md) |
|---|---|
| 1 (BR5) | nothing |
| 2 (formatter) F0, F1, F5 | nothing |
| 3 D1–D3 (`is`, unions, `unknown`) | steps 1–3 |
| 3 D4 (`case` arms) | steps 4–5 |
| 3 D5 (labels) | nothing — N24 landed |
| 3 D6, D7 (`loop`, `break`) | nothing |
| 4 (imported-type method) | nothing |
| 5 (dead lowerings) | step 8's R7 |

**The named-type half of decision 8 is not this front's.** `is Person`, a union of named types, a
`case` over them and F2/F3/F4 all need a value to answer which named type it is at run time — the
third half of [`13-module-identity`](../13-module-identity/README.md). The cut agreed with the maintainer: the backends take primitives,
tuples, the wasm box and `loop`; 13 takes named-type identity.

### Ordering against [`13-module-identity`](../13-module-identity/README.md)

[`13-module-identity`](../13-module-identity/README.md) owns `codegen/beam_asm.zig` **whole** in its second and third halves (policy 3,
and identity inside the value), and re-records 188 + 130 snapshots across
`snapshots/codegen/{erlang,beam}/`. The two cannot run at the same time.

[`../decisions-pending.md` #4](../decisions-pending.md) asks this for the milestone and recommends
**(a) 14 → 13 → the backends**. This front's measurement agrees with it for every row **except one**,
and the exception is not a preference — it is a sequencing constraint:

**BR5 must precede 13, whatever else is decided.** Policy 3 splits the emitter into a module per
type. Splitting an emitter that still carries a run-time template evaluator means splitting
`'__bp_erl_eval'` across the pieces and then deleting it out of each of them, instead of deleting it
once from one emitter. BR5 also re-records **only the `.S` text of the 11 snapshots that carry the
helper and no RUN LOG at all**, so it is the cheapest thing in this front to pull forward.

| Order | Cost, measured |
|---|---|
| **(a) 13 → 03**, BR5 included | one recording per snapshot, in the final module layout. But `'__bp_erl_eval'` is split by policy 3 and then deleted from the pieces, and the only backend without decision 1a's print text stays that way for the milestone's longest front — unmeasured by the language suite, which does not run beam at all |
| (b) 03 → 13 whole | 17 RUN LOGs and up to 163 prelude-carrying `.S` texts recorded twice. That set is a **subset** of the 188 + 130 files 13 re-records anyway, so it is the same files touched twice rather than extra files — but two reasons pass over them |
| **(c) BR5 first and alone, then 13, then steps 2–5** — **recommended** | BR5 moves 11 `.S` texts and no RUN LOG; nothing else in this front runs before 13. 13 then splits an emitter with no run-time template evaluator in it. The formatter (F0–F5 in one commit) and steps 3–5 land after 13, each snapshot recorded once. This is (a) with one row pulled forward for a stated technical reason |

Whatever the order, beam's own halves land separately: **BR5 first and alone**, the formatter after,
so no re-recorded snapshot ever carries both reasons; and F2/F3/F4 land inside
[`13-module-identity`](../13-module-identity/README.md)'s commit with the rest of §7.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `scripts/beam_export_audit.sh` assembles every module, before and after each row
- [ ] every re-recorded RUN LOG **verified by running the program** — `erlc +from_asm out/*.S` then `erl -pa out -eval "main:'_botopink_main'()"` — and checked against decision 8 §7
- [ ] every `tests/language` cell this front's rows touch run by hand on beam and matched against its `.out`, with the transcript in the landing note (the suite cannot do it)
- [ ] `src/codegen/AGENTS.md` and `src/codegen/beam/AGENTS.md` updated in the same commit as each row
- [ ] Commit on `fix/beam`; no push, no merge

## Blast radius

| What | Count | How measured |
|---|---|---|
| `snapshots/codegen/beam/` | **314** | `find … -name '*.snap.md' \| wc -l` |
| with a `RUN LOG` block | 305 | parsed out of each file |
| with a **non-empty** log | 151 | the same |
| whose log text changes under step 2 (arrays, tuples, floats, records, Erlang binaries) | **17** | matched for `[…]`, `#(`/`{…}`, `\d+\.\d+`, `<<` |
| whose emitted `.S` changes when the print prelude changes | **163** | `grep -rl "__bp_print"` |
| carrying `'__bp_erl_eval'` (step 1) | **11** files / **22** occurrences | `grep -rl` / `grep -ro` |
| `make_fun3` sites (step 5) | **12** | `grep -c make_fun3 src/codegen/beam_asm.zig` |

Step 1 moves the `.S` text of 11 snapshots and **no** RUN LOG. Step 2 moves 17 RUN LOGs and up to 163
`.S` texts. Steps 3 and 4 move whatever fixture they newly lower — measure per row.

**This front does not move any other directory.** If a change here moves
`snapshots/codegen/erlang/`, the shared template walker of step 1 crossed into
[`02-erlang`](../02-erlang/README.md) — stop and report.

## Notes

- **beam's run-time abort on an unbound name is the backstop, not a fix.** Keep
  `{unresolved_identifier, N}`; the check is the checker's and landed (C12, `ae146e0`).
- **`scripts/beam_export_audit.sh` is this front's gate, not a formality.** It is the only mechanical
  proof that every emitted `.S` assembles, and beam has no language-suite line to fall back on.

## Rows for `fronts.md`

**Ownership row**

| Front | Source it owns | Snapshots it owns | Spec rows |
|---|---|---|---|
| **03** [`beam`](./03-beam/README.md) | `modules/compiler-core/src/codegen/beam_asm.zig` · `modules/compiler-core/src/codegen/beam/**` · `scripts/beam_export_audit.sh` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/beam/**` (314) | steps 1–5; **0** `expected-failures.txt` lines — the language suite does not run beam |

**Conflict notes**

1. **03 × 02 × 04 × 05 — `yes`.** File-disjoint and snapshot-disjoint. One shared *idea*: step 1
   reuses the erlang template rendering. If that means a shared walker in a new file, the file is
   03's and 02 reads it — say which in the landing note, and verify `snapshots/codegen/erlang/` is
   byte-identical afterwards.
2. **03 × 01 — `yes`.** No shared file. Per-row dependency in [Dependencies](#dependencies); BR5 and
   the formatter's F0/F1/F5 depend on nothing. When an 01 strictness step kills a fixture, its beam
   snapshot goes with it — 01 reports rather than deletes.
3. **03 × [`13-module-identity`](../13-module-identity/README.md) — `no`.** 13 owns `beam_asm.zig` whole in its second and third halves
   and re-records 188 + 130 snapshots across the erlang and beam directories.
   **Recommended order: BR5 first and alone, then 13, then steps 2–5** — policy 3 must not split an
   emitter that still carries a run-time template evaluator, and BR5 re-records 11 `.S` texts and no
   RUN LOG, so it is the cheapest row to pull forward. The three options and their measured costs
   are in [Ordering against `13-module-identity`](#ordering-against-13-module-identity); the
   milestone question is [`../decisions-pending.md` #4](../decisions-pending.md). F2/F3/F4 land
   with 13.
4. **03 × [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — `no`.** 14 runs comptime evaluation on beam and reads
   `beam_asm.zig` and `beam/**` to do it. Sequence them, or 14 takes a carve-out named in its README.
   Both fronts also touch `beam_export_audit.sh`.
5. **03 × [`07-review-backlog`](../07-review-backlog/README.md) — `no`.** It owns `src/codegen/tests/**`; this front's fixtures
   and `KNOWN` notes are a carve-out.
6. **03 × [`10-cli-residuals`](../10-cli-residuals/README.md) — `yes`**, with a note: `botopink run --target beam` writes the
   `.S` and stops, which is why this front verifies by hand. If the CLI grows an `erlc +from_asm`
   step, the language suite could run beam and this front would gain listed lines — a CLI row worth
   scheduling, not a blocker.
7. **03 × [`08-hygiene`](../08-hygiene/README.md) — `no`.** Its comment sweep over `beam_asm.zig` lands after this front.
8. **03 × [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md) — `yes`.** No library cell runs on beam.
9. **03 × [`12-language-tests`](../12-language-tests/README.md) — `yes`**, delete-only on `expected-failures.txt` — and
   the front worth asking to add beam cells once the CLI can run them.

**Front-table row**

| [`03-beam/`](./03-beam/README.md) | high | BR5 — `@External.Erlang` templates compiled at build time instead of `'__bp_erl_eval'` — plus the formatter beam never got (decision 1a **and** §7), decision 8 at run time, and a method on a type from another module, which is `{badfun, …}` today |

---

## Handed over by `15-language-surface` (2026-09-18, `109f6c9`)

**One lowering: the index expression.** [Decision 30](../decisions-taken.md) landed in the parser as a
builtin call — `ast.index_builtin_name` (`"[]"`) over `(receiver, index)`, contract at
`ast.zig:1681-1703` — so `xs[0]`, `d["k"]`, `s[0]` and the slice `xs[0..2]` (the same node with a
`range` second argument) all arrive as one shape. Until this backend lowers it, the form falls into the
unrecognised-builtin path — the same place `x is T` sat before it was lowered.

**`a ?? b` asks nothing of this backend.** It desugars in the parser into the optional-binding `if`
the language already has (`ast.nullish_binding_name`), which this backend already emits.

---

## Handed over by `14-comptime-on-beam` (2026-09-18, `bef762b`)

**Step 3 of front 14 waits on this front, and its blocker is measurable here today.** The untyped
comptime mode on beam cannot be written while the **typed** backend fails the same case:
`"a b".split(" ").map({ x -> x.toUpper() })` with `--target beam` assembles and then dies at run time
with `{unresolved_method, toUpper, 1}`, while straight-line typed code (`.trim()`, `.slice()`,
`.split()`, `.join()`, a record field, an `if`) runs. In a comptime body **every** receiver is untyped,
so that path is the whole feature. `beam_asm.zig` is 6 401 lines with **0** occurrences of
`ComptimeModule`, `'__bp_len'`, `'__bp_json'` or `'__bp_prim_'`, and ~80 type-directed sites would have
to grow an untyped arm.

**And the prize shrank**, measured after 14's step 2 landed: step 3 would save ≈ 39 ms of a 645 ms
erika-linq build (≈ 6 %), because the erl-side cost is now paid once per build instead of 18 times.

---

## Handed over by `12-language-tests` (2026-09-18) — beam is wrong *quietly*

**The index expression is dropped and the program exits 0.** The other three targets fail loudly —
`SyntaxError` on commonJS, `'[]'/2 undefined` on erlang, wasm refuses to validate — while beam prints
the whole array for `xs[0]`, and `ok` for `xs[0..2].length` and `rows[1][0]`. A silent wrong answer is
worse than a crash, and it is the reason the suite now runs `--target beam` at all (14 passed / 20
expected / 0 failed).

Also measured while writing the range cells: `case 9 { 1...9 { 1 } _ { 0 } }` prints `undefined` on
commonJS, `0` on erlang and **`256` — a heap address — on wasm**. Three backends, three wrong answers;
the cells are owed once `01 step 4` lands.

The suite records the index expression's owner cells as `03 handover 15`, because decision 30 says
"one lowering in each of fronts 02–05" and this front has no numbered step for it. Worth giving it a
number when the step is planned.

