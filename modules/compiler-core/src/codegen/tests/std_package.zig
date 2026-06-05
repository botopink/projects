//! codegen: `"std"` package qualified calls (F2a, stdlib-gleam) and the
//! builtin `result` namespace.
//! `import {bool} from "std"` pulls the embedded std module into the
//! compilation (own output file); `bool.negate(x)` lowers to a remote call
//! (erlang `bool:negate(...)`) / module-object member call (commonJS).
//! `result.map(r, f)` needs NO import — it is a builtin namespace lowered
//! inline to the same `__bp_result_*` ops the method form uses.

const std = @import("std");
const h = @import("helpers.zig");

test "js: std package ---- bool qualified call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {bool} from "std";
        \\
        \\fn main() {
        \\    val flipped = bool.negate(false);
        \\    @print(bool.exclusive_or(flipped, false));
        \\}
    );
}

test "js: builtin result namespace ---- qualified call lowers inline" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parse(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val r = result.map(parse(21), { x -> x * 2 });
        \\    @print(result.unwrap(r, 0));
        \\}
    );
}
