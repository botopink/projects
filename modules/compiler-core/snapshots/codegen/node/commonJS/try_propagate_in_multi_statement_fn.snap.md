----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result<i32, IoError> {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result<i32, IoError> {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- JAVASCRIPT -- main.js
```javascript
class IoError {
    constructor(path) {
        this.path = path;
    }
}

function step1() {
    throw IoError("/data");
}

function step2(x) {
    throw IoError("/out");
}

function pipeline() {
    const _try0 = step1();
    if (_try0.tag === "Error") return _try0;
    const a = _try0.result;
    const _try1 = step2(a);
    if (_try1.tag === "Error") return _try1;
    const b = _try1.result;
    return b;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
