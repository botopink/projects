# Interface / Struct / Record / Implement — full coverage

**Branch**: `feat/interface-coverage`
**Depends on**: `feat/implement-extend-decls` for the impl dispatch/semantic-validation part
**Status**: pending (Phase 1 parser done)

## Steps

### Phase 1: Parser tests — done
- [x] Interface with field + abstract + default method
- [x] Interface with multiple abstract methods
- [x] Struct with private field + getter + setter(throw) + method
- [x] Record with fields + method
- [x] Implement single/multiple interface (separate form)
- [x] Struct/enum/record with inline implement

### Phase 2: Comptime / Inference
- [ ] Interface with field and abstract method infers correctly
- [ ] Interface with multiple abstract methods infers param types
- [ ] Struct with getter/setter/method infers Self and field types
- [ ] Record with fields and method infers return type
- [ ] Implement single — binding list sees the implement decl
- [ ] Implement two interfaces with qualified methods — disambiguation resolves

### Phase 3: Semantic validation
- [ ] Error: implement missing a required interface method
- [ ] Error: implement has a method not declared in the interface
- [ ] Error: qualified prefix doesn't match a declared interface
- [ ] Error: duplicate method name across interfaces without qualification
- [ ] Error: getter return type mismatch with field type
- [ ] Error: setter called with the wrong value type

### Phase 4: Codegen
- [ ] CommonJS: interface → comment, struct → class with getter/setter, record → class with constructor
- [ ] CommonJS: implement → prototype.method (see `feat/extension-dispatch` for external dispatch)
- [ ] Erlang: struct → map + accessor fns, record → tagged tuple, implement → module export
- [ ] BEAM ASM / WAT: struct/record/implement lowering

## Test scenarios
See the full parser/infer/codegen list — ~25 scenarios across the four phases.