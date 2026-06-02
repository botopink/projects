----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
fn strict() -> @Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class ApiError {
    constructor(msg) {
        this.msg = msg;
    }
}

function fetch() {
    throw ApiError("not found");
}

function strict() {
    const _try0 = fetch();
    if (_try0.tag === "Error") { throw "fetch failed"; }
    const r = _try0.result;
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
