//! comptime: jhonstart framework `check` scenarios.
//!
//! jhonstart is a React/Next-style framework written in botopink on the
//! language's own primitives — `@Context<Element, _>` hooks (context-inference)
//! and the `html` authoring DSL (expr-templates building an Element tree). The
//! package is not embedded (reached via `from "jhonstart"`), so each scenario
//! inlines the minimal declarations it needs — mirroring effects.zig/templates.zig.
//!
//! The four language gaps the framework once surfaced are now closed by the
//! `jhonstart-language-gaps` spec, and their Test scenarios open this file:
//!   G1. records carry function-typed fields (`set: fn(next: T)`) — and `get`/
//!       `set` are soft keywords, valid as the hook shape's field names;
//!   G2. anonymous record TYPE syntax (`-> { value: T, set: fn(T) }`);
//!   G3. a function type returns an array (`fn() -> T[]`, `?T[]`, `T[][]`);
//!   G4. `Element[]` (and a single `Element`, or a `string`) coerces into a
//!       `Children`-typed parameter — the builder children model `div([a, b])`.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

/// Compile `src` through the full node pipeline and require a `.ok` outcome.
/// (Snapshot-only assertions accept error outcomes as a SOURCE-only snapshot,
/// which would silently hide a template-evaluation failure.)
fn assertCompilesOk(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        .node,
        build_root,
    );
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    switch (outcome) {
        .ok => {},
        .typeError => |te| {
            const desc = try h.renderTypeError(std.testing.allocator, src, te);
            defer std.testing.allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        },
        .validationError => |ve| {
            const desc = try ve.renderAlloc(std.testing.allocator, src);
            defer std.testing.allocator.free(desc);
            std.debug.print("\nunexpected validation error:\n{s}\n", .{desc});
        },
        .parseError => std.debug.print("\nunexpected parse error\n", .{}),
    }
    try std.testing.expect(outcome == .ok);
}

// ── check ---- record/array ergonomics (jhonstart-language-gaps) ───────────────
//
// The four language gaps the framework surfaced (spec: jhonstart-language-gaps).
// Each is now expressible; these are the spec's Test scenarios.

// G1 ---- a record can carry a function-typed field (`set: fn(next: T)`). `set`
// is a soft keyword, valid as a field name (the hook shape `{value, set}`).
test "jhonstart gap ---- G1 record with a fn-typed field parses" {
    try h.assertInfersOk(std.testing.allocator,
        \\record State<T> { value: T, set: fn(next: T) }
    );
}

// G3 ---- a function type returns an array (`fn() -> T[]`), incl. nested forms.
test "jhonstart gap ---- G3 fn() -> T[] parses" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn rows() -> i32[] { rows(); }
        \\fn grid() -> i32[][] { grid(); }
        \\fn maybe() -> ?i32[] { maybe(); }
        \\record Builder { make: fn() -> i32[] }
    );
}

// G1 ---- the `{value, set}` hook shape type-checks: a hook returns a record
// carrying a fn-typed `set`, and a component uses it (`s.set(s.value)`).
test "jhonstart gap ---- G1 {value, set} hook shape type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\record State<T> { value: T, set: fn(next: T) }
        \\fn state<T>(initial: T) -> @Context<Element, State<T>> {
        \\    State(value: initial, set: { n -> });
        \\}
        \\fn Counter() -> Element {
        \\    val s = use state(0);
        \\    s.set(s.value);
        \\    Element();
        \\}
    );
}

// G2 ---- an anonymous record TYPE is accepted as a return annotation, and a
// `record { … }` literal unifies with it field-by-field.
test "jhonstart gap ---- G2 anonymous record type as return annotation" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn mk() -> { value: i32, set: fn(next: i32) } {
        \\    record { value: 0, set: { n -> } };
        \\}
    );
}

// G4 ---- `Element[]` coerces into a `Children`-typed parameter (the builder
// children model `div([a, b])`); a single `Element` and a `string` coerce too.
test "jhonstart gap ---- G4 Element[] coerces into Children" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn div(children: Children) -> Element { Element(); }
        \\fn a() -> Element { Element(); }
        \\val list = div([a(), a()]);
        \\val one = div(a());
        \\val text = div("hello");
    );
}

// ── check ---- hook surface (@Context<Element, _>) ────────────────────────────
//
// The `use` prefix is legal only on a value implementing @Context, and only
// inside a component (a fn returning the same ContextBase). Hook returns use
// simple/named-record shapes (gap #1 blocks the `{value, set}` callback shape).

test "jhonstart check ---- counter_typechecks (use state/effect inside a component)" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> { initial; }
        \\fn effect(run: fn()) -> @Context<Element, i32> { 0; }
        \\fn Counter() -> Element {
        \\    val value = use state(0);
        \\    use effect({ -> });
        \\    Element();
        \\}
    );
}

test "jhonstart check ---- use_outside_element_rejected (use in a fn returning string)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> { initial; }
        \\fn bad() -> string {
        \\    val value = use state(0);
        \\    "nope";
        \\}
    );
}

test "jhonstart check ---- hook_compose_transitive (custom hook propagates @Context<Element,_>)" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\val Toggle = struct implement @Context<Element, Toggle> { on: bool }
        \\fn state(initial: bool) -> @Context<Element, bool> { initial; }
        \\fn useToggle(initial: bool) -> Toggle {
        \\    val value = use state(initial);
        \\    Toggle(on: value);
        \\}
        \\fn Switch() -> Element {
        \\    val {on} = use useToggle(false);
        \\    Element();
        \\}
    );
}

test "jhonstart check ---- contextbase_mismatch (use Http hook in an Element component)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> { initial; }
        \\fn request() -> @Context<Http, i32> { 0; }
        \\fn bad() -> @Context<Element, i32> {
        \\    val r = use request();
        \\    state(0);
        \\}
    );
}

// ── check ---- the `html` authoring DSL builds an Element tree ─────────────────
//
// The DSL captures markup unevaluated (`@Expr<string>`), expands it at compile
// time, and yields a plain `Element` — verified to compile end-to-end through
// the node pipeline. Children are assembled with `fragment(Element[])`.

test "jhonstart check ---- html_component_tags (<Component/> resolves to a call)" {
    try assertCompilesOk(@src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn fragment(items: Element[]) -> Element { Element(); }
        \\fn Page1() -> Element { Element(); }
        \\fn Page2() -> Element { Element(); }
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<Element> {
        \\    return q.build("fragment([Page1(), Page2()])");
        \\}
        \\val page = html """<Page1/><Page2/>""";
    );
}

test "jhonstart check ---- html_interp_hole (${expr} splices as a text child)" {
    try assertCompilesOk(@src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn fragment(items: Element[]) -> Element { Element(); }
        \\fn text(value: string) -> Element { Element(); }
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<Element> {
        \\    var acc = "fragment([";
        \\    loop (q.parts()) { p ->
        \\        if (p.kind == "Interp") {
        \\            acc = acc + "text(" + p.code + "),";
        \\        };
        \\    };
        \\    return q.build(acc + "])");
        \\}
        \\val name = "world";
        \\val page = html """<p>${name}</p>""";
    );
}
