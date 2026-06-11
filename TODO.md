# TODO — lsp-project-awareness (v0.beta.14)

**Branch**: `task/lsp-project-awareness` (from `origin/feat` @ 36347ab)
**Slug**: lsp-project-awareness · **Spec**: `tasks/v0.beta.14/specs/lsp-project-awareness.md`
**Depends on**: `module-system` (graph + `from "<lib>"` resolution, DONE), `sublanguage-lsp`
(Custom AST overlay, DONE), `libs-module-migration` (`botopink.json` `files` surface, DONE).
**Status**: DONE — F0–F5 implemented; `zig build test` green (fmt + lib-agnostic gate +
1100+ tests). `botopink-lib-test` commonJS green (erlang reds pre-existing, backends-parity
scope). Codegen byte-identical (snapshots + test-libs unchanged).

> Edit code **inside this worktree only** (`.tasks/lsp-project-awareness/...`), not the main
> repo. Pre-commit runs zig fmt + build + test (no `--no-verify`).

## Why

The editor tooling goes dark on real files: comptime decorator bodies, example apps that
apply emitting decorators, and any file importing across modules. One structural cause —
**the LSP compiles each document in isolation and has no local-scope symbol model**. This
task makes completion, go-to-def, hover, and sub-language highlighting survive those shapes.
No language surface changes.

## Four reproductions (each must gain a regression test)

```
R1  libs/rakun/src/decorators.bp     completion + Ctrl+Click on `decl` / `args` / `f` → nothing
R2  examples/rakun/posts.bp          completion empty everywhere in the file
R3  examples/rakun/posts.bp          Ctrl+Click on `Response.created` (and every import) → nothing
R4  examples/erika-linq/src/main.bp  `erika "select name from cities …"` painted as a plain string
```

## Files

- `modules/language-server/src/{server,compiler,engine,project_index}.zig`
- `modules/compiler-core/src/comptime/infer.zig` (F2 — the one narrow core fix)
- Docs: `modules/language-server/AGENTS.md`, `modules/language-server/src/docs.md`

## Checklist

### F0 — reproductions first
- [x] Failing test per report under `modules/language-server/src/tests/` (F2's lives in
      `comptime/tests/`), each using the real shape (decorator body of locals; record with
      `#[service]`; `from "<lib>"` member access; cross-module `erika "…"`). Must fail on
      `feat`.

### F1 — local-scope symbol model (R1)
- [x] Position-scoped view at the cursor: params, `comptime` params, `val`/`var` locals from
      enclosing blocks, closure binders (`{ f -> … }`). Source from the typed body; fall back
      to an AST/token walk so completion degrades, not vanishes, on a type error.
- [x] `engine.completion` merges locals with module-level bindings (inner shadows outer),
      prefix-filtered. Kind `Variable` for locals.
- [x] go-to-def resolves a param / `var` / closure binder to its binding site in the enclosing
      function, nearest scope wins over a same-named top-level decl. Add `var` to the decl
      keyword set in `findDeclLocation`.

### F2 — decorators must not discard bindings (R2)
- [x] In `inferProgramTyped` (`infer.zig:147-151`), stop returning an empty list when
      `env.contributions.items.len > 0`. Collect `TypedBinding`s for the source decls (record,
      fields, imported decorator names) before returning, or surface the spliced
      `analyzeSource` bindings. **Generic — no rakun/jhonstart/onze names in core.**
- [x] Verify `@emit` codegen / `botopink test` output is byte-identical after the fix.

### F3 — project-graph compile in the LSP (R3)
- [x] Compile the active document **with its module graph** (`compiler.zig`/`server.zig`),
      using the compiler's own rules: `mod`/`pub mod` siblings via `root.bp`/`mod.bp`;
      `from "<lib>"` via the lib `botopink.json` `src` + `files`; `from "std"` via embedded std.
      Active doc stays the hot in-memory copy; deps read from disk.
- [x] Cache the graph keyed by dependency document versions; a keystroke re-infers only the
      active doc. Invalidate on save/watch.
- [x] go-to-def for `from "<lib>"` symbols incl. member access (`Response.created`) resolves
      through the graph, independent of the editor workspace root. `project_index` stays the
      fast path.

### F4 — cross-module sub-language expansion (R4)
- [x] With F3, the cross-module `erika`/`html` template fn resolves, so the eval compile
      expands `erika "…"` and `customAstFor(uri)` returns the `CustomNode` tree. Confirm
      `engine.customSemanticTokens` paints `select`/`from`/`where`/`order by` as `keyword`,
      idents as `property`. Overlay code unchanged — only the AST now exists.
- [x] Confirm the same compile feeds `definitionCustomRef` / `hoverCustomRef` for a
      cross-module sub-language literal.

### F5 — capabilities + docs
- [x] Document the project-graph compile + local-scope model in `language-server/AGENTS.md`
      and `src/docs.md`. No new capability advertised — these correct existing providers.
- [x] Snapshots under `snapshots/lsp/`: decorator body (completion + def), `#[service]` record
      (completion), `from "<lib>"` member def, cross-module `erika "…"` (semantic tokens).

## Done means

`zig build test` + `botopink-lib-test` green; the four reproductions each have a regression
test that fails on `feat` and passes here; AGENTS.md + docs.md updated. See the spec's
`## Test scenarios` block for the full `[have]`/`[gap]` list.
