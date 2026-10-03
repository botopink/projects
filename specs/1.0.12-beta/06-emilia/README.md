# Track 06 — emilia

**Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 docs (4.3.2 compiled output) · the
tree on disk is [`modules.md`](./modules.md).

emilia is CSS (decision 113): a `Token` enum resolved through a theme and emitted as a layered
`<style>` document, compiled and tested on both targets, importing nobody. It is green (`emilia`
734 tests on both rows, fifteen example members, `emilia-test` 1). What is left is one std-dedupe
box, five Tailwind families out of parity with 4.3.2, a handful of unplaced rows, the examples'
READMEs and an emilia-only `emilia-card` (the test layer is `20-snap`'s). Two fronts, cut by file: the library's source (every
family lives in `emilia.bp` / `tokens.bp`) and the test member plus the examples.

## What emilia still owes

| Id | Item | Where | Front |
|---|---|---|---|
| EM-1 | `hashHex` (`emilia.bp:95-97`, used at `:114`) is a copy of std's `hash.contentHash`; the switch is one import, the fixture `e_39b87d03` must not move. The `output.bp:379-388` comment explains a commonJS prelude defect (C-37) that is closed in the compiler (`01-compiler/04-js`) — the comment is emilia's to drop | `modules/emilia/src/emilia.bp`, `output.bp` | 34 step 1 |
| EM-11 | six comment lines of `modules/` name another library (`attributes.bp:4,30`, `emilia.bp:110,16500,16501,16510`), and five name jhonstart's `[name]={…}` DSL spelling (`attributes.bp:30,32,36`, `emilia.bp:185,202`) — decision 114's grep cannot be empty | `modules/emilia/src/` | 34 step 1 |
| EM-8 | five families out of parity with 4.3.2 (05emilia-l's tail): transition presets write `var(--ease-out)` / `150ms` where upstream writes `var(--tw-ease, var(--default-transition-timing-function))` / `var(--tw-duration, …)` and sets `--tw-ease`; `backdrop-opacity-*` is `opacity(0.5)` for upstream's `opacity(50%)`; `border-spacing-*` writes the property for upstream's `--tw-border-spacing-{x,y}`; the backdrop filters omit `-webkit-backdrop-filter`; `divide-*` omits `border-*-style:var(--tw-border-style)` | `emilia.bp` blocks 44 · 42 · 43 · 40; `examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` where they pin the output | 34 step 2 |
| EM-9 | the unplaced rows of `34-emilia-modifiers/reference-rows.md`, category (c): named `:has()` / `:not()` / ARIA / data-attribute / `in-[…]` forms; named `group/name` / `peer/name`; a cleared `--breakpoint-*` emits `@media (width >= )` instead of refusing; `@theme inline`; negative translate (`tokens.bp:2259-2279` has no `Neg`) | `tokens.bp`, `emilia.bp` blocks 34 · 54 · 45 | 34 steps 3 (the refusal) and 4 (the rest, on 05emilia-n) |
| EM-3 | `emilia-test` exposes no `assert<Subject>` — `root.bp` holds one resolve test (PK-4) | `modules/emilia-test/src/**` | `20-snap` step 4 (`snap-a`) |
| EM-7 | `emilia-card` depends on jhonstart (`botopink.json` `"jhonstart": { "path": … }`); decision 114 makes it emilia-only, printing its class names and flushed sheet | `examples/emilia-card/**` | 33 step 2 |
| PK-2 | fifteen example members without `README.md` | `examples/*/README.md` | 33 step 2 |
| EM-4 · EM-5 | the per-front snapshot suites and the eight cross-front examples of the 1.0.10 maps — the 610 inline tests in `emilia.bp` are the evidence today | `modules/emilia/test/**`, `examples/<new>/**` | `20-snap` step 4 (`snap-a`) |

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`34-emilia-modifiers/`](./34-emilia-modifiers/README.md) | **high** — the parity tail moves pinned output every later snapshot would re-record | not started | `modules/emilia/src/**`: `hashHex` → std and the cross-library comments; the five families to upstream's form; the breakpoint refusal; the unplaced rows (on 05emilia-n); the examples that pin the moved families | 05emilia-l (step 2), 05emilia-n (step 4) — opens now |
| [`33-emilia-color-palette/`](./33-emilia-color-palette/README.md) | medium | not started | the fifteen READMEs, `emilia-card` emilia-only (step 2); steps 1, 3, 4 (the helpers, the suites, the examples) → `20-snap` | step 2: nothing — open now |

## Order

```
34-emilia-modifiers ─────────────────────────────────┐   (modules/emilia/src/** and four examples' src/main.bp)
33 step 2 (READMEs, emilia-card) ────────────────────┘   (examples/*/README.md, examples/emilia-card/**)
   20-snap step 4 (emilia-test's two helpers) — after 34, which moves the output they record

outbound: nothing — emilia imports nobody; onze 68 reads `styleRule` and the fixture, which 34 keeps byte-identical
inbound:  08-bpp/119 step 1 ──► new `modules/emilia/src/scoped.bp` and its test, beside 34 (119 appends its line to
                                `root.bp` / `botopink.json`, which no step of 34 edits)
```

34 is the only editor of `emilia.bp` and `tokens.bp`, and a snapshot recorded before a family
moves is recorded twice, so `20-snap`'s emilia step follows it. 33 step 2 shares no file with it
and runs beside it. `08-bpp/118` step 1's bracket-attribute carve-out does not gate
either front: in emilia it touches only comments (no code uses `[name]={`) — 34 step 1 rewords
those of `attributes.bp` / `emilia.bp`, and 33 step 2 rewrites `emilia-card` (`src/main.bp:5`).

## Decisions

Confirmations kept from 1.0.10 ([`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) § Track D):

| Id | Choice | Closes |
|---|---|---|
| 05emilia-a … 05emilia-k | the filter chain inline; `BackdropFilter`; `drop-shadow-none`; snap strictness fallback; `fullOptions()`; `--inset-shadow-*`; `space-*` / `divide-*` selector; siblings never import `from "emilia"`; `@property` blocks; selector-list modifiers; `spacingNegHalf` | — |
| 05emilia-l | confirming a column moves its whole family to upstream's form — its § Blocks names the five families 34 step 2 moves | 34 step 2 (the confirmation settles that the rule applies to families no open row named) |

The snapshot suites and the eight cross-front examples are [`decisions-pending.md`](../decisions-pending.md) `snap-a`, worked by [`20-snap`](../20-snap/README.md) step 4.

### 05emilia-n · The unplaced Tailwind rows — declare them, or leave them to `arbSel`

> **Raised by:** front 34, from [`34-emilia-modifiers/reference-rows.md`](./34-emilia-modifiers/reference-rows.md)
> (category (c)).
> **Measured.** Five rows have no owner: the named `:has()` / `:not()` / ARIA / data-attribute /
> `in-[…]` forms (reachable through `arbSel` only); named groups and peers (`group/item`,
> `peer/name` — six group and eight peer states exist, unnamed); `@theme inline` (emilia always
> emits `var(--x)`); negative translate (`Rotate.Neg` exists, `TranslateX/Y.Neg` does not,
> `tokens.bp:2259-2279`); and one that is not a feature but a hole — a cleared `--breakpoint-*`
> makes the variant emit `@media (width >= )` instead of refusing, as 58 refuses an emptied
> container size.
> **Options.** (a) the refusal only: a cleared breakpoint panics naming the entry, as 58 does;
> the four feature rows stay out of scope, stated in `docs.md` § Deviations (`arbSel` is the
> spelling); (b) (a) plus negative translate and named groups/peers (two token sections, one
> `Variant` fn each — small, upstream-shaped); (c) all five, including `@theme inline` (a second
> render mode over every `var()` site — large).
> **Recommendation.** (a) — the refusal is decision 67 and not optional; the rest is a feature
> decision. (b) is the recommended *feature* answer if the maintainer wants any: negative
> translate is the one row a user meets first (`-translate-y-2`), and named groups are the one
> modifier upstream documents that `arbSel` cannot spell readably.
> **Blocks.** 34 step 4; step 3 (the refusal) is not conditional.
