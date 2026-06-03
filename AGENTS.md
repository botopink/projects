# botopink-lang · root AGENTS.md

Guidance for AI agents working on the botopink language workspace.

> Convention: source, comments, commit messages and docs are all in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree. Detailed architectural explanations live in sibling
> `docs.md` files; concrete `.bp` / CLI usage in sibling `examples.md` files.

## Repository tree

```text
botopink-lang/
├── AGENTS.md                  ← you are here (workspace overview)
├── README.md                  ← public-facing intro
├── CHANGELOG.md               ← release notes (current: v0.0.13-beta)
├── docs.md                    ← language reference (.bp syntax + semantics)
├── build.zig                  ← workspace build graph (CLI + LSP)
├── test_format.zig            ← ad-hoc formatter smoke
├── test_pub.zig               ← ad-hoc pub-decl smoke
├── modules/                   ← all Zig packages — see modules/AGENTS.md
│   ├── compiler-cli/          ← `botopink` CLI
│   ├── compiler-core/         ← lexer, parser, AST, infer, comptime, codegen
│   ├── language-server/       ← `botopink-lsp` LSP server
│   └── vscode-extension/     ← VS Code extension (syntax + LSP client)
├── libs/                      ← .bp libraries — see libs/AGENTS.md
│   ├── std/                   ← standard library (prelude loaded at infer time)
│   ├── server/                ← server-side interfaces (scaffold)
│   └── client/                ← client-side interfaces (scaffold)
├── examples/                  ← .bp example programs
└── snapshots/                 ← workspace-level codegen snapshots
    └── codegen/{erlang,node}/ ← target-specific smoke outputs (commonJS, erlang)
```

## Workspace commands

```bash
zig build           # compile CLI + language-server
zig build test      # run compiler-core + language-server tests
zig build run       # run the CLI entry point
```

Per-package commands live in each package's `build.zig` — see
[`modules/AGENTS.md`](modules/AGENTS.md).

## AGENTS index — what each directory contains

```text
.                                              → workspace overview, conventions, AGENTS index
modules/                                       → all Zig packages
modules/compiler-cli/                          → `botopink` CLI executable
  └── src/                                     → argv parser + command dispatch
      └── cli/                                 → per-subcommand impls (build, run, check, format, new, clean)
modules/compiler-core/                         → main compiler library (lex → codegen)
  └── src/                                     → compiler stages (façades)
      ├── codegen/                             → per-target emitters (commonJS, erlang, beam, wasm, typescript)
      ├── comptime/                            → HM inference, unification, Aggregator transform
      │   └── runtime/                         → Node.js + Erlang external comptime eval backends
      ├── format/                              → formatter snapshot tests (round-trip stable)
      ├── lexer/                               → Token struct + lexer snapshot tests
      ├── parser/                              → parser snapshot tests (recursive descent)
      └── utils/                               → shared snap/pretty/json_diff helpers
  └── snapshots/                               → .snap.md fixtures: parser / codegen / comptime
      ├── codegen/                             → target output + error rendering
      │   ├── erlang/erlang/                   → 162 Erlang outputs
      │   ├── beam/beam/                       → 162 BEAM Assembly outputs
      │   ├── node/commonJS/                   → 162 CommonJS outputs
      │   ├── wasm/wasm/                       → 162 WASM Text outputs
      │   └── errors/                          → codegen-time error rendering (4 targets × 1)
      ├── comptime/                            → inference + evaluation snapshots (per backend)
      │   ├── erlang/{,errors/}                → success (137) + errors (44)
      │   └── node/{,errors/}                  → success (137) + errors (44)
      └── parser/                              → 174 AST golden snapshots
modules/language-server/                       → `botopink-lsp` LSP server
  ├── src/                                     → JSON-RPC server + feature engine
  │   └── tests/                               → LSP feature test harness (15 feature files)
  └── snapshots/lsp/                           → 70 LSP feature snapshots
modules/vscode-extension/                      → VS Code extension (TypeScript)
  ├── syntaxes/                                → TextMate grammar + markdown injection
  └── src/                                     → extension.ts (LSP client launcher)
libs/                                          → .bp libraries (see libs/AGENTS.md)
  ├── std/                                     → embedded standard library (prelude + interfaces)
  │   └── src/                                 → prelude.zig + primitives/array/string.bp + builtins.d.bp
  ├── server/                                  → server-side interfaces (scaffold)
  └── client/                                  → client-side interfaces (scaffold)
examples/                                      → .bp example programs
snapshots/                                     → workspace-level smoke snapshots
  └── codegen/                                 → 1 .bp scenario mirrored across targets
      ├── erlang/erlang/                       → 1 Erlang snapshot
      └── node/commonJS/                       → 1 CommonJS snapshot
```

## Where deep content lives

| Topic | Doc |
|---|---|
| Full compiler pipeline + AST model + public API | [`modules/compiler-core/docs.md`](modules/compiler-core/docs.md) |
| Façade pattern + allocator rule | [`modules/compiler-core/src/docs.md`](modules/compiler-core/src/docs.md) |
| Backend design (emitters are blind) | [`modules/compiler-core/src/codegen/docs.md`](modules/compiler-core/src/codegen/docs.md) |
| HM inference + Aggregator transform | [`modules/compiler-core/src/comptime/docs.md`](modules/compiler-core/src/comptime/docs.md) |
| CLI lifecycle | [`modules/compiler-cli/docs.md`](modules/compiler-cli/docs.md) |
| LSP layered design | [`modules/language-server/docs.md`](modules/language-server/docs.md) |
| Stdlib loading + interface conventions | [`libs/std/docs.md`](libs/std/docs.md) |
| `.bp` libraries group (std/server/client) | [`libs/AGENTS.md`](libs/AGENTS.md) |
| VS Code extension design + LSP wiring | [`modules/vscode-extension/docs.md`](modules/vscode-extension/docs.md) |
| `.bp` language reference (user-facing) | [`docs.md`](docs.md) |

## Where concrete examples live

| Topic | Doc |
|---|---|
| `botopink` CLI command usage | [`modules/compiler-cli/src/cli/examples.md`](modules/compiler-cli/src/cli/examples.md) |
| `.bp` token / numeric literal syntax | [`modules/compiler-core/src/lexer/examples.md`](modules/compiler-core/src/lexer/examples.md) |
| `.bp` declarations / expressions / statements | [`modules/compiler-core/src/parser/examples.md`](modules/compiler-core/src/parser/examples.md) |
| `.bp` source → JS / Erlang side-by-side | [`modules/compiler-core/src/codegen/examples.md`](modules/compiler-core/src/codegen/examples.md) |
| `comptime` usage in `.bp` | [`modules/compiler-core/src/comptime/examples.md`](modules/compiler-core/src/comptime/examples.md) |
| `botopink format` before/after | [`modules/compiler-core/src/format/examples.md`](modules/compiler-core/src/format/examples.md) |
| Using the stdlib (Array, String, builtins) | [`libs/std/src/examples.md`](libs/std/src/examples.md) |
| Minimal runnable `.bp` program | [`examples/hello.bp`](examples/hello.bp) |

## Conventions

- **AGENTS.md must always be kept up to date.** Whenever code, layout, or
  pipeline behaviour changes, update the affected `AGENTS.md` / `docs.md`
  in the same change. Each directory's `AGENTS.md` is the contract for
  that directory — stale docs are worse than missing docs.
- **`README.md` and `docs.md` (language reference) must also stay in sync.**
  When a language feature, CLI flag, syntax form, or compiler-visible
  behaviour changes, update both files alongside the code.
- **English only** in source, comments, commits, AGENTS.md docs.
- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an
  allocator — it is always passed as `alloc: std.mem.Allocator` to the
  method that needs it.
- Type annotations always use `TypeRef` (`named`, `array`, `tuple_`,
  `optional`, `function`, `generic`). Generic types use `is_builtin`
  flag to distinguish `@Result<D, E>` (builtin) from `MyType<T>` (user).
- Record/struct/enum/interface shorthand decls map to the same AST nodes
  as long-form declarations.
- Formatter must be round-trip stable: `format(parse(src))` must re-parse
  to an equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across
  cycles.

## Parallel tasks (git worktrees)

Independent features are developed in parallel, one **git worktree per task**
under `.tasks/<name>/`, each on its own `task/<name>` branch. `feat` is the
integration branch (it receives the merges); `main` is **not** — it diverges
and lacks the task base. Always branch off `feat`, and run all remote git
operations over **SSH** (`git@github.com:botopink/botopink-lang.git`).

### Create a task

```bash
# from the main worktree (on feat), one per independent feature:
git worktree add .tasks/<name> -b task/<name> feat
```

Pick names that touch **disjoint files** where possible so tasks run without
blocking each other; when two tasks share a backend file (e.g. `beam_asm.zig`
or `wat.zig`), note the collision in both TODO.md files so integration expects
the conflict.

### Feed a task — `TODO.md` is the per-task spec

Each worktree carries its own `.tasks/<name>/TODO.md`, distinct from this root
roadmap. Keep it short — it states **only what the task will do**:

```markdown
# <name>

**Branch**: `task/<name>` (born from `feat` <short-sha>)
**Depends on**: <prereq already in feat, or "nothing">
**Files**: <target source files>

## What this task will do
- [ ] <step>
- [ ] <step>
- [ ] Snapshots per backend / feature

## On completion (commit → update remote `feat` → delete task)
<the three steps below>
```

Tool paths (Read/Edit/Write) must target the worktree
(`.../botopink-lang/.tasks/<name>/...`), never the main repo — it is easy to
edit the wrong tree. Do not `cd` into the main repo in Bash; the hook resets
cwd to the worktree.

### On completion — commit, update remote feature, delete the task

1. **Commit** inside the worktree (no `cd`): `git add -A && git commit -m "…"`.
   A **pre-commit hook runs `zig fmt` + `zig build` + `zig build test`** — the
   commit only lands if it compiles and tests pass. Do not use `--no-verify`.
2. **Update the remote feature** (integrate into `feat`, over SSH). The main
   `feat` worktree is often dirty with other WIP, so integrate via a throwaway
   worktree based on the remote:
   ```bash
   git fetch origin feat
   git worktree add .tasks/_integrate-<name> -b integrate/<name> origin/feat
   #   in it:  git merge --no-ff task/<name>  →  resolve  →  zig build test
   git push origin integrate/<name>:feat      # fast-forward, never --force
   ```
   `feat` refactors the AST fast; an old task merge conflicts in
   `infer.zig` / `env.zig` / `error.zig` / `tests.zig`. Take `feat`'s version
   and re-apply the task edits on the new AST rather than stitching markers.
   Task `.snap.md` files were generated on the old base — delete the task's and
   regenerate by running `zig build test` under `feat` (missing snapshots are
   recreated).
3. **Delete the task** once integrated:
   ```bash
   git worktree remove .tasks/<name> && git worktree remove .tasks/_integrate-<name>
   git branch -d task/<name> integrate/<name>
   git worktree prune
   ```

### Open parallel tasks

| Worktree (`.tasks/`) | Branch | Scope (see its TODO.md) |
|---|---|---|
| `ext-dispatch-backends` | `task/ext-dispatch-backends` | extension-dispatch call-site rewrite for Erlang/BEAM/WAT/TS |
| `result-runtime` | `task/result-runtime` | real `@Result`/`@Option` runtime in BEAM/WASM (today: stubs) |
| `wat-features` | `task/wat-features-impl` | WAT destructure, pipeline, string ops, linear-memory layout, tag-based try/catch |
| `beam-asm-finish` | `task/beam-asm-finish` | BEAM phases 7–9: full ranges, full try/catch, polish, guards |

## Recent commit context

| Commit | Summary |
|---|---|
| `611275f` | feat: lower try/catch to `Ok`/`Error` pattern matching across all backends (+ `tryOnNonResult` inference error) |
| `a42d948` | feat: add `Expr.useHook` AST variant for use-hooks in function bodies |
| `1888bfb` | feat: reject old `from "mod"` import syntax with migration hint |
| `65f990d` | feat: use syntax migration `from "mod"` → `= @root()` / `= @module()` |
| `8a79f94` | feat: `@Result<D, E>` generic syntax with `is_builtin` flag, snapshot refresh |
| `7991edc` | feat: wasm/beam comptime runtimes, `@print` test coverage, TODO roadmap |
| `4cf9e60` | test: refresh WAT snapshots — memory, data section, WASI print |
| `76f247a` | test: refresh BEAM + Erlang snapshots with run log output |
| `1705da2` | feat(wasm): linear memory, WASI `@print`, case, loops |
| `d090e36` | feat(beam): test_heap guards, real loops, dead code fix |
| `f9a1a13` | refactor: rename snapshot dirs `beam_asm` → `beam`, `wat` → `wasm` |

Current release: see [`CHANGELOG.md`](CHANGELOG.md) (v0.0.13-beta, May 2026).

When editing files: consult the closest `AGENTS.md` first, then parent
docs up to this root file. For design rationale read the sibling
`docs.md`; for concrete syntax / CLI usage read the sibling
`examples.md`.
