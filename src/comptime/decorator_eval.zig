/// Decorator invocation — single persistent erl runtime.
///
/// A decorator is a comptime function whose first parameter is `comptime _:
/// @Decl`. When `#[d(args)]` is applied to a declaration, the core serializes
/// that declaration into a `@Decl` handle and runs the decorator body inside
/// the persistent erl subprocess.
///
/// The decompiler (emitBpBody / emitBpStmt / emitBpExpr) is shared with
/// template_eval.zig and lives there as public functions.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erl_emitter = @import("./erl_emitter.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

/// Native representation of a `@Decl` handle — replaces JSON intermediate format.
pub const DeclHandle = struct {
    kind: []const u8,
    name: []const u8,
    fields: []const Field,
    methods: []const Method,
    returnType: []const u8,
    annotations: []const Annotation,

    pub const Field = struct {
        name: []const u8,
        typeName: []const u8,
        annotations: []const Annotation = &.{},
    };

    pub const Method = struct {
        name: []const u8,
        params: []const Param,
        returnType: []const u8,
        annotations: []const Annotation = &.{},
    };

    pub const Param = struct {
        name: []const u8,
        typeName: []const u8,
    };

    pub const Annotation = struct {
        name: []const u8,
        args: []const []const u8,
    };

    /// Emit this handle as Erlang terms bound to the given variable name.
    pub fn emitErl(
        self: *const DeclHandle,
        buf: *std.ArrayListUnmanaged(u8),
        arena: std.mem.Allocator,
        var_name: []const u8,
    ) std.mem.Allocator.Error!void {
        var entries = try arena.alloc(erl_emitter.MapEntry, 6);
        entries[0] = .{ .key = "kind", .value = .{ .string = self.kind } };
        entries[1] = .{ .key = "name", .value = .{ .string = self.name } };
        entries[2] = .{ .key = "fields", .value = .{ .list = try self.emitFieldsErl(arena) } };
        entries[3] = .{ .key = "methods", .value = .{ .list = try self.emitMethodsErl(arena) } };
        entries[4] = .{ .key = "returnType", .value = .{ .string = self.returnType } };
        entries[5] = .{ .key = "annotations", .value = .{ .list = try self.emitAnnotationsErl(arena) } };

        try erl_emitter.emitMap(buf, arena, var_name, entries);
    }

    fn emitFieldsErl(self: *const DeclHandle, arena: std.mem.Allocator) std.mem.Allocator.Error![]const erl_emitter.ErlValue {
        var fields = try arena.alloc(erl_emitter.ErlValue, self.fields.len);
        for (self.fields, 0..) |f, i| {
            var field_entries = try arena.alloc(erl_emitter.MapEntry, 3);
            field_entries[0] = .{ .key = "name", .value = .{ .string = f.name } };
            field_entries[1] = .{ .key = "typeName", .value = .{ .string = f.typeName } };
            field_entries[2] = .{ .key = "annotations", .value = .{ .list = try self.emitAnnotationsErl(arena) } };
            fields[i] = .{ .map = field_entries };
        }
        return fields;
    }

    fn emitMethodsErl(self: *const DeclHandle, arena: std.mem.Allocator) std.mem.Allocator.Error![]const erl_emitter.ErlValue {
        var methods = try arena.alloc(erl_emitter.ErlValue, self.methods.len);
        for (self.methods, 0..) |m, i| {
            var params = try arena.alloc(erl_emitter.ErlValue, m.params.len);
            for (m.params, 0..) |p, j| {
                var param_entries = try arena.alloc(erl_emitter.MapEntry, 2);
                param_entries[0] = .{ .key = "name", .value = .{ .string = p.name } };
                param_entries[1] = .{ .key = "typeName", .value = .{ .string = p.typeName } };
                params[j] = .{ .map = param_entries };
            }

            var method_entries = try arena.alloc(erl_emitter.MapEntry, 4);
            method_entries[0] = .{ .key = "name", .value = .{ .string = m.name } };
            method_entries[1] = .{ .key = "params", .value = .{ .list = params } };
            method_entries[2] = .{ .key = "returnType", .value = .{ .string = m.returnType } };
            method_entries[3] = .{ .key = "annotations", .value = .{ .list = try self.emitAnnotationsErl(arena) } };
            methods[i] = .{ .map = method_entries };
        }
        return methods;
    }

    fn emitAnnotationsErl(self: *const DeclHandle, arena: std.mem.Allocator) std.mem.Allocator.Error![]const erl_emitter.ErlValue {
        var annotations = try arena.alloc(erl_emitter.ErlValue, self.annotations.len);
        for (self.annotations, 0..) |a, i| {
            var args = try arena.alloc(erl_emitter.ErlValue, a.args.len);
            for (a.args, 0..) |arg, j| {
                args[j] = .{ .string = arg };
            }

            var ann_entries = try arena.alloc(erl_emitter.MapEntry, 2);
            ann_entries[0] = .{ .key = "name", .value = .{ .string = a.name } };
            ann_entries[1] = .{ .key = "args", .value = .{ .list = args } };
            annotations[i] = .{ .map = ann_entries };
        }
        return annotations;
    }
};

pub const Outcome = union(enum) {
    ok: []const []const u8,
    fail: struct { message: []const u8, span: ?template.Span },
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

const ErlResult = struct {
    kind: []const u8,
    message: ?[]const u8 = null,
    contributions: ?[]const []const u8 = null,
    span: ?ErlSpan = null,
};

const ErlSpan = struct {
    start: usize,
    end: usize = 0,
    line: usize = 1,
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) !Outcome {
    const result = std.json.parseFromSliceLeaky(ErlResult, arena, stdout, .{ .ignore_unknown_fields = true }) catch {
        return .{ .err = try std.fmt.allocPrint(arena, "decorator evaluator produced no result", .{}) };
    };

    if (std.mem.eql(u8, result.kind, "ok")) {
        const contributions = result.contributions orelse &.{};
        return .{ .ok = contributions };
    }
    if (std.mem.eql(u8, result.kind, "fail")) {
        const message = result.message orelse "decorator rejected the declaration";
        const span: ?template.Span = if (result.span) |s|
            .{ .start = s.start, .end = if (s.end == 0) s.start else s.end, .line = s.line }
        else
            null;
        return .{ .fail = .{ .message = message, .span = span } };
    }
    const message = result.message orelse "decorator evaluation failed";
    return .{ .err = message };
}

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = build_root;
    return evaluateErl(arena, io, dfn, handle, plainArgs);
}

fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    std.debug.print("decorator_eval: starting evaluation for fn '{s}'\n", .{dfn.name});

    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(arena);

    const hash = std.hash.Wyhash.hash(0, dfn.name);
    const mod_name = try std.fmt.allocPrint(arena, "decorator_{x}", .{hash});

    try buildErlModule(&buf, arena, mod_name, dfn, handle, plainArgs);

    const tmp_dir = try std.fmt.allocPrint(arena, ".botopinkbuild/tmp/{s}", .{mod_name});
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch |err| {
        std.debug.print("decorator_eval: createDirPath failed: {}\n", .{err});
        return error.EvalFailed;
    };
    const erl_path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ tmp_dir, mod_name });
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = buf.items }) catch |err| {
        std.debug.print("decorator_eval: writeFile failed: {}\n", .{err});
        return error.EvalFailed;
    };

    const persistent_erl = @import("./runtime/persistent_erl.zig");
    const stdout = persistent_erl.eval(arena, io, erl_path) catch |err| {
        std.debug.print("decorator_eval: persistent_erl.eval failed: {}\n", .{err});
        return error.EvalFailed;
    };
    defer arena.free(stdout);
    return parseOutcome(arena, stdout) catch |err| {
        std.debug.print("decorator_eval: parseOutcome failed: {}\n", .{err});
        return error.EvalFailed;
    };
}

fn buildErlModule(
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    mod_name: []const u8,
    dfn: ast.FnDecl,
    handle: DeclHandle,
    plainArgs: []const template.PlainArg,
) !void {
    try buf.appendSlice(arena, "-module(");
    try buf.appendSlice(arena, mod_name);
    try buf.appendSlice(arena, ").\n-export([main/0]).\n\n");

    for (plainArgs) |pa| {
        try erl_emitter.emitVar(buf, arena, pa.paramName);
        try buf.appendSlice(arena, "() -> ");
        try buf.appendSlice(arena, pa.jsValue);
        try buf.appendSlice(arena, ".\n");
    }

    try buf.appendSlice(arena, "\nmain() ->\n    try\n        ");
    try handle.emitErl(buf, arena, dfn.params[0].name);
    try buf.appendSlice(arena, ",\n        ");
    try emitBody(buf, arena, dfn);
    try buf.appendSlice(arena, ",\n        json:encode(#{kind => ok, contributions => []})\n");
    try buf.appendSlice(arena, "    catch\n");
    try buf.appendSlice(arena, "        throw:{fail, Msg} -> json:encode(#{kind => fail, message => Msg});\n");
    try buf.appendSlice(arena, "        throw:{compilerError, Msg} -> json:encode(#{kind => fail, message => Msg});\n");
    try buf.appendSlice(arena, "        throw:{emit, Src} -> json:encode(#{kind => ok, contributions => [Src]});\n");
    try buf.appendSlice(arena, "        Class:Reason -> json:encode(#{kind => error, message => iolist_to_binary(io_lib:format(\"~p:~p\", [Class, Reason]))})\n");
    try buf.appendSlice(arena, "    end.\n\n");

    try buf.appendSlice(arena, "fail(_Decl, Msg) -> throw({fail, Msg}).\n");
    try buf.appendSlice(arena, "compilerError(Msg) -> throw({compilerError, Msg}).\n");
    try buf.appendSlice(arena, "emit(Src) -> throw({emit, Src}).\n");
}

fn emitBody(
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    dfn: ast.FnDecl,
) !void {
    for (dfn.body, 0..) |stmt, i| {
        if (i > 0) try buf.appendSlice(arena, ",\n        ");
        try emitStmt(buf, arena, stmt.expr);
    }
}

fn emitStmt(
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    expr: ast.Expr,
) std.mem.Allocator.Error!void {
    switch (expr) {
        .binding => |b| {
            switch (b.kind) {
                .localBind => |lb| {
                    try erl_emitter.emitVar(buf, arena, lb.name);
                    try buf.appendSlice(arena, " = ");
                    try emitExpr(buf, arena, lb.value.*);
                },
                .assign => |a| {
                    switch (a.target) {
                        .name => |n| try erl_emitter.emitVar(buf, arena, n),
                        .fieldAccess => |fa| {
                            try emitExpr(buf, arena, fa.receiver.*);
                            try buf.appendSlice(arena, "#.");
                            try buf.appendSlice(arena, fa.field);
                        },
                    }
                    try buf.appendSlice(arena, " = ");
                    try emitExpr(buf, arena, a.value.*);
                },
                .localBindDestruct => try buf.appendSlice(arena, "undefined"),
            }
        },
        .branch => |b| {
            switch (b.kind) {
                .if_ => |if_| {
                    try buf.appendSlice(arena, "case ");
                    try emitExpr(buf, arena, if_.cond.*);
                    try buf.appendSlice(arena, " of\n            true -> ");
                    for (if_.then_, 0..) |s, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitStmt(buf, arena, s.expr);
                    }
                    if (if_.else_) |else_body| {
                        try buf.appendSlice(arena, ";\n            _ -> ");
                        for (else_body, 0..) |s, i| {
                            if (i > 0) try buf.appendSlice(arena, ", ");
                            try emitStmt(buf, arena, s.expr);
                        }
                    } else {
                        try buf.appendSlice(arena, ";\n            _ -> ok");
                    }
                    try buf.appendSlice(arena, "\n        end");
                },
                .tryCatch => try buf.appendSlice(arena, "undefined"),
            }
        },
        else => {
            try emitExpr(buf, arena, expr);
        },
    }
}

fn emitExpr(
    buf: *std.ArrayListUnmanaged(u8),
    arena: std.mem.Allocator,
    expr: ast.Expr,
) std.mem.Allocator.Error!void {
    switch (expr) {
        .literal => |lit| {
            switch (lit.kind) {
                .stringLit => |s| try erl_emitter.emitString(buf, arena, s),
                .numberLit => |n| try buf.appendSlice(arena, n),
                .null_ => try buf.appendSlice(arena, "undefined"),
                else => try buf.appendSlice(arena, "undefined"),
            }
        },
        .identifier => |id| {
            switch (id.kind) {
                .ident => |name| {
                    if (std.mem.eql(u8, name, "true")) {
                        try buf.appendSlice(arena, "true");
                    } else if (std.mem.eql(u8, name, "false")) {
                        try buf.appendSlice(arena, "false");
                    } else {
                        try erl_emitter.emitVar(buf, arena, name);
                    }
                },
                .dotIdent => |name| {
                    try buf.appendSlice(arena, try erlVarName(arena, name));
                },
                .identAccess => |acc| {
                    try emitExpr(buf, arena, acc.receiver.*);
                    if (std.mem.eql(u8, acc.member, "len")) {
                        try buf.appendSlice(arena, "_len()");
                    } else {
                        try buf.appendSlice(arena, "#.");
                        try buf.appendSlice(arena, acc.member);
                    }
                },
            }
        },
        .binaryOp => |b| {
            try buf.appendSlice(arena, "(");
            try emitExpr(buf, arena, b.lhs.*);
            try buf.appendSlice(arena, " ");
            const erl_op: []const u8 = switch (b.op) {
                .lt => "<",
                .gt => ">",
                .lte => "=<",
                .gte => ">=",
                .eq => "=:=",
                .ne => "=/=",
                .add => "++",
                .sub => "-",
                .mul => "*",
                .div => "div",
                .mod => "rem",
                .@"and" => "andalso",
                .@"or" => "orelse",
            };
            try buf.appendSlice(arena, erl_op);
            try buf.appendSlice(arena, " ");
            try emitExpr(buf, arena, b.rhs.*);
            try buf.appendSlice(arena, ")");
        },
        .call => |c| {
            switch (c.kind) {
                .call => |cl| {
                    if (cl.is_builtin) {
                        if (std.mem.eql(u8, cl.callee, "@emit")) {
                            try buf.appendSlice(arena, "emit(");
                            if (cl.args.len > 0) try emitExpr(buf, arena, cl.args[0].value.*);
                            try buf.appendSlice(arena, ")");
                            return;
                        } else if (std.mem.eql(u8, cl.callee, "@compilerError")) {
                            try buf.appendSlice(arena, "compilerError(");
                            if (cl.args.len > 0) try emitExpr(buf, arena, cl.args[0].value.*);
                            try buf.appendSlice(arena, ")");
                            return;
                        }
                    }
                    if (cl.receiver) |recv| {
                        try emitExpr(buf, arena, recv.*);
                        if (std.mem.eql(u8, cl.callee, "forEach")) {
                            try buf.appendSlice(arena, "_forEach(");
                        } else {
                            try buf.appendSlice(arena, ":");
                            try buf.appendSlice(arena, cl.callee);
                            try buf.appendSlice(arena, "(");
                        }
                    } else {
                        try buf.appendSlice(arena, cl.callee);
                        try buf.appendSlice(arena, "(");
                    }
                    for (cl.args, 0..) |arg, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitExpr(buf, arena, arg.value.*);
                    }
                    for (cl.trailing) |t| {
                        if (cl.args.len > 0) try buf.appendSlice(arena, ", ");
                        try buf.appendSlice(arena, "fun(");
                        for (t.params, 0..) |p, j| {
                            if (j > 0) try buf.appendSlice(arena, ", ");
                            try erl_emitter.emitVar(buf, arena, p);
                        }
                        try buf.appendSlice(arena, ") -> ");
                        for (t.body, 0..) |stmt, j| {
                            if (j > 0) try buf.appendSlice(arena, ", ");
                            try emitStmt(buf, arena, stmt.expr);
                        }
                        try buf.appendSlice(arena, " end)");
                    }
                    try buf.appendSlice(arena, ")");
                },
                .pipeline => |p| {
                    try buf.appendSlice(arena, "(");
                    try emitExpr(buf, arena, p.rhs.*);
                    try buf.appendSlice(arena, "(");
                    try emitExpr(buf, arena, p.lhs.*);
                    try buf.appendSlice(arena, "))");
                },
            }
        },
        .function => |f| {
            try buf.appendSlice(arena, "fun(");
            for (f.kind.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try erl_emitter.emitVar(buf, arena, p);
            }
            try buf.appendSlice(arena, ") -> ");
            for (f.kind.body, 0..) |stmt, i| {
                if (i > 0) try buf.appendSlice(arena, ", ");
                try emitStmt(buf, arena, stmt.expr);
            }
            try buf.appendSlice(arena, " end)");
        },
        .collection => |col| {
            switch (col.kind) {
                .arrayLit => |arr| {
                    try buf.appendSlice(arena, "[");
                    for (arr.elems, 0..) |elem, i| {
                        if (i > 0) try buf.appendSlice(arena, ", ");
                        try emitExpr(buf, arena, elem);
                    }
                    try buf.appendSlice(arena, "]");
                },
                else => try buf.appendSlice(arena, "undefined"),
            }
        },
        else => {
            try buf.appendSlice(arena, "undefined");
        },
    }
}

