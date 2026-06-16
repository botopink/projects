# v0.beta.20 — closing the v0.beta.19 deferrals + opening ecosystem expansion

> v0.beta.19 closed every recorded gap in the **language itself** — frente-c
> (distribution) + recursive-test-gate + ci-pipelines-green + std-expansion
> (7/19 modules) all merged; frente-a partial (§S/§U/§A6/§D1/§G1/§G3) merged
> with §A7/§B/§C/§D2-D5/§G2 explicitly deferred; frente-b authored its rules
> contract but left F4F/F4G/F4C/F4I/F5/F6/§T pending; prim-op-annotation
> shipped Family 1 erlang (9/19) but Family 1 BEAM/wat + Family 2/3 across
> 4 backends pending; std-expansion-tail landed §A2 + 8 modules with 9
> phases + 14 sub-deferrals tail open.
>
> **v0.beta.20 closes them all** as a single closing wave + opens the
> *ecosystem-expansion* line with one keystone (`emilia`, the third
> sub-language). **6 frente files** in `tasks/v0.beta.20/specs/`, each
> consolidating its complete frente plan (keystones + consumers +
> closeout) into a single document. 27 sub-specs total — readable
> top-to-bottom within each frente's file.

## Layout

```
tasks/v0.beta.20/specs/
├── frente-a.md       compiler-core close (10 sub-specs)
├── prim-op.md        annotation-grammar extension (9 sub-specs)
├── std-tail.md       std-expansion finish (2 sub-specs, flat)
├── frente-b.md       rules + tooling close (3 sub-specs)
├── ci-tail.md        CI cleanup (2 sub-specs)
└── ecosystem.md      emilia (1 sub-spec)
```

One file per frente. Inside each, sub-specs are ordered by
**dependency stage** (when applicable):

- **Stage 01 — keystones** — independent, parallel.
- **Stage 02 — consumers** — each picks a 01-keystone as its prerequisite.
- **Stage 03 — closeout** — audit + final sweep after every 01 + 02 lands.

Flat frentes (`std-tail`, `ecosystem`) omit the stage labels.

## Frente count summary

| Frente | Stages | Sub-specs | What it closes (from v0.beta.19) |
|---|---|---|---|
| [frente-a](specs/frente-a.md) | 3 | 10 | §A7 BEAM templates · §B generic inference · §C wasm aggregates + wat refactor · §D2-D5 cross-backend parity · §G2 erika runtime-string · §D6 doc tail · §D4 future erlang/beam · wasm test runner · **enum-sections** (nested enum grouping with path access — lifted from v21 to unblock emilia) |
| [prim-op](specs/prim-op.md) | 3 | 9 | Family 1 BEAM+wat · Family 2 BEAM+wat · Family 3 `@block` 4 backends · `External.<Target>` lib sweep · `when($argc==N)` retirement · `fn-param-default-expansion` AST · §A2 BEAM+wat tail · AGENTS resync |
| [std-tail](specs/std-tail.md) | flat | 2 | std-expansion-tail's 9 phases + 14 sub-deferrals · Option.expect<T> |
| [frente-b](specs/frente-b.md) | 2 | 3 | F4F/F4G/F4C/F4I/F5/F6 rules-tooling close · `break :label` 4 backends · `----- RUN LOG -----` §T |
| [ci-tail](specs/ci-tail.md) | 2 | 2 | (01) v19 ci-pipelines-green shims drop + `test-libs.sh` consolidation · (02) backends-parity erlang BIF directive + windows-2022 snap normalisation + shell-var fix |
| [ecosystem](specs/ecosystem.md) | flat | 1 | **opens** v0.beta.20 ecosystem-expansion line — `emilia` (CSS-in-bp, type-safe Token enum, cross-frente dep on `enum-sections` from frente-a) |

Total: **27 sub-specs** across **6 frente files**. Every v0.beta.19 row in
[v19/status.md](../v0.beta.19/status.md) flagged "deferred" / "pending"
has a corresponding sub-spec here.

## Order — across frentes

```text
frente-a:
  ┌─ 01 keystones (parallel)
  │    generic-inference-foundation, wat-refactor,
  │    beam-inline-prim-methods, erika-runtime-string,
  │    future-runtime-erlang-beam, enum-sections
  ├─ 02 consumers (parallel — each picks a 01 dep)
  │    primitive-interface-default-fns ← generic-inference-foundation
  │    typed-method-dispatch           ← generic-inference-foundation
  │    wasm-test-runner                ← wat-refactor
  └─ 03 closeout
       closeout (snapshot sweep + umbrella audit)

prim-op:
  ┌─ 01 keystones (parallel)
  │    family-2-beam-wat-runtime-ops, family-3-block-builtin,
  │    template-instance-methods, external-target-libs-migration,
  │    fn-param-default-expansion
  ├─ 02 consumers (parallel — each picks 01 deps)
  │    family-1-beam-wat-prim-methods ← family-2 + external-target + fn-param
  │    when-argc-removal              ← fn-param + external-target
  │    annotation-tail (§A2)          ← family-1/2/3 + template-instance-methods
  └─ 03 closeout
       agents-md-resync

std-tail (flat — both parallel):
  followup, option-expect

frente-b:
  ┌─ 01 keystones (parallel)
  │    rules-tooling-close, test-run-log
  └─ 02 consumers
       codegen-break-label ← rules-tooling-close

ci-tail:
  01-cleanup (drops v19 shims + consolidates test-libs.sh)
    └─▶ 02-backends-parity (erlang BIF + windows-2022 combined)

ecosystem (cross-frente dep):
  emilia ← enum-sections (in frente-a.md)
```

Frentes are file-disjoint at the directory level — they can proceed in
parallel on per-frente worktrees with no cross-merge contention. Two
cross-frente coordination points:

1. **ecosystem → frente-a**: `emilia` blocks on `enum-sections` (lands inside `frente-a.md`).
2. **prim-op → frente-a**: `prim-op` `template-instance-methods` touches
   the same `codegen/AGENTS.md` "Remaining gaps" row that `frente-a`
   closeout audits. Resolution: each sub-spec rewrites only its own
   row; the closeout reads what's there at close-out time.

## Non-goals (explicit)

- **One language extension, scoped.** `enum-sections` (inside `frente-a.md`)
  is the only net-new language surface in v20 (lifted from v21 because
  the ecosystem keystone needs it). All other sub-specs are closing —
  most delete arms / consume existing AST nodes.
- **No backward-compatibility shims** for retired surfaces (`when($argc==N)`,
  the legacy `#[@external(target,…)]` form, dead builtins). Hard deletes
  with live grep evidence in commit bodies — same discipline as v19 §S/§U.
- **No bpmp / distribution change.** ci-tail is workflow-YAML only;
  emilia rides the existing `bpmp install <lib>` path.
- **No new framework-coupling fan-out.** Ecosystem libs (here: emilia)
  may make *generic* hooks in an existing framework (jhonstart gains a
  `#[<name>(...)]` annotation hook + `[<name>]={...}` html attribute
  hook) — both must be framework-agnostic; the framework cannot grow
  emilia-specific branches.

## Goal

After v0.beta.20 lands:

- `zig build test` + `zig build test-libs` + `botopink-lib-test` +
  `zig build test-vscode` green across every backend, **including
  wasm via wasmtime**.
- Zero `when($argc==N)` literals; zero `#[@external(target,…)]` literals
  outside CHANGELOG.md; zero `emitResultOptionOp` / `emitPrimMethod`
  arms (everything annotation-driven via the unified prim-op template).
- Every backend's `codegen/AGENTS.md` "Remaining gaps" row narrows to
  empty or one residual item with a v21 follow-up spec authored.
- `botopink test` emits `----- RUN LOG -----` per test on all 4
  backends; `break :label` honors the label on all 4 backends.
- `bpmp install emilia` resolves from the new submodule's `feat`
  tag; `examples/emilia-card/` renders a small jhonstart page with
  collected CSS via `renderToString + emilia.flush()`.
- `enum-sections` lands in `feat`; `emilia` Token enum uses the
  natural path access (`.Color.Red.500`, `.Pad.X.4`) end-to-end.
- Every CI matrix job green across the 7 repos — no `allow_fail` rows
  on the windows-2022 / erlang-shadowed-BIF axes.
- All AGENTS.md updated in the same commit as the code (memory rule).
- 7 remotes (meta + 6 submodules — now **7** with emilia) all on
  unified `feat` heads.

After this set lands, every spec authored in v0.beta.12–v0.beta.19 is
fully closed, and the ecosystem-expansion line is open with one
keystone shipped.
