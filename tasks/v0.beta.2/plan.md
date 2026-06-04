# Working plan — v0.beta.2

> **What this file is.** The agent's working memory — a **living, mutable**
> scratchpad, thinking out loud. It is the opposite of a spec (`<slug>.md`),
> which is *immutable once written*. Here the agent records reasoning, open
> questions, hypotheses and next steps **while it thinks**, and edits it freely
> every turn.
>
> Siblings: [`README.md`](README.md) (set index) · [`status.md`](status.md) (real state) · [`../AGENTS.md`](../AGENTS.md) (task-set contract)
>
> Trust order on conflict: `status.md` > `.tasks/<slug>/TODO.md` > spec header > **this plan**.
> (This plan is reasoning, not a source of truth — once a decision settles, it migrates to its owning file.)

---

## 0. Plan state

- **Current phase:** `docs-refactor` **done** (F0–F4) on branch `feat`; 5 specs defined.
- **Last updated:** 2026-06-04.
- **Next milestone:** start the Wave-1 worktree (`stdlib-gleam`) and/or run the `zig-feature-gaps` analysis; `test-blocks` waits for stdlib-gleam (front-end collision) — note its worktree is already pre-seeded (`.tasks/test-blocks`, 0/41).

---

## 1. Settled decisions (will migrate to their owning file)

> Everything here was decided in conversation; "home" is where it migrates once it becomes permanent.

| # | Decision | Final home |
|---|---|---|
| D1 | **Three-layer model**: (1) permanent co-located contracts (`AGENTS.md`/`docs.md`/`examples.md`), (2) centralized specs/roadmap (`tasks/`), (3) ephemeral per-worktree execution (`.tasks/<slug>/TODO.md`). | `tasks/AGENTS.md` |
| D2 | **One fact → one source.** Each fact lives in a single file; the others *link*, they don't copy. Root `AGENTS.md` becomes an index (no duplicated tree, no volatile counters); the leaf owns the detail. | `tasks/AGENTS.md` + root `AGENTS.md` |
| D3 | **Derivable slug.** `slug` propagates: spec `tasks/v0.beta.N/specs/<slug>.md` = branch `task/<slug>` = worktree `.tasks/<slug>/`. The agent *computes* the path, it doesn't search. | `tasks/AGENTS.md` |
| D8 | **`specs/` subfolder.** Per-feature specs live in `tasks/v0.beta.N/specs/<slug>.md`, separated from the set-level files at the root (`README.md`, `plan.md`, `status.md`). Physically separates *authored sources* (`specs/`) from *views/working docs* (root), and makes `specs/*.md` the exact glob for generators (DAG, status rollup). `_TEMPLATE.md` stays at `tasks/` (shared across sets). | `tasks/AGENTS.md` |
| D9 | **Independence + history.** The unit of independence is the *task* (parallel worktrees, default `Depends on: nothing`; the DAG only draws real exceptions). A *set* is a batch label, **not** a sequential phase. A completed set **freezes as immutable history**; a new `v0.beta.(N+1)` opens for fresh work. Past sets = navigable institutional memory (each set is a closed namespace — no rotting global status). | `tasks/AGENTS.md` |
| D10 | **Ownership levels.** (A) Universal rules → `tasks/AGENTS.md` + `tasks/_TEMPLATE.md` (every version). (B) Set-specific → `tasks/v0.beta.N/` (`README`/`plan`/`status`, this batch only). (C) Feature-specific → `tasks/v0.beta.N/specs/<slug>.md` (one feature). D1–D9 are level-A → migrate from this `plan.md` into `tasks/AGENTS.md`. | `tasks/AGENTS.md` |
| D4 | **State trust order**: `status.md` > `TODO.md` > spec header. `Status` in the header is coarse (`pending`/`done`); live state lives only in `status.md`/`TODO.md`. | `tasks/AGENTS.md` |
| D5 | **Neutrality.** Content (specs, template, scripts) lives in neutral, version-controlled folders; `.claude/` (or any `.X/`) only holds *triggers* that point to the neutral content, never a source of truth. Portability anchor = `AGENTS.md` (open convention). | root `AGENTS.md` (conventions) |
| D6 | **AI-optimized spec**: front-loaded header with closed fields (`Slug`/`Depends on`/`Files`/`Touches docs`/`Status`), DAG in the README, `Test scenarios` as acceptance criteria, resumable checkbox steps. | `tasks/_TEMPLATE.md` |
| D7 | **End-to-end workflow** across the 3 layers (Open set → Define → Execute → Complete → Archive), see §5. | `tasks/AGENTS.md` |

---

## 2. Open / thinking

- [ ] **v0.beta.2 feature list?** A set is a **batch label, not a sequential phase** — the unit of independence is the *task* (one spec = one worktree = one branch off `feat`), so tasks run in parallel and never wait on each other unless a real `Depends on` says so (default `nothing`; the DAG only draws the rare exception). So this is not "pick one theme" — it's "list the independent features to tackle"; each becomes its own spec in `specs/`. The README title is just an optional umbrella name.
- [ ] **Spec granularity**: same as beta.1 (verbose, self-contained) or lean (header + checklist + scenarios)? Leaning toward matching beta.1 for consistency.
- [ ] Does the `Touches docs:` header field work? (closes the spec → Layer 1 loop).
- [x] Worth a `scripts/doc-health.sh`? → yes, built (docs-refactor F4); wiring it into CI is still open.

---

## 3. Next actions (suggested order)

1. [x] Create `tasks/AGENTS.md` — task-set contract (migrated D1–D10 + workflow).
2. [x] Create `tasks/_TEMPLATE.md` — spec template (D6).
3. [x] Trim root `AGENTS.md` to an index (applies D2) + record D5/neutrality in the conventions; link to `tasks/AGENTS.md`. (docs-refactor F1)
4. [ ] Fill `tasks/v0.beta.2/README.md` (umbrella name + DAG + table) once the feature list (§2) is known.
5. [ ] Define features one at a time → one `specs/<slug>.md` from the template.
6. [x] `scripts/status.sh` to regenerate `status.md` as a derived rollup (docs-refactor F4).

---

## 4. v0.beta.2 feature backlog (to fill with the user)

> Each row becomes a spec `tasks/v0.beta.2/specs/<slug>.md` once defined (then leaves this backlog).

| slug | one-line | depends on | graduated to README? |
|---|---|---|---|
| `docs-refactor` | apply the 3-layer doc model to the repo (markdown-only) | nothing | ✅ yes — `specs/docs-refactor.md` |
| `stdlib-gleam` | expand `libs/std` mirroring Gleam's stdlib (list/dict/set/option/result/int/float/…) | nothing | ✅ yes — `specs/stdlib-gleam.md` (hybrid model assumed; F1 = `@[external(…)]` builtin annotation) |
| `test-blocks` | `test { … }` / `test "name" { … }` declarations + `assert` + `botopink test` runner (Zig/Gleam-style) | nothing | ✅ yes — `specs/test-blocks.md` |
| `stdlib-tests` | `.bp` test suite **for `libs/std`** via `test-blocks`, one file per module (Zig-style) | test-blocks, stdlib-gleam | ✅ yes — `specs/stdlib-tests.md` |
| `zig-feature-gaps` | catalog of Zig features bp won't support (manual memory etc.), to evaluate later | nothing | ✅ yes — `specs/zig-feature-gaps.md` |
| _(next front)_ | _(to define with user)_ | | |

---

## 5. End-to-end workflow (D7 — migrates to `tasks/AGENTS.md`)

Five phases across the 3 layers. Each phase names **who writes what** and the **exit gate**.

### Phase 0 — Open a set (`v0.beta.N`)
- Create `tasks/v0.beta.N/` with `README.md` (empty DAG + table skeleton) and `plan.md` (this file).
- Decide the set theme (drives the README title + "core model").
- **Gate:** README skeleton + plan.md exist.

### Phase 1 — Define a feature (with the user)
- Discuss in chat; capture the rough idea in `plan.md` §4 backlog (slug + one-line + deps).
- Once agreed, create the spec `tasks/v0.beta.N/specs/<slug>.md` from `_TEMPLATE.md` (intent: grammar, examples, steps F0/F1…, test scenarios, `Touches docs:`).
- Add the row to `README.md` tables + draw the edge in the DAG.
- **Gate:** spec written; `Status: pending`; README updated. Spec is now **immutable**.

### Phase 2 — Start execution (worktree)
- `git worktree add .tasks/<slug> -b task/<slug> feat` (branch off `feat`, never `main`).
- Seed `.tasks/<slug>/TODO.md` from the spec's steps (live checklist).
- **Gate:** worktree + TODO.md exist on `task/<slug>`.

### Phase 3 — Work
- Edit code **inside the worktree only** (`.tasks/<slug>/...`); tick `TODO.md` checkboxes as steps land.
- `plan.md` tracks only cross-feature reasoning, never per-step state (that lives in TODO.md).
- **Gate:** all steps done; `Test scenarios` pass locally.

### Phase 4 — Complete (commit → integrate → sync docs)
1. Commit in the worktree (no `cd`); the pre-commit hook runs `zig fmt` + `zig build` + `zig build test` — no `--no-verify`.
2. Integrate into `feat` over SSH via a throwaway worktree: `git worktree add .tasks/_integrate-<slug> -b integrate/<slug> origin/feat` → `git merge --no-ff task/<slug>` → resolve → `zig build test` → `git push origin integrate/<slug>:feat`.
3. Update `status.md` (real state).
4. Update every `AGENTS.md`/`docs.md` listed in the spec's `Touches docs:` — closes the Layer 2 → Layer 1 loop.
- **Gate:** merged into `feat`; status.md + touched docs updated.

### Phase 5 — Archive
- `git worktree remove .tasks/<slug> && git worktree remove .tasks/_integrate-<slug>`; `git branch -d task/<slug> integrate/<slug>`; `git worktree prune`.
- Spec stays as immutable history; README/status show it done.
- **Gate:** worktrees gone; set reflects completion.

### Cross-cutting loop
- The agent edits `plan.md` (§0 phase, §3 checkboxes, §5 log) **every turn while reasoning**, before touching the owning files.
- On any state conflict, read in trust order: `status.md` > `TODO.md` > spec header > `plan.md`.

---

## 6. Reasoning log (append-only, newest at the bottom)

- **2026-06-03** — Mapped the existing structure: the `AGENTS.md`/`docs.md`/`examples.md` triad per directory (~40 nodes) + the spec set in `tasks/v0.beta.1/` (README + status + one file per feature). Found 3 gaps: no `tasks/AGENTS.md`, no template, and the spec ↔ permanent-doc link is implicit.
- **2026-06-03** — Decided to keep docs distributed (locality = information) and centralize only Layer 2. `.claude/` moves off the critical path (triggers only). Confirmed architecture decisions live in `tasks/AGENTS.md`, not in the AI's private memory.
- **2026-06-03** — Created this `plan.md` as the set's living working memory.
- **2026-06-03** — Renamed `plano.md` → `plan.md` and rewrote the body in English (everything in English, per project convention).
- **2026-06-03** — Translated `tasks/v0.beta.1/situacao.md` to English and renamed it `status.md` (Portuguese filename); fixed all references.
- **2026-06-03** — Redundancy review: Status lived in 4 places, deps in 2. Resolution = authored vs derived (README drops Status column → links to `status.md`; DAG derived from spec `Depends on`; `status.md` is a generated rollup; backlog rows graduate to README). Recording as D8-adjacent (still open in §2).
- **2026-06-03** — Adopted `specs/` subfolder (D8): per-feature specs go in `tasks/v0.beta.N/specs/<slug>.md`; root keeps only set-level files. Slug invariant gains one segment; `_TEMPLATE.md` stays at `tasks/`.
- **2026-06-03** — User clarification on independence + history → recorded as D9: the unit of independence is the *task* (parallel worktrees, default `Depends on: nothing`); a *set* is a batch label, not a sequential phase; the DAG only draws real exceptions; a completed set **freezes as immutable history**, and a new `v0.beta.(N+1)` opens for fresh work. Past sets are navigable institutional memory (consistent with D2 — each set is a closed namespace, no rotting global status).
- **2026-06-03** — Created `tasks/AGENTS.md` (universal contract, D1–D10 + workflow) and `tasks/_TEMPLATE.md` (spec mold). Defaults baked in: verbose spec (O2), `Touches docs:` field (O3), authored-vs-derived (O5). O2/O3/O5 now closed.
- **2026-06-03** — O6 = yes: migrated `v0.beta.1` to the `specs/` layout (20 feature files → `specs/`, README/status stay at root, README links rewritten to `specs/`).
- **2026-06-03** — Defined v0.beta.2 fronts (it is a NEW set, not beta.1 leftovers): (1) `docs-refactor` (markdown-only, dogfoods D1–D10), (2) `stdlib-gleam` (Gleam-style stdlib for `libs/std`). Both specced + added to README. `stdlib-gleam` assumes the hybrid model and its F1 introduces an FFI annotation, enabling the declaration+external modules (`int`/`float`/`string`/`io`).
- **2026-06-03** — `stdlib-gleam` F1 redesigned per user: `@external` is **not** a parser keyword — it is a **builtin** (`external(target, module, symbol)` in `builtins.d.bp`) invoked inside a generic **annotation syntax `@[ … ]`** (extensible: future `@[deprecated]`, `@[inline]`). Updated all examples to `@[external(…), external(…)]`.
- **2026-06-03** — `stdlib-gleam` F0 fixed per user: `prelude.zig` (embed/loader glue) does **not** belong in `libs/std/src/` (which stays `.bp`-only) — relocate it into `modules/compiler-core/src/comptime/stdlib/prelude.zig` (next to `registerStdlib`), `@embedFile` via relative path; update `build.zig`.
- **2026-06-03** — Added 3rd front `test-blocks`: Zig/Gleam-style `test { … }` / `test "name" { … }` top-level declarations + `assert` builtin + `botopink test` runner subcommand (front-end → assert → infer → per-backend runner → CLI). Distinct from the compiler's internal `zig build test` snapshot suite. Specced + added to README.
- **2026-06-03** — Added `stdlib-tests` (re-scoped from a generic "lang-test-suite" per user: tests are **for `libs/std`**, Zig-style co-located + `libs/std/test/`, one file per module). Depends on `test-blocks` + `stdlib-gleam` (first real DAG edge in beta.2).
- **2026-06-03** — Added `zig-feature-gaps`: an evaluation backlog cataloging Zig features bp won't support (manual memory, pointers, alignment, …) with ❌/🟡/✅ decisions; 🟡 items graduate to follow-up specs. It is the "out of scope" reference for the stdlib specs. Memory-management is a stated **non-goal** of bp.
- **2026-06-03** — Wave plan agreed (run on `feat` directly, no worktree, per user): docs-refactor + zig-feature-gaps + one of {stdlib-gleam, test-blocks} in parallel; never stdlib-gleam ⨯ test-blocks together (both rewrite the compiler front-end + builtins.d.bp); stdlib-tests last (deps).
- **2026-06-03** — Executed `docs-refactor` F1 + F3 on `feat`: root `AGENTS.md` trimmed to an index (removed the duplicated "AGENTS index" subtree + volatile counters; added `tasks/` + neutrality/one-fact conventions; trimmed worktree prose + dropped the stale "Open parallel tasks" table). beta.1 README rewritten without Status columns → links `status.md`; `status.md` marked single source of truth. F2 leaf-audit + F4 scripts deferred. Committing all session work.
- **2026-06-03** — User clarified ownership levels → recorded as D10: three levels — (A) **universal** rules in `tasks/AGENTS.md` + `tasks/_TEMPLATE.md` (apply to every version), (B) **set-specific** in `tasks/v0.beta.N/` (README/plan/status — this batch only), (C) **feature-specific** in `tasks/v0.beta.N/specs/<slug>.md` (one feature). Implication: D1–D9 are level-A and belong in `tasks/AGENTS.md`; they sit in this `plan.md` only as staging until that file exists. Creating `tasks/AGENTS.md` = migrating D1–D9 out of here, leaving `plan.md` with beta.2-only reasoning.
- **2026-06-04** — Finished `docs-refactor` F2 + F4 on `feat`. F2 (4 parallel audit agents over the ~40 leaf `AGENTS.md`): removed every volatile counter (snapshot/fixture/line counts), fixed trees that omitted real `beam/`/`wasm/` dirs, dropped the duplicated `alloc` convention (root owns it), corrected the `libs/std/src` claim that `builtins.d.bp` is embedded (it is registered programmatically in `env.zig` — wiring it = stdlib-gleam), deleted the vestigial top-level `snapshots/` tree (0-byte placeholders; build writes only under `modules/compiler-core/`), added 5 minimal `AGENTS.md` for `compiler-core/src/*/tests/`, translated `build.zig` comments to English. F4: `scripts/doc-health.sh` (orphan dirs / broken links / volatile counters — found+fixed 4 real broken links on first run) + `scripts/status.sh <set>` (derived rollup; first run revealed the pre-seeded `.tasks/test-blocks` worktree). Created `tasks/v0.beta.2/status.md`. docs-refactor: **done**.
