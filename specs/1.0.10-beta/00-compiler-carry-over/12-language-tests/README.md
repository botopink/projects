# Front 12 — language tests

**State:** closed (C-16) — steps 1, 4 (items 1–4) and 5 delivered; step 2 is continuous, step 3's
last box waits on beam joining `--target all`, and step 4's item 5 is owed.
**Priority:** high — this is the only suite that asserts what a botopink **program does**, on more
than one backend, rather than what the compiler emits
**Owns:** `repository/botopink-lang/tests/language/**` — the cells, their `.out`/`.expect`/`.exit`
files, `expected-failures.txt`, `run.sh` and `AGENTS.md`
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**`. A cell that fails is recorded as an expected failure naming the front that
owns the fix, **never** fixed here.

---

## The suite today

| Kind | What a cell is | Runs on |
|---|---|---|
| `test/` | `test "…" { assert … }` blocks | commonJS, erlang (`botopink test` refuses beam and wasm) |
| `run/` | a whole program; stdout (and, with a `.exit`, the exit status) is the assertion | commonJS, erlang, wasm; beam with `--target beam` |
| `reject/` | must not compile; `.expect` names the code and the location | once (`check` is target-independent) |
| `modules/` | a whole project with its own `botopink.json`, a local dependency included | commonJS, erlang, wasm; beam with `--target beam` |

- `tests/language/run.sh [--target commonJS|erlang|wasm|beam|all]` prints the run's own tally; the
  header carries no hand-kept number. `all` is commonJS, erlang and wasm; **beam** runs
  `botopink run --target beam`, then `erlc +from_asm`, then `erl` (`exec_run`), and is not in `all`
  yet — the flip is one line in `run.sh`, scheduled as 13's closing step.
- `expected-failures.txt` is shared and **delete-only**: every line names an owner row — a 1.0.5-beta
  step spelling (`01 step 4`, `02 step 4`, `04 step 2`, …), which resolves against the carried copies
  under `00-compiler-carry-over/<front>/README.md` with the same number, or a carry-over item (`C-02`,
  `C-03`, `C-18`); `AGENTS.md` documents both spellings. A line whose cell passes fails the runner
  ("now passes: delete its line"). A cell whose owner is nobody is reported to the maintainer, not
  listed against an invented row.
- `AGENTS.md`'s "what cannot be tested from botopink at all" list keeps only `@typeInfo` /
  `@makeRecord` / `partial` / `omit` / `pick`, with the reason.

## Steps

### Step 1 — every owner row names a live front — delivered

- [x] Every line's owner cell names a 1.0.5-beta front and, where the front has numbered rows, one of
      them; the 1.0.5 spellings resolve against the carried copies under
      `00-compiler-carry-over/<front>/`, same step numbers, and `AGENTS.md` says so
- [x] The erlang / commonJS / wasm lines once owned by 1.0.4's `01 step 6` are split across
      [`02-erlang`](../02-erlang/README.md), [`04-js`](../04-js/README.md),
      [`05-wasm`](../05-wasm/README.md) — by the target in column 1, not by guess
- [x] `reject/external_lowercase_target.bp` names a real row, or the cell is deleted with the decision
      that deleted it written in `AGENTS.md` — neither: the cell passes and its line is gone
- [x] `zig build test-language` reads `0 failed` — repointing an owner changes no result
- [x] `AGENTS.md`'s owner-row rule names the 1.0.5-beta fronts and where their steps now live

### Step 2 — re-classify after each landing

Run the suite after every front lands and re-derive each remaining line's **reason**, not only its
owner. A line whose failure has changed shape moves to the front that now owns it; a line that passes
is deleted by the landing front.

- [ ] After each landing: the suite run, `0 failed`, and every surviving line's reason re-derived from
      the actual output, quoted in the line — **continuous**; the beam column included, run by hand
      with `--target beam`
- [x] No line names a front that has closed — `13 step …` is gone from the file, and the 1.0.5 step
      spellings resolve against their carried copies in this milestone's tree
- [x] The lines that survive [`01-checker`](../01-checker/README.md) with a run-time reason name
      [`13-module-identity`](../13-module-identity/README.md) — none survive: no line names 13, and no
      `type_identity_*` cell carries a line on any target

### Step 3 — beam in the suite

beam is an opt-in target: `run.sh --target beam` assembles and runs every `run/` and `modules/` cell;
`test/` cells stay out until `botopink test` accepts the target (a CLI row).

- [x] `tests/language/AGENTS.md`'s target table states the measured behaviour of all four targets,
      with the commands
- [x] every `run/` and `modules/` cell has a beam result, each pass or expected failure, and the beam
      expected failures name [`03-beam`](../03-beam/README.md)
- [ ] `erlc` is already a gate dependency (`beam_export_audit.sh`) — no new tool in the gate, verified
      by running `scripts/gate.sh --cold` on a machine without anything installed beyond what it
      needed before — **open**, and moot until beam joins `--target all`

### Step 4 — the cells that were missing

1. **Run-time type identity** — `type_identity_*` cells: two types with identical fields comparing
   unequal; `is` on a named type through a union and through `unknown`; `@print` of a record and of
   a variant naming the type (§7); a `case` over a union of two named types. Delivered.
2. **A local dependency** — `modules/local_dependency`: `deps/shapesdsl/` with `pub default mod
   shapesdsl;`, a `pub default fn … -> @ExprCustom<T>` returning `e.custom(ast, code)`, and
   `shapes.d.bp` shipped through `files`; the consumer expands `shapesdsl "4, 5"` at compile time. No
   network. Delivered.
3. **`@panic` / `@todo`** — `run/panic_aborts.bp`, `run/todo_aborts.bp`, each with `.exit` =
   `nonzero`. Delivered.
4. **"no external target for the active backend"** — `run/external_erlang_only.bp`, refused on
   commonJS and wasm (`.commonJS.expect`, `.wasm.expect`), runs on erlang and beam. Delivered.
5. **DSL hygiene** ([decision 112](../../decisions-taken.md#112-dsl-hygiene-each-name-resolves-in-the-scope-of-whoever-wrote-it))
   — **owed.** Three `run/` cells over one local library `shapesdsl` whose template writes
   `e.build("double(" + e.text() + ")")` with `double` **private** to the library:
   `shapesdsl "area(4, 5)"` with `{area}` imported; the same through `{area as surface}` and
   `shapesdsl "surface(4, 5)"`; and a consumer that declares its own
   `fn double(x: i32) -> i32 { return x + 1; }`. Each prints **40** (today: unbound, unbound, 21). No
   `reject/` cell. Until [`01-checker`](../01-checker/README.md) step 14 lands, the three are
   expected failures against it.

Also delivered: a cell per decision 63–66 of 1.0.5-beta — 63 `run/index_*`, 64
`run/std_erlang_node`, 66 the three `modules/*` cells formatted; 65 is a sentence, since the formatter
writes text and the suite runs programs (`AGENTS.md` § Notes).

**Acceptance:**
- [x] `zig build test-language` green, with the new cells, on every target each declares (items 1–4;
      all four pass on beam as well)
- [x] Every added `expected-failures.txt` line names an existing 1.0.5-beta row — or a carry-over item
      (`C-02`, `C-03`, `C-18`), the second spelling `AGENTS.md` documents
- [x] Anything with no owner is reported here and to the maintainer, not listed against an invented row
- [x] `AGENTS.md`'s "what cannot be tested from botopink at all" list loses the entries step 4 covers,
      and each remaining entry keeps its reason

### Step 5 — `AGENTS.md` matches the suite — delivered

- [x] The coverage table's cell counts equal what is on disk, per directory, with the command that
      counted them
- [x] The classification line quotes the runner's own tally line
- [x] The "shapes that do not parse" list is re-derived: the entries that parse now (`Pattern { body }`
      arms, §5.3b, a module-level `var`) are struck or moved

## Delivered (the C-16 cells)

C-16's step 4.2–4.4 cells are items 2–4 of [step 4](#step-4--the-cells-that-were-missing); the tally
is `run.sh`'s own; decisions 63–66 have their cells. The beam column, run by hand, found cells other
fronts had measured on three targets only — the `modules/*_name_collision` cells,
`run/labelled_arguments.bp`, `run/effect_method.bp` — handed to [`03-beam`](../03-beam/README.md),
which closed them.

## Handed over by 15-language-surface steps 3 and 4b

Written by 15 itself (12 had closed), each run on every target it declares:

- **Eight `reject/` cells, one per decided-against form** — each pins the named code at the site
  every spelling reaches: `reject/ternary_absent` (`ternary-absent`),
  `reject/bitwise_operator_absent` (`bitwise-operator-absent`), `reject/char_literal_absent`
  (`char-literal-absent`), `reject/nested_fn_decl` (`nested-fn-decl`),
  `reject/list_spread_not_last` (`list-spread-not-last`), `reject/list_spread_dot_dot_dot`
  (`list-spread-dot-dot-dot`), `reject/implement_clause_for` (`implement-clause-for`),
  `reject/tuple_literal_label` (`tuple-literal-label`). `tests/language/AGENTS.md`'s list of
  deliberately absent forms carries them.
- **`run/decorator_negative_argument`** — `#[mark(-20)]` over `type Account(id: i32)`; the decorator
  receives the number `-20`, one annotation argument; `.out` = `5`.
- **`run/loop_one_line_body`** — a trailing lambda and a `for (xs) { x -> … }` body whose one
  statement takes no `;`; `.out` = `52`.

- [x] the eight `reject/` cells — each carries a header comment, so its `.expect` line 2 is the
      location shifted by the header's lines
- [x] `run/decorator_negative_argument` and `run/loop_one_line_body` — pass on all four targets
      (beam included)
- [x] listed in `tests/language/AGENTS.md`; no `expected-failures.txt` line

## Open rows

- **`test/case_arms.bp`'s `1..9` arm** — the cell writes `1..9`; decision 53 of 1.0.5-beta made
  `A...B` the inclusive range pattern and `..` the exclusive slice. `01-checker`'s README says the cell
  is this front's to rewrite; its `expected-failures.txt` line (owner `01 step 4`) says the cell is
  right as written. One of the two readings is the owner's to settle.

- **`AGENTS.md`'s decision-29 row is stale.** "Shapes that do not parse" still lists a block-shaped
  statement not last in its block (`if (1 > 0) { … }` then `@print("b");`); since C-13 the `;` after a
  braced block is optional (decisions 29, 132) and the program runs. The row leaves the list with the
  next `AGENTS.md` edit.

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree — the pre-commit gate ran green on
      every commit; `--cold` not run separately
- [x] `zig build test-language` green on every target the suite declares, and on `--target beam`
- [x] `tests/language/AGENTS.md` updated in the same commit as any cell or owner-row change
- [x] Commit on a branch; no push, no merge — `front/12-language-tests`

## Notes

- **Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
  written and is listed in `expected-failures.txt`. Never rewrite a cell to match current behaviour —
  the rule is in `AGENTS.md` and it is what makes the file an inventory of open promises rather than a
  log.
- `test/case_arrow_arms.bp` is a transition guard beside `test/case_arms.bp`: both arm forms parse,
  and the suite pins both; the cell is how a removal of the arrow form would be noticed.
- A cell that needs a git dependency stays out of scope — that is `zig build test-libs`' job, and this
  suite must not need the network. `modules/local_dependency` is a *local* second project.
- A front that adds a `run/` or `modules/` cell runs `--target beam` once by hand until beam is in
  `all`.
