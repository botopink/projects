# v0.beta.20 — status

> _Generated, do not edit by hand._ Rollup of git state +
> `.tasks/<slug>/TODO.md` per universal contract. See
> [`AGENTS.md`](../AGENTS.md) §"One fact, one source".

| Spec | Slug | Branch | Worktree | State |
|---|---|---|---|---|
| [frente-a-compiler-tail](specs/frente-a-compiler-tail.md) | `frente-a-compiler-tail` | (pending — likely one worktree per track) | — | pending |
| [ci-pipelines-green-tail](specs/ci-pipelines-green-tail.md) | `ci-pipelines-green-tail` | `task/ci-pipelines-green` (current) — or piggy-back on `.tasks/ci-pipelines-green/` until v0.beta.19's worktree is torn down | `.tasks/ci-pipelines-green/` (carryover) | pending — F0 awaits the OTP 28 run; F1–F4 are sequential edits after F0 confirms green |
| [backends-parity-erlang](specs/backends-parity-erlang.md) | `backends-parity-erlang` | (pending — likely `.tasks/backends-parity-erlang/`) | — | pending |
| [backends-parity-windows](specs/backends-parity-windows.md) | `backends-parity-windows` | (pending — likely `.tasks/backends-parity-windows/`) | — | pending |
| [test-libs-consolidation](specs/test-libs-consolidation.md) | `test-libs-consolidation` | (pending — single meta commit; no dedicated worktree expected) | — | pending |

## Carryover state from v0.beta.19

| v0.beta.19 spec | State at v0.beta.20 kickoff | What v0.beta.20 closes |
|---|---|---|
| `frente-a-compiler` | **partial** (§G1+§D1+§D2(BEAM partial)+§B3+§S+§U+§A6 landed; §A7/§B/§C/§D3-D5/§G2 deferred) | `frente-a-compiler-tail` |
| `ci-pipelines-green` | landed but `status.md` row reads `pending F4 + F5` qualifier from an earlier seed | `ci-pipelines-green-tail` (F4 flips the row to `done`) |
| frente-b-rules-tooling | pending (not v0.beta.20 surface) | n/a |
| frente-c-distribution | **done+merged** (`origin/feat` ← 4957f2d, H8 ops + J2 fork smoke deferred to maintainer) | n/a |
| prim-op-annotation | partial — 9/19 erlang Family 1 byte-identical merged; 4 inline arms + BEAM/commonJS/wat deferred | n/a (carries through v0.beta.20 as a recorded gap) |
| std-expansion | partial — 7/19 modules landed | n/a (std-expansion-tail tracks the rest) |
| std-expansion-tail | pending — F0 + 4×F4 landed (math/asserts/path/random/time tails); F1/F2/§A2/§A3 blockers tracked | n/a (still v0.beta.19 worktree) |
| recursive-test-gate | **done+merged** | n/a |

## Done = the whole set ships

- [ ] `frente-a-compiler-tail` merged + pushed (all 7 tracks closed)
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
