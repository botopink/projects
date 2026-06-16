# TODO — std-tail (std-expansion follow-ups + Option.expect<T>)

> Worktree task: closes v0.beta.19 `std-expansion-tail` partial — the 9 phases + 14 sub-deferrals from std-expansion-tail-followup, plus the additive `Option.expect<T>` method.
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
- [~] **std-expansion-tail-followup** — partial close (9/19 phases landed):
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
  - [~] **P9** F1 STD-001 — diagnostic constant + `all_codes` row landed;
        runtime check (`Env.target` threading + `stdModuleFns`
        population) deferred (CLI thread, multi-file).
  - [ ] **P10** F2 sidecar shipping infra.
  - [ ] **P4** F5 json (unblocked by P1; pure-bp parse-via-template
        + recursive stringify).
  - [ ] **P11** F4.time.sleep + F4.asserts.throws (unblocked by P1).
  - [ ] **P12** F4.random.seed + F8.crypto.randomBytes (gated on P10
        sidecar).
  - [ ] **P15** F6.fs (gated on P1 + P10).
  - [ ] **P16** F8.http (gated on P10 sidecar).
  - [ ] **P17** F4.random.shuffle — DEFERRED. Pure-bp Fisher–Yates over
        generic `Array<T>` is circular even with `.expect(sentinel)` (the
        sentinel itself must be a `T`, but the only T values available
        are wrapped in `?T`). Host-backed needs generic-fn declare
        syntax (no precedent in `libs/std`); the call is documented in
        `random.bp` for future-Eric.
  - [ ] **P18** F9 examples-CLI walkthrough + per-target coverage table.
  - [ ] **P19** unification sweep + push to origin/feat.

## Coordination

- Both sub-specs are file-disjoint (different modules), can be dispatched to two agents simultaneously.
- F2 sidecar shipping + F3 `#[@result] declare fn` template have prim-op overlap: F3 consumes the `prim-op` `fn-param-default-expansion` work if not yet landed (otherwise the §A3 wrapper falls back to per-arity overloads).

## Exit gate

Per spec — every std module green on `commonJS` + `erlang` test-libs; `Option.expect<T>` callable from any `?T`; examples-CLI walkthrough doc complete.
