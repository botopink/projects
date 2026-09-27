# Front 112 — gate-format: every `.bp` tree canonical and in `TREES`, every `.zig` file formatted, the one unformattable fixture exempt by structure

**Priority:** high — stage 3 is green only because 226 red files sit in trees it does not walk,
and 11 `.zig` files are a red the gate meets the day a front stages one.
**Depends on:** none — lands first in group A (a reformat commit is the cheapest thing for every
other front to rebase over). `110` rebases its `asserts.bp` edit; `111` writes its new cells
formatted.
**Owns:** `scripts/format-check.sh` (`TREES`, the header) · `modules/compiler-cli/src/cli/format_cmd.zig`
(the structural exemption, gate-c) · the 11 `zig fmt` files (a `zig fmt` commit, no other change) ·
**reformat-only commits** over `libs/std/src/**` (19 files), `examples/generic-loader-binding/**`,
`examples/stdlib-tour/**` (and `examples/yamlconf` if red — measure), `modules/compiler-cli/tests/**/*.bp`
(5 fixtures), `tests/language/{test,run,modules}/**/*.bp` (199 files) · stage 1 of `scripts/gate.sh`
(`:131-133` — `zig fmt --check` widened from staged files to `modules`) · `scripts/AGENTS.md`
§ format-check.sh.
**Does not touch:** any source change in the trees it reformats (the reformat commit is
`botopink format` output and nothing else — a hand edit in it is a red flag for the reviewer);
`format.zig` and the formatter's rules (`../../01-compiler/16-formatter`'s: decision 132's `;`
refusal lands *after* this front, on the migrated trees); `wat.zig` (110), `run.sh` (111).

---

## Problem

```
$ bash scripts/format-check.sh
  ✓ examples/modules  ✓ libs/std/src/builtins.d.bp  ✓ libs/std/src/builtins_fns.d.bp  ✓ libs/routing  ✓ libs/actions  ✓ libs/validation
$ zig-out/bin/botopink format --check libs/std | grep -c "would reformat"
19
$ zig fmt --check modules | wc -l
11
```

Stage 3 walks six trees (`format-check.sh:41-48`). Outside them, measured at the open with
`botopink format --check <tree>`: `libs/std` 19 files (async, collections, encoding, erlang,
escape, hash, io/clock, io/net, io/random, json, math, path, primitives, querystring, regex,
testing/asserts, testing/mocks, testing/snapshots, url — the header at `:14-16` claims 2);
`examples/generic-loader-binding` 1; `examples/stdlib-tour` 1; `tests/language` 199 would-reformat
(modules/ 37, run/ 105, test/ 57 — the header at `:20-27` says "run/ 9 of 22, test/ 42 of 49",
two milestones stale) + 1 cannot-format (`modules/lexer_error_in_imported_module/src/pattern.bp:3`,
a deliberate bad escape); `modules/compiler-cli/tests` 5 fixtures at two-space indent. `zig fmt
--check modules` (verified at the open): `bpmp/src/commands/{self_uninstall,self_update}.zig`,
`bpmp/src/{registry,storage}.zig`, `compiler-cli/src/cli/test_cmd.zig`,
`compiler-core/src/comptime/{env,infer}.zig`, `compiler-core/src/comptime/runtime/beam/{lower,program}.zig`,
`compiler-core/src/parser/patterns.zig`, `language-server/src/engine.zig` — the gate checks staged
`.zig` only (`gate.sh:131-133`), so each is a latent red.

## Current state

On `front/112-gate-format` (re-measured after each step; see § Gate for how the commits stand):

- `zig fmt --check modules` → exit 0, no file; `gate.sh` stage 1 runs `zig fmt --check modules`
  on every run (the staged check stays as the commit's fast path) and fails on a synthetic
  unformatted file (verified with a probe file, then deleted).
- `format_cmd.zig` has the second structural arm (gate-c option b): a `.bp` under `modules/<cell>/`
  that one of the cell's `<target>.expect` files names on its second line **and** that does not
  lex or parse is left out of the walk; pinned by the test "gate-c: …" with a synthetic cell (named
  and unlexable → exempt; named but parsing → walked; another file named → walked; the same pair
  outside `modules/` → walked; a `deps/<dep>/src` file named from the cell → exempt). No list, no
  flag. `pattern.bp:3` is byte-identical to the open.
- Reformat-only commits, one per tree, each `botopink format` output and nothing else:
  `examples/generic-loader-binding` 1 file, `examples/stdlib-tour` 1 (`examples/yamlconf` and
  `examples/modules` were already canonical; each example prints the same before and after),
  `modules/compiler-cli/tests` 5 fixtures (`test-cli` green before and after),
  `tests/language/modules` 36 of 37 files (below).
- `TREES` = every `examples/*` directory, `libs/std`'s two `.d.bp` files, `libs/routing`,
  `libs/actions`, `libs/validation`, `modules/compiler-cli/tests`; `format-check.sh` → every tree
  ✓; the header no longer names red trees.

**Not landed — `libs/std` (19 files) is not reformatted and stays out of `TREES`.** The reformat
is semantically neutral (the std cell prints 433 passed / 0 failed on commonJS and on erlang
before and after), but `zig build test` quotes std source verbatim in 26 snapshots and every one
moves with the text: the 24 `std_package_*` codegen snapshots
(`modules/compiler-core/snapshots/codegen/{beam,wat}/{beam,commonJS,erlang,wasm}/std_package_{a_dotted_path_and_a_group_bind_leaves_of_std_modules,methods_of_a_type_answered_by_an_imported_module_resolve_in_its_owner,order_enum_module_with_type_export}.snap.md`
— the hunks are the quoted `collections.bp` lines only, the generated code is unchanged) and two
LSP snapshots (`modules/language-server/snapshots/lsp/definition_std_module_member.snap.md`, a
range in the embedded std source moving from line 512 to 517; `completion_array_methods.snap.md`,
whose `detail` quotes `flatMap`'s signature as written in `primitives.bp`, now over four lines).
Those snapshots are not this front's (the wasm columns are `110-gate-wasm`'s; the rest
`../../01-compiler`'s): **needs the 26 snapshots re-recorded in the same commit as
`botopink format libs/std`** — one commit, reformat + the quoted text following it — by whoever
owns them once 110 has landed; `libs/std` then replaces its two `.d.bp` lines in `TREES`.

**Not landed — `tests/language/modules` stays out of `TREES` on one cell.**
`modules/decorator_imported_function_name_conflict`'s four `.expect` files pin the refusal at
`src/main.bp:17:3`; the reformat of `src/main.bp` (an `@emit(…)` argument broken over four lines)
moves that line to 21, so the reformatted cell is red on every target ("right message, wrong
location") — measured on beam: 381 / 2 / 1 with the file reformatted, 382 / 2 / 0 without. The
`.expect` files are the cell's, not this front's (`../../01-compiler/12-language-tests`, FC-4's
owner of the cells): **needs `tests/language/modules/decorator_imported_function_name_conflict/
{beam,commonJS,erlang,wasm}.expect` line 2 → `src/main.bp:21:3`**, then `botopink format` on the
one file, then `tests/language/modules` joins `TREES` (`format --check tests/language/modules`
names exactly that file today; the other 36 are canonical and the lexer-error cell is exempt).

**Not landed — `tests/language/run` and `tests/language/test` (162 files) stay out of `TREES`.**
The reformat of the two trees does not round-trip (measured by `botopink format` on a copy, then
`format --check` on the copy): two printer defects, both in `modules/compiler-core/src/format.zig`
(`../../01-compiler/16-formatter`), not this front's:

- `run/record_update.bp:18` — `val c = Cfg(..base, revalidate: 60);` is printed
  `Cfg(..: base, revalidate: 60)`, which the parser refuses ("this token cannot appear here",
  `:18:19`). The record-constructor spread is printed as a labelled argument named `..`.
- `test/effect_result.bp:16` — `assert (parse(7) catch -1) == 7;` is printed
  `assert (try parse(7) catch -1) == 7;`: the `.tryCatch` arm (`format.zig:725`) always prints
  `try `, and the parser refuses `try` under parentheses (`error[try-await-operand]`). A `catch`
  written without `try` is printed with one — a meaning change, not only a round-trip failure.

Per the rule (a tree the printer cannot round-trip is a formatter defect, never a hand edit), the
160 other files of the two trees are not reformatted either: the two trees join `TREES` in one
reformat commit when 16 fixes both arms (`tests/language/AGENTS.md` § 66 and
`scripts/format-check.sh`'s header say the same).

## Mechanism

`botopink format` is the migrator for a tree the formatter owns (`../../01-compiler/README.md`
FC-4): the 199 `tests/language` files differ from canonical by the `;` after a braced block the
printer no longer writes (C-13) and by decision 65's method-chain and lambda rules (C-12/C-14),
which `libs/std` and the two examples also carry. None of it is a semantic change; each reformat
is verified by the cells it touches staying green before and after.

## Steps

### Step 1 — `zig fmt` the 11 files; stage 1 checks the tree

One commit: `zig fmt` over the 11 files, nothing else. `gate.sh:131-133`: the staged-file check
stays (it is the fast path for a `--staged` run) and a full run adds `zig fmt --check modules`
before stage 2 — a red file anywhere fails the gate, staged or not.

**Acceptance:**
- [x] `zig fmt --check modules; echo $?` → `0`, no output
- [x] `scripts/gate.sh` prints a `zig fmt --check modules` line in stage 1 and fails on a synthetic unformatted file

### Step 2 — reformat and add to `TREES`: `libs/std`, the two examples, `compiler-cli/tests`

One reformat-only commit per tree. `libs/std`: the std cell count unchanged
(`zig build test-libs -- --lib std` on both targets, before and after); the two `.d.bp` lines in
`TREES` (`:43-44`) are replaced by `libs/std`. `examples/generic-loader-binding`, `examples/stdlib-tour`
(measure `examples/yamlconf` and any other `examples/*` not in `TREES`; add every green one): each
example builds and runs the same before and after. `modules/compiler-cli/tests`: `zig build test-cli`
green before and after (the fixtures' expected outputs do not depend on indentation — verify).

**Acceptance:**
- [x] `TREES` lists `examples/*` (every example directory), `libs/std/src/{builtins,builtins_fns}.d.bp`, `libs/routing`, `libs/actions`, `libs/validation`, `modules/compiler-cli/tests`; `bash scripts/format-check.sh` → every line ✓ (`libs/std` waits on its 26 snapshots, `tests/language/*` — step 3 — on 12's four `.expect` lines and 16's two printer fixes, § Current state)
- [x] `zig build test-libs -- --lib std` on commonJS and erlang: the same pass count with the reformat applied (433/433 on each, measured before the reformat was backed out — § Current state); `zig build test-cli` green

### Step 3 — `tests/language` reformatted and in `TREES`; the lexer-error cell exempt by structure (gate-c)

`botopink format` over `tests/language/test`, `run`, `modules` (`reject/` is already structurally
outside the walk). Every cell green before and after on `--target all` and `--target beam`
(measured at the open: 1244/1/1 and 382/2/0 — the reformat changes neither number; 110 and 111
change them afterwards). `format_cmd.zig`: the `reject/` rule generalised — a `.bp` inside a
`modules/<cell>/` directory is left out of the walk when the cell's `<target>.expect` files name a
lexer/parser error located *in that file* (`src/pattern.bp:3:2` in all four `.expect` of
`lexer_error_in_imported_module`); pinned by a `format_cmd.zig` test with a synthetic cell (one
`.expect` naming the file → exempt; naming another file → walked). No list, no flag (decision 67).

**Acceptance:**
- [ ] `zig-out/bin/botopink format --check tests/language/modules` → exit 0, `Unchanged` lines only (the exempt file prints nothing, as `reject/` does) — names one file today, `decorator_imported_function_name_conflict/src/main.bp` (§ Current state); `pattern.bp:3` is byte-identical to the open ✓
- [ ] `… format --check tests/language/run` and `tests/language/test` → exit 0 — waits on 16's two printer fixes (§ Current state); then one reformat-only commit over both
- [x] `bash tests/language/run.sh --target all` and `--target beam` print the same tallies as before the reformat (1244 / 1 / 1 and 382 / 2 / 0 at the open, unchanged by this front)
- [x] the `format_cmd.zig` test for the structural exemption

### Step 4 — the header and `scripts/AGENTS.md`

`format-check.sh:5-29`: the header names `TREES` and the rule; the "red trees today" paragraph is
deleted (there are none — a red tree is a red gate). `scripts/AGENTS.md` § format-check.sh
(`:205-220`) the same.

**Acceptance:**
- [x] `grep -c "red today\|joins TREES when" scripts/format-check.sh scripts/AGENTS.md` = 0

## Gate

- [x] `zig build test` from a cold runtime cache, green; `zig build test-cli` green
- [x] `bash scripts/format-check.sh` → every tree ✓; `zig fmt --check modules` → exit 0
- [x] `bash tests/language/run.sh --target all` and `--target beam`: tallies unchanged by this front
- [ ] `scripts/gate.sh --cold` green in this front's worktree — stages 1–7, 9 and 10 green; stage 8
  (`test-libs`) red on the 36 rakun/onze cells that are red at the sibling `feat` tips (99 and 100's
  reds, not this front's); green with those two checkouts absent
- [x] `scripts/AGENTS.md`, `modules/compiler-cli/AGENTS.md` (format_cmd's exemption), `tests/language/AGENTS.md` (`modules/` canonical, `run`/`test` waiting on 16) updated in the same commits
- [ ] commits on `front/112-gate-format` in `repository/botopink-lang`, pushed; no merge — the
  work sits in the worktree, staged step by step by a script (`todo.md` holds it): the pre-commit
  hook (`gate.sh --staged`) refuses every commit at stage 8, with the sibling checkouts present
  (rakun 25 + onze 11 cells red, 21 unledgered restrictions, 9 moved counts) and with them absent
  (the 17 rakun and 4 onze lines of `scripts/restricted-targets.txt` are then "stale"); no stage
  this front can affect is red, and neither the libraries nor the ledger are its files. The
  commits land the day 99, 100 and 113 have landed — or under a maintainer's decision on how a
  botopink-lang commit is gated while the sibling libraries are red

## Blast radius

- Every `../../01-compiler/` front that owns one of the 11 `.zig` files (01: `env.zig`, `infer.zig`,
  `patterns.zig`; 14: `runtime/beam/{lower,program}.zig`; 26: `bpmp/**`, `test_cmd.zig`,
  `engine.zig`) rebases over a `zig fmt` commit — mechanical.
- `../../01-compiler/16-formatter` C-13 step 3 loses `tests/language/modules` from its migration
  count (37 here) and **gains two printer rows** (§ Current state: the record-constructor spread
  printed as `..: <expr>`, and `try ` printed for a `catch` written without one); `tests/language/
  run` and `test` (162 files) are reformatted in one commit once both land and then join `TREES`.
  It keeps rakun/jhonstart/erika/onze (99 and 101 do the PK-5 trees; the rest is 16's) and lands
  decision 132's refusal after them.
- `../../02-std-and-packaging/97-std-dedupe` and `23-std-purity` rebase over the `libs/std` reformat.
- `../../01-compiler/08-hygiene` (`examples/**`) and `26-cli-tooling` (`compiler-cli/tests`) rebase.
- `110` (asserts.bp) and `111` (new cells) start from this landing.
