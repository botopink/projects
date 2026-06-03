//! comptime: case exhaustiveness (+errors) (split from tests.zig).

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

test "exhaustiveness error: missing enum patterns" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\    }
        \\};
    );
}

test "exhaustiveness: all enum patterns covered" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}

test "exhaustiveness: wildcard covers remaining patterns" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        _ -> "other";
        \\    }
        \\};
    );
}

test "exhaustiveness error: missing string patterns (with wildcard)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val categorize = fn(s: string) -> string {
        \\    case s {
        \\        "hello" -> "greeting";
        \\    }
        \\};
    );
}

test "exhaustiveness: nested pattern matching" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T, E> {
        \\    Ok(value: T),
        \\    Err(error: E),
        \\};
        \\val unwrap_or = fn(r: Result<i32, string>, default: i32) -> i32 {
        \\    case r {
        \\        Ok(v) -> v,
        \\        Err(_) -> default,
        \\    }
        \\};
    );
}

test "exhaustiveness: or-pattern covers multiple variants" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val warm = fn(c: Color) -> bool {
        \\    case c {
        \\        Red | Green -> true;
        \\        Blue -> false;
        \\    }
        \\};
    );
}

test "exhaustiveness: guarded arm does not cover its variant" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Blue if false -> "blue";
        \\    }
        \\};
    );
}

test "exhaustiveness error: unreachable arm after wildcard" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        _ -> "other";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}

test "exhaustiveness error: duplicate variant arm" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\};
        \\val name = fn(c: Color) -> string {
        \\    case c {
        \\        Red -> "red";
        \\        Green -> "green";
        \\        Red -> "again";
        \\        Blue -> "blue";
        \\    }
        \\};
    );
}
