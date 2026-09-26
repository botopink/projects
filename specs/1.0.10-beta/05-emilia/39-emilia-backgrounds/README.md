# Front 39 — emilia-backgrounds

**Track:** D emilia
**Priority:** high — `Bg` today can set a colour and nothing else. No image, no gradient, no size, no position, no repeat: every hero, every card overlay and every progress bar in real Tailwind markup uses at least one of them.
**Target:** comptime — `emilia` runs at comptime and emits a CSS string. It is neither erlang- nor js-specific, and this front compiles for neither target in particular.
**Wave:** 3
**Depends on:** 33 (`Gradient` stops are palette entries and go through `paletteVar`), 54 (the `Theme` parameter every sub-dispatcher takes), 56 (`declSheet` — this front emits declarations only, no selector)
**Owns:** `repository/emilia/src/tokens.bp` (the non-colour sub-sections of `Bg`, and the new `Gradient` section) · `repository/emilia/src/emilia.bp` (`bgTokenToCss` and its sub-dispatchers, `gradientTokenToCss`) · `repository/emilia/test/backgrounds_test.bp`
**Does not touch:** `Bg.Color` — front 33 owns the colour grid on `background-color`; the legacy `Bg.Red`/`Bg.Blue`/`Bg.Gray`/`Bg.White`/`Bg.Black`/`Bg.Hex` leaves, which front 33 keeps working unchanged
**Reference:** `TAILWIND_CSS_DOCS.md § 10. Backgrounds` (10.1–10.8) · https://tailwindcss.com/docs/background-attachment

---

## Problem

`Bg` (`tokens.bp:118-138`) is a colour section and nothing else: three families, `White`, `Black`
and an unconstructible `Hex`. `§ 10` has eight property groups and emilia covers one of them,
partially.

There is no `background-image`, so a gradient — the single most-used non-colour background in
Tailwind markup — cannot be expressed. There is no `background-size`, so a hero image cannot cover
its box; no `background-position`, so it cannot be anchored; no `background-repeat`, so a texture
cannot tile on one axis; no `background-attachment`, so nothing can be fixed; no `background-clip`,
so the `bg-clip-text` gradient-text idiom is impossible; no `background-origin`.

`bgTokenToCss` (`emilia.bp:169-179`) also emits the wrong property: `background:red`, the shorthand,
where `§ 10.3` sets `background-color`. Using the shorthand means any background *colour* token
silently resets every other background property set beside it — a gradient followed by a colour
would lose the gradient. Front 33 fixes that for the new `Bg.Color` grid; this front is the reason
it matters.

## Current state

| What | Where | State |
|---|---|---|
| `Bg { Red{100,500,700}, Blue{100,500,700}, Gray{100,200,500,900}, White, Black, Hex(value) }` | `tokens.bp:118-138` | colour only |
| `bgTokenToCss` | `emilia.bp:169-179` | emits the `background` shorthand; discards the shade |
| attachment, clip, origin, position, repeat, size, image | — | no tokens |
| gradients | — | no tokens |

## Mechanism

`Bg` gains one sub-section per `§ 10` property group, appended under this front's banner beside
front 33's `Bg.Color` block. Both fronts write into the same `Bg { … }` braces, which is the one
place in track D where two fronts share a section rather than a file. It is safe because front 33 is
wave 0 and this front is wave 1: by the time this block is appended, `Bg.Color` is already there and
the diff is additive at the end of the section.

Gradients are their own top-level section rather than a sub-section of `Bg`, for two reasons. The
stop colours (`from-*`, `via-*`, `to-*`) are not `background-image` at all — they are custom
properties the gradient reads — so nesting them under `Bg.Image` would put three properties under
one name. And a stop is a four-segment path already (`.Gradient.From.Indigo.500`); nesting it one
deeper would make it five for no gain.

Every declaration in this front is a plain declaration with no selector, so each sub-dispatcher
keeps the `fn <name>(t: Token.Bg.<Sub>, th: Theme) -> string` shape contract 4a in
[`contracts.md`](../../contracts.md) prescribes, and front 56's `declSheet` adapts it. This front adds
no `…TokenToSheet` variant.

The stop colours go through front 33's `paletteVar` — itself a wrapper over front 54's `themeVar` —
so `from-indigo-500` and `bg-indigo-500` reference the same custom property by construction rather
than by two transcriptions agreeing.

## Token surface

### Attachment, clip, origin — `§ 10.1`, `§ 10.2`, `§ 10.5`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `bg-fixed` | `.Bg.Attachment.Fixed` | `background-attachment:fixed` |
| `bg-local` | `.Bg.Attachment.Local` | `background-attachment:local` |
| `bg-scroll` | `.Bg.Attachment.Scroll` | `background-attachment:scroll` |
| `bg-clip-border` | `.Bg.Clip.Border` | `background-clip:border-box` |
| `bg-clip-padding` | `.Bg.Clip.Padding` | `background-clip:padding-box` |
| `bg-clip-content` | `.Bg.Clip.Content` | `background-clip:content-box` |
| `bg-clip-text` | `.Bg.Clip.Text` | `background-clip:text` |
| `bg-origin-border` | `.Bg.Origin.Border` | `background-origin:border-box` |
| `bg-origin-padding` | `.Bg.Origin.Padding` | `background-origin:padding-box` |
| `bg-origin-content` | `.Bg.Origin.Content` | `background-origin:content-box` |

### Position — `§ 10.6`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `bg-bottom` | `.Bg.Pos.Bottom` | `background-position:bottom` |
| `bg-center` | `.Bg.Pos.Center` | `background-position:center` |
| `bg-left` | `.Bg.Pos.Left` | `background-position:left` |
| `bg-left-bottom` | `.Bg.Pos.LeftBottom` | `background-position:left bottom` |
| `bg-left-top` | `.Bg.Pos.LeftTop` | `background-position:left top` |
| `bg-right` | `.Bg.Pos.Right` | `background-position:right` |
| `bg-right-bottom` | `.Bg.Pos.RightBottom` | `background-position:right bottom` |
| `bg-right-top` | `.Bg.Pos.RightTop` | `background-position:right top` |
| `bg-top` | `.Bg.Pos.Top` | `background-position:top` |

The sub-section is `Pos`, not `Position`, so that `.Bg.Pos.*` stays four segments and reads
differently from `.Layout.Position.*` — two different properties that Tailwind spells with the same
English word.

### Repeat and size — `§ 10.7`, `§ 10.8`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `bg-repeat` | `.Bg.Repeat.Repeat` | `background-repeat:repeat` |
| `bg-no-repeat` | `.Bg.Repeat.None` | `background-repeat:no-repeat` |
| `bg-repeat-x` | `.Bg.Repeat.X` | `background-repeat:repeat-x` |
| `bg-repeat-y` | `.Bg.Repeat.Y` | `background-repeat:repeat-y` |
| `bg-repeat-round` | `.Bg.Repeat.Round` | `background-repeat:round` |
| `bg-repeat-space` | `.Bg.Repeat.Space` | `background-repeat:space` |
| `bg-auto` | `.Bg.Size.Auto` | `background-size:auto` |
| `bg-cover` | `.Bg.Size.Cover` | `background-size:cover` |
| `bg-contain` | `.Bg.Size.Contain` | `background-size:contain` |

`.Bg.Repeat.None` rather than `.Bg.Repeat.NoRepeat`: the CSS value keeps its `no-` prefix, the token
does not repeat the word.

### Image and gradient direction — `§ 10.4`

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `bg-none` | `.Bg.Image.None` | `background-image:none` |
| `bg-gradient-to-t` | `.Gradient.To.T` | `background-image:linear-gradient(to top, var(--tw-gradient-stops))` |
| `bg-gradient-to-tr` | `.Gradient.To.Tr` | `background-image:linear-gradient(to top right, var(--tw-gradient-stops))` |
| `bg-gradient-to-r` | `.Gradient.To.R` | `background-image:linear-gradient(to right, var(--tw-gradient-stops))` |
| `bg-gradient-to-br` | `.Gradient.To.Br` | `background-image:linear-gradient(to bottom right, var(--tw-gradient-stops))` |
| `bg-gradient-to-b` | `.Gradient.To.B` | `background-image:linear-gradient(to bottom, var(--tw-gradient-stops))` |
| `bg-gradient-to-bl` | `.Gradient.To.Bl` | `background-image:linear-gradient(to bottom left, var(--tw-gradient-stops))` |
| `bg-gradient-to-l` | `.Gradient.To.L` | `background-image:linear-gradient(to left, var(--tw-gradient-stops))` |
| `bg-gradient-to-tl` | `.Gradient.To.Tl` | `background-image:linear-gradient(to top left, var(--tw-gradient-stops))` |

### Gradient stops

`§ 10.4` shows `from-indigo-500 via-purple-500 to-pink-500` in markup and prints no CSS for the
three stop utilities — see *Reference gaps*. The shape below is the one the `var(--tw-gradient-stops)`
reference in the same table implies, and it must be checked against upstream before merge.

| Tailwind utility | emilia token | CSS emitted |
|---|---|---|
| `from-indigo-500` | `.Gradient.From.Indigo.500` | `--tw-gradient-from:var(--color-indigo-500);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to)` |
| `from-transparent` | `.Gradient.From.Transparent` | `--tw-gradient-from:transparent;--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to)` |
| `via-purple-500` | `.Gradient.Via.Purple.500` | `--tw-gradient-via:var(--color-purple-500);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-via), var(--tw-gradient-to)` |
| `to-pink-500` | `.Gradient.Stop.Pink.500` | `--tw-gradient-to:var(--color-pink-500)` |
| `to-transparent` | `.Gradient.Stop.Transparent` | `--tw-gradient-to:transparent` |

The terminal stop is `Stop`, not `To`, because `.Gradient.To.*` is already the direction. That is a
deliberate divergence from Tailwind's naming, where `bg-gradient-to-r` and `to-pink-500` share the
word `to` while setting unrelated things; the README says so rather than letting a reader discover
it.

Every family and shade front 33 declares is available on all three stops, plus `White`, `Black`,
`Transparent`, `Current` and `Inherit`.

## Steps

### Step 1 — the six keyword sub-sections

`Attachment`, `Clip`, `Origin`, `Pos`, `Repeat`, `Size`, plus `Image.None`. All keyword leaves, one
declaration each.

**Acceptance:**
- [x] all three attachment values, four clip values, three origin values — held: tests `background-attachment — the three values of § 10.1`, `background-clip — the four values…`, `background-origin — the three values…`
- [x] all nine positions, with the four two-word values carrying exactly one space — held: `background-position — each two-word value carries exactly one space and no hyphen`
- [x] all six repeat values; `.Bg.Repeat.None` emits `no-repeat` — held: `background-repeat — the six values of § 10.7, None spelling no-repeat`
- [x] three size values — held: `background-size — the three values of § 10.8…`
- [x] `.Bg.Image.None` emits `background-image:none` — held: `background-image — bg-none is the one non-gradient row of § 10.4`
- [x] `.Bg.Pos.*` and `.Layout.Position.*` are distinct paths and neither shadows the other — held: `background-position — .Bg.Pos and .Layout.Position are two properties`
- [x] the legacy `.Bg.White` path still emits `background:#ffffff`, and `emilia.bp:419-421` passes
      untouched — held (shape: the `emilia.bp:419-421` cite is stale; pinned by `the legacy Bg leaves are byte-identical after this front`)

### Step 2 — gradient direction

```bp
    Gradient {
        To { T, Tr, R, Br, B, Bl, L, Tl }
    }
```

One fn builds the whole declaration from the direction phrase, so adding a direction is one arm.

**Acceptance:**
- [x] all eight directions emit `linear-gradient(<phrase>, var(--tw-gradient-stops))` with the
      phrase exactly as `§ 10.4` prints it — `to top right`, not `to top-right` — held: `gradient direction — the eight phrases of § 10.4`, `…a corner is two keywords, not a hyphenated one`
- [x] one space after the comma — held: `gradient direction — exactly one space after the comma, on all eight`
- [x] the direction phrases are spelled in exactly one place — held: `emilia.bp:gradientToTokenToCss` (+ `linearGradient`)

### Step 3 — gradient stops

```bp
        From  { Red { 50, …, 950 } … White, Black, Transparent, Current, Inherit }
        Via   { … }
        Stop  { … }
```

The colour half of each stop is `paletteVar(family, shade)` from front 33. This front holds no
colour table.

**Acceptance:**
- [x] `.Gradient.From.Indigo.500` and `.Bg.Color.Indigo.500` reference the same custom property,
      asserted by comparing the substring `var(--color-indigo-500)` in both outputs — held: `gradient stops — the stop and the background read ONE custom property`
- [x] `From` sets `--tw-gradient-from` and the two-stop `--tw-gradient-stops` — held (shape: the terminal reference carries a `var(--tw-gradient-to, transparent)` fallback for upstream's `@property` default, per emilia AGENTS.md front 39): `gradient stops — From sets its colour and the two-stop list`
- [x] `Via` sets `--tw-gradient-via` and the three-stop `--tw-gradient-stops` — held (shape: `from`/`to` references carry the `transparent` fallback): `gradient stops — Via sets its colour and the three-stop list`
- [x] `Stop` sets `--tw-gradient-to` only — held: `gradient stops — Stop sets the terminal colour AND NOTHING ELSE`
- [x] a `From` + `Via` + `Stop` triple composes in one class body, with `Via`'s three-stop list
      overriding `From`'s two-stop list because it is listed after it — which makes token order
      load-bearing, exactly as contract 4 in [`contracts.md`](../../contracts.md) requires — held: `gradient stops — From + Via + Stop composes, and order is load-bearing`, `…reversing the two lists reverses which one wins`
- [x] the custom-property names are checked against upstream before merge — see *Reference gaps* — held: names verified, composition simplified after the check (note above `emilia.bp:gradientFromVar`; AGENTS.md front 39 row)

### Step 4 — the dispatchers and the top-level arm

`bgTokenToCss` gains one arm per new sub-section and keeps its six legacy arms and front 33's
`Color` arm. `gradientTokenToCss` is new, with three sub-dispatchers. One arm is added to the
top-level `case` for `Gradient`; `Bg` already has one.

**Acceptance:**
- [x] every arm is an arrow arm, and each dispatcher follows the `val out = case …; return out;` idiom — held: `emilia.bp` front 39 block (`bgTokenToCss` arms, `gradientTokenToCss` and sub-dispatchers)
- [x] each sub-dispatcher has the `(t, th: Theme) -> string` shape front 56's `declSheet` adapts;
      this front emits no selector and adds no `…TokenToSheet` — held: every `bg*TokenToCss`/`gradient*TokenToCss` is `(…, th: Theme) -> string`; no `…TokenToSheet`
- [x] the banner `// ── front 39 — backgrounds ──` fences this front's block in both files — held: `tokens.bp` (inside `Bg`, before `Gradient`) and `emilia.bp` (`bgTokenToCss` arms, `tokenToSheet` arm, main block)
- [x] the `Bg` sub-sections are appended after front 33's `Bg.Color` block, not interleaved with it — held: `tokens.bp` `Bg` — after `Color` and the legacy leaves
- [ ] one arm added to the top-level `tokenToCss` / `tokenToSheet` case, in front-number order — **open:** the `Gradient` arm sits after front 45's arms in `tokenToSheet`, not between front 38's and front 40's

## Examples

- `./examples/backgrounds-example.bp` — attachment, clip, origin, position, repeat, size and
  `bg-none`; ends with a hero panel whose photograph covers and is anchored to the top.
- `./examples/gradients-example.bp` — the eight directions and the three stops across families;
  ends with a gradient call-to-action and a gradient-text heading built with `bg-clip-text`.

## Language gaps

None — every construct in this front's examples parses today. The one shape worth naming is that a
gradient stop is a four-segment path (`.Gradient.From.Indigo.500`), which resolves; the deepest path
used here is four, one shallower than front 36's. The general gap that a payload leaf inside a
section cannot be constructed is recorded once in
[`language-gaps.md`](../../language-gaps.md) and does not bite this front, which declares no payload
leaf.

## Reference gaps

`TAILWIND_CSS_DOCS.md` does not carry these. Nothing below may be trusted from this spec; each must
be checked against upstream before implementation.

| Item | Why it is missing | What implementation must do |
|---|---|---|
| `from-*`, `via-*`, `to-*` | `§ 10.4` shows them in markup and prints no CSS | verify `--tw-gradient-from`, `--tw-gradient-via`, `--tw-gradient-to` and the `--tw-gradient-stops` composition against upstream `tailwindcss.com/docs/background-image#adding-color-stops`; this spec's shape is inferred from the `var(--tw-gradient-stops)` reference in `§ 10.4`'s own table |
| Colour-stop **positions** (`from-10%`, `via-30%`, `to-90%`) | absent entirely | not declared by this front; they need a second numeric level under each stop and should land with, or after, the upstream check above |
| **Radial and conic gradients** (`bg-radial`, `bg-radial-[…]`, `bg-conic`) | absent entirely — `§ 10.4` lists the eight linear directions and nothing else | not declared by this front. A radial gradient is a different function with a position argument; specifying it from memory would be guessing |
| **Gradient interpolation** (`bg-linear-to-r/oklch`, `/srgb`, `/longer`) | absent entirely | not declared by this front |
| `bg-[url(...)]` and every other arbitrary image | `§ 3.1` names arbitrary values generally; `§ 10.4` prints only `bg-none` | front 57's escape hatches |
| `bg-size-[…]`, `bg-position-[…]` | absent | front 57 |

Four of the six rows above are Tailwind features this front **cannot map to a token**, and the
reason in every case is the same: the local reference does not document them and this spec does not
invent CSS. They are named here so the coverage audit records a hole rather than a silence.

## Test plan

`repository/emilia/test/backgrounds_test.bp`, flat, bare-importing across `src`. Run with
`botopink test` from `repository/emilia` and under `zig build test-libs -- --lib emilia`.

emilia has no target split, so the suite runs on **both** backends: `botopink test` (commonJS) and
`botopink test --target erlang`. A gradient whose declaration differs between them is a string-
concatenation bug, since every value here is a literal or a `paletteVar` call.

What the tests assert:

1. **One test per keyword sub-section** — attachment, clip, origin, position, repeat, size.
2. **Two-word positions** — asserted individually, because a missing or doubled space is the failure
   mode a table transcription produces.
3. **`bg-clip-text`** — asserted on its own, because it is the one clip value that is not a `*-box`.
4. **Direction phrases** — eight asserts on the full `linear-gradient(...)` string.
5. **Stops** — `From` alone, `From` + `Stop`, `From` + `Via` + `Stop`, each asserting the
   `--tw-gradient-stops` list that results, and one assert that token order changes the output.
6. **Palette agreement** — `.Gradient.From.Indigo.500` and `.Bg.Color.Indigo.500` both contain
   `var(--color-indigo-500)`.
7. **The legacy `Bg` paths** — `.Bg.White` and `.Bg.Black` unchanged.
8. **End to end** — `emilia([.Gradient.To.R, .Gradient.From.Indigo.500, .Gradient.Stop.Pink.500])`
   then `await flush()`, asserting the whole `<style>` block.

## Definition of done

- [x] every utility in `§ 10.1`–`§ 10.8` that the reference documents has a token — held: `tokens.bp` `Bg.{Attachment,Clip,Origin,Pos,Repeat,Size,Image}` + `Gradient`; `regression — every one of the 910 leaves declares something`
- [x] the four undocumented gradient families are recorded in *Reference gaps*, not guessed at — held: this README's *Reference gaps*; AGENTS.md front 39 row
- [x] `Gradient` stops call front 33's `paletteVar`; this front holds no colour table — held: `emilia.bp:gradientFromTokenToCss`/`…Via…`/`…Stop…` call `paletteVar`
- [x] the eight direction phrases are spelled once — held: `emilia.bp:gradientToTokenToCss`
- [x] the legacy `Bg` leaves emit byte-identical CSS afterwards — held: `the legacy Bg leaves are byte-identical after this front`
- [x] the banner fences this front's block in both files, appended at the end — held: front 39 blocks close `Bg` and follow front 45 in `tokens.bp`; last block of `emilia.bp`
- [ ] one arm added to the top-level dispatcher, in front-number order — **open:** `Gradient` arm trails front 45's in `tokenToSheet`
- [x] `repository/emilia/AGENTS.md` and the `////` header of `tokens.bp` record the new sections — held: AGENTS.md front 39 row + § Test surface; `tokens.bp` header `Bg` and `Gradient` entries
- [x] the front's tests are green on its assigned target — here, both backends, since emilia is comptime — held: `modules/emilia` 569/569 on commonJS and erlang (AGENTS.md § Test surface); `examples/emilia-backgrounds`
