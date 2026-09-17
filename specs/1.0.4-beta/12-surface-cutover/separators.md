# Deep dive — separators

> Carried from `1.0.3-beta/02-surface-cutover/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F4` and bare front numbers are 1.0.3-beta's numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Part of [front 03](./README.md). One rule for commas across `type`, `behavior` and tuples, and one
canonical output from the formatter.

## The rule

1. **A comma separates data items**: fields in a field list, variants, items of a section,
   elements of a tuple or array, arguments, generic parameters. A trailing comma is allowed.
2. **The trailing comma picks the layout** — the author decides, not the line width:
   - no comma after the last item → **compact**: the whole list on one line;
   - comma after the last item → **open**: one item per line, trailing comma kept.
   A `//` comment inside a list cannot sit on one line, so the formatter opens the list and adds
   the trailing comma. Annotations do not force anything (`(#[value("k")] host: string)` stays
   compact).
3. **A `fn` definition is always open.** A method body is never printed on one line, and a body
   (`type` or `behavior`) that holds any member — a method, a bodyless `fn`, a `val` field — is
   printed one member per line, whatever its variants or field list do. Only an empty body stays
   `{}`. Lambdas (`{ x -> x * 2 }`) are expressions, not definitions, and may stay compact.
4. **Declarations are not comma-separated.** A member that ends with `}` (a method with a body, a
   section) takes nothing after it. A member without a body — a bodyless `fn`, a `declare fn`, a
   `val` field of a behavior — ends with `;`.

```bp
pub behavior Request {
    val method: HttpMethod;
    val path: string;

    fn param(self: Self, name: string) -> string;
    declare fn body(self: Self) -> string;

    default fn isGet(self: Self) -> bool {
        return self.method == HttpMethod.Get;
    }
}

pub type Shape {
    Circle(radius: f64),
    Square(side: f64),

    pub fn area(self: Self) -> f64 {
        return 0.0;
    }
}

pub type Config(
    // where the server listens
    host: string = "0.0.0.0",
    port: i32,
)
```

## Today

- Behavior (interface) bodies accept `,`, `;` or nothing after a member (`parser/decls.zig:604,628`;
  `parseInterfaceMethod` matches an optional `;` at `:671`). `declare fn` requires `;` (`:717`).
- Real `.bp` sources (std, embedded prelude, the five libraries): signature lines end with `;` 157
  times, with no terminator 32 times (some of these are wrapped signatures), with `,` **zero** times. Zig test sources: `;` 39, `,` 20.
- Record and enum bodies use `,` after fields and variants; methods take nothing.
- emilia's sections (`emilia/src/tokens.bp:37`) take no comma after `}`.
- The formatter already keys layout on the trailing comma (`format.zig:722–788`, `:1634`, `:1746`).

The rule therefore codifies what the libraries already write; the only style that disappears is the
comma after a signature, used by the previous draft of this milestone and by 20 Zig tests.

## Parser

- In a behavior body, `,` after a member is `member-comma-separator` ("members end with `;`, not
  `,`"), with a fix-it.
- A bodyless `fn` member without `;` is `member-missing-semicolon` (up to 32 library sites,
  rewritten manually).
- In a `type` body, a `,` after a method is `member-comma-separator`.
- Case arms keep accepting `,` or `;` — out of scope here.

## Formatter

Canonical output, so two authors produce the same file:

- Field lists, variant lists, section items, tuples, arguments, generic arguments: rule 2.
- Bodies with members and every method body: rule 3.
- Bodyless members: `;`. Members with a body: no separator.
- One blank line between groups (fields/variants → methods; `val` fields → signatures → default
  methods) — groups are not reordered, only separated.
- Formatting is idempotent; `botopink format --check` fails on non-canonical separators.

## Acceptance

- [ ] `behavior B { fn f(self: Self) -> i32, }` → `member-comma-separator`
- [ ] `behavior B { fn f(self: Self) -> i32 }` → `member-missing-semicolon`
- [ ] `behavior B { val x: i32; fn f(self: Self) -> i32; default fn g(self: Self) -> i32 { return 1; } }` parses
- [ ] `format` of `type Point(x: i32, y: i32)` stays on one line, even past the line width
- [ ] `format` of `type Point(x: i32, y: i32,)` prints one field per line with the trailing comma
- [ ] `format` of a compact field list containing a `//` comment opens it and adds the trailing comma
- [ ] `format` of `type Color { Red, Green }` stays compact; `type Color { Red, Green, }` opens
- [ ] `format` of `type Shape { Circle(r: f64), pub fn area(self: Self) -> f64 { return 0.0; } }` prints the body open and the method body on its own lines
- [ ] `format` of `behavior Marker {}` stays `{}`; a behavior with one `fn` member is open
- [ ] `format` twice is a no-op on every file of `libs/std`
