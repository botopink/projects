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

## F0 — Audit  ✔ DONE
- [x] Diff grammar keywords vs lexer table (`lexer.zig` `keywordOrIdent`, not
      just the `token.zig` enum). Missing: `await`, `extend`. Stale (not real
      keywords): `typeinfo`, `echo`, `todo`. `|>` already present.
- [x] Inventory unhighlighted syntax: `#[@external(…)]` (only `@external`
      caught generic @-builtin), `@Expr`/`@Result`/`@Option`/`@Iterator`
      (mis-scoped as builtin *functions* — should be types), `*fn`, `?.`,
      `${…}` holes. Anonymous records = lexically `{…}` blocks → semantic, skip.
- [x] LSP gaps inventory → F3 (test blocks not in documentSymbol/foldingRange;
      std module completion/hover); F4 (primitive receiver methods).

## F1 — TextMate grammar sync  ✔ DONE
- [x] Keyword groups synced (`+await`, `+extend`, `-typeinfo/-echo/-todo`)
- [x] Added scopes: `#[…]` attribute block, builtin `@Type` names (before the
      generic @-rule), `*fn` effect `*`, `?.` chaining, `${…}` interpolation
- [x] `botopink.codeblock.json` injects `source.botopink` → inherits all of the
      above automatically (no mirror edits needed)
- [x] JSON + regex sanity validated; no vscode-textmate locally for live tokens

## F2 — Snippets + language configuration  ✔ DONE
- [x] Snippets added: `test` block (linked got mirror) + `assert`,
      `#[@external]` declare fn (`external`), `*fn` generator, `importstd`
- [x] Reviewed `language-configuration.json`: `#[…]` auto-closes via `[`/`]`,
      `${…}` via `{`/`}`; indentation rules already cover blocks — adequate

## F3 — LSP: test blocks + stdlib surface  ✔ DONE
- [x] `documentSymbol` (Method kind, string-literal name) + `foldingRange` for
      `test "name" { … }` blocks
- [x] `completion`: `list.`/`io.` lists the std module's `pub fn`s (signatures as
      detail), gated on `import { … } from "std"` (`stdModuleCompletion`)
- [x] `hover`: qualified std member renders `pub [declare] fn` signature + doc
      comment from embedded source, tagged `from std/<module>` (`hoverStdModule`)
- [x] Snapshots: hover_std_module_fn, hover_std_external_declare,
      symbols_test_block, folding_test_block; stdio-verified end to end
      (100 LSP tests green)

## F4 — LSP: interface-method dispatch  ✔ DONE
- [x] Unblocked: `stdlib-interface` landed primitive/array/string interfaces
      (`primitives.d.bp` `I32`/`U32`/…/`Bool`, `array.d.bp` `Array<T>`,
      `string.d.bp` `String`), pulled in via the generic-inference merge.
- [x] Exposed the embedded interface sources to the LSP:
      `comptime_pipeline.{primitive_interfaces_src,array_interface_src,
      string_interface_src}` (new pub consts in `comptime.zig`).
- [x] `completion` on receiver dot: `true.` / `42.` / `xs.` / `"s".` — resolves
      the receiver's inferred type → interface, lists its `fn`/`val` members
      (`builtinReceiverCompletion`/`receiverBuiltinInterface`/
      `collectInterfaceMembers` in `engine.zig`). Member-end scan tracks paren
      depth so `fn`-typed params (`map(transform: fn(item:T)->T)`) aren't truncated.
- [x] `hover` (`hoverBuiltinInterfaceMethod`, digit-tolerant `dotReceiverBefore`)
      + `signatureHelp` (`builtinMethodSignature`, drops the implicit `self`) for
      interface methods on builtin receivers.
- [x] Snapshots: `completion_primitive_methods`, `completion_bool_methods`,
      `completion_array_methods`, `hover_interface_method`,
      `hover_interface_method_array`, `sig_interface_method`. `zig build test`
      green (106/106). Stdio-verified end to end: `n.`/`true.`/`xs.` completion +
      hover, `n.clamp(` signatureHelp.
> Caveat: an integer *literal* receiver (`42.`) is engine-correct but the editor
> can't reach it — a buffer with `42.method()` doesn't compile (the lexer reads
> `42.` as a float), so completion gates on a clean compile. Realistic path is a
> variable (`val n = 42; n.`). Mapping covers `i32/u32/i64/u64/f32/f64`→I32…/Bool,
> `string`→String, `array`→Array; other widths (`i8`/`i16`/…) have no interface yet.

## F5 — Manifest + docs  ✔ DONE
- [x] Bumped `package.json` 0.0.1 → 0.1.0; refreshed README feature list
      (attributes/@-types/`*fn`/`?.`/`${…}`, std go-to-def, std completion,
      test-block symbols, new snippets)
- [x] Updated language-server + vscode-extension `AGENTS.md` + `docs.md`
      feature tables (done incrementally across F0a/F1/F3)
- [x] `zig build test` in `modules/language-server` green (100/100)

## Notes
- Grammar = purely lexical; semantics belong to the LSP ("no compiler-internal
  knowledge" rule in `vscode-extension/AGENTS.md`).
- `botopink-lsp` launches with no args — no subcommands.
