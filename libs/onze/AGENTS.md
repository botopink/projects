# onze

> Path: `libs/onze/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Spec: [`../../tasks/v0.beta.8/specs/onze.md`](../../tasks/v0.beta.8/specs/onze.md)

A **Mockito-style mocking + verification library** for botopink unit tests:
create a mock of an interface, **stub** what its methods return, exercise the code
under test, then **verify** the mock was called as expected. Pure `.bp` client —
**zero** compiler-core surface. It is the proof that the generic annotation-processor
mechanism (`@Decl` reflection + `@emit`) and host-bound state handle mocking, not
just DI/routing (sibling: `rakun`). Reached via `from "onze"`.

## Tree

```text
onze/
├── AGENTS.md          ← you are here
├── docs.md            ← API reference + the comptime synthesis / host-cell model
├── botopink.json      ← package metadata (files: onze.bp)
├── src/
│   ├── AGENTS.md      ← internals: host cells, the when/verify protocol, #[mock]
│   ├── onze.bp        ← ALL behaviour: externals · matchers · when/verify · #[mock]
│   └── onze.mjs       ← host runtime (the one mutable seam: call log + stub table)
├── test/
│   └── onze_test.bp   ← runtime tests (run by `botopink test` from libs/onze/)
└── examples/
    └── mock_synthesis.bp ← `#[mock]` synthesis, shown under `botopink build`
```

## Design at a glance

- **Mock = a record that implements the interface.** Every method funnels through
  one host call (`onzeInvoke`) that records the invocation and returns the matching
  stub value, or the **type-default** for its return type (`"" / false / 0 / []`).
- **`when(mock.m(args)).thenReturn(v) / .thenThrow(msg)`** writes the stub table;
  **last stub wins**. `verify(mock, spec).m(args)` reads the call log and asserts
  the count (`atLeastOnce()` / `times(n)` / `never()`).
- **Argument matchers** (`eq(v)`, `anyInt()`, `anyString()`) return a dummy value of
  the right type and push a descriptor onto a host matcher stack — Mockito's exact
  trick, the only way to pass matchers through a statically-typed call. A literal
  argument means exact equality.
- **Host-bound mutable state.** The recorder + stub table + matcher stack live in
  `onze.mjs` behind `#[@external(node, …)]` declarations — the one mutable seam, so
  the mocked code stays ordinary immutable botopink and the **core learns nothing**.
- **`#[mock]` synthesis.** A comptime annotation processor reflects an interface's
  methods via `@Decl` and `@emit`s the mock record + a `mockXxx()` factory, so the
  double is generated, never hand-written.

## Status (v1)

| Area | State |
|---|---|
| Runtime: record/stub/verify/matchers/thenThrow | **done** — 7 tests green under `botopink test` |
| `from "onze"` resolution (generic loader) | **done** — bare-imported fns bind |
| `#[mock]` synthesis (`@Decl` → `@emit`) | **done** — reflects the interface, emits `record MockXxx implement Xxx` + `mockXxx()`; `test/onze_test.bp` drives the suite through `#[mock]` under `botopink test` |

This needed two **core** fixes (in this branch — pure-lib onze couldn't do them):
1. **Decorators run before body inference** — `@emit`ed decls are spliced before a
   body that references them (a `test {}` calling `mockXxx()`) is type-checked.
   Previously decorators ran after bodies, so the reference failed as unbound and
   `@emit` was silently dead under `botopink test`.
2. **Interface-level markers run** (`DeclKind.Interface`) — `#[mock]` sits on an
   interface; the old pipeline skipped interface-level decorators entirely.

### Known constraints

- **Host path is project-relative.** `#[@external(node, "../../src/onze.mjs", …)]`
  resolves from `…/.botopinkbuild/test-out/<mod>.js` back to `libs/onze/src/` — correct
  for onze's own tests. A general consumer story (copying/resolving the host file
  from a dependency) is future work.
- **Emitted mock body references host externals.** `@emit`s into the annotated
  module, so `onzeInvoke`/`onzeKey`/`onzeNewMock` must be in scope there — the
  consumer imports them (bare in-project, or via `from "onze"`).
- **No fn overloading / default params**, so `verify` is uniform two-arg:
  `verify(repo, atLeastOnce())` rather than `verify(repo)`.
- **`==` on arrays** lowers to JS reference equality (general codegen trait) — tests
  compare arrays with `.join(",")`.

## Conventions

- **Pure `.bp`, zero core.** `grep -riE "onze" modules/compiler-core/src` must return
  nothing. All behaviour is in `src/onze.bp`; the only host code is `src/onze.mjs`.
- **`.bp` over `.d.bp`.** onze ships real, runnable code, not declaration markers.
- **camelCase** functions (`mockUserRepo`, `anyInt`, `atLeastOnce`).
- **Comptime-body gotchas** (the `#[mock]` body): `if` is an *expression* (needs
  `else`, `;`-terminated branches); a bare `if {…}` statement is legal only as the
  last statement in a block; the body can't call sibling fns (only the decorator fn
  is lowered into the eval script — inline helpers); avoid `//` comments containing
  quotes/backticks inside a closure body. See `src/AGENTS.md`.

## Testing

```bash
cd libs/onze && botopink test          # runs test/onze_test.bp through #[mock] (commonJS/node)
```

`examples/mock_synthesis.bp` is a standalone `from "onze"` usage sample.
