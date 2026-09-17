# Examples — before and after 1.0.4-beta

> **Naming.** Written for 1.0.3-beta, which was folded into 1.0.4-beta before it shipped. Here
> "1.0.3" names the **new surface** and "1.0.2" the **old one**; both land in the 1.0.4-beta release
> ([`overview.md`](./overview.md)).

Every **Before** block in sections 1–13 was compiled and run with `botopink check` / `botopink run`
at `botopink-lang` `41981e3` (commonJS target unless noted); the output is shown under it. The
**After** blocks are the target surface — what the migrated fixtures of fronts 12 and 13 must
reproduce, with the same output — and follow
[decision 8](./08-review-backlog/decision-8-language.md) (2026-09-17): `Self<T>` in generic
declarations, `case` arms as `Pattern { body }`, tuples without labels in construction. Sections
14–17 show decision 8's additions; they have no 1.0.2 counterpart and were not compiled — *to verify
when 06/12 land*.

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
    pub fn size(self: Self<T>) -> i32 {
        return self.items.length;
    }

    pub fn push(self: Self<T>, item: T) -> Self<T> {
        return Stack(items: self.items.append([item]));
    }
}

pub fn main() {
    val s = Stack(items: [1, 2]).push(3);
    @print(s.size());
}
```

In a generic declaration `Self` carries its type arguments (decision 8 §1.2).

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
        .Lt { -1 }
        .Eq { 0 }
        _ { 1 }
    };
}

pub fn main() {
    @print(toInt(Order.Gt));
}
```

A `case` arm is `Pattern { body }` and takes no `;`; `.Lt` names the variant of the matched value's
type (decision 8 §5).

---

## 5 — Enum with payloads and a method

**Before** — output `16` on the Erlang target. At `41981e3` commonJS type-checked it but failed at
run time (`Shape.Square(...).area is not a function`); fixed by
[`01-backend-residuals/`](./01-backend-residuals/README.md#delivered-by-this-front) step 3 (CR4,
`dbe2863`) — `16` on commonJS too.

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
            .Circle(r) { r * r * 3 }
            .Square(s) { s * s }
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

## 10 — Anonymous record → tuple

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

**After** — same output; the values are tuples at run time (`[0, 7]`, `[1, "n"]`)

```bp
fn origin() -> #(x: i32, y: i32) {
    return #(0, 7);
}

pub fn main() {
    val o = origin();
    val pairs = [1, 2].map({ i -> #(i, "n") });
    @print(o.y);
    @print(pairs.map({ p -> p.1 }).join(","));
}
```

Construction takes no labels; `origin`'s written return type gives them, so `o.y` is `o.1` at
compile time. The lambda's tuple has a label only for the variable element (`i`), so the literal is
read by position (decision 8 §6).

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
        8000 + t.length,
        true,
    ));
}

pub fn main() {
    val c = conf "abc";
    @print(c.port);
}
```

The labels come from the written `@Expr<#(port: i32, debug: bool)>`; that they reach `c.port`
through the template's expansion is *to verify when 06/12 land*.

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

**Before** — `val get = 42;` was a parse error at `41981e3` (and so were `auto`, `derive`, `macro`,
`set`, `opaque`, `private`; the compiler half landed in `ecac19d`, jhonstart's accessors in
`bf868ca`). `delegate` and `new` follow ([`06-checker/`](./06-checker/README.md) N27). jhonstart's `.d.bp` declares accessors that the parser already rejects:

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
val delegate = 1;               // after 06 N27
val new = 2;                    // after 06 N27 — `throw Error("x")`, not `throw new Error("x")`

pub behavior Router {
    fn pathname(self: Self) -> string;
    fn params(self: Self) -> Dict<string, string>;
    fn push(self: Self, href: string);
}
```

`x.get(k)` and `x.set(v)` keep working — they are plain method names.

---

## 14 — `unknown`, `is` and a guarded `case`

*Decision 8 §2, §4, §5 — to verify when 06/12 land.* Output `number 3` then `other`

```bp
fn describe(x: unknown) -> string {
    return case x {
        i32 { n -> "number " + n }
        string when (x == "") { "empty text" }
        string { s -> "text " + s }
        _ { "other" }
    };
}

pub fn main() {
    val a: unknown = 3.0;
    @print(describe(a));          // 3.0 fits i32: the value is converted
    @print(describe(true));
}
```

`_` is required: the matched value is `unknown`, and guarded arms never make a `case` exhaustive.

---

## 15 — Unions

*Decision 8 §3 — to verify when 06/12 land.* Output `2` then `1`

```bp
fn size(v: i32 | string) -> i32 {
    return case v {
        i32 { n -> n }
        string { s -> s.length }
    };
}

pub fn main() {
    val a = if (true) { 2 } else { "a" };     // i32 | string
    val xs = [1, "a"];                          // (i32 | string)[]
    @print(size(a));
    @print(size(xs[1]));
}
```

No `_`: every member is covered.

---

## 16 — Effects and `loop (condition)`

*Decision 8 §9, §10 — to verify when 06/12 land.* Output `3` then `0`

```bp
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") { throw "empty"; };
    return s.length;
}

pub fn main() {
    var attempts = 0;
    loop (attempts < 3) {
        attempts = attempts + 1;
    };
    val assert Ok(n) = parse("abc");
    @print(n);
    @print(parse("") catch 0);
}
```

`while` does not exist; `#[@result]` and `@Result<T, E>` go together.

---

## 17 — Printing

*Decision 8 §7 — to verify when 01 step 6 lands.* The same text on every backend:

```bp
pub type Point(x: i32, y: i32)

pub fn main() {
    @print([Point(x: 1, y: 2)]);      // [Point(x: 1, y: 2)]
    @print(#(1, "a\"b"));             // #(1, "a\"b")
    @print(2.0);                       // 2.0
    @print("hi");                      // hi
}
```
