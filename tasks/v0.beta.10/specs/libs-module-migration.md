# libs-module-migration — port every `libs/*` package onto the explicit module tree

**Slug**: libs-module-migration
**Depends on**: [`module-system`](module-system.md) — needs `mod`/`pub mod`/`root.bp`/`mod.bp` + the migration mechanism
**Files**: `libs/client/**`, `libs/erika/**`, `libs/jhonstart/**`, `libs/onze/**`, `libs/rakun/**`, `libs/server/**` (each package's sources + a new `root.bp`)
**Touches docs**: each `libs/<x>/AGENTS.md`
**Status**: pending

> The breaking-change fan-out: `module-system` ships the mechanism and migrates
> `libs/std` as the pilot; this spec ports the remaining six library packages onto
> the explicit tree. Each `libs/<x>` is a **disjoint package**, so the per-lib ports
> are mutually parallel once the core lands (the granularity rule). Memory:
> [[feedback_agents_md_maintenance]], [[feedback_prefer_bp_over_dbp]].

## Context — why every lib must change

With `module-system`, a package no longer builds by blindly scanning `src/` — it
builds from a declared tree rooted at `root.bp` (libraries) following `mod`/`pub mod`
to each file. Every `libs/<x>` currently relies on the implicit scan, so each needs
a `root.bp` declaring its public surface and (for multi-file libs) the right
`mod`/`pub mod` wiring. The migration generator from `module-system` F5 does the
mechanical part; this spec applies it per lib, fixes what the generator can't infer
(which modules are `pub` vs internal), and re-greens each lib's own `botopink test`.

## Per-package work

Each row: add `root.bp`, declare modules with correct visibility, keep
`botopink test` green. `.d.bp` declaration modules are surface-only — they are wired
the same way (a `mod`/`pub mod` entry) but carry no runnable body.

- [ ] **client** (`src/client.d.bp`) — single declaration module. `root.bp`:
      `pub mod client;`. Trivial.
- [ ] **erika** (`src/erika.bp`) — single module (the SQL DSL + `Query<T>`).
      `root.bp`: `pub mod erika;`. Confirm `from "erika"` + the `erika "…"` template
      still resolve through the tree (interacts with the loader — keep the bare
      template-fn binding working). Memory: [[project_erika_dsl_done]].
- [ ] **jhonstart** (`element.bp`, `hooks.bp`, `html.bp`, `router.d.bp`,
      `server.d.bp`) — multi-file. `root.bp` declares `pub mod element; pub mod hooks;
      pub mod html;` + the `.d.bp` surfaces; mark any internal helper module `mod`.
      Confirm the `html "…"` template + builder imports resolve. Memory:
      [[project_jhonstart_language_gaps]].
- [ ] **onze** (`src/onze.bp`) — single module (mocking). `root.bp`: `pub mod onze;`.
      Confirm `#[mock]` decorator + host cells resolve through the tree. Memory:
      [[onze_mocking_lib]].
- [ ] **rakun** (`decorators.bp`, `http.bp`, `runtime.bp`, `rakun.d.bp`) — multi-file.
      `root.bp`: `pub mod decorators; pub mod http; pub mod runtime;` + the `.d.bp`.
      Keep the cross-module `#[@external]` runtime wiring resolving. Memory:
      [[project_rakun_progress]].
- [ ] **server** (`src/server.d.bp`) — single declaration module. `root.bp`:
      `pub mod server;`. (Grows real in [[project_v0beta9_tail]] rakun F5 — keep the
      tree ready for added modules.)

## Steps

### F0 — run the generator per lib, then fix visibility
- [ ] Apply the `module-system` migration generator to each package to scaffold
      `root.bp` + any `mod.bp`. The generator defaults everything to `pub mod`;
      hand-correct genuinely-internal modules to `mod` so each lib exposes only its
      real public surface (the path-visibility rule then enforces it).

### F1 — re-green each lib
- [ ] `botopink test` per lib passes on the targets it ran before. A consumer
      (`examples/*`, the cross-lib imports like rakun→server) still resolves
      `from "<lib>"`. Update each `libs/<x>/AGENTS.md` tree section.

### F2 — cross-lib + example consumers
- [ ] Verify cross-package imports across the new trees: `examples/erika-linq`
      (`from "erika"`), a jhonstart example (`from "jhonstart"`), rakun importing
      `server`. Fix any path that assumed the old flat scan.

## Test scenarios

```
build ---- each libs/<x> builds from its root.bp tree (no implicit scan)
test  ---- botopink test stays green per lib on its existing targets
visib ---- a lib's internal `mod` is NOT importable by a consumer; its `pub mod` is
run   ---- examples/erika-linq + a jhonstart example + rakun→server still run
docs  ---- every libs/<x>/AGENTS.md reflects the root.bp + mod wiring
```

## Notes

- Parallel per package — six independent ports; nothing here touches the compiler
  core (that's all in [[module-system]]). Each port is small (most libs are one or a
  few files); jhonstart and rakun are the only multi-module ones.
- Keep each commit's `AGENTS.md` in sync with the new tree
  ([[feedback_agents_md_maintenance]]).
- `libs/std` is **not** here — it is the pilot migrated inside `module-system` F5.
