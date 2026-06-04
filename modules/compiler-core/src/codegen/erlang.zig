/// Erlang codegen backend.
///
/// Translates the botopink typed AST to Erlang source.
///
/// Conventions used:
///   - Variables → CamelCase (first letter uppercased)
///   - String literals → <<"...">> binaries
///   - Function bodies → comma-separated expressions; last is return value
///   - OR patterns  → expanded to multiple Erlang case clauses
///   - `return expr` → bare `expr` (Erlang last-expr return)
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

fn isZeroArgMainCallExpr(expr: ast.Expr) bool {
    return switch (expr) {
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and
                cc.receiver == null and
                cc.args.len == 0 and
                cc.trailing.len == 0 and
                std.mem.eql(u8, cc.callee, "main"),
            else => false,
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| isZeroArgMainCallExpr(rp.*) else false,
            .try_ => |t| if (t) |tp| isZeroArgMainCallExpr(tp.*) else false,
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |inner| isZeroArgMainCallExpr(inner.*),
            else => false,
        },
        else => false,
    };
}

fn isSyntheticMainEntrypointCall(v: ast.ValDecl) bool {
    if (std.mem.startsWith(u8, v.name, "_main")) return true;
    return std.mem.startsWith(u8, v.name, "_") and isZeroArgMainCallExpr(v.value.*);
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitErlang(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, config.test_mode);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ─────────────────────────────────────────────────────────

fn emitErlang(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    test_mode: bool,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    var em = Emitter.init(alloc, &aw.writer, comptime_vals, rewrites);
    em.test_mode = test_mode;
    em.module_name = module_name;

    // Test registry entries collected while emitting decls (test mode only).
    const TestEntry = struct { name: ?[]const u8, line: usize, idx: usize };
    var test_entries: std.ArrayListUnmanaged(TestEntry) = .empty;
    defer test_entries.deinit(alloc);
    var test_count: usize = 0;
    if (test_mode) {
        for (program.decls) |decl| {
            if (decl == .@"test") test_count += 1;
        }
    }
    // Names of `implement`/`extend` blocks — a PascalCase call receiver that
    // matches one is a qualified extension call (`PatoNada.swim(d)`), lowered
    // to the bare local function `swim(d)` rather than a remote module call.
    try em.collectExtensionNames(program);
    defer em.ext_names.deinit();
    try em.collectExternals(program);
    defer em.externals.deinit();
    defer em.externals_missing.deinit();
    var top_runtime_vals: std.ArrayListUnmanaged(ast.ValDecl) = .empty;
    defer top_runtime_vals.deinit(alloc);
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (!v.value.isComptimeExpr() and !isSyntheticMainEntrypointCall(v)) try top_runtime_vals.append(alloc, v);
            },
            .@"fn" => |f| {
                if (std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0) has_main_0 = true;
            },
            else => {},
        }
    }
    // Test mode never auto-runs `main/0` — the escript entry is the test runner.
    const emit_entrypoint_wrapper = has_main_0 and !test_mode;

    // Module header
    try aw.writer.print("-module({s}).\n", .{module_name});

    // Collect public function names for export.
    var pub_fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    defer pub_fns.deinit(alloc);
    for (program.decls) |decl| {
        switch (decl) {
            // External fns emit no local definition — nothing to export.
            .@"fn" => |f| if (f.isPub and !f.isExternal()) try pub_fns.append(alloc, f),
            else => {},
        }
    }
    // Export generated entrypoint wrapper when main/0 exists.
    // `main/1` is the escript entry point — escript calls it with the argv list.
    if (emit_entrypoint_wrapper) {
        try aw.writer.writeAll("-export(['_botopink_main'/0, main/1]).\n");
    }
    // Test runner escript entry point.
    if (test_mode and test_count > 0) {
        try aw.writer.writeAll("-export([main/1]).\n");
    }

    // Export other public functions
    if (pub_fns.items.len > 0) {
        try aw.writer.writeAll("-export([");
        for (pub_fns.items, 0..) |f, i| {
            if (i > 0) try aw.writer.writeAll(", ");
            try aw.writer.print("{s}/{d}", .{ f.name, fnArityNoSelf(f) });
        }
        try aw.writer.writeAll("]).\n");
    }

    // Emit declarations
    for (program.decls) |decl| {
        try aw.writer.writeByte('\n');
        switch (decl) {
            .val => |v| {
                if (emit_entrypoint_wrapper) {
                    if (v.value.isComptimeExpr()) try em.emitTopVal(v, comptime_vals);
                } else {
                    try em.emitTopVal(v, comptime_vals);
                }
            },
            .@"fn" => |f| {
                if (f.isExternal()) {
                    // FFI declaration — calls lower to the remote target directly.
                    if (em.externals.get(f.name)) |ref| {
                        try aw.writer.print("%% external fn {s} -> {s}:{s}\n", .{ f.name, ref.module, ref.symbol });
                    } else {
                        try aw.writer.print("%% external fn {s} (no erlang target)\n", .{f.name});
                    }
                } else {
                    try em.emitFn(f);
                }
            },
            .@"struct" => |s| try em.emitStruct(s),
            .record => |r| try em.emitRecord(r),
            .@"enum" => |e| try em.emitEnum(e),
            .interface => |i| try em.emitInterface(i),
            .implement => |im| try em.emitImplement(im),
            .extend => |ex| try em.emitExtend(ex),
            .use => |u| try em.emitUse(u),
            .delegate => |d| try aw.writer.print("%% delegate {s}\n", .{d.name}),
            // Test blocks are only compiled under `botopink test`; in normal
            // builds they are skipped entirely.
            .@"test" => |t| {
                if (!test_mode) continue;
                const idx = test_entries.items.len;
                try test_entries.append(alloc, .{ .name = t.name, .line = t.loc.line, .idx = idx });
                try em.emitTestFn(t, idx);
            },
            .comment => |c| {
                const prefix = if (c.is_doc) "%%" else if (c.is_module) "%%%" else "%";
                try aw.writer.print("{s} {s}\n", .{ prefix, c.text });
            },
        }
    }

    if (emit_entrypoint_wrapper) {
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll("'_botopink_main'() ->\n");
        const saved_indent = em.indent;
        em.indent = 1;

        for (top_runtime_vals.items) |v| {
            try em.writeIndent();
            try em.emitTopValEntryStmt(v);
            try aw.writer.writeAll(",\n");
        }
        try em.writeIndent();
        try aw.writer.writeAll("main().\n");
        em.indent = saved_indent;

        // escript entry point — `escript <file>` calls main/1 with the argv list.
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll("main(_Args) ->\n");
        try aw.writer.writeAll("    '_botopink_main'().\n");
    }

    // Test mode: emit the registry + runner + escript entry.
    if (test_mode and test_entries.items.len > 0) {
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll(
            \\'__bp_run_one'({Name, Fun, Loc}) ->
            \\    try
            \\        Fun(),
            \\        io:format("  ok   ~s~n", [Name]),
            \\        ok
            \\    catch
            \\        error:{bp_assert, Msg, ALoc} ->
            \\            io:format("  FAIL ~s  (~s)  at ~s~n", [Name, Msg, ALoc]),
            \\            fail;
            \\        Class:Reason ->
            \\            io:format("  FAIL ~s  (~p:~p)  at ~s~n", [Name, Class, Reason, Loc]),
            \\            fail
            \\    end.
            \\
            \\'__bp_run_tests'(Filter) ->
            \\    Tests = [
            \\
        );
        for (test_entries.items, 0..) |t, i| {
            if (i > 0) try aw.writer.writeAll(",\n");
            if (t.name) |n| {
                try aw.writer.print("        {{<<\"{s}\">>, fun '__bp_test_{d}'/0, <<\"{s}.bp:{d}\">>}}", .{ n, t.idx, module_name, t.line });
            } else {
                try aw.writer.print("        {{<<\"test_{d}\">>, fun '__bp_test_{d}'/0, <<\"{s}.bp:{d}\">>}}", .{ t.idx, t.idx, module_name, t.line });
            }
        }
        try aw.writer.writeAll(
            \\
            \\    ],
            \\    Selected = case Filter of
            \\        none -> Tests;
            \\        _ -> [T || {N, _, _} = T <- Tests, binary:match(N, Filter) =/= nomatch]
            \\    end,
            \\    io:format("running ~p tests~n", [length(Selected)]),
            \\    Results = ['__bp_run_one'(T) || T <- Selected],
            \\    Failed = length([R || R <- Results, R =:= fail]),
            \\    Passed = length(Results) - Failed,
            \\    io:format("~p passed, ~p failed~n", [Passed, Failed]),
            \\    case Failed > 0 of true -> halt(1); false -> ok end.
            \\
            \\main(Args) ->
            \\    Filter = case Args of
            \\        [F | _] -> list_to_binary(F);
            \\        _ -> none
            \\    end,
            \\    '__bp_run_tests'(Filter).
            \\
        );
    }

    return aw.toOwnedSlice();
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Return a heap-allocated copy of `name` with the first byte uppercased.
/// Caller owns the result.
fn erlangVar(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return alloc.dupe(u8, name);
    const buf = try alloc.dupe(u8, name);
    buf[0] = std.ascii.toUpper(buf[0]);
    return buf;
}

/// True when `name` looks like a module/type reference (PascalCase) rather than
/// a local variable. A qualified call whose receiver is such a name maps to an
/// Erlang remote call `module:fun(...)`; a lowercase receiver is a value the
/// method is invoked on and is left as-is.
fn isModuleRef(name: []const u8) bool {
    return name.len > 0 and std.ascii.isUpper(name[0]);
}

/// Return a heap-allocated copy of `name` with the first byte lowercased so it
/// is a valid unquoted Erlang module atom (`List` → `list`). Inverse of
/// `erlangVar`. Caller owns the result.
fn erlangModule(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return alloc.dupe(u8, name);
    const buf = try alloc.dupe(u8, name);
    buf[0] = std.ascii.toLower(buf[0]);
    return buf;
}

// ── Emitter ───────────────────────────────────────────────────────────────────

const Emitter = struct {
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),
    indent: usize = 0,
    try_seq: usize = 0,
    alloc: std.mem.Allocator,
    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    /// At these sites `recv.m(args)` lowers to the bare local function `m(Recv, args)`.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Set of `implement`/`extend` block names (for qualified-call dispatch).
    ext_names: std.StringHashMap(void),
    /// `@[external(erlang, "module", "symbol")]` fns: name → remote target.
    /// Calls lower to `module:symbol(Args)`; the decl itself emits nothing.
    externals: std.StringHashMap(ast.ExternalRef),
    /// `@[external(…)]` fns with no `erlang` target — calling one is an error.
    externals_missing: std.StringHashMap(void),
    /// When true, `emitFn` keeps the `self` parameter (extension methods take
    /// the receiver as an explicit first argument; ordinary fns drop `self`).
    keep_self: bool = false,
    /// `botopink test` compilation: `assert` lowers to a `bp_assert` error the
    /// test runner catches per test instead of a hard `true = (...)` badmatch.
    test_mode: bool = false,
    /// Module name, used for `<module>.bp:<line>` source locations in
    /// test-mode assert failures.
    module_name: []const u8 = "main",

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .out = out,
            .cv = cv,
            .alloc = alloc,
            .rewrites = rewrites,
            .ext_names = std.StringHashMap(void).init(alloc),
            .externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .externals_missing = std.StringHashMap(void).init(alloc),
        };
    }

    fn collectExtensionNames(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try this.ext_names.put(im.name, {}),
            .extend => |ex| try this.ext_names.put(ex.name, {}),
            else => {},
        };
    }

    /// Indexes every `@[external(…)]` fn by name: with an `erlang` target it
    /// goes to `externals`; without one it goes to `externals_missing` (so a
    /// call can fail with a clear error instead of an undefined function).
    fn collectExternals(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                if (f.externalFor("erlang")) |ref| {
                    try this.externals.put(f.name, ref);
                } else {
                    try this.externals_missing.put(f.name, {});
                }
            },
            else => {},
        };
    }

    fn w(this: *Emitter, s: []const u8) !void {
        try this.out.writeAll(s);
    }

    fn fmt(this: *Emitter, comptime f: []const u8, args: anytype) !void {
        try this.out.print(f, args);
    }

    fn writeIndent(this: *Emitter) !void {
        for (0..this.indent) |_| try this.w("    ");
    }

    // ── top-level val ─────────────────────────────────────────────────────────

    fn emitTopVal(this: *Emitter, v: ast.ValDecl, cv: std.StringHashMap([]const u8)) !void {
        if (v.value.isComptimeExpr()) {
            _ = cv;
            try this.fmt("%% comptime val {s}\n", .{v.name});
            return;
        }
        // Emit as a 0-arity function when there is no script wrapper entrypoint.
        try this.fmt("{s}() ->\n", .{v.name});
        const saved = this.indent;
        this.indent = 1;
        try this.writeIndent();
        try this.emitExpr(v.value.*);
        this.indent = saved;
        try this.w(".\n");
    }

    fn emitTopValEntryStmt(this: *Emitter, v: ast.ValDecl) !void {
        const synthetic_runtime_stmt = std.mem.startsWith(u8, v.name, "_");
        if (synthetic_runtime_stmt) {
            try this.emitExpr(v.value.*);
            return;
        }
        const vname = try erlangVar(this.alloc, v.name);
        defer this.alloc.free(vname);
        try this.fmt("{s} = ", .{vname});
        try this.emitExpr(v.value.*);
    }

    // ── fn ────────────────────────────────────────────────────────────────────

    /// True when the body is a flat sequence of `yield` statements (a simple
    /// finite generator that lowers to an eager Erlang list).
    fn isPlainYieldGenerator(f: ast.FnDecl) bool {
        if (!f.isStarFn or f.body.len == 0) return false;
        for (f.body) |stmt| {
            if (!(stmt.expr == .jump and stmt.expr.jump.kind == .yield)) return false;
        }
        return true;
    }

    fn emitFn(this: *Emitter, f: ast.FnDecl) !void {
        // `*fn` is async/generator. Erlang is eager: a `@Future<T>` resolves to
        // `T` (so `await` is identity) and a finite `@Iterator<T>` is a list.
        if (f.isStarFn) {
            try this.fmt("%% *fn (async/generator) — eager lowering\n", .{});
        }
        try this.w(f.name);
        try this.w("(");
        var first = true;
        for (f.params) |p| {
            if (p.destruct) |d| {
                switch (d) {
                    .names => |*n| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (n.fields, 0..) |fld, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, fld.bind_name);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        }
                        if (n.hasSpread) try this.w(", _");
                        try this.w("}");
                        first = false;
                    },
                    .tuple_ => |t| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (t, 0..) |nm, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, nm);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        }
                        try this.w("}");
                        first = false;
                    },
                    .list => {}, // List pattern — placeholder
                    .ctor => {}, // Constructor pattern — placeholder
                }
            } else if (this.keep_self or !std.mem.eql(u8, p.name, "self")) {
                if (!first) try this.w(", ");
                const vname = try erlangVar(this.alloc, p.name);
                defer this.alloc.free(vname);
                try this.w(vname);
                first = false;
            }
        }
        try this.w(") ->\n");
        const saved = this.indent;
        this.indent = 1;
        this.try_seq = 0;
        if (isPlainYieldGenerator(f)) {
            // Finite generator → eager list of yielded items: `[V1, V2, ...]`.
            try this.writeIndent();
            try this.w("[");
            for (f.body, 0..) |stmt, i| {
                if (i > 0) try this.w(", ");
                if (stmt.expr.jump.kind.yield.value) |val| try this.emitExpr(val.*);
            }
            try this.w("]");
        } else {
            try this.emitBody(f.body);
        }
        this.indent = saved;
        try this.w(".\n");
    }

    /// Emit a `test { … }` body as `'__bp_test_<idx>'() -> Body.`
    /// Same body emission as `emitFn` — no params, exported via the runner.
    fn emitTestFn(this: *Emitter, t: ast.TestDecl, idx: usize) !void {
        try this.fmt("'__bp_test_{d}'() ->\n", .{idx});
        const saved = this.indent;
        this.indent = 1;
        this.try_seq = 0;
        try this.emitBody(t.body);
        this.indent = saved;
        try this.w(".\n");
    }

    /// `try expr` (no catch) at body position → propagate `{error, E}` by nesting
    /// the rest of the body inside the `{ok, V}` arm. Returns the inner expr.
    fn propagateTryInner(e: ast.Expr) ?ast.Expr {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |t| if (t) |i| i.* else null,
                else => null,
            },
            else => null,
        };
    }

    // ── body (comma-separated stmts; does NOT emit trailing newline) ──────────
    //
    // Callers are responsible for the terminator that follows on the same line:
    //   emitFn  → ".\n"
    //   fun end → "\nINDENT end"

    fn emitBody(this: *Emitter, body: []const ast.Stmt) !void {
        try this.emitBodyFrom(body, 0);
    }

    /// Emit statements `body[start..]`. A `try` without `catch` short-circuits:
    /// it lowers to `case Inner of {ok, V} -> <rest>; {error, E} -> {error, E} end`,
    /// nesting every following statement inside the Ok arm (Erlang has no early
    /// return), so the Error variant propagates up as the function's value.
    fn emitBodyFrom(this: *Emitter, body: []const ast.Stmt, start: usize) anyerror!void {
        var i = start;
        while (i < body.len) : (i += 1) {
            const stmt = body[i];
            const is_last = (i == body.len - 1);

            // Detect `[val name =] try inner` (no catch) at this position.
            const prop: ?struct { inner: ast.Expr, head: TryHead } = switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .name = lb.name } }
                    else
                        null,
                    .localBindDestruct => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .destruct = lb.pattern } }
                    else
                        null,
                    else => null,
                },
                .jump => |j| switch (j.kind) {
                    .try_ => |t| if (t) |inner|
                        .{ .inner = inner.*, .head = .none }
                    else
                        null,
                    .@"return" => |r| if (r) |rv| if (propagateTryInner(rv.*)) |inner|
                        .{ .inner = inner, .head = .none }
                    else
                        null else null,
                    else => null,
                },
                else => null,
            };

            if (prop) |p| {
                try this.writeIndent();
                try this.emitPropagateTry(body, i, p.inner, p.head);
                return; // remaining statements are nested inside the Ok arm
            }

            try this.writeIndent();
            try this.emitBodyStmt(stmt, is_last);
            if (!is_last) try this.w(",\n");
        }
    }

    const TryHead = union(enum) {
        name: []const u8,
        destruct: ast.ParamDestruct,
        none,
    };

    /// Emit the propagating `case` for a `try` at `body[i]`, nesting `body[i+1..]`
    /// inside the `{ok, _}` arm.
    fn emitPropagateTry(this: *Emitter, body: []const ast.Stmt, i: usize, inner: ast.Expr, head: TryHead) !void {
        const n = this.try_seq;
        this.try_seq += 1;

        try this.w("case ");
        try this.emitExpr(inner);
        try this.w(" of\n");
        this.indent += 1;
        try this.writeIndent();

        // {ok, <bind>} ->
        try this.w("{ok, ");
        switch (head) {
            .name => |nm| {
                const vname = try erlangVar(this.alloc, nm);
                defer this.alloc.free(vname);
                try this.w(vname);
            },
            .destruct => |pat| try this.emitDestructPattern(pat),
            .none => try this.fmt("_TryV{d}", .{n}),
        }
        try this.w("} ->\n");

        this.indent += 1;
        if (i + 1 < body.len) {
            try this.emitBodyFrom(body, i + 1);
        } else {
            // No continuation: the Ok value is the function's result.
            try this.writeIndent();
            switch (head) {
                .name => |nm| {
                    const vname = try erlangVar(this.alloc, nm);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                },
                else => try this.fmt("_TryV{d}", .{n}),
            }
        }
        this.indent -= 1;
        try this.w(";\n");
        try this.writeIndent();
        try this.fmt("{{error, _TryE{d}}} -> {{error, _TryE{d}}}\n", .{ n, n });
        this.indent -= 1;
        try this.writeIndent();
        try this.w("end");
    }

    /// Render a destructuring pattern (tuple/record names) as an Erlang pattern.
    fn emitDestructPattern(this: *Emitter, pattern: ast.ParamDestruct) !void {
        switch (pattern) {
            .names => |n| {
                try this.w("{");
                for (n.fields, 0..) |fld, k| {
                    if (k > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, fld.bind_name);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                if (n.hasSpread) try this.w(", _");
                try this.w("}");
            },
            .tuple_ => |t| {
                try this.w("{");
                for (t, 0..) |nm, k| {
                    if (k > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, nm);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w("}");
            },
            .list, .ctor => try this.w("_"),
        }
    }

    /// Emit a statement inside a function body.
    /// When `is_last` is true, `return expr` is emitted as bare `expr`.
    fn emitBodyStmt(this: *Emitter, stmt: ast.Stmt, is_last: bool) !void {
        const e = stmt.expr;
        switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    // In Erlang the last expression is the return value.
                    // Emit a bare expression; if not last, wrap in a noop binding.
                    _ = is_last;
                    if (r) |val| try this.emitExpr(val.*) else try this.w("undefined");
                },
                else => try this.emitExpr(e),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    switch (a.target) {
                        .name => |name| {
                            const vname = try erlangVar(this.alloc, name);
                            defer this.alloc.free(vname);
                            switch (a.op) {
                                .assign => try this.fmt("{s} = ", .{vname}),
                                .plusAssign => try this.fmt("{s} = {s} + ", .{ vname, vname }),
                            }
                            try this.emitExpr(a.value.*);
                        },
                        .fieldAccess => |*fa| {
                            _ = fa;
                            try this.w("%% field assignment is not directly supported in Erlang");
                        },
                    }
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
            },
            else => try this.emitExpr(e),
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn emitBinaryOp(this: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
        try this.w("(");
        try this.emitExpr(lhs.*);
        try this.w(" ");
        try this.w(op);
        try this.w(" ");
        try this.emitExpr(rhs.*);
        try this.w(")");
    }

    /// Emit the inline Erlang form for a lowered `@Result`/`@Option` method op.
    /// `args[0]` is the receiver; `args[1]` (when present) the fn/default value.
    /// A fun binds the receiver once (so chains don't re-evaluate it). Result
    /// values use the `{tag, 'Ok'|'Error', Payload}` shape; absent options are
    /// `undefined`.
    fn emitResultOptionOp(this: *Emitter, callee: []const u8, args: []const ast.CallArg) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;

        if (std.mem.eql(u8, callee, "__bp_result_map")) {
            try this.w("(fun(R) -> case R of {tag, 'Ok', V} -> {tag, 'Ok', (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V)}; _ -> R end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            try this.w("(fun(R) -> case R of {tag, 'Ok', V} -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V); _ -> R end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            try this.w("(fun(R) -> case R of {tag, 'Ok', V} -> V; _ -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(") end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            try this.w("(fun(R) -> case R of {tag, 'Ok', _} -> true; _ -> false end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            try this.w("(fun(R) -> case R of {tag, 'Error', _} -> true; _ -> false end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            try this.w("(fun(O) -> case O of undefined -> undefined; V -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V) end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            try this.w("(fun(O) -> case O of undefined -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w("); V -> V end end)(");
        } else {
            return;
        }
        try this.emitExpr(recv.*);
        try this.w(")");
    }

    fn emitExpr(this: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| try this.w(n),
                .comment => |c| {
                    const prefix = switch (c.kind) {
                        .normal => "%",
                        .doc => "%%",
                        .module => "%%%",
                    };
                    try this.fmt("{s} {s}", .{ prefix, c.text });
                },
                .stringLit => |s| try this.emitBinary(s),
                .null_ => try this.w("undefined"),
            },

            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    // Boolean literals are env-bound identifiers in botopink —
                    // they must stay lowercase atoms, never `True`/`False` vars.
                    if (std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false")) {
                        try this.w(n);
                    } else {
                        const vname = try erlangVar(this.alloc, n);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                },
                .identAccess => |ia| {
                    try this.emitExpr(ia.receiver.*);
                    try this.fmt("_{s}", .{ia.member});
                },
                .dotIdent => |n| try this.fmt("{s}", .{n}),
            },

            .binaryOp => |bin| switch (bin.op) {
                .add => try this.emitBinaryOp("+", bin.lhs, bin.rhs),
                .sub => try this.emitBinaryOp("-", bin.lhs, bin.rhs),
                .mul => try this.emitBinaryOp("*", bin.lhs, bin.rhs),
                .div => try this.emitBinaryOp("div", bin.lhs, bin.rhs),
                .mod => try this.emitBinaryOp("rem", bin.lhs, bin.rhs),
                .lt => try this.emitBinaryOp("<", bin.lhs, bin.rhs),
                .gt => try this.emitBinaryOp(">", bin.lhs, bin.rhs),
                .lte => try this.emitBinaryOp("=<", bin.lhs, bin.rhs),
                .gte => try this.emitBinaryOp(">=", bin.lhs, bin.rhs),
                .eq => try this.emitBinaryOp("=:=", bin.lhs, bin.rhs),
                .ne => try this.emitBinaryOp("=/=", bin.lhs, bin.rhs),
                .@"and" => try this.emitBinaryOp("and", bin.lhs, bin.rhs),
                .@"or" => try this.emitBinaryOp("or", bin.lhs, bin.rhs),
            },

            .unaryOp => |un| switch (un.op) {
                .not => {
                    try this.w("(not ");
                    try this.emitExpr(un.expr.*);
                    try this.w(")");
                },
                .neg => {
                    try this.w("(-");
                    try this.emitExpr(un.expr.*);
                    try this.w(")");
                },
            },

            .call => |c| switch (c.kind) {
                .pipeline => |b| {
                    // Flatten the pipeline chain
                    var items: std.ArrayList(ast.Expr) = .empty;
                    defer items.deinit(this.alloc);
                    try items.append(this.alloc, b.lhs.*);
                    var current = b.rhs.*;
                    while (true) {
                        switch (current) {
                            .call => |cc| switch (cc.kind) {
                                .pipeline => |p| {
                                    try items.append(this.alloc, p.lhs.*);
                                    current = p.rhs.*;
                                    continue;
                                },
                                else => {},
                            },
                            else => {},
                        }
                        break;
                    }
                    try items.append(this.alloc, current);

                    // Emit as nested calls: last(...(first))
                    var i: usize = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.emitExpr(items.items[i]);
                        try this.w("(");
                    }
                    try this.emitExpr(items.items[0]);
                    i = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.w(")");
                    }
                },

                .call => |cc| {
                    if (cc.is_builtin) {
                        if (std.mem.eql(u8, cc.callee, "print")) {
                            // @print(arg1, arg2, ...) becomes io:format("~p~n", [arg1, arg2, ...])
                            try this.w("io:format(\"~p~n\", [");
                            var first = true;
                            for (cc.args) |arg| {
                                if (!first) try this.w(", ");
                                try this.emitExpr(arg.value.*);
                                first = false;
                            }
                            try this.w("])");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "todo")) {
                            try this.w("erlang:error({todo, ");
                            if (cc.args.len > 0) {
                                try this.emitExpr(cc.args[0].value.*);
                            } else {
                                try this.w("\"not implemented\"");
                            }
                            try this.w("})");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "panic")) {
                            try this.w("erlang:error({panic, ");
                            if (cc.args.len > 0) {
                                try this.emitExpr(cc.args[0].value.*);
                            } else {
                                try this.w("\"panic\"");
                            }
                            try this.w("})");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "block")) {
                            // @block { ... } emits an immediately-invoked fun
                            // so the body executes and its value is the call result.
                            if (cc.args.len == 1) {
                                const arg = cc.args[0].value;
                                const isFunction = switch (arg.*) {
                                    .function => true,
                                    else => false,
                                };
                                if (!isFunction) return error.InvalidArgs;
                                try this.w("(fun() ->\n");
                                this.indent += 1;
                                try this.emitExpr(arg.*);
                                this.indent -= 1;
                                try this.w("\n");
                                try this.writeIndent();
                                try this.w("end)()");
                                return;
                            } else if (cc.trailing.len == 1 and cc.trailing[0].params.len == 0) {
                                // @block { body } - trailing lambda with no params
                                try this.w("(fun() ->\n");
                                this.indent += 1;
                                try this.emitBody(cc.trailing[0].body);
                                this.indent -= 1;
                                try this.w("\n");
                                try this.writeIndent();
                                try this.w("end)()");
                                return;
                            } else {
                                return error.InvalidArgs;
                            }
                        }
                        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
                            try this.emitResultOptionOp(cc.callee, cc.args);
                            return;
                        }
                        try this.fmt("{s}(", .{cc.callee});
                        var first = true;
                        for (cc.args) |arg| {
                            if (!first) try this.w(", ");
                            try this.emitExpr(arg.value.*);
                            first = false;
                        }
                        // Trailing lambdas: emit as fun args
                        for (cc.trailing) |tl| {
                            if (!first) try this.w(", ");
                            first = false;
                            try this.w("fun(");
                            for (tl.params, 0..) |p, pi| {
                                if (pi > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, p);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w(") ->\n");
                            const tl_saved = this.indent;
                            this.indent = this.indent + 1;
                            try this.emitBody(tl.body);
                            this.indent = tl_saved;
                            try this.w("\n");
                            try this.writeIndent();
                            try this.w("end");
                        }
                        try this.w(")");
                    } else {
                        // `recv_arg_emitted` tracks whether the receiver was
                        // already written as the first positional argument
                        // (activated extension dispatch) so the argument loop
                        // knows to prefix a comma.
                        var recv_arg_emitted = false;
                        if (cc.receiver) |recv| {
                            const mod_name: ?[]const u8 = switch (recv.*) {
                                .identifier => |id| switch (id.kind) {
                                    .ident => |n| if (isModuleRef(n)) n else null,
                                    else => null,
                                },
                                else => null,
                            };
                            if (this.rewrites.get(c.loc)) |_| {
                                // Activated extension dispatch: `recv.m(args)` →
                                // `m(Recv, args)`, a bare local call to the
                                // function emitted by `emitExtensionMethods`.
                                try this.fmt("{s}(", .{cc.callee});
                                try this.emitExpr(recv.*);
                                recv_arg_emitted = true;
                            } else if (mod_name != null and this.ext_names.contains(mod_name.?)) {
                                // Qualified extension call `Sym.m(obj)`: the
                                // receiver names the extension block, so it is
                                // not a module — call the bare local `m(obj)`.
                                try this.fmt("{s}(", .{cc.callee});
                            } else if (mod_name) |name| {
                                // A PascalCase identifier receiver is a module-qualified
                                // call: `List.map(xs, f)` → a remote call `list:map(Xs, F)`.
                                // The module name is lowercased to a valid atom; arity is
                                // implicit from the arg count (args + trailing lambdas).
                                const mod = try erlangModule(this.alloc, name);
                                defer this.alloc.free(mod);
                                try this.fmt("{s}:{s}(", .{ mod, cc.callee });
                            } else {
                                // Method call on a value receiver.
                                try this.emitExpr(recv.*);
                                try this.fmt(":{s}(", .{cc.callee});
                            }
                        } else if (this.externals.get(cc.callee)) |ref| {
                            // `@[external(erlang, "module", "symbol")]` fn:
                            // the call lowers to the remote `module:symbol(…)`.
                            try this.fmt("{s}:{s}(", .{ ref.module, ref.symbol });
                        } else if (this.externals_missing.contains(cc.callee)) {
                            // External fn with no `erlang` target — no symbol
                            // to call on this backend.
                            return error.MissingExternalTarget;
                        } else {
                            try this.fmt("{s}(", .{cc.callee});
                        }
                        var first = !recv_arg_emitted;
                        for (cc.args) |arg| {
                            if (!first) try this.w(", ");
                            try this.emitExpr(arg.value.*);
                            first = false;
                        }
                        // Trailing lambdas: emit as fun args
                        for (cc.trailing) |tl| {
                            if (!first) try this.w(", ");
                            first = false;
                            try this.w("fun(");
                            for (tl.params, 0..) |p, pi| {
                                if (pi > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, p);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w(") ->\n");
                            const tl_saved = this.indent;
                            this.indent = this.indent + 1;
                            try this.emitBody(tl.body);
                            this.indent = tl_saved;
                            try this.w("\n");
                            try this.writeIndent();
                            try this.w("end");
                        }
                        try this.w(")");
                    }
                },
            },

            .function => |func| {
                try this.w("fun(");
                for (func.kind.params, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, p);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w(") ->\n");
                const lam_saved = this.indent;
                this.indent = this.indent + 1;
                try this.emitBody(func.kind.body);
                this.indent = lam_saved;
                try this.w("\n");
                try this.writeIndent();
                try this.w("end");
            },

            .collection => |col| switch (col.kind) {
                .grouped => |inner| {
                    try this.w("(");
                    try this.emitExpr(inner.*);
                    try this.w(")");
                },
                .arrayLit => |al| {
                    // Special handling for spreadExpr: use ++ operator for list concatenation
                    if (al.spreadExpr) |se| {
                        // Emit the first part as a list
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        try this.w("]");

                        // Use ++ to concatenate with the spread expression
                        try this.w(" ++ ");
                        try this.emitExpr(se.*);
                    } else {
                        // Normal array literal or simple spread (identifier)
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        if (al.spread) |name| {
                            if (al.elems.len > 0) try this.w(", ");
                            if (name.len > 0) try this.w(name);
                        }
                        try this.w("]");
                    }
                },
                .tupleLit => |tl| {
                    try this.w("{");
                    for (tl.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitExpr(elem);
                    }
                    try this.w("}");
                },
                .case => |c| try this.emitCase(c.subjects, c.arms),
                .range => |r| {
                    try this.w("lists:seq(");
                    try this.emitExpr(r.start.*);
                    try this.w(", ");
                    if (r.end) |end| try this.emitExpr(end.*) else try this.w("infinity");
                    try this.w(")");
                },
            },

            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |val| try this.emitExpr(val.*),
                .throw_ => |r| if (r) |val| {
                    try this.w("erlang:throw(");
                    try this.emitExpr(val.*);
                    try this.w(")");
                },
                .try_ => |t| if (t) |val| try this.emitExpr(val.*),
                .await_ => |av| try this.emitExpr(av.*),
                .@"break" => |b| if (b) |bp| try this.emitExpr(bp.*),
                .yield => |y| if (y.value) |val| try this.emitExpr(val.*),
                .@"continue" => try this.w("%% continue"),
            },

            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    try this.w("case ");
                    try this.emitExpr(i.cond.*);
                    try this.w(" of\n");
                    this.indent += 1;
                    try this.writeIndent();
                    if (i.binding) |_| {
                        try this.w("undefined -> undefined;\n");
                        try this.writeIndent();
                        try this.w("_ ->\n");
                    } else {
                        try this.w("true ->\n");
                    }
                    this.indent += 1;
                    try this.emitBranchBody(i.then_);
                    this.indent -= 1;
                    if (i.else_) |els| {
                        try this.w(";\n");
                        try this.writeIndent();
                        try this.w("false ->\n");
                        this.indent += 1;
                        try this.emitBranchBody(els);
                        this.indent -= 1;
                    } else {
                        // No else branch — emit a catch-all so the case
                        // doesn't crash when the condition is false.
                        try this.w(";\n");
                        try this.writeIndent();
                        try this.w("_ -> ok");
                    }
                    this.indent -= 1;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
                .tryCatch => |tc| {
                    // `try expr catch handler` → pattern match on the Result tag.
                    //   case Expr of {ok, V} -> V; {error, E} -> Handler end
                    const handler = tc.handler.*;
                    const is_jump = switch (handler) {
                        .jump => |j| switch (j.kind) {
                            .throw_, .@"return", .@"break", .@"continue", .yield => true,
                            else => false,
                        },
                        else => false,
                    };
                    const is_fun = switch (handler) {
                        .function => true,
                        else => false,
                    };
                    const n = this.try_seq;
                    this.try_seq += 1;

                    try this.w("case ");
                    try this.emitExpr(tc.expr.*);
                    try this.w(" of\n");
                    this.indent += 1;
                    try this.writeIndent();
                    try this.fmt("{{ok, TryV{d}}} -> TryV{d};\n", .{ n, n });
                    try this.writeIndent();
                    try this.fmt("{{error, _TryE{d}}} ->\n", .{n});
                    this.indent += 1;
                    try this.writeIndent();
                    try this.emitExpr(handler);
                    if (is_fun) {
                        try this.fmt("(_TryE{d})", .{n});
                    } else if (is_jump) {
                        // handler already emitted its own control-flow expression
                    }
                    this.indent -= 2;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
            },

            .loop => |lp| {
                const has_yield = blk: {
                    for (lp.body) |stmt| {
                        if (switch (stmt.expr) {
                            .jump => |j| j.kind == .yield,
                            else => false,
                        }) break :blk true;
                    }
                    break :blk false;
                };
                const fun_kw = if (has_yield) "lists:map" else "lists:foreach";
                try this.fmt("{s}(fun(", .{fun_kw});
                for (lp.params, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, p);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w(") ->\n");
                const fun_body_indent = this.indent + 1;
                const saved2 = this.indent;
                this.indent = fun_body_indent;
                try this.emitBody(lp.body);
                this.indent = saved2;
                try this.w("\n");
                try this.writeIndent();
                try this.w("end, ");
                try this.emitExpr(lp.iter.*);
                try this.w(")");
            },

            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    switch (a.target) {
                        .name => |name| {
                            const vname = try erlangVar(this.alloc, name);
                            defer this.alloc.free(vname);
                            switch (a.op) {
                                .assign => try this.fmt("{s} = ", .{vname}),
                                .plusAssign => try this.fmt("{s} = {s} + ", .{ vname, vname }),
                            }
                            try this.emitExpr(a.value.*);
                        },
                        .fieldAccess => |*fa| {
                            // Erlang records don't support mutation like this; emit a comment
                            try this.fmt("%% {s}.{s} = ...", .{ "self", fa.field });
                        },
                    }
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
            },

            // `use` is a transparent prefix in Erlang: lower the wrapped call.
            // Any binding is handled by the enclosing `val` (localBind/Destruct),
            // so the hook result lands in a bound variable (a per-process slot).
            .useHook => |uh| try this.emitExpr(uh.kind.inner.*),

            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| try this.emitExpr(inner.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .jump => |j| switch (j.kind) {
                                .@"break" => |y| {
                                    if (y) |yp| try this.emitExpr(yp.*);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                    }
                },
                .assert => |a| {
                    if (this.test_mode) {
                        // Raise a tagged error the test runner catches per
                        // test (records the failure and continues).
                        try this.w("case (");
                        try this.emitExpr(a.condition.*);
                        try this.w(") of true -> ok; _ -> erlang:error({bp_assert, ");
                        if (a.message) |msg| {
                            try this.emitExpr(msg.*);
                        } else {
                            try this.w("<<\"assertion failed\">>");
                        }
                        try this.fmt(", <<\"{s}.bp:{d}\">>}}) end", .{ this.module_name, ct.loc.line });
                    } else {
                        // Erlang doesn't have built-in assert, so we use pattern matching
                        try this.w("true = (");
                        try this.emitExpr(a.condition.*);
                        try this.w(")");
                    }
                },
                .assertPattern => |ap| {
                    // Use Erlang's native pattern matching with case expressions
                    try this.w("case ");
                    try this.emitExpr(ap.expr.*);
                    try this.w(" of ");

                    // Emit the pattern
                    try this.emitPattern(ap.pattern);
                    try this.w(" -> ");

                    // On successful match, return the matched value
                    try this.emitExpr(ap.expr.*);

                    try this.w("; _ -> ");

                    // Handle the failure case
                    try this.emitExpr(ap.handler.*);

                    try this.w(" end");
                },
            },
        }
    }

    // ── if branch body (delegates to emitBody) ────────────────────────────────

    fn emitBranchBody(this: *Emitter, body: []const ast.Stmt) !void {
        try this.emitBody(body);
    }

    // ── case expression ───────────────────────────────────────────────────────

    fn emitCase(this: *Emitter, subjects: []ast.Expr, arms: []ast.CaseArm) !void {
        try this.w("case ");
        if (subjects.len == 1) {
            try this.emitExpr(subjects[0]);
        } else {
            try this.w("{");
            for (subjects, 0..) |s, i| {
                if (i > 0) try this.w(", ");
                try this.emitExpr(s);
            }
            try this.w("}");
        }
        try this.w(" of\n");
        this.indent += 1;

        var first_clause = true;
        for (arms) |arm| {
            // OR patterns expand to multiple Erlang clauses with the same body
            switch (arm.pattern) {
                .@"or" => |pats| {
                    for (pats) |p| {
                        if (!first_clause) try this.w(";\n");
                        try this.writeIndent();
                        try this.emitPattern(p);
                        try this.w(" ->\n");
                        this.indent += 1;
                        try this.emitCaseBody(arm.body);
                        this.indent -= 1;
                        first_clause = false;
                    }
                },
                .multi => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
                else => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
            }
        }

        this.indent -= 1;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end");
    }

    fn emitPattern(this: *Emitter, pat: ast.Pattern) !void {
        switch (pat) {
            .wildcard => try this.w("_"),
            .ident => |n| try this.w(n), // enum variant → atom
            .numberLit => |n| try this.w(n),
            .stringLit => |s| try this.emitBinary(s),
            .variant => |v| switch (v.payload) {
                .binding => |binding| {
                    const vname = try erlangVar(this.alloc, binding);
                    defer this.alloc.free(vname);
                    try this.fmt("{{tag, {s}, {s}}}", .{ v.name, vname });
                },
                .fields => |fields| {
                    try this.fmt("{{tag, {s}", .{v.name});
                    for (fields) |bb| {
                        try this.w(", ");
                        const vname = try erlangVar(this.alloc, bb);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                    try this.w("}");
                },
                .literals => |args| {
                    try this.fmt("{{tag, {s}", .{v.name});
                    for (args) |arg| {
                        try this.w(", ");
                        try this.emitPattern(arg);
                    }
                    try this.w("}");
                },
            },
            .list => |lp| {
                if (lp.spread) |sp| {
                    if (lp.elems.len == 0 and sp.len == 0) {
                        try this.w("_");
                    } else {
                        try this.w("[");
                        for (lp.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitListPatElem(elem);
                        }
                        if (sp.len > 0) {
                            if (lp.elems.len > 0) try this.w(" | ");
                            const vname = try erlangVar(this.alloc, sp);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        } else {
                            try this.w(" | _");
                        }
                        try this.w("]");
                    }
                } else if (lp.elems.len == 0) {
                    try this.w("[]");
                } else {
                    try this.w("[");
                    for (lp.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitListPatElem(elem);
                    }
                    try this.w("]");
                }
            },
            .@"or" => |pats| {
                // Should be expanded by emitCase; fallback: emit first
                if (pats.len > 0) try this.emitPattern(pats[0]);
            },
            .multi => |pats| {
                try this.w("{");
                for (pats, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    try this.emitPattern(p);
                }
                try this.w("}");
            },
        }
    }

    fn emitListPatElem(this: *Emitter, elem: ast.ListPatternElem) !void {
        switch (elem) {
            .wildcard => try this.w("_"),
            .bind => |name| {
                const vname = try erlangVar(this.alloc, name);
                defer this.alloc.free(vname);
                try this.w(vname);
            },
            .numberLit => |n| try this.w(n),
        }
    }

    fn emitCaseBody(this: *Emitter, body: ast.Expr) !void {
        switch (body) {
            .function => |func| switch (func.kind.syntax) {
                .lambda => {
                    // Multi-statement block: emitBody handles indentation via this.indent
                    try this.emitBody(func.kind.body);
                },
                .fnExpr => {
                    // Single expression: emit with current indentation
                    try this.writeIndent();
                    try this.emitExpr(body);
                },
            },
            else => {
                // Single expression: emit with current indentation
                try this.writeIndent();
                try this.emitExpr(body);
            },
        }
    }

    // ── struct / record / enum ────────────────────────────────────────────────

    fn emitStruct(this: *Emitter, s: ast.StructDecl) !void {
        try this.fmt("-record({s}, {{", .{s.name});
        var first = true;
        for (s.members) |m| switch (m) {
            .field => |f| {
                if (!first) try this.w(", ");
                try this.w(f.name);
                first = false;
            },
            else => {},
        };
        try this.w("}).\n");
        // Emit methods as standalone functions
        for (s.members) |m| switch (m) {
            .method => |md| {
                if (md.is_declare) continue;
                try this.w("\n");
                try this.emitFn(.{
                    .isPub = false,
                    .name = md.name,
                    .annotations = &.{},
                    .genericParams = &.{},
                    .params = md.params,
                    .returnType = md.returnType,
                    .body = md.body orelse &.{},
                });
            },
            else => {},
        };
    }

    fn emitRecord(this: *Emitter, r: ast.RecordDecl) !void {
        try this.fmt("-record({s}, {{", .{r.name});
        for (r.fields, 0..) |f, i| {
            if (i > 0) try this.w(", ");
            try this.w(f.name);
        }
        try this.w("}).\n");
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitEnum(this: *Emitter, e: ast.EnumDecl) !void {
        try this.fmt("%% enum {s}\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try this.fmt("%%   {s}\n", .{v.name});
            } else {
                try this.fmt("%%   {s}(", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try this.w(", ");
                    try this.w(f.name);
                }
                try this.w(")\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitInterface(this: *Emitter, i: ast.InterfaceDecl) !void {
        try this.fmt("%% interface {s}\n", .{i.name});
    }

    fn emitImplement(this: *Emitter, im: ast.ImplementDecl) !void {
        try this.w("%% implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try this.w(", ");
            try this.w(iface);
        }
        try this.fmt(" for {s}\n", .{im.target});
        try this.emitExtensionMethods(im.methods);
    }

    fn emitExtend(this: *Emitter, ex: ast.ExtendDecl) !void {
        try this.fmt("%% extend {s}\n", .{ex.target});
        try this.emitExtensionMethods(ex.methods);
    }

    /// Extension methods (from `implement`/`extend`) are emitted as bare
    /// top-level functions that take the receiver as their first param, so an
    /// activated `recv.m(args)` dispatch can call `m(Recv, args)` directly.
    fn emitExtensionMethods(this: *Emitter, methods: []const ast.ImplementMethod) !void {
        const saved_keep_self = this.keep_self;
        this.keep_self = true;
        defer this.keep_self = saved_keep_self;
        for (methods) |m| {
            try this.w("\n");
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body,
            });
        }
    }

    fn emitUse(this: *Emitter, u: ast.ImportDecl) !void {
        try this.w(if (u.activationOnly) "%% activate " else "%% import ");
        for (u.imports, 0..) |imp, i| {
            if (i > 0) try this.w(", ");
            try this.w(imp.name());
        }
        try this.w("\n");
    }

    // ── binary string helper ─────────────────────────────────────────────────

    fn emitBinary(this: *Emitter, s: []const u8) !void {
        try this.w("<<\"");
        for (s) |c| switch (c) {
            '"' => try this.w("\\\""),
            '\\' => try this.w("\\\\"),
            '\n' => try this.w("\\n"),
            '\r' => try this.w("\\r"),
            '\t' => try this.w("\\t"),
            else => try this.out.writeByte(c),
        };
        try this.w("\">>");
    }
};
