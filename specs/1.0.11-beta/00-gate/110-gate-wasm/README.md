# Front 110 — gate-wasm: the link loop drops colliding types, and 18 sites degrade silently

**Priority:** critical — stage 9's one red cell, and the only class of defect in the compiler that
prints a wrong value at exit 0.
**Depends on:** none to start; `112` reformats `libs/std/src/testing/asserts.bp` — this front
rebases its restructure over that commit. `111` starts from this front's landing.
**Owns:** `modules/compiler-core/src/codegen/wat.zig` (the link loop `:633-700`, the 18 sites
below, `collectHostBound` `:1445`) · `modules/compiler-core/snapshots/codegen/wasm/**` ·
`libs/std/src/testing/asserts.bp` (the ck-host restructure, gate-b) · the single `wasm |` line of
`tests/language/expected-failures.txt` (`:243` — the file is 111's; this front's only edit to it is
deleting that line, and 111 starts from the result) · new `tests/language/run/*.bp` and
`modules/*` cells for wasm only.
**Does not touch:** `wat_prelude.zig`, `wat_runtime.zig`, `codegen/wat/**` beyond what a hard error
needs (`../../01-compiler/05-wasm` owns wasm's lowering rows — `Array.unique`, the primitive-method
traps, C-07 twins); `tests/language/run.sh` (111's); `beam_asm.zig`, `erlang.zig`, `commonJS.zig`.

---

## Problem

```
$ bash tests/language/run.sh --target wasm modules/import_same_name_from_two_packages
FAIL     [wasm] modules/import_same_name_from_two_packages — exit 0; stdout: 200\n0\n
                                                             expected: 200\n<p>\n
language tests: … 1 failed
```

The cell links two packages that both declare `type Response` (`web`: `Response(status: i32)`;
`ui/stream`: `Response(html: string)`); on wasm the program prints `0` for `ok().html` and exits 0.
Measured at the open (`par/6.out`): `1244 passed, 1 expected failures, 1 failed` on `--target all`.

## Current state

- **The link loop** (`wat.zig:642-700`): wasm links statically into one namespace. When a linked
  module declares a name this module also declares, a `fn` is mangled `<module>/<name>`
  (`:662-670`, calls rewritten by `renameLinkedCalls`) and a `val` likewise (`:671-679`); **every
  other declaration hits `else => {}` (`:680`) and is dropped**. `ui/stream`'s `type Response` is
  never registered; `web`'s is the only `Response` the record registry knows. The linked
  `$ui/stream/ok` builds a record with `web`'s descriptor (offset 260) and stores `i32.const 0` for
  `html`; `ui`'s data segment (`<p>` at 280) is never merged. In `main`, `ok().html` →
  `lowerFieldAccess` → `fieldOffsetIn(web Response, "html")` fails, `uniqueFieldOffset` fails, and
  `:9299` emits `zero` with a note.
- **18 silent-degradation sites** — a lowering that cannot proceed emits `i32.const 0` (`emitCf(zero,
  …)`) or a `;; note` and continues, so the program runs and prints a wrong value. Measured at the
  open (`sed -n <line>p wat.zig`):

| Line | Site |
|---|---|
| 2679 | `note("unsupported param destructure pattern")` |
| 4156 | `note("field assign (unknown receiver type)")` |
| 4217 | `note("unsupported destructure pattern")` |
| 4228 | `note("unsupported destructure pattern")` |
| 4423 | `emitCf(zero, "unbound identifier {s}")` |
| 4432 | `emitCf(zero, ".{s}")` (a bare `.Variant` with no context) |
| 4513 | `emitCf(zero, "unresolved pipeline target {s}")` |
| 4566 | `note("continue outside a loop")` |
| 4957 | `note("builtin stub")` |
| 5186 | `note("map/flatMap needs a literal closure on WASM — receiver passed through")` |
| 5277 | same |
| 5669 | `emitCf(zero, "unknown variant pattern: {s}")` |
| 5827 | `emitCf(zero, "no descriptor for variant {s}")` |
| 6240 | `note("note: array spread not lowered")` |
| 6310 | `emitCf(zero, "unresolved dispatch: {s}")` |
| 6329 | `emitCf(zero, "unresolved dispatch: {s}")` |
| 9296 | `emitCf(zero, "optional field access .{s} (unknown receiver type)")` |
| 9299 | `emitCf(zero, "field access .{s} (unknown receiver type)")` |

- **ck-host** (gate-b): `wasm | run/external_wrapper_keeps_refusal.bp` (`expected-failures.txt:243`)
  — the strict rule (`docs.md` § host bindings: a wrapper around a host call with no wasm binding
  is refused even if nothing calls it) meets `collectHostBound` (`wat.zig:1445`), which drops such
  a function and refuses only a call to it — written so that `testing.asserts` builds on wasm:
  `deepEquals` (`asserts.bp:105`) reaches `canonical` (`:99-101`), which has Node and Erlang
  templates only. wasm accepts the cell and prints `up`; commonJS refuses it. Open question
  `specs/1.0.10-beta/decisions-pending.md` § ck-host, recommendation (a): strict everywhere.

## Mechanism

Two habits, one consequence: a name collision the link loop does not resolve, and a lowering that
cannot resolve a name emitting `0` instead of an error. Together, a wrong program is indistinguishable
from a right one at the exit code — which is the failure mode the gate exists to catch, and the
one a snapshot cannot (the wasm snapshot of a stub is the stub).

## Steps

### Step 1 — the link loop mangles every colliding declaration, or the registries are keyed by module

Options: (a) extend the `:661-681` switch: a colliding `type`, `enum` (and any other named
declaration) is mangled `<module>/<name>` like a `fn`, and every reference — constructor calls,
patterns, `is`, field access resolution, the record registry — is renamed the way
`renameLinkedCalls` renames calls; (b) key the record/enum registries by `(module, name)` and
resolve a reference from the module it is written in. **Recommend (b)**: it is the model the other
three backends already have (a module is a namespace), it needs no renaming pass over patterns,
and it removes the `else => {}` arm instead of widening it. The data segment of every linked
module is merged (the `<p>` at 280 today is not).

**Acceptance:**
- [ ] `bash tests/language/run.sh --target wasm modules/import_same_name_from_two_packages` → `passed`, stdout `200\n<p>\n`
- [ ] a second cell: two linked packages declaring the same `enum` name with different variants, matched by `case` in each — passes on all four targets (commonJS, erlang, beam already resolve per module; the wasm twin is the regression test)
- [ ] `:680`'s `else => {}` is gone (`grep -n "else => {}" wat.zig` in the link loop range: 0)

### Step 2 — the 18 sites become hard errors

Each `emitCf(zero, …)` / `note(…)` in the table becomes a located compile error
(`self.fail(loc, "…")` or the emitter's diagnostic path — the one `wat.zig` uses for
`external_missing`), so `botopink build --target wasm` exits non-zero with the message and the
`.wat` is not written. Budget for more reds: every fixture that reached one of these stubs prints
today's `0` in its snapshot `RUN LOG`; each becomes a refusal or a real lowering. Measure first —
step 2a: grep the wasm snapshots for the 18 messages
(`grep -rl "field access\|unresolved dispatch\|unbound identifier\|unknown variant\|no descriptor\|builtin stub\|not lowered\|destructure pattern\|pipeline target\|continue outside\|receiver passed through" modules/compiler-core/snapshots/codegen/wasm/`)
and list them here with the site each hits; step 2b: for each, either the lowering exists on the
other backends and the wasm half is written here, or it is an `01-compiler/05-wasm` row and the
fixture is re-recorded as the refusal (a snapshot of a diagnostic is evidence; a snapshot of `0`
is not).

**Acceptance:**
- [ ] `grep -c "emitCf(zero" wat.zig` = 0; `grep -c 'self.note("' wat.zig` = 0 for the 18 messages (a `;; note` that documents a *correct* lowering may stay — list each survivor with its reason)
- [ ] every re-recorded wasm snapshot's `RUN LOG` is either the value the other backends print or a located refusal — no `0` where commonJS prints something else (`scripts/snap_audit.sh --mode=runtime-parity` green, `zig build test` green)
- [ ] `tests/language/run.sh --target wasm` → `0 failed`

### Step 3 — ck-host (a): `collectHostBound` strict, `asserts` restructured

`collectHostBound` (`:1445`) stops dropping a function whose body reaches a host call with no wasm
binding: the function is refused where it is declared (the strict rule, `docs.md` § host
bindings). `libs/std/src/testing/asserts.bp`: `deepEquals` no longer reaches `canonical` on wasm —
either `canonical` gets a wasm lowering (a structural stringify over the value's descriptor, which
`wat_runtime`'s print path already has for `@print`), or `deepEquals` is restructured to compare
structurally without a string. Recommend the wasm lowering of `canonical` (one template, and
`deepEquals`'s message keeps its shape on every target). Then delete `expected-failures.txt:243`.

**Acceptance:**
- [ ] `bash tests/language/run.sh --target wasm run/external_wrapper_keeps_refusal.bp` → `passed` (the cell's `.expect` is the refusal)
- [ ] `zig build test-libs -- --lib std --target wasm` — not runnable (`botopink test` refuses wasm); the check is `botopink build --target wasm` in `libs/std` → exit 0, and `deepEquals` exercised by a `run/` cell on wasm that prints a structured mismatch message
- [ ] `expected-failures.txt` has no `wasm |` line; `run.sh --target all` prints `0 expected` for wasm

## Gate

- [ ] `zig build test` from a cold runtime cache, green, in this front's worktree
- [ ] `scripts/snap_audit.sh --mode=runtime-parity` green; every re-recorded wasm snapshot listed in the commit message with the value it was verified against (running under `wasmtime`)
- [ ] `bash tests/language/run.sh --target all` → `0 failed` on wasm (the two beam lines remain until 111)
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` (the wat section: no silent degradation; the link model), `libs/std/AGENTS.md` (`canonical` on wasm) updated in the same commit
- [ ] commit on `fix/gate-wasm` in `repository/botopink-lang`; no push, no merge

## Blast radius

- wasm snapshots: the count re-recorded is step 2a's measurement (unknown at the open; the 18
  messages appear in the snapshot text where a stub fired). Every one is re-recorded against a
  value verified by running, or against a refusal.
- `../../01-compiler/05-wasm` starts from this landing: its rows (`Array.unique` trap, the pinned
  primitive-method traps, `==` by word) are lowerings, and after step 2 a missing lowering is a
  refusal rather than a `0` — 05's fixtures may move from "prints wrong" to "refused"; that is the
  intended direction.
- `../../02-std-and-packaging/97-std-dedupe` rebases over `asserts.bp`.
- `111` deletes what is left of `expected-failures.txt` after this front removes its line.

## Notes

- A `;; note` in the emitted `.wat` is a comment; the acceptance is about what the emitter *does*
  after writing it — continue with `0` — not about the comment.
- The compiler knows no library: `asserts.bp` is std, and the restructure is a std change this
  front owns only because the ck-host line cannot close without it.
