# Front 07 — comptime-dedup

**Status:** not started. Carried whole from 1.0.2-beta front 10.

**Priority:** medium — nothing is wrong at run time, but every comptime snapshot change costs four
files, and the typed-AST renderer hides what the checker does behind `?` and `"id": 0`
**Depends on:** [`../06-checker/`](../06-checker/README.md) landed. Both re-record
`snapshots/comptime/**`, the directory this front restructures, so they never run together
([`../fronts.md`](../fronts.md#conflict-matrix)). Either order would work; this milestone runs the
checker first so its row counts and migration plan are not invalidated mid-front, and accepts that
the checker pays four copies per regeneration. `BOTOPINK_SNAP_TRACE` (landed with 1.0.2-beta
review-tooling) is how step 1 proves no path was orphaned. Must not run beside
[`../08-review-backlog/`](../08-review-backlog/README.md)'s comptime wave (same `comptime/tests/**`)
**Owns:** `src/comptime/snapshot.zig` · `src/comptime/tests/helpers.zig` · `snapshots/comptime/**`
(layout; it deletes 3 of 4 copies) · `src/comptime/tests/AGENTS.md` and the `snapshots/` tree in
`modules/compiler-core/AGENTS.md`
**Does not touch:** `src/comptime/infer.zig`, `src/comptime/types.zig`, `src/comptime/env.zig`
([`../06-checker/`](../06-checker/README.md)) — the renderer reads inference, it does not change it
· `src/comptime.zig` (the `type_ids` map, see step 3 — read-only here) · `src/utils/snap.zig`,
`scripts/snap_audit.sh`, the rest of `src/comptime/tests/**`
([`../08-review-backlog/`](../08-review-backlog/README.md)) · `src/codegen/**`

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` was measured
2026-09-16 at the 1.0.2-beta commit; re-measure the counts after the checker lands — it moves them.

---

## Problem

**Four byte-identical copies.** Every typed-AST comptime test writes the same snapshot four times,
and every type-error test twice:

```
$ for d in node erlang beam wasm; do find snapshots/comptime/$d -type f | wc -l; done
305        # 199 AST + 106 errors/
305        # 199 AST + 106 errors/
199
199
$ find snapshots/comptime -type f | wc -l
1009       # + templates/fail_span_in_template.snap.md
```

A one-line renderer or checker change re-records up to 4 × 199 files, and a reviewer reads each
diff four times.

**A renderer that cannot show what it claims to.** `TYPED AST JSON` prints `?` for 78 types per
directory and `"id": 0` for all 69 record/enum ids, omits interfaces' members, enum variants,
methods and `implement` blocks, and shows fn bodies as raw source. Two different functions produce
the `?`, and only one of them is the checker's tripwire — see [Mechanism](#mechanism).

## Current state

| | Count (per directory) | How measured |
|---|---|---|
| comptime snapshot files | 1009 total: `node` 305 · `erlang` 305 · `beam` 199 · `wasm` 199 · `templates` 1 | `rtk proxy find snapshots/comptime/<d> -type f \| wc -l` |
| unique paths | 306 — 199 AST slugs + 106 error slugs + 1 template | the `node` tree plus `templates/` |
| byte-identical copies | **703 of 703** comparisons equal (`node` vs `erlang`/`beam`/`wasm` for AST, `node/errors` vs `erlang/errors`); no file exists in a sibling that is absent from `node` | `cmp` over the `node` listing |
| distinct contents | 300 — six pairs of error snapshots written by **different** tests are byte-identical (`1g_rg3_*` ≡ `rg3_*` ×3, `1f_rf5_let_binding…` ≡ `rf5_let_binding…`, `e_inside_future…` ≡ `rf2_throw…`, `rf1_return_future…` ≡ `t_inside_future…`) | `md5sum` |
| `?` in `TYPED AST JSON` | 78 in 51 files: 52 from `typeNameFromTypeRef`, 26 (17 files) from `typeNameOf` | JSON parse + field attribution, [`renderer.md`](./renderer.md) |
| `"id": 0` | 69 in 63 files; 0 non-zero ids anywhere | `grep -o` |

The six content-identical pairs are review `duplicate` rows (tests that assert the same thing), not
copies; deduplicating paths does not touch them — they are
[`../08-review-backlog/backlog.md`](../08-review-backlog/backlog.md) rows.

## Mechanism

**Copies.** `assertComptimeAstExpecting` (`src/comptime/tests/helpers.zig:117-186`) compiles once and
loops `const runtime_dirs = [_][]const u8{ "node", "erlang", "wasm", "beam" }` (`:132`), calling
`snapshot.assertComptimeAstWithPath` with `comptime/<rt>/<slug>` for each (`:151-157`). The comment
at `:126-131` gives the reason: the four-runtime architecture collapsed, the AST snapshot never
included the per-runtime script, and the layout was kept "to avoid 4 × N stale-file churn".
`assertTypeErrorSnap` (`:224-260`) does the same with `{ "node", "erlang" }` (`:254-259`) — which is
why `beam`/`wasm` have no `errors/`.

`src/comptime/snapshot.zig:1060-1070` already has an `assertComptimeAst` that writes one copy to
`comptime/ast/<slug>`. It has **no callers** — every test calls the `helpers.zig` wrapper of the
same name.

**Renderer.** Summary; the full attribution, per-field counts and the 17 slugs are in
[`renderer.md`](./renderer.md).

- `typeNameFromTypeRef` (`src/comptime/snapshot.zig:239-244`) renders an **annotation**: anything
  but `.named` is `?`. It never consults inference — **it does not move when the checker becomes
  strict.** 52 `?`s (28 fn returns, 22 fn params, 2 record fields).
- `typeNameOf` (`src/comptime/snapshot.zig:478`, `?` at `:512`) renders an **inferred** type and
  prints `?` for a type variable. **This is the real tripwire**: the 26 `?`s in 17 slugs are the
  checker saying it does not know. It is also too coarse — it prints `?` for a `.generic` variable
  (a correct polymorphic answer) exactly as for an `.unbound` one (a failure).
- `"id": 0`: `resolveTypeId` (`snapshot.zig:225-230`) looks the type's name up in a map keyed by
  the declared name (`src/comptime.zig:1276-1279`), but a record's type name is the structural
  string `buildRecordDeclName` builds (`src/comptime/infer.zig:474`, `:1760`), so the lookup always
  misses and `orelse 0` (`snapshot.zig:446`, `:457`) wins. The id is already on the binding as
  `TypedBinding.typeId` (`infer.zig:46`).
- Missing kinds: `bindingToRepr` (`snapshot.zig:369-473`) renders interfaces as name + generics
  only, records without methods, enums without variants, and `implement` blocks not at all; fn
  bodies are raw source lines (`extractFnBody`, `:246-257`).

## Steps

### Step 1 — One comptime snapshot per test

Record each snapshot once under a backend-independent path.

| | Layout | Trade-off |
|---|---|---|
| A | `snapshots/comptime/<slug>.snap.md`, `snapshots/comptime/errors/<slug>.snap.md`, `templates/` | Flattest; mixes AST files with the two subdirectories |
| B | `snapshots/comptime/ast/<slug>.snap.md`, `snapshots/comptime/errors/<slug>.snap.md`, `templates/` | Three siblings named by what they hold; `ast/` is the path `snapshot.zig:1065` already names |
| C | keep `node/` and `node/errors/`, delete the rest | Smallest diff; keeps a backend name that no longer means anything |

**Recommended: B.** In `helpers.zig`, replace the `runtime_dirs` loop (`:132`, `:151-157`) with one
call to the existing `snapshot.assertComptimeAst` (`snapshot.zig:1060`), and the `runtimes` loop in
`assertTypeErrorSnap` (`:254-259`) with one `checkText` to `comptime/errors/<slug>`; delete the
comment at `:126-131`. Move `node/<slug>` → `ast/<slug>` and `node/errors/<slug>` → `errors/<slug>`
with `git mv` so history follows, then delete `erlang/`, `beam/`, `wasm/`. `templates/` is unchanged
(`src/comptime/tests/templates.zig:218` writes it directly).

Do this as a **pure move**: no renderer change in the same commit, so the content set is provably
unchanged.

**Acceptance:**
- [ ] `find snapshots/comptime -name '*.snap.md' | wc -l` → **306** (199 + 106 + 1), not 1009
- [ ] The set of `md5sum`s over `snapshots/comptime` is the same 300 hashes before and after
- [ ] `zig build test` green without `BOTOPINK_SNAP_CREATE`, 0 `.snap.md.new` on disk
- [ ] A `BOTOPINK_SNAP_TRACE` run ([`../08-review-backlog/`](../08-review-backlog/README.md) step 1)
      lists no `comptime/node|erlang|beam|wasm/` path and no orphan
- [ ] `src/comptime/tests/AGENTS.md` and the `snapshots/` tree in `modules/compiler-core/AGENTS.md`
      (`:22`, today `beam/, erlang/, node/, templates/, wasm/`) name the new layout, and state the
      mapping from the old paths the 1.0.1-beta reports cite (`SN/…` = `comptime/node/…`)

### Step 2 — Render inferred types, and keep the tripwire visible

Render every type in `TYPED AST JSON` from inference, and make an unresolved one unmistakable.

1. `fn_def` params and return type: from the binding's `.func` type (`b.type_`, params in
   `T.Type.func.params`) through `typeNameOf`, not from `typeNameFromTypeRef`. Delete
   `typeNameFromTypeRef` once nothing calls it (`record_def` fields move the same way, from the
   registered type def).
2. `typeNameOf` `.typeVar` (`:512`): split the states — `.generic` renders as the type parameter's
   name (or a stable `'a`, `'b` by first appearance), `.unbound` keeps `?`. **Do not** map `.unbound`
   to anything that reads as a resolved type: it is the only place a snapshot shows the checker
   punting.
3. `.func` (`:511`): render `fn(<params>) -> <ret>`, not the return type alone.

Expect the `?` count to **change shape, not just drop**: the 52 syntactic `?`s go, and an
unannotated param that inference leaves unbound becomes a new, meaningful `?`.

**Acceptance:**
- [ ] No `"?"` in a snapshot for a type inference resolved; every remaining `?` is an `.unbound`
      variable (checked by a test in `snapshot.zig` over a generic fn and a resolved fn)
- [ ] The 17 tripwire slugs in [`renderer.md`](./renderer.md) still show `?` until
      [`../06-checker/`](../06-checker/README.md) resolves them — this front does not make them green
- [ ] The re-recorded snapshots reviewed, not blanket-accepted: each file's diff is only type text

### Step 3 — `"id"`, missing declaration kinds, cosmetics

1. **`"id"`.** Two options:

   | | Change | Trade-off |
   |---|---|---|
   | A | Render `b.typeId` directly in `bindingToRepr` (the binding is in hand at `:369`), and delete `resolveTypeId` and the `type_ids` map use | Real ids — but a monotonic counter over the whole env, so any type added upstream of a test (a `libs/std` record, a prelude change) shifts every id after it and re-records every snapshot that has one |
   | B | Drop `"id"` from `record_def` / `enum_def` | 63 files change once; no snapshot ever moves for an id again. Nothing in the tree reads the field |

   **Recommended: B**, unless a consumer of the id is found; A turns every `libs/std` edit into
   comptime re-records.
   Either way the `type_ids` plumbing in `src/comptime.zig:1276-1279`, `:1455-1458` becomes dead;
   removing it is a `src/comptime.zig` edit — hand it to
   [`../05-cli-residuals/`](../05-cli-residuals/README.md), which owns that file, rather than editing
   it here (or, if that front has closed, claim the deletion here and say so).
2. **Missing kinds.** Serialise interface member signatures, record and enum methods, enum variants
   with payload types, and `implement` blocks (as their own entry or on the implementing type).
3. **Cosmetics.** Rename `"indent"` → `"ident"` (`:60`, `:120`; 102 files per directory before
   step 1) in the same re-record as step 2, so the files move once.

Leave fn bodies as source lines: a typed body renderer is a larger change than this front, and the
checker front already asserts bodies through annotated top-level `val`s and error snapshots.

**Acceptance:**
- [ ] No `"id": 0` placeholder in any snapshot (field removed, or a real id)
- [ ] Interfaces, implements, methods and variants appear in `TYPED AST JSON`
- [ ] Error snapshots (`comptime/errors/`) byte-identical across steps 2–3 — the diagnostic
      renderers (`renderTypeErrorBody`, `:573`) are not touched

## Gate

- [ ] `zig build test` from a **cold** runtime cache (`modules/compiler-core/.botopinkbuild/runtime-cache`
      deleted), green in this front's worktree
- [ ] Step 1 lands byte-identical by content (same 300 hashes); steps 2–3 re-record only
      `snapshots/comptime/ast/`
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/comptime-dedup`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Files.** Step 1: 1009 → 306 (703 deletions, 305 renames). Steps 2–3: nearly every AST snapshot —
  141 of the 199 contain a `fn_def`, `record_def`, `enum_def`, `interface_def` or an `"id"`, and 102
  carry `"indent"`. The 106 error snapshots and `templates/` do not move.
- **Other fronts.** [`../06-checker/`](../06-checker/README.md) sizes its rows in `?` counts and
  "68 files across the four dirs"
  ([`rows.md`](../06-checker/rows.md), [`blast-radius.md`](../06-checker/blast-radius.md)); after
  step 1 those are 17 files, after step 2 the syntactic `?`s its counts exclude are gone. Its
  counts must be re-measured, not scaled. [`../09-hygiene/`](../09-hygiene/README.md)'s
  5.13 fixture rewrite (`src/comptime/tests/infer_decls.zig:518`) re-records one comptime snapshot in
  this directory — sequence it.
- **Tooling.** `scripts/snap_audit.sh` scans `snapshots/comptime` recursively (`:62`); its `legacy`
  mode counts each comptime hit four times today and once after step 1. No script or workflow names
  a per-backend comptime path.
- **The 1.0.1-beta reports** cite `snapshots/comptime/node/…` (`SN/…`) throughout. They are the audit
  record and are not edited; the path mapping in `src/comptime/tests/AGENTS.md` is how a reader
  follows them.

## Notes

- The copies were kept on purpose (`helpers.zig:126-131`) to avoid churn during the runtime
  collapse. That reason is spent: every renderer or checker fix now pays the churn four times.
- Step 1 before step 2, in separate commits: a move proven by hash equality, then a re-record
  reviewed as type text only. Merging them would make a 1009-file diff unreviewable.
- The six content-identical error pairs are test duplicates, not copies — owned by the review
  backlog, not by the layout.
- `"id": 0` is not a checker defect: the ids are allocated and stored; only the renderer's lookup key
  is wrong.
