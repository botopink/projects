----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime template: expr string) -> expr string {
    return expr { ${template} };
}
val name = "world";
val page = html """
<p>${name}</p>
""";
fn main() {
    @print(page);
}
```

----- JAVASCRIPT -- main.js
```javascript
const name = "world";

const page = (("\n<p>" + name) + "</p>\n");

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
export declare function html(template: ): any;







```

----- RUN LOG -----
```logs

<p>world</p>

```
