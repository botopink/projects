# templates-decorators-botopink-native

> Spec: [`tasks/v0.beta.21/specs/templates-decorators-botopink-native.md`](../../tasks/v0.beta.21/specs/templates-decorators-botopink-native.md) — full content lives there.

## Baseline

- meta `feat`: `c6cff7d` (post wat-refactor F2+F3+F4+F5 + perf cache + beam-inline-prim-methods merge).
- bot-lang `feat`: `7fd5099` (post wat-refactor + perf-cache + beam-inline merge).
- **`wasm3-unified-runtime` landed** (meta `5f627d1` / bot-lang `1749054` + perf follow-ups). `wasm3_host.runWat`, `wat_to_wasm.compile`, and the unified comptime pipeline are present. Unblocked.
- **`wat-refactor` landed on feat** (bot-lang `1b2de3c` perf + `0d220f7` F2/F3/F4/F5). My record field access by name (via `local_types` + `recordTypeOfExpr` recovery) and `?.` guard land in `wat.zig`. **This complements F1's `uniqueFieldOffset` heuristic — both stay; reconcile after merge.**

## Phases (from spec F0–F10)

- [x] **F0 — Audit template/decorator feature set** — done 2026-06-19.
  - 20 bodies enumerated (4 templates + 16 decorators) across `repository/{botopink-lang/examples,erika,jhonstart,onze,rakun}/src/*.bp`.
  - Closed feature set: `anon-record` (incl. nested) + `opt-null` + `list-literal` + `str-{concat,len,slice,eq,split,trim}` + `string-multiline` + `cond-if` + `iter-for` + `method-on-record` + `interp-q` + `e.*` (10 capture methods) + `decl.*` (8 reflection methods) + `throw` (via `__failRaw`).
  - Out-of-set: NONE. JS fallback in F8/F9 is a transition safety net, not load-bearing.
  - Audit table + acceptance matrix: [`tasks/v0.beta.21/specs/templates-decorators-botopink-native-audit.md`](../../tasks/v0.beta.21/specs/templates-decorators-botopink-native-audit.md).

### WAT backend feature extensions (F1–F5, ~codegen/wat.zig MUTATED + tests)
- [~] **F1 — Anonymous records** (~250 LOC additions, 6 fixtures byte-equal vs hand-written WAT)
  - **Constructor** (bot-lang `cdae3d9`): `lowerRecordLit` mirrors `lowerRecordCtor`; 2 anon fixtures + 8 backend snaps.
  - **Field-by-name read** (bot-lang `ad31d93`): `uniqueFieldOffset(name)` scans `records` registry, returns the unambiguous slot offset; `lowerIdentAccess` consults it before the optional-chain stub. 2 more fixtures (`record_field_access_via_unique_name`, `record_returned_then_field_read_on_call_result`). 6 pre-existing wasm snapshots that previously snapped the `i32.const 0 ;; field access .X` stub now load real values; RUN LOG rows that depended on those reads moved from `0` to the correct value (dispatch_auto_applied 0→2, dispatch_multi_module_* 0→3, struct_implement_fields_round_trip 0→5).
  - **After merging wat-refactor**: my `recordTypeOfExpr` (via `local_types`/`self_type`) AND `uniqueFieldOffset` co-exist in `lowerIdentAccess`. Order: typed recovery first (more specific), uniqueFieldOffset fallback (covers anon + ambiguous-name-with-unique-resolution cases).
  - **Status**: 4/6 fixtures landed. Gap: anon records bound to a local lose field identity (no synthetic registry entry yet); a true template body with a mixed `anon { kind: …, code: … }` literal can't have its fields read by name through the heuristic. Tracked for F1's last increment (synthetic anon-record registration at lowering time).
- [ ] **F2 — Optionals `?T`** (~120 LOC, 4 fixtures)
- [ ] **F3 — String operations** (concat, length, slice, equal — ~200 LOC, 5 fixtures)
- [ ] **F4 — List literals** (~150 LOC, 4 fixtures)
- [ ] **F5 — Structured throw/catch** (manual unwind protocol — wasm3 doesn't impl exceptions proposal yet — ~250 LOC, 3 fixtures + 2 round-trips against JS)

### Runtime support (F6–F7)
- [ ] **F6 — `wat_runtime.zig`** (NEW, ~400 LOC Zig emitting ~300 LOC WAT)
  - Mirrors `template_eval.zig`'s JS prelude: `__expr`, `__code`, `Span`, `CustomNode`, `__failRaw`, `__capture` (with `text/parts/source/context/lookup/bindings/build/custom/fail/failAt` methods).
- [ ] **F7 — `@Decl` reflection cluster** (~100 LOC additions to `wat_runtime.zig`)
  - JSON-decoded handle: `kind`, `name`, `fields`, `methods`, `returnType`, `annotations`, `fail()`, `failAt()`.

### Migration (F8–F10)
- [ ] **F8 — Switch `template_eval.evaluate` to WAT path** (`template_eval.zig` MUTATED)
  - `commonJS.emitFnJs(...)` → `wat.codegenEmitTemplate(...)`.
  - JS prelude → WAT prelude from `wat_runtime.zig`.
  - Fallback to JS path preserved through 1 release cycle.
  - Exit gate: 9 sublanguage tests + N codegen template tests byte-identical vs v0.beta.20 baseline.
- [ ] **F9 — Switch `decorator_eval.evaluate` to WAT path** (`decorator_eval.zig` MUTATED)
  - Same swap. `__decl` handle becomes WAT struct.
  - Exit gate: every decorator test (R2, onze mocks, #[service] examples) byte-identical.
- [ ] **F10 — Cleanup**
  - DELETE `persistent_node.zig` + runner.
  - DELETE `warmPersistentNodeRunner` in `comptime.zig`.
  - Remove `_warmup` Node test in both test_root warmups.
  - `AGENTS.md` (root): `node` removed from required PATH binaries. Mention only as optional for running user's generated commonJS output.
  - `comptime/AGENTS.md`, `comptime/docs.md`, `codegen/AGENTS.md` narrative updates.
  - `CHANGELOG.md` + `tasks/v0.beta.21/status.md`.
  - Exit gate: `grep -r "persistent_node\|process\.run.*node\|spawn.*node" modules/compiler-core/src` returns zero (excluding comments / docs / `codegen/runtime.executeJavaScript`).

## Out of scope (separate concerns)

- `codegen/runtime.executeJavaScript` / `executeErlang` / `executeBeamAsm` — they run the USER's PROGRAM (RUN LOG capture), not comptime. They keep their current spawn paths after this spec.
- Templates that exercise features outside the F0 audit set (async, generators, complex trait dispatch) — those hit the JS fallback. Future spec widens if the use case materialises.

## Exit gate

- F0 audit committed; every template body classified.
- F1–F7 codegen extensions byte-equal in pinning fixtures.
- F8 + F9 byte-identical against v0.beta.20 baseline.
- After 1 release cycle of zero JS-fallback fires, F10 deletes the fallback + `persistent_node.zig`.
- `node` removed from required PATH binaries.
- Clean Docker container with only the compiler binary (no `node`/`erl`/`wasmtime`) successfully compiles a template-heavy `.bp` to identical output.
- AGENTS.md per affected module updated in the same commit as code.

## Block — cleared

`wasm3-unified-runtime` landed (meta `5f627d1` / bot-lang `1749054` + perf follow-ups). All three prerequisites available: `wasm3_host.runWat()`, `wat_to_wasm.compile()`, unified comptime pipeline (Runtime enum collapsed).
