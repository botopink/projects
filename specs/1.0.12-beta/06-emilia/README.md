# Track 06 — emilia

**Repo:** `repository/emilia` · **Reference:** Tailwind CSS v4 docs (4.3.2 compiled output) · tree on
disk: [`modules.md`](./modules.md).

emilia is CSS (decision 113): a `Token` enum resolved through a theme, emitted as a layered `<style>`
document, both targets, importing nobody — until `34` step 5 makes it the third layer over the
repositories `css` and `styled` (decision 338: each family a `styledProperty`, the theme mechanism
`styled`'s, Tailwind's values emilia's). Green (`emilia` 734 tests on both rows, fifteen example
members, `emilia-test` 1). Left: one std-dedupe box, five Tailwind families out of parity with
4.3.2, a few unplaced rows (test layer is `20-snap`'s). Two fronts by file: library source (every family in `emilia.bp` / `tokens.bp`), and
test member plus examples.

## What emilia still owes

| Id | Item | Where | Front |
|---|---|---|---|
| EM-1 | `hashHex` (`emilia.bp:95-97`, used at `:114`) copies std's `hash.contentHash`; one import, fixture `e_39b87d03` must not move. `output.bp:379-388`'s comment explains a commonJS prelude defect (C-37) closed in the compiler (`01-compiler/04-js`) — emilia drops it | `modules/emilia/src/emilia.bp`, `output.bp` | 34 step 1 |
| EM-11 | six comment lines of `modules/` name another library (`attributes.bp:4,30`, `emilia.bp:110,16500,16501,16510`), five name jhonstart's `[name]={…}` DSL spelling (`attributes.bp:30,32,36`, `emilia.bp:185,202`) — decision 114's grep cannot be empty | `modules/emilia/src/` | 34 step 1 |
| EM-8 | five families out of parity with 4.3.2 (decision 350 moves them) — table in [34 § Mechanism](./34-emilia-modifiers/README.md): transition presets, `backdrop-opacity-*`, `border-spacing-*`, backdrop filters' `-webkit-backdrop-filter`, `divide-*`'s `border-*-style:var(--tw-border-style)` | `emilia.bp` blocks 44 · 42 · 43 · 40; `examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` where they pin the output | 34 step 2 (after step 5, 350) |
| EM-9 | unplaced rows of `34-emilia-modifiers/reference-rows.md`, category (c): named `:has()` / `:not()` / ARIA / data-attribute / `in-[…]` forms; named `group/name` / `peer/name`; a cleared `--breakpoint-*` emits `@media (width >= )` instead of refusing; `@theme inline`; negative translate (`tokens.bp:2259-2279` has no `Neg`) | `tokens.bp`, `emilia.bp` blocks 34 · 54 · 45 | 34 steps 3 (the refusal, decision 300) and 4 (the four feature rows, on 05emilia-n) |
| EM-12 | emilia's own sheet model (`Rule`, `Sheet`, `renderRule`, `renderDocument`, the per-render store) and string-built families become `styled` components (`styledProperty "…"`); the theme mechanism moves to `styled`, `defaultTheme()` stays (decision 338) | `modules/emilia/src/{output,emilia,spacing,theme}.bp`, `botopink.json` | 34 steps 3, 5 |
| EM-3 | `emilia-test` exposes no `assert<Subject>` — `root.bp` holds one resolve test (PK-4) | `modules/emilia-test/src/**` | `20-snap` step 4 (`snap-a`) |
| EM-4 · EM-5 | per-front snapshot suites and the eight cross-front examples of the 1.0.10 maps — the 610 inline tests in `emilia.bp` are today's evidence | `modules/emilia/test/**`, `examples/<new>/**` | `20-snap` step 4 (`snap-a`) |

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`34-emilia-modifiers/`](./34-emilia-modifiers/README.md) | **high** — emilia on `styled` first (350); the parity tail moves pinned output every later snapshot would re-record | step 1 done; step 5's text boxes done, the rest on `34-a` · `34-b` · `34-c` | `modules/emilia/src/**`: `hashHex` → std and the cross-library comments; the five families to upstream's form; Tailwind's theme values over `styled`'s `#[theme]` (300, 338); the four unplaced feature rows (on 05emilia-n); the examples that pin the moved families; emilia over `styled` (338) | 05emilia-n (step 4), `08-bpp/119` step 1 (steps 5, 3) — order: step 5 first, then 2 (in `styled`'s literal), 3; 4 on 05emilia-n |
| [`33-emilia-color-palette/`](./33-emilia-color-palette/README.md) | medium | step 2 done | steps 1, 3, 4 (the helpers, the suites, the examples) → `20-snap`; step 2 (the fifteen READMEs, `emilia-card` emilia-only) landed | — |

## Order

```
34-emilia-modifiers ─────────────────────────────────┐   (modules/emilia/src/** and four examples' src/main.bp)
33 step 2 (READMEs, emilia-card) ────────────────────┘   (examples/*/README.md, examples/emilia-card/**)
   20-snap step 4 (emilia-test's two helpers) — after 34, which moves the output they record

outbound: nothing — emilia imports nobody (after 34 step 5: the repository `styled`, 338); onze 68 reads `styleRule`
          and the fixture, which 34 keeps byte-identical
inbound:  08-bpp/119 step 1 ──► the repositories `css` and `styled`, before 34 step 5 (first, 350), then 2 and 3
```

- 34 alone edits `emilia.bp` and `tokens.bp`; a snapshot recorded before a family moves is recorded
  twice, so `20-snap`'s emilia step follows it. 33 step 2 shares no file, runs beside.
- `08-bpp/118` step 1's bracket-attribute carve-out gates neither: in emilia it is comments only (no
  code uses `[name]={`) — 34 step 1 rewords those of `attributes.bp` / `emilia.bp`; 33 step 2
  rewrites `emilia-card` (`src/main.bp:5`).

## Decisions

Confirmations kept from 1.0.10 ([`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) § Track D):

| Id | Choice | Closes |
|---|---|---|
| 05emilia-a … 05emilia-k (e → 358) | the filter chain inline; `BackdropFilter`; `drop-shadow-none`; snap strictness fallback; `fullOptions()`; `--inset-shadow-*`; `space-*` / `divide-*` selector; siblings never import `from "emilia"` (05emilia-h → 206: `from "<module of this package>"` is an error, a sibling imports by path); `@property` blocks; selector-list modifiers; `spacingNegHalf` | — |

Snapshot suites and the eight cross-front examples: [`decisions-pending.md`](../decisions-pending.md) `snap-a`, worked by [`20-snap`](../20-snap/README.md) step 4.

### 05emilia-n · The unplaced Tailwind rows — declare them, or leave them to `arbSel` (reduced: only the four features)

> **Raised by:** front 34, from [`34-emilia-modifiers/reference-rows.md`](./34-emilia-modifiers/reference-rows.md)
> (category (c)). Current wording: [`decisions-pending.md`](../decisions-pending.md) `05emilia-n`.
> **Measured.** Four ownerless feature rows: named `:has()` / `:not()` / ARIA / data-attribute /
> `in-[…]` forms (only via `arbSel`); named groups and peers (`group/item`, `peer/name` — six group
> and eight peer states exist, unnamed); `@theme inline` (emilia always emits `var(--x)`); negative
> translate (`Rotate.Neg` exists, `TranslateX/Y.Neg` not, `tokens.bp:2259-2279`). The fifth row —
> a cleared `--breakpoint-*` emitting `@media (width >= )` instead of refusing — is no longer part of
> this question: decision 300 settles it ("a token naming a cleared or absent breakpoint is a
> compile error where the token list is comptime-known"; 34 step 3, unconditional).
> **Options.** (a) None: the four out of scope, stated in `docs.md` § Deviations (`arbSel` is the
> spelling); (b) negative translate and named groups/peers (two token sections, one `Variant` fn
> each — small, upstream-shaped); (c) all four, including `@theme inline` (a second render mode over
> every `var()` site — large).
> **Recommendation.** (a); (b) is the feature answer if any: negative translate is the row a user
> meets first (`-translate-y-2`), named groups the one documented modifier `arbSel` cannot spell
> readably.
> **Blocks.** 34 step 4 (conditional).
