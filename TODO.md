# TODO — tooling-update

> Live checklist for branch `task/tooling-update` (worktree `.tasks/tooling-update/`).
> Spec (intent, immutable): [`tasks/v0.beta.3/specs/tooling-update.md`](tasks/v0.beta.3/specs/tooling-update.md)

> **Goal**: bring `modules/language-server` + `modules/vscode-extension` up to
> the current language surface (test blocks, `#[@external]`, `@`-types, `*fn`,
> import rework, `|>`, `?.`). **F0a (ctrl+click) first** — reported broken
> 2026-06-07. Only F4 waits for `stdlib-interface`.

## F0a — Fix go-to-definition (ctrl+click) regression  ✔ DONE
- [x] Reproduce via stdio: same-file `val`/`fn`, cross-module `pub`, std module fn
      (scripted JSON-RPC session against `zig-out/bin/botopink-lsp`)
- [x] Run `src/tests/definition.zig` (9 tests) — green (suite never covered stdio)
- [x] Bisect — three real bugs, none in `identAt`/`extension.ts`:
      1. `messages.zig` framing: Zig 0.16 `takeDelimiterExclusive` stops *before*
         `\n` → body truncated → server died on the FIRST message (whole LSP
         down, not just ctrl+click). Fixed with `takeDelimiter`.
      2. `project_index.zig` `openDir` without `.iterate = true` → O_PATH fd →
         BADF panic on first `iter.next()` (killed cross-module definition).
      3. `compiler-core/build.zig` still pointed at the pre-312d1ad prelude path
         → standalone `zig build test` in language-server didn't even compile.
- [x] Fix + snapshots (same-file, cross-module, std module): std resolution via
      new `engine.definitionInStdModules` (qualifier-aware: `list.map`), module
      source materialized to `~/.cache/botopink-lsp/std/<name>.bp`; regression
      tests for the frame reader in `src/tests/messages.zig`

## F0 — Audit
- [ ] Diff grammar keywords vs `compiler-core/src/lexer/token.zig`
- [ ] Inventory unhighlighted syntax: `#[@external(…)]`, `@Expr`/`@Result`/
      `@Option`/`@Iterator`, `*fn`, `|>`, `?.`, template holes, anonymous records
- [ ] Inventory LSP gaps per feature against the same list

## F1 — TextMate grammar sync
- [ ] Update keyword groups in `botopink.tmLanguage.json`
- [ ] Add scopes: attributes, `@Type` names, `*fn`, `|>`, `?.`
- [ ] Mirror in `botopink.codeblock.json` (markdown ```bp)
- [ ] Smoke: open `libs/std/src/*.bp` and check colouring

## F2 — Snippets + language configuration
- [ ] Snippets: `test` block, `#[@external]` declare fn, `*fn`, `import from "std"`
- [ ] Review `language-configuration.json` on-enter/auto-close rules

## F3 — LSP: test blocks + stdlib surface
- [ ] `documentSymbol` + `foldingRange` for `test "name" { … }` blocks
- [ ] `completion`: std module members after `import {list} from "std"`
- [ ] `hover`: std module fns + `#[@external]` declares
- [ ] Snapshots under `snapshots/lsp/`

## F4 — LSP: interface-method dispatch  ◀ BLOCKED on stdlib-interface
- [ ] `completion` on receiver dot: `true.` / `42.` / `xs.`
- [ ] `hover` + `signatureHelp` for interface methods on primitives
- [ ] Snapshots `lsp/completion_primitive_methods`, `lsp/hover_interface_method`

## F5 — Manifest + docs
- [ ] Bump `package.json` version; refresh README
- [ ] Update both `AGENTS.md` + `docs.md`
- [ ] `zig build test` in `modules/language-server` green

## Notes
- Grammar = purely lexical; semantics belong to the LSP ("no compiler-internal
  knowledge" rule in `vscode-extension/AGENTS.md`).
- `botopink-lsp` launches with no args — no subcommands.
