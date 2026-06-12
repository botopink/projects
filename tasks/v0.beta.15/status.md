# v0.beta.15 — status

> One keystone spec ([`lsp-definition-completeness`](specs/lsp-definition-completeness.md));
> track per-step (F0–F6) closure. **In progress** in `.tasks/lsp-definition-completeness`
> (branch `task/lsp-definition-completeness`).

| Step | What | Reproductions | State |
|---|---|---|---|
| F0 | repro fixtures + failing tests (real erika shape) | R2–R7 | in progress |
| F1 | member-access definition (`recv.field` / `recv.method`), type-aware | R2, R4, R5 | pending |
| F1b | builtin-receiver methods → `primitives.d.bp` | R6 | pending |
| F2 | `self.field` → enclosing record | R4 | pending |
| F3 | named constructor-argument labels (`Name(field: …)`) | R3 | pending |
| F4 | `mod` reference → sibling module file | R7 | pending |
| F5 | cross-module fields (`definitionInModules`, `require_pub`) | — | pending |
| F6 | docs (`AGENTS.md`, `docs.md`) + snapshot/unit tests | — | pending |

_No language surface changes. Done = R2–R7 resolve in `libs/erika/src/{erika,root}.bp` +
fixtures, method go-to-def is type-aware without regressing name-based jumps, and the full
suite (`zig build test` + `botopink-lib-test`) stays green._
