# Botopink Compiler — Summary of Recent Changes

## Version: v1.0.10-beta (draft — effects by return type)

### Overview

The effect of a function is its return type (decisions 118–128). The six effect
annotations leave, `@Future<T, E>` becomes `@Task<T>`, which never fails, and
only `@Result` fails: a fallible task is `@Task<@Result<T, E>>`. Blocks and loops
gain prefixes — `async { }`, `iter` and `stream` — and hooks and components share
one wrapper, `@Component<C, T>`. There is no compatibility window (decision 127):
the old forms are located compile errors, each naming its new spelling. There is
no automatic rewriter (decision 131).

---

## Key Changes

### 1. The return is the annotation

| Before | After |
|---|---|
| `#[@X]` annotation + `@X` wrapper in the return | the wrapper in the return only (118) |
| `@Future<T, E>` (may fail) | `@Task<T>` (never fails); failure is `@Task<@Result<T, E>>` (120) |
| `await x` propagates the error | `await x` answers the `@Result`; `try await x` propagates (120) |
| every hook and component may `throw` | `throw` / `try` only where the return carries a `@Result` (121) |
| `@Use<C, T>` (hook) · `@Component<T>` (component) | one wrapper, `@Component<C, T>`, the base always written (128) |
| `@Generator<T>` · `@ResultGenerator<T, E>` · `@FutureGenerator<T, E>` | `@Iterator<T>` · `@Iterator<@Result<T, E>>` · `@Stream<@Result<T, E>>` (122) |
| `YieldStep<T, E>` with `Error` | `YieldStep<T>` = `{ Yield(value: T), Done }` (122) |
| `for` over a fallible generator is an implicit `try` | `for` hands over the `@Result`; the `try` is explicit (122) |
| `#[@generator] loop { … }` / `#[@futureGenerator] loop { … }` | `iter loop` · `iter while` · `iter for` / `stream loop` · `stream while` · `stream for` (125) |
| — | `async { … }` → `@Task<T>`, in any function (124) |
| `return r` re-wraps an existing `@Result` | `return` wraps a plain value and passes a wrapper-typed one through (119) |

### 2. JavaScript interop — a failing Task resolves, it does not reject

On commonJS a `@Task` (and `@Component`) function is still an `async function`,
but **a `throw` in a `@Task<@Result<…>>` resolves the Promise with the `Error`
value instead of rejecting it**. JavaScript that calls a botopink function and
relied on `catch` / `.catch()` now reads the value it answers. In the other
direction, an `#[@External.Node]` declared `-> @Task<@Result<T, E>>` turns a
rejected Promise into `Error(…)`; declared `-> @Task<T>`, a rejection is a fatal
host failure. On erlang an `{error, R}` from an `#[@External.Erlang]` declared
`-> @Task<@Result<T, E>>` becomes `Error(R)`.

### 3. New diagnostics

`effect-annotation-removed`, `effect-type-removed`, `iterator-error-param-removed`
(the migration errors, each with a fix-it); `effect-await-without-task` (was
`effect-await-without-future`); `effect-wrapper-behind-alias`,
`effect-return-ambiguous-nesting`, `iter-await`, `iter-mixed-yield-return`,
`gen-infer-conflicting-errors`.

### 4. The libraries and the reference

std (`async`, `http`), jhonstart, rakun, emilia, onze and erika are rewritten to
the new surface; `docs.md` documents it (§ *Effects*, *Results*, *Tasks*,
*Iterators and streams*, *use*, *Loops*, *Host bindings*, *Migrating from the
effect annotations*), and the 1.0.10-beta library specs' examples are written in
it.

---

## Migration Guide

Compile the project: each old form is a located error whose fix-it names the
new spelling (`docs.md` § *Migrating from the effect annotations* carries the
full old → new table). Remove the annotations, rename the wrappers and loops, and
write `try await` where the function's return carries a `@Result`. Five changes
are not a rename and need a decision per site:

- an `await` or `throw` in a hook or component whose `T` is not a `@Result` — the
  error has nowhere to go: handle it with `try … catch`, `case` or a navigation
  signal, or make the hook return `@Component<C, @Result<T, E>>`;
- a `for` / `for await` over what was a fallible generator — add `try r` or a
  `case`;
- a `case` over `YieldStep` with an `.Error` arm, and code that called `.next()`
  by hand and handled `Error`;
- a wrapper alias used as a return;
- JavaScript that expected a rejected Promise.

---


## Version: v0.0.12-beta (April 2026)

### Overview

Introdução do **language-server** completo, novo operador `catch` universal,
anotações de tipo obrigatórias em parâmetros de função, refactor do AST
(`typeRef` estruturado), módulo `compiler-cli` e workspace build unificado.

---

## Key Changes

### 1. Language-server — novo módulo (`modules/language-server/`)

Motor LSP completo implementado em Zig:

| Feature | Descrição |
|---------|-----------|
| Diagnostics | Erros de parse + erros de comptime validation |
| Hover | Tipo inferido do símbolo sob o cursor |
| Go-to-definition | Localiza a declaração do símbolo |
| Document symbols | Lista todas as declarações do arquivo |
| Completion | Filtra bindings pelo prefixo digitado |
| References | Todas as ocorrências de um símbolo |
| Rename | Renomeia todas as ocorrências |
| Signature help | Parâmetros da função enquanto o usuário digita `f(` |
| Inlay hints | Tipos inferidos após cada declaração |
| Formatting | Reformatação via pretty-printer existente |

**56 testes passando** com snapshot testing estilo Gleam (cursor `↑` alinhado
na posição exata dentro do code block).

**Padrão split-compile** para signature help: bindings da última compilação
bem-sucedida + text-scan da fonte atual (possivelmente incompleta) — reflete
o comportamento real de um LSP server em produção.

---

### 2. Operador `catch` universal (substitui `orthrow`)

```botopink
// Antes
val x = riskyOp() |> orthrow;

// Depois — catch é o operador tail universal para error propagation
val x = riskyOp() catch;
val y = parse(input) catch |err| handleErr(err);
```

`orthrow` foi removido; `catch` funciona como operador tail em qualquer
posição de expressão.

---

### 3. Tipo obrigatório em parâmetros de função

```botopink
// Antes (permitido)
fn identity(x) { return x; }

// Agora (obrigatório)
fn identity(x: i32) { return x; }
```

O parser retorna `UnexpectedToken` se o `:` + tipo estiver ausente. Isso
habilita inferência completa do tipo da função sem depender de call sites.

---

### 4. AST: `typeRef` estruturado em `Param`

`Param.type_name: []const u8` substituído por `Param.typeRef: TypeRef` —
suporta tipos complexos (`T[]`, `?T`, `fn(A) -> B`, genéricos `T<U>`) em
parâmetros sem ambiguidade.

---

### 5. Compiler-core: resiliência LSP

- `ComptimeOutput.Outcome` ganhou variante `.parseError` — fontes incompletas
  (como `val r = add(`) não propagam erros, apenas marcam o output como
  parse-failed.
- `TypedBinding` de `fn` agora guarda o tipo `.func` real (não um `namedType`
  com string), permitindo que o engine de signature help detecte tipos de
  função corretamente.
- `root.zig` separado de `test_root.zig`: importar `botopink` como dependência
  não puxa mais os testes do compiler-core para o binário consumidor.

---

### 6. Workspace build unificado

```
zig build        → compila botopink (CLI) + botopink-lsp
zig build test   → roda compiler-core (758 testes) + language-server (56 testes)
zig build run    → compila e executa o botopink CLI
```

- `modules/compiler-cli/` — executável `botopink`
- `modules/language-server/` — executável `botopink-lsp`
- Snapshots de codegen gravados em `modules/compiler-core/snapshots/` (não
  mais na raiz do workspace)

---

### 7. stdlib

- `fn block<T>(body: fn() -> T) T` — block scope como expressão
- `panic` e `trap` agora têm tipo de retorno `noreturn`

---

## Testing

```
✅ 758 testes do compiler-core passando
✅  56 testes do language-server passando (todos novos)
```

---

## Version: v0.0.11-beta (April 2026)

### Overview

Major refactoring focused on **allocator consistency**, **code deduplication**, and **Erlang codegen support**.

---

## Key Changes

### 1. Allocator Pattern — "Never Store, Always Pass"

**Problem:** Parser stored `allocator` as a struct field, creating implicit dependencies and making it harder to track allocation ownership.

**Solution:**
- Removed `allocator` field from `Parser` struct
- `Parser.init(tokens)` — receives only tokens
- `Parser.initWithSource(tokens, source)` — receives only tokens and source
- All parse methods receive `alloc: std.mem.Allocator` as first parameter

**Applied to:**
- `Parser` — `init(tokens)`, all methods use `alloc` parameter
- `Lexer` — `init(source)`, `scanAll(alloc)`, `deinit(alloc)`
- All codegen functions — `alloc: std.mem.Allocator` as first parameter
- All Emitter structs — `alloc` passed in `init()`, named consistently

**Naming convention:** All parameters use `alloc` (not `allocator`) for consistency.

---

### 2. Code Deduplication via Helper Functions

**Binary Operator Emission:**
- **Before:** 14 operators × 6 lines = 84 lines (commonJS.zig)
- **Before:** 12 operators × 6 lines = 72 lines (erlang.zig)
- **After:** 1 helper function + 14/12 single-line calls
- **Savings:** ~104 lines eliminated

**Parser Helpers Created:**
| Helper | Replaces | Savings |
|--------|----------|---------|
| `boxExpr(alloc, expr)` | `alloc.create(Expr)` pattern (34 occurrences) | ~30 lines |
| `parseStmtListInBraces(alloc)` | Duplicate `parseBraceBlock` + 6 similar blocks | ~60 lines |
| `parseCommaSeparatedIdentifiers(alloc, stopAt)` | Comma-separated identifier loops | ~20 lines |
| `reportReservedWordError()` | Reserved word error blocks (2 occurrences) | ~18 lines |

**Total savings:** ~122 lines of repetitive code eliminated.

---

### 3. Erlang Codegen Support

**New backend:** `codegen/erlang.zig`
- Generates `.erl` files directly from Zig
- Erlang-style operators: `div`, `rem`, `=:`, `=/=`, `=<`
- Module header and export declarations
- Comptime evaluation via Erlang's `json:encode/1`
- Function arity calculation (excludes `self` parameter)
- Consistent `emitBinaryOp` helper with CommonJS

---

### 4. New Language Features

**Pipeline operator:** `a |> b |> c`
- Left-associative function composition
- Emits as nested calls: `c(b(a))`

**Anonymous functions:** `fn(params) { body }`
- `ExprKind.fnExpr` node
- Formatted with force-break for readability

**Pattern matching improvements:**
- `CaseArm.emptyLineBefore` — preserves blank lines between arms
- OR patterns: `pattern1 | pattern2 | pattern3`
- List patterns with spread: `[first, ..rest]`

---

## Architecture

### 2-Phase Codegen Pipeline

```
compile(alloc, modules, io, config)
  ↓
ComptimeSession
  ├─ arena: ArenaAllocator (shared parse/type arena)
  └─ outputs: []ComptimeOutput (per-module results)
  ↓
codegenEmit(alloc, outputs, config)
  ↓
[]ModuleOutput (js, erl, typedef, etc.)
```

**Convenience:** `generate(alloc, modules, io, config)` — runs both phases in sequence.

---

## Testing

```
✅ 542 tests passing
⚠️  156 pre-existing failures (formatter issues, unrelated to these changes)
```

**Test infrastructure:**
- Snapshot-based testing (`snapshots/` directory)
- Auto-creation of `.snap.md` on first run
- `.snap.md.new` on mismatch, deleted on fix

---

## Files Modified

| Category | Files Changed |
|----------|--------------|
| Parser | `src/parser.zig`, `src/parser/tests.zig` |
| Codegen | `src/codegen/commonJS.zig`, `src/codegen/erlang.zig`, `src/codegen/typescript.zig`, `src/codegen/snapshot.zig` |
| Comptime | `src/comptime.zig`, `src/comptime/tests.zig` |
| Format | `src/format/tests.zig` |
| Docs | `README.md`, `docs.md`, `src/AGENTS.md`, `CHANGELOG.md` |

---

## Migration Guide

### For Code Using Parser

```zig
// Before
var p = Parser.init(tokens, allocator);

// After
var p = Parser.init(tokens);
var program = try p.parse(allocator);
```

### For Code Using Lexer

```zig
// No change needed — Lexer never stored allocator
var l = Lexer.init(source);
const tokens = try l.scanAll(allocator);
defer l.deinit(allocator);
```

### For Code Using Codegen

```zig
// Before
const outputs = try codegen.generate(allocator, modules, io, config);

// After (parameter renamed, same behavior)
const outputs = try codegen.generate(alloc, modules, io, config);
```

---

## Principles Going Forward

1. **Allocator is a parameter, never a field** (except internal Emitters)
2. **Use `alloc` as parameter name** consistently
3. **Extract helpers for 3+ repetitive occurrences**
4. **Keep codegen backends consistent** (CommonJS ↔ Erlang patterns)
5. **Snapshot tests for all new features**
