/// Lib discovery — enumerate `libs/*/` projects and decide which have tests.
///
/// A "lib" is any immediate subdirectory of the libs root that holds a
/// `botopink.json`. "Has tests" means either a `test/` directory with at least
/// one `.bp` suite, or a `src/**/*.bp` file containing a `test` block. A lib with
/// no tests is reported (`has_tests = false`) and rendered as a green skip — it is
/// never a failure, matching `botopink test`'s own "no test blocks found" → exit 0.
const std = @import("std");

// ── Types ───────────────────────────────────────────────────────────────────────

pub const Lib = struct {
    /// Directory name under the libs root. Owned by the caller-supplied `gpa`.
    name: []const u8,
    has_tests: bool,
};

pub const Error = error{
    LibsRootNotFound,
} || std.mem.Allocator.Error;

// ── Discovery ───────────────────────────────────────────────────────────────────

/// Discover every lib under `libs_root` (relative to cwd) that carries a
/// `botopink.json`. If `only` is set, restrict to that one lib. Results are sorted
/// by name; each `name` is heap-allocated with `gpa` — call `free` when done.
pub fn discover(
    gpa: std.mem.Allocator,
    io: std.Io,
    libs_root: []const u8,
    only: ?[]const u8,
) Error![]Lib {
    var root = std.Io.Dir.cwd().openDir(io, libs_root, .{ .iterate = true }) catch {
        return error.LibsRootNotFound;
    };
    defer root.close(io);

    var libs: std.ArrayListUnmanaged(Lib) = .empty;
    errdefer free(gpa, libs.items);
    errdefer libs.deinit(gpa);

    var it = root.iterate();
    while (it.next(io) catch return error.LibsRootNotFound) |entry| {
        if (entry.kind != .directory) continue;
        if (only) |want| {
            if (!std.mem.eql(u8, entry.name, want)) continue;
        }

        var lib_dir = root.openDir(io, entry.name, .{}) catch continue;
        defer lib_dir.close(io);

        // A project is a lib iff it has a manifest.
        lib_dir.access(io, "botopink.json", .{}) catch continue;

        // `entry.name` is backed by the iterator's scratch buffer — dupe before
        // any further `it.next()` invalidates it.
        const name = try gpa.dupe(u8, entry.name);
        errdefer gpa.free(name);

        try libs.append(gpa, .{ .name = name, .has_tests = libHasTests(gpa, io, lib_dir) });
    }

    const items = libs.items;
    std.mem.sort(Lib, items, {}, struct {
        fn lt(_: void, a: Lib, b: Lib) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.lt);

    return libs.toOwnedSlice(gpa);
}

pub fn free(gpa: std.mem.Allocator, libs: []Lib) void {
    for (libs) |l| gpa.free(l.name);
    gpa.free(libs);
}

// ── "Has tests" detection ───────────────────────────────────────────────────────

/// True when `lib_dir` has a `test/` suite (`*.bp`) or a `src/**/*.bp` with a
/// `test` block. Any IO error is treated as "no tests" (conservative — a lib that
/// cannot be scanned is skipped, never falsely failed).
fn libHasTests(gpa: std.mem.Allocator, io: std.Io, lib_dir: std.Io.Dir) bool {
    if (dirHasBpSuite(io, lib_dir)) return true;
    return srcHasTestBlock(gpa, io, lib_dir);
}

/// Any `.bp` (non-`.d.bp`) file directly inside `test/`.
fn dirHasBpSuite(io: std.Io, lib_dir: std.Io.Dir) bool {
    var test_dir = lib_dir.openDir(io, "test", .{ .iterate = true }) catch return false;
    defer test_dir.close(io);

    var it = test_dir.iterate();
    while (it.next(io) catch return false) |entry| {
        if (entry.kind != .file) continue;
        if (isBpSource(entry.name)) return true;
    }
    return false;
}

/// Any `src/**/*.bp` (non-`.d.bp`) file containing a `test` block.
fn srcHasTestBlock(gpa: std.mem.Allocator, io: std.Io, lib_dir: std.Io.Dir) bool {
    var src_dir = lib_dir.openDir(io, "src", .{ .iterate = true }) catch return false;
    defer src_dir.close(io);

    var walker = src_dir.walk(gpa) catch return false;
    defer walker.deinit();

    while (walker.next(io) catch return false) |entry| {
        if (entry.kind != .file) continue;
        if (!isBpSource(entry.basename)) continue;

        const source = entry.dir.readFileAlloc(io, entry.basename, gpa, .limited(8 * 1024 * 1024)) catch continue;
        defer gpa.free(source);

        if (containsTestBlock(source)) return true;
    }
    return false;
}

// ── Pure helpers ────────────────────────────────────────────────────────────────

/// A runnable `.bp` source file — excludes declaration files (`*.d.bp`), which
/// carry type surface only and have no executable `test` blocks.
pub fn isBpSource(name: []const u8) bool {
    if (std.mem.endsWith(u8, name, ".d.bp")) return false;
    return std.mem.endsWith(u8, name, ".bp") or std.mem.endsWith(u8, name, ".botopink");
}

/// True when `source` contains a `test` block: the `test` keyword at a word
/// boundary, followed by whitespace and then a name string (`"`) or a body (`{`).
/// This matches `test "…" {}` (named) and `test {}` (anonymous) without tripping
/// on identifiers like `latest` or `tests`.
pub fn containsTestBlock(source: []const u8) bool {
    const kw = "test";
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, source, i, kw)) |pos| {
        i = pos + kw.len;

        // Left boundary: preceding byte must not be an identifier character.
        if (pos > 0 and isIdentByte(source[pos - 1])) continue;

        // Skip whitespace after the keyword; there must be at least one byte left.
        var j = i;
        while (j < source.len and isSpace(source[j])) j += 1;
        if (j == i) continue; // keyword must be followed by whitespace
        if (j >= source.len) continue;

        if (source[j] == '"' or source[j] == '{') return true;
    }
    return false;
}

fn isIdentByte(c: u8) bool {
    return c == '_' or std.ascii.isAlphanumeric(c);
}

fn isSpace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\r' or c == '\n';
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "isBpSource accepts .bp, rejects .d.bp" {
    try testing.expect(isBpSource("erika.bp"));
    try testing.expect(isBpSource("main.botopink"));
    try testing.expect(!isBpSource("primitives.d.bp"));
    try testing.expect(!isBpSource("README.md"));
}

test "containsTestBlock detects named test" {
    try testing.expect(containsTestBlock("test \"adds two numbers\" {\n  ok\n}"));
}

test "containsTestBlock detects anonymous test" {
    try testing.expect(containsTestBlock("fn x() {}\ntest {\n  ok\n}"));
}

test "containsTestBlock detects indented test" {
    try testing.expect(containsTestBlock("module m\n    test \"x\" {}"));
}

test "containsTestBlock ignores 'latest' and 'tests' identifiers" {
    try testing.expect(!containsTestBlock("let latest = 1\nlet tests = 2\nfn testHelper() {}"));
}

test "containsTestBlock ignores the word test without a block" {
    try testing.expect(!containsTestBlock("// run the test suite\nlet x = test"));
}

test "containsTestBlock requires whitespace after keyword" {
    try testing.expect(!containsTestBlock("test{}")); // no space → treated as identifier-ish use
}
