/// Runtime execution for generated code.
///
/// Provides functions to execute generated JavaScript (via Node.js) and
/// Erlang code, capturing stdout/stderr for inclusion in snapshots.
const std = @import("std");

/// Execute JavaScript code using Node.js and capture stdout/stderr.
pub fn executeJavaScript(allocator: std.mem.Allocator, js_code: []const u8, io: anytype) ![]u8 {
    // Write code to a temporary file
    const tmp_path = "tmp_run.js";
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp_path, .data = js_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, tmp_path) catch {};

    // Execute with Node.js
    const result = try std.process.run(allocator, io, .{ .argv = &.{ "node", tmp_path } });
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    // Combine stdout and stderr
    var output: std.ArrayListUnmanaged(u8) = .empty;
    try output.appendSlice(allocator, result.stdout);
    if (result.stderr.len > 0) {
        if (output.items.len > 0) try output.append(allocator, '\n');
        try output.appendSlice(allocator, result.stderr);
    }

    return output.toOwnedSlice(allocator);
}

/// Execute Erlang code and capture stdout/stderr.
pub fn executeErlang(allocator: std.mem.Allocator, erl_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    _ = erl_code;
    _ = module_name;
    _ = io;

    // For now, just return empty string for Erlang
    // A full implementation would need to compile and execute Erlang code
    var output: std.ArrayListUnmanaged(u8) = .empty;
    try output.appendSlice(allocator, "// Erlang execution not yet implemented");
    return output.toOwnedSlice(allocator);
}
