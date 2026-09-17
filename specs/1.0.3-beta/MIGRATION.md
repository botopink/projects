# Migrating to 1.0.3-beta

1.0.3-beta is a hard cutover: the old spellings are parse errors, with a diagnostic that names the
replacement. Migration is manual (beta phase).

## Keywords

| 1.0.2-beta | 1.0.3-beta |
|---|---|
| `record Name { fields, methods }` | `type Name(fields) { methods }` |
| `enum Name { variants, methods }` | `type Name { variants, methods }` |
| `interface Name { … }` | `behavior Name { … }` |
| `record { x: 1 }` (value) | `#(x: 1)` — labeled tuple |
| `{ x: i32 }` (type) | `#(x: i32)` — labeled tuple type |
| `record { }` / `{}` | `#()` |
| `auto`, `derive`, `get`, `macro`, `opaque`, `private`, `set` | ordinary identifiers |
| `get name(self: Self) -> T` (accessor in `.d.bp`) | `fn name(self: Self) -> T;` |

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

// 1.0.3-beta
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

## Labeled tuples

```bp
val p = #(x: 10, y: 20);
p.x;    // 10
p._1;   // 20

fn origin() -> #(x: i32, y: i32) {
    return #(x: 0, y: 0);
}
```

- A labeled tuple **is a tuple** at runtime: `[10, 20]` in JavaScript, `{10, 20}` in Erlang. Printing
  it shows the elements, not the labels.
- Labels and order are part of the type: `#(x: i32, y: i32)` ≠ `#(y: i32, x: i32)`.
- A labeled tuple is accepted where the plain tuple `#(i32, i32)` is expected; the reverse needs a
  literal.
- A label cannot be read through an unbounded generic `T` or `any`.

## Separators

- `,` separates data: fields, variants, tuple elements, arguments.
- The trailing comma picks the layout: none → compact on one line; present → one item per line.
- A `fn` definition is always printed open.
- Declarations are not separated by commas: `;` after a bodyless member, nothing after `}`.

## What does not change

- `implement`, `extends`, `default fn`, `declare fn`
- Construction: `Point(x: 1, y: 2)`, `Point(1, 2)`, `Shape.Circle(radius: 1.0)`
- `case` patterns, generics, annotations `#[…]`, effects
- Runtime representation of named records, enums and behaviors

## Diagnostics you will see

| You wrote | Error |
|---|---|
| `record Point { … }` | `removed-keyword-record` — use `type Point(fields) { methods }` |
| `enum Color { … }` | `removed-keyword-enum` — use `type Color { variants }` |
| `interface Printable { … }` | `removed-keyword-interface` — use `behavior Printable { … }` |
| `record { x: 1 }` | `removed-record-literal` — use `#(x: 1)` |
| `fn f(p: { x: i32 })` | `removed-record-type` — use `#(x: i32)` |
| `type P(x: i32) { A }` | `type-record-with-variants` |
| `type P(val x: i32)` | `type-field-val-prefix` |
| `fn f(self: Self) -> i32,` in a behavior | `member-comma-separator` |
| `#(x: 1, 2)` | `tuple-mixed-labels` |
