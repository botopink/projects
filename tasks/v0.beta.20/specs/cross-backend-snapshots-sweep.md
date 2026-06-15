# cross-backend-snapshots-sweep — close v0.beta.19's §D6 doc tail

**Slug**: cross-backend-snapshots-sweep
**Depends on**: [`typed-method-dispatch`](typed-method-dispatch.md),
  [`beam-inline-prim-methods`](beam-inline-prim-methods.md),
  [`future-runtime-erlang-beam`](future-runtime-erlang-beam.md) —
  this spec lands AFTER those, regenerating their cross-backend
  snapshots in one sweep.
**Files**: `modules/compiler-core/snapshots/codegen/{erlang,beam}/`
  · `modules/compiler-core/src/codegen/AGENTS.md`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
  (Remaining-gaps rows narrow to their final state)
**Status**: pending

## Background

v0.beta.19's frente-a-compiler §D6 deferred to a follow-up because
the per-track snapshots ride their own producing commits. This
sweep is the close-out: a single PR/commit that regens every
cross-backend snapshot affected by §D3, §D4, §D5 and sweeps the
last open note in `codegen/AGENTS.md:57`
(`negation_in_expression gc_bif Live count`).

## Checklist

- [ ] **F1-snapshots-D3** — Cross-backend snapshots for typed
      method dispatch: fixture compiled with `--target erlang`
      and `--target beam`; both emit the mangled local
      `'Parser_parse'(P, X)` form; the snapshots match byte-for-byte
      across the two backends.
- [ ] **F2-snapshots-D5** — Each of the 6 BEAM inline-fun methods
      gets its snapshot already in the
      [`beam-inline-prim-methods`](beam-inline-prim-methods.md)
      spec; this spec confirms the snapshots round-trip through
      `erlc +from_asm` and matches the erlang reference.
- [ ] **F3-snapshots-D4** — `#[@future]` fixture's snapshot lands
      via [`future-runtime-erlang-beam`](future-runtime-erlang-beam.md);
      this sweep verifies the chained Future.map produces matching
      output across erlang+beam.
- [ ] **F4-negation-note** — Sweep the
      `negation_in_expression gc_bif Live count` note pinned in
      `codegen/AGENTS.md:57`. Snapshot the actual register layout
      in beam_asm + add an `erlc +from_asm` smoke that asserts the
      gc_bif Live argument matches the documented minimum.
- [ ] **F5-AGENTS-final** — Drop every row from `codegen/AGENTS.md`
      Remaining-gaps that this spec closes. Final-state rows pin
      the surviving gaps in one line each (no follow-up references
      — every prior gap either landed in v0.beta.20 or is
      explicitly scoped to a successor spec).

## Test scenarios

```
F1 ---- `record Parser …; p.parse(x)` snapshot pinned on erlang+beam
        (mangled local).
F2 ---- 6 BEAM snapshots all match the erlang reference; `erlc
        +from_asm` round-trips.
F3 ---- `#[@future] fn …` cross-backend snapshot pinned.
F4 ---- negation_in_expression gc_bif Live count pinned in the
        snapshot.
F5 ---- `codegen/AGENTS.md` Remaining-gaps section is final-state;
        zero "deferred" entries point at v0.beta.20 specs (every
        such entry has been closed).
```

## Notes

- This spec is the **gate** for v0.beta.20's compiler-tail tracks
  shipping as a coherent set. It runs last.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
