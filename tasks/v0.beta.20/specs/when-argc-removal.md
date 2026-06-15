# when-argc-removal — retire the `when(argc == N)` arity-branch grammar

**Slug**: when-argc-removal
**Depends on**: `fn-param-default-expansion` (F0+F3 — the surface
migrations that move every libs/std `when(argc == N)` usage to
default-value form); `external-target-libs-migration` (F4 — the lib
+ example sweep eliminates any third-party `when` usage).
**Files**:
- `modules/compiler-core/src/ast.zig` — delete `ArityBranch`,
  `parseArityBranchArg`, `externalHasArityBranches`,
  `externalArityBranchFor`.
- `modules/compiler-core/src/parser.zig` — delete the
  `when($argc == N): "..."` label parse path in `parseAnnotationCall`
  (~lines 686–716).
- `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,wat}.zig`
  — `PrimErlangCall` / `BuiltinNodeCall` / siblings drop the
  `arity_branches: ?[]ArityBranch` field; the `branches[]` collector
  loops in `collect…Dispatch` shrink to single-template form.
- `modules/compiler-core/src/comptime/primOpTemplate.zig` — the
  renderer is unchanged (it never knew about arity branches; they
  live one level up at dispatch).
- `libs/std/src/primitives.d.bp` — verify zero `when(argc ==` hits
  post-`fn-param-default-expansion`.
- `libs/std/AGENTS.md` — drop the §"Arity branching" section; keep the
  ~5-line reference pointing at `fn-param-default-expansion`.
**Touches docs**: `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` (drop the §"Arity
  branching" row in the `primOpTemplate.zig` row) · `CHANGELOG.md`.
**Status**: pending

## Background

`prim-op-annotation` added `when($argc == N): "<template>"` arity-branch
syntax (commit `59ab77f`) to express the `slice(start)` vs
`slice(start, end)` shape — at the time, fn-param defaults weren't
expanded at call sites, so the dispatch had to branch on `argc`.

`fn-param-default-expansion` retires the underlying need: every
arity-branched usage in `libs/std` migrates to a default-value param
(`end: i32 = self.length()` for slice, `message: string = "panic"`
for panic, etc.). Third-party libs migrate via
`external-target-libs-migration`.

Once both land, the `when(argc == N)` grammar is dead code. This spec
retires it from the parser + AST + dispatch tables in one focused
commit.

## Premise

After this spec lands:

- The `when($argc == N)` token sequence inside `#[@External.*(...)]`
  reds with a parse error (the parser no longer recognises `when` as
  an annotation arg keyword).
- The `ArityBranch` AST type + its readers (`parseArityBranchArg`,
  `externalHasArityBranches`, `externalArityBranchFor`) are deleted.
- Each codegen backend's dispatch entry struct
  (`PrimErlangCall` / `BuiltinNodeCall` / siblings) drops the
  `arity_branches` field; the dispatch loop reads a single template
  per `(callee, target)` pair.
- The single-arity-template surface is the only annotation grammar.

## Compiler path

### F0 — verify no surviving usage

- [ ] `git grep "when(argc ==" libs/ examples/ tests/` finds zero hits.
- [ ] `git grep "parseArityBranchArg" modules/compiler-core/src/` shows
      the readers are only consumed by codegen — no parser cross-ref
      remains besides the parser's own `parseAnnotationCall`.

### F1 — delete the parser path

- [ ] `parser.zig`: remove the `when(argc == N): "..."` branch in
      `parseAnnotationCall` (~lines 686–716). The annotation arg loop
      reverts to its pre-`59ab77f` shape: balanced parens, comma-
      separated, no special label-spanning logic.

### F2 — delete the AST readers

- [ ] `ast.zig`: delete `ArityBranch`, `parseArityBranchArg`,
      `externalHasArityBranches`, `externalArityBranchFor`. The
      remaining `externalRefFor` / `externalInlineFor` /
      `externalAnnotationTargetsExt` / `externalBodyArgsExt` are
      unaffected (they never knew about arity branches).

### F3 — collapse the dispatch tables

- [ ] `codegen/erlang.zig`: `PrimErlangCall` drops `arity_branches`;
      `collectPrimErlangDispatch` + `collectBuiltinErlangDispatch`
      stop iterating `parseArityBranchArg`; only the single-template
      collection path stays. `tryEmitPrimAnnotation` +
      `tryEmitBuiltinAnnotation` drop the `if (call.arity_branches.len
      > 0)` branch.
- [ ] `codegen/commonJS.zig`: same shape — `BuiltinNodeCall` drops
      `arity_branches`; the collector + dispatch shrink.
- [ ] `codegen/beam_asm.zig`: same.
- [ ] `codegen/wat.zig`: same.

### F4 — delete the inline-seeding test coverage

- [ ] `tests/comptime/primOpTemplate.zig`: delete the
      `parseArityBranchArg` test block.
- [ ] `tests/codegen/prim_op_templates.zig`: drop the `F1-arity` +
      `F3-RP2` scenarios; the RP2 diagnostic (no `when` clause
      matched) goes away with the grammar.

### F5 — docs

- [ ] `libs/std/AGENTS.md`: §"Arity branching" section becomes a
      ~5-line "deprecated since v0.beta.20 — use param defaults
      instead, see `fn-param-default-expansion`" pointer.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md`: drop the
      `Arity branching` subsection from the `primOpTemplate.zig` row.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `refactor(annotations): when($argc == N) arity-branch grammar
       retired; defaults are the unified arity-flexibility mechanism.`

## Test scenarios

```
F0       ---- post-`fn-param-default-expansion` + `external-target-libs-migration`, `git grep "when(argc ==" libs/ examples/ tests/` finds zero hits
F1-red   ---- `#[@External.Erlang(when(argc == 1): "x")]` reds with `parser: unexpected token "when"` after the parser path is gone
F2-build ---- `zig build` builds clean after the AST type is deleted (no dangling references)
F3-byte  ---- snapshot diffs across every backend empty against pre-F3 HEAD (every test scenario already migrated to single-template form by F0)
F4-clean ---- the deleted tests' siblings still pass; no orphan helper functions linger
F5-docs  ---- libs/std/AGENTS.md + comptime/AGENTS.md + CHANGELOG.md updated in the F3 commit
gate     ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

## Notes

- **Cross-spec interaction.** Strict dependency:
  `fn-param-default-expansion` + `external-target-libs-migration` MUST
  land first. If any in-tree `.bp` still uses `when(argc == N)`, the
  F1 parser deletion turns it into a build break. Pin landing order:
  `fn-param-default-expansion` → `external-target-libs-migration` →
  `when-argc-removal`.
- **What this spec is NOT.** Not a feature; pure code-deletion sweep
  (~300 lines net). The release notes call it out as the closure of
  the `prim-op-annotation` grammar cleanup.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
