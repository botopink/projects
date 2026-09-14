# TODO — Step 1: Fix decorator eval (9 failures)

**Branch:** `fix/step-1-decorator-eval`  
**Commit base:** `8d88372` (feat atual com Step 4 concluído)  
**Objetivo:** 164/164 testes passando (atualmente 155/164)  
**Prioridade:** 🔴 CRÍTICO

---

## Estado atual (2026-09-14)

- ✅ **Step 4 (Interface Literal) CONCLUÍDO** e merged em `feat` (commit `8d88372`)
- ✅ Branches atualizadas (todos os worktrees no commit `8d88372`)
- ❌ 9 testes falhando em `decorator_invocation.zig`
- ❌ 4 testes de regressão falhando em `decorator_regression.zig` (dependem deste step)

### ⚠️ RETOMANDO O TRABALHO

**Step 4 concluído com sucesso:**
- ✅ Sintaxe `@Decl(field: value)` implementada
- ✅ Parser reconhece interface literals
- ✅ Type inference funciona
- ✅ Codegen emite corretamente (Erlang, CommonJS, WAT, BEAM)
- ✅ Formatter com round-trip estável
- ✅ Testes de parser passando

**Próximo passo:**
1. Rodar testes de decorator para ver erros específicos
2. Investigar por que `@Decl(...)` ainda não funciona no decorator eval
3. Verificar se há problemas de type checking ou runtime

---

## Testes falhando

| # | Teste | Arquivo | Complexidade |
|---|-------|---------|--------------|
| 1 | `body accepts a record` | decorator_invocation.zig:51 | Baixa |
| 2 | `body rejects wrong placement` | decorator_invocation.zig:61 | Baixa |
| 3 | `method placement accepted` | decorator_invocation.zig:71 | Baixa |
| 4 | `method decorator rejects a record` | decorator_invocation.zig:83 | Baixa |
| 5 | `body reads the reflected name` | decorator_invocation.zig:93 | Média |
| 6 | `@compilerError rejects wrong placement` | decorator_invocation.zig:103 | Baixa |
| 7 | `@compilerError body accepts the right placement` | decorator_invocation.zig:115 | Baixa |
| 8 | `@emit contributes a top-level declaration` | decorator_invocation.zig:127 | Alta |
| 9 | `a body may reference an @emit'd declaration` | decorator_invocation.zig:155 | Alta |

**Erro comum:**
```
error: the decorator evaluator failed to run
hint: Decorator bodies run in the node runtime at compile time — check that `node` is available.
```

---

## Causa raiz

**Arquivo:** `modules/compiler-core/src/comptime/decorator_eval.zig`

**Problema:**
- `evaluateErl()` retorna `error.EvalFailed` para decorators complexos
- O decompiler `emitBpExpr` em `template_eval.zig` já está completo
- Mas `decorator_eval.zig` não o usa corretamente ou tem gaps na implementação

**Constructs que falham:**
1. String concatenation (`methods = methods + "..."`)
2. Loops (`decl.methods.forEach({ m -> ... })`)
3. @emit (`@emit("pub fn ...")`)
4. Field access (`decl.name`, `m.name`)
5. Conditionals (`if (decl.kind != DeclKind.Record)`)

---

## Checklist de implementação

### Investigação
- [ ] Rodar `zig build test --test-filter "decorator"` para ver erros detalhados
- [ ] Ler `decorator_eval.zig:94-100` (função `evaluateErl`)
- [ ] Ler `template_eval.zig` (funções `emitBpExpr`, `emitBpStmt`)
- [ ] Verificar se `emitBpExpr`/`emitBpStmt` são públicos

### Implementação
- [ ] Importar `template_eval` em `decorator_eval.zig`
- [ ] Usar `emitBpBody` para decompilar corpo do decorator
- [ ] Construir script Erlang com corpo decompilado
- [ ] Executar via `persistent_erl.eval`
- [ ] Parsear resultado e retornar `Outcome`

### Testes
- [ ] Teste 1: String concatenation passa
- [ ] Teste 2: Loops passam
- [ ] Teste 3: @emit passa
- [ ] Teste 4: Field access passa
- [ ] Teste 5: Conditionals passam
- [ ] Todos os 9 testes de `decorator_invocation.zig` passam
- [ ] Todos os 4 testes de `decorator_regression.zig` passam

### Validação final
- [ ] `zig build test` → 164/164 pass (ou mais, se regression tests contarem)
- [ ] `zig build test` → 0 leaks
- [ ] `zig fmt` nos arquivos modificados
- [ ] Commit: `fix: decorator eval for complex constructs`
- [ ] Merge para `feat`

---

## Arquivos a modificar

| Arquivo | Ação | Linhas estimadas |
|---------|------|------------------|
| `decorator_eval.zig` | Modificar | ~50-100 |
| `template_eval.zig` | Verificar/Modificar | ~10-20 (se necessário) |

---

## Dependências

- **Nenhuma** — este é o primeiro step
- Step 2 (allocation leaks) pode ser feito em paralelo, mas testes podem crashar/timeout
- Step 3 (regression tests) já foi escrito mas depende deste step para passar

---

## Notas

- Os 4 testes de regressão já foram criados em `decorator_regression.zig` (commit `731963d`)
- Test runner crasha com timeout (1m8s) por causa dos failures
- Solução: reutilizar `emitBpExpr` de `template_eval.zig` (Opção A do spec)
