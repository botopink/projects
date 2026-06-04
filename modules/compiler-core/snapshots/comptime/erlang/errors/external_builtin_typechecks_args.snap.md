----- SOURCE CODE
@[external(python, "string", "length")]
pub fn str_length(s: string) -> i32

----- ERROR
error: `external` target must be a Target member: node, typescript, erlang, beam or wasm

  hint: Example: @[external(erlang, "string", "length")]
