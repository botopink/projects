# Group A — the removed WAT runtime (5.6, 5.7)

`wasm3` and `wat_runtime` are gone: no file named `wasm3*`, `wat_runtime*` or `wat_to_wasm*` exists,
there is no `vendor/`, and nothing in the tree calls `linkLibC`, `link_libc` or `@cImport`. What is
left is dead code, comments asserting the removed architecture in the present tense, and a CI step
that downloads a binary nothing invokes.

**Settle first:** whether a WAT runtime is wired back in. `executeWat` (`codegen/runtime.zig:547-558`)
returns `""` unconditionally and is honestly documented as a stub — it is the only accurate
wasm3-adjacent comment in the tree. Everything below reads differently depending on that answer, so
do not start until [`../06-wasm/`](../06-wasm/README.md) has made it.

---

## A1 — dead code (5.6)

| Site | What a reader sees | Fix |
|---|---|---|
| `build.zig:13-15`, imported at `:96` and `:108` | A `build_options` module with **no options registered** (`b.addOptions()` then `createModule()`; no `addOption` anywhere) and **no importer** — `grep 'import("build_options")'` over the tree matches only the *comment* at `:13` | Delete the module and both `addImport` calls |
| `build.zig:95` | `// wasm3 headers are accessed via @cImport in` — a sentence with no object; its referent was deleted | Delete the line |
| `build.zig:17-23`, `libcResolvedTarget` at `:334-347` (glibc pinned to 2.38 at `:345`), consumed at `:102, 162, 182, 201, 217` | A glibc pin whose entire justification is "wasm3 needs libc" | Drop it if `zig build` + `zig build test` pass without it on Linux-gnu (Arch glibc ≥ 2.42 and the CI runner). If a runner still needs it, keep it with a comment that does not mention wasm3 |
| `codegen/wat.zig:130` `pub fn emitFnWat` | **Zero callers** — `grep "emitFnWat("` over the whole tree returns the definition only. Not re-exported from `modules/compiler-core/src/root.zig`. Its doc comment names a caller (`comptime/template_eval.zig`) that no longer calls it | Delete, unless the WAT-execution step adopts it |
| `libs/std/src/builtins.d.bp:269-279` (`#[@Host]`) | `:272` — "the raw-infra WAT in `wat_runtime.zig` provides the actual implementation". The `Host` enum is still parsed (`ast.zig:1090`), so a `#[@Host]` fn is still **skipped at codegen** and nothing supplies a body | No `.bp` in the tree uses `#[@Host]`. Delete the annotation, or keep it and make the wat backend reject it instead of silently emitting nothing |

`wat.zig:2416-2419` is a self-documented known gap in the same family (`$__emit`,
`$__compilerError`, `$__binding_ref` "are defined by the `wat_runtime` prelude … In the whole-program
path nothing defines them"). It belongs to the WAT-execution decision, not to this front —
cross-reference it rather than editing it here.

Two of these five are in files this front does not own: root `build.zig`
([`../02-cli-gate/`](../02-cli-gate/README.md)) and `codegen/wat.zig` +
`libs/std/src/builtins.d.bp` ([`../06-wasm/`](../06-wasm/README.md),
[`../03-std-surface/`](../03-std-surface/README.md)). They are deletions, not comment edits, so hand
them to the owning front rather than sweeping them.

## A2 — comments asserting the removed architecture (5.6)

`codegen/config.zig:20-24` is the one that actively misleads: `:23` says "every comptime val
expression **now runs** through the embedded wasm3 interpreter". It runs on the persistent `erl`
server (`meta:architecture.md:15` — "Não há runtime Node, wasm3 ou WAT para comptime").

Remaining sites, all comments: `codegen/wat.zig:127, 129, 138, 442, 965, 968, 2417`;
`codegen/wat/wat_ast.zig:265, 494`; `codegen/AGENTS.md:508-514, 520-521, 605`;
`codegen/tests/features.zig:927`; `codegen/tests/wat.zig:402-403`;
`comptime/tests/helpers.zig:127`.

## A3 — CI (5.7)

`.github/workflows/test.yml`, 148 lines.

| Site | What a reader sees | Fix |
|---|---|---|
| `:82-100` | wasmtime installed on `ubuntu-22.04` (a pinned v45.0.1 tarball, `:86-96`) and `macos-14` (`brew`, `:98-100`), justified at `:71-73` as feeding "26 wasm-codegen snapshot tests". Only the `test` job installs it; `test-libs` (`:114-147`) does not. `executeWat` returns `""`, so **nothing invokes it** | Keep or drop per the WAT-execution decision. If kept, say what will use it and when |
| `:44` | Step named "Install Zig (pinned to `build.zig.zon` `minimum_zig_version`)" with `version: 0.16.0` hardcoded at `:47`. **There is no root `build.zig.zon`** — the only `.zon` files are under `modules/*/` | Name the real source of the pin, or add the root manifest the name claims |
| `:49` | "60 tests under `comptime/runtime/erlang.zig`". That file does not exist; the directory holds `AGENTS.md` and `persistent_erl.zig` | Rewrite to the real file. The OTP 27+ reason it gives (`json:encode/1`) still holds |
| `:1-6` | calls `test-libs` "opt-in"; it is a job with `needs: test` and `allow_fail: false` on linux/macOS | Rewrite |

`.github/workflows/**` is [`../02-cli-gate/`](../02-cli-gate/README.md)'s, and that front is also
widening the gate — so A3 is four corrections to text that front is rewriting anyway. Send them
there unless it has already landed.

## Acceptance

- [ ] No `wasm3` / `wat_runtime` / `wat_to_wasm` / `wasm3_host` mention left in the tree
- [ ] `build_options` and `emitFnWat` deleted, or each has a named user
- [ ] `libcResolvedTarget` deleted, or its comment explains a reason that still exists
- [ ] Every comment about the comptime runtime names the persistent `erl` server
- [ ] `zig build` and `zig build test` green on Linux-gnu and on the CI runners
