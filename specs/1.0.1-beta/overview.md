# Specs — 1.0.1-beta

Delivered. What this milestone made true, and where each part lives. Everything it left open moved
to [`1.0.2-beta`](../1.0.2-beta/overview.md).

The milestone's subject turned out to be the suite itself: it was green on output nobody checked.
A run was decided by whether a tool printed anything, so the BEAM backend never executed and its
RUN LOGs came from a local cache; an `erlc` warning silently blanked an erlang RUN LOG; a program
that failed to compile recorded an empty snapshot and passed; only the first backend of a test was
compared. Fixing that turned ~70 vacuous tests into real ones, and the defects they then exposed
were fixed backend by backend.

| # | Spec | Delivered |
|---|------|-----------|
| 01 | [`01-suite-clean.md`](./01-suite-clean.md) | A run is decided by the process exit status (`codegen/runtime.zig` `runCaptured`/`RunStatus`); a compile failure is recorded, not dropped; the four leaked `erlc`-output slices are freed; a harness version is folded into the cache key, so a warm cache cannot hide a harness defect. |
| 02 | [`02-type-system.md`](./02-type-system.md) | Comptime folding by operand kind (`comptime/eval.zig`) and a real scope for `comptime { … }` — one row of thirteen; the checker rows are 1.0.2-beta. |
| 03 | [`03-codegen-hardening.md`](./03-codegen-hardening.md) | erlang: module-level `val`s, variant patterns, `case` guards, `Ok`/`Err`, string concat, loops lowered by shape. beam: register discipline, `case` match tests, `@print`, `.len`, `call_ext`. wasm: every emitted module loads. |
| 04 | [`04-emitter-centralization.md`](./04-emitter-centralization.md) | Every backend builds a model and an emitter renders it: `beam/beam_emitter.zig` grew a typed instruction vocabulary, `codegen/wat/` and `codegen/js/` were created, and `wat.zig`, `commonJS.zig`, `typescript.zig` and `beam_asm.zig` write no target syntax. All three migrations were snapshot-byte-identical. |
| 05 | [`05-repo-hygiene.md`](./05-repo-hygiene.md) | The retired `@[` opener is rejected with its own diagnostic, the dead language-server test files are gone, the fixtures with retired syntax were migrated, and the ignore rules are in place — 4 of 17 items. |
| 06 | [`06-snapshot-review.md`](./06-snapshot-review.md) | Every snapshot reviewed against its test and re-checked at HEAD (evidence in [`06-snapshot-review/`](./06-snapshot-review/)); harness defects H1–H10 closed; 116 zero-byte and 39 source-only snapshots gone. |

Also delivered, outside the numbered specs: parse errors are located correctly (a token carries its
byte offset), a token's location is where it starts, `${…}` hole positions map back to the source,
the formatter stopped silently deleting enum sections, and the language server stopped leaking
source text into completion and hover details.

## How it is verified

`zig build test` from a **cold** runtime cache (`modules/compiler-core/.botopinkbuild/runtime-cache`
deleted): exit 0, 0 failures, 0 leaks, 0 `.snap.md.new`. 11 tests are documented skips, each naming
the missing feature and the spec that owns it.

That gate has a known blind spot, which is why 1.0.2-beta opens with it: it never compiles a `.bp`
library, and it never asserts on program output for the non-commonJS backends.

## Rules this milestone established

- **A backend builds a model, an emitter renders it.** Hand-written target text is where the bugs
  were: a raw node put `{tag, Circle, R}` into a pattern, a `raw("")` placeholder rendered invalid
  Erlang, and template escapes leaked into the module.
- **The gate is a cold runtime cache** — a stale entry can hide a backend that never ran.
- **A snapshot is evidence, not a baseline** — re-record only a value verified by running the
  program; a fixture that pins known-wrong output says so in the test.
