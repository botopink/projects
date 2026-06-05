//! codegen: `@[external(…)]` FFI declarations (F1, stdlib-gleam).
//! Erlang lowers calls to the remote `module:symbol(…)`; CommonJS imports the
//! host symbol under the fn name via `require`.

const std = @import("std");
const h = @import("helpers.zig");

test "js: external ---- call emits module symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\@[external(erlang, "string", "length"),
        \\  external(node, "./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    @print(str_length("hello"));
        \\}
    );
}

test "js: external ---- import binds symbol" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\@[external(erlang, "erlang", "abs"),
        \\  external(node, "./stdlib.mjs", "abs")]
        \\pub declare fn abs(n: i32) -> i32;
        \\
        \\fn main() {
        \\    @print(abs(-5));
        \\}
    );
}
