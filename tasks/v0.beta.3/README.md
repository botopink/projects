# v0.beta.3 — spec set

> A batch of independent specs. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Live progress → [`status.md`](status.md)
> (this README carries **no** status column).

## Context — what v0.beta.2 delivered

v0.beta.2 closed the Gleam-style stdlib (all modules `bool` → `queue`), test
declarations (`test { … }` + `assert`), inline tests in non-generic modules, and
the docs/project-structure refactor. One major spec — **expr-templates** — was
designed but never implemented. Several runtime/backend gaps remain open.

## What didn't land in v0.beta.2

| Carry-over | Reason |
|---|---|
| `zig-feature-gaps` | Catalog walk + decisions not finalized |
| WASM test runner | Deferred from `test-blocks` |
| Duplicate-name test warning | Deferred from `test-blocks` |

## Features (v0.beta.3)

| Spec | Slug | Depends on |
|---|---|---|
| [Generic type instantiation](specs/generic-inference.md) | `generic-inference` | nothing |
| [stdlib interface redesign](specs/stdlib-interface.md) | `stdlib-interface` | `generic-inference` |
| [Backend parity + stdlib gaps](specs/backend-parity.md) | `backend-parity` | nothing |
| [Tooling update (LSP + VS Code)](specs/tooling-update.md) | `tooling-update` | `stdlib-interface` (F4 only) |

## Dependency DAG

```text
generic-inference ──► stdlib-interface ──► tooling-update (F4)

backend-parity   (independent)
tooling-update F0–F3, F5   (independent)
```

## v0.beta.2 → v0.beta.3 gap summary

| Spec (v0.beta.2) | Items done | Items NOT done |
|---|---|---|
| `docs-refactor` | F0–F4 all done | — |
| `stdlib-gleam` | F0–F10 all done | F10: bit_array/uri/regexp/dynamic (per demand) |
| `test-blocks` | F0–F4 done | WASM runner; duplicate-name warning |
| `stdlib-tests` | All suites complete (option/result/bool/order/pair/list/dict/set/int/float/string/iterator/function/queue) | — |
| `zig-feature-gaps` | Not started | F0 catalog walk; F1 record non-goals; F2 graduate 🟡 items |
| `expr-templates` | Fully implemented | landed in `task/expr-templates` (c5434bf) |

### Known gaps catalogued in `stdlib-gleam` (drive v0.beta.3 backend-parity spec)

1. snake_case method JS name mapping — `s.to_upper()` verbatim; typed-value dispatch needed
2. Builtin method lowering is commonJS-only — Erlang/BEAM untested
3. Erlang escript can't load `"std"` package modules — multi-file compile pending
4. Literal method receivers don't parse — `"a,b".split(",")` is a parse error
5. Structural `==` on arrays is reference equality in JS — tests use `.join(…)` workaround
6. **Generic fns share type across call sites** — inline tests in generic std modules fail during `registerStdlib` because `.generic` vars are not instantiated per call site → `unify.zig:55` TypeError
7. `?.` codegen on erlang/beam/wasm blocked on record-field-access gap
8. `iterator.fromList` JS codegen broken — `*fn + loop { yield }` emits `.map()` for non-Array iterables
