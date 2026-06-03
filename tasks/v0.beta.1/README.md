# v0.beta.1 — spec set

> One spec per feature (branch, dependencies, steps, test scenarios) under
> [`specs/`](specs/). **Live state is not here** — the real, current status of every
> task lives in [`status.md`](status.md) (single source of truth). The tables below
> are structure only (no status column).

## Dependency DAG

```
import-rework ─────────┐
                       ├─► extension-dispatch ─► context-inference ─► hook-codegen
implement-extend-decls ┘                              ▲
use-await-prefix ─────────────────────────────────────┘

async-generators · beam-asm · wat-features · erlang-gaps · typeparam ·
throw-check · trycatch-lowering · stdlib-result · interface-coverage · tooling
   └── parallel, no merge with the chain above

ast-simplification — isolated in time (alone, before or after everything)
```

## New-model features (`import` / `use` / `extend`)

| Spec | Branch | Phase | Depends on |
|---|---|---|---|
| [import-rework](specs/import-rework.md) | `feat/import-rework` | F0–F2 | — |
| [use-await-prefix](specs/use-await-prefix.md) | `feat/use-await-prefix` | F3 | — |
| [implement-extend-decls](specs/implement-extend-decls.md) | `feat/implement-extend-decls` | F4–F5 | — |
| [extension-dispatch](specs/extension-dispatch.md) | `feat/extension-dispatch` | F6 | import-rework + implement-extend-decls |
| [context-inference](specs/context-inference.md) | `feat/context-inference` | F7 | use-await-prefix + extension-dispatch |
| [hook-codegen](specs/hook-codegen.md) | `feat/hook-codegen` | F8 | context-inference |

## Parallel backlog (independent)

| Spec | Branch | Notes |
|---|---|---|
| [async-generators](specs/async-generators.md) | `feat/async-generators` | `await` prefix comes from use-await-prefix |
| [beam-asm](specs/beam-asm.md) | `feat/beam-asm` | — |
| [wat-features](specs/wat-features.md) | `feat/wat-features` | — |
| [erlang-gaps](specs/erlang-gaps.md) | `feat/erlang-gaps` | — |
| [typeparam](specs/typeparam.md) | `feat/typeparam` | — |
| [throw-check](specs/throw-check.md) | `feat/throw-check` | — |
| [trycatch-lowering](specs/trycatch-lowering.md) | `feat/trycatch-lowering` | — |
| [stdlib-result](specs/stdlib-result.md) | `feat/stdlib-result` | — |
| [interface-coverage](specs/interface-coverage.md) | `feat/interface-coverage` | — |
| [tooling](specs/tooling.md) | `feat/tooling` | — |
| [test-reorg](specs/test-reorg.md) | `feat/test-reorg` | pure test move — split monolithic `tests.zig` per stage |
| [parser-split](specs/parser-split.md) | `feat/parser-split` | pure refactor — split `parser.zig` by sub-grammar; coordinate dir with test-reorg |
| [ast-simplification](specs/ast-simplification.md) | `feat/ast-simplification` | ⚠️ do not parallelize |

## Suggested order

1. (optional) `ast-simplification` on a clean base
2. In parallel: `import-rework`, `use-await-prefix`, `implement-extend-decls` + any backlog
3. After the 3 merge: `extension-dispatch`
4. `context-inference` → `hook-codegen`

## Core syntax model

Two axes, keywords never overlap:

- **`import`** = compile-time. Bring **names** from another file + activate extension **dispatch**.
- **`use` / `await`** = runtime prefix operators, gated by the interface on the function's return type:
  - `use expr` ⟶ return implements `@Context<B, _>` (hook)
  - `await expr` ⟶ return implements `@Future<_>` (async)

```bp
import {Pato, PatoNada*} from "ducks";   // name Pato + activate PatoNada's methods

fn Panel() -> Element {
    val {count, set} = use state(0);     // use unwraps @Context
    use effect({ -> log("mounted") });
    val resp = await fetch(url);         // await unwraps @Future
}
```

Symmetry: `use` : `@Context` :: `await` : `@Future`. One rule, two interfaces.
