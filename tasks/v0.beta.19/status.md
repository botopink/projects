# v0.beta.19 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

| Frente / spec | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [frente-a-compiler](specs/frente-a-compiler.md) | `frente-a-compiler` | `task/frente-a-compiler` | `.tasks/frente-a-compiler/` | partial — §S/§U/§A6/§D1/§G1/§G3 done; §A7/§B/§C/§D2-D5/§G2 deferred + recorded |
| [frente-b-rules-tooling](specs/frente-b-rules-tooling.md) | `frente-b-rules-tooling` | `task/frente-b-rules-tooling` | `.tasks/frente-b-rules-tooling/` | pending |
| [frente-c-distribution](specs/frente-c-distribution.md) | `frente-c-distribution` | `task/frente-c-distribution` | `.tasks/frente-c-distribution/` | **merged+pushed** (`origin/feat` ← 4957f2d; H8 ops + J2 fork smoke deferred to maintainer) |
| [prim-op-annotation](specs/prim-op-annotation.md) | `prim-op-annotation` | (pending — likely lands in Frente A's worktree as a satellite) | — | pending |
| [std-expansion](specs/std-expansion.md) | `std-expansion` | `task/std-expansion` | `.tasks/std-expansion/` | **merged+pushed** (`origin/feat` ← bot-lang `83d5d1a` + meta `06fa981`; 7/19 modules landed: math/asserts/path/random/querystring/time/url; 12 deferred → `std-expansion-tail`) |
| [std-expansion-tail](specs/std-expansion-tail.md) | `std-expansion-tail` | (pending — single worktree `.tasks/std-expansion-tail/`) | — | pending |
| [recursive-test-gate](specs/recursive-test-gate.md) | `recursive-test-gate` | `task/recursive-test-gate` | `.tasks/recursive-test-gate/` | **done** (F0–F7 merged + pushed to `origin/feat` eede97d; submodule shim commits on each lib's `feat`; recursive submodule scan exercised live during the bump commit) |

## std-expansion — per-wave state

| Wave | Modules | State |
|---|---|---|
| §W1 essentials | `math`, `json`, `base64`, `time`, `random` | **done** for `math` ✓ + `time` (partial — `nowMillis`) + `random` (partial — `float`/`coin`/`pick<T>`); `json`/`base64` and the time/random tails moved to `std-expansion-tail` |
| §W2 system | `env`, `path`, `fs`, `process`, `os` | **done** for `path` ✓ (`relative`/`resolve` tail moved to `std-expansion-tail`); `env`/`fs`/`process`/`os` moved to `std-expansion-tail` |
| §W3 text | `regex`, `unicode`, `array_ext` (Array<T> methods), `string_ext` (String methods) | all moved to `std-expansion-tail` |
| §W4 network+crypto | `url`, `querystring`, `http`, `crypto` | **done** for `url` ✓ (`parse` + `serialize`) and `querystring` ✓; `http`/`crypto` moved to `std-expansion-tail` |
| §W5 assertions | `assert` | **done** as `asserts` ✓ (plural — `assert` is keyword); `throws`/`matches`/`AssertError` tail moved to `std-expansion-tail` |

## Frente A — per-track state

| Track | Description | State |
|---|---|---|
| §A | annotation-driven-builtins tail (v16 §A6+§A7) | A6 closed; **A7 deferred** (BEAM bytecode-template gate — 3/4 backends viable without it) |
| §B | generic-inference (v14 E + v16 §B) | **deferred** (deep inferencer work; planned for a successor spec — keeps the pre-existing erlang/beam erika-LINQ + generic-module inline-test reds recorded) |
| §C | wasm-aggregates + wat refactor (v14 W + v16 §C) | **deferred** (deep wat refactor; no regression — the wasm gap was the spec's premise) |
| §D | cross-backend parity (v14 F3+B + v16 §D) | **D1 done** (annotation-driven `print`/`println`/`debug` + new `$args` template marker — `console.log($args)` / `io:format("~p~n", [$args])` on commonJS+erlang; BEAM keeps inline shape); D2–D5 deferred (substantive cross-module / type-directed / register choreography work — pinned in `codegen/AGENTS.md` Remaining gaps); D6 partial (Remaining-gaps rows updated, cross-backend snapshots TBD) |
| §G | erika DSL extensions (v16 §G) | **G1 done** (`${…}` interp via `q.parts()` + `substituteHoles` deep walk in `comptime/infer.zig`); G2 deferred (runtime-string form needs a generic compiler mechanism); G3 done (AGENTS gaps refreshed, inline tests added) |
| §S | `*fn` removal (v12 cleanup) | done (S0–S6 — merged via 1a478cd + 5697b89 + follow-ups) |
| §U | unused-builtin sweep (live audit) | U0–U4 done (975910b composite — 15 fns + AsyncIterable); U5 gate pending |

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

- [ ] `std-expansion-tail` merged + pushed (12 deferred modules + F6 `STD-001` + F7 examples-CLI + the in-module tails)
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
- [ ] `scripts/install-hooks.sh --check` green on a fresh clone (all 7
      tracked pre-commit symlinks in place) and `hook-integrity.yml` CI
      job green on every PR
