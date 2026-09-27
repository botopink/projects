# Closure — 1.0.10-beta

**Closed 2026-09-26**, at meta `feat` = `origin/feat` = `985582ac`, `botopink-lang` `83360f39`,
rakun `22574a4`, jhonstart `4133646`, emilia `c486f93`, onze `9a579c8`, erika `fc4bf55`,
vscode-extension `cbe31cb`. The milestone was the open half of the compiler milestone carried as one
front beside the whole ecosystem milestone: the assertion library, the snapshot engine and `@src()`
that every library test stands on; the package cut; and the four libraries against their references —
rakun against Spring Boot 4 and the server half of Next.js, jhonstart against the React half, emilia
against Tailwind CSS v4, onze as the orchestrator that takes the old mocking library's name. One
hundred and fifteen fronts across seven tracks; decisions 68–143.

**Where the open work went:** [`specs/1.0.11-beta/`](../1.0.11-beta/overview.md) — every open item,
re-cut by ownership of files into fronts that run in parallel, with the deep dives an open item
still needs copied beside it; the map is [`1.0.11-beta/carried.md`](../1.0.11-beta/carried.md) and
each track's `carried.md`. [`decisions-taken.md`](./decisions-taken.md) **stays here** as the record;
1.0.11-beta continues the numbering at 144. [`decisions-pending.md`](./decisions-pending.md) stays
as the full text of every choice a front made; 1.0.11-beta's copy carries the twenty-seven open
questions verbatim and indexes the rest.

**How this record was derived.** Not from the specs' own claims: three read-only audits at the
commits above, each verifying every "landed" box it could against the code, the tests, the
`expected-failures.txt` and ledger files, a freshly built `botopink`, and scratch-project probes —
plus one full run of `scripts/gate.sh --cold` with every stage forced past a red one, and one run of
each library's own gate. Where a box could not be verified the row below says **unverified** and
names what would verify it.

---

## What the milestone measured, at its close

| | Reading | Source |
|---|---|---|
| `scripts/gate.sh --cold` | **8 of 10 stages green.** `zig build test` 2585 / 2585; runtime-parity 1427 pairs, 0 differing; `beam_export_audit` 488 / 488; `test-bpmp`, `test-cli`, `test-docs` (93 fences, 77 checked, 8 skipped) green | the forced run, 2026-09-26, load 58–68 on 16 cores |
| `zig build test-libs` | **RED — 84 passed, 36 failed cells**, 0 known red, 13 restricted as pinned, 9 without tests; 21 restricted cells missing from the ledger, 9 pinned counts moved | the same run; `scratchpad/libs.txt` |
| `zig build test-language` (`--target all` = commonJS · erlang · wasm) | **RED — 1244 passed / 1 expected / 1 failed**: `[wasm] modules/import_same_name_from_two_packages` prints `0` for `<p>` (`wat.zig`'s link loop drops a colliding `type`) | the same run |
| `tests/language/run.sh --target beam` | 382 / 2 / 0 — beam executes; not in `--target all` (`run.sh:155`) | the same run |
| `tests/language/expected-failures.txt` | **3 lines** (from 58 at 1.0.5's close, 7 before the last merge): two beam sidecar lines (`03-beam`), one wasm `ck-host` line (`05-wasm`) | the file at `83360f39` |
| `scripts/restricted-targets.txt` | **21 lines**: 17 rakun commonJS rows by design (decision 113), `jhonstart-dom-test erlang 1`, and three `0`-failure lines that outlived their reason (`erika-linq`, `jhonstart-counter`, `jhonstart-todo` on erlang) | the file; the run |
| `scripts/known-red-libs.txt` | 0 live lines (`scripts/AGENTS.md` still names two — stale) | the file |
| `scripts/format-check.sh` | green over its six `TREES`; **226 files red outside them** (`libs/std` 19, `examples/` 2, `tests/language` 199, `modules/compiler-cli/tests` 5) and one deliberately unlexable fixture | re-measured at the close |
| `zig fmt --check modules` | **11 files red** | re-measured |
| Library rows | std 4 / 4 both rows · emilia 17 / 17 (734 / 734 tests, 15 examples) · erika 3 / 3 · jhonstart 15 / 15 (204 tests both rows) · **onze 2 pass + 5 fail (commonJS), 2 + 6 (erlang)** · **rakun 6 pass + 25 fail (erlang)** | the run |

**Why the two library rows are red at the close, and were not before it.** The last merge into
`feat` (`front/residual-checker-3`, compiler `dd3c873f` → `86f815b9`) made an `if` expression in
operand position a parse error (`if-operand`, choice `rc3-a`) and deleted `any` (decision 31,
`any-type-removed`). rakun (≈40 sites) and onze (≈25 sites) were written against the previous
compiler and were not migrated in the same landing; nearly every other red cell is a cascade of a
module that no longer parses. One more is structural: `rakun/starters/rakun-starter-test` still
depends on `onze` by path, and `onze` became a workspace. The counts in the fronts table below are
the fronts' own acceptance counts **as they stood before that merge**; the gate they must meet again
is `1.0.11-beta/00-gate`'s first front.

---

## Fronts

Status: **done** — every step landed or struck with a reason · **partial** — steps landed, named steps
open · **open** — never started. The evidence column names what verified the row; "boxes" are the
README's own checkboxes at the close.

### `00-compiler-carry-over` (25 sub-fronts, items C-01…C-33)

| Front | Status | What landed (evidence) | What did not, and where it went |
|---|---|---|---|
| `01-checker` | **partial** (≈97 %) | Decision 8's inference whole — `unknown`, unions, `is` and narrowing (also through `&&` / `||` / `while`), arm resolution, exhaustiveness, generics, trailing defaults (C-04), the residual rows R1–R9, the `.withLoc` sweep, the parser gaps, the flat bare-name table, `any` deleted, located errors; probes: `Box<i32>(value: 1).get()` → `1`, `fn get(b: Box)` refused, `val unknown` refused | `[1, "a"]` join (D5), `fn` in an enum section body, ck2-c's leading default (decision only); the language-gaps rows it owns (record-value call, second binding, function-typed `case` arms, `throw` in an arm, `try` in a lambda lg-a, captured `var` lg-b …) → `1.0.11-beta/01-compiler/01-checker` |
| `02-erlang` | **partial** | Steps 1–3, 6–8, 10; every "row no step named"; module load, `lastIndexOf`, `case` on a record named like a variant, `?T` index, `return;` in `@Task<void>`, multi-subject `case`, an imported fn as a value; JS-4's erlang twin | Step 9 (the dead tail-`case` lowering), C-07's fixtures, C-06's `KNOWN` notes; verified defects with no cell — BIF-shadow `element/2`, `__Loop`, `indexOf` in bytes, module-level `@print` in a dependency (C-34), `Array.unique` (C-35), `\u{…}` truncation (C-36) → `01-compiler/02-erlang` |
| `03-beam` | **partial** | BR5 / C-24, steps 2–5, the C-03 beam half, `split("")`, decision 141; 382 / 2 / 0 on `--target beam`; audit 488 / 488 | JS-4's beam twin (`val Label(t, w) = Tag.Label(…)` → `{unresolved_identifier,t}`, verified), C-07's tails, **the beam build ships no erlang host sidecar** (the 2 expected-failure lines), beam into `--target all` → `01-compiler/03-beam`, `26-cli-tooling`, `12-language-tests`; the lines themselves → `00-gate` |
| `04-js` | **partial** (nearly done) | Steps 1, 2 (D1–D4), 4–7; `await` in `if`, `$` template quoting, enum-implements-behavior, multi-subject arms | The one `@block` IIFE site, `$stringify` in a Node template (verified unsupported), the `tsc` gate as a script, `unwrapOrThrow` (undecided), C-37 → `01-compiler/04-js` |
| `05-wasm` | **partial** | Steps 1–3, 5–9 (`?.` chain, `map`, tail calls); the last batch closed five wasm lines (multi-subject `case`, unit-enum print, generic specialization, HOF named fn, `val assert` record pattern) | `run/external_wrapper_keeps_refusal` (ck-host), the link loop's dropped `type` (the red cell), 18 silent-degradation stubs, the pinned primitive-method traps, `==` on a type parameter (re-measure) → `01-compiler/05-wasm`; the line → `00-gate` |
| `07-review-backlog` | **open** | Nothing (step 5's `snap_audit.sh` classification is on disk by another front's hand) | C-22 whole → `01-compiler/07-review-backlog` |
| `08-hygiene` | **partial** | Groups A–E, the links, `docs.md`'s re-derived table, `test-docs` green | 14 stale `primitives.d.bp` comments, the `@external(` comments, 4 test-file comments, the transport-error test, 11 `zig fmt` files, `@BeamMemory`'s unpublished docs text, C-18's five document corrections → `01-compiler/08-hygiene`; `zig fmt` → `00-gate` |
| `09-ecosystem-residuals` | **partial** | erika reformatted and verified, §5.3b, rakun's erlang-only story, `AGENTS.md` re-derived | `erika-linq`'s dead ledger line, C-14's `->` arms (maintainer's word), the four libraries' `format --check` and decision-132 migration (C-13) → `01-compiler/09-ecosystem-residuals`, `16-formatter`, `00-gate` |
| `11-tooling` | **done** | Every step and gate ticked (C-19); the gate lock, the stale-binary refusal, the run totals, ledger pins, the test-path race | one comment in `hover.zig:277` (08's) |
| `12-language-tests` | **partial** | Steps 1, 4 (the DSL-hygiene cells exist), 5, front 15's cells | beam into `--target all`, two stale `AGENTS.md` rows, the 199-file reformat → `01-compiler/12-language-tests`, `16-formatter` |
| `13-module-identity` | **done** (C-01) | Halves 1–3 and every gate: one BEAM module per `type` and `behavior`, the type's atom in the value, `is` / union `case` / §7 print on named types, `out/erl/` + `out/beam/`, the collision fixtures | one box gated by decision 23 (recorded as a decision row, not work); the 12 deep dives stay here |
| `14-comptime-on-beam` | **partial** (C-20 absorbed by C-26) | § Delivered whole; the prelude-parse memo that blocked the N=200 budget is landed (`erlang.zig:288`) | The `unsupported_method` fixture (likely landed — verify), the N=200 re-measure, three round-trip fixtures, `\u{…}` (C-36) → `01-compiler/14-comptime-on-beam`, `02-erlang` |
| `15-language-surface` | **done** | `T[]`, the chain from every receiver, `42.toString()`, `parseBlockBody`, decision 30's index and slice, decision 28's `??`, bodyless `fn`; at the close `Box<i32>(…).get()`, `fn get(b: Box)` and `any` also verified closed | `decision-29-parser-half.patch` (C-13's third step) → copied into `01-compiler/16-formatter`; its gap rows → `01-checker` and `language-gaps.md` |
| `16-formatter` | **partial** | Lossless and idempotent, `format --check` whole-project with `reject/**` exempt, the width rules (16-a / 16-b, decision 133), `;` optional and not printed, the compiler trees migrated, `builtins.d.bp` formats | C-13 step 3 (`tests/language` 199, rakun 454 / jhonstart 40 / erika 28 / onze 1 — unverified counts — then the parser refusal), `commaList` and the one-step pipeline width, `arrow_when_empty`, the siblings' reformat at C-12's rules → `01-compiler/16-formatter` (`c13-migrate.py` copied) |
| `17-beam-memory` | **partial** (C-05 done) | Steps 0–5, 7 (every cell and reject cell on disk), 8 specified; `@BeamMemory` on erlang and beam | `keyed = true` (row-per-key `Dict` under `Ets`) not lowered, the docs text unpublished, the rakun migration → `01-compiler/17-beam-memory`, `08-hygiene`, `03-rakun` |
| `18-comptime-runtimes` | **partial** (C-26 landed) | BEAM bytes emitted directly, the WAT comptime runtime on wasm3, snapshots per runtime, the compiler on wasm in the browser | The CI matrix run and `release.yml`'s rows (maintainer, after push), `test-web` on the matrix, the bench table; `wat-runtime.md` § 7's limits recorded → `01-compiler/18-comptime-runtimes` |
| `19-use-activation` · `20-builtins-surface` · `21-effect-chain` · `22-loops` | **done** (C-27…C-30) | The `use` construct; `builtins.d.bp` agreeing with itself; `@Context<Base>` as the owner marker; `loop` / `while` / `for` / `for await` | 19's two findings (a transitive workspace dependency; the provider stack behind `@getContext`) → `01-compiler/26-cli-tooling`, a design row |
| `23-std-purity` | **partial** | Steps 1–6: std as a pure root · `io/` · `testing/`, the import tree; `docs.md`'s grammar replaced (verified) | The gate rows (four targets, `project_graph.zig` cells, five `AGENTS.md`) — unverified; 23-a/b/c, std-c to confirm → `01-compiler/23-std-purity` |
| `24-effects-by-return` | **partial** (C-32 landed) | Decisions 118–135: the return type is the annotation, `@Task<T>` never fails, only `@Result` fails, `@Component<C, T>`, `@Iterator` / `@Stream`, `async { }`; the libraries and every example in that spelling | E3's guide fences as one program (only § 7's `serverAction` stubs hold it), `unwrapOrThrow`, 24-a/b/c/g, the `@Result`-per-item cost → `01-compiler/24-effects-by-return` |
| `25-gate-perf` | **done** (C-33) | Steps 1–4 and the gate: the same gate in less wall clock, the green-tree record | The per-cell dependency compile (~4–6 s a cell) and the worktree-hooks proposal → `00-gate`'s performance front, `01-compiler/25-gate-perf` |
| Items with no directory | | C-02 (the index as a method call — all six boxes landed, unticked), C-05, C-08, C-17, C-21, C-24 (`wip/br5-beam-templates` branch to delete), the checker half of C-25 | C-14 (`->` arms), C-18's documents half, C-25's sidecar-named-like-an-atom half, C-22, C-23 → `01-compiler` |

### `01-std` (6 sub-fronts) — **done in code; partial in record**

| What landed (verified) | What did not |
|---|---|
| `@src()` and `SourceLocation` on four backends; a `try` in a test fails located · `testing.asserts` (26 assertions + `errorText`, builds on four targets) · `testing.snapshots` (`.new` on mismatch, no update flag) · `testing.mocks` (`#[mocks.mock]` through the handle) · the std tree (`root`, `io/`, `testing/`) · the JSON writers, `Json`, `json.decode` (decision 142) · **`01-std-lib-enablement` steps 1–14** (`escape`, `path`, `fs`, `encoding`, `hash` with b64url and `equalsConstantTime`, `clock`, `random`, `regex`, `process`, `io.net` TCP and TLS, the json writers) · **`02-std-async-primitives`** (`delay`, `allOf`, `all`, `race`, `runAll`, `raceOf`, `timeout`, the gate; load-independent verdicts) · **`03-std-content-hash`** (`contentHash`, `strongHash`, `cacheKey`, `etag`, `fingerprint`) · **`04-routing-lib`** (bundled, 8 modules, 66 tests; imported by rakun, jhonstart, onze-cli) · **`05-actions-lib`** (`refreshValue` consumed by both halves) · **`06-validation-lib`** (54 tests; the rakun member deleted) | The `*.snap.new` guard in the five library repositories; the snapshot map (4 of ~40 `.snap`); `snapshots.bp`'s private file helpers; the routing and validation boxes that close by decision (01std-a, 01std-c); six gap rows never written (array destructuring, lifecycle hooks, `isOkAnd`, `throwsType`, `typeOf`, `@Result` pass-through, structural `==`); many boxes true on disk and unticked → `1.0.11-beta/02-std-and-packaging` (all of `01-std/01…06` closes on tick or confirmation; the work is `97-std-dedupe`), `00-gate` |

### `02-packaging` · front 95 — **partial**

| What landed | What did not |
|---|---|
| One manifest reader (`modules/manifest`) shared by the CLI, the LSP, the lib-test-runner and bpmp; package vs workspace; object-form `dependencies` (`path`, one-pin `git`, `{workspace: true}`); `scanRoots`; located errors; `docs/botopink-json.md` · every library a workspace, all 49 members with `files`, no `../../` path · every `-test` member exists · the relocation cut (`jhonstart-html`, `jhonstart-link`, `rakun-app`; 95-a, b, e) · no rakun commonJS remains, `runtime.mjs` gone · **the onze takeover happened** (decision 79): `repository/onze` is the orchestrator, 8 members, built on top of tag `mocking-lib-final` on the same remote — not as the orphan branch 95-d assumed | A `README.md` per example (29 missing); the `assert<Subject>` helpers in emilia-test, rakun-test, erika-test; `format --check` drift in four trees; the three onze ledger lines (**the onze gate row is red today for their absence**); lg2-v (`subdir`); 95-a…e to confirm, 95-d amended → `02-std-and-packaging/98-packaging-tail`, each library's track, `00-gate` |

### `03-rakun` (51 fronts) — **1787 of 1981 boxes**

**done** (16): 07 middleware · 10 security-auth · 12 cache · 15 messaging (on the in-process broker) ·
20 websocket · 21 hateoas · 23 ssr-pipeline · 61 parallel/intercepting routes · 63 navigation
signals · 72 auto-configuration · 73 starters · 76 actuator security/probes · 80 devtools · 84
persistent jobs · 85 mail · 87 audit and exchanges. **partial** (34): 04 (57 / 5) · 05 (60 / 2) ·
06 (45 / 8) · 08 (51 / 2) · 11 (50 / 13) · 13 (27 / 1) · 14 (33 / 1) · 16 (25 / 1) · 17 (35 / 2) ·
18 (31 / 1) · 19 (17 / 11) · 22 (33 / 1) · 24 (37 / 2) · 25 (23 / 4) · 60 (43 / 1) · 62 (43 / 2) ·
64 (39 / 2) · 65 (40 / 2) · 66 (38 / 2, jhonstart's) · 74 (31 / 4) · 75 (44 / 2) · 77 (40 / 1) · 78
(47 / 2) · 79 (48 / 6) · 81 (38 / 5) · 82 (46 / 3) · 83 (40 / 3) · 86 (29 / 2) · 88 (24 / 9) · 89
(24 / 3) · 90 (19 / 8) · 91 pulsar (6 / 21) · 92 (16 / 10) · 93 (17 / 11). **open** (1): **09
data-nosql** — no code. 25 members on disk, every manifest `["erlang"]`; the `rakun_runtime.erl`
listener over HTTP and TLS; 328 / 0 on the core from a cold cache before the last merge.

Not realised: the snapshot map (`test-snap.md`, 11 647 lines, 57 helpers — 0 `.snap` files); 7 of
the 10 reference examples; `modules.md` differs from the tree in 20 rows (no `rakun-pulsar`,
`rakun-ws` never renamed `rakun-soap`, `rakun-starter-app` missing). Two `// LANGUAGE GAP:` markers
without a row (13, 21). → `1.0.11-beta/03-rakun` (19 fronts), the migration off `(if …)` operands →
`00-gate`.

### `04-jhonstart` (9 fronts) — **partial, close to done**

**done**: 94 element surface · 28 server components · 29 client directive · 32 metadata.
**partial**: 26 router (one late-signal handler still twice) · 27 link (the `reconcile` driver not
written) · 30 render/streaming (siblings through `__jhEachCompleted`, not `async.runAll`; two tests
missing) · 31 error boundaries (the digest, 31-b) · 67 forms (the four DOM-side boxes). 204 tests on
both rows; no `// LANGUAGE GAP:` marker in code; the module-level snapshot map not realised. Two
dead ledger lines (`jhonstart-counter`, `jhonstart-todo` on erlang pass). → `1.0.11-beta/04-jhonstart`
(3 fronts), `00-gate`.

### `05-emilia` (22 fronts) — **done but one box**

Fronts 33–47, 54, 55, 57, 58, 59 done; 48's last box is asserted by onze; 56's `hashHex` → std
`contentHash` is the one open code box. 734 / 734 on both rows, 15 examples green, measured against
Tailwind 4.3.2 (05emilia-a…l; `reference-coverage.md` 244 / 267). Five families not at upstream's
form (transition presets, `backdrop-opacity`, `border-spacing`, `-webkit-backdrop-filter`,
`divide-*`'s style var); `emilia-card` depends on jhonstart against decision 114; the per-front
snapshot suites and eight cross-front examples not written; three stale gap markers in frozen
examples. → `1.0.11-beta/05-emilia` (2 fronts).

### `06-onze` (9 fronts) — **partial; 68 done**

68 client bundle **63 / 63** (11 modules, 42 tests both rows). 49 stand-up 33 / 36 · 50 CLI 34 / 45
(`onze dev` not written) · 51 image 31 / 34 · 52 font 24 / 25 · **53 example app 19 / 41** (the
read path of the blog, the boundaries, the gate; no write path, no E2E runner, no browser harness) ·
69 styling 23 / 24 (the public root waits on rakun 69-b) · 70 image response 39 / 43 · 71 release
33 / 41 (no bootable tarball verified). 8 members (`onze-server` is the eighth the specs did not
count); the three restricted cells have no ledger line — **the onze test-libs row is red for it**
before any code defect. → `1.0.11-beta/06-onze` (5 fronts), `00-gate`.

---

## Decisions

Taken: 68–90, 95, 96, 98, 102–143 (91–94, 97, 99–101 were questions resolved inside other
decisions — used, not free). Open at the close: 26 questions (`ck2-c`, `lg-a`, `lg-b`, `lg2-a…w`)
plus `ck-host`, which was raised and never counted. Implementation choices awaiting confirmation:
≈80 lettered ids across every track (`24-*`, `01std-*`, `std-*`, `01c-*`, `ck2-*`, `rc3-*`, `23-*`,
`95-*`, `03r-a…x`, `16-*`, the jhonstart, emilia, onze and `lem-*` sets). All carried to
[`1.0.11-beta/decisions-pending.md`](../1.0.11-beta/decisions-pending.md) with ids unchanged; the
full text of the choices stays in [`decisions-pending.md`](./decisions-pending.md) here.

## What this directory keeps

Everything, frozen: the track READMEs, the 115 front directories with their deep dives and
examples, `modules.md` / `test-snap.md` per library, `contracts.md`, `deferred.md`,
`language-gaps.md`, `unification.md`, both decision files, and [`status.md`](./status.md) as it
stood at the close. Nothing here is edited again; a stale statement inside a frozen README is
listed in the 1.0.11-beta track's `carried.md` that supersedes it, not fixed in place. The files an
open item still needs were **copied**, not moved, so every link inside this directory still
resolves.
