/// LSP feature implementations: diagnostics, formatting, hover, definition, symbols,
/// completion, references, and rename.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");
const compiler_mod = @import("./compiler.zig");
const index_mod = @import("./project_index.zig");

const Lexer = bp.Lexer;
const Parser = bp.Parser;
const Token = bp.Token;
const TokenKind = bp.TokenKind;
const ast = bp.ast;
const format_fn = bp.format.format;
const comptime_pipeline = bp.comptime_pipeline;

// ── Diagnostics ───────────────────────────────────────────────────────────────

pub const DiagnosticsResult = struct {
    uri: []const u8,
    diagnostics: []proto.Diagnostic,

    pub fn deinit(self: *DiagnosticsResult, gpa: std.mem.Allocator) void {
        for (self.diagnostics) |d| gpa.free(d.message);
        gpa.free(self.diagnostics);
    }
};

pub fn diagnose(
    gpa: std.mem.Allocator,
    io: std.Io,
    uri: []const u8,
    source: []const u8,
) !DiagnosticsResult {
    _ = io;
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa);
    const entries = [_]compiler_mod.ModuleEntry{.{ .uri = uri, .source = source }};

    var result = try lsp_compiler.compile(&entries);
    defer result.deinit(gpa);

    var diags: std.ArrayList(proto.Diagnostic) = .empty;
    errdefer {
        for (diags.items) |d| gpa.free(d.message);
        diags.deinit(gpa);
    }

    // Comptime validation errors
    const compile_diags = try result.diagnosticsFor(gpa, uri);
    defer {
        for (compile_diags) |d| gpa.free(d.message);
        gpa.free(compile_diags);
    }
    for (compile_diags) |d| {
        try diags.append(gpa, .{
            .range = d.range,
            .severity = d.severity,
            .message = try gpa.dupe(u8, d.message),
            .source = d.source,
        });
    }

    // Parse errors
    {
        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();
        const alloc = arena.allocator();
        var lexer = Lexer.init(source);
        if (lexer.scanAll(alloc)) |tokens| {
            var parser = Parser.init(tokens);
            _ = parser.parse(alloc) catch |err| switch (err) {
                error.UnexpectedToken => {
                    if (parser.parseError) |pe| {
                        const msgs = bp.print_errors.errorMessages(pe);
                        try diags.append(gpa, .{
                            .range = lsp_types.spanToRange(source, pe.start, pe.end),
                            .severity = proto.DiagnosticSeverity.Error,
                            .message = try gpa.dupe(u8, msgs.message),
                            .source = "botopink",
                        });
                    }
                },
                else => {},
            };
        } else |_| {}
    }

    return .{ .uri = uri, .diagnostics = try diags.toOwnedSlice(gpa) };
}

// ── Formatting ────────────────────────────────────────────────────────────────

pub fn formatting(arena: std.mem.Allocator, source: []const u8) !?proto.TextEdit {
    var lexer = Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch return null;
    var parser = Parser.init(tokens);
    const program = parser.parse(arena) catch return null;
    const formatted = try format_fn(arena, program);
    if (std.mem.eql(u8, source, formatted)) return null;
    return .{ .range = lsp_types.fullRange(source), .newText = formatted };
}

// ── Hover ─────────────────────────────────────────────────────────────────────

/// Returns hover info (inferred type) for the symbol under the cursor.
/// The `contents.kind` field of the returned Hover is owned by the caller.
pub fn hover(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Hover {
    const name = identAt(source, pos) orelse return null;

    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, name)) continue;

        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(gpa);

        try buf.appendSlice(gpa, "```botopink\n");

        switch (b.decl) {
            .@"fn" => |f| {
                // The effect is carried by a `#[@<effect>]` annotation; the
                // deprecated `*` prefix marks a `*fn` that has no annotation.
                if (f.effectAnnotation()) |e| {
                    try buf.appendSlice(gpa, "#[@");
                    try buf.appendSlice(gpa, e.annotationName());
                    try buf.appendSlice(gpa, "]\n");
                }
                if (f.isPub) try buf.appendSlice(gpa, "pub ");
                const isStar = f.effect != null and f.effectAnnotation() == null;
                try buf.appendSlice(gpa, if (isStar) "*fn " else "fn ");
                try buf.appendSlice(gpa, b.name);
                try buf.append(gpa, '(');
                for (f.params, 0..) |p, pi| {
                    if (pi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, p.name);
                    try buf.appendSlice(gpa, ": ");
                    try appendTypeRef(gpa, &buf, p.typeRef);
                }
                try buf.append(gpa, ')');
                if (f.returnType) |rt| {
                    try buf.appendSlice(gpa, " -> ");
                    try appendTypeRef(gpa, &buf, rt);
                }
                if (f.label) |lbl| {
                    try buf.appendSlice(gpa, " :");
                    try buf.appendSlice(gpa, lbl);
                }
            },
            .val => {
                const type_str = try renderType(gpa, b.type_);
                defer gpa.free(type_str);
                try buf.appendSlice(gpa, "val ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " : ");
                try buf.appendSlice(gpa, type_str);
            },
            .record => |r| {
                if (r.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "record ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " { ");
                for (r.fields, 0..) |field, fi| {
                    if (fi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, field.name);
                    try buf.appendSlice(gpa, ": ");
                    try appendTypeRef(gpa, &buf, field.typeRef);
                }
                try buf.appendSlice(gpa, " }");
            },
            .@"struct" => |s| {
                if (s.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "struct ");
                try buf.appendSlice(gpa, b.name);
            },
            .@"enum" => |e| {
                if (e.isPub) try buf.appendSlice(gpa, "pub ");
                try buf.appendSlice(gpa, "enum ");
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " { ");
                for (e.variants, 0..) |v, vi| {
                    if (vi > 0) try buf.appendSlice(gpa, ", ");
                    try buf.appendSlice(gpa, v.name);
                    if (v.fields.len > 0) try buf.appendSlice(gpa, "(...)");
                }
                try buf.appendSlice(gpa, " }");
            },
            .interface => {
                try buf.appendSlice(gpa, "interface ");
                try buf.appendSlice(gpa, b.name);
            },
            else => {
                const type_str = try renderType(gpa, b.type_);
                defer gpa.free(type_str);
                try buf.appendSlice(gpa, b.name);
                try buf.appendSlice(gpa, " : ");
                try buf.appendSlice(gpa, type_str);
            },
        }

        try buf.appendSlice(gpa, "\n```");

        // For an effect fn, surface the unwrapped element type produced by
        // `await` / `yield` / iteration (the `T` of `@Future<T>` /
        // `@Iterator<T>` / `@AsyncIterator<T, _>`).
        if (b.decl == .@"fn" and b.decl.@"fn".effect != null) {
            if (b.decl.@"fn".returnType) |rt| {
                if (asyncItemTypeRef(rt)) |item| {
                    try buf.appendSlice(gpa, "\n\n---\n\n`await`/`yield` element type: `");
                    try appendTypeRef(gpa, &buf, item);
                    try buf.appendSlice(gpa, "`");
                }
            }
        }

        // Append doc comment if available.
        const doc = getDeclDocComment(b.decl);
        if (doc) |d| {
            try buf.appendSlice(gpa, "\n\n---\n\n");
            try buf.appendSlice(gpa, d);
        }

        return .{ .contents = .{ .kind = proto.MarkupKind.Markdown, .value = try buf.toOwnedSlice(gpa) } };
    }

    // Not a local binding — try a qualified std module member (`list.map`).
    if (try hoverStdModule(gpa, source, pos)) |h| return h;

    // …or an interface method on a builtin receiver (`42.abs`, `xs.map`).
    if (try hoverBuiltinInterfaceMethod(gpa, source, pos, bindings)) |h| return h;

    return null;
}

/// Hover for `list.map` / `io.println` where the qualifier is a module
/// imported from "std": renders the `pub [declare] fn` signature plus its
/// doc comment, read from the embedded std source. Returns null otherwise.
fn hoverStdModule(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
) !?proto.Hover {
    const span = identSpanAt(source, pos) orelse return null;
    const name = source[span.start..span.end];
    const qual = qualifierBefore(source, span.start) orelse return null;
    const mod = findStdModule(qual) orelse return null;
    if (!importsStdModule(source, qual)) return null;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    var lexer = Lexer.init(mod.source);
    const tokens = lexer.scanAll(arena.allocator()) catch return null;

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .@"pub") continue;
        // `pub fn name` or `pub declare fn name`
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j < tokens.len and tokens[j].kind == .declare) j += 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .@"fn") continue;
        const fn_idx = j;
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind == .endOfFile) : (k += 1) {}
        if (k >= tokens.len or tokens[k].kind != .identifier) continue;
        if (!std.mem.eql(u8, tokens[k].lexeme, name)) continue;

        // Signature slice spans the `pub` keyword through the `{`/`;`.
        const sig_start = tokenOffset(mod.source, tokens[i]);
        var end_idx = fn_idx + 1;
        var depth: u32 = 0;
        while (end_idx < tokens.len) : (end_idx += 1) {
            const ek = tokens[end_idx].kind;
            if (ek == .leftParenthesis) depth += 1;
            if (ek == .rightParenthesis) depth -= 1;
            if (depth == 0 and (ek == .leftBrace or ek == .semicolon)) break;
        }
        const sig_end = if (end_idx < tokens.len) tokenOffset(mod.source, tokens[end_idx]) else mod.source.len;
        const sig = std.mem.trim(u8, mod.source[sig_start..@min(sig_end, mod.source.len)], " \t\r\n");

        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(gpa);
        try buf.appendSlice(gpa, "```botopink\n");
        try buf.appendSlice(gpa, sig);
        try buf.appendSlice(gpa, "\n```");
        try buf.print(gpa, "\n\n*from `std/{s}`*", .{mod.name});

        // Doc comment: consecutive `///` lines immediately above the decl.
        if (stdDocCommentBefore(tokens, i)) |doc| {
            try buf.appendSlice(gpa, "\n\n---\n\n");
            try buf.appendSlice(gpa, doc);
        }

        return .{ .contents = .{ .kind = proto.MarkupKind.Markdown, .value = try buf.toOwnedSlice(gpa) } };
    }
    return null;
}

/// Returns the `///` doc-comment lexeme immediately preceding the token at
/// `decl_idx` (skipping any `#[…]` attribute tokens in between), or null.
fn stdDocCommentBefore(tokens: []const Token, decl_idx: usize) ?[]const u8 {
    var i = decl_idx;
    // Skip backwards over attribute tokens (`]`, `)`, strings, `@external`, `#[`).
    while (i > 0) {
        const k = tokens[i - 1].kind;
        if (k == .commentDoc) return tokens[i - 1].lexeme;
        if (k == .commentModule or k == .commentNormal or k == .endOfFile) {
            i -= 1;
            continue;
        }
        // Attribute / decorator tokens may sit between the doc and the decl.
        if (k == .rightSquareBracket or k == .leftSquareBracket or k == .hash or
            k == .at or k == .identifier or k == .stringLiteral or
            k == .leftParenthesis or k == .rightParenthesis or k == .comma)
        {
            i -= 1;
            continue;
        }
        break;
    }
    return null;
}

fn getDeclDocComment(decl: ast.DeclKind) ?[]const u8 {
    return switch (decl) {
        .@"fn" => |f| f.docComment,
        .val => |v| v.docComment,
        .record => |r| r.docComment,
        .@"struct" => |s| s.docComment,
        .@"enum" => |e| e.docComment,
        .interface => |i| i.docComment,
        .delegate => |d| d.docComment,
        .implement => |i| i.docComment,
        else => null,
    };
}

/// The element type `T` of an async/generator return type
/// (`@Future<T>` / `@Iterator<T>` / `@AsyncIterator<T, _>`), or null.
fn asyncItemTypeRef(tr: ast.TypeRef) ?ast.TypeRef {
    return switch (tr) {
        .generic => |g| if (g.is_builtin and g.args.len >= 1 and
            (std.mem.eql(u8, g.name, "Future") or
                std.mem.eql(u8, g.name, "Iterator") or
                std.mem.eql(u8, g.name, "AsyncIterator")))
            g.args[0]
        else
            null,
        else => null,
    };
}

fn appendTypeRef(gpa: std.mem.Allocator, buf: *std.ArrayList(u8), tr: ast.TypeRef) !void {
    switch (tr) {
        .named => |n| try buf.appendSlice(gpa, n),
        .array => |a| {
            try appendTypeRef(gpa, buf, a.*);
            try buf.appendSlice(gpa, "[]");
        },
        .optional => |o| {
            try buf.append(gpa, '?');
            try appendTypeRef(gpa, buf, o.*);
        },
        .function => |f| {
            try buf.appendSlice(gpa, "fn(");
            for (f.params, 0..) |p, pi| {
                if (pi > 0) try buf.appendSlice(gpa, ", ");
                try appendTypeRef(gpa, buf, p);
            }
            try buf.appendSlice(gpa, ") -> ");
            try appendTypeRef(gpa, buf, f.returnType.*);
        },
        .tuple_ => |t| {
            try buf.appendSlice(gpa, "#(");
            for (t, 0..) |elem, ei| {
                if (ei > 0) try buf.appendSlice(gpa, ", ");
                try appendTypeRef(gpa, buf, elem);
            }
            try buf.append(gpa, ')');
        },
        .generic => |b| {
            if (b.is_builtin) try buf.append(gpa, '@');
            try buf.appendSlice(gpa, b.name);
            try buf.append(gpa, '<');
            for (b.args, 0..) |a, i| {
                if (i > 0) try buf.appendSlice(gpa, ", ");
                try appendTypeRef(gpa, buf, a);
            }
            try buf.append(gpa, '>');
        },
        .typeparam => |constraints| {
            try buf.appendSlice(gpa, "type");
            for (constraints, 0..) |c, i| {
                try buf.appendSlice(gpa, if (i == 0) " " else " | ");
                try appendTypeRef(gpa, buf, c);
            }
        },
        .record_type => |flds| {
            try buf.appendSlice(gpa, "{ ");
            for (flds, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(gpa, ", ");
                try buf.appendSlice(gpa, f.name);
                try buf.appendSlice(gpa, ": ");
                try appendTypeRef(gpa, buf, f.typeRef);
            }
            try buf.appendSlice(gpa, " }");
        },
    }
}

// ── Go to Definition ──────────────────────────────────────────────────────────

/// A borrowed view of one module's source, used for cross-module lookups.
pub const ModuleSource = struct {
    uri: []const u8,
    source: []const u8,
};

/// Scan `tokens` for the name token of a declaration named `name` and return a
/// Location pointing at it. When `require_pub` is set, the declaration must be
/// preceded by a `pub` keyword (used when resolving symbols imported from
/// another module — only exported declarations are reachable).
fn findDeclLocation(
    gpa: std.mem.Allocator,
    uri: []const u8,
    name: []const u8,
    tokens: []const Token,
    require_pub: bool,
) !?proto.Location {
    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl_kw = false;
        for (decl_values) |k| {
            if (tok.kind == k) {
                is_decl_kw = true;
                break;
            }
        }
        if (!is_decl_kw) continue;

        if (require_pub) {
            // The token immediately before the decl keyword must be `pub`.
            if (i == 0 or tokens[i - 1].kind != .@"pub") continue;
        }

        // Next non-trivial token should be the name identifier
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }
    return null;
}

/// Returns the location of the declaration for the symbol under the cursor.
/// The returned `uri` is owned by the caller.
pub fn definition(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
) !?proto.Location {
    const name = identAt(source, pos) orelse return null;
    return findDeclLocation(gpa, uri, name, tokens, false);
}

/// Like `definition`, but when the symbol is not declared in the current file
/// (e.g. it was brought in via `use { X } = @root()` / `import { X }`), search
/// the other modules' `pub` declarations and jump there. The returned `uri` is
/// owned by the caller.
pub fn definitionInModules(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
    others: []const ModuleSource,
) !?proto.Location {
    const name = identAt(source, pos) orelse return null;

    // Prefer a local declaration in the current file.
    if (try findDeclLocation(gpa, uri, name, tokens, false)) |loc| return loc;

    // Otherwise resolve to an exported declaration in another module.
    for (others) |m| {
        if (std.mem.eql(u8, m.uri, uri)) continue;
        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();
        var lexer = Lexer.init(m.source);
        const mod_tokens = lexer.scanAll(arena.allocator()) catch continue;
        if (try findDeclLocation(gpa, m.uri, name, mod_tokens, true)) |loc| return loc;
    }
    return null;
}

// ── Go to Definition: embedded "std" modules ──────────────────────────────────

/// One embedded "std" package module, keyed by bare name (no `std/` prefix).
pub const StdModule = struct {
    name: []const u8,
    source: []const u8,
};

/// Embedded "std" package modules (`import {…} from "std";`), bare names.
pub const std_modules: [comptime_pipeline.std_pkg_modules.len]StdModule = blk: {
    var mods: [comptime_pipeline.std_pkg_modules.len]StdModule = undefined;
    for (comptime_pipeline.std_pkg_modules, 0..) |spm, i| {
        mods[i] = .{ .name = spm.path["std/".len..], .source = spm.source };
    }
    break :blk mods;
};

pub fn findStdModule(name: []const u8) ?StdModule {
    for (std_modules) |m| {
        if (std.mem.eql(u8, m.name, name)) return m;
    }
    return null;
}

/// A definition resolved into an embedded "std" module. The caller decides
/// how to expose `module.source` to the editor (e.g. materialize to disk).
pub const StdDefinition = struct {
    module: StdModule,
    range: proto.Range,
};

/// Resolves the identifier at `pos` against the embedded "std" package
/// modules. Qualified access (`list.map`) restricts the search to the
/// qualifying module; a bare module name (`list`) jumps to the top of the
/// module. Unqualified names are searched across every std module, but only
/// when the file imports from "std".
pub fn definitionInStdModules(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
) !?StdDefinition {
    const span = identSpanAt(source, pos) orelse return null;
    const name = source[span.start..span.end];

    // `list.map` — the qualifier names the module.
    if (qualifierBefore(source, span.start)) |qual| {
        const mod = findStdModule(qual) orelse return null;
        return findStdDecl(gpa, mod, name);
    }

    // Bare module name (`list` in `import {list} from "std"`).
    if (findStdModule(name)) |mod| {
        const top = proto.Position{ .line = 0, .character = 0 };
        return .{ .module = mod, .range = .{ .start = top, .end = top } };
    }

    // Unqualified fallback — only meaningful when the file uses "std".
    if (std.mem.indexOf(u8, source, "from \"std\"") == null) return null;
    for (std_modules) |mod| {
        if (try findStdDecl(gpa, mod, name)) |sd| return sd;
    }
    return null;
}

/// Scans one std module for a `pub` declaration named `name`.
fn findStdDecl(gpa: std.mem.Allocator, mod: StdModule, name: []const u8) !?StdDefinition {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    var lexer = Lexer.init(mod.source);
    const tokens = lexer.scanAll(arena.allocator()) catch return null;
    const loc = try findDeclLocation(arena.allocator(), mod.name, name, tokens, true) orelse return null;
    return .{ .module = mod, .range = loc.range };
}

// ── Document Symbols ──────────────────────────────────────────────────────────

/// Returns all top-level symbol declarations in the document, with children
/// for struct/record members and enum variants.
/// The caller owns the returned slice and must free each `name` field.
pub fn documentSymbols(
    gpa: std.mem.Allocator,
    tokens: []const Token,
) ![]proto.DocumentSymbol {
    var syms: std.ArrayList(proto.DocumentSymbol) = .empty;
    errdefer {
        for (syms.items) |s| freeSymbol(gpa, s);
        syms.deinit(gpa);
    }

    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];

        // `test "name" { … }` — the name is a string literal, not an
        // identifier, so it gets its own branch (no children).
        if (tok.kind == .@"test") {
            var tj = i + 1;
            while (tj < tokens.len and tokens[tj].kind == .endOfFile) : (tj += 1) {}
            if (tj >= tokens.len or tokens[tj].kind != .stringLiteral) continue;

            const str_tok = tokens[tj];
            const sel_start = lsp_types.locToPosition(str_tok.line, str_tok.col);
            const sel_end = lsp_types.locToPosition(str_tok.line, str_tok.col + str_tok.lexeme.len);

            var range_end = sel_end;
            const block_end_idx = findBlockEnd(tokens, tj + 1);
            if (block_end_idx) |end_idx|
                range_end = lsp_types.locToPosition(tokens[end_idx].line, tokens[end_idx].col + 1);

            // Strip the surrounding quotes from the string lexeme for display.
            const raw = str_tok.lexeme;
            const name = if (raw.len >= 2 and raw[0] == '"') raw[1 .. raw.len - 1] else raw;

            try syms.append(gpa, .{
                .name = try gpa.dupe(u8, name),
                .kind = proto.SymbolKind.Method,
                .range = .{ .start = sel_start, .end = range_end },
                .selectionRange = .{ .start = sel_start, .end = sel_end },
                .children = null,
            });

            if (block_end_idx) |end_idx| i = end_idx else i = tj;
            continue;
        }

        var sym_kind: ?u32 = null;
        var decl_kind: ?TokenKind = null;
        for (decl_values) |k| {
            if (tok.kind == k) {
                sym_kind = tokenToSymbolKind(k);
                decl_kind = k;
                break;
            }
        }
        if (sym_kind == null) continue;

        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;

        const sel_start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const sel_end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);

        // Find the full range of the declaration (up to matching `}`).
        var range_end = sel_end;
        const block_end_idx = findBlockEnd(tokens, j + 1);
        if (block_end_idx) |end_idx| {
            range_end = lsp_types.locToPosition(tokens[end_idx].line, tokens[end_idx].col + 1);
        }

        // Collect children for types with bodies.
        var children: ?[]proto.DocumentSymbol = null;
        if (block_end_idx) |end_idx| {
            children = try collectChildren(gpa, tokens, j + 1, end_idx, decl_kind.?);
        }

        try syms.append(gpa, .{
            .name = try gpa.dupe(u8, name_tok.lexeme),
            .kind = sym_kind.?,
            .range = .{ .start = sel_start, .end = range_end },
            .selectionRange = .{ .start = sel_start, .end = sel_end },
            .children = children,
        });

        if (block_end_idx) |end_idx| {
            i = end_idx;
        } else {
            i = j;
        }
    }

    return syms.toOwnedSlice(gpa);
}

pub fn freeSymbol(gpa: std.mem.Allocator, sym: proto.DocumentSymbol) void {
    if (sym.children) |kids| {
        for (kids) |k| freeSymbol(gpa, k);
        gpa.free(kids);
    }
    gpa.free(sym.name);
}

fn findBlockEnd(tokens: []const Token, start: usize) ?usize {
    var k = start;
    while (k < tokens.len and tokens[k].kind != .leftBrace) : (k += 1) {
        if (tokens[k].kind == .semicolon or tokens[k].kind == .endOfFile) return null;
    }
    if (k >= tokens.len or tokens[k].kind != .leftBrace) return null;
    var depth: u32 = 1;
    k += 1;
    while (k < tokens.len and depth > 0) : (k += 1) {
        if (tokens[k].kind == .leftBrace) depth += 1;
        if (tokens[k].kind == .rightBrace) depth -= 1;
    }
    return if (depth == 0) k - 1 else null;
}

fn collectChildren(
    gpa: std.mem.Allocator,
    tokens: []const Token,
    start: usize,
    end: usize,
    parent_kind: TokenKind,
) !?[]proto.DocumentSymbol {
    var kids: std.ArrayList(proto.DocumentSymbol) = .empty;
    errdefer {
        for (kids.items) |k| freeSymbol(gpa, k);
        kids.deinit(gpa);
    }

    // Find the opening brace.
    var i = start;
    while (i < end and tokens[i].kind != .leftBrace) : (i += 1) {}
    if (i >= end) return null;
    i += 1; // skip past `{`

    while (i < end) : (i += 1) {
        const tok = tokens[i];

        switch (parent_kind) {
            .@"enum" => {
                // Enum variants are PascalCase identifiers at depth 0.
                if (tok.kind == .identifier and tok.lexeme.len > 0 and tok.lexeme[0] >= 'A' and tok.lexeme[0] <= 'Z') {
                    const s = lsp_types.locToPosition(tok.line, tok.col);
                    const e = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
                    try kids.append(gpa, .{
                        .name = try gpa.dupe(u8, tok.lexeme),
                        .kind = proto.SymbolKind.EnumMember,
                        .range = .{ .start = s, .end = e },
                        .selectionRange = .{ .start = s, .end = e },
                    });
                }
                // Methods inside enum.
                if (tok.kind == .@"fn") {
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = proto.SymbolKind.Function,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            .@"struct", .record => {
                // Fields: identifier followed by `:` (but not `self`).
                if (tok.kind == .identifier and i + 1 < end and tokens[i + 1].kind == .colon) {
                    if (!std.mem.eql(u8, tok.lexeme, "self")) {
                        const s = lsp_types.locToPosition(tok.line, tok.col);
                        const e = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, tok.lexeme),
                            .kind = proto.SymbolKind.Variable,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                    }
                }
                // Methods/getters/setters.
                if (tok.kind == .@"fn" or tok.kind == .get or tok.kind == .set) {
                    const child_kind: u32 = if (tok.kind == .@"fn") proto.SymbolKind.Function else proto.SymbolKind.Variable;
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = child_kind,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            .interface => {
                // Interface methods.
                if (tok.kind == .@"fn") {
                    var j = i + 1;
                    while (j < end and tokens[j].kind == .endOfFile) : (j += 1) {}
                    if (j < end and tokens[j].kind == .identifier) {
                        const nt = tokens[j];
                        const s = lsp_types.locToPosition(nt.line, nt.col);
                        const e = lsp_types.locToPosition(nt.line, nt.col + nt.lexeme.len);
                        try kids.append(gpa, .{
                            .name = try gpa.dupe(u8, nt.lexeme),
                            .kind = proto.SymbolKind.Function,
                            .range = .{ .start = s, .end = e },
                            .selectionRange = .{ .start = s, .end = e },
                        });
                        i = j;
                    }
                }
            },
            else => {},
        }

        // Skip nested brace blocks to avoid picking up inner members.
        if (tok.kind == .leftBrace) {
            var depth: u32 = 1;
            i += 1;
            while (i < end and depth > 0) : (i += 1) {
                if (tokens[i].kind == .leftBrace) depth += 1;
                if (tokens[i].kind == .rightBrace) depth -= 1;
            }
        }
    }

    if (kids.items.len == 0) {
        kids.deinit(gpa);
        return null;
    }
    const slice = try kids.toOwnedSlice(gpa);
    return slice;
}

// ── Internal helpers ──────────────────────────────────────────────────────────

const IdentSpan = struct { start: usize, end: usize };

/// Returns the byte span of the identifier at the given cursor position.
fn identSpanAt(source: []const u8, pos: proto.Position) ?IdentSpan {
    const offset = lsp_types.positionToOffset(source, pos);
    var i: usize = 0;
    while (i < source.len) {
        if (!isIdentStart(source[i])) {
            i += 1;
            continue;
        }
        const start = i;
        while (i < source.len and isIdentCont(source[i])) i += 1;
        if (offset >= start and offset < i) return .{ .start = start, .end = i };
    }
    return null;
}

/// Returns the identifier name at the given cursor position by scanning the source.
fn identAt(source: []const u8, pos: proto.Position) ?[]const u8 {
    const span = identSpanAt(source, pos) orelse return null;
    return source[span.start..span.end];
}

/// Returns the identifier immediately before `start` when the access is a
/// plain `qualifier.member` chain (e.g. the `list` in `list.map`). Optional
/// chaining (`?.`) and other receivers return null.
fn qualifierBefore(source: []const u8, start: usize) ?[]const u8 {
    if (start == 0 or source[start - 1] != '.') return null;
    const dot = start - 1;
    var i = dot;
    while (i > 0 and isIdentCont(source[i - 1])) i -= 1;
    if (i == dot) return null;
    if (!isIdentStart(source[i])) return null;
    return source[i..dot];
}

fn isIdentStart(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}
fn isIdentCont(c: u8) bool {
    return isIdentStart(c) or (c >= '0' and c <= '9');
}

fn tokenToSymbolKind(kind: TokenKind) u32 {
    return switch (kind) {
        .@"fn" => proto.SymbolKind.Function,
        .val => proto.SymbolKind.Variable,
        .record => proto.SymbolKind.Struct,
        .@"struct" => proto.SymbolKind.Struct,
        .@"enum" => proto.SymbolKind.Enum,
        .interface => proto.SymbolKind.Interface,
        else => proto.SymbolKind.Variable,
    };
}

/// Renders a Type as a human-readable string. The caller owns the result.
pub fn renderType(gpa: std.mem.Allocator, ty: *comptime_pipeline.Type) ![]u8 {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| blk: {
            if (n.args.len == 0) break :blk gpa.dupe(u8, n.name);
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, n.name);
            try buf.append(gpa, '<');
            for (n.args, 0..) |arg, idx| {
                if (idx > 0) try buf.appendSlice(gpa, ", ");
                const s = try renderType(gpa, arg);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            try buf.append(gpa, '>');
            break :blk buf.toOwnedSlice(gpa);
        },
        .func => |f| blk: {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, "fn(");
            for (f.params, 0..) |param, idx| {
                if (idx > 0) try buf.appendSlice(gpa, ", ");
                const s = try renderType(gpa, param);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            try buf.appendSlice(gpa, ") -> ");
            const rs = try renderType(gpa, f.ret);
            defer gpa.free(rs);
            try buf.appendSlice(gpa, rs);
            break :blk buf.toOwnedSlice(gpa);
        },
        .typeVar => |cell| switch (cell.state) {
            .unbound => gpa.dupe(u8, "_"),
            .generic => |id| std.fmt.allocPrint(gpa, "T{d}", .{id}),
            .link => |linked| renderType(gpa, linked),
        },
        .record => |fields| blk: {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, "record { ");
            for (fields, 0..) |f, idx| {
                if (idx > 0) try buf.appendSlice(gpa, ", ");
                try buf.appendSlice(gpa, f.name);
                try buf.appendSlice(gpa, ": ");
                const fs = try renderType(gpa, f.type_);
                defer gpa.free(fs);
                try buf.appendSlice(gpa, fs);
            }
            try buf.appendSlice(gpa, " }");
            break :blk buf.toOwnedSlice(gpa);
        },
        .union_ => |arms| blk: {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            for (arms, 0..) |arm, idx| {
                if (idx > 0) try buf.appendSlice(gpa, " | ");
                const s = try renderType(gpa, arm);
                defer gpa.free(s);
                try buf.appendSlice(gpa, s);
            }
            break :blk buf.toOwnedSlice(gpa);
        },
    };
}

// ── Type Definition ──────────────────────────────────────────────────────────

pub fn typeDefinition(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Location {
    const name = identAt(source, pos) orelse return null;

    // Find the type name for this binding.
    const type_name: []const u8 = blk: {
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, name)) continue;
            const t = b.type_.deref();
            switch (t.*) {
                .named => |n| break :blk n.name,
                .func => |f| {
                    const ret = f.ret.deref();
                    if (ret.* == .named) break :blk ret.named.name;
                },
                else => {},
            }
            break;
        }
        return null;
    };

    const decl_kws = [_]TokenKind{ .record, .@"struct", .@"enum", .interface, .type };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_type_kw = false;
        for (decl_kws) |k| {
            if (tok.kind == k) {
                is_type_kw = true;
                break;
            }
        }
        if (!is_type_kw) continue;

        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;

        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, type_name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }

    // Fallback: if the name was declared with `val Name = struct/record/enum`,
    // look for `val` followed by the type name.
    var k: usize = 0;
    while (k < tokens.len) : (k += 1) {
        if (tokens[k].kind != .val) continue;
        var j = k + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len) break;
        const name_tok = tokens[j];
        if (name_tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, name_tok.lexeme, type_name)) continue;

        const start = lsp_types.locToPosition(name_tok.line, name_tok.col);
        const end = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
        return .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        };
    }
    return null;
}

// ── Folding Ranges ───────────────────────────────────────────────────────────

pub fn foldingRanges(
    gpa: std.mem.Allocator,
    source: []const u8,
    tokens: []const Token,
) ![]proto.FoldingRange {
    var ranges: std.ArrayList(proto.FoldingRange) = .empty;
    errdefer ranges.deinit(gpa);

    // Track brace-delimited blocks for fn/struct/record/enum/interface/
    // implement and `test "name" { … }` blocks. The brace-finder skips the
    // intervening string-literal name, so `test` needs no special handling.
    const block_kws = [_]TokenKind{
        .@"fn", .@"struct", .record, .@"enum", .interface, .implement, .@"test",
    };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_block_kw = false;
        for (block_kws) |k| {
            if (tok.kind == k) {
                is_block_kw = true;
                break;
            }
        }
        if (!is_block_kw) continue;

        // Find the opening `{` for this declaration.
        var j = i + 1;
        while (j < tokens.len) : (j += 1) {
            if (tokens[j].kind == .leftBrace) break;
            if (tokens[j].kind == .semicolon or tokens[j].kind == .endOfFile) break;
        }
        if (j >= tokens.len or tokens[j].kind != .leftBrace) continue;

        const open_line = tokens[j].line;

        // Find the matching `}`.
        var depth: u32 = 1;
        var end_j = j + 1;
        while (end_j < tokens.len and depth > 0) : (end_j += 1) {
            if (tokens[end_j].kind == .leftBrace) depth += 1;
            if (tokens[end_j].kind == .rightBrace) depth -= 1;
        }
        if (depth != 0) continue;
        const close_line = tokens[end_j - 1].line;

        if (close_line > open_line) {
            try ranges.append(gpa, .{
                .startLine = @intCast(open_line -| 1),
                .endLine = @intCast(close_line -| 1),
                .kind = proto.FoldingRangeKind.Region,
            });
        }
    }

    // Track consecutive `import` statements as a foldable region.
    _ = source;
    i = 0;
    var import_start: ?usize = null;
    var import_end_line: u32 = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind == .import) {
            if (import_start == null) {
                import_start = @intCast(tokens[i].line -| 1);
            }
            // Scan to the end of this `import` statement (semicolon).
            while (i < tokens.len and tokens[i].kind != .semicolon) : (i += 1) {}
            if (i < tokens.len) {
                import_end_line = @intCast(tokens[i].line -| 1);
            }
        } else if (import_start != null) {
            // Non-use token: close the import block if it spans multiple lines.
            const start_line: u32 = @intCast(import_start.?);
            if (import_end_line > start_line) {
                try ranges.append(gpa, .{
                    .startLine = start_line,
                    .endLine = import_end_line,
                    .kind = proto.FoldingRangeKind.Imports,
                });
            }
            import_start = null;
        }
    }
    // Close trailing import block.
    if (import_start) |start| {
        const start_line: u32 = @intCast(start);
        if (import_end_line > start_line) {
            try ranges.append(gpa, .{
                .startLine = start_line,
                .endLine = import_end_line,
                .kind = proto.FoldingRangeKind.Imports,
            });
        }
    }

    return ranges.toOwnedSlice(gpa);
}

// ── Prepare Rename ───────────────────────────────────────────────────────────

pub fn prepareRename(
    source: []const u8,
    pos: proto.Position,
) ?proto.PrepareRenameResult {
    const name = identAt(source, pos) orelse return null;
    if (name.len == 0) return null;

    // Reject keywords and reserved words.
    if (isKeyword(name)) return null;

    const offset = lsp_types.positionToOffset(source, pos);
    var start = offset;
    while (start > 0 and isIdentCont(source[start - 1])) start -= 1;

    const start_pos = lsp_types.offsetToPosition(source, start);
    const end_pos = lsp_types.offsetToPosition(source, start + name.len);

    return .{
        .range = .{ .start = start_pos, .end = end_pos },
        .placeholder = name,
    };
}

fn isKeyword(name: []const u8) bool {
    const keywords = [_][]const u8{
        "as",       "assert",    "auto",   "await",    "break",   "case",
        "catch",    "comptime",  "const",  "continue", "declare", "default",
        "delegate", "derive",    "echo",   "else",     "enum",    "extends",
        "fn",       "for",       "from",   "get",      "if",      "implement",
        "import",   "interface", "loop",   "macro",    "new",     "null",
        "opaque",   "private",   "pub",    "record",   "return",  "self",
        "set",      "struct",    "syntax", "test",     "throw",   "todo",
        "true",     "false",     "try",    "type",     "use",     "val",
        "var",      "yield",     "Self",
    };
    for (keywords) |kw| {
        if (std.mem.eql(u8, name, kw)) return true;
    }
    return false;
}

// ── Code Actions ─────────────────────────────────────────────────────────────

pub fn codeActions(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    project_index: ?*index_mod.ProjectIndex,
) ![]proto.CodeAction {
    var actions: std.ArrayList(proto.CodeAction) = .empty;
    errdefer actions.deinit(gpa);

    try addTypeAnnotationActions(gpa, &actions, uri, source, range, tokens, bindings);
    try addRemoveUnusedImportActions(gpa, &actions, uri, source, range, tokens);
    try addMissingCasePatternsActions(gpa, &actions, uri, source, range, tokens, bindings);
    if (project_index) |idx| {
        try addMissingImportActions(gpa, &actions, uri, range, tokens, bindings, idx);
    }

    return actions.toOwnedSlice(gpa);
}

fn addTypeAnnotationActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !void {
    const decl_kws = [_]TokenKind{ .val, .@"var" };
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        var is_decl = false;
        for (decl_kws) |k| {
            if (tok.kind == k) {
                is_decl = true;
                break;
            }
        }
        if (!is_decl) continue;

        const tok_line: u32 = @intCast(tok.line -| 1);
        if (tok_line < range.start.line or tok_line > range.end.line) continue;

        // Next token should be the identifier name.
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .identifier) continue;

        const name_tok = tokens[j];

        // Check if there's already a type annotation (`:` after the name).
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind == .endOfFile) : (k += 1) {}
        if (k < tokens.len and tokens[k].kind == .colon) continue; // already annotated

        // Find the binding and get its inferred type.
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, name_tok.lexeme)) continue;
            const t = b.type_.deref();
            if (t.isUnbound()) break;
            const type_str = renderType(gpa, b.type_) catch break;
            defer gpa.free(type_str);

            const annotation = std.fmt.allocPrint(gpa, ": {s}", .{type_str}) catch break;
            defer gpa.free(annotation);

            // Insert position: right after the name token.
            const insert_pos = lsp_types.locToPosition(
                name_tok.line,
                name_tok.col + name_tok.lexeme.len,
            );

            _ = source;
            const title = std.fmt.allocPrint(gpa, "Add type annotation: {s}", .{type_str}) catch break;

            const edit_slice = gpa.alloc(proto.TextEdit, 1) catch break;
            edit_slice[0] = .{
                .range = .{ .start = insert_pos, .end = insert_pos },
                .newText = std.fmt.allocPrint(gpa, ": {s}", .{type_str}) catch break,
            };

            const doc_edit_slice = gpa.alloc(proto.TextDocumentEdit, 1) catch break;
            doc_edit_slice[0] = .{
                .textDocument = .{ .uri = uri, .version = null },
                .edits = edit_slice,
            };

            try actions.append(gpa, .{
                .title = title,
                .kind = proto.CodeActionKind.QuickFix,
                .edit = .{ .documentChanges = doc_edit_slice },
            });
            break;
        }
    }
}

fn addRemoveUnusedImportActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
) !void {
    // Scan for `import { name1, name2 } from "module";` patterns.
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .import) continue;

        const use_tok = tokens[i];
        const use_line: u32 = @intCast(use_tok.line -| 1);
        if (use_line < range.start.line or use_line > range.end.line) continue;

        // Collect imported names between `{` and `}`.
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind != .leftBrace) : (j += 1) {
            if (tokens[j].kind == .semicolon or tokens[j].kind == .endOfFile) break;
        }
        if (j >= tokens.len or tokens[j].kind != .leftBrace) continue;
        j += 1; // skip `{`

        var imported_names: std.ArrayList([]const u8) = .empty;
        defer imported_names.deinit(gpa);

        while (j < tokens.len and tokens[j].kind != .rightBrace) : (j += 1) {
            if (tokens[j].kind == .identifier) {
                try imported_names.append(gpa, tokens[j].lexeme);
            }
        }
        if (j >= tokens.len) continue;

        // Find the semicolon to get the full statement range.
        var stmt_end = j + 1;
        while (stmt_end < tokens.len and tokens[stmt_end].kind != .semicolon) : (stmt_end += 1) {}
        if (stmt_end >= tokens.len) continue;

        // Check each imported name: is it referenced elsewhere?
        for (imported_names.items) |name| {
            var used = false;
            for (tokens, 0..) |tok, ti| {
                if (ti >= i and ti <= stmt_end) continue; // skip the use statement itself
                if (tok.kind == .identifier and std.mem.eql(u8, tok.lexeme, name)) {
                    used = true;
                    break;
                }
            }
            if (used) continue;

            // This import is unused — offer removal.
            // For simplicity, if there's only one import in the statement, remove the whole line.
            // If multiple, just flag it (full multi-name editing is complex).
            if (imported_names.items.len == 1) {
                const line_start = lsp_types.locToPosition(use_tok.line, 1);
                const line_end_line = tokens[stmt_end].line;
                // Include the newline after the semicolon.
                const del_end = lsp_types.locToPosition(line_end_line + 1, 1);

                _ = source;
                const title = try std.fmt.allocPrint(gpa, "Remove unused import '{s}'", .{name});

                const edit_slice = try gpa.alloc(proto.TextEdit, 1);
                edit_slice[0] = .{
                    .range = .{ .start = line_start, .end = del_end },
                    .newText = try gpa.dupe(u8, ""),
                };

                const doc_edit_slice = try gpa.alloc(proto.TextDocumentEdit, 1);
                doc_edit_slice[0] = .{
                    .textDocument = .{ .uri = uri, .version = null },
                    .edits = edit_slice,
                };

                try actions.append(gpa, .{
                    .title = title,
                    .kind = proto.CodeActionKind.QuickFix,
                    .edit = .{ .documentChanges = doc_edit_slice },
                });
            }
        }
    }
}

fn addMissingCasePatternsActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    source: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) !void {
    _ = source;
    // Scan for `case <ident> {` patterns.
    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .case) continue;

        const case_line: u32 = @intCast(tokens[i].line -| 1);
        if (case_line < range.start.line or case_line > range.end.line) continue;

        // Next token should be an identifier (the subject).
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .identifier) continue;

        const subject_name = tokens[j].lexeme;

        // Find the subject's type via bindings.
        var enum_decl: ?ast.EnumDecl = null;
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, subject_name)) continue;
            const t = b.type_.deref();
            if (t.* != .named) break;
            // Look up the enum declaration by type name.
            for (bindings) |tb| {
                if (tb.decl != .@"enum") continue;
                if (std.mem.eql(u8, tb.name, t.named.name)) {
                    enum_decl = tb.decl.@"enum";
                    break;
                }
            }
            break;
        }
        const ed = enum_decl orelse continue;

        // Find the opening `{` of the case block.
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind != .leftBrace) : (k += 1) {
            if (tokens[k].kind == .semicolon or tokens[k].kind == .endOfFile) break;
        }
        if (k >= tokens.len or tokens[k].kind != .leftBrace) continue;

        // Find the matching `}`.
        var depth: u32 = 1;
        var case_end = k + 1;
        while (case_end < tokens.len and depth > 0) : (case_end += 1) {
            if (tokens[case_end].kind == .leftBrace) depth += 1;
            if (tokens[case_end].kind == .rightBrace) depth -= 1;
        }
        if (depth != 0) continue;
        const close_idx = case_end - 1;

        // Collect covered patterns (identifiers inside the case block at depth 0).
        var covered: std.ArrayList([]const u8) = .empty;
        defer covered.deinit(gpa);
        var ci = k + 1;
        var cdepth: u32 = 0;
        while (ci < close_idx) : (ci += 1) {
            if (tokens[ci].kind == .leftBrace) cdepth += 1;
            if (tokens[ci].kind == .rightBrace) cdepth -= 1;
            if (cdepth == 0 and tokens[ci].kind == .identifier) {
                try covered.append(gpa, tokens[ci].lexeme);
            }
        }

        // Find missing variants.
        var missing: std.ArrayList([]const u8) = .empty;
        defer missing.deinit(gpa);
        for (ed.variants) |v| {
            var found = false;
            for (covered.items) |c| {
                if (std.mem.eql(u8, c, v.name)) {
                    found = true;
                    break;
                }
            }
            if (!found) try missing.append(gpa, v.name);
        }

        if (missing.items.len == 0) continue;

        // Build the insertion text for missing patterns.
        var insert_buf: std.ArrayList(u8) = .empty;
        defer insert_buf.deinit(gpa);
        for (missing.items) |m| {
            try insert_buf.appendSlice(gpa, "    ");
            try insert_buf.appendSlice(gpa, m);
            try insert_buf.appendSlice(gpa, " -> todo;\n");
        }

        // Insert position: just before the closing `}`.
        const insert_pos = lsp_types.locToPosition(tokens[close_idx].line, tokens[close_idx].col);

        const title = try std.fmt.allocPrint(gpa, "Add {d} missing case pattern(s)", .{missing.items.len});

        const edit_slice = try gpa.alloc(proto.TextEdit, 1);
        edit_slice[0] = .{
            .range = .{ .start = insert_pos, .end = insert_pos },
            .newText = try insert_buf.toOwnedSlice(gpa),
        };

        const doc_edit_slice = try gpa.alloc(proto.TextDocumentEdit, 1);
        doc_edit_slice[0] = .{
            .textDocument = .{ .uri = uri, .version = null },
            .edits = edit_slice,
        };

        try actions.append(gpa, .{
            .title = title,
            .kind = proto.CodeActionKind.QuickFix,
            .edit = .{ .documentChanges = doc_edit_slice },
        });

        i = close_idx;
    }
}

fn addMissingImportActions(
    gpa: std.mem.Allocator,
    actions: *std.ArrayList(proto.CodeAction),
    uri: []const u8,
    range: proto.Range,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    idx: *index_mod.ProjectIndex,
) !void {
    // Find identifiers on the selected line(s) that are not in bindings.
    const decl_kws = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface, .@"var" };

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];
        if (tok.kind != .identifier) continue;

        const tok_line: u32 = @intCast(tok.line -| 1);
        if (tok_line < range.start.line or tok_line > range.end.line) continue;

        // Skip if it's a declaration name (preceded by val/fn/etc).
        if (i > 0) {
            var is_decl_name = false;
            for (decl_kws) |k| {
                if (tokens[i - 1].kind == k) {
                    is_decl_name = true;
                    break;
                }
            }
            if (is_decl_name) continue;
        }

        // Skip if it's in bindings.
        var in_bindings = false;
        for (bindings) |b| {
            if (std.mem.eql(u8, b.name, tok.lexeme)) {
                in_bindings = true;
                break;
            }
        }
        if (in_bindings) continue;

        // Skip common keywords/builtins that aren't real identifiers.
        if (isKeyword(tok.lexeme)) continue;
        if (std.mem.eql(u8, tok.lexeme, "self")) continue;
        if (std.mem.eql(u8, tok.lexeme, "print")) continue;
        if (std.mem.eql(u8, tok.lexeme, "console")) continue;

        // Check if the project index has this symbol.
        const sym = idx.findSymbol(tok.lexeme) orelse continue;

        // Don't suggest importing from the current file.
        if (std.mem.eql(u8, sym.uri, uri)) continue;

        const title = std.fmt.allocPrint(gpa, "Import '{s}' from \"{s}\"", .{ tok.lexeme, sym.module_name }) catch continue;

        // Build the import statement: `import { name } from "module";\n`
        const import_text = std.fmt.allocPrint(gpa, "import {{ {s} }} from \"{s}\";\n", .{ tok.lexeme, sym.module_name }) catch continue;

        // Insert at the top of the file (line 0, char 0).
        const edit_slice = gpa.alloc(proto.TextEdit, 1) catch continue;
        edit_slice[0] = .{
            .range = .{ .start = .{ .line = 0, .character = 0 }, .end = .{ .line = 0, .character = 0 } },
            .newText = import_text,
        };

        const doc_edit_slice = gpa.alloc(proto.TextDocumentEdit, 1) catch continue;
        doc_edit_slice[0] = .{
            .textDocument = .{ .uri = uri, .version = null },
            .edits = edit_slice,
        };

        try actions.append(gpa, .{
            .title = title,
            .kind = proto.CodeActionKind.QuickFix,
            .edit = .{ .documentChanges = doc_edit_slice },
        });
    }
}

// ── Module completion ────────────────────────────────────────────────────────

pub fn moduleCompletion(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    idx: *index_mod.ProjectIndex,
) !?[]proto.CompletionItem {
    const offset = lsp_types.positionToOffset(source, pos);

    // Check if cursor is inside `use ... from "..."` by looking for `from` + `"` before cursor.
    if (!cursorInFromString(source, offset)) return null;

    const module_names = idx.getModuleNames();
    if (module_names.len == 0) return null;

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| gpa.free(it.label);
        items.deinit(gpa);
    }

    for (module_names) |name| {
        try items.append(gpa, .{
            .label = try gpa.dupe(u8, name),
            .kind = proto.CompletionItemKind.Module,
            .detail = null,
        });
    }

    const slice = try items.toOwnedSlice(gpa);
    return slice;
}

fn cursorInFromString(source: []const u8, offset: usize) bool {
    // Walk backward from cursor to find opening `"` then `from`.
    var i = offset;
    if (i > 0 and source[i - 1] == '"') i -= 1; // skip quote at cursor
    while (i > 0 and i < source.len and source[i] != '"') {
        if (source[i] == '\n') return false;
        i -= 1;
    }
    if (i == 0 or source[i] != '"') return false;
    // Now walk backward past whitespace to find `from`.
    var j = i;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j < 4) return false;
    return std.mem.eql(u8, source[j - 4 .. j], "from");
}

// ── Cross-module references ──────────────────────────────────────────────────

pub fn crossModuleReferences(
    gpa: std.mem.Allocator,
    io: std.Io,
    source: []const u8,
    pos: proto.Position,
    current_uri: []const u8,
    current_tokens: []const Token,
    include_declaration: bool,
    idx: *index_mod.ProjectIndex,
) ![]proto.Location {
    const name = identAt(source, pos) orelse return &.{};

    var locs: std.ArrayList(proto.Location) = .empty;
    errdefer {
        for (locs.items) |l| gpa.free(l.uri);
        locs.deinit(gpa);
    }

    // First add references from the current file.
    const local_refs = try references(gpa, current_uri, source, pos, current_tokens, include_declaration);
    defer gpa.free(local_refs);
    for (local_refs) |loc| {
        try locs.append(gpa, loc);
    }

    // Collect unique URIs of files that have matching symbols.
    var seen_uris: std.StringHashMap(void) = .init(gpa);
    defer seen_uris.deinit();
    try seen_uris.put(current_uri, {});

    const all_syms = idx.getAllSymbols();
    for (all_syms) |sym| {
        if (seen_uris.contains(sym.uri)) continue;
        if (!std.mem.eql(u8, sym.name, name)) continue;
        try seen_uris.put(sym.uri, {});
    }

    // Re-lex each external file and find exact positions of every identifier match.
    var it = seen_uris.keyIterator();
    while (it.next()) |key_ptr| {
        const ext_uri = key_ptr.*;
        if (std.mem.eql(u8, ext_uri, current_uri)) continue;

        const ext_path = lsp_types.uriToPath(ext_uri);
        const cwd = std.Io.Dir.cwd();
        const ext_source = cwd.readFileAlloc(io, ext_path, gpa, .limited(10 * 1024 * 1024)) catch continue;
        defer gpa.free(ext_source);

        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();

        var lexer = Lexer.init(ext_source);
        const ext_tokens = lexer.scanAll(arena.allocator()) catch continue;

        for (ext_tokens) |tok| {
            if (tok.kind != .identifier) continue;
            if (!std.mem.eql(u8, tok.lexeme, name)) continue;

            const start = lsp_types.locToPosition(tok.line, tok.col);
            const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
            try locs.append(gpa, .{
                .uri = try gpa.dupe(u8, ext_uri),
                .range = .{ .start = start, .end = end },
            });
        }
    }

    return locs.toOwnedSlice(gpa);
}

/// Cross-module rename: applies rename in current file + all external files
/// that reference the symbol. Returns a list of (uri, edits) pairs encoded
/// as a JSON body for the WorkspaceEdit response.
pub fn crossModuleRename(
    gpa: std.mem.Allocator,
    io: std.Io,
    source: []const u8,
    pos: proto.Position,
    new_name: []const u8,
    current_uri: []const u8,
    current_tokens: []const Token,
    idx: *index_mod.ProjectIndex,
) !CrossModuleRenameResult {
    const name = identAt(source, pos) orelse return .{ .entries = &.{} };

    var entries: std.ArrayList(RenameFileEntry) = .empty;
    errdefer {
        for (entries.items) |e| {
            gpa.free(e.uri);
            gpa.free(e.edits);
        }
        entries.deinit(gpa);
    }

    // Current file edits.
    const cur_edits = try rename(gpa, source, pos, new_name, current_tokens);
    if (cur_edits.len > 0) {
        try entries.append(gpa, .{
            .uri = try gpa.dupe(u8, current_uri),
            .edits = cur_edits,
        });
    }

    // External files.
    var seen_uris: std.StringHashMap(void) = .init(gpa);
    defer seen_uris.deinit();
    try seen_uris.put(current_uri, {});

    const all_syms = idx.getAllSymbols();
    for (all_syms) |sym| {
        if (seen_uris.contains(sym.uri)) continue;
        if (!std.mem.eql(u8, sym.name, name)) continue;
        try seen_uris.put(sym.uri, {});
    }

    var it = seen_uris.keyIterator();
    while (it.next()) |key_ptr| {
        const ext_uri = key_ptr.*;
        if (std.mem.eql(u8, ext_uri, current_uri)) continue;

        const ext_path = lsp_types.uriToPath(ext_uri);
        const cwd = std.Io.Dir.cwd();
        const ext_source = cwd.readFileAlloc(io, ext_path, gpa, .limited(10 * 1024 * 1024)) catch continue;
        defer gpa.free(ext_source);

        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();

        var lexer = Lexer.init(ext_source);
        const ext_tokens = lexer.scanAll(arena.allocator()) catch continue;

        var file_edits: std.ArrayList(proto.TextEdit) = .empty;
        for (ext_tokens) |tok| {
            if (tok.kind != .identifier) continue;
            if (!std.mem.eql(u8, tok.lexeme, name)) continue;

            const start = lsp_types.locToPosition(tok.line, tok.col);
            const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
            file_edits.append(gpa, .{
                .range = .{ .start = start, .end = end },
                .newText = new_name,
            }) catch continue;
        }

        if (file_edits.items.len > 0) {
            try entries.append(gpa, .{
                .uri = try gpa.dupe(u8, ext_uri),
                .edits = try file_edits.toOwnedSlice(gpa),
            });
        } else {
            file_edits.deinit(gpa);
        }
    }

    return .{ .entries = try entries.toOwnedSlice(gpa) };
}

pub const RenameFileEntry = struct {
    uri: []const u8,
    edits: []const proto.TextEdit,
};

pub const CrossModuleRenameResult = struct {
    entries: []const RenameFileEntry,
};

// ── Signature Help ────────────────────────────────────────────────────────────

/// Returns signature help for the function call under the cursor, or null if
/// the cursor is not inside a call. All strings in the result are allocated in
/// `arena` — caller deinits the arena when done.
pub fn signatureHelp(
    arena: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.SignatureHelp {
    const offset = lsp_types.positionToOffset(source, pos);

    // Walk backwards to find the opening `(` of the current call at depth 0.
    var depth: u32 = 0;
    var active_param: u32 = 0;
    var paren_idx: ?usize = null;

    var i: usize = offset;
    while (i > 0) {
        i -= 1;
        switch (source[i]) {
            ')', ']' => depth += 1,
            '[' => {
                if (depth == 0) break; // index access, not a call
                depth -= 1;
            },
            '(' => {
                if (depth == 0) {
                    paren_idx = i;
                    break;
                }
                depth -= 1;
            },
            ',' => if (depth == 0) {
                active_param += 1;
            },
            else => {},
        }
    }

    const paren = paren_idx orelse return null;

    // Find the identifier immediately before `(` (skip whitespace).
    var j = paren;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j == 0 or !isIdentCont(source[j - 1])) return null;
    const name_end = j;
    while (j > 0 and isIdentCont(source[j - 1])) j -= 1;
    const fn_name = source[j..name_end];

    // Find the binding whose name matches and has a function type.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, fn_name)) continue;
        const t = b.type_.deref();
        if (t.* != .func) continue;
        const func = t.*.func;

        // Build "name(T1, T2) -> R" label.
        var lbl: std.ArrayList(u8) = .empty;
        try lbl.appendSlice(arena, fn_name);
        try lbl.append(arena, '(');
        for (func.params, 0..) |param_ty, pi| {
            if (pi > 0) try lbl.appendSlice(arena, ", ");
            const ps = try renderType(arena, param_ty);
            try lbl.appendSlice(arena, ps);
        }
        try lbl.appendSlice(arena, ") -> ");
        try lbl.appendSlice(arena, try renderType(arena, func.ret));

        // Build ParameterInformation slice.
        const params = try arena.alloc(proto.ParameterInformation, func.params.len);
        for (func.params, 0..) |param_ty, pi| {
            params[pi] = .{ .label = try renderType(arena, param_ty) };
        }

        const sigs = try arena.alloc(proto.SignatureInformation, 1);
        sigs[0] = .{
            .label = try lbl.toOwnedSlice(arena),
            .parameters = if (params.len > 0) params else null,
        };

        const active = if (func.params.len > 0)
            @min(active_param, @as(u32, @intCast(func.params.len - 1)))
        else
            0;

        return proto.SignatureHelp{
            .signatures = sigs,
            .activeSignature = 0,
            .activeParameter = active,
        };
    }

    // No matching binding — the call may be an interface method on a builtin
    // receiver (`42.clamp(|)`, `xs.map(|)`). Resolve via the receiver before the
    // method name.
    if (j > 0 and source[j - 1] == '.') {
        var r = j - 1; // index of the '.'
        while (r > 0 and isIdentCont(source[r - 1])) r -= 1;
        const receiver = source[r .. j - 1];
        if (try builtinMethodSignature(arena, receiver, fn_name, active_param, bindings)) |sh|
            return sh;
    }

    return null;
}

/// Builds signature help for an interface method on a builtin receiver. The
/// receiver's `self` parameter is dropped — the caller fills the remaining
/// arguments. Returns null when the receiver/method has no interface entry.
fn builtinMethodSignature(
    arena: std.mem.Allocator,
    receiver: []const u8,
    method: []const u8,
    active_param: u32,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.SignatureHelp {
    const iface = receiverBuiltinInterface(receiver, bindings) orelse return null;
    const members = (try collectInterfaceMembers(arena, iface)) orelse return null;

    for (members) |m| {
        if (!m.is_fn or !std.mem.eql(u8, m.name, method)) continue;

        // Re-lex the signature to split the parameter list, dropping `self`.
        var lexer = Lexer.init(m.sig);
        const tokens = lexer.scanAll(arena) catch return null;
        var lp: ?usize = null;
        var rp: ?usize = null;
        var depth: u32 = 0;
        for (tokens, 0..) |t, ti| {
            if (t.kind == .leftParenthesis) {
                if (depth == 0 and lp == null) lp = ti;
                depth += 1;
            } else if (t.kind == .rightParenthesis) {
                depth -= 1;
                if (depth == 0) {
                    rp = ti;
                    break;
                }
            }
        }

        var params: std.ArrayList(proto.ParameterInformation) = .empty;
        if (lp != null and rp != null) {
            // Split top-level params by commas between `(` and `)`.
            var seg_start = tokenOffset(m.sig, tokens[lp.? + 1]);
            var pd: u32 = 0;
            var ti = lp.? + 1;
            while (ti <= rp.?) : (ti += 1) {
                const tk = tokens[ti].kind;
                if (tk == .leftParenthesis) pd += 1;
                if (tk == .rightParenthesis) {
                    if (pd == 0) {
                        try pushParam(arena, &params, m.sig[seg_start..tokenOffset(m.sig, tokens[ti])]);
                        break;
                    }
                    pd -= 1;
                }
                if (pd == 0 and tk == .comma) {
                    try pushParam(arena, &params, m.sig[seg_start..tokenOffset(m.sig, tokens[ti])]);
                    seg_start = tokenOffset(m.sig, tokens[ti + 1]);
                }
            }
        }

        const nparams = params.items.len;
        const sigs = try arena.alloc(proto.SignatureInformation, 1);
        sigs[0] = .{
            .label = try arena.dupe(u8, m.sig),
            .parameters = if (nparams > 0) try params.toOwnedSlice(arena) else null,
        };
        const active = if (nparams > 0)
            @min(active_param, @as(u32, @intCast(nparams - 1)))
        else
            0;
        return proto.SignatureHelp{
            .signatures = sigs,
            .activeSignature = 0,
            .activeParameter = active,
        };
    }
    return null;
}

/// Appends a trimmed parameter to `params`, skipping the implicit `self`.
fn pushParam(
    arena: std.mem.Allocator,
    params: *std.ArrayList(proto.ParameterInformation),
    raw: []const u8,
) !void {
    const p = std.mem.trim(u8, raw, " \t\r\n,");
    if (p.len == 0) return;
    if (std.mem.eql(u8, p, "self") or std.mem.startsWith(u8, p, "self:") or
        std.mem.startsWith(u8, p, "self ")) return;
    try params.append(arena, .{ .label = try arena.dupe(u8, p) });
}

// ── Inlay Hints ───────────────────────────────────────────────────────────────

/// Returns inlay hints within `range`. Three kinds are produced, all derived
/// from the typed top-level `bindings`:
///   • inferred-type hints after `val x = …` (suppressed when annotated)
///   • parameter-name hints before call arguments (`fn(»name:« arg)`)
///   • lambda parameter-type hints, when a lambda is passed to a function whose
///     matching parameter is a function type (`{ x»: i32« -> … }`)
/// All strings in the result are allocated in `arena`.
pub fn inlayHints(
    arena: std.mem.Allocator,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
    range: proto.Range,
) ![]proto.InlayHint {
    var hints: std.ArrayList(proto.InlayHint) = .empty;

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];

        // ── inferred-type hint on `val name = …` ──
        if (tok.kind == .val) {
            const j = nextSignificantIdx(tokens, i) orelse continue;
            if (tokens[j].kind != .identifier) continue;
            const name_tok = tokens[j];

            // Annotated (`val name: T = …`) → suppress: a `:` before `=`/`;`.
            var annotated = false;
            var k = j + 1;
            while (k < tokens.len) : (k += 1) {
                switch (tokens[k].kind) {
                    .colon => {
                        annotated = true;
                        break;
                    },
                    .equal, .semicolon, .endOfFile => break,
                    else => {},
                }
            }

            if (!annotated) {
                const hint_pos = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
                if (posInRange(hint_pos, range)) {
                    if (findBinding(bindings, name_tok.lexeme)) |b| {
                        if (!b.type_.deref().isUnbound()) {
                            const type_str = try renderType(arena, b.type_);
                            try hints.append(arena, .{
                                .position = hint_pos,
                                .label = try std.fmt.allocPrint(arena, ": {s}", .{type_str}),
                                .kind = proto.InlayHintKind.Type,
                                .paddingLeft = true,
                            });
                        }
                    }
                }
            }
            i = j;
            continue;
        }

        // ── call-site hints: `callee( … )` for a known top-level fn ──
        if (tok.kind == .identifier) {
            const ni = nextSignificantIdx(tokens, i) orelse continue;
            if (tokens[ni].kind != .leftParenthesis) continue;
            // Skip declarations (`fn name(`) and method calls (`recv.name(`).
            const pk = prevSignificantKind(tokens, i);
            if (pk == .@"fn" or pk == .dot or pk == .questionDot) continue;
            if (fnDeclParams(bindings, tok.lexeme)) |params| {
                try emitCallHints(arena, &hints, tokens, ni, params, range);
            }
        }
    }

    return hints.toOwnedSlice(arena);
}

/// Emits parameter-name and lambda-type hints for the call whose `(` is at
/// `lparen_idx`, mapping top-level arguments to `params` by position.
fn emitCallHints(
    arena: std.mem.Allocator,
    hints: *std.ArrayList(proto.InlayHint),
    tokens: []const Token,
    lparen_idx: usize,
    params: []const ast.Param,
    range: proto.Range,
) !void {
    var depth: u32 = 1;
    var arg_index: usize = 0;
    var at_arg_start = true; // next significant token begins an argument
    var idx: usize = lparen_idx + 1;
    while (idx < tokens.len and depth > 0) : (idx += 1) {
        const t = tokens[idx];
        switch (t.kind) {
            .endOfFile, .commentNormal, .commentDoc, .commentModule => continue,
            .leftParenthesis, .leftSquareBracket => {
                depth += 1;
                at_arg_start = false;
                continue;
            },
            .rightParenthesis, .rightSquareBracket => {
                depth -= 1;
                at_arg_start = false;
                continue;
            },
            .leftBrace => {
                // A lambda argument `{ p -> … }`.
                if (depth == 1 and at_arg_start and arg_index < params.len) {
                    try emitLambdaTypeHints(arena, hints, tokens, idx, params[arg_index], range);
                }
                depth += 1;
                at_arg_start = false;
                continue;
            },
            .rightBrace => {
                depth -= 1;
                at_arg_start = false;
                continue;
            },
            .comma => {
                if (depth == 1) {
                    arg_index += 1;
                    at_arg_start = true;
                }
                continue;
            },
            else => {},
        }

        if (depth == 1 and at_arg_start) {
            at_arg_start = false;
            if (arg_index < params.len) {
                const p = params[arg_index];
                // Skip when redundant (arg is the bare param name) or already
                // a named argument (`name: value`).
                const nk = nextSignificantKind(tokens, idx);
                const is_named = t.kind == .identifier and nk == .colon;
                const is_redundant = t.kind == .identifier and
                    std.mem.eql(u8, t.lexeme, p.name) and
                    (nk == .comma or nk == .rightParenthesis or nk == null);
                if (!is_named and !is_redundant and p.name.len > 0) {
                    const pos = lsp_types.locToPosition(t.line, t.col);
                    if (posInRange(pos, range)) {
                        try hints.append(arena, .{
                            .position = pos,
                            .label = try std.fmt.allocPrint(arena, "{s}:", .{p.name}),
                            .kind = proto.InlayHintKind.Parameter,
                            .paddingRight = true,
                        });
                    }
                }
            }
        }
    }
}

/// For a lambda `{ a, b -> … }` opening at `brace_idx`, emits a `: T` hint after
/// each parameter name, taken from the callee's declared `fn(...)` parameter
/// signature — either the legacy `syntax` `param.fnType` or a plain
/// `TypeRef.function`. No-op when `param` isn't a function-typed param.
fn emitLambdaTypeHints(
    arena: std.mem.Allocator,
    hints: *std.ArrayList(proto.InlayHint),
    tokens: []const Token,
    brace_idx: usize,
    param: ast.Param,
    range: proto.Range,
) !void {
    // Resolve the declared parameter-type strings of the callee's fn-type param.
    var param_types: std.ArrayList([]const u8) = .empty;
    if (param.fnType) |fn_type| {
        for (fn_type.params) |p| try param_types.append(arena, p.typeName);
    } else switch (param.typeRef) {
        .function => |f| for (f.params) |p| {
            var buf: std.ArrayList(u8) = .empty;
            try appendTypeRef(arena, &buf, p);
            try param_types.append(arena, try buf.toOwnedSlice(arena));
        },
        else => return,
    }
    if (param_types.items.len == 0) return;

    // Collect lambda param-name tokens between `{` and `->` at brace depth 1.
    var lp: usize = 0;
    var idx = brace_idx + 1;
    while (idx < tokens.len) : (idx += 1) {
        switch (tokens[idx].kind) {
            .rightArrow, .rightBrace, .endOfFile => break,
            .identifier => {
                if (lp < param_types.items.len and param_types.items[lp].len > 0) {
                    const name_tok = tokens[idx];
                    const pos = lsp_types.locToPosition(name_tok.line, name_tok.col + name_tok.lexeme.len);
                    if (posInRange(pos, range)) {
                        try hints.append(arena, .{
                            .position = pos,
                            .label = try std.fmt.allocPrint(arena, ": {s}", .{param_types.items[lp]}),
                            .kind = proto.InlayHintKind.Type,
                            .paddingLeft = true,
                        });
                    }
                }
                lp += 1;
            },
            else => {},
        }
    }
}

fn findBinding(bindings: []const comptime_pipeline.TypedBinding, name: []const u8) ?comptime_pipeline.TypedBinding {
    for (bindings) |b| {
        if (std.mem.eql(u8, b.name, name)) return b;
    }
    return null;
}

/// The declared parameters of a top-level `fn` binding, or null.
fn fnDeclParams(bindings: []const comptime_pipeline.TypedBinding, name: []const u8) ?[]const ast.Param {
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, name)) continue;
        return switch (b.decl) {
            .@"fn" => |f| f.params,
            else => null,
        };
    }
    return null;
}

/// Index of the next non-trivia token after `i`, or null at EOF.
fn nextSignificantIdx(tokens: []const Token, i: usize) ?usize {
    var j = i + 1;
    while (j < tokens.len) : (j += 1) {
        switch (tokens[j].kind) {
            .endOfFile, .commentNormal, .commentDoc, .commentModule => continue,
            else => return j,
        }
    }
    return null;
}

/// Kind of the previous non-trivia token before `i`, or null at the start.
fn prevSignificantKind(tokens: []const Token, i: usize) ?TokenKind {
    if (i == 0) return null;
    var j = i;
    while (j > 0) {
        j -= 1;
        switch (tokens[j].kind) {
            .endOfFile, .commentNormal, .commentDoc, .commentModule => continue,
            else => return tokens[j].kind,
        }
    }
    return null;
}

fn posInRange(pos: proto.Position, range: proto.Range) bool {
    if (pos.line < range.start.line or pos.line > range.end.line) return false;
    if (pos.line == range.start.line and pos.character < range.start.character) return false;
    if (pos.line == range.end.line and pos.character > range.end.character) return false;
    return true;
}

// ── Semantic Tokens ─────────────────────────────────────────────────────────

/// One classified token in absolute coordinates (0-based line/char). The server
/// delta-encodes a sorted slice of these into the LSP wire format.
pub const SemToken = struct {
    line: u32,
    start: u32,
    len: u32,
    type_idx: u32,
    mods: u32,
};

/// The lexical container a token sits directly inside — drives the
/// method-vs-function and enum-member distinctions.
const ContainerKind = enum { none, interface, @"struct", record, @"enum", extend, implement };

/// Classifies `tokens` into semantic tokens, driven by lexical kind, light
/// structural tracking (container / param / paren nesting), and a name→category
/// map built from the typed top-level `bindings`. Returns absolute-coordinate
/// tokens in source order. All memory is allocated in `arena`.
///
/// This is intentionally token-driven (like hover / inlay / symbols) rather than
/// AST-walking: top-level `bindings` give symbol categories, and the structural
/// scan supplies the rest (declaration sites, receivers, params, enum members).
pub fn semanticTokens(
    arena: std.mem.Allocator,
    tokens: []const Token,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]SemToken {
    var out: std.ArrayList(SemToken) = .empty;

    var containers: std.ArrayList(ContainerKind) = .empty;
    defer containers.deinit(arena);
    var pending_container: ContainerKind = .none;

    var paren_depth: u32 = 0;
    var fn_param_depth: ?u32 = null; // paren depth at which a fn param list opened
    var expect_fn_name = false; // just saw `fn` → next ident is the name
    var expect_fn_paren = false; // saw `fn name` → next `(` opens params
    var saw_comptime = false; // previous significant token was `comptime`
    var prev_kind: ?TokenKind = null; // previous significant (non-trivia) token

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        const tok = tokens[i];

        // Comments emit a token but are trivia for context purposes.
        switch (tok.kind) {
            .endOfFile => continue,
            .commentNormal, .commentDoc, .commentModule => {
                try emitSem(arena, &out, tok, proto.SemanticTokenTypes.comment, 0);
                continue;
            },
            else => {},
        }

        // Structural punctuation: never classified, but tracks nesting.
        switch (tok.kind) {
            .leftBrace => {
                try containers.append(arena, pending_container);
                pending_container = .none;
                prev_kind = tok.kind;
                continue;
            },
            .rightBrace => {
                if (containers.items.len > 0) _ = containers.pop();
                prev_kind = tok.kind;
                continue;
            },
            .leftParenthesis => {
                if (expect_fn_paren or prev_kind == .@"fn") {
                    if (fn_param_depth == null) fn_param_depth = paren_depth;
                    expect_fn_paren = false;
                }
                expect_fn_name = false;
                paren_depth += 1;
                prev_kind = tok.kind;
                continue;
            },
            .rightParenthesis => {
                if (paren_depth > 0) paren_depth -= 1;
                if (fn_param_depth) |d| {
                    if (paren_depth == d) fn_param_depth = null;
                }
                prev_kind = tok.kind;
                continue;
            },
            else => {},
        }

        const container_top: ContainerKind = if (containers.items.len > 0)
            containers.items[containers.items.len - 1]
        else
            .none;

        // Container keywords arm `pending_container` for the next `{`.
        switch (tok.kind) {
            .interface => pending_container = .interface,
            .@"struct" => pending_container = .@"struct",
            .record => pending_container = .record,
            .@"enum" => pending_container = .@"enum",
            .extend, .extends => pending_container = .extend,
            .implement => pending_container = .implement,
            else => {},
        }

        // `*` immediately before `fn` is the effect marker of a `*fn`.
        if (tok.kind == .star) {
            if (nextSignificantKind(tokens, i) == .@"fn")
                try emitSem(arena, &out, tok, proto.SemanticTokenTypes.keyword, 0);
            prev_kind = tok.kind;
            saw_comptime = false;
            continue;
        }

        if (isKeywordKind(tok.kind)) {
            if (tok.kind == .@"fn") expect_fn_name = true;
            if (tok.kind == .selfType) {
                try emitSem(arena, &out, tok, proto.SemanticTokenTypes.type_, proto.SemanticTokenModifiers.defaultLibrary);
            } else {
                try emitSem(arena, &out, tok, proto.SemanticTokenTypes.keyword, 0);
            }
            saw_comptime = (tok.kind == .@"comptime");
            prev_kind = tok.kind;
            continue;
        }

        if (tok.kind == .builtinIdent) {
            // `@Name` (PascalCase) → builtin type; `@name` → builtin fn.
            const is_type = tok.lexeme.len >= 2 and std.ascii.isUpper(tok.lexeme[1]);
            const ty = if (is_type) proto.SemanticTokenTypes.type_ else proto.SemanticTokenTypes.function;
            try emitSem(arena, &out, tok, ty, proto.SemanticTokenModifiers.defaultLibrary);
            prev_kind = tok.kind;
            saw_comptime = false;
            continue;
        }

        if (tok.kind == .identifier) {
            const pk = prev_kind;
            const nk = nextSignificantKind(tokens, i);
            const in_params = fn_param_depth != null and paren_depth == fn_param_depth.? + 1;

            var type_idx: u32 = proto.SemanticTokenTypes.variable;
            var mods: u32 = 0;

            if (expect_fn_name) {
                expect_fn_name = false;
                expect_fn_paren = true;
                type_idx = switch (container_top) {
                    .interface, .@"struct", .record, .extend, .implement => proto.SemanticTokenTypes.method,
                    else => proto.SemanticTokenTypes.function,
                };
                mods |= proto.SemanticTokenModifiers.declaration;
            } else if (pk == .val or pk == .record or pk == .@"struct" or pk == .@"enum" or pk == .interface) {
                type_idx = lookupCategory(bindings, tok.lexeme) orelse switch (pk.?) {
                    .record, .@"struct" => proto.SemanticTokenTypes.type_,
                    .@"enum" => proto.SemanticTokenTypes.@"enum",
                    .interface => proto.SemanticTokenTypes.interface,
                    else => proto.SemanticTokenTypes.variable,
                };
                mods |= proto.SemanticTokenModifiers.declaration;
            } else if (pk == .dot or pk == .questionDot) {
                type_idx = if (nk == .leftParenthesis) proto.SemanticTokenTypes.method else proto.SemanticTokenTypes.property;
            } else if (in_params and (pk == .leftParenthesis or pk == .comma or pk == .@"comptime")) {
                type_idx = proto.SemanticTokenTypes.parameter;
                if (saw_comptime) mods |= proto.SemanticTokenModifiers.readonly;
            } else if (container_top == .@"enum" and paren_depth == 0 and (pk == .leftBrace or pk == .comma)) {
                type_idx = proto.SemanticTokenTypes.enumMember;
            } else if (lookupCategory(bindings, tok.lexeme)) |cat| {
                type_idx = cat;
            } else if (isPrimitiveType(tok.lexeme)) {
                type_idx = proto.SemanticTokenTypes.type_;
                mods |= proto.SemanticTokenModifiers.defaultLibrary;
            } else if (nk == .leftParenthesis) {
                type_idx = proto.SemanticTokenTypes.function;
            }

            try emitSem(arena, &out, tok, type_idx, mods);
            prev_kind = tok.kind;
            saw_comptime = false;
            continue;
        }

        // Operators / literals / punctuation: not classified, but still the
        // "previous significant token" for the next identifier's context.
        prev_kind = tok.kind;
        saw_comptime = false;
    }

    return out.toOwnedSlice(arena);
}

/// Delta-encodes semantic tokens (sorted by position) into the LSP wire format:
/// 5 ints per token — [deltaLine, deltaStartChar, length, tokenType, modifiers].
pub fn encodeSemanticTokens(arena: std.mem.Allocator, toks: []const SemToken) ![]u32 {
    const data = try arena.alloc(u32, toks.len * 5);
    var prev_line: u32 = 0;
    var prev_start: u32 = 0;
    for (toks, 0..) |t, idx| {
        const dl = t.line - prev_line;
        const ds = if (dl == 0) t.start - prev_start else t.start;
        data[idx * 5 + 0] = dl;
        data[idx * 5 + 1] = ds;
        data[idx * 5 + 2] = t.len;
        data[idx * 5 + 3] = t.type_idx;
        data[idx * 5 + 4] = t.mods;
        prev_line = t.line;
        prev_start = t.start;
    }
    return data;
}

fn emitSem(arena: std.mem.Allocator, out: *std.ArrayList(SemToken), tok: Token, type_idx: u32, mods: u32) !void {
    try out.append(arena, .{
        .line = @intCast(tok.line -| 1),
        .start = @intCast(tok.col -| 1),
        .len = @intCast(tok.lexeme.len),
        .type_idx = type_idx,
        .mods = mods,
    });
}

/// Maps a top-level binding's declaration kind to a semantic token type.
fn lookupCategory(bindings: []const comptime_pipeline.TypedBinding, name: []const u8) ?u32 {
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, name)) continue;
        return switch (b.decl) {
            .@"fn" => proto.SemanticTokenTypes.function,
            .record, .@"struct" => proto.SemanticTokenTypes.type_,
            .@"enum" => proto.SemanticTokenTypes.@"enum",
            .interface => proto.SemanticTokenTypes.interface,
            .val => proto.SemanticTokenTypes.variable,
            else => null,
        };
    }
    return null;
}

/// The kind of the next non-trivia token after index `i`, or null at EOF.
fn nextSignificantKind(tokens: []const Token, i: usize) ?TokenKind {
    var j = i + 1;
    while (j < tokens.len) : (j += 1) {
        switch (tokens[j].kind) {
            .endOfFile, .commentNormal, .commentDoc, .commentModule => continue,
            else => return tokens[j].kind,
        }
    }
    return null;
}

fn isPrimitiveType(name: []const u8) bool {
    const prims = [_][]const u8{
        "bool", "string", "void",  "char", "byte",
        "i8",   "i16",    "i32",   "i64",  "isize",
        "u8",   "u16",    "u32",   "u64",  "usize",
        "f32",  "f64",    "never", "any",
    };
    for (prims) |p| if (std.mem.eql(u8, name, p)) return true;
    return false;
}

/// True for every keyword-group token kind (`selfType` routes here too and is
/// reclassified as a type by the caller).
fn isKeywordKind(kind: TokenKind) bool {
    return switch (kind) {
        .as, .assert, .auto, .await, .case, .@"const", .default, .delegate, .derive, .@"else", .@"enum", .extend, .extends, .@"fn", .@"for", .from, .get, .@"if", .implement, .import, .macro, .new, .@"opaque", .private, .@"pub", .@"return", .selfType, .set, .@"struct", .@"test", .throw, .interface, .type, .record, .use, .val, .@"var", .@"comptime", .syntax, .@"break", .loop, .@"continue", .yield, .declare, .null, .@"try", .@"catch" => true,
        else => false,
    };
}

// ── Completion ────────────────────────────────────────────────────────────────

/// Returns completion items for all bindings in scope at the cursor position.
/// The prefix typed so far (the partial identifier before the cursor) is used
/// to filter candidates. Caller owns the returned slice and all `label`/`detail`
/// strings inside each item.
///
/// Returns an empty slice when the cursor is inside a string literal or when
/// the cursor is positioned on / immediately before a numeric literal.
pub fn completion(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    const offset = lsp_types.positionToOffset(source, pos);

    // ── guard: cursor inside a string literal ─────────────────────────────────
    if (cursorInString(source, offset))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── guard: cursor inside a comment ────────────────────────────────────────
    if (cursorInComment(source, pos))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── guard: cursor on a numeric literal ────────────────────────────────────
    // Case A: prefix itself starts with a digit (cursor is inside/after a number).
    // Case B: prefix is empty but the character at the cursor is a digit
    //         (cursor is just before a number literal, e.g. `{ |42 }`).
    const prefix = prefixAt(source, pos);
    if (prefix.len > 0 and isDigit(prefix[0]))
        return gpa.alloc(proto.CompletionItem, 0);
    if (prefix.len == 0 and offset < source.len and isDigit(source[offset]))
        return gpa.alloc(proto.CompletionItem, 0);

    // ── dot-completion: `expr.` triggers member completion ───────────────────
    const dot_ctx = dotContext(source, offset);
    if (dot_ctx) |ctx| {
        // Local types/values win; on a miss, `list.` resolves to the embedded
        // "std" module's `pub fn` members (when imported from "std").
        const member_items = try dotCompletion(gpa, ctx.receiver, bindings);
        if (member_items.len > 0) return member_items;
        gpa.free(member_items);
        if (try stdModuleCompletion(gpa, source, ctx.receiver)) |std_items| return std_items;
        // Methods on primitives / arrays / strings (`42.`, `true.`, `xs.`).
        if (try builtinReceiverCompletion(gpa, ctx.receiver, bindings)) |bi_items| return bi_items;
        return gpa.alloc(proto.CompletionItem, 0);
    }

    // ── labeled argument completion: inside `fn_name(|)` suggest param labels
    if (prefix.len == 0 or (prefix.len > 0 and !isDigit(prefix[0]))) {
        const label_items = try labeledArgCompletion(gpa, source, offset, prefix, bindings);
        if (label_items.len > 0) return label_items;
    }

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }

    for (bindings) |b| {
        if (b.name.len == 0) continue;
        if (!std.mem.startsWith(u8, b.name, prefix)) continue;

        const kind = bindingCompletionKind(b);
        const detail = try renderType(gpa, b.type_);
        errdefer gpa.free(detail);

        try items.append(gpa, .{
            .label = try gpa.dupe(u8, b.name),
            .kind = kind,
            .detail = detail,
            .sortText = bindingSortText(b),
        });
    }

    return items.toOwnedSlice(gpa);
}

// ── Dot-completion helpers ───────────────────────────────────────────────────

const DotCompletionContext = struct {
    receiver: []const u8,
};

fn labeledArgCompletion(
    gpa: std.mem.Allocator,
    source: []const u8,
    offset: usize,
    prefix: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    // Walk backwards to find the opening `(` at depth 0.
    var depth: u32 = 0;
    var paren_idx: ?usize = null;
    var i: usize = offset;
    while (i > 0) {
        i -= 1;
        switch (source[i]) {
            ')', ']' => depth += 1,
            '[' => {
                if (depth == 0) break;
                depth -= 1;
            },
            '(' => {
                if (depth == 0) {
                    paren_idx = i;
                    break;
                }
                depth -= 1;
            },
            else => {},
        }
    }

    const paren = paren_idx orelse return gpa.alloc(proto.CompletionItem, 0);

    // Find the function name before `(`.
    var j = paren;
    while (j > 0 and (source[j - 1] == ' ' or source[j - 1] == '\t')) j -= 1;
    if (j == 0 or !isIdentCont(source[j - 1])) return gpa.alloc(proto.CompletionItem, 0);
    const name_end = j;
    while (j > 0 and isIdentCont(source[j - 1])) j -= 1;
    const fn_name = source[j..name_end];

    // Find the binding for this function.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, fn_name)) continue;
        switch (b.decl) {
            .@"fn" => |f| {
                var items: std.ArrayList(proto.CompletionItem) = .empty;
                errdefer {
                    for (items.items) |it| {
                        gpa.free(it.label);
                        if (it.detail) |d| gpa.free(d);
                    }
                    items.deinit(gpa);
                }
                for (f.params) |p| {
                    if (std.mem.eql(u8, p.name, "self")) continue;
                    if (prefix.len > 0 and !std.mem.startsWith(u8, p.name, prefix)) continue;
                    const label = try std.fmt.allocPrint(gpa, "{s}:", .{p.name});
                    try items.append(gpa, .{
                        .label = label,
                        .kind = proto.CompletionItemKind.Field,
                        .detail = null,
                        .insertText = try std.fmt.allocPrint(gpa, "{s}: ", .{p.name}),
                    });
                }
                return items.toOwnedSlice(gpa);
            },
            else => {},
        }
        break;
    }

    return gpa.alloc(proto.CompletionItem, 0);
}

fn dotContext(source: []const u8, offset: usize) ?DotCompletionContext {
    if (offset == 0) return null;
    if (source[offset - 1] != '.') {
        // Check if there's a prefix after the dot: `foo.ba|`
        const end = offset;
        var start = offset;
        while (start > 0 and isIdentCont(source[start - 1])) start -= 1;
        if (start == end) return null; // no prefix
        if (start == 0 or source[start - 1] != '.') return null;
        // Found `receiver.prefix` — we want `receiver` for member lookup
        const dot_pos = start - 1;
        if (dot_pos == 0) return null;
        const recv_end = dot_pos;
        var recv_start = recv_end;
        while (recv_start > 0 and isIdentCont(source[recv_start - 1])) recv_start -= 1;
        if (recv_start == recv_end) return null;
        return .{ .receiver = source[recv_start..recv_end] };
    }
    // Cursor is right after the dot: `foo.|`
    const dot_pos = offset - 1;
    if (dot_pos == 0) return null;
    const recv_end = dot_pos;
    var recv_start = recv_end;
    while (recv_start > 0 and isIdentCont(source[recv_start - 1])) recv_start -= 1;
    if (recv_start == recv_end) return null;
    return .{ .receiver = source[recv_start..recv_end] };
}

fn dotCompletion(
    gpa: std.mem.Allocator,
    receiver_name: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) ![]proto.CompletionItem {
    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }

    // Case 1 — the receiver names a type declaration directly
    // (`Status.`, `Point.`): complete its variants / fields / methods.
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, receiver_name)) continue;
        if (isTypeDecl(b.decl)) {
            try appendDeclMembers(gpa, &items, b.decl);
            return items.toOwnedSlice(gpa);
        }
    }

    // Case 2 — the receiver is a value (`origin.`): resolve its named type,
    // then complete that type's members.
    var receiver_type_name: ?[]const u8 = null;
    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, receiver_name)) continue;
        const t = b.type_.deref();
        if (t.* == .named) receiver_type_name = t.named.name;
        break;
    }
    // Iterator receivers (`@Iterator` / `@AsyncIterator`) expose the iteration
    // protocol: `next()`, `iter()` and `map()`.
    if (receiver_type_name) |rtn| {
        if (std.mem.eql(u8, rtn, "Iterator") or std.mem.eql(u8, rtn, "AsyncIterator")) {
            const iter_methods = [_][]const u8{ "next", "iter", "map" };
            for (iter_methods) |m| {
                try items.append(gpa, .{
                    .label = try gpa.dupe(u8, m),
                    .kind = proto.CompletionItemKind.Method,
                    .detail = null,
                });
            }
            return items.toOwnedSlice(gpa);
        }
    }

    if (receiver_type_name) |type_name| {
        for (bindings) |b| {
            if (!std.mem.eql(u8, b.name, type_name)) continue;
            if (isTypeDecl(b.decl)) try appendDeclMembers(gpa, &items, b.decl);
            break;
        }
    }

    return items.toOwnedSlice(gpa);
}

/// True when the file imports `module_name` from the "std" package, i.e. it
/// contains an `import { … module_name … } from "std";` declaration.
fn importsStdModule(source: []const u8, module_name: []const u8) bool {
    var search: usize = 0;
    while (std.mem.indexOfPos(u8, source, search, "from \"std\"")) |from_idx| {
        // Walk back to the `import { … }` list that precedes this `from`.
        const brace = std.mem.lastIndexOfScalar(u8, source[0..from_idx], '{') orelse {
            search = from_idx + 1;
            continue;
        };
        const list = source[brace + 1 .. from_idx];
        // Match the bare module name as a whole identifier in the import list.
        var it = std.mem.tokenizeAny(u8, list, " \t\r\n,{}*");
        while (it.next()) |seg| {
            if (std.mem.eql(u8, seg, module_name)) return true;
        }
        search = from_idx + 1;
    }
    return false;
}

/// Byte offset of `tok`'s first character within `source` (1-based line/col).
fn tokenOffset(source: []const u8, tok: Token) usize {
    return lsp_types.positionToOffset(source, lsp_types.locToPosition(tok.line, tok.col));
}

/// Completion for `list.` where `list` is a module imported from "std":
/// lists the module's `pub fn` declarations with their rendered signatures.
/// Returns null when `receiver` is not an imported std module.
fn stdModuleCompletion(
    gpa: std.mem.Allocator,
    source: []const u8,
    receiver: []const u8,
) !?[]proto.CompletionItem {
    const mod = findStdModule(receiver) orelse return null;
    if (!importsStdModule(source, receiver)) return null;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    var lexer = Lexer.init(mod.source);
    const tokens = lexer.scanAll(arena.allocator()) catch return null;

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }

    var i: usize = 0;
    while (i < tokens.len) : (i += 1) {
        if (tokens[i].kind != .@"pub") continue;
        var j = i + 1;
        while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
        if (j >= tokens.len or tokens[j].kind != .@"fn") continue;
        var k = j + 1;
        while (k < tokens.len and tokens[k].kind == .endOfFile) : (k += 1) {}
        if (k >= tokens.len or tokens[k].kind != .identifier) continue;

        const detail = stdSignatureDetail(gpa, mod.source, tokens, j) catch null;
        try items.append(gpa, .{
            .label = try gpa.dupe(u8, tokens[k].lexeme),
            .kind = proto.CompletionItemKind.Function,
            .detail = detail,
        });
        i = k;
    }

    return try items.toOwnedSlice(gpa);
}

// ── Builtin-type interface methods (primitives / arrays / strings) ────────────
//
// The methods callable on a primitive (`42.abs()`), boolean (`true.to_string()`),
// array (`xs.map(…)`) or string (`"s".len()`) come from the embedded interface
// declarations in `primitives.d.bp` / `array.d.bp` / `string.d.bp`. These are
// not user bindings, so completion / hover / signatureHelp resolve them by
// scanning those embedded sources directly.

/// One builtin-type interface: its declared name plus the embedded source that
/// contains the `interface … { … }` block.
const BuiltinInterface = struct {
    name: []const u8,
    source: []const u8,
};

/// Maps a botopink type name (as it appears in an inferred `Type.named`) to its
/// builtin interface, or null when the type has no method surface.
fn builtinInterfaceForType(type_name: []const u8) ?BuiltinInterface {
    const prim = comptime_pipeline.primitive_interfaces_src;
    const pairs = [_]struct { ty: []const u8, iface: []const u8 }{
        .{ .ty = "i32", .iface = "I32" },
        .{ .ty = "u32", .iface = "U32" },
        .{ .ty = "i64", .iface = "I64" },
        .{ .ty = "u64", .iface = "U64" },
        .{ .ty = "f32", .iface = "F32" },
        .{ .ty = "f64", .iface = "F64" },
        .{ .ty = "bool", .iface = "Bool" },
    };
    for (pairs) |p| {
        if (std.mem.eql(u8, type_name, p.ty)) return .{ .name = p.iface, .source = prim };
    }
    if (std.mem.eql(u8, type_name, "array"))
        return .{ .name = "Array", .source = comptime_pipeline.array_interface_src };
    if (std.mem.eql(u8, type_name, "string"))
        return .{ .name = "String", .source = comptime_pipeline.string_interface_src };
    return null;
}

/// Resolves a dot-receiver to its builtin interface. Numeric literals default
/// to `I32`, `true`/`false` to `Bool`; any other receiver is looked up as a
/// value binding and mapped from its inferred type.
fn receiverBuiltinInterface(
    receiver: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) ?BuiltinInterface {
    if (receiver.len == 0) return null;

    // Integer literal receiver (`42.`): defaults to `i32`.
    var all_digits = true;
    for (receiver) |c| {
        if (!isDigit(c)) {
            all_digits = false;
            break;
        }
    }
    if (all_digits) return builtinInterfaceForType("i32");

    if (std.mem.eql(u8, receiver, "true") or std.mem.eql(u8, receiver, "false"))
        return builtinInterfaceForType("bool");

    for (bindings) |b| {
        if (!std.mem.eql(u8, b.name, receiver)) continue;
        const t = b.type_.deref();
        if (t.* == .named) return builtinInterfaceForType(t.named.name);
        return null;
    }
    return null;
}

/// Like `qualifierBefore`, but tolerant of receivers that start with a digit
/// (an integer literal such as `42.abs`). Returns the `receiver` in
/// `receiver.member` when `start` sits just after the `.`.
fn dotReceiverBefore(source: []const u8, start: usize) ?[]const u8 {
    if (start == 0 or source[start - 1] != '.') return null;
    const dot = start - 1;
    var i = dot;
    while (i > 0 and isIdentCont(source[i - 1])) i -= 1;
    if (i == dot) return null;
    return source[i..dot];
}

/// A single member declared inside an interface block. `sig` is the source
/// slice spanning the declaration (e.g. `fn clamp(self: Self, min: i32, …) -> i32`).
const InterfaceMember = struct {
    is_fn: bool,
    name: []const u8,
    sig: []const u8,
};

/// Collects every `fn`/`val` member declared inside `iface`'s `interface { … }`
/// block. Slices borrow `iface.source`, which is an embedded compile-time
/// string (static lifetime). Returns null when the block can't be located.
fn collectInterfaceMembers(
    arena: std.mem.Allocator,
    iface: BuiltinInterface,
) !?[]InterfaceMember {
    var lexer = Lexer.init(iface.source);
    const tokens = lexer.scanAll(arena) catch return null;

    var members: std.ArrayList(InterfaceMember) = .empty;
    var seen = std.StringHashMap(void).init(arena);
    var found_any = false;

    // Follow the `extends` chain (e.g. `I32 → Signed → Integer → Number`),
    // collecting each interface's members. The most-derived interface is visited
    // first, so a member redeclared in a base (e.g. `toString`) doesn't shadow
    // the derived one — duplicates by name are skipped.
    var current: ?[]const u8 = iface.name;
    var guard: usize = 0;
    while (current) |cname| {
        if (guard >= 16) break; // depth / cycle guard
        guard += 1;
        current = null;

        // Locate `interface <cname>`; capture an optional `extends <Base>` and
        // the `{ … }` body that follows (skipping generic params `<T>`).
        var i: usize = 0;
        var body_start: ?usize = null;
        while (i < tokens.len) : (i += 1) {
            if (tokens[i].kind != .interface) continue;
            var j = i + 1;
            while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
            if (j >= tokens.len or tokens[j].kind != .identifier) continue;
            if (!std.mem.eql(u8, tokens[j].lexeme, cname)) continue;
            j += 1;
            while (j < tokens.len and tokens[j].kind != .leftBrace) : (j += 1) {
                if (tokens[j].kind == .extends) {
                    var q = j + 1;
                    while (q < tokens.len and tokens[q].kind != .identifier and tokens[q].kind != .leftBrace) : (q += 1) {}
                    if (q < tokens.len and tokens[q].kind == .identifier) current = tokens[q].lexeme;
                }
            }
            if (j < tokens.len) body_start = j + 1;
            break;
        }
        const start = body_start orelse continue;
        found_any = true;

        // Find the matching closing brace (depth tracking).
        var depth: u32 = 1;
        var body_end: usize = start;
        while (body_end < tokens.len) : (body_end += 1) {
            const bk = tokens[body_end].kind;
            if (bk == .leftBrace) depth += 1;
            if (bk == .rightBrace) {
                depth -= 1;
                if (depth == 0) break;
            }
        }

        // Walk member declarations; each spans from its `fn`/`val` keyword up to
        // the next member keyword (or the closing brace).
        var k: usize = start;
        while (k < body_end) : (k += 1) {
            const kind = tokens[k].kind;
            if (kind != .@"fn" and kind != .val) continue;

            var n = k + 1;
            while (n < body_end and tokens[n].kind == .endOfFile) : (n += 1) {}
            if (n >= body_end or tokens[n].kind != .identifier) continue;
            const name = tokens[n].lexeme;

            // The signature spans `fn name(params) -> Ret`, stopping at the body
            // brace (`default fn`), an attribute (`@[…]` / `#[…]`) or the next
            // member keyword — so trailing comments/attributes that precede the
            // next method never leak into this member's detail. `sig_end` is the
            // end of the last signature token (not the start of the boundary),
            // dropping whitespace/comments between sig and next decl. A `fn`
            // nested in parentheses (function-typed param) is not a boundary.
            const fn_kw = k;
            var e = n + 1;
            var pdepth: i32 = 0;
            var seen_params = false;
            var last_tok = n;
            while (e < body_end) : (e += 1) {
                const ek = tokens[e].kind;
                if (ek == .leftParenthesis) {
                    pdepth += 1;
                    last_tok = e;
                } else if (ek == .rightParenthesis) {
                    pdepth -= 1;
                    last_tok = e;
                    if (pdepth == 0) seen_params = true;
                } else if (pdepth > 0) {
                    last_tok = e;
                } else if (seen_params and (ek == .leftBrace or ek == .at or ek == .hash or ek == .@"fn" or ek == .val)) {
                    break;
                } else {
                    last_tok = e;
                }
            }
            k = n;
            if (seen.contains(name)) continue;
            try seen.put(name, {});

            const sig_start = tokenOffset(iface.source, tokens[fn_kw]);
            const end_tok = tokens[last_tok];
            const sig_end = tokenOffset(iface.source, end_tok) + end_tok.lexeme.len;
            const sig = std.mem.trim(u8, iface.source[sig_start..@min(sig_end, iface.source.len)], " \t\r\n");

            try members.append(arena, .{ .is_fn = kind == .@"fn", .name = name, .sig = sig });
        }
    }
    if (!found_any) return null;
    return try members.toOwnedSlice(arena);
}

/// Completion for `42.` / `true.` / `xs.` / `"s".`: lists the methods/values of
/// the receiver's builtin interface. Returns null when the receiver has none.
fn builtinReceiverCompletion(
    gpa: std.mem.Allocator,
    receiver: []const u8,
    bindings: []const comptime_pipeline.TypedBinding,
) !?[]proto.CompletionItem {
    const iface = receiverBuiltinInterface(receiver, bindings) orelse return null;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const members = (try collectInterfaceMembers(arena.allocator(), iface)) orelse return null;

    var items: std.ArrayList(proto.CompletionItem) = .empty;
    errdefer {
        for (items.items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        items.deinit(gpa);
    }
    for (members) |m| {
        try items.append(gpa, .{
            .label = try gpa.dupe(u8, m.name),
            .kind = if (m.is_fn) proto.CompletionItemKind.Method else proto.CompletionItemKind.Field,
            .detail = try gpa.dupe(u8, m.sig),
        });
    }
    return try items.toOwnedSlice(gpa);
}

/// Hover for an interface method invoked on a builtin receiver
/// (`42.abs`, `true.to_string`, `xs.map`): renders the method signature plus
/// the interface it comes from. Returns null when nothing matches.
fn hoverBuiltinInterfaceMethod(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    bindings: []const comptime_pipeline.TypedBinding,
) !?proto.Hover {
    const span = identSpanAt(source, pos) orelse return null;
    const member = source[span.start..span.end];
    const receiver = dotReceiverBefore(source, span.start) orelse return null;
    const iface = receiverBuiltinInterface(receiver, bindings) orelse return null;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const members = (try collectInterfaceMembers(arena.allocator(), iface)) orelse return null;

    for (members) |m| {
        if (!std.mem.eql(u8, m.name, member)) continue;
        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(gpa);
        try buf.appendSlice(gpa, "```botopink\n");
        try buf.appendSlice(gpa, m.sig);
        try buf.appendSlice(gpa, "\n```");
        try buf.print(gpa, "\n\n*from `interface {s}`*", .{iface.name});
        return .{ .contents = .{ .kind = proto.MarkupKind.Markdown, .value = try buf.toOwnedSlice(gpa) } };
    }
    return null;
}

/// Renders the signature of a `fn` declaration (the `fn` token sits at index
/// `fn_idx`) as the source slice from `fn` up to the body `{` or `;`.
fn stdSignatureDetail(
    gpa: std.mem.Allocator,
    mod_source: []const u8,
    tokens: []const Token,
    fn_idx: usize,
) ![]u8 {
    const start = tokenOffset(mod_source, tokens[fn_idx]);
    var end_idx = fn_idx + 1;
    var depth: u32 = 0;
    while (end_idx < tokens.len) : (end_idx += 1) {
        const k = tokens[end_idx].kind;
        if (k == .leftParenthesis) depth += 1;
        if (k == .rightParenthesis) depth -= 1;
        if (depth == 0 and (k == .leftBrace or k == .semicolon)) break;
    }
    const end = if (end_idx < tokens.len)
        tokenOffset(mod_source, tokens[end_idx])
    else
        mod_source.len;
    const sig = std.mem.trim(u8, mod_source[start..@min(end, mod_source.len)], " \t\r\n");
    return gpa.dupe(u8, sig);
}

/// True when `decl` is a record / struct / enum type declaration whose members
/// can be completed after a `.`.
fn isTypeDecl(decl: anytype) bool {
    return switch (decl) {
        .record, .@"struct", .@"enum" => true,
        else => false,
    };
}

/// Append the completable members of a type declaration: record fields/methods,
/// struct fields/methods/getters/setters, or enum variants/methods.
fn appendDeclMembers(
    gpa: std.mem.Allocator,
    items: *std.ArrayList(proto.CompletionItem),
    decl: anytype,
) !void {
    switch (decl) {
        .record => |r| {
            for (r.fields) |field| try items.append(gpa, .{
                .label = try gpa.dupe(u8, field.name),
                .kind = proto.CompletionItemKind.Field,
                .detail = null,
            });
            for (r.methods) |method| try items.append(gpa, .{
                .label = try gpa.dupe(u8, method.name),
                .kind = proto.CompletionItemKind.Method,
                .detail = null,
            });
        },
        .@"struct" => |s| {
            for (s.members) |member| switch (member) {
                .field => |field| try items.append(gpa, .{
                    .label = try gpa.dupe(u8, field.name),
                    .kind = proto.CompletionItemKind.Field,
                    .detail = null,
                }),
                .method => |method| try items.append(gpa, .{
                    .label = try gpa.dupe(u8, method.name),
                    .kind = proto.CompletionItemKind.Method,
                    .detail = null,
                }),
                .getter => |getter| try items.append(gpa, .{
                    .label = try gpa.dupe(u8, getter.name),
                    .kind = proto.CompletionItemKind.Property,
                    .detail = null,
                }),
                .setter => |setter| try items.append(gpa, .{
                    .label = try gpa.dupe(u8, setter.name),
                    .kind = proto.CompletionItemKind.Property,
                    .detail = null,
                }),
            };
        },
        .@"enum" => |e| {
            for (e.variants) |v| try items.append(gpa, .{
                .label = try gpa.dupe(u8, v.name),
                .kind = proto.CompletionItemKind.EnumMember,
                .detail = null,
            });
            for (e.methods) |method| try items.append(gpa, .{
                .label = try gpa.dupe(u8, method.name),
                .kind = proto.CompletionItemKind.Method,
                .detail = null,
            });
        },
        else => {},
    }
}

/// Returns true if `offset` (byte index into `source`) falls inside a
/// double-quoted string literal.  Handles `\"` escapes; strings cannot span
/// newlines so a bare `\n` also closes an open string.
fn cursorInString(source: []const u8, offset: usize) bool {
    var in_string = false;
    var i: usize = 0;
    while (i < offset) {
        const c = source[i];
        if (in_string) {
            if (c == '\\' and i + 1 < source.len) {
                i += 2; // skip escape sequence
                continue;
            }
            if (c == '"' or c == '\n') in_string = false;
        } else {
            if (c == '"') in_string = true;
        }
        i += 1;
    }
    return in_string;
}

/// Returns true if the cursor at `pos` is inside a line comment (`//`).
/// Locates the start of the cursor's line and scans forward until the cursor
/// position to check if `//` appears before it (outside of a string).
fn cursorInComment(source: []const u8, pos: proto.Position) bool {
    const offset = lsp_types.positionToOffset(source, pos);

    // Find the start of the current line
    var line_start: usize = offset;
    while (line_start > 0 and source[line_start - 1] != '\n') {
        line_start -= 1;
    }

    // Scan from line start to cursor position
    var in_string = false;
    var i: usize = line_start;
    while (i < offset) {
        const c = source[i];

        // Track string state (but don't care about closing strings here)
        if (in_string) {
            if (c == '\\' and i + 1 < offset) {
                i += 2; // skip escape sequence
                continue;
            }
            if (c == '"') in_string = false;
        } else {
            if (c == '"') {
                in_string = true;
            } else if (c == '/' and i + 1 < offset and source[i + 1] == '/') {
                // Found `//` before cursor position (and not inside a string)
                return true;
            }
        }
        i += 1;
    }

    return false;
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn bindingCompletionKind(b: comptime_pipeline.TypedBinding) u32 {
    return switch (b.decl) {
        .@"fn" => proto.CompletionItemKind.Function,
        .record, .@"struct" => proto.CompletionItemKind.Struct,
        .@"enum" => proto.CompletionItemKind.Enum,
        .interface => proto.CompletionItemKind.Interface,
        else => proto.CompletionItemKind.Variable,
    };
}

fn bindingSortText(b: comptime_pipeline.TypedBinding) []const u8 {
    return switch (b.decl) {
        .@"fn" => "0",
        .val => "1",
        .record, .@"struct" => "2",
        .@"enum" => "2",
        .interface => "3",
        else => "4",
    };
}

/// Returns the partial identifier immediately before (and including) `pos`.
fn prefixAt(source: []const u8, pos: proto.Position) []const u8 {
    const offset = lsp_types.positionToOffset(source, pos);
    if (offset == 0) return "";
    const end = offset;
    // Walk back to find start of current identifier word
    var start = end;
    while (start > 0 and isIdentCont(source[start - 1])) start -= 1;
    return source[start..end];
}

// ── Find References ───────────────────────────────────────────────────────────

/// Returns all locations in `source` where the identifier at `pos` is used.
/// Caller owns the returned slice and each `uri` string inside each Location.
pub fn references(
    gpa: std.mem.Allocator,
    uri: []const u8,
    source: []const u8,
    pos: proto.Position,
    tokens: []const Token,
    include_declaration: bool,
) ![]proto.Location {
    const name = identAt(source, pos) orelse return &.{};

    var locs: std.ArrayList(proto.Location) = .empty;
    errdefer {
        for (locs.items) |l| gpa.free(l.uri);
        locs.deinit(gpa);
    }

    const decl_values = [_]TokenKind{ .val, .@"fn", .record, .@"struct", .@"enum", .interface };

    for (tokens, 0..) |tok, i| {
        if (tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, tok.lexeme, name)) continue;

        // Check if this token is a declaration name (previous token is a keyword).
        const is_decl = blk: {
            if (i == 0) break :blk false;
            const prev = tokens[i - 1];
            for (decl_values) |k| {
                if (prev.kind == k) break :blk true;
            }
            break :blk false;
        };

        if (is_decl and !include_declaration) continue;

        const start = lsp_types.locToPosition(tok.line, tok.col);
        const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
        try locs.append(gpa, .{
            .uri = try gpa.dupe(u8, uri),
            .range = .{ .start = start, .end = end },
        });
    }

    return locs.toOwnedSlice(gpa);
}

// ── Rename ────────────────────────────────────────────────────────────────────

/// Computes all edits needed to rename the symbol at `pos` to `new_name`.
/// Returns a slice of TextEdits for the current file. Caller owns it.
pub fn rename(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
    new_name: []const u8,
    tokens: []const Token,
) ![]proto.TextEdit {
    const name = identAt(source, pos) orelse return &.{};

    var edits: std.ArrayList(proto.TextEdit) = .empty;
    errdefer edits.deinit(gpa);

    for (tokens) |tok| {
        if (tok.kind != .identifier) continue;
        if (!std.mem.eql(u8, tok.lexeme, name)) continue;

        const start = lsp_types.locToPosition(tok.line, tok.col);
        const end = lsp_types.locToPosition(tok.line, tok.col + tok.lexeme.len);
        try edits.append(gpa, .{
            .range = .{ .start = start, .end = end },
            .newText = new_name,
        });
    }

    return edits.toOwnedSlice(gpa);
}
