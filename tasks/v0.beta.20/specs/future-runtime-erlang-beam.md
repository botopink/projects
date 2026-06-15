# future-runtime-erlang-beam — `#[@future]` spawn-and-await lowering

**Slug**: future-runtime-erlang-beam
**Depends on**: `@Future<T, E>` surface contract, already on
  `origin/feat` (v0.beta.19 frente-b §1F).
**Files**: `modules/compiler-core/src/codegen/{erlang,beam_asm}.zig`
  · runtime `.erl` companion (`Future_*` ops, sibling to other
  runtime modules) · cross-backend snapshots
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md` ·
  `libs/std/AGENTS.md` (Future doc row narrows)
**Status**: pending

## Background

v0.beta.19's frente-a-compiler §D4 deferred per its own "scope to
follow-up if too large" clause. Erlang's `spawn/1` +
`make_ref()`-tagged message passing is the canonical idiom for
single-result futures; this spec ships that on both erlang and
beam, matching the commonJS Promise-shaped surface frente-b §1F
defined.

`@Future<T, E>` per frente-b's §1F:

```bp
pub interface Future<T, E = any> {
    fn await(self: Self) -> Result<T, E>
    fn map<R>(self: Self, transform: fn(value: T) -> R) -> Future<R, E>
    fn flatMap<R>(self: Self, transform: fn(value: T) -> Future<R, E>) -> Future<R, E>
}
```

## Checklist

- [ ] **F1-erlang** — `#[@future] fn body` lowers to:
      ```
      future(Args) ->
          Caller = self(),
          Ref = make_ref(),
          spawn(fun() -> Caller ! {Ref, body(Args)} end),
          {future, Ref}.
      ```
      `await(F)` does a selective receive on the ref:
      `receive {Ref, V} -> {ok, V} after Timeout -> {error, timeout} end`.
- [ ] **F2-beam** — Same shape at register level.
      `spawn/1` is `call_ext` to `erlang:spawn/1` with a closure
      built via `make_fun3`; the await branch is a `loop_rec` +
      `remove_message` + `is_tagged_tuple` sequence.
- [ ] **F3-map/flatMap** — `Future.map<R>(self, transform)` /
      `Future.flatMap<R>(self, transform)` lower as new futures
      chained off the await result. Same dispatch path on both
      backends (the body is pure botopink built atop spawn + await).
- [ ] **F4-snapshot** — A `#[@future] fn double(n: i32) -> i32 {
      return n * 2; }` produces a working future on erlang + beam
      under `erlc +from_asm`; the chained Future.map preserves
      semantics across the await.
- [ ] **F5-docs** — `codegen/AGENTS.md` Remaining-gaps rows drop
      `#[@future]` async/await; `libs/std/AGENTS.md` Future doc row
      gains an "erlang/beam: spawn-and-await; commonJS: Promise"
      sentence.

## Test scenarios

```
F4 ---- a fixture: `#[@future] fn double(n) -> i32 { n * 2 }; val
        r = double(21).await();` returns 21*2=42 via spawn+receive
        on erlang+beam.
F3 ---- `double(21).map({ x -> x + 1 }).await()` returns 43 (the
        map chains a new future).
```

## Notes

- Timeout default lives in a single host helper (`'Future_await'/1`
  with an `infinity` default; `'Future_await'/2` accepts an explicit
  timeout). Override via `await(self, timeout: i32)` overload — out
  of scope here, queued as known gap.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
