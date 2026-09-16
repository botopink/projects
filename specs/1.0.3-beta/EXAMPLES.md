# Examples — before and after 1.0.3-beta

Every **Before** block was compiled and run with `botopink check` / `botopink run` at
`botopink-lang` `41981e3` (commonJS target unless noted); the output is shown under it. The
**After** blocks are the target surface — they are what F3's migrated fixtures must reproduce, with
the same output.

---

## 1 — Record, labeled and positional construction

**Before** — output `12`

```bp
pub record Point {
    x: i32,
    y: i32,
}

pub fn main() {
    val p = Point(x: 10, y: 20);
    val q = Point(1, 2);
    @print(p.x + q.y);
}
```

**After**

```bp
pub type Point(x: i32, y: i32)

pub fn main() {
    val p = Point(x: 10, y: 20);
    val q = Point(1, 2);
    @print(p.x + q.y);
}
```

The declaration and the construction now read the same way.

---

## 2 — Generic record with methods

**Before** — output `3`

```bp
pub record Stack<T> {
    items: T[],

    pub fn size(self: Self) -> i32 {
        return self.items.length;
    }

    pub fn push(self: Self, item: T) -> Stack<T> {
        return Stack(items: self.items.append([item]));
    }
}

pub fn main() {
    val s = Stack(items: [1, 2]).push(3);
    @print(s.size());
}
```

**After**

```bp
pub type Stack<T>(items: T[]) {
    pub fn size(self: Self) -> i32 {
        return self.items.length;
    }

    pub fn push(self: Self, item: T) -> Stack<T> {
        return Stack(items: self.items.append([item]));
    }
}

pub fn main() {
    val s = Stack(items: [1, 2]).push(3);
    @print(s.size());
}
```

---

## 3 — Fields with a comment and defaults

**Before** — output `8080`

```bp
pub record Config {
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,
    debug: bool = false,
}

pub fn main() {
    val c = Config(host: "localhost", port: 8080, debug: true);
    @print(c.port);
}
```

**After**

```bp
pub type Config(
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,
    debug: bool = false,
)

pub fn main() {
    val c = Config(host: "localhost", port: 8080, debug: true);
    @print(c.port);
}
```

The trailing comma keeps one field per line; the comment stays attached to `host` (today the
record parser drops it).

---

## 4 — Simple enum

**Before** — output `1`

```bp
pub enum Order {
    Lt,
    Eq,
    Gt,
}

pub fn toInt(o: Order) -> i32 {
    return case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
}

pub fn main() {
    @print(toInt(Order.Gt));
}
```

**After**

```bp
pub type Order {
    Lt,
    Eq,
    Gt,
}

pub fn toInt(o: Order) -> i32 {
    return case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
}

pub fn main() {
    @print(toInt(Order.Gt));
}
```

---

## 5 — Enum with payloads and a method

**Before** — output `16` on the Erlang target. On commonJS it type-checks but fails at runtime
(`Shape.Square(...).area is not a function`) — a 1.0.2-beta defect, see
[`overview.md`](./overview.md#found-during-the-review--belongs-to-102-beta).

```bp
pub enum Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn main() {
    @print(Shape.Square(side: 4).area());
}
```

**After**

```bp
pub type Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn main() {
    @print(Shape.Square(side: 4).area());
}
```

---

## 6 — Enum with sections

**Before** — output `3`

```bp
pub enum Token {
    Color {
        Red { 100, 500, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4 },
    }
    Hover(inner: Token[]),
}

pub fn main() {
    val tokens: Token[] = [
        .Pad.X.__4,
        .Color.Red.__500,
        Token.Hover([.Color.Red.__100]),
    ];
    @print(tokens.length);
}
```

**After**

```bp
pub type Token {
    Color {
        Red { 100, 500, 900 },
        Hex(value: string),
    }
    Pad {
        X { 1, 2, 4 },
    }
    Hover(inner: Token[]),
}

pub fn main() {
    val tokens: Token[] = [
        .Pad.X.__4,
        .Color.Red.__500,
        Token.Hover([.Color.Red.__100]),
    ];
    @print(tokens.length);
}
```

Sections end with `}` and take no comma.

---

## 7 — Record with no fields

**Before** — output `3`

```bp
pub record MathOps {
    pub fn add(a: i32, b: i32) -> i32 {
        return a + b;
    }
}

pub fn main() {
    @print(MathOps.add(1, 2));
}
```

**After**

```bp
pub type MathOps {
    pub fn add(a: i32, b: i32) -> i32 {
        return a + b;
    }
}

pub fn main() {
    @print(MathOps.add(1, 2));
}
```

No parentheses and no variant in the body → a record with no fields.

---

## 8 — Behavior implemented by a record

**Before** — output `<p>hi</p>`

```bp
pub interface Renderable {
    fn render(self: Self) -> string,
}

pub record Document implement Renderable {
    content: string,

    pub fn render(self: Self) -> string {
        return "<p>" + self.content + "</p>";
    }
}

pub fn main() {
    val d = Document(content: "hi");
    @print(d.render());
}
```

**After**

```bp
pub behavior Renderable {
    fn render(self: Self) -> string;
}

pub type Document(content: string) implement Renderable {
    pub fn render(self: Self) -> string {
        return "<p>" + self.content + "</p>";
    }
}

pub fn main() {
    val d = Document(content: "hi");
    @print(d.render());
}
```

---

## 9 — Behaviors with `extends` and a default method

**Before** — output `1`

```bp
interface Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,
}

interface Integer extends Number {
    fn toString(self: Self) -> string,
    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}

pub fn main() {
    @print(1);
}
```

**After**

```bp
behavior Number {
    fn min(self: Self, other: Self) -> Self;
    fn max(self: Self, other: Self) -> Self;
}

behavior Integer extends Number {
    fn toString(self: Self) -> string;

    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}

pub fn main() {
    @print(1);
}
```

Bodyless members end with `;`; the default method takes nothing after `}`.

---

## 10 — Anonymous record → labeled tuple

**Before** — output `7` then `n,n`

```bp
fn origin() -> { x: i32, y: i32 } {
    return record { x: 0, y: 7 };
}

pub fn main() {
    val o = origin();
    val pairs = [1, 2].map({ i -> record { key: i, label: "n" } });
    @print(o.y);
    @print(pairs.map({ p -> p.label }).join(","));
}
```

**After** — same output; the values are tuples at runtime (`[0, 7]`, `[1, "n"]`)

```bp
fn origin() -> #(x: i32, y: i32) {
    return #(x: 0, y: 7);
}

pub fn main() {
    val o = origin();
    val pairs = [1, 2].map({ i -> #(key: i, label: "n") });
    @print(o.y);
    @print(pairs.map({ p -> p.label }).join(","));
}
```

---

## 11 — Comptime template returning a labeled tuple

**Before** — output `8003`

```bp
pub fn conf(comptime q: @Expr<string>) -> @Expr<{ port: i32, debug: bool }> {
    val t = q.text();
    return @expr(record {
        port: 8000 + t.length,
        debug: true,
    });
}

pub fn main() {
    val c = conf "abc";
    @print(c.port);
}
```

**After**

```bp
pub fn conf(comptime q: @Expr<string>) -> @Expr<#(port: i32, debug: bool)> {
    val t = q.text();
    return @expr(#(
        port: 8000 + t.length,
        debug: true,
    ));
}

pub fn main() {
    val c = conf "abc";
    @print(c.port);
}
```

---

## 12 — A small module

**Before** — output `hi /`

```bp
pub enum Method {
    Get,
    Post,
}

pub record Request {
    method: Method,
    path: string,
}

pub record Response {
    status: i32,
    body: string,
}

pub interface Handler {
    fn handle(self: Self, req: Request) -> Response,
}

pub record Hello implement Handler {
    greeting: string,

    pub fn handle(self: Self, req: Request) -> Response {
        return Response(status: 200, body: self.greeting + " " + req.path);
    }
}

pub fn main() {
    val res = Hello(greeting: "hi").handle(Request(method: Method.Get, path: "/"));
    @print(res.body);
}
```

**After**

```bp
pub type Method {
    Get,
    Post,
}

pub type Request(method: Method, path: string)

pub type Response(status: i32, body: string)

pub behavior Handler {
    fn handle(self: Self, req: Request) -> Response;
}

pub type Hello(greeting: string) implement Handler {
    pub fn handle(self: Self, req: Request) -> Response {
        return Response(status: 200, body: self.greeting + " " + req.path);
    }
}

pub fn main() {
    val res = Hello(greeting: "hi").handle(Request(method: Method.Get, path: "/"));
    @print(res.body);
}
```

---

## 13 — Freed keywords and accessors

**Before** — `val get = 42;` is a parse error today (and so are `auto`, `derive`, `macro`, `set`,
`opaque`, `private`). jhonstart's `.d.bp` declares accessors that the parser already rejects:

```bp
pub interface Router {
    get pathname(self: Self) -> string
    get params(self: Self) -> Dict<string, string>
    fn push(self: Self, href: string)
}
```

**After**

```bp
val get = 42;
val set = 99;
val auto = 10;

pub behavior Router {
    fn pathname(self: Self) -> string;
    fn params(self: Self) -> Dict<string, string>;
    fn push(self: Self, href: string);
}
```

`x.get(k)` and `x.set(v)` keep working — they are plain method names.
