# Front 161 — vscode-extension: `.bpp` registered

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `vscode-extension` — worktree `--repo vscode-extension` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/vscode-extension/**`
**Depends on:** 144 B-27 (116's botopink-lang half)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `116-bpp-file-format` s4 box 3 | 161 s1 |

## Steps

### 161 s1 — `.bpp` in the editor (116 s4)

**Repository:** `vscode-extension` (`--repo vscode-extension`) · **Model:** sonnet

#### Step 4 — The span mapping and the editor — part (was `116-bpp-file-format` s4 box 3)

- [ ] `vscode-extension`: `.bpp` registered; `zig build test-vscode` green

### 161 Conformance — the front's last step (decision 465)

**Repository:** vscode-extension (`--repo vscode-extension`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `vscode-extension/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

