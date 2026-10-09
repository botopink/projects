# Front 17 — beam-memory: `keyed: true` row per key, and `@BeamMemory` refused off the BEAM

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

## Done

- Step 1, boxes 1–3 and 5 — `keyed: true` row per key on erlang and beam (decisions 168, 174: `run/beam_memory_ets_keyed`, `reject/beam_memory_ets_keyed_{seed,recompose,whole_read}`); `#[@BeamMemory]` refused off the BEAM (167: `run/beam_memory_off_beam`)
- The text's two sentences step 1 changed applied in `../07-residuals/beam-memory-docs-text.md`

## Open

### Step 1 — the per-row increment (box 4, decision 340)

- [ ] std's `Dict.bump(key, by) -> Dict<K, V>` (integer `V`, an absent key counts from 0) is
      `insert(key, (at(key) ?? 0) + by)` on any `Dict`; on a keyed var `counts = counts.bump(k, n)`
      lowers to `ets:update_counter(T, k, n, {k, 0})` on erlang and beam — a `run/beam_memory_ets`
      cell with concurrent bumps of one key losing none; `counts.insert(k, (counts.at(k) ?? 0) + n)`
      stays refused (no pattern recognised); `docs.md`'s `keyed` sentence names `bump`

### Step 2 — the text and the migration handed over

- [ ] `keyed: true` (decision 305) in every cell and diagnostic of this front; `keyed = true` is the
      parser's located error (`01-checker` step 27)

- [ ] `07-residuals` step 6 places the text (`docs.md` § `@BeamMemory` with the three mode
      paragraphs and the `keyed` sentence)
- [ ] the rakun track's README names the migration by its 1.0.10 path
      ([`rakun-migration.md`](../../../1.0.10-beta/00-compiler-carry-over/17-beam-memory/rakun-migration.md):
      the `rakun_runtime.erl` registry / `gen_server` half remains)

## Decisions

Measured / options / blocks in [`../../decisions-pending.md`](../../decisions-pending.md).

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
