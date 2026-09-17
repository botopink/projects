# Group B — build files that lie (5.4, 5.16, 5.17)

> Carried from `1.0.2-beta/11-hygiene/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Build files and root scripts that do not work, or work wrongly. Paths are relative to
`repository/botopink-lang/` unless they start with `meta:`.

One of these is not cosmetic: **5.16b** builds a compiler with **5 of 23** std modules and
succeeds, and `modules/compiler-core/AGENTS.md:28-31` tells the reader to use it.

---

## Items

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.4 | `build.zig:301` — `b.addSystemCommand(&.{ "bash", "../../scripts/test-vscode.sh" })`, cwd `.` at `:302` | The path resolves to `meta:scripts/test-vscode.sh`; **`meta:scripts/` does not exist** and `find -name test-vscode.sh` returns nothing. The step fails on every checkout, meta or standalone. `modules/AGENTS.md:65` lists it as working; the comment at `:294-300` describes an `npm ci` marker file that is never written | Delete the step (the extension runs `npm test` in its own repo — see `vscode-extension.md` (1.0.2-beta library-repos, landed), 7g), or inline `npm ci && npm test` with cwd `../vscode-extension` behind an existence check. The sibling `test-libs` step at `:285` shows the in-tree pattern this one violates. Update `AGENTS.md`, `modules/AGENTS.md:65` and the `:294-300` comment |
| 5.16a | `meta:build.zig` (107 lines, tracked, Portuguese) | Every path dangles — `:15` `modules/stdlib/src/prelude.zig`, `:22`, `:32`, `:54`, `:72`, `:88` — because `meta:modules/` does not exist. It declares the **same step names** as the real build (`test` at `:48`, `run` at `:105`), so `zig build test` typed one directory too high fails with a confusing path error instead of "no build.zig". It left `meta:.zig-cache/` and `meta:zig-out/` behind | Delete the file and both directories. `meta:AGENTS.md` already says the repo holds no code |
| 5.16b | `modules/compiler-core/build.zig:58-64` | `std_pkg_files` hardcodes **5** modules (`order, dict, sets, string_builder, queue`) — the first five of `libs/std/src/root.bp:13-35`, which now declares 23. A build from inside `modules/compiler-core/` **succeeds** and produces a compiler that rejects `from "std"` for the other 18. Its `:57` tells the reader to maintain two lists; the root `build.zig:46-53` says `root.bp` is "the single source of truth … (no build.zig edit)". `modules/compiler-core/AGENTS.md:15-16` presents it as an entry point and `:28-31` gives commands that use it | Delete `modules/compiler-core/build.zig` + `.zon` and the same pair under `compiler-cli`, `language-server`, `lib-test-runner` unless a use is found (see [the per-module picture](#the-per-module-buildzig-files) below). Then fix `modules/compiler-core/AGENTS.md:15-16, 25-32` and `comptime/stdlib/AGENTS.md` |
| 5.17 | root `test_pub.zig` and `test_format.zig` | `test_pub.zig:2` imports `modules/core/src/parser.zig` — `modules/core/` does not exist — and calls a two-generations-old API (`parser.tokenize`, `Parser.init(alloc, tokens)`). `test_format.zig:16` uses `std.heap.GeneralPurposeAllocator`, the pre-0.15 spelling. Both define `pub fn main()`, neither is in `build.zig`, and `AGENTS.md:22-23` lists them between the build graph and `.github/` as first-class root artefacts | Delete both; remove `AGENTS.md:22-23` |

## The per-module `build.zig` files

5.16b's deletion is wider than one file. What each module under `modules/` has, and how it is
reached:

| Module | `build.zig` | `build.zig.zon` | Relationship |
|---|---|---|---|
| `compiler-core` | yes — the 5-module `std_pkg_files` list at `:58-64` | yes | the file that builds a wrong compiler |
| `compiler-cli` | yes | yes | depends on compiler-core by `path = "../compiler-core"` |
| `language-server` | yes | yes | depends on compiler-core by `path = "../compiler-core"` |
| `lib-test-runner` | yes | yes | `lib-test-runner/build.zig:9` deliberately does **not** depend on compiler-core |
| `bpmp` | **no** | yes | builds only from the root, at `build.zig:247-253` |

Delete all four `build.zig` + `.zon` pairs unless a use is found. `bpmp`'s lone `.zon` shows the
modules already build fine from the root without their own `build.zig`.

The `modules/compiler-core/build.zig` header is unmodified `zig init` boilerplate with a global
`fu`→`f` corruption (`fnction` at `:3, 5, 111, 121`) — a reason to delete rather than repair.

## Steps

1. **5.4** — delete the `test-vscode` step at `build.zig:294-302` or inline it behind an existence
   check; fix `modules/AGENTS.md:65` and the step's comment either way.
2. **5.16a** — delete `meta:build.zig`, `meta:.zig-cache/`, `meta:zig-out/`.
3. **5.16b** — delete the four per-module `build.zig` + `.zon` pairs (or keep one with a named use
   and derive its std list from `root.bp` the way the root build does); fix
   `modules/compiler-core/AGENTS.md:15-16, 25-32` and `comptime/stdlib/AGENTS.md`.
4. **5.17** — delete `test_pub.zig` and `test_format.zig`; remove `AGENTS.md:22-23`.

## Acceptance

- [ ] `zig build test-vscode` runs and passes, or the step and every reference to it are gone
- [ ] `zig build` from any directory either works or fails with "no build.zig"
- [ ] No second list of std modules exists anywhere
- [ ] No unreachable `.zig` file sits at a repo root, and `AGENTS.md` trees match the disk

## Ownership

Root `build.zig` (5.4) belongs to [`../05-cli-residuals/`](../05-cli-residuals/README.md), which is also
widening the gate there. Send the 5.4 edit to that front unless it has already landed. The
`meta:` files, the `modules/*/build.zig` + `.zon` pairs, the root `.zig` files and the `AGENTS.md`
lines are this front's.

Blast radius: dropping `modules/*/build.zig` removes an entry point
`modules/compiler-core/AGENTS.md:15-16` currently documents. No snapshot moves.
