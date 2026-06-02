----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
fn firstName(p: Person) -> @Option<string> { @todo(); }
fn shout(s: string) -> @Option<string> { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, firstName, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, firstName}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, undef}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, shout, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, shout}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {atom, undef}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, greet, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, greet}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    %% unsupported on BEAM: __bp_option_unwrapOr
    %% unsupported on BEAM: __bp_option_flatMap
    %% unsupported on BEAM: __bp_option_map
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
