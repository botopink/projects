/// Workspace build — coordinates compiler-core, compiler-cli and language-server.
///
///   zig build          → builds botopink + botopink-lsp
///   zig build test     → runs every compiler-core test
///   zig build run      → builds and runs the botopink CLI
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── std prelude ───────────────────────────────────────────────────────────

    const std_prelude = b.addModule("std_prelude", .{
        .root_source_file = b.path("modules/compiler-core/src/comptime/stdlib/prelude.zig"),
        .target = target,
    });

    // The stdlib .bp/.d.bp sources live under libs/std/src/ (outside the
    // std_prelude module root), so each file is exposed as an anonymous
    // import that prelude.zig embeds by name. One entry per stdlib module.
    const std_bp_files = [_][]const u8{
        "primitives.d.bp",
        "builtins.d.bp",
        "order.bp",
        "dict.bp",
        "sets.bp",
        "string_builder.bp",
        "queue.bp",
    };
    for (std_bp_files) |f| {
        std_prelude.addAnonymousImport(f, .{
            .root_source_file = b.path(b.fmt("libs/std/src/{s}", .{f})),
        });
    }

    // ── compiler-core (library) ───────────────────────────────────────────────

    const core_mod = b.addModule("botopink", .{
        .root_source_file = b.path("modules/compiler-core/src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "std_prelude", .module = std_prelude },
        },
    });

    // ── compiler-core tests ───────────────────────────────────────────────────

    const core_test_mod = b.addModule("botopink_tests", .{
        .root_source_file = b.path("modules/compiler-core/src/test_root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "std_prelude", .module = std_prelude },
        },
    });

    const core_tests = b.addTest(.{
        .root_module = core_test_mod,
    });

    const run_core_tests = b.addRunArtifact(core_tests);
    // Ensure snapshots are written inside modules/compiler-core/,
    // not at the workspace root.
    run_core_tests.setCwd(b.path("modules/compiler-core"));

    const test_step = b.step("test", "Run every test (compiler-core + language-server)");
    test_step.dependOn(&run_core_tests.step);

    // ── language-server tests ─────────────────────────────────────────────────

    const lsp_test_mod = b.createModule(.{
        .root_source_file = b.path("modules/language-server/src/test_root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "botopink", .module = core_mod },
        },
    });

    const lsp_tests = b.addTest(.{ .root_module = lsp_test_mod });
    const run_lsp_tests = b.addRunArtifact(lsp_tests);
    run_lsp_tests.setCwd(b.path("modules/language-server"));

    test_step.dependOn(&run_lsp_tests.step);

    // ── compiler-cli (botopink executable) ────────────────────────────────────

    const cli_exe = b.addExecutable(.{
        .name = "botopink",
        .root_module = b.createModule(.{
            .root_source_file = b.path("modules/compiler-cli/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "botopink", .module = core_mod },
            },
        }),
    });

    b.installArtifact(cli_exe);

    // ── language-server (botopink-lsp executable) ─────────────────────────────

    const lsp_exe = b.addExecutable(.{
        .name = "botopink-lsp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("modules/language-server/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "botopink", .module = core_mod },
            },
        }),
    });

    b.installArtifact(lsp_exe);

    // ── Run step ──────────────────────────────────────────────────────────────

    const run_cmd = b.addRunArtifact(cli_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Build and run the botopink CLI");
    run_step.dependOn(&run_cmd.step);
}
