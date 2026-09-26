# Front 54 — emilia theme

**Track:** D emilia · **Priority:** critical · **Level:** 0 · **Target:** comptime (commonJS and erlang)
**Depends on:** none
**Code:** `repository/emilia/modules/emilia/src/theme.bp`, `src/spacing.bp` (inline `test {}` blocks)
**User docs:** `repository/emilia/docs.md` § *The theme*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.5`, `§ 3.9`, `§ 20.2 @theme`, `§ 20.8 --spacing()`, `§ 20.9 theme()`, `§ 21.1–§ 21.7` · https://tailwindcss.com/docs/theme

**Open:** one box — the unknown-prefix refusal is not yet in the compiler's Zig suite (Step 3).

---

## What it delivers

The theme every other track-D front resolves values through, and the one spacing ladder.

A theme is a **flat list of CSS custom properties**, not one record field per namespace — the only
shape in which "clear one namespace" and "clear everything" are ordinary values. Namespaces stay
typed through the `Ns` enum; `nsPrefix` is the one place a prefix string is written.

```bp
pub type ThemeEntry(name: string, value: string)
pub type DarkMode { Media, Class(name: string), Attribute(name: string, value: string) }
pub type Theme(entries: ThemeEntry[], keyframes: ThemeEntry[], darkMode: DarkMode)
pub type Ns {
    Color, Font, Text, FontWeight, Tracking, Leading, Breakpoint, Container,
    Spacing, Radius, Shadow, InsetShadow, DropShadow, Blur, Perspective,
    Aspect, Ease, Animate, Keyframes,
}
```

| Function | Contract |
|---|---|
| `nsPrefix(ns)` / `allNamespaces()` | the nineteen prefixes (`--color-` … `--animate-`, `--spacing` with no trailing dash, `@keyframes `), in declaration order |
| `defaultTheme()` | `--spacing:0.25rem`, the five `--breakpoint-*`, the eight `--radius-*`, `--color-black`/`--color-white` only, thirteen `--text-*` each paired with `--text-*--line-height`, seven `--shadow-*`, thirteen `--container-*`, four `--animate-*` and the four keyframes (`spin`, `ping`, `pulse`, `bounce`); `DarkMode.Media` |
| `emptyTheme()` | zero entries, zero keyframes — the `--*: initial` reset |
| `extendTheme(th, entries)` | adds entries; a name already present is overridden in place. An entry whose name matches no `Ns` prefix is refused with a message naming it — no permissive mode (the name is not `extend`: that is a keyword) |
| `clearNamespace(th, ns)` / `namespace(th, ns)` | the `--color-*: initial` reset; one namespace's entries in theme order |
| `themeValue(th, name)` / `themeVar(name)` | `theme()` of `§ 20.9` (`""` when absent); the reference form `var(--name)` every utility emits |
| `themeCss(th)` / `keyframeCss(th)` | the `:root` body (`name:value` joined by `;`, in theme order — deterministic, since class names are content hashes); the keyframe entries, bodies brace-balanced |
| `darkAtRule(th)` / `darkSelector(th)` / `withDarkMode(th, mode)` | `Media` → `@media (prefers-color-scheme: dark)` + `&`; `Class("dark")` → `""` + `&:where(.dark, .dark *)`; `Attribute("data-theme", "dark")` → `""` + `&:where([data-theme=dark], [data-theme=dark] *)`. Front 34's `Dark` consumes them |
| `spacing(n)` / `spacingHalf(n)` | `spacing(0) == "0"`, otherwise `calc(var(--spacing) * n)` (negatives included); `spacingHalf(n)` is `calc(var(--spacing) * n.5)`. emilia never resolves a spacing value; `i32`, not `f64`, so no backend float formatting leaks into the string |

The theme block is always the whole theme (upstream's `@theme static`): tree-shaking would need a
whole-program pass over every `emilia()` site. The palette and the other per-front namespaces are
contributed by their fronts as `ThemeEntry[]` functions and composed by `fullTheme()` (front 56).
A theme is a function in a module, so sharing one is an ordinary package dependency
(`repository/emilia/examples/emilia-theme/`).

## Acceptance

### Delivered

- [x] `nsPrefix` has exactly nineteen arms, each exercised by a test, each matching the `§ 3.5`
      table character for character; `--spacing` carries no trailing `-`.
- [x] `Theme` is constructed only by named arguments anywhere in the library.
- [x] `defaultTheme()`: thirteen `--text-*` sizes each paired with a line height (twenty-six
      entries, `§ 21.3`); the seven `--shadow-*` values byte-equal to `§ 21.4`, `sm`–`xl` carrying
      two shadows; the four `--animate-*` values and four keyframes (`§ 21.6`); the thirteen
      `--container-*` entries (`§ 3.3`); no `--color-` entry beyond black and white.
- [x] `extendTheme` adds a new name that reads back through `themeValue`; a name already present is
      overridden in place (namespace length unchanged).
- [x] `clearNamespace(th, Ns.Color)` empties the colour namespace and leaves the others unchanged.
- [x] `emptyTheme()` has zero entries and keyframes, and `themeValue` on it reads `""`.
- [x] `spacing(0) == "0"`, `spacing(4) == "calc(var(--spacing) * 4)"`, `spacing(-4) ==
      "calc(var(--spacing) * -4)"`, `spacingHalf(0) == "calc(var(--spacing) * 0.5)"` — identical on
      commonJS and erlang.
- [x] `themeCss(defaultTheme())` starts with `--spacing:0.25rem;`; `themeCss(emptyTheme()) == ""`;
      two calls return the same string; `keyframeCss(defaultTheme())` has the four named,
      brace-balanced bodies.
- [x] The three dark-mode strategies are asserted with the exact `§ 3.4` selector text; switching
      the strategy changes nothing else about the theme.
- [x] A brand theme is defined in one function and used (`examples/emilia-theme`), and a test
      composes `defaultTheme()` with a second package's entries, both reachable through `themeValue`.

### Open

- [ ] `extendTheme(th, [ThemeEntry(name: "--gutter", value: "1rem")])` aborts with a message
      naming the unknown prefix. A test asserts the *absence* of the entry, and the wrong-placement
      case is recorded in the compiler's own suite per the project convention. — the abort holds
      (`theme.bp` `checkEntry` panics naming the entry; the file records why absence is not asserted
      at runtime); the `--gutter` case is not yet in the compiler's Zig suite.

## Constraints

- Records are immutable and there is no module-level mutable state: `extendTheme`/`clearNamespace`
  return a new `Theme`, and the theme is threaded as an argument.
- A cross-module bare import of an `#[@External.…]` declaration does not lower; `theme.bp` and
  `spacing.bp` declare no externals, which is why the host cells live in `emilia.bp` (front 56).

## Examples

- [`./examples/theme-example.bp`](./examples/theme-example.bp) — a brand theme extending the default,
  a cleared colour namespace, a `themeValue` readback, and one card spaced against `--spacing`.
