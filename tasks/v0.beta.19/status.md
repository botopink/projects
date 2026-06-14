# v0.beta.19 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

| Frente | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [frente-a-compiler](specs/frente-a-compiler.md) | `frente-a-compiler` | `task/frente-a-compiler` | `.tasks/frente-a-compiler/` | pending |
| [frente-b-rules-tooling](specs/frente-b-rules-tooling.md) | `frente-b-rules-tooling` | `task/frente-b-rules-tooling` | `.tasks/frente-b-rules-tooling/` | pending |
| [frente-c-distribution](specs/frente-c-distribution.md) | `frente-c-distribution` | `task/frente-c-distribution` | `.tasks/frente-c-distribution/` | **merged+pushed** (`origin/feat` ← 4957f2d; H8 ops + J2 fork smoke deferred to maintainer) |

## Frente A — per-track state

| Track | Description | State |
|---|---|---|
| §A | annotation-driven-builtins tail (v16 §A6+§A7) | pending |
| §B | generic-inference (v14 E + v16 §B) | pending |
| §C | wasm-aggregates + wat refactor (v14 W + v16 §C) | pending |
| §D | cross-backend parity (v14 F3+B + v16 §D) | pending |
| §G | erika DSL extensions (v16 §G) | pending |
| §S | `*fn` removal (v12 cleanup) | pending |
| §U | unused-builtin sweep (live audit) | pending |

## Frente B — per-track state

| Track | Description | State |
|---|---|---|
| Rules §0–§4 | effect-annotation ruleset (§1 result · §1F future · §1I iterator · §1C context · §1G generic defaults) | pending |
| §E | LSP definition tail (v16 §E) | pending |
| §F | TS .d.ts template skip (v16 §F) | pending |
| §T | test-run-log (net-new tooling) | pending |

## Frente C — per-track state

| Track | Description | State |
|---|---|---|
| §H | bpmp online (v18 pinned follow-ups) | **done** (H1–H7); H8 = DNS redirect ops step, deferred to maintainer |
| §I | distribution submodule mergeback | **done** (closed-early: v18 work already on each sibling's `feat`; 6 SHA bumps + 6 sibling `feat` heads pushed across §H/§J/§K commits) |
| §J | module-auto-tag (v18 spec 6, deferred) | **done** (J1+J3); J2 fork smoke deferred to maintainer |
| §K | v17 environment deferreds | **done** (K1+K2 wrappers + AGENTS.md matrix) |

## Done = the whole set ships

- [ ] Frente A: §A through §G + §S + §U all merged + pushed to `feat`
- [ ] Frente B: Rules track §0–§4 + §E + §F + §T all merged + pushed
- [x] Frente C: §H + §I + §J + §K all merged + pushed (4957f2d; H8 ops step + J2 fork smoke deferred to maintainer)
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` +
      `zig build test-vscode` all green
- [ ] Zero `*fn` literals in `repository/` outside CHANGELOG.md
- [ ] Every entry in `libs/std/src/builtins.d.bp` has at least one
      authored caller
- [ ] `botopink test` emits `----- RUN LOG -----` per test on all 4 backends
- [ ] R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4 diagnostics fire
- [ ] `builtins.d.bp` `§ effect annotations` block matches Frente B §4
      verbatim
- [ ] `bpmp install <pkg>` succeeds online end-to-end
- [ ] All 6 submodule pointers in `repository/botopink-lang` track each
      sibling's `feat` head
- [ ] `compiler-core` / `compiler-cli` / `vscode-extension` cut their
      own version tags via `module-auto-tag`
- [ ] All AGENTS.md updated in the same commit as the code (memory rule)
