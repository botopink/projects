# v0.beta.20 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

## Frente files

| Frente file | Sub-specs | Branch / worktree | State |
|---|---|---|---|
| [frente-a.md](specs/frente-a.md) | 10 — generic-inference-foundation · wat-refactor · beam-inline-prim-methods · erika-runtime-string · future-runtime-erlang-beam · enum-sections (keystones) · primitive-interface-default-fns · typed-method-dispatch · wasm-test-runner (consumers) · closeout | `.tasks/frente-a/` (partial in-progress) | **partial in-progress** — enum-sections keystone MERGED+PUSHED `origin/feat` via `bd5c69d Merge task/frente-a into feat — enum-sections close` (path-access codegen `d432635` + beam codegen `5d41277` + F3 sync `18c785c` bumped along the way); remaining 9 sub-specs still on `.tasks/frente-a/` worktree (generic-inference-foundation · wat-refactor · beam-inline-prim-methods · erika-runtime-string · future-runtime-erlang-beam · primitive-interface-default-fns · typed-method-dispatch · wasm-test-runner · closeout) |
| [prim-op.md](specs/prim-op.md) | 9 — family-2-beam-wat-runtime-ops · family-3-block-builtin · template-instance-methods · external-target-libs-migration · fn-param-default-expansion (keystones) · family-1-beam-wat-prim-methods · when-argc-removal · annotation-tail (consumers) · agents-md-resync (closeout) | `task/prim-op-annotation` + `task/fn-param-default-expansion` (partials) | **partial in-progress** — Family 1 erlang/commonJS landed in v19 (`64a3436`); Family 2 erlang/commonJS landed (`7f8f259` / `f9918b1`); merge from `origin/feat` resolved on `task/prim-op-annotation` (`6b0ae8c`); `task/fn-param-default-expansion` carries 3 docs commits + partial AST plumbing `5f0f1d9` |
| [std-tail.md](specs/std-tail.md) | 2 — followup · option-expect | merged into `feat` (`08f7467`) | **mostly done** — option-expect closed (`b91495d`); std-expansion-tail-followup at 17/19 phases closed (P1 §A3 `#[@result] declare fn` · P2 time.formatIso8601 · P3 asserts.matches · P4 F5 json V1 · P5 F7.array_ext · P6 F7.string_ext · P7 F7.unicode tails · P8 F7.regex tails · P9 F1 STD-001 runtime check · P10 F2 sidecar shipping · P11 F4.asserts.throws · P12 F4.random.seed + F8.crypto.randomBytes · P13 F6.env tails · P14 F6.os tails · P15 F6.fs · P18 F9 examples-CLI walkthrough · P19 unification sweep + push). **2 residuals deferred to v0.beta.21**: P16 F8.http (needs Promise wrapper sidecar — sync/async contract belongs with `#[@future]` rollout from `frente-a`); P17 F4.random.shuffle (pure-bp Fisher–Yates over generic `Array<T>` is circular). |
| [frente-b.md](specs/frente-b.md) | 3 — rules-tooling-close · test-run-log (keystones) · codegen-break-label (consumer) | merged into `feat` (`df14ef3`) | **partial in-progress** — session 2 MERGED+PUSHED `origin/feat` via `df14ef3 Merge task/frente-b into feat — session 2 (F5 atomic + T0+T2+T3+T4+T5+T2-followup)`; bot-lang 45f341e brings F5 Iterator/IteratorStep atomic + test-run-log T0/T1-{commonJS,erlang}/T2/T3/T4/T5 + T2-followup `duration_ms` + F6-T1/T2/T3 effect_result/effect_generator + F4G enum default-fill consumer-threading + F4F `#[@future]` transform + 4-backend lowering + F4C-RC3 context-getcontex-anchor-violation comptime check + fn-param-default-expansion AST plumbing. Codegen-break-label (consumer) + remaining rules-tooling-close tail still on `task/frente-b` worktree. |
| [ci-tail.md](specs/ci-tail.md) | 2 — 01-cleanup · 02-backends-parity | merged into `feat` (6c5e4e1) | **mostly done** — 01-cleanup closed (A0/A4 v19 row → done; B-half AGENTS.md note landed). 02-backends-parity: BEAM asm parity comment + `snap.zig` CRLF/path-sep normalisation + `codegen/erlang.zig` BIF shadow walk extended to record/enum/struct/extend/implement methods + `libs/std/src/erlang.bp` catalog extended (50+ entries via verbose overloads); `shell: bash` on 4 sibling-lib source-test step + `windows-2022 commonJS allow_fail` flipped to `false` across the 4 siblings (W1+W2). **2 residuals deferred → v0.beta.21**: bot-lang windows-2022 row W4+W5 (audit in [`bot-lang-windows-snap-w5.md`](specs/bot-lang-windows-snap-w5.md) — needs runner-side snapshot regen pass first); 4 sibling-lib erlang reds (audit in [`sibling-lib-erlang-codegen-reds.md`](specs/sibling-lib-erlang-codegen-reds.md)). |
| [ecosystem.md](specs/ecosystem.md) | 1 — emilia (F0–F5) | merged into `feat` (`b188e00`) | **mostly done** — emilia F0/F2/F3/F4/F5 MERGED+PUSHED `origin/feat` via `a62334f` (bump `repository/emilia` → `10ea69e`) + `c1455c9`/`b188e00` (task/emilia merge syncs). v0 ships: Token enum (3 sections flat + 6 modifiers Hover/Focus/Active/Md/Lg/Xl) · `emilia(tokens)` + `flush()` per-render · Hover/Md nesting · `examples/emilia-card/` (13 tests green). **2 residuals deferred**: jhonstart 2 hooks (annotation-on-builder + `[name]={expr}` html attribute) — F0; F1 full nested-section Token enum (Text/Font/Color/Bg/Pad/Margin/Layout/Flex/Border/Effect) unblocked by `bd5c69d` enum-sections close, next session. |

## emilia — per-step state

| Step | Description | State |
|---|---|---|
| F0 | lib stand-up + jhonstart 2 hooks (annotation-on-builder + `[name]={expr}` html attribute) | **partial** — lib stand-up done; 2 jhonstart hooks deferred to next session |
| F1 | Token enum (full sections: Text, Font, Color, Bg, Pad, Margin, Layout, Flex, Border, Effect + modifiers) | **partial** — 3 sections flat (v0) + 6 modifiers (Hover/Focus/Active/Md/Lg/Xl) shipped; full nested-section enum unblocked by `bd5c69d` enum-sections close, next session |
| F2 | `tokenToCss` exhaustive match handler | **done** |
| F3 | Modifier composition (`.Hover`, `.Focus`, `.Md`, `.Lg`, `.Xl`) | **done** — Hover/Md nesting shipped |
| F4 | `Stylesheet` host cell + `emilia.flush()` (per-render semantics) | **done** — `emilia(tokens)` + `flush()` per-render |
| F5 | runnable `examples/emilia-card/` + docs sweep | **done** — `examples/emilia-card/` 13 tests green |

## Done = the whole set ships

### Closing (v19 deferrals)

- [ ] **frente-a** (10 sub-specs): every §A7 / §B / §C / §D2-D5 / §G2 row in `codegen/AGENTS.md` narrows to "done"; cross-backend snapshots regen green; `enum-sections` language extension lands.
- [ ] **prim-op** (9 sub-specs): Family 1/2/3 + instance-methods + §A2 BEAM+wat merged; `when($argc==N)` parse path retired; legacy `@external(target,…)` retired.
- [ ] **std-tail** (2 sub-specs): 9 phases + 14 sub-deferrals merged; `Option.expect<T>` merged.
- [ ] **frente-b** (3 sub-specs): F4F/F4G/F4C/F4I/F5/F6 merged; `break :label` on 4 backends; `----- RUN LOG -----` per test on 4 backends.
- [ ] **ci-tail** (2 sub-specs): all `allow_fail` rows deleted across 5 workflow YAMLs; `test-libs.sh` consolidated to single source.
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test` + `zig build test-vscode` green across every backend incl. wasm via wasmtime.
- [ ] R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4 diagnostics fire (v19 surface still verified).

### Opening (ecosystem)

- [ ] `ecosystem` `emilia` F0–F5 merged + pushed.
- [ ] `repository/emilia` `feat` head tracked by the meta submodule pointer.
- [ ] `repository/jhonstart` `feat` head carries the 2 generic hooks (annotation-on-builder + `[name]={expr}` html attribute).
- [ ] `botopink test` green in `repository/emilia/examples/emilia-card/`.
- [ ] `bpmp install emilia` resolves the lib from its GitHub Releases tag.
- [ ] emilia uses `.Color.Red.500` / `.Pad.X.4` natural path access (enum-sections landed in `frente-a.md`).

### Universal

- [ ] All AGENTS.md updated in the same commit as the code (memory rule).
- [ ] 7 remotes (meta + 6 — now **7** with emilia — submodules) all on unified `feat` heads.
- [ ] `scripts/install-hooks.sh --check` green on a fresh clone (v19 recursive-test-gate also covers `repository/emilia`).
- [ ] `hook-integrity.yml` CI job green on every PR.
