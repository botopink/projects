# Task status — v0.beta.6

> **Single source of truth for v0.beta.6 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.6`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [stdlib-backends-and-tooling](specs/stdlib-backends-and-tooling.md) | pending — JS path done (v0.beta.4); backends/dispatch/tooling ahead | not opened | — | Parts A–C |
| [cross-module-codegen](specs/cross-module-codegen.md) | pending — commonJS leg landed; erlang/beam/wasm parity ahead | not opened | — | F0–F3 (0/4 phases) |
| [rakun-ioc-web](specs/rakun-ioc-web.md) | pending — rakun foundation landed (`from "rakun"`, `http.bp`, `#[decorator]` resolution) | `task/rakun` | `.tasks/rakun` | F2–F4 (0/3 phases) |
| [rakun-bootstrap](specs/rakun-bootstrap.md) | pending — blocked on `rakun-ioc-web`; needs real `libs/server` | not opened | — | F0–F2 (0/3 phases) |
| [jhonstart-language-gaps](specs/jhonstart-language-gaps.md) | pending — 4 blockers verified on `task/jhonstart` | not opened | — | F0–F3 (0/4 phases) |

## Notes

- **Already in `feat` (from the rakun work this set builds on):** `from "rakun"`
  opt-in resolution; the real emitted HTTP layer (`libs/rakun/src/http.bp` —
  `Response`/`App`/`HttpMethod`); `#[decorator]` markers resolving to imported
  rakun symbols; and the **commonJS** cross-module codegen leg (`require` paths,
  `new` for imported records, `static` associated fns, `exports.X`). rakun's own
  `http.bp` test passes under `botopink test` on commonJS **and** erlang.
- **cross-module-codegen** is the cross-cutting remainder: erlang cross-*package*
  calls + the beam/wasm backends.
- **rakun-ioc-web** is the rakun framework's actual semantics (F2 IoC container,
  F3 annotation argument validation, F4 router) — the markers resolve today but
  carry no behaviour yet.
- **rakun-bootstrap** (F5) blocks on `rakun-ioc-web` and on `libs/server`
  graduating from scaffold to a real HTTP backing.
- **jhonstart-language-gaps** are language features surfaced by jhonstart; its
  own F4–F5 (SSR/loaders) stay gated on the async specs in `tasks/v0.beta.1/`.
