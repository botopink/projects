# Front 17 — beam-memory: `keyed: true` row per key, and `@BeamMemory` refused off the BEAM

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s2 box 1 → B-02 · s1 → B-26; [150-rakun](../../../2-libraries/150-rakun/README.md): s2 box 3 → 150 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium · **State:** partial: step 1 on feat but its fourth box (`Dict.bump`, decision 340); step 2 open
**Depends on:** `07-residuals` step 6 (text into `docs.md`) · rakun track
(migration)
**Owns:** module-`var` read/write lowering under `#[@BeamMemory.Ets(keyed: true)]` in
`codegen/erlang.zig` and `codegen/beam_asm.zig` (`keyedSeedRows`, `emitKeyedRowRead`,
`emitKeyedRowWrite`, `emitKeyedHelpers` — carve-out of 02 and 03 by name) · `libs/std/src/beam.bp`'s
keyed primitives and `Dict.bump` (decision 340; std-track carve-out, named in the commit) · `beam_memory_*` cells · this directory
**Does not touch:** `src/parser/**`, `src/ast.zig`, `src/comptime/**` beyond `validateMemoryAnnotations`
(01) · rest of `erlang.zig` / `beam_asm.zig` (02, 03) · `docs.md` (07 — text in
[`../07-residuals/beam-memory-docs-text.md`](../07-residuals/beam-memory-docs-text.md)) ·
`repository/rakun/**` (rakun track)

Paths relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

`#[@BeamMemory.Ets(keyed: true)] var counts: Dict<K, V>` = one ETS row per key on erlang and beam
(concurrent writers of different keys lose nothing); per-key increment by `Dict.bump` (340); refused off the
BEAM (decision 167); documented in `docs.md`.

## Mechanism

- **Off the BEAM** (decision 167): `validateMemoryAnnotations` (`comptime/infer.zig`) records a
  module's first annotation when the target is neither erlang nor beam; `reportOffBeamMemory`
  refuses at the annotation: ``error: `#[@BeamMemory]` has no meaning on the <target> backend``.
- **`keyed: true`** (decisions 168, 174): `Ets`'s only argument, never on a `pub` var; seed
  `Dict.empty()` or `Dict.ofEntries([…])` of literal `#(key, value)` entries (`isKeyedSeed`), folded
  into rows (`keyedSeedRows`; repeated key keeps its last value). The var appears only as receiver
  of `counts.at(k)` (`'__bp_ets_at'(Name, Rows, K)` — `ets:lookup`, `null` without a row) and
  `counts = counts.insert(k, v)` (`'__bp_ets_row'(Name, Rows, {K, V})` — `ets:insert` of one row); a
  row computed from the var's own rows = decision 40 §5(b) refusal; any other read/write refused
  naming the one form. `std/beam` has `etsLookup`.

## Decisions

Measured / options / blocks in [`../../decisions-pending.md`](../../../decisions-pending.md).

Answered: 17-b → decision 340 (`Dict.bump`, `ets:update_counter` under `keyed: true`).

### 17-c. What else names a `keyed: true` var

Recommendation (a): the built forms only — `at`, `insert` and 340's `bump`. Blocks nothing — built
surface stands until widened.

**Gate:** standard (fronts.md § Gate) + per-mode cells (`run/beam_memory_{process_dict,ets,persistent_term}`)
green on erlang and beam, a new cell's `.out` what `erl` printed · `scripts/beam_export_audit.sh` green

## Notes

- Decisions 38–43 hold: `val` immutable, registered owner, `+=` integer-only under `Ets`, misspelled
  annotation an error, `keyed` unwritten on a `Dict` no warning, two layers.
- No library writes `#[@BeamMemory]` or `keyed: true` yet (the rakun migration will).
