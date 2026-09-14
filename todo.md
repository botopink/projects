# TODO — Step 2: Fix allocation leaks

**Branch:** `fix/step-2-allocation-leaks`  
**Commit base:** `461a5894` (feat atual)  
**Objetivo:** 0 allocation leaks em todos os testes  
**Prioridade:** 🟡 ALTA  
**Depende de:** Step 1 (decorator eval) — recomendado fazer depois

---

## Estado atual (2026-09-14)

- ✅ Branches atualizadas (todos os worktrees no commit `461a5894`)
- ⏳ **NENHUM TRABALHO DE CÓDIGO INICIADO**
- ❌ Leaks suspeitos em múltiplos codegen tests
- ⚠️ Difícil de isolar porque test runner crasha/timeout por causa dos 9 failures do Step 1

---

## Testes com leak suspeitos

| # | Teste | Leak | Arquivo |
|---|-------|------|---------|
| 1 | values | 1 alloc | `codegen/tests.zig` |
| 2 | string interpolation | 1 alloc | `codegen/tests.zig` |
| 3 | loop | 1 alloc | `codegen/tests.zig` |
| 4 | try/catch | 1 alloc | `codegen/tests.zig` |
| 5 | @print | 1 alloc | `codegen/tests.zig` |
| 6 | dispatch | 1 alloc | `codegen/tests.zig` |
| 7 | destructure | 1 alloc | `codegen/tests.zig` |

**Nota:** Lista baseada no spec original. Precisa ser validada com `zig build test 2>&1 | grep "memory leak"` depois que Step 1 estiver completo.

---

## Causa raiz (hipóteses)

### Padrões comuns de leak em Zig

1. **ArrayList sem deinit**
   ```zig
   var list = std.ArrayList(T).init(allocator);
   // ... usa list
   // esquece: defer list.deinit();
   ```

2. **Arena sem deinit**
   ```zig
   var arena = std.heap.ArenaAllocator.init(allocator);
   // ... usa arena
   // esquece: defer arena.deinit();
   ```

3. **Pointer sem destroy**
   ```zig
   const ptr = try allocator.create(T);
   // ... usa ptr
   // esquece: defer allocator.destroy(ptr);
   ```

### Arquivos suspeitos

- `modules/compiler-core/src/codegen.zig` — pipeline principal
- `modules/compiler-core/src/codegen/snapshot.zig` — test helpers
- `modules/compiler-core/src/comptime.zig` — comptime evaluation
- `modules/compiler-core/src/codegen/tests/helpers.zig` — test setup

---

## Checklist de implementação

### Pré-requisito
- [ ] **Step 1 completo** — test runner estável (164/164 pass)

### Investigação
- [ ] Rodar `zig build test 2>&1 | grep -B2 -A5 "memory leak"`
- [ ] Listar todos os testes com leak
- [ ] Para cada leak, identificar a função que vaza:
  - `codegen.zig`?
  - `snapshot.zig`?
  - `comptime.zig`?
  - `helpers.zig`?

### Correção
- [ ] Adicionar `defer deinit` onde necessário
- [ ] Adicionar `defer destroy` onde necessário
- [ ] Verificar arenas sem deinit

### Validação
- [ ] `zig build test` → 0 leaks (sem output de "memory leak")
- [ ] `zig build test` → 164/164 pass (sem regressões)
- [ ] `zig fmt` nos arquivos modificados
- [ ] Commit: `fix: allocation leaks in codegen tests`
- [ ] Merge para `feat`

---

## Arquivos a investigar

| Arquivo | Ação | Prioridade |
|---------|------|------------|
| `codegen.zig` | Investigar | Alta |
| `codegen/snapshot.zig` | Investigar | Alta |
| `comptime.zig` | Investigar | Média |
| `codegen/tests/helpers.zig` | Investigar | Média |

---

## Estratégia de debug

### 1. Isolar o leak

```zig
// No setup do teste
const allocator = std.testing.allocator;
// Zig automaticamente detecta leaks quando o teste termina
```

### 2. Usar TrackingAllocator

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

### 3. Binary search

Se muitos testes vazam, dividir e conquistar:
- Rodar metade dos testes
- Ver qual metade vaza
- Repetir até isolar

---

## Dependências

- **Depende de Step 1** — test runner precisa estar estável
- **Bloqueia Step 3** — regression tests precisam de 0 leaks

---

## Notas

- Leaks em Zig são detectados automaticamente pelo test runner
- Cada leak é tipicamente 1 allocation não liberada
- Padrão mais comum: ArrayList ou Arena sem deinit
- Pode ser feito em paralelo com Step 1, mas validação final depende de Step 1
