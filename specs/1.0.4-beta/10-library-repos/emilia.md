# emilia — no gate at all (7d)

> Carried from `1.0.2-beta/12-library-repos/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Paths are relative to `repository/`.

**Blocks:** nothing compiles wrong today (`check` passes, `test` 17/17) — but nothing would stop it
from doing so. That is exactly how the escaped-markdown source (`#\[@External\.node(`) shipped.

---

## Deciding site

emilia's top level: `src/ examples/ AGENTS.md CHANGELOG.md README.md docs.md botopink.json
.gitignore`. There is no `scripts/`, no `.github/`, and no `test/`.

Every other code repo in the workspace ships a `scripts/git-hooks/pre-commit` plus
`scripts/git-hooks/lib/`, and a `.github/workflows/test.yml`:

| Repo | tracked hook source | `.github/workflows/` | installed `pre-commit` (maintainer's meta checkout, measured 2026-09-16) |
|---|---|---|---|
| erika, jhonstart, onze, rakun, vscode-extension | yes | yes | yes — a symlink in `meta:.git/modules/repository/<repo>/hooks/` that resolves to the tracked script |
| botopink-lang | yes | yes | **no** — the checkout uses its own `.git/` directory, whose `hooks/` holds only samples |
| **emilia** | **no** | **no** | no |

A fresh clone of any repo installs no hook: `core.hooksPath` is unset everywhere, and the documented
installer, `scripts/install-hooks.sh`, exists in no repo. See
[`../09-hygiene/decisions.md`](../09-hygiene/decisions.md) item 5.5.

`emilia/AGENTS.md` has no "## Local gate" section — only "## Test surface" (`:137-153`), which
declares 17 in-file tests (`:139-140`) plus 4 in `examples/emilia-card/` (`:150-151`) and nothing
that enforces them.

## Mechanism

With no hook source and no workflow, a commit in emilia runs nothing locally and nothing in CI.
A source file can carry markdown escapes, fail to parse, and still be committed and pushed.

Fixing emilia's missing *source* without fixing the install path leaves the gate
red-by-omission: the file exists but nothing runs it on a fresh clone, in emilia or in any sibling.
The install-path answer is [`../09-hygiene/decisions.md`](../09-hygiene/decisions.md) 5.5 (b), and
it is a precondition for this step's second acceptance row.

## Fix — in emilia

1. Copy the sibling `scripts/git-hooks/` pair (`pre-commit` and `lib/runner-standalone.sh` — the
   six existing copies of `pre-commit` are byte-identical), taking whatever change 5.5 (b) makes to
   the meta-delegation branch at `pre-commit:12-17`.
2. Add a `.github/workflows/test.yml` matching the siblings', with the `BOTOPINK_LANG_REF` default
   settled in `vscode-extension.md` (1.0.2-beta library-repos, landed) 7g.
3. Add the "## Local gate" section to `AGENTS.md`, with the install command 5.5 (b) chooses.
4. Make the gate run the 21 tests `AGENTS.md` already claims (17 in `src/`, 4 in
   `examples/emilia-card/`).

## Acceptance

- [ ] emilia has a tracked hook source and a CI workflow matching its siblings
- [ ] Every sibling library's pre-commit hook is installable by a documented command and passes
- [ ] The gate would reject a source file carrying markdown escapes
