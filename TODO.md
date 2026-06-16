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
  - [x] W-half (drop sibling-lib windows-2022 commonJS `allow_fail`): W2 landed on all 4 sibling libs (erika b84bd3e · jhonstart 0691d0b · onze c56c729 · rakun 99916fd); meta bumped (6c5e4e1). CI confirms green or surfaces a follow-up red.
  - [ ] W-half (bot-lang snap regen + drop windows `allow_fail`): requires an actual windows-2022 runner cycle — `snap.zig` normalisation should clear most CRLF/path-sep drift, but residual snapshots that were recorded on a CRLF host need a windows-side regen. **Deferred** until a green windows-2022 cycle observed; once green, drop the bot-lang `windows-2022` row in `repository/botopink-lang/.github/workflows/test.yml` (W5) as a follow-up commit.
  - [x] E-half catalog: extended `libs/std/src/erlang.bp` with verbose multi-arity overloads (apply/3 · error/2-3 · exit/2 · halt/1-2 · monitor/3 · nodes/1 · send/2-3 · spawn/2-4) + missing single-word entries (erlangGet/0-1 · ports/0 · processes/0). Compact form via `fn-param-default-expansion` (frente-b) can land later as a refactor.
  - [x] E-half emit-shadow coverage: `codegen/erlang.zig` `emitNoAutoImportDirective` walks methods in record/enum/struct/extend/implement (not just top-level fns). Confirmed via `erika.erl` head: `-compile({no_auto_import,[min/2, max/2]}).` now emitted; OTP `ambiguous call` warning gone.

## Coordination

- **frente-b dependency**: catalog extension awaits `fn-param-default-expansion`. Verbose per-arity decls would work today; defer for the compact form.
- **4 sibling-lib erlang reds**: formally tracked in `tasks/v0.beta.20/specs/sibling-lib-erlang-codegen-reds.md` with per-lib root-cause + recommended single follow-up spec in v0.beta.21.

## Exit gate

Per spec — every CI matrix job green across the 7 repos; no `allow_fail` rows on the windows-2022 / erlang-shadowed-BIF axes; v0.beta.19 `ci-pipelines-green` row → done.

**Status:** BIF-shadow axis fully closed — `erlang.zig` now walks every method-bearing decl shape (record/enum/struct/extend/implement), the directive fires off the annotation-driven catalog in `libs/std/src/erlang.bp` (50+ entries after the extension), BEAM asm carries the parity comment, and `erika.erl` head verifies the `-compile({no_auto_import,...})` line landing. windows-2022 commonJS `allow_fail` rows dropped across the 4 sibling libs. Two residuals remain:

1. **bot-lang windows-2022 `allow_fail`** — `snap.zig` normalisation collapses CRLF + `\\` drift in-flight, but the recorded baselines were authored under LF and any residual mismatch still needs a windows-side regen sweep. Drop the row once a windows-2022 cycle confirms green.
2. **4 sibling-lib erlang `allow_fail`** — pre-existing codegen-completion reds (interface dispatch · extension fan-out · HTML DSL · DI primitives · MissingExternalTarget) per `tasks/v0.beta.20/specs/sibling-lib-erlang-codegen-reds.md`; deferred to v0.beta.21.
