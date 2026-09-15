# Step 2 — Allocation leaks

**Prioridade:** 🟡 ALTA
**Branch:** `fix/step-2-allocation-leaks`

---

## Problema

`zig build test` reporta **13 leaks**, todos de 1 alocação, em testes de snapshot de codegen
(`std.testing.allocator` detecta o leak ao fim de cada teste):

| Arquivo (`modules/compiler-core/src/codegen/tests/`) | Teste |
|---|---|
| `values.zig` | `string ---- interpolation lowers to concat` |
| `control_flow.zig` | `loop ---- side-effect print in iterator` |
| `control_flow.zig` | `try ---- nested try catch` |
| `control_flow.zig` | `try ---- catch preserves surrounding bindings` |
| `control_flow.zig` | `try ---- multiple catch with different fallbacks` |
| `builtins.zig` | `builtin ---- @print multiple arguments` |
| `builtins.zig` | `builtin ---- @print with variable` |
| `dispatch.zig` | `dispatch ---- multi-module extension activated via star import` |
| `features.zig` | `destructure ---- record val binding` |
| `features.zig` | `destructure ---- tuple val binding` |
| `narrowing.zig` | `narrow ---- case enum area with print` |
| `wat.zig` | `string concat of two literals` |
| `wat.zig` | `string length after concat` |

## Causa

Os 13 stack traces apontam para o mesmo lugar: `codegen/runtime.zig` `executeErlang`
(executado por `codegen.generate` ao preencher o RUN LOG erlang de cada snapshot).
A saída de `runWithTimeout` para `erlc` (`compile_out`, e `aux_out` nos módulos auxiliares)
é alocada com `toOwnedSlice` e nunca liberada; quando o `erlc` imprime algo, o
`return allocator.dupe(u8, "")` antecipado deixa o buffer para trás. Só vaza nos
testes cujo Erlang gera saída no `erlc` (warnings/erros), por isso 13 e não todos.

---

## Plano

1. Liberar `compile_out`/`aux_out` (`defer allocator.free(...)`) em `executeErlang`;
   conferir o mesmo padrão em `executeBeamAsm` e `executeJavaScript`.
2. Avaliar se a saída do `erlc` deveria ir para o RUN LOG em vez de ser descartada
   (hoje o snapshot fica com RUN LOG vazio sem explicação).
3. Rodar a suíte e confirmar 0 leaks.

## Aceitação

- [ ] `zig build test` sem `leaked` na saída
- [ ] Sem regressões de snapshot
