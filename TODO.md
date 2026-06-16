# TODO — frente-b (rules + tooling close)

> Worktree task: closes v0.beta.19 `frente-b-rules-tooling` partial — F4F/F4G/F4C/F4I-tail/F5/F6 + `break :label` 4 backends + §T `----- RUN LOG -----` per test.
>
> Spec: [`tasks/v0.beta.20/specs/frente-b.md`](tasks/v0.beta.20/specs/frente-b.md) — full content of all 3 sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **rules-tooling-close partials landed**: §1G generic-param defaults wired into TypeDef + infer (`3ed957c`) · F4I `Jump.@"break"` widened (`a9f1a6d`) + 4 call sites updated.

## Current head (session 2 close)

- meta: `25f8ec9` (F5 bump → bot-lang `d5f277c`) + meta after T2 bump (see `git log`)
- bot-lang: `a190ee2` (T2+T4 `--json` JSONL + 7 unit tests).

## Session progress (pushed to origin/task/frente-b)

### rules-tooling-close — Stage 01 keystone (partial DONE)

- [x] **F4G-tail** — enum default-fill consumer-threading (bot-lang `cc49f05`). registerEnum ctor return now carries `<T_cell, E_cell>` (mirrors registerRecord); `Env.resolveTypeName` fills fresh vars for typeDef names referenced bare. 2 enum positive tests + 4 Option/Result ast snapshots regenerated.
- [x] **F4F-tail** — `#[@future]` transform + 4-backend lowering. `future_jump_lowerings` map (parallel to result_jump_lowerings); transform rewrites `return <t>;`/`throw <e>;` to `return __bp_future_<resolved|rejected>(<v>);`; commonJS/erlang/beam_asm/wat strip the marker back to native shape (`async function` wraps in commonJS; eager/sync on erlang+beam; wat traps gated on Frente A §D-D4).
- [x] **F4C-tail PARTIAL** — RC3 (context-getcontex-anchor-violation) comptime check in the `@getContex(T)` handler. Compares requested type's `contextBase` vs enclosing fn's `fnContext.base`. Snapshots in node+erlang error dirs.
- [x] **fn-param-default-expansion** — 3 parser tests pin `declare fn (param: type = expr)` form (parser already supported it via shared `parseParam`; tests lock it in for prim-op + ci-tail catalogs).

### F6 — per-effect snapshot suites (3 of 5 DONE)

- [x] **F6-T1 effect_result.zig** — §1 R11/R12 + R11-mirror + throw-mismatch + 3 happy paths (bare jumps, try-catch round-trip, nested `#[@result]` via `try`).
- [x] **F6-T2 effect_future.zig** — §1F RF1-RF5 + 2 happy paths (`fetchUser` shape + `await` unwrap).
- [x] **F6-T3 effect_generator.zig** — §1 RI4 (`yield-label-unbound`) + 3 happy paths (bare/labelled/return-channel). R8 (yield outside generator) noted as follow-up — not enforced at comptime today.

### F5 — Iterator<T,E,C> + IteratorStep — ATOMIC DONE (session 2)

- [x] **F5-T2** (bot-lang `d5f277c`) — `libs/std/src/builtins.d.bp`: Iterator/Iterable/AsyncIterator gain `E = any, C = void` defaulted tail; `next` now returns `IteratorStep<T,E,C>` (Yield/Done/Error). Generic-param defaults pre-wired in `infer.builtinDefaultFilledArgs`.
- [x] **F5-T1** audit — zero `.bp` consumers across libs/tests/examples call `.next()` on an Iterator. One-file change is atomic.
- [x] **F5-T3** codegen — no change today; `loop` lowers to native `for…of`/`.map(...)`. The `IteratorStep` discriminator surfaces only when F4I-tail's transform rewrite materialises `return @IteratorStep.Done/Error(...)`. **Unblocks F4I-T1**.

### test-run-log — T2+T4 landed (session 2)

- [x] **T2** (bot-lang `a190ee2`) — `botopink test --json` captures child stdout, parses §T envelope, emits one JSON object per test on stdout (forward-compatible 5-state parser, RFC 8259 §7 string escaping). End-of-run aggregated `{"event":"summary",…}` record across all modules.
- [x] **T4** — 7 inline unit tests in `test_cmd.zig` (passing/failing/multi-test/multi-line-log paths + parser regressions + JSON-string escaping). Picked up by `zig build test` via `cli_test_mod`. Standalone `tests/cli/test_run_log_*.zig` files in TODO subsumed by inline coverage.
- [x] **T0** — `runtime.captureStdout` was already shipping (all 4 `executeJavaScript/Erlang/BeamAsm/Wat` capture + thread through `codegen.zig`). Marked done on confirmation.

## Still pending (deferred to follow-up sessions)

### rules-tooling-close keystone — remaining items

- [ ] **F4C-tail FULL** — `comptime/contextStack.zig` (new file, Type → Provider scope tracker), RC1 (`context-unbound`) comptime check + runtime trap, `use <hook>(args)` lowering on commonJS (push/pop array) + erlang/beam (process dictionary), `effect_context.zig` snapshot suite.
- [ ] **F4I-tail** — `transform.zig → @IteratorStep` rewrites (NOW UNBLOCKED by F5-T2). `break`/`throw` inside `#[@iterator]` body rewrite to `@IteratorStep.Done(<c>)` / `@IteratorStep.Error(<e>)` / `@IteratorStep.Yield(<t>)`. Per-backend codegen for each variant.
- [ ] **F6-T4 effect_iterator.zig** — §1I `lazyMap` end-to-end (gated on F4I-tail + codegen-break-label).
- [ ] **F6-T5 effect_context.zig** — §1C happy path + RC1/RC2/RC3/RC4/RC5/RC6 (gated on F4C-tail FULL).

### test-run-log keystone — remaining items (T1-{commonJS,erlang}+T2+T3+T4+T5 DONE)

- [x] **T1-commonJS** — bot-lang `e968493`.
- [x] **T1-erlang** — bot-lang `400e71c`.
- [x] **T5** docs — bot-lang `9bb0419`.
- [x] **T3** — bot-lang `2c49630`. `botopink-lib-test --json` splices `"lib":"<name>","target":"<t>"` into every child JSONL record; emits per-cell `{"event":"cell_summary",…}` + final `{"event":"run_summary",…}`. Text-mode per-line prefix deliberately rejected (would corrupt fenced ```` ```logs ```` blocks); cyan stderr header keeps text-mode attribution.
- [ ] **T1-beam** — mirror erlang's shape lowered to BEAM bytecode. ⚠ no `__bp_run_tests` runner exists in `beam_asm.zig` today; this is "write a BEAM bytecode test runner from scratch", not "tweak existing one".
- [ ] **T1-wat** — gated on Frente A §C2 (`botopink test --target wasm` wiring).
- [ ] **T2-followup** — per-test `duration_ms` in the envelope + JSONL (runners need to emit `Date.now()` deltas; currently neither commonJS nor erlang runners track it).

### codegen-break-label — Stage 02 consumer (deferred)

- [ ] Gated on rules-tooling-close F4I-T2/T3 transform rewrite. CP-commonJS / CP-erlang / CP-beam / CP-wat for FSM-targeting break vs inner-loop break dispatch.

## Coordination

- **prim-op overlap on `fn-param-default-expansion`**: prim-op spec owns the codegen consumption; frente-b's parser-side accept is DONE.
- **test-run-log + ci-tail**: ci-tail's snap normalisation (CRLF / path-sep) might need to consider RUN LOG output formatting. Coordinate via `snap.zig` PR review.

## Exit gate

Per spec — F4F/F4G/F4C/F4I/F5/F6 done; `break :label` honors label on commonJS + erlang + beam + wasm; `botopink test` emits `----- RUN LOG -----` per test on all 4 backends. **Sessions 1+2 shipped: F4G-full / F4F-full / F4C-partial(RC3) / F6-T1+T2+T3 / fn-param-default-expansion / F5-atomic / test-run-log T0+T1-{commonJS,erlang}+T2+T3+T4+T5. Remaining: F4C-full / F4I-tail / F6-T4+T5 / codegen-break-label / T1-beam / T1-wat / T2-followup.**
