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
| traps | `"a\nb".lines()`, `xs.flatMap(…)`, `xs.flatten()`, `xs.flat()`, `xs.chunked(2)`, `xs.sliding(2)`, `xs.fill(0)`, `xs.unique()` | lowered (step 1); what has no answer traps by name — `unique` over records (commonJS `2`, erlang `1`), `flatMap` whose function answers no array, `flatten` over elements no shape says are arrays |
| type-param `==` | a string bound to a type parameter | compared by content wherever the binding is visible (step 2); the one generic body — reached only by a call nothing types (a generic fn in a field or an unannotated `val`, a parameter type `bindParam` does not read) — still compares words |
| C-07 | the tuple / `..` / type / list pattern shapes | one wasm fixture per shape (step 3); `run/is_truth_table` and `run/unknown_stores_nothing` do not exist yet (`02-erlang` step 7) |
| shadow | a block's `val x` over an outer `x` (decision 152: legal, a new scope) | a local of its own, aliased until the block ends (`wat/AGENTS.md` § A binding in an inner block); erlang and beam refuse the program (02's, 03's rows) |

## Current state

Steps 1–4 are done (step 1's and step 3's last boxes wait on 02's cells); step 5 waits on `05w-a` / `05w-b`; the cells `run/string_lines_words`, `run/array_flat_forms`,
`run/array_windows`, `run/array_fill` and `run/generic_string_equality` pass on four targets. The
step-1 cells also closed five shape rows that printed a container's element as its word at exit 0
(`wat/AGENTS.md` § Shapes a container carries), and step 3 closed two pattern rows that matched
wrongly at exit 0 (every list pattern irrefutable, `true`/`false` binders in a tuple pattern). A binding in an inner
block no longer overwrites the outer one (a `val`, a loop's, a HOF's and a `case` binder).
`run/array_unique` (02's cell) is not written: `[3, 1, 1, 3].unique()` answers `[3, 1, 3]` on all
four targets at this tip, so C-35's wasm half is done and its cell is 02's to add.

## Mechanism

| Row | Deciding site | What it decides |
|---|---|---|
| traps | `primCallRes` and the prelude groups `str_lines` … `arr_fill` (`wat/AGENTS.md` § The primitive method table); `newArrShape` for the results' shapes | a lowering, or a named trap |
| type-param `==` | `specializedCallee` / `specializeMethod` / `specializeByFnType`, `ctorTypeRef`, `fieldSub` / `recvTypeArg` (`wat/AGENTS.md`, the generic-parameter limit) | which calls reach a copy with the type substituted |
| C-07 | `emitTuplePatternTest`, `emitListPatternTest`, `noteSubjectShape`, `patternIsIrrefutable` | the test and the binders each shape emits |

## Steps

### Step 1 — the primitive-method traps become lowerings

One lowering per pinned method in `wat.zig` / `wat_prelude.zig`, each with a fixture whose RUN LOG
is the value commonJS answers for the same program: `String.lines`, `String.words`, `Array.pop`
(`?T`), `Array.flatMap`, `Array.flatten`, `Array.flat`, `Array.chunked`, `Array.sliding`,
`Array.fill`, `Array.unique` (C-35 — after 02 step 4 types the prelude body, or as its own wasm
lowering). The trap fixture at `codegen/tests/wat.zig:1122` loses each method as it is lowered and
is deleted when empty.

**Acceptance:**
- [ ] `run/array_unique` (02's cell) green on wasm — the cell does not exist; the program answers `[3, 1, 3]` on four targets
- [x] one `run/` cell per method group (`run/string_lines_words`, `run/array_flat_forms`, `run/array_windows`, `run/array_fill`; `pop` is `run/array_pop_removes`), each `.out` shared by four targets
- [x] `src/codegen/wat/AGENTS.md` § The primitive method table lists no method as "trap"

### Step 2 — `==` between type-parameter values

Re-measure `modules/method_on_unimported_type` at the open; if the word comparison still holds, a
string held in a type-parameter slot compares by content (the value's header says it is a string,
as the `?T` carrier and the boxed `unknown` already do — `wat/AGENTS.md` § the carrier of a `?T`),
so no monomorphisation is needed for equality.

**Acceptance:**
- [x] `modules/method_on_unimported_type` prints the present value with a computed key on wasm; `run/generic_string_equality` on four targets
- [x] `wat/AGENTS.md`'s generic-parameter limit re-derived (equality leaves it; what stays is written)

### Step 3 — C-07's wasm twins

The tuple / `..` / type-pattern fixtures 02 added get wasm twins in `codegen/tests/wat.zig`, each
with a RUN LOG; `run/is_truth_table` and `run/unknown_stores_nothing` (02 step 7's cells) green on
wasm — a row wasm cannot answer traps and its `.wasm.expect` says so.

**Acceptance:**
- [x] one wasm fixture per shape, RUN LOG verified under wasmtime and equal to erlang's and beam's for the same program (commonJS answers differently on three rows, each named at its fixture — `04-js`'s)
- [ ] the two cells green on wasm — blocked: neither cell exists (`02-erlang` step 7)

### Step 4 — after 00-gate: the strict host-wrapper rule holds

The gate lands EF-3 (`collectHostBound` strict; `asserts.bp` restructured). This front verifies
afterwards that `wat/AGENTS.md` § Where this backend refuses to answer states the strict rule and
that no other function is dropped silently (the audit of the wrong-answer class re-run).

**Acceptance:**
- [x] `run/external_wrapper_keeps_refusal` refused on wasm by the documented rule (`wat/AGENTS.md` § Where this backend refuses to answer, "refused where the call is written, called or not"; the cell's `.wasm.expect` is the refusal at `14:12`); `expected-failures.txt` is deleted (111 step 4)
- [x] `zig build test-libs -Doptimize=ReleaseSafe -- --lib std` — `2 passed, 0 failed` (`std · commonJS`, `std · erlang`); `std` has no wasm leg, since `botopink test` refuses wasm, so no wasm-reachable cell moved

### Step 5 — std on wasm: the `@External.Wasm` template reader and the WASI imports (decision 230)

Moved from `00-gate/110-gate-wasm`. `botopink build --target wasm` in `libs/std` exits 1 with
fifteen modules refused (re-measured at this front's tip: `async`, `encoding`, `escape`, `hash`,
`io/clock`, `io/fs`, `io/http`, `io/random`, `json`, `math`, `querystring`, `testing/asserts`,
`testing/mocks`, `testing/snapshots`, `unicode`), because the wasm backend reads `@External.Wasm`
nowhere: no host function can be bound, and no binding in the ecosystem writes one. This step owns
two of the three groups (the third is `02-std-and-packaging`'s):

| Group | Modules | What it needs |
|---|---|---|
| 1 | `math`, `unicode`, `json`, `escape`, `encoding` (and so `querystring`), `hash` | the `@External.Wasm` template reader: a host cell lowered to wasm opcodes (`math`: `f64.floor` …) or to a prelude helper / pure `.bp` body |
| 2 | `io/clock`, `io/random`, `io/fs` (and so `testing/snapshots`) | WASI imports (`clock_time_get`, `random_get`, `path_open` …) bound through the same reader |

**Blocked on two questions** ([`decisions-pending.md`](../../decisions-pending.md)): `05w-a` — what
an `@External.Wasm` binding names (a WAT expression, a closed `op:` / `fn:` / `wasi:` vocabulary, or
no algorithm binding at all) and WASI preview1; `05w-b` — the three cells preview1 has no answer for
(`io/clock.offsetMinutes`, `io/fs.workingDir`, `io/fs.scratchDir`, each refusing its whole module
under decision 146) and the directory `wasmtime run` pre-opens (none today, so every `path_open`
would fail). `05w-a` blocks the whole step; `05w-b` blocks group 2 but `io/random`. What group 1
needs beyond the form: `math` is opcodes (`f64.floor`/`sqrt`/`min`/`max`/`abs`/`trunc`; not `round`:
`f64.nearest` rounds half to even, `Math.round(2.5)` is `3`) plus algorithms wasm has no instruction for (`exp`, `ln`, `pow`, the trigonometry); `hash`, `json`,
`unicode` (four normalisations), `encoding`, `escape` and `io/clock`'s ISO-8601 / civil arithmetic
are algorithms.

**Acceptance:**
- [ ] `botopink build --target wasm` in `libs/std` refuses only group 3's modules (each with its located message)
- [ ] `std · wasm` cells for groups 1 and 2 pass (wasmtime), the same answers as commonJS — `zig build test-libs` has no wasm leg today (`botopink test` refuses wasm), so these are `tests/language` `run/` cells importing each module, one per module, on four targets
- [ ] `wat/AGENTS.md` § Where this backend refuses to answer lists only group 3

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
