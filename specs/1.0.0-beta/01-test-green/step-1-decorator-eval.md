# Step 1 — Fix decorator eval (9 failures)

**Status:** ⏳ pending  
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

## Causa raiz

### Análise do código

**`decorator_eval.zig:94-100`:**
```zig
fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handleJson: []const u8,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    // ... implementação
}
```

**Problema identificado:**
- `evaluateErl()` retorna `error.EvalFailed` para decorators complexos
- O decompiler `emitBpExpr` em `template_eval.zig` já está completo
- Mas `decorator_eval.zig` não o usa corretamente ou tem gaps na implementação

### Constructs que falham

Baseado nos testes, os decorators que falham usam:

1. **String concatenation** (`methods = methods + "..."`)
2. **Loops** (`decl.methods.forEach({ m -> ... })`)
3. **@emit** (`@emit("pub fn ...")`)
4. **Field access** (`decl.name`, `m.name`)
5. **Conditionals** (`if (decl.kind != DeclKind.Record)`)

---

## Solução

### Opção A (recomendada): Reutilizar decompiler

**Arquivos a modificar:**
- `modules/compiler-core/src/comptime/decorator_eval.zig`
- `modules/compiler-core/src/comptime/template_eval.zig` (se necessário)

**Passos:**

1. **Verificar se `emitBpExpr`/`emitBpStmt` são públicos em `template_eval.zig`**
   ```zig
   // template_eval.zig
   pub fn emitBpExpr(...) void { ... }
   pub fn emitBpStmt(...) void { ... }
   ```

2. **Importar em `decorator_eval.zig`**
   ```zig
   const templateEval = @import("template_eval.zig");
   ```

3. **Usar o decompiler em `evaluateErl`**
   ```zig
   fn evaluateErl(...) EvalError!Outcome {
       // Decompilar o corpo do decorator para BP source
       var bp_source = std.ArrayList(u8).init(arena);
       templateEval.emitBpBody(&bp_source, dfn.body);
       
       // Executar via persistent_erl
       // ...
   }
   ```

4. **Testar cada construct**
   - String concat
   - Loops
   - @emit
   - Field access
   - Conditionals

### Opção B: Implementar decompiler separado

**Não recomendado** — duplicaria código e aumentaria manutenção.

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
