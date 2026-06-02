# try/catch lowering

**Branch**: `feat/trycatch-lowering`
**Depends on**: nothing (independent)
**Status**: ✅ done

> `try`/`catch` must lower to pattern matching on `Ok`/`Error`, **not** to JS try/catch.

## Steps

1. ✅ CommonJS: `const _try0 = expr; if (_try0.tag === "Error") return _try0; const r = _try0.result;` (propagate) / `_try0.tag === "Error" ? fallback : _try0.result` (catch)
2. ✅ Erlang: `case Expr of {ok, V} -> V; {error, E} -> Fallback end` (catch); propagate nests the rest of the body in the `{ok, V}` arm
3. ✅ BEAM ASM: `{test, is_tagged_tuple, {f, L}, {x,0}, 2, {atom, ok}}` + `get_tuple_element`; propagate via early `return`
4. ✅ WAT: `i32.load` of the tag + `if`/`else` on Ok/Error; payload at `offset=4` in linear memory
5. ✅ Inference: `try`/`catch` on a non-`@Result` value is a compile-time error (`tryOnNonResult`)

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

All covered by `codegen/tests.zig` (4 targets each) + `comptime/tests.zig`:

```
✅ try ---- simple try unwraps Ok to value (CommonJS, Erlang, BEAM, WAT)
✅ try ---- catch with literal fallback on Error (CommonJS, Erlang)
✅ try ---- catch with lambda handler receives error value (CommonJS, Erlang)
✅ try ---- nested try catch both lowered to pattern match
✅ try ---- try without catch propagates Error variant up
✅ try ---- catch tail on method call chain
✅ try ---- multiple try in same fn body independent temps
✅ try ---- try on non-Result type (comptime error → comptime/tests.zig)
```