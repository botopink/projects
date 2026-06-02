----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- JAVASCRIPT -- main.js
```javascript
class ParseError {
    constructor(msg) {
        this.msg = msg;
    }
}

class Parser {

    parse() {
        throw ParseError("bad input");
    }
}

function run(p) {
    const result = (() => { try { return p.parse(); } catch(_e) { return (0)(_e); } })();
    return result;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
