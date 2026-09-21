# Front 11 — emilia-transforms

**Priority:** medium — Transforms são essenciais para animações e interações visuais
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Transform section) · `test/transforms_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a transforms CSS (rotate, scale, skew, translate).

## Steps

### Step 1 — Adicionar seção Transform

```bp
Transform {
    Rotate {
        0, 1, 2, 3, 6, 12, 45, 90, 180,
    }
    NegRotate {       // negative rotation
        1, 2, 3, 6, 12, 45, 90, 180,
    }
    Scale {
        0, 50, 75, 90, 95, 100, 105, 110, 125, 150,
    }
    ScaleX {
        0, 50, 75, 90, 95, 100, 105, 110, 125, 150,
    }
    ScaleY {
        0, 50, 75, 90, 95, 100, 105, 110, 125, 150,
    }
    SkewX {
        0, 1, 2, 3, 6, 12,
    }
    SkewY {
        0, 1, 2, 3, 6, 12,
    }
    TranslateX {
        0, 1, 2, 4, 8, 16,
        Full,         // 100%
        Half,         // 50%
    }
    NegTranslateX {
        1, 2, 4, 8, 16,
        Full,
        Half,
    }
    TranslateY {
        0, 1, 2, 4, 8, 16,
        Full,
        Half,
    }
    NegTranslateY {
        1, 2, 4, 8, 16,
        Full,
        Half,
    }
    Origin {
        Center,
        Top,
        TopRight,
        Right,
        BottomRight,
        Bottom,
        BottomLeft,
        Left,
        TopLeft,
    }
    Perspective {
        None,
        Dramatic,     // 100px
        Near,         // 300px
        Normal,       // 500px
        Midrange,     // 800px
        Distant,      // 1200px
    }
    PerspectiveOrigin {
        Center,
        Top,
        Bottom,
        Left,
        Right,
    }
    Backface {
        Visible,
        Hidden,
    }
    Style {
        Flat,         // transform-style: flat
        Preserve3d,   // transform-style: preserve-3d
    }
}
```

**Acceptance:**
- [ ] `Transform.Rotate.__45` → `transform:rotate(45deg)`
- [ ] `Transform.NegRotate.__90` → `transform:rotate(-90deg)`
- [ ] `Transform.Scale.__50` → `transform:scale(0.5)`
- [ ] `Transform.ScaleX.__150` → `transform:scaleX(1.5)`
- [ ] `Transform.SkewX.__3` → `transform:skewX(3deg)`
- [ ] `Transform.TranslateX.__4` → `transform:translateX(1rem)`
- [ ] `Transform.TranslateX.Full` → `transform:translateX(100%)`
- [ ] `Transform.NegTranslateY.__2` → `transform:translateY(-0.5rem)`
- [ ] `Transform.Origin.Center` → `transform-origin:center`
- [ ] `Transform.Perspective.Normal` → `perspective:500px`
- [ ] `Transform.Backface.Hidden` → `backface-visibility:hidden`
- [ ] `Transform.Style.Preserve3d` → `transform-style:preserve-3d`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~80 linhas
- `emilia.bp`: +~120 linhas
- `test/transforms_test.bp`: novo arquivo, ~25 testes
