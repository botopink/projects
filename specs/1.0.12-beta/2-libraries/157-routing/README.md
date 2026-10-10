# Front 157 — routing: Astro's routing in `segment.bp` / `conventions.bp` (117, routing's half)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/routing/src/{segment.bp, conventions.bp, match.bp}` and their tests
**Depends on:** 102 done · 144 B-20 (330 codemod, a consumer commit)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

117's other halves (rakun-app's `static_gen.bp`, onze's `paginate.bp` and `scan.bp`) are 162 s5's; this front
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
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `onze/examples/blog` builds unchanged
