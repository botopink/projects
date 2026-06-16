# v0.beta.20 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

## Frente files

| Frente file | Sub-specs | Branch / worktree | State |
|---|---|---|---|
| [frente-a.md](specs/frente-a.md) | 10 — generic-inference-foundation · wat-refactor · beam-inline-prim-methods · erika-runtime-string · future-runtime-erlang-beam · enum-sections (keystones) · primitive-interface-default-fns · typed-method-dispatch · wasm-test-runner (consumers) · closeout | `.tasks/frente-a-tail/` (pending) | pending |
| [prim-op.md](specs/prim-op.md) | 9 — family-2-beam-wat-runtime-ops · family-3-block-builtin · template-instance-methods · external-target-libs-migration · fn-param-default-expansion (keystones) · family-1-beam-wat-prim-methods · when-argc-removal · annotation-tail (consumers) · agents-md-resync (closeout) | `task/prim-op-annotation` + `task/fn-param-default-expansion` (partials) | **partial in-progress** — Family 1 erlang/commonJS landed in v19 (`64a3436`); Family 2 erlang/commonJS landed (`7f8f259` / `f9918b1`); merge from `origin/feat` resolved on `task/prim-op-annotation` (`6b0ae8c`); `task/fn-param-default-expansion` carries 3 docs commits + partial AST plumbing `5f0f1d9` |
| [std-tail.md](specs/std-tail.md) | 2 — followup · option-expect | `task/std-expansion-tail` (partial) | **partial in-progress** — meta `fd3604d` / bot-lang local `6efa449` covers §A2 commonJS+erlang + F0 docs + 4 F4 in-module tails + 8 net-new modules (14 commits); 9 phases + 14 sub-deferrals remain |
| [frente-b.md](specs/frente-b.md) | 3 — rules-tooling-close · test-run-log (keystones) · codegen-break-label (consumer) | `task/frente-b-rules-tooling` (partial) | **partial in-progress** — task branch carries F4F/F4G/F4C/F4I/F5/F6 partials (22 commits ahead `origin/feat`); WIP on `env.zig`/`infer.zig`/`generic_defaults.zig` not yet committed |
| [ci-tail.md](specs/ci-tail.md) | 2 — 01-cleanup · 02-backends-parity | merged into `feat` (6c5e4e1) | **mostly done** — 01-cleanup closed (A0/A4 v19 row → done; B-half AGENTS.md note landed). 02-backends-parity: BEAM asm parity comment + `snap.zig` CRLF/path-sep normalisation + `codegen/erlang.zig` BIF shadow walk extended to record/enum/struct/extend/implement methods + `libs/std/src/erlang.bp` catalog extended (50+ entries via verbose overloads); `shell: bash` on 4 sibling-lib source-test step + `windows-2022 commonJS allow_fail` flipped to `false` across the 4 siblings (W1+W2). **2 residuals deferred**: bot-lang windows-2022 row (W5 — needs runner-side snapshot regen pass first); 4 sibling-lib erlang reds → v0.beta.21 (audit in [`sibling-lib-erlang-codegen-reds.md`](specs/sibling-lib-erlang-codegen-reds.md)). |
| [ecosystem.md](specs/ecosystem.md) | 1 — emilia (F0–F5) | `.tasks/emilia/` (pending) | pending — `repository/emilia` seed `f3b6ef7` pushed to `botopink/emilia` `feat`; submodule wired in meta `.gitmodules` (uncommitted) |

## emilia — per-step state

| Step | Description | State |
|---|---|---|
| F0 | lib stand-up + jhonstart 2 hooks (annotation-on-builder + `[name]={expr}` html attribute) | pending |
| F1 | Token enum (full sections: Text, Font, Color, Bg, Pad, Margin, Layout, Flex, Border, Effect + modifiers) | pending |
| F2 | `tokenToCss` exhaustive match handler | pending |
| F3 | Modifier composition (`.Hover`, `.Focus`, `.Md`, `.Lg`, `.Xl`) | pending |
| F4 | `Stylesheet` host cell + `emilia.flush()` (per-render semantics) | pending |
| F5 | runnable `examples/emilia-card/` + docs sweep | pending |

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
