# v0.beta.14 — plan

## Premise

`botopink-lsp` already implements completion, definition, hover, semantic tokens, and the
sub-language overlay — and they pass their unit tests. The tests all use **single, self
-contained documents with module-level bindings**. Real files break three assumptions at
once:

1. they have meaningful state in **function-local scope** (decorator bodies are nothing
   but locals: `decl`, `args`, the closure param `f`);
2. they **apply decorators that `@emit`**, which today zeroes the binding list;
3. they **import across modules** (`mod` siblings, `from "<lib>"`, `from "std"`), which a
   one-document compile cannot resolve — and the sub-language Custom AST is downstream of
   that same compile.

So the work is to give the server (a) a project module graph to compile against, (b) a
local-scope symbol model for completion + definition, and (c) the one `compiler-core` fix
that stops decorators from discarding bindings.

## Method

Each step in the spec is independently shippable and independently testable. Order by
leverage — the decorator early-return fix (F2) is one line and unblocks every example app;
the local-scope model (F1) unblocks every library body; the project graph (F3) is the
larger change that also lights up the sub-language overlay (F4) for free.

Per step: add a focused unit/snapshot test under `modules/language-server/src/tests/`
(or `comptime/tests/` for F2) that uses a *multi-module* or *decorator-bearing* fixture —
the existing single-doc tests are exactly why these bugs shipped, so the new tests must
reproduce the real shape.

## Risks / coordination

- **Latency.** The project-graph compile (F3) must not re-read+re-lex the world on every
  keystroke. Cache the module graph keyed by document versions; only the active document's
  source is hot. The Custom AST is already a by-product of the compile (no extra evaluator
  pass) once the graph resolves the template fn.
- **`.d.bp` discipline.** Package resolution for `from "<lib>"` must follow the lib's
  `botopink.json` `files` (declaration surface) + `root.bp`/`mod.bp` tree — the same rule
  the compiler uses — not a blind directory walk. See [[project_libs_module_migration_done]].
- **No core coupling.** The decorator fix in `infer.zig` is generic (it concerns *any*
  `@emit`ing decorator); it must not name rakun/jhonstart/onze. See
  [[feedback_compiler_unaware_of_jhonstart]].

## Done means

`zig build test` + `botopink-lib-test` stay green; the four reproductions
(`decorators.bp`, `posts.bp` ×2, `erika-linq/src/main.bp`) each have a regression test
that fails on `feat` and passes here; `language-server/AGENTS.md` + `docs.md` describe the
project-graph compile and the local-scope model.
