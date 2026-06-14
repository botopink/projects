# TODO — docs-audit-refresh (v0.beta.19)

> Branch: `task/docs-audit-refresh` · Worktree: `.tasks/docs-audit-refresh/`
> Spec: [`tasks/v0.beta.19/specs/docs-audit-refresh.md`](tasks/v0.beta.19/specs/docs-audit-refresh.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Edit docs/comments **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).
>
> **Comments-only invariant** for `*.zig` / `*.bp` / `*.d.bp` / `*.ts` /
> `*.js` / `*.mjs`: every diff hunk must be comment lines. Verified by F6.

## Immutability boundary — DO NOT TOUCH

- `tasks/v0.beta.{1..18}/**` (frozen sets — tasks/AGENTS.md D9)
- `tasks/v0.beta.19/specs/*.md` (open-spec bodies — tasks/AGENTS.md D6)
- `zig-out/` · `.zig-cache/` · `node_modules/` · `repository/vscode-extension/out/`
  (unless tracked + hand-authored) · `libs/**/dist/`

## F0 — orphan triage (`tasks/` root)

- [ ] `git rm tasks/parser-split.md` (duplicate of `v0.beta.1/specs/parser-split.md`)
- [ ] `git rm tasks/test-reorg.md` (duplicate of `v0.beta.1/specs/test-reorg.md`)
- [ ] `git rm tasks/situacao.md` (2026-06-02 snapshot — git log + per-set
      status.md are authoritative; filename violates English-only rule)
- [ ] Verify no in-scope file references those 3 paths
      (`rg -F 'tasks/parser-split.md|tasks/test-reorg.md|tasks/situacao.md' --type md`)

## F1 — stale-reference sweep (per-file *.md audit)

- [ ] Build inventory of in-scope `*.md` (see spec "In scope — mutable")
- [ ] Per file, apply the five-point operational definition (syntax /
      path / command / supersession / contradiction)
- [ ] Produce `audit-md.log` (per-file: keep / edit / delete)
- [ ] Apply edits; anchor each rewrite to current truth with link to
      the v0.beta.N spec that landed the change
- [ ] Re-run `rg -o '\[.*?\]\(([^)]+\.md[^)]*)\)' --replace '$1'` and
      `ls` every link target — broken links become sub-task fixes

## F2 — HTML-comment + editorial-marker sweep (*.md only)

- [ ] `rg -F '<!--' --type md` over in-scope set → per-occurrence decision
- [ ] `rg -i '\b(TODO|TBD|FIXME|WIP|XXX)\b' --type md` over in-scope set
      → resolve each (shipped → strike; dropped → delete or pivot;
      still open → link to open spec)

## F3 — English-only sweep (*.md only)

- [ ] `rg -i '\b(situação|situacao|português|portugues|levantamento|atualiz|conclu|MESCLAD|PUSHED|verde|vermelho|ativ|inativ)\b' --type md`
      → translate or delete (false positives reviewed by hand)
- [ ] Every in-scope filename is English

## F4 — refresh meta-root `TODO.md`

- [ ] Replace body with: 1-line pointer to `tasks/v0.beta.19/status.md` +
      pending list for v0.beta.19 only (from README Scope table)
- [ ] Delete any claim about v0.beta.{<19} pending work

## F4a — `*.zig` comment sweep (comments-only)

- [ ] Inventory: `rg -n '^[[:space:]]*(//|///|//!)' --type zig` over
      `repository/botopink-lang/src/**`, `modules/**`, workspace
      `build.zig*` → `audit-zig-comments.log`
- [ ] Per file, five-point definition against comment lines only
- [ ] Edit: drop discarded-surface refs (`*fn`, retired AST nodes),
      missing paths, resolved TODOs, closed FIXMEs
- [ ] Keep + sharpen comments that explain *why* (non-obvious
      invariants, workarounds, surprising behavior). One short line max.
- [ ] **Zero semantic edits**: every diff hunk is comment lines

## F4b — `*.bp` / `*.d.bp` comment sweep (comments-only)

- [ ] Inventory: `rg -n '^[[:space:]]*(//|/\*)' --type-add 'bp:*.bp' --type-add 'dbp:*.d.bp' --type bp --type dbp`
      over `repository/botopink-lang/libs/**` + every sibling lib's
      `libs/**` + example dirs → `audit-bp-comments.log`
- [ ] Watchouts: `*fn` examples (discarded v0.beta.12); `.d.bp`
      headers citing canonical Node/Erlang URLs (keep + verify HTTP 200);
      `// TODO` naming v0.beta.{<19} as the resolver (closed)
- [ ] Keep + sharpen `interface`/`template` body comments encoding
      mock/sigil semantics (`$self`, `$0..N`, `$argc`, `when($argc==N)`)
- [ ] **Zero semantic edits**

## F4c — `*.ts` / `*.js` / `*.mjs` comment sweep (comments-only)

- [ ] Inventory: `rg -n '^[[:space:]]*(//|/\*|\*)' --type ts --type js`
      over `repository/vscode-extension/{src,test}/**` + every tracked
      `*.mjs`/`*.js` sidecar under `libs/**/src/` → `audit-ts-js-comments.log`
- [ ] JSDoc `/** … */`: keep when export still in `package.json` exports
      graph; delete orphaned blocks
- [ ] `// TODO` naming closed tasks → delete or pivot to
      "(landed in vN — see spec link)"
- [ ] `console.log` / `console.warn` debug breadcrumbs: out of scope
      (audit log records sightings only)
- [ ] **Zero semantic edits**

## F5 — set-level updates (`tasks/v0.beta.19/`)

- [x] Add row to `tasks/v0.beta.19/README.md` Scope table + Order block
      (done in initial spec commit)
- [x] Add rollup row to `tasks/v0.beta.19/status.md`
      (done in initial spec commit)

## F6 — verification gate

- [ ] `rg -F '<!--' --type md repository/ scripts/ tasks/AGENTS.md tasks/_TEMPLATE.md tasks/v0.beta.19/{README,plan,status}.md`
      returns only audit-whitelisted comments
- [ ] No `<!-- TODO -->`-style markers remain in scope
- [ ] No link in the in-scope `*.md` set resolves to a missing file
- [ ] `git grep -l 'situacao\|tasks/parser-split.md\|tasks/test-reorg.md'`
      finds only the F0 deletion commit's own body + the immutable
      `v0.beta.1/specs/{parser-split,test-reorg}.md`
- [ ] Spot-check 5 sample files end-to-end: root `AGENTS.md` ·
      `repository/AGENTS.md` · `repository/botopink-lang/AGENTS.md` ·
      `repository/erika/docs.md` · `tasks/AGENTS.md`
- [ ] **Strip-comments invariant**: per-file `strip-comments` pass on
      base vs. tip yields byte-identical result for every `*.zig` /
      `*.bp` / `*.d.bp` / `*.ts` / `*.js` / `*.mjs` the audit touched
- [ ] `zig build` + `zig build test` + `zig build test-libs` +
      `botopink-lib-test` + `npm test` (vscode-extension) all green
- [ ] No surviving `// TODO`/`FIXME`/`XXX`/`HACK`/`WIP` in any
      in-scope code file (unless whitelisted with permanent
      "(see spec X)" anchor)

## Integration

- [ ] All checks above ticked
- [ ] AGENTS.md updated everywhere the audit edited (memory rule —
      AGENTS sempre atualizado)
- [ ] Sweep submodule feat heads (memory: feat remotas sempre unificadas)
- [ ] Integrate into feat via throwaway `.tasks/_integrate-docs-audit-refresh/`
      worktree (per repository/botopink-lang AGENTS.md "Parallel tasks
      (git worktrees)" workflow)
- [ ] Push over SSH (memory: sempre SSH no git)
- [ ] Update `tasks/v0.beta.19/status.md` row to **merged+pushed**
- [ ] Remove worktrees and prune
