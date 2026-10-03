# Front 17 — beam-memory

**Priority:** medium — the carrier, the three modes, the registered owner and the refusals are
landed (C-05, C-10 steps 4–5); decision 167's refusal off the BEAM and decision 168's
`keyed = true` (the seed, the row read, the row write, on erlang and beam) are built on
`front/17-beam-memory`. Open: the per-row increment and the row operations beyond `at` /
`insert` (questions `17-b`, `17-c` in [`../README.md`](../README.md) § Decisions), and the hand-off
of the text to 08.
**Depends on:** maintainer decision 17-a (the seed of a keyed `Dict`) · `02-erlang` and `03-beam`
landed — this front's emission sites are in their files (`erlang.zig`'s module-`var` lowering,
`beam_asm.zig`'s twin), so it runs after them as a named carve-out, one site each · `01-checker`
for the seed's folding if 17-a (a) (a carve-out of `infer.zig`'s `isComptimeExpr()` path, named in
the commit) · `08-hygiene` publishes part 2 of the text after step 1.
**Owns:** the module-`var` read/write lowering under `#[@BeamMemory.Ets(keyed = true)]` in
`codegen/erlang.zig` and `codegen/beam_asm.zig` (one function each, a carve-out of 02 and 03
granted by name) · `libs/std/src/beam.bp`'s keyed primitives if the lowering needs new ones (a
carve-out of the std track, named in the commit — the layer-1 half of decision 43) · the cells
`run/beam_memory_ets_keyed` and `reject/beam_memory_ets_keyed_seed` · this directory
**Does not touch:** `src/parser/**`, `src/ast.zig`, `src/comptime/**` beyond the seed carve-out (01)
· the rest of `erlang.zig` / `beam_asm.zig` (02, 03) · `docs.md` (08 — the text is
[`../08-hygiene/beam-memory-docs-text.md`](../08-hygiene/beam-memory-docs-text.md)) ·
`repository/rakun/**` (the rakun track — the migration is 1.0.10's
[`17-beam-memory/rakun-migration.md`](../../../1.0.10-beta/00-compiler-carry-over/17-beam-memory/rakun-migration.md),
handed to `04-rakun`; a pointer only here).

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/` unless a row says
otherwise.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| `keyed = true` | `00/README.md` · `17-beam-memory/README.md` | § C-10, "`keyed = true` not lowered (refused on the BEAM)" · § Step 7, "Not written: `run/beam_memory_ets_keyed`" |
| the `docs.md` text | `17-beam-memory/docs-text.md` | parts 1–2 → 08 |
| rakun's migration | `17-beam-memory/rakun-migration.md` | whole → the rakun track (registered against decision 17) |
| the design | `17-beam-memory/design.md` | stays in 1.0.10; §4 and §6 carry the measurements the text quotes |

## Problem

```
#[@BeamMemory.Ets(keyed = true)] var counts: Dict<string, i32> = Dict.empty();
```

validated (`keyed` on a `Dict`, decision 51) and was refused on erlang and beam: the `Ets`
initialiser had to be a literal or `isComptimeExpr()`, there is no `Dict` literal, and `comptime
Dict.empty()` does not fold — so no program could write the argument. Under `keyed = false` a
`Dict` is one row: a write copies the whole dict, and two processes writing different keys lose
one of the writes (measured in 1.0.10: 19 994 of 20 000; on beam with the whole-value lowering at
this front: 19 996 of 20 000). And off the BEAM the annotation was a silent no-op (decision 43):
commonJS built `run/beam_memory_process_dict` with exit 0.

## Mechanism

The checker (`comptime/infer.zig`, `validateMemoryAnnotations` beside the `val`-assignment
diagnostics) validates the annotation; the emission (`erlang.zig`'s module-`var` lowering,
`beam_asm.zig`'s twin) lowers a read and a write onto `std/beam`'s primitives through the guard
and the registered owner of decision 39.

- **Off the BEAM** (decision 167): `validateMemoryAnnotations` records the first annotation of a
  module whose `Env.target` is neither erlang nor beam, and `reportOffBeamMemory` (after
  `reportStdTargetGates`, once the module is inferred, so the annotation's own rules answer first —
  `reject/` cells run `botopink check`, whose default target is commonJS) refuses it at the
  annotation: ``error: `#[@BeamMemory]` has no meaning on the <target> backend``.
- **`keyed = true`** (decisions 168, 174): `Ets`'s argument alone, never on a `pub` var; the seed is
  `Dict.empty()` or `Dict.ofEntries([…])` of literal `#(key, value)` entries (`isKeyedSeed`),
  folded into the table's rows by `erlang.zig` `keyedSeedRows` (a repeated key keeps its last
  value). The var is named only as the receiver of `counts.at(k)` (`'__bp_ets_at'(Name, Rows, K)`
  — `ets:lookup`, `null` without a row) and of `counts = counts.insert(k, v)`
  (`'__bp_ets_row'(Name, Rows, {K, V})` — `ets:insert` of the one row); a row computed from the
  var's own rows is decision 40's §5(b) refusal, any other write or read is refused naming the
  one form. The owner of a module with a keyed var inserts a seed tagged `{'__bp_rows', Rows}` as
  the rows; no other module's output moved. `std/beam` gained `etsLookup` (`ets:lookup`).

## Steps

### Step 1 — `keyed = true` lowers, row per key (17-a), and the refusal off the BEAM (167)

Per 17-a (decision 168, the constructor named by 174): `Dict.empty()` and `Dict.ofEntries([…])`
of literals are the accepted seed of a keyed `Ets` var, folded as the table's rows; a read
`counts.at(k)` is `ets:lookup` on the key, a write `counts = counts.insert(k, v)` is `ets:insert`
of one row; the registered owner unchanged. The same in `.S` — this front emits both (its § Owns
names the function in `beam_asm.zig`; 03 step 5 is a pointer here).

**Acceptance:**
- [x] `run/beam_memory_ets_keyed` (`.targets erlang beam`) — two spawned processes writing **different** keys 20 000 times each print `20000 20000` on erlang and on beam (the `keyed = false` twin is the measurement, not a cell — a test that fails by chance is not a test); the seed's repeated key reads its last value, a key with no row `null`; `codegen/tests/beam_memory.zig` runs the same on both backends
- [x] `reject/beam_memory_ets_keyed_seed` — a seed that is neither `Dict.empty()` nor a literal-entried `Dict.ofEntries` is refused naming the accepted forms
- [x] any other read-modify-write on a row refused with decision 40's 5(b) diagnostic: `reject/beam_memory_ets_keyed_recompose`; a whole read refused: `reject/beam_memory_ets_keyed_whole_read`
- [ ] `+=` through a row — `ets:update_counter` on the key — has no surface: `counts.at(k)` is a `?V`, there is no `??`, and `counts.at(k) += n` is no assignment target; question `17-b`
- [x] off the BEAM `#[@BeamMemory]` is refused (decision 167, confirmed for wasm by `111-a`): `botopink build --target commonJS` and `--target wasm` exit 1 with ``error: `#[@BeamMemory]` has no meaning on the <target> backend``, located at the annotation; `test/beam_memory_noop` is deleted, `run/beam_memory_off_beam` pins the refusal (`.commonJS.expect`, `.wasm.expect`) and prints `2` on the BEAM; `run/beam_memory_ets` and `run/beam_memory_persistent_term` narrow to `erlang beam`, and `run.sh`'s audit takes the refusal as a host binding (its structural `#[@BeamMemory]` exemption is gone)

### Step 2 — the text and the migration handed over

Part 2 of [`../08-hygiene/beam-memory-docs-text.md`](../08-hygiene/beam-memory-docs-text.md)
publishes with step 1 (08's commit); the rakun migration (1.0.10's `rakun-migration.md`: the
`runtime.mjs` half moot since the packaging, the `rakun_runtime.erl` registry / `gen_server` half
remains) is the rakun track's, registered against decision 17 — nothing here.

**The hand-off to 08** — two sentences of the text changed with step 1:
- Part 1, under `### var`: "Off the BEAM the annotation is a silent no-op …" is superseded by
  decision 167: *Off the BEAM the annotation is refused where it is written — ``error:
  `#[@BeamMemory]` has no meaning on the commonJS backend`` — because a target with one execution
  context has no BEAM storage to name; a `var` there is one value for the whole program.*
- Part 2, the `keyed` sentence: *Under `keyed = true` each key is its own row: the seed is
  `Dict.empty()` or `Dict.ofEntries([#("a", 1)])` of literals, a row is read as `counts.at(k)`
  and written as `counts = counts.insert(k, v)`, and nothing else names the var — measured, two
  processes writing 20 000 times each to their own key finish at `20000` and `20000`
  (`run/beam_memory_ets_keyed`), where the whole-value dict finished at `19 996` (`19 994` in
  1.0.10).* The 5× / 5 000× cost figures stay quoted from 1.0.10's `design.md` §6 (the emission of
  a row write is one `ets:insert`, as the design measured).

**Acceptance:**
- [ ] 08's `docs.md` § `@BeamMemory` carries the three mode paragraphs and the `keyed` sentence with its measured figures
- [ ] the rakun track's README names the migration by its 1.0.10 path

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [x] the per-mode cells (`run/beam_memory_{process_dict,ets,persistent_term}`) still green on erlang and beam; the new cell's `.out` is what `erl` printed
- [x] `scripts/beam_export_audit.sh` green (490/490)
- [x] `AGENTS.md` of `src/codegen/`, `src/codegen/tests/`, `src/comptime/`, `tests/language/` in the same commit (`src/codegen/beam/` and `libs/std/` name nothing that moved; `beam.bp`'s own header carries `etsLookup`)
- [x] Commit on `front/17-beam-memory`; no push, no merge

## Blast radius

The `beam_memory_*` cells only — no snapshot moved: a module without a keyed var emits byte for
byte what it did. Decision 167 reaches every program that writes `#[@BeamMemory]` and builds for
commonJS or wasm: no library writes the annotation (measured at the answer and again here — rakun,
emilia, erika, jhonstart, onze), so the fallout is the four language cells. No library writes
`keyed = true` (the rakun migration is what will).

## Notes

- Decisions 38–43 hold as answered in 1.0.10 (`design.md`, the README's § Decisions the
  maintainer owes): `val` immutable, the registered owner, `+=` integer-only under `Ets`, a
  misspelled annotation an error, `keyed` unwritten on a `Dict` no warning, two layers.
- The `keyed = false` measurement (19 994 / 20 000; 5 061× at 10 000 keys) lives in the text and
  in `design.md` §4 and §6 — quoted, not re-run, unless the emission changes.
