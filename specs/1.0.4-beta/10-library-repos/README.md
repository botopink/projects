# Front 10 — library repos

**Priority:** medium — erika and emilia are the two libraries whose own work is unfinished; the rest
is one default string per repo and one export the rakun bootstrap needs
**Status:** carried from 1.0.2-beta front 12, whose rakun (7a), vscode-extension (7e, 7f, 7g) and
bpmp (7h) items landed — see [Delivered](#delivered-by-102-beta-library-repos)
**Depends on:** the `libs/std` `String.split("")` fix for erika (**landed**, `botopink-lang` `c8c2541`) — the commit of 7c; its compiler
half, 7b, landed with 1.0.4-beta erlang (`42429dc`), and the fix has no owner ([`../fronts.md`](../fronts.md#unowned-items));
[`../09-hygiene/decisions.md`](../09-hygiene/decisions.md) item 5.5 for emilia (7d). The
`BOTOPINK_LANG_REF` defaults can land at any time
**Owns:** `repository/erika/**` · `repository/emilia/**` · the one-line `BOTOPINK_LANG_REF` default
in `repository/{jhonstart,onze}/.github/workflows/test.yml` — one commit per repo
**Does not touch:** `modules/compiler-core/**` (rakun's missing export is a codegen fix — see
step 4) · `libs/std/**` ·
`modules/compiler-cli/**`, `build.zig`, `scripts/**` ([`../05-cli-residuals/`](../05-cli-residuals/README.md))
· `repository/jhonstart/**` and `repository/onze/**` beyond the one line ·
`repository/rakun/**` and `repository/vscode-extension/**` (delivered; no open item edits them)

Paths are relative to `repository/`, except where they name the compiler (`botopink-lang/…`).
Inside a per-repo file, bare paths are relative to that repo.

---

## Delivered by 1.0.2-beta library-repos

| Item | What landed |
|---|---|
| 7a rakun | the phantom `server` dependency dropped; the node `http` transport vendored as `serve` in `runtime.mjs` / `rkServe` in `runtime.bp`; `"target": "commonJS"` added. `botopink test` 17/17 |
| 7e vscode-extension | retired snippets (`*fn`, `struct`, the garbled `external`) replaced or dropped; grammar drops `struct`/`const`/`*fn`, adds `is` |
| 7f vscode-extension | `TEST_TARGETS` + `testTargetFor` in `targetConfig.ts`; Test Explorer, CodeLens and the `test` task gated |
| 7g vscode-extension (+ rakun) | a CI `compiler` job (`BOTOPINK_LANG_REF \|\| 'feat'`) running `scripts/compilerCheck.ts`; rakun's default flipped to `feat` |
| 7h bpmp | the resolver probes the store (`--frozen` miss → `DEP-005 FrozenStoreMiss`); `Action.ref` carries branch/tag/rev with hermetic git tests; `sync` resolves from each dep's `git:`. `zig build test-bpmp` 108/108 |

## Problem

| Repo | Open item | Blocked by | Deep dive |
|---|---|---|---|
| erika | **7b** — the two-parameter `loop` lost its accumulator. **Compiler fix landed** (1.0.4-beta erlang); verify in erika | — | [`erika.md`](./erika.md) |
| erika | **7c** — `AGENTS.md` documents a removed comptime evaluator. **Written and staged**, uncommitted: erika's hook runs `botopink test`, red on `libs/std`'s `String.split("")` | the `libs/std` fix (unowned) | [`erika.md`](./erika.md) |
| erika | stale comments in `src/erika.bp` that still describe the removed evaluator and the pre-1.0.2 `libs/std` layout | — | — |
| emilia | **7d** — no hook source, no CI; nothing enforces the tests `AGENTS.md` declares | hygiene 5.5 | [`emilia.md`](./emilia.md) |
| jhonstart, onze | the `BOTOPINK_LANG_REF` default in CI still names `main`, which lags `feat` (the last two of five) | — | — |
| rakun | `botopink build` emits no `module.exports` for rakun's records: the emitted `bootstrap.js` does not export `Rakun`, so a consumer cannot `require` it | **probably closed** by 1.0.4-beta js-bridges (`aa02bb4`: every pub enum and record emits `exports.Name = Name;`) — step 4 verifies | — |

The library gate (`zig build test-libs`, 2026-09-17, `botopink-lang` `ed15323`): emilia, onze,
rakun and `libs/std` pass; erika (commonJS + erlang) and jhonstart (commonJS) are known-red on one
`libs/std` line, `String.split("")` binding `string:split/3` with an empty separator ([`../fronts.md`](../fronts.md#unowned-items)).
Patched locally, erika passes 31/31 on both targets and jhonstart 8/8.

## Steps

### Step 1 — erika: verify 7b, commit 7c (7b · 7c)

After the `libs/std` `String.split("")` fix lands, rebase `.tasks/library-repos/erika` onto
erika's `feat`, rebuild the compiler from `botopink-lang` `feat`, and commit the staged 7c and
`BOTOPINK_LANG_REF` change through the hook. Then sweep `src/erika.bp`'s comments against the
constraints that still exist.

**Acceptance:**
- [x] erika's `buildCmp` and its lexer produce their accumulated values (erlang)
- [x] `botopink check` and `botopink test` green in `repository/erika` on commonJS and erlang; the
      `erika·*` lines deleted from `scripts/known-red-libs.txt` (a commit in botopink-lang — hand it
      to [`../05-cli-residuals/`](../05-cli-residuals/README.md) if that front is open)
- [x] 7c and the `BOTOPINK_LANG_REF` default committed through the hook, no `--no-verify`
- [x] No comment in `src/erika.bp` describes a JavaScript, wasm3 or WAT comptime runtime, or a
      `libs/std` file that no longer exists

### Step 2 — emilia: give it a gate (7d)

Copy the sibling `scripts/git-hooks/` pair and a `.github/workflows/test.yml`, add "## Local gate"
to `AGENTS.md`, run the declared tests. Install path per
[`../09-hygiene/decisions.md`](../09-hygiene/decisions.md) 5.5. [`emilia.md`](./emilia.md).

**Acceptance:**
- [x] emilia has a tracked hook source and a CI workflow matching its siblings
- [x] The hook is installable by the documented command and passes
- [x] The gate would reject a source file carrying markdown escapes

### Step 3 — the last two `BOTOPINK_LANG_REF` defaults

**Acceptance:**
- [x] jhonstart's and onze's `test.yml` default to `feat`; all five defaults name the same branch

### Step 4 — rakun's records are exported

Not this front's fix: `botopink build` must emit `module.exports` for a module's public records
(commonJS). 1.0.4-beta js-bridges (`aa02bb4`) made every pub enum and record emit
`exports.Name = Name;`, which should close it; this front verifies it in rakun, and a failure goes to
[`../01-backend-residuals/`](../01-backend-residuals/README.md) if it is open, else to
[`../fronts.md`](../fronts.md#unowned-items).

**Acceptance:**
- [x] rakun's emitted `bootstrap.js` exports `Rakun`, and a scratch consumer `require`s it

## Gate

- [ ] erika, emilia: `botopink check` and `botopink test` green in the repo root, on commonJS and
      erlang, with a compiler built from `botopink-lang` `feat`
- [ ] `zig build test-libs` has no known-red line left that names a library this front owns
- [ ] Each repo's `AGENTS.md` updated in the same commit
- [ ] One commit per repo on `fix/library-repos`; no push, no merge

## Blast radius

- **erika goes green** once the `libs/std` `String.split("")` fix lands and step 1 commits; the `known-red-libs.txt` lines
  for erika are deleted in botopink-lang.
- **emilia gains a hook**, so every later emilia commit — including
  [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md)'s migration — pays its gate.
- **The `BOTOPINK_LANG_REF` change** points jhonstart's and onze's CI at `feat`, which may red them
  on a compiler change their `main`-pinned CI never saw. That is the point.

## Notes

- **This front runs before the 1.0.3 surface fronts.** [`../11-dead-keywords-residual/`](../11-dead-keywords-residual/README.md)
  edits jhonstart and [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md) rewrites
  all five libraries; landing erika's 7c and emilia's gate first means the migration is verified
  by a working hook in both.
- **Library hooks are local state.** In the maintainer's meta checkout the erika, jhonstart, onze,
  rakun and vscode-extension hooks are installed as symlinks and resolve, so a red hook blocks
  commits there; a fresh clone installs none. Measured detail in
  [`../09-hygiene/decisions.md`](../09-hygiene/decisions.md).
