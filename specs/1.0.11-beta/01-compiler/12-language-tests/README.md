# Front 12 — language tests

**Priority:** medium — the only suite that asserts what a botopink **program does** on more than
one backend; in this milestone it is also where every area front's new cell lives, and the file
that says which reds are tolerated must say none.
**Depends on:** `00-gate` (EF-1, EF-2 — beam joins `--target all` only when no beam line is left;
FC-4 — `tests/language` reformatted by the gate and in `TREES`) · `25-gate-perf` (owns `run.sh`;
step 1's one-line flip at `run.sh:155` is a named carve-out) · the area fronts, whose cells land in
their commits under the owner rule below.
**Owns:** `repository/botopink-lang/tests/language/**` — the cells, their `.out` / `.expect` /
`.exit` / `.targets` files, `expected-failures.txt` (delete-only, shared with every front), `AGENTS.md` ·
by carve-out from 25: the `all)` line of `tests/language/run.sh` (`:155`)
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**`, the rest of `run.sh` (25). A cell that fails is recorded as an expected
failure naming the front that owns the fix, **never** fixed here.
**Does not touch until 00-gate lands:** every existing cell's text (FC-4's reformat lands first; a
cell added by this front before it is formatted at birth).

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| beam in `--target all`; the `--cold` no-new-tool check | `12-language-tests/README.md` | § Step 3, last box · § Notes |
| the stale decision-29 row | `12-language-tests/README.md` · `tests/language/AGENTS.md:1319` | § Open rows, second bullet |
| the `1..9` open row | `12-language-tests/README.md` | § Open rows, first bullet — **stale**: `test/case_arms.bp:21` writes `1...9` and passes (`AGENTS.md:241`) |
| C-06 / C-07 bookkeeping | `00/README.md` | § C-06 box 2 (every moved RUN LOG verified), § C-07 box 2 (every §2/§4/§5/§6 cell on beam) |
| the ten cells with no cell today | the audit (`E-compiler-carry-over.md` § Test infra, row 4) | JS-4's beam twin, `Array.unique`, `element/2`, `__Loop`, `indexOf` units, a module-level `@print` in a dependency, a record value called, a redeclared binding, function-typed arms, `throw` in a `case` arm |
| T10 re-measure | `language-gaps.md` | T10 (`try` inside a `for` writing a `var` — no longer reproduces; pin it) |

## The suite today

| Kind | What a cell is | Runs on |
|---|---|---|
| `test/` (64) | `test "…" { assert … }` blocks | commonJS, erlang (`botopink test` refuses beam and wasm) |
| `run/` (370) | a whole program; stdout (and, with a `.exit`, the exit status) is the assertion | commonJS, erlang, wasm; beam with `--target beam` |
| `reject/` (346) | must not compile; `.expect` names the code and the location | once (`check` is target-independent) |
| `modules/` (58) | a whole project with its own `botopink.json`, a local dependency included | commonJS, erlang, wasm; beam with `--target beam` |

Counts by `ls | wc -l` at the open. `run.sh --target all` is commonJS, erlang and wasm
(`run.sh:155`); `--target beam` is 382 / 2 / 0. `expected-failures.txt` has three live lines (two
beam, one wasm — 00-gate's), each naming its 1.0.10 sub-front; the owner-row spellings the file
documents (`01 step 4`, `C-02`) resolve against the 1.0.10 record, which is frozen.

## Steps

### Step 1 — beam joins `--target all`

After EF-1/EF-2: `all) targets=(commonJS erlang wasm beam)` (`run.sh:155`, 25's carve-out); every
`run/` and `modules/` cell re-run on beam; the `--cold` check: `erlc` is already a gate dependency
(`beam_export_audit.sh`), so `scripts/gate.sh --cold` on a machine with nothing beyond what it needed
before stays green — verified by running, not by reading.

**Acceptance:**
- [ ] `run.sh --target all` runs four targets; `zig build test-language` reads `0 failed` with no beam line
- [ ] `--cold` verified on a runner with the pre-existing tool set; `tests/language/AGENTS.md`'s target table updated
- [ ] 03's note "a front that adds a `run/` cell runs `--target beam` once by hand" deleted from the READMEs that carry it

### Step 2 — the owner rule for the new cells

Every cell an area front adds in this milestone lands **in that front's commit** (one file per
cell, no shared edit — the carve-out every front README names) and is **proved able to fail** by
running it on the parent binary before the fix. The list, so this front can audit at the close
that each exists and names no `expected-failures.txt` line:

| Cell | Front | Row |
|---|---|---|
| `run/ctor_pattern_in_val_binding` | 03 step 1 | JS-4's beam twin |
| `run/array_unique` | 02 step 4 (05 step 1 for wasm) | C-35 |
| `run/module_fn_named_like_bif` | 02 step 1 | T13 |
| `run/host_template_binding_inside_while` | 02 step 2 | T14 |
| `run/string_index_of_codepoints` | 02 step 6 | T18 |
| `modules/dependency_module_level_print` | 02 step 3 | C-34 |
| `reject/call_of_record_value` | 01 step 4 | row 32 |
| `reject/binding_redeclared_in_body` (or `run/binding_rebound_in_body`) | 01 step 5 | row 34 |
| `run/case_function_typed_arms` | 01 step 2 | row 31 |
| `run/throw_in_case_arm_result` | 01 step 6 | row 29 |
| `run/try_in_for_writing_var` | this front | T10 — no longer reproduces; the cell pins it (`var i = 0; for (xs) { x -> try f(x); i = i + 1; }` prints the count on four targets) |

**Acceptance:**
- [ ] every cell above exists at the close, passes on every target it declares, and was red on the parent binary (the front's commit message says so)
- [ ] `run/try_in_for_writing_var` added by this front, green on four targets

### Step 3 — `AGENTS.md` matches the suite

The decision-29 row (`AGENTS.md:1319`, "a block-shaped statement not last in its block") leaves the
"shapes that do not parse" list — since C-13 the `;` is optional and the program runs; the `1..9`
bullet of the 1.0.10 README is not carried (the cell writes `1...9`). The coverage table's counts
re-derived; the classification line quotes the runner's tally.

**Acceptance:**
- [ ] `AGENTS.md` names no shape that parses; the counts equal `ls | wc -l` per directory with the command
- [ ] the owner-row rule names this milestone's fronts (`specs/1.0.11-beta/01-compiler/<front>/`) beside the frozen 1.0.10 spellings

### Step 4 — C-06 / C-07 bookkeeping

Every RUN LOG C-06 moved was verified by running (02's and 03's records say so — this front
confirms the boxes and closes them); every cell naming §2, §4, §5, §6 has a beam result under step
1's `all`.

**Acceptance:**
- [ ] the two 1.0.10 boxes closed with the run that proves them (`run.sh --target all` after step 1)

## Gate

- [ ] `zig build test-language` green on every target the suite declares, from the meta worktree
- [ ] `tests/language/AGENTS.md` updated in the same commit as any cell or owner-row change
- [ ] Commit on `fix/12-language-tests`; no push, no merge

## Notes

- **Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays
  as written and is listed in `expected-failures.txt` — and in this milestone the list must be
  empty at the close: a cell that cannot pass names the front that owes it, and that front's step
  is the milestone's.
- `test/case_arrow_arms.bp` is the transition guard beside `test/case_arms.bp`: both arm forms
  parse, and the suite pins both; C-14's answer (09 item 2) is how a removal would be noticed.
- A cell that needs a git dependency stays out of scope — `zig build test-libs`' job; this suite
  must not need the network.
