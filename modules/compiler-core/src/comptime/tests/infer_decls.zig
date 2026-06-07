//! comptime: pub fn/record/struct/interface/implement inference (split from tests.zig).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

test "infer: enum constructors" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
        \\val c1 = Color.Red;
        \\val c2 = Color.Rgb(r: 255, g: 0, b: 0);
        \\val c3: Color = .Red;
    );
}

test "infer: record constructor" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
        \\@print(p);
    );
}

test "infer: record with method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: f64,
        \\    lon: f64,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
        \\val g = GPSCoordinates(lat: 5.0, lon: 3.0);
    );
}

test "infer: struct constructor" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    count: i32 = 0,
        \\};
        \\val c = Counter(0);
    );
}

test "infer: struct with private field and method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: i32 = 0,
        \\    fn deposit(self: Self, amount: i32) {
        \\        self._balance += amount;
        \\    }
        \\};
        \\val a = Account(0);
    );
}

test "infer: pub fn basic ---- greet returns string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
        \\val msg = greet("world");
        \\@print(msg);
    );
}

test "infer: pub fn with local val binding in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn compute(x: i32) -> i32 {
        \\    val doubled = x + x;
        \\    @print(doubled);
        \\    return doubled;
        \\}
        \\val result = compute(21);
        \\@print(result);
    );
}

test "infer: pub fn with comptime params" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: i32) -> string {
        \\    @todo();
        \\}
        \\val r = repeat("hi", 3);
    );
}

test "infer: pub fn using enum + case in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
        \\pub fn label(d: Direction) -> string {
        \\    val result = case d {
        \\        North -> "N";
        \\        South -> "S";
        \\        East -> "E";
        \\        West -> "W";
        \\        _ -> "?";
        \\    };
        \\    @print(result);
        \\    return result;
        \\}
        \\val n = label(Direction.North);
        \\@print(n);
    );
}

test "infer: val with explicit type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x: i32 = 42;
        \\val y: f64 = 3.14;
        \\val msg: string = "hello";
    );
}

test "infer: val dependency chain" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = 10;
        \\val b = a + 5;
        \\val c = b + a;
    );
}

test "infer: dotIdent resolved from type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Blue,
        \\};
        \\val c: Color = .Red;
    );
}

test "infer: implement block is invisible to the binding list" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @todo();
        \\    }
        \\};
        \\val c = Circle(radius: 5.0);
    );
}

test "infer: interface with field and abstract method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\}
    );
}

test "infer: interface with multiple abstract methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self),
        \\    fn drawLine(self: Self, x1: i32, y1: i32),
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string),
        \\}
    );
}

test "infer: struct with private field, getter, setter and method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
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

test "infer: record with fields and toString method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "infer: implement single interface for record" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("Drawing circle");
        \\    }
        \\};
    );
}

test "infer: implement two interfaces with qualified methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val UsbCharger = interface {
        \\    fn Connect(self: Self),
        \\};
        \\val SolarCharger = interface {
        \\    fn Connect(self: Self),
        \\};
        \\val SmartCamera = record { batteryLevel: i32 };
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        @print("Connected via USB");
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        @print("Connected via Solar");
        \\    }
        \\};
    );
}

test "infer: doc comment on function" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// Adds two numbers
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\val result = add(1, 2);
    );
}

test "infer: doc comment on struct" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// A point in 2D space
        \\val Point = struct { x: i32, y: i32 };
    );
}

test "infer: activated extension method resolves" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\PatoNada*;
        \\val donald = Pato(1);
        \\val splash = donald.swim();
    );
}

test "infer: qualified extension call needs no activation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = PatoNada.swim(donald);
    );
}

test "infer: inherent record method is always available" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record Pato {
        \\    id: i32,
        \\    fn quack(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val noise = donald.quack();
    );
}

test "infer: var binding ---- mutable local inside fn" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn count() -> i32 {
        \\    var n = 0;
        \\    return n;
        \\}
        \\val r = count();
    );
}

test "infer: var binding ---- mutable string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet() -> string {
        \\    var msg = "hello";
        \\    return msg;
        \\}
        \\val r = greet();
    );
}

test "infer: pub val ---- infers same as private val" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val NAME = "botopink";
    );
}

test "infer: star fn ---- async returns @Future is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
    );
}

test "infer: star fn ---- generator returns @Iterator is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<i32> {
        \\    yield 1;
        \\}
    );
}

test "infer: test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\test "addition works" {
        \\    val r = add(2, 3);
        \\    assert r == 5;
        \\}
    );
}

test "infer: anonymous test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

test "infer: external ---- fn no body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@external(erlang, "string", "length"),
        \\  @external(node, "./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    val n = str_length("hi");
        \\}
    );
}

test "infer: std package ---- import binds namespace" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {bool} from "std";
        \\
        \\fn main() {
        \\    val a: bool = bool.negate(false);
        \\    val b: bool = bool.exclusiveOr(a, true);
        \\}
    );
}

test "infer: builtin result namespace ---- qualified calls typecheck" {
    try h.assertInfersOk(std.testing.allocator,
        \\*fn parse(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val doubled = result.map(parse(21), { x -> x * 2 });
        \\    val n: i32 = result.unwrap(doubled, 0);
        \\    val ok: bool = result.isOk(parse(n));
        \\}
    );
}

test "infer: @Option<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOption(x: @Option<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    @print(takeOption(3));
        \\}
    );
}

test "infer: @Optional<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOptional(x: @Optional<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    @print(takeOptional(3));
        \\}
    );
}
