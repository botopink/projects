# docs-audit-refresh — sweep every mutable `*.md` **and every comment block in `*.zig`/`*.bp`/`*.ts`/`*.js`**, drop discarded paths, rewrite to current truth

**Slug**: docs-audit-refresh
**Depends on**: Frente A §S (`*fn` removal) and §U (unused-builtin sweep) —
  the comment-tier of code files lands **after** the semantic changes Frente A
  makes, so the comment audit doesn't churn against an in-flight code edit.
  File-disjoint with the rest (Frente B, C, `prim-op-annotation`,
  `std-expansion`, `recursive-test-gate`) at the doc-content level.
**Files**:
  - **In scope — mutable `*.md`**:
    - top-level: `AGENTS.md` · `README.md` · `docs.md` · `CHANGELOG.md` · `TODO.md`
    - `repository/AGENTS.md`
    - `repository/botopink-lang/{AGENTS.md, README.md, docs.md, CHANGELOG.md}`
      + nested `{examples,libs,modules,scripts}/AGENTS.md` + `modules/docs.md`
      + `docs/botopink-json.md`
    - each sibling lib's `{AGENTS.md, README.md, docs.md, CHANGELOG.md}`:
      `erika/` (+ `examples.md`) · `jhonstart/` (+ `src/AGENTS.md`) ·
      `onze/` (+ `src/AGENTS.md`) · `rakun/` · `vscode-extension/`
    - `scripts/AGENTS.md`
    - `tasks/{AGENTS.md, _TEMPLATE.md}` (universal layer — mutable)
    - `tasks/v0.beta.19/{README.md, plan.md, status.md}` (level B — mutable;
      `specs/*.md` are immutable, **out of scope**)
    - **orphans to triage**: `tasks/situacao.md` · `tasks/parser-split.md` ·
      `tasks/test-reorg.md` (live in `tasks/` root, outside any set —
      they violate the level-A/B/C layout of `tasks/AGENTS.md`)
  - **In scope — comment blocks inside source files** (comments only;
    *zero* semantic edits — `git diff -U0 --ignore-all-space --ignore-blank-lines`
    must show only comment lines):
    - `*.zig` — every file under `repository/botopink-lang/src/`,
      `repository/botopink-lang/modules/**/src/`, and every workspace
      `build.zig` / `build.zig.zon`. Comment syntax: `//` line comments
      and `///` / `//!` doc-comments.
    - `*.bp` (botopink) — every file under `repository/botopink-lang/libs/**/src/`
      and `repository/botopink-lang/libs/**/tests/`, every lib's
      `repository/<sub>/libs/**/src/` and `repository/<sub>/examples/**`.
      Comment syntax: `//` line comments and `/* … */` block comments.
    - `*.d.bp` — every declaration file (`libs/std/src/*.d.bp`,
      `repository/<sub>/libs/**/*.d.bp`). Header comments + per-decl
      docstrings.
    - `*.ts` — `repository/vscode-extension/src/**` + `repository/vscode-extension/test/**`.
      Comment syntax: `//`, `/* … */`, JSDoc `/** … */`.
    - `*.js` / `*.mjs` — every sidecar (`commonJS` / `mjs` adapters in
      `libs/std/src/`, `libs/rakun/src/`, etc.) + `repository/vscode-extension/out/`
      shipped files **only if** they are tracked sources (skip generated
      outputs). Comment syntax: same as `*.ts`.
  - **Out of scope (immutable, do not touch)**:
    - every `tasks/v0.beta.{1..18}/**` file (frozen sets per
      `tasks/AGENTS.md` D9: "a set freezes as immutable history")
    - every `tasks/v0.beta.19/specs/*.md` (spec body is immutable per
      `tasks/AGENTS.md` D6 / `_TEMPLATE.md` preamble)
    - **all code semantics**: every `.zig` / `.bp` / `.d.bp` / `.ts` /
      `.js` / `.mjs` change is **comments-only**. A diff that touches
      non-comment lines is a bug in the audit and gets reverted in F6.
    - generated / vendored sources: `zig-out/`, `.zig-cache/`,
      `node_modules/`, `repository/vscode-extension/out/` (unless tracked
      and hand-authored), `libs/**/dist/` — never audited.
**Touches docs**: this spec **is** the docs work — every file listed above is
  both the input and the output. Set-level updates: `tasks/v0.beta.19/README.md`
  (add this row to the Scope table + Order block) · `tasks/v0.beta.19/status.md`
  (rollup row, generated)
**Status**: pending

## Problem

The mutable documentation tier has drifted in three directions during the
v0.beta.{3..19} wave of parallel work:

1. **Stale references to discarded paths.** Memos and AGENTS sections still
   point at approaches that were tried and dropped — e.g. `*fn` examples
   (v0.beta.12 removed the surface), `.tasks/` cleanup steps that the
   v0.beta.7 consolidation already executed, hooks documented as "live in
   `.git/hooks/` only" while `recursive-test-gate` is in flight to move
   them to `scripts/git-hooks/`. A reader hitting these claims either
   wastes time looking for files that no longer exist, or worse, copies
   the discarded pattern into new code.
2. **Orphan files in `tasks/` root.** `tasks/parser-split.md`,
   `tasks/test-reorg.md`, `tasks/situacao.md` predate the level-A/B/C
   ownership rule in `tasks/AGENTS.md` (D10). They sit outside any set,
   outside `specs/`, with no `Status` field — `parser-split` and
   `test-reorg` are duplicated as spec files under `v0.beta.1/specs/`, so
   their root copies are pure rot. `situacao.md` is a 2026-06-02 audit
   snapshot whose every row is now reachable via `git log` + the set
   `status.md` files; its filename also violates the "everything in
   English" rule (memory: `feedback_everything_english.md`).
3. **Stale HTML comments and TODO scaffolding.** Several AGENTS / docs /
   README files carry `<!-- … -->` blocks that were scratchpad notes
   during authoring ("TODO: link the schema once the parser lands",
   "see #123") whose referenced PRs/issues have shipped or been
   abandoned. The `_TEMPLATE.md` rule "Remove these comments when done"
   was followed for specs but not for the surrounding contracts.

Net effect: the **permanent-contracts** tier (`AGENTS.md` / `docs.md` /
`examples.md`) — the tier that `tasks/AGENTS.md` D1 calls "what the code
*is*" — does not reliably reflect what the code is. Every other v0.beta.19
spec assumes "the contracts are current" as a starting point; this spec
makes that assumption true.

## Goal

Every file in **In scope** above accurately describes the code, layout,
workflow, and decisions **as of v0.beta.19 HEAD on `feat`**. Concretely:

- No prose references a discarded mechanism without an explicit
  "(removed in vN, see commit X)" anchor.
- No file claims a file path, command, env var, or workflow that no
  longer exists.
- No orphan task file remains in `tasks/` root: each is either
  promoted into the correct level (A/B/C) or deleted with a `git rm`
  documented in the commit body.
- Every `<!-- -->` HTML comment is either (a) load-bearing context for
  a future reader (kept with a sharpened message) or (b) deleted.
- Every file is **English-only** (memory rule
  `feedback_everything_english.md`).
- Cross-file links resolve: a `./AGENTS.md` link from `repository/erika/`
  actually lands on `repository/erika/AGENTS.md`, etc.

Out of scope (explicit, repeated for safety):

- **Past sets** (`tasks/v0.beta.{1..18}/**`) are not touched. They are
  institutional memory, frozen by `tasks/AGENTS.md` D9 ("a completed
  set freezes as immutable history"). Even a typo in
  `v0.beta.5/specs/jhonstart.md` is left as-is.
- **Open spec bodies** (`tasks/v0.beta.19/specs/*.md`) are not touched.
  `_TEMPLATE.md` says "immutable once written". This spec is itself
  one of them — once written, only fix typos via a follow-up spec.
- **No code changes.** Not a single `.zig`, `.bp`, `.md` file outside the
  scope list above is touched. If the audit surfaces a contract that
  drifted *because the code did* (e.g. `AGENTS.md` describes the old
  module layout), the spec **records the drift** but leaves the fix to
  the code-owning frente — `docs-audit-refresh` does not silently
  reshape contracts to match wrong code.

## What "outdated information that was discarded" means — operational definition

A claim in a doc is "discarded" when at least one of:

1. It references a syntactic surface that the codebase no longer parses
   (e.g. `*fn`, `@external` outside `#[…]`, `from "lib"` without the
   v13 generic-loader fix).
2. It references a file path that no longer exists (`git ls-files | grep
   -q '<path>'` returns nothing).
3. It references a workflow command that no longer works (`scripts/<x>.sh`
   missing, `zig build <step>` target removed).
4. It references a memory/task/PR that the project itself supersedes
   (e.g. "we're considering N approaches" when one of them shipped).
5. It contradicts a newer, authoritative file (`tasks/AGENTS.md`'s
   level-A rules vs. an older `repository/.../AGENTS.md` paragraph
   describing the *old* tasks layout).

The audit produces a per-file decision: **keep** (no drift) · **edit**
(rewrite the drifting prose, anchor to current truth, link to the
v0.beta.N spec that landed the change) · **delete** (whole file is
discarded — only the orphan triage in F0 produces deletions).

## What "review all comments" means

Two senses of "comment":

- **HTML comments inside `*.md`** (`<!-- … -->`). Cataloged and decided
  per occurrence: keep (with sharpened message), keep + convert to
  visible prose (if a future reader would benefit), or delete.
- **Editorial commentary in prose** — "WIP", "TODO", "TBD", "FIXME",
  "for now", "we may", "we're considering", "see #N", "this should
  probably". Each is a deferral marker; the audit resolves it: did the
  thing ship? Strike the marker. Did it get dropped? Either delete the
  paragraph or pivot it to "discarded — see <commit>".

The audit treats both as the same signal (uncommitted authorial intent
leaking into a permanent contract).

## Examples

### orphan triage (F0)
```bash
$ ls tasks/*.md
tasks/AGENTS.md
tasks/_TEMPLATE.md
tasks/parser-split.md        # duplicate of v0.beta.1/specs/parser-split.md
tasks/test-reorg.md          # duplicate of v0.beta.1/specs/test-reorg.md
tasks/situacao.md            # 2026-06-02 audit snapshot (Portuguese filename + body)

# Audit outcome:
#   parser-split.md  → delete (duplicate of v0.beta.1/specs/parser-split.md)
#   test-reorg.md    → delete (duplicate of v0.beta.1/specs/test-reorg.md)
#   situacao.md      → delete (snapshot superseded by per-set status.md +
#                              git log; never replaced — Portuguese filename
#                              violates English-only rule too)
```

### stale-reference sweep (F1)
```diff
# repository/botopink-lang/AGENTS.md (before)
- The pre-commit hook lives in `.git/hooks/pre-commit` (not version-controlled).
- To install on a fresh clone, copy the snippet from this file into your
- `.git/hooks/` directory.

# repository/botopink-lang/AGENTS.md (after)
+ The pre-commit hook is version-controlled at
+ `scripts/git-hooks/pre-commit` and wired by `scripts/install-hooks.sh`.
+ See [`tasks/v0.beta.19/specs/recursive-test-gate.md`](../../tasks/v0.beta.19/specs/recursive-test-gate.md)
+ for the recursive-gate design.
```

### HTML-comment sweep (F2)
```diff
# repository/erika/docs.md (before)
- <!-- TODO: document the query AST once erika-query-ast lands -->
- ## Query DSL
- The query DSL is `erika "…"` — syntax TBD.

# repository/erika/docs.md (after)
+ ## Query DSL
+ The query DSL is `erika "…"` (single-line) or `erika """…"""`
+ (multi-line), lowered through `@ExprCustom<Query>` per
+ [`tasks/v0.beta.11/specs/erika-query-ast.md`](../../tasks/v0.beta.11/specs/erika-query-ast.md).
```

### English-only sweep (F3)
```diff
# tasks/situacao.md (deleted in F0, so this example uses a hypothetical leak)
- ## Situação
- > Levantamento real cruzando cada arquivo...

# nowhere — content removed entirely, no English replacement needed
# (the data was a one-shot snapshot; git log + status.md are authoritative)
```

### TODO.md refresh (F4)
```diff
# TODO.md (before — at meta root)
- ## v0.beta.18
- - [ ] bpmp online (deferred)
- - [ ] module-auto-tag (J)

# TODO.md (after)
+ ## v0.beta.19 — pending
+ - [ ] recursive-test-gate (independent, this set)
+ - [ ] docs-audit-refresh (independent, this set)
+ (Frente A/B/C, prim-op-annotation, std-expansion: see
+  tasks/v0.beta.19/status.md — generated rollup)
```

## Steps

### F0 — orphan triage (`tasks/` root)
- [ ] `git rm tasks/parser-split.md` (duplicate of
      `v0.beta.1/specs/parser-split.md`) — commit body cites the
      duplicate path and the v0.beta.1 spec slug.
- [ ] `git rm tasks/test-reorg.md` (duplicate of
      `v0.beta.1/specs/test-reorg.md`) — same.
- [ ] `git rm tasks/situacao.md` (2026-06-02 snapshot; data
      reachable via `git log` + each set's `status.md`; filename also
      violates English-only rule).
- [ ] Confirm no other file references these three paths
      (`rg -F 'tasks/parser-split.md|tasks/test-reorg.md|tasks/situacao.md' --type md`)
      — if hits, update the referring file in F1.

### F1 — stale-reference sweep (per-file audit)
- [ ] For each file in **In scope** above, run the five-point
      operational definition (syntax / path / command / supersession /
      contradiction) against the prose. Produce one `audit-<file>.diff`
      patch per drifting file.
- [ ] Apply patches; verify links resolve
      (`rg -o '\[.*?\]\(([^)]+\.md[^)]*)\)' --replace '$1' | xargs ls`)
      — broken links become a sub-task list, fixed in this same step.
- [ ] Every rewrite anchors to current truth with a link to the
      v0.beta.N spec that landed the change (e.g. `*fn` removal →
      `tasks/v0.beta.12/specs/effect-annotations.md`).

### F2 — HTML-comment sweep
- [ ] `rg -F '<!--' --type md` over the **In scope** set; per match,
      decide keep / convert-to-prose / delete (one bullet in the
      audit log per occurrence).
- [ ] Same for editorial markers: `rg -i '\b(TODO|TBD|FIXME|WIP|XXX)\b'
      --type md` over the same set. Each marker is resolved (the thing
      shipped → strike; the thing was dropped → delete the paragraph
      or pivot to "discarded, see <commit>"; the thing is still open →
      keep + link to the open spec).

### F3 — English-only sweep
- [ ] `rg -i '\b(situação|situacao|situaç|português|portugues|levantamento|atualiz|conclu|MESCLAD|PUSHED|verde|vermelho|ativ|inativ)\b' --type md`
      over **In scope** — flag any Portuguese leakage. (False positives
      like "active"/"ativ" are OK — review per hit.)
- [ ] Translate or delete. The user's conversational language is
      pt-br (memory `feedback_pt_br_conversation.md`), but files are
      English (memory `feedback_everything_english.md`).

### F4 — refresh `TODO.md` (meta root)
- [ ] Replace the meta-root `TODO.md` body with: a one-line pointer to
      `tasks/v0.beta.19/status.md` (the generated rollup) + the pending
      list for the **current** set only (this set's pending specs,
      lifted from `v0.beta.19/README.md`'s Scope table).
- [ ] Anything claiming "v0.beta.{<19}" pending in the current TODO is
      either superseded (delete) or was deferred to v0.beta.19 (already
      tracked in this set, delete from TODO).

### F4a — `*.zig` comment sweep (`repository/botopink-lang/src/**`, `modules/**`, workspace `build.zig*`)
- [ ] Inventory: `rg -n '^[[:space:]]*(//|///|//!)' --type zig` over
      the in-scope tree; produce `audit-zig-comments.txt` (file:line:
      comment text). The inventory is the working set.
- [ ] Per file, run the five-point operational definition (syntax /
      path / command / supersession / contradiction) **against the
      comment lines only**. Decide keep / edit / delete per comment.
- [ ] Edit comments to remove:
      - references to discarded surfaces (`*fn`, old `@external`
        spelling, retired AST node names);
      - file paths that no longer exist;
      - "TODO: do X once Y lands" markers whose Y already shipped
        (resolve to either a sharpened invariant note or deletion);
      - "FIXME"/"XXX"/"HACK"/"WIP" markers whose underlying issue is
        closed.
- [ ] Keep + sharpen comments that encode a **why** (non-obvious
      constraint, subtle invariant, workaround for a known bug, a
      surprising behavior). User's global CLAUDE.md rule: comments
      should explain *why*, not *what*; one short line max.
- [ ] **Zero semantic edits.** Every diff hunk's added/removed lines
      are comment lines. Verified per file by stripping comments
      pre/post and `diff -u` showing empty: see F6 gate.

### F4b — `*.bp` / `*.d.bp` comment sweep (botopink sources)
- [ ] Inventory: `rg -n '^[[:space:]]*(//|/\*)' --type-add 'bp:*.bp' --type-add 'dbp:*.d.bp' --type bp --type dbp`
      over `repository/botopink-lang/libs/**`, every sibling lib's
      `libs/**`, every example dir. Produce `audit-bp-comments.txt`.
- [ ] Same five-point review as F4a. Botopink-specific watchouts:
      - `//` examples that show `*fn` syntax → discarded (v0.beta.12);
      - header comments in `.d.bp` files that cite canonical Node /
        Erlang URLs (per `std-expansion` convention) — keep + verify
        the URL still resolves;
      - `// TODO` markers naming v0.beta.{<19} as the resolver — every
        such version has closed; either the thing shipped (strike) or
        was dropped (delete the paragraph).
- [ ] `interface` and `template` body comments: keep + sharpen the
      ones that encode mock/sigil semantics (`$self`, `$0..N`,
      `$argc`, `when($argc == N)` from `prim-op-annotation`); they're
      load-bearing.
- [ ] Comments-only diff invariant — same as F4a.

### F4c — `*.ts` / `*.js` / `*.mjs` comment sweep
- [ ] Inventory: `rg -n '^[[:space:]]*(//|/\*|\*)' --type ts --type js`
      over `repository/vscode-extension/src/**`, `test/**`, plus every
      `*.mjs` / `*.js` sidecar tracked under `libs/**/src/`. Produce
      `audit-ts-js-comments.txt`.
- [ ] JSDoc blocks (`/** … */`) on exported APIs — keep if the export
      is still in `package.json` `"main"`/`"exports"` graph or
      consumed by the vscode-extension's contributes; delete the
      JSDoc when the export is gone.
- [ ] `// TODO` markers naming closed tasks (lib-test-workflows,
      install-script, etc.) → delete or pivot to a permanent
      "(landed in vN — see spec link)" comment when the explanation
      benefits a reader.
- [ ] `console.log` / `console.warn` left as debug breadcrumbs are
      **out of scope** — those are code, not comments. Audit log
      records sightings, but the spec does not delete them.
- [ ] Comments-only diff invariant — same as F4a.

### F5 — set-level updates (`tasks/v0.beta.19/`)
- [ ] Add this spec's row to `tasks/v0.beta.19/README.md` Scope table
      + Order block (the file-disjoint, parallel-with-everything row).
- [ ] Add the rollup row to `tasks/v0.beta.19/status.md` (one line —
      slug · branch · `pending`/`done` · short).

### F6 — verification gate
- [ ] `rg -F '<!--' --type md repository/ scripts/ tasks/AGENTS.md tasks/_TEMPLATE.md tasks/v0.beta.19/{README,plan,status}.md` returns **only** comments
      that the F2 audit explicitly kept (the audit log is the
      whitelist).
- [ ] No `<!-- TODO -->` style markers remain in scope.
- [ ] No link in the **In scope** set resolves to a missing file
      (the F1 link-check rerun).
- [ ] `git grep -l 'situacao\|tasks/parser-split.md\|tasks/test-reorg.md'`
      finds **only** the F0 deletion commit's own body (and
      `tasks/v0.beta.1/specs/{parser-split,test-reorg}.md`, which are
      frozen and out of scope).
- [ ] The five sample files spot-checked end-to-end:
      `AGENTS.md` (root) · `repository/AGENTS.md` ·
      `repository/botopink-lang/AGENTS.md` · `repository/erika/docs.md` ·
      `tasks/AGENTS.md`.
- [ ] **Comments-only invariant** for `*.zig` / `*.bp` / `*.d.bp` /
      `*.ts` / `*.js` / `*.mjs`: a per-file `strip-comments` pass on
      base vs. tip (e.g. for zig: tokenize + drop `//` and `///`/`//!`
      lines; for bp/ts/js: same plus `/* … */` blocks) yields a
      byte-identical result on every file the audit touched. Any file
      where the stripped diff is non-empty fails the gate and gets
      reverted to base.
- [ ] **Build still green**: `zig build` + `zig build test` + `zig
      build test-libs` + `botopink-lib-test` + (if `node` present)
      `npm test` in `vscode-extension/`. Comment-only edits must not
      change any output; the build is the bottom-line guard against
      an accidental semantic edit slipping through the strip-comments
      check.
- [ ] No `// TODO` / `// FIXME` / `// XXX` / `// HACK` / `// WIP`
      marker survives in any in-scope `*.zig` / `*.bp` / `*.d.bp` /
      `*.ts` / `*.js` / `*.mjs` file — unless paired with a permanent
      "(see spec X)" anchor explicitly whitelisted in the audit log.

## Test scenarios

```
inventory ---- find -name '*.md' / '*.zig' / '*.bp' / '*.d.bp' / '*.ts' / '*.js' / '*.mjs' over scope dirs matches the In scope list exactly
inventory ---- tasks/v0.beta.{1..18}/** is NOT visited by any step (immutability gate)
inventory ---- tasks/v0.beta.19/specs/*.md is NOT visited by any step (spec immutability)
orphans   ---- tasks/{parser-split,test-reorg,situacao}.md are deleted; commit body cites duplicates
orphans   ---- rg over the in-scope set finds zero references to the deleted orphans afterwards
stale     ---- no in-scope file references `.tasks/<slug>` workflow steps as live work outside .tasks/<active>/
stale     ---- no in-scope file documents *fn as live syntax (effect annotations replaced it)
stale     ---- no in-scope file claims pre-commit lives only in .git/hooks/ (recursive-test-gate updates the source of truth)
stale     ---- every "see #N" / "see commit X" anchor resolves (manual spot-check, recorded in audit log)
links     ---- every relative .md link in the in-scope set resolves to an existing file
comments  ---- no <!-- TODO --> / <!-- TBD --> / <!-- WIP --> survives in scope
comments  ---- every kept <!-- … --> is listed in the audit log with a "why kept" reason
markers   ---- no in-scope file has unresolved TODO/TBD/FIXME/WIP markers
language  ---- no in-scope file contains Portuguese prose (per the F3 grep set; allowed false positives reviewed by hand)
language  ---- every in-scope filename is English (situacao.md is deleted)
todo      ---- meta-root TODO.md references only the current set (v0.beta.19) and the rollup status.md
set       ---- tasks/v0.beta.19/README.md Scope table lists docs-audit-refresh
set       ---- tasks/v0.beta.19/status.md rollup row exists
edge      ---- audit log itself is NOT committed (it's a working artifact under .tasks/docs-audit-refresh/, not a contract)
edge      ---- a kept comment that future drift invalidates remains keep-flagged (the audit is a snapshot, re-run on the next sweep spec)
code      ---- no *.zig / *.bp / *.d.bp / *.ts / *.js / *.mjs file has a non-comment-line diff between base and tip (strip-comments invariant)
code      ---- no in-scope source file documents *fn as live syntax (matches the *.md sweep)
code      ---- no in-scope source file has unresolved TODO/FIXME/XXX/HACK/WIP markers (or each is paired with a permanent "see spec X" anchor whitelisted in the audit log)
code      ---- every .d.bp header citing a canonical Node/Erlang URL resolves (HTTP 200 spot-check, recorded in audit log)
code      ---- every JSDoc /** */ on an export still in `package.json` exports graph is kept; orphans are deleted
build     ---- `zig build` + `zig build test` + `zig build test-libs` + `botopink-lib-test` + (if node present) `npm test` in vscode-extension/ all green at the tip of task/docs-audit-refresh
build     ---- pre-commit recursive-test-gate (if landed) green on the integration merge
```

## Notes

- **Why one sweep spec instead of per-file edits as each frente lands?**
  The three frentes (A/B/C) and the two satellites (`prim-op-annotation`,
  `std-expansion`) each update **the AGENTS.md files they touch**
  (memory: `feedback_agents_md_maintenance.md`), but only at the
  blast-radius of their own code. Drift accumulated *before*
  v0.beta.19 — `*fn` rot from v0.beta.12, hook prose from before
  `recursive-test-gate`, Portuguese leakage from the 2026-06-02
  `situacao.md` snapshot — has no in-flight code change that would
  fix it as a side effect. One sweep spec, file-disjoint with the
  rest, closes it without contending for files with the active
  frentes.

- **Why hands-off on past sets?** `tasks/AGENTS.md` D9 makes them
  **immutable history**. Even an obvious typo in
  `v0.beta.5/specs/jhonstart.md` is left alone — they're a closed
  namespace, navigable as "what we thought at the time". Mutating them
  would erase the institutional record that the v0.beta.19 README
  itself relies on when it cites "the closing wave for v0.beta.{12, 14,
  16, 17, 18}".

- **Why hands-off on the open set's spec bodies?** `_TEMPLATE.md`
  preamble: "A spec is INTENT, written before building, IMMUTABLE
  once written." `tasks/AGENTS.md` D4 confirms the spec's `Status`
  field is intentionally coarse precisely because the live state lives
  in `TODO.md` + `status.md`. If a spec turns out to be wrong, the
  remedy is a follow-up spec in the next set, not a back-edit. This
  spec is itself bound by that rule the moment it lands.

- **Why include `_TEMPLATE.md` in scope?** It's level A (universal),
  shared by every future set. Drift here is amplified across every
  future spec author. Audit example: the preamble's "Remove these
  comments when done" line stays (it's instruction, not rot), but
  any phrasing that references discarded conventions is rewritten.

- **Why does the audit log live in `.tasks/docs-audit-refresh/`
  instead of the spec?** The audit log is **working state** (which
  files were keep / edit / delete; which comments were kept and why) —
  it informs the work, but it isn't a permanent contract. Committing
  it would either bloat the spec or create another stale file in the
  next cycle. The log lives next to the worktree's `TODO.md`, where
  the live state already lives by `tasks/AGENTS.md` D4 convention.

- **Why no rule about line counts or "max age"?** A doc isn't stale
  because it's old — `repository/AGENTS.md`'s workspace overview is
  several months old and still accurate. Stale means *contradicts
  current truth*, per the five-point operational definition above.
  Age is a heuristic, not the rule.

- **Cross-spec coordination.**
  - [`recursive-test-gate`](recursive-test-gate.md) lands new prose
    about `scripts/git-hooks/`; the F1 stale-reference sweep treats
    "pre-commit lives in `.git/hooks/`" as discarded **only after**
    `recursive-test-gate` lands. If this spec is integrated first,
    the relevant AGENTS lines retain a "(soon: see
    recursive-test-gate)" anchor until the gate lands; on its merge,
    those anchors are sharpened. (No race: both specs file-disjoint;
    the integration order picks the wording.)
  - [`std-expansion`](std-expansion.md) and
    [`prim-op-annotation`](prim-op-annotation.md) update
    `libs/std/src/{builtins,primitives}.d.bp` headers and may bump
    `repository/botopink-lang/libs/AGENTS.md`. Their AGENTS edits
    land via their own commits; this spec touches `libs/AGENTS.md`
    only to fix drift unrelated to their changes (orphan refs,
    stale workflow paths). Last-writer wins on a clean rebase.
  - [`frente-a-compiler`](frente-a-compiler.md) §S (the `*fn`
    deletion) is the source of truth for "no `*fn` anywhere". F1
    treats `*fn` documentation as discarded **regardless** of §S's
    landing order — the surface is already gone from v0.beta.12;
    §S only cleans up the parser path.

- **Re-run cadence.** Drift accumulates. One sweep per closing wave
  (v0.beta.{19, 22, …}) seems right; a future set can clone this
  spec into its own slug (`docs-audit-refresh-v0beta22`, etc.) when
  the next batch of frentes closes. This spec does **not** pre-author
  the recurrence — that's a v0.beta.(N+1) decision.
