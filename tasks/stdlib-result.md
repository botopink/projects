# Stdlib — `@Result` / `@Option`

**Branch**: `feat/stdlib-result`
**Depends on**: nothing (independent)
**Status**: pending
**File**: `builtins.d.bp`

## Steps

- [ ] `@Result.map(fn(D) -> D2)` — transform the Ok value
- [ ] `@Result.flatMap(fn(D) -> @Result<D2, E>)` — chain fallible operations
- [ ] `@Result.unwrapOr(default: D)` — extract Ok or use the default
- [ ] `@Result.isOk()` / `@Result.isError()` — boolean predicates
- [ ] `@Option.map` / `@Option.flatMap` / `@Option.unwrapOr` — mirror the Result API

## Examples

```bp
fn parseAge(s: string) -> @Result<i32, string> { todo; }

fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })                      // @Result<i32, string>
        .flatMap({ n -> validate(n) })            // @Result<i32, string>
        .unwrapOr(0);                             // i32

    val ok = parseAge("42").isOk();               // bool
}

fn firstName(p: Person) -> @Option<string> { todo; }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .unwrapOr("Hello stranger");
}
```

**Expected output (CommonJS):**
```javascript
// .map: applies only on Ok, propagates Error
// _r.tag === "Ok" ? Ok(f(_r.data)) : _r
```

## Test scenarios

```
stdlib ---- Result.map transforms Ok, propagates Error intact
stdlib ---- Result.map on Error does not call the function
stdlib ---- Result.flatMap chains, flattens @Result<@Result<..>>
stdlib ---- Result.flatMap on Error short-circuits
stdlib ---- Result.unwrapOr returns data on Ok, default on Error
stdlib ---- Result.isOk / isError correct predicates
stdlib ---- Option.map / flatMap / unwrapOr mirror Result
stdlib ---- Option.map on None does not call the function
stdlib ---- chain map().flatMap().unwrapOr() types correctly
```