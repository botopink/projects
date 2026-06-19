# beam-inline-prim-methods (F1 / F2 / F3 — pick one, all file-disjoint)

> Spec: [`tasks/v0.beta.20/specs/frente-a.md`](../../tasks/v0.beta.20/specs/frente-a.md) (search for `beam-inline-prim-methods`).

## Baseline

- meta `feat`: `1c38772`.
- bot-lang `feat`: `6b46f55`.
- Already landed on bot-lang `feat`:
  - **F4** — 2-arg `slice` (`c635730`).
  - **F5** — string `contains` (inline `binary:match`).
  - **F6** — string `startsWith` (inline `binary:part`).
- All 3 lowerings live in `modules/compiler-core/src/codegen/beam_asm.zig`.

## Pending phases (each independent)

- [x] **F1 — `Array.join`** (BEAM) — `primJoin` ships per-element stringify
      closure via `ensureStringifyHelper` + `make_fun3`, then
      `lists:map` + `lists:join` + `iolist_to_binary`. Snapshot
      `array_join_lowers_byte_identically_across_backends.snap.md`
      runs to `<<"10, 20, 30">>` (byte-identical with erlang).
- [x] **F2 — `Array.indexOf`** (BEAM) — `primIndexOf` lazily emits 3-arg
      recursive synth helper `'-bp_indexOf-'/3 (L, X, I)` tail-recursing
      via `call_only` with the running index in `{x, 2}`; hit returns the
      index, miss returns `-1`. Snapshot
      `array_indexof_lowers_byte_identically_across_backends.snap.md`
      runs to `2` / `-1`.
- [x] **F3 — `Array.at`** (BEAM, bounds-safe) — `primAt` ships
      `'-bp_at-'/2 (L, I)` that spills both args to y-slots so
      `erlang:length/1` survives, then `is_ge` against `0` + `is_lt`
      against length + `gc_bif '+' (I+1)` + `call_ext_last lists:nth/2`
      on hit, `undefined` on miss. Snapshot
      `array_at_lowers_byte_identically_across_backends.snap.md` runs
      to `10` / `undefined`.
- [x] **F7 — docs**
      - `modules/compiler-core/src/codegen/AGENTS.md` `beam_asm.zig`
        row updated — join/indexOf/at moved out of "not yet lowered".
      - `CHANGELOG.md` v0.beta.20 entry for beam-inline-prim-methods.

## Out of scope

- Wat versions of these methods — separate spec.
- erlang versions — already landed in v0.beta.19 (`64a3436`).

## Exit gate (per phase)

- BEAM snap byte-identical with the spec's reference.
- `zig build test` green; `zig build test-libs` green on beam axis.
- AGENTS.md updated in same commit.
