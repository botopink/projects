# Migrating to 1.0.4-beta

> **Naming.** Written for 1.0.3-beta, which was folded into 1.0.4-beta before it shipped. Here
> "1.0.3" names the **new surface** and "1.0.2" the **old one**; both land in the 1.0.4-beta release
> ([`overview.md`](./overview.md)). The language design decided on 2026-09-17 —
> [decision 8](./08-review-backlog/decision-8-language.md), with decision 5 — is part of this
> migration.

1.0.4-beta is a hard cutover: the old spellings are parse errors, with a diagnostic that names the
replacement. Migration is manual (beta phase).

## Keywords

| 1.0.2-beta | 1.0.4-beta |
|---|---|
| `record Name { fields, methods }` | `type Name(fields) { methods }` |
| `enum Name { variants, methods }` | `type Name { variants, methods }` |
| `interface Name { … }` | `behavior Name { … }` |
| `record { x: 1 }` (value) | `#(1)`, or `#(x)` from a variable `x` — a tuple |
| `{ x: i32 }` (type) | `#(x: i32)` — a tuple type, labels optional |
| `record { }` / `{}` | `#()` |
| `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` | ordinary identifiers |
| `delegate`, `new` | ordinary identifiers — `throw Error("x")`, not `throw new Error("x")` |
| `get name(self: Self) -> T` (accessor in `.d.bp`) | `fn name(self: Self) -> T;` |
| `while (cond) { … }` | `loop (cond) { … }` |
| `$self` in an `#[@External…]` template | `$0` (the first declared parameter, `self` included) |

`type` keeps its existing meaning in type position (`comptime T: type`, `-> type`).

## Records

```bp
// 1.0.2-beta
pub record Config {
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,

    pub fn url(self: Self) -> string {
        return self.host + ":" + self.port.toString();
    }
}

// 1.0.4-beta
pub type Config(
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,
) {
    pub fn url(self: Self) -> string {
        return self.host + ":" + self.port.toString();
    }
}
```

- Fields go in parentheses, like the call that builds the value: `Config(host: "h", port: 80)`.
- Fields keep defaults, annotations and comments. The `val` prefix on a field is gone.
- The body is optional: `pub type Point(x: i32, y: i32)`.
- A record with no fields has no parentheses: `pub type MathOps { pub fn add(…) … }`.

## Enums

```bp
pub type Shape {
    Circle(radius: f64),
    Square(side: f64),

    pub fn area(self: Self) -> f64 { … }
}
```

- A body with at least one variant or section is an enum.
- Variants come before methods.
- Variant payloads use the same field list as records (annotations and comments allowed).

## Behaviors

```bp
pub behavior Request {
    val method: HttpMethod;
    val path: string;

    fn param(self: Self, name: string) -> string;

    default fn isGet(self: Self) -> bool {
        return self.method == HttpMethod.Get;
    }
}
```

Same semantics as `interface`. Members end with `;` when they have no body; nothing follows a `}`.

## Generic types and `Self`

A written generic type carries all its type arguments — in a parameter, a return type, a field, an
annotation — and so does `Self` inside a generic `type` or `behavior`.

```bp
// 1.0.2-beta
pub interface Array<T> {
    fn filter(self: Self, pred: fn(item: T) -> bool) -> Self
    fn map<U>(self: Self, f: fn(item: T) -> U) -> Array<U>
}
fn isOk(r: Result) -> bool { … }

// 1.0.4-beta
pub behavior Array<T> {
    fn filter(self: Self<T>, pred: fn(item: T) -> bool) -> Self<T>;
    fn map<U>(self: Self<T>, f: fn(item: T) -> U) -> Self<U>;
}
fn isOk<T, E>(r: Result<T, E>) -> bool { … }
```

- In a type with no type parameters `Self` stays bare.
- A non-generic type implementing a generic behavior writes `Self`, and the behavior's extra type
  parameter is bound to its argument: `type Point(x: i32) implement Mappable<i32>` has
  `fn map(self: Self, f: fn(x: i32) -> i32) -> Self`.
- Explicit type arguments are allowed at a use: `Option<i32>.None`, `first<string>([])`.

## Declarations that would be `unknown`

A type argument is decided where the value is born — written at the use, from the arguments, or from
the immediate context (return type, annotation, parameter). Later uses never decide it, so an
unannotated empty literal is `unknown`, with a warning:

```bp
// 1.0.2-beta
var out = [];
out = out.append([1]);
return out;                       // fn … -> i32[]

// 1.0.4-beta
var out: i32[] = [];
out = out.append([1]);
return out;
```

`val z = Option.None;` is `Option<unknown>` — write `val z: Option<i32> = Option.None;`. A `pub`
declaration whose inferred type contains `unknown` is an error.

## Tuples

```bp
val name = "SP";
val pop = 12;
val row = #(name, pop);                 // labels name, pop, from the variables
row.pop;                                // 12 — rewritten to row.1 at compile time
row.1;                                  // 12

fn load() -> #(name: string, pop: i32) {
    return #("SP", 12);                 // labels come from the written return type
}
load().name;                            // "SP"

fn plain() -> #(string, i32) { … }
plain().name;                           // error: the written type has no label — use .0
```

- Construction never writes a label; an element that is a variable lends its name.
- A written type may carry labels; they are names for the compiler only.
- A tuple **is a tuple** at run time and prints positionally: `#("SP", 12)`.
- Labels never take part in type comparison: `#(name: string, pop: i32)` accepts `#(string, i32)`.
- In a pattern a tuple is positional: `case row { #("SP", p) { p } _ { 0 } }`.

## `case`, `is` and guards

```bp
// 1.0.2-beta
return case s {
    Circle(r) -> r * r;
    Square(side) -> side * side;
};

// 1.0.4-beta
return case s {
    Shape.Circle(r) { r * r }
    .Square(side) { side * side }
};
```

- An arm is `Pattern { body }`; `{ n -> body }` binds the whole matched value; the body's last
  expression is the arm's value; arms take no `;`.
- Guards: `Option.Some(value: v) when (v is string) { v.length }`.
- `_ { … }` is the catch-all — required unless no other value is possible; guarded arms never make a
  `case` exhaustive.
- `..` ignores the rest: `#(0, ..)`, `Shape.Rect(width: w, ..)`.
- `x is i32` tests the value (a float with an integral value in range is an `i32`, converted inside
  the block). *(The exact spelling of the 1.0.2 arms above is to verify when 06/12 land.)*

## `unknown` and unions

```bp
val data: unknown = json.parse(text);
if (data is string) { @print(data); };

val v = if (c) { 1 } else { "a" };      // i32 | string
case v {
    i32 { n -> n + 1 }
    string { s -> s.length }
}
```

Nothing leaves `unknown` or a union without `is` or a `case`; there is no `any`.

## Effects

```bp
// 1.0.2-beta
#[@result]
fn parse(s: string) -> i32 { … }

// 1.0.4-beta
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") { throw "empty"; };
    return 42;
}
```

The annotation and the wrapped return type go together: `#[@result]` ↔ `@Result<T, E>`,
`#[@future]` ↔ `@Future<T>`, `#[@iterator]` ↔ `@Iterator<T>`, `#[@asyncGenerator]` ↔
`@AsyncGenerator<T>`. `val assert Ok(n) = parse("42");` matches the result; after `catch` the value
is no longer a `@Result`.

## Loops

```bp
loop (xs) { x -> … }
loop (0..n) { i -> … }
loop (attempts < 3) { … }       // replaces while
loop { … break; }
```

## Printing

`@print` text is the same on every backend and shaped like the source: `[1, 2]`, `#(1, "a")`,
`Point(x: 1, y: 2)`, `Shape.Square(side: 4)`, `5.0` for an `f64`; a top-level string is printed bare,
a nested one quoted. A type implementing `behavior Display` prints its `display()`.

## Separators

- `,` separates data: fields, variants, tuple elements, arguments.
- The trailing comma picks the layout: none → compact on one line; present → one item per line.
- A `fn` definition is always printed open.
- Declarations and `case` arms are not separated by commas: `;` after a bodyless member, nothing
  after `}`.

## What does not change

- `implement`, `extends`, `default fn`, `declare fn`
- Construction: `Point(x: 1, y: 2)`, `Point(1, 2)`, `Shape.Circle(radius: 1.0)`
- Annotations `#[…]`
- Runtime representation of named records, enums and behaviors

## Diagnostics you will see

| You wrote | Error |
|---|---|
| `record Point { … }` | `removed-keyword-record` — use `type Point(fields) { methods }` |
| `enum Color { … }` | `removed-keyword-enum` — use `type Color { variants }` |
| `interface Printable { … }` | `removed-keyword-interface` — use `behavior Printable { … }` |
| `record { x: 1 }` | `removed-record-literal` — use `#(x)` or `#(1)` |
| `fn f(p: { x: i32 })` | `removed-record-type` — use `#(x: i32)` |
| `type P(x: i32) { A }` | `type-record-with-variants` |
| `type P(val x: i32)` | `type-field-val-prefix` |
| `fn f(self: Self) -> i32,` in a behavior | `member-comma-separator` |
| `fn get(b: Box) -> i32` | `Box` is generic and needs 1 type argument |
| `fn get(self: Self) -> T` in `type Box<T>` | `Self` needs its type arguments — write `Self<T>` |
| `while (c) { … }` | `while` does not exist — use `loop (c)` |
| `throw new Error("x")` | use `throw Error("x")` |
| `#[@result] fn f() -> i32` | `#[@result]` requires the return type `@Result<T, E>` |
| `row.name` where the type has no label | the written type has no label — use `row.N` |
| `#(x: 1)` | a tuple is built without labels — write `#(1)`, or label it in the destination type |

Error codes other than the first eight are sketches; the implementing fronts fix the wording.
