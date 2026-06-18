# template-static-fold — fold `@Expr` / `@ExprCustom` template bodies statically, skip the `node` spawn

**Slug**: template-static-fold
**Depends on**: nothing — file-disjoint with the rest of v0.beta.21. Touches the V1 classifier in `infer.zig` + a new sibling folder module under `comptime/`. The runtime-backed `template_eval.evaluate` path stays as a fallback.
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/comptime/template_static_fold.zig` (NEW, ~400 LOC) — the pure-Zig constant-folder. Walks an already-typed template body, recognises `CustomNode(...)` literals, `e.lookup(name)`, `e.build(<folded string>)`, `e.custom(tree, code)`, list/record literals, `val` chains, and returns an `Outcome` byte-equivalent to what `template_eval.evaluate` would emit. Returns `null` on the first un-foldable node.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/infer.zig` — extend the V1 classifier (`infer.zig` already has one; spec extends the recogniser). At the call site, before dispatching to `templateEval.evaluate`, try the folder. On `Some(outcome)` thread it back as if eval ran; on `None` keep today's eval path. Single new branch, ~40 LOC.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/template_eval.zig` — drop the stale "Tooling paths (compileTypesOnly / LSP) never reach this module" line (line 18-19); add a one-liner pointing to the folder as the preferred fast path.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/tests/template_static_fold.zig` (NEW, ~25 cases) — pin every foldable shape (incl. negative cases that must NOT fold), runtime-independent (no `node` reached).
  - `repository/botopink-lang/modules/language-server/src/tests/sublanguage.zig` — no source change; the existing 9 tests become the integration assertion.
**Touches docs**:
  - `repository/botopink-lang/modules/compiler-core/src/comptime/AGENTS.md` — new `template_static_fold.zig` row + a paragraph wiring the V1 → folder → eval fallback chain.
  - `repository/botopink-lang/modules/compiler-core/src/comptime/docs.md` — same fallback chain in narrative form.
  - `repository/botopink-lang/CHANGELOG.md`.
  - `tasks/v0.beta.21/status.md`.
**Status**: pending

## Problem

`template_eval.evaluate` (compiler-core/src/comptime/template_eval.zig:292) spawns `node` per call site to expand the body of every `@Expr` / `@ExprCustom` template fn whose body the V1 classifier in `infer.zig` cannot reduce. Each spawn is ~18ms on a warm machine. v0.beta.20's `test-speed-tmp-consolidation` added a process-wide stdout memo (SHA-256 → cached stdout), which kills duplicate spawns but leaves the first-of-kind cost intact:

- **9 sublanguage tests in `modules/language-server/src/tests/sublanguage.zig`** measure ~20ms each in `zig build test --time-report`. The hot loop is `compileEval → LspCompiler.compile → compileTypesOnly → templateEval.evaluate → node`. With the v0.beta.20 memo: 4 unique scripts × ~18ms = ~72ms; 5 cache hits @ ~1ms = ~5ms. Total ~77ms of test time is pure subprocess overhead.
- **Every codegen test that triggers a template** pays the spawn × 4 backends (commonJS/erlang/wasm/beam). The eval is host-side (always `node`), so the script is the same across backends — but each backend's compile invokes the eval independently. Same memo helps inside one process, but at ~150 codegen tests × 4 backends with templates, the cold spawns add up.

**Crucial observation:** in practice every sub-language template (`erika`, `html`, `q`-style query DSL, json model, …) is **structurally a constant-folder problem** — the body builds a fixed `CustomNode`/`@code` tree from the captured `@Expr` argument and a handful of `e.lookup`/`e.build` calls, with no loops or external IO. Zig can fold these by walking the already-typed AST. The `node` runtime exists for templates that genuinely need JS evaluation (today: none in the test corpus; tomorrow: maybe arithmetic-driven HTML, dynamic dispatch on a captured value).

The fast path therefore is: **fold what we can, run JS for what we cannot.**

## Intent

- **Add a pure-Zig constant-folder for template bodies.** Lives in `template_static_fold.zig`. Walks the typed AST of `tfn.body` with the `captures` + `plainArgs` bound, recognises a closed catalogue of "foldable" node kinds, returns a `template_eval.Outcome` byte-equivalent to what `node` would emit. Returns `null` on the first un-foldable node — never approximates.
- **Wire it in as a strict precondition to `template_eval.evaluate`.** Same call-site in `infer.zig`. The fallback to JS stays — folder is a fast path, not a replacement.
- **Zero behavioural change.** Folded vs. evaluated outcomes must be byte-identical (the unit tests pin a closed shape). The folder is an optimisation, not a redesign of expansion semantics.
- **One catalogue of folder shapes**, documented in `template_static_fold.zig`'s top comment, kept in sync with the unit tests.

## Foldable catalogue (closed set, v1)

```
1. Literal:
   - string/int/float/bool/null literal
   - list literal of folded elements
   - tuple literal of folded elements
   - record literal of folded fields (anon record `{ k: v, … }` or nominal `Name(k: v)`)
   - enum variant constructor with folded payload

2. Captured-expr surface (the `e: @Expr<T>` parameter's methods):
   - e.build(<folded string>)                 → Outcome.code{<string>}
   - e.custom(<folded CustomNode>, <folded string>) → Outcome.custom{ ast, code }
   - e.lookup("Name")                         → CustomRef{ name: "Name", scope: caller.topLevel }
   - e.failAt(<folded Span>, <folded string>) → Outcome.fail{ message, span, param: null }
   - e.fail(<folded string>)                  → Outcome.fail{ message, span: null, param: null }

3. CustomNode constructor (a record literal):
   - CustomNode(kind, span, label, ref, children) with all five fields folded.

4. Plumbing:
   - val <name> = <folded expr>;             → bind in folder's local env
   - val <name>: <type> = <folded expr>;      → same
   - <name> resolves to a previously folded `val` or to a capture/plainArg
   - tail `return <folded expr>;`            → final outcome
   - block-as-expression { … <tail> }         → fold body, take tail
```

Anything else returns `null` (un-foldable): conditionals, loops, function calls outside the surface above, `try`/`throw`, async, references to module-level symbols other than the captured `e`, etc. The catalogue is intentionally small for v1.

## DAG

```
F0-folder-skeleton        the new module + Outcome surface + unit-test scaffold
F1-foldable-catalogue     implement each row of the catalogue above (TDD)
F2-wire-into-infer        plug as the V1-classifier extension; eval stays as fallback
F3-sublanguage-pin        prove ~20ms → <1ms on the 9 LSP sublanguage tests
F4-codegen-pin            prove ~72ms → ~1ms on codegen tests that exercise templates
F5-docs-and-status        AGENTS/docs/CHANGELOG/status sweep
```

---

## F0 — `template_static_fold.zig` skeleton

**Files**: `repository/botopink-lang/modules/compiler-core/src/comptime/template_static_fold.zig` (NEW), `…/comptime/tests/template_static_fold.zig` (NEW).

Layout:

```zig
//! Pure-Zig constant-folder for `@Expr` / `@ExprCustom` template bodies.
//! Lives between the V1 classifier (`infer.zig`) and the runtime-backed
//! evaluator (`template_eval.zig`): tries to fold; if not, returns null
//! and the caller falls back to JS.
//!
//! Foldable catalogue documented at the top of the file (kept in sync with
//! `tests/template_static_fold.zig`).
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const eval = @import("./template_eval.zig");

/// Try to fold `tfn`'s body against the given captures/plainArgs.
/// Returns null on the first un-foldable node — never approximates.
pub fn tryFold(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) ?eval.Outcome {
    // …
}
```

Smoke test in F0:

```
fold ---- empty body returns null
fold ---- top-level literal returns null (not a template shape)
```

---

## F1 — Foldable catalogue (TDD)

**Files**: `template_static_fold.zig` + `tests/template_static_fold.zig`.

Implement one shape per slice. Each slice = one PR-sized step; every step ships pinning tests that NEVER reach `node` (the test harness asserts `template_eval.evaluate` is not called — via a `tryFold(...).?` assertion).

```
fold ---- bare e.build("[1, 2]")                       → Outcome.code{"[1, 2]"}
fold ---- val s = "[1, 2]"; return e.build(s);          → same
fold ---- bare e.failAt(Span(1,2,3), "msg")             → Outcome.fail{...}
fold ---- CustomNode literal with no children           → CustomNode struct
fold ---- CustomNode literal with children: [a, b]      → nested CustomNode tree
fold ---- e.lookup("Users")                             → CustomRef{name:"Users", …}
fold ---- nested `val` chain (kw, col, root)            → folded root
fold ---- bare e.custom(root, code)                     → Outcome.custom{ ast, code }
fold ---- block-as-expression body                       → tail outcome
fold ---- if-expression body                            → returns null (un-foldable)
fold ---- function call outside surface                 → returns null
fold ---- reference to module-level fn                  → returns null
```

---

## F2 — Wire into `infer.zig`

**Files**: `…/comptime/infer.zig` (~40 LOC at one call-site).

```
// existing
const outcome = templateEval.evaluate(env.arena, ctx.io, ctx.build_root, tfn, captures, plainArgs) catch …;

// after
const folded = template_static_fold.tryFold(env.arena, tfn, captures, plainArgs);
const outcome = if (folded) |o| o
    else templateEval.evaluate(env.arena, ctx.io, ctx.build_root, tfn, captures, plainArgs) catch …;
```

`template_eval.evaluate` stays untouched (memo from v0.beta.20 still applies for non-foldable templates).

`template_eval.zig:18-19` comment ("Tooling paths never reach this module") is replaced by one line: "Most call sites are intercepted by `template_static_fold.tryFold` before reaching here — this module only runs when the body has truly dynamic computation."

---

## F3 — Sublanguage pin (LSP regression target)

**Files**: no source change; the existing tests in `modules/language-server/src/tests/sublanguage.zig` are the integration assertion.

Exit gate:
- `zig build test -Dtest-filter="sublanguage" --time-report` shows each sublanguage test at **< 1ms** (down from ~20ms today).
- Adding a `std.debug.print` in `template_eval.evaluate` and re-running the filter prints zero MISS lines (every body was folded).
- All 9 sublanguage tests continue to pass byte-identical snapshots.

---

## F4 — Codegen pin

**Files**: pick one representative test from `modules/compiler-core/src/codegen/tests/js_comptime.zig` (the "template end to end ---- bounded html expansion" case is ideal) and assert it drops from ~1.3s to under 100ms (4 backends × ~20ms spawn → 4 × ~0.5ms fold).

The codegen path runs comptime for all 4 backends (commonJS/erlang/wasm/beam); each backend calls into `templateEval.evaluate` independently. The folder is target-agnostic (it produces an `Outcome` regardless of target), so a single fold result is reused across all 4 backends inside one process.

Exit gate:
- The 5 `template end to end ----` cases in `js_comptime.zig` drop to <100ms each. Their snapshots remain byte-identical.

---

## F5 — Docs + status sweep

**Files**:
  - `…/comptime/AGENTS.md` — add `template_static_fold.zig` row + paragraph describing the V1 → folder → eval chain.
  - `…/comptime/docs.md` — narrative version of the same chain.
  - `repository/botopink-lang/CHANGELOG.md` — entry under v0.beta.21.
  - `tasks/v0.beta.21/status.md` — row flipped to **done** when F0–F4 are green.

---

## Test scenarios

```
fold ---- bare e.build with string literal
fold ---- bare e.build with val-bound string
fold ---- bare e.failAt with literal span + message
fold ---- bare e.fail with literal message
fold ---- CustomNode literal: no children
fold ---- CustomNode literal: with children list
fold ---- val chain (kw, col, root) into e.custom
fold ---- e.lookup("Name") becomes a CustomRef
fold ---- block-as-expression body collapses to tail outcome
fold ---- record literal with all folded fields
fold ---- list of folded elements
fold ---- enum variant constructor with folded payload
fold negative ---- if-expression body returns null
fold negative ---- function call outside surface returns null
fold negative ---- reference to module-level fn returns null
fold negative ---- loop body returns null
fold negative ---- try/throw returns null
sublanguage integration ---- 9 LSP tests < 1ms each
sublanguage integration ---- zero MISS in template_eval after fold lands
codegen integration ---- "bounded html expansion" < 100ms
codegen integration ---- 4 backends share one fold
```

## Notes

- **Catalogue is intentionally tiny.** Extending it later is one slice each; the folder reports `null` on anything outside, so over-eager folding is impossible. This is a strict-subset accelerator, not a re-implementation of eval semantics.
- **No new dependencies.** Pure Zig; no `node` involvement.
- **No file collisions** with the rest of v0.beta.21. Touches `infer.zig` at one call-site only (~40 LOC), file-disjoint from any inference rewrite.
- **Eval-fallback safety net.** Because `tryFold` returns `null` whenever it's unsure, any template the folder can't handle continues to evaluate via `node` exactly as today. The memo from v0.beta.20 (`test-speed-tmp-consolidation`) still applies to that fallback path.
- **Why one spec, not two.** The "skip JS no LSP" idea and "extend V1 classifier" idea collapse into the same implementation: a constant-folder used as a V1 extension. Putting it as a V1 extension (rather than an LSP-only branch) means the codegen path also benefits — at no extra cost.
- **What is explicitly OUT of scope:**
  - Persistent `node` IPC (separate spec if v1 folder doesn't cover enough of the corpus).
  - Embedded QuickJS (separate spec; bigger dependency call).
  - Folder-vs-eval paranoid diff mode in CI (nice-to-have; add only if a regression surfaces).
  - Folding for non-`@Expr` runtime templates (e.g. decorator bodies) — different evaluator, different catalogue.
- **Exit gate (full spec):**
  - `template_static_fold.zig` unit tests green on all 4 backends (the unit tests are runtime-agnostic).
  - 9 LSP sublanguage tests < 1ms each.
  - 5 `template end to end ----` codegen cases < 100ms each.
  - Adding a sentinel `std.debug.print` inside `template_eval.evaluate` and running the full suite shows zero invocations on the sublanguage tests.
  - `AGENTS.md` per affected module updated in the same commit as code.
