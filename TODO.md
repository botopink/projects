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

### WAT backend feature extensions (F1–F5)
- [x] **F1 — Anonymous records** — DONE (bot-lang `6afd928`).
  - `lowerRecordLit` (anon constructor, bot-lang `cdae3d9`).
  - `uniqueFieldOffset` heuristic + 4 fixtures (bot-lang `ad31d93`).
  - **F1 tail** (`6afd928`): `ensureAnonRecord(loc, rl)` registers a synthetic `__anon_L{line}_C{col}` entry in `records`+`record_field_types`. `recordTypeOfExpr` gains a `.collection.recordLit` arm that calls it lazily. `val r = record { ... }; r.field` now lowers to a real `i32.load offset=N`. Nested anon literals are registered recursively so `outer.span.start` chains through. 2 more fixtures pinning the typed + nested shapes.
- [x] **F2 — Optionals `?T`** — DONE (bot-lang `8d8fdaf`).
  - Statement-form `(if ...)` lowering (`branchIsVoid` detects void-tailed branches; bare `if` for those, `(if (result i32))` for value-form). This was a pre-existing bug surfaced by F2's null-equality fixtures.
  - `?T` rides the existing 0=null + non-zero=present convention; `?.` guard already shipped in wat-refactor F3.
  - 4 fixtures pinning null/equality/return-paths/branch shapes, RUN LOGs `1`/`0`/`7`/`11`.
- [x] **F3 — String operations** — DONE (bot-lang `64fed8f`).
  - 4 helpers (`__str_concat`/`__str_eq`/`__str_slice` + `.len` prefix read) already existed from wat-refactor. F3 pinned the surface with 5 byte-equal fixtures that run under wasm3 (`.len` after concat, equality drives if-branch, slice with both bounds, etc.). RUN LOGs `8`/`1`/`3`/`6`/`42`.
- [x] **F4 — List literals** — DONE (bot-lang `c63fc89`).
  - `lowerArrayLit` now allocates `(len+1)*4` bytes — slot 0 is the i32 length prefix, slots 1..N hold elements. Same layout as strings; `.len` is uniform across both. 10 pre-existing array snapshots regenerated (length prefix added). 4 new fixtures.
- [x] **F5 — Structured throw/catch** — PARTIAL (bot-lang `eea3ac8`).
  - `@Result`-style try/catch + `try` propagation already lower correctly on WAT (linear-memory `[tag, payload]` pair). 3 fixtures pin the surface.
  - **Manual-unwind throw/catch** (the spec's deeper goal: `throw expr` storing in a global error register + `try { ... } catch (e) { ... }` block-wrapping) is folded into F6's prelude — `__failRaw` lives there and shares the global with the compiled body. RUN LOG empty for now (wasm3 trips on the `@Result` runtime helpers; lands with F6 bodies).

### Runtime support (F6–F7)
- [~] **F6 — `wat_runtime.zig`** — SCAFFOLD (bot-lang `4b1d7f7`).
  - **NEW**: `modules/compiler-core/src/comptime/runtime/wat_runtime.zig` (~210 LOC).
  - Full export surface mapped — every name from the spec's acceptance matrix appears: 4 constructors (`__expr`/`__code`/`Span`/`CustomNode`), 2 error fns (`__failRaw`/`__compilerError`), `__capture` + 10 methods, 8 `__decl` reflection methods (F7 folded in).
  - **Bodies are `unreachable` stubs** today. Remaining work (~190 LOC of body fills) walks the captured-descriptor JSON blob via heap-allocated record records. Each stub method calls `unreachable` so an F8/F9 swap surfaces the gap loudly instead of silently corrupting comptime evaluation.
  - Wired into the test barrel; one unit test verifies every documented export appears in the emitted prelude.
- [~] **F7 — `@Decl` reflection cluster** — SCAFFOLD (folded into F6's commit).
  - 8 method stubs (`__decl__kind`/`name`/`fields`/`methods`/`returnType`/`annotations`/`fail`/`failAt`) part of the F6 prelude. Bodies pending; JSON walker design notes in the scaffold's comments.

### Migration (F8–F10)
- [ ] **F8 — Switch `template_eval.evaluate` to WAT path** — PENDING.
  - **Blocker**: F6 prelude bodies (currently `unreachable`). A swap with stub bodies would crash on first template that calls `e.text()` / `e.parts()` / `e.lookup(...)`.
  - **Plan**: once F6 bodies are filled, add a `Runtime { node, wat }` parameter to `template_eval.evaluate`; `wat` route builds the source as `wat_runtime.prelude(allocator) ++ codegen.emitTemplate(tfn)` and runs through `wasm3_host.runWat`. `node` stays default through one release cycle.
  - **Exit gate**: 9 sublanguage tests + N codegen template tests byte-identical vs v0.beta.20 baseline.
- [ ] **F9 — Switch `decorator_eval.evaluate` to WAT path** — PENDING (gated on F8).
  - Same swap; `__decl` JSON snapshot becomes a WAT struct read via F7's reflection methods.
  - **Exit gate**: every decorator test (R2, onze mocks, #[service] examples) byte-identical.
- [ ] **F10 — Cleanup (DELETE `persistent_node.zig`)** — PENDING (gated on F8+F9).
  - Cannot proceed until F8 and F9 ship the WAT path successfully through a release cycle (zero JS-fallback fires).
  - Final steps once unblocked: delete `persistent_node.zig` + warmup test + `warmPersistentNodeRunner` in `comptime.zig`; remove `node` from required PATH binaries in `AGENTS.md`.
  - **Note**: `codegen/runtime.executeJavaScript` (RUN LOG capture for tests) is OUT OF SCOPE and stays — it runs the USER's program, not comptime.

## Session log — 2026-06-20

Shipped in this auto-mode pass (incrementally, with full test gate each commit):

| Phase | Status | Commit | LOC added | Fixtures |
|---|---|---|---|---|
| F1 tail | ✅ DONE | `6afd928` | ~85 | 2 new |
| F2 | ✅ DONE | `8d8fdaf` | ~70 | 4 new |
| F3 | ✅ DONE | `64fed8f` | docs only | 5 new |
| F4 | ✅ DONE | `c63fc89` | ~10 | 4 new + 10 regen |
| F5 | ✅ DONE (partial) | `eea3ac8` | docs only | 3 new |
| F6 scaffold | ✅ DONE | `4b1d7f7` | ~210 | 1 unit |
| F7 scaffold | ✅ DONE (in F6) | — | (folded) | — |
| F8 / F9 / F10 | ⏳ PENDING | — | gated on F6 bodies | — |

Test gate: **1378/1378 green** at session close (baseline 1359 → +19 new fixtures + 10 regenerated snapshots).

**Honest scope note**: F6 body fills + F8/F9 swaps + F10 deletion are genuinely 4-8 weeks per the original spec. The session shipped the foundation (F1–F5 WAT codegen + F6 export surface) that the remaining work consumes; bodies + swaps are next-session work.

## Discarded sibling spec — supersedes `persistent-erlang-ipc.md`

- [x] **persistent-erlang-ipc — DISCARDED 2026-06-20** (this task supersedes it).
  - Rewrote `tasks/v0.beta.21/specs/persistent-erlang-ipc.md` as a
    "**DISCARDED · NEVER DO**" stub explaining why.
  - **Key rationale**: this task ends with `persistent_node.zig` deleted
    (F8/F9/F10). Adding a sibling `persistent_erlang.zig` would be
    moving the wrong way under the same roadmap.
  - The codegen-test Erlang/BEAM cold-spawn cost the discarded spec was
    trying to solve is already covered by the perf tail on
    `codegen/runtime.zig` (no-I/O early bail + content-keyed output
    cache, shipped in bot-lang `1b2de3c`): warm-run wall clock 3m20s →
    16.6s (~12×).
  - **Do not implement persistent_erlang.zig**. Do not vendor an
    escript runner. Do not re-add `comptime/runtime/erlang.zig` (it was
    deleted by the wasm3-unified-runtime spec on purpose).
  - Override path: if a future profile genuinely re-surfaces this cost,
    extend the output cache key with `erlc --version` first; only after
    that fails should this decision be re-opened via a new ADR.

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
