# Front 106 — a bundled `log`: one error digest, one way to the logger

**Priority:** high — `05-jhonstart/26` step 4, `04-rakun/17` and `07-onze/49` step 3 are written
against this package and cannot land before it (decisions 194, 195).
**Depends on:** `00-gate` green · `97-std-dedupe` (`clock.formatIso8601` replaces `rkLogIso`). No
open question: decision 195 (`07-f` (b)) makes the package exist and decision 194 (`31-b`) makes
its `errorDigest` the one digest. The three registration files take one front at a time
(decision 189).
**Owns:** `repository/botopink-lang/libs/log/**` (new) · registration lines (append) · one
consumer commit of its own: `repository/rakun/modules/rakun-web/src/error.bp:56-57,199` (the
`problem_digest` erlang cell, deleted for `errorDigest`) — after `04-rakun/65` has landed, never
in a wave with it, `08-bpp/123` or `104-http`'s consumer sweep, which hold the same member
(decision 188).
**Does not touch:** the consumer edits the owning fronts make against the landed package, each in
its own step: `repository/rakun/modules/rakun/src/logging/**` (`04-rakun/17` — where
`rakun-logging` lives after `04-rakun/128`, decision 187; it imports the pure half and installs
itself as the sink), `repository/jhonstart/modules/jhonstart/src/error_boundary.bp`
(`05-jhonstart/26` step 4), onze's sink line (`07-onze/49` step 3) · `rakun-logging`'s `cells.bp`
(41 erlang cells: OTP handler install, file rotation, per-name overrides, correlation id,
capture), the `rkProp` levels and groups, the actuator endpoints.

---

## Problem

An error has three digests today. jhonstart's `digestOf(message)` is `contentHash(message)` (8
hex, `error_boundary.bp:77`); rakun-logging's `errorDigest` is 16 hex of `strongHash` over four
parts (`digest.bp:63-70`); rakun-web's problem detail computes a third in an erlang cell
(`problem_digest`, `rakun-web/src/error.bp:56-57`, `:199`). An error rendered by jhonstart and
logged by rakun cannot be correlated, and the render has no way to the logger at all (it imports
none — decision 113).

## Mechanism

One scheme, one implementation (decision 194): `errorDigest(module, errorClass, message,
topFrames)` — the first 16 hex of `strongHash` over `module|errorClass|message|topFrames`, the
frames normalised (the first three, line numbers stripped) — lives here and nowhere else, pinned
by one known-answer fixture on every target. The package is target-agnostic and names no
framework: levels, `LogRecord`, the four renderers, and a `Logger` whose sink is injected
(decision 195). The render reaches the logger through one error-logging function: it writes the
record through the injected sink and answers the digest, so the digest a fallback shows is the one
on the log line. With no sink set, the default sink (erlang `logger` / node `console`) receives
the record. No `RenderHooks.onError` exists.

## Steps

### Step 1 — the package

`repository/botopink-lang/libs/log` (`levels`, `formats`, `digest`, `sink`, `logging`; its
`AGENTS.md` holds the surface): `Level`, `LogRecord`, the `Format` enum and
`renderRecord(format, record)` for ECS / GELF / logstash / plain (the two timestamp cells are botopink
over std `clock.toCivil`), `parseFormat(name) -> @Result<Format, string>`,
`errorDigest(module, errorClass, message, topFrames)` (moved from `digest.bp:63-70`),
`LogSink(enabled, write)` with `setSink` / `defaultSink` (OTP `logger` / node `console`, inline
templates), a `Logger(name)` over the sink in force, and `Logger.logError(module, errorClass,
message, topFrames, fields) -> string`, which writes one error record and answers its digest.
`import {errorDigest, Logger} from "log";` resolves as written.

**Acceptance:**
- [x] the four renderers byte-identical to rakun-logging's for one fixed record, both rows —
  rakun's four pinned `format_test.bp` lines, plus a record taking every optional branch
- [x] `errorDigest` known-answer, both rows — `90e4cc2a07abe1fb` (rakun's fixture) and
  `be5be69f55e91af2` (four empty parts), each the SHA-256 of the documented input
- [x] the error-logging function writes one record through the injected sink and answers the
  digest, also when the sink takes no errors
- [x] every target the package runs on: erlang and commonJS tested; beam runs it from a consumer
  (same digest); wasm is refused at the first std cell the package reaches without a wasm binding
  (`` `quote` has no `#[@External.<Target>(…)]` for the wasm backend ``)
- [x] registered as its own commit: `build.zig` `bundled_packages`, `libs/AGENTS.md`,
  `scripts/format-check.sh` `TREES`

### Step 2 — consumers

The first two boxes are landed by the fronts that own the members and ticked here when they are;
the `problem_digest` cell is this front's own commit, after `04-rakun/65`.

- [ ] rakun-logging imports the package for the pure half; its cells untouched; tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest`; `05-jhonstart` 31's box closes
- [ ] rakun-web's `problem_digest` cell (`error.bp:56-57`, `:199`, `rakun_chain.erl:461-462,480-481`)
  deleted for `errorDigest`

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green — measured on the branch:
  `zig build test` cold and `test-libs -- --lib log` green; the full `test-libs` is the landing gate's
- [x] `libs/log/AGENTS.md` written; touched `AGENTS.md` files updated
- [x] Commit on `front/106-log`

## Notes

- Every exported name is checked against std's and the frameworks' roots (decision 163): none is
  std's; the sink type is `LogSink` (rakun-stream has a `Sink`) and the dispatch `renderRecord`
  (rakun-actuator has a `render`); `Level`, `LogRecord`, `Logger`, `errorDigest`, `clientErrorBody`
  are rakun-logging's own copies, which step 2 deletes for these.
