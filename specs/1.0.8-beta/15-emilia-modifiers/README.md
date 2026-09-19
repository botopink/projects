# Front 15 — emilia-modifiers

**Priority:** critical — Modifiers são pré-requisito para responsividade e estados
**Depends on:** none
**Owns:** `src/tokens.bp` (modifier variants expansion) · `test/modifiers_test.bp`
**Does not touch:** Seções de tokens (apenas modifiers)

---

## Problem

Modifiers atuais: Hover, Focus, Active, Md, Lg, Xl. Falta: Sm, 2Xl breakpoints, Dark mode, pseudo-classes (Visited, First, Last, Odd, Even, Disabled, Required, Invalid, FocusVisible), Group/Peer modifiers, pseudo-elements (Placeholder, Before, After, Selection, Marker), media queries (Print, MotionReduce, MotionSafe, Portrait, Landscape), direction (Rtl, Ltr), states (Open, Inert).

## Current state

`tokens.bp:264-269` — Hover/Focus/Active/Md/Lg/Xl como modifier variants com payload `Token[]`.

## Mechanism

Adicionar novos modifier variants ao Token enum. Cada modifier é um variant com payload `Token[]` que é envolvido pelo CSS correspondente no `tokenToCss`.

## Steps

### Step 1 — Adicionar breakpoint modifiers

```bp
// existing
Md(inner: Token[]),
Lg(inner: Token[]),
Xl(inner: Token[]),

// NEW
Sm(inner: Token[]),       // @media(min-width:640px){...}
X2xl(inner: Token[]),     // @media(min-width:1536px){...}
MaxSm(inner: Token[]),    // @media(max-width:640px){...}
MaxMd(inner: Token[]),    // @media(max-width:768px){...}
MaxLg(inner: Token[]),    // @media(max-width:1024px){...}
MaxXl(inner: Token[]),    // @media(max-width:1280px){...}
MaxX2xl(inner: Token[]),  // @media(max-width:1536px){...}
```

### Step 2 — Adicionar dark mode modifier

```bp
Dark(inner: Token[]),     // @media(prefers-color-scheme:dark){...}
```

### Step 3 — Adicionar pseudo-class modifiers

```bp
Visited(inner: Token[]),      // :visited{...}
FocusVisible(inner: Token[]), // :focus-visible{...}
FocusWithin(inner: Token[]),  // :focus-within{...}
First(inner: Token[]),        // :first-child{...}
Last(inner: Token[]),         // :last-child{...}
Only(inner: Token[]),         // :only-child{...}
Odd(inner: Token[]),          // :nth-child(odd){...}
Even(inner: Token[]),         // :nth-child(even){...}
FirstOfType(inner: Token[]),  // :first-of-type{...}
LastOfType(inner: Token[]),   // :last-of-type{...}
Empty(inner: Token[]),        // :empty{...}
Disabled(inner: Token[]),     // :disabled{...}
Enabled(inner: Token[]),      // :enabled{...}
Checked(inner: Token[]),      // :checked{...}
Indeterminate(inner: Token[]),// :indeterminate{...}
Default(inner: Token[]),      // :default{...}
Optional(inner: Token[]),     // :optional{...}
Required(inner: Token[]),     // :required{...}
Valid(inner: Token[]),        // :valid{...}
Invalid(inner: Token[]),      // :invalid{...}
InRange(inner: Token[]),      // :in-range{...}
OutOfRange(inner: Token[]),   // :out-of-range{...}
PlaceholderShown(inner: Token[]), // :placeholder-shown{...}
Autofill(inner: Token[]),     // :autofill{...}
ReadOnly(inner: Token[]),     // :read-only{...}
Target(inner: Token[]),       // :target{...}
```

### Step 4 — Adicionar group/peer modifiers

```bp
GroupHover(inner: Token[]),   // .group:hover &{...}
GroupFocus(inner: Token[]),   // .group:focus &{...}
GroupActive(inner: Token[]),  // .group:active &{...}
GroupVisited(inner: Token[]), // .group:visited &{...}
PeerHover(inner: Token[]),    // .peer:hover ~ &{...}
PeerFocus(inner: Token[]),    // .peer:focus ~ &{...}
PeerActive(inner: Token[]),   // .peer:active ~ &{...}
PeerChecked(inner: Token[]),  // .peer:checked ~ &{...}
PeerInvalid(inner: Token[]),  // .peer:invalid ~ &{...}
PeerRequired(inner: Token[]), // .peer:required ~ &{...}
PeerDisabled(inner: Token[]), // .peer:disabled ~ &{...}
PeerPlaceholderShown(inner: Token[]), // .peer:placeholder-shown ~ &{...}
```

### Step 5 — Adicionar pseudo-element modifiers

```bp
Placeholder(inner: Token[]),  // &::placeholder{...}
Before(inner: Token[]),       // &::before{...}
After(inner: Token[]),        // &::after{...}
Selection(inner: Token[]),    // &::selection{...}
Marker(inner: Token[]),       // & ::marker{...}
FirstLine(inner: Token[]),    // &::first-line{...}
FirstLetter(inner: Token[]),  // &::first-letter{...}
File(inner: Token[]),         // &::file-selector-button{...}
Backdrop(inner: Token[]),     // &::backdrop{...}
```

### Step 6 — Adicionar media query modifiers

```bp
Print(inner: Token[]),        // @media print{...}
MotionReduce(inner: Token[]), // @media(prefers-reduced-motion:reduce){...}
MotionSafe(inner: Token[]),   // @media(prefers-reduced-motion:no-preference){...}
Portrait(inner: Token[]),     // @media(orientation:portrait){...}
Landscape(inner: Token[]),    // @media(orientation:landscape){...}
ContrastMore(inner: Token[]), // @media(prefers-contrast:more){...}
ContrastLess(inner: Token[]), // @media(prefers-contrast:less){...}
ForcedColors(inner: Token[]), // @media(forced-colors:active){...}
```

### Step 7 — Adicionar direction/state modifiers

```bp
Rtl(inner: Token[]),          // [dir="rtl"] &{...}
Ltr(inner: Token[]),          // [dir="ltr"] &{...}
Open(inner: Token[]),         // &[open]{...}
Inert(inner: Token[]),        // &:is([inert],[inert] *){...}
```

### Step 8 — Adicionar container query modifiers

```bp
ContainerSm(inner: Token[]),  // @container(min-width:24rem){...}
ContainerMd(inner: Token[]),  // @container(min-width:28rem){...}
ContainerLg(inner: Token[]),  // @container(min-width:32rem){...}
ContainerXl(inner: Token[]),  // @container(min-width:36rem){...}
Container2xl(inner: Token[]), // @container(min-width:42rem){...}
```

### Step 9 — Atualizar tokenToCss dispatch

Adicionar braços para cada novo modifier no `tokenToCss` switch:

```bp
Sm(inner) -> "@media(min-width:640px){" + tokensToCss(inner) + "}",
X2xl(inner) -> "@media(min-width:1536px){" + tokensToCss(inner) + "}",
Dark(inner) -> "@media(prefers-color-scheme:dark){" + tokensToCss(inner) + "}",
Visited(inner) -> ":visited{" + tokensToCss(inner) + "}",
First(inner) -> ":first-child{" + tokensToCss(inner) + "}",
Last(inner) -> ":last-child{" + tokensToCss(inner) + "}",
Odd(inner) -> ":nth-child(odd){" + tokensToCss(inner) + "}",
Even(inner) -> ":nth-child(even){" + tokensToCss(inner) + "}",
Disabled(inner) -> ":disabled{" + tokensToCss(inner) + "}",
Required(inner) -> ":required{" + tokensToCss(inner) + "}",
Invalid(inner) -> ":invalid{" + tokensToCss(inner) + "}",
GroupHover(inner) -> ".group:hover &{" + tokensToCss(inner) + "}",
PeerFocus(inner) -> ".peer:focus ~ &{" + tokensToCss(inner) + "}",
Placeholder(inner) -> "::placeholder{" + tokensToCss(inner) + "}",
Before(inner) -> "::before{" + tokensToCss(inner) + "}",
After(inner) -> "::after{" + tokensToCss(inner) + "}",
Print(inner) -> "@media print{" + tokensToCss(inner) + "}",
Rtl(inner) -> "[dir=\"rtl\"] &{" + tokensToCss(inner) + "}",
Open(inner) -> "&[open]{" + tokensToCss(inner) + "}",
ContainerMd(inner) -> "@container(min-width:28rem){" + tokensToCss(inner) + "}",
// ... etc
```

**Acceptance:**
- [ ] `Sm([Token.PadAll.__4])` → `@media(min-width:640px){padding:1rem}`
- [ ] `X2xl([Token.TextSizeXl])` → `@media(min-width:1536px){font-size:1.25rem}`
- [ ] `Dark([Token.BgBlack])` → `@media(prefers-color-scheme:dark){background-color:#000000}`
- [ ] `Hover([Token.ColorRed.__500])` → `:hover{color:#ef4444}` (existing, verify)
- [ ] `Visited([Token.ColorPurple.__700])` → `:visited{color:#7e22ce}`
- [ ] `First([Token.Mt.__0])` → `:first-child{margin-top:0}`
- [ ] `Last([Token.Mb.__0])` → `:last-child{margin-bottom:0}`
- [ ] `Odd([Token.BgGray.__100])` → `:nth-child(odd){background-color:#f3f4f6}`
- [ ] `Even([Token.BgWhite])` → `:nth-child(even){background-color:#ffffff}`
- [ ] `Disabled([Token.Opacity.__50])` → `:disabled{opacity:0.5}`
- [ ] `Required([Token.BorderRed.__500])` → `:required{border-color:#ef4444}`
- [ ] `Invalid([Token.ColorRed.__700])` → `:invalid{color:#b91c1c}`
- [ ] `GroupHover([Token.ColorWhite])` → `.group:hover &{color:#ffffff}`
- [ ] `PeerFocus([Token.BorderBlue.__500])` → `.peer:focus ~ &{border-color:#3b82f6}`
- [ ] `Placeholder([Token.ColorGray.__400])` → `::placeholder{color:#9ca3af}`
- [ ] `Before([Token.ContentNone])` → `::before{content:""}`
- [ ] `Print([Token.Hidden])` → `@media print{display:none}`
- [ ] `MotionReduce([Token.AnimateNone])` → `@media(prefers-reduced-motion:reduce){animation:none}`
- [ ] `Portrait([Token.Hidden])` → `@media(orientation:portrait){display:none}`
- [ ] `Rtl([Token.Mr.__4])` → `[dir="rtl"] &{margin-right:1rem}`
- [ ] `Ltr([Token.Ml.__4])` → `[dir="ltr"] &{margin-left:1rem}`
- [ ] `Open([Token.BgGray.__100])` → `&[open]{background-color:#f3f4f6}`
- [ ] `ContainerMd([Token.FlexRow])` → `@container(min-width:28rem){flex-direction:row}`
- [ ] Modifiers aninham: `Md([Hover([Token.BgBlack])])` → `@media(min-width:768px){:hover{background-color:#000000}}`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos modifiers mapeados para CSS correto
- [ ] Modifiers existentes (Hover, Focus, Active, Md, Lg, Xl) não quebrados
- [ ] Nesting de modifiers funciona
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~80 linhas (novos modifier variants)
- `emilia.bp`: +~100 linhas (braços no tokenToCss switch)
- `test/modifiers_test.bp`: novo arquivo, ~40 testes
- Todos os outros fronts podem usar os novos modifiers

## Notes

- Group/Peer modifiers requerem que o elemento pai tenha `.group` ou `.peer` class
- Container query modifiers usam `@container` em vez de `@media`
- Dark mode usa `prefers-color-scheme` por padrão; pode ser customizado via `@custom-variant`
- Modifiers podem aninhar livremente: `Dark([Md([Hover([Token.BgBlack])])])`
