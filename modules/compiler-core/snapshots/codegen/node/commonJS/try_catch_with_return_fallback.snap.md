----- SOURCE CODE -- main.bp
```botopink
record NetError { code: i32 }
fn fetch() -> @Result<i32, NetError> {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class NetError {
    constructor(code) {
        this.code = code;
    }
}

function fetch() {
    throw NetError(500);
}

function safe() {
    const _try0 = fetch();
    if (_try0.tag === "Error") { return (-1); }
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
