# Spec 01 — Test Green

**Prioridade:** CRÍTICO — bloqueia as demais specs
**Objetivo:** `zig build test` (em `repository/botopink-lang`) sem falhas nem leaks.

---

## Estado atual

`zig build test` → **1390/1421** passam · **31 falhas** · **13 leaks** · ~17s, sem travamentos.

| Grupo | Falhas | Step |
|---|---|---|
| `comptime/tests/decorator_invocation.zig` | 6 | 1 |
| `comptime/tests/decorator_regression.zig` | 2 | 1 |
| `comptime/tests/templates.zig` | 9 | 1 |
| `language-server` `sublanguage` (templates erika `@ExprCustom`) | 8 | 1 |
| `language-server` `completion` (record com decorator) | 1 | 1 |
| snapshots de codegen (RUN LOG divergente) | 5 | 1 |
| leaks em testes de codegen | 13 | 2 |

---

## Steps

| # | Step | Branch |
|---|------|--------|
| 1 | [Comptime eval no erl (decorators + templates)](./step-1-decorator-eval.md) | `fix/step-1-decorator-eval` |
| 2 | [Allocation leaks](./step-2-allocation-leaks.md) | `fix/step-2-allocation-leaks` |
| 3 | [Regression tests de decorator](./step-3-regression-tests.md) | `fix/step-3-regression-tests` |

```
Step 1 ──► Step 3 (os testes de regressão só passam com o Step 1)
Step 2 ── independente (leaks de codegen não dependem do comptime)
```

---

## Critério de aceitação

- [ ] `zig build test`: 0 falhas, 0 leaks
- [ ] Nenhum `.snap.md.new` gerado
- [ ] Nenhum `beam.smp` órfão após a suíte
