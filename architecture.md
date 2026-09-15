# Arquitetura: Structs Nativas no Pipeline Comptime

**Data:** 2026-09-15  
**Status:** Decorators ✅, Templates ✅ (parse), BEAM ✅ (parse)

---

## Visão Geral

A arquitetura de comptime do botopink-lang foi migrada de um fluxo baseado em JSON intermediário para um fluxo baseado em structs nativas Zig. Esta mudança melhora type safety, performance e manutenibilidade.

## Problema Antigo

### Fluxo com JSON intermediário

```
Zig → serializa para JSON → envia para runtime → runtime executa → 
runtime serializa resultado para JSON → Zig parseia JSON → Zig usa resultado
```

**Problemas:**
1. **Sem type safety:** JSON é apenas texto, erros de estrutura só são detectados em runtime
2. **Performance:** serialização/desserialização manual é lenta
3. **Manutenibilidade:** código de serialização é verboso e propenso a erros
4. **Debug difícil:** inspecionar strings JSON é mais difícil que inspecionar structs

## Solução: Structs Nativas

### Fluxo com structs nativas

```
Zig → cria struct nativa → emite Erlang direto da struct → 
runtime executa → runtime retorna JSON → Zig parseia JSON para struct nativa → Zig usa struct
```

**Benefícios:**
1. **Type safety:** compilador valida a estrutura dos dados
2. **Performance:** ~30% mais rápido (estima-se) por eliminar serialização manual
3. **Manutenibilidade:** código mais limpo e direto
4. **Debug:** inspecionar structs é mais fácil que inspecionar JSON strings

## Implementação

### 1. Decorators ✅

**Structs definidas em `decorator_eval.zig`:**

```zig
pub const DeclHandle = struct {
    kind: []const u8,
    name: []const u8,
    fields: []const Field,
    methods: []const Method,
    returnType: []const u8,
    annotations: []const Annotation,

    pub const Field = struct {
        name: []const u8,
        typeName: []const u8,
        annotations: []const Annotation = &.{},
    };

    pub const Method = struct {
        name: []const u8,
        params: []const Param,
        returnType: []const u8,
        annotations: []const Annotation = &.{},
    };

    pub const Param = struct {
        name: []const u8,
        typeName: []const u8,
    };

    pub const Annotation = struct {
        name: []const u8,
        args: []const []const u8,
    };
};

const ErlResult = struct {
    kind: []const u8,
    message: ?[]const u8 = null,
    contributions: ?[]const []const u8 = null,
    span: ?ErlSpan = null,
};
```

**Funções em `infer.zig`:**

```zig
fn buildHandle(...) !decoratorEval.DeclHandle
fn appendAnnotationsHandle(...) ![]const decoratorEval.DeclHandle.Annotation
fn appendMethodsHandle(...) ![]const decoratorEval.DeclHandle.Method
fn appendParamsHandle(...) ![]const decoratorEval.DeclHandle.Param
```

**Emitter Erlang em `decorator_eval.zig`:**

```zig
fn emitDeclHandle(buf, arena, handle, var_name) !void
fn emitBody(buf, arena, dfn) !void
fn emitStmt(buf, arena, expr) !void
fn emitExpr(buf, arena, expr) !void
```

### 2. Templates ✅ (parse)

**Structs definidas em `template_eval.zig`:**

```zig
pub const TypedValue = union(enum) {
    integer: i64,
    float: f64,
    string: []const u8,
    bool: bool,
    null: void,
    array: []const TypedValue,
    object: []const KeyValuePair,

    pub const KeyValuePair = struct {
        key: []const u8,
        value: TypedValue,
    };
};

pub const CustomNodeTree = struct {
    kind: []const u8,
    span: ?template.Span = null,
    label: ?[]const u8 = null,
    ref: ?[]const u8 = null,
    children: []const CustomNodeTree = &.{},
};

const ErlTemplateResult = union(enum) {
    code: struct { source: []const u8 },
    value: struct { value: TypedValue },
    capture: struct { param: []const u8 },
    custom: struct { source: []const u8, ast: CustomNodeTree },
    fail: struct {
        message: []const u8,
        param: ?[]const u8 = null,
        span: ?template.Span = null,
    },
    err: struct { message: []const u8 },
};
```

**Funções em `infer.zig`:**

```zig
fn valueToAstLiteral(env: *Env, v: templateEval.TypedValue, loc: ast.Loc) ?*const ast.Expr
```

**Funções em `template.zig`:**

```zig
pub fn parseCustomNodeFromTree(arena: std.mem.Allocator, tree: template_eval.CustomNodeTree) error{OutOfMemory}!CustomNode
```

**Nota:** O emitter Erlang ainda usa o pipeline completo de compilação (gerando código botopink sintético). A migração para emitter direto é um trabalho futuro.

### 3. BEAM Comptime ✅ (parse)

**Structs definidas em `beam.zig`:**

```zig
const BeamValue = union(enum) {
    integer: i64,
    float: f64,
    string: []const u8,
    bool: bool,
    null: void,
    array: []const BeamValue,
};

const BeamResultEntry = struct {
    id: []const u8,
    value: BeamValue,
};
```

**Função atualizada:**

```zig
fn parseResults(allocator: std.mem.Allocator, data: []const u8, out: *std.StringHashMap([]const u8)) !void
```

**Nota:** O emitter (`renderExprValue`) ainda renderiza `TypedExpr` como JSON. A migração para emitter direto é um trabalho futuro devido à complexidade da AST tipada.

## Como Funciona

### Entrada (Zig → Erlang)

1. Zig cria struct nativa (ex: `DeclHandle`)
2. Emitter Erlang percorre a struct e gera código Erlang direto
3. Código Erlang é escrito em arquivo `.erl`
4. `persistent_erl.eval()` compila e executa o arquivo

### Saída (Erlang → Zig)

1. Erlang executa e retorna JSON via `json:encode()`
2. Zig usa `std.json.parseFromSliceLeaky(Struct, ...)` para parsear JSON direto para struct nativa
3. Zig usa a struct nativa

**Exemplo:**

```zig
// Erlang retorna: {"kind":"ok","contributions":["pub fn helper() {}"]}
// Zig parseia automaticamente:
const result = std.json.parseFromSliceLeaky(ErlResult, arena, stdout, .{}) catch ...;
// result.kind == "ok"
// result.contributions == ["pub fn helper() {}"]
```

## JSON de Saída

O JSON de saída **não foi eliminado** — ele ainda é usado para comunicação inter-processo entre Zig e Erlang. O que foi eliminado é o JSON de **entrada** (DeclHandle) e o parse manual de JSON de saída.

**Fluxo atual:**
```
Zig (DeclHandle nativo) → gera Erlang → Erlang executa → retorna JSON → Zig parseia para ErlResult struct
```

**Por que manter JSON de saída?**
- `json:encode` é builtin no Erlang/OTP 27+
- `std.json.parseFromSliceLeaky` é rápido no Zig
- Overhead é mínimo vs IPC (que já é o gargalo)
- Eliminar JSON de saída exigiria parser manual de termos Erlang (complexo, propenso a erros)

## Migração

### Passo a passo

1. **Definir structs nativas** para entrada e saída
2. **Criar funções** que constroem structs nativas (ex: `buildHandle`)
3. **Implementar emitter** que gera Erlang direto da struct
4. **Atualizar parse** para usar `std.json.parseFromSliceLeaky(Struct, ...)`
5. **Remover funções antigas** de serialização JSON
6. **Testar** com testes existentes

### Critérios de sucesso

- ✅ Build compila sem erros
- ✅ Todos os testes passam
- ✅ Sem referências a funções JSON antigas
- ✅ Documentação atualizada

## Status Atual

### ✅ Concluído

1. **Decorators:**
   - ✅ `DeclHandle` struct nativa
   - ✅ Emitter Erlang direto do AST + DeclHandle
   - ✅ `parseOutcome` usa `std.json.parseFromSliceLeaky(ErlResult, ...)`
   - ✅ `infer.zig` usa `buildHandle` em vez de `buildHandleJson`

2. **Templates (parse):**
   - ✅ `TypedValue` struct nativa
   - ✅ `CustomNodeTree` struct nativa
   - ✅ `ErlTemplateResult` struct nativa
   - ✅ `parseOutcome` usa `std.json.parseFromSliceLeaky(ErlTemplateResult, ...)`
   - ✅ `infer.zig` usa `valueToAstLiteral` em vez de `literalFromJson`
   - ✅ `template.zig` tem `parseCustomNodeFromTree`

3. **BEAM Comptime (parse):**
   - ✅ `BeamValue` struct nativa
   - ✅ `BeamResultEntry` struct nativa
   - ✅ `parseResults` usa `std.json.parseFromSliceLeaky([]const BeamResultEntry, ...)`

### 🔧 Trabalho Futuro

1. **Templates (emitter):**
   - 🔧 Migrar `evaluateErl` para gerar Erlang direto do AST + captures
   - 🔧 Eliminar pipeline completo de compilação (gerar código botopink sintético)

2. **BEAM Comptime (emitter):**
   - 🔧 Migrar `renderExprValue` para gerar Erlang direto de `TypedExpr`
   - 🔧 Eliminar serialização manual de JSON

3. **Generalização de Emitters:**
   - 🔧 Criar módulo `erl_emitter.zig` com funções reutilizáveis
   - 🔧 Refatorar `DeclHandle.emitErl()` para usar `erl_emitter`
   - 🔧 Remover funções duplicadas (`emitErlString`, `erlVarName`)
   - 🔧 Benefícios: reutilização, testabilidade, manutenibilidade

## Generalização de Emitters

### Problema Atual

- `emitErl` está acoplado ao `DeclHandle` como método
- Não é reutilizável para outros tipos de dados
- Viola o princípio de responsabilidade única
- Dificulta testes isolados

### Solução Proposta

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

### Refatoração de DeclHandle

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

### Benefícios

- **Reutilização:** Pode emitir qualquer struct para Erlang
- **Testabilidade:** Mais fácil testar emitters isoladamente
- **Manutenibilidade:** Separação clara entre modelo e serialização
- **Extensibilidade:** Facilita adicionar novos tipos de handles no futuro

### Estrutura Proposta

```
src/comptime/
├── erl_emitter.zig          # Novo: emitters genéricos
│   ├── emitString()
│   ├── emitVar()
│   ├── emitMap()
│   ├── emitList()
│   ├── MapEntry
│   └── ErlValue
├── decorator_eval.zig       # Usa erl_emitter
│   └── DeclHandle
│       └── emitErl()        # Usa erl_emitter
├── template_eval.zig        # Pode usar erl_emitter no futuro
└── runtime/beam.zig         # Pode usar erl_emitter no futuro
```

## Referências

- **Implementação decorators:** `decorator_eval.zig`, `infer.zig`
- **Implementação templates:** `template_eval.zig`, `template.zig`, `infer.zig`
- **Implementação BEAM:** `runtime/beam.zig`
- **Plano completo:** `.tasks/step-1-decorator-eval/todo.md`
- **Documentação comptime:** `modules/compiler-core/src/comptime/AGENTS.md`
