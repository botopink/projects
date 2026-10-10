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
