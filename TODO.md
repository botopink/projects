# TODO — std-tail (std-expansion follow-ups + Option.expect<T>)

> Worktree task: closes v0.beta.19 `std-expansion-tail` partial — the 9 phases + 14 sub-deferrals from std-expansion-tail-followup, plus the additive `Option.expect<T>` method.
>
> **Status (as of bot-lang `1791337`):** 17/19 phases closed (P19 push
> landed alongside ci-tail closeout). P16 (http) + P17 (random.shuffle)
> formally deferred to v0.beta.21 — both wait on language features
> (`#[@future]` rollout from `frente-a`, generic-fn declare).
>
> Spec: [`tasks/v0.beta.20/specs/std-tail.md`](tasks/v0.beta.20/specs/std-tail.md) — full content lives there.

## Baseline (from origin/feat after prim-op-template-fix merge)

- meta: `932256a` · bot-lang: `f57a8cd`
- **std·erlang test-libs red CLEARED** by prim-op-template-fix (`emitStringifyOpen`/`Close` added to all 6 erlang Ctx structs).
- **4 sibling-lib erlang reds remain DEFERRED** — erika/jhonstart/onze/rakun (LINQ method lowering / HTML DSL imports / JS-only runtimes). Tracked in `std-tail.md` lib×backend table. **NOT scope for this worktree** — handled by `ci-tail 02-backends-parity`.

## Flat — both sub-specs run in parallel

- [x] **option-expect** — `Option.expect<T>(default: T) -> T` on `?T` (b91495d).
  Compiler arm in `inferResultOptionMethod` routes to the same
  `MethodLowering.Op.unwrapOr` lowering; zero codegen changes; 4 backend
  snapshots pinned.
- [~] **std-expansion-tail-followup** — partial close (16/19 phases landed):
  - [x] F3 / **P1** §A3 `#[@result] declare fn` template-owned wrapper
        (parser/decls R1 relaxed when `@external` is present + matching
        infer arm + `result-template-shape-mismatch` diag registered;
        round-trip fixture green on commonJS + Erlang).
  - [x] **P2** time.formatIso8601 (Node `toISOString` / Erlang
        `calendar:system_time_to_rfc3339`).
  - [x] **P3** asserts.matches (regex-backed, self-contained — duplicates
        the regex.bp template inline rather than cross-imports).
  - [x] **P5** F7.array_ext — `some`/`every`/`flat` aliases + net-new
        `findIndex`/`fill`/`chunked`/`sliding`/`unique`/`zip`. LSP +
        snapshot updated.
  - [x] **P6** F7.string_ext — 9 net-new String methods
        (`padStart`/`padEnd`/`repeat`/`replaceAll`/`chars`/`lines`/`words`/
        `charCodeAt`/`lastIndexOf`).
  - [x] **P7** F7.unicode tails (`codepoints` + `NormalizationForm` enum +
        `normalize`).
  - [x] **P8** F7.regex tails (`record Match` + `match` + `matchAll`).
  - [x] **P13** F6.env tails (`args()` + `vars()`).
  - [x] **P14** F6.os tails (`record UserInfo` + `userInfo()` + `eol()`).
  - [x] **P9** F1 STD-001 — diagnostic constant + `all_codes` row +
        runtime check: `comptime.compile` threads `target_name: ?[]const u8`
        through `analyzeSource` → `Env.target`; `markStdImports` walks
        `Env.stdModuleFns` (populated in `registerStdlib`) and reds
        `std-unsupported-on-target: std/<m>.<fn> has no \`@external\` for
        target '<t>'` on the first host-bound declare without a target
        match. `codegen.generate` + `cli/check.zig` forward `node` /
        `erlang` / `wasm`; LSP + comptime tests pass `null`. 3 new
        unit tests in `tests/std_target_gating.zig`.
  - [x] **P10** F2 sidecar shipping infra — `shipMjsSidecars` probes
        `<lib>/src/sidecars/<base>` first; `libs/std/AGENTS.md` documents
        the convention. Unblocks P12/P15/P16.
  - [x] **P4** F5 json (V1) — `parse(s) -> @Result<string, string>` +
        `stringify` via §A3. Validates + canonicalises; full `JsonValue`
        enum walker deferred.
  - [x] **P11** F4.asserts.throws — `tryCatch` §A3 wrapper + `throws`
        pure-bp; sleep deferred (sync vs async @future contract).
  - [x] **P12** F4.random.seed + F8.crypto.randomBytes — Mulberry32
        sidecar at `libs/std/src/sidecars/random.mjs`; `seed` flips a
        module-local switch so subsequent `seededFloat` reads from the
        reproducible stream; `crypto.randomBytes` emits a hex-encoded
        N-byte digest (2N chars) to sidestep the `Array<u8>` cross-backend
        gap.
  - [x] **P15** F6.fs — `record FileStat { size: i64, mtime: i64, isDir:
        bool }` + 8 host-bound declares (`readText`, `writeText`,
        `exists`, `list`, `mkdir`, `rm`, `copy`, `stat`). Fallible ops
        return `@Result<_, string>` via the §A3 wrapper.
  - [ ] **P16** F8.http — DEFERRED. Unblocked by P10 infra-wise, but
        needs a Promise wrapper sidecar (node-side `async` + Erlang
        `httpc:request/4` divergence) — non-trivial sync/async contract
        belongs with the `#[@future]` rollout (`frente-a` keystone).
        Drives to v0.beta.21 alongside the §A3 future rollout.
  - [ ] **P17** F4.random.shuffle — DEFERRED. Pure-bp Fisher–Yates over
        generic `Array<T>` is circular even with `.expect(sentinel)`.
        Documented in `random.bp` for future-Eric.
  - [x] **P18** F9 examples-CLI walkthrough + per-target coverage
        table — `libs/std/src/examples.md` updated.
  - [x] **P19** unification sweep + push to origin/feat — landed
        (meta `38e9bbb` bot-lang bump to `5d19f7e`, `17edf6e` merge from
        `task/std-tail`, `92e3660` ci-tail close, `08f7467` bot-lang bump
        to `1791337` for .gitignore `.tmp-exec-*/`). All 7 submodule
        remotes verified at unified `feat` heads.

## Coordination

- Both sub-specs are file-disjoint (different modules), can be dispatched to two agents simultaneously.
- F2 sidecar shipping + F3 `#[@result] declare fn` template have prim-op overlap: F3 consumes the `prim-op` `fn-param-default-expansion` work if not yet landed (otherwise the §A3 wrapper falls back to per-arity overloads).

## Exit gate

Per spec — every std module green on `commonJS` + `erlang` test-libs; `Option.expect<T>` callable from any `?T`; examples-CLI walkthrough doc complete.
