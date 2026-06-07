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
        \\    @print(bool.exclusiveOr(flipped, false));
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

test "js: std package ---- order enum module with type export" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {order} from "std";
        \\
        \\fn describe(o: Order) -> string {
        \\    val s = case o {
        \\        Lt -> "less";
        \\        Gt -> "greater";
        \\        _ -> "equal";
        \\    };
        \\    return s;
        \\}
        \\
        \\fn main() {
        \\    @print(order.toInt(order.lt()));
        \\    @print(describe(order.reverse(order.lt())));
        \\}
    );
}

test "js: std package ---- list module map filter fold" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {list} from "std";
        \\
        \\fn main() {
        \\    val xs = [1, 2, 3, 4];
        \\    val doubled = list.map(xs, { x -> x * 2 });
        \\    @print(list.fold(doubled, 0, { acc, x -> acc + x }));
        \\    @print(list.length(list.filter(xs, { x -> x > 2 })));
        \\    @print(list.contains(xs, 3));
        \\    @print(list.take(xs, 2).join(","));
        \\}
    );
}

test "js: std package ---- list module v2 range append flatten" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {list} from "std";
        \\
        \\fn main() {
        \\    @print(list.range(1, 5).join(","));
        \\    @print(list.append([1, 2], [3, 4]).join(","));
        \\    @print(list.prepend([2, 3], 1).join(","));
        \\    @print(list.flatten([[1, 2], [3]]).join(","));
        \\    @print(list.count(list.range(0, 10), { x -> x > 6 }));
        \\}
    );
}

test "js: std package ---- array method dispatch xs.isEmpty() sugar" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs: Array<i32> = [];
        \\    @print(xs.isEmpty());
        \\    val ys = [1, 2, 3];
        \\    @print(ys.isEmpty());
        \\    @print(ys.length());
        \\    @print(ys.contains(2));
        \\}
    );
}

test "js: std package ---- array method dispatch no explicit import needed" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn checkAll(xs: Array<i32>) -> bool {
        \\    return xs.isEmpty();
        \\}
        \\
        \\fn main() {
        \\    @print(checkAll([]));
        \\    @print(checkAll([1]));
        \\}
    );
}

test "js: std package ---- pair record module qualified calls" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {pair} from "std";
        \\
        \\fn main() {
        \\    val p = pair.of(1, "one");
        \\    val q = pair.swap(p);
        \\    @print(pair.first(q));
        \\    @print(pair.second(q));
        \\}
    );
}
