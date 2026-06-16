# agents-md-resync — refresh AGENTS.md across the v0.beta.19 surface changes

**Slug**: agents-md-resync
**Depends on**: `prim-op-annotation` (every commit landed) +
`fn-param-default-expansion` (F0–F3) + the four other v0.beta.20
specs (`family-1-beam-wat-prim-methods` /
`family-2-beam-wat-runtime-ops` / `family-3-block-builtin` /
`external-target-libs-migration` / `when-argc-removal`) — sweeps
documentation **after** the code lands so the surface is consistent.
**Files**:
- `modules/compiler-core/AGENTS.md` ·
  `modules/compiler-core/src/parser/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/codegen/tests/AGENTS.md` ·
  `modules/compiler-core/snapshots/codegen/AGENTS.md` ·
  `modules/compiler-core/snapshots/comptime/AGENTS.md` ·
  `modules/language-server/AGENTS.md` ·
  `libs/std/AGENTS.md` ·
  `libs/std/src/AGENTS.md` ·
  `libs/{onze,rakun,erika,jhonstart,server}/AGENTS.md` ·
  per-lib `src/AGENTS.md` files where applicable ·
  `tasks/v0.beta.19/status.md` + `tasks/v0.beta.20/status.md` (rollups).
**Touches docs**: every AGENTS.md in the monorepo (sweep) ·
  `CHANGELOG.md` (single rollup line).
**Status**: pending

## Background

The v0.beta.19 wave (`prim-op-annotation` + neighbours) and the
v0.beta.20 follow-ups (`fn-param-default-expansion` and the four sister
specs) move several surfaces:

- `@external(target, ...)` retires; `@External.<Target>("template")` is
  the only host-backed lowering annotation form.
- `when($argc == N)` retires; defaults at every call surface are the
  unified arity-flexibility mechanism.
- `$stringify(...)` + arbitrary inner expression + arity-branch +
  triple-quoted form survive in the template grammar.
- Every backend's `emitPrimMethod` / `emitResultOptionOp` switch shrinks
  to the annotation-driven path.
- `builtins.d.bp` splits into a decl-only fn block + an interface block;
  `registerStdlib` reads both.
- `Param.default: ?Expr` + `EnumVariantField.default: ?Expr` are the
  unified default-value AST slot.
- `expandTrailingDefaults` is the unified call-site default injection
  point.
- New diagnostics D1–D6 + EX1 + RP7 land.

Each of these surfaces is documented in **multiple** AGENTS.md files
across the monorepo (compiler-core's per-subdir + libs/std + the
per-lib AGENTS.md). Per the memory rule (`feedback_agents_md_maintenance`:
"Toda mudança de código/layout exige atualizar o AGENTS.md correspondente
no mesmo commit"), each landing spec touches its own AGENTS.md inline —
but a sweep pass at the end catches any cross-references that drift
across spec boundaries.

This spec is that sweep — pure documentation, **no code changes**.

## Premise

After this spec lands, every AGENTS.md in the monorepo reflects the
state of the code on its branch. Stale references to retired surfaces
(`when($argc ==)`, `@external(target, ...)`, `emitResultOptionOp`,
`emitPrimMethod` switch arms) are gone. New surfaces are documented in
the file that owns them; cross-references between AGENTS.md files point
at the right anchors.

## Compiler path

### F0 — monorepo-wide stale-reference grep

Run these greps and reconcile each hit:

```bash
git grep -nE '@external\(' -- '*.md'
git grep -nE 'when\(\$?argc' -- '*.md'
git grep -nE 'emitResultOptionOp' -- '*.md'
git grep -nE 'emitPrimMethod' -- '*.md'
git grep -nE 'arity_branches' -- '*.md'
git grep -nE 'ArityBranch' -- '*.md'
git grep -nE 'defaultVal' -- '*.md'
```

Each hit is either:
- (a) **historical reference** — keep, add a `// retired in v0.beta.20`
  marker pointing at the relevant spec.
- (b) **stale instruction** — rewrite to point at the new surface.

### F1 — per-file refresh checklist

Touch each AGENTS.md and verify the on-disk content matches the code
state after every v0.beta.19 + v0.beta.20 spec lands:

- [ ] `modules/compiler-core/AGENTS.md` — top-level §"`comptime/`",
      §"`codegen/`", §"`parser/`" subsections call out the new shape.
- [ ] `modules/compiler-core/src/parser/AGENTS.md` — `parseParam`
      reads `= <expr>` default; `parseAnnotationCall` no longer reads
      `when(...)` labels; `parseEnumBody` reads variant-field defaults.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md` —
      `primOpTemplate.zig` row drops the §"Arity branching" subsection;
      `transform.zig` row gains the `expandTrailingDefaults` line;
      diagnostics list reflects D1–D6 + EX1 + RP7.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — §"§A6 closure"
      no longer carries the "irreducible allow-list" (every arm
      migrated); §"Annotation-driven lowering" lists every backend's
      consumer + dispatch table; the per-target `$stringify` expansion
      table sits here.
- [ ] `modules/compiler-core/src/codegen/tests/AGENTS.md` — new
      `prim_op_templates.zig` + `fn_param_defaults.zig` test banks
      noted.
- [ ] `modules/compiler-core/snapshots/codegen/AGENTS.md` +
      `…/comptime/AGENTS.md` — folder structure unchanged, but any
      "expected output shape" prose reflects the new templates.
- [ ] `modules/language-server/AGENTS.md` — the LSP completion snapshot
      reflects `@External.<Target>(...)` form; nothing else changes.
- [ ] `libs/std/AGENTS.md` — §"External annotation vocabulary" carries
      the single typed-enum form; §"Template grammar" carries the
      marker table + arity-branch deprecation note pointing at
      `fn-param-default-expansion`; §"Default values in fn-decl param
      lists" is a new section.
- [ ] `libs/std/src/AGENTS.md` — per-module surface description (math,
      random, time, querystring, asserts, path, url) reflects the
      annotation form actually shipping.
- [ ] `libs/{onze,rakun,erika,jhonstart,server}/AGENTS.md` — the
      per-lib section that quotes its own `#[@external(...)]` examples
      moves to `#[@External.<Target>(...)]`.
- [ ] `libs/{onze,rakun,erika,jhonstart}/src/AGENTS.md` — same shape,
      where the per-src-tree AGENTS.md carries lib-internal annotation
      examples.

### F2 — meta-root TODO + status

- [ ] `tasks/v0.beta.19/status.md` — close out the
      `prim-op-annotation` row; add receipts for the eight commits
      (`72e17e9` … `5f0f1d9`).
- [ ] `tasks/v0.beta.20/status.md` (new) — rollup of the five
      v0.beta.20 specs (`fn-param-default-expansion` /
      `family-1-beam-wat-prim-methods` / `family-2-beam-wat-runtime-ops`
      / `family-3-block-builtin` / `external-target-libs-migration` /
      `when-argc-removal` / `agents-md-resync` itself).
- [ ] `tasks/v0.beta.20/specs/index.md` — one-line pointer per spec.
- [ ] Meta-root `TODO.md` flips the pending v0.beta.19 row to done
      and adds a v0.beta.20 row pointing at `tasks/v0.beta.20/status.md`.

### F3 — cross-reference invariant

- [ ] `scripts/check-md-links.sh` (new — if not already in tree from
      `recursive-test-gate`): walks every AGENTS.md, follows relative
      links, reds on any broken link. The test gate runs it.
- [ ] Run it; reconcile.

### F4 — final invariant assertion

- [ ] `git grep -nE 'when\(\$?argc'` returns hits **only** in this
      spec's "deprecated since v0.beta.20" prose blocks.
- [ ] `git grep -nE '@external\(' -- '*.md'` returns hits **only** in
      historical-reference contexts.
- [ ] `CHANGELOG.md` under v0.beta.20:
      `docs: AGENTS.md sweep — v0.beta.19 + v0.beta.20 surfaces
       reflected across the monorepo.`

## Test scenarios

```
F0-grep   ---- every stale-reference grep returns the expected reconciled set
F1-cover  ---- every AGENTS.md in the listed table is touched in this spec's commit
F2-status ---- v0.beta.20/status.md + meta TODO.md flip green
F3-links  ---- `scripts/check-md-links.sh` reds zero
F4-clean  ---- the final invariant grep set returns the expected residue (only historical refs)
gate      ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green (no code touched)
```

## Notes

- **Cross-spec interaction.** This spec depends on every prior
  v0.beta.19 + v0.beta.20 spec landing first. Authoring it before code
  lands is fine (so the spec exists as a placeholder + checklist);
  executing it before code lands risks "documents the future" which
  drifts back to stale on every re-merge.
- **No code changes.** Pure docs sweep. The gate runs to verify the
  monorepo still builds, not to validate any new behaviour.
- **Per-memory:** SSH for git remote ops; commit messages in English;
  this spec's commit message lists every AGENTS.md it touches in the
  trailing "Co-touched files" block.
