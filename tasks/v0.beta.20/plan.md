# v0.beta.20 — plan (reasoning scratchpad)

Mutable. The *why* behind v0.beta.20's shape and the trade-offs each frente
chose. Authored intent lives in `specs/`; this file is the thinking around
them.

## Premise

v0.beta.20 carries a **dual mandate**:

1. **Closing.** Every deferral the v0.beta.19 closing wave recorded —
   frente-a §A7/§B/§C/§D2-D5/§G2, frente-b F4F/F4G/F4C/F4I/F5/F6 + §T,
   prim-op-annotation Family 1 BEAM/wat + Family 2/3 across 4 backends,
   std-expansion-tail 9 phases + 14 sub-deferrals, ci-pipelines-green
   2 deferreds + transitional shims. v19 was supposed to be the closing
   wave; in practice it merged a strong partial across each frente
   plus the standalone tracks (frente-c, recursive-test-gate, ci-
   pipelines-green YAML scope). v20 is the *true* closing wave for v19.
2. **Opening.** The ecosystem-expansion line, with one keystone
   (`emilia`). The language is done after v20 closes the v19 deferrals;
   the ecosystem on top of it is just beginning.

Both mandates ride the same set: 29 specs, 6 frentes, one closing
batch label.

## What this set is NOT

- **Not a new language wave** — but **one targeted language extension**
  (`enum-sections`) lands here. Lifted from v0.beta.21 during the emilia
  design session: emilia's token surface (`.Color.Red.500`,
  `.Pad.X.4`, `.Text.Size.X3xl`) needs nested enum grouping with
  path access + numeric variant leaves; without it the surface is
  `Token.Color(TokenColor.Red(_500))` — unusable in practice. Every
  other spec either *deletes* surface (`when($argc==N)`,
  `emitResultOptionOp`, `emitPrimMethod`, the legacy
  `@external(target,…)` form) or consumes existing AST nodes
  (`Param.default` slot, `Jump.@"break".label` field — both
  authored in v19).
- **Not a v19 redo.** v19's merged work stays merged. v20 closes
  the *deferred* rows, not the merged ones.
- **Not a bpmp / distribution change.** ci-tail is workflow-YAML only;
  emilia rides the existing `bpmp install <lib>` path; module-auto-tag
  ran in v19 §J and is immutable.
- **Not a CSS engine.** emilia v1 ships a flat declaration list per
  class — no nesting, no media queries, no preprocessor pipeline
  (those are v21+ candidates).
- **Not the place for effect composition** (`#[@result]
  #[@asyncGenerator]` etc.). That hook is recorded in v19 frente-b
  §3 and will get its own spec when scoped.

## Big decisions

### D1. Six frentes instead of three

v0.beta.19 used three frentes (compiler / rules+tooling / distribution)
because its 7 specs naturally clustered into three file-disjoint
directory groups. v20 has 29 specs that touch many more sub-areas:
prim-op grammar extension lives next to codegen but is conceptually
its own surface (annotation language); std-tail is libs-only and
file-disjoint from compiler-core; ci-tail is workflow-YAML; ecosystem
is its own sibling repo.

Six frentes is the smallest grouping that keeps each frente
file-disjoint AND coherent in mandate:

- **frente-a-tail** — closes the compiler-core deferrals (10 specs,
  internal DAG through `generic-inference-foundation` keystone).
- **prim-op-extension** — extends the annotation grammar + retires
  hardcoded switch arms across 4 backends (9 specs, internal DAG
  through Family 2 → Family 1).
- **std-tail** — libs/std/ tail (2 specs, parallel).
- **frente-b-tail** — rules+tooling close (3 specs, mostly parallel).
- **ci-tail** — workflow YAML + snap normalisation (4 specs, near
  parallel).
- **ecosystem** — sibling repo only (1 spec, no compiler change).

### D2. `generic-inference-foundation` is the v20 keystone

§B was deferred in v19 because the inferencer work is *deep* — it
touches `comptime/{infer,unify,types}.zig` plus the call-site tagging
that other v20 specs (`primitive-interface-default-fns`,
`typed-method-dispatch`) consume. Putting it first inside
frente-a-tail gives the rest of the frente a stable foundation. The
spec deliberately ends with **only** the foundation (Self primitive
kind resolution + generic var instantiation tagging); the *consumers*
of the tag are separate specs, each independently testable.

This mirrors v19's decision (Frente A §A first → §B/§C/§D consume).

### D3. prim-op-extension's Family 2 lands before Family 1 on BEAM+wat

Family 2 (`@Result`/`@Option` ops) and Family 1 (primitive methods)
both need a `tryEmitBuiltinAnnotation`-shape dispatch infrastructure on
BEAM + wat. v19 landed it on erlang + commonJS via Family 2 there.
Mirroring the order on BEAM + wat reuses the same shape: Family 2
authors the infra (`registerInlineBuiltinBeamDispatch` /
`registerInlineBuiltinWatDispatch`); Family 1 plugs into it.

### D4. `when($argc==N)` is retired, not extended

The grammar was authored in `prim-op-annotation` as a stopgap for
multi-arity host symbols. Once `fn-param-default-expansion` lands the
unified call-site default injection, every `when($argc==N)` use case
collapses to a default-value form. Retiring the grammar is a hard
delete (memory: same discipline as v19 §S `*fn`).

Counter-argument: an out-of-tree user might author `when($argc==N)`.
Response: it was authored in v19 prim-op-annotation; an out-of-tree
user is already living with v0.beta.13–.19 of breaking changes. The
migration is mechanical (move the arity check to a default-value).

### D5. `@external(target,…)` → `@External.<Target>(...)` is org-wide

`prim-op-annotation` shipped the new form (commit `85b199d` — codegen
recognises `@External.<Target>(...)`) and migrated `libs/std` +
`libs/server`. v20 finishes the sweep across every sibling lib
(`onze`, `rakun`, `erika`, `jhonstart`) + every `examples/**/*.bp` +
`tests/**/*.bp` + retires the legacy declaration from `builtins.d.bp`
+ the legacy AST path.

This is the *only* spec in v20 that touches multiple sibling repos.
The cross-repo nature is intentional: a partial migration leaves a
mixed surface that confuses readers. One spec, one sweep, one
retirement commit per repo.

### D6. wasm-test-runner is its own spec (not folded into wat-refactor)

`wat-refactor` authors the wasm aggregate types + the value-tracking
classifier (the "what does this register hold" pass). That's a
backend-emitter change. `wasm-test-runner` is a CLI change
(`compiler-cli/src/cli/test_cmd.zig` accepts `--target wasm`) plus a
test-mode emission (`__bp_run_tests` entry). Splitting them keeps each
spec single-mandate.

### D7. emilia rides the **opener** of v20, alongside the closing frentes

emilia is independent of every other v20 spec at the source level
(its own sibling repo + 1 minimal carrier in jhonstart). It rides
v20's opening batch because:

1. The language work it consumes (template fns + `@ExprCustom` +
   `package-default-dsl`) is all on `feat` post-v19.
2. Pre-authoring emilia + the language closings in the same batch
   demonstrates the *third sub-language* on top of a *closed*
   language, in one set. v21 then opens with a clean ecosystem-only
   slate.

### D8. CI-tail closes the v19 ci-pipelines-green deferreds *and* drops its shims

v19 ci-pipelines-green merged the YAML scope across 7 repos + 12
uncovered follow-up layers — including diagnostic shims and
`ERL_AFLAGS` envs that were transitional. `ci-pipelines-green-tail`
drops those. The backends-parity erlang + windows specs delete the
`allow_fail` rows v19 added to keep CI green over the deferred reds.

This is the cleanest possible close: every v19 ci-pipelines-green
row that's "done with transitional shim" or "deferred + allow_fail"
gets retired in v20.

### D9. `frente-a-tail` as an umbrella spec, not deleted

Even though the 9 concrete specs above close §A7/§B/§C/§D3-D5/§G2
individually, the umbrella spec carries the *audit + close-out*
checklist — re-grepping `frente-a-compiler.md`'s "deferred" markers,
verifying each Remaining-gaps row narrows, running the cross-backend
snapshot diff. It's the v19 closing-wave receipt; without it, "did
we close everything?" is an unanswered question.

Same reasoning applies to `prim-op-annotation-tail` (umbrella for the
Family 1/2/3 + instance-methods landings) and
`std-expansion-tail-followup` (umbrella for the 9 phases + 14
sub-deferrals).

### D10. Six worktrees instead of one

Each frente has its own worktree under `.tasks/<frente>/`. The
internal DAG inside each frente is small (≤3 levels); the cross-
frente coordination is *zero* (six file-disjoint directory groups).
Six worktrees is the smallest count that lets every frente progress
in parallel without merge contention.

Single-worktree alternative was rejected: it serialises the work and
re-introduces the merge-contention the v19 three-frente split
deliberately avoided.

## Risk surface

| Risk | Mitigation |
|---|---|
| `generic-inference-foundation` keystone reshapes `comptime/infer.zig` in a way `primitive-interface-default-fns` / `typed-method-dispatch` weren't ready for | Keystone authored with the consumer signature in mind (see the spec's "Files" list — both consumers are named); the keystone's gate is "every existing inline test still passes after the re-fold". |
| Family 2 BEAM dispatch infra differs subtly from erlang's, breaking Family 1 BEAM after it | Family 2 spec mandates `tryEmitBuiltinAnnotation`-shape parity (same signature as erlang); Family 1 BEAM tests round-trip against the existing erlang snapshots — divergence surfaces in the diff. |
| `when($argc==N)` retirement misses an in-tree caller (parser still accepts but no consumer remains, or vice versa) | `when-argc-removal` F0 gate: `rtk proxy grep -rn 'when(\$argc' repository/` returns empty before the parser path deletion lands. |
| `external-target-libs-migration` corrupts a lib's `feat` head when migrating multiple `@external` annotations | One PR per sibling, smoke `botopink test` after each PR before the next. Same discipline as v19 frente-c §I. |
| wat-refactor's value-tracking classifier mis-classifies a fixture's register usage → wasm-test-runner fails on that fixture | F1 of wat-refactor lands a per-fixture audit. wasm-test-runner depends on wat-refactor (recorded in the spec's Depends-on); ordering enforces the dependency. |
| `rules-tooling-close` F4I codegen wrap reintroduces a `break :label` red on commonJS that v19 already fixed | `codegen-break-label` is the v20 spec that *replaces* the v19 naive lowering on all 4 backends; rules-tooling-close consumes the v20 emitter, not the v19 one. |
| `emilia` `Stylesheet` host cell leaks classes across SSR requests | spec's F4 gate: two consecutive renders produce two independent `<style>` blocks (explicit in-file test). Per-request `flush()` is the contract. |
| Six worktrees diverge on a shared file (e.g., `codegen/AGENTS.md`) | frentes are file-disjoint *by directory*. The one shared sink is `codegen/AGENTS.md` (touched by `frente-a-tail` + `prim-op-extension` + `ci-tail`). Resolution rule: each landing rewrites only its own "Remaining gaps" row; cross-row conflicts are mechanical to resolve. |

## Order of work — recommended

Six worktrees in parallel; weave the work as follows:

**frente-a-tail worktree** (`.tasks/frente-a-tail/`):
1. `generic-inference-foundation` (keystone first — others consume the tagging).
2. `primitive-interface-default-fns` + `typed-method-dispatch` (parallel after keystone).
3. `wat-refactor` ─▶ `wasm-test-runner` (sequential — runner consumes encoder).
4. `beam-inline-prim-methods` + `erika-runtime-string` + `future-runtime-erlang-beam` (parallel any time).
5. `cross-backend-snapshots-sweep` (after every track above).
6. `frente-a-tail` umbrella audit (close-out — receipt commit).

**prim-op-extension worktree** (`.tasks/prim-op-extension/`):
1. `family-2-beam-wat-runtime-ops` (authors the BEAM+wat dispatch infra).
2. `family-1-beam-wat-prim-methods` + `family-3-block-builtin` (parallel after Family 2 dispatch).
3. `prim-op-template-instance-methods` (parallel — adds instance method template).
4. `prim-op-annotation-tail` (§A2 BEAM+wat user-template — after Family 1/2/3).
5. `external-target-libs-migration` + `fn-param-default-expansion` (parallel — pure lib sweep + comptime/transform extension).
6. `when-argc-removal` (after every consumer has migrated).
7. `agents-md-resync` (close-out — receipt commit).

**std-tail worktree** (`.tasks/std-tail/`):
1. `std-expansion-tail-followup` (9 phases, F1..F9 chained internally).
2. `option-expect` (independent any time).

**frente-b-tail worktree** (`.tasks/frente-b-tail/`):
1. `rules-tooling-close` (F4F/F4G/F4C/F4I/F5/F6).
2. `codegen-break-label` (after F4I-T2/T3 transform rewrite lands).
3. `test-run-log` (independent any time).

**ci-tail worktree** (`.tasks/ci-tail/`):
1. `ci-pipelines-green-tail` (drop shims first).
2. `backends-parity-erlang` + `backends-parity-windows` + `test-libs-consolidation` (parallel after shims dropped).

**ecosystem worktree** (`.tasks/emilia/`):
1. F0 — lib stand-up + jhonstart `attr(EmiliaClass)` carrier.
2. F1 — `css """…"""` template fn.
3. F2 — `tw "…"` template fn.
4. F3 — `styled.<tag>` namespace.
5. F4 — `Stylesheet` host cell + `emilia.flush()`.
6. F5 — runnable `examples/emilia-card/` + docs.

## What's deliberately deferred to v0.beta.21+

- **emilia: nested selectors / media queries / animations** — recorded
  in the emilia spec Notes.
- **emilia: erlang/beam host port** — Stylesheet host cell ports
  structurally identical; gated on rakun's erlang-server port.
- **Effect composition** (`#[@result] #[@asyncGenerator]` etc.) —
  recorded in v19 frente-b §3.
- **bpmp registry / index server** — recorded in v18 `bpmp.md` non-goals.
- **Multi-package workspaces** — recorded in v18 README non-goals.
- **wasm cross-module linking** — recorded in v19 frente-a §C5;
  v20 `wat-refactor` only does single-module aggregates.
- **Composing `#[@future]` with `#[@result]`** for fallible futures —
  v19 frente-b Rules §1F noted the boundary; not in v20.
- **`#[@context]` runtime reflection on `any`-typed rejection payloads** —
  v19 frente-b Rules §1G hint.
- **Ecosystem libs beyond emilia** (realtime / ORM / content-collections
  / test reporter) — listed in v20 README "Roadmap candidates";
  each will scope its own spec when ready.

## Per-memory reminders applicable to v20 work

- All commits in English; conversation here in pt-br
  (`feedback_pt_br_conversation`).
- AGENTS.md updated in the same commit as the code it documents
  (`feedback_agents_md_maintenance`).
- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit during execution; `rtk git` / `rtk proxy`
  for filtered output (`reference_rtk_filters_git_diff`).
- Pre-commit gate (zig fmt + build + test) on every commit; **no
  `--no-verify`** ever; the v19 `recursive-test-gate` runs every
  sibling's gate too.
- Functions in camelCase (`feedback_camelcase_naming`).
- Implement in `.bp` when possible; `.d.bp` only for markers / FFI
  (`feedback_prefer_bp_over_dbp`).
- After commit, advance to the next checkbox
  (`feedback_continue_after_commit`).
- End-of-session sweep across the 7 remotes (meta + 6 submodules —
  now **7** with emilia) for any drifted `feat` heads
  (`feedback_feat_remotes_unified`).
- Eric works in parallel — re-check `git status` immediately before
  every commit/merge (`feedback_user_works_in_parallel`).
