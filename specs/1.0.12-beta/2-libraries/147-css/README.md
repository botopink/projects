# Front 147 — css: the base for building CSS

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/css/**`
**Depends on:** nothing open
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

No open step of its own after 119 step 1 (decision 338, its css half done). It receives consumer commits only:
144 B-20 (the 330 codemod, if a site exists), B-28 (the `;` migration and the reformat). Runs before styled (148).

### 147 Conformance — the front's last step (decision 465)

**Repository:** css (`--repo css`) · **Model:** opus

After every other step of this front has landed.

- [ ] `botopink cell check conformance/` — every cell of `css/conformance/` green on the targets the manifests declare
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows

