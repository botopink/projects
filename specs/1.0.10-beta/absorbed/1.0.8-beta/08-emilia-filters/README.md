# Front 08 — emilia-filters

**Priority:** medium — Filters são úteis para efeitos visuais e glass morphism
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Filter section, BackdropFilter section) · `test/filters_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a filtros CSS (blur, brightness, contrast, etc.) nem backdrop filters.

## Steps

### Step 1 — Adicionar seção Filter

```bp
Filter {
    Blur {
        None,
        Xs,           // 4px
        Sm,           // 8px
        Md,           // 12px
        Lg,           // 16px
        Xl,           // 24px
        X2xl,         // 40px
        X3xl,         // 64px
    }
    Brightness {
        0, 50, 75, 90, 95, 100, 105, 110, 125, 150, 200,
    }
    Contrast {
        0, 50, 75, 100, 125, 150, 200,
    }
    DropShadow {
        None,
        Xs,
        Sm,
        Md,
        Lg,
        Xl,
        X2xl,
    }
    Grayscale {
        0,
        Full,         // 100%
    }
    HueRotate {
        0, 15, 30, 60, 90, 180,
    }
    Invert {
        0,
        Full,         // 100%
    }
    Saturate {
        0, 50, 100, 150, 200,
    }
    Sepia {
        0,
        Full,         // 100%
    }
}
```

### Step 2 — Adicionar seção BackdropFilter

```bp
BackdropFilter {
    Blur {
        None,
        Xs, Sm, Md, Lg, Xl, X2xl, X3xl,
    }
    Brightness {
        0, 50, 75, 90, 95, 100, 105, 110, 125, 150, 200,
    }
    Contrast {
        0, 50, 75, 100, 125, 150, 200,
    }
    Grayscale {
        0,
        Full,
    }
    HueRotate {
        0, 15, 30, 60, 90, 180,
    }
    Invert {
        0,
        Full,
    }
    Opacity {
        0, 5, 10, 25, 50, 75, 100,
    }
    Saturate {
        0, 50, 100, 150, 200,
    }
    Sepia {
        0,
        Full,
    }
}
```

**Acceptance:**
- [ ] `Filter.Blur.Sm` → `filter:blur(8px)`
- [ ] `Filter.Brightness.__50` → `filter:brightness(0.5)`
- [ ] `Filter.Contrast.__200` → `filter:contrast(2)`
- [ ] `Filter.Grayscale.Full` → `filter:grayscale(100%)`
- [ ] `Filter.HueRotate.__90` → `filter:hue-rotate(90deg)`
- [ ] `Filter.Invert.Full` → `filter:invert(100%)`
- [ ] `Filter.Saturate.__150` → `filter:saturate(1.5)`
- [ ] `Filter.Sepia.Full` → `filter:sepia(100%)`
- [ ] `BackdropFilter.Blur.Md` → `backdrop-filter:blur(12px)`
- [ ] `BackdropFilter.Opacity.__50` → `backdrop-filter:opacity(0.5)`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~80 linhas
- `emilia.bp`: +~120 linhas
- `test/filters_test.bp`: novo arquivo, ~25 testes
