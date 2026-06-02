----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
```

----- JAVASCRIPT -- main.js
```javascript
class DbError {
    constructor(msg) {
        this.msg = msg;
    }
}

function inner() {
    throw DbError("conn refused");
}

function outer() {
    throw DbError("timeout");
}

function process() {
    const _try0 = inner();
    const a = _try0.tag === "Error" ? (0) : _try0.result;
    const _try1 = outer();
    const b = _try1.tag === "Error" ? (a) : _try1.result;
    console.log(a, b);
    return (a + b);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
