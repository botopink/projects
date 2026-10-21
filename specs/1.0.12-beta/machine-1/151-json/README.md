# Front 151 — json: std's `json.bp` as a repository of its own (396)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `json` — worktree `--repo json` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/json/**`; the consumers' dependency and import lines (decision 188)
**Depends on:** 144 B-27 (142 s1's std half: the move out of std)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Then 97 s15's `Json` numbers (144 B-24, question `97-s15-a`) and 05-wasm s5's `json` cell (B-00e).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `142-data-formats` s1 box 3 | 151 s1 |

## Steps

### 151 s1 — the consumers import `from "json"` (142 s1)

**Repository:** `json`, and the consumer commits it names in their repositories (a full worktree, decision 188) · **Model:** sonnet

#### Step 1 — `json` leaves std — part (was `142-data-formats` s1 box 3)

- [ ] the consumers declare `{ "json": { "git": "https://github.com/botopink/json.git", "branch": "feat" } }`
      and import `from "json"`, one commit per library (188): validation, actions, log, jhonstart, onze,
      rakun (after `04-rakun/128`); each library's suite green unchanged
- [x] 941: `Json.isString()` beside `isObject` travels with the type (written in std's `json.bp` until this step moves it); cell `json_is_string`, four targets — landed (`conformance/modules/std/cells/json_is_string`; rakun-ssr's half is 150 s59's)

### 151 Conformance — the front's last step (decision 465)

**Repository:** json (`--repo json`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `json/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

