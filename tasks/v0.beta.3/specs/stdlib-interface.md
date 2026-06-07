# stdlib interface redesign — funções soltas → métodos de interface

**Slug**: `stdlib-interface`
**Depends on**: `generic-inference` (methods genéricos precisam de type vars frescos por call site)
**Files**: `libs/std/src/*.d.bp`, `libs/std/src/*.bp`; `modules/compiler-core/src/comptime/infer.zig` (method dispatch em tipos primitivos e enums)
**Touches docs**: `libs/std/AGENTS.md`; `libs/std/src/docs.md`; `libs/std/src/examples.md`
**Status**: pending

## Problema

Os módulos stdlib atuais (`bool.bp`, `list.bp`, `order.bp`, `pair.bp`, etc.) são
**namespaces com funções soltas** — chamadas como `list.map(xs, f)` ou
`bool.negate(x)`. Isso diverge da abordagem de como `Array<T>` já funciona
(método: `xs.map(f)`).

A consistência com a forma nativa é melhor: `xs.fold(0, f)` em vez de
`list.fold(xs, 0, f)`, `o.reverse()` em vez de `order.reverse(o)`.

Além disso, `io.d.bp` é um arquivo de declaração isolado desnecessariamente —
pode ser uma seção em `builtins.d.bp` como os outros primitivos.

## Arquitetura alvo

Cada módulo vira uma **extensão de interface** no arquivo de declaração do tipo:

| Módulo atual | Passa a ser | Interface alvo |
|---|---|---|
| `bool.bp` | seção em `primitives.d.bp` | `interface Bool { … }` |
| `int.bp` | seção em `primitives.d.bp` | `interface I32 { … }` |
| `float.bp` | seção em `primitives.d.bp` | `interface F64 { … }` |
| `string.bp` | fusão em `string.d.bp` | `interface String { … }` |
| `list.bp` | fusão em `array.d.bp` | `interface Array<T> { … }` (métodos adicionais) |
| `order.bp` | novo `order.d.bp` | `interface OrderOps` + enum `Order` |
| `pair.bp` | novo `pair.d.bp` | `interface Pair<A, B>` em `#(A, B)` |
| `iterator.bp` | fusão em `builtins.d.bp` | `interface Iterator<T>` (operações eager) |
| `dict.bp` | fica `.bp` com métodos | `pub record Dict<K,V>` com métodos |
| `sets.bp` | fica `.bp` com métodos | `pub record Set<T>` com métodos |
| `queue.bp` | fica `.bp` com métodos | `pub record Queue<T>` com métodos |
| `string_builder.bp` | fica `.bp` com métodos | `pub record StringBuilder` com métodos |
| `function.bp` | eliminado ou virar utils | funções estáticas úteis (sem receiver natural) |
| `io.d.bp` | fusão em `builtins.d.bp` | seção `// ── I/O ──` |

## Sintaxe alvo

### bool — métodos no tipo primitivo `bool`

```bp
// primitives.d.bp
interface Bool {
    fn negate(self: bool) -> bool
    fn nor(self: bool, other: bool) -> bool
    fn nand(self: bool, other: bool) -> bool
    fn exclusiveOr(self: bool, other: bool) -> bool
    fn exclusiveNor(self: bool, other: bool) -> bool
}
```

```bp
// chamada (sem import)
val x = true.negate();
val y = false.nor(false);
```

### int — métodos em `i32`

```bp
interface I32 {
    fn absoluteValue(self: i32) -> i32
    fn min(self: i32, other: i32) -> i32
    fn max(self: i32, other: i32) -> i32
    fn clamp(self: i32, lo: i32, hi: i32) -> i32
    fn isEven(self: i32) -> bool
    fn isOdd(self: i32) -> bool
    fn toString(self: i32) -> string
}
```

```bp
val n = (-5).absoluteValue();   // 5
val e = 4.isEven();             // true
```

### order — métodos no enum `Order`

```bp
// order.d.bp (novo arquivo declaração)
pub enum Order { Lt, Eq, Gt }

interface OrderOps {
    fn toInt(self: Order) -> i32
    fn reverse(self: Order) -> Order
}
```

```bp
// sem import
val o = Order.Lt;
val n = o.toInt();      // -1
val r = o.reverse();    // Order.Gt
```

### pair — métodos em `#(A, B)`

```bp
// pair.d.bp (novo arquivo declaração)
interface Pair<A, B> {
    fn first(self: #(A, B)) -> A
    fn second(self: #(A, B)) -> B
    fn swap(self: #(A, B)) -> #(B, A)
    fn mapFirst<C>(self: #(A, B), f: fn(A) -> C) -> #(C, B)
    fn mapSecond<C>(self: #(A, B), f: fn(B) -> C) -> #(A, C)
}
```

```bp
val p = #("hello", 42);
val s = p.swap();       // #(42, "hello")
val n = p.second();     // 42
```

### list — fusão em `Array<T>`

```bp
// array.d.bp — seção adicional (list ops)
interface Array<T> {
    // … ops existentes …

    fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A
    fn flatMap<U>(self: Self, f: fn(item: T) -> Array<U>) -> Array<U>
    fn flatten(self: Self) -> Array<T>        // onde T = Array<U>
    fn append(self: Self, other: Array<T>) -> Array<T>
    fn prepend(self: Self, item: T) -> Array<T>
    fn take(self: Self, n: i32) -> Array<T>
    fn drop(self: Self, n: i32) -> Array<T>
    fn first(self: Self) -> ?T
    fn rest(self: Self) -> Array<T>
    fn find(self: Self, pred: fn(T) -> bool) -> ?T
    fn all(self: Self, pred: fn(T) -> bool) -> bool
    fn any(self: Self, pred: fn(T) -> bool) -> bool
    fn count(self: Self, pred: fn(T) -> bool) -> i32
    fn isEmpty(self: Self) -> bool
    fn range(start: i32, stop: i32) -> Array<i32>   // static fn
}
```

### iterator — operações eager na interface `Iterator<T>`

```bp
// builtins.d.bp — interface Iterator<T> estendida
pub interface Iterator<T> {
    fn next(self: Self) -> ?T

    // operações eager (retornam Array)
    fn toList(self: Self) -> Array<T>
    fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A
    fn map<U>(self: Self, f: fn(item: T) -> U) -> Array<U>
    fn filter(self: Self, pred: fn(item: T) -> bool) -> Array<T>
    fn take(self: Self, n: i32) -> Array<T>
}
```

### io — fusão em `builtins.d.bp`

```bp
// builtins.d.bp — nova seção (substituindo io.d.bp)

// ── I/O ────────────────────────────────────────────────────────────────────────

#[@external(node, "console", "log"),
  @external(erlang, "io", "format")]
pub declare fn print(message: string);

#[@external(node, "console", "log"),
  @external(erlang, "io", "format")]
pub declare fn println(message: string);

#[@external(node, "console", "debug"),
  @external(erlang, "io", "format")]
pub declare fn debug(value: string);
```

## Steps

### F0 — Fundir `io.d.bp` em `builtins.d.bp` (menor impacto, sem deps)

- [ ] Mover as 3 declarações de `io.d.bp` para uma seção `// ── I/O ──` em `builtins.d.bp`
- [ ] Deletar `io.d.bp`
- [ ] Remover `io_mod` de `prelude.zig` e de `std_pkg_modules` em `comptime.zig`
- [ ] Remover `io.d.bp` de `std_bp_files` em `build.zig`
- [ ] Manter `import {io} from "std"` funcionando: `print`/`println`/`debug` são
      builtins agora — sem módulo qualificado, acessados diretamente ou via `io.print`
      via o namespace builtin
- [ ] Atualizar `libs/std/AGENTS.md`

### F1 — Métodos em `bool` (primitives.d.bp)

- [ ] Adicionar `interface Bool { … }` em `primitives.d.bp` com os 5 métodos
- [ ] Remover (ou manter como alias) `bool.bp` — se mantido, vira `.d.bp` vazio
- [ ] Ajustar `registerStdlib` / `prelude.zig`: remover embedding de `bool.bp` se eliminado
- [ ] Confirmar method dispatch: `true.negate()` → inferência via `primitives.d.bp`
- [ ] Migrar inline tests para a nova forma de chamada

### F2 — Métodos em `i32` e `f64` (primitives.d.bp)

- [ ] `interface I32 { absoluteValue, min, max, clamp, isEven, isOdd, toString }`
- [ ] `interface F64 { absoluteValue, min, max, clamp, toString; + floor/ceiling/round/squareRoot via #[@external] }`
- [ ] Remover `int.bp` e `float.bp` (ou manter como shims transitórios)
- [ ] Migrar testes inline para method syntax

### F3 — `Order` enum com métodos (`order.d.bp` novo)

- [ ] Criar `libs/std/src/order.d.bp` com `pub enum Order { Lt, Eq, Gt }` e `interface OrderOps`
- [ ] Remover `order.bp` (funções migradas para interface)
- [ ] Atualizar prelude.zig + comptime.zig + build.zig
- [ ] Migrar `order_test.bp` para method syntax

### F4 — `Pair<A, B>` interface em `#(A, B)` (`pair.d.bp` novo)

- [ ] Criar `libs/std/src/pair.d.bp` com `interface Pair<A, B>` sobre o tipo `#(A, B)`
- [ ] Remover `pair.bp`
- [ ] Confirmar que `inferMethodCallExpr` resolve métodos em tuples `#(A, B)`
- [ ] Migrar `pair_test.bp` para method syntax

### F5 — List ops em `Array<T>` (array.d.bp estendido)

- [ ] Adicionar `fold`, `flatMap`, `flatten`, `append`, `prepend`, `take`, `drop`,
      `first`, `rest`, `find`, `all`, `any`, `count`, `isEmpty`, `range` ao `interface Array<T>`
- [ ] Remover `list.bp`
- [ ] Confirmar que os generics de `fold<A>` etc. funcionam via `generic-inference`
- [ ] Migrar `list_test.bp` para method syntax (`xs.fold(0, f)`, `xs.take(3)`, etc.)

### F6 — `String` interface estendida (string.d.bp)

- [ ] Mover as implementações de `string.bp` para `string.d.bp` como declarações
- [ ] Confirmar snake_case → camelCase mapping (ou normalizar na definição)
- [ ] Remover `string.bp`
- [ ] Migrar `string_test.bp` e inline tests

### F7 — `Iterator<T>` com operações eager (builtins.d.bp)

- [ ] Adicionar `toList`, `fold`, `map`, `filter`, `take` à `interface Iterator<T>`
- [ ] Remover `iterator.bp` (ou manter `range`, `repeat` como funções geradoras)
- [ ] Migrar `iterator_test.bp`

### F8 — Records com métodos: `Dict<K,V>`, `Set<T>`, `Queue<T>`, `StringBuilder`

- [ ] Converter sintaxe de chamada para method dispatch: `d.insert("k", v)` em vez de
      `dict.insert(d, "k", v)` — provavelmente o compilador já suporta se o record tem
      os métodos declarados
- [ ] Atualizar test files correspondentes

### F9 — Remover módulos eliminados e atualizar prelude

- [ ] Remover arquivos `.bp` que viraram `.d.bp` ou foram eliminados da `prelude.zig`
- [ ] Remover entradas de `std_pkg_modules` em `comptime.zig`
- [ ] Remover de `std_bp_files` em `build.zig`
- [ ] Atualizar `libs/std/AGENTS.md` (tree + tabelas)

## Test scenarios

```
comptime ---- bool methods: true.negate() resolves via primitives.d.bp
comptime ---- int methods: 5.clamp(0, 3) resolves
comptime ---- order enum method: Order.Lt.toInt() == -1
comptime ---- pair methods: #(1, "a").swap() == #("a", 1)
comptime ---- array list ops: [1,2,3].fold(0, { acc, x -> acc + x }) == 6
comptime ---- iterator methods: range(0, 5).toList().length == 5
codegen/node ---- bool method dispatch lowers correctly
codegen/node ---- int method toString: 42.toString() == "42"
```

## Notes

- A implementação de **method dispatch em tipos primitivos** (`bool`, `i32`, `f64`)
  precisa de suporte no `inferMethodCallExpr` para lookup de interface pelo tipo
  do receiver. Verificar se já funciona para `Array<T>` e reusar o mesmo mecanismo.
- `function.bp` não tem receiver natural — `identity`, `constant` são funções
  estáticas. Pode ficar como namespace de utilitários (não vira interface).
  `compose` e `flip` poderiam ser métodos em tipos função (`fn(A)->B`), mas isso
  é mais complexo.
- O `range(start, stop)` é uma função estática (não tem receiver) — pode virar
  função builtin em `builtins.d.bp` ou método estático de `Array<i32>`.
- F5 (list ops em Array) depende de `generic-inference` para que `fold<A>` funcione
  corretamente com type vars frescos por call site.
- Os records (`Dict`, `Set`, `Queue`, `StringBuilder`) já suportam method dispatch
  via record fields se o compilador os trata como self — confirmar antes de F8.
