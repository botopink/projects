# Spec 01 — Test Green (100% testes unitários)

**Status:** 🔴 in progress  
**Priority:** CRÍTICO — bloqueia tudo  
**Objetivo:** Fazer 100% dos testes unitários passarem sem falhas ou leaks

---

## Estado atual

```
155/164 tests passed (9 failed)
```

### Falhas identificadas

| Categoria | Quantidade | Arquivo |
|-----------|------------|---------|
| Decorator eval | 9 | `decorator_invocation.zig` |
| Allocation leaks | 7+ | `codegen/tests.zig` |

---

## Steps

| # | Step | Status | Bloqueia |
|---|------|--------|----------|
| 1 | [Fix decorator eval](./step-1-decorator-eval.md) | ⏳ pending | CI verde |
| 2 | [Fix allocation leaks](./step-2-allocation-leaks.md) | ⏳ pending | CI verde |
| 3 | [Regression tests](./step-3-regression-tests.md) | ⏳ pending | — |

---

## Ordem de execução

```
Step 1 (decorator eval) ← CRÍTICO, 9 failures
  └─► Step 2 (allocation leaks)
       └─► Step 3 (regression tests)
```

---

## Métricas de sucesso

| Métrica | Antes | Depois |
|---------|-------|--------|
| Testes passando | 155/164 | 164/164 |
| Falhas | 9 | 0 |
| Leaks | 7+ | 0 |
| CI status | 🔴 vermelho | 🟢 verde |

---

## Arquivos relevantes

| Arquivo | Papel |
|---------|-------|
| `modules/compiler-core/src/comptime/tests/decorator_invocation.zig` | Testes falhando |
| `modules/compiler-core/src/comptime/decorator_eval.zig` | Avaliação de decorators |
| `modules/compiler-core/src/comptime/template_eval.zig` | Decompiler (emitBpExpr) |
| `modules/compiler-core/src/codegen/tests.zig` | Codegen tests com leaks |
