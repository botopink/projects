# persistent-erlang-ipc — long-lived Erlang/BEAM runner over a length-prefixed stdin/stdout protocol

**Slug**: persistent-erlang-ipc
**Depends on**: nothing — file-disjoint with `template-static-fold` and other v0.beta.21 specs at the source level. Mirrors `persistent_node.zig` (landed in v0.beta.20's `test-speed-tmp-consolidation`).
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/persistent_erlang.zig` (NEW, ~200 LOC) — Zig client to a long-lived `escript` runner. Mirrors `persistent_node.zig`'s singleton + spinlock + length-prefixed protocol.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/persistent_erlang_runner.escript` (NEW, ~80 LOC) — embedded Erlang script that reads scripts from stdin, dynamically compiles each one via `compile:forms/2`, loads via `code:load_binary/3`, runs `Module:main(ok)` with a captured group_leader, and emits length-prefixed stdout. The escript source is embedded as a Zig comptime string (same approach as `persistent_node.zig`'s embedded `runner_js`).
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/erlang.zig` — call `persistent_erlang.eval(...)` before falling back to the one-shot `erlc + erl` path. Same wiring pattern as the node fast path landed in v0.beta.20. ~20 LOC.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/AGENTS.md` — add a row for `persistent_erlang.zig` mirroring the `persistent_node.zig` row.
**Touches docs**:
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/AGENTS.md`.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/docs.md`.
  - `repository/botopink-lang/CHANGELOG.md`.
  - `tasks/v0.beta.21/status.md`.
**Status**: pending

## Problem

`erlang.zig` (compiler-core/src/comptime/runtime/erlang.zig) spawns `erlc` + `erl` per call. v0.beta.20's `test-speed-tmp-consolidation` added a process-wide stdout memo (SHA-256 → cached stdout), which kills duplicate spawns but leaves the first-of-kind cost intact:

- **`erlc` cold spawn**: ~200–400ms (parses + compiles a .erl module to .beam).
- **`erl` cold spawn**: ~400–700ms (BEAM VM bootstrap is heavy).
- **Total per unique script**: ~600ms–1.1s.

In a `zig build test` run with ~150 codegen tests × 4 backends, the erlang/beam axis dominates the timeline — the codegen `assertJs` tests sitting at ~2.4s each are almost entirely BEAM cold-start. The memo lands ~30% reduction in spawns (duplicates within one process); the remaining ~70% pay the cold tax.

`persistent_node.zig` (landed in v0.beta.20) solves the analogous problem for `node`: one long-lived process, scripts streamed via stdin/stdout, ~1ms per call instead of ~18ms cold. This spec mirrors that work for Erlang.

## Intent

- **One long-lived `escript` per Zig process.** Spawned lazily on the first `eval` call (same singleton pattern as `persistent_node.zig`).
- **Length-prefixed stdin/stdout protocol** identical to the node runner:
  - Client → server: `<len-hex8>\n<script-bytes>`.
  - Server → client: `<len-hex8>\n<captured-stdout-bytes>`.
- **Dynamic compilation** inside the runner: each request body is a full `-module(<name>).` Erlang source. The runner:
  1. Parses tokens via `erl_scan:string/1` + `erl_parse:parse_form/1` (loop).
  2. Compiles forms via `compile:forms/2` → `{ok, ModuleName, Binary}`.
  3. Loads via `code:load_binary(ModuleName, "bp_request.erl", Binary)`.
  4. Captures `Module:main(ok)`'s stdout by replacing its `group_leader` with a buffering process for the call's duration.
  5. Restores the original `group_leader`, drains the buffer, and writes it back as the response payload.
  6. Soft-purges via `code:soft_purge(ModuleName)` / `code:delete(ModuleName)` after each call so loaded modules don't accumulate.
- **Coarse atomic spinlock** around the send/receive pair (matches `persistent_node.zig`). The BEAM scheduler is single-threaded for our one-script-at-a-time use case anyway.
- **Graceful fallback**: when the runner can't be spawned (`escript` not on PATH, protocol framing error, runner crash), fall back to the existing one-shot `erlc + erl` path — same `else |_| { … }` pattern `persistent_node.zig` already enables in `template_eval.evaluate` and `runtime/node.zig run`.

## Disk layout (proposed)

The runner is embedded as a comptime Zig string and passed to `escript` via stdin or a tmp file — final choice is part of F0 (escript reads from stdin natively, but accepting a file is simpler for the first cut). Either way, **no per-request file lives on disk**: scripts are streamed in memory.

## DAG

```
F0-escript-runner-skel    embedded escript + zig client skeleton
F1-protocol-loop          length-prefixed read/write + dynamic compile + group_leader capture
F2-wire-into-erlang       hook into `erlang.run` as fast path with eval fallback
F3-runtime-tests          a new `tests/persistent_erlang.zig` pin: 2 evals, 2nd one < 5ms total
F4-codegen-pin            the heavy codegen tests drop from ~2.4s to <300ms
F5-docs-status            AGENTS / docs / CHANGELOG / status sweep
```

---

## F0 — Runner skeleton

**Files**:
  - `modules/compiler-core/src/comptime/runtime/persistent_erlang.zig` (NEW, skeleton ~80 LOC mirroring `persistent_node.zig`).
  - `modules/compiler-core/src/comptime/runtime/persistent_erlang_runner.escript` (NEW, ~30 LOC for now — bare read-loop that echoes back).

Smoke test: spawn the runner, send `<<00000001\n">"`, read back the same single-byte response. Asserts the framing wires up.

---

## F1 — Protocol loop + dynamic compile + group_leader capture

**Files**: `persistent_erlang.zig` + `persistent_erlang_runner.escript` (~120 LOC).

Runner code outline:

```erlang
#!/usr/bin/env escript
main(_) -> loop().

loop() ->
    case read_len() of
        eof -> halt(0);
        Len ->
            ScriptBin = read_exact(Len),
            Out = run_one(ScriptBin),
            emit(Out),
            loop()
    end.

read_len() ->
    case io:get_chars(standard_io, '', 9) of
        eof -> eof;
        Bytes -> list_to_integer(string:trim(lists:sublist(Bytes, 1, 8)), 16)
    end.

read_exact(N) -> iolist_to_binary(io:get_chars(standard_io, '', N)).

run_one(ScriptBin) ->
    Script = unicode:characters_to_list(ScriptBin),
    case erl_scan:string(Script) of
        {ok, Tokens, _} ->
            Forms = parse_forms(Tokens),
            case compile:forms(Forms, [binary, return]) of
                {ok, Mod, Bin, _Warnings} ->
                    code:load_binary(Mod, "bp_request.erl", Bin),
                    Capture = start_capture(),
                    Old = group_leader(),
                    group_leader(Capture, self()),
                    _ = (catch Mod:main(ok)),
                    group_leader(Old, self()),
                    Out = stop_capture(Capture),
                    code:soft_purge(Mod), code:delete(Mod),
                    Out;
                _ -> <<"__BP_RUNNER_ERROR__: compile failed">>
            end;
        _ -> <<"__BP_RUNNER_ERROR__: scan failed">>
    end.

parse_forms(Tokens) -> %% split by . and parse each form
    Chunks = split_dots(Tokens, [], []),
    [erl_parse:parse_form(C) || C <- Chunks].

start_capture() ->
    spawn_link(fun() -> capture_loop([]) end).

capture_loop(Acc) ->
    receive
        {io_request, From, ReplyAs, {put_chars, _Enc, Chars}} ->
            From ! {io_reply, ReplyAs, ok},
            capture_loop([Chars | Acc]);
        {io_request, From, ReplyAs, {put_chars, _Enc, M, F, A}} ->
            From ! {io_reply, ReplyAs, ok},
            capture_loop([erlang:apply(M, F, A) | Acc]);
        {drain, From} ->
            From ! {drained, iolist_to_binary(lists:reverse(Acc))}
    end.

stop_capture(Pid) ->
    Pid ! {drain, self()},
    receive {drained, Bin} -> Bin end.

emit(OutBin) ->
    Hex = io_lib:format("~8.16.0B~n", [byte_size(OutBin)]),
    io:put_chars(standard_io, [Hex, OutBin]).
```

The Zig client is a 1-for-1 of `persistent_node.zig`: singleton, spinlock, `ensureSpawned`, `readExact`, `eval`.

---

## F2 — Wire into `erlang.zig`

**Files**: `modules/compiler-core/src/comptime/runtime/erlang.zig` (~20 LOC).

Insert before the existing `erlc + erl` block, after the memo lookup:

```zig
if (persistent_erlang.eval(allocator, io, src)) |out| {
    defer allocator.free(out);
    memoStore(key, out);
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();
    try parseResults(allocator, out, &values);
    return .{ .script = src, .values = values };
} else |_| {}
```

Same wiring as `node.zig` already has (landed in v0.beta.20's `test-speed-tmp-consolidation`).

---

## F3 — Runtime pin

**Files**: `modules/compiler-core/src/codegen/tests/persistent_erlang.zig` (NEW, ~50 LOC).

Two evals of the same trivial script (`io:format("~p", [42]).`). Assert:
- First eval succeeds (~600ms — single cold start).
- Second eval succeeds AND completes in < 5ms (no second BEAM spawn).
- `state.child.id` is the SAME pid across the two calls (the runner is reused).

---

## F4 — Codegen pin

**Files**: pick a representative test from `codegen/tests/js_values.zig` that hits ~2.4s today, assert it now runs < 300ms.

The 4-backend codegen path (commonJS/erlang/wasm/beam) lights up persistent_node + persistent_erlang concurrently. Combined with the v0.beta.20 cache, the spawn overhead per test drops from ~720ms (cold) to ~20ms (one round-trip per backend × 4).

---

## F5 — Docs + status

**Files**:
  - `modules/compiler-core/src/comptime/runtime/AGENTS.md` — row for `persistent_erlang.zig`.
  - `modules/compiler-core/src/comptime/runtime/docs.md` — paragraph.
  - `CHANGELOG.md`.
  - `tasks/v0.beta.21/status.md`.

---

## Test scenarios

```
persistent-erl ---- two evals reuse one BEAM
persistent-erl ---- captured stdout matches one-shot output (byte-identical)
persistent-erl ---- erlang error in script surfaces __BP_RUNNER_ERROR__
persistent-erl ---- 100 sequential evals all reuse one BEAM, no module-leak
persistent-erl ---- parallel evals from N threads serialise correctly (smoke)
codegen integration ---- one js_values test < 300ms (was ~2.4s)
codegen integration ---- erlang-runtime tests pass byte-identical snapshots
```

## Notes

- **Why two separate specs (persistent-node already done, persistent-erlang here)?** node was landed in v0.beta.20's `test-speed-tmp-consolidation` because the LSP sublanguage tests were the immediate user-visible regression. Erlang has the same architectural fix but more BEAM-specific moving parts (dynamic compile, group_leader capture, module purge) — it deserves its own spec/PR.
- **Why not a shared "persistent runner" abstraction?** The IPC frame is identical, but the runner code is per-runtime. Extracting a shared abstraction is premature until WASM (wasmtime) and BEAM ASM (beam_asm) join the family.
- **wasm/beam follow-ups**: WASM goes through `wasmtime` (fast cold start, ~10ms) — persistent isn't worth it. BEAM goes through `beam_asm.zig` which itself delegates to `erlang.run`, so this spec covers it transitively.
- **Out of scope**:
  - Crash recovery (if the runner exits unexpectedly, fall through to one-shot — implemented today via the `else |_|` fallback).
  - Per-script timeout / kill (a runaway BEAM call hangs the test binary; not a concern for the deterministic scripts the eval emits).
  - Concurrent compile in the runner (BEAM scheduler is multi-core but our protocol serialises — one script at a time is fine; matches `persistent_node.zig`'s assumption).
- **Exit gate**:
  - `persistent_erlang.zig` unit tests green (no `erlc + erl` spawn on the 2nd call).
  - One representative codegen test drops 8× (≥ 2.4s → ≤ 300ms).
  - Existing codegen suite byte-identical snapshots.
  - `AGENTS.md` per affected module updated in the same commit as code.
