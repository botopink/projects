# Step 1 — Fix decorator eval (9 failures)

**Status:** 🔄 em andamento — foco em build funcional (2026-09-15)  
**Priority:** 🔴 CRÍTICO  
**Estimativa:** 4-8 horas

---

## Estado Atual

### Nova abordagem implementada

**Mudança de estratégia:** gerar Erlang **direto do AST**, sem passar por:
- JSON intermediário (`handleJson` ainda recebido, mas convertido direto para termos Erlang)
- Source botopink intermediário (sem `emitBpBody` → `compile()` → codegen)
- Parse/lex do código gerado (elimina `parseError` do `compile()`)

### Fluxo direto

```
ast.FnDecl → emitExpr/emitStmt → Erlang source → persistent_erl.eval()
```

### Implementação

- `jsonToErl()` converte `handleJson` diretamente para maps Erlang (`#{kind => ..., name => ...}`)
- `emitExpr()` emite expressões AST direto para Erlang:
  - Field access → `maps:get(field, Recv)`
  - Binary ops → `(Lhs op Rhs)`
  - String literals → `<<"...">>`
  - Identifiers → uppercase first letter (Erlang variables)
- `emitStmt()` emite statements AST direto para Erlang:
  - Bindings → `Var = Expr`
  - Assigns → `Var = Expr`
  - Returns → `erlang:return(Expr)`
- `buildErlModule()` monta módulo Erlang completo com:
  - `-module(decorator_<hash>).`
  - `-export([main/0]).`
  - Plain arg bindings como funções 0-arity
  - Decl handle como map Erlang nativo
  - Corpo do decorator como função Erlang
  - Host functions: `fail/2`, `compilerError/1`, `emit/1`
  - `main/0` com try/catch → JSON via `json:encode`

### Problema anterior (resolvido)

- `compile()` falhava com `parseError` no código botopink gerado
- Parser rejeitava constructs válidos em contexto de `compile()` mas não em parse standalone
- Root cause: contexto de compilação com std imports e múltiplos módulos
- Solução: pular completamente o `compile()` e gerar Erlang direto

---

## Plano de Execução

### FASE 1: Fazer Build Funcional (PRIORIDADE ALTA)

**Objetivo:** Código compila sem erros

#### Passo 1: Ajustar infer.zig para criar DeclHandle
```zig
// Remover:
fn buildHandleJson(...) ![]const u8 { ... }
fn appendAnnotationsJson(...) !void { ... }
fn appendMethodsJson(...) !void { ... }

// Modificar invokeDecorators():
const h = decoratorEval.DeclHandle{
    .kind = "Record",
    .name = r.name,
    .fields = fields,
    .methods = r.methods,
    .returnType = "",
    .annotations = r.annotations,
};

// Modificar runDeclDecorators():
fn runDeclDecorators(
    env: *Env,
    ctx: envMod.TemplateEvalCtx,
    anns: []const ast.Annotation,
    handle: decoratorEval.DeclHandle,  // <- mudar de []const u8
) InferError!void { ... }
```

#### Passo 2: Completar decorator_eval.zig
```zig
// Implementar emitDeclHandle():
fn emitDeclHandle(
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    handle: DeclHandle,
) !void {
    // Converter DeclHandle para termos Erlang
    // #{kind => ..., name => ..., fields => [...], ...}
}

// Ajustar buildErlModule() para usar DeclHandle
```

#### Passo 3: Verificar Build
```bash
zig build test
```
**Critério de sucesso:** Compila sem erros (testes podem falhar)

---

### FASE 2: Corrigir Testes (PRIORIDADE MÉDIA)

**Objetivo:** Testes passam

1. **Validar saída Erlang gerada**
   - Verificar que DeclHandle é convertido corretamente para termos Erlang
   - Verificar que decorator body é emitido corretamente

2. **Corrigir problemas de runtime**
   - Ajustar conversões de tipos (TypeRef → string)
   - Ajustar emissão de constructs específicos (if, loops, etc.)

3. **Rodar testes de decorator**
   - `decorator_invocation.zig` (11 testes)
   - `decorator_regression.zig` (4 testes)

**Critério de sucesso:**
- ✅ `decorator_invocation.zig`: 11/11 testes passam
- ✅ `decorator_regression.zig`: 4/4 testes passam
- ✅ Sem regressões em outros testes

---

### FASE 3: Limpeza e Otimização (PRIORIDADE BAIXA)

**Objetivo:** Código limpo e otimizado

1. Remover código morto
2. Otimizar conversões
3. Atualizar documentação

---

## Próximas Melhorias (Planejadas)

### Remover JSON intermediário completamente

**Problema atual:**
- `infer.zig` cria strings JSON via `buildHandleJson()` ❌
- `decorator_eval.zig` já ajustado para receber `DeclHandle` (estrutura nativa) ✅
- Build quebrado devido a incompatibilidade de tipos

**Solução:**
- `infer.zig` deve criar `DeclHandle` (estrutura nativa) em vez de strings JSON
- `decorator_eval.zig` receberá `DeclHandle` diretamente
- Eliminar completamente o JSON intermediário

**Benefícios:**
1. **Separação de responsabilidades:** infer trabalha com AST, não com JSON
2. **Type safety:** Compilador pega erros de tipo
3. **Performance:** ~30% mais rápido (estima-se) por eliminar serialização
4. **Manutenibilidade:** Código mais simples e direto
5. **Debug:** Mais fácil de debugar estruturas nativas que JSON

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

---

## Histórico de Abordagens

### Abordagem 1: compile() intermediário (abandonada)

- Gerar código botopink sintético → `compile()` → codegen Erlang
- Problema: `compile()` falhava com `parseError` em contexto de múltiplos módulos
- Solução tentada: debug do parser, mas root cause era contexto de compilação

### Abordagem 2: Erlang direto do AST (atual)

- Gerar Erlang direto do AST do decorator body
- Converter `handleJson` → termos Erlang nativos
- Montar módulo Erlang com main/0 + host functions
- Executar no `persistent_erl.eval()`
- Vantagens: mais rápido, mais simples, elimina problemas de parse/compile

---

## Notas de Build

- `zig build test -- --test-filter "..."` **NÃO funciona** no Zig 0.16
- Rodar o binário de teste direto: `.zig-cache/o/<hash>/test`
- `persistent_erl` deixa um processo `beam.smp` órfão por execução
