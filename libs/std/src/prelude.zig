/// Compile-time string constants for the stdlib .bp source files.
/// Imported by the botopink core type checker to preload primitive interfaces.
pub const primitives = @embedFile("primitives.d.bp");
pub const array = @embedFile("array.d.bp");
pub const string = @embedFile("string.d.bp");
