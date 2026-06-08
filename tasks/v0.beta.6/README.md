# v0.beta.6 — finish stdlib backends + remaining backend/tooling work

> A single carry-forward spec. See [`../AGENTS.md`](../AGENTS.md) for the rules
> (3-layer model, slug, workflow). Live progress → [`status.md`](status.md)
> (this README carries **no** status column).

## Context — where v0.beta.4 left off

v0.beta.4 (`tasks/v0.beta.4/specs/carryover.md`) drove the stdlib-interface
migration's **JS path** to completion: every primitive's instance methods
(`Array`/`Bool`/numeric tower/`String`) and the associated functions
(`Pair.of`, `Function.compose`) now run on node, with `1030/1030` zig tests and
`31/31` `libs/std` tests green. The spec file there grew thick with DONE/PENDING
annotations as the work landed.

## Theme

**Finish what the JS path proved out, everywhere else.** The dispatch and the
codegen pattern are established; this set is the remainder:

- **Part A** — the other backends (erlang/beam/wasm) for the same method
  lowering, plus the dispatch stragglers (`s.contains()`, `Array.range`,
  record-method bodies, companion modules) and inference correctness
  (`default fn` body type-checking, literal receivers).
- **Part B** — the backend-parity F1–F6 features still open from v0.beta.3.
- **Part C** — editor-experience F0–F5 (semantic tokens, inlay hints, VS Code
  task/test integration), none of which is implemented yet.

The single spec: [`specs/stdlib-backends-and-tooling.md`](specs/stdlib-backends-and-tooling.md).
