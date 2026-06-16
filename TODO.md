# TODO — prim-op (annotation-grammar extension + family migration)

> Worktree task: closes v0.beta.19 `prim-op-annotation` partial — Family 1 BEAM+wat + Family 2/3 across 4 backends + lib migration + grammar retirement.
>
> Spec: [`tasks/v0.beta.20/specs/prim-op.md`](tasks/v0.beta.20/specs/prim-op.md) — full content of all 9 sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **annotation-tail (§A2) already DONE** in `task/prim-op-template-fix` (merged): `@External.<Variant>` arity-branched dispatch + `$stringify` Ctx pair on all 6 erlang Ctx structs + `fnAtom` widening for leading-`_` quoting + 27 snapshot regenerations.

## Stage 01 — keystones (5, parallel)

- [ ] **family-2-beam-wat-runtime-ops** — BEAM + wat dispatch infra (erlang `7f8f259` + commonJS `f9918b1` already landed; complete the other two backends).
- [ ] **family-3-block-builtin** — `@block` across every backend.
- [ ] **template-instance-methods** — instance method template path on every backend.
- [~] **external-target-libs-migration** — F0–F4 done (onze `64fe0d9` · rakun `4e8d4d3` · jhonstart `2ddda6a` migrated + pushed; erika has no legacy form; bot-lang examples/tests sweep clean). F5–F7 (compiler retirement + EX1 + docs) DEFERRED — 8 files in `libs/std/src/` (`base64`/`crypto`/`env`/`os`/`process`/`regex`/`time`/`unicode`) still ship `#[@external(target,…)]` (mostly with `when(argc==N):` clauses); compiler retire must follow `when-argc-removal`.
- [ ] **fn-param-default-expansion** — F0–F6 (builtins.d.bp split + receiver-bound default + 4 diagnostics + when-argc consumers). AST plumbing landed via `4c2e62c` + `5f0f1d9`. **Unblocks**: when-argc-removal + ci-tail catalog extension.

## Stage 02 — consumers (2, parallel; each picks 01 deps)

- [ ] **family-1-beam-wat-prim-methods** ← family-2 + external-target + fn-param. Family 1 erlang 9/19 landed via `64a3436`; complete BEAM + wat.
- [ ] **when-argc-removal** ← fn-param + external-target. Retire grammar after every consumer migrates.

## Stage 03 — closeout

- [ ] **agents-md-resync** — umbrella docs sweep across every AGENTS.md under `modules/compiler-core/`.

## Coordination

- **frente-a overlap**: `template-instance-methods` rewrites its `codegen/AGENTS.md` "Remaining gaps" row; frente-a `closeout` reads-and-audits — no conflict per the README protocol.
- **annotation-tail §A2 BEAM+wat user-template dispatch**: deferred from prim-op-template-fix (only erlang + commonJS have the `$stringify` Ctx pair now). Optional pickup if a template surface emerges.

## Exit gate

Per spec — zero `when($argc==N)` literals; zero `#[@external(target,…)]` outside CHANGELOG; zero `emitResultOptionOp`/`emitPrimMethod` arms; every backend annotation-driven via unified template.
