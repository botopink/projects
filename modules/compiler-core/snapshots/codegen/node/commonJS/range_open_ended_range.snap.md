----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    loop (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function countUp(x) {
    for (const [i] of Object.entries(x..)) {
    (() => { if ((i > 100)) { return return; } })();
};
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js:2
    for (const [i] of Object.entries(x..)) {
                                       ^

SyntaxError: Unexpected token '.'
    at wrapSafe (node:internal/modules/cjs/loader:1762:18)
    at Module._compile (node:internal/modules/cjs/loader:1805:20)
    at Object..js (node:internal/modules/cjs/loader:1971:10)
    at Module.load (node:internal/modules/cjs/loader:1552:32)
    at Module._load (node:internal/modules/cjs/loader:1354:12)
    at wrapModuleLoad (node:internal/modules/cjs/loader:255:19)
    at Module.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:154:5)
    at node:internal/main/run_main_module:33:47

Node.js v25.8.0
```
