# Step 3 — Regression tests de decorator

**Prioridade:** 🟢 MÉDIA
**Branch:** `fix/step-3-regression-tests`
**Depende de:** Step 1

---

## Estado

Os testes existem em `modules/compiler-core/src/comptime/tests/decorator_regression.zig`
(registrados em `comptime/tests.zig`). Hoje 2 dos 4 falham porque dependem do Step 1.

| Teste | Helper | Cobre |
|---|---|---|
| `loop in body` | `assertRejects` | `decl.fields.forEach` com `decl.fail` dentro da lambda |
| `conditional in body` | `assertRejects` | `if` aninhado, `DeclKind.Record`, `decl.fields.len` |
| `string concat in body` | `assertRejects` | `var msg` religado com `msg + decl.name` |
| `@emit in body` | `assertAccepts` | `@emit` com concatenação + uso da fn emitida |

## Problema a corrigir

`assertRejects` procura o texto esperado no erro **renderizado**, que inclui o trecho do
código-fonte. Como a mensagem (`"field 'bad' not allowed"`, `"too many fields"`) aparece
literalmente no fonte, os testes `loop` e `conditional` passam mesmo com o avaliador
quebrado. Comparar só a mensagem do `TypeError` (não o render com fonte), ou montar a
mensagem no decorator de forma que ela não exista literal no fonte.

Leaks não precisam de testes dedicados: `std.testing.allocator` já falha o teste que vaza.

## Aceitação

- [ ] `assertRejects` não casa com o trecho de código-fonte
- [ ] 4/4 passando após o Step 1
- [ ] Cada teste falha se a feature que cobre for quebrada
