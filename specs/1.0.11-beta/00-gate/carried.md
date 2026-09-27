# Carried into 00-gate — what each chunk and each hand-over became

Every item that reached this track — report A's chunks (C1–C9), report L's chunks (A–H) and every
other track's *Handed to 00-gate* row — appears once below with the front that owns it. An item
this track hands *out* (a compiler row) is in the last table. Measured at the milestone's open.

## Report A's chunks

| Chunk | What | Front |
|---|---|---|
| C1 rakun repo: the `(if …)` operands, `-> any` ×2, `rakun-starter-test/botopink.json:21`, leftovers (websocket `limits_test:48`, metrics `export_test`, `orm_test` `__rkDerived_*`) | the 42 sites (step 1a–1c), R2 (step 2), R5 (step 3), the chase (step 5) | [`99-gate-rakun`](./99-gate-rakun/README.md) |
| C2 onze repo: ~25 sites + cascades | the 23 sites (step 1), `onze-og`'s unknown type and the cascades (step 2) | [`100-gate-onze`](./100-gate-onze/README.md) |
| C3 ledger: 21 missing + 9 moved lines, the 3 zero lines, `scripts/AGENTS.md` stale, the policy question | gate-a answered as "delete the file": the manifest rule and the restriction audit (steps 2–3), `AGENTS.md` (step 4); the three zero lines close by widening in 101 and 108 | [`113-gate-ledger-and-scripts`](./113-gate-ledger-and-scripts/README.md) · 101 · 108 |
| C4 codegen/wasm: mangle colliding linked types; 18 stubs → hard errors; ck-host + the wasm line | steps 1, 2, 3 | [`110-gate-wasm`](./110-gate-wasm/README.md) |
| C5 codegen/beam + CLI sidecar shipping; `run.sh:155` beam in `all`; `expected-failures.txt` | steps 1, 2, 4 | [`111-gate-beam-and-targets`](./111-gate-beam-and-targets/README.md) |
| C6 formatter trees: `libs/std` 19, examples ×2, `tests/language` 199, `compiler-cli/tests` 5 → `TREES`; the lexer-error fixture structurally; the header | steps 2, 3, 4; gate-c | [`112-gate-format`](./112-gate-format/README.md) |
| C7 `run.sh` honesty: honour `modules/` `targets`; review the 17 `.targets`; modules/ test-kind cells on wasm once the CLI can | steps 3, 5; gate-d; the test-kind arm stays a CLI capability (§ Notes) | [`111-gate-beam-and-targets`](./111-gate-beam-and-targets/README.md) |
| C8 docs: `reject` mode for `:1351`, `:1765`; a project harness for `:223`, `:235` | step 1; gate-e | [`114-gate-docs-and-ci`](./114-gate-docs-and-ci/README.md) |
| C9 CI windows row `allow_fail` | step 3; gate-f | [`114-gate-docs-and-ci`](./114-gate-docs-and-ci/README.md) |
| (not a chunk) `zig fmt --check modules` 11 files; stage 1 checks staged files only | step 1 | [`112-gate-format`](./112-gate-format/README.md) |
| (not a chunk) the gate's wall clock (stage 8 1944 s, stage 9 794 s under load) | the maintainer's explicit ask | [`115-gate-perf`](./115-gate-perf/README.md) |

## Report L's chunks (each repository's own CI)

| Chunk | What | Front |
|---|---|---|
| A `rakun-data` + `rakun-scheduling` if-operand (unblocks ~15 dependents) | step 1a | 99 |
| B `rakun-messaging` + `rsocket` + `stream` + `ws` | step 1b | 99 |
| C `rakun-app`/`web`/`security`/`release`/`devtools`/`cli`/`actuator` (if-operand + `any` + the hook's grep fix) | steps 1c, 2, 6 (R4) | 99 |
| D `rakun-metrics` `CacheLife` workaround + CI cleanup (commonJS/beam rows, `allow_fail`, every member, `BOTOPINK_BIN`) | step 2 (workaround), step 6 (CI); `BOTOPINK_BIN` → 113 step 4b | 99 · 113 |
| E onze if-operand + `onze-server` in onze's CI | steps 1, 4 | 100 |
| F stale restrictions + `jhonstart/repro/**` + erika `beam` rows | 101 steps 1, 3b; 108 steps 1, 2 | 101 · 108 |
| G ledger re-measure last | replaced by gate-a: deleted, not re-measured | 113 |
| H compiler: imported-type re-check + mislocated diagnostic (R3) | handed out (last table) | `../01-compiler/01-checker` |
| the meta repository has no `.github/` | step 4: the meta workflow is a front step | 114 |
| CI coverage: core member only (emilia, erika, jhonstart, rakun); examples only on commonJS | gate-j; each repository's CI step | 99 · 100 · 101 · 108 · 109 |
| five `// LANGUAGE GAP` notes with no row (emilia `tokens.bp:2194`; rakun `conditions.bp:287`, `session.bp:7`, `query.bp:33`, `exchange.bp:48,78`) | step 4c: the marker script + row stubs | 113 (rows' substance: `../01-compiler/`) |
| the erlang examples crash at run time (`undef rakun_runtime:serve/2`, sidecars outside test mode) | not gated; the toolchain row stays `../01-compiler/` § 26's; 111 step 1 notes it for `botopink run --target beam` symmetry | 111 (note) · `../01-compiler/26-cli-tooling` |

## The other tracks' "Handed to 00-gate"

| Track · item | What | Front |
|---|---|---|
| `01-compiler` · EF-1, EF-2 (beam ships no sidecar) | step 1 | 111 |
| `01-compiler` · EF-3 (`external_wrapper_keeps_refusal`, ck-host) | step 3 | 110 |
| `01-compiler` · ZF-1…11 (`zig fmt`) | step 1 | 112 |
| `01-compiler` · FC-1 (`libs/std`), FC-2 (two examples), FC-3 (`compiler-cli/tests`) | step 2 | 112 |
| `01-compiler` · FC-4 (`tests/language` 199 + the lexer-error fixture) | step 3; gate-c | 112 |
| `01-compiler` · RT-1…3 (`erika-linq`, `jhonstart-counter`, `jhonstart-todo` at `0`) | widen: 108 step 1, 101 step 1; the lines go with the file: 113 | 101 · 108 · 113 |
| `01-compiler` · "beam outside `--target all` is 12's step 1" | 111 step 2 does it (12's box closes on 111's landing) | 111 |
| `01-compiler` · C-11, C-13 (16 · 00-gate), C-23 item 5 | C-13's `tests/language` share and C-23's `zig fmt` → 112; C-11 stays 16's | 112 |
| `01-compiler` · 25-gate-perf follow-ups (§ Not a step, step 4's last paragraph) | steps 2, 6 | 115 |
| `02-std-and-packaging` · STD-1 / EM-6 (`*.snap.new` guard in five repositories) | each repository's hook step; verified by 113 step 5; made continuous by 114 step 4 | 99 · 100 · 101 · 108 · 109 · 113 · 114 |
| `02-std-and-packaging` · PK-1 / ONZ-0 (three onze ledger lines) | not written: gate-a deletes the ledger | 113 |
| `02-std-and-packaging` · PK-5 (format drift in `jhonstart`, `jhonstart-link`, `rakun`, `rakun-app`) | 101 step 4, 99 step 7 | 99 · 101 |
| `02-std-and-packaging` · STD-10 (a marker in a frozen 1.0.10 example; the rows `asserts-api.md` names) | the marker script excludes `specs/1.0.10-beta/**`; rows are `language-gaps.md`'s | 113 step 4c |
| `02-std-and-packaging` · STD-4 (the `01-std` Gate boxes, "seven remotes unified") | the track's exit gate is their definition | `README.md` § Exit gate |
| `02-std-and-packaging` · 95 ("step 2 closed with the onze rows") | closes with 100 + 113 | 100 · 113 |
| `02-std-and-packaging` · STD-11 (compiler rows: `io.process` shadows `process`; non-ASCII literal on erlang) | not gate items — `language-gaps.md` rows for `../01-compiler/` (04-js, 02-erlang) | handed out |
| `03-rakun` · 03r-ah (the eighteen commonJS ledger lines structurally absent) | gate-a answered as recommended | 113 |
| `03-rakun` · the env-gated cells (`RAKUN_TEST_REDIS_URL`, `broadcast_test.bp:102`; 03r-aa) | gate-h; step 4 | 99 |
| `03-rakun` · "rakun line in `known-red-libs.txt`: none" | the file is deleted | 113 |
| `04-jhonstart` · JH-LEDGER (`counter`, `todo` at `0`; `dom-test` at `1`) | step 1 (widen), step 2 (dom-test: structural under gate-d) | 101 |
| `04-jhonstart` · PK-5, STD-1 | steps 4, 3 | 101 |
| `04-jhonstart` · the spec markers under `67/examples` (frozen; the copies carry none) | the marker script excludes `specs/1.0.10-beta/**` | 113 step 4c |
| `07-bundled-libs` · "`00-gate` green before any cross-repository refactor" | the track's exit gate | `README.md` § Exit gate |

## Handed out of this track

| Item | To | Why |
|---|---|---|
| R3 — an imported type's field type unresolved at the import site (`RestClient.cacheLife: CacheLife`), diagnostic attributed to the importing test file at a line past its end | `../01-compiler/01-checker` (imported-type closure; diagnostic file attribution) — 99 files the row with a two-module reproduction | a compiler defect; the library workaround (import `CacheLife`) is 99's |
| the five library `// LANGUAGE GAP` notes | `../01-compiler/` via `language-gaps.md` (113 writes the stubs) | rows, not gate items |
| STD-11's two rows | `../01-compiler/04-js`, `02-erlang` | rows, not gate items |
| a `.targets` or manifest narrowing that gate-d's audit refuses because the cell *builds* on the excluded target but is red there | `../01-compiler/05-wasm` / `03-beam` (a lowering gap) — 111 step 5 names each | the narrowing is deleted; the red is the compiler's, never re-narrowed |
| `botopink test --integration` (gate-h's flag) | `../01-compiler/26-cli-tooling`, only if the maintainer wants it and a CI job provides a service in the same landing | no flag without a job |
