----- SOURCE CODE -- jhonstart.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    loop (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
```

----- JAVASCRIPT -- jhonstart.js
```javascript
```

----- TYPESCRIPT TYPEDEF -- jhonstart.d.ts
```typescript
export declare function html(q: ): Expr<string>;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {html} from "jhonstart";

val name = "world";

val page = html
    \\<div>
    \\  <p>${name}</p>
    \\  <Page1/>
    \\</div>
;
fn main() {
    @print(page);
}
```

----- JAVASCRIPT -- main.js
```javascript
const { html } = require("jhonstart");

const name = "world";

const page = ((("" + "<div>\n  <p>") + name) + "</p>\n  <Page1/>\n</div>");

function main() {
    console.log(page);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { html } from "jhonstart";







```

----- RUN LOG -----
```logs
```
