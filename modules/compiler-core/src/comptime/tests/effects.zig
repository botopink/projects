//! comptime: throw/context/@Result effect checking (split from tests.zig).

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

test "@Result: try unwraps Result to D" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record AppError { msg: string }
        \\*fn fetch() -> @Result<i32, AppError> {
        \\    throw AppError(msg: "fail");
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
    );
}

test "@Result: try propagates without catch" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record IoError { path: string }
        \\*fn load() -> @Result<string, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\*fn run() -> @Result<string, IoError> {
        \\    val s = try load();
        \\    return s;
        \\}
    );
}

test "@Result: multiple catch with different types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record UserError { msg: string }
        \\*fn getName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\*fn getAge() -> @Result<i32, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\fn loadUser() {
        \\    val name = try getName() catch "anon";
        \\    val age = try getAge() catch 0;
        \\}
    );
}

test "throw check: string matches declared E = string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn parse(s: string) -> @Result<i32, string> {
        \\    if (s == "") {
        \\        throw "empty input";
        \\    }
        \\    return 0;
        \\}
    );
}

test "throw check: record matches declared E = ErrorRecord" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record AppError { code: i32, msg: string }
        \\*fn load() -> @Result<string, AppError> {
        \\    throw AppError(code: 500, msg: "boom");
        \\}
    );
}

test "throw check: throw inside catch handler checks enclosing fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch() -> @Result<i32, string> {
        \\    throw "primary";
        \\}
        \\*fn process() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "secondary";
        \\    return r;
        \\}
    );
}

test "throw check: multiple throw sites all match E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn validate(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) {
        \\        throw "negative";
        \\    }
        \\    if (n > 100) {
        \\        throw "too big";
        \\    }
        \\    return n;
        \\}
    );
}

test "throw check: throw inside nested fn does not check outer fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn outer() -> @Result<i32, string> {
        \\    val cb = fn() {
        \\        throw 404;
        \\    };
        \\    throw "outer error";
        \\}
    );
}

test "throw check error: type mismatch i32 thrown but E = string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn parse(s: string) -> @Result<i32, string> {
        \\    throw 404;
        \\}
    );
}

test "throw check error: throw without enclosing Result return type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn run() -> i32 {
        \\    throw "x";
        \\}
    );
}

test "context: use with binding in @Context fn passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn useThing() -> @Context<Element, i32> {
        \\    val x = use state(0);
        \\    state(0);
        \\}
    );
}

test "context: use void hook with discard binding passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn effect(cb: i32) -> @Context<Element, i32> {
        \\    cb;
        \\}
        \\fn comp() -> @Context<Element, i32> {
        \\    use effect(0);
        \\    effect(0);
        \\}
    );
}

test "context: struct implement @Context resolved via inline impl passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val n = use state(0);
        \\    Element();
        \\}
    );
}

test "context: custom hook propagates ContextBase transitively passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\val AuthState = struct implement @Context<Element, AuthState> {
        \\    loggedIn: bool
        \\}
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn useAuth() -> AuthState {
        \\    val t = use state(0);
        \\    AuthState(loggedIn: true);
        \\}
        \\fn Dashboard() -> Element {
        \\    val {loggedIn} = use useAuth();
        \\    Element();
        \\}
    );
}

test "context error: use in fn returning string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn bad() -> string {
        \\    val x = use state(0);
        \\    "hi";
        \\}
    );
}

test "context error: ContextBase mismatch Element vs Http" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn connection() -> @Context<Http, i32> {
        \\    0;
        \\}
        \\fn bad() -> @Context<Element, i32> {
        \\    val c = use connection();
        \\    state(0);
        \\}
    );
}

test "context error: struct without @Context impl used with use" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Plain = struct { x: i32 }
        \\fn make() -> Plain {
        \\    Plain(x: 0);
        \\}
        \\fn comp() -> @Context<Element, i32> {
        \\    val p = use make();
        \\    0;
        \\}
    );
}
