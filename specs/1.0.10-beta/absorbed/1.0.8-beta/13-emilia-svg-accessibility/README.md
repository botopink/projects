# Front 13 — emilia-svg-accessibility

**Priority:** low — SVG e Accessibility são importantes para completeness
**Depends on:** F14 (colors)
**Owns:** `src/tokens.bp` (Svg section, A11y section) · `test/svg_a11y_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a propriedades SVG (fill, stroke) nem acessibilidade (sr-only).

## Steps

### Step 1 — Adicionar seção Svg

```bp
Svg {
    Fill {
        None,
        Current,      // fill: currentColor
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
    }
    Stroke {
        None,
        Current,      // stroke: currentColor
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
    }
    StrokeWidth {
        0, 1, 2,
    }
}
```

### Step 2 — Adicionar seção A11y

```bp
A11y {
    SrOnly,           // position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0
    NotSrOnly,        // position:static;width:auto;height:auto;padding:0;margin:0;overflow:visible;clip:auto;white-space:normal
    ForcedColorAdjust {
        Auto,
        None,
    }
}
```

**Acceptance:**
- [ ] `Svg.Fill.None` → `fill:none`
- [ ] `Svg.Fill.Current` → `fill:currentColor`
- [ ] `Svg.Fill.Red.__500` → `fill:#ef4444`
- [ ] `Svg.Stroke.Current` → `stroke:currentColor`
- [ ] `Svg.Stroke.Blue.__500` → `stroke:#3b82f6`
- [ ] `Svg.StrokeWidth.__2` → `stroke-width:2`
- [ ] `A11y.SrOnly` → `position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0`
- [ ] `A11y.NotSrOnly` → `position:static;width:auto;height:auto;padding:0;margin:0;overflow:visible;clip:auto;white-space:normal`
- [ ] `A11y.ForcedColorAdjust.None` → `forced-color-adjust:none`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~40 linhas
- `emilia.bp`: +~60 linhas
- `test/svg_a11y_test.bp`: novo arquivo, ~15 testes
