# rakun — the `server` dependency exists nowhere (7a)

Paths are relative to `repository/`; compiler paths start with `botopink-lang/`.

**Blocks:** `botopink check`, `build` and `test` in `rakun/` — all three fail before rakun's own
source is read.

---

## Deciding site

`rakun/botopink.json:7` — `"dependencies": ["server"]`.

There is no directory named `server` under `repository/`, no `botopink.json` with
`"name": "server"` anywhere in the workspace, and nothing in the git history of either rakun or the
meta repo (`git log --all -S'"name": "server"'` is empty in both).

## Mechanism

The array form is valid — `botopink-lang/modules/compiler-cli/src/cli/config.zig:182-195`
`parseDependencies` accepts both the legacy array and the object form. The failure is resolution:

1. `botopink-lang/modules/compiler-cli/src/cli/libs.zig:295` — `return error.LibNotFound`
2. surfaced by `cli/build.zig:65` and `cli/check.zig:40` as *"a declared dependency was not found
   under the libs root"*

rakun's source does use it: `rakun/src/bootstrap.bp:26` `import {serverServe} from "server";`,
called at `:35`. The prose at `bootstrap.bp:6-7`, `:21`, `runtime.bp:85-88` and
`test/server_test.bp:4-10` all describe a `libs/server` that owns the socket.

### Two asymmetries to fix with it

- **The LSP disagrees with the CLI.** `botopink-lang/modules/language-server/src/project_graph.zig:171`
  swallows the miss (`self.loadLib(…) catch continue`), so the editor shows a working project while
  the CLI refuses to build it.
- **A test hard-codes the phantom.** `libs.zig:669` —
  `test "loadOne: rakun resolves \"server\" across roots; absent dep is LibNotFound"` — synthesises
  `ws/repository/botopink-lang/libs/server/botopink.json` at `:677` because no real one exists.

### A silently ignored key

`rakun/botopink.json:6`: `"targets": ["commonJS"]` (plural, array). The manifest parser reads only
a singular string `"target"` (`config.zig:158-161`, default at `:61`), so the key is silently
ignored — an instance of the CLI's "unknown key accepted" class
([`../02-cli-gate/command-contract.md`](../02-cli-gate/command-contract.md)).

## Fix

Decide one of:

| Option | What it implies |
|---|---|
| **Create `libs/server`** | The `bootstrap.bp` prose already describes its contract: one `serverServe(port, dispatcher)` entry point. A new library with its own manifest, tests and gate — and a decision about which repo it lives in |
| **Vendor it into rakun** | A `declare fn` over `node:http` in rakun's own `src/`; the import at `bootstrap.bp:26` becomes local, and the dependency is dropped. Smallest change that keeps the feature; ties rakun's server to commonJS |
| **Drop it** | Remove the dependency and the `bootstrap.bp:26` import together, plus the call at `:35` and the prose at `bootstrap.bp:6-7, 21`, `runtime.bp:85-88`, `test/server_test.bp:4-10` |

Whatever is chosen:

- `"targets"` becomes `"target": "commonJS"` in `rakun/botopink.json`.
- The `libs.zig:669` test must stop inventing the lib — a change in
  `botopink-lang/modules/compiler-cli/**`, owned by [`../02-cli-gate/`](../02-cli-gate/README.md).
- `project_graph.zig:171` must report a missing dependency the way the CLI does —
  `modules/language-server/**` is assigned to no front in [`../fronts.md`](../fronts.md); hand it to
  [`../02-cli-gate/`](../02-cli-gate/README.md) with the `libs.zig` half, since the two must agree.

## Acceptance

- [ ] `botopink check`, `test` and `build` run in `rakun/` — no `LibNotFound`
- [ ] No compiler test synthesises a library that does not exist
- [ ] A missing dependency is reported the same way by the CLI and the language server

## Blast radius

rakun's 22 comptime-dispatch errors are latent behind this failure (counted in
[`../01-comptime-dispatch/primitive-surface.md`](../01-comptime-dispatch/primitive-surface.md)).
Fixing 7a surfaces them; rakun stays red until that front lands.
