# Erlang codegen — gaps

**Branch**: `task/erlang-gaps`
**Depends on**: nothing (independent)
**Status**: done
**File**: `erlang.zig`

## Steps

- [x] List patterns in case arms — `emitPattern` already lowers `[]`, `[X]`,
      `[First | Rest]` (the remaining placeholders are in let-binding
      destructure, not case arms). Covered by
      `case_list_patterns_empty_single_spread`.
- [x] Constructor patterns in case arms — unit variants → atoms, payload
      variants → `{tag, Name, ...}` tuples. Covered by
      `enum_mixed_unit_and_payload_with_method_using_mixed_case`.
- [x] Correct arity tracking for qualified function calls — a module-qualified
      call `List.map(xs, f)` now emits the remote call `list:map(Xs, F)`
      (PascalCase receiver lowercased to a valid module atom; arity = arg count,
      including trailing lambdas). Helpers `isModuleRef` / `erlangModule` in
      `erlang.zig`. Covered by `call_qualified_module_call_resolves_arity` and
      `call_qualified_module_call_with_trailing_lambda_arity`.

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