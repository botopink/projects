# Task status — v0.beta.3

> **Single source of truth for v0.beta.3 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.3`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [backend-parity](specs/backend-parity.md) | F7/F8/F0/F9 done; F1–F6 pending | merged | present | 4/10 phases |
| [generic-inference](specs/generic-inference.md) | F1 (per-call instantiation) done; F2/F3 superseded by stdlib-interface | merged | present | done |
| [stdlib-interface](specs/stdlib-interface.md) | src+wiring done; compiler integration in progress (13 std_package tests red) | merged (via generic-inference) | .tasks/generic-inference | in progress |
| [tooling-update](specs/tooling-update.md) | done (F0a–F5) | merged | — | done |
| [editor-experience](specs/editor-experience.md) | merged | merged | present | — |

## Notes

- **generic-inference** is a prerequisite for `stdlib-interface` (generic modules
  get inline tests once `.typeVar` instantiation is fixed).
- **backend-parity** is independent — can run in parallel with any other spec.
- **tooling-update** F0–F3/F5 are independent; F4 (interface-method completion)
  waits for `stdlib-interface`.
