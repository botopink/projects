# Front 03 — beam

**Priority:** high — beam is the only target with lines left in `expected-failures.txt` (two, the
sidecar) and the one the language suite reaches only through `--target beam`, so a defect here is
quiet unless someone runs it.
**Depends on:** `00-gate` (EF-1, EF-2 — the beam sidecar; this front's `beam_asm.zig` is one of the
fix's files) · `01-checker` step 7 (lg-b) · `02-erlang` step 7 (the shared `.out` of the C-07
cells) · maintainer decision lg-b (step 4). The `keyed = true` `.S` arm is `17-beam-memory`'s
(its § Owns names the function in `beam_asm.zig`; step 5 is a pointer).
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` · `src/codegen/beam/**` except
`{erl_ast,erl_emitter}.zig` (02's Erlang-text renderer), `beam_file.zig` / `opcodes.zig` /
`gen_opcodes.sh` (18's container) and `asm_text.zig` (14's listing) · the beam snapshots under
`snapshots/codegen/<runtime>/beam/**` and `snapshots/codegen/<runtime>/errors/beam/**` ·
`scripts/beam_export_audit.sh` · its fixtures in a per-backend test file (`codegen/tests/beam.zig`,
created if absent) · [`pattern-binding.md`](./pattern-binding.md) · the cells its steps add
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `src/codegen/erlang.zig`,
`crossModule.zig`, `beam/{erl_ast,erl_emitter}.zig` (02) · `commonJS.zig`, `typescript.zig`, `js/**`
(04) · `wat.zig`, `wat/**` (05) · `modules/compiler-cli/**` (26 — the sidecar's CLI half) ·
`tests/language/run.sh:155` (12's carve-out of 25's runner: the `all` flip)
**Does not touch until 00-gate lands:** `beam_asm.zig`'s module prologue (`main`, the init
order) — EF-1/EF-2 add a `__bp_load_siblings` twin there; this front's steps 1–3 edit the pattern
and call lowerings only, and rebase on the gate's commit.

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise. How a beam program is run by hand: `botopink build --target beam`, `erlc +from_asm
out/beam/*.S`, `erl -noshell -pa out/beam -eval "'<pkg>@main':'_botopink_main'(), halt()."`;
`tests/language/run.sh --target beam` does it for every `run/` and `modules/` cell (382 / 2 / 0 at
the open).

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| JS-4's beam twin | `03-beam/README.md` · `04-js/pattern-binding.md` | § Open rows, "JS-4's beam twin" · § Acceptance, box 1 |
| C-07's beam tails | `03-beam/README.md` · `00/README.md` | § Open rows, "Decision 8's tails" · § C-07, boxes 2–3 |
| the two `expected-failures.txt` lines | `tests/language/expected-failures.txt` (the lines name `03-beam`) | — |
| C-10's beam emission | `17-beam-memory/README.md` | § Step 5 (the same three modes in assembly), the `keyed` row |
| lg-b's beam half | `language-gaps.md` | T6 ("beam drops the write and answers the old value at exit 0") |

## Problem

| Row | Program | beam answers |
|---|---|---|
| JS-4 | `val Label(t, w) = Tag.Label(…);` (a one-variant enum's constructor in binding position) | assembles, then `{unresolved_identifier, t}` — the `.ctor` destructure binds nothing (commonJS and wasm print `x 2 5 hi! 7`, `codegen/tests/aggregates.zig:482`) |
| EF-1, EF-2 | `modules/erlang_host_sidecar_shipped`, `modules/erlang_sidecar_named_like_a_module` | `text:shout/1` is `undef`: the beam build ships no `.erl` sidecar and the `.S` module loads none |
| T6 | `var n = 0; run({ -> n = n + 1; 1; }, 0); @print(n)` | `0` at exit 0 — the write is dropped silently (erlang refuses the module, commonJS prints `1`) |
| C-07 | the tuple / `..` / type-pattern fixtures 02 added; §4.1 × §4.2 | no beam fixture with a RUN LOG pins them; the cells pass by hand |
| C-10 | `#[@BeamMemory.Ets(keyed = true)] var counts: Dict<string, i32> = …` | lowered row per key by `17-beam-memory` (step 5 is a pointer) |

## Current state

`botopink test --target beam` runs (test blocks, a runner compiled at build time, the CLI's
`erlc +from_asm` + `erl` half), and `run.sh` schedules `test/` and test-kind `modules/` cells on
beam: all 68 pass. A constructor or list pattern in binding position binds its names, list
patterns in `case` bind and test every element, a lambda ending a `case` arm is its value, a type
adopts its behavior's `default fn`s, `?.` through a tuple label answers absent, `-x` is the unary
minus, a capitalised imported fn is a call, a bare `break` ends a `for`, the keyword form of an
`@External.Erlang` template compiles, a tuple type in `is` tests each element, and an entry point
sets `standard_io` to unicode before anything prints. Pinned by `codegen/tests/beam.zig` and three
cells. `beam_export_audit.sh` assembles all 490 modules. Every step's beam half is done; what is
open waits on another front: step 1's last box on `01-checker` step 13, step 2's first on
`02-erlang` step 7 and `05-wasm`, step 5 is `17-beam-memory`'s (a pointer).

## Mechanism

| Row | Deciding site | What it decides |
|---|---|---|
| JS-4 | `beam_asm.zig`'s `val` destructure lowering: a `.ctor` pattern is matched (`{TypeAtom, …}` arity and tag) but its sub-patterns are not bound into registers | the names the pattern introduces are never assigned |
| EF-1/2 | `beam_asm.zig` emits no sibling loader; `cli/build.zig`'s beam path calls no `shipErlSidecars` (26's half) | a host module beside the `.S` is neither shipped nor loaded |
| T6 | the closure lowering captures the `var`'s value at closure creation and never writes it back | the stale `0` |
| C-07 | the cells are asserted by `run.sh --target beam` only; no `codegen/tests` fixture carries a beam RUN LOG for the primitive `is` and pattern shapes | a regression in `.S` would be caught by the suite, not by the snapshot |

## Steps

### Step 1 — JS-4's beam twin

The `.ctor` destructure binds each sub-pattern's name to the matched tuple's element register (the
same walk the `case` arm uses for a constructor pattern — `pattern-binding.md` § The contract says
no run-time test is needed: 01's R5 admits only irrefutable patterns). A nested constructor binds
recursively; a spread-only list pattern binds `rest` (01 step 13's checker gaps decide what
reaches here).

**Acceptance:**
- [x] `run/ctor_pattern_in_val_binding` — `val Label(t, w) = Tag.Label(t: 2, w: 5); @print(t + w)` prints `7` on four targets (erlang's `destructPatternExpr` twin: measured landed or added by 02 — the cell's erlang column says which)
- [x] `codegen/tests/aggregates.zig:482`'s fixture gains its beam RUN LOG (`x 2 5 hi! 7`), the four-backend snapshot it was written to be
- [ ] `run/val_nested_ctor_pattern` and `run/val_spread_only_list_pattern` (01 step 13's cells) pass on beam — **open:** the beam lowering is in (`emitPatternDestruct`); the checker still refuses both programs (`refutable-val-pattern`, `rest` unbound), so neither cell exists yet. Measured with the checker's refusal lifted in a local build (not committed): beam prints `val Pair(Circle(r), n) = p` as `3 4`, `val W(I(a, b), n) = …` (nested one-variant enums) and `val H(Circle(r)) = …` as `7 x 9`, and `val [..rest] = [1, 2, 3]`'s length as `3`; commonJS answers the same; erlang leaves `Rest` unbound (`erlc` refuses the module, 02's row — `val assert [..rest] = xs` panics there too) and wasm refuses the nested pattern (05's row). 01 step 13 waits on 02 and 05, not on this front

### Step 2 — C-07's beam tails

Every `tests/language` cell naming §2, §4, §5, §6 runs on beam and matches its `.out`; the tuple /
`..` / type-pattern fixtures 02 added have beam twins in `codegen/tests/beam.zig`, each with a RUN
LOG that is the value run; §4.1's truth table answered by each §4.2 form on beam
(`run/is_truth_table`'s beam column, 02 step 7's shared `.out`).

**Acceptance:**
- [ ] `run/is_truth_table`, `run/unknown_stores_nothing` green on beam — **open:** both are 02 step 7's cells, not landed; 02's `test/is_truth_table` passes on beam, and `codegen/tests/beam.zig` pins its table and `unknown` by value. The table as a program (every row of the test cell, `@print` per form) prints the same ten lines on commonJS, erlang and beam; wasm refuses it (`cannot box this value as unknown`, 05's row), which is what keeps a four-target `.out` from landing
- [x] one beam fixture per tuple / `..` / type-pattern shape, RUN LOG verified by running (`erlc +from_asm` + `erl`)
- [x] `beam_export_audit.sh` green at its new total

### Step 3 — the sidecar's `.S` half (after 00-gate)

00-gate lands EF-1/EF-2 (the CLI ships the sidecars into `out/beam/`, `beam_asm.zig` loads them).
This front verifies afterwards that the loader is emitted for every entry point the erlang emitter
emits it for (02 step 9's `build` case included) and that `beam_export_audit.sh` still assembles
every module with the prologue.

**Acceptance:**
- [x] the two cells green on beam under `botopink test` and on a built program by hand
- [x] no beam line in `expected-failures.txt`; 12's step 1 (beam in `all`) can open

### Step 4 — the captured-`var` write (T6, lg-b)

Under lg-b (1), 01's refusal keeps the shape from this backend; this front pins that the two
threaded forms (`forEach`, a local closure at statement position) still answer on beam and that no
silent `0` is left: `run/closure_capture_statement_position` on beam. Under (2)/(3), the emission
twin of 02 step 8.

**Acceptance:**
- [x] `test/closure_capture.bp`'s shapes as a `run/` cell green on beam; the exit-0 stale value gone (either refused before beam or written back)

### Step 5 — `keyed = true` in assembly (C-10) — a pointer to `17-beam-memory`

The `.S` keyed arm is `17-beam-memory`'s: its § Owns names the module-`var` read/write lowering in
`beam_asm.zig` (a carve-out of this front's file granted by name), so 17 emits it beside the erlang
lowering — `emitKeyedRowRead`, `emitKeyedRowWrite`, `emitKeyedHelpers` — and
`run/beam_memory_ets_keyed` runs on beam with erlang. Its boxes live in
[`../17-beam-memory/README.md`](../17-beam-memory/README.md) step 1; nothing is open here.

### Step 6 — the entry point's `standard_io` (02 step 5's beam twin)

`erl` opens `standard_io` in the host locale's encoding: under `LANG=C` a beam program wrote
`@print("é")` as the latin1 byte `0xE9` and `"\u{1F600}"` as the text `\x{1F600}` (erlang sets it
itself since 02 step 5). `'_botopink_main'/0` and the test runner's `main(Args)` call
`io:setopts(standard_io, [{encoding, unicode}])` first (`emitUnicodeStdio`).

**Acceptance:**
- [x] `run/string_literal_unicode_escape` under `LANG=C LC_ALL=C` prints the characters on beam (measured by hand: the bytes equal erlang's and the `.out`); `codegen/tests/beam.zig` "an entry point sets standard_io to unicode before anything prints" pins the call and the RUN LOG
- [x] the 438 beam snapshot files that moved (219 fixtures × `codegen/{beam,wat}/beam/`) moved by the entry's frame and the `setopts` call alone (`{call_only, 0, …}` → `{allocate, 0, 0}` + the call + `{call_last, …}`); no RUN LOG moved; `beam_export_audit.sh` green

## Gate

- [x] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [x] `scripts/beam_export_audit.sh` assembles every module, before and after each step
- [x] every re-recorded RUN LOG **verified by running the program** (the harness runs `erlc +from_asm` and `erl`; each moved block compared by hand)
- [x] `tests/language/run.sh --target beam` green with the new cells; every cell proved able to fail on the parent binary
- [x] `src/codegen/AGENTS.md` and `src/codegen/beam/AGENTS.md` in the same commit as each step
- [ ] Commit on `front/03-beam`; no push, no merge

## Blast radius

Step 1 moves the beam snapshots of every fixture destructuring a constructor in a `val` (few — the
form is new); step 2 adds fixtures and moves nothing; step 3 (the gate's) adds a loader call to
every beam module's `main` — every beam `.S` snapshot moves by the prologue, no RUN LOG; step 5
moves the `beam_memory_*` snapshots only; step 6 moved every beam snapshot with an entry point by
its prologue (438 files: 219 fixtures under `codegen/{beam,wat}/beam/`), no RUN LOG.

## Notes

- **beam's run-time abort on an unbound name is the backstop, not a fix.** Keep
  `{unresolved_identifier, N}`; the check is the checker's.
- **`scripts/beam_export_audit.sh` is this front's gate, not a formality** — the only mechanical
  proof that every emitted `.S` assembles.
- **This front moves only beam snapshots.** If a change here moves the erlang snapshots, the
  shared Erlang-text renderer crossed into 02 — stop and report.
- [`pattern-binding.md`](./pattern-binding.md) is 1.0.10's `04-js/pattern-binding.md`, moved here
  because its only open half is this backend's; commonJS's half is closed and stays recorded in it.
