//! comptime: `from "rakun"` import resolution + `#[decorator]` annotation
//! resolution (rakun framework, spec tasks/v0.beta.5/specs/rakun.md, F2–F3).
//! rakun is an opt-in application lib: its symbols enter a module only via
//! `import {…} from "rakun"`, never auto-loaded.

const std = @import("std");
const h = @import("helpers.zig");

// ── from "rakun" import resolution ────────────────────────────────────────────

test "rakun: import binds decorator symbols" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {service, repository, getMapping} from "rakun";
        \\
        \\fn main() {}
    );
}

test "rakun: import binds Response and resolves its associated fns" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {Response} from "rakun";
        \\
        \\fn make() -> Response {
        \\    return Response.json("hi");
        \\}
    );
}

test "rakun: import binds HttpMethod enum" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {HttpMethod} from "rakun";
        \\
        \\fn main() {}
    );
}

test "rakun: unknown rakun import is a type error" {
    try h.assertInfersErr(std.testing.allocator,
        \\import {bogusDecorator} from "rakun";
        \\
        \\fn main() {}
    );
}
