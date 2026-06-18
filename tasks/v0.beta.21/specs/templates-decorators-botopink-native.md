# templates-decorators-botopink-native — execute template/decorator bodies via the WAT backend instead of JavaScript-in-Node

**Slug**: templates-decorators-botopink-native
**Depends on**: `wasm3-unified-runtime` (must land first — provides the embedded wasm3 + wat→wasm Zig converter that this spec relies on as the **execution mechanism**).
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/wat.zig` (MUTATED, ~2126 → ~3400 LOC). The WAT backend is extended to produce template-eligible output: anonymous records (CustomNode/Span literals), optional `?T` (the `ref: null` pattern), throw/catch lowering, list literals with iteration, string concat/length/slice. Today this backend covers ~60% of the surface area of `commonJS.zig`; this spec brings it to ~95% — enough that every template/decorator body the codebase emits today lowers byte-equivalent to WAT.
  - `repository/botopink-lang/modules/compiler-core/src/codegen/wat_runtime.zig` (NEW, ~400 LOC). The runtime support module embedded into each generated WAT module: `__capture` (the capture object exposing `text/parts/source/context/lookup/bindings/build/custom/fail/failAt`), `__expr` (value lift wrapper), `__code` (source-text wrapper), `Span` / `CustomNode` (anonymous-record helpers), `__failRaw` (throw protocol with structured payload), `__decl` (the `@Decl` reflection cluster). All emitted as WAT functions with linear-memory-allocated heap objects. Mirror of `template_eval.zig`'s `prelude` string but as a Zig string of WAT source.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/template_eval.zig` (MUTATED) — `evaluate()` (line 292) switches from `commonJS.emitFnJs` → `node` spawn / `persistent_node.eval` to `wat.codegenEmitTemplate` → `wat_to_wasm.compile` → `wasm3_host.runWat`. The JS prelude (`__expr`, `__code`, `Span`, `CustomNode`, `__failRaw`, `__capture`) is replaced by the WAT prelude from `wat_runtime.zig`. `parseOutcome` stays — the JSON output format on stdout is preserved exactly (so the result-parsing contract doesn't change).
  - `repository/botopink-lang/modules/compiler-core/src/comptime/decorator_eval.zig` (MUTATED) — same swap as `template_eval.zig`. Replaces `commonJS.emitFnJs` of the decorator body with `wat.codegenEmitDecorator`. The `__decl(...)` handle object (today bound in JS) becomes a WAT struct populated from the same `handleJson` argument.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/runtime/persistent_node.zig` (DELETED). After templates and decorators move off Node, this file has zero remaining consumers (`runtime/node.zig` was already deleted by `wasm3-unified-runtime`; `codegen/runtime.zig:executeJavaScript` stays on Node but uses one-shot spawn, see Notes).
  - `repository/botopink-lang/modules/compiler-core/src/comptime.zig` (MUTATED) — `warmPersistentNodeRunner` is deleted; the `wasm3` runtime is already warmed by the previous spec's `warmWasm3Runtime`, which now serves templates + decorators too.
  - `repository/botopink-lang/modules/compiler-core/src/test_warmup.zig` + `modules/language-server/src/tests/_warmup.zig` — drop the `pre-spawn the persistent node runner` test. One warmup (`wasm3 runtime`) covers everything.
  - `repository/botopink-lang/modules/compiler-core/src/codegen/AGENTS.md` — `wat.zig` row gains the new surface notes; `wat_runtime.zig` row added.
  - `repository/botopink-lang/AGENTS.md` — Build & test section: `node` removed from required PATH binaries. The compiler is now self-contained.
**Touches docs**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/AGENTS.md`.
  - `repository/botopink-lang/modules/compiler-core/src/codegen/docs.md`.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/AGENTS.md` (template_eval / decorator_eval rows).
  - `repository/botopink-lang/AGENTS.md`.
  - `repository/botopink-lang/CHANGELOG.md`.
  - `tasks/v0.beta.21/status.md`.
**Status**: pending

## Context

After `wasm3-unified-runtime` lands, the only remaining JavaScript-execution dependency in the compiler is `template_eval.zig` + `decorator_eval.zig`. Their evaluation pipeline:

```
template body (Botopink) →
  commonJS.emitFnJs (lowering to JS) →
  spawn node / persistent_node.eval →
  parseOutcome(json)
```

It exists for a single reason: the WAT backend doesn't yet support the language features template/decorator bodies use. Specifically:

| Feature | commonJS | wat | Used by templates/decorators |
|---|:---:|:---:|:---:|
| Number / string literals | ✓ | ✓ | yes |
| Binary ops (+ - * / mod) | ✓ | ✓ | yes |
| String concat | ✓ | partial (no general impl) | yes |
| List literals | ✓ | partial | **yes** |
| Anonymous records (`{ a, b }`) | ✓ | ✗ | **yes** (CustomNode, Span) |
| Optional type (`?T`, `null`) | ✓ | ✗ | **yes** (ref: null) |
| Throw / catch (structured) | ✓ | ✗ | **yes** (`__failRaw`) |
| Reflection (`@Expr`, `@Decl`) | ✓ (via capture object) | ✗ | **yes** |
| String methods (length, slice) | ✓ (native JS) | partial | yes |
| Method dispatch on records | ✓ | ✗ | yes |

The asymmetry isn't accidental: commonJS rides on JS's runtime (objects, closures, exceptions for free), while WAT has to build everything on top of linear memory + i32/i64/f32/f64. The gap closes in this spec — once.

## Intent

- **Move template/decorator evaluation to the same wasm3 pipeline** the previous spec established for comptime val. After this spec ships, **every comptime evaluation in the compiler** flows through one execution path: AST → WAT → wat→wasm → wasm3.
- **No change to the language surface.** Existing `.bp` template/decorator bodies compile unchanged. Users write the same code. What changes is the compiler's internal compilation target.
- **Bring the WAT backend to template parity**, not to full JS parity. The closed set is bounded by what `template_eval` and `decorator_eval` invoke: capture-object methods, anonymous records, optional null, structured throw, JSON serialisation. Features the JS backend has but templates don't use (e.g., async/await in template bodies — forbidden today) stay out of scope.
- **Delete `persistent_node.zig`** as the last step. The compiler binary no longer requires `node` on PATH at all.
- **Preserve snapshot byte-identity** wherever possible. The output of `template_eval.evaluate` is consumed by `parseOutcome`, which decodes a JSON object with keys `kind`/`source`/`ast`/etc. Templates that emit identical JSON via WAT and via JS are indistinguishable downstream.

## DAG

Eight phases, ordered so each is shippable and tested before the next:

```
F0-audit-template-surface     enumerate every Botopink feature template/decorator bodies actually use
F1-wat-anon-records           anonymous record literals (CustomNode, Span, anonymous { k: v }) → struct layout in linear memory
F2-wat-optionals              ?T = tagged i32 (0 = null, 1 = some, payload follows)
F3-wat-string-ops             concat, length, slice, equality — full implementation backed by linear memory string layout
F4-wat-list-literals          [a, b, c] over linear memory with explicit length prefix
F5-wat-throw-catch            structured throw (`throw { __bpfail: {…} }`) → trap with i32 payload-pointer; catch handler decodes
F6-wat-capture-runtime        wat_runtime.zig: `__capture`, `__expr`, `__code`, `Span`, `CustomNode`, `__failRaw` as WAT functions
F7-wat-decl-reflection        `__decl` cluster: kind / name / fields / methods / annotations + fail/failAt method dispatch
F8-template-eval-swap         template_eval.evaluate uses wat path; persistent_node deleted afterwards
F9-decorator-eval-swap        decorator_eval.evaluate uses wat path
F10-cleanup                   warmPersistentNodeRunner deleted; docs sweep
```

Phases F1–F5 are pure codegen extensions — they don't touch template/decorator yet. They can be validated against the existing codegen snapshot suite (`codegen/tests/`) by adding fixtures that exercise the new features through the WAT backend. F6–F7 builds the runtime support. F8–F9 are the actual swap with parity testing. F10 is cleanup.

---

## F0 — Audit: enumerate the closed feature set

**Files**: `tasks/v0.beta.21/specs/templates-decorators-botopink-native.md` (this file, gets an appendix listing the audit results); no source changes.

Mechanical audit: grep every `.bp` template/decorator body in the codebase (`libs/*/src/*.bp`, `repository/*/src/*.bp` where `pub fn …(comptime e: @Expr<…>)` or annotated with `#[…]` and the body uses `decl.*`). For each, list the language features it uses. The union of those features is **the closed set this spec commits to**. Features outside the set continue to fall back to `persistent_node` until follow-up audits widen the set.

Concrete starting list (from inspection of existing templates: `erika/src/erika.bp`, `jhonstart/src/html.bp`, `onze`, `std/result.bp`, `std/option.bp`):
- Anonymous record literal: `CustomNode(kind:…, span:…, ref:…, children:…)`, `Span(start, end, line)`, `{ kind: "Interp", code: …, span: …}`.
- Optional null: `ref: null`, `ref: e.lookup("Users")`.
- List literal: `children: [kw, col]`, `parts: [Text, Interp, Text]`.
- String concat: `"select " + name`.
- String methods: `s.length` (via interface dispatch).
- `val` binding chain: `val kw = …; val col = …; val root = …; return e.custom(root, code);`.
- Method calls on capture: `e.build(s)`, `e.lookup(name)`, `e.failAt(span, msg)`, `e.custom(tree, code)`.
- Method calls on decl reflection: `decl.fail(msg)`, `decl.name`, `decl.fields`.
- Conditionals (rare, but present): `if x { … } else { … }` in template bodies.
- Pattern matching: in onze-style mock decorators, `case kind { Fn -> …; _ -> … }`.
- Throw / throwy semantics: `e.fail("msg")` raises a structured error.

**Out of audit set (fall through to fallback)**: async/await, generators (`yield`), trait/interface method dispatch on non-receiver types, generic functions with type parameters bound at template-call-time.

F0 exit gate: a markdown table committed under `tasks/v0.beta.21/specs/templates-decorators-botopink-native-audit.md` listing every template body, every feature it uses, and the F-phase that delivers each feature. The table becomes the test acceptance matrix.

---

## F1 — Anonymous records in WAT

**Files**: `modules/compiler-core/src/codegen/wat.zig` (~250 LOC additions).

Layout: an anonymous record `{ a: i32, b: string, c: ?T }` becomes a heap-allocated struct in linear memory. Memory model:

```
@offset 0: i32 — bytes layout begins
@offset N: per-field, declaration-order, naturally-aligned
```

Allocator: a bump allocator backed by a `(memory)` declaration. Each template invocation gets its own arena (the runtime is fresh per call — F2 of `wasm3-unified-runtime`). De-alloc is the runtime drop, not per-record.

Emit:
- `record_alloc(size)` → returns `i32` (linear-memory pointer).
- `record_set_field(ptr, offset, value)` — emitted per field.
- `record_get_field(ptr, offset)` — emitted at every `.field` access in the body.
- Field-offset table emitted per record-type at module top.

Snapshot diff goal: existing `codegen/tests/wat.*` tests that touch records (e.g. `record construct two fields`) produce byte-identical WAT to today — this phase adds NEW record features, doesn't change existing ones.

F1 exit gate: 6 new fixtures pass byte-equal vs hand-written WAT references:
- anonymous record with 2 i32 fields
- anonymous record with mixed types (i32 + string)
- anonymous record passed to a fn parameter
- anonymous record nested as a field (CustomNode-like with children: [])
- anonymous record method call (no inheritance — just `r.kind`)
- anonymous record literal returned from a fn

---

## F2 — Optional `?T` in WAT

**Files**: `modules/compiler-core/src/codegen/wat.zig` (~120 LOC).

Encoding: `?T` = `(i32 tag, payload)`. Tag 0 = null, tag 1 = some, payload follows immediately. For pointer-typed payloads (string, record), null is also encodable as the all-zero pointer — but the tag form generalises (covers `?i32` where 0 is a valid value).

Emit:
- `val x: ?T = null;` → emit tag 0, payload uninit.
- `val x: ?T = some_value;` → emit tag 1, then the value.
- Pattern `if x { v -> body }` → check tag, branch.
- `x.is_some()` / `x.is_none()` → tag check.

F2 exit gate: 4 fixtures pass byte-equal vs reference WAT:
- `val x: ?i32 = null;`
- `val x: ?string = e.lookup("name");`
- if-let-style binding
- explicit `null` field in an anonymous record

---

## F3 — String operations in WAT

**Files**: `modules/compiler-core/src/codegen/wat.zig` (~200 LOC).

String layout (already partially present): `(i32 length, ...bytes)`. Operations to add:
- `concat(a, b)`: allocate new buffer = len_a + len_b, memcpy, return.
- `length(s)` (already exists).
- `slice(s, start, end)`: allocate new buffer, memcpy slice, return.
- `equal(a, b)`: len-equal short-circuit + memcmp.
- String literal in `data` section emitted with explicit length prefix.

Interface dispatch: `s.length` lowers to a direct call to the `length` function generated per template invocation. No vtable needed for these primitives (single concrete type).

F3 exit gate: 5 fixtures pass byte-equal:
- concat 2 literals
- concat literal + variable
- length on a literal (compile-time fold)
- equality of two strings (literal == identifier)
- slice with two indices

---

## F4 — List literals in WAT

**Files**: `modules/compiler-core/src/codegen/wat.zig` (~150 LOC).

Layout: `(i32 length, ...elements)`. Each element is the element-type's WAT representation (i32 pointer for records/strings, scalar for primitives).

Emit:
- `[a, b, c]` → allocate `4 + 3 * elem_size`, write length + elements.
- `list[i]` → bounds-check (trap on OOB), pointer arithmetic, load.
- `list.length` → already exists as a primitive op.
- Iteration via `for (x in list) { … }` if present in templates today (audit confirms).

F4 exit gate: 4 fixtures:
- `[1, 2, 3]` (i32 list)
- `["a", "b"]` (string list)
- list of anonymous records
- nested lists `[[1], [2, 3]]`

---

## F5 — Structured throw / catch in WAT

**Files**: `modules/compiler-core/src/codegen/wat.zig` (~250 LOC). The most architecturally significant phase.

WASM has an exceptions proposal but it isn't universally supported and wasm3 doesn't implement it. So this phase uses a **manual unwind protocol**:

- Each function emits a hidden trailing `(i32 exception_tag, i32 payload_ptr)` pair in linear memory at a known offset (per-call-frame).
- `throw expr` → write tag = 1 + payload pointer to that slot, then `return` with the function's normal result type bound to a "discarded" sentinel.
- Caller checks the slot after every call; if tag ≠ 0, propagates.

This is more code than a single WASM trap would be, but it preserves the structured-payload contract the JS `try/catch` pattern provides — and the throw protocol is the same byte-shape as the existing JS `throw { __bpfail: {…} }` pattern. The `try/catch` block in a template body lowers to: call inner fn → check exception slot → enter handler if set → propagate if not handled.

F5 exit gate: 3 fixtures + 2 round-trip tests:
- `throw "msg"` propagates upward.
- `try { throw "msg" } catch (e) { … }` enters the handler.
- nested try/catch: inner re-throws, outer catches.
- round-trip with the existing JS test: `assert_throw_byte_equal "msg"`.

---

## F6 — Capture object runtime in WAT (`wat_runtime.zig`)

**Files**: `modules/compiler-core/src/codegen/wat_runtime.zig` (NEW, ~400 LOC of Zig that emits ~300 LOC of WAT).

Mirror of `template_eval.zig`'s `prelude` string, but expressed as a Zig string of WAT source. The WAT module exports the same surface:

```wat
;; --- prelude.wat ---
(func $__expr (param $v i32) (result i32) ...)        ;; { __lift: v }
(func $__code (param $s i32) (result i32) ...)        ;; { __code: s }
(func $Span (param $start i32) (param $end i32) (param $line i32) (result i32) ...)
(func $CustomNode (param $kind i32) ... (result i32) ...)
(func $__failRaw (param $message i32) (param $param i32) (param $span i32) ...)
(func $__capture (param $param i32) (param $ctx_ptr i32) (param $parts_ptr i32) (result i32))
  ;; allocates a record exposing text/parts/source/context/lookup/bindings/build/custom/fail/failAt
  ;; each method is a separate exported function that takes the capture record as first arg
```

Each capture method (e.g., `__capture_text(self)`) reads from the capture record's fields and either returns a value or invokes `__failRaw`. The reflection-object semantics — that calling `e.text()` raises if the template is holed — get encoded as a tag check + conditional throw.

The runtime is prepended to every emitted template/decorator WAT module by `template_eval.evaluate` / `decorator_eval.evaluate`. It's identical across calls (`wat_runtime.text` returns the same string each time), so the wat→wasm conversion is amortized via the `wasm3` script memo from `wasm3-unified-runtime`.

F6 exit gate: a Zig unit test in `codegen/tests/wat_runtime.zig` instantiates the runtime module via wasm3_host and calls each function — every method produces the byte-equal output the JS prelude would.

---

## F7 — `@Decl` reflection cluster in WAT

**Files**: `modules/compiler-core/src/codegen/wat_runtime.zig` (~100 LOC additions).

The `@Decl` handle exposes:
```
decl.kind      → enum string ("Record" | "Struct" | "Enum" | "Fn" | …)
decl.name      → string
decl.fields    → list of Field { name, typeName, annotations }
decl.methods   → list of Method { name, params, returnType, annotations }
decl.returnType → string
decl.annotations → list of Annotation { name, args }
decl.fail(msg) → invokes __failRaw with span = null
decl.failAt(span, msg) → invokes __failRaw with the span
```

The handle is constructed from a serialized JSON blob (today: `handleJson` passed to `decorator_eval.evaluate`). For the WAT path, that JSON is decoded once by `__decl_init(json_ptr)` and stored as a heap record. The decoder is ~100 LOC: scan JSON via the established WAT string-ops + list-ops.

F7 exit gate: 3 fixture decorators (today running via JS prelude) produce byte-equal output via WAT prelude:
- `service` decorator that reads `decl.name` + emits one string.
- `mock` decorator (onze) that walks `decl.methods` + emits stubs.
- `compilerError` decorator that calls `decl.fail` conditionally.

---

## F8 — Switch `template_eval.evaluate` to WAT path

**Files**: `modules/compiler-core/src/comptime/template_eval.zig` (MUTATED, line 292).

```zig
pub fn evaluate(arena, io, build_root, tfn, captures, plainArgs) !Outcome {
    const wat_src = try wat.codegenEmitTemplate(arena, wat_runtime.prelude, tfn, captures, plainArgs);
    const stdout = wasm3_host.runWat(arena, wat_src) catch |err| {
        // Fallback: if the WAT path fails (feature outside the closed set), fall back to JS.
        // This fallback is intended for templates the audit (F0) flagged as out-of-set.
        // Reaching this branch with an audited-in-set template is a bug.
        std.debug.print("wat path failed for template '{s}': {} — falling back to JS\n", .{ tfn.name, err });
        return evaluateViaJs(arena, io, build_root, tfn, captures, plainArgs);
    };
    return parseOutcome(arena, stdout);
}
```

`evaluateViaJs` is the OLD path, preserved as a transition aid. After 1 release cycle of zero fallback fires across all known templates (validated via `--time-report` showing no fallback invocations + manual log scan), the fallback is deleted. The `script_memo` (from earlier work) applies unchanged — it caches by the bytes of `wat_src`, which is deterministic.

F8 exit gate:
- Every `tests.sublanguage` test passes with byte-equal snapshots vs v0.beta.20 baseline.
- Every codegen `template end to end` test in `js_comptime.zig` passes byte-equal.
- A new `tests/template_eval_wat.zig` test pins: for the 9 sublanguage fixtures, the OUTCOME (Outcome.code / Outcome.custom) is byte-identical between JS path and WAT path.

---

## F9 — Switch `decorator_eval.evaluate` to WAT path

**Files**: `modules/compiler-core/src/comptime/decorator_eval.zig` (MUTATED, line 210).

Mirror of F8 for decorators. The `__decl` handle (today bound as a JS object in the prelude) becomes a WAT record initialized from the same `handleJson` argument. Fallback to JS preserved through one release cycle.

F9 exit gate:
- Every decorator test (`decorator-bearing record (R2)`, the `onze` lib's mock-based tests, the `#[service]` example) passes byte-equal snapshots.
- A new `tests/decorator_eval_wat.zig` test pins parity for the 5–8 decorator fixtures in the repo.

---

## F10 — Cleanup: delete `persistent_node`, drop Node from PATH

**Files**:
  - `modules/compiler-core/src/comptime/runtime/persistent_node.zig` (DELETED, after zero fallback fires across 1 release cycle).
  - `modules/compiler-core/src/comptime/runtime/persistent_node_runner.js` if it exists as a separate file (DELETED).
  - `modules/compiler-core/src/comptime.zig` — `warmPersistentNodeRunner` deleted.
  - `modules/compiler-core/src/test_warmup.zig` + `modules/language-server/src/tests/_warmup.zig` — Node warmup test removed.
  - `AGENTS.md` (repo root) — Build & test section drops `node` from required PATH binaries. Mention `node` as optional only for running the generated commonJS output of the user's program — but the compiler itself never spawns it.
  - `comptime/AGENTS.md`, `comptime/docs.md`, `comptime/runtime/AGENTS.md`, `codegen/AGENTS.md` — narrative updates.
  - `CHANGELOG.md` — entry under `Changed (templates-decorators-botopink-native)`.
  - `tasks/v0.beta.21/status.md` — row → done.

After F10, the compiler binary has zero JavaScript-engine dependency and zero non-Zig runtime requirement. `botopink build` works on a machine with only the compiler binary installed.

F10 exit gate:
- `grep -r "persistent_node\|process\.run.*node\|spawn.*node" modules/compiler-core/src` returns ZERO matches (excluding comments / docs and excluding `codegen/runtime.zig:executeJavaScript`, which runs the USER'S output program for snapshot capture — still spawns one-shot `node` for that purpose).
- A clean Docker container with only the compiler binary (and the underlying OS) can run `botopink build app.bp` on a `.bp` that uses templates + decorators, producing identical output to a machine with `node` installed.

---

## Test scenarios

```
F1 ---- 6 record fixtures byte-equal to hand-written WAT
F2 ---- 4 optional fixtures byte-equal
F3 ---- 5 string-op fixtures byte-equal
F4 ---- 4 list-literal fixtures byte-equal
F5 ---- 3 throw fixtures + 2 JS round-trips byte-equal
F6 ---- every capture method's WAT impl produces byte-equal output to the JS prelude version
F7 ---- 3 fixture decorators emit byte-equal output via WAT prelude vs JS prelude
F8 ---- 9 sublanguage tests + N codegen template tests pass byte-identical against v0.beta.20 baseline
F9 ---- 5–8 decorator tests pass byte-identical
F10 ---- grep persistent_node returns 0 matches; clean Docker test build succeeds
end-to-end ---- a real example app (`erika`-using or `jhonstart`-using) builds + runs identical output before/after this spec
```

## Notes

- **Scope honesty.** This is a multi-week (realistically 4–8 weeks) effort. The phasing (F0–F10) is deliberate: each phase is shippable independently and validated against the existing JS-path snapshots before moving on. The fallback to JS during F8/F9 means a failed phase doesn't break the suite — it just leaves Node briefly in the loop.
- **What about `executeJavaScript`?** `codegen/runtime.zig:executeJavaScript` (and `executeErlang`, `executeBeamAsm`) run the USER's generated PROGRAM to capture RUN LOG for snapshots. They're separate from `template_eval`/`decorator_eval` — those run the COMPILER's internal evaluation of template bodies. This spec deletes `persistent_node.zig` (which served template_eval/decorator_eval), but `executeJavaScript` continues to spawn one-shot `node` for the user-program execution path. That's a different concern (running the user's emitted JS); a follow-up spec could persistify it again if needed, but it's out of scope here.
- **Snapshot churn risk.** WAT execution may produce subtly different byte output than JS execution for edge cases (number formatting, string encoding, error message format). Mitigation: F8 + F9 acceptance criteria require BYTE-IDENTICAL snapshots vs v0.beta.20 baseline. Any divergence is either (a) a bug in the WAT lowering, fixed before merge, or (b) a deliberate format normalization, called out in the CHANGELOG.
- **Why not push for the WASM exceptions proposal in F5?** Because wasm3 doesn't implement it. Re-evaluating per wasm3 upgrade is a separate task. The manual unwind protocol (~250 LOC) is well-understood and works today.
- **Risk: WAT backend bug accumulation.** Each new feature adds bug surface. Mitigation: the F0 audit caps the feature set at exactly what existing templates use — no speculative features. Test fixtures (F1–F5) cover every new code path with byte-equal snapshot pinning.
- **Performance.** wasm3 is an interpreter — running complex template bodies through WAT may be slower than running them through V8's JIT-optimized JS. For the typical template body (anonymous record construction + a few method calls), the difference is sub-millisecond and dominated by the wat→wasm conversion (cached by `script_memo` after first hit). Net dev-loop impact: positive (no Node cold start, no IPC overhead).
- **Out of scope:**
  - Templates that use features outside the F0 audit set (async, generators, complex trait dispatch) — they hit the fallback to JS during transition, and a future spec widens the set if the use case materialises.
  - Replacing `executeJavaScript` / `executeErlang` / `executeBeamAsm` — those run the USER's program, a different concern entirely.
  - Adding new template/decorator features. This spec is migration only, not feature work.
- **Exit gate (full spec):**
  - F0 audit committed; every template body in the repo has its feature set classified.
  - F1–F7 codegen extensions land with byte-equal WAT fixture tests.
  - F8 + F9 swap template_eval / decorator_eval onto the WAT path.
  - Fallback to JS preserved through 1 release cycle, then deleted in F10.
  - `persistent_node.zig` deleted; `node` removed from required PATH binaries.
  - Clean Docker container without `node`/`erl`/`wasmtime` installed compiles a template-heavy `.bp` successfully.
  - All AGENTS.md / docs.md per affected module updated in the same commit as code.
