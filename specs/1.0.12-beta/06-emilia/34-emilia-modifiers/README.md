# Front 34 — emilia source tail: std's hash, five families at upstream parity, the breakpoint refusal (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56)

**Priority:** high — step 2 moves output that every later snapshot (`20-snap` step 4) would
otherwise record twice · **State:** not started — opens now
**Depends on:** `05emilia-l` confirmed (the rule step 2 applies) · `05emilia-n` (step 4).
Nothing else: `hash.contentHash` exists in std; `08-bpp/118` step 1's bracket-attribute
carve-out is comments only in this member's files and step 1 rewords them here (no code uses
`[name]={`).
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; the blocks it edits are
named per step), `modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (`20-snap`) · the other eleven examples' `src/main.bp` (none pins a moved
family; if one does, the front reports it to 33 rather than editing) · `repository/jhonstart/**`
(`html_attrs.bp` is 48's, closed) · `.gitignore`, the hooks, `.github/` (`00-gate`) ·
`src/scoped.bp` and its test (`08-bpp/119` adds them beside this front and appends its line to
`root.bp` / `botopink.json`, which no step here edits)

## Goal

The class name is std's `hash.contentHash` (decision 116) with the contract-4 fixture `e_39b87d03`
unchanged; `modules/` names no other library (decision 114); five families render what Tailwind
4.3.2 renders; a cleared `--breakpoint-*` refuses; the unplaced rows are declared or stated as
deviations (05emilia-n). `emilia` has 734 tests on both rows; the five families are pinned by
inline tests in their blocks and by the four examples this front owns.

## Mechanism

- **The hash.** `hashHex` (`emilia.bp:95-97`: a Node and an Erlang template of the djb2 fold,
  used in `styleRule` at `:114`) is what `hash.contentHash` implements — decision 116 chose it
  *because* it is emilia's. `import {hash} from "std"` in `emilia.bp`, `hash.contentHash(payload)`
  in `styleRule`, the two templates deleted; the fixture proves the equivalence. The
  `output.bp:379-388` comment ("NEITHER OF THESE MAY USE `String.slice`") explains a commonJS
  prelude defect (C-37: a self-recursive `charCodeAt` patch) that is closed in the compiler
  (`01-compiler/04-js`, `run/string_char_code_after_slice` on four targets).
- **The families.** Measured against Tailwind 4.3.2's compiled output:

| Family | emilia writes | upstream writes | Block |
|---|---|---|---|
| transition presets | `transition-timing-function:var(--ease-out);transition-duration:150ms` (`transitionPreset`, `emilia.bp:13053`; tests from `:13263`) | `…:var(--tw-ease, var(--default-transition-timing-function));…:var(--tw-duration, var(--default-transition-duration))` and sets `--tw-ease` / `--tw-duration` | 44 |
| `backdrop-opacity-*` | `opacity(0.5)` | `opacity(50%)` | 42 |
| backdrop filters | `backdrop-filter:…` | `-webkit-backdrop-filter:…;backdrop-filter:…` | 42 |
| `border-spacing-*` | `border-spacing:calc(…) 0` (`emilia.bp:313`, `:12805-12897`) | `--tw-border-spacing-x:…;--tw-border-spacing-y:…;border-spacing:var(--tw-border-spacing-x) var(--tw-border-spacing-y)` | 43 |
| `divide-*` | the width | `border-*-style:var(--tw-border-style);` beside the width | 40 |

  Each is one dispatcher arm in its block plus the `@property` / theme entries the chain reads
  (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`; `fullTheme()`
  gains no entry — the variables are per-utility, with `@property` registrations as the transform
  variables have; no new `Ns` prefix — 05emilia-a, -d, -i stand). 05emilia-l's rule: a family
  moves whole, one helper per shape. The class-name hash of a token list using a moved family
  changes (the hash is over the sheet); the contract-4 fixture's list (padding / colour / hover)
  uses none of the five and does not move. jhonstart and onze assert class names, not bodies.
- **The refusal.** A cleared `--breakpoint-*` (`extendTheme` with an empty value) makes the
  breakpoint variant emit `@media (width >= )`, silently; `theme.bp`'s breakpoint reader panics on
  an empty entry naming it, as `container.bp`'s does for an emptied `--container-*` (front 58).
- **The unplaced rows** ([`reference-rows.md`](./reference-rows.md), category (c)): named
  `:has()` / `:not()` / ARIA / data / `in-[…]` forms, named groups and peers, `@theme inline`,
  negative translate.

## Open

### Step 1 — `hashHex` → `hash.contentHash`; `modules/` names no other library

- [ ] `grep -n hashHex repository/emilia/modules/emilia/src` is empty; `emilia.bp` imports
      `{hash} from "std"` and computes the class as `"e_" + hash.contentHash(payload)`
- [ ] the contract-4 fixture `e_39b87d03` is byte-identical on both rows; `bridge_test.bp` and
      onze's `build_test.bp:104` unchanged and green
- [ ] `output.bp:379-388`'s comment no longer names `hashHex`: the defect it explains is closed
      in the compiler (C-37), so the comment goes, or — if the `split("\t")` workaround stays —
      it names C-37 as closed in one line
- [ ] the six comment lines that name another library — `attributes.bp:4,30`,
      `emilia.bp:110,16500,16501,16510` — state the shape without the neighbour ("a consumer's
      element", "a build step that reads `styleRule`", "every reader of the contract-4
      literal"); and the `[class]={…}` comments (`attributes.bp:30,32,36`, `emilia.bp:185,202`)
      describe the class-name value without spelling a template surface — this replaces
      `08-bpp/118`'s carve-out in emilia; `grep -rn "jhonstart\|rakun\|onze"
      repository/emilia/modules` is empty

### Step 2 — the five families to upstream's form (05emilia-l applied)

- [ ] `transition` / `transition-*` presets render upstream's `var(--tw-ease, …)` /
      `var(--tw-duration, …)` pair and set `--tw-ease` / `--tw-duration` with their `@property`
      registrations; `rawTransitionProperty` takes the same pair
- [ ] `backdrop-opacity-50` is `opacity(50%)`; every backdrop utility writes
      `-webkit-backdrop-filter` before `backdrop-filter`
- [ ] `border-spacing-*` writes `--tw-border-spacing-x` / `-y` and the reader
- [ ] `divide-x-*` / `divide-y-*` write `border-*-style:var(--tw-border-style)` beside the width
- [ ] each moved arm's inline tests and the four examples' inline strings assert the new
      literal, measured against 4.3.2's compiled output quoted in the test's comment; `docs.md`
      and its `tailwind-mapping` rows updated
- [ ] no other family's literal moves: `emilia` stays 734 or more with every unrelated test
      byte-identical (the diff of the test file shows only the five families)

### Step 3 — a cleared breakpoint refuses

- [ ] `extendTheme(th, [#("--breakpoint-md", "")])` followed by `Md([…])` panics naming
      `--breakpoint-md`, asserted by its message like front 54's unknown-prefix refusal;
      `container.bp`'s message shape is the model
- [ ] `reference-rows.md` § 3.3 "removing breakpoints" reads as a deviation in `docs.md`

### Step 4 — the unplaced rows (on `05emilia-n`)

Under (b): `TranslateX.Neg` / `TranslateY.Neg` in `tokens.bp` (`:2259-2279`) beside `Rotate.Neg`,
with the `calc(… * -1)` form of 05emilia-l; named groups and peers as `GroupNamed(name, inner)` /
`PeerNamed(name, inner)` payload variants (top-level, as every payload-carrying token is) with
`.group\/<name>` / `.peer\/<name>` selectors. Under (c): also `@theme inline` as an `Options`
field resolving every `var(--x)` at render. Under (a) — the recommendation — nothing but
`docs.md` § Deviations stating `arbSel` as the spelling.

- [ ] under (b): `-translate-y-2` renders `--tw-translate-y:calc(var(--spacing) * -2)` and the
      composed `translate`; `group/item:hover` renders `.group\/item:hover .e_…`; both measured
      against 4.3.2
- [ ] under (a): the `docs.md` paragraph; `reference-rows.md` rows marked (b)

**Gate:** standard (fronts.md § Gate) + `emilia` 734 or more on both rows; the fifteen examples
green on both rows; `jhonstart-emilia` and `onze-cli` (the two fixture readers) green ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` empty (decision 114; step 1's last
box)
