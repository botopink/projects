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

### Wave 1 — Erlang Runtime + Codegen (13 steps)

**Status:** 8/13 completados

| Step | Título | Status |
|------|--------|--------|
| 1 | Fix template body decompiler | ✅ completed |
| 2 | Fix decorator eval | ✅ completed |
| 3 | Fix record layout assumption | ✅ completed |
| 4 | Fix test failures + regenerate snapshots | 🔄 in progress (9 language-server failures) |
| 5.1 | Extend renderExprValue | ✅ completed |
| 5.2 | Complete patchHostMethods | ✅ completed |
| 5.3 | Add fail/failAt to erl prelude | ✅ completed |
| 5.4 | Handle return in comptime blocks | ✅ completed |
| 5.5 | Eval pipeline integration test | ✅ completed |
| 6 | Add erl runtime regression tests | ⏳ pending |
| 7 | Comptime type evaluation tests | ⏳ pending |
| 8 | Fix codegen runtime crashes | ⏳ pending |
| 8a | Add 2-min timeout | ✅ completed |
| 8b | Fix OTP 27 read_frame compat | ✅ completed |
| 9 | Remove orphaned snapshots | ✅ completed |

### Wave 2 — Comptime Type System (9 steps)

**Status:** 0/9 completados (depende de Wave 1)

| Step | Título | Status |
|------|--------|--------|
| 1 | `type` as first-class comptime value | ⏳ pending |
| 1b | `#[@code]` annotation | ⏳ pending |
| 2 | Implement comptime value evaluation | ⏳ pending |
| 3 | Implement comptime eval loop | ⏳ pending |
| 4 | Implement std functions in .bp | ⏳ pending |
| 5 | Comptime tests | ⏳ pending |
| 6 | Parser support for type guards | ⏳ pending |
| 7 | Inference engine state narrowing | ⏳ pending |
| 8 | Comptime narrowing tests | ⏳ pending |
| 9 | Codegen narrowing tests | ⏳ pending |

---

## Trabalho pendente — botopink-lang

### Prioridade alta

**Step 4 — Language-server failures**
- 9 testes falhando em `modules/language-server/src/tests/`
- Causa raiz: `#[@Host]` methods não patcheados em template bodies
- Opções:
  - Estender `patchHostMethods` para template bodies
  - Implementar `#[@Host]` lowering no Erlang codegen

**Allocation leaks**
- Múltiplos codegen tests vazam 1 allocation cada
- Arquivos: values, string interpolation, loop, try/catch, @print, dispatch, destructure

### Próximo passo

1. Corrigir Step 4 (language-server failures)
2. Wave 1 Steps 6-8 (regression tests, codegen crashes)
3. Wave 2 Step 1 (type as first-class value)

---

## Estrutura de arquivos

```
projects/
├── specs/                          ← Specs 1.0.0-beta
│   ├── 1.0.0-beta/
│   │   ├── 01-erl-fixes.md        ← Wave 1: Erlang + Codegen
│   │   ├── 02-typesystem.md       ← Wave 2: Type System
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
| Specs 1.0.0-beta | 2 waves, 22 steps |
| Wave 1 completada | 8/13 steps (62%) |
| Wave 2 completada | 0/9 steps (0%) |
| Testes adicionados | ~550+ |
| Testes falhando | 9 (language-server) |
| Commits não pushados | 0 |
| Branches extras | 0 (apenas main/feat) |
