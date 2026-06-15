# TODO — frente-b-rules-tooling (v0.beta.19)

> Branch: `task/frente-b-rules-tooling` · Worktree: `.tasks/frente-b-rules-tooling/`
> Spec: [`tasks/v0.beta.19/specs/frente-b-rules-tooling.md`](tasks/v0.beta.19/specs/frente-b-rules-tooling.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Tracks (four file-disjoint surfaces)

| Track | Description |
|---|---|
| **Rules** §0–§4 | authoritative ruleset for the six `#[@<effect>]` markers + §1G default generics |
| **§E** | LSP definition tail (tuple `recv._N` + interface assoc dispatch) |
| **§F** | TS `.d.ts` template skip (drop `@Expr<…>` / `@ExprCustom<…>` returns) |
| **§T** | test-run-log (`----- RUN LOG -----` fence per test, all 4 backends) |

The Rules track has internal sequencing; §E/§F/§T are parallel.

## Coordination

- **Frente A §D-D4 (`#[@future]` erlang/beam) reads this frente's §1F.**
  Land Rules §1F first so Frente A can consume the contract.
- **§T's wasm backend depends on Frente A §C2** (wires
  `botopink test --target wasm`). §T's commonJS/erlang/beam shipping
  doesn't block on §C2; the wat path turns green later.

---

## Rules track — §0 → §1 → §1F → §1I → §1C → §1G → §2 → §3 → §4 → Steps F0–F7

### F0 — write the spec + lock the contract
- [x] Spec authored in `tasks/v0.beta.19/specs/frente-b-rules-tooling.md`
      (ce7afe6). Immutable now.

### F1 — diagnostic-code table
- [x] Reserve stable codes R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4
      in `modules/compiler-core/src/comptime/diagnostics.zig` (or
      equivalent). Existing diagnostics keep their text; new ones are
      net-new. (cb28f06 — `comptime/diagnostics.zig` reserves every
      code as a stable string constant; the catalogue is the contract.)

### F2 — parser rejections (R1, R2, R5, RG1)
- [x] **R1** — `#[@<effect>] declare fn …` reds with
      `effect-on-declare-forbidden`. (461b681 — parser path)
- [x] **R2** — `interface I { #[@<effect>] fn … }` reds with
      `effect-on-interface-method-forbidden`. (461b681)
- [x] **R5** — duplicate effect annotation reds with
      `effect-duplicate-annotation`. (461b681)
- [x] **RG1** — generic-default-before-required rejection at every
      `GenericParamList` site (struct, fn, enum, interface, TypeRef).
      (7db5de7 — `parseGenericParams` enforces strict-trailing.)

### F3 — comptime cross-checks (R3, R4, R6, R7, R8, R9, R10, RG3, RG4)
- [x] Cross-check `effectAnnotation()` vs `returnType` for each
      `EffectKind.returnWrapper()`. (34ae1af — R3/R4 codes on the
      existing check; discriminator picks the missing-wrapper vs
      mismatch case.)
- [x] Body walk — partial: R7 / R8 / RI4 already fire from the existing
      starFn/labelStack infrastructure, now carry stable codes
      (34ae1af). R6 extended (f619737) — `throw` inside
      `#[@future]` / `#[@iterator]` / `#[@asyncGenerator]` is no
      longer red; `#[@generator]` / `#[@context]` / plain fn keep the
      `effect-throw-without-fallible-channel` reject text.
- [x] **RG3** — missing required generic arg → `generic-required-arg-missing`.
      (`builtinRequiredGenericArgs` in `comptime/infer.zig` fires on
      `@Future<>` / `@Iterator<>` / `@Result<i32>` etc.)
- [x] **RG4** — skipped middle generic arg → `generic-arg-skip-forbidden`.
      (`parser/types.zig` detects the `,,` / `,>` slot at parse time,
      `ParseErrorType.genericArgSkipForbidden`.)

### F4 — `#[@result]` auto-wrap (§1) + R11/R12
- [x] `comptime/transform.zig` rewrites `return <r>;` inside `#[@result]`
      to `return @Result.Ok(<r>);` AST-level. (Already wired —
      `infer.zig` populates `env.result_jump_lowerings.put(loc, .wrap_ok)`
      at the return site; transform consumes it to emit `__bp_ok(<r>)`.)
- [x] Same file rewrites `throw <e>;` to `return @Result.Err(<e>);`.
      (`env.result_jump_lowerings.put(loc, .wrap_error)` at the throw
      site; `__bp_error(<e>)` lowering in transform.)
- [x] **R11/R12** — visiting manual `Result::Ok(…)` / `Result::Err(…)`
      forms inside `#[@result]` body emits the matching diagnostic.
      (`resultVariantCallName` in `comptime/infer.zig`; R11 +
      `throw-must-be-bare-E` fire at the jump site, R12 fires at any
      other call site.)

### F4F — `#[@future]` auto-wrap (§1F) + RF1–RF5
- [ ] `transform.zig` rewrites `return <t>;` inside `#[@future]` to
      `return @Future.resolved(<t>);` and `throw <e>;` to
      `return @Future.rejected(<e>);`. (Deferred — JS `async function`
      already wraps native; erlang/beam process-spawn handled by
      Frente A §D-D4. Manual wrappings already rejected; the
      transform-level rewrite is a pure renaming with no observable
      output today.)
- [x] **RF1/RF2/RF5** — visiting manual `Future.resolved(…)` /
      `Future.rejected(…)` reds. (`futureConstructorCallName` in
      `comptime/infer.zig`; `StarFnCtx.effect` field added so
      `inEffectContext(env, .future)` distinguishes future from
      iterator/asyncGenerator/generator contexts.)
- [ ] commonJS lowering: `@Future.resolved` → bare `return <t>;`;
      `@Future.rejected` → `throw <e>;` (inside `async function`).
      (Untouched — the bare `return <t>;` already lowers to a resolved
      Promise via JS's native `async function`; `throw <e>;` already
      rejects. Only the AST-level explicit-wrap form would need the
      lowering, and the contract rejects authoring it.)
- [ ] erlang/beam: **gated on Frente A §D-D4** — coordinate at merge.

### F4I — `#[@iterator]` `break <C>` + `yield :label` (§1I) + RI1–RI6
- [x] `parser/exprs.zig` parses `break :label [<expr>];` inside
      `#[@iterator]`/`#[@asyncGenerator]` — widened the Jump AST
      `.@"break"` variant from `?*ExprOf(phase)` to
      `{label: ?[]const u8, value: ?*ExprOf(phase)}` (mirrors `.yield`),
      updated all 4 codegen backends + comptime transform/specialize/
      error/runtime + format printer.
- [x] `parser/decls.zig` parses trailing `:label` after the return type
      (already effect-agnostic; the comment was misleading and now spells
      out §1I's iterator/asyncGenerator coverage explicitly).
- [ ] `transform.zig` rewrites `break <c>;` to
      `return @IteratorStep.Done(<c>);` and `throw <e>;` to
      `return @IteratorStep.Error(<e>);`. (Deferred — `@IteratorStep` enum
      itself still needs the F5 builtins.d.bp migration; landing this
      ahead of the consumer migration would crash codegen.)
- [x] **RI1** — `return <expr>;` inside `#[@iterator]` /
      `#[@asyncGenerator]` reds with `iterator-return-forbidden`.
- [x] **RI2** — `break <expr>;` whose value type does not unify with the
      declared `C` reds with `iterator-break-type-mismatch`. Fires only
      when the break targets the iterator (top-level or fn-labelled).
- [x] **RI3** — `break <expr>;` inside an iterator whose `C` defaults to
      `void` reds with `iterator-break-without-completion-type`. Same
      scoping rule as RI2.
- [x] **RI5** — `break :label <expr>` whose label isn't on `env.labelStack`
      reds with `break-label-unbound`. Mirrors RI4's `yield :label`
      machinery.
- [x] **RI4** — already covered by `yield-label-unbound` in
      `comptime/infer.zig` (34ae1af).
- [x] **RI6** — parser hard-rejects the legacy `yield break <expr>` /
      `yield break` form with `yield-break-removed` (32883c9).

### F4C — `#[@context]` Anchor + `@getContex` (§1C) + RC1–RC6 (R18–R21)
- [x] `@getContex(T)` parses as a builtin call (the existing `@`-prefix
      `.builtinIdent` lexer path handles it; no new parser surface).
- [ ] `transform.zig` records the Anchor (`Base`) extracted from
      `@Context<Base, T>`; every `use <hook>()` / `use @getContex(<T>)`
      is type-checked against it. (Partial — `validateUseBase` /
      `contextBaseOfType` already cover the `use <hook>` path; the
      `@getContex` Anchor-tree check pends RC3.)
- [ ] **`comptime/contextStack.zig` (new)** — per-compilation-unit map of
      `Type → Provider`, populated by `use`-block entry / exit.
- [ ] **RC1 (E1)** — no active provider ⇒ comptime if statically known;
      runtime trap otherwise. (Needs contextStack.)
- [x] **RC2 (E2)** — `use <hook>()` whose HookBase ≠ enclosing Anchor reds
      with `context-anchor-violation:` (pre-existing `contextMismatch`
      check now carries the §2 code prefix).
- [ ] **RC3** — `@getContex(T)` outside Anchor tree reds with
      `context-getcontex-anchor-violation`. (Needs Anchor extraction from
      `@Context<Base, T>` on the fn signature; pends with contextStack.)
- [x] **RC4** — `@getContex(<value>)` reds with
      `context-getcontex-expects-type` (the typed arg must be an
      identifier whose name resolves via `env.lookupTypeDef`).
- [x] **RC5** — `@getContex(…)` outside a `#[@context]` fn body reds with
      `context-getcontex-outside-context-fn` (`env.inContextFn` flag
      saved/restored around the body in `inferFnBody`).
- [x] **RC6** — `use <hook>()` where `<hook>` is not a `#[@context]` fn
      reds with `use-of-non-context-fn:` (pre-existing `useNotContext` /
      `useNotAllowed` checks now carry the §2 code prefix).
- [ ] commonJS lowering: scope-stack as a module-level array; push/pop.
- [ ] erlang/beam lowering: process-dictionary scope.

### F4G — default generic parameters (§1G) + RG1–RG4
- [x] `parser/types.zig` `GenericParamList` accepts `IDENT ("=" TypeRef)?`;
      enforce strict-trailing-position rule at parse time. (7db5de7)
- [x] `comptime/types.zig` — omitted trailing args resolve to declared
      defaults. (Builtins-only: `builtinDefaultFilledArgs` in
      `comptime/infer.zig` fills `@Future<T>` ⇒ `<T, any>`,
      `@Iterator<T>` ⇒ `<T, any, void>`, `@Iterator<T, E>` ⇒
      `<T, E, void>`, `@Generator<T>` ⇒ `<T, void>`. User-typeDef
      defaults need `TypeDef.Record/Struct/Enum.genericDefaults` plus
      threading through `registerTypeDef` call sites — separate
      follow-up; not blocking F6 / §T.)
- [ ] Update consumers (struct, fn, enum, interface) to thread
      default-typed params through codegen.

### F5 — `builtins.d.bp` mirror (§4)
- [x] Rewrite the `§ effect annotations` block per §4 (the §1 + §1F +
      §1I + §1C + §1G summaries land here). (ae32095)
- [x] Update `pub interface Future<T, E = any>` declaration. (ae32095 —
      requires `any` primitive, added in `comptime/env.zig`.)
- [ ] Update `pub interface Iterator<T, E = any, C = void>` declaration
      + new `pub enum IteratorStep<T, E, C>`. (Deferred until libs
      `next() -> ?T` consumers migrate atomically.)
- [x] Add `@getContex` intrinsic declaration. (ae32095 — comptime/
      parser side of the intrinsic still gated on F4C.)
- [x] Add `libs/std/AGENTS.md` link to the spec under "Effect annotations".
      (ae32095)

### F6 — snapshot suites
- [ ] `effect_result.zig`
- [ ] `effect_future.zig` (covers §1F + `fetchUser` example)
- [ ] `effect_generator.zig`
- [ ] `effect_iterator.zig` (covers §1I `yield :label` + `break <C>` +
      `lazyMap` example)
- [ ] `effect_asyncGenerator.zig` (gated on Frente A §D-D4)
- [ ] `effect_context.zig` (covers §1C Anchor + `@getContex`)
- [x] `generic_defaults.zig` (covers §1G: every RG-code + resolution rules)
      — partial: RG1/RG2/RG3/RG4 all asserted; resolution rules
      (`Future<User>` ⇒ `E = any` etc.) deferred until F4G compile-side
      lands. Lives in `comptime/tests/generic_defaults.zig`.

### F7 — AGENTS sweep
- [x] `modules/compiler-core/AGENTS.md` comptime section: pointer to this
      spec under "Effect annotations". (Landed in
      `src/comptime/AGENTS.md` "Effect annotations" — the module-level
      AGENTS.md is a Tree/Children index; the comptime-level one is the
      runtime-behaviour doc that gets the spec link.)
- [x] `codegen/AGENTS.md` "Effects" subsection with the support matrix.
      (New "Effects (`#[@<effect>]`)" section with a per-backend matrix
      for the six markers, plus rejection-codes paragraph and the
      `StarFnCtx.effect` ↔ `inEffectContext` thread.)

---

## §E — LSP definition tail
- [x] **E1** — tuple-field `recv._N` resolves to the Nth element's type.
      `ReceiverType` gained a `.tuple: []*T.Type` variant carrying the
      element types; `resolveHead` populates it from a binding whose
      deref'd type is `.named "tuple"`; `stepField` adds the `_<digits>`
      arm that picks element `N` (via `tupleMemberIndex`) and lifts it
      back through `receiverFromType`. A request directly on `_N`
      returns null (no source-declared name); a chained `t._0.field`
      lands on `field`'s decl on element 0's record. Exposes
      `compiler-core`'s `types` module via `bp.types` for the LSP.
- [x] **E2** — interface assoc-fn dispatch: `Iface.method(...)` (head is an
      interface name, not a value binding) routes through a new
      `findInterfaceMethodAcross` that scans the active file + project graph
      for `interface <head> { … }` and returns the inner `default fn` /
      `declare fn` location. Cross-module reach gated on `pub interface`.
- [x] **E3** — `language-server/AGENTS.md` + `docs.md` document both §E E1
      and §E E2 paths; regression tests under `tests/definition.zig`
      (`definition: tuple element chain …` + `definition: interface
      assoc-fn cross-module …`).

## §F — typescript `.d.ts` template skip
- [x] **F1** — `typescript.zig` decl emitter skips any fn whose return
      type starts with `@Expr<` / `@ExprCustom<` / is `@expr` / `@code`.
      (Done via `TypeRef.isTemplateReturnType()` on free fns, struct
      methods, record methods, and interface methods — e3104e2.)
- [x] **F2** — remove KNOWN GAP note in `codegen/AGENTS.md`; add
      `.d.ts` snapshot asserting no `Expr<>` shows up.
      (Note rewritten to mirror the drop; new
      `codegen/tests/dts_skips_templates.zig` asserts no `Expr<` /
      `ExprCustom<` leaks — e3104e2.)

## §T — test-run-log
- [ ] **T0** — `runtime.zig.captureStdout(...)` primitive. Each
      `execute*` path returns `(exit_code, stdout_bytes)`.
- [ ] **T1** — per-backend test-mode codegen wraps each test body and
      emits the `TEST <file>:<line> <name>\n----- RUN LOG -----\n` +
      fenced ```logs``` block:
      - [ ] commonJS
      - [ ] erlang
      - [ ] beam_asm
      - [ ] wat (gated on Frente A §C2)
- [ ] **T2** — `test_cmd.zig` parses sentinels; renders per "Target
      format"; adds `--json` mode emitting per-test
      `{file,line,name,status,duration_ms,run_log}` records.
- [ ] **T3** — `lib-test-runner` `report.zig` lib-prefixes lines;
      `--json` records carry `lib` field.
- [ ] **T4** — `tests/cli/test_run_log_format.zig` (pass/fail/empty/
      multi-test on each backend); `tests/cli/test_run_log_json.zig`
      (schema check); snapshots under `snapshots/cli/test/`.
- [ ] **T5** — docs:
      `modules/compiler-cli/AGENTS.md` "Test output format" subsection,
      `modules/lib-test-runner/AGENTS.md` lib-prefixed mirror,
      `libs/std/AGENTS.md` "test blocks" paragraph,
      `modules/compiler-core/AGENTS.md` codegen section link.

---

## Done gate (whole frente)

- [ ] Rules track F1–F7 ticked above
- [ ] §E/§F/§T checklists ticked above
- [ ] R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4 all defined +
      fire correctly under tests
- [ ] `libs/std/src/builtins.d.bp` `§ effect annotations` block matches §4
      verbatim
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` green
- [ ] every touched AGENTS.md updated in the same commit as the code

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/frente-b-rules-tooling/`.
- Functions in camelCase (`feedback_camelcase_naming`).
- Implement in `.bp` when possible (`feedback_prefer_bp_over_dbp`).
- After each commit, advance to the next checkbox (`feedback_continue_after_commit`).
- The bilingual §1/§1F/§1I/§1C addendum blocks are the **only**
  Portuguese surface — preserve them verbatim (the user's hand-supplied
  rulesets, zero translation drift); everything else stays English.
