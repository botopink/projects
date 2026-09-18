# Front 06 — comptime-dedup

**Priority:** high — not because anything is wrong at run time, but because of **what it costs every
other front**: every comptime snapshot is written four times, and [`01-checker`](../01-checker/README.md)
re-records that directory in bulk. Paid before the checker runs, it is a one-time 741-file deletion;
paid after, every checker commit carries four copies of each change.
**Depends on:** nothing. **It runs first, before [`01-checker`](../01-checker/README.md)** — see
[Why this front runs before the checker](#why-this-front-runs-before-the-checker), which step 1's
measurement is required to restate at the front's own HEAD.
**Owns:** `src/comptime/snapshot.zig` · `src/comptime/tests/helpers.zig` · `snapshots/comptime/**`
(layout — it deletes 3 of 4 copies per slug) · `src/comptime/tests/AGENTS.md` and the `snapshots/`
tree in `modules/compiler-core/AGENTS.md`
**Does not touch:** `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` and
`src/parser/**` ([`01-checker`](../01-checker/README.md)) — the renderer reads inference, it does not
change it · `src/comptime.zig` (the `type_ids` map, step 3 — read-only here) · `src/utils/snap.zig`,
`scripts/snap_audit.sh` and the rest of `src/comptime/tests/**`
([`07-review-backlog`](../07-review-backlog/README.md)) · `src/codegen/**` (fronts 02–05)

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every count and `file:line`
below was measured at `botopink-lang` `c2dd780` (2026-09-18) unless a row says otherwise.

---

## Problem

**Four byte-identical copies per slug.** Every typed-AST comptime test writes the same snapshot four
times, and every type-error test twice:

```
$ for d in node erlang beam wasm; do find snapshots/comptime/$d -type f | wc -l; done
337   # 202 AST + 135 errors/
337   # 202 AST + 135 errors/
202
202
$ find snapshots/comptime -type f | wc -l
1079  # + templates/fail_span_in_template.snap.md
```

**1079 files carry 338 unique paths and 332 distinct contents.** A one-line renderer or checker
change re-records up to 4 × 202 files, and a reviewer reads each diff four times.

**A renderer that cannot show what it claims to.** `TYPED AST JSON` prints `?` for 69 types per
AST directory and `"id": 0` for all 71 record/enum ids, omits behavior members, enum variants,
methods and `implement` blocks, and shows fn bodies as raw source. Two different functions produce
the `?` and only one of them is the checker's tripwire — see [Mechanism](#mechanism).

## Current state

Measured at `c2dd780`; every command is runnable from `modules/compiler-core/`.

| | Value | How measured |
|---|---|---|
| comptime snapshot files | **1079**: `node` 337 · `erlang` 337 · `beam` 202 · `wasm` 202 · `templates` 1 | `rtk proxy find snapshots/comptime/<d> -type f \| wc -l` |
| unique paths | **338** — 202 AST slugs + 135 error slugs + 1 template | the `node` tree (202 at depth 1, 135 under `errors/`) plus `templates/` |
| byte-identical copies | **741 of 741** comparisons equal (`node` AST vs `erlang`/`beam`/`wasm`; `node/errors` vs `erlang/errors`); no file exists in a sibling that is absent from `node` | byte compare over the `node` listing |
| distinct contents | **332** — six pairs written by **different** tests are byte-identical | md5 over the 338 unique paths |
| `?` in `TYPED AST JSON` | **69** per AST directory, in 43 files: **57 syntactic** (`typeNameFromTypeRef`: 31 fn returns + 24 fn params + 2 record fields) and **12 inferred** (`typeNameOf`: 6 `val` + 6 `call` return types) in **6** files | JSON parse of every `node` snapshot, each `?` attributed to the `ast` node and key that produced it |
| `?` outside the JSON | 1 — a `_ -> "?";` inside a raw fn body source line (`pub_fn_using_enum_case_in_body.snap.md:15`) | `grep -o '"?"'` reports 70, the JSON walk 69 |
| `"id": 0` | **71** in 65 files; **0** non-zero ids anywhere | `grep -o '"id": 0'` / `grep -oE '"id": [1-9][0-9]*'` |
| `"indent"` (the misspelling of `"ident"`) | **102** files per AST directory | `grep -l '"indent"'` |

The six content-identical pairs are review `duplicate` rows (tests that assert the same thing), not
layout copies; deduplicating paths does not touch them. They are
[`07-review-backlog`](../07-review-backlog/README.md)'s:

| A | B |
|---|---|
| `rg3_future_rejects_t_is_required` | `1g_rg3_future_rejects_t_is_required` |
| `rg3_iterator_rejects_t_is_required` | `1g_rg3_iterator_rejects_t_is_required` |
| `rg3_result_i32_rejects_e_is_required_no_default` | `1g_rg3_result_i32_rejects_e_is_required_no_default` |
| `rf1_return_future_resolved_inside_future_reds_future_return_must_be_bare_t` | `t_inside_future_reds_future_return_must_be_bare_t` |
| `rf2_throw_future_rejected_inside_future_reds_future_throw_must_be_bare_e` | `e_inside_future_reds_future_throw_must_be_bare_e` |
| `1f_rf5_let_binding_future_resolved_inside_future_reds_future_manual_construction_forbidden` | `rf5_let_binding_future_resolved_inside_future_reds_future_manual_construction_forbidden` |

### What moved since 1.0.4-beta

The 1.0.4-beta document was written against 1009 files / 306 unique paths / 78 rendered `?` in
51 files / 69 `"id": 0`. The suite grew (1079 / 338) and **the tripwire set shrank from 17 slugs to
6**: the ten `case` slugs and `multi_module_extension_activated_via_star_import`'s AST `?` closed
with the checker work that landed between `26d4fdc` and `c2dd780` (`d0c27f6` grammar, `174e0e4` N24,
`75a6906` C9, `f6d8ce6` C3). The surviving six are the method/extension-dispatch and `@makeRecord`
groups:

| Group | Slugs (each carries one `val.return_type` and one `call.return_type` `?`) |
|---|---|
| method / extension dispatch (4) | `local_extension_method_resolves_without_activation`, `multi_module_extension_activated_via_star_import`, `multi_module_local_extension_resolves_on_an_imported_record`, `qualified_extension_call_needs_no_activation` |
| `@makeRecord` (2) | `single_field_returns_record_type`, `multiple_fields_returns_record_type` |

**Do not `grep '"?"'` to size a row** — 57 of the 69 come from a function that never consults
inference and cannot move when the checker becomes strict.

## Why this front runs before the checker

1.0.4-beta ordered this front *after* its checker, accepting that the checker "pays four copies per
regeneration". Measured, that acceptance is expensive and the ordering is now reversed.

Between `26d4fdc` and `c2dd780` — the checker work that has already landed — **113** compiler-core
snapshots were re-recorded. Of those, **48 are comptime files carrying only 16 unique slugs**:

```
$ git diff --name-only 26d4fdc c2dd780 -- 'modules/compiler-core/snapshots/**' | wc -l
113
$ … | sed 's|.*/snapshots/||;s|/[^/]*$||' | sort | uniq -c
   8 comptime/beam      8 comptime/erlang      8 comptime/erlang/errors
   8 comptime/node      8 comptime/node/errors  8 comptime/wasm
  …
```

8 AST slugs cost 32 files and 8 error slugs cost 16 — **3.0× the files for the same review**. That is
one partial checker front. [`01-checker`](../01-checker/README.md) folds the whole of inference and
will re-record a large fraction of the 202 AST slugs; at 4× that is a four-figure diff nobody reviews.

The counter-argument 1.0.4-beta gave — that running the checker first keeps this front's row counts
and migration plan valid — does not apply: this front's plan is a path move plus a renderer change,
and neither is sized by what the checker resolves. The one thing the checker *does* invalidate is the
tripwire slug list above, which is why step 2's acceptance names the list by identity ("every
remaining `?` is `.unbound`"), not by count.

**Step 1's first act is to re-measure the two numbers in this section at the front's own HEAD** and
write them into this README, so the ordering argument is evidence and not a quotation.

## Mechanism

**Copies.** `assertComptimeAstExpecting` (`src/comptime/tests/helpers.zig`) compiles once and loops
`const runtime_dirs = [_][]const u8{ "node", "erlang", "wasm", "beam" }` (`:134`), calling
`snapshot.assertComptimeAstWithPath` with `comptime/<rt>/<slug>` for each (`:153-156`). The comment at
`:129-133` gives the reason: the four-runtime architecture collapsed, the AST snapshot never included
the per-runtime script, and the layout was kept "to avoid 4 × N stale-file churn".
`assertTypeErrorSnap` does the same with `const runtimes = [_][]const u8{ "node", "erlang" }`
(`:257-258`) — which is why `beam`/`wasm` have no `errors/`.

`src/comptime/snapshot.zig:1059` already has an `assertComptimeAst` that writes one copy to
`comptime/ast/<slug>` (`:1064`). It has **no callers** — every test calls the `helpers.zig` wrapper of
the same name.

**Renderer.**

- `typeNameFromTypeRef` (`snapshot.zig:239-244`) renders an **annotation**: `.named` passes, anything
  else is `"?"`. It never consults inference — **it does not move when the checker becomes strict.**
  It fills `fn_def` params and `return_type` (`bindingToRepr`'s `.@"fn"` arm) and `record_def` field
  values (its `.type_` arm). 57 of the 69 `?`.
- `typeNameOf` (`snapshot.zig:477`, the `?` in its `.typeVar` arm) renders an **inferred** `*T.Type`
  and prints `?` for a type variable. **This is the tripwire**: the 12 `?` in 6 slugs are the checker
  saying it does not know. It is also too coarse — `T.TypeVar` has three states and `deref` removes
  only `.link`; both `.unbound` (a failure) and `.generic` (a correct polymorphic answer) print `?`.
- `typeNameOf`'s `.func` arm renders the return type alone, so a `val` bound to a function looks like
  a value of its return type.
- `"id": 0`: `resolveTypeId` (`snapshot.zig:225-230`) looks the type's name up in a map keyed by the
  **declared** name (`src/comptime.zig:1311-1313`, again at `:1490-1492`), but a type's binding type
  is `env.namedType(buildRecordDeclName(env, r))` and `buildRecordDeclName`
  (`src/comptime/infer.zig:1832`; `buildInterfaceDeclName` `:1891`, `buildEnumDeclName` `:1934`) builds
  a **structural** string (`record { name: string, id: i32 }`). The keys never match, so
  `.id = resolvedTypeId orelse 0` always takes the fallback. The id is already on the binding as
  `TypedBinding.typeId`, and `src/comptime.zig:1313` reads exactly that field to build the map.
- Missing kinds: `bindingToRepr` (`snapshot.zig:369-473`) handles `.use`, `.val`, `.@"fn"`, `.type_`
  and `.behavior`; everything else becomes `{"ast": "<tag>"}`. Behaviors render as name + generics
  only, records without methods, enums without variants (the `.type_` arm's `else` branch emits
  `enum_def` with `name`, `id`, `generic` and nothing more), and `implement` blocks not at all. Fn
  bodies are raw source lines (`extractFnBody`, `:246-257`).

## Steps

### Step 1 — One comptime snapshot per test

Re-measure [Why this front runs before the checker](#why-this-front-runs-before-the-checker) at HEAD,
write the two numbers into this README, then record each snapshot once under a backend-independent
path.

| | Layout | Trade-off |
|---|---|---|
| A | `snapshots/comptime/<slug>.snap.md`, `…/errors/<slug>.snap.md`, `templates/` | Flattest; mixes AST files with the two subdirectories |
| B | `snapshots/comptime/ast/<slug>.snap.md`, `…/errors/<slug>.snap.md`, `templates/` | Three siblings named by what they hold; `ast/` is the path `snapshot.zig:1064` already names |
| C | keep `node/` and `node/errors/`, delete the rest | Smallest diff; keeps a backend name that means nothing |

**Recommended: B.** In `helpers.zig`, replace the `runtime_dirs` loop (`:134`, `:153-156`) with one
call to the existing `snapshot.assertComptimeAst` (`snapshot.zig:1059`), and the `runtimes` loop
(`:257-258`) with one write to `comptime/errors/<slug>`; delete the comment at `:129-133`. Move
`node/<slug>` → `ast/<slug>` and `node/errors/<slug>` → `errors/<slug>` with `git mv` so history
follows, then delete `erlang/`, `beam/`, `wasm/`. `templates/` is unchanged
(`src/comptime/tests/templates.zig` writes it directly).

Do this as a **pure move**: no renderer change in the same commit, so the content set is provably
unchanged.

**Acceptance:**
- [ ] `find snapshots/comptime -name '*.snap.md' | wc -l` → **338** (202 + 135 + 1), not 1079
- [ ] The multiset of md5 sums over `snapshots/comptime` is the same **332** distinct hashes before
      and after, and the 338 surviving paths hash to the same values their `node` originals did
- [ ] `zig build test` green without `BOTOPINK_SNAP_CREATE`, 0 `.snap.md.new` on disk
- [ ] A `BOTOPINK_SNAP_TRACE` run (`scripts/snap_audit.sh --mode=orphans --trace=<file>`, an
      unfiltered run from an empty trace file) lists no `comptime/{node,erlang,beam,wasm}/` path,
      0 `orphan` and 0 `unrecorded`
- [ ] `src/comptime/tests/AGENTS.md` and `modules/compiler-core/AGENTS.md:20` (today
      `comptime/ (beam/, erlang/, node/, templates/, wasm/)`) name the new layout and state the mapping
      from the old paths the 1.0.1-beta reports cite (`SN/…` = `comptime/node/…`)
- [ ] This README's [Why this front runs before the checker](#why-this-front-runs-before-the-checker)
      carries the re-measured numbers

### Step 2 — Render inferred types, and keep the tripwire visible

Render every type in `TYPED AST JSON` from inference, and make an unresolved one unmistakable.

1. `fn_def` params and return type: from the binding's `.func` type (`b.type_`, params in
   `T.Type.func.params`) through `typeNameOf`, not from `typeNameFromTypeRef`. `record_def` fields move
   the same way, from the registered type def. Delete `typeNameFromTypeRef` once nothing calls it.
2. `typeNameOf`'s `.typeVar` arm: split the states — `.generic` renders the type parameter's name (or
   a stable `'a`, `'b` by first appearance), `.unbound` keeps `?`. **Do not** map `.unbound` to
   anything that reads as a resolved type: it is the only place a snapshot shows the checker punting.
3. `.func`: render `fn(<params>) -> <ret>`, not the return type alone.

Expect the `?` count to **change shape, not just drop**: the 57 syntactic `?` go, and an unannotated
param inference leaves unbound becomes a new, meaningful `?`.

**Acceptance:**
- [ ] No `"?"` in a snapshot for a type inference resolved; every remaining `?` is an `.unbound`
      variable — asserted by a unit test in `snapshot.zig` over a generic fn (renders its parameter
      name, not `?`) and a resolved fn (renders the type)
- [ ] The six slugs listed in [What moved since 1.0.4-beta](#what-moved-since-104-beta) still show a
      `?` until [`01-checker`](../01-checker/README.md) resolves them — this front does not make them
      green, and the list in this README is re-derived in the same commit
- [ ] The re-recorded snapshots reviewed, not blanket-accepted: each file's diff is only type text

### Step 3 — `"id"`, missing declaration kinds, cosmetics

1. **`"id"`.**

   | | Change | Trade-off |
   |---|---|---|
   | A | Render `b.typeId` directly in `bindingToRepr` (the binding is in hand), and delete `resolveTypeId` and the `type_ids` map use | Real ids — but a monotonic counter over the whole env, so any type added upstream of a test (a `libs/std` type, a prelude change) shifts every id after it and re-records every snapshot that has one |
   | B | Drop `"id"` from `record_def` / `enum_def` | 65 files change once; no snapshot ever moves for an id again. Nothing in the tree reads the field |

   **Recommended: B**, unless a consumer of the id is found; A turns every `libs/std` edit into a
   comptime re-record. Either way the `type_ids` plumbing in `src/comptime.zig:114`, `:1311-1313`,
   `:1324`, `:1490-1492`, `:1503` becomes dead. **`src/comptime.zig` is not this front's file** — it is
   [`01-checker`](../01-checker/README.md)'s. Leave the plumbing in place, name the five sites in the
   commit message, and hand the deletion to that front (this front's change only stops *reading* the
   map, which is a `snapshot.zig` edit).
2. **Missing kinds.** Serialise behavior member signatures, type methods, enum variants with payload
   types and sections, and `implement` blocks (as their own entry or on the implementing type).
3. **Cosmetics.** Rename `"indent"` → `"ident"` (written at `snapshot.zig:60` and `:120`, filled with
   `b.name` in the `.use`, `.val` arms; **102 files**) in the same re-record as step 2, so the files
   move once.

Leave fn bodies as source lines: a typed body renderer is a larger change than this front, and
[`12-language-tests`](../12-language-tests/README.md) now asserts bodies by running the program.

**Acceptance:**
- [ ] No `"id": 0` placeholder in any snapshot (field removed, or a real id)
- [ ] Behaviors, `implement` blocks, methods and variants appear in `TYPED AST JSON`
- [ ] Error snapshots (`comptime/errors/`) byte-identical across steps 2–3 — the diagnostic renderers
      are not touched
- [ ] `grep -rl '"indent"' snapshots/comptime` is empty
- [ ] The five `src/comptime.zig` `type_ids` sites are named in the commit message and registered
      with [`01-checker`](../01-checker/README.md); no line of that file is edited here

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] Step 1 lands byte-identical by content (the same 332 distinct hashes); steps 2–3 re-record only
      `snapshots/comptime/ast/`
- [ ] A `BOTOPINK_SNAP_TRACE` run after each step: 0 orphans, traced = on disk
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/comptime-dedup`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Files.** Step 1: **1079 → 338** (741 deletions, 337 renames). Steps 2–3: nearly every AST snapshot
  — 43 carry a rendered `?`, 65 an `"id"`, 102 an `"indent"`, and every file with a `fn_def` gains
  inferred parameter text. The 135 error snapshots and `templates/` do not move.
- **Other fronts.** This is the point of running first: after step 1, one comptime slug is one file for
  [`01-checker`](../01-checker/README.md), for
  [`07-review-backlog`](../07-review-backlog/README.md)'s wave B, and for
  [`08-hygiene`](../08-hygiene/README.md)'s 5.13 fixture rewrite. Measured against the last partial
  checker wave, that is 48 files → 16.
- **Tooling.** `scripts/snap_audit.sh` scans `snapshots/comptime` recursively; its path classifier has
  an explicit `seg[5] ~ /^(node|erlang|wasm|beam)$/` arm (`:501`) that collapses the four copies into
  one review row. After step 1 that arm matches nothing — **it must be updated in the same commit or
  every comptime row loses its suite label**, and `scripts/snap_audit.sh` is
  [`07-review-backlog`](../07-review-backlog/README.md)'s file. Hand that one-arm edit to it, or take
  it as a carve-out named in the commit message.
- **The 1.0.1-beta reports** cite `snapshots/comptime/node/…` (`SN/…`) throughout. They are the audit
  record and are not edited; the path mapping in `src/comptime/tests/AGENTS.md` is how a reader follows
  them.

## Notes

- The copies were kept on purpose (`helpers.zig:129-133`) to avoid churn during the runtime collapse.
  That reason is spent: every renderer or checker fix now pays the churn four times.
- Step 1 before step 2, in separate commits: a move proven by hash equality, then a re-record reviewed
  as type text only. Merging them makes a 1079-file diff nobody reads.
- The six content-identical error pairs are test duplicates, not layout copies — owned by
  [`07-review-backlog`](../07-review-backlog/README.md).
- `"id": 0` is not a checker defect: the ids are allocated and stored; only the renderer's lookup key
  is wrong.
- `buildRecordDeclName`'s structural output is also what makes hover print `record { … }`
  ([`11-tooling`](../11-tooling/README.md) reports it, [`01-checker`](../01-checker/README.md) owns
  it). If that front renames the builders, `resolveTypeId` starts matching and option A's ids appear
  for free — which is a reason to take option B **before** it lands, not after.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **06** [`comptime-dedup`](./06-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 1079 files → 338) | not started — **runs before 01** |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **no** — 06 first | Both write `snapshots/comptime/**`. 06 deletes 3 of 4 copies per slug; 01 re-records the directory in bulk. Running 01 first costs 3× the files on every 01 commit (measured: 48 files for 16 slugs over the last partial wave) |
| **02 erlang · 03 beam · 04 js · 05 wasm** | yes | No shared file; `snapshots/codegen/**` is theirs, `snapshots/comptime/**` is 06's |
| **07 review-backlog** | **no** — 06 first | 06 owns `src/comptime/tests/helpers.zig`, 07 the rest of `src/comptime/tests/**`; 07's wave B is ordered after 06 step 2. 06 also needs a one-arm edit in `scripts/snap_audit.sh` (07's file, `:501`) — carve-out or handed over |
| **08 hygiene** | **no** — 06 first | 08's 5.13 fixture rewrite (`src/comptime/tests/infer_decls.zig`) re-records one comptime snapshot: 4 files before step 1, 1 after |
| **09 ecosystem-residuals · 10 cli-residuals · 11 tooling · 12 language-tests** | yes | No shared file, no shared snapshot directory |
| **13 module-identity** | yes | 13 takes the module-atom lines of `comptime/{template_eval,decorator_eval}.zig` and `snapshots/codegen/{erlang,beam}/`; neither is 06's |
| **14 comptime-on-beam** | yes, but **06 first is cheaper** — measured | 14 re-records the 48 snapshots carrying a `----- COMPTIME ERLANG` section. Measured at `c2dd780` (`grep -rl 'COMPTIME ERLANG' snapshots/`): 7 each in `codegen/{beam,commonJS,erlang,wasm}` — **not 06's** — and 5 each in `comptime/{beam,erlang,node,wasm}`, which is **20 files carrying 5 unique slugs**. After 06 step 1 those 20 become 5, so 14 lands 48 → 33 files. No file is shared at any moment (14 owns none of `snapshot.zig`, `helpers.zig` or the layout), so this sequences a landing, not the work. 14 must not land *between* 06 step 1 and its commit, or its 20 files are deleted under it |

**Front-table row (`overview.md`):**

```markdown
| [`06-comptime-dedup`](./06-comptime-dedup/README.md) | high | not started — **before 01** | 1079 comptime snapshot files carry 338 unique paths: four byte-identical copies per typed-AST slug, two per type-error slug. Deleted before the checker runs, that is one 741-file deletion; after it, every checker commit pays 4×. Plus the renderer: 57 of its 69 `?` come from a function that never consults inference, all 71 `"id"`s are `0`, and behaviors, variants, methods and `implement` blocks never reach the JSON |
```
