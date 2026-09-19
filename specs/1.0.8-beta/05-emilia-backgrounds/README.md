# Front 05 — emilia-backgrounds

**Priority:** high — Backgrounds com gradientes são essenciais para UIs modernas
**Depends on:** F14 (colors)
**Owns:** `src/tokens.bp` (Bg expansion, Gradient section) · `test/backgrounds_test.bp`
**Does not touch:** Layout, Grid, Text, Font, Pad, Margin, Border, Effect sections

---

## Problem

Bg atual tem apenas cores fixas (Red/Blue/Gray palettes + White/Black/Hex). Falta: bg-attachment, bg-clip, bg-image (gradientes), bg-origin, bg-position, bg-repeat, bg-size.

## Steps

### Step 1 — Expandir seção Bg

```bp
Bg {
    // existing colors (expanded by F14)
    Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Blue { /* same */ }
    Green { /* same */ }
    Gray { /* same */ }
    White,
    Black,
    Hex(value: string),

    // NEW sub-sections
    Attachment {
        Fixed,
        Local,
        Scroll,
    }
    Clip {
        Border,
        Padding,
        Content,
        Text,
    }
    Origin {
        Border,
        Padding,
        Content,
    }
    Position {
        Bottom,
        Center,
        Left,
        LeftBottom,
        LeftTop,
        Right,
        RightBottom,
        RightTop,
        Top,
    }
    Repeat {
        Repeat,
        NoRepeat,
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
}
```

### Step 2 — Adicionar seção Gradient

```bp
Gradient {
    To {              // bg-gradient-to-*
        T,            // to top
        Tr,           // to top right
        R,            // to right
        Br,           // to bottom right
        B,            // to bottom
        Bl,           // to bottom left
        L,            // to left
        Tl,           // to top left
    }
    From {            // gradient color stops
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
        Transparent,  // NEW
    }
    Via { /* same as From */ }
    To { /* same as From */ }  // color stop
}
```

**Acceptance:**
- [ ] `Bg.Attachment.Fixed` → `background-attachment:fixed`
- [ ] `Bg.Clip.Text` → `background-clip:text`
- [ ] `Bg.Position.Center` → `background-position:center`
- [ ] `Bg.Repeat.NoRepeat` → `background-repeat:no-repeat`
- [ ] `Bg.Size.Cover` → `background-size:cover`
- [ ] `Gradient.To.R` → `background-image:linear-gradient(to right,var(--tw-gradient-stops))`
- [ ] `Gradient.From.Red.__500` → `--tw-gradient-from:#ef4444;--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to,transparent)`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~80 linhas
- `emilia.bp`: +~120 linhas
- `test/backgrounds_test.bp`: novo arquivo, ~25 testes
