# Front 02 — emilia-grid

**Priority:** critical — Grid é essencial para layouts modernos; sem grid-template-columns/rows não se constrói layouts complexos
**Depends on:** F14 (colors), F15 (modifiers), F03 (spacing/sizing)
**Owns:** `src/tokens.bp` (Grid section) · `test/grid_test.bp`
**Does not touch:** Layout, Text, Font, Color, Bg, Pad, Margin, Border, Effect sections

---

## Problem

A seção `Flex` atual cobre apenas Row/Col/Wrap/NoWrap + Items/Justify/Gap básico. Falta todo o sistema de Grid CSS: `grid-template-columns/rows`, `grid-column/row` span, `grid-auto-flow/columns/rows`, gap expandido, justify/align/place completo.

## Current state

`tokens.bp:194-218` — seção Flex com Row/Col/Wrap/NoWrap + Items{Start,Center,End,Stretch} + Justify{Start,Center,End,Between,Around} + Gap{1,2,4,8}.

## Mechanism

Expandir a seção `Flex` com sub-seções adicionais + adicionar nova seção `Grid` top-level. O `tokenToCss` switch ganha novos braços; cada braço chama um sub-dispatcher dedicado.

## Steps

### Step 1 — Expandir seção Flex

```bp
Flex {
    Row,
    RowReverse,       // NEW
    Col,
    ColReverse,       // NEW
    Wrap,
    WrapReverse,      // NEW
    NoWrap,
    Grow,             // NEW: flex-grow: 1
    Grow0,            // NEW: flex-grow: 0
    Shrink,           // NEW: flex-shrink: 1
    Shrink0,          // NEW: flex-shrink: 0
    Flex1,            // NEW: flex: 1 1 0%
    FlexAuto,         // NEW: flex: 1 1 auto
    FlexInitial,      // NEW: flex: 0 1 auto
    FlexNone,         // NEW: flex: none
    Basis {           // NEW
        0, 1, 2, 4, 8, 16,
        Auto,
        Full,
        Half,         // 50%
        Third,        // 33.333%
        TwoThirds,    // 66.666%
    }
    Order {           // NEW
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        First,        // -9999
        Last,         // 9999
        None,         // 0
    }
    Items {
        Start,
        Center,
        End,
        Stretch,
        Baseline,     // NEW
    }
    Justify {
        Start,
        Center,
        End,
        Between,
        Around,
        Evenly,       // NEW
        Stretch,      // NEW
    }
    AlignContent {    // NEW
        Start,
        Center,
        End,
        Between,
        Around,
        Evenly,
        Stretch,
    }
    AlignSelf {       // NEW
        Auto,
        Start,
        Center,
        End,
        Stretch,
        Baseline,
    }
    Gap {
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24,
    }
    GapX {            // NEW
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24,
    }
    GapY {            // NEW
        0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24,
    }
    PlaceContent {    // NEW
        Start,
        Center,
        End,
        Between,
        Around,
        Evenly,
        Stretch,
    }
    PlaceItems {      // NEW
        Start,
        Center,
        End,
        Stretch,
    }
    PlaceSelf {       // NEW
        Auto,
        Start,
        Center,
        End,
        Stretch,
    }
}
```

### Step 2 — Adicionar seção Grid

```bp
Grid {
    Cols {            // grid-template-columns
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        None,
        Subgrid,
    }
    Col {             // grid-column span
        Auto,
        Span1, Span2, Span3, Span4, Span5, Span6,
        Span7, Span8, Span9, Span10, Span11, Span12,
        Full,         // 1 / -1
    }
    ColStart {        // grid-column-start
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
        Auto,
    }
    ColEnd {          // grid-column-end
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
        Auto,
    }
    Rows {            // grid-template-rows
        1, 2, 3, 4, 5, 6,
        None,
        Subgrid,
    }
    Row {             // grid-row span
        Auto,
        Span1, Span2, Span3, Span4, Span5, Span6,
        Full,
    }
    RowStart {        // grid-row-start
        1, 2, 3, 4, 5, 6, 7,
        Auto,
    }
    RowEnd {          // grid-row-end
        1, 2, 3, 4, 5, 6, 7,
        Auto,
    }
    AutoFlow {        // grid-auto-flow
        Row,
        Col,
        Dense,
        RowDense,
        ColDense,
    }
    AutoCols {        // grid-auto-columns
        Auto,
        Min,
        Max,
        Fr,
    }
    AutoRows {        // grid-auto-rows
        Auto,
        Min,
        Max,
        Fr,
    }
    JustifyItems {    // justify-items
        Start,
        Center,
        End,
        Stretch,
    }
    JustifySelf {     // justify-self
        Auto,
        Start,
        Center,
        End,
        Stretch,
    }
}
```

**Acceptance:**
- [ ] `botopink test` green com novos testes
- [ ] `Flex.RowReverse` → `flex-direction:row-reverse`
- [ ] `Flex.Grow` → `flex-grow:1`
- [ ] `Flex.Gap.__4` → `gap:1rem`
- [ ] `Flex.GapX.__2` → `column-gap:0.5rem`
- [ ] `Grid.Cols.__3` → `grid-template-columns:repeat(3,minmax(0,1fr))`
- [ ] `Grid.Col.Span2` → `grid-column:span 2 / span 2`
- [ ] `Grid.Col.Full` → `grid-column:1 / -1`
- [ ] `Grid.Rows.__2` → `grid-template-rows:repeat(2,minmax(0,1fr))`
- [ ] `Grid.AutoFlow.Col` → `grid-auto-flow:column`

### Step 3 — Sub-dispatchers em emilia.bp

Adicionar `flexBasisToCss`, `flexOrderToCss`, `gridColsToCss`, `gridColToCss`, etc.

**Acceptance:**
- [ ] `tokenToCss` switch tem braços para Flex(expandido) e Grid
- [ ] Cada sub-dispatcher é exaustivo (sem `_`)
- [ ] commonJS + erlang green

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto
- [ ] Tokens existentes (Flex.Row, Flex.Col, Flex.Items.Start, etc.) não quebrados
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~150 linhas (Flex expandido + Grid section)
- `emilia.bp`: +~250 linhas (sub-dispatchers)
- `test/grid_test.bp`: novo arquivo, ~40 testes
- Nenhum outro front afetado

## Notes

- Gap scale usa `--spacing` (1=0.25rem, 4=1rem, etc.)
- Grid.Cols.N → `repeat(N, minmax(0, 1fr))` como no Tailwind
- Grid.Col.SpanN → `span N / span N`
- Grid.Col.Full → `1 / -1`
- Flex.Order.First → `order:-9999`, Flex.Order.Last → `order:9999`
