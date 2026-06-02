/// Type system tests for the botopink compiler.
///
/// Two values of tests:
///   1. AST snapshots ---- validate inferred AST structure via `assertTypeAst`.
///   2. Error snapshots ---- verify type error messages via `assertTypeErrorSnap`.
const std = @import("std");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const snapMod = @import("../utils/snap.zig");
const prettyMod = @import("../utils/pretty.zig");
const T = @import("./types.zig");
const envMod = @import("env.zig");
const inferMod = @import("infer.zig");
const comptimeMod = @import("../comptime.zig");
const errorMod = @import("error.zig");
const snapshot = @import("snapshot.zig");
const Module = @import("../module.zig").Module;
const format = @import("../format.zig");

const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;

fn slugify(comptime s: []const u8) []const u8 {
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true;
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1;
                sep = true;
            }
        }
        if (sep and count > 0) count -= 1;
        break :blk count;
    };
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

fn buildRootPathFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const slug = comptime slugFromSrc(loc);
    return comptime std.fmt.comptimePrint(".botopinkbuild/comptime/{s}", .{slug});
}

// ── assertTypeAst ---- validate AST structure via JSON snapshots ───────────────

/// Validate the AST structure of inferred types via JSON snapshots.
///
/// Produces a multi-section snapshot for each module:
///   ----- SOURCE CODE -- name.bp
///   <source code>
///
///   ----- TYPED AST JSON -- name.json
///   <JSON array of binding representations>
///
/// For `val` bindings whose value is a `case` expression the JSON captures
/// the full case structure:
///   `{ "ast": "case", "param": "<subject_type>", "match": [...], "returnType": "..." }`
/// For all other bindings the JSON captures:
///   `{ "ast": "val", "returnType": "..." }` or `{ "ast": "fn_def", ... }`
fn assertComptimeAst(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    const io = std.testing.io;
    const runtimes = [_]comptimeMod.ComptimeRuntime{ .node, .erlang, .wasm, .beam };
    const base_slug = comptime slugFromSrc(loc);

    for (runtimes) |runtime| {
        var build_root_buf: [512]u8 = undefined;
        const build_root_path = try std.fmt.bufPrint(&build_root_buf, ".botopinkbuild/comptime/{s}", .{base_slug});

        var session = try comptimeMod.compile(allocator, modules, io, runtime, build_root_path);
        defer session.deinit(allocator);

        // Collect outputs
        var outputs = std.ArrayList(comptimeMod.ComptimeOutput).empty;
        defer outputs.deinit(allocator);

        for (session.outputs.items) |output| {
            try outputs.append(allocator, output);
        }

        // Save snapshots in separate directories per runtime
        const runtime_path = switch (runtime) {
            .node => "comptime/node",
            .erlang => "comptime/erlang",
            .wasm => "comptime/wasm",
            .beam => "comptime/beam",
        };
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "{s}/{s}", .{ runtime_path, base_slug });
        try snapshot.assertComptimeAstWithPath(allocator, snap_slug, outputs.items);
    }
}

/// Convenience wrapper for single-module AST validation.
fn assertComptimeAstSingle(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertComptimeAst(allocator, loc, &.{.{ .path = "", .source = src }});
}

// ── assertTypeErrorSnap ---- snapshot the type error message ────────────────────

/// Returns the text of the `line`-th line (1-based) in `src`.
fn getSourceLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return src[start..end];
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return src[start..];
}

/// Render a TypeError as a Gleam-style diagnostic string.
/// Caller owns the returned slice (allocated from `allocator`).
fn renderTypeError(
    allocator: std.mem.Allocator,
    src: []const u8,
    err: errorMod.TypeError,
) ![]u8 {
    // Use an arena so intermediate allocPrint strings are freed together.
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const tmp = arena.allocator();

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // ----- SOURCE CODE section
    try out.appendSlice(allocator, "----- SOURCE CODE\n");
    try out.appendSlice(allocator, src);
    if (src.len > 0 and src[src.len - 1] != '\n') try out.append(allocator, '\n');
    try out.appendSlice(allocator, "\n----- ERROR\n");

    // Error title
    const title = switch (err.kind) {
        .typeMismatch => "type mismatch",
        .unboundVariable => "unbound variable",
        .arityMismatch => "arity mismatch",
        .unknownField => "unknown field",
        .notARecord => "not a record type",
        .recursiveType => "recursive type",
        .unknownTypeName => "unknown type",
        .missingField => "missing field",
        .methodNotActive => "method not active",
        .ambiguousExtension => "ambiguous extension method",
        .notAnExtension => "not an extension symbol",
        .useNotAllowed => "`use` not allowed",
        .useNotContext => "`use` requires @Context",
        .contextMismatch => "ContextBase mismatch",
        .throwWithoutResult => "throw outside @Result",
        .missingMethod => "missing interface method",
        .unknownMethod => "unknown method",
        .unknownInterface => "unknown interface",
        .ambiguousMethod => "ambiguous method",
        .typeparamConstraint => "typeparam constraint not satisfied",
        .tryOnNonResult => "try on non-Result",
        .custom => |c| c.message,
    };
    try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "error: {s}\n", .{title}));

    // Location box if available
    if (err.loc) |errLoc| {
        const lineText = getSourceLine(src, errLoc.line);
        const col0 = if (errLoc.col > 0) errLoc.col - 1 else 0;
        // ┌─ :line:col
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "  \u{250c}\u{2500} :{d}:{d}\n",
            .{ errLoc.line, errLoc.col },
        ));
        // │
        try out.appendSlice(allocator, "  \u{2502}\n");
        // N │ source line
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "{d} \u{2502} {s}\n",
            .{ errLoc.line, lineText },
        ));
        // │ spaces^
        try out.appendSlice(allocator, "  \u{2502} ");
        for (0..col0) |_| try out.append(allocator, ' ');
        try out.appendSlice(allocator, "^\n");
    }

    // Error details
    switch (err.kind) {
        .typeMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  expected: {s}\n  found:    {s}\n",
                .{ try snapshot.typeNameOf(tmp, m.expected), try snapshot.typeNameOf(tmp, m.got) },
            ));
        },
        .unboundVariable => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not in scope\n",
                .{name},
            ));
        },
        .arityMismatch => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' expected {d} argument(s), got {d}\n",
                .{ a.name, a.expected, a.got },
            ));
        },
        .unknownField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .notARecord => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not a record or struct type\n",
                .{name},
            ));
        },
        .recursiveType => {
            try out.appendSlice(allocator, "\n  type variable would reference itself (infinite type)\n");
        },
        .unknownTypeName => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  the type '{s}' is not defined in this scope\n",
                .{name},
            ));
        },
        .missingField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' requires field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .methodNotActive => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no active method '{s}'\n  hint: activate the extension with `{s}*`\n",
                .{ m.typeName, m.method, m.hintSym },
            ));
        },
        .ambiguousExtension => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}.{s}' is provided by both '{s}' and '{s}'\n  hint: qualify the call, e.g. `{s}.{s}(obj)`\n",
                .{ a.typeName, a.method, a.symA, a.symB, a.symA, a.method },
            ));
        },
        .notAnExtension => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not name an implement/extend symbol\n",
                .{name},
            ));
        },
        .useNotAllowed => |returnType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function returns `{s}` which does not implement @Context\n",
                .{returnType},
            ));
        },
        .useNotContext => |exprType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `{s}` does not implement @Context — `use` requires @Context<_, _>\n",
                .{exprType},
            ));
        },
        .contextMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function returns @Context<{s}, _>\n  but the `use` expression returns @Context<{s}, _>\n",
                .{ m.fnBase, m.useBase },
            ));
        },
        .throwWithoutResult => {
            try out.appendSlice(allocator, "\n  'throw' requires the enclosing fn to return '@Result<D, E>'\n");
        },
        .missingMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not implement '{s}' required by interface '{s}'\n",
                .{ m.typeName, m.method, m.interfaceName },
            ));
        },
        .unknownMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not declared in any interface implemented for '{s}'\n",
                .{ m.method, m.typeName },
            ));
        },
        .unknownInterface => |u| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not an interface implemented here (method '{s}')\n",
                .{ u.qualifier, u.method },
            ));
        },
        .ambiguousMethod => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is declared by both '{s}' and '{s}' — qualify it\n",
                .{ a.method, a.interfaceA, a.interfaceB },
            ));
        },
        .typeparamConstraint => |c| {
            const gotName = try snapshot.typeNameOf(tmp, c.got);
            var list: std.ArrayList(u8) = .empty;
            for (c.constraints, 0..) |name, i| {
                if (i > 0) try list.appendSlice(tmp, ", ");
                try list.appendSlice(tmp, name);
            }
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has type '{s}', which does not satisfy 'typeparam {s}'\n",
                .{ c.paramName, gotName, list.items },
            ));
        },
        .tryOnNonResult => |ty| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `try` requires a @Result<D, E> value, found '{s}'\n",
                .{try snapshot.typeNameOf(tmp, ty)},
            ));
        },
        .custom => |c| {
            if (c.hint) |h| {
                try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "\n  hint: {s}\n", .{h}));
            }
        },
    }

    return try out.toOwnedSlice(allocator);
}

/// Parse `src`, expect inference to fail, snapshot the error description.
fn assertTypeErrorSnap(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;

    const desc = try renderTypeError(allocator, src, err);
    defer allocator.free(desc);

    const base_slug = comptime slugFromSrc(loc);

    // Save the same error snapshot in both node/errors/ and erlang/errors/
    // Error messages are runtime-agnostic (type inference happens before codegen)
    const runtimes = [_][]const u8{ "node", "erlang" };
    for (runtimes) |runtime| {
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "comptime/{s}/errors/{s}", .{ runtime, base_slug });
        try snapMod.checkText(allocator, snap_slug, desc);
    }
}

/// Parse `src` and assert inference succeeds (no type error). Inference-only:
/// no codegen runs, which keeps capability checks (e.g. @Context `use`,
/// typeparam constraints) isolated from backend concerns.
fn assertInfersOk(
    allocator: std.mem.Allocator,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    _ = inferMod.inferProgram(&env, program) catch |err| {
        if (env.lastError) |te| {
            const desc = try renderTypeError(allocator, src, te);
            defer allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        }
        return err;
    };
}

// ── typeparam constraint inference ──────────────────────────────────────────────

test "infer: typeparam ---- arg satisfies single constraint" {
    try assertInfersOk(std.testing.allocator,
        \\fn render(comptime tag: typeparam string, props: i32) -> i32 {
        \\    return props;
        \\}
        \\val a = render("div", 1);
    );
}

test "infer: typeparam ---- arg satisfies one of multiple constraints" {
    try assertInfersOk(std.testing.allocator,
        \\fn coerce(comptime v: typeparam string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val s = coerce("s", 0);
        \\val i = coerce(7, 0);
        \\val b = coerce(true, 0);
    );
}

test "infer: typeparam ---- no constraint accepts any type" {
    try assertInfersOk(std.testing.allocator,
        \\fn id(comptime t: typeparam, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val a = id("s", 0);
        \\val b = id(3.14, 0);
        \\val c = id(true, 0);
    );
}

test "infer error: typeparam ---- arg violates constraint" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn coerce(comptime v: typeparam string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val bad = coerce(3.14, 0);
    );
}

// ── inference tests ───────────────────────────────────────────────────────────

test "infer: integer and float literals" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = 42;
        \\val y = 3.14;
        \\@print(x, y);
    );
}

test "infer: string literal" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
        \\@print(greeting);
    );
}

test "infer: binary operators" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val sum = 1 + 2;
        \\val product = 3.0 * 2.0;
        \\val joined = "a" + "b";
        \\@print(sum, product, joined);
    );
}

test "infer: local binding inside comptime" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val hash = comptime { break 6364 + 11; };
    );
}

test "infer: enum constructors" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
        \\val c1 = Color.Red;
        \\val c2 = Color.Rgb(r: 255, g: 0, b: 0);
        \\val c3: Color = .Red;
    );
}

// ── records ───────────────────────────────────────────────────────────────────

test "infer: record constructor" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
        \\@print(p);
    );
}

test "infer: generic record Pair<A, B>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Pair = record <A, B> { first: A, second: B };
        \\val p = Pair(first: 42, second: "hello");
        \\@print(p);
    );
}

test "infer: record with method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

test "infer: generic record Triple<A, B, C>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Triple = record <A, B, C> { first: A, second: B, third: C };
        \\val t = Triple(first: 1, second: "x", third: 3.14);
    );
}

// ── structs ───────────────────────────────────────────────────────────────────

test "infer: struct constructor" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    count: i32 = 0,
        \\};
        \\val c = Counter(0);
    );
}

test "infer: struct with private field and method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: i32 = 0,
        \\    fn deposit(self: Self, amount: i32) {
        \\        self._balance += amount;
        \\    }
        \\};
        \\val a = Account(0);
    );
}

test "infer: generic struct Box<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = struct <T> {
        \\    value: T = todo,
        \\};
        \\val b = Box(42);
    );
}

// ── generic enums ─────────────────────────────────────────────────────────────

test "infer: generic enum Option<T> ---- unit and payload variants" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    None,
        \\    Some(value: T),
        \\};
        \\val n = Option.None;
        \\val s = Option.Some(value: 42);
    );
}

test "infer: generic enum Result<T> with Ok and Err" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

// ── case expressions ──────────────────────────────────────────────────────────

test "infer: case on enum variants ---- all arms return string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
        \\val subject = Color.Red;
        \\val label = case subject {
        \\    Red -> "red";
        \\    Green -> "green";
        \\    Blue -> "blue";
        \\    _ -> "other";
        \\};
    );
}

test "infer: case on integer with wildcard" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val desc = case 42 {
        \\    0 -> "zero";
        \\    _ -> "nonzero";
        \\};
        \\@print(desc);
    );
}

test "infer: case with OR patterns" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _ -> "odd";
        \\};
        \\@print(parity);
    );
}

test "infer: case with variant field bindings ---- body does not use bound vars" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    Point,
        \\}
        \\val s = Shape.Point;
        \\val label = case s {
        \\    Circle(radius) -> "circle";
        \\    Square(side)   -> "square";
        \\    Point          -> "point";
        \\    _           -> "other";
        \\};
    );
}

// ── pub fn ────────────────────────────────────────────────────────────────────

test "infer: pub fn basic ---- greet returns string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
        \\val msg = greet("world");
        \\@print(msg);
    );
}

test "infer: pub fn generic ---- identity<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\val r = identity(42);
    );
}

test "infer: pub fn with local val binding in body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: i32) -> string {
        \\    @todo();
        \\}
        \\val r = repeat("hi", 3);
    );
}

test "infer: pub fn generic with two type params<T, R>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn transform<T, R>(x: T, y: R) -> R {
        \\    return y;
        \\}
        \\val result = transform(42, "mapped");
    );
}

test "infer: pub fn using enum + case in body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

// ── val declarations ──────────────────────────────────────────────────────────

test "infer: val with explicit type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x: i32 = 42;
        \\val y: f64 = 3.14;
        \\val msg: string = "hello";
    );
}

test "infer: val dependency chain" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = 10;
        \\val b = a + 5;
        \\val c = b + a;
    );
}

test "infer: lt comparison returns bool" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val less = 1 < 2;
        \\val bigger = 10 < 5;
    );
}

test "infer: dotIdent resolved from type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Blue,
        \\};
        \\val c: Color = .Red;
    );
}

test "infer comptime: expressions of multiple types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val pi      = comptime 3.14 * 2.0;
        \\val maxVal  = comptime 100 + 1;
        \\val banner  = comptime "Hello, " + "World";
    );
}

// ── implement (produces no binding) ──────────────────────────────────────────

test "infer: generic interface Container<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Container = interface <T> {
        \\    fn fetch(self: Self) -> T;
        \\    fn store(self: Self, value: T);
        \\}
    );
}

test "infer: implement block is invisible to the binding list" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

// ── interface: full structures ───────────────────────────────────────────────

test "infer: interface with field and abstract method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\}
    );
}

test "infer: interface with multiple abstract methods" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self),
        \\    fn drawLine(self: Self, x1: i32, y1: i32),
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string),
        \\}
    );
}

// ── struct: full with getter/setter/method ──────────────────────────────────

test "infer: struct with private field, getter, setter and method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

// ── record: with fields and method ──────────────────────────────────────────

test "infer: record with fields and toString method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

// ── implement: interface for record ─────────────────────────────────────────

test "infer: implement single interface for record" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

// ── Phase 3: implement / interface semantic validation (errors) ──────────────

test "infer error: implement missing a required interface method" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\    fn erase(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: implement method not declared in the interface" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\    fn explode(self: Self) {
        \\        @print("boom");
        \\    }
        \\};
    );
}

test "infer error: implement qualified prefix is not a declared interface" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn Renderable.draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: duplicate method across interfaces without qualification" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val UsbCharger = interface {
        \\    fn connect(self: Self),
        \\};
        \\val SolarCharger = interface {
        \\    fn connect(self: Self),
        \\};
        \\val Camera = record { battery: i32 };
        \\val CameraCharger = implement UsbCharger, SolarCharger for Camera {
        \\    fn connect(self: Self) {
        \\        @print("connect");
        \\    }
        \\};
    );
}

test "infer error: getter return type mismatch with field type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    balance: i32 = 0,
        \\    get balance(self: Self) -> string {
        \\        return "nope";
        \\    }
        \\};
    );
}

test "infer error: setter value type mismatch with field type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    balance: i32 = 0,
        \\    set balance(self: Self, value: string) {
        \\        self.balance = value;
        \\    }
        \\};
    );
}

// ── logical operators ────────────────────────────────────────────────────────

test "infer: logical and returns bool" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = true && false;
    );
}

test "infer: logical or returns bool" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = true || false;
    );
}

test "infer: logical not returns bool" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = !true;
    );
}

test "infer: chained logical operators" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = true && false || true;
    );
}

test "infer: logical not with parens" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = !(true && false);
    );
}

test "infer error: type mismatch ---- non-bool lhs with &&" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 1 && true;
    );
}

test "infer error: type mismatch ---- non-bool rhs with ||" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = true || 0;
    );
}

test "infer error: type mismatch ---- non-bool with !" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = !42;
    );
}

test "infer: doc comment on function" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// Adds two numbers
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\val result = add(1, 2);
    );
}

test "infer: doc comment on struct" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// A point in 2D space
        \\val Point = struct { x: i32, y: i32 };
    );
}

// ── error cases ───────────────────────────────────────────────────────────────

// type mismatch ───────────────────────────────────────────────────────────────

test "infer error: type mismatch ---- i32 + bool" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 1 + true;
    );
}

test "infer: concat with i32 rhs ---- coerces to string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = "hello" + 42;
    );
}

test "infer: concat with i32 lhs ---- coerces to string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = 1 + "hello";
    );
}

test "infer error: type mismatch ---- mul with non-numeric" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 3.14 * "oops";
    );
}

test "infer error: type mismatch ---- function argument wrong type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn double(x: i32) -> i32 {
        \\    @todo();
        \\}
        \\val bad = double("hello");
    );
}

test "infer error: type mismatch ---- val annotation mismatch" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x: string = 42;
    );
}

test "infer: case arms with different types ---- string | i32 union" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> "zero";
        \\    _ -> 1;
        \\};
    );
}

test "infer: case arms with same type ---- no union" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val label = case 42 {
        \\    0 -> "zero";
        \\    1 -> "one";
        \\    _ -> "many";
        \\};
    );
}

test "infer: case arms three distinct types ---- union of three" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = case 0 {
        \\    0 -> "zero";
        \\    1 -> 42;
        \\    _ -> 3.14;
        \\};
    );
}

// arity mismatch ──────────────────────────────────────────────────────────────

test "infer error: arity mismatch ---- too many arguments" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "hi";
        \\}
        \\val bad = greet("a", "extra");
    );
}

test "infer error: arity mismatch ---- too few arguments" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    @todo();
        \\}
        \\val bad = add(1);
    );
}

test "infer error: arity mismatch ---- zero-param function called with argument" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hello() -> string {
        \\    @todo();
        \\}
        \\val bad = hello(42);
    );
}

// unbound variable ────────────────────────────────────────────────────────────

test "infer error: unbound variable ---- undefined identifier" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedIdent;
    );
}

test "infer error: unbound variable ---- undefined function call" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedFn(42);
    );
}

test "infer error: not a record ---- destructure val binding on primitive" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn describe(x: i32) -> string {
        \\    val { result } = x;
        \\    return result;
        \\}
    );
}

// ── arrays and tuples ─────────────────────────────────────────────────────────

test "types: array literal infers element type" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "types: val with array type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "types: array ---- prepend with empty array" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list1 = [1, ..[]];
    );
}

test "types: array ---- prepend with single element array" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list2 = [1, 2, ..[3]];
    );
}

test "types: array ---- prepend with multiple elements array" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "types: assert ---- simple assertion" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "types: assert ---- with arithmetic comparison" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "types: assert ---- with message" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "error message";
        \\}
    );
}

test "types: assert ---- array equality" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "types: assert pattern ---- with catch throw" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "types: assert pattern ---- with catch default value" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "types: assert pattern ---- with string literal" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "types: assert pattern ---- with number literal" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "types: assert pattern ---- with enum variant" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "types: assert pattern ---- with empty list" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "types: assert pattern ---- with multiple element list" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "types: assert pattern ---- with list and rest" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "types: tuple literal infers element types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "types: tuple destructuring binds variables" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn extract() {
        \\    val #(first, second) = #(1, "hello");
        \\}
    );
}

test "types: val with tuple type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "types: tuple literal with mixed types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #(12, "5452");
    );
}

// ── assertTypeAst: multi-module (import … from "name") ───────────────────────

test "assertTypeAst: single module ---- basic val bindings" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "", .source =
        \\val x = 42;
        \\val name = "alice";
        },
    });
}

test "assertTypeAst: import single val from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "constants", .source =
        \\pub val MAX = 100;
        },
        .{ .path = "", .source =
        \\import {MAX} from "constants";
        \\val limit = MAX;
        },
    });
}

test "assertTypeAst: import multiple vals from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source =
        \\pub val host = "localhost";
        \\pub val port = 8080;
        },
        .{ .path = "", .source =
        \\import {host, port} from "config";
        \\val addr = host;
        \\val p = port;
        },
    });
}

test "assertTypeAst: import fn from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
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

test "assertTypeAst: three-level chain ---- a imports b, b imports c" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "base", .source =
        \\pub val VERSION = 1;
        },
        .{ .path = "mid", .source =
        \\import {VERSION} from "base";
        \\pub val MAJOR = VERSION;
        },
        .{ .path = "", .source =
        \\import {MAJOR} from "mid";
        \\val v = MAJOR;
        },
    });
}

test "infer error: import of val ---- unbound variable" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {SECRET};
        \\val x = SECRET;
    );
}

// ── static extension dispatch (F6) ──────────────────────────────────────────────

test "infer error: extension method not active ---- hint to activate" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
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
        \\val r = donald.swim();
    );
}

test "infer error: extension method ambiguous ---- two activated impls" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\val Diver = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val PatoFundo = implement Diver for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\PatoNada*;
        \\PatoFundo*;
        \\val donald = Pato(1);
        \\val r = donald.swim();
    );
}

test "infer error: activation of non-extension symbol" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record Pato { id: i32 }
        \\Pato*;
    );
}

test "infer error: implement declares method not in interface" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\    fn fly(self: Self) {
        \\        return self.id;
        \\    }
        \\}
    );
}

test "infer: activated extension method resolves" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

test "assertTypeAst: unused dependency does not pollute main bindings" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "unused", .source =
        \\val secret = "hidden";
        },
        .{ .path = "", .source =
        \\val answer = 42;
        },
    });
}

test "assertTypeAst: import record constructor from dependency" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "models", .source =
        \\record Point { x: i32, y: i32 }
        },
        .{ .path = "", .source =
        \\import {Point} from "models";
        \\val origin = Point(0, 0);
        },
    });
}

// ── optional types ────────────────────────────────────────────────────────────

test "infer: null literal ---- type is optional<?>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = null;
    );
}

test "infer: optional annotation ---- ?string val" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val msg: ?string = null;
    );
}

test "infer: optional annotation ---- ?i32 val with null" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val count: ?i32 = null;
    );
}

// ── if expression ─────────────────────────────────────────────────────────────

test "infer: if expression ---- result type from then branch" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    return r;
        \\}
        \\val s = sign(1);
    );
}

test "infer: if expression ---- with else branch" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return if (n > 0) { "positive"; } else { "non-positive"; };
        \\}
        \\val s = describe(5);
    );
}

// ── var binding ───────────────────────────────────────────────────────────────

test "infer: var binding ---- mutable local inside fn" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn count() -> i32 {
        \\    var n = 0;
        \\    return n;
        \\}
        \\val r = count();
    );
}

test "infer: var binding ---- mutable string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet() -> string {
        \\    var msg = "hello";
        \\    return msg;
        \\}
        \\val r = greet();
    );
}

// ── null-check binding ────────────────────────────────────────────────────────

test "infer: null-check binding ---- if (x) { e -> } body ignores binding" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn check() -> string {
        \\    var x = null;
        \\    if (x) { e ->
        \\        return "found";
        \\    };
        \\    return "none";
        \\}
        \\val r = check();
    );
}

// ── try / catch ───────────────────────────────────────────────────────────────

test "infer: try expression ---- result type unified with return" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
        \\val x = process();
    );
}

test "infer: try-catch ---- handler provides fallback" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
        \\val x = safe();
    );
}

test "infer error: try ---- on non-Result type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    return 42;
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
    );
}

// ── pub val ───────────────────────────────────────────────────────────────────

test "infer: pub val ---- infers same as private val" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val NAME = "botopink";
    );
}

// ── variable assignment ───────────────────────────────────────────────────────

test "infer: assign ---- number literal to var" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = 10;
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- string to var" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var name = "old";
        \\    name = "new";
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- type mismatch error" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = "oops";
        \\}
    );
}

// ── additional case patterns (not covered by infer: section above) ────────────

test "infer ast: case ---- list patterns empty, single, spread" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe() -> string {
        \\    val items = ["a", "b", "c"];
        \\    return case items {
        \\        [] -> "empty";
        \\        [x] -> "one";
        \\        [first, ..rest] -> "many";
        \\    };
        \\}
    );
}

// ── unique case patterns (not covered by infer: section above) ────────────────

test "infer ast: delegate declaration" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

test "infer ast: case ---- OR patterns with block arm body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _      -> {
        \\        val value = "odd";
        \\        break value;
        \\    };
        \\};
    );
}

test "infer ast: case ---- union return type from mismatched arms" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0    -> "zero";
        \\    _ -> 1;
        \\};
    );
}

test "infer ast: case ---- nested case in block arm" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> {
        \\      case 1 {
        \\          0    -> 54;
        \\          _ -> 1;
        \\      };
        \\   };
        \\   _ -> 1;
        \\};
    );
}

// ── pipeline ──────────────────────────────────────────────────────────────────

test "types: pipeline ---- simple chain" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1 |> double |> inc;
        \\}
    );
}

test "types: pipeline ---- multiple parameters" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\fn multiply(a: i32, b: i32) -> i32 { return a * b; }
        \\fn format(value: i32, prefix: string, suffix: string) -> string { return prefix + value + suffix; }
        \\fn main() {
        \\    val result = 5 |> add(3) |> multiply(2) |> format("Result: ", " !");
        \\}
    );
}

// ── comments / doc comments ───────────────────────────────────────────────────

test "types: comment ---- single line" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\// This is a comment
        \\fn main() {
        \\    null;
        \\}
    );
}

test "types: doc comment ---- before fn" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\/// This is a documented function
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "types: module comment ---- top of file" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// This module provides utilities
        \\
        \\fn main() {
        \\    null;
        \\}
    );
}

// ── negation ──────────────────────────────────────────────────────────────────

test "types: negation ---- unary minus" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn negate(x: i32) -> i32 {
        \\    return -x;
        \\}
    );
}

// ── range ─────────────────────────────────────────────────────────────────────

test "types: range ---- iterate 0 to n" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) {
        \\    loop (0..n) { i ->
        \\        yield i;
        \\    };
        \\}
    );
}

// ── break / continue / yield ──────────────────────────────────────────────────

test "types: loop ---- break with value" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32 {
        \\    return loop (arr) { x ->
        \\        if (x > 10) { break x; };
        \\    };
        \\}
    );
}

test "types: loop ---- yield accumulation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn doubles(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        yield x * 2;
        \\    };
        \\}
    );
}

// ── assign operations ─────────────────────────────────────────────────────────

test "types: assign ---- plusEq on var" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn increment() {
        \\    var count = 0;
        \\    count += 1;
        \\}
    );
}

// ── self field access ────────────────────────────────────────────────────────

test "types: self ---- field access in method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = struct {
        \\    x: i32,
        \\    y: i32,
        \\    fn sum() -> i32 {
        \\        return self.x + self.y;
        \\    },
        \\};
    );
}

// ── if with binding (null-check) ─────────────────────────────────────────────

test "types: if ---- null-check binding returns optional" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: ?string) -> ?string {
        \\    return if (name) { n -> n; };
        \\}
    );
}

test "types: if ---- null-check binding with else" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: ?string) -> string {
        \\    return if (name) { n -> n; } else { "anonymous"; };
        \\}
    );
}

// ── variant inference (TODO: not yet implemented) ──────────────────────────────

test "variant inference: field access after pattern matching" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val get_value = fn(r: Result) -> i32 {
        \\    case r {
        \\        Ok(v) -> v;
        \\        Error(_) -> 0;
        \\    }
        \\};
    );
}

test "variant inference error: shared field without pattern matching" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val get_value = fn(r: Result) -> i32 {
        \\    r.kind
        \\};
    );
}

test "variant inference error: variant does not escape clause scope" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Error(message: string),
        \\};
        \\val test = fn(r: Result) -> i32 {
        \\    case r {
        \\        Ok(_) -> {};
        \\        Error(_) -> {};
        \\    };
        \\    return r.kind;
        \\};
    );
}

test "variant inference: multiple variants with different fields" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Rectangle(width: f64, height: f64),
        \\    Point,
        \\};
        \\val area = fn(s: Shape) -> f64 {
        \\    case s {
        \\        Circle(r) -> 3.14 * r * r;
        \\        Rectangle(w, h) -> w * h;
        \\        Point -> 0.0;
        \\    }
        \\};
    );
}

// ── record update (TODO: not yet implemented) ───────────────────────────────────

test "record update: simple field update" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\    city: string,
        \\};
        \\val alice = Person(name: "Alice", age: 30, city: "London");
        \\val bob = Person(..alice, name: "Bob", age: 25);
    );
}

test "record update error: variant mismatch" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Subject = enum {
        \\    Person(name: string, age: i32),
        \\    Animal(species: string),
        \\};
        \\val alice = Subject.Person(name: "Alice", age: 30);
        \\val dog = Subject.Animal(..alice);
    );
}

test "record update error: non-existent field" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val alice = Person(name: "Alice", age: 30);
        \\val bob = Person(..alice, nickname: "Bobby");
    );
}

test "record update error: field type mismatch" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val alice = Person(name: "Alice", age: 30);
        \\val bob = Person(..alice, age: "thirty");
    );
}

// ── exhaustiveness checking (TODO: not yet implemented) ────────────────────────

test "exhaustiveness error: missing enum patterns" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val categorize = fn(s: string) -> string {
        \\    case s {
        \\        "hello" -> "greeting";
        \\    }
        \\};
    );
}

test "exhaustiveness: nested pattern matching" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
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

test "pattern: non-empty list pattern" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val first_or_default = fn(list: i32[], default: i32) -> i32 {
        \\    case list {
        \\        [first, ..] -> first;
        \\        [] -> default;
        \\    }
        \\};
    );
}

test "pattern: assign pattern in enum" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Err(message: string),
        \\};
        \\val process = fn(r: Result) -> string {
        \\    case r {
        \\        Ok(v) as result -> "Got: " + v;
        \\        Err(e) as result -> "Error: " + e;
        \\    }
        \\};
    );
}

test "type_unification_does_not_allow_different_variants_to_be_treated_as_safe" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum {
        \\    Ok(value: i32),
        \\    Err(message: string),
        \\};
        \\val process = fn(r: Result) -> string {
        \\    case r {
        \\      Ok(..) as b -> Wibble(..b, value: 1);
        \\      Err(..) as b -> Wobble(..b, message: "a");
        \\    }
        \\};
    );
}
test "pattern: assign pattern in record" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Person = record {
        \\    name: string,
        \\    age: i32,
        \\};
        \\val describe = fn(p: Person) -> string {
        \\    case p {
        \\        Person(name, age) as person -> name + " is " + age;
        \\    };
        \\};
    );
}

test "pattern: complex nested patterns" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T, E> {
        \\    Ok(value: T),
        \\    Err(error: E),
        \\};
        \\val Container = enum {
        \\    Single(Result<i32, string>),
        \\    Multiple(Result<i32, string>[]),
        \\};
        \\val extract = fn(c: Container) -> i32 {
        \\    case c {
        \\        Single(Ok(v)) -> v;
        \\        Multiple([Ok(v), ..]) -> v;
        \\        _ -> 0;
        \\    }
        \\};
    );
}

// ── combined tests: variant inference + pattern matching ───────────────────────

test "variant inference: access variant-specific field after matching" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\};
        \\val scale = fn(s: Shape, factor: f64) -> Shape {
        \\    case s {
        \\        Circle(r) -> Circle(radius: r * factor);
        \\        Square(s) -> Square(side: s * factor);
        \\    };
        \\};
    );
}

test "variant inference: pattern matching on generic enum" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    Some(value: T),
        \\    None,
        \\};
        \\val map = fn(opt: Option<i32>, f: fn(i32) -> i32) -> Option<i32> {
        \\    case opt {
        \\        Some(v) -> Some(value: f(v));
        \\        None -> None;
        \\    };
        \\};
    );
}

// ── @Result<R, E> type resolution ──────────────────────────────────────────────────

test "@Result: try unwraps Result to D" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record AppError { msg: string }
        \\fn fetch() -> @Result<i32, AppError> {
        \\    throw AppError(msg: "fail");
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
    );
}

test "@Result: try propagates without catch" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record IoError { path: string }
        \\fn load() -> @Result<string, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\fn run() -> @Result<string, IoError> {
        \\    val s = try load();
        \\    return s;
        \\}
    );
}

test "@Result: multiple catch with different types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record UserError { msg: string }
        \\fn getName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\fn getAge() -> @Result<i32, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\fn loadUser() {
        \\    val name = try getName() catch "anon";
        \\    val age = try getAge() catch 0;
        \\}
    );
}

// ── throw type checking ───────────────────────────────────────────────────────
//
// The value thrown by `throw` must match the `E` of the enclosing function's
// `@Result<D, E>` return type. Functions with no declared return type leave
// `throw` unchecked (e.g. `catch throw …`); functions with a declared,
// non-`@Result` return type reject `throw` entirely.

test "throw check: string matches declared E = string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn parse(s: string) -> @Result<i32, string> {
        \\    if (s == "") {
        \\        throw "empty input";
        \\    }
        \\    return 0;
        \\}
    );
}

test "throw check: record matches declared E = ErrorRecord" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record AppError { code: i32, msg: string }
        \\fn load() -> @Result<string, AppError> {
        \\    throw AppError(code: 500, msg: "boom");
        \\}
    );
}

test "throw check: throw inside catch handler checks enclosing fn E" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    throw "primary";
        \\}
        \\fn process() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "secondary";
        \\    return r;
        \\}
    );
}

test "throw check: multiple throw sites all match E" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn validate(n: i32) -> @Result<i32, string> {
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
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn outer() -> @Result<i32, string> {
        \\    val cb = fn() {
        \\        throw 404;
        \\    };
        \\    throw "outer error";
        \\}
    );
}

test "throw check error: type mismatch i32 thrown but E = string" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn parse(s: string) -> @Result<i32, string> {
        \\    throw 404;
        \\}
    );
}

test "throw check error: throw without enclosing Result return type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn run() -> i32 {
        \\    throw "x";
        \\}
    );
}

// ── @print ─────��─────────────────────────────────────────────────────────────

test "@print: single string argument infers void" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("hello");
        \\}
    );
}

test "@print: multiple arguments infers void" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("x =", 42, true);
        \\}
    );
}

test "@print: expression argument infers void" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x = 10;
        \\    @print(x + 5);
        \\}
    );
}

test "@print: in if branch infers void" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn check(x: i32) {
        \\    if x > 0 {
        \\        @print("positive");
        \\    } else {
        \\        @print("non-positive");
        \\    }
        \\}
    );
}

test "@print: string interpolation argument" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: string) {
        \\    @print("Hello, " + name + "!");
        \\}
    );
}

// ── @Context<B, R> capability inference (F7) ────────────────────────────────────

test "context: use with binding in @Context fn passes" {
    try assertInfersOk(std.testing.allocator,
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
    try assertInfersOk(std.testing.allocator,
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
    try assertInfersOk(std.testing.allocator,
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
    try assertInfersOk(std.testing.allocator,
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
    try assertTypeErrorSnap(std.testing.allocator, @src(),
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
    try assertTypeErrorSnap(std.testing.allocator, @src(),
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
    try assertTypeErrorSnap(std.testing.allocator, @src(),
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

// ── async / generators (*fn, await, yield, loop await) ────────────────────────

test "infer: star fn ---- async returns @Future is valid" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
    );
}

test "infer: star fn ---- generator returns @Iterator is valid" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<i32> {
        \\    yield 1;
        \\}
    );
}

test "infer error: star fn returning a non-async type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> string {
        \\    return "x";
        \\}
    );
}

test "infer error: normal fn returning @Future must be star fn" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Future<i32> {
        \\    return 0;
        \\}
    );
}

test "infer error: await outside a star fn" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn notAsync() -> i32 {
        \\    val x = await ready();
        \\    return x;
        \\}
    );
}

test "infer error: await on a non-@Future value" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> @Future<i32> {
        \\    val x = await 5;
        \\    return x;
        \\}
    );
}

test "infer error: yield targets an unknown label" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<i32> {
        \\    yield :nope 1;
        \\}
    );
}

test "infer error: loop await on a non-async-iterable" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> @Future<i32> {
        \\    loop await (5) { x ->
        \\        ping(x);
        \\    }
        \\}
    );
}
