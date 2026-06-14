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
- [ ] Cross-check `effectAnnotation()` vs `returnType` for each
      `EffectKind.returnWrapper()`.
- [ ] Body walk: `throw` outside fallible-channel effects ⇒ R6;
      `await` outside `#[@future]`/`#[@asyncGenerator]` ⇒ R7; `yield`
      outside `#[@generator]`/`#[@iterator]`/`#[@asyncGenerator]` ⇒ R8.
- [ ] **RG3** — missing required generic arg → `generic-required-arg-missing`.
- [ ] **RG4** — skipped middle generic arg → `generic-arg-skip-forbidden`.

### F4 — `#[@result]` auto-wrap (§1) + R11/R12
- [ ] `comptime/transform.zig` rewrites `return <r>;` inside `#[@result]`
      to `return @Result.Ok(<r>);` AST-level.
- [ ] Same file rewrites `throw <e>;` to `return @Result.Err(<e>);`.
- [ ] **R11/R12** — visiting manual `Result::Ok(…)` / `Result::Err(…)`
      forms inside `#[@result]` body emits the matching diagnostic.

### F4F — `#[@future]` auto-wrap (§1F) + RF1–RF5
- [ ] `transform.zig` rewrites `return <t>;` inside `#[@future]` to
      `return @Future.resolved(<t>);` and `throw <e>;` to
      `return @Future.rejected(<e>);`.
- [ ] **RF1/RF2/RF5** — visiting manual `Future::resolved(…)` /
      `Future::rejected(…)` reds.
- [ ] commonJS lowering: `@Future.resolved` → bare `return <t>;`;
      `@Future.rejected` → `throw <e>;` (inside `async function`).
- [ ] erlang/beam: **gated on Frente A §D-D4** — coordinate at merge.

### F4I — `#[@iterator]` `break <C>` + `yield :label` (§1I) + RI1–RI6
- [ ] `parser/stmts.zig` parses `break;`, `break <expr>;`,
      `break :label [<expr>];` inside `#[@iterator]`/`#[@asyncGenerator]`.
- [ ] `parser/decls.zig` parses trailing `:label` after the return type
      (extend from `#[@generator]` to `#[@iterator]`/`#[@asyncGenerator]`).
- [ ] `transform.zig` rewrites `break <c>;` to
      `return @IteratorStep.Done(<c>);` and `throw <e>;` to
      `return @IteratorStep.Error(<e>);`.
- [ ] **RI1/RI2/RI3/RI4/RI5/RI6** — invalid forms reject with their codes;
      RI6 in particular hard-rejects the legacy `yield break`.

### F4C — `#[@context]` Anchor + `@getContex` (§1C) + RC1–RC6 (R18–R21)
- [ ] `parser/decls.zig` parses `@getContex(T)` intrinsic.
- [ ] `transform.zig` records the Anchor (`Base`) extracted from
      `@Context<Base, T>`; every `use <hook>()` / `use @getContex(<T>)`
      is type-checked against it.
- [ ] **`comptime/contextStack.zig` (new)** — per-compilation-unit map of
      `Type → Provider`, populated by `use`-block entry / exit.
- [ ] **RC1 (E1)** — no active provider ⇒ comptime if statically known;
      runtime trap otherwise.
- [ ] **RC2 (E2)** — hook's `HookBase` not assignable to enclosing Anchor.
- [ ] **RC3/RC4/RC5/RC6** — invalid `@getContex` / `use` forms reject.
- [ ] commonJS lowering: scope-stack as a module-level array; push/pop.
- [ ] erlang/beam lowering: process-dictionary scope.

### F4G — default generic parameters (§1G) + RG1–RG4
- [x] `parser/types.zig` `GenericParamList` accepts `IDENT ("=" TypeRef)?`;
      enforce strict-trailing-position rule at parse time. (7db5de7)
- [ ] `comptime/types.zig` — omitted trailing args resolve to declared
      defaults.
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
- [ ] `generic_defaults.zig` (covers §1G: every RG-code + resolution rules)

### F7 — AGENTS sweep
- [ ] `modules/compiler-core/AGENTS.md` comptime section: pointer to this
      spec under "Effect annotations".
- [ ] `codegen/AGENTS.md` "Effects" subsection with the support matrix.

---

## §E — LSP definition tail
- [ ] **E1** — tuple-field `recv._N` resolves to the Nth element's type
      (`resolveChainType` + a new step for `_<digits>`).
- [ ] **E2** — interface assoc-fn dispatch — `Iface.method(...)` from
      another module jumps to the `default fn` in the interface source.
- [ ] **E3** — note both paths in `modules/language-server/AGENTS.md` +
      `docs.md`; regression tests under `language-server/src/tests/`.

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
