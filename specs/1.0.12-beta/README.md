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

The open work is cut by the repository it changes, in three tiers. **First of all, before any other step of any
front, comes decision 434 — comptime on wasm only** (front 144's group B-00); until it lands, the other fronts only
finish what is already in flight. A front keeps its number for good; each README opens with an alias table from the
old ids to its steps.

| Tier | Front | What |
|---|---|---|
| **First** | [`144` B-00a–B-00e](1-botopink-lang/144-botopink-lang/README.md) | Decision 434: `modules/std-wasm`, `modules/beam-to-wasm`, the comptime driver on wasm for every target, the BEAM comptime runtime deleted (one `snapshots/codegen/<target>/` tree), std-wasm in the `--target wasm` output |
| **Maximum** | [`1-botopink-lang/144-botopink-lang`](1-botopink-lang/144-botopink-lang/README.md) | Every open step that changes `repository/botopink-lang`, in one order: B-00 (434) → the error contract of 431 / 432 (B-01–B-09) → the structural fixes the libraries wait on (430: B-10–B-19) → the rest (B-20–B-29). The only front that edits botopink-lang |
| **High** | [`2-libraries/`](2-libraries/) — one per repository, in this order | [145 erika](2-libraries/145-erika/README.md) · [146 validation](2-libraries/146-validation/README.md) · [147 css](2-libraries/147-css/README.md) · [148 styled](2-libraries/148-styled/README.md) · [149 jhonstart](2-libraries/149-jhonstart/README.md) · [150 rakun](2-libraries/150-rakun/README.md) · [151 json](2-libraries/151-json/README.md) · [152 yaml](2-libraries/152-yaml/README.md) · [153 dbcontext](2-libraries/153-dbcontext/README.md) · [154 emilia](2-libraries/154-emilia/README.md) · [155 http](2-libraries/155-http/README.md) · [156 log](2-libraries/156-log/README.md) · [157 routing](2-libraries/157-routing/README.md) · [158 markdown](2-libraries/158-markdown/README.md) · [159 actions](2-libraries/159-actions/README.md) · [160 snap](2-libraries/160-snap/README.md) · [161 vscode-extension](2-libraries/161-vscode-extension/README.md) · [162 onze](2-libraries/162-onze/README.md) — onze last: its example app needs every other front |
| **Medium** | [`3-medium/`](3-medium/) | [136 cardume](3-medium/136-cardume/README.md) (moved as is) · [163 meta-ci](3-medium/163-meta-ci/README.md) (the meta CI, the pointers' sweep, the specs' drift rule) · [105 i18n](3-medium/105-i18n/README.md) · [107 release](3-medium/107-release/README.md) · [98 packaging tail](3-medium/98-packaging-tail/README.md) · [135 snap](3-medium/135-snap/README.md) (coordination) |

25 fronts hold open work. Where each stands is [`status.md`](status.md); who may run beside whom and the
execution order are [`fronts.md`](fronts.md).

## Old ids

The old track directories (`00-gate` … `10-specs`, `20-snap`) are gone (decision 433): an old id (`01-checker` s42,
`137-erika-sql` s2) resolves through the alias table at the top of the front that holds its step, and an old front's
goal, mechanism, topic files and examples sit beside those steps, in a subdirectory named after it
(`2-libraries/149-jhonstart/26-jhonstart-router/`). Done steps live in git history, `decisions-taken.md` and the
1.0.11 closure.

## Rules in force

- **The most restrictive behaviour, and no configuration that bypasses it** (decision 67). A red cell is fixed,
  or its test is deleted by a decision — never allow-listed, expected or skipped.
- **Comptime on wasm first** (434): nothing new opens before front 144's B-00 group lands.
- **A structural fix comes first** (430): a library front that meets a compiler or std gap files a
  [`language-gaps.md`](language-gaps.md) row and pauses on the 144 step that fixes it; no new workaround.
- **Only front 144 edits `repository/botopink-lang`** (433); a library front edits its own repository and the
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
| [`status.md`](status.md) | The only status: five lanes — finish what is on `feat` (434 first), the libraries' critical path, ready now, later, blocked on a decision — each by tier and front |
| [`fronts.md`](fronts.md) | The rules for a front, ownership by repository, the conflict rules, the execution order, and § Gate (the standard landing every README cites) |
| [`decisoes-pendentes.md`](decisoes-pendentes.md) | The pending decisions in Portuguese, ordered by what each unblocks, with an example per option — the page the maintainer answers on; `decisions-pending.md` stays the source |
| [`decisions-taken.md`](decisions-taken.md) | The numbered decisions in force (the next free number lives only there) |
| [`decisions-pending.md`](decisions-pending.md) | The open questions, the contradictions (`ctr-*`), the 1.0.10 choices awaiting confirmation |
| [`language-gaps.md`](language-gaps.md) | Every compiler gap a library front meets, with its nearest form, owner and the Marker index |
| [`contracts.md`](contracts.md) | The cross-library contracts |
| [`deferred.md`](deferred.md) | What has no path on the BEAM or no gate cell this milestone |

A new front starts from [`../__template.md`](../__template.md), in the tier of the repository it changes.
