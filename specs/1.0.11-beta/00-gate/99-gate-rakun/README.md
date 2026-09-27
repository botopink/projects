# Front 99 — gate-rakun: every rakun cell green on the target rakun declares, and the repository's own gate runs

**Priority:** critical — 25 of the gate's 36 red `test-libs` cells are rakun's erlang cells, the
repository's own pre-commit fails before it runs a single test, and every `03-rakun` front waits
on this one.
**Depends on:** none to start (gate-g's recommendation is the starting assumption; the front stops
if the maintainer answers rc3-a otherwise). `113` lands after it.
**Owns:** `repository/rakun/**` for the duration of the front — in particular the files named in
the steps: the 42 `(if …)` sites, `modules/rakun-actuator/test/health_test.bp:67,71,89`,
`modules/rakun-app/test/ssr_test.bp:309,313,318`, `starters/rakun-starter-test/botopink.json:21-23`,
`modules/rakun-metrics/src/export.bp` (the `CacheLife` workaround), `modules/rakun-websocket/test/limits_test.bp`,
`modules/rakun-session/test/store_test.bp`, `modules/rakun-websocket/test/broadcast_test.bp`,
`modules/rakun-app/src/{static_gen,route_slots,metadata_routes,actions}.bp` (the comment lines the
hook's greps match), `examples/rakun-ssr/**`, `.github/workflows/test.yml`, `.gitignore`,
`scripts/git-hooks/**`, and a reformat-only commit over `modules/rakun/**` and
`modules/rakun-app/**` (PK-5).
**Does not touch:** `repository/botopink-lang/**` (a compiler defect met here is a row for
`../../01-compiler/` and the cell stays red until it lands — reported, not worked around by deleting
the test; R3 below has a library-side workaround that is not a deletion); `scripts/restricted-targets.txt`
(113's; it is deleted, not edited); any other repository.

The front may run as **three worktrees on disjoint member sets** (report L's chunks A, B, C —
`front/gate-rakun-a`, `-b`, `-c`, one front number, merged in that order) because the members do
not share files; chunk D (metrics, CI, hook) follows C, on the same branch as C or its own.

---

## Problem

```
$ cd repository/botopink-lang && zig build test-libs -- --lib rakun-data --target erlang
error[if-operand]: an `if` expression begins an expression; it is not an operand   (×4)
error: unbound variable …                                                             (×2)
error: 6 module(s) failed to compile: orm/entity, orm/query, orm/repository, migration/migrate, migration_test, orm_test
── rakun-data · erlang: FAIL

$ cd repository/rakun && scripts/git-hooks/pre-commit
── pre-commit ──
✗ … names onze …                      # stage 1b greps: comments in rakun-app/src/*.bp; `xmlElement` matches "UI type"
```

Measured at the milestone's open (report A `scratchpad/libs.txt`, per-cell digest `cells.txt`;
report L for the repository's own gate): 25 rakun erlang cells FAIL — `rakun-actuator`, `-app`,
`-cache`, `-cli`, `-data`, `-devtools`, `-mail`, `-messaging`, `-metrics`, `-release`, `-rsocket`,
`-scheduling`, `-security`, `-session`, `-ssr-example`, `-starter-cache`, `-starter-data-sql`,
`-starter-messaging`, `-starter-security`, `-starter-test`, `-stream`, `-tx`, `-web`, `-websocket`,
`-ws`; 6 pass (`rakun`, `-actuator-api`, `-client`, `-hateoas`, `-logging`, `-test`); 5 have no
tests. The pre-commit hook fails at stage 1b (the front 22/23 greps) before `botopink test` runs;
with the greps passing, 6 of 25 members would be green; `examples/rakun-ssr` does not build. The
35 commonJS cells are the restricted matrix (decision 113) and are not this front's — gate-a makes
them stop existing.

## Current state

Root causes, by the diagnostics in the 25 cells (report A § R1–R5, report L § Reds):

| Cause | Cells | Where |
|---|---|---|
| **R1** `if-operand`: `(if (c) a else b)` as an operand is a parse error since `residual-checker-3` (rc3-a) | 22 directly or by cascade — every `unbound variable X` and every `asserts.contains: needle not in actual` in a `*_build_test.bp` (`rakun-app actions_build:52`, `rakun-cache consumer:71,82`, `rakun-data orm_build/sql_build` ×9, `messaging build:54,82`, `scheduling build:79`, `jobstore/build:50`, `security build:73,99,261`, `websocket build:47`) is the cascade of a module that did not compile | 42 sites, step 1 |
| **R2** `-> any` on a `declare fn` (`any-type-removed`) | `rakun-actuator·erlang`, `rakun-app·erlang` | `rakun-actuator/test/health_test.bp:67,71,89` (`selfPid`, pids), `rakun-app/test/ssr_test.bp:309,313,318` (`rawUntil`, connections) — host handles that need a real type |
| **R3** `rakun-metrics` "unknown type `CacheLife`" — **a compiler defect** (report L): `export.bp` imports `RestClient` from `rakun-client`; the checker re-checks `RestClient`'s declaration at the import site and cannot resolve the field type `cacheLife: CacheLife`; the diagnostic is mislocated to `test/export_test.bp:137` (past that 122-line file — really `rakun-client/src/client.bp:137`) | `rakun-metrics·erlang` | owner `../../01-compiler/01-checker` (imported-type closure + diagnostic attribution); library workaround: import `CacheLife` in the `rakun-metrics` module |
| **R4** the hook's stage 1b greps: "names onze" matches comments (`rakun-app/src/static_gen.bp:34`, `route_slots.bp:22`, `metadata_routes.bp:21,469`, `actions.bp:14,191,192`); "UI type" matches `xmlElement` (substring `Element`) in `metadata_routes.bp` and a comment naming jhonstart (`route_slots.bp:23`) | the whole pre-commit | `scripts/git-hooks/lib/runner-standalone.sh` stage 1b — tighten the greps (word boundaries, code not comments) and reword the comments |
| **R5** a path dependency on a workspace root | `rakun-starter-test·erlang` | `starters/rakun-starter-test/botopink.json:21-23`: `"onze": { "path": "../../../onze" }` — onze became a workspace; the error names the members to depend on |
| **R6** a probable genuine runtime red | `rakun-websocket·erlang` | `test/limits_test.bp:48` "limits: a connection that stops reading is closed with 1013, its queue never past the cap — 51" (re-check after R1) |
| `examples/rakun-ssr` does not build | the examples gate | verify after R1 (it depends on `rakun-app`, `rakun-data`) |

Tolerances in this repository, all to delete:

| Tolerance | Where | Decision |
|---|---|---|
| a cell green only because it prints `SKIPPED` | `rakun-session/test/store_test.bp:68-71` (Redis arm behind `RAKUN_TEST_REDIS_URL`) | gate-h |
| a cell that accepts `skipped: <why>` | `rakun-websocket/test/broadcast_test.bp:102` (no peer node) | gate-h |
| CI: `erlang` rows `allow_fail: true` for a `runtime.mjs` reason that is gone, `commonJS` rows hard and judged against the drifted ledger (red), two `beam` rows that print `skipped` and pass; only the core member tested (`--lib rakun`) — the other 35 members only under pre-commit | `.github/workflows/test.yml:32-50,132-142` | gate-j |
| pre-commit warns and skips when the compiler is not found; `known-broken-examples.txt` branch | `scripts/git-hooks/lib/runner-standalone.sh` | gate-i |
| no `*.snap.new` guard | `.gitignore`, `scripts/git-hooks/pre-commit` (`grep -c snap.new` = 0) | gate-i |
| `botopink format --check` drift | `modules/rakun/**`, `modules/rakun-app/**` (PK-5, `../../02-std-and-packaging/README.md`) | — |

Not a red, filed here so it is not lost: `rakun-client` has 7 fixture-build tests that need
`BOTOPINK_BIN` (green 70/0 with it; the fallback `../../../botopink-lang/zig-out/bin/botopink`
exists only in the meta layout, not in CI's) — `113` makes `botopink test` export the compiler's
own path to the test process; the erlang examples crash at run time (`undef rakun_runtime:serve/2`:
`botopink run` does not compile the shipped sidecars outside test mode — `../../01-compiler/README.md`
§ 26's toolchain row, and `111` step 1's note); four `// LANGUAGE GAP` notes without a row
(`rakun/src/conditions.bp:287` a type named by string, `rakun-session/src/session.bp:7`,
`rakun-data/src/orm/query.bp:33` method `@Decl` params, `rakun-client/src/exchange.bp:48,78` no
JSON value model) — `113`'s marker check lists them and the rows go to `../../language-gaps.md`.

## Mechanism

The parser reads `if` only in `parseExpr`'s prefix arm (decision 137's positions); under an
operator, a unary, `??`, an index or inside a group it is `error[if-operand]`
(`parser/tests/effect_rejections.zig:266`; `tests/language/reject/if_in_parentheses`). A module
with one such site does not compile; every module that imports it reports its exports as
`unbound variable`, and every `*_build_test.bp` that asserts a build's stdout with
`asserts.contains` sees the compile error instead. That is why 24 sites in `rakun-data` and one in
`rakun-scheduling` red ~15 dependents: `rakun-data` is in the closure of `-app`, `-cache`,
`-devtools`, `-mail`, `-scheduling`, `-security`, `-session`, `-ssr-example`, `-stream`, `-tx`,
`-websocket`, the eight starters and `onze-server`.

## Steps

### Step 1 — migrate the 42 `(if …)` operand sites, in dependency order

Rewrite each as a binding before its use — `val x = if (c) { a } else { b };` — never by
re-admitting the form (gate-g). Measured at the open with
`grep -rnE "[=(,\[+:]\s*\(if \(|return \(if \(|\(if \(.*\) .*else .*\)\." repository/rakun --include=*.bp`
(42 lines; the compiler's own count decides — a site the grep missed is found by the cell).

**1a (chunk A) — `rakun-data` + `rakun-scheduling`, unblocks ~15 dependents:**

| File | Lines |
|---|---|
| `modules/rakun-data/src/orm/entity.bp` | 97, 150, 153, 156, 158, 160, 162, 177, 179, 180, 181, 183, 184, 186 |
| `modules/rakun-data/src/orm/query.bp` | 42, 127, 137 |
| `modules/rakun-data/src/orm/repository.bp` | 77, 121, 162, 205, 211, 227, 267 |
| `modules/rakun-data/test/migration_test.bp` | 185 |
| `modules/rakun-scheduling/src/jobstore/scheduler.bp` | 108 |

**1b (chunk B) — `rakun-messaging` + `rsocket` + `stream` + `ws`:**

| File | Lines |
|---|---|
| `modules/rakun-messaging/src/container.bp` | 167 |
| `modules/rakun-messaging/src/jms/jms.bp` | 109, 183, 198 |
| `modules/rakun-messaging/src/reliability/dispatch.bp` | 272 |
| `modules/rakun-messaging/test/registry_test.bp` | 76 |
| `modules/rakun-ws/src/ws.bp` | 136, 137 |
| `modules/rakun-ws/test/client_test.bp` | 94 |

**1c (chunk C) — `rakun-app`, `-web`, `-security`, `-release`, `-devtools`, `-cli`, `-actuator`:**

| File | Lines |
|---|---|
| `modules/rakun-app/src/metadata_routes.bp` | 352, 406 |
| `modules/rakun-devtools/src/db_console.bp` | 45 |
| `modules/rakun-release/src/release.bp` | 78 |
| `modules/rakun-security/test/oauth2_test.bp` | 45, 310 |
| `modules/rakun-web/test/dispatch_seam_test.bp` | 21 |

**Acceptance:**
- [ ] `grep -rn "error\[if-operand\]"` over a full `zig build test-libs -- --lib rakun-<m> --target erlang` log for each of the 25 members: 0 hits
- [ ] after 1a: `rakun-data·erlang`, `rakun-scheduling·erlang` compile; their `*_build_test.bp` cells run and name real failures, if any

### Step 2 — the `-> any` declarations (chunk C) and the `CacheLife` workaround (chunk D)

`health_test.bp:67,71,89` and `ssr_test.bp:309,313,318`: spell the host handle's type (`rc3-b`'s
answer is the spelling; until then a named opaque record the test owns). `rakun-metrics/src/export.bp`:
import `CacheLife` from `rakun-client` beside `RestClient` (the workaround), and file R3 as a row in
`../../01-compiler/01-checker` (the imported-type closure and the diagnostic's file attribution) —
the row's reproduction is this very pair of modules reduced to two files.

**Acceptance:**
- [ ] `rakun-actuator·erlang`, `rakun-app·erlang`, `rakun-metrics·erlang`: no `any-type-removed`, no `unknown type`
- [ ] the R3 row written with a two-module reproduction (`language-gaps.md` of this milestone, owner `01-checker`)

### Step 3 — `rakun-starter-test` depends on an onze member

`starters/rakun-starter-test/botopink.json:21-23`: replace `"onze": { "path": "../../../onze" }` by
the member(s) the starter imports (`onze`, `onze-test` — read the starter's `import … from "onze…"`
lines; the runner's error names the members). This is the only rakun→onze edge and it stays a
package edge (decision 113).

**Acceptance:**
- [ ] `zig build test-libs -- --lib rakun-starter-test --target erlang` → `pass`

### Step 4 — the two `SKIPPED` cells become assertions (gate-h)

- `rakun-session/test/store_test.bp:68-71`: the Redis arm runs against `rakun-test`'s RESP double
  on a loopback port (the double `../../03-rakun/12-rakun-cache/README.md` specifies — this front
  lands the cell against the double only if the double exists; else the cell asserts the
  `ets:memory` datasource and the Redis arm is deleted with a `../../deferred.md` row). The
  `env.read("RAKUN_TEST_REDIS_URL")` read and the `SKIPPED` print are deleted.
- `rakun-websocket/test/broadcast_test.bp:102`: the cell asserts a same-node `pg` broadcast to two
  subscriber processes; the cross-node arm and its `skipped:` acceptance are deleted.

**Acceptance:**
- [ ] `grep -rn "SKIPPED\|skipped: \|RAKUN_TEST_" repository/rakun/modules --include=*.bp` → 0 hits (the `migrate.bp` record field named `skipped` is not a verdict — the grep is on the two spellings above)

### Step 5 — chase every leftover red to green; the examples build

After steps 1–4, re-run all 30 erlang cells and the examples gate. Expected leftovers to verify by
running: the websocket `limits_test.bp:48` (R6 — a real defect in the queue cap or a timing
assumption; fix the library or the test's clock, never widen the assertion), `orm_test`
`__rkDerived_*` names, `examples/rakun-ssr` (build), and any `asserts.contains` red that survives
its module compiling. A red that is the compiler's is a `language-gaps.md` row for
`../../01-compiler/` and the cell stays red — this front then reports it as its blocker in
`../../status.md` instead of ticking.

**Acceptance:**
- [ ] `for m in $(members); do zig build test-libs -- --lib $m --target erlang; done` → every line `pass` or `no tests`; `0 failed`
- [ ] `(cd examples/rakun-ssr && botopink build --out $(mktemp -d))` exit 0; the three examples build

### Step 6 — the repository's own gate: greps, hook, guard, CI (chunk D; gate-i, gate-j)

- `scripts/git-hooks/lib/runner-standalone.sh` stage 1b (R4): the greps match code, not comments,
  and whole identifiers (`\bonze\b` outside `//` lines; the UI-type grep on the type names front
  22/23 forbid, not the substring `Element`); reword the seven comment lines so a reader is not
  told the greps are wrong. The rule stays a refusal.
- `.gitignore`: `*.snap.new`, `*.snap.md.new`.
- `scripts/git-hooks/pre-commit` (via `runner-standalone.sh`): refuse a staged `*.snap.new` /
  `*.snap.md.new` (`git diff --cached --name-only`, as `botopink-lang/scripts/gate.sh:120-135`);
  `locateBotopink` miss → `fail`, not `warn`; the `known-broken-examples.txt` branch deleted.
- `.github/workflows/test.yml`: the matrix is `erlang` × {ubuntu-22.04, macos-14, windows-2022},
  every row `allow_fail: false`; the `commonJS` and `beam` rows deleted (decision 113; `botopink
  test` cannot run beam — a row that prints `skipped` measures nothing); the test step runs **every
  member and example** (the runner's discovery from the workspace root — no `--lib rakun` alone);
  the examples gate runs on the erlang row; the windows row installs OTP via `erlef/setup-beam`
  (as botopink-lang's does) and is subject to gate-f's answer for windows drift — if it cannot be
  hard, it is deleted, not soft.

**Acceptance:**
- [ ] `(cd repository/rakun && scripts/git-hooks/pre-commit)` passes stage 1b on the current tree and still fails on a synthetic `import … from "onze"` in a `rakun-*` module
- [ ] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` → ≥ 1 each; a staged `x.snap.new` makes the hook exit 1
- [ ] `grep -c "allow_fail: true" .github/workflows/test.yml` → 0; `grep -c "target: commonJS\|target: beam"` → 0; the step's log lists all 38 members
- [ ] the workflow green on `feat` after the push (the maintainer's landing step)

### Step 7 — PK-5: `botopink format` over `modules/rakun` and `modules/rakun-app`

One reformat-only commit after steps 1–6 (the migration and the reformat touch the same files —
same owner, sequenced). `botopink format --check modules/rakun modules/rakun-app` exit 0. Decision
132's refusal of the `;` after a braced block (`../../01-compiler/16-formatter`) waits on this.

**Acceptance:**
- [ ] `repository/botopink-lang/zig-out/bin/botopink format --check repository/rakun/modules/rakun repository/rakun/modules/rakun-app` → exit 0; every erlang cell still `pass`

## Gate

- [ ] `zig build test-libs -- --lib <m> --target erlang` for all 38 members (25 modules, 3 examples, 8 starters — `find repository/rakun/{modules,examples,starters} -maxdepth 1 -mindepth 1 -type d`): `0 failed`
- [ ] `scripts/gate.sh --cold` in `repository/botopink-lang` with this rakun checkout: stage 8 has no rakun line but `pass` / `no tests` (the restricted commonJS lines disappear only with 113 — until then they print as today and this front's gate reads the erlang lines)
- [ ] `(cd repository/rakun && scripts/git-hooks/pre-commit)` green end to end (greps, 38 `botopink test`, 3 example builds); the workflow green
- [ ] `repository/rakun/AGENTS.md` updated (the hook's greps and refusal, the CI matrix, the removed env variables); commit on `front/gate-rakun` (or `-a`/`-b`/`-c`) in the rakun submodule; no push, no merge

## Blast radius

- Every `03-rakun` front (`04`, `08`, `09`, `11`, `12`, `13`, `15`, `17`, `19`, `22`, `65`, `73`,
  `74`, `79`, `81`, `88`, `91`, `92`, `93`) starts from this front's landing — they share
  `rakun-data/src/orm/**`, `rakun-messaging/src/**`, `rakun-app/src/**`, the starters' manifests
  and the test files above. `03-rakun/README.md` already says so.
- `onze-server·erlang` (100) compiles only when `rakun-data` and `rakun-scheduling` do: 100 verifies
  its `onze-server` cell against this front's tree.
- `113` deletes the 18 + 17 rakun ledger lines in the commit that lands the manifest rule — this
  front does not edit the ledger; `113` also lands the `BOTOPINK_BIN` export the fixture-build tests
  need in CI.
- `../../01-compiler/01-checker` receives R3.

## Notes

- rakun is erlang-only (decision 113): nothing here adds a node binding, an `.mjs` or a commonJS
  row; the commonJS cells stop existing with gate-a.
- The compiler knows no library: a red that is the compiler's (R3, or a checker gap the migration
  exposes) is filed, not worked around by deleting the test.
