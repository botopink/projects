# Task status — v0.beta.3

> **Single source of truth for v0.beta.3 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.3`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [backend-parity](specs/backend-parity.md) | pending | merged | present | 0/30 done |
| [generic-inference](specs/generic-inference.md) | pending | merged | present | 0/12 done |
| [stdlib-interface](specs/stdlib-interface.md) | pending | — | — | — |
| [tooling-update](specs/tooling-update.md) | pending | merged | present | 0/24 done |

## Notes

- **generic-inference** is a prerequisite for `stdlib-interface` (generic modules
  get inline tests once `.typeVar` instantiation is fixed).
- **backend-parity** is independent — can run in parallel with any other spec.
- **tooling-update** F0–F3/F5 are independent; F4 (interface-method completion)
  waits for `stdlib-interface`.
