# Specs — 1.0.11-beta: green first, then what 1.0.10 left

1.0.11-beta opens on a measured fact: at 1.0.10-beta's close
([`closure.md`](../1.0.10-beta/closure.md)) the gate was **8 of 10 stages green**, with 36 red
library cells, one red language cell, three expected-failure lines, a 21-line ledger of tolerated
reds, 226 files outside the format check and 11 `zig fmt` reds — and every one of those had a
mechanism that let the gate report green around it. The milestone's first track deletes those
mechanisms and makes every repository green under its own gate; the other seven tracks carry
everything 1.0.10-beta left open, re-cut by **ownership of files** so that several fronts run at
the same time, one worktree each.

**Where the milestone stands is [`status.md`](./status.md)** — the one file allowed to carry status.
**What the maintainer has decided and still owes is [`decisions-taken.md`](./decisions-taken.md)
(numbering starts at 144) and [`decisions-pending.md`](./decisions-pending.md)** (the open
questions verbatim, every lettered choice indexed to the track that raised it). The 1.0.10 → 1.0.11
map is [`carried.md`](./carried.md) and each track's `carried.md`.

## Tracks

A track is a directory of fronts. The track number is the blocking order; a front inside keeps its
global number, which is an identifier and never reassigned (front 53 is still
`07-onze/53-onze-example-app/`). Numbers 97–128 are new in this milestone; compiler sub-fronts keep
`01…25`, and `26-cli-tooling` is new.

| Track | Priority | Fronts | What |
|---|---|---|---|
| [`00-gate/`](./00-gate/README.md) | **critical — first, alone** | 14 | A 100 % green gate in every repository, with **zero tolerated reds**: one front per repository that is red or tolerant (rakun 99, onze 100, jhonstart 101, erika 108, emilia 109), one per compiler area (wasm 110, beam + `.targets` 111), the formatter trees (112), the ledgers and guards (113 — both ledger files deleted; a manifest's `targets` is the only source of truth), docs-check and every CI workflow (114 — including the meta repo, which has none), and gate performance (115 — a wall-clock budget, never coverage traded for time). Decisions `gate-a…j` |
| [`01-compiler/`](./01-compiler/README.md) | high | 17 | The open compiler work of `00-compiler-carry-over`, under the same sub-front numbers: the checker (the literal join, function-typed arms, record-value call, redeclaration, `try` in a lambda, the captured `var`, the imported-type closure), each backend's tails and the cells the audit found without one (C-34…C-37), the comptime runtimes, the formatter's C-13 migration, `keyed` `Ets`, the review backlog (C-22), hygiene (C-23), `26-cli-tooling` (sidecars, `botopink clean`, `Env.warnings`) |
| [`02-std-and-packaging/`](./02-std-and-packaging/README.md) | high — before `03` | 2 | `97-std-dedupe`: what is generic goes to std (`parseInt` / `parseFloat`, `Json` accessors, `pbkdf2Sha256`, `clock.parseDuration`, `RetryPolicy`) and the copies in the libraries are deleted by the fronts that own them; `98-packaging-tail`: example READMEs, `-test` helpers, front 95 closed |
| [`03-bundled-libs/`](./03-bundled-libs/README.md) | medium — after `00` and `97` | 7 | What the frameworks copy from each other, extracted under decisions 115–117: `routing` gains `conventions`, `actions` gains `id`, new `http` (cookie, accept, mime, status, date, range — decision 196), `i18n`, `log` (the one error digest and the render's way to the logger — decisions 194, 195); `release` conditional on `07-g`; **125** — Zod's feature set in `validation`: `#[schema]` derives `parse<T>` from a type, `Schema<T>` is the composable value, 58 more checks ([`surface.md`](./03-bundled-libs/125-validation-zod/surface.md), 205 reference rows). Decisions `07-a…n` |
| [`04-rakun/`](./04-rakun/README.md) | per front | 20 | **128 first**: nine of the 25 members merge into the member that always loads or solely uses them (decision 187); then the 51 carried fronts consolidated by member, at the paths 128 leaves; **09 data-nosql** is the one never started; the two cells that read `skipped` as green become real assertions (in-process doubles, decision 160); `modules.md` re-derived from the tree. Decisions `03r-y…am` — eight still open |
| [`05-jhonstart/`](./05-jhonstart/README.md) | per front | 3 | 26 (with 28 · 29 · 30 · 31): one late-signal handler, the streaming tests, the error digest through the bundled `log` (decisions 194, 195), the two stage markers `#[serverOnly]` / `#[clientOnly]` (decision 186); 27: the `reconcile` driver; 67: the DOM-side form boxes |
| [`06-emilia/`](./06-emilia/README.md) | medium | 2 | 34: `hashHex` → std, five Tailwind families to upstream's form; 33: the test and examples layer, conditional on `05emilia-m` |
| [`07-onze/`](./07-onze/README.md) | per front | 5 | 49 stand-up (the public root, `serveActions`, the `log` sink, the bridge for the dynamic mark until decision 186's compile-time stage lands), 50 CLI (`onze dev`, SIGTERM), 51 image (with 52 · 70), 71 release (a bootable tarball, verified), **53 the example app** — the proof of the stack, last |
| [`08-bpp/`](./08-bpp/README.md) | per front | 11 | **New in this milestone.** Astro's feature set on the stack ([`surface.md`](./08-bpp/surface.md): of 160 reference rows, 60 are on disk, 14 are on disk and not connected, 70 are added here). 118: the template language (`jhonstart-html`); 121: Markdown, frontmatter, collections (a new onze member); 120: hydration strategies and server islands; 117: `.bpp` / `.md` pages, static paths with data, pagination, partials; 119: scoped `<style>` (emilia); 127: actions typed by a schema; 122: the request surface; 123: `locals` and `sequence`; 126: view transitions; 116: the `.bpp` file kind — another spelling of a `.bp` module, unfolded by the toolchain onto the `pub default fn` of the package the application's manifest names (`"bpp": "<package>"`; decisions 198, 199), the only front that edits the compiler; 124: the build and the config keys. Decisions `08-a…i` — `08-a`, `08-a2`, `08-a3`, `08-c`, `08-i` answered (190–193, 198–200) |

Top-level documents: [`fronts.md`](./fronts.md) (ownership, the conflict rules, the parallel groups,
the exit gate) · [`contracts.md`](./contracts.md) (the cross-library contracts, carried) ·
[`language-gaps.md`](./language-gaps.md) (every compiler gap a library front filed, carried and
re-owned, ten rows added) · [`deferred.md`](./deferred.md) (what has no path on BEAM, carried) ·
[`carried.md`](./carried.md) (1.0.10 → 1.0.11).

## Order

```
wave 0    00-gate ─── 112-format · 110-wasm · 99-rakun · 100-onze · 101-jhonstart · 108-erika · 109-emilia   (7 in parallel)
                        └──► 111-beam-and-targets ──► 113-ledger-and-scripts ──► 115-perf
                        114-docs-and-ci any time
          nothing else lands on feat until 113 is green: the gate is what decides a merge
                                                             │
then      02-std-and-packaging/97-std-dedupe (alone: libs/std) ▼
          01-compiler group A (7 in parallel: 01 · 02 · 03 · 04 · 05 · 14 · 26) — group B beside (12 · 18 · 23 · 24 · 25),
          then 17 · 16 · 07 · 08 · 09 (sequenced)
                                                             │
tracks 03–08, in ten waves of at most six threads (fronts.md § Execution order of tracks 03–08):
  1   the package branches land (102 · 103 · 125) · 102 step 3 + 103 step 2 (the consumer commits, first) ·
      128 rakun consolidation (alone in rakun) · 118 · 106 log · 104 http package · 71
  2   04 · 49 · 26 · 50 · 19 step 1 · 27
  3   22 · 13 · 67 · 51 · 34 · 121 (steps 1–3)
  4   65 · 12 · 15 · 17 · 119 · 74
  5   53 · 117 · 123 · 81 · 79 · 125 (steps 3–10)
  6   120 · 121 (steps 4–5) · 08 · 11 · 92 · 19 (steps 2–5)
  7   122 · 126 · 121 (step 6) · 104 consumer sweep · 93 · 73
  8   127 · 88 · 91 · 09 · 33 (steps 1–2) · 71 (step 5)
  9   124 (steps 1–4) · 105 · 121 (step 7) · the conditional ones: 107 · 33 (steps 3–4) · 26 (step 7)
  10  124 (step 5: the second example app, the blog as `.bpp`) — then 02/98-packaging-tail
  116 opens when 118, 26 and 01-compiler/26 have landed
```

**Where it stands (2026-10-02).** `00-gate` is not green: its compiler fronts are committed on one
local integration branch waiting for one `gate.sh --cold`; only the jhonstart, erika and emilia
tips are on a remote, and their CI is red. Nothing of the waves above can land before it;
[`status.md`](./status.md) carries the detail.

**Why `00-gate` is first and alone.** Every other front lands through `scripts/gate.sh --cold`, and
today that gate reports green around 36 red cells. A front that lands on a gate with an allow-list
cannot tell its own red from a tolerated one; the library fronts of `04-rakun` and `07-onze` edit the
same files the gate fronts migrate off `(if …)` operands, so they start from the gate fronts'
result, not beside them. `114-docs-and-ci` is the exception that runs any time: it touches nothing
the others do.

**Why `97-std-dedupe` precedes `03-bundled-libs`.** Every extraction deletes a hand-rolled
`parseInt` or `Json` accessor in the files it touches; without std's replacement it can delete
nothing.

**Why the compiler runs beside and not ahead.** As in 1.0.10: a library front that meets a missing
compiler feature files a row in `language-gaps.md` and works around it. The `lg2-*` rows open no
front until the maintainer answers them.

**Why `08-bpp` starts with a library and not with the compiler.** Its keystone is the template
function in `jhonstart-html` (118): every other front of the track writes markup through it, and
every feature is testable from a `.bp` module. The `.bpp` file kind (116) is another spelling of
such a module (decision 198): the application's manifest names a package (`"bpp": "<package>"`),
everything before a `---` line is ordinary botopink, and the rest is the literal handed to that
package's `pub default fn`, so no tool learns a syntax. It is the one front of the track that
edits `repository/botopink-lang`; the manifest reads `"bpp": "jhonstart"`, whose default
function is `html` once `jhonstart-html` has merged into the core (decision 200).
`125-validation-zod`'s first three steps precede the two fronts that take a `Schema<T>` (121's
collections, 127's actions).

## Rules carried forward

- **The most restrictive behaviour, and no configuration that bypasses it** (decision 67). In this
  milestone it has a corollary the first track enforces: **a red cell is fixed, or its test is
  deleted by a decision — never allow-listed.** `expected-failures.txt`, `restricted-targets.txt`,
  `known-red-libs.txt`, `known-broken-examples.txt`, `docs-check: skip`, `allow_fail`, a `.targets`
  file that hides a backend gap, a cell that reports `skipped` as green — each is either deleted or
  turned into a structural rule the runner audits (`gate-a…j`).
- **A manifest's `targets` is the single source of truth** for where a cell exists; a target is
  excluded only because a host binding does not exist for it, and the runner proves that.
- **The libraries split by concern** (decision 113); **the compiler knows none of them**; **a
  bundled library is neutral like std** and ships `.bp` only (decisions 115–117); **the return type
  is the annotation** (118–128); **a page signal is jhonstart's end to end** (117).
- **Examples are code, not prose**; a `// LANGUAGE GAP:` marker with no row is red (the gate greps
  every repository, excluding the frozen `specs/1.0.10-beta/**`).
- **A snapshot is evidence, not a baseline; the gate runs from a cold runtime cache; a backend
  builds a model and an emitter renders it.**
- **Coverage is never traded for wall clock** (`115-gate-perf`): the gate asserts that the number of
  cells it ran equals the number that exist.
- **`status.md` is the only file that carries status.** Every other spec describes current state and
  remaining work; a front's README becomes the record of what shipped when it lands.
