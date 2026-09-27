# Front 101 — gate-jhonstart: no stale restriction, the dom-test cell decided, the repository's own gate hard

**Priority:** high — jhonstart's cells are green today, but three of its manifests carry a
restriction the ledger tolerates (two at `0` failed, one at `1`), and its trees carry the PK-5
format drift decision 132 waits on.
**Depends on:** none to start. `113` lands after it (the three `jhonstart-*` ledger lines go with
the file).
**Owns:** `repository/jhonstart/**` for the duration of the front — `examples/jhonstart-counter/botopink.json:8`,
`examples/jhonstart-todo/botopink.json:8`, `modules/jhonstart-dom-test/**`,
`.github/workflows/test.yml`, `.gitignore`, `scripts/git-hooks/**`, a reformat-only commit over
`modules/jhonstart/**` and `modules/jhonstart-link/**`.
**Does not touch:** `repository/botopink-lang/**` (`scripts/restricted-targets.txt` is 113's);
`repository/onze/**`, `repository/rakun/**`; `modules/jhonstart-router`, `-forms`, `-link` source
beyond the reformat (`../../04-jhonstart/` fronts 26, 27, 67 own them).

---

## Problem

```
$ cd repository/botopink-lang && zig build test-libs -- --lib jhonstart-counter --target erlang
── jhonstart-counter · erlang: restricted — 0 failed, as pinned (00/02-erlang `"targets": ["commonJS"]`; … the restriction outlived its reason)
```

A restriction that pins `0` failed restricts nothing: the cell passes and the manifest still says it
must not run. Measured at the open: `jhonstart-counter erlang 0`, `jhonstart-todo erlang 0`
(`scripts/restricted-targets.txt:53-54`), `jhonstart-dom-test erlang 1` (`:55`). Every other jhonstart
cell passes: 15 commonJS, 12 erlang. The repository's own gate (report L): **green, 100 %** —
27/27 cells (`jhonstart` 204/0, link 38/0, test 21/0, forms 15/0, emilia 10/0, html 5/0, dom-test
9/0, 8 examples); pre-commit 7/7 members, 8/8 examples, 3/3 refusals. What is stale: `repro/**` —
four reproductions, none reproduces any more (`erlang-imported-fn-field` green on both targets;
`local-binding-leaks-to-later-decls` and `self-param-free-fn` now refused, fixed;
`erlang-std-slice-shim` no longer compiles — `result-member-not-a-method` on `length`, the
`querystring` API changed); its README says to delete each when the fix lands.

## Current state

| Cell | Manifest | Measured | Reason on the ledger line |
|---|---|---|---|
| `jhonstart-counter·erlang` | `examples/jhonstart-counter/botopink.json:8` `"targets": ["commonJS"]` | passes (0 failed) | was `build` while a `fn`-typed field across a module boundary lowered wrong — fixed in the compiler; outlived |
| `jhonstart-todo·erlang` | `examples/jhonstart-todo/botopink.json:8` `["commonJS"]` | passes 3/3 | was `build` while the example wrote bare `print(…)`; fixed; outlived |
| `jhonstart-dom-test·erlang` | `modules/jhonstart-dom-test/botopink.json:8` `["commonJS"]` | 1 failed: `installDocument has no #[@External] for the erlang backend` (`src/root.bp:30`); the module does not compile | there is no DOM on the BEAM (`04-jhonstart` 30-g) — structural |

Tolerances in this repository:

| Tolerance | Where | Decision |
|---|---|---|
| pre-commit warns and skips when the compiler is not found; `known-broken-examples.txt` branch | `scripts/git-hooks/lib/runner-standalone.sh` | gate-i |
| no `*.snap.new` guard | `.gitignore`, `scripts/git-hooks/pre-commit` | gate-i |
| CI examples gate only on the commonJS row; rows otherwise hard (`:45-49`, all `allow_fail: false`) | `.github/workflows/test.yml` | gate-j |
| `botopink format --check` drift | `modules/jhonstart/**`, `modules/jhonstart-link/**` (PK-5) | — |

## Mechanism

`lib-test-runner/src/discovery.zig:307` — `libRunsTarget` is the manifest whitelist unless
`--include-unsupported`, which `test-libs.sh:326` always passes; the cell then runs and its failed
count is compared with the ledger. A `0` line is therefore a cell that runs, passes, and is reported
in yellow as "restricted". Under gate-a the ledger goes and the manifest decides; under gate-d a
restriction survives only when the excluded target fails on a host binding — which is exactly
`jhonstart-dom-test`'s case and not the two examples'.

## Steps

### Step 1 — widen the two examples

Delete the `"targets"` line in `examples/jhonstart-counter/botopink.json` and
`examples/jhonstart-todo/botopink.json` (the workspace's two targets are inherited). Run both cells on
erlang and commonJS.

**Acceptance:**
- [ ] `zig build test-libs -- --lib jhonstart-counter --target erlang` → `pass`; same for `jhonstart-todo`; both commonJS cells unchanged
- [ ] until 113 lands, `zig build test-libs` reports the two lines as *stale* (`test-libs.sh:333-342`) — expected; 113 deletes the file. The front's own gate reads `--lib` runs

### Step 2 — `jhonstart-dom-test` on erlang: structurally restricted, or asserting the empty twins

The choice `04-jhonstart`'s README hands here (JH-LEDGER): (a) keep `"targets": ["commonJS"]` — under
gate-d the runner audits it: `botopink build --target erlang` in the member must fail with the
host-binding refusal (`installDocument has no #[@External] for the erlang backend` — it does,
`src/root.bp:30`), so the restriction stands and no erlang cell exists; (b) widen and make
`dom_test.bp`'s erlang row assert the erlang twins' empty answers (count 0). **Recommendation: (a)**
— there is no DOM on the BEAM; a cell that asserts "nothing happens" on a target the module does
not exist for is a test of the restriction, not of the library. Record the audit line in this README.

**Acceptance:**
- [ ] the audit table: `jhonstart-dom-test` · `erlang` · the first refusal line of `botopink build --target erlang`
- [ ] `26-jhonstart-router` (`../../04-jhonstart/26-jhonstart-router/README.md` § the `dom-test` erlang cell) points here for the rule

### Step 3 — the repository's own gate: hook, guard, CI (gate-i, gate-j)

- `.gitignore` + hook: `*.snap.new` / `*.snap.md.new` refused; `locateBotopink` miss → fail; the
  `known-broken-examples.txt` branch deleted.
- `.github/workflows/test.yml`: rows stay `commonJS` × 3 runners + `erlang` × 2 (all hard already);
  the examples gate runs on every row (an example's manifest target decides what it builds — the
  gate builds each example with its own target, so once per row is redundant but never wrong; the
  point is that no row is "the one that checks examples"); the windows row subject to gate-f.

**Acceptance:**
- [ ] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` ≥ 1 each; a staged `x.snap.new` → hook exit 1; the hook without a compiler binary → exit 1 with the build hint
- [ ] `grep -c "allow_fail: true" .github/workflows/test.yml` = 0

### Step 3b — delete the stale `repro/**`

`repro/README.md` says each reproduction is deleted when its fix lands; all four have (report L):
`erlang-imported-fn-field` (green on both targets), `local-binding-leaks-to-later-decls` and
`self-param-free-fn` (now refused by the compiler), `erlang-std-slice-shim` (no longer compiles —
`result-member-not-a-method` on `length`; the `querystring` API changed). Delete the directory;
a reproduction that is still wanted as a regression test is a cell in the member it belongs to, or
a `tests/language` cell filed to `../../01-compiler/12-language-tests` — never a tree the gate does
not run.

**Acceptance:**
- [ ] `test ! -e repository/jhonstart/repro`; `repository/jhonstart/AGENTS.md` no longer names it

### Step 4 — PK-5: `botopink format` over `modules/jhonstart` and `modules/jhonstart-link`

One reformat-only commit. `botopink format --check` exit 0 over both trees; every cell still green.

**Acceptance:**
- [ ] `repository/botopink-lang/zig-out/bin/botopink format --check repository/jhonstart/modules/jhonstart repository/jhonstart/modules/jhonstart-link` → exit 0
- [ ] `zig build test-libs -- --lib jhonstart` and `-- --lib jhonstart-link` on both targets → `pass`

## Gate

- [ ] every jhonstart cell `pass` / `no tests` on its declared targets (`find repository/jhonstart/{modules,examples} -maxdepth 1 -mindepth 1 -type d`)
- [ ] `(cd repository/jhonstart && scripts/git-hooks/pre-commit)` green; the workflow green
- [ ] `repository/jhonstart/AGENTS.md` updated; commit on `front/gate-jhonstart` in the jhonstart submodule; no push, no merge

## Blast radius

- `26-jhonstart-router`, `27-jhonstart-link`, `67-jhonstart-forms` (`../../04-jhonstart/`) start
  from this front's landing (the reformat of `modules/jhonstart` and `modules/jhonstart-link`
  touches every file they own).
- `113` deletes `restricted-targets.txt:53-55` with the file; `04-jhonstart/modules.md:34,36`
  (the "stale restriction — `00-gate`" cells) close on this landing.
- `emilia`'s examples depend on jhonstart (`repository/emilia/.github/workflows/test.yml:136`
  checks out jhonstart for the examples gate) — 109 verifies against this tree.
