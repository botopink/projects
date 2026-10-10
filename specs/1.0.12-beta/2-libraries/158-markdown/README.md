# Front 158 — markdown: the tree and its one consumer (396)

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
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

#### Step 3 — `markdown` (was `142-data-formats` s3)

- [x] onze-content's Markdown reader moves to `repository/markdown`, answering a tree of its own
      (`Heading`, `Paragraph`, `Emphasis`, `Strong`, `Code`, `CodeBlock`, `Link`, `Image`, `List`,
      `Quote`, …); it names no framework (113); its fixtures and tests move with it (690, both rows)
- [ ] onze-content maps the tree to jhonstart's `Element` (`element.toElement`, built; onze-content
      depends on `markdown` by git, 242; 31 tests left in onze-content, 721 with the library's, both rows) —
      **open:** "a node rendered by a component of the page's own where the page asks" (the hook's form is a
      question, `decisions-pending.md`)
- [x] `markdown`'s one consumer is the maintainer's exception to 115, stated in its `AGENTS.md` (396 (4))

**Gate:** standard (fronts.md § Gate) + every consumer's suite green on both rows after its import
commit · `grep -rn "pub mod json" repository/botopink-lang/libs/std/src/root.bp` empty
