----- SOURCE CODE -- main.bp
```botopink
use { foo, bar } from "mylib";
```

----- JAVASCRIPT -- main.js
```javascript
const { foo, bar } = require("./mylib.js");
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
```

----- RUN LOG -----
```logs
node:internal/modules/cjs/loader:1478
  throw err;
  ^

Error: Cannot find module './mylib.js'
Require stack:
- /home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js
    at Module._resolveFilename (node:internal/modules/cjs/loader:1475:15)
    at wrapResolveFilename (node:internal/modules/cjs/loader:1048:27)
    at defaultResolveImplForCJSLoading (node:internal/modules/cjs/loader:1072:10)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1093:12)
    at Module._load (node:internal/modules/cjs/loader:1261:25)
    at wrapModuleLoad (node:internal/modules/cjs/loader:255:19)
    at Module.require (node:internal/modules/cjs/loader:1575:12)
    at require (node:internal/modules/helpers:191:16)
    at Object.<anonymous> (/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js:1:22)
    at Module._compile (node:internal/modules/cjs/loader:1831:14) {
  code: 'MODULE_NOT_FOUND',
  requireStack: [
    '/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js'
  ]
}

Node.js v25.8.0
```
