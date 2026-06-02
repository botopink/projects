----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn validate(n: i32) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })
        .flatMap({ n -> validate(n) })
        .unwrapOr(0);
}
```

----- JAVASCRIPT -- main.js
```javascript
function parseAge(s) {
    (() => { throw new Error("not implemented") })();
}

function validate(n) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const r = ((_r) => _r.tag === "Ok" ? _r.result : (0))(((_r) => _r.tag === "Ok" ? ((n) => {
    validate(n);
})(_r.result) : _r)(((_r) => _r.tag === "Ok" ? { tag: "Ok", result: ((n) => {
    (n + 1);
})(_r.result) } : _r)(parseAge("42"))));
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
