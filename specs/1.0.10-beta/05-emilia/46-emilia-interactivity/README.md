# Front 46 — emilia interactivity

**Track:** D emilia · **Priority:** medium · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 33 (`paletteVar` for the colour payloads), 54 (`spacing(n)`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 46 — interactivity` block:
`Interact`, and the top-level `InteractAccent`, `InteractCaret`, `InteractScrollbarColor`) ·
`src/emilia.bp` (front-46 block: `interactTokenToCss` and its sub-dispatchers taking `th: Theme`; the
wrappers `accent(value)`, `caret(value)`, `scrollbarColor(thumb, track)`; four `tokenToSheet` arms
after front 45's)
**User docs:** `repository/emilia/docs.md` § *Interact*
**Reference:** `TAILWIND_CSS_DOCS.md § 17` (spacing base `§ 21.2`) · https://tailwindcss.com/docs/cursor

**Open:** none.

---

## What it delivers

`§ 17` — **161 leaves** in one `Interact` section, none resolving a length or a colour.

| Group | Tokens | CSS |
|---|---|---|
| Cursor (`§ 17.5`) | `.Interact.Cursor.*` — 36 leaves (`Auto`, `Standard`, `Pointer`, … `NotAllowed`, … `ZoomOut`) | `cursor:<value>`; `Standard` → `cursor:default` (`default` is a keyword) |
| Form controls | `.Interact.Appearance.{None, Auto}`, `.Interact.FieldSizing.{Fixed, Content}`, `.Interact.ColorScheme.{Normal, Light, Dark, LightDark, OnlyDark, OnlyLight}`, `.Interact.AccentAuto` | `color-scheme:light dark`; `AccentAuto` → `accent-color:auto` (decision 81) |
| Colours | `Token.InteractAccent(value)`, `Token.InteractCaret(value)`, `Token.InteractScrollbarColor(thumb, track)` — top-level; wrappers `accent`, `caret`, `scrollbarColor` | `accent-color:<v>`, `caret-color:<v>`, `scrollbar-color:<thumb> <track>`; the value is always `paletteVar(family, shade)`, e.g. `var(--color-indigo-600)` — never a hex |
| Pointer / resize / select / will-change / touch | `.Interact.PointerEvents.{None, Auto}`, `.Interact.Resize.{None, Y, X, Both}`, `.Interact.Select.{None, Text, All, Auto}`, `.Interact.WillChange.{Auto, Scroll, Contents, Transform}`, `.Interact.Touch.*` (10) | `resize-y` → `resize:vertical`, `resize-x` → `horizontal`, `will-change-scroll` → `scroll-position`; `user-select:none`; `touch-action:pan-x` |
| Scroll (`§ 17.12`–`17.14`) | `.Interact.Scroll.Behavior.{Auto, Smooth}`; `.Interact.Scroll.{M, Mx, My, Mt, Mr, Mb, Ml, P, Px, Py, Pt, Pr, Pb, Pl}.{0, 1, 2, 4, 8}` | `scroll-margin-top:calc(var(--spacing) * 4)`; `M.0` → `scroll-margin:0`; axes are two declarations, left before right, top before bottom |
| Scrollbar (`§ 17.10`) | `.Interact.Scrollbar.Width.{Auto, Thin, None}`, `.Interact.Scrollbar.Gutter.{Auto, Stable, StableBothEdges}` | `scrollbar-gutter:stable both-edges` |
| Snap (`§ 17.15`–`17.18`) | `.Interact.Snap.Align.{Start, End, Center, None}`, `.Snap.Stop.{Normal, Always}`, `.Snap.Type.{None, X, Y, Both}`, `.Snap.Strictness.{Mandatory, Proximity}` | `scroll-snap-type:x var(--tw-scroll-snap-strictness, proximity)`; `--tw-scroll-snap-strictness:mandatory`; `snap-none` (`Type.None`) and `snap-align-none` (`Align.None`) are different properties |

- **The snap pairing.** `Snap.Type` reads `--tw-scroll-snap-strictness` and `Snap.Strictness` writes it;
  both land in one rule. A lone `Snap.Type.X` falls back to upstream's `@property` initial value
  `proximity` inlined through `cssVarOr` — a `--tw-*` default cannot be a theme entry.
- `scrollbar-color` is one property taking two colours, so it is one variant with two fields,
  destructured by their declared names.

## Acceptance

### Delivered

- [x] Thirty-six cursor arms in `interactCursorToCss`, no `_`; `Cursor.Standard` → `cursor:default`;
      kebab values keep their hyphens.
- [x] `ColorScheme.LightDark` → `color-scheme:light dark`;
      `Token.InteractAccent(value: paletteVar("indigo", "600"))` constructs and emits
      `accent-color:var(--color-indigo-600)`; no hex in any test or example; no payload leaf inside a
      section.
- [x] `Resize.Y` → `resize:vertical`; `WillChange.Scroll` → `will-change:scroll-position`; all ten
      `touch-action` values keep their prefix.
- [x] `Scroll.Mt.4` → `scroll-margin-top:calc(var(--spacing) * 4)`; no `rem` in the block;
      `Scroll.M.0` → `scroll-margin:0`; `Mx.4`/`My.4` asserted whole.
- [x] `InteractScrollbarColor(thumb: paletteVar("red", …), track: paletteVar("gray", …))` →
      `scrollbar-color:var(--color-red-500) var(--color-gray-200)`; its arm destructures
      `(thumb, track)`; `Gutter.StableBothEdges` → `scrollbar-gutter:stable both-edges`.
- [x] `[.Interact.Snap.Type.X, .Interact.Snap.Strictness.Mandatory]` declares both in one rule; the
      lone type uses the `proximity` fallback; `snap-none` and `snap-align-none` asserted adjacently;
      the pairing is stated in the `tokens.bp` docblock.
- [x] Four `tokenToSheet` arms right after front 45's, each one `declSheet(…)`, destructuring by
      declared field name; no `_` arm.
- [x] `Interact` has `Cursor`, `Appearance`, `FieldSizing`, `ColorScheme`, `PointerEvents`, `Resize`,
      `Select`, `WillChange`, `Touch`, `Scroll`, `Scrollbar`, `Snap` and the nullary `AccentAuto`, no
      payload leaf; all 161 leaves well formed, none resolving a length or a colour;
      `repository/emilia/AGENTS.md` records the section and both notes; green on commonJS and erlang.

## Examples

- [`./examples/interactivity-example.bp`](./examples/interactivity-example.bp) — the `Interact`
  catalogue, the snap pairing, a snapping carousel, a drag handle whose cursor changes while held, and
  a non-interactive overlay.
