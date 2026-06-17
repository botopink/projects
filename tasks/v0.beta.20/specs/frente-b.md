# frente-b — rules + tooling close (closes v0.beta.19 `frente-b-rules-tooling` partial)

**Slug**: frente-b
**Depends on**: v0.beta.19 `frente-b-rules-tooling` partial — Rules F0–F3 + R1/R2/R5/RG1 + R3/R4/R6/R7/R8/R9/R10/RG3/RG4 already landed; F4F/F4G/F4C/F4I/F5/F6 + §T pending.
**Files**: see each sub-spec — `comptime/{infer,transform,contextStack}.zig` · `codegen/{erlang,beam_asm,commonJS,wat}.zig` · `runtime/runlog.zig` (new) · test-mode codegen wrappers.
**Touches docs**: `modules/compiler-core/src/comptime/AGENTS.md` · `tasks/v0.beta.19/status.md` (frente-b row → done).
**Status**: **partial in-progress + F4I-tail WIP shipped** — bot-lang `feat` at `ffe7aff` (meta `b1324d8`). Session 2 (df14ef3) already landed F5 atomic + test-run-log T0-T5 + F6-T1/T2/T3 + F4G/F4F/F4C-RC3 + fn-param-default-expansion AST plumbing. **2026-06-16 session** adds **F4I-tail WIP** (`c982097` in bot-lang task/frente-b, merged forward to ffe7aff): `env.IteratorJumpLowering` enum (wrap_done / wrap_done_void / wrap_error) + `env.iterator_jump_lowerings` map keyed by jump loc + `inferJumpExpr` arm populating the map when inside `#[@iterator]`/`#[@asyncGenerator]` for `throw <e>` (and previously for `break <c>`, partially). **Remaining**: F4I-T2/T3 (`transform.zig → @IteratorStep` rewrite that consumes the map); F5 atomic Iterator enum migration finish; F6 effect_*.zig suites cross-pollination; `codegen-break-label` consumer (depends on F4I-T2/T3); `test-run-log` consumer.

## Current state (partials landed on origin/feat — bot-lang 0568466)

| Sub-spec | Landed | Remaining |
|---|---|---|
| **rules-tooling-close** | §1G generic-param defaults wired into TypeDef + infer (`3ed957c`) · F4I Jump.@"break" widened from `?*Expr` to `{label, value}` struct + 4 call sites in commonJS/erlang updated to read `.value` accessor (`a9f1a6d`) + RI1–RI6 + RC4/RC5/RC6 + RG3 diagnostics snapshots · `comptime/tests/generic_defaults.zig` | F4F (`#[@future]` RF3/RF4) · F4G (default generics gates beyond §1G) · F4C (context body validation) · F4I tail (T2/T3 `@IteratorStep` transform rewrite) · F5 builtins.d.bp Iterator enum · F6 effect suites cross-pollination · **`fn-param-default-expansion` for `declare fn`**: parser does NOT yet accept `param: type = expr` in `declare fn` signatures — blocked path that prim-op/ci-tail catalogs need (currently every BIF arity overload is a separate decl in `libs/std/src/erlang.bp`) |
| **test-run-log** | — | §T `----- RUN LOG -----` per test on 4 backends (net-new tooling) |
| **codegen-break-label** | — | `break :label` honors label on 4 backends (consumes F4I-T2/T3) |

## DAG

```
01-keystones (2, parallel)
  rules-tooling-close  (F4F/F4G/F4C/F4I/F5/F6 closure)
  test-run-log         (§T `----- RUN LOG -----` per test, net-new tooling)

02-consumers
  codegen-break-label  ← rules-tooling-close (F4I-T2/T3 transform rewrite)
```

---


---

## rules-tooling-close — F4F/F4G/F4C/F4I/F5/F6 closure

**Slug**: rules-tooling-close
**Depends on**: `v0.beta.19/specs/frente-b-rules-tooling.md` (the umbrella
  this closes)
**Status**: pending

### Reanalysis (snapshot at spec-authoring time)

End of session 2026-06-15, on `task/frente-b-rules-tooling` (meta +
bot-lang both pushed, 5 secondary submodules paritárias com
`origin/feat`). What the v0.beta.19 umbrella actually shipped:

| Surface | State | Notes |
|---|---|---|
| Rules F0/F1/F2/F3 | ✅ | catalogue + parser rejections (R1/R2/R5/RG1) + comptime cross-checks (R3/R4/R6/R7/R8/R9/R10/RG3/RG4) |
| Rules F4 (`#[@result]`) | ✅ | auto-wrap + R11/R12 |
| Rules F4F (`#[@future]`) | 🟡 | RF1/RF2/RF5 done; transform-rewrite + commonJS lowering deferred (identity-lowering today); erlang/beam **gated on Frente A §D-D4** (out of scope here) |
| Rules F4I (`#[@iterator]`) | ✅ | RI1–RI6 firing + Jump AST `.@"break"` widened + `break :label` parser + `StarFnCtx.{iterCompletion,fnLabel}` + `Env.loopDepth`. `transform.zig → @IteratorStep` pends F5-tail |
| Rules F4C (`#[@context]`) | 🟡 | RC2/RC4/RC5/RC6 firing with §2 code prefixes. RC1/RC3 + `contextStack.zig` + lowerings pend — **biggest chunk here** |
| Rules F4G (builtin defaults) | 🟡 | builtin wrappers fill (`@Future<T>` ⇒ `<T,any>` etc.). User-typeDef defaults consumer-threading WIP at session end (TypeDef extension + register-pass + resolve-time fill — see F4G-tail) |
| Rules F5 (`builtins.d.bp` §4) | 🟡 | `Future<T, E = any>` + `@getContex` declarations landed; `Iterator<T,E,C>` + `IteratorStep<T,E,C>` enum pend (atomic libs migration of every `next() -> ?T` consumer) |
| Rules F6 (snapshot suites) | 🟡 | `generic_defaults.zig` partial; the 5 effect_*.zig suites pend |
| Rules F7 (AGENTS sweep) | ✅ | spec link + effects matrix landed |

#### Findings worth highlighting

1. **AST widening blast radius was ~25 call sites.** Pattern was
   mechanical (`|x| if (x) |xp|` → `|x| if (x.value) |xp|`) but
   `parser.zig::makeJump` had to stop covering `.@"break"`. The
   parser inlines the union init directly — same shape as `.yield`.
2. **§G1 substituteHoles integration seam.** Frente A's
   `substituteHoles` (merged from feat mid-session) used the old
   `?*Expr` shape; the 1-line fix landed in `7abbed4`. Any new walker
   over Jump AST follows the same gate.
3. **`return <iter>` shortcut removed.** Pre-RI1, JS lowered
   `return doRange(...)` to `yield* doRange(...)`. RI1 forbids the
   form; the `js: iterator fromList yields array items` snapshot was
   simplified (dropped recursive `doRange`). Recursive-delegation
   coverage moves to F6 `effect_iterator.zig`.
4. **`use*` errors carry §2 prefixes via message alias, not variant
   rename.** Pattern generalizes to RC1/RC3 once their runtime/anchor
   checks land — message format `<rc-code>: <legacy-text>`.
5. **`@getContex` parses for free.** The lexer's `@`-prefix
   `.builtinIdent` path handles it. RC4 inspects the typed arg as
   `.identifier` with name in `env.lookupTypeDef`. Doesn't yet cover
   `@getContex(MyType<Generic>)`; pin if a need emerges.
6. **Eric works in parallel.** Three separate `feat` advances arrived
   during the session (ci-pipelines-green + frente-a §G1/§D1/§D2 +
   test-libs shipping + erlang B3 + lib allow_fail). Pattern that
   works: sweep on every checkpoint; resolve `TODO.md` conflict with
   `--ours`; take working-tree pointer for submodule conflicts.

---

### F4F-tail — `#[@future]` transform + commonJS lowering

#### F4F-T1 — `transform.zig` rewrites
- [ ] `comptime/transform.zig`: inside a `#[@future]` body, rewrite
      `return <t>;` to `return @Future.resolved(<t>);` at AST level;
      rewrite `throw <e>;` to `return @Future.rejected(<e>);`. Use the
      same `env.future_jump_lowerings` shape that `result_jump_lowerings`
      uses (allocate the map; populate at the jump site in `infer.zig`
      `.@"return"` / `.@"throw_"` arms; consume in `transform.zig`).

#### F4F-T2 — commonJS lowering
- [ ] `codegen/commonJS.zig`: any `__bp_future_resolved(<t>)` call lowers
      to bare `return <t>;` inside the enclosing `async function`; any
      `__bp_future_rejected(<e>)` lowers to `throw <e>;`. (The native JS
      `async function` machinery is the wrap; this lowering is the
      identity for hand-written `return`/`throw`, which is exactly what
      makes the contract-author surface read like plain code.)

#### F4F-T3 — snapshot
- [ ] Add a `codegen/tests/effect_future_lowering.zig` snapshot asserting
      the lowering shape end-to-end on commonJS.

**Files**: `modules/compiler-core/src/comptime/{transform,infer}.zig` ·
  `modules/compiler-core/src/codegen/commonJS.zig` ·
  `modules/compiler-core/src/codegen/tests/effect_future_lowering.zig`
  (new)

---

### F4G-tail — user-typeDef defaults consumer-threading

#### F4G-T1 — TypeDef extension
- [ ] `comptime/env.zig`: add `genericDefaults: []const ?*T.Type = &.{}`
      to each of `TypeDef.Record`, `TypeDef.Struct`, `TypeDef.Enum`. Add
      a `TypeDef.genericDefaults()` helper that returns the right slice
      per variant.
      *(WIP partial at session end: env.zig changes drafted on the
      `task/frente-b-rules-tooling` worktree; not committed.)*

#### F4G-T2 — registerTypeDef populates
- [ ] `comptime/infer.zig`: in each of `registerRecord` /
      `registerStruct` / `registerEnum`, resolve `gp.default` (if any)
      against the same `genericMap` the field types use; pass the
      resulting `[]?*T.Type` to the new field. Order matters: a default
      like `<T, U = T>` must see `T` already in the map.
      *(WIP partial at session end: record + struct + enum sites
      drafted; not committed.)*

#### F4G-T3 — resolveTypeRefInContext applies
- [ ] In the `.generic` arm, parallel to `builtinDefaultFilledArgs`: when
      `!b.is_builtin` AND `env.lookupTypeDef(b.name)` has a non-empty
      `genericDefaults()` AND `b.args.len < genericDefaults.len`, fill
      the missing trailing slots from the resolved defaults. RG3 already
      catches the under-supplied case where the first omitted slot has a
      null default.
      *(WIP partial at session end: drafted; not committed.)*

#### F4G-T4 — snapshot
- [ ] Extend `comptime/tests/generic_defaults.zig` with positive cases:
      - `record Container<A, B = string>` + `Container<i32>` resolves
        with `B = string`.
      - `record Sym<T, U = T>` + `Sym<i32>` resolves with `U = i32`.
      - `enum Result2<T, E = string>` + `Result2<i32>` resolves with
        `E = string`.
      *(WIP partial at session end: 3 tests drafted; the enum case
      tripped `assertInfersOk` — needs investigation before commit.)*

**Files**: `modules/compiler-core/src/comptime/{env,infer}.zig` ·
  `modules/compiler-core/src/comptime/tests/generic_defaults.zig`

---

### F4C-tail — `contextStack.zig` + RC1 + RC3 + lowerings

#### F4C-T1 — `comptime/contextStack.zig` (new file)
- [ ] Author the per-compilation-unit map of `Type → Provider` (each
      entry records the active provider value's source location, so RC1
      can point at it). API:
      ```zig
      pub const ContextStack = struct {
          entries: std.AutoArrayHashMapUnmanaged(TypeId, []Entry),
          pub fn push(self: *@This(), type_id: TypeId, provider_loc: ast.Loc) !void;
          pub fn pop(self: *@This(), type_id: TypeId) void;
          pub fn lookup(self: *@This(), type_id: TypeId) ?Entry;
          pub const Entry = struct { provider_loc: ast.Loc };
      };
      ```
- [ ] Populate at `use`-block entry/exit. The transform pass marks each
      `use <hook>()` so the codegen knows where to emit push/pop.

#### F4C-T2 — Anchor extraction (RC3 prerequisite)
- [ ] In `inferFnBody`, when `eff == .context`, extract the Anchor type
      from the return wrapper: `@Context<Base, T>` → `Base`. Store on a
      new `env.contextAnchor: ?*T.Type` field (save/restore around the
      body, like `env.inContextFn`).

#### F4C-T3 — RC1: no active provider
- [ ] `inferBuiltinCallReturnType` "getContex" arm: if the requested type
      is not on the active `ContextStack`, fire `context-unbound`
      diagnostic at COMPTIME when the absence is statically knowable
      (e.g. no enclosing `use` block declared `T`). At codegen time,
      emit a runtime trap (`throw new Error("context-unbound: …")` for
      JS, `error({context_unbound, …})` for erlang/beam).

#### F4C-T4 — RC3: `@getContex(T)` outside Anchor tree
- [ ] Same `getContex` arm: when `env.contextAnchor` is non-null and the
      requested type's `contextBase` (from its `TypeDef`) is not a
      subtype of the Anchor, fire `context-getcontex-anchor-violation`.

#### F4C-T5 — commonJS lowering
- [ ] Emit a module-level `__bp_context_stack = []` array; each
      `use <hook>(args)` lowers to:
      ```js
      __bp_context_stack.push({type: '<TypeName>', value: <hook>(args)});
      try { /* body using @getContex */ } finally { __bp_context_stack.pop(); }
      ```
      `@getContex(T)` lowers to
      `__bp_context_stack.find(e => e.type === 'T')?.value ?? __bp_context_trap('T')`.

#### F4C-T6 — erlang/beam lowering
- [ ] Use the process dictionary: `put({bp_context, 'T'}, Value)` on
      `use`, `erase({bp_context, 'T'})` on exit. `@getContex(T)` lowers
      to `get({bp_context, 'T'})` with a `case` for the `undefined`
      path → `error({context_unbound, 'T'})`.

#### F4C-T7 — snapshots
- [ ] `comptime/tests/effect_context.zig` covers RC1, RC2, RC3, RC4,
      RC5, RC6 plus a happy-path test that exercises `use <hook>()` +
      `@getContex(T)` across nested providers.
- [ ] `codegen/tests/effect_context_lowering.zig` covers the lowering
      shape on commonJS + erlang (beam mirrors erlang).

**Files**: `modules/compiler-core/src/comptime/contextStack.zig` (new) ·
  `modules/compiler-core/src/comptime/{infer,transform,env}.zig` ·
  `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm}.zig` ·
  `modules/compiler-core/src/comptime/tests/effect_context.zig` (new) ·
  `modules/compiler-core/src/codegen/tests/effect_context_lowering.zig`
  (new)

---

### F5-tail — `Iterator<T,E,C>` + `IteratorStep` migration

#### F5-T1 — atomic-migrate consumers
- [ ] Audit every `next() -> ?T` call site in `libs/`. The contract
      switches from "exhausted = none, yielded = some" to "step is one of
      Yield/Done/Error". Land all consumer migrations in a single commit
      so no cross-library compile is half-stale.

#### F5-T2 — `builtins.d.bp`
- [ ] `pub interface Iterator<T, E = any, C = void>`:
      ```bp
      pub interface Iterator<T, E = any, C = void> {
          declare fn next(self: Self) -> @IteratorStep<T, E, C>;
      }
      pub enum IteratorStep<T, E, C> {
          Yield(T),
          Done(C),
          Error(E),
      }
      ```
- [ ] `pub interface AsyncIterator<T, E = any, C = void>` (parallel).

#### F5-T3 — codegen + snapshots
- [ ] Adjust each backend's iterator-loop adapter (`function*` on JS,
      the erlang/beam process-spawn shape) to translate the new
      `IteratorStep` variants. F4I-tail consumes this here.

**Files**: `libs/std/src/builtins.d.bp` · every `libs/<lib>/` that uses
  `next()` (audit pass) · `modules/compiler-core/src/codegen/*.zig`
  (loop adapters)

---

### F4I-tail — `transform.zig → @IteratorStep`

#### F4I-T1 — gated on F5-tail
- [ ] BLOCKED on F5-tail landing `pub enum IteratorStep<T, E, C>` in
      `libs/std/src/builtins.d.bp`.

#### F4I-T2 — transform rewrites
- [ ] `comptime/transform.zig`: inside an `#[@iterator]` /
      `#[@asyncGenerator]` body, rewrite `break <c>;` (when targeting
      the FSM — top-level or fn-labelled, the same scoping rule F4I's
      RI2/RI3 use) to `return @IteratorStep.Done(<c>);`. Rewrite
      `throw <e>;` to `return @IteratorStep.Error(<e>);`. Bare `break;`
      becomes `return @IteratorStep.Done(void);`. Use a new
      `env.iterator_jump_lowerings` map (parallel to
      `result_jump_lowerings`).

#### F4I-T3 — codegen
- [ ] Each backend renders `@IteratorStep.Done(c)` /
      `@IteratorStep.Error(e)` / `@IteratorStep.Yield(t)` natively
      (the existing `function*` shape already does this for `yield`;
      the new cases close `break`/`throw`).

#### F4I-T4 — snapshot
- [ ] `codegen/tests/effect_iterator_lowering.zig` covers all three
      step variants on all four backends.

**Files**: `modules/compiler-core/src/comptime/{transform,infer}.zig` ·
  `modules/compiler-core/src/codegen/{commonJS,erlang,beam_asm,wat}.zig` ·
  `modules/compiler-core/src/codegen/tests/effect_iterator_lowering.zig`
  (new)

---

### F6 — per-effect snapshot suites

Each suite lives at `modules/compiler-core/src/comptime/tests/effect_<name>.zig`
and covers the §<section> contract end-to-end. Pattern mirrors
`generic_defaults.zig`: success cases + every rejection diagnostic.

- [ ] **F6-T1** `effect_result.zig` — §1 (R11 / R12 / auto-wrap return /
      auto-wrap throw / try-catch round-trip / nested `#[@result]` call).
- [ ] **F6-T2** `effect_future.zig` — §1F + the `fetchUser` example
      (RF1 / RF2 / RF3 / RF4 / RF5 + happy path with `await`). Pairs
      with F4F-tail's lowering snapshot.
- [ ] **F6-T3** `effect_generator.zig` — `#[@generator]` (`yield` /
      `yield :label` / labelled-loop interaction + R8 + R10).
- [ ] **F6-T4** `effect_iterator.zig` — §1I `lazyMap` example end-to-end
      (RI1–RI6 + the spec's `break :a 445` form once `codegen-break-label`
      lands). Replaces the recursive-delegation coverage dropped from
      `js_features.zig` when RI1 landed.
- [ ] **F6-T5** `effect_context.zig` — §1C Anchor + `@getContex` (RC1–
      RC6 + nested `use` providers + cross-Anchor rejection). Lands with
      F4C-tail.
- [ ] **F6-T6** (gated on Frente A §D-D4, out of scope here)
      `effect_asyncGenerator.zig`.

**Files**: `modules/compiler-core/src/comptime/tests/effect_*.zig` ·
  `modules/compiler-core/src/comptime/tests.zig` (barrel — add the new
  imports)

---

### Done gate (this spec)

- [ ] F4F-T1 + F4F-T2 + F4F-T3 ticked
- [ ] F4G-T1 + F4G-T2 + F4G-T3 + F4G-T4 ticked (resolve the enum
      `assertInfersOk` red recorded in the reanalysis above)
- [ ] F4C-T1 → F4C-T7 ticked
- [ ] F5-T1 + F5-T2 + F5-T3 ticked
- [ ] F4I-T1 → F4I-T4 ticked (depends on F5-tail)
- [ ] F6-T1 → F6-T5 ticked (T6 deferred to Frente A §D-D4)
- [ ] R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4 all fire under
      tests with §2-prefix on every message
- [ ] `libs/std/src/builtins.d.bp` `§ effect annotations` block matches
      v0.beta.19 spec §4 verbatim
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` green
- [ ] Every touched AGENTS.md updated in the same commit as the code

### Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`).
- Functions in camelCase (`feedback_camelcase_naming`).
- Implement in `.bp` when possible (`feedback_prefer_bp_over_dbp`).
- After each commit, advance to the next checkbox
  (`feedback_continue_after_commit`).
- The bilingual §1/§1F/§1I/§1C addendum blocks from the umbrella spec
  are the **only** Portuguese surface — preserve them verbatim if any
  of them gets quoted here; everything else stays English.

---

## test-run-log — `----- RUN LOG -----` fence per test on all 4 backends

**Slug**: test-run-log
**Depends on**: `v0.beta.19/specs/frente-b-rules-tooling.md` §T (the
  umbrella that scoped this) — nothing else; file-disjoint from
  `rules-tooling-close` and `codegen-break-label`.
**Status**: pending

### Premise

v0.beta.19 closed every Rules-track effect-annotation contract surface
the AUTHOR can observe syntactically. The whole §T track — capturing
stdout per `test "name" { … }` block and rendering it as a fenced
```logs``` block under a `----- RUN LOG -----` sentinel — is **net-new
tooling** that v0.beta.19 explicitly scoped out. This spec ships it
end-to-end: a runtime primitive, per-backend codegen wrappers, a CLI
consumer (`botopink test` + `--json`), a lib-test-runner prefix, plus
cli tests + snapshots + docs.

The wat backend is gated on Frente A §C2 (wires
`botopink test --target wasm`); commonJS/erlang/beam ship in T1's
first three subtasks and turn green immediately.

### Target format (umbrella spec verbatim)

Each `test "name" { … }` body produces:

```
TEST <file>:<line> <name>
----- RUN LOG -----
\`\`\`logs
<captured stdout, escaped only for ASCII control chars + the closing
fence sequence>
\`\`\`
```

A `--json` mode emits one JSON record per line (JSONL) with
`{file,line,name,status,duration_ms,run_log}` keys.

### Tracks

#### T0 — `runtime.captureStdout` primitive

- [ ] `modules/compiler-core/src/runtime.zig`: every `execute*` path
      returns `(exit_code: u8, stdout_bytes: []const u8)`. Captures via
      OS pipe on each shell-out target:
      - Node: spawn with `stdio: ['ignore', 'pipe', 'inherit']`.
      - Erlang/BEAM: `os:cmd/1` returns combined output; tee through a
        wrapper script that splits on a sentinel marker.
      - wasmtime: `--invoke` with `--inherit-stderr` + `--capture-stdout`.
      Single shape across targets — the caller doesn't case-split on
      which runtime emitted the bytes.

#### T1 — per-backend test-mode codegen

Each backend's `emitTestRunner` / `__bp_run_tests` path wraps each
`test "name" { … }` body with the Target format above. The test name
+ source location are embedded as literal strings at codegen time
(no runtime reflection needed).

- [ ] **T1-commonJS** in `codegen/commonJS.zig` — wrap each test body
      in a function literal called from a runner array; the runner
      prints `TEST <file>:<line> <name>` + `----- RUN LOG -----`, then
      runs the body. Capture is implicit: stdout is whatever the body
      writes.
- [ ] **T1-erlang** in `codegen/erlang.zig` — same shape; each test
      becomes a runner-list entry; the runner calls `io:put_chars/1`
      with the sentinel envelope around the body invocation.
- [ ] **T1-beam** in `codegen/beam_asm.zig` — mirrors erlang's shape
      lowered to BEAM bytecode (`call_ext_only` to the same
      `io:put_chars/1`).
- [ ] **T1-wat** in `codegen/wat.zig` — **gated on Frente A §C2**
      wiring `botopink test --target wasm`. Track that gating in the
      `Done gate` and don't block T2/T3/T4 on it.

#### T2 — `test_cmd.zig` consumer + `--json` mode

- [ ] `modules/compiler-cli/src/cli/test_cmd.zig`: parse the sentinels
      emitted by T1 (read line-by-line, accumulate into a per-test
      record). Render per the "Target format". Add a `--json` mode
      emitting JSONL records as defined above.
- [ ] Exit code: nonzero if any test fails; mirrors `zig build test`'s
      semantics.

#### T3 — `lib-test-runner` prefix

- [ ] `modules/lib-test-runner/src/{runner,report}.zig`: lib-prefix
      every emitted line (`<lib>: TEST …`). `--json` records carry a
      `lib` field. Reuse T2's parser; just inject the lib name at the
      reader's call site.

#### T4 — CLI tests + snapshots

- [ ] `tests/cli/test_run_log_format.zig` — cases:
      - 1 pass test, no stdout → log block empty
      - 1 fail test → status `fail`, log carries the assertion message
      - 0 tests → no `TEST` line emitted, exit 0
      - 3 tests → all three blocks in source order
      - Each scenario × commonJS/erlang/beam (×wat per gating)
- [ ] `tests/cli/test_run_log_json.zig` — schema check: each line
      parses, has the required keys, no extras.
- [ ] Snapshots under `snapshots/cli/test/`.

#### T5 — docs sweep

- [ ] `modules/compiler-cli/AGENTS.md` — new "Test output format"
      subsection: the sentinel, the fenced ```logs``` block, the
      `--json` JSONL schema.
- [ ] `modules/lib-test-runner/AGENTS.md` — lib-prefixed mirror note +
      the `lib` field on `--json` records.
- [ ] `libs/std/AGENTS.md` — `test { … }` block paragraph: "each test's
      stdout is captured and surfaced under the `----- RUN LOG -----`
      fence; assertion failures show up in the same channel".
- [ ] `modules/compiler-core/AGENTS.md` — codegen section link to the
      test-mode emitter pattern.

---

### Done gate (this spec)

- [ ] T0 ticked (one `runtime.captureStdout(...)` shape across all
      shell-out targets)
- [ ] T1-commonJS + T1-erlang + T1-beam ticked (T1-wat per Frente A §C2
      gating)
- [ ] T2 ticked (sentinel parser + `--json` mode)
- [ ] T3 ticked (lib-prefix + `lib` JSON field)
- [ ] T4 ticked (cli tests + snapshots; wat scenarios per gating)
- [ ] T5 ticked (4 AGENTS updated in the same commit as the code)
- [ ] `botopink test` emits `----- RUN LOG -----` per test on
      commonJS/erlang/beam (wat per gating)
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` +
      `zig build test-vscode` all green

### Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`).
- Worktree paths for Read/Edit (`project_worktree_workflow`).
- Functions in camelCase (`feedback_camelcase_naming`).
- After each commit, advance to the next checkbox
  (`feedback_continue_after_commit`).

---

## codegen-break-label — `break :label` honors the label on all 4 backends

**Slug**: codegen-break-label
**Depends on**: `rules-tooling-close` F4I-T2/T3 (the `@IteratorStep`
  transform rewrite; the codegens dispatch off the rewritten form).
**Status**: pending

### Premise

v0.beta.19 F4I widened the Jump AST `.@"break"` variant from
`?*Expr` to `{label: ?[]const u8, value: ?*Expr}` (mirrors `.yield`).
The parser accepts `break :label [<expr>]`; the comptime body walk
fires RI2 (break-type-mismatch with declared `C`), RI3 (break-with-
C=void), and RI5 (label unbound) when the break targets the iterator
FSM (top-level or fn-labelled, the same scoping rule §1I REGRAS DE
ESCOPO uses).

**Every codegen backend ignores the label** — they lower only the
value. For `break :iteratorFnLabel <C>` inside a nested loop, all
four backends emit "break the loop", NOT "exit the FSM with
completion value `<C>`". This was registered in
`project_v0beta19_f4i_done.md` as a known gap.

Each backend needs its own escape mechanism (JS generator functions
have no labelled break; the FSM exit needs explicit state). The
work is mostly mechanical once `rules-tooling-close` F4I-T2 lands
the `@IteratorStep.Done(<C>)` rewrite — the codegens then dispatch
on the rewritten form.

### Tracks

#### CP-commonJS — generator-function break-target dispatch
- [ ] When the break targets the FSM (label matches the fn signature
      label, or top-level + no enclosing loop), rewrite via
      `return @IteratorStep.Done(<C>);` (via the F4I-T2 transform)
      and let the existing `function*` codegen lower the `return`
      naturally. The label drives which escape level — inner-loop
      breaks stay as JS `break`; FSM breaks lower as `return { done:
      true, value: <C> }`.

#### CP-erlang
- [ ] FSM-targeting breaks lower to `throw({bp_iter_done, <Label>, C})`;
      the iterator-loop adapter catches the tagged tuple by label.
      `throw <e>;` inside `#[@iterator]` lowers to `throw({bp_iter_error,
      <Label>, E})` — same catch shape, different tag.
- [ ] Inner-loop breaks keep their existing erlang `break`-equivalent
      (the `loop_pop` BIF or the case-expression unwind).

#### CP-beam
- [ ] Mirrors erlang's shape lowered to BEAM bytecode (the tagged-tuple
      throw becomes a `raise` op; the catch becomes a `try`/`of`
      pattern). If the iterator runs in its own process, the catch
      becomes a `receive` for the message.

#### CP-wat
- [ ] Branch table with one label per active loop / iterator FSM;
      `(br $<n>)` per label depth. The FSM scope's label is at the
      deepest level; inner-loop labels stack on top. The break
      compiler walks the active label stack at the break site, picks
      the index matching the targeted label, and emits `br $<index>`.

### Notes

- F4I-tail's `transform.zig → @IteratorStep` rewrite is the upstream
  prerequisite: each FSM-targeting break becomes
  `return @IteratorStep.Done(<C>);` BEFORE codegen sees it. The codegens
  here only need to handle the LABELLED INNER-LOOP break — the rewrite
  takes care of the FSM-exit shape.
- A break inside a nested loop with **no** label still targets the
  loop, not the FSM (§1I REGRAS DE ESCOPO). Verified by the F4I-tail
  `Env.loopDepth` machinery; the codegen need not re-check.
- F6-T4 `effect_iterator.zig` is the consumer test (`lazyMap` example's
  `break :a 445` form); it lands AFTER this spec closes.

### Done gate

- [ ] CP-commonJS ticked (generator-function break-target dispatch lands;
      `return { done: true, value: <C> }` shape verified)
- [ ] CP-erlang ticked (tagged-tuple throw + catch in iterator adapter)
- [ ] CP-beam ticked (mirror of erlang shape on BEAM bytecode)
- [ ] CP-wat ticked (branch-table label stack)
- [ ] `rules-tooling-close` F4I-T2/T3 closed (otherwise the rewrite is
      not in scope and `break <C>` doesn't surface)
- [ ] F6 `effect_iterator.zig` lazyMap test passes on all 4 backends
- [ ] `zig build test` + `zig build test-libs` green

### Per-memory reminders

- SSH for all git remote ops.
- Worktree paths for Read/Edit; one worktree (`.tasks/codegen-break-label/`)
  if you want isolated coverage, otherwise lands inline with
  `rules-tooling-close`.
- Functions in camelCase.
