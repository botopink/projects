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
(numbering continues at 144) and [`decisions-pending.md`](./decisions-pending.md)** (the 27 open
questions verbatim, every lettered choice indexed to the track that raised it). The 1.0.10 → 1.0.11
map is [`carried.md`](./carried.md) and each track's `carried.md`.

## Tracks

A track is a directory of fronts. The track number is the blocking order; a front inside keeps its
global number, which is an identifier and never reassigned (front 53 is still
`06-onze/53-onze-example-app/`). Numbers 97–115 are new in this milestone; compiler sub-fronts keep
`01…25`, and `26-cli-tooling` is new.

| Track | Priority | Fronts | What |
|---|---|---|---|
| [`00-gate/`](./00-gate/README.md) | **critical — first, alone** | 11 | A 100 % green gate in every repository, with **zero tolerated reds**: one front per repository that is red or tolerant (rakun 99, onze 100, jhonstart 101, erika 108, emilia 109), one per compiler area (wasm 110, beam + `.targets` 111), the formatter trees (112), the ledgers and guards (113 — both ledger files deleted; a manifest's `targets` is the only source of truth), docs-check and every CI workflow (114 — including the meta repo, which has none), and gate performance (115 — a wall-clock budget, never coverage traded for time). Decisions `gate-a…j` |
| [`01-compiler/`](./01-compiler/README.md) | high | 17 | The open compiler work of `00-compiler-carry-over`, under the same sub-front numbers: the checker (the literal join, function-typed arms, record-value call, redeclaration, `try` in a lambda, the captured `var`, the imported-type closure), each backend's tails and the cells the audit found without one (C-34…C-37), the comptime runtimes, the formatter's C-13 migration, `keyed` `Ets`, the review backlog (C-22), hygiene (C-23), `26-cli-tooling` (sidecars, `botopink clean`, `Env.warnings`) |
| [`02-std-and-packaging/`](./02-std-and-packaging/README.md) | high — before `07` | 2 | `97-std-dedupe`: what is generic goes to std (`parseInt` / `parseFloat`, `Json` accessors, `pbkdf2Sha256`, `clock.parseDuration`, `RetryPolicy`) and the copies in the libraries are deleted by the fronts that own them; `98-packaging-tail`: example READMEs, `-test` helpers, front 95 closed |
| [`03-rakun/`](./03-rakun/README.md) | per front | 19 | 51 fronts consolidated by member; **09 data-nosql** is the one never started; the two cells that read `skipped` as green become real assertions (in-process doubles, `03r-aa`); `modules.md` re-derived from the tree. Decisions `03r-y…am` |
| [`04-jhonstart/`](./04-jhonstart/README.md) | per front | 3 | 26 (with 28 · 29 · 30 · 31): one late-signal handler, the streaming tests, `RenderHooks.onError` for 31-b; 27: the `reconcile` driver; 67: the DOM-side form boxes |
| [`05-emilia/`](./05-emilia/README.md) | medium | 2 | 34: `hashHex` → std, five Tailwind families to upstream's form; 33: the test and examples layer, conditional on `05emilia-m` |
| [`06-onze/`](./06-onze/README.md) | per front | 5 | 49 stand-up (the public root, `serveActions`, one writer for the dynamic mark), 50 CLI (`onze dev`, SIGTERM), 51 image (with 52 · 70), 71 release (a bootable tarball, verified), **53 the example app** — the proof of the stack, last |
| [`07-bundled-libs/`](./07-bundled-libs/README.md) | medium — after `00` and `97` | 6 | What the frameworks copy from each other, extracted under decisions 115–117: `routing` gains `conventions`, `actions` gains `id`, new `http` (cookie, accept, mime, status, date, range), `i18n`; `log` and `release` conditional on `07-f` / `07-g`. Decisions `07-a…i` |

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
wave 1    02-std-and-packaging/97-std-dedupe (alone: libs/std) ▼
          01-compiler group A (7 in parallel: 01 · 02 · 03 · 04 · 05 · 14 · 26) — group B beside (12 · 18 · 23 · 24 · 25)
          03-rakun group A (04 · 74 · 08 · 15 · 79 · 81 · 93 · 19-step-1)      04-jhonstart 26 · 27
          05-emilia 34 · 33 (steps 1–2)                                          06-onze 49 · 50 · 51 · 71
                                                             │
wave 2    07-bundled-libs 102 · 103 · 104 (3 in parallel)   ▼   03-rakun group B (13 · 17 · 22 · 12 · 11 · 65 · 09 · 91 · 92 · 73)
          01-compiler 17 · 16 · 07 · 08 · 09 (sequenced)         04-jhonstart 67 · 05-emilia 33 (steps 3–4)
                                                             │
wave 3    07-bundled-libs 105 · 106 · 107                     ▼   03-rakun group C (88 · 19 steps 3–5) · 06-onze 53 · 02/98-packaging-tail
```

**Why `00-gate` is first and alone.** Every other front lands through `scripts/gate.sh --cold`, and
today that gate reports green around 36 red cells. A front that lands on a gate with an allow-list
cannot tell its own red from a tolerated one; the library fronts of `03-rakun` and `06-onze` edit the
same files the gate fronts migrate off `(if …)` operands, so they start from the gate fronts'
result, not beside them. `114-docs-and-ci` is the exception that runs any time: it touches nothing
the others do.

**Why `97-std-dedupe` precedes `07-bundled-libs`.** Every extraction deletes a hand-rolled
`parseInt` or `Json` accessor in the files it touches; without std's replacement it can delete
nothing.

**Why the compiler runs beside and not ahead.** As in 1.0.10: a library front that meets a missing
compiler feature files a row in `language-gaps.md` and works around it. The `lg2-*` rows open no
front until the maintainer answers them.

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
