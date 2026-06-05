//! comptime: `@Expr` template capture, scope snapshot, template methods,
//! `fail`/`failAt` span mapping, and call-site expansion (expr-templates).

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
        \\pub fn sql(comptime q: @Expr<string>) -> @Expr<string> {
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
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
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
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
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
        \\pub fn html(comptime template: @Expr<string>, sp: Span) -> @Expr<string> {
        \\    val v = template.value();
        \\    val t = template.text();
        \\    val ps = template.parts();
        \\    val where = template.source();
        \\    val ctx = template.context();
        \\    val scope = template.bindings();
        \\    val b = template.lookup("Button");
        \\    val made = template.build("1 + 2");
        \\    template.failAt(sp, "bad tag");
        \\    template.fail("no component");
        \\    return template;
        \\}
        \\pub fn mk<T>(b: Binding) -> @Expr<T> {
        \\    return b.ref();
        \\}
    );

    try std.testing.expectEqual(@as(usize, 11), env.templateLowerings.count());
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
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
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
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val tpl = "<p></p>";
        \\val c = html(tpl);
    );
}

test "infer error: expr argument is typed in the caller against inner T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn check(comptime cond: @Expr<bool>) -> @Expr<bool> {
        \\    return cond;
        \\}
        \\val c = check("not a bool");
    );
}

test "template: context exposes declaration position and scope for second-layer languages" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn dsl(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = dsl """
        \\<Button/>
        \\""";
    );

    const captures = try onlyCaptures(&env);
    const json = try template.contextJsonAlloc(&captures[0], std.testing.allocator);
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings(
        \\{"file":"","line":7,"col":13,"multiline":true,"text":"\n<Button/>\n","scope":{"Button":"Struct","dsl":"Fn","c":"Val"}}
    , json);
}

test "infer: context/source/bindings/build methods typecheck against std.syntax" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn dsl(comptime template: @Expr<string>) -> @Expr<string> {
        \\    val ctx = template.context();
        \\    val file: string = ctx.source.file;
        \\    val line: i32 = ctx.source.line;
        \\    val raw: string = ctx.text;
        \\    val names = template.bindings();
        \\    return template.build("file + raw");
        \\}
    );
}

test "comptime: template fn with expr param compiles through the pipeline" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>hello</p>
        \\""";
    );
}

// ── F6: call-site expansion ───────────────────────────────────────────────────

test "template: bounded expansion is transparent to the caller (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>hi</p>
        \\""";
    );

    // The call site types as the bound `string`, not `expr<string>` —
    // splice + re-check happened during inference.
    try std.testing.expectEqualStrings("string", env.lookup("c").?.deref().named.name);
    try std.testing.expectEqual(@as(u32, 1), env.templateExpansions.count());
}

test "template: generic @Expr<T> return reveals the expansion type per call (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn answer<T>() -> @Expr<T> {
        \\    return @code("42");
        \\}
        \\val n = answer();
        \\val m = n + 1;
    );

    // `n` carries the expansion's own type — the generic `@Expr<T>` return
    // revealed it, and `n + 1` typechecked against it.
    try std.testing.expectEqualStrings("i32", env.lookup("n").?.deref().named.name);
}

test "template: explicit value lift via @expr builtin (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn port() -> @Expr<i32> {
        \\    return @expr(8080);
        \\}
        \\val p = port();
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
}

test "infer error: splice bound violation at the call site (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn bad() -> @Expr<i32> {
        \\    return @expr("not an int");
        \\}
        \\val d = bad();
    );
}

test "infer error: template body not expandable by the V1 driver (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hard(comptime t: @Expr<string>) -> @Expr<string> {
        \\    val x = t.text();
        \\    return t;
        \\}
        \\val c = hard "SELECT 1";
    );
}

// ── F6-full: runtime-backed template bodies ───────────────────────────────────

test "comptime: runtime template body ---- text() + build() end to end" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val t = q.text();
        \\    return q.build("\"" + t + "!\"");
        \\}
        \\val s = shout "hey";
    );
}

test "comptime: runtime template body ---- lookup miss drives control flow" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
        \\    val hit = t.lookup("Buttom");
        \\    if (hit) { b ->
        \\        return t.fail("should be missing");
        \\    };
        \\    return t.build("\"ok\"");
        \\}
        \\val r = need "x";
    );
}

test "comptime: runtime template body ---- @expr lifts a computed value" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn six(comptime t: @Expr<string>) -> @Expr<i32> {
        \\    val n = 2 + 4;
        \\    return @expr(n);
        \\}
        \\val n = six "ignored";
    );
}

test "template: runtime fail() maps into the caller's template" {
    const src =
        \\pub fn lint(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val t = q.text();
        \\    q.fail("template rejected: " + t);
        \\    return q;
        \\}
        \\val s = lint "bad";
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        .node,
        ".botopinkbuild/comptime/runtime_fail_maps_into_template",
    );
    defer session.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .typeError);
    const te = outcome.typeError;
    // The diagnostic points at the template literal in the caller's file.
    try std.testing.expectEqual(@as(usize, 6), te.loc.?.line);
    const msg = try te.message(std.testing.allocator);
    defer std.testing.allocator.free(msg);
    try std.testing.expectEqualStrings("template rejected: bad", msg);
}
