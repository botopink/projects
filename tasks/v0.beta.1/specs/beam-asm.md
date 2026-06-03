# BEAM ASM — remaining phases

**Branch**: `feat/beam-asm`
**Depends on**: nothing (independent)
**Status**: pending (Phases 1–2 done)
**File**: `beam_asm.zig`

## Steps

- **Phase 3**: strings/binaries — `{put_string, …}`, binary syntax, `@print` via `io:format`
- **Phase 4**: records/structs — map creation `{put_map_assoc, …}`, field access
- **Phase 5**: enums — tagged tuple `{tag, Fields...}`, case dispatch on tag
- **Phase 6**: closures/lambdas — `{make_fun3, …}`, higher-order calls
- **Phase 7**: ranges — `lists:seq/2` or loop counter lowering
- **Phase 8**: try/catch — `{try, …}` / `{try_end, …}` / `{try_case, …}` (align with `feat/trycatch-lowering`)
- **Phase 9**: polish — register allocation, tail-call optimization, dead code elimination

## Examples

### Phase 3 — string + `@print`
```bp
fn greeting() -> string {
    val msg = "hi";
    @print(msg);
    return msg;
}
```
```erlang
%% expected (BEAM asm)
{put_string, {string, "hi"}, {x,0}}.
{call_ext, 2, {extfunc, io, format, 2}}.
```

### Phase 5 — enum tagged tuple + case dispatch
```bp
val Shape = enum { Circle(r: f64), Square(s: f64) };
fn area(sh: Self) -> f64 {
    return case sh {
        Circle(r) -> r * r * 3.14;
        Square(s) -> s * s;
    };
}
```
```erlang
%% {circle, R} / {square, S} — dispatch via is_tagged_tuple
```

## Test scenarios

```
beam ---- string literal via put_string + io:format (Phase 3)
beam ---- binary concat of two strings (Phase 3)
beam ---- record with 2 fields → put_map_assoc + field access (Phase 4)
beam ---- enum unit variant → atom; payload variant → tagged tuple (Phase 5)
beam ---- case dispatch on tag via is_tagged_tuple (Phase 5)
beam ---- lambda capturing a var → make_fun3 + apply (Phase 6)
beam ---- range 0..10 → lists:seq/2 (Phase 7)
beam ---- try/catch → try/try_end/try_case (Phase 8)
beam ---- tail call in recursive fn → call_only (Phase 9)
beam ---- dead code after return eliminated (Phase 9)
```