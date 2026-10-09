# Front 106 — log: a shared `log`, one error digest, one way to the logger

**Priority:** high — `05-jhonstart/26` step 4, `04-rakun/17`, `07-onze/49` step 3 written against it
(decisions 194, 195) · **State:** partial: step 1 (the package) on feat; step 2 open
**Depends on:** step 2 — `04-rakun/17` and `05-jhonstart/26` step 4 (their boxes), `04-rakun/65`
landed (own commit)
**Owns:** `repository/log/**` · one consumer commit:
`repository/rakun/modules/rakun-web/src/error.bp` (`problem_digest` erlang cell) and
`rakun-web/src/sidecars/rakun_chain.erl`'s `problem_digest/1` — after `04-rakun/65`, never in a wave
with it, `08-bpp/123` or `104-http` step 5 (same member, decision 188)
**Does not touch:** owners' consumer edits, each in its own step:
`repository/rakun/modules/rakun/src/logging/**` (`04-rakun/17` — `rakun-logging`'s home after
`04-rakun/128`, decision 187; imports the pure half, installs itself as the sink),
`repository/jhonstart/modules/jhonstart/src/error_boundary.bp` (`05-jhonstart/26` step 4), onze's sink
line (`07-onze/49` step 3) · `rakun-logging`'s `cells.bp` (41 erlang cells: OTP handler install, file
rotation, per-name overrides, correlation id, capture), the `rkProp` levels and groups (a typed
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

- [ ] rakun-logging imports the package's pure half (`Level`, `LogRecord`, `Logger`, `errorDigest`,
      `clientErrorBody` — own copies deleted); cells untouched; tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest` (`05-jhonstart/26` step 4)
- [ ] rakun-web's `problem_digest` cell (`error.bp`, `rakun_chain.erl` `problem_digest/1`) deleted
      for `errorDigest`

**Gate:** standard (fronts.md § Gate), for step 2's own commit
