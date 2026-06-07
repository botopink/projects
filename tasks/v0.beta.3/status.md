# Task status — v0.beta.3

> **Single source of truth for v0.beta.3 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.3`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [generic-inference](specs/generic-inference.md) | pending | — | — | — |
| [stdlib-interface](specs/stdlib-interface.md) | pending | — | — | — |
| [expr-templates](specs/expr-templates.md) | pending | — | — | — |
| [backend-parity](specs/backend-parity.md) | pending | — | — | — |

## Notes

- **generic-inference** is a prerequisite for `expr-templates` (comptime template
  expansion calls generic functions internally; same `.generic` var instantiation
  issue would surface).
- **backend-parity** is independent — can run in parallel with either other spec.
