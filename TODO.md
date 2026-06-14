# TODO — prim-op-annotation (v0.beta.19 satellite)

> Branch: `task/prim-op-annotation` · Worktree: `.tasks/prim-op-annotation/`
> Spec: [`tasks/v0.beta.19/specs/prim-op-annotation.md`](tasks/v0.beta.19/specs/prim-op-annotation.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Mission

Extend `#[@external]`'s template grammar so every primitive-method
lowering across the four codegens is annotation-driven. Delete **~105
hardcoded switch arms** across `erlang.zig` + `beam_asm.zig` +
`commonJS.zig` + `wat.zig` by migrating to `primitives.d.bp` /
`builtins.d.bp` annotations. Output stays **byte-identical** at every
commit — this is a pure refactor.

## Coordination

- **Frente A §A keystone must be in place.** §A5 (annotation-driven
  primitive method emission, last commit `0a37fbe`) is the prerequisite —
  `tryEmitPrimAnnotation` exists. This worktree extends the grammar it
  consumes.
- **Frente A §A6 hands its surviving switch arms off to this spec.**
  After F2 here lands, §A6's "irreducible allow-list" carve-out goes
  away — every prim method is annotation-driven.
- **Frente A §D-D5 (BEAM inline-fun array/string methods) collapses
  into entries on this annotation grammar.** Coordinate at merge:
  prefer this spec landing first so §D-D5 becomes "author annotation
  rows in `primitives.d.bp`" not "hand-code BEAM helper funs".
- **Land before std-expansion.** The new modules in std-expansion
  consume the multi-line `"""…"""` + `$stringify(...)` grammar this
  spec ships.

---

## F0 — extend the AST + parser
- [x] **F0.1 (partial)** — `comptime/primOpTemplate.zig` carries the
      template-vs-legacy discriminator (`looksLikeTemplate`); no AST
      enum churn (`legacy_2_arg` / `template` / `arity_branch`) — the
      raw `external` symbol bytes ARE the template body, recognised by
      the `$` marker. `arity_branch` (`when($argc == N)`) and `"""…"""`
      raw-string form remain deferred (need parser + ast extension).
- [ ] **F0.2** — `"""…"""` raw strings (any string with embedded `"`
      like `Array.join`'s `io_lib:format("~p", …)` template body needs
      this); `when(…)` clauses (`Array.slice` arity branch). Both
      deferred — the existing migrations use single-string templates
      that fit on one line.

## F1 — `tryEmitPrimAnnotation` + shared renderer
- [x] **F1.1** — `comptime/primOpTemplate.zig` shipped: `render(template,
      ctx)` walks the body and dispatches `$self` / `$<digits>` markers
      via `ctx.emitRecv()` / `ctx.emitArg(i)`. RP1
      (`error.PrimOpArgIndexOutOfRange`) reserved.
- [x] **F1.2 (erlang only)** — `codegen/erlang.zig`
      `tryEmitPrimAnnotation` detects template form via
      `primOpTemplate.looksLikeTemplate(call.symbol)` and renders;
      `collectIfaceErlangDispatch` stores the template body verbatim
      (skips `parseExternalCallTemplate`, which would mis-parse
      `($self ++ $0)` as a `f(arg)` shape). `codegen/beam_asm.zig`
      short-circuits on the same discriminator and falls through to its
      inline switch (BEAM has not migrated). `codegen/commonJS.zig` /
      `codegen/wat.zig` not yet wired — pending.
- [ ] **F1.3** — `$stringify($expr)` not yet supported. Per-target
      table not yet added to `codegen/AGENTS.md`.

## F2 — migrate Family 1 (`emitPrimMethod`) — erlang only
- [x] **F2.Array.append** — `($self ++ $0)` annotation; switch arm deleted
      (NB: spec said `($self ++ [$0])`, but the existing switch — and
      `default fn append(self, other: Self)` semantics — concatenate two
      lists; the `[$0]` shape belongs to `push`).
- [x] **F2.Array.prepend** — `[$0 | $self]` annotation; switch arm deleted
- [x] **F2.Array.push** — `($self ++ [$0])` annotation; switch arm deleted
- [x] **F2.Array.contains** — `lists:member($0, $self)`; switch arm deleted
- [x] **F2.Array.indexOf** — single-line inline-fun template; switch arm deleted
- [ ] **F2.Array.{len,length,size}** — pending: `length` is a `val`
      (property) in primitives.d.bp, not a `fn`; the
      `collectIfaceErlangDispatch` collector only iterates
      `iface.methods`. Needs val-property support OR explicit
      `fn length() -> i32` / `fn len()` / `fn size()` declarations.
- [x] **F2.Array.isEmpty** — `($self =:= [])`; switch arm deleted
- [ ] **F2.Array.slice** — arity branch (1 vs 2 args) — deferred
- [ ] **F2.Array.join** — embedded `"~p"` inside template needs `"""…"""` — deferred
- [x] **F2.Array.at** — single-line inline-fun + bounds check template; switch arm deleted
- [ ] **F2.String.slice** — arity branch — deferred
- [x] **F2.String.contains** — `(string:find($self, $0) =/= nomatch)`; switch arm deleted
- [x] **F2.String.startsWith** — `(string:prefix($self, $0) =/= nomatch)`; switch arm deleted
- [x] **F2.String.split** — `string:split($self, $0, all)`; switch arm deleted
- [x] **F2.Bool.negate** — `(not $self)`; switch arm deleted
- [ ] **F2 verification** — `git grep 'if (eq(u8, callee,'
      codegen/erlang.zig` now finds 4 surviving Array arms
      (`length/len/size`, `slice`, `join`) waiting on the deferred
      grammar features (arity branch, `"""…"""` raw strings, val-property
      bridge) + the final `// Unmapped` fallback. `beam_asm.zig` and
      `commonJS.zig` are NOT yet migrated (the latter never had per-callee
      arms for these — its JS-method renames already cover most).

## F2-R — migrate Family 2 (`emitResultOptionOp`)
- [ ] **F2-R.1** — Convert `@Result` / `@Option` doc-comment method block
      (lines 44–88) in `builtins.d.bp` into real `fn` decls with full
      per-backend `#[@external]` sets.
- [ ] **F2-R.2** — In `comptime/{infer,transform}.zig`, the emission
      path for `@Result`/`@Option` methods looks up the annotation set
      on the receiver's enum (not the synthetic `__bp_*` name) and feeds
      it to the shared renderer.
- [ ] **F2-R.3** — Delete `emitResultOptionOp` (or stub to delegating
      call) in `erlang.zig`, `beam_asm.zig`, `wat.zig`, `commonJS.zig`.
- [ ] One commit per synthetic callee: `refactor(codegen): drive
      @Result.<op> from annotation` (9 commits).

## F2-B — migrate Family 3 (`@todo` / `@panic` / `@block`)
- [ ] **F2-B.todo** — `fn todo() noreturn` decl in `builtins.d.bp` gains
      full `#[@external]` set; switch arms deleted.
- [ ] **F2-B.panic** — `panic(message: string) noreturn` decl gains
      annotation set; switch arms deleted. `@print` already covered.
- [ ] **F2-B.block** — coordinate with Frente A §U: if §U deletes
      `block`, this row drops. Otherwise annotation set + switch deletion.

## F2-X — verify `runtime.zig` + `typescript.zig` out-of-scope
- [ ] `runtime.zig`: confirm no callee-keyed switches (all `mem.eql`
      hits are on module / target / shell-arg strings).
- [ ] `typescript.zig`: confirm no `mem.eql(callee, …)` switches.
- [ ] `codegen/AGENTS.md` §"Annotation-driven lowering" gains a note
      that `runtime.zig` is host-side and `typescript.zig` emits decls
      only — both out of scope.

## F3 — diagnostics + tests
- [ ] Reserve RP1–RP5 in `comptime/diagnostics.zig`:
      - **RP1** `prim-op-arg-index-out-of-range`
      - **RP2** `prim-op-no-arity-match`
      - **RP3** `prim-op-stringify-unsupported` (wat)
      - **RP4** `prim-op-argc-only-in-when`
      - **RP5** target-language passthrough (documented escape hatch)
- [ ] `tests/codegen/prim_op_templates.zig`:
      - [ ] Valid: every migration row renders correctly per F2.
      - [ ] Invalid: each RP-code reds with the expected text.
      - [ ] Multi-line: an inline-fun template preserves whitespace and
            substitutes correctly.
      - [ ] Arity branch: 1-arg call selects the 1-arg `when`; 2-arg
            selects the 2-arg `when`; 3-arg reds with RP2.

## F4 — docs
- [ ] `libs/std/AGENTS.md` §"External annotation vocabulary" — new
      "Template grammar" subsection with marker table + arity-branch
      syntax + `"""…"""` form.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — per-target
      `$stringify` expansion table.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md` — document
      `comptime/primOpTemplate.zig` as the shared renderer.
- [ ] `CHANGELOG.md` under v0.beta.19:
      `feat(stdlib): primitive-method lowering driven entirely by annotations; no more hardcoded switches.`

---

## Done gate

- [ ] F0–F4 all ticked. Current: F0/F1 partial, F2 erlang partial,
      F2-R/F2-B/F2-X/F3 pending, F4 partial (codegen+comptime AGENTS.md
      updated; libs/std/AGENTS.md docs not yet refreshed).
- [x] `zig build test` green at every commit on this branch.
- [x] `zig build test-libs` matches baseline failure set (no
      regressions introduced — same pre-existing jhonstart erlang
      badarith, hooks Counter, rakun decorator emit issues).
- [x] Snapshot diff against pre-F2 HEAD: **empty for codegen**. LSP
      `completion_bool_methods` and `completion_array_methods` snapshots
      updated to reflect the new annotations being visible in completion
      detail — desired behavioural change, not codegen drift.
- [ ] `git grep 'if (eq(u8, callee,'
      modules/compiler-core/src/codegen/erlang.zig` — currently 4
      surviving Array arms (`length/len/size`, `slice` arity branch,
      `join` quoted-string template, `at` is DONE). `beam_asm.zig` /
      `commonJS.zig` / `wat.zig` not yet migrated.
- [x] Every touched `AGENTS.md` updated in the same commit as the
      code (codegen/AGENTS.md erlang row; comptime/AGENTS.md tree +
      file table both for the new `primOpTemplate.zig`).
- [x] Commit message convention followed (`feat(comptime+codegen/...)`
      for foundation; `refactor(codegen/erlang): drive <X>.<method>
      from annotation` per migration; `fix(codegen): …` for the
      dispatch + BEAM passthrough fixes; English; no `--no-verify`).

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/prim-op-annotation/`.
- Functions in camelCase (`feedback_camelcase_naming`).
- After each commit, advance to the next checkbox
  (`feedback_continue_after_commit`).
- Byte-identical promise from v12 + §A5 covers F2: if a snapshot drifts,
  **that** is the real bug — not a deprecation issue. Investigate; do
  not lower the bar.
