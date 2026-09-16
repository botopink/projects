# Specs — 1.0.2-beta

What [`1.0.1-beta`](../1.0.1-beta/overview.md) left open, plus what a health check of the whole
workspace found. 1.0.1-beta made the suite tell the truth (a run is decided by the process exit
status, a program that does not compile fails its test, every backend is compared) and gave every
backend a code model with a single emitter. This milestone spends that: the defects the suite now
shows get fixed, and the gate is widened to the libraries it never compiled.

The work is cut into **twelve fronts** — one directory each, one worktree and branch each. The cut
is by ownership of files and snapshot directories, so the fronts that do not share either run at
the same time. [`fronts.md`](./fronts.md) holds the ownership table and the conflict matrix.

## Fronts

| Front | Priority | What |
|---|---|---|
| [`01-comptime-dispatch`](./01-comptime-dispatch/README.md) | critical | A template or decorator body calling a primitive method lowers to a bare local call nothing defines — four of six libraries cannot compile. The typed tables are already built; one `PrimKind` per call site is missing. Also the closure-mutation fold and the evidence for trailing defaults. |
| [`02-cli-gate`](./02-cli-gate/README.md) | critical | CLI commands that report success on failure (`build` exits 0 after dropping a module, `test` exits 0 on a project that does not compile, `format --check` passes unparseable source, `build` executes the program), and a gate that never compiles a `.bp` library. |
| [`03-std-surface`](./03-std-surface/README.md) | critical | `libs/std` does not compile on one blocker; the Gleam runtime file 22 primitives point at (removed, not shipped — own helpers are emitted per used function); how `#[@External…]` should be used. |
| [`04-beam`](./04-beam/README.md) | high | 58 of 128 fixtures disagree; one guard turns an unresolvable identifier into an atom of its own name (22). |
| [`05-erlang`](./05-erlang/README.md) | high | Record destructuring, binary segments, imported enum variants, `return` in a narrowed arm, the two-parameter `loop`; the remaining `raw` rows. |
| [`06-wasm`](./06-wasm/README.md) | high | 64 of 128 correct; `emitWat` never receives `instance_lowerings` (27 traps); the exact condition for turning `executeWat` on. |
| [`07-checker`](./07-checker/README.md) | high | C1–C13: `return` never unified, `case` untyped, pattern bindings unconstrained, permissive methods and fields — with the blast radius per row and the groups they must land in. |
| [`08-js-bridges`](./08-js-bridges/README.md) | medium | The six bridges that pin illegal JS/`.d.ts` shapes, and the commonJS lowering causes. |
| [`09-review-tooling`](./09-review-tooling/README.md) | medium | Orphan tracing, the review worksheet, the 777-row residual backlog, and four cross-backend semantics decisions nobody owned. |
| [`10-comptime-dedup`](./10-comptime-dedup/README.md) | low | Four byte-identical copies per comptime slug, and a renderer that prints `?` and `"id": 0`. |
| [`11-hygiene`](./11-hygiene/README.md) | low | The comptime frame protocol, the removed WAT runtime's leftovers, build files that lie, retired vocabulary, license and hooks. |
| [`12-library-repos`](./12-library-repos/README.md) | medium | rakun's dependency that exists nowhere, erika's docs for an evaluator that no longer exists, emilia's missing gate, the extension's retired snippets, bpmp's git-dependency bugs. |

## Order

```
F2 cli-gate ───────┐                (widens the gate; land first)
F9 review-tooling ─┤  run alone     (the harness every front triages against)
F1 comptime-dispatch ──┤            (four libraries depend on it)
F3 std-surface ────────┘  run alone (re-records every backend)
        │
        ├──► F4 beam · F5 erlang · F6 wasm · F8 js-bridges     (4 in parallel)
        ├──► F7 checker  run alone ──► F12 library-repos
        └──► F10 comptime-dedup

F11 hygiene — frame protocol any time; each comment sweep after the front that owns the file
```

The first row is not ordered by importance. Today the gate cannot see a broken library and four are
broken, so a backend fix landed before F2 and F1 would be verified with the libraries' eyes closed.

## Rules carried from 1.0.1-beta

- **A backend builds a model, an emitter renders it.** Hand-written target text is where the bugs
  were; when the model cannot express a construct, extend the model.
- **The gate is a cold runtime cache** — a stale entry can hide a backend that never ran.
- **A snapshot is evidence, not a baseline** — re-record only a value verified by running the
  program; a fixture that pins known-wrong output says so in the test.
- **A front never edits a file it does not own** — it stops and reports.
