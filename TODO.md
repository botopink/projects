# TODO — prim-op (annotation-grammar extension + family migration)

> Worktree task: closes v0.beta.19 `prim-op-annotation` partial — Family 1 BEAM+wat + Family 2/3 across 4 backends + lib migration + grammar retirement.
>
> Spec: [`tasks/v0.beta.20/specs/prim-op.md`](tasks/v0.beta.20/specs/prim-op.md) — full content of all 9 sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `6875657` · bot-lang: `c828308`
- **annotation-tail (§A2) already DONE** in `task/prim-op-template-fix` (merged): `@External.<Variant>` arity-branched dispatch + `$stringify` Ctx pair on all 6 erlang Ctx structs + `fnAtom` widening for leading-`_` quoting + 27 snapshot regenerations.

## Stage 01 — keystones (5, parallel)

- [ ] **family-2-beam-wat-runtime-ops** — BEAM + wat dispatch infra (erlang `7f8f259` + commonJS `f9918b1` already landed). **BLOCKED on backend architectural prereqs**: wat backend uses linear-memory `i32.store` + heap-ptr bookkeeping with stateful `_resN` locals + inline lambda body splicing — template `(struct.new $bp_result_ok $0)` from the spec sketch assumes Wasm GC struct types not in current emitter. BEAM-asm has the same issue (bytecode + register alloc, not text). Needs either a wasm-GC migration OR a structured emitArg callback DSL extending `primOpTemplate` first.
- [ ] **family-3-block-builtin** — `@block` across every backend. Same architectural prereq as family-2 for BEAM+wat (`$body` needs structured stmt-list emit, not text substitution).
- [ ] **template-instance-methods** — instance method template path on every backend.
- [x] **external-target-libs-migration** — F0–F4 + F5-partial done. **Landed this session**:
  - onze `641e344 → 64fe0d9` (8 host cells)
  - rakun `d7582cc → 4e8d4d3` (17 host cells)
  - jhonstart `7b87a59 → 2ddda6a` (3 hooks)
  - erika: no legacy form to migrate
  - bot-lang std `f57a8cd → c828308`: base64/time/unicode (the 3 non-when-argc files)
  - meta bumps `0faa003` + `6875657` pushed
  - F5/F6/F7 (compiler retirement + EX1 diag + remaining docs) still DEFERRED: 5 std files (`crypto`/`env`/`os`/`process`/`regex`) ship the legacy form via `when(argc==N):` clauses; compiler retire must follow `when-argc-removal`.
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
