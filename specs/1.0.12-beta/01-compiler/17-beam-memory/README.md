# Front 17 — beam-memory: `keyed = true` row per key, and `@BeamMemory` refused off the BEAM

**Priority:** medium · **State:** partial: step 1 on feat but its fourth box (17-b); step 2 open
**Depends on:** 17-b (step 1 box 4) · `07-residuals` step 6 (the text into `docs.md`) · the rakun
track (the migration)
**Owns:** the module-`var` read/write lowering under `#[@BeamMemory.Ets(keyed = true)]` in
`codegen/erlang.zig` and `codegen/beam_asm.zig` (`keyedSeedRows`, `emitKeyedRowRead`,
`emitKeyedRowWrite`, `emitKeyedHelpers` — a carve-out of 02 and 03 granted by name) ·
`libs/std/src/beam.bp`'s keyed primitives (a carve-out of the std track, named in the commit) · the
`beam_memory_*` cells · this directory
**Does not touch:** `src/parser/**`, `src/ast.zig`, `src/comptime/**` beyond `validateMemoryAnnotations`
(01) · the rest of `erlang.zig` / `beam_asm.zig` (02, 03) · `docs.md` (07 — the text is
[`../07-residuals/beam-memory-docs-text.md`](../07-residuals/beam-memory-docs-text.md)) ·
`repository/rakun/**` (the rakun track)

Paths are relative to `repository/botopink-lang/modules/compiler-core/src/`.

## Goal

A `#[@BeamMemory.Ets(keyed = true)] var counts: Dict<K, V>` is one ETS row per key on erlang and
beam, so concurrent writers of different keys never lose a write; the per-key increment has the
surface 17-b decides; off the BEAM the annotation is refused (decision 167); `docs.md` documents it.

## Mechanism

- **Off the BEAM** (decision 167): `validateMemoryAnnotations` (`comptime/infer.zig`) records the
  first annotation of a module whose target is neither erlang nor beam, and `reportOffBeamMemory`
  refuses it at the annotation: ``error: `#[@BeamMemory]` has no meaning on the <target> backend``.
- **`keyed = true`** (decisions 168, 174): `Ets`'s argument alone, never on a `pub` var; the seed is
  `Dict.empty()` or `Dict.ofEntries([…])` of literal `#(key, value)` entries (`isKeyedSeed`), folded
  into the table's rows (`keyedSeedRows`; a repeated key keeps its last value). The var is named
  only as the receiver of `counts.at(k)` (`'__bp_ets_at'(Name, Rows, K)` — `ets:lookup`, `null`
  without a row) and of `counts = counts.insert(k, v)` (`'__bp_ets_row'(Name, Rows, {K, V})` —
  `ets:insert` of the one row); a row computed from the var's own rows is decision 40's §5(b)
  refusal, any other read or write is refused naming the one form. `std/beam` has `etsLookup`.

## Done

- Step 1, boxes 1–3 and 5 — `keyed = true` row per key on erlang and beam (decisions 168, 174: `run/beam_memory_ets_keyed`, `reject/beam_memory_ets_keyed_{seed,recompose,whole_read}`); `#[@BeamMemory]` refused off the BEAM (decision 167: `run/beam_memory_off_beam`)
- The text's two sentences that step 1 changed are applied in `../07-residuals/beam-memory-docs-text.md`

## Open

### Step 1 — the per-row increment (box 4, 17-b)

- [ ] the answer to 17-b built: `+=` through a row reaches `ets:update_counter` on the key, or the
      refusal is the rule and `docs.md`'s text says so

### Step 2 — the text and the migration handed over

- [ ] `07-residuals` step 6 places the text (`docs.md` § `@BeamMemory` with the three mode
      paragraphs and the `keyed` sentence)
- [ ] the rakun track's README names the migration by its 1.0.10 path
      ([`rakun-migration.md`](../../../1.0.10-beta/00-compiler-carry-over/17-beam-memory/rakun-migration.md):
      the `rakun_runtime.erl` registry / `gen_server` half remains)

## Decisions

### 17-b. The per-row increment of a `keyed = true` `Dict`

The row write is `counts = counts.insert(k, v)`. `??` exists (`run/nullish_tuple_operand`), so
`counts = counts.insert(k, (counts.at(k) ?? 0) + 1)` types — but it is a row computed from the
var's own rows, decision 40's §5(b) refusal (two processes running it lose a write), and no surface
reaches `ets:update_counter`: `counts.at(k) += 1` / `counts[k] += 1` are no assignment targets (a
target is a name or a field).
**Options.** (a) none — a keyed row is written whole; a per-key counter is refused, and a counter
several processes bump is one `#[@BeamMemory.Ets] var n: i32` each (decision 40's increment);
(b) a std method `Dict.bump(key, by) -> Dict<K, V>` (`V` an integer; an absent key counts from 0),
an ordinary method on a plain `Dict`, lowered under `keyed = true` to
`ets:update_counter(T, K, By, {K, 0})`: `counts = counts.bump(k, 1);`; (c) an index assignment
`counts[k] += 1` in the grammar, lowered the same way.
**Recommendation.** (a) — no new method or grammar for one annotation.

### 17-c. What else names a `keyed = true` var

Built: only `counts.at(k)` and `counts = counts.insert(k, v)`; `counts[k]`, `counts.hasKey(k)`,
`counts.delete(k)`, `counts.size()`, passing `counts` on are refused at the identifier, and a keyed
var is never `pub`. Decision 63 defines `d[k]` as `d.at(k)`, so the index form is refused although
it means the lowered read.
**Options.** (a) the two forms only, as built; (b) (a) plus `counts[k]`; (c) (b) plus `hasKey`
(`ets:member`) and `delete` (`ets:delete`) as row operations, each a new `std/beam` primitive.
**Recommendation.** (a). **Blocks** nothing — the built surface stands until widened.

**Gate:** standard (fronts.md § Gate) + the per-mode cells (`run/beam_memory_{process_dict,ets,persistent_term}`)
green on erlang and beam, a new cell's `.out` what `erl` printed · `scripts/beam_export_audit.sh` green

## Notes

- Decisions 38–43 hold: `val` immutable, the registered owner, `+=` integer-only under `Ets`, a
  misspelled annotation an error, `keyed` unwritten on a `Dict` no warning, two layers.
- No library writes `#[@BeamMemory]` or `keyed = true` (the rakun migration is what will).
