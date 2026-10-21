# Front 156 — log: the consumers and the wasm column

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `log` — worktree `--repo log` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/log/**`; rakun-web's `problem_digest` commit
**Depends on:** 150 s16 (65) · s2: 144 B-25 / B-00e (G4)
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `106-log` s2 | 156 s1 |
| `106-log` s3 | 156 s2 |

## Steps

### 156 s1 — consumers (106 s2)

**Repository:** `log`, and the consumer commits it names in their repositories (a full worktree, decision 188) · **Model:** sonnet

#### Step 2 — consumers (was `106-log` s2)

Boxes 1–2 landed by the members' owners, ticked here; box 3 this front's own commit, after `04-rakun/65`.

- [ ] rakun-logging imports `log` (`Level`, `LogRecord`, `Logger`, `errorDigest`, `clientErrorBody` —
      own copies deleted); after step 3 its sink and capture cells deleted for `log`'s (349); tests green
- [ ] rakun-bpp's `error_boundary.bp` digests through `log.errorDigest` (`05-jhonstart/26` step 4)
- [ ] rakun-service's `problem_digest` cell (`error.bp`, `rakun_chain.erl` `problem_digest/1`) deleted
      for `errorDigest`
- [x] `fileSink` / `appendRotating` answer `Error` of `log`'s enum on a failed host call (the four file cells `result: true`), `logfile.bp`'s "raises" and `sink.bp`'s `@print` comment respelled; cell `log_file_sink_answers_error` (decision 921) — landed (`LogError { AppendFailed, SizeFailed, MoveFailed, RemoveFailed }`;
      cells `rotation_keeps_two_archives`, `unwritable_path_answers_error`; `logFileBytes` and `rotate` answer `Result<_, LogError>`)
- [ ] `logFileBytes` on an unwritable path answers `Error` on erlang and `Ok(-1)` on commonJS: commonJS answers `Error` as erlang does;
      the `unwritable_path_answers_error` cell reads it once both agree

### 156 s2 — the sinks' wasm column (106 s3)

**Repository:** `log` (`--repo log`) · **Model:** sonnet

#### Step 3 — the sinks and the runtime-report capture (decision 349) (was `106-log` s3)

- [ ] sinks in `log`: console, a file with rotation, per-name levels — one API on every target; an
      `compiler.external` cell they use is bound on erlang/beam, commonJS and wasm, never on some only (on the
      BEAM a sink may hand records to OTP's `logger`); ported from `rakun-logging`'s `cells.bp`
      — built: `consoleSink` (`terminal.print`, no cell), `fileSink` / `LogFile` (`logger_std_h`'s rotation in
      botopink over four cells), `fanOut`, `Threshold` / `Levels` (longest dotted prefix) — choices
      106-b…106-d; `hostWrite` bound on wasm (`fn:printLine`). Left: the wasm binding of the sink slot
      (**A wasm binding cannot keep a value across calls**, 140) and of the four file cells (**A wasm
      binding cannot reach the file system** — 405: each a wasm `fn:` binding reaching no file, `fileSink` an `Error` naming `consoleSink` on both hosts)
- [x] `log.captureRuntimeReports()`: BEAM the OTP `logger`'s crash, supervisor and SASL reports; node
      `uncaughtException` / `unhandledRejection`; wasm a no-op binding — a cell per target (106-e;
      the wasm cell measured in isolation)
- [ ] `log` imports on every target (146): the four-target build of its test member green — erlang,
      commonJS and beam green (35 tests each); wasm refused first at std (`std/json`, `02/97` step 15;
      `std/io/clock`'s `systemTimeWithUnit` / `toCivil`), then at the two gap rows above

**Gate:** standard (fronts.md § Gate), for step 2's own commit and step 3

### 156 Conformance — the front's last step (decision 465)

**Repository:** log (`--repo log`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `log/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

