# Front 34 — emilia source tail (carries 40 · 42 · 43 · 44 · 45 · 54 · 56)

**Priority:** high — step 1 is the one std-dedupe consumer in emilia; step 2 moves output that
every later snapshot (33 steps 3–4) would otherwise record twice
**Depends on:** `02-std-and-packaging/97-std-dedupe` (nothing new — `hash.contentHash` exists;
97 records this front as the consumer) · `05emilia-l` confirmed (the rule step 2 applies) ·
`05emilia-n` (step 4, conditional) · `00-gate` for the `.snap.new` guard (33 records snapshots
after this front; this front records none)
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; the blocks it edits are
named per step), `modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (33) · the other eleven examples' `src/main.bp` (none pins a moved
family — measured; if one does, the front reports it to 33 rather than editing) ·
`repository/jhonstart/**` (`html_attrs.bp` is 48's, closed) · `.gitignore`, the hooks (`00-gate`)
**Carried from 1.0.10:** `56-emilia-cascade-and-output/README.md` § Open (the `hashHex` box) ·
`decisions-pending.md` 05emilia-l § Blocks and `status.md`'s "families no open row named" row (the
five families) · `reference-coverage.md` § Missing and partial rows, category (c) (copied to
[`reference-rows.md`](./reference-rows.md)) · `unification.md` § Open boxes rows 2 and 5

---

## Problem

1. `grep -n hashHex repository/emilia/modules/emilia/src/emilia.bp` finds the declaration
   (`:97`) and its use (`:114`): a Node and an Erlang template of the djb2 fold that std's
   `hash.contentHash` implements. Decision 116 says the class name is std's function; front 56's
   box says the switch is one import line and the fixture `e_39b87d03` must not move.
2. Measured against Tailwind 4.3.2's compiled output while confirming 05emilia-l, five families
   render a different string:

| Family | emilia writes | upstream writes | Block |
|---|---|---|---|
| transition presets | `transition-timing-function:var(--ease-out);transition-duration:150ms` (`emilia.bp:13056`, `:13263-13264`) | `…:var(--tw-ease, var(--default-transition-timing-function));…:var(--tw-duration, var(--default-transition-duration))` and sets `--tw-ease` / `--tw-duration` | 44 |
| `backdrop-opacity-*` | `opacity(0.5)` | `opacity(50%)` | 42 |
| backdrop filters | `backdrop-filter:…` | `-webkit-backdrop-filter:…;backdrop-filter:…` | 42 |
| `border-spacing-*` | `border-spacing:calc(…) 0` (`:12811-12897`) | `--tw-border-spacing-x:…;--tw-border-spacing-y:…;border-spacing:var(--tw-border-spacing-x) var(--tw-border-spacing-y)` | 43 |
| `divide-*` | the width | `border-*-style:var(--tw-border-style);` beside the width | 40 |

3. A cleared `--breakpoint-*` (`extendTheme` with an empty value) makes the breakpoint variant
   emit `@media (width >= )` — an invalid query, silently; front 58 refuses the same for an
   emptied `--container-*` (`reference-rows.md` § 3.3).
4. Four Tailwind rows have no token (`reference-rows.md`, category (c)): named `:has()` /
   `:not()` / ARIA / data / `in-[…]` forms, named groups and peers, `@theme inline`, negative
   translate.

## Current state

`emilia` 734 / 734 on both rows; the five families are pinned by inline tests in their blocks and
by `examples/emilia-transitions`, `emilia-effects`, `emilia-outline-ring` and `emilia-transforms`
(`grep -l`), all green on the current strings. `output.bp:379-388` explains why `hashHex`'s
neighbour must not use `String.slice` (a commonJS prelude defect — a row for the compiler, `00-gate`'s
hand-off in `../README.md`).

## Mechanism

- The hash: `hash.contentHash` is the same fold (decision 116 chose it *because* it is emilia's);
  `import {hash} from "std"` in `emilia.bp`, `hash.contentHash(payload)` at `:114`, the two
  templates deleted. The fixture proves the equivalence.
- The families: each is one dispatcher arm in its block plus the `@property` / theme entries the
  chain reads (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`;
  `fullTheme()` gains no entry — the variables are per-utility, with `@property` registrations as
  the transform variables have). 05emilia-l's rule: a family moves whole, one helper per shape.
- The refusal: `theme.bp`'s breakpoint reader panics on an empty entry naming it, as
  `container.bp`'s does.

## Steps

### Step 1 — `hashHex` → `hash.contentHash` (front 56's box; the std-dedupe consumer)

**Acceptance:**
- [ ] `grep -n hashHex repository/emilia/modules/emilia/src` is empty; `emilia.bp` imports
      `{hash} from "std"` and computes the class as `"e_" + hash.contentHash(payload)`
- [ ] the contract-4 fixture `e_39b87d03` is byte-identical on both rows; `bridge_test.bp` and
      onze's `build_test.bp:104` unchanged and green
- [ ] `output.bp:379-388`'s comment names the compiler row instead of `hashHex` (the workaround
      stays until the row closes)

### Step 2 — the five families to upstream's form (05emilia-l applied)

**Acceptance:**
- [ ] `transition` / `transition-*` presets render upstream's `var(--tw-ease, …)` /
      `var(--tw-duration, …)` pair and set `--tw-ease` / `--tw-duration` with their `@property`
      registrations; `rawTransitionProperty` takes the same pair
- [ ] `backdrop-opacity-50` is `opacity(50%)`; every backdrop utility writes
      `-webkit-backdrop-filter` before `backdrop-filter`
- [ ] `border-spacing-*` writes `--tw-border-spacing-x` / `-y` and the reader
- [ ] `divide-x-*` / `divide-y-*` write `border-*-style:var(--tw-border-style)` beside the width
- [ ] each moved arm's inline tests and the four examples' inline strings assert the new
      literal, measured against 4.3.2's compiled output quoted in the test's comment; `docs.md`
      and `tailwind-mapping`'s rows in `docs.md` updated
- [ ] no other family's literal moves: `emilia` stays 734 or more with every unrelated test
      byte-identical (the diff of the test file shows only the five families)

### Step 3 — a cleared breakpoint refuses

**Acceptance:**
- [ ] `extendTheme(th, [#("--breakpoint-md", "")])` followed by `Md([…])` panics naming
      `--breakpoint-md`, asserted by its message like front 54's unknown-prefix refusal;
      `container.bp`'s message shape is the model
- [ ] `reference-rows.md` § 3.3 "removing breakpoints" reads as a deviation in `docs.md`

### Step 4 — conditional on `05emilia-n`: the unplaced rows

Under (b): `TranslateX.Neg` / `TranslateY.Neg` in `tokens.bp` beside `Rotate.Neg`, with the
`calc(… * -1)` form of 05emilia-l; named groups and peers as `GroupNamed(name, inner)` /
`PeerNamed(name, inner)` payload variants (top-level, as every payload-carrying token is) with
`.group\/<name>` / `.peer\/<name>` selectors. Under (c): also `@theme inline` as an `Options`
field resolving every `var(--x)` at render. Under (a) — the recommendation for this front —
nothing; `docs.md` § Deviations states `arbSel` as the spelling.

**Acceptance:**
- [ ] under (b): `-translate-y-2` renders `--tw-translate-y:calc(var(--spacing) * -2)` and the
      composed `translate`; `group/item:hover` renders `.group\/item:hover .e_…`; both measured
      against 4.3.2
- [ ] under (a): the `docs.md` paragraph; `reference-rows.md` rows marked (b)

## Gate

- [ ] `zig build test-libs` — `emilia` 734 or more on both rows; the fifteen examples green on
      both rows; `jhonstart-emilia` and `onze-cli` (the two fixture readers) green
- [ ] `grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` empty (decision 114)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/34-emilia-modifiers`; no push, no merge — landing is the maintainer's step

## Blast radius

Step 2 changes the rendered CSS of five families: every consumer that pinned one (the four
examples here; nothing outside emilia — jhonstart and onze assert class names, not bodies)
re-asserts. The class-name hash of a token list using a moved family changes (the hash is over
the sheet), which is why 33's snapshots record after this front. The contract-4 fixture's token
list uses none of the five families (measured: `e_39b87d03` is a padding/colour/hover list) and
does not move.

## Notes

- The directory is named after the lowest front number it carries (the convention of this
  milestone); the front is the whole source tail of emilia because every family shares
  `emilia.bp` and `tokens.bp`.
- No new `Ns` prefix for `--tw-*`: the variables are per-utility with `@property` registrations
  (05emilia-a, -d, -i stand).
