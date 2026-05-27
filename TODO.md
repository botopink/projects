# TODO — Botopink Compiler

## Done

### @Result(D, E) migration
- [x] Remove `TypeRef.errorUnion` variant from AST (`ast.zig`)
- [x] Remove `E!T` parsing from `parseTypeRef` (`parser.zig`)
- [x] Remove `errorUnion` from type inference — `appendTypeRefStr` and `resolveTypeRefInContext` (`infer.zig`)
- [x] Remove `errorUnion` from formatter (`format.zig`)
- [x] Remove `errorUnion` from TypeScript codegen (`typescript.zig`)
- [x] Remove `errorUnion` from language server hover (`engine.zig`)
- [x] Add `@Result<R, E>` builtin declaration to `builtins.d.bp`
- [x] Add `TypeRef.generic` variant with `is_builtin` flag for `@Name<T1, T2>` type annotations (`ast.zig`)
- [x] Parse `@Name<T1, T2>` in `parseBaseTypeRef` (`parser.zig`)
- [x] Handle `generic` TypeRef in type inference — `appendTypeRefStr`, `resolveTypeRefInContext` (`infer.zig`)
- [x] Handle `generic` TypeRef in formatter (`format.zig`)
- [x] Handle `generic` TypeRef in TypeScript codegen — `@Result<D,E>` emits tagged union (`typescript.zig`)
- [x] Handle `generic` TypeRef in LSP hover (`engine.zig`)
- [x] Semantic awareness: `try expr` unwraps `@Result<D,E>` to `D` via `unwrapResultType` (`infer.zig`)
- [x] `catch` handler: lambda handlers use return type for unification (`infer.zig`)
- [x] Error message: `T!E` syntax rejected with hint to use `@Result<D, E>` (`parser.zig`, `print.zig`)
- [x] Tests: parser error test for rejected `E!T`, 3 comptime inference tests, 15 codegen tests (60 snapshots)

### typeinfo → typeparam migration
- [x] Remove `typeinfo` keyword/token from lexer
- [x] Remove `typeinfo` ParamModifier variant from AST
- [x] Remove `comptime: typeinfo T` parsing path from parser
- [x] Remove `typeinfoConstraints` field from Param
- [x] Replace builtins.d.bp `typeinfo` params with `comptime T: typeparam`
- [x] Formatter: `comptime` params output as `comptime name: type` (pre-name style)

### Runtime expansion
- [x] Add `wasm` variant to `Runtime` enum (`eval.zig`)
- [x] Create `comptime/runtime/wasm.zig` — WAT-based comptime eval via wasmtime
- [x] Add `beam` variant to `Runtime` enum (`eval.zig`)
- [x] Create `comptime/runtime/beam.zig` — BEAM comptime eval (delegates to erlang)
- [x] Update codegen configs: `beam` uses `.beam` comptimeRuntime, `wasm` uses `.wasm` comptimeRuntime

### @print test coverage
- [x] Add `@print` to ~20 existing codegen tests (operators, destructuring, pipeline, loop, if, try/catch, lambda, negation, assign)
- [x] Add `@print` to ~10 existing comptime tests (literals, binary ops, records, case, pub fn)
- [x] Add 5 new `@print` dedicated tests in `comptime/tests.zig`
- [x] Add 4 new `@print` dedicated tests in `codegen/tests.zig`
- [x] Regenerate all snapshots (4 runtimes × 4 targets)

---

## Pending — Syntax

### Use syntax: `from "mod"` → `= @root()` / `= @module()`

Migrar de:
```
use { X } from "mod"
use { X } from loader()
```
Para:
```
use { X } = @root()
use { X.x1.x2.X3 } = @module()
```

#### Fase 1: AST
- [ ] `Source` union: remover `stringPath` e `functionCall`, adicionar `builtinCall: []const u8` para `@root`, `@module` etc. (`ast.zig`)
- [ ] `UseDecl.imports`: mudar de `[]const []const u8` para suportar dotted paths (ex: `X.x1.x2.X3`) — usar struct `ImportPath { segments: []const []const u8 }` ou `[]const []const []const u8`
- [ ] Atualizar `DeclKind.deinit` para desalocar novos campos

#### Fase 2: Lexer
- [ ] Verificar que `@` seguido de identifier já é parseado (provavelmente via `@identifier` como builtin)
- [ ] Remover keyword `from` do lexer (`token.zig`) — ou manter como reserved/deprecated
- [ ] Garantir que `=` após `}` no contexto de `use` é reconhecido corretamente

#### Fase 3: Parser
- [ ] `parseUseDecl`: trocar consumo de `from` por consumo de `=` (`parser.zig`)
- [ ] `parseSource`: parsear `@name()` como `Source.builtinCall` — consumir `@`, identifier, `(`, `)` (`parser.zig`)
- [ ] `parseImportList`: suportar dotted paths — parsear `X.x1.x2.X3` como lista de segmentos separados por `.` (`parser.zig`)
- [ ] Error message: rejeitar sintaxe antiga `use { X } from "mod"` com hint para usar `= @root()`

#### Fase 4: Formatter & Printer
- [ ] `fmtUse`: emitir `use { X.x1.x2 } = @root()` em vez de `use { X } from "mod"` (`format.zig`)
- [ ] `print.zig`: atualizar printer para nova sintaxe se aplicável

#### Fase 5: Type inference / Comptime
- [ ] `resolveImports`: resolver `@root()` como caminho para o módulo raiz do projeto (`comptime.zig` / `infer.zig`)
- [ ] `resolveImports`: resolver `@module()` como caminho para o módulo atual/local
- [ ] Resolver dotted paths: `X.x1.x2.X3` navega submodules/exports aninhados
- [ ] Definir semântica exata de `@root()` vs `@module()` (e outros builtins futuros como `@pkg()`)

#### Fase 6: Codegen
- [ ] CommonJS: `use { X } = @root()` → `const { X } = require("./root-path");` — mapear `@root()` para path relativo (`commonJS.zig`)
- [ ] CommonJS: dotted path `X.x1.x2.X3` → destructuring aninhado ou qualified access
- [ ] Erlang: `use { X } = @root()` → `-import(root_module, [X/0]).` (`erlang.zig`)
- [ ] TypeScript: `use { X } = @root()` → `import { X } from "./root-path";` (`typescript.zig`)
- [ ] BEAM ASM: atualizar se necessário (`beam_asm.zig`)
- [ ] WAT: atualizar se necessário (`wat.zig`)

#### Fase 7: Language Server
- [ ] LSP folding: atualizar detecção de blocos `use` consecutivos (`engine.zig`)
- [ ] LSP unused imports: atualizar scan para nova sintaxe (`engine.zig`)
- [ ] LSP go-to-definition: resolver `@root()` / `@module()` para arquivo/módulo correto

#### Fase 8: Tests & Snapshots
- [ ] Parser tests: atualizar todos os testes `use` existentes para nova sintaxe (`parser/tests.zig`)
- [ ] Parser tests: adicionar testes para dotted paths (`X.x1.x2.X3`)
- [ ] Parser tests: adicionar teste de erro para sintaxe antiga `from`
- [ ] Format tests: atualizar para nova sintaxe (`format/tests.zig`)
- [ ] Codegen tests: atualizar snapshots de import para todos os backends
- [ ] Comptime tests: verificar resolução de `@root()` e `@module()`
- [ ] Regenerar todos os snapshots afetados

##### Cenários de teste

**Parser (`parser/tests.zig`)**
```
use ---- single import from @root()
use ---- multiple imports from @root()
use ---- single dotted path X.x1.x2
use ---- deeply nested dotted path X.a.b.c.D
use ---- mixed simple and dotted imports
use ---- @module() source
use ---- trailing comma in import list with @root()
use ---- empty imports from @root() (error)
use ---- rejected old syntax from "mod" (error with hint)
use ---- missing = after } (error)
use ---- @root without parens (error)
use ---- unknown builtin @pkg() (future-proof parse)
```

**Comptime / Inference (`comptime/tests.zig`)**
```
import single val from @root() dependency
import multiple vals from @root() dependency
import fn from @module() dependency
three-level chain ---- a imports b via @root(), b imports c via @module()
dotted path ---- X.sub.Value resolves nested export
dotted path ---- unresolved segment (error)
@root() vs @module() ---- correct module resolution
```

**Codegen (`codegen/tests.zig`)**
```
use ---- single import @root() (CommonJS: require, Erlang: -import, TS: import)
use ---- dotted path X.a.B (CommonJS: nested destructure, Erlang: qualified, TS: import)
use ---- multi-module pub fn import with @root()
use ---- multi-module pub val import with @module()
```

**Format (`format/tests.zig`)**
```
use ---- formats @root() with spaces around =
use ---- formats dotted path with dots preserved
use ---- multiple use declarations alignment
```

#### Fase 9: Docs & Stdlib
- [ ] Atualizar `docs.md` com nova sintaxe de imports
- [ ] Atualizar `examples.md` com exemplos usando `@root()` / `@module()`
- [ ] Atualizar `builtins.d.bp` se tiver declarações `use`
- [ ] Atualizar AGENTS.md com mudança de sintaxe

---

### Result: `@Result(D, E)` → `@Result<D, E>` ✓

- [x] Refactor `TypeRef.builtin` to `TypeRef.generic` with `is_builtin` flag (`ast.zig`)
- [x] Parse `@Name<T1, T2>` as builtin generic and `Name<T1, T2>` as user generic (`parser.zig`)
- [x] Emit `removedBuiltinType` error for old `@Name(...)` parenthesis syntax (`parser.zig`)
- [x] Remove `@Result` from `inferBuiltinCallReturnType` (`infer.zig`)
- [x] Update `appendTypeRefStr` and `resolveTypeRefInContext` for `.generic` with `is_builtin` (`infer.zig`)
- [x] Update formatter — `@Name<args>` for builtins, `Name<args>` for user generics (`format.zig`)
- [x] Update TypeScript codegen for `.generic` (`typescript.zig`)
- [x] Update LSP hover — `@Name<args>` for builtins (`engine.zig`)
- [x] Define `Result<R, E>` as generic enum in `builtins.d.bp`
- [x] Update error messages: `removedBuiltinType` + updated `removedErrorUnion` hint (`print.zig`)
- [x] Update all tests: `@Result(D, E)` → `@Result<D, E>` in comptime + codegen tests
- [x] Regenerate all snapshots (4 runtimes × 4 targets)

---

## Pending — Type System

### Typeparam constraints
- [ ] Constraint syntax: `comptime f: typeparam string | int` — type constraints on typeparam
- [ ] Parser: parse `|`-separated type list after `typeparam` in param type position
- [ ] Inference: validate comptime argument satisfies declared constraints
- [ ] Error message: clear diagnostic when constraint is violated

#### Cenários de teste
```
parser ---- typeparam with single constraint
parser ---- typeparam with multiple pipe-separated constraints
parser ---- typeparam without constraint (backwards compat)
inference ---- comptime arg satisfies single constraint (pass)
inference ---- comptime arg satisfies one of multiple constraints (pass)
inference ---- comptime arg violates constraint (error)
inference ---- comptime arg with no constraint accepts any type (pass)
codegen ---- constrained typeparam specializes correctly
error ---- clear message shows expected vs actual type in constraint violation
```

### Throw type checking
- [ ] Semantic awareness of `throw`: verify thrown value matches the `E` type of enclosing `@Result<D, E>` return
- [ ] Error message: mismatch between thrown type and declared `E` in `@Result<D, E>`

#### Cenários de teste
```
throw ---- string matches declared E = string (pass)
throw ---- record matches declared E = ErrorRecord (pass)
throw ---- type mismatch i32 thrown but E = string (error)
throw ---- throw inside nested fn does not check outer fn's E
throw ---- throw inside catch handler checks enclosing fn's E
throw ---- multiple throw sites all must match E
throw ---- throw without enclosing Result return type (error)
```

---

## Pending — Codegen

### try/catch lowering
- [ ] Codegen: `try`/`catch` should lower to pattern matching on `Ok`/`Error` variants (not JS try/catch)
- [ ] CommonJS: `try expr catch fallback` → `const _r = expr(); if (_r.tag === "Error") { ... } else { _r.data }`
- [ ] Erlang: `try`/`catch` → `case Expr of {ok, V} -> V; {error, E} -> Fallback end`
- [ ] BEAM ASM: same pattern via `{test, is_tagged_tuple, ...}` or case dispatch
- [ ] WAT: `try`/`catch` → `if` on Ok/Error i32 tag in linear memory

#### Cenários de teste
```
try ---- simple try unwraps Ok to value (CommonJS)
try ---- simple try unwraps Ok to value (Erlang)
try ---- simple try unwraps Ok to value (BEAM ASM)
try ---- simple try unwraps Ok to value (WAT)
try ---- catch with literal fallback on Error (CommonJS)
try ---- catch with literal fallback on Error (Erlang)
try ---- catch with lambda handler receives error value (CommonJS)
try ---- catch with lambda handler receives error value (Erlang)
try ---- nested try catch both lowered to pattern match
try ---- try without catch propagates Error variant up
try ---- catch tail on method call chain
try ---- multiple try in same fn body independent temps
try ---- try on non-Result type (comptime error)
```

### BEAM ASM — remaining fases
- [ ] **Fase 3**: strings/binaries — `{put_string, ...}`, binary syntax, `@print` via `io:format`
- [ ] **Fase 4**: records/structs — map creation `{put_map_assoc, ...}`, field access
- [ ] **Fase 5**: enums — tagged tuple `{tag, Fields...}`, case dispatch on tag
- [ ] **Fase 6**: closures/lambdas — `{make_fun3, ...}`, higher-order calls
- [ ] **Fase 7**: ranges — `lists:seq/2` or loop counter lowering
- [ ] **Fase 8**: try/catch — `{try, ...}` / `{try_end, ...}` / `{try_case, ...}` instructions
- [ ] **Fase 9**: polish — proper register allocation, tail-call optimization, dead code elimination

#### Cenários de teste
```
beam ---- string literal emits put_string instruction
beam ---- string concat emits binary append
beam ---- @print string calls io:format
beam ---- record creation emits put_map_assoc
beam ---- record field access emits get_map_element
beam ---- record update emits update_map_assoc
beam ---- enum unit variant emits tagged atom tuple
beam ---- enum payload variant emits tagged tuple with fields
beam ---- case on enum dispatches on first tuple element
beam ---- lambda emits make_fun3
beam ---- lambda as argument emits apply instruction
beam ---- higher-order call on captured fn
beam ---- range 0..n emits lists:seq call
beam ---- range in loop emits counter-based iteration
beam ---- try/catch emits try/try_end/try_case block
beam ---- tail call optimization emits call_last
beam ---- dead code after return is eliminated
```

### WAT — remaining features
- [ ] Destructure patterns (record, tuple) in WAT
- [ ] Pipeline operator lowering in WAT
- [ ] String operations (concat, compare) via linear memory
- [ ] Enum/record representation in linear memory (tagged structs)
- [ ] try/catch → tag-based if/else in WASM

#### Cenários de teste
```
wat ---- record destructure emits correct memory loads
wat ---- tuple destructure emits indexed memory loads
wat ---- pipeline a |> b |> c lowers to nested calls
wat ---- string concat allocates and copies in linear memory
wat ---- string equality compares bytes in linear memory
wat ---- enum unit variant stores i32 tag at offset 0
wat ---- enum payload variant stores tag + fields contiguously
wat ---- record stores fields at known offsets
wat ---- try/catch emits if/else on tag i32
```

### Erlang codegen gaps
- [ ] List patterns in case arms (currently placeholder)
- [ ] Constructor patterns in case arms (currently placeholder)
- [ ] Proper arity tracking for qualified function calls

#### Cenários de teste
```
erlang ---- case with empty list pattern [] matches empty list
erlang ---- case with [H | T] pattern destructures head and tail
erlang ---- case with [A, B, ..Rest] multi-element pattern
erlang ---- case with constructor pattern Variant(field: x) matches tuple
erlang ---- case with nested constructor in list
erlang ---- qualified call Module.fn(a, b) emits correct arity /2
erlang ---- qualified call with zero args emits /0
erlang ---- imported fn call tracks declared arity
```

---

## Pending — Async, Generator & Iterator

### Sintaxe decidida

`*fn` obrigatório para retornos especiais. Sempre com body. `fn` normal retornando esses tipos = erro.

```bp
// async
*fn fetch(url: string) -> Future<Response, Error> {
    val resp = await http.get(url)
    val data = try await parseJson(resp)
    return data
}

// generator
*fn fibonacci() -> Iterator<i32> {
    yield 0
    yield 1
}

// async generator
*fn stream(url: string) -> AsyncIterator<string, Error> {
    loop {
        yield await readLine(url)
    }
}

// yield com label (só quando ambíguo)
*fn chunks(items: i32[]) -> Iterator<i32[]> :gen {
    var batch = loop (items) :acc { item ->
        if needFlush() {
            yield :gen batch    // suspende generator
        }
        yield :acc item         // acumula no loop
    }
}

// loop await para async iterators
loop await (stream) { line ->
    @print(line)
}
```

### Fase 1: Lexer + AST

**Arquivos**: `lexer/token.zig`, `lexer.zig`, `ast.zig`

- [ ] Lexer: adicionar token `await` ao `TokenKind` enum
- [ ] Lexer: adicionar reconhecimento `"await"` no `identifierType`
- [ ] AST: adicionar `Expr.await` variant (prefix unary, como `try`)
- [ ] AST: adicionar campo `isStarFn: bool` ao `FnDecl` / fn expressions
- [ ] AST: adicionar campo `awaitLoop: bool` ao `LoopExpr` (para `loop await`)
- [ ] AST: adicionar campo `label: ?[]const u8` ao `JumpExpr.yield`
- [ ] AST: adicionar campo `label: ?[]const u8` ao `LoopExpr`
- [ ] AST: adicionar campo `label: ?[]const u8` ao `FnDecl`

### Fase 2: Parser

**Arquivo**: `parser.zig`

- [ ] Parser: parsear `*fn` — detectar `*` antes de `fn` como declaração de função especial
- [ ] Parser: parsear `await expr` como expressão prefix (similar a `try expr`)
- [ ] Parser: parsear `loop await (iter) { ... }` — detectar `await` token após `loop`
- [ ] Parser: parsear labels `:name` após keyword `loop` ou após return type de `*fn`
- [ ] Parser: parsear `yield :label expr` — label opcional no yield
- [ ] Parser: erro se `*fn` sem body

### Fase 3: Type Inference

**Arquivo**: `comptime/infer.zig`

- [ ] Validar `*fn`: retorno deve ser `Future<T,E>`, `Iterator<T>`, `Generator<T,R>`, ou `AsyncIterator<T,E>`
- [ ] Erro se `fn` normal retorna `Future`/`Iterator`/`Generator`/`AsyncIterator`
- [ ] Erro se `*fn` retorna tipo que não é especial
- [ ] `await expr`: verificar que `expr` tem tipo `Future<T, E>`, resultado = `Result<T, E>`
- [ ] Erro se `await` fora de `*fn` com retorno `Future` ou `AsyncIterator`
- [ ] `yield expr` em `*fn` generator: unificar tipo de `expr` com `T` de `Iterator<T>` / `Generator<T,R>`
- [ ] `yield` sem `*fn`: mantém comportamento atual (accumulate em loop)
- [ ] Labels: verificar que label referenciado existe, erro se label inexistente
- [ ] `loop await`: verificar que iter é `AsyncIterable<T, E>` ou `AsyncIterator<T, E>`, inferir param como `T`
- [ ] `try await expr`: unwrap Future e Result (`Future<T,E>` → `Result<T,E>` → `T`)

### Fase 4: Codegen

#### CommonJS (`codegen/commonJS.zig`)
- [ ] `*fn` com `Future` → `async function`
- [ ] `*fn` com `Iterator`/`Generator` → `function*` com `yield`
- [ ] `*fn` com `AsyncIterator` → `async function*`
- [ ] `await expr` → `await expr`
- [ ] `yield expr` (suspend) → `yield expr`
- [ ] `loop await` → `for await (const item of iter) { ... }`

#### Erlang (`codegen/erlang.zig`)
- [ ] `*fn` com `Future` → spawn + receive pattern
- [ ] `*fn` com `Iterator`/`Generator` → processo com send/receive ou closure com estado
- [ ] `await` → `receive` / `gen_server:call`
- [ ] `loop await` → receive loop recursivo

#### BEAM ASM (`codegen/beam_asm.zig`)
- [ ] `*fn` async → spawn/receive OTP pattern
- [ ] `*fn` generator → spawn + message passing
- [ ] `loop await` → receive + pattern match

#### WAT (`codegen/wat.zig`)
- [ ] `*fn` async → state machine com linear memory, continuation-based
- [ ] `*fn` generator → state machine com linear memory
- [ ] `loop await` → callback chain em linear memory

#### TypeScript (`codegen/typescript.zig`)
- [ ] `Future<T, E>` → `Promise<Result<T, E>>`
- [ ] `Iterator<T>` → `IterableIterator<T>`
- [ ] `Generator<T, R>` → `Generator<T, R, unknown>`
- [ ] `AsyncIterator<T, E>` → `AsyncIterableIterator<T>`
- [ ] `*fn` → emitir com modifier correspondente no `.d.ts`

### Fase 5: Formatter + LSP

**Arquivos**: `format.zig`, `engine.zig`

- [ ] Formatter: emitir `*fn`, `await expr`, `loop await`, `yield :label`
- [ ] LSP hover: mostrar tipo unwrapped de `await`/`yield`, indicar `*fn`
- [ ] LSP autocomplete: sugerir `next()`, `iter()`, `map()`, `flatMap()` nos tipos correspondentes

### Fase 6: Testes

- [ ] Parser: testes para `*fn`, `await expr`, `loop await`, `yield :label`
- [ ] Inference: `*fn` com retorno correto (pass), `fn` retornando Future (erro), `*fn` sem body (erro)
- [ ] Inference: `await` fora de `*fn` (erro), `yield :label` com label inexistente (erro)
- [ ] Codegen: snapshots para cada target (CommonJS, Erlang, BEAM, WAT, TS)
- [ ] Inference: `try await` unwrap duplo (Future → Result → T)

#### Cenários de teste

**Parser (`parser/tests.zig`)**
```
*fn ---- async function declaration with Future return
*fn ---- generator function with Iterator return
*fn ---- async generator with AsyncIterator return
*fn ---- with label :gen after return type
*fn ---- without body (error)
await ---- prefix expression inside *fn
await ---- chained await on method call
loop await ---- iteration over async iterator
yield ---- with label :gen targets generator
yield ---- with label :acc targets loop accumulator
yield ---- without label in generator context
```

**Inference (`comptime/tests.zig`)**
```
*fn ---- Future<Response, Error> return is valid
*fn ---- Iterator<i32> return is valid
*fn ---- string return type on *fn (error: must be special type)
fn ---- normal fn returning Future<T,E> (error: must use *fn)
fn ---- normal fn returning Iterator<T> (error: must use *fn)
await ---- inside *fn Future unwraps to Result<T, E>
await ---- outside *fn (error: await requires async context)
await ---- on non-Future type (error)
yield ---- in *fn Iterator<i32> unifies expr with i32
yield ---- in *fn Generator<string, i32> unifies correctly
yield :label ---- references existing loop label (pass)
yield :label ---- references nonexistent label (error)
loop await ---- infers param type T from AsyncIterator<T, E>
loop await ---- on non-async-iterable (error)
try await ---- Future<T,E> → Result<T,E> → T double unwrap
try await ---- propagates Error from Future
```

**Codegen (`codegen/tests.zig`)**
```
*fn async ---- simple fetch (CommonJS: async function, Erlang: spawn+receive)
*fn generator ---- fibonacci yields (CommonJS: function*, Erlang: process)
*fn async generator ---- stream (CommonJS: async function*, Erlang: spawn+receive loop)
await ---- inside async fn (CommonJS: await, Erlang: receive)
yield ---- suspend generator (CommonJS: yield, Erlang: send)
loop await ---- iterate stream (CommonJS: for await, Erlang: receive loop)
yield :label ---- disambiguated yield targets correct scope
try await ---- unwrap async result in one expression
```

---

## Pending — Stdlib

- [ ] `@Result.map(fn(D) -> D2)` — transform Ok value
- [ ] `@Result.flatMap(fn(D) -> @Result<D2, E>)` — chain fallible operations
- [ ] `Result.unwrapOr(default: D)` — extract Ok or use default
- [ ] `Result.isOk()` / `Result.isError()` — boolean predicates
- [ ] `Option.map` / `Option.flatMap` / `Option.unwrapOr` — mirror Result API

#### Cenários de teste
```
Result.map ---- transforms Ok value with fn
Result.map ---- preserves Error unchanged
Result.flatMap ---- chains Ok into another Result
Result.flatMap ---- short-circuits on Error
Result.unwrapOr ---- returns Ok value when present
Result.unwrapOr ---- returns default on Error
Result.isOk ---- true for Ok variant
Result.isOk ---- false for Error variant
Result.isError ---- true for Error variant
Result.isError ---- false for Ok variant
Option.map ---- transforms Some value with fn
Option.map ---- preserves None unchanged
Option.flatMap ---- chains Some into another Option
Option.flatMap ---- short-circuits on None
Option.unwrapOr ---- returns Some value when present
Option.unwrapOr ---- returns default on None
```

---

## Pending — Language Features

### Lambda syntax
- [ ] Lambda with full type annotations: `val func: fn(String, Int) -> String = { s, i -> ... }`
- [ ] Infer lambda param types from context when annotation is present

#### Cenários de teste
```
lambda ---- full type annotation fn(String, Int) -> String parses
lambda ---- params inferred from val type annotation
lambda ---- type mismatch between annotation and body return (error)
lambda ---- annotation with generic fn(T) -> T infers from usage
lambda ---- multi-param annotation matches lambda arity
lambda ---- annotation arity mismatch (error)
```

### Pattern matching
- [ ] Exhaustiveness checking for case expressions
- [ ] Nested pattern matching (pattern inside pattern)
- [ ] Guard clauses in case arms: `case x { n if n > 0 -> ... }`

#### Cenários de teste
```
exhaustiveness ---- all enum variants covered (pass)
exhaustiveness ---- missing enum variant (error with hint)
exhaustiveness ---- wildcard covers remaining (pass)
exhaustiveness ---- bool true/false both covered (pass)
exhaustiveness ---- bool only true covered (error)
exhaustiveness ---- nested enum in record field
nested pattern ---- record inside enum variant
nested pattern ---- list inside tuple
nested pattern ---- enum inside list head
guard ---- simple comparison n > 0
guard ---- guard with logical and (n > 0 && n < 100)
guard ---- guard references bound variable from pattern
guard ---- guard with function call (isValid(x))
guard ---- overlapping guards last wins
guard ---- guard does not affect exhaustiveness
```

---

## Pending — Tooling

### Language Server
- [ ] Go-to-definition for imported symbols (`use { X } from "mod"`)
- [ ] Auto-complete for record/struct fields
- [ ] Auto-complete for enum variants
- [ ] Diagnostic squiggles for type errors in editor

#### Cenários de teste
```
lsp goto ---- jumps to fn definition in imported module
lsp goto ---- jumps to record definition in imported module
lsp goto ---- jumps to enum variant definition
lsp goto ---- unresolved import shows error (no crash)
lsp complete ---- record field names after dot
lsp complete ---- struct method names after dot
lsp complete ---- enum variant names after Type.
lsp complete ---- fn params in scope inside body
lsp diagnostic ---- type mismatch shows squiggle on expr
lsp diagnostic ---- unbound variable shows squiggle on identifier
lsp diagnostic ---- arity mismatch shows squiggle on call
```

### Formatter
- [ ] Format `@Result<D, E>` return type annotations consistently
- [ ] Format `comptime` param modifiers consistently with type constraints

#### Cenários de teste
```
format ---- @Result<D, E> with spaces after commas
format ---- nested generics @Result<Option<T>, E>
format ---- comptime param with typeparam constraint aligned
format ---- comptime param without constraint preserves spacing
format ---- long generic type wraps consistently
```
