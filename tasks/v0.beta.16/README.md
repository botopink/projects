# v0.beta.16 — the recorded-gap sweep

> Everything still on the books. Each prior version closed a wave and **recorded** the bits it
> deliberately left for later (in spec "non-goals", in `AGENTS.md` "KNOWN GAP" / "Recorded
> gaps" notes, in backend "Remaining gaps"). This version collects those grounded, deferred
> items into **one unified spec** — nothing invented; every section cites the note it closes.

## The spec

A single, unified spec — [`recorded-gap-sweep`](specs/recorded-gap-sweep.md) — organized into
**file-disjoint sections** (each was a standalone spec before they were merged):

| § | Section | Closes (recorded where) | Area |
|---|---|---|---|
| A | annotation-driven-builtins **(keystone)** | builtin method lowering hardcoded in 4–5 `.zig` (`isNativeProtoMethod`, `jsBuiltinMethodName`, `emitPrimMethod` switches, `primMethodReturnType`) instead of read from `#[@external]`/signatures | parser · codegen ×3 · comptime · `*.d.bp` |
| B | generic-inference | `Self`→primitive kind in interface `default fn` (backends-parity-tail **E**) + generic inline-test cascade (`libs/std/AGENTS.md`) | `comptime/{infer,unify,types}.zig` |
| C | wasm-aggregates | named record-field layout (`self.id`→`i32.const 0`) + `?.` on wasm (`codegen/AGENTS.md`) | `codegen/wat.zig` |
| D | cross-backend-feature-parity | features broken on erlang **and** beam: `new Error`, `console.log`, cross-module fn imports, `*fn` async/await, typed dispatch (`beam_asm.zig` "Remaining gaps") | `codegen/{erlang,beam_asm,commonJS}.zig` |
| E | lsp-definition-tail | tuple `p._0` + interface associated-fn dispatch (v0.beta.15 non-goals) | `language-server/src/engine.zig` |
| F | typescript-dts-templates | `.d.ts` still declares comptime template fns (`codegen/AGENTS.md` KNOWN GAP) | `codegen/typescript.zig` |
| G | erika-dsl-extensions | interpolated queries + string form seeing `var` (`libs/erika/AGENTS.md` "Recorded gaps") | `libs/erika/src/erika.bp` + comptime |

## Ordering / coordination

The sections are file-disjoint and independently shippable, **except** one merge-order rule.
The spec's own *"Cross-section consistency"* block records the full pairwise check; the gist:

- **§A lands first.** It refactors the same emitters (`commonJS`/`erlang`/`beam_asm`) + `infer`
  that §B and §D touch (different functions, same files). Doing the keystone first means those
  build on the annotation-driven base, not the soon-to-be-deleted switches. Acceptance bar =
  **byte-identical emitted output** (pure refactor), so it merges cleanly ahead.
- **§B unblocks the erlang/beam emission** of erika's instance `default fn`s, also tracked by
  `backends-parity-tail` (v0.beta.14) **E** — merge-order them.
- **§D's `console.log`/`new Error`** are the raw host forms (the `print` builtin already lowers
  via `@external`); §D reuses §A's *consult-don't-hardcode* principle, not a new switch.
- Everything else (§C after backends-parity-tail **W**; §E, §F, §G) runs any time.

## Goal

A builtin primitive method is **declared once** (its `#[@external]` annotation + signature in
`primitives.d.bp`/`builtins.d.bp`) and lowers on every backend with no hardcoded `.zig` table.
On that base, the recorded-gap notes shrink: generic interface bodies lower (erika green on
erlang), wasm reads/writes named fields and guards `?.`, the multi-backend feature gaps lower
on erlang+beam, go-to-def reaches `p._0` and interface assoc fns, `.d.ts` stops leaking
template fns, and the erika string DSL handles interpolation + `var`. `zig build test` +
`botopink-lib-test` + `zig build test-libs` stay green throughout.
