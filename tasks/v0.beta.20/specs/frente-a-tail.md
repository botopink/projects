# frente-a-tail — close v0.beta.19 frente-a-compiler deferrals (§A7 / §B / §C / §D3-D5 / §G2)

**Slug**: frente-a-tail
**Depends on**: v0.beta.19 `frente-a-compiler` partial close (`fe2b7e3`
  — §S/§U/§A6/§D1/§G1/§G3 done); v0.beta.20 `prim-op-annotation-tail`
  for §A7 alignment (BEAM template dispatch).
**Files**:
- §A7 lands in `prim-op-annotation-tail` — this spec only carries the
  audit + close-out check.
- §B: `comptime/infer.zig` (generic inference + `registerStdlib` gap),
  `comptime/transform.zig` (erika-LINQ red), new
  `tests/comptime/generic_inference.zig`.
- §C: `codegen/wat.zig` + `codegen/wasm/aggregate.zig` (new) — wasm
  aggregate types refactor + wat encoder hygiene.
- §D3: `codegen/beam_asm.zig` cross-module qualified-call lowering
  (the dual of §D2's `fbe6b62`).
- §D4: `codegen/{erlang,beam_asm}.zig` `#[@future]` lowering — the
  erlang Promise-equivalent shape (gen_server callback / `timer:sleep`
  + return value extraction).
- §D5: per-target coverage matrix (the documented surface in the
  codegen AGENTS.md; the **enforcement** part landed via STD-001 in
  `std-expansion-tail-followup` P9 — this spec only ensures the
  matrix's row-set is updated).
- §G2: erika runtime-string interpolation — `transform.zig` lowering
  + `tests/comptime/erika_runtime.zig`.
**Touches docs**:
- `modules/compiler-core/src/codegen/AGENTS.md` (Remaining-gaps roll —
  drop §A6 row, refresh §D2 to "done upstream + §A2-twin-aware").
- `modules/compiler-core/src/comptime/AGENTS.md` (generic-inference
  fix's caller-impact note).
- `libs/erika/AGENTS.md` (§G2 runtime-string row).
- `CHANGELOG.md` (per-track entries).
**Status**: pending

## Premise

The v0.beta.19 `frente-a-compiler` set landed §S (`*fn` removal), §U
(unused-builtin sweep), §A6 (annotation-driven Family 1), §D1 (print
family), §G1 (`${…}` interp), §G3 (AGENTS refresh). The status row
(`fe2b7e3`) deferred §A7 / §B / §C / §D2-D5 / §G2 with specific
reasons recorded; §D2 since landed upstream (`fbe6b62` / `c5a4ad3`).

`frente-a-tail` closes the remaining tracks. The choice not to fold
them into `std-expansion-tail-followup` is deliberate — those tracks
are deep compiler work (generic inference; wat refactor;
`#[@future]` lowering on a new backend pair) and file-disjoint with
the stdlib-driven follow-ups. Running them on their own worktree
keeps the std-tail-followup's spec / test gate focused on stdlib
surface.

## Steps

### §A7 — BEAM bytecode-template gate (audit-only)

The actual wiring lands in `prim-op-annotation-tail` P-A. This spec's
§A7 phase is the close-out audit:

- [ ] After `prim-op-annotation-tail` lands its BEAM template path,
      verify the §A6 "irreducible allow-list" carve-out from
      `codegen/AGENTS.md` is empty.
- [ ] Cross-check via `git grep "mem.eql(u8, callee" modules/compiler-core/src/codegen/beam_asm.zig`
      — expect zero matches in `emitPrimMethod` (the dispatch surface).
- [ ] Update `frente-a-compiler` spec's §A7 row in v0.beta.19 status
      to "done via prim-op-annotation-tail P-A".

### §B — generic-inference (inline tests in generic modules + erika-LINQ + registerStdlib)

The deepest pending track. v0.beta.19 status: "deep inferencer work;
planned for a successor spec — keeps the pre-existing erlang/beam
erika-LINQ + generic-module inline-test reds recorded".

- [ ] `comptime/infer.zig` — fix `registerStdlib`'s generic-instance
      gap. Currently inline tests in generic modules (pair, list,
      iterator, dict, sets, function, queue) red with `.generic
      TypeError.typeMismatch` because each scratch env processes the
      module source with type variables still un-instantiated (memory
      note `project_generic_inference_gap`). The fix: defer
      type-variable instantiation in `freshTestEnv` until the test
      body's call site materialises the witnesses.
- [ ] `comptime/transform.zig` — erika-LINQ shape on erlang/beam:
      the `Query<T>` enumerator's `where`/`select` chain currently
      emits a generic `.unify failure` because the receiver type isn't
      propagated through the templated body's hole-substitution pass.
      Trace via `tests/comptime/erika_linq.zig` (new) — fix lowers to
      `tryEmitPrimAnnotation` recognising the `Query<T>` receiver as
      `.prim(.record)` with the type-name visible through the §A2
      template path.
- [ ] `tests/comptime/generic_inference.zig` (new) — round-trip a
      generic module's inline tests on every backend (`pair`, `list`,
      `iterator`, `dict`, `sets`).

### §C — wasm-aggregates + wat refactor

v0.beta.19 status: "deep wat refactor; no regression — the wasm gap
was the spec's premise".

- [ ] `codegen/wasm/aggregate.zig` (new file) — extract the
      record/struct/enum lowering shape from `wat.zig` into a focused
      module. The current monolith makes the aggregate path
      indistinguishable from the value-level instruction emit.
- [ ] `codegen/wat.zig` — refactor `emitRecord` / `emitStruct` /
      `emitEnum` to delegate to `aggregate.zig`. No behaviour change
      (snapshots stay byte-identical).
- [ ] Add support for nested record / struct / enum lowering — the
      current implementation flattens at the call site, which fails
      for `record A { b: B }` where `B` is itself a record. Test via
      `tests/codegen/wasm/nested_record.zig` (new).
- [ ] Pin via per-shape snapshots.

### §D3 — beam_asm cross-module qualified-call lowering

The dual of §D2 (`fbe6b62`). §D2 wired `from "<lib>"` qualified calls
into BEAM register-allocation; §D3 wires the inverse direction
(cross-module calls FROM the std lib TO user code).

- [ ] `codegen/beam_asm.zig` — extend the qualified-call emitter to
      recognise the local-module receiver path (`from "myMod"
      myFn(args)` → `beam atom-lookup + apply` on the receiver
      module).
- [ ] Per-call snapshots.

### §D4 — `#[@future]` erlang/beam lowering

v0.beta.19 status: "D2–D5 deferred (substantive cross-module /
type-directed / register choreography work)".

- [ ] `codegen/erlang.zig` — `#[@future]` fn bodies lower to a `proc`
      shape that returns `{ok, V}` on success or `{error, R}` on
      throw. The erlang side has no native Promise — the simplest
      shape is a synchronous return wrapped in the result tuple, with
      `await` lowering to a `case` that extracts. (The deferred
      `time.sleep` from `std-expansion-tail-followup` P11 wraps this.)
- [ ] `codegen/beam_asm.zig` — mirror the lowering, register-
      allocating the result tuple.
- [ ] `tests/codegen/future_erlang.zig` + `tests/codegen/future_beam.zig`
      (new) round-trip a `*fn() -> T` shape.

### §D5 — per-target coverage matrix (close-out)

The STD-001 diagnostic from `std-expansion-tail-followup` P9 drives
the matrix at runtime. This spec's §D5 phase is the docs sweep that
mirrors the runtime matrix into the codegen AGENTS table.

- [ ] `modules/compiler-core/src/codegen/AGENTS.md` — extract the
      per-target coverage table from the STD-001 lookup output and
      pin it in the AGENTS file. (`std-expansion-tail-followup` P18
      already does this — this phase is the audit pass.)

### §G2 — erika runtime-string interpolation (generic compiler mechanism)

v0.beta.19 status: "G2 deferred (runtime-string form needs a generic
compiler mechanism)". §G1 wired `${…}` interp via `q.parts()` +
`substituteHoles` at compile time; §G2 wires the runtime-string form
where the template body is built from a `string`-typed expression
(not a `@code`-typed template literal).

- [ ] `comptime/transform.zig` — add the runtime-string lowering: when
      the erika template body's `parts()` resolves to a `string`-typed
      expr (not an `@code`-typed expr), lower to a runtime `String`
      concatenation across the holes via the existing `[a, b].join("")`
      shape.
- [ ] `libs/erika/src/erika.bp` — the template body's contract gets
      a `runtimeBody: string` alternative carrier (no AST change to
      the existing `compileBody: @code` path).
- [ ] `tests/comptime/erika_runtime.zig` (new) — round-trip a
      runtime-string template across the four backends.

## Test scenarios

```
§B   inline tests in pair/list/iterator/dict/sets all green on commonJS+erlang
§B   erika-LINQ Query<T>.where().select() lowers on erlang+beam
§C   record A { b: B } nested record lowers on wat
§C   wat snapshots byte-identical pre- and post-refactor
§D3  qualified cross-module call from a std module emits BEAM apply
§D4  `*fn() -> i32` returns {ok, V} on erlang; throw lowers to {error, R}
§D5  STD-001 matrix matches the codegen AGENTS row by row
§G2  erika "..." with a runtime-string body emits the join shape
```

## Notes

- **§B is the keystone risk** — generic-inference work is deep, and
  the fixes here have to keep the existing `tests/comptime/*.zig`
  snapshots byte-identical (the `tryEmitPrimAnnotation` interface-
  method path stays untouched). If `registerStdlib`'s fix surfaces
  cross-backend snapshot churn, defer to v0.beta.21 with a clear
  carve-out.
- **§C wasm refactor** can land independently — it's purely
  organizational at the file level, no surface change.
- **§D4 `#[@future]`** crosses over with `std-expansion-tail-followup`
  P11 (`time.sleep`). If P11 wants a clean shape, schedule §D4 first;
  otherwise the spec author may choose to land sleep with the §A3
  `#[@result]` shape and defer §D4 to v0.beta.21.

## Exit gate

- [ ] §A7 audit confirms zero `mem.eql` BEAM allow-list arms.
- [ ] §B `registerStdlib` fix lands; generic-module inline tests
      green; erika-LINQ on erlang+beam green.
- [ ] §C wat aggregate refactor lands; per-shape snapshots regenerate
      green.
- [ ] §D3 beam_asm cross-module qualified-call lowering green.
- [ ] §D4 `#[@future]` lowering green on erlang+beam.
- [ ] §D5 codegen AGENTS per-target table matches STD-001 runtime
      lookup row-by-row.
- [ ] §G2 erika runtime-string interpolation lands; new fixture
      green across the four backends.
- [ ] `botopink-lib-test --lib all --target all` green.
- [ ] CHANGELOG per-track entries.
