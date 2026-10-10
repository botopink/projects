# Front 151 — json: std's `json.bp` as a repository of its own (396)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
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

#### Step 1 — `json` leaves std — part (was `142-data-formats` s1 box 3)

- [ ] the consumers declare `{ "json": { "git": "https://github.com/botopink/json.git", "branch": "feat" } }`
      and import `from "json"`, one commit per library (188): validation, actions, log, jhonstart, onze,
      rakun (after `04-rakun/128`); each library's suite green unchanged
