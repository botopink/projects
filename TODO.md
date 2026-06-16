# TODO — snap-audit

> Worktree task: **meta-audit every `*.snap.md` in the workspace** —
> RUN LOG coverage, legacy-surface conformity, value cross-check,
> gap fixtures. Spec:
> [`tasks/v0.beta.20/specs/snap-audit.md`](../../tasks/v0.beta.20/specs/snap-audit.md).
>
> Read-mostly + reroute: F0 builds the audit tool; F1/F2 rewrite
> sources and regenerate; F3 cross-checks values; F4 conjectures ≤10
> gap fixtures (each registered under its owning frente, not here).
> Discovered gaps land in this spec's `## Findings` table pointing at
> the owning frente (frente-a-03-closeout / prim-op-annotation-tail /
> ci-tail-02-backends-parity / std-tail-followup), never at new specs.
>
> Branch: `task/snap-audit`. Lands BEFORE `frente-a-03-closeout`.

## F0 — audit tooling (read-only)

- [ ] **F0.0 — baseline snapshot of the corpus**
  - [ ] `rtk proxy find ./repository -name '*.snap.md' -not -path '*/.git/*' | wc -l` to confirm the ~2 077 file count from the spec premise.
  - [ ] Per-suite counts (parser / comptime / codegen / lsp / errors) match the spec's `## Premise` table; record any drift in commit body.
- [ ] **F0.1 — author `scripts/snap_audit.sh`**
  - [ ] Single entry; subcommands `--mode={runlog,legacy,values,coverage}`.
  - [ ] Pure shell (`awk` + `grep` + `find`). Read-only — zero writes outside `build/snap-audit/`.
  - [ ] `--mode=runlog`: classify each codegen snap `(a)` / `(b)` / `(c)` by parsing SOURCE CODE block; columns `backend\tlabel\tactual-runlog-state\tpath`.
  - [ ] `--mode=legacy`: grep each SOURCE CODE block for the legacy surface list (§F2); columns `surface\tcount\tpath`.
  - [ ] `--mode=values`: dump `(suite, backend, source-hash, runlog-text)` for non-empty (b) snaps.
  - [ ] `--mode=coverage`: pivot runlog by backend × label; emit the table from spec `## Premise`.
- [ ] **F0.2 — register entry**
  - [ ] Update `repository/botopink-lang/scripts/AGENTS.md` with the new entry.
- [ ] **F0.3 — pin baseline numbers**
  - [ ] Update `tasks/v0.beta.20/status.md` `snap-audit` row with the F0 baseline (80% empty, 17%+23%+60% split).
- [ ] **F0.4 — commit**: `feat(snap-audit): scripts/snap_audit.sh — 4-mode read-only audit`.

## F1 — promote `(a) → (b)` where the observable form is mechanical

- [ ] **F1.0 — dry-run** `scripts/snap_audit.sh --mode=runlog > build/snap-audit/runlog.tsv`; pick the `(a)` candidate set.
- [ ] **F1.1 — declaration-style snaps**: every snap whose source is a single `val` / `fn` decl with a representable result. Wrap in `fn main() { … @print(…); }`.
  - **Hard rule**: keep the original decl shape intact. The `@print` call is *added*, not substituted.
- [ ] **F1.2 — regen across 4 backends**: `UPDATE_SNAPS=1 zig build test` from `repository/botopink-lang/`.
- [ ] **F1.3 — per-backend RUN LOG audit**: any backend whose RUN LOG stays empty after the rewrite → finding for F4 + row in this spec's `## Findings`.
- [ ] **F1.4 — commit per source rewrite campaign**: bundle the 4-backend regens; commit subject identifies the rewrite category (e.g., `snaps(codegen): promote array-literal fixtures (a)→(b)`).
- [ ] **F1.5 — measure**: re-run `--mode=coverage`; empty-share must drop from 80% baseline to ≤55%.

## F2 — legacy surface sweep across every suite

- [ ] **F2.0 — run** `scripts/snap_audit.sh --mode=legacy > build/snap-audit/legacy.tsv`.
- [ ] **F2.1 — `*fn `** prefix (removed in v0.beta.19 §S). Zero hits expected — gate-evidence regression check.
- [ ] **F2.2 — `#[@external(<target>, "…")]`** legacy form. Rewrite to `#[@External.<Target>("…")]` (memory `feedback_external_annotation_form`); regen across 4 backends; emitted output must stay byte-identical.
- [ ] **F2.3 — `@[external]` / `@[<annotation>]`** outside `#[…]`. Same rewrite shape.
- [ ] **F2.4 — `when($argc == N)`** literals. Track count for `prim-op-extension when-argc-removal`'s gate-evidence.
- [ ] **F2.5 — `string.length()` inside `@code` template bodies** and `value:length()` in erlang templates (memory `reference_bp_parser_comptime_gotchas` #11).
- [ ] **F2.6 — top-level `(expr).method()`** in `@code` (memory `reference_bp_parser_comptime_gotchas` #12).
- [ ] **F2.7 — deprecated builtins** (grep for any builtin name *not* present in `libs/std/src/builtins.d.bp`).
- [ ] **F2.8 — comptime + parser + LSP snaps** — same legacy sweep, no RUN LOG involvement; the regen rewrites the TYPED-AST / parser-JSON / LSP-output section automatically.
- [ ] **F2.9 — commit per surface** (one commit per `F2.N` row that produces source changes); subject `snaps(codegen): retire <surface>`.

## F3 — value correctness cross-check

- [ ] **F3.0 — run** `scripts/snap_audit.sh --mode=values > build/snap-audit/values.tsv`.
- [ ] **F3.1 — authoritative external diff**: for every `(b)` snap with non-empty RUN LOG, invoke the runner outside the test harness:
  - [ ] `node`: `node <emitted>.js` from a scratch dir.
  - [ ] `erlang`: `erlc + erl -noshell -s main main -s init stop`.
  - [ ] `beam`: `erlc +from_asm <emitted>.S; erl -noshell -s main main`.
  - [ ] `wasm`: `wasmtime <compiled>.wasm` (memory `project_v0beta19_ci_pipelines_green`).
- [ ] **F3.2 — classify diffs**: `equal` / `equal-modulo-trailing-newline` / `different`. Each `different` → finding in this spec's `## Findings` table pointing at the owning frente.
- [ ] **F3.3 — cross-backend parity**: backend-agnostic fixtures must match byte-for-byte across the 4 backends. Real divergences pin with `// per-backend: …` source comment; bugs → finding under the owning backend.
- [ ] **F3.4 — commit per finding category**.

## F4 — conjecture new scenarios

- [ ] **F4.0 — gather**: read this spec's `## Findings` table + F1/F2/F3 outputs; pick ≤10 categories.
- [ ] **F4.1 — author** the minimal new fixtures (single observable, single backend assertion). Candidates from the spec:
  - [ ] `@print` of a record with nested arrays.
  - [ ] `@print` of an enum payload variant.
  - [ ] `@print` inside a `fn main()` called from a generic-module inline test (`comptime/infer.zig` STD-001 path).
  - [ ] `@assert` with a string message + array equality.
  - [ ] Cross-module `@print` from a `mod` sibling (gated on frente-a §D3 lowering).
  - [ ] `@print` inside a `comptime { … }` block whose value is a runtime fold (prim-op Family 3 `@block`).
- [ ] **F4.2 — register**: each new snap registers under the *owning* spec's test-scenarios block, not under this spec.
- [ ] **F4.3 — commit per fixture batch**.

## F5 — docs + closeout

- [ ] **F5.0 — author** `modules/compiler-core/snapshots/AGENTS.md` (new) — RUN LOG contract: when `(a)` / `(b)` / `(c)` apply; the framework-side runtime hook path.
- [ ] **F5.1 — update** `modules/compiler-core/src/codegen/AGENTS.md` — per-backend RUN LOG coverage row derived from this audit.
- [ ] **F5.2 — populate** `tasks/v0.beta.20/specs/snap-audit.md` `## Findings` table with every residual + owning frente.
- [ ] **F5.3 — flip** `tasks/v0.beta.20/status.md` `snap-audit` row → **done**.
- [ ] **F5.4 — CHANGELOG entry**.

## Exit gate (mirrors spec `## Exit gate`)

- [ ] F0 tooling lands; 4 modes runnable on a clean `feat`.
- [ ] F1 empty-share ≤55% codegen-wide.
- [ ] F2 zero hits across every legacy-surface row.
- [ ] F3 every non-empty RUN LOG passes the authoritative external diff; cross-backend parity holds (or pins divergence with comment).
- [ ] F4 ≤10 new fixtures; each registered under an owning spec.
- [ ] `## Findings` table populated; every row points at an existing v0.beta.20 frente.
- [ ] `snapshots/AGENTS.md` documents the RUN LOG contract.
- [ ] `tasks/v0.beta.20/status.md` row → **done**.

## Discipline (memory anchors)

- All commits in English; conversation in pt-br (`feedback_pt_br_conversation`, `feedback_everything_english`).
- AGENTS.md updated in the same commit as the code it documents (`feedback_agents_md_maintenance`).
- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit during execution; `rtk git` / `rtk proxy` for filtered output (`reference_rtk_filters_git_diff`).
- Pre-commit gate (zig fmt + build + test) on every commit; **no `--no-verify`** ever (`project_worktree_workflow`).
- Functions in camelCase (`feedback_camelcase_naming`).
- After commit, advance to the next checkbox (`feedback_continue_after_commit`).
- Eric works in parallel — re-check `git status` immediately before every commit/merge (`feedback_user_works_in_parallel`).
- End-of-session sweep across the 7 remotes (meta + 6 submodules) for any drifted `feat` heads (`feedback_feat_remotes_unified`).
