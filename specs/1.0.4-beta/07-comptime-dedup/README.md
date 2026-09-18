# Front 07 — comptime-dedup

**Not started. It moves whole to 1.0.5-beta `06-comptime-dedup`.** Nothing of it landed in
1.0.4-beta; what this directory keeps is the **measurement** — the file counts, the hash survey and
the renderer attribution — which is the record the next front is sized against, and
[`renderer.md`](./renderer.md), which holds the per-field attribution and the 17 tripwire slugs.

It would have owned `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` and the *layout* of
`snapshots/comptime/**`. It never ran because it shares that directory with the checker, which
re-records it: the milestone ran the checker first so its row counts and migration plan were not
invalidated mid-front, and accepted that the checker pays four copies per regeneration.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` was
measured 2026-09-16 at the 1.0.2-beta commit; the checker has moved them since — re-measure before
quoting.

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

A one-line renderer or checker change re-records up to 4 × 199 files, and a reviewer reads each diff
four times.

**A renderer that cannot show what it claims to.** `TYPED AST JSON` prints `?` for 78 types per
directory and `"id": 0` for all 69 record/enum ids, omits interfaces' members, enum variants, methods
and `implement` blocks, and shows fn bodies as raw source. Two different functions produce the `?`,
and only one of them is the checker's tripwire — see [Mechanism](#mechanism).

## Measurements

| | Count (per directory) | How measured |
|---|---|---|
| comptime snapshot files | 1009 total: `node` 305 · `erlang` 305 · `beam` 199 · `wasm` 199 · `templates` 1 | `rtk proxy find snapshots/comptime/<d> -type f \| wc -l` |
| unique paths | 306 — 199 AST slugs + 106 error slugs + 1 template | the `node` tree plus `templates/` |
| byte-identical copies | **703 of 703** comparisons equal (`node` vs `erlang`/`beam`/`wasm` for AST, `node/errors` vs `erlang/errors`); no file exists in a sibling that is absent from `node` | `cmp` over the `node` listing |
| distinct contents | 300 — six pairs of error snapshots written by **different** tests are byte-identical | `md5sum` |
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
`assertTypeErrorSnap` (`:224-260`) does the same with `{ "node", "erlang" }` — which is why
`beam`/`wasm` have no `errors/`. `src/comptime/snapshot.zig:1060-1070` already has an
`assertComptimeAst` that writes **one** copy to `comptime/ast/<slug>`, and it has no callers.

**Renderer.** Summary; the full attribution and the 17 slugs are in [`renderer.md`](./renderer.md).

- `typeNameFromTypeRef` (`snapshot.zig:239-244`) renders an **annotation**: anything but `.named` is
  `?`. It never consults inference — **it does not move when the checker becomes strict.** 52 `?`s
  (28 fn returns, 22 fn params, 2 record fields).
- `typeNameOf` (`snapshot.zig:478`, `?` at `:512`) renders an **inferred** type and prints `?` for a
  type variable. **This is the real tripwire**: the 26 `?`s in 17 slugs are the checker saying it
  does not know. It is also too coarse — it prints `?` for a `.generic` variable (a correct
  polymorphic answer) exactly as for an `.unbound` one (a failure).
- `"id": 0`: `resolveTypeId` (`snapshot.zig:225-230`) looks the type's name up in a map keyed by the
  declared name (`src/comptime.zig:1276-1279`), but a record's type name is the structural string
  `buildRecordDeclName` builds, so the lookup always misses and `orelse 0` wins. The id is already on
  the binding as `TypedBinding.typeId` (`infer.zig:46`). **Not a checker defect**: the ids are
  allocated and stored; only the renderer's lookup key is wrong.
- Missing kinds: `bindingToRepr` (`snapshot.zig:369-473`) renders interfaces as name + generics only,
  records without methods, enums without variants, and `implement` blocks not at all; fn bodies are
  raw source lines.

## What it left, and where

**All of it**, to 1.0.5-beta `06-comptime-dedup`, in the three pieces the analysis cut it into:

1. **One comptime snapshot per test.** Of the three layouts considered, the recommendation is **B** —
   `snapshots/comptime/{ast,errors,templates}/` — because `ast/` is the path `snapshot.zig:1065`
   already names and the three siblings are named by what they hold. It lands as a **pure move**
   (`git mv`, no renderer change in the same commit), provable by hash equality: the same 300 hashes
   before and after, 1009 files → 306.
2. **Render inferred types, and keep the tripwire visible.** Types in `TYPED AST JSON` come from
   inference, not from syntax; `typeNameOf`'s `.typeVar` splits so `.generic` renders as the type
   parameter's name and only `.unbound` keeps `?`. Expect the `?` count to change shape, not just
   drop.
3. **`"id"`, the missing declaration kinds, and the `"indent"`→`"ident"` typo.** The recommendation
   is to **drop** `"id"` rather than render a real one: a monotonic counter over the whole env means
   any type added upstream of a test re-records every snapshot after it. Nothing in the tree reads
   the field. Fn bodies stay as source lines.

Two dependencies to carry with it:

- **It must not run beside the checker or the review backlog.** The checker re-records
  `snapshots/comptime/**` and the review backlog owns the rest of `comptime/tests/**`. Its step 2 is
  also what turns many of the backlog's `weak` rows into `ok` or into a real `wrong-output` with no
  test change — so the backlog's wave B waits for it.
- **The checker's counts are stated in this layout.** [`../06-checker/rows.md`](../06-checker/rows.md)
  and [`blast-radius.md`](../06-checker/blast-radius.md) size rows in `?` counts and "68 files across
  the four dirs"; after step 1 that is 17 files, and after step 2 the syntactic `?`s those counts
  exclude are gone. They must be re-measured, not scaled.
- **The 1.0.1-beta reports cite `snapshots/comptime/node/…` (`SN/…`) throughout.** They are the audit
  record and are not edited; the path mapping belongs in `src/comptime/tests/AGENTS.md`.
