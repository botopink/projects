# onze — mocking + verification for botopink tests

`onze` is botopink's test-double layer: a Mockito-style API for unit tests. Create
a **mock** of an interface, **stub** what its methods return, run the code under
test, then **verify** the mock was called as you expect. It is a pure `.bp` library
reached via `from "onze"` — the compiler core knows nothing about it.

```bp
import {mock, when, verify, eq, anyInt, times, never, atLeastOnce} from "onze";
```

## The workflow

```bp
#[mock]
interface UserRepo {
    fn find(self: Self, id: i32) -> string
    fn all(self: Self) -> Array<string>
}

fn test_service() {
    val repo = mockUserRepo();                       // synthesized stub instance

    when(repo.all()).thenReturn(["ana", "bob"]);     // stub a return
    when(repo.find(eq(7))).thenReturn("ana");        // stub by argument matcher

    val svc = UserService(repo: repo);
    assert svc.list().join(",") == "ana,bob";
    assert svc.name(7) == "ana";

    verify(repo, atLeastOnce()).all();               // was called (≥1)
    verify(repo, times(1)).find(eq(7));              // exactly once with 7
    verify(repo, never()).find(eq(99));              // never called with 99
}
```

## How a mock behaves

A mock is a record that implements the target interface. Each method records the
call and returns the matching stub value — or, with no matching stub, the
**type-default** for its return type:

```bp
val repo = mockUserRepo();
assert repo.all().join(",") == "";   // no stub → default for Array<string> ([])
assert repo.find(1) == "";           // no stub → default for string ("")
```

| Return type | Default |
|---|---|
| `string` | `""` |
| `bool` | `false` |
| `Array<…>` | `[]` |
| numeric / other | `0` |

## API

### Mocking

| Form | Meaning |
|---|---|
| `#[mock] interface T { … }` | Synthesize `record MockT implement T` + `mockT() -> T`. |
| `mockT()` | A fresh mock instance (unique id; isolated call log). |

### Stubbing — `when(...)`

| Form | Meaning |
|---|---|
| `when(m.method(args)).thenReturn(v)` | A later matching call returns `v`. |
| `when(m.method(args)).thenThrow(msg)` | A later matching call raises `msg`. |

The last stub registered for an overlapping match **wins**.

### Argument matchers

| Matcher | Matches |
|---|---|
| `eq(v)` | exactly `v` (same as a bare literal `v`) |
| `anyInt()` | any `i32` |
| `anyString()` | any `string` |

A literal argument means exact equality. Matchers compose across parameters. Mix
freely — `when(m.f(eq(7), anyString()))`. (More typed `anyXxx()` are easy to add
per type; a single generic `any<T>()` can't produce a per-type dummy value.)

### Verification — `verify(mock, spec)`

| Spec | Asserts |
|---|---|
| `atLeastOnce()` | ≥ 1 matching call |
| `times(n)` | exactly `n` matching calls |
| `never()` | 0 matching calls |

`verify(mock, spec).method(args)` checks the count of prior calls matching `args`.
A failure raises a clear assertion (expected vs. actual count + the recorded calls).
The two-argument form is uniform because botopink has no fn overloading / default
parameters.

## Design notes

- **Comptime synthesis.** `#[mock]` is an annotation processor: it reflects the
  interface's methods via `@Decl` and `@emit`s the mock record + factory. The core
  only provides the protocol (recognise → reflect → run the body); every rule lives
  in `src/onze.bp`.
- **Host-bound state.** The call log, stub table and matcher stack are the one
  mutable seam, isolated in `src/onze.mjs` behind `#[@external(node, …)]`. The mocked
  code stays ordinary immutable botopink.
- **Out of scope (v1):** spies / partial mocks, `thenAnswer` callbacks, in-order
  verification across mocks, and argument captors — clean follow-ups.

## Current limitation

`@emit` contributions splice under `botopink build` but **not** under `botopink test`
yet (a core test-mode gap). Until that lands, write the mock explicitly in the shape
`#[mock]` emits (see `test/onze_test.bp`) when the double must run under `botopink
test`; use `#[mock]` directly under `build` (see `examples/mock_synthesis.bp`). The
runtime — stubbing, matchers, verification — is identical either way. See
[`AGENTS.md`](AGENTS.md) for the full status table.
