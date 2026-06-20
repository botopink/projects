# persistent-erlang-ipc — **DISCARDED · NEVER DO**

**Slug**: persistent-erlang-ipc
**Status**: **DISCARDED 2026-06-20**. Do not implement. Do not create
`persistent_erlang.zig`. Do not vendor an `escript` runner.

## Why this is closed

This spec proposed mirroring `persistent_node.zig`'s long-lived runner for
Erlang/BEAM (length-prefixed stdin/stdout protocol, dynamic compilation
via `compile:forms`, group_leader capture). It is **explicitly rejected**
because:

1. **Wrong direction.** The strategic roadmap is to remove every host-
   runtime dependency from comptime — `templates-decorators-botopink-
   native` is the active spec for that, and it ends with `persistent_node`
   deleted, not multiplied. Reintroducing a sibling `persistent_erlang`
   would be moving the wrong way.

2. **No comptime use case for Erlang.** The wasm3-unified-runtime spec
   (`1749054`) collapsed the four comptime backends (node/erlang/beam/wasm)
   into a single wasm3 path. There is no longer any comptime Erlang
   evaluation — `comptime/runtime/erlang.zig` was **deleted** with
   `persistent_erlang.zig`, `beam.zig`, and `node.zig`. The "first-of-kind
   cold spawn" problem this spec was trying to solve doesn't exist for
   comptime anymore.

3. **Codegen test spawns already covered.** The remaining `erlc + erl`
   spawns live in `codegen/runtime.executeErlang` / `executeBeamAsm`,
   which run the **user's program** during RUN LOG capture (not comptime).
   Those have been addressed by:

   - **No-I/O early bail** (`erlangCodeWritesOutput` /
     `beamAsmCodeWritesOutput`): every fixture without an `io:format`-
     producing path short-circuits to `""` before the spawn. Cold-pass
     speedup: ~22%.
   - **Content-keyed output cache** (`CACHE_ROOT =
     ".botopinkbuild/runtime-cache"`): SHA-256 hash of `(target, module
     name, code, aux)` → `OK:`-prefixed stdout file. Warm-run wall-clock
     dropped from ~3m20s to ~16.6s (**~12× speedup**) without any new
     long-lived runner.

   Both shipped in `1b2de3c` (`perf(codegen/runtime): no-I/O early-bail
   + output cache`). The first-of-kind cost is what remains, and the
   cache amortises it to once-per-distinct-fixture (then forever).

4. **Adds 280 LOC + an escript runner + an embedded Erlang VM lifecycle
   for ~30% benefit over the cache.** The dominant warm cost is now I/O
   on the cache files (<1ms each). A long-lived runner would shave at
   most ~600ms per UNIQUE fixture on the cold pass — a small absolute
   win at a large maintenance cost (BEAM scheduler timing, group_leader
   restoration, soft_purge, dynamic compile recovery from parse errors,
   …).

5. **Maintenance asymmetry.** `persistent_node.zig` exists today because
   templates + decorators *currently* execute under Node (the
   `templates-decorators-botopink-native` spec is removing that). After
   F8/F9/F10 land, `persistent_node.zig` itself goes too. Adding
   `persistent_erlang.zig` now would be net-negative: more code to delete
   later under the same roadmap.

## What to do instead

If a future profile shows codegen-test Erlang/BEAM cold-spawn time has
re-surfaced as the dominant cost (after persistent_node deletion, after
wasm3-unified-runtime stabilisation):

- **First**: extend the output cache key with `(erlc --version)` so
  toolchain upgrades don't need a manual clear, *then* re-measure.
- **Second**: look at whether `executeErlang`/`executeBeamAsm` can be
  *removed entirely* from the RUN LOG capture path (e.g., by trusting the
  codegen unit tests + a once-per-release execution gate), rather than
  swapping in a long-lived runner.

Do **not** revive `persistent_erlang.zig` without an explicit ADR
overriding this decision.

## Historical footnote

This spec was authored 2026-06-17 (memory `project_v0beta21_specs.md`)
and survived as "NARROW (só codegen executeErlang/BeamAsm)" through
2026-06-19. The 2026-06-20 perf tail on `codegen/runtime.zig` made the
spec obsolete. Marker kept for git archaeology — do not implement.
