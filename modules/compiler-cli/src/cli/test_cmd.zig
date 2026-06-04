/// `botopink test` — compile in test mode then run every test block.
///
/// Compiles the project with `test_mode = true` (test blocks emit as
/// functions + a registry + runner entry; `fn main/0` is not auto-invoked),
/// writes artifacts under `.botopinkbuild/test-out/`, then executes each
/// module that contains tests and aggregates the exit codes.
///
/// Currently only the `commonJS` target runs tests (node); other targets
/// are pending phases of the `test-blocks` spec.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const scanner = @import("./scanner.zig");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    /// `--filter <substr>` — only run tests whose name contains the substring.
    filter: ?[]const u8 = null,
};

const TEST_OUT_DIR = ".botopinkbuild/test-out";

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget();
    if (target != .commonJS and target != .erlang) {
        reporter.errMsg("`botopink test` currently supports only the commonJS and erlang targets");
        reporter.hintMsg("run with `--target commonJS` or set \"target\": \"commonJS\" in botopink.json");
        return 1;
    }

    // Scan source files: `src/` (inline test blocks) plus `test/` (separate
    // `*_test.bp` suites). Test modules come last so `src/` exports are
    // already registered when they compile.
    const src_modules = try scanner.scanSources(gpa, io, "src");
    defer scanner.freeModules(gpa, src_modules);
    const test_modules = try scanner.scanSources(gpa, io, "test");
    defer scanner.freeModules(gpa, test_modules);

    const modules = try std.mem.concat(arena, bp.Module, &.{ src_modules, test_modules });

    if (modules.len == 0) {
        reporter.errMsg("no source files found in src/ or test/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    reporter.compiling(modules.len);

    // Build codegen config in test mode.
    const cfg = bp.codegen.Config{
        .targetSource = switch (target) {
            .commonJS => .commonJS,
            .erlang => .erlang,
            else => unreachable, // guarded above
        },
        .comptimeRuntime = switch (target) {
            .commonJS => .node,
            .erlang => .erlang,
            else => unreachable,
        },
        .build_root = ".botopinkbuild",
        .test_mode = true,
    };

    var outputs = bp.codegen.generate(gpa, modules, io, cfg) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    // Check for comptime errors in outputs.
    var had_error = false;
    for (outputs.items) |o| {
        if (o.result.comptime_err) |ce| {
            had_error = true;
            const rendered = ce.renderAlloc(gpa, o.src) catch continue;
            defer gpa.free(rendered);
            std.debug.print("{s}", .{rendered});
        }
    }
    if (had_error) return 1;

    // Modules with parse/type errors produce no output at all — surface that
    // instead of silently skipping their tests.
    if (outputs.items.len < modules.len) {
        const msg = try std.fmt.allocPrint(
            arena,
            "{d} module(s) failed to compile — run `botopink check` for diagnostics",
            .{modules.len - outputs.items.len},
        );
        reporter.errMsg(msg);
        return 1;
    }

    // Write every module's test-mode artifact (test modules `require` their
    // sibling modules on commonJS), then run each module that contains tests.
    std.Io.Dir.cwd().createDirPath(io, TEST_OUT_DIR) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext: []const u8 = switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        else => unreachable,
    };
    const runner: []const u8 = switch (target) {
        .commonJS => "node",
        .erlang => "escript",
        else => unreachable,
    };

    for (outputs.items) |o| {
        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });
    }

    // commonJS: root-source imports (`import {x};`) emit `require("./module")`
    // — write a `module.js` aggregator that merges every module's exports.
    // Runners only execute as the entry module (`require.main === module`),
    // so requiring a sibling never re-runs its tests.
    if (target == .commonJS) {
        var agg = std.ArrayListUnmanaged(u8).empty;
        defer agg.deinit(arena);
        try agg.appendSlice(arena, "module.exports = Object.assign({}");
        for (outputs.items) |o| {
            try agg.appendSlice(arena, ", require(\"./");
            try agg.appendSlice(arena, o.name);
            try agg.appendSlice(arena, ".js\")");
        }
        try agg.appendSlice(arena, ");\n");
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = TEST_OUT_DIR ++ "/module.js", .data = agg.items });
    }

    var any_tests = false;
    var exit_code: u8 = 0;
    for (outputs.items) |o| {
        // Modules without test blocks have no runner — skip them.
        if (std.mem.indexOf(u8, o.result.js, "__bp_run_tests") == null) continue;
        any_tests = true;

        const sub_path = try std.fmt.allocPrint(arena, TEST_OUT_DIR ++ "/{s}{s}", .{ o.name, ext });

        var argv = std.ArrayListUnmanaged([]const u8).empty;
        defer argv.deinit(arena);
        try argv.append(arena, runner);
        try argv.append(arena, sub_path);
        if (opts.filter) |f| try argv.append(arena, f);

        // Spawn and wait — stdio is inherited so the runner reports directly.
        var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
            const msg = try std.fmt.allocPrint(arena, "failed to spawn '{s}': {s}", .{ runner, @errorName(err) });
            reporter.errMsg(msg);
            return 1;
        };
        defer child.kill(io);

        const term = try child.wait(io);
        const code: u8 = switch (term) {
            .exited => |c| c,
            .signal, .stopped, .unknown => 1,
        };
        if (code != 0) exit_code = code;
    }

    if (!any_tests) {
        reporter.stdout(io, "no test blocks found\n");
        return 0;
    }

    return exit_code;
}
