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
- **Status: EM ANDAMENTO** — investigação concluída, implementação parcial

**Feito nesta etapa:**
- `compileFromAst` em `comptime.zig` (compila `ast.Program` direto, sem lex/parse)
- `decorator_eval.zig` refatorado para construir AST direto (`jsonToExpr` + `buildDeclKindRecord`)
- Fix no codegen Erlang: `atomName(f.name)` em `recordLit`/`interfaceLit`
- Off-by-one corrigido (`2 + plainArgs.len` → `3 + plainArgs.len`)

**Causa raiz real (não é só "reutilizar emitBpExpr"):**
- A avaliação de decorator via Erlang **nunca esteve completa**.
- `template_eval.zig` documenta: *"evaluateErl() returns EvalFailed until erlang.zig gains #[@Host] method lowering"*.
- `warmPersistentErlRunner` (que compila `template_runtime.bp` e aplica `patchHostMethods`) **não é chamado em lugar nenhum**.
- O módulo `.erl` gerado para o corpo do decorador não tem `main/0` nem as host functions
  (`fail`/`emit`/`compilerError`) → `erlc` falha com `function compilerError/1 undefined`.

**Falta (próximos passos):**
1. Sintetizar `main/0` no `.erl` gerado (chama `fn(decl(), <arg>()...)`).
2. Definir host functions `fail/2`, `compilerError/1`, `emit/1`.
3. `main/0` devolver o JSON esperado por `parseOutcome` (com escape de string).
4. Inserir `-export([main/0])` após `-module(...)`.
5. Revisar/regenerar snapshots afetados pelo fix `atomName`.

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
| Commits não pushados | 0 |
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
