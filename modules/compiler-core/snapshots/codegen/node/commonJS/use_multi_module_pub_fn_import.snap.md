----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- JAVASCRIPT -- math.js
```javascript
function double(x) {
    return (x * 2);
}
exports.double = double;
```

----- TYPESCRIPT TYPEDEF -- math.d.ts
```typescript
export declare function double(x: ): i32;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
use {double} from "math";
val result = double(21);
```

----- JAVASCRIPT -- main.js
```javascript
const { double } = require("./math.js");

const result = double(21);
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { double } from "./math";



```

----- RUN LOG -----
```logs
node:internal/modules/cjs/loader:1478
  throw err;
  ^

Error: Cannot find module './math.js'
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
    at Object.<anonymous> (/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js:1:20)
    at Module._compile (node:internal/modules/cjs/loader:1831:14) {
  code: 'MODULE_NOT_FOUND',
  requireStack: [
    '/home/ericfillipe/develop/botopink-lang/modules/compiler-core/tmp_run.js'
  ]
}

Node.js v25.8.0
```
