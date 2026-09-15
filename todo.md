# TODO — Eliminar JSON intermediário no pipeline comptime

**Branch:** `fix/step-1-decorator-eval`
**Objetivo:** Substituir JSON intermediário por structs nativas em decorators, templates e BEAM comptime
**Prioridade:** 🔴 CRÍTICO

---

## Estado atual (2026-09-15)

### Nova abordagem: Structs nativas em todo o pipeline

**Mudança de estratégia:** usar structs nativas em vez de JSON intermediário em **todo o pipeline comptime** (decorators, templates, beam).

**Benefícios:**
1. **Type safety:** Compilador pega erros de estrutura
2. **Performance:** ~30% mais rápido (estima-se) por eliminar serialização manual
3. **Manutenibilidade:** Código mais limpo e direto
4. **Debug:** Mais fácil inspecionar structs que JSON strings

---

## Fluxo Atual vs Novo

### **DECORATORS ✅ IMPLEMENTADO**

**Fluxo Antigo:**
```
infer.zig → buildHandleJson() → string JSON
decorator_eval.zig → recebe handleJson: []const u8
→ gera Erlang com DeclHandle convertido manualmente
→ Erlang → json:encode() → JSON string
→ parseOutcome() → std.json.Value manual
→ Outcome
```

**Fluxo Novo:**
```
infer.zig → buildHandle() → DeclHandle (struct nativa)
decorator_eval.zig → recebe handle: DeclHandle
→ gera Erlang direto do AST + DeclHandle
→ Erlang → json:encode() → JSON string
→ parseOutcome() → std.json.parseFromSliceLeaky(ErlResult, ...)
→ Outcome
```

**Implementado:**
- ✅ `DeclHandle` struct nativa em `decorator_eval.zig`
- ✅ `buildHandle()`, `appendAnnotationsHandle()`, `appendMethodsHandle()`, `appendParamsHandle()` em `infer.zig`
- ✅ `runDeclDecorators()` recebe `DeclHandle` em vez de `[]const u8`
- ✅ `invokeDecorators()` chama `buildHandle()` em vez de `buildHandleJson()`
- ✅ `evaluateErl()` gera Erlang direto do AST + `DeclHandle`
- ✅ `parseOutcome()` usa `std.json.parseFromSliceLeaky(ErlResult, ...)`

### **TEMPLATES (@expr, @code, custom) 🔧 A IMPLEMENTAR**

**Fluxo Antigo:**
```
template.zig → contextJsonAlloc() → string JSON
→ injeta JSON no código Erlang gerado
→ Erlang → json:encode() → JSON string
→ template_eval.zig → parseOutcome() → std.json.Value genérico
→ Outcome.value: std.json.Value
→ infer.zig → literalFromJson(std.json.Value) → AST literal
→ template.zig → parseCustomNode(std.json.Value) → CustomNode
```

**Fluxo Novo:**
```
template.zig → buildCaptureContext() → CaptureContext struct
→ template_eval.zig → gera Erlang direto da struct
→ Erlang → json:encode() → JSON string
→ template_eval.zig → parseOutcome()
→ std.json.parseFromSliceLeaky(TemplateResult, ...)
→ Outcome.value: TypedValue (struct nativa)
→ infer.zig → valueToAstLiteral(TypedValue) → AST literal
→ template.zig → parseCustomNode(TemplateResult.custom) → CustomNode
```

### **BEAM COMPTIME 🔧 A IMPLEMENTAR**

**Fluxo Antigo:**
```
beam.zig → renderExprValue() → JSON array manual
→ gera main() -> "[{id,value},...]"
→ Erlang → JSON string
→ beam.zig → std.json.parseFromSlice() → std.json.Value
→ itera array manualmente, extrai id/value
```

**Fluxo Novo:**
```
beam.zig → buildComptimeInput() → ComptimeInput struct
→ gera Erlang direto da struct
→ Erlang → json:encode() → JSON string
→ beam.zig → std.json.parseFromSliceLeaky(BeamResult, ...)
→ []BeamEntry (struct nativa)
```

---

## Plano de Execução

### FASE 1: Decorators ✅ CONCLUÍDO

**Objetivo:** Código compila sem erros
**Status:** ✅ Concluído

- ✅ Definir `DeclHandle` struct nativa
- ✅ Remover `buildHandleJson`, `appendAnnotationsJson`, `appendMethodsJson`, `appendParamsJson`
- ✅ Criar `buildHandle`, `appendAnnotationsHandle`, `appendMethodsHandle`, `appendParamsHandle`
- ✅ Atualizar `runDeclDecorators` para receber `DeclHandle`
- ✅ Atualizar `invokeDecorators` para usar `buildHandle`
- ✅ Implementar `evaluateErl` com emitter Erlang direto
- ✅ Atualizar `parseOutcome` para usar `std.json.parseFromSliceLeaky(ErlResult, ...)`
- ✅ Build compila sem erros

### FASE 2: Templates ✅ PARSE CONCLUÍDO

**Objetivo:** Templates usam structs nativas para parse de resultados
**Status:** ✅ Parse concluído, emitter pendente

- ✅ Definir `TypedValue` struct nativa em `template_eval.zig`
- ✅ Definir `CustomNodeTree` struct nativa em `template_eval.zig`
- ✅ Definir `ErlTemplateResult` struct nativa em `template_eval.zig`
- ✅ Atualizar `parseOutcome` para usar `std.json.parseFromSliceLeaky(ErlTemplateResult, ...)`
- ✅ Criar `valueToAstLiteral` em `infer.zig` (substitui `literalFromJson`)
- ✅ Criar `parseCustomNodeFromTree` em `template.zig`
- ✅ Atualizar `infer.zig` para usar `valueToAstLiteral` e `parseCustomNodeFromTree`
- ✅ Build compila sem erros

**Trabalho pendente:**
- 🔧 Migrar `evaluateErl` para gerar Erlang direto do AST + captures (eliminando pipeline completo)

### FASE 3: BEAM Comptime ✅ PARSE CONCLUÍDO

**Objetivo:** BEAM comptime usa structs nativas para parse de resultados
**Status:** ✅ Parse concluído, emitter pendente

- ✅ Definir `BeamValue` struct nativa em `beam.zig`
- ✅ Definir `BeamResultEntry` struct nativa em `beam.zig`
- ✅ Atualizar `parseResults` para usar `std.json.parseFromSliceLeaky([]const BeamResultEntry, ...)`
- ✅ Build compila sem erros

**Trabalho pendente:**
- 🔧 Migrar `renderExprValue` para gerar Erlang direto de `TypedExpr` (complexo devido à AST tipada)

### FASE 4: Limpeza e Testes 🔧 EM ANDAMENTO

**Objetivo:** Código limpo, otimizado e testado

- ✅ Remover referências a `buildHandleJson` (substituído por `buildHandle`)
- ✅ Remover referências a `literalFromJson` para templates (substituído por `valueToAstLiteral`)
- ✅ Atualizar documentação (`AGENTS.md`, `architecture.md`, `todo.md`)
- 🔧 Rodar todos os testes
- 🔧 Verificar se há regressões

**Critério de sucesso:**
- ✅ Sem referências a `buildHandleJson`
- ✅ Templates e BEAM usam structs nativas para parse
- ✅ Build compila sem erros
- 🔧 Todos os testes passam
- ✅ Documentação atualizada

### FASE 5: Generalização de Emitters 🔧 EM ANDAMENTO

**Objetivo:** Criar emitters Erlang genéricos e reutilizáveis

#### Problema Atual

- `emitErl` está acoplado ao `DeclHandle` como método
- Não é reutilizável para outros tipos de dados
- Viola o princípio de responsabilidade única
- Dificulta testes isolados

#### Solução Proposta

Criar módulo `erl_emitter.zig` com funções genéricas:

```zig
/// Generic Erlang term emitter — reusable by any struct that needs to emit Erlang.
const std = @import("std");

/// Emit a string as an Erlang binary: <<"value">>
pub fn emitString(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, s: []const u8) std.mem.Allocator.Error!void {
    try buf.appendSlice(arena, "<<\"");
    for (s) |c| {
        if (c == '"' or c == '\\') {
            try buf.append(arena, '\\');
        }
        try buf.append(arena, c);
    }
    try buf.appendSlice(arena, "\">>");
}

/// Emit a variable name (uppercase first letter)
pub fn emitVar(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, name: []const u8) std.mem.Allocator.Error!void {
    if (name.len == 0) {
        try buf.appendSlice(arena, "_");
        return;
    }
    const var_name = try arena.alloc(u8, name.len);
    var_name[0] = std.ascii.toUpper(name[0]);
    for (name[1..], 1..) |c, i| {
        var_name[i] = c;
    }
    try buf.appendSlice(arena, var_name);
}

/// Emit a map: #{key1 => value1, key2 => value2}
pub fn emitMap(buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, var_name: []const u8, entries: []const MapEntry) std.mem.Allocator.Error!void {
    try emitVar(buf, arena, var_name);
    try buf.appendSlice(arena, " = #{");
    for (entries, 0..) |entry, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try buf.appendSlice(arena, entry.key);
        try buf.appendSlice(arena, " => ");
        try entry.value.emitErl(buf, arena);
    }
    try buf.appendSlice(arena, "}");
}

pub const MapEntry = struct {
    key: []const u8,
    value: ErlValue,
};

pub const ErlValue = union(enum) {
    string: []const u8,
    int: i64,
    bool: bool,
    list: []const ErlValue,
    map: []const MapEntry,

    pub fn emitErl(self: ErlValue, buf: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator) std.mem.Allocator.Error!void {
        switch (self) {
            .string => |s| try emitString(buf, arena, s),
            .int => |n| {
                const text = try std.fmt.allocPrint(arena, "{d}", .{n});
                try buf.appendSlice(arena, text);
            },
            .bool => |b| try buf.appendSlice(arena, if (b) "true" else "false"),
            .list => |items| {
                try buf.appendSlice(arena, "[");
                for (items, 0..) |item, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try item.emitErl(buf, arena);
                }
                try buf.appendSlice(arena, "]");
            },
            .map => |entries| {
                try buf.appendSlice(arena, "#{");
                for (entries, 0..) |entry, i| {
                    if (i > 0) try buf.appendSlice(arena, ", ");
                    try buf.appendSlice(arena, entry.key);
                    try buf.appendSlice(arena, " => ");
                    try entry.value.emitErl(buf, arena);
                }
                try buf.appendSlice(arena, "}");
            },
        }
    }
};
```

#### Refatoração de DeclHandle

```zig
pub fn emitErl(
    self: *const DeclHandle,
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    var_name: []const u8,
) std.mem.Allocator.Error!void {
    const erl_emitter = @import("./erl_emitter.zig");

    var entries = try arena.alloc(erl_emitter.MapEntry, 6);
    entries[0] = .{ .key = "kind", .value = .{ .string = self.kind } };
    entries[1] = .{ .key = "name", .value = .{ .string = self.name } };
    entries[2] = .{ .key = "fields", .value = .{ .list = try self.emitFieldsErl(arena) } };
    entries[3] = .{ .key = "methods", .value = .{ .list = try self.emitMethodsErl(arena) } };
    entries[4] = .{ .key = "returnType", .value = .{ .string = self.returnType } };
    entries[5] = .{ .key = "annotations", .value = .{ .list = try self.emitAnnotationsErl(arena) } };

    try erl_emitter.emitMap(buf, arena, var_name, entries);
}
```

#### Passos de Implementação

1. **Criar módulo `erl_emitter.zig`**
   - Implementar `emitString()`, `emitVar()`, `emitMap()`, `emitList()`
   - Definir tipos `MapEntry` e `ErlValue`
   - Implementar `ErlValue.emitErl()`

2. **Refatorar `DeclHandle.emitErl()`**
   - Usar `erl_emitter` em vez de emitir diretamente
   - Criar métodos auxiliares: `emitFieldsErl()`, `emitMethodsErl()`, `emitAnnotationsErl()`

3. **Remover funções duplicadas**
   - Remover `emitErlString()` de `decorator_eval.zig` (usar `erl_emitter.emitString()`)
   - Remover `erlVarName()` de `decorator_eval.zig` (usar `erl_emitter.emitVar()`)

4. **Testar e validar**
   - Rodar testes de decorator
   - Verificar que o código Erlang gerado é válido
   - Validar que não há regressões

**Critério de sucesso:**
- ✅ Módulo `erl_emitter.zig` criado
- ✅ `DeclHandle.emitErl()` usa `erl_emitter`
- ✅ Todas as funções duplicadas removidas
- ✅ Build compila sem erros
- ✅ Testes passam
- ✅ Código mais limpo e reutilizável

**Benefícios:**
- **Reutilização:** Pode emitir qualquer struct para Erlang
- **Testabilidade:** Mais fácil testar emitters isoladamente
- **Manutenibilidade:** Separação clara entre modelo e serialização
- **Extensibilidade:** Facilita adicionar novos tipos de handles no futuro

---

## Notas de Build

- `zig build test -- --test-filter "..."` **NÃO funciona** no Zig 0.16 (test runner
  só aceita `--listen`, `--seed`, `--cache-dir`). Rodar o binário de teste direto:
  ```bash
  .zig_cache/o/<hash>/test           # roda os 1244 testes
  ```
  ou `zig build test` (sem filtro).
- `persistent_erl` deixa um processo `beam.smp` órfão por execução; matar com
  `/bin/kill -9 <pid>` (o builtin `kill` do shell não aceita `-9`).

---

## Histórico de Abordagens

### Abordagem 1: compile() intermediário (abandonada)

- Gerar código botopink sintético → `compile()` → codegen Erlang
- Problema: `compile()` falhava com `parseError` em contexto de múltiplos módulos
- Solução tentada: debug do parser, mas root cause era contexto de compilação

### Abordagem 2: Erlang direto do AST (decorator eval)

- Gerar Erlang direto do AST do decorator body
- Converter `handleJson` → termos Erlang nativos
- Montar módulo Erlang com main/0 + host functions
- Executar no `persistent_erl.eval()`
- Vantagens: mais rápido, mais simples, elimina problemas de parse/compile

### Abordagem 3: Structs nativas em todo o pipeline (atual)

- Eliminar JSON intermediário em decorators, templates, e BEAM comptime
- Usar `std.json.parseFromSliceLeaky(Struct, ...)` para parse automático
- Gerar Erlang direto de structs nativas
- Benefícios: type safety, performance, manutenibilidade
