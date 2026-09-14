# Spec 01 — Test Green (100% testes unitários)

**Version:** 1.0.0-beta  
**Status:** 🔴 in progress  
**Priority:** CRÍTICO — bloqueia tudo  
**Created:** 2026-09-14  
**Author:** ericfillipe

---

## Objetivo

Fazer **100% dos testes unitários passarem** sem falhas ou leaks.

**Estado atual:** 155/164 pass (9 fail)

---

## Steps

| Step | Título | Status | Bloqueia |
|------|--------|--------|----------|
| 1 | Fix decorator eval (9 failures) | ⏳ pending | CI verde |
| 2 | Fix allocation leaks | ⏳ pending | CI verde |
| 3 | Regression tests | ⏳ pending | — |

---

## Step 1 — Fix decorator eval (9 failures)

**Status:** ⏳ pending  
**Priority:** 🔴 CRÍTICO

### Problema

9 testes em `decorator_invocation.zig` falham com:
```
error: the decorator evaluator failed to run
hint: Decorator bodies run in the node runtime at compile time — check that `node` is available.
```

### Causa raiz

`evaluateErl()` em `decorator_eval.zig` retorna `error.EvalFailed` para decorators que usam constructs complexos (loops, conditionals, string concat).

O decompiler `emitBpExpr` em `template_eval.zig` já está completo, mas `decorator_eval.zig` não o usa corretamente.

### Testes falhando

| Teste | Arquivo |
|-------|---------|
| decorator invocation: a body may reference an @emit'd declaration | decorator_invocation.zig:160 |
| decorator invocation: mock-style synthesis from an interface compiles | decorator_invocation.zig:185 |
| + 7 outros | decorator_invocation.zig |

### Solução

1. **Opção A (recomendada):** Reutilizar `emitBpExpr`/`emitBpStmt` de `template_eval.zig` em `decorator_eval.zig`
2. **Opção B:** Implementar decompiler separado em `decorator_eval.zig`

### Arquivos

| Arquivo | Ação |
|---------|------|
| `modules/compiler-core/src/comptime/decorator_eval.zig` | Importar/usar decompiler de template_eval |
| `modules/compiler-core/src/comptime/template_eval.zig` | Tornar `emitBpExpr`/`emitBpStmt` públicos |

### Aceitação

- [ ] 9 testes de decorator_invocation passam
- [ ] `zig build test` mostra 0 failures em decorator tests
- [ ] Decorators com loops, conditionals, string concat funcionam

---

## Step 2 — Fix allocation leaks

**Status:** ⏳ pending  
**Priority:** 🟡 ALTA

### Problema

Múltiplos codegen tests vazam 1 allocation cada.

### Testes com leak

| Teste | Leak |
|-------|------|
| values | 1 alloc |
| string interpolation | 1 alloc |
| loop | 1 alloc |
| try/catch | 1 alloc |
| @print | 1 alloc |
| dispatch | 1 alloc |
| destructure | 1 alloc |

### Solução

Identificar e corrigir allocations não liberadas nos codegen tests.

### Arquivos

| Arquivo | Ação |
|---------|------|
| `modules/compiler-core/src/codegen/tests.zig` | Investigar leaks |
| `modules/compiler-core/src/codegen/*.zig` | Corrigir allocations |

### Aceitação

- [ ] 0 allocation leaks em `zig build test`
- [ ] Todos os codegen tests passam sem leak warnings

---

## Step 3 — Regression tests

**Status:** ⏳ pending  
**Priority:** 🟢 MÉDIA

### Objetivo

Adicionar testes para garantir que fixes não regredam.

### Testes a adicionar

1. **Decorator regression tests**
   - Decorator com loop
   - Decorator com conditional
   - Decorator com string concat
   - Decorator com @emit

2. **Allocation regression tests**
   - Verificar que cada codegen test não vaza

### Aceitação

- [ ] ≥4 decorator regression tests
- [ ] Allocation checks em codegen tests
- [ ] `zig build test` passa 100%

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
