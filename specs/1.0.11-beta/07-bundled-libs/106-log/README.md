# Front 106 — a bundled `log` (conditional on `07-f`)

**Priority:** low — opens only if the maintainer chooses the package over 31-b option (a).
**Depends on:** `07-f` answered "package" · `00-gate` green · `97-std-dedupe`
(`clock.formatIso8601` replaces `rkLogIso`).
**Owns:** `repository/botopink-lang/libs/log/**` (new) · registration lines (append) · consumers:
`repository/rakun/modules/rakun-logging/src/{formats,levels,digest}.bp` (the pure halves),
`repository/jhonstart/modules/jhonstart/src/error_boundary.bp:77`.
**Does not touch:** `rakun-logging/src/cells.bp` (41 erlang cells: OTP handler install, file
rotation, per-name overrides, correlation id, capture), the `rkProp` levels and groups, the actuator
endpoints (`03-rakun` 17 owns them).

---

## Problem

jhonstart's error digest is `contentHash(message)`; rakun-logging's is `strongHash` over four
parts. An error rendered by jhonstart and logged by rakun has two digests, and a user cannot
correlate the page with the log line. 31-b names the two fixes; this front is the package-shaped
one.

## Steps

### Step 1 — the package

`Level`, `LogRecord`, `render(format, record)` for ECS / GELF / logstash / plain (pure; the two
timestamp cells replaced by std `clock`), `errorDigest(module, class, message, frames)` (moved from
`digest.bp:63-70`), a `Logger` whose sink is injected (`setSink`; default sink erlang `logger` /
node `console`, as inline templates).

**Acceptance:**
- [ ] the four renderers byte-identical to rakun-logging's for one fixed record, both rows
- [ ] `errorDigest` known-answer, both rows

### Step 2 — consumers

- [ ] rakun-logging imports the package for the pure half; its cells untouched; tests green
- [ ] jhonstart `error_boundary.bp` digests through `log.errorDigest`; `04-jhonstart` 31's box closes

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green
- [ ] `libs/log/AGENTS.md` written; touched `AGENTS.md` files updated
- [ ] Commit on `front/106-log`

## Notes

If `07-f` answers (a), this directory is deleted and the digest box closes in `04-jhonstart` 31
through the `onError` hook; nothing here lands.
