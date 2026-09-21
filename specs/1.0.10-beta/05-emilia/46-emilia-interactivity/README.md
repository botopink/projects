# Front 46 — emilia interactivity

**Track:** D emilia
**Priority:** medium — twenty CSS properties that decide whether a page can be dragged, scrolled, selected or clicked, and `emilia` has a token for none of them
**Target:** comptime
**Wave:** 3
**Depends on:** 33 (the palette — `accent-color`, `caret-color` and `scrollbar-color` take colours, and this front takes them as payloads rather than duplicating front 33's families)
**Owns:** token section `Interact` in `repository/emilia/src/tokens.bp` · dispatcher `interactTokenToCss` in `repository/emilia/src/emilia.bp` · `repository/emilia/test/interactivity_test.bp`
**Does not touch:** every other token section and sub-dispatcher; `emilia()`, `flush()`, `tokensToCss`, `hashHex`, `register`, `flushSheet`
**Reference:** `TAILWIND_CSS_DOCS.md § 17. Interatividade` (the spacing base from `§ 21.2`) · https://tailwindcss.com/docs/cursor
**Replaces:** `1.0.8-beta/12-emilia-interactivity`

---

## Problem

`emilia` can say what an element looks like and cannot say how it behaves under a pointer.
`repository/emilia/src/tokens.bp:36-270` has no `cursor`, no `user-select`, no `pointer-events`, no
scroll family, no `touch-action` and no form-control properties. A disabled button cannot get
`cursor: not-allowed`, a drag handle cannot get `cursor: grab`, a decorative overlay cannot get
`pointer-events: none`, a carousel cannot snap, and a checkbox cannot take the brand colour.

Two of those are not cosmetic. `pointer-events: none` is the standard way to make an overlay
non-interactive, and without it an overlay that is visually behind the content still swallows every
click. `scroll-margin-top` is the standard fix for an anchor target that lands under a sticky
header, and without it every in-page link on a site with a fixed header scrolls to the wrong place.

`§ 17` is the largest section of the reference — twenty subsections — and it is also the flattest:
almost every row is one class to one property/value pair, with no theme variable and no composition
problem. The work is breadth, and the risk is transcription, not design.

## Current state

- No `Interact` section, and no `cursor`, `resize`, `scroll-`, `snap-`, `touch-action`,
  `user-select`, `will-change`, `appearance`, `accent-color`, `caret-color`, `field-sizing`,
  `color-scheme` or `scrollbar-` string anywhere in `repository/emilia/src/`.
- `Pad` and `Margin` — `tokens.bp:140-183` — carry the step set `{1, 2, 4, 8, 16}` / `{1, 2, 4, 8}`,
  which is the house precedent the scroll-margin and scroll-padding scales follow.
- `Color.Hex(value: string)` — `tokens.bp:115` — is the working precedent for a leaf carrying a
  colour as a string, which is how this front takes `accent-color`, `caret-color` and
  `scrollbar-color` without reaching into front 33's palette.
- `tokensToCss` joins tokens with `;` — `emilia.bp:103`. That join is what makes
  `scroll-snap-type` work here; see the note in Step 6.

## Mechanism

One top-level section, `Interact`, with fourteen sub-sections, one dispatcher and fourteen sub-
dispatchers. Almost every leaf is one property/value pair copied from the reference.

**Colours are top-level payload variants, and their values come from front 33.** `§ 17.1`, `§ 17.3`
and `§ 17.10` give only HTML examples — `accent-indigo-600`, `caret-red-500`,
`scrollbar-thumb-red-500` — and no property/value rows. The property comes from the subsection
heading (`accent-color`, `caret-color`, `scrollbar-color`); the value is a palette colour, and the
palette belongs to front 33.

Two facts settle the shape, and the first draft of this front got both wrong.

1. **A payload leaf nested inside an enum section cannot be constructed by any spelling.** Verified
   against the real compiler and recorded as `language-gaps.md` row 52:
   `Token.Interact.Accent(value: "…")` reports
   `'Accent' is not declared in any behavior implemented for 'Token'`, and the dot form reports
   `unbound variable 'Interact'`. Contract `§ 4a` therefore names these three at the **top level** of
   `Token`: `Token.InteractAccent(value: string)`, `Token.InteractCaret(value: string)`,
   `Token.InteractScrollbarColor(thumb: string, track: string)`.
2. **The payload is not a hand-written hex.** Contract `§ 4a` pins it to front 33's
   `paletteVar(family, shade)`, which returns `var(--color-indigo-500)`. A developer writes
   `accent(paletteVar("indigo", 500))`, and `accent-indigo-500` and `bg-indigo-500` then read the
   *same* theme entry and cannot drift. A literal `#4f46e5` here would be a second copy of a colour
   the theme owns, which is exactly the drift the palette front exists to prevent.

The fields stay builtin-typed (`string`) rather than section-typed, because a section-typed value
cannot be constructed standalone either (`language-gaps.md` row 53).

**Scroll offsets are `spacing(n)`.** `§ 17.13` and `§ 17.14` give `scroll-m-0`, `scroll-mt-4` →
`scroll-margin-top: calc(var(--spacing) * 4)` and write the two axis rows with their values elided
(`scroll-margin-left: ...; scroll-margin-right: ...`). The elision is filled by the per-side row in
the same table — both sides get `spacing(n)` — and the step set is `{0, 1, 2, 4, 8}`, the same steps
`Pad` and `Margin` already use. Contract `§ 4a` requires `spacing(n)` to stay
`calc(var(--spacing) * n)` and never resolve to a `rem`, which is what `§ 17.13` writes anyway.

**Dispatcher shape.** Per contract `§ 4a`:

```bp
fn interactTokenToCss(t: Token.Interact, th: Theme) -> string
```

No `Interact` token needs a selector outside its own class — cursor, scroll offsets, snap and
touch-action all apply to the element carrying them — so this front keeps the declaration-string
form and does not take the `…TokenToSheet(t, th) -> Sheet` shape. The three top-level colour
variants are handled in their own `tokenToSheet` arms, not by `interactTokenToCss`.

As everywhere in `emilia`, the declaration is written `prop:value` with no space after the colon
(`emilia.bp:108-115`). The **value** is byte-equal to the reference; the separator is emilia's.

## Steps

### Step 1 — `cursor`

Thirty-six leaves, one per `§ 17.5` row. The value is always the class suffix unchanged.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `cursor-auto` | `.Interact.Cursor.Auto` | `cursor:auto` |
| `cursor-default` | `.Interact.Cursor.Standard` | `cursor:default` |
| `cursor-pointer` | `.Interact.Cursor.Pointer` | `cursor:pointer` |
| `cursor-wait` | `.Interact.Cursor.Wait` | `cursor:wait` |
| `cursor-text` | `.Interact.Cursor.Text` | `cursor:text` |
| `cursor-move` | `.Interact.Cursor.Move` | `cursor:move` |
| `cursor-help` | `.Interact.Cursor.Help` | `cursor:help` |
| `cursor-not-allowed` | `.Interact.Cursor.NotAllowed` | `cursor:not-allowed` |
| `cursor-none` | `.Interact.Cursor.None` | `cursor:none` |
| `cursor-context-menu` | `.Interact.Cursor.ContextMenu` | `cursor:context-menu` |
| `cursor-progress` | `.Interact.Cursor.Progress` | `cursor:progress` |
| `cursor-cell` | `.Interact.Cursor.Cell` | `cursor:cell` |
| `cursor-crosshair` | `.Interact.Cursor.Crosshair` | `cursor:crosshair` |
| `cursor-vertical-text` | `.Interact.Cursor.VerticalText` | `cursor:vertical-text` |
| `cursor-alias` | `.Interact.Cursor.Alias` | `cursor:alias` |
| `cursor-copy` | `.Interact.Cursor.Copy` | `cursor:copy` |
| `cursor-no-drop` | `.Interact.Cursor.NoDrop` | `cursor:no-drop` |
| `cursor-grab` | `.Interact.Cursor.Grab` | `cursor:grab` |
| `cursor-grabbing` | `.Interact.Cursor.Grabbing` | `cursor:grabbing` |
| `cursor-all-scroll` | `.Interact.Cursor.AllScroll` | `cursor:all-scroll` |
| `cursor-col-resize` | `.Interact.Cursor.ColResize` | `cursor:col-resize` |
| `cursor-row-resize` | `.Interact.Cursor.RowResize` | `cursor:row-resize` |
| `cursor-n-resize` | `.Interact.Cursor.NResize` | `cursor:n-resize` |
| `cursor-e-resize` | `.Interact.Cursor.EResize` | `cursor:e-resize` |
| `cursor-s-resize` | `.Interact.Cursor.SResize` | `cursor:s-resize` |
| `cursor-w-resize` | `.Interact.Cursor.WResize` | `cursor:w-resize` |
| `cursor-ne-resize` | `.Interact.Cursor.NeResize` | `cursor:ne-resize` |
| `cursor-nw-resize` | `.Interact.Cursor.NwResize` | `cursor:nw-resize` |
| `cursor-se-resize` | `.Interact.Cursor.SeResize` | `cursor:se-resize` |
| `cursor-sw-resize` | `.Interact.Cursor.SwResize` | `cursor:sw-resize` |
| `cursor-ew-resize` | `.Interact.Cursor.EwResize` | `cursor:ew-resize` |
| `cursor-ns-resize` | `.Interact.Cursor.NsResize` | `cursor:ns-resize` |
| `cursor-nesw-resize` | `.Interact.Cursor.NeswResize` | `cursor:nesw-resize` |
| `cursor-nwse-resize` | `.Interact.Cursor.NwseResize` | `cursor:nwse-resize` |
| `cursor-zoom-in` | `.Interact.Cursor.ZoomIn` | `cursor:zoom-in` |
| `cursor-zoom-out` | `.Interact.Cursor.ZoomOut` | `cursor:zoom-out` |

`cursor-default` is spelled `.Interact.Cursor.Standard`: `default` is in the language's keyword
table (`modules/compiler-core/src/lexer.zig:721-767`), and a leaf whose name differs from a keyword
only by case is an avoidable hazard. The emitted value is still `default`.

**Acceptance:**
- [ ] Thirty-six arms in `cursorToCss`, exhaustive, no `_`.
- [ ] `interactTokenToCss(.Cursor.Standard, th)` returns `cursor:default`.
- [ ] Every kebab-case value keeps its hyphens: `not-allowed`, `nesw-resize`, `zoom-out`.

### Step 2 — the form-control properties

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `appearance-none` | `.Interact.Appearance.None` | `appearance:none` |
| `appearance-auto` | `.Interact.Appearance.Auto` | `appearance:auto` |
| `field-sizing-fixed` | `.Interact.FieldSizing.Fixed` | `field-sizing:fixed` |
| `field-sizing-content` | `.Interact.FieldSizing.Content` | `field-sizing:content` |
| `accent-indigo-600` | `Token.InteractAccent(value: v)` — **top-level** | `accent-color:<v>` |
| `caret-red-500` | `Token.InteractCaret(value: v)` — **top-level** | `caret-color:<v>` |
| `color-scheme-normal` | `.Interact.ColorScheme.Normal` | `color-scheme:normal` |
| `color-scheme-light` | `.Interact.ColorScheme.Light` | `color-scheme:light` |
| `color-scheme-dark` | `.Interact.ColorScheme.Dark` | `color-scheme:dark` |
| `color-scheme-light-dark` | `.Interact.ColorScheme.LightDark` | `color-scheme:light dark` |
| `color-scheme-only-dark` | `.Interact.ColorScheme.OnlyDark` | `color-scheme:only dark` |
| `color-scheme-only-light` | `.Interact.ColorScheme.OnlyLight` | `color-scheme:only light` |

`accent-color` and `caret-color` are top-level payload variants for the reason stated under
*Mechanism*, and `v` is `paletteVar("indigo", 600)` → `var(--color-indigo-600)`, not a hex.

**Acceptance:**
- [ ] `interactTokenToCss(.ColorScheme.LightDark, th)` returns `color-scheme:light dark` — one
      space, two words.
- [ ] `Token.InteractAccent(value: paletteVar("indigo", 600))` **constructs** and its arm returns
      `accent-color:var(--color-indigo-600)`.
- [ ] No hex literal appears in any test or example of this front: every colour goes through
      `paletteVar`.
- [ ] No section in this front's `tokens.bp` block contains a payload leaf.

### Step 3 — `pointer-events`, `resize`, `user-select`, `will-change`, `touch-action`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `pointer-events-none` | `.Interact.PointerEvents.None` | `pointer-events:none` |
| `pointer-events-auto` | `.Interact.PointerEvents.Auto` | `pointer-events:auto` |
| `resize-none` | `.Interact.Resize.None` | `resize:none` |
| `resize-y` | `.Interact.Resize.Y` | `resize:vertical` |
| `resize-x` | `.Interact.Resize.X` | `resize:horizontal` |
| `resize` | `.Interact.Resize.Both` | `resize:both` |
| `select-none` | `.Interact.Select.None` | `user-select:none` |
| `select-text` | `.Interact.Select.Text` | `user-select:text` |
| `select-all` | `.Interact.Select.All` | `user-select:all` |
| `select-auto` | `.Interact.Select.Auto` | `user-select:auto` |
| `will-change-auto` | `.Interact.WillChange.Auto` | `will-change:auto` |
| `will-change-scroll` | `.Interact.WillChange.Scroll` | `will-change:scroll-position` |
| `will-change-contents` | `.Interact.WillChange.Contents` | `will-change:contents` |
| `will-change-transform` | `.Interact.WillChange.Transform` | `will-change:transform` |
| `touch-auto` | `.Interact.Touch.Auto` | `touch-action:auto` |
| `touch-none` | `.Interact.Touch.None` | `touch-action:none` |
| `touch-pan-x` | `.Interact.Touch.PanX` | `touch-action:pan-x` |
| `touch-pan-left` | `.Interact.Touch.PanLeft` | `touch-action:pan-left` |
| `touch-pan-right` | `.Interact.Touch.PanRight` | `touch-action:pan-right` |
| `touch-pan-y` | `.Interact.Touch.PanY` | `touch-action:pan-y` |
| `touch-pan-up` | `.Interact.Touch.PanUp` | `touch-action:pan-up` |
| `touch-pan-down` | `.Interact.Touch.PanDown` | `touch-action:pan-down` |
| `touch-pinch-zoom` | `.Interact.Touch.PinchZoom` | `touch-action:pinch-zoom` |
| `touch-manipulation` | `.Interact.Touch.Manipulation` | `touch-action:manipulation` |

Three rows here have a class name that does not match the CSS value and each is a place a
from-memory transcription goes wrong: `resize-y` → `vertical`, `resize-x` → `horizontal`,
`will-change-scroll` → `scroll-position`.

**Acceptance:**
- [ ] `interactTokenToCss(.Resize.Y, th)` returns `resize:vertical`, not `resize:y`.
- [ ] `interactTokenToCss(.WillChange.Scroll, th)` returns `will-change:scroll-position`.
- [ ] All ten `touch-action` values keep the `pan-`/`pinch-` prefix.

### Step 4 — `scroll-behavior`, `scroll-margin`, `scroll-padding`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `scroll-auto` | `.Interact.Scroll.Behavior.Auto` | `scroll-behavior:auto` |
| `scroll-smooth` | `.Interact.Scroll.Behavior.Smooth` | `scroll-behavior:smooth` |
| `scroll-m-0` | `.Interact.Scroll.M.0` | `scroll-margin:0` |
| `scroll-m-4` | `.Interact.Scroll.M.4` | `scroll-margin:calc(var(--spacing) * 4)` |
| `scroll-mx-4` | `.Interact.Scroll.Mx.4` | `scroll-margin-left:calc(var(--spacing) * 4);scroll-margin-right:calc(var(--spacing) * 4)` |
| `scroll-my-4` | `.Interact.Scroll.My.4` | `scroll-margin-top:calc(var(--spacing) * 4);scroll-margin-bottom:calc(var(--spacing) * 4)` |
| `scroll-mt-4` | `.Interact.Scroll.Mt.4` | `scroll-margin-top:calc(var(--spacing) * 4)` |
| `scroll-mr-4` | `.Interact.Scroll.Mr.4` | `scroll-margin-right:calc(var(--spacing) * 4)` |
| `scroll-mb-4` | `.Interact.Scroll.Mb.4` | `scroll-margin-bottom:calc(var(--spacing) * 4)` |
| `scroll-ml-4` | `.Interact.Scroll.Ml.4` | `scroll-margin-left:calc(var(--spacing) * 4)` |
| `scroll-p-0` | `.Interact.Scroll.P.0` | `scroll-padding:0` |
| `scroll-px-4` | `.Interact.Scroll.Px.4` | `scroll-padding-left:calc(var(--spacing) * 4);scroll-padding-right:calc(var(--spacing) * 4)` |
| `scroll-py-4` | `.Interact.Scroll.Py.4` | `scroll-padding-top:calc(var(--spacing) * 4);scroll-padding-bottom:calc(var(--spacing) * 4)` |
| `scroll-pt-4` | `.Interact.Scroll.Pt.4` | `scroll-padding-top:calc(var(--spacing) * 4)` |
| `scroll-pr-4` | `.Interact.Scroll.Pr.4` | `scroll-padding-right:calc(var(--spacing) * 4)` |
| `scroll-pb-4` | `.Interact.Scroll.Pb.4` | `scroll-padding-bottom:calc(var(--spacing) * 4)` |
| `scroll-pl-4` | `.Interact.Scroll.Pl.4` | `scroll-padding-left:calc(var(--spacing) * 4)` |

Each of the twelve offset sub-sections carries the steps `{0, 1, 2, 4, 8}`; the table shows `4` and
`0` as representatives. The `0` step emits `0` with no `calc` and no unit, matching the reference's
own `scroll-m-0` and `scroll-p-0` rows. The two axis sub-sections emit two declarations joined by
`;`, which is the same join `tokensToCss` uses, so they drop into a rule body unchanged.

**Acceptance:**
- [ ] `interactTokenToCss(.Scroll.Mt.4, th)` returns `scroll-margin-top:calc(var(--spacing) * 4)` —
      `spacing(4)`, spaces around the `*` kept, and **no `rem` literal anywhere in this front's
      block**.
- [ ] `.Interact.Scroll.M.0` returns `scroll-margin:0`, with no `calc`.
- [ ] `.Interact.Scroll.Mx.4` returns two declarations, left before right; `.My.4` returns top before
      bottom. Both asserted whole.

### Step 5 — the scrollbar family

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `scrollbar-auto` | `.Interact.Scrollbar.Width.Auto` | `scrollbar-width:auto` |
| `scrollbar-thin` | `.Interact.Scrollbar.Width.Thin` | `scrollbar-width:thin` |
| `scrollbar-none` | `.Interact.Scrollbar.Width.None` | `scrollbar-width:none` |
| `scrollbar-gutter-auto` | `.Interact.Scrollbar.Gutter.Auto` | `scrollbar-gutter:auto` |
| `scrollbar-gutter-stable` | `.Interact.Scrollbar.Gutter.Stable` | `scrollbar-gutter:stable` |
| `scrollbar-gutter-stable-both-edges` | `.Interact.Scrollbar.Gutter.StableBothEdges` | `scrollbar-gutter:stable both-edges` |
| `scrollbar-thumb-red-500 scrollbar-track-gray-200` | `Token.InteractScrollbarColor(thumb: t, track: k)` — **top-level** | `scrollbar-color:<t> <k>` |

`scrollbar-color` is one CSS property taking two colours, and upstream it is two classes. A token
per class would mean two `scrollbar-color:` declarations and the second winning, so this front makes
it one **top-level** variant with two payload fields — the shape `docs.md:246`
(`Node(left: …, right: …)`) shows is legal, and top-level because a nested payload leaf does not
construct at all. Both fields are `string` and both carry a `paletteVar(...)` result. They are read
by their declared names, which is required: a payload is projected by field name, and an arbitrary
positional bind type-checks and is `undefined` at run time.

**Acceptance:**
- [ ] `Token.InteractScrollbarColor(thumb: paletteVar("red", 500), track: paletteVar("gray", 200))`
      returns `scrollbar-color:var(--color-red-500) var(--color-gray-200)` — one space between them.
- [ ] The `case` arm destructures as `InteractScrollbarColor(thumb, track)`, matching the declared
      field names.
- [ ] `interactTokenToCss(.Scrollbar.Gutter.StableBothEdges, th)` returns
      `scrollbar-gutter:stable both-edges`.

### Step 6 — the snap family, and the one place a `--tw-*` variable resolves

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `snap-start` | `.Interact.Snap.Align.Start` | `scroll-snap-align:start` |
| `snap-end` | `.Interact.Snap.Align.End` | `scroll-snap-align:end` |
| `snap-center` | `.Interact.Snap.Align.Center` | `scroll-snap-align:center` |
| `snap-align-none` | `.Interact.Snap.Align.None` | `scroll-snap-align:none` |
| `snap-normal` | `.Interact.Snap.Stop.Normal` | `scroll-snap-stop:normal` |
| `snap-always` | `.Interact.Snap.Stop.Always` | `scroll-snap-stop:always` |
| `snap-none` | `.Interact.Snap.Type.None` | `scroll-snap-type:none` |
| `snap-x` | `.Interact.Snap.Type.X` | `scroll-snap-type:x var(--tw-scroll-snap-strictness)` |
| `snap-y` | `.Interact.Snap.Type.Y` | `scroll-snap-type:y var(--tw-scroll-snap-strictness)` |
| `snap-both` | `.Interact.Snap.Type.Both` | `scroll-snap-type:both var(--tw-scroll-snap-strictness)` |
| `snap-mandatory` | `.Interact.Snap.Strictness.Mandatory` | `--tw-scroll-snap-strictness:mandatory` |
| `snap-proximity` | `.Interact.Snap.Strictness.Proximity` | `--tw-scroll-snap-strictness:proximity` |

`snap-x` reads `var(--tw-scroll-snap-strictness)` and `snap-mandatory` writes it, and front 56's
`Rule.declarations` keeps both in one rule — so a list containing `.Interact.Snap.Type.X` and
`.Interact.Snap.Strictness.Mandatory` produces a class where the variable resolves. The first draft
of this front called this the *only* such chain in fronts 41–47; it is now the general mechanism,
and fronts 42 and 45 use the same shape for `filter` and `translate`.

The remaining contract is: **a `Snap.Type` token without a `Snap.Strictness` token falls back to the
theme's `--tw-scroll-snap-strictness` entry**, which front 54 carries, so the lone token still
renders. The test file asserts both the explicit pair and the lone `Snap.Type.X`.

**Acceptance:**
- [ ] `[.Interact.Snap.Type.X, .Interact.Snap.Strictness.Mandatory]` produces
      `scroll-snap-type:x var(--tw-scroll-snap-strictness)` and
      `--tw-scroll-snap-strictness:mandatory` as two entries of `Rule.declarations`.
- [ ] The `--tw-scroll-snap-strictness` default is contributed to front 54's theme and named in this
      front's `TODO.md`.
- [ ] `snap-align-none` maps to `Snap.Align.None` and `snap-none` to `Snap.Type.None` — two
      different properties whose class names differ by one word, asserted adjacently.
- [ ] The pairing contract is stated in the `tokens.bp` docblock.

### Step 7 — four new arms in `tokenToSheet`

Per contract `§ 4a` the top-level dispatcher is `tokenToSheet`, reached through `declSheet(...)`,
and each top-level payload variant needs its own arm.

```bp
        Interact(_inner) -> declSheet(interactTokenToCss(_inner, th));
        InteractAccent(value) -> declSheet("accent-color:" + value);
        InteractCaret(value) -> declSheet("caret-color:" + value);
        InteractScrollbarColor(thumb, track) -> declSheet("scrollbar-color:" + thumb + " " + track);
```

**Acceptance:**
- [ ] The four arms sit between front 45's arms and front 47's, in front-number order.
- [ ] Each arm is one `declSheet(...)` call; none builds a `Rule` or a `Sheet` by hand.
- [ ] Every payload arm destructures by declared field name (`value`, `thumb`, `track`).
- [ ] `tokenToSheet` still has no `_` arm.

## Examples

- [`./examples/interactivity-example.bp`](./examples/interactivity-example.bp) — the whole
  `Interact` catalogue, the snap pairing shown as working code, then a horizontal image carousel
  that snaps, a drag handle that changes cursor while held, and a non-interactive overlay.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — `language-gaps.md` row 52, verified against `zig-out/bin/botopink` | this front's three colour-carrying variants, written `Interact.Accent`, `Interact.Caret` and `Interact.Scrollbar.Color` in the first draft. They are the only way this front takes a colour, so the defect would have made a third of the section unusable | the variants move to the **top level** of `Token` per contract `§ 4a`: `Token.InteractAccent(value: string)`, `Token.InteractCaret(value: string)`, `Token.InteractScrollbarColor(thumb: string, track: string)`, each with its own `tokenToSheet` arm | let a section leaf carry a payload and be constructed through its path, so a colour token can live beside the section it belongs to |
| **A section-typed value cannot be constructed standalone** — `language-gaps.md` row 53 | the same three: their fields cannot be typed as a colour section | fields stay builtin-typed (`string`) and carry front 33's `paletteVar(family, shade)` result | dot-shorthand rooted at the parameter's declared section type |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context** — `language-gaps.md` row 51 | the same three, now top-level: `[.InteractAccent(paletteVar("indigo", 600))]` still trips the parser | a wrapper fn returning the token (`fn accent(v: string) -> Token { return Token.InteractAccent(value: v); }`) or a typed `val` intermediate | let a leading-dot path carry a payload call inside a typed array literal |

## Reconciled with front 33

The first draft of this front left the colour payload as an open question: a bare `string`, with a
note that front 33 might supersede it. Contract `§ 4a` closed it. `Token.InteractAccent`,
`Token.InteractCaret` and `Token.InteractScrollbarColor` keep `string` fields — a section-typed
field would not construct (`language-gaps.md` row 53) — and the **value** is always front 33's
`paletteVar(family, shade)`, which returns `var(--color-indigo-500)`. This front therefore holds no
copy of the palette and cannot drift from it: `accent-indigo-500` and `bg-indigo-500` read one theme
entry. A hex literal anywhere in this front is a defect, and a test asserts their absence.

## Test plan

`repository/emilia/test/interactivity_test.bp`, run by `botopink test` from `repository/emilia/` and
by `zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it
emits a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert interactTokenToCss(<token>, th) == "<css>"` per row of
   the six tables, and one per step of each of the twelve scroll-offset sub-sections; the three
   top-level colour variants are asserted through their `tokenToSheet` arms. This is the largest
   test file in track D and it is almost entirely transcription checking, which is the right shape
   for a front whose risk is transcription.
1b. **No hex, no `rem`.** A test greps this front's block of `emilia.bp` and this front's tests for
   `#` followed by six hex digits, and for `rem`, and fails on either — colours come from
   `paletteVar` and offsets from `spacing(n)`.
2. **The three names that do not match their values.** `resize-y` → `vertical`, `resize-x` →
   `horizontal`, `will-change-scroll` → `scroll-position`, asserted in three adjacent lines with a
   comment saying the class name lies.
3. **`snap-none` versus `snap-align-none`.** Two properties, class names one word apart, asserted
   adjacently.
4. **The snap pairing.** One test for the explicit pair (variable written and read in one rule) and
   one for the lone `Snap.Type.X`, which falls back to front 54's theme entry — the second test
   pins the fallback rather than an unresolved variable.
5. **The axis scroll offsets.** `Mx.4` and `My.4` asserted whole, so the two-declaration order is
   pinned; swapping left and right inside one declaration is invisible otherwise.
6. **The `0` steps.** `Scroll.M.0` and `Scroll.P.0` emit a bare `0`, so a refactor that runs every
   step through one `calc(…)` template fails here.
7. **Variant nesting.** `Token.Hover([.Interact.Cursor.Grabbing])` reaches front 34's `nestVariant`
   with the inner declaration `cursor:grabbing`; this front asserts the declaration, not the wrap.
   The carousel example's full token list round-trips through `emilia()` and `await flush()` to a
   literal `<style>` string.
8. **The three colour variants construct.** A test builds each of `InteractAccent`, `InteractCaret`
   and `InteractScrollbarColor` — the check that would have failed against the nested spelling.
9. **Determinism across targets.** The class name for a fixed `Token[]` **and a fixed `Theme`** is
   asserted as a literal, so `commonJS` and `erlang` must agree on the `djb2` hash of
   `encodeSheet(tokensToSheet(tokens, th))` (contract `§ 4`). Every value here is ASCII, the
   condition `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Interact` exists as a top-level section with `Cursor`, `Appearance`, `FieldSizing`,
      `ColorScheme`, `PointerEvents`, `Resize`, `Select`, `WillChange`, `Touch`, `Scroll`,
      `Scrollbar`, `Snap` — and **no payload leaf** — fenced by a `front 46` banner in `tokens.bp`
      and appended after front 45's block.
- [ ] `Token.InteractAccent`, `Token.InteractCaret` and `Token.InteractScrollbarColor` exist as
      top-level variants with `string` fields, in the same banner.
- [ ] `interactTokenToCss` and its sub-dispatchers are fenced by a `front 46` banner in `emilia.bp`,
      appended after front 45's block, and take `th: Theme` per contract `§ 4a`.
- [ ] Four arms added to `tokenToSheet`, each a `declSheet(...)` call, in front-number order, and no
      other line of that `case` moved.
- [ ] No hex literal and no `rem` literal appears in this front's block or tests.
- [ ] The snap fallback and the `paletteVar` rule are stated in the `tokens.bp` docblock, not only
      here.
- [ ] `repository/emilia/AGENTS.md` records the new section and both notes.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.

## Carried from 1.0.8-beta F12 emilia-interactivity

Everything below was in the 1.0.8 draft and is not stated above. Where the 1.0.10 text supersedes
the old value the old value is still quoted, marked as superseded, so the change is visible rather
than silent.

**`accent-auto`** — complements Step 2; missing because 1.0.10 collapsed the whole `AccentColor`
section into the payload variant `Token.InteractAccent(value)` and lost the one keyword leaf. The
1.0.8 draft declared `AccentColor { Auto, … }`, i.e. the Tailwind utility `accent-auto` →
`accent-color:auto`. A payload carrying `paletteVar(...)` cannot express a keyword; if the leaf is
wanted it is a section leaf (`.Interact.Accent.Auto` → `accent-color:auto`) beside the payload
variant, or `Token.InteractAccent(value: "auto")`.

**The `16` step of the scroll-offset scales** — complements Step 4; missing because the 1.0.10 scale
was pinned to `{0, 1, 2, 4, 8}`. The 1.0.8 draft declared
`ScrollMargin { 0, 1, 2, 4, 8, 16 }`, `ScrollMarginX`, `ScrollMarginY`, `ScrollPadding { 0, 1, 2, 4, 8, 16 }`,
`ScrollPaddingX`, `ScrollPaddingY` (the axis sections marked `/* same */`). Under contract `§ 4a`
the missing rows would read `.Interact.Scroll.M.16` → `scroll-margin:calc(var(--spacing) * 16)`,
`.Interact.Scroll.P.16` → `scroll-padding:calc(var(--spacing) * 16)`, and so on per side. The old
draft had no per-side sub-sections (`Mt`/`Mr`/`Mb`/`Ml`, `Pt`/`Pr`/`Pb`/`Pl`); 1.0.10 adds them.

**The 1.0.8 palette-leaf colour sections** — complements Step 2, Step 5 and *Reconciled with
front 33*; **superseded** by the top-level payload variants, kept so the shape that was rejected is
on record:

```bp
AccentColor {
    Auto,
    Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Blue { /* same */ }
    Green { /* same */ }
    Gray { /* same */ }
    White,
    Black,
}
CaretColor {
    Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Blue { /* same */ }
    Green { /* same */ }
    Gray { /* same */ }
    White,
    Black,
}
```

The 1.0.10 form is `Token.InteractAccent(value: paletteVar("blue", 500))` →
`accent-color:var(--color-blue-500)` and `Token.InteractCaret(value: paletteVar("red", 500))` →
`caret-color:var(--color-red-500)`. `White`/`Black` go through the same payload with front 33's
`paletteVar("white", …)`/`paletteVar("black", …)` spelling, whatever front 33 settles on.

**The 1.0.8 section spellings** — complements Steps 1–6; missing because 1.0.10 regrouped them.
Old → new: `Cursor.Default` → `.Interact.Cursor.Standard` (keyword clash); `ScrollBehavior` →
`.Interact.Scroll.Behavior`; `ScrollbarWidth` → `.Interact.Scrollbar.Width`; `ScrollbarGutter` →
`.Interact.Scrollbar.Gutter`; `ScrollMargin*`/`ScrollPadding*` → `.Interact.Scroll.M`/`Mx`/`My`/
`P`/`Px`/`Py`; `SnapAlign`/`SnapStop`/`SnapType`/`SnapStrictness` → `.Interact.Snap.Align`/`Stop`/
`Type`/`Strictness`; `TouchAction` → `.Interact.Touch`; `UserSelect` → `.Interact.Select`. Numeric
leaves were written `__N` (`Interact.AccentColor.Blue.__500`).

**The 1.0.8 acceptance list** — complements Steps 1–6; every bullet but the two hex ones is covered
above, and the two hex ones are **superseded** by `paletteVar`:

- [ ] `Interact.Cursor.Pointer` → `cursor:pointer`
- [ ] `Interact.Cursor.NotAllowed` → `cursor:not-allowed`
- [ ] `Interact.PointerEvents.None` → `pointer-events:none`
- [ ] `Interact.Resize.Y` → `resize:vertical`
- [ ] `Interact.ScrollBehavior.Smooth` → `scroll-behavior:smooth`
- [ ] `Interact.ScrollbarWidth.Thin` → `scrollbar-width:thin`
- [ ] `Interact.SnapType.X` → `scroll-snap-type:x var(--tw-scroll-snap-strictness)`
- [ ] `Interact.SnapAlign.Center` → `scroll-snap-align:center`
- [ ] `Interact.TouchAction.None` → `touch-action:none`
- [ ] `Interact.UserSelect.None` → `user-select:none`
- [ ] `Interact.WillChange.Transform` → `will-change:transform`
- [ ] `Interact.Appearance.None` → `appearance:none`
- [ ] `Interact.AccentColor.Blue.__500` → `accent-color:#3b82f6` — **superseded**: `Token.InteractAccent(value: paletteVar("blue", 500))` → `accent-color:var(--color-blue-500)`; `#3b82f6` is what the theme entry resolves to
- [ ] `Interact.CaretColor.Red.__500` → `caret-color:#ef4444` — **superseded**: `Token.InteractCaret(value: paletteVar("red", 500))` → `caret-color:var(--color-red-500)`; `#ef4444` is what the theme entry resolves to
- [ ] `Interact.FieldSizing.Content` → `field-sizing:content`

**Dependency as first drafted** — complements the header. The 1.0.8 draft read
`Depends on: F15 (modifiers)` (front 34 today); 1.0.10 depends on 33 (palette) instead.

**Gate** — complements *Test plan* and *Definition of done*; covered above, old wording kept:

- [ ] `botopink test` green on commonJS and erlang
- [ ] Every new token mapped to the correct CSS

**Blast radius** — no 1.0.10 counterpart; the section was dropped in the rewrite:

- `tokens.bp`: +~120 lines
- `emilia.bp`: +~180 lines
- `test/interactivity_test.bp`: new file, ~30 tests

**Test names in the 1.0.8 example** — complements *Test plan*; the 1.0.10 example has no inline
`test` blocks. The old file asserted with `styles.indexOf("<css>") != -1` after `await flush()`
under these names: `"cursor-pointer generates correct CSS"`, `"cursor-not-allowed generates correct CSS"`,
`"pointer-events-none generates correct CSS"`, `"resize-y generates correct CSS"`,
`"scroll-behavior-smooth generates correct CSS"`, `"scrollbar-width-thin generates correct CSS"`,
`"snap-align-center generates correct CSS"`, `"snap-type-x generates correct CSS"` (asserted
`scroll-snap-type:x`), `"touch-action-none generates correct CSS"`, `"user-select-none generates correct CSS"`,
`"will-change-transform generates correct CSS"`, `"appearance-none generates correct CSS"`,
`"field-sizing-content generates correct CSS"`.

Examples carried:
- [`./examples/interactivity-example-1.0.8.bp`](./examples/interactivity-example-1.0.8.bp) — the 1.0.8 file, kept beside the 1.0.10 rewrite because the two differ (`cmp`); it uses the flat 1.0.8 section names (`.Interact.ScrollBehavior.Smooth`, `.Interact.SnapType.X`, `.Interact.AccentColor.Blue.__500`) and is reference material, not a build target.
