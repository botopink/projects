# TODO — stdlib-backends-parity

> Task branch `task/stdlib-backends-parity` · spec
> [`tasks/v0.beta.7/specs/stdlib-backends-parity.md`](../../tasks/v0.beta.7/specs/stdlib-backends-parity.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test.
> Independent / parallel-safe with `annotation-processors`. No framework knowledge;
> stdlib coupling in the core is allowed (this spec de-couples nothing).

## A1 — mirror JS instance/associated-method lowering on the other backends
- [x] **erlang** value-receiver instance methods: record/enum/struct methods bind
      `self`; calls dispatch via the loc-keyed `instanceLowerings` table
      (`.record` → `m(Recv,args)`/`owner:m(...)`, `.prim` → host op). Array/String
      primitive lowering (`emitPrimMethod`: map/filter/forEach/reverse/append/
      prepend/push/at/slice/join/indexOf/contains/len; string upper/lower/trim/
      length/slice/find/prefix/split). `.length`/`.len` field → `length(...)`.
      fn-typed locals call as `F(args)` (`locals` set). Enum case patterns emit
      atoms (`enum_variants`), not unbound vars.
- [ ] **beam_asm.zig / wat.zig** — same lowering not yet ported (still emit the
      old value-receiver form for primitives). See A1b.
- [~] `std_erlang.sh` **partial**: `order` 3/3 green; `dict`/`queue`/`sets`
      compile + run partially; `erika` (LINQ) still blocked. Remaining blockers:
      structural `==`/`!=` on tuples/maps, `?T` option chaining through method
      results, erika `case … of` codegen + LINQ inference gaps.

## A2 (remainder) — `@[external]` associated fns
- [ ] `Array.range`/`Array.repeat` + other `@[external]` associated fns lower on
      every backend; ship companion host modules (`primitives.mjs`/`.erl`).

## A3 — inference correctness
- [x] Type-check method / `default fn` bodies (`inferTypeMethods` — best-effort:
      record-method gaps are skipped so `erika` still compiles).
- [~] Generic-extends-generic (`implement Foo<A> for Bar<A>`) — resolves through
      the existing generic machinery; no dedicated test added.
- [ ] Parse + infer literal method receivers (`[1,2].map(...)`, `"x".contains(...)`)
      — parser still only chains off identifier receivers.

## B — backend-parity F1–F6
- [ ] F1 literal method receivers reach codegen on every backend (blocked on A3).
- [ ] F2 snake_case→camelCase dispatch normalization (legacy `to_string`).
- [~] F3 erlang loads std modules (records/methods lower); beam pending.
- [~] F4 `?.` optional-chaining: erlang already lowers it (immediate-fun guard);
      beam/wasm pending.
- [~] F5 wasm test runner: `wat.zig` notes a `wasmtime` runner; `botopink test`
      still only runs `commonJS`/`erlang` (test_cmd gate).
- [x] F6 duplicate test-name warning (commonJS test-entry collection → stderr).

## Done gate
- [x] `zig build && zig build test` green (erlang snapshots regenerated).
- [~] `std_erlang.sh` **partial** (order green; others partial — see A1).
- [x] `codegen/AGENTS.md` + `comptime/AGENTS.md` updated.

## Notes
- Node suite stays fully green (12/19/3/7/9). Erlang went 0 → 9 passing tests.
- The core machinery (instance-lowering table threaded inference→codegen,
  method-body inference, primitive lowering, enum-pattern + fn-local fixes) is in
  place; the remainder is a per-module long tail + beam/wasm porting.
