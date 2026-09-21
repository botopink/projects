# Status — 1.0.10-beta

**Updated:** 2026-09-20 · **Progress:** ~4 % (3 of 119 work items landed as-is; the milestone was cut
today — its specs are what is in analysis, no library front has started, and the compiler
carry-over holds the only code in flight)

Count: 27 compiler carry-over items (`00`, C-01…C-27) · `01-std` (6 steps + 3 carried std fronts) ·
`02-packaging` · 51 rakun · 9 jhonstart · 22 emilia · 9 onze fronts. The percentage weighs items
equally; it is a ratio, not a measurement. Open questions for the maintainer: 2
([`decisions-pending.md`](./decisions-pending.md), 75 — the `workspaces` counter-proposal — and 87, answered ambiguously and held for confirmation); 71–74, 76–86, 88 and 89 were answered the same day ([`decisions-taken.md`](./decisions-taken.md)).

## Done
- [x] 1.0.5-beta closed — [`../1.0.5-beta/closure.md`](../1.0.5-beta/closure.md); fronts 06 and 10 landed in full, 15 with three hold-backs, the rest partial (row by row there)
- [x] 1.0.6 … 1.0.9-beta absorbed and deleted (decision 68) — every 1.0.9 front copied by name under its track; the merged drafts kept verbatim under [`absorbed/`](./absorbed/README.md); proof in [`unification.md`](./unification.md)
- [x] Top-level documents — `overview.md`, `fronts.md`, `contracts.md` (+ contract 7, the test/snapshot contract), `deferred.md`, `language-gaps.md` (+ the `00` owner column and the `@src()` row), `unification.md`, `decisions-taken.md` (68–70), `decisions-pending.md` (71–82), this file
- [x] `00-compiler-carry-over/README.md` — C-01…C-27 prioritised, with the 1.0.5 deep dives carried beside it (17 front directories)
- [x] `00 · 19-use-activation/` (C-27) — specified: README (steps 0–5: the language reference, `use` in `#[@future]` bodies, tuple destructuring, the boundary directives, the lowering contract), `surface.md` (construct × backend table), `evidence.md`; questions 87–89 raised; `04-jhonstart/**` swept to the rule (`use router()`, `use pathname()`, `use actionState(…)` — zero `use use` left)
- [x] `00 · 18-comptime-runtimes/` (C-26) — specified: README (steps 0–5), `current-path.md`, `beam-file-format.md`, `wat-runtime.md`, `snapshot-layout.md`, `browser-build.md`, `evidence.md`; questions 83–86 raised
- [x] `00` C-19 — declaration-name builders: landed on the compiler's `feat` on 2026-09-20 (`wip(tooling)` + merge `fix/tooling-step5`, pushed); gate green at the tip
- [x] `00` C-06 (wasm half) and C-12 (formatter width) — landed on the compiler's `feat` on 2026-09-20 as-is (`wip(wasm)` + `fix/wasm-patterns`; `wip(formatter)` + `fix/fits`, pushed) — **landed, not verified**: their acceptance rows (zero bytes moved, the per-tree measurement, the four-backend loop cells) are still open under Pending
- [x] `01-std/` — `README.md`, `asserts-api.md` (26 functions + the old-onze migration table), `src-builtin.md` (`@src()`), `snapshots.md`, `onze-migration.md`, `modules.md`, `test-snap.md`, `unification.md`, the two plan examples under `examples/`, fronts 01–03 carried
- [x] `02-packaging/README.md` — the `modules/**` + `examples/**` rules, manifests, `test-libs` discovery, dependency direction; front 95 carried beside it
- [x] `03-rakun/` — 51 fronts carried with their 1.0.6/1.0.7 appendices (26 sections) and examples; `README.md` (levels computed from the dependency lines), `modules.md` (28 submodules + `starters/`, the 13 scaffolded dirs reconciled), `unification.md` (+ the Spring Boot sections still unowned), `test-snap.md` (~380 cases) and `test-snap-examples.md` (8 projects, ~76 cases)
- [x] `04-jhonstart/` — 9 fronts + 8 appendices + 19 carried examples; `README.md`, `modules.md` (5 submodules), `unification.md`, `test-snap.md` (~55 cases), `test-snap-examples.md` (5 projects, 32 cases)
- [x] `05-emilia/` — 22 fronts + 17 appendices + 15 carried examples; `README.md`, `modules.md` (2 submodules; `tokens.bp` stays one file, sub-dispatchers move per front), `reference-coverage.md` (267 Tailwind rows), `tailwind-mapping.md`, `unification.md`, `test-snap.md` (~130 cases), `test-snap-examples.md` (9 projects)
- [x] `06-onze/` — 9 fronts, `onze13` → `onze` normalised (34 identifiers); `README.md`, `modules.md` (7 submodules), `unification.md`, `test-snap.md` (55 cases), `test-snap-examples.md` (21 cases)

## In analysis
- [ ] `00` C-05 — module-level `var` + `@BeamMemory` carrier · worktree `.tasks/beammem` · steps 1–3 in code and unit tests; the pre-commit gate is red (`infer.zig:2870`, `comptime.types` has no `typeToString`) — not landed
- [ ] `00` C-03 — a wrapper per host-bound std `declare fn` · worktree `.tasks/identity` · erlang side done, beam helper unwired; 7 snapshot mismatches in `codegen/erlang/external_*` keep the gate red — not landed
- [ ] `00` C-02 — an index is a method call · worktree `.tasks/ecosystem` · the `libs/std` half; 8 snapshot mismatches keep the gate red — not landed

## Pending
- [ ] `00` C-06 / C-12 acceptance — the landed `wip` commits verified against the fronts' acceptance rows (formatter: zero bytes moved across the six trees, the 44 chains measured; wasm: the `expected-failures.txt` lines re-classified) — and the `wip(…)` subjects rewritten or the rows re-opened
- [ ] Meta-repo submodule bump to the compiler's new `feat` tip — the maintainer's commit (the meta working tree holds uncommitted spec edits)
- [ ] `01-std` step 1 — `@src()` in the compiler (the `00` carve-out): decisions 73/74 taken; ready to open a worktree
- [ ] `01-std` steps 2–3 — `std/asserts` and `std/snapshots`: decision 72 taken; wait on step 1
- [ ] `01-std` step 4 — retire the old `onze` mocking lib into `std/asserts` + `std/mocks` (decision 71): waits on step 2
- [ ] `01-std` step 5 — `onze13` → `onze` name takeover (decision 79): waits on step 4 and on the maintainer tagging/archiving the old repo
- [ ] `02-packaging` — waits on `01-std` steps 2–3 and on decision 75 (the `workspaces` counter-proposal); decision 76 taken
- [ ] `04-jhonstart/**` sweep for decision 88 — every component becomes `#[@Context] fn … -> Element` in examples, maps and READMEs; `01-std` example 2 and front 19's *rule for libraries* re-stated
- [ ] Specs updated for decisions 83–86 and 88 (front 18 steps 1c/3/4; front 19 steps 1/4/5) — the READMEs still carry the pre-answer options
- [ ] `00` C-01 — module identity (the spine): pulled ahead of wave 1; no worktree yet
- [ ] `06-onze` 68/69 and `03-rakun` 23/29 `Owns:` lines — decision 77 taken (`RenderHooks`); rewrite pending
- [ ] `04-jhonstart` 32/67/94 — decision 78 taken; the jhonstart hook cells on commonJS wait on decision 88's compiler half (the React rename removed)
- [ ] `05-emilia` 54/56/34/46 — decisions 80–82 taken; ready when track D opens
- [ ] `fronts.md` § Waves regenerated from `03-rakun/README.md`'s level table (60/61/63/65 sit above 23 there; 81/88 in wave 2) — a documentation defect, not a decision
- [ ] Merge or discard of the three remaining `.tasks/*` worktrees (`beammem`, `ecosystem`, `identity`, gates red) — the maintainer's step, per [`../1.0.5-beta/closure.md`](../1.0.5-beta/closure.md) § Worktrees

## Open
- [ ] `00` C-04, C-07…C-11, C-13…C-18, C-20 (absorbed by C-26), C-21…C-25 — no worktree, no owner
- [ ] `03-rakun` — 51 fronts, none started; band 1: `04-rakun-erlang-runtime` · `05-rakun-config-profiles` · `22-rakun-file-routing` (`72-rakun-auto-configuration` follows 06 — see `03-rakun/README.md` § disagreements)
- [ ] `04-jhonstart` — 9 fronts, none started; first: `94-jhonstart-element-surface` → `26-jhonstart-router`
- [ ] `05-emilia` — 22 fronts, none started; may start on day one: `54-emilia-theme` → `56-emilia-cascade-and-output`
- [ ] `06-onze` — 9 fronts, none started; `49-onze-stand-up` after the name takeover, then `68-onze-client-bundle`

## Deferred out of this milestone
- See [`deferred.md`](./deferred.md) — GraalVM/AOT/CRaC/JNDI/Servlet/agents, Vercel hosting, the bundler plugin APIs, the CSS features that read user files, the old `onze` mocking runtime; plus the per-track reference-coverage holes listed in each `unification.md`.
