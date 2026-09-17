# Decisions — not work (5.9, 5.5)

> Carried from `1.0.2-beta/11-hygiene/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

These two do not have a smallest fix; they have an answer someone has to give. Nothing in their
groups can close until they do. Paths are relative to `repository/` unless they start with
`meta:`.

The workspace is **eight** git repositories: the meta repo, `botopink-lang`, and six library repos
(`emilia`, `erika`, `jhonstart`, `onze`, `rakun`, `vscode-extension`). "Every repo" below means
all eight unless a row says otherwise.

---

## 5.9 — the license

### Facts

| | |
|---|---|
| Claim | `botopink-lang/README.md:74` says `MIT` |
| Files | No `LICENSE` file in **any** repo (`find -maxdepth 3 -iname 'LICENSE*'` over the workspace returns nothing) |
| Extension | `vscode-extension/package.json` has no `license` field (211 lines; keys run `name … dependencies`, no `license`), so `vsce package` warns and the Marketplace listing shows none |
| Siblings | Each sibling README carries a License section with no file behind it |

### Options

| Option | What it implies |
|---|---|
| **MIT everywhere** (what `botopink-lang/README.md:74` already says) | One `LICENSE` text copied into every repo; `"license": "MIT"` in `vscode-extension/package.json`; the sibling README sections become true as written. Smallest change, no README edits |
| **One license, but not MIT** | Same file in every repo, plus rewriting `botopink-lang/README.md:74` and every sibling README's License section |
| **Different licenses per repo** (e.g. the compiler and the libraries apart) | Each repo gets its own `LICENSE`, and each README's License section is re-checked individually. The libraries ship code into user programs (`std`, `erika`, `jhonstart`, `rakun`, `onze`, `emilia` are compiled into consumers), so a copyleft choice there binds consumers in a way it would not for the compiler or the extension |
| **Leave it undecided** | The extension stays published unlicensed; the README claim stays unbacked |

**Decided 2026-09-17 by the maintainer: MIT in every repo, `Copyright (c) 2026 Eric Fillipe and botopink contributors`.**

**Decide:** the license, and whether every repo takes the same one. Then add `LICENSE` to every
repo and `"license"` to the extension's `package.json`. Until it is decided, the extension is
published unlicensed.

## 5.5 — whether the meta repo needs a gate, and how a hook gets installed

Two separable questions.

### Facts

| | |
|---|---|
| Hook source | `scripts/git-hooks/pre-commit` exists in `botopink-lang`, `erika`, `jhonstart`, `onze`, `rakun` and `vscode-extension` (23 lines, byte-identical), plus `scripts/git-hooks/lib/runner-standalone.sh`. **emilia has neither** ([`../10-library-repos/emilia.md`](../10-library-repos/emilia.md)) |
| Delegation | `pre-commit:12-17` prefers `$META_ROOT/scripts/git-hooks/lib/test-runner.sh`; `meta:scripts/` does not exist, so the branch is dead and `:21-22` always takes the standalone fallback. `runner-standalone.sh:2-4` still calls itself a mirror of `botopink/projects'` runner, and `pre-commit:5` calls the meta workspace a "worktree of botopink/projects" — a repo that is not in this workspace |
| `core.hooksPath` | Unset in the meta repo and in every submodule |
| Installed hooks (local state of the maintainer's checkout, measured 2026-09-16) | Submodule git dirs live under `meta:.git/modules/repository/<repo>/`, not in `<repo>/.git/hooks/`. There, `erika`, `jhonstart`, `onze`, `rakun` and `vscode-extension` each have `hooks/pre-commit` as a symlink to `../../../../../repository/<repo>/scripts/git-hooks/pre-commit`, and all five **resolve** to the tracked, executable script. `emilia`'s hooks dir holds only samples. `botopink-lang` is checked out with its own `repository/botopink-lang/.git/` **directory**, whose `hooks/` holds only samples — the symlink that exists for it, `meta:.git/modules/repository/botopink-lang/hooks/pre-commit`, sits in a git dir that checkout does not use |
| meta | `meta:.git/hooks/pre-commit` is a **dangling symlink** to `../../scripts/git-hooks/pre-commit`, beside a stale `pre-commit.bak.20260614-175956`. Meta commits run no gate |
| How they got there | All symlinks are dated 2026-06-14 — the same day as the `.bak` — i.e. installed once by a script that no longer exists. A fresh clone gets none of them |
| Documented install path | `scripts/install-hooks.sh`, which exists in no repo. The meta repo has no `scripts/`. Measured 2026-09-16, five `AGENTS.md` point at it: `erika/AGENTS.md:245, 250`, `jhonstart/AGENTS.md:145, 150`, `onze/AGENTS.md:141, 146`, `rakun/AGENTS.md:159, 164`, `vscode-extension/AGENTS.md:231` |

Whether "the hooks are installed" is true depends on the clone, not on HEAD: in the maintainer's
meta checkout the five siblings above run their standalone gate on commit, so a red hook does block
commits in jhonstart, onze, rakun, erika (and vscode-extension); `botopink-lang` and `emilia` run
none, and a fresh clone of any repo runs none. Nothing tracked installs a hook — that is the gap
(b) closes.

### Decide (a) — does the meta repo need a pre-commit gate?

**Decided 2026-09-17 by the maintainer: no gate.** The dangling `meta:.git/hooks/pre-commit` and
`pre-commit.bak.20260614-175956` were deleted the same day.

It holds no code — only submodule pointers and `specs/`.

| Option | What it implies |
|---|---|
| **No gate** (recommended — nothing in the meta repo compiles) | Delete `meta:.git/hooks/pre-commit` and `pre-commit.bak.20260614-175956`. Meta commits stay ungated, which is the state today |
| **A specs-only gate** | The gate has to be something a specs-only repo can run: link checking across `specs/`, a check that every submodule pointer is a commit reachable on its remote. It needs a tracked source under `meta:scripts/` and an install instruction in `meta:AGENTS.md` |
| **A gate that runs the submodules' suites** | Recreates the dead delegation the six hooks already carry. Every meta commit then costs a full `zig build test` plus every library's tests, for a repo whose commits are pointer bumps |

### Decide (b) — is the hook self-contained per repo, or does a shared runner come back?

**Decided 2026-09-17 by the maintainer: self-contained per repo.** Each repo carries its own
`scripts/git-hooks/` and documents `git config core.hooksPath scripts/git-hooks`; the dead meta
delegation goes from every hook; emilia receives the same pair ([`../10-library-repos/`](../10-library-repos/README.md) step 2).

Everything today points at a meta script that does not exist.

| Option | What it implies |
|---|---|
| **Self-contained per repo** (recommended — the smaller change) | Drop the `pre-commit:12-17` meta branch in all six repos that carry the hook, fix the `runner-standalone.sh:2-4` header, and document `git config core.hooksPath scripts/git-hooks` in each `AGENTS.md` §Local gate. emilia receives the same pair. A standalone clone and a meta checkout behave the same |
| **A shared runner in the meta repo** | Create `meta:scripts/git-hooks/lib/test-runner.sh` and `meta:scripts/install-hooks.sh`, keep the fallback for standalone clones, and keep two runners in sync forever. The byte-identical copies stay a drift risk |

Either answer is a precondition for
[`../10-library-repos/emilia.md`](../10-library-repos/emilia.md): giving emilia the hook source its
siblings have does not give it a gate, because nothing tracked installs a hook — a fresh clone of
any sibling runs none either.

## Acceptance

- [ ] `LICENSE` in every repo; `"license"` in `vscode-extension/package.json`
- [ ] `git config core.hooksPath scripts/git-hooks` (or the chosen equivalent) documented in every
      repo's `AGENTS.md`, and the hook demonstrably runs after following it
- [ ] `meta:.git/hooks/pre-commit` either resolves or is gone
- [ ] No script or `AGENTS.md` references `meta:scripts/` or `botopink/projects`
