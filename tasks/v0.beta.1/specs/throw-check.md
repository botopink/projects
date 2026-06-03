# Throw type checking

**Branch**: `feat/throw-check`
**Depends on**: nothing (independent)
**Status**: done (implemented & tested)

## Goal

Verify that the value thrown by `throw` matches the `E` of the enclosing function's `@Result<D, E>`.

## Steps

1. Verify thrown value vs the `E` of the enclosing fn's `@Result<D, E>` return
2. Error message: mismatch between thrown type and declared `E`

## Examples

### Match (pass)
```bp
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";   // ✓ "empty input": string == E
    }
    return 0;
}
```

### Mismatch (error)
```bp
fn parse(s: string) -> @Result<i32, string> {
    throw 404;   // ✗ error: i32 thrown, but E = string
}
```

### No Result return (error)
```bp
fn run() -> i32 {
    throw "x";   // ✗ error: throw without @Result in the fn's return
}
```

### Error as a record
```bp
record AppError { code: i32, msg: string }
fn load() -> @Result<string, AppError> {
    throw new AppError(500, "boom");   // ✓ AppError == E
}
```

## Test scenarios

```
throw ---- string matches declared E = string (pass)
throw ---- record matches declared E = ErrorRecord (pass)
throw ---- type mismatch i32 thrown but E = string (error)
throw ---- throw inside nested fn does not check outer fn's E
throw ---- throw inside catch handler checks enclosing fn's E
throw ---- multiple throw sites all must match E
throw ---- throw without enclosing Result return type (error)
```