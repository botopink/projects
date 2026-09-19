# Front 07 — emilia-effects

**Priority:** high — Effects completos (shadow, text-shadow, opacity, blend, mask) são essenciais para UIs polidas
**Depends on:** F14 (colors)
**Owns:** `src/tokens.bp` (Effect expansion, Blend section, Mask section) · `test/effects_test.bp`
**Does not touch:** Layout, Grid, Text, Font, Color, Bg, Pad, Margin, Border sections

---

## Problem

Effect atual tem apenas Shadow{Sm,Md,Lg,Xl} e Opacity{0,25,50,75,100}. Falta: box-shadow expandido, text-shadow, opacity completa, mix-blend-mode, background-blend-mode, mask-*.

## Steps

### Step 1 — Expandir seção Effect

```bp
Effect {
    Shadow {
        2xs,          // 0 1px rgb(0 0 0 / 0.05)
        Xs,           // 0 1px 2px 0 rgb(0 0 0 / 0.05)
        Sm,
        Md,
        Lg,
        Xl,
        X2xl,
        None,
        Inner,        // inset shadow
    }
    InsetShadow {     // NEW
        2xs,
        Xs,
        Sm,
    }
    TextShadow {      // NEW
        2xs,
        Xs,
        Sm,
        Md,
        Lg,
        None,
    }
    Opacity {
        0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
    }
}
```

### Step 2 — Adicionar seção Blend

```bp
Blend {               // mix-blend-mode
    Normal,
    Multiply,
    Screen,
    Overlay,
    Darken,
    Lighten,
    ColorDodge,
    ColorBurn,
    HardLight,
    SoftLight,
    Difference,
    Exclusion,
    Hue,
    Saturation,
    Color,
    Luminosity,
    PlusLighter,
}

BgBlend {             // background-blend-mode
    Normal,
    Multiply,
    Screen,
    Overlay,
    Darken,
    Lighten,
    ColorDodge,
    ColorBurn,
    HardLight,
    SoftLight,
    Difference,
    Exclusion,
    Hue,
    Saturation,
    Color,
    Luminosity,
    PlusLighter,
}
```

### Step 3 — Adicionar seção Mask

```bp
Mask {
    Clip {
        Border,
        Padding,
        Content,
    }
    Composite {
        Add,
        Subtract,
        Intersect,
        Exclude,
    }
    Image {
        None,
    }
    Mode {
        Alpha,
        Luminance,
    }
    Origin {
        Border,
        Padding,
        Content,
    }
    Position {
        Center,
        Top,
        Bottom,
        Left,
        Right,
    }
    Repeat {
        NoRepeat,
        Repeat,
        RepeatX,
        RepeatY,
        Round,
        Space,
    }
    Size {
        Auto,
        Cover,
        Contain,
    }
    Type {
        Alpha,
        Luminance,
    }
}
```

**Acceptance:**
- [ ] `Effect.Shadow.__2xs` → `box-shadow:0 1px rgb(0 0 0 / 0.05)`
- [ ] `Effect.Shadow.X2xl` → `box-shadow:0 25px 50px -12px rgb(0 0 0 / 0.25)`
- [ ] `Effect.Shadow.None` → `box-shadow:none`
- [ ] `Effect.Shadow.Inner` → `box-shadow:inset 0 2px 4px 0 rgb(0 0 0 / 0.05)`
- [ ] `Effect.TextShadow.Sm` → `text-shadow:0px 1px 0px rgb(0 0 0 / 0.075),...`
- [ ] `Effect.Opacity.__50` → `opacity:0.5`
- [ ] `Blend.Multiply` → `mix-blend-mode:multiply`
- [ ] `BgBlend.Screen` → `background-blend-mode:screen`
- [ ] `Mask.Clip.Content` → `mask-clip:content-box`
- [ ] `Mask.Composite.Subtract` → `mask-composite:subtract`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~120 linhas
- `emilia.bp`: +~200 linhas
- `test/effects_test.bp`: novo arquivo, ~35 testes
