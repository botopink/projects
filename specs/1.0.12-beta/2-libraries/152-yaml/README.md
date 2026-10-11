# Front 152 — yaml: one YAML subset into `Json` (396)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `yaml` — worktree `--repo yaml` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/yaml/**`; rakun's `config.bp` YAML subset (deleted), onze-content's frontmatter read (consumer commits)
**Depends on:** 151 s1
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `142-data-formats` s2 | 152 s1 |

## Steps

### 152 s1 — `yaml` and its two consumers (142 s2)

**Repository:** `yaml`, and the consumer commits it names in their repositories (a full worktree, decision 188) · **Model:** sonnet

#### Step 2 — `yaml` (was `142-data-formats` s2)

- [ ] `repository/yaml` reads one YAML subset into `json`'s `Json`: block and flow mappings and
      sequences, plain / quoted / block scalars, comments; an anchor, an alias, a tag and a second
      document each `Error` naming the line (67), never read as something else
- [ ] rakun's `config.bp` reads `.yaml` / `.yml` through it and deletes its own subset (after
      `04-rakun/128`); its config tests unchanged
- [ ] `08-bpp/121` step 3's frontmatter reads through it (no copy in onze-content)

### 152 Conformance — the front's last step (decision 465)

**Repository:** yaml (`--repo yaml`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `yaml/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

