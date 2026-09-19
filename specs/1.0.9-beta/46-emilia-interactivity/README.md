# Front 46 — emilia interactivity

**Track:** D emilia
**Priority:** medium — twenty CSS properties that decide whether a page can be dragged, scrolled, selected or clicked, and `emilia` has a token for none of them
**Target:** comptime
**Wave:** 1
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

**Colours are payloads, not a second palette.** `§ 17.1`, `§ 17.3` and `§ 17.10` give only HTML
examples — `accent-indigo-600`, `caret-red-500`, `scrollbar-thumb-red-500` — and no property/value
rows. The property comes from the subsection heading (`accent-color`, `caret-color`,
`scrollbar-color`); the value is a palette colour, and the palette belongs to front 33. Duplicating
twenty-two colour families inside `Interact` would make this front conflict with front 33 on every
future palette change, which the ownership table exists to prevent. Instead the three tokens take
the colour as a string payload — `Interact.Accent(value: string)` — the same shape
`Color.Hex(value: string)` already uses. A developer writes `accent("#4f46e5")`, or passes whatever
hex accessor front 33 exposes. **This is the one assumption in this front that another front could
contradict:** if front 33 ships a `Token`-valued colour type that other sections are expected to
embed, this front's three payload leaves should take that instead of a string.

**Scroll offsets derive from the spacing base.** `§ 17.13` and `§ 17.14` give `scroll-m-0`,
`scroll-mt-4` → `scroll-margin-top: calc(var(--spacing) * 4)` and write the two axis rows with their
values elided (`scroll-margin-left: ...; scroll-margin-right: ...`). The elision is filled by the
per-side row in the same table — both sides get `calc(var(--spacing) * N)` — and the step set is
`{0, 1, 2, 4, 8}`, the same steps `Pad` and `Margin` already use. `calc(var(--spacing) * N)` is
emitted verbatim rather than resolved to a `rem` literal, because `§ 17.13` writes it that way and
`--spacing` is one variable a stylesheet is likely to define even without a full theme.

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
- [ ] `tokensToCss([.Interact.Cursor.Standard])` returns `cursor:default`.
- [ ] Every kebab-case value keeps its hyphens: `not-allowed`, `nesw-resize`, `zoom-out`.

### Step 2 — the form-control properties

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `appearance-none` | `.Interact.Appearance.None` | `appearance:none` |
| `appearance-auto` | `.Interact.Appearance.Auto` | `appearance:auto` |
| `field-sizing-fixed` | `.Interact.FieldSizing.Fixed` | `field-sizing:fixed` |
| `field-sizing-content` | `.Interact.FieldSizing.Content` | `field-sizing:content` |
| `accent-indigo-600` | `Token.Interact.Accent(value: v)` | `accent-color:<v>` |
| `caret-red-500` | `Token.Interact.Caret(value: v)` | `caret-color:<v>` |
| `color-scheme-normal` | `.Interact.ColorScheme.Normal` | `color-scheme:normal` |
| `color-scheme-light` | `.Interact.ColorScheme.Light` | `color-scheme:light` |
| `color-scheme-dark` | `.Interact.ColorScheme.Dark` | `color-scheme:dark` |
| `color-scheme-light-dark` | `.Interact.ColorScheme.LightDark` | `color-scheme:light dark` |
| `color-scheme-only-dark` | `.Interact.ColorScheme.OnlyDark` | `color-scheme:only dark` |
| `color-scheme-only-light` | `.Interact.ColorScheme.OnlyLight` | `color-scheme:only light` |

`accent-color` and `caret-color` take a payload for the reason stated under *Mechanism*: the palette
belongs to front 33 and this front does not copy it.

**Acceptance:**
- [ ] `.Interact.ColorScheme.LightDark` returns `color-scheme:light dark` — one space, two words.
- [ ] `Token.Interact.Accent(value: "#4f46e5")` returns `accent-color:#4f46e5`.
- [ ] The `tokens.bp` docblock records that a future front 33 colour type supersedes the string
      payload if one lands.

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
- [ ] `tokensToCss([.Interact.Resize.Y])` returns `resize:vertical`, not `resize:y`.
- [ ] `tokensToCss([.Interact.WillChange.Scroll])` returns `will-change:scroll-position`.
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
- [ ] `tokensToCss([.Interact.Scroll.Mt.4])` returns `scroll-margin-top:calc(var(--spacing) * 4)` —
      spaces around the `*` kept.
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
| `scrollbar-thumb-red-500 scrollbar-track-gray-200` | `Token.Interact.Scrollbar.Color(thumb: t, track: k)` | `scrollbar-color:<t> <k>` |

`scrollbar-color` is one CSS property taking two colours, and upstream it is two classes. A token
per class would mean two `scrollbar-color:` declarations and the second winning, so this front makes
it one leaf with two payload fields — the shape `docs.md:246` (`Node(left: …, right: …)`) shows is
legal. The two fields are read by their declared names, which is required: a payload is projected by
field name, and an arbitrary positional bind type-checks and is `undefined` at run time.

**Acceptance:**
- [ ] `Token.Interact.Scrollbar.Color(thumb: "#ef4444", track: "#e5e7eb")` returns
      `scrollbar-color:#ef4444 #e5e7eb` — one space between them.
- [ ] The `case` arm destructures as `Color(thumb, track)`, matching the declared field names.
- [ ] `.Interact.Scrollbar.Gutter.StableBothEdges` returns `scrollbar-gutter:stable both-edges`.

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

**This is the one `--tw-*` chain in my fronts that works.** `snap-x` reads
`var(--tw-scroll-snap-strictness)` and `snap-mandatory` writes it, and `emilia` puts both
declarations in the *same* rule body — so a list containing `.Interact.Snap.Type.X` and
`.Interact.Snap.Strictness.Mandatory` produces a class where the variable resolves. Front 42's
filter chain and front 45's transform chain fail because each utility needs its own declaration to
survive alongside the others; this one works because the writer and the reader are different
properties. The contract is: **a `Snap.Type` token is only correct in a list that also carries a
`Snap.Strictness` token**, and the test file asserts both the working pair and the lone
`Snap.Type.X` with the variable unresolved.

**Acceptance:**
- [ ] `tokensToCss([.Interact.Snap.Type.X, .Interact.Snap.Strictness.Mandatory])` returns
      `scroll-snap-type:x var(--tw-scroll-snap-strictness);--tw-scroll-snap-strictness:mandatory`.
- [ ] `snap-align-none` maps to `Snap.Align.None` and `snap-none` to `Snap.Type.None` — two
      different properties whose class names differ by one word, asserted adjacently.
- [ ] The pairing contract is stated in the `tokens.bp` docblock.

### Step 7 — one new arm in `tokenToCss`

```bp
        Interact(_inner) -> interactTokenToCss(_inner);
```

**Acceptance:**
- [ ] The arm sits between front 45's arm and front 47's two, in front-number order.
- [ ] `tokenToCss` still has no `_` arm.

## Examples

- [`./examples/interactivity-example.bp`](./examples/interactivity-example.bp) — the whole
  `Interact` catalogue, the snap pairing shown as working code, then a horizontal image carousel
  that snaps, a drag handle that changes cursor while held, and a non-interactive overlay.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A dot-shorthand path ending in a payload call does not propagate the typed-array context, so `[.Interact.Accent("#4f46e5")]` trips the parser | `Interact.Accent`, `Interact.Caret`, `Interact.Scrollbar.Color` — the three colour-carrying leaves, which is the only way this front takes a colour | wrap the constructor in a fn (`fn accent(v: string) -> Token { return Token.Interact.Accent(value: v); }`) or bind a typed `val` first — the workaround `repository/emilia/src/emilia.bp:498-503` documents for `Color.Hex` | let a leading-dot path carry a payload call inside a typed array literal: `val ts: Token[] = [.Interact.Accent("#4f46e5")];` |

## Assumptions another front can contradict

`Interact.Accent`, `Interact.Caret` and `Interact.Scrollbar.Color` take a colour as a `string`
payload. This front does not reach into front 33's palette, because duplicating it would make the
two fronts conflict on every palette change. If front 33 ships a colour type meant to be embedded by
other sections, these three leaves should take that type instead and this README's Step 2 and Step 5
tables change accordingly. The coordinator should check this against front 33 before either lands.

## Test plan

`repository/emilia/test/interactivity_test.bp`, run by `botopink test` from `repository/emilia/` and
by `zig build test-libs` on both `commonJS` and `erlang`. `emilia` is comptime-only surface — it
emits a string — so both rows run the same assertions and a divergence is a bug, not a coverage gap.

What the tests assert:

1. **Every leaf, individually.** One `assert tokensToCss([<token>]) == "<css>"` per row of the six
   tables, and one per step of each of the twelve scroll-offset sub-sections. This is the largest
   test file in track D and it is almost entirely transcription checking, which is the right shape
   for a front whose risk is transcription.
2. **The three names that do not match their values.** `resize-y` → `vertical`, `resize-x` →
   `horizontal`, `will-change-scroll` → `scroll-position`, asserted in three adjacent lines with a
   comment saying the class name lies.
3. **`snap-none` versus `snap-align-none`.** Two properties, class names one word apart, asserted
   adjacently.
4. **The snap pairing.** One test for the working pair (variable written and read in one rule) and
   one for the lone `Snap.Type.X`, asserting the unresolved `var(…)` is present — the second test
   documents the sharp edge rather than hiding it.
5. **The axis scroll offsets.** `Mx.4` and `My.4` asserted whole, so the two-declaration order is
   pinned; swapping left and right inside one declaration is invisible otherwise.
6. **The `0` steps.** `Scroll.M.0` and `Scroll.P.0` emit a bare `0`, so a refactor that runs every
   step through one `calc(…)` template fails here.
7. **Modifier nesting.** `Token.Hover([.Interact.Cursor.Grabbing])` wraps as
   `:hover{cursor:grabbing}`, and the carousel example's full token list round-trips through
   `emilia()` and `await flush()` to a literal `<style>` string.
8. **Determinism across targets.** The class name for a fixed `Token[]` is asserted as a literal, so
   `commonJS` and `erlang` must agree on the `djb2` hash. Every value here is ASCII, the condition
   `emilia.bp:32-37` states for the two hashes to match.

## Definition of done

- [ ] `Interact` exists as a top-level section with `Cursor`, `Appearance`, `FieldSizing`, `Accent`,
      `Caret`, `ColorScheme`, `PointerEvents`, `Resize`, `Select`, `WillChange`, `Touch`, `Scroll`,
      `Scrollbar`, `Snap`, fenced by a `front 46` banner in `tokens.bp` and appended after front 45's
      block.
- [ ] `interactTokenToCss` and its sub-dispatchers are fenced by a `front 46` banner in `emilia.bp`,
      appended after front 45's block.
- [ ] One arm added to `tokenToCss`, in front-number order, and no other line of that `case` moved.
- [ ] The snap pairing contract and the colour-payload assumption are stated in the `tokens.bp`
      docblock, not only here.
- [ ] `repository/emilia/AGENTS.md` records the new section and both notes.
- [ ] The front's tests are green on its assigned target — here, both `commonJS` and `erlang`,
      because comptime output must not differ between them.
