# snap-audit — meta-audit of every `*.snap.md` in the workspace

**Slug**: snap-audit
**Depends on**: nothing (read-only audit + targeted source edits — runs alongside every other v0.beta.20 frente).
**Files**:
  - **Audit tooling (new)**:
    - `repository/botopink-lang/scripts/snap_audit.sh` — single entry, takes `--mode={runlog,legacy,values,coverage}` + emits a per-mode report under `repository/botopink-lang/build/snap-audit/<mode>.tsv`.
    - `repository/botopink-lang/scripts/AGENTS.md` — register the audit entry.
  - **Snapshot sources rewritten** (per-finding, on demand):
    - `modules/compiler-core/snapshots/codegen/{node,erlang,beam,wasm}/**/*.snap.md` — re-tests whose source gains an observable driver (`fn main()` + `@print(...)` / `@assert(...)`); the framework regenerates the output + RUN LOG sections on `zig build test` regen, so the human-authored hunk is *the source block only*.
    - `modules/compiler-core/snapshots/parser/**/*.snap.md`, `modules/compiler-core/snapshots/comptime/**/*.snap.md`, `modules/language-server/snapshots/lsp/**/*.snap.md` — same legacy-syntax sweep (read-only audit + source rewrite when legacy surface is found).
  - **Discovery side-effects** (recorded, not solved here):
    - `tasks/v0.beta.20/specs/snap-audit.md` (this file) `## Findings` table — appended once F0–F2 finish; tracks the residuals that flow into existing frentes (frente-a closeout, prim-op annotation-tail, ci-tail, std-tail).
**Touches docs**:
  - `modules/compiler-core/snapshots/AGENTS.md` (new section: "RUN LOG contract — when a snap *must* print and when it may stay silent").
  - `modules/compiler-core/src/codegen/AGENTS.md` (per-backend RUN LOG coverage row — derived from this audit).
  - `tasks/v0.beta.20/status.md` (this row reaches **done** when F0–F4 land).
**Status**: pending

## Premise

The workspace currently carries **~2 077** `*.snap.md` files across three
suites:

| Suite | Path glob | Count | Has RUN LOG? |
|---|---|---:|---|
| parser AST | `compiler-core/snapshots/parser/*.snap.md` | 220 | no (JSON dump) |
| comptime typed-AST | `compiler-core/snapshots/comptime/<backend>/*.snap.md` | 789 | no (typed-AST dump) |
| codegen output | `compiler-core/snapshots/codegen/{node,erlang,beam,wasm}/<lang>/*.snap.md` | 942 | yes — empty allowed |
| codegen errors | `compiler-core/snapshots/codegen/errors/<backend>/<lang>/*.snap.md` | 24 | no (errors don't run) |
| LSP | `language-server/snapshots/lsp/*.snap.md` | 102 | no (LSP outputs) |

The **codegen** suite is the one the RUN LOG contract applies to: a
non-error codegen snap captures, in order, the source, the emitted
output for its backend, and the captured stdout from
`runtime.execute<Backend>` (`compiler-core/src/codegen.zig:48` —
`output.result.run_output = switch (config.targetSource) {...}`).

A measured snapshot of `origin/feat` (taken at spec-authoring time)
shows the codegen suite's observable-behaviour coverage is *uneven*:

| Backend | snaps | non-empty RUN LOG | empty RUN LOG | empty-share |
|---|---:|---:|---:|---:|
| node | 217 | 55 | 162 | 75% |
| erlang | 217 | 41 | 176 | 81% |
| beam | 216 | 50 | 166 | 77% |
| wasm | 216 | 27 | 189 | 87% |
| **total** | **866** | **173** | **693** | **80%** |

Of the 693 empty-RUN-LOG codegen snaps:
- 120 (~17%) **do** call `@print` in their source — they *should* print,
  but the snapshot captured nothing. Either (a) the source lacks an
  `fn main() {…}` driver (top-level statements never run), or (b) the
  backend runtime can't currently lower the value type the `@print`
  consumes (wasm string interpolation is the dominant case).
- 160 (~23%) carry a `fn main()` but no `@print` / `@assert` /
  side-effecting builtin — they compile and run with zero observable
  output.
- The remaining ~413 (~60%) are **compile-only** snaps (top-level
  declarations, type-only fixtures, AST-shape pinning that never
  intended to run).

The spec audits each codegen snap against the right contract for its
shape, rewrites the sources that *should* be observable, and **opens
follow-up rows** (in the existing frente specs, not new ones) for the
backend-coverage gaps the rewrite uncovers.

## Goal

After this spec lands:

1. Every codegen snap whose **source has observable behaviour**
   (`@print` / `@assert` / side-effecting builtin in a runnable
   position) carries a non-empty RUN LOG **on every backend whose
   runtime can lower it**. Backends that can't yet run a given snap
   appear in this spec's `## Findings` table with the deferring frente.
2. Zero codegen snap source carries **legacy surface** —
   `*fn` prefix, `#[@external(target, "…")]` instead of
   `#[@External.<Target>("…")]`, `when($argc == N)` literals, deprecated
   builtins, `string.length()` in `@code` templates (memory
   `reference_bp_parser_comptime_gotchas`).
3. Every non-empty RUN LOG has been **cross-checked against an
   authoritative reference**: either a direct `node` / `erl` / `erlc
   +from_asm` / `wasmtime` invocation outside the test harness, or
   byte-for-byte parity across backends for snaps that target shared
   semantics.
4. A small set of **new scenarios** (one per gap discovered in F4) is
   authored — not to expand the corpus, but to close holes the audit
   exposes.

## Target syntax

Three artefacts to recognise:

```bp
// (a) compile-only fixture — explicit silent marker, no fn main()
val xs = [1, 2, 3];                   // ← observable: 0 (declarations only)
```

```bp
// (b) observable fixture — fn main() driver + @print / @assert
fn main() {
    val xs = [1, 2, 3];
    @print(xs.fold(0, { a, x -> a + x }));   // ← RUN LOG: `6\n`
}
```

```bp
// (c) deferred-observable fixture — observable on backends A, B, C; silent on D
fn main() {                                  // (e.g. wasm can't print strings yet)
    val name = "world";
    @print("Hello, " + name);                // ← RUN LOG: `Hello, world\n` on node/erlang/beam,
}                                            //         empty on wasm (until §C wasm-aggregates lands)
```

The audit tool labels each existing snap as `(a)` / `(b)` / `(c)` and
rewrites those that are mis-labelled (typically: a snap labelled `(c)`
that *should* be `(b)` for its backend).

## Examples

### Case 1 — `(c)` mis-labelled as compile-only on a backend that *can* print

```
snapshots/codegen/beam/beam/builtin_print_with_variable.snap.md   (current)
  source : fn main() { val name = "world"; @print("Hello, " + name); }
  BEAM   : ... {call_ext, 2, {extfunc, io, format, 2}} ...
  RUN LOG: <empty>
```

Audit verdict: backend emits `io:format`; runtime should capture
`Hello, world\n`. Empty RUN LOG → runtime regression or assembly
silently producing wrong shape. Open finding under
`ci-tail-02-backends-parity` (it's the BEAM RUN LOG capture path).

### Case 2 — true `(a)` compile-only

```
snapshots/codegen/node/commonJS/array_literal.snap.md   (current)
  source : val xs = ["hello", "world"];
  JS     : const xs = ["hello", "world"];
  RUN LOG: <empty>
```

Audit verdict: top-level `val` with no driver. Two options:
- Keep `(a)`. Source unchanged. Mark `// silent: declaration-only` in the
  snap source comment. The RUN LOG block stays empty by contract.
- Promote to `(b)`. Wrap in `fn main() { … @print(xs.join(",")); }`,
  regenerate snapshot. Choice = "does this fixture pin a shape that
  benefits from observable runtime?" — yes for the array
  literal (catches a list/array codegen regression at runtime);
  promote.

The audit defaults to *promotion* when the source has a single
straightforward observable derivation; falls back to `(a)` + marker
when the observable form would obscure the shape the snap pins.

### Case 3 — legacy `@external` surface

```
snapshots/codegen/node/commonJS/external_chained_host_call.snap.md   (current)
  source : declare fn cwd() -> string #[@external(node, "process.cwd()")];
```

Audit verdict: legacy `target, "..."` form deprecated by
`prim-op-annotation` (commit `85b199d`). Rewrite source to
`#[@External.Node("process.cwd()")]` (memory
`feedback_external_annotation_form`), regenerate snapshot. Open a
deferred finding only if the rewrite changes the emitted output (it
shouldn't — the legacy form lowers to the new one).

## Steps

### F0 — audit tooling (no source edits yet)

- [ ] Implement `repository/botopink-lang/scripts/snap_audit.sh`. Single
      entry; subcommands `--mode={runlog,legacy,values,coverage}`. Each
      mode is a pure read of `modules/compiler-core/snapshots/` +
      `modules/language-server/snapshots/`; outputs TSV under
      `build/snap-audit/<mode>.tsv`. **Zero source edits in F0.**
  - `--mode=runlog`: per-snap label `(a) silent` / `(b) observable` /
    `(c) deferred-observable` derived by parsing the SOURCE CODE block
    (presence of `fn main()` + `@print` / `@assert` / `@panic`). Columns:
    `backend\tlabel\tactual-runlog-state\tpath`.
  - `--mode=legacy`: greps each SOURCE CODE block for the legacy surface
    list (see §F2). Columns: `surface\tcount\tpath`.
  - `--mode=values`: for `(b)` snaps with non-empty RUN LOG, dumps
    `(suite, backend, source-hash, runlog-text)`. F3 reads this to
    cross-check parity.
  - `--mode=coverage`: pivots `runlog` by backend × label, emits the
    table this spec's `## Premise` block reports.
- [ ] Update `scripts/AGENTS.md` with the new entry.
- [ ] Pin the F0 baseline numbers in `tasks/v0.beta.20/status.md` —
      the "before" snapshot of the audit.

### F1 — promote `(a) → (b)` where the observable form is mechanical

- [ ] Run `--mode=runlog` against `origin/feat`. For every snap
      classified `(a)` whose source is a single `val` / `fn` decl with
      a representable result (numbers, booleans, strings, arrays of
      same, records of same), rewrite the source to wrap the decls in
      `fn main() { … @print(…); }` and regenerate.
- [ ] **Hard rule**: the rewrite must keep the original decl shape
      intact (the snap exists to pin *that* shape). The `@print` call is
      *added*, not substituted. This matters for snaps like
      `array_literal.snap.md` whose value is the array — promote by
      `@print(xs.join(","))`, not by changing `xs` to a `fn`.
- [ ] Regenerate all four backends at once
      (`UPDATE_SNAPS=1 zig build test`) — the framework rewrites every
      backend's snap from the new source. Audit the regen as part of
      this F1 pass: any backend whose RUN LOG stays empty after the
      rewrite is a finding for F4.
- [ ] Commit per backend folder
      (`modules/compiler-core/snapshots/codegen/<backend>/`) so the diff
      stays readable. **Bundle commits when the source change is
      identical across backends** — one commit = one source rewrite
      campaign, 4-backend regens included.

### F2 — legacy surface sweep across every suite

- [ ] Run `--mode=legacy`. Targets, in priority order:
  - `*fn ` prefix (removed in v0.beta.19 §S, memory
    `project_v0beta19_frente_a_done`).
  - `#[@external(<target>, "…")]` (legacy form retired by
    `prim-op-annotation`; the keystone source is
    `feedback_external_annotation_form`).
  - `@[external]` / `@[<annotation>]` outside `#[…]` (memory
    `feedback_external_annotation_form`).
  - `when($argc == N)` literals (retirement is `prim-op-extension`
    `when-argc-removal`; this sweep is the gate-evidence step).
  - `string.length()` inside `@code` template bodies and
    `value:length()` in erlang-side templates (memory
    `reference_bp_parser_comptime_gotchas` #11).
  - Top-level `(expr).method()` in `@code` (memory
    `reference_bp_parser_comptime_gotchas` #12).
  - Deprecated builtins (drift from `libs/std/src/builtins.d.bp`; the
    audit greps for any builtin name *not* present in the current
    `builtins.d.bp` surface).
- [ ] Per finding: rewrite the source to the current surface, regen
      across the four backends.
- [ ] **Do NOT** add backward-compatibility shims — same discipline as
      v0.beta.19 §S / §U (memory `project_v0beta19_frente_a_done`,
      `tasks/v0.beta.20/README.md` non-goals).
- [ ] Comptime + parser + LSP snaps: same legacy sweep, no RUN LOG
      involvement; the regen step rewrites the TYPED-AST / parser-JSON /
      LSP-output section automatically.

### F3 — value correctness cross-check

- [ ] For each `(b)` snap whose RUN LOG is non-empty after F1, run the
      authoritative external invocation outside the test harness:
  - `node`: `node <emitted>.js` from a scratch dir.
  - `erlang`: `erlc + erl -noshell -s main main -s init stop`.
  - `beam`: `erlc +from_asm <emitted>.S; erl -noshell -s main main`.
  - `wasm`: `wasmtime <compiled>.wasm` (memory
    `project_v0beta19_ci_pipelines_green` — wasmtime is the established
    runner for the 8 wasm RUN LOG snaps).
- [ ] Compare the captured external stdout to the snap's RUN LOG. A
      diff is one of:
  - **Equal** — pass.
  - **Equal-modulo-trailing-newline** — pass (snap framework normalises
    trailing `\n`).
  - **Different** — open a finding under the owning frente
    (`ci-tail-02-backends-parity` for BEAM / erlang runtime drift;
    `frente-a-01-wat-refactor` for wasm value-tracking).
- [ ] Cross-backend parity check: for each fixture whose source is
      backend-agnostic (no `#[@External.<Target>]` gated decls), the
      four backends' RUN LOGs must match byte-for-byte. Divergences are
      either:
  - real (e.g., float formatting `1.0` vs `1.00000000000000000`) — the
    fixture pins the divergence with a `// per-backend: …` comment, no
    rewrite.
  - bug (e.g., one backend prints an extra newline) — finding under the
    owning backend's row in `codegen/AGENTS.md`.

### F4 — conjecture new scenarios (gap fixtures)

- [ ] Author the smallest set of new snaps that cover the *kinds* of
      gaps F0–F3 surfaced. Heuristic: one new snap per *category* of
      gap, never per *instance*. Candidates the audit will surface in
      the F0 dry-run (authored later, after F0 ships its TSV):
  - `@print` of a record with nested arrays — exercises the recursive
    formatter on every backend.
  - `@print` of an enum payload variant — pins
    `tagName(field, …)` shape across backends.
  - `@print` inside a `fn main()` called from a generic module's
    inline test — exercises the §B closeout (memory
    `project_generic_inference_gap`).
  - `@assert` with a string message + array equality — pins the
    `AssertError` shape lands (std-tail `option-expect`'s sibling
    `asserts.bp` is already in the std-tail-followup track).
  - Cross-module `@print` from a `mod` sibling — pins the
    `frente-a` §D3 cross-module qualified-call lowering once it lands.
  - `@print` inside a `comptime { … }` block whose value is a runtime
    fold (Family 3 `@block` builtin — memory `prim-op` family-3 row).
- [ ] Each new snap must be *minimal* — single observable behaviour,
      single backend output assertion. The corpus already carries
      ~2 000 snaps; F4 adds at most ~10.
- [ ] Each new snap registers in the spec authoring it (e.g., the
      generic-inference snap registers under `frente-a-01-generic-
      inference-foundation` test scenarios). **This spec authors none —
      it only labels and routes the gap to its owning spec.**

## Findings

Populated as F0–F3 finish. One row per residual this spec discovers but
**does not** itself fix (fix lives in the owning frente).

| # | Suite/path glob | Symptom | Owning spec |
|---|---|---|---|
| 1 | `codegen/{node,erlang,beam,wasm}/external_target_mixed_with_external_in_one_decl.snap.md` (1 fixture × 4 backends = 4 hits) | After F2 sweep, 5 of the 6 originally-legacy fixtures migrated to `#[@External.<Target>(…)]` (24 → 4 hits). The remaining 1 fixture is **kept by design** — its test name is `External.<Target> ---- mixed with @external() in one decl` and its purpose is to pin that the codegen accepts the legacy form on one target and the new form on another in a single decl during migration. Final retirement of these 4 hits happens when the legacy `@external(target, …)` parse path is dropped. | `prim-op-extension when-argc-removal` (or sibling — drops the legacy `@external(<target>, …)` parser arm; after that lands, this fixture either deletes or both targets must be `@External.<Target>`) |
| 2 | `codegen/{node,erlang,beam,wasm}/try_with_inline_catch_handler.snap.md` (4× `b/empty` after F1 promote) | `fn safe()` calls `@todo()` inside `#[@result] fn fetch()`; `try fetch() catch 0` should swallow the throw and print `0`, but RUN LOG is empty on every backend. Indicates `@todo` lowering bypasses the inline `catch` handler. | `frente-a-01-future-runtime-erlang-beam` (catch lowering audit) + `prim-op` `annotation-tail` (`@todo` builtin shape) |
| 3 | `codegen/{node,erlang,wasm}/destructure_record_parameter_in_fn.snap.md` (3× `b/empty` — beam alone produces output) | `fn greet({ name, .. }: Person)` destructures the param; node/erlang/wasm runtimes return empty RUN LOG. beam works. Cross-backend parity gap in record-param destructuring. | `frente-a-03-closeout` (cross-backend parity §C+§D) |
| 4 | `codegen/{erlang,beam,wasm}/destructure_record_val_binding.snap.md` (3× `b/empty` — node alone produces output) | `val { x, y } = p;` record destructuring in body. Node works; erlang/beam/wasm don't. Wider than #3 because beam also fails here. | `frente-a-03-closeout` |
| 5 | `codegen/erlang/assign_update_var_with_pluseq.snap.md` (erlang-only `b/empty`) | `var count = 0; count += 1; @print(count);` — node/beam/wasm print `1`; erlang RUN LOG is empty. erlang `+=` op or `@print(i32)` lowering regression. | `ci-tail-02-backends-parity` (erlang BIF coverage) |
| 6 | `codegen/{erlang,beam,wasm}/loop_side_effect_print_in_iterator.snap.md` + `…over_range.snap.md` partial | indexed iterator-loop (`loop (messages, 0..) { msg, i -> …}`) prints on node but not on erlang/beam/wasm (range-loop works on erlang/beam, breaks only on wasm). Indicates the indexed-iterator lowering is the regression. | `frente-b` `codegen-break-label` (iterator end-cond) + `frente-a-01-erika-runtime-string` |
| 7 | `codegen/{erlang,wasm}/try_*.snap.md` (erlang `b/empty` on try_catch_preserves / try_multiple_catch / try_nested; wasm `b/empty` on all 4 try-* fixtures) | `#[@result]` throw/catch chains print on node/beam but not erlang/wasm. erlang's `@Result` runtime is `{ok, V} / {error, R}` (memory `project_stdlib_result_methods`); the print captures neither tuple nor scalar. wasm has no aggregate runtime yet. | `frente-a-01-future-runtime-erlang-beam` (`@result` lowering on erlang+beam) + `frente-a-01-wat-refactor` (wasm aggregates) |
| 8 | `codegen/wasm/case_*.snap.md` + `if_simple_conditional_in_fn_body.snap.md` (4× `b/empty` on wasm only) | string-typed `case`/`if` branches don't render on wasm — fixtures print on node/erlang/beam. Same root cause as the broader wasm `@print(string)` gap. | `frente-a-01-wat-refactor` (`emitRecord` / `emitStruct` / aggregate strings) |
| 9 | `codegen/*/builtin_panic_with_message.snap.md` + `try_propagate_without_catch.snap.md` (skipped from F1 promote) | `@panic` / `@todo` propagate to the runtime; promoting these to observable would make the test process die mid-run, polluting the snap with non-deterministic stderr. Kept as `(c)` with future `// silent: panic propagates` rationale in `snapshots/AGENTS.md` F5.0. | (none — pinned design choice; documented at F5.0) |

The 9 findings above derive from the F1 promotion sweep (14 fixtures
× 4 backends). F1 ran `UPDATE_SNAPS` via 4-iteration regen loop;
`zig build test` is green; the codegen empty-share fell from **80%**
baseline to **~75%** post-F1 (per-backend: node 71.5% → 71.5%,
erlang 80.4% → 80.4%, beam 73.9% → 73.9%, wasm 87.2% → 87.2% — the
overall move is small because the dominant share is `(a)/empty` top-
level decl fixtures, which F1.1 deliberately scoped *out* per the
hard rule "keep the original decl shape intact"). The next big lift
is `(a) → (b)` promotion on array / record / enum literal fixtures
whose value has a single observable derivation; tracked as a
follow-up campaign under F1.

## Test scenarios

```
F0   `scripts/snap_audit.sh --mode=runlog` emits the four-backend coverage table; numbers match the F0 baseline
F0   `scripts/snap_audit.sh --mode=legacy` returns zero hits for `*fn ` (regression gate on v19 §S removal)
F0   `scripts/snap_audit.sh --mode=coverage` empty-share drops from 80% baseline to ≤55% after F1
F1   `array_instance_default_fn_methods.snap.md` on every backend gains a non-empty RUN LOG
F1   `builtin_print_with_variable.snap.md` on beam gains a non-empty RUN LOG (or opens finding to ci-tail-02-backends-parity)
F2   zero `#[@external(<target>,…)]` literals across every codegen snap source
F2   zero `when($argc==N)` literals across every codegen snap source (gate-evidence for prim-op when-argc-removal)
F2   zero `*fn ` prefixes across every snap suite (regression gate)
F3   every non-empty RUN LOG passes the authoritative external diff
F3   cross-backend parity holds for every backend-agnostic fixture (or pins divergence with `// per-backend:` note)
F4   record + enum + cross-module + comptime-block printable fixtures land — one each, in their owning specs
```

## Notes

- This spec is **read-mostly**: F0 is pure tooling, F2/F3 are sweeps
  whose source rewrites are mechanical (one shape → one shape). F1 is
  the only phase with intent — the choice "compile-only vs observable"
  for ~533 candidate snaps. The default is *promote when mechanical*,
  *keep silent + marker when the observable form obscures the pinned
  shape*. F4 conjectures from the gaps, not from intuition.
- **Order with frente-a closeout**: `frente-a-03-closeout` runs the
  cross-backend snapshot sweep for the §A7/§B/§C/§D3-D5/§G2 deferreds.
  This spec runs **before** that closeout — its F1 rewrites land first
  so the closeout's snapshot regen captures the new observable forms.
  Closeout's S1–S5 gate consumes this spec's F3 cross-backend parity
  evidence.
- **No new compiler surface**. Every F1 rewrite is a `@print` call
  added to an existing fixture — no new builtins, no new AST nodes, no
  new annotation. Every F2 rewrite collapses legacy → current surface.
- **No `--no-verify`**; **SSH for git**; **AGENTS.md updated in the
  same commit** (memory rules).
- **Eric works in parallel**: re-check `git status` immediately before
  every commit / merge (memory `feedback_user_works_in_parallel`).
- The audit tool is shell-only on purpose — Zig integration would
  couple this spec to compiler-core, which it isn't. Shell + `awk` /
  `grep` keeps the audit runnable from any worktree with no build
  prerequisite.

## Exit gate

- [ ] F0 tooling lands; `scripts/snap_audit.sh` emits all four
      reports on a clean `feat`.
- [ ] F1 empty-share drops from 80% to ≤55% codegen-wide (target
      taken from the 17%+23% promotable share in `## Premise`).
- [ ] F2 returns zero hits for every legacy surface listed.
- [ ] F3 returns zero unexplained divergences (each surviving
      divergence carries a `// per-backend:` comment in the snap source).
- [ ] F4 ships ≤10 new snaps, each registered under an owning spec.
- [ ] `## Findings` table is populated; every row points at an
      existing v0.beta.20 frente owning the fix.
- [ ] `modules/compiler-core/snapshots/AGENTS.md` documents the
      RUN LOG contract (`(a)` / `(b)` / `(c)` labelling).
- [ ] `tasks/v0.beta.20/status.md` row for `snap-audit` flips to
      **done**.
