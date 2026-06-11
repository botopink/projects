/// `botopink-lib-test` — run every `libs/` project's test suite on each requested
/// backend and aggregate the results into a lib×target matrix.
///
/// Usage:
///   botopink-lib-test [--target <t>[,<t>…] | --target all]
///                     [--lib <name>] [--filter <s>] [--strict] [--bin <path>]
///
/// It discovers every lib under `libs/` carrying a `botopink.json`, runs
/// `botopink test --target <t>` with `cwd` set to each lib, and **exits non-zero
/// iff any cell fails** — the missing CI gate for the lib ecosystem. It shells out
/// to the installed `botopink` binary and touches no compiler internals.
const std = @import("std");
const args = @import("args.zig");
const discovery = @import("discovery.zig");
const matrix = @import("matrix.zig");
const runner = @import("runner.zig");

const HELP =
    \\botopink-lib-test — run every libs/ project's tests per backend
    \\
    \\Usage:
    \\  botopink-lib-test [options]
    \\
    \\Options:
    \\  --target <t>[,<t>…]   Targets to run; repeatable. Accepts commonJS|erlang|
    \\                        beam|wasm plus the alias node→commonJS, and --target=<t>.
    \\                        `all` expands to every supported target.
    \\                        Default: commonJS,erlang.
    \\  --lib <name>          Restrict to one lib under libs/ (default: all).
    \\  --filter <s>          Forwarded to `botopink test --filter`.
    \\  --strict              Treat an unsupported target as a failure, not a skip.
    \\  --bin <path>          Path to the `botopink` binary (env: BOTOPINK_BIN;
    \\                        default: ./zig-out/bin/botopink, else PATH).
    \\  -h, --help            Show this message.
    \\
;

pub fn main(init: std.process.Init) void {
    const exit_code = run(init) catch |err| blk: {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{@errorName(err)});
        break :blk 1;
    };
    if (exit_code != 0) std.process.exit(exit_code);
}

fn run(init: std.process.Init) !u8 {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    const argv = try init.minimal.args.toSlice(arena);
    const rest = if (argv.len > 1) argv[1..] else argv[0..0];

    for (rest) |a| {
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            std.Io.File.stdout().writeStreamingAll(io, HELP) catch {};
            return 0;
        }
    }

    const opts = args.parse(arena, rest) catch |err| {
        switch (err) {
            error.MissingArgument => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: a flag is missing its argument\n", .{}),
            error.InvalidTarget => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown --target (use commonJS|erlang|beam|wasm|node|all)\n", .{}),
            error.UnknownFlag => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: unknown flag (run with --help)\n", .{}),
            else => return err,
        }
        return 2;
    };

    // Resolve the repo root (cwd), the libs root, and the botopink binary —
    // all as absolute paths so each child's `cwd = libs/<lib>` stays consistent.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_len = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_len];

    const libs_root = findLibsRoot(arena, io, cwd) orelse {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no libs/ directory found in this or any parent directory\n", .{});
        return 1;
    };

    const bin = try resolveBin(arena, io, cwd, opts.bin, init.environ_map.get("BOTOPINK_BIN"));

    // Discover libs.
    const libs = discovery.discover(gpa, io, libs_root, opts.lib) catch |err| {
        switch (err) {
            error.LibsRootNotFound => std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: libs/ directory could not be read\n", .{}),
            else => return err,
        }
        return 1;
    };
    defer discovery.free(gpa, libs);

    if (libs.len == 0) {
        if (opts.lib) |name| {
            std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no lib named '{s}' found under {s}\n", .{ name, libs_root });
            return 1;
        }
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: no libs found under {s}\n", .{libs_root});
        return 1;
    }

    // Run each (lib, target) cell.
    var lib_names = try arena.alloc([]const u8, libs.len);
    var cells = try arena.alloc([]matrix.Status, libs.len);
    var summary: matrix.Summary = .{};

    for (libs, 0..) |lib, r| {
        lib_names[r] = lib.name;
        cells[r] = try arena.alloc(matrix.Status, opts.targets.len);
        for (opts.targets, 0..) |target, c| {
            const status: matrix.Status = if (!lib.has_tests)
                .no_tests
            else
                try runner.runCell(arena, io, bin, libs_root, lib.name, target, opts.filter, opts.strict);
            cells[r][c] = status;
            summary.tally(status);
        }
    }

    // Render the matrix.
    const cells_const = try arena.alloc([]const matrix.Status, libs.len);
    for (cells, 0..) |row, i| cells_const[i] = row;
    const text = try matrix.render(arena, lib_names, opts.targets, cells_const, summary);
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};

    // Exit non-zero iff any cell failed.
    return if (summary.failed > 0) 1 else 0;
}

/// Walk up from `start` until a directory containing a readable `libs/` is found.
/// Returns the absolute path to that `libs/` (arena-owned), or null.
fn findLibsRoot(arena: std.mem.Allocator, io: std.Io, start: []const u8) ?[]const u8 {
    var dir: []const u8 = start;
    while (true) {
        const candidate = std.fs.path.join(arena, &.{ dir, "libs" }) catch return null;
        var d = std.Io.Dir.cwd().openDir(io, candidate, .{ .iterate = true }) catch {
            const parent = std.fs.path.dirname(dir) orelse return null;
            if (std.mem.eql(u8, parent, dir)) return null;
            dir = parent;
            continue;
        };
        d.close(io);
        return candidate;
    }
}

/// Resolve the `botopink` binary path. Precedence: `--bin` flag, then
/// `BOTOPINK_BIN`, then `<cwd>/zig-out/bin/botopink` if it exists, else the bare
/// name `botopink` (resolved via PATH). Any path containing a separator is made
/// absolute against `cwd` so it survives the child's `cwd = libs/<lib>` chdir.
fn resolveBin(
    arena: std.mem.Allocator,
    io: std.Io,
    cwd: []const u8,
    flag: ?[]const u8,
    env: ?[]const u8,
) ![]const u8 {
    if (flag orelse env) |override| {
        return absolutize(arena, cwd, override);
    }

    const local = try std.fs.path.join(arena, &.{ cwd, "zig-out", "bin", "botopink" });
    std.Io.Dir.cwd().access(io, local, .{}) catch {
        // Not built locally — fall back to PATH lookup of the bare name.
        return "botopink";
    };
    return local;
}

/// Make `path` absolute against `base`, unless it is a bare name (no separator),
/// which must stay bare so the child resolves it via PATH.
fn absolutize(arena: std.mem.Allocator, base: []const u8, path: []const u8) ![]const u8 {
    if (std.fs.path.isAbsolute(path)) return path;
    if (std.mem.indexOfScalar(u8, path, '/') == null) return path; // bare name → PATH
    return std.fs.path.join(arena, &.{ base, path });
}
