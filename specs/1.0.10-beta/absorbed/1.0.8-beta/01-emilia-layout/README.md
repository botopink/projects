# Front 01 — emilia-layout

**Priority:** critical — Layout é a base de qualquer UI; sem position/overflow/z-index/visibility não se constrói interfaces reais
**Depends on:** F14 (colors), F15 (modifiers), F03 (spacing/sizing)
**Owns:** `src/tokens.bp` (Layout section expansion) · `test/layout_test.bp`
**Does not touch:** Color, Bg, Grid, Text, Font, Pad, Margin, Border, Effect sections

**Tailwind CSS Reference:**
- https://tailwindcss.com/docs/display
- https://tailwindcss.com/docs/position
- https://tailwindcss.com/docs/top-right-bottom-left
- https://tailwindcss.com/docs/overflow
- https://tailwindcss.com/docs/overscroll-behavior
- https://tailwindcss.com/docs/visibility
- https://tailwindcss.com/docs/z-index
- https://tailwindcss.com/docs/float
- https://tailwindcss.com/docs/clear
- https://tailwindcss.com/docs/isolation
- https://tailwindcss.com/docs/object-fit
- https://tailwindcss.com/docs/object-position
- https://tailwindcss.com/docs/aspect-ratio
- https://tailwindcss.com/docs/columns
- https://tailwindcss.com/docs/break-after
- https://tailwindcss.com/docs/break-before
- https://tailwindcss.com/docs/break-inside
- https://tailwindcss.com/docs/box-decoration-break
- https://tailwindcss.com/docs/box-sizing

---

## Problem

A seção `Layout` atual tem apenas 6 variantes: `Block`, `InlineBlock`, `Inline`, `Hidden`, `Flex`, `Grid`. Falta todo o sistema de posicionamento CSS que o Tailwind cobre: `position`, `top/right/bottom/left`, `overflow`, `overscroll-behavior`, `visibility`, `z-index`, `float`, `clear`, `isolation`, `object-fit`, `object-position`, `aspect-ratio`, `columns`, `break-after/before/inside`, `box-decoration-break`, `box-sizing`.

## Current state

`tokens.bp:185-192` — seção Layout com 6 variantes simples (sem payload).
`emilia.bp` — `layoutTokenToCss` faz dispatch exaustivo sobre as 6 variantes.

## Mechanism

Adicionar novas sub-seções ao `Layout` existente + novas seções top-level quando necessário. O `tokenToCss` switch ganha novos braços; cada braço chama um sub-dispatcher dedicado.

## Steps

### Step 1 — Expandir seção Layout

Adicionar ao `Layout` existente:

```bp
Layout {
    // existing
    Block,
    InlineBlock,
    Inline,
    Hidden,
    Flex,
    InlineFlex,       // NEW
    Grid,
    InlineGrid,       // NEW
    Contents,         // NEW
    FlowRoot,         // NEW
    ListItem,         // NEW

    // NEW sub-sections
    Position {
        Static,
        Fixed,
        Absolute,
        Relative,
        Sticky,
    }
    Top {
        0, 1, 2, 4, 8, 16,
        Auto,
        Full,         // 100%
        Half,         // 50%
    }
    Right { /* same scale as Top */ }
    Bottom { /* same scale as Top */ }
    Left { /* same scale as Top */ }
    Inset {
        0, 1, 2, 4, 8, 16,
        Auto,
        Full,
    }
    Overflow {
        Auto,
        Hidden,
        Clip,
        Visible,
        Scroll,
    }
    OverflowX { /* same as Overflow */ }
    OverflowY { /* same as Overflow */ }
    Overscroll {
        Auto,
        Contain,
        None,
    }
    Visibility {
        Visible,
        Hidden,
        Collapse,
    }
    Z {
        0, 10, 20, 30, 40, 50,
        Auto,
    }
    Float {
        Start,
        End,
        Right,
        Left,
        None,
    }
    Clear {
        Start,
        End,
        Left,
        Right,
        Both,
        None,
    }
    Isolation {
        Isolate,        // isolation: isolate
        Auto,           // isolation: auto
    }
    ObjectFit {
        Contain,
        Cover,
        Fill,
        None,
        ScaleDown,
    }
    ObjectPosition {
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
    Aspect {
        Auto,
        Square,         // 1/1
        Video,          // 16/9
    }
    Columns {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        Auto,
    }
    BreakAfter {
        Auto,
        Avoid,
        All,
        Page,
        Left,
        Right,
        Column,
    }
    BreakBefore { /* same as BreakAfter */ }
    BreakInside {
        Auto,
        Avoid,
        AvoidPage,
        AvoidColumn,
    }
    BoxDecoration {
        Clone,
        Slice,
    }
    BoxSizing {
        Border,         // border-box
        Content,        // content-box
    }
}
```

**Acceptance:**
- [ ] `botopink test` green com novos testes cobrindo cada sub-seção
- [ ] CSS emitido para `Layout.Position.Absolute` é `position:absolute`
- [ ] CSS emitido para `Layout.Overflow.Hidden` é `overflow:hidden`
- [ ] CSS emitido para `Layout.Z.__50` é `z-index:50`
- [ ] CSS emitido para `Layout.Aspect.Video` é `aspect-ratio:16/9`
- [ ] CSS emitido para `Layout.Inset.__0` é `inset:0`
- [ ] CSS emitido para `Layout.Visibility.Hidden` é `visibility:hidden`
- [ ] CSS emitido para `Layout.ObjectFit.Cover` é `object-fit:cover`
- [ ] CSS emitido para `Layout.BoxSizing.Border` é `box-sizing:border-box`
- [ ] Teste regression: tokens existentes (Block, Flex, Grid, Hidden) continuam funcionando

### Step 2 — Sub-dispatchers em emilia.bp

Adicionar `layoutPositionToCss`, `layoutOverflowToCss`, etc. Cada um faz `case` exaustivo sobre sua sub-seção.

**Acceptance:**
- [ ] `tokenToCss` switch tem braços para todas as novas sub-seções
- [ ] Cada sub-dispatcher é exaustivo (sem `_`)
- [ ] commonJS + erlang green

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto
- [ ] Tokens existentes não quebrados
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~120 linhas (novas sub-seções no Layout)
- `emilia.bp`: +~200 linhas (sub-dispatchers)
- `test/layout_test.bp`: novo arquivo, ~30 testes
- Nenhum outro front afetado (seção isolada)

## Notes

- `Top`, `Right`, `Bottom`, `Left` usam a mesma scale do spacing (1=0.25rem, 4=1rem, etc.)
- `Z` usa valores absolutos (10, 20, 30, 40, 50) como no Tailwind
- `Inset` é shorthand para top+right+bottom+left simultaneamente
- `Float.Start/End` mapeiam para `float:inline-start/inline-end` (Tailwind v4)
