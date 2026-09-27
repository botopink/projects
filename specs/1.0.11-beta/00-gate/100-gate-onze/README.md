# Front 100 — gate-onze: every onze cell green on the targets its members declare

**Priority:** critical — 11 of the gate's 36 red `test-libs` cells are onze's, on both targets, and
every `06-onze` front waits on this one.
**Depends on:** none to start (gate-g's recommendation is the starting assumption). `onze-server·erlang`
is verified against `99`'s tree (it imports `rakun-data` and `rakun-scheduling`). `113` lands after it.
**Owns:** `repository/onze/**` for the duration of the front — the 23 `(if …)` sites,
`modules/onze-og/**` (the `unknown type`), `.github/workflows/test.yml`, `.gitignore`,
`scripts/git-hooks/**`.
**Does not touch:** `repository/botopink-lang/**`; `scripts/restricted-targets.txt` (113's — the
three onze lines PK-1 asked for are never written: gate-a deletes the file); `repository/rakun/**`
(99's); `repository/jhonstart/**`.

---

## Problem

```
$ cd repository/botopink-lang && zig build test-libs -- --lib onze-bundler --target commonJS
error[if-operand]: an `if` expression begins an expression; it is not an operand   (×3)
error: unbound variable …                                                             (×9)
error: 12 module(s) failed to compile: chunk, graph, link, rebuild, entry, refusal, chunk_test, entry_test, …
── onze-bundler · commonJS: FAIL
```

Measured at the open (`cells.txt`): FAIL — `blog` (commonJS, erlang), `onze-assets` (both),
`onze-bundler` (both), `onze-cli` (commonJS), `onze-og` (erlang), `onze-release` (both),
`onze-server` (erlang); restricted and not in the ledger — `onze-cli·erlang`, `onze-og·commonJS`,
`onze-server·commonJS` (each `build`); pass — `onze`, `onze-test` (both); no tests — `scaffold`,
and the `onze` example. The repository's own gate (report L): **~29 %** — 4 pass, 2 no-tests, 10
FAIL of 16 cells; the pre-commit hook stops at the second of eight members (`onze-assets`); 6/8
members red; `examples/blog` does not build, `scaffold` builds.

## Current state

| Cause | Cells | Where |
|---|---|---|
| **R1** `if-operand` in `onze-bundler/src/**` cascades to everything that imports the bundler (`blog`, `onze-assets`, `onze-cli`, `onze-release`) | 9 | 23 sites, step 1 |
| `unknown type` in `onze-og` | `onze-og·erlang` (and the commonJS row, which is restricted by manifest) | `modules/onze-og/src/**` — one unknown type after the 2 `if-operand` (`layout.bp:193,217,236`, `test/og_test.bp:121`) |
| `onze-server·erlang`: 11 `if-operand` in its closure — `rakun-data/orm/**`, `rakun-scheduling/jobstore/**` (99's) plus its own | 1 | verified after 99 lands |

The manifests: `onze-cli` `["commonJS"]`, `onze-og` `["erlang"]`, `onze-server` `["erlang"]`
(`botopink.json:8` in each) — each a structural restriction to audit under gate-d (the CLI needs
node's process host; og and server need erlang hosts). Under gate-a no ledger line is written for
them; under gate-d the runner refuses the restriction unless `botopink build --target <excluded>`
fails with a host-binding error — this front checks that today's reason is that one (the
`onze-server·commonJS` diagnostic is `42× has no #[@External] for the node backend`: yes; `onze-cli`
and `onze-og`: verify).

Tolerances in this repository:

| Tolerance | Where | Decision |
|---|---|---|
| CI loop runs seven members and omits `onze-server` and the three examples (`blog`, `onze`, `scaffold`) | `.github/workflows/test.yml:120,130` | gate-j |
| pre-commit warns and skips when the compiler is not found; `known-broken-examples.txt` branch | `scripts/git-hooks/lib/runner-standalone.sh` | gate-i |
| no `*.snap.new` guard | `.gitignore`, `scripts/git-hooks/pre-commit` | gate-i |

## Mechanism

As 99's: one `if-operand` site reds its module, its importers report `unbound variable`, and a
`*_test.bp` that builds a scaffold and asserts stdout sees the compile error. `onze-bundler` is in
the closure of `blog`, `onze-assets`, `onze-cli` and `onze-release` — 6 sites red 9 cells.

## Steps

### Step 1 — migrate the 23 `(if …)` operand sites

`val x = if (c) { a } else { b };` before the use (gate-g). Measured at the open with the same grep
as 99's:

| File | Lines |
|---|---|
| `modules/onze-bundler/src/chunk.bp` | 209 |
| `modules/onze-bundler/src/graph.bp` | 181, 183, 185 |
| `modules/onze-bundler/src/rebuild.bp` | 50 |
| `modules/onze-assets/src/assets.bp` | 29 |
| `modules/onze-assets/src/font.bp` | 195, 257 |
| `modules/onze-assets/src/image.bp` | 139, 140 |
| `modules/onze-cli/src/create.bp` | 224, 226, 228 |
| `modules/onze-cli/src/generate.bp` | 209 |
| `modules/onze-cli/src/resolve.bp` | 53 |
| `modules/onze-cli/src/scan.bp` | 76 |
| `modules/onze-cli/src/start.bp` | 26 |
| `modules/onze-og/src/layout.bp` | 193, 217, 236 |
| `modules/onze-og/test/og_test.bp` | 121 |
| `modules/onze-release/src/lifecycle.bp` | 73 |
| `modules/onze-release/test/package_test.bp` | 52 |

Order: `onze-bundler` first (4 importers), then the rest.

**Acceptance:**
- [ ] no `error[if-operand]` in any onze cell's log; `onze-bundler` compiles on both targets

### Step 2 — `onze-og`'s unknown type, then every cascade

Name or import the type `onze-og` refers to. Re-run the eleven cells; chase every `unbound
variable` and `asserts.contains` red to the module that owns it. `onze-server·erlang` is re-run on
a tree that has 99's `rakun-data` and `rakun-scheduling` migrations.

**Acceptance:**
- [ ] `for m in onze onze-assets onze-bundler onze-cli onze-og onze-release onze-server onze-test blog scaffold; do zig build test-libs -- --lib $m --target <declared>; done` → `pass` / `no tests`, `0 failed`
- [ ] `(cd examples/blog && botopink build --out $(mktemp -d))` exit 0 — the examples gate builds all three (`blog`, `onze`, `scaffold`); the pre-commit hook runs all eight members to the end

### Step 3 — the three restrictions are structural (gate-d)

For `onze-cli` (excludes erlang), `onze-og` and `onze-server` (exclude commonJS): run
`botopink build --target <excluded>` in the member and record the first error. It must be a
host-binding refusal (`has no #[@External.<Target>]`). If it is anything else — the member builds,
or fails on a checker error — the restriction is not structural and the `targets` line is deleted
(the member then runs on both targets and must pass).

**Acceptance:**
- [ ] a table in this README: member · excluded target · the refusal line, for the three
- [ ] no ledger line written anywhere (`scripts/restricted-targets.txt` is 113's and is deleted)

### Step 4 — the repository's own gate: hook, guard, CI (gate-i, gate-j)

- `.gitignore` + hook: `*.snap.new` / `*.snap.md.new` refused; `locateBotopink` miss → fail; the
  `known-broken-examples.txt` branch deleted.
- `.github/workflows/test.yml`: the member loop (`:120`, `:130`) is replaced by one
  `zig build test-libs -- --lib onze --target <t>`-per-member call generated from the workspace —
  or, simpler and what the runner already does, `zig build test-libs` filtered to this repository's
  root so every member and example is a row; `onze-server`, `blog`, `onze`, `scaffold` join;
  every row `allow_fail: false`; the erlang rows run the members that declare erlang and the
  commonJS rows the ones that declare commonJS (the runner reads the manifest — nothing is skipped
  as `restricted`).

**Acceptance:**
- [ ] the workflow names every member and example (a `grep` of the member names against `find modules examples -maxdepth 1 -mindepth 1 -type d` is the check — or the loop is gone and discovery is the runner's)
- [ ] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` ≥ 1 each; `grep -c "allow_fail: true" .github/workflows/test.yml` = 0

## Gate

- [ ] every onze cell `pass` / `no tests` on its declared targets, `0 failed`
- [ ] `scripts/gate.sh --cold` in `repository/botopink-lang` with this onze checkout and 99's rakun: stage 8 has no onze red
- [ ] `(cd repository/onze && scripts/git-hooks/pre-commit)` green; the workflow green
- [ ] `repository/onze/AGENTS.md` updated; commit on `front/gate-onze` in the onze submodule; no push, no merge

## Blast radius

- Every `06-onze` front (`49`–`53`, `68`, `69`, `71` and the ones this milestone's `06-onze/`
  opens) starts from this front's landing: `onze-bundler/src/**`, `onze-cli/src/**`,
  `onze-assets/src/**`, `onze-og/src/**`, `onze-release/src/**` are rewritten here.
- `rakun-starter-test` (99 step 3) depends on an onze member — 99 verifies its cell against this
  front's tree once both are in one checkout.
- PK-1's three ledger lines (`../../02-std-and-packaging/README.md` § Handed to 00-gate) are not
  written: under gate-a the ledger is deleted by 113.

## Notes

- onze wires the libraries (decision 113): `onze-server`'s erlang closure includes rakun members,
  and its commonJS exclusion is structural because rakun's host cells are erlang-only — that is the
  one place an onze restriction is *rakun's* reason, and step 3's table says so.
