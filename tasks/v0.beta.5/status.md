# Task status — v0.beta.5

> **Single source of truth for v0.beta.5 state.** The README carries no status
> column — it links here. Regenerate the table with `scripts/status.sh v0.beta.5`
> (run from the repo root; paste the table below, keep this header).

| Spec | Header status | Branch `task/<slug>` | Worktree `.tasks/<slug>` | TODO.md |
|---|---|---|---|---|
| [jhonstart](specs/jhonstart.md) | pending — spec authored; examples landed | not opened | — | F0–F6 (0/7 phases) |
| [rakun](specs/rakun.md) | pending — spec authored; scaffold + examples landed | not opened | — | F0–F6 (0/6 phases) |

## Notes

- **jhonstart** is spec-only so far: the `examples/jhonstart-*` demos document
  intended usage; the `libs/jhonstart` package is **not created yet** (F0). It is
  a *consumer* of `use-await-prefix` + `async-generators` (both pending in
  `tasks/v0.beta.1/`): F0–F3 (core types/builders/hooks/`html` DSL) land once the
  `use` prefix is in `feat`; F4–F5 (SSR/server loaders) gate on the async work.
- **rakun** is spec-only so far: the `libs/rakun` package exists as an **inert
  scaffold** (declarations, `files: []`, not embedded) and `examples/rakun/*`
  document the intended usage. No compiler wiring yet.
- F0–F4 (HTTP types · IoC container · annotations · router) are self-contained.
  F5 (bootstrap) blocks on `libs/server` becoming real HTTP backing — a separate
  task tracked in `libs/server`.
