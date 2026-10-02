# Front 100 — gate-onze: every onze cell green on the targets its members declare

**Priority:** critical — 11 of the gate's 36 red `test-libs` cells were onze's at the open, on both
targets, and every `06-onze` front waits on this one.
**Depends on:** none to start (gate-g's recommendation was the starting assumption).
`onze-server·erlang` and `onze-cli`'s fixture-build tests compile rakun's `rakun-data`,
`rakun-scheduling` and `rakun-app` — they are green only on a tree that has `99`'s migration.
`113` lands after it.
**Owns:** `repository/onze/**` — the `(if …)` sites, `modules/onze-cli/**`, `modules/onze-og/**`,
`.github/workflows/test.yml`, `.gitignore`, `scripts/git-hooks/**`.
**Does not touch:** `repository/botopink-lang/**`; `scripts/restricted-targets.txt` (113's — the
three onze lines PK-1 asked for were never written: gate-a deletes the file); `repository/rakun/**`
(99's); `repository/jhonstart/**`.

---

## Problem, as measured at the open

```
$ cd repository/botopink-lang && zig build test-libs -- --lib onze-bundler --target commonJS
error[if-operand]: an `if` expression begins an expression; it is not an operand   (×3)
error: unbound variable …                                                             (×9)
error: 12 module(s) failed to compile: chunk, graph, link, rebuild, entry, refusal, chunk_test, entry_test, …
── onze-bundler · commonJS: FAIL
```

At the open (`cells.txt`): FAIL — `blog` (commonJS, erlang), `onze-assets` (both), `onze-bundler`
(both), `onze-cli` (commonJS), `onze-og` (erlang), `onze-release` (both), `onze-server` (erlang);
restricted and not in the ledger — `onze-cli·erlang`, `onze-og·commonJS`, `onze-server·commonJS`;
pass — `onze`, `onze-test` (both); no tests — `scaffold`. The repository's own gate (report L):
**~29 %** — 4 pass, 2 no-tests, 10 FAIL of 16 cells; the pre-commit hook stopped at the second of
eight members; `examples/blog` did not build.

## Current state

Measured with `botopink test --target <t>` in every member on every target its manifest declares
and `botopink build --target <t>` of every example, compiler `botopink-lang` `eec364de`, on this
front's tree (rakun at `feat`) and, for the cells whose closure holds rakun, on a tree with 99's
working copy of rakun beside it. 19 cells (the `targets` lines of `onze-cli` and `onze-og` are gone,
step 3, so both run on both rows):

| Cell | commonJS | erlang |
|---|---|---|
| `onze` | pass 23 | pass 23 |
| `onze-assets` | pass 26 | pass 26 |
| `onze-bundler` | pass 41 | pass 41 |
| `onze-cli` | **FAIL** 29 / 2 (99's tree; on `feat`'s rakun 25 / 6, the four more are rakun's `if-operand`) | **FAIL** 28 / 3 (99's tree) |
| `onze-og` | pass 10 | pass 10 |
| `onze-release` | pass 9 | pass 9 |
| `onze-server` | — (`["erlang"]`, structural) | pass 10 on 99's tree; on `feat`'s rakun the run passes 10 / 0 and exits 1 on rakun's seven `if-operand` modules |
| `onze-test` | pass 7 | pass 7 |
| `blog` | pass 12 · builds | pass 12 · builds |
| `scaffold` | no tests · builds | no tests · builds |

17 of 19 cells green; the two `onze-cli` cells stay red on five tests, none of them an onze red
(§ What is left). No `if-operand` diagnostic is left in any onze cell's log; `onze-og`'s "unknown
type" was the cascade of its own two sites and is gone.

The hook (`scripts/git-hooks/pre-commit`, the one text of the five library repositories):
stages 1–3 green (no staged `*.snap.new`, no conflict marker, the compiler found), then every
stage runs and every red is listed — measured 2026-10-02 with the compiler built from
botopink-lang `29cfffc8`: 17 of 19 cells, 4 / 4 example builds, exit 1 on `onze-cli` commonJS
(30 / 1) and erlang (28 / 3) and on nothing else (was: stopped at the second of eight members,
then at the fourth).

### Step 3 — the restrictions, audited (gate-d)

`botopink build --target <excluded>` in the member, the first error recorded:

| Member | Excluded target | Result | Decision |
|---|---|---|---|
| `onze-cli` | erlang | builds (93 modules, exit 0) | `targets` line deleted — runs on both rows |
| `onze-og` | commonJS | builds (39 modules, exit 0) | `targets` line deleted — runs on both rows |
| `onze-server` | commonJS | `` `numeralText` has no `#[@External.<Target>(…)]` for the node backend `` — then `rkReqLive`, `rkListenerStore`, `rkLifecycleStore`, `rkBeanStore`, `rkCwd`, `rkSslGet`, … | structural: rakun's hosts are erlang-only (decision 117); the `["erlang"]` line stays |

No ledger line was written anywhere.

### Step 4 — the repository's own gate (gate-i, gate-j)

- `scripts/git-hooks/lib/runner-standalone.sh` — one text in the five library repositories
  (`sha256sum` equal ×5; the meta `hook-integrity` check 4): the compiler is a stage and its
  absence fails the gate (the message names `BOTOPINK_BIN`, the enclosing checkout's `zig-out/bin`,
  `PATH`; a `BOTOPINK_BIN` that is not an executable fails too); a staged `*.snap.new` /
  `*.snap.md.new` is refused; `known-broken-examples.txt` and its branch are gone; every workspace
  member — the eight modules and the two examples — runs on every target its manifest declares
  (`manifestTargets` — the member's `targets`, else the workspace's), every example builds on
  every declared target; `BOTOPINK_BIN` is exported to the suites. `.gitignore` lists both scratch
  suffixes.
- `.github/workflows/test.yml`: the member loop is gone. One `botopink-lib-test --target <t>` per
  runner × workspace target, from a scratch cwd with `BOTOPINK_LIB_ROOTS` naming this repository,
  so the runner discovers every member and example from the root and nothing else (the walk-up
  from a cwd inside the checkout would add every sibling library under `repository/`);
  `onze-server`, `blog` and `scaffold` are rows; `allow_fail` does not appear; jhonstart, emilia
  and rakun are checked out as the `path` dependencies the manifests declare (the old workflow
  checked out neither and could not have compiled `modules/onze`); both hosts on every row (the
  cli's fixture builds run `erlc` and `node` on either row); the examples gate runs on every row.
  Rows `{ubuntu-24.04, macos-14} × {commonJS, erlang}`: `ubuntu-24.04` because of the compiler's
  glibc pin and no windows row because the compiler has none (101's README has both rows);
  `--strict`. The workflow is written, not run: it triggers on push / PR to `feat`, `master`,
  `main` only.
  Its command shape is measured in a scratch layout of its checkout
  (`botopink-lang/{libs,repository/{onze,jhonstart,emilia,rakun}}`): `botopink-lib-test --target
  commonJS --strict` → 7 passed, 1 failed (`onze-cli`), 1 no-tests (`scaffold`), 1 skipped
  (`onze-server`, by its manifest); `--target erlang --strict` → 8 passed, 1 failed (`onze-cli`),
  1 no-tests; the examples step → 2 builds on each target. The rows are onze's ten members and no
  other.
- `onze-cli`'s fixture suites (`build`, `create`, `generate`, `start` tests) read `BOTOPINK_BIN`
  before walking up to a `repository/botopink-lang/zig-out/bin/botopink` — in a worktree the
  walk-up reached the main checkout's compiler; in CI's layout it reaches none.

## What is left

Five red tests, all in `onze-cli`, none fixable in `repository/onze/**`:

| Test | Targets | Cause | Owner |
|---|---|---|---|
| `start: the blog through onze build && onze start` (`test/start_test.bp`) | both | the staged blog holds `app/not_found.bp` and `app/blog/d_slug/not_found.bp`, both `pub fn NotFound` (jhonstart's convention); every import of either — `import {NotFound} from "app.blog.d_slug.not_found"`, which does say which — is refused with `ambiguous-import-use: NotFound is imported from two declarations — declared pub by app/blog/d_slug/not_found and by app/not_found — and this use does not say which`. Reproduction: two modules `a/nf.bp`, `b/nf.bp` each `pub fn NotFound() -> string`, a third with `import {NotFound} from "a.nf"; NotFound()` → refused on both targets. The docs (`docs.md:146-149`) say the `from` item is the way out; here it is not. | `../01-compiler/01-checker` — a named import from a spelled module must resolve to that module |
| `start: onze build && onze start serves the scaffold's /` | commonJS | the staged scaffold builds and `onze start` listens, but `GET /` answers `404` with an empty body, on 99's working tree of rakun (`rakun-app` is mid-migration there, its route files rewritten); `onze-server`'s own test "Onze.run listens on 3000 and answers / from `#[page("")]`" passes on the same tree; the staged `onze_routes.bp` imports `home as onze_app_page` and a probe shows an aliased, unused import runs the module body on both targets | re-measure on 99's landed tree; if it stays red it is onze-server's (a `06-onze` row), not a gate tolerance |
| `build: the scaffold ---- the staged server, its BEAM …` and `start: … serves the scaffold's /` | erlang | the whole `onze build` on the BEAM throws a bare `enoent` (an Erlang exception escaping a std host binding, not a `@Result`); every `io.fs` / `io.process` function answers a `@Result` for a missing path in a probe, `process.cwd()` is the member directory inside the test, and the scaffold's manifest reads — so the throw is inside the build's compile-and-link half on the BEAM; not localised yet (the erlang runner prints no stack) | first `botopink build --target erlang` of `onze-cli` driven by `erl` to get the stack; then either a std erlang binding row (`../02-std-and-packaging`) or an onze-cli fix |
| `build: a client emilia call is evaluated by both backends` and `build: a CSS module's generated accessors compile …` | erlang (on `feat`'s rakun; green on 99's tree) | rakun's `if-operand` cascade in the staged server | 99 |

Two compiler rows this front hands out besides the checker one above:

- `../01-compiler/02-erlang`: `indexOf` answers a byte offset and `slice` counts code points once a
  non-ASCII character precedes the match (`"//// `/about` — group.\n#[page(\"(marketing)/about\")]"`:
  `indexOf` 23 on node, 25 on the BEAM; the slice loses `(m`). `onze-cli/src/scan.bp`
  `declaredArgument` reads with `split` now.
- `../01-compiler/26-cli-tooling` or `113`: `botopink test` does not export `BOTOPINK_BIN` to a
  suite that builds fixtures (the track README's rakun-client row); onze's hook and workflow
  export it themselves.

## Mechanism

One `if-operand` site reds its module, its importers report `unbound variable`, and a `*_test.bp`
that builds a scaffold and asserts stdout sees the compile error. `onze-bundler` is in the closure
of `blog`, `onze-assets`, `onze-cli` and `onze-release` — 6 sites red 9 cells. `onze-cli`'s
`build`/`start` suites compile the staged server, whose closure is `onze-server` → rakun, so a
rakun red reaches `onze-cli` on both rows.

## Steps

### Step 1 — the `(if …)` operand sites

`val x = if (c) { a } else { b };` before the use (gate-g). The grep at the open listed 23; the
migration covered every parenthesised operand it found — 26 sites — since `layout.bp:197,209` and
`font.bp:101`'s inner `if` are operands too:

| File | Lines at the open |
|---|---|
| `modules/onze-bundler/src/chunk.bp` | 209 |
| `modules/onze-bundler/src/graph.bp` | 181, 183, 185 |
| `modules/onze-bundler/src/rebuild.bp` | 50 |
| `modules/onze-assets/src/assets.bp` | 29 |
| `modules/onze-assets/src/font.bp` | 101 (inner), 195, 257 |
| `modules/onze-assets/src/image.bp` | 139, 140 |
| `modules/onze-cli/src/create.bp` | 224, 226, 228 |
| `modules/onze-cli/src/generate.bp` | 209 |
| `modules/onze-cli/src/resolve.bp` | 53 |
| `modules/onze-cli/src/scan.bp` | 76 |
| `modules/onze-cli/src/start.bp` | 26 |
| `modules/onze-og/src/layout.bp` | 193, 197, 209, 217, 236 |
| `modules/onze-og/test/og_test.bp` | 121 |
| `modules/onze-release/src/lifecycle.bp` | 73 |
| `modules/onze-release/test/package_test.bp` | 52 |

An `if` that begins a call argument (`push(if …)`, `quote(if …)`, `attr(if …)`) is not an operand
and stays. A closure whose body was one such expression became a loop or a named helper.

- [x] no `error[if-operand]` in any onze cell's log; `onze-bundler` compiles on both targets

### Step 2 — `onze-og`'s unknown type, then every cascade

- [x] `onze-og`: the unknown type was the cascade; 10 / 0 on both targets
- [x] every member but `onze-cli` `pass` / `no tests`, `0 failed`, on its declared targets
- [x] `(cd examples/blog && botopink build --out $(mktemp -d))` exit 0; the examples gate builds
      `blog` and `scaffold` on both targets
- [ ] `onze-cli` on both targets — blocked on the checker row, 99's landing and the BEAM `enoent`
      (§ What is left); the hook then runs all eight members to the end

### Step 3 — the restrictions are structural (gate-d)

- [x] the table above; two lines deleted, one stays
- [x] no ledger line written anywhere

### Step 4 — hook, guard, CI (gate-i, gate-j)

- [x] the loop is gone and discovery is the runner's; `onze-server`, `blog`, `scaffold` are rows
- [x] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` ≥ 1 each;
      `grep -c "allow_fail: true" .github/workflows/test.yml` = 0

## Gate

- [ ] every onze cell `pass` / `no tests` on its declared targets, `0 failed` — 17 of 19; the two
      `onze-cli` cells wait on § What is left
- [ ] `scripts/gate.sh --cold` in `repository/botopink-lang` with this onze checkout and 99's rakun:
      stage 8 has no onze red — not run by this front (the compiler fronts share the machine); the
      per-cell measurement above is the same runner's
- [ ] `(cd repository/onze && scripts/git-hooks/pre-commit)` green — 17 of 19 cells and 4 / 4
      builds in one run, exit 1 on the two `onze-cli` cells; the workflow is unrun
- [x] `repository/onze/AGENTS.md` updated; the work is on `front/100-gate-onze` in the onze submodule

## Blast radius

- Every `06-onze` front starts from this front's landing: `onze-bundler/src/**`, `onze-cli/src/**`,
  `onze-assets/src/**`, `onze-og/src/**`, `onze-release/src/**` are rewritten here, and `onze-cli`
  and `onze-og` are two-row members now.
- `rakun-starter-test` (99 step 3) depends on an onze member — 99 verifies its cell against this
  front's tree once both are in one checkout.
- PK-1's three ledger lines are not written: under gate-a the ledger is deleted by 113.

## Notes

- onze wires the libraries (decision 113): `onze-server`'s erlang closure includes rakun members,
  and its commonJS exclusion is structural because rakun's host cells are erlang-only — the one
  place an onze restriction is *rakun's* reason.
- The workflow's one-call discovery relies on the runner's root resolution: `BOTOPINK_LIB_ROOTS`
  entries come first and the walk-up from the cwd adds an ancestor workspace, `repository/` and
  the bundled `libs/`; only a cwd outside every checkout keeps the roots to the one named. A
  `--lib <root>` that means "every member of this workspace" does not exist (`--lib` matches a
  member's name, and the umbrella is not a cell) — a `113` / `115` improvement if the scratch cwd
  is judged too indirect.
