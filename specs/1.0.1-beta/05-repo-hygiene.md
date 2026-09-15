# Spec 05 — Repo hygiene

**Version:** 1.0.1-beta
**Priority:** low
**Depends on:** none

---

## Objective

Close the findings of the 1.0.0-beta docs audit that were recorded but not fixed. Each item
was re-checked against the code when this spec was written; confirm again before acting.

Paths are relative to `repository/botopink-lang/` unless they start with `meta:`.

---

## Items

| # | Finding | Decision / fix | Done |
|---|---|---|---|
| 5.1 | `libs/std/src/reflect.bp` and `types.bp` are in neither `libs/std/src/root.bp` (`pub mod …`) nor `build.zig` | wire them (`pub mod`) or delete them; `types.bp` is the target of spec 02 step 5 | [ ] |
| 5.2 | `libs/std/src/primitives.bp` is listed in `build.zig` but not declared in `root.bp`, so its 67 inline tests probably do not run under `botopink test` | confirm, then make them run (or move them) | [ ] |
| 5.3 | `libs/std/botopink.json` `files` lists `primitives.d.bp`, `array.d.bp`, `string.d.bp`, which do not exist (`src/` has `builtins.d.bp`, `builtins_fns.d.bp`) | fix the list to the real ambient files | [ ] |
| 5.4 | `zig build test-vscode` runs `bash ../../scripts/test-vscode.sh`, but the meta repo has no `scripts/` | add the wrapper to the meta repo or point the step at `repository/vscode-extension` directly | [ ] |
| 5.5 | `scripts/git-hooks/pre-commit` looks for `meta:scripts/git-hooks/lib/test-runner.sh` (missing; only `scripts/git-hooks/lib/runner-standalone.sh` exists) and no script installs the hook (`install-hooks.sh` is gone) | restore the meta runner + installer, or make the hook self-contained and document the install | [ ] |
| 5.6 | Comments still describe the removed `wasm3` / `wat_runtime` runtime: `modules/compiler-core/src/codegen/runtime.zig` (`executeWat` doc), `codegen/config.zig`, `codegen/wat.zig` (`wat_runtime` prelude), `codegen/tests/features.zig`, `codegen/tests/wat.zig`, `build.zig` (libc/glibc pin "wasm3 needs libc", `@cImport` note) | rewrite to the current state; re-check whether the glibc pin in `build.zig` is still needed without wasm3. `executeWat` overlaps spec 03 step 2 | [ ] |
| 5.7 | `.github/workflows/test.yml` comments are stale (wasmtime for "26 wasm snapshots", test counts) | update to the current numbers / WAT decision from spec 03 | [ ] |
| 5.8 | `examples/hello.bp` header says `botopink run examples/hello.bp` / `botopink check …`, but the CLI is project-based (`botopink.json`) | fix the header to the real invocation | [ ] |
| 5.9 | `README.md` states the MIT license, but there is no `LICENSE` file | add `LICENSE` (confirm the license with the maintainer) | [ ] |
| 5.10 | A hint was dropped from `AGENTS.md` for lack of verification: "the OTP logger writes SIGTERM to stdout and corrupts the `persistent_erl` frame protocol" | reproduce; if true, restore the hint (and guard the protocol) | [ ] |

## Acceptance

- [ ] Every item fixed or closed with a written reason
- [ ] Matching `AGENTS.md` files updated in the same commits
- [ ] `zig build test` still green
