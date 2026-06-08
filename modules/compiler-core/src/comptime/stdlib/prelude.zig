/// Compile-time string constants for the stdlib .bp source files.
/// Imported by the botopink core type checker to preload primitive interfaces.
/// The .bp/.d.bp sources stay under libs/std/src/ (which is .bp-only); each
/// file is exposed as an anonymous import in build.zig (std_bp_files) and
/// embedded here by name. One `pub const` per stdlib source.
///
/// `primitives.d.bp` is the controller (numeric tower, Bool, String, Function,
/// Array<T>) and `builtins.bp` holds the builtin model (reflection, io, Result,
/// the lazy Iterator<T>, generators, async, Expr<E>, annotations). Both flatten
/// into the global env. The remaining files are concrete `record`/`enum` modules
/// importable via `import {…} from "std";`.
pub const primitives = @embedFile("primitives.d.bp");
pub const builtins = @embedFile("builtins.bp");

// "std" package impl modules — importable via `import {…} from "std";`.
// These are NOT flattened into the global env (see comptime.zig std_pkg_modules).
// NOTE: `option`/`result` are NOT modules — they are builtin namespaces lowered
// inline by every backend (see comptime/infer.zig `inferBuiltinNamespaceCall`).
pub const pair = @embedFile("pair.bp");
pub const order = @embedFile("order.bp");
pub const dict_mod = @embedFile("dict.bp");
pub const sets_mod = @embedFile("sets.bp");
pub const string_builder_mod = @embedFile("string_builder.bp");
pub const queue_mod = @embedFile("queue.bp");
