# stdlib-gleam — a Gleam-style standard library for `libs/std`

**Slug**: stdlib-gleam
**Depends on**: nothing
**Files**: libs/std/src/*.bp, libs/std/src/*.d.bp (`.bp`-only — no Zig here); **loader relocated** libs/std/src/prelude.zig → modules/compiler-core/src/comptime/stdlib/prelude.zig + build.zig; **F1 (`@external`) also touches the compiler**: modules/compiler-core/src/{lexer,parser,ast,comptime,codegen}/* (new attribute → AST → inference → per-backend emit)
**Touches docs**: libs/std/AGENTS.md, libs/std/docs.md, libs/std/src/AGENTS.md, libs/std/src/examples.md, docs.md (language reference: `@external`), modules/compiler-core/src/codegen/AGENTS.md
**Status**: F0–F3 done (merged into `feat`, 2026-06-05) — layout/wiring, `@[…]` +
`external` builtin, `"std"` package namespacing (`import {bool} from "std"`),
builtin `result` namespace, unified `@Result` runtime, `*fn` checked-Result rule,
optional chaining `?.` (v1, commonJS), `bool.bp`/`order.bp`/`pair.bp` + std type
exports + per-call-site generic record instantiation. **F4–F9 pending** — see
"Remaining work" below; each remaining module must land WITH its test suite
(stdlib-tests pairing).

> **Goal**: grow `libs/std` from 4 declaration files into a module set that mirrors
> Gleam's stdlib (`gleam/list`, `gleam/dict`, `gleam/option`, `gleam/result`,
> `gleam/int`, `gleam/float`, `gleam/bool`, `gleam/order`, `gleam/string`,
> `gleam/iterator`, …), callable as `import {list}; list.map(xs, f)` or via pipeline
> `xs |> list.map(f)`.
>
> **Architecture (working assumption — hybrid, flippable):**
> - **Pure-logic modules → real `.bp` implementations** (compile once, all backends):
>   `list`, `dict`, `set`, `option`, `result`, `order`, `pair`, `bool`, `iterator`,
>   `function`.
> - **Primitive/host-backed → declarations + externals** (`.d.bp`, codegen/FFI per
>   target): `int`, `float`, `string`, `io`, `bit_array`.
> This matches Gleam (most stdlib in Gleam, a thin FFI layer for primitives). If we
> instead keep the current *declarations-only* model, every `.bp` impl below becomes
> a `.d.bp` signature and the bodies move into codegen — see Notes.

## Module map (Gleam → botopink)

| Gleam module | botopink file | Kind | Notes |
|---|---|---|---|
| `gleam/option` | `option.bp` | impl | over built-in `?T` (`none`) |
| `gleam/result` | `result.bp` | impl | over built-in `@Result<D, E>` |
| `gleam/order` | `order.bp` | impl | `enum Order { Lt, Eq, Gt }` |
| `gleam/bool` | `bool.bp` | impl | guards/combinators |
| `gleam/pair` | `pair.bp` | impl | over `(a, b)` tuples |
| `gleam/list` | `list.bp` | impl | over `Array<T>` (botopink's list type) |
| `gleam/dict` | `dict.bp` | impl | `Dict<K, V>` |
| `gleam/set` | `set.bp` | impl | `Set<T>` on top of `dict` |
| `gleam/int` | `int.d.bp` | decl | parse/convert host-backed |
| `gleam/float` | `float.d.bp` | decl | parse/round host-backed |
| `gleam/string` | `string.d.bp` (extend existing) | decl | host string ops |
| `gleam/string_tree` | `string_builder.bp` | impl | efficient concat |
| `gleam/iterator` | `iterator.bp` | impl | lazy sequences |
| `gleam/function` | `function.bp` | impl | `identity`, `compose`, `flip` |
| `gleam/io` | `io.d.bp` | decl | `print`/`debug` host-backed |
| `gleam/bit_array`, `uri`, `regexp`, `dynamic`, `queue` | — | later | optional, Phase F10 |

## Steps

### F0 — module layout + wiring + conventions
- [ ] **Relocate the embed/loader glue out of `libs/std/`**: `libs/std/src/` keeps only
      `.bp`/`.d.bp` (language-neutral source); move `prelude.zig` into
      `modules/compiler-core/` (next to its consumer — `comptime` calls
      `registerStdlib`). Proposed home: `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
- [ ] Update `build.zig` for the relocated `std_prelude` Zig module path
- [ ] The relocated `prelude.zig` `@embedFile`s each `.bp`/`.d.bp` via a relative path
      into `libs/std/src/`; add one entry per new module
- [ ] Update `libs/std/AGENTS.md` + `docs.md`: `src/` is `.bp`-only; the loader now
      lives in compiler-core; the hybrid model (impl vs decl); import/call convention
- [ ] Decide calling convention: qualified (`list.map(xs, f)`) and/or pipeline (`xs |> list.map(f)`)

```zig
// modules/compiler-core/src/comptime/stdlib/prelude.zig  (relocated; was libs/std/src/prelude.zig)
const STD = "../../../../../libs/std/src/";   // .bp source stays under libs/std
pub const list   = @embedFile(STD ++ "list.bp");
pub const option = @embedFile(STD ++ "option.bp");
pub const result = @embedFile(STD ++ "result.bp");
// … one per module
```

### F1 — annotation syntax `@[…]` + `external` builtin (FFI primitive; prerequisite for decl modules)

`@external` is **not** a parser keyword. It is a **builtin function** declared in
`builtins.d.bp`, invoked inside the generic **annotation syntax `@[ … ]`** that
precedes a declaration. This keeps annotations extensible (future `@[deprecated(…)]`,
`@[inline]`, …) — `external` is just the first annotation builtin.

- [ ] Builtins: declare the annotation builtin in `builtins.d.bp`:
      `enum Target { node, typescript, erlang, beam, wasm }` +
      `fn external(target: Target, module: string, symbol: string)`
- [ ] Lexer/parser: annotation block `@[ <builtin-call> ("," <builtin-call>)* ]`
      placed above any declaration; an annotation is a normal builtin-function call
- [ ] AST: `decl.annotations: []Annotation { name, args }` (generic — not external-specific)
- [ ] Inference: type-check each annotation against its builtin signature in
      `builtins.d.bp`; a `pub fn` annotated with `external` needs **no body** (typed
      from the signature alone, like today's `.d.bp` declarations)
- [ ] Codegen: read the `external` annotations off the decl; each backend emits a call
      to its target's symbol (Erlang `module:symbol`, JS `import {symbol} from module`);
      error if the active target has no `external` for that fn

```bp
// libs/std/src/builtins.d.bp — the annotation builtin
enum Target { node, typescript, erlang, beam, wasm }
fn external(target: Target, module: string, symbol: string)
```
```bp
// libs/std/src/string.d.bp — used as an annotation via @[ … ]
@[external(erlang, "string", "length"),
  external(node, "./gleam_stdlib.mjs", "string_length")]
pub fn length(s: string) -> i32

@[external(erlang, "erlang", "abs"),
  external(node, "./stdlib.mjs", "abs")]
pub fn absolute_value(n: i32) -> i32
```
```text
mirrors Gleam (whose attribute is a language keyword)…
  @external(erlang, "string", "length")
  @external(javascript, "../gleam_stdlib.mjs", "string_length")
  pub fn length(string: String) -> Int
…but in botopink it is a builtin call inside @[ … ]:
  @[external(erlang, "string", "length"), external(node, "…", "string_length")]
```

### F2 — `option` + `result` (effect types over built-ins)
- [ ] `option.bp`: `map`, `then` (flat_map), `unwrap`, `or`, `is_some`, `is_none`, `to_result`
- [ ] `result.bp`: `map`, `map_error`, `then`, `unwrap`, `unwrap_error`, `or`, `is_ok`, `from_option`

```bp
// libs/std/src/option.bp
pub fn map(opt: ?T, f: fn(T) -> U) -> ?U = case opt {
    some(x) -> some(f(x)),
    none    -> none,
};

pub fn unwrap(opt: ?T, default: T) -> T = case opt {
    some(x) -> x,
    none    -> default,
};

// libs/std/src/result.bp
pub fn map(res: @Result<T, E>, f: fn(T) -> U) -> @Result<U, E> = case res {
    Ok(x)    -> Ok(f(x)),
    Error(e) -> Error(e),
};

pub fn then(res: @Result<T, E>, f: fn(T) -> @Result<U, E>) -> @Result<U, E> = case res {
    Ok(x)    -> f(x),
    Error(e) -> Error(e),
};
```
```bp
// usage
import {result, option};
val n = result.unwrap(parse_int("42"), 0);        // 42
val doubled = option.map(head, { x -> x * 2 });    // ?i32
```

### F3 — `order` + `bool` + `pair` (small foundations)
- [ ] `order.bp`: `enum Order { Lt, Eq, Gt }` + `reverse`, `negate`, `to_int`
- [ ] `bool.bp`: `negate`, `and`, `or`, `to_string`, `guard`
- [ ] `pair.bp`: `first`, `second`, `map_first`, `map_second`, `swap`

```bp
// libs/std/src/order.bp
pub enum Order { Lt, Eq, Gt }

pub fn reverse(o: Order) -> Order = case o {
    Lt -> Gt,
    Eq -> Eq,
    Gt -> Lt,
};

// libs/std/src/pair.bp
pub fn first(p: (a, b)) -> a  = p.0;
pub fn swap(p: (a, b)) -> (b, a) = (p.1, p.0);
```

### F4 — `list` (the core module, over `Array<T>`)
- [ ] Folds: `fold`, `fold_right`, `reduce`
- [ ] Transform: `map`, `index_map`, `filter`, `filter_map`, `flat_map`, `flatten`
- [ ] Query: `length`, `is_empty`, `contains`, `find`, `all`, `any`, `count`
- [ ] Build/slice: `append`, `prepend`, `reverse`, `take`, `drop`, `first`, `rest`, `range`
- [ ] Combine: `zip`, `unzip`, `intersperse`, `sort` (with `order`)

```bp
// libs/std/src/list.bp
pub fn fold(over: Array<T>, from: A, with: fn(A, T) -> A) -> A = case over {
    []          -> from,
    [x, ..rest] -> fold(rest, with(from, x), with),
};

pub fn map(over: Array<T>, f: fn(T) -> U) -> Array<U> =
    fold(over, [], { acc, x -> acc.push(f(x)) });

pub fn filter(over: Array<T>, keep: fn(T) -> bool) -> Array<T> =
    fold(over, [], { acc, x -> if keep(x) { acc.push(x) } else { acc } });
```
```bp
// usage — qualified + pipeline both work
import {list};
val evens = list.filter([1,2,3,4], { n -> n % 2 == 0 });   // [2, 4]
val total = [1,2,3] |> list.fold(0, { a, b -> a + b });     // 6
```

### F5 — `dict` + `set`
- [ ] `dict.bp`: `new`, `get`, `insert`, `delete`, `keys`, `values`, `size`, `merge`, `fold`, `map_values`
- [ ] `set.bp`: `new`, `insert`, `contains`, `delete`, `union`, `intersection`, `to_list` (on top of `dict`)

```bp
// libs/std/src/dict.bp
pub fn get(d: Dict<K, V>, key: K) -> ?V { /* … */ }
pub fn insert(d: Dict<K, V>, key: K, value: V) -> Dict<K, V> { /* … */ }
```
```bp
import {dict};
val d = dict.new() |> dict.insert("a", 1) |> dict.insert("b", 2);
val v = dict.get(d, "a");        // some(1)
```

### F6 — `int` + `float` (declarations + externals, via F1 `@[external(…)]`)
- [ ] `int.d.bp`: `parse`, `to_float`, `to_string`, `absolute_value`, `min`, `max`, `clamp`, `power`, `is_even`
- [ ] `float.d.bp`: `parse`, `round`, `floor`, `ceiling`, `truncate`, `to_string`, `power`, `square_root`

```bp
// libs/std/src/int.d.bp  (signatures + @[external]; bodies live in the host)
@[external(erlang, "erlang", "binary_to_integer"),
  external(node, "./gleam_stdlib.mjs", "parse_int")]
pub fn parse(s: string) -> @Result<i32, Nil>

@[external(erlang, "erlang", "float"),
  external(node, "./gleam_stdlib.mjs", "to_float")]
pub fn to_float(n: i32) -> f64

pub fn clamp(n: i32, min: i32, max: i32) -> i32   // pure → may be .bp impl instead
```

### F7 — `string` (+ `string_builder`, via F1 `@[external(…)]`)
- [ ] Extend `string.d.bp` to Gleam's surface: `length`, `reverse`, `replace`, `split`, `join`, `pad_left`, `pad_right`, `slice`, `contains`, `starts_with`, `to_graphemes`
- [ ] `string_builder.bp`: `new`, `append`, `from_strings`, `to_string` (efficient concat)

```bp
import {string};
val parts = string.split("a,b,c", ",");      // ["a", "b", "c"]
val s = string.join(["x", "y"], "-");        // "x-y"
```

### F8 — `iterator` (lazy sequences)
- [ ] `iterator.bp`: `from_list`, `map`, `filter`, `take`, `fold`, `to_list`, `range`, `repeat`
- [ ] Build on botopink's `@Iterator<_>` / `*fn` generators

```bp
// libs/std/src/iterator.bp
pub *fn range(from: i32, to: i32) -> @Iterator<i32> {
    let mut i = from;
    loop {
        if i >= to { break; }
        yield i;
        i = i + 1;
    }
}
```
```bp
import {iterator as iter};
val xs = iter.range(0, 5) |> iter.map({ n -> n * n }) |> iter.to_list();  // [0,1,4,9,16]
```

### F9 — `function` + `io` (`io` via F1 `@[external(…)]`)
- [ ] `function.bp`: `identity`, `compose`, `flip`, `const`
- [ ] `io.d.bp`: `print`, `println`, `debug` (host-backed)

```bp
// libs/std/src/function.bp
pub fn identity(x: a) -> a = x;
pub fn compose(f: fn(a) -> b, g: fn(b) -> c) -> fn(a) -> c = { x -> g(f(x)) };
```

### F10 — extended modules (optional)
- [ ] `bit_array`, `uri`, `regexp`, `dynamic`, `queue` — scope per demand

## Test scenarios

```
comptime ---- option_map_some_none           (inference: ?T threads through)
comptime ---- result_then_chains_error
comptime ---- list_fold_map_filter_infer
comptime ---- list_sort_with_order
comptime ---- dict_get_returns_option
comptime ---- iterator_range_map_to_list
codegen/node ---- list_map_filter            (CommonJS output)
codegen/erlang ---- list_fold                 (Erlang output)
codegen/beam ---- option_unwrap               (BEAM output)
codegen/wasm ---- int_clamp                   (WAT output / external)
parser ---- module_qualified_call list.map(xs, f)
parser ---- annotation_block_at_bracket            (@[ external(…), external(…) ] over a decl)
comptime ---- external_builtin_typechecks_args     (external(target, module, symbol) vs builtins.d.bp)
comptime ---- external_fn_no_body_typechecks
codegen/erlang ---- external_call_emits_module_symbol  (string:length/1)
codegen/node ---- external_call_emits_import           (import {string_length})
```

## Remaining work (carried over from the F0–F3 waves + stdlib-tests, 2026-06-05)

The unimplemented phases, in dependency order:

- **F4 — `list`** (the core module, over `Array<T>`): folds, transform, query,
  build/slice, combine (`sort` needs `order` — done). Pair with `list_test.bp`.
- **F5 — `dict` + `set`**: pair with `dict_test.bp` / `set_test.bp`.
- **F6 — `int` + `float`** (declarations + `@[external(…)]` — F1 mechanism done):
  pair with `number_test.bp`.
- **F7 — `string` + `string_builder`**: pair with extended `string_test.bp`.
- **F8 — `iterator`**: pair with `iterator_test.bp`.
- **F9 — `function` + `io`**: pair with `function_test.bp`.
- **F10 — extended modules** (optional, per demand).

**Test pairing rule** (from stdlib-tests): every module above lands in the same
commit as its `libs/std/test/<module>_test.bp` suite (and may carry inline
Zig-style `test { … }` blocks — the mechanism works, first one in `bool.bp`).

Discovered gaps that block or degrade the remaining phases (catalogued on
`task/test-blocks` TODO.md; fix within the phase that hits them or split out):

1. **snake_case builtin methods lack a JS name mapping** — the blind commonJS
   emitter writes `s.to_upper()` verbatim; only methods whose botopink name
   matches the JS native work. Blocks fuller `string` coverage (F7). Needs
   typed-value method dispatch (loc-keyed rewrites, like extension dispatch).
2. **Builtin method lowering is commonJS-only** — `.join`/`.split`/… emit
   invalid Erlang (syntax errors in `array_test.erl`); beam/wasm untested.
   Affects every module that leans on builtin methods.
3. **Erlang test runner can't reach `"std"` package modules** — the escript
   compiles/loads only the entry module, so `bool:negate(...)` is
   `error:undef`. Needs multi-file compile/load in the escript harness.
4. **Literal method receivers don't parse** — `"a,b".split(",")` is a parse
   error; receivers must be `val`-bound identifiers.
5. **Structural `==` on arrays** lowers to JS `===` (reference equality) —
   suites compare via `.join(...)`; motivates `expect().to_equal()`.
6. **Local generic fns share their type across call sites** (two calls with
   different types collapse) — std-module fns dodge this via the F2a
   `instantiateType` path; matters if F4+ helpers call local generics.
7. **`?.` codegen on erlang/beam/wasm** blocked on the record-field-access gap
   on those backends (commonJS native `?.` works).

## Notes

- **Architecture is the one open decision.** Hybrid is the assumption; to keep the
  current declarations-only model, turn every `.bp` impl above into a `.d.bp`
  signature and push the body into each backend's codegen — far more codegen work,
  but no `.bp` self-hosting requirement on BEAM/WASM.
- `option`/`result` build on the **existing** `@Option`/`@Result` method work
  (`map`/`flatMap`/`unwrapOr` from the stdlib-result task) — extend, don't duplicate.
- `list` operates on botopink's `Array<T>` (its list type); confirm list patterns
  `[]` / `[x, ..rest]` are accepted by the parser (they are used in every impl above).
- Each new file MUST get a matching `@embedFile` in the relocated `prelude.zig`
  (now under `modules/compiler-core/src/comptime/stdlib/`) or inference won't see it.
  `libs/std/src/` stays `.bp`-only.
- Keep signatures additive/stable — renames churn every codegen/comptime snapshot.
- Everything in English, including this file.
```
