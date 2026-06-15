# beam-inline-prim-methods — 6 array/string methods on BEAM ASM

**Slug**: beam-inline-prim-methods
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other
  v0.beta.20 spec.
**Files**: `modules/compiler-core/src/codegen/beam_asm.zig`
  (`emitPrimMethod` array + string arms) · snapshots under
  `modules/compiler-core/snapshots/codegen/beam/beam/`
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`
  `beam_asm.zig` row (the "Remaining gaps" sentence loses 6 methods)
**Status**: pending

## Background

v0.beta.19's frente-a-compiler §D5 deferred per-method because each
one needs register choreography + a `erlc +from_asm` smoke. The
erlang backend already emits these via templates in
`primitives.d.bp`; BEAM needs the equivalent bytecode shape.

The six methods + their target shapes (all already documented in the
erlang templates):

| Method | Erlang template (already in `primitives.d.bp`) | BEAM target |
|---|---|---|
| `xs.join(sep)` | `iolist_to_binary(lists:join($0, lists:map(stringify_fun, $self)))` | inline closure + `lists:map` + `lists:join` + `iolist_to_binary` |
| `xs.indexOf(item)` | recursive `__Find/2` inline fun | inline closure with recursive `call_fun` |
| `xs.at(i)` | bounds-safe `lists:nth(I+1, L)` with `undefined` fallback | `is_lt`/`is_ge` guard + `gc_bif` arithmetic + `lists:nth` |
| `xs.slice(start, end)` (2-arg) | `lists:sublist($self, ($0)+1, (($1)-($0)))` | arity-branched register layout + arithmetic |
| `s.contains(needle)` | `(binary:match($self, $0) =/= nomatch)` | `call_ext binary:match` + `is_eq` test |
| `s.startsWith(prefix)` | `(string:prefix($self, $0) =/= nomatch)` | `call_ext string:prefix` + `is_eq` test |

## Checklist

- [ ] **F1-join** — `xs.join(sep)` on BEAM: build the per-element
      stringify fun via `make_fun3` (`is_binary` / `is_integer` →
      `integer_to_binary` / `io_lib:format`); register layout
      `{x,0} = stringify-fun, {x,1} = list`, then `call_ext
      lists:map/2`, `{x,1} = sep`, `{x,0} = result`, `call_ext
      lists:join/2`, then `call_ext iolist_to_binary/1`. Snapshot
      pinned.
- [ ] **F2-indexOf** — `xs.indexOf(item)`: emit a recursive
      `__Find/2` fun (already documented in the erlang template);
      register layout `{x,0} = Item, {x,1} = List`. The closure
      uses `call_fun` for the self-recursion.
- [ ] **F3-at** — `xs.at(i)` bounds-safe: `is_lt`/`is_ge` against
      `length`, then `lists:nth/2` with `I + 1` (gc_bif on the
      arithmetic). Return `undefined` (the `@Option` absent atom)
      on out-of-range.
- [ ] **F4-slice-2** — 2-arg `xs.slice(start, end)`: extend the
      existing 1-arg `slice` arity branch with a `cc.args.len + cc
      .trailing.len == 2` case that emits `lists:sublist(L, Start+1,
      End-Start)` with the right register choreography.
- [ ] **F5-string-contains** — `s.contains(needle)`: `call_ext
      binary:match/2`, then `is_eq` against `{atom, nomatch}` →
      boolean.
- [ ] **F6-string-startsWith** — `s.startsWith(prefix)`: `call_ext
      string:prefix/2`, then `is_eq` against `{atom, nomatch}`
      negated.
- [ ] **F7-docs** — `codegen/AGENTS.md` `beam_asm.zig` row: drop
      the 6 methods from "Methods needing inline funs / arithmetic
      / structural compares (`join`, `indexOf`, `at`, `isEmpty`,
      2-arg `slice`, … `string contains/startsWith`) are not yet
      lowered on BEAM".

## Test scenarios

Each method gets a snapshot fixture compiled with `botopink build
--target beam`, then assembled with `erlc +from_asm` and run via
`erl`. The expected outputs match the erlang backend's output
byte-identical.

```
F1 ---- `[10,20,30].join(", ")` emits the iolist_to_binary∘lists:join
        shape; assembles + runs to `<<"10, 20, 30">>`.
F2 ---- `[1,2,3,4].indexOf(3)` runs to `2`; `[1,2,3].indexOf(99)`
        runs to `-1`.
F3 ---- `[10,20].at(0)` runs to `10`; `[10].at(5)` runs to
        `undefined`.
F4 ---- `[1,2,3,4,5].slice(1, 4)` runs to `[2,3,4]`.
F5 ---- `<<"hello">>.contains(<<"ell">>)` runs to `true`.
F6 ---- `<<"hello">>.startsWith(<<"he">>)` runs to `true`.
```

## Notes

- Each method ships in its own commit (one snapshot per commit so
  bisection is clean if `erlc +from_asm` regresses).
- **No `--no-verify`**; **SSH for git**; **AGENTS.md in the same
  commit**.
