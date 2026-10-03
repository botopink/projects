# Front 106 — log: a bundled `log`, one error digest, one way to the logger

**Priority:** high — `05-jhonstart/26` step 4, `04-rakun/17` and `07-onze/49` step 3 are written
against this package (decisions 194, 195) · **State:** partial: step 1 (the package) on feat; step 2
open
**Depends on:** step 2 — `04-rakun/17` and `05-jhonstart/26` step 4 (their boxes), `04-rakun/65`
landed (this front's own commit)
**Owns:** `repository/botopink-lang/libs/log/**` · one consumer commit of its own:
`repository/rakun/modules/rakun-web/src/error.bp` (the `problem_digest` erlang cell) and
`rakun-web/src/sidecars/rakun_chain.erl`'s `problem_digest/1` — after `04-rakun/65` has landed,
never in a wave with it, `08-bpp/123` or `104-http`'s step 5, which hold the same member
(decision 188)
**Does not touch:** the consumer edits the owning fronts make against the package, each in its own
step: `repository/rakun/modules/rakun/src/logging/**` (`04-rakun/17` — where `rakun-logging` lives
after `04-rakun/128`, decision 187; it imports the pure half and installs itself as the sink),
`repository/jhonstart/modules/jhonstart/src/error_boundary.bp` (`05-jhonstart/26` step 4), onze's
sink line (`07-onze/49` step 3) · `rakun-logging`'s `cells.bp` (41 erlang cells: OTP handler
install, file rotation, per-name overrides, correlation id, capture), the `rkProp` levels and
groups, the actuator endpoints

## Goal

An error has one digest everywhere: `log.errorDigest(module, errorClass, message, topFrames)` — the
first 16 hex of `strongHash` over `module|errorClass|message|topFrames`, frames normalised (first
three, line numbers stripped), pinned by one known-answer fixture on every target (decision 194).
Today three remain beside it: jhonstart's `digestOf(message)` (`contentHash`, 8 hex,
`error_boundary.bp`), rakun-logging's `errorDigest` (`digest.bp`), and rakun-web's `problem_digest`
erlang cell. The render reaches the logger through `Logger.logError`, which writes the record
through the injected sink and answers the digest, so the digest a fallback shows is the one on the
log line; no `RenderHooks.onError` exists (decision 195).

## Done

- Step 1 — the package (`levels`, `formats`, `digest`, `sink`, `logging`): `Level`, `LogRecord`,
  `Format` / `parseFormat` / `renderRecord` (ECS, GELF, logstash, plain), `errorDigest`,
  `clientErrorBody`, `LogSink` / `setSink` / `defaultSink`, `Logger.logError`; registered in the
  three files; refused on wasm at the first std cell without a wasm binding

## Open

### Step 2 — consumers

The first two boxes are landed by the fronts that own the members and ticked here when they are;
the third is this front's own commit, after `04-rakun/65`.

- [ ] rakun-logging imports the package for the pure half (`Level`, `LogRecord`, `Logger`,
      `errorDigest`, `clientErrorBody` — its own copies deleted); its cells untouched; tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest` (`05-jhonstart/26` step 4)
- [ ] rakun-web's `problem_digest` cell (`error.bp`, `rakun_chain.erl` `problem_digest/1`) deleted
      for `errorDigest`

**Gate:** standard (fronts.md § Gate), for step 2's own commit
