# Erlang codegen — gaps

**Branch**: `feat/erlang-gaps`
**Depends on**: nothing (independent)
**Status**: pending
**File**: `erlang.zig`

## Steps

- [ ] List patterns in case arms (currently a placeholder)
- [ ] Constructor patterns in case arms (currently a placeholder)
- [ ] Correct arity tracking for qualified function calls

## Examples

### List patterns in case (currently placeholder)
```bp
fn describe(items: i32[]) -> string {
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```
```erlang
%% expected
case Items of
    []              -> <<"empty">>;
    [X]             -> <<"one">>;
    [First | Rest]  -> <<"many">>
end.
```

### Constructor patterns in case (currently placeholder)
```bp
fn check(m: Maybe) -> string {
    return case m {
        Nothing -> "nothing";
        Just(v) -> "just";
    };
}
```
```erlang
case M of
    nothing  -> <<"nothing">>;
    {just, V} -> <<"just">>
end.
```

### Arity in a qualified call
```bp
import { std.List* };
val n = List.map(xs, f);   %% must resolve to list:map/2, not map/1
```

## Test scenarios

```
erlang ---- case with [] / [x] / [first, ..rest] → list clauses
erlang ---- case with unit variant → atom; payload variant → tagged tuple
erlang ---- case mixing literal + constructor patterns
erlang ---- qualified call List.map → list:map/2 (correct arity)
erlang ---- qualified call with variable arity resolves by arg count
```