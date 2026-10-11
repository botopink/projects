# Front 161 — vscode-extension: `.bpp` registered

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
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

#### Step 4 — The span mapping and the editor — part (was `116-bpp-file-format` s4 box 3)

- [ ] `vscode-extension`: `.bpp` registered; `zig build test-vscode` green

### 161 Conformance — the front's last step (decision 465)

**Repository:** vscode-extension (`--repo vscode-extension`) · **Model:** opus

After every other step of this front has landed.

- [ ] `botopink cell check conformance/` — every cell of `vscode-extension/conformance/` green on the targets the manifests declare
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477): the runs on `feat` since the front's base green, or each red named and fixed or filed
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

