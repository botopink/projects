# external-target-libs-migration — migrate libs to `@External.<Target>` and retire the legacy `@external` form

**Slug**: external-target-libs-migration
**Depends on**: `prim-op-annotation` commit `85b199d` (codegen recognises
`#[@External.<Target>(...)]`) + commit `5f0f1d9` (`libs/std/src/` and
`libs/server/src/` already migrated).
**Files**:
- `libs/onze/src/**/*.bp` · `libs/rakun/src/**/*.bp` ·
  `libs/erika/src/**/*.bp` · `libs/jhonstart/src/**/*.bp` — every
  `#[@external(target, ...)]` annotation migrates to
  `#[@External.<Target>("template")]`.
- `examples/**/*.bp` + `tests/**/*.bp` — same sweep over downstream test
  fixtures.
- `modules/compiler-core/src/ast.zig` — once every `.bp` file in the
  monorepo migrates, retire the legacy `fn external(target, mod, sym,
  inline: bool = false)` declaration in `builtins.d.bp` and remove the
  legacy branch in `externalAnnotationTargetsExt` / `externalBodyArgsExt`
  / `FnDecl.isExternal` / `InterfaceMethod.isExternal`.
- `modules/compiler-core/src/parser.zig` — no parser change needed (the
  qualified-path parsing already accepts `External.<Variant>`); the
  legacy `external` fn-annotation just falls out of test coverage.
**Touches docs**: `libs/std/AGENTS.md` (§"External annotation
  vocabulary") · per-lib AGENTS.md (onze/rakun/erika/jhonstart) ·
  `CHANGELOG.md`.
**Status**: pending

## Background

`prim-op-annotation` commit `85b199d` plumbed the `#[@External.<Target>(...)]`
annotation form through the codegen readers (`externalAnnotationTargetsExt`
+ `externalBodyArgsExt` + `FnDecl.isExternal` + `InterfaceMethod.isExternal`).
Commit `5f0f1d9` migrated `libs/std/src/` + `libs/server/src/` to the new
form. The other four libs in the monorepo (`libs/onze`, `libs/rakun`,
`libs/erika`, `libs/jhonstart`) still ship `#[@external(target, "mod",
"sym")]` annotations — both forms parse + dispatch identically today.

After every consumer in the monorepo migrates, the legacy `external`
fn-annotation can retire:
- The `fn external(target: Target, module: string, symbol: string,
  inline: bool = false)` decl in `libs/std/src/builtins.d.bp`.
- The "legacy 2-arg form" branches in
  `externalAnnotationTargetsExt` / `externalBodyArgsExt`.
- The "external" name match in `FnDecl.isExternal` /
  `InterfaceMethod.isExternal`.

This spec ships both halves: the sweep + the retirement.

## Premise

After this spec lands, the only host-backed lowering annotation in the
monorepo is `#[@External.<Target>("template")]`. The grammar surface
is the single typed-enum form documented in `builtins.d.bp`'s
`pub enum External implement Annotation`. Legacy support is removed.

## Target migration table

Mechanical sed-driven transform per file:

| Before | After |
|---|---|
| `@external(erlang, "mod", "sym")` | `@External.Erlang("mod", "sym")` |
| `@external(erlang, "$self.template")` | `@External.Erlang("$self.template")` |
| `@external(node, "mod", "sym")` | `@External.Node("mod", "sym")` |
| `@external(node, "sym")` (node-prototype shorthand) | `@External.Node("sym")` |
| `@external(beam, ...)` | `@External.Beam(...)` |
| `@external(wasm, ...)` | `@External.Wasm(...)` |
| `@external(typescript, ...)` | `@External.Typescript(...)` |
| `@external(target, ...)` with `inline: true` | `@External.<Target>(..., inline: true)` |

Same sweep works for both `#[@external(...)]` and bare
`#[external(...)]` (the `@`-less form fires inside `builtins.d.bp`'s
own decls, per the user's bare-name rule for self-refs).

## Compiler path

### F0 — migrate `libs/onze`

- [ ] `libs/onze/src/**/*.bp`: sed every `@external(target, ` to
      `@External.<Target>(`. Reconcile any `inline: true` flag
      positions.
- [ ] `libs/onze/AGENTS.md`: replace `@external` references with the
      new form.
- [ ] `botopink test` in `libs/onze/` stays green.

### F1 — migrate `libs/rakun`

- [ ] Same shape as F0. The `rakun` framework has server-side
      `@external(erlang, "node_http", ...)` style annotations; migrate
      each carefully (host symbol templates may carry `:` characters
      that read as namespace separators).

### F2 — migrate `libs/erika`

- [ ] Same shape as F0.

### F3 — migrate `libs/jhonstart`

- [ ] Same shape as F0. The jhonstart `html` DSL has its own
      `@[external]` legacy pattern (memory `feedback_external_annotation_form`):
      the migration ALSO normalises any surviving `@[external]` →
      `#[@External.<Target>]`.

### F4 — sweep `examples/` + `tests/`

- [ ] Same mechanical transform across `examples/**/*.bp` and
      `tests/**/*.bp`.

### F5 — retire the legacy form in the compiler

- [ ] `libs/std/src/builtins.d.bp`: delete the `fn external(target,
      module, symbol, inline: bool = false)` declaration (the typed-enum
      `pub enum External implement Annotation` form remains).
- [ ] `modules/compiler-core/src/ast.zig`:
      - `externalAnnotationTargetsExt`: drop the
        `std.mem.eql(u8, a.name, "external")` branch.
      - `externalBodyArgsExt`: same.
      - `FnDecl.isExternal`: drop the `"external"` match (keep the
        `externalVariantTarget` match).
      - `InterfaceMethod.isExternal`: same.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` §"§A5 external
      annotation surface": replace the dual-form description with the
      single `@External.<Target>` form.

### F6 — diagnostics for unknown variants

- [ ] `ast.externalVariantTarget` returns null for any unknown variant
      (already the case). Make a `parseAnnotationCall`-time diagnostic
      fire for `@External.Foo(...)` where `Foo` isn't one of
      `{ Erlang, Node, Beam, Wasm, Typescript, NodePrototype }`:
      diagnostic code `EX1` (`external-unknown-target`).
- [ ] Add tests covering EX1 + every known variant.

### F7 — docs

- [ ] `libs/std/AGENTS.md` §"External annotation vocabulary": single
      grammar; the dual-form table goes away.
- [ ] Each lib's AGENTS.md updated in the migration commit.
- [ ] `CHANGELOG.md`:
      `refactor(annotations): @External.<Target> is the only host-backed
       lowering annotation form; legacy @external() retired.`

## Test scenarios

```
F0–F3      ---- every `botopink test` per migrated lib stays green; snapshot diffs empty
F4         ---- examples + tests sweep doesn't break any backend's example runner
F5         ---- post-F5 `git grep '@external(' libs/ modules/ examples/ tests/` finds zero hits outside comments
F5-empty   ---- post-F5 `git grep '"external"' modules/compiler-core/src/ast.zig` (case-sensitive) finds zero hits in the annotation-reading helpers
F6-EX1     ---- `@External.UnknownTarget("x")` reds with external-unknown-target
F7-docs    ---- AGENTS.md + CHANGELOG.md updated in the F5 commit
gate       ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

## Notes

- **Cross-spec interaction.** Completes the migration started by
  `prim-op-annotation` commit `5f0f1d9` for the rest of the monorepo,
  closing the back-compat shim explicitly kept "so external callers
  (libs/onze, libs/rakun, libs/erika, libs/jhonstart) can migrate at
  their own pace" (see `5f0f1d9`'s commit message).
- **Coordinate with lib maintainers.** Each lib has its own task track
  in the meta repo. This spec assumes all four lib worktrees can land
  the per-lib F0–F3 hunks in parallel + the meta F5 retire commit
  bumps every submodule's tip in one go.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
