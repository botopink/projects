# test-snap — the snapshot-test map of the `emilia` modules

**Track:** D — emilia · **Repo:** `repository/emilia` · **Contract:** [`../01-std/snapshots.md`](../01-std/snapshots.md), [`../01-std/src-builtin.md`](../01-std/src-builtin.md), [`../01-std/asserts-api.md`](../01-std/asserts-api.md)

Preventive: written before the modules exist, so that every front lands with its snapshots and no
snapshot is ever accepted by a flag. Each test below is followed by the exact `.snap` file it
produces. Paths are relative to `repository/emilia/`.

## The contract

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime
```

- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`. `suite` is the text
  before the first `": "` of the test name; `slug` is the rest, lower-cased, every run of characters
  outside `[a-z0-9]` collapsed to one `-`, leading and trailing `-` trimmed. So
  `test "css: color ---- red 500 text"` in `modules/emilia/test/colors_test.bp` writes
  `modules/emilia/test/__snapshots__/css/color-red-500-text.snap`.
- A mismatch or a missing file writes `<path>.new` and fails the test. Nothing accepts a snapshot
  but a person renaming the `.new` file. There is no update flag.
- Every test file runs on `--target commonJS` **and** `--target erlang` against the **same** `.snap`
  file. A string that differs by backend is a red test, which is the point.

## The helpers (`modules/emilia-test/src/asserts.bp`)

```bp
pub fn assertCss(loc: SourceLocation, tokens: Token[]) -> @Result<void, string>
pub fn assertCssWith(loc: SourceLocation, tokens: Token[], th: Theme) -> @Result<void, string>
pub fn assertUtility(loc: SourceLocation, token: Token) -> @Result<void, string>
pub fn assertVariant(loc: SourceLocation, v: Variant) -> @Result<void, string>
pub fn assertTheme(loc: SourceLocation, th: Theme) -> @Result<void, string>
pub fn assertRules(loc: SourceLocation, rules: Rule[]) -> @Result<void, string>
pub fn assertCascade(loc: SourceLocation, lists: Token[][], o: Options) -> @Result<void, string>
pub fn assertClassName(loc: SourceLocation, tokens: Token[]) -> @Result<void, string>
```

| Helper | What the `.snap` holds |
|---|---|
| `assertCss` | `tokensToSheet(tokens, fullTheme())`, rendered as the utilities layer of one class whose name is fixed to `e`: rules with no at-rule first (stable), adjacent rules with equal `layer`/`atRules`/`selector`/`important` coalesced into one, each rendered rule on its own line, then each `Block` on its own line |
| `assertCssWith` | the same under `th` |
| `assertUtility` | the style AST of one token: one line per `Rule` — `layer \| atRules (outermost first, `, `-joined, `-` if none) \| selector \| declarations \| important` — then one line per `Block` — `block \| header \| body` |
| `assertVariant` | two lines: `atRule: <v.atRule>` and `selector: <v.selector>` |
| `assertTheme` | `themeCss(th)` split on `;`, one `name:value` per line, then each `@keyframes` block on its own line |
| `assertRules` | each `Rule` through `renderRule("", r, defaultOptions())`, one per line — for literal-selector rules |
| `assertCascade` | every list through `emiliaWith(list, o.theme)`, then `flushWith(o)` with `<style>`/`</style>` stripped, a newline after the `@layer …;` preamble and after every top-level `}`, and class names rewritten `e1 … eN` in registration order |
| `assertClassName` | one line: the literal `e_<hex>` of `emilia(tokens)` under `fullTheme()` — the contract 4 fixture |

Conventions in every test file: `import { Token, … } from "emilia";` and
`import { assertCss, … } from "emilia-test";`; `equal`/`contains` come from `std/asserts`. A
payload-carrying token (`Token.Hover(inner)`, `Token.Nth(index: 3, inner: xs)`, `Token.Alpha(…)`)
is bound to a typed `val` first — `[.Hover([...])]` inside an array literal does not parse
([`../language-gaps.md`](../language-gaps.md)). `try` unwraps the `@Result`.

Refusals (a `Variant` with two `&`, `extend` with an unknown prefix, `arbValue` with `}`) are build
failures, not values; each test file records them in a comment and they live in the compiler's suite.

---

## 33 — color palette · `modules/emilia/test/colors_test.bp`

```bp
import { Token, paletteVar, paletteEntries, defaultTheme, extend } from "emilia";
import { assertCss, assertUtility, assertTheme, assertClassName } from "emilia-test";
import { equal } from "std/asserts";

test "css: color ---- red 500 text" {
    try assertCss(@src(), [.Color.Red.500]);
}

test "css: color ---- slate 900 background with slate 50 text" {
    try assertCss(@src(), [.Bg.Color.Slate.900, .Color.Slate.50]);
}

test "css: color ---- keywords transparent current inherit" {
    try assertCss(@src(), [.Color.Transparent, .Bg.Color.Current, .Color.Inherit]);
}

test "css: color ---- taupe 950 is the last family and shade" {
    try assertCss(@src(), [.Color.Taupe.950, .Bg.Color.Taupe.50]);
}

test "css: color ---- alpha 50 over a background" {
    val inner: Token[] = [.Bg.Color.Red.500];
    val tokens: Token[] = [Token.Alpha(percent: 50, inner: inner)];
    try assertCss(@src(), tokens);
}

test "css: color ---- alpha rewrites both colours under it" {
    val inner: Token[] = [.Bg.Color.Blue.600, .Color.White];
    val tokens: Token[] = [Token.Alpha(percent: 80, inner: inner)];
    try assertCss(@src(), tokens);
}

test "css: color ---- alpha inside hover" {
    val inner: Token[] = [.Bg.Color.Red.500];
    val alpha: Token[] = [Token.Alpha(percent: 50, inner: inner)];
    val tokens: Token[] = [Token.Hover(alpha)];
    try assertCss(@src(), tokens);
}

test "ast: color ---- one declaration rule" {
    try assertUtility(@src(), .Color.Red.500);
}

test "theme: color ---- palette entries" {
    try assertTheme(@src(), extendTheme(emptyTheme(), paletteEntries()));
}

test "class: color ---- slate card" {
    try assertClassName(@src(), [.Bg.Color.Slate.900, .Color.Slate.50]);
}

test "palette var spells the theme reference" {
    equal(paletteVar("red", "500"), "var(--color-red-500)");
    equal(paletteEntries().length, 286);
}
```

`modules/emilia/test/__snapshots__/css/color-red-500-text.snap`
```css
.e{color:var(--color-red-500)}
```

`modules/emilia/test/__snapshots__/css/color-slate-900-background-with-slate-50-text.snap`
```css
.e{background-color:var(--color-slate-900);color:var(--color-slate-50)}
```

`modules/emilia/test/__snapshots__/css/color-keywords-transparent-current-inherit.snap`
```css
.e{color:transparent;background-color:currentColor;color:inherit}
```

`modules/emilia/test/__snapshots__/css/color-taupe-950-is-the-last-family-and-shade.snap`
```css
.e{color:var(--color-taupe-950);background-color:var(--color-taupe-50)}
```

`modules/emilia/test/__snapshots__/css/color-alpha-50-over-a-background.snap`
```css
.e{background-color:color-mix(in oklab, var(--color-red-500) 50%, transparent)}
```

`modules/emilia/test/__snapshots__/css/color-alpha-rewrites-both-colours-under-it.snap`
```css
.e{background-color:color-mix(in oklab, var(--color-blue-600) 80%, transparent);color:color-mix(in oklab, var(--color-white) 80%, transparent)}
```

`modules/emilia/test/__snapshots__/css/color-alpha-inside-hover.snap`
```css
@media (hover: hover){.e:hover{background-color:color-mix(in oklab, var(--color-red-500) 50%, transparent)}}
```

`modules/emilia/test/__snapshots__/ast/color-one-declaration-rule.snap`
```
utilities | - | & | color:var(--color-red-500) | false
```

`modules/emilia/test/__snapshots__/theme/color-palette-entries.snap` — 286 lines, one per
family × shade in the order `paletteEntries()` declares them (17 chromatic families then 9
neutral, 50 → 950 inside each). The two the front pins today, and the shape of the rest:
```
--color-red-50:oklch(0.971 0.013 17.38)
…
--color-red-500:oklch(0.637 0.237 25.331)
…
--color-blue-500:oklch(0.623 0.214 259.815)
…
--color-taupe-950:<value from tailwindcss/theme.css>
```
The remaining values are copied from upstream `theme.css` when 33 lands; the file is written once
and never regenerated by a flag.

`modules/emilia/test/__snapshots__/class/color-slate-card.snap`
```
e_<hex>
```
The literal is fixed the first time the test runs on `commonJS`; the `erlang` run must then match
it byte for byte. `<hex>` is written here as a placeholder only because the encoding it hashes
(56's `encodeSheet`) is what pins it.

---

## 34 — modifiers · `modules/emilia/test/modifiers_test.bp`

```bp
import { Token, hoverVariant, focusVariant, mdVariant, groupHoverVariant, rtlVariant, openVariant } from "emilia";
import { assertCss, assertVariant, assertUtility } from "emilia-test";

test "variant: modifiers ---- hover is media guarded" {
    try assertVariant(@src(), hoverVariant());
}

test "variant: modifiers ---- md is a width query" {
    try assertVariant(@src(), mdVariant());
}

test "variant: modifiers ---- group hover looks for the group class" {
    try assertVariant(@src(), groupHoverVariant());
}

test "variant: modifiers ---- rtl puts the class last" {
    try assertVariant(@src(), rtlVariant());
}

test "variant: modifiers ---- open is a selector list" {
    try assertVariant(@src(), openVariant());
}

test "css: modifiers ---- hover on md breakpoint" {
    val hovered: Token[] = [.Bg.Color.Red.500];
    val onMd: Token[] = [Token.Hover(hovered)];
    val tokens: Token[] = [Token.Md(onMd)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- breakpoint ladder" {
    val sm: Token[] = [.Text.Size.Sm];
    val md: Token[] = [.Text.Size.Base];
    val lg: Token[] = [.Text.Size.Lg];
    val xl: Token[] = [.Text.Size.Xl];
    val x2: Token[] = [.Text.Size.X2xl];
    val tokens: Token[] = [Token.Sm(sm), Token.Md(md), Token.Lg(lg), Token.Xl(xl), Token.X2xl(x2)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- max breakpoints" {
    val hidden: Token[] = [.Layout.Hidden];
    val tokens: Token[] = [Token.MaxSm(hidden), Token.MaxX2xl(hidden)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- dark inside md inside hover" {
    val bold: Token[] = [.Text.Bold];
    val h: Token[] = [Token.Hover(bold)];
    val m: Token[] = [Token.Md(h)];
    val tokens: Token[] = [Token.Dark(m)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- structural first last odd nth" {
    val zeroTop: Token[] = [.Pad.T.0];
    val zeroBottom: Token[] = [.Pad.B.0];
    val striped: Token[] = [.Bg.Color.Gray.50];
    val marked: Token[] = [.Text.Underline];
    val tokens: Token[] = [
        Token.First(zeroTop),
        Token.Last(zeroBottom),
        Token.Odd(striped),
        Token.Nth(index: 3, inner: marked),
        Token.NthLast(index: 5, inner: marked),
    ];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- pseudo elements before marker selection" {
    val star: Token[] = [.Text.Content.Empty, .Color.Red.500];
    val bullets: Token[] = [.Color.Sky.400];
    val picked: Token[] = [.Bg.Color.Fuchsia.300];
    val tokens: Token[] = [Token.Before(star), Token.Marker(bullets), Token.Selection(picked)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- hover before and before hover differ" {
    val red: Token[] = [.Color.Red.500];
    val b: Token[] = [Token.Before(red)];
    val h: Token[] = [Token.Hover(red)];
    val tokens: Token[] = [Token.Hover(b), Token.Before(h)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- group and peer" {
    val reveal: Token[] = [.Color.White];
    val warn: Token[] = [.Layout.Visibility.Visible];
    val tokens: Token[] = [Token.GroupHover(reveal), Token.PeerFocus(warn), Token.PeerChecked(warn)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- direction and descent" {
    val left: Token[] = [.Margin.L.3];
    val right: Token[] = [.Margin.R.3];
    val pill: Token[] = [.Border.Rounded.Full];
    val tokens: Token[] = [Token.Ltr(left), Token.Rtl(right), Token.Children(pill), Token.Descendants(pill)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- form states" {
    val muted: Token[] = [.Color.Gray.400];
    val bad: Token[] = [.Border.Color.Pink.500];
    val tokens: Token[] = [Token.Disabled(muted), Token.Invalid(bad), Token.PlaceholderShown(muted), Token.Open(muted), Token.Inert(muted)];
    try assertCss(@src(), tokens);
}

test "css: modifiers ---- print and motion" {
    val none: Token[] = [.Layout.Hidden];
    val still: Token[] = [.Transition.None];
    val tokens: Token[] = [Token.Print(none), Token.MotionReduce(still), Token.ForcedColors(none)];
    try assertCss(@src(), tokens);
}

test "ast: modifiers ---- hover carries its at rule" {
    val bold: Token[] = [.Text.Bold];
    try assertUtility(@src(), Token.Hover(bold));
}

test "css: modifiers ---- empty inner is an empty sheet" {
    val none: Token[] = [];
    val tokens: Token[] = [.Text.Bold, Token.Hover(none)];
    try assertCss(@src(), tokens);
}
```

`modules/emilia/test/__snapshots__/variant/modifiers-hover-is-media-guarded.snap`
```
atRule: @media (hover: hover)
selector: &:hover
```

`modules/emilia/test/__snapshots__/variant/modifiers-md-is-a-width-query.snap`
```
atRule: @media (width >= 48rem)
selector: &
```

`modules/emilia/test/__snapshots__/variant/modifiers-group-hover-looks-for-the-group-class.snap`
```
atRule: 
selector: &:is(:where(.group):hover *)
```

`modules/emilia/test/__snapshots__/variant/modifiers-rtl-puts-the-class-last.snap`
```
atRule: 
selector: [dir="rtl"] &
```

`modules/emilia/test/__snapshots__/variant/modifiers-open-is-a-selector-list.snap`
```
atRule: 
selector: &:open, &:popover-open
```

`modules/emilia/test/__snapshots__/css/modifiers-hover-on-md-breakpoint.snap`
```css
@media (width >= 48rem){@media (hover: hover){.e:hover{background-color:var(--color-red-500)}}}
```

`modules/emilia/test/__snapshots__/css/modifiers-breakpoint-ladder.snap`
```css
@media (width >= 40rem){.e{font-size:var(--text-sm);line-height:var(--text-sm--line-height)}}
@media (width >= 48rem){.e{font-size:var(--text-base);line-height:var(--text-base--line-height)}}
@media (width >= 64rem){.e{font-size:var(--text-lg);line-height:var(--text-lg--line-height)}}
@media (width >= 80rem){.e{font-size:var(--text-xl);line-height:var(--text-xl--line-height)}}
@media (width >= 96rem){.e{font-size:var(--text-2xl);line-height:var(--text-2xl--line-height)}}
```

`modules/emilia/test/__snapshots__/css/modifiers-max-breakpoints.snap`
```css
@media (width < 40rem){.e{display:none}}
@media (width < 96rem){.e{display:none}}
```

`modules/emilia/test/__snapshots__/css/modifiers-dark-inside-md-inside-hover.snap`
```css
@media (prefers-color-scheme: dark){@media (width >= 48rem){@media (hover: hover){.e:hover{font-weight:bold}}}}
```

`modules/emilia/test/__snapshots__/css/modifiers-structural-first-last-odd-nth.snap`
```css
.e:first-child{padding-top:0}
.e:last-child{padding-bottom:0}
.e:nth-child(odd){background-color:var(--color-gray-50)}
.e:nth-child(3){text-decoration-line:underline}
.e:nth-last-child(5){text-decoration-line:underline}
```

`modules/emilia/test/__snapshots__/css/modifiers-pseudo-elements-before-marker-selection.snap`
```css
.e::before{content:"";color:var(--color-red-500)}
.e ::marker{color:var(--color-sky-400)}
.e ::selection{background-color:var(--color-fuchsia-300)}
```

`modules/emilia/test/__snapshots__/css/modifiers-hover-before-and-before-hover-differ.snap`
```css
@media (hover: hover){.e:hover::before{color:var(--color-red-500)}}
@media (hover: hover){.e::before:hover{color:var(--color-red-500)}}
```

`modules/emilia/test/__snapshots__/css/modifiers-group-and-peer.snap`
```css
.e:is(:where(.group):hover *){color:var(--color-white)}
.e:is(:where(.peer):focus ~ *){visibility:visible}
.e:is(:where(.peer):checked ~ *){visibility:visible}
```

`modules/emilia/test/__snapshots__/css/modifiers-direction-and-descent.snap`
```css
[dir="ltr"] .e{margin-left:calc(var(--spacing) * 3)}
[dir="rtl"] .e{margin-right:calc(var(--spacing) * 3)}
:is(.e > *){border-radius:9999px}
:is(.e *){border-radius:9999px}
```

`modules/emilia/test/__snapshots__/css/modifiers-form-states.snap`
```css
.e:disabled{color:var(--color-gray-400)}
.e:invalid{border-color:var(--color-pink-500)}
.e:placeholder-shown{color:var(--color-gray-400)}
.e:open, .e:popover-open{color:var(--color-gray-400)}
.e:is([inert], [inert] *){color:var(--color-gray-400)}
```

`modules/emilia/test/__snapshots__/css/modifiers-print-and-motion.snap`
```css
@media print{.e{display:none}}
@media (prefers-reduced-motion: reduce){.e{transition-property:none}}
@media (forced-colors: active){.e{display:none}}
```

`modules/emilia/test/__snapshots__/ast/modifiers-hover-carries-its-at-rule.snap`
```
utilities | @media (hover: hover) | &:hover | font-weight:bold | false
```

`modules/emilia/test/__snapshots__/css/modifiers-empty-inner-is-an-empty-sheet.snap`
```css
.e{font-weight:bold}
```

---

## 35 — spacing and sizing · `modules/emilia/test/spacing_test.bp`

```bp
import { Token, spacing, spacingHalf } from "emilia";
import { assertCss, assertUtility } from "emilia-test";
import { equal } from "std/asserts";

test "css: spacing ---- padding all four" {
    try assertCss(@src(), [.Pad.All.4]);
}

test "css: spacing ---- padding zero px and half steps" {
    try assertCss(@src(), [.Pad.All.0, .Pad.T.Px, .Pad.B.Half.1]);
}

test "css: spacing ---- padding axes and logical sides" {
    try assertCss(@src(), [.Pad.X.4, .Pad.Y.2, .Pad.S.4, .Pad.E.4]);
}

test "css: spacing ---- margin auto and negative" {
    try assertCss(@src(), [.Margin.X.Auto, .Margin.All.Auto, .Margin.T.Neg.4, .Margin.B.Neg.Px]);
}

test "css: sizing ---- width and height forms" {
    try assertCss(@src(), [.Size.W.Full, .Size.W.Screen, .Size.H.Screen, .Size.H.Dvh, .Size.W.Fit, .Size.H.Auto]);
}

test "css: sizing ---- fractions" {
    try assertCss(@src(), [.Size.W.Frac.Half, .Size.W.Frac.Third, .Size.W.Frac.TwoThirds, .Size.W.Frac.FiveSixths]);
}

test "css: sizing ---- max width ladder and screens" {
    try assertCss(@src(), [.Size.MaxW.Xs, .Size.MaxW.Xl, .Size.MaxW.X7xl, .Size.MaxW.Screen.X2xl, .Size.MaxW.None]);
}

test "css: sizing ---- both and logical sizes" {
    try assertCss(@src(), [.Size.Both.12, .Size.Inline.4, .Size.MinBlock.0]);
}

test "css: spacing ---- space between children" {
    try assertCss(@src(), [.Pad.All.4, .Space.Y.4, .Space.X.2, .Space.XReverse]);
}

test "ast: spacing ---- space y is a sibling rule" {
    try assertUtility(@src(), .Space.Y.4);
}

test "spacing ladder is a calc over the theme" {
    equal(spacing(0), "0");
    equal(spacing(4), "calc(var(--spacing) * 4)");
    equal(spacing(-4), "calc(var(--spacing) * -4)");
    equal(spacingHalf(1), "calc(var(--spacing) * 1.5)");
}
```

`modules/emilia/test/__snapshots__/css/spacing-padding-all-four.snap`
```css
.e{padding:calc(var(--spacing) * 4)}
```

`modules/emilia/test/__snapshots__/css/spacing-padding-zero-px-and-half-steps.snap`
```css
.e{padding:0;padding-top:1px;padding-bottom:calc(var(--spacing) * 1.5)}
```

`modules/emilia/test/__snapshots__/css/spacing-padding-axes-and-logical-sides.snap`
```css
.e{padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);padding-inline-start:calc(var(--spacing) * 4);padding-inline-end:calc(var(--spacing) * 4)}
```

`modules/emilia/test/__snapshots__/css/spacing-margin-auto-and-negative.snap`
```css
.e{margin-left:auto;margin-right:auto;margin:auto;margin-top:calc(var(--spacing) * -4);margin-bottom:-1px}
```

`modules/emilia/test/__snapshots__/css/sizing-width-and-height-forms.snap`
```css
.e{width:100%;width:100vw;height:100vh;height:100dvh;width:fit-content;height:auto}
```

`modules/emilia/test/__snapshots__/css/sizing-fractions.snap`
```css
.e{width:50%;width:33.333333%;width:66.666667%;width:83.333333%}
```

`modules/emilia/test/__snapshots__/css/sizing-max-width-ladder-and-screens.snap`
```css
.e{max-width:20rem;max-width:36rem;max-width:80rem;max-width:96rem;max-width:none}
```

`modules/emilia/test/__snapshots__/css/sizing-both-and-logical-sizes.snap`
```css
.e{width:calc(var(--spacing) * 12);height:calc(var(--spacing) * 12);inline-size:calc(var(--spacing) * 4);min-block-size:0}
```

`modules/emilia/test/__snapshots__/css/spacing-space-between-children.snap`
```css
.e{padding:calc(var(--spacing) * 4)}
.e > :not(:last-child){margin-block-end:calc(var(--spacing) * 4);margin-inline-end:calc(var(--spacing) * 2);--tw-space-x-reverse:1}
```

`modules/emilia/test/__snapshots__/ast/spacing-space-y-is-a-sibling-rule.snap`
```
utilities | - | & > :not(:last-child) | margin-block-end:calc(var(--spacing) * 4) | false
```

---

## 36 — layout · `modules/emilia/test/layout_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: layout ---- display values old and new" {
    try assertCss(@src(), [.Layout.Block, .Layout.Hidden, .Layout.FlowRoot, .Layout.InlineGrid, .Layout.Contents]);
}

test "css: layout ---- sticky header" {
    try assertCss(@src(), [.Layout.Position.Sticky, .Layout.Inset.T.0, .Layout.Z.50]);
}

test "css: layout ---- inset forms" {
    try assertCss(@src(), [.Layout.Inset.All.0, .Layout.Inset.X.0, .Layout.Inset.T.1, .Layout.Inset.T.Frac.Half, .Layout.Inset.T.Neg.4, .Layout.Inset.S.0]);
}

test "css: layout ---- overflow overscroll visibility" {
    try assertCss(@src(), [.Layout.Overflow.Hidden, .Layout.Overflow.X.Auto, .Layout.Overscroll.Y.Contain, .Layout.Visibility.Invisible, .Layout.Visibility.Collapse]);
}

test "css: layout ---- float clear isolation" {
    try assertCss(@src(), [.Layout.Float.Start, .Layout.Clear.Start, .Layout.Clear.Both, .Layout.Isolation.Isolate]);
}

test "css: layout ---- object and aspect" {
    try assertCss(@src(), [.Layout.Object.Fit.Cover, .Layout.Object.Pos.LeftBottom, .Layout.Aspect.Square, .Layout.Aspect.Video]);
}

test "css: layout ---- columns and breaks" {
    try assertCss(@src(), [.Layout.Columns.3, .Layout.Columns.X3xs, .Layout.Columns.X7xl, .Layout.Break.Inside.AvoidColumn, .Layout.Break.After.Page]);
}

test "css: layout ---- box sizing and decoration" {
    try assertCss(@src(), [.Layout.Box.Border, .Layout.BoxDecoration.Clone]);
}
```

`modules/emilia/test/__snapshots__/css/layout-display-values-old-and-new.snap`
```css
.e{display:block;display:none;display:flow-root;display:inline-grid;display:contents}
```

`modules/emilia/test/__snapshots__/css/layout-sticky-header.snap`
```css
.e{position:sticky;top:0;z-index:50}
```

`modules/emilia/test/__snapshots__/css/layout-inset-forms.snap`
```css
.e{inset:0;left:0;right:0;top:calc(var(--spacing) * 1);top:50%;top:calc(var(--spacing) * -4);inset-inline-start:0}
```

`modules/emilia/test/__snapshots__/css/layout-overflow-overscroll-visibility.snap`
```css
.e{overflow:hidden;overflow-x:auto;overscroll-behavior-y:contain;visibility:hidden;visibility:collapse}
```

`modules/emilia/test/__snapshots__/css/layout-float-clear-isolation.snap`
```css
.e{float:inline-start;clear:inline-start;clear:both;isolation:isolate}
```

`modules/emilia/test/__snapshots__/css/layout-object-and-aspect.snap`
```css
.e{object-fit:cover;object-position:left bottom;aspect-ratio:1 / 1;aspect-ratio:16 / 9}
```

`modules/emilia/test/__snapshots__/css/layout-columns-and-breaks.snap`
```css
.e{columns:3;columns:16rem;columns:80rem;break-inside:avoid-column;break-after:page}
```

`modules/emilia/test/__snapshots__/css/layout-box-sizing-and-decoration.snap`
```css
.e{box-sizing:border-box;box-decoration-break:clone}
```

---

## 37 — flexbox, grid and gap · `modules/emilia/test/grid_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: flex ---- direction wrap and value" {
    try assertCss(@src(), [.Flex.RowReverse, .Flex.Col, .Flex.NoWrap, .Flex.Value.One, .Flex.Value.Initial, .Flex.Value.None]);
}

test "css: flex ---- grow shrink basis order" {
    try assertCss(@src(), [.Flex.Grow.1, .Flex.Shrink.0, .Flex.Basis.1, .Flex.Basis.Frac.Third, .Flex.Order.First, .Flex.Order.Last, .Flex.Order.None]);
}

test "css: flex ---- alignment keeps the flex start asymmetry" {
    try assertCss(@src(), [.Flex.Justify.Start, .Flex.Justify.Between, .Flex.JustifyItems.Start, .Flex.Items.Baseline, .Flex.Self.Start, .Flex.Content.Evenly, .Flex.Place.Content.Between]);
}

test "css: grid ---- twelve columns three rows" {
    try assertCss(@src(), [.Layout.Grid, .Grid.Cols.12, .Grid.Rows.3, .Gap.All.4]);
}

test "css: grid ---- spans starts and keywords" {
    try assertCss(@src(), [.Grid.Col.Span.2, .Grid.Col.Span.Full, .Grid.Col.Start.13, .Grid.Row.Auto, .Grid.Cols.Subgrid, .Grid.Rows.None]);
}

test "css: grid ---- auto flow and auto tracks" {
    try assertCss(@src(), [.Grid.Flow.ColDense, .Grid.AutoCols.Fr, .Grid.AutoRows.Min]);
}

test "css: gap ---- all x y px zero" {
    try assertCss(@src(), [.Gap.All.0, .Gap.X.1, .Gap.Y.1, .Gap.All.Px, .Gap.All.Half.1]);
}

test "css: gap ---- legacy flex gap equals gap all" {
    try assertCss(@src(), [.Flex.Gap.4, .Gap.All.4]);
}
```

`modules/emilia/test/__snapshots__/css/flex-direction-wrap-and-value.snap`
```css
.e{flex-direction:row-reverse;flex-direction:column;flex-wrap:nowrap;flex:1 1 0%;flex:0 1 auto;flex:none}
```

`modules/emilia/test/__snapshots__/css/flex-grow-shrink-basis-order.snap`
```css
.e{flex-grow:1;flex-shrink:0;flex-basis:calc(var(--spacing) * 1);flex-basis:33.333333%;order:-9999;order:9999;order:0}
```

`modules/emilia/test/__snapshots__/css/flex-alignment-keeps-the-flex-start-asymmetry.snap`
```css
.e{justify-content:flex-start;justify-content:space-between;justify-items:start;align-items:baseline;align-self:flex-start;align-content:space-evenly;place-content:space-between}
```

`modules/emilia/test/__snapshots__/css/grid-twelve-columns-three-rows.snap`
```css
.e{display:grid;grid-template-columns:repeat(12, minmax(0, 1fr));grid-template-rows:repeat(3, minmax(0, 1fr));gap:calc(var(--spacing) * 4)}
```

`modules/emilia/test/__snapshots__/css/grid-spans-starts-and-keywords.snap`
```css
.e{grid-column:span 2 / span 2;grid-column:1 / -1;grid-column-start:13;grid-row:auto;grid-template-columns:subgrid;grid-template-rows:none}
```

`modules/emilia/test/__snapshots__/css/grid-auto-flow-and-auto-tracks.snap`
```css
.e{grid-auto-flow:column dense;grid-auto-columns:minmax(0, 1fr);grid-auto-rows:min-content}
```

`modules/emilia/test/__snapshots__/css/gap-all-x-y-px-zero.snap`
```css
.e{gap:0;column-gap:calc(var(--spacing) * 1);row-gap:calc(var(--spacing) * 1);gap:1px;gap:calc(var(--spacing) * 1.5)}
```

`modules/emilia/test/__snapshots__/css/gap-legacy-flex-gap-equals-gap-all.snap`
```css
.e{gap:calc(var(--spacing) * 4);gap:calc(var(--spacing) * 4)}
```

---

## 38 — typography · `modules/emilia/test/typography_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: typography ---- size carries its line height" {
    try assertCss(@src(), [.Text.Size.Lg, .Text.Size.X9xl]);
}

test "css: typography ---- family weight smoothing" {
    try assertCss(@src(), [.Font.Sans, .Font.Weight.Thin, .Font.Weight.Semibold, .Text.Bold, .Font.Smoothing.Antialiased]);
}

test "css: typography ---- tracking and leading" {
    try assertCss(@src(), [.Text.Tracking.Wide, .Text.Leading.Tight, .Text.Leading.None]);
}

test "css: typography ---- decoration" {
    try assertCss(@src(), [.Text.Underline, .Text.NoUnderline, .Text.Decoration.Style.Wavy, .Text.Decoration.Thickness.2, .Text.Decoration.Offset.4, .Text.Decoration.Color.Red.500]);
}

test "css: typography ---- clamp and truncate" {
    try assertCss(@src(), [.Text.Clamp.3]);
}

test "css: typography ---- clamp none" {
    try assertCss(@src(), [.Text.Clamp.None, .Text.Truncate]);
}

test "css: typography ---- transform overflow wrap whitespace" {
    try assertCss(@src(), [.Text.Transform.Uppercase, .Text.Overflow.Ellipsis, .Text.Wrap.Balance, .Text.Whitespace.PreWrap, .Text.Break.Normal, .Text.OverflowWrap.Anywhere, .Text.Hyphens.Auto]);
}

test "css: typography ---- indent align tab content" {
    try assertCss(@src(), [.Text.Indent.8, .Text.Align.Middle, .Text.Tab.4, .Text.Content.Empty, .Text.Content.None]);
}

test "css: typography ---- stretch and numeric variants" {
    try assertCss(@src(), [.Font.Stretch.UltraCondensed, .Font.Nums.Tabular, .Font.Nums.SlashedZero, .Font.Style.Italic]);
}

test "css: typography ---- list" {
    try assertCss(@src(), [.List.Disc, .List.Inside, .List.None, .List.ImageNone]);
}
```

`modules/emilia/test/__snapshots__/css/typography-size-carries-its-line-height.snap`
```css
.e{font-size:var(--text-lg);line-height:var(--text-lg--line-height);font-size:var(--text-9xl);line-height:var(--text-9xl--line-height)}
```

`modules/emilia/test/__snapshots__/css/typography-family-weight-smoothing.snap`
```css
.e{font-family:var(--font-sans);font-weight:100;font-weight:600;font-weight:bold;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}
```

`modules/emilia/test/__snapshots__/css/typography-tracking-and-leading.snap`
```css
.e{letter-spacing:var(--tracking-wide);line-height:var(--leading-tight);line-height:1}
```

`modules/emilia/test/__snapshots__/css/typography-decoration.snap`
```css
.e{text-decoration-line:underline;text-decoration-line:none;text-decoration-style:wavy;text-decoration-thickness:2px;text-underline-offset:4px;text-decoration-color:var(--color-red-500)}
```

`modules/emilia/test/__snapshots__/css/typography-clamp-and-truncate.snap`
```css
.e{overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3}
```

`modules/emilia/test/__snapshots__/css/typography-clamp-none.snap`
```css
.e{overflow:visible;display:block;-webkit-box-orient:horizontal;-webkit-line-clamp:none;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
```

`modules/emilia/test/__snapshots__/css/typography-transform-overflow-wrap-whitespace.snap`
```css
.e{text-transform:uppercase;text-overflow:ellipsis;text-wrap:balance;white-space:pre-wrap;overflow-wrap:normal;word-break:normal;overflow-wrap:anywhere;hyphens:auto}
```

`modules/emilia/test/__snapshots__/css/typography-indent-align-tab-content.snap`
```css
.e{text-indent:calc(var(--spacing) * 8);vertical-align:middle;tab-size:4;content:"";content:none}
```

`modules/emilia/test/__snapshots__/css/typography-stretch-and-numeric-variants.snap`
```css
.e{font-stretch:ultra-condensed;font-variant-numeric:tabular-nums;font-variant-numeric:slashed-zero;font-style:italic}
```

`modules/emilia/test/__snapshots__/css/typography-list.snap`
```css
.e{list-style-type:disc;list-style-position:inside;list-style-type:none;list-style-image:none}
```

---

## 39 — backgrounds · `modules/emilia/test/backgrounds_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: backgrounds ---- attachment clip origin" {
    try assertCss(@src(), [.Bg.Attachment.Fixed, .Bg.Clip.Text, .Bg.Clip.Border, .Bg.Origin.Padding]);
}

test "css: backgrounds ---- position repeat size image" {
    try assertCss(@src(), [.Bg.Pos.LeftBottom, .Bg.Pos.Center, .Bg.Repeat.None, .Bg.Repeat.X, .Bg.Size.Cover, .Bg.Image.None]);
}

test "css: backgrounds ---- gradient to right from via stop" {
    try assertCss(@src(), [.Gradient.To.R, .Gradient.From.Indigo.500, .Gradient.Via.Purple.500, .Gradient.Stop.Pink.500]);
}

test "css: backgrounds ---- gradient to top right with transparent stop" {
    try assertCss(@src(), [.Gradient.To.Tr, .Gradient.From.Sky.400, .Gradient.Stop.Transparent]);
}

test "css: backgrounds ---- hero card" {
    val dark: Token[] = [.Bg.Color.Slate.900];
    try assertCss(@src(), [.Bg.Color.White, .Bg.Size.Cover, .Bg.Pos.Center, Token.Dark(dark)]);
}
```

`modules/emilia/test/__snapshots__/css/backgrounds-attachment-clip-origin.snap`
```css
.e{background-attachment:fixed;background-clip:text;background-clip:border-box;background-origin:padding-box}
```

`modules/emilia/test/__snapshots__/css/backgrounds-position-repeat-size-image.snap`
```css
.e{background-position:left bottom;background-position:center;background-repeat:no-repeat;background-repeat:repeat-x;background-size:cover;background-image:none}
```

`modules/emilia/test/__snapshots__/css/backgrounds-gradient-to-right-from-via-stop.snap`
```css
.e{background-image:linear-gradient(to right, var(--tw-gradient-stops));--tw-gradient-from:var(--color-indigo-500);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to);--tw-gradient-via:var(--color-purple-500);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-via), var(--tw-gradient-to);--tw-gradient-to:var(--color-pink-500)}
```

`modules/emilia/test/__snapshots__/css/backgrounds-gradient-to-top-right-with-transparent-stop.snap`
```css
.e{background-image:linear-gradient(to top right, var(--tw-gradient-stops));--tw-gradient-from:var(--color-sky-400);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to);--tw-gradient-to:transparent}
```

`modules/emilia/test/__snapshots__/css/backgrounds-hero-card.snap`
```css
.e{background-color:var(--color-white);background-size:cover;background-position:center}
@media (prefers-color-scheme: dark){.e{background-color:var(--color-slate-900)}}
```

---

## 40 — borders, outlines, rings and divides · `modules/emilia/test/borders_test.bp`

```bp
import { Token } from "emilia";
import { assertCss, assertUtility } from "emilia-test";

test "css: borders ---- width style colour radius" {
    try assertCss(@src(), [.Border.W.1, .Border.Style.Dashed, .Border.Color.Slate.200, .Border.Rounded.Lg]);
}

test "css: borders ---- per side widths" {
    try assertCss(@src(), [.Border.W.X.1, .Border.W.T.2, .Border.W.S.1, .Border.W.8]);
}

test "css: borders ---- radius corners and keywords" {
    try assertCss(@src(), [.Border.Rounded.None, .Border.Rounded.Full, .Border.Rounded.T.Lg, .Border.Rounded.Ss.Lg, .Border.Rounded.X4xl]);
}

test "css: borders ---- colour keywords" {
    try assertCss(@src(), [.Border.Color.Current, .Border.Color.Transparent]);
}

test "css: outline ---- focus visible ring of outline" {
    val ring: Token[] = [.Outline.W.2, .Outline.Color.Indigo.500, .Outline.Offset.2];
    try assertCss(@src(), [.Outline.Style.None, Token.FocusVisible(ring)]);
}

test "css: outline ---- negative offset" {
    try assertCss(@src(), [.Outline.Offset.Neg.1, .Outline.Style.Dashed]);
}

test "css: ring ---- one pixel ring with colour offset inset" {
    try assertCss(@src(), [.Ring.W.1, .Ring.Color.Indigo.500, .Ring.Offset.W.2, .Ring.Inset]);
}

test "css: divide ---- y two x one colour reverse" {
    try assertCss(@src(), [.Divide.Y.2, .Divide.X.1, .Divide.Color.Slate.200, .Divide.XReverse]);
}

test "ast: divide ---- same sibling selector as space" {
    try assertUtility(@src(), .Divide.Y.2);
}
```

`modules/emilia/test/__snapshots__/css/borders-width-style-colour-radius.snap`
```css
.e{border-width:1px;border-style:dashed;border-color:var(--color-slate-200);border-radius:var(--radius-lg)}
```

`modules/emilia/test/__snapshots__/css/borders-per-side-widths.snap`
```css
.e{border-left-width:1px;border-right-width:1px;border-top-width:2px;border-inline-start-width:1px;border-width:8px}
```

`modules/emilia/test/__snapshots__/css/borders-radius-corners-and-keywords.snap`
```css
.e{border-radius:0;border-radius:9999px;border-top-left-radius:var(--radius-lg);border-top-right-radius:var(--radius-lg);border-start-start-radius:var(--radius-lg);border-radius:var(--radius-4xl)}
```

`modules/emilia/test/__snapshots__/css/borders-colour-keywords.snap`
```css
.e{border-color:currentColor;border-color:transparent}
```

`modules/emilia/test/__snapshots__/css/outline-focus-visible-ring-of-outline.snap`
```css
.e{outline:2px solid transparent;outline-offset:2px}
.e:focus-visible{outline-width:2px;outline-color:var(--color-indigo-500);outline-offset:2px}
```

`modules/emilia/test/__snapshots__/css/outline-negative-offset.snap`
```css
.e{outline-offset:-1px;outline-style:dashed}
```

`modules/emilia/test/__snapshots__/css/ring-one-pixel-ring-with-colour-offset-inset.snap`
```css
.e{--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);--tw-ring-color:var(--color-indigo-500);--tw-ring-offset-width:2px;--tw-ring-inset:inset}
```

`modules/emilia/test/__snapshots__/css/divide-y-two-x-one-colour-reverse.snap`
```css
.e > :not(:last-child){border-top-width:0px;border-bottom-width:2px;border-inline-start-width:0px;border-inline-end-width:1px;border-color:var(--color-slate-200);--tw-divide-x-reverse:1}
```

`modules/emilia/test/__snapshots__/ast/divide-same-sibling-selector-as-space.snap`
```
utilities | - | & > :not(:last-child) | border-top-width:0px;border-bottom-width:2px | false
```
The selector column of this file and of `ast/spacing-space-y-is-a-sibling-rule.snap` must be
byte-identical; a test in each front `contains`-checks the other's file.

---

## 41 — effects · `modules/emilia/test/effects_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: effects ---- shadow ladder" {
    try assertCss(@src(), [.Effect.Shadow.X2xs, .Effect.Shadow.Md, .Effect.Shadow.X2xl, .Effect.Shadow.None]);
}

test "css: effects ---- inner and inset shadow" {
    try assertCss(@src(), [.Effect.Shadow.Inner, .Effect.InsetShadow.Sm]);
}

test "css: effects ---- text shadow" {
    try assertCss(@src(), [.Effect.TextShadow.Sm, .Effect.TextShadow.None]);
}

test "css: effects ---- opacity steps keep the leading zero" {
    try assertCss(@src(), [.Effect.Opacity.5, .Effect.Opacity.60, .Effect.Opacity.100]);
}

test "css: effects ---- blend modes" {
    try assertCss(@src(), [.Blend.Mix.PlusLighter, .Blend.Mix.Multiply, .Blend.Bg.Multiply]);
}

test "css: effects ---- mask" {
    try assertCss(@src(), [.Mask.Clip.Padding, .Mask.Mode.Luminance, .Mask.Composite.Subtract, .Mask.Repeat.NoRepeat, .Mask.Size.Cover]);
}

test "css: effects ---- raw shadow and raw mask image" {
    val tokens: Token[] = [
        Token.EffectShadowRaw(value: "0 0 0 1px red"),
        Token.MaskImageRaw(value: "linear-gradient(black, transparent)"),
    ];
    try assertCss(@src(), tokens);
}

test "css: effects ---- shadow lifts on hover" {
    val lifted: Token[] = [.Effect.Shadow.Lg];
    try assertCss(@src(), [.Effect.Shadow.Sm, Token.Hover(lifted)]);
}
```

`modules/emilia/test/__snapshots__/css/effects-shadow-ladder.snap`
```css
.e{box-shadow:var(--shadow-2xs);box-shadow:var(--shadow-md);box-shadow:var(--shadow-2xl);box-shadow:none}
```

`modules/emilia/test/__snapshots__/css/effects-inner-and-inset-shadow.snap`
```css
.e{box-shadow:inset 0 2px 4px 0 rgb(0 0 0 / 0.05);box-shadow:inset var(--inset-shadow-sm)}
```

`modules/emilia/test/__snapshots__/css/effects-text-shadow.snap`
```css
.e{text-shadow:var(--text-shadow-sm);text-shadow:none}
```

`modules/emilia/test/__snapshots__/css/effects-opacity-steps-keep-the-leading-zero.snap`
```css
.e{opacity:0.05;opacity:0.6;opacity:1}
```

`modules/emilia/test/__snapshots__/css/effects-blend-modes.snap`
```css
.e{mix-blend-mode:plus-lighter;mix-blend-mode:multiply;background-blend-mode:multiply}
```

`modules/emilia/test/__snapshots__/css/effects-mask.snap`
```css
.e{mask-clip:padding-box;mask-mode:luminance;mask-composite:subtract;mask-repeat:no-repeat;mask-size:cover}
```

`modules/emilia/test/__snapshots__/css/effects-raw-shadow-and-raw-mask-image.snap`
```css
.e{box-shadow:0 0 0 1px red;mask-image:linear-gradient(black, transparent)}
```

`modules/emilia/test/__snapshots__/css/effects-shadow-lifts-on-hover.snap`
```css
.e{box-shadow:var(--shadow-sm)}
@media (hover: hover){.e:hover{box-shadow:var(--shadow-lg)}}
```

---

## 42 — filters · `modules/emilia/test/filters_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: filters ---- blur ladder ends in the shorthand" {
    try assertCss(@src(), [.Filter.Blur.None]);
}

test "css: filters ---- blur sm composes with grayscale" {
    try assertCss(@src(), [.Filter.Blur.Sm, .Filter.Grayscale.100]);
}

test "css: filters ---- brightness contrast drop leading zero" {
    try assertCss(@src(), [.Filter.Brightness.50, .Filter.Brightness.110, .Filter.Contrast.75, .Filter.Brightness.100]);
}

test "css: filters ---- hue rotate invert saturate sepia" {
    try assertCss(@src(), [.Filter.HueRotate.90, .Filter.Invert.100, .Filter.Saturate.150, .Filter.Sepia.0]);
}

test "css: filters ---- drop shadow" {
    try assertCss(@src(), [.Filter.DropShadow.Md, .Filter.DropShadow.None]);
}

test "css: filters ---- backdrop blur and opacity" {
    try assertCss(@src(), [.Backdrop.Blur.None, .Backdrop.Blur.Sm, .Backdrop.Opacity.50]);
}

test "css: filters ---- raw filter and raw backdrop" {
    val tokens: Token[] = [
        Token.FilterRaw(value: "blur(8px) grayscale(100%)"),
        Token.BackdropRaw(value: "blur(2px)"),
    ];
    try assertCss(@src(), tokens);
}
```

`modules/emilia/test/__snapshots__/css/filters-blur-ladder-ends-in-the-shorthand.snap`
```css
.e{filter:none}
```

`modules/emilia/test/__snapshots__/css/filters-blur-sm-composes-with-grayscale.snap`
```css
.e{--tw-blur:blur(var(--blur-sm));filter:var(--tw-filter);--tw-grayscale:grayscale(100%);filter:var(--tw-filter)}
```

`modules/emilia/test/__snapshots__/css/filters-brightness-contrast-drop-leading-zero.snap`
```css
.e{--tw-brightness:brightness(.5);filter:var(--tw-filter);--tw-brightness:brightness(1.1);filter:var(--tw-filter);--tw-contrast:contrast(.75);filter:var(--tw-filter);--tw-brightness:brightness(1);filter:var(--tw-filter)}
```

`modules/emilia/test/__snapshots__/css/filters-hue-rotate-invert-saturate-sepia.snap`
```css
.e{--tw-hue-rotate:hue-rotate(90deg);filter:var(--tw-filter);--tw-invert:invert(100%);filter:var(--tw-filter);--tw-saturate:saturate(1.5);filter:var(--tw-filter);--tw-sepia:sepia(0);filter:var(--tw-filter)}
```

`modules/emilia/test/__snapshots__/css/filters-drop-shadow.snap`
```css
.e{--tw-drop-shadow:drop-shadow(var(--drop-shadow-md));filter:var(--tw-filter);filter:drop-shadow(none)}
```

`modules/emilia/test/__snapshots__/css/filters-backdrop-blur-and-opacity.snap`
```css
.e{backdrop-filter:none;--tw-backdrop-blur:blur(var(--blur-sm));backdrop-filter:var(--tw-backdrop-filter);--tw-backdrop-opacity:opacity(0.5);backdrop-filter:var(--tw-backdrop-filter)}
```

`modules/emilia/test/__snapshots__/css/filters-raw-filter-and-raw-backdrop.snap`
```css
.e{filter:blur(8px) grayscale(100%);backdrop-filter:blur(2px)}
```

---

## 43 — tables · `modules/emilia/test/tables_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: tables ---- collapse separate layout caption" {
    try assertCss(@src(), [.Table.Collapse, .Table.Separate, .Table.Layout.Fixed, .Table.Caption.Bottom]);
}

test "css: tables ---- spacing all x y and zero" {
    try assertCss(@src(), [.Table.Spacing.2, .Table.SpacingX.2, .Table.SpacingY.2, .Table.Spacing.0, .Table.SpacingX.0]);
}

test "css: tables ---- raw spacing" {
    val tokens: Token[] = [Token.TableSpacingRaw(value: "1px 2px")];
    try assertCss(@src(), tokens);
}

test "css: tables ---- fixed layout from md" {
    val fixed: Token[] = [.Table.Layout.Fixed];
    try assertCss(@src(), [.Table.Layout.Auto, Token.Md(fixed)]);
}
```

`modules/emilia/test/__snapshots__/css/tables-collapse-separate-layout-caption.snap`
```css
.e{border-collapse:collapse;border-collapse:separate;table-layout:fixed;caption-side:bottom}
```

`modules/emilia/test/__snapshots__/css/tables-spacing-all-x-y-and-zero.snap`
```css
.e{border-spacing:calc(var(--spacing) * 2);border-spacing:calc(var(--spacing) * 2) 0;border-spacing:0 calc(var(--spacing) * 2);border-spacing:0;border-spacing:0 0}
```

`modules/emilia/test/__snapshots__/css/tables-raw-spacing.snap`
```css
.e{border-spacing:1px 2px}
```

`modules/emilia/test/__snapshots__/css/tables-fixed-layout-from-md.snap`
```css
.e{table-layout:auto}
@media (width >= 48rem){.e{table-layout:fixed}}
```

---

## 44 — transitions and animation · `modules/emilia/test/transitions_test.bp`

```bp
import { Token } from "emilia";
import { assertCss, assertUtility } from "emilia-test";

test "css: transitions ---- presets" {
    try assertCss(@src(), [.Transition.None, .Transition.All, .Transition.Colors]);
}

test "css: transitions ---- base preset lists eleven properties" {
    try assertCss(@src(), [.Transition.Base]);
}

test "css: transitions ---- duration delay ease behavior" {
    try assertCss(@src(), [.Transition.Duration.300, .Transition.Duration.0, .Transition.Delay.150, .Transition.Ease.Linear, .Transition.Ease.InOut, .Transition.Behavior.Discrete]);
}

test "css: transitions ---- colours then duration override" {
    try assertCss(@src(), [.Transition.Colors, .Transition.Duration.300]);
}

test "css: animation ---- spin carries its keyframes" {
    try assertCss(@src(), [.Animate.Spin]);
}

test "css: animation ---- two spins one block" {
    try assertCss(@src(), [.Animate.Spin, .Animate.Spin]);
}

test "css: animation ---- none has no block" {
    try assertCss(@src(), [.Animate.None]);
}

test "css: animation ---- ping pulse bounce" {
    try assertCss(@src(), [.Animate.Ping, .Animate.Pulse, .Animate.Bounce]);
}

test "ast: animation ---- spin is a rule plus a block" {
    try assertUtility(@src(), .Animate.Spin);
}

test "css: transitions ---- raw property and raw animation" {
    val tokens: Token[] = [
        Token.TransitionProperty(value: "opacity, transform"),
        Token.AnimateRaw(value: "wiggle 1s ease-in-out infinite"),
    ];
    try assertCss(@src(), tokens);
}
```

`modules/emilia/test/__snapshots__/css/transitions-presets.snap`
```css
.e{transition-property:none;transition-property:all;transition-timing-function:var(--ease-out);transition-duration:150ms;transition-property:color, background-color, border-color, text-decoration-color, fill, stroke;transition-timing-function:var(--ease-out);transition-duration:150ms}
```

`modules/emilia/test/__snapshots__/css/transitions-base-preset-lists-eleven-properties.snap`
```css
.e{transition-property:color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter;transition-timing-function:var(--ease-out);transition-duration:150ms}
```

`modules/emilia/test/__snapshots__/css/transitions-duration-delay-ease-behavior.snap`
```css
.e{transition-duration:300ms;transition-duration:0ms;transition-delay:150ms;transition-timing-function:linear;transition-timing-function:var(--ease-in-out);transition-behavior:allow-discrete}
```

`modules/emilia/test/__snapshots__/css/transitions-colours-then-duration-override.snap`
```css
.e{transition-property:color, background-color, border-color, text-decoration-color, fill, stroke;transition-timing-function:var(--ease-out);transition-duration:150ms;transition-duration:300ms}
```

`modules/emilia/test/__snapshots__/css/animation-spin-carries-its-keyframes.snap`
```css
.e{animation:var(--animate-spin)}
@keyframes spin{to{transform:rotate(360deg)}}
```

`modules/emilia/test/__snapshots__/css/animation-two-spins-one-block.snap`
```css
.e{animation:var(--animate-spin);animation:var(--animate-spin)}
@keyframes spin{to{transform:rotate(360deg)}}
```

`modules/emilia/test/__snapshots__/css/animation-none-has-no-block.snap`
```css
.e{animation:none}
```

`modules/emilia/test/__snapshots__/css/animation-ping-pulse-bounce.snap`
```css
.e{animation:var(--animate-ping);animation:var(--animate-pulse);animation:var(--animate-bounce)}
@keyframes ping{75%,100%{transform:scale(2);opacity:0}}
@keyframes pulse{50%{opacity:0.5}}
@keyframes bounce{0%,100%{transform:translateY(-25%);animation-timing-function:cubic-bezier(0.8,0,1,1)}50%{transform:none;animation-timing-function:cubic-bezier(0,0,0.2,1)}}
```
The four bodies are not in `TAILWIND_CSS_DOCS.md`; they are upstream `theme.css`'s, pasted once when
44 lands (the front gates them on that read). The `--animate-*` values they pair with are in 54's
theme snapshot.

`modules/emilia/test/__snapshots__/ast/animation-spin-is-a-rule-plus-a-block.snap`
```
utilities | - | & | animation:var(--animate-spin) | false
block | @keyframes spin | to{transform:rotate(360deg)}
```

`modules/emilia/test/__snapshots__/css/transitions-raw-property-and-raw-animation.snap`
```css
.e{transition-property:opacity, transform;animation:wiggle 1s ease-in-out infinite}
```

---

## 45 — transforms · `modules/emilia/test/transforms_test.bp`

```bp
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: transforms ---- rotate and negative rotate" {
    try assertCss(@src(), [.Transform.Rotate.45, .Transform.Rotate.Neg.12, .Transform.Rotate.0]);
}

test "css: transforms ---- scale drops the leading zero zoom keeps it" {
    try assertCss(@src(), [.Transform.Scale.50, .Transform.Scale.100, .Transform.Scale.105, .Transform.ScaleX.50, .Transform.ScaleY.50, .Transform.Zoom.50]);
}

test "css: transforms ---- translate axis vars and shorthand" {
    try assertCss(@src(), [.Transform.TranslateX.Half, .Transform.TranslateY.Full]);
}

test "css: transforms ---- translate px and spacing" {
    try assertCss(@src(), [.Transform.TranslateX.Px, .Transform.TranslateX.1]);
}

test "css: transforms ---- skew origin style backface" {
    try assertCss(@src(), [.Transform.SkewX.3, .Transform.Origin.TopLeft, .Transform.Style.Preserve3d, .Transform.Backface.Hidden]);
}

test "css: transforms ---- perspective" {
    try assertCss(@src(), [.Transform.Perspective.None, .Transform.Perspective.Normal, .Transform.PerspectiveOrigin.Top]);
}

test "css: transforms ---- gpu shorthand" {
    try assertCss(@src(), [.Transform.Shorthand.Gpu]);
}

test "css: transforms ---- lift on hover with transition" {
    val up: Token[] = [.Transform.Scale.105];
    try assertCss(@src(), [.Transition.Transform, Token.Hover(up)]);
}
```

`modules/emilia/test/__snapshots__/css/transforms-rotate-and-negative-rotate.snap`
```css
.e{rotate:45deg;rotate:-12deg;rotate:0deg}
```

`modules/emilia/test/__snapshots__/css/transforms-scale-drops-the-leading-zero-zoom-keeps-it.snap`
```css
.e{scale:.5;scale:1;scale:1.05;scale:.5 1;scale:1 .5;zoom:0.5}
```

`modules/emilia/test/__snapshots__/css/transforms-translate-axis-vars-and-shorthand.snap`
```css
.e{--tw-translate-x:50%;translate:var(--tw-translate-x) var(--tw-translate-y);--tw-translate-y:100%;translate:var(--tw-translate-x) var(--tw-translate-y)}
```

`modules/emilia/test/__snapshots__/css/transforms-translate-px-and-spacing.snap`
```css
.e{--tw-translate-x:1px;translate:var(--tw-translate-x) var(--tw-translate-y);--tw-translate-x:calc(var(--spacing) * 1);translate:var(--tw-translate-x) var(--tw-translate-y)}
```

`modules/emilia/test/__snapshots__/css/transforms-skew-origin-style-backface.snap`
```css
.e{skew-x:3deg;transform-origin:top left;transform-style:preserve-3d;backface-visibility:hidden}
```
`skew-x:3deg` is the reference's row verbatim; the front flags it for an upstream check (`skew-x`
is not a CSS property) and this line is regenerated by hand if the check changes it.

`modules/emilia/test/__snapshots__/css/transforms-perspective.snap`
```css
.e{perspective:none;perspective:var(--perspective-normal);perspective-origin:top}
```

`modules/emilia/test/__snapshots__/css/transforms-gpu-shorthand.snap`
```css
.e{transform:translate3d(var(--tw-translate-x), var(--tw-translate-y), 0) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}
```

`modules/emilia/test/__snapshots__/css/transforms-lift-on-hover-with-transition.snap`
```css
.e{transition-property:transform;transition-timing-function:var(--ease-out);transition-duration:150ms}
@media (hover: hover){.e:hover{scale:1.05}}
```

---

## 46 — interactivity · `modules/emilia/test/interactivity_test.bp`

```bp
import { Token, paletteVar } from "emilia";
import { assertCss } from "emilia-test";

test "css: interactivity ---- cursors" {
    try assertCss(@src(), [.Interact.Cursor.Pointer, .Interact.Cursor.Standard, .Interact.Cursor.NotAllowed, .Interact.Cursor.Grabbing, .Interact.Cursor.ZoomIn]);
}

test "css: interactivity ---- pointer resize select will change touch" {
    try assertCss(@src(), [.Interact.PointerEvents.None, .Interact.Resize.Y, .Interact.Resize.X, .Interact.Select.None, .Interact.WillChange.Scroll, .Interact.Touch.PanX]);
}

test "css: interactivity ---- scroll behaviour margin padding" {
    try assertCss(@src(), [.Interact.Scroll.Behavior.Smooth, .Interact.Scroll.M.0, .Interact.Scroll.Mt.4, .Interact.Scroll.Mx.4, .Interact.Scroll.Py.4]);
}

test "css: interactivity ---- scrollbar and snap" {
    try assertCss(@src(), [.Interact.Scrollbar.Width.Thin, .Interact.Scrollbar.Gutter.StableBothEdges, .Interact.Snap.Type.X, .Interact.Snap.Strictness.Mandatory, .Interact.Snap.Align.Center, .Interact.Snap.Stop.Always]);
}

test "css: interactivity ---- appearance colour scheme field sizing" {
    try assertCss(@src(), [.Interact.Appearance.None, .Interact.ColorScheme.LightDark, .Interact.FieldSizing.Content]);
}

test "css: interactivity ---- accent caret scrollbar colours" {
    val tokens: Token[] = [
        Token.InteractAccent(value: paletteVar("indigo", "600")),
        Token.InteractCaret(value: paletteVar("pink", "500")),
        Token.InteractScrollbarColor(thumb: paletteVar("red", "500"), track: paletteVar("gray", "200")),
    ];
    try assertCss(@src(), tokens);
}
```

`modules/emilia/test/__snapshots__/css/interactivity-cursors.snap`
```css
.e{cursor:pointer;cursor:default;cursor:not-allowed;cursor:grabbing;cursor:zoom-in}
```

`modules/emilia/test/__snapshots__/css/interactivity-pointer-resize-select-will-change-touch.snap`
```css
.e{pointer-events:none;resize:vertical;resize:horizontal;user-select:none;will-change:scroll-position;touch-action:pan-x}
```

`modules/emilia/test/__snapshots__/css/interactivity-scroll-behaviour-margin-padding.snap`
```css
.e{scroll-behavior:smooth;scroll-margin:0;scroll-margin-top:calc(var(--spacing) * 4);scroll-margin-left:calc(var(--spacing) * 4);scroll-margin-right:calc(var(--spacing) * 4);scroll-padding-top:calc(var(--spacing) * 4);scroll-padding-bottom:calc(var(--spacing) * 4)}
```

`modules/emilia/test/__snapshots__/css/interactivity-scrollbar-and-snap.snap`
```css
.e{scrollbar-width:thin;scrollbar-gutter:stable both-edges;scroll-snap-type:x var(--tw-scroll-snap-strictness);--tw-scroll-snap-strictness:mandatory;scroll-snap-align:center;scroll-snap-stop:always}
```

`modules/emilia/test/__snapshots__/css/interactivity-appearance-colour-scheme-field-sizing.snap`
```css
.e{appearance:none;color-scheme:light dark;field-sizing:content}
```

`modules/emilia/test/__snapshots__/css/interactivity-accent-caret-scrollbar-colours.snap`
```css
.e{accent-color:var(--color-indigo-600);caret-color:var(--color-pink-500);scrollbar-color:var(--color-red-500) var(--color-gray-200)}
```

---

## 47 — SVG and accessibility · `modules/emilia/test/svg_a11y_test.bp`

```bp
import { Token, paletteVar } from "emilia";
import { assertCss } from "emilia-test";

test "css: svg ---- fill stroke width keywords" {
    try assertCss(@src(), [.Svg.Fill.Current, .Svg.Stroke.Current, .Svg.StrokeWidth.2, .Svg.Fill.None, .Svg.StrokeWidth.0]);
}

test "css: svg ---- palette fill and stroke" {
    val tokens: Token[] = [
        Token.SvgFill(value: paletteVar("red", "500")),
        Token.SvgStroke(value: paletteVar("blue", "500")),
        Token.SvgStrokeWidthRaw(value: "3"),
    ];
    try assertCss(@src(), tokens);
}

test "css: a11y ---- sr only" {
    try assertCss(@src(), [.A11y.SrOnly]);
}

test "css: a11y ---- not sr only from md" {
    val shown: Token[] = [.A11y.NotSrOnly];
    try assertCss(@src(), [.A11y.SrOnly, Token.Md(shown)]);
}

test "css: a11y ---- forced colour adjust" {
    try assertCss(@src(), [.A11y.ForcedColorAdjust.None, .A11y.ForcedColorAdjust.Auto]);
}
```

`modules/emilia/test/__snapshots__/css/svg-fill-stroke-width-keywords.snap`
```css
.e{fill:currentcolor;stroke:currentcolor;stroke-width:2;fill:none;stroke-width:0}
```

`modules/emilia/test/__snapshots__/css/svg-palette-fill-and-stroke.snap`
```css
.e{fill:var(--color-red-500);stroke:var(--color-blue-500);stroke-width:3}
```

`modules/emilia/test/__snapshots__/css/a11y-sr-only.snap`
```css
.e{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}
```

`modules/emilia/test/__snapshots__/css/a11y-not-sr-only-from-md.snap`
```css
.e{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}
@media (width >= 48rem){.e{position:static;width:auto;height:auto;padding:0;margin:0;overflow:visible;clip:auto;white-space:normal}}
```
The two bodies are the 1.0.8 draft's, carried into 47's README; the front gates them on an upstream
read (`NotSrOnly` may need `border-width` restored). Regenerated by hand if the read changes them.

`modules/emilia/test/__snapshots__/css/a11y-forced-colour-adjust.snap`
```css
.e{forced-color-adjust:none;forced-color-adjust:auto}
```

---

## 48 — attributes · `modules/emilia/test/attributes_test.bp`, `modules/emilia/test/integration_test.bp`

```bp
// attributes_test.bp
import { Token, styled, styledWith, className, mergeClass, assertAsciiBody, fullTheme, emiliaWith, extend, ThemeEntry } from "emilia";
import { assertClassName } from "emilia-test";
import { equal, truthy, falsy } from "std/asserts";

fn cardTokens() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Gray.100];
    val tokens: Token[] = [.Bg.Color.White, .Pad.All.4, .Text.Bold, Token.Hover(hovered)];
    return tokens;
}

test "class: attributes ---- the shared fixture" {
    try assertClassName(@src(), cardTokens());
}

test "class: attributes ---- order is identity" {
    try assertClassName(@src(), [.Color.Black, .Text.Bold]);
}

test "class: attributes ---- reversed order is another class" {
    try assertClassName(@src(), [.Text.Bold, .Color.Black]);
}

test "styled is the class pair" {
    val th = fullTheme();
    val pair = styled(cardTokens(), th);
    equal(pair._0, "class");
    equal(pair._1, emiliaWith(cardTokens(), th));
    equal(className(cardTokens(), th), pair._1);
}

test "a themed value is a different class" {
    val brand: ThemeEntry[] = [ThemeEntry(name: "--spacing", value: "4px")];
    val other = extendTheme(fullTheme(), brand);
    truthy(className(cardTokens(), fullTheme()) != className(cardTokens(), other));
}

test "merge is static first one space no sort no dedup no trim" {
    equal(mergeClass("card", "e_abc"), "card e_abc");
    equal(mergeClass("", "e_abc"), "e_abc");
    equal(mergeClass("card", ""), "card");
    equal(mergeClass("a  b", "e_x"), "a  b e_x");
    equal(styledWith("card", cardTokens(), fullTheme())._1.startsWith("card "), true);
}

test "ascii gate" {
    truthy(assertAsciiBody(cardTokens()));
    val raw: Token[] = [Token.EffectShadowRaw(value: "0 0 0 1px 🚫")];
    falsy(assertAsciiBody(raw));
}
```

```bp
// integration_test.bp — jhonstart is a dev-dependency of the core module
import { Token, cls, styled, fullTheme, flush } from "emilia";
import { div, p, text, renderToString, html } from "jhonstart";
import { classAttr, withAttrs, attrValue } from "jhonstart";
import { equal, contains } from "std/asserts";

fn cardTokens() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Gray.100];
    val tokens: Token[] = [.Bg.Color.White, .Pad.All.4, .Text.Bold, Token.Hover(hovered)];
    return tokens;
}

test "builders and the html DSL produce the same markup" {
    val th = fullTheme();
    val c = cls(cardTokens(), th);
    val built = div([p([text("hi")], [])], [classAttr(c)]);
    val dsl = html """<div [class]={c}><p>hi</p></div>""";
    equal(renderToString(built), renderToString(dsl));
    equal(renderToString(built), "<div class=\"" + c + "\"><p>hi</p></div>");
}

test "the slot appends and reads back" {
    val th = fullTheme();
    val attrs = withAttrs([#("id", "x")], [styled(cardTokens(), th)]);
    equal(attrValue(attrs, "id"), "x");
    equal(attrValue(attrs, "class"), cls(cardTokens(), th));
    equal(attrValue(attrs, "role"), "");
}

test "the flushed selector matches the rendered class" {
    val th = fullTheme();
    val c = cls(cardTokens(), th);
    val css = await flush();
    contains(css, "." + c + "{");
}
```

`modules/emilia/test/__snapshots__/class/attributes-the-shared-fixture.snap`
```
e_<hex>
```
This is contract 4's literal. Rakun 23's SSR test and onze 68's bundle test assert the same string;
all three read it from this file, which is why the file is the contract and not the number.

`modules/emilia/test/__snapshots__/class/attributes-order-is-identity.snap` and
`…/attributes-reversed-order-is-another-class.snap`: two `e_<hex>` lines; a test asserts the files
differ.

---

## 54 — theme · `modules/emilia/test/theme_test.bp`, `modules/emilia/test/spacing_test.bp`

```bp
import { Theme, ThemeEntry, Ns, DarkMode, defaultTheme, emptyTheme, extend, clearNamespace, themeValue, themeVar, nsPrefix, darkSelector, darkAtRule, keyframeCss } from "emilia";
import { assertTheme } from "emilia-test";
import { equal } from "std/asserts";

test "theme: default ---- the static theme" {
    try assertTheme(@src(), defaultTheme());
}

test "theme: default ---- empty theme renders nothing" {
    try assertTheme(@src(), emptyTheme());
}

test "theme: extend ---- brand overrides and adds" {
    val brand: ThemeEntry[] = [
        ThemeEntry(name: "--spacing", value: "4px"),
        ThemeEntry(name: "--color-lagoon", value: "oklch(0.72 0.11 221.19)"),
    ];
    try assertTheme(@src(), extendTheme(emptyTheme(), brand));
}

test "theme: clear ---- colour namespace cleared" {
    val colours: ThemeEntry[] = [
        ThemeEntry(name: "--color-lagoon", value: "oklch(0.72 0.11 221.19)"),
        ThemeEntry(name: "--radius-pill", value: "9999px"),
    ];
    val th = clearNamespace(extendTheme(emptyTheme(), colours), Ns.Color);
    try assertTheme(@src(), th);
}

test "nineteen prefixes" {
    equal(nsPrefix(Ns.Spacing), "--spacing");
    equal(nsPrefix(Ns.Color), "--color-");
    equal(nsPrefix(Ns.Keyframes), "@keyframes ");
}

test "value and var" {
    equal(themeValue(defaultTheme(), "--spacing"), "0.25rem");
    equal(themeValue(emptyTheme(), "--spacing"), "");
    equal(themeVar("--color-lagoon"), "var(--color-lagoon)");
}

test "dark strategies" {
    equal(darkAtRule(defaultTheme()), "@media (prefers-color-scheme: dark)");
    equal(darkSelector(defaultTheme()), "&");
    val byClass = Theme(entries: [], keyframes: [], darkMode: DarkMode.Class(name: "dark"));
    equal(darkAtRule(byClass), "");
    equal(darkSelector(byClass), "&:where(.dark, .dark *)");
    val byAttr = Theme(entries: [], keyframes: [], darkMode: DarkMode.Attribute(name: "data-theme", value: "dark"));
    equal(darkSelector(byAttr), "&:where([data-theme=dark], [data-theme=dark] *)");
}
// `extendTheme(th, [ThemeEntry(name: "--gutter", value: "1rem")])` fails the build naming `--gutter`;
// the case lives in the compiler suite.
```

`modules/emilia/test/__snapshots__/theme/default-the-static-theme.snap`
```
--spacing:0.25rem
--breakpoint-sm:40rem
--breakpoint-md:48rem
--breakpoint-lg:64rem
--breakpoint-xl:80rem
--breakpoint-2xl:96rem
--radius-xs:0.125rem
--radius-sm:0.25rem
--radius-md:0.375rem
--radius-lg:0.5rem
--radius-xl:0.75rem
--radius-2xl:1rem
--radius-3xl:1.5rem
--radius-4xl:2rem
--color-black:#000
--color-white:#fff
--text-xs:0.75rem
--text-xs--line-height:calc(1 / 0.75)
--text-sm:0.875rem
--text-sm--line-height:calc(1.25 / 0.875)
--text-base:1rem
--text-base--line-height:calc(1.5 / 1)
--text-lg:1.125rem
--text-lg--line-height:calc(1.75 / 1.125)
--text-xl:1.25rem
--text-xl--line-height:calc(1.75 / 1.25)
--text-2xl:1.5rem
--text-2xl--line-height:calc(2 / 1.5)
--text-3xl:1.875rem
--text-3xl--line-height:calc(2.25 / 1.875)
--text-4xl:2.25rem
--text-4xl--line-height:calc(2.5 / 2.25)
--text-5xl:3rem
--text-5xl--line-height:1
--text-6xl:3.75rem
--text-6xl--line-height:1
--text-7xl:4.5rem
--text-7xl--line-height:1
--text-8xl:6rem
--text-8xl--line-height:1
--text-9xl:8rem
--text-9xl--line-height:1
--shadow-2xs:0 1px rgb(0 0 0 / 0.05)
--shadow-xs:0 1px 2px 0 rgb(0 0 0 / 0.05)
--shadow-sm:0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)
--shadow-md:0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)
--shadow-lg:0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)
--shadow-xl:0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)
--shadow-2xl:0 25px 50px -12px rgb(0 0 0 / 0.25)
--container-3xs:16rem
--container-2xs:18rem
--container-xs:20rem
--container-sm:24rem
--container-md:28rem
--container-lg:32rem
--container-xl:36rem
--container-2xl:42rem
--container-3xl:48rem
--container-4xl:56rem
--container-5xl:64rem
--container-6xl:72rem
--container-7xl:80rem
--animate-spin:spin 1s linear infinite
--animate-ping:ping 1s cubic-bezier(0, 0, 0.2, 1) infinite
--animate-pulse:pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite
--animate-bounce:bounce 1s infinite
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes ping{75%,100%{transform:scale(2);opacity:0}}
@keyframes pulse{50%{opacity:0.5}}
@keyframes bounce{0%,100%{transform:translateY(-25%);animation-timing-function:cubic-bezier(0.8,0,1,1)}50%{transform:none;animation-timing-function:cubic-bezier(0,0,0.2,1)}}
```
Every value line is a `§ 21.2`–`§ 21.6` or `§ 3.3` row; the order is `defaultTheme()`'s declaration
order, which is why the file doubles as the determinism test.

`modules/emilia/test/__snapshots__/theme/default-empty-theme-renders-nothing.snap` — an empty file
(zero bytes).

`modules/emilia/test/__snapshots__/theme/extend-brand-overrides-and-adds.snap`
```
--spacing:4px
--color-lagoon:oklch(0.72 0.11 221.19)
```

`modules/emilia/test/__snapshots__/theme/clear-colour-namespace-cleared.snap`
```
--radius-pill:9999px
```

`spacing_test.bp` holds the `spacing`/`spacingHalf` equalities shown under 35 (they are 54's; 35
re-asserts nothing about them) and no snapshot.

---

## 55 — preflight · `modules/emilia/test/preflight_test.bp`

```bp
import { Token, preflightRules, preflight, defaultOptions, withBase } from "emilia";
import { assertRules, assertCascade } from "emilia-test";
import { equal, falsy } from "std/asserts";

test "rules: preflight ---- the reset in full" {
    try assertRules(@src(), preflightRules());
}

test "cascade: preflight ---- base layer precedes utilities" {
    val bordered: Token[] = [.Border.W.1];
    val lists: Token[][] = [bordered];
    try assertCascade(@src(), lists, withBase(defaultOptions(), preflightRules()));
}

test "the default document has no base layer" {
    equal(preflightRules().length, 11);
    equal(preflight().startsWith("*,::before,::after{box-sizing:border-box"), true);
    falsy(preflight().contains("@layer"));
}
```

`modules/emilia/test/__snapshots__/rules/preflight-the-reset-in-full.snap`
```css
*,::before,::after{box-sizing:border-box;border-width:0;border-style:solid}
html{line-height:1.5;-webkit-text-size-adjust:100%;tab-size:4}
body{margin:0}
h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit;margin:0}
p,blockquote,figure,pre,dl,dd,hr{margin:0}
ol,ul,menu{list-style:none;margin:0;padding:0}
a{color:inherit;text-decoration:inherit}
img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}
img,video{max-width:100%;height:auto}
button,input,select,optgroup,textarea{font:inherit;color:inherit;margin:0;padding:0;background-color:transparent}
::before,::after{content:""}
```

`modules/emilia/test/__snapshots__/cascade/preflight-base-layer-precedes-utilities.snap` — under
`defaultOptions()` the theme layer is `fullTheme()`, so this file opens with the full `:root` block
(the `theme/default-the-static-theme.snap` lines joined by `;`, then the palette and per-front
entries). Shown here with that block elided; the file on disk is complete:
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;…}}
@layer base{*,::before,::after{box-sizing:border-box;border-width:0;border-style:solid}html{line-height:1.5;-webkit-text-size-adjust:100%;tab-size:4}body{margin:0}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit;margin:0}p,blockquote,figure,pre,dl,dd,hr{margin:0}ol,ul,menu{list-style:none;margin:0;padding:0}a{color:inherit;text-decoration:inherit}img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}img,video{max-width:100%;height:auto}button,input,select,optgroup,textarea{font:inherit;color:inherit;margin:0;padding:0;background-color:transparent}::before,::after{content:""}}
@layer utilities{.e1{border-width:1px}}
```

---

## 56 — cascade and output · `modules/emilia/test/output_test.bp`, `modules/emilia/test/cascade_test.bp`

```bp
// output_test.bp — the model
import { Rule, Sheet, Variant, declSheet, emptySheet, staticSheet, blockSheet, mergeSheet, nestVariant, markImportant, encodeSheet, decodeSheet, renderRule, defaultOptions, withPrefix } from "emilia";
import { assertRules } from "emilia-test";
import { equal } from "std/asserts";

test "rules: output ---- decl sheet is one utilities rule" {
    try assertRules(@src(), declSheet("color:red").rules);
}

test "rules: output ---- nesting twice in both orders" {
    val hover = Variant(atRule: "@media (hover: hover)", selector: "&:hover");
    val before = Variant(atRule: "", selector: "&::before");
    val a = nestVariant(nestVariant(declSheet("color:red"), before), hover);
    val b = nestVariant(nestVariant(declSheet("color:red"), hover), before);
    try assertRules(@src(), mergeSheet(a, b).rules);
}

test "rules: output ---- important per declaration" {
    try assertRules(@src(), markImportant(declSheet("color:red;font-weight:700")).rules);
}

test "rules: output ---- two at rules nest outermost first" {
    val md = Variant(atRule: "@media (width >= 48rem)", selector: "&");
    val dark = Variant(atRule: "@media (prefers-color-scheme: dark)", selector: "&");
    try assertRules(@src(), nestVariant(nestVariant(declSheet("color:red"), md), dark).rules);
}

test "rules: output ---- literal selector ignores the prefix" {
    val s = mergeSheet(staticSheet("base", "html", "line-height:1.5"), declSheet("color:red"));
    val o = withPrefix(defaultOptions(), "tw_");
    val lines: string[] = s.rules.map({ r -> renderRule("e_1", r, o) });
    equal(lines.at(0), "html{line-height:1.5}");
    equal(lines.at(1), ".tw_e_1{color:red}");
}

test "codec round trip" {
    val v = Variant(atRule: "@supports(display:grid)", selector: "&:hover");
    val s = mergeSheet(markImportant(nestVariant(declSheet("display:grid"), v)), blockSheet("@keyframes spin", "to{transform:rotate(360deg)}"));
    equal(encodeSheet(decodeSheet(encodeSheet(s))), encodeSheet(s));
    equal(encodeSheet(emptySheet()), "");
}
// A `Variant` with zero or two `&`, and a declaration containing "\n", "\t" or "\r", fail the
// build; both cases live in the compiler suite.
```

`modules/emilia/test/__snapshots__/rules/output-decl-sheet-is-one-utilities-rule.snap`
```css
{color:red}
```
(`renderRule("", …)` substitutes the empty class for `&`; the bare body is the assertion that
nothing else was added.)

`modules/emilia/test/__snapshots__/rules/output-nesting-twice-in-both-orders.snap`
```css
@media (hover: hover){:hover::before{color:red}}
@media (hover: hover){::before:hover{color:red}}
```

`modules/emilia/test/__snapshots__/rules/output-important-per-declaration.snap`
```css
{color:red!important;font-weight:700!important}
```

`modules/emilia/test/__snapshots__/rules/output-two-at-rules-nest-outermost-first.snap`
```css
@media (prefers-color-scheme: dark){@media (width >= 48rem){{color:red}}}
```

```bp
// cascade_test.bp — order, layers, keyframes, the two-flush contract
import { Token, ThemeEntry, emptyTheme, extend, defaultOptions, withTheme, withLayers, withPrefix, withImportant, emilia, flush } from "emilia";
import { assertCascade } from "emilia-test";
import { equal } from "std/asserts";

fn tinyTheme() -> Theme {
    val entries: ThemeEntry[] = [
        ThemeEntry(name: "--spacing", value: "0.25rem"),
        ThemeEntry(name: "--color-white", value: "#fff"),
        ThemeEntry(name: "--color-gray-100", value: "oklch(0.967 0.003 264.542)"),
        ThemeEntry(name: "--animate-spin", value: "spin 1s linear infinite"),
        ThemeEntry(name: "@keyframes spin", value: "to{transform:rotate(360deg)}"),
    ];
    return extendTheme(emptyTheme(), entries);
}

fn tiny() -> Options {
    return withTheme(defaultOptions(), tinyTheme());
}

test "cascade: output ---- one card hover and breakpoint hoisted" {
    val hovered: Token[] = [.Bg.Color.Gray.100];
    val wide: Token[] = [.Pad.All.8];
    val card: Token[] = [.Bg.Color.White, .Pad.All.4, Token.Hover(hovered), Token.Md(wide)];
    val lists: Token[][] = [card];
    try assertCascade(@src(), lists, tiny());
}

test "cascade: output ---- last rule wins inside one call and across calls" {
    val a: Token[] = [.Layout.Grid, .Layout.Flex];
    val b: Token[] = [.Layout.Block];
    val c: Token[] = [.Layout.Grid, .Layout.Flex];
    val lists: Token[][] = [a, b, c];
    try assertCascade(@src(), lists, tiny());
}

test "cascade: output ---- unconditioned before conditioned within a class" {
    val wide: Token[] = [.Pad.All.8];
    val tokens: Token[] = [Token.Md(wide), .Pad.All.4, .Bg.Color.White];
    val lists: Token[][] = [tokens];
    try assertCascade(@src(), lists, tiny());
}

test "cascade: output ---- keyframes once for three classes" {
    val a: Token[] = [.Animate.Spin];
    val b: Token[] = [.Animate.Spin, .Bg.Color.White];
    val c: Token[] = [.Pad.All.4, .Animate.Spin];
    val lists: Token[][] = [a, b, c];
    try assertCascade(@src(), lists, tiny());
}

test "cascade: output ---- layers off" {
    val tokens: Token[] = [.Bg.Color.White];
    val lists: Token[][] = [tokens];
    try assertCascade(@src(), lists, withLayers(tiny(), false));
}

test "cascade: output ---- prefix and important" {
    val tokens: Token[] = [.Bg.Color.White, .Pad.All.4];
    val lists: Token[][] = [tokens];
    try assertCascade(@src(), lists, withImportant(withPrefix(tiny(), "tw_"), true));
}

test "cascade: output ---- nothing registered" {
    val lists: Token[][] = [];
    try assertCascade(@src(), lists, tiny());
}

test "two flushes are independent and the class collapses" {
    val tokens: Token[] = [.Bg.Color.White];
    val a = emilia(tokens);
    val b = emilia(tokens);
    equal(a, b);
    val first = await flush();
    val second = await flush();
    equal(first.startsWith("<style>@layer theme, base, components, utilities;"), true);
    equal(second.contains("@layer utilities"), false);
}
```

`modules/emilia/test/__snapshots__/cascade/output-one-card-hover-and-breakpoint-hoisted.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer utilities{.e1{background-color:var(--color-white);padding:calc(var(--spacing) * 4)}@media (hover: hover){.e1:hover{background-color:var(--color-gray-100)}}@media (width >= 48rem){.e1{padding:calc(var(--spacing) * 8)}}}
```

`modules/emilia/test/__snapshots__/cascade/output-last-rule-wins-inside-one-call-and-across-calls.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer utilities{.e1{display:grid;display:flex}.e2{display:block}}
```
Three lists, two classes: `a` and `c` are the same token list and collapse to `e1`; `§ 3.1`'s
`grid flex` example is the first rule's body.

`modules/emilia/test/__snapshots__/cascade/output-unconditioned-before-conditioned-within-a-class.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer utilities{.e1{padding:calc(var(--spacing) * 4);background-color:var(--color-white)}@media (width >= 48rem){.e1{padding:calc(var(--spacing) * 8)}}}
```

`modules/emilia/test/__snapshots__/cascade/output-keyframes-once-for-three-classes.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer utilities{.e1{animation:var(--animate-spin)}.e2{animation:var(--animate-spin);background-color:var(--color-white)}.e3{padding:calc(var(--spacing) * 4);animation:var(--animate-spin)}}
@keyframes spin{to{transform:rotate(360deg)}}
```

`modules/emilia/test/__snapshots__/cascade/output-layers-off.snap`
```css
:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}
.e1{background-color:var(--color-white)}
```

`modules/emilia/test/__snapshots__/cascade/output-prefix-and-important.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer utilities{.tw_e1{background-color:var(--color-white)!important;padding:calc(var(--spacing) * 4)!important}}
```

`modules/emilia/test/__snapshots__/cascade/output-nothing-registered.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
```
No `@layer utilities` body and no `@keyframes` block: the keyframe entry of the theme is emitted only
when a registered class references its animation.

---

## 57 — escape hatches · `modules/emilia/test/arbitrary_test.bp`

```bp
import { Token, arbValue, arbProp, arbSel, arbAt, arbMin, arbMax, spacing, themeVar, paletteVar } from "emilia";
import { assertCss, assertUtility } from "emilia-test";

test "css: arbitrary ---- value and property" {
    val tokens: Token[] = [arbValue("background-color", "#316ff6"), arbProp("--gutter-width", spacing(4))];
    try assertCss(@src(), tokens);
}

test "css: arbitrary ---- theme composes into a value" {
    val tokens: Token[] = [
        arbValue("max-height", "calc(100dvh - " + spacing(6) + ")"),
        arbValue("color", themeVar("--color-brand")),
        arbValue("outline-color", paletteVar("indigo", "500")),
    ];
    try assertCss(@src(), tokens);
}

test "css: arbitrary ---- selector variant" {
    val dragging: Token[] = [.Effect.Shadow.Lg, .Effect.Opacity.75];
    val tokens: Token[] = [arbSel("&.is-dragging", dragging)];
    try assertCss(@src(), tokens);
}

test "css: arbitrary ---- supports query" {
    val grid: Token[] = [.Layout.Grid];
    val tokens: Token[] = [arbAt("supports(display:grid)", grid)];
    try assertCss(@src(), tokens);
}

test "css: arbitrary ---- min and max breakpoints" {
    val centered: Token[] = [.Text.Center];
    val stacked: Token[] = [.Flex.Col];
    val tokens: Token[] = [arbMin("320px", centered), arbMax("600px", stacked)];
    try assertCss(@src(), tokens);
}

test "css: arbitrary ---- selector variant inside md" {
    val dragging: Token[] = [.Effect.Opacity.75];
    val sel: Token[] = [arbSel("&.is-dragging", dragging)];
    val tokens: Token[] = [Token.Md(sel)];
    try assertCss(@src(), tokens);
}

test "ast: arbitrary ---- min is hoisted not nested" {
    val centered: Token[] = [.Text.Center];
    try assertUtility(@src(), arbMin("320px", centered));
}
// `cssValue """red}</style><script>"""` fails the build with a message containing the rejected
// text; `arbValue("color", "red}</style>")` panics naming the property and the payload, with the
// same message on both targets. Both cases live in the compiler suite.
```

`modules/emilia/test/__snapshots__/css/arbitrary-value-and-property.snap`
```css
.e{background-color:#316ff6;--gutter-width:calc(var(--spacing) * 4)}
```

`modules/emilia/test/__snapshots__/css/arbitrary-theme-composes-into-a-value.snap`
```css
.e{max-height:calc(100dvh - calc(var(--spacing) * 6));color:var(--color-brand);outline-color:var(--color-indigo-500)}
```

`modules/emilia/test/__snapshots__/css/arbitrary-selector-variant.snap`
```css
.e.is-dragging{box-shadow:var(--shadow-lg);opacity:0.75}
```

`modules/emilia/test/__snapshots__/css/arbitrary-supports-query.snap`
```css
@supports(display:grid){.e{display:grid}}
```

`modules/emilia/test/__snapshots__/css/arbitrary-min-and-max-breakpoints.snap`
```css
@media (width >= 320px){.e{text-align:center}}
@media (width < 600px){.e{flex-direction:column}}
```

`modules/emilia/test/__snapshots__/css/arbitrary-selector-variant-inside-md.snap`
```css
@media (width >= 48rem){.e.is-dragging{opacity:0.75}}
```

`modules/emilia/test/__snapshots__/ast/arbitrary-min-is-hoisted-not-nested.snap`
```
utilities | @media (width >= 320px) | & | text-align:center | false
```

---

## 58 — container queries · `modules/emilia/test/container_test.bp`

```bp
import { Token, ContainerSize, containerKey, containerAt, containerAtMd, containerAt2xl, containerAtSm, containerNamed, ThemeEntry, fullTheme, extend } from "emilia";
import { assertCss, assertCssWith } from "emilia-test";
import { equal } from "std/asserts";

test "css: container ---- markers" {
    val tokens: Token[] = [.Container.Inline, .Container.Normal, .Container.Size];
    try assertCss(@src(), tokens);
}

test "css: container ---- named container shell" {
    val tokens: Token[] = [Token.ContainerNamed(name: "page"), .Layout.Block];
    try assertCss(@src(), tokens);
}

test "css: container ---- card responds to its container" {
    val row: Token[] = [.Flex.Row, .Flex.Items.Center, .Gap.All.4];
    val roomy: Token[] = [.Pad.All.8];
    val tokens: Token[] = [.Bg.Color.White, .Layout.Flex, .Flex.Col, containerAtMd(row), containerAt2xl(roomy)];
    try assertCss(@src(), tokens);
}

test "css: container ---- named query" {
    val row: Token[] = [.Flex.Row];
    val tokens: Token[] = [.Layout.Flex, .Flex.Col, containerNamed(ContainerSize.X3xl, "page", row)];
    try assertCss(@src(), tokens);
}

test "css: container ---- inside hover" {
    val row: Token[] = [.Flex.Row];
    val sm: Token[] = [containerAtSm(row)];
    val tokens: Token[] = [Token.Hover(sm)];
    try assertCss(@src(), tokens);
}

test "css: container ---- narrowed theme changes the query" {
    val row: Token[] = [.Flex.Row];
    val narrow: ThemeEntry[] = [ThemeEntry(name: "--container-md", value: "20rem")];
    val tokens: Token[] = [containerAtMd(row)];
    try assertCssWith(@src(), tokens, extendTheme(fullTheme(), narrow));
}

test "keys and the thirteen sizes" {
    equal(containerKey(ContainerSize.X3xs), "3xs");
    equal(containerKey(ContainerSize.Md), "md");
    equal(containerKey(ContainerSize.X7xl), "7xl");
}
// `containerAtMd(...)` under `clearNamespace(th, Ns.Container)` panics; never `@container (width >= )`.
```

`modules/emilia/test/__snapshots__/css/container-markers.snap`
```css
.e{container-type:inline-size;container-type:normal;container-type:size}
```

`modules/emilia/test/__snapshots__/css/container-named-container-shell.snap`
```css
.e{container-type:inline-size;container-name:page;display:block}
```

`modules/emilia/test/__snapshots__/css/container-card-responds-to-its-container.snap`
```css
.e{background-color:var(--color-white);display:flex;flex-direction:column}
@container (width >= 28rem){.e{flex-direction:row;align-items:center;gap:calc(var(--spacing) * 4)}}
@container (width >= 42rem){.e{padding:calc(var(--spacing) * 8)}}
```

`modules/emilia/test/__snapshots__/css/container-named-query.snap`
```css
.e{display:flex;flex-direction:column}
@container page (width >= 48rem){.e{flex-direction:row}}
```

`modules/emilia/test/__snapshots__/css/container-inside-hover.snap`
```css
@media (hover: hover){@container (width >= 24rem){.e:hover{flex-direction:row}}}
```

`modules/emilia/test/__snapshots__/css/container-narrowed-theme-changes-the-query.snap`
```css
@container (width >= 20rem){.e{flex-direction:row}}
```

---

## 59 — custom utilities and variants · `modules/emilia/test/compose_test.bp`

```bp
import { Token, Variant, compose, named, hocus, selector, themeMidnight, scrollbarHidden, emilia, defaultOptions, flushWith } from "emilia";
import { assertCss, assertCascade, assertClassName } from "emilia-test";
import { equal } from "std/asserts";

fn buttonBase() -> Token[] {
    val tokens: Token[] = [.Border.Rounded.Md, .Pad.X.4, .Pad.Y.2, .Font.Weight.Bold];
    return tokens;
}

fn primarySkin() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Blue.700];
    val base: Token[] = [.Bg.Color.Blue.500, .Color.White];
    return base.append(hocus(hovered));
}

test "css: compose ---- a bundle is a token list" {
    try assertCss(@src(), buttonBase());
}

test "css: compose ---- hocus is hover and focus" {
    val bold: Token[] = [.Text.Bold];
    try assertCss(@src(), hocus(bold));
}

test "css: compose ---- composed bundles keep order so the later wins" {
    val a: Token[] = [.Bg.Color.White, .Text.Bold];
    val b: Token[] = [.Bg.Color.Black];
    val lists: Token[][] = [a, b];
    try assertCss(@src(), compose(lists));
}

test "css: compose ---- custom variant" {
    val white: Token[] = [.Color.White];
    try assertCss(@src(), themeMidnight(white));
}

test "css: compose ---- selector helper" {
    val v = Variant(atRule: "", selector: "&[aria-busy=\"true\"]");
    val dim: Token[] = [.Effect.Opacity.50];
    val tokens: Token[] = [selector(v, dim)];
    try assertCss(@src(), tokens);
}

test "css: compose ---- scrollbar hidden" {
    try assertCss(@src(), scrollbarHidden());
}

test "css: compose ---- the primary button" {
    val midnight: Token[] = [.Bg.Color.Black, .Color.White];
    val lists: Token[][] = [buttonBase(), primarySkin(), themeMidnight(midnight)];
    try assertCss(@src(), compose(lists));
}

test "cascade: compose ---- a named utility lands in components" {
    val _btn = named("btn", compose([buttonBase(), primarySkin()]));
    val extra: Token[] = [.Text.Center];
    val lists: Token[][] = [extra];
    try assertCascade(@src(), lists, withTheme(defaultOptions(), tinyTheme()));
}

test "class: compose ---- naming does not change the hashed class" {
    try assertClassName(@src(), compose([buttonBase(), primarySkin()]));
}

test "named returns its name and compose of nothing is emilia of nothing" {
    equal(named("btn", buttonBase()), "btn");
    val nothing: Token[][] = [];
    val none: Token[] = [];
    equal(emilia(compose(nothing)), emilia(none));
}
// `named("e_abc", …)`, a name outside `cssIdent`, and `named("btn", …)` twice with different tokens
// are refused; the cases live in the compiler suite.
```

`modules/emilia/test/__snapshots__/css/compose-a-bundle-is-a-token-list.snap`
```css
.e{border-radius:var(--radius-md);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);font-weight:700}
```

`modules/emilia/test/__snapshots__/css/compose-hocus-is-hover-and-focus.snap`
```css
.e:focus{font-weight:bold}
@media (hover: hover){.e:hover{font-weight:bold}}
```
`hocus` returns `[Hover(inner), Focus(inner)]`; the focus rule renders first because rules without
an at-rule precede rules with one inside a class (56, order rule 5).

`modules/emilia/test/__snapshots__/css/compose-composed-bundles-keep-order-so-the-later-wins.snap`
```css
.e{background-color:var(--color-white);font-weight:bold;background-color:var(--color-black)}
```

`modules/emilia/test/__snapshots__/css/compose-custom-variant.snap`
```css
.e:where([data-theme="midnight"] *){color:var(--color-white)}
```

`modules/emilia/test/__snapshots__/css/compose-selector-helper.snap`
```css
.e[aria-busy="true"]{opacity:0.5}
```

`modules/emilia/test/__snapshots__/css/compose-scrollbar-hidden.snap`
```css
.e{scrollbar-width:none}
.e::-webkit-scrollbar{display:none}
```

`modules/emilia/test/__snapshots__/css/compose-the-primary-button.snap`
```css
.e{border-radius:var(--radius-md);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);font-weight:700;background-color:var(--color-blue-500);color:var(--color-white)}
.e:focus{background-color:var(--color-blue-700)}
.e:where([data-theme="midnight"] *){background-color:var(--color-black);color:var(--color-white)}
@media (hover: hover){.e:hover{background-color:var(--color-blue-700)}}
```

`modules/emilia/test/__snapshots__/cascade/compose-a-named-utility-lands-in-components.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-gray-100:oklch(0.967 0.003 264.542);--animate-spin:spin 1s linear infinite}}
@layer components{.btn{border-radius:var(--radius-md);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);font-weight:700;background-color:var(--color-blue-500);color:var(--color-white)}.btn:focus{background-color:var(--color-blue-700)}@media (hover: hover){.btn:hover{background-color:var(--color-blue-700)}}}
@layer utilities{.e1{text-align:center}}
```
`assertCascade` rewrites only hashed class names; `.btn` is a literal and stays.

---

## Coverage of the acceptance criteria

| Front | Acceptance items pinned by a `.snap` above | Left to plain asserts / the compiler suite |
|---|---|---|
| 33 | 26 × 11 shape (family-per-test files, two shown), keywords, `Alpha` over one and two colours and inside `Hover`, palette entries, class literal | `paletteEntries().length`, no `@theme` in output, no `//` inside `Token` |
| 34 | the `§ 3.2` selector for every group (variant snaps + rendered), all five breakpoints both ways, triple nesting, indexed structural, pseudo-element spacing, group/peer, direction/descent, empty inner | 36 nullary variants each once (one `css:` test per name in the real file, same shape as shown) |
| 35 | scale, `Px`, `Half`, axes and logical sides, `Auto`, `Neg`, every `Size` form, `Space` selector | `spacing()` equalities; `grep -E '[0-9]rem'` on the front's block |
| 36 | display, position/inset/z, overflow/overscroll/visibility, float/clear/isolation, object/aspect, columns/break, box | — |
| 37 | direction/value/grow/shrink/basis/order, alignment asymmetry, grid template/span/start/keywords, flow/auto tracks, gap forms, legacy `Flex.Gap` ≡ `Gap.All` | — |
| 38 | size+line-height, family/weight/smoothing, tracking/leading, decoration, clamp/truncate, transform/overflow/wrap/whitespace/break/hyphens, indent/align/tab/content, stretch/nums/style, list | theme entries (`--font-weight-*`, `--tracking-*`, `--leading-*`) via a `theme:` snapshot in the real file |
| 39 | attachment/clip/origin, position/repeat/size/image, `To`/`From`/`Via`/`Stop`, transparent stop, dark composition | — |
| 40 | width/style/colour/radius, per side, corners, keywords, outline none/dashed/negative, focus-visible outline, ring stack, divide selector + colour + reverse | selector byte-equality with 35 (cross-file `contains`) |
| 41 | shadow ladder/none/inner/inset, text shadow, opacity leading zero, blend, mask, raw payloads, hover lift | no `rgb(` literal in the front's block except `Inner` |
| 42 | `none`, blur+grayscale composition, brightness/contrast forms, hue/invert/saturate/sepia, drop shadow, backdrop forms, raw | every non-`None` arm ends in `filter:var(--tw-filter)` (walk) |
| 43 | collapse/separate/layout/caption, spacing forms incl. `0 0`, raw, `Md` | — |
| 44 | presets, `Base` eleven properties, duration/delay/ease/behavior, override order, keyframes once, `None` no block, all four animations, raw | keyframe bodies pasted after the upstream read |
| 45 | rotate/neg, scale vs zoom, translate vars+shorthand, px/spacing, skew/origin/style/backface, perspective, gpu shorthand, hover lift | `skew-x` upstream check |
| 46 | cursors, pointer/resize/select/will-change/touch, scroll m/p, scrollbar/snap, appearance/scheme/field-sizing, three colour payloads | all 36 cursor arms (one `css:` per leaf in the real file) |
| 47 | fill/stroke/width keywords, palette payloads, sr-only, not-sr-only, forced colour | sr-only bodies after the upstream read |
| 48 | the contract 4 literal, order-is-identity, the jhonstart round trip | `styled`/`mergeClass`/ASCII equalities |
| 54 | the default theme entry by entry incl. keyframes, empty, extend/override, clear | nineteen prefixes, `themeValue`/`themeVar`, dark strategies, refusal |
| 55 | eleven rules in order, base before utilities | `preflight()` string properties |
| 56 | decl sheet, nesting both orders, important, two at-rules, hoisting, last-wins in and across calls, partition order, keyframe dedup, layers off, prefix+important, empty document | codec round trip, two-flush independence, literal selector ignoring prefix, refusals |
| 57 | value/property, theme composition, selector variant, supports, min/max, variant under `Md`, hoisted AST | validator refusals |
| 58 | markers, named shell, size ladder (28/42rem), named query, hover composition, narrowed theme | thirteen keys, cleared-namespace panic |
| 59 | bundle, `hocus`, compose order, custom variant, selector helper, scrollbar, the button, components layer, class stability under `named` | `named` return, empty compose, refusals |
