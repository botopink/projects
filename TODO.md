# botopink-install-from-deps — F0–F6 closeout

> Spec: [`tasks/v0.beta.20/specs/botopink-install-from-deps.md`](../../tasks/v0.beta.20/specs/botopink-install-from-deps.md)

## Baseline

- meta `feat`: `ebd0fcc` (post wasm3-unified-runtime perf).
- bot-lang `feat`: `8f2fdbe` (post wasm3 perf).

## Phases

- [x] **F3 — consumer fixture migration** (8/8 botopink.json on object form)
  - emilia-card `af1c66d`, erika-linq `abfcfe4`, jhonstart-{counter,html,todo} `7a9b0ae`,
    onze `ab7788b`, rakun `ee798f8`, generic-loader-binding `3aecd65`.
- [ ] **F0 — `config.zig` parser extension** — accept legacy array form AND new object form
  - Touch `modules/compiler-cli/src/cli/config.zig` (Dep struct/parse) + tests.
- [ ] **F2 — resolver `$BPMP_HOME` fallback** — added to `libs.zig` search path
  - Touch `modules/compiler-cli/src/cli/libs.zig` + tests.
- [ ] **F1 — `bpmp install` implementation** — fetch deps into CAS, write lockfile, symlink under project
  - Touch `modules/bpmp/src/cli.zig` (`install` subcommand) + `cas.zig` + `lockfile.zig` + tests.
- [ ] **F4 — snapshot e2e** — record a `bpmp install` end-to-end flow against a tiny fixture
- [ ] **F5 — `--frozen` flag** — reject lockfile drift
- [ ] **F6 — AGENTS sweep** — bpmp/AGENTS.md, bpmp/docs.md, cli/AGENTS.md, root AGENTS.md

## Exit gate

- [x] All consumer fixtures on the new schema (F3).
- [ ] `config.zig` accepts both legacy + object form, with parser test coverage.
- [ ] `libs.zig` consults `$BPMP_HOME` fallback when a lib isn't found via the existing resolver.
- [ ] `bpmp install <path>` materializes the dependency closure into `$BPMP_HOME` + writes a `botopink.lock` next to `botopink.json`.
- [ ] `bpmp install --frozen` exits non-zero when `botopink.lock` is missing or out of date.
- [ ] Per-module AGENTS.md updated in the same commit as the code.
- [ ] `zig build test` green.
