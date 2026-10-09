# Specs — 1.0.12-beta

1.0.12-beta is 1.0.11-beta consolidated: the same goals and the same open work, every front under
its own number, rewritten to current state and remaining work only. The history — measurements,
status narratives, the text of done steps, the carry maps, the snapshot maps — stays in
[`../1.0.11-beta/`](../1.0.11-beta/closure.md), which is frozen; 1.0.10-beta's record is
[`../1.0.10-beta/closure.md`](../1.0.10-beta/closure.md).

The goal does not change: every repository green under its own gate with zero tolerated reds (the
baseline in `00-gate`), then what 1.0.10 left open — the compiler's tails, std as the one place a
shared primitive lives, the packages the frameworks copy from each other, rakun on its 16-member
cut, the jhonstart / emilia / onze tails, and Astro's feature set on the stack — cut by file
ownership so that several fronts run at once, one worktree each.

## Tracks

The track number is the blocking order. A front keeps its global number and directory for good.

| Track | Fronts | What |
|---|---|---|
| [`00-gate/`](./00-gate/README.md) | 1 | The gate's baseline: the 17 rules every landing is held to (decisions 67, 153–162, 225–233, 249, 265 …). [`114`](./00-gate/114-gate-docs-and-ci/README.md): docs fences, every CI workflow hard and green, the gate's residue |
| [`01-compiler/`](./01-compiler/README.md) | 19 | The checker and parser rows, the four backends' tails, std on wasm, residuals, language tests, comptime on beam, the formatter, keyed `Ets`, comptime runtimes, std purity, effects by return, CLI tooling, 129 (done), 130 decorator outputs (216), 134 builtins declared |
| [`02-std-and-packaging/`](./02-std-and-packaging/README.md) | 2 | 97: the shared primitives in std and the copies handed to their owners; 98: the packaging rule checked everywhere (last) |
| [`03-bundled-libs/`](./03-bundled-libs/README.md) | 8 | What the frameworks copy from each other (decisions 115–117): 102 `routing.conventions`, 103 `actions.id`, 104 `http`, 105 `i18n`, 106 `log`, 107 `release` (on `07-g`), 125 Zod's feature set in `validation`; 138 the packages to their own repositories (326) |
| [`04-rakun/`](./04-rakun/README.md) | 21 | 128 merges nine members first and alone (decision 187); then the 19 member fronts in groups A → B → C on the paths it leaves; 137, erika's database target, for rakun-data's repositories (decisions 311–313) |
| [`05-jhonstart/`](./05-jhonstart/README.md) | 3 | 26 the core (one late-signal handler, no rakun in `src/`, the digest through `log`, the stage markers), 27 the reconcile driver, 67 the forms' DOM half |
| [`06-emilia/`](./06-emilia/README.md) | 2 | 34 `hashHex` → std and five families to Tailwind 4.3.2's form; 33 the `-test` member and the examples |
| [`07-onze/`](./07-onze/README.md) | 5 | 49 stand-up, 50 CLI (`onze dev`), 51 image, 71 release, 53 the example app — the proof of the stack, last |
| [`08-bpp/`](./08-bpp/README.md) | 11 | Astro's feature set on the stack: 118 the template first; 121 content, 120 islands, 117 routing, 119 scoped CSS, 127 actions, 122 data, 123 `locals`, 126 view transitions; 116 the `.bpp` file kind (the one front that edits the toolchain); 124 the CLI last |
| [`09-cardume/`](./09-cardume/README.md) | 1 | 136: `cardume`, a library of its own — shared state as atoms (Recoil's model; decision 296), its core and the two bridges `rakun-cardume`, `jhonstart-cardume` |
| [`20-snap/`](./20-snap/README.md) | 1 | 135: the nine snapshot maps re-evaluated case by case; owns every snapshot step the other fronts carried; last |

71 fronts in all. Where each stands is [`status.md`](./status.md).

## Rules in force

- **The most restrictive behaviour, and no configuration that bypasses it** (decision 67). A red
  cell is fixed, or its test is deleted by a decision — never allow-listed, expected or skipped.
- **A manifest's `targets` is the single source of truth** for where a cell exists; a target is
  excluded only when a host binding does not exist for it, and the runner proves it (decision 156).
- **The libraries split by concern** (113); **the compiler knows no library**; **a bundled library
  is neutral like std** and ships `.bp` only (115–117); **the return type is the annotation**
  (118–128); **a page signal is jhonstart's end to end** (117).
- **A library front never touches `repository/botopink-lang/modules/**`**: it files a
  [`language-gaps.md`](./language-gaps.md) row and works around the gap.
- **Examples are code, not prose**; a `// LANGUAGE GAP:` marker with no row in the Marker index
  is red (meta CI check 5).
- **A snapshot is evidence, not a baseline; the gate runs from a cold runtime cache; a backend
  builds a model and an emitter renders it.**
- **Coverage is never traded for wall clock**: the gate asserts that the cells it ran equal the
  cells that exist; over the 7m30s budget is yellow, never red (decision 265).
- **Decisions are asked, not guessed**: a question goes to `decisions-pending.md` with a
  recommendation, most restrictive first.
- **`status.md` is the only file that carries status.** Every other spec describes current state
  and remaining work; a done step is one line under its front's `## Done`.

## Where things are

| File | What |
|---|---|
| [`status.md`](./status.md) | The only status: the fronts in five lanes — finish what is on `feat`, the libraries' critical path, ready now, later waves, blocked on a decision |
| [`fronts.md`](./fronts.md) | The rules for a front, ownership by track, the conflict rules, the execution order, and § Gate (the standard landing every README cites) |
| [`decisoes-pendentes.md`](./decisoes-pendentes.md) | The pending decisions in Portuguese, ordered by what each unblocks, with an example per option — the page the maintainer answers on; `decisions-pending.md` stays the source |
| [`decisions-taken.md`](./decisions-taken.md) | The numbered decisions in force (the next free number lives only there) |
| [`decisions-pending.md`](./decisions-pending.md) | The open questions, the contradictions (`ctr-*`), the 1.0.10 choices awaiting confirmation |
| [`language-gaps.md`](./language-gaps.md) | Every compiler gap a library front meets, with its nearest form, owner and the Marker index |
| [`contracts.md`](./contracts.md) | The cross-library contracts |
| [`deferred.md`](./deferred.md) | What has no path on the BEAM or no gate cell this milestone |

A new front starts from [`../__template.md`](../__template.md).
