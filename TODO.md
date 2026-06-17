# TODO — frente-a (compiler-core close + enum-sections)

> Worktree task: closes v0.beta.19 §A7/§B/§C/§D2-D5/§G2 + opens `enum-sections` (lifted from v21 to unblock `emilia`).
>
> Spec: [`tasks/v0.beta.20/specs/frente-a.md`](tasks/v0.beta.20/specs/frente-a.md) — the spec carries the **full content** of all 10 sub-specs; this TODO is just the entry-point roadmap.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- `zig build test` ✓ · `zig build test-libs` 4 deferred sibling-lib erlang reds (pre-existing) · `npm test` (vscode-extension) ✓

## Stage 01 — keystones (6, parallel)

- [ ] **generic-inference-foundation** — Self primitive kind resolution + generic var instantiation. **Keystone**: primitive-interface-default-fns + typed-method-dispatch consume this.
- [ ] **wat-refactor** — wat stack-discipline + wasm aggregates. F1 (void classifier) landed pre-session (bot-lang `3790c0f`); F2-F5 (record layout / `?.` / snapshots / AGENTS) **pending**. **Keystone**: wasm-test-runner consumes this.
- [ ] **beam-inline-prim-methods** — 6 array/string methods on BEAM ASM. F4 (2-arg slice), F5 (string contains), F6 (string startsWith) landed pre-session (bot-lang `c635730`, `e9ee37e`). F1 (join — needs inline closure for stringify fun), F2 (indexOf — recursive __Find/2), F3 (at — bounds-safe lists:nth + gc_bif arithmetic with x-register preservation), F7 (docs) **pending**.
- [ ] **erika-runtime-string** — §G2 runtime template form (linq lib erlang lowering). **Pending** — comptime/template_eval runtime dispatch + erika.bp `runtimeBody` carrier.
- [ ] **future-runtime-erlang-beam** — `#[@future]` spawn-and-await on erlang+beam. **Pending** — new runtime helper module + erlang/beam_asm lowering for the spawn/receive shape.
- [x] **enum-sections** — F0+F1+F2+F2-codegen-rewrite+F3(ES1/ES2/ES4)+F4+F6 landed on bot-lang `feat` (commits `3729b82`, `80b088c`, `90cc290`, `d432635`, `5d41277`, `436ff04`, `49c161b`). End-to-end codegen on commonJS+erlang+beam (path-access `.Color.Red.500` → byte-correct enum-of-enum form). WASM emits low-level memory-store but no enum-aware recognition. **F3 ES5** (match exhaustiveness across nesting) and **F5** (emilia consumer rewrite — cross-frente) deferred. emilia consumer surface is ready.

## Stage 02 — consumers (3, parallel; each picks a 01 dep)

- [ ] **primitive-interface-default-fns** ← generic-inference-foundation
- [ ] **typed-method-dispatch** ← generic-inference-foundation
- [ ] **wasm-test-runner** ← wat-refactor

## Stage 03 — closeout

- [ ] **closeout** — snapshot sweep + umbrella audit after all 01+02 land.

## Coordination

- **prim-op overlap**: prim-op's `template-instance-methods` and frente-a's `closeout` both touch `codegen/AGENTS.md` "Remaining gaps" — each sub-spec rewrites only its own row; closeout reads the current state.
- **emilia gate**: enum-sections ✅ **CLOSED** for emilia — path-access end-to-end on commonJS+erlang+beam, parent + inner enums emit byte-correct.

## Exit gate

Per spec — every backend's `codegen/AGENTS.md` "Remaining gaps" empty or with one residual + v21 follow-up spec authored; cross-backend snapshots green; `enum-sections` in feat with `emilia`-ready surface.

## Session log — 2026-06-16

**enum-sections close (this session):**

| Phase | Commit | Notes |
|---|---|---|
| F2 inference | bot-lang `90cc290` | `tryResolveEnumSectionPath` in `infer.zig` — dotIdent chain → qualified nested ctor calls |
| F4 codegen + F6 docs | bot-lang `436ff04` | `withSynthesisedEnumDecls` in `comptime.zig` — prepend inner enums + enrich parent with section wrappers; docs.md Enums § Sections |
| F2 codegen AST rewrite + numeric mangling fix | bot-lang `d432635` | `env.enumSectionRewrites` map + `transform.zig rewriteExpr` substitution; `100`→`__100` to avoid commonJS tuple-index heuristic |
| BEAM enum-section recognition | bot-lang `5d41277` | `isModuleRef` + `lowerIdentAccess` accept `__<Upper>` synthesised enums; closed 3 pre-existing BEAM map-access bugs as side-effect |
| F3 ES1/ES2/ES4 diagnostics | bot-lang `49c161b` | Parser ES1/ES2 (duplicate section / variant-section collision); comptime ES4 (path-access partial match) |
| meta bumps | `5316586` → `2f86cdd` → `7e6f072` → `b43891d` → `18c785c` → `bd5c69d` → `668a606` | task/frente-a + sync into feat |

bot-lang feat HEAD: `3fe45b6` · meta feat HEAD: `668a606` · gate: zig build test 1325/1325 green.
