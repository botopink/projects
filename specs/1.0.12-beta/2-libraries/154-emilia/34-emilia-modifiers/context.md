# Front 34 — emilia source tail: std's hash, five families at upstream parity, the breakpoint refusal (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [154-emilia](../README.md): open → 154 s1 · s5 → 154 s1 · s2 → 154 s2 · s3 → 154 s3. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — emilia on `styled` first (decision 350): step 5 before step 2, so the five
families move once, in `styled`'s literal; step 2 moves output every later snapshot (`20-snap`
step 4) would otherwise record twice · **State:** step 1 done; next step 5, after `08-bpp/119`
step 1's two open boxes; then step 2 (decision 350) and step 3 (358); step 4 on 401 (no wait) · step 5's two text boxes and its class box
(367) done; boxes 1–3 and 6 wait on 381's literal in `styled` (34-d: `styledProperty` answers the record),
box 4 on `08-bpp/119` step 4 (383's `StyledMeta` and its reader), `01-compiler/130` step 8 and the toolchain row "A nested-section enum value at comptime",
box 5 on that row and "emilia's dispatcher at comptime", box 8 on box 1
**Depends on:** `08-bpp/119` step 1 (step 5, and through it step 2 — its box 4 registers through
`use context(StyledSheet)`, 352, 354, 379, so `flush()` — which provides `StyledContext` — waits on
`01-compiler/134` step 6; step 3: the repositories `css`
and `styled` — the components and the theme mechanism, decision 338) · nothing for step 4 (401).
Nothing else:
`hash.contentHash` exists; `08-bpp/118` step 1's bracket-attribute carve-out is comments only here,
reworded by step 1 (no code uses `[name]={`).
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; edited blocks named per step),
`modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory · step 5
only, the carve-out of 369 and 367 (emilia's run-time calls moved to `comptime` / `#[emilia]`, and the re-recorded class):
`repository/jhonstart/modules/jhonstart-emilia/{src/root.bp,test/bridge_test.bp}`, onze 68's
`styleRule` reader and bundle test, `onze-cli`, `examples/emilia-card/**` and the other eleven
examples' `src/main.bp`
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (`20-snap`) · the other eleven examples' `src/main.bp` (none pins a moved
family; if one does, report to 33) · `repository/jhonstart/**` (`html_attrs.bp` is 48's, closed) ·
`.gitignore`, the hooks, `.github/` (`00-gate`) · `repository/css/**`, `repository/styled/**`
(`08-bpp/119` step 1)

## Goal

Class name is std's `hash.contentHash` (decision 116) over the class's rules, the `e_` prefix (367):
the contract-4 fixture re-derived once in step 5, `e_f51c2501`;
`modules/` names no other library (decision 114); five families render what Tailwind 4.3.2 renders;
the theme is typed and declared once with `#[theme]` — the mechanism `styled`'s, the Tailwind values
emilia's `defaultTheme()` —, a token naming a cleared breakpoint a compile error (decisions 300, 338);
negative translate and named groups / peers added, the other two feature rows stated as deviations (401); emilia runs at compile
time — a tag decorator `#[emilia(…)]` over typed tokens, its families compile-time functions written
with `styled`'s literal, its own sheet model gone (338, 369).
`emilia`: 734 tests on both rows; the five families pinned by inline tests in their blocks and by
the four owned examples.

## Mechanism

- **The hash.** `hashHex` (`emilia.bp:95-97`: Node and Erlang templates of the djb2 fold, used in
  `styleRule` at `:114`) is what `hash.contentHash` implements (decision 116 chose it *because* it
  is emilia's). `import {hash} from "std"` in `emilia.bp`, `hash.contentHash(payload)` in
  `styleRule`, both templates deleted; the fixture proves equivalence. `output.bp:379-388`'s comment
  ("NEITHER OF THESE MAY USE `String.slice`") explains a commonJS prelude defect (C-37: a
  self-recursive `charCodeAt` patch) closed in the compiler (`01-compiler/04-js`,
  `run/string_char_code_after_slice` on four targets).
- **The families**, against Tailwind 4.3.2's compiled output:

| Family | emilia writes | upstream writes | Block |
|---|---|---|---|
| transition presets | `transition-timing-function:var(--ease-out);transition-duration:150ms` (`transitionPreset`, `emilia.bp:13053`; tests from `:13263`) | `…:var(--tw-ease, var(--default-transition-timing-function));…:var(--tw-duration, var(--default-transition-duration))` and sets `--tw-ease` / `--tw-duration` | 44 |
| `backdrop-opacity-*` | `opacity(0.5)` | `opacity(50%)` | 42 |
| backdrop filters | `backdrop-filter:…` | `-webkit-backdrop-filter:…;backdrop-filter:…` | 42 |
| `border-spacing-*` | `border-spacing:calc(…) 0` (`emilia.bp:313`, `:12805-12897`) | `--tw-border-spacing-x:…;--tw-border-spacing-y:…;border-spacing:var(--tw-border-spacing-x) var(--tw-border-spacing-y)` | 43 |
| `divide-*` | the width | `border-*-style:var(--tw-border-style);` beside the width | 40 |

  Each (step 2, over step 5's components): its family's `styledProperty` literal + the `@property` / theme entries the chain reads
  (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`; `fullTheme()`
  gains no entry — per-utility variables with `@property` registrations like the transform ones; no
  new `Ns` prefix — 05emilia-a, -d, -i stand). Decision 350: a family moves whole, one helper per
  shape. A token list using a moved family changes class-name hash (hash is over the rules, 367); the
  contract-4 fixture (padding / colour / hover) uses none and does not move in step 2. jhonstart and onze
  assert class names, not bodies.
- **The refusal.** Today a cleared `--breakpoint-*` (`extendTheme` with an empty value) silently
  emits `@media (width >= )`. Decision 300: a token naming a cleared or absent breakpoint is a compile
  error where the token list is comptime-known (a `#[styled(…)]` tag annotation's tokens always are,
  280/301); `theme.bp`'s breakpoint reader panics on an empty entry naming it, as `container.bp`'s
  does for an emptied `--container-*` (front 58), only for a list built at run time (step 3).
- **The unplaced rows:** [`reference-rows.md`](reference-rows.md), category (c).
