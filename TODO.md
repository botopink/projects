# wat-refactor — F2 (record layout) + F3 (`?.`) + F4 (snapshots) + F5 (AGENTS) — DONE

> Spec: [`tasks/v0.beta.20/specs/frente-a.md`](../../tasks/v0.beta.20/specs/frente-a.md) (search for `wat-refactor`).

## Baseline (pre-this-session)

- meta `feat`: `1c38772` (post merge with install-from-deps F0–F6 + wasm3-unified-runtime closeout).
- bot-lang `feat`: `6b46f55` (install-from-deps F0–F6 closeout atop wasm3).
- **F1 (void classifier) already landed**: bot-lang `3790c0f`.

## Closed phases

- [x] **F2 — record layout** (`modules/compiler-core/src/codegen/wat.zig`)
  - Stable 4-byte slot offsets per declared field order (mirrors `beam_asm`'s
    map-by-field-name shape but linearised — no `record_tag` header, the spec
    test scenario doesn't need one and `recordTypeOfExpr` recovers the
    type-name from let-bindings + fn return types + chained field types).
  - `recv.field` / `self.field` now load `base + offset` via the new
    `local_types: StringHashMap → record name` + `self_type` recovery
    (codegen is untyped, this is a best-effort walk of decl-time annotations).
  - `recv.field = v` / `recv.field += v` store at the same offset; `+=` uses
    one `$__mem{n}` scratch for the load-add-store cycle.
  - Tuple `t._N` indexes the same memory (already in place).
  - **Record / struct member methods now emit** as `$<owner>_<method>`
    linear-memory fns (`emitInterfaceMethods` / `emitStructMethods` /
    `emitMemberFn`). A method body that references `self` without listing it
    as a param gets an implicit `(param $self i32)` synthesised
    (`bodyReferencesSelf`), so the bare `self.field` reads through a real
    local instead of a `global.get $self` to a non-existent global.
  - **Destructure `{ a, b } = Rec(...)`** now walks the record's declared
    field order via `fieldOffsetIn`, so out-of-order destructuring
    (`{ b, a } = R(7, 11)`) reads the right slot.
- [x] **F3 — optional chaining `?.`** (`wat.zig`)
  - `recv?.field` lowers to `local.tee $__mem{k}` + `i32.eqz` +
    `(if (result i32) (then i32.const 0) (else local.get $__mem{k} i32.load offset=N))`.
  - Matches the existing `?T` carrier shape (none = `i32.const 0`, some =
    base pointer).
  - Chained `a?.b?.c` composes through fresh scratch slots.
- [x] **F4 — snapshot sweep**
  - 25 wasm snapshots regenerated (record/struct/enum methods now emit real
    method bodies; field access reads slots; field assign writes slots; `?.`
    guards via `local.tee` + `if`).
  - New fixtures pinned in `tests/wat.zig`:
    - `wat: record field access by name loads at declared offset` —
      `val r = R(a: 7, b: 11); @print(r.b);` lowers + runs → RUN LOG `11`.
    - `wat: optional chaining on record null returns zero` —
      `fn pick(maybe: ?R) -> i32 { return maybe?.b; }` pins the guard shape.
- [x] **F5 — AGENTS.md sweep** (`modules/compiler-core/src/codegen/AGENTS.md`)
  - `wat.zig` row updated: dropped the "named record-field access is
    unsupported" / "`?.` can't be realised" `(KNOWN GAP)` clauses; pinned the
    new record method emission + field access by name + `?.` guard pattern
    + the implicit-self synthesis rule.

## Out of scope (carried)

- `wasm-test-runner` (separate consumer spec; depends on this — now
  unblocked).
- The `i32.mul` on `f64` record fields surfacing in regenerated snapshots
  (e.g. `Vec2_lengthSq`) is a pre-existing wat-untyped-codegen limit, not a
  regression of this spec.
- The `Counter_inc` body lowers without an `i32.store` size suffix — pre-
  existing, applies to all `+=` lowering.

## Exit gate

- [x] `zig build test` green on the full suite (1352/1352 tests passed).
- [x] `zig build test-backends` green — wasmtime executes the new
  `record_field_access` fixture (RUN LOG `11`).
- [x] F4 snapshots committed alongside the code.
- [x] AGENTS.md updated in the same commit.
- [x] No `--no-verify`; SSH for git per CLAUDE.md memory.
