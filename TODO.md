# TODO — frente-a (compiler-core close + enum-sections)

> Worktree task: closes v0.beta.19 §A7/§B/§C/§D2-D5/§G2 + opens `enum-sections` (lifted from v21 to unblock `emilia`).
>
> Spec: [`tasks/v0.beta.20/specs/frente-a.md`](tasks/v0.beta.20/specs/frente-a.md) — the spec carries the **full content** of all 10 sub-specs; this TODO is just the entry-point roadmap.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- `zig build test` ✓ · `zig build test-libs` 4 deferred sibling-lib erlang reds (pre-existing) · `npm test` (vscode-extension) ✓

## Stage 01 — keystones (6, parallel)

- [ ] **generic-inference-foundation** — Self primitive kind resolution + generic var instantiation. **Keystone**: primitive-interface-default-fns + typed-method-dispatch consume this.
- [ ] **wat-refactor** — wat stack-discipline + wasm aggregates. **Keystone**: wasm-test-runner consumes this.
- [ ] **beam-inline-prim-methods** — 6 array/string methods on BEAM ASM.
- [ ] **erika-runtime-string** — §G2 runtime template form (linq lib erlang lowering).
- [ ] **future-runtime-erlang-beam** — `#[@future]` spawn-and-await on erlang+beam.
- [~] **enum-sections** — F0 (parser/decls.zig + ast.zig `EnumSection`) and F1 (comptime desugar in `registerEnum` → mangled inner enums + wrapper variants) landed on bot-lang `task/frente-a` (commits `3729b82`, `80b088c`). F2 (path access `.Outer.Inner` in `infer.zig` + match exhaustiveness across nesting), F3 (ES1–ES6 diagnostics), F4 (cross-backend snapshot sweep), F5 (emilia consumer rewrite), F6 (docs.md Enums section) **pending**. **Cross-frente unblock**: `ecosystem/emilia` depends on this — F2 is the next hard prerequisite for first consumer use.

## Stage 02 — consumers (3, parallel; each picks a 01 dep)

- [ ] **primitive-interface-default-fns** ← generic-inference-foundation
- [ ] **typed-method-dispatch** ← generic-inference-foundation
- [ ] **wasm-test-runner** ← wat-refactor

## Stage 03 — closeout

- [ ] **closeout** — snapshot sweep + umbrella audit after all 01+02 land.

## Coordination

- **prim-op overlap**: prim-op's `template-instance-methods` and frente-a's `closeout` both touch `codegen/AGENTS.md` "Remaining gaps" — each sub-spec rewrites only its own row; closeout reads the current state.
- **emilia gate**: enum-sections is on the critical path for the `ecosystem` worktree; prioritize if `ecosystem` agent picks up.

## Exit gate

Per spec — every backend's `codegen/AGENTS.md` "Remaining gaps" empty or with one residual + v21 follow-up spec authored; cross-backend snapshots green; `enum-sections` in feat with `emilia`-ready surface.
