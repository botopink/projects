# v0.beta.20 — closing the v0.beta.19 follow-ups + emilia (CSS lib)

> v0.beta.19 closed every *recorded* gap from v0.beta.12–v0.beta.18 organised
> as three file-disjoint frentes + the std-expansion / std-expansion-tail
> satellites; v0.beta.20 picks up the **deliberately-partial closes** of that
> set (frente-a §A7/§B/§C/§D2-D5/§G2 · frente-b Rules track · prim-op-annotation
> BEAM/wat backend migration · std-expansion-tail's 9 remaining phases + 14
> sub-deferrals) and ships **emilia** — the styled/CSS surface for the
> jhonstart framework — as the v0.beta.20 keystone. Like v0.beta.19, the set
> is organised into file-disjoint specs each runnable on its own worktree.

## Scope

| Spec | Slug | Tracks | Files |
|---|---|---|---|
| [emilia](specs/emilia.md) | `emilia` | new sibling lib (`libs/emilia/`) — `styled`/`css`/`tw` template engines + `Style` carrier + `@Expr`/`@ExprCustom` lowering hooks; jhonstart `attr` carrier + `#attr` parse branch to thread per-component styles | `libs/emilia/**` (new) · `repository/emilia/` submodule wired · `libs/jhonstart/src/element.bp` (attr carrier) · `parser/exprs.zig` (`#attr` branch) · `libs/std/AGENTS.md` (sibling pointer row) |
| [std-expansion-tail-followup](specs/std-expansion-tail-followup.md) | `std-expansion-tail-followup` | finishes the 9 remaining phases + 14 sub-deferrals of `std-expansion-tail` — P1 §A3 `#[@result] declare fn` template-owned wrapper · P2 `time.formatIso8601` · P3 `asserts.matches` · P4 `json` · P5/P6 `array_ext`/`string_ext` (26 methods) · P7/P8 `unicode.codepoints`/`normalize` + `regex.match`/`matchAll` + `record Match` · P9 STD-001 diagnostic · P10 sidecar shipping in `lib_test.zig` · P11–P14 small tails · P15 `fs` · P16 `http` · P17 `random.shuffle` (gated on `Option.expect`) · P18 examples-CLI + per-target coverage · P19 final unification + push | `parser/decls.zig` (R1 relax) · `comptime/{infer,diagnostics}.zig` (§A3 + STD-001) · `compiler-cli/src/cli/lib_test.zig` (sidecar) · 4 new `libs/std/src/*.bp` files + `libs/std/src/sidecars/*.{mjs,erl}` + `primitives.d.bp` (26 methods) + tests across `tests/{codegen,comptime,cli}/` + docs rolls |
| [option-expect](specs/option-expect.md) | `option-expect` | satellite to std-expansion-tail-followup P17 — adds `Option.expect<T>(default: T) -> T` to the `?T` surface in `builtins.d.bp`; unblocks `random.shuffle<T>` and the `at(idx).expect(<sentinel>)` pattern across stdlib (`pick`, `firstCodepoint`, etc.). Pure lift over `unwrapOr` semantically; carries the documentation contract "use when you can prove the index is in bounds" | `libs/std/src/builtins.d.bp` (1 new method on `?T`) · `comptime/infer.zig` (handler arm) · `tests/comptime/option_expect.zig` (new) · AGENTS rows |
| [prim-op-annotation-tail](specs/prim-op-annotation-tail.md) | `prim-op-annotation-tail` | finishes BEAM/wat backend §A2 wiring (mirror of the commonJS+erlang twin landed in std-expansion-tail) — BEAM bytecode templates for the §A6-deferred surface (15 methods × 4 backends → 60 dispatch cells); wat backend's per-callee dispatch gate (template-form recognition; emitter context for the wat instruction encoder); closes the BEAM "irreducible allow-list" carve-out from v0.beta.19 frente-a §A6 | `modules/compiler-core/src/codegen/{beam_asm,wat}.zig` (new `user_*_templates` maps + `tryEmitUserTemplate` mirroring the commonJS/erlang shape) · `libs/std/src/primitives.d.bp` (BEAM/wat external annotations on the 15 methods) · `tests/codegen/prim_op_chained_{beam,wat}.zig` (new fixtures) |
| [frente-a-tail](specs/frente-a-tail.md) | `frente-a-tail` | finishes the v0.beta.19 `frente-a-compiler` deferrals — §A7 BEAM bytecode-template gate (1/4 backends) · §B generic-inference (inline tests in generic modules, erika-LINQ red, registerStdlib gap) · §C wasm-aggregates + wat refactor · §D2–§D5 cross-backend parity remainders (D2 done in upstream c5a4ad3; D3–D5 pending) · §G2 erika runtime-string interpolation (generic compiler mechanism — distinct from §G1's `${…}` template-time form) | `comptime/infer.zig` (generic inference + registerStdlib fix) · `codegen/{beam_asm,wat}.zig` · `comptime/transform.zig` (erika runtime-string lowering) · `tests/comptime/generic_inference.zig` (new) · per-backend snapshots |
| [frente-b-rules-tooling](specs/frente-b-rules-tooling.md) | `frente-b-rules-tooling` | (carry-over from v0.beta.19 — Rules track §0–§4 effect-annotation contract + §E LSP definition tail + §F TS `.d.ts` template skip + §T test-run-log). The spec in v0.beta.19 stays authoritative; v0.beta.20 just gates a worktree on closing it. | `comptime/{infer,transform,contextStack}.zig` · `parser/decls.zig` · `language-server/src/engine.zig` · `codegen/typescript.zig` · test-mode codegen ×4 · `compiler-cli/src/cli/test_cmd.zig` · `lib-test-runner/src/{runner,report}.zig` · `libs/std/src/builtins.d.bp` (§4 mirror) |

## Order

```text
std-expansion-tail-followup ─▶ P1 (§A3 compiler infra) first, unblocks P4 (json),
                              P11 (sleep+throws). P9 (STD-001) and P10 (sidecar
                              shipping) before P15 (fs) + P16 (http). P5/P6/P7/P8
                              are file-disjoint with the others — run in parallel.

option-expect              ─▶ small focused commit; lands BEFORE P17 (random.shuffle)
                              in std-expansion-tail-followup. File-disjoint with
                              every other spec — single addition to builtins.d.bp.

prim-op-annotation-tail    ─▶ finishes the §A2 four-backend story (commonJS+erlang
                              twin landed in std-expansion-tail; BEAM+wat finish
                              here). File-disjoint with std-expansion-tail-followup
                              at the directory level (touches codegen/{beam_asm,
                              wat}.zig).

emilia                     ─▶ keystone v0.beta.20 feature. File-disjoint with the
                              compiler-side specs (touches libs/emilia/** + a
                              jhonstart hook + a `parser/exprs.zig` `#attr` branch).
                              Independent of every other v0.beta.20 spec; runs
                              on its own worktree.

frente-a-tail              ─▶ deep compiler work (generic inference + wat
                              refactor). File-disjoint with everything above at
                              the codegen-file level; sequential with std-expansion-tail-followup's
                              compiler-core edits — schedule after std-tail-followup's
                              P1+P9+P10 land.

frente-b-rules-tooling     ─▶ same spec file as v0.beta.19; opens a v0.beta.20
                              worktree for the unmoved Rules track. File-disjoint
                              with every other v0.beta.20 spec.
```

- **All v0.beta.20 specs are file-disjoint at the directory level** — emilia
  touches `libs/emilia/**`, std-expansion-tail-followup touches `libs/std/**`
  + `comptime/**` + `compiler-cli/cli/lib_test.zig`, option-expect touches
  `libs/std/src/builtins.d.bp` + a single infer arm, prim-op-annotation-tail
  touches `codegen/{beam_asm,wat}.zig` + `primitives.d.bp`. frente-a-tail's
  generic-inference work overlaps `comptime/infer.zig` with
  std-expansion-tail-followup's P1/P9, so they are **sequential** rather
  than parallel on that file.
- **The bot-lang `feat` push to origin** stays the final unification step of
  std-expansion-tail-followup (P19) — per the shared-branch policy that
  blocked the push in the previous session, the user authorises it once
  every v0.beta.19+v0.beta.20 piece is in.

## Carry-forward

v0.beta.20 inherits the **partial close** of std-expansion-tail from the
v0.beta.19 set (meta `task/std-expansion-tail` @ `fd3604d` pushed to
`origin/task/std-expansion-tail`; bot-lang local `feat` @ `6efa449` — 14
commits, not pushed to origin/feat). Every landed surface stays green:
F0 docs + §A2 commonJS+erlang twin + 4 F4 in-module tails + 8 net-new
modules. `std-expansion-tail-followup` closes the remainder without
retouching any landed file.

## Done = the whole set ships

- [ ] `emilia` v0.beta.20 keystone closed + the sibling repo wired into
      the meta as a tracked submodule (`repository/emilia/feat`).
- [ ] `std-expansion-tail-followup` P1–P19 ticked + pushed to feat
      across all 7 repos.
- [ ] `option-expect` merged + pushed (single commit on bot-lang feat).
- [ ] `prim-op-annotation-tail` BEAM + wat dispatch cells parity-green
      on `botopink-lib-test --lib std --target beam,wasm`.
- [ ] `frente-a-tail` §A7/§B/§C/§D3-D5/§G2 all closed or explicitly
      deferred to v0.beta.21.
- [ ] `frente-b-rules-tooling` Rules track §0–§4 + §E + §F + §T merged
      + pushed.
- [ ] `zig build test` + `zig build test-libs` + `botopink-lib-test
      --target all` + `zig build test-vscode` all green across the
      v0.beta.20 close.
