# Static extension dispatch

**Branch**: `feat/extension-dispatch`
**Phase**: F6
**Depends on**: `feat/import-rework` (activation `*`) + `feat/implement-extend-decls` (Impl/ExtendDecl) — ✅ both in `feat`
**Status**: ✅ done — merged on top of `feat`. Inference (`registerExtensions` +
`resolveReceiverCall` in `comptime/infer.zig`), dispatch tables in `comptime/env.zig`,
and CommonJS external-dispatch codegen (namespace objects + call-site rewrite). Notes:
impl-vs-interface coverage is left to `validateProgram` (no duplicate check here);
Erlang/BEAM/WAT/TS handle the new decls structurally — their call-site external
rewrite is follow-up.

## Model (Rust/C# — Model Y)

`obj.m()` only resolves if the impl/extension is **activated** (`X*` in import or `X*;`)
in the file. Otherwise: error with hint, or qualified call `Sym.m(obj)`.

```bp
import {Pato, PatoNada*, PatoExtra*} from "ducks";
val donald = new Pato();
donald.swim();    // ✓ PatoNada* activated
donald.quack();   // ✓ PatoExtra* activated

import {Pato, PatoNada};        // no *
donald.swim();                  // ✗ error: method not active; hint: use `PatoNada*`
PatoNada.swim(donald);          // ✓ qualified call needs no activation
```

### Resolution of `obj.m(args)`
1. **Inherent** — `m` on the type (or inline `implement`). Always available.
2. **Activated** — `Name implement T for TypeOf(obj)` or `Name extend TypeOf(obj)` with `m`, and `Name` activated.
3. Otherwise → error + hint. Ambiguity (two activated) → error, require `Name.m(obj)`.

## Steps

### Inference (`comptime/infer.zig`)
1. Per-file set of **activations** (symbols with `*` in import + `X*;`)
2. Global tables `(traitId, targetTypeId) -> []ImplementDecl` and `targetTypeId -> []ExtendDecl`
3. `obj.m(args)`: apply rules 1–3, considering only activated ones
4. Error: method not active → hint with `Sym*`
5. Error: two ambiguous activations → require `Sym.m(obj)`
6. Error: `Sym*` where `Sym` is not an impl/extend or not imported
7. Error: method in impl not declared in interface; required method missing
8. Qualified call `Sym.m(obj)` resolves without activation

### Codegen — external dispatch (no monkey-patch)
9. CommonJS: activated `obj.m()` → `Sym.m(obj)`
10. Erlang: `sym:m(Obj)`
11. BEAM ASM: tagged tuple / module call
12. WAT: function table entry per impl/extend
13. TypeScript: external dispatch or `declare module` augmentation

## Test scenarios

```
infer   ---- donald.swim() with PatoNada* (pass)
infer   ---- donald.swim() imported but no * (error + hint)
infer   ---- donald.quack() with PatoExtra* (pass)
infer   ---- two activated impls same method (error + qualify)
infer   ---- PatoNada.swim(donald) qualified, no * needed (pass)
infer   ---- inherent method always available (pass)
infer   ---- impl extra/missing method vs interface (error)
codegen ---- donald.swim() activated → PatoNada.swim(donald)   (CommonJS external)
codegen ---- extend method → external dispatch
```

## Open points
- **P2 orphan rule**: allow `implement T for X` where `T` and `X` come from external packages? Rust forbids it.
- **P3 re-export**: does `pub import {X*} from "m";` re-export name + activation?
- **P4 scope**: does `X*` in import apply file-wide; does `X*;` inside a fn apply only to the fn? Or always file-level?