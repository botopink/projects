# v0.beta.16 — status

> The recorded-gap sweep: **one unified spec** ([`recorded-gap-sweep`](specs/recorded-gap-sweep.md))
> with seven file-disjoint sections (§A–§G), each closing a cited `AGENTS.md` / non-goals note.
> No worktrees yet — spun up from `feat` when the wave activates (earlier-wave pattern). None
> implemented.

| § | Section | Closes | State |
|---|---|---|---|
| A | annotation-driven-builtins **(keystone)** | `.d.bp` `#[@external]`/signature as single source of truth for builtin method lowering (delete `isNativeProtoMethod`/`jsBuiltinMethodName`/`primMethodReturnType`/`emitPrimMethod` switches) | pending |
| B | generic-inference | `Self`→kind in interface `default fn` + generic inline-test cascade | pending |
| C | wasm-aggregates | wasm named record-field layout + `?.` | pending |
| D | cross-backend-feature-parity | erlang+beam: `new Error`/`console.log`/cross-module fn/`*fn`/typed dispatch | pending |
| E | lsp-definition-tail | go-to-def for `p._0` + interface assoc fns | pending |
| F | typescript-dts-templates | drop template fns from `.d.ts` | pending |
| G | erika-dsl-extensions | interpolated queries + `var` string form | pending |

## Coordination notes (full pairwise check in the spec's "Cross-section consistency" block)

- **§A lands first** — pure refactor (byte-identical emitted output) over the emitters + `infer`
  that §D and §B also touch (different functions, same files); merge it ahead so they extend the
  annotation-driven base, not the hardcoded switches.
- **§B ↔ backends-parity-tail (v0.beta.14) E** — inference unblock here; the erlang/beam emission
  of erika instance `default fn`s can land in either; merge-order them.
- **§C after backends-parity-tail W** — loops must compile before field-bearing method bodies.
- **§E after v0.beta.15** — extends the `lsp-definition-completeness` member-resolution machinery.
- No section contradicts another (verified): the only ordering constraint is §A before §B/§D;
  §C/§E/§F/§G are independently shippable.

_Done = the cited gap notes shrink, each section's "What changes (before → after)" examples hold,
and `zig build test` + `botopink-lib-test` + `zig build test-libs` stay green._
