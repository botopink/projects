# try/catch lowering

**Branch**: `feat/trycatch-lowering`
**Depends on**: nothing (independent)
**Status**: done

> `try`/`catch` must lower to pattern matching on `Ok`/`Error`, **not** to JS try/catch.

## Steps

1. CommonJS: `try expr catch fallback` → `const _r = expr(); if (_r.tag === "Error") { … } else { _r.data }`
2. Erlang: → `case Expr of {ok, V} -> V; {error, E} -> Fallback end`
3. BEAM ASM: via `{test, is_tagged_tuple, …}` or case dispatch
4. WAT: → `if` on the Ok/Error tag (i32) in linear memory

## Examples

### try without catch (propagates Error)
```bp
fn process() -> @Result<i32, string> {
    val r = try fetch();   // if Error, returns process()'s Error
    return r + 1;
}
```
```javascript
const _r = fetch();
if (_r.tag === "Error") return _r;
const r = _r.data;
return r + 1;
```

### try with literal catch
```bp
fn safe() -> i32 {
    val r = try fetch() catch 0;   // Error → 0
    return r;
}
```
```javascript
const _r = fetch();
const r = _r.tag === "Error" ? 0 : _r.data;
return r;
```

### catch with handler (receives the error)
```bp
fn safe() -> i32 {
    val r = try fetch() catch { e -> log(e); 0 };
    return r;
}
```

### Erlang
```erlang
case fetch() of
    {ok, V}     -> V;
    {error, _E} -> 0
end.
```

## Test scenarios

```
try ---- simple try unwraps Ok to value (CommonJS, Erlang, BEAM, WAT)
try ---- catch with literal fallback on Error (CommonJS, Erlang)
try ---- catch with lambda handler receives error value (CommonJS, Erlang)
try ---- nested try catch both lowered to pattern match
try ---- try without catch propagates Error variant up
try ---- catch tail on method call chain
try ---- multiple try in same fn body independent temps
try ---- try on non-Result type (comptime error)
```