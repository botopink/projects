# Front 157 — routing: Astro's routing in `segment.bp` / `conventions.bp` (117, routing's half)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `routing` — worktree `--repo routing` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/routing/src/{segment.bp, conventions.bp, match.bp}` and their tests
**Depends on:** 102 done · 144 B-20 (330 codemod, a consumer commit)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

117's other halves (rakun-app's `static_gen.bp`, onze's `paginate.bp` and `scan.bp`) are 150 s63's; this front
lands first (producer).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `117-bpp-routing` s0 box 2 | 157 s1 |
| `117-bpp-routing` s1 box 1 | 157 s1 |
| `117-bpp-routing` s5 | 157 s1 |
| `117-bpp-routing` gate | 157 s1 |

## Steps

### 157 s1 — the app-file kinds, two parameters in a segment, the priority rules (117)

**Repository:** `routing` (`--repo routing`) · **Model:** sonnet

#### Step 0 — Measure — part (was `117-bpp-routing` s0 box 2)

- [ ] the reference's eight priority rules, each a `match_test.bp` case over a two-route table —
      failures are step 5's list

#### Step 1 — `.bpp`, `.md` and `.html` as app files (a page takes no parameter: 293) — part (was `117-bpp-routing` s1 box 1)

- [ ] `routing.conventions.classify` answers kind and form for the four extensions; rakun-app and
      onze-cli read it (after 102)

#### Step 5 — Two parameters in a segment, and the priority rules (was `117-bpp-routing` s5)

- [ ] `[lang]-[version]` parses to two parameters with a literal between; `/en-v1/info` binds
      both; touching parameters (`[a][b]`) refused
- [ ] eight rules green in `match_test.bp`; rule 6 ("an endpoint over a page") stays a scan refusal, asserted as one

#### Gate additions (was `117-bpp-routing` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `repository/routing`, on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun green; `rakun-ssr/examples/blog` builds unchanged

### 157 Conformance — the front's last step (decision 465)

**Repository:** routing (`--repo routing`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `routing/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

