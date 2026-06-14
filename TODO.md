# TODO — frente-a-compiler (v0.beta.19)

> Branch: `task/frente-a-compiler` · Worktree: `.tasks/frente-a-compiler/`
> Spec: [`tasks/v0.beta.19/specs/frente-a-compiler.md`](tasks/v0.beta.19/specs/frente-a-compiler.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Internal ordering

```text
§A (keystone)  ──▶  §B  ──▶  §D
§A             ──▶  §C  (parallel with §B after §A)
§A             ──▶  §G  (erika DSL, file-disjoint)
§S  (*fn removal)      — parallel; lexer/parser/AST
§U  (unused-builtin)   — parallel; builtins.d.bp + comptime handlers
```

§S ships first (pure deletion, byte-identical). Then §A (keystone),
then §B/§C/§D/§G in parallel. §U after the Rules track in Frente B
locks the effect tags.

## Coordination

- **§D-D4 (`#[@future]` erlang/beam)** consumes Frente B's Rules track
  §1F — schedule §1F first; §D-D4 reads it. If §1F isn't in yet,
  §D-D4 scopes to follow-up per the spec's "scope to follow-up" clause.

---

## §A — annotation-driven-builtins tail
- [x] **A6** — migrate every remaining prim method that still relies on a
      hardcoded entry. Closed per spec's "or document the irreducible
      allow-list" clause: residual hardcoded arms are BEAM bytecode
      patterns (need template machinery), erlang `length` BIF arm (needs
      val-annotation support), commonJS property-vs-call special case,
      and wat string-length read — all recorded in
      `codegen/AGENTS.md` "§A6 closure" subsection. Snapshot diff is
      empty (no codegen behaviour changed).
- [ ] **A7** — Array.zip via ONE annotation on all 4 targets. **Deferred**
      to follow-up — gated on BEAM bytecode-template work above; without
      it, "lowers on all 4 targets without .zig edits" can only land on
      3 of 4 (commonJS + erlang + wat, sans BEAM).

## §B — generic-inference
- [ ] **B1** — resolve `Self`'s primitive kind inside an interface
      `default fn` body (`comptime/infer.zig` `instance_lowering`).
- [ ] **B2** — instantiate callee generic vars before `unifyAt` so
      generic inline `test { … }` works; re-fold external `*_test.bp`
      shadow files back to inline tests in `order.bp` / `sets.bp` /
      `dict.bp` / `queue.bp`.
- [ ] **B3** — fix `variable 'B' is unbound` codegen bug from LINQ
      pipeline; capture the `B`-binding lambda's free vars.
- [ ] **B4** — emit primitive interfaces' instance `default fn`s on
      erlang + beam (mangled). erika test-libs row flips red→green on
      erlang and beam.
- [ ] **B5** — drop the generic-module inline-test caveat in
      `libs/std/AGENTS.md`; add inference unit tests for B1/B2.

## §C — wasm-aggregates + wat stack-discipline
- [ ] **C1** — track per-expression "produces a value" in the wat
      emitter. Classifier + `returns_value` threaded into `emitBody`.
- [ ] **C2** — wire `botopink test --target wasm`. `test_cmd.zig:46`
      gates wasm; test-mode emits `__bp_run_tests`; CLI invokes via
      `wasmtime`.
- [ ] **C3** — record field layout (stable 4-byte slot offsets).
- [ ] **C4** — `?.` on wasm: guards base against null, reads the slot.
- [ ] **C5** — note wasm single-module rule in `codegen/AGENTS.md`.
- [ ] **C6** — update `codegen/AGENTS.md`; add `.wat` snapshots.

## §D — cross-backend feature parity
- [ ] **D1** — `console.log` + `new Error(…)` declared as `#[@external]`;
      lowered by reading the annotation.
- [ ] **D2** — cross-module fn imports lower to remote call on erlang
      first, then beam. Unblocks `from "std"` on erlang/beam.
- [ ] **D3** — typed-value method dispatch (`p.parse(x)` →
      `'Parser_parse'(P, X)` on erlang/beam).
- [ ] **D4** — `#[@future]` lowering on erlang/beam (spawn body as
      process, return Future handle whose `await` joins). **Reads
      contract from Frente B §1F.** Scope to follow-up if too large; note
      in `codegen/AGENTS.md`.
- [ ] **D5** — BEAM inline-fun array/string methods: `join`, `indexOf`,
      `at`, 2-arg `slice`, string `contains` / `startsWith`.
- [ ] **D6** — update beam + erlang AGENTS "Remaining gaps"; add
      cross-backend snapshots for D1–D3 + D5; sweep the negation
      `gc_bif Live count` note.

## §G — erika DSL extensions
- [ ] **G1** — lower `${expr}` interpolations inside an `erika`
      template literal (reuse `Part.Interp` machinery).
- [ ] **G2** — `var s = "select ..."; erika s` runtime-string form
      (generic mechanism, no erika coupling in core).
- [ ] **G3** — update `libs/erika/AGENTS.md` "Recorded gaps"; add `.bp`
      tests under `libs/erika/tests/`.

## §S — remove deprecated `*fn` prefix
- [x] **S0** — survey: `git grep -nE '\*fn\b' repository/` captures the
      surface; sanity-check zero authored `.bp` / `.d.bp` hits.
- [x] **S1** — lexer drops `*` lookahead; parser emits
      `deprecated-star-fn` diagnostic with migration help line.
- [x] **S2** — delete `EffectKind.fromStarReturn` + `FnDecl.is_star`;
      docstrings drop `*fn` mentions; collapse `effectAnnotation` if
      identical to `effect`.
- [x] **S3** — rewrite codegen comment lines (`// *fn …` → `#[@<effect>]`).
- [x] **S4** — rewrite `\\*fn` literals in `js_builtins.zig` (5) +
      `js_control_flow.zig` (~30); output stays byte-identical.
- [x] **S5** — AGENTS sweep + `CHANGELOG.md` `BREAKING:` line.
- [x] **S6** — gate: `git grep '\*fn'` finds only the CHANGELOG line;
      `zig build test` + `botopink-lib-test` green; end-to-end test of
      the diagnostic.

## §U — remove unused stdlib builtins
- [x] **U0** — re-run candidate grep at execution time; abort any
      candidate that now has a caller. (2026-06-14: 15/15 fns + 8/8
      tags confirmed zero authored callers.)
- [x] **U1** — per confirmed-unused fn (15 candidates from the
      2026-06-13 audit): delete declaration + handler + per-backend
      lowering + AGENTS row. **Landed as one composite commit**
      (975910b) — `typeOf`/`typeName`/`sizeOf`/`alignOf`/`hasField`/
      `hasDecl`/`tagName`/`min`/`max`/`abs`/`as`/`block`/`src`/
      `compilerError`/`embedFile`/`root` + `pub interface AsyncIterable`.
- [x] **U2** — per unused `@<tag>` (8 candidates): subsumed by U1 —
      capture-tag form derives from the same fn surface; deleting the
      fn removes the `@<tag>` form. **KEEP** the six effect tags +
      `@trap` / `@module` (their fn counterparts are retained).
- [ ] **U3** — sweep `builtins.d.bp` comment-block headers; delete
      orphans. (DONE inline with U1 — 5 orphan headers removed: type
      reflection, numeric, control flow, compile-time I/O, "compile-time
      diagnostics" block. Re-verify before gate.)
- [x] **U4** — `CHANGELOG.md` grouped `BREAKING:` line (in 975910b).
- [ ] **U5** — gate: full test sweep green; fresh `git grep` finds each
      removed symbol only in CHANGELOG.md.

---

## Done gate (whole frente)

- [ ] every section's checklist ticked above
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` green
- [ ] every touched AGENTS.md updated in the same commit as the code
      (memory rule `feedback_agents_md_maintenance`)
- [ ] zero `*fn` literals in `repository/` outside `CHANGELOG.md`
- [ ] every entry in `libs/std/src/builtins.d.bp` has at least one
      authored caller
- [ ] commit message convention: `feat(...)` / `refactor(...)` /
      `docs(...)` per phase; English; no `--no-verify`

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/frente-a-compiler/`.
- Functions in camelCase (`feedback_camelcase_naming`).
- Implement in `.bp` when possible (`feedback_prefer_bp_over_dbp`);
  `.d.bp` only for markers / FFI / abstract interface.
- After each commit, advance to the next checkbox (`feedback_continue_after_commit`).
