# Front 12 — language tests

**Priority:** medium — the only suite that asserts what a botopink **program does** on more than
one backend; in this milestone it is also where every area front's new cell lives, and the file
that says which reds are tolerated must say none.
**Depends on:** `00-gate` (EF-1, EF-2 — beam joins `--target all` only when no beam line is left;
FC-4 — `tests/language` reformatted by the gate and in `TREES`) · `25-gate-perf` (owns `run.sh`;
step 1's one-line flip at `run.sh:155` is a named carve-out) · the area fronts, whose cells land in
their commits under the owner rule below.
**Owns:** `repository/botopink-lang/tests/language/**` — the cells, their `.out` / `.expect` /
`.exit` / `.targets` files, `AGENTS.md`, and `run.sh`'s report (the per-target line) · by carve-out
from 25: the `all)` line of `tests/language/run.sh` (landed by 111)
**Does not touch:** any compiler source, `libs/std/**`, `examples/**`, any snapshot directory,
`build.zig`, `scripts/**`, the rest of `run.sh` (25). A cell that fails is red until the front that
owns the fix lands it — **never** fixed here, never tolerated (the suite keeps no list).
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

| Kind | What a cell is | Runs on | `ls … \| wc -l` |
|---|---|---|---|
| `test/` | `test "…" { assert … }` blocks | commonJS, erlang (`botopink test` refuses beam and wasm) | 64 |
| `run/` | a whole program; stdout (and, with a `.exit`, the exit status) is the assertion | commonJS, erlang, wasm, beam | 171 (17 `.targets`, 25 `.<target>.expect`, 2 `.exit`) |
| `reject/` | must not compile; `.expect` names the code and the location | once (`check` is target-independent) | 174 |
| `modules/` | a whole project with its own `botopink.json`, a local dependency included | commonJS, erlang, wasm, beam (the 4 test-kind projects: commonJS, erlang) | 68 (33 `<target>.expect`, 1 `"targets"`) |

`run.sh --target all` is the four targets; `expected-failures.txt` is deleted (111, decision 154).
`zig build test-language` at this front's tip:

```
narrowings: 30 exclusions audited — each stands on a host binding the target does not have
by target: commonJS 449/449 · erlang 452/452 · wasm 217/217 · beam 232/232 · * 174/174
language tests: 1524 passed, 0 failed
```

## Steps

### Step 1 — beam joins `--target all`

After EF-1/EF-2: `all) targets=(commonJS erlang wasm beam)` (`run.sh:155`, 25's carve-out); every
`run/` and `modules/` cell re-run on beam; the `--cold` check: `erlc` is already a gate dependency
(`beam_export_audit.sh`), so `scripts/gate.sh --cold` on a machine with nothing beyond what it needed
before stays green — verified by running, not by reading.

**Acceptance:**
- [x] `run.sh --target all` runs four targets; `zig build test-language` reads `0 failed` with no beam line — `all) targets=(commonJS erlang wasm beam)` (111); `beam 232/232`, `1524 passed, 0 failed`
- [ ] `--cold` verified on a runner with the pre-existing tool set; `tests/language/AGENTS.md`'s target table updated — the suite's half holds: `env -i HOME=… LANG=C.UTF-8 PATH=/usr/bin:/bin:<wasmtime>` runs the four targets green (`1524 passed, 0 failed`; node, erl, erlc, wasmtime — no zig, nothing new), and § The targets says so. Open: `scripts/gate.sh --cold` itself is the landing run's, not this front's; and with no `LANG` (or `LANG=C`) `run/string_split_empty_separator` is red on erlang and beam (`erl` writes `é` as latin-1 `0xE9`) — a backend row, § Open questions
- [x] 03's note "a front that adds a `run/` cell runs `--target beam` once by hand" deleted from the READMEs that carry it — no README carries it word for word; the two that still said beam is outside `--target all` (`03-beam` § Current state and § Does not touch, `01-compiler/README.md` § Not handed) say what holds

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
- [ ] every cell above exists at the close, passes on every target it declares, and was red on the parent binary (the front's commit message says so) — the rule is `tests/language/AGENTS.md` § Who adds a cell; at this front's tip none of the ten area-front cells exists yet (audited by path)
- [x] `run/try_in_for_writing_var` added by this front, green on four targets — a pin: `4 passed, 0 failed` on the parent binary and at the tip (count `3`/`0`, a `throw` → `99`, and the same through a `val v = try …` sum)

### Step 3 — `AGENTS.md` matches the suite

The decision-29 row (`AGENTS.md:1319`, "a block-shaped statement not last in its block") leaves the
"shapes that do not parse" list — since C-13 the `;` is optional and the program runs; the `1..9`
bullet of the 1.0.10 README is not carried (the cell writes `1...9`). The coverage table's counts
re-derived; the classification line quotes the runner's tally.

**Acceptance:**
- [x] `AGENTS.md` names no shape that parses; the counts equal `ls | wc -l` per directory with the command — every row re-measured (`1..9` is `pattern-range-exclusive` at the `..`, now `reject/pattern_range_exclusive`; `42.toString()` prints `42` on four, now `run/method_on_number_literal`); 64 / 171 / 174 / 68 with the commands in § Status
- [x] the owner-row rule names this milestone's fronts (`specs/1.0.11-beta/01-compiler/<front>/`) beside the frozen 1.0.10 spellings — § Who adds a cell

### Step 4 — C-06 / C-07 bookkeeping

Every RUN LOG C-06 moved was verified by running (02's and 03's records say so — this front
confirms the boxes and closes them); every cell naming §2, §4, §5, §6 has a beam result under step
1's `all`.

**Acceptance:**
- [ ] the two 1.0.10 boxes closed with the run that proves them (`run.sh --target all` after step 1) — the suite's halves hold: C-06's six wasm RUN LOGs were compared by running (C-16's record) and `run/case_range_value` passes on four; C-07's 18 `run/` cells naming §2/§4/§5/§6 are in beam's `232/232` (none narrowed, none refused). Open: C-06's stale `KNOWN` note (`src/codegen/tests/control_flow.zig:528-533` says `[20]`, the RUN LOG reads `20`) is 02's; C-07's 21 `test/` cells naming those sections cannot reach beam (`botopink test` refuses it) — § Open questions

## Gate

- [x] `zig build test-language` green on every target the suite declares, from the meta worktree — `1524 passed, 0 failed`
- [x] `tests/language/AGENTS.md` updated in the same commit as any cell or owner-row change
- [x] Commit on `front/12-language-tests`; no push, no merge

## Notes

- **Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays
  as written and is red: the suite keeps no list, so a cell that cannot pass lands with the fix of
  the front that owes it, or a decision deletes it.
- `test/case_arrow_arms.bp` is the transition guard beside `test/case_arms.bp`: both arm forms
  parse, and the suite pins both; C-14's answer (09 item 2) is how a removal would be noticed.
- A cell that needs a git dependency stays out of scope — `zig build test-libs`' job; this suite
  must not need the network.

## Open questions

- **`botopink test` on beam, for C-07's `test/` half.** Measured: 21 `test/` cells name §2/§4/§5/§6
  (`case_*`, `tuple_*`, `type_identity*`, `type_suffix`, `contextual_words`, `yield_step_next`) and
  run on commonJS and erlang only. Options: (a) a `run/` twin per cell, its `.out` the assertions'
  answers — 21 new cells here; (b) `botopink test --target beam` (26's CLI, 03's runner) so the cells
  reach beam as written; (c) C-07's box reads "every `run/` and `modules/` cell". Recommendation:
  (b) — one source per scenario, no twin to drift; (c) would narrow a box to fit the tool.
- **A program's stdout depends on the host locale on erlang and beam.** Measured: under `LANG=C`
  `@print` of `é` writes `0xE9`; commonJS and wasm write UTF-8. Options: (a) the emitted program sets
  `standard_io` to `{encoding, unicode}` before `main` (02 / 03); (b) `botopink run` passes it to
  `erl` (26); (c) the runner pins `LANG`. Recommendation: (a) — the built program is what ships;
  (c) hides the defect and is refused (decision 67).
