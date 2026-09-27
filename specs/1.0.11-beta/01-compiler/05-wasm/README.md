# Front 05 — wasm

**Priority:** high — wasm is the backend that can answer a wrong value with exit 0 and no
diagnostic; the rule this front holds is that a shape wasm cannot do traps, and the open rows are
the traps that should be lowerings.
**Depends on:** `00-gate` (EF-3 — `run/external_wrapper_keeps_refusal`'s wasm line is fixed by the
gate in `wat.zig`'s `collectHostBound` under ck-host (a); this front rebases on it) · `02-erlang`
step 4 (C-35's typing) and step 7 (the C-07 cells' `.out`) · maintainer decision ck-host (the gate's
item; confirmed before the gate lands it).
**Owns:** `modules/compiler-core/src/codegen/wat.zig` · `src/codegen/wat/**` except
`wasm_binary_emitter.zig` (18's) · the wasm snapshots under `snapshots/codegen/<runtime>/wasm/**`
and `snapshots/codegen/<runtime>/errors/wasm/**` · `src/codegen/tests/wat.zig` (its fixtures) ·
the cells its steps add
**Does not touch:** `src/comptime/**`, `src/parser/**` (01, 14, 18) · `erlang.zig`, `crossModule.zig`,
`beam/{erl_ast,erl_emitter}.zig` (02) · `beam_asm.zig`, `beam/**` (03) · `commonJS.zig`,
`typescript.zig`, `js/**` (04) · `modules/compiler-cli/**` (26) · `libs/std/**` (the std track —
`asserts.bp`'s restructure under ck-host is theirs, with the gate) · `modules/wasm3/**`,
`comptime/runtime/wat/**` (18)
**Does not touch until 00-gate lands:** `wat.zig`'s `collectHostBound` (`:1445`) and the
host-binding walk around it (EF-3).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise; programs run with `botopink run --target wasm` (wasmtime).

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| the pinned primitive-method traps | `05-wasm/README.md` | § Step 6, box 2 (`String.lines`/`words`, `Array.pop`/`flatMap`/`flatten`/`flat`/`chunked`/`sliding`/`fill`/`unique`) |
| `==` between type-parameter values | `05-wasm/README.md` | § Open rows |
| C-07's wasm twins | `00/README.md` | § C-07, box 2 (the tuple / `..` / type-pattern fixtures' wasm twins) |
| `run/external_wrapper_keeps_refusal` | `tests/language/expected-failures.txt` (the line names `05-wasm`) · `decisions-pending.md` ck-host | — |
| C-35's trap | this milestone's [`carried.md`](../carried.md) | § New C-items |

## Problem

| Row | Program | wasm answers |
|---|---|---|
| traps | `"a\nb".lines()`, `xs.pop()`, `xs.flatMap(…)`, `xs.flatten()`, `xs.flat()`, `xs.chunked(2)`, `xs.sliding(2)`, `xs.fill(0)`, `xs.unique()` | `RUNTIME TRAP` — each pinned by `codegen/tests/wat.zig:1122` (`a primitive method with no wasm lowering traps, never answers`); commonJS and erlang answer |
| type-param `==` | `modules/method_on_unimported_type`: `Dict.at` with a string key through a type parameter | finds the key only when both sides are one interned literal (`src/codegen/wat/AGENTS.md:219`, the generic-parameter limit) — re-measure: the audit notes the AGENTS row may be stale after the `?T` carrier work |
| EF-3 | `run/external_wrapper_keeps_refusal` | the cell **passes** on wasm (the lazy `collectHostBound` drops the wrapper) while the strict rule says refuse — listed as an expected failure because the strict rule is the documented one |
| C-07 | the tuple / `..` / type-pattern fixtures | no wasm twin with a RUN LOG |

## Current state

`run.sh --target wasm` green with the one line above; every `RUNTIME TRAP` fixture re-read at
1.0.10's close is still a shape wasm cannot do or is the program's own `@todo()` / fatal `assert`.
The 1.0.10 status rows for wasm (a multi-subject `case`, an all-unit enum printed through a name,
a named fn handed to `map`) closed with their cells. `zig fmt` green on this front's files.
Measured at the open.

## Mechanism

| Row | Deciding site | What it decides |
|---|---|---|
| traps | `wat.zig`'s primitive method table (`src/codegen/wat/AGENTS.md` § The primitive method table): a method with no entry lowers to `unreachable` | a trap instead of a wrong value |
| type-param `==` | string equality on wasm compares words when the declared type is a type parameter — no shape exists to compare by (`wat/AGENTS.md:219`); nothing monomorphises | two equal strings from different allocations are `!=` |
| EF-3 | `collectHostBound` (`wat.zig:1445`) walks the program for host-bound functions and drops a function whose only body is a host call with no wasm binding; the call site is refused instead | the wrapper is accepted although the documented rule refuses it |

## Steps

### Step 1 — the primitive-method traps become lowerings

One lowering per pinned method in `wat.zig` / `wat_prelude.zig`, each with a fixture whose RUN LOG
is the value commonJS answers for the same program: `String.lines`, `String.words`, `Array.pop`
(`?T`), `Array.flatMap`, `Array.flatten`, `Array.flat`, `Array.chunked`, `Array.sliding`,
`Array.fill`, `Array.unique` (C-35 — after 02 step 4 types the prelude body, or as its own wasm
lowering). The trap fixture at `codegen/tests/wat.zig:1122` loses each method as it is lowered and
is deleted when empty.

**Acceptance:**
- [ ] `run/array_unique` (02's cell) green on wasm; one `run/` cell per method group (`run/string_lines_words`, `run/array_pop`, `run/array_flat_forms`, `run/array_windows`, `run/array_fill`), each `.out` shared by four targets
- [ ] `src/codegen/wat/AGENTS.md` § The primitive method table lists no method as "trap"

### Step 2 — `==` between type-parameter values

Re-measure `modules/method_on_unimported_type` at the open; if the word comparison still holds, a
string held in a type-parameter slot compares by content (the value's header says it is a string,
as the `?T` carrier and the boxed `unknown` already do — `wat/AGENTS.md` § the carrier of a `?T`),
so no monomorphisation is needed for equality.

**Acceptance:**
- [ ] `modules/method_on_unimported_type` prints the present value with a computed key on wasm; `run/generic_string_equality` on four targets
- [ ] `wat/AGENTS.md`'s generic-parameter limit re-derived (equality leaves it; what stays is written)

### Step 3 — C-07's wasm twins

The tuple / `..` / type-pattern fixtures 02 added get wasm twins in `codegen/tests/wat.zig`, each
with a RUN LOG; `run/is_truth_table` and `run/unknown_stores_nothing` (02 step 7's cells) green on
wasm — a row wasm cannot answer traps and its `.wasm.expect` says so.

**Acceptance:**
- [ ] one wasm fixture per shape, RUN LOG verified under wasmtime and equal to commonJS's for the same program
- [ ] the two cells green on wasm

### Step 4 — after 00-gate: the strict host-wrapper rule holds

The gate lands EF-3 (`collectHostBound` strict; `asserts.bp` restructured). This front verifies
afterwards that `wat/AGENTS.md` § Where this backend refuses to answer states the strict rule and
that no other function is dropped silently (the audit of the wrong-answer class re-run).

**Acceptance:**
- [ ] `run/external_wrapper_keeps_refusal` refused on wasm by the documented rule; no wasm line in `expected-failures.txt`
- [ ] `zig build test-libs` — `std`'s wasm-reachable cells at baseline

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] every re-recorded RUN LOG **verified by running the program** under wasmtime and compared with commonJS's for the same fixture
- [ ] no new RUN LOG answers a value with exit 0 that another backend answers differently — a shape wasm cannot do is a `RUNTIME TRAP`, never a wrong number
- [ ] the `RUNTIME TRAP` fixtures re-read: each is still a shape wasm cannot do, or it is fixed
- [ ] `src/codegen/AGENTS.md` and `src/codegen/wat/AGENTS.md` in the same commit as each step
- [ ] Commit on `fix/05-wasm`; no push, no merge

## Blast radius

Step 1 moves the wasm snapshots of every fixture calling one of the ten methods (the trap fixture
and any program that avoided them — few) and the wasm column of the `std` cells that use them;
step 2 moves the wasm snapshots of generic string comparisons; step 3 adds fixtures. Step 4 (the
gate's) reds any library function that wraps a wasm-less host call — measured by the gate before
it lands (std's `deepEquals` is the known one).

## Notes

- **wasm must not answer wrongly and silently.** Where wasm cannot do a shape, it traps; a wrong
  value with exit 0 is a bug even when a fixture records it.
- **`botopink test` refuses wasm**, so only `run/` and `modules/` cells reach it.
- **This front moves only wasm snapshots.** If a change here moves erlang, beam or commonJS
  snapshots, something crossed a boundary — stop and report.
- The comptime wat runtime's four non-parity items (`wat-runtime.md` §7) are 18's limits, not this
  target's.
