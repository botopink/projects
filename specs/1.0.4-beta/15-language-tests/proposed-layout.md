# Proposed layout — the suite after the gap analysis

What `tests/language/` becomes once the cells of [`example-programs.md`](./example-programs.md) land.
Three changes to the shape, then the cell list with owners.

## What stays

The three kinds, the per-file scratch project, `expected-failures.txt`'s five outcome rules and the
`run.sh` contract are right and are not touched. So is the rule that a test describes decision 8 and
is listed, never rewritten, when the compiler lags.

## Change 1 — areas become directories, not filename prefixes

Today every cell is `test/<area>_<group>.bp` and the suite has one area per decision-8 section. With
the language's whole surface in scope the flat list stops scanning: 16 `case` files and 5 `loop`
files already sit beside each other with nothing but a prefix separating them.

```
tests/language/
  botopink.json
  run.sh
  expected-failures.txt
  AGENTS.md

  test/                       assert-based cells, run by `botopink test --target <t> --json`
    case/        case_arms.bp  case_variants.bp  case_tuples.bp  case_guards.bp
                 case_exhaustive.bp  case_unknown.bp  case_sections.bp
    tuple/       tuple_construct.bp  tuple_labels.bp  tuple_nested.bp
                 tuple_equality.bp  tuple_zip_destructure.bp  tuple_fn_field.bp
    loop/        loop_collection.bp  loop_range.bp  loop_generator.bp
                 loop_condition.bp  loop_break.bp  loop_break_value.bp
    types/       generic_behavior.bp  generic_inference.bp  optional.bp  union_unknown.bp
    effects/     effect_result.bp  effect_future.bp  effect_iterator.bp  effect_context.bp
    comptime/    comptime_template.bp  comptime_value.bp  decorator_emit.bp  decorator_reflect.bp
    host/        external_host.bp  external_markers.bp
    core/        closure_capture.bp  fn_defaults.bp  recursion.bp  string_array.bp
    smoke.bp

  run/                        whole programs, stdout compared byte for byte
    print/       print_formatter.bp(+.out)  display_print.bp(+.out)  print_nested.bp(+.out)
    case/        case_values.bp(+.out)
    smoke.bp(+.out)

  reject/                     programs that must not compile
    case/        …the nine existing case cells…
    tuple/       tuple_label_on_unlabeled.bp  tuple_unknown_label.bp
    loop/        loop_while.bp  loop_condition_parameter.bp
    types/       generic_missing_argument.bp  self_without_argument.bp
    effects/     result_without_wrapper.bp  wrapper_without_annotation.bp
                 throw_outside_result.bp  two_effect_markers.bp
    host/        external_lowercase_target.bp  external_no_target_for_backend.bp
    smoke.bp

  modules/                    NEW kind — a whole project, not a file
    two_modules/     botopink.json  src/main.bp  src/geometry.bp  expected.out
    mod_tree/        botopink.json  src/main.bp  src/shapes/mod.bp  src/shapes/circle.bp  expected.out
    std_import/      botopink.json  src/main.bp  expected.out
    default_mod/     botopink.json  src/main.bp  src/query.bp  expected.out

  crash/                      NEW kind — one rule: the compiler must not die by signal
    val_assert_binding.bp
```

`run.sh` keeps collecting `test/**/*.bp`, `run/**/*.bp`, `reject/**/*.bp` — one `find` instead of one
`ls` — and the key in `expected-failures.txt` stays the path relative to `tests/language/`, so every
existing line survives the move with its directory inserted.

## Change 2 — a `modules/` kind, for cells the one-file shape cannot express

Gap G-8: `pub mod`, `import … from "<module>"`, `pub default mod`, `from "std"` and `.d.bp` sidecars
are not merely unpinned, they are unpinnable — `run.sh` copies a single file into `src/main.bp`. Six
inventory rows (M1–M6) sit behind that, and the one cell already verified by hand
(`modules/two_modules`) finds a real erlang defect.

A `modules/<name>/` cell is a **directory that is already a project**: its own `botopink.json`, its
own `src/`, and an `expected.out`. The runner copies the directory whole, runs
`botopink run --target <t>`, and compares stdout with `expected.out` — the `run/` rules, over a tree
instead of a file. Nothing else changes: same expected-failure keys, same five outcome rules.

Deliberately out of scope: a cell with a **git dependency**. That is `zig build test-libs`' job and
would make the language suite need the network.

## Change 3 — a `crash/` kind, with one rule

Gap G-1: `val assert Ok(n) = parse(7);` aborts the compiler (exit 134, `General protection
exception`). `run.sh` records that as "does not compile", which is true and misleading — the same
string it prints for a parse error.

A `crash/<name>.bp` cell has one rule: **`botopink check` must terminate normally.** Exit 0 and
exit 1 both pass; termination by signal (exit ≥ 128, or a `zig` panic on stderr) fails. No `.expect`,
no target loop. The directory is expected to be empty; a cell in it is a standing report that the
compiler dies on a documented construct, and it is deleted — not re-listed — when that is fixed.

Two lines in `run.sh` and one column in the summary. It is the cheapest way to make "the language
tests are green" mean "the compiler did not crash on anything we know crashes it".

## Cell list and owners

New cells only; the 34 existing files move into their area directory unchanged.

| Cell | Kind | Status today | Expected-failure owner |
|---|---|---|---|
| `test/effects/effect_result.bp` | test | green both | — |
| `test/effects/effect_iterator.bp` | test | commonJS green, erlang fails at run time | erlang → **01 step 6** |
| `test/effects/effect_future.bp` | test | **unwritten** — `#[@future]` + `await`; `libs/std/src/http.bp` is the model | to be classified when written |
| `test/effects/effect_context.bp` | test | **unwritten** — `@Context<H, T>` + `use`; `jhonstart/src/hooks.bp` is the model | to be classified when written |
| `test/comptime/comptime_template.bp` | test | green both | — |
| `test/comptime/comptime_value.bp` | test | folded into the cell above; split if it grows | — |
| `test/comptime/decorator_emit.bp` | test | green both | — |
| `test/comptime/decorator_reflect.bp` | test | **unwritten** — `decl.fields` / `decl.methods` / `decl.annotations`; `rakun/src/decorators.bp` is the model | to be classified when written |
| `test/host/external_host.bp` | test | green both | — |
| `test/host/external_markers.bp` | test | **unwritten** — `$args`, `self` in the numbering (decision 5 / §8) | to be classified when written |
| `test/core/closure_capture.bp` | test | green both | — |
| `test/core/string_array.bp` | test | commonJS green, erlang does not compile (`toUpperCase`) | erlang → **01 step 6** |
| `test/core/fn_defaults.bp` | test | red both | **06 N1** |
| `test/core/recursion.bp` | test | green both (verified: `fact`, mutual `isEven`/`isOdd`) | — |
| `test/types/generic_behavior.bp` | test | commonJS green, erlang fails `default fn` | erlang → **01 step 6** |
| `test/types/optional.bp` | test | **unwritten** — `?T`, `?.`, `if (x) { n -> … }`; note `Option<T>` is rejected by design | to be classified when written |
| `test/tuple/tuple_fn_field.bp` | test | red both | **06 N24** |
| `test/loop/loop_break_value.bp` | test | red both, differently | commonJS → **06 N12**; erlang → **01 step 6** |
| `test/case/case_sections.bp` | test | red both (does not parse) | **06 N22**, **06 N28** |
| `run/print/print_formatter.bp` | run | red both, differently | **01 step 6** (both) |
| `run/print/display_print.bp` | run | red both | **01 step 6** (both) |
| `run/print/print_nested.bp` | run | **unwritten** — §7's nested-string escapes (`"hi"`, `\"`, `\\`, `\n`) | **01 step 6**, expected |
| `reject/types/generic_missing_argument.bp` | reject | accepted today | **06 N18** |
| `reject/types/self_without_argument.bp` | reject | **unwritten** — §1.2 bare `Self` in a generic type | **06 N18**, expected |
| `reject/effects/result_without_wrapper.bp` | reject | correct today | — |
| `reject/effects/throw_outside_result.bp` | reject | correct today | — |
| `reject/effects/wrapper_without_annotation.bp` | reject | wrong diagnostic | **06** |
| `reject/effects/two_effect_markers.bp` | reject | **unwritten** — R5; `parser/tests/effect_rejections.zig` is the model | to be classified when written |
| `reject/host/external_lowercase_target.bp` | reject | accepted today | **06** (fronts.md § unowned items) |
| `reject/host/external_no_target_for_backend.bp` | reject | **unwritten** — `MissingExternalTarget` has no location and no fn name (fronts.md § unowned items) | **06** or **01** |
| `modules/two_modules/` | modules | commonJS green, erlang undefined function | erlang → **01 step 6** |
| `modules/mod_tree/` | modules | **unwritten** — `examples/modules` is the model | to be classified when written |
| `modules/std_import/` | modules | `import { dict } from "std"` — commonJS green, **erlang `function insert/3 undefined`** (verified) | erlang → **01 step 6** |
| `modules/default_mod/` | modules | **unwritten** — `pub default mod` / `pub default fn`; `erika/src/root.bp` is the model | to be classified when written |
| `crash/val_assert_binding.bp` | crash | aborts the compiler | **06** — report before 06 starts |

## What belongs in one cell

Unchanged from the delivered suite, restated because the surface is now much wider:

- **One scenario group per file.** A parse error fails a whole module, so a file is the blast radius.
  Nine `#[@External]` declarations in one file mean one unparseable annotation hides the other eight.
- **A cell names its section.** `test "§9 …"`, `test "§5.4 …"` for decision-8 rules; a plain sentence
  for a capability decision 8 does not legislate (`test "a returned closure keeps its capture"`).
- **A cell asserts behaviour, not emitted text.** Emitted text is the codegen snapshots' job. If the
  only way to state the rule is to read the output, it is a snapshot fixture, not a language cell.
- **A cell that fails is listed with an owner, never trimmed to pass.** A cell that fails *differently
  on each target* gets two lines and may get two owners — `loop_break_value` is the worked example.
- **A cell stays single-file unless it is a `modules/` cell.** Needing a second module is the
  criterion for the new kind, not a convenience.

## Naming

| Kind | Path | Name |
|---|---|---|
| test | `test/<area>/<area>_<group>.bp` | area prefix kept inside the directory, so a failure line reads unambiguously in the runner's flat output |
| run | `run/<area>/<name>.bp` + `<name>.out` | |
| reject | `reject/<area>/<name>.bp` + `<name>.expect` | named for the rule broken, not the construct: `generic_missing_argument`, not `generic_box` |
| modules | `modules/<name>/` | `botopink.json`, `src/**`, `expected.out` |
| crash | `crash/<name>.bp` | named for the construct that kills the compiler |

Areas: `case`, `tuple`, `loop` (decision 8's three sections) plus `types`, `effects`, `comptime`,
`host`, `core`. Eight, closed — a capability that fits none of them is a sign the area list needs a
maintainer decision, not a ninth directory added in passing.

## Gate, amended

The delivered gate plus what the new shape requires:

- [ ] `zig build test-language` green on commonJS and erlang
- [ ] Every `expected-failures.txt` line names an owner row that exists in the specs
- [ ] Every scenario bullet of the README has at least one cell — **checked mechanically**, since
      `break <value>` was listed and absent (G-4)
- [ ] `crash/` fails the run on any termination by signal, and is empty or fully listed
- [ ] `modules/` cells run on both targets and compare `expected.out` byte for byte
- [ ] `AGENTS.md` describes the five kinds, the area directories and the expected-failure rules
- [ ] The four items of the gap analysis's "report to the maintainer" list are reported

## Sequencing

Nothing here needs a compiler change, so all of it can be authored before 06 starts — which is the
point: the green cells (effects, comptime, decorators, externals, closures, recursion) are the
regression net **for** 06 and 07, and they only help if they exist first. The order that keeps each
step independently landable:

1. **The move and the two new kinds** — directories, `run.sh`'s `find`, `modules/` and `crash/`,
   existing lines rewritten with their directory. No new cells. Snapshot-neutral.
2. **The green cells** — the seven files verified passing today. These close nothing and guard
   everything after them.
3. **The red and split cells** — with their `expected-failures.txt` lines and owners.
4. **The unwritten cells** — `effect_future`, `effect_context`, `decorator_reflect`,
   `external_markers`, `optional`, `print_nested`, `two_effect_markers`,
   `external_no_target_for_backend`, and the three remaining `modules/` cells.

Steps 1–3 are `tests/language/**`, `build.zig`'s `test-language` step and `scripts/gate.sh` — all
front 15's own files, no conflict with any open front.
