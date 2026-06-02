----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn doubled(self: Self) -> i32[] {
        return List.map(self.items) { x ->
            return x * 2;
        };
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, 'Pipeline_doubled', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Pipeline_doubled'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, List}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 4}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    %% unresolved method call: map/2
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
