# scripts

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Repo maintenance scripts (bash). Born in the `docs-refactor` spec
(`tasks/v0.beta.2/specs/docs-refactor.md`, F4).

## Tree

```text
scripts/
├── AGENTS.md        ← you are here
├── doc-health.sh    ← doc invariants: orphan source dirs, broken md links, volatile counters
└── status.sh        ← print a set's status.md rollup table (usage: status.sh v0.beta.2)
```

## Conventions

- `set -euo pipefail`; run from anywhere (each script `cd`s to the repo root).
- Read-only by default — scripts print to stdout; the caller redirects into files.
- Exit 0 = healthy, 1 = violations (one line per violation on stderr).
