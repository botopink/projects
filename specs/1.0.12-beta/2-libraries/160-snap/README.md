# Front 160 — snap: the snapshot engine; consumer commits only

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/snap/**`
**Depends on:** nothing open
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

135 s0 is done (391). The snapshot steps write through it in their own repositories: std 144 B-27 (135 s1),
rakun 150 s24, jhonstart 149 s10, emilia 154 s4, onze 162 s10; the coordination is 3-medium/135-snap. It receives
consumer commits only: 144 B-08 (17 sites), B-20, B-28.

### 160 Conformance — the front's last step (decision 465)

**Repository:** snap (`--repo snap`) · **Model:** opus

After every other step of this front has landed.

- [ ] `botopink cell check conformance/` — every cell of `snap/conformance/` green on the targets the manifests declare
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the GitHub pipeline read (474): the runs on `feat` since the front's base green, or each red named and fixed or filed

