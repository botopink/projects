# Interface / Struct / Record / Implement — full coverage

**Branch**: `feat/interface-coverage`
**Depends on**: `feat/implement-extend-decls` for the impl dispatch/semantic-validation part
**Status**: done — all four phases implemented and snapshot-tested

## Steps

### Phase 1: Parser tests — done
- [x] Interface with field + abstract + default method
- [x] Interface with multiple abstract methods
- [x] Struct with private field + getter + setter(throw) + method
- [x] Record with fields + method
- [x] Implement single/multiple interface (separate form)
- [x] Struct/enum/record with inline implement

### Phase 2: Comptime / Inference — done
- [x] Interface with field and abstract method infers correctly
- [x] Interface with multiple abstract methods infers param types
- [x] Struct with getter/setter/method infers Self and field types
- [x] Record with fields and method infers return type
- [x] Implement single — binding list sees the implement decl
- [x] Implement two interfaces with qualified methods — disambiguation resolves

### Phase 3: Semantic validation — done
Implemented as a third inference pass (`validateProgram` in `comptime/infer.zig`),
run from both `inferProgram` and `inferProgramTyped`. Backed by four new
`TypeErrorKind` variants (`missingMethod`, `unknownMethod`, `unknownInterface`,
`ambiguousMethod`) in `comptime/error.zig`; getter/setter checks reuse
`typeMismatch`. Only the standalone `implement … for …` form is checked for
method coverage; interfaces not declared in the program (e.g. stdlib) are skipped.

- [x] Error: implement missing a required interface method → `missingMethod`
- [x] Error: implement has a method not declared in the interface → `unknownMethod`
- [x] Error: qualified prefix doesn't match a declared interface → `unknownInterface`
- [x] Error: duplicate method name across interfaces without qualification → `ambiguousMethod`
- [x] Error: getter return type mismatch with field type → `typeMismatch`
- [x] Error: setter value type mismatch with field type → `typeMismatch`

### Phase 4: Codegen — done
Each `js:` codegen scenario is emitted across all four targets
(commonJS / erlang / beam / wasm), so one test covers every backend.
- [x] CommonJS: interface → comment, struct → class with getter/setter, record → class with constructor
- [x] CommonJS: implement → prototype.method (see `feat/extension-dispatch` for external dispatch)
- [x] Erlang: struct → map + accessor fns, record → tagged tuple, implement → module export
- [x] BEAM ASM / WAT: struct/record/implement lowering

## Test scenarios
Parser (Phase 1) and infer/codegen (Phases 2 & 4) snapshots already existed.
Phase 3 added six new error-snapshot tests in `comptime/tests.zig`, each
producing snapshots under `snapshots/comptime/{node,erlang}/errors/`.
