# Fix options for the untyped primitive dispatch

Three ways to make `recv.m(args)` in a comptime body reach the same lowering the typed path uses,
with cost, what each covers, what it breaks, and what it does to the `COMPTIME ERLANG` snapshots.
Paths are relative to `repository/botopink-lang/`.

## (a) A per-method runtime-dispatch shim, generated from the typed table

At `codegen/erlang.zig:3571`, when `this.untyped`, record `(callee, argc)` in a
`needed_untyped_prim_shims` set and emit `'__bp_prim_<callee>'(Recv, A0…An)` instead of the bare
call. Then emit one form per reached `(callee, argc)`: one clause per `PrimKind` that has a
`prim_erlang_dispatch` entry for the method, guarded by `is_binary/1` (string), `is_list/1`
(array), `is_boolean/1` (bool), `is_integer/1` (int), `is_float/1` (float), plus a final clause
that raises a readable error. Erlang's runtime types separate the five kinds cleanly, which is
exactly the trick `'__bp_len'/2` (`codegen/erlang.zig:406-424`) already plays.

Each clause body is produced by calling `primMethodNode` (`:3829`) itself with a synthetic
receiver identifier and synthetic argument identifiers — so the shim body *is* the typed path's
output and no lowering logic is duplicated.

- **Cost:** one collector plus one form emitter of roughly the size of `instanceDefaultForms`
  (`:3884`), one branch at `:3571`, and synthetic `ast.Expr`/`ast.Loc` construction (safe here:
  `rewrites` and `instance_lowerings` are both empty, so a synthetic loc cannot collide).
- **Covers:** every method carrying an `@External.Erlang` annotation — i.e. all of **G1** — and,
  because `primMethodNode` also runs `arrayPrimFallbackNode` (`:3845`) and `ifaceDefaultNode`
  (`:3849`), the **G2** tail too, for free and only for the methods actually reached.
- **Breaks:** nothing structurally. The failure mode moves from "`erl_lint` rejects the module" to
  "the shim's last clause raises at evaluation time on a receiver of an unexpected type", which is
  what `'__bp_add'`/`'__bp_len'` already do.
- **Interaction with `instanceDefaultForms`:** a shim clause reaching `ifaceDefaultNode` writes to
  `needed_instance_defaults` (`:3871`). Shim generation must therefore run **before** the drain at
  `:803`, or that drain must be re-entered. The shim generator must also save/set/restore
  `self_prim_kind` per clause the way `instanceDefaultForms` does at `:3897`, so a default body's
  `self.x()` resolves through `selfPrimKind` (`:3565`).
- **`COMPTIME ERLANG` snapshots:** a listing renders `forms.items[decls_start + 1 ..]`
  (`codegen/erlang.zig:851`) and skips the helper block behind `if (!cm.listing)` (`:806`), so
  shims emitted inside that gate never appear in a section. The *call sites* do move
  (`split(…)` → `'__bp_prim_split'(…)`) — but no existing section contains a primitive method
  call, so none changes. See [`primitive-surface.md`](./primitive-surface.md#snapshot-coverage-measured).

## (b) Emit the reached `default fn` bodies (the untyped analogue of `instanceDefaultForms`)

- **Cost:** needs the same missing `PrimKind` to pick the interface, *and* `iface_instance_defaults`
  populated from the embedded prelude. `collectInterfaces` (`:1777`) reads `program.decls` only;
  extending it to the re-parse at `:1614-1621` means deep-copying whole `ast.InterfaceMethod`
  bodies out of that throwaway arena (today only three strings per entry are copied) or keeping the
  arena alive for the emit.
- **Does not cover G1 at all.** `String.split`, `Array.join`, `Array.map` are bodyless `fn`s — there
  is no body to emit. So (b) alone does not fix the reported failure.
- **Reintroduces the bug inside its own output.** `Array.append`'s body
  (`libs/std/src/primitives.bp:693-697`) is `var out = self.slice(…); other.forEach({ y -> out.push(y); })`
  — `out` is a local, not `self`, so `selfPrimKind` cannot help it, and `push` on a local is the
  discarded-mutation defect of [`closure-mutation.md`](./closure-mutation.md).
- **`COMPTIME ERLANG` snapshots:** `instanceDefaultForms` is emitted at `:803`, *above* the
  `cm.listing` gate and after `decls_start` (`:851`), so every body it adds **does** land in the
  listing. Harmless today only because no existing fixture reaches a default; structurally it means
  every future default-fn body shows up in the snapshot of any body that touches it.
- **Verdict:** required as a complement for the G2 tail, wrong as the mechanism. Under (a) it is
  reached automatically and only for what is used.

## (c) Extend the comptime prelude by hand (`comptime_helper_forms`, `codegen/erlang.zig:389`)

- **Cost:** hand-transcribe ~40 methods × up to 5 kinds of Erlang clauses, duplicating
  `libs/std/src/primitives.bp` in Zig. Two sources of truth that will drift: every new
  `@External.Erlang` annotation needs a matching Zig edit. The templates are not trivial —
  `padStart` (`:191`) is a one-line `fun` over `binary:first`, `lastIndexOf` (`:223`) a recursive
  `fun` — and transcription is where the bugs go.
- **Breaks:** nothing, and it needs no interaction with `instanceDefaultForms`. Snapshots are
  untouched (same `!cm.listing` gate at `:806`), though every comptime module grows by the full
  prelude unless it is gated on reached names — which is (a)'s collector anyway.
- **Verdict:** the escape hatch if the milestone needs the six jhonstart names today; not the fix.

## Recommendation

**(a), with (b) reached through it; keep (c) off the table.** (a) is the only option in which
`libs/std/src/primitives.bp` stays the single source of truth, it adds no new lowering logic (the
shim body is `primMethodNode`'s own output), it extends the `'__bp_add'`/`'__bp_len'` precedent the
module already carries, and its forms sit behind the `cm.listing` gate so no green
`COMPTIME ERLANG` section moves.

Fix `codegen/erlang.zig:3053` (`size`, missing next to `len`/`length`) in the same change.

## A fragility the fix rests on

The whole untyped fix rests on the `primitives.bp` re-parse at `codegen/erlang.zig:1617-1620`
succeeding; both `scanAll` and `parse` there are `catch return`, so a parse regression in
`libs/std/src/primitives.bp` would silently empty the dispatch table for **every** module, typed
and untyped. Worth a test that asserts the table is non-empty.
