# Status Report — botopink projects

**Data:** 2026-09-14  
**Última atualização:** Após merge de specs e unificação de branches

---

## Repositórios

| Repo | Branch | main == feat | Status |
|------|--------|--------------|--------|
| **projects** (root) | `feat` | ✅ | specs adicionadas |
| **botopink-lang** | `main` | ✅ | wave1 merged |
| **jhonstart** | `main` | ✅ | estável |
| **emilia** | `feat` | ✅ | estável |
| **onze** | `main` | ✅ | estável |
| **vscode-extension** | `main` | ✅ | estável |
| **erika** | `main` | ✅ | estável |
| **rakun** | `main` | ✅ | estável |

---

## Últimos commits

```
projects:           3e5bef6 feat: add specs directory to main
botopink-lang:      a6d73f6 merge: integrate spec/1.0.0-beta.wave1
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
**Estado atual:** 155/164 pass (9 fail)

| Step | Título | Status |
|------|--------|--------|
| 1 | Fix decorator eval (9 failures) | ⏳ pending |
| 2 | Fix allocation leaks | ⏳ pending |
| 3 | Regression tests | ⏳ pending |

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
- 9 testes em `decorator_invocation.zig` falham
- Erro: "Decorator bodies run in the node runtime"
- Causa: `evaluateErl` retorna `EvalFailed`
- Solução: Reutilizar `emitBpExpr` de `template_eval.zig`

**Step 2 — Fix allocation leaks**
- Múltiplos codegen tests vazam 1 allocation cada
- Arquivos: values, string interpolation, loop, try/catch, @print, dispatch, destructure

**Step 3 — Regression tests**
- Adicionar testes para garantir que fixes não regredam

### Depois — Spec 02

Type system features (não bloqueia testes verdes)

---

## Estrutura de arquivos

```
projects/
├── specs/                          ← Specs 1.0.0-beta
│   ├── 1.0.0-beta/
│   │   ├── 01-test-green.md       ← CRÍTICO: 100% testes
│   │   ├── 02-type-system.md      ← MÉDIA: type features
│   │   └── overview.md
│   └── __template.md
├── repository/
│   ├── botopink-lang/             ← Compiler (Zig)
│   ├── jhonstart/                 ← Framework
│   ├── emilia/                    ← Query builder
│   ├── onze/                      ← ORM
│   ├── rakun/                     ← Runtime
│   ├── erika/                     ← LINQ-like
│   └── vscode-extension/          ← VS Code
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
| Testes falhando | 9 (decorator_invocation) |
| Commits não pushados | 0 |
| Branches extras | 0 (apenas main/feat) |
