# Track 06 — emilia

**Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 docs (4.3.2 compiled output) ·
**Carried from:** `specs/1.0.10-beta/05-emilia/` (22 fronts: 33–48 · 54–59) — the mapping is
[`carried.md`](./carried.md); the tree as it is on disk is [`modules.md`](./modules.md).

emilia is CSS (decision 113): a `Token` enum resolved through a theme and emitted as a layered
`<style>` document, compiled and tested on both targets, importing nobody. 1.0.10 landed all 22
fronts — 734 / 734 on both rows, fifteen example members, `emilia-test` 1 / 1. What is left is
one dedupe box, five Tailwind families measured out of parity after the fronts closed, a handful
of unplaced rows, and the test-and-examples layer the maps specify. Two fronts, cut by file: the
library's source (one front, because every family lives in `emilia.bp` / `tokens.bp`) and the
test member plus the examples (the other).

## What emilia still owes

| Id | Item | Where | Front |
|---|---|---|---|
| EM-1 | `hashHex` (`emilia.bp:95-97`, used at `:114`) is a copy of std's `hash.contentHash`; the switch is one import, the fixture `e_39b87d03` must not move; the `output.bp:386` comment explains a commonJS prelude defect (a `charCodeAt` patch that recurses when `String.slice` is used in the same module) — a compiler row, not emilia's | `modules/emilia/src/emilia.bp`, `output.bp` | 34 |
| EM-8 | five families out of parity with 4.3.2 (05emilia-l's tail): transition presets write `var(--ease-out)` / `150ms` where upstream writes `var(--tw-ease, var(--default-transition-timing-function))` / `var(--tw-duration, …)` and sets `--tw-ease`; `backdrop-opacity-*` is `opacity(0.5)` for upstream's `opacity(50%)`; `border-spacing-*` writes the property for upstream's `--tw-border-spacing-{x,y}` (`emilia.bp:12811-12897`); the backdrop filters omit `-webkit-backdrop-filter`; `divide-*` omits `border-*-style:var(--tw-border-style)` | `emilia.bp` blocks 44 · 42 · 43 · 40; `examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` where they pin the output | 34 |
| EM-9 | the unplaced rows of `reference-coverage.md` § Missing and partial, category (c): named `:has()` / `:not()` / ARIA / data-attribute / `in-[…]` forms; named `group/name` / `peer/name`; a cleared `--breakpoint-*` emits `@media (width >= )` instead of refusing; `@theme inline`; negative translate (`tokens.bp:2259-2279` has no `Neg`) | `tokens.bp`, `emilia.bp` blocks 34 · 54 · 45 | 34 (the refusal unconditionally; the rest on 05emilia-n) |
| EM-3 | `emilia-test` exposes no `assert<Subject>` — `root.bp` holds one resolve test; the eight helpers of `test-snap.md` § The helpers (`assertCss`, `assertCssWith`, `assertUtility`, `assertVariant`, `assertTheme`, `assertRules`, `assertCascade`, `assertClassName`) are unwritten (PK-4) | `modules/emilia-test/src/**` | 33 |
| EM-4 | the per-front snapshot suites (21 `modules/emilia/test/<front>_test.bp` + `__snapshots__/`) — the 610 inline tests in `emilia.bp` are the evidence today | `modules/emilia/test/**` | 33 (conditional on 05emilia-m) |
| EM-5 | eight cross-front examples of `test-snap-examples.md` (`theme-brand`, `dashboard-layout`, `typography-article`, `interactive-button`, `dark-mode-nav`, `media-gallery`, `arbitrary-and-compose`, `class-attributes`) | `examples/<new>/**` | 33 (conditional on 05emilia-m) |
| EM-7 | `emilia-card` depends on jhonstart (`botopink.json` `"jhonstart": { "path": … }`); decision 114 makes it emilia-only, printing its class names and flushed sheet | `examples/emilia-card/**` | 33 |
| PK-2 | fifteen example members without `README.md` | `examples/*/README.md` | 33 |
| PK-3 | "`emilia-card` prints what it printed before the move" — superseded by EM-7 | — | 33 |

Not carried as work: EM-2 (front 48's last box — onze 68's `build_test.bp:104` asserts the
literal; closed on tick), the `extendTheme` refusal in the compiler suite (54's box — the message
is asserted in the compiler's `reject/` cells; closed on tick), and the three stale `// LANGUAGE
GAP` markers in the frozen spec examples (EM-10, `00-gate`).

## Fronts

| Front | Priority | Carries | Parallel group | What |
|---|---|---|---|---|
| [`34-emilia-modifiers/`](./34-emilia-modifiers/README.md) | **high** — EM-1 is the one std dedupe consumer in emilia, and the parity tail moves pinned output every later snapshot would re-record | 40 · 42 · 43 · 44 · 45 · 54 · 56 | A | `modules/emilia/src/**`: `hashHex` → std; the five families to upstream's form; the breakpoint refusal; the unplaced rows (conditional); the examples that pin the moved families |
| [`33-emilia-color-palette/`](./33-emilia-color-palette/README.md) | medium — the `-test` member is mandatory (02-packaging § 5); the rest is conditional | 35 · 36 · 37 · 38 · 39 · 41 · 46 · 47 · 48 · 55 · 57 · 58 · 59 (their maps) | A for steps 1–2 (file-disjoint from 34); B for steps 3–4 (records after 34) | `modules/emilia-test/**`, the fifteen READMEs, `emilia-card` emilia-only; then, on 05emilia-m, the snapshot suites and the eight examples |

## Order

```
97-std-dedupe (track 02) ──► 34-emilia-modifiers step 1 (hash.contentHash exists already; 97 only records the consumer)

34-emilia-modifiers ────────────┐   (A: modules/emilia/src/** and four examples' src/main.bp)
33 steps 1–2 (test member, READMEs, emilia-card) ──┤   (A: modules/emilia-test/**, examples/*/README.md, examples/emilia-card/**)
                                └──► 33 steps 3–4 (B: modules/emilia/test/__snapshots__/, eight new examples — records what 34 pinned)

outbound: nothing — emilia imports nobody; onze 68 reads `styleRule` and the fixture, which 34 keeps byte-identical
inbound:  08-bpp/118 step 1 ──► one-line carve-outs: the `[name]={expr}` attributes in `attributes.bp` and `emilia.bp` (34's files)
                                and in `examples/emilia-card` (33's) — landed before 34 and 33 open (decision 189)
          08-bpp/119 step 1 ──► new `modules/emilia/src/scoped.bp` and its test, beside 34 (34 does not edit `root.bp` or
                                `botopink.json`, which are its by ownership; 119 appends its line)
```

34 runs first among the source edits because it is the only editor of `emilia.bp` and
`tokens.bp`, and because a snapshot recorded before a family moves is recorded twice. 33's
member and README steps share no file with it and run beside it. Neither opens before
`08-bpp/118` step 1 has landed its carve-out in the file the front owns: 118 refuses the bracket
attribute and rewrites its ten uses in the same landing, as named one-line edits sequenced with
the owners (decision 189).

## Handed to 00-gate

| Item | File | Fix |
|---|---|---|
| EM-6 / STD-1 — no `*.snap.new` guard | `repository/emilia/.gitignore`, `scripts/git-hooks/pre-commit` (measured: no `snap.new` line) | the `02-std-and-packaging` track's row |
| EM-10 — three stale `// LANGUAGE GAP:` markers whose gap closed (the nested payload leaf, 01-checker step 12) | `specs/1.0.10-beta/05-emilia/33-emilia-color-palette/examples/palette-example.bp:108`, `40-emilia-borders/examples/borders-example.bp:80`, `41-emilia-effects/examples/effects-example.bp:45` (frozen record) | the gate's marker grep excludes `specs/1.0.10-beta/**`; no 1.0.11-beta emilia example carries a marker (measured: `grep -c` 0) |
| the `output.bp:386` comment — a commonJS prelude defect (the `String` behavior prelude's `charCodeAt` patch is self-recursive once `slice` is used in a module) described in a comment with no row | `repository/emilia/modules/emilia/src/output.bp:379-388` | a compiler row for this milestone's `language-gaps.md` (`01-compiler/04-js`, C-37); emilia keeps the workaround (`split("\t")`) until it closes |
| the examples' `targets` | — | none stale: `emilia-card` is `["commonJS", "erlang"]` (02-packaging's 1.0.10 row); no emilia ledger line exists |

## Maintainer decisions

Ids kept from 1.0.10 (`specs/1.0.10-beta/decisions-pending.md` § Track D, `05emilia-a…l`); new
questions continue the sequence. Numbered decisions continue from 214 when answered.

### To confirm

| Id | Choice | Closes |
|---|---|---|
| 05emilia-a … 05emilia-k | the filter chain inline; `BackdropFilter`; `drop-shadow-none`; snap strictness fallback; `fullOptions()`; `--inset-shadow-*`; `space-*` / `divide-*` selector; siblings never import `from "emilia"`; `@property` blocks; selector-list modifiers; `spacingNegHalf` | — |
| 05emilia-l | confirming a column moves its whole family to upstream's form — **and its § Blocks names the five families 34 step 2 moves** | 34 step 2 (the families are moved under the same rule; the confirmation settles that the rule applies to families no open row named) |

### 05emilia-m · The snapshot suites and the eight cross-front examples — realise or retire

> **Raised by:** front 33, from `test-snap.md` (2 341 lines) and `test-snap-examples.md` (735),
> both copied to `33-emilia-color-palette/`
> **Measured.** The maps name one `.snap` per case for 21 per-front suites under
> `modules/emilia/test/` and eight example projects with their own snapshots. None exists. What
> exists: 610 inline tests in `emilia.bp` (734 across the member) assert every rendered literal
> on both rows; fifteen example members assert their strings inline; the one contract another
> library reads — the class literal `e_39b87d03` of contract 4 — is asserted by emilia, by
> jhonstart's `bridge_test.bp` and by onze's `build_test.bp:104`.
> **Options.** (a) retire both maps: the inline literals are the evidence, the contract-4 literal
> has three readers already, and a `.snap` of a utility's CSS proves nothing a consumer reads;
> `emilia-test` keeps the two helpers a consumer can use (`assertCss`, `assertClassName`) and the
> fixture builders; (b) realise the module map only (21 suites, ~600 files, each a second copy of
> a literal in `emilia.bp`); (c) realise both (the eight examples are ~50 more members' worth of
> inline tests plus snapshots).
> **Recommendation.** (a). A module-level snapshot is realised only where it proves a contract
> another library reads; emilia's one such contract already has readers on both sides. The eight
> examples were written as a coverage map before the fronts landed; every family they exercise is
> exercised by the fifteen per-front examples that exist.
> **Blocks.** 33 steps 3–4 (conditional).

### 05emilia-n · The unplaced Tailwind rows — declare them, or leave them to `arbSel`

> **Raised by:** front 34, from `reference-coverage.md` § Missing and partial (category (c),
> copied to `34-emilia-modifiers/reference-rows.md`)
> **Measured.** Five rows have no owner: the named `:has()` / `:not()` / ARIA / data-attribute /
> `in-[…]` forms (reachable through `arbSel` only); named groups and peers (`group/item`,
> `peer/name` — six group and eight peer states exist, unnamed); `@theme inline` (emilia always
> emits `var(--x)`); negative translate (`Rotate.Neg` exists, `TranslateX/Y.Neg` does not,
> `tokens.bp:2259-2279`); and one that is not a feature but a hole — a cleared `--breakpoint-*`
> makes the variant emit `@media (width >= )` instead of refusing, as 58 refuses an emptied
> container size.
> **Options.** (a) the refusal only: a cleared breakpoint panics naming the entry, as 58 does;
> the four feature rows stay out of scope, stated in `reference-coverage.md` § Deviations
> (`arbSel` is the spelling); (b) (a) plus negative translate and named groups/peers (two token
> sections, one `Variant` fn each — small, upstream-shaped); (c) all five, including `@theme
> inline` (a second render mode over every `var()` site — large).
> **Recommendation.** (a) — the refusal is decision 67 and not optional; the rest is a feature
> decision. (b) is the recommended *feature* answer if the maintainer wants any: negative
> translate is the one row a user meets first (`-translate-y-2`), and named groups are the one
> modifier upstream documents that `arbSel` cannot spell readably.
> **Blocks.** 34 step 4 (conditional); step 3 (the refusal) is not conditional.
