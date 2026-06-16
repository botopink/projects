# TODO — frente-b (rules + tooling close)

> Worktree task: closes v0.beta.19 `frente-b-rules-tooling` partial — F4F/F4G/F4C/F4I-tail/F5/F6 + `break :label` 4 backends + §T `----- RUN LOG -----` per test.
>
> Spec: [`tasks/v0.beta.20/specs/frente-b.md`](tasks/v0.beta.20/specs/frente-b.md) — full content of all 3 sub-specs lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **rules-tooling-close partials landed**: §1G generic-param defaults wired into TypeDef + infer (`3ed957c`) · F4I `Jump.@"break"` widened (`a9f1a6d`) + 4 call sites updated.

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

## Still pending (deferred to follow-up sessions)

### rules-tooling-close keystone — remaining items

- [ ] **F4C-tail FULL** — `comptime/contextStack.zig` (new file, Type → Provider scope tracker), RC1 (`context-unbound`) comptime check + runtime trap, `use <hook>(args)` lowering on commonJS (push/pop array) + erlang/beam (process dictionary), `effect_context.zig` snapshot suite.
- [ ] **F5-tail** — `Iterator<T,E,C>` + `IteratorStep<T,E,C>` migration in `libs/std/src/builtins.d.bp`. ATOMIC across every `libs/<lib>/` `next() -> ?T` consumer + each backend's iterator-loop adapter. Single commit per spec.
- [ ] **F4I-tail** — `transform.zig → @IteratorStep` rewrites (gated on F5-tail). `break`/`throw` inside `#[@iterator]` body rewrite to `@IteratorStep.Done(<c>)` / `@IteratorStep.Error(<e>)` / `@IteratorStep.Yield(<t>)`. Per-backend codegen for each variant.
- [ ] **F6-T4 effect_iterator.zig** — §1I `lazyMap` end-to-end (gated on F4I-tail + codegen-break-label).
- [ ] **F6-T5 effect_context.zig** — §1C happy path + RC1/RC2/RC3/RC4/RC5/RC6 (gated on F4C-tail FULL).

### test-run-log keystone — Stage 01 (deferred)

- [ ] **T0** runtime.captureStdout single shape (existing executeJavaScript/Erlang/BeamAsm/Wat already capture stdout — mostly READY, just thread the result through).
- [ ] **T1-commonJS** — rewrite `__bp_run_tests` in commonJS.zig (~lines 533-555) to emit `TEST <file>:<line> <name>\n----- RUN LOG -----\n\`\`\`logs\n<captured>\n\`\`\`` per test. ⚠ regenerates every `test_runner.snap.md` + every lib that emits the runner.
- [ ] **T1-erlang** — same for `__bp_run_tests` in erlang.zig (~lines 644-675). Uses `io:put_chars/1` with sentinel envelope.
- [ ] **T1-beam** — mirror erlang's shape lowered to BEAM bytecode.
- [ ] **T1-wat** — gated on Frente A §C2 (`botopink test --target wasm` wiring).
- [ ] **T2** test_cmd.zig sentinel parser + `--json` mode (JSONL).
- [ ] **T3** lib-test-runner lib-prefix injection (every line of child stdout) + `lib` JSON field.
- [ ] **T4** new tests/cli/test_run_log_format.zig + tests/cli/test_run_log_json.zig + snapshots/cli/test/.
- [ ] **T5** docs sweep — compiler-cli/AGENTS.md (Test output format), lib-test-runner/AGENTS.md, libs/std/AGENTS.md, compiler-core/AGENTS.md.

### codegen-break-label — Stage 02 consumer (deferred)

- [ ] Gated on rules-tooling-close F4I-T2/T3 transform rewrite. CP-commonJS / CP-erlang / CP-beam / CP-wat for FSM-targeting break vs inner-loop break dispatch.

## Coordination

- **prim-op overlap on `fn-param-default-expansion`**: prim-op spec owns the codegen consumption; frente-b's parser-side accept is DONE.
- **test-run-log + ci-tail**: ci-tail's snap normalisation (CRLF / path-sep) might need to consider RUN LOG output formatting. Coordinate via `snap.zig` PR review.

## Exit gate

Per spec — F4F/F4G/F4C/F4I/F5/F6 done; `break :label` honors label on commonJS + erlang + beam + wasm; `botopink test` emits `----- RUN LOG -----` per test on all 4 backends. **This session shipped: F4G-full / F4F-full / F4C-partial(RC3) / F6-T1+T2+T3 / fn-param-default-expansion. Remaining: F4C-full / F5-tail / F4I-tail / F6-T4+T5 / codegen-break-label / test-run-log full.**
