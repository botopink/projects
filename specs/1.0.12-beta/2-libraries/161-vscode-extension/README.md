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
