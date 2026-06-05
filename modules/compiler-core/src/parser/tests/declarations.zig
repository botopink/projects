//! parser: struct/record/enum/interface/implement, val/pub/fn (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: empty program" {
    try h.assertParser(std.testing.allocator, @src(), "");
}

test "parser: whitespace-only source" {
    try h.assertParser(std.testing.allocator, @src(), "   \t\n  ");
}

test "parser: empty interface" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface {}");
}

test "parser: interface with one field" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface { val color: string }");
}

test "parser: abstract method with 1 param (self: Self)" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface { fn draw(self: Self) }");
}

test "parser: abstract method with multiple params" {
    try h.assertParser(std.testing.allocator, @src(), "val Positionable = interface { fn moveTo(self: Self, x: i32, y: i32) }");
}

test "parser: interface with methods of varying param counts" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self)
        \\    fn drawLine(self: Self, x1: i32, y1: i32)
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string)
        \\}
    );
}

test "parser: full Drawable interface (field + abstract + default method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\}
    );
}

test "parser: empty struct" {
    try h.assertParser(std.testing.allocator, @src(), "val Account = struct {}");
}

test "parser: struct with one field" {
    try h.assertParser(std.testing.allocator, @src(), "val Account = struct { _balance: number = 0 }");
}

test "parser: struct with field and default" {
    try h.assertParser(std.testing.allocator, @src(), "val Config = struct { host: string = \"localhost\" }");
}

test "parser: struct with a simple getter" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\}
    );
}

test "parser: struct with a setter that throws" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Saldo nao pode ser negativo");
        \\    }
        \\}
    );
}

test "parser: setter with assign" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\}
    );
}

test "parser: struct with a fn method (deposit)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: full Account struct (private field + getter + setter + method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: struct with inline implement single interface" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val AuthState = struct implement Drawable {}
    );
}

test "parser: struct with inline implement builtin generic" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val AuthState = struct implement @Context<Element, AuthState> {}
    );
}

test "parser: struct with inline implement multiple interfaces" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Widget = struct implement Drawable, @Context<Element, Widget> {}
    );
}

test "parser: enum with inline implement" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Color = enum implement Printable { Red, Green, Blue }
    );
}

test "parser: record with inline implement" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Point = record implement Serializable { x: number, y: number }
    );
}

test "parser: empty record (no fields, no methods)" {
    try h.assertParser(std.testing.allocator, @src(), "val Point = record {}");
}

test "parser: record with two fields and no methods" {
    try h.assertParser(std.testing.allocator, @src(), "val Point = record { x: number, y: number }");
}

test "parser: record with one method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Point = record {
        \\    x: number,
        \\    fn show(self: Self) {
        \\        return self.x;
        \\    }
        \\}
    );
}

test "parser: full GPSCoordinates record (two fields + toString method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    pub fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "parser: record with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = record {
        \\    value: string,
        \\    declare fn foo(self: Self);
        \\}
    );
}

test "parser: struct with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self) {}
        \\    declare fn withdraw(self: Self) -> number;
        \\}
    );
}

test "parser: enum with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    declare fn label(self: Self) -> string;
        \\}
    );
}

test "parser: implement with one interface and one unqualified method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Myimplement = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\}
    );
}

test "parser: implement with two interfaces and qualified methods" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via USB. Bateria atual: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via Painel Solar. Bateria atual: " + self.batteryLevel);
        \\    }
        \\}
    );
}

test "parser: interface with multiple abstract methods (Canvas)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self),
        \\    fn drawLine(self: Self, x1: i32, y1: i32),
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string),
        \\}
    );
}

test "parser: struct with private field, getter, setter with throw, and method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Balance cannot be negative");
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: record with two fields and a toString method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "parser: implement single interface with method body" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("Drawing circle");
        \\    }
        \\}
    );
}

test "parser: implement two interfaces with qualified method disambiguation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        @print("Connected via USB. Battery level: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        @print("Connected via Solar Panel. Battery level: " + self.batteryLevel);
        \\    }
        \\}
    );
}

test "parser: implement shorthand named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\}
    );
}

test "parser: implement shorthand named pub" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\}
    );
}

test "parser: extend shorthand named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\PatoExtra extend Pato {
        \\    fn quack(self: Self) {}
        \\}
    );
}

test "parser: extend explicit named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val PatoExtra = extend Pato {
        \\    fn quack(self: Self) {}
        \\}
    );
}

test "parser: initWithSource stores the source" {
    var l = lexerMod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parserMod.Parser.initWithSource(tokens, "const x = 1");
    try std.testing.expect(p.source != null);
    try std.testing.expectEqualStrings("const x = 1", p.source.?);
}

test "parser: init has null source" {
    var l = lexerMod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parserMod.Parser.init(tokens);
    try std.testing.expect(p.source == null);
}

test "parser: reserved words are not identifier tokens" {
    const reservedWords = [_][]const u8{ "auto", "delegate", "echo", "implement", "macro", "derive" };
    for (reservedWords) |word| {
        var l = lexerMod.Lexer.init(word);
        const tokens = try l.scanAll(std.testing.allocator);
        defer l.deinit(std.testing.allocator);
        try std.testing.expect(tokens[0].kind != .identifier);
        try std.testing.expect(lexerMod.isReservedWord(tokens[0].kind));
    }
}

test "parser: enum ---- simple unit variants" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "parser: enum ---- with payload variant" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

test "parser: interface extends ---- val form single" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2 {}
    );
}

test "parser: interface extends ---- val form multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub val form multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- shorthand single" {
    try h.assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2 {}
    );
}

test "parser: interface extends ---- shorthand multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub shorthand multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub interface I1 extends T2, T3, T4 {}
    );
}

test "parser: annotation ---- fn no args" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[inline]
        \\fn greet() {}
    );
}

test "parser: annotation ---- fn with dot-ident arg" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\pub fn maxval() {}
    );
}

test "parser: annotation ---- fn multiple annotations" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\#[inline]
        \\fn compute() {}
    );
}

test "parser: annotation ---- val form fn" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val maxval = #[target(.erlang)] fn() {}
    );
}

test "parser: annotation ---- struct shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\struct Point {}
    );
}

test "parser: annotation ---- record shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[derive(Eq)]
        \\record Person { name: string }
    );
}

test "parser: annotation ---- enum shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.beam)]
        \\enum Color {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
    );
}

test "parser: annotation ---- interface shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\interface Printable {}
    );
}

test "parser: annotation block ---- at bracket" {
    try h.assertParser(std.testing.allocator, @src(),
        \\@[external(erlang, "string", "length"),
        \\  external(node, "./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn length(s: string) -> i32;
    );
}

test "parser: annotation block ---- external decl then next decl" {
    try h.assertParser(std.testing.allocator, @src(),
        \\@[external(erlang, "erlang", "abs")]
        \\pub declare fn absolute_value(n: i32) -> i32;
        \\
        \\fn main() {
        \\    absolute_value(-5);
        \\}
    );
}

test "parser: val local binding with case expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        val result = case x {
        \\            _ -> "ok";
        \\        };
        \\    }
        \\}
    );
}

test "parser: val top-level constant ---- integer" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val MAX = 100;
    );
}

test "parser: val top-level constant ---- comptime float mul" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val pi = comptime 3.14 * 2.0;
    );
}

test "parser: val top-level constant ---- comptime string concat" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val greeting = comptime "Hello, " + "World";
    );
}

test "parser: val top-level constant ---- comptime block" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val hash = comptime {
        \\    break 6364 + 11;
        \\};
    );
}

test "parser: pub fn ---- comptime params" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax bool param" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn check(cond comptime: syntax bool) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning generic" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn select<T, R>(lamb comptime: syntax fn(item: T) -> R) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning bool" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn where<T>(pred comptime: syntax fn(item: T) -> bool) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind no constraint" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn wrap(comptime T: type) -> type {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind single constraint" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn render(comptime tag: type string, props: i32) -> string {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind multiple pipe constraints" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    @todo();
        \\}
    );
}

test "parser: val top-level ---- call expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val box = wrap(int);
        \\val m = maxval(float);
    );
}

test "parser: empty array literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val xs = [];
    );
}

test "parser: val with array type annotation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "parser: val with tuple type annotation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "parser: test anonymous" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

test "parser: test named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test "addition works" {
        \\    val r = 2 + 3;
        \\    assert r == 5;
        \\}
    );
}

test "parser: test named with message assert" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test "map doubles" {
        \\    assert [2, 4, 6] == [2, 4, 6], "map should double each element";
        \\}
    );
}

test "parser: test rejects in fn body" {
    // `test` is a top-level declaration only.
    try h.expectParseFails(std.testing.allocator,
        \\fn run() {
        \\    test { assert true; }
        \\}
    );
}

test "parser: Expr builtin type ---- param and bounded return" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<Component> {
        \\    @todo();
        \\}
    );
}

test "parser: Expr builtin type ---- generic return" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn yaml<T>(comptime template: @Expr<string>) -> @Expr<T> {
        \\    @todo();
        \\}
    );
}

test "parser: Expr builtin type ---- composed type position" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn collect<T>(comptime first: ?@Expr<Element>) -> @Expr<T> {
        \\    @todo();
        \\}
    );
}
