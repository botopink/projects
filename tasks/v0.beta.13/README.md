# v0.beta.13 — test audit: scenarios for the language as it is today

> Not a feature wave. This version **re-derives the test scenarios for the CURRENT
> `feat`** and flags the coverage gaps. Many earlier specs (v0.beta.1–12) describe
> syntax that no longer exists (`*fn`, `@[external]` blocks, `to_string`, the old
> import-activation rules) or features that were superseded. Here every scenario uses
> the syntax that compiles **today**, and each is tagged `[have]` or `[gap]`.

## Tag convention

Each scenario line is prefixed:

- `[have]` — behaviour that current tests already exercise (Zig `test {}` / snapshot /
  `.bp` `test {}` / runner). Listed so the audit is complete, not to re-write.
- `[gap]`  — a current feature with **no** (or only partial / unverified) coverage. These
  are the work items: add the test.

Phase tags after the prefix follow the repo convention:
`parser` · `format` · `infer` · `comptime` · `codegen/{node,erlang,beam,wasm}` · `run` ·
`run/{node,erlang,beam,wasm}` · `lsp` · `cli` · `gate`.

## What changed since the old specs (excluded from every scenario)

| Dead form | Current form |
|---|---|
| `*fn` effect marker | `#[@result]` / `#[@future]` / `#[@generator]` on the impl |
| `@[external(…)]` block | `#[@external(target,"mod","sym")]` attribute (stackable) |
| `to_string` | `toString` (camelCase) |
| bare `import {X*}` ad-hoc activation + free `extend Type {}` | extension-discipline: local `implement` auto-applies; `extend` requires an interface; `*` only activates a **cross-module** import |
| implicit file-scan packaging | `mod` / `pub mod` module tree |
| string `q.build(...)` sub-language scanner | `@Expr`/`@ExprCustom` + `q.custom` (erika today; html being migrated) |

## Three parallel fronts (file-disjoint — work any one without touching the others)

The audit is split into **at most 3 fronts**, partitioned by **file territory** so each can
be a separate worktree/branch with **zero overlap**. Pick a front; you only edit its files.

| Front | Spec(s) | Territory it edits (disjoint) | Areas covered |
|---|---|---|---|
| **A — core** | [front-a-core](specs/front-a-core.md) | `modules/compiler-core/src/**/tests/*.zig` + `snapshots/**` | effects · errors-result-option · pattern-matching · generics-recursion-context · extension-dispatch · module-system · expr-templates · backends codegen-**snapshots** |
| **B — libs & examples** | [front-b-libs](specs/front-b-libs.md) | `libs/**` (`.bp` tests) + `examples/**` (demo apps) | stdlib · sublanguages (lib-side expansion) · frameworks (rakun/jhonstart/onze) |
| **C — runtime & editor** | [front-c-runtime](specs/front-c-runtime.md) | `modules/{language-server,vscode-extension,compiler-cli/tests,lib-test-runner}` | test-tooling · backend **execution** (.sh/wasm) · language-server (every LSP request + overlay) · VS Code client |

**Why these three never collide:** A is pure compiler-core (Zig `test {}` + `.snap.md`); B is
pure `.bp`/`examples` (run via `botopink test`); C is the CLI/runner/LSP/VS-Code tooling.
No file is owned by two fronts. Areas that spanned a boundary were split at the file seam:
**backends-parity** → codegen snapshots in A, execution scripts in C; **sub-languages** →
lib-side expansion in B, the LSP overlay in C. Exactly one spec per front
(`front-c-runtime.md` absorbed the former `language-server.md` + `vscode-extension.md` as its
C3/C4 sections). Each front maps to a worktree: `task/v13-core`, `task/v13-libs`,
`task/v13-tooling`.

## Goal

Turn every `[gap]` into a `[have]`. No production behaviour changes are required by this
version — only tests (and the tiny fixtures they need). Where a `[gap]` exposes a real
product gap (e.g. a backend that can't execute a construct), record it as a limitation
instead of forcing a test. See [`plan.md`](plan.md) and live [`status.md`](status.md).
