# onze — a Mockito-style mocking + verification library for tests

**Slug**: onze
**Depends on**: nothing — the annotation-processor mechanism (`@Decl` reflection + `@emit`) and the generic `from "<lib>"` loader are in `feat`; `onze` is a pure `.bp` client
**Files**: `libs/onze/src/*.bp` (ALL behaviour — mock synthesis, stubbing, verification, matchers), `libs/onze/botopink.json`
**Touches docs**: `libs/onze/AGENTS.md`, `libs/onze/docs.md`, `libs/onze/src/AGENTS.md`
**Status**: pending

> Lib-side only — **zero** core code. `onze` is a new ecosystem lib (the test
> double / mocking layer), built entirely on the generic primitives already in
> `feat`: `@Decl` reflection to synthesize a mock from a type, `@emit` for the
> generated impl, and host-bound mutable state for the call recorder. The compiler
> stays unaware of it (memory: [[feedback_no_lib_specific_in_core]],
> [[feedback_compiler_unaware_of_jhonstart]]).

## Intent

`onze` brings Mockito's workflow to botopink unit tests: **create a mock** of a
record/interface, **stub** what its methods return, exercise the code under test,
then **verify** the mock was called as expected. Reached via `from "onze"`,
imported bare (`import {mock, when, verify} from "onze"`).

A mock is **synthesized at compile time** from the target type's `@Decl`: `onze`
reflects the methods (names, params, return types) and `@emit`s an implementation
that, per call, consults a **stub table** (what to return) and appends to a **call
log** (what was invoked, with which args). `when(...)` writes the stub table;
`verify(...)` reads the call log. The stub table + log are runtime state held
behind `#[@external]` host cells (a JS `Map`/array; the equivalent on erlang) —
host-bound is fine for a test lib, the *core* learns nothing.

## Target syntax

```bp
import {mock, when, verify, any, eq, times, never} from "onze";

record UserRepo {
    pub fn find(self: Self, id: i32) -> string { return "?"; }
    pub fn all(self: Self) -> Array<string> { return []; }
}

test "service reads stubbed users and the repo is queried once" {
    val repo = mock(UserRepo);                       // a synthesized stub instance

    when(repo.all()).thenReturn(["ana", "bob"]);     // stub a return
    when(repo.find(eq(7))).thenReturn("ana");        // stub by argument matcher

    val svc = UserService(repo: repo);
    assert svc.list() == ["ana", "bob"];
    assert svc.name(7) == "ana";

    verify(repo).all();                              // was called (≥1)
    verify(repo, times(1)).find(eq(7));              // called exactly once with 7
    verify(repo, never()).find(eq(99));              // never called with 99
}
```

## Examples

### unstubbed methods return a type-default
```bp
val repo = mock(UserRepo);
assert repo.all() == [];        // no stub → default for Array<string>
assert repo.find(1) == "";      // no stub → default for string
```

### `thenReturn` / `thenThrow`
```bp
when(repo.find(any())).thenReturn("x");      // any i32 → "x"
when(repo.find(eq(0))).thenThrow(NotFound);  // a specific arg raises
```

## Steps

### F0 — stand up the lib
- [ ] `libs/onze/botopink.json` + `src/` skeleton; `from "onze"` resolves via the
      generic loader; a trivial `test {}` runs under `botopink test`.

### F1 — mock synthesis from `@Decl`
- [ ] `mock(T)` reflects `T`'s methods via `@Decl` and `@emit`s an implementation
      where each method: records the call (method name + args) into the call log,
      then returns the stub-table entry if one matches, else the **type-default**
      for its return type. Backed by a host-cell registry keyed per mock instance.

### F2 — stubbing (`when … thenReturn / thenThrow`)
- [ ] `when(mock.m(args))` captures the just-recorded call as a stub key; the
      returned builder's `.thenReturn(v)` / `.thenThrow(e)` writes the stub table.
      A later matching call returns `v` (or raises `e`). Last stub wins.

### F3 — verification (`verify`, `times`, `never`)
- [ ] `verify(mock).m(args)` asserts ≥1 matching call; `verify(mock, times(n))`
      asserts exactly `n`; `verify(mock, never())` asserts 0. A failed verification
      raises a clear assertion (expected vs actual count + the recorded calls).

### F4 — argument matchers
- [ ] `any()` / `anyString()` / `eq(v)` match a stubbed-or-verified call's args;
      a literal arg means exact-equality. Matchers compose across params.

### F5 — docs
- [ ] `libs/onze/AGENTS.md`, `src/AGENTS.md`, `docs.md`: the API, the comptime
      synthesis model, the host-cell state, and the `from "onze"` import path — in
      the **same commit** as the code.

## Test scenarios

```
comptime ---- mock(UserRepo) synthesizes an instance implementing every method
run      ---- an unstubbed method returns the type-default ([] / "" / 0)
run      ---- when(m.all()).thenReturn(xs) makes m.all() return xs
run      ---- when(m.find(eq(7))).thenReturn("ana") matches only the 7 call
run      ---- verify(m).all() passes after a call, fails with none
run      ---- verify(m, times(1)).find(eq(7)) checks the exact count
run      ---- verify(m, never()).find(eq(99)) passes when 99 was never used
gate     ---- grep -riE "onze" modules/compiler-core/src returns nothing
```

## Notes

- **Pure `.bp` client, zero core surface.** Mock synthesis is the `@Decl`/`@emit`
  mechanism (the same rakun uses for DI); the stub table + call log are runtime
  state behind `#[@external]` host cells (memory: [[feedback_external_annotation_form]]).
  No compiler change — `onze` is the proof the mechanism handles mocking, not just
  DI/router. Memory: [[feedback_prefer_bp_over_dbp]].
- **v1 scope:** mock records/interfaces (method signatures), stub by return value /
  matcher, verify call count. **Out of scope (recorded):** spies / partial mocks,
  `thenAnswer` callbacks, in-order verification across multiple mocks, capturing
  argument captors — clean follow-ups.
- **Immutable-first tension:** the recorder/stub-table is the one mutable seam;
  keep it isolated behind the host cells so the mocked code stays ordinary
  immutable botopink.
- Tests live in `libs/onze`'s own `.bp` files (`botopink test`), and `onze` itself
  is then usable by other libs' tests. Independent of every other v0.beta.8 spec —
  parallel-safe.
