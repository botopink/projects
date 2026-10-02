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

`Level`, `LogRecord`, `render(format, record)` for ECS / GELF / logstash / plain (pure; the two
timestamp cells replaced by std `clock`), `errorDigest(module, class, message, frames)` (moved from
`digest.bp:63-70`), a `Logger` whose sink is injected (`setSink`; default sink erlang `logger` /
node `console`, as inline templates), and the error-logging function that writes one record
through the sink and answers its digest.

**Acceptance:**
- [ ] the four renderers byte-identical to rakun-logging's for one fixed record, both rows
- [ ] `errorDigest` known-answer, both rows

### Step 2 — consumers

The first two boxes are landed by the fronts that own the members and ticked here when they are;
the `problem_digest` cell is this front's own commit.

- [ ] rakun-logging imports the package for the pure half; its cells untouched; tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest`; `05-jhonstart` 31's box closes

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green
- [ ] `libs/log/AGENTS.md` written; touched `AGENTS.md` files updated
- [ ] Commit on `front/106-log`

## Notes

- `import {errorDigest, Logger} from "log";` is the import decision 195 writes; every exported
  name is checked against std's and the frameworks' roots (decision 163).
- The acceptance of steps 1 and 2 predates decisions 194 and 195: it has no box for the
  error-logging function, for the fixture on every target (wasm included), or for the
  `problem_digest` cell. The front writes them when it opens.
