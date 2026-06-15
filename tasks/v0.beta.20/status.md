# v0.beta.20 — closing the prim-op-annotation deferred items + finishing the monorepo migration

This wave closes the items recorded as deferred at the end of
v0.beta.19's `prim-op-annotation` (see commit `5f0f1d9`'s message) and
finishes the migration of the rest of the monorepo to the
`@External.<Target>` form. Six specs, file-disjoint, sequenced by the
dependency chain in §"Landing order" below.

## Specs

| Slug | Spec | Status |
|---|---|---|
| `fn-param-default-expansion` | [`specs/fn-param-default-expansion.md`](specs/fn-param-default-expansion.md) | pending |
| `family-1-beam-wat-prim-methods` | [`specs/family-1-beam-wat-prim-methods.md`](specs/family-1-beam-wat-prim-methods.md) | pending |
| `family-2-beam-wat-runtime-ops` | [`specs/family-2-beam-wat-runtime-ops.md`](specs/family-2-beam-wat-runtime-ops.md) | pending |
| `family-3-block-builtin` | [`specs/family-3-block-builtin.md`](specs/family-3-block-builtin.md) | pending |
| `external-target-libs-migration` | [`specs/external-target-libs-migration.md`](specs/external-target-libs-migration.md) | pending |
| `when-argc-removal` | [`specs/when-argc-removal.md`](specs/when-argc-removal.md) | pending |
| `agents-md-resync` | [`specs/agents-md-resync.md`](specs/agents-md-resync.md) | pending |

## Premise

Three big stories thread through the wave:

1. **Defaults are the unified arity-flexibility mechanism.** After
   `fn-param-default-expansion` lands, `when($argc == N)` retires from
   libs/std; after `when-argc-removal` lands, the grammar itself is
   gone. The same `Param.default: ?Expr` slot serves fn calls,
   annotations, record constructors, and enum-variant constructors —
   Kotlin parity.

2. **Every backend's primitive-method + runtime-op + builtin dispatch
   is annotation-driven end-to-end.** The §A6 closure "irreducible
   allow-list" from `prim-op-annotation` retires: BEAM bytecode templates
   + wat instruction templates + the `@ExternalProperty.<Target>` form
   (for `val length` on Array + String) close every gap.

3. **`@External.<Target>("template")` is the only host-backed lowering
   annotation form.** Legacy `@external(target, ...)` retires.
   `external-target-libs-migration` sweeps `libs/{onze,rakun,erika,
   jhonstart}` + `examples/` + `tests/` + retires the parser+AST
   helpers.

## Landing order (strict)

The dependency chain is linear; specs must merge in this order:

```
fn-param-default-expansion       ─┐
                                  ├─→ family-3-block-builtin      ─┐
external-target-libs-migration   ─┤                                 │
                                  └─→ when-argc-removal             ├─→ agents-md-resync
family-2-beam-wat-runtime-ops    ──→ family-1-beam-wat-prim-methods ┘
```

- `fn-param-default-expansion` lands first — `family-3-block-builtin`
  needs the `builtins_fns.d.bp` split for the `fn block<T>` row;
  `when-argc-removal` needs every `when` usage migrated away first.
- `external-target-libs-migration` runs in parallel — it touches only
  per-lib `.bp` files; both can merge to feat without ordering risk.
- `family-2-beam-wat-runtime-ops` lands before `family-1-beam-wat-prim-methods`
  so BEAM + wat already have `tryEmitBuiltinAnnotation`-shape infra
  to reuse.
- `when-argc-removal` lands **after** every `when` consumer migrates
  (so the parser deletion doesn't break builds).
- `agents-md-resync` lands last — it sweeps stale references after
  every code change settles.

## Test gate

The wave's done-gate runs on every merge:

```
zig build test            ── core unit tests green
zig build test-libs       ── every lib's .bp test suite green on every backend
zig build test-backends   ── beam/wasm/erlang execution parity green
botopink-lib-test         ── meta-level integration green
scripts/check-md-links.sh ── AGENTS.md cross-refs reconciled (from `agents-md-resync` F3)
```

## Cross-wave receipts (v0.beta.19 → v0.beta.20)

The items deferred at v0.beta.19's `prim-op-annotation` closure
(commit `5f0f1d9`'s "Deferreds intentionally left in place" block) all
map to v0.beta.20 specs:

- `when(argc == N): "..."` arity-branch syntax for Array.slice +
  String.slice → resolved by `fn-param-default-expansion` §F1+§F3, then
  the grammar retires via `when-argc-removal`.
- `todo`/`panic` inline-seeded dispatch shipping two arity branches →
  resolved by `fn-param-default-expansion` §F0+§F3.
- BEAM + wat Family 2 (`@Result`/`@Option` runtime ops) → resolved by
  `family-2-beam-wat-runtime-ops`.
- BEAM + wat Family 1 (primitive-method lowering on bytecode/wasm) →
  resolved by `family-1-beam-wat-prim-methods`.
- `@block` annotation-driven on every backend → resolved by
  `family-3-block-builtin`.
- The §A6 closure "irreducible allow-list" → fully retired by
  `family-1-beam-wat-prim-methods` §F5.

## Notes

- **Spec authoring sources.** Five of seven specs trace directly to
  the "Deferreds intentionally left in place" block in
  `prim-op-annotation` commit `5f0f1d9`'s message. The other two
  (`external-target-libs-migration` + `agents-md-resync`) trace to the
  back-compat shim explicitly kept "so external callers can migrate at
  their own pace" + the AGENTS.md sync invariant from
  `feedback_agents_md_maintenance`.
- **Per-memory.** Per `feedback_feat_remotes_unified`: every spec
  closure bumps the meta + 6 submodules' `feat` tips in a single sweep
  commit. Per `feedback_always_update_remote_feat_submodules`: fetch +
  pull `feat` in each submodule before each spec's first commit (Eric
  works in parallel).
