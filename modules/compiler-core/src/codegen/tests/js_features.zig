//! codegen: lambda/enum/destructure/star/import/range/pipeline/hooks (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

test "js: star fn ---- async function with await" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
        \\*fn loadTwice(x: i32) -> @Future<i32> {
        \\    val a = await fetch(x);
        \\    return a + a;
        \\}
    );
}

test "js: star fn ---- generator with yield" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn counter() -> @Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\    yield 3;
        \\}
    );
}

test "js: star fn ---- async generator" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn stream() -> @AsyncIterator<i32, string> {
        \\    yield 1;
        \\    yield 2;
        \\}
    );
}

test "js: star fn ---- pub typedefs" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub *fn loadOne(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
        \\pub *fn count() -> @Iterator<i32> {
        \\    yield 1;
        \\}
        \\pub *fn pulses() -> @AsyncIterator<i32, string> {
        \\    yield 1;
        \\}
    );
}

test "js: enum ---- unit variants" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "js: enum ---- payload variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

test "js: enum ---- payload variants with method using variantFields case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    Triangle(base: f64, height: f64),
        \\    fn area(shape: Self) -> f64 {
        \\        return case shape {
        \\            Circle(radius) -> radius * radius * 3.14;
        \\            Square(side) -> side * side;
        \\            Triangle(base, height) -> base * height * 0.5;
        \\            _ -> 0.0;
        \\        };
        \\    }
        \\}
    );
}

test "js: enum ---- unit variants with method using ident case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val HttpMethod = enum {
        \\    Get,
        \\    Post,
        \\    Put,
        \\    Delete,
        \\    fn name(m: Self) -> string {
        \\        val label = case m {
        \\            Get -> "GET";
        \\            Post -> "POST";
        \\            Put -> "PUT";
        \\            _ -> "DELETE";
        \\        };
        \\        return label;
        \\    }
        \\}
    );
}

test "js: enum ---- mixed unit and payload with method using mixed case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Maybe = enum {
        \\    Nothing,
        \\    Just(value: string),
        \\    fn check(m: Self) -> string {
        \\        return case m {
        \\            Nothing -> "nothing";
        \\            Just(value) -> "just";
        \\        };
        \\    }
        \\}
    );
}

test "js: enum ---- method using qualified enum member" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Status = enum {
        \\    Active,
        \\    Inactive,
        \\    fn isDefault(s: Self) -> string {
        \\        val current = Status.Active;
        \\        return current;
        \\    }
        \\}
    );
}

test "js: import ---- named imports" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import { foo, bar };
    );
}

test "codegen ---- use object destructure state to useState" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val {count, setCount} = use state(0);
        \\    Element();
        \\}
    );
}

test "codegen ---- use tuple destructure state to useState" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val #(count, setCount) = use state(0);
        \\    Element();
        \\}
    );
}

test "codegen ---- use memo infers dependency array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn memo() -> @Context<Element, i32> {
        \\    0;
        \\}
        \\fn Counter() -> Element {
        \\    val {count, setCount} = use state(0);
        \\    val doubled = use memo { -> return count * 2; };
        \\    Element();
        \\}
    );
}

test "codegen ---- use effect void hook empty deps" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn cleanup() {
        \\    0;
        \\}
        \\fn effect() -> @Context<Element, i32> {
        \\    0;
        \\}
        \\fn Widget() -> Element {
        \\    use effect { -> cleanup(); };
        \\    Element();
        \\}
    );
}

test "codegen ---- inline implement context base erased at runtime" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn render() -> Element {
        \\    Element();
        \\}
    );
}

test "js: destructure ---- record val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, y } = p;
        \\    @print(x, y);
        \\    return x;
        \\}
    );
}

test "js: destructure ---- record val binding with spread" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32, z: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, .. } = p;
        \\    return x;
        \\}
    );
}

test "js: destructure ---- record parameter in fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Person { name: string, age: i32 }
        \\fn greet({ name, .. }: Person) -> string {
        \\    @print(name);
        \\    return name;
        \\}
    );
}

test "js: destructure ---- tuple val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn extract() {
        \\    val #(a, b) = #(12, "hello");
        \\    @print(a, b);
        \\}
    );
}

test "js: destructure ---- tuple parameter in fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

test "js: destructure ---- tuple var binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    var #(x, y) = #(10, 20);
        \\}
    );
}

test "js: destructure ---- tuple with long names" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn get_coordinates() -> #(f32, f32) {
        \\    return #(0.0, 0.0);
        \\}
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

test "js: destructure ---- tuple with try-catch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Error { msg: string }
        \\*fn fetch() -> @Result<#(i32, i32), Error> {
        \\    throw Error(msg: "boom");
        \\}
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "js: enum ---- shorthand declaration without val Name =" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\enum Direction {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "js: import ---- multi-module pub fn import" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "math", .source =
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        },
        .{ .path = "", .source =
        \\import {double} from "math";
        \\val result = double(21);
        },
    });
}

test "js: import ---- multi-module pub val import" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source =
        \\pub val PORT = 8080;
        \\pub val HOST = "localhost";
        },
        .{ .path = "", .source =
        \\import {PORT, HOST} from "config";
        \\val addr = HOST;
        \\val port = PORT;
        },
    });
}

test "js: pipeline ---- simple chain" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\    @print(result);
        \\}
    );
}

test "js: pipeline ---- with labeled args" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\    @print(result);
        \\}
    );
}

test "js: range ---- iterate over range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) -> i32 {
        \\    return loop (0..n) { i ->
        \\        yield i;
        \\    };
        \\}
    );
}

test "js: range ---- open-ended range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countUp(x: i32) {
        \\    loop (x..) { i ->
        \\        if (i > 100) {
        \\          break;
        \\        };
        \\    };
        \\}
    );
}

test "js: negation ---- simple unary minus" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn negate(x: i32) -> i32 {
        \\    return -x;
        \\}
        \\fn main() {
        \\    @print(negate(42));
        \\}
    );
}

test "js: negation ---- in expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn diff(x: i32, y: i32) -> i32 {
        \\    return x + -y;
        \\}
        \\fn main() {
        \\    @print(diff(10, 3));
        \\}
    );
}

test "js: enum ---- method with case on self" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    fn name() -> string {
        \\        case (self) {
        \\            Red -> "red";
        \\            Green -> "green";
        \\            Blue -> "blue";
        \\        };
        \\    }
        \\};
    );
}

test "js: lambda ---- with parameter" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(10);
        \\}
    );
}

test "js: lambda ---- multi-statement body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(5);
        \\}
    );
}

test "js: lambda ---- standalone with params" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val add = { x, y ->
        \\    x + y;
        \\};
        \\val result = add(10, 20);
        \\@print(result);
    );
}

test "js: lambda ---- with type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func: fn(string)-> string = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

test "js: lambda ---- multi param with type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> i32 {
        \\    val add: fn(i32,i32)-> i32 = {a, b ->
        \\        return a + b;
        \\    };
        \\    return add(10, 20);
        \\}
    );
}

test "js: lambda ---- simple standalone" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

test "js: lambda ---- full type annotation infers params" {
    // Before the `fn(...) -> ...` annotation was lowered to a `.func` type,
    // this failed to type-check (named-vs-func mismatch). It must now compile,
    // with `a`/`b` inferred as `i32` from the annotation.
    try h.assertJsContains(std.testing.allocator,
        \\val add: fn(i32, i32) -> i32 = { a, b -> a + b };
        \\val result = add(2, 3);
    , &.{
        "add(2, 3)",
    });
}

test "js: lambda ---- string-typed annotation infers params" {
    // A different element type proves the annotation (not just `+` defaulting)
    // drives param typing: `a`/`b` are `string` and the body concatenates them.
    try h.assertJsContains(std.testing.allocator,
        \\val join: fn(string, string) -> string = { a, b -> a + b };
        \\val r = join("x", "y");
    , &.{
        "join(",
    });
}

test "js: optional chaining ---- member access short-circuits null" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record User { name: string }
        \\
        \\fn main() {
        \\    val u: ?User = User(name: "ana");
        \\    @print(u?.name);
        \\}
    );
}

test "js: reserved word identifiers" {
    // JS reserved words used as botopink fn names, params, and locals must be
    // renamed on emission (`delete` → `delete_`, `with` → `with_`) — emitting
    // them verbatim is a SyntaxError that kills the whole module. The rename is
    // consistent across the decl, call sites, and the `exports.<name>` property
    // keeps the original botopink name.
    // `delete`/`with`/`class`/`static` are JS reserved words but valid botopink
    // identifiers (botopink keywords like `new`/`enum` are excluded by the
    // parser, so they can never reach codegen as user names).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn delete(with: string, class: string) -> string {
        \\    val static = with + class;
        \\    return static;
        \\}
        \\
        \\fn main() {
        \\    @print(delete("a", "b"));
        \\}
    );
}
