# lsp-project-awareness — the language-server "sees" real project files

**Slug**: lsp-project-awareness
**Depends on**: [`module-system`](../../v0.beta.11/specs/module-system.md) (module graph + `from "<lib>"` resolution, DONE), [`sublanguage-lsp`](../../v0.beta.10/specs/sublanguage-lsp.md) (Custom AST overlay, DONE), [`libs-module-migration`](../../v0.beta.10/specs/libs-module-migration.md) (`botopink.json` `files` surface, DONE)
**Files**: `modules/language-server/src/{server,compiler,engine,project_index}.zig`, `modules/compiler-core/src/comptime/infer.zig`
**Touches docs**: `modules/language-server/AGENTS.md`, `modules/language-server/src/docs.md`
**Status**: pending

> The LSP's features are correct in isolation but **die on the files that matter**:
> comptime decorator bodies, example apps that apply emitting decorators, and any file
> that imports across modules. The cause is structural, not per-feature: every handler
> compiles a **single document** (`server.zig`: one `ModuleEntry`) and the binding model
> is **module-level only**. Real files have local scope, cross-module imports, and
> decorators that `@emit`. This spec closes all four without adding language surface.

## The four reproductions (must each gain a regression test)

```
R1  libs/rakun/src/decorators.bp     completion + Ctrl+Click on `decl` / `args` / `f` → nothing
R2  examples/rakun/posts.bp          completion empty everywhere in the file
R3  examples/rakun/posts.bp          Ctrl+Click on `Response.created` (and every import) → nothing
R4  examples/erika-linq/src/main.bp  `erika "select name from cities …"` rendered as a plain string
```

## Root cause (verified on `feat`)

- **`engine.completion`** (`engine.zig:2740`) iterates the flat module-level
  `bindings` slice and filters by prefix only. Function-local `val`/`var`, parameters,
  `comptime` params, and closure binders are **never in that slice** → R1 (completion).
- **`findDeclLocation`** (`engine.zig:433`) matches only declaration *keywords*
  `{ val, fn, record, struct, enum, interface }`. A parameter (`comptime decl: @Decl`), a
  `var` local (`args`), and a closure binder (`{ f -> … }`) carry no such keyword → R1
  (go-to-def). Note `var` is absent from the keyword set entirely.
- **`inferProgramTyped`** (`infer.zig:147-151`) returns the binding list **early and
  empty** whenever decorators produced `@emit` contributions: the per-decl loop that
  appends bindings sits *after* that `return`. Any file applying an emitting decorator
  (`#[service]`, `#[controller]`, …) hands the LSP zero bindings → R2.
- **Single-document compile** (`server.zig`, every handler builds
  `[_]ModuleEntry{.{ .uri, .source }}`): `mod` siblings and `from "<lib>"`/`"std"`
  packages are unresolved. Go-to-def leans on `project_index`, which only sees whatever
  `.bp` files fall under the editor's **workspace root** (`project_index.zig:128`), so
  `from "rakun"` resolves by luck, not by the lib's `botopink.json` → R3. And the
  sub-language Custom AST is a by-product of *expanding* the `erika` template fn during
  that compile — unresolved template fn ⇒ no expansion ⇒ `customAstFor(uri)` empty ⇒ no
  overlay tokens → R4.

## Steps

### F0 — reproductions first
- [ ] Add a failing test per report under `modules/language-server/src/tests/` (F2's lives
      in `comptime/tests/`), each using the **real shape**: a decorator body full of
      locals (R1), a record carrying `#[service]` + fields (R2), a `from "<lib>"` member
      access (R3), a cross-module `erika "…"` (R4). These must fail on `feat` — the
      existing single-document tests are precisely why the bugs shipped.

### F1 — local-scope symbol model (R1)
- [ ] Give the engine a position-scoped view of bindings visible at the cursor: function
      parameters, `comptime` params, `val`/`var` locals declared earlier in the enclosing
      blocks, and closure binders (`{ f -> … }` / `{ a, b -> … }`). Source this from the
      typed body where available; fall back to a token/AST walk of the enclosing function
      so it works even when the body fails to type-check (completion must degrade, not
      vanish).
- [ ] `engine.completion` merges these locals with the module-level bindings, inner scopes
      shadowing outer, filtered by the prefix as today. Item `kind`: `Variable` for
      locals, `Property`/`Variable` for params.
- [ ] `findDeclLocation` (or a new local-first path in `engine.definition`) resolves a
      parameter / `var` / closure binder to its **binding site within the enclosing
      function**, preferring the nearest enclosing scope over a same-named top-level decl.
      Add `var` to the declaration-keyword set so `var`-locals resolve at all.

### F2 — decorators must not discard bindings (R2)
- [ ] In `inferProgramTyped` (`infer.zig:147-151`), stop returning an empty list when
      `env.contributions.items.len > 0`. The bindings the LSP needs (the record, its
      fields, the imported decorator names) come from the **original** decls, which are
      already inferable; only the *spliced re-analysis* of `@emit`ed code must be deferred.
      Continue collecting `TypedBinding`s for the source decls before returning, or run the
      spliced `analyzeSource` and surface its bindings. Generic — no rakun/jhonstart/onze
      names in core ([[feedback_compiler_unaware_of_jhonstart]]).
- [ ] Verify `botopink test` / decorator `@emit` codegen is unchanged (the early-return was
      a perf/ordering shortcut, not a correctness requirement for the binding list).

### F3 — project-graph compile in the LSP (R3, and the substrate for R4)
- [ ] `compiler.zig`/`server.zig`: compile the active document **with its module graph**,
      not alone. Resolve, using the same rules the compiler uses
      ([[project_libs_module_migration_done]]): `mod`/`pub mod` siblings via
      `root.bp`/`mod.bp`; `from "<lib>"` via the lib's `botopink.json` `src` + `files`
      (declaration surface); `from "std"` via the embedded std package. The current
      document's source stays the hot/in-memory copy; dependencies are read from disk.
- [ ] Cache the resolved graph so a keystroke re-lexes/re-infers only the active document,
      not the world. Key by dependency document versions; invalidate on save/watch.
- [ ] Go-to-def for `from "<lib>"` symbols (incl. member access like `Response.created`)
      resolves through the graph deterministically, independent of the editor workspace
      root. Keep `project_index` as the fast path; the graph is the source of truth for
      imported packages.

### F4 — cross-module sub-language expansion (R4)
- [ ] With F3 in place, the cross-module `erika` (or `html`) template fn resolves, so the
      LSP's template-eval compile expands `erika "…"` and `customAstFor(uri)` returns the
      `CustomNode` tree. Confirm `engine.customSemanticTokens` then paints
      `select`/`from`/`where`/`order by` as `keyword` and the field idents as `property`
      inside the string — the overlay code is unchanged; only the AST now exists.
- [ ] Confirm the same compile feeds the in-string diagnostics / hover / go-to-def paths
      (`definitionCustomRef`, `hoverCustomRef`) for a cross-module sub-language literal.

### F5 — capabilities + docs
- [ ] Document the project-graph compile and the local-scope binding model in
      `language-server/AGENTS.md` + `src/docs.md` (the dev loop section). No new LSP
      capability is advertised — these are corrections to existing providers.
- [ ] Snapshot tests under `snapshots/lsp/`: a decorator body (completion + def), a
      decorator-bearing record (completion), a `from "<lib>"` member def, and a
      cross-module `erika "…"` (semantic tokens).

## Test scenarios

```
[gap] lsp ---- decorator body: completion at the cursor lists `decl`, `args`, `f` (locals/params/closure binder)   (R1)
[gap] lsp ---- decorator body: go-to-def on `decl`/`args`/`f` jumps to its binding site in the same function        (R1)
[gap] lsp ---- a same-named top-level decl does NOT shadow the nearer enclosing local on go-to-def                  (R1)
[gap] lsp ---- `var`-declared local resolves on go-to-def (keyword set includes `var`)                              (R1)
[gap] lsp ---- a record carrying `#[service]` (emitting decorator): completion still lists its fields + imports     (R2)
[gap] infer -- a module whose decorators `@emit` returns non-empty `TypedBinding`s for its source decls            (R2)
[gap] comptime ---- `@emit` codegen / `botopink test` output is byte-identical after the early-return fix           (R2)
[gap] lsp ---- go-to-def on a `from "<lib>"` symbol resolves via the lib `botopink.json`, not the workspace root    (R3)
[gap] lsp ---- go-to-def on member access `Response.created` jumps to `pub fn created` in the lib                   (R3)
[gap] lsp ---- completion/hover work in a file importing across `mod` siblings + `from "<lib>"` + `from "std"`      (R3)
[gap] lsp ---- a keystroke re-infers only the active doc (graph cache hit on unchanged dependencies)                (R3)
[gap] lsp ---- cross-module `erika "select name from cities …"`: select/from/where/order → keyword, idents → property (R4)
[gap] lsp ---- a malformed cross-module `erika "…"` yields a diagnostic whose range is inside the string           (R4)
[have] lsp ---- a plain string with no sub-language stays opaque (no spurious tokens)                               (regression guard)
```

## Notes

- **Why isolation tests passed.** Every existing LSP test is a single self-contained
  document with module-level bindings — the exact shape that *doesn't* hit any of these
  bugs. F0 deliberately reproduces the real shapes first.
- **F2 is the cheapest, highest-leverage fix** (one early-return) and unblocks every
  example app that applies decorators. F1 unblocks every library body. F3 is the larger
  change and F4 falls out of it with no overlay-code change — the genericity that
  [`sublanguage-lsp`](../../v0.beta.10/specs/sublanguage-lsp.md) promised.
- **No core coupling.** The `infer.zig` change concerns *any* `@emit`ing decorator; it
  names no framework. Package resolution reuses the compiler's existing module-system
  machinery ([[project_v0beta11_module_system]], [[project_libs_module_migration_done]]).
- **Latency is the one real risk** — guard it with the per-document-version graph cache
  (F3). The Custom AST needs no extra evaluator pass beyond the compile that already runs.
