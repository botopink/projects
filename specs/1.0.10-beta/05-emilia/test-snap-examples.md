# test-snap-examples — the snapshot-test map of `repository/emilia/examples/**`

**Track:** D — emilia · **Contract:** as in [`test-snap.md`](./test-snap.md) — `@src()`, `snapshots.path(loc)`, `<path>.new` on mismatch, no update flag, one `.snap` shared by `commonJS` and `erlang`.

Nine example packages ([`modules.md`](./modules.md) § examples). Each is
`examples/<name>/{botopink.json, src/main.bp, test/main_test.bp, test/__snapshots__/}` and builds under
the examples gate. Snapshot paths are relative to `repository/emilia/`. The example's `src/main.bp`
exports the token-list functions its test imports; `main()` prints the rendered page and is not
tested. Every example that flushes a document uses a small explicit theme through
`withTheme(defaultOptions(), …)` so the `@layer theme` line stays readable; `fullTheme()` is exercised
by the modules' own tests.

```jsonc
// examples/<name>/botopink.json — the shape every example uses
{ "name": "<name>", "target": "commonJS", "targets": ["commonJS", "erlang"], "src": "src/",
  "files": ["main.bp"], "dependencies": ["emilia"], "devDependencies": ["emilia-test"] }
```

---

## `examples/emilia-card` — the existing example, on the 1.0.10 surface

`src/main.bp` keeps its three token lists (`cardTokens`, `titleTokens`, `bodyTokens`) and its
jhonstart page; the numeric leaves keep the `.Pad.All.4` spelling and the palette moves to
`.Color.Red.500` / `.Bg.Color.White`. `dependencies: ["emilia", "jhonstart"]`.

```bp
import { cardTokens, titleTokens, bodyTokens, tinyTheme } from "main";
import { Token, defaultOptions, withTheme } from "emilia";
import { assertCss, assertCascade, assertClassName } from "emilia-test";

test "css: card ---- the card surface" {
    try assertCss(@src(), cardTokens());
}

test "css: card ---- the title" {
    try assertCss(@src(), titleTokens());
}

test "css: card ---- the body with hover and md" {
    try assertCss(@src(), bodyTokens());
}

test "cascade: card ---- the page document" {
    val lists: Token[][] = [cardTokens(), titleTokens(), bodyTokens(), cardTokens()];
    try assertCascade(@src(), lists, withTheme(defaultOptions(), tinyTheme()));
}

test "class: card ---- the card class is stable" {
    try assertClassName(@src(), cardTokens());
}
```

`examples/emilia-card/test/__snapshots__/css/card-the-card-surface.snap`
```css
.e{padding:calc(var(--spacing) * 4);background-color:var(--color-white);color:var(--color-black)}
```

`examples/emilia-card/test/__snapshots__/css/card-the-title.snap`
```css
.e{font-size:var(--text-3xl);line-height:var(--text-3xl--line-height);font-weight:bold;color:var(--color-red-500)}
```

`examples/emilia-card/test/__snapshots__/css/card-the-body-with-hover-and-md.snap`
```css
.e{font-size:var(--text-base);line-height:var(--text-base--line-height);color:var(--color-gray-500)}
@media (hover: hover){.e:hover{color:var(--color-red-500)}}
@media (width >= 48rem){.e{font-size:var(--text-lg);line-height:var(--text-lg--line-height)}}
```

`examples/emilia-card/test/__snapshots__/cascade/card-the-page-document.snap`
(`tinyTheme()` = `--spacing`, `--color-white`, `--color-black`, `--color-red-500`, `--color-gray-500`, the four `--text-*` pairs used)
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-black:#000;--color-red-500:oklch(0.637 0.237 25.331);--color-gray-500:oklch(0.551 0.027 264.364);--text-base:1rem;--text-base--line-height:calc(1.5 / 1);--text-lg:1.125rem;--text-lg--line-height:calc(1.75 / 1.125);--text-3xl:1.875rem;--text-3xl--line-height:calc(2.25 / 1.875)}}
@layer utilities{.e1{padding:calc(var(--spacing) * 4);background-color:var(--color-white);color:var(--color-black)}.e2{font-size:var(--text-3xl);line-height:var(--text-3xl--line-height);font-weight:bold;color:var(--color-red-500)}.e3{font-size:var(--text-base);line-height:var(--text-base--line-height);color:var(--color-gray-500)}@media (hover: hover){.e3:hover{color:var(--color-red-500)}}@media (width >= 48rem){.e3{font-size:var(--text-lg);line-height:var(--text-lg--line-height)}}}
```
Four lists, three classes: the fourth registration is the first list again and collapses to `e1`.

`examples/emilia-card/test/__snapshots__/class/card-the-card-class-is-stable.snap`
```
e_<hex>
```

---

## `examples/theme-brand` — 54 · 33

`src/main.bp`: `brandTheme()` (the `§ 21.7` theme: default extended, colour namespace cleared, four
brand variables), `card()` = `[.Bg.Color.Lagoon…]` is not possible — brand colours are not palette
leaves — so the card uses `arbValue("background-color", themeVar("--color-lagoon"))` beside
`.Pad.All.4` and `.Text.Bold`.

```bp
import { brandTheme, card } from "main";
import { Token, ThemeEntry, defaultOptions, withTheme, themeValue, defaultTheme, emptyTheme, extend, clearNamespace, Ns } from "emilia";
import { assertTheme, assertCssWith, assertCascade } from "emilia-test";
import { equal } from "std/asserts";

test "theme: brand ---- the brand variables" {
    val brand: ThemeEntry[] = [
        ThemeEntry(name: "--spacing", value: "4px"),
        ThemeEntry(name: "--font-body", value: "Inter, sans-serif"),
        ThemeEntry(name: "--color-lagoon", value: "oklch(0.72 0.11 221.19)"),
        ThemeEntry(name: "--color-coral", value: "oklch(0.74 0.17 40.24)"),
    ];
    try assertTheme(@src(), extendTheme(emptyTheme(), brand));
}

test "css: brand ---- the card references the theme" {
    try assertCssWith(@src(), card(), brandTheme());
}

test "cascade: brand ---- the document carries the brand spacing" {
    val brandOnly = clearNamespace(clearNamespace(brandTheme(), Ns.Text), Ns.Shadow);
    val lists: Token[][] = [card()];
    try assertCascade(@src(), lists, withTheme(defaultOptions(), clearNamespace(clearNamespace(clearNamespace(clearNamespace(brandOnly, Ns.Radius), Ns.Container), Ns.Animate), Ns.Breakpoint)));
}

test "the stock palette is gone and the brand is reachable" {
    equal(themeValue(brandTheme(), "--color-white"), "");
    equal(themeValue(brandTheme(), "--color-lagoon"), "oklch(0.72 0.11 221.19)");
    equal(themeValue(defaultTheme(), "--spacing"), "0.25rem");
}
```

`examples/theme-brand/test/__snapshots__/theme/brand-the-brand-variables.snap`
```
--spacing:4px
--font-body:Inter, sans-serif
--color-lagoon:oklch(0.72 0.11 221.19)
--color-coral:oklch(0.74 0.17 40.24)
```

`examples/theme-brand/test/__snapshots__/css/brand-the-card-references-the-theme.snap`
```css
.e{background-color:var(--color-lagoon);padding:calc(var(--spacing) * 4);font-weight:bold}
```

`examples/theme-brand/test/__snapshots__/cascade/brand-the-document-carries-the-brand-spacing.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:4px;--font-body:Inter, sans-serif;--color-lagoon:oklch(0.72 0.11 221.19);--color-coral:oklch(0.74 0.17 40.24)}}
@layer utilities{.e1{background-color:var(--color-lagoon);padding:calc(var(--spacing) * 4);font-weight:bold}}
```
`extend` overrides in place, so `--spacing:4px` keeps the position `defaultTheme()` gave `--spacing`
— first — and the four keyframes cleared with `Ns.Animate` leave no `@keyframes` line.

---

## `examples/dashboard-layout` — 35 · 36 · 37 · 58

`src/main.bp`: `shell()` (sticky header over a twelve-column grid), `sidebar()` (span 3, hidden under
`md`), `panel()` (a container whose card goes to a row at `@md`).

```bp
import { shell, header, sidebar, panel, card } from "main";
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: dashboard ---- the grid shell" {
    try assertCss(@src(), shell());
}

test "css: dashboard ---- the sticky header" {
    try assertCss(@src(), header());
}

test "css: dashboard ---- the sidebar spans three and hides under md" {
    try assertCss(@src(), sidebar());
}

test "css: dashboard ---- the panel is a container" {
    try assertCss(@src(), panel());
}

test "css: dashboard ---- the card responds to the panel" {
    try assertCss(@src(), card());
}
```

with

```bp
pub fn shell() -> Token[] {
    val tokens: Token[] = [.Layout.Grid, .Grid.Cols.12, .Gap.All.4, .Size.MinH.Screen, .Pad.All.6, .Size.MaxW.X7xl, .Margin.X.Auto];
    return tokens;
}
pub fn header() -> Token[] {
    val tokens: Token[] = [.Grid.Col.Span.Full, .Layout.Position.Sticky, .Layout.Inset.T.0, .Layout.Z.50, .Bg.Color.White, .Border.W.B.1, .Border.Color.Slate.200];
    return tokens;
}
pub fn sidebar() -> Token[] {
    val shown: Token[] = [.Layout.Block];
    val tokens: Token[] = [.Grid.Col.Span.3, .Layout.Hidden, Token.Md(shown), .Space.Y.2];
    return tokens;
}
pub fn panel() -> Token[] {
    val tokens: Token[] = [.Grid.Col.Span.9, .Container.Inline, .Layout.Flex, .Flex.Col, .Gap.Y.4];
    return tokens;
}
pub fn card() -> Token[] {
    val row: Token[] = [.Flex.Row, .Flex.Items.Center, .Flex.Justify.Between];
    val tokens: Token[] = [.Layout.Flex, .Flex.Col, .Pad.All.4, .Border.Rounded.Lg, .Bg.Color.White, containerAtMd(row)];
    return tokens;
}
```

`examples/dashboard-layout/test/__snapshots__/css/dashboard-the-grid-shell.snap`
```css
.e{display:grid;grid-template-columns:repeat(12, minmax(0, 1fr));gap:calc(var(--spacing) * 4);min-height:100vh;padding:calc(var(--spacing) * 6);max-width:80rem;margin-left:auto;margin-right:auto}
```

`examples/dashboard-layout/test/__snapshots__/css/dashboard-the-sticky-header.snap`
```css
.e{grid-column:1 / -1;position:sticky;top:0;z-index:50;background-color:var(--color-white);border-bottom-width:1px;border-color:var(--color-slate-200)}
```

`examples/dashboard-layout/test/__snapshots__/css/dashboard-the-sidebar-spans-three-and-hides-under-md.snap`
```css
.e{grid-column:span 3 / span 3;display:none}
.e > :not(:last-child){margin-block-end:calc(var(--spacing) * 2)}
@media (width >= 48rem){.e{display:block}}
```
The `Space.Y.2` sibling rule has no at-rule and precedes the `Md` rule (56, order rule 5), even
though it was listed after it.

`examples/dashboard-layout/test/__snapshots__/css/dashboard-the-panel-is-a-container.snap`
```css
.e{grid-column:span 9 / span 9;container-type:inline-size;display:flex;flex-direction:column;row-gap:calc(var(--spacing) * 4)}
```

`examples/dashboard-layout/test/__snapshots__/css/dashboard-the-card-responds-to-the-panel.snap`
```css
.e{display:flex;flex-direction:column;padding:calc(var(--spacing) * 4);border-radius:var(--radius-lg);background-color:var(--color-white)}
@container (width >= 28rem){.e{flex-direction:row;align-items:center;justify-content:space-between}}
```

---

## `examples/typography-article` — 38 · 55 · 34

`src/main.bp`: `prose()`, `heading()`, `lede()` (a first-letter drop cap and a three-line clamp),
and a page flushed with preflight on.

```bp
import { prose, heading, lede } from "main";
import { Token, preflightRules, defaultOptions, withBase, withTheme, emptyTheme, extend, ThemeEntry } from "emilia";
import { assertCss, assertCascade } from "emilia-test";

test "css: article ---- prose measure and leading" {
    try assertCss(@src(), prose());
}

test "css: article ---- heading" {
    try assertCss(@src(), heading());
}

test "css: article ---- lede with drop cap and clamp" {
    try assertCss(@src(), lede());
}

test "cascade: article ---- reset first then the heading" {
    val entries: ThemeEntry[] = [
        ThemeEntry(name: "--spacing", value: "0.25rem"),
        ThemeEntry(name: "--text-4xl", value: "2.25rem"),
        ThemeEntry(name: "--text-4xl--line-height", value: "calc(2.5 / 2.25)"),
        ThemeEntry(name: "--tracking-tight", value: "-0.025em"),
    ];
    val lists: Token[][] = [heading()];
    try assertCascade(@src(), lists, withBase(withTheme(defaultOptions(), extendTheme(emptyTheme(), entries)), preflightRules()));
}
```

with

```bp
pub fn prose() -> Token[] {
    val tokens: Token[] = [.Size.MaxW.X2xl, .Margin.X.Auto, .Font.Serif, .Text.Size.Lg, .Text.Leading.Relaxed, .Text.Wrap.Pretty, .Text.Hyphens.Auto];
    return tokens;
}
pub fn heading() -> Token[] {
    val tokens: Token[] = [.Text.Size.X4xl, .Font.Weight.Extrabold, .Text.Tracking.Tight, .Text.Wrap.Balance, .Margin.B.6];
    return tokens;
}
pub fn lede() -> Token[] {
    val cap: Token[] = [.Text.Size.X5xl, .Font.Weight.Bold, .Layout.Float.Start, .Margin.R.2];
    val tokens: Token[] = [.Text.Clamp.3, .Text.Size.Xl, .Color.Slate.700, Token.FirstLetter(cap)];
    return tokens;
}
```

`examples/typography-article/test/__snapshots__/css/article-prose-measure-and-leading.snap`
```css
.e{max-width:42rem;margin-left:auto;margin-right:auto;font-family:var(--font-serif);font-size:var(--text-lg);line-height:var(--text-lg--line-height);line-height:var(--leading-relaxed);text-wrap:pretty;hyphens:auto}
```

`examples/typography-article/test/__snapshots__/css/article-heading.snap`
```css
.e{font-size:var(--text-4xl);line-height:var(--text-4xl--line-height);font-weight:800;letter-spacing:var(--tracking-tight);text-wrap:balance;margin-bottom:calc(var(--spacing) * 6)}
```

`examples/typography-article/test/__snapshots__/css/article-lede-with-drop-cap-and-clamp.snap`
```css
.e{overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3;font-size:var(--text-xl);line-height:var(--text-xl--line-height);color:var(--color-slate-700)}
.e::first-letter{font-size:var(--text-5xl);line-height:var(--text-5xl--line-height);font-weight:700;float:inline-start;margin-right:calc(var(--spacing) * 2)}
```

`examples/typography-article/test/__snapshots__/cascade/article-reset-first-then-the-heading.snap`
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--text-4xl:2.25rem;--text-4xl--line-height:calc(2.5 / 2.25);--tracking-tight:-0.025em}}
@layer base{*,::before,::after{box-sizing:border-box;border-width:0;border-style:solid}html{line-height:1.5;-webkit-text-size-adjust:100%;tab-size:4}body{margin:0}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit;margin:0}p,blockquote,figure,pre,dl,dd,hr{margin:0}ol,ul,menu{list-style:none;margin:0;padding:0}a{color:inherit;text-decoration:inherit}img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}img,video{max-width:100%;height:auto}button,input,select,optgroup,textarea{font:inherit;color:inherit;margin:0;padding:0;background-color:transparent}::before,::after{content:""}}
@layer utilities{.e1{font-size:var(--text-4xl);line-height:var(--text-4xl--line-height);font-weight:800;letter-spacing:var(--tracking-tight);text-wrap:balance;margin-bottom:calc(var(--spacing) * 6)}}
```
`h1{font-size:inherit}` in `base` loses to the utility in `utilities` by layer order, which is the
whole reason the layers exist.

---

## `examples/interactive-button` — 34 · 40 · 41 · 44 · 45 · 46

`src/main.bp`: `button()` — the one component that touches six fronts.

```bp
import { button } from "main";
import { Token } from "emilia";
import { assertCss, assertUtility } from "emilia-test";

test "css: button ---- rest hover focus visible active disabled" {
    try assertCss(@src(), button());
}

test "ast: button ---- the focus ring is one rule" {
    val ring: Token[] = [.Ring.W.2, .Ring.Color.Indigo.500, .Ring.Offset.W.2];
    try assertUtility(@src(), Token.FocusVisible(ring));
}
```

with

```bp
pub fn button() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Indigo.700, .Effect.Shadow.Md, .Transform.Scale.105];
    val ring: Token[] = [.Ring.W.2, .Ring.Color.Indigo.500, .Ring.Offset.W.2];
    val pressed: Token[] = [.Transform.Scale.95];
    val off: Token[] = [.Effect.Opacity.50, .Interact.Cursor.NotAllowed, .Interact.PointerEvents.None];
    val tokens: Token[] = [
        .Layout.InlineFlex, .Flex.Items.Center, .Gap.X.2,
        .Pad.X.4, .Pad.Y.2, .Border.Rounded.Md,
        .Bg.Color.Indigo.600, .Color.White, .Font.Weight.Semibold,
        .Effect.Shadow.Sm, .Outline.Style.None, .Interact.Cursor.Pointer, .Interact.Select.None,
        .Transition.Base, .Transition.Duration.150,
        Token.Hover(hovered), Token.FocusVisible(ring), Token.Active(pressed), Token.Disabled(off),
    ];
    return tokens;
}
```

`examples/interactive-button/test/__snapshots__/css/button-rest-hover-focus-visible-active-disabled.snap`
```css
.e{display:inline-flex;align-items:center;column-gap:calc(var(--spacing) * 2);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);border-radius:var(--radius-md);background-color:var(--color-indigo-600);color:var(--color-white);font-weight:600;box-shadow:var(--shadow-sm);outline:2px solid transparent;outline-offset:2px;cursor:pointer;user-select:none;transition-property:color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter;transition-timing-function:var(--ease-out);transition-duration:150ms;transition-duration:150ms}
.e:focus-visible{--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);--tw-ring-color:var(--color-indigo-500);--tw-ring-offset-width:2px}
.e:active{scale:.95}
.e:disabled{opacity:0.5;cursor:not-allowed;pointer-events:none}
@media (hover: hover){.e:hover{background-color:var(--color-indigo-700);box-shadow:var(--shadow-md);scale:1.05}}
```

`examples/interactive-button/test/__snapshots__/ast/button-the-focus-ring-is-one-rule.snap`
```
utilities | - | &:focus-visible | --tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);--tw-ring-color:var(--color-indigo-500);--tw-ring-offset-width:2px | false
```
Three declaration tokens under one variant coalesce into one rule before the variant is applied.

---

## `examples/dark-mode-nav` — 34 · 54

`src/main.bp`: `navBar()` (front 34's example nav: hidden under `sm`, a row from `md`, dark surface,
group-hover reveal) and three themes differing only in `darkMode`.

```bp
import { shell, link, mediaTheme, classTheme, attrTheme } from "main";
import { Token, defaultOptions, withTheme } from "emilia";
import { assertCss, assertCssWith, assertCascade } from "emilia-test";

test "css: nav ---- the shell under prefers colour scheme" {
    try assertCss(@src(), shell());
}

test "css: nav ---- the shell under a dark class" {
    try assertCssWith(@src(), shell(), classTheme());
}

test "css: nav ---- the shell under a data attribute" {
    try assertCssWith(@src(), shell(), attrTheme());
}

test "css: nav ---- the link with group hover" {
    try assertCss(@src(), link());
}
```

with

```bp
pub fn shell() -> Token[] {
    val dark: Token[] = [.Bg.Color.Slate.900, .Color.Slate.100];
    val row: Token[] = [.Flex.Row];
    val hidden: Token[] = [.Layout.Hidden];
    val tokens: Token[] = [.Layout.Flex, .Flex.Col, .Bg.Color.White, .Color.Slate.800, Token.Md(row), Token.Dark(dark), Token.MaxSm(hidden)];
    return tokens;
}
pub fn link() -> Token[] {
    val reveal: Token[] = [.Color.Indigo.600];
    val trimFirst: Token[] = [.Pad.L.0];
    val tokens: Token[] = [.Pad.X.3, .Color.Slate.700, Token.GroupHover(reveal), Token.First(trimFirst)];
    return tokens;
}
```

`examples/dark-mode-nav/test/__snapshots__/css/nav-the-shell-under-prefers-colour-scheme.snap`
```css
.e{display:flex;flex-direction:column;background-color:var(--color-white);color:var(--color-slate-800)}
@media (width >= 48rem){.e{flex-direction:row}}
@media (prefers-color-scheme: dark){.e{background-color:var(--color-slate-900);color:var(--color-slate-100)}}
@media (width < 40rem){.e{display:none}}
```

`examples/dark-mode-nav/test/__snapshots__/css/nav-the-shell-under-a-dark-class.snap`
```css
.e{display:flex;flex-direction:column;background-color:var(--color-white);color:var(--color-slate-800)}
.e:where(.dark, .dark *){background-color:var(--color-slate-900);color:var(--color-slate-100)}
@media (width >= 48rem){.e{flex-direction:row}}
@media (width < 40rem){.e{display:none}}
```
Under `DarkMode.Class("dark")` the dark rule has no at-rule and moves ahead of the breakpoint rules
(56, order rule 5). This snapshot is the one [`unification.md`](./unification.md) says 34 owes: it
exists only once `darkVariant(th)` reads 54's `darkSelector`.

`examples/dark-mode-nav/test/__snapshots__/css/nav-the-shell-under-a-data-attribute.snap`
```css
.e{display:flex;flex-direction:column;background-color:var(--color-white);color:var(--color-slate-800)}
.e:where([data-theme=dark], [data-theme=dark] *){background-color:var(--color-slate-900);color:var(--color-slate-100)}
@media (width >= 48rem){.e{flex-direction:row}}
@media (width < 40rem){.e{display:none}}
```

`examples/dark-mode-nav/test/__snapshots__/css/nav-the-link-with-group-hover.snap`
```css
.e{padding-left:calc(var(--spacing) * 3);padding-right:calc(var(--spacing) * 3);color:var(--color-slate-700)}
.e:is(:where(.group):hover *){color:var(--color-indigo-600)}
.e:first-child{padding-left:0}
```

---

## `examples/media-gallery` — 39 · 42 · 47 · 36 · 43

`src/main.bp`: `hero()` (gradient overlay), `thumb()` (object-fit, grayscale lifting on hover),
`glass()` (backdrop blur panel), `icon()` (svg fill/stroke), `captionTable()`.

```bp
import { hero, thumb, glass, icon, captionTable } from "main";
import { Token } from "emilia";
import { assertCss } from "emilia-test";

test "css: gallery ---- hero gradient" {
    try assertCss(@src(), hero());
}

test "css: gallery ---- thumbnail" {
    try assertCss(@src(), thumb());
}

test "css: gallery ---- glass panel" {
    try assertCss(@src(), glass());
}

test "css: gallery ---- icon" {
    try assertCss(@src(), icon());
}

test "css: gallery ---- caption table" {
    try assertCss(@src(), captionTable());
}
```

with

```bp
pub fn hero() -> Token[] {
    val tokens: Token[] = [.Layout.Position.Relative, .Layout.Aspect.Video, .Bg.Size.Cover, .Bg.Pos.Center, .Gradient.To.T, .Gradient.From.Black, .Gradient.Via.Transparent, .Gradient.Stop.Transparent];
    return tokens;
}
pub fn thumb() -> Token[] {
    val lifted: Token[] = [.Filter.Grayscale.0, .Filter.Brightness.110];
    val tokens: Token[] = [.Size.Both.24, .Layout.Object.Fit.Cover, .Border.Rounded.Md, .Filter.Grayscale.100, .Transition.All, Token.Hover(lifted)];
    return tokens;
}
pub fn glass() -> Token[] {
    val inner: Token[] = [.Bg.Color.White];
    val tokens: Token[] = [Token.Alpha(percent: 30, inner: inner), .Backdrop.Blur.Md, .Border.W.1, .Border.Color.White, .Pad.All.4];
    return tokens;
}
pub fn icon() -> Token[] {
    val tokens: Token[] = [.Size.Both.5, .Svg.Fill.None, .Svg.Stroke.Current, .Svg.StrokeWidth.2, .Layout.Inline];
    return tokens;
}
pub fn captionTable() -> Token[] {
    val tokens: Token[] = [.Size.W.Full, .Table.Separate, .Table.SpacingY.2, .Table.Layout.Fixed, .Table.Caption.Bottom, .Text.Size.Sm];
    return tokens;
}
```

`examples/media-gallery/test/__snapshots__/css/gallery-hero-gradient.snap`
```css
.e{position:relative;aspect-ratio:16 / 9;background-size:cover;background-position:center;background-image:linear-gradient(to top, var(--tw-gradient-stops));--tw-gradient-from:var(--color-black);--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-to);--tw-gradient-via:transparent;--tw-gradient-stops:var(--tw-gradient-from), var(--tw-gradient-via), var(--tw-gradient-to);--tw-gradient-to:transparent}
```

`examples/media-gallery/test/__snapshots__/css/gallery-thumbnail.snap`
```css
.e{width:calc(var(--spacing) * 24);height:calc(var(--spacing) * 24);object-fit:cover;border-radius:var(--radius-md);--tw-grayscale:grayscale(100%);filter:var(--tw-filter);transition-property:all;transition-timing-function:var(--ease-out);transition-duration:150ms}
@media (hover: hover){.e:hover{--tw-grayscale:grayscale(0);filter:var(--tw-filter);--tw-brightness:brightness(1.1);filter:var(--tw-filter)}}
```

`examples/media-gallery/test/__snapshots__/css/gallery-glass-panel.snap`
```css
.e{background-color:color-mix(in oklab, var(--color-white) 30%, transparent);--tw-backdrop-blur:blur(var(--blur-md));backdrop-filter:var(--tw-backdrop-filter);border-width:1px;border-color:var(--color-white);padding:calc(var(--spacing) * 4)}
```

`examples/media-gallery/test/__snapshots__/css/gallery-icon.snap`
```css
.e{width:calc(var(--spacing) * 5);height:calc(var(--spacing) * 5);fill:none;stroke:currentcolor;stroke-width:2;display:inline}
```

`examples/media-gallery/test/__snapshots__/css/gallery-caption-table.snap`
```css
.e{width:100%;border-collapse:separate;border-spacing:0 calc(var(--spacing) * 2);table-layout:fixed;caption-side:bottom;font-size:var(--text-sm);line-height:var(--text-sm--line-height)}
```

---

## `examples/arbitrary-and-compose` — 57 · 59

`src/main.bp`: front 57's five call sites and front 59's button, in one package.

```bp
import { signInButton, gutterContainer, draggableRow, progressiveGrid, narrowAndWide, primaryButton, tinyTheme } from "main";
import { Token, named, compose, defaultOptions, withTheme } from "emilia";
import { assertCss, assertCascade } from "emilia-test";

test "css: arbitrary ---- sign in button with a brand hex" {
    try assertCss(@src(), signInButton());
}

test "css: arbitrary ---- gutter property from the spacing scale" {
    try assertCss(@src(), gutterContainer());
}

test "css: arbitrary ---- dragging row" {
    try assertCss(@src(), draggableRow());
}

test "css: arbitrary ---- progressive grid and the two widths" {
    try assertCss(@src(), progressiveGrid().append(narrowAndWide()));
}

test "css: compose ---- the primary button" {
    try assertCss(@src(), primaryButton());
}

test "cascade: compose ---- published button beside a hashed class" {
    val _btn = named("btn", primaryButton());
    val lists: Token[][] = [signInButton()];
    try assertCascade(@src(), lists, withTheme(defaultOptions(), tinyTheme()));
}
```

with (`brand` is `cssValue """#316ff6"""`, `gutter` is `cssIdent """--gutter-width"""`, `dragging`
is `cssSelector """&.is-dragging"""`)

```bp
pub fn signInButton() -> Token[] {
    val tokens: Token[] = [arbValue("background-color", brand), .Color.White, .Text.Bold, .Pad.All.4, .Border.Rounded.Md];
    return tokens;
}
pub fn gutterContainer() -> Token[] {
    val tokens: Token[] = [arbProp(gutter, spacing(4)), .Layout.Flex, arbValue("gap", "var(--gutter-width)")];
    return tokens;
}
pub fn draggableRow() -> Token[] {
    val lifted: Token[] = [.Effect.Shadow.Lg, .Effect.Opacity.75];
    val tokens: Token[] = [.Layout.Flex, .Interact.Cursor.Grab, arbSel(dragging, lifted)];
    return tokens;
}
pub fn progressiveGrid() -> Token[] {
    val grid: Token[] = [.Layout.Grid, .Grid.Cols.3];
    val tokens: Token[] = [.Layout.Flex, .Flex.Wrap, arbAt("supports(display:grid)", grid)];
    return tokens;
}
pub fn narrowAndWide() -> Token[] {
    val centered: Token[] = [.Text.Center];
    val stacked: Token[] = [.Flex.Col];
    val tokens: Token[] = [arbMin("320px", centered), arbMax("600px", stacked)];
    return tokens;
}
pub fn primaryButton() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Blue.700];
    val base: Token[] = [.Border.Rounded.Md, .Pad.X.4, .Pad.Y.2, .Font.Weight.Bold];
    val skin: Token[] = [.Bg.Color.Blue.500, .Color.White];
    val midnight: Token[] = [.Bg.Color.Black, .Color.White];
    return compose([base, skin.append(hocus(hovered)), themeMidnight(midnight)]);
}
```

`examples/arbitrary-and-compose/test/__snapshots__/css/arbitrary-sign-in-button-with-a-brand-hex.snap`
```css
.e{background-color:#316ff6;color:var(--color-white);font-weight:bold;padding:calc(var(--spacing) * 4);border-radius:var(--radius-md)}
```

`examples/arbitrary-and-compose/test/__snapshots__/css/arbitrary-gutter-property-from-the-spacing-scale.snap`
```css
.e{--gutter-width:calc(var(--spacing) * 4);display:flex;gap:var(--gutter-width)}
```

`examples/arbitrary-and-compose/test/__snapshots__/css/arbitrary-dragging-row.snap`
```css
.e{display:flex;cursor:grab}
.e.is-dragging{box-shadow:var(--shadow-lg);opacity:0.75}
```

`examples/arbitrary-and-compose/test/__snapshots__/css/arbitrary-progressive-grid-and-the-two-widths.snap`
```css
.e{display:flex;flex-wrap:wrap}
@supports(display:grid){.e{display:grid;grid-template-columns:repeat(3, minmax(0, 1fr))}}
@media (width >= 320px){.e{text-align:center}}
@media (width < 600px){.e{flex-direction:column}}
```

`examples/arbitrary-and-compose/test/__snapshots__/css/compose-the-primary-button.snap`
```css
.e{border-radius:var(--radius-md);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);font-weight:700;background-color:var(--color-blue-500);color:var(--color-white)}
.e:focus{background-color:var(--color-blue-700)}
.e:where([data-theme="midnight"] *){background-color:var(--color-black);color:var(--color-white)}
@media (hover: hover){.e:hover{background-color:var(--color-blue-700)}}
```

`examples/arbitrary-and-compose/test/__snapshots__/cascade/compose-published-button-beside-a-hashed-class.snap`
(`tinyTheme()` = `--spacing`, `--color-white`, `--color-black`, `--color-blue-500`, `--color-blue-700`, `--radius-md`)
```css
@layer theme, base, components, utilities;
@layer theme{:root{--spacing:0.25rem;--color-white:#fff;--color-black:#000;--color-blue-500:oklch(0.623 0.214 259.815);--color-blue-700:oklch(0.488 0.243 264.376);--radius-md:0.375rem}}
@layer components{.btn{border-radius:var(--radius-md);padding-left:calc(var(--spacing) * 4);padding-right:calc(var(--spacing) * 4);padding-top:calc(var(--spacing) * 2);padding-bottom:calc(var(--spacing) * 2);font-weight:700;background-color:var(--color-blue-500);color:var(--color-white)}.btn:focus{background-color:var(--color-blue-700)}.btn:where([data-theme="midnight"] *){background-color:var(--color-black);color:var(--color-white)}@media (hover: hover){.btn:hover{background-color:var(--color-blue-700)}}}
@layer utilities{.e1{background-color:#316ff6;color:var(--color-white);font-weight:bold;padding:calc(var(--spacing) * 4);border-radius:var(--radius-md)}}
```

---

## `examples/jhonstart-attributes` — 48 (`dependencies: ["emilia", "jhonstart"]`)

`src/main.bp`: `page()` builds one card through `styled` on a builder and one through `cls` in a
`[class]={…}` hole, and `renderPage()` returns `renderToString(page) + await flush()`.

```bp
import { cardTokens, page, renderPage } from "main";
import { Token, cls, styledWith, fullTheme, mergeClass } from "emilia";
import { renderToString } from "jhonstart";
import { assertClassName, assertCss } from "emilia-test";
import { equal, contains } from "std/asserts";

test "class: attributes ---- the page card is the shared fixture" {
    try assertClassName(@src(), cardTokens());
}

test "css: attributes ---- the card rules" {
    try assertCss(@src(), cardTokens());
}

test "both routes write the same class" {
    val th = fullTheme();
    val c = cls(cardTokens(), th);
    val markup = renderToString(page());
    equal(markup, "<div class=\"" + c + "\"><p>hi</p></div><div class=\"card " + c + "\"><p>hi</p></div>");
    equal(styledWith("card", cardTokens(), th)._1, mergeClass("card", c));
}

test "the document follows the markup" {
    val out = await renderPage();
    val c = cls(cardTokens(), fullTheme());
    contains(out, "</div><style>@layer theme, base, components, utilities;");
    contains(out, "." + c + "{background-color:var(--color-white)");
}
```

with

```bp
pub fn cardTokens() -> Token[] {
    val hovered: Token[] = [.Bg.Color.Gray.100];
    val tokens: Token[] = [.Bg.Color.White, .Pad.All.4, .Text.Bold, Token.Hover(hovered)];
    return tokens;
}
```

`examples/jhonstart-attributes/test/__snapshots__/class/attributes-the-page-card-is-the-shared-fixture.snap`
```
e_<hex>
```
Byte-identical to `modules/emilia/test/__snapshots__/class/attributes-the-shared-fixture.snap`: the
same token list under the same `fullTheme()`. A test in the module `contains`-checks this file.

`examples/jhonstart-attributes/test/__snapshots__/css/attributes-the-card-rules.snap`
```css
.e{background-color:var(--color-white);padding:calc(var(--spacing) * 4);font-weight:bold}
@media (hover: hover){.e:hover{background-color:var(--color-gray-100)}}
```

---

## What the examples cover that the module tests do not

| Example | Adds |
|---|---|
| `emilia-card` | a four-list document where one list repeats (collapse across calls with other classes between) |
| `theme-brand` | a cleared namespace rendering, an `arbValue` over `themeVar`, `extend` keeping the override's position |
| `dashboard-layout` | a sibling rule listed after a breakpoint rule (partition order visible on real markup), grid span + container on one element |
| `typography-article` | the `base` layer losing to `utilities` on `h1`, `::first-letter` carrying a size pair |
| `interactive-button` | six fronts in one class: coalescing of three declaration tokens under one variant, the at-rule-free variants (`:focus-visible`, `:active`, `:disabled`) preceding the hover |
| `dark-mode-nav` | the three `DarkMode` strategies on one token list — the class and attribute forms are the snapshots 34 owes |
| `media-gallery` | `Alpha` + backdrop on one panel, a gradient with keyword stops, a filter that resets on hover |
| `arbitrary-and-compose` | `components` beside `utilities` in one document with a real theme line |
| `jhonstart-attributes` | the markup-then-document order onze 69 inserts, `mergeClass` on a rendered attribute, the fixture literal shared with the module test |
