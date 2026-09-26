# Front 44 — emilia transitions and animation

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 34 (modifiers — a transition is observable only when a state changes), 54 (`themeVar`, `--animate-*`, `keyframeEntries()`), 56 (`declSheet`, `blockSheet`, `Sheet.blocks`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 44 — transitions and animation`
block: `Transition`, `Animate`, and the top-level `TransitionProperty`, `AnimateRaw`) · `src/emilia.bp`
(front-44 block: `transitionTokenToCss`, `animateTokenToSheet`, `animationSheet`, `transitionEntries`,
`rawTransitionProperty`, `rawAnimate`; four `tokenToSheet` arms after front 43's)
**User docs:** `repository/emilia/docs.md` § *Transition and Animate*
**Reference:** `TAILWIND_CSS_DOCS.md § 15` (animation values `§ 21.6`) · https://tailwindcss.com/docs/transition-property

**Open:** none.

---

## What it delivers

`§ 15` — **36 leaves**. `Transition` is a declaration dispatcher; `Animate` is the one `…TokenToSheet`
in fronts 41–47, because `animate-spin` is a declaration plus a `@keyframes` block.

| Group | Tokens | CSS |
|---|---|---|
| Presets (`§ 15.1`) | `.Transition.{Base, All, Colors, Opacity, Shadow, Transform}` | three declarations each: `transition-property:<list>;transition-timing-function:var(--ease-out);transition-duration:150ms`. `Base` (bare `transition`) lists eleven properties `color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter` — a space after each comma; `Colors` lists the first six |
| None | `.Transition.None` | `transition-property:none` — one declaration |
| Behavior (`§ 15.2`) | `.Transition.Behavior.{Normal, Discrete}` | `transition-behavior:normal`; `Discrete` → `allow-discrete` |
| Duration / delay (`§ 15.3`, `15.5`) | `.Transition.Duration.N`, `.Transition.Delay.N` over `{0, 75, 100, 150, 200, 300, 500, 700, 1000}` | `transition-duration:300ms` — every step carries `ms`, `0ms` included; literal, as upstream has no `--duration-*` |
| Easing (`§ 15.4`) | `.Transition.Ease.{Linear, In, Out, InOut}` | `Linear` → the keyword `linear`; the others `var(--ease-in)` … |
| Animate (`§ 15.6`) | `.Animate.{None, Spin, Ping, Pulse, Bounce}` | `animation:var(--animate-spin)` plus the `@keyframes spin` block; `None` → `animation:none`, no block |
| Arbitrary | `Token.TransitionProperty(value)` / `rawTransitionProperty(v)`, `Token.AnimateRaw(value)` / `rawAnimate(v)` | `transition-property:<v>`; `animation:<v>` through `declSheet`, no block |

- `Base`, not `Default`: `default` is a keyword and `Default(inner)` is front 34's modifier.
- **List order is declaration order**: `[.Transition.Colors, .Transition.Duration.200]` keeps the
  preset's `150ms` with `200ms` after it, so the later wins.
- **Keyframes come from the theme.** `animationSheet(th, name)` reads the body through
  `keyframeCss(th)` (front 54's `keyframeEntries()`, read from upstream `theme.css`); under a theme
  without that body the token still emits its declaration and hoists no block. `renderDocument` hoists
  blocks out of every layer and `dedupeBlocks` makes two spinners one block.
- **`transitionEntries()`** contributes `--ease-in: cubic-bezier(0.4, 0, 1, 1)`,
  `--ease-out: cubic-bezier(0, 0, 0.2, 1)`, `--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1)` to
  `fullTheme()`. The three names are the reference's; the values are upstream v4's `theme.css`
  (the reference prints none).

## Acceptance

### Delivered

- [x] The seven preset leaves return their exact strings; `Base` lists eleven properties in the
      reference's order, asserted whole; `None` is one declaration; `transitionTokenToCss` has no `_`
      arm and takes `th: Theme`.
- [x] `.Transition.Behavior.Discrete` → `transition-behavior:allow-discrete`.
- [x] Nine duration and nine delay steps carry `ms`; `Ease.Linear` is the keyword and the other three
      `var(--ease-…)`, with no `cubic-bezier(` in any `Ease` arm; `[.Transition.Colors,
      .Transition.Duration.300]` puts the override last.
- [x] `animateTokenToSheet(.Pulse, th)` has the declaration and one `@keyframes pulse` block;
      `.Animate.None` and `AnimateRaw` hoist none; `Token.AnimateRaw(…)` and
      `Token.TransitionProperty(…)` construct, qualified and through the wrappers; no payload leaf
      inside a section; two tokens naming one animation render one block; `animateTokenToSheet` has
      no `_` arm.
- [x] The `--animate-*` entries are front 54's; `--ease-*` come from `transitionEntries()`; no leaf
      resolves a timing function or an animation.
- [x] The keyframes bodies were read from upstream `theme.css` (recorded in the comment above
      `keyframeEntries()`) and are asserted as literals.
- [x] Four `tokenToSheet` arms after front 43's; `Animate` is the only one not through `declSheet`,
      and the banner says why; no `_` arm.
- [x] `repository/emilia/AGENTS.md` records the sections, the `…TokenToSheet` exception and the
      keyframes source; a fixed transitions list hashes to the same class on both targets; green on
      commonJS and erlang.

## Not declared

- `@starting-style` — absent from the reference; `Sheet.blocks` would carry it.

## Examples

- [`./examples/transitions-example.bp`](./examples/transitions-example.bp) — the `Transition` and
  `Animate` catalogues, preset-then-override ordering, and a submit button that transitions its
  colours on hover and swaps to a spinner while the form is in flight.
