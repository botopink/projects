# Specs — 1.0.5-beta (closed)

**Closed 2026-09-20** at `botopink-lang` `feat` `d55a3b87`. [`closure.md`](./closure.md) is the closing
record — per front what landed and with which commit, what did not, the state of the six `.tasks/*`
worktrees, which of the sixty-seven decisions are implemented, partial or open, and the rules that
still bind. Everything open or in progress moved, ranked, to
[`specs/1.0.10-beta/00-compiler-carry-over/`](../1.0.10-beta/00-compiler-carry-over/README.md), with
the deep dives that still apply copied beside it. [`decisions-taken.md`](./decisions-taken.md) stays
here as the record the carry-over implements against. The rest of this file is the milestone as it was
planned, kept as written.

What 1.0.4-beta did not deliver, re-cut so that it can be worked in parallel.
[1.0.4-beta](../1.0.4-beta/overview.md) shipped the surface cutover, the library migration, the
tooling, the language suite and most of the checker; it is now a closed record. Everything it left —
row by row, each verified against `botopink-lang` `c2dd780` before it was carried — is here.

**The cut is different, and that is the point.** 1.0.4-beta had one front owning `comptime/**` and one
owning all of `codegen/**`, so the milestone's critical path was two fronts wide and everything else
waited on them. Here the backends are **four file-disjoint fronts** (`02-erlang`, `03-beam`, `04-js`,
`05-wasm`) that run at the same time, the checker is one front over `comptime/**`, and the seven
support fronts touch none of those files at all.

**Read [`decisions-taken.md`](./decisions-taken.md) first** — twenty-seven decisions taken on
2026-09-18, each with the evidence that produced it, the options that were on the table and the answer.
They are what the fronts implement against, and several reshape a front rather than settle a detail:
the JS value becomes a class per declaration and a subclass per variant (5); a record's identity on
erlang is a tagged tuple (21); there is one range spelling, `..` (20), which reverses part of what the
grammar half just landed; `case` arms union, so **inference may produce a union type** (26); rakun
supports every target with `libs/std` growing underneath it (17); and `14-comptime-on-beam` runs every
step, because the principle governs and not the build time (24).
[`decisions-pending.md`](./decisions-pending.md) holds **six open questions, 38 to 43**, all raised by
the `@BeamMemory` measurement that opened [`17-beam-memory`](./17-beam-memory/README.md) — including
one, 39, where the measurement contradicts the effect a decision was taken for.

## Fronts

| Front | Priority | What |
|---|---|---|
| [`01-checker`](./01-checker/README.md) | critical | The inference half of decision 8 (`unknown`, unions, `is` and narrowing, `case` arms and exhaustiveness — the grammar landed and nothing types it), C13's located-error sweep, C12's pipeline half, types-as-values, trailing defaults, the parser gaps that are inference-side, and decision 8 in `libs/std` and `examples/**` |
| [`02-erlang`](./02-erlang/README.md) | high | Decision 8 at run time on erlang: the §7 formatter, `is`, unions, `case` arms, tuple labels, `loop`; the generator protocol that raises `case_clause`; the block-as-value lowerings decision 2 leaves dead |
| [`03-beam`](./03-beam/README.md) | high | BR5 (the beam backend compiles `@External.Erlang` templates at build time) and the same run-time half on beam |
| [`04-js`](./04-js/README.md) | high | The same on commonJS and typescript: `break <value>` yields a list today, a sibling module's `require` path, a unit variant emitted as a bare string that the emitted `.d.ts` contradicts, and JS-4's codegen half |
| [`05-wasm`](./05-wasm/README.md) | high | The same on wasm, where a record prints as a raw heap address, `Dict.lookup` answers absent, and `modules/std_import` answers `0` with no diagnostic |
| [`06-comptime-dedup`](./06-comptime-dedup/README.md) | high | Four byte-identical copies per comptime slug: `snapshots/comptime/**` goes from **1079 files to 338**. It runs **before** `01-checker`, not after — measured: the checker's partial wave re-recorded 48 comptime files carrying 16 slugs, 3× the files for the same review |
| [`07-review-backlog`](./07-review-backlog/README.md) | medium | The per-report residuals of the 1.0.1-beta snapshot review, wave A now split per backend |
| [`08-hygiene`](./08-hygiene/README.md) | low | The last of the vocabulary and comment sweeps: 19 comments still name `primitives.d.bp`, the `docs.md` diagnostics table has five wrong rows, and the comptime transport error is a one-liner |
| [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) | medium | `format --check` on four of the five libraries, rakun's erlang story, decision 8 in the library sources, and the erlang cells re-run after 13 |
| [`10-cli-residuals`](./10-cli-residuals/README.md) | medium | An unresolved `import` passing `check` **and** `build` in silence — implemented, parked, blocked on one documentation fence — plus the flat `test/` suite that never reaches the resolver |
| [`11-tooling`](./11-tooling/README.md) | medium | The extension's `compiler-check` is red today; the `case` snippet waits on the checker; `SymbolKind.Method` and the Test Explorer must move together across two repositories |
| [`12-language-tests`](./12-language-tests/README.md) | high | Re-point the 54 expected-failure lines at this milestone's fronts, re-classify as each lands, and answer whether the suite runs on beam — the recorded reason not to has been measured false |
| [`13-module-identity`](./13-module-identity/README.md) | critical | One front, three halves, in order: the module atom (`std@math`, `web@api@http`) · one BEAM module per `type` and per `behavior` · the type's atom **inside the value**, so `is`, unions, `case` over named types and per-type printing have something to test. Today `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` answers `true` on erlang |
| [`14-comptime-on-beam`](./14-comptime-on-beam/README.md) | critical | The comptime evaluator stops paying `compile:file` for a program that never changes: **942 ms of a 1 592 ms build** on `erika-linq`, for a body that runs in 0.99 ms, with 200 call sites hashing to one distinct program. Steps 0–2 only — 19× — with step 3 (`.S`) deferred by measurement |
| [`15-language-surface`](./15-language-surface/README.md) | high | An audit of the written surface against what the parser accepts, producing decisions rather than making them: **24 forms the documents write that do not parse** (the 6 real ones decision 14 named, plus 18 found by walking) and 22 that parse and contradict the document writing them. Among them: there is **no index expression** — `xs[0]` is a parse error anywhere, and decision 8 presupposes one twice |
| [`16-formatter`](./16-formatter/README.md) | **high** | `format --check` is red on four of five libraries, and the formatter is idempotent — so the reds are disagreements about the canonical form. Except one, which is a defect and raised this front's priority: the formatter **deletes the word `default`** (`pub default mod` → `pub mod`), which turns off the package handle and then reports the broken file as clean |
| [`17-beam-memory`](./17-beam-memory/README.md) | high | Module-level `var` and the `#[@BeamMemory.…]` annotation that gives it storage on the BEAM — [decision 28](./decisions-taken.md#28-what-decision-14-left-unassigned)'s last unlanded half, which [`15-language-surface`](./15-language-surface/README.md) measured and left to the semantics. The carrier cannot land alone: `val hits = 0;` reassigned passes `check` and then throws on node, **does not compile** on erlang and does not validate on wasm, because the only immutability rule in the compiler is decision 37's record-field one. The annotation's spelling already parses on a `fn`; what is missing is a declaration that can carry an annotation and a mutable value. The payoff is measured — **96 of `rakun/src/runtime.mjs`'s 231 lines** and **13 of its 16 `@External.Node` declarations** are registry maintenance that this removes rather than ports — and so is the warning: `-on_load` cannot create an ETS table, so the `Ets` mode as designed degrades into the `ProcessDict` it exists to replace (5 requests × 3 increments → the counter reads **0**), unless the module emits an owner. And the maintainer's own rule cuts the front in half: `libs/std/src/erlang.bp` already proves a target-specific std module can drive emission without a `.zig` recompile, so the host primitives belong in a sibling `std/beam` and only the read/write lowering is irreducibly core — question 43 |

## Order

`14` first and `13` immediately after is the maintainer's decision of 2026-09-18
([decision 4](./decisions-taken.md#4-the-order-that-dissolves-the-circular-dependency--settled)); `06` before
both, because it is what makes their snapshot re-recordings cheap.

```
06 comptime-dedup ──► 14 comptime-on-beam (steps 0–2) ──► 13 module-identity ──► 02 erlang ∥ 03 beam
                                   │                          (atom → policy 3 → identity)
                                   └──► 01 checker ──────────────────────────► 07 review-backlog
04 js ∥ 05 wasm ∥ 09 ecosystem ∥ 10 cli ∥ 11 tooling ∥ 12 language-tests   — beside all of it
08 hygiene's sweeps land after each swept file's owner
```

**Critical path:** `06` → `14` → `13` → `02` ∥ `03`, and `06` → `14` → `01` → `07`.

Two orderings are worth stating because measurement, not preference, produced them. **`06` before
`14`**: dedup first means 14 re-records 5 comptime cells, 14 first means 20, of which dedup then
deletes 15. **`13` before the backends**: with the backends first, 13 would re-record 318 cells in
`erlang.zig`'s and `beam_asm.zig`'s snapshot directories on top of what they had just written — and
the identity they need would not exist yet.

The price of that order, which must stay visible: **`02-erlang` and `03-beam` stand still** while 13's
second and third halves run. `04-js` and `05-wasm` are unaffected.

## Rules carried forward

Earned in earlier milestones and still binding:

- **A front never edits a file it does not own.** If a fix needs one, it stops and reports. Every
  carve-out is named in [`fronts.md`](./fronts.md), granted, and written down.
- **A re-recorded snapshot is classified, not bulk-accepted.** A `.snap.md.new` is a proposal: a
  changed RUN LOG must be a value explainable from the emitted code, a new one a value verified by
  running the program.
- **A refactor front lands snapshot-byte-identical**; a fix front re-records only what it verified.
- **One commit never carries two reasons.** 13's three halves exist because of this rule.
- **The gate before landing:** `scripts/gate.sh --cold` green in the front's own worktree, then again
  in the main checkout after the merge. Never `--no-verify`.
- **`AGENTS.md` of every directory touched, in the same commit.**
- A claim in a spec is measured or it is marked unverified. Several rows carried from 1.0.4-beta were
  dropped during this re-cut because they no longer reproduced.
