# v0.beta.20 — plan (reasoning scratchpad)

Mutable. The *why* behind v0.beta.20's shape and the trade-offs each
spec chose. Authored intent lives in `specs/`; this file is the
thinking around them.

## Premise

v0.beta.19 closed every *recorded* gap across v0.beta.12–v0.beta.18
organised as three file-disjoint frentes + the `std-expansion` /
`std-expansion-tail` satellites. It also added two ad-hoc late-cycle
specs (`recursive-test-gate`, `ci-pipelines-green`) that closed cleanly
on their own worktrees.

The frontier at v0.beta.20 open is two-fold:

1. **Partial closes carry over.** `frente-a-compiler` shipped §S, §U,
   §A6, §D1, §G1, §G3 but deferred §A7, §B, §C, §D3–D5, §G2 with
   recorded reasons. `frente-b-rules-tooling` and `prim-op-annotation`
   are partials too. `std-expansion-tail` shipped F0 + §A2 commonJS+
   erlang twin + 4 F4 in-module tails + 8 net-new modules in 14 bot-
   lang commits, but P1 (§A3) through P19 (final unification + push)
   carry over with 14 sub-deferrals.
2. **emilia is the v0.beta.20 keystone.** A new sibling lib for the
   jhonstart framework's styled / CSS / tw template engines. Eric
   seeded the repo + a draft spec NOT committed.

## Big decisions

### 1. Split `std-expansion-tail` carry-over into its own spec

The original `std-expansion-tail.md` is the spec contract for the
whole set; it stays immutable. The follow-on phases live in
`std-expansion-tail-followup.md` per the v0.beta.20 set. Phases are
re-numbered P1–P19 (instead of inheriting F1/F2/§A3/F4–F9) because the
build order changes: §A2 already landed, so the gating dependencies
shift — P1 is §A3 (was F3), P9 is STD-001 (was F1), P10 is sidecar
shipping (was F2). The phase order reflects the actual infra
dependencies, not the original spec ordering.

### 2. `option-expect` is its own micro-spec

Adding `Option.expect<T>(default: T) -> T` is a single-method addition
to `?T` in `builtins.d.bp` — but it unblocks `random.shuffle<T>`
cleanly, and the spec contract for *why* a synonym deserves its own
short doc (matches Rust convention, documents the "proven in bounds"
intent). Could fold into `std-expansion-tail-followup` P17, but the
discrete spec gives reviewers a clean diff for the surface choice.

### 3. `prim-op-annotation-tail` carries §A2 to BEAM + wat

The §A2 work in `std-expansion-tail` was scope-creep within that spec
— commonJS + erlang twin was necessary to unblock F5.base64 + F6
modules. BEAM + wat backends still carry the `mem.eql(callee, …)`
allow-list. `prim-op-annotation-tail` finishes the four-backend story.
It's distinct from `frente-a-tail` §A7 because §A7 is a 1/4-backend
gate (BEAM bytecode-template), while this spec mirrors the §A2 path
on the same two backends.

### 4. `frente-a-tail` for the deep deferrals

§B generic-inference, §C wasm-aggregates refactor, §D3–§D5 cross-
backend parity remainders, §G2 erika runtime-string interp. These are
deep compiler work that shouldn't gate on `std-expansion-tail-followup`
landing (the std lib doesn't need them to ship). `frente-a-tail` runs
on its own worktree, file-disjoint with `std-expansion-tail-followup`
at the directory level except for `comptime/infer.zig` which both
touch — so schedule sequentially on that file.

## What this set is NOT

- **Not a new language wave.** No new keywords (emilia uses the
  existing `@ExprCustom` carrier; std-expansion-tail-followup uses
  the §A2/§A3 grammar already authored).
- **Not a re-design of std-expansion-tail.** The inherited spec stays
  authoritative; the followup just re-numbers and re-orders the
  unmoved phases.
- **Not a new sub-language carrier.** emilia uses the existing
  `q.custom()` + `CustomNode` infra from `expr-custom` v0.beta.10.
- **Not the place to add effect composition.** `#[@result]
  #[@asyncGenerator]` still deferred; explicit non-goal per the
  v0.beta.19 frente-b-rules-tooling §3 carve-out.

## Order

```text
emilia                       ─▶ runs first (keystone) — file-disjoint with
                                everything else.

option-expect                ─▶ lands inline before std-tail-followup P17
                                (single commit on bot-lang feat).

std-expansion-tail-followup  ─▶ P1 (§A3) → P9 (STD-001) → P10 (sidecar) before
                                P15+P16; P5/P6/P7/P8 run in parallel as time
                                allows. P19 closes with the bot-lang feat push.

prim-op-annotation-tail      ─▶ file-disjoint with std-tail-followup; own
                                worktree. Independent of every other v0.beta.20
                                spec.

frente-a-tail                ─▶ sequential on `comptime/infer.zig` with
                                std-tail-followup's P1/P9 (both touch infer).
                                Schedule after the std-tail-followup §A3 +
                                STD-001 land to avoid merge churn.

frente-b-rules-tooling       ─▶ same spec as v0.beta.19; reopened on a
                                v0.beta.20 worktree to close the Rules track
                                + §E/§F/§T.
```

## Coordination points

- **`comptime/infer.zig` is a hotspot** — `std-expansion-tail-followup`
  P1 (§A3) + P9 (STD-001), `frente-a-tail` §B (generic inference),
  `option-expect` (option-method dispatch), and `frente-b-rules-tooling`
  Rules track all touch this file. Schedule sequentially: std-tail-
  followup's two phases land first (they're the keystone for the
  followup); option-expect inline before P17; frente-a-tail §B last
  (it's the deepest change).
- **`primitives.d.bp` is touched by 3 specs** — std-tail-followup P5+P6
  (26 new methods on interfaces), option-expect (1 method on `?T`),
  prim-op-annotation-tail (BEAM/wat annotations). Methods are
  additive — no conflict in practice, but co-ordinate the diff
  per-section.
- **The bot-lang `feat` push** stays the final step of std-tail-
  followup P19; it carries every v0.beta.20 commit aside from emilia
  (which lives in its own `repository/emilia/` repo).

## Risks

- **§B generic-inference is deep**. If the `registerStdlib` fix
  surfaces unexpected snapshot churn, defer to v0.beta.21 with a
  clear carve-out (memory `project_generic_inference_gap` already
  flags this).
- **emilia's spec is uncommitted**. The v0.beta.20 scope hinges on
  Eric's draft landing; if it doesn't, the scope-table row in the
  v0.beta.20 README documents the seed but the spec body stays a
  stub.
- **STD-001 infra (P9) needs target threading through 3-4 callsites**.
  Touching `compile` / `analyzeModule` / `analyzeSource` is invasive
  — schedule before the broader frente-a-tail work to keep merge
  diffs clean.
