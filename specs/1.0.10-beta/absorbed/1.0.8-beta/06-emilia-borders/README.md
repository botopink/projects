# Front 06 — emilia-borders

**Priority:** high — Borders completas com outline são essenciais para forms e focus states
**Depends on:** F14 (colors)
**Owns:** `src/tokens.bp` (Border expansion, Outline section) · `test/borders_test.bp`
**Does not touch:** Layout, Grid, Text, Font, Color, Bg, Pad, Margin, Effect sections

---

## Problem

Border atual tem W{0,1,2,4}, Color{Red/Gray palettes + Hex}, Rounded{Sm,Md,Lg,Full}. Falta: border-style, border-radius expandido, outline-width/color/style/offset.

## Steps

### Step 1 — Expandir seção Border

```bp
Border {
    W {
        0, 1, 2, 4, 8,
    }
    Style {           // NEW
        Solid,
        Dashed,
        Dotted,
        Double,
        Hidden,
        None,
    }
    Color {
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
        Transparent,
        Hex(value: string),
    }
    Rounded {
        None,         // 0
        Sm,           // 0.125rem
        Md,           // 0.375rem
        Lg,           // 0.5rem
        Xl,           // 0.75rem
        X2xl,         // 1rem
        X3xl,         // 1.5rem
        X4xl,         // 2rem
        Full,         // 9999px
    }
    RoundedT {        // NEW: top
        None, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, Full,
    }
    RoundedR { /* same */ }
    RoundedB { /* same */ }
    RoundedL { /* same */ }
    RoundedTl {       // NEW: top-left
        None, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, Full,
    }
    RoundedTr { /* same */ }
    RoundedBr { /* same */ }
    RoundedBl { /* same */ }
}
```

### Step 2 — Adicionar seção Outline

```bp
Outline {
    W {               // outline-width
        0, 1, 2, 4, 8,
    }
    Style {
        None,         // outline: 2px solid transparent; outline-offset: 2px
        Solid,
        Dashed,
        Dotted,
        Double,
    }
    Color {
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Gray { /* same */ }
        White,
        Black,
        Transparent,
        Hex(value: string),
    }
    Offset {
        0, 1, 2, 4, 8,
    }
}
```

**Acceptance:**
- [ ] `Border.W.__2` → `border-width:2px`
- [ ] `Border.Style.Dashed` → `border-style:dashed`
- [ ] `Border.Color.Red.__500` → `border-color:#ef4444`
- [ ] `Border.Rounded.Xl` → `border-radius:0.75rem`
- [ ] `Border.RoundedT.Lg` → `border-top-left-radius:0.5rem;border-top-right-radius:0.5rem`
- [ ] `Border.RoundedTl.Full` → `border-top-left-radius:9999px`
- [ ] `Outline.W.__2` → `outline-width:2px`
- [ ] `Outline.Style.Dashed` → `outline-style:dashed`
- [ ] `Outline.Offset.__2` → `outline-offset:2px`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~80 linhas
- `emilia.bp`: +~150 linhas
- `test/borders_test.bp`: novo arquivo, ~30 testes
