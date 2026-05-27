----- SOURCE CODE -- config.bp
```botopink
pub val PORT = 8080;
pub val HOST = "localhost";
```

----- JAVASCRIPT -- config.js
```javascript
const PORT = 8080;

const HOST = "localhost";
```

----- TYPESCRIPT TYPEDEF -- config.d.ts
```typescript
export declare const PORT: i32;


export declare const HOST: string;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
use {PORT, HOST} = @root()
val addr = HOST;
val port = PORT;
```

----- JAVASCRIPT -- main.js
```javascript
const { PORT, HOST } = @root();

const addr = HOST;

const port = PORT;
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { PORT, HOST } from "./module";


import { PORT, HOST } from "./module";





```

----- RUN LOG -----
```logs
```
