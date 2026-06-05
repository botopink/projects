//! comptime: type & generic inference (split from tests.zig).

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

test "infer: type ---- arg satisfies single constraint" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn render(comptime tag: type string, props: i32) -> i32 {
        \\    return props;
        \\}
        \\val a = render("div", 1);
    );
}

test "infer: type ---- arg satisfies one of multiple constraints" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val s = coerce("s", 0);
        \\val i = coerce(7, 0);
        \\val b = coerce(true, 0);
    );
}

test "infer: type ---- no constraint accepts any type" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn id(comptime t: type, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val a = id("s", 0);
        \\val b = id(3.14, 0);
        \\val c = id(true, 0);
    );
}

test "infer: generic record Pair<A, B>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Pair = record <A, B> { first: A, second: B };
        \\val p = Pair(first: 42, second: "hello");
        \\@print(p);
    );
}

test "infer: generic record Triple<A, B, C>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Triple = record <A, B, C> { first: A, second: B, third: C };
        \\val t = Triple(first: 1, second: "x", third: 3.14);
    );
}

test "infer: generic struct Box<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = struct <T> {
        \\    value: T = todo,
        \\};
        \\val b = Box(42);
    );
}

test "infer: generic enum Option<T> ---- unit and payload variants" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    None,
        \\    Some(value: T),
        \\};
        \\val n = Option.None;
        \\val s = Option.Some(value: 42);
    );
}

test "infer: generic enum Result<T> with Ok and Err" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T> {
        \\    Ok(value: T),
        \\    Err(message: string),
        \\};
        \\pub fn isOk(r: Result) -> bool {
        \\    return true;
        \\}
        \\val r = Result.Ok(value: 42);
        \\val ok = isOk(r);
    );
}

test "infer: pub fn generic ---- identity<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\val r = identity(42);
    );
}

test "infer: pub fn generic with two type params<T, R>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn transform<T, R>(x: T, y: R) -> R {
        \\    return y;
        \\}
        \\val result = transform(42, "mapped");
    );
}

test "infer: generic interface Container<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Container = interface <T> {
        \\    fn fetch(self: Self) -> T;
        \\    fn store(self: Self, value: T);
        \\}
    );
}

test "infer: @Expr builtin type ---- declaration with bounded return typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn identity(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\fn main() {
        \\    @print("ok");
        \\}
    );
}
