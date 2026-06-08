# Task status — v0.beta.6

> **Single source of truth for v0.beta.6 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.6`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [stdlib-backends-and-tooling](specs/stdlib-backends-and-tooling.md) | pending — JS path done (v0.beta.4); backends/dispatch/tooling ahead | `task/stdlib-backends-and-tooling` | `.tasks/stdlib-backends-and-tooling` | Parts A–C |
| [cross-module-codegen](specs/cross-module-codegen.md) | pending — commonJS leg landed; erlang/beam/wasm parity ahead | `task/cross-module-codegen` | `.tasks/cross-module-codegen` | F0–F3 (0/4 phases) |
| [rakun](specs/rakun.md) | pending — rakun foundation landed (`from "rakun"`, `http.bp`, `#[decorator]` resolution) | `task/rakun` | `.tasks/rakun` | F2–F5 (0/4 phases) |
| [jhonstart-language-gaps](specs/jhonstart-language-gaps.md) | pending — 4 blockers verified on `task/jhonstart` | `task/jhonstart-language-gaps` | `.tasks/jhonstart-language-gaps` | F0–F3 (0/4 phases) |
| [implement-completeness](specs/implement-completeness.md) | pending — G5/G6/G7 verified on `task/jhonstart` (G7 = codegen bug) | `task/implement-completeness` | `.tasks/implement-completeness` | F0–F2 (0/3 phases) |
| [mutual-recursion](specs/mutual-recursion.md) | pending — verified on `task/jhonstart` (renderToString) | `task/mutual-recursion` | `.tasks/mutual-recursion` | F0 (0/1 phases) |
| [erika](specs/erika.md) | pending — pure `.bp` std module over `Array<T>` (eager v1); `erika "…"` query string built on `@Expr` | `task/erika` | `.tasks/erika` | F0–F6 (0/7 phases) |

## Notes

- **Already in `feat` (from the rakun work this set builds on):** `from "rakun"`
  opt-in resolution; the real emitted HTTP layer (`libs/rakun/src/http.bp` —
  `Response`/`App`/`HttpMethod`); `#[decorator]` markers resolving to imported
  rakun symbols; and the **commonJS** cross-module codegen leg (`require` paths,
  `new` for imported records, `static` associated fns, `exports.X`). rakun's own
  `http.bp` test passes under `botopink test` on commonJS **and** erlang.
- **cross-module-codegen** is the cross-cutting remainder: erlang cross-*package*
  calls + the beam/wasm backends.
- **rakun** is the rakun framework's actual semantics, one branch, sequential
  phases: F2 IoC container, F3 annotation argument validation, F4 router (the
  markers resolve today but carry no behaviour yet), then F5 bootstrap
  (`Rakun.run` + `libs/server` graduating from scaffold to a real HTTP backing).
  F5 boots F2–F4, so it stays internal to the spec rather than a separate task.
- **jhonstart-language-gaps** are language features surfaced by jhonstart; its
  own F4–F5 (SSR/loaders) stay gated on the async specs in `tasks/v0.beta.1/`.
- **implement-completeness** + **mutual-recursion** were surfaced going deeper on
  jhonstart (attaching `@Context` to `Element`, the recursive renderer): G5/G6/G7
  + forward-reference, continuing the G1–G4 numbering. **G7 is a correctness bug**
  (inline `struct implement` values drop their fields at runtime — latent because
  that form was only typecheck-tested). jhonstart V1 already sidesteps all of them.
