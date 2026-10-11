# Front 147 — css: the base for building CSS

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `css` — worktree `--repo css` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
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

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `css/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

