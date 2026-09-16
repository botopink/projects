# Front 12 — library repos

**Priority:** high for [rakun](./rakun.md) and [erika](./erika.md) (neither compiles), medium for
the rest — every defect here either blocks a library from compiling or ships something the
compiler rejects to the people using it
**Depends on:** [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md) step 1 for erika's
documentation rewrite (7c); [`../11-hygiene/decisions.md`](../11-hygiene/decisions.md) item 5.5
for emilia's gate (7d). rakun, vscode-extension and bpmp can start at once
**Owns:** `repository/rakun/**` · `repository/erika/**` · `repository/emilia/**` ·
`repository/vscode-extension/**` — one commit per repo · `repository/botopink-lang/modules/bpmp/**`
(7h; [`../fronts.md`](../fronts.md) assigns this directory to no front, and its spec row is this
front's)
**Does not touch:** `modules/compiler-core/src/codegen/erlang.zig` (erika's loop defect, 7b — owned
by [`../05-erlang/`](../05-erlang/README.md) and [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)) ·
`modules/compiler-cli/**` and `build.zig` ([`../02-cli-gate/`](../02-cli-gate/README.md)) ·
`repository/jhonstart/**` and `repository/onze/**` beyond the one-line `BOTOPINK_LANG_REF` default
7g asks for

Paths are relative to `repository/`, except where they name the compiler (`botopink-lang/…`).
Inside a per-repo file, bare paths are relative to that repo.

---

## Problem

Measured against a compiler built from HEAD — the checked-in `zig-out/bin/botopink` was stale and
predated half the 1.0.1-beta waves, so build it first when diagnosing:

```
cd repository/rakun && botopink check
→ a declared dependency was not found under the libs root          exit 1
```

erika's `check` and `test` fail too: its 13 template tests are dead on the comptime-dispatch cause,
and behind that its two-parameter `loop` lowers to Erlang that loses the accumulator.

The other three repos build, but ship things that do not work: vscode-extension offers a snippet and
a keyword the parser rejects and a Test Explorer action that `botopink test` refuses; emilia has no
gate at all, which is how a source file carrying markdown escapes shipped; bpmp's `install
--frozen` reports success while leaving a dangling symlink.

## Current state

| Repo | `check` | `test` | Blocking defect | Fix lives in | Deep dive |
|---|---|---|---|---|---|
| rakun | **fail** | fail | a dependency that exists in no commit — fails before compiling | rakun, or a new repo | [`rakun.md`](./rakun.md) (7a) |
| erika | fail | fail | 13 template tests dead (the comptime-dispatch cause); two-parameter `loop` loses the accumulator | compiler | [`erika.md`](./erika.md) (7b) |
| erika | | | `AGENTS.md` documents a removed evaluator | erika | [`erika.md`](./erika.md) (7c) |
| emilia | pass | **17/17** | no hook, no CI | emilia | [`emilia.md`](./emilia.md) (7d) |
| vscode-extension | — | **15/15** | retired syntax in snippets + grammar | extension | [`vscode-extension.md`](./vscode-extension.md) (7e) |
| vscode-extension | | | Test Explorer forwards targets `test` refuses | extension | [`vscode-extension.md`](./vscode-extension.md) (7f) |
| vscode-extension | | | CI never builds against this compiler | extension | [`vscode-extension.md`](./vscode-extension.md) (7g) |
| bpmp | builds | **90** `test` declarations, run by `zig build test-bpmp` | three git-dependency bugs | bpmp | [`bpmp.md`](./bpmp.md) (7h) |

emilia's 17/17 is after a fix: the source carried markdown escapes (`#\[@External\.node(`) and was
dead. erika's fluent layer passes 16/18 once the 13 template tests are removed.

No failure is a regression of the 1.0.1-beta waves — each reproduces byte-identically on the
compiler built from the commit that milestone started at.

## Mechanism

Five repos, five unrelated mechanisms; each file holds the deciding lines.

| Repo | Deciding `file:line` | What it decides |
|---|---|---|
| rakun | `rakun/botopink.json:7` → `botopink-lang/modules/compiler-cli/src/cli/libs.zig:295` | `"dependencies": ["server"]` names a library that does not exist; `libs.zig:295` returns `error.LibNotFound` before rakun's source is read |
| erika | `botopink-lang/modules/compiler-core/src/codegen/erlang.zig:2547` and `:3259` | a two-parameter `loop` is refused the fold, and its `enumerate` repair requires an explicit range, so a 2-arity fun reaches `lists:foreach/2` |
| erika | `erika/AGENTS.md:108-148` | every workaround in the file is derived from a JavaScript comptime evaluator that no longer exists |
| emilia | `emilia/` top level | no `scripts/`, no `.github/` — nothing enforces the 21 tests `AGENTS.md` declares |
| vscode-extension | `snippets.json:52-56, 71-82` · `syntaxes/botopink.tmLanguage.json:47` · `src/testExplorer.ts:243` · `.github/workflows/test.yml` | snippets and grammar for removed syntax; a target list not filtered for `test`; a CI that never checks out the compiler |
| bpmp | `src/dep/resolver.zig:96, 116` · `resolver.zig:20-29` · `src/commands/sync.zig:60` | `reuse_cas` never probes the store; `Action` drops the ref; `sync` hardcodes the org |

## Steps

### Step 1 — rakun: resolve or remove the `server` dependency (7a)

Decide one of: create `libs/server`, vendor a `declare fn` over `node:http` into rakun's `src/`, or
drop the dependency and its import. Fix `"targets"` → `"target"`. The compiler-side halves (the
`libs.zig:669` test that invents the lib, and the LSP swallowing the miss) go to the fronts that own
those files. [`rakun.md`](./rakun.md).

**Acceptance:**
- [ ] `botopink check`, `test` and `build` run in `rakun/` — no `LibNotFound`
- [ ] No compiler test synthesises a library that does not exist
- [ ] A missing dependency is reported the same way by the CLI and the language server

### Step 2 — erika: two-parameter `loop`, then the comptime-eval section (7b · 7c)

7b is a compiler fix handed to [`../05-erlang/`](../05-erlang/README.md); this front verifies it in
erika. 7c rewrites `erika/AGENTS.md:108-148` against the Erlang evaluator, after
[`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md) step 1 lands. [`erika.md`](./erika.md).

**Acceptance:**
- [ ] `loop (xs) { x, i -> acc = … }` threads `acc` out, like the one-parameter form
- [ ] No `lists:foreach/2` or `lists:map/2` ever receives a fun of arity ≠ 1
- [ ] A compiler-core regression test covers the two-parameter loop on the typed **and** the
      comptime path, so it does not depend on an erika checkout
- [ ] erika's `buildCmp` and its lexer produce their accumulated values
- [ ] No `AGENTS.md` in the workspace describes a JavaScript, wasm3 or WAT comptime runtime
- [ ] Every workaround erika documents is justified by a constraint that still exists

### Step 3 — emilia: give it a gate (7d)

Copy the sibling `scripts/git-hooks/` pair and a `.github/workflows/test.yml`, add "## Local gate" to
`AGENTS.md`, run the 21 declared tests. Install path per
[`../11-hygiene/decisions.md`](../11-hygiene/decisions.md) 5.5. [`emilia.md`](./emilia.md).

**Acceptance:**
- [ ] emilia has a tracked hook source and a CI workflow matching its siblings
- [ ] Every sibling library's pre-commit hook is installable by a documented command and passes
- [ ] The gate would reject a source file carrying markdown escapes

### Step 4 — vscode-extension: snippets, grammar, Test Explorer, CI (7e · 7f · 7g)

[`vscode-extension.md`](./vscode-extension.md).

**Acceptance:**
- [ ] Every snippet body and every grammar keyword parses against the compiler at HEAD
- [ ] A test asserts the grammar's declaration-keyword list against `keywordOrIdent`
- [ ] No Test Explorer action can produce the `test_cmd.zig:60` error
- [ ] The two target sets (build vs test) are declared in one place and tested
- [ ] The extension's CI compiles at least one `.bp` file with the compiler from this workspace
- [ ] All five `BOTOPINK_LANG_REF` defaults name the same branch

### Step 5 — bpmp: the three git-dependency bugs (7h)

[`bpmp.md`](./bpmp.md).

**Acceptance:**
- [ ] `bpmp install --frozen` against an empty store fails with a named error, not a dangling symlink
- [ ] A first install of a `branch:`/`tag:` dep checks out the named ref, asserted by a test
- [ ] `sync` resolves each dep from its own declared source; no org name is hardcoded
- [ ] `install.zig` and `sync.zig` have tests; `zig build test-bpmp` is in the documented gate
      ([`../02-cli-gate/`](../02-cli-gate/README.md)) or the reason it is not is written down

## Gate

Each repo gates on its own suite, with a compiler built from `botopink-lang` `feat`:

- [ ] rakun, erika, emilia: `botopink check` and `botopink test` green in the repo root, on commonJS
      and erlang
- [ ] vscode-extension: `npm ci && npm test` green, plus the new compiler-backed job from 7g
- [ ] bpmp: `zig build test-bpmp` green in a `botopink-lang` worktree, and `zig build test` from a
      **cold** runtime cache (the `modules/bpmp` edit lands in that repo)
- [ ] Each repo's `AGENTS.md` updated in the same commit
- [ ] One commit per repo on `fix/library-repos`; no push, no merge

## Blast radius

- **rakun goes from blocked to measurable.** It has 22 comptime-dispatch errors latent behind the
  missing dependency (counted by [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md));
  once 7a lands they surface, and rakun stays red until that front lands too.
- **The gate widens.** [`../02-cli-gate/`](../02-cli-gate/README.md) lands `test-libs` coverage with
  rakun as a named skip; 7a is what lets that skip flip to a hard assert.
- **7b moves erlang snapshots.** Any fixture with a two-parameter loop re-records in
  `snapshots/codegen/erlang/` and in the comptime snapshots — that is
  [`../05-erlang/`](../05-erlang/README.md)'s and
  [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)'s to plan, not this front's.
- **7g touches sibling workflows** outside this front's four repos (jhonstart, onze) — one default
  string each.
- **7e can red the extension's CI** once 7g's parse check exists: land 7e before or with 7g.

## Notes

- **7b is assigned to no compiler front.** Neither [`../05-erlang/`](../05-erlang/README.md) nor
  [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md) lists it, yet the two deciding
  lines are in the file they share, and the fix must cover both the typed and the comptime path. It
  needs an owner before erika can close; the natural one is 05-erlang, sequenced against 01 per
  [`../fronts.md`](../fronts.md) note 2.
- **Library hooks are local state.** In the maintainer's meta checkout the erika, jhonstart, onze,
  rakun and vscode-extension hooks are installed as symlinks and resolve, so a red hook blocks
  commits there; a fresh clone installs none, and the documented installer
  (`scripts/install-hooks.sh`) exists in no repo. Measured detail in
  [`../11-hygiene/decisions.md`](../11-hygiene/decisions.md).
- jhonstart and onze need no step here: both pass 8/8 once they compile, and what stops them
  compiling is [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)'s (plus, for
  jhonstart, the case-arm rebinding residual that front names and does not close).
