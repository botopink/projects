----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
fn getA() -> @Result<i32, CalcError> {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- JAVASCRIPT -- main.js
```javascript
class CalcError {
    constructor(msg) {
        this.msg = msg;
    }
}

function getA() {
    throw CalcError("overflow");
}

function compute() {
    const _try0 = getA();
    const r = _try0.tag === "Error" ? (0) : _try0.result;
    return r;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
