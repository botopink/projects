# v0.beta.2 — spec set

> A batch of independent specs. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Working notes → [`plan.md`](plan.md). Live
> progress → [`status.md`](status.md) (this README carries **no** status column).

## Features

| Spec | Slug | Depends on |
|---|---|---|
| [Docs & project-structure refactor](specs/docs-refactor.md) | `docs-refactor` | nothing |
| [Gleam-style standard library](specs/stdlib-gleam.md) | `stdlib-gleam` | nothing |
| [`test { … }` declarations](specs/test-blocks.md) | `test-blocks` | nothing |
| [`libs/std` test suite](specs/stdlib-tests.md) | `stdlib-tests` | test-blocks, stdlib-gleam |
| [Zig feature gaps (evaluate later)](specs/zig-feature-gaps.md) | `zig-feature-gaps` | nothing |
| [Comptime template strings (`type`/`expr` meta-kinds)](specs/expr-templates.md) | `expr-templates` | nothing |

<!-- more fronts to be added as defined -->

## Dependency DAG

```text
docs-refactor       (independent)
zig-feature-gaps    (independent — analysis backlog)
expr-templates      (independent — but front-end collision: not in parallel with stdlib-gleam/test-blocks)

test-blocks ─┐
stdlib-gleam ─┴─► stdlib-tests
```
