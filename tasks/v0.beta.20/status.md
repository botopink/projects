# v0.beta.20 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

| Frente / spec | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [emilia](specs/emilia.md) | `emilia` | `task/emilia` (seed `f3b6ef7`) | `.tasks/emilia/` (to seed) | **seeded, not committed** — repo `botopink/emilia` created (default `feat`); submodule wired but NOT committed in meta; spec authored in `tasks/v0.beta.20/specs/emilia.md`; 1 edit `jhonstart` (attr carrier + `#attr` branch); pending worktree open |
| [std-expansion-tail-followup](specs/std-expansion-tail-followup.md) | `std-expansion-tail-followup` | (pending — new worktree to seed) | — | pending |
| [option-expect](specs/option-expect.md) | `option-expect` | (pending — likely lands inline in std-expansion-tail-followup's worktree before P17) | — | pending |
| [prim-op-annotation-tail](specs/prim-op-annotation-tail.md) | `prim-op-annotation-tail` | (pending — file-disjoint with std-tail-followup; own worktree) | — | pending |
| [frente-a-tail](specs/frente-a-tail.md) | `frente-a-tail` | (pending — own worktree; sequential on `comptime/infer.zig` with std-tail-followup) | — | pending |
| [frente-b-rules-tooling](../v0.beta.19/specs/frente-b-rules-tooling.md) | `frente-b-rules-tooling` | `task/frente-b-rules-tooling` (carry-over from v0.beta.19) | `.tasks/frente-b-rules-tooling/` | pending — same spec as v0.beta.19; reopened on v0.beta.20 to close the Rules track + §E/§F/§T |

## std-expansion-tail-followup — per-phase state

| Phase | Description | State |
|---|---|---|
| P1 | §A3 `#[@result] declare fn` template-owned wrapper (parser R1 relax + infer skip auto-wrap + `result-template-shape-mismatch` diagnostic + 2 fixtures) | pending |
| P2 | `time.formatIso8601` backfill — Node `new Date($0).toISOString()` + Erlang `calendar:system_time_to_rfc3339` via §A2 | pending |
| P3 | `asserts.matches` backfill — pure-bp wrapper over the landed `regex.matches` | pending |
| P4 | F5.json — `JsonValue` enum + `parse`/`stringify`/`stringifyPretty` (gated on P1) | pending |
| P5 | F7.array_ext — 15 methods on `interface Array<T>` in `primitives.d.bp` | pending |
| P6 | F7.string_ext — 11 methods on `interface String` in `primitives.d.bp` | pending |
| P7 | F7.unicode tails — `codepoints` + `normalize(NormalizationForm)` | pending |
| P8 | F7.regex tails — `record Match` + `match` + `matchAll` | pending |
| P9 | F1 STD-001 `std-unsupported-on-target` diagnostic + 2 fixtures (target threaded through compile → analyzeModule → analyzeSource → Env) | pending |
| P10 | F2 sidecar shipping infra (`lib_test.zig` copy step + smoke fixture) | pending |
| P11 | `time.sleep` + `asserts.throws` backfill (gated on P1) | pending |
| P12 | `random.seed` + `crypto.randomBytes` (gated on P10 sidecar) | pending |
| P13 | F6.env tails — `args()` + `vars()` | pending |
| P14 | F6.os tails — `userInfo()` + `eol()` | pending |
| P15 | F6.fs — heavy surface, `@Result` family + sidecar (gated on P1 + P10) | pending |
| P16 | F8.http — Promise wrapper + harness fixture (gated on P10) | pending |
| P17 | F4.random.shuffle — gated on `option-expect` spec landing | pending |
| P18 | F9 examples-CLI "Real-world examples" + per-target coverage table in `codegen/AGENTS.md` + CHANGELOG per-wave entries | pending |
| P19 | Final unification sweep + push to origin/feat (bot-lang push requires explicit user authorization for the shared-branch policy) | pending |

## prim-op-annotation-tail — per-backend state

| Backend | §A2-style per-callee templates | §A6 method dispatch | State |
|---|---|---|---|
| commonJS | ✓ (landed in std-expansion-tail `a7c6d07`) | ✓ (existing `tryEmitPrimAnnotation`) | done |
| erlang | ✓ (landed in std-expansion-tail `52d6101`) | ✓ (existing) | done |
| BEAM | ✗ | partial (§A6 closed, 4 inline arms) | pending |
| wat | ✗ | not wired (3/4 backends viable without it per v0.beta.19 §A7 deferral) | pending |

## frente-a-tail — per-track state

| Track | Description | State |
|---|---|---|
| §A7 | BEAM bytecode-template gate (1/4 backends — closes §A6 carve-out) | pending |
| §B | generic-inference (inline tests in generic modules + erika-LINQ + `registerStdlib` gap) | pending |
| §C | wasm-aggregates + wat refactor (deep wat refactor) | pending |
| §D2 | beam_asm `from "std"` qualified-call lowering | **DONE** (upstream `c5a4ad3` / `fbe6b62`) |
| §D3 | cross-module beam_asm parity | pending |
| §D4 | `#[@future]` erlang/beam lowering | pending |
| §D5 | per-target coverage matrix (will fold into std-tail-followup P9 STD-001 enforcement once it lands) | pending |
| §G2 | erika runtime-string interpolation (generic compiler mechanism) | pending |

## Carry-forward from v0.beta.19

| v0.beta.19 spec | State at v0.beta.20 open | Where it goes |
|---|---|---|
| `frente-a-compiler` | partial (§S/§U/§A6/§D1/§G1/§G3 done; §A7/§B/§C/§D2-D5/§G2 deferred) | `frente-a-tail` (v0.beta.20 spec) |
| `frente-b-rules-tooling` | pending (Rules track + §E/§F/§T) | `frente-b-rules-tooling` (carry — same spec file, v0.beta.20 worktree) |
| `frente-c-distribution` | **merged+pushed** | closed |
| `prim-op-annotation` | partial (Family 1 erlang 9/19 done; BEAM/commonJS/wat deferred) | `prim-op-annotation-tail` (v0.beta.20 spec — closes BEAM/wat after std-tail-followup landed the commonJS/erlang twin) |
| `std-expansion` | **merged+pushed** | closed |
| `std-expansion-tail` | partial (F0 + §A2 commonJS+erlang twin + 4 F4 in-module tails + 8 net-new modules landed in 14 commits on bot-lang local feat) | `std-expansion-tail-followup` (v0.beta.20 spec — closes the 9 remaining phases + 14 sub-deferrals) |
| `recursive-test-gate` | **merged+pushed** | closed |
| `ci-pipelines-green` | **CI-YAML scope done + pushed** (2 deferred reds out of scope) | closed (the 2 deferred reds carry to `frente-a-tail` §B / `frente-c-distribution` follow-up) |

## Done = the whole set ships

- [ ] `emilia` keystone closed + the sibling repo wired + jhonstart attr-carrier integration green
- [ ] `std-expansion-tail-followup` P1–P19 ticked + pushed to feat across all 7 repos
- [ ] `option-expect` merged + pushed (single commit)
- [ ] `prim-op-annotation-tail` BEAM + wat dispatch cells parity-green on `botopink-lib-test --lib std --target beam,wasm`
- [ ] `frente-a-tail` §A7/§B/§C/§D3-D5/§G2 all closed or explicitly deferred to v0.beta.21 (deferral list pinned in this status's per-track table)
- [ ] `frente-b-rules-tooling` Rules track §0–§4 + §E + §F + §T merged + pushed
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test --target all` + `zig build test-vscode` all green across the v0.beta.20 close
- [ ] All AGENTS.md updated in the same commit as the code (memory rule)
- [ ] Memory updates — flip `project_v0beta19_std_expansion_tail.md` to `DONE+PUSHED` (after P19); seed `project_v0beta20_state.md` capturing the close-of-set
