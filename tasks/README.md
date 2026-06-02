# Tasks — one file per feature

Each file is a self-contained feature (branch name, dependencies, steps, test scenarios).

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

| File | Branch | Phase | Depends on | Status |
|---|---|---|---|---|
| [import-rework.md](import-rework.md) | `feat/import-rework` | F0–F2 | — | pending |
| [use-await-prefix.md](use-await-prefix.md) | `feat/use-await-prefix` | F3 | — | pending |
| [implement-extend-decls.md](implement-extend-decls.md) | `feat/implement-extend-decls` | F4–F5 | — | pending |
| [extension-dispatch.md](extension-dispatch.md) | `feat/extension-dispatch` | F6 | import-rework + implement-extend-decls | blocked |
| [context-inference.md](context-inference.md) | `feat/context-inference` | F7 | use-await-prefix + extension-dispatch | blocked |
| [hook-codegen.md](hook-codegen.md) | `feat/hook-codegen` | F8 | context-inference | blocked |

## Parallel backlog (independent)

| File | Branch | Status |
|---|---|---|
| [async-generators.md](async-generators.md) | `feat/async-generators` | pending (`await` prefix comes from use-await-prefix) |
| [beam-asm.md](beam-asm.md) | `feat/beam-asm` | pending (Phases 1–2 done) |
| [wat-features.md](wat-features.md) | `feat/wat-features` | pending |
| [erlang-gaps.md](erlang-gaps.md) | `feat/erlang-gaps` | pending |
| [typeparam.md](typeparam.md) | `feat/typeparam` | pending |
| [throw-check.md](throw-check.md) | `feat/throw-check` | pending |
| [trycatch-lowering.md](trycatch-lowering.md) | `feat/trycatch-lowering` | pending |
| [stdlib-result.md](stdlib-result.md) | `feat/stdlib-result` | pending |
| [interface-coverage.md](interface-coverage.md) | `feat/interface-coverage` | pending (Phase 1 done) |
| [tooling.md](tooling.md) | `feat/tooling` | pending |
| [ast-simplification.md](ast-simplification.md) | `feat/ast-simplification` | pending ⚠️ do not parallelize |

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
