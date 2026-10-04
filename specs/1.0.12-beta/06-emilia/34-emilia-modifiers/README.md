# Front 34 — emilia source tail: std's hash, five families at upstream parity, the breakpoint refusal (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56)

**Priority:** high — step 2 moves output every later snapshot (`20-snap` step 4) would otherwise
record twice · **State:** not started — opens now
**Depends on:** `05emilia-l` confirmed (step 2's rule) · `05emilia-n` (step 4). Nothing else:
`hash.contentHash` exists; `08-bpp/118` step 1's bracket-attribute carve-out is comments only here,
reworded by step 1 (no code uses `[name]={`).
**Owns:** `repository/emilia/modules/emilia/src/**` (all eleven files; edited blocks named per step),
`modules/emilia/AGENTS.md`, `docs.md`,
`examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` · this directory
**Does not touch:** `modules/emilia-test/**`, `examples/*/README.md`, `examples/emilia-card/**`,
`modules/emilia/test/**` (`20-snap`) · the other eleven examples' `src/main.bp` (none pins a moved
family; if one does, report to 33) · `repository/jhonstart/**` (`html_attrs.bp` is 48's, closed) ·
`.gitignore`, the hooks, `.github/` (`00-gate`) · `src/scoped.bp` and its test (`08-bpp/119` adds
them beside, appending its line to `root.bp` / `botopink.json`, which no step here edits)

## Goal

Class name is std's `hash.contentHash` (decision 116), contract-4 fixture `e_39b87d03` unchanged;
`modules/` names no other library (decision 114); five families render what Tailwind 4.3.2 renders;
a cleared `--breakpoint-*` refuses; unplaced rows declared or stated as deviations (05emilia-n).
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

  Each: one dispatcher arm in its block + the `@property` / theme entries the chain reads
  (05emilia-i's shape for `--tw-ease` / `--tw-duration` / `--tw-border-spacing-*`; `fullTheme()`
  gains no entry — per-utility variables with `@property` registrations like the transform ones; no
  new `Ns` prefix — 05emilia-a, -d, -i stand). 05emilia-l: a family moves whole, one helper per
  shape. A token list using a moved family changes class-name hash (hash is over the sheet); the
  contract-4 fixture (padding / colour / hover) uses none and does not move. jhonstart and onze
  assert class names, not bodies.
- **The refusal.** A cleared `--breakpoint-*` (`extendTheme` with an empty value) silently emits
  `@media (width >= )`; `theme.bp`'s breakpoint reader panics on an empty entry naming it, as
  `container.bp`'s does for an emptied `--container-*` (front 58).
- **The unplaced rows:** [`reference-rows.md`](./reference-rows.md), category (c).

## Open

### Step 1 — `hashHex` → `hash.contentHash`; `modules/` names no other library

- [ ] `grep -n hashHex repository/emilia/modules/emilia/src` is empty; `emilia.bp` imports
      `{hash} from "std"` and computes the class as `"e_" + hash.contentHash(payload)`
- [ ] contract-4 fixture `e_39b87d03` byte-identical on both rows; `bridge_test.bp` and onze's
      `build_test.bp:104` unchanged and green
- [ ] `output.bp:379-388`'s comment no longer names `hashHex`: its defect is closed (C-37), so the
      comment goes, or — if the `split("\t")` workaround stays — names C-37 as closed in one line
- [ ] the six comment lines naming another library — `attributes.bp:4,30`,
      `emilia.bp:110,16500,16501,16510` — state the shape without the neighbour ("a consumer's
      element", "a build step that reads `styleRule`", "every reader of the contract-4 literal");
      the `[class]={…}` comments (`attributes.bp:30,32,36`, `emilia.bp:185,202`) describe the
      class-name value without spelling a template surface (replaces `08-bpp/118`'s carve-out in
      emilia); `grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` is empty

### Step 2 — the five families to upstream's form (05emilia-l applied)

- [ ] `transition` / `transition-*` presets render upstream's `var(--tw-ease, …)` /
      `var(--tw-duration, …)` pair, set `--tw-ease` / `--tw-duration` with `@property`
      registrations; `rawTransitionProperty` takes the same pair
- [ ] `backdrop-opacity-50` is `opacity(50%)`; every backdrop utility writes
      `-webkit-backdrop-filter` before `backdrop-filter`
- [ ] `border-spacing-*` writes `--tw-border-spacing-x` / `-y` and the reader
- [ ] `divide-x-*` / `divide-y-*` write `border-*-style:var(--tw-border-style)` beside the width
- [ ] each moved arm's inline tests and the four examples' inline strings assert the new literal,
      measured against 4.3.2's output quoted in the test's comment; `docs.md` and its
      `tailwind-mapping` rows updated
- [ ] no other family's literal moves: `emilia` stays 734 or more, every unrelated test
      byte-identical (test-file diff shows only the five families)

### Step 3 — the theme: typed entries, one `#[theme]`, a cleared breakpoint refused at compile time (decision 300)

The theme stays CSS's flat entry list (`theme.bp`'s reasons hold: nineteen namespaces, three reset
forms); what goes is the string that hid code:

```bp
#[theme]
pub val appTheme = comptime extendTheme(defaultTheme(), [
    entry(.Breakpoint, "md", Rem(40.0)),       // was #("--breakpoint-md", "40rem")
    clear(.Breakpoint, "lg"),                  // was #("--breakpoint-lg", "")
]);
emilia([.Lg([.Pad.All.4])])                    // compile error: breakpoint lg was cleared in the theme
```

- [ ] `entry(ns: Ns, name: string, value: <the namespace's value type>)` (`Rem`, `Color`, `Shadow`, …),
      `clear(ns, name)`, `clearNs(ns)` (`--color-*: initial`), `clearAll()` (`--*: initial`); the name
      inside a namespace stays a string (CSS's, 281); `#("--…", "…")` pairs leave the API
- [ ] `#[theme]`: the app's one theme, found with `@TypeInfo.all(with: theme)`; two refused at compile
      time naming both; none = `defaultTheme()`
- [ ] a token naming a cleared or absent breakpoint (`Lg` after `clear(.Breakpoint, "lg")`) refused at
      compile time when the token list is comptime-known (the literal lists `emilia(...)` takes),
      naming the theme's line; the run-time refusal stays only for a list built at run time
- [ ] `reference-rows.md` § 3.3 "removing breakpoints" reads as a deviation in `docs.md`

### Step 4 — the unplaced rows (on `05emilia-n`)

(b): `TranslateX.Neg` / `TranslateY.Neg` in `tokens.bp` (`:2259-2279`) beside `Rotate.Neg`, with
05emilia-l's `calc(… * -1)` form; named groups and peers as `GroupNamed(name, inner)` /
`PeerNamed(name, inner)` payload variants (top-level, like every payload-carrying token) with
`.group\/<name>` / `.peer\/<name>` selectors. (c): also `@theme inline` as an `Options` field
resolving every `var(--x)` at render. (a), recommended: only `docs.md` § Deviations stating
`arbSel` as the spelling.

- [ ] under (b): `-translate-y-2` renders `--tw-translate-y:calc(var(--spacing) * -2)` and the
      composed `translate`; `group/item:hover` renders `.group\/item:hover .e_…`; both measured
      against 4.3.2
- [ ] under (a): the `docs.md` paragraph; `reference-rows.md` rows marked (b)

**Gate:** standard (fronts.md § Gate) + `emilia` 734 or more on both rows; the fifteen examples
green on both rows; `jhonstart-emilia` and `onze-cli` (the two fixture readers) green ·
`grep -rn "jhonstart\|rakun\|onze" repository/emilia/modules` empty (decision 114; step 1's last box)
