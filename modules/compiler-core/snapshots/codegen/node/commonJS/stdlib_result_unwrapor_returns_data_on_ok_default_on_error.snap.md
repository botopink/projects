----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val n = parseAge("42").unwrapOr(0);
}
```

----- JAVASCRIPT -- main.js
```javascript
function parseAge(s) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const n = ((_r) => _r.tag === "Ok" ? _r.result : (0))(parseAge("42"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
