----- SOURCE CODE
@[external(erlang, "string")]
pub declare fn str_length(s: string) -> i32;

----- ERROR
error: `external` expects exactly 3 arguments: external(target: Target, module: string, symbol: string)

  hint: Example: @[external(erlang, "string", "length")]
