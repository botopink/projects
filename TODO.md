# TODO — libs-module-migration  (libs · Wave 2 of 3)

> Task branch `task/libs-module-migration` · spec
> [`tasks/v0.beta.10/specs/libs-module-migration.md`](tasks/v0.beta.10/specs/libs-module-migration.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** `module-system` (Wave 1, DONE+merged) — uses `mod`/`pub mod`/
> `root.bp`/`mod.bp` + `botopink migrate`. Six **disjoint** library packages, so the
> per-lib ports are mutually parallel. Touches **no** compiler core. `libs/std` is
> already migrated (the module-system F5 pilot).

> **`.d.bp` decision (matches the std pilot):** the resolver follows `mod` paths to
> `<name>.bp` / `<name>/mod.bp` only — never `.d.bp`. Declaration modules are not
> tree modules; they ship as consumer surface via `botopink.json` `files` (loaded
> `.declaration = true` for a `from "<lib>"` consumer), exactly as `libs/std` keeps
> its ambient `.d.bp` out of `root.bp`. So `root.bp` declares the runnable `.bp`
> modules; pure-`.d.bp` scaffolds (client/server) get a doc-only `root.bp`.

## Per-package work (add `root.bp`, correct visibility, keep `botopink test` green)
- [x] **client** (`src/client.d.bp`) — `root.bp`: doc-only (no `mod`; `client.d.bp`
      is consumer surface, not a tree module). `botopink test` → no test blocks, exit 0.
- [x] **erika** (`src/erika.bp`) — `root.bp`: `pub mod erika;`. `from "erika"`
      + the `erika "…"` template still resolve through the tree (25 tests green;
      `examples/erika-linq` consumer green).
- [x] **jhonstart** (`element.bp`, `hooks.bp`, `html.bp`, `router.d.bp`,
      `server.d.bp`) — multi-file. `root.bp`: `pub mod element; pub mod hooks;
      pub mod html;` (the `.d.bp` surfaces stay consumer-surface, not in the tree).
      All three modules are public; `hooks` imports `Element` (resolver orders
      `element` first). `html "…"` + builder imports resolve; 6 tests green.
- [x] **onze** (`src/onze.bp`) — `root.bp`: `pub mod onze;`. `#[mock]` +
      host cells resolve through the tree; 7 tests green.
- [x] **rakun** (`decorators.bp`, `http.bp`, `runtime.bp`, `rakun.d.bp`) — multi-file.
      `root.bp`: `pub mod decorators; pub mod http; pub mod runtime;` (`rakun.d.bp`
      stays consumer-surface). Cross-module `#[@external]` runtime wiring resolves;
      5 tests green.
- [x] **server** (`src/server.d.bp`) — `root.bp`: doc-only (no `mod`; grows real in
      rakun F5). `botopink test` → no test blocks, exit 0.

## F0 — run the generator per lib, then fix visibility
- [x] `root.bp` scaffolded per package (hand-written with std-style doc headers; the
      generator only handles `.bp` and skips the pure-`.d.bp` scaffolds). No
      genuinely-internal modules exist — every declared module is real public surface
      (element/hooks/html, decorators/http/runtime), so all are `pub mod` (matching
      the generator default). Note: at top level `mod` vs `pub mod` is currently
      package-wide-visible either way; `mod` would only matter for a nested subtree.

## F1 — re-green each lib
- [x] `botopink test` per lib passes on its prior target (commonJS): client/server
      (no tests, exit 0), erika 25, jhonstart 6, onze 7, rakun 5. No blind-scan
      fallback warning. Consumers (`examples/*`) still resolve `from "<lib>"`. Every
      `libs/<x>/AGENTS.md` tree + module-tree section updated.

## F2 — cross-lib + example consumers
- [x] `examples/erika-linq` (`from "erika"`, build + 6 tests), `generic-loader-binding`,
      `jhonstart-counter`/`-html`/`-todo` (`from "jhonstart"`) all build green —
      consumers load via `botopink.json` `files`, decoupled from `root.bp`. (rakun→server
      has no real wiring yet; server is a scaffold until rakun F5.)

## Done gate
- [x] Each `libs/<x>` builds from its `root.bp` tree (no implicit scan);
      `botopink test` stays green per lib on its target.
- [x] `examples/erika-linq` + jhonstart examples still run; every
      `libs/<x>/AGENTS.md` reflects the tree.
- [x] `zig build && zig build test` green.

> **Out of scope / pre-existing:** `zig build test-libs` shows erlang-backend reds
> for erika/jhonstart/onze/rakun (undefined `fold/3`, `toString/1`, `forEach/2`, … —
> method-codegen gaps unchanged by `root.bp`, identical source lowering). These are
> the backends-parity reds the lib-test-runner already exposed; commonJS (the libs'
> actual target) is green across the board.
