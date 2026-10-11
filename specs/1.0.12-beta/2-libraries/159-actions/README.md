# Front 159 — actions: `id` done; consumer commits only

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/actions/**`
**Depends on:** nothing open
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

103 steps 1–2 are done; its one open box (the action secret from rakun-app's `#[config]` record) is rakun's
(150 s2). The typed action shape is rakun's (150 s23, 127). It receives consumer commits only: 144 B-20 (the 330
codemod), B-28 (the `;` migration and reformat), 151 s1 (`json`). Its gate line stands:
`repository/actions/AGENTS.md` names `id`.

### 159 Conformance — the front's last step (decision 465)

**Repository:** actions (`--repo actions`) · **Model:** opus

After every other step of this front has landed.

- [ ] `botopink cell check conformance/` — every cell of `actions/conformance/` green on the targets the manifests declare
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477): the runs on `feat` since the front's base green, or each red named and fixed or filed
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

