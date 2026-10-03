# Front 02 — erlang

**Priority:** high — erlang is the target the libraries' CI cells run on and the one rakun ships;
five of the rakun sweep's toolchain rows bottom out in `erlang.zig`.
**Depends on:** `00-gate` (nothing of this front's files is a gate item; the erlang cells the gate
runs must be green before a re-record here is judged) · `01-checker` step 6 (the `throw`-in-arm
typed AST) and step 7 (lg-b's check-time refusal — the lowering half here follows the answer) ·
maintainer decisions lg-b (step 8), 23-d (step 6) · `26-cli-tooling` step 1 consumes step 9's loader
(sequence: this front lands the emitter half first).
**Owns:** `modules/compiler-core/src/codegen/erlang.zig` · `src/codegen/crossModule.zig` ·
`src/codegen/beam/{erl_ast,erl_emitter}.zig` (the Erlang-text renderer, a carve-out from 03 — both
the erlang target and the comptime module text go through it) · the erlang snapshots under
`snapshots/codegen/<runtime>/erlang/**` and `snapshots/codegen/<runtime>/errors/erlang/**` · the
`KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**`, in a per-backend test file
(`codegen/tests/erlang.zig`, created if absent — never a shared feature file, so 03 and 05 do not
touch the same file for their twins) · the cells its steps add under `tests/language/{run,modules}/`
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/beam_asm.zig`,
the rest of `src/codegen/beam/**` (03) · `src/codegen/{commonJS,typescript}.zig`, `codegen/js/**` (04) ·
`src/codegen/wat.zig`, `codegen/wat/**` (05) · `modules/compiler-cli/**` (26) · `libs/std/**` (the
std track: `primitives.bp`'s `Array.unique` body and the `indexOf` template are its rows — this
front hands them the measurement and the cell) · `tests/language/expected-failures.txt` (12)
**Does not touch until 00-gate lands:** nothing — but `erlang.zig`'s comments are 08's sweep after
this front, and `codegen/tests/**`'s test names are 07's.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. `botopink build --target erlang` never invokes `erlc`: a build that passes proves the
text was emitted, not that it compiles — every step runs `botopink run --target erlang`.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the dead tail-`case` lowering | `02-erlang/README.md` | § Step 9 (C-09 R7) |
| C-07's erlang tails | `02-erlang/README.md` · `00-compiler-carry-over/README.md` | § Open rows, "Decision 8's tails" · § C-07, boxes 2–3 |
| C-06's `KNOWN` notes | `02-erlang/README.md` · `00/README.md` | § Open rows, "C-06's bookkeeping" · § C-06, box 2 |
| the language-gaps rows | `language-gaps.md` | T1 (the sibling loader under `build`), T6 (lg-b), T13 (a fn named like a BIF), T14 (`__Loop`), T18 (`indexOf` in bytes) |
| C-34, C-35, C-36 | this milestone's [`carried.md`](../carried.md) | § New C-items |
| the comment sweeps in `erlang.zig` | `08-hygiene/README.md` | § Open, items 1 (×10) and 2 (×16 at the 1.0.10 count) |

## Problem

Each reproduced under `botopink run --target erlang` at the open (the audit's probes; the
`$HOME/.cache/bp-rakun/*` repros of the rows are the rakun sweep's):

| Row | Program | erlang answers |
|---|---|---|
| T13 | a module declaring `fn element(name: string, value: string) -> string`, and a record field read anywhere in it | `{error, badarg}` at run time — the field read `element(4, E)` dispatches to the local `element/2` (`erlc` accepts it silently) |
| T14 | a `while` body calling an `#[@External.Erlang]` template that binds `__Loop` | `{badmatch, #Fun<…>}` — the lowering's `fun __Loop(…)` is already bound |
| T18 | `"a—bXc".indexOf("X")` | `5` (bytes) while `.length()` is `5` and `.at(5)` empty (codepoints) |
| C-34 | a dependency module with `val _x = @print("boot");` at module level | `undefined function '__bp_print'/1` — the helper is emitted per module only where the module's own functions print |
| C-35 | `[1, 2, 1].unique()` | `[1, 2, 1]` (the prelude `default fn` body's `prev.unwrapOr(x)` is never typed); wasm traps |
| C-36 | `"\u{1F600}"` reaching an Erlang binary through `writeStringFromLexeme` | `\x{00}` — the low byte (`erl_emitter.zig:173,184`) |
| T6 | `var n = 0; run({ -> n = n + 1; 1; }, 0); @print(n)` | does not compile: `variable 'N@1' is unbound` |
| T1 | a built program (not under `botopink test`) whose module calls an `.erl` sidecar | `undef` — `__bp_load_siblings/0` is emitted only under the test flag (`erlang.zig:2405-2415`) |
| R7 | `@block { 1 + 2 }` and every block-as-value shape decision 2 refuses | the tail-`case` lowering still has a producer count to measure |

## Current state

`tests/language/run.sh --target erlang` green with no erlang line in `expected-failures.txt`;
`zig build test-libs` erlang cells at baseline. T7 ("a module imported for its types only never
runs its body") is **fixed** in the probed shape (decision 140's `pub val`) and left C-34 behind;
T10 ("`try` inside a `for` writing a `var`") **no longer reproduces** (`I@2 unsafe in 'case'` is
gone) — 12 pins it with a cell, this front adds nothing. The 1.0.10 README's steps 1–3, 6–8, 10
and the "rows no step named" hold. Measured at the milestone's open.

## Mechanism

| Row | Deciding site (`erlang.zig` unless stated) | What it decides |
|---|---|---|
| T13 | the field-read and dynamic-call lowerings emit bare `element/2`, `apply/3` and other auto-imported BIF names | a module fn of that name and arity shadows the BIF for the whole module |
| T14 | the `while` lowering names its fun `__Loop`; a template's text is spliced verbatim into the same clause | a template binding `__Loop` re-matches the bound fun |
| T18 | `primitives.bp`'s erlang template for `indexOf` uses a byte-offset host call (the std track's file); `at` / `slice` / `length` use codepoint ones | two units on one type |
| C-34 | `'__bp_print'/1` is a per-module synthesized helper, emitted when a function body prints; a module-level `val`'s initialiser runs in `'_botopink_init'/0` and is not walked for helpers | the init calls a helper the module never defines |
| C-35 | the prelude's `default fn` bodies are lowered untyped: `prev.unwrapOr(x)` on a `?T` receiver has no lowering, so it emits a call to `unwrapOr/2` | undefined function, or a wrong value where a fallback exists |
| C-36 | `erl_emitter.zig:173` writes every byte ≥ 0x80 as `\x{HH}`, but a `\u{…}` escape in the lexeme is copied as written and Erlang's `\x{…}` keeps 8 bits | a code point above 255 truncates |
| T6 | the closure lowering threads a captured `var` only through `forEach` (a fold) and a local closure at statement position; a lambda handed to an arbitrary function has no value to thread | `N@1` unbound |
| T1 | `erlang.zig:2405` builds `__bp_load_siblings`, `:2415` calls it — both under the test-mode flag only | a built program never loads its sidecars |
| R7 | the tail-`case` block-as-value arm: a block in value position lowers to a `case` whose last expression is the value | dead since decision 2 is enforced (01's R7), producers to count |

## Steps

### Step 1 — a module fn named like an auto-imported BIF (T13)

Every BIF the codegen calls is emitted fully qualified (`erlang:element/2`, `erlang:apply/3`,
`erlang:length/1`, …), so a user fn of the same name and arity never captures the codegen's own
calls; a user fn that shadows an auto-import gets `-compile({no_auto_import, [element/2]})` so
`erlc` resolves the user's calls to the user's fn.

**Acceptance:**
- [x] `run/module_fn_named_like_bif` — a module declaring `fn element(…)` and `fn apply(…)` reads a record field and calls both, prints the right values on four targets (commonJS, wasm: the names are ordinary)
- [x] `grep -c 'erlang:element(' snapshots/codegen/beam/erlang/*.snap.md` ≥ the count of field reads; every erlang snapshot re-recorded is a qualification only (RUN LOGs unchanged, compared block by block)

The `no_auto_import` catalog is OTP's own auto-import list (`erl_internal:bif/2`), and a host
template's bare call of a name the module's own fn shadows is written `erlang:<name>(`.

### Step 2 — the `while` lowering's fun name (T14)

The loop fun's name is one a template cannot spell (a generated suffix per loop, `'__bp_loop_N'`),
and a template's text is wrapped so its bindings cannot see the caller's (`(fun() -> … end)()` is
what the template already does; the lowering's own names must not be plain identifiers a template
can bind).

**Acceptance:**
- [x] `run/host_template_binding_inside_while` — an `#[@External.Erlang]` template binding `__Loop` called in a `while` body prints the loop's count on erlang and beam (`.targets erlang beam`)
- [x] erlang snapshots with a `while` re-record the fun name only

The fun is `__BpLoop` (`__BpLoop<depth>` nested), the backend's own `__Bp` variable prefix.

### Step 3 — a module-level `@print` in a dependency module (C-34)

The `'_botopink_init'/0` initialiser is walked for synthesized helpers like any function body, so a
module whose only print is a module-level binding defines `'__bp_print'/1`.

**Acceptance:**
- [x] `modules/dependency_module_level_print` — a dependency with `val _x = @print("boot");` and a consumer importing a value from it prints `boot` first on four targets
- [x] the same module imported for a type only still runs its body (T7's fixed shape, pinned in the same cell with a second consumer)

### Step 4 — `Array.unique` (C-35, the prelude typing)

The prelude's `default fn` bodies are lowered with the primitive receiver types they declare, so
`prev.unwrapOr(x)` on a `?T` reaches the optional's lowering; or the body is rewritten by the std
track without a method call on an optional inside a `default fn` (decision 9 (b), the 1.0.10
choice — `primitives.bp:640-641` records why). Either way the cell is this front's and the body
is the std track's: hand the measurement over first, land the typing if the body still needs it.

**Acceptance:**
- [ ] `run/array_unique` — `[1, 2, 1, 3, 2].unique()` prints `[1, 2, 3]` on commonJS, erlang and beam; wasm traps until 05 lowers it (05's row, its `.wasm.expect` or `.targets`)
- [x] `src/codegen/AGENTS.md` § Primitive methods loses the `Array.unique` limit row

The typing landed: inside a `default fn` body a local takes the kind its declared types give it
(a parameter's type, a `val`'s annotation, a literal, a behavior method's or a prelude fn's return
type), and a body of the embedded `primitives.bp` is lowered without inference's loc-keyed tables
(a program's call at the same line and column answered for it). `codegen/tests/erlang.zig` pins it,
with `Array.unique`'s RUN LOG on erlang. The `run/` cell is open on two counts: wasm traps on
`unique` and neither a `.wasm.expect` (a compile refusal) nor a `.targets` (a host binding) can
say so; and `primitives.bp` documents `unique` as dropping **consecutive** duplicates
(`[1, 2, 1, 3, 2]` → `[1, 2, 1, 3, 2]` on commonJS, erlang and beam), not the `[1, 2, 3]` the box
writes. Decision 217 settles the second count for the box: `unique` drops **every** duplicate,
keeping first occurrences (`[1, 2, 3]`); the body is the std track's (`02-std-and-packaging`),
and the cell lands with it — on erlang nothing is left to lower (the typing above serves the new
body as it serves the old).

### Step 5 — `\u{…}` and non-ASCII literals in Erlang text (C-36)

`writeStringFromLexeme` decodes a `\u{…}` escape to its UTF-8 bytes before writing `\x{HH}` per
byte, so a binary holds the code point's encoding; the same routine serves the comptime module
text (14's, 18's) and the target's. The std track's STD-11 twin (a non-ASCII literal reaching
erlang as latin1, `illegal character` above U+00FF) is the same site: one fix, two cells.

**Acceptance:**
- [x] `run/string_literal_unicode_escape` — a `\u{1F600}` and a literal `"ç"` print the character on four targets, under any host locale (an entry point sets `standard_io` to unicode itself)
- [ ] a decorator body carrying a `\u{…}` literal evaluates to the character (`comptime/tests/**` — 14's file; the fixture reported to 14, or added as a carve-out named in the commit)

`.length()` of `"\u{1F600}"` is `1` on erlang and beam, `2` on commonJS (UTF-16 units, 04's row)
and `4` on wasm (bytes, 05's row), so the cell prints the characters only. Under `LANG=C` beam
still writes latin1 (03's twin).

### Step 6 — `string.indexOf` counts codepoints (T18, 23-d)

Per 23-d (recommendation (a)): `indexOf` / `lastIndexOf` answer the codepoint index on erlang, the
unit `at` / `slice` / `length` use. The template is `primitives.bp`'s (the std track's file); this
front owns the cell and the erlang lowering if the template needs a helper.

**Acceptance:**
- [ ] `run/string_index_of_codepoints` — `"a—bXc".indexOf("X")` prints `3` and `.at(3)` prints `X` on four targets
- [ ] rakun's `codepointIndex` host cell (`autoconfig_registry.bp`) deletable — the rakun track's row

Done by the std front 97 (decision 169, measured as `string:length/1` of the prefix — decision 197).
`erlang.zig` has no `indexOf` lowering of its own: the erlang text is `primitives.bp`'s template,
so nothing of this step is left in this front's files. The cell waits on
[`decisions-pending.md` 02e-a](../../decisions-pending.md#02e-a--the-unit-of-a-string-index-on-wasm):
erlang, beam and commonJS print `3` and `X`, wasm counts bytes everywhere (`5`, and `.at(1)` of
`"a—bXc"` is one byte of the dash) — decision 169 names no unit for wasm, and wasm accepts the
program, so no `.targets` may leave it out.

### Step 7 — C-07's erlang tails

§4.1's truth table answered by each §4.2 form on erlang (`is` on a primitive, a constructor, a
tuple, `Box<unknown>`), §11's "erlang: nothing" pinned by a fixture, and the tuple / `..` /
type-pattern fixtures this front added given their `.out` on erlang for the cells 03 and 05 twin.

**Acceptance:**
- [ ] `run/is_truth_table` — every row of §4.1 × §4.2, one `.out` shared by four targets (03 and 05 list their lines until their twins land)
- [ ] `run/unknown_stores_nothing` (§11) on four targets
- [x] every `tests/language` cell naming §2, §4, §5, §6 green on erlang (`run.sh --target erlang`)

The table is `test/is_truth_table` (commonJS and erlang agree on every row): no list of lines
exists any more (decision 154), and as a `run/` cell it is red on beam (`#(i32, string)` holds for
a record and a variant too) and traps on wasm — 03's and 05's rows; it becomes the `run/` cell
when they land. §11's "erlang: nothing" is pinned by `codegen/tests/control_flow.zig`'s needle
(`A = 2.0,`, no box); a program cannot tell a stored value from an unboxed one, so
`run/unknown_stores_nothing` has nothing to print that differs.

### Step 8 — the captured-`var` write (T6, lg-b)

Per lg-b's answer: under (1) nothing lowers here — 01's refusal keeps the program from reaching
this backend, and `run/closure_capture_statement_position` pins the two forms that thread; under (2)
a process-dictionary cell per activation; under (3) an ETS cell through decision 39's owner.

**Acceptance:**
- [x] under (1): the cell passes on erlang; under (2)/(3): `run/captured_var_write_in_lambda` prints `1` on erlang and beam

Decision 148 answered (1); `run/closure_capture_statement_position` passes on four targets.

### Step 9 — the sibling loader under `build` (T1)

`__bp_load_siblings/0` is emitted and called for a build entry point too (not only under the test
flag), so a built program loads the `.erl` sidecars beside it; 26 step 1 ships them for `build`
and `run` and the beam twin (03). The compiler's half lands first.

**Acceptance:**
- [x] `modules/erlang_host_sidecar_shipped` passes under `botopink run --target erlang` on a **built** program (`build` then `erl -pa out/erl`), not only under `botopink test` — the cell's existing `.out`, run by hand until 26 lands the CLI half

The entry loads its siblings when some module of the build binds a BEAM host of its own (beam's
rule); a sidecar that does not compile refuses the run, named.
- [ ] language-gaps T1's row closes with 26's step

### Step 10 — the dead tail-`case` lowering (R7)

Measure the producers (`grep` over the erlang snapshots for the tail-`case` shape after 01's R7),
then delete the lowering; the erlang snapshots are otherwise byte-identical.

**Acceptance:**
- [x] the producers measured and written in `src/codegen/AGENTS.md` (§ erlang, "A block as a value has no lowering of its own")
- [ ] `@block { 1 + 2 }` refused by the checker (01's file, the same box as `04-js` step 1) — then nothing in `erlang.zig` is deleted and `snapshots/codegen/*/erlang/**` stay byte-identical

**Measured.** The one erlang site that takes a block in value position is `@block`'s applied
`fun` (`builtinCallNode`), and it has genuine producers: `val a = @block { return 3; }` (`3`), a
body whose every path returns (`js: block ---- @block builtin`, snapshot `block_block_builtin`,
the only fixture writing `@block`; no `.bp` under `tests/language` or `libs` does) and
`@block { … };` as a statement. The tail form decision 2 refuses — `val a = @block { 1 + 2 };`
checks and prints `3` on erlang, beam and wasm, `null` on commonJS — goes through the same `fun`,
whose last expression is its value by Erlang's own rule: there is no tail-`case` lowering to
delete, and no erlang snapshot holds one. A value `if` / `case` with block arms (`docs.md`
§ If / else) is legal and not R7's.

### Step 11 — C-06's `KNOWN` notes and the comment sweeps

The `KNOWN` notes in `codegen/tests/**` that explained the decision-55 cells go (C-30 re-specified
them); every moved RUN LOG of C-06 verified by running (the erlang and beam arms are landed —
verify, do not re-record). Then 08 items 1–2 in `erlang.zig`: the ten `primitives.d.bp` mentions
(`:2535`, `:2566`, `:2699`, `:2951`, `:3300`, `:3320`, `:3322`, `:3333`, `:4732`, `:8878` at HEAD) and
every comment presenting `@external(<target>, …)` as current (re-measure: `grep -c '@external('
erlang.zig` answers 0 at HEAD; the 1.0.10 count was 16 — the sites may spell it differently).

**Acceptance:**
- [x] no `KNOWN` note names decision 55; `grep -rIn 'primitives\.d\.bp' src/codegen` returns nothing
- [x] one commit per sweep, after every other step; 08 verifies

`grep -c '@external(' erlang.zig` was 16 (not 0); every one now spells `#[@External.Erlang(…)]`.

### Rows other fronts found

Each pinned by `codegen/tests/erlang.zig` (the backend's own fixtures) or a `tests/language` cell.

- [x] a `default fn` body of `primitives.bp`: `opt.unwrapOr(d)` was an undefined `unwrapOr/2` — step 4's typing
- [x] a method on a local of such a body (`exponent.startsWith("+")`) was a bare call — the body read the consuming module's loc-keyed lowerings; step 4
- [x] `true` / `false` inside a tuple pattern were binders — matched as atoms
- [x] `Point(x: 0, ..)` in a `case` died `case_clause` — a record's constructor pattern takes the record's own tag (commonJS answers `null` on the same program: 04's row)
- [x] `throw` inside a `case` arm of a `-> @Result` fn, arrow and block form — the `{ok, …}` goes into the arms that do not leave (beam's block form still throws: 03's row)
- [x] erlang stdout followed the host locale (`LANG=C`: `é` as `0xE9`) — an entry point sets `standard_io` to unicode itself
- [x] the sibling loader under `build` — step 9
- [x] a lambda's parameter or `val` over a name of the enclosing function (decision 205) did not compile — each takes a fresh version and the enclosing names come back after the fun; `run/lambda_binds_name_of_enclosing_fn` (red on wasm: 05's row)
- [x] a `default fn` two types adopt (or one adopts while another declares it) was emitted by neither, `twice/1` undefined — each adopter emits it into its own module, a call two types answer dispatches on the value; `run/behavior_default_adopted_by_two_types` (red on beam until 03's adopted-defaults commit lands, and on wasm)
- [x] a `test/` module calling a sidecar function it declares itself died `{error,undef}` — the runner loads its siblings when the build binds a host; `modules/erlang_host_sidecar_in_a_test`

## Gate

- [x] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [x] every re-recorded RUN LOG **verified by running the program** under `erl`; nothing bulk-accepted; steps 1, 2, 10 move `.erl` text only, RUN LOGs unchanged block by block
- [x] `tests/language/run.sh --target erlang` green with the new cells; every cell proved able to fail on the parent binary
- [x] `zig build test-libs` erlang cells at baseline; rakun's members re-run (its host modules call the BIFs step 1 qualifies)
- [x] `src/codegen/AGENTS.md` and `erlang.zig`'s own notes updated in the same commit as each step

The fixes' cells fail on the parent binary; three cells are pins that pass there too
(`test/is_truth_table`, `run/closure_capture_statement_position`) or fail there only under
`LANG=C` (`run/string_literal_unicode_escape`). `zig build test-libs -Doptimize=ReleaseSafe` in this
front's worktree: `123 passed, 0 failed, 15 without tests, 38 restrictions audited` — the
milestone's baseline, every rakun member's erlang cell among the passes.
- [ ] Commit on `front/02-erlang`; no push, no merge

## Blast radius

Step 1 re-records every erlang snapshot with a field read (most of the ~300 erlang cells per
runtime tree — text only, RUN LOGs unchanged); step 2 those with a `while`; step 10 none. Step 4
under the typing option changes the emitted prelude for every erlang module (`primitives.bp`'s
default fns are embedded per module) — one re-record of the tree, classified by the shape. Steps
5 and 6 change what libraries answer for non-ASCII strings: rakun's manifest scanner (front 72/73)
and its `codepointIndex` cell are the measured consumers. Step 9 changes every built program's
`main` (a loader call) — every `run/` cell's erlang output text moves by one line, no RUN LOG.

## Notes

- **Erlang is not the oracle.** Where two backends disagree, the assertion is what the program
  means under decision 8, not what erlang prints.
- **This front moves only erlang snapshots.** A change here that moves `snapshots/comptime/**`
  crossed into 01; one that moves the beam snapshots crossed into 03 (the shared Erlang-text
  renderer of step 5 is the one place both can move: the comptime listings under
  `snapshots/codegen/beam/**` are 14's — report the moved files, do not re-record them here).
- `crossModule.zig` carries decision 109's atoms and layout; nothing here changes an atom.
- The "`@Result` method inside a closure" row of the 1.0.10 README is closed: the shape that
  reproduces is C-35 (a prelude body), not a user closure.
