# Front 106 — log: a shared `log`, one error digest, one way to the logger

**Priority:** high — `05-jhonstart/26` step 4, `04-rakun/17`, `07-onze/49` step 3 written against it
(decisions 194, 195) · **State:** partial: step 1 (the package) on feat; step 2 open; step 3 built on
erlang, beam and commonJS (`front/106-s3`), its wasm column waiting on 106-a and two gap rows
**Depends on:** step 2 — `04-rakun/17` and `05-jhonstart/26` step 4 (their boxes), `04-rakun/65`
landed (own commit)
**Owns:** `repository/log/**` · one consumer commit:
`repository/rakun/modules/rakun-web/src/error.bp` (`problem_digest` erlang cell) and
`rakun-web/src/sidecars/rakun_chain.erl`'s `problem_digest/1` — after `04-rakun/65`, never in a wave
with it, `08-bpp/123` or `104-http` step 5 (same member, decision 188)
**Does not touch:** owners' consumer edits, each in its own step:
`repository/rakun/modules/rakun/src/logging/**` (`04-rakun/17` — `rakun-logging`'s home after
`04-rakun/128`, decision 187; imports `log`, installs one of its sinks — 349),
`repository/jhonstart/modules/jhonstart/src/error_boundary.bp` (`05-jhonstart/26` step 4), onze's sink
line (`07-onze/49` step 3) · `rakun-logging`'s `cells.bp` (its sink and capture cells are ported here by step 3
and deleted by `04-rakun/17`; the correlation-id cell stays rakun's), the `rkProp` levels and groups (a typed
`#[config]` record with 299 — rakun's), actuator endpoints

## Goal

One digest everywhere: `log.errorDigest(module, errorClass, message, topFrames)` — first 16 hex of
`strongHash` over `module|errorClass|message|topFrames`, frames normalised (first three, line numbers
stripped), one known-answer fixture on every target (decision 194). Three remain beside it:
jhonstart `digestOf(message)` (`contentHash`, 8 hex, `error_boundary.bp`), rakun-logging
`errorDigest` (`digest.bp`), rakun-web's `problem_digest` erlang cell. The render reaches the logger
through `Logger.logError` (writes the record via the injected sink, answers the digest — the
fallback shows the log line's digest); no `RenderHooks.onError` (decision 195).

## Done

- Step 1 — the package (`levels`, `formats`, `digest`, `sink`, `logging`): `Level`, `LogRecord`,
  `Format` / `parseFormat` / `renderRecord` (ECS, GELF, logstash, plain), `errorDigest`,
  `clientErrorBody`, `LogSink` / `setSink` / `defaultSink`, `Logger.logError`; registered in the
  three files; refused on wasm at the first std cell without a wasm binding

## Open

### Step 2 — consumers

Boxes 1–2 landed by the members' owners, ticked here; box 3 this front's own commit, after `04-rakun/65`.

- [ ] rakun-logging imports `log` (`Level`, `LogRecord`, `Logger`, `errorDigest`, `clientErrorBody` —
      own copies deleted); after step 3 its sink and capture cells deleted for `log`'s (349); tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest` (`05-jhonstart/26` step 4)
- [ ] rakun-web's `problem_digest` cell (`error.bp`, `rakun_chain.erl` `problem_digest/1`) deleted
      for `errorDigest`

### Step 3 — the sinks and the runtime-report capture (decision 349)

- [ ] sinks in `log`: console, a file with rotation, per-name levels — one API on every target; an
      `@External` cell they use is bound on erlang/beam, commonJS and wasm, never on some only (on the
      BEAM a sink may hand records to OTP's `logger`); ported from `rakun-logging`'s `cells.bp`
      — built: `consoleSink` (`@print`, no cell), `fileSink` / `LogFile` (`logger_std_h`'s rotation in
      botopink over four cells), `fanOut`, `Threshold` / `Levels` (longest dotted prefix) — choices
      106-b…106-d; `hostWrite` bound on wasm (`fn:printLine`). Left: the wasm binding of the sink slot
      (**A wasm binding cannot keep a value across calls**, 140) and of the four file cells (**A wasm
      binding cannot reach the file system**, 106-a)
- [x] `log.captureRuntimeReports()`: BEAM the OTP `logger`'s crash, supervisor and SASL reports; node
      `uncaughtException` / `unhandledRejection`; wasm a no-op binding — a cell per target (106-e;
      the wasm cell measured in isolation)
- [ ] `log` imports on every target (146): the four-target build of its test member green — erlang,
      commonJS and beam green (35 tests each); wasm refused first at std (`std/json`, `02/97` step 15;
      `std/io/clock`'s `systemTimeWithUnit` / `toCivil`), then at the two gap rows above

**Gate:** standard (fronts.md § Gate), for step 2's own commit and step 3
