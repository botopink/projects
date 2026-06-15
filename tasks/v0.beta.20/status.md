# v0.beta.20 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

### frente-a-compiler-tail family (10 specs)

| Spec | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [generic-inference-foundation](specs/generic-inference-foundation.md) | `generic-inference-foundation` | (pending — keystone) | — | pending |
| [primitive-interface-default-fns](specs/primitive-interface-default-fns.md) | `primitive-interface-default-fns` | (pending; depends on generic-inference-foundation) | — | pending |
| [wat-refactor](specs/wat-refactor.md) | `wat-refactor` | (pending) | — | pending |
| [wasm-test-runner](specs/wasm-test-runner.md) | `wasm-test-runner` | (pending; depends on wat-refactor) | — | pending |
| [prim-op-template-instance-methods](specs/prim-op-template-instance-methods.md) | `prim-op-template-instance-methods` | (pending) | — | pending |
| [typed-method-dispatch](specs/typed-method-dispatch.md) | `typed-method-dispatch` | (pending; depends on generic-inference-foundation) | — | pending |
| [future-runtime-erlang-beam](specs/future-runtime-erlang-beam.md) | `future-runtime-erlang-beam` | (pending) | — | pending |
| [beam-inline-prim-methods](specs/beam-inline-prim-methods.md) | `beam-inline-prim-methods` | (pending) | — | pending |
| [erika-runtime-string](specs/erika-runtime-string.md) | `erika-runtime-string` | (pending) | — | pending |
| [cross-backend-snapshots-sweep](specs/cross-backend-snapshots-sweep.md) | `cross-backend-snapshots-sweep` | (pending — sweep at the end) | — | pending |

### ci-pipelines-green family (4 specs)

| Spec | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [ci-pipelines-green-tail](specs/ci-pipelines-green-tail.md) | `ci-pipelines-green-tail` | `task/ci-pipelines-green` | `.tasks/ci-pipelines-green/` | **done** — F0 confirmed green (all 7 workflows succeed on `feat`); F1 dropped the snap-diff artifact upload step (c8e1e6d); F2 dropped `ERL_AFLAGS` from both bot-lang/test.yml + meta/hook-integrity.yml (c8e1e6d + 7bf9e17); F3 documented the runtime.zig stdout-only RUN LOG contract (08ad75f); F4 flipped the v0.beta.19/status.md row to `done` (7bf9e17) |
| [backends-parity-erlang](specs/backends-parity-erlang.md) | `backends-parity-erlang` | (pending — likely `.tasks/backends-parity-erlang/`) | — | pending |
| [backends-parity-windows](specs/backends-parity-windows.md) | `backends-parity-windows` | (pending — likely `.tasks/backends-parity-windows/`) | — | pending |
| [test-libs-consolidation](specs/test-libs-consolidation.md) | `test-libs-consolidation` | `task/ci-pipelines-green` (piggy-back) | `.tasks/ci-pipelines-green/` (carryover) | **done** — deleted `<meta>/scripts/test-libs.sh`; bot-lang's `repository/botopink-lang/scripts/test-libs.sh` is the single source. scripts/AGENTS.md gained the path-note section; bot-lang AGENTS.md hyperlink updated to bot-lang's own copy. Three callers verified: build.zig already uses the in-tree relative path (no change needed); scripts/git-hooks/lib/runners/botopink-lang.sh's prose comment works for either copy (no change needed). |

## Carryover state from v0.beta.19

| v0.beta.19 spec | State at v0.beta.20 kickoff | What v0.beta.20 closes |
|---|---|---|
| `frente-a-compiler` | **partial** (§G1+§D1+§D2(BEAM partial)+§B3+§S+§U+§A6 landed; §A7/§B/§C/§D3-D5/§G2 deferred) | the 10-spec frente-a-tail family (see top table) |
| `ci-pipelines-green` | landed but `status.md` row reads `pending F4 + F5` qualifier from an earlier seed | `ci-pipelines-green-tail` (F4 flips the row to `done`) |
| frente-b-rules-tooling | pending (not v0.beta.20 surface) | n/a |
| frente-c-distribution | **done+merged** (`origin/feat` ← 4957f2d, H8 ops + J2 fork smoke deferred to maintainer) | n/a |
| prim-op-annotation | partial — 9/19 erlang Family 1 byte-identical merged; 4 inline arms + BEAM/commonJS/wat deferred | n/a (carries through v0.beta.20 as a recorded gap) |
| std-expansion | partial — 7/19 modules landed | n/a (std-expansion-tail tracks the rest) |
| std-expansion-tail | pending — F0 + 4×F4 landed (math/asserts/path/random/time tails); F1/F2/§A2/§A3 blockers tracked | n/a (still v0.beta.19 worktree) |
| recursive-test-gate | **done+merged** | n/a |

## Done = the whole set ships

- [ ] frente-a-tail family (10 specs) all merged + pushed:
      generic-inference-foundation · primitive-interface-default-fns ·
      wat-refactor · wasm-test-runner · prim-op-template-instance-methods ·
      typed-method-dispatch · future-runtime-erlang-beam ·
      beam-inline-prim-methods · erika-runtime-string ·
      cross-backend-snapshots-sweep
- [ ] `ci-pipelines-green-tail` merged + pushed (diagnostic shim
      removed, `ERL_AFLAGS` removed, runtime.zig contract documented,
      v0.beta.19 status.md `ci-pipelines-green` row → `done`)
- [ ] `backends-parity-erlang` merged + pushed (BIF directive emitted
      across erlang.zig + beam_asm.zig + snapshots regen + lib
      workflows drop the allow_fail rows)
- [ ] `backends-parity-windows` merged + pushed (sibling-lib shell-var
      fix + bot-lang snap.zig normalisation + windows allow_fail drop
      across the org)
- [ ] `test-libs-consolidation` merged + pushed (single source of
      truth at `repository/botopink-lang/scripts/test-libs.sh`)
- [ ] `gh run list --workflow test --branch feat --limit 1` on every
      repo + `gh run list --workflow hook-integrity --branch feat
      --limit 1` on meta all report `success` **without** any
      `allow_fail` carve-outs.
