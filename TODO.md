# TODO — ci-tail (CI cleanup + backends-parity close)

> Worktree task: closes v0.beta.19 `ci-pipelines-green` 2 deferreds + transitional shims. Drops dead infra and flips `allow_fail` to `false` on erlang + windows matrices.
>
> Spec: [`tasks/v0.beta.20/specs/ci-tail.md`](tasks/v0.beta.20/specs/ci-tail.md) — full content of both sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **01-cleanup partials landed**: meta `scripts/test-libs.sh` deleted (`e3b9d3a`) · bot-lang in-tree wrapper canonical · F1 artifact step drop (`c8e1e6d`) · F2 `ERL_AFLAGS` drop (`c8e1e6d`+`7bf9e17`) · F3 `runtime.zig` doc (`08ad75f`).
- **02-backends-parity partials landed**: erlang BIF auto-import directive now **annotation-driven** from `libs/std/src/erlang.bp` (`0568466`) + 4 snapshot regens.

## Sequential — 01 → 02

- [x] **01-cleanup** — closed:
  - [x] B-half: AGENTS.md `scripts/` path note already landed (see `scripts/AGENTS.md` §"`test-libs.sh` lives under botopink-lang"); remaining `test-libs.sh` references are doc-only and historical.
  - [x] A0/A4: `tasks/v0.beta.19/status.md` `ci-pipelines-green` row already reads `done`.
- [ ] **02-backends-parity** — partial done; one half deferred with audit:
  - [x] E-half (BEAM ASM): `codegen/beam_asm.zig` parity comment added — BEAM asm calls are pre-resolved (`{f, X}` / `{extfunc, mod, fn, N}`), so the `no_auto_import` directive does not apply at the asm stage.
  - [ ] E-half (sibling libs): 4 sibling libs (erika · jhonstart · onze · rakun) **deferred to v0.beta.21** — per-lib codegen reds (interface-method dispatch, external-target fan-out, HTML DSL lowering, DI primitives, missing erlang shim) audited in `tasks/v0.beta.20/specs/sibling-lib-erlang-codegen-reds.md`.
  - [x] W-half (sibling libs): `shell: bash` added to the 4 sibling-lib `zig build test-libs ... (source)` steps so `${LIB_NAME}` expansion no longer dies under PowerShell on windows-2022.
  - [x] W-half (snap normalisation): `snap.zig` `normalizeForCompare` collapses CRLF → LF and rewrites `\\` → `/` on path-bearing lines before `std.mem.eql`.
  - [ ] W-half (bot-lang snap regen): requires an actual windows-2022 runner cycle — deferred to a CI cycle post-merge; once green, drop the bot-lang windows `allow_fail` row in a follow-up commit.
  - [ ] W-half (drop sibling-lib windows-2022 commonJS `allow_fail`): pending CI confirmation that `shell: bash` clears the row (mechanical follow-up commit per lib).
  - [ ] Catalog: extend `libs/std/src/erlang.bp` with `spawn/N`, `monitor/N`, `apply/N` once `fn-param-default-expansion` for `declare fn` lands (`frente-b` rules-tooling-close).

## Coordination

- **frente-b dependency**: catalog extension awaits `fn-param-default-expansion`. Verbose per-arity decls would work today; defer for the compact form.
- **4 sibling-lib erlang reds**: formally tracked in `tasks/v0.beta.20/specs/sibling-lib-erlang-codegen-reds.md` with per-lib root-cause + recommended single follow-up spec in v0.beta.21.

## Exit gate

Per spec — every CI matrix job green across the 7 repos; no `allow_fail` rows on the windows-2022 / erlang-shadowed-BIF axes; v0.beta.19 `ci-pipelines-green` row → done. **Partial**: BIF-shadow axis closed for bot-lang (annotation-driven) + BEAM asm (pre-resolved); 4 sibling-lib erlang axes carried forward to v0.beta.21 per the audit. Windows-2022 `allow_fail` rows still pending a CI cycle to confirm `shell: bash` + `snap.zig` normalisation clear them.
