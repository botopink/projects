# Status Report — botopink projects

**Data:** 2026-09-14  
**Última atualização:** Após atualização das branches e todos

---

## Repositórios

| Repo | Branch | main == feat | Status |
|------|--------|--------------|--------|
| **projects** (root) | `feat` | ✅ | specs adicionadas |
| **botopink-lang** | `feat` | ✅ | 155/164 testes passando |
| **jhonstart** | `main` | ✅ | estável |
| **emilia** | `feat` | ✅ | estável |
| **onze** | `main` | ✅ | estável |
| **vscode-extension** | `main` | ✅ | estável |
| **erika** | `main` | ✅ | estável |
| **rakun** | `main` | ✅ | estável |

---

## Últimos commits

```
projects:           461a5894 docs: mark step-3 regression tests as complete
botopink-lang:      731963d test: add decorator regression tests
jhonstart:          a79d654 merge: integrate feat into main
emilia:             068333b docs(emilia): update docs and CHANGELOG
onze:               8889441 merge: integrate feat into main
vscode-extension:   8b1c083 docs(vscode-extension): update snippets
erika:              670134a merge: integrate feat into main
rakun:              d4a6794 merge: integrate feat into main
```

---

## Specs 1.0.0-beta

### Spec 01 — Test Green (CRÍTICO)

**Objetivo:** 100% testes unitários passando  
**Estado atual:** 155/164 pass (9 fail) + 4 regression tests falhando

| Step | Título | Status | Branch | Commit |
|------|--------|--------|--------|--------|
| 1 | Fix decorator eval (9 failures) | ⏳ NÃO INICIADO | fix/step-1-decorator-eval | 461a5894 |
| 2 | Fix allocation leaks | ⏳ NÃO INICIADO | fix/step-2-allocation-leaks | 461a5894 |
| 3 | Regression tests | ✅ ESCRITO, ❌ FALHANDO | fix/step-3-regression-tests | 461a5894 |

**Notas:**
- Step 3 já tem 4 testes escritos (commit `731963d` na feat)
- Todos os 4 testes de regressão falham porque dependem do Step 1
- Branches de todos os worktrees atualizadas para `461a5894`

### Spec 02 — Type System (MÉDIA — não bloqueia testes)

**Objetivo:** Features de type system  
**Estado:** 0/9 steps

**Part A — Type Infrastructure:**
- Step 1: `type` as first-class value
- Step 1b: `#[@code]` annotation
- Step 2: Comptime value evaluation
- Step 3: Comptime eval loop
- Step 4: Std functions in .bp
- Step 5: Comptime tests

**Part B — State Narrowing:**
- Step 6: Parser type guards
- Step 7: Inference narrowing (13 patterns)
- Step 8: Comptime narrowing tests
- Step 9: Codegen narrowing tests

---

## Trabalho pendente — botopink-lang

### Prioridade CRÍTICA — Spec 01

**Step 1 — Fix decorator eval (9 failures)**
- 9 testes em `decorator_invocation.zig` falham (+ 4 em `decorator_regression.zig`)
- **Status: 🔄 EM ANDAMENTO** — nova abordagem implementada, foco em build funcional

**Nova abordagem (2026-09-15):**
- `decorator_eval.zig` reescrito para gerar Erlang **direto do AST**, sem passar por:
  - JSON intermediário (`handleJson` ainda recebido, mas convertido direto para termos Erlang)
  - Source botopink intermediário (sem `emitBpBody` → `compile()` → codegen)
  - Parse/lex do código gerado (elimina `parseError` do `compile()`)
- Fluxo direto: `ast.FnDecl` → `emitExpr`/`emitStmt` → Erlang source → `persistent_erl.eval()`
- `jsonToErl()` converte `handleJson` diretamente para maps Erlang (`#{kind => ..., name => ...}`)
- `emitExpr()` emite expressões AST direto para Erlang (field access → `maps:get`, binary ops, etc.)
- `emitStmt()` emite statements AST direto para Erlang (bindings, assigns, returns)
- `buildErlModule()` monta módulo Erlang completo com:
  - `-module(decorator_<hash>).`
  - `-export([main/0]).`
  - Plain arg bindings como funções 0-arity
  - Decl handle como map Erlang nativo
  - Corpo do decorator como função Erlang
  - Host functions: `fail/2`, `compilerError/1`, `emit/1`
  - `main/0` com try/catch → JSON via `json:encode`

**Problema anterior (resolvido):**
- `compile()` falhava com `parseError` no código botopink gerado
- Parser rejeitava constructs válidos em contexto de `compile()` mas não em parse standalone
- Root cause: contexto de compilação com std imports e múltiplos módulos
- Solução: pular completamente o `compile()` e gerar Erlang direto

**Próximas melhorias (planejadas):**
- Remover JSON intermediário completamente
- `infer.zig` deve criar `DeclHandle` (estrutura nativa) em vez de strings JSON
- `decorator_eval.zig` receberá `DeclHandle` diretamente
- Benefícios: type safety, performance, simplicidade

**Prioridades atuais:**
1. **FASE 1 (PRIORIDADE ALTA):** Fazer build funcionar
   - Ajustar `infer.zig` para criar `DeclHandle` em vez de JSON
   - Completar `decorator_eval.zig` com `emitDeclHandle()`
   - Critério: `zig build test` compila sem erros (testes podem falhar)

2. **FASE 2 (PRIORIDADE MÉDIA):** Corrigir testes
   - Validar saída Erlang gerada
   - Corrigir problemas de runtime
   - Critério: 11/11 decorator_invocation + 4/4 decorator_regression passam

3. **FASE 3 (PRIORIDADE BAIXA):** Limpeza e otimização
   - Remover código morto
   - Otimizar conversões
   - Atualizar documentação

**Step 2 — Fix allocation leaks**
- Múltiplos codegen tests vazam 1 allocation cada
- Arquivos: values, string interpolation, loop, try/catch, @print, dispatch, destructure
- **Status: NÃO INICIADO**
- **Depende de Step 1** (test runner precisa estar estável)

**Step 3 — Regression tests**
- 4 testes já escritos em `decorator_regression.zig`
- Todos falhando (dependem do Step 1)
- **Status: ESCRITO, AGUARDANDO Step 1 + Step 2**

### Depois — Spec 02

Type system features (não bloqueia testes verdes)

---

## Worktrees

| Worktree | Branch | Commit | Status |
|----------|--------|--------|--------|
| `.tasks/step-1-decorator-eval` | fix/step-1-decorator-eval | 461a5894 | ✅ atualizado |
| `.tasks/step-2-allocation-leaks` | fix/step-2-allocation-leaks | 461a5894 | ✅ atualizado |
| `.tasks/step-3-regression-tests` | fix/step-3-regression-tests | 461a5894 | ✅ atualizado |

**Todos os worktrees estão no mesmo commit (`461a5894`) e prontos para trabalho.**

---

## Estrutura de arquivos

```
projects/
├── .tasks/                       ← Worktrees para paralelismo
│   ├── step-1-decorator-eval/   ← Branch: fix/step-1-decorator-eval
│   ├── step-2-allocation-leaks/ ← Branch: fix/step-2-allocation-leaks
│   ├── step-3-regression-tests/ ← Branch: fix/step-3-regression-tests
│   └── WORKTREES.md             ← Instruções de uso
├── specs/                        ← Specs 1.0.0-beta
│   ├── 1.0.0-beta/
│   │   ├── 01-test-green.md     ← CRÍTICO: 100% testes
│   │   ├── 02-type-system.md    ← MÉDIA: type features
│   │   └── overview.md
│   └── __template.md
├── repository/
│   ├── botopink-lang/           ← Compiler (Zig) — branch feat
│   ├── jhonstart/               ← Framework
│   ├── emilia/                  ← Query builder
│   ├── onze/                    ← ORM
│   ├── rakun/                   ← Runtime
│   ├── erika/                   ← LINQ-like
│   └── vscode-extension/        ← VS Code
└── STATUS.md
```

---

## Métricas

| Métrica | Valor |
|---------|-------|
| Repositórios | 7 + 1 (projects root) |
| Specs 1.0.0-beta | 2 specs |
| Spec 01 completado | 0/3 steps (0%) |
| Spec 02 completado | 0/9 steps (0%) |
| Testes passando | 155/164 (94%) |
| Testes falhando | 9 (decorator_invocation) + 4 (regression) |
| Worktrees atualizados | 3/3 (100%) |
| Commits não pushados | 1 (fix/step-1-decorator-eval) |
| Branches extras | 3 (fix/step-1, fix/step-2, fix/step-3) |

---

## Próximos passos

1. **Step 1** — Fix decorator eval (desbloqueia 9 testes + 4 regression tests)
2. **Step 2** — Fix allocation leaks (depois de Step 1)
3. **Step 3** — Validar regression tests (depois de Step 1 + Step 2)
4. **Spec 02** — Type system features (depois de Spec 01 completa)

---

## Notas

- Todos os todo.md foram atualizados com estado real
- Branches de todos os worktrees sincronizadas com feat
- Compiler (botopink-lang) na branch `feat` com 155/164 testes passando
- 4 testes de regressão já escritos mas falhando (dependem do Step 1)
