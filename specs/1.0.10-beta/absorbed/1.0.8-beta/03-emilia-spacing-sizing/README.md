# Front 03 — emilia-spacing-sizing

**Priority:** critical — Scale completa de spacing e sizing é pré-requisito para Layout, Grid e todos os outros fronts
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Pad/Margin expansion, Size section) · `test/spacing_test.bp`
**Does not touch:** Layout, Grid, Text, Font, Color, Bg, Border, Effect sections

---

## Problem

Pad/Margin atuais têm scale limitada (1,2,4,8,16 para Pad; 1,2,4,8 para Margin). Falta a scale completa do Tailwind (0–96 + px + full + auto) e toda a seção de Sizing (width, min-width, max-width, height, min-height, max-height).

## Current state

`tokens.bp:140-183` — Pad com X{1,2,4,8,16}/Y{1,2,4,8}/All{1,2,4,8,16}; Margin com X{Auto,1,2,4,8}/Y{1,2,4,8}/All{1,2,4,8}.

## Mechanism

Expandir Pad/Margin para scale completa + adicionar nova seção `Size` top-level.

## Steps

### Step 1 — Expandir Pad

```bp
Pad {
    X {
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,         // 1px
        Full,       // 100%
    }
    Y {
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Full,
    }
    All {
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Full,
    }
    T { 0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96, Px, Full }
    R { /* same */ }
    B { /* same */ }
    L { /* same */ }
    S { /* same */ }  // padding-inline-start
    E { /* same */ }  // padding-inline-end
}
```

### Step 2 — Expandir Margin

```bp
Margin {
    X {
        Auto,
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Full,
    }
    Y { /* same without Auto */ }
    All { /* same without Auto */ }
    T { /* same */ }
    R { /* same */ }
    B { /* same */ }
    L { /* same */ }
    S { /* same */ }  // margin-inline-start
    E { /* same */ }  // margin-inline-end
    NegX {            // negative margins
        1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
    }
    NegY { /* same */ }
    NegT { /* same */ }
    NegR { /* same */ }
    NegB { /* same */ }
    NegL { /* same */ }
}
```

### Step 3 — Adicionar seção Size

```bp
Size {
    W {               // width
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Auto,
        Full,         // 100%
        Screen,       // 100vw
        Svw,          // 100svw
        Lvw,          // 100lvw
        Dvw,          // 100dvh
        Min,          // min-content
        Max,          // max-content
        Fit,          // fit-content
    }
    MinW {            // min-width
        0,
        Full,
        Min,
        Max,
        Fit,
    }
    MaxW {            // max-width
        0,
        None,
        Xs,           // 20rem
        Sm,           // 24rem
        Md,           // 28rem
        Lg,           // 32rem
        Xl,           // 36rem
        X2xl,         // 42rem
        X3xl,         // 48rem
        X4xl,         // 56rem
        X5xl,         // 64rem
        X6xl,         // 72rem
        X7xl,         // 80rem
        Full,
        ScreenSm,     // 40rem
        ScreenMd,     // 48rem
        ScreenLg,     // 64rem
        ScreenXl,     // 80rem
        Screen2xl,    // 96rem
        Prose,        // 65ch
    }
    H {               // height (same scale as W)
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Auto,
        Full,
        Screen,
        Svh,
        Lvh,
        Dvh,
        Min,
        Max,
        Fit,
    }
    MinH {
        0,
        Full,
        Screen,
        Svh,
        Lvh,
        Dvh,
        Fit,
    }
    MaxH {
        0,
        None,
        Full,
        Screen,
        Svh,
        Lvh,
        Dvh,
        Fit,
    }
    InlineSize {      // logical width
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Auto,
        Full,
    }
    MinInlineSize {
        0,
        Full,
    }
    MaxInlineSize {
        0,
        None,
        Full,
    }
    BlockSize {       // logical height
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80, 96,
        Px,
        Auto,
        Full,
    }
    MinBlockSize {
        0,
        Full,
    }
    MaxBlockSize {
        0,
        None,
        Full,
    }
}
```

**Acceptance:**
- [ ] `botopink test` green com novos testes
- [ ] `Pad.All.__0` → `padding:0`
- [ ] `Pad.All.__4` → `padding:1rem`
- [ ] `Pad.All.__96` → `padding:24rem`
- [ ] `Pad.All.Px` → `padding:1px`
- [ ] `Pad.X.__4` → `padding-left:1rem;padding-right:1rem`
- [ ] `Pad.T.__2` → `padding-top:0.5rem`
- [ ] `Margin.X.Auto` → `margin-left:auto;margin-right:auto`
- [ ] `Margin.NegX.__4` → `margin-left:-1rem;margin-right:-1rem`
- [ ] `Size.W.__4` → `width:1rem`
- [ ] `Size.W.Full` → `width:100%`
- [ ] `Size.W.Screen` → `width:100vw`
- [ ] `Size.MaxW.Xl` → `max-width:36rem`
- [ ] `Size.H.Screen` → `height:100vh`
- [ ] `Size.MinH.Screen` → `min-height:100vh`

### Step 4 — Sub-dispatchers em emilia.bp

Adicionar `padScaleToCss` (unified scale function), `marginScaleToCss`, `sizeWToCss`, `sizeMaxWToCss`, etc.

**Acceptance:**
- [ ] `tokenToCss` switch tem braços para Pad(expandido), Margin(expandido), Size
- [ ] Cada sub-dispatcher é exaustivo (sem `_`)
- [ ] commonJS + erlang green

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto
- [ ] Tokens existentes (PadX4, PadAll4, MarginXAuto) não quebrados
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~200 linhas (Pad/Margin expandidos + Size section)
- `emilia.bp`: +~300 linhas (sub-dispatchers + scale functions)
- `test/spacing_test.bp`: novo arquivo, ~50 testes
- F01 (Layout), F02 (Grid) dependem desta scale

## Notes

- Scale: 0=0, 1=0.25rem, 2=0.5rem, 3=0.75rem, 4=1rem, 5=1.25rem, 6=1.5rem, 8=2rem, 10=2.5rem, 12=3rem, 16=4rem, 20=5rem, 24=6rem, 32=8rem, 40=10rem, 48=12rem, 56=14rem, 64=16rem, 72=18rem, 80=20rem, 96=24rem
- Px = 1px
- Negative margins: `Margin.NegX.__4` → `margin-left:-1rem;margin-right:-1rem`
- Size.W.Screen → `width:100vw`, Size.H.Svh → `height:100svh`
- MaxW.Xs = 20rem, MaxW.Sm = 24rem, ..., MaxW.X7xl = 80rem
