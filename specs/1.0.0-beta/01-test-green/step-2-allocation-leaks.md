# Step 2 — Fix allocation leaks

**Status:** ⏳ pending  
**Priority:** 🟡 ALTA  
**Estimativa:** 2-4 horas  
**Depende de:** Step 1 (decorator eval)

---

## Problema

Múltiplos codegen tests vazam 1 allocation cada. O Zig test runner detecta e reporta:

```
error: memory leak detected
```

---

## Testes com leak

| # | Teste | Leak | Arquivo |
|---|-------|------|---------|
| 1 | values | 1 alloc | `codegen/tests.zig` |
| 2 | string interpolation | 1 alloc | `codegen/tests.zig` |
| 3 | loop | 1 alloc | `codegen/tests.zig` |
| 4 | try/catch | 1 alloc | `codegen/tests.zig` |
| 5 | @print | 1 alloc | `codegen/tests.zig` |
| 6 | dispatch | 1 alloc | `codegen/tests.zig` |
| 7 | destructure | 1 alloc | `codegen/tests.zig` |

---

## Causa raiz

### Análise padrão

Leaks em Zig geralmente ocorrem quando:

1. **Allocator não libera memória**
   ```zig
   const ptr = try allocator.create(T);
   // ... usa ptr
   // esquece: allocator.destroy(ptr);
   ```

2. **ArrayList não deinit**
   ```zig
   var list = std.ArrayList(T).init(allocator);
   // ... usa list
   // esquece: list.deinit();
   ```

3. **Arena não deinit**
   ```zig
   var arena = std.heap.ArenaAllocator.init(allocator);
   // ... usa arena
   // esquece: arena.deinit();
   ```

### Onde procurar

**Arquivos suspeitos:**
- `modules/compiler-core/src/codegen/tests.zig` — setup dos testes
- `modules/compiler-core/src/codegen/*.zig` — codegen em si
- `modules/compiler-core/src/comptime/*.zig` — comptime evaluation

---

## Investigação

### 1. Identificar o leak exato

```bash
# Rodar um teste específico com verbose
cd modules/compiler-core
zig build test --test-filter "values" 2>&1 | grep -A5 "memory leak"
```

### 2. Usar Zig leak detector

```zig
// No setup do teste
const allocator = std.testing.allocator;
// Zig automaticamente detecta leaks quando o teste termina
```

### 3. Adicionar logs de allocation

```zig
const TrackingAllocator = std.heap.TrackingAllocator;
var tracking = TrackingAllocator.init(allocator);
defer {
    const stats = tracking.stats();
    std.debug.print("allocations: {}, deallocations: {}\n", .{
        stats.total_allocations,
        stats.total_deallocations,
    });
}
```

---

## Solução

### Padrão 1: Missing deinit

**Antes:**
```zig
test "values" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    // ... usa list
    // falta: list.deinit();
}
```

**Depois:**
```zig
test "values" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    // ... usa list
}
```

### Padrão 2: Missing destroy

**Antes:**
```zig
test "string interpolation" {
    const ptr = try std.testing.allocator.create(MyStruct);
    // ... usa ptr
    // falta: std.testing.allocator.destroy(ptr);
}
```

**Depois:**
```zig
test "string interpolation" {
    const ptr = try std.testing.allocator.create(MyStruct);
    defer std.testing.allocator.destroy(ptr);
    // ... usa ptr
}
```

### Padrão 3: Arena sem deinit

**Antes:**
```zig
test "loop" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const alloc = arena.allocator();
    // ... usa alloc
    // falta: arena.deinit();
}
```

**Depois:**
```zig
test "loop" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    // ... usa alloc
}
```

---

## Implementação

### 1. Rodar testes com leak detection

```bash
cd modules/compiler-core
zig build test 2>&1 | grep -B2 -A5 "memory leak"
```

### 2. Para cada leak encontrado

```zig
// Identificar a linha exata
// Adicionar defer deinit/destroy
// Rodar teste novamente para verificar
```

### 3. Verificar todos os testes

```bash
# Rodar todos os testes
zig build test

# Verificar que não há leaks
echo $?  # deve ser 0
```

---

## Testes de aceitação

### Teste 1: Zero leaks

```bash
zig build test 2>&1 | grep "memory leak"
# Esperado: nenhum output
```

### Teste 2: Todos os testes passam

```bash
zig build test
# Esperado: 164/164 tests passed
```

---

## Arquivos a modificar

| Arquivo | Ação | Linhas estimadas |
|---------|------|------------------|
| `codegen/tests.zig` | Adicionar `defer deinit()` | ~10-20 |
| `codegen/*.zig` | Corrigir allocations | ~20-50 |

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Leak em código de produção | Baixa | Alto | Revisar codegen em si, não só testes |
| Performance degrada com tracking | Baixa | Médio | Remover tracking após fix |
| Falso positivo no leak detector | Muito baixa | Baixo | Verificar com múltiplas runs |

---

## Checklist

- [ ] Rodar `zig build test` e capturar todos os leaks
- [ ] Para cada leak, identificar a causa exata
- [ ] Adicionar `defer deinit()` ou `defer destroy()`
- [ ] Rodar testes novamente para verificar
- [ ] Verificar que não há leaks em código de produção
- [ ] Rodar `zig build test` — 0 leaks
- [ ] Verificar que não há regressões
