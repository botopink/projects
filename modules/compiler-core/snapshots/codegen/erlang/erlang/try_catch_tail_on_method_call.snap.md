----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(ParseError, {msg}).

-record(Parser, {}).

parse() ->
    erlang:throw(ParseError(<<"bad input">>)).

run(P) ->
    Result = try
        p:parse()
catch
        _Err ->
            0(_Err)
end,
    Result.
```

----- RUN LOG -----
```logs
```
