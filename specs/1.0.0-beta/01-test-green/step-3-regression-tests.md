# Step 3 — Regression tests

**Status:** ⏳ pending  
**Priority:** 🟢 MÉDIA  
**Estimativa:** 2-3 horas  
**Depende de:** Step 1 e Step 2

---

## Objetivo

Adicionar testes para garantir que fixes dos Steps 1 e 2 não regredam no futuro.

---

## Testes a adicionar

### 1. Decorator regression tests (4 testes)

**Arquivo:** `modules/compiler-core/src/comptime/tests/decorator_regression.zig`

#### Teste 1: Decorator com loop

```botopink
fn validate(comptime decl: @Decl) {
    decl.fields.forEach({ f ->
        if (f.name == "bad") { decl.fail("field 'bad' not allowed"); }
    });
}
#[validate]
record Good { name: string, age: i32 }
```

**Verifica:** Loops em decorator bodies funcionam

#### Teste 2: Decorator com conditional

```botopink
fn conditional(comptime decl: @Decl) {
    if (decl.kind == DeclKind.Record) {
        if (decl.name == "Bad") { decl.fail("Bad not allowed"); }
    }
}
#[conditional]
record Good { x: i32 }
```

**Verifica:** Conditionals em decorator bodies funcionam

#### Teste 3: Decorator com string concat

```botopink
fn concat(comptime decl: @Decl) {
    val msg = "Processing: " + decl.name;
    @print(msg);
}
#[concat]
record Service { x: i32 }
```

**Verifica:** String concatenation em decorator bodies funciona

#### Teste 4: Decorator com @emit

```botopink
fn emit(comptime decl: @Decl) {
    @emit("pub val generated_" + decl.name + " = 42;");
}
#[emit]
record Service { x: i32 }
fn useit() -> i32 { return generated_Service; }
```

**Verifica:** @emit em decorator bodies funciona

---

### 2. Allocation regression tests

**Arquivo:** `modules/compiler-core/src/codegen/tests.zig` (adicionar aos testes existentes)

#### Padrão de verificação

```zig
test "values — no allocation leak" {
    const before = std.testing.allocator.stats();
    
    // ... código do teste
    
    const after = std.testing.allocator.stats();
    try std.testing.expectEqual(before.total_allocations, after.total_deallocations);
}
```

#### Testes a adicionar

1. **values** — verificar que não vaza
2. **string interpolation** — verificar que não vaza
3. **loop** — verificar que não vaza
4. **try/catch** — verificar que não vaza
5. **@print** — verificar que não vaza
6. **dispatch** — verificar que não vaza
7. **destructure** — verificar que não vaza

---

## Implementação

### 1. Criar arquivo de regression tests

```bash
touch modules/compiler-core/src/comptime/tests/decorator_regression.zig
```

### 2. Adicionar testes de decorator

```zig
// decorator_regression.zig
const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

fn assertAccepts(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .ok);
}

test "decorator regression: loop in body" {
    try assertAccepts(@src(),
        \\fn validate(comptime decl: @Decl) {
        \\    decl.fields.forEach({ f ->
        \\        if (f.name == "bad") { decl.fail("bad not allowed"); }
        \\    });
        \\}
        \\#[validate]
        \\record Good { name: string }
    );
}

// ... mais testes
```

### 3. Adicionar ao test runner

```zig
// test_root.zig
pub const decorator_regression = @import("tests/decorator_regression.zig");
```

### 4. Adicionar allocation checks

```zig
// codegen/tests.zig
test "values — no allocation leak" {
    const before = std.testing.allocator.stats();
    
    // ... código existente do teste
    
    const after = std.testing.allocator.stats();
    try std.testing.expectEqual(before.total_allocations, after.total_deallocations);
}
```

---

## Testes de aceitação

### 1. Todos os regression tests passam

```bash
zig build test --test-filter "regression"
# Esperado: 4/4 tests passed
```

### 2. Zero leaks em todos os testes

```bash
zig build test 2>&1 | grep "memory leak"
# Esperado: nenhum output
```

### 3. Suite completa verde

```bash
zig build test
# Esperado: 164/164 tests passed, 0 leaks
```

---

## Arquivos a criar/modificar

| Arquivo | Ação | Linhas estimadas |
|---------|------|------------------|
| `decorator_regression.zig` | Criar | ~100 |
| `test_root.zig` | Adicionar import | ~5 |
| `codegen/tests.zig` | Adicionar allocation checks | ~50 |

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Testes flaky | Baixa | Médio | Usar asserts determinísticos |
| Allocation stats não confiável | Baixa | Alto | Verificar com múltiplas runs |
| Testes lentos | Baixa | Médio | Manter testes simples |

---

## Checklist

- [ ] Criar `decorator_regression.zig`
- [ ] Adicionar 4 decorator regression tests
- [ ] Adicionar ao `test_root.zig`
- [ ] Adicionar allocation checks em codegen tests
- [ ] Rodar `zig build test --test-filter "regression"` — 4/4 pass
- [ ] Rodar `zig build test` — 164/164 pass, 0 leaks
- [ ] Verificar que testes são determinísticos
