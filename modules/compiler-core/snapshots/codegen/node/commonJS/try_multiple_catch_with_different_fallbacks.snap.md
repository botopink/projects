----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
```

----- JAVASCRIPT -- main.js
```javascript
class UserError {
    constructor(msg) {
        this.msg = msg;
    }
}

function fetchName() {
    throw UserError("name missing");
}

function fetchAge() {
    throw UserError("age missing");
}

function loadUser() {
    const _try0 = fetchName();
    const name = _try0.tag === "Error" ? ("anonymous") : _try0.result;
    const _try1 = fetchAge();
    const age = _try1.tag === "Error" ? (0) : _try1.result;
    console.log(name, age);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
