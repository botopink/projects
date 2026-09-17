# Group A — the removed WAT runtime (5.6, 5.7)

> Carried from `1.0.2-beta/11-hygiene/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

`wasm3` and `wat_runtime` are gone: no file named `wasm3*`, `wat_runtime*` or `wat_to_wasm*` exists,
there is no `vendor/`, and nothing in the tree calls `linkLibC`, `link_libc` or `@cImport`. What is
left is dead code and comments asserting the removed architecture in the present tense.

**Answered — start.** A WAT runtime is wired back in, as a process: 1.0.4-beta wasm (`ed15323`) made
`executeWat` run each module under `wasmtime run` (`HARNESS_VERSION = "3-wasm-runs"`). The same
landing deleted `emitFnWat`, `Module.externs` + `Builder.externs`, and the `wat_runtime` / `wasm3`
comments in `codegen/wat.zig`, `codegen/wat/**` and `codegen/AGENTS.md`. The sections below keep the
1.0.2-beta measurement and mark what that closed.

---

## A1 — dead code (5.6)

| Site | What a reader sees | Fix |
|---|---|---|
| `build.zig:13-15`, imported at `:96` and `:108` | A `build_options` module with **no options registered** (`b.addOptions()` then `createModule()`; no `addOption` anywhere) and **no importer** — `grep 'import("build_options")'` over the tree matches only the *comment* at `:13` | Delete the module and both `addImport` calls |
| `build.zig:95` | `// wasm3 headers are accessed via @cImport in` — a sentence with no object; its referent was deleted | Delete the line |
| `build.zig:17-23`, `libcResolvedTarget` at `:334-347` (glibc pinned to 2.38 at `:345`), consumed at `:102, 162, 182, 201, 217` | A glibc pin whose entire justification is "wasm3 needs libc" | Drop it if `zig build` + `zig build test` pass without it on Linux-gnu (Arch glibc ≥ 2.42 and the CI runner). If a runner still needs it, keep it with a comment that does not mention wasm3 |
| ~~`codegen/wat.zig:130` `pub fn emitFnWat`~~ | **Deleted** by 1.0.4-beta wasm (step 8) | — |
| `libs/std/src/builtins.d.bp:269-279` (`#[@Host]`) | `:272` — "the raw-infra WAT in `wat_runtime.zig` provides the actual implementation". The `Host` enum is still parsed (`ast.zig:1090`), so a `#[@Host]` fn is still **skipped at codegen** and nothing supplies a body | No `.bp` in the tree uses `#[@Host]`. Delete the annotation, or keep it and make the wat backend reject it instead of silently emitting nothing |

`wat.zig`'s `KNOWN GAP` block (`$__emit`, `$__compilerError`, `$__binding_ref`) went with
`Module.externs` in the same landing.

Two of the four left are in files this front does not own: root `build.zig`
([`../05-cli-residuals/`](../05-cli-residuals/README.md)) and `libs/std/src/builtins.d.bp` (no owner
this milestone — this front takes the line). The `build.zig` ones are deletions, not comment edits,
so hand them to 05 rather than sweeping them.

## A2 — comments asserting the removed architecture (5.6)

`codegen/config.zig:20-24` is the one that actively misleads: `:23` says "every comptime val
expression **now runs** through the embedded wasm3 interpreter". It runs on the persistent `erl`
server (`meta:architecture.md:15` — "Não há runtime Node, wasm3 ou WAT para comptime").

The sites inside `codegen/wat*` and `codegen/AGENTS.md` were swept by 1.0.4-beta wasm. What it left,
reported at `ed15323` as outside its files — all comments:

| Site | Owner of the file |
|---|---|
| `comptime/tests/helpers.zig:129` | [`../07-comptime-dedup/`](../07-comptime-dedup/README.md) edits it first — sweep after |
| `codegen/tests/features.zig:927` | [`../08-review-backlog/`](../08-review-backlog/README.md) |
| `codegen/crossModule.zig:9-10` | no front — this one |
| `libs/std/src/builtins.d.bp:272` | no owner — this one (with A1's `#[@Host]` row) |
| `codegen/config.zig:22-23` | no front — this one (the misleading "now runs through wasm3" above) |
| `build.zig:19`, `:97` | [`../05-cli-residuals/`](../05-cli-residuals/README.md) |

## A3 — CI (5.7)

`.github/workflows/test.yml`, 148 lines.

| Site | What a reader sees | Fix |
|---|---|---|
| `:82-100` | wasmtime installed on `ubuntu-22.04` (a pinned v45.0.1 tarball, `:86-96`) and `macos-14` (`brew`, `:98-100`), justified at `:71-73` as feeding "26 wasm-codegen snapshot tests". Only the `test` job installs it; `test-libs` (`:114-147`) does not. At the 1.0.2-beta commit nothing invoked it; **since 1.0.4-beta wasm, `executeWat` does** | Keep. Rewrite the justification: `executeWat` runs every wasm snapshot's module under `wasmtime run`, and a missing `wasmtime` must not red the job silently |
| `:44` | Step named "Install Zig (pinned to `build.zig.zon` `minimum_zig_version`)" with `version: 0.16.0` hardcoded at `:47`. **There is no root `build.zig.zon`** — the only `.zon` files are under `modules/*/` | Name the real source of the pin, or add the root manifest the name claims |
| `:49` | "60 tests under `comptime/runtime/erlang.zig`". That file does not exist; the directory holds `AGENTS.md` and `persistent_erl.zig` | Rewrite to the real file. The OTP 27+ reason it gives (`json:encode/1`) still holds |
| `:1-6` | calls `test-libs` "opt-in"; it is a job with `needs: test` and `allow_fail: false` on linux/macOS | Rewrite |

`.github/workflows/**` is [`../05-cli-residuals/`](../05-cli-residuals/README.md)'s, and that front is also
widening the gate — so A3 is four corrections to text that front is rewriting anyway. Send them
there unless it has already landed.

## Acceptance

- [ ] No `wasm3` / `wat_runtime` / `wat_to_wasm` / `wasm3_host` mention left in the tree
- [ ] `build_options` deleted, or it has a named user (`emitFnWat` is gone)
- [ ] `libcResolvedTarget` deleted, or its comment explains a reason that still exists
- [ ] Every comment about the comptime runtime names the persistent `erl` server
- [ ] `zig build` and `zig build test` green on Linux-gnu and on the CI runners
