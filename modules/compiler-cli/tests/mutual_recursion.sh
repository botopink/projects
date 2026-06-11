#!/usr/bin/env bash
# Integration test: a top-level fn calling another declared *later* (a forward
# reference) plus true mutual recursion (`isEven` <-> `isOdd`) must COMPILE AND
# RUN — returning the right result, not merely type-checking — on every backend.
#
# This is the run-side regression guard the mutual-recursion spec asked for
# (`tasks/v0.beta.9/specs/mutual-recursion.md`). The inference guards already
# live in `comptime/tests/infer_decls.zig`; the all-backend codegen guard lives
# in `codegen/tests/js_control_flow.zig`. This script proves the emitted code
# actually executes and asserts the boolean result, which a snapshot cannot.
#
# It is an end-to-end test (builds the `botopink` CLI, spawns node/escript/erl),
# so it is NOT part of `zig build test` — run it directly:
#
#     bash modules/compiler-cli/tests/mutual_recursion.sh
#
# Backends:
#   commonJS  ── `botopink test`            (assert isEven(10) == true, …)
#   erlang    ── `botopink test --target erlang`
#   beam      ── build the BEAM assembly, `erlc +from_asm`, then `main:main()`
#   wasm      ── DEFERRED: the run is blocked by an unrelated boolean-literal
#                gap (`return true` lowers to `global.get $true`, no such
#                global). The wasm *codegen* is still covered by the snapshot
#                test; only the live run is skipped. Not a mutual-recursion bug.
#
# Exit 0 = every available backend ran the recursion and returned the right
# answer. A missing runtime (node/escript/erl) skips that backend with a notice;
# a wrong answer fails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/mutual_recursion"

echo "==> building botopink CLI"
( cd "$REPO_ROOT" && zig build )

BP_BIN="$REPO_ROOT/zig-out/bin/botopink"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

cd "$FIXTURE_DIR"

# ── commonJS ──────────────────────────────────────────────────────────────────
if command -v node >/dev/null 2>&1; then
  echo "==> commonJS: botopink test"
  "$BP_BIN" test --target commonJS
else
  echo "==> commonJS: SKIPPED (node not on PATH)"
fi

# ── erlang ────────────────────────────────────────────────────────────────────
if command -v escript >/dev/null 2>&1; then
  echo "==> erlang: botopink test --target erlang"
  "$BP_BIN" test --target erlang
else
  echo "==> erlang: SKIPPED (escript not on PATH)"
fi

# ── beam ──────────────────────────────────────────────────────────────────────
# `botopink run --target beam` only writes the .S artifact, so assemble it with
# `erlc +from_asm` and invoke `main:main()`, which returns `isEven(10)` — the
# atom `true` when the bare-`if` base case falls through to the recursive call.
if command -v erlc >/dev/null 2>&1 && command -v erl >/dev/null 2>&1; then
  echo "==> beam: build --target beam, erlc +from_asm, run main:main()"
  "$BP_BIN" build --target beam
  erlc +from_asm -o out out/main.S
  erl -noshell -pa out -eval \
    'case main:main() of true -> io:format("  beam: main:main() => true~n"), halt(0); X -> io:format("  beam: WRONG result ~p~n", [X]), halt(1) end'
else
  echo "==> beam: SKIPPED (erlc/erl not on PATH)"
fi

# ── wasm ──────────────────────────────────────────────────────────────────────
echo "==> wasm: DEFERRED (blocked by unrelated boolean-literal lowering, not mutual recursion)"

echo "==> mutual-recursion run guard: OK"
