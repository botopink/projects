/// Generic external-lib loader.
///
/// Resolves a project's declared `dependencies` (from `botopink.json`) to their
/// source modules on disk and returns them as `botopink.Module` values, prefixed
/// by lib name (`rakun/http`, `rakun/rakun`, …). This is the driver-side half of
/// the lib-agnostic package mechanism: the compiler core never names a specific
/// lib — it only sees ordinary `Module[]` and resolves `from "<lib>"` generically
/// through the shared import registry. `std` is the one embedded exception and is
/// NOT loaded here.
///
/// Lib layout (each lib carries its own manifest):
///   <libs_root>/<name>/botopink.json   { "src": "src/", "files": ["a.bp", …] }
///   <libs_root>/<name>/<src>/<file>
const std = @import("std");
const bp = @import("botopink");

const Module = bp.Module;

/// Minimal view of a lib's own `botopink.json` — only the fields the loader needs.
const LibManifest = struct {
    src: []const u8 = "src/",
    files: []const []const u8 = &.{},
};

pub const Error = error{
    LibsRootNotFound,
    LibNotFound,
    LibManifestInvalid,
} || std.mem.Allocator.Error;

/// Resolve the libs root: the nearest ancestor directory (starting at cwd) that
/// contains a `libs/` subdirectory. Returns the path to that `libs/` directory
/// (caller owns via `gpa`), or null if none is found.
pub fn resolveLibsRoot(gpa: std.mem.Allocator, io: std.Io) !?[]u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &buf);
    var dir = buf[0..n];

    while (true) {
        const candidate = try std.fs.path.join(gpa, &.{ dir, "libs" });
        const exists = blk: {
            var d = std.Io.Dir.cwd().openDir(io, candidate, .{}) catch break :blk false;
            d.close(io);
            break :blk true;
        };
        if (exists) return candidate;
        gpa.free(candidate);

        const parent = std.fs.path.dirname(dir) orelse return null;
        if (std.mem.eql(u8, parent, dir)) return null;
        dir = dir[0..parent.len];
    }
}

/// Load every module of every declared dependency. Returns a flat `Module[]`
/// (caller owns — free with `freeModules`). With no dependencies this returns an
/// empty slice without touching the filesystem.
pub fn loadDependencies(
    gpa: std.mem.Allocator,
    io: std.Io,
    deps: []const []const u8,
) ![]Module {
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    // On error, free what was accumulated, then the list backing — in this order
    // (a single block, not two errdefers, which would run LIFO and free the
    // backing before reading `.items`).
    errdefer {
        for (modules.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
        }
        modules.deinit(gpa);
    }

    if (deps.len == 0) return try modules.toOwnedSlice(gpa);

    const libs_root = (try resolveLibsRoot(gpa, io)) orelse return error.LibsRootNotFound;
    defer gpa.free(libs_root);

    for (deps) |dep| {
        try loadOne(gpa, io, libs_root, dep, &modules);
    }
    return try modules.toOwnedSlice(gpa);
}

fn loadOne(
    gpa: std.mem.Allocator,
    io: std.Io,
    libs_root: []const u8,
    dep: []const u8,
    out: *std.ArrayListUnmanaged(Module),
) !void {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const lib_dir = try std.fs.path.join(arena, &.{ libs_root, dep });
    const manifest_path = try std.fs.path.join(arena, &.{ lib_dir, "botopink.json" });

    const data = std.Io.Dir.cwd().readFileAlloc(io, manifest_path, arena, .limited(64 * 1024)) catch
        return error.LibNotFound;
    const manifest = std.json.parseFromSliceLeaky(LibManifest, arena, data, .{
        .ignore_unknown_fields = true,
    }) catch return error.LibManifestInvalid;

    for (manifest.files) |file| {
        const file_path = try std.fs.path.join(arena, &.{ lib_dir, manifest.src, file });
        const source = try std.Io.Dir.cwd().readFileAlloc(io, file_path, gpa, .unlimited);
        errdefer gpa.free(source);

        // Module path: `<dep>/<basename without extension>`. The `<dep>/` prefix
        // is how the core resolves `from "<dep>"` generically.
        const stem = stripSourceExt(file);
        const mod_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ dep, stem });
        errdefer gpa.free(mod_path);

        try out.append(gpa, .{ .path = mod_path, .source = source, .declaration = isDeclFile(file) });
    }
}

fn isDeclFile(name: []const u8) bool {
    return std.mem.endsWith(u8, name, ".d.bp");
}

fn stripSourceExt(name: []const u8) []const u8 {
    // Longest match first so `.d.bp` wins over `.bp`.
    const exts = [_][]const u8{ ".d.bp", ".botopink", ".bp" };
    for (exts) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return name[0 .. name.len - ext.len];
    }
    return name;
}

/// Free memory allocated by `loadDependencies`.
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    gpa.free(modules);
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "stripSourceExt strips .d.bp before .bp" {
    try std.testing.expectEqualStrings("rakun", stripSourceExt("rakun.d.bp"));
    try std.testing.expectEqualStrings("http", stripSourceExt("http.bp"));
    try std.testing.expectEqualStrings("page", stripSourceExt("page.botopink"));
    try std.testing.expectEqualStrings("noext", stripSourceExt("noext"));
}

test "isDeclFile recognizes declaration modules" {
    try std.testing.expect(isDeclFile("rakun.d.bp"));
    try std.testing.expect(!isDeclFile("http.bp"));
}

test "loadDependencies with no deps touches no filesystem" {
    const mods = try loadDependencies(std.testing.allocator, std.testing.io, &.{});
    defer freeModules(std.testing.allocator, mods);
    try std.testing.expectEqual(@as(usize, 0), mods.len);
}

test "LibManifest parses src + files, ignores unknown fields" {
    const json =
        \\{ "name": "rakun", "version": "0.0.1", "src": "src/",
        \\  "files": ["http.bp", "rakun.d.bp"] }
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const m = try std.json.parseFromSliceLeaky(LibManifest, arena.allocator(), json, .{
        .ignore_unknown_fields = true,
    });
    try std.testing.expectEqualStrings("src/", m.src);
    try std.testing.expectEqual(@as(usize, 2), m.files.len);
    try std.testing.expectEqualStrings("http.bp", m.files[0]);
}
