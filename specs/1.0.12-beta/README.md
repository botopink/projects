# Specs — 1.0.12-beta

1.0.12-beta is 1.0.11-beta consolidated: the same goals and the same open work, rewritten to current state and
remaining work only. The history — measurements, status narratives, the text of done steps, the carry maps, the
snapshot maps — stays in [`../1.0.11-beta/`](../1.0.11-beta/closure.md), which is frozen; 1.0.10-beta's record is
[`../1.0.10-beta/closure.md`](../1.0.10-beta/closure.md).

The goal does not change: every repository green under its own gate with zero tolerated reds (the baseline in
`00-gate`), then what 1.0.10 left open — the compiler's tails, std as the one place a shared primitive lives, the
packages the frameworks copy from each other, rakun on its 16-member cut, the jhonstart / emilia / onze tails,
and Astro's feature set on the stack.

## Tiers — the open work, by repository (decision 433)

The open work is cut by the repository it changes, in three tiers. **First of all came decision 434 — comptime on
wasm only** (front 144's group B-00): it is done but for B-00c's last box, each library's own hook on the new
compiler, the seventh step of the conformance order now being worked ([`fronts.md`](fronts.md) § Execution order).
A front keeps its number for good; each README opens with an alias table from the old ids to its steps, a
**Repository** and a **Model** line, and ends with its "Conformance" step (decisions 459, 465).

| Tier | Front | What |
|---|---|---|
| **First** | [`144` B-00a–B-00k](machine-1/144-botopink-lang/README.md) | Decision 434, **done** but for B-00c's last box (`scripts/gate.sh libs`, the conformance order's seventh step): `modules/std-wasm`, `modules/beam-to-wasm` (a standalone utility the comptime does not call, 452), the comptime driver on wasm for every target, the BEAM comptime runtime deleted (one `snapshots/codegen/<target>/` tree), std-wasm in the `--target wasm` output, B-00k its Conformance step |
| **Maximum** | [`machine-2/144-backends-tooling/164-wasm-gc`](machine-2/144-backends-tooling/164-wasm-gc/README.md) — where new development is centred (2026-10-14): s1 the comptime runtime on wasmtime (wasm3 removed), s2 the wasm target on WasmGC, s3 std-wasm in botopink and hand-written `.wat`, s4 Conformance; the second front that edits botopink-lang (amends 433) |
| **Maximum** | [`machine-1/144-botopink-lang`](machine-1/144-botopink-lang/README.md) (two machines: [`machine-1/144-checker/`](machine-1/144-checker/README.md), [`machine-2/144-backends-tooling/`](machine-2/144-backends-tooling/README.md)) | Every open step that changes `repository/botopink-lang`, in one order: B-00 (434) → the error contract of 431 / 432 (B-01–B-09) → the structural fixes the libraries wait on (430: B-10–B-19) → the rest (B-20–B-29). Beside them: B-29 steps G–J — the step gate (460, landed), the cells in `conformance/` and `botopink cell` (H, 457, 464, 475), the reference into `conformance/` and the hook's `--no-conformance` (I, 461, 462, 466, 470), the gate taking a total of jobs (J, 468, 469); B-30 wasm memory as erlang's (448, 449); B-31 and B-32, the structural fixes B-00k found (430, 471, 472). Each group ends with its Conformance step. The only front that edits botopink-lang |
| **High** | [`machine-1/`](machine-1/) — one per repository, in this order | [145 query](machine-1/145-query/README.md) · [146 validation](machine-1/146-validation/README.md) · [147 css](machine-1/147-css/README.md) · [150 rakun](machine-1/150-rakun/README.md) (s25: its timing tests on a controlled clock; it holds the open steps of the former 148 styled — [s32 … s35](machine-1/150-rakun/steps-styled.md) —, 149 jhonstart — [s36 … s47](machine-1/150-rakun/steps-jhonstart.md) —, 153 dbcontext — [s48 … s51](machine-1/150-rakun/steps-dbcontext.md) —, 154 emilia — [s52 … s58](machine-1/150-rakun/steps-emilia.md) — and 162 onze — [s59 … s71](machine-1/150-rakun/steps-onze.md), onze last: its example app needs every other front) · [151 json](machine-1/151-json/README.md) · [152 yaml](machine-1/152-yaml/README.md) · [155 http](machine-1/155-http/README.md) · [156 log](machine-1/156-log/README.md) · [157 routing](machine-1/157-routing/README.md) · [158 markdown](machine-1/158-markdown/README.md) · [159 actions](machine-1/159-actions/README.md) · [160 snap](machine-1/160-snap/README.md) · [161 vscode-extension](machine-1/161-vscode-extension/README.md) · [165 rakun-workspace](machine-1/165-rakun-workspace/README.md) (opens now: one `rakun` repository, a workspace of 17 plug-and-play packages — mono-a; 150 (with the steps of the former 148, 149, 153, 154 and 162 refiled into it) pauses until its s1) |
| **Medium** | under the machine that runs each: [`machine-1/`](machine-1/) 136, 105, 135 · [`machine-2/`](machine-2/) 163, 107, 98, 166 | [136 cardume](machine-1/136-cardume/README.md) (moved as is) · [163 meta-ci](machine-2/163-meta-ci/README.md) (the meta CI, the pointers' sweep, the specs' drift rule; s6 a language tour from `botopink-lang/conformance/`, s7 `scripts/gate.sh` in every repository and the meta one the scheduler, s8 each library's CI fetching its dependencies, s9 the measurements at the end) · [105 i18n](machine-1/105-i18n/README.md) · [107 release](machine-2/107-release/README.md) · [98 packaging tail](machine-2/98-packaging-tail/README.md) · [135 snap](machine-1/135-snap/README.md) (coordination) · [166 decision-cells](machine-2/166-decision-cells/README.md) (one cell per decision in the repository it binds, `conformance/modules/decisions-taken/<slug>-<N>/` — `docs.md` with `{src/main.bp}`, one real example; s1 `scripts/decision-cells.py` and meta CI check 7, s3 the docs and code per repository, s4 the flip to `botopink cell check`, s5 Conformance; questions 166-a … 166-d) |

The specs are laid out by machine (the maintainer, 2026-10-17): [`machine-1/`](machine-1/README.md) holds `144-botopink-lang/` (the front's shared rules), `144-checker/`, the library fronts, 165, 136, 105 and 135; [`machine-2/`](machine-2/README.md) holds `144-backends-tooling/` (with `164-wasm-gc`), `163-meta-ci`, 107, 98 and `166-decision-cells`; each folder's README is that machine's work queue. The tier directories `1-botopink-lang/`, `machine-1/` and `3-medium/` are gone; the tiers stay as the table's rows. 20 fronts hold open work. Where each stands is [`status.md`](status.md); who may run beside whom and the
execution order are [`fronts.md`](fronts.md).

## Old ids

The old track directories (`00-gate` … `10-specs`, `20-snap`) are gone (decision 433): an old id (`01-checker` s42,
`137-erika-sql` s2) resolves through the alias table at the top of the front that holds its step, and an old front's
goal, mechanism, topic files and examples sit beside those steps, in a subdirectory named after it
(`machine-1/150-rakun/26-jhonstart-router/`). Done steps live in git history, `decisions-taken.md` and the
1.0.11 closure.

## Rules in force

- **The most restrictive behaviour, and no configuration that bypasses it** (decision 67). A red cell is fixed,
  or its test is deleted by a decision — never allow-listed, expected or skipped.
- **Comptime on wasm first** (434): front 144's B-00 group went first; it is done but for the conformance order's
  seventh step.
- **Every front ends with its "Conformance" step** (459, 465): a front lands on `feat` once its commits passed the
  hook's `scripts/gate.sh --no-conformance` (470, 477); its Conformance step reads `feat`'s GitHub pipeline, which
  runs `scripts/gate.sh` with conformance (474, 477) — conformance runs locally only to reproduce a red, and a red
  gets the cheap test the hook runs that would have caught it (478); it holds back no front that builds on it (479)
  and updates the reference beside the cells (480). The suite and the reference live in each repository's
  `conformance/` (466; no `botopink/conformance` repository, 467).
- **The gates' scheduling is the meta repository's** (468, 469, 473): its `scripts/gate.sh` owns the machine's job
  pool and runs the full gates; a repository's own gate takes a total of jobs and knows no pool and no lock.
- **A structural fix comes first** (430): a library front that meets a compiler or std gap files a
  [`language-gaps.md`](language-gaps.md) row and pauses on the 144 step that fixes it; no new workaround.
- **Only fronts 144 and 164 edit `repository/botopink-lang`** (433, amended for 164 wasm-gc); a library front edits its own repository and the
  consumer commits it carries (188).
- **A manifest's `targets` is the single source of truth** for where a cell exists; a target is excluded only
  when a host binding does not exist for it, and the runner proves it (decision 156).
- **The libraries split by concern** (113); **the compiler knows no library**; **a shared library is neutral like
  std** and ships `.bp` only (115–117, 326); **the return type is the annotation** (118–128); **a page signal is
  jhonstart's end to end** (117).
- **Examples are code, not prose**; a `// LANGUAGE GAP:` marker with no row in the Marker index is red (meta CI
  check 5).
- **A snapshot is evidence, not a baseline; the gate runs from a cold runtime cache; a backend builds a model and
  an emitter renders it.**
- **Coverage is never traded for wall clock**: the gate asserts that the cells it ran equal the cells that exist;
  over the 7m30s budget is yellow, never red (decision 265).
- **Decisions are asked, not guessed**: a question goes to `decisions-pending.md` with a recommendation, most
  restrictive first.
- **`status.md` is the only file that carries status.** Every other spec describes current state and remaining
  work; a done step is one line under its front's `## Done`.

## Where things are

| File | What |
|---|---|
| [`status.md`](status.md) | The only status: five lanes of open lines — finish what is on `feat` (the conformance order first), the libraries' critical path, ready now, later, blocked on a decision — each by tier and front, and Done |
| [`fronts.md`](fronts.md) | The rules for a front, ownership by repository, the conflict rules, the execution order, and § Gate (the standard landing every README cites) |
| [`decisoes-pendentes.md`](decisoes-pendentes.md) | The pending decisions in Portuguese, ordered by what each unblocks, with an example per option — the page the maintainer answers on; `decisions-pending.md` stays the source |
| [`decisions-taken.md`](decisions-taken.md) | The numbered decisions in force (the next free number lives only there) |
| [`decisions-pending.md`](decisions-pending.md) | The open questions, the contradictions (`ctr-*`), the 1.0.10 choices awaiting confirmation |
| [`language-gaps.md`](language-gaps.md) | Every compiler gap a library front meets, with its nearest form, owner and the Marker index |
| [`contracts.md`](contracts.md) | The cross-library contracts |
| [`deferred.md`](deferred.md) | What has no path on the BEAM or no gate cell this milestone |

A new front starts from [`../__template.md`](../__template.md), in the tier of the repository it changes.
