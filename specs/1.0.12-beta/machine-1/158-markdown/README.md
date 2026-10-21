# Front 158 — markdown: the tree and its one consumer (396)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `markdown` — worktree `--repo markdown` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/markdown/**`; onze-content's mapping (consumer commit)
**Depends on:** 151 s1 (if `Json` crosses) · 144 B-02 (consumer commit)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `142-data-formats` s3 | 158 s1 |

## Steps

### 158 s1 — onze-content maps the tree (142 s3)

**Repository:** `markdown`, and the consumer commits it names in their repositories (a full worktree, decision 188) · **Model:** sonnet

#### Step 3 — `markdown` (was `142-data-formats` s3)

- [x] onze-content's Markdown reader moves to `repository/markdown`, answering a tree of its own
      (`Heading`, `Paragraph`, `Emphasis`, `Strong`, `Code`, `CodeBlock`, `Link`, `Image`, `List`,
      `Quote`, …); it names no framework (113); its fixtures and tests move with it (690, both rows)
- [ ] rakun-ssr's content maps the tree to rakun-bpp's `Element` (`element.toElement`, built; the content
      depends on `markdown` by git, 242; 31 tests left in the content, 721 with the library's, both rows) —
      **open:** "a node rendered by a component of the page's own where the page asks" (the hook's form is a
      question, `decisions-pending.md`)
- [x] `markdown`'s one consumer is the maintainer's exception to 115, stated in its `AGENTS.md` (396 (4))

**Gate:** standard (fronts.md § Gate) + every consumer's suite green on both rows after its import
commit · `grep -rn "pub mod json" repository/botopink-lang/libs/std/src/root.bp` empty

### 158 Conformance — the front's last step (decision 465)

**Repository:** markdown (`--repo markdown`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `markdown/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

