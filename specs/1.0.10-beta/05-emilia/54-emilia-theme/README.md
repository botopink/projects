# Front 54 — emilia theme

**Track:** D emilia
**Priority:** critical — without it every one of fronts 33–47 hard-codes its own value ladder, which is what `emilia.bp` does today and which has already drifted: `marginScaleX` emits `m-0.25`, a string that is not CSS.
**Target:** comptime
**Wave:** 0 — and first inside wave 0. Fronts 33, 34 and 35 are wave 2 and all three consume `spacing(n)` and `Theme`, so 54 lands before them.
**Depends on:** none
**Owns:** `repository/emilia/src/theme.bp`, `repository/emilia/src/spacing.bp`, `repository/emilia/test/theme_test.bp`, `repository/emilia/test/spacing_test.bp`; the `pub mod theme;` / `pub mod spacing;` lines in `src/root.bp` and the two matching entries in `botopink.json`
**Does not touch:** `src/tokens.bp` (it adds no `Token` variant), `src/emilia.bp` (it adds no `tokenToCss` arm), and every other front's dispatcher
**Reference:** `TAILWIND_CSS_DOCS.md § 3.5 Variáveis de Tema`, `§ 3.9 Funções e Diretivas`, `§ 20.2 @theme`, `§ 20.8 Função --spacing()`, `§ 20.9 Função theme()`, `§ 21.1–§ 21.7` · https://tailwindcss.com/docs/theme
**Replaces:** new — the 1.0.8-beta draft had no theme front; this one comes out of the Tailwind coverage audit

---

## Problem

`emilia` has no theme. It has fifteen literal ladders scattered through one file, and they disagree
with each other. `padScaleX`, `padScaleAll`, `padScaleY`, `marginScaleY`, `marginScaleAll` and
`flexGapScale` (`repository/emilia/src/emilia.bp:190-220`, `:242-260`, `:308-316`) each hold their
own copy of `1 → 0.25rem, 2 → 0.5rem, 4 → 1rem, 8 → 2rem`. `marginScaleX` (`:231-240`) holds a
seventh copy that emits `m-0.25`, `m-0.5`, `m-1`, `m-2` — those are Tailwind *class names*, not CSS
values, and `margin-x:` on the line above (`:225`) is not a CSS property either. Nothing catches it,
because nothing in `emilia` knows what the spacing scale is; each `fn` is the scale.

Sixteen more fronts are about to be written against this file. If each one lands its own ladder,
`emilia` ends the milestone with twenty-two hard-coded dialects and no way to change a value, and
`@theme`, `theme()` and `--spacing()` — three things the milestone brief names directly — stay
unanswerable.

The second half of the problem is that a consumer cannot change anything. Tailwind's whole
customization story is a set of CSS custom properties a project extends, overrides, narrows or
replaces wholesale (`§ 3.5`). `emilia` has no such surface: the only way to reach a value outside
the enum today is `Color.Hex("#abc")`, one declaration at a time, at one call site.

## Current state

- `repository/emilia/src/` holds exactly three modules: `root.bp`, `tokens.bp`, `emilia.bp`
  (`botopink.json` `"files"`). There is no `theme.bp` and no `test/` directory.
- Spacing values appear as literal `rem` strings inside seven `case` dispatchers
  (`emilia.bp:190`, `:201`, `:211`, `:231`, `:242`, `:252`, `:308`).
- Font sizes are literal (`emilia.bp:121-133`), shadows are placeholders that are not CSS
  (`emilia.bp:364-372`: `box-shadow:sm`), radii are literal (`emilia.bp:346-354`), the red palette
  is literal and unreachable — `redPaletteHex` (`emilia.bp:385-398`) is never called, because
  `colorTokenToCss` throws the shade away (`emilia.bp:158-161`: `Red(_inner) -> "color:red"`).
- Breakpoints are literal inside the modifier arms (`emilia.bp:88-90`), and they are wrong: `768px`
  where `§ 3.3` says `48rem`, expressed as `min-width` where the doc's table says `width >=`.
- There is no custom-property output at all: `flushSheet` (`emilia.bp:28-29`) emits
  `<style>.cls{body}</style>` and nothing else, so no `var(--…)` reference emilia emits could
  resolve today.

## Mechanism

**Upstream.** A Tailwind theme is a flat set of CSS custom properties declared in `@theme { … }`
(`§ 20.2`). The prefix of a property name selects its *namespace* (`§ 3.5`): `--color-*`, `--font-*`,
`--text-*`, `--font-weight-*`, `--tracking-*`, `--leading-*`, `--breakpoint-*`, `--container-*`,
`--spacing-*`, `--radius-*`, `--shadow-*`, `--inset-shadow-*`, `--drop-shadow-*`, `--blur-*`,
`--perspective-*`, `--aspect-*`, `--ease-*`, `--animate-*` — eighteen, plus the `@keyframes` bodies
`§ 3.5` allows inside an `@theme` block, which makes nineteen things a theme carries. Adding a name
extends the theme; reusing one overrides it; `--color-*: initial` clears a namespace; `--*: initial`
clears everything (`§ 3.5`, `§ 21.7`). Utilities do not inline theme values — they emit references:
`p-4` is `padding: calc(var(--spacing) * 4)` (`§ 7.1`), not `padding: 1rem`.

**In botopink.** The theme is a record holding that flat set, and the namespaces are validated
prefixes rather than nineteen record fields:

```bp
pub type ThemeEntry(name: string, value: string)

pub type Theme(
    entries: ThemeEntry[],
    keyframes: ThemeEntry[],
    darkMode: DarkMode,
)
```

This is one deliberate deviation from the audit's brief, which asked for "one field group per
namespace". A nineteen-field record cannot express `--color-*: initial` or `--*: initial` without
nineteen more functions, and every extension point would have to name its field. The flat set is
what CSS actually has, so it delivers all nineteen namespaces *and* the three reset forms with five
functions. Namespaces stay typed through an `Ns` enum that maps to its prefix, so no caller writes a
prefix string by hand, and `extend` refuses an entry whose name is outside the known prefixes —
refuse, do not accept-and-ignore, and no flag to turn the check off.

**Why `spacing(n)` returns a `calc()` and not a `rem` literal.** `§ 7.1` and `§ 21.2` are explicit:
every spacing utility is a multiplier of `var(--spacing)`, resolved by the browser. Emitting
`padding: 1rem` would be byte-different from Tailwind for every spacing utility in the library, and
it would make a consumer's `--spacing: 4px` override silently ineffective. So `spacing(4)` is
`calc(var(--spacing) * 4)`, the theme's `--spacing` is emitted as a custom property, and *emilia
never resolves a spacing value*. That removes the entire class of drift the current file has.

**Why the theme block is always emitted.** Tailwind's default emits only the variables the build
actually used, and `@theme static` (`§ 3.5`, `§ 20.2`) emits all of them. Tree-shaking needs a
whole-program pass over every `emilia()` call site, which `emilia` cannot do — it hashes per call
site. So emilia's behaviour is `@theme static`, always, and the tree-shaken form is out of scope for
this milestone. Saying it here means nobody files it later as a bug.

**Dark mode.** `§ 3.4` gives three strategies: `prefers-color-scheme`, a class, or a data attribute.
The *strategy* is a theme property because it is chosen once per project; the `Dark` variant that
consumes it belongs to front 34. 54 ships `DarkMode` and the function that turns it into the variant
front 34 wraps with.

## Steps

### Step 1 — the theme record and its namespaces

`Theme` holds a flat entry list, a separate keyframes list (their values are rule bodies, not
property values), and the dark-mode strategy. `Ns` names the nineteen namespaces; `nsPrefix` is the
only place a prefix string is written.

```bp
pub type ThemeEntry(name: string, value: string)

pub type DarkMode {
    Media,
    Class(name: string),
    Attribute(name: string, value: string),
}

pub type Theme(
    entries: ThemeEntry[],
    keyframes: ThemeEntry[],
    darkMode: DarkMode,
)

pub type Ns {
    Color, Font, Text, FontWeight, Tracking, Leading, Breakpoint, Container,
    Spacing, Radius, Shadow, InsetShadow, DropShadow, Blur, Perspective,
    Aspect, Ease, Animate, Keyframes,
}

pub fn nsPrefix(ns: Ns) -> string {
    val out = case ns {
        Color -> "--color-";
        Font -> "--font-";
        Text -> "--text-";
        FontWeight -> "--font-weight-";
        Tracking -> "--tracking-";
        Leading -> "--leading-";
        Breakpoint -> "--breakpoint-";
        Container -> "--container-";
        Spacing -> "--spacing";
        Radius -> "--radius-";
        Shadow -> "--shadow-";
        InsetShadow -> "--inset-shadow-";
        DropShadow -> "--drop-shadow-";
        Blur -> "--blur-";
        Perspective -> "--perspective-";
        Aspect -> "--aspect-";
        Ease -> "--ease-";
        Animate -> "--animate-";
        Keyframes -> "@keyframes ";
    };
    return out;
}
```

`--spacing` has no trailing dash because `§ 21.2` makes it a single variable, not a family.

**Acceptance:**
- [ ] `nsPrefix` has exactly nineteen arms and every one is exercised by a test.
- [ ] Every prefix matches the `§ 3.5` namespace table character for character, and `--spacing`
      carries no trailing `-`.
- [ ] `Theme` is constructed only by named arguments; no positional construction appears anywhere.

### Step 2 — `defaultTheme()`

The defaults the doc pins: `--spacing` from `§ 21.2`, `--text-*` and their line heights from
`§ 21.3`, `--shadow-*` from `§ 21.4`, `--radius-*` from `§ 21.5`, `--animate-*` plus the four
keyframe bodies from `§ 21.6`, `--breakpoint-*` from `§ 3.3`, `--container-*` from `§ 3.3`.

```bp
pub fn defaultTheme() -> Theme {
    val base: ThemeEntry[] = [
        ThemeEntry(name: "--spacing", value: "0.25rem"),
        ThemeEntry(name: "--breakpoint-sm", value: "40rem"),
        ThemeEntry(name: "--breakpoint-md", value: "48rem"),
        ThemeEntry(name: "--breakpoint-lg", value: "64rem"),
        ThemeEntry(name: "--breakpoint-xl", value: "80rem"),
        ThemeEntry(name: "--breakpoint-2xl", value: "96rem"),
        ThemeEntry(name: "--radius-xs", value: "0.125rem"),
        ThemeEntry(name: "--radius-sm", value: "0.25rem"),
        ThemeEntry(name: "--radius-md", value: "0.375rem"),
        ThemeEntry(name: "--radius-lg", value: "0.5rem"),
        ThemeEntry(name: "--radius-xl", value: "0.75rem"),
        ThemeEntry(name: "--radius-2xl", value: "1rem"),
        ThemeEntry(name: "--radius-3xl", value: "1.5rem"),
        ThemeEntry(name: "--radius-4xl", value: "2rem"),
        ThemeEntry(name: "--color-black", value: "#000"),
        ThemeEntry(name: "--color-white", value: "#fff"),
    ];
    val more = base.append(textEntries()).append(shadowEntries()).append(containerEntries()).append(animateEntries());
    return Theme(entries: more, keyframes: keyframeEntries(), darkMode: DarkMode.Media);
}
```

`--color-*` carries only `black` and `white` here. The 26 families × 11 shades of `§ 21.1` are
front 33's data, and front 33 hands them over as `paletteEntries() -> ThemeEntry[]`; the composed
theme is `extend(defaultTheme(), paletteEntries())`. 54 does not import front 33, and front 33 does
not edit `theme.bp` — that is the whole interface between them.

**Acceptance:**
- [ ] Every `--text-*` entry has a matching `--text-*--line-height` entry, both taken from the
      `§ 21.3` table (thirteen sizes, twenty-six entries).
- [ ] The seven `--shadow-*` values are byte-equal to the `§ 21.4` table, including the
      two-shadow values for `sm`, `md`, `lg` and `xl`.
- [ ] The four `--animate-*` values are byte-equal to `§ 21.6`, and `keyframes` carries exactly
      four entries: `spin`, `ping`, `pulse`, `bounce`.
- [ ] The thirteen `--container-*` entries match the `§ 3.3` container-size table.
- [ ] `defaultTheme()` contains no `--color-` entry other than `--color-black` and `--color-white`.

### Step 3 — extend, override, clear, empty

Four operations, matching `§ 3.5`'s four headings. `extend` is also the override path: a later entry
with the same name wins, which is what re-declaring a variable in `@theme` does.

```bp
pub fn extend(th: Theme, entries: ThemeEntry[]) -> Theme
pub fn clearNamespace(th: Theme, ns: Ns) -> Theme
pub fn emptyTheme() -> Theme
pub fn themeValue(th: Theme, name: string) -> string
pub fn themeVar(name: string) -> string
```

`themeValue` is the `theme()` function of `§ 20.9`: it resolves a name to its literal value, and
returns `""` when the name is not in the theme. `themeVar` is the reference form, `"var(" + name + ")"`,
which is what every utility emits. A front that wants a value at authoring time calls `themeValue`;
a front that wants byte-parity with Tailwind emits `themeVar`.

`extend` refuses an entry whose name matches no `Ns` prefix. There is no permissive mode and no
argument that relaxes it: an unknown prefix is a typo or a namespace this library does not have, and
both are errors.

**Acceptance:**
- [ ] `themeValue(extend(th, [ThemeEntry(name: "--color-brand", value: "oklch(0.72 0.11 178)")]), "--color-brand")` returns the value.
- [ ] Extending with a name already present returns a theme where `themeValue` gives the new value,
      and where `namespace(th, Ns.Color)` has the same length as before.
- [ ] `clearNamespace(th, Ns.Color)` leaves `namespace(th, Ns.Color)` empty and leaves every other
      namespace unchanged in length.
- [ ] `emptyTheme()` has zero entries and zero keyframes, and `themeValue` on it returns `""` for
      every name in `defaultTheme()`.
- [ ] `extend(th, [ThemeEntry(name: "--gutter", value: "1rem")])` fails the build with a message
      naming the unknown prefix. A test asserts the *absence* of the entry, and the wrong-placement
      case is recorded in the compiler's own suite per the project convention.

### Step 4 — `spacing(n)`

The botopink answer to `--spacing()` (`§ 20.8`) and to the whole `§ 7`/`§ 8` ladder.

```bp
pub fn spacing(n: i32) -> string {
    val step = n.toString();
    val out = if (n == 0) { "0"; } else { "calc(var(--spacing) * " + step + ")"; };
    return out;
}

pub fn spacingHalf(n: i32) -> string {
    val step = n.toString();
    return "calc(var(--spacing) * " + step + ".5)";
}
```

`spacing` takes an `i32` rather than an `f64` because the ladder's fractional steps are a closed set
(`0.5`, `1.5`, `2.5`, `3.5`) that a second function covers exactly, while an `f64` parameter would
make the emitted string depend on the backend's float formatting, which this milestone does not pin
down. Negative steps work without a second function: `spacing(-4)` is
`calc(var(--spacing) * -4)`, which is the `-mt-4` row of `§ 7.2`.

**Acceptance:**
- [ ] `spacing(0) == "0"` — `§ 7.1` gives `p-0` as `padding: 0`, not a `calc`.
- [ ] `spacing(4) == "calc(var(--spacing) * 4)"`, byte-equal to the `p-4` row of `§ 7.1`.
- [ ] `spacing(-4) == "calc(var(--spacing) * -4)"`, byte-equal to the `-mt-4` row of `§ 7.2`.
- [ ] `spacingHalf(0) == "calc(var(--spacing) * 0.5)"`.
- [ ] The test file asserts identical strings on `--target commonJS` and `--target erlang`.

### Step 5 — the static custom-property emitter

`themeCss(th)` renders the theme as the body of a `:root` rule; `keyframeBlocks(th)` renders the
`@keyframes` bodies, which cannot live inside `:root`. Front 56 wraps both — 54 produces strings and
imports nothing.

```bp
pub fn themeCss(th: Theme) -> string
pub fn keyframeCss(th: Theme) -> ThemeEntry[]
```

`themeCss` joins `name + ":" + value` with `";"`, in the order the entries are held, which is the
order `defaultTheme()` declares them followed by the order each `extend` added them. Deterministic
order matters: the class names emilia hands out are content hashes, and a reordered theme would
produce a different document for the same input.

**Acceptance:**
- [ ] `themeCss(defaultTheme())` starts with `--spacing:0.25rem;`.
- [ ] `themeCss(emptyTheme()) == ""`.
- [ ] Two calls to `themeCss` on the same theme return the same string.
- [ ] `keyframeCss(defaultTheme())` has four entries whose names are `spin`, `ping`, `pulse`,
      `bounce` and whose values are brace-balanced.

### Step 6 — dark-mode strategy

```bp
pub fn darkSelector(th: Theme) -> string
pub fn darkAtRule(th: Theme) -> string
```

`DarkMode.Media` gives `darkAtRule` `"@media (prefers-color-scheme: dark)"` and `darkSelector` `"&"`
(`§ 3.2` reference table). `DarkMode.Class("dark")` gives `darkAtRule` `""` and `darkSelector`
`"&:where(.dark, .dark *)"` (`§ 3.4`). `DarkMode.Attribute("data-theme", "dark")` gives
`"&:where([data-theme=dark], [data-theme=dark] *)"` (`§ 3.4`). Front 34 reads both and builds the
variant; 54 does not own the `Dark` token.

**Acceptance:**
- [ ] All three strategies are covered by a test asserting the exact selector text from `§ 3.4`.
- [ ] Switching a theme's strategy changes nothing else about it.

### Step 7 — a theme is a module

`§ 21.7` shares a theme between projects by importing a CSS file. In botopink a theme is a function
in a module, so sharing it is an ordinary package dependency. This step is one example plus one
test that an imported theme composes with `extend`; it builds no machinery.

**Acceptance:**
- [ ] `examples/theme-example.bp` defines a brand theme in one function and uses it.
- [ ] A test composes `defaultTheme()` with a second theme's entries and asserts both are reachable
      through `themeValue`.

## Examples

- [`./examples/theme-example.bp`](./examples/theme-example.bp) — a project defines a brand theme by
  extending the default, clears the stock colour namespace, reads a value back with `themeValue`,
  and styles one card with spacing that resolves against the theme's `--spacing`.

## Language gaps

None — every construct in the examples parses today.

Two constraints shaped the design and are recorded here because they are easy to rediscover as
bugs, not because they are gaps:

- Records are immutable, so `extend`/`clearNamespace` return a new `Theme` rather than mutating one.
  There is no module-level mutable state in botopink, which is why the theme is threaded as an
  argument instead of read from a global (`repository/emilia/src/emilia.bp` reaches host cells for
  the one piece of state it does have).
- A cross-module bare import of an `#[@External.…]` declaration does not lower
  (`repository/emilia/src/root.bp:9-22`). `theme.bp` and `spacing.bp` declare no externals, so this
  does not bite 54 — it is the reason 56 keeps the host cells in `emilia.bp`.

## Test plan

`repository/emilia/test/theme_test.bp` and `repository/emilia/test/spacing_test.bp`, run by
`botopink test` at `repository/emilia/` and by `zig build test-libs` from
`repository/botopink-lang/`. Track D is target-independent, so both files must be green on
`--target commonJS` **and** `--target erlang`; a theme test that passes on one target only is a
failure, because the only thing 54 produces is strings and a string that differs by backend is a
defect.

`theme_test.bp` asserts: the nineteen prefixes; the `§ 21.3`, `§ 21.4`, `§ 21.5`, `§ 21.6` and
`§ 3.3` default tables entry by entry; extend/override/clear/empty; `themeValue` and `themeVar`;
`themeCss` determinism; the three dark-mode strategies. `spacing_test.bp` asserts the `spacing`
and `spacingHalf` ladder against the `§ 7.1`/`§ 7.2` rows, including `0` and a negative.

The refusal path (`extend` with an unknown prefix) cannot be asserted as a runtime `assert` — a
build that must fail is not a value a test can read. It is recorded the way rakun records its
decorator-placement cases (`repository/rakun/test/di_test.bp:14-16`): a note in the test file, and
the case itself in the compiler's Zig suite.

## Definition of done

- `src/theme.bp` and `src/spacing.bp` exist, are declared in `src/root.bp`, and are listed in
  `botopink.json` `"files"`.
- `defaultTheme()` covers the nineteen namespaces, with the doc's default tables byte-equal.
- `spacing(n)` is the only spacing ladder in `repository/emilia/`; front 35 deletes the seven
  copies in `emilia.bp` as its own step, and 54's test asserts nothing about them.
- `themeCss` and `keyframeCss` produce the strings front 56 wraps.
- Front 33's `paletteEntries()` interface is written down here and in 33, identically.
- The front's tests are green on its assigned target — for track D, both of them.
