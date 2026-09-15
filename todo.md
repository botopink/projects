# TODO — Step 1: Fix decorator eval (9 failures)

**Branch:** `fix/step-1-decorator-eval`
**Commit base:** `8d88372` (feat com interface literal tests)
**Objetivo:** decorator tests verdes (9 em `decorator_invocation.zig` + 4 em `decorator_regression.zig`)
**Prioridade:** 🔴 CRÍTICO

---

## Estado real (após investigação profunda — 2026-09-15)

### O que a sessão anterior fez (parcialmente concluído)

- ✅ `compileFromAst` criado em `comptime.zig` — compila um `ast.Program` direto (pula lex/parse).
- ✅ `decorator_eval.zig` refatorado — constrói AST direto (`jsonToExpr` + `buildDeclKindRecord`),
  remove o modificador `comptime` do 1º parâmetro do fn.
- ✅ Fix no codegen Erlang: `atomName(f.name)` em `recordLit`/`interfaceLit`
  (`codegen/erlang.zig:3031,3040`) — gera `#{'Record' => ...}` em vez de `#{Record => ...}`
  (Erlang interpreta `Record` como variável, não átomo).

### O que ainda quebra (bloqueando os testes)

1. **CRASH off-by-one (corrigido)** — `decorator_eval.zig:188`
   - `arena.alloc(ast.DeclKind, 2 + plainArgs.len)` → deve ser **`3 + plainArgs.len`**.
   - São 3 decls fixas: `DeclKind`, handle `@Decl`, e o fn do decorador.
   - Crash real observado: `panic: index out of bounds: index 2, len 2` no teste
     `body accepts a record`.

2. **`main/0` ausente** — `persistent_erl.eval` chama `Mod:main()`, mas o módulo gerado
   não tem `main/0`. Precisa sintetizar `main/0` que chama o decorador com `decl()` + args.

3. **Host functions ausentes** — o corpo gerado chama `fail/2`, `compilerError/1`,
   `emit/1` como funções locais não definidas → `erlc` falha com
   `function compilerError/1 undefined`. Precisa defini-las (ou redirecionar para
   `botopink_comptime_prelude`).

4. **Protocolo de resultado** — `parseOutcome` espera JSON
   (`{"kind":"ok","contributions":[...]}`, `{"kind":"fail","message":...}`), mas o
   servidor erl devolve termo Erlang cru. `main/0` precisa montar esse JSON
   (com escape de string para os `@emit`).

5. **`-export([main/0])`** — precisa ser inserido logo após `-module(...)`, senão
   `Mod:main()` não é exportado.

6. **Regenerar snapshots** — o fix `atomName` muda a saída Erlang de vários snapshots.
   Já há `.snap.md.new` gerados (ver lista abaixo); falta apagar os antigos e rodar
   `zig build test` para recriar.

---

## Testes falhando

| # | Teste | Arquivo | Erro observado |
|---|-------|---------|----------------|
| 1 | `body accepts a record` | decorator_invocation.zig:51 | panic: index out of bounds (off-by-one) |
| 2 | `body rejects wrong placement` | decorator_invocation.zig:61 | PersistentErlCompileError |
| 3 | `method placement accepted` | decorator_invocation.zig:71 | PersistentErlCompileError |
| 4 | `method decorator rejects a record` | decorator_invocation.zig:83 | PersistentErlCompileError |
| 5 | `body reads the reflected name` | decorator_invocation.zig:93 | PersistentErlCompileError |
| 6 | `@compilerError rejects wrong placement` | decorator_invocation.zig:103 | PersistentErlCompileError |
| 7 | `@compilerError body accepts the right placement` | decorator_invocation.zig:115 | PersistentErlCompileError |
| 8 | `@emit contributes a top-level declaration` | decorator_invocation.zig:127 | PersistentErlCompileError |
| 9 | `a body may reference an @emit'd declaration` | decorator_invocation.zig:155 | PersistentErlCompileError |
| 10 | `interface-level marker runs over the interface` | decorator_invocation.zig:170 | PersistentErlCompileError |
| 11 | `mock-style synthesis from an interface compiles` | decorator_invocation.zig:182 | PersistentErlCompileError |

### Erro detalhado

Compilar o `decorator_body.erl` gerado manualmente com `erlc` mostra:

```
decorator_body.erl:12:13: function compilerError/1 undefined
%   12|             compilerError(<<"#[service] must annotate a record">>);
```

O módulo gera `fail(...)`, `compilerError(...)`, `emit(...)` como chamadas locais
sem definição. Faltam o `main/0` e essas funções host.

---

## Causa raiz (definitiva)

A avaliação de decorator via Erlang **nunca esteve completa**. Evidências:

- `template_eval.zig` (linha 14-20) documenta: *"evaluateErl() returns EvalFailed
  until erlang.zig gains #[@Host] method lowering"*.
- `warmPersistentErlRunner` em `comptime.zig:382` (compila `template_runtime.bp`
  → `template_runtime.erl` e aplica `patchHostMethods`) **não é chamado em lugar
  nenhum** — só `getStdlibTemplate` é aquecido em `test_warmup.zig`.
- O caminho que FUNCIONA para comptime val é `beam.zig` (`renderExprValue`),
  que avalia expressões simples **em Zig** e só usa o erl para devolver um JSON
  pré-computado (`main() -> "<json>".`). Não serve para corpos com `if`/loop/`fail`.

O corpo do decorador (`fail`/`@emit`/`@compilerError`/string concat/loop/field access)
não é reduzível por inspeção (V1), então `decoratorEval.evaluate` → `evaluateErl`
é atingido e falha.

---

## Solução (a implementar)

### Opção A (recomendada): completar o caminho Erlang

Já há `compileFromAst` + codegen Erlang gerando o corpo corretamente. Falta pós-processar
o `.erl` gerado em `decorator_eval.zig` para adicionar:

1. `-export([main/0]).` logo após `-module(...)`.
2. Host functions:
   ```erlang
   fail(Decl, Msg) -> erlang:throw({comptime_fail, Msg, #{}}).
   compilerError(Msg) -> erlang:throw({comptime_fail, Msg, #{}}).
   emit(Src) -> erlang:put('__emit', [Src | emit_stack()]).
   emit_stack() -> case erlang:get('__emit') of undefined -> []; L -> L end.
   ```
3. `main/0` que chama `fn(decl(), <arg>()...)`, captura `{comptime_fail, Msg, _}`
   e devolve o JSON esperado por `parseOutcome` (com escape de string p/ os `@emit`).

### Opção B (alternativa): interpretador em Zig

Interpretar o corpo do decorador direto em Zig (como `beam.zig` faz com expressões,
mas estendendo p/ `if`/loop/`fail`/`emit`/string concat). Evita o runtime Erlang,
porém exige um mini-interpretador completo do AST não-tipado.

---

## Snapshots pendentes (`.snap.md.new` já gerados)

```
codegen/beam/beam/array_zip_via_external_node_template.snap.md.new
codegen/beam/beam/builtin_print_return_value_void.snap.md.new
codegen/beam/beam/external_a3_result_template_owned_declare_fn.snap.md.new
codegen/beam/beam/stdlib_associated_fn_namespace_injected.snap.md.new
codegen/beam/beam/std_package_order_enum_module_with_type_export.snap.md.new
codegen/erlang/erlang/anon_record_literal_nested.snap.md.new
codegen/erlang/erlang/call_children_coercion_list_single_text.snap.md.new
codegen/erlang/erlang/external_import_binds_symbol.snap.md.new
codegen/erlang/erlang/fn_max_via_if_comparison.snap.md.new
codegen/erlang/erlang/if_with_else_branch.snap.md.new
codegen/erlang/erlang/nested_anon_record_chained_field_read.snap.md.new
```

**Atenção:** os `.new` de `beam/` e alguns de `erlang/` (ex.: `fn_max_via_if_comparison`,
`if_with_else_branch`) NÃO são do fix `atomName` — são diferenças de execução de testes
(output extra) ou `no_auto_import`. Precisam ser revisados individualmente antes de aceitar.

---

## Checklist

- [x] Corrigir off-by-one (`3 + plainArgs.len`)
- [ ] Sintetizar `main/0` no módulo Erlang gerado
- [ ] Definir host functions (`fail`, `compilerError`, `emit`)
- [ ] Montar JSON de resultado com escape de string
- [ ] Inserir `-export([main/0])` após `-module(...)`
- [ ] Testar string concatenation
- [ ] Testar loops (`forEach`)
- [ ] Testar `@emit`
- [ ] Testar field access
- [ ] Testar conditionals
- [ ] Rodar `zig build test` — 0 falhas nos decorator tests
- [ ] Revisar/regenerar snapshots afetados (não aceitar cegamente os `.new`)
- [ ] Verificar que não há regressões em outros testes

---

## Notas de build

- `zig build test -- --test-filter "..."` **NÃO funciona** no Zig 0.16 (test runner
  só aceita `--listen`, `--seed`, `--cache-dir`). Rodar o binário de teste direto:
  ```bash
  .zig-cache/o/<hash>/test           # roda os 1244 testes
  ```
  ou `zig build test` (sem filtro).
- O binário de teste já compilado com as mudanças atuais é o de ~73 MB
  (ex.: `.zig-cache/o/5e3b2762.../test`).
- `persistent_erl` deixa um processo `beam.smp` órfão por execução; matar com
  `/bin/kill -9 <pid>` (o builtin `kill` do shell não aceita `-9`).
