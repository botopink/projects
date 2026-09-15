# Specs — 1.0.0-beta

Closed. Every open item below was carried into [`1.0.1-beta`](../1.0.1-beta/overview.md).

| # | Spec | Priority | What |
|---|------|----------|------|
| 01 | [`01-test-green/`](./01-test-green/README.md) | critical | `zig build test` green: comptime eval on erl (decorators + templates), allocation leaks, decorator regression tests. Blocks everything else. |
| 02 | [`02-type-system.md`](./02-type-system.md) | medium | Comptime type values, `#[@code]` type lifting, std type functions, state narrowing. |
| 03 | [`03-codegen-hardening.md`](./03-codegen-hardening.md) | medium | Backend runtime crashes, WAT execution, missing codegen coverage, erl runtime regression tests. |

## Dependencies

```
01-test-green
  ├──► 02-type-system   (comptime eval must work before value-level type evaluation)
  └──► 03-codegen-hardening (template/@Expr codegen tests need template eval)
```

02 and 03 are independent of each other.

## Branches

Each step runs in its own worktree `.tasks/<name>` and branch — see
[`../../AGENTS.md`](../../AGENTS.md#worktrees).
