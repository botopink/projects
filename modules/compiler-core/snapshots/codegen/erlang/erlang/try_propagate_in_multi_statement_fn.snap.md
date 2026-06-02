----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result<i32, IoError> {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result<i32, IoError> {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(IoError, {path}).

step1() ->
    erlang:throw(IoError(<<"/data">>)).

step2(X) ->
    erlang:throw(IoError(<<"/out">>)).

pipeline() ->
    case step1() of
        {ok, A} ->
            case step2(A) of
                {ok, B} ->
                    B;
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.
```

----- RUN LOG -----
```logs
```
