//! comptime: `expr` template capture, scope snapshot, template methods, and
//! `fail`/`failAt` span mapping (expr-templates F4).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const template = @import("../template.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

/// Parse + infer `src` into `env` (builtins + stdlib preloaded). The caller
/// owns `env` (deinit) and the arena everything is allocated in.
fn inferInto(env: *Env, arena: std.mem.Allocator, src: []const u8) !void {
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const program = try p.parse(arena);
    _ = inferMod.inferProgramTyped(env, program) catch |err| {
        if (env.lastError) |te| {
            const desc = try h.renderTypeError(std.testing.allocator, src, te);
            defer std.testing.allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        }
        return err;
    };
}

fn freshTestEnv(arena: std.mem.Allocator) !Env {
    var env = Env.init(arena);
    errdefer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, std.testing.allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    return env;
}

/// The single capture list recorded during inference (asserts exactly one call
/// site captured).
fn onlyCaptures(env: *Env) ![]const template.CapturedExpr {
    try std.testing.expectEqual(@as(usize, 1), env.exprCaptures.count());
    var it = env.exprCaptures.valueIterator();
    return it.next().?.*;
}

test "template: expr param capture ---- plain string arg arrives unevaluated" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn sql(comptime q: expr string) -> expr string {
        \\    return q;
        \\}
        \\val stmt = sql "SELECT 1";
    );

    const captures = try onlyCaptures(&env);
    try std.testing.expectEqual(@as(usize, 1), captures.len);
    const cap = captures[0];
    try std.testing.expectEqualStrings("sql", cap.callee);
    try std.testing.expectEqualStrings("q", cap.paramName);
    try std.testing.expectEqual(@as(usize, 0), cap.paramIndex);
    try std.testing.expectEqualStrings("SELECT 1", cap.text.?);
    try std.testing.expect(!cap.multiline);
    // The captured node is the literal exactly as parsed — unevaluated.
    try std.testing.expect(cap.node.* == .literal);
    try std.testing.expect(cap.node.literal.kind == .stringLit);
}

test "template: expr param capture ---- multiline template with hole keeps parts" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(comptime template: expr string) -> expr string {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>${1 + 2}</p>
        \\""";
    );

    const captures = try onlyCaptures(&env);
    const cap = captures[0];
    try std.testing.expectEqualStrings("template", cap.paramName);
    try std.testing.expect(cap.multiline);
    // Holes present: no contiguous text — the parts live on the node.
    try std.testing.expect(cap.text == null);
    try std.testing.expect(cap.node.* == .literal);
    const parts = cap.node.literal.kind.stringTemplate.parts;
    try std.testing.expectEqual(@as(usize, 3), parts.len); // text, hole, text
    try std.testing.expect(parts[1] == .expr);
}

test "template: scope snapshot lookup ---- hit and miss" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn html(comptime template: expr string) -> expr string {
        \\    return template;
        \\}
        \\val c = html """
        \\<Button/>
        \\""";
    );

    const captures = try onlyCaptures(&env);
    const scope = captures[0].scope.?;
    // Hits: the caller's top-level decls, with their kinds.
    try std.testing.expectEqual(template.BindingKind.struct_, scope.lookup("Button").?.kind);
    try std.testing.expectEqual(template.BindingKind.fn_, scope.lookup("html").?.kind);
    try std.testing.expectEqual(template.BindingKind.val, scope.lookup("c").?.kind);
    // Miss: typo'd component is simply absent (`lookup` surfaces @Option none).
    try std.testing.expect(scope.lookup("Buttom") == null);

    // The serializable handle for the expansion runtime (F6).
    const json = try scope.toJsonAlloc(std.testing.allocator);
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings(
        \\{"Button":"Struct","html":"Fn","c":"Val"}
    , json);
}

test "template: expr methods typecheck and record lowerings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(comptime template: expr string, sp: Span) -> expr string {
        \\    val t = template.text();
        \\    val ps = template.parts();
        \\    val b = template.lookup("Button");
        \\    template.failAt(sp, "bad tag");
        \\    template.fail("no component");
        \\    return template;
        \\}
        \\pub fn mk(b: Binding) -> expr {
        \\    return b.ref();
        \\}
    );

    try std.testing.expectEqual(@as(usize, 6), env.templateLowerings.count());
    var counts = std.enums.EnumArray(envMod.TemplateOp, usize).initFill(0);
    var it = env.templateLowerings.valueIterator();
    while (it.next()) |op| counts.set(op.*, counts.get(op.*) + 1);
    for (std.enums.values(envMod.TemplateOp)) |op| {
        try std.testing.expectEqual(@as(usize, 1), counts.get(op));
    }
}

test "template: fail span maps into the caller's template" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    const src =
        \\pub fn html(comptime template: expr string) -> expr string {
        \\    return template;
        \\}
        \\val c = html """
        \\<Buttom label="Send"/>
        \\""";
    ;
    try inferInto(&env, alloc, src);

    const captures = try onlyCaptures(&env);
    const cap = &captures[0];

    // Template text is contiguous (no holes) and keeps the leading newline.
    const text = cap.text.?;
    const start = std.mem.indexOf(u8, text, "Buttom").?;

    // `failAt` with a span pointing at `Buttom` lands on line 5 col 2 of the
    // caller's file — inside the """…""" literal, not in the template library.
    const err = template.failDiagnostic(cap, .{ .start = start, .end = start + "Buttom".len, .line = 1 }, "component `Buttom` not found in caller scope");
    try std.testing.expectEqual(@as(usize, 5), err.loc.?.line);
    try std.testing.expectEqual(@as(usize, 2), err.loc.?.col);

    // Bare `fail` (no span) points at the template literal itself.
    const errNoSpan = template.failDiagnostic(cap, null, "nope");
    try std.testing.expectEqual(cap.loc.line, errNoSpan.loc.?.line);

    const desc = try h.renderTypeError(std.testing.allocator, src, err);
    defer std.testing.allocator.free(desc);
    try snapMod.checkText(std.testing.allocator, "comptime/templates/fail_span_in_template", desc);
}

test "infer error: expr argument must be a literal string (V1)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn html(comptime template: expr string) -> expr string {
        \\    return template;
        \\}
        \\val tpl = "<p></p>";
        \\val c = html(tpl);
    );
}

test "infer error: expr argument is typed in the caller against inner T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn check(comptime cond: expr bool) -> expr bool {
        \\    return cond;
        \\}
        \\val c = check("not a bool");
    );
}

test "comptime: template fn with expr param compiles through the pipeline" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime template: expr string) -> expr string {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>hello</p>
        \\""";
    );
}
