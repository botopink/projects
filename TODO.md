# TODO — botopink/projects (meta)

> One-line pointer per universal contract
> ([`tasks/AGENTS.md`](tasks/AGENTS.md) §"One fact, one source"):
> **the live rollup of the active set lives in
> [`tasks/v0.beta.19/status.md`](tasks/v0.beta.19/status.md)** — start there.
> This file only carries the unchecked items for the **current** set so a
> reader at the meta root knows what is in flight.

## v0.beta.19 — pending

Closing wave for everything recorded as deferred across v0.beta.{12, 14,
16, 17, 18}. Three file-disjoint frentes + four satellites; one set
worktree per slug under `.tasks/<slug>/`.

- [ ] **[frente-a-compiler](tasks/v0.beta.19/specs/frente-a-compiler.md)**
      — §A annotation-driven-builtins · §B generic-inference · §C
      wasm-aggregates · §D cross-backend parity · §G erika DSL · §S `*fn`
      removal · §U unused-builtin sweep
- [ ] **[frente-b-rules-tooling](tasks/v0.beta.19/specs/frente-b-rules-tooling.md)**
      — Rules §0–§4 (`#[@result]` / `#[@future]` / `#[@iterator]` /
      `#[@generator]` / `#[@asyncGenerator]` / `#[@context]` + §1G default
      generics) · §E LSP definition tail · §F TS `.d.ts` template skip ·
      §T test-run-log
- [ ] **[prim-op-annotation](tasks/v0.beta.19/specs/prim-op-annotation.md)**
      — `#[@external]` template grammar + 3 families of switch-arm
      migrations across 4 backends (partial: foundation + erlang Family 1
      landed; BEAM/commonJS/wat + Families 2–3 in flight)
- [ ] **[std-expansion-tail](tasks/v0.beta.19/specs/std-expansion-tail.md)**
      — 12 deferred std modules + tails (`json`/`base64`/`env`/`fs`/
      `process`/`os`/`regex`/`unicode`/`array_ext`/`string_ext`/`http`/
      `crypto`) — consumes `prim-op-annotation`'s template grammar

Done in this set (kept here as anchors, full receipts in `status.md`):

- [x] **frente-c-distribution** — §H bpmp online · §I distribution
      submodule mergeback · §J module-auto-tag · §K v17 environment
      deferreds. Merged + pushed to `origin/feat` (4957f2d). H8 DNS-redirect
      ops step + J2 fork smoke deferred to maintainer.
- [x] **std-expansion** — first wave (math · asserts · path · random ·
      querystring · time · url) merged + pushed; remaining stdlib gaps
      pivot to `std-expansion-tail` once `prim-op-annotation`'s richer
      `#[@external]` template grammar lands.
- [x] **recursive-test-gate** — F0–F7 done; tracked
      `scripts/git-hooks/pre-commit` + recursive submodule-bump gate +
      `scripts/install-hooks.sh` merged + pushed to `origin/feat`
      (eede97d); per-submodule shim commits landed on each lib's feat.
- [x] **docs-audit-refresh** — two-tier audit done; F0 deletions, F1
      cross-submodule `*.md` drift sweep, F2/F3 clean, F4 meta-root
      `TODO.md` refresh, F4a comments-only LSP sweep (pt-br translation
      + closed TODO markers), F4b/F4c clean, F6 link + strip-comments
      invariant green.

See [`tasks/v0.beta.19/status.md`](tasks/v0.beta.19/status.md) for the
per-track rollup and the done-gate.
