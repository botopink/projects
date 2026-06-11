# v0.beta.14 — status

> One keystone spec; track per-step (F0–F5) closure.

| Step | What | State |
|---|---|---|
| F0 | repro fixtures + failing tests for all four reports | pending |
| F1 | local-scope bindings → completion + go-to-def (params, `var`/`val` locals, `comptime` params, closure binders) | pending |
| F2 | decorator-emitting modules keep their bindings (`infer.zig` early-return fix) | pending |
| F3 | project-graph compile in the LSP (resolve `mod` siblings + `from "<lib>"`/`"std"`) | pending |
| F4 | cross-module sub-language expansion → Custom AST → semantic tokens (`erika "…"`) | pending |
| F5 | capabilities/docs (`AGENTS.md`, `docs.md`) + snapshot tests | pending |

_No language surface changes expected. Done = the four reproductions resolve and the
full test suite (`zig build test` + `botopink-lib-test`) stays green._
