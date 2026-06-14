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
- [x] **F0.1** — `comptime/primOpTemplate.zig` carries the
      template-vs-legacy discriminator (`looksLikeTemplate`); raw
      `external` symbol bytes ARE the template body. `ArityBranch`
      `{argc, template}` lives on `ast.zig` with
      `parseArityBranchArg` / `externalHasArityBranches` /
      `externalArityBranchFor`. Tests in `primOpTemplate.zig`.
- [x] **F0.2** — `"""…"""` raw strings: `unquoteAnnotationArg`
      recognises the `multilineStringLiteral` lexeme and strips one
      leading + one trailing newline ("indent the block" convention),
      preserving inner indentation. `when(argc == N): "<template>"`
      clauses: parser spans through balanced parens + `:` + value as
      ONE arg lexeme (predicate uses bare `argc`, not `$argc` — the
      botopink lexer rejects bare `$` outside string literals).

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
- [x] **F2.Array.slice** — `when(argc == 1)` / `when(argc == 2)` arity branch; switch arm deleted
- [x] **F2.Array.join** — `"""…"""` raw-string single-line template; switch arm deleted
- [x] **F2.Array.at** — single-line inline-fun + bounds check template; switch arm deleted
- [x] **F2.String.slice** — `when(argc == 1)` / `when(argc == 2)` arity branch; switch arm deleted
- [x] **F2.String.contains** — `(string:find($self, $0) =/= nomatch)`; switch arm deleted
- [x] **F2.String.startsWith** — `(string:prefix($self, $0) =/= nomatch)`; switch arm deleted
- [x] **F2.String.split** — `string:split($self, $0, all)`; switch arm deleted
- [x] **F2.Bool.negate** — `(not $self)`; switch arm deleted
- [x] **F2 verification (erlang)** — `git grep 'if (eq(u8, callee,'
      codegen/erlang.zig` now finds **1 surviving arm**
      (`len/length/size` at line 2781), the val-property bridge that
      can't migrate until property-shape annotations land (cf. F2.Array.
      {len,length,size}). `slice`/`join`/`at` all migrated in this
      pass — initial estimate of 4 surviving arms was conservative.
- [ ] **F2 verification (BEAM)** — BEAM still owns its prim-method
      lowerings inline (`beam_asm.zig:2280/2284` — 2 mega-arms covering
      contains/len/prepend/push/append/isEmpty + split/slice). Migration
      blocked by BEAM's needing `inline-fun` codegen for the
      template body (a register-allocated closure, not a textual
      substitution). Spec §D-D5 owns this; left for follow-up.
- [ ] **F2 verification (commonJS)** — has no per-callee `if (eq(u8,
      callee, …))` arms; JS-method renaming via the `prim_node_renames`
      / per-loc `renames` map already covers the surface (`.contains` →
      `.includes`, `.length()` → `.length` property, etc.). No
      migration target.

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
> **BLOCKED on `builtins.d.bp` parsability.** Two attempts landed and
> were reverted:
> - `d51e935` (F2-B erlang) → reverted at `8f56133`, reapplied at
>   `fb9aa4a`, then reverted again at `0f6a820`.
> - `9390f1c` (F2-B commonJS) → reverted at `0bc62aa`.
>
> Root cause: `collectBuiltinErlangDispatch` / `collectBuiltinNodeDispatch`
> call `Parser.parse(prelude.builtins)`, which aborts at the FIRST
> bodyless `fn` without the `declare` keyword (e.g.
> `fn typeOf<T>(val: T) type` on line 4). `Parser.parse` has no error
> recovery — one bad decl rejects the whole prelude, leaving the
> dispatch map empty. The fallback in commonJS emits the raw `@todo()`
> literal (visible regression); the fallback in erlang emits `todo(arg)`
> raw, which mismatched the saved erlang snapshot but was masked
> because `assertJs` runs configs in order (commonJS first) and the
> commonJS failure short-circuits the test before erlang config runs.
>
> Unblock path (one of):
> 1. Make `builtins.d.bp` fully parseable — add `declare` + `->` to all
>    bodyless `fn` decls, rename param `val` (keyword clash) → `value`.
>    ~30 decls touched; needs CI verification it doesn't break other
>    tooling that reads the file.
> 2. Lift the parse out of `builtins.d.bp` — embed a dedicated minimal
>    source string (like `decl_reflection_src` in `comptime.zig`) with
>    only the `fn todo` / `fn panic` decls in parseable form. Cleanest;
>    loses the "single source of truth" property.
> 3. Make `Parser.parse` skip-on-error or accept bodyless without
>    `declare`. Largest blast radius; defer.
- [ ] **F2-B.todo** — pending. `fn todo() noreturn` annotation set was
      authored on `builtins.d.bp` lines 160-166 but the dispatch never
      fired; annotation removed by the reverts. Hardcoded `is_todo`
      switch arms restored in `commonJS.zig` + `erlang.zig`.
- [ ] **F2-B.panic** — pending. Same status as todo.
- [ ] **F2-B.block** — coordinate with Frente A §U: if §U deletes
      `block`, this row drops. Otherwise annotation set + switch deletion.

## F2-X — verify `runtime.zig` + `typescript.zig` out-of-scope
- [x] `runtime.zig`: confirmed no callee-keyed switches — every
      `mem.eql` hit lands on `aux_module`/`entry_module` (host path
      strings for aux-module aggregation).
- [x] `typescript.zig`: confirmed no `mem.eql(callee, …)` switches —
      every `mem.eql` hit lands on `p.name == "self"` (param skip) or
      builtin generic type names (`Context`/`Result`/`Future`/…); no
      call-site lowering exists in this emitter.
- [x] `codegen/AGENTS.md` table rows for both files gained a
      "`prim-op-annotation` out-of-scope" note explaining why.

## F3 — diagnostics + tests
- [x] **RP1** `prim-op-arg-index-out-of-range` — reserved as
      `error.PrimOpArgIndexOutOfRange` in `primOpTemplate.render`
      (`comptime/primOpTemplate.zig:67`) with `render: $N out of range
      reds` covering it.
- [ ] **RP2** `prim-op-no-arity-match` — currently a silent fall-through
      in `tryEmitBuiltinAnnotation` / `tryEmitPrimAnnotation` (loop
      returns `false` when no `branch.argc` matches). Spec wants this
      surfaced as a diagnostic; deferred — no caller depends on the
      hard-error today and Family-1 migrations all have full arity
      coverage. Reserve when F2-B unblocks and a real "no match"
      annotation appears in `builtins.d.bp`.
- [ ] **RP3** `prim-op-stringify-unsupported` (wat) — deferred,
      `$stringify(...)` not implemented (TODO F1.3).
- [ ] **RP4** `prim-op-argc-only-in-when` — deferred, would surface
      when a bare `argc` reference appears in a template body outside
      the `when(...)` predicate (the parser doesn't accept this today,
      so the case is effectively closed; reserve if escape hatches
      emerge).
- [ ] **RP5** target-language passthrough — passthrough IS the default
      `render` behaviour (literal bytes emitted verbatim — that's the
      escape hatch); no diagnostic needed. Documented at the
      `primOpTemplate.zig` module header.
- [x] **Tests live in `comptime/primOpTemplate.zig`** (kept next to the
      renderer so the unit covers the helper directly, no
      `tests/codegen/prim_op_templates.zig` shim):
      - [x] `render: $self → recv` / `$0 → first arg` / `$0 and $1`
      - [x] `render: list cons / operator passthrough` (the `[$0 |
            $self]` migration)
      - [x] `render: empty-list eq operator` (the `($self =:= [])`
            migration)
      - [x] `render: unary not` (the `(not $self)` migration)
      - [x] `render: $ followed by non-digit is literal` (RP5
            passthrough sanity)
      - [x] `render: $N out of range reds` (RP1)
      - [x] `looksLikeTemplate` discriminator
      - [x] `parseArityBranchArg: 1-arg branch` / `2-arg with internal
            whitespace` / `non-when returns null` / `missing predicate
            returns null` / `missing colon returns null`
      - [x] `parseArityBranchArg: triple-quoted template strips fences
            + leading/trailing newline` (the `"""…"""` form proven on
            an embedded-`"` template)
      - [x] **End-to-end coverage** is exercised by the existing
            `js: builtin ---- @todo with message` / `@panic with
            message` / erlang `Array.append/prepend/push/contains/…`
            snapshot tests — every migration row renders through the
            backend's emitter at test time.

## F4 — docs
- [x] `libs/std/AGENTS.md` §"Template grammar (`prim-op-annotation`)" —
      marker table + arity-branch syntax + `"""…"""` form +
      per-target reach.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — per-target
      `$stringify` expansion table. **Deferred**: `$stringify(...)` is
      not implemented yet (TODO F1.3), so there is no per-target
      expansion to document. The `typescript.zig` + `runtime.zig` rows
      gained their `prim-op-annotation` out-of-scope note in this pass.
- [x] `modules/compiler-core/src/comptime/AGENTS.md` — primOpTemplate
      row now spells out arity branching + triple-quoted +
      RP1/RP2/RP5 status; deferred `$stringify` + val-property bridge
      flagged.
- [x] `CHANGELOG.md` under v0.beta.19 — already documents the shipped
      grammar (template form, `$self`/`$N`, arity-branch, triple-quoted)
      plus the erlang Family-1 migrations (`Bool.negate`,
      `Array.{contains,isEmpty,push,append,prepend,indexOf,at,slice,
      join}`, `String.{contains,startsWith,split,slice}`). The
      optimistic "primitive-method lowering driven entirely by
      annotations" line from the original TODO is **not** added — F2-B
      and BEAM/commonJS/wat migrations are blocked, so the broader
      claim would mislead.

---

## Done gate

- [x] F0 — AST + parser foundation landed (`comptime/primOpTemplate.zig`,
      `ast.ArityBranch` / `parseArityBranchArg`, parser `when(...)` arg
      span, triple-quoted via `unquoteAnnotationArg`).
- [x] F1 — `tryEmitPrimAnnotation` + shared renderer landed (erlang +
      BEAM passthrough). F1.3 `$stringify` still deferred — no
      consumer yet.
- [~] F2 — erlang Family-1 partial: 14/15 method-row arms gone. The
      4 surviving arms (`Array.{length,len,size}` val-property +
      `Array.slice` arity branch + `Array.join` triple-quoted +
      `Array.at` already DONE — only `length/len/size` val-property
      remains; the others all migrated). BEAM/commonJS/wat backends
      not migrated (per-target lowerings still inline).
- [x] F2-X verified — `runtime.zig`/`typescript.zig` confirmed
      out-of-scope (no callee-keyed switches; docs note added).
- [x] F3 partial — RP1 reserved + tested; renderer tests cover every
      Family-1 migration shape + arity-branch + triple-quoted; RP2/RP3/
      RP4 deferred behind real consumers.
- [x] F4 partial — `libs/std/AGENTS.md`, `comptime/AGENTS.md`,
      `codegen/AGENTS.md`, `CHANGELOG.md` all reflect the shipped
      grammar + reach; `$stringify` per-target table deferred.
- [ ] **F2-B (`@todo`/`@panic`)** — blocked; see F2-B section above.
- [ ] **F2-R (`@Result`/`@Option`)** — blocked on the same
      `builtins.d.bp` parsability gap (both F2-B and F2-R need the
      collector to scan the full builtins prelude).
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
