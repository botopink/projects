/// Compile-time string constants for the stdlib .bp source files.
/// Imported by the botopink core type checker to preload primitive interfaces.
/// The .bp/.d.bp sources stay under libs/std/src/ (which is .bp-only); each
/// file is exposed as an anonymous import in build.zig (std_bp_files) and
/// embedded here by name. One `pub const` per stdlib module.
pub const primitives = @embedFile("primitives.d.bp");
pub const array = @embedFile("array.d.bp");
pub const string = @embedFile("string.d.bp");
pub const syntax = @embedFile("syntax.bp");
