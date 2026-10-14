# Front 105 — i18n: a shared `i18n`, one locale grammar for the server and the page

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Repository:** `i18n` (`botopink/i18n`, born in s1) — worktree `--repo i18n`; s2's consumer commits (rakun-app, jhonstart, validation) run in a full worktree, producer first (decision 188)
**Model:** sonnet — the README fixes the design (`AGENTS.md` § Which model a thread runs on); the Conformance step opus
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** `repository/i18n/**` when born (`botopink/i18n`), the consumer lines step 2 names.
**Depends on:** 155 s2 (104 s5) · rakun 150 s13 (22) · jhonstart 150 s36 · `03r-q` confirmed. Goal and mechanism:
[`03-bundled-libs/105-i18n`](105-i18n/context.md).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `105-i18n` s1 | 105 s1 |
| `105-i18n` s2 | 105 s2 |

## Steps

### 105 s1 — the package

**Repository:** `i18n` (`--repo i18n`) · **Model:** sonnet

#### Step 1 — the package (was `105-i18n` s1)

- `LocaleSet`; `wellFormedTag` / `normalizeTag` / `isSupported` under decision 180 (language 2–3
  letters, optional script 4, optional region 2 letters or 3 digits; case normalised; else refused)
- `negotiate(set, acceptLanguage, cookieValue) -> ?string` (pure, over
  `http.accept.parseAcceptLanguage`)
- `localeOfPath` / `stripLocale` / `withLocale`, `alternatesFor`
- `interpolate(template, bindings)` (moved from validation, which then declares `i18n` in `dependencies` —
  a package-to-package edge like `actions` → `routing`)
- **No plural rules** (none today, none invented). No name std or a framework exports (decision
  163, checked against `libs/std/src/root.bp` and each framework's root).

- [ ] `repository/i18n/test/tag_test.bp`: `zh-Hant-TW`, `pt-BR`, `en-419` accepted and normalised;
      `x-private`, `en-US-u-ca-gregory` refused; both rows
- [ ] `negotiate` known-answers over RFC 4647 basic filtering examples

### 105 s2 — consumers

**Repository:** rakun-app, jhonstart, validation — the consumer commits, a full worktree (decision 188) · **Model:** sonnet

#### Step 2 — consumers (was `105-i18n` s2)

- [ ] rakun-app keeps only its registry, filter, cookie and loader; generic half deleted
- [ ] jhonstart `isLangTag` deleted; `render.bp` imports `i18n.wellFormedTag`
- [ ] validation's `interpolate` deleted; `messages.bp` imports `i18n.interpolate`; validation's
      tests unchanged

### 105 Conformance — the front's last step (decisions 465, 474, 477, 478, 479, 480)

**Repository:** i18n (`--repo i18n`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `i18n/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

**Gate:** standard (fronts.md § Gate) + `repository/i18n/AGENTS.md` written
