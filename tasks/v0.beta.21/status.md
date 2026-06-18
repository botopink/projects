# v0.beta.21 — status

> Live status of the three specs under [`specs/`](specs/). Updated as each lands.

| Spec | Slug | State |
|---|---|---|
| [`wasm3-embedded-runtime`](specs/wasm3-embedded-runtime.md) | `wasm3-unified-runtime` | in progress — F0–F5 + docs done on `task/wasm3-unified-runtime`; F6 (full `zig build test` sweep) pending; F7 docs partially in (CHANGELOG + runtime/AGENTS.md + runtime/docs.md updated; repo-root AGENTS.md PATH section kept since `test-libs`/`test-backends` still need the runtimes for codegen-execution). |
| [`templates-decorators-botopink-native`](specs/templates-decorators-botopink-native.md) | `templates-decorators-botopink-native` | pending — depends on `wasm3-embedded-runtime`. |
| [`persistent-erlang-ipc`](specs/persistent-erlang-ipc.md) | `persistent-erlang-ipc` | **superseded** by `wasm3-embedded-runtime` (persistent_erlang.zig deleted at the comptime layer). The narrow codegen-execution Erlang IPC piece (`executeErlang` / `executeBeamAsm`) remains pending and is now the spec's only deliverable. |

## Open items on the wasm3 spec

- F6 — Run the full `zig build test` suite end-to-end + collect the
  `strace -f -e trace=execve` zero-wasmtime/erlc/escript receipt.
- F7 (residual) — Remove `wasmtime` / `erl` / `erlc` / `escript` from the
  AGENTS.md "required PATH" matrix once the codegen-execution paths
  (`executeErlang` / `executeBeamAsm`) are also redirected away from system
  spawns. Today the comptime path is clean (this spec); `test-libs` /
  `test-backends` still rely on the system runtimes.
- Snapshot regeneration for any codegen WAT test whose RUN-LOG row changed
  shape (the wasm3 `_botopink_main` auto-detection vs. the legacy
  `wasmtime <file>.wat` invocation).
