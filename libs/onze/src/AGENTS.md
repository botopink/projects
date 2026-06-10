# onze/src

> Path: `libs/onze/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The whole library: one `.bp` module of behaviour plus one host module for the
mutable state it stands on.

## Files

| File | Role |
|---|---|
| `onze.bp` | Public API + the `#[mock]` synthesizer. Sections: **host cells** (`#[@external]` `declare fn`s → `onze.mjs`), **matchers** (`eq`/`anyInt`/`anyString`), **verify specs** (`atLeastOnce`/`times`/`never`), **stubbing** (`OnzeStub` builder + `when`), **verification** (`verify`), and the **`#[mock]`** decorator. |
| `onze.mjs` | Host runtime — the call log, stub table, matcher stack, and the `when`/`verify` protocol. The single mutable seam; everything else is immutable botopink. |

## How the pieces connect

A mock method (hand-written in `test/`, or `@emit`ed by `#[mock]`) is one call:

```bp
fn find(self: Self, id: i32) -> string {
    return onzeInvoke(self.__id, "find", [onzeKey(id)], "");
}
```

- `onzeKey(v)` → a canonical, comparable string key for any value (`JSON.stringify`).
- `onzeInvoke(id, method, keys, def)` → the heart. It pulls the matcher stack for
  this call (or treats every key as exact-equality), then:
  - in **verify mode** (set by `verify`): counts matching prior calls and asserts
    against the spec (`-1` = ≥1, `n` = exactly n), throwing a clear message on
    mismatch (returns `def`, ignored);
  - otherwise: appends to the call log, finds the **last** matching stub and returns
    its value (or host-throws for `thenThrow`), else returns `def` — the per-return-type
    default the caller supplied.
- `def` is type-directed: `onzeInvoke<T>` is generic, so the return type flows from
  the method's declared return type into `T` and the `def` literal (`"" / false / 0 / []`).

### `when(...).thenReturn / thenThrow`

`when(mock.m(args))` evaluates the argument first — that records the call (with its
matchers) — then `onzeWhen()` pops it back off the log and parks it as the pending
stub target. `thenReturn(v)` / `thenThrow(msg)` write the stub table. `value` passed
to `when` is ignored; the host holds the captured call.

### matchers

`eq(v)` returns `v` and pushes `{eq, key(v)}`; `anyInt()`/`anyString()` return a dummy
of the type and push `{any}`. The mock method consumes the stack: one matcher per
argument → use them; otherwise every argument is exact-equality on its key. So
`when(m.find(eq(7)))` then a real `m.find(7)` match because `7`'s key equals the
recorded `eq` key.

## `#[mock]` synthesis (the comptime body)

`mock(comptime decl: @Decl)` runs over the annotated **interface** (interface-level
markers reflect with `DeclKind.Interface`), reflects `decl.methods` (each `Method{
name, params: [{name, typeName}], returnType }`) and `@emit`s two declarations into
the module:

```
record MockXxx implement Xxx { __id: string, <one method per signature> }
pub fn mockXxx() -> Xxx { return MockXxx(__id: onzeNewMock()); }
```

Each method body is the single `onzeInvoke(...)` call above; the return-type default
is computed inline (`string→"" `, `bool→false`, `Array…→[]`, else `0`).

### Comptime-body gotchas (learned the hard way)

The decorator body is lowered to JS by the same emitter as normal code and run in the
node eval runtime, but the **parser** is stricter here and the eval script contains
**only this fn**:

- `if` is an **expression** — needs `else`, branch bodies end in `;`
  (`val x = if (c) { "a"; } else { "b"; };`); `else if` chains are fine.
- A bare `if {…}` **statement** parses only as the *last* statement in a block. Build
  lists with `push` + `join` instead of an `if`-guarded accumulator.
- The body **cannot call sibling fns** (only the decorator fn is emitted into the eval
  script) — inline any helper.
- Avoid `//` comments containing quotes/backticks **inside a closure body** — the
  lexer mishandles them there.
- See [`tasks/v0.beta.8/specs/onze.md`](../../../tasks/v0.beta.8/specs/onze.md) and the
  decorator infra in `modules/compiler-core/src/comptime/decorator_eval.zig`.

## Host file path

`#[@external(node, "../../src/onze.mjs", …)]` is relative to the generated JS at
`…/.botopinkbuild/test-out/<module>.js`, so `../../src/` reaches the lib source when
onze is the project under test. Keep all `.bp` in `src/` so the depth stays constant.
