# Specs — 1.0.0-beta

**Version:** 1.0.0-beta  
**Last updated:** 2026-09-14

---

## Prioridade

| # | Spec | Status | O que faz |
|---|------|--------|-----------|
| 1 | [`01-test-green`](./01-test-green.md) | 🔴 in progress | **CRÍTICO**: Fazer 100% dos testes unitários passarem |
| 2 | [`02-type-system`](./02-type-system.md) | ⏳ pending | Type system features (não bloqueia testes) |

---

## Dependências

```
01-test-green (CRÍTICO — testes verdes)
  ├── Step 1: Fix decorator eval (9 failures)
  ├── Step 2: Fix allocation leaks
  └── Step 3: Regression tests

02-type-system (features novas — não bloqueia testes)
  ├── Part A: Type infrastructure
  └── Part B: State narrowing
```

---

## Estado atual dos testes

```
155/164 tests passed (9 failed)
```

**Falhas (9 testes):**
- Todos em `decorator_invocation.zig`
- Erro: "Decorator bodies run in the node runtime at compile time"
- Causa: `evaluateErl` retorna `EvalFailed` para decorators complexos

---

## Branch naming

```
spec/1.0.0-beta.<spec>-<step>
```

Exemplos: `spec/1.0.0-beta.test-green`, `spec/1.0.0-beta.type-system`
