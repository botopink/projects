/// Compile-time string constants for the stdlib .bp source files.
/// Imported by the botopink core type checker to preload primitive interfaces.
/// The .bp/.d.bp sources stay under libs/std/src/ (which is .bp-only); each
/// file is exposed as an anonymous import in build.zig (std_bp_files) and
/// embedded here by name. One `pub const` per stdlib module.
pub const primitives = @embedFile("primitives.d.bp");
pub const array = @embedFile("array.d.bp");
pub const string = @embedFile("string.d.bp");
pub const syntax = @embedFile("syntax.bp");

// "std" package impl modules — importable via `import {…} from "std";`.
// These are NOT flattened into the global env (see comptime.zig std_pkg_modules).
// NOTE: `option`/`result` are NOT modules — they are builtin namespaces lowered
// inline by every backend (see comptime/infer.zig `inferBuiltinNamespaceCall`).
pub const bool_mod = @embedFile("bool.bp");
pub const pair = @embedFile("pair.bp");
pub const order = @embedFile("order.bp");
pub const list = @embedFile("list.bp");
pub const int_mod = @embedFile("int.bp");
pub const float_mod = @embedFile("float.bp");
pub const string_mod = @embedFile("string.bp");
