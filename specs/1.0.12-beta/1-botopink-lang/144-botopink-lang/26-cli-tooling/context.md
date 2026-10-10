# Front 26 — cli-tooling: a program built by the CLI serves on the BEAM, and every driver speaks

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s9 → B-27 · rows → B-27. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high · **State:** partial: steps 1, 2 (box 3 measured, rakun's row), 3, 4, 5, 6, 7 and 8
done; step 9 open
**Depends on:** `../../02-std-and-packaging/98-packaging-tail/` step 4 (decision 344's manifest
side; the `bpmp` resolver half is step 6) · 23-c's two `botopink test` fixes confirmed (decision 317 — this front's files, kept)
**Owns:** `modules/compiler-cli/**` (`src/cli/{build,run,test_cmd,libs,sources,config,resolver}.zig`,
the rest, `tests/**`) · `modules/bpmp/**` except `src/manifest.zig` under 98's step 4 ·
`modules/language-server/src/**` except `src/tests/**` (07) and `project_graph.zig`'s import-tree
cells (23) · `modules/language-server/snapshots/lsp/**` · `repository/vscode-extension/**` ·
`scripts/test-vscode.sh` · root `build.zig` except 18's `render-resident` / `compiler-web` steps
(decision 219) · its cells
**Does not touch:** `modules/compiler-core/**` (a CLI row needing the emitter is a named 02/03 step)
· `scripts/gate.sh`, `scripts/check-docs.sh` (`00-gate/114`) · `modules/manifest/**` (98)

Paths relative to `repository/botopink-lang/modules/` unless a row says otherwise.

## Goal

`botopink build` / `run` ship and load every sidecar `test` does, on erlang and beam; imports name
only declared dependencies (decision 242); `build`, `test` and the LSP print checker warnings as
`check` does.

## Notes

- `project_graph.zig` shared with 23 (import-tree cells), `src/tests/**` with 07: named carve-outs,
  sequenced by commit.
- `wip/br5-beam-templates` branch (C-24) is the maintainer's to delete.
