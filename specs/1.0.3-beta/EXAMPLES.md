# Examples — Before and After 1.0.3-beta

This document shows **complete, real-world examples** of how code changes from 1.0.2-beta to
1.0.3-beta. Each example shows the full "before" and "after" so you can see the cumulative
effect of all three fronts:

- **F1**: `record`/`enum` → `type` (records use parentheses or `constructor` for fields)
- **F2**: `interface` → `behavior`
- **F3**: Dead keywords removed (`auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set`)

---

## Example 1 — Simple Record

### Before (1.0.2-beta)

```bp
pub record Point {
    x: i32,
    y: i32,
}

pub fn main() -> i32 {
    val p = Point(x: 10, y: 20);
    return p.x + p.y;
}
```

### After (1.0.3-beta) — Form 1 (preferred)

```bp
pub type Point(x: i32, y: i32) {
}

pub fn main() -> i32 {
    val p = Point(x: 10, y: 20);
    return p.x + p.y;
}
```

### After (1.0.3-beta) — Form 2 (alternative)

```bp
pub type Point {
    constructor(x: i32, y: i32)
}

pub fn main() -> i32 {
    val p = Point(x: 10, y: 20);
    return p.x + p.y;
}
```

**Changes:** `record Point { fields }` → `type Point(fields) {}` OR `type Point { constructor(fields) }`

---

## Example 2 — Generic Record with Methods

### Before (1.0.2-beta)

```bp
pub record Dict<K, V> {
    pairs: Array<#(K, V)>,

    pub fn lookup(self: Self, key: K) -> ?V {
        return self.pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
    }

    pub fn hasKey(self: Self, key: K) -> bool {
        return self.lookup(key) != null;
    }

    pub fn size(self: Self) -> i32 {
        return self.pairs.length;
    }
}
```

### After (1.0.3-beta) — Form 1

```bp
pub type Dict<K, V>(pairs: Array<#(K, V)>) {
    pub fn lookup(self: Self, key: K) -> ?V {
        return self.pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
    }

    pub fn hasKey(self: Self, key: K) -> bool {
        return self.lookup(key) != null;
    }

    pub fn size(self: Self) -> i32 {
        return self.pairs.length;
    }
}
```

### After (1.0.3-beta) — Form 2

```bp
pub type Dict<K, V> {
    constructor(pairs: Array<#(K, V)>)

    pub fn lookup(self: Self, key: K) -> ?V {
        return self.pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
    }

    pub fn hasKey(self: Self, key: K) -> bool {
        return self.lookup(key) != null;
    }

    pub fn size(self: Self) -> i32 {
        return self.pairs.length;
    }
}
```

**Changes:** `record Dict<K, V> { fields, methods }` → `type Dict<K, V>(fields) { methods }` OR `type Dict<K, V> { constructor(fields); methods }`

---

## Example 3 — Simple Enum

### Before (1.0.2-beta)

```bp
pub enum Order {
    Lt,
    Eq,
    Gt,
}

pub fn toInt(o: Order) -> i32 {
    return case o {
        Lt -> -1,
        Eq -> 0,
        _ -> 1,
    };
}
```

### After (1.0.3-beta)

```bp
pub type Order {
    Lt,
    Eq,
    Gt,
}

pub fn toInt(o: Order) -> i32 {
    return case o {
        Lt -> -1,
        Eq -> 0,
        _ -> 1,
    };
}
```

**Changes:** `enum` → `type` (1 line)

---

## Example 4 — Generic Enum with Payloads

### Before (1.0.2-beta)

```bp
pub enum Result<R, E> {
    Ok(result: R),
    Error(error: E),
}

pub fn divide(a: i32, b: i32) -> Result<i32, string> {
    if b == 0 {
        return Result.Error(error: "division by zero");
    }
    return Result.Ok(result: a / b);
}
```

### After (1.0.3-beta)

```bp
pub type Result<R, E> {
    Ok(result: R),
    Error(error: E),
}

pub fn divide(a: i32, b: i32) -> Result<i32, string> {
    if b == 0 {
        return Result.Error(error: "division by zero");
    }
    return Result.Ok(result: a / b);
}
```

**Changes:** `enum` → `type` (1 line)

---

## Example 5 — Enum with Sections

### Before (1.0.2-beta)

```bp
pub enum Token {
    Color {
        Red { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Blue { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4, 8, 16 },
        Y { 1, 2, 4, 8 },
    }
    Hover(inner: Token[]),
}

pub fn main() -> string {
    val tokens: Token[] = [
        .Pad.All.__4,
        .Color.Red.__500,
        Token.Hover([.Color.Blue.__100]),
    ];
    return tokens.toString();
}
```

### After (1.0.3-beta)

```bp
pub type Token {
    Color {
        Red { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Blue { 100, 200, 300, 400, 500, 600, 700, 800, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4, 8, 16 },
        Y { 1, 2, 4, 8 },
    }
    Hover(inner: Token[]),
}

pub fn main() -> string {
    val tokens: Token[] = [
        .Pad.All.__4,
        .Color.Red.__500,
        Token.Hover([.Color.Blue.__100]),
    ];
    return tokens.toString();
}
```

**Changes:** `enum` → `type` (1 line)

---

## Example 6 — Record with `implement`

### Before (1.0.2-beta)

```bp
pub record Element implement @Context<Element, Element> {
    tag: string,
    value: string,
    children: Array<Element>,
    attrs: Array<#(string, string)>,
}
```

### After (1.0.3-beta) — Form 1

```bp
pub type Element(tag: string, value: string, children: Array<Element>, attrs: Array<#(string, string)>) implement @Context<Element, Element> {
}
```

### After (1.0.3-beta) — Form 2

```bp
pub type Element implement @Context<Element, Element> {
    constructor(tag: string, value: string, children: Array<Element>, attrs: Array<#(string, string)>)
}
```

**Changes:** `record Name implement X { fields }` → `type Name(fields) implement X {}` OR `type Name implement X { constructor(fields) }`

---

## Example 7 — Anonymous Record Literal

### Before (1.0.2-beta)

```bp
pub fn createPoint() -> record { x: i32, y: i32 } {
    return record { x: 10, y: 20 };
}
```

### After (1.0.3-beta)

```bp
pub fn createPoint() -> type { x: i32, y: i32 } {
    return type { x: 10, y: 20 };
}
```

**Changes:** `record { … }` → `type { … }` (2 occurrences). Note: literals still use `{ }`, not `( )` or `constructor`.

---

## Example 8 — Simple Interface

### Before (1.0.2-beta)

```bp
pub interface Printable {
    fn print(self: Self) -> string,
}

pub record Document implement Printable {
    content: string,

    pub fn print(self: Self) -> string {
        return self.content;
    }
}
```

### After (1.0.3-beta) — Form 1

```bp
pub behavior Printable {
    fn print(self: Self) -> string,
}

pub type Document(content: string) implement Printable {
    pub fn print(self: Self) -> string {
        return self.content;
    }
}
```

### After (1.0.3-beta) — Form 2

```bp
pub behavior Printable {
    fn print(self: Self) -> string,
}

pub type Document implement Printable {
    constructor(content: string)

    pub fn print(self: Self) -> string {
        return self.content;
    }
}
```

**Changes:** `interface` → `behavior`, `record Name { fields, methods }` → `type Name(fields) { methods }` OR `type Name { constructor(fields); methods }`

---

## Example 9 — Interface with `extends`

### Before (1.0.2-beta)

```bp
interface Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

interface Integer extends Number {
    fn toString(self: Self) -> string,

    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}

interface Signed extends Integer {
    fn abs(self: Self) -> Self,
}

interface I32 extends Signed {}
```

### After (1.0.3-beta)

```bp
behavior Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

behavior Integer extends Number {
    fn toString(self: Self) -> string,

    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}

behavior Signed extends Integer {
    fn abs(self: Self) -> Self,
}

behavior I32 extends Signed {}
```

**Changes:** `interface` → `behavior` (4 lines)

---

## Example 10 — Interface with Fields

### Before (1.0.2-beta)

```bp
pub interface Request {
    val method: HttpMethod,
    val path: string,

    fn param(self: Self, name: string) -> string,
    fn query(self: Self, name: string) -> string,
    fn header(self: Self, name: string) -> string,
    fn body(self: Self) -> string,
}
```

### After (1.0.3-beta)

```bp
pub behavior Request {
    val method: HttpMethod,
    val path: string,

    fn param(self: Self, name: string) -> string,
    fn query(self: Self, name: string) -> string,
    fn header(self: Self, name: string) -> string,
    fn body(self: Self) -> string,
}
```

**Changes:** `interface` → `behavior` (1 line)

---

## Example 11 — Standalone `implement` Block

### Before (1.0.2-beta)

```bp
record Circle {
    radius: f64,
}

interface Drawable {
    fn draw(self: Self) -> string,
}

val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) -> string {
        return "Drawing circle with radius " + self.radius.toString();
    }
}
```

### After (1.0.3-beta) — Form 1

```bp
type Circle(radius: f64) {
}

behavior Drawable {
    fn draw(self: Self) -> string,
}

val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) -> string {
        return "Drawing circle with radius " + self.radius.toString();
    }
}
```

### After (1.0.3-beta) — Form 2

```bp
type Circle {
    constructor(radius: f64)
}

behavior Drawable {
    fn draw(self: Self) -> string,
}

val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) -> string {
        return "Drawing circle with radius " + self.radius.toString();
    }
}
```

**Changes:** `record` → `type` (with parentheses or constructor), `interface` → `behavior`. `implement` unchanged.

---

## Example 12 — Multiple Interfaces

### Before (1.0.2-beta)

```bp
interface UsbCharger {
    fn connect(self: Self) -> string,
}

interface SolarCharger {
    fn connect(self: Self) -> string,
}

record SmartCamera {
    model: string,
}

val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.connect(self: Self) -> string {
        return "Connected via USB";
    }
    fn SolarCharger.connect(self: Self) -> string {
        return "Connected via Solar";
    }
}
```

### After (1.0.3-beta) — Form 1

```bp
behavior UsbCharger {
    fn connect(self: Self) -> string,
}

behavior SolarCharger {
    fn connect(self: Self) -> string,
}

type SmartCamera(model: string) {
}

val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.connect(self: Self) -> string {
        return "Connected via USB";
    }
    fn SolarCharger.connect(self: Self) -> string {
        return "Connected via Solar";
    }
}
```

### After (1.0.3-beta) — Form 2

```bp
behavior UsbCharger {
    fn connect(self: Self) -> string,
}

behavior SolarCharger {
    fn connect(self: Self) -> string,
}

type SmartCamera {
    constructor(model: string)
}

val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.connect(self: Self) -> string {
        return "Connected via USB";
    }
    fn SolarCharger.connect(self: Self) -> string {
        return "Connected via Solar";
    }
}
```

**Changes:** `interface` → `behavior` (2 lines), `record` → `type` (with parentheses or constructor). `implement` unchanged.

---

## Example 13 — Comptime with Record Literal

### Before (1.0.2-beta)

```bp
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(record {
        server: record { host: "0.0.0.0", port: 8000 + t.length },
        debug: true,
    });
}
```

### After (1.0.3-beta)

```bp
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(type {
        server: type { host: "0.0.0.0", port: 8000 + t.length },
        debug: true,
    });
}
```

**Changes:** `record { … }` → `type { … }` (3 occurrences). Note: literals still use `{ }`.

---

## Example 14 — Dead Keywords Become Identifiers

### Before (1.0.2-beta)

```bp
// These would fail to parse:
val auto = 10;          // ERROR: 'auto' is a reserved word
val derive = "test";    // ERROR: 'derive' is a reserved word
val macro = fn() {};    // ERROR: 'macro' is a reserved word
val get = 42;           // ERROR: 'get' is a keyword
val set = 99;           // ERROR: 'set' is a keyword
```

### After (1.0.3-beta)

```bp
// These now compile:
val auto = 10;          // OK: 'auto' is a valid identifier
val derive = "test";    // OK: 'derive' is a valid identifier
val macro = fn() {};    // OK: 'macro' is a valid identifier
val get = 42;           // OK: 'get' is a valid identifier
val set = 99;           // OK: 'set' is a valid identifier
```

**Changes:** Dead keywords (`auto`, `derive`, `macro`, `get`, `set`) are now valid identifiers.

---

## Example 15 — Complete Real-World Module

### Before (1.0.2-beta) — `http.bp`

```bp
pub enum HttpMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Head,
    Options,
}

pub record Request {
    method: HttpMethod,
    path: string,
    headers: Dict<string, string>,
    body: string,
}

pub record Response {
    status: i32,
    body: string,
}

pub interface Handler {
    fn handle(self: Self, req: Request) -> Response,
}

pub record Server {
    port: i32,
    handler: Handler,

    pub fn start(self: Self) {
        @print("Starting server on port " + self.port.toString());
    }
}
```

### After (1.0.3-beta) — `http.bp` — Form 1

```bp
pub type HttpMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Head,
    Options,
}

pub type Request(method: HttpMethod, path: string, headers: Dict<string, string>, body: string) {
}

pub type Response(status: i32, body: string) {
}

pub behavior Handler {
    fn handle(self: Self, req: Request) -> Response,
}

pub type Server(port: i32, handler: Handler) {
    pub fn start(self: Self) {
        @print("Starting server on port " + self.port.toString());
    }
}
```

### After (1.0.3-beta) — `http.bp` — Form 2

```bp
pub type HttpMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Head,
    Options,
}

pub type Request {
    constructor(method: HttpMethod, path: string, headers: Dict<string, string>, body: string)
}

pub type Response {
    constructor(status: i32, body: string)
}

pub behavior Handler {
    fn handle(self: Self, req: Request) -> Response,
}

pub type Server {
    constructor(port: i32, handler: Handler)

    pub fn start(self: Self) {
        @print("Starting server on port " + self.port.toString());
    }
}
```

**Changes:** `enum` → `type`, `record Name { fields }` → `type Name(fields) {}` OR `type Name { constructor(fields) }`, `interface` → `behavior`

---

## Summary of Changes per Example

| # | Example | Lines Changed | Keywords Affected |
|---|---------|---------------|-------------------|
| 1 | Simple record | 1 | `record Point { x, y }` → `type Point(x, y) {}` OR `type Point { constructor(x, y) }` |
| 2 | Generic record + methods | 1 | `record Dict<K,V> { fields, methods }` → `type Dict<K,V>(fields) { methods }` OR `type Dict<K,V> { constructor(fields); methods }` |
| 3 | Simple enum | 1 | `enum` → `type` |
| 4 | Generic enum + payloads | 1 | `enum` → `type` |
| 5 | Enum with sections | 1 | `enum` → `type` |
| 6 | Record with `implement` | 1 | `record Name implement X { fields }` → `type Name(fields) implement X {}` OR `type Name implement X { constructor(fields) }` |
| 7 | Anonymous record literal | 2 | `record { … }` → `type { … }` (literals unchanged) |
| 8 | Simple interface | 2 | `interface` → `behavior`, `record` → `type` (with parentheses or constructor) |
| 9 | Interface with `extends` | 4 | `interface` → `behavior` (×4) |
| 10 | Interface with fields | 1 | `interface` → `behavior` |
| 11 | Standalone `implement` | 2 | `record` → `type` (with parentheses or constructor), `interface` → `behavior` |
| 12 | Multiple interfaces | 3 | `interface` → `behavior` (×2), `record` → `type` (with parentheses or constructor) |
| 13 | Comptime record literal | 3 | `record { … }` → `type { … }` (×3, literals unchanged) |
| 14 | Dead keywords as identifiers | 5 | `auto`, `derive`, `macro`, `get`, `set` now valid |
| 15 | Complete HTTP module | 5 | `enum` → `type`, `record` → `type` (×3, with parentheses or constructor), `interface` → `behavior` |

**Total across all examples: 33 lines changed**

---

## Key Syntax Difference

**Record declaration — Form 1 (preferred):**
- Before: `record Name { field: Type, ... }`
- After: `type Name(field: Type, ...) { methods }`

**Record declaration — Form 2 (alternative):**
- Before: `record Name { field: Type, ... }`
- After: `type Name { constructor(field: Type, ...); methods }`

**Enum declaration:**
- Before: `enum Name { Variant, ... }`
- After: `type Name { Variant, ... }`

**Record literal (expression):**
- Before: `record { field: value, ... }`
- After: `type { field: value, ... }` (still uses `{ }`, not `( )` or `constructor`)

The key insight: **declarations** use `( )` or `constructor` for fields (mirroring constructor calls), but **literals** use `{ }` (mirroring object initialization). Both forms are equivalent and produce the same AST.

---

## What Does NOT Change

- `implement` keyword — unchanged
- `extends` keyword — unchanged
- Method syntax (`fn`, `default fn`, `declare fn`) — unchanged
- Field syntax in interfaces (`val`) — unchanged
- Constructor call syntax (`Point(x: 10, y: 20)`) — unchanged
- Pattern matching (`case`) — unchanged
- Generic syntax (`<T, E>`) — unchanged
- Annotation syntax (`#[...]`) — unchanged
- Runtime representation — unchanged
