/// Tests for the sub-language (`@ExprCustom`) LSP overlay: semantic tokens,
/// diagnostics, hover, and go-to-definition driven by the generic `CustomNode`
/// trees a template lib produces (sublanguage-lsp).
///
/// These exercise the full tooling path — `compileEval` runs the node-backed
/// template evaluator so the `CustomNode` trees actually exist — so they need
/// `node` on PATH (like the comptime template tests).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");
const lsp_types = @import("../lsp_types.zig");

/// A self-contained sub-language fixture: a template fn that returns
/// `@ExprCustom`, lighting up `select` as a keyword and `name` as a property
/// (the latter bound to the `Users` struct via `ref`). No real lib involved —
/// proves the overlay is generic.
const FIXTURE =
    \\pub struct Users { name: string }
    \\pub fn q<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    \\    val code = e.build("[1, 2]");
    \\    val kw = CustomNode(kind: "kw", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
    \\    val col = CustomNode(kind: "col", span: Span(7, 11, 1), label: "property", ref: e.lookup("Users"), children: []);
    \\    val root = CustomNode(kind: "root", span: Span(0, 0, 1), label: "none", ref: null, children: [kw, col]);
    \\    return e.custom(root, code);
    \\}
    \\val xs = q "select name";
;

/// Semantic tokens with the sub-language overlay merged in (mirrors the server's
/// `handleSemanticTokens`).
fn semanticTokensWithCustom(
    gpa: std.mem.Allocator,
    slug: []const u8,
    source: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var c = try h.compileEval(gpa, source);
    defer c.deinit(gpa);

    const tokens = try h.tokenize(a, source);
    const bindings = c.bindings() orelse &.{};
    const lexed = try engine.semanticTokens(a, tokens, bindings);
    const custom = try engine.customSemanticTokens(a, source, c.customAst());
    const toks = try engine.mergeSemanticTokens(a, lexed, custom);

    try snap.assertSemanticTokens(gpa, slug, source, toks);
}

test "sublanguage: custom AST is retrievable after compile" {
    const gpa = std.testing.allocator;
    var c = try h.compileEval(gpa, FIXTURE);
    defer c.deinit(gpa);

    const entries = c.customAst();
    try std.testing.expectEqual(@as(usize, 1), entries.len);
    try std.testing.expectEqualStrings("q", entries[0].callee);
    try std.testing.expectEqualStrings("keyword", entries[0].root.children[0].label);
    try std.testing.expect(entries[0].root.children[1].ref != null);
    try std.testing.expectEqualStrings("Users", entries[0].root.children[1].ref.?.name);
}

test "sublanguage: semantic tokens light up keyword + property inside the string" {
    try semanticTokensWithCustom(std.testing.allocator, "sublanguage_semantic_tokens", FIXTURE);
}

/// A template that aborts via `q.failAt(span, msg)` — the sub-language rejecting
/// a malformed query. The span (7..11) targets `name` inside `q "select name"`.
const FIXTURE_FAIL =
    \\pub struct Users { name: string }
    \\pub fn q<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    \\    e.failAt(Span(7, 11, 1), "unknown column 'name'");
    \\    val code = e.build("[1, 2]");
    \\    val root = CustomNode(kind: "root", span: Span(0, 0, 1), label: "none", ref: null, children: []);
    \\    return e.custom(root, code);
    \\}
    \\val xs = q "select name";
;

/// Byte offset of `pos` in `source` (test-side mirror of the engine's mapping).
fn offsetOf(source: []const u8, p: proto.Position) usize {
    return lsp_types.positionToOffset(source, p);
}

test "sublanguage F2: a malformed query yields a diagnostic ranged inside the string" {
    const gpa = std.testing.allocator;
    var c = try h.compileEval(gpa, FIXTURE_FAIL);
    defer c.deinit(gpa);

    const diags = try c.result.diagnosticsFor(gpa, h.TEST_URI);
    defer {
        for (diags) |d| gpa.free(d.message);
        gpa.free(diags);
    }

    // The `failAt` message surfaces as a botopink diagnostic …
    const lit = "select name";
    const cstart = std.mem.indexOf(u8, FIXTURE_FAIL, lit).?;
    const cend = cstart + lit.len;

    var found = false;
    for (diags) |d| {
        if (std.mem.indexOf(u8, d.message, "unknown column") == null) continue;
        // … ranged *inside* the string literal (on `name`), not at the call site.
        const off = offsetOf(FIXTURE_FAIL, d.range.start);
        try std.testing.expect(off >= cstart and off < cend);
        found = true;
    }
    try std.testing.expect(found);
}

test "sublanguage F3: hover on a bound node shows the referenced symbol" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    var c = try h.compileEval(gpa, FIXTURE);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.NoBindings;

    // Cursor in the middle of `name` (the `col` node bound to `Users`).
    const lit = "select name";
    const content = std.mem.indexOf(u8, FIXTURE, lit).?;
    const p = lsp_types.offsetToPosition(FIXTURE, content + 8);

    const hover = (try engine.hoverCustomRef(gpa, FIXTURE, p, bindings, c.customAst())) orelse
        return error.NoHover;
    defer gpa.free(hover.contents.value);

    // Hover renders the *bound* symbol (`struct Users`), not the word `name`.
    try std.testing.expect(std.mem.indexOf(u8, hover.contents.value, "struct Users") != null);
}

test "sublanguage F3: go-to-definition on a bound node jumps to its declaration" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var c = try h.compileEval(gpa, FIXTURE);
    defer c.deinit(gpa);

    const tokens = try h.tokenize(a, FIXTURE);
    const lit = "select name";
    const content = std.mem.indexOf(u8, FIXTURE, lit).?;
    const p = lsp_types.offsetToPosition(FIXTURE, content + 8);

    const loc = (try engine.definitionCustomRef(gpa, h.TEST_URI, FIXTURE, p, tokens, c.customAst())) orelse
        return error.NoDefinition;
    defer gpa.free(loc.uri);

    // `Users` is declared on the first line.
    try std.testing.expectEqual(@as(u32, 0), loc.range.start.line);
}

test "sublanguage F4: hover snapshot on a bound sub-language node" {
    const gpa = std.testing.allocator;
    var c = try h.compileEval(gpa, FIXTURE);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.NoBindings;

    const lit = "select name";
    const content = std.mem.indexOf(u8, FIXTURE, lit).?;
    const cursor = lsp_types.offsetToPosition(FIXTURE, content + 8);

    const hover = try engine.hoverCustomRef(gpa, FIXTURE, cursor, bindings, c.customAst());
    defer if (hover) |hv| gpa.free(hv.contents.value);

    try snap.assertHover(gpa, "sublanguage_hover_ref", FIXTURE, cursor, hover);
}
