# Front 17 — beam-memory

**Priority:** medium — the carrier, the three modes, the registered owner and the refusals are
landed (C-05, C-10 steps 4–5); what is open is the one argument decision 51 defined that nothing
can be written on: `keyed = true`.
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

validates (`keyed` on a `Dict`, decision 51) and is refused on erlang and beam: the `Ets`
initialiser must be a literal or `isComptimeExpr()`, there is no `Dict` literal, and `comptime
Dict.empty()` does not fold — so no program can write the argument. Under `keyed = false` a
`Dict` is one row: a write copies the whole dict, and two processes writing different keys lose
one of the writes (measured in 1.0.10: 19 994 of 20 000). Measured at 1.0.10's close; the refusal
re-verified at the open (`reject/beam_memory_ets_initialiser` pins the rule).

## Mechanism

The `Ets` seed rule (`infer.zig`, the `@BeamMemory` validation beside the `val`-assignment
diagnostics) admits a literal or a comptime-foldable expression; `Dict.empty()` is a call on a
type-scoped constructor (decision 111) the folder does not evaluate. The emission
(`erlang.zig`'s module-`var` lowering, `beam_asm.zig`'s twin) has the whole-value `Ets` arm
(`ets:insert` / `ets:lookup` on one key, the `-on_load` seed, decision 39's owner) and no
row-per-key arm.

## Steps

### Step 1 — `keyed = true` lowers, row per key (17-a)

Per 17-a (a): `Dict.empty()` (and `Dict.fromList([…])` of literals) is the accepted seed of a keyed
`Ets` var, folded as the empty table (or its rows); a read `counts.at(k)` is `ets:lookup` on the
key, a write `counts = counts.insert(k, v)` is `ets:insert` of one row, `+=` through
`counts.at(k)` on an integer value is `ets:update_counter` on that key (decision 40's rule per
row); the registered owner unchanged. The same in `.S` (03 step 5 emits, this front specifies and
compares).

**Acceptance:**
- [ ] `run/beam_memory_ets_keyed` (`.targets erlang beam`) — two spawned processes writing **different** keys 20 000 times each print `20000 20000` (the `keyed = false` twin is the measurement, not a cell — a test that fails by chance is not a test)
- [ ] `reject/beam_memory_ets_keyed_seed` — a seed that is neither `Dict.empty()` nor a literal-rowed `fromList` is refused naming the accepted forms
- [ ] any other read-modify-write on a row refused with decision 40's 5(b) diagnostic; `reject/beam_memory_ets_keyed_recompose`
- [ ] `test/beam_memory_noop` gains the keyed `Dict` back on commonJS and wasm (off the BEAM the annotation is a no-op — every test writes and reads back)

### Step 2 — the text and the migration handed over

Part 2 of [`../08-hygiene/beam-memory-docs-text.md`](../08-hygiene/beam-memory-docs-text.md)
publishes with step 1 (08's commit); the rakun migration (1.0.10's `rakun-migration.md`: the
`runtime.mjs` half moot since the packaging, the `rakun_runtime.erl` registry / `gen_server` half
remains) is the rakun track's, registered against decision 17 — nothing here.

**Acceptance:**
- [ ] 08's `docs.md` § `@BeamMemory` carries the three mode paragraphs and the `keyed` sentence with its measured figures
- [ ] the rakun track's README names the migration by its 1.0.10 path

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] the per-mode cells (`run/beam_memory_{process_dict,ets,persistent_term}`) still green on erlang and beam; the new cell's `.out` is what `erl` printed
- [ ] `scripts/beam_export_audit.sh` green
- [ ] `AGENTS.md` of `src/codegen/`, `src/codegen/beam/`, `libs/std/` (if `beam.bp` moves) in the same commit
- [ ] Commit on `fix/17-beam-memory`; no push, no merge

## Blast radius

The `beam_memory_*` snapshots and cells only; no library writes `keyed = true` at the open (the
rakun migration is what will).

## Notes

- Decisions 38–43 hold as answered in 1.0.10 (`design.md`, the README's § Decisions the
  maintainer owes): `val` immutable, the registered owner, `+=` integer-only under `Ets`, a
  misspelled annotation an error, `keyed` unwritten on a `Dict` no warning, two layers.
- The `keyed = false` measurement (19 994 / 20 000; 5 061× at 10 000 keys) lives in the text and
  in `design.md` §4 and §6 — quoted, not re-run, unless the emission changes.
