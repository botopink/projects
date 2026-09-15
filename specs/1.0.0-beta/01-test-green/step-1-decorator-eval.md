# Step 1 — Fix decorator eval (9 failures)

**Status:** 🟡 in progress (investigação concluída; implementação parcial)  
**Priority:** 🔴 CRÍTICO  
**Estimativa:** 4-8 horas

---

## Problema

9 testes em `decorator_invocation.zig` falham com:

```
error: the decorator evaluator failed to run
hint: Decorator bodies run in the node runtime at compile time — check that `node` is available.
```

---

## Testes falhando

| # | Teste | Linha | Complexidade |
|---|-------|-------|--------------|
| 1 | `body accepts a record` | 51 | Baixa |
| 2 | `body rejects wrong placement` | 61 | Baixa |
| 3 | `method placement accepted` | 71 | Baixa |
| 4 | `method decorator rejects a record` | 83 | Baixa |
| 5 | `body reads the reflected name` | 93 | Média |
| 6 | `@compilerError rejects wrong placement` | 103 | Baixa |
| 7 | `@compilerError body accepts the right placement` | 115 | Baixa |
| 8 | `@emit contributes a top-level declaration` | 127 | Alta |
| 9 | `a body may reference an @emit'd declaration` | 155 | Alta |
| 10 | `interface-level marker runs over the interface` | 170 | Média |
| 11 | `mock-style synthesis from an interface compiles` | 182 | Alta |

**Nota:** Alguns testes passam, outros falham. Os que falham usam constructs mais complexos.

---

## Causa raiz (definitiva — atualizada)

A avaliação de decorator via Erlang **nunca esteve completa**. Não é um bug pontual
de "reutilizar o decompiler": o caminho inteiro (`decorator_eval` → codegen Erlang →
`persistent_erl`) está incompleto.

### Evidências

1. **`template_eval.zig:14-20` documenta o gap:**
   > *"evaluateErl() returns EvalFailed until erlang.zig gains #[@Host] method
   > lowering. Methods like Capture.lookup(), Capture.bindings(), failRaw(),
   > makeExpr(), makeCode() are annotated #[@Host] in template_runtime.bp and must
   > be redirected to botopink_comptime_prelude module calls."*

2. **`warmPersistentErlRunner` (`comptime.zig:382`) nunca é chamado.** Ele compila
   `template_runtime.bp` → `template_runtime.erl` e aplica `patchHostMethods`, mas só
   `getStdlibTemplate` é aquecido em `test_warmup.zig`. O `template_runtime.erl`/`.beam`
   nunca é gerado/load no processo erl.

3. **O caminho que FUNCIONA p/ comptime val é `beam.zig`** (`renderExprValue`): avalia
   expressões simples **em Zig** e usa o erl só para devolver um JSON pré-computado
   (`main() -> "<json>".`). Não serve para corpos com `if`/loop/`fail`/`@emit`.

### Falhas concretas observadas (após rodar os testes)

1. **Off-by-one (corrigido):** `decorator_eval.zig` alocava `2 + plainArgs.len` decls,
   mas são 3 fixas (`DeclKind`, handle `@Decl`, fn) + plain args. Crash real:
   `panic: index out of bounds: index 2, len 2`.

2. **`main/0` ausente:** `persistent_erl.eval` chama `Mod:main()`, mas o `.erl` gerado
   não tem `main/0`.

3. **Host functions ausentes:** o corpo gerado chama `fail/2`, `compilerError/1`,
   `emit/1` como funções locais não definidas. `erlc` falha:
   ```
   decorator_body.erl:12:13: function compilerError/1 undefined
   ```

4. **Protocolo de resultado:** `parseOutcome` espera JSON
   (`{"kind":"ok","contributions":[...]}`, `{"kind":"fail","message":...}`), mas o
   servidor erl devolve termo Erlang cru.

5. **`-export([main/0])`** precisa ser inserido logo após `-module(...)`.

### Constructs que os testes exercitam

1. **String concatenation** (`methods = methods + "..."`)
2. **Loops** (`decl.methods.forEach({ m -> ... })`)
3. **@emit** (`@emit("pub fn ...")`)
4. **Field access** (`decl.name`, `m.name`)
5. **Conditionals** (`if (decl.kind != DeclKind.Record)`)
6. **Host calls** (`decl.fail(msg)`, `@compilerError(msg)`)

---

## Solução

### Opção A (recomendada): completar o caminho Erlang

`compileFromAst` + codegen Erlang já geram o corpo corretamente. Falta pós-processar
o `.erl` em `decorator_eval.zig` para adicionar:

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
estendendo p/ `if`/loop/`fail`/`emit`/string concat). Evita o runtime Erlang, mas exige
um mini-interpretador do AST não-tipado.

---

## Implementação detalhada

### 1. Verificar estado atual do decompiler

```bash
# Ver se emitBpExpr está público
grep -n "pub fn emitBp" modules/compiler-core/src/comptime/template_eval.zig
```

### 2. Implementar evaluateErl completo

```zig
fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    // 1. Decompilar corpo do decorator
    var bp_body = std.ArrayList(u8).init(arena);
    defer bp_body.deinit();
    
    try templateEval.emitBpBody(arena, &bp_body, dfn.body);
    
    // 2. Construir script Erlang
    var script = std.ArrayList(u8).init(arena);
    defer script.deinit();
    
    try script.writer().print(
        \\__decorator_body() ->
        \\    {ok, Decl} = botopink_comptime_prelude:decode_decl(~s),
        \\    ~s
        \\    .
    , .{ handleJson, bp_body.items });
    
    // 3. Executar via persistent_erl
    const result = persistent_erl.eval(arena, io, script.items) catch {
        return error.EvalFailed;
    };
    
    // 4. Parsear resultado
    return parseOutcome(arena, result);
}
```

### 3. Adicionar suporte a constructs específicos

**String concatenation:**
```zig
// emitBpExpr já deve suportar BinaryOp com +
```

**Loops:**
```zig
// emitBpExpr já deve suportar Loop/ForEach
```

**@emit:**
```zig
// @emit é um builtin — verificar se emitBpExpr suporta BuiltinCall
```

**Field access:**
```zig
// emitBpExpr já deve suportar FieldAccess
```

**Conditionals:**
```zig
// emitBpExpr já deve suportar If
```

---

## Testes de aceitação

### Teste 1: String concatenation

```botopink
fn mock(comptime decl: @Decl) {
    var methods = "";
    decl.methods.forEach({ m ->
        methods = methods + "  fn " + m.name + "(self: Self) -> i32 { return 0; }\n";
    });
    @emit("record Mock" + decl.name + " { " + methods + " }");
}
#[mock]
interface Counter { fn value(self: Self) -> i32 }
```

**Esperado:** Compila sem erros

### Teste 2: @emit com string dinâmica

```botopink
fn gen(comptime decl: @Decl) {
    @emit("pub fn make" + decl.name + "() -> i32 { return 42; }");
}
#[gen]
record Service { x: i32 }
fn useit() -> i32 { return makeService(); }
```

**Esperado:** Compila sem erros, `makeService()` existe

### Teste 3: Loop com field access

```botopink
fn validate(comptime decl: @Decl) {
    decl.fields.forEach({ f ->
        if (f.name == "bad") { decl.fail("field 'bad' not allowed"); }
    });
}
#[validate]
record Good { name: string }
```

**Esperado:** Compila sem erros

---

## Arquivos a modificar

| Arquivo | Ação | Linhas estimadas |
|---------|------|------------------|
| `decorator_eval.zig` | Implementar `evaluateErl` completo | ~50-100 |
| `template_eval.zig` | Tornar `emitBpBody` público se necessário | ~5 |

---

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Decompiler não suporta todos os constructs | Média | Alto | Testar cada construct individualmente |
| Persistent erl não executa scripts complexos | Baixa | Alto | Verificar logs do erl |
| Performance degrada | Baixa | Médio | Benchmark antes/depois |

---

## Checklist

- [ ] Verificar se `emitBpExpr`/`emitBpStmt` são públicos
- [ ] Implementar `evaluateErl` completo
- [ ] Testar string concatenation
- [ ] Testar loops
- [ ] Testar @emit
- [ ] Testar field access
- [ ] Testar conditionals
- [ ] Rodar `zig build test` — 0 failures em decorator tests
- [ ] Verificar que não há regressões em outros testes
