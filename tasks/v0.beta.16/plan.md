# v0.beta.16 — plan

## Premise

The roadmap has been run as **waves of disjoint specs**, and every wave deliberately recorded
what it left behind rather than faking it — that discipline is exactly what makes this version
possible. v0.beta.16 is the **sweep**: it gathers the genuinely-deferred, genuinely-recorded
gaps into **one unified spec** ([`recorded-gap-sweep`](specs/recorded-gap-sweep.md)) with
file-disjoint sections §A–§G. Nothing here is invented; each section cites the `AGENTS.md`
"KNOWN GAP" / "Recorded gaps" / backend "Remaining gaps" note, or the prior spec's "non-goals",
that it closes.

## How the items were sourced

Each section maps to a recorded note:

- `annotation-driven-builtins` ← the **keystone**: `primitives.d.bp` already declares every
  primitive method with `#[@external(erlang, "lists", "reverse"), @external(node, …)]` and a
  real signature, but the emitters ignore it and re-hardcode the same knowledge in
  `commonJS.zig` (`isNativeProtoMethod`, `jsBuiltinMethodName`, `jsPrototypeOwner`),
  `erlang.zig`/`beam_asm.zig` (`emitPrimMethod` name switches), and `infer.zig`
  (`primMethodReturnType` return-type switch, `jsStringMethodRename`/`jsMethodRenames`).
  Adding a method touches 4–5 `.zig` files instead of one `.d.bp` line; the `.zig` even
  overrides the annotation (`reverse` is both `@external(node, "./gleam_stdlib.mjs", …)` *and*
  in `isNativeProtoMethod`). Make the annotation + signature the single source of truth.
- `generic-inference` ← backends-parity-tail **E** ("blocked on generic-inference") +
  `libs/std/AGENTS.md` generic-module inline-test caveat.
- `wasm-aggregates` ← `codegen/AGENTS.md` `wat.zig` ("self.id → i32.const 0", "`?.`
  unsupported on wasm") + the branch backends-parity-tail **W** punts.
- `cross-backend-feature-parity` ← `beam_asm.zig` AGENTS "Remaining gaps … also broken on
  Erlang" (`new Error`, `console.log`, cross-module fn imports, `*fn` async/await,
  typed-value dispatch).
- `lsp-definition-tail` ← v0.beta.15 `lsp-definition-completeness` non-goals (tuple fields,
  interface assoc dispatch).
- `typescript-dts-templates` ← `codegen/AGENTS.md` KNOWN GAP (`.d.ts` still declares template
  fns).
- `erika-dsl-extensions` ← `libs/erika/AGENTS.md` "Recorded gaps" (interpolated queries, `var`
  string form).

## Method

Run as a wave: the seven sections are **file-disjoint** (parser+codegen+comptime / comptime /
wat / erlang+beam / typescript / language-server / erika). Although they live in one spec file,
each section can still be a separate `.tasks/<slug>` worktree spun up when the wave starts —
same pattern as the earlier waves (worktrees created from `feat` at activation time, `TODO.md`
overwritten with the section + checklist; see [[project_worktree_workflow]] and
[[feedback_task_todo_md]]). The spec's *"Cross-section consistency"* block verifies no section
contradicts another and pins the one ordering constraint (§A first).

**Each section carries a "What changes (before → after)" section** with concrete `.bp` + emitted
output, so the done-state is observable, not abstract.

Ordering by leverage:
1. **§A annotation-driven-builtins** first — the keystone refactor. It touches the same emitters
   + `infer` that §D and §B extend, so landing it first lets them build on the annotation-driven
   base instead of the hardcoded switches. Pure refactor (byte-identical output) → merges ahead.
2. **§B generic-inference** — the long pole that also unblocks the erlang/beam erika emission
   tracked by backends-parity-tail.
3. **§C wasm-aggregates** after backends-parity-tail **W** (loops must compile first).
4. The rest (**§D** cross-backend-feature-parity, **§E** lsp-definition-tail, **§F** typescript-
   dts-templates, **§G** erika-dsl-extensions) are independent and can run any time — §D benefits
   from the keystone (its `console.log`/`new Error` items become declare-and-consult, not a switch).

## Risks / coordination

- **Keystone merges first.** `annotation-driven-builtins` is a refactor with a **byte-identical
  output** acceptance bar (snapshot diff empty). Land it before the emitter-touching specs so
  they extend the annotation-driven base, not the hardcoded switches it deletes.
- **Don't lose the irreducible inline cases.** A few erlang/beam lowerings are real logic, not
  a symbol map (`indexOf` fold, `join` stringify, `at` bounds check, `slice` arithmetic) —
  keep them, explicitly marked as exceptions; the goal is killing the *symbol-map* hardcoding,
  not zero inline code. Prefer pure-botopink `default fn` bodies (like `range`/`repeat`) where
  the backend can lower the body.
- **generic-inference ↔ backends-parity-tail E.** The inference unblock lives in this spec;
  the erlang/beam *emission* of erika's instance `default fn`s can land in either task —
  coordinate by merge order so neither re-does the other's work.
- **No core coupling.** The erika `var`-snapshot item touches core comptime; keep it generic
  (no `erika`/lib names in core — see [[feedback_compiler_unaware_of_jhonstart]] and
  [[feedback_no_lib_specific_in_core]]).
- **`.d.bp` discipline / declaration surfaces** unchanged; the typescript `.d.ts` drop only
  removes comptime-only template fns, nothing real.
- **Record limits, don't fake them.** `*fn` async/await on erlang/beam and wasm cross-module
  linking may exceed this wave — if so, record the precise boundary (the house rule that made
  this version authorable in the first place).

## Done means

The recorded-gap notes named above are removed or shrunk; each spec's "What changes" examples
hold; `zig build test` + `botopink-lib-test` + `zig build test-libs` stay green; the touched
`AGENTS.md` files are updated in the same commits.
