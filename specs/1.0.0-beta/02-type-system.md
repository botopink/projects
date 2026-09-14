# Spec 02 — Type System Features

**Version:** 1.0.0-beta  
**Status:** ⏳ pending  
**Priority:** 🟡 MÉDIA — não bloqueia testes  
**Created:** 2026-09-14  
**Author:** ericfillipe  
**Depends on:** Spec 01 (testes verdes)

---

## Objetivo

Implementar features de type system que **não são necessárias para testes passarem**, mas expandem capacidades da linguagem.

---

## Part A — Type Infrastructure (Steps 1-5)

### Step 1 — `type` as first-class comptime value

**Status:** ⏳ pending

`type` como valor e annotation em comptime.

```botopink
val T = i32;                              // T: type = i32
fn identityType(comptime T: type) -> type { break T; }
```

**Arquivos:** `comptime/env.zig`, `comptime/infer.zig`, `parser/decls.zig`

---

### Step 1b — `#[@code]` annotation

**Status:** ⏳ pending

Anotação que diz ao compiler: "o retorno é um TypeInfo que representa um tipo".

```botopink
#[@code]
fn Point() -> TypeInfo {
    return TypeInfo.Record(fields: [
        RecordField(name: "x", typeName: i32),
        RecordField(name: "y", typeName: i32),
    ]);
}
val p: Point() = Point()(x: 1, y: 2);
```

**Arquivos:** `parser/decls.zig`, `comptime/infer.zig`, `comptime/builtins.zig`

---

### Step 2 — Comptime value evaluation para builtins

**Status:** ⏳ pending

`@typeInfo` e `@TypeOf` computam valores reais (não só tipos).

```botopink
@typeInfo(i32)                    → TypeInfo.Int (valor)
@typeInfo(record { x: i32 })      → TypeInfo.Record(fields: [...])
@TypeOf(42)                       → i32 (type value)
```

**Arquivos:** `comptime/eval.zig`, `comptime/infer.zig`

---

### Step 3 — Comptime eval loop para std functions

**Status:** ⏳ pending

Funções `.bp` com params `comptime` executam durante inference.

**Arquivos:** `comptime/specialize.zig`, `comptime/builtins.zig`

---

### Step 4 — Std functions em .bp

**Status:** ⏳ pending

6 funções std em user-space:

```botopink
#[@code] fn mergeRecords(comptime A: type, comptime B: type) -> TypeInfo
#[@code] fn partial(comptime T: type) -> TypeInfo
#[@code] fn omit(comptime T: type, comptime name: string) -> TypeInfo
#[@code] fn pick(comptime T: type, comptime names: string[]) -> TypeInfo
fn recordKeys(comptime T: type) -> string[]
fn field(comptime T: type, v: T, comptime name: string) -> any
```

**Arquivos:** `libs/std/src/types.bp`

---

### Step 5 — Comptime tests

**Status:** ⏳ pending

~20 testes para builtins + std functions.

---

## Part B — State Narrowing (Steps 6-9)

### Step 6 — Parser: type guards

**Status:** ⏳ pending

```botopink
fn isCircle(s: Shape) -> s is Shape.Circle { ... }
```

**Arquivos:** `parser/decls.zig`

---

### Step 7 — Inference: narrowing

**Status:** ⏳ pending

13 padrões de narrowing:

| # | Padrão | Exemplo |
|---|--------|---------|
| 1 | `if (x)` null-check | `?T → T` |
| 2 | `if (x)` else branch | then/else narrowing |
| 3 | `case` on `@Result` | Ok/Err variants |
| 4 | `case` on `@Option` | Some/None |
| 5 | `case` on user enum | Variant fields |
| 6 | OR patterns | Shared fields |
| 7 | Guard clauses | Narrowed in guard |
| 8 | `assert x is Pattern` | Post-assert |
| 9 | Early return | Post-guard |
| 10 | `else if` chains | Each branch |
| 11 | `if (x && x.field)` | Pre-field |
| 12 | `x?.field` | Optional chaining |
| 13 | Type guards | `isX(x)` call site |

**Arquivos:** `comptime/infer.zig`, `comptime/env.zig`

---

### Step 8 — Comptime narrowing tests

**Status:** ⏳ pending

24 testes (22 positive + 2 negative).

---

### Step 9 — Codegen narrowing tests

**Status:** ⏳ pending

≥8 testes codegen, 4 backends, RUN LOG validation.

---

## Ordem de execução

```
Part A (type infrastructure):
  Step 1 → Step 2 → Step 3 → Step 4 → Step 5

Part B (narrowing) — pode rodar em paralelo com Part A após Step 1:
  Step 6 → Step 7 → Step 8 → Step 9
```

---

## Métricas

| Métrica | Valor |
|---------|-------|
| Core builtins | 2 (`@typeInfo`, `@TypeOf`) + `@comptimeError` |
| Annotations | 1 (`#[@code]`) |
| Std functions | 6 |
| Narrowing patterns | 13 |
| Comptime tests | ~42 |
| Codegen tests | ≥8 |
