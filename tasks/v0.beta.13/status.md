# v0.beta.13 — status

> Test-audit version, split into 3 file-disjoint fronts. Track gap closure, not features.

| Front | Spec(s) | Worktree | State |
|---|---|---|---|
| A — core | front-a-core | `task/v13-core` | pending |
| B — libs & examples | front-b-libs | `task/v13-libs` | pending |
| C — runtime & editor | front-c-runtime (C1 tooling · C2 exec · C3 LSP · C4 vscode) | `task/v13-tooling` | pending (vscode C4: no harness yet, F0) |

_Each front is one worktree/branch; they share no files, so all three run in parallel.
Fill have/gap counts per spec as worked. No production behaviour is expected to change —
only tests added and limitations recorded._
