# Status — 1.0.10-beta

**Updated:** 2026-09-20 · **Progress:** ~11 % (11 of 119 work items landed, 6 worktrees open; the milestone was cut
today — its specs are what is in analysis, no library front has started, and the compiler
carry-over holds the only code in flight)

Count: 27 compiler carry-over items (`00`, C-01…C-27) · `01-std` (6 steps + 3 carried std fronts) ·
`02-packaging` · 51 rakun · 9 jhonstart · 22 emilia · 9 onze fronts. The percentage weighs items
equally; it is a ratio, not a measurement. Open questions for the maintainer: 1 — 90 (`#[@future]` + `#[@context]` on a server component vs R5), raised by front 19's landing; 71–89 are in [`decisions-taken.md`](./decisions-taken.md).

## Done
- [x] 1.0.5-beta closed — [`../1.0.5-beta/closure.md`](../1.0.5-beta/closure.md); fronts 06 and 10 landed in full, 15 with three hold-backs, the rest partial (row by row there)
- [x] 1.0.6 … 1.0.9-beta absorbed and deleted (decision 68) — every 1.0.9 front copied by name under its track; the merged drafts kept verbatim under [`absorbed/`](./absorbed/README.md); proof in [`unification.md`](./unification.md)
- [x] Top-level documents — `overview.md`, `fronts.md`, `contracts.md` (+ contract 7, the test/snapshot contract), `deferred.md`, `language-gaps.md` (+ the `00` owner column and the `@src()` row), `unification.md`, `decisions-taken.md` (68–70), `decisions-pending.md` (71–82), this file
- [x] `00-compiler-carry-over/README.md` — C-01…C-27 prioritised, with the 1.0.5 deep dives carried beside it (17 front directories)
- [x] `02-packaging` step 2 (rakun) — landed on rakun's `feat` `e50a63b`: the umbrella is a workspace (`workspaces: ["modules/*", "examples/*"]`), the core moved to `modules/rakun/` (6 `files`, `runtime.mjs`, 5 tests — 17/17), the 13 scaffolds carry `files` + `{ "rakun": { "workspace": true } }` and their target, the example is member `rakun-example` (renamed from `rakun-app`, which front 22's submodule will take), the pre-commit hook runs every member; `botopink-lib-test` sees 15 rows, no new red
- [x] `00 · 18-comptime-runtimes` steps 0–1c (C-26, part) — landed on `feat` `85a8ab4e` (+ `361d255d`: release runners install OTP 28): `codegen/beam/beam_file.zig` writes a loadable `.beam` (FOR1 chunks, `LitT` stored zlib, `Line`), `opcodes.zig` generated from OTP 28's `genop.tab` (184, 118 emittable — the OTP-24-stable subset), three `erl`-validated round-trip tests; cmd 4 loads `.beam` bytes in-frame; the server and two preludes are compiled by `erlc` at `zig build` and embedded (`server_source.zig`, `render_resident.zig`) — `erlc` leaves the user's machine, OTP 28 floor refusal; erika-linq build 627 → 464 ms. Remaining C-26: the untyped BEAM lowering (`beam_asm.zig`, 1 500–2 500 LOC, after C-01), `persistent_wat.zig`, the selector (84), the `{beam,wat}` layout (85), the browser build
- [x] `02-packaging` step 1 — landed on `feat` `81e10a18`: the shared manifest model `modules/manifest/` (workspace vs package, `workspaces` globs, members, `targets` inheritance), object-form `dependencies` only (`git`/`path`/`{ "workspace": true }`, one source, one pin), discovery via `manifest.scanRoots` in runner/loader/LSP/bpmp, `botopink test` per member with `✗ ships nothing` for a member without `files`, `docs/botopink-json.md`, 47 fixtures + tests; 20 located error messages
- [x] `00` C-19, and the 1.0.5 worktrees `beammem` (C-05 steps 1–3), `identity` (C-03 erlang half), `ecosystem` (C-02 `libs/std` half) — landed on the compiler's `feat` on 2026-09-20 with a cold gate green each (`2788be9f`, `a6b5b62a`, `1769456d`; two real `at`-rename regressions fixed on the way); worktrees removed
- [x] `00 · 19-use-activation` step 1 (C-27) — landed on `feat` `85f883bd`: `docs.md` documents `use`/`@Context`, the static-prefix guard holds at any nesting, the commonJS React rename is gone (`use f(x)` → `f(x)` everywhere), `#[@context]` is required to activate a hook (`use-without-context-effect`), 8 language cells (348/45/0). jhonstart is in `known-red-libs.txt` until its hooks gain `#[@context]`
- [x] `00` C-11 + C-12 acceptance — landed on `feat` `f5c58e34`: `format --check` walks the whole project (`.bp` + `.d.bp`, nested projects), `reject/<n>.bp` beside its `.expect` is structurally exempt, `scripts/format-check.sh` is gate stage 3 for the trees that are canonical (`examples/modules` only today — the reds are listed in its header with owner), 3 unit + 1 contract tests; C-12 measured: 0 hunks outside the chain rule across six trees, 29 chains opened (12 of the 44 predicted were not chains), `fits` predicate tests added
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
- [ ] `02-packaging` step 2 (emilia, erika) — worktrees `.tasks/emilia-workspace`, `.tasks/erika-workspace`: the same migration; jhonstart follows once `.tasks/jhonstart-context` lands; the old `onze` mocking lib is not migrated (retired by `01-std` step 4)
- [ ] jhonstart made green under decision 88 — worktree `.tasks/jhonstart-context` (`fix/context` in `repository/jhonstart`): `#[@context]` on every activating body, hook nouns (`counter`, `router`, `toggle`), the client runtime for `state`/`effect`/`memo`; then the two `known-red-libs.txt` rows go
- [ ] Spec maintenance — decisions 75/83–89 folded into `02-packaging`, front 18, front 19 and the `04-jhonstart` docs (`#[@context]` sweep)
- [ ] `00` C-01 — worktree `.tasks/module-identity` (`fix/module-identity-halves`): policy 3 (one BEAM module per `type`/`behavior`) and the identity in the value on every backend (decisions 21/22/23/5)
- [ ] `00` C-06 acceptance + C-16 — worktree `.tasks/language-cells` (`fix/language-cells`): the six wasm RUN LOGs verified under wasmtime, cells for decisions 52/53/55/63–66, the suite tally recounted from the files
- [ ] `01-std` steps 1–3 — worktree `.tasks/src-builtin` (`fix/src-builtin`): `@src()` + the fallible test body (decisions 73/74), then `std/asserts`, then `std/snapshots` (72); commits on the branch, merge into `feat` by the coordinator

## Pending
- [ ] `00` C-06 acceptance (wasm) — in `.tasks/language-cells`; C-12's is done
- [ ] `00 · 19` step 2 (decision 89) — waits on question 90
- [ ] jhonstart: `#[@context]` on every component and hook noun rename (`useCounter` → `counter`), then delete its two `known-red-libs.txt` lines — the library track's first commit
- [ ] `01-std` step 1 — `@src()` in the compiler (the `00` carve-out): decisions 73/74 taken; ready to open a worktree
- [ ] `01-std` steps 2–3 — `std/asserts` and `std/snapshots`: decision 72 taken; wait on step 1
- [ ] `01-std` step 4 — retire the old `onze` mocking lib into `std/asserts` + `std/mocks` (decision 71): waits on step 2
- [ ] `01-std` step 5 — `onze13` → `onze` name takeover (decision 79): waits on step 4 and on the maintainer tagging/archiving the old repo
- [ ] `00 · 10-cli-residuals` — `libs.zig:shipMjsSidecars` resolves the sidecar owner by name across roots and silently ships nothing when the name is flagged as a duplicate (found while migrating rakun: `Cannot find module './runtime.mjs'` with no diagnostic) — a located error or a workspace-aware lookup
- [ ] `02-packaging` step 2 — each library's umbrella becomes a workspace (`workspaces: ["modules/*", "examples/*"]`, core moved under `modules/<lib>/` with `files`, submodules with `{ "workspace": true }`); rakun first (13 manifests would read `✗ ships nothing` today); the `-test` submodules wait on `01-std` steps 2–3
- [ ] `02-packaging` README § Mechanism rewritten to the workspace rule (routes A/B kept as the record)
- [ ] `04-jhonstart/**` sweep for decision 88 — every component becomes `#[@Context] fn … -> Element` in examples, maps and READMEs; `01-std` example 2 and front 19's *rule for libraries* re-stated
- [ ] Specs updated for decisions 75, 83–86 and 88 (`02-packaging` § Mechanism; front 18 steps 1c/3/4; front 19 steps 1/4/5) — the READMEs still carry the pre-answer options
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
