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
- [~] **template-instance-methods** — F1-commonJS + F2-erlang + inference fix LANDED via `Array.zip` surface (bot-lang `bdebded` + infer fix):
  - F2-erlang: already worked through existing dispatch (`collectIfaceErlangDispatch` indexes every method + `tryEmitPrimAnnotation` renders `$self`/`$N`); `lists:zipwith(...)` RUN LOG green
  - F1-commonJS: `emitInterface` now patches `Owner.prototype.<m>` for non-`default fn` instance methods with template-form `@External.Node` (the 1-arg `module="" + symbol=<template>` case takes precedence over the §A4 native-prototype skip); template-rendered body inlined; RUN LOG green
  - Inference fix: `findInterfaceDefaultFn` (`comptime/infer.zig`) now matches non-default-fn instance methods with template-form annotation so `usedAssocInterfaces` triggers Array splicing for `xs.zip(ys)` alone — no `xs.isEmpty()` workaround needed
  - F3-beam: still emits `%% unresolved method call: zip/2` (deferred — `beam_asm.zig` template-form path bails at lines 2372-2373 with "BEAM has not migrated"; same architectural blocker as family-2/3 BEAM)
  - F4-wat: deferred per spec
- [x] **external-target-libs-migration** — F0–F4 + F5-partial done. **Landed this session**:
  - onze `641e344 → 64fe0d9` (8 host cells)
  - rakun `d7582cc → 4e8d4d3` (17 host cells)
  - jhonstart `7b87a59 → 2ddda6a` (3 hooks)
  - erika: no legacy form to migrate
  - bot-lang std `f57a8cd → c828308`: base64/time/unicode (the 3 non-when-argc files)
  - meta bumps `0faa003` + `6875657` pushed
  - F5/F6/F7 (compiler retirement + EX1 diag + remaining docs) still DEFERRED: 5 std files (`crypto`/`env`/`os`/`process`/`regex`) ship the legacy form via `when(argc==N):` clauses; compiler retire must follow `when-argc-removal`.
- [~] **fn-param-default-expansion** — AST plumbing pre-landed via `4c2e62c` + `5f0f1d9`. **F0 + F2-partial LANDED this session**:
  - **F0** (bot-lang `93cad6f`, meta `f899164`): split `libs/std/src/builtins_fns.d.bp` carrying `todo`/`panic` as annotated `declare fn` (the FFI form parses as `FnDecl`). `registerStdlib` parses it; `env.stdlibFnDecls` carries every entry; `compile` + `compileTypesOnly` merge into transform's `fn_decls` so `expandTrailingDefaults` injects the trailing literal default at every bare `todo()` / `panic()` call site. 10 erlang snapshots regen (binary-string form per spec F0-erl). `field<T,F>` / `trap` / `emit` / `module` / `getContex<T>` stay doc-only in `builtins.d.bp` (no defaults, parse-blockers via keyword/generic).
  - **F2 partial** (bot-lang `5666500`): catalog D1–D6 in `comptime/diagnostics.zig`; D5 (`fn-param-default-trailing-only`) at `parseParamList` + D2 (`fn-param-positional-after-named`) at `parseCallArgs` with new `ParseErrorType` variants + `print.errorMessages` entries. D1/D3/D4/D6 infer-time wording **deferred** until F1's expansion path reaches instance methods (the wording shape matches the spec's "...requires N arguments..." only after default injection has run).
  - **F1 DEFERRED** (receiver-bound default rewrite — `Array.slice` / `String.slice`): substantial architectural work because instance method dispatch bypasses transform's `fn_decls` path. Requires either transform-side instance-method default injection (look up the receiver's interface method, run `expandTrailingDefaults` analogue) OR codegen-side injection in each backend's `tryEmitPrimAnnotation` template renderer (`$N` for out-of-range indices renders the rebound default Expr with `self` → receiver substitution via a new `comptime/expr_walk.zig` visitor). Both paths touch all 4 backends; family-2/3 BEAM+wat block parallel-work-spec anyway.
  - **F3/F4/F5/F6 DEFERRED**: F3 (slice surface migration) needs F1. F4 (record/struct/enum constructor defaults) is a sibling rewrite — doable without F1 but punted to keep the spec checklist coherent. F5/F6 are tests + docs.

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
