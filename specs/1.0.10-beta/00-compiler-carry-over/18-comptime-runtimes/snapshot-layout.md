# The snapshot re-layout: `codegen/{beam,wat}/{beam,commonJS,erlang,errors,wasm}`

**Decided (85, 2026-09-20): the tree is doubled as asked — option (a) of § 7; `git mv` into `beam/`, `wat/` recorded once and audited pair by pair, the harness asserting pair equality; § 6's (b) stands for `comptime/`.**

The directory rule, the harness change, the migration, the doubled counts, and how a per-runtime
difference is reported. Counts measured 2026-09-20 ([`evidence.md`](./evidence.md) E-6).

## 1. Today

| Tree | Files | Bytes | Chosen at |
|---|---:|---:|---|
| `snapshots/codegen/beam/` | 333 | 1 392 160 | `codegen/snapshot.zig:205` — `"codegen/{s}/{s}"` with `@tagName(cfg.targetSource)`, `slug` |
| `snapshots/codegen/commonJS/` | 334 | 531 326 | same |
| `snapshots/codegen/erlang/` | 334 | 375 431 | same |
| `snapshots/codegen/wasm/` | 333 | 1 387 012 | same |
| `snapshots/codegen/errors/{beam,commonJS,erlang,wasm}/` | 3 each = 12 | 3 280 | `codegen/snapshot.zig:230` — `"codegen/errors/{s}/{s}"` |
| **total codegen** | **1 346** | **3 689 209** | |
| `snapshots/comptime/ast/` | 202 | | `comptime/snapshot.zig:1509` — `"comptime/ast/{s}"` |
| `snapshots/comptime/errors/` | 137 | | `comptime/tests/helpers.zig:249` |
| `snapshots/comptime/templates/` | 1 | | `comptime/tests/templates.zig` |

Every `assertJs*` in `codegen/tests/helpers.zig` loops `configs` (`:19-36`: commonJS, erlang, beam,
wasm) and calls `snap.assertCodegen` per target (`:198`); `snap.zig`'s `checkText`
(`utils/snap.zig:46`) prefixes `snapshots/` and compares (`compareOrCreate`, `:138`): missing →
`<snap>.new` written and `error.SnapshotMissing` unless `BOTOPINK_SNAP_CREATE=1` (`:67`, `:142-155`);
mismatch → `<snap>.new` written, `error.SnapshotMismatch` (`:182-207`).

Sections that depend on the **comptime runtime**: `COMPTIME ERLANG` (the listing) and
`COMPTIME REPLY` (the reply), written by `writeComptimeSections` (`codegen/snapshot.zig:45`) from
`result.comptime_trace`. They exist in **7** files per codegen target (28) and **5** in
`comptime/ast/`. `COMPTIME VALUES` (11 in `codegen/beam`) is Zig-folded; `RUN LOG` (324 in `beam`,
324 in `wasm`) is the *target's* VM. Neither can differ per comptime runtime.

The layout `codegen/<runtime>/<target>/` existed until 2026-09-15 as `legacyRuntimeTag`, a 1:1 alias
(`node/commonJS`, `erlang/erlang`, `beam/beam`, `wasm/wasm`) kept "purely to leave the on-disk tree
byte-identical", then flattened; `comptime/{node,erlang,beam,wasm}/` (four byte-identical copies)
was collapsed to `comptime/ast/` on 2026-09-18. The tree this front creates is the first one where
the runtime level is a real second axis.

## 2. The rule

```
snapshots/codegen/<comptime runtime>/<target>/<slug>.snap.md
snapshots/codegen/<comptime runtime>/errors/<target>/<slug>.snap.md
```

with `<comptime runtime>` ∈ `{beam, wat}` = `@tagName(runtime.ComptimeRuntime)`. Section names
inside a file follow the runtime: `COMPTIME BEAM ASSEMBLY` under `beam/`, `COMPTIME WAT` under
`wat/`; `COMPTIME REPLY` keeps its name in both (it is the assertion that they are equal).

## 3. The harness change (not a `mv`)

| File | Change |
|---|---|
| `codegen/config.zig` | `Config` gains `comptime_runtime: ComptimeRuntime` (the field the 2026-09-15 comment says was removed — it returns with a meaning: which runtime evaluated the comptime sections of this generation) |
| `codegen/snapshot.zig:205` | `"codegen/{s}/{s}/{s}"` ← `@tagName(cfg.comptime_runtime)`, `@tagName(cfg.targetSource)`, `slug` |
| `codegen/snapshot.zig:230` | `"codegen/{s}/errors/{s}/{s}"` |
| `codegen/snapshot.zig:45` | the section header text from the runtime (`COMPTIME BEAM ASSEMBLY` / `COMPTIME WAT`) |
| `codegen/tests/helpers.zig:19-36` | `configs` becomes `targets × runtimes` (4 × 2 = 8 entries) generated at comptime; `:198` loops all 8; H10's "compare every backend before failing" keeps its shape |
| `comptime/snapshot.zig:1509` | `"comptime/ast/{s}"` unchanged for the 197 runtime-independent files; the 5 with a comptime trace are asserted per runtime — see § 6 |
| `comptime.zig` / `codegen.zig:79-81` | the runtime reaches the evaluators through `Config`, not a global, so two generations in one test process can use different runtimes |
| `scripts/snap_audit.sh:134-141`, `:496` | `backendOf` parses `codegen/<rt>/<target>` and `codegen/<rt>/errors/<target>`; gains `--mode=runtime-parity` (§ 5) |
| `scripts/beam_export_audit.sh:48` | `snap_dir` → `snapshots/codegen/beam/beam` (the beam-runtime copy is the audited one; the audit is about the *target*) |
| `codegen/tests/AGENTS.md:24`, `:49`; `codegen/AGENTS.md:1272`, `:1453`, `:1858`; `scripts/AGENTS.md:232` | path text |

## 4. Migration

```
cd modules/compiler-core/snapshots/codegen
git mv beam     _beam_target && mkdir beam && git mv _beam_target beam/beam
git mv commonJS beam/commonJS
git mv erlang   beam/erlang
git mv wasm     beam/wasm
git mv errors   beam/errors
```

then, in the 28 files with a `COMPTIME ERLANG` section, the header line becomes
`----- COMPTIME BEAM ASSEMBLY -- …` and the fenced body becomes the `.S` listing of step 1b — that
part is a **content** change and lands in step 1's commit, not the layout commit. The layout commit
is proven byte-identical the way the 2026-09-18 collapse was: `md5sum` of every file before and after,
1 346 paths, the same 1 346 sums.

Then the first `wat/` recording:

```
BOTOPINK_SNAP_CREATE=1 zig build test -Dtest-filter=codegen      # writes snapshots/codegen/wat/**
scripts/snap_audit.sh --mode=runtime-parity                       # § 5; must exit 0 before the commit
```

`BOTOPINK_SNAP_CREATE` is used exactly once, for the paths that do not exist yet; a missing `beam/`
file is still a failure (spec 06 H4 stays).

## 5. How a per-runtime difference is reported

Three layers, each failing loudly:

1. **The snapshot itself.** Under `wat/`, a fixture whose reply differs from the recorded one fails
   with `error.SnapshotMismatch` and a `.snap.md.new` beside it — the ordinary contract.
2. **`parity.zig`** (step 3): the same fixtures run under both runtimes in one process, `Response`
   bytes compared, both replies printed on a difference. This catches a divergence before either
   snapshot is recorded.
3. **`scripts/snap_audit.sh --mode=runtime-parity`**: for every `beam/<t>/<slug>` and `wat/<t>/<slug>`
   pair, `diff` after stripping the `COMPTIME BEAM ASSEMBLY`/`COMPTIME WAT` fenced bodies (the
   listings are *expected* to differ); any remaining difference — a `COMPTIME REPLY`, a `RUN LOG`,
   generated code, a `COMPILE DIAGNOSTIC` — is printed as a unified diff and the audit exits 1. A
   missing pair member is also exit 1. This runs in `scripts/gate.sh` after `zig build test`.

A difference is a defect in one runtime — usually the wat one, the BEAM being the reference — and
is fixed there; it is never accepted by re-recording `wat/` alone. The audit has no allow-list
(decision 67).

## 6. `comptime/` under the split

`comptime/ast/*.snap.md` carry `TYPED AST JSON` and, in 5 files, the runtime exchange. Options were
(a) double all 202 (what 2026-09-18 undid), (b) double only the 5 — under `comptime/ast/<slug>` for
the AST and `comptime/runtime/{beam,wat}/<slug>` for the 5 exchanges, (c) leave `comptime/ast/`
recording the BEAM exchange and rely on `parity.zig` for wat. This front takes **(b)**: the AST is
runtime-independent by construction and stays single; the 5 exchanges become 10 files whose replies
the audit compares like the codegen pairs. `comptime/errors/` (137) and `comptime/templates/` (1)
carry no runtime section and do not move. This is the mirror of README question 3 for the
`comptime/` tree; decision 85 answered (a) there, and (b) here is its application to a tree whose
AST half cannot differ.

## 7. The doubled counts

| | before | after (decision 85 — option a, taken) | after (option c, not taken) |
|---|---:|---:|---:|
| `codegen/` files | 1 346 | **2 692** | 1 346 + 28 = 1 374 |
| `codegen/` bytes | 3.69 MB | ≈ 7.4 MB | ≈ 3.8 MB |
| pairs that may legitimately differ (listing only) | — | 28 | 28 |
| pairs that must be byte-identical | — | 1 318 | — |
| `comptime/` files | 340 | 345 | 345 |
| generations per `assertJs*` | 4 | 8 | 8 |
| RUN LOG executions per `assertJs*` | 4 (content-cached, `runtime.zig:244`) | 4 + 4 cache hits | same |

The suite's wall time doubles its **codegen** share, not its execution share: the second runtime's
generation produces the same target text, so `cacheKey(target, module, code)` hits. The current suite
time is not recorded in any `AGENTS.md` (E-12); step 0 measures it and step 4's acceptance records
the ratio.

## 8. Sibling worktrees and sequencing

At measurement `.tasks/wasm` held 6 modified `codegen/wasm/loop_*.snap.md` and `.tasks/tooling` one
LSP snapshot; both are in `feat`, with `.tasks/formatter`. `.tasks/beammem`,
`.tasks/ecosystem`, `.tasks/identity` remain with staged, uncommitted work whose pre-commit hooks
fail (a compile error; 8 and 7 snapshot mismatches respectively — `codegen/erlang/external_*` for
identity, string/std-package fixtures for ecosystem). Any of those that lands *after* the layout
commit conflicts on every snapshot it touches (rename vs. modify — git resolves it as a modify under
the new path if the rename is detected, and it is: 1 346 pure renames). The order that costs least:
land the surviving worktrees first (their snapshot edits are few), then the layout commit; if the
layout must go first, their edits are re-applied by `git mv`-aware rebase (`git rebase
--rebase-merges` detects the renames). C-01 (`.tasks/identity`) re-records ≈ 318 cells under
`codegen/{erlang,beam}/` — under the new tree that is 318 × 2 files (decision 85; option (c) would
have made it 318 again).
